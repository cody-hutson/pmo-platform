---
title: Release Plan — work-nature-and-axis-model (one decision record for the work natures and the design axes each owes)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.70; the concrete number binds at the Stage-12 atomic claim)
milestone: work-nature-and-axis-model
release_class: novel
reversibility: CHEAP / Confidence HIGH before the Stage-13 ratification gate — drop the record commit before merge, or revert the single release merge after it; after ratification the record is immutable and is changed only by a superseding record. The two register rows are deleted with the revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `work-nature-and-axis-model`

**Milestone:** `work-nature-and-axis-model` (milestone 426) · one member, **#7959** (`type:spike`, P2, size:L) · Stage-4 sub-task **#7969** = the approved plan (Parts 1–2), its gate **Decision Recorded** comment and the scaffold record · Stage-5 sub-task **#7971** = the design (revision 2, Parts 1–3), the round-1 gate record and the **round-2 gate record with the binding amendments B1–B10** · **#7972** = the Stage-6 Engineering sub-task whose spoke authored this file.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.70`**, contested by all five in-flight siblings. The concrete `vX.Y` binds only at the Stage-12 atomic claim, so this plan file and the branch stay slug-primary while in flight, and the Header `**Version**` cell carries the unresolved stamp placeholder.

**Topology:** D-C **SINGLE** — one release branch (`release/work-nature-and-axis-model`), one draft release PR opened at Stage 6 after the record and its register rows land, one merge, base `main`. This plan lands as **Engineering Commit 0**; the same spoke then lands the record, the register rows and the validation study, in that order.

**Concurrency posture:** **P0 fully serial** — one Engineering spoke on the branch. No force-push, `--force-with-lease` included.

