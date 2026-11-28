---
title: Release Plan — issue-body-is-the-scope-of-record (the issue body's contract sections are the scope of record; successor to ADR-062, in part)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.15, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: issue-body-is-the-scope-of-record
release_class: novel
reversibility: CHEAP / Confidence HIGH — one pull request; reverting it removes the successor record, the pointer on ADR-062 and every narrowing edit together, with no data migration. If the operator declines to ratify the successor at Stage 13 Phase A13, a follow-up change reverts the edits that cite it. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `issue-body-is-the-scope-of-record`

**Milestone:** `issue-body-is-the-scope-of-record`. One card, **#7970** — the ADR card for the scoped successor to ADR-062: an issue body's contract sections are the scope of record and are edited in place; its record sections are never rewritten. The Stage-4 planning sub-task **#9147** carries the approved plan (`#9147 comment 7230675373`) and the Stage-4 gate's Decision Recorded (`#9147 comment 7230841719`). The Stage-5 design is on **#9151**, revision 1 in two parts (`#9151 comment 7232246392`, part 1/2, and `#9151 comment 7232247542`, part 2/2); revision 1 supersedes the revision-0 design comment on that sub-task wherever they differ. The operator's Stage-5 design decisions are `#9151 comment 7231808357`. The Stage-6 Engineering sub-task is **#9152**; this file is Engineering Commit 0, authored by the spoke on #9152, which also builds slices S1–S5.

**Version identity:** **versioned** — bump-class **`minor`** (when-to-version row WV-1). The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header **Version** cell carries the double-brace release-version placeholder, which this file writes in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.15`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/issue-body-is-the-scope-of-record`, cut from `origin/main` at `8ed5e273`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial** — Commit 0, then S1 → S2 → S3 → S4 → S5 on the one branch. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9147 and is amended, in order, by: the Stage-4 gate's Decision Recorded (plan approved as amended — slice S6 removed, ratification moved to Stage 13 Close Phase A13; D-ReleaseClass `novel`; D-AC-Source (A); the Release Outcome Statement; four corrections to the File Change Matrix, the slice list and the evidence wording), then the Stage-5 design revision 1 on #9151 and the operator's four Stage-5 design decisions recorded there. Where the Stage-4 plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Sections marked *Stage-4 record* are transcribed as written at Stage 4 and are read through § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): the change set carries material edits to rules agents follow — stage-05 Phase A1.5, the bridge's Stage 5 substrate-drift chip pattern, the ticket spec's write permissions, the field lifecycle matrix and the release-process AC-Drift Handling Protocol — per the Bump-Class Selection Guide's row for a protocol text modification. The rule-computed next-free re-verified at Engineering Commit 0 is `v5.15`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub; Stage 6 Engineering spoke) |
| **Status** | Executing — Stage 6 Engineering: slices S0–S5 landed and self-verified; next, Stage 7 Dev Testing |
| **Branch** | `release/issue-body-is-the-scope-of-record` |
| **PR** | #9201, opened in **draft** at Stage 6 (transitioned to ready at the Stage 9 gate) |
| **Milestone** | `issue-body-is-the-scope-of-record` |
| **Baseline pin** | `origin/main` at `8ed5e273d301f80bb0e281222e06a22432090ebb` (the Stage-4 pin; the branch is cut from the same commit) |

### Domain Practice Provenance

domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: governance }

