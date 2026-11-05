---
title: Release Plan — sequencing-layer-foundation (dependency edges read directed from one parser, and every chain head in one view)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v5.02; the concrete number binds at the Stage-12 atomic claim)
milestone: sequencing-layer-foundation
release_class: novel
reversibility: CHEAP / Confidence HIGH — one branch and one merge; reverting the merge restores both tools, the parser's section extractor and the documents byte-for-byte, and nothing outside the tree persists (no milestone carries a position, the dependency mirror only ever adds author-declared edges, and the chain-head view writes nothing). It becomes MODERATE only once a later reader builds on the parser's shared section-read home. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `sequencing-layer-foundation`

**Milestone:** `sequencing-layer-foundation` (milestone 411; epic #6443). The Stage-4 planning sub-task **#8664** carries the approved plan (`#8664 comment 6662630799`) and the Stage-4 gate's Decision Recorded (`#8664 comment 6662940952`). The Stage-5 designs are on **#8695** (#7177, `#8695 comment 6664324331`), **#8699** (#6397, `#8699 comment 6664326625`, which carries the same joint S5-D1 block) and **#8703** (#6398, `#8703 comment 6663998167`); their independent Phase A6.5 adversarial reviews are on **#8777** (#7177), **#8778** (#6397) and **#8780** (#6398). The Collective Review scope-lock Decision Recorded is `#8695 comment 6665179890`. The Stage-6 Engineering sub-tasks are **#8696** (#7177), **#8700** (#6397) and **#8704** (#6398); this file is Engineering Commit 0, authored by the spoke on **#8696**, which also builds #7177's slice.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v5.02`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. Milestone 438 (`guards-judge-every-spelling-alike`) recomputes the same next-free slot, so whichever release merges first claims it and the other takes the next.

**Topology:** D-C **SINGLE** — one release branch, `release/sequencing-layer-foundation`, one pull request opened in **draft** at Stage 6 Phase C2 after #7177's slice, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — #7177 → #6397 → #6398, one Engineering spoke at a time, each landing on the release branch before the next starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel` — Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8664 and is amended by two decision records, in order: the Stage-4 gate's Decision Recorded on #8664 (plan approved with the milestone's Release Outcome Statement kept verbatim; `novel`; SINGLE; P0; D-Version recorded), and the Collective Review scope-lock Decision Recorded on #8695 (scope hard-locked through Stage 9; D-7177-Extractor; D-6397-Negation; D-6398-AC6; D-6398-Standing; the recorded alignments; the Stage-6 fixes; the items held for the Stage 9 follow-up ledger). The three Stage-5 designs and the approved findings of their adversarial reviews are design inputs as that record adopts them. Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log with the decision that caused it. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): tool behaviour changes, a new release tool, and gate and reference text added inside existing structure, per the Bump-Class Selection Guide's "protocol text addition or modification" and "reference document addition or update"; no new skill and no new governance file. Provisional display `v5.02`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-05 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file and the shared-home ADR), then #7177's slice, then #6397's and #6398's slices in their own spokes |
| **Branch** | `release/sequencing-layer-foundation` |
| **PR** | opened in **draft** at Stage 6 Phase C2 after #7177's slice; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `sequencing-layer-foundation` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-05, domain: software }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform artifact — release tools, their tests, a CI workflow, an allowlist and a manifest, two ADR records, a gate specification, a taxonomy, a standard and a roadmap README — so no external body of practice is consumed. Dominant domain **`software`** (release-tooling code); secondary domain governance (gate text, taxonomy and roadmap documents). Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `b1042eec` (`b1042eecd6294d4c460c109f2c4b8dd6ed9896a9`), equal to the hub's read at Stage 5 and to the Commit-0 base. This file is written on that base |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha b1042eecd6294d4c460c109f2c4b8dd6ed9896a9 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v5.02`** (exit 0; "would claim v5.02 (no tag pushed)"), equal to the Stage-4 provisional display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan that compares exact (major, minor) version
             tuples carrying no patch component
Denominator: 456 ls-remote lines (222 distinct versions; the highest is v5.01); 227 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             2,934 lines
Control - sensitivity: the same scan on the v5.01 slot — 2 tag lines, 1 Release line and
             7 ledger lines. Every arm returns non-zero, so a zero on the v5.02 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality,
             so v5.0.2 and v5.020 are different tuples, not prefixes)
Extraction:  the whole ls-remote output (26,701 bytes), the whole Release list (22,101 bytes)
             and the whole ledger (944,477 bytes) read from origin/main, never the worktree copy
