<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
---
version: stage-document-model-decision
date: 2026-11-05
type: plan
status: ACTIVE
issues: ["#8153", "#8154", "#8155", "#8156", "#8157"]
pr: "#8814"
links:
  note: release/releases/notes/_unversioned/stage-document-model-decision_RELEASE_NOTES.md
  log_anchor: "#stage-document-model-decision"
reversibility-tier: CHEAP
themes: ["cluster:documentation"]
audit_class: true
---

<!--
The `domain_practice` provenance label has ONE home in this file: the
`### Release Class declaration` H3 below. It is deliberately not duplicated into
this frontmatter block, because a second copy drifts the moment one of the two is
edited, and the provenance-survival check reports a multi-label plan as an
ambiguity. The `audit_class` declaration lives in the frontmatter only.
-->

# Release Plan — stage-document-model-decision

> **Status:** Stage 12 Execute, authorized by the operator. Stage 9 rendered GO WITH CONDITIONS (PA-016), and the founding ADR is `Accepted`, ratified with amendments (PA-017). The merge waits on condition C1, every required check green on the final head (release branch `release/stage-document-model-decision`).
> **Identity: VERSION-LESS.** The release identity is the capability slug `stage-document-model-decision`. No version key is claimed at any stage, no release-version stamp token is authored, and the Stage-12 rename never fires. The plan moves to `plans/_unversioned/` at Stage 13 close.
> **Topology:** D-C SINGLE — one release branch, one pull request, one merge.
> **Release Class:** `novel` · **Milestone:** `stage-document-model-decision`.
> **Source of record:** this file. The Stage-4 planning sub-task comment (comment 6664007762 on #8751) was the working reference until this commit landed. It is transcribed here with the Commit-0 Survival Set, the operator's Stage-4 gate decisions, the Collective Review scope-lock, and the D-Version re-render applied. Every departure from the Stage-4 comment's text is a row of § Deviation Log.

## Header

| Field | Value |
|-------|-------|
| **Version** | (none) — version-less |
| **Bump Class** | N/A — version-less release; no number binds at Stage 12 (D-Version re-rendered version-less by the operator on 2026-11-05 after the PA-007 scope change) |
| **Date Created** | 2026-11-05 (Thursday) |
| **Release Manager** | Agent-assisted (release hub + stage spokes) |
| **Status** | Executing — Stage 12 Execute, authorized; GO WITH CONDITIONS (PA-016), ADR ratified (PA-017); the merge waits on condition C1 |
| **Branch** | `release/stage-document-model-decision` |
| **PR** | #8814, the draft release PR opened at Stage 6 Phase C2; the frontmatter `pr:` field was populated by the Wave-2 commit |
| **Milestone** | stage-document-model-decision |

### Release Class declaration

**Release Class: `novel`.** Posture carried through the pipeline: engagement density Standard; Stage 9 review depth **Deep**; Stage 5 activation bias **ALL**; Stage 13 outcome window **30-day**.

Trigger evidence (re-rendered at Collective Review after PA-007): novel trigger (a) fires, because the release now ships one new ADR file; trigger (b) fires, because the deliverable is a D-class decision (the ratified design plus the Stage-4 D-decisions). Routine (a) fails: the cards are P2, not P3/P4. Cross-cutting (a)–(c) do not fire: 0 stage files and 0 rule-defining surfaces change, and an ADR is neither; the 4 compositional edges all feed one card.

**Domain-practice provenance.** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-05, domain: governance }`

The label takes the pipeline-internal exemption form: the File Change Matrix holds this plan and one platform ADR, both internal platform artifacts, so no external best-practice sourcing step is triggered. #8155 already carried the external sourcing for the vocabulary question (16 sources). The domain classification makes the close class resolve DEPLOYABLE through rung 1. `task-artifact` was weighed and is unreachable today: such a release halts at Stage 12 (G-EX4 and G-EX5 are unconditioned), and the Artifact-Acceptance Record needs `git show origin/main:<path>` to succeed, which a git-ignored record cannot satisfy.

**Audit class.** Declared in this file's frontmatter (the `audit_class` key). Release-diff folder detection reads 0 by construction for git-ignored records, so without the declaration the Stage-13 follow-up sweep would never read the records' downstream items.

### Baseline pin

- **Stage-4 planning baseline:** `origin/main` @ `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` (2026-11-05, Thursday). Every Stage-4 probe below was run against that commit.
- **Commit-0 base:** `origin/main` @ `b1042eec`, re-fetched at Engineering Commit 0 — 0 commits since the Stage-4 baseline.
- **W1 discovery base (read only):** `cebcf6c251c8d381842750b0d10f173f965e34a5`, the commit the W1 record and the platform-release pages are pinned to.
- **`${AUDIT_DATE_UTC}` = `2026-11-05`.** Resolved once at the hub at Stage-6 start (Collective Review recorded determination) and recorded here at Commit 0. Every Stage-6 session reads this value from this file; none re-runs `date`.

### Recorded decisions

| ID | Gate | Decision | Reversibility |
|---|---|---|---|
| PA-001 | Stage 4 plan approval | Plan and the Release Outcome Statement draft with its `**Limb owners:**` line, approved | MODERATE |
| PA-002 | D-8157-Scope | (B): carry the 2026-10-24 widening as a binding input; #8157's Stage-5 spec authors one design criterion per widened element; its body and acceptance criteria are decided at ratification | CHEAP |
| PA-003 | D-VerifiedCards | (A): #8154 and #8155 stay in this release, verify-only | CHEAP |
| PA-004 | D-Concurrency Posture | P1: parallel compute, one commit lane; the #8153 Stage-6 session is the only Commit-0 writer | CHEAP |
| PA-005 | D-ReleaseClass | `novel`, re-confirmed | CHEAP |
| PA-006 | Collective Review scope-lock | Approved with amendments (1)–(5), applied as Tier 1 [ADJUST] on the Stage 6–8 sub-tasks (DEV-11) | MODERATE |
| PA-007 | D-DurableHome | (B) + (C): this release ships the founding ADR, authored `Proposed` at Stage 6 and `Accepted` at ratification — a Tier 2 [SCOPE CHANGE]; the current-state inventories are routed to the #8115 catalog pages through a coordination edge (DEV-12) | MODERATE |
| PA-008 | D-OwnedFindings | (a): the findings the process-baseline gate assigned to #8153 (7), #8154 (15) and #8155 (6) are carried as tagged release follow-ups; the Stage-9 ledger reads them and Stage 13 files them (DEV-15) | CHEAP |
| PA-009 | D-VerifyOnlyRigor | (a): Stage 7 is restored for #8154 and #8155 (#8785 and #8786 reopen); Stage 6 derives its answers fresh before comparing them, as verify-and-refresh (DEV-16) | CHEAP |
| PA-010 | D-8157-BuildPrinciples | (b): #8157 gains one graded design criterion for the operator's four § 2 constraints (no bloat; reviewed over releases; repo versus local-folder best practice; repeatable for adopters) (DEV-17) | CHEAP |
| D-Version | Re-render after PA-007 | Version-less, re-confirmed by the operator ("Stay version-less (Recommended)") | CHEAP / HIGH (reversible up to Stage 12) |
| PA-011 | Stage 9 pre-GO, D-PreGateADRFix | (A): one Tier 1 wording commit on the founding ADR while it is `Proposed` (DEV-26) | CHEAP |
| PA-012 | Stage 9 pre-GO, D-Stage8Acceptance | Accepted as listed: #8153, #8155 and #8156 ACCEPT; #8154 CONDITIONAL, AC-3's three `not stated` lifecycle rows accepted as-is; #8157 ACCEPT once PA-011 lands (DEV-27) | CHEAP |
| PA-013 | Stage 9 pre-GO, D-8156-QA | (A) + (a): the Scrum/Kanban-design join rule stated in the #8156 record, the ADR's figure staying 19; the record's sunset extended with a reason and the record named as slice S3's input (DEV-28) | CHEAP |
| PA-014 | Stage 9 pre-GO, D-DeliveryCutDeps | Slice S7 split to a later milestone, so milestone 2 is back to two external dependencies (DEV-29) | CHEAP |
| PA-015 | Stage 9 pre-GO, D-OwnedFindingsFiling | The 28 owned findings stay unfiled, owned by #8150's delivery cut, with the 8 bug-tag candidates listed in the Stage-9 ledger (DEV-30) | CHEAP |
| PA-016 | Stage 9 GO / NO-GO | **GO WITH CONDITIONS.** C1: every required check passes on the final head before the merge. C2: the ratification head re-read. C3: the draft-to-ready transition, read back. C4: the R7/R9 re-dispositions and the CIAC-2..CIAC-6 grade lines recorded (DEV-31) | EXPENSIVE |
| PA-017 | Stage 9, D-Ratify-8157 | **Ratify with amendments:** the founding ADR goes `Proposed` → `Accepted` with RQ-2, RQ-3, RQ-4 and RQ-5 as proposed, the risk-class home re-check recorded, and the node-delta lint adopted on its supporting-grade premise (DEV-32) | EXPENSIVE |
| PA-018 | Stage 9, D-8150-Body | #8150's body changes per RQ-1: the three Out bullets stay, and "system documentation" repoints from #8110 to #8111 and #8114 (DEV-33) | CHEAP |
| D-Execute | Stage 12 Execute | **Authorized:** the pre-merge plan update, then the merge only once every required check is green (C1), ADR number binding, B3 N/A (version-less), B4, and the B5 RELEASE_LOG chore PR (DEV-34) | IRREVERSIBLE |

Every choice equals the hub's recommendation, so there is no recommendation-versus-choice delta. PA-011 to PA-015 were rendered together on 2026-11-05 ("Approve all five"; Decision Recorded, comment 6670710105 on #8794). PA-016 to PA-018 were rendered together the same day ("Approve all three"; comment 6671846290 on #8794). D-Execute was rendered the same day ("Authorize Execute"; comment 6672132704 on #8797). Recorded determinations, not gates: D-C SINGLE; Stage 5 ACTIVATE release-wide under the all-or-nothing rule; one PR (now carrying this plan and the founding ADR, DEV-12).

## Phase A0 — Triage→Design re-review and currency gates (transcribed from the Stage-4 output)

**G-PL5 cache-read: HIT.** Rows adopted from the Mode R briefing on the planning sub-task (comment 6663347621 on #8751, author association `OWNER`, the only marker-bearing comment, `part: 1/1`), `emitted_at: 2026-11-05T16:22:56Z`. `rows_source: mode-r-cache`.

| Operand | Recorded (briefing) | Recomputed (2026-11-05T16:33:57Z, `set -o pipefail`, every read exit 0) | Equal |
|---|---|---|---|
| L1+L2 `card_set_fingerprint` | `16b073151e9ad2f5ad6ea103b58b9c10e61b2c58118833ff7f0ddfe9b72025fe` | `16b073151e9ad2f5ad6ea103b58b9c10e61b2c58118833ff7f0ddfe9b72025fe` (5 non-`sub-task` members; 6 returned against `--limit 500`, so no truncation) | yes |
| L3a `milestone_updated_at` | `2026-11-05T16:29:18Z` | `2026-11-05T16:29:18Z` | yes |
| L3b `milestone_description_sha256` | `1e28087be11041aff378055e2b86a97612b81820f67c6b4903759c2a0e1e1c66` | `1e28087be11041aff378055e2b86a97612b81820f67c6b4903759c2a0e1e1c66` | yes |
| L4 `main_head_sha` | `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` | `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` | yes |
| L5 age | `emitted_at` 16:22:56Z | 11 min old, inside the 7-day window | yes |

MISS conditions checked and absent: no non-`sub-task` member titled `^Stage [0-9]` (the only `Stage …` title, #8751, carries the label); recomputed card set non-empty. Column completeness (PV-1, PV-2): a parser over the five adopted tables read **34 rows** (6 / 7 / 6 / 5 / 10), all in the six-column form, **0** empty D1/D2/D3 cells, **0** C3. Sensitivity arm: the same parser over a copy with one D1 cell blanked reported exactly that cell. No adopted row is C3 or PT-2, so the § 3.1 freshness re-run has no row to stamp.

**Header (A0-authored, all five cards):** release_milestone `stage-document-model-decision` (ms#432, version-less) · stage 4 · spoke_author Stage-4 Release Planning spoke (`spoke:#8751`) · re_review_date 2026-11-05 · triage_decision_date 2026-10-04 · issue_body_revision and effort_tier per card: #8153 `2026-10-25T05:52:04Z` standard · #8154 `2026-10-25T05:52:02Z` standard · #8155 `2026-10-25T05:52:05Z` standard · #8156 `2026-10-04T17:03:07Z` standard · #8157 `2026-10-04T17:03:09Z` complex.

### Adopted per-requirement tables (verbatim from the briefing)