Determined at Stage 4 Phase A1.5 and carried unchanged through Stage 5 (§ 5.7, `domain_practice` carried unchanged). Rationale: every add and edit row is an internal governance, pipeline-spec or ADR artifact; the design depends on no external best practice.

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0: `origin/main` = `8ed5e273`; the highest version tag is `v5.14`; no `v5.15` tag exists on the remote.
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha 8ed5e273d301f80bb0e281222e06a22432090ebb --dry-run`): **`v5.15`**.
3. `v5.15` is not in the claimed set and equals the recomputed next-free: **PROCEED**. The tag arm binds. No in-flight `release/*` sibling exists on the remote (`git ls-remote --heads origin 'release/*'` returned 0 heads before this branch), and there are 0 open pull requests.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp issue-body-is-the-scope-of-record` — run after this file was written and before it was committed; the result is recorded in the Engineering Commit 0 message and in the #9152 output comment.

### Write-set currency since the Stage-4 pin

`origin/main` equals the Stage-4 pin `8ed5e273` at Commit 0, so the window `8ed5e273..origin/main` holds 0 commits and the nine existing files the release edits are byte-identical to the files Stage 4 and Stage 5 read. The two new files (the successor ADR and this plan) have no prior state.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | § Header → Domain Practice Provenance |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix (revision 1's 11-file matrix) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria (none — one card) |
| 4 | Verification Plan | § Verification Plan (revision 1's 33 rows) |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | § Header, the **Baseline pin** row (`8ed5e273`; § Write-set currency above) |

## Summary (30 seconds)

- **One card, one design deliverable.** #7970 (size M, adr template) produces the scoped successor to ADR-062 and the narrowing edits its Decision names. One branch, one pull request, six slices as commits in dependency order (S0–S5).
- **The write set is 11 files:** the successor ADR (new), this plan (new), and nine edits — ADR-062 (one `superseded_by:` frontmatter line), the core ADR index, the ticket information architecture spec, the field lifecycle matrix, stage-05 Phase A1.5, the bridge's Stage 5 substrate-drift chip pattern, the release-personas Stage 5 line, the failure-mode standard's intake-substrate-drift example, and the release-process AC-Drift Handling Protocol (QA-side subsections).
- **The Stage-4 CONDITIONAL rows do not fire.** The operator's A′ decision opens the matrix's acceptance-criteria cell at Planning (`U*`, two named triggers) to match the surfaces that refine criteria there, so it narrows none of them. `release/governance/release-process.md` joined the write set by operator decision at Stage 5.
- **Ratification is Stage 13 Close Phase A13's.** The successor merges `status: Proposed`; the `Proposed → Accepted` flip is rendered per record at Phase A13 and verified by Gate 13 row G-CL9. It is never inferred from milestone closure.
- **Verification: 33 rows** — 30 acceptance-criterion rows (AC-1 … AC-9 with sub-rows) and OBL-1–3 for the design-only criterion; 31 runnable, 2 declared-deferred (AC-2c to Stage 7, AC-9 to after the Stage 13 close-out).
- **Version:** versioned, bump-class `minor`; the rule-computed next-free at Commit 0 is `v5.15`.

## Phase A0 — Triage→Design Re-Review (*Stage-4 record*)

Transcribed as written at Stage 4. Two of its counts have since moved, by recorded decision: the write set is nine edited files plus the new record and this plan, and the CONDITIONAL rows it anticipates did not fire (§ Deviation Log, DEV-6). The open governing-table assumption it routes to Stage 5 was settled there (§ Operator Decisions — rendered).

**Header**

| Field | Value |
|---|---|
| `issue_number` | #7970 |
| `release_milestone` | `issue-body-is-the-scope-of-record` (slug-primary, pre-claim) |
| `stage` | 4 |
| `spoke_author` | Stage 4 Release Planning spoke (Release Manager — Release Planning persona) |
| `re_review_date` | 2026-11-27 |
| `issue_body_revision` | 2026-11-21T23:44:59Z (`updatedAt`, the milestoning write; the last body edit was 2026-11-14, per the owner comment) |
| `triage_decision_date` | 2026-10-25 (UTC timestamp of the `status: approved` label event, 2026-10-25T01:49:57Z; the decision is dated 2026-10-24 in the operator's local day) |
| `effort_tier` | **complex**. The label says size M, but the scope crosses ≥3 governance files (8 edited plus 1 new), so the tier is upgraded; § 7 makes upgrades autonomous. The Complex cross-issue section is below. Blast-radius re-validation against Solutioning A3 is deferred to Stage 5, because A3 has not run. |

`rows_source: re-derived (PT-1..4)` · G-PL5 **MISS**, reason: *no marker-bearing comment from the trusted author set exists*. Sub-task #9147 had 0 comments at read time. Operands recomputed for the record: `card_set_fingerprint` `d57b7318ea3aaff7798d3026bf2e7cc567e321a5b09af5f8f4d18251c8da15df` (card_set `7970:2026-11-21T23:44:59Z`) · `milestone_updated_at` `2026-11-27T23:40:11Z` · `milestone_description_sha256` `ba1ff8d901968ef531467daec082b6038d1990f3f92b937ac1d9f08e97e40808` · `main_head_sha` `8ed5e273d301f80bb0e281222e06a22432090ebb`.

**Per-requirement table**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| Decision rule 1 — Sections (the contract sections are edited in place; the record sections are never rewritten) | `decision-discipline.md` § 2.1 Mechanism 1 (Localization Check): the rule must localize to every surface it binds. Here that means every intake template, not one. | `.github/ISSUE_TEMPLATE/*.yml` at `8ed5e273`. Only `improvement.yml` carries all six section names the rule uses. `adr.yml` has Status / Context / Decision Drivers / Considered Options / Decision / Consequences / Related Issues. `story.yml` has Value / Acceptance Criteria / Story points / Parent epic. `bug.yml` has Reproduction Steps / Expected / Actual / Environment / Evidence / Affected Files / Acceptance Criteria. `epic.yml` has Outcome / Scope. `observation.yml` has What is missing / What does good look like. | #7970 is itself an adr card. Its 2026-11-14 ruling edited Context, Considered Options, Decision and Consequences in place, and the rule's vocabulary names none of those sections. ADR-210's source observations show that a heading vocabulary decides what a reader reads: 1,451 bodies carried one heading form and 148 another. | **C2** | Delta (Tier 1 [ADJUST], carried in the plan, not in the body): the successor states the contract-versus-record cut for every intake template's section set, or gives a rule that classifies any section by what it holds (what the card asks for, or what was observed at intake). It must not name only `improvement.yml`'s headings. Owner: Stage 5. |
| Decision rule 2 — Writers, and the card's open `[ASSUMPTION – CONFIRM]` on the governing table | `duplicate-source-discipline.md` (register-or-remove): two tables stating one permission must have one authority. | `ticket-information-architecture.md` § Agent Write Permissions declares the matrix authoritative and its own alignment "one-directional", yet it still diverges from the matrix. **(a)** Evidence at Triage: the table says U (one counted-observation line), the matrix says R. **(b)** Evidence at Close: the table says "add one evidence line", the matrix says L. **(c)** AC at Planning: the table **agrees** with the matrix (no AC at Stage 4). The openers are elsewhere: `stage-04-planning.md` § 5 A0.5 ("AC refinement via `gh issue edit --body`", Tier 1 [ADJUST]), `stage-08-qa-testing.md` § 4 Criterion namespace (`issue` list "amended at Stage 4") and `triage-design-rereview.md` § 3 C2 routing ("commit the refinement to the issue body"). **(d)** The ticket spec's § Body Update Protocol has the row "Stage 8 drift → revised AC in body", while the matrix has AC = L at 8-QA. **(e)** The matrix has Priority U\* at 7-DT and 8-QA, while rule 2 lists "anything after Stage 5" as outside the opened stages. | #7953 R1 test: "`ticket-information-architecture.md`, the ADR-062 successor and `CLAUDE.md` agree". | **C2** | The assumption is still live; **this re-review does not resolve it**, and it routes to Stage 5. Delta: the card frames it as matrix-versus-table on two fields. The evidence set is the five disagreements (a)–(e) above. Depending on the answer, up to three CONDITIONAL rows fire (stage-04 A0.5, stage-08 § 4, re-review § 3). |
| Decision rule 3 — Citations (file plus section name, no line number; commit-pinned evidence stays as written) | `reference-durability-standard.md`: summarize, and cite the durable form. | The card's own Context cites "ADR-062 line 24". The durable form of that citation is ADR-062 § Status, the succession clause. | Audit-baseline discipline (charter § Universal Preferences): a pinned SHA is a measurement, not a moving reference. That is consistent with "commit-pinned evidence stays". | **C1** | Hygiene note for Stage 5/6: the successor cites ADR-062 by § Status, never by line. |
| Decision rule 4 — Operator rulings (the section is rewritten in place, with one short comment) | `external-seam-conduct.md`: state goes to the record; a comment carries an ask or an answer. | The ticket spec § Body Update Protocol row "AC updated + comment explaining why" already seeds this rule. ADR-211 (Accepted) relies on that row. | #7970's 2026-11-14 revision is a worked instance: the body was edited in place, with one comment giving the date, what changed and why. | **C1** | — |
| The bound-surface list (8 edited files plus 1 new record) | `rename-reference-cascade.md` § 2: every site that restates the rule changes in the same change. | Probe P-1, at `8ed5e273`: exactly six normative files restate the body-wide no-rewrite rule. They are ADR-062 (Decision item 2, Option B), the `core/ADRs/README.md` ADR-062 entry, `stage-05-solutioning.md` A1.5, the bridge's Procedure 3 Stage 5 Chip Pattern M1.1, the `release-personas.md` Stage 5 line, and the `failure-mode-standard.md` intake-substrate-drift example. All six are on the card's list. | The 2026-11-14 finding ("four more files than this card listed", read at `29c60404`) reproduces exactly: the four are the bridge, the personas spec, the failure-mode example and the index. The set is unchanged across `29c60404` → `7813457d` → `8ed5e273`. | **C1** | — |
| ADR-062 supersession mechanics (stays Accepted; gains `superseded_by`; status value and body unedited) | `adr-authoring-guide.md` § Supersession + immutability: a partly superseded record keeps `status: Accepted`. Adding a `superseded_by:` pointer is permitted hygiene. | ADR-062 carries no `superseded_by:` today (0; control: 21 ADRs carry one). No ADR carries a `supersedes:` line naming 062 (0; control: 68 `supersedes:` lines exist). | The authoring guide's T-ADR-3 row cites ADR-046 superseding ADR-012's location clause in part, which is the same shape. | **C1** | — |
| R3 — the standing why-comment rule, "placed with R1" | ADR-094 (extend before create). | Probe P-4: R3's only current statement is the ticket spec § Body Update Protocol row "AC updated + comment explaining why". It covers AC only, and only the stage-finding trigger. No other surface states it. | ADR-211 cites that row as the carrier of "a stage finding which changes requirements updates the criteria with a comment explaining why". | **C2** | Delta: R3 lands as a generalization of that existing row (scope, AC or fix direction changed → one why-comment; hygiene and citation fixes need none), and the successor states the rule. No new file. Owner: Stage 5. |
| The done-definition is gradable ("successor merged Accepted + the named edits") | AC-Binding Limb 1 (`stage-04-planning.md` § 6): a verification row binds to an issue-body ordinal. | `check-ac-binding.py --fetch` reads #7970 as `NOT-EVALUATED … (no-criteria-section)`; control #6170 reads 6 criteria. `adr.yml` has no Acceptance Criteria field. `stage-08-qa-testing.md` § 4: the issue body is the namespace of record for `AC-` ordinals. | ADR-210's source observations: a criterion graded under the wrong list was reported upward as a different criterion. | **C2** | Operator decision **D-AC-Source** (below). This is not a G-PL2 FAIL: the Gate 1 substantive checks apply to the `improvement | bug | observation` templates, and adr is not one of them. |

**PT interrogation (no C3).**
- **PT-1 (stale assumption): none.** The write set has a 0-line diff `7813457d..8ed5e273`. ADR-062 was last changed before the card was filed. The 148 commits since bundling include two that touched `core/ADRs/`, and neither touched a file this card names.
- **PT-2 (subsumption): none.** ADR-210 (Accepted 2026-09-26) makes the body the list of record for AC ordinals only, not for scope or dependencies; the successor extends it. There are 0 open PRs, and an open-issue search for ADR-062 returns only #7970, #7953 and #6170. No C3/PT-2 row exists, so the § 3.1 freshness-check sub-step was not triggered.
- **PT-3 (best-practice conflict): none.** Supersede-not-edit is honoured by the pointer form.
- **PT-4 (learnings contradiction): none.**

**Complex-tier cross-issue cross-reference.** #6170 (milestone `stage-assertions-reconcile`, not running) is natively blocked by #7970; it amends its criteria in place after this lands and also edits `stage-05-solutioning.md`. #7953 is the parent epic; its sub-issues are #7970, #7920 and #7958, and the last two are unmilestoned and both edit the bridge. #7680 (unmilestoned) is the AC-replacement slice that consumes rule 1.

**Phase A0 gates**

| Step | Verdict | Evidence |
|---|---|---|
| Ticket-architecture reconciliation | PASS | The card was filed 2026-09-27. ADR-062 dates from 2026-07-01 and is unchanged. ADR-210 (2026-09-26) is Accepted. The authoring guide's partial-supersession policy is already applied in the 2026-11-14 revision. The only stale form is the line-number citation (rule 3 row). |
| Architecture evaluative lens (advisory) | advisory | Placement: `core/ADRs/`. The decision crosses modules (the field matrix is in `core/schemas/`, the ticket spec in `release/`), and ADR-062 lives in core. Stage 5 confirms. |
| A0.5 / G-PL1 reference currency | PASS | The card has no AC. Its Context claims were re-read at `8ed5e273`: the ticket spec cites ADR-062 0 times (control: "source of truth", 13 in the same file); stage-05 cites it once; ADR-062 § Status carries the succession clause; Decision item 2 is present. |
| A0.6 / G-PL2 body crisping | N/A, with reason | The Gate 1 substantive checks apply to `improvement | bug | observation` cards, and #7970 is an adr card. Gradability goes to D-AC-Source. |
| A0.7 / G-PL3 placement forward-check | SKIP on the release-base window; PASS on the bundling window | `8ed5e273..origin/main` is 0 commits. `7813457d..origin/main` has 396 name-status rows: 1 directory-crossing rename (a release plan's claim-time move into `plans/v5/`) and 0 delete rows in scope. No new file is placed at an eliminated path. |
| A0.8 / G-PL4 empirical repro | **admit-still-valid** | Drift-class by predicate (i): the body matches `reconcil` ("neither reconciled"), so the check is mandatory. The card has no AC commands, so its own Context claims are the runnable checks. The headline defect, that the corpus disagrees about who owns a body, still reproduces: the ticket spec § Source of Truth says "updated in-place", while ADR-062 Decision item 2 says the body remains historical record. |
| Parallelization-Map currency | **FINDING → Tier 1 [ADJUST]** | The milestone description carries only the `### Composition Lock` block. Controls on the same instrument: 13 of 53 open milestones carry a map, and 34 of 53 carry a `Release-identity mode:` line. Text is proposed under Recommendations. |
| Sibling-merge stale-pin trigger | empty | X = `8ed5e273` = `origin/main`. |
| Currency-decision confidence gate | CONVERGENT → **amend** (description only) | Membership is unchanged. A0.5, A0.8 and the 0-line write-set diff agree that there is no composition delta. The A7 amend path stays operator-routed at its existing authorization. |

## Dependency Graph (*Stage-4 record*)

```
#7970 ──blocks (native)──▶ #6170   (stage-assertions-reconcile; not running; merges after this release)
#7970 ◀──blocked_by── (none)
#7953 (epic) ─ sub-issues ─▶ #7970 · #7920 · #7958   (#7920 / #7958 unmilestoned)
#7970 ──soft (rule consumer)──▶ #7680 (unmilestoned)   and every R2 child of #7953
```

In-bundle edges: 0 (single member). Probe: `dependencies/blocked_by` on #7970 returned `[]`; the same call on #6170 returned `[#7970]` (control, non-zero). Circular chains: none (enumerated over 1 member plus 4 edge endpoints).

## Implementation Sequence

Slices are commits on `release/issue-body-is-the-scope-of-record`, in this order (Stage-5 revision 1, § Output for Stage 6). Prose in every later slice cites the successor by its slug token, `{{ADR:issue-body-contract-sections-are-the-scope-of-record}}`; a link target uses the record's real path, so a token never sits inside a link target. The number is taken from `release/tools/renumber-adr.py --detect` immediately before the file is created (provisionally 242) and binds at merge.

| Slice | Content | Design edits | Depends on |
|---|---|---|---|
| **S0** | Engineering Commit 0: this plan file, carrying the Commit-0 Survival Set. The version re-verify and `claim-version.sh --verify-stamp issue-body-is-the-scope-of-record` run before the commit. | — | the Stage-4 and Stage-5 gates |
| **S1** | The successor ADR, `core/ADRs/ADR-NNN-issue-body-contract-sections-are-the-scope-of-record.md`, `status: Proposed`, with `supersedes: ADR-062 in-part (Decision item 2)` and rules 1–4, the why-comment rule, the ADR-062 standing clause and the ratification-keyed cutover. | E0 | S0 |
| **S2** | ADR-062: the single `superseded_by:` frontmatter line (status and body untouched). `core/ADRs/README.md`: the pointer line on the ADR-062 entry and the successor's entry. | E1, E2 | S1 |
| **S3** | The authority pair: `release/references/specs/ticket-information-architecture.md` (cites the successor; the contract/record classification; the Body Update Protocol rows and the why-comment rule; the Agent Write Permissions Body Updates cells as pointers to their matrix columns) and `core/schemas/field-lifecycle-matrix.md` (the governing-table sentence; the locked-cell path; the AC `U*` cell at Planning and its footnote; the section-classes paragraph and the Tier-A artifact). | E3, E4 | S1 |
| **S4** | The narrowing edits: stage-05 Phase A1.5, the bridge's Procedure 3 Stage 5 substrate-drift chip pattern (M1.1 only), the release-personas Stage 5 line, and the failure-mode standard's intake-substrate-drift example (inside the fence only). | E5, E6, E7, E8 | S1 |
| **S5** | `release/governance/release-process.md` § AC-Drift Handling Protocol, the QA-side subsections only: the post-Stage-8 criteria refinement is written into the issue body only to carry out the operator's recorded decision on the flag. | E9 | S1 |

Removed from the Stage-4 sequence: the Stage-4 S5 (CONDITIONAL rows; none fire under A′) and S6 (ratification; it is Stage 13 Close Phase A13's). See § Deviation Log.

### Sub-task decomposition (Stage 6 Phase A2)

The decomposition is the slice set above. The A2 container predicate reads six slices over 11 files with a cross-file change, which selects the GitHub sub-issue container; the slices are instead tracked as the release pull request's checklist rows, beside the three special rows (sync, plan update, verification). The choice and its reason are recorded in the #9152 output comment for the hub.

## File Change Matrix

```
# ── always-applies ──
core/ADRs/ADR-NNN-issue-body-contract-sections-are-the-scope-of-record.md   add    # number from release/tools/renumber-adr.py --detect at create time (provisional 242)
core/ADRs/README.md                                                         edit   # E2
core/ADRs/ADR-062-substrate-vs-canonical-precedent.md                       edit   # E1: frontmatter superseded_by only
release/references/specs/ticket-information-architecture.md                 edit   # E3
core/schemas/field-lifecycle-matrix.md                                      edit   # E4
release/references/pipeline/stage-05-solutioning.md                         edit   # E5
release/references/how-to/hub-spoke-bridge.md                               edit   # E6: Procedure 3, M1.1 only
release/references/specs/release-personas.md                                edit   # E7
core/standards/failure-mode-standard.md                                     edit   # E8: inside the fenced example only
release/governance/release-process.md                                       edit   # E9: § AC-Drift Handling Protocol, QA-side only (operator decision at Stage 5)
release/releases/plans/issue-body-is-the-scope-of-record_RELEASE_PLAN.md    add    # Commit 0
```

The three rows declared at Stage 4 under `governing-table-narrows-openers` — `stage-04-planning.md`, `stage-08-qa-testing.md` and `triage-design-rereview.md` — **do not fire**. A′ opens the matrix cell to match the openers and narrows none of them (Part 1, D-AC4), so the rows are removed from the matrix rather than carried as CONDITIONAL.

**Read-only inputs** (READ, not edited): `core/standards/adr-authoring-guide.md`, `core/schemas/adr-schema.md`, `release/ADRs/ADR-210-acceptance-verdicts-name-their-criterion-namespace.md`, `core/ADRs/ADR-211-design-axes-and-cut-patterns-key-on-work-nature.md`, `release/references/pipeline/stage-02-triage.md` (§ 4 directional-not-authoritative handoff; § Observation counting), `release/references/pipeline/stage-01-intake.md` § 6, `release/references/pipeline/stage-13-close.md` § Phase A13, `core/CLAUDE.md.template` pre-creation check, `.github/ISSUE_TEMPLATE/*.yml` — READ.

**Release-wide explicit non-scope** (NOT EDITED): the held stale-citation edits and #6170's corrected criteria (operator-authorized backlog work under the umbrella #7953); every R2 producer change, including the charter pre-creation check (separate children of #7953); the ADRs that applied ADR-062's no-rewrite limb (Accepted records are immutable; one is still `Proposed` in its own release); the five surfaces held as follow-up candidates (§ Held follow-up candidates); `CHANGELOG.md` and the release-tracking corpus — NOT EDITED.

**Placement and coupling.** No write-set file is a `TEMPLATE_SYNC_MAP` source and none is a mirror-pair member, so the matrix carries no package-rebuild rows and Check 9 is untouched. No process-catalog page lists a write-set file under `depicts`. `release/governance/release-process.md` is not a mirror-pair member, not packaged, not catalog-depicted, and carries the `allow-version-ref` and `allow-link` markers (Stage-5 revision 1, Blast Radius). Domain: § Header → Domain Practice Provenance.

### Agent-Editability Read

**Derivation** — controls read at commit `8ed5e273`:
- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh`, every `case "$ABS_TARGET"` block whose arms call `always_block "BLOCK-AUTONOMY-001"`. **2 blocks observed** at Stage 4.
  - Block 1 (anchored), arms verbatim: `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`.
  - Block 2 (membership), arm verbatim: `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`.
  - Tested against the tracked index at `8ed5e273`. Surviving tracked targets: `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md`, `release/governance/RELEASE_PROTOCOL.md`. The CLAUDE.md arms and the `.claude/` arms track nothing (0 tracked `.claude/` paths).
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh`. `SKILL_SCOPE_RE` = `'(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$'`. Arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`. Exemption list: not consulted, because conjunct 1 is false for every write-set path, which decides every row. Control: `release/skills/release-hub/SKILL.md` matches the regex (1).

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #7970 | each of the ten add/edit paths declared at Stage 4 that remain in the matrix (the three Stage-4 CONDITIONAL paths did not fire and are removed) | 0 (no OPERATIONS.md / RELEASE_PROTOCOL.md / CLAUDE.md basename) | 0 (conjunct 1 false: no `<module>/skills/` path) | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #7970 | `release/governance/release-process.md` (added by operator decision at Stage 5) | 0 (no CLAUDE.md / OPERATIONS.md / RELEASE_PROTOCOL.md basename; `core/hooks/block-autonomy-ceiling.sh` names `release-process` 0 times, control `RELEASE_PROTOCOL` 6 times, re-read at Commit 0) | 0 (not a `<module>/skills/` path) | `unconstrained` | `unconstrained` | ordinary Engineering spoke |

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9 Plan Review | 10–11 | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|
| #7970 | **RUN** (done: revision 1 on #9151) | **RUN** | **RUN**: the ADR durability lint (R4, R5 and R6 with `--diff-base origin/main`), ADR-number integrity, `check-doc-links.py`, `check-release-links.py --check-anchors` in the real tree, the reference-durability and repo-integrity gates on the changed files, the `deploy.sh --check` delta (Check 63), the plan verifier, and AC-2c | **RUN**: per-criterion verdicts in the `issue` namespace (D-AC-Source (A)); the design-only criterion graded through OBL-1–3 | **RUN** (Deep) | compressed (git-native) | **RUN** | **RUN**, including Phase A13 ratification of the successor (G-CL9 reads its `status:` on main) |

## Contention Map

**Write set:** the 11 rows of § File Change Matrix.

| Counterparty | Its write set (from card bodies and comments, Stage 4) | ∩ this release | overlap_class | Disposition |
|---|---|---|---|---|
| ms455 `fs-boundary-judges-every-listed-verb-operand` | the fs-boundary hook, its awk library (conditional), its suite and readiness fragment, `core/rules/bypass-mode-readiness.md` (generated) | ∅ | — | Independent. Version-slot and ADR-slot edges only. |
| ms435 `rollups-select-projects-by-portfolio` | five operations skill files, the portfolio composer, the portfolio write-back contract; its comments add the project entity model, the entity field schemas and `core/deploy/deploy.sh` | ∅ | — | Independent. Version-slot edge only. |
| ms449 `worktree-sessions-reach-in-repo-homes` | `core/rules/git-workflow.md`, the autonomy-ceiling hook and its library and suites, the analysis workspace standard and resolver, `release/references/how-to/hub-spoke-bridge.md` (conditional: spoke output handling), the hub session continuity standard | `hub-spoke-bridge.md` (conditional) | different regions: this release edits only Procedure 3's Stage 5 Chip Pattern — Substrate-Drift Reconciliation (M1.1) | This release merges first; ms449 rebases. LOW. |
| ms398 `stage-assertions-reconcile`, not running | `stage-05-solutioning.md`, `stage-08-qa-testing.md`, the intake style guide | `stage-05-solutioning.md` (the stage-08 overlap fell away with the CONDITIONAL rows) | not computable (no branch) | Natively sequenced after this release; it rebases. |
| Unmilestoned epic siblings under #7953 | bridge Procedure 1 / Procedure 2; the release-hub playbook and its package | `hub-spoke-bridge.md` (different procedures) | — | Not in flight. Informational. |
| Open pull requests | — | — | — | **0 open pull requests** at Commit 0 (`origin/main` = `8ed5e273`). |

### In-Flight Release Roster

**Measured at:** `8ed5e273` · `2026-11-27T23:46:53Z` (Stage 4), re-measured at Commit 0 on the same commit · **Population:** n=0 sibling(s) — open pull requests with a `release/*` head, plus remote `release/*` heads with no pull request. The zero is not a statement of no contention: three sibling hubs run local-only (unpushed) and are invisible to this population until they push; Stage 9 Phase A6.6 re-measures them.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| none in flight at `8ed5e273` / 2026-11-28 (Commit 0) | — | — | — | — | — | — |

## Risk Register

| # | Risk | Class | Severity | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | The governing-table answer widens the write set. | scope | **resolved at Stage 5** | A′ opens the matrix cell to match the Planning-stage openers and narrows none, so no CONDITIONAL row fires. The write set gained `release/governance/release-process.md` by operator decision; the class stays `novel` (1 pipeline stage file; 2 of the 6 rule-defining surfaces). Any further row is a Tier 2 [SCOPE CHANGE]. | Stage 5 → operator |
| R2 | No criteria to grade. | verification | **resolved at Stage 4** | D-AC-Source (A): the card's body gained an Acceptance Criteria section (nine criteria) as the operator's recorded decision; Stage 8 grades them. | operator |
| R3 | Partial supersession recorded as a status flip on ADR-062, which would move it into the frozen state and drop it from the durability lint's population. | rollback / correctness | MEDIUM | S2 touches one frontmatter line only. AC-2a reads `status: Accepted` beside the pointer (expect 2; a status-flip mutant reads 1), AC-2b reads the line count, and Stage 7 reads the AC-2c numstat. | Stage 6/7 |
| R4 | Ratification lands late or is inferred. | process | LOW–MEDIUM | Ratification is rendered per record at Stage 13 Close Phase A13 and verified by G-CL9 reading the successor's `status:` on main; AC-9 is graded after the close-out. It is never inferred from milestone closure. | hub / Stage 13 |
| R5 | ADR slot and index contention. Slot 242 is provisional, and any sibling whose design authors an ADR also appends to `core/ADRs/README.md`. | contention | LOW | `renumber-adr.py` at merge. Prose cites the successor by slug token. The index entry is an append-pattern edit. | Stage 6 / 12 |
| R6 | Bridge contention with ms449 (conditional). | contention | LOW | Different procedures; this release edits M1.1 only and merges first. | ms449 hub |
| R7 | A reflexive loop: the successor changes who may write card bodies while this release's own stages run. | process | LOW | The cutover is keyed on ratification: this release runs every stage under ADR-062, its own Stage 13 included, and no agent edits a card body except to carry out an operator-recorded decision. | Stage 5 (designed) |
| R8 | Check 63 (count-vs-structure): `failure-mode-standard.md` and `release-process.md` each carry a baselined count preamble. An edit that touches a preamble re-keys it and FAILs. | gate | LOW | E8 stays inside the fenced intake-substrate-drift example and E9 inside the QA-side subsections, far from both preambles; Stage 7 runs `deploy.sh --check` and reads the Check 63 lines (Stage 5 simulation: `KNOWN=1 FAIL=0` on both). | Stage 6/7 |
| R9 | Public surface: the new ADR carries issue references and a `deciders:` line. | gate | LOW | References sit in the `## References` block, each with a summary; `deciders:` names roles, never a handle. The repo-integrity gates run at pull-request time. | Stage 6 |
| R10 | Downstream wait: #6170 waits on this merge. | dependency | LOW | Natively encoded. Surface the cost at once if this release slips. | hub |
| R11 | Usage window: four hubs draw on one account's window concurrently. | capacity | MEDIUM | Checkpoint B at every launch; this release launches singletons only. | hub |

## Release Class declaration

**Class: `novel`** (operator-rendered at the Stage-4 gate, D-ReleaseClass). Fired triggers: (b) the plan carries D-class decisions (D-AC-Source; the Stage-5 governing-table decisions) and (c) a Stage-5 ADR is the deliverable. Not fired: cross-cutting (a) — 1 of the ≥3 `pipeline/stage-*.md` files (`stage-05-solutioning.md`); (b) — 2 of the 6 rule-defining surfaces (`hub-spoke-bridge.md`, `release-process.md`); (c) — 0 in-bundle edges. Routine is excluded by (c), which allows no new files. Posture: engagement **Standard** · Stage 9 depth **Deep** · Stage 5 bias **ALL** · Stage 13 outcome window **30-day**.

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-28 UTC; `#9147 comment 7230841719`)

| Decision | Operator's choice | Reversibility · confidence |
|---|---|---|
| Plan approval | Approve as amended. Slice S6 is removed: the successor merges as `Proposed`, and the `Proposed → Accepted` flip happens at Stage 13 Close Phase A13, authorized per record and verified by G-CL9. The File Change Matrix corrections are carried into this file at Engineering Commit 0. | MODERATE · HIGH |
| D-ReleaseClass | `novel` — Standard engagement · Stage 9 Deep · Stage 5 bias ALL · Stage 13 outcome window 30-day | CHEAP · HIGH |
| D-AC-Source | (A) — an Acceptance Criteria section is added to the card's body as this recorded decision, with one short why-comment; Stage 8 grades those criteria. Criterion 9 reads "after the Stage 13 close-out", matching the ratification timing. | CHEAP · HIGH |
| Release Outcome Statement | Approve the draft; written to the milestone description as the canonical Release Outcome Statement block | CHEAP · HIGH |

**Recorded determinations (rule-computed, not gated):** D-Version — versioned (WV-1), bump-class `minor`, provisional `v5.15`, re-verified at Commit 0 (§ Commit-0 Version Re-Verify Record). ADR number — provisional next-free `242` (`renumber-adr.py --detect`, anchor 241); Stage 6 takes it at create time. D-C Branch Topology — SINGLE. D-Concurrency — P0 fully serial (one card).

### Stage 5 design decisions (operator, 2026-11-28 UTC; `#9151 comment 7231808357`)

| Decision | Operator's choice | Reversibility · confidence |
|---|---|---|
| D-GT — what the field lifecycle matrix governs | G1, limited to body fields. The successor governs body-field writes only and says nothing about labels or Projects fields, which keep their standing (the matrix's State Anchor section and the ticket spec, unchanged in their authority). | CHEAP · HIGH |
| D-AC4 — acceptance criteria at Planning | A′. The matrix's AC cell at `4-Plan` becomes `U*`, with one footnote naming its two triggers: an A0.5 currency mismatch recorded in the deviation log, and a C2 refinement routed by the triage-design re-review. Any other criteria change at Planning carries out a decision the operator has recorded. | CHEAP · HIGH |
| Add-beside writers | An added line is an edit like any other: allowed at the steps that add one today (the Stage 2 counted-observation line, the Stage 13 folded follow-up line), or to carry out a decision the operator has recorded. | CHEAP · MEDIUM |
| `release-process.md` § AC-Drift Handling | (A) Fixed in this release. The section's post-Stage-8 default is brought into line with the writers rule; the write set gains this one file; the class stays `novel`. | CHEAP · HIGH |

**Stage-5 Minor design choices for the operator to see at Stage 9** (revision 1, part 1/2, Decisions & Recommendations items 1–7; none reopens an operator decision): the Body Updates cells become pointers to their matrix columns; the cutover is keyed on ratification, with a decline at A13 routing a revert of the citing edits; Risks & Cross-Cutting Impact is classed as contract; an O cell on a record field marks optional presence and opens no addition; the rowless single-value fields follow named rows, with the Title row as the fallback; rule 3's citation-fix reading; and the Tier 1 [ADJUST] name kept for the post-Stage-8 criteria refinement.

## Delivery Strategy · Rollback Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential, in slice order S0 → S5 |
| **Commit strategy** | One signed commit per slice, each pushed as it lands, plus plan-update commits on this file |
| **Review approach** | One pull request, `release(issue-body-is-the-scope-of-record): …`, opened in draft at Stage 6 and transitioned to ready at the Stage 9 gate. Its Issue References block carries the closing keyword for #7970; nothing else in its title, body or commit messages pairs a close-family verb with a number. |
| **Deployment mechanism** | Git merge only — no skill copy, no mirror pair, no harness artifact (§ Operational Deployment Manifest) |
| **Merge order** | ms455 → this release → ms435 → ms449; ms398 follows this release |

**Rollback:** Revert the release PR (CHEAP). If the operator declines to ratify the successor at Stage 13 Phase A13, the decline is recorded there, the record stays `Proposed` and binds nothing, and a follow-up change reverts the edits that cite it.

## Verification Plan

### Per-Issue Verification

`ac_baseline: { #7970: 9, read_at: 8ed5e273d301f80bb0e281222e06a22432090ebb }`. The criteria were added by the operator-recorded D-AC-Source decision, and Commit 0 re-reads them. Each row runs one command in the verifier's allowlist; each clause of a criterion is its own row. OBL-1–3 verify the design-only criterion `design #7970 AC-10` (E9, `Maps-to: none`), which Stage 7 grades against this design.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7970 | AC-1 | `grep -r -l -F "supersedes: ADR-062 in-part (Decision item 2)" core/ADRs` at least 1 | 1 file: the successor's frontmatter (0 at baseline) |
| #7970 | AC-1a | `grep -r -h -F -e "**1. Sections" -e "**2. Writers" -e "**3. Citations" -e "**4. Operator rulings" core/ADRs` at least 4 | the section, writer, citation and ruling rules, one heading each (0 at baseline) |
| #7970 | AC-1b | `grep -r -l -F "**The why-comment rule.**" core/ADRs` at least 1 | 1 file (0 at baseline) |
| #7970 | AC-2 | `grep -c -F "superseded_by: ADR-" core/ADRs/ADR-062-substrate-vs-canonical-precedent.md` expect 1 | 1: the pointer to the successor (0 at baseline) |
| #7970 | AC-2a | `grep -c -x -E -e "status: Accepted" -e "superseded_by: ADR-[0-9]+ in-part .*" core/ADRs/ADR-062-substrate-vs-canonical-precedent.md` expect 2 | 2: the status still reads Accepted beside the pointer (1 at baseline; a delivery that flips the status reads 1) |
| #7970 | AC-2b | `wc -l core/ADRs/ADR-062-substrate-vs-canonical-precedent.md` expect 86 | 86: exactly one line added (85 at baseline) |
| #7970 | AC-2c | declared, verification deferred to Stage 7 DevTest — read of `git diff --numstat origin/main -- core/ADRs/ADR-062-substrate-vs-canonical-precedent.md` | `1 0`: one line added, none removed or changed |
| #7970 | AC-3 | `grep -r -l -F "the field lifecycle matrix is the governing table for body fields" core/ADRs` at least 1 | 1 file: the successor names the governing table (0 at baseline) |
| #7970 | AC-3a | `grep -c -F "Matrix column " release/references/specs/ticket-information-architecture.md` expect 11 | 11: every stage row's Body Updates cell points at its matrix column (0 at baseline) |
| #7970 | AC-3b | `grep -c -F "Proposed Change (R/U), AC (R/U)" release/references/specs/ticket-information-architecture.md` expect 0 | 0: no hand-written field list is left to disagree (1 at baseline) |
| #7970 | AC-3c | `grep -c -F "one-directional" release/references/specs/ticket-information-architecture.md` expect 0 | 0: the old alignment sentence is gone (1 at baseline) |
| #7970 | AC-3d | `grep -c -F "is the governing table for which stage may write each body field" core/schemas/field-lifecycle-matrix.md` at least 1 | ≥1: the matrix states the same authority (0 at baseline) |
| #7970 | AC-3e | `grep -c -F "Updated only on one of two triggers" core/schemas/field-lifecycle-matrix.md` expect 1 | 1: the AC cell at Planning reads U* with its footnote (0 at baseline) |
| #7970 | AC-4 | `grep -c -F "a hygiene or citation fix gets none" release/references/specs/ticket-information-architecture.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-4a | `grep -c -F "changes scope, acceptance criteria or fix direction gets one short comment" release/references/specs/ticket-information-architecture.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-4b | `grep -c -F "issue-body-contract-sections-are-the-scope-of-record" release/references/specs/ticket-information-architecture.md` at least 1 | ≥1: the spec cites the successor (0 at baseline) |
| #7970 | AC-5 | `grep -c -F "the path for changing a locked field" core/schemas/field-lifecycle-matrix.md` at least 1 | ≥1: the L cell names the path for changing a locked field (0 at baseline) |
| #7970 | AC-6 | `grep -c -F "substrate-citation translation never edits the issue body" release/references/pipeline/stage-05-solutioning.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-6a | `grep -c -F "issue body remains historical record" release/references/pipeline/stage-05-solutioning.md` expect 0 | 0 (1 at baseline) |
| #7970 | AC-7 | `grep -c -F "the body is edited only to carry out the decision the operator records" release/references/how-to/hub-spoke-bridge.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-7a | `grep -c -F "NEVER auto-amend the issue body" release/references/how-to/hub-spoke-bridge.md` expect 0 | 0 (1 at baseline) |
| #7970 | AC-7b | `grep -c -F "historical-record" release/references/how-to/hub-spoke-bridge.md` expect 0 | 0 (2 at baseline) |
| #7970 | AC-7c | `grep -c -F "leaves the body's record sections as written" release/references/specs/release-personas.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-7d | `grep -c -F "leaving the body as historical-record" release/references/specs/release-personas.md` expect 0 | 0 (1 at baseline) |
| #7970 | AC-7e | `grep -c -F "a point-in-time observation of a platform fact" core/standards/failure-mode-standard.md` at least 1 | ≥1 (0 at baseline) |
| #7970 | AC-7f | `grep -c -F "historical-record" core/standards/failure-mode-standard.md` expect 0 | 0 (3 at baseline) |
| #7970 | AC-7g | `grep -c -F "never auto-amend the body" core/standards/failure-mode-standard.md` expect 0 | 0 (1 at baseline) |
| #7970 | AC-8 | `grep -c -F "issue-body-contract-sections-are-the-scope-of-record" core/ADRs/README.md` at least 2 | ≥2: the new entry's File line and the ADR-062 pointer line (0 at baseline) |
| #7970 | AC-8a | `grep -c -F "which supersedes Decision item 2 — the body-wide clause" core/ADRs/README.md` expect 1 | 1: ADR-062 marked superseded in part (0 at baseline) |
| #7970 | AC-9 | [DEFERRED — graded after the Stage 13 close-out: Stage 13 Phase A13 performs the Proposed → Accepted flip and Gate 13 row G-CL9 reads the successor's status on main] | on the successor file: `status: Accepted` → 1, `status: Proposed` → 0 |
| #7970 | OBL-1 | `grep -c -F "amends it in the issue body only once the operator records the decision that adopts it" release/governance/release-process.md` expect 1 | 1: design #7970 AC-10 (Maps-to none), E9 (0 at baseline) |
| #7970 | OBL-2 | `grep -c -F "only to carry out the operator's recorded decision" release/governance/release-process.md` expect 2 | 2: the FLAG-UPSTREAM row and the Phase E bullet (0 at baseline) |
| #7970 | OBL-3 | `grep -c -F "Tier 1 [ADJUST] is the default routing (Planning spoke amends the AC)" release/governance/release-process.md` expect 0 | 0: the post-Stage-8 default is gone (1 at baseline) |

Row count: 33 — 30 acceptance-criterion rows (AC-1 … AC-9 with sub-rows) and OBL-1–3; 31 runnable, 2 declared-deferred. At Commit 0 the criteria were re-read in #7970's body: nine checkboxes under its Acceptance Criteria heading, equal to the baseline.

**Design criteria** (for `check-ac-binding.py --design-file`, in the design's own order):
- `design #7970 AC-1` … `AC-9` restate issue AC-1 … AC-9 as the rows above refine them, each `Maps-to` its issue ordinal.
- `design #7970 AC-10` — `release-process.md` § AC-Drift Handling: after Stage 8, the Planning spoke amends the criteria in the issue body only to carry out the operator's recorded decision · `Maps-to: none`.

The binder reads `VERDICT BOUND ns:plan>issue,design>issue` on that snapshot (Part 1, P-2).

**Stage 7 additions:**
- `check-adr-durability.py` R4, R5 and R6 with `--diff-base origin/main`, plus `check-adr-numbers.py`.
- `renumber-adr.py --stamp --check` after Stage 12, which covers the token E9 adds to `release-process.md` (a branch-changed file).
- `check-release-links.py --check-anchors` in the real tree, for `#contract-and-record-sections`, `#body-fields-lifecycle` and `#agent-write-permissions`. This was left INDETERMINATE in Part 1, P-6.
- `check-doc-links.py`; the reference-durability and repo-integrity gates.
- `deploy.sh --check`: Check 63 stays `KNOWN:` for `release-process.md` line 29 and `failure-mode-standard.md`, with no new FAIL.
- AC-2c: read `git diff --numstat origin/main -- core/ADRs/ADR-062-substrate-vs-canonical-precedent.md` → `1 0`.

### Release-Level Verification

Stage 6 Phase C4 runs `release/tools/verify-release-plan.sh` on the committed plan (the runnable rows are expected to PASS, with AC-2c and AC-9 SKIP as declared), `check-doc-links.py --self-test` and a run over the changed files, `renumber-adr.py --detect` (no gap, no duplicate), the ADR durability lint over the new record, and a diff-stat of the release against `origin/main` that must equal the 11-file matrix exactly, with ADR-062's diff the one `superseded_by:` line.

## Cross-Issue Acceptance Criteria

None — enumerated over the release's one member card; a cross-issue criterion requires at least two issues.

## Tier-A Activated Design Artifacts

| Artifact | Flow class | Trigger | Tier | Home |
|---|---|---|---|---|
| `body-section-write-authority` | data-flow | a schema with two or more producer/consumer entities is modified (`design-artifact-standard.md` § 7) | **A** | an embedded marker plus table in the matrix (E4(d)), now depicting both files |
| `engineering-brief-editability-pre-flight` | agent-process | its depicted file changes; M1.1 is outside the flow | B — confirm-only at G-CL6 | unchanged |

## Held follow-up candidates (for the Stage 9 filing step)

Five surfaces outside the write set write card bodies under rules that do not yet state the successor's. This release does not edit them; each is filed only if it passes the filing threshold (Stage-5 revision 1, part 1/2, item 8).

1. `release/skills/implementation-planner/references/output-format-spec.md`, `Body Edit Mode: full`: a wholesale body re-scaffold rewrites record sections. `follow-up: none · bug`.
2. `release/references/standards/triage-design-rereview.md` § 3 C2, "commit the refinement to the issue body": not bounded by the matrix (record sections, or Dependencies at Stage 5). `follow-up: none · bug`.
3. `release/references/pipeline/stage-03-bundle.md` § Template-Conversion Rule, "body rewritten": should carry the observation's record text verbatim into the new template's record sections. `follow-up: none · bug`.
4. The ticket spec's § Mirror Trigger Points row 5 and `stage-05-solutioning.md`'s "Dependencies-field AC refinement" note both presume a Stage-5 Dependencies edit the matrix locks. The trigger still fires whoever writes. `follow-up: none · bug`.
5. `stage-13-close.md` § Phase A13 flips a record's file status but not its card's body Status. This is permitted under the Title row and not required. `follow-up: none · feature`.

## Quota Budget (*Stage-4 record*)

**Verdict:** PASS (Checkpoint A, `quota-budget-protocol.md`)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 1 · Stage 7: 1 · Stage 8: 1
**Per-spoke cost estimate:** `size:M` → low–moderate (§ 5 size-bucket band; no telemetry median used)
**Assumed remaining usage-window envelope:** unstated → conservative default (full window assumed unavailable to this hub alone: three sibling hubs share it)
**Estimated cumulative draw % (worst parallel batch):** one singleton, well under 50% of the envelope, even at a quarter-share of the window
**Routing:** PASS → proceed. Note: Checkpoint B re-validates at every `Agent`-tool launch, wave or singleton, at every stage. It is the runtime gate and the load-bearing one, with PROCEED/DEFER for a singleton. STAGGER is a secondary rate-limit-only defence, not a usage-window mitigation. Checkpoint B also gates on the host-API axis at runtime (§ 4.3b); Checkpoint A deliberately leaves that axis out. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Operational Deployment Manifest

N/A — enumerated over the classes {skill S-2 copies, rules mirror pairs, harness artifacts, packaged skill rebuilds, schema migrations, memory evictions}; none present in this release. No write-set file is a skill file, a mirror-pair member, a harness artifact or a `TEMPLATE_SYNC_MAP` source, and the release evicts no memory.

## Evidence (*Stage-4 record, with the P-1 wording corrected at the plan gate*)

- **P-1 (the no-rewrite restatement set).**
  - Invocation: a case-insensitive `git grep -n -I` at `8ed5e273`, over the whole tree minus `release/releases/` and `*.json`. Patterns: `historical.record`, `auto-amend`, `rewrite the body`, `rewrite the issue body`, `body.*never.*rewrit`, `not rewrite.*body`, `never rewrite`. A line filter then requires `body` or `bodies` on the same line.
  - Denominator: 2,400 tracked files. Raw hits: 88 files. Filtered: 36 files, each read and classified. 6 normative restaters; 18 ADR applications; 1 terminal record (`CHANGELOG.md`); the rest are false positives (ADR-body immutability, artifact bodies, commit bodies).
  - Sensitivity hole closed. The 52 files the same-line filter dropped were checked for a wrapped restatement with a context grep, not a full read: 0 found. The ADR-062 citer set (`ADR-062` / `substrate-vs-canonical` / `substrate-versus-canonical`, 71 files) was unioned in, adding 7 more ADR applications, 7 canonical-wins-only citers and 5 numbering or precedent mentions; there are 0 new restaters. The total is 25 applying ADRs, 24 of them `Accepted`; the one still `Proposed` is not in scope.
  - Sensitivity arm: the known positive, ADR-062 Decision item 2, was found on the same instrument. Specificity: the same filter over the two earlier pins gives 35 and 36 files, and the only difference from `8ed5e273` is a false positive in `stage-12-execute.md`.
- **P-2 (write-set drift since bundling).** `git diff --stat 7813457d 8ed5e273` over the ten Stage-4 files: empty. Control on the same instrument: the ADR-150 diff shows "1 file changed, 6 insertions".
- **P-3 (no criteria section at Stage 4).** `check-ac-binding.py --fetch` read #7970 as `NOT-EVALUATED (no-criteria-section)`; control #6170 read 6 criteria. Resolved by D-AC-Source (A).
- **P-4 (the why-comment rule's statements).** `git grep -i` for `why-comment`, `why comment`, `comment explaining why` and `comment saying what changed` outside the release-tracking corpus: 2 hits — the ticket spec's Body Update Protocol row, and ADR-211 citing it.
- **P-6 (templates).** The section labels of the six `.github/ISSUE_TEMPLATE/*.yml` files were read directly.
- **ADR numbering.** `renumber-adr.py --detect` at Stage 4 and again at Commit 0: `ANCHOR 241 · NEXT-FREE 242`. Provisional; a branch claim never binds.

## Deviation Log

| # | Stage-4 plan said | This file carries | Basis |
|---|---|---|---|
| DEV-1 | Slice S6: flip the successor to `Accepted` after the Stage 9 GO, with a verification row reading its status | No S6. The successor merges `Proposed`; ratification is Stage 13 Close Phase A13's, verified by G-CL9; AC-9 is graded after the close-out | Stage-4 plan gate (correction 3) |
| DEV-2 | File Change Matrix fence label `# ── unconditional ──` | `# ── always-applies ──`, so the label carries no substring the verifier reads as conditional | Stage-4 plan gate (correction 1) |
| DEV-3 | The new ADR row as `core/ADRs/ADR-242-<successor-slug>.md` | `core/ADRs/ADR-NNN-issue-body-contract-sections-are-the-scope-of-record.md`, so a renumbered delivery still matches | Stage-4 plan gate (correction 2); Stage-5 revision 1 |
| DEV-4 | Rollback: "the successor never merges as `Proposed` without an explicit operator decision" | Removed; the rollback line is revision 1's (§ Delivery Strategy · Rollback Strategy) | Stage-4 plan gate (correction 3); Stage-5 revision 1 (FM-7) |
| DEV-5 | P-1: the 52 filtered-out files "were read for a wrapped restatement" | They got a context grep, not a full read | Stage-4 plan gate (correction 4) |
| DEV-6 | Ten unconditional rows plus three CONDITIONAL rows (`stage-04-planning.md`, `stage-08-qa-testing.md`, `triage-design-rereview.md`), and S5 as "CONDITIONAL rows" | Revision 1's 11-file matrix: the three CONDITIONAL rows do not fire under A′ and are removed; `release/governance/release-process.md` is added (E9), and S5 is E9 | Stage-5 operator decisions (D-AC4 A′; E9) |
| DEV-7 | A draft Verification Plan of nine rows, three deferred to later stages | Revision 1's 33 rows and its design-criteria note | Stage-5 revision 1 (FM-3) |
| DEV-8 | Agent-Editability Read over 10 + 3 paths | The ten remaining Stage-4 paths plus one row for `release/governance/release-process.md` (unconstrained) | Stage-5 operator decision (E9); editability currency refresh on #9152 |
| DEV-9 | Stage 9 Plan Review: "RUN (Deep), and the ratification decision" | Stage 9: RUN (Deep); ratification at Stage 13 Phase A13 | Stage-4 plan gate |

### Stage 6 implementation notes (minor; no scope change)

| # | Note | Basis |
|---|---|---|
| ENG-1 | E6(c) names no position for the added reading entry; it is placed directly after the ADR-062 entry it qualifies, so the predecessor and its successor are read together. | Stage 6 inline decision (spec depth: placement unspecified) |
| ENG-2 | E6(d) and E8 replace hard-wrapped text; the replacement is re-wrapped to each passage's width, and every probe phrase the verification rows name stays on one line. | Stage-5 revision 1, transcription conventions |
| ENG-3 | The Phase A2 container predicate selects the GitHub sub-issue container (six slices over 11 files); the slices are tracked as the release pull request's checklist rows instead, and the choice is put to the hub. | Stage 6 Phase A2; recorded on #9152 |

## Verification Evidence

### Stage 6 Phase C4 self-verification

Head `834a2a93` (slice S5) against `origin/main` `8ed5e273`.

| Check | Result |
|---|---|
| Plan verifier (`release/tools/verify-release-plan.sh --format=json`, with the Stage-4 comment supplied for the provenance delta) | 38 PASS · 0 FAIL · 2 SKIP (AC-2c and AC-9, declared-deferred) · 0 UNRUNNABLE · 0 ERROR; 33 per-issue rows read. File Change Matrix: `declared=11 interpreted=11 obligations=2 excluded=0 conditional=0 uninterpreted=0`, both ADDs delivered. Provenance: presence, grammar and delta PASS. |
| The same 33 rows at Engineering Commit 0 (before S1) | 31 FAIL · 2 SKIP — every runnable row discriminates before the change |
| Cross-issue criteria lint (`--ciac-lint`) | `CIAC-LINT-SUMMARY declared=0 parsed=0 clean=0 declared-deferral=0 flagged=0` (one card; none declared) |
| Release diff against the matrix (`git diff --name-status origin/main...HEAD`) | 11 paths — 2 added, 9 modified — equal to § File Change Matrix; no extra and no missing file |
| ADR-062 | numstat `1 0`; the one added line is the `superseded_by:` pointer and `status: Accepted` is unchanged (an early reading of AC-2c, which Stage 7 grades) |
| ADR numbering | `renumber-adr.py --detect`: anchor 241, next-free 242, branch claim ADR-242 (detection only). `check-adr-numbers.py`: PASS, contiguous, no duplicates |
| ADR durability lint (`check-adr-durability.py --diff-base origin/main`, ADR-242 and ADR-062) | COUNT 0, reciprocity included; the lint's self-test passes in full |
| Doc links (`check-doc-links.py`) | `--self-test` OK; a run over the 11 changed files reports 0 broken links (control: a planted broken link in a scratch tree is reported, a valid one is not) |
| Dead-file references and anchors (`check-release-links.py --check-anchors --anchors-hard-fail --diff-base origin/main`, the 11 files) | 0 broken links and 0 missing anchors on added lines. The same instrument without the diff base reports two missing anchors on unchanged lines of the ticket spec and the matrix (a glossary anchor, pre-existing), so it reads anchors there and the three new ones resolve. |
| Transcription fidelity (each NEW span of revision 1's E3–E9 searched in its target file, whitespace-normalized) | 55 of 55 present; control arm (each span plus a sentinel) 55 of 55 absent |
| Skill-package cascade (`build-skill-packages.sh --skills-for-paths`, paths on STDIN) | 0 skills over the 11 paths (control: `release/skills/release-hub/SKILL.md` returns `release-hub`); no package rebuild |
| Check 63 (`check-count-structure.py`) | `release-process.md` and `failure-mode-standard.md` read KNOWN (their baselined preambles), and no write-set file reads FAIL. Six FAIL rows sit in files outside the write set that this release leaves byte-identical to `origin/main`. |
| Reference-durability classes on the added lines (a local reading of the gate's link, version-cutover and issue-reference classes) | 0 findings; the bridge, the personas spec and this plan are whole-file allowlisted, and every scanned file that gains a link carries `allow-link` (control: planted lines → 2 findings) |
| Release-module ADR index | N/A — this release adds no record under `release/ADRs/` |
| Runtime suite | Selection-map row 8 (no match): doc and governance changes only, so `test-run/suite-skip` |
| Deployed copies (Phase C3) | N/A — no write-set file is a mirror-pair member, a skill file or a harness artifact |
| `deliverable_state` | `deployed-copy-synced` for every deliverable: each is committed on the release branch and the release declares no propagation target (§ Operational Deployment Manifest) |

## Deployment Execution Log

(Populated during Stage 12.)

## Change Description

### Outcome

This release states who owns each part of an issue body, binding once the successor is ratified at Stage 13 Close. A body's contract sections — what the card asks for: the change, the criteria, the files, the dependencies, the expected effects — are the scope of record and are edited in place; its record sections — what was observed — are never rewritten, and a later observation is added beside them only at a step that adds one today or on a decision the operator has recorded. The field lifecycle matrix is the one table that says which stage may write each body field, and the rule is recorded in a new ADR that supersedes ADR-062's body-wide no-rewrite clause.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #7970 | The successor ADR (`status: Proposed`) and every surface that restated ADR-062's body-wide rule, narrowed in the same change; ratification follows at Stage 13 Close Phase A13 | DONE (ratification pending at Stage 13) |

### Key decisions

- **D-GT — G1, limited to body fields.** The matrix governs body-field writes; the successor says nothing about labels or Projects fields, which keep their standing.
- **D-AC4 — A′.** The matrix's acceptance-criteria cell at Planning reads `U*`, open on an A0.5 currency mismatch or a C2 re-review refinement; any other Planning-stage criteria change carries out an operator-recorded decision.
- **Add-beside writers.** A line added beside a record section is an edit like any other: the Stage 2 counted-observation line, the Stage 13 folded follow-up line, or an operator-recorded decision.
- **release-process.md § AC-Drift Handling.** The post-Stage-8 criteria refinement is written into the body only to carry out the operator's recorded decision on the flag.
- **Ratification at Stage 13 Close Phase A13** (Stage-4 plan gate), never inferred from milestone closure. If it is declined, the record stays `Proposed` and a follow-up change reverts the edits that cite it.

### Reversibility

**CHEAP — HIGH confidence.** Revert the release pull request: the ADR, ADR-062's pointer and every narrowing edit revert together, with no data migration.

### Downstream impact

- Card-body edits held behind this decision (the stale-citation backlog and #6170's corrected criteria) proceed under the rules once the successor is ratified.
- The permissions table's Body Updates cells now point at matrix columns, so the six-cell drift between the two tables cannot recur.
- Affected surfaces, by reader:
  - agents running the CER Claim phase read body-field permission from the matrix alone, and a Planning agent may change criteria only on the AC cell's two triggers;
  - the ticket spec carries the per-template contract/record classification and the why-comment rule a scope, criteria or fix-direction edit follows;
  - a Stage 5 chip built from the bridge's M1.1 pattern routes a contract-section change through the writers rule instead of forbidding every body edit;
  - a Stage 8 `FLAG-UPSTREAM` verdict still routes Tier 1 / Tier 2, and its criteria refinement lands in the body only on the operator's recorded decision;
  - the core ADR index marks ADR-062 as superseded in part and lists the successor.
- No skill package, mirror pair or harness artifact is touched, so nothing is rebuilt or redeployed.
- Five surfaces outside the write set write card bodies under rules that do not yet state the successor's; they are held as follow-up candidates for the Stage 9 filing step (§ Held follow-up candidates).
- Stage 7 runs the ADR durability lint with a diff base, ADR-number integrity, the anchor check in the real tree, the reference-durability and repo-integrity gates, `deploy.sh --check`, and AC-2c.

### Cross-references

- Release plan: this file, from its Header
- Milestone: `issue-body-is-the-scope-of-record`
- Successor ADR: `core/ADRs/ADR-242-issue-body-contract-sections-are-the-scope-of-record.md` (number provisional until merge)
- User-facing release notes: authored at Stage 13 Close under `release/releases/notes/`, named for the claimed version, per the release-notes standard
