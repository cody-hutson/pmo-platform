---
title: Release Plan — closeout-verification-rows-consistent (close-out verdicts report the state the tooling read)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.70; the concrete number binds at the Stage-12 atomic claim)
milestone: closeout-verification-rows-consistent
release_class: novel
reversibility: CHEAP / Confidence HIGH — one revert of the single release merge restores the three tools, the stage spec, the standard and both decision records together. Two residues are recorded in § Rollback Strategy — thread locks applied by post-merge closes under D-PhaseC5 E2 survive a revert (a per-thread unlock is the inverse, and the cutover is forward-only), and a claimed version tag is retained and recorded rather than deleted.
---
# Release Plan — `closeout-verification-rows-consistent`

**Milestone:** `closeout-verification-rows-consistent` (ms#395) · Stage-4 sub-task **#7682** = the approved plan (Parts 1–3), the Stage-4 gate **Decision Recorded** comment, the scaffolding record, the Stage-5 wave-shape and cross-release `--retro` ownership records, the **Collective Review** scope-lock with **Plan amendment 1** and its follow-up observation cards, the Stage-6 shape record and the Commit-0 pre-flight determinations · **#7685 · #7689 · #7693 · #7697 · #7701 · #7705 · #7709 · #7713 · #7717 · #7721** = the ten Stage-5 designs, each with its independent adversarial review and its lock record · **#7686** = the Stage-6 Engineering sub-task whose spoke (E1) authored this file.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.70`**. Recorded as a determination (not a click-gate) at the Stage-4 gate, where the rule computed `v4.69`. `egress-hook-batch` then claimed `v4.69` at its merge, so the hub's Commit-0 pre-flight re-derived `v4.70`, and the Commit-0 re-verify below re-ran both halves against fresh host state (DEV-1). The concrete `vX.Y` binds only at the Stage-12 atomic claim, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp placeholder.

**Topology:** D-C **SINGLE** — one release branch (`release/closeout-verification-rows-consistent`), one PR opened in draft at Commit 0 so CI runs while the later slices land, one merge, base `main`. This plan lands as **Engineering Commit 0**, authored by #7437's Engineering spoke (E1), which then lands slice 1. Spokes E2–E5 land slices 2–9 on the same branch, in plan order.

**Concurrency posture:** **P0 fully serial** — one Engineering spoke at a time on the branch, because seven of the ten cards edit `release/tools/automated-closeout.sh` and its single self-test harness. No force-push under any posture, `--force-with-lease` included.

**Release class:** `novel` — re-rendered from the Stage-3 `routine` declaration at the Stage-4 D-ReleaseClass gate. Stage 9 review depth **Deep**. See § Release Class declaration.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on #7682 (Parts 1–3) and the Stage-4 gate **Decision Recorded** comment on it, with **Plan amendment 1** from the Collective Review applied as replacement text: where an amendment item changes plan text, the section carries the amended text, not both versions. It is reconciled to the ten Stage-5 lock records and to the Commit-0 pre-flight determinations. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Every thread comment consumed was `OWNER`-authored (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — provisional display v4.70; binds at the Stage-12 atomic claim |
| **Date Created** | 2026-09-25 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Engineering (Stage 6) — Engineering Commit 0; slices 1–9 follow in plan order |
| **Branch** | `release/closeout-verification-rows-consistent` |
| **PR** | opened in **draft** immediately after this commit, per the SINGLE topology; transitions to ready-for-review at the Stage-9 gate. The slice-1 plan update records its number here |
| **Milestone** | `closeout-verification-rows-consistent` (ms#395) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-25, domain: software }`

**Domain classification** (transcribed from the Stage-4 D-ReleaseClass block). Every FCM path is an internal pmo-platform artifact, so this is Form X. The dominant domain is software (shell tooling under `release/tools/`); the secondary is governance (`stage-13-close.md`). Plan amendment 1 adds two decision records under `release/ADRs/`, the generated release-ADR index and one section of `close-class-telemetry.md` to the matrix. All of them are internal governance artifacts, so the form and the dominant domain are unchanged.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location.

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `1c3f17db`, unmoved from the hub's brief-time read |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `bash release/tools/claim-version.sh --sha 1c3f17db7ad7a62f6e747c4824f94f61cfc95423 --bump minor --dry-run` (the adapter's own `anchor()` + `claimed_set()`; no tag pushed) | **`v4.70`** — "would claim v4.70 (no tag pushed)", exit 0; equal to the planned provisional display |
| **3** | HALT on collision: the planned version must be absent from the claimed set AND equal the recomputed next-free. The tag arm binds; published Releases and the RELEASE_LOG at `origin/main` corroborate and never authorize | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.70*'                          (tag arm — binds)
             gh release list --limit 5000 --json tagName -> startswith("v4.70")      (Releases arm)
             python3 count of v4.70 over git show origin/main:release/releases/RELEASE_LOG.md (ledger arm)
Denominator: 214 v* origin tags (426 refs, peeled refs excluded); 211 published Releases (limit
             5000, so the read is not truncated); RELEASE_LOG at origin/main, 2605 lines
Control - sensitivity: the tag arm on the v4.69 slot -> 1 tag (claimed at egress-hook-batch's merge
             40cec0c7); the ledger arm on v4.69 -> 3 lines; the Releases arm on v4.69 -> 0, because
             that Release publishes at its Stage-13 close, which has not run, so the Releases arm's
             sensitivity is shown on v4.68 instead -> 1 (published 2026-09-25T02:21:04Z)
Control - specificity: NOT TRIGGERED — slot occupancy over an exact version tuple has no near-miss
             class; the v4.70* glob is broader than the tuple, so its zero implies the tuple's zero
Extraction:  the full ls-remote output; the full 211-row release list; the full ledger, read from
             origin/main (never the worktree copy)
Result:      0 occupants of the (4,70) slot on every arm
Verdict:     CLEAN — v4.70 is free on the binding tag arm and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** `git ls-remote --heads origin 'release/*'` → **1** head, `release/verifier-grades-what-plans-declare` (control: the unfiltered head reader → 4 heads). Open PRs (`--limit 500`) → **2**: draft #7839, that sibling release, and #7888, the `v4.69` Stage-13 corpus chore, which touches no write-set path in this matrix. Control: the unfiltered PR reader (`--state all`) returns merged and open rows. See § Cross-PR Overlap Audit → In-Flight Release Roster.

### Manifest half (step 3b, post-write / pre-commit)

`bash release/tools/claim-version.sh --verify-stamp closeout-verification-rows-consistent` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder instead of reproducing it. The claim tool resolves the token by global substitution across the whole file, so a literal prose citation would be rewritten at Stage 12 along with the record site.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale is required) with its rationale sentence | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited), amended per Plan amendment 1 item 12 | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..5`), CIAC-2 at seven states per item 11 | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (37 per-issue rows, amended per items 1–10, with the AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin, and § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

**Ten content members, all bugs, one root-cause class: a close-out phase reports before, without, or regardless of the state it should read.** Seven of the ten edit `release/tools/automated-closeout.sh`, which is 15,887 lines behind one self-test harness. The other three edit `cleanup-orphan-state.sh` (#7437), `verify-release-plan.sh` (#6257) and Stage-13 Phase C5 (#4768; #5284 edits C5 and the close-out tool both).

| Slice | Issue | Problem | Size | Priority (as the card declares it) |
|---|---|---|---|---|
| 1 | #7437 | `cleanup-orphan-state.sh --dry-run` does not project the prune phase — 0 stale projected where apply prunes 1 | S | not declared on the card |
| 2 | #7182 | close-out `create_chore_branch` reports SKIPPED for a checkout it failed to perform | S | P2 |
| 3 | #7436 | `automated-closeout.sh` cannot be resumed after its own chore-PR merge, so the MERGED terminal-PASS arm is unreachable | M (S at Stage 4; re-sized at the Collective Review) | not declared on the card |
| 4 | #5769 | the close-out report header misdescribes a legitimately skipped chore PR on an apply run | XS | P4 |
| 5 | #5910 | the Procedure 7a attestation is never recorded — the emitter omits a required flag and swallows its own failure | S | P1 |
| 6 | #7465 | close-out phase 15.55 asserts anchor parity under both `--no-merge` and `--dry-run`, halting on a state it deferred | M | P2 |
| 7 | #5284 | Stage 13 Phase C5 thread-locking has not fired for at least two releases | S | P4 |
| 7 | #4768 | Stage 13 Phase C5's count verification can never pass — it compares an issues-only count against a PR-inclusive one | S | not declared on the card |
| 8 | #6892 | Close-Class-Telemetry is injected before the retro register is produced, so Indicators 1–2 can only read N/A | S | P3 |
| 9 | #6257 | the `verify-release-plan.sh` FCM check emits a false FAIL when run after the release merges | M | not declared on the card |

**Size:** raw **25** points (XS = 1 · S = 2 · M = 4, per `bundle-composition-doctrine.md` § 3 Step 5); effective **29** under `novel`'s × 1.15, kept under the recorded G3-15 rationale (§ Release Class declaration).

**Acceptance criteria.** 37 across the ten cards, all of them in the `### Acceptance Criteria` checkbox form since the Stage-4 Tier-1 [ADJUST] converted the three cards authored in other forms. They were re-read at Commit 0 (§ Verification Plan → AC baseline). The criteria's single home is each issue body; § Verification Plan binds each one by ordinal and never restates it.

**Members closed before Stage 4.** #4703 and #5768 were closed as already fixed on 2026-09-20 and listed OUT by that day's bundle amendment; the Stage-4 currency refresh then removed the milestone from both. Read at Commit 0, both are CLOSED and carry no milestone. They carry no work here and are referenced plainly, never as close targets.

**Explicit non-scope.** #5586 (`telemetry-is-computable`) keeps the telemetry tool's own edits under D-Retro-Owner hold K. No skill file and no package change under the accepted re-home. See § File Change Matrix → Release-wide explicit non-scope.

### Stage-4 Phase A0 re-review (summary)

The per-card six-column re-review tables are on #7682, comment 5826262724. This is their summary.