Result:      0 occupants of the (5,2) slot on every arm
Verdict:     CLEAN — v5.02 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** one sibling release in flight — `release/guards-judge-every-spelling-alike` (milestone 438, draft #8651, head `fc556c66`), bump-class minor, which recomputes the same `v5.02` slot. That is the Stage-4 Tier-S serialization edge (R-7); it binds at whichever Stage-12 claim runs first and is not a HALT condition here.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp sequencing-layer-foundation`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-05`** (Thursday). It fills the one load-bearing date identifier slice 1 creates: the shared-home ADR's frontmatter `date:`. The chain-head ADR that slice 3 authors carries the same resolved value. No path, verifier identifier or audit folder in this release carries a date.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 and Collective Review conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-4` (CIAC-3 restated under D-7177-Extractor, DEV-4) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as Stage 5 and the scope lock resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA; the Commit-0 base is recorded beside it) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Title | Disposition |
|---|---|---|---|
| #7177 | P2 | extract_section returns an empty section when a heading carries two blank lines, so a declared dependency silently vanishes | carried; Stage-5 design on #8695 with its A6.5 review on #8777; the extractor remedy replaced by D-7177-Extractor at the scope lock, AC5 restated in the body; slice 1 |
| #6397 | P2 | bundle-issues-parser scrapes every #N as an undirected dependency, so milestone sequencing derives from reversed and hierarchy edges | carried; Stage-5 design on #8699 with its A6.5 review on #8778; D-6397-Negation at the scope lock; slice 2 |
| #6398 | P2 | Render every chain head in one view — derived initiative and lone-epic cards with drill-down to epics and children | carried; Stage-5 design on #8703 with its A6.5 review on #8780; D-6398-AC6 and D-6398-Standing at the scope lock, AC6 restated in the body; slice 3 |

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| The epic rollup-close audit reading a failed child read as "no children" | found by an A6.5 review; outside this release's capability boundary | the Stage 9 follow-up ledger (held, not filed) |
| The release-planner `Hard`-row divergence from `parse_dependencies` | the Mode A doc row does not change in this release (S5-D3) | the Stage 9 follow-up ledger (held, not filed) |
| `release/tools/verify-release-plan.sh:3359`'s stale parser line cite | a comment in a file this release does not edit | the Stage 9 follow-up ledger (held, not filed) |
| Native-edge reads (GraphQL `blockedBy`) for sequencing | #6426 proposes them; this release keeps the body grammar per #6397 AC1 | #6426 in milestone 410, sequenced after this release |
| A third Acceptance Criteria presence state in Check 22 | `core/deploy/deploy.sh` is read-only here | the shared acceptance-criteria reader card (#7678, compose slot b21), which merges after this release |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-05)

| Decision | Rendered |
|---|---|
| D-PlanApproval | **Approved as posted**; the milestone's existing Release Outcome Statement is kept verbatim |
| D-ReleaseClass | **`novel`** (Stage 9 Deep, Stage 5 for every card, 30-day outcome window) |
| D-Concurrency | **P0, fully serial** |
| D-C branch topology | **SINGLE**: one branch `release/sequencing-layer-foundation`, one PR, one merge |
| D-Version | **Recorded, not asked:** bump class minor; provisional `v5.02`; milestone 438 computes the same slot and the first merge claims it |
| Per-card disposition | #6397, #7177 and #6398 carried. Sequence Commit 0 → #7177 → #6397 → #6398, the first two reversible at Stage 5 (Stage 5 confirmed the order) |
| Hub follow-through (Tier 1 [ADJUST]) | the Parallelization Map entered the milestone description; the card-body re-pins and the criteria and Documentation Impact edits landed on the three cards with why-comments; Stages 5–13 were scaffolded |

### Collective Review scope lock (operator, 2026-11-05)

| Decision | Rendered |
|---|---|
| D-CRLock | **Approved**: three cards, designs approved with the decisions below; Engineering authorized; scope hard-locked through Stage 9 |
| D-7177-Extractor | **The A6.5 counter-design.** A section ends at the next heading or a `---` line; the two-blank-line terminator is removed; the return stays a plain string (`None` only for an absent heading); there is no `SectionRecord` / `DegradedSectionRecord`; AC5 is restated, because the "cannot locate" case no longer exists |
| D-6397-Negation | **Fix the negated-label case** ("not blocked by") inside the shared grammar, in #6397; its AC2 covers it |
| D-6398-AC6 | **AC6 retires the interim board's portfolio map only**; the hand-ordered milestone lanes stay until #6443 ships; AC6 is restated in the body |
| D-6398-Standing | **Standing is declared by the label description's first word `Standing`**, plus a guard that fails loudly when no initiative reads as standing |

**Recorded alignments (Tier 1 [ADJUST]):** both new ADR records are written `Proposed` and ratified at Stage 13; their numbers bind at merge through `release/tools/renumber-adr.py` (mainline next-free was 230, and other branches hold 230 and 231 provisionally). `_epic_child_set.py` is recorded as net-new, because the rule it shares lives inline in a shell script and cannot be loaded in place.

**Stage-6 fixes applied regardless (from the A6.5 reviews):** a missing `parent_issue_url` key means no parent, not unreadable (FM-1, slice 3); a section-presence facet plus the native blocked-by count in the #6398 view (CD-1, slice 3); type hints in the parser use only names it imports — no `Union` (slice 1); no `from __future__ import annotations` in `native-dep-mirror.py`, because it breaks that file's test loader under Python 3.9 (slices 1 and 2); report unlabelled references rather than dropping them under `clean` (slice 2); CRLF-safe `---` detection (slice 1); CIAC-1's test reconciled with the docstrings (slice 1); G3-07 wording matched to the code (slice 2); the script-execution allowlist row for the new Python tool (slice 3); the epic rollup-close audit's stale `classify` comments (slice 3).

**Held for the Stage 9 follow-up ledger (not filed):** the three items in § Exclusions so marked. The b21 inputs recorded on #8695 stay in this release's records.

---

## Dependency Graph

```
directed edges (governed grammar + native GraphQL blockedBy, read 2026-11-05):
  #6398 --blocked_by--> #6397        native edge present; body "Blocked by: #6397"
  #6397   (no blockers)              GraphQL blockedBy = []
  #7177   (no blockers)              body "None blocking."; GraphQL blockedBy = []
design coupling (not a dependency edge):
  #7177 <-> #6397                    one shared home (S5-D1): slice 1 creates the mirror -> parser load,
                                     slice 2 moves the direction grammar along it
cross-milestone (no governed edge touches milestone 411; Parallelization Map recorded 2026-11-05):
  b21 gate-one-reads-one-way (#7678)   this-blocks-other (directed merge order: this release first)
  milestone 410 obligations-get-runners (#6426)   this-blocks-other (soft)
  milestone 381 deploy-decomposes-per-check (#42)   bidirectional (soft: the FC-1d fixture string)
  milestone 438 guards-judge-every-spelling-alike   bidirectional (structural: the v5.02 slot)
```

Circular chains: **0** — one edge over three nodes.

---

## Implementation Sequence

Single branch `release/sequencing-layer-foundation`, posture **P0 (fully serial)**. Each slice is its own spoke and its own commits, pushed on landing (Write-Early).

| Step | Card | What lands (as Stage 5 and the scope lock resolved it) | Ends when |
|---|---|---|---|
| **0** | plan | this file, carrying the Commit-0 Survival Set and the stamp manifest in its Header `**Version**` cell; the shared-home ADR record (`Proposed`) and its row in the release ADR index | `claim-version.sh --verify-stamp` exits 0 before the commit; the ADR index verifies `COUNT 0` |
| **1** | #7177 | the parser becomes the single home of the issue-body section extractor and ends a section only at a heading or a break line; the mirror loads the parser by path and binds its extractor names; the section-read regression arms and two mirror self-test cases; the smoke suite's count-free label | the parser suite (`TEST OK`) and the three self-tests pass; the pre-repair extractor fails the new arms |
| **2** | #6397 | the direction grammar moves into the parser; `parse_dependencies` returns directed `blocked_by` targets only, the negated label included (D-6397-Negation), unlabelled references reported rather than dropped; the position tool carries the parse status; the G3-07 text matched to the code; the mirror binds the moved names | its Stage-5 verification plan, with CIAC-3's arm still green over the rewritten `parse_dependencies` |
| **3** | #6398 | `_epic_child_set.py` (the G1a child-set rule, one home) and the chain-head view `compute-chain-head-rollup.py`, reading edges through the parser's `parse_dependencies`; the standing-initiative label word and its guard (D-6398-Standing); the selftest manifest, the script-execution allowlist row and the smoke step; the chain-head ADR (`Proposed`); the taxonomy, framework and roadmap README edits; AC6 restated (D-6398-AC6); the release's `## Change Description` (Phase C1) after all three slices land | its Stage-5 verification plan; CIAC-4's arm |
| post-merge | operator | #6398 AC6: retire the interim board's portfolio map and point its README at the view — git-ignored, so not in the diff; read at Stage 8. The milestone lanes stay until #6443 ships | read at Stage 8 |

### #7177 — change specification (slice 1; Stage-5 design on #8695 as D-7177-Extractor amended it)

**Files:** `release/tools/bundle-issues-parser.py`, `release/tools/native-dep-mirror.py`, `release/tools/tests/test_bundle_issues_parser.py`, `.github/workflows/release-tooling-smoke.yml`.

**The extractor (D-7177-Extractor).** `extract_section` ends a section at the next H2/H3 heading or at a break line — a new `SECTION_BREAK_RE`, three or more hyphens indented at most three spaces, trailing spaces or tabs allowed, with an optional carriage return before the line end so a CRLF body reads like an LF one. The two-blank-line terminator is deleted. The return stays `Optional[str]`: a plain string for a present heading, `None` only for an absent one. Leading blank lines are kept, so a genuinely empty section reads exactly as it did. The heading match (DS-1) is unchanged. `extract_section_with_alias(body, aliases)` joins the parser — it returns `(matched_alias, section)` — and `extract_section_aliased` delegates to it, so one alias loop exists. Type hints use only `List`, `Set`, `Dict`, `Optional` and `Tuple`, which the parser already imports.

**The shared home (S5-D1).** The parser is the single home of the extractor and of `DEP_HEADING_ALIASES`; it loads nothing local, so its three standalone by-path loaders are untouched. The mirror loads it by path through a never-raising `_load_bip()` and binds `DEP_HEADING_ALIASES`, `extract_section_with_alias` and `extract_section_aliased` from it, keeping every public name. Its duplicate extractor and its `SECTION_HEADING_RE` are deleted. When the parser cannot be loaded, the mirror's self-test and its body-reading run return exit 2 with `ERROR: native-dep-mirror cannot load its parser: <cause>`. No `from __future__ import annotations` is added. The callers — the parser's six readers and the mirror's `_segments_for_body` — need no change, because the return contract is unchanged; the only difference any of them sees is a section no longer cut short at a blank-line gap, or ended at a break line.

**Tests.** `test_bundle_issues_parser.py` gains six labelled arms — `7177-AC1`, `7177-AC2`, `7177-AC4`, `7177-AC5`, `CIAC-1` and `CIAC-3` — each carrying the arm that shows it bites: a reference copy of the pre-repair extractor, kept in the suite as the sensitivity arm and never shipped; the frozen-sample variants doubled after a heading and inside a section; the no-break control; the CRLF break line and its near-misses; and, for CIAC-1, a structural scan (no non-docstring string or import in the parser names the mirror; the same scan over the mirror sees its load literal), the parser copied alone, the mirror copied alone exiting 2, and identity of the mirror's bound names with the parser's own objects. An arm that raises is recorded as that arm's failure. The parser's `--self-test` gains SX-1..SX-4, and the mirror's gains cases 23 and 24 (two and three blank lines after the heading; a doubled blank line inside the section), which slice 2 counts on.

**Smoke label.** The suite's two count-bearing labels in `.github/workflows/release-tooling-smoke.yml` become count-free: the header comment reads "its legs and section-read arms over the committed frozen sample", and the step name reads `bundle-issues-parser regression suite (frozen sample + section-read arms)`. A step name is not a check context, and no census keys on it. The precision probe's anchor line in the parser is untouched.

### #6397 — change specification (slice 2)

Carried by its own Stage-5 design (#8699), its A6.5 review (#8778) and the scope lock, and recorded in this file by its own Stage-6 spoke (#8700) as the slice lands. Four scope-lock items bind it beyond the design: the negated label ("not blocked by") is fixed inside the shared grammar and covered by AC2 (D-6397-Negation); unlabelled references are reported rather than dropped under `clean`; the G3-07 text is matched to the code; and the mirror gets no `from __future__ import annotations` — the design's Change 2 step 1 is superseded, so annotations that name a bound name are avoided instead. The grammar moves into the parser along slice 1's load; the mirror self-test still passes all 24 cases.

### #6398 — change specification (slice 3)

Carried by its own Stage-5 design (#8703), its A6.5 review (#8780) and the scope lock, and recorded here by its own Stage-6 spoke (#8704). Scope-lock items that bind it: standing is declared by the label description's first word `Standing`, with a guard that fails loudly when no initiative reads as standing (D-6398-Standing); AC6 retires the interim board's portfolio map only, and the milestone lanes stay until #6443 ships (D-6398-AC6); a missing `parent_issue_url` key means no parent (FM-1); the view carries a section-presence facet and the native blocked-by count (CD-1); the script-execution allowlist row for the new Python tool; and the epic rollup-close audit's stale `classify` comments. The view takes its edges from the parser's `parse_dependencies` (CIAC-4). Its integration criterion INT-2 names "#7177's degraded verdict" as one non-clean case; under D-7177-Extractor that verdict does not exist, so the criterion's non-clean population is the deferred and failed parse statuses alone. The slice also authors this file's `## Change Description` (Phase C1).

---

## Stage Applicability Matrix

| Card | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|
| #7177 | APPLY (ran; joint S5-D1 with #6397) | APPLY (slice 1) | APPLY | APPLY | APPLY (Deep) | COMPRESS (platform-satisfied) | COMPRESS (platform-satisfied) | APPLY (release-scoped) | APPLY (release-scoped) |
| #6397 | APPLY (ran; joint S5-D1 with #7177) | APPLY (slice 2) | APPLY | APPLY | APPLY (Deep) | COMPRESS | COMPRESS | APPLY | APPLY |
| #6398 | APPLY (ran; consumes S5-D1's grammar home) | APPLY (slice 3) | APPLY | APPLY (AC6 operator step read here) | APPLY (Deep) | COMPRESS | COMPRESS | APPLY | APPLY |

Skips: none at 5–9 — all three cards change tool behaviour. Stage-5 activation was ACTIVATE for all three (T3 + T4 on every card).

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. A shared path is listed once, under the first slice that edits it; the slices that edit it are named after the verb.

```
# ── Engineering Commit 0 ──
release/releases/plans/sequencing-layer-foundation_RELEASE_PLAN.md  ADD
release/ADRs/ADR-NNN-issue-body-reads-single-sourced-in-the-bundle-parser.md  ADD
release/ADRs/README.md  EDIT
# ── #7177 (slice 1) ──
release/tools/bundle-issues-parser.py  EDIT  7177 slice 1 · 6397 slice 2
release/tools/native-dep-mirror.py  EDIT  7177 slice 1 · 6397 slice 2
release/tools/tests/test_bundle_issues_parser.py  EDIT  7177 slice 1 · 6397 slice 2
.github/workflows/release-tooling-smoke.yml  EDIT  7177 slice 1 · 6398 slice 3
# ── #6397 (slice 2) ──
release/tools/tests/test_native_dep_mirror.py  EDIT
release/tools/compute-milestone-positions.py  EDIT
core/schemas/gate-criteria-spec.md  EDIT
# ── #6398 (slice 3) ──
release/tools/_epic_child_set.py  ADD
release/tools/audit-epic-rollup-close.sh  EDIT
release/tools/compute-chain-head-rollup.py  ADD
release/tools/tests/test_compute_chain_head_rollup.py  ADD
core/deploy/allowlists/selftest-coverage-manifest.txt  EDIT
core/config/allowlists/script-execution-allowlist.txt  EDIT
core/ADRs/ADR-NNN-chain-head-set-derives-from-tracker-labels.md  ADD
core/specs/label-taxonomy.md  EDIT
core/standards/initiative-roadmap-framework.md  EDIT
roadmaps/README.md  EDIT
```

#### Read-only inputs

```
core/deploy/deploy.sh  READ
core/deploy/tools/check-doc-gates.py  READ
release/tools/tests/conformant_bundleable_sample.json  READ
release/references/pipeline/stage-02-triage.md  READ
release/references/specs/ticket-information-architecture.md  READ
```

#### Release-wide explicit non-scope

```
core/deploy/tests/test_g1_form_family.sh  NOT EDITED
release/skills/release-planner/references/dependency-analysis.md  NOT EDITED
packages/release-planner.skill  NOT EDITED
release/tools/verify-release-plan.sh  NOT EDITED
release/releases/RELEASE_LOG.md  NOT TOUCHED
release/releases/notes/  NOT TOUCHED
core/rules/  NOT TOUCHED
```

The repository-root `CHANGELOG.md` is also not touched (the Stage-13 chore PR writes it). It is named here rather than as a fenced row because the matrix reader recognises no repository-root path that carries no directory segment.

**The Stage-4 conditional rows are resolved at this commit** (rule 5 of the declared-vs-delivered contract). `STAGE5-SHARED-HOME` did **not** fire — S5-D1 extends the parser and creates no third module — so the placeholder shared-module row is dropped and `core/deploy/tests/test_g1_form_family.sh` moves to the non-scope block: the parser loads nothing local, so the degraded-root arm that copies only the parser is unaffected. `STAGE5-TOOL-NAME` fired with the names `compute-chain-head-rollup.py` and `test_compute_chain_head_rollup.py`. `NEW-SELFTEST-TOOL` fired (the new tool advertises `--self-test`). `NEW-BARE-SUITE` fired (slice 3 adds a smoke step), and the smoke workflow is edited unconditionally in slice 1 for its count-free label besides. `STAGE5-CONSUMER-ADJUST` fired (the position tool carries the parse status). `STAGE5-MODEA-DOC` did **not** fire (S5-D3: no label change), so `dependency-analysis.md` and its package move to the non-scope block. No CONDITIONAL row remains.

**Rows added since Stage 4 (Tier 1 [ADJUST], recorded at the scope lock):** the shared-home ADR and its index row (slice 1's design, R3); `_epic_child_set.py`, the epic rollup-close audit and the chain-head ADR (slice 3's design, R1, recorded as net-new at the scope lock); the script-execution allowlist row (a scope-lock Stage-6 fix). Both ADR rows carry the `NNN` placeholder rather than a number, because an ADR number is allocated at authorship and bound at merge: the shared-home record is provisionally 230 (the mainline next-free at Commit 0), and the chain-head record takes the next number on this branch in slice 3; either may move under `release/tools/renumber-adr.py` before the merge.

**Zero `ADD` rows for shell executables** — the new-executable companion obligation for `*.sh` does not fire; the script-execution allowlist row is for the new Python tool, a scope-lock fix. **No path is renamed, moved or deleted** → the mover set is empty. **No `pipeline/stage-*.md` file** is edited, and one of the six rule-defining surfaces is (`gate-criteria-spec.md`), so the class stays `novel`. No skill package is staled by any path in the matrix: `printf '%s\n' <path> | bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` is run per slice at C4 (§ Verification Evidence).

### Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `ac96b3ea`) and re-applied to the rows added since. The Tier-0 floor's surviving union is the basenames `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md` at any depth; no matrix path carries one. The sanctioned-session gate's first conjunct needs a `*/skills/<name>/` segment; with `STAGE5-MODEA-DOC` resolved not-fired, no matrix path carries one.

| Card | Write-set paths | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| plan | this file · the shared-home ADR · the release ADR index | ∅ | ∅ — conjunct 1 false | — | first Engineering spoke (Commit 0) |
| #7177 | the parser · the mirror · the parser suite · the smoke workflow | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #6397 | the parser · the mirror · both suites · the position tool · the gate specification | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #6398 | `_epic_child_set.py` · the audit · the view and its suite · the selftest manifest · the script-execution allowlist · the chain-head ADR · the taxonomy · the framework · the roadmap README · the smoke workflow | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |

Every card is `unconstrained`. That says no control refuses the writes; it does not make them ungoverned.

---

## Contention Map

**Within release (serial P0 order resolves every row):**

| File | Slices | Regions | Resolution |
|---|---|---|---|
| `release/tools/bundle-issues-parser.py` | 1, 2 | slice 1: the extractor, `SECTION_BREAK_RE`, `extract_section_with_alias`, the module docstring, self-test SX-1..SX-4; slice 2: the direction grammar section after `DEP_HEADING_ALIASES`, `parse_dependencies`, `DEP_RE` | serialize 1 → 2; CIAC-1 and CIAC-3 guard the hand-off |
| `release/tools/native-dep-mirror.py` | 1, 2 | slice 1: the load seam in place of the alias list, the deleted extractor, the exit-code docstring, the two guards, cases 23–24; slice 2: the grammar definitions removed and bound | serialize 1 → 2 |
| `release/tools/tests/test_bundle_issues_parser.py` | 1, 2 | slice 1: the six section-read arms; slice 2: its `6397-AC1`, `6397-AC2` arms | append-pattern; serialized |
| `.github/workflows/release-tooling-smoke.yml` | 1, 3 | slice 1: two label lines; slice 3: one new step in `closeout-smoke` | distinct lines; serialized |

**Cross-release** (baseline-pinned; Stage 9 A6.5 re-measures):

| File / surface | This release | Sibling or dormant item | Disposition |
|---|---|---|---|
| `release/tools/bundle-issues-parser.py`'s extractor | the shared home | b21 (#7678) builds one shared acceptance-criteria reader on the same extractor | directed merge order: this release first; S5-D1 names the parser as the seam b21 extends (R-9) |
| the `v5.02` version slot | minor | milestone 438 (draft #8651), minor | Tier-S serialization: the first merge claims it, the other re-derives at its claim (R-7) |
| the FC-1d fixture string in the parser | kept | milestone 381's #42 expects it to stay in the parser | CIAC-2 (R-5) |

---

## Cross-PR Overlap Audit

### Baseline SHA

`ac96b3ea123f6092070f29ca380ad159c1d87ab3` — the Stage-4 Phase A0 pin. The Commit-0 base is `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` (`origin/main` at Engineering Commit 0, equal to the hub's read at Stage 5): the commits between the two touch none of this release's matrix paths (the Stage-5 designs' re-read at `b1042eec` and this commit's A3 snapshot agree).

### In-Flight Release Roster

**Measured at:** `b1042eec` · `2026-11-05` (Engineering Commit 0) · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|
| `guards-judge-every-spelling-alike` | `#8651` (draft) | `fc556c66` | `minor` | `v5.02` | — (Stage 4 measured 0 shared paths) |

Probe: `git ls-remote --heads origin 'release/*'` → 1 head (that branch); control: the same read with no pattern returns `main` and that branch, so the reader sees remote heads. This is a pinned measurement with no verdict; Stage 9 Phase A6.6 re-measures it.

### Structural sub-audit

No file is renamed, moved or deleted, so the mover set is empty. `SURFACE(R)` is the version-slot token `Δversion/minor` only.

---

## Risk Register

| # | Risk | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| R-1 | Import cycle between the parser and the mirror | Stage 5 → slice 1 | **Resolved by S5-D1**: one direction only, mirror → parser; CIAC-1's structural arm asserts it | CHEAP / HIGH |
| R-2 | `parse_dependencies` narrowing is a behaviour change for every caller (the position tool, Check 52, Mode A, the suite) | slice 2 | #6397 AC4 consumer audit, one disposition per caller | CHEAP / HIGH |
| R-3 | The parser is loaded alone by path (Check 22's delegates, the position tool, the degraded-root arm) | slice 1 | **Resolved by S5-D1**: the parser gains no local load; CIAC-1 loads a copy of the parser alone; `test_g1_form_family.sh` is unedited | CHEAP / HIGH |
| R-4 | A degraded verdict would change the extractor contract for every caller | slice 1 | **Retired by D-7177-Extractor**: no degraded verdict exists; the return stays a plain string, so no caller changes | CHEAP / HIGH |
| R-5 | Milestone 381's #42 expects the FC-1d fixture string to stay in the parser | Eng | CIAC-2; slice 1 leaves the fixture untouched | CHEAP / HIGH |
| R-6 | Moving the grammar starts a reference cascade (the view's AC4 cite, the mirror suite, the smoke step, a runner string, two pseudocode blocks) | slice 2 | `parse_body_dependencies` keeps its name in the mirror; sweep with pre and post counts | CHEAP / HIGH |
| R-7 | Version slot `v5.02` is also milestone 438's next-free | hub | Re-verified free at Commit 0; binds at the Stage-12 atomic claim | CHEAP / HIGH |
| R-8 | The view renders sequencing it cannot support (few governed milestone edges; lone-epic heads are evergreen containers) | slice 3 | D-6398-Standing and the container disposition; never present a tie-break as a sequence; unmeasured is never 0 | CHEAP / MEDIUM |
| R-9 | b21 (#7678) builds a shared reader on this extractor; a third reader appears if this release's home is not the seam b21 extends | hub | S5-D1 names the parser; this release merges first | CHEAP / MEDIUM |
| R-10 | Several hub sessions run on the same account during this release | hub | Checkpoint B at every launch | CHEAP / MEDIUM |
| R-11 | `Hard:` / `Soft:` residual | slice 2 | S5-D3: no label change; AC2 fixtures assert the disposition | CHEAP / HIGH |
| R-12 | AC5 of #6397 ("no new failures" in `deploy.sh --check`) needs a pre-change baseline | DT | Capture the `  FAIL:` lines at `b1042eec` and diff | CHEAP / HIGH |
| R-13 | **Un-headed trailing text joins a section.** With no whitespace terminator, text after a blank-line gap that is neither a heading nor a break line is read as part of the section | slice 1 | Measured at Commit 0: identical caller output, pre-repair vs repaired, on every open body and every frozen body (§ Verification Evidence); recorded as a residual in the shared-home ADR | CHEAP / MEDIUM |
| R-14 | **A break line ends a section the old extractor read past**, including a hyphen line inside a fenced example (the extractor was already fence-blind for headings) | slice 1 | Measured at Commit 0: the sections the repaired extractor ends at a break line with no gap before it are provenance footers, and no caller output changes | CHEAP / MEDIUM |

Rollback complexity is CHEAP for the release (§ Rollback Strategy).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#6397 × #7177 on the shared-home seam):** the single-sourced extractor and direction grammar load with no import cycle between `bundle-issues-parser.py` and `native-dep-mirror.py`. *Method:* `grep -c -F "CIAC-1 no import cycle between the parser and the mirror" release/tools/tests/test_bundle_issues_parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR;* the suite's CI step grades the arm's behaviour.
- [ ] **CIAC-2 (#6397 × #7177 on `release/tools/bundle-issues-parser.py`):** neither restructuring removes the FC-1d fixture string that milestone 381's #42 AC1 expects in the parser. *Method:* `grep -c -F "pmo-platform/engineering/" release/tools/bundle-issues-parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7177 × #6397 on `parse_dependencies`):** after #6397 rewrites `parse_dependencies`, a Dependencies section whose heading carries a doubled blank line, or that carries one between its lines, still reads the same targets and the same status as its single-blank form — #7177's blank-line-invariant extraction survives the directed parse. *Method:* `grep -c -F "CIAC-3 blank-line-invariant extraction survives the directed parse" release/tools/tests/test_bundle_issues_parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR;* the suite's CI step grades the arm's behaviour.
- [ ] **CIAC-4 (#6397 × #6398 on the direction grammar):** the chain-head view takes its dependency edges from the same single-sourced grammar `parse_dependencies` uses — no third grammar and no naive number scrape. *Method:* declared, verification deferred to #6397 AC-1 and #6398 AC-4 — the latter through the `CIAC-4 view loads the single-sourced grammar` arm of the view's suite (slice 3). *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 body read `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6. CIAC-3 is restated under D-7177-Extractor (DEV-4): the Stage-4 text asserted a degraded extractor verdict that no longer exists.

---

## Verification Plan

**AC baseline:** #7177 = **5** criteria, #6397 = **5**, #6398 = **6**, read by the governed parser on the live bodies at Engineering Commit 0 (the counts the Stage-4 plan recorded at `ac96b3ea`; the scope-lock restatements of #7177 AC5 and #6398 AC6 changed no count).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7177 | AC-1 | `grep -c -F "7177-AC1 blank-line tolerance" release/tools/tests/test_bundle_issues_parser.py` at least 1 [READER-GRADED — the arm runs in the CI-wired suite step of release-tooling-smoke.yml and carries the pre-repair sensitivity arm] | at least 1 (0 at the base) |
| #7177 | AC-2 | `grep -c -F "7177-AC2 empty, absent and populated stay distinct" release/tools/tests/test_bundle_issues_parser.py` at least 1 [READER-GRADED — present-and-empty, absent and populated asserted as three reads] | at least 1 (0 at the base) |
| #7177 | AC-3 | `grep -c -F "blank lines after the heading still mirror" release/tools/native-dep-mirror.py` at least 1 [READER-GRADED — self-test case 23, run by the selftest-discovery job; a non-empty eligible set for two and three blank lines] | at least 1 (0 at the base) |
| #7177 | AC-4 | `grep -c -F "7177-AC4 parse rate unchanged under the two-blank shape" release/tools/tests/test_bundle_issues_parser.py` at least 1 [READER-GRADED — the frozen sample doubled after a heading and inside a section, each non-vacuous, with the pre-repair count shown to move] | at least 1 (0 at the base) |
| #7177 | AC-5 | `grep -c -F "7177-AC5 no whitespace-only gap ends a section" release/tools/tests/test_bundle_issues_parser.py` at least 1 [READER-GRADED — doubled internal blank lines in all three headings, the break-line footer arm and its CRLF arm, the plain-string return and both G3-20 readers] | at least 1 (0 at the base) |
| #6397 | AC-1 | declared, verification deferred to the `6397-AC1` arm of release/tools/tests/test_bundle_issues_parser.py (slice 2) | directed `blocked_by` only, from the single-sourced grammar |
| #6397 | AC-2 | declared, verification deferred to the `6397-AC2` arms of release/tools/tests/test_bundle_issues_parser.py (slice 2) | one fixture per relation, `Hard:`/`Soft:` and the negated label included; zero edges for each non-blocking form · control: the `Blocked by: #N` fixture → 1 edge |
| #6397 | AC-3 | declared, verification deferred to the Stage-7 live run of compute-milestone-positions.py --dry-run, with the pre-change parser as the naive arm on the same snapshot | governed 0 cycle-resident; naive arm at least 1 (2026-11-05: 10 of 56, 703 open issues) |
| #6397 | AC-4 | declared, verification deferred to the consumer-audit table in the #6397 Stage-5 design on #8699 | one disposition per named consumer |
| #6397 | AC-5 | declared, verification deferred to the selftest-discovery job (both self-tests) and the Stage-7 deploy-check FAIL-line diff against the `b1042eec` baseline | both pass; no new `  FAIL:` lines |
| #6398 | AC-1 | declared, verification deferred to the view's suite (slice 3) and the Stage-7 live run of compute-chain-head-rollup.py | one command, live tracker reads, nothing cached or written |
| #6398 | AC-2 | declared, verification deferred to the view's suite (slice 3) | head set derived at runtime; a new `project:*` label becomes a head with no registry edit |
| #6398 | AC-3 | declared, verification deferred to the view's suite (slice 3) | three drill levels; a standing initiative (label description's first word `Standing`) shows no percentage; the no-standing guard fails loudly |
| #6398 | AC-4 | declared, verification deferred to the view's suite and CIAC-4 (slice 3) | the fixture differs under a naive number scrape; edges from `parse_dependencies` |
| #6398 | AC-5 | declared, verification deferred to the view's suite (slice 3) | per-head unparented counts; an unreadable count reads unmeasured, never 0 |
| #6398 | AC-6 | [DEFERRED — operator post-merge step on the git-ignored interim board, read at Stage 8: the portfolio map retired, the milestone lanes kept until #6443 ships] | the map retired; its README points to the view |

`ac_baseline: { #7177: 5, #6397: 5, #6398: 6, read_at: b1042eec }`

**Null and threshold rows carry a same-target control** (AC-Binding Limb 2): each `#7177` label row reads 0 at the base, and the same instrument on the same file returns non-zero once the slice lands; the pre-repair sensitivity arm inside each labelled arm is what makes the label's presence mean a test that bites.

### Release-Level Verification

These checks use tools or shapes outside the plan verifier's runnable set, so each is declared deferred to the Stage-6 C4 run that executes it; the commands and observed results land in § Verification Evidence as each slice lands.

| Check | Verification Method | Expected |
|---|---|---|
| Parser regression suite | [DEFERRED — release/tools/tests/test_bundle_issues_parser.py at Stage 6 C4 per slice] | `TEST OK`; frozen sample combined-clean unchanged (39 of 40 at the base) |
| Tool self-tests | [DEFERRED — the parser's, the mirror's and the position tool's self-tests at Stage 6 C4 per slice] | each `SELF-TEST OK` |
| Mirror frozen suite | [DEFERRED — release/tools/tests/test_native_dep_mirror.py at Stage 6 C4 per slice] | `TEST OK` |
| RED arm | [DEFERRED — the new suite run against the pre-repair tools from the base, at Stage 6 C4 slice 1] | every new section-read arm fails |
| Precision probe | [DEFERRED — the smoke workflow's priority-detector mutation reproduced on a throwaway copy, at Stage 6 C4 slice 1] | the suite exits non-zero via the T-13 liveness assertion with the new arms present |
| Live equivalence | [DEFERRED — the pre-repair and repaired extractors compared on every open body and every frozen body, at Stage 6 C4 slice 1] | identical caller output; the break-ended sections counted and read |
| Degraded-root arm | [DEFERRED — core/deploy/tests/test_g1_form_family.sh at Stage 6 C4 slice 1 or Stage 7] | arm G unchanged |
| ADR gates | [DEFERRED — generate-adr-index.py --verify, check-adr-numbers.py and check-adr-durability.py at Stage 6 A1 and per slice that adds a record] | `COUNT 0`; contiguous; no finding |
| Doc-link integrity | [DEFERRED — the doc-link checker and the release-link checker with the plan-depth lint on this plan, at Stage 6 A1 and C4] | no new broken link |
| Package consequence | [DEFERRED — the package resolver reading each changed path on STDIN, at Stage 6 C4 per slice] | empty — no rostered skill's package is staled |
| CIAC authoring lint | [DEFERRED — the plan verifier's CIAC lint over this file, at Stage 6 A1 and Stage 9 A3.6] | declared=4 parsed=4 flagged=0 |
| Cascade sweeps (DTA-7) | [DEFERRED — the Stage-5 sweeps over the two tool files, pre and post, at Stage 6 C4 per slice] | every surviving hit is a kept name or a PRESERVE row |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential (P0 serial; contention-driven) |
| Commit strategy | Commit 0 (this plan and the shared-home ADR), then one or more commits per slice, each pushed on landing (Write-Early); messages carry the `sequencing-layer-foundation:` prefix and a reference-only `(#N)` |
| Review approach | Single release PR, draft until Stage 9 Phase A8 |
| Deployment mechanism | Git merge. No skill package and no rules-mirror member changes |
| Stacked-base cleanup | N/A (single branch) |

The PR body is parser-clean: each card is named in the dedicated Issue References block; no close-family verb precedes an issue number anywhere else.

---

## Rollback Strategy

| Scope | Method | Complexity |
|---|---|---|
| Whole release | Revert the merge (`git revert -m 1 <merge>`) through a PR. Nothing outside the tree persists: no milestone carries a position, the mirror only adds author-declared edges, and the view writes nothing | CHEAP / HIGH |
| One slice | Revert that slice's commits; slice 2 depends on slice 1's load seam, so reverting slice 1 alone means reverting slice 2 first | CHEAP / HIGH |
| After a dependent builds on the home | Revert this release together with the dependent, or keep the home | MODERATE / HIGH |
| Version tag | Retained and recorded per Tag Retention; never deleted | — |

Rollback infeasibility: none; every step is a commit.

---

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A), transcribed from Stage 4 — usage-window basis **UNSTATED**.
**Parallel-eligible spokes per parallel stage:** Stage 5: 3 · Stage 7: 3 · Stage 8: 3 (Stage 6 is serial).
**Per-spoke cost estimate:** ordinal size band — #7177 S (lowest), #6397 M (low–moderate), #6398 L (moderate–high) (heuristic).
**Assumed remaining usage-window envelope:** unstated at hub start; the conservative default applies [ASSUMPTION – CONFIRM].
**Estimated cumulative draw (worst parallel batch):** not computed — the protocol forbids a synthesized figure on an unstated band.
**Routing:** WARN → window-aware launch timing; Checkpoint B re-validates at every launch.

---

## Release Class declaration

**`novel`** — #6398 introduces a new tool with a machine-readable rollup schema (trigger (a)), and Stage 5 rendered D-class decisions S5-D1..S5-D4 (trigger (b)). `routine` fails (a new file, a size-L card, D-decisions). `cross-cutting` does not fire: 0 `pipeline/stage-*.md` files, 1 of the six rule-defining surfaces (`gate-criteria-spec.md`), and 1 in-bundle dependency edge. `hotfix` does not fire. Differentiation posture: engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed verbatim from the milestone description at Engineering Commit 0 (the Stage-4 gate kept it as written).

**AFTER:** Dependency edges are read directed from the governed parser (which no longer returns an empty section on a double blank line), and every chain head renders in one generated view with drill-down and per-head unparented counts.

**BEFORE:** The parser scrapes every #N as an undirected edge; work above the epic tier is visible only by hand.

**Actor(s):** platform engineering session. **Success Indicator:** every member's own acceptance signal verified at Stage 8; one PR.

Limb ownership — derived at Engineering Commit 0 from the AFTER sentence's clauses and the Implementation Sequence; it is not part of the milestone's text above: the parser no longer returns an empty section on a double blank line → #7177 · dependency edges are read directed from the governed parser → #6397 · every chain head renders in one generated view with drill-down and per-head unparented counts → #6398.

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| Every matrix path | **Repository-only** — none is under a skills tree or in the rules mirror set, so no installed copy exists | none required |
| The release tools and their tests | Run from the repository by CI, the deploy check and the pipeline stages; nothing is copied | none required |

**`deliverable_state: deployed-copy-synced`** — the release declares no Layer-2 propagation target, which this state admits ("or the release declares no propagation target").

### Schema Migrations

N/A — enumerated over data-file formats, the frozen sample's schema, register and ledger schemas, the pipeline-event-log schema and the gate-criteria schema columns; none migrates. The extractor's return contract is unchanged. The view's machine-readable rollup is a new schema, introduced rather than migrated (slice 3).

### Memory Evictions

N/A — enumerated over memory eviction, memory re-point and archive disposition; no card in this release is tied to an auto-memory entry, so nothing is evicted.

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Run by the Stage-6 spoke on #8696 after this file was written and before it was committed, on base `b1042eec`. The Phase A checkpoint ("present A1–A2 before B1") is discharged by the operator's Collective Review scope lock, which authorized Engineering, and is recorded here rather than opened as a fresh gate.

**A2 container determination:** the decomposition is multi-file and changes structure across two tools (S5-D1's load seam), so the Phase A2 threshold predicate selects the **GitHub sub-issue container**; the Stage-6 sub-task the hub scaffolded per card (#8696, #8700, #8704) is that container, the change units are listed in § Implementation Sequence, in each spoke's output and as checklist rows in the pull-request body, and no further sub-issues are created (the v5.00 precedent).

**A3 file-state snapshot:** every matrix path that exists was read at `b1042eec`; `origin/main` had not moved from the hub's read, so no file in the change set diverged.

| Check | Command | Observed |
|---|---|---|
| Stamp manifest (step 3b) | `bash release/tools/claim-version.sh --verify-stamp sequencing-layer-foundation` | exit 0 — "verify-stamp OK — sequencing-layer-foundation carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries exactly 1 literal placeholder (python count) |
| CIAC authoring lint (A1) | `bash release/tools/verify-release-plan.sh --ciac-lint release/releases/plans/sequencing-layer-foundation_RELEASE_PLAN.md` | exit 0 — `CIAC-LINT-SUMMARY declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`, equal to the Stage-4 reading; CIAC-1..3 CLEAN, CIAC-4 DECLARED. Sensitivity arm: an earlier draft of CIAC-4's method that dropped the `#6398 AC-4` deferral target read `flagged=1` (`evidence-misses-spanned-issue:#6398`), so the lint bites; the Stage-4 deferral wording was restored. G4-06 holds on the committed plan |
| Full verifier (matrix reading) | `bash release/tools/verify-release-plan.sh release/releases/plans/sequencing-layer-foundation_RELEASE_PLAN.md` | exit 3 pre-commit. `FCM-COVERAGE` PASS: `declared=32 interpreted=32 obligations=6 excluded=12 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; FCM-1..FCM-6 FAIL pre-commit (each ADD delivers at its own commit — this file and the shared-home ADR at Commit 0, the four slice-3 ADDs later). `PROV-PRESENCE` / `PROV-GRAMMAR` PASS (Form X). The per-issue and CIAC rows are graded at slice 1's C4 |
| Probe literals at the base | each Verification Plan and CIAC label counted at `b1042eec` (`git show`, python line count) | the five #7177 labels, CIAC-1 and CIAC-3: **0** at the base — each row's RED arm for its later GREEN; CIAC-2's fixture string: 2 at the base. Control: the suite's existing `T-13 liveness` literal reads 2 at the base, so the reader sees the file |
| ADR gates | `python3 release/tools/generate-adr-index.py --write`, then `--verify`; `python3 release/tools/check-adr-numbers.py`; `python3 release/tools/check-adr-durability.py --files <the record> --diff-base origin/main` | index `COUNT 0` (70 rows; one row added); numbering PASS, contiguous through 230 with no duplicate; durability lint `COUNT 0` on the record — its own self-test passes 156 of 156, so a zero is not a blind lint |
| Doc links and plan depth | `python3 core/deploy/tools/check-doc-links.py --target-paths <this file>,<the record>,release/ADRs/README.md --require-targets`; `python3 release/tools/check-release-links.py --files <the same> --check-anchors`, and with `--plan-depth-lint` | doc links exit 0, no findings; release links 0 broken, plan depth 0 findings. Both checkers' self-tests pass (the release-link self-test asserts the plan-depth lint fires) |
| Identity strings, host URLs, close keywords | a python scan of this file and the record for the home path, the bare username, the repository owner's handle, an email address, a raw host URL and a close-family verb before an issue number | 0 in every class. Control: one constructed line carrying one of each fires every class |

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **D-7177-Extractor replaces the Stage-5 extractor design (S5-D2).** A section ends at the next H2/H3 heading or a break line; the two-blank-line terminator is removed; the return stays `Optional[str]`. There are no record types, no per-caller rendering change, no mirror WARNING and no new `failed` source for whitespace. The Stage-5 design's D-7177-1 leading-blank skip is not applied: once no whitespace ends a section it has no reading effect, and skipping it would change the text every caller receives and the present-and-empty control arm Stages 4 and 5 recorded | scope lock D-7177-Extractor; A6.5 review on #8777 (PRF-1, FM-1, CD-1) | **APPLIED** — slice 1 |
| **DEV-2** | **The break line's definition.** The decision names "a `---` line"; it is implemented as three or more hyphens, indented at most three spaces, optional trailing spaces or tabs, CRLF-safe (`\r?` before the line end). `***` and `___` are not break lines, and HTML comments are not stripped: the decision names the hyphen line, and the observed separator footers are all of that shape | scope lock D-7177-Extractor and its Stage-6 fix (CRLF-safe detection); A6.5 FM-3 | **APPLIED** — slice 1 |
| **DEV-3** | **S5-D1 keeps every public name of the mirror, `extract_section_with_alias` and `extract_section_aliased` included.** The Stage-5 design deleted both; the hub's scope-lock reading keeps them, bound from the parser. So the parser gains `extract_section_with_alias` (returning the matched alias with the section, the contract the mirror's copy had), and `extract_section_aliased` delegates to it. The Stage-5 reference-cascade expectation of a post-0 count for `extract_section_with_alias` does not apply — the name's definition moves and its call sites stay | the hub's Stage-6 brief for #8696 (S5-D1 stands, every public name kept) | **APPLIED** — slice 1 |
| **DEV-4** | **CIAC-3 is restated.** The Stage-4 text asserted that "a Dependencies heading whose content the extractor cannot locate still yields a non-clean status — #7177's degraded verdict survives the rewrite", and its grep label named a degraded verdict. Under D-7177-Extractor that state is unreachable by construction, so the criterion now asserts the property that does survive — a doubled blank line reads the same targets and status as the single-blank form through the rewritten `parse_dependencies` — under the label `CIAC-3 blank-line-invariant extraction survives the directed parse`. The ID, the cards, the seam and the grep-for-a-label method are unchanged | scope lock D-7177-Extractor (AC5 restated "because the cannot-locate case no longer exists") | **APPLIED** — § Cross-Issue Acceptance Criteria; the arm lands in slice 1 |
| **DEV-5** | **CIAC-1's test is structural, not a text search.** The Stage-5 arm asserted the parser's source contains no `native-dep-mirror`, which the parser's own docstring now names; the arm instead asserts no non-docstring string and no import in the parser names the mirror, with the same scan over the mirror as its sensitivity arm, plus the copy-alone loads | scope-lock Stage-6 fix (CIAC-1's test reconciled with the docstrings); A6.5 FM-2 | **APPLIED** — slice 1 |
| **DEV-6** | **The ADR is written `Proposed`, not `Accepted`**, and covers S5-D1 with D-7177-Extractor; the record types become a rejected alternative, and the new-module candidate stays the opposing view | scope-lock recorded alignment | **APPLIED** — Commit 0 |
| **DEV-7** | **The Stage-4 conditional rows are resolved and the matrix gains the rows Stage 5 and the scope lock added** — the shared-home ADR and its index row, `_epic_child_set.py`, the epic rollup-close audit, the chain-head ADR and the script-execution allowlist row; the two `STAGE5-SHARED-HOME` rows and the two `STAGE5-MODEA-DOC` rows resolved not-fired | Stage-5 designs (R3 on #8695, R1 on #8703); scope-lock alignments and Stage-6 fixes | **APPLIED** — § File Change Matrix |
| **DEV-8** | **The smoke workflow is an unconditional EDIT in slice 1** for its count-free label, not only `CONDITIONAL:NEW-BARE-SUITE` | Stage-5 design R3 on #8695, approved at the scope lock | **APPLIED** — slice 1 |
| **DEV-9** | **The mirror's load guard in `main()` sits after the `--verify-write-surface` dispatch**, not as its first statement, so `--help` and the write-surface introspection — neither reads a body — still run with no parser beside the tool; every body-reading path and the self-test still exit 2 first | Stage-6 B3 (minor adjustment) | **APPLIED** — slice 1 |
| **DEV-10** | **Only the shared-home ADR is written at Commit 0.** The scope-lock alignment reads "both new ADR records are written `Proposed` at Engineering Commit 0"; the hub's Stage-6 brief scoped this spoke to the shared-home record and left #6398's to its own slice, so the chain-head ADR is authored `Proposed` by slice 3 and takes the next number on this branch | the hub's Stage-6 brief for #8696 | **RECORDED** — for the hub to confirm |
| **DEV-11** | **#6398's integration criterion INT-2 names "#7177's degraded verdict"** as a non-clean case; that verdict does not exist under D-7177-Extractor, so INT-2's non-clean population is the deferred and failed statuses alone. Recorded for slice 3; its body is not edited here | scope lock D-7177-Extractor | **RECORDED** — slice 3 |

---

## Issue References

- **#7177** — the section-extractor card: a heading carrying two blank lines read as an empty section. Mark as closed at Stage 13.
- **#6397** — the direction-grammar card: the parser scraped every issue number as an undirected edge. Mark as closed at Stage 13.
- **#6398** — the chain-head view card. Mark as closed at Stage 13.
- **#8664 · #8695 · #8699 · #8703** — the Stage-4 sub-task (plan and gate record) and the three Stage-5 sub-tasks (designs and the scope lock).
- **#8777 · #8778 · #8780** — the three Phase A6.5 adversarial reviews.
- **#8696 · #8700 · #8704** — the three Stage-6 sub-tasks.
- **#6443** — the milestone's epic; **#6619** — #7177's home epic.
- **#7678** — compose slot b21, the shared acceptance-criteria reader that merges after this release.
- **#6426** — native-edge reads, milestone 410, sequenced after this release.
- **#42** — milestone 381's card whose AC1 expects the FC-1d fixture string in the parser.
- **#8651** — milestone 438's draft release PR, the sibling for the `v5.02` slot.