**Release class:** `novel` (see § Release Class declaration). Stage 9 review depth **Deep**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output on #7969 (Parts 1–2) and its gate Decision Recorded comment, with the Stage-5 deltas from #7971's revision-2 output (Change 3, items 1–9) as updated by the round-2 gate decisions (B1–B10, D2–D8). Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority. Every thread comment consumed was `OWNER`-authored (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — provisional display v4.70 (recorded determination at the Stage-4 gate; re-verified at Commit 0); binds at the Stage-12 atomic claim |
| **Date Created** | 2026-09-27 (Sunday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Engineering (Stage 6) complete, with DT iteration 1 applied (Stage 7's F-01..F-07, #7973) — the record filled from the 31-item validation study; the C4 battery run on the artifact, with the mutant arms § Verification Evidence records; next, the Stage-7 re-test |
| **Branch** | `release/work-nature-and-axis-model` |
| **PR** | #8004 (draft) |
| **Milestone** | `work-nature-and-axis-model` (milestone 426) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-27, domain: governance }`

**Domain classification.** The File Change Matrix is one decision record, two register rows in a core standard, and this plan — all internal — so the closed grammar requires Form X. The dominant domain is `governance` (a decision record); `process` is secondary, because the record governs how work is decomposed and framed. The external practice this release needs (Zachman, Kruchten's 4+1, arc42, UML, BABOK, ISO/IEC/IEEE 42010 and 14764) is the deliverable's own content, graded by AC-2 and Stage-5 MD-G3, not by A1.5.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location.

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `35dbf418`, unmoved from the Stage-4 pin |
| **2** | Recompute next-free for bump-class **`minor`**. The adapter's own `claim-version.sh --dry-run` needs `gh` for its published-Releases arm, and this environment has none, so the arms were read directly (DEV-1): the tag arm from the fetched tags, the published-Releases arm through the GitHub connector (`get_latest_release`, `list_releases`, `list_tags`), and the ledger arm from `git show origin/main:release/releases/RELEASE_LOG.md` | anchor **`v4.69`** → minor floor **`v4.70`**; `v4.70` is in no arm → next-free **`v4.70`**, equal to the planned provisional display |
| **3** | HALT on collision: the planned version must be absent from the claimed set AND equal the recomputed next-free. The tag arm binds; published Releases and the ledger corroborate and never authorize | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git tag -l 'v4.7*'                                       (tag arm — binds; after git fetch --tags origin)
             connector get_latest_release / list_releases / list_tags  (Releases arm — corroborates)
             grep -c '| DEPLOYED |' on git show origin/main:release/releases/RELEASE_LOG.md, and a grep for v4.7x (ledger arm)
Denominator: every fetched v* tag (sorted with sort -V; highest v4.69 -> 40cec0c7); the connector's
             latest release (v4.69, published 2026-09-25T16:26:25Z) and its first page of releases and tags;
             the RELEASE_LOG at origin/main, 823,610 bytes
Control - sensitivity: the tag arm on the v4.69 slot -> 1 tag (40cec0c7); the Releases arm on v4.69 -> 1
             (latest release); the ledger arm's row reader on '| VERIFIED |' -> 237 rows, so the table parse is live
Control - specificity: NOT TRIGGERED — slot occupancy over an exact version tuple has no near-miss class;
             the v4.7* glob is broader than the tuple, so its zero implies the tuple's zero
Extraction:  the full local tag list; the connector's latest-release record; the full ledger read from
             origin/main (never the worktree copy)
Result:      0 occupants of the (4,70) slot on every arm
Verdict:     CLEAN — v4.70 is free on the binding tag arm and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** five open draft release PRs, all `minor` with provisional `v4.70` (see § Cross-PR Overlap Audit → In-Flight Release Roster). The version slot stays contested; the Stage-12 compare-and-swap arbitrates in merge order.

### Manifest half (step 3b, post-write / pre-commit)

`bash release/tools/claim-version.sh --verify-stamp work-nature-and-axis-model` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence. The verb is read-only and network-free, so it runs here unchanged.

This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — and every other mention names the placeholder instead of reproducing it, because the claim tool resolves the token by global substitution across the whole file.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6).

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X) with its rationale sentence | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited), amended by the Stage-5 deltas | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria — **none**: one member, and a CIAC spans at least two issues, so the section is omitted (present-when-nonzero) | — |
| 4 | Verification Plan, with the AC baseline at body revision 2026-09-27T23:01:38Z | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced) | § Header `**Version**` cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin, and § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

One card: **#7959 — Decide the work natures and the design axes each nature owes** (`type:spike`, P2, size:L; parent epic #6420). It delivers one decision record that decides the work natures (a definition and a boundary example for each; one key or two), the design axes (each sourced in established practice), the nature × axis owed table (each row marked proven or hypothesis against a validation set), the owed-axis coverage states, the continuity rule, the calibration trigger and the shared-key rule for the cut-pattern catalog and the axis toolkit, and applies the model to the measured instance.

**The record is authored `Proposed`** and is ratified to `Accepted` at the Stage-13 ratification gate (Phase A13, G-CL9). It carries a validation study designed at Stage 5 under the Research-Methodology Design variant (ADR-011) and executed at Stage 6.

Graded against #7959's six acceptance criteria at body revision **2026-09-27T23:01:38Z** (the round-2 refinement of AC-5).

### Stage-4 Phase A0 re-review (summary)

G-PL5 Mode R cache-read MISS (no marker-bearing comment); PT-1..4 run fresh: 0 C3, 3 C2 (AC-1, AC-2, AC-3 refinements applied to the body at the Stage-4 gate), 5 C1. G-PL1 and G-PL2 PASS, G-PL3 SKIP (empty window), G-PL4 admit-still-valid. The full re-review artifact is #7969 Part 1.

---

## Dependency Graph

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #7959 | P2 | bundled | (none — root) | — |

**Artifact relationship graph**

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #7959 | GENERATES | `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` | #7959 → file | File Change Matrix (add) |
| #7959 | GENERATES | two register rows and one Version History row in `core/standards/gate-efficacy-standard.md` | #7959 → file | File Change Matrix (edit; Stage-5 D2 and round-2 D3) |
| #7959 | BLOCKS | #7960 · #7961 · #7962 · #7966 | #7959 → each | each dependent's body `Blocked by: #7959` (cross-milestone; dependents unmilestoned) |
| #7961 | BLOCKS | #7962 | #7961 → #7962 | #7962's body (second-order) |
| #7962 | BLOCKS | #7963 | #7962 → #7963 | #7540's filed-children table (second-order) |

**Critical path:** none — the bundle has no in-release dependency edge (chain length 0). G3-07 PASS: 4 dependency edges checked, 0 cross-milestone violations.

---

## Decision Record

### Stage-4 gate (operator, 2026-09-27)

| # | Decision | Verdict |
|---|---|---|
| 1 | Plan approval; D-C topology; D-Concurrency posture; three AC refinements to #7959 | **Approved** — SINGLE · P0 · refinements applied to #7959's body (Tier 1 [ADJUST]) |
| 2 | D-ReleaseClass | **novel** — Standard engagement · Deep Stage 9 · Stage 5 activation ALL · 30-day outcome window · 8 raw → 9 effective points |
| 3 | D-StageApplicability | **(A)** — Stage 5 base plus the Research-Methodology Design variant, then the A6.5 adversarial review · Stages 7 and 8 REDUCE · Stages 10 and 11 platform-satisfied |
| 4 | D-OutcomeStatement | **A′** at the Stage-4 gate; superseded at the round-2 Stage-5 gate by **A″** (below) |
| — | D-Version (recorded determination) | minor → provisional v4.70; the number binds at the Stage-12 atomic claim |

### Stage-5 gate, round 1 (operator, 2026-09-27)

RETURN TO SOLUTIONING, with: **D2** the calibration comparison is registered as a class-3-O named gap in `core/standards/gate-efficacy-standard.md` (adds that file to this matrix; a Tier-2 scope change); **D3** Stage 6 runs in the hub's cloud session with push permission for this branch, and Stages 12–13 run on the operator's instance; **D5** Stage 8 blind re-codes the nine-item prefix, and a nature agreement below 7 of 9 leaves every row a hypothesis; **D6** the continuity rule, both epic-to-slices and stage-to-stage, is decided in the record while the cut mechanism stays with #7963 and #7960; **D7** a second axis binds to registry concept 1 (Deliverable-class) and the "three form values" floor is retired; **D8** no separate `adr` issue (the ADR file is the record). AC-1 and AC-5 refined in the body (revision 2026-09-27T18:36:40Z).

### Stage-5 gate, round 2 (operator, 2026-09-27) — AUTHORIZE ENGINEERING with binding amendments

**D1** AUTHORIZE ENGINEERING, conditional on B1–B10, which Stage 6 applies to the revision-2 handoff and scaffold before coding. **D2** one carrier for the framing carry: at the cut, #7963's mechanism writes a "Framing carry" section into each slice's body, which every stage reads first. **D3** Row C (a′) with a comparing observable that states it cannot emit until that carrier ships; Row B takes its two-row variant. **D4** AC-5 refined in the body (revision **2026-09-27T23:01:38Z**). **D5** Row A's framing line gains the framed epic's concept-1 class. **D6** Outcome Statement **A″** adopted. **D7** Stage 6 (engineering) is inside the carry, and a Stage-6 survey row joins the carry table; "overlap considerations" includes shared surfaces (topics and files; files join at the cut). **D8** authoritative sources for `defect` are governed sources only. **AI-005** widened to #7919 and #7901.

**Binding amendments (verbatim scope; where each lands is recorded in § Amendments applied):**

- **B1** — classification step 5 reads "An authoritative statement recorded before the work was raised — a spec, rule, contract, schema, decision record, or the stated purpose of the capability — already requires the missing or wrong behaviour, and it can be quoted → `defect`"; a coding rule **Authoritative sources** names what counts (a governed file in the repository, an ADR, or a ratified release plan; an operator comment, directive or scanner alert only once a governed file adopts it); each `defect` code records its source and the basis for its authority.
- **B2** — an item owes the union of its primary nature's owed axes and the owed axes of every surface nature (steps 3–4) that at least one classified criterion carries; the primary nature still indexes the row for grading; report how many items the union widens and the MULTI rate with the owed-set difference; at epic altitude a slice's nature is expected to be among its parent's natures, and one outside them says why.
- **B3** — E2-T is defined by function ("a passage in a section or field that the governing template requires for every item regardless of nature"); the list is derived, not closed, and includes the issue form's Affected Files and Documentation Impact, the plan's File Change Matrix and Contention Map, the Stage-5 output's Blast Radius and `### Output for Stage 6` blocks, and the release PR template's Documentation Impact table; Stage 6 records which templates it read.
- **B4** — Change 2's check uses Check 62's own pointer pattern (0 expected on the new rows; the HSR-1 row returns 1 as the control); the AC-3 checks are scoped to the extracted § Calibration trigger section, with a mutant deleting the over-owed limb and the supersession sentence as the sensitivity arm; every check in the verification plan runs on the artifact and on a mutant before Stage 6 pushes.
- **B5** — threat V15 (the codebook was tuned on drawn items V-03, V-09 and V-12); the `defect` and `data-structure-change` boundary examples and the `new-capability` "widening" clause are replaced with examples drawn from outside the 31-item set, their source items named in the Stage-6 evidence; Stage 8 reports nature agreement as k of 9 (D5's floor applies) and as k′ of the 7 items left once V-03 and V-09 are set aside; the Stage-8 brief carries the codebook sections verbatim and the Stage-8 spoke records its codes before it opens the record, this plan or its sub-task, and states that read order.
- **B6** — the carry table: (i)-A answered axes #7963; silent and not-applicable parent axes #7963 once widened (note posted), otherwise unowned; (i)-L and (i)-O vocabulary #7960, carry the slice-body Framing carry section written at the cut through #7963; stage-to-stage carries the slice-body Framing carry section, read first by every stage, with changes through the AC-update-plus-comment rule; a Stage-6 row is added; "unowned — recommended home" where a carry has neither an enforcing surface nor an owning card.
- **B7** — an over-owed candidate needs at least 2 completed items of the nature; limb (a) counts a not-owed axis as needed only when a later correction supplied it or the framing states why it was needed; each proven row reports its concept-1 span next to its strata.
- **B8** — R-C1 resolves an item's class through its `milestone` field to that milestone's release plan label; `scopemap.py` is a cross-check whose disagreements are reported and never decide the class.
- **B9** — the n on each side is printed in the one-key sentence; Row A's framing line is `framing N · YYYY-MM-DD · <nature> · <concept-1 class> · <axes needed> · <axes declared not applicable, with reasons>`, and the framing-1 line carries the measured instance's class, marked inferred, or "unresolved"; on the B side of the demonstration no item may carry E3-F on the axis.
- **B10** — the record and this plan carry A″; the record's key sentence is conditional: "the work-nature key (one key by default, or nature × deliverable class where a demonstration held)".

### Amendments applied (Stage 6)

`<record>` = `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md`; `<standard>` = `core/standards/gate-efficacy-standard.md`; `<plan>` = this file.

| Item | Landed in (file · section) |
|---|---|
| **B1** | `<record>` § Classification procedure (step 5 verbatim; the **Authoritative sources** rule); `<plan>` § Validation Study Design → Coding scheme C1 (each `defect` code records its source and the basis for its authority) |
| **B2** | `<record>` § Classification procedure (**Owed set**; "Why this order" now agrees with it); § Owed axes by nature (owed-axis rule excludes axes already owed through a surface nature); § Continuity rule (a slice's nature is among its parent's natures); `<plan>` § Validation Study Design → Analysis plan step 6 (union-widening count, MULTI rate and owed-set difference) |
| **B3** | `<record>` § Owed axes by nature → Grades (E2-T defined by function; derived list with the five named sections); `<plan>` § Validation Study Design → Rubric and "Templates read" |
| **B4** | `<plan>` § Verification Plan → Release-Level Verification (Check 62's own pattern with the HSR-1 control; AC-3 scoped to § Calibration trigger by a probe the executor dispatches, with its mutant); § Verification Evidence records the checks Stage 6 ran on the artifact and on a mutant or control — slots, durability, the issue-reference gate, AC-1..AC-6, the ADR schema, Change 2's pattern, and the plan's own checks (verify-stamp; in DT iteration 1 also the issue-reference gate, the depth lint, the count-structure lint and the parser-clean grep) — and names the rows Stage 6 ran on the artifact only (numbering, Check 62 unchanged, Row A content, the executor's families, Check 58), each run on the artifact and on mutants by the Stage-7 battery (#7973 comment 5862203943) |
| **B5** | `<record>` § Work natures (`defect` and `data-structure-change` boundary examples and the `new-capability` widening clause replaced, sources under `## References`); § Row grading (k of nine and k′ of seven); § Validation set (the tuning disclosure); `<plan>` § Validation Study Design → threat V15; § Verification Plan D5 row (k and k′; read order); the Stage-8 codebook hand-off in the Stage-6 output |
| **B6** | `<record>` § Continuity rule → the carry table: three rows into slices (the silent and not-applicable axes "unowned — recommended home: the framing-to-cut card") and eight stage rows carried by the Framing carry section, each cited section re-read at the fill commit `7496458c` |
| **B7** | `<record>` § Owed axes by nature (over-owed candidates need at least two delivered items; proven rows report their deliverable-class span); § Calibration trigger (limb (a)); `<standard>` Row A limb (a) |
| **B8** | `<plan>` § Validation Study Design → Concept-1 rules (R-C1 through the `milestone` field; `scopemap.py` a cross-check); `<record>` § Validation set (classes found) |
| **B9** | `<record>` § Nature is one key (n on each side; the B-side excludes E3-F); `<standard>` Row A framing line (`<concept-1 class>` field; framing-1 line marked "unresolved") |
| **B10** | `<record>` § Decision opening sentence and § How the catalog and the toolkit share the key (conditional key sentence); `<plan>` § Release Outcome Statement (A″) |
| **D2** | `<record>` § Continuity rule (**One carrier** paragraph); `<standard>` Row C (Act: write the slice's Framing carry section) |
| **D3** | `<standard>` Row C (comparing observable; cannot emit until the carrier ships); Row B two-row variant |
| **D5** | `<standard>` Row A framing line; `<record>` § Calibration trigger (the line carries the framed epic's deliverable class) |
| **D6** | `<plan>` § Release Outcome Statement (A″) |
| **D7** | `<record>` § Terms (overlap considerations include shared surfaces: topics at framing, files at the cut); § Continuity rule (engineering in the stage list); the carry table's Stage-6 row; `<standard>` Row C trigger list |
| **D8** | as B1 |
| **AI-005 widened** | `<plan>` § Action items; § Contention Map |

---

## Implementation Sequence

Single card, strictly serial (P0).

| Order | Stage | Actor | Work | Exit |
|---|---|---|---|---|
| 1 | 5 Solutioning | Stage-5 spoke (base + Research-Methodology Design variant), then the A6.5 adversarial reviewer; revision 2 and its second A6.5 round | methodology, validity threats, codebook, owed table, scaffold, register rows, verification plan | done — AUTHORIZE ENGINEERING with B1–B10 |
| 2 | 6 — Commit 0 | Stage-6 Engineering spoke | Commit-0 version re-verify (steps 1–3), write this plan carrying the Commit-0 Survival Set and the Stage-5 deltas, the stamp-manifest check (step 3b), commit | `claim-version.sh --verify-stamp` exit 0 |
| 3 | 6 — the record and rows | same spoke | apply B1–B10 and D2, D3, D5, D7 to the scaffold; author the record at the mainline next-free (`renumber-adr.py --next-free` → 207) with `status: Proposed` and its ratification promise; append Rows A and C at the register tail and Row B at the Version History tail; open the draft release PR | C4 battery on the scaffold |
| 4 | 6 — the validation study | same spoke | census re-run (pass 1), state-reason pass (1b), concept-1 pass (1c, B8), testability table re-issued; code the 31 items in sequence order, committing after every batch of at most six; analysis steps 5–7 (B9's n per side); the AC-5 application (in-sample label); the continuity carry table (B6 and the Stage-6 row); the AC-6 check | every slot filled (`grep -c` of the slot marker → 0) |
| 5 | 6 — fill and verify | same spoke | C4 battery and every verification-plan check on the artifact and on a mutant (B4); § Change Description and § Deviation Log; update the PR body | C4 self-verification |
| 6 | 7 · 8 | DT, QA spokes | REDUCE batteries; Stage 8 adds D5's blind re-code (B5) | per-criterion verdicts |
| 7 | 9 → 13 | hub + spokes | Deep review; merge, atomic claim, an ADR renumber if the slot collided, the `{{ADR:…}}` stamp; A13 ratification → successor coupling → C1 | G-PR7 · G-CL7 · G-CL9 |

**Change specification — #7959**
- **Files:** § File Change Matrix.
- **Change:** the record (Change 1), the two named-gap register rows and one Version History row (Change 2), this plan (Change 3).
- **Acceptance criteria:** AC-1..AC-6 at body revision 2026-09-27T23:01:38Z (6).
- **Complexity:** High (a research-grade decision; the validation study is the only non-transcription work). **Dependencies:** none in-release, none inbound.

**Lifecycle Definition (new artifact: the ADR)** — per `RELEASE_PROTOCOL.md` § Lifecycle Definition Requirement: (1) growth — fixed size, one record per decision; (2) size discipline — the ADR schema's seven sections plus `## References`; the mutable axis reference prose ships with #7961's toolkit, not here; (3) cleanup trigger — the calibration trigger, or #7540's sunset review; (4) archive path — none; a superseded record stays in place marked Superseded; (5) ownership — the decomposition method's owner (#6420), with the framing epic (#7540) as co-consumer; (6) exit — superseded by a later record, never deleted.

### Agent-Editability Read

Controls read at `35dbf418` (#7969 Part 1 § Agent-Editability Read carries the derivation): the Tier-0 floor in `core/hooks/block-autonomy-ceiling.sh` reduces in-repo to three basenames at any depth (`CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`); the sanctioned-session gate in `core/hooks/block-skill-direct-edit.sh` scopes `SKILL.md` and skill `references/` paths.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #7959 | `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #7959 | `core/standards/gate-efficacy-standard.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #7959 | `core/ADRs/README.md` (CONDITIONAL; `renumber-adr.py` R4 log append) | no | no | unconstrained | unconstrained | Stage-12 merge reconciliation |
| release | `release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md` | no | no | unconstrained | — | Engineering Commit 0 |

There are no `delete` rows. `unconstrained` means no control refuses the write; the change is still governed through issue, plan and PR.

---

## Stage Applicability Matrix

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #7959 | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | T1: a new ADR carrying named tables. T3: placement confirmed at Stage 5; one key or two open. T4: several axis sources and two classification shapes. T2: no skill path. T5: 0 governance files. T6: the write set is enumerable, the conditional rows are declared, and no shared pattern changes. |

**Riders recorded against #7959** (Stage 4, carried; Stage 5 dispositions): § 3.1 abstraction altitude — the record extends the core module boundary with an orthogonal classification dimension (seam rider PASS, check 4.7); § 3.2 structural premise — SR-G1..SR-G4 met at Stage-5 exit; **SR-G6** — `net-new because in-place is infeasible:` each partially-covering surface (the intake type map, the process designer's requirement types, registry concept 1, methodology-pack kinds, `type:` labels) owns another concept, so the record crosswalks them as hints under its procedure rather than extending one into a key; **SR-G7 applies to Change 2** — the gate-coverage register's aggregated evaluand set gains two members, traced to Check 62 (the only register reader, which reads resolution pointers only; neither row carries one).

| Stage | #7959 | Basis |
|---|---|---|
| **5 — Solutioning** | ACTIVATE — base + Research-Methodology Design variant; A6.5 adversarial review (two rounds) | T1/T3/T4; MD-G1..MD-G5 and the § 12 handoff; activation bias ALL |
| **6 — Engineering** | APPLY | Commit 0 (plan) + the record + the register rows + the validation study; P0 |
| **7 — Dev Testing** | REDUCE | no executable surface; the doc-conformance battery (§ Verification Plan, release-level), including the `domain_practice` verification Stage 7 always runs |
| **8 — QA** | REDUCE, plus D5's blind re-code | per-criterion verdicts AC-1..AC-6 by named read, the AC-6 collision check with its control arm, and the blind re-code of V-01..V-09 (B5: k of 9 and k′ of 7) |
| **9 — Plan Review** | APPLY (release) | Deep (`novel`); G-PR7 against the approved Outcome Statement A″; A6.5 divergence and A6.6 in-flight re-measure (version and ADR slots) |
| **10 — Dry Run** | PLATFORM-SATISFIED | the PR diff is the dry run; no schema or Layer-2 migration |
| **11 — Snapshot** | PLATFORM-SATISFIED | git history is the snapshot |
| **12 — Execute** | APPLY (release) | merge commit; atomic claim with `--stamp-slug work-nature-and-axis-model`; `renumber-adr.py` reconciliation if the slot collided, then the `{{ADR:…}}` stamp; the AI-005 keep-both merge on the standard; no Layer-2 deploy |
| **13 — Close** | APPLY (release) | A13 ratification (G-CL9) → successor coupling (#7966, AI-003) → C1; 30-day outcome window |

Skips: 0 · REDUCE: 2 · platform-satisfied: 2 · parallel-eligible spokes: Stage 5: 1 · Stage 7: 1 · Stage 8: 1.

---

## File Change Matrix

```
# ── Engineering Commit 0 (plan transcription) ──
release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md       add
# ── #7959 — the decision record (placement core/ADRs/ per Stage 5; number = mainline next-free at authoring, reconciled at merge) ──
core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md    add
# ── #7959 — Change 2: Rows A and C at the gate-coverage register tail, Row B at the Version History tail (Stage-5 round-1 D2; round-2 D3) ──
core/standards/gate-efficacy-standard.md                                 edit

# ── CONDITIONAL — resolved FALSE at Stage 5 (placement is core/ADRs/); NOT DELIVERED, recorded in § Deviation Log ──
CONDITIONAL:S5-PLACEMENT-RELEASE     release/ADRs/ADR-*-design-axes-and-cut-patterns-key-on-work-nature.md   add
CONDITIONAL:S5-PLACEMENT-RELEASE     release/ADRs/README.md                                                   edit
# ── CONDITIONAL — the ADR number collides at merge and renumber-adr.py moves the record (resolves at Stage 12) ──
CONDITIONAL:ADR-RENUMBER-AT-MERGE    core/ADRs/README.md                                                      edit
```

#### Read-only inputs

```
core/disciplines/work-organization-mapping-framework.md                 READ
core/disciplines/discovery-discipline.md                                READ
core/disciplines/cross-chain-architecture-map.md                        READ
core/disciplines/decision-discipline.md                                 READ
operations/skills/intake-desk/references/type-map.md                    READ
operations/skills/pmo-process-designer/SKILL.md                         READ
core/specs/domain-token-registry.md                                     READ
core/schemas/work-item-type-schema.md                                   READ
core/packs/scrum/pack.toml                                              READ
core/packs/kanban/pack.toml                                             READ
.github/ISSUE_TEMPLATE/improvement.yml                                  READ
.github/PULL_REQUEST_TEMPLATE.md                                        READ
release/references/standards/solutioning-output-template.md             READ
release/skills/release-planner/references/release-plan-template.md      READ
release/references/specs/ticket-information-architecture.md            READ
release/references/pipeline/stage-02-triage.md                          READ
release/references/pipeline/stage-04-planning.md                        READ
release/references/pipeline/stage-05-solutioning.md                     READ
release/references/pipeline/stage-06-engineering.md                     READ
release/references/pipeline/stage-07-dev-testing.md                     READ
release/references/pipeline/stage-08-qa-testing.md                      READ
core/schemas/adr-schema.md                                              READ
core/standards/adr-authoring-guide.md                                   READ
release/tools/renumber-adr.py                                           READ
release/tools/check-adr-numbers.py                                      READ
release/tools/check-adr-durability.py                                   READ
release/tools/claim-version.sh                                          READ
core/deploy/tools/check-issue-ref-validity.sh                           READ
```

#### Release-wide explicit non-scope

```
release/references/protocols/fission-convention.md                      NOT EDITED
operations/skills/intake-desk/SKILL.md                                  NOT EDITED
.github/ISSUE_TEMPLATE/epic.yml                                         NOT EDITED
core/disciplines/review-discipline-principles.md                        NOT EDITED
release/references/standards/triage-design-rereview.md                  NOT EDITED
```

New-executable companion obligation: N/A — enumerated over the two `add` rows and the one `edit` row; all three are Markdown and no `.sh` is added. The study's instruments (`census.py`, `sample.py`, `scopemap.py` and the coding and check scripts) run from the Engineering spoke's run directory and are not committed (draft and scratch content stays out of the tracked corpus).

---

## Integration Points

- **Upstream inputs:** #6420 R1 (the nature list); #7540 R1–R4 and § The measured instance; the operator's 2026-09-26 delivery-continuity comment on #7540; the operator decision of 2026-09-27 to run one joint spike.
- **Downstream consumers** (outside this milestone, held on it): #7960 (the cut-basis vocabulary; reads the key and the continuity rule's cut limb); #7961 (the toolkit; cites the owed table or projects it row for row); #7962 (the coverage states); #7966 (the successor card; composes MS-1 and gates this milestone's close); second-order #7963 (carries the owed axes into the cut and writes the slice-body Framing carry section, round-2 D2).
- **Coordination:** #6390 `composition-method-host-decision` (the toolkit's carrier relates to its host; no build edge); #7965 (altitude binding and slip detection).
- **Mechanical seams:** the ADR number space (`check-adr-numbers.py`, `renumber-adr.py`, whose `--stamp` resolves `{{ADR:…}}` tokens at the claim); the version claim (`claim-version.sh`); the gate-coverage register (Check 62 reads resolution pointers only); Stage-13 A13 and G-CL9; Check 58.

### Contention Map

**Within the release:** none — one card (denominator 1, so no pair exists).

| Surface | Siblings touching it (heads read live at Commit 0) | overlap_class (ADR-005) | Resolution |
|---|---|---|---|
| `core/ADRs/ADR-207-…md` (unconditional add) | none on this path | single-pr | — |
| ADR number slot 207 (virtual) | #7839 (`release/ADRs/` 207–210), #7895 (`release/ADRs/` 207–208), **#7919 (`core/ADRs/`, slot 207 under its own slug, new since Stage 5)** | Tier-S serialization | author at the mainline next-free (207); the first to merge binds and later claimants renumber at merge (ADR-115); the R3 citation sweep and the `{{ADR:…}}` stamp carry the final number |
| `core/standards/gate-efficacy-standard.md` register tail (after the row now at L310) | #7919 (+112 lines there), #7901 (+1 class-3-O row there) | append-pattern | **keep-both at merge (AI-005, widened)** |
| `core/standards/gate-efficacy-standard.md` Version History tail (after L429) | #7919 (+2 lines there) | append-pattern | **keep-both at merge (AI-005)** |
| `core/standards/gate-efficacy-standard.md` other regions | #7919 (in-place edits near L81, L107, L124, L214, L242, L271, L309, L394, L402); #7839 (L299 in place) | line-disjoint | no action |
| the plan file | none | single-pr | — |
| version slot `Δversion/minor-after-v4.69` (virtual) | all five siblings | Tier-S serialization | the Stage-12 compare-and-swap in merge order |
| `core/ADRs/README.md` § Renumber log (CONDITIONAL) | any sibling that renumbers at merge | append-pattern | `renumber-adr.py` R4 appends; informational |

---

## Cross-PR Overlap Audit

### Baseline SHA

`35dbf41847df2c1deab792d2944e46ac6ddd26fd` (`origin/main`, 2026-09-25T16:17:45Z, the merge of PR #7888). Unmoved at Commit 0. **Sibling-merge revalidation predicate** (Stage 9 G-PR9 and Stage 12 A.5): `git log 35dbf418..origin/main --name-status --find-renames`, intersected with SURFACE(R) = { `core/ADRs/ADR-*-design-axes-and-cut-patterns-key-on-work-nature.md`, `core/standards/gate-efficacy-standard.md`, `Δversion/minor-after-v4.69`, the ADR slot }.

### In-Flight Release Roster

**Measured at:** Commit 0, 2026-09-27T23:13Z · **Population:** n=5 (open PRs with a `release/*` head, drafts included, through the connector's `list_pull_requests state=open` → 5; `git ls-remote --heads origin 'refs/heads/release/*'` → the same five heads plus this branch).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `install-resolves-identically` | `#7931` | `c8ae83d4` | `minor` | `v4.70` | `v4.70` | — |
| `controls-fail-loud` | `#7919` | `7ff5a9cd` | `minor` | `v4.70` | `v4.70` | the standard (register tail, Version History tail, in-place rows); ADR slot 207 (`core/ADRs/`) |
| `telemetry-is-computable` | `#7901` | `eea3df66` | `minor` | `v4.70` | `v4.70` | the standard (register tail, +1) |
| `closeout-verification-rows-consistent` | `#7895` | `faa7662d` | `minor` | `v4.70` | `v4.70` | ADR slot 207–208 (`release/ADRs/`) |
| `verifier-grades-what-plans-declare` | `#7839` | `a49bc0e7` | `minor` | `v4.69` (stale) | `v4.70` | the standard (L299 in place); ADR slot 207–210 (`release/ADRs/`) |

No verdict is rendered here; Stage 9 A6.6 re-measures.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | **ADR slot.** The mainline next-free is 207, and three sibling branches already claim 207 (#7839 and #7895 under `release/ADRs/`; #7919 under `core/ADRs/`, new since Stage 5). This record will probably move at merge. | High | Low | Author at the mainline next-free (ADR-115); never step past a branch claim. `renumber-adr.py --detect` at Commit 0 and `--renumber` at merge (Status provenance note, § Renumber log entry, branch-scoped R3 citation sweep); the `{{ADR:…}}` tokens in the register rows resolve at the claim. | Stage-6 spoke; Stage-12 executor |
| R2 | **Version slot.** All five siblings recompute v4.70. | High | Low | Recorded determination; the Commit-0 re-verify ran (PROCEED); the Stage-12 compare-and-swap arbitrates. Slug-primary names do not rename. | Stage 12 |
| R3 | **Stage-13 close coupling.** The milestone does not close until #7966 is done or its successor is explicitly deferred; no Stage-13 gate enforces that. | Medium | Medium | AI-003: before C1, confirm #7966 is marked as closed, or its deferral is recorded on #7966 and #7540. Sequence A13 → #7966 or its deferral → C1. | hub (Procedure 7); operator |
| R4 | **Validation set (re-stated).** The retired "three form values" floor no longer binds; the second-axis question is testable for **at most one nature, on one class pair (governance × software)**, because the set's delivered items span two concept-1 classes. | High | Medium | The three-valued demonstration (demonstrated / tested, not demonstrated / not testable); one key is a stated default where no demonstration held; the calibration framing line carries the framed epic's class (B9, D5). | Stage-6 spoke |
| R5 | **Measured-instance evidence and depersonalization.** The consumer's records are not in this repository, and its owner/repo slug carries the operator handle. | Medium | Medium | The record names the instance by role, cites #7540 only under `## References`, and labels AC-5 an in-sample consistency check. | Stage-6 spoke |
| R6 | **Term collisions.** "Design axis" has four other senses; `domain` has six registered senses plus the form field; "altitude" names two axes. | High | Medium | The record's § Terms distinguishes each and cites registry concept 1. | Stage-6 spoke |
| R7 | **Keying on a Proposed record.** The dependents unblock at merge, but the record stays Proposed until A13. | Medium | Medium | The status line carries the ratification promise; Check 58 reports it as advisory until G-CL9; #7966's re-triage starts after A13 or treats the record as provisional. | hub; #7966's owner |
| R8 | **Ceremony risk.** A forced axis set becomes checkbox theatre on work that owes one axis. | Medium | Medium | Nature-keying; not-owed axes omitted; declared not applicable with a reason; the over-owed statistic (B7: at least two completed items). | Stage-6 spoke |
| R9 | **Small evidence base.** One epic-altitude instance, two deliverable classes among delivered items, a single-cluster Data stratum. | High | Medium | Hypothesis rows marked; the calibration trigger routes disagreement to a superseding record. | record owner |
| R10 | **Time-box overrun.** 31 items coded per criterion. | Medium | Low | The first nine items are the minimum viable prefix; batches of at most six are committed as they land, so an interruption loses at most one batch. | Stage-6 spoke |
| R11 | **Rollback cost grows with consumption.** | Low | Medium | § Rollback Strategy; the calibration trigger is the planned exit. | operator |
| R12 | **Governing-spec drift.** #7839 edits `stage-04-planning.md`, which governs this transcription. | Medium | Low | Transcribed against `main`'s current § 6; #7839 has not merged (`main` unmoved). | Stage-6 spoke |
| R13 | **The named gaps stay open.** Rows A and C have no runner until #7962 records coverage, #7963 records the cut's axis mapping and writes the Framing carry section, and the recommended homes ship. | High | Low | Each row's observable is a dated line appended at a Stage-13 close, so a skipped comparison shows as a stale date; Row C states it cannot emit until the carrier ships. | workspace owner |
| R14 | **The Stage-8 blind re-code can leave every row a hypothesis late in the release.** | Medium | Low | The record already carries the sentence; the change is a text edit returned to Engineering under Phase E. | Stage-8 spoke; Stage-6 spoke |
| R15 | **Keep-both merge on the standard** with two siblings at the same two insertion points (AI-005). | High | Low | Append-only rows; the merge keeps every sibling's rows and ours; Check 62's count is unchanged by ours (no pointer). | Stage-12 executor |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential — one card |
| Commit strategy | Commit 0 = this plan; then the record and register rows; then the validation study in batches of at most six coded items, each committed and pushed; then fill-and-verify. Stage 7 and 8 fix-ups land as separate commits. A merge-time renumber commit is added only if the slot collided. |
| Review approach | One release PR, `release(work-nature-and-axis-model): …`, from `release/work-nature-and-axis-model`, opened in draft at Stage 6. The close keyword for #7959 appears only in the PR body's Issue References block; #7966 stays open. |
| Topology · posture | D-C SINGLE · P0 fully serial |
| Deployment mechanism | Git merge commit plus the Stage-12 atomic claim; no Layer-2 deploy |
| Execution venue | Stage 6 in the hub's cloud session with push permission for this branch only (Stage-5 round-1 D3); Stages 12–13 on the operator's instance |

---

## Validation Study Design (the Stage-5 handoff as amended by B1–B10)

The Stage-5 revision-2 Methodology-Design Handoff (#7971) is the design; this section carries it as the round-2 amendments changed it, so Stages 7 and 8 read one current copy. Fixed inputs are unchanged: the frame, the exclusions, the normalization, the strata, the quotas and the seeded 31-item draw.

**Frame (fixed).** One tracker issue filed on the improvement form, created 2026-06-21T01:22:40Z (the Domain field's go-live) through 2026-09-27T15:46:56Z, whose first `Domain` heading carries a value normalizing to one of the form's seven values (case-insensitive exact match, else the leading token, flagged `annotated`; otherwise off-enum and outside every stratum). Excluded as circular evidence: #7959 and its five held cards (#7960, #7961, #7962, #7963, #7966). Strata by normalized value; quota min(stratum, 12); a larger stratum draws closed first, up to 8, the rest open; round-robin over Data, Software, Governance; seeds `random.Random("7959:<Stratum>:closed")` and `("7959:<Stratum>:open")`, each `.sample(sorted_numbers, k)`, on Python 3.11.15. N = 31; the minimum viable prefix is the first nine items. "Closed" means `state_reason: completed`; #2344 (V-08) and #5589 (V-06) are not planned — marked, coded, reported, and entered in no count.

**Rubric (item × axis).**

| Grade | Meaning | Counts as |
|---|---|---|
| E0 | nothing answers or names the axis question | E0 |
| E1 framed | the item's own body, as filed or converted at triage, names or partly answers it; an open item's design passages grade at most E1 | E1 |
| E2 delivered | a completed item's delivered design or change answers it in an item-specific passage, from the first source yielding one — closing PR body, the milestone's release PR body, commits citing the item, the item's Stage-5 output — outside a template-forced section | E2 |
| E2-T template-forced | the only delivered passage sits in a section or field that the governing template requires for every item regardless of nature (B3; list below) | E1, in every rule |
| E3-P pipeline refinement | the axis surface was added at a planned Stage 2–5 step inside a surface the framing named | E2 on a completed item, E1 otherwise; never counts for owed-ness |
| E3-F framing corrective | the item's first framing was E0 on the axis, and a later record supplies it by an operator correction naming it, or a re-scope whose stated reason is that the framing missed it | counts for owed-ness; E2 on a completed item |

**E2-T sections — derived from the templates, not closed (B3).** Templates read at Stage 6: `.github/ISSUE_TEMPLATE/improvement.yml` (its required fields), `release/skills/release-planner/references/release-plan-template.md`, `release/references/standards/solutioning-output-template.md` § 3, and `.github/PULL_REQUEST_TEMPLATE.md`. Sections required for every item regardless of nature that can carry axis-shaped text: the issue form's **Affected Files** and **Documentation Impact** fields; the plan's **File Change Matrix**, **Contention Map**, **Agent-Editability Read** and per-issue **Change Specification** file line; the Stage-5 output's **Blast Radius** bucket and its **`### Output for Stage 6`** block (row 7 of that template's comment frame); and the release PR template's **Documentation Impact** table, **Implementation** table and **Verification Evidence** block.

**Minimum load-bearing grade (MD-G5).** E2 (including E3-P and E3-F on completed items) to prove a row or demonstrate class dependence; E3-F to make an axis owed; E1 and E2-T support "hypothesis" only.

**Rules over the grades.**

| Rule | Items counted | Evidence that counts |
|---|---|---|
| Owed-axis rule (R-a) | items of nature N, completed or open (never not planned) | an axis N does not owe becomes owed iff at least 2 items carry E3-F on it, each from its own correction record; an axis already in an item's owed set through a surface nature (B2) does not count toward it |
| R-b | — | Stage 6 never removes an owed mark |
| Over-owed candidate (reported, never removed) | completed items of N, **at least 2 (B7)** | an owed axis at E1 or below on every completed N-item, with E3-F on none; "untested" below 2 |
| Proven row (non-investigation) | completed items of N | at least 3 items from at least 2 Domain strata; every owed axis at E2, E3-P or E3-F in at least 2 of them; no E3-F on an axis outside an item's owed set; **the row reports its concept-1 span beside its strata (B7)** |
| Proven `investigation` | completed investigation items | at least 3 items from at least 2 strata whose framings state question, method and time box, with no E3-F on any axis |
| Demonstration (one key or two) | completed items, by concept-1 class | step 7 below; **on the B side, no item carries E3-F on the axis (B9)** |

**Coding scheme (one row per item).**

- **C1 nature.** Run the record's procedure on each acceptance criterion (first yes wins per criterion); the item's primary nature is the one most criteria carry, ties to the earlier step; the others are secondary. No criteria → the proposed change as one unit. A criterion that verifies no change is not classified. Step 5 needs an authoritative statement (B1): a governed file, an ADR or a ratified release plan; an operator comment, directive or scanner alert only once a governed file adopts it — **each `defect` code records its source and the basis for its authority**. The item's **owed set** is the union of its primary nature's owed axes and those of every surface nature (steps 3–4) any classified criterion carries (B2). NO-FIT records the matching candidate. Crosswalk hints (type-map row, `type:` label, requirement type) are recorded; the procedure wins.
- **C2 axis grades.** Quote each graded passage (at most 25 words, with source) and code it to one primary axis: the axis whose "answered when" object is the passage's main-clause object — an entity, field, key, value set or owner → `data`; a step, order, actor, hand-off, decision point or error path → `process-flow`; a part, its location, or what it composes with or depends on → `structure-placement`; a state, a transition, or persistence across a session, phase or version boundary → `behaviour-over-time`. Other axes the passage answers are secondary; grades count on the primary axis only.
- **C3** an uncovered surface with its nearest established viewpoint, or "none". **C4** who set Domain (filer or triage conversion), when stated. **C5** concept-1 class by R-C1..R-C3. **C6** `state_reason`.

**Concept-1 rules.** **R-C1 resolved** — through the item's `milestone` field, to that milestone's release plan (located through the release index), and its `domain_practice` label (B8); `scopemap.py`'s scope-row reading is a cross-check, and its disagreements are reported and never decide the class. **R-C2 inferred** (marked) — the milestone's plan carries no label, or no plan file exists, or the item was completed outside a milestone with a delivering commit identifiable: the class the delivered files fall in under Stage 4 § 5.7, with the basis stated. **R-C3 unresolved** — none of these; counted, never assigned.

**Analysis plan.** (1) Census re-run over the fixed window, deltas reported; the set stays fixed. (1b) State-reason pass: `reason:"not planned"` and `reason:duplicate` searches over the window, with the controls #2344 and #5589 present and #5844 absent. (1c) Concept-1 pass over the pool's completed items by R-C1..R-C3. (2) Re-issue the testability table before coding. (3) Code in sequence order; commit the record's validation table after every batch of at most six items. (4) Time box: a valid prefix has at least three items per stratum (seq at least 9). (5) A candidate nature joins as a hypothesis row iff at least three unmarked NO-FIT items match it. (6) Apply R-a and R-b; grade the rows and the `investigation` row; report the over-owed candidates, the axis co-occurrence matrix, the MULTI rate with the owed-set difference the union causes, and the crosswalk divergence rate. (7) Demonstration, three-valued, per nature: *demonstrated* iff for classes A and B some axis is E2 or above in at least 2 completed N-items of A while at least 2 completed N-items of B show E0 on it and none of those carries E3-F on it; *tested, not demonstrated* iff some class pair has at least 2 completed N-items on each side and no axis meets that test; *not testable* otherwise; the n on each side is printed (B9). (8) Transcribe the AC-5 application with its in-sample label. (9) Transcribe the continuity carry table (B6 plus the Stage-6 row), re-reading each cited section. (10) The AC-6 check with its control arm. (11) Fill every slot; run the verification battery on the artifact and on a mutant (B4).

**Validity threats (declared before findings).**

| # | Threat | Mitigation |
|---|---|---|
| V1 | Selection and coverage: Governance is 88% of the frame; four strata empty; Data is one initiative | balanced quotas; "across domains" limited to the form's populated values |
| V2 | Closed-first skew | at least a third of a large stratum's quota is open; "closed" means completed; marked items enter no count |
| V3 | Construct: the form's Domain is optional and used as a topic label | strata stay the form's values; the one-key-or-two question runs on registry concept 1 |
| V4 | Altitude: items are work-item level; the consumer is epic framing | nature holds at every altitude (#6420 R6); the epic-level test is the calibration framings |
| V5 | Single coder | the codebook rules; quoted grades; Stage 8 blind re-codes the nine-item prefix; nature agreement below 7 of 9 → every row hypothesis |
| V6 | Circularity | the six exclusions; V12 |
| V7 | Instance access | #7540's summary and verbatim quote only; the consumer's records are not read |
| V8 | Missing delivery links | the E2 chain; else E1 at most |
| V9 | Moving population | fixed window, literal seeds, fixed list; Python 3.11.15; census and state-reason deltas reported |
| V10 | Power | the demonstration is testable for at most one nature on one pair; the three-valued outcome |
| V11 | MULTI order bias | per-criterion majority; the step order justified in the record; MULTI rate reported |
| V12 | In-sample application: the four axes came from the measured instance | the record labels AC-5 an in-sample consistency check; the out-of-sample test is the calibration framings |
| V13 | Template-forced and planned-refinement text inflates owed-ness | E2-T and E3-P never make an axis owed; the over-owed statistic |
| V14 | Concept-1 label provenance: many plans carry no label | R-C2 marks inferred values; results resting on them say so |
| **V15** | **The codebook was tuned on drawn items V-03, V-09 and V-12 (B5)** | their boundary examples were replaced with examples from outside the set (#5592, #6201); Stage 8 reports nature agreement as k of 9 (D5's floor applies) and as k′ of the 7 items left once V-03 and V-09 are set aside, and records its codes before opening the record or this plan, #7959's thread, #7971 (where B5 was posted), #7972, #7973, #7991, #7997, PR #8004 or any other issue of milestone 426, except the Stage-8 sub-task's own body (#7974), which the spoke reads for its instructions; that body predates the study and carries no result |

---

## Verification Plan

`ac_baseline: { #7959: 6, read_at: 35dbf41847df2c1deab792d2944e46ac6ddd26fd }` (body revision **2026-09-27T23:01:38Z**). An amendment to any of the six criteria obliges an update to its row in the same change. Each AC row points at a heading of the record; `<record>` below is `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` (its number is reconciled at merge by `renumber-adr.py`, whose branch-scoped citation sweep rewrites this path).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7959 | AC-1 | Named read of the record's § Work natures, § Nature is one key and § Validation set and candidate pool; probe `grep -c '^### Validation set and candidate pool' core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` expect 1; the table parse in § Release-Level Verification | every State is completed, not planned or open; every completed row's class is a concept-1 value or a free name, marked inferred where R-C2 applied; the pool-classes sentence names every class pass 1c found; the testable and not-testable sentence and the Domain-field paragraph are present |
| #7959 | AC-2 | Named read of § Design axes and § Terms; probe `grep -c 'ISO/IEC/IEEE 42010' core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` at least 1 | every axis Source cell names a work, author or body with a year or version; § Terms separates the four other senses (ADR-127's altitude axis, design exploration's distinctness axes, ADR-063's decision dimension, the workspace-layout guide's design principle) |
| #7959 | AC-3 | Named read of § Owed axes by nature and § Calibration trigger; section-scoped probe (B4) `grep -c -z -E '### Calibration trigger([^#]\|[[:space:]])*over-owed([^#]\|[[:space:]])*supersedes this one' core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` at least 1 — `-z` reads the file as one record, and each `([^#]\|[[:space:]])*` run crosses line ends but cannot cross a `#`, so it stops at the next heading and counts 1 only when the over-owed limb and the supersession sentence both sit inside § Calibration trigger (both phrases also occur outside it, in § Status and § Owed axes by nature). The `[[:space:]]` alternative carries the run across a line end under BSD grep, whose `[^#]` never matches a newline even with `-z`; under GNU grep, where `[^#]` already matches one, it adds nothing | every nature row reads proven or hypothesis; inside § Calibration trigger, "supersedes this one", "under-owed", "unnamed axis" and "over-owed" each at least 1, and the revised-in-place sentence present; a mutant deleting the over-owed limb and the supersession sentence fails the scoped check |
| #7959 | AC-4 | Named read of § Coverage states; probe `grep -c 'omitted, not marked not applicable' core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` expect 1 | three states defined; the answered test stated; not-owed axes stated as omitted |
| #7959 | AC-5 | Named read of § Applying the model to the measured instance and § Continuity rule; probe `grep -c 'in-sample consistency check' core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` at least 1 | "in-sample consistency check" and "E2 (reported, unverified)" present; § Continuity rule carries both directions and the stage list including engineering; the carry table has one row per carry naming an enforcing surface, an owning card, or "unowned — recommended home"; #7963 and #7960 under `## References`; the milestone-sequencing sentence present |
| #7959 | AC-6 | `python3` intersection of the record's 12 identifiers with the reserved tokens (pack `kind_id`s in `core/packs/*/pack.toml`, the `type:` kind labels, the `_common` categories); named read of § How the catalog and the toolkit share the key | intersection expect 0 · control: the same check with `story` appended → 1; the key-sharing paragraph states the catalog and the toolkit share the nature key |

### Release-Level Verification (the Stage-7 REDUCE battery; Stage-6 C4 runs it first, on the artifact and on a mutant, B4)

| Check | Method | Pass |
|---|---|---|
| ADR schema | the seven sections in order (`core/schemas/adr-schema.md` § 3) plus `## References` last; `status:` leading token `Proposed`; `## Status` restates it | all present |
| Numbering | `python3 release/tools/check-adr-numbers.py`; the `python3 release/tools/renumber-adr.py --detect` report attached | exit 0 |
| Issue-reference gate | `bash core/deploy/tools/check-issue-ref-validity.sh --path <record>` (and on the standard), with `--resolver fixture` and a map built from connector `issue_read` reads (CI runs the real resolver) | exit 0; a seeded out-of-block `#N` mutant exits 1 |
| ADR durability lint | `python3 release/tools/check-adr-durability.py --files <record> --diff-base origin/main` (R1–R7) | COUNT 0; a seeded `#N` in `title:` mutant flags R4 |
| Slots filled | `grep -c` of the slot marker on the record | 0; a mutant with one slot restored → 1 |
| Change 2 — pointer-free rows | Check 62's own pattern `runner-def:[[:space:]]*[A-Za-z0-9._/-]+::[A-Za-z0-9._-]+` (and the `runner-src:` twin) over the three new rows | 0 on the new rows; 1 on the HSR-1 row as the control |
| Change 2 — Check 62 unchanged | Check 62's verdict and count (or its pointer-extraction pipeline, where `deploy.sh --check` cannot run here) before and after | identical CLEAN count |
| Change 2 — Row A content | Row A carries the three limbs, "Owner:", "Stage-13 close" and a framing-1 line with the concept-1 class field (B9) | all present |
| AC-6 control | the AC-6 intersection with `story` appended | 1 |
| Plan file | `claim-version.sh --verify-stamp work-nature-and-axis-model` exit 0; `check-release-links.py --plan-depth-lint` (workspace-rooted links only); the `verify-release-plan.sh` families `provenance-survival` and `fcm-delivery` | exit 0; PASS or recorded SKIP |
| **D5 — blind re-code (Stage 8)** | before opening the record or this plan, #7959's thread, #7971 (where B5 was posted), #7972, #7973, #7991, #7997, PR #8004 or any other issue of milestone 426 (except the Stage-8 sub-task's own body, #7974, which the spoke reads for its instructions; that body predates the study and carries no result), re-code V-01..V-09 from the codebook sections pasted into the Stage-8 brief: C1 (per-criterion majority) and C2 (a grade per axis); report nature agreement k of 9 and k′ of the 7 items left once V-03 and V-09 are set aside, and grade agreement per axis; state the read order | k at least 7; if k is below 7 → NOT MET, returned to Engineering to set every row to hypothesis and record the figures |
| Check 58 | `deploy.sh --check` lists the record as Proposed with a flip promise | advisory and expected; G-CL9 settles it at Stage 13 |

**ADR index:** N/A — this release adds no record under `release/ADRs/` (`core/ADRs/README.md` is curated and has no projector).

---

## Quota Budget

**Verdict:** PASS (Checkpoint A). Every parallel-safe stage carries a single spoke.
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: 1 · Stage 7: 1 · Stage 8: 1.
**Per-spoke cost estimate:** size:L → the moderate–high ordinal band (source: heuristic).
**Assumed/stated remaining usage-window envelope:** UNSTATED — the conservative default applies [ASSUMPTION – CONFIRM].
**Estimated cumulative draw % (worst parallel batch):** not synthesized, because the basis is UNSTATED; the worst batch is one moderate–high spoke.
**Routing:** PASS: proceed.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`novel`.** Triggers (b) the nature and axis model is a D-class decision and (c) the deliverable is the Stage-5-decided ADR fire; (a) does not fire by the letter (the reference docs, schema and skill ship with #7961). `routine` fails (P2/L, a new file, a D-class decision); `cross-cutting` fails (0 stage files, 0 of the six rule-defining surfaces, 0 in-bundle compositional edges); `hotfix` is not applicable.

- **Differentiation posture:** Engagement **Standard** · Stage 9 review **Deep** · Stage 5 activation **ALL** · outcome window **30-day**.
- **Size bound:** `effective_pts: raw 8 × 1.15 = 9 — below band vs 15-25` (9.2, rounded half-up). The `< 10` disposition keeps it as a single-item gating slice.

---

## Release Outcome Statement

Approved **A″** (Stage-5 round-2 gate, D6; supersedes A′). The milestone-description edit is operator-owned (AI-001 edit 1).

**AFTER** — The platform has one decision record, ratified at this release's close, that names the work natures it recognizes, each with a definition and a boundary example, and the design axes each nature owes, each sourced from established practice. Every nature × axis row is marked proven or hypothesis against a validation set drawn from a stated candidate pool whose delivered items are characterized by deliverable class (registry concept 1); the record says which classes were testable for whether nature needs a second axis, and keeps one key as a stated default where no demonstration held. It applies the model to the measured instance as an in-sample consistency check, states the continuity rule by which an epic's framing carries into its slices and through the later stages — naming where each carry is enforced, which card owns it, or that it is unowned with a recommended home — and registers its calibration comparison and its continuity rule as named gaps with dated observables. The record fixes the work-nature key (one key by default, or nature × deliverable class where a demonstration held) that the decomposition method's cut-pattern catalog and the epic-framing toolkit will share, so the cards held on it (#7960, #7961, #7962) proceed against that key and the successor card #7966 can compose the next epic-framing milestone from it.

**BEFORE** — No work-nature classification and no design-axis model exist in the corpus, so the decomposition method and the epic-framing method each lack the key they need, and the cards that would build the cut-basis vocabulary, the axis toolkit and the framing surface are held. An epic's first framing pass omits the behaviour-over-time axis until an operator names it.

**Actor(s):** a Stage-5 Solutioning spoke (Research-Methodology Design variant), a Stage-6 Engineering spoke and a Stage-8 QA spoke (blind re-coding); the operator at Stage 9 and at the Stage-13 ratification gate.

**Success Indicator:** At Stage 13 the record reads Accepted on `main`, and #7966 records its re-triage of #7960, #7961 and #7962 against the record — or its successor is explicitly deferred — before the milestone is closed.

---

## Rollback Strategy

| Issue | Rollback Method | Rollback Complexity |
|---|---|---|
| #7959 | Before merge: drop the record commit and delete the three register rows. After merge, before A13: `git revert` of the merge commit. After A13 (Accepted): author a superseding record, because an Accepted record is immutable. | Low, rising to Medium over time |

| Strategy | Trigger | Procedure |
|---|---|---|
| Partial revert | the record is wrong before A13 | Revert the record commit and the Change 2 commit. If `renumber-adr.py` moved the record, the revert also removes its § Renumber log line. |
| Full restore | systemic failure after merge | Revert the merge commit and record the rollback; the version tag is retained, never deleted (`core/rules/git-workflow.md` § Tag Retention). After the Stage-12 chore PR this plan sits at `release/releases/plans/v4/v4.NN_RELEASE_PLAN.md`, and the revert must name that renamed path. |
| Forward fix | the model needs recalibration after A13 | The calibration trigger leads to a superseding record; the dependents re-triage against it. |

---

## Operational Deployment Manifest

N/A — enumerated over skill trees, rules mirrors, hooks, templates, config, packages and harness artifacts; the write set contains none of them. ADRs and standards are not deployed to Layer 2. Schema migrations: none.

---

## Action items

| id | owner | category | description | status |
|---|---|---|---|---|
| AI-001 | operator | deferred-edit | Milestone 426 description: edit 1 replaces the Release Outcome Statement with **A″**; edits 2 (the version-axis line) and 3 (the Composition Lock block) unchanged | open |
| AI-002 | operator | deferred-edit | Replay the staged pipeline-event rows on the operator instance (Stage 4, scaffold, Stage 5 rounds 1 and 2, and this Stage-6 spoke's rows) | open |
| AI-003 | hub | cross-issue-merge | Before Stage-13 C1: #7966 records its re-triage of #7960, #7961 and #7962, or its successor deferral is recorded on #7966 and #7540 | open, not yet due |
| AI-004 | operator | decision-deferred | Where Stage 6 runs | resolved (round-1 D3: the hub's cloud session) |
| AI-005 | hub | cross-issue-merge | Stage-12 keep-both merge on `core/standards/gate-efficacy-standard.md` with **#7919 and #7901** (widened, round 2) | open |
| AI-006 | hub | decision-to-post | Revise the A′ Release Outcome Statement | resolved (round-2 D6: A″) |

---

## Deviation Log

| # | Severity | Deviation | Authority / rationale |
|---|---|---|---|
| DEV-1 | minor | The Commit-0 re-verify's step 2 did not run `claim-version.sh --dry-run`: its published-Releases arm shells out to `gh`, which this environment lacks. The three arms were read directly — tags from `git fetch --tags`, published Releases through the GitHub connector (`get_latest_release`, `list_releases`, `list_tags`), the ledger from `origin/main`. | The hub brief's venue clause (connector substitutes for `gh`, each recorded as a deviation). Result agrees with the Stage-4 determination. |
| DEV-2 | minor | Both `CONDITIONAL:S5-PLACEMENT-RELEASE` rows — `release/ADRs/ADR-*-design-axes-and-cut-patterns-key-on-work-nature.md` (add) and `release/ADRs/README.md` (edit) — are NOT DELIVERED: Stage 5 placed the record in `core/ADRs/`. | Stage-5 D-Placement (revision 1, carried in revision 2); Change 3 item 2. |
| DEV-3 | minor | `core/standards/gate-efficacy-standard.md` enters the matrix as an unconditional `edit` (Rows A, B, C), which Stage 4 did not plan. | Stage-5 round-1 D2 (a Tier-2 scope change, operator-approved) and round-2 D3 (Row C, two-row Row B). |
| DEV-4 | minor | The `ac_baseline` body revision moves from the Stage-4 value (13:23:59Z, then 15:41:37Z at the Stage-4 gate) to **2026-09-27T23:01:38Z**. | Stage-5 round-1 D6/D7 (18:36:40Z) and round-2 D4/D7 (23:01:38Z). |
| DEV-5 | minor | The Release Outcome Statement is A″, not the Stage-4 gate's A′. | Stage-5 round-2 D6. |
| DEV-7 | minor | Row B (the two-row Version History variant) gains one clause beyond the Stage-5 literal: the continuity line "compares each slice's framing with its parent's and is emitted only once the slice-body Framing carry section it reads ships". Without it Row B would say a skipped continuity check shows as a stale date, which Row C (a′) now states is not true before the carrier ships. | Round-2 D3 (Row C's comparing observable states it cannot emit until the carrier ships); the literal predates D3. |
| DEV-8 | informational | The study's read-only passes 1, 1b and 1c (census, state reason, concept 1) ran before the record and rows were committed, and their results enter the record in the study commits. No file was written before the scaffold commit. | Order of work; reads only. |
| DEV-9 | minor | Pass 1c located each milestone's plan through `release/releases/RELEASE_INDEX.md` (milestone → version → plan file), because most plans declare no milestone field; where a milestone had no plan file (v2.41) or no milestone (ten items), R-C2 read the delivering commit that cites the item (`git log --all --grep`) rather than a closing comment's citation. | B8 names the `milestone` field as the path; the index is the corpus's own version ↔ milestone projection. Each inferred basis is recorded. |
| DEV-10 | minor | **Coding interpretations the codebook left open, applied uniformly to all 31 items.** (a) E2 chain read order: the commits citing an item were read first; where an axis lacked E2 there, the closing PR body, the milestone's release PR body and the Stage-5 output were read before settling a lower grade — the chain's sources, not its order, decide the grade. (b) A PR body's Summary is not template-forced (not E2-T); the Implementation, Documentation Impact and Verification Evidence tables and a release Outcome Statement's required fields are. (c) V-12 has no closing PR and no citing commit; the closure record names commit `0b9a339a` (dated before the item was filed) as the delivering change, and it was graded as such. (d) Per-criterion majority counts a criterion that fits no nature under the candidate it matches; an item whose majority is a candidate fits no nature, and it counts toward that candidate's admission only if none of its criteria carries a nature (V-22 and V-23 do not count; V-17 and V-27, whose one other criterion matches the other candidate, do). (e) A criterion that records a measurement of the existing state is a recorded baseline and is not classified (V-18 AC5, V-26 AC1); read as `investigation`, V-26's AC1 would tie with its `defect` criterion and make the item an `investigation` owing no axis. (f) An open item's body revised after the frame cutoff (V-25, revised 16:15:44Z) is graded on the sections the revision kept; the connector serves no edit history. | The codebook (record § Classification procedure, § Grades; plan § Validation Study Design) is silent on each; each reading is recorded per item in the run's codes log and repeated in the Stage-8 hand-off so the blind re-code applies the same reading. |
| DEV-11 | minor | **Two boundary examples sit beside drawn items, beyond the three B5 names.** `restructure`'s ("Collapsing hand-copied constants into one library") describes V-21's subject (#4198), and `infrastructure-change`'s ("Bounding CI suite run time") describes V-22's AC2 (#7418). Both examples are unchanged from revision 1; neither item is in the D5 nine. Disclosed in the record's § Validation set; both codes marked. Under B1, V-21 codes `defect` (the duplicate-source rule, `core/standards/duplicate-source-discipline.md` § 1, binds inside `core/`), so the `restructure` example and step 5 collide wherever that rule binds. | Found while coding; changing a codebook example mid-coding would change the instrument, so it is disclosed rather than edited — an operator call for Stage 13 (keep, or replace from outside the set). |
| DEV-12 | minor | **Candidate admission completed the procedure.** Both candidates met their pre-set admission rule, so their rows moved into the natures table (the slot's instruction) and the procedure gained steps 7 (`restructure`) and 8 (`behaviour-change`) plus one "Why this order" sentence, so the admitted natures are reachable by the procedure. The step text restates each definition; nothing else in the procedure moved. | The record's own admission rule and slot; the step text is beyond the slot's literal words, hence recorded. |
| DEV-13 | informational | **Shallow clone.** The local history begins 2026-06-05 and omits commits on squash-merged release branches; commits named in a PR body but absent locally (V-09's `aae4e4eb`, `a5b701ce`) were read through the connector's `get_commit`. Local `git log --all --grep` found every other citing commit used. | Environment; recorded so Stage 7 can reproduce the reads. |
| DEV-14 | informational | **Author-reading divergences and B1 probes.** Nine items' own text or triage called them a defect (V-03, V-08, V-18, V-20, V-22, V-25, V-26, V-28, V-30); the procedure coded four as `defect` (V-18, V-25, V-26, V-28) and five otherwise — V-03, V-20, V-22 and V-30 `behaviour-change`, and V-08 `infrastructure-change` because step 2 fires first. Where a code turned on whether a quotable authoritative statement existed, the codes log records the probe: V-03 (G1-03's governed self-repair text), V-05 (fix-forward and scanner-alert policy searches over the governed trees), V-14 (the quota protocol's § 4.3b scope; the tool site at `35dbf418`), V-19 AC2 (Check 34's "opt-in by manifest presence" header), V-20 (`build_chore_pr_body` and `stage-13-close.md`), V-22 (the guard's "newly-wired steps" success line), V-23 AC2 (the parity tool's header at `94296f35`), V-26 AC2 (the egress hook's stated premise, which made it a `defect`), V-30 (the depersonalization spec's scope). | B1 (each `defect` code records its source and authority basis); the probes stand as the zero-claims' evidence. |
| DEV-15 | minor | **One word of the Stage-5 procedure text reworded for Check 63.** `deploy.sh --check` Check 63 (count-vs-structure, enforcing) read "the item's nature is the one most of its criteria carry" as a stated count of one above the procedure's numbered steps. The phrase now reads "the nature most of its criteria carry"; the meaning is unchanged, and the lint passes on the record (FAIL=0). The phrase dates from the Stage-5 scaffold, so the finding predates the fill. | Hook-Response Discipline move 1 (reword when the control's objection is to the text and the meaning is unchanged); recorded as a control firing in the Stage-6 output. |
| DEV-16 | minor | **Pre-filing authority text for V-15 and V-21.** The coding log quoted both items' step-5 authority, `core/standards/duplicate-source-discipline.md`, from the file's current text: "(a) … (b) … (c) … or (d) …" for V-15 and "unless one of four conditions holds" for V-21. The text in force when each item was raised is at tag `v2.30` for V-15 (tagged 2026-06-26T21:45Z; #2156 filed 22:23Z) and at tag `v3.99` for V-21 (tagged 2026-07-29T00:47Z; #4198 filed 01:28Z), and the file is unchanged at the next tags, `v2.31` and `v4.01`. That text lists (a)–(c) and reads "unless one of three conditions holds". V-15's code rests on (b), consolidation to a single canonical source with cross-references replacing the duplicate sites, which `v2.30` carries. V-21's rests on the register-or-remove rule itself; its three conditions are the first three of today's four, so copies that meet none of the four meet none of the three. Both codes stay `defect`, and no code, count or grade changes. | B1: step 5 needs an authoritative statement recorded before the work was raised. Stage 7 verified that the pre-filing text supports the same codes (#7973 comment 5862203943, F-05). |
| DEV-17 | informational | **The pass-1c concept-1 list is published.** The record's pool-level class counts rest on pass 1c's list of the candidate pool's 112 delivered items, which lived only in the run directory. It is now published in the DT iteration-1 comment on #7972 ("Stage 6 Engineering — DT iteration 1 (fix(dt)) — work-nature-and-axis-model"), in a collapsed block with its probe record: one row per item, giving the number, Domain value, milestone, plan, class, and resolved, inferred or unresolved with the basis, plus B8's scope-map cross-check. Recounted from the published rows, the list reproduces the record. Governance's 108 split into 80 `governance` (21 inferred), 25 `software` (6 inferred) and 3 unresolved; Software's 2 and Data's 2 fall as the record states; 83 `governance` and 26 `software` in all; the Domain name agrees for 81 of the 109 classed items. | Stage 7 could not re-derive the inferred limb without the list (#7973 comment 5862203943, F-06). The record is unchanged. |
| DEV-18 | minor | **AC-3's section-scoped probe was GNU-grep-only, and was replaced.** Iteration 1 assumed that `-z`, by reading the file as one record, makes a newline an ordinary character, so `[^#]*` crosses lines and stops only at the next heading. That held where the probe was first run, the hub's cloud session (a GNU userland [INFERRED]). On the operator's host, where Stages 8–13 run and the executor's pinned `PATH` resolves `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD), `[^#]` never matches a newline, even with `-z`: the probe counted 0 on the clean record, so `verify-release-plan.sh` graded a correct record FAIL, and the B4 mutant alike. Each `[^#]*` is now `([^#]\|[[:space:]])*`, the pipe escaped for the table cell and healed by the executor before it runs the probe: a run of characters other than `#`, which the whitespace class carries across line ends under either grep. Through the executor on this host the clean record PASSes with count 1, and the B4 mutant, each single deletion, both phrases moved out of the section, and a heading inserted between them each FAIL with count 0. The GNU arm is reasoned, not observed, because GNU grep is not installed here: where `[^#]` already matches a newline, the alternative adds nothing, so the probe matches the same text the iteration-1 form matched there. | Stage 7 pass 2 re-opened F-02 (#7973 comment 5943332241); the hub reproduced it on this host and rendered it fix-now (#7973 comment 5943382669). |
| DEV-6 | informational | A third sibling now claims ADR slot 207: #7919 (`controls-fail-loud`, head `7ff5a9cd`) adds a `core/ADRs/` record at slot 207 under its own slug, which the Stage-5 contention read (heads `99d36318`, `341c8c8`) did not show. The resolution is unchanged — author at the mainline next-free, renumber at merge. | Contention re-read at Commit 0 (hub brief: sibling heads re-read live). |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit(s) | Notes |
|---|---|---|---|---|
| #7959 | None — no documentation impact (rationale: the deliverable is the decision record itself; the reference docs that carry the classification and the toolkit ship with the cards this spike gates) | NONE | — | the record and its register rows are the deliverable |

**Deliverable state:** `artifact-accepted` — the record at its declared canonical path, with its Artifact-Acceptance Record row populated in § Verification Evidence at Stage 13 (a task-class deliverable; no deployed copy).

---

## Verification Evidence

Populated at C4 self-verification (Stage 6), then re-run at Stage 7.

- **Commit-0 step 3b** — `bash release/tools/claim-version.sh --verify-stamp work-nature-and-axis-model` → exit **0**, "verify-stamp OK — work-nature-and-axis-model carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". Sensitivity arm (PV-2a mutation form): the same file with the placeholder replaced by a literal version → exit **1**, "verify-stamp TOKEN-LESS PLAN"; the original was restored from a copy and re-counted at exactly one placeholder.
- **Scaffold C4 (before the record's study commits; artifact and mutant, B4):**
  - `python3 release/tools/check-adr-numbers.py` → "PASS (207 ADRs, contiguous 001..207, no duplicates)", exit 0. `python3 release/tools/renumber-adr.py --detect` → ANCHOR 206 (origin/main) · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY 207,208,209,210.
  - `python3 release/tools/check-adr-durability.py --files <record> --diff-base origin/main` → SCANNED 1 · COUNT 0 (R5 and R6 active). Mutant (a fixture root holding the record with an issue reference seeded into `title:`) → R4 flagged, COUNT 1; the unmutated fixture → COUNT 0.
  - `bash core/deploy/tools/check-issue-ref-validity.sh --resolver fixture --fixture-map <map> --path <record>` → exit 0 (the map lists each `#N` the record carries as `valid`, each confirmed an issue in this repository by a connector `issue_read`; CI runs the real resolver). Mutant (an issue reference seeded into § Context) → exit 1, flagged at line 23. On `<standard>` the gate reports the file's own `allow-issue-ref` marker and skips it, so the rows are checked directly: 0 issue references in the three new rows.
  - Change 2: Check 62's own pattern over the three new rows → **0**; over the HSR-1 row → **1** (control). The superseded check `grep -cE 'runner-(def|src):'` would count **2** on the new rows (their "No `runner-def:` pointer is recorded" sentences) — the over-match B4 retired. Check 62's extraction (`_rr_compute_verdict`'s own `grep -o` patterns) over the standard at `origin/main` and on the branch → 31 `runner-def` + 3 `runner-src` declarations both times, byte-identical, so its count and verdict cannot move. Row A carries the three limbs, "Owner:", "Stage-13 close", the `<concept-1 class>` field and the framing-1 line.
- **Plan links** — the plan carries no markdown link sequence (a count of the link-opening sequence over this file → 0), so the plan-depth lint has nothing to grade. `check-release-links.py --plan-depth-lint --files <this plan>` reported "0 files", a vacuous run, recorded as such rather than as a pass.
- **Validation study (six batch commits `0d0089c8` … `eec5ddd8`, then the fill commit `7496458c`).** Each batch of at most six coded items was committed and pushed as it landed, the issue-reference gate and the durability lint re-run on the record before each commit (exit 0 · COUNT 0 every time). The per-item codes, quotes and sources are in the run's codes log (`${SCRATCH_BASE}/spoke-6-7972-qmCYrV/codes.md`); the record carries the table and its summary.
- **Final C4 (after the fill commit; artifact and mutant, B4).** Mutants are copies of the filled record in fixture roots under the run directory, one seeded defect each.
  - Slots: `grep -c '⟦' <record>` → **0**; mutant (one slot restored) → **1**.
  - Numbering: `check-adr-numbers.py` → "PASS (207 ADRs, contiguous 001..207, no duplicates)", exit 0; `renumber-adr.py --detect` → ANCHOR 206 · NEXT-FREE 207 · CLAIMED-SET-BRANCH-ONLY 207,208,209,210 · this record's CLAIM ADR-207 BINDS BRANCH-CLAIM (renumbers at merge if a sibling lands 207 first).
  - Durability: `check-adr-durability.py --files <record> --diff-base origin/main` → SCANNED 1 · COUNT 0; the clean fixture → COUNT 0; the `title:` mutant → R4 flagged, COUNT 1.
  - Issue-reference gate with the fixture map (38 numbers, each confirmed an issue in this repository by a connector `issue_read`) → exit 0; the § Context mutant → exit 1, flagged at line 23 ("resolves but is placed outside a designated reference").
  - AC probes on the record: AC-1 heading 1; AC-2 `ISO/IEC/IEEE 42010` 1; AC-3 inside the extracted § Calibration trigger — "supersedes this one" 1, "under-owed" 1, "unnamed axis" 1, "over-owed" 1, "revised in place" 1; the AC-3 mutant (over-owed limb and supersession sentence deleted) → 0 and 0, so the scoped check fails; AC-4 1; AC-5 "in-sample consistency check" 1, "E2 (reported, unverified)" 1, the carry table 11 rows with an engineering row, both cards under `## References`; AC-6 — the 12 identifiers against pack `kind_id`s {card, epic, story, task}, the `type:` kinds and the 12 `_common` category labels → intersection **0**; control with `story` appended → **1**.
  - Change 2 (the standard is unchanged since the scaffold commit): Check 62's own pattern → 0 on the three new rows, 1 on the HSR-1 control row; its extraction over the standard → 31 `runner-def` + 3 `runner-src`, byte-identical to `origin/main` (`cmp` silent); Row A carries every required element.
  - Plan: `claim-version.sh --verify-stamp work-nature-and-axis-model` → exit 0 ("verify-stamp OK … plan-only manifest"); exactly one braced version placeholder; the plan-depth lint again vacuous (0 link sequences).
  - `verify-release-plan.sh --format=table <this plan>` exits **3** ("one or more checks FAIL or ERROR"; this bullet first recorded exit 0, corrected under F-03). Its 26 rows: the per-issue rows AC-1..AC-5 PASS; `fcm-delivery` PASS ×4; `provenance-survival` PASS ×3 plus a named SKIP (the Stage-4 delta limb, no comment supplied). Eleven rows return ERROR: AC-6 and nine release-level rows are `unclassified`, because their methods are prose or multi-command, which the executor cannot dispatch; the Slots row is classified per-issue, but its backticked `grep -c` names no pattern or file, so its count is unreadable. The two rows it routes to `sync` (Check 62 before/after; Check 58) return FAIL, because `deploy.sh --check` exits 1 on this host. Each ERROR row was run by hand above; the `sync` rows are read from `deploy.sh --check` below.
  - `deploy.sh --check` (run on the branch in this environment; about seven minutes, Check 43 alone about four): exit 1, "165 issue(s) found". **Check 14 (doc-link integrity) OK** — "no broken cross-refs in scope"; Check 31 (reference durability) OK; Check 59 OK for this plan's slug-primary identity; **Check 62 OK — "all 34 gate-coverage register resolution pointer(s) resolve"**; Check 58 ADVISORY — "5 of 7 Proposed ADR(s) carry flip-promise wording", this record among them, settled by G-CL9 at Stage 13. One finding named a changed file: **Check 63 (count-vs-structure, enforcing) flagged `<record>`:54** — "the one most of its criteria carry" bound "one" to "criteria" as a stated count of 1 against the procedure's eight steps. The phrase was reworded to "the nature most of its criteria carry" (meaning unchanged; DEV-15), and `check-count-structure.py --path <record>` then returns FAIL=0. No other finding names a changed file. Check 7 fails on this host's `stat` output (`deploy.sh:3829: Inodes: unbound variable`), and the remaining issues come from absent operator-instance paths and the offline `gh`.
- **DT iteration 1 (the `fix(dt)` pass after Stage 7, #7973 comment 5862203943).** Mutants are fixture copies under the run directory, one seeded defect each.
  - AC-3, dispatched (F-02): the row's probe is now the section-scoped `grep -c -z -E` form, which `verify-release-plan.sh` runs as a per-issue row. On a byte copy of this plan outside the tree, with `--root` set to a fixture root holding the record: the clean copy → `count=1 (>= 1)` PASS; the B4 mutant (over-owed limb and supersession sentence deleted from § Calibration trigger) → `count=0 (wanted >= 1)` FAIL; both moved out of the section into § Reversibility → FAIL. The pre-fix probe on the same B4 mutant → `count=1 (>= 1)` PASS, the defect Stage 7 reported. Direct `grep` on the single-deletion mutants (the limb only; the supersession sentence only) → 0 each. A grep without `-z` exits 2, which the executor reports as ERROR, never PASS.
  - Per-issue rows on mutants (B4): the same fixture plan against four more fixture roots, each with one probed phrase removed from the record (the § Validation set heading renamed; `ISO/IEC/IEEE 42010` shortened; "omitted, not marked not applicable" shortened; "in-sample consistency check" shortened). AC-1, AC-2, AC-4 and AC-5 each FAIL on their own mutant and PASS on the other three; the clean root passes all five.
  - ADR schema (F-04), in the row's own terms (`core/schemas/adr-schema.md` § 2–3): the six required frontmatter fields, an ISO `date`, the seven sections in schema order, `## References` last, the `status:` leading token `Proposed`, and `## Status` restating it → 11 of 11 on the record. Four mutants each fail only their seeded assertion: Alternatives Considered and Consequences swapped (order); § Status restating `Accepted` (restatement); an H2 appended after References (References last); `deciders:` removed (frontmatter).
  - Executor re-run after F-01 and F-02 (F-03), at `a6a96772`: exit **3**, 26 rows — PASS 12 (AC-1..AC-5, AC-3 now by the dispatched probe; `fcm-delivery` ×4; `provenance-survival` ×3), ERROR 11 (10 `unclassified` and the Slots row), FAIL 2 (the `sync` rows), SKIP 1 (the provenance delta limb). These are the same counts as the run above.
  - Rows with no Stage-6 mutant arm — numbering, Check 62 unchanged, Row A content, the executor's `fcm-delivery` and `provenance-survival` families, and Check 58 — were each run on the artifact and on mutants by the Stage-7 battery (#7973 comment 5862203943).
  - The plan's own checks after the F-01..F-07 edits, at `be057b42`, each on the artifact and on a mutant. The issue-reference gate (fixture resolver) → exit 0 in place, because it exempts `release/releases/*`, so that arm is vacuous by design; the same bytes at a non-exempt path → exit 1 (185 findings). `claim-version.sh --verify-stamp` → exit 0; the placeholder replaced by a literal in the tree → exit 1 "TOKEN-LESS PLAN", then restored from a copy (`cmp` silent, `git diff` clean). `check-release-links.py --plan-depth-lint` → 0 findings over 0 link sequences (vacuous); its `check_plan_depth` on a copy with one relative link → 1, and with one workspace-rooted link → 0. `check-count-structure.py --path <this plan>` → NOT-EVALUATED under the frozen-artifact exemption; with `--no-exempt` → FAIL=0 (0 pairs examined, its own controls PASS); a copy with a seeded preamble stating two items above a three-item list → FAIL=1. The parser-clean grep for a close-family verb before an issue number → 0 (37 lines at `be057b42` carry such a verb, none before a number); a copy with one seeded → 1.

---

## Change Description

### Outcome

The platform gains one decision record, `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` (`status: Proposed`, flipped at the Stage-13 ratification gate), that names eight work natures and the four design axes each owes, classifies work by a stated per-criterion procedure, and grades every owed-axis row against a 31-item validation set drawn from the improvement form's filings. Two named gaps and a Version History row in `core/standards/gate-efficacy-standard.md` make the calibration comparison and the continuity rule observable once their surfaces ship.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #7959 | The work natures (six, plus `restructure` and `behaviour-change` admitted from candidates), the four design axes with their sources in practice, the owed-axis table graded — `defect` proven within one deliverable class, every other row a hypothesis — the three coverage states, the continuity rule with its carry table, and the calibration trigger | DONE (pending Stage 8's blind re-code, D5: a nature agreement below seven of nine sets every row to hypothesis) |

### Key decisions

- **One key, by default** — the one-key-or-two question was not testable for any nature (no nature has two delivered items in both deliverable classes); the record keeps the conditional key sentence (B10).
- **Both candidates admitted** — `behaviour-change` (six items fitting it and no other nature) and `restructure` (three, the floor); the procedure gains steps 7 and 8 (DEV-12).
- **`defect` proven** — six delivered items across two strata, and still proven with its tuned items and the item beside the `restructure` example set aside; its proof spans `governance` only.
- **No mark moved** — no item carries E3-F, so the owed-axis rule changed nothing; over-owed candidates are "none" for `defect` and `behaviour-change` and untested elsewhere.
- **Carry table** — stage-to-stage carries ride the slice-body Framing carry section (D2); the carry of silent and not-applicable axes into slices is unowned, with the framing-to-cut card as its recommended home (B6).
- Stage-5 round-2 decisions D1–D8 and amendments B1–B10: § Decision Record → Amendments applied.

### Reversibility

CHEAP / HIGH before the Stage-13 ratification gate — revert the record and Change 2 commits (or the single release merge); after ratification the record is immutable and a change takes a superseding record (MODERATE).

### Downstream impact

- The framing-to-cut and cut-basis cards (#7963, #7960) build on the key, the owed-axis table and the Framing carry section; the successor card #7966 composes the next milestone after ratification.
- The design-axis toolkit and the cut-pattern catalog cite this table or reproduce it as a declared projection.
- Carry-forward to the operator at Stage 13: whether to replace the two boundary examples that sit beside drawn items (DEV-11); whether to widen the framing-to-cut card to silent and not-applicable axes (B6).
- Stage 8 re-codes V-01..V-09 blind from the codebook sections named in the Stage-6 output; the D5 floor decides whether `defect` stays proven.

### Cross-references

- Release plan: `release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md` (this file; renamed to its versioned form at the Stage-12 claim).
- Milestone: `work-nature-and-axis-model` (milestone 426), `https://github.com/cody-hutson/pmo-platform/milestone/426`.
- Release PR: #8004. User-facing release notes: authored at Stage 13 under `release/releases/notes/`.

---

## Baseline pin

`origin/main` @ `35dbf41847df2c1deab792d2944e46ac6ddd26fd` (2026-09-25T16:17:45Z), the Stage-4 audit-start baseline; unmoved at Commit 0.

---

## Issue References

- #7959 — the one member: the joint spike deciding the work natures and the design axes each owes
- #7969 — Stage-4 Release Planning sub-task: the approved plan and its gate record
- #7971 — Stage-5 Solutioning sub-task: the design (revision 2) and both gate records
- #7972 — Stage-6 Engineering sub-task
- #7997 — the round-2 adversarial design review behind B1–B10
- #6420 — the decomposition-method epic (parent)
- #7540 — the epic-framing epic: the measured instance, the calibration trigger and the continuity ask
- #7960, #7961, #7962, #7963, #7966 — the held cards and the successor card
- #7919, #7901, #7839, #7895, #7931 — the in-flight sibling releases