**#8153**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 — all 13 stages covered, each with a row or a reason | The coverage claim names its denominator, 13, as `review-discipline-principles.md` § 8.1 PV-1 requires. | `release-process.md` still defines Stages 1–13 at `b1042eec` (`:239`–`:609`). The W1 record already holds 112 (stage, document) rows across all 13, at baseline `cebcf6c2` [SOURCE: W1 files table]. | On 2026-10-24 the operator directed that #8153 "verify against those views rather than re-inventory" [SOURCE: #8150 comment 6390883242 § 3]. The P2 release-universe pages met their refuter gate on 2026-10-25. | C2 | Re-scope the method: verify W1 and the P2 views against the stage specs at the run's `main` head, and record only what they omit. 40 commits have touched `release/references/pipeline/` since `4babbba9`, so refresh the W1 baseline rather than reuse it as it stands. |
| AC2 — every row names home, lifecycle class in practice, reader or "none" | Rule 3: every row carries all three, with no empty cell. | W1's row grain already encodes `home_class`, `lifecycle_class_in_practice` and `readers` (same-change and future-change) [SOURCE: W1 § 1.2]. | Read the declared TSV columns, not prose: a structure-shaped probe over the whole population, with a control arm [CONTEXT]. | C1 | — |
| AC3 — release sample stated with size and selection rule | PV-1: the denominator is stated. | W1 samples three milestones and states its reads [SOURCE: W1 § 1.1, § 1.3]. The 2026-10-25 observation records a release that ran with no sub-tasks (merged by #8453), whose stage reports were never posted [SOURCE: #8153 comment 6394105818]. | The card's own risk says a small sample can miss a compressed stage. | C2 | In the sample note, record that release shape (scaffolded or not) changes what persists, and cite the #8453 case. |
| AC4 — each Stage 5 output classified durable or comment-only | `decision-discipline.md` § 2.1.1: reconcile the snapshot against live state. | The Stage 5 → 6 boundary in `stage-io-contracts.md` is unchanged since 2026-10-04; its only change is a Stage 12 row [SOURCE: `git diff 4babbba9 origin/main`]. ADR-224 decision 6 gives catalog pages a lifecycle `status` field, which is a new candidate durable home for a design record. | #8495 (shipped in ms#434) added a planning read of current-state process pages at Stages 2 and 5 [SOURCE: commit `627cf5e2`]. | C2 | Classify each Stage 5 output against the catalog page as a candidate home too, not only against comments and tracked files. |
| AC5 — summary posted on the card, naming where the record is held | PV-0: name the record's location. | The summary was held until Phase 3 [SOURCE: process-baseline `RESUME.md:439`]. Phase 3 has now completed. | G-2 item 5 posted the #8154 and #8155 summaries only after an egress check and the operator's second yes [SOURCE: `planning/G-2-review.md:34`]. | C2 | Draft under the analysis-workspace egress rule: no instance detail on a public card. |
| risk-1 — Documentation Impact declaration | PV: a declaration that cannot be evaluated must not read as clean. | The parser grades it `ungradable` because of the trailing period after `)` (fixture DI-4, `:1125`). It is advisory for bundled cards. | ms#411's Mode R found the same G3-20 shape. | C2 | Remove the trailing period. |

**§ 11:** PV-A (the Stage 5 → 6 contract row that delivers design specs only as a review comment; the "Verify" stage defect in `operational-artifacts.md`). **AL-FIT:** this is an investigation with no remediation band. The seam searched is the stage specs and `stage-io-contracts.md`.

**#8154**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 — every artifact in both tables appears, or is dropped with a reason | PV-1: the denominator is stated (50 names). | The posted summary reports 50 names: 46 mapped and 4 dropped with a reason [SOURCE: comment 6368771590]. The input files have 0 commits since 2026-10-04 [SOURCE: `git log`]. | A refuter re-derived 6 rows independently, and all 6 held [SOURCE: same comment]. | C1 | — |
| AC2 — every row names its template family, or "none" | Rule 3. | 90 rows, each naming a family or "none" [SOURCE: same comment]. `template-taxonomy.md` has had 0 commits since. | Same refuter. | C1 | — |
| AC3 — every row names lifecycle class, home class and readers | Rule 3. | Met, per the summary. `operations/templates/` has one template edited and none added or removed [SOURCE: `git diff --name-status`]. | Same refuter. | C1 | — |
| AC4 — the disagreements are listed | Root-cause format (Rule 4) applies to each disagreement. | 46 disagreement rows [SOURCE: same comment; `table-disagreements.tsv`]. | The 2026-10-25 observations add four more [SOURCE: comment 6394105544]. | C1 | — |
| AC5 — summary posted on the card | PV-0. | Posted 2026-10-23, naming `<OPERATOR_INSTANCE_ANALYSIS_PATH>/process-baseline-2026-10-22/discovery/records/w2-project-delivery/`. | — the G-2 egress check was applied before posting [SOURCE: G-2 item 5]. | C1 | — |
| proposed-change-1 — how the card is executed | `reversibility-protocol.md` § The Four Tiers: verify-and-close is CHEAP. | Every acceptance criterion is already evidenced as met, on the card itself. | When every criterion passes at the first check, verify and close rather than re-author [CONTEXT]. | C2 | Stage 6 verifies the record against each criterion and closes the card. Fold the 2026-10-25 observations into the record, or note them there. Re-size. |
| risk-1 — Documentation Impact declaration | As #8153. | `ungradable` (trailing period). | As #8153. | C2 | Remove the trailing period. |

**§ 11:** PV-A (the two `operational-artifacts.md` tables are keyed to different stage and phase lists, `:97-120`). **AL-FIT** (investigation; the seam searched is `operational-artifacts.md` and `template-taxonomy.md`).

**#8155**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 — the crosswalk includes 13 / 11 / 6 / lifecycle states | PV-1: each model is a named denominator. | The crosswalk has 18 aligned rows covering all four models [SOURCE: comment 6368771981]. `release-process.md` still defines 13 stages despite 11 commits. | A refuter re-derived 3 rows independently, and all held. | C1 | — |
| AC2 — at least two external sources, each with its contribution | Evidence labels: the unreachable ISO rows are marked unverified, which is a declared coverage boundary (§ 8.1). | 16 sources, including PMBOK 7, the Scrum Guide, SAFe, PRINCE2 and ITIL 4 [SOURCE: same comment]. | — the refuter sample covered rows, not sources. | C1 | — |
| AC3 — each candidate states its tradeoffs and the surfaces it renames | Reversibility: renaming cost is the irreversibility signal. | C1: no renames. C2: five classes. C3: about 18 files as a layer, or about 600 as a replacement [SOURCE: same comment]. | Reuse first: extend what exists before adding anything new [CONTEXT]. | C1 | — |
| AC4 — summary posted | PV-0. | Posted 2026-10-23, naming `…/w3-crosswalk/`. | G-2 egress check. | C1 | — |
| proposed-change-1 — execution, and a premise note | `decision-discipline.md` § 2.1.1. | The card says "#6433 names the two process universes". The catalog G-1 approved, and ADR-224 adopted, has **three** universes: release, project delivery and the engineering harness [SOURCE: `w5-synthesis/universes.tsv`]. The 2026-10-25 observations add two vocabulary findings [SOURCE: comment 6394105970]. | Same as #8154 (pre-rendered → verify). | C2 | Verify, then close. Carry the three-universe fact to #8157. The card's criteria are unaffected. |
| risk-1 — Documentation Impact declaration | As #8153. | `ungradable`. | As #8153. | C2 | Remove the trailing period. |

**§ 11:** PV-A (the "Verify" stage the pipeline does not define, in `operational-artifacts.md`). **AL-FIT** (investigation; the seams searched are `release-process.md`, the five-function spine and `lifecycle-tailoring.md`).

**#8156**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 — a row for each of the 8 `delivery_approach` values | PV-1: the denominator is 8. | The enum still has 8 values at `b1042eec` (`project-schema.md:66`, V2 `:449`). The methodology spec changed by 2 lines since 2026-10-04 [SOURCE: `git diff --stat`]. | The process-baseline plan lists #8156 as "Partial; confirm in Planning" [SOURCE: `SUMMARY.md:681`], and no record answers it: `w4` covers controls [SOURCE: records listing]. | C1 | — |
| AC2 — cadence and lifecycle class per document group, or how configuration supplies them | Reversibility: no invented default, so the safe choice is "the configuration supplies it". | The card already routes Hybrid and Custom to the resolved configuration. | Methodology is operator-local configuration, and the public corpus stays methodology-neutral [CONTEXT]. | C1 | — |
| AC3 — each existing methodology rail assessed | Rule 3: every rail gets a finding. | The card lists four rails but not the **per-space resolution**: Step 0, `operational_methodology` / `release_methodology` (`methodology-parameterization-v1.md:226-232`), which was already present at `4babbba9` (7 matches). The model's two projections line up with those two spaces. `core/packs/` holds only `scrum`, `kanban` and `_common` [SOURCE: `git ls-tree`]. | — no retrospective covers this rail. | C2 | Add Step 0 per-space resolution as a fifth rail. State which archetypes have no pack. |
| AC4 — summary posted | PV-0. | Not yet run. | The public-card egress check that preceded the #8154 and #8155 summaries applies here too [SOURCE: `planning/G-2-review.md:34`]. | C1 | — |
| risk-1 — Documentation Impact declaration | As #8153. | `ungradable`. | As #8153. | C2 | Remove the trailing period. |

**§ 11:** **PV-D** (strict: the evidence cites only the platform's own rails, and no instance where the problem bit; logged, not escalated). **AL-FIT:** the nearest seam is methodology-parameterization Step 0 and the tracker-schemas Methodology Variation. The card proposes hook options at the extend-seam band, which matches.

**#8157**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1 — each owed axis gets a coverage state and a concrete element | Rule 3 per axis. | ADR-224 (Accepted) now fixes, for catalog pages, the home (a sibling under `core/`, decision 4), the lifecycle (DRAFT / ACTIVE / SUPERSEDED / DEPRECATED, decision 6) and the generation boundary (L0–L2 written, L3 seeded, L4 generated, decision 7). The card's behaviour-over-time axis names only the three `operational-artifacts.md` classes. | The 2026-10-24 hypothesis: "No new artifact type or status". It leaves one seam open: who writes L0–L3 at Stage 6 [SOURCE: #8150 comment 6390883242 § 4]. | C2 | Reconcile living / point-in-time / baselined with ADR-224's four statuses, and answer the L0–L3 writer seam. |
| AC2 — one vocabulary, mapped to the 13 stages and the project phases | PV-1: two named projections. | #8155 delivered three candidates with their costs. The catalog has three universes [SOURCE: `universes.tsv`]. | — no prior cycle. | C2 | State whether the engineering-harness universe takes a projection, or why it does not. |
| AC3 — the methodology hook, shown for at least two methodologies | Reversibility: the hook is config-selected. | It depends on #8156's finding about the per-space rail. | Methodology is operator-local configuration; the public corpus stays methodology-neutral [CONTEXT]. | C1 | — |
| AC4 — the seams with #8117, #8114, #8005 and project-data-architecture | `decision-discipline.md` § 2.1.1. | #8117 is **closed and decided** (ADR-224; ms#434 closed 2026-10-25). #8494 and #8495 shipped. #8016, the risk-class homes ADR, is bundled in ms#428, which is holding at Stage 4. | The card's own rule: a seam with an undecided ADR is recorded as provisional. | C2 | The #8117 seam is final, with ADR-224 as its input. Add #8016/ms#428 as the remaining provisional seam. Cite #8494 and #8495 as foundation already built. |
| AC5 — the delivery cut: slices, work natures, edges, milestones | `decision-discipline.md` (decision-class output). | `bundle-composition-doctrine.md` has 4 commits since 2026-10-04, and ms#419 `bundle-doctrine-runs-from-evidence` is open [SOURCE]. | Composing a release is a judgment of capability coherence and dependency edges, not bin-packing by size [CONTEXT]. | C1 | — read the doctrine at run time. |
| AC6 — the operator's ratification recorded on the card | `reversibility-protocol.md` EXPENSIVE: an explicit sign-off gate. | The ratification is the operator's gate, and Mode O stops there. | The 2026-10-24 comment makes the ratification also decide whether #8150's body and Out list change [SOURCE: comment 6390883242, Scope note]. | C1 | — |
| proposed-change-1 — the 2026-10-24 scope widening | `decision-discipline.md` § 2.1.1: it is a recorded operator decision, not recalled framing, so it stands. | The design now covers the loop: read current state, design, build and document in one release, validate, feed back, review over time. The comment carries a leading hypothesis (a node-delta block at Stage 5, DRAFT edits at scope lock, a Stage 6 flip to ACTIVE, four checks in code). It defers any body change to ratification [SOURCE: comment 6390883242 §§ 1, 4]. None of the six criteria names the loop. | Distil the intent: a proposed remediation is directional, and the hypothesis is "an input, not a decision" [CONTEXT]. | C2 | **Stage-4 D-decision:** amend the criteria now, or carry the widening as a binding input and decide the body at ratification. Re-check size:L/8. |
| risk-1 — vocabulary collision with #8117 | Reversibility. | Its premise has changed: #8117 has decided, so the risk is now an alignment check against a ratified vocabulary. | The process-baseline D-E question, whether to merge or sequence #8117 and #8157, resolved as a sequence, with #8117 first [SOURCE: `SUMMARY.md:705`]. | C2 | Rewrite the risk as alignment with ADR-224. |
| risk-2 — coordination with ms#437 | — the coordination edge is recorded in the Parallelization Map. | ms#437 publishes catalog pages, and #8157 designs how pages become ACTIVE. | DEC-26 places ms#437 last. | C2 | Note the edge in the refreshed Parallelization Map. |
| risk-3 — Documentation Impact declaration | As #8153. | `ungradable`. | As #8153. | C2 | Remove the trailing period. |

**§ 11:** **PV-D** (strict: the body cites ADR-211 and #8150's open decisions; the parent epic carries the PV-A instances; logged). **AL-FIT:** the nearest seams are `operational-artifacts.md` § Artifact Lifecycle Patterns and ADR-224's catalog. Extending or splitting that standard is the extend-seam band, which matches.

### Sibling Phase A0 gates (all ran; a cache HIT skips none of them)

- **Ticket-architecture reconciliation.** #8157 cites ADR-211 (Accepted 2026-10-02, 0 commits since the card was filed) and named #8117 as "deciding". #8117 is closed as completed and ADR-224 is Accepted (2026-10-23), so the card body was stale on that seam. Its premise still holds; this was a C2 currency delta, corrected by the hub after plan approval (DEV-3).
- **A0.5 / G-PL1 (reference currency): PASS after reconciliation.** 17 of 17 concrete paths the five cards cite exist at `origin/main` (`git cat-file -e`); sensitivity arm, an invented stage-14 path, returned 128. The two `<OPERATOR_INSTANCE_ANALYSIS_PATH>` paths are tokens, not paths. Inputs changed since card filing (`4babbba9..b1042eec`): `stage-io-contracts.md` 1 commit (2 lines), `release-process.md` 11 commits, 43 changed lines (still 13 `### Stage N` headings), `project-schema.md` 1 commit, 10 changed lines (enum still 8 values), `bundle-composition-doctrine.md` 4 commits (the size-class rubric), `release/references/pipeline/` 40 commits; `operational-artifacts.md`, `template-taxonomy.md` and `operational-artifact-inventory.md` 0 commits. CURRENCY-MISMATCH on #8157 only: "#8117 is deciding" → decided (ADR-224). Every AC stays evaluable as written.
- **A0.6 / G-PL2 (crisping): PASS.** G1-02, G1-04 and G1-05 hold on all five current bodies (`bundle-issues-parser.py`: `parse_status: clean` ×5; AC counts 5 / 5 / 4 / 4 / 6). #8153's method changed by operator direction on 2026-10-24, and the plan carries it (Implementation Sequence), so no body crisping is owed.
- **A0.7 / G-PL3 (placement): FIRES, no re-home.** `git log 4babbba9..origin/main --name-status --find-renames` (no release branch existed, so the card-filing base stood in for `<release-base>`): 1,157 rows, 27 R, of which 11 cross a directory and all 11 hit the reference surface. All 11 are the ADR-092 claim-time folds `plans/<slug>_RELEASE_PLAN.md → plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`, the per-release claim step and not a reorg of the pre-claim home. 0 D rows on the surface. This plan is placed at the pre-claim top level `release/releases/plans/stage-document-model-decision_RELEASE_PLAN.md` per current-main topology (plans/README rule 0): the in-flight home is unchanged, and a version-less plan moves to `_unversioned/` only after it ships (rule 2).
- **A0.8 / G-PL4 (empirical re-run), pinned at `b1042eec`.** #8154 is drift/reconciliation-class by predicate (i) (its body says "reconciles"), so it is mandatory and no-skip.

| Card | Re-run check | Observed | Verdict |
|---|---|---|---|
| #8153 | Stage-Artifact Mapping rows in `operational-artifacts.md`; `### Stage N` headings in `release-process.md` | 11 rows incl. **Verify**, no Bundle / Dry Run / Snapshot; 13 headings | admit-still-valid |
| #8154 (mandatory) | the two tables' row counts; inventory § 5 class counts | 11 stage rows vs 6 phase rows; 5 + 21 + 6 + 10 + 6 = 48 | admit-still-valid |
| #8155 | the 13 / 11 / 6 models; `lifecycle-tailoring.md` states | unchanged; ACTIVE / CLOSING / CLOSED | admit-still-valid |
| #8156 | `delivery_approach` enum; a document set in `core/packs/` | 8 values; packs = `_common`, `kanban`, `scrum`, 0 document-set declarations (control: `kind` returns 47 in the scrum pack) | admit-still-valid |
| #8157 | no runnable check (a design card) | — | documented pass-through to the per-spoke PT-1/PT-2 check |

No card's cached rows are superseded. The four admit-still-valid verdicts corroborate the HIT.

- **Parallelization-Map currency: stale → Tier 1 [ADJUST], applied by the hub (DEV-4).** The milestone's map was dated 2026-10-04 and predated two A7 events: the 2026-10-24 scope enrichment and the 2026-11-05 Mode R recompute. Re-run: 55 open milestones; 1 remote `release/*` head (`guards-judge-every-spelling-alike`, draft PR #8651). Its 24-path edit set intersects this release's FCM, its read inputs and the shipped-plan samples at 0 / 0 / 0 (control arm: the same intersection against its own plan path returns 1). Both 2026-10-04 edges are discharged; ms#341 and ms#334 closed. Tier-S: the Stage-4 FCM declared no mover, so its structural surface was empty. PA-007's ADR row is an `add` and declares no mover either (DEV-12).
- **Currency-decision confidence gate.** Refresh outcome: **amend** (milestone description: map, Actors line, size table, Limb owners). Signal: corroborated and grounded. Three independent reads agree (the G-PL5 HIT, G-PL4 ×4 admit-still-valid, and the map re-derivation), and the weakest label under the outcome is `[SOURCE]`.

## Summary (30 seconds)

- **Tracked files: two** (one before PA-007). This plan, at Engineering Commit 0, and the founding ADR, authored `Proposed` by the #8157 Stage-6 session in Wave 2 and moved to `Accepted` at ratification (PA-007 (B), DEV-12). No card changes any other tracked file. Delivery is **one branch, one PR, one merge**, then the Stage-12 B5 chore PR and the Stage-13 version-less Phase-B chore PR, with no GitHub Release. Precedent for the plan-carrying PR: the version-less release `memory-to-corpus-codification` shipped as PR #604.
- **Execution per card.** #8154 and #8155 are verify-and-refresh: their records exist, nothing is re-authored, and figures are re-measured at head (PA-009). #8153 verifies the W1 record and the P2 views at the run's `main` head, records only what they omit, and adds a field-check arm (PA-006 (1)). #8156 is full discovery plus the per-space rail. #8157 designs after all four, with refreshed inputs, and authors the founding ADR.
- **Re-sized: 24 raw / 28 effective → 20 raw / 23 effective, inside the 15–25 band.** Every size here is a judgment, because the doctrine gives zero-surface work no row. #8154 and #8155 M → S; #8153, #8156 and #8157 unchanged. The 2026-10-04 over-band disposition retires.
- **Stage 5 ACTIVATES release-wide.** T3 and T4 fire on #8157, and the all-or-nothing rule applies. For #8154 and #8155, Stage 5 was a one-paragraph verification-only disposition.
- **Ratification** is a named operator D-gate at **Stage 9 Plan Review**, after Stage 7 and Stage 8 have verified the design record. A redirect iterates #8157 alone to Stage 6.
- **Risks:** records written into a worktree's own `analysis/` copy are lost when the worktree is removed; a release-version stamp token in a version-less plan; #8157's widened scope; public egress of instance detail; the founding ADR's number slot (R9).

## Scope

### Issues Included

| # | Issue | Title | Priority | Size | Labels (cluster) |
|---|-------|-------|----------|------|--------|
| 1 | #8153 | Inventory what each release-pipeline stage writes today, where it persists, and which later stage or change reads it | P2 | M (4) | cluster: documentation |
| 2 | #8154 | Inventory what project delivery produces in each phase, which template backs it, and who reads it next | P2 | S (2) | cluster: documentation |
| 3 | #8155 | Crosswalk the stage and phase models in the platform and in established practice, and propose candidate shared stage vocabularies | P2 | S (2) | cluster: documentation |
| 4 | #8156 | Map how each delivery methodology changes when documents are written and how long they stay current | P2 | M (4) | cluster: documentation |
| 5 | #8157 | Design the stage-to-document model and its architecture, and bring it to ratification | P2 | L (8) | cluster: documentation |

All five are sub-issues of #8150, which has no parent.

### Dependency Graph

Native edges (GraphQL `blockedBy`/`blocking`, 2026-11-05): **4**, all inside the milestone. #8157 has 4 blockers (#8153, #8154, #8155, #8156); each discovery card blocks 1 and has 0 blockers. Cross-milestone edges: 0. Cycle check: none; a 2-level DAG.

```
#8153 ─┐
#8154 ─┤
#8155 ─┼──▶ #8157 ──▶ [operator ratification gate, Stage 9]
#8156 ─┘
```

Coordination edges, not build edges: #8016 in `placement-rules-and-adr` (ms#428, provisional home-class seam); `engineering-harness-pages-published` (ms#437, catalog pages, outbound); #6433 (open, the universes naming); ADR-224 (#8117, decided, input); the #8115 process-catalog pages, which receive the current-state inventories as input (PA-007 (C)). Foundation built: #8494 and #8495, both complete and delivered by ms#434.

### Exclusions

N/A — enumerated over the classes reasoned over: cards removed at the Stage-4 gate (D-VerifiedCards rendered (A), so none), cards deferred to another milestone (none), and cards split or merged (none, § Merge / split). None present in this release.

## Implementation Sequence

**Wave 1 (parallel compute): #8153, #8154, #8155, #8156.** **Wave 2: #8157**, once all four records exist and are verified. **Gate: ratification at Stage 9.**

| # | Card | Execution | Record home (all under `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` = the in-repo `analysis/` workspace) |
|---|---|---|---|
| 1 | #8153 | **Re-scoped verification.** Refresh the W1 record (112 rows, 13 stages, baseline `cebcf6c2`) and the P2 release-universe views against the stage specs at the run's `main` head, and record only the omissions, keyed by (stage, document) against a sha256-pinned base. Add the field-check arm in its minimum form: seed the process-baseline refuter's contested rows, compare each boundary-contract Delivery cell with W1's home and readers with the P2 data-flow view's "Consumed by" column, and label every base cell not verified (graded G-C). Add the table of the 7 process-baseline findings this card owns, each tagged as a release follow-up. Classify each Stage 5 output against the catalog page (ADR-224 decision 6) as a third candidate home. Add the release-shape note to the sample (a release run without sub-tasks persists differently; cite #8453). This session writes the parent folder's `SUMMARY.md` once. | Base, read only: `process-baseline-2026-10-22/discovery/records/w1-release-stages/`. Delta: `delivery-doc-practice-discovery-2026-11-05/w1-verification/`, plus the parent `delivery-doc-practice-discovery-2026-11-05/SUMMARY.md` |
| 2 | #8154 | **Verify and refresh.** Read the posted record against AC-1..AC-5, re-measuring its figures at head, check for collisions against `lifecycle-states-canonical.md` § 5, and add the table of the process-baseline findings this card owns. Note the four 2026-10-25 observations in two new files beside the record, with the base byte-identical (#8154 D-1: note, do not fold). Nothing is re-authored. | `process-baseline-2026-10-22/discovery/records/w2-project-delivery/` (existing; 90 rows, 46 disagreements), plus the two sidecar files |
| 3 | #8155 | **Verify and refresh**, as #8154, in the same verification-file form. Carry the three-universe fact (release, project delivery, engineering harness) to #8157. | `process-baseline-2026-10-22/discovery/records/w3-crosswalk/` (existing; 18 rows) |
| 4 | #8156 | **Full discovery as written**, plus a fifth rail: the per-space resolution (Step 0, `operational_methodology` / `release_methodology`). State which archetypes have no pack (only `scrum` and `kanban` ship). Fill cells from sources only, with derived values in their own columns; bind lifecycle class per member with its source entity; add an empty-group code; read AC-2 strictly (a `not-stated` cell needs a named supply path). Write only inside `methodology-variation/`; never the parent `SUMMARY.md`. | `delivery-doc-practice-discovery-2026-11-05/methodology-variation/` |
| 5 | #8157 | **Design and take it to ratification**, on the input register below, in the registered-report form (questions and eliminators frozen, a logged door for new candidates, one reduction rule per DR), with one graded design criterion for the operator's four § 2 constraints. **Author the founding ADR** at `core/ADRs/`, status `Proposed`, holding the design and the gap map with the current-state evidence summarized in its Context; it moves to `Accepted` at ratification. | `delivery-doc-practice-design-2026-11-05/`; the ADR is tracked (§ File Change Matrix) |

**Record-home rule.** Every record is written at the token-resolved path, the primary in-repo `analysis/` workspace, which `core/standards/analysis-workspace-standard.md` opens to any session shape. It is never written into a spoke worktree's own `analysis/` copy, which `git worktree remove` deletes, and never under the legacy operator-instance tree. Every record's frontmatter sets `sunset` with both limbs: created + 90 days, or the card's close + 30 days, whichever comes first.

**#8157 input register (binding).** It reads:
- the four records above, including #8156's `hook-options.tsv` and #8154's addendum;
- ADR-224 as the final #8117 seam: home (decision 4), the four statuses (decision 6), and the L0–L2 / L3 / L4 generation boundary (decision 7);
- #8494 and #8495 as built foundation;
- the 2026-10-24 widening and leading hypothesis on #8150, as binding inputs that are not yet decisions;
- the open seams: who writes L0–L3 at Stage 6, and whether the engineering-harness universe takes a projection;
- #8016 (ms#428) as the remaining provisional seam;
- the rename cost of the chosen vocabulary (#8155 C3 ≈ 600 files as a replacement).

### Agent-Editability Read

**Derivation**, with the controls read at commit `b1042eec`:
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` has **2** `case "$ABS_TARGET"` blocks invoking `always_block "BLOCK-AUTONOMY-001"`. Their arms, verbatim:
  - Block 1 (lines 725–741):
    ```
    "${PRIMARY_ROOT}/CLAUDE.md" \
    | "${PRIMARY_ROOT}/projects/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md" \
    | "${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md" \
    | "${PRIMARY_ROOT}/.claude/settings.json" \
    | "${PRIMARY_ROOT}/.claude/hooks/"* \
    | "${PRIMARY_ROOT}/.claude/rules/"*)
    ```
  - Block 2 (lines 770–783, the membership stage): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md)`

  Projected to repo-relative form and filtered to tracked paths, the Tier-0 union is `CLAUDE.md`, `*/CLAUDE.md`, `OPERATIONS.md`, `*/OPERATIONS.md`, `RELEASE_PROTOCOL.md` and `*/RELEASE_PROTOCOL.md`. The workspace-root, `projects/` and `.claude/` arms are outside the repository and are discarded.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`:
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`;
  - arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`;
  - exemption list (`pmo_skill_editor_exemption_list_for`) = **undetermined**: two BLOCK-DESTRUCTIVE-022 refusals at Stage 4. It is immaterial here, because conjunct 1 is false on every row.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| release (Commit 0) | `release/releases/plans/stage-document-model-decision_RELEASE_PLAN.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8157 | `core/ADRs/ADR-232-stage-documents-are-declared-once-and-projected-twice.md` (the founding ADR, PA-007 (B)) | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8153 · #8154 · #8155 · #8156 | none tracked (records git-ignored; BLOCK-DESTRUCTIVE-019 exempts `analysis/<subfolder>/…`) | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke |

**Integration points:** none in code. The integration is the content join #8153–#8156 → #8157, which CIAC-2..CIAC-5 assert, and the ADR, which holds #8157's design.

## Delivery Strategy

**D-C SINGLE, recorded determination.** One branch, `release/stage-document-model-decision`. Engineering Commit 0 is this plan, written by a single designated writer, the first Stage-6 session launched (#8153). Under P1 no other Wave-1 session commits; their Stage-6 evidence goes to sub-task comments. In Wave 2 the #8157 session commits the founding ADR on the same branch (PA-007 (B)). The draft release PR opens at Stage 6 Phase C2. It merges at Stage 12 B1. B3 (version claim) is N/A for a version-less release; Phase A.5.7 reconciles the founding ADR's number if a sibling claimed the slot first; B4 runs; B5 lands the RELEASE_LOG row by chore PR. At Commit 0, steps 1–3 (version re-verify) are N/A, and `--verify-stamp` (step 3b) reports `TOKEN-LESS PLAN`, which is the correct version-less state and not a HALT. **Do not add the release-version stamp token to make it pass.** Stage 13 hand-assembles the version-less Phase-B chore PR:
- RELEASE_LOG `DEPLOYED → VERIFIED`;
- the INDEX and DIGEST entries;
- the note at `notes/_unversioned/stage-document-model-decision_RELEASE_NOTES.md`;
- the plan's move to `plans/_unversioned/`;
- the compiled Verification Evidence.

There is no CHANGELOG key and no `.version` stamp (SKIP-with-PASS), and no GitHub Release.

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Two waves: Wave 1 parallel compute (#8153–#8156), Wave 2 #8157 |
| **Commit strategy** | P1 serialized commit lane: Commit 0 (this plan) by the #8153 session; one ADR commit by the #8157 session in Wave 2; no force-push of any kind on the shared branch |
| **Review approach** | Single PR for the entire release, draft from Stage 6 Phase C2, ready-for-review at the Stage 9 gate |
| **Deployment mechanism** | Git merge only; no skill copy, no manifest execution (§ Operational Deployment Manifest) |
| **Stacked-base cleanup posture** | N/A — single branch, no stacked bases |

#### File Change Matrix

```
release/releases/plans/stage-document-model-decision_RELEASE_PLAN.md  ADD
core/ADRs/ADR-232-stage-documents-are-declared-once-and-projected-twice.md  ADD
core/ADRs/README.md  MODIFY (one § Renumber log line, written by the Stage-12 A.5.7c renumber)
```

The second row is the founding ADR (PA-007 (B)), written by the #8157 Stage-6 session in Wave 2. Its filename takes the mainline next-free number (`release/tools/renumber-adr.py --next-free`), and its slug is `stage-documents-are-declared-once-and-projected-twice`; the Wave-2 commit replaced the placeholder row with that literal path (DEV-21). Until the number bound at Stage 12, branch-authored prose cited the record by its slug token, `{{ADR:<slug>}}` (ADR-181), and carried no number. The stamp resolved those tokens at the ratification head. A sibling release then merged its own ADR-230 first, so Stage 12 Phase A.5.7 read this release's claim as a duplicate and renumbered the record to ADR-232 before the merge. That rewrote this row and moved the stamped citations (DEV-35).

The third row is that renumber's R4 step: one line appended to the § Renumber log of `core/ADRs/README.md`. Nothing else in that curated file changes, and DEV-23 still holds — the founding ADR gets no thematic entry.

#### Read-only inputs

`release/references/pipeline/stage-*.md` (13), `core/schemas/stage-io-contracts.md`, `release/governance/release-process.md`, `release/releases/plans/`, `release/releases/notes/`, `core/standards/operational-artifacts.md`, `core/standards/template-taxonomy.md`, `core/specs/operational-artifact-inventory.md`, `core/schemas/tracker-schemas.md`, `core/disciplines/lifecycle-tailoring.md`, `core/disciplines/five-function-spine-and-process-flows.md`, `operations/templates/`, `release/references/specs/methodology-parameterization-v1.md`, `core/packs/`, `core/schemas/project-schema.md`, `core/ADRs/ADR-211-…`, `core/ADRs/ADR-224-…`, `release/references/standards/bundle-composition-doctrine.md` — READ.

#### Release-wide explicit non-scope

Every other tracked path is NOT TOUCHED (CIAC-1 asserts it). The discovery and design records are git-ignored and are not FCM rows.

## Stage Applicability Matrix

| Stage | #8153 | #8154 | #8155 | #8156 | #8157 |
|---|---|---|---|---|---|
| 5 Solutioning | ✓ method spec for the re-scope | ✓ verification-only disposition | ✓ verification-only disposition | ✓ methodology design (Research-Methodology variant) | ✓ methodology design + T3 riders + design criteria for the widening |
| 6 Engineering | ✓ (Commit-0 writer) | ✓ verify and refresh against each AC; note the observations | ✓ same | ✓ discovery | ✓ author the design record and the founding ADR |
| 7 Dev Testing | ✓ refuter re-derivation sample | ✓ restored (PA-009) | ✓ restored (PA-009) | ✓ refuter sample | ✓ adversarial / refuter review + grading of the design criteria |
| 8 QA Testing | ✓ | ✓ | ✓ | ✓ | ✓ AC-1..AC-5 (AC-6 deferred to the gate) |
| 9 Plan Review | release-level, **Deep**, plus the **ratification D-gate** for #8157 ||||
| 10 / 11 | N/A, compressed: git-native, no deploy target, nothing to snapshot ||||
| 12 Execute | release-level: B1 merge, A.5.7 ADR reconciliation and stamp, B3 N/A (version-less), B4, B5 chore PR ||||
| 13 Close | release-level: version-less Phase-B chore PR; mark #8153–#8157 as closed after the ratification is recorded ||||

**Stage 5 activation (planning-solutioning-handoff.md § 4):**

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #8153 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | investigation; no tracked file |
| #8154 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | verify-only |
| #8155 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | verify-only |
| #8156 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | — | proposes hook options without choosing one |
| #8157 | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | T3: "#8150 leaves three decisions to design"; T4: extend `operational-artifacts.md` or split it, and choose among C1/C2/C3 |

**Release rollup: ACTIVATE**, under the all-or-nothing rule; mixed routing is DISABLED, and `novel` biases ALL anyway. The T3 riders travel to #8157's Stage-5 spec:
- § 3.1, altitude: name the seam extended, `operational-artifacts.md` § Artifact Lifecycle Patterns and the ADR-224 catalog, or justify a point solution with the search cited.
- § 3.2, structural premise: record "reviewed → retained / changed because …" for extending `operational-artifacts.md`.

Collective Review fired, with 5 issues in Solutioning.

**Ratification placement.** The gate sits at Stage 9, after Stage 7 and Stage 8 have verified the design record, so the operator ratifies a checked design.
- **D-Ratify-8157:** ratify / ratify with amendments / redirect. EXPENSIVE / HIGH, per the card's "EXPENSIVE scope-lock".
- The operator renders it; the hub posts the operator's decision verbatim on #8157. No spoke records it.
- A redirect sets `iterate:stage-6` for #8157 alone.
- #8157 AC-6 is graded after the gate, at Stage 13.
- The companion operator decision at the same gate is whether #8150's body and Out list change (per the 2026-10-24 Scope note).

### Quota Budget

**Verdict:** PASS against a full window; **WARN** if less than ~50% of the window remains at launch (`quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: 5 · Stage 7: 5 (3 at Stage 4; #8154 and #8155 restored by PA-009) · Stage 8: 5
**Per-spoke cost estimate:** size-bucket ordinal band (S lowest, M low–moderate, L moderate–high). The reference datum is ≈5% of a 5-hour window for a heavy spoke [INFERRED, from an operator-local fan-out observation, not from pipeline telemetry].
**Assumed/stated remaining usage-window envelope:** unstated, so a conservative 50% remaining is assumed
**Estimated cumulative draw % (worst parallel batch):** a 5-spoke stage is ≤ ~25% of a full window, ≈50% of the assumed envelope
**Routing:** WARN at the assumed envelope. Use window-aware launch and 3–4 lanes; the #8154 and #8155 dispositions are the lightest spokes and may run hub-direct.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch and is the load-bearing gate; its host-API axis is runtime-only. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Contention Map

- **Within the release: none.** The FCM has 2 paths, each with 1 writer (the plan: the #8153 session at Commit 0; the ADR: the #8157 session in Wave 2), and the waves serialize the two commits. Stage-4 probe: `bundle-issues-parser.py --issues 8153,8154,8155,8156,8157,7408` returned `affected_files: []` for all five, against 3 declared files for the control #7408 (PV-1 denominator 5 cards; sensitivity arm non-zero).
- **Cross-PR:** 1 open PR at `b1042eec` (#8651, draft). Its edit set ∩ this release's FCM and inputs = ∅ (control arm above). The ADR row adds `core/ADRs/` to the release's write surface; #8651's edit set was measured at Stage 4 against the plan path and inputs only, so the Stage-9 A6.6 re-measure covers the ADR row.
- **Structural blast radius:** the mover set is ∅ (add-only) and there is no `Δversion` token (version-less), so no Tier-S edge.

### In-Flight Release Roster

**Measured at:** `b1042eec` · `2026-11-05T16:45Z` · **Population:** n=1 sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `guards-judge-every-spelling-alike` | `#8651` | `fc556c66` | `minor` | none (bump-class only) | `v5.02` (allocation rule applied to fetched tags, anchor `v5.01`; allocator not invoked) | — |

This release is version-less, so the slot predicate does not apply to it.

## Risk Register

| # | Risk | Likelihood / impact | Mitigation | Owner |
|---|---|---|---|---|
| R1 | A spoke writes its record into its own worktree's `analysis/` copy, and worktree cleanup deletes it | Medium / High (lost discovery) | Every spoke prompt names the token-resolved home. Stage 6 C4 checks that the record exists at that home before the summary posts. | hub (prompts), Stage-6 spokes |
| R2 | A release-version stamp token in the version-less plan: `--verify-stamp` misleads, and a versioned sibling's slug derivation becomes ambiguous | Low / Medium | No token anywhere in the plan; the Version cell reads version-less; Commit-0 step 3b is recorded N/A | Commit-0 writer |
| R3 | #8157's widened scope (the loop, the hypothesis, L0–L3, the harness universe) overruns L / 2 days | Medium / Medium | Stage-5 design criteria per widened element; the Stage-5 methodology states its time box. An overrun becomes Tier 2 [SCOPE CHANGE], not a silent stretch. | #8157 Stage-5 spoke, operator |
| R4 | Instance detail from the analysis workspace reaches a public card or the plan | Medium / High (public repo) | The G-2 egress check before every summary (as on #8154 and #8155 on 2026-10-23); `path-leak-patterns.sh` on every comment and the plan; CIAC-6 | each spoke; Stage 9 |
| R5 | A seam moves before ratification: #8016 (ms#428) undecided, ms#437 publishing pages | Medium / Low | A seam is recorded as provisional and re-checked at ratification (the card's own rule); the ms#437 edge is in the map | #8157, hub |
| R6 | 25 pipeline-spec commits since the W1 baseline (cebcf6c2; 40 since card filing, 4babbba9) mean #8153 under-reports drift | Medium / Medium | Re-baseline at the run's `main` head; record the head SHA in the delta | #8153 |
| R7 | Close-out mis-classified (`task-artifact`, or rung-3 fall-through) | Low / Medium | `domain: governance` in the plan; Stage 13 reports the rung | Stage 13 |
| R8 | Ratification read as a spoke act | Low / High | Only the operator ratifies; the hub posts the verbatim decision | hub |
| R9 | The founding ADR's number slot is claimed by a sibling release first (ADR numbers bind at merge, ADR-115), or the curated `core/ADRs/README.md` needs an entry the FCM does not carry | Medium / Low | #8157 allocates with `release/tools/renumber-adr.py --next-free` against `origin/main` at its commit and checks the README; a README edit adds an FCM row and widens CIAC-1 in the same commit; Stage 12 A.5.7 reconciles a collided slot | #8157 Stage-6 session; Stage-12 executor |

## Rollback Strategy

**CHEAP.**
- Before Stage 12: abandon the branch. The records are git-ignored and stay as analysis.
- After merge: `git revert` the release PR, which carries this plan and the founding ADR, and the two chore PRs, if landed.
- A redirect at ratification is not a rollback: #8157 iterates to Stage 6.
- No version tag exists to retain.

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #8153–#8156 | none tracked; the git-ignored records stay as analysis | Low |
| #8157 | `git revert` of the ADR commit, or of the release merge | Low — one added file |

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8153 × #8154 × #8155 × #8156 × #8157 on the release diff):** the release changes no tracked file other than its own plan and the founding ADR under `core/ADRs/`, plus, only when Stage 12 Phase A.5.7c renumbers that ADR, the one line its R4 step appends to the § Renumber log of `core/ADRs/README.md` (DEV-35). *Method:* `git diff --name-only origin/main...HEAD -- . ':!release/releases/plans/stage-document-model-decision_RELEASE_PLAN.md' ':!core/ADRs/ADR-*.md' ':!core/ADRs/README.md'` expect 0. *Graded at Stage 9 QC3.5 on the merged PR, and re-graded at Stage 12 after the renumber; after the merge, the same instrument reads the range `<merge>^1 <merge>`.* Control arm, same instrument and target: `git diff --name-only origin/main...HEAD -- release/releases/plans/stage-document-model-decision_RELEASE_PLAN.md` expect 1. Bound on the README exclusion, read alongside: `git diff --numstat origin/main...HEAD -- core/ADRs/README.md` reads empty, or `1 0` with the one added line opening `` ADR-<old> (`stage-documents-are-declared-once-and-projected-twice`) → **ADR-<new>** ``. Residual, stated: the method alone admits any edit to `core/ADRs/README.md`; the bound is what holds it to the one renumber-log line.
- [ ] **CIAC-2 (#8153 × #8157 on the release projection):** every Stage 5 output that #8153 classifies as comment-only appears in the release projection of #8157's design record with a lifecycle class and a named reader, or "none" with a reason. *Method:* declared, verification deferred to #8153 AC-4, #8157 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#8154 × #8157 on the project-delivery projection):** every document row in the project-delivery projection of #8157's design record traces to a row of the #8154 record, or is named as new or dropped with a reason, and each of the #8154 disagreements is either resolved by the design or carried as an open item. *Method:* declared, verification deferred to #8154 AC-4, #8157 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#8155 × #8157 on the shared stage vocabulary):** the vocabulary #8157 chooses is one of the #8155 candidates, or a named derivative of one, and carries that candidate's stated rename cost. *Method:* declared, verification deferred to #8155 AC-3, #8157 AC-2. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#8156 × #8157 on the delivery-approach hook):** the hook #8157 states is assessed against every rail #8156 assessed, the per-space resolution rail included, and each delivery-approach variant #8157 shows resolves through it. *Method:* declared, verification deferred to #8156 AC-3, #8157 AC-3. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (#8153 × #8154 × #8155 × #8156 on the record homes):** every discovery summary names a record home under the analysis workspace and none under the legacy operator-instance tree, and no summary carries instance detail beyond what the cards already carry. *Method:* declared, verification deferred to #8153 AC-5, #8154 AC-5, #8155 AC-4, #8156 AC-4. *Graded at Stage 9 QC3.5 on the merged PR.*

CIAC lint at Stage 4: `CIAC-LINT-SUMMARY	declared=6	parsed=6	clean=1	declared-deferral=5	flagged=0` (`verify-release-plan.sh --ciac-lint`, exit 0; the first run flagged CIAC-5 `method-clause-displaced`, reworded). The Commit-0 re-read on this file, after the CIAC-1 amendment (DEV-13), is recorded in § Verification Evidence.

## Recommendations (transcribed from the Stage-4 output)

### Release Class declaration

**Proposed: `novel`** (matches the Stage-3 declaration), rendered as PA-005 and re-rendered unchanged after PA-007 (§ Release Class declaration above). Stage-4 trigger evidence:
- (b) fires: ≥1 D-class decision, namely the ratified design plus the four Ds below.
- Routine (a) fails: the cards are P2, not P3/P4.
- Cross-cutting (a)–(c) do not fire: 0 stage files and 0 governance surfaces are changed; 4 compositional edges, but all of them feed one card.

### Operator Decisions (D-Gate Block)

**Recorded determinations (not gates):**
- **D-Version:** version-less, condition (B); re-confirmed by the operator after PA-007.
- **D-C Branch Topology:** SINGLE.
- **Delivery shape:** one PR, carrying the plan as Commit 0 (precedent PR #604) and, after PA-007, the founding ADR.
- **Stage 5:** ACTIVATE, under the all-or-nothing rule.

For each, the override valve is the operator's: name an alternative and the hub re-plans.

#### D-8157-Scope: Amend #8157's acceptance criteria now, or carry the 2026-10-24 widening as a binding input and decide the body at ratification?
**Gate input:** the operator's 2026-10-24 enrichment on #8150 widened the design to the design → build → validate → document loop. Its Scope note leaves the body decision to #8157's ratification. None of #8157's six ACs names the loop (Mode R #8157 proposed-change-1).
**Gate decision:**
- **(A)** Amend now: add an AC for the loop and the hypothesis disposition; add #8016 to AC-4; add the engineering-harness universe to AC-2.
- **(B)** Carry as a binding input:
  - The plan's input register binds it.
  - #8157's Stage-5 spec authors one design criterion (`design #8157 AC-k`, `Maps-to: none`) per widened element: the loop's six steps; adopt / modify / reject for each element of the leading hypothesis; the L0–L3 writer; the engineering-harness projection; and #8016 as a provisional seam. Stage 7 grades them.
  - #8157's body and ACs, and #8150's Out list, are decided at ratification.
**Blocks:** #8157 Stage 5.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A): `**CONFLICT.**` DP-3 Maintainability (`core/disciplines/build-philosophy.md:50`). The ACs would restate the widening, which lives in the #8150 comment. Mitigation: phrase the AC as "addresses the widening recorded on #8150", citing it rather than copying it.
- (A): ALIGNED DP-7 Track-all-edits (`build-philosophy.md:56`). The edit goes through the plan's deviation log.
- (B): ALIGNED DP-3, because the comment stays the single source.
- (B): ALIGNED DP-4 Simplicity (`build-philosophy.md:51`), because there is no body edit.
- (B): ALIGNED DP-7.

The register rows were last verified 2026-07-27, more than 90 days before Stage 4; the verdicts hold on their statements.
**Reversibility / Confidence:** CHEAP / HIGH. Either path can change at any later gate.
**Recommendation:** **(B).** Rendered (B) as PA-002.

#### D-VerifiedCards: Keep #8154 and #8155 in this release as verify-only, or mark them closed outside it?
**Gate input:** both records and summaries already meet every AC, and refuters checked them (Mode R; the 2026-10-23 comments).
**Gate decision:**
- **(A)** Keep: Stage 6 verifies and accounts for the 2026-10-25 observations; Stage 13 marks them closed.
- **(B)** Remove both from the milestone and mark them closed now, with the verification evidence.
**Blocks:** Procedure 1 scaffolding for both cards.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A): ALIGNED DP-4: no restructure.
- (B): ALIGNED DP-4, but it rewrites the milestone composition after the Composition Lock (G-CL10 re-pointing).
**Reversibility / Confidence:** CHEAP / HIGH
**Recommendation:** **(A).** Rendered (A) as PA-003; PA-009 later raised their rigor to verify-and-refresh with Stage 7 restored.

#### D-Concurrency Posture: Which Stage-6 parallelism posture?
**Gate input:**
- Contention map: 1 tracked path and 1 writer at Stage 4 (2 paths, 2 writers in separate waves after PA-007).
- `overlap_class`: single-pr.
- Topology: SINGLE.
- Waves: 2. Wave 1 has 4 cards, and only Commit 0 is a tracked write.
**Gate decision:** P0 serial, or P1 serialized commit lane (parallel compute, serial commit).
**Blocks:** Wave-1 Stage-6 dispatch.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A — no design-principle scope_predicate matches this option's change surface.
**Reversibility / Confidence:** CHEAP / HIGH
**Recommendation:** **P1.** Rendered P1 as PA-004: Wave-1 compute runs in parallel; the #8153 session holds the lane for Commit 0; the other three Wave-1 sessions never commit; no force-push of any kind.

#### D-ReleaseClass: Re-confirm `novel`?
**Gate decision:** (A) routine · (B) novel · (C) cross-cutting · (D) hotfix.
**Blocks:** the Stage-9 review depth.
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface.
**Reversibility / Confidence:** CHEAP / HIGH
**Recommendation:** **(B) novel**, unchanged. Rendered as PA-005.

### Merge / split
- **No merge, no split.** The four discovery cards stay separate: one record each, one synthesis point.
- #8157 stays one card. Splitting the loop out would create two ratification gates, and size:XL would route it to G3-09 decomposition, against the tight-merge the operator ratified.

### Size re-check

Zero-surface work has no row in the doctrine, so every class below is a judgment with its reason.

| Card | Was | Proposed | Reason |
|---|---|---|---|
| #8153 | M (4) | M (4) | The method changes, the effort does not: 112 rows against 25 spec commits since the W1 baseline plus 70 P2 pages |
| #8154 | M (4) | **S (2)** | Verify against a finished record, and note four observations |
| #8155 | M (4) | **S (2)** | Verify, and note two observations |
| #8156 | M (4) | M (4) | Unchanged; one rail added |
| #8157 | L (8) | L (8) | The widening is real; R3 guards it |

**20 raw × 1.15 = 23 effective**, which is inside 15–25. The over-band disposition retires.

### Proposed edits for the hub to apply after plan approval

Each was a Tier 1 [ADJUST]; each is a row of § Deviation Log with its read-back.

1. **Documentation Impact, all five cards.** Remove the one trailing `.` after the closing `)` (DEV-1).
2. **Labels.** #8154 `size:M` → `size:S`; #8155 `size:M` → `size:S` (DEV-2).
3. **#8157 body, stale prose only. The ACs stay unchanged under (B)** (DEV-3).
4. **Milestone description (ms#432):** the size table and total, the size disposition, the Actors line, the Parallelization Map dated 2026-11-05, the Limb owners line and the Release Outcome Statement (DEV-4).
5. **Plan file (Commit 0):** the `domain_practice` label, `audit_class: true`, a Version cell reading `(none) — version-less` with no release-version stamp token, and the AC baseline (DEV-5).

### Release Outcome Statement (Stage-4 draft, applied to the milestone description by the hub)

The milestone description is this statement's home. The text below is the approved Stage-4 draft as transcribed; § Deviation Log DEV-12 records the two clauses PA-007 supersedes.

```markdown
### Release Outcome Statement

**AFTER:** The stage-to-document model for release and project delivery has an evidence-based design that the operator has ratified or redirected. The design states:
- what each delivery stage writes;
- each document's lifecycle class, template, home and readers;
- one stage vocabulary, mapped onto both the release pipeline and project delivery;
- the hook a delivery approach uses to vary cadence and lifecycle class;
- how a change moves through design → build → validate → document (the 2026-10-24 widening).

It also proposes how epic #8150 is cut into delivery slices and milestones.

**BEFORE:** What each stage should write is spread across two tables that disagree on the stage list. Stage 5 design output does not survive a release, and the epic has no design to build against.

**Actor(s):** one re-scoped verification session (#8153), two verification sessions (#8154, #8155), one discovery session (#8156), one design session (#8157), and the operator at the ratification gate.

**Success Indicator:** #8157 records the operator's ratification and the proposed delivery cut, and the founding ADR card is filed against the ratified design.

**Limb owners:** what each stage writes, with lifecycle class, template, home and readers → #8157, #8153, #8154 · one stage vocabulary on both projections → #8157, #8155 · the delivery-approach hook → #8157, #8156 · the design → build → validate → document loop → #8157 · the proposed delivery cut → #8157
```

## Verification Plan

### Per-Issue Verification

Every row is graded at Stage 8 by a named read. The plan verifier runs none of them (SKIP); CIAC-1 is the one command it runs.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8153 | AC-1 | declared, verification deferred to Stage 8 QA — read of the delta record's stage column against the W1 base | 13 of 13 stages, each with ≥1 row or a stated reason |
| #8153 | AC-2 | declared, verification deferred to Stage 8 QA — read of the home, lifecycle-class and reader columns | no empty cell · control: the same read over a copy with one cell blanked → 1 |
| #8153 | AC-3 | declared, verification deferred to Stage 8 QA — read of the sample note | size and selection rule stated, with the release-shape note |
| #8153 | AC-4 | declared, verification deferred to Stage 8 QA — read of the Stage-5 rows against the 5→6 boundary of `core/schemas/stage-io-contracts.md` | each of the 11 named outputs classed durable or comment-only, each with a catalog-page-candidate verdict (yes with its page section, or no with the failing test) |
| #8153 | AC-5 | declared, verification deferred to Stage 8 QA — read of the #8153 thread | summary posted, naming the record home |
| #8154 | AC-1 | declared, verification deferred to Stage 8 QA — read of the W2 record | 50 names: 46 mapped, 4 dropped with a reason |
| #8154 | AC-2 | declared, verification deferred to Stage 8 QA — read of the template-family column | 90 rows, each a family or none |
| #8154 | AC-3 | declared, verification deferred to Stage 8 QA — read of the lifecycle, home and reader columns | no empty cell · control: the same read over a copy with one cell blanked → 1 |
| #8154 | AC-4 | declared, verification deferred to Stage 8 QA — read of the disagreements table | 46 rows, plus the 2026-10-25 observations noted beside the record |
| #8154 | AC-5 | declared, verification deferred to Stage 8 QA — read of the #8154 thread | summary of 2026-10-23 present, naming the record home |
| #8155 | AC-1 | declared, verification deferred to Stage 8 QA — read of the W3 crosswalk | 18 rows covering 13 / 11 / 6 and the lifecycle states |
| #8155 | AC-2 | declared, verification deferred to Stage 8 QA — read of the source list | at least 2 sources, each with its contribution (16 reported) |
| #8155 | AC-3 | declared, verification deferred to Stage 8 QA — read of the candidates | 3 candidates, each with tradeoffs and rename cost |
| #8155 | AC-4 | declared, verification deferred to Stage 8 QA — read of the #8155 thread | summary of 2026-10-23 present, naming the record home |
| #8156 | AC-1 | declared, verification deferred to Stage 8 QA — read of the matrix | 8 rows, one per `delivery_approach` value |
| #8156 | AC-2 | declared, verification deferred to Stage 8 QA — read of the matrix cells | cadence and class for design, plan, test and release on each row, or the configuration that supplies them |
| #8156 | AC-3 | declared, verification deferred to Stage 8 QA — read of the rail assessment | 5 rails assessed, the per-space resolution included |
| #8156 | AC-4 | declared, verification deferred to Stage 8 QA — read of the #8156 thread | summary posted, naming the record home |
| #8157 | AC-1 | declared, verification deferred to Stage 8 QA — read of the design record's axis section | 4 axes, each with a coverage state and a concrete element; structure-placement names the file and the home-class rule |
| #8157 | AC-2 | declared, verification deferred to Stage 8 QA — read of the vocabulary section | one vocabulary, mapped to the 13 stages and the delivery phases |
| #8157 | AC-3 | declared, verification deferred to Stage 8 QA — read of the hook section | the hook, with at least 2 delivery-approach variants shown |
| #8157 | AC-4 | declared, verification deferred to Stage 8 QA — read of the seams section | the seams with #8117, #8114, #8005 and project-data-architecture |
| #8157 | AC-5 | declared, verification deferred to Stage 8 QA — read of the delivery cut | each slice with its work nature and edges, grouped into milestones |
| #8157 | AC-6 | [DEFERRED — graded at Stage 13, after the Stage-9 ratification gate, by reading #8157 for the operator's recorded decision] | the ratification or redirection is recorded |

**AC baseline** — per-issue criterion counts as read at Stage 4, and the commit SHA read against (#8153 5 · #8154 5 · #8155 4 · #8156 4 · #8157 6 = **24**):

```
ac_baseline: { #8153: 5, #8154: 5, #8155: 4, #8156: 4, #8157: 6, read_at: b1042eec }
```

### Release-Level Verification

- [ ] File Integrity — the release diff equals the three FCM rows (CIAC-1; `fcm-delivery`)
- [ ] Content Correctness — the Stage-8 per-criterion verdicts above
- [ ] Cross-Reference Validity — the PR-time link gates on this plan and the ADR
- [ ] Skill Invocation — N/A: no skill changes
- [ ] Output Contract Compliance — CIAC-2..CIAC-6, read at Stage 9 QC3.5

## Operational Deployment Manifest

N/A — enumerated over the propagation classes reasoned over: skill copies (S-2), harness artifacts, rules-mirror pairs, operator-instance seed files, and Layer-2 file targets. None present in this release: the FCM holds a release plan and an ADR, neither of which propagates to Layer 2.

### Schema Migrations

N/A — enumerated over data-schema changes, frontmatter-schema version bumps, event-log schema versions and tracker-schema columns. None present in this release.

### Memory Evictions

N/A — enumerated over the manifest classes reasoned over, memory eviction among them: no card in this release is a codification card tied to an auto-memory entry. None present in this release.

## Discoveries outside scope (transcribed from the Stage-4 output)

- `hub-spoke-bridge.md` Procedure 0, Commit-0 step 3b, has no version-less carve-out. On a version-less plan `--verify-stamp` returns `TOKEN-LESS PLAN` by design, but the text says HALT and restore the token. Minor · `follow-up: none · bug`
- `git-workflow.md` says a spawned spoke never mutates the primary checkout, while `analysis-workspace-standard.md` lets any session shape write `analysis/`, and the token resolves inside the primary checkout. This plan follows the standard (R1). Minor · `follow-up: none · bug`
- Procedure 7 audit-class detection reads the release diff, so git-ignored records always read 0. This plan uses the documented declaration fallback. Informational.
- #8150's Out list still routes system documentation to #8110, whose state is now CLOSED (completed). This is an input to the #8150 body decision at ratification. Informational.

## Hub actions (transcribed from the Stage-4 output)

- **Instrumentation rows.** Append 5 rows to `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/triage-design-rereview-instrumentation.md` at anchors `stage-document-model-decision/<N>/4` (appended by the hub after Stage 4).
- **Phase B.** Emit `decision/d-class` per D, the five `card-disposition:carried` rows, and `decision/scope-lock`.
- **After ratification:**
  - Post the operator's verbatim decision on #8157.
  - Move the founding ADR from `Proposed` to `Accepted` on this branch (PA-007 (B) replaces the Stage-4 action "file the founding ADR card through intake-desk"; DEV-12).
  - Edit #8150's body or Out list only as the operator decides.

## Verification Evidence

Commit-0 entries. Later stages append theirs.

- **Commit-0 version re-verify (Procedure 0 § Canonical location).** Steps 1–3: N/A, version-less (no planned version exists to collide). Step 3b: `release/tools/claim-version.sh --verify-stamp stage-document-model-decision` → `verify-stamp TOKEN-LESS PLAN`, exit 1 — the correct state for a version-less plan, not a HALT (D-Version re-render, 2026-11-05). Sensitivity arm, same instrument and file: the first transcription, which still named the token literally in prose, read `verify-stamp OK`, exit 0 (DEV-19).
- **CIAC lint re-read (Stage 6 A1):** `release/tools/verify-release-plan.sh --ciac-lint` on this file → `CIAC-LINT-SUMMARY	declared=6	parsed=6	clean=1	declared-deferral=5	flagged=0`, exit 0 (CIAC-1 `CLEAN` after the DEV-13 amendment; CIAC-2..6 `DECLARED`). No CIAC is flagged, so Gate 4 criterion G4-06 reads PROCEED at Stage 6 entry.
- **AC binding:** `python3 release/tools/check-ac-binding.py --fetch` on this file → `VERDICT BOUND ns:plan>issue`, exit 0: 24 rows, every baseline count equal to the live criterion count (5 / 5 / 4 / 4 / 6), coverage 1..N on all five cards.
- **Path-leak scan:** `bash core/deploy/tools/path-leak-patterns.sh --scan-file` on this file → exit 0; sensitivity arm, a planted absolute home path in a control file → exit 1.
- **ADR index:** N/A — this release adds no record under `release/ADRs/`; the founding ADR is under `core/ADRs/`, whose README is curated and has no projector.
- **Runtime suite:** `test-run/suite-skip` — the change set is a release plan and an ADR, the selection map's no-match row (doc/governance/spec-only).

Wave-2 entries (the #8157 Stage-6 commit that adds the founding ADR):

- **ADR number:** `release/tools/renumber-adr.py --next-free` → the mainline anchor plus one; `--detect` reports the branch's claim and two claims on unmerged branches (detection only). `python3 release/tools/check-adr-numbers.py` → PASS, contiguous, no duplicates.
- **ADR durability lint:** `python3 release/tools/check-adr-durability.py --files <the ADR> --diff-base origin/main` → `COUNT 0`; sensitivity arm, a copy carrying a live population count and a hardcoded SHA → `COUNT 2` (R2-COUNT, R2-SHA).
- **Issue-reference validity:** `check-issue-ref-validity.sh --path <the ADR> --resolver gh` → pass (every bare reference resolves and sits in `## References`); sensitivity arm, a file with a bare reference in body prose → the gate's failure text.
- **Dead-file references:** `check-release-links.py --roots core release docs .github --top-level-md --check-anchors --images --diff-base origin/main --files <plan> <ADR>` → 0 broken links.
- **Operator-memory references (DEV-25):** the pattern of `.github/workflows/operator-memory-ref.yml`, run with `grep -cE` → this file 7 at Commit 0, 0 now; the ADR 0; control, a line naming a memory-shaped file → 1.
- **Path-leak scan:** `path-leak-patterns.sh --scan-file` → exit 0 on this file and on the ADR; control → exit 1.
- **AC binding with the design criteria:** `check-ac-binding.py --fetch --design-file <design criteria, AC-1..AC-12>` → `VERDICT BOUND ns:plan>issue,design>issue`; design AC-1..AC-6 BOUND, AC-7..AC-12 NONE (`Maps-to: none`, as designed).
- **ADR index:** N/A — the record is under `core/ADRs/`, whose README is curated (DEV-23).
- **Skill packages:** `printf '%s\n' <changed paths> | bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` → no skill named; nothing to rebuild.

Stage-12 entries (the A.5.7 reconciliation, the merge, and Phases B1.1 and B4):

- **ADR number (A.5.7a/c/e):** after the signed merge of `origin/main` (`02f72af6`), `release/tools/renumber-adr.py --detect` read this release's ADR-230 as DUPLICATE (anchor 231, next-free 232). `--renumber 230 232 --apply` exited 0 (`bab6e677`, signed): R1 PROCEED; R3 moved 5 citations, and its REVIEW block named 0 sites; R4 added one § Renumber log line to `core/ADRs/README.md`, and the `release/ADRs/` index regenerated UNCHANGED; R5 wrote the provenance note; R6 found zero dangling; R7 found no package affected. Re-read before the merge: `--detect` reads `CLAIM ADR-232 … BINDS`, and `--stamp --check` finds 0 residual tokens. `[REFCASCADE: git grep ADR-230 over the release diff → pre 5 / post 0]`; the ADR-230 mentions that remain are the provenance note and the renumber-log records.
- **Required checks (GO condition C1):** on `bab6e677`, 24 of 24 branch-protection contexts read `completed / success`, matched by name from REST `check-runs` to `branches/main/protection/required_status_checks`; 57 of 57 runs read the same. Control: a name absent from the roster reads missing.
- **CIAC-1 re-grade:** as first written, the predicate returned 1 file on the release merge (`core/ADRs/README.md`), so it was not met. Amended (DEV-35), its first command returns 0, its README numstat reads `1 0`, and the added line is the renumber-log entry. Control: the plan reads 1. Sensitivity arm: the unamended command on the same range reads 1.
- **Phase B1.1 sibling dark-branch sweep:** `release/tools/check-dark-branch.py sweep … --before ef7a0ec5 --after b0763aac` exited 0. Of 5 open pull requests on `main`, 0 were newly dark. 2 were still dark (#8821 and #8651), and each was already conflicted before this push. `state=none-new`.
- **Phase B4 release-stamped deploy:** run from the hub worktree detached at `origin/main` (`b0763aac`; `merge-base --is-ancestor` exit 0). Before the deploy, the join key `stage-document-model-decision` was read back non-empty with 76 rows. The merge changed 0 paths under the skill and package roots, so the command was `bash core/deploy/deploy.sh --deploy --release stage-document-model-decision --no-targets`; it exited 0 and wrote the rules mirror (9 files). It appended one `deployment-status/deploy-rules-mirror` row, making 77 rows. The run did not report `Deploy mode: user-local only`.

## Deployment Execution Log

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | 2026-11-07T06:00Z | PASS | 24/24 required checks green on `bab6e677`; `main` (`ef7a0ec5`) an ancestor; merge state `clean` |
| Merge PR | 2026-11-07T06:02:31Z | MERGED | #8814 → `b0763aac` (parents `ef7a0ec5`, `bab6e677`); REST merge pinned to the head SHA; no admin override; read back `merged == true` |
| ADR number reconciliation and stamp (A.5.7) | 2026-11-07T03:29:31Z | RENUMBERED | ADR-230 DUPLICATE → ADR-232 (`bab6e677`); BINDS; stamp check 0 residual (DEV-35) |
| Version claim | N/A | N/A | version-less |
| Post-execution verification | 2026-11-07T06:05:14Z | PASS | B1.1 exit 0, 0 newly dark; B4 `--no-targets` exit 0, one rules-mirror row; primary checkout fast-forwarded to `b0763aac` |

## Deviation Log

Departures from the Stage-4 comment (comment 6664007762 on #8751), each with the authority that licensed it. Tier 1 [ADJUST] unless stated.

| # | Deviation | Source and authority | Rationale | Disposition |
|---|---|---|---|---|
| DEV-1 | Documentation Impact: the trailing `.` after the closing `)` removed on all five cards | Stage-4 proposed edit 1; applied by the hub under PA-001 | The parser graded all five `ungradable`; fixture DI-2 versus DI-4 at `bundle-issues-parser.py:1123/1125` confirms the graded form | APPLIED — read back at Commit 0: 5 of 5 cards carry one Documentation Impact line with no trailing period |
| DEV-2 | Labels: #8154 and #8155 `size:M` → `size:S` | Stage-4 proposed edit 2; hub under PA-001 | Verify against a finished record is S-sized work | APPLIED — read back at Commit 0: #8154 `size:S`, #8155 `size:S`; #8153 `size:M`, #8156 `size:M`, #8157 `size:L` unchanged |
| DEV-3 | #8157 body, stale prose: "#8117 is deciding" → decided (ADR-224, Accepted); the first risk rewritten as alignment with ADR-224's ratified vocabulary. The ACs are unchanged | Stage-4 proposed edit 3; hub under PA-001 | A0 ticket-architecture reconciliation: CURRENCY-MISMATCH on #8157 only | APPLIED — read back at Commit 0: the body no longer contains "#8117 is deciding" and contains "#8117 decided" and "ADR-224" |
| DEV-4 | Milestone description (ms#432): size table (#8154, #8155 at S / 2), total `5 cards / 20 pts (23 effective)`, size disposition, Actors line, Parallelization Map recorded 2026-11-05, Limb owners line, Release Outcome Statement | Stage-4 proposed edit 4; hub under PA-001 | Parallelization-Map currency gate (stale → amend) and the re-size | APPLIED — read back at Commit 0. One form difference: the `### Size disposition (G3-15)` heading was kept and its body replaced with the in-band text, where the edit said to replace the section; the substance is the same |
| DEV-5 | Plan-file Commit-0 carries: the `domain_practice` label, `audit_class: true`, the Version cell `(none) — version-less` with no release-version stamp token, and the 24-criterion AC baseline | Stage-4 proposed edit 5; PA-001; the D-Version re-render | Commit-0 Survival Set rows 1 and 5; the audit-class declaration fallback | APPLIED in this file |
| DEV-6 | R-2: the drift since the W1 baseline is 25 pipeline-spec commits (`cebcf6c2..b1042eec`), not 40 (40 is since card filing, `4babbba9`); the P2 page census is exactly 70. Edited: R6, and the #8153 size cell | #8153 Stage-5 design R-2 (comment 6665186074); approved by Collective Review ("Approve all five"), PA-006 | Probe P-3: 25 and 40 over the two ranges; P-5: 70 pages | APPLIED in this file. The Phase A0 rows that state 40 since `4babbba9` are preserved, because they are correct for their stated range |
| DEV-7 | R-3: the #8153 AC-4 expected result reads as a binary class plus a catalog-page-candidate verdict, not a three-way enum. The AC itself is unchanged | #8153 Stage-5 design R-3 and D-3; Collective Review | A three-way enum loses the current-home fact AC-4 exists to surface | APPLIED in § Per-Issue Verification |
| DEV-8 | R-4: `<run-date>` in Implementation Sequence rows 1, 4 and 5 resolved to `2026-11-05` | #8153 Stage-5 design R-4; Collective Review recorded determination (`${AUDIT_DATE_UTC}` resolved once at the hub) | The folder name is load-bearing for three cards; the Stage-5 design had the Commit-0 writer run `date`, and Collective Review moved the resolution to the hub, so this session substituted the injected value and ran no `date` | APPLIED: 3 of 3 cells |
| DEV-9 | R6: the verification section is rendered as `## Verification Plan` → `### Per-Issue Verification`, with the `ac_baseline:` line inside it | #8157 Stage-5 design R6 (comment 6664987065); Collective Review | `release/tools/check-ac-binding.py` reads those two anchors; the Stage-4 comment carried neither, so the checker read it UNPARSEABLE | APPLIED in § Verification Plan |
| DEV-10 | #8154 D-1: the 2026-10-25 observations are noted in two new files beside the W2 record, with the base byte-identical; Implementation Sequence row 2, the size cell and the #8154 AC-4 expected result now say "note" where the Stage-4 comment said "fold in or note" | #8154 Stage-5 design D-1 (comment 6665013890); Collective Review | The only option that meets verify-only, nothing re-authored and "note them there" together; the base is cited from 283 files at 430 anchored sites | APPLIED in this file |
| DEV-11 | PA-006: the Collective Review amendments. (1) #8153 gains a field-check arm (minimum form) with the delta keyed by (stage, document) and a pinned sha256; (2) #8156 fills cells from sources only, derived values in their own columns, lifecycle class bound per member with its source entity, an empty-group code, AC-2 read strictly; (3) #8157 takes the registered-report form, fixes its eliminators, binds its method to the four sibling outputs (#8156's `hook-options.tsv` and #8154's addendum included), restates INT-1/2/3/5 on the real record shapes, and adds the second lifecycle vocabulary to DR-2; (4) every card uses one sunset rule with both limbs; (5) #8154 and #8155 use one shared verification-file form. The #8153 design's single-writer rule for the parent `SUMMARY.md` (D-6) is carried into row 4 | Collective Review Decision Recorded (comment 6666337237 on #8751), PA-006, MODERATE | Approved with amendments; applied as Tier 1 [ADJUST] on the Stage 6–8 sub-tasks by the hub | APPLIED in Implementation Sequence rows 1–5 and the record-home rule |
| DEV-12 | **PA-007 — Tier 2 [SCOPE CHANGE].** (B): the release ships the founding ADR, authored `Proposed` by the #8157 Stage-6 session in Wave 2 and moved to `Accepted` at ratification. The File Change Matrix gains its row; the Summary, Delivery Strategy, Agent-Editability Read, Stage Applicability Matrix (Stages 6 and 12), Contention Map, Risk Register (R9 added), Rollback Strategy and Hub actions are reconciled to it. (C): the current-state inventories are routed as input to the #8115 process-catalog pages through a coordination edge (§ Dependency Graph) | Collective Review, PA-007, MODERATE; release identity re-confirmed version-less by the operator (comment 6666420320 on #8751) | The operator chose a durable tracked home for the design; Release Class stays `novel` (trigger (a)); D-Version stays version-less | APPLIED in this file. **Not applied here, routed to the hub:** the milestone description, the Release Outcome Statement's home, still says "No member changes a tracked file" (Release Class rationale and Scope) and "the founding ADR card is filed against the ratified design" / "the founding ADR card is filed as the first slice" (Success Indicator and Downstream). PA-007 supersedes those clauses; the § Release Outcome Statement copy above stays as approved, because the milestone is its home |
| DEV-13 | CIAC-1 widened to admit the founding ADR: the predicate names it, and the method gains the exclusion `':!core/ADRs/ADR-*.md'` | Cascade of PA-007 (DEV-12) | As authored, CIAC-1 grades NOT MET the moment the ADR lands. Residual, stated: the exclusion also admits an edit to an existing core ADR, which the FCM's `fcm-delivery` check and Stage-9 review would surface | APPLIED in § Cross-Issue Acceptance Criteria; the CIAC lint is re-run on this file |
| DEV-14 | The founding-ADR FCM row is written `core/ADRs/ADR-NNN-<slug>.md`, not the form the Commit-0 brief gave, `core/ADRs/ADR-{{ADR:<slug>}}-….md` | Commit-0 writer, transparency note; same intent as the brief | The FCM parser normalizes the brief's form to `core/ADRs/ADR-*-….md`, keeping a literal ellipsis no delivered filename carries, so Stage 9's `fcm-delivery` would read the ADR as never delivered; and the Stage-12 stamp rewrites a `{{ADR:…}}` token to `ADR-NNN`, which would read `ADR-ADR-NNN` in a filename. `ADR-NNN-<slug>` is the corpus's established placeholder (8 earlier plans) and normalizes to `core/ADRs/ADR-*-*.md` | APPLIED; the #8157 commit replaces the row with the literal path |
| DEV-15 | PA-008 (a): the process-baseline findings assigned to #8153 (7), #8154 (15) and #8155 (6) are carried as tagged release follow-ups; each card's Stage-6 record holds its owned-findings table | Collective Review, PA-008, CHEAP | The Stage-9 ledger reads them and Stage 13 files them | APPLIED in Implementation Sequence rows 1–3 |
| DEV-16 | PA-009 (a): Stage 7 restored for #8154 and #8155 (#8785 and #8786 reopen); their Stage 6 is verify-and-refresh (figures re-measured at head, a collision check against `lifecycle-states-canonical.md` § 5, an owned-findings table). The Stage Applicability Matrix and the Quota Budget's Stage-7 count (3 → 5) are updated | Collective Review, PA-009, CHEAP | A verify-only pass that re-reads a summary is not an independent check | APPLIED in this file |
| DEV-17 | PA-010 (b): #8157 gains one graded design criterion for the operator's four § 2 constraints (no bloat; reviewed over releases; repo versus local-folder best practice; repeatable for adopters) | Collective Review, PA-010, CHEAP | The operator's build principles become gradable at Stage 7 | APPLIED in Implementation Sequence row 5 |
| DEV-18 | AC-Binding Limb 2: the two null expected results (#8153 AC-2 and #8154 AC-3, "no empty cell") gain a control arm on the same read | Commit-0 writer, Tier 1 [ADJUST]; `stage-04-planning.md` § AC-Binding Limb 2 | A null result needs a control arm on the same instrument and target; the Stage-4 rows carried none | APPLIED in § Per-Issue Verification |
| DEV-19 | The literal release-version stamp token is named in words, never written out, at the six sites where the Stage-4 comment wrote it in prose (the identity note, the Summary risk line, the Delivery Strategy warning, R2, edit 5 and DEV-5) | Commit-0 writer, Tier 1 [ADJUST]; risk R2 | `claim-version.sh` matches the literal token anywhere in a plan: a first transcription that kept it in prose made `--verify-stamp` report `verify-stamp OK` instead of `TOKEN-LESS PLAN`, and the same match would count this plan when a versioned sibling's claim derives its slug — R2's two harms, produced by text that warns against them | APPLIED: 0 literal tokens in this file; step 3b re-run reads `TOKEN-LESS PLAN` (§ Verification Evidence) |
| DEV-20 | #8155 D-2 (note rather than fold): #8155's 2026-10-25 observations are **noted** beside the W3 crosswalk record (its `verification.md` § 3), not folded into it, and the record's base files stay as verified. Two sites of this plan already carry that wording without a row until now: D-VerifiedCards (A), which reads "verifies and accounts for the 2026-10-25 observations" where the Stage-4 comment read "verifies and folds in", and the #8155 cell of § Size re-check, which reads "Verify, and note two observations" where the Stage-4 comment read "fold in two observations" | #8155 Stage-5 design D-2 and its Phase A6.5 FM-4; #8155 Stage-6 output (comment 6666816989 on #8781); #8155 Stage-7 F-06 (comment 6668420098 on #8786); Collective Review PA-006 (5) | Folding would re-author a refuter-verified record pinned to one baseline; #8157 reads the observations from the note. DEV-10 covers #8154 only | APPLIED: this row records the two existing sites; the W3 record is unchanged and is read by #8157 together with its `verification.md` |
| DEV-21 | The File Change Matrix row and the Agent-Editability Read write-set path name the founding ADR's literal path, replacing the `ADR-NNN-<slug>` placeholder | #8157 Stage-6 session, per DEV-14's stated disposition | The number is the mainline next-free slot (`renumber-adr.py --next-free`); `--detect` also showed two higher-or-equal numbers claimed on unmerged branches, reported as detection only (adr-helper allocation rule), so a merge-time renumber is possible and Stage 12 A.5.7 owns it | APPLIED in § File Change Matrix and § Agent-Editability Read; DEV-14 is kept as the record of the placeholder |
| DEV-22 | The founding ADR is authored with its decision prose filled in, where the `adr-helper` scaffold leaves decision sections as author-fill placeholders | Collective Review PA-007 (B): the release ships the founding ADR "holding #8157's design and gap map with the current-state evidence summarized in its Context" | The operator's PA-007 decision is the authorization for the prose, and the prose restates the #8157 design record rather than inventing rationale; the record stays `Proposed`, and only the operator's Stage-9 ratification moves it to `Accepted` | APPLIED; the ADR's own structural lints are in § Verification Evidence |
| DEV-23 | No `core/ADRs/README.md` entry is added for the founding ADR | R9's README check, run at the #8157 commit | That README is a curated thematic document, not an index (its own opening paragraph, ADR-117); adr-helper registers nothing for a `core/ADRs/` record | APPLIED: the File Change Matrix stays at two rows and CIAC-1 is unchanged |
| DEV-24 | The #8157 design record is staged in the spoke's run directory with a sha256 manifest for the hub to place, rather than written at the token-resolved analysis home; the harness also refused the subagent's write of the record's index file (`SUMMARY.md`), whose content therefore travels in the spoke's hand-back for hub-direct placement | The operator's record-placement decision (2026-11-05) and the #8157 Wave-2 brief; the Collective Review recorded determination (a refused write is placed hub-direct) | An isolated spoke cannot write the primary analysis workspace; the refusal of the index file is a harness control, recorded as a firing on #8783, not routed around | STAGED at this commit; placing the folder, and checking each file's sha256 and `git check-ignore -v`, is the hub's step |
| DEV-25 | In the transcribed Phase A0 tables (#8153, #8154, #8155, #8156 and #8157 rows), the seven D3 cells that named an operator-local memory file now state the principle it stands for as one plain clause labelled `[CONTEXT]`, and drop the file name | Hub instruction to the #8157 Wave-2 commit, after the Stage-7 review of #8154 (comment 6668355579 on #8785) found the required check "Operator-memory-reference gate" failing on this file | A public plan may not name operator-local memory files; the principle carries the meaning without the name. The `allow-memory-ref` override is not used | APPLIED: the gate's own pattern finds 7 lines in this file at Commit 0 and 0 after this commit; a control line naming a memory-shaped file reads 1 (§ Verification Evidence) |
| DEV-26 | **PA-011 D-PreGateADRFix (A).** One Tier 1 wording commit on the founding ADR while it is `Proposed`: § 3 maps the delivery-engine lifecycle (15 stages in 5 phases) at stage grain, states that a phase spanning several spans maps per member stage, and writes `Build` object-typed where the two models meet (`Span-Build`, `Engine-Build`) (#8793 QA-01; Stage-7 F-02 on #8788); § 5 defines `platform-instance` by role and reads #8016's draft against the home-class table (Stage-7 F-01); F-11's attribute count and the in-place definitions of the Commit-0 writer, Step 0 and the engine decision | Stage 9 pre-GO Decision Recorded (comment 6670710105 on #8794), PA-011, CHEAP | Cheap while the ADR is `Proposed` and EXPENSIVE once built (the QA-01 weighted layer); it turns #8157 AC-2 from PARTIAL to MET | APPLIED in the ADR at `64615ed5`, whose checks are recorded in comment 6670835521 on #8793. The ADR stays `Proposed`; only the ratification moves it |
| DEV-27 | **PA-012 D-Stage8Acceptance, accepted as listed.** #8153, #8155 and #8156 ACCEPT; #8154 CONDITIONAL ACCEPT, with AC-3's three `not stated` lifecycle rows (Intake form, Business case, Resource Plan) accepted as-is; #8157 ACCEPT once PA-011 lands | Stage 9 pre-GO Decision Recorded, PA-012, CHEAP | The operator renders Stage 8's Phase E at the Stage 9 gate; PA-011 has landed (`64615ed5`) | APPLIED in § Change Description → Issues resolved. #8157 reads PARTIAL there until the ratification is recorded, per this plan's own status rule |
| DEV-28 | **PA-013 D-8156-QA (A) + (a).** The #8156 record states the binding rule that joins the Scrum and Kanban design cadences to their grid cells, so the founding ADR's "19 with a source-stated cadence" stays 19; the record's sunset is extended with a reason, and the record is named as slice S3's input | Stage 9 pre-GO Decision Recorded, PA-013, CHEAP | Option (A) keeps the evidence and moves no decision (#8793 QA-05); option (a) keeps the member-grain data alive for S3 | APPLIED in the git-ignored #8156 record, Revision 3, placed by the hub (comment 6670797979 on #8782). No tracked text changes: the ADR figure stays 19 |
| DEV-29 | **PA-014 D-DeliveryCutDeps.** Slice S7, the catalog integrity checks, is split from the second delivery milestone into a third, so the second milestone carries two external dependencies rather than three | Stage 9 pre-GO Decision Recorded, PA-014, CHEAP; Stage-7 F-03 on #8788 | The composition doctrine targets at most two external dependencies per milestone; S7 waits on the catalog generator | APPLIED in the ADR's § Delivery cut at `64615ed5`, and in § Change Description → Downstream impact at this commit |
| DEV-30 | **PA-015 D-OwnedFindingsFiling.** The 28 process-baseline findings this release's cards own (#8153 7, #8154 15, #8155 6) stay unfiled, owned by epic #8150's delivery cut. The 8 bug-tag candidates (#8154's seven ` · bug` rows plus F-032, under Stage-7 F-03's reading on #8785) are listed in the Stage-9 ledger. This replaces the "Stage 13 files them" clause of PA-008 (a) and DEV-15 | Stage 9 pre-GO Decision Recorded, PA-015, CHEAP | Every owned finding carries class `none` at its source, so all 28 sit below the filing threshold's class limb; their remedies are the delivery cut's work | APPLIED: the Stage-9 Phase A7.6 ledger on #8794 counts them below-threshold, and Stage 13 files none of them |
| DEV-31 | **PA-016, GO WITH CONDITIONS.** The release passes Stage 9 with four conditions, none needing a code change. C1: every required check passes on the final head before the merge. C2: the ratification head is re-read. C3: the draft-to-ready transition is made and read back. C4: the R7/R9 re-dispositions and the CIAC-2..CIAC-6 grade lines are recorded | Stage 9 Decision Recorded (comment 6671846290 on #8794), PA-016, EXPENSIVE | The readiness scan read ANY-PARTIAL: required checks queued, and package hygiene open. The content gates read MET | C2, C3 and C4 DISCHARGED (comment 6672012208 on #8794: CIAC-1 PASS and MATRIX-DELIVERED on the ratification head; R7 and R9 dispositioned; five CIAC grade lines MET; the PR ready, read back). C1 OPEN until Stage 12 reads every required check green |
| DEV-32 | **PA-017, ratified with amendments.** The founding ADR moves `Proposed` → `Accepted` and records what the ratification settled: point-in-time binds to Domain C, reopening the frozen Axis-2 set only on a shown need; the timeboxed and continuous design default is a labelled default; the vocabulary and the design's home stand as proposed; the risk-class home decision is re-checked, still `Proposed`, with every home nameable; and the node-delta lint is adopted on its supporting-grade premise | Stage 9 Decision Recorded, PA-017, EXPENSIVE; the ratification posted verbatim on #8157 (comment 6671846544) | The ADR left these clauses to the gate; settling them in its text makes the `Accepted` record self-contained | APPLIED in the ADR at `78db45aa`; the gap map, Consequences and Reversibility are reconciled to it |
| DEV-33 | **PA-018, #8150's body per RQ-1.** In the Out list's system-documentation bullet, #8110 (completed) is repointed to #8111 and #8114; the three Out bullets the widening touched stay | Stage 9 Decision Recorded, PA-018, CHEAP | #8110 closed as completed on 2026-10-25; the 2026-10-24 Scope note left the body to the ratification | APPLIED on #8150 by a one-line body edit, read back. It touches no tracked file; this row records it |
| DEV-34 | **Stage 12 Execute authorized.** This plan is brought current before the merge: #8157 reads DONE, the Status reads Stage 12, and PA-016 to PA-018 and the authorization are recorded | Stage 12 Decision Recorded (comment 6672132704 on #8797), D-Execute, IRREVERSIBLE | The plan is the record the merge lands; it states the ratified state rather than the pending one | APPLIED in this file. The merge itself waits on C1 |
| DEV-35 | **Stage 12 A.5.7c renumber, ADR-230 → ADR-232, and CIAC-1 widened to admit its one renumber-log line.** A sibling release's ADR-230 merged first. The renumber tool moved the record and its 5 citations, and its R4 step appended one line to the § Renumber log of `core/ADRs/README.md`. This adds a third File Change Matrix row; widens CIAC-1 to that line alone, with a second command that bounds it; and makes the Release-Level File Integrity line read three rows | `stage-12-execute.md` Phase A.5.7c (a Tier-1 mechanical remediation) and this plan's R9 row; recorded on #8797 (comment 6703123372) | ADR numbers bind at merge (ADR-115), so the collision could not surface before the sibling merged. R9 named both remedies: A.5.7 for a collided slot, and an FCM row with a CIAC-1 widening whenever the README changes. The widening lands after the merge, in the Stage-12 chore PR, because no pre-merge step runs the plan verifier and a fresh head would have re-queued every required check. Residual, stated: CIAC-1 read NOT MET as written on the merged release until this amendment | APPLIED in § File Change Matrix, § Cross-Issue Acceptance Criteria, § Release-Level Verification and § Verification Evidence. CIAC-1 grades MET on `b0763aac^1 b0763aac` under the amended method |

## Change Description

Authored at Engineering Commit 0 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, with what is true at this commit. The #8157 session refreshes it when the founding ADR lands, and it is read at Stage 9 Plan Review.

### Outcome

This release produces the evidence and the design for how each delivery stage records its work. Four discovery cards verify or produce the current-state records (what each release stage writes, what project delivery produces, a shared stage vocabulary, and how methodology changes cadence), and #8157 designs the stage-to-document model on them. The design is held in a founding ADR, `ADR-232`, that ships in this release `Accepted`. It was authored `Proposed` and ratified with amendments by the operator at Stage 9 (PA-017). In one line, the design: every stage's documents are declared once, in a new core standard that both the release pipeline and project delivery read; every pipeline stage, and every project phase or stage, belongs to one of eight delivery spans; a document's lifecycle class binds to the field its file already carries; homes are named by role; a delivery approach varies cadence through one member-grain section; and a change's process design is written as DRAFT catalog pages at Engineering Commit 0 and becomes current when its code is built.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #8153 | What each release stage writes, where it persists and who reads it, verified as a delta over the W1 record at head | DONE — Stage 8 ACCEPT, 5 of 5 criteria MET, accepted by the operator (PA-012) |
| #8154 | The project-delivery inventory, verified and refreshed, with the 2026-10-25 observations noted beside it | DONE — Stage 8 CONDITIONAL ACCEPT, 4 of 5 MET; AC-3 PARTIAL, its three `not stated` lifecycle rows accepted as-is by the operator (PA-012) |
| #8155 | The stage-vocabulary crosswalk, verified and refreshed | DONE — Stage 8 ACCEPT, 4 of 4 MET, accepted by the operator (PA-012) |
| #8156 | How each delivery approach changes when documents are written and how long they stay current | DONE — Stage 8 ACCEPT, 4 of 4 MET, accepted by the operator (PA-012); record Revision 3 per PA-013 |
| #8157 | The stage-to-document model design and the founding ADR, brought to ratification | DONE — Stage 8 ACCEPT once PA-011 landed (`64615ed5`), accepted by the operator (PA-012); ratified with amendments at the Stage 9 gate (PA-017), recorded on #8157; AC-6 is graded at Stage 13 from that record |

Each status follows the operator's Stage-8 acceptance, rendered at the Stage 9 pre-GO gate (PA-012). #8157's also follows the ratification (PA-017).

### Key decisions

- **D-8157-Scope (B):** the 2026-10-24 widening is a binding input, and #8157's body is decided at ratification.
- **D-VerifiedCards (A), raised by PA-009:** #8154 and #8155 stay in the release as verify-and-refresh, with Stage 7 restored.
- **D-Concurrency P1:** parallel compute, one commit lane.
- **D-DurableHome (B) + (C):** the design ships as a founding ADR in this release; the inventories feed the process-catalog pages.
- **D-Version:** version-less, re-confirmed after the ADR joined the release.
- **Stage 9 pre-GO, PA-011 to PA-015 ("Approve all five"):** the founding ADR's pre-GO wording commit (the delivery-engine map, `Span-Build` against `Engine-Build`, `platform-instance` by role); the Stage-8 verdicts accepted as listed; #8156's join rule stated, with the ADR's "19" kept and the record's sunset extended; slice S7 split to a third milestone; the 28 owned findings kept unfiled, owned by #8150's delivery cut.
- **Stage 9 GO and ratification, PA-016 to PA-018 ("Approve all three"):** GO WITH CONDITIONS; the founding ADR ratified with amendments and now `Accepted`; #8150's Out list repointed from #8110 to #8111 and #8114.
- **Stage 12, D-Execute ("Authorize Execute"):** the merge proceeds once every required check is green (C1).

### Reversibility

**CHEAP — HIGH confidence.** `git revert` of the release merge removes the plan and the ADR; the git-ignored records are unaffected, and no version tag is claimed.

### Downstream impact

- The ratified design is the build target for epic #8150's delivery milestones, cut by #8157. The proposed cut is three milestones (PA-014 split slice S7 out of the second): one declaration (the standard, the lifecycle-register entries, the methodology section, gap detection on spans, the template gap list); then the design living in the catalog (the node-delta block, the Stage-6 page writes, the Stage-7 designed-versus-built read); then the catalog keeping its integrity (the integrity checks, warn-mode first, which wait on the catalog generator). The second milestone therefore carries two external dependencies, the composition doctrine's target.
- The current-state inventories feed the #8115 process-catalog pages (PA-007 (C)).
- No skill, hook, deploy gate or Layer-2 surface changes.

### Cross-references

- Release plan: this file.
- Milestone: `stage-document-model-decision`.
- User-facing release note: `release/releases/notes/_unversioned/stage-document-model-decision_RELEASE_NOTES.md`, authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`.
