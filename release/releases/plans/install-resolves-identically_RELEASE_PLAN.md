---
title: Release Plan — install-resolves-identically (install, deploy and guard decisions resolve from the subject they govern)
type: release-plan
plan_type: release
status: IN PROGRESS — Stage 6 Engineering (Commit 0)
release: versioned (bump-class minor; provisional display v4.70; the concrete number binds at the Stage-12 atomic claim)
milestone: install-resolves-identically
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH — every row is a bounded edit to tracked files, or a new file, on one branch with one merge, so `git revert -m 1` of the merge restores `main`. Two hook changes (#7497's target-keyed -019 and #6440's memory-store arm) are MODERATE at ship time because a revert must be followed by a hook republish, and two changes leave state outside git (#6896's checkout-root layouts, #5265's install-record key). Each is qualified in § Rollback Strategy. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `install-resolves-identically`

**Milestone:** `install-resolves-identically` · milestone #338 · Stage-4 sub-task **#7684** = the approved plan (parts 1–2) and every decision record of this release · **#7750–#7764** = the eight Stage-5 designs · **#7859–#7866** = their eight adversarial reviews · **#7766** = the Stage-6 Engineering sub-task whose spoke authored this file (Commit 0), ahead of #6896's slice.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.70`**. The Stage-4 provisional `v4.69` was claimed by `egress-hook-batch` (PR #7638, tag `v4.69` on its merge commit), so the Collective Review re-determined the display. It is recorded as a determination (not a click-gate). The concrete `vX.Y` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp placeholder. Four other open releases display the same provisional slot — PRs #7901, #7895 and #7839 (named in the Collective Review record) and #7919 (opened since). The Stage-12 atomic claim serializes them; the loser re-versions forward. The Commit-0 re-verify ran in full, both halves — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/install-resolves-identically`), one PR opened in draft at Commit 0 so CI runs while the slices land, one merge, base `main`. This plan lands as **Engineering Commit 0**; #6896's slice runs next on the same branch, then the other seven in serial order.

**Concurrency posture:** **P0 fully-serial**, one spoke in flight at a time (W_max 1, the operator's pacing decision recorded as DEV-15). Every non-serial posture prohibits force-push on the shared release branch; P0 is in force.

**Release class:** `cross-cutting`, ratified at the Stage-4 gate. Stage 9 review depth **Deep**. See § Release Class declaration.

> **Provenance.** This file transcribes the approved Stage-4 Release Planning output on #7684 (comments 5826287871 and 5826288647) and every decision record on #7684: the Stage-4 gate Decision Recorded (5826471133), the deviation-log addenda (5826554941, 5829665231, 5839221431), the Stage-5 launch-shape and quota-gate records (5826801615, 5829477009), the Collective Review evidence record (5840282367, 5840282806, 5840283143) and its Decision Recorded (5841113925), the Stage-6 entry record (5841775627) and the quota-to-cap Decision Recorded (5841863468). It is reconciled to the eight Stage-5 designs and their eight adversarial reviews. **Where a source's wording is ambiguous, the Decision Recorded governs the design and the design governs the review;** each such resolution is listed in § Decision Record → Transcription interpretations. Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority. Every thread comment consumed was `OWNER`-authored (Comment-Ingestion Trust Boundary). Security-relevant detail from the designs and reviews is not carried here; an in-scope fix is stated only at the level its rendered decision states it.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — provisional display v4.70 (the Stage-4 provisional v4.69 was claimed by `egress-hook-batch`); binds at the Stage-12 atomic claim |
| **Date Created** | 2026-09-24 (Thursday) — the Stage-4 plan of record; transcribed at Engineering Commit 0 on 2026-09-26 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | In progress — Stage 6 Engineering, Commit 0 |
| **Branch** | `release/install-resolves-identically`, created from `origin/main` `35dbf418` |
| **PR** | Opened in **draft** at Commit 0 per the SINGLE topology; its number is recorded on #7766. It transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `install-resolves-identically` (#338) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-24, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every write-set path is an internal `pmo-platform` artifact. The dominant class is executable behaviour — hooks, install and update scripts, a deploy tool and test harnesses — which resolves `domain-best-practices/software.md`; the secondary class is governance text (rules, standards, specs and pipeline references). Transcribed from Stage-4 Phase A1.5 and carried forward unchanged by all eight Stage-5 designs (§ 5.7). No Mode-B label existed to upgrade.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (steps 1–3, then 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `35dbf418`, the Collective Review assembly base (the Stage-4 pin was `8e0ee084`) |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 35dbf41847df2c1deab792d2944e46ac6ddd26fd --bump minor --dry-run`, run with `CLAIM_REPO=<owner>/<repo>` so the claimed-set read uses the REST arm (the adapter's own `anchor()` + `claimed_set()`; no tag pushed) | **`v4.70`** — "would claim v4.70 (no tag pushed)"; equal to the planned display |
| **3** | HALT on collision: the planned version must be absent from every `claimed_set()` arm AND equal the recomputed next-free. The tag arm binds; published Releases and the RELEASE_LOG corroborate | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.70*'                     (tag arm — binds)
             the published-Releases list, REST, paginated → tag names v4.70*     (Releases arm)
             v4.70 followed by a non-digit or end of line, over the ledger read
             with git show origin/main:release/releases/RELEASE_LOG.md           (ledger arm)
Denominator: 214 v* origin tags (peeled refs excluded); 212 published Releases (paginated,
             so the read is not truncated); RELEASE_LOG at origin/main, 2618 lines
Control - sensitivity: the SAME three readers on the v4.69 slot — tag v4.69 present (the
             annotated tag peels to 40cec0c7, the egress-hook-batch merge); Releases 1;
             ledger 5 lines. Every arm resolves and returns non-zero, so a zero on the
             v4.70 slot is a real negative
Control - specificity: the ledger pattern over a planted pair of lines, one naming v4.700
             and one naming v4.70 → 1 (the v4.70 line only). Tag and Releases arms: NOT
             TRIGGERED — an exact slot tuple has no near-miss class beyond the glob, which
             is broader than the tuple, so its zero implies the tuple's zero
Extraction:  the full ls-remote output; the full paginated Releases list; the full ledger
             read from origin/main (never the worktree copy)
Result:      0 occupants of the (4,70) slot on every arm; v4.71 through v4.79 → 0 on the
             Releases arm
Verdict:     CLEAN — v4.70 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** `git ls-remote --heads origin 'release/*'` → **4** heads (`controls-fail-loud`, `telemetry-is-computable`, `closeout-verification-rows-consistent`, `verifier-grades-what-plans-declare`); this release's head was absent before creation (0; control: `main` → 1). Open PRs → **4**, all draft, all OWNER-authored — the same four branches (§ In-Flight Release Roster).

**ADR numbering (Q3) — nothing is allocated at Commit 0.** The mainline anchor at `35dbf418` is 206: 206 ADR files across `core/ADRs/` and `release/ADRs/`, maximum 206, no duplicate and no gap (control: the two directory READMEs are excluded by the ADR-file pattern). At Commit 0 the `verifier-grades-what-plans-declare` draft branch (ms#405, PR #7839) holds four `release/ADRs/` numbers, 207 through 210 — the Collective Review measured three — and ms#395 plans two more. This release's three records are numbered literally at authorship, in serial order (#5265, then #5274, then #6440), and cited in prose by the ADR slug token (the double-brace `ADR:` form); Stage-12 A.5.7 reconciles if another release merges ADRs first.

### Manifest half (step 3b, post-write / pre-commit)

`release/tools/claim-version.sh --verify-stamp install-resolves-identically` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder instead of reproducing it. The claim tool resolves the token by global substitution across the whole file, so a literal prose citation would be rewritten at Stage 12 along with the record site.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, no Mode-B rationale required) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..6`, as corrected by Q5) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (AC-bound per-issue rows, the AC baseline, the Q5 corrections) | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin |

---

## Scope

**Eight members, one root-cause class** — C19, a scope predicate anchored on invocation context rather than on the governed subject. Zero native dependency edges (16 reads, with a live control); the edges below are derived from shared surfaces and composition.

| # | Issue | The defect this slice removes | Size (pts) | Design · review |
|---|---|---|---|---|
| 1 | #6896 | The hook-suite layout helper's documented invocation is refused by BLOCK-DESTRUCTIVE-022: the default sandbox is an unallowlisted temp path, and the documented runner line carries a variable | S (2) | #7750 · #7859 |
| 2 | #4993 | The standing install regression reports FAIL under its own sandboxed HOME, while its R-8 safety proof passes on an empty subject | M (4) | #7752 · #7860 |
| 3 | #4994 | An unattended (`--non-interactive`) install hangs when stdin is open: three human-answer prompts are unguarded | M (4) | #7754 · #7861 |
| 4 | #5265 | `[PMO_PLATFORM_ROOT]` resolves by self-location, so a refresh run from a worktree bakes that worktree's path into deployed surfaces | S (2) | #7756 · #7862 |
| 5 | #6168 | The composed script allowlist depends on which checkout ran the refresh, and the refresh does not say which root it bound | S (2) | #7758 · #7863 |
| 6 | #5274 | The skill-editor exemption list resolves to four paths across five consumers, and the update completeness gate covers the hook tier only | L (8) | #7760 · #7864 |
| 7 | #7497 | BLOCK-DESTRUCTIVE-019's worktree exemption keys on the session's working directory instead of the write target | M (4) | #7762 · #7865 |
| 8 | #6440 | Evicting an auto-memory entry — a Trash move — is structurally unexecutable: the deletion-containment hook refuses every target outside the workspace root | M (4) | #7764 · #7866 |

**Size:** 30 raw points → **effective 39** (`round_half_up(30 × 1.3)`, class `cross-cutting`), above the 15–25 band. The G3-15 Override is re-recorded at 39 (Q10), superseding the Stage-4 Override at 30 (DEV-1). The resizes: #6896 XS → S, #7497 S → M, #5274 M → L.

**Acceptance criteria.** 35 criteria across the eight cards: #6896 3 · #4993 5 · #4994 6 · #5265 4 · #6168 4 · #5274 5 · #7497 5 · #6440 3. The criteria's single home is each issue body; § Verification Plan binds each one by ordinal and never restates it.

**Explicit non-scope.**
- #6198 (ms#402): a co-discharge candidate for #5274's end-to-end arm and layout materialization. It is not pulled in; AI-001 grades it at Stage 13.
- #5633 (ms#366): the enforcing-first hazard notice was posted at the Collective Review (Q11).
- F1, the other five vacuous row-5 live-install detectives, routed as a follow-up (Q7).
- The worktree-base drift at `core/rules/git-workflow.md:39`, routed out under the N-way R14 override (Q9).
- #6440's stated residual: eviction has no read-back.
- #5185's ARCHIVE destination (ms#352).

---

## Decision Record

### Stage-4 gate (operator, 2026-09-24)

| Decision | Outcome |
|---|---|
| D-Capacity | **keep all 8 — Override** (G3-15 disposition C) at effective 30. Re-rendered at the Collective Review at 39 (Q10) |
| D-Outcome | **adopt the draft**, unchanged. Clause 2 of its Success Indicator was later replaced (Q4) |
| Plan approval | **approve + apply the card corrections** (DEV-6) |
| D-ReleaseClass | **`cross-cutting`** |
| D-C Branch Topology | **SINGLE** — one branch, one PR |
| D-Concurrency Posture | **P0** |
| D-Version | recorded determination: versioned · `minor` · provisional `v4.69`. Re-determined `v4.70` at the Collective Review |

### Stage 5 (operator, 2026-09-24 → 2026-09-25)

- **Launch shape** (#7684 comment 5826801615): eight designs plus eight Phase A6.5 adversarial reviews, per-card dossiers, card-targeted governance reads, opus at MAX effort.
- **Quota gate** (#7684 comment 5829477009): one lane per window, superseding the four-lane width; the rest of the launch shape stands.

### Collective Review scope-lock (operator, 2026-09-25)

**Scope-lock: LOCKED.** Every decision took the recommended option. The N-way table's 15 `disagreement` rows are cleared by the decisions below, and N-way row R14 by an override: "Override: convention `core/rules/git-workflow.md:39` worktree base accepted as diverged because it is routed out of this release (Q9) rather than corrected in #7497's slice. Deviation logged for Stage 13 retrospective."

| # | Decision | Rendered |
|---|---|---|
| Q1 | Where HOME-override runs and RED-first observations execute | CI as the observer: RED and GREEN are read from the PR's check runs; any local run sets `PMO_REGRESSION_EMIT=0` |
| Q2 | #6896 layout default | α with #7859's amendments: freshness digest and LAYOUT-FRESH-01, one recorded footprint that #5274's step 3b writes through, identity checks, re-baselined arm counts, and a scoped executor-safety carve-out |
| Q3 | ADR numbers | literal numbers at authorship, in serial order; prose cites the ADR slug token; Stage 12 reconciles if another release merges ADRs first |
| Q4 | Success Indicator, clause 2 | replaced by a Stage-12 real-instance observation (#7863 CD-2 (a)) |
| Q5 | One Tier-1 [ADJUST] at Engineering Commit 0 | approved; CIAC-3 graded by the independent oracle (#7862 FM-4); the remaining Minor findings go to the deviation log |
| Q6 | #4994's stdin census vs #5265's tab split | REC-6 adopted; P-10 treats a redirect-fed `read` as a data read (#7861 FM-1 (a)) |
| Q7 | #4993 D-5 scope | D-5 (a) with truthful, scoped map text; follow-up F1 carries the other sites |
| Q8 | #5274 legacy reconcile | its own phase after `refresh_hooks` (#7864 CD-1); `--surfaces-only` omits it or detects and WARNs |
| Q9 | #7497's working-directory claims; the stale worktree base | #7865 FM-3's qualification; the `git-workflow.md:39` drift is routed out (the N-way R14 override above) |
| Q10 | D-Capacity | all 8 kept; #6896 → S, #7497 → M, #5274 → L; the G3-15 Override is re-recorded at effective **39** (raw 30 × 1.3), superseding the Stage-4 Override at 30 |
| Q11 | Cross-milestone notices (AI-002) | the #5633 notice only; #6198 stays with AI-001 at Stage 13; this milestone's Parallelization Map is refreshed |
| Q12 | Security-relevant items | handled outside this plan; no detail is carried here |
| Q13 | Uncontested per-card recommendations | ratified as listed in the evidence record (§ 10, Q13) |
| Q14 | #4994 REC-3 / REC-7 / REC-8 | E66 — exit 66 with nothing modified, the schema-mismatch trigger named; REC-7 declined; REC-8 acknowledged |
| Q15 | #5265 record-first resolution | C3 plus #7862 CD-2 (a record-provenance key) and CD-1b (remedy text names `--force-regen`) |
| Q16 | #7497 Layer-1 write guard | target-only keying approved as an explicit tightening — three shipped arms invert — with two-view input (B) plus FM-1's root fix and FM-2's arms, the roadmaps carve-out (a) with FM-4, and #7865 CD-2 |
| Q17 | #6440 memory eviction | α — a Trash-only arm, item 8a and a core ADR — with #7866 CD-2 (an admission log) and FM-3 |

**Version:** provisional v4.70, because `egress-hook-batch` took v4.69; the Stage-12 atomic claim decides.
**Ledger:** AI-002 discharged (Q11). AI-003 step 1 discharged by the evidence record's routing register; step 2 opens as AI-004. AI-005 is superseded by AI-006 (DEV-14).

### Per-card rendered decisions

| Card | Rendered at the scope-lock | Carried into |
|---|---|---|
| #6896 | **Q2 (a) α** with #7859's amendments — FM-1: a build digest recorded inside the owned directory plus the `LAYOUT-FRESH-01` arm, and "both commands, in order, every time" with the harness's minutes-scale runtime stated in USAGE and row 3; FM-2: an ownership marker written first, every write routed through one function that appends to an owned footprint, the purge removing exactly that list, a `git check-ignore` arm over every recorded path, a refusal naming trash-then-rerun, and #5274's step 3b writing through the same function; FM-3: identity checks rather than path strings; FM-5: re-baselined arm counts with the arm IDs declared; FM-7 (a): the scoped executor-safety carve-out — the hub directive and the Spoke Template permit the helper's default site inside the spoke's own worktree, and the ban on the live workspace and `$HOME` stays. Carried under every option: D-Guard reads the account home, not `${HOME}` (#7860 routed 4); D-Mirror; the `.gitignore` entries. **Q13:** D-Mirror (V-5's premise MEDIUM), D-CI-Layout (ii), D-Row3, D-Allowlist-Comment with #7859 PR-2's wording, the `.gitignore` entries, the `test-runner.sh` comment, no ADR | FCM #6896; slice 1; #6896 AC rows; CIAC-4, CIAC-6 |
| #4993 | **Q7 (a)** D-5 (a) with truthful, scoped map text: the § 3 sentence states the condition a detective must meet to be named in a cell; row 5 names the durability member's proof as the conforming detective; the Notes state, as current fact, that five members' own live-install proofs still take their subject from `$HOME`; F1's criteria gain "update row 5 when the last one is repaired". Carried: #7860 FM-1's in-suite CI arm on the resolver, recording `r8: caller` when a caller set the subject; #7860 FM-7 (F1's population includes the second subject at `test_refresh_surfaces.sh:129`); #7862 FM-3 (Arm 6's backstop). **Q13:** D-1 C, D-2 (b) `r8_finish`, D-3 (the verdict stamp and env vocabulary), D-4 as scoped by Q7, D-6 (the stage-07 edit). **Q1** locus; **Q5** corrections | FCM #4993; slice 2; #4993 AC rows; CIAC-2 |
| #4994 | **Q6 (a)** REC-6 adopted: P-10 treats a `read` whose own line carries input redirection as a data read, and its fixture carries #7861 PR-1's must-flag lines and FM-1's must-not-flag line. Carried: #4994's downstream-contract sentence is corrected (a flag-only branch would leave #5265's root empty), and #5265 never records an empty root. **Q14:** REC-3 E66; REC-7 declined; REC-8 acknowledged (Structural by count: 112 first-order, 693 second-order). **Q13:** REC-1 G1, REC-2 ND2, REC-4 (the open-stdin harness), REC-5 (Case 12 unedited), REC-9 (routing), REC-10 | FCM #4994; slice 3; #4994 AC rows; CIAC-2, CIAC-3 |
| #5265 | **Q15 (b)** C3 record-first + #7862 CD-2: an additive `source_repo_path_source` key; a legacy record without the key is used only when tier 5 cannot resolve or agrees with it, otherwise a WARN names both roots — and CD-1b: the remedy texts name `--force-regen` and `docs/UPDATE.md` § 6.1 is retitled. Tier 2 adds `core/deploy/qa/checks.py` (#7862 PR-4). **Q13:** D-Git-Mechanism with PR-2's identity fix, D-Threading, D-Laziness, D-Refusal-Predicate with PR-5, D-Exit-Codes 3/65/66, `STATE_SCHEMA_VERSION` unchanged. **Q3:** the ADR is the first of three | FCM #5265; slice 4; #5265 AC rows; CIAC-1, CIAC-3 |
| #6168 | **Q13:** D-Report-Content (c), D-Identity-Scope S2, D-Control K2, D-Vacuity V3, D-AC2-Method RE, D-Env-Scrub, D-Landing L1, D-Unit-Arm. Its own file set is `update.sh` and `test_refresh_surfaces.sh`; its A-1..A-8 amend #5265's Change 8 (L1), and **the hub issues ONE merged Change 8 text before #5265's slice** (#7863 FM-5). A-3 matches the named member by basename; each Arm 8 refresh runs from its own tree | FCM #6168; slices 4–5; #6168 AC rows; CIAC-1 |
| #5274 | **Q8 (b)** #7864 CD-1: the legacy reconcile is its own named phase after `refresh_hooks` in the full flow; it retires the legacy file only when the deployed hook is byte-identical to source and the co-deployed lib is present; `--surfaces-only` omits it or detects and WARNs; the hook-read declaration stays in `lib-instance-path.sh`. Carried: E2E-6, an arm that exercises production root derivation. **Q13:** D-Exemption-Resolver C1 with PR-1's residuals recorded in the ADR, D-Hook-Root, D-Resolve-Isolation, D-E2E-Arm plus E2E-6. **Q5** corrections. **Q3:** the ADR is the second of three | FCM #5274; slice 6; #5274 AC rows; CIAC-4, CIAC-5 |
| #7497 | **Q9 (a)** #7865 FM-3's qualification of the "whatever the session's working directory" statements to sessions inside the governed workspace root; the `git-workflow.md:39` drift routed out. **Q16 (a)** target-only keying approved as an explicit tightening — three shipped arms invert — with two-view input (B), FM-1's root fix and FM-2's arms, the roadmaps carve-out (a) with FM-4's predicate amendment, and #7865 CD-2 (the worktree-root `.git`-leaf exclusion). **Q13:** (B) with FM-1 and FM-2 ("keep R2, amend the implementation"); the stale test comment folded in (FM-5); routing (vi) dropped | FCM #7497; slice 7; #7497 AC rows; CIAC-5, CIAC-6 |
| #6440 | **Q17 (b)** α — a Trash-only arm, item 8a and a core ADR — with #7866 CD-2 (an admission log) and FM-3 (a memory-specific message when the store is declared outside user scope). Under α, INT-1 is rewritten against Q2's outcome and the ADR follows Q3 (the third of three). **Q13:** D-Verb, D-Store-Source, D-Target-Shape, D-Normalizer, D-Rule-ID, D-Default-Location, D-Conditional, D-#5185-Coupling | FCM #6440; slice 8; #6440 AC rows; CIAC-5, CIAC-6 |

### The Tier-1 [ADJUST] (Q5, option (a)) — applied in this commit

One Tier-1 [ADJUST] (the DEV-9 pattern), recorded as one row in § Deviation Log. Every correction from the evidence record's Q5 (part 2/3), and where this file carries it:

*Corrections to the plan of record*
1. D-Version: provisional v4.70 → Header; Version identity; § Commit-0 Version Re-Verify Record.
2. #4994 AC-1 (`timeout 900`) and CIAC-3 (`timeout`) move to the python open-stdin harness (REC-4) → #4994 AC-1; CIAC-3.
3. CIAC-1, #5265 AC-2 and #6168 AC-1/AC-2 use a root-equality probe plus a `managed_at`-normalized comparison; Stage 10 never uses `diff -r` → those rows; CIAC-1; § Stage Applicability Matrix (Stage 10).
4. ODM row 6: the root-equality probe plus the report line → § Operational Deployment Manifest.
5. ODM row 9: the mechanism is the next install flow, and its verification follows Q15's CD-2 outcome → § Operational Deployment Manifest.
6. CIAC-5 legs: #7497's leg uses its cascade-sweep file set; #6440's leg counts the new memory-store wording in the fragment and the index (0 at baseline) → CIAC-5.
7. CIAC-6: each suite is re-baselined at the post-sync base and arm-ID sets are compared → CIAC-6.
8. "171 rows" → "168 rows (171 lines)" → § File Change Matrix note.
9. #6168's Stage 7 selection → rows 5 and 2 → § Stage Applicability Matrix.
10. IP-5's Check 9 leg is vacuous → § Integration Points; ODM row 8.
11. V-4 is read from the CI log → § Implementation Sequence, slice 1.
12. The ms#404 map row's region claim now includes `block-destructive.sh:544-545` → § Contention.

*Corrections to card acceptance criteria and methods*
13. #4993: AC-1, AC-5 and CIAC-2 use the pinned recipe plus Step 0; AC-4's snapshot adds the user settings file → #4993 rows; CIAC-2.
14. #4994: INT-1 restated as "PASSes where a live install exists and SKIPs — never PASSes — where none does", with counts as deltas on the post-#4993 baseline; AC-6 graded against 10 invocations; the P-9e precondition and per-arm markers; under E66 the schema-mismatch trigger named → #4994 rows; § Integration criteria.
15. #5265: `\` added to the refusal set on POSIX (PR-5); RK1 and AT-2 restated (PR-3); the identity-over-membership fix (PR-2); PR-4's `core/deploy/qa/checks.py` rides Q10 as Tier 2 → slice 4; FCM #5265.
16. #5274: the AC-2 RED-first arm drives the writer at the manifest-resolved path; AC-3 becomes the OV-1..OV-4 sweep; #7864 FM-4 (a)–(d), PR-2 and PR-3 → #5274 rows; slice 6.
17. #7497: AC-4 names the three arms; AC-5's control is 13, not 20, and its `two exemptions` pattern is split by option; AC-1 is refined; AC-6 and AC-7 are proposed → #7497 rows; § Proposed criteria.

*Corrections to text*
18. #5265's § 2 bullet and its ADR draft list all five tiers, including declared-source, and say "identical apart from `managed_at`" → slice 4.
19. `stage-08-qa-testing.md:174`: #4993 Change 4 rewrites the row-3 runner parenthetical to the post-#6896 cell, or cites row 3 without quoting it; INT-1 gains a clause (d) → slice 2; § Integration criteria.
20. `pipeline-event-log-schema.md:225-226`: the `env:` examples move to the new vocabulary (#4993 G3, a Tier-1 add) → FCM #4993; slice 2.
21. #6168's report key is matched as a fixed string, with a control arm, and its Change 1 comment is reworded → #6168 AC-4; slice 5.
22. The missing Evidence-Grounding canonicalizations for #6896 and #5265 → § Evidence-Grounding additions below.

**Evidence-Grounding additions (Q5, item 22).**

| Card | Canonicalization | Grounding |
|---|---|---|
| #6896 | exit 65 for the D-Guard refusal | the helper defines exit 64 for bad arguments (`core/hooks/tests/setup-ci-layout.sh:64`); 65 is the next code of the same sysexits-style family the update entrypoint declares (`update.sh:46-52`), where 65 names a refusal before any write (`EX_NOCONFIG`, `:48`) |
| #6896 | the D-Guard live-root set | the workspace-root order of ADR-204 less its hook-relative step (a test helper cannot use it), read from the account home rather than `${HOME}` (Q2), compared by filesystem identity rather than by path string (Q2, #7859 FM-3) |
| #5265 | `update.sh` exit 65 for an unresolvable root | the existing `EX_NOCONFIG=65` (`update.sh:48`, used at four pre-flight refusals, `:198-218`); the usage line is broadened |
| #5265 | `setup-workspace.sh` exit 66 for the refusal | the installer's existing no-mutation class: 10 `exit 66` sites in `docs/scripts/setup-workspace.sh`, which `cleanup()` already treats as no-mutation |

### Stage 6 entry and pacing

- **Stage 6 entry** (#7684 comment 5841775627, carrying DEV-14): milestone #338 refreshed per the Collective Review; the merged Change 8 text for #5265 and #6168 is issued before #5265's slice; each Stage-6 sub-task's rendered-design block lands just before its slice; Engineering Commit 0 runs as its own spoke on #7766, ahead of #6896's slice.
- **Pacing** (#7684 comment 5841863468, carrying DEV-15): one spoke in flight until the usage cap stops the run; the hub checkpoints before and after every spoke; every spoke commits and pushes at each coherent step.

### Transcription interpretations (recorded at Commit 0)

1. **Q2 FM-7 (a)'s carve-out** is carried as a #6896-slice edit to `release/references/how-to/hub-spoke-bridge.md` (the Spoke Template's § Run-Directory Discipline); the hub-directive half is the hub's brief text, not a file.
2. **#5265's ADR** is an unconditional ADD: its design marked it optional (`ADR-ROUTED`), but Q3 (b) numbers three records — #5265's, #5274's and #6440's — and option (c), fewer ADRs, was not rendered.
3. **#5274's ADR directory** is `core/ADRs/`: the design names no directory; the decision governs a `core/` resolver and `core/rules/` text, and the release's other two records sit there.
4. **#7497's AC-6 and AC-7** are "proposed" (Q5) and are not on the card, so they are recorded under § Proposed criteria with their methods, not bound as rows. The hub amends the card; the #7497 slice binds them.
5. **The DEV range.** The Decision Recorded's "Next" line names DEV-1 through DEV-13; the Stage-6 entry and pacing records add DEV-14 and DEV-15. All fifteen are carried.
6. **The designs' "stamp the ADR number at Commit 0"** (#5265, #6440) is superseded by Q3: no number is allocated at Commit 0.
7. **Q15 (b)'s CD-1b retitles `docs/UPDATE.md` § 6.1,** where #5265's Change 9 said "heading unchanged"; the decision governs.
8. **#7864 PR-2** offers two remedies. The #6198 co-discharge claim is narrowed to AC-1 unless the #5274 slice adds the mutation arm; either way AI-001 grades #6198 at Stage 13.
9. **#7864 FM-5's INT-2 demotion** is a Minor finding that no rendered option names, so INT-2 is kept as designed and the finding is logged.
10. **Three Stage-4 conditions fired on a basis other than their token names:** #4993's stage-07 row fires on the cascade basis (D-6), #4994's `docs/INSTALL.md` row on the E66 basis (Q14), and #5274's `SEED-PATH-CHANGES` resolved false while the file is still edited for a comment. Each is recorded both ways.
11. **Q1's locus has no CI producer for the override leg** at Commit 0 — recorded as R18, not resolved here.

---

## Implementation Sequence

One branch (`release/install-resolves-identically`), P0, slices in the Stage-4 Kahn order: **#6896 → #4993 → #4994 → #5265 → #6168 → #5274 → #7497 → #6440**. Each slice lands its RED arms first: **arm → observe RED → fix → observe GREEN**. Under Q1, RED and GREEN are read from the pull request's check runs on the slice commits; any local run sets `PMO_REGRESSION_EMIT=0`, and no spoke runs the regression under a `HOME=` prefix. A slice that edits a registry fragment regenerates `core/rules/bypass-mode-readiness.md` in the same commit (Check 38). Every slice re-reads its anchors at entry and binds by text, never by line number.

| # | Slice | Card | Content | Satisfies |
|---|---|---|---|---|
| **0** | Engineering Commit 0 | release | This plan file, with the Commit-0 re-verify (steps 1–3, then 3b) | Survival Set |
| **1** | Layout helper | #6896 | **RED:** the new suite `core/hooks/tests/setup-ci-layout.test.sh` (`LAYOUT-FRESH-01` first, then the DOC, SITE, DEFAULT, GUARD and PURGE arms, the footprint and identity arms, arm IDs declared) and the `.gitignore` entries; the current documented commands wrapped in the `AGENT-INVOCATION` markers. **GREEN:** the default site becomes the checkout root; D-Guard with identity checks against the account-home live roots, the ownership marker written first, the recorded footprint and a purge of exactly that list, the empty-`--sandbox` refusal; D-Mirror; the explicit fresh sandbox in `run-install-regression.sh` and in the CI hook-tests step (D-CI-Layout (ii)); selection-map row 3 (D-Row3); the allowlist and runner comments; the Spoke Template carve-out (Q2 FM-7 (a)). V-4 is read from the CI log (Q5) | AC-1..AC-3 |
| **2** | Regression verdict | #4993 | **Step 0** (the RED-first classification of every override failure as R, I or S, with its two-arm user-base pin control computed with `/usr/bin/python3`) is graded from the CI record (Q1). Changes 1–5: R-8's subject pinned to the account home, an empty subject reporting SKIP, one exit path (`r8_finish`), the R-8c classifier control and the in-suite resolver arm; the runner's verdict stamp and live-home export; the map's row 5 and § 3–4 text scoped to what ships (Q7); stage-08 `:161` and `:174` with the row-3 parenthetical; stage-07 `:403` and `:477-478`; the event-log schema's `env:` examples (G3) | AC-1..AC-5 |
| **3** | Unattended install | #4994 | **Commit A (tests):** the python open-stdin harness, the P-9 precondition and P-9a..P-9g with per-arm markers, and the P-10 census with the redirect-fed-read rule and its fixture lines — observed RED at each arm's own prompt. **Commit B (fix):** the three `NON_INTERACTIVE` branches (G1, ND2), E66 guided recovery naming the schema-mismatch trigger, the REC-6 local guard, and the `docs/INSTALL.md` § 5.5 paragraph. Expected counts are deltas on the post-#4993 baseline measured at this slice's entry | AC-1..AC-6 |
| **4** | Canonical root | #5265 | **Precondition:** the hub's ONE merged Change 8 text (#5265's Arms 7–10 and 8c, #6168's A-1..A-8, Arm 6 moved last) is issued before this slice (#7863 FM-5). Arms first, RED. Then one commit carries `compose.py`, `lib-composition.sh`, `update.sh` and `setup-workspace.sh` together (partial landing is unsafe): the five-tier refusing resolver, lazy resolution, `resolve-root`; the record with its `source_repo_path_source` key and the empty-record guard (Q15, Q6); `\` in the refusal set on POSIX; the identity-over-membership git check; remedy texts naming `--force-regen`; the § 2 bullet, the allowlist header (the HL-1 heal trigger), `docs/UPDATE.md` § 3.2 and the retitled § 6.1, `core/deploy/qa/checks.py` F4; the ADR, numbered at authorship | AC-1..AC-4 |
| **5** | Root report | #6168 | **C-6168a:** Arm 11 and its header line, test-first — RED, 0 report lines in all six logs. **C-6168b:** one `info` line inside #5265's resolver naming the root, its tier and the template checkout — GREEN, every Arm 7–10 assertion still GREEN. The report key is matched as a fixed string, with a control arm, and the Change 1 comment is reworded (#7863 FM-3, FM-2) | AC-1..AC-4 |
| **6** | One exemption-list path | #5274 | **Rebase point:** `core/hooks/allowlist-add.sh`'s exemption member is now at `:65` (it was `:48`; #7638 inserted 17 lines above it); the #7638 usage-block and array-close context lines stay untouched. **C1** the resolver pair and hook-read set in `lib-instance-path.sh` with value pins; **C2** tests first — Test 3/3b, E2E-1..E2E-6 (E2E-6 before the slice's other arms, Q8), the writer driven at the manifest-resolved path, new arms under unused IDs; **C3** the four consumers; **C4** the OV-1..OV-4 cascade (`[REFCASCADE: … pre 10 / post 0]`) with #7864 PR-3's added rows, the index regenerated; **C5** the gate widening, the legacy reconcile as its own phase after `refresh_hooks` (Q8), step 3b through #6896's recorded footprint, the Linux CI leg, the end-to-end arms and the ADR. No added line on Check 43's surface spells the instance-directory leaf bare | AC-1..AC-5 |
| **7** | Target-keyed write guard | #7497 | Assertion-first in one commit with the fix, since the inverted arms fail against the old hook: target-only keying with its three named inversions; the as-written dot-segment guard ahead of the worktree arm; two-view input (B) with FM-1's root fix (the root resolved by the target's resolver, failing closed) and FM-2's three arms; the roadmaps carve-out (a) with FM-4's amendment; CD-2's exclusion and its arm; the block message naming the target; the FM-3 qualification in the fragment, `_cross-cutting.md` and `operating-model.md`; the stale layout comment in the test file (FM-5); the index regenerated. INT-5 is graded from the CI record (Q1) | AC-1..AC-5 |
| **8** | Memory eviction | #6440 | The suite first (MEM-01..MEM-27b: 8 RED, 20 GREEN expected), then the memory-store arm with its admission-log row (CD-2) and the memory-specific refusal (FM-3), the fragment and the regenerated index, the § 7 paragraph and its Tier-A flowchart, item 8 and the new item 8a, and the ADR — one PR, since they are one decision | AC-1..AC-3 |
| **9** | Release-level verification | release | § Release-Level Verification and CIAC-1..CIAC-6 | — |

**Dependency graph.** Native edges: none (0 of 16 reads; control: #7506 `blocked_by` → 1). Derived edges, all `DEPENDS_ON`:

| Edge | Strength | Shared surface / reason |
|---|---|---|
| #5265 → #6168 | logical (co-discharge, D3) | `resolve_repo_root`; #6168's report line reads the two variables #5265 sets |
| #6896 → #4993 | composition | `run-install-regression.sh`: the hook floor passes the explicit fresh sandbox #6896 introduces (INT-1 (d)) |
| #4993 → #4994 | composition | `test_upgrade_config_durability.sh`: R-8 made non-vacuous before new arms are born under it (CIAC-2) |
| #4994 → #5265 | composition | `setup-workspace.sh`: the guard census in place before #5265 adds its recording step (CIAC-3) |
| hub → #5265 | precondition | the ONE merged Change 8 text (#7863 FM-5) |
| #6168 → #5274 | contention | `update.sh`; under Q8 (b) #5274's reconcile leaves the Phase-3 loop, so the edges shrink to adjacent regions |
| #5265 → #5274 | contention | `update.sh` threading vs the gate (INT-1) |
| #6896 → #5274 | composition | step 3b writes through #6896's recorded footprint (Q2 FM-2) |
| #6896 → #5274, #7497, #6440 | verification | each hook slice self-verifies through #6896's documented invocation under the Q2 carve-out |
| #5274 → #7497 | contention | `_cross-cutting.md` `:124-126` vs `:135`; `operating-model.md` `:263` vs `:262`; the generated index |
| #7497 → #6440 | contention | the generated index (Check 38) |
| #7497 ⇢ #4993 | backward seam | #7497 changes the tree #4993's AC-1/AC-5 and CIAC-2 grade; closed by FM-1's root fix and INT-5, graded from CI |

**Kahn's emission** (priority-desc → issue-asc tie-breaker): every step had a single zero-in-degree candidate, so no tie arose — 1 #6896 · 2 #4993 · 3 #4994 · 4 #5265 · 5 #6168 · 6 #5274 · 7 #7497 · 8 #6440. Cycle check: none.

---

## Stage Applicability Matrix

**Stage 5: ACTIVATE (release-wide)** — ran for all eight cards (T3: #5265, #5274, #6440, #7497; T4: #4993, #4994, #6440, #6896; T5: #7497, #5274; T6: #5274, #6896). Stages 7 and 8 apply to every card: each ships executable behaviour.

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing (selection-map rows) | 8 QA | Notes |
|---|---|---|---|---|---|
| #6896 | APPLY (#7750 · #7859) | APPLY | APPLY — row 3, and row 2 (the runner call changes) | APPLY | size S under α |
| #4993 | APPLY (#7752 · #7860) | APPLY | APPLY — rows 2 and 5; the override half graded from the CI record (Q1) | APPLY | — |
| #4994 | APPLY (#7754 · #7861) | APPLY | APPLY — row 5, plus Case 12 under the open-stdin harness | APPLY | — |
| #5265 | APPLY (#7756 · #7862) | APPLY | APPLY — rows 1 and 5 | APPLY | — |
| #6168 | APPLY (#7758 · #7863) | APPLY | APPLY — **rows 5 and 2** (Q5; it was row 1) | APPLY | RED for Arm 11 is recorded at Stage 6 |
| #5274 | APPLY (#7760 · #7864) | APPLY | APPLY — rows 2, 3 and 5 | APPLY | size L |
| #7497 | APPLY (#7762 · #7865) | APPLY | APPLY — row 3; INT-5 through the row-5 recipe, from the CI record | APPLY | size M |
| #6440 | APPLY (#7764 · #7866) | APPLY | APPLY — row 3 | APPLY | retained (Q10) |

**Release-scoped stages:**
- **Stage 9 Plan Review:** Deep (class).
- **Stage 10 Dry Run: ACTIVE.** The deploy mechanism changes — the resolver behind every composed surface (#5265/#6168) and the exemption-list target (#5274). The recipe pins `PMO_PLATFORM_CONFIG_ROOT` and `HOME` to the sandbox (#7863 PR-2). It composes from the primary checkout and from a worktree and compares them with Arm 8's `managed_at`-normalized comparison over the manifest-resolved set — **never `diff -r`** (Q5) — reads each refresh's report line, and runs a sandbox install → update cycle with #5274's probes (the list at its resolved location; update exit 0/64; the list removed → 75; a lossless legacy copy retired by the reconcile phase; a legacy copy with an extra entry WARNed and kept).
- **Stage 11 Snapshot:** compressed (git, plus the installer's durable hook snapshot and backups).
- **Stage 12 Execute:** APPLY — merge, atomic claim, hook-bundle republish (Check 79), surface regeneration, the rules-mirror redeploy for `core/rules/skill-deployment.md` (Check 9). **Operator-observed row (Success Indicator clause 2, Q4):** after the operator's `./update.sh` from the primary checkout, a `--surfaces-only --force-regen` refresh run from a linked worktree at the merged commit leaves the deployed allowlist identical apart from `managed_at`, with every token row bound to the primary. The report line is quoted with the root rendered as `<primary-checkout>`.
- **Stage 13 Close:** APPLY (30-day outcome window). The eight cards transition to closed here; AI-001 grades #6198; #5274 AC-5 is recorded on #4449.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction; blocks are labelled per card. Every Stage-4 CONDITIONAL row whose condition resolved true at the Collective Review, before this commit, is **promoted in this commit** and names its basis in its annotation; the rows that resolved false keep their token and are recorded NOT DELIVERED in § Deviation Log. Each card's rows carry its design's file set as amended by its review and its rendered decisions — the Tier 2 [SCOPE CHANGE] additions the scope-lock approved.

```
# ── release ──
release/releases/plans/install-resolves-identically_RELEASE_PLAN.md               ADD
core/ADRs/README.md                                                               EDIT  CONDITIONAL:ADR-RENUMBER-AT-CLAIM  (a Renumber-log line per Stage-12 move, written by the renumber tool)

# ── #6896 — layout helper (Q2 α with the #7859 amendments) ──
core/hooks/tests/setup-ci-layout.sh                                               EDIT  (default site = the checkout root; guard with identity checks; recorded footprint; purge; freshness digest; USAGE)
core/hooks/tests/setup-ci-layout.test.sh                                          ADD   (the LAYOUT arms, LAYOUT-FRESH-01 first)
core/deploy/tests/run-install-regression.sh                                       EDIT  (promoted: the hook floor passes a fresh explicit sandbox; the suite count dropped)
.github/workflows/install-tests.yml                                               EDIT  (promoted: the hook-tests step passes a fresh explicit sandbox; step comment)
.gitignore                                                                        EDIT  (the two layout entries)
release/references/standards/runtime-suite-selection-map.md                       EDIT  (row 3 runner cell)
core/config/allowlists/script-execution-allowlist.txt                             EDIT  (layout comment; 0 rows)
core/hooks/tests/test-runner.sh                                                   EDIT  (one comment)
release/references/how-to/hub-spoke-bridge.md                                     EDIT  (the scoped Spoke Template carve-out, Q2 FM-7 a)

# ── #4993 — regression verdict (Q7 D-5 a, scoped map text) ──
core/deploy/tests/test_upgrade_config_durability.sh                               EDIT  (R-8 subject; SKIP on an empty subject; one exit path; R-8c; the resolver arm)
core/deploy/tests/run-install-regression.sh                                       EDIT  (verdict stamp; live-home export)
release/references/standards/runtime-suite-selection-map.md                       EDIT  (row 5 cell and notes; sections 3 and 4, scoped to what ships)
release/references/pipeline/stage-08-qa-testing.md                                EDIT  (lines 161 and 174, the row-3 parenthetical included)
release/references/pipeline/stage-07-dev-testing.md                               EDIT  (promoted on the cascade basis, D-6)
release/references/standards/pipeline-event-log-schema.md                         EDIT  (env examples; the G3 Tier-1 add, Q5)

# ── #4994 — unattended means unattended (Q6 a, Q14 E66) ──
docs/scripts/setup-workspace.sh                                                   EDIT  (the NON_INTERACTIVE branches at the three prompt sites; E66 recovery; the REC-6 local guard)
core/deploy/tests/test_upgrade_config_durability.sh                               EDIT  (the open-stdin harness; the P-9 arms; the P-10 census)
docs/INSTALL.md                                                                   EDIT  (promoted on the E66 basis, Q14: one paragraph in section 5.5; the unattended-contract row stays verify-only)

# ── #5265 — canonical repository root (Q15 b) ──
core/deploy/compose.py                                                            EDIT  (tiered refusing resolver; lazy; resolve-root)
core/deploy/lib-composition.sh                                                    EDIT  (promoted: the root threaded through the lib, Change 2)
update.sh                                                                         EDIT  (pre-flight resolver; threading; remedy text names --force-regen)
docs/scripts/setup-workspace.sh                                                   EDIT  (records the canonical root and its provenance key; never an empty record)
core/standards/depersonalization-spec.md                                          EDIT  (the five-tier ladder in section 2)
core/deploy/tests/test_compose.py                                                 EDIT  (tier arms on a hermetic fixture)
core/config/allowlists/script-execution-allowlist.txt                             EDIT  (token header comment, the HL-1 heal trigger; 0 rows)
core/deploy/tests/test_refresh_surfaces.sh                                        EDIT  (the merged Change 8: Arms 7-10 and 8c with A-1..A-8; Arm 6 moved last)
docs/UPDATE.md                                                                    EDIT  (section 3.2; section 6.1 retitled)
core/deploy/qa/checks.py                                                          EDIT  (F4 docstring and remedy string, #7862 PR-4)
core/ADRs/ADR-NNN-pmo-platform-root-resolves-from-install-record.md               ADD   (numbered literally at authorship, first of three, Q3)
core/deploy/tests/test_lib_composition.sh                                         EDIT  CONDITIONAL:OPTIONAL-LIB-ARM  (Change 11)

# ── #6168 — composed allowlist is caller-independent (Q13) ──
update.sh                                                                         EDIT  (promoted: the report line inside the pre-flight resolver, R1)
core/deploy/tests/test_refresh_surfaces.sh                                        EDIT  (Arm 11 and its header line)

# ── #5274 — one exemption-list path (Q8 b, Q13 C1) ──
core/deploy/lib-instance-path.sh                                                  EDIT  (the resolver pair and the hook-read set; header contract)
core/deploy/tests/test_lib_instance_path.sh                                       EDIT  (value pins)
core/hooks/block-skill-direct-edit.sh                                             EDIT  (lazy isolated resolution; fails toward enforcement)
core/hooks/allowlist-add.sh                                                       EDIT  (the exemption member resolved and physical; rebase on the moved anchor)
core/deploy/deploy.sh                                                             EDIT  (one resolver, no fallback)
core/deploy/tools/check-canonical-structure.sh                                    EDIT  (one resolver; the checkout fallback removed)
update.sh                                                                         EDIT  (the gate covers the hook-read set; the legacy reconcile as its own phase after the hook refresh)
core/deploy/composition-surface-manifest.sh                                       EDIT  (comments; the row and the count kept)
core/hooks/tests/setup-ci-layout.sh                                               EDIT  (promoted: step 3b, written through the recorded footprint)
.github/workflows/install-tests.yml                                               EDIT  (the Linux leg seeds the hook-read set)
core/hooks/block-fragile-refs.sh                                                  EDIT  (one comment)
docs/scripts/setup-workspace.sh                                                   EDIT  (consumer-list comment; the seed path stays)
core/hooks/tests/block-skill-direct-edit.test.sh                                  EDIT  (Test 3 and 3b; E2E-1..E2E-6)
core/deploy/tests/test_install_end_to_end.sh                                      EDIT  (new Stage-4 arms under unused IDs)
core/standards/canonical-skill-structure.md                                       EDIT  (resolver naming)
core/rules/skill-deployment.md                                                    EDIT  (resolver naming; a mirror-pair member)
core/standards/version-field-semantics.md                                         EDIT  (resolver naming)
release/references/pipeline/stage-05-solutioning.md                              EDIT  (promoted on the reference cascade)
core/disciplines/operating-model.md                                               EDIT  (promoted on the reference cascade)
core/rules/bypass-mode-readiness/_cross-cutting.md                                EDIT  (promoted on the reference cascade)
core/rules/bypass-mode-readiness.md                                               EDIT  (promoted on the reference cascade; generated index)
release/references/specs/release-personas.md                                      EDIT  (promoted on the reference cascade)
core/standards/duplicate-source-discipline.md                                     EDIT  (promoted on the reference cascade)
docs/UPDATE.md                                                                    EDIT  (section 6.3a heading and body; lines 103, 107 and 109)
core/ADRs/ADR-NNN-exemption-list-resolves-at-the-instance-tier-through-one-resolver.md  ADD  (second of three, Q3)

# ── #7497 — write guard keys on the target (Q9 a, Q16 a) ──
core/hooks/block-destructive.sh                                                   EDIT  (target-keyed -019 exemption, two views; the message names the target; the -022 helper comment)
core/hooks/tests/block-destructive.test.sh                                        EDIT  (new arms; the three named inversions; the stale layout comment)
core/rules/bypass-mode-readiness/block-destructive.md                             EDIT  (the -019 row and its paragraphs)
core/rules/bypass-mode-readiness/_cross-cutting.md                                EDIT  (lines 135 and 217)
core/rules/bypass-mode-readiness.md                                               EDIT  (generated index)
core/disciplines/operating-model.md                                               EDIT  (lines 262 and 397, qualified per Q9)

# ── #6440 — memory eviction is executable (Q17 α with CD-2 and FM-3) ──
core/hooks/block-rm-prefer-trash.sh                                               EDIT  (the memory-store arm; the admission log; the memory-specific refusal)
core/hooks/tests/block-rm-prefer-trash.test.sh                                    EDIT  (the MEM arms)
core/rules/bypass-mode-readiness/block-rm-prefer-trash.md                         EDIT  (scope, rows, the memory-store arm subsection)
core/rules/bypass-mode-readiness.md                                               EDIT  (generated index)
core/disciplines/knowledge-architecture.md                                        EDIT  (the EVICT paragraph in section 7 and its Tier-A flowchart)
core/specs/autonomy-tiers.md                                                      EDIT  (item 8 and the new item 8a)
core/ADRs/ADR-NNN-memory-eviction-is-not-an-outside-workspace-deletion.md         ADD   (third of three, Q3)

# ── CONDITIONAL — resolved FALSE at the Collective Review; NOT DELIVERED, see § Deviation Log ──
CONDITIONAL:QA-ANTIPATTERN-NAMED             release/references/pipeline/stage-08-qa-testing.md       EDIT
CONDITIONAL:SEED-PATH-CHANGES                docs/scripts/setup-workspace.sh                          EDIT
CONDITIONAL:E2E-ARM-IN-WRITER-SUITE          core/hooks/tests/allowlist-add.test.sh                   EDIT
CONDITIONAL:RESOLVER-LIB-ADDED               core/hooks/lib/skill-editor-exemption-path.sh            ADD
CONDITIONAL:RESOLVER-LIB-ADDED               core/config/allowlists/script-execution-allowlist.txt    EDIT
CONDITIONAL:MEMORY-DIR-FROM-PLATFORM-CONFIG  core/config/platform-config.toml.template                EDIT
CONDITIONAL:MEMORY-DIR-FROM-PLATFORM-CONFIG  docs/platform-config-reference.md                        EDIT
```

- **Repository-root rows.** `update.sh` (three rows) and `.gitignore` carry no directory segment, so the plan-driven executor's first-segment enum reads them as `fence-unrecognized-path` (FCM-COVERAGE SKIP, `fcm-rows-uninterpreted`). Each is an EDIT, so no ADD obligation is lost.
- **Counts.** 70 unconditional rows over 54 distinct paths: 5 ADDs (this plan, the new suite and three ADRs) and 49 edited paths. Nine CONDITIONAL rows are counted apart — two live (the ADR README and the optional lib arm) and the seven of the resolved-false block. Across every row, 60 distinct paths are declared. The allowlist's token population is **168 rows (171 lines)** at the pin (Q5).
- **New-executable companion obligation: does not fire.** `CONDITIONAL:RESOLVER-LIB-ADDED` resolved false — the resolver lands in `core/deploy/lib-instance-path.sh`, which the hook bundle already co-deploys. The one new shell file, `core/hooks/tests/setup-ci-layout.test.sh`, is a suite the runner discovers by its `*.test.sh` glob; no allowlist row changes (#7750).
- **ADR rows.** The three `ADR-NNN` placeholders take literal numbers when their slices author them (Q3); the `NNN` form is the matrix contract's glob for a not-yet-numbered record, never a filename.

#### Read-only inputs

```
core/deploy/tests/test_refresh_hooks.sh                               READ
core/hooks/lib/platform-membership.sh                                 READ
core/deploy/tools/build-hook-registry.py                              READ
core/hooks/block-autonomy-ceiling.sh                                  READ
core/config/allowlists/skill-editor-exemption-list.txt                READ
release/tools/renumber-adr.py                                         READ
```

`core/deploy/lib-instance-path.sh` moved from this block to #5274's edit rows (its Tier 2 addition). `core/deploy/tests/test_refresh_hooks.sh` Case 12 runs unedited (REC-5).

#### Release-wide explicit non-scope

```
docs/workspace-setup.md                                               NOT EDITED
core/rules/git-workflow.md                                            NOT EDITED
core/disciplines/memory-architecture.md                               NOT EDITED
```

- `docs/workspace-setup.md` is already canonical; #5274's design dropped the edit (PRESERVE).
- `core/rules/git-workflow.md:39`'s worktree base is routed out under the N-way R14 override (Q9).
- `core/disciplines/memory-architecture.md:40` changes only under #6440's δ, which was not rendered; under α it becomes consistent through item 8a.
- `core/deploy/compose.py` and `core/deploy/tests/test_compose.py` leave #6168's set (its design dropped them); #5265 still edits both.

### Agent-Editability Read

Controls read at `8e0ee084` (Stage 4) and re-checked at `35dbf418`: `core/hooks/block-autonomy-ceiling.sh` and `core/hooks/block-skill-direct-edit.sh` are byte-unchanged between the two. **Tier-0 floor** (`BLOCK-AUTONOMY-001`, both `case` blocks) projected onto the tracked index at `35dbf418` survives as `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md` (the control union is non-empty). **Tier-0 ∩ write set = ∅** over all 60 declared paths, conditional rows included. **Skill gate:** no declared path carries a `*/skills/<name>/` segment, so conjunct 1 is false everywhere and conjuncts 2 and 3 do not decide.

| Card | Write-set paths (add/edit, CONDITIONAL included) | Tier-0 ∩ | Skill-gate ∩ | Path class |
|---|---|---|---|---|
| release | `release/releases/plans/install-resolves-identically_RELEASE_PLAN.md` · `core/ADRs/README.md` | ∅ | ∅ (c1) | unconstrained |
| #6896 | `core/hooks/tests/setup-ci-layout.sh` · `core/hooks/tests/setup-ci-layout.test.sh` · `core/deploy/tests/run-install-regression.sh` · `.github/workflows/install-tests.yml` · `.gitignore` · `release/references/standards/runtime-suite-selection-map.md` · `core/config/allowlists/script-execution-allowlist.txt` · `core/hooks/tests/test-runner.sh` · `release/references/how-to/hub-spoke-bridge.md` | ∅ | ∅ (c1) | unconstrained |
| #4993 | `core/deploy/tests/test_upgrade_config_durability.sh` · `core/deploy/tests/run-install-regression.sh` · `release/references/standards/runtime-suite-selection-map.md` · `release/references/pipeline/stage-08-qa-testing.md` · `release/references/pipeline/stage-07-dev-testing.md` · `release/references/standards/pipeline-event-log-schema.md` | ∅ | ∅ (c1) | unconstrained |
| #4994 | `docs/scripts/setup-workspace.sh` · `core/deploy/tests/test_upgrade_config_durability.sh` · `docs/INSTALL.md` | ∅ | ∅ (c1) | unconstrained |
| #5265 | `core/deploy/compose.py` · `core/deploy/lib-composition.sh` · `update.sh` · `docs/scripts/setup-workspace.sh` · `core/standards/depersonalization-spec.md` · `core/deploy/tests/test_compose.py` · `core/config/allowlists/script-execution-allowlist.txt` · `core/deploy/tests/test_refresh_surfaces.sh` · `docs/UPDATE.md` · `core/deploy/qa/checks.py` · the `core/ADRs/` record · `core/deploy/tests/test_lib_composition.sh` | ∅ | ∅ (c1) | unconstrained |
| #6168 | `update.sh` · `core/deploy/tests/test_refresh_surfaces.sh` | ∅ | ∅ (c1) | unconstrained |
| #5274 | `core/deploy/lib-instance-path.sh` · `core/deploy/tests/test_lib_instance_path.sh` · `core/hooks/block-skill-direct-edit.sh` · `core/hooks/allowlist-add.sh` · `core/deploy/deploy.sh` · `core/deploy/tools/check-canonical-structure.sh` · `update.sh` · `core/deploy/composition-surface-manifest.sh` · `core/hooks/tests/setup-ci-layout.sh` · `.github/workflows/install-tests.yml` · `core/hooks/block-fragile-refs.sh` · `docs/scripts/setup-workspace.sh` · `core/hooks/tests/block-skill-direct-edit.test.sh` · `core/deploy/tests/test_install_end_to_end.sh` · `core/standards/canonical-skill-structure.md` · `core/rules/skill-deployment.md` · `core/standards/version-field-semantics.md` · `release/references/pipeline/stage-05-solutioning.md` · `core/disciplines/operating-model.md` · `core/rules/bypass-mode-readiness/_cross-cutting.md` · `core/rules/bypass-mode-readiness.md` · `release/references/specs/release-personas.md` · `core/standards/duplicate-source-discipline.md` · `docs/UPDATE.md` · the `core/ADRs/` record · resolved-false: `core/hooks/tests/allowlist-add.test.sh` · `core/hooks/lib/skill-editor-exemption-path.sh` | ∅ | ∅ (c1) | unconstrained |
| #7497 | `core/hooks/block-destructive.sh` · `core/hooks/tests/block-destructive.test.sh` · `core/rules/bypass-mode-readiness/block-destructive.md` · `core/rules/bypass-mode-readiness/_cross-cutting.md` · `core/rules/bypass-mode-readiness.md` · `core/disciplines/operating-model.md` | ∅ | ∅ (c1) | unconstrained |
| #6440 | `core/hooks/block-rm-prefer-trash.sh` · `core/hooks/tests/block-rm-prefer-trash.test.sh` · `core/rules/bypass-mode-readiness/block-rm-prefer-trash.md` · `core/rules/bypass-mode-readiness.md` · `core/disciplines/knowledge-architecture.md` · `core/specs/autonomy-tiers.md` · the `core/ADRs/` record · resolved-false: `core/config/platform-config.toml.template` · `docs/platform-config-reference.md` | ∅ | ∅ (c1) | unconstrained |

**Card class `unconstrained` for all eight; execution path: ordinary Engineering spoke.** Unconstrained is not ungoverned: `core/rules/*.md`, `core/disciplines/*`, `core/specs/*` and `core/standards/*` edits remain governance-file changes authorized by the issue + plan + PR route, and hook edits remain security-control changes. The deployed copy of each edited hook is what fires, so each needs a Stage-12 republish.

---

## Integration Points

| ID | Contract | Issues | What must hold |
|---|---|---|---|
| IP-1 | compose resolver ↔ `update.sh` ↔ `lib-composition.sh` ↔ the install record written by `setup-workspace.sh` | #5265, #6168, #4994 | One canonical root on every path; the record is written without a prompt (CIAC-3) and carries its provenance key (Q15) |
| IP-2 | exemption list: manifest tier ↔ installer seed ↔ writer ↔ hook reader ↔ `deploy.sh` / `check-canonical-structure.sh` ↔ CI layout (step 3b) ↔ the Linux CI leg ↔ the `update.sh` gate and the legacy reconcile phase | #5274, #6896 (#6198 external) | One path, materialized wherever the hook runs (CIAC-4) |
| IP-3 | hook-suite runner ↔ allowlist runner rows ↔ composed `[PMO_PLATFORM_ROOT]` | #6896, #5265 | The documented invocation matches an admitted row (CIAC-6); the absolute worktree form depends on IP-1 |
| IP-4 | durability suite ↔ regression runner ↔ selection-map row 5 ↔ stage-07/08 A8 wording ↔ the `test-run` payload `env:` | #4993, #4994, #6896 | The map names the real preventive mechanism, truthfully scoped (Q7); verdicts agree across HOMEs (CIAC-2) |
| IP-5 | registry fragments ↔ generated index ↔ Check 38 | #5274, #7497, #6440 | Index fresh; rows describe shipped predicates (CIAC-5). The Stage-4 row's rules-mirror / Check 9 leg is **vacuous**: the generated index is not a mirror-pair member (Q5) |
| IP-6 | § 7 encode-and-evict ↔ BLOCK-TRASH-003 ↔ autonomy-tiers item 8a ↔ #5185 ARCHIVE | #6440 | One normative home for the mechanism (#6440 AC-3) |

### Contention

**Within the release** — 13 paths are edited by two or more cards under the rendered designs (anchors at `35dbf418`). Serial P0 makes each a rebase, never a conflict; each later slice re-reads the file at entry.

| File | Cards, in landing order | Regions |
|---|---|---|
| `.github/workflows/install-tests.yml` | #6896 → #5274 | hook-tests step `:959-968` · Linux leg `:1155-1210` |
| `core/config/allowlists/script-execution-allowlist.txt` | #6896 → #5265 | comments `:117-123` · token paragraph `:48-54`; either edit changes the template SHA, so every install regenerates on its first post-release update (HL-1) |
| `core/deploy/tests/run-install-regression.sh` | #6896 → #4993 | `:14`, `:17-19`, `:149-153` · `:9-13`, `:21-30`, `:185-186`, `:212` — adjacent at the header; INT-1 specifies the merged runner |
| `core/deploy/tests/test_refresh_surfaces.sh` | #5265 (with #6168's A-1..A-8) → #6168 | one arm block, two amendment layers — the hub's ONE merged Change 8 text; Arm 6 moves to the end |
| `core/deploy/tests/test_upgrade_config_durability.sh` | #4993 → #4994 | R-8 window `:1983-2211` · header `:36-44` and an insertion before Stage 5c `:863`, inside the R-8 window |
| `core/disciplines/operating-model.md` | #5274 → #7497 | `:263` · `:262`, `:397` — adjacent, disjoint |
| `core/hooks/tests/setup-ci-layout.sh` | #6896 → #5274 | by line disjoint; by footprint joined — step 3b writes through #6896's recorded footprint (Q2) |
| `core/rules/bypass-mode-readiness.md` (generated) | #5274 → #7497 → #6440 | regenerated in each slice, in slice order (N-way R9) |
| `core/rules/bypass-mode-readiness/_cross-cutting.md` | #5274 → #7497 | `:124-126` · `:135`, `:217` |
| `docs/UPDATE.md` | #5265 → #5274 | § 3.2 and § 6.1 (bind by heading; § 6.1 moved +11 lines) · § 6.3a and `:103`, `:107`, `:109` |
| `docs/scripts/setup-workspace.sh` | #4994 → #5265 → #5274 | the prompt sites · the recording flows and `:3005` · the comment `:2529-2537`; the census stays guarded = total under Q6 (a) |
| `release/references/standards/runtime-suite-selection-map.md` | #6896 → #4993 | row 3 `:35` · row 5 `:37`, § 3, § 4 |
| `update.sh` | #5265 → #6168 → #5274 | pre-flight resolver and threading · one line inside that resolver · `:73-77`, `:386-387`, `:787-820`, `:150` and the new reconcile phase after `refresh_hooks` (Q8 (b) moves #5274's hunk out of the Phase-3 loop) |

`core/deploy/compose.py` and `core/deploy/tests/test_compose.py` are no longer shared (#6168 dropped them). `release/references/pipeline/stage-08-qa-testing.md` is #4993's alone (REC-7 declined).

**Cross-milestone** — the milestone's Parallelization Map, refreshed at the Collective Review (Q11), plus one row measured at Commit 0. Verdict: Tier-B soft-coupled + Tier-S (version slot; ADR axis); no hard or blocking edge in either direction.

| Other milestone | Edge | What this release does |
|---|---|---|
| `egress-hook-batch` (ms#392; PR #7638 merged at `40cec0c7`) | file contention; version slot | #5274 rebases on `allowlist-add.sh` (member now `:65`); the index regenerates on this branch; `v4.69` is taken, so this release displays `v4.70` |
| `install-wires-what-it-ships` (ms#366) | soft | #5633's invariant check reads red on the exemption row if it ships enforcing before #5274 — the notice was posted at the Collective Review; #5750 shares `setup-workspace.sh` and `update.sh` |
| `authoring-conventions-enforced-or-retired` (ms#352) | soft | #6440 ↔ #5185 on disjoint regions of § 7 |
| `evergreen-cleanup-batch` (ms#402) | soft | #6198 is a co-discharge candidate, narrowed per #7864 PR-2; graded at Stage 13 (AI-001) |
| `hook-walk-adjudicates-every-operand` (ms#404) | file contention | `block-destructive.sh`, its test and its fragment, region-disjoint; #7497's claim now includes `block-destructive.sh:544-545` (Q5); the second merger rebases |
| `verifier-grades-what-plans-declare` (ms#405; PR #7839, draft, head `1f4a8423`) | file contention + ADR axis | line-level collisions on the selection map (row 3 `:35`, row 5 `:37`, § 3 and § 4) and on `stage-08-qa-testing.md` `:161` and `:174`; `stage-07-dev-testing.md` hunks adjacent to `:403`; `install-tests.yml` `:830-843`, disjoint. It holds four `release/ADRs/` numbers (207–210). The second merger rebases and reconciles |
| `telemetry-is-computable` (ms#341; PR #7901, draft, head `acf9c2c7`) | version slot | displays provisional `v4.70`; 0 of its 18 files are in this write set at Commit 0; no ADR |
| `closeout-verification-rows-consistent` (ms#395; PR #7895, draft, head `f314496a`) | version slot + ADR axis | displays provisional `v4.70`; plans two release ADRs; shares `hub-spoke-bridge.md` at `:2236` and `:2442`, disjoint from #6896's carve-out in § Run-Directory Discipline |
| `deploy-decomposes-per-check` (ms#381) | Tier-S candidate | re-run the A4 structural sub-audit if ms#381 declares a move of `deploy.sh :7816-7852` first |
| `controls-fail-loud` (PR #7919, draft, head `cef8f82a`) — **not in the milestone's map at Commit 0** | version slot + file contention | displays provisional `v4.70`; shares `core/deploy/deploy.sh` (hunks from `:956` to `:20149`, none within #5274's `:7816-7852`) and `hub-spoke-bridge.md` (`:2234`) — region-disjoint; no ADR |

Re-verified: `detectors-match-the-property-not-the-spelling` (ms#413) shares no file with #7497 (coordination only).

### In-Flight Release Roster

**Stage-4 measurement:** `8e0ee084` · 2026-09-25T03:09:46Z · n=1 — `egress-hook-batch`, PR #7638 (draft then; merged since as `40cec0c7`, tag `v4.69`).

**Re-read at Commit 0:** `35dbf418` · 2026-09-26 (UTC) · **n=4 siblings**.

| Slug | PR | Head SHA | Bump-class · display | EDITSET ∩ FCM |
|---|---|---|---|---|
| `controls-fail-loud` | #7919 (draft) | `cef8f82a` | minor · `v4.70` | `core/deploy/deploy.sh`, `release/references/how-to/hub-spoke-bridge.md` (2 of 7), region-disjoint |
| `telemetry-is-computable` | #7901 (draft) | `acf9c2c7` | minor · `v4.70` | none (0 of 18) |
| `closeout-verification-rows-consistent` | #7895 (draft) | `f314496a` | minor · `v4.70` | `release/references/how-to/hub-spoke-bridge.md` (1 of 11), region-disjoint |
| `verifier-grades-what-plans-declare` | #7839 (draft) | `1f4a8423` | claims at its own Stage 12 | `.github/workflows/install-tests.yml`, `release/references/pipeline/stage-07-dev-testing.md`, `release/references/pipeline/stage-08-qa-testing.md`, `release/references/standards/runtime-suite-selection-map.md` (4 of 44) |

Probe: the open-PR list (REST, `state=open`) → 4, all OWNER-authored; control: `git ls-remote --heads origin 'release/*'` → the same 4 branches. Each PR's changed-file list was intersected with this plan's 60 declared paths; control: #7839's list contains the selection map, a known shared path. This roster is a measurement, not a verdict; Stage 9 A6.6 re-measures it.

---

## Risk Register

| # | Risk | L | I | Mitigation (named by the mechanism that catches it) | Owner | Rev. |
|---|---|---|---|---|---|---|
| R1 | Scope: effective 39 against a 25 ceiling; the labels may still understate (#6896 under α; #5265 nearer M) | High | Med | The Override is recorded at 39 (Q10); Checkpoint B before every launch; W_max 1 pacing (DEV-15) | operator | CHEAP |
| R2 | #7497's target-only keying refuses a primary-checkout Layer-1 Write/Edit from a worktree-rooted session — approved as an explicit tightening (Q16); three v3.43 arms invert | Med | High | The three inversions named in AC-4; Stage 7 runs the full -019 set; FM-1's root fix holds the flip count at three under a symlinked sandbox HOME (INT-5, graded from CI) | Stage 6 + operator | MODERATE |
| R3 | A target-keyed exemption admits a dot-segment escape into tracked Layer-1 files | Med | High | The as-written dot-segment guard ahead of the worktree arm; the two-view rule (the as-written and resolved locations must agree, and an unresolved target gets no exemption); FM-2's arms; Deep Stage-9 review | Stage 6 | MODERATE |
| R4 | #6440 widens a deletion control outside the workspace root | Low | High | α's predicate (a Trash-verb move of one direct `*.md` entry of the declared store, never the index or a directory, fail closed); an admission-log row per admission (CD-2); a memory-specific refusal outside user scope (FM-3); outside-both arms stay blocked (AC-2) | Stage 6 | MODERATE |
| R5 | #6896's checkout-root default persists a reused layout: stale snapshots, an unowned purge, legacy layouts | Med | Med | The freshness digest and `LAYOUT-FRESH-01`; one recorded footprint the purge reads and step 3b writes through; the ownership marker written first; the `.gitignore` entries; programmatic callers pass an explicit fresh sandbox; the CI hook-tests job | Stage 6 | CHEAP |
| R6 | Version-slot and ADR-axis contention: `v4.70` is displayed by four other open releases (#7919, #7901, #7895, #7839); ms#405's branch holds four release ADR numbers (207–210) and ms#395 plans two | High | Low | The Stage-12 atomic claim re-versions the loser forward; ADR numbers are literal at authorship and reconciled at Stage 12 (Q3) | hub | CHEAP |
| R7 | Siblings edit FCM paths — #7839 (the selection map and stage-08 at line level), #7919 and #7895 (the bridge), ms#366, ms#402, ms#404, ms#381 | Med | Low | The refreshed Parallelization Map (Q11); the second merger rebases; Stage 9 A6.5/A6.6 re-measure; #7919's missing map row is flagged to the hub | hub | CHEAP |
| R8 | Under G1 and E66 the flagged recovery exits 66 instead of 0, so `install.sh` stops before Phase 2 | Med | Med | E66 rendered (Q14) and stated in `docs/INSTALL.md` § 5.5, the schema-mismatch trigger named; the stdin-open arms observed RED first (the P-9 family and Case 12) | Stage 6 | CHEAP |
| R9 | A fail-loud R-8 turns CI red where HOME has no skills tree | Med | Med | R-8's subject is the account home; an empty subject SKIPs with a reason, never PASS (D-1 C); the in-suite resolver arm (#7860 FM-1) | Stage 6 | CHEAP |
| R10 | An incomplete #5274 reference cascade leaves stale spellings | Med | Med | The OV-1..OV-4 sweep with `[REFCASCADE: … pre 10 / post 0]`; #7864 PR-3's emphasis-stripped probe and added rows | Stage 6 | CHEAP |
| R11 | #5265: a legacy install record naming another existing clone, or no record at all | Med | Med | C3 record-first with CD-2's provenance key (a legacy record without it is advisory); the deterministic fallback to the main working tree; never an empty record (Q6) | Stage 6 | CHEAP |
| R12 | A stale generated index after a slice (Check 38) | Med | Low | Regenerate in every fragment-editing commit; `build-hook-registry.py --check` at C4; CIAC-5 | Stage 6 | CHEAP |
| R13 | Merged hooks do not fire until republished | Med | High | The Stage-12 republish of every edited hook and the co-deployed `lib-instance-path.sh`; Check 79 content MATCH (ODM rows 1–6) | Stage 12 | CHEAP |
| R14 | #7497 entered without a Stage-2 verdict and without criteria | — | — | **Closed** at the Stage-4 follow-through (DEV-6): five criteria, the approval basis recorded | hub | CHEAP |
| R15 | Two deployed exemption-list copies; a consolidation could drop an operator entry | Low | Med | The legacy reconcile retires a copy only when lossless and only after the hook refresh (Q8); extra entries are WARNed with the writer command; a backup is written | Stage 12 | MODERATE |
| R16 | #6440 ↔ #5185 coupling on § 7 | Med | Low | α's mechanism is one paragraph in EVICT; #5185's ARCHIVE region is disjoint; the second merger rebases | Stage 6 | CHEAP |
| R17 | The ambient rules budget (Check 78) and `core/rules/skill-deployment.md` | Low | Low | The edit swaps a path spelling (≈0 B); the admitted set measured 152,831 B against 204,800 B at the pin | Stage 6 | CHEAP |
| R18 | **Found at Commit 0:** Q1 names CI as the observer, but `.github/workflows/install-tests.yml` runs the regression once, with no caller-side HOME override (`:1000-1007`). The override half of #4993 AC-1, AC-3 (ii) and AC-5, CIAC-2's override limb, the Success Indicator's clause 1 and #7497's INT-5 therefore have no CI record yet | High | Med | The #4993 slice raises the producer before its RED commit — a CI leg applying the row-5 recipe is a Tier 2 [SCOPE CHANGE] on `install-tests.yml`, a file #6896 and #5274 also edit — or the hub names another sanctioned locus. Until then those rows read INDETERMINATE, never PASS | hub | CHEAP |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential, P0 fully-serial, along the eight-slice chain; one spoke in flight at a time |
| Commit strategy | Per slice, a RED commit (the arms), then a GREEN commit (the fix), with RED and GREEN read from the PR's check runs (Q1). The index is regenerated inside the fragment-editing commit. Commit messages carry the `release(install-resolves-identically):` prefix and name the card. This plan is Engineering Commit 0 |
| Review approach | A single PR for the whole release (D-C SINGLE), opened in draft at Commit 0. The body is parser-clean: close-family verbs next to an issue number appear only in the dedicated Issue References block; the eight cards transition to closed at Stage 13 |
| Deployment mechanism | Git merge + atomic version claim + hook-tier republish (`update.sh` → `setup-workspace.sh --refresh-hooks`, the co-deployed `lib-instance-path.sh` included) + composition-surface regeneration (`update.sh`; the HL-1 heal on the first post-release update) + the rules-mirror redeploy of `core/rules/skill-deployment.md` (`deploy.sh --deploy`). **No skill S-2 deploy and no package rebuild** — measured: `build-skill-packages.sh --skills-for-paths` over the 60 declared paths returns no skill |
| Stacked-base cleanup posture | N/A — single branch |

---

## Verification Plan

**Verification locus (Q1).** CI is the observer: RED and GREEN are read from the pull request's check runs on the slice commits. Any local run sets `PMO_REGRESSION_EMIT=0`. Every method that runs the regression under an overridden HOME — #4993's Step 0, AC-1, AC-3 (ii) and AC-5, CIAC-2, and #7497's INT-5 — is graded from the CI record, not from a spoke-run `HOME=` prefix; the user-base pin is computed with `/usr/bin/python3`. At Commit 0 no CI step produces that record (R18), so those rows read INDETERMINATE until it exists — never PASS. A hook-suite run by a spoke uses #6896's documented invocation from its own worktree root, the site Q2's scoped carve-out admits.

**Every method cell carries its command literally**, reproducible from the cell alone. A `bash …` cell is dispatchable but **not executed** by the plan-driven executor `release/tools/verify-release-plan.sh`, whose runnable-verb set is closed to read-only queries; such a row reads as ERROR (`unclassified-method`) there, and its guarantee lives in the suite's own CI-invoked run. At Commit 0 every verdict is a pre-fix reading by construction.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6896 | AC-1 | From the spoke's worktree root, the two documented literal commands: `bash core/hooks/tests/setup-ci-layout.sh`, then `bash .claude/hooks/tests/test-runner.sh`. Attribute any new hook-log row by `cwd` and time window across every hook log, not the destructive log alone (#7750 F14); then `git status --porcelain`. The RED-first observation is read from the PR's check run (Q1), and the refused pre-change forms are proven hermetically by `LAYOUT-DOC-03a/b`, never by tripping the live control (#7859 FM-4) | Helper exit 0 with stdout the worktree's `.claude/hooks/tests`; runner exit 0, `AGGREGATE … FAIL=0`; 0 new hook-log rows for this `cwd`; no `.claude/` entry in `git status`; `LAYOUT-FRESH-01` PASS · control: `LAYOUT-DOC-01` is RED on the pre-change helper |
| #6896 | AC-2 | Named read of the allowlist on the merged tree: `grep -c -e '^/tmp' -e '^/private/tmp' -e '^/var/folders' -e '^[$]TMPDIR' core/config/allowlists/script-execution-allowlist.txt` → expect 0; plus a diff of the non-comment rows against the pre-release file | 0 temp-root rows; the non-comment row diff is empty (comment edits only) · control: the same file's layout-runner rows naming `.claude/hooks/tests/test-runner.sh` → 4 |
| #6896 | AC-3 | `bash core/hooks/tests/setup-ci-layout.test.sh` under the CI layout — arms `LAYOUT-SITE-01` (a non-allowlisted script beside the runner, named so it cannot match the `*.test.sh` rows) and `LAYOUT-DOC-03b` (the literal temp-path runner form) — read from the CI hook-tests log (Q1) | Each exits 2 naming `BLOCK-DESTRUCTIVE-022` · control: `LAYOUT-GUARD-05` and `LAYOUT-DOC-01` admit the documented forms (exit 0) |
| #4993 | AC-1 | CI record (Q1): the check run that executes `bash core/deploy/tests/run-install-regression.sh` under the selection map's § 3 row-5 recipe — `HOME` a fresh `mktemp -d`, `PYTHONUSERBASE` computed with `/usr/bin/python3` before the override, `PMO_REGRESSION_EMIT=0` — after Step 0 has classified every override failure as R, I or S with its two-arm pin control (#7860 FM-6); read the single verdict line | `VERDICT PASS [env: home-override; skipped: N]`, exit 0 · pre-fix, Step 0's override FAIL set is classified and never reported as PASS · INDETERMINATE until the CI producer exists (R18) |
| #4993 | AC-2 | (i) the override run's durability R-8 line, from the CI record (Q1); (ii) `PMO_REGRESSION_LIVE_HOME="$(mktemp -d)" bash core/deploy/tests/test_upgrade_config_durability.sh`; (iii) the in-suite CI arm that evaluates the member's resolver with `HOME` pointed at a sandbox and the subject variable unset (#7860 FM-1) | (i) `PASS: R-8 live install byte-identical before/after (<N> files …)` with N > 0; (ii) `SKIP: R-8 live-install byte-identity` with its `reason:` line and a summary counting 1 skipped — R-8 never PASSes on an empty subject; (iii) a non-empty subject that is not the sandbox directory, and `r8: caller` stamped when a caller set the subject · control: the pre-fix override run prints an R-8 PASS over an empty subject (RED) |
| #4993 | AC-3 | (i) the in-suite arm `R-8c classifier discriminates …`; (ii) a fixture home `F` holding one skill file, drifted mid-run by `( sleep 20; printf 'drift\n' >> "$F/.claude/skills/probe/SKILL.md" ) &`, then the member under the row-5 recipe with `PMO_REGRESSION_LIVE_HOME="$F"`, graded from the CI record (Q1) | (i) PASS; (ii) R-8 FAILs naming `probe/SKILL.md`, exit 1 · control: the pre-fix member ignores the variable and reports no drift |
| #4993 | AC-4 | An external snapshot bracketing Step 0's pinned and real runs and the post-fix runs: `shasum -a 256` over every file under the account home's `.claude/skills`, `.claude/rules`, `.claude/commands` and `.claude/settings.json` (added by #7860 FM-8) and `.config/pmo-platform`, and under the workspace's `.claude/hooks`, `.claude/settings.json` and `CLAUDE.md`, sorted, then `diff` of before against after — the verifier's own read, not the suite's self-report | `diff` empty · sensitivity: the same snapshot over a scratch copy with one file touched names exactly that file · specificity: two snapshots of the untouched copy give an empty `diff` |
| #4993 | AC-5 | CI record (Q1): the same runner under the row-5 recipe and under the real HOME; compare the two verdict lines | Both `VERDICT PASS`, the stamps reading `env: home-override` and `env: home-account` · control: pre-fix the two verdict lines are identical, so the runs are indistinguishable |
| #4994 | AC-1 | `bash core/deploy/tests/test_upgrade_config_durability.sh < /dev/null` — arms P-9c, P-9e and P-9f, each a `--non-interactive` install whose stdin is an open, silent pipe under the python3 open-stdin harness (`run_open_stdin`, 300 s budget, exit 124 plus a sentinel on timeout; REC-4); P-9f's guided recovery exits 66 with nothing modified, naming the schema-mismatch trigger (Q14). Case 12 of `test_refresh_hooks.sh` runs under the same harness shape: `python3 - 600 bash core/deploy/tests/test_refresh_hooks.sh` fed the design's eight-line open-stdin program | P-9c and P-9e exit 0 within the budget; P-9f exits 66 and modifies nothing; Case 12 rc 0 · control: pre-fix each arm is held at its own prompt, exit 124 with the sentinel (RED); Case 12 rc 124 |
| #4994 | AC-2 | The P-10 census (REC-6, Q6 (a)) in `bash core/deploy/tests/test_upgrade_config_durability.sh`: every human-answer `read` in `docs/scripts/setup-workspace.sh` is dominated by a `NON_INTERACTIVE` guard, and a `read` whose own line carries input redirection counts as a data read; its fixture carries #7861 PR-1's must-flag lines and FM-1's must-not-flag line | Census `5 5 -` (guarded = total = 5), still guarded = total after #5265's slice lands its heredoc-fed `read` · control: the pre-fix installer reads `5 1 2440,2870,3543,4467`; the fixture reads its planted verdicts |
| #4994 | AC-3 | Arm P-9d: a `--non-interactive` run; read `platform-config.toml` for `master_enabled = false` and stderr for the activation prompt's needle | The key is set; the prompt is absent · control: a pre-fix closed-stdin run prints the prompt |
| #4994 | AC-4 | Join the backslash-continued lines of `core/deploy/tests/test_upgrade_config_durability.sh`, then count `"${SETUP}"` invocations carrying `--non-interactive` without `0<&-` (DEV-9) | At least 1 — the design's GREEN count is 3 (baseline 0) · control: the same joined count of closed-stdin `--non-interactive` invocations → 10; all `"${SETUP}"` invocations → 14 at `8e0ee084` |
| #4994 | AC-5 | Commit A (the tests alone) against the pre-fix installer, its RED read from the PR's check run (Q1): P-9c, P-9e and P-9f; P-10's installer check; Case 12 under the harness; the P-9e precondition and a per-arm marker proving each arm reached its prompt (#7861 FM-2) | Each stdin-open arm FAILs with exit 124 and the sentinel; P-10 FAILs naming `2440,2870,3543,4467`; Case 12 rc 124 · control: P-9a, P-9b, P-9g, the P-9 precondition and every pre-existing assertion PASS |
| #4994 | AC-6 | `PMO_REGRESSION_EMIT=0 bash core/deploy/tests/run-install-regression.sh`, the durability member | Every closed-stdin `--non-interactive 0<&-` arm passes, graded against 10 invocations (REC-10); counts are deltas on the post-#4993 baseline measured at this slice's entry: +9 (+11 with REC-6), 0 failed |
| #5265 | AC-1 | `bash core/deploy/tests/test_refresh_surfaces.sh` — Arm 8 of the merged Change 8: `<tree>/update.sh --surfaces-only --force-regen` for the fixture primary, a nested worktree and an out-of-tree worktree, each run from its own tree (#7863 PR-2); compare the manifest-resolved targets with each file's `managed_at` marker line removed, and run the root-equality probe on each | Identical target sets, and the probe passes on every run · control: Arm 8c; a copy with one token row's root altered makes the comparison non-empty and fails the probe; the pre-fix worktree run differs (RED) |
| #5265 | AC-2 | The root-equality probe (#7756 D&R 2, Q5), run inside Arm 8 of `bash core/deploy/tests/test_refresh_surfaces.sh`: for every token row of the source template (168, counted at run time), the deployed allowlist carries that row with `[PMO_PLATFORM_ROOT]` replaced by the canonical root computed independently (the installed repository's main working tree); the distinct roots of the worktree-glob rows equal that root | 0 missing · sensitivity: a nested-worktree root and an out-of-tree-worktree root each report every row missing · specificity: a correct surface reports 0 missing, although its 85 worktree-glob rows (86 lines) legitimately contain `/.claude/worktrees/*/` |
| #5265 | AC-3 | `python3 -m pytest core/deploy/tests/test_compose.py` — the tier-ladder arms (primary, nested and out-of-tree worktrees resolve to the primary; a plain tree resolves only through its record, never to itself; a bare repository's worktree is unresolvable; the refusal set rejects a linked worktree, a `.claude/worktrees` segment, `*`, `?`, `[`, tab, newline, carriage return and, on POSIX, `\`); then the docstring, `--help`, and `python3 core/deploy/compose.py resolve-root --source-tree <plain tree>` | Green; the stated order ends at a repository-canonical anchor (tier 5, the enclosing repository's main working tree) and otherwise fails; the plain-tree query exits 3 naming the reason · control: the pre-fix self-location arms are rewritten, not kept |
| #5265 | AC-4 | `bash core/deploy/tests/test_refresh_surfaces.sh` — Arm 7 (the install record's `source_repo_path` equals `pwd -P` of the fixture primary, and `source_repo_path_source` names the tier that supplied it, #7862 CD-2) and Arm 9 (with `source_repo_path` deleted, resolution falls back to the primary's main working tree and names that tier; A-5 restores the record byte-for-byte); plus a legacy-record arm, a record without the provenance key naming another existing clone | Arms 7 and 9 PASS; the legacy record is used only when tier 5 cannot resolve or agrees with it, otherwise a WARN names both roots; the installer never records an empty `source_repo_path` — it falls back to the raw value with a WARN, or refuses, and says which · control: pre-fix the record is written raw, by full installs only, and read by nothing |
| #6168 | AC-1 | `bash core/deploy/tests/test_refresh_surfaces.sh` — Arm 8 as amended by A-3: refreshes from the main checkout, a nested worktree and an out-of-tree worktree against one sandbox workspace, each rewriting every manifest-resolved target (21 at `40cec0c7`, counted at run time); compare the three target sets with each file's `managed_at` marker line removed | Identical, and neither worktree's own path appears in any target · control (8c): a worktree whose allowlist template carries one additional branch-only tool block changes the set by exactly that block, bound to the main checkout, plus the allowlist's two hash markers |
| #6168 | AC-2 | `bash core/deploy/tests/test_refresh_surfaces.sh` — #5265's root-equality probe (D-AC2-Method RE) over the deployed allowlist: every template row carrying `[PMO_PLATFORM_ROOT]` (168 at `40cec0c7`, counted at run time) present with the token replaced by the installed repository's main working tree, and the distinct worktree-glob roots equal to that root | 0 missing and 0 outside the resolved root · sensitivity: a nested-worktree root and an out-of-tree-worktree root each report every row missing · specificity: a correct surface reports 0 missing, although its 2 `[CLAUDE_WORKSPACE_ROOT]` rows lie outside the install root |
| #6168 | AC-3 | The suite's existing OPERATOR ADDITIONS sentinel arm (planted in Arm 1, asserted in Arm 5); Arm 8 also asserts that the sentinel survives every checkout, worktree and branch refresh | PASS |
| #6168 | AC-4 | Arm 11 of `bash core/deploy/tests/test_refresh_surfaces.sh` over six refreshes — main checkout, nested, out-of-tree and branch worktrees with the record present; the nested worktree with the record absent; the nested worktree after the heal, record restored — with stderr matched as a fixed string for the prefix `INFO: Resolved [PMO_PLATFORM_ROOT] = `, and a control arm (#7863 FM-3) | Exactly one line per run naming the main working tree, the tier (`install-record`, or `main-worktree` with a `NOTE:` naming the skipped tier when the record is absent) and the invoked checkout; an absent or empty log FAILs · RED at C-6168a: 0 such lines in all six logs |
| #5274 | AC-1 | `git grep -n -F 'skill-editor-exemption-list.txt' -- '*.sh' ':!release/releases/**'` over the code consumers; E2E-1 (the manifest row's resolved write target equals `pmo_skill_editor_exemption_list_for` on the same root) | Only the resolver, the manifest seed path and derived test lines remain — one resolution site, every consumer calling it; E2E-1 green. Scope: the default root, or a root exported as `CLAUDE_WORKSPACE_ROOT` (#7864 PR-1's residuals recorded in the ADR) · control: at the pin the same search finds the divergent consumer spellings |
| #5274 | AC-2 | `bash core/hooks/tests/block-skill-direct-edit.test.sh` — E2E-2 (the writer `allowlist-add.sh` driven at the manifest-resolved path, then the hook on the added skill), E2E-3 (its sensitivity control) and E2E-6 (the hook and the writer copied into a sandbox `.claude/hooks/` and run with `CLAUDE_WORKSPACE_ROOT` and `PMO_INSTANCE_PATH` unset — the production root derivation); the RED-first observation is read from the PR's check run (Q1) | The exemption is granted (exit 0, no `BLOCK-SKILL-EDIT-00[12]`); E2E-3 blocks with `BLOCK-SKILL-EDIT-001`; E2E-6 grants, and its unlisted-skill control blocks · RED before the fix: the writer refuses the target and the hook blocks; E2E-6's mutation (the hook's root derivation one level short) turns it RED |
| #5274 | AC-3 | The rename-reference-cascade sweep for the superseded spellings OV-1..OV-4 — `git grep -n -F -e '.claude/skill-editor-exemption-list.txt' -e '<OPERATOR_INSTANCE_CLAUDE_DIR>/skill-editor-exemption-list.txt' -e '/../skill-editor-exemption-list.txt' -e '${CLAUDE_DIR}/skill-editor-exemption-list.txt' -- ':!release/releases/**'` — plus #7864 PR-3's emphasis-stripped probe and its added rows (`update.sh:150`; `install-tests.yml:1188`, `:1209` and `:1212` PRESERVE with reason; `docs/UPDATE.md:103`, `:107` and `:109`), each hit read and classified | `[REFCASCADE: … pre 10 / post 0]`; historical release plans preserved with reason · control: the pre-change count of 10 is the sensitivity arm |
| #5274 | AC-4 | Commit order from the branch history (the gate widening in C5 follows the single resolver at C3 and the cascade at C4); `bash core/deploy/tests/test_install_end_to_end.sh` — new Stage-4 arms under unused IDs (#7864 FM-4 (a)), graded by arm message rather than label: a real update with the list absent; a lossless legacy copy, retired only by the reconcile phase after `refresh_hooks` (Q8), its backup asserted by the exact retired name `hook-skill-editor-exemption-list.txt.legacy` in a backup directory whose name lacks `-instance-` (FM-4 (b)); a legacy copy with an extra entry | The absent-list update exits 75 with no `REFRESHED:` and names the list; the lossless copy is retired only after the hook refresh, never under `--surfaces-only`, which omits the step or detects and WARNs; the extra entry is WARNed with the writer command and the copy kept · RED at the C4 commit's check run, GREEN at C5 |
| #5274 | AC-5 | A named read at Stage 13 of the record on #4449, in References-only phrasing | Its AC2 residual recorded as closed for every hook-paired surface, or the remainder named |
| #7497 | AC-1 | `bash core/hooks/tests/block-destructive.test.sh` — two arms whose target is a primary Layer-1 path outside the declared exemptions (the classes `CLAUDE.md`, `pmo-platform/**`, `.claude/settings.json`, `.claude/hooks/*`, `.claude/rules/*`), one from a primary-rooted session and one from a worktree-rooted session | Exit 2 naming `BLOCK-DESTRUCTIVE-019` on both · RED before: the worktree-rooted arm allows today |
| #7497 | AC-2 | The same suite: a primary-rooted session writing a target inside `pmo-platform/.claude/worktrees/<name>/`, plus FM-2 (a), an Edit of an existing file inside the sandbox worktree | Exit 0 on each · RED before: the primary-rooted worktree write is refused today |
| #7497 | AC-3 | The same suite: traversal arms — a target whose as-written spelling carries a `..` or `.` segment over the worktree prefix while naming a primary Layer-1 file | Exit 2 on each; the dot-segment guard runs ahead of the worktree arm |
| #7497 | AC-4 | The same suite plus the aggregate harness through #6896's documented invocation; a verdict diff against the pre-change suite; the Block C variant whose `CLAUDE_WORKSPACE_ROOT` is spelled through a symlink to a directory that does not exist yet (#7865 FM-1); FM-2's remaining arms; INT-5 — the regression's hook floor under the row-5 recipe — graded from the CI record (Q1) | FAIL=0; exactly three arms invert — `:2882-2884`, `:2898-2900` and `:3055-3057`, each named with its rationale (the target-only tightening, Q16); every other -019 arm, the analysis carve-out's included, keeps its verdict; the Block C variant and FM-2's arms PASS; INT-5 reads a block-destructive FAIL count of 0 |
| #7497 | AC-5 | The Cascade-Sweep over the five non-test files: `git grep -n -i -F -e "cwd is not under" -e "is not under pmo-platform/.claude/worktrees" -e "worktree cwd" -e "non-worktree context" -e "non-worktree cwd" -e "relies on the payload" -e "cwd under a worktree allows" -e 'cwd=${CWD}' -e "two exemptions" -- core/hooks/block-destructive.sh core/rules/bypass-mode-readiness/block-destructive.md core/rules/bypass-mode-readiness/_cross-cutting.md core/rules/bypass-mode-readiness.md core/disciplines/operating-model.md` — the `two exemptions` pattern stays in the set because option (a) is adopted, under which the new text reads three; plus arm T7497-S1d's stderr pattern (the block message names the refused target) | 0 · control: 13 on the pre-change files, the same five (#7865 PR-2); S1d PASS |
| #6440 | AC-1 | `bash core/hooks/tests/block-rm-prefer-trash.test.sh`, run through #6896's documented invocation (Q17: INT-1 rewritten against Q2) — MEM-01..MEM-05: `trash` of a scratch `*.md` entry directly in the declared store, with no bypass; plus the CD-2 arm (one admission-log row per admission) and the FM-3 arm (a store declared outside user scope gets the memory-specific refusal, not the generic cancel text) | Exit 0 on each admission, one admission-log row each; the FM-3 arm refuses with the memory-specific message · RED before: `BLOCK-TRASH-003` |
| #6440 | AC-2 | The same suite: MEM-06..MEM-27a plus the existing BLOCK-TRASH-001 and -003 arms — `rm` or `trash` outside both roots; a subdirectory or a non-`.md` target in the store; the store's index file; a traversing path | Exit 2 with the named rule on each · control: the AC-1 admission arms |
| #6440 | AC-3 | The mechanism-block census (#7764): over the markdown under `core/`, `release/references/`, `release/governance/`, `release/skills/`, `operations/` and `docs/` (excluding `release/releases/` and both ADR directories), a blank-line-delimited block that names an `evict` stem and a removal verb is HOME inside § 7 of `core/disciplines/knowledge-architecture.md`, CITED when it names `knowledge-architecture`, `encode-and-evict`, `memory-corpus-boundary` or `Memory↔corpus boundary`, and UNCITED otherwise; run arms plant one uncited restatement and one citing block | The UNCITED set stays within the baseline's three N/A blocks; the new blocks in `autonomy-tiers.md`, the fragment and the index are CITED; § 7 holds the home blocks · the planted arms classify as planted |

**AC baseline** (replaces the Stage-4 plan's):

`ac_baseline: { #4993: 5, #4994: 6, #5265: 4, #5274: 5, #6168: 4, #6440: 3, #6896: 3, #7497: 5, read_at: 35dbf418, re-read: 2026-09-26 Commit 0 }`

Re-read at Commit 0: the eight issue bodies carry 35 `- [ ]` criteria in total, matching the rows above one for one, in list order. The Stage-4 line was `{ #4993: 5, #4994: 6, #5265: 3, #5274: 5, #6168: 4, #6440: 3, #6896: 3, #7497: 0 (5 drafted), read_at: 8e0ee084 }`; #5265 gained AC-4 and #7497 its five criteria in the Stage-4 follow-through (DEV-6).

### Proposed criteria (not yet on the card)

Q5 records two criteria for #7497 as **proposed**. They are not bound as rows until the hub adds them to the card; the #7497 slice then binds them.
- **#7497 AC-6 (proposed, under (B)):** a target whose resolved location lies outside the exemption home it is spelled inside is blocked, and a target the hook cannot resolve receives no exemption. Method: the sandbox arms T7497-L2..L6, with FM-2's third arm covering the unresolvable clause (#7865 PR-2).
- **#7497 AC-7 (proposed, under (a)):** a roadmap instance under `pmo-platform/roadmaps/` is writable from a primary-rooted and from a worktree-rooted session, and the tracked `roadmaps/README.md` is blocked in any case spelling. Method: T7497-R1..R8, plus #7865 FM-4's arm.

### Integration criteria (from the designs, as rendered)

Graded at Stage 8 Phase B under the standard per-criterion verdict enum, from the merged tree.
- [ ] **INT-1 (#4993 × #6896, `run-install-regression.sh`):** the merged runner (a) sources nothing; (b) prints exactly one `INSTALL-REGRESSION:` line whose format carries `[env: %s; skipped: %d]`; (c) adds the hook floor's `PASS=`/`FAIL=` into the totals the verdict reads; and (d) the hook-floor invocation passes `--sandbox` with a non-empty, freshly created directory (Q5; #7860 FM-4).
- [ ] **INT-1 (#4994 × #4993, the durability suite), restated per Q5:** the P-9 and P-10 arms stay inside the suite's R-8 sandbox; R-8 PASSes where a live install exists and SKIPs — never PASSes — where none does; counts are deltas on the post-#4993 baseline (+9, or +11 with REC-6), 0 failed.
- [ ] **INT-2 (#4994 × #4993, the verdict line):** the durability member reports PASS under both the row-5 recipe (the user-base pin included) and the real HOME — graded from the CI record (Q1).
- [ ] **INT-1 (#5265 × #4994):** graded as one run with CIAC-3, against #7862 FM-4's independent oracle.
- [ ] **INT-1 (#6168 × #5265, `resolve_platform_root` → the composition writes):** the report line interpolates the canonical root and its source; `update.sh` carries exactly one `lib_compose_resolve_root` call; for each of Arm 8's runs, Arm 11 reads the main checkout as root and #5265's probe finds that same root baked in the same run.
- [ ] **INT-2 (#6168 × #5265, `core/standards/depersonalization-spec.md` § 2):** the clause "`update.sh` resolves it once per run, reports the value and the tier that supplied it" is true of the merged tree.
- [ ] **INT-1 (#5274 × #5265, `update.sh`):** the absent-target branch carries `is_hook_read_instance_file`; both `lib_compose_regen` call sites carry #5265's threaded root; neither edit reverts the other; the legacy reconcile runs as its own phase after `refresh_hooks` (Q8).
- [ ] **INT-2 (#5274 × #6168):** a refresh from a linked worktree and one from the primary produce instance-tier exemption lists identical apart from `managed_at`, read from #6168's A-3 arm, the member matched by basename.
- [ ] **INT-3 (#5274 × #6896):** in the helper's default layout and in an explicit `--sandbox`, the list exists at the layout root's resolved instance-tier location (`PMO_INSTANCE_PATH` unset), lies inside #6896's recorded footprint and is removed by the purge on rebuild; E2E-6 exercises it; the runner reports FAIL=0.
- [ ] **INT-1 (#7497 × #6896):** run exactly as #6896 documents it: AGGREGATE FAIL=0; the block-destructive suite's arm-ID set gains the design's T7497 arms plus FM-1's Block C variant, FM-2's three arms, FM-4's arm and CD-2's arm; no BLOCK-DESTRUCTIVE-022 refusal of that invocation.
- [ ] **INT-2..INT-4 (#7497 × #5274):** the `_cross-cutting.md` statements describe shipped state (`:124-126` for #5274; `:135` in target wording, 0 hits for "worktree cwd"); the generator's `--check` exits 0 on the merged tree; the `operating-model.md` -019 and SKILL-EDIT bullets each describe their own rule.
- [ ] **INT-5 (#7497 × #4993, on CIAC-2; #7865 FM-1):** the regression's hook floor under the row-5 recipe reports a block-destructive FAIL count of 0 — graded from the CI record (Q1).
- [ ] **INT-1 (#6440 × #6896), rewritten against Q2 (Q17):** through #6896's two literal commands from the spoke's worktree root, the `block-rm-prefer-trash.test.sh` arm-ID set is MEM-01..MEM-27b plus the CD-2 and FM-3 arms, FAIL 0, and the AGGREGATE counts them.
- [ ] **INT-2 (#6440 × #7497):** the generator's `--check` exits 0; the index carries #7497's target-keyed -019 row and #6440's memory-store scope phrase; neither regeneration dropped the other's fragment.

### Release-Level Verification

- [ ] File integrity: `bash -n` on every edited shell file; `python3 -m py_compile core/deploy/compose.py core/deploy/qa/checks.py`.
- [ ] Hook harness through #6896's documented invocation and in the CI hook-tests job: FAIL=0; each suite's arm-ID set contains its post-sync baseline set plus the declared new IDs (CIAC-6).
- [ ] Install regression (row 5) in CI: `VERDICT PASS` with its stamp; the override record once its producer exists (R18).
- [ ] Composition units (row 1) and the deploy suite (row 2) green in CI.
- [ ] Index freshness after each fragment edit: `python3 core/deploy/tools/build-hook-registry.py --check`, exit 0.
- [ ] ADR number integrity and durability: `python3 release/tools/check-adr-numbers.py` passes; `renumber-adr.py --detect` reports each new record `BINDS` at authorship; the ADR durability lint reports no finding on the three records.
- [ ] Pre-merge required subset: `deploy.sh --check-required-subset` — index FRESH, mirror-pair parity PASS, rules budget PASS.
- [ ] Skill-package freshness: N/A — measured at Commit 0 (§ Verification Evidence).
- [ ] `domain_practice` label present (Commit-0 survival row 1).
- [ ] CIAC-1..CIAC-6 (below).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria** — graded at Stage 9 QC3.5 on the merged PR, as corrected by Q5. Each stays a cross-issue criterion because at least two of its cards edit or depend on the named surface.
- [ ] **CIAC-1 (#5265 × #6168 on `resolve_repo_root` and the composed allowlist):** A composition refresh run from the primary checkout, from a nested worktree and from an out-of-tree worktree, against one sandbox workspace, composes surface sets identical apart from their `managed_at` marker lines; every run rewrites every manifest-resolved target; and on each run every template token row is bound to the canonical primary root (the root-equality probe: 168 token rows, distinct worktree-glob roots equal to that root). *Method:* `bash core/deploy/tests/test_refresh_surfaces.sh` — Arm 8 as amended by #6168's A-3 (the named member matched by basename) and Arm 8c; Stage 10 repeats the comparison and never uses `diff -r` · control: Arm 8c, where one branch-only tool block changes the set by exactly that block, bound to the primary; the naive `/.claude/worktrees/` segment count is not a criterion (86 on a correct build). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#4993 × #4994 on `test_upgrade_config_durability.sh` and `run-install-regression.sh`):** The standing regression prints `VERDICT PASS` under the selection map's § 3 row-5 recipe — `HOME` a fresh `mktemp -d`, `PYTHONUSERBASE` pinned from `/usr/bin/python3` before the override — and under the real HOME, each verdict line's stamp naming its environment; and the durability suite carries at least one `--non-interactive` invocation with stdin open. *Method:* the CI record (Q1) of `bash core/deploy/tests/run-install-regression.sh` under each environment with `PMO_REGRESSION_EMIT=0` (the override leg's CI producer is open, R18); then join the suite's backslash-continued lines and count `"${SETUP}"` invocations carrying `--non-interactive` without `0<&-` → at least 1 (the design's GREEN count is 3) · control: the same joined count of closed-stdin `--non-interactive` invocations → 10; all `"${SETUP}"` invocations → 14 at `8e0ee084`. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#4994 × #5265 on `docs/scripts/setup-workspace.sh`):** The install-time root-recording step adds no unguarded prompt: every human-answer `read` in the installer sits behind the `NON_INTERACTIVE` guard (guarded equals total), a `read` fed by input redirection on its own line counting as a data read (Q6); and a stdin-open `--non-interactive` install from a linked worktree completes and records the canonical root. *Method:* the independent oracle Q5 names (FM-4 of the #5265 review) — `bash core/deploy/tests/test_refresh_surfaces.sh` Arm 7 run under #4994's open-stdin harness shape (`run_open_stdin`), comparing the recorded `source_repo_path` with `pwd -P` of the fixture primary, never with the resolver's own output; plus the P-10 census in `bash core/deploy/tests/test_upgrade_config_durability.sh` → `5 5 -` · control: the pre-fix installer reads `5 1 2440,2870,3543,4467`. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#5274 × #6896 on the exemption list across layouts):** The path `block-skill-direct-edit.sh` resolves for its exemption list exists and carries the canary in a fresh sandbox install and in the `setup-ci-layout.sh` layout (its default site and an explicit `--sandbox`); step 3b writes it through #6896's recorded footprint, so the purge removes it on rebuild; and the deployed-shape arm E2E-6 — the hook and the writer run with `CLAUDE_WORKSPACE_ROOT` and `PMO_INSTANCE_PATH` unset — grants the exemption. *Method:* `bash core/hooks/tests/block-skill-direct-edit.test.sh` (Test 3 and 3b, E2E-1..E2E-6) and `bash core/hooks/tests/setup-ci-layout.test.sh` (the footprint and purge arms), read from the CI hook-tests log (Q1) · control: the pre-fix CI layout lacks the file (the co-discharge candidate's finding), and E2E-6's mutation — the hook's root derivation one level short — turns it RED. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#7497 × #6440 × #5274 on `core/rules/bypass-mode-readiness.md`):** The committed index equals the generator's output, and the shipped rows describe the shipped predicates: -019 target-keyed (#7497's cascade-sweep file set carries 0 superseded spellings) and the BLOCK-TRASH memory-store arm (#6440's new wording present in the fragment and the index, 0 at baseline). *Method:* `python3 core/deploy/tools/build-hook-registry.py --check` → exit 0; `grep -c -i 'auto-memory' core/rules/bypass-mode-readiness/block-rm-prefer-trash.md` → at least 3, and the same count over `core/rules/bypass-mode-readiness.md` → at least 3; #7497's Cascade-Sweep command over its five non-test files → 0 · control: the sweep reads 13 on the pre-change files. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (#6896 × #5274 × #7497 × #6440 on the hook-suite runner):** The full harness, run through the invocation #6896 documents — `bash core/hooks/tests/setup-ci-layout.sh` then `bash .claude/hooks/tests/test-runner.sh` from the spoke's worktree root, the site Q2's scoped carve-out admits — reports FAIL=0; each suite's arm-ID set contains its post-sync baseline set plus the new arm IDs #6896, #5274, #7497 and #6440 declare; and no BLOCK-DESTRUCTIVE-022 refusal of that invocation is recorded. *Method:* per-suite arm-ID sets re-baselined at the post-sync base and compared by ID, read from the CI hook-tests log (Q1) and the agent-side run · control: `LAYOUT-DOC-03a/b` prove both refused pre-change forms hermetically, against the layout's own hook and log; no live refusal is tripped. *Graded at Stage 9 QC3.5 on the merged PR.*

**Population enumerated** for cross-issue cohesion: shared file, shared function or seam, shared test harness, shared record schema, shared doc surface.

---

## Quota Budget

**Superseded by the operator's pacing decision** (#7684 comment 5841863468, DEV-15): one spoke in flight at a time (W_max 1) until the usage cap stops the run, with checkpoints so a fresh session resumes with no lost work. Checkpoint B still renders before every launch; when its weekly axis renders DEFER, that decision overrides it and the launch line cites it. The Stage-4 verdict (WARN, window UNSTATED, W_max 2) is historical.

---

## Release Class declaration

**`cross-cutting`** — ratified at the Stage-4 gate (DEV-5 wrote the milestone's rationale in template form).

- **Rationale:** eight fixes share root-cause class C19 (a scope predicate anchored on invocation context, not the governed subject) and compose over shared surfaces — the compose resolver, the install durability suite, the hook-suite runner and the generated hook registry — giving ≥3 in-bundle compositional edges (trigger c). Novel triggers also fire (Stage-5 design decisions), and cross-cutting dominates under multi-trigger resolution.
- **Differentiation posture:** Engagement **Tight** · Stage 9 review **Deep** · Stage 5 bias **ALL** · outcome window **30-day**.
- **Size bound:** `effective_pts: raw 30 × 1.3 = 39 — above band vs 15-25`, kept under the G3-15 Override (Q10).

---

## Release Outcome Statement

Transcribed from the milestone description as refreshed at the Collective Review (Q4).

**AFTER** — Install, deploy and guard decisions resolve from the subject they govern — the canonical repository, the declared surface path, the write target — rather than from where they were invoked. A refresh from any checkout, an unattended install with stdin open, and the regression suite under a sandboxed HOME each produce the same result as their canonical counterpart, and the platform's guards admit the paths their documented procedures use while still refusing everything else.

**BEFORE** — Several paths key on the caller's context instead: a refresh from a worktree stamps that worktree's path into deployed surfaces, one exemption list resolves to four paths across five consumers, an unattended install hangs when stdin is open, and the regression suite reports FAIL under its own sandbox while its safety proof passes on an empty subject. Guards decide on the session's working directory or the workspace root rather than the target, so documented invocations are refused.

**Actor(s):** operators running install and update from any checkout; Stage 6–8 spokes running the hook and install suites.

**Success Indicator:** On the merged tree, `run-install-regression.sh` prints `VERDICT PASS` under both `HOME=$(mktemp -d)` — read as the runtime-suite selection map's § 3 row-5 recipe, including its user-base pin — and the real HOME. At Stage 12, after the operator's `./update.sh` from the primary checkout, a `--surfaces-only --force-regen` refresh run from a linked worktree at the merged commit leaves the deployed allowlist identical apart from `managed_at`, with every token row bound to the primary.

---

## Tier-A Activated Design Artifacts

| Artifact | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| `release/references/standards/runtime-suite-selection-map.md` § 4 — the "Verdict-line stamp" table (embedded; #4993) | data flow | a K1 cross-stage contract with a producer→consumer field flow across ≥2 entities: the runner's verdict line → the Stage 7 A8 `Env` cell → the `test-run` payload `env:` → Stage 8 citations | A — NEW (embedded) | Stage 13 refreshes it if the stamp's fields or vocabulary change |
| The `[PMO_PLATFORM_ROOT]` resolution contract and its five-tier ladder (#5265); durable home `core/standards/depersonalization-spec.md` § 2 | data flow + process flow | a contract field's semantics change (`source_repo_path`) and an output format is added (`resolve-root`), with ≥2 producers and consumers | A — NEW | Stage 13 confirms the § 2 ladder text matches the shipped `resolve_repo_root_with_source` tier order |
| The exemption-surface resolution contract (actor × role × path; #5274), landing as the header contract block of `core/deploy/lib-instance-path.sh` | data flow | a contract with ≥2 producer/consumer entities (installer, update, writer → hook, Checks 6/10) | A — NEW (embedded) | refreshed if a consumer is added |
| The EVICT execution path (Mermaid; #6440), embedded in `core/disciplines/knowledge-architecture.md` after the new EVICT paragraph | process flow (3 lanes) | ≥1 gate (the hook's admission) and ≥2 actors (the executor and the operator) | A — NEW (embedded) | refreshed at Stage 13 if the EVICT mechanism changes again |

#6168 adds no Tier-A artifact; a Tier-B refresh rides #5265's G-CL6. #6896 and #7497 activate none.

---

## Rollback Strategy

| Issue | Rollback method | Complexity |
|---|---|---|
| #6896 | `git revert` of the slice commits, callers included. **Keep the new `.gitignore` lines** (or sweep the checkout-root layouts first): a revert that drops them leaves every populated checkout one `git add` away from committing token-resolved files that carry a home path (#7859 PR-3) | Low |
| #4993 | `git revert` of the slice | Low |
| #4994 | `git revert` of the slice; the flagged recovery exit returns to 0 | Low |
| #5265 + #6168 | Revert both slices together (the shared `test_refresh_surfaces.sh` arm block; the resolver and its report line), then regenerate surfaces from the primary checkout. A canonical `source_repo_path` and its provenance key are inert to the prior resolver | Medium |
| #5274 | Revert the slice; the gate widening reverts with it. A retired legacy copy is restored from its backup; an operator entry added at the canonical path after merge must be re-added at the hook-tier copy | Medium |
| #7497 | Revert, then republish the hook. Reverting **re-opens** the worktree → primary Write/Edit path and reinstates the roadmaps refusal for primary-rooted sessions. Verify with the -019 arms | Medium (MODERATE) |
| #6440 | Revert, then republish the hook; item 8a reverts with it. A numbered, merged ADR is superseded, never deleted (the gap-free sequence). Evictions already made are recoverable from Trash | Medium (MODERATE) |

**Whole release:** a partial revert per slice (regenerate the index after any fragment revert); a full restore by `git revert -m 1 <merge>`, then a hook republish and a surface regeneration from the primary checkout; a forward fix is preferred for a well-understood defect. **A claimed version tag is retained and recorded, never deleted** — version tags are host-protected. After the claim, a merge revert stops once, on this plan's claim-stamp rename: keep the stamped plan, `git add` it and continue.

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/hooks/block-destructive.sh` | `<OPERATOR_INSTANCE_CLAUDE_DIR>/hooks/` | hook refresh (update path) | **Check 79 content MATCH** — never the publisher's exit status |
| 2 | `core/hooks/block-skill-direct-edit.sh` | same | same | same |
| 3 | `core/hooks/allowlist-add.sh` | same | same (unconditional) | same |
| 4 | `core/hooks/block-rm-prefer-trash.sh` | same | same | same |
| 5 | `core/hooks/block-fragile-refs.sh` (comment edit, #5274) | same | same | same |
| 6 | `core/deploy/lib-instance-path.sh` — the resolver's home. The Stage-4 row for a new `core/hooks/lib/` resolver **did not fire** (`CONDITIONAL:RESOLVER-LIB-ADDED` resolved false) | `<OPERATOR_INSTANCE_CLAUDE_DIR>/hooks/` (co-deployed beside the hooks) | the same hook refresh | present + content MATCH |
| 7 | `core/config/allowlists/script-execution-allowlist.txt` | `<OPERATOR_INSTANCE_CLAUDE_DIR>/script-execution-allowlist.txt` | composition regeneration (managed section; OPERATOR ADDITIONS preserved); the template SHA changes, so every install regenerates on its first post-release update (HL-1) | **The root-equality probe plus the report line (Q5):** every token row (168) bound to the canonical primary root; the report line names the primary checkout and its tier; the operator region byte-identical; a pre-write backup exists |
| 8 | `core/config/allowlists/skill-editor-exemption-list.txt` | the single resolved instance-tier location | instance-tier composition; the legacy reconcile phase after the hook refresh (Q8) | canary present; operator entries from **both** existing copies preserved |
| 9 | `core/rules/skill-deployment.md` — the one mirror-pair member this release edits | `<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/` | `deploy.sh --deploy` (mirror) | Check 9. The generated `core/rules/bypass-mode-readiness.md` is **not** a mirror-pair member, so it has no deployed copy (Q5: IP-5's Check 9 leg is vacuous) |
| 10 | #5265's install-recorded source root | the install record | **the next install flow** (Q5) | per Q15's CD-2 outcome: the record carries `source_repo_path` equal to the canonical primary root and a `source_repo_path_source` naming its tier; a legacy value without the key is read and reported, never asserted canonical |
| 11 | Success Indicator clause 2 (Q4) — operator-observed | the deployed allowlist | a `--surfaces-only --force-regen` refresh from a linked worktree at the merged commit, after the operator's `./update.sh` from the primary checkout | identical apart from `managed_at`, with every token row bound to the primary |

**Repository-only surfaces** (no deployed copy to sync): the test suites (CI- and agent-executed), the registry fragments and their generated index, the reference and standard docs, `docs/UPDATE.md` and `docs/INSTALL.md`, the ADRs and this plan.

**`deliverable_state: deployed-copy-synced`** is reached at Stage 12, when rows 1–11 verify by content.

**Schema and data migration.** The exemption-list consolidation — the legacy reconcile retires a lossless copy after the hook refresh and WARNs on extras (Q8) — and one additive install-record key, `source_repo_path_source` (`STATE_SCHEMA_VERSION` unchanged, Q13). Otherwise N/A — enumerated over {tracker schemas, config schemas, persisted state files}. **Stage-12 premise:** the auto-memory store's location setting sits in the operator's user scope (#6440 design R4, confirmed by the hub before the Collective Review); re-read at Stage 12.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | [SCOPE] G3-15 keep-with-rationale Override at the Stage-4 gate | #7684 comment 5826471133 | RECORDED — its amount is superseded by the Override at 39 (row CR-Q10) |
| **DEV-2** | [ADJUST] #7497 sized at Stage 4 | #7684 comment 5826471133 | RECORDED — re-sized M at the Collective Review (Q10) |
| **DEV-3** | [ADJUST] #6168's placement basis | #7684 comment 5826471133 | RECORDED |
| **DEV-4** | [ADJUST] the Release Outcome Statement replaced | #7684 comment 5826471133 | RECORDED — clause 2 of its Success Indicator later replaced (row CR-Q4) |
| **DEV-5** | [ADJUST] `## Release Class` rewritten in template form | #7684 comment 5826471133 | RECORDED |
| **DEV-6** | [ADJUST] the A0.5 refinements and A0.6 crisping | #7684 comments 5826471133 (authorized) and 5826554941 (completed) | RECORDED |
| **DEV-7** | [ADJUST] the Parallelization Map added | #7684 comment 5826471133 | RECORDED — refreshed at the Collective Review (Q11) |
| **DEV-8** | [PROCESS] the Stage-4 hub brief | #7684 comment 5826471133 | RECORDED |
| **DEV-9** | [ADJUST] probe validity: #4994 AC-4 and CIAC-2 | #7684 comment 5826554941 | APPLIED — § Verification Plan, #4994 AC-4; CIAC-2 |
| **DEV-10** | [ADJUST] the reviewer agent type | #7684 comment 5829665231 | RECORDED |
| **DEV-11** | [ADJUST] the Stage-5 brief content | #7684 comment 5829665231 | RECORDED |
| **DEV-12** | [ADJUST] the Collective Review assembly brief | #7684 comment 5839221431 | RECORDED |
| **DEV-13** | [ADJUST] the discharge of AI-003 | #7684 comment 5839221431 | RECORDED |
| **DEV-14** | Stage 6 entry | #7684 comment 5841775627 | RECORDED — for the Stage 13 retrospective |
| **DEV-15** | quota pacing until the cap | #7684 comment 5841863468 | RECORDED — for the Stage 13 retrospective; § Quota Budget |
| **CR-ADJ** | **The Tier-1 [ADJUST] at Engineering Commit 0 (Q5, option (a))** — every correction in the evidence record's Q5 ("Corrections to the plan of record", "Corrections to card acceptance criteria and methods", "Corrections to text"), as one set; CIAC-3 graded by #7862 FM-4's independent oracle | Collective Review Decision Recorded, #7684 comment 5841113925; the option in full at comment 5840282806 (§ 10, Q5) | **APPLIED** in this commit — the 22 items and their locations are enumerated in § Decision Record → The Tier-1 [ADJUST] |
| **CR-R14** | "Override: convention `core/rules/git-workflow.md:39` worktree base accepted as diverged because it is routed out of this release (Q9) rather than corrected in #7497's slice. Deviation logged for Stage 13 retrospective." | Collective Review Decision Recorded, #7684 comment 5841113925 | **LOGGED** for the Stage 13 retrospective; the drift is routed out (routing register RR-13) |
| **CR-Q10** | The Override re-recorded at effective 39 (raw 30 × 1.3), superseding the Stage-4 Override at 30; #6896 S, #7497 M, #5274 L | #7684 comment 5841113925; the milestone #338 amendment of 2026-09-25 | **APPLIED** — § Scope; § Release Class declaration |
| **CR-VER** | D-Version re-determined: provisional `v4.70` (the Stage-4 provisional `v4.69` was claimed by `egress-hook-batch`) | #7684 comment 5841113925; this commit's re-verify | **APPLIED** — Header; § Commit-0 Version Re-Verify Record |
| **CR-Q4** | Success Indicator clause 2 replaced by a Stage-12 real-instance observation; clause 1 read with the row-5 recipe | #7684 comment 5841113925; milestone #338 | **APPLIED** — § Release Outcome Statement; § Stage Applicability Matrix (Stage 12); ODM row 11 |
| **CR-Q3** | ADR numbers are literal at authorship, in serial order (#5265, #5274, #6440), cited in prose by the slug token, reconciled at Stage 12; no number at Commit 0 — the designs' "stamp the number at Commit 0" (#5265, #6440) is superseded | #7684 comment 5841113925 | **APPLIED** — § Commit-0 Version Re-Verify Record; the FCM ADR rows |
| **CR-T2** | Tier 2 [SCOPE CHANGE] additions and drops approved at the scope-lock: #6896 from 3 to 9 files (the bridge carve-out included, Q2); #4993's stage-07 row promoted and the event-log schema added (Q5); #5265 plus four files (the allowlist header, `test_refresh_surfaces.sh`, `docs/UPDATE.md`, `core/deploy/qa/checks.py`) and its ADR; #6168's set replaced by `update.sh` and `test_refresh_surfaces.sh`; #5274 plus six files, with `docs/workspace-setup.md` dropped; #7497's roadmaps carve-out; #6440 plus `core/specs/autonomy-tiers.md` and a core ADR, less the two config files | #7684 comment 5841113925 (Q2, Q10, Q13, Q15, Q16, Q17); evidence record § 4 | **APPLIED** — § File Change Matrix |
| **PROM** | Stage-4 conditional rows **promoted in this commit** — their conditions resolved true at the Collective Review, before Commit 0: `DEFAULT-SANDBOX-CHANGES` (#6896, two rows; Q2 α changes the default); `A8-INVOCATION-CONTRACT-CHANGES` (#4993's stage-07 row, firing on the cascade basis D-6 rather than on an invocation-contract change); `DELIVERED-CONTRACT-DIFFERS-FROM-ROW` (#4994's `docs/INSTALL.md`, promoted on the E66 basis, Q14 — the unattended-contract row stays verify-only); `ROOT-THREADED-VIA-LIB` (#5265); `ROOT-REPORTED-BY-UPDATE` (#6168, R1); `REFCASCADE-CLASSIFY-UPDATE` (#5274, six rows); `EXEMPTION-LIST-IN-HOOK-LAYOUT` (#5274's step 3b); and #5265's `ADR-ROUTED` record, promoted to an unconditional ADD because Q3 (b) numbers three records and option (c) was not rendered | The matrix authoring contract (a fired conditional is promoted in the commit its condition resolves); #7684 comment 5841113925 | **APPLIED** — each promoted row names its basis |
| **ND-1** | `CONDITIONAL:QA-ANTIPATTERN-NAMED` — **NOT DELIVERED** (`release/references/pipeline/stage-08-qa-testing.md`, #4994's conditional edit): resolved false, REC-7 declined (Q14). #4993 still edits the file on its own row | #7684 comment 5841113925 (Q14) | **RECORDED** |
| **ND-2** | `CONDITIONAL:SEED-PATH-CHANGES` — **NOT DELIVERED** as declared (`docs/scripts/setup-workspace.sh`, #5274): the seed path is kept; the file is edited for a consumer-list comment only, on an unconditional row | #7760 design (its matrix row 11); Q13 | **RECORDED** |
| **ND-3** | `CONDITIONAL:E2E-ARM-IN-WRITER-SUITE` — **NOT DELIVERED** (`core/hooks/tests/allowlist-add.test.sh`): the writer → hook arm lives in `block-skill-direct-edit.test.sh` (E2E-2) | #7760 design; Q13 | **RECORDED** |
| **ND-4** | `CONDITIONAL:RESOLVER-LIB-ADDED` — **NOT DELIVERED** (`core/hooks/lib/skill-editor-exemption-path.sh` ADD and its `core/config/allowlists/script-execution-allowlist.txt` companion row): the resolver lands in `core/deploy/lib-instance-path.sh` (C1), which is already co-deployed; the new-executable companion obligation does not fire | Q13 (#5274, C1) | **RECORDED** |
| **ND-5** | `CONDITIONAL:MEMORY-DIR-FROM-PLATFORM-CONFIG` — **NOT DELIVERED** (`core/config/platform-config.toml.template`, `docs/platform-config-reference.md`): the store's location is read from the operator's user-scope settings (D-Store-Source) | Q17; Q13 (#6440) | **RECORDED** |
| **REV-7859** | #7859 → #6896 (comment 5831544548). Minor: PR-2 · PR-3 · FM-3 · FM-5 · FM-6 · CD-2 | Collective Review § 9 routing, Minor → this log (evidence record part 2/3, comment 5840282806) | PR-2 APPLIED (Q13, the D-Allowlist-Comment wording) · PR-3 APPLIED (§ Rollback Strategy) · FM-3 APPLIED (Q2, identity checks) · FM-5 APPLIED (Q2; arm IDs declared; CIAC-6) · FM-6 APPLIED (Q5 item 19) · CD-2 NOT TAKEN (Q2 = α) |
| **REV-7860** | #7860 → #4993 (comment 5833822887). Minor: FM-2 · FM-3 · FM-4 · FM-5 · FM-6 · FM-7 · FM-8 · CD-2 | as above | FM-2 APPLIED (Q5 item 14) · FM-3 APPLIED (Q4; INT-2 carries the pinned recipe) · FM-4 APPLIED (Q5 item 19) · FM-5 APPLIED (Arm 6 moved last) · FM-6 APPLIED (Q1, the `/usr/bin/python3` pin with its control) · FM-7 ROUTED (F1's population, carried under Q7) · FM-8 APPLIED (Q5 item 13) · CD-2 NOT TAKEN (Q1: CI as the observer; no runner-internal override) |
| **REV-7861** | #7861 → #4994 (comment 5834396727). Minor: PR-1 · FM-2 · FM-3 · FM-4 · CD-1 | as above | PR-1 APPLIED (Q6 (a), the fixture's must-flag lines) · FM-2 APPLIED (Q5 item 14) · FM-3 NOT TAKEN (Q5 (a): #7862 FM-4's oracle grades CIAC-3) · FM-4 APPLIED (Q14; the interactive option-E exit routed as RR-11) · CD-1 NOT TAKEN (Q13, REC-1 G1) |
| **REV-7862** | #7862 → #5265 (comment 5835052300). Minor: PR-2 · PR-3 · PR-4 · PR-5 · FM-2 · FM-3 · FM-4 · FM-5 · CD-3 | as above | PR-2, PR-3 and PR-5 APPLIED (Q5 item 15; Q13) · PR-4 APPLIED (Q5 item 18; `core/deploy/qa/checks.py` added) · FM-2 APPLIED in the merged Change 8 (Arm 9 must rewrite) · FM-3 APPLIED (Arm 6 moved last; the install record in the baseline) · FM-4 APPLIED (Q5 (a); the Q6 empty-record guard) · FM-5 APPLIED (Q13, A-3 by basename) · CD-3 NOT TAKEN (Q15 = (b)) |
| **REV-7863** | #7863 → #6168 (comment 5835688997). Minor: PR-1 · PR-2 · FM-2 · FM-3 · FM-4 · FM-5 · CD-1 · CD-2 | as above | PR-1 APPLIED (Q4) · PR-2 APPLIED (Q13, each Arm 8 refresh from its own tree; the Stage-10 recipe pins `PMO_PLATFORM_CONFIG_ROOT` and `HOME`) · FM-2 and FM-3 APPLIED (Q5 item 21) · FM-4 APPLIED (Q13) · FM-5 APPLIED (the hub's ONE merged Change 8 text) · CD-1 NOT TAKEN (Q15 = (b)) · CD-2 APPLIED (Q4) |
| **REV-7864** | #7864 → #5274 (comment 5838300298). Minor: PR-1 · PR-2 · PR-3 · FM-4 · FM-5 · FM-6 · CD-2 | as above | PR-1 APPLIED (Q13; AC-1 scoped) · PR-2 APPLIED (Q5 item 16; the #6198 claim narrowed, see § Transcription interpretations 8) · PR-3 APPLIED (Q5 item 16) · FM-4 APPLIED (Q5 item 16, (a)–(d)) · FM-5 PARTLY APPLIED (Q13, A-3 by basename; INT-2 kept as designed) · FM-6 APPLIED (Q1) · CD-2 NOT TAKEN (Q8 = (b)) |
| **REV-7865** | #7865 → #7497 (comment 5838822276). Minor: PR-2 · FM-3 · FM-4 · FM-5 · FM-6 · CD-1 · CD-2 | as above | PR-2 APPLIED (Q5 item 17) · FM-3 APPLIED (Q9 (a)) · FM-4 APPLIED (Q16) · FM-5 APPLIED (Q13) · FM-6 per Q12, outside this plan · CD-1 NOT TAKEN (Q9 = (a)) · CD-2 APPLIED (Q16) |
| **REV-7866** | #7866 → #6440 (comment 5839203338). Minor, weighed up by the Collective Review: FM-3 | as above | FM-3 APPLIED (Q17 (b)). Its Majors are decided: FM-1 by Q3; FM-2 by Q2 and Q17 (INT-1 rewritten); CD-1 NOT TAKEN (Q17 = α); CD-2 APPLIED (Q17 (b)) |
| **RES** | Residuals the designs record as accepted (routing register RR-38): #7754 G-4; #7764's card drift; #7758's note that the Arm 6 backstop is not the real instance directory | evidence record § 11.1, RR-38 | **ACCEPTED** as residual |

---

## Documentation Impact

Authored per slice at Stage 6 C1.5; status at Commit 0.

| Issue | Declared docs | Status |
|---|---|---|
| #6896 | the helper's header and USAGE; selection-map row 3; the allowlist and runner comments; the Spoke Template carve-out in `release/references/how-to/hub-spoke-bridge.md` | PENDING (slice 1) |
| #4993 | selection-map row 5, § 3 and § 4 (the stamp contract); `stage-08-qa-testing.md` `:161` and `:174`; `stage-07-dev-testing.md` `:403` and `:477-478`; `pipeline-event-log-schema.md` `:225-226` | PENDING (slice 2) |
| #4994 | `docs/INSTALL.md` § 5.5 (E66); the unattended-contract statements (usage, `install.sh`, INSTALL `:113` and `:139`) verify-only | PENDING (slice 3) |
| #5265 | `core/standards/depersonalization-spec.md` `:44` and § 2; the allowlist token header; `docs/UPDATE.md` § 3.2 and the retitled § 6.1; the ADR | PENDING (slice 4) |
| #6168 | the report line, documented by #5265's `docs/UPDATE.md` § 3.2 text | PENDING (slice 5) |
| #5274 | the ten-site reference graph; `docs/UPDATE.md` § 6.3a; the ADR | PENDING (slice 6) |
| #7497 | the -019 fragment rows and paragraphs; `_cross-cutting.md` `:135` and `:217`; the index; `operating-model.md` `:262` and `:397` | PENDING (slice 7) |
| #6440 | the BLOCK-TRASH fragment and the index; § 7's EVICT paragraph and flowchart; `autonomy-tiers.md` items 8 and 8a; the ADR | PENDING (slice 8) |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7, 8, 12 and 13.*

| Check | Result |
|---|---|
| **Commit-0 version half** | `git fetch --tags origin` and `git fetch origin main` (exit 0); the adapter's dry-run recomputes **`v4.70`** for bump-class `minor`; the slot is free on all three `claimed_set()` arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp install-resolves-identically` → **exit 0**, "verify-stamp OK — install-resolves-identically carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised", after its pre-flight line "manifest stales 0 package(s)". Exactly one double-brace `RELEASE_VERSION` placeholder in this file (the Header `**Version**` cell) |
| **Plan-driven executor at Commit 0** | `release/tools/verify-release-plan.sh --root=<hermetic stub> --format=md --stage4-comment <the Stage-4 plan comment, both parts> <this plan>`, where the stub is an archive of the branch base plus this file, with `core/deploy/deploy.sh` and `release/tools/append-pipeline-event.sh` replaced by inert stubs that exit non-zero; never against the repository root. **Verdict roll-up: 5 PASS / 1 FAIL / 10 SKIP / 30 ERROR — over 35 per-issue rows; 0 declared-deferred.** It indexes all 35 per-issue rows and all six CIACs. The 29 per-issue ERROR rows are `unclassified-method` by the executor's design (its runnable-verb set is closed to read-only queries; the `bash` suites are graded from CI). FCM-COVERAGE is ERROR `diff-unresolvable`, by construction: the stub has no git history. CIAC-5 FAILs because its `grep` reads the pre-fix fragment — 0 of the 3 required lines exist before #6440's slice. #6896 AC-2 PASSes (0 temp-root rows), and provenance survival reads 4 of 4 PASS. The PROV-DELTA PASS is not evidence on this host (its multi-line comparison does not run under the system awk); an independent read finds the Stage-4 comment's four survival elements — the label, the matrix, the CIACs, the Verification Plan — all present here, with the stamp placeholder the fifth |
| **Skill-package freshness** | **N/A — measured:** `build-skill-packages.sh --skills-for-paths` over the 60 declared paths returns no skill; sensitivity: the same query over a skill's own `SKILL.md` returns that skill |
| **Tier-0 projection** | the `BLOCK-AUTONOMY-001` union projected onto the tracked index at `35dbf418` is 3 paths; its intersection with the 60 declared paths is empty |
| **Declared paths exist** | all 63 non-ADD paths the matrix names — edit rows, conditional edit rows, READ rows and NOT EDITED rows — are tracked at `35dbf418`; the 5 unconditional ADD paths and the one conditional ADD are absent there, as a create requires |

---

## Baseline pin

- **Stage-4 pin (survival row 9):** `origin/main` `8e0ee084` — every Stage-4 anchor binds there.
- **Collective Review assembly base:** `35dbf418`.
- **Branch base (Engineering Commit 0):** `35dbf41847df2c1deab792d2944e46ac6ddd26fd`. Between the two, three write-set files moved, all from `egress-hook-batch`: `core/hooks/allowlist-add.sh`, `core/rules/bypass-mode-readiness.md` and `docs/UPDATE.md`. Each slice re-reads its anchors at entry and binds by text.

---

## Issue References

- **Members (transitioned to closed at Stage 13):** #6896 · #4993 · #4994 · #5265 · #6168 · #5274 · #7497 · #6440
- **Planning and Stage 6:** #7684 (the Stage-4 plan and every decision record) · #7766 (this Commit 0)
- **Stage 5:** designs #7750 · #7752 · #7754 · #7756 · #7758 · #7760 · #7762 · #7764; reviews #7859 · #7860 · #7861 · #7862 · #7863 · #7864 · #7865 · #7866
- **Related:** #6198 (co-discharge candidate) · #5633 (notice posted) · #5185 (ARCHIVE destination) · #4449 (AC2 residual, recorded at Stage 13) · #7638 (`egress-hook-batch`, merged) · #7839 · #7901 · #7895 · #7919 (in flight at Commit 0)