- **Classification:** 37 requirement rows plus 1 record fix-locus row = 38 rows — **C1 22 · C2 16 · C3 0**. No Tier 0.
- **A0.8 / G-PL4 empirical re-run:** **10 of 10 admit-still-valid**, 0 close-resolved, 0 re-scope-changed, pinned at `8e0ee084`. Five cards were re-run empirically; five were re-run statically, with their runtime arms carried to Stage 7.
- **Gate results:** ticket-architecture reconciliation, 2 findings (ADR-076 decision 3 governs C5; ADR-158's record form for #7465) · A0.5 AC currency, PASS with 4 Tier-1 [ADJUST]s · A0.6 crisping, FLAG on form rather than substance (11 of 37 ACs outside the checkbox form) · A0.7 placement, PASS · Parallelization Map, absent (Tier-1 [ADJUST]) · currency-decision confidence gate, amend, grounded and CHEAP.
- **Where the Stage-4 brief was wrong** (each finding was carried into a decision, an [ADJUST] or a Stage-5 correction): #6892's skill-file locus does not resolve, so its doc edit re-homes; #6892 is not independent of #5586; the size scale comes from `bundle-composition-doctrine.md` § 3 Step 5, because the `size:*` label descriptions are empty; #5910 needs two writer flags, not one; C5's governing decision is ADR-076; the milestone lacked its Parallelization Map; the contention map missed three surfaces; and two sibling milestones edit the same files.

---

## Dependency Graph

Transcribed from the Stage-4 plan, with the D-PhaseC5 outcome (E2) carried in place of the open condition.

```
WITHIN THE MILESTONE (A2 DAG — directional; shared-file ORDER is contention, kept separate below)
  [D-PhaseC5 decision: E2] ──► #5284 ──► #4768   HARD  co-discharged pair; #4768's comparison shape is set by the target set #5284 decides
  #7465 ──► #5284                            HARD (C5 enforced under E2)  the new lock phase is post-merge-dependent and is declared through #7465's membership predicate
  #7182 ──► #7436                            SOFT  the resume fixture traverses phase 5; one idempotence claim covers both (CIAC-2)
  #7436 ──► #5769                            SOFT  the header enumerates the chore-PR outcome partition #7436 defines (CIAC-2)
  #7465 ⇄ #7436                              WORKFLOW (no order)  the --no-merge follow-up prescribes the resume #7436 repairs (CIAC-3)
  independent within the milestone: #7437, #5910, #6892, #6257

CROSS-MILESTONE
  #5586 [telemetry-is-computable] ──► #6892 AC-1 outcome   SHIP-GATE + same call site  → D-Telemetry-Pair K, held at Stage 5
  verifier-grades-what-plans-declare [draft #7839 in flight] ──► #6257   FILE  verify-release-plan.sh + its test suite; sibling merges first
  controls-fail-loud #6871/#4917 ◄─► automated-closeout.sh   FILE  region-adjacent to #7436's chore-PR state read
```

- **Edge count:** 2 hard, 1 hard on a condition that has fired (C5 is enforced under E2), 2 soft. **0 cycles.** A topological order exists; the Implementation Sequence is one.
- **Native edges: 0 of 20** (Stage-4 probe P1). **Mirror none:** the only unconditional hard edge (#5284 → #4768) joins a pair that lands as one slice, so a native blocked-by edge would gate nothing; and the #5586 → #6892 edge is a ship-gate, not a build-block, so it is recorded in the Parallelization Map instead.

---

## Decision Record

### Stage-4 gate (operator, 2026-09-24 local / 2026-09-25 UTC)

Rendered through the hub's Stage-4 Decision Briefing. The hub re-ran the plan's load-bearing claims before briefing (the skill-locus re-home, the two writer flags, the `--retro` absence, the Phase C5 lock counts, ADR-076 decision 3, the class weights, the version anchor and the sibling milestone's size), and every one held.

| Decision | Outcome |
|---|---|
| **D-PhaseC5** | **E2** — enforce: a close-out phase locks every milestone thread, issues and PRs, over REST; always emits a row; non-blocking; defers under `--no-merge`; forward-only (recommended E2 — aligned) |
| **D-Telemetry-Pair** | **K** — the #6892 card carries the ordering, the declared register precondition and passing the resolved register path; the #5586 card narrows to its part 2 (recommended K — aligned) |
| **D-ReleaseClass** | **novel** — supersedes the Stage-3 `routine` declaration: routine trigger (d) fails, and novel trigger (b) fires on D-PhaseC5 and D-Telemetry-Pair (aligned) |
| **D-Sizing** | #7465 `size:M` · #7436 `size:S` · #7437 `size:S` at Stage 4 (aligned). #7436 was later re-sized S → M at the Collective Review |
| **G3-15 disposition** | **keep** — raw 23 × 1.15 = 26.45 → 26, one over the 25 ceiling. Rationale: ten cards share one tool and one cause class; a split doubles close-out-tool contention across two releases. Re-affirmed at the Collective Review at raw 25 / effective 29 |
| **Plan + Release Outcome Statement** | **approve — hub-condensed Outcome Statement** (§ Release Outcome Statement) |
| **D-C Branch Topology** (recorded) | **SINGLE** — one release branch, one release PR, cards as dependency-ordered commits (the operator's standing preference) |
| **D-Concurrency Posture** (recorded) | **P0** fully serial — ratified with the plan. No force-push under any posture |
| **D-Version** (recorded determination) | `versioned` · bump-class **minor** · Stage-4 rule-computed provisional **v4.69** (anchor v4.68). `egress-hook-batch` held the same provisional slot, so the number re-derives at the Engineering Commit-0 re-verify — where it became **v4.70** (DEV-1) — and binds only at the Stage-12 atomic claim, which must pass the release slug explicitly |
| **Class posture (novel)** | engagement density Standard · Stage 9 review depth Deep · Stage 5 activation bias ALL · Stage 13 outcome window 30-day |

**Tier-1 [ADJUST]s accepted with the plan** (verbatim):

1. The #6892 documentation edit re-homes from the release-hub skill (whose cited procedure does not exist there) to `stage-13-close.md` § Phase A7.2, plus `close-class-telemetry.md` § 3.2 if the ordering rule is normative. The release makes no skill edit and no package rebuild.
2. The #5910 fix passes both `--reversibility` and `--outcome`; the writer requires both.
3. #7182 AC-6 reads "no new `  FAIL:` line attributable to this release's paths".
4. The acceptance criteria on #7465, #7436 and #7437 move into `### Acceptance Criteria` checkbox form, text unchanged.
5. Citation drift: #7182's idempotence claim is at `:16` (not `:21`); #7436's terminal-state reader is at `:5578` (not `:5557`). Locate by content.

**[BUNDLE AMENDMENT] — A7 refresh outcome path (2), Stage 4 currency refresh** (verbatim):

- **Triggers:** T5 (the milestone carried no Parallelization Map) and description currency (the Scope table named four cards no longer in scope and omitted seven open members; the Outcome Statement named outcomes owned by departed cards).
- **Composition:** `issues_added` 0 · `issues_removed` 2 — the two members closed as already fixed on 2026-09-20 (#4703, #5768), which that day's amendment listed OUT but which still carried the milestone. `composition_delta_pct` = 2 / 12 = 16.7%; theme preserved → **amend**. No issue is added, so the composition lock is untouched.
- **Recording:** this comment · the milestone description amendment (Outcome Statement, Release Class, Scope table, sequence, Parallelization Map) · per-issue label sync (three size labels) · a deviation-log entry carried into the plan at Engineering Commit 0.

**Hub actions authorized by the approval, with their state read at Commit 0:** the milestone description amendment — present, carrying the Outcome Statement, the Release Class, the Scope table, the sequence and the Parallelization Map; the size labels on #7465, #7436 and #7437 — present, and #7436 reads `size:M` after the Collective Review; milestone removal from #4703 and #5768 — done; the acceptance-criteria checkbox conversion and the #7182 AC-6 restatement — done, 37 of 37 criteria in checkbox form and AC-6 reading the attributable-FAIL predicate; a coordination note on the #5586 card and its milestone's Stage-4 sub-task — not re-read at Commit 0; Procedure 1 scaffolding — § Stage Applicability Matrix. The approval did not cover any branch, commit or PR, or the Stage-5 launch.

### Stage 5 — scaffold, wave shape and cross-release `--retro` ownership

**Scaffold (hub, executed under the Stage-4 approval).** Procedure 1 created one sub-task per card for each of Stages 5–8 and one release-scoped sub-task for each of Stages 9–13; Stages 10 and 11 were compressed on creation. The completeness check (`check-milestone-epic-membership.py --leg M3`) read 10 work items, 46 expected slots, 46 created, 0 load-bearing and 0 advisory findings. The numbers are in § Stage Applicability Matrix.

| Decision | Chosen |
|---|---|
| **D-Stage5-Shape** (operator, 2026-09-24) | **A** — four seam-grouped design spokes, then two adversarial reviewers. Groups: G1 #7182, #7436, #5769 · G2 #7465, #5910 · G3 #5284, #4768, #6892 · G4 #7437, #6257. Reviewers: R1 one integrative review over the eight close-out-driver and Phase C5 designs · R2 #7437 and #6257. Order: [G3, G2] → [G1, G4] → [R1, R2], each launch re-gated. Usage band fresh, so at most 2 spokes in flight |
| **D-Retro-Owner** (operator, 2026-09-24, after the G3 designs returned) | **hold K** — #6892 owns the A7.2 producer move, the phase-6.8 `--retro` wiring and the declared precondition; #5586 narrows to its part 2. It arose because `telemetry-is-computable`'s Stage-4 gate recorded D-Coordination (keep #5586 and #6892 separate) without narrowing #5586, so both designs owned the same phase-6.8 change. Executed under it: scope-alignment notes on #7731 (that milestone's #5586 Stage-5 sub-task) and on #5586. **#6892's design makes no edit to `compute-close-class-telemetry.sh`; the tool-side edits are #5586's.** Usage re-check: still fine, 2 wide |

### Stage 5 — per-card lock records (operator, at the Collective Review, 2026-09-25)

Each design and its adversarial review were consumed by the hub at Procedure 4, with their load-bearing claims re-verified against `origin/main` @ `8e0ee084`. Scope is locked through Stage 9.

| Card (slice) | Lock record |
|---|---|
| #7437 (1) | Approved with Plan amendment 1 item 8: read-back after the mutating prune (survivors render `FAILED — survived prune`), Q5 needles keyed to the enumeration field with a specificity control, `LC_ALL=C` for the prune-output parse, one sentence in `stage-13-close.md` § Phase C4, and the AC-2 fixture at 2 = 2. The tri-state enumeration is ratified. This card's Engineering spoke also lands Engineering Commit 0 |
| #7182 (2) | Approved. Item 10: the AC-5 idempotence sweep also reconciles the blanket claim in the Deferred follow-up text. `_detail_one_line` becomes the release's shared diagnostic projection (items 4 and 5) |
| #7436 (3) | Approved with item 4 — the REST, owner-qualified candidate binding (a fork's same-named branch never binds), containment against the merged PR's own `refs/pull/<n>/head` (merge-method-agnostic), Change 4b with the ancestry refinement, the `OPEN` arm in the zero-commit guard, a ≥4096-byte window into `_detail_one_line`, and one arm asserting phase 11's and phase 12's readers agree. **Size re-rendered S → M** |
| #5769 (4) | Approved with item 7 (Change 5: the JSON twin carries the seven outcome states, plus arm HF-8b and a single `import os`) and item 11 (CIAC-2 has seven states) |
| #5910 (5) | Approved. The non-blocking emit is ratified. Item 5: the emitter calls `_detail_one_line` — redact, then cap — instead of an inline `head -c 800` projection |
| #7465 (6) | Approved with item 3: structural arm NM-5d (every `defer` phase opens with `_nm_defer … && return 0`), and the Deferred follow-up text names the merge method as information only. **The new record is authored** — {{ADR:post-merge-phases-declare-their-no-merge-behaviour}}, recording that post-merge phases declare their `--no-merge` behaviour; ADR-158 stays untouched. Its number was stamped with #5284's at Commit 0 |
| #5284 (7) | Approved with item 1: phase 15.2 opens with `_nm_defer` and declares one `defer` row, its `--help` row carries `DEFERS under --no-merge` on the name's line, every record site uses the literal `mark_phase "lock_milestone_threads"`, and diagnostics go through `_detail_one_line`. **The record superseding ADR-076 Decision 3 in part is authored** — {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}}, status `Proposed`, ratified at this release's Stage 13 |
| #4768 (7) | Approved with item 2: it lands in slice 7 with #5284, inheriting its literal-name and diagnostic fixes; the spec text is #5284's Change 2 plus this card's additive batch-CLI-limits sentence |
| #6892 (8) | Approved with item 6: the five arms that pin phase 6.8 to PASS get register-producing fixtures, or re-expect WARN on the missing-register path; the M5 hard gate stays deferred, with the post-ship phase-6.8 WARN count as its revisit trigger. D-Retro-Owner hold K stands |
| #6257 (9) | Approved with item 9: the post-merge range requires the plan's merge record to resolve **and** `git merge-base --is-ancestor <merge> <head>`; arm A6257-4 covers a branch ahead of `main`; M6257-3 is dropped or re-targeted. No `SCHEMA_VERSION` bump (ratified). Re-plan points R-P1..R-P7 are re-checked after `verifier-grades-what-plans-declare` merges |

### Collective Review — scope locked, with Plan amendment 1 (operator, 2026-09-25)

Rendered in the hub session's main-thread gate over ten Stage-5 designs and ten independent adversarial reviews (one integrative reviewer over the eight close-out-driver and Phase C5 designs, one over the two independent-tool designs). **Scope is hard-locked through Stage 9. Engineering is authorized: one release branch, P0 fully serial, from Engineering Commit 0.** The hub re-verified every Major finding against `origin/main` @ `8e0ee084` and live host state before the gate.

| Decision | Chosen |
|---|---|
| Scope-lock | **Approve with Plan amendment 1** (below) |
| ADRs | **Author both.** (1) A new ADR recording that post-merge phases declare their `--no-merge` behaviour (from #7465); ADR-158 stays untouched. (2) A new ADR superseding ADR-076 Decision 3 in part (from #5284) — status `Proposed`, ratified at this release's Stage 13. Both numbers are stamped together at Engineering Commit 0 (+1 / +2). |
| In-slice additions | **All four:** #7436 fail-loud push (Change 4b) with the ancestry refinement · #7437 prune read-back · #7437 Phase C4 sentence · #5769 JSON twin states |
| Size | **#7436 S → M.** Raw 25 · effective 29 (× 1.15), kept under the recorded G3-15 rationale |
| Follow-ups | **Four observation cards** (numbers in a reply on this issue): report path interpolation in phase 12.2 details · cleanup per-phase projectability declaration · event-reader version-key fallback · RELEASE_LOG rows without a 40-hex Merge SHA |
| Defaults ratified | #5910 emit stays non-blocking · #6257 owes no `SCHEMA_VERSION` bump (noted: the coverage-field precedent arrived with a bump) · #7437 tri-state enumeration (`ok` / `unavailable` / `not-consulted`) · #6892's hard preflight gate (M5) stays deferred, with the post-ship phase-6.8 WARN count as its revisit trigger |

No finding reached Blocker grade. Major findings are resolved by the amendment below; Minor findings are resolved by it or recorded in the deviation log.

#### Plan amendment 1 — replaces the corresponding plan text

The items below are verbatim. Each **replaces** the plan text it names, and the sections of this file carry the amended text: § Verification Plan (items 1–10), § Cross-Issue Acceptance Criteria (item 11), § File Change Matrix (item 12), § Cross-PR Overlap Audit → Parallelization Map (item 13), and § Implementation Sequence throughout. Stage 7, 8 and 9 graders read the plan, so these items bind the designs as amended.

1. **#5284 (slice 7).** Phase 15.2 `lock_milestone_threads` declares one `defer` row in the per-phase `--no-merge` behaviour table and opens with `_nm_defer "lock_milestone_threads" "<detail>" && return 0` (seam S-1, INT-1). Its `--help` row carries `DEFERS under --no-merge` on the phase-name line (S-2). Every record site uses the literal `mark_phase "lock_milestone_threads"` (S-3). Diagnostic details go through `_detail_one_line`; no `| head` pipeline idiom (S-4). The superseding ADR is authored as above.
2. **#4768 (slice 7).** Lands with #5284; inherits S-3 and S-4 through the shared slice. Spec text is #5284's Change 2 plus #4768's additive batch-CLI-limits sentence.
3. **#7465 (slice 6).** Adds structural arm NM-5d: every `defer` row's phase opens with `_nm_defer … && return 0` (S-1). The new ADR records the per-phase behaviour decision. The Deferred follow-up text names the merge method as information only — containment is merge-method-agnostic under item 4.
4. **#7436 (slice 3, size M).**
   - Candidate resolution runs over REST through a repo-host binding, `_host_chore_pr_candidates`: `pulls?head=<owner>:<chore-branch>&state=all`, paginated, projecting `number`, `state` and `merged_at`. The owner qualifier means a fork's same-named branch never binds as this run's chore PR (public-repository security), and the idempotent path makes no GraphQL call (S-6).
   - Containment is "the local chore tip is an ancestor of the merged PR's own head": fetch `refs/pull/<n>/head` over git transport, then `git merge-base --is-ancestor <local-tip> FETCH_HEAD`. This holds for merge-commit, squash and rebase merges (S-5; the Success Indicator's resume path).
   - Change 4b: the push fails loud, with the ancestry refinement — a remote head that is merely ahead of the local tip (for example after the host's "Update branch") is not a failure.
   - The zero-commit guard gains an `OPEN` arm (S-9).
   - Detail text reaches `_detail_one_line` with a window of at least 4096 bytes, so the helper redacts before it caps (S-7).
   - One CR arm asserts that phase 11's REST reader and phase 12's reader agree on the fixture.
5. **#5910 (slice 5).** The emitter calls `_detail_one_line` (redact, then cap) instead of an inline `head -c 800` projection (S-7).
6. **#6892 (slice 8).** The five existing arms that pin phase 6.8 to PASS get fixtures that produce the register, or re-expect WARN where the fixture exercises the missing-register path. The M5 revisit observable is the post-ship phase-6.8 WARN count (S-11).
7. **#5769 (slice 4).** Change 5: the JSON report twin carries the same seven outcome states (+ arm HF-8b), with a single `import os` (S-12).
8. **#7437 (slice 1).** After the mutating prune, each enumerated ref is read back; survivors render `FAILED — survived prune` and are counted separately. Q5's needles are keyed to `"tracking_ref_enumeration":…`, with a specificity control. The prune-output parse pins `LC_ALL=C`. One sentence in `stage-13-close.md` § Phase C4 names the prune projection and says its rows are repo-wide. The AC-2 fixture reads 2 = 2.
9. **#6257 (slice 9).** With no `--merge-base`, the post-merge range is used only when the plan's merge record resolves **and** `git merge-base --is-ancestor <merge> <head>` holds; otherwise the default range. An A6257-4 arm covers a branch ahead of `main`. Mutation arm M6257-3 is dropped or re-targeted to a property the exact-path probe decides. Re-plan points R-P1..R-P7 are re-checked after `verifier-grades-what-plans-declare` merges.
10. **#7182 (slice 2).** The AC-5 idempotence sweep also reconciles the blanket claim in the Deferred follow-up text (S-8).
11. **CIAC-2.** The outcome partition has **seven** states: `created` · `existing-open` · `resumed-already-merged` · `skipped-as-idempotent` · `dry-run` · `failed` · empty (not yet created). The JSON twin carries the same partition.
12. **File Change Matrix.**
    - Promoted to unconditional: the two new ADR files, the ADR-076 `superseded_by` pointer edit, and `release/references/standards/close-class-telemetry.md` § 3.2 (its emit-mechanism sentence is normative and omits `--retro`).
    - Dropped: `release/tools/compute-close-class-telemetry.sh` (the tool-side edits belong to #5586 under K), the ADR-158 hygiene row, the `hub-spoke-bridge.md` row (C5 is not retired), and the release-hub skill and package rows (the re-home stands).
    - Unchanged in shape: `stage-13-close.md` stays one edited file; #7437's Phase C4 sentence joins it.
13. **Parallelization Map.** The `verifier-grades-what-plans-declare` row records the `fcm_resolve_diff` coupling (that release's decision D43; INT-1 in the #6257 design).

**Follow-up observation cards filed under the Collective Review** (each carries the `observation` and `status: proposed` labels for Stage-2 triage): #7855 — close-out report details interpolate the absolute primary-checkout path into a report relayed to public sub-tasks · #7856 — cleanup dry-run has no per-phase projectability declaration · #7857 — the event read behind `_ai_recommended_cause` may not admit the version-key fallback · #7858 — some RELEASE_LOG rows carry no 40-hex Merge SHA.

### Stage-6 shape (operator, 2026-09-25)

| Decision | Chosen |
|---|---|
| **D-Stage6-Shape** | **A** — E1 Engineering Commit 0 + #7437 · E2 #7182 → #7436 → #5769 · E3 #5910 → #7465 · E4 #5284 + #4768 → #6892 · E5 #6257, after `verifier-grades-what-plans-declare` merges (aligned) |
| Usage-window band | **fresh** |

Each Engineering spoke lands one commit per slice, in plan order, and pushes each as it lands. P0 serial: one spoke at a time on `release/closeout-verification-rows-consistent`.

### Commit-0 pre-flight determinations (hub, 2026-09-25) — re-read at Commit 0

Rule executions under the Stage-4 and Collective Review authorizations; none of them is an operator gate. Engineering spoke E1 re-ran each at Commit 0.

| Determination | Value (hub, before the first Stage-6 brief) | Re-read at Commit 0 |
|---|---|---|
| **D-Version (re-derived)** | Bump-class `minor`, unchanged. Provisional display is now **v4.70** (was v4.69): `egress-hook-batch` claimed v4.69 at its merge `40cec0c7`, the tag arm reads it as taken, and the adapter's dry-run at `1c3f17db` computes v4.70 without pushing a tag. Other in-flight releases may compute the same slot, and the claim arbitrates | Holds — § Commit-0 Version Re-Verify Record: `v4.70`, free on every arm (DEV-1) |
| **ADR numbers** | {{ADR:post-merge-phases-declare-their-no-merge-behaviour}} → the anchor's next number (slice 6, #7465); {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} → the one after it (slice 7, #5284). `renumber-adr.py --detect` read anchor 206 on `origin/main`, so next-free is 207 and the two records take 207 and 208, +1 and +2 in slice order. The `verifier-grades-what-plans-declare` branch held 207 branch-only; `--detect` reports that for detection only, and it never binds. Whichever release merges second renumbers at its Stage-12 A.5.7. Prose cites both records by the slug token, never by the number | Anchor still **206**, next-free **207** — the allocation stands. The sibling branch now holds **both 207 and 208** branch-only: it added its second record at `804434e5`, minutes before the pre-flight posted. Detection only; it binds nothing, and the merge-second rule is unchanged (DEV-2, R12) |
| **Baseline** | Release branch base `1c3f17db`; Stage-4 pin `8e0ee084`. 26 commits and 13 files landed since the pin, all from `egress-hook-batch`'s merge and its Stage-12 chore; none is in this release's write set, so the designs' line citations stand | Holds — 26 commits, 13 files, **0** in the write set; one read-only input, `RELEASE_LOG.md`, moved (§ Baseline pin, DEV-3) |
| **Editability currency** | Every card stays `unconstrained`. Plan amendment 1 changed four cards' write sets: #7437 (+ `stage-13-close.md`); #7465 (+ its ADR and the generated release-ADR index); #5284 (+ its ADR, the ADR-076 pointer and the index; − `hub-spoke-bridge.md`); #6892 (+ `close-class-telemetry.md`; − `compute-close-class-telemetry.sh`). Stage-4 § 5.9 was re-run over those paths at `1c3f17db`; neither control hook has changed since the Stage-4 read at `8e0ee084`. This refresh was owed at the Collective Review turn and was recorded before any Stage-6 brief | Holds — § Implementation Sequence → Agent-Editability Read (DEV-4) |

---

## Implementation Sequence

One branch (`release/closeout-verification-rows-consistent`), P0, slices in order. **Each remediation slice lands its RED arms first: arm → observe RED → fix → observe GREEN**, with the RED observation (command plus FAIL lines) recorded in § Verification Evidence, and each re-runs the touched tool's `--self-test`. Every commit is pushed as it lands.

| Step | Slice | Card(s) | Files | Why here |
|---|---|---|---|---|
| 0 | Engineering Commit 0 | — | this plan | Carries the Commit-0 Survival Set. The version re-verify (steps 1–3) and the stamp-manifest check (step 3b) run here |
| 1 | cleanup dry-run projects the prune | #7437 | `cleanup-orphan-state.sh`; the phase-16 comment and PASS note in `automated-closeout.sh`; one § Phase C4 sentence in `stage-13-close.md` | Its only edits to files other slices touch are the phase-16 note and one sentence, so it banks a small, independent win first. Item 8 binds it; AC-3 is a self-test arm only and never a runtime exit-code change (INT-a) |
| 2 | chore branch fails loud | #7182 | `automated-closeout.sh` (phase 5, header `:16`, self-test) | Earliest phase touched. It settles the idempotence claim #7436 also bears on; item 10 widens the sweep to the Deferred follow-up text |
| 3 | resume across the chore-PR merge | #7436 | `automated-closeout.sh` (phase 11, self-test) | Its fixture traverses phase 5. It defines the outcome partition step 4 renders. Item 4 binds it (size M) |
| 4 | report header chore-PR field | #5769 | `automated-closeout.sh` (`:7580`, the JSON report twin, self-test `:14069-14188`) | Consumes step 3's partition. The collapsed-string pins change in the same commit. Items 7 and 11 bind it |
| 5 | attestation emitter | #5910 | `automated-closeout.sh` (12.9 emitter, call site, group AI) | Independent. Placed here to keep the 12.x region together. Item 5 binds it |
| 6 | 15.55 deferral/prediction + declared post-merge membership | #7465 | `automated-closeout.sh` (13 / 14 / 15.5 / 15.55 / 15.6, report Deferred section, self-test), `stage-13-close.md` Phase B note, the new record {{ADR:post-merge-phases-declare-their-no-merge-behaviour}}, and `release/ADRs/README.md` regenerated by `generate-adr-index.py --write` | Largest refactor of the shared file. It follows the resume fix so the follow-up it prescribes works (CIAC-3). Item 3 binds it; ADR-158 stays byte-untouched |
| 7 | Phase C5 per D-PhaseC5 E2 | #5284 + #4768 | `stage-13-close.md` C5; the lock phase 15.2 `lock_milestone_threads` in `automated-closeout.sh`; the new record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}}; the ADR-076 `superseded_by` pointer; `release/ADRs/README.md` regenerated | After step 6, so the new post-merge lock phase is declared through #7465's predicate from birth (CIAC-5). Items 1 and 2 bind it |
| 8 | telemetry ordering + declared precondition | #6892 | `automated-closeout.sh` (6.8 + dispatch), `stage-13-close.md` § A7.2, `close-class-telemetry.md` § 3.2 | Serializes the dispatch-list and header edits after step 7. Cross-milestone coordination per D-Telemetry-Pair K, held at Stage 5; no edit to `compute-close-class-telemetry.sh`. Item 6 binds it |
| 9 | FCM range + tree-presence discrimination | #6257 | `verify-release-plan.sh`, `tests/test_verify_release_plan.sh` | Last: it re-baselines on the sibling's merged verifier, follows that release's contract, and re-checks re-plan points R-P1..R-P7. Item 9 binds it; no `SCHEMA_VERSION` bump is owed |

**Spoke mapping (D-Stage6-Shape A):** E1 — steps 0–1 · E2 — steps 2–4 · E3 — steps 5–6 · E4 — steps 7–8 · E5 — step 9, launched only after `verifier-grades-what-plans-declare` merges, and re-checking re-plan points R-P1..R-P7 against the merged verifier before its RED arms.

**A2 container determination, recorded rather than assumed.** The threshold predicate is evaluated from the change matrix: this release has ten cards, several multi-file, structure-changing and calibration-bearing, so the predicate selects the **GitHub sub-issue container** on its literal reading. The release nonetheless runs each card's Stage-6 decomposition through the **per-issue Stage-6 sub-task the hub already scaffolded** (#7686, #7690, #7694, #7698, #7702, #7706, #7710, #7714, #7718, #7722), with each card's change units rendered as checklist rows in the release PR body. Creating further sub-issues would duplicate a container the hub already owns — the determination the exemplar release recorded for the same shape. No further sub-issue is created (DEV-19).

**The ADR index beat.** Slices 6 and 7 each add a record under `release/ADRs/`, so each regenerates `release/ADRs/README.md` with `python3 release/tools/generate-adr-index.py --write` and confirms `--verify` → `COUNT 0`. The index is tool output and is never hand-edited. Slices 0–5, 8 and 9 add no record and state the no-op in § Verification Evidence.

### Agent-Editability Read

Transcribed from the Stage-4 derivation, controls read at commit `8e0ee084`, and re-read at the branch base `1c3f17db` per the Commit-0 pre-flight's editability refresh (DEV-4).

**Derivation** — controls read at commit `8e0ee084`; re-read at `1c3f17db`:

- **Currency of the controls:** `git diff --name-only 8e0ee084 origin/main -- core/hooks/block-autonomy-ceiling.sh core/hooks/block-skill-direct-edit.sh` → **0** lines, so both hooks are byte-unchanged since the Stage-4 read. Control: the same probe over a file that did change in that window, `core/hooks/block-egress.sh` → 1 line.
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh`, reading every `case "$ABS_TARGET"` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. **2 blocks observed.**
  - Block 1 (anchored, `:725-741`), arms verbatim:
    - `"${PRIMARY_ROOT}/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/projects/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/.claude/settings.json"`
    - `"${PRIMARY_ROOT}/.claude/hooks/"*`
    - `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 (repository-membership stage, `:770-783`; the operative arm for in-repo work): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`.
  - **Projected union** (repo-relative): `CLAUDE.md` · `*/CLAUDE.md` · `OPERATIONS.md` · `*/OPERATIONS.md` · `RELEASE_PROTOCOL.md` · `*/RELEASE_PROTOCOL.md`.
  - The workspace-root, `projects/` and `.claude/` arms are discarded because the repository tracks none of them. Re-tested against the tracked index at `1c3f17db`: 0 tracked `.claude` paths. The same probe returns `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md`, which is its sensitivity arm.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`.
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
  - Arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`, grepped on the owning `SKILL.md`. Its failure branch is `exit 0  # not yet gated`.
  - The exemption list resolves at the deployed hook directory's parent (`<deploy-root>/.claude/skill-editor-exemption-list.txt`): **present, 1 entry** (re-read at Commit 0). Sensitivity arm: `pmo-skill-refiner-selftest-canary` → 1. `release-hub` → 0.
- **Classification probe at Commit 0:** the 11 write-set paths below, matched against the projected Tier-0 union and against `SKILL_SCOPE_RE` → **0** Tier-0 matches and **0** skill-scope matches. Controls on the same matchers: `release/governance/RELEASE_PROTOCOL.md` and `core/governance/OPERATIONS.md` match Tier-0; `release/skills/release-hub/SKILL.md` and `release/skills/release-hub/references/orchestration-playbook.md` match the skill scope.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| Commit 0 | `release/releases/plans/closeout-verification-rows-consistent_RELEASE_PLAN.md` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #7437 | `release/tools/cleanup-orphan-state.sh` · `release/tools/automated-closeout.sh` (the phase-16 comment and PASS note) · `release/references/pipeline/stage-13-close.md` (one § Phase C4 sentence) | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #7182 · #7436 · #5769 · #5910 | `release/tools/automated-closeout.sh` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #7465 | `release/tools/automated-closeout.sh` · `release/references/pipeline/stage-13-close.md` · the new record {{ADR:post-merge-phases-declare-their-no-merge-behaviour}} under `release/ADRs/` · `release/ADRs/README.md` (generated index) | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #5284 + #4768 | `release/references/pipeline/stage-13-close.md` · `release/tools/automated-closeout.sh` · the new record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} under `release/ADRs/` · `release/ADRs/ADR-076-comment-author-association-trust-boundary.md` (its `superseded_by` pointer) · `release/ADRs/README.md` (generated index) | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #6892 | `release/tools/automated-closeout.sh` · `release/references/pipeline/stage-13-close.md` · `release/references/standards/close-class-telemetry.md` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #6257 | `release/tools/verify-release-plan.sh` · `release/tools/tests/test_verify_release_plan.sh` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |

**Rows removed from the Stage-4 read.** The two rows that applied only if the #6892 re-home were declined — `release/skills/release-hub/references/orchestration-playbook.md` (`sanctioned-session-required`: conjunct 1 matches the scope regex, conjunct 2 true, conjunct 3 true) and `packages/release-hub.skill` (build output of that row) — are removed. The re-home stood at Stage 4, and Plan amendment 1 item 12 dropped both paths from the matrix. #6892's row also loses `compute-close-class-telemetry.sh`, dropped under hold K.

**Card classes:** every card is `unconstrained`. No path is `tier-0-floored` or `sanctioned-session-required`. An `unconstrained` row means no control refuses the write; it does not mean the change is ungoverned.

---

## Stage Applicability Matrix

**Solutioning activation** (`planning-solutioning-handoff.md` § 3; logical OR; all-or-nothing per release):

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #7465 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T3: per-phase declared membership. T4: declared predicate vs guard-presence check, and whole-phase vs own-tag prediction. T6: `NO_MERGE` read at 8 sites, not the 5 cited |
| #7437 | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ACTIVATE | T3: the record's durable form is a per-phase projectability declaration |
| #7436 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | (SKIP alone) | Point fix. Covered by the release-wide activation |
| #7182 | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ACTIVATE | T6: the record says the sibling-phase class was not audited (22 swallowed git ops in the file) |
| #6892 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | T3: a declared precondition in the telemetry tool's contract. T4: move vs compute-now/inject-later. T2 fires only if the re-home is declined |
| #6257 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | T3: a new emitted verdict token. T4: the body offers 3 options |
| #5910 | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ACTIVATE | T4: block the close vs stay non-blocking and surface the diagnostic |
| #5769 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | (SKIP alone) | Deterministic. Covered by the release-wide activation |
| #5284 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | T3/T4: enforce / amend / retire (D-PhaseC5) |
| #4768 | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ACTIVATE | T4: two comparison shapes plus the PR-scope question |

**Release-level: ACTIVATE.** Eight of ten cards fire at least one trigger, and none fires only by the letter.

- **§ 3.1 abstraction-altitude rider** (name the seam) travels with the T3 cards: #7465, #7437, #6892, #6257 and #5284.
- **§ 3.2 structural-premise-review rider** travels with #7465 (it extends the per-phase `NO_MERGE` guard structure) and #7437 (it extends the #6207 projection structure).

**Stages per issue:**

| Issue | 5 | 6 | 7 | 8 | 9 | 10/11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|
| all 10 | ✓ | ✓ | ✓ | ✓ | ✓ release-scoped | COMPRESS (git-native: the diff is the dry run; sub-tasks closed with the Skip Closure Format) | ✓ versioned claim | ✓ |

No card skips Stage 7 or 8. Every card changes executable behaviour, except #4768 under retire or amend — and D-PhaseC5 chose neither (E2). Even #4768 keeps a behavioural control arm (AC-3): the count check must pass on a PR-milestoned release and fail on a genuine mismatch.

**Scaffolded sub-tasks** (Procedure 1, the scaffold record on #7682):

| Card (slice) | Stage 5 | Stage 6 | Stage 7 | Stage 8 |
|---|---|---|---|---|
| #7437 (1) | #7685 | #7686 | #7687 | #7688 |
| #7182 (2) | #7689 | #7690 | #7691 | #7692 |
| #7436 (3) | #7693 | #7694 | #7695 | #7696 |
| #5769 (4) | #7697 | #7698 | #7699 | #7700 |
| #5910 (5) | #7701 | #7702 | #7703 | #7704 |
| #7465 (6) | #7705 | #7706 | #7707 | #7708 |
| #5284 (7) | #7709 | #7710 | #7711 | #7712 |
| #4768 (7) | #7713 | #7714 | #7715 | #7716 |
| #6892 (8) | #7717 | #7718 | #7719 | #7720 |
| #6257 (9) | #7721 | #7722 | #7723 | #7724 |

Release-scoped: Stage 9 #7725 · Stage 10 #7726 (closed — compressed, git-native) · Stage 11 #7727 (closed — compressed, git-native) · Stage 12 #7728 · Stage 13 #7729. Stage 4: #7682 (closed).

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. **Plan amendment 1 item 12 is applied in this commit** (authoring rules 3 and 5): every Stage-4 CONDITIONAL row resolved at or before the Collective Review, so each row whose condition fired is promoted here with its concrete path, and each row whose condition did not fire is dropped from the obligation set and carried in the separately labelled non-scope block (DEV-5 to DEV-13). The two decision records carry the numbers the Commit-0 pre-flight allocated against the mainline anchor 206; the literal number appears only in these path rows, and every prose citation uses the slug token.

```
# ── Engineering Commit 0 (plan transcription) ──
release/releases/plans/closeout-verification-rows-consistent_RELEASE_PLAN.md  add

# ── #7437 — cleanup dry-run projects the prune phase ──
release/tools/cleanup-orphan-state.sh  edit

# ── #7182 / #7436 / #5769 / #5910 / #7465 / #6892 / #5284 — close-out driver (#7437: the phase-16 comment and PASS note only) ──
release/tools/automated-closeout.sh  edit

# ── #5284 + #4768 (C5) · #7465 (Phase B deferred-set note) · #6892 (§ Phase A7.2, re-homed) · #7437 (§ Phase C4 sentence) ──
release/references/pipeline/stage-13-close.md  edit

# ── #6892 — § 3.2 emit-mechanism sentence (normative; omits --retro) ──
release/references/standards/close-class-telemetry.md  edit

# ── #6257 — FCM range + tree-presence discrimination ──
release/tools/verify-release-plan.sh  edit
release/tools/tests/test_verify_release_plan.sh  edit

# ── #7465 — decision record, slice 6 (promoted at Commit 0; number per the pre-flight allocation) ──
release/ADRs/ADR-207-post-merge-phases-declare-their-no-merge-behaviour.md  add

# ── #5284 — decision record superseding ADR-076 Decision 3 in part, slice 7 (promoted at Commit 0; number per the pre-flight allocation) ──
release/ADRs/ADR-208-lock-at-close-is-a-close-out-phase-over-every-milestone-thread.md  add
release/ADRs/ADR-076-comment-author-association-trust-boundary.md  edit

# ── generated release-ADR index — regenerated by generate-adr-index.py --write in slices 6 and 7, never hand-edited ──
release/ADRs/README.md  edit
```

#### Read-only inputs

```
release/tools/append-pipeline-event.sh  READ
release/releases/RELEASE_LOG.md  READ
release/tools/produce-learnings-register.sh  READ
core/hooks/block-autonomy-ceiling.sh  READ
core/hooks/block-skill-direct-edit.sh  READ
```

#### Release-wide explicit non-scope

```
release/tools/compute-close-class-telemetry.sh  NOT EDITED
release/references/how-to/hub-spoke-bridge.md  NOT EDITED
release/ADRs/ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md  NOT EDITED
release/skills/release-hub/references/orchestration-playbook.md  NOT EDITED
packages/release-hub.skill  NOT EDITED
```

- `release/tools/compute-close-class-telemetry.sh` — under D-Telemetry-Pair K, held at Stage 5, the tool-side edits belong to #5586 (DEV-10).
- `release/references/how-to/hub-spoke-bridge.md` — C5 is enforced, not retired, so the retirement cascade does not fire (DEV-11).
- `release/ADRs/ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md` — stays byte-untouched; #7465's decision is recorded in its own new record (DEV-12).
- `release/skills/release-hub/references/orchestration-playbook.md` and `packages/release-hub.skill` — the #6892 re-home was accepted at Stage 4, so the release makes no skill edit and no package rebuild (DEV-13).
- **New executables:** there are 0 `add` rows for a `*.sh`, so no `script-execution-allowlist.txt` companion row and no CI-wiring statement is owed.
- **ADR numbers:** the two `add` rows carry the numbers the pre-flight allocated (anchor 206, +1 and +2). A number binds only at merge. The `verifier-grades-what-plans-declare` branch holds both numbers branch-only at Commit 0; whichever release merges second renumbers at its Stage-12 A.5.7 with `renumber-adr.py`, which rewrites these path rows, and `renumber-adr.py --stamp` resolves every slug token as the last step of the claim (R12).
- **The generated index is edited only by its generator** in the slices that add a record, and `generate-adr-index.py --verify` → `COUNT 0` confirms it.

---

## Integration Points

| ID | Seam | Why it binds | Authority |
|---|---|---|---|
| INT-a | `cleanup-orphan-state.sh --release-close <slug> --dry-run --markdown` exit status ↔ close-out phase 16, `phase_invoke_orphan_cleanup` (`automated-closeout.sh:7471` at the pin) | Phase 16 reads only the cleanup dry-run's exit status. #7437 must not change it: AC-3 is a self-test arm, never a runtime exit-code change, and the phase-16 PASS note is updated so it names what the dry-run projects | Stage-4 Contention Map; #7437 design § Integration Acceptance Criteria |
| S-1 (INT-1) | #5284's phase 15.2 `lock_milestone_threads` ↔ #7465's per-phase `--no-merge` behaviour table | The lock phase declares one `defer` row and opens with `_nm_defer … && return 0`; NM-5d asserts that every `defer` row's phase opens that way | Plan amendment 1 items 1 and 3; CIAC-5 |
| `_detail_one_line` | the release's shared diagnostic projection — redact, then cap | #7436 (a window of at least 4096 bytes), #5910 and #5284 route diagnostic detail through it; no pipe-into-`head` idiom | Plan amendment 1 items 1, 4 and 5; #7182's lock record |
| Chore-PR outcome partition | #7436's phase 11/12 readers ↔ #5769's report header and JSON twin | Seven outcome states; one CR arm asserts phase 11's REST reader and phase 12's reader agree on the fixture | CIAC-2; items 4, 7 and 11 |
| `--no-merge` → merge → resume | #7465's Deferred section ↔ #7436's resume path | The follow-up the report prescribes must be runnable | CIAC-3 |
| `fcm_resolve_diff` | this release's #6257 ↔ `verifier-grades-what-plans-declare` (its decision D43; INT-1 in the #6257 design) | Both releases change how the verifier resolves the FCM diff range; the sibling merges first and slice 9 re-plans against it | Plan amendment 1 item 13; R3 |

### Contention Map

**Within the release, by file** (Stage-4 probe P3: 7 of 10 records name `automated-closeout.sh` in their fix locus; amended per Plan amendment 1 item 12):

| File | Cards |
|---|---|
| `release/tools/automated-closeout.sh` | #7182, #7436, #5769, #5910, #7465, #6892, #5284 (the lock phase, enforced under E2), and #7437 (the phase-16 comment and PASS note only) |
| `release/references/pipeline/stage-13-close.md` | #5284 + #4768 (Phase C5 `:540-557`), #7465 (Phase B deferred-set note), #6892 (§ Phase A7.2 `:68`, after the re-home), #7437 (one § Phase C4 sentence) |
| `release/tools/cleanup-orphan-state.sh` | #7437 |
| `release/tools/verify-release-plan.sh` + `release/tools/tests/test_verify_release_plan.sh` | #6257 |
| `release/references/standards/close-class-telemetry.md` | #6892 (§ 3.2) |
| `release/ADRs/` records and the generated `release/ADRs/README.md` | #7465 (its new record, slice 6) · #5284 (its new record and the ADR-076 pointer, slice 7) — the index regenerates in both slices |

**Inside `automated-closeout.sh`, by region** (at `8e0ee084`, byte-identical at the branch base; functions are disjoint, and four regions are shared):

| Region (at `8e0ee084`) | Cards |
|---|---|
| header phase inventory `:16-59` | #7182 (claim `:16`), #7465 (deferral annotation), #6892 (6.8 position), #5284 (lock-phase row) |
| `phase_create_chore_branch` `:1959-1982` | #7182 |
| `phase_inject_close_class_telemetry_field` `:3083-3392` | #6892 |
| `phase_create_chore_pr` `:5476-5575`, `_chore_pr_terminal_state` `:5578` | #7436 |
| `_ai_emit_attestation` `:6035-6055`, call `:6294` | #5910 |
| post-merge guards `:6326` / `:6357` / `:6810` / `:7375`, 15.55 `:7079-7330` | #7465 |
| `phase_invoke_orphan_cleanup` `:7450-7477` (phase 16) | #7437 (the comment and the PASS `mark_phase` note only; the `if` / `return 3` logic is unchanged) |
| `generate_report`: header `:7580` / Deferred section `:7666-7690` / C5 row | #5769 / #7465 / #5284 |
| `self_test()` `:7901`–end of harness | #7182, #7436, #5769 (`:14069-14188`), #5910 (group AI `:14212-15060`), #7465 (`:10840-10878`, `:13298-13370`), #6892, #5284 |
| dispatch list `:15847-15884` | #6892 (move 6.8), #5284 (append the lock phase) |

**Resolution:** the serial order in the Implementation Sequence settles every within-release overlap, so no scope split is needed. **Shared regions to watch:** the self-test harness, the header inventory, the dispatch list and `generate_report`. Integration point INT-a above is the one runtime seam #7437 must not move.

---

## Cross-PR Overlap Audit

### Baseline SHA

`8e0ee084` — `origin/main` at the Stage-4 audit (measured 2026-09-25T02:59:09Z). The release branch was cut at Commit 0 from `1c3f17db`; the 26 commits between the two touch 0 paths of the write set (§ Baseline pin). The Stage-9 GO records its own baseline here when it is rendered.

**Cross-PR at Stage 4.** There was 1 open PR, #7638 (`release/egress-hook-batch`, draft), and its 12 files ∩ this FCM = 0 (probe P10). That release has since merged (`40cec0c7`) and claimed `v4.69`.

**Cross-PR at Commit 0.** 2 open PRs:

- draft #7839 (`release/verifier-grades-what-plans-declare`) — its changed files against its merge base meet this FCM on **3** paths: `release/tools/verify-release-plan.sh`, `release/tools/tests/test_verify_release_plan.sh` and the generated `release/ADRs/README.md`. It also holds ADR numbers 207 and 208 branch-only, the same numbers allocated to this release's two records at Commit 0;
- #7888 (`chore/v4.69-stage-13-corpus-update`, the `v4.69` close-out) — it touches no write-set path; its one overlap is `release/releases/RELEASE_LOG.md`, a read-only input here.

A pinned observation, not a verdict: Stage-9 A6.5 and A6.6 render the verdicts.

**Structural (Tier-S).** This release's mover set is empty: there is no rename, relocate or delete in the FCM. So `SURFACE(R)` is only the version-slot token `Δversion/minor@v4.69`, re-minted at Commit 0 because `v4.69` is claimed. `verifier-grades-what-plans-declare` recomputes the same next-free, `v4.70`, so it is a Tier-S serialization edge on the version axis: the Stage-12 atomic claim arbitrates, and merge order equals tag order.

**Sibling-merge stale-pin trigger.** `8e0ee084..1c3f17db` intersected with `SURFACE(R)` beyond the version slot is ∅ (§ Baseline pin).

### In-Flight Release Roster

**Measured at:** `1c3f17db` · `2026-09-25` Engineering Commit 0 · **Population:** n=1 sibling.

Commands: `git ls-remote --heads origin 'release/*'` → 1 head; open PRs with `--limit 500` → 2, of which one has a `release/*` head. Controls: the unfiltered head reader → 4 heads (`main`, the sibling release and two `chore/*` close-out branches); the unfiltered PR reader (`--state all`) returns open and merged rows; each filter's known positive, `release/verifier-grades-what-plans-declare`, is present in both filtered reads.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `verifier-grades-what-plans-declare` | `#7839` (draft) | `a57a341c` | `minor` | `v4.69` (stale — claimed by `egress-hook-batch`) | `v4.70` | `release/tools/verify-release-plan.sh` · `release/tools/tests/test_verify_release_plan.sh` · `release/ADRs/README.md` |

- **`verifier-grades-what-plans-declare`** edits `verify-release-plan.sh` and its test suite with eight cards; slice 9 (#6257) serializes after it merges and re-plans against the merged file. It carries the stale `v4.69` label and recomputes the same next-free as this release, so the two releases share the version slot (Tier-S), and its two branch-only ADR numbers equal this release's (R12).
- **`telemetry-is-computable`** (ms#341) has no branch at Commit 0. Both releases edit the phase-6.8 region of `automated-closeout.sh` (#5586's `--retro` limb is narrowed to its part 2 under hold K), and whichever merges second re-baselines.
- **`controls-fail-loud`** (ms#334) and **`install-resolves-identically`** (ms#338) have no branch at Commit 0 (planned siblings below).

### Planned siblings (recorded for Stage-9 A6.6)

These had no branch at Stage 4 or at Commit 0, so they fall outside the roster's definition.

| Milestone | Same-file overlap with this FCM | Note |
|---|---|---|
| `telemetry-is-computable` (ms#341) | `automated-closeout.sh` (#5586 phase-6.8 call; #5193 self-test Test 11) · `stage-13-close.md` (#5586 § A7.2; #4741) | Same call site as #6892. Under hold K, #5586 narrows to its part 2 and owns the edits to `compute-close-class-telemetry.sh`, which this release no longer touches. Whichever merges second re-baselines |
| `controls-fail-loud` (ms#334) | `automated-closeout.sh` (#6871 `gh pr view --json` sites incl. the chore-PR merge-state read; #4917 a never-FAIL site) | Region-adjacent to #7436 |
| `verifier-grades-what-plans-declare` (ms#405) | `verify-release-plan.sh` (8 cards) · `tests/test_verify_release_plan.sh` | In flight at Commit 0 (roster above). Its plan records #6257's region as "no overlap"; the two releases couple through `fcm_resolve_diff` (item 13). It merges first |
| `install-resolves-identically` (ms#338) | none: 0 of 8 member bodies name an FCM file (probe P9) | Parallel-safe |

### Parallelization Map

Transcribed from Stage 4, with Plan amendment 1 item 13 folded into the `verifier-grades-what-plans-declare` row. The milestone description carries the same map, amended by the hub.

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| `telemetry-is-computable` (ms#341) | bidirectional | soft + file-contention | #5586 and #6892 change the same phase-6.8 call site. D-Telemetry-Pair K, held at Stage 5: #6892 wires the register path; #5586 narrows to its part 2. Ship-gate for #6892 AC-1. Whichever release merges second re-baselines |
| `verifier-grades-what-plans-declare` (ms#405) | other-blocks-this (merge order) | file-contention | `verify-release-plan.sh` and its test suite, edited by eight sibling cards. The sibling merges first; #6257 slices last and re-baselines. The two releases couple through `fcm_resolve_diff` (that release's decision D43; INT-1 in the #6257 design); #6257 owes no `SCHEMA_VERSION` bump |
| `controls-fail-loud` (ms#334) | bidirectional | file-contention | `automated-closeout.sh` — #6871's chore-PR merge-state read is region-adjacent to #7436. Whichever merges second re-baselines |
| version slot | shared | Tier-S structural | `egress-hook-batch` claimed `v4.69` and this release re-derived `v4.70`, which `verifier-grades-what-plans-declare` also computes. The Stage-12 atomic claim serializes the two |
| `install-resolves-identically` (ms#338) | — | none (parallel-safe) | no shared files |

Hard edges: none (0 native edges; 0 external blockers).

---

## Risk Register

| ID | Risk | L | I | Mitigation | Stage |
|---|---|---|---|---|---|
| R1 | Same-file contention: 7 cards on `automated-closeout.sh` and its one self-test harness | H | H | P0 serial, one slice per commit, `--self-test` after every slice, CIAC-1 on the merged tree | 6 / 9 |
| R2 | Cross-release on `automated-closeout.sh`: `telemetry-is-computable` (#5586 same call site, #5193 self-test) and `controls-fail-loud` (#6871 chore-PR state read) | M | H | Whichever merges second re-baselines. Stage 9 A6.5 re-measures. Parallelization Map edge | 9 / 12 |
| R3 | Cross-release on `verify-release-plan.sh` and its test suite (8 sibling cards; draft #7839 in flight at Commit 0) | H | M | #6257 last, launched after the sibling merges. Re-plan by function name (line refs will move); re-check R-P1..R-P7; the `fcm_resolve_diff` coupling is item 13; no `SCHEMA_VERSION` bump is owed | 6 |
| R4 | #6892 AC-1 cannot be MET without #5586 | H | M | **Settled:** D-Telemetry-Pair K, held at Stage 5 — #6892 carries the ordering, the declared precondition and the resolved register path | 4 / 5 |
| R5 | **Reflexive close:** this release's Stage 13 runs the very tools it changes | M | H | Before `--apply`: run each tool's `--self-test` and a `--dry-run` on this release. The Phase-B chore-PR fallback stays available. The C5 cutover exempts this release, with a voluntary live-fire recommended | 13 |
| R6 | D-PhaseC5 needs a superseding ADR (ADR-076 is Accepted) | M | M | **Settled under E2:** the superseding record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} is authored `Proposed` and ratified at this release's Stage 13, and ADR-076 gains its `superseded_by` pointer. C5 is not retired, so no retirement cascade applies; the rows are unconditional in the FCM, and the rename-reference-cascade sweep runs in slice 7 | 5 / 6 |
| R7 | #5910's record sketch passes 1 flag where 2 are needed, and its falsification clause would reject a correct cause | H | M | The Stage-5 brief carried the writer-replay evidence; the fix passes both flags (Tier-1 [ADJUST] 2) | 5 |
| R8 | #7436 fixture vacuity: the zero-commit guard bypasses the probe when `origin/main` is fresh | M | M | The fixture models a stale ref. AC-1 names the arm per path | 5 / 7 |
| R9 | #7465 dry-run design tension with #5268's mode-invariant limb | M | M | Stage-5 decision; two-state dry-run fixture | 5 |
| R10 | #7437 AC3 read as a runtime exit change would halt close-out phase 16 on repos with no stale refs | L | H | Scope to a self-test arm; INT-a | 5 / 7 |
| R11 | Version slot: `egress-hook-batch` (then provisional v4.69, ahead) and `verifier-grades-what-plans-declare` compute the same next-free | H | L | Defer-to-merge. **At Commit 0:** `egress-hook-batch` claimed `v4.69`; this release re-derived `v4.70`, which the sibling also computes. Stage-12 atomic claim with an explicit `--stamp-slug` | 6 / 12 |
| R12 | ADR number collision | L | L | Number claimed at merge; `renumber-adr.py`. **At Commit 0:** `egress-hook-batch` took 205 and 206 on the mainline, so this release's records were allocated 207 and 208 — and the `verifier-grades-what-plans-declare` branch holds both 207 and 208 branch-only. Whichever release merges second renumbers both of its records at Stage-12 A.5.7; prose uses slug tokens, so the sweep is the FCM rows, the filenames and the generated index | 12 |
| R13 | Rollback leaves host state: under E2, thread locks from post-merge closes survive a revert | M | L | Forward-only cutover. Per-thread unlock is the inverse | 13 |
| R14 | Class-level ACs grow scope: #7465 AC5, #5284 AC4, #7182's class audit | M | M | Right-sized at Stage 5 (measurement, not per-phase remediation) | 5 |
| R15 | Pipeline-entry record gaps: 5 of 10 lack an Approve on the thread, #5284's last verdict is Defer, 3 were unsized (G3-09) | L | M | Hub disposition; the three size labels were applied at the Stage-4 gate | 4 |
| R16 | Closed members #4703 / #5768 still carry the milestone: 6 planned points with no delivered work | L | L | **Resolved:** the milestone was removed from both under the Stage-4 approval (read at Commit 0) | 4 / 13 |
| R17 | Parallelization Map absent, so Stage-9 A6.6 has no prior map to diff against | L | M | **Resolved:** the hub amended the milestone description, which now carries the map and item 13's coupling | 4 |

**Rollback complexity:** LOW. It is one revert of one merge. The residue is host-state thread locks under E2 (R13) and a tag that is retained, never deleted (Tag Retention). There are no deploy targets under the accepted re-home.

---

## Delivery Strategy

- **Branch** `release/closeout-verification-rows-consistent` (slug-primary). **One release PR.** D-C SINGLE, P0.
- **Commit 0** is the plan file. It carries the Commit-0 Survival Set rows 1–9:
  - label · FCM · CIAC · Verification Plan
  - the double-brace `RELEASE_VERSION` placeholder in the Header `**Version**` cell only (named here, not reproduced)
  - matrix · class · sequence · pin `8e0ee084`
  - It runs the Commit-0 version re-verify (fetch tags, recompute next-free) and `claim-version.sh --verify-stamp closeout-verification-rows-consistent`. All intra-repo links in the plan use the workspace-rooted `/…` form.
- **Slices 1–9** follow the Implementation Sequence. Each is RED → fix → GREEN, re-runs the touched tool's self-test, and gets CIAC-1 at the end. There is no force-push, and there is no merge with any red check unread. Commit messages carry the `release(closeout-verification-rows-consistent):` prefix and reference the source card.
- **PR body:** parser-clean. Close-family verbs adjacent to an issue number appear nowhere in the body: the ten content members are referenced with `References`, and they are transitioned to closed at Stage 13 by the release close-out's structured close, not by an auto-close keyword at merge (DEV-18). The two members already closed get a plain reference.
- **Operational Deployment Manifest: none under the accepted re-home.** See § Operational Deployment Manifest.
- **Stage 13 (reflexive, R5).** This release's close runs the tools it modifies. Order: the tools' self-tests, then `--dry-run`, then `--no-merge --apply`, then merge, then resume `--apply` (the Success Indicator). The C5 cutover exempts this release, with a voluntary live-fire recommended.

---

## Verification Plan

**Per-Issue Verification.** Every null expectation carries a control arm on the same instrument and target (AC-Binding limb 2). "self-test" means `bash release/tools/automated-closeout.sh --self-test`, and "cleanup self-test" means `bash release/tools/cleanup-orphan-state.sh --self-test`; the Stage-5 designs fixed the arm labels. Rows amended by Plan amendment 1 say so in their method cell, and D-PhaseC5 E2 is carried in place of the Stage-4 alternatives (DEV-15).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7465 | AC-1 | self-test arm: `--no-merge` run with an unpublished Release | 15.55 row reads a deferral; 15.6 / 16 / 16.5 / 16.7 each emit a row; exit 0 |
| #7465 | AC-2 | self-test arm: `--dry-run`, run twice (LOG row DEPLOYED, then VERIFIED) | exit 0 in both; 15.55 reads a prediction in both states |
| #7465 | AC-3 | self-test arm: `--apply` with an injected tag↔Release divergence | 15.55 FAIL observed (sensitivity arm non-zero) |
| #7465 | AC-4 | self-test arm: own tag unpublished at `--apply` vs a sibling tag unpublished | own tag → 0 findings · control: sibling-tag arm on the same fixture → 1 finding |
| #7465 | AC-5 | self-test arm: a synthetic post-merge phase added with no declaration; named read of the phase inventory's per-phase `--no-merge` behaviour; plus structural arm NM-5d (item 3) | the arm fails the suite when the declaration is missing; every post-merge phase names a behaviour; NM-5d: every `defer` row's phase opens with `_nm_defer … && return 0` |
| #7437 | AC-1 | cleanup self-test arm (Q2): dry-run over a fixture with 1 ref stale now and 1 ref made stale by the same run's remote-branch removal (item 8) | the report lists both refs in the shared two-column `Tracking ref` / `Action` row shape the apply uses — the stale-now ref as `PRUNE`, the induced ref as `WILL-PRUNE — stale after same-run remote-branch removal` — and the dry arm mutates nothing |
| #7437 | AC-2 | cleanup self-test arm (Q3): projection vs apply outcome on the identical fixture, one invocation; after the mutating prune each enumerated ref is read back (item 8) | projected set = pruned set (**2 = 2**), every row `PRUNED`, both tracking refs gone; a ref that survives the prune renders `FAILED — survived prune` and is counted separately |
| #7437 | AC-3 | cleanup self-test arms: Q4, the pre-fix empty projection (mutation); Q5, the production dispatch with its needles keyed to `"tracking_ref_enumeration":…` plus a specificity control, and its stripped-dispatch copy; Q6, an unreadable remote (items 8 and the ratified tri-state) | Q4: the empty projection fails the predicate loudly; Q5: the inner dry-run exits 0 (INT-a) and reads `ok` or `unavailable`, never `not-consulted`, while the stripped copy reads `not-consulted`; Q6: `UNAVAILABLE`, not zero · the dry-run's runtime exit status is unchanged (INT-a) |
| #7436 | AC-1 | self-test arm: resumed `--apply`, chore PR MERGED, branch deleted, local `origin/main` stale; candidate resolution over REST, owner-qualified; containment against the merged PR's own head (item 4) | passes phase 11; phase 12 renders the MERGED terminal-PASS arm |
| #7436 | AC-2 | same arm, reading its reached-witness line; plus the CR arm that phase 11's REST reader and phase 12's reader agree on the fixture (item 4) | witness observed (reachability, not a presence grep); the two readers agree |
| #7436 | AC-3 | self-test control arm: chore PR never created / wrong slug | loud FAIL at `create_chore_pr`, exit 3 |
| #7182 | AC-1 | self-test arms: free branch vs held branch | free → success with HEAD on the chore branch; held → not success-class |
| #7182 | AC-2 | self-test arm: branch held by a second worktree | FAIL row carrying git's stderr; run exits 3 at `create_chore_branch`, before `transition_release_log` |
| #7182 | AC-3 | named read of `phase_create_chore_branch` (`:1959-1982` at the pin) | no checkout exit status discarded · control: the same read at `8e0ee084` shows the swallowed checkout at `:1970` |
| #7182 | AC-4 | self-test RED arm plus free-branch control in one run | RED aborts at `create_chore_branch`; control PASS |
| #7182 | AC-5 | `grep -c -F '(sequenced; each idempotent — re-running is safe)' release/tools/automated-closeout.sh` plus a named read of the claim and of the Deferred follow-up text (item 10) | 0 if qualified (control at `8e0ee084` → 1), or 1 when upheld with arms covering phases 5 and 11; the Deferred follow-up text's blanket claim is reconciled the same way |
| #7182 | AC-6 | `bash core/deploy/deploy.sh --check`, reading its `  FAIL:` lines against the pre-existing set at the release base | no `  FAIL:` line names a path in this FCM · control: the base run shows its pre-existing FAIL lines (instrument reads FAILs) |
| #6892 | AC-1 | fixture close that produces a register; read the injected `**Close-Class-Telemetry:**` field. The five existing arms that pin phase 6.8 to PASS run on register-producing fixtures, or re-expect WARN on the missing-register path (item 6) | Indicators 1–2 carry computed values (D-Telemetry-Pair K, held at Stage 5: #6892 passes the resolved register path) |
| #6892 | AC-2 | same fixture with no register | the field reads `N/A — no retro register found for <version>` · control: the AC-1 fixture → computed values |
| #6892 | AC-3 | `grep -c 'Close-Class-Telemetry:\*\*' release/releases/RELEASE_LOG.md` and `grep -c 'retro-conformance N/A — no retro register found for v' release/releases/RELEASE_LOG.md`, plus per-version register-existence reads | count and denominator reported (baseline at `8e0ee084`: 56 / 43) |
| #6257 | AC-1 | `bash release/tools/verify-release-plan.sh --format=json <plan>` at the branch tip and at a descendant of the merge; with no `--merge-base`, the post-merge range is used only when the plan's merge record resolves and `git merge-base --is-ancestor <merge> <head>` holds, else the default range; arm A6257-4 covers a branch ahead of `main` (item 9) | FCM-1 verdict equal across both · control: an undelivered declared ADD FAILs in both |
| #6257 | AC-2 | same run; read the FAIL row's `observed` | names the base and head it compared |
| #6257 | AC-3 | `bash release/tools/tests/test_verify_release_plan.sh` arm: one absent-from-tree fixture and one outside-range fixture | two distinct observed strings; `grep -c -F 'declared-add-not-in-range' release/tools/verify-release-plan.sh` ≥ 1 (baseline 0) |
| #5910 | AC-1 | `grep -c -F -- '--reversibility' release/tools/automated-closeout.sh`, plus a replay of `_ai_emit_attestation`'s argument list through `append-pipeline-event.sh --dry-run` | ≥ 1 (baseline 0); the replay exits 0 (baseline: exits 1 on `--reversibility`) |
| #5910 | AC-2 | fixture close with `--attest-action-items`: PRE/POST count of `procedure-7a-attestation` rows | POST − PRE = 1 |
| #5910 | AC-3 | self-test arm: induced writer failure; the emitter projects the writer's message through `_detail_one_line` (item 5) | the report shows the failure with the writer's own message, redacted and then capped; the close stays non-blocking |
| #5910 | AC-4 | self-test group AI: success arm (real writer contract via `--dry-run`) plus induced-failure arm | both arms PASS |
| #5769 | AC-1 | `grep -c -F 'N/A — dry-run or not-yet-created' release/tools/automated-closeout.sh`, plus the state-enumeration self-test arm and arm HF-8b for the JSON twin (items 7 and 11) | 0 · control: same grep at `8e0ee084` → 3; the arm renders the seven outcome states of CIAC-2, and the JSON twin carries the same seven |
| #5769 | AC-2 | self-test arm: idempotent skip at `--apply` | the header reads a success outcome |
| #5769 | AC-3 | self-test arms: dry-run and not-yet-created | two distinct strings, both distinct from AC-2's |
| #5284 | AC-1 | named read of `stage-13-close.md` § Phase C5 | states the enforced disposition (E2) with a reason; the PR quotes the pre-change text |
| #5284 | AC-2 | named read of the phase inventory and the per-phase `--no-merge` behaviour table, plus `grep -c -F '/lock' release/tools/automated-closeout.sh` (item 1) | phase 15.2 `lock_milestone_threads` is listed with one `defer` row, opens with `_nm_defer "lock_milestone_threads" … && return 0`, and every record site uses the literal `mark_phase "lock_milestone_threads"`; count ≥ 1 (baseline 0) · control: `grep -c 'issue close' release/tools/automated-closeout.sh` → 6 |
| #5284 | AC-3 | named read of the C5 text and the D-PhaseC5 record | the retrofit answer is stated (forward-only) |
| #5284 | AC-4 | measurement over the non-blocking / spoke-manual close-out phase population Stage 5 defined, against the most recent close | count checked is stated · control: ≥ 1 phase observed firing |
| #4768 | AC-1 | `grep -c -F "verify the returned count matches the milestone's closed-issue total" release/references/pipeline/stage-13-close.md`, plus a named read of the replacement clause and #4768's additive batch-CLI-limits sentence (item 2) | 0 · control: same grep at `8e0ee084` → 1 |
| #4768 | AC-2 | `grep -c -i 'PR-inclusive' release/references/pipeline/stage-13-close.md` | ≥ 1 (baseline 0) |
| #4768 | AC-3 | run the new count check on ms#386 (which milestones its own PRs) and on a fixture with one issue removed | ms#386 passes; the fixture fails |

**AC baseline** (read at `8e0ee084`, 2026-09-25; re-read at Commit 0 against the live issue bodies):

`ac_baseline: { #7465: 5, #7437: 3, #7436: 3, #7182: 6, #6892: 3, #6257: 3, #5910: 4, #5769: 3, #5284: 4, #4768: 3, read_at: 8e0ee084, re-read: 1c3f17db }`

- **Counts:** 37 criteria in total, unchanged at Commit 0.
- **Form:** at Stage 4, 26 were in `### Acceptance Criteria` checkbox form; #7465 (5) used a numbered list, and #7436 / #7437 (6) used `## Acceptance` bullets. Tier-1 [ADJUST] 4 converted those 11 with their text unchanged, and the re-read at Commit 0 finds **37 of 37** checkbox criteria, each card carrying exactly one `### Acceptance Criteria` heading. Ordinals are therefore bound by the checkbox list. **Amending a criterion obliges updating its bound row in the same change.**
- **Domain classification:** software, per the `domain_practice` label in § Header.

### Release-Level Verification

The checks below are the ones this plan and the Stage-6 C4 step already name; they are listed here so Stage 7 re-executes the same set.

- [ ] Each slice re-runs the touched tool's own `--self-test` after its fix, and `bash -n` (and `shellcheck` where it is on `PATH`) on each changed script
- [ ] CIAC-1 on the merged tree: `bash release/tools/automated-closeout.sh --self-test` → exit 0
- [ ] Runtime suite, selection-map row 4: `python3 release/tools/check-selftest-coverage.py --run`, with a `test-run` event per Stage-6 spoke
- [ ] `bash core/deploy/deploy.sh --check`: no new `  FAIL:` line attributable to this release's paths (Check 14, doc links, runs inside it)
- [ ] The plan-driven executor over this plan; `claim-version.sh --verify-stamp closeout-verification-rows-consistent` → exit 0 until the claim
- [ ] ADR beats in slices 6 and 7: `python3 release/tools/generate-adr-index.py --verify` → `COUNT 0`; ADR-number integrity; ADR durability on the added records
- [ ] Skill-package freshness: `build-skill-packages.sh --skills-for-paths`, paths on STDIN, names no skill

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#7182 × #7436 × #5769 × #5910 × #7465 × #6892 × #5284, the lock phase being enforced under D-PhaseC5 E2, on the `automated-closeout.sh` self-test harness):** every card's new arms coexist and the tool's single self-test passes as one suite on the merged tree. *Method:* dispatch the runtime-suite for the close-out driver, `bash release/tools/automated-closeout.sh --self-test`, and expect exit 0. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#7182 × #7436 × #5769 on the chore-branch / chore-PR outcome, the report header and its JSON twin):** for every outcome phases 5 and 11 can record — the **seven** states `created` · `existing-open` · `resumed-already-merged` · `skipped-as-idempotent` · `dry-run` · `failed` · empty (not yet created) — the header's chore-PR field names the same outcome as the phase row, and the JSON report twin carries the same partition. No success renders as N/A, and no failure renders as SKIPPED. *Method:* `grep -c -F 'N/A — dry-run or not-yet-created' release/tools/automated-closeout.sh`, expect 0, with control: same grep at `8e0ee084` → 3. The runtime limb is the #5769 self-test arm enumerating the partition, with arm HF-8b for the JSON twin. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7465 × #7436 on the `--no-merge` → merge → resume workflow):** the follow-up that the report's "Deferred Under --no-merge" section prescribes can actually run. A `--no-merge` run defers 15.55, and a resumed `--apply` over a merged, branch-deleted chore PR gets past phase 11 and asserts 15.55 for real. *Method:* `grep -c -F 'pr list --repo "$REPO_SLUG" --head "$CHORE_BRANCH" --state open' release/tools/automated-closeout.sh`, expect 0, with control: same grep at `8e0ee084` → 1. The runtime limb is the paired self-test arm (label fixed at Stage 5), graded from its emitted verdict. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#5284 × #4768 on `release/references/pipeline/stage-13-close.md` Phase C5):** the spec records C5's disposition and no longer compares an issues-only count against a PR-inclusive counter. *Method:* `grep -c -F "verify the returned count matches the milestone's closed-issue total" release/references/pipeline/stage-13-close.md`, expect 0, with control: same grep at `8e0ee084` → 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#7465 × #5284 on the post-merge membership predicate; C5 enforced under D-PhaseC5 E2):** the new lock phase is a declared post-merge member. It defers under `--no-merge` through `_nm_defer … && return 0` and appears in the report's deferred list. *Method:* dispatch the runtime-suite, with the #7465 membership arm extended to the lock phase and NM-5d covering its defer row. *Graded at Stage 9 QC3.5 on the merged PR.*

**Population enumerated** for cross-issue cohesion: shared file, shared function or seam, shared test harness, shared report surface, shared spec section. INT-a is a per-card consumer seam (#7437) and is graded at Stage 8, not here.

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A). The usage-window basis was **UNSTATED** at Stage 4: no band was supplied, so the conservative default applied and no figure was synthesized.
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **10** · Stage 7: **10** · Stage 8: **10**
**Per-spoke cost estimate:** 7 × `size:S` → lowest band. #6257 `M`, plus #7465 at M and #7436 at M after the Collective Review → low–moderate. #5769 `XS` → treated as the lowest band, since § 5 has no XS row. Source: the § 5 heuristic.
**Assumed/stated remaining usage-window envelope:** UNSTATED at Stage 4, so the conservative default applied. The operator then stated a **fresh** band at the Stage-5 launch (at most 2 spokes in flight) and again at the Stage-6 launch (records on #7682).
**Estimated cumulative draw % (worst parallel batch):** not synthesized (UNSTATED basis at Stage 4).
**Routing:** window-aware timing plus split batches. Under UNSTATED, Checkpoint B renders `W_max 2`, so N=10 becomes 5 sub-waves per parallel stage, each re-gated. Stages 6 and 13 are serial singletons and are still gated.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time (§ 3.1). Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`novel`** — re-rendered from the Stage-3 `routine` declaration at the Stage-4 D-ReleaseClass gate. Multi-trigger resolution: routine trigger (d) fails (D-PhaseC5 and D-Telemetry-Pair are release-specific, not recurring), and **novel trigger (b)** fires on D-PhaseC5 (≥ 1 D-class decision). Routine (b) also fails, because ADR-158 had 1 commit on `origin/main`; novel (c) now fires too, since two Stage-5 ADRs are authored.

- **Differentiation posture:** Engagement **Standard** · Stage 9 review **Deep** · Stage 5 bias **ALL** · outcome window **30-day**.
- **Size bound:** `effective_pts: raw 25 × 1.15 = 28.75 → 29 — ABOVE band 15-25 by 4`. At Stage 4 it read raw 23 × 1.15 = 26.45 → 26; #7436's S → M re-size at the Collective Review raised it.
- **G3-15 disposition: keep, with rationale** — "ten cards share one tool and one cause class; a split doubles close-out-tool contention across two releases." Recorded at the Stage-4 gate and re-affirmed at the Collective Review.
- **Weights:** read from the documented default in `platform-config.toml.template [bundling].release_class_capacity_weights`.

---

## Release Outcome Statement

The approved, hub-condensed statement, verbatim from the Stage-4 decision record.

**AFTER** — Every Stage-13 close-out verdict reflects state the tooling actually read: `--no-merge` and `--dry-run` runs defer or predict their post-merge checks instead of halting, a resumed run finishes past its own merged chore PR, and a chore branch that cannot be checked out fails loudly. The report header, the Procedure 7a attestation trace, the Close-Class-Telemetry field, the orphan-cleanup dry-run and the plan verifier's FCM grade each report the same state on every path a close can take. Phase C5 locks the release's finished issue and PR threads by mechanism, with a count check that compares like with like.

**BEFORE** — Close-out phases write verdicts from state they never read — SKIPPED for a failed checkout, `N/A — dry-run or not-yet-created` for a chore PR legitimately skipped on an apply run, `declared-add-not-delivered` for a delivered file, and N/A telemetry computed before its register exists — so a spoke cannot finish a close in one pass. The Procedure 7a attestation has never reached the event log, and Phase C5 has locked threads on 2 of the last 18 closes.

**Actor(s):** Stage 13 close spokes and the hub (running the close-out driver and the orphan-cleanup tool); Stage 6/7 spokes (running the plan verifier).

**Success Indicator:** this release's own Stage-13 close reaches report generation on both the `--no-merge --apply` pass and the resumed `--apply` pass after its chore-PR merge, with no exit 3.

---

## Rollback Strategy

1. **Unit:** revert the single release merge commit (D-C SINGLE). That restores all three tools, the stage spec, the standard's § 3.2 and the ADR surfaces together. CHEAP.
2. **Host-state residue:** under E2, thread locks applied by post-merge closes survive the revert. The inverse is a per-thread unlock (REST `DELETE …/lock`). The forward-only cutover limits this to closes after the merge.
3. **Version tag:** retained, never deleted (Tag Retention). The rollback is recorded against it.
4. **Deploy targets:** none under the accepted re-home, so there is nothing to re-deploy.
5. **Superseding ADR:** the record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} reverts with the PR, together with ADR-076's `superseded_by` pointer, and ADR-076 decision 3 stands unchanged. The record {{ADR:post-merge-phases-declare-their-no-merge-behaviour}} reverts the same way; ADR-158 was never touched.

**Whole release:** a partial revert per slice; a full restore by reverting the merge; a forward fix preferred for anything well understood.

---

## Operational Deployment Manifest

**None under the accepted re-home.** Enumerated over the four `deploy.sh --deploy` classes after Plan amendment 1: 0 paths under any `skills/` tree, 0 under `packages/`, 0 under `core/rules/`, 0 under `core/hooks/`. The `release/tools/` scripts are neither rostered skills nor packages (v4.63 precedent), and the two decision records, the release-ADR index, `stage-13-close.md` and `close-class-telemetry.md` are repository-only surfaces with no deployed copy.

**`deliverable_state: deployed-copy-synced`** for every card's deliverable — reached when its change is committed on the release branch, because the release declares no propagation target (the tools run from the repository, and no deployed copy exists to sync).

**Schema migrations:** N/A — enumerated over {event-log rows, report fields, JSON report keys, plan and ADR frontmatter}. The JSON report changes (#7437's `pruned_tracking_refs` element type and its new `tracking_ref_enumeration` key; #5769's seven outcome states) have 0 in-repo consumers at the pin (#7437's design, probe P-1), and log rows stay append-only.

---

## Deviation Log

### Stage-4 entries (verbatim from the Stage-4 decision record)

| Date | Stage | Tier | Entry |
|---|---|---|---|
| 2026-09-24 | 4 | A7 path 2 | Currency-refresh amend: two members closed as already fixed removed from the milestone; description brought current; Parallelization Map added |
| 2026-09-24 | 4 | Tier 1 [ADJUST] | #6892 documentation locus re-homed from the release-hub skill to `stage-13-close.md` § Phase A7.2 |
| 2026-09-24 | 4 | Tier 1 [ADJUST] | #5910 fix scope: both writer flags |
| 2026-09-24 | 4 | Tier 1 [ADJUST] | #7182 AC-6 predicate restated; ACs of #7465 / #7436 / #7437 converted to checkbox form |
| 2026-09-24 | 4 | D-ReleaseClass | Class re-rendered `routine` → `novel`; G3-15 keep-with-rationale at effective 26 |

### Collective Review entries (verbatim from the Collective Review record)

| Date | Stage | Tier | Entry |
|---|---|---|---|
| 2026-09-25 | 5 | Collective Review | Scope locked with Plan amendment 1 (items 1–13) |
| 2026-09-25 | 5 | Tier 1 [ADJUST] | CIAC-2 widened to seven states |
| 2026-09-25 | 5 | Size | #7436 S → M; effective 29, G3-15 keep-with-rationale |
| 2026-09-25 | 5 | Minor findings | #7182 (cap-before-redact, stale claim), #5769 (open-PR intent gap, duplicate import), #5910 (cap-before-redact), #7437 (rationale wording) — resolved by items 4, 5, 7, 8, 10 or recorded here |

### Engineering entries

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **D-Version re-derived, provisional display `v4.69` → `v4.70`.** `egress-hook-batch` claimed `v4.69` at its merge `40cec0c7`. The Commit-0 re-verify recomputed next-free through the adapter at `1c3f17db` and read `v4.70` free on the binding tag arm, corroborated by the Releases and ledger arms. The Stage-4 value stays recorded in § Decision Record as the record of that instant | The Stage-4 D-Version record (the number re-derives at Engineering Commit 0); the hub's Commit-0 pre-flight | **APPLIED** — the frontmatter, the Version identity line, the Bump Class cell and the D-Version row carry `v4.70`; the Header `**Version**` cell keeps its stamp placeholder |
| **DEV-2** | **ADR allocation: 207 and 208.** `renumber-adr.py --detect` reads anchor 206 on `origin/main` and next-free 207, so #7465's record takes 207 and #5284's takes 208, +1 and +2 in slice order. At the pre-flight the `verifier-grades-what-plans-declare` branch held 207 branch-only; at Commit 0 it holds **207 and 208** (its second record landed at `804434e5`). Branch claims are detection only and never bind; whichever release merges second renumbers both of its records at its Stage-12 A.5.7 | The Collective Review ("both numbers are stamped together at Engineering Commit 0 (+1 / +2)"); the pre-flight's ADR determination; ADR-181 | **APPLIED** in § File Change Matrix — the only place the numbers appear as record identifiers; prose cites both records by slug token. The collision on both numbers is R12 |
| **DEV-3** | **Baseline moved `8e0ee084` → `1c3f17db`.** 26 commits and 13 files landed between the Stage-4 pin and the branch base — `egress-hook-batch`'s merge and its Stage-12 chore. **0** of them are in the write set; one read-only input, `release/releases/RELEASE_LOG.md`, moved (its `v4.69` row). The designs' line citations stand: all 8 edited paths are blob-identical at both commits | The pre-flight's baseline determination; the Stage-6 A3 snapshot | **RECORDED** — § Baseline pin carries both SHAs |
| **DEV-4** | **The editability refresh owed at the Collective Review turn** was recorded by the hub before the first Stage-6 brief (the Commit-0 pre-flight), not at the Collective Review itself. It re-ran Stage-4 § 5.9 over the four cards whose write sets Plan amendment 1 changed. This commit transcribes it and re-checks it at `1c3f17db`: both control hooks unchanged, every card `unconstrained` | The pre-flight's editability determination; `hub-spoke-bridge.md` Procedure 4 (editability currency) | **APPLIED** — § Implementation Sequence → Agent-Editability Read |
| **DEV-5** | **FCM promotion:** the record {{ADR:post-merge-phases-declare-their-no-merge-behaviour}} — an `add` under `release/ADRs/`, for #7465, slice 6. Stage 4 carried it as `CONDITIONAL:ADR-RECORD-FORM-NEW` with a placeholder number | Plan amendment 1 item 12; authoring rule 5 (a fired conditional is promoted in the same commit) | **APPLIED** — unconditional in § File Change Matrix, with its concrete path. `declared-add-not-delivered` until slice 6 lands it |
| **DEV-6** | **FCM promotion:** the record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} — an `add` under `release/ADRs/`, for #5284, slice 7. Stage 4 carried it as `CONDITIONAL:C5-SUPERSEDES-ADR-076` with a placeholder number | Plan amendment 1 item 12; authoring rule 5 | **APPLIED** — unconditional in § File Change Matrix, with its concrete path. `declared-add-not-delivered` until slice 7 lands it |
| **DEV-7** | **FCM promotion:** `release/ADRs/ADR-076-comment-author-association-trust-boundary.md  edit` — its `superseded_by` pointer only. Stage 4 carried it as `CONDITIONAL:C5-SUPERSEDES-ADR-076` | Plan amendment 1 item 12 | **APPLIED** — unconditional in § File Change Matrix |
| **DEV-8** | **FCM row added:** `release/ADRs/README.md  edit` — the generated release-ADR index, regenerated by `generate-adr-index.py --write` in slices 6 and 7, never hand-edited. Stage 4 carried no row for it, because it carried no unconditional release-ADR record | Stage-6 C4 ADR-index beat (a release that adds a record under `release/ADRs/` declares the index EDIT in its matrix); the pre-flight's editability determination (#7465 and #5284 gain the index) | **APPLIED** |
| **DEV-9** | **FCM promotion:** `release/references/standards/close-class-telemetry.md  edit` — § 3.2, whose emit-mechanism sentence is normative and omits `--retro`. Stage 4 carried it as `CONDITIONAL:TELEMETRY-ORDER-NORMATIVE` | Plan amendment 1 item 12 | **APPLIED** |
| **DEV-10** | **FCM drop:** `release/tools/compute-close-class-telemetry.sh` leaves the obligation set — under D-Telemetry-Pair K, held at Stage 5, the tool-side edits belong to #5586 | Plan amendment 1 item 12; D-Retro-Owner hold K | **APPLIED** — carried as `NOT EDITED` in the release-wide non-scope block |
| **DEV-11** | **FCM drop:** `release/references/how-to/hub-spoke-bridge.md` (Stage 4: `CONDITIONAL:C5-RETIRED`) leaves the obligation set — C5 is enforced, not retired | Plan amendment 1 item 12; D-PhaseC5 E2 | **APPLIED** — `NOT EDITED` |
| **DEV-12** | **FCM drop:** `release/ADRs/ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md` (Stage 4: `CONDITIONAL:ADR-RECORD-FORM-HYGIENE`) leaves the obligation set — it stays byte-untouched, and #7465's decision gets its own record | Plan amendment 1 item 12; the Collective Review ADR decision | **APPLIED** — `NOT EDITED` |
| **DEV-13** | **FCM drop:** `release/skills/release-hub/references/orchestration-playbook.md` and `packages/release-hub.skill` (Stage 4: `CONDITIONAL:REHOME-DECLINED`) leave the obligation set — the re-home was accepted at Stage 4. Their two § Agent-Editability Read rows are removed with a note | Plan amendment 1 item 12; Stage-4 Tier-1 [ADJUST] 1 | **APPLIED** — `NOT EDITED` |
| **DEV-14** | **`stage-13-close.md` stays one edited file, and #7437 joins its row.** The row's label now names #7437's one § Phase C4 sentence alongside C5, the Phase B note and § Phase A7.2 | Plan amendment 1 item 12 ("unchanged in shape"); item 8 | **APPLIED** — § File Change Matrix and § Contention Map |
| **DEV-15** | **Verification Plan rows carry the ratified values.** #7437 AC-2 reads **2 = 2** where Stage 4 read 1 = 1: the fixture carries one ref stale now and one made stale by the same run (the #7437 design's R-4, item 8). The rows items 1–10 amend carry the amended method or expectation, and the D-PhaseC5 alternatives are replaced by E2: #5284 AC-2 keeps only the enforce limb and #4768 AC-2 drops its retire-case deferral | Plan amendment 1 items 1–10; AC-Binding (an amended criterion or method obliges its bound row in the same change); the Stage-4 D-PhaseC5 decision | **APPLIED** — § Verification Plan. No criterion's text changes |
| **DEV-16** | **The A1–A2 checkpoint is presented after the fact.** The Stage-6 shard asks for A1–A2 to be presented before B1; the operator's scope-lock and the Stage-6 shape decision authorize Commit 0 → slice 1 end to end, so the hub's brief directed it without a pause | The Collective Review scope-lock; D-Stage6-Shape A | **RECORDED.** A1 (entry contract) and A2 (the container determination, § Implementation Sequence) are in this file and in the Stage-6 output comment on #7686; an A1 HOLD would still have stopped the run |
| **DEV-17** | **CIAC-1 and CIAC-5 lose their condition.** Stage 4 wrote them as applying to #5284 "when C5 is enforced" and `CONDITIONAL:C5-ENFORCED`; D-PhaseC5 E2 enforces C5, so both now name #5284 unconditionally. CIAC-5's method also names item 3's NM-5d, and its predicate names the `_nm_defer` opening from item 1 | The Stage-4 D-PhaseC5 decision; Plan amendment 1 items 1 and 3 | **APPLIED** — § Cross-Issue Acceptance Criteria |
| **DEV-18** | **PR-body issue-reference form: `References #N` for every card, with a Stage-13 closure sentence.** Part 3's Delivery Strategy asked for a close keyword per open member. Close-out phase 14, `manual_close_release_issues`, closes the release issues at Stage 13 with a structured comment; a close keyword would auto-close them at merge and pre-empt it. This matches the two most recent release PRs | The hub's Stage-6 brief; close-out phase 14 | **APPLIED** — the release PR's Issue References block |
| **DEV-19** | **A2 container: the per-issue Stage-6 sub-tasks, rendered as PR-body checklist rows.** The threshold predicate, read literally, selects the sub-issue container; the hub already scaffolded one Stage-6 sub-task per card, so no further sub-issue is created | The hub's Stage-6 brief; the scaffold record; the exemplar release's determination for the same shape | **RECORDED** — § Implementation Sequence |
| **DEV-20** | **The version re-verify's Releases-arm control moved from `v4.69` to `v4.68`.** `v4.69`'s Release publishes at its Stage-13 close, which has not run, so that arm reads 0 for `v4.69` and could not show its own sensitivity there | Probe-validity discipline (a sensitivity arm that reads zero proves nothing) | **RECORDED** — § Commit-0 Version Re-Verify Record |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #7437 | `release/references/pipeline/stage-13-close.md` § Phase C4 — one sentence naming the cleanup dry-run's prune projection and stating that its rows are repo-wide (item 8) | PENDING — slice 1b | — | the tool's own `--help` header and close-out phase 16's PASS note change in the same slice; neither is K1 corpus |
| #7182 | none declared ("None expected" on the card) | PENDING — slice 2 | — | the idempotence claim in the close-out driver's header is qualified or upheld in-tool (AC-5, item 10) |
| #7436 | none declared on the card | PENDING — slice 3 | — | write set is `automated-closeout.sh` only |
| #5769 | none declared on the card | PENDING — slice 4 | — | write set is `automated-closeout.sh` only |
| #5910 | none declared (the card notes that any description of Procedure 7a's attestation as auditable is aspirational until the fix lands) | PENDING — slice 5 | — | write set is `automated-closeout.sh` only |
| #7465 | `stage-13-close.md` Phase B deferred-set note · the new record {{ADR:post-merge-phases-declare-their-no-merge-behaviour}} · the regenerated `release/ADRs/README.md` | PENDING — slice 6 | — | the card's declared doc is the post-merge phase list, which the declared membership predicate replaces |
| #5284 + #4768 | `stage-13-close.md` § Phase C5 (#5284's Change 2 plus #4768's batch-CLI-limits sentence) · the new record {{ADR:lock-at-close-is-a-close-out-phase-over-every-milestone-thread}} · ADR-076's `superseded_by` pointer · the regenerated index | PENDING — slice 7 | — | "whichever way C5 resolves, the stage spec must match what the tooling actually does" (#5284's declaration) |
| #6892 | `stage-13-close.md` § Phase A7.2 · `close-class-telemetry.md` § 3.2 | PENDING — slice 8 | — | the card declares that the close-class telemetry spec should state which phase the register must exist by |
| #6257 | the constraint that the default range is valid only pre-merge, stated where a Stage-13 reader meets it (the card's declaration) | PENDING — slice 9 | — | resolved against the merged verifier after the sibling release lands |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification; extended at Stages 7, 8 and 12.*

| Check | Result |
|---|---|
| **Commit-0 version half** | `git fetch --tags origin` and `git fetch origin main` (exit 0); the adapter's dry-run recomputes **`v4.70`** for bump-class `minor`; the slot is free on all three `claimed_set()` arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | `bash release/tools/claim-version.sh --verify-stamp closeout-verification-rows-consistent` → **exit 0**, *"verify-stamp OK — closeout-verification-rows-consistent carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))"*. Exactly one double-brace `RELEASE_VERSION` placeholder in this file, in the Header `**Version**` cell; every other mention uses the named form |
| **Plan-driven executor at Commit 0** (pre-commit) | `bash release/tools/verify-release-plan.sh --format=md --merge-base origin/main --stage4-comment <the three Stage-4 parts, concatenated> <this plan>` → **9 PASS / 10 FAIL / 2 SKIP / 29 ERROR** (exit 3). Run twice: the first run read CIAC-5's method as invoking a tool named `defer`, because a backtick span in the text this commit added looked like a command; the backticks were removed and the second run reads it as a documented-decision method. The counts are the same in both runs. Each non-PASS row is classified: **FAIL 10** — FCM-1 (this plan, not yet committed at that instant) and FCM-2 / FCM-3 (the two decision records, delivered at slices 6 and 7) are declared ADDs not yet delivered, expected at Commit 0; #5910 AC-1, #5284 AC-2, #4768 AC-2, CIAC-2, CIAC-3 and CIAC-4 are pre-fix counts that slices 5, 7, 7, 4, 3 and 7 change, expected at Commit 0; #7182 AC-6 is `deploy.sh --check` exiting 1 on the base tree (next row). **SKIP 2** — CIAC-1 invokes `bash`, outside the executor's read-only verb set, so its verdict is the close-out driver's own self-test; CIAC-5 is a documented-decision method. **ERROR 29** — `unclassified-method` on the self-test arms and named reads, which the executor's closed read-only verb set cannot run by design; their verdicts come from the tools' own suites at each slice and at Stage 7. **PASS 9** — FCM coverage (21 declared, 21 interpreted, 0 uninterpreted, 0 pathless) and the four provenance rows are real verdicts. The four per-issue PASS rows are graded on the grep's exit status, not against their Expected cells: #5769 AC-1 reads 3 and #4768 AC-1 reads 1, the pre-fix control values, so those two PASSes carry no evidence until slices 4 and 7. No row is a parse error on a section this commit wrote |
| **#7182 AC-6 baseline — `deploy.sh --check` on the Commit-0 tree** | `bash core/deploy/deploy.sh --check` → exit 1, **2** `  FAIL:` lines out of 816 output lines (372 `  OK:` lines, so the reader reads the run): `release-body-drift` (13 published Release bodies diverged from their notes; names no path) and `count-structure` (names `core/references/reference/operator-instance-home-and-isolation-key.md` and `release/references/standards/release-notes-standard.md`). **Neither names a path in this File Change Matrix** — python intersection of the paths each line names with the 11 matrix paths → 0; control: a planted FAIL line naming `release/tools/cleanup-orphan-state.sh` → 1. Both are the pre-existing classes the v4.68 plan recorded. This is AC-6's control arm: the pre-existing FAIL set at the release base, against which each slice's run is compared |
| **Provenance survival** | PRESENCE PASS (1 label) · GRAMMAR PASS (Form X, date 2026-09-25) · DELTA PASS. **The delta verdict was re-computed independently**, because on this host the executor's delta limb reaches `prov-no-loss` without comparing: it hands a multi-line value to `awk -v`, which the macOS system awk rejects as fatal (`newline in string`, exit 2), so the lost set it reads is empty whatever the inputs. Measured: a planted `have = a,b,c` against a comment set `a,d` returns nothing where `d` is expected. Re-computed with the executor's own five element predicates: the Stage-4 comment carries 4 elements and the plan carries all 4 (plus the stamp manifest); control — a planted copy of this plan without its `CIAC-` tokens loses exactly `ciac`. The construct is on `main` and on the `verifier-grades-what-plans-declare` branch; it is routed to the hub, not changed here |
| **Structural lint** (python, over this file) | one stamp placeholder, in the Header `**Version**` cell · one `domain_practice` label · the two decision records' numbered identifiers appear only in their FCM rows · both slug tokens match the FCM filenames and none sits in a link target · 0 markdown links · 0 raw GitHub URLs, home paths, email addresses, operator handles or private-upstream slugs · no declared ADD written off · every table row matches its header's cell count. Each check ran with a planted control that must fire (the placeholder counter, the email pattern, the pipe-parity counter and its escaped-pipe case) |
| **A3 file-state snapshot** | all 8 edited paths of the matrix are blob-identical at `8e0ee084` and `1c3f17db` (for example `automated-closeout.sh` `03ba3b17`, `cleanup-orphan-state.sh` `92375e70`, `stage-13-close.md` `06f8fdaf`), so no design pinned at `8e0ee084` has drifted |
| **AC baseline re-read** | the ten live issue bodies carry **37** checkbox criteria under one `### Acceptance Criteria` heading each, equal to the Stage-4 baseline; the body-wide checkbox count per card equals the section count, so no criterion sits outside the heading |
| **ADR allocation** | `python3 release/tools/renumber-adr.py --detect` → `ANCHOR 206 origin/main` · `NEXT-FREE 207` · `CLAIMED-SET-BRANCH-ONLY 207,208 (detection only — never binds)` · `CLAIM - NONE (this tree adds no ADR)`. The branch-only set is the sibling `verifier-grades-what-plans-declare`'s two records |
| **Editability re-check** | both control hooks → 0 diff lines since `8e0ee084` (control → 1); the 11 write-set paths → 0 Tier-0 and 0 skill-scope matches (controls → 2 and 2) |

---

## Baseline pin

**Stage-4 pin:** `origin/main` @ **`8e0ee084`** (`8e0ee08450a5e1d64f352279a3ab0f4a6ce46f6d`), measured at Stage-4 Phase A0 and used by every Stage-5 design. Read by the Stage-9 mid-pipeline divergence re-check.

**Branch base:** `origin/main` @ **`1c3f17db`** (`1c3f17db7ad7a62f6e747c4824f94f61cfc95423`) at Engineering Commit 0 — the release branch was cut from exactly this commit.

**Movement between them:** 26 commits and 13 files, all from `egress-hook-batch`'s merge and its Stage-12 chore. **Intersection with this release's write set: 0 paths** (python3 set intersection over the 13 moved paths and the 11 write-set paths; control: the same intersection with one known-moved path added → 1). One read-only input moved — `release/releases/RELEASE_LOG.md`, which gained the `v4.69` row; #6257 reads that file and never writes it. The 8 edited paths of the matrix are blob-identical at both commits, so the designs' line citations stand (DEV-3).

---

## Issue References

The ten content members are transitioned to closed at Stage 13 by the release close-out, not by the release PR's merge.

- **#7465** — close-out phase 15.55 asserts anchor parity under `--no-merge` and `--dry-run`, halting on a state it deferred. Five acceptance criteria.
- **#7437** — the orphan-cleanup dry-run does not project the prune phase. Three acceptance criteria.
- **#7436** — the close-out driver cannot be resumed after its own chore-PR merge. Three acceptance criteria.
- **#7182** — the close-out chore-branch phase reports SKIPPED for a checkout it failed to perform. Six acceptance criteria.
- **#6892** — Close-Class-Telemetry is injected before the retro register exists. Three acceptance criteria.
- **#6257** — the plan verifier's FCM check emits a false FAIL after merge. Three acceptance criteria.
- **#5910** — the Procedure 7a attestation is never recorded. Four acceptance criteria.
- **#5769** — the report header misdescribes a legitimately skipped chore PR. Three acceptance criteria.
- **#5284** — Stage 13 Phase C5 thread-locking has not fired. Four acceptance criteria.
- **#4768** — Phase C5's count verification compares unlike counts. Three acceptance criteria.
- **#4703 · #5768** — the two members closed as already fixed before Stage 4 and removed from the milestone at the Stage-4 currency refresh.
- **#5586** — the `telemetry-is-computable` card that narrows to its part 2 under D-Telemetry-Pair K.
- **#6871 · #4917** — the `controls-fail-loud` cards region-adjacent to #7436's chore-PR state read.
- **#7855 · #7856 · #7857 · #7858** — the four follow-up observation cards filed under the Collective Review.
- **#7682** — the Stage-4 planning sub-task carrying the approved plan and every hub decision record transcribed here.
- **#7685 · #7689 · #7693 · #7697 · #7701 · #7705 · #7709 · #7713 · #7717 · #7721** — the Stage-5 sub-tasks carrying the ten designs, their adversarial reviews and their lock records.
- **#7686 · #7690 · #7694 · #7698 · #7702 · #7706 · #7710 · #7714 · #7718 · #7722** — the Stage-6 sub-tasks, one per card, that carry each card's Engineering decomposition.
