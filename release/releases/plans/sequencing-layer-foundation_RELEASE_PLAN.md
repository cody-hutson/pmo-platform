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

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8664 and is amended by three decision records, in order: the Stage-4 gate's Decision Recorded on #8664 (plan approved with the milestone's Release Outcome Statement kept verbatim; `novel`; SINGLE; P0; D-Version recorded), the Collective Review scope-lock Decision Recorded on #8695 (scope hard-locked through Stage 9; D-7177-Extractor; D-6397-Negation; D-6398-AC6; D-6398-Standing; the recorded alignments; the Stage-6 fixes; the items held for the Stage 9 follow-up ledger), and the pre-Stage-9 Decision Recorded on #8707 (D-6397-AC2-Gap; D-6398-Q01; D-6398-AC6-ReadPoint; D-CIAC3-Restated). The three Stage-5 designs and the approved findings of their adversarial reviews are design inputs as that record adopts them. Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log with the decision that caused it. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): tool behaviour changes, a new release tool, and gate and reference text added inside existing structure, per the Bump-Class Selection Guide's "protocol text addition or modification" and "reference document addition or update"; no new skill and no new governance file. Provisional display `v5.02`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-05 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering complete: Engineering Commit 0 (this file and the shared-home ADR, `5c6ea3fd`), #7177's slice (`5634b68e`), #6397's slice (`3c3acb6c`, `00785cd4`) and #6398's slice (`94483098`, `3da7400b`, `a0599135`) landed, with slice 3's C4 evidence and this file's `## Change Description`, and the hub's exec-mode repair (`f23837a3`, DEV-26). Stage 7 Dev Testing returned PASS on all three cards; DT iteration 1's Tier 1 fixes landed (`63fdc04c` and `beb07cf4`, DEV-27) and the hub re-reviewed them. Stage 8 QA Testing reviewed all three cards (#8698, #8702, #8706), and DT iteration 2 applied the operator's pre-Stage-9 decisions (`bd19879b` and this file's DT commit, DEV-28 and DEV-29). At Stage 12 the pre-merge sync merged `origin/main` (`adf9bffd`), renumbered the two ADR records to 234 and 235 (`007e330b`, `7e9e7932`) and stamped their slug-token citations (DEV-30); milestone 438 then merged first and took 234 and 235, so a second sync merged `origin/main` (`9a394380`) and renumbered the records to 236 and 237 (`2e2ce58b`, `d9ef001a`, DEV-31). Next: the Stage-12 merge, version claim and deploy |
| **Branch** | `release/sequencing-layer-foundation` |
| **PR** | **#8811**, opened in **draft** at Stage 6 Phase C2 after #7177's slice; transitions to ready-for-review at the Stage-9 gate |
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

### Pre-Stage-9 decisions (operator, 2026-11-05)

Rendered in the release-hub session from the Stage 8 acceptance reviews on #8698, #8702 and #8706, and recorded on #8707.

| Decision | Rendered |
|---|---|
| D-6397-AC2-Gap | **Fix now (DT iteration 2):** a blank line ends a `Blocked by:` run, and every other directional label's, so a reference in a later paragraph is not read as a blocker — 1 of 154 live directed references changes (#7466 → #7889); the underscore-emphasis spelling `_not_ blocked by` reads as negated too |
| D-6398-Q01 | **Fix now (DT iteration 2):** a failed epic child-set read renders that epic's children and the blocked count unmeasured, never "No open children" or Blocked 0 |
| D-6398-AC6-ReadPoint | **AC6 is read and recorded at Stage 13 close-out:** the operator's post-merge interim-board step follows the merge, which Stage 8 precedes; the pull request's Issue References block is unchanged; a plan-only change (DEV-28) |
| D-CIAC3-Restated | **Confirmed:** CIAC-3 as restated under DEV-4 — a doubled blank line reads the same through the directed parse; AI-001 resolves |

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
| post-merge | operator | #6398 AC6: retire the interim board's portfolio map and point its README at the view — git-ignored, so not in the diff; read and recorded at Stage 13 close-out (D-6398-AC6-ReadPoint). The milestone lanes stay until #6443 ships | read and recorded at Stage 13 close-out |

### #7177 — change specification (slice 1; Stage-5 design on #8695 as D-7177-Extractor amended it)

**Files:** `release/tools/bundle-issues-parser.py`, `release/tools/native-dep-mirror.py`, `release/tools/tests/test_bundle_issues_parser.py`, `.github/workflows/release-tooling-smoke.yml`.

**The extractor (D-7177-Extractor).** `extract_section` ends a section at the next H2/H3 heading or at a break line — a new `SECTION_BREAK_RE`, three or more hyphens indented at most three spaces, trailing spaces or tabs allowed, with an optional carriage return before the line end so a CRLF body reads like an LF one. The two-blank-line terminator is deleted. The return stays `Optional[str]`: a plain string for a present heading, `None` only for an absent one. Leading blank lines are kept, so a genuinely empty section reads exactly as it did. The heading match (DS-1) is unchanged. `extract_section_with_alias(body, aliases)` joins the parser — it returns `(matched_alias, section)` — and `extract_section_aliased` delegates to it, so one alias loop exists. Type hints use only `List`, `Set`, `Dict`, `Optional` and `Tuple`, which the parser already imports.

**The shared home (S5-D1).** The parser is the single home of the extractor and of `DEP_HEADING_ALIASES`; it loads nothing local, so its three standalone by-path loaders are untouched. The mirror loads it by path through a never-raising `_load_bip()` and binds `DEP_HEADING_ALIASES`, `extract_section_with_alias` and `extract_section_aliased` from it, keeping every public name. Its duplicate extractor and its `SECTION_HEADING_RE` are deleted. When the parser cannot be loaded, the mirror's self-test and its body-reading run return exit 2 with `ERROR: native-dep-mirror cannot load its parser: <cause>`. No `from __future__ import annotations` is added. The callers — the parser's six readers and the mirror's `_segments_for_body` — need no change, because the return contract is unchanged; the only difference any of them sees is a section no longer cut short at a blank-line gap, or ended at a break line.

**Tests.** `test_bundle_issues_parser.py` gains six labelled arms — `7177-AC1`, `7177-AC2`, `7177-AC4`, `7177-AC5`, `CIAC-1` and `CIAC-3` — each carrying the arm that shows it bites: a reference copy of the pre-repair extractor, kept in the suite as the sensitivity arm and never shipped; the frozen-sample variants doubled after a heading and inside a section; the no-break control; the CRLF break line and its near-misses; and, for CIAC-1, a structural scan (no non-docstring string or import in the parser names the mirror; the same scan over the mirror sees its load literal), the parser copied alone, the mirror copied alone exiting 2, and identity of the mirror's bound names with the parser's own objects. An arm that raises is recorded as that arm's failure. The parser's `--self-test` gains SX-1..SX-4, and the mirror's gains cases 23 and 24 (two and three blank lines after the heading; a doubled blank line inside the section), which slice 2 counts on.

**Smoke label.** The suite's two count-bearing labels in `.github/workflows/release-tooling-smoke.yml` become count-free: the header comment reads "its legs, section-read arms and direction-grammar arms over the committed frozen sample", and the step name reads `bundle-issues-parser regression suite (frozen sample + section-read and direction-grammar arms)` (the direction-grammar arms, slice 2's, named at DT iteration 1 — DEV-27). A step name is not a check context, and no census keys on it. The precision probe's anchor line in the parser is untouched.

### #6397 — change specification (slice 2; Stage-5 design on #8699 as the scope lock and the A6.5 review on #8778 amended it)

**Files:** `release/tools/bundle-issues-parser.py`, `release/tools/native-dep-mirror.py`, `release/tools/compute-milestone-positions.py`, `release/tools/tests/test_bundle_issues_parser.py`, `release/tools/tests/test_native_dep_mirror.py`, `core/schemas/gate-criteria-spec.md`.

**One direction grammar (S5-D1).** The grammar region moves verbatim from the mirror into the parser, after `DEP_HEADING_ALIASES`: `SEGMENT_LABELS`, `_SEGMENT_LABEL_RE`, `_LABEL_KIND_BY_GROUP`, `DEP_TOKEN_RE`, `_LIST_MARKER_RE`, `_PROSE_WORD_RE`, `DIRECTIONAL_HEADINGS`, `_is_bare_ref_run`, `BodyDep`, `_attribute_segments`, `_parse_token`, `_segments_for_body`, `unattributed_refs` and `parse_body_dependencies`. Three changes ride along and nothing else differs: the section's header comment, `_parse_token`'s stderr prefix (`bundle-issues-parser:`), and the negated-label rule below. The mirror deletes the region and binds the six public names it exposed — `SEGMENT_LABELS`, `DEP_TOKEN_RE`, `DIRECTIONAL_HEADINGS`, `BodyDep`, `parse_body_dependencies`, `unattributed_refs` — beside slice 1's three. Its two annotations that name `BodyDep` are quoted, with no `from __future__ import annotations`, so a mirror with no parser beside it still reaches its exit-2 path; its `re` import, used only by the moved region, goes.

**The directed parse (D-6397-2).** `parse_dependencies` returns the `blocked_by` targets of `parse_body_dependencies`, of any dependency type or lag, and `DEP_RE` is deleted. The status vocabulary is unchanged: `clean` for an absent or read section, `deferred` for the intake deferral marker. No `failed` source is added, because D-7177-Extractor left no degraded verdict to map.

**The negated label (D-6397-Negation).** In `_attribute_segments`, a `blocked_by`-kind label whose same-line prefix ends in `not`, `no longer`, `never` or an `n't` contraction (markdown emphasis tolerated) is attributed `relates`: no edge, and no unattributed reference. The A3.5 mirror inherits it through its binding (self-test case 25).

**The paragraph end (D-6397-AC2-Gap, DT iteration 2 — DEV-29).** In `_attribute_segments`, a `blocked_by` or `blocks` run ends at the first blank line after its first text; blank lines between the label and that text do not end it, so a list set under its label keeps its edges. The rest, up to the next label, is unlabelled text beneath the section heading: under a directional heading it takes the heading's direction, and otherwise it yields no edge and is reported as unattributed. The bare-reference shim is not applied to it — it covers only the run before the first label — and a `relates` run, a negated label included, is not ended. The negated-label rule accepts underscore emphasis before the word (`_not_`, `__not__`); an underscore inside a word is not emphasis. One blank line and several end a run alike, so CIAC-3's property holds by construction.

**Unattributed references reported (A6.5 FM-2).** `IssueRecord` gains two defaulted, data-only fields — `dependencies_unattributed` (the numbers) and `dependencies_unattributed_count` — filled from `unattributed_refs`. Neither feeds `parse_status`; the JSON output carries both; `parse_dependencies` keeps its two-value return.

**The position tool (`STAGE5-CONSUMER-ADJUST`).** `IssueLite` carries `dep_status`, `gh_open_issues` keeps it, and `aggregate_edges` lists a source whose status is not `clean` among the unresolvable edges. The `--check-drift` TSV is unchanged.

**G3-07 (the card's Documentation Impact row).** The criterion reads "directed dependency edge", and an **Edge source** paragraph names `parse_dependencies` as the authority and describes the grammar as the code behaves, its imprecisions included (A6.5 FM-3).

**Tests.** Parser self-test DG-1..DG-22; mirror self-test case 25 (25 cases); parser suite arms `6397-AC1 one direction grammar` and `6397-AC2 relation fixtures`, each with a reference copy of the old scrape as its sensitivity arm (`6397-AC2` gains, at DT iteration 2, the later-paragraph, `Blocks`-paragraph and underscore-negation rows and four edge controls); CIAC-1's identity check extended to the grammar names; mirror suite the single-source assertion; the position-tool self-test a parse-status fixture with its `clean` control. CIAC-3's arm is unchanged and green over the rewritten `parse_dependencies`.

### #6398 — change specification (slice 3; Stage-5 design on #8703 as the scope lock and the A6.5 review on #8780 amended it)

**Files:** `release/tools/_epic_child_set.py`, `release/tools/audit-epic-rollup-close.sh`, `release/tools/compute-chain-head-rollup.py`, `release/tools/tests/test_compute_chain_head_rollup.py`, `core/deploy/allowlists/selftest-coverage-manifest.txt`, `core/config/allowlists/script-execution-allowlist.txt`, `.github/workflows/release-tooling-smoke.yml`, the chain-head ADR (`core/ADRs/`, ADR-237 after the Stage-12 renumbers in DEV-30 and DEV-31, `Proposed`), `core/specs/label-taxonomy.md`, `core/standards/initiative-roadmap-framework.md`, `roadmaps/README.md`.

**One child-set rule (D4-7, SR-G6 net-new).** `_epic_child_set.py` holds the G1a rule — native sub-issues union `epic:`-label links, the carrier excluded, a native row winning a duplicate — as the pure `child_set(epic, native_rows, label_rows)` returning `(native, label_only)`, plus `union()`. It is net-new because extending in place is infeasible: the rule lived inside a single-quoted `python3 -c` program no second reader can load. The audit's `classify` loads it by path from `SCRIPT_DIR` through a plain shell global (not an environment default, so an inherited variable cannot redirect it); a failed load exits 1, with no inline fallback. Its classifier fixtures 1–13 and K-1..K-4 are unchanged and green; arm 14 asserts the load, with a missing-module control. The two comments that called `classify` free of file I/O now say what it reads, and the exit-code line names the new exit-1 cause.

**The view (D4-1, D4-2, D4-6).** `compute-chain-head-rollup.py` — `fetch_snapshot()` is the only code that calls the host (REST through `gh api`: labels, open issues, the open-issue search total, and each open epic's sub-issues and `epic:`-label links); `derive(snapshot, grammar, child_rule)` is pure; `render_markdown()` and `--json` (schema v1) format it. It writes no file and keeps no cache. Exit 0 renders, unmeasured facets included; exit 1 for a usage error, an unreadable or empty population, more open issues than `--limit`, a broken partition sum, no standing initiative, or a module that will not load.

- **Heads (D4-3, R4).** Every `project:` label with an open issue is an initiative head; a label with none is listed empty. Every label-less open epic is a lone-epic head unless more than half of its children over all states carry one standing label, in which case it renders inside that initiative as a flow container; a tie, a half share, an empty child set or a failed child-set read leaves it a head, the last marked `absorption: unmeasured`.
- **Standing (D-6398-Standing).** A label whose description, left-stripped, begins with the word `Standing` is standing: its head shows no percentage. No standing label stops the run with exit 1 and an error naming the cause.
- **Members and the partition (FM-1).** Members are open issues carrying the label that are not epics or sub-tasks; each is in an epic tree of the head, parented outside it, or unparented, and the three must sum (exit 1 otherwise). A missing `parent_issue_url` key means no parent. The facet, and the partition, read unmeasured only when the host serves the field on no open issue while some issue reports sub-issues, or serves neither the field nor the sub-issue summary on any open issue (DT iteration 1 — DEV-27); the sum is asserted only when measured.
- **Edges (CIAC-4, CD-1).** Edges come from the parser's `parse_dependencies`, loaded by path; the view defines no grammar. `clean` is measured; any other status (today `deferred`) is unmeasured and out of the blocked count. Each member also carries `edges.section` (`present` / `absent`, from the parser's `extract_section_aliased` over `DEP_HEADING_ALIASES`) and `native_blocked_by_open` (the REST `issue_dependencies_summary.blocked_by`); an absent section with open native blockers is unmeasured, never "not blocked". A target is tagged `in_open_set`; a member is blocked when one is.
- **Progress.** A finite epic: closed `completed` children over its child set, `not_planned` reported beside; an empty set is undefined and a failed read unmeasured. A finite head sums its finite epics. A standing head and every flow container are not-applicable.
- **Drill-down and order.** Head, then epics and flow containers (open-child count descending, then number), then each node's open children (by number; closed children count in progress). `meta.ordering.is_sequence` is `false` and the Markdown says the order is not a sequence. The milestone-chain payload is not a render input (R5); each child carries its milestone. A failed child-set read renders the node's open children unmeasured, and a lone-epic head's blocked facet unmeasured — `status`, null counts and a reason — never "No open children" or 0 (D-6398-Q01, DT iteration 2); an initiative head counts blocked over its members, so its count stays measured.
- **Encoding.** Every interpolated title, description and milestone passes through `md_cell()` (ampersand, angle brackets, backtick and square brackets to entities, the pipe escaped, line breaks folded).

**Integration criteria (restated against the live statuses, DEV-11).**

- [ ] **INT-1 (vs #6397):** for every fixture body in `test_compute_chain_head_rollup.py`, the targets the view records equal the targets `parse_dependencies` returns for the same body, with no second parse, filter or union. *Method:* `grep -c -F "INT-1 view edges equal parse_dependencies targets" release/tools/tests/test_compute_chain_head_rollup.py` at least 1, and the suite step passes. *Graded at Stage 8 Phase B.*
- [ ] **INT-2 (vs #6397):** a body whose Dependencies parse is not `clean` — today the `deferred` status, the only other value `parse_dependencies` returns — has its edges recorded unmeasured and is left out of the blocked count; it is never shown as having zero blockers. *Method:* `grep -c -F "INT-2 non-clean dependency parse renders unmeasured edges" release/tools/tests/test_compute_chain_head_rollup.py` at least 1. *Graded at Stage 8 Phase B.*

**Tests.** The suite's 15 arms carry the design's labels verbatim — AC1, AC2, AC3 (and its control and guard), AC4 (substitution and source scan), AC5 (unmeasured, measured-zero control, and the keyless member), INT-1, INT-2, CD-1, CIAC-4, the four EVG arms, PART, ENC, ORD, G1A — and, from DT iteration 2, Q01 (a failed child-set read renders unmeasured), each with a control where a pass could be vacuous. The view's `--self-test` (9 checks) and `_epic_child_set.py --self-test` (ST-1..ST-4 and a control) join the selftest manifest; the suite runs as an unmasked step of the required `closeout-smoke` job.

**Documentation (the card's three Documentation Impact rows, and R8).** The label taxonomy states that standing is declared on the label (with the guard) and gains `#### Derived chain-head view` — a design-artifact marker and a producer/consumer table — at the end of § Initiative Labels; its dead "§6.1(f)" citation now names §7.6 criterion (f), the `sunset_criteria` field of §6.1. The roadmap framework gains § 4.6 (the view is a read surface, not a roadmap). The roadmaps README points at the live command.

**AC6 (D-6398-AC6)** is the operator's post-merge step on the git-ignored interim board — retire its portfolio map and point its README at the view, keeping the milestone lanes until #6443 ships — read and recorded at Stage 13 close-out against the closed card, because the step follows the merge and Stage 8 runs before it (D-6398-AC6-ReadPoint, DEV-28). Neither this slice nor the view edits that board.

### Tier-A Activated Design Artifacts

| Artifact path | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| `core/specs/label-taxonomy.md` § Initiative Labels → `#### Derived chain-head view` (embedded, with marker) | data-flow | a new output-format contract with two or more producers and consumers (the REST snapshot, the child-set module and the grammar home feed the rollup; the operator and later tools read it) | A (NEW) | Stage 13 confirms the region matches the shipped tool |

---

## Stage Applicability Matrix

| Card | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|
| #7177 | APPLY (ran; joint S5-D1 with #6397) | APPLY (slice 1) | APPLY | APPLY | APPLY (Deep) | COMPRESS (platform-satisfied) | COMPRESS (platform-satisfied) | APPLY (release-scoped) | APPLY (release-scoped) |
| #6397 | APPLY (ran; joint S5-D1 with #7177) | APPLY (slice 2) | APPLY | APPLY | APPLY (Deep) | COMPRESS | COMPRESS | APPLY | APPLY |
| #6398 | APPLY (ran; consumes S5-D1's grammar home) | APPLY (slice 3) | APPLY | APPLY | APPLY (Deep) | COMPRESS | COMPRESS | APPLY | APPLY (AC6 operator step read and recorded at close-out) |

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
core/deploy/allowlists/skip-tool-exec-mode-check.txt  EDIT
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

**Rows added since Stage 4 (Tier 1 [ADJUST], recorded at the scope lock):** the shared-home ADR and its index row (slice 1's design, R3); `_epic_child_set.py`, the epic rollup-close audit and the chain-head ADR (slice 3's design, R1, recorded as net-new at the scope lock); the script-execution allowlist row (a scope-lock Stage-6 fix). Both ADR rows carry the `NNN` placeholder rather than a number, because an ADR number is allocated at authorship and bound at merge: the shared-home record is provisionally 230 (the mainline next-free at Commit 0), and the chain-head record takes the next number on this branch in slice 3; either may move under `release/tools/renumber-adr.py` before the merge — both did, at the Stage-12 claim: to 234 and 235 (DEV-30), then to 236 and 237 (DEV-31).

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
| R-13 | **Un-headed trailing text joins a section.** With no whitespace terminator, text after a blank-line gap that is neither an H2 or H3 heading nor a break line is read as part of the section | slice 1 | Measured at Commit 0: identical caller output, pre-repair vs repaired, on every open body and every frozen body (§ Verification Evidence); recorded as a residual in the shared-home ADR | CHEAP / MEDIUM |
| R-14 | **A break line ends a section the old extractor read past**, including a hyphen line inside a fenced example (the extractor was already fence-blind for headings) | slice 1 | Measured at Commit 0: the sections the repaired extractor ends at a break line with no gap before it are provenance footers, and no caller output changes | CHEAP / MEDIUM |

Rollback complexity is CHEAP for the release (§ Rollback Strategy).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#6397 × #7177 on the shared-home seam):** the single-sourced extractor and direction grammar load with no import cycle between `bundle-issues-parser.py` and `native-dep-mirror.py`. *Method:* `grep -c -F "CIAC-1 no import cycle between the parser and the mirror" release/tools/tests/test_bundle_issues_parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR;* the suite's CI step grades the arm's behaviour.
- [ ] **CIAC-2 (#6397 × #7177 on `release/tools/bundle-issues-parser.py`):** neither restructuring removes the FC-1d fixture string that milestone 381's #42 AC1 expects in the parser. *Method:* `grep -c -F "pmo-platform/engineering/" release/tools/bundle-issues-parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7177 × #6397 on `parse_dependencies`):** after #6397 rewrites `parse_dependencies`, a Dependencies section whose heading carries a doubled blank line, or that carries one between its lines, still reads the same targets and the same status as its single-blank form — #7177's blank-line-invariant extraction survives the directed parse. *Method:* `grep -c -F "CIAC-3 blank-line-invariant extraction survives the directed parse" release/tools/tests/test_bundle_issues_parser.py` at least 1. *Graded at Stage 9 QC3.5 on the merged PR;* the suite's CI step grades the arm's behaviour.
- [ ] **CIAC-4 (#6397 × #6398 on the direction grammar):** the chain-head view takes its dependency edges from the same single-sourced grammar `parse_dependencies` uses — no third grammar and no naive number scrape. *Method:* declared, verification deferred to #6397 AC-1 and #6398 AC-4 — the latter through the `CIAC-4 view loads the single-sourced grammar` arm of the view's suite (slice 3). *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 body read `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6. CIAC-3 is restated under D-7177-Extractor (DEV-4): the Stage-4 text asserted a degraded extractor verdict that no longer exists. The operator confirmed the restatement before Stage 9 (D-CIAC3-Restated).

---

## Verification Plan

**AC baseline:** #7177 = **5** criteria, #6397 = **5**, #6398 = **6**, read by the governed parser on the live bodies at Engineering Commit 0 (the counts the Stage-4 plan recorded at `ac96b3ea`; the scope-lock restatements of #7177 AC5 and #6398 AC6 changed no count).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7177 | AC-1 | `grep -c -F "7177-AC1 blank-line tolerance" release/tools/tests/test_bundle_issues_parser.py` at least 1 [READER-GRADED — `extract_section` returns the section after one, two or three blank lines; the arm runs in the CI-wired suite step of release-tooling-smoke.yml and carries the pre-repair sensitivity arm] | at least 1 (0 at the base) |
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
| #6398 | AC-6 | [DEFERRED — operator post-merge step on the git-ignored interim board, read and recorded at Stage 13 close-out (D-6398-AC6-ReadPoint): the portfolio map retired, the milestone lanes kept until #6443 ships] | the map retired; its README points to the view |

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

Committed as Engineering Commit 0, `5c6ea3fd`.

### Plan step 1 (#7177) — Stage 6 C4

Run by the Stage-6 spoke on #8696 against slice 1's commit `5634b68e`, on Python 3.9.6 (the parser and the mirror compile; no `Union`, no `from __future__ import annotations`).

| Check | Command | Observed |
|---|---|---|
| Parser regression suite | `python3 release/tools/tests/test_bundle_issues_parser.py` | exit 0, `TEST OK`; combined-clean 39/40 = 97.5%, unchanged; section-read arms 6 run, 0 failures. The AC4 arm doubled a blank line after a heading in 33 frozen bodies and inside a section in 8; the pre-repair extractor's clean count on the after-heading bodies falls 32 → 0, so the arm bites |
| Tool self-tests | `python3 release/tools/bundle-issues-parser.py --self-test` · `python3 release/tools/native-dep-mirror.py --self-test` · `python3 release/tools/compute-milestone-positions.py --self-test` | `SELF-TEST OK` ×3 — the parser's SX-1..SX-4 and the mirror's cases 23 and 24 included |
| Mirror frozen suite | `python3 release/tools/tests/test_native_dep_mirror.py` | exit 0, `TEST OK`, 20 cases |
| RED arm | the new suite run against the parser and the mirror taken from the base (`git show b1042eec:<path>`), with the suite, its fixtures and the G-CL8 engine beside them | exit 1 — all 6 section-read arms fail, 13 failures: AC1 and CIAC-1 raise on a mirror with no load seam, AC2 reads a break line as section text, AC4 moves a body from clean to failed, AC5 drops the text after each doubled blank line, CIAC-3 reads the doubled form as empty. The frozen-sample legs still pass there, so the failures are the new arms' alone |
| Precision probe | the `release-tooling-smoke.yml` probe's priority-detector mutation applied to a throwaway copy of `release/tools/` | anchor found exactly once; the suite exits 1 and its output carries `T-13 liveness`, so the probe's pass condition holds with the new arms present. One further failure line appears in that copy — AC5's misheaded leg cannot load the G-CL8 engine, because the copy has no `core/` beside it — which the probe does not read |
| Live equivalence | the pre-repair and repaired tools compared on every open body and every frozen body (probe record below) | identical caller output on 814 of 814 open bodies and 40 of 40 frozen bodies |
| Degraded-root arm | `bash core/deploy/tests/test_g1_form_family.sh` | exit 0 — 41 passed, 0 failed; arm G's control holds (`F0/F1 cards are still fully evaluated under a degraded vocabulary`), so the parser still loads alone |
| Package consequence | `printf '%s\n' <the seven changed paths> \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled. Sensitivity arm: `release/skills/release-planner/references/dependency-analysis.md` on the same reader resolves `release-planner` |
| Skill-roster totals | `python3 core/deploy/tools/check-skill-count-imp.py --files <this file>,<the ADR>,release/ADRs/README.md --mode both` | exit 0, no finding; its self-test passes 19 invariants |
| Plan verifier | `bash release/tools/verify-release-plan.sh release/releases/plans/sequencing-layer-foundation_RELEASE_PLAN.md` | exit 3 — 9 PASS / 4 FAIL / 25 SKIP / 5 UNRUNNABLE / 0 ERROR over 43 records. `FCM-COVERAGE` PASS (32 of 32 interpreted); FCM-1 and FCM-2 PASS (this file and the shared-home ADR, the latter matched through the `NNN` placeholder); FCM-3..FCM-6 FAIL — slice 3's ADDs, not yet delivered; CIAC-1..CIAC-3 PASS; CIAC-4 SKIP (declared). The five #7177 rows read UNRUNNABLE: each grep limb PASSes (count 1, 0 at the base) and the reader-graded limb — the arm's behaviour, graded by the CI suite step — is not graded by this executor, which the verifier states rather than counting as a pass |
| Runtime-suite selection | `release/references/standards/runtime-suite-selection-map.md` rows 4 (`release/tools/*.py`) and 6 (`release/tools/tests/*.py`) | row 6's suite is the parser suite above. Row 4: `python3 release/tools/check-selftest-coverage.py --run` exit 1 — **77 of 78** discovered self-tests pass, the parser's, the mirror's and the position tool's among them; the one failure is `release/tools/cleanup-orphan-state.sh --self-test`, which hit the runner's 300-second per-tool timeout (exit 124). That tool is unchanged since the base and names neither tool nor the suite (0 references); its self-test walks every process's working directory through `lsof`, which this busy workstation made slow (8.6 s of CPU in over 4 minutes). It is recorded **NOT-EVALUATED here**, not as a pass and not as a regression; the `selftest-discovery` job on #8811 is the enforced reading. `--reconcile`: `RECONCILE VERDICT: CLEAN`. The `test-run` event is not emitted by this spoke — the pipeline-event log is an operator-instance surface outside its write boundary; Stage 7 Phase A8 re-runs both rows as the gate input |
| Close-keyword self-check | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | exit 0, CLEAN, over 2 commits, before each push |
| Draft PR (C2) | `gh pr create --draft` with the title, the body from the template, the milestone, the union of the three cards' labels, `--assignee @me` and `--reviewer` | **#8811**, draft, read back with its milestone, 11 labels and an assignee; the reviewer field reads empty, the expected self-review no-op. `--project "PMO Pipeline"` was rejected by the CLI ("not found"), which aborted the first attempt with no PR created; the PR was created without it. The body's close-keyword arm: 0 matches outside the Issue References block |

**Probe record for the live-equivalence zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       per body, compare under the pre-repair tools (from the base) and the repaired
             tools: Affected Files (paths, status), Dependencies (set, status), Acceptance
             Criteria (present, count), Documentation Impact presence (is not None, the test
             both G3-20 readers make), and the mirror's eligible and unattributed sets
Denominator: 814 open bodies (gh issue list --limit 5000 returned 814, equal to the search
             total_count 814, so not truncated); 40 frozen bodies
             (release/tools/tests/conformant_bundleable_sample.json)
Control - sensitivity: a body whose Affected Files and Dependencies headings each carry two
             blank lines -> the two tool sets differ (True)
Control - specificity: the same body with one blank line -> the two tool sets agree (True)
Extraction:  814 bodies, 4,382,915 bytes, 0 empty; 40 frozen bodies, 205,454 bytes
Result:      0 differing bodies on the live set; 0 on the frozen set
Verdict:     CLEAN
```

**The break-line class (R-14).** Of 2,105 parser-read sections on the live set, 4 end at a break line, and 3 of those have no blank-line gap before the break — the only sections the old extractor read past. Each is followed by a provenance or reconciliation footer (on #6637's Affected Files, #5280's and #5064's Acceptance Criteria), and none changes a read. On the frozen set, 10 of 128 sections end at a break line, every one after a gap — the separator footers the Stage-5 design measured. Sensitivity: a constructed section with a break line and no gap before it is counted (1 of 1).

**Reference cascade (DTA-7).**

```
[REFCASCADE: git grep -c -w -F SECTION_HEADING_RE over release/tools/native-dep-mirror.py → pre 2 / post 0]
[REFCASCADE: git grep -c -F 'n\s*\n\s*\n' over release/tools/bundle-issues-parser.py + release/tools/native-dep-mirror.py → pre 2 / post 0]
[REFCASCADE: git grep -c -F '13 legs' over .github/workflows/release-tooling-smoke.yml → pre 2 / post 0]
```

`extract_section_with_alias` and `extract_section_aliased` keep their names in the mirror (DEV-3): the definition moved from the mirror to the parser (`def extract_section_with_alias` pre 1 in the mirror, post 0 in the mirror and 1 in the parser), and the call sites stay by design. The Stage-5 mirror sweep reads 10 lines before and 5 after — the three bindings, the rewritten header comment, and the unchanged caller; the "mirrors bundle-issues-parser" and "canonical body parser" phrases read 0. The parser sweep reads 3 before and 2 after: the module docstring's opening line (still true; the shared-home role is stated in the paragraph added beneath it) and a self-test comment that describes the old defect (PRESERVE). The test file's reference copy of the old terminator is the RED arm's instrument and is out of the sweep's scope.

### Plan step 2 (#6397) — Stage 6 C4

Run by the Stage-6 spoke on #8700 against slice 2's commits `3c3acb6c` (the grammar move and the directed parse) and `00785cd4` (the position tool and G3-07), on Python 3.9.6. The live reads are one snapshot taken on 2026-11-05 at 18:45Z: 799 open issues (equal to the search total of 799, so not truncated) and 57 open milestones, none of which carries `position:`.

| Check | Command | Observed |
|---|---|---|
| Parser regression suite | `python3 release/tools/tests/test_bundle_issues_parser.py` | exit 0, `TEST OK`; combined-clean 39/40 = 97.5%, unchanged; section-read arms 6 run, 0 failures; direction-grammar arms 2 run, 0 failures. `6397-AC1` read all 40 frozen bodies through the grammar, and the old scrape reads 26 of them differently, so the arm is not vacuous |
| Tool self-tests | `python3 release/tools/bundle-issues-parser.py --self-test` · `python3 release/tools/native-dep-mirror.py --self-test` · `python3 release/tools/compute-milestone-positions.py --self-test` | `SELF-TEST OK` ×3 — the parser's DG-1..DG-22, the mirror's case 25, and the position tool's parse-status fixture with its `clean` control included |
| Mirror frozen suite | `python3 release/tools/tests/test_native_dep_mirror.py` | exit 0, `TEST OK`, 20 cases; the grammar is read from `bundle_issues_parser` |
| RED arm | both suites run against the parser and the mirror taken from `6b76da98`, the slice's base, with the suites, their fixtures, the G-CL8 engine and its `_frontmatter.py` beside them | parser suite exit 1 with 7 failure lines, every one a new arm: `6397-AC1` ×5, `6397-AC2` ×1 (it raises: the old parser has no `unattributed_refs`), `CIAC-1` ×1 (the grammar names are not the parser's objects). The `7177-` arms, CIAC-3, the 90% floor and T-13 read 0 there. Mirror suite exit 1 on the single-source assertion |
| Mutation probes | each on a copy of the shipped tools; the unmutated copies exit 0 on all five runs | M1, the undirected scrape restored: 17 DG lines in the parser self-test, and both `6397-` arms in the suite. M2, the negation rule removed: DG-13..DG-18 and DG-20, 8 `6397-AC2` lines, and mirror case 25. M3, the position tool discarding the status again: its parse-status arm. M4, the mirror defining its own `parse_body_dependencies`: `6397-AC1`, `CIAC-1` and the mirror suite |
| AC3 (snapshot) | the position tool's own `aggregate_edges` and `derive_positions` over the snapshot, once per parser: the base parser (`6b76da98`), the shipped parser, and the shipped parser with the negation rule disabled | the old scrape: 647 issue-level refs, 19 milestone edges, **10** cycle-resident (ms 349, 358, 360, 361, 365, 382, 406, 407, 408, 417). Directed: 154 refs, 4 edges, **0**. Directed without the negation rule: 177 refs, 5 edges, 0 — the rule removes one milestone edge, 408 → 349, a merge-order gate its author disclaimed as a blocker. Every body reads `clean`, so the new parse-status line fires on none |
| AC3 (the live command) | `python3 release/tools/compute-milestone-positions.py --dry-run` at 19:03Z | exit 0; no `CYCLE:` block; 68 unresolvable edges listed; "would PATCH 57 milestone(s)". The open-issue search total read 798 at that moment |
| G3-07 text against the code | each behaviour the Edge-source paragraph states, run through `parse_dependencies` | 17 of 17 hold, the imprecisions it names included: `requires` mid-sentence opens a segment, and a segment runs past its sentence to the next recognised label |
| Reference durability | the link, cutover, raw-URL and issue-reference detectors of `core/hooks/lib/fragile-ref-patterns.sh`, read as patterns, over the lines this slice adds to `core/schemas/gate-criteria-spec.md` | 0 on each over 2 added lines; a seeded control line fires each detector once |
| Doc links | `python3 core/deploy/tools/check-doc-links.py --target-paths core/schemas/gate-criteria-spec.md --require-targets`; `python3 release/tools/check-release-links.py --roots core --files core/schemas/gate-criteria-spec.md --check-anchors` | exit 0, no findings; 0 broken links |
| Degraded-root arm | `bash core/deploy/tests/test_g1_form_family.sh` | exit 0 — 41 passed, 0 failed; the parser still loads alone |
| Package consequence | `printf '%s\n' <the seven changed paths> \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled. Sensitivity: the release-planner dependency reference resolves `release-planner` |
| Runtime-suite selection | `release/references/standards/runtime-suite-selection-map.md` rows 4 and 6; row 8 for the gate specification | row 6: the two suites above. Row 4: `python3 release/tools/check-selftest-coverage.py --run` exit 1 — **77 of 78** discovered self-tests pass, the parser's, the mirror's and the position tool's among them; the one failure is `release/tools/cleanup-orphan-state.sh --self-test`, which hit the runner's 300-second per-tool timeout (exit 124) as it did at slice 1. That tool is unchanged by this slice, so it is recorded **NOT-EVALUATED here**, not as a pass and not as a regression; the `selftest-discovery` job on #8811 is the enforced reading. The killed self-test left its mutated script copy untracked in `release/tools/`, as at slice 1; it was this run's own artifact and was moved to the Trash before the commit. `--reconcile`: `RECONCILE VERDICT: CLEAN`. Row 8: the gate specification maps to no suite. The `test-run` event is not emitted by this spoke — the pipeline-event log is outside its write boundary |
| AC5, deploy-check limb | — | not run here (DEV-17): Stage 7 diffs the `  FAIL:` lines against the `b1042eec` baseline |
| Plan verifier and CIAC lint | `bash release/tools/verify-release-plan.sh <this file>`, and with `--ciac-lint` | exit 3 — 9 PASS / 4 FAIL / 25 SKIP / 5 UNRUNNABLE / 0 ERROR over 43 records, as at slice 1; the 4 FAILs are slice 3's ADDs; CIAC-1..CIAC-3 PASS, CIAC-4 declared. The lint reads `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0` |
| ADR index | — | N/A — this slice adds no record under `release/ADRs/` |
| Close-keyword self-check | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | exit 0, CLEAN, before each push |

**Probe record for the AC3 directed zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       compute-milestone-positions.py aggregate_edges + derive_positions over the
             snapshot, its records built from the shipped parse_dependencies; the count of
             cycle_members
Denominator: 799 open issues (gh issue list --limit 5000 returned 799, equal to the search
             total 799); 57 open milestones (REST, paginated); 397 Dependencies sections
Control - sensitivity: the same code over the same snapshot with the base parser -> 10
Control - specificity: NOT TRIGGERED — cycle membership is computed, not matched, so it has
             no lexical near-miss; the tool's own self-test pairs an X <-> Y cycle with an
             acyclic Z
Extraction:  799 bodies, 4,360,185 bytes, 0 empty, read by every arm
Result:      0
Verdict:     CLEAN
```

**Probe record for the stderr exposure** (the moved grammar warns on stderr for a comma-grouped token, and Check 52 captures the position tool's output with stderr merged):

```
Probe:       parse_dependencies and unattributed_refs from the shipped parser on each snapshot
             body, stderr captured; the count of bodies that write to it
Denominator: 799 open bodies, 397 Dependencies sections
Control - sensitivity: a comma-grouped token in a Blocked by segment, and in unlabelled
             prose -> each writes
Control - specificity: the same number without the separator, and a comma after a whole
             reference -> neither writes
Extraction:  799 bodies, 4,360,185 bytes
Result:      0
Verdict:     CLEAN
```

**Reference cascade (DTA-7).**

```
[REFCASCADE: git grep -nE '^(SEGMENT_LABELS|_SEGMENT_LABEL_RE|_LABEL_KIND_BY_GROUP|DEP_TOKEN_RE|_LIST_MARKER_RE|_PROSE_WORD_RE|DIRECTIONAL_HEADINGS)[ :=]' over release/tools/native-dep-mirror.py → pre 7 / post 0]
[REFCASCADE: git grep -nE '^def (_is_bare_ref_run|_attribute_segments|_parse_token|_segments_for_body|unattributed_refs|parse_body_dependencies)|^class BodyDep|native-dep-mirror: skipping' over release/tools/native-dep-mirror.py → pre 8 / post 0]
[REFCASCADE: git grep -nwF DEP_RE over release/tools/bundle-issues-parser.py → pre 2 / post 0]
```

The first two sweeps read 7 and 8 over the parser after the change — the definitions' new home — so the mirror's zeros are not a blind probe. The public names keep their call sites by design, because the mirror binds them: `parse_body_dependencies` in the Stage-2 triage shard's and the ticket specification's pseudocode, the runner string in `check-doc-gates.py`, and both suites read unchanged (PRESERVE). The position tool's method paragraph and its `gh_open_issues` docstring are updated in place to say the edges are directed; its "reuse parse_dependencies() as-is" comment is PRESERVE, still true. The shared-home ADR already records the grammar's move into this home and needs no edit.

### Plan step 3 (#6398) — Stage 6 C4

Run by the Stage-6 spoke on #8704 against slice 3's commits `94483098` (the shared child-set rule and the audit), `3da7400b` (the view, its suite, the manifest, the allowlist and the smoke step) and `a0599135` (the chain-head ADR and the three documents), on Python 3.9.6. `origin/main` is still `b1042eec`.

| Check | Command | Observed |
|---|---|---|
| Chain-head suite | `python3 release/tools/tests/test_compute_chain_head_rollup.py` | exit 0, `TEST OK` — 14 arms, 0 failures |
| Tool self-tests | `python3 release/tools/compute-chain-head-rollup.py --self-test` · `python3 release/tools/_epic_child_set.py --self-test` · `bash release/tools/audit-epic-rollup-close.sh --self-test` | PASS 9 of 9 · PASS (ST-1..ST-4 and a control) · PASS — classifier fixtures 1–13, K-1..K-4, and arm 14 with its missing-module control |
| RED arm | the new suite run against the parser and the audit taken from `47d27e70`, the slice's base | exit 1 — neither new module exists there, and the base audit still carries the inline union the G1A arm rejects |
| Mutation probes | eleven mutants, each on a copy of the shipped tool; the unmutated copy is the control (exit 0) | each turns its own arm red: a naive scrape in the view (AC4, INT-1, INT-2); a missing key read as unmeasured (AC5, PART); no standing guard (AC3); a standing percentage (AC3); an absent section read as measured (CD-1); a deferred parse read as measured (INT-2); a half share absorbed (EVG); no encoding (ENC); an inline child set (G1A); a sequence claim (ORD) |
| Live run (AC1, AC2, AC5, FM-1) | `python3 release/tools/compute-chain-head-rollup.py --json` at 19:42Z, read-only | exit 0. 792 open issues, equal to the search total; 59 reads, 0 failed. 10 initiative heads, one per `project:` label with members, and the eleventh label listed empty; 0 lone-epic heads, the 6 label-less epics absorbed into the standing initiative at shares from 60/94 to 90/90. The parent field reads measured, and the unparented counts read measured on every head — 7, 5 and 3 on the three heads the A6.5 review named, 0 on the rest; every partition sums. The standing head shows no percentage. 3 child edges read unmeasured under CD-1, and 1 child is outside the open-issue read. The same rollup rendered as Markdown: 1,096 lines, 56 balanced `<details>` blocks, 619 child rows, none malformed |
| Discovered self-tests (selection-map row 4) | `python3 release/tools/check-selftest-coverage.py --run`, and `--reconcile` | exit 1 — **79 of 80** pass, the view's, the child-set module's and the audit's among them; `cleanup-orphan-state.sh --self-test` hit the 300-second per-tool timeout (exit 124) as at slices 1 and 2, untouched by this slice, recorded **NOT-EVALUATED** here (the `selftest-discovery` job on #8811 is the enforced reading); it left no stray copy this time. `--reconcile`: `RECONCILE VERDICT: CLEAN`, Arm F 10 of 10 admitted |
| Install regression (selection-map row 5, for the allowlist) | `bash core/deploy/tests/run-install-regression.sh` | exit 0 — `INSTALL-REGRESSION: 3392 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`, the hook-test floor included |
| ADR gates | `check-adr-numbers.py`; `check-adr-durability.py --files <the record> --diff-base origin/main`; `generate-adr-index.py --verify`; `renumber-adr.py --detect` | numbering PASS, contiguous 001..231; durability `COUNT 0` (its self-test passes 156 of 156); index `COUNT 0`; both branch claims `BINDS` |
| ADR index | — | N/A — this slice adds no record under `release/ADRs/`; the chain-head record is under `core/ADRs/`, whose README is curated, not an index |
| Doc links | `check-doc-links.py --target-paths <the four documents> --require-targets`; `check-release-links.py --roots core roadmaps --files <the same> --check-anchors` | exit 0, no findings; 0 broken. Four missing-anchor notes name glossary links on lines this slice does not edit (warn mode) |
| Label parity | `check-label-parity.py` over the taxonomy and the three packs, as Check 51 reads them, at the base taxonomy and at the edited one | identical 51-line output and the same pre-existing exit 1; the taxonomy alone yields zero label rows at both, so the new table adds none |
| Check 55 H1 | `check-work-hierarchy.py --skip-backlog` | `COUNT 0` over 987 scanned documents |
| Workflow | the smoke workflow parsed as YAML | `closeout-smoke` has 27 steps; the 5 unmasked suites are the ones its rationale now counts |
| Package consequence | `printf '%s\n' <the 12 changed paths> \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled. Sensitivity: the release-planner dependency reference resolves `release-planner` |
| Skill-roster totals | `check-skill-count-imp.py --files <the four documents> --mode both` | exit 0, no finding |
| Plan verifier and CIAC lint | `bash release/tools/verify-release-plan.sh <this file>`, and with `--ciac-lint`; `claim-version.sh --verify-stamp sequencing-layer-foundation` | exit 0 — 13 PASS / 0 FAIL / 25 SKIP / 5 UNRUNNABLE / 0 ERROR over 43 records; FCM-3..FCM-6 now PASS (every ADD delivered); the 5 UNRUNNABLE are #7177's reader-graded rows, as before. The lint reads `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`; the stamp check passes |
| Identity, host URL and close-keyword scan | a python scan of each commit's added lines | 0 in every class on every commit; a seeded control line fires every class. The only issue numbers in a durable document are the three in the chain-head ADR's References block |
| Close-keyword self-check | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | exit 0, CLEAN, before each push |

**Probe record for the live unparented and failed-read readings** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       compute-chain-head-rollup.py --json, live; per head the unparented status and
             count, the partition sum, and the count of reads whose status is not ok
Denominator: 792 open issues (REST list 792, equal to the search total 792); 11 project
             labels; 56 open epics, 59 reads in all
Control - sensitivity: the suite's AC5 arm on a population whose rows carry no parent key
             while an epic reports sub-issues -> unmeasured (and the M2 mutant, which reads
             a missing key as unmeasured, turns AC5 red)
Control - specificity: the AC5 keyless arm — a member with no key among members that carry
             it -> counted unparented, measured
Extraction:  the whole rollup document; every head, node and read row
Result:      unparented measured on all 10 heads (7, 5, 3, and 0 on 7 heads); 0 failed reads
Verdict:     CLEAN
```

**Cascade sweep (narrative counts this slice changes).** `git grep -c -F` for the four replaced phrasings ("ONE GROUP SINCE", "the one group below", "the two below because all three", "the four trailing") over the allowlist and the smoke workflow reads 4 at `origin/main` and 0 at the head; their replacements read 3. Kept as written, each a dated measurement rather than a census: the allowlist's "32 tools" and "289 non-comment entries", and the workflow's "78 discovered = 74 ubuntu + 4 macOS" (whose own text says to read the live split from the engine) and "all six newly-wired suites". The workflow's header names suites selectively — it omits several already-wired suites — so it gains no entry.

**Deliverable state:** `deployed-copy-synced` for slice 3 — no matrix path has a deployed copy.

### DT iteration 2 — Stage 6 Phase E

Run by the Stage-6 spoke on #8704 against `bd19879b`, on Python 3.9.6, for the operator's pre-Stage-9 decisions (DEV-29). `origin/main` is still `b1042eec`. The live reads are one REST snapshot taken on 2026-11-05 at 23:12Z: 749 open issues, equal to the search total of 749 read before and after, and 57 open milestones; no measurement below reads through GraphQL.

| Check | Command | Observed |
|---|---|---|
| Parser regression suite | `python3 release/tools/tests/test_bundle_issues_parser.py` | exit 0, `TEST OK`; combined-clean 39/40, unchanged; section-read arms 6 run, 0 failures; direction-grammar arms 2 run, 0 failures |
| Chain-head suite | `python3 release/tools/tests/test_compute_chain_head_rollup.py` | exit 0, `TEST OK` — 15 arms, 0 failures; INT-2 and the EVG arms pass unchanged |
| Tool self-tests | the parser's, the mirror's, the position tool's, the view's and the child-set module's `--self-test` | `SELF-TEST OK` ×3 and PASS ×2; the view's 9 checks unchanged |
| Mirror frozen suite | `python3 release/tools/tests/test_native_dep_mirror.py` | exit 0, `TEST OK`; the grammar is read from `bundle_issues_parser` |
| RED arm, parser | the new parser suite against the parser and the mirror from `beb07cf4`, with the G-CL8 engine and `_frontmatter.py` beside them | exit 1 with 11 failure lines, every one a new `6397-AC2` row: the two later-paragraph rows (3 each), the `Blocks`-paragraph row (1), `_not_` and `__not__` (2 each). The four new edge controls pass there, and the section-read arms read 0 |
| RED arm, view | the new chain-head suite against the view, the parser, the child-set module and the audit from `beb07cf4` | exit 1 — only `arm_q01` fails, with 4 lines (blocked `{count 0, unmeasured 0}`, the Markdown cell `0`, "No open children", no unmeasured line); every other arm passes, 14 of 15 |
| Mutation probes | each on a copy of the fixed view | the node-block branch reverted: `arm_q01` alone, 2 lines; the lone-epic blocked branch reverted: `arm_q01` alone, 2 lines |
| Live re-measure | `parse_dependencies` and `unattributed_refs` over every snapshot body, through the `beb07cf4` parser and the fixed parser | directed references **154 → 153**: removed #7466 → #7889, added none. Unattributed references 116 → 120: added #42 → #43, #44 and #45 (still directed from #42's first line) and #7466 → #7889, removed none. Every body reads `clean`; 0 stderr bytes |
| AC3 (snapshot) | each tree's own `compute-milestone-positions.py` `run_dry_run()`, with only `subprocess.run` answered from the snapshot | fixed head: 153 references, 4 milestone edges, **0** cycle-resident, no `cycle` line, 68 unresolvable. `beb07cf4`: 154, 4, 0. `b1042eec`, the naive arm: 647 references, 19 edges, **10** cycle-resident (ms 349, 358, 360, 361, 365, 382, 406, 407, 408, 417) |
| Underscore negation, live | the spelling's pattern over every Dependencies section | 0 of 397 sections; 19 sections carry "not blocked by", and no reference in them is newly read as a target, since the fixed parser adds no directed reference |
| G3-07 text against the code | each claim the reconciled Edge-source paragraph makes — the segment end, the label-to-list blank line, the emphasised negation, the later-paragraph reference — run through `parse_dependencies` | 11 of 11 hold. The same probe over the `beb07cf4` parser holds 7 of 11: the four claims this iteration changes fail there |
| Reference durability | the link, raw-URL, issue-reference and cutover patterns of `core/hooks/lib/fragile-ref-patterns.sh` over the line this iteration changes in `core/schemas/gate-criteria-spec.md` | 0 on each; a seeded control line fires each |
| Doc links | `check-doc-links.py --target-paths <gate-criteria-spec.md, this file> --require-targets`; `check-release-links.py --files <each> --check-anchors`, with `--plan-depth-lint` on this file | 0 findings; 0 broken links; both checkers' `--self-test` pass |
| Tool exec mode | `python3 core/deploy/tools/check-tool-exec-mode.py` | exit 0 — 0 findings, 7 exempt; no file mode changed |
| Plan verifier and CIAC lint | `bash release/tools/verify-release-plan.sh <this file>`, and with `--ciac-lint`; `claim-version.sh --verify-stamp sequencing-layer-foundation` | exit 0 — 13 PASS / 0 FAIL / 25 SKIP / 5 UNRUNNABLE / 0 ERROR over 43 records, as at slice 3; the lint reads `declared=4 parsed=4 clean=3 declared-deferral=1 flagged=0`; the stamp check passes |
| AC binding | `python3 release/tools/check-ac-binding.py <this file> --fetch`, before and after the AC-6 row edit | `VERDICT BOUND` both times; #6398 AC-6 `BOUND` on the same five tokens |
| Close-keyword self-check | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | exit 0, CLEAN, before each push |

**Probe records** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       directed (source, target) references — parse_dependencies over every snapshot body,
             the beb07cf4 parser against the fixed parser; the set difference each way
Denominator: 749 open issues (REST paginated; 749 = the search total, read before and after);
             154 directed references at beb07cf4
Control - sensitivity: the parser suite's later-paragraph rows read {30, 31} and {32, 33} under
             the beb07cf4 parser and {30} and {32} under the fixed one, so a moved reference is seen
Control - specificity: the same comparison with the beb07cf4 parser on both sides -> 0 removed,
             0 added
Extraction:  749 bodies, 4,250,034 bytes, 0 empty, read by every arm
Result:      1 removed (#7466 -> #7889), 0 added
Verdict:     N-of-M: 1 of 154
```

```
Probe:       AC3 — each tree's own run_dry_run() over the snapshot; the count of cycle_members and
             of output lines containing "cycle"
Denominator: 749 open issues; 57 open milestones (REST, paginated)
Control - sensitivity: the same harness and snapshot with the b1042eec tree -> 10 cycle-resident,
             1 cycle line
Control - specificity: NOT TRIGGERED — cycle membership is computed, not matched; the position
             tool's own self-test pairs an X <-> Y cycle with an acyclic Z (SELF-TEST OK)
Extraction:  749 bodies; each tree's whole dry-run output
Result:      0
Verdict:     CLEAN
```

```
Probe:       underscore-emphasised negation before a blocked_by label (_not_ / __not__ then
             blocked by / depends on / requires) in live Dependencies sections
Denominator: 397 Dependencies sections in 749 open bodies
Control - sensitivity: the pattern over the suite's _not_ and __not__ rows -> 1 each
Control - specificity: "do_not blocked by" (an underscore inside a word) -> 0; plain
             "not blocked by" -> 0
Extraction:  397 sections, each read whole
Result:      0
Verdict:     CLEAN
```

**Cascade sweeps.** Each pattern brackets one character so that it does not match its own line here. The AC6 read point: `grep -oE 'read at Stage [8]|step read [h]ere|Stage 8:[*][*] #6398'` over this file → pre 7 / post 1; the survivor is DEV-28's own description of the old read point (PRESERVE). The view suite's arm count: `grep -oE '1[4] arms|stays 1[4]'` → pre 3 / post 2; § #6398 — change specification now reads 15 (UPDATE), and the slice-3 evidence row and DEV-27 keep 14 as dated records (PRESERVE).

**Deliverable state:** `deployed-copy-synced` for DT iteration 2 — no matrix path has a deployed copy.

---

## Change Description

Authored at Stage 6 Phase C1 by the last Engineering spoke (#8704, slice 3), after all three slices landed and before the draft pull request is marked ready-for-review. Operator-facing; the user-facing release note is a separate Stage-13 artifact. A Tier 1 [ADJUST] at Stage 7 or 8 that changes which issues land or which decision stands refreshes **Issues resolved**, **Key decisions** and **Downstream impact** in a later commit.

### Outcome

Dependency edges are now read with their direction, from one grammar in one parser: `parse_dependencies` returns only the issues a body says block it, so a reciprocal `Blocks`, a hierarchy reference, a negated label and unlabelled prose no longer read as blockers, and on one snapshot the milestone position tool's cycle-resident milestones fell from 10 to 0. The same parser is the single home of the issue-body section extractor, which now ends a section only at a heading or a `---` break line, so a blank line too many no longer empties a section. A new command, `release/tools/compute-chain-head-rollup.py`, prints every chain head — each initiative and any lone epic — with its epics, their open children, and per-head unparented and blocked counts, read live, with anything it could not read marked unmeasured rather than shown as 0.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #7177 | A section ends only at an H2/H3 heading or a break line; the dependency mirror loads the parser's extractor instead of carrying a copy; caller output unchanged on 814 of 814 open bodies | DONE |
| #6397 | `parse_dependencies` returns directed `blocked_by` targets from the one grammar now in the parser, the negated label included, and a reference in a later paragraph of a `Blocked by:` run no longer reads as a blocker; prose references are reported, the position tool keeps the parse status, and G3-07 names its edge source | DONE |
| #6398 | The chain-head view renders live — 10 initiative heads and 0 lone-epic heads at the Stage-6 run, the six evergreen containers absorbed into the standing initiative — and the epic child-set rule has one home that the view and the rollup-close audit both load | DONE (AC6 is the operator's post-merge step, read and recorded at Stage 13 close-out) |

### Key decisions

Each is recorded in this file's § Decision Record.

- **D-7177-Extractor — the A6.5 counter-design:** no run of blank lines ends a section; the return stays a plain string, so no caller changes, and #7177's AC5 is restated.
- **D-6397-Negation — fixed in the shared grammar:** a `blocked_by` label negated on its own line reads non-blocking, and the A3.5 mirror inherits the rule.
- **D-6398-Standing — the label word, plus a guard:** a label description that begins with `Standing` declares a standing initiative, which shows no percentage; a run that finds none stops with exit 1 rather than turn the standing initiative finite and the flow containers back into heads.
- **D-6398-AC6 — retire the interim board's portfolio map only:** its hand-ordered milestone lanes stay until #6443 ships.
- **D-6397-AC2-Gap — a blank line ends a directional run:** a reference in a later paragraph no longer reads as a blocker (1 of 154 live references changed), and `_not_ blocked by` reads as negated.
- **D-6398-AC6-ReadPoint — AC6 is read at Stage 13 close-out:** the operator's post-merge step is read and recorded against the closed card.
- **D-Concurrency P0 and D-C SINGLE:** three serial slices on one branch, one merge.

### Reversibility

**CHEAP — HIGH confidence.** `git revert -m 1` of the merge restores the parser's extractor and grammar, the mirror's copies, the position tool, the audit's inline child-set rule and the documents byte-for-byte, and nothing outside the tree persists: no milestone carries a position, the mirror only ever adds author-declared edges, and the view writes nothing. It becomes MODERATE once a later reader builds on the parser's shared home; a claimed version tag is retained, never deleted.

### Downstream impact

- **Stage 7:** the live `compute-milestone-positions.py --dry-run` (no `CYCLE:` block) and `compute-chain-head-rollup.py --json` (heads equal the labels with members); the `deploy.sh --check` FAIL-line diff against `b1042eec` (DEV-17); the discovered self-test run, whose one local timeout is not evaluated here.
- **Stage 12:** the two ADR records bind at the claim through `renumber-adr.py` — the pre-merge sync moved them to 234 and 235 and stamped their slug-token citations (DEV-30), and a second sync moved them to 236 and 237 after milestone 438 took those numbers (DEV-31); milestone 438 computes the same version slot, and the first merge claims it.
- **Stage 13:** both records are ratified (G-CL9); G-CL6 reads the taxonomy's chain-head region against the shipped tool; #6398's AC6 — the operator's post-merge step that retires the interim board's portfolio map and points its README at the view, keeping the lanes — is read and recorded in the close-out record (D-6398-AC6-ReadPoint); three items are held for the follow-up ledger (§ Exclusions).
- **Every Stage-13 close-out after the merge** loads `_epic_child_set.py` at its epic rollup-close phase; a missing module stops that phase loudly instead of falling back.
- **Later work:** b21 (#7678) builds its shared acceptance-criteria reader on the parser's extractor and merges after this release; native-edge reads (#6426) and the sequencing layer (#6443) build on the directed edges.

### Cross-references

- Release plan: this file, top section.
- Milestone: `sequencing-layer-foundation`.
- Decision records: the shared-home ADR under `release/ADRs/` and the chain-head ADR under `core/ADRs/`, both `Proposed` until Stage 13.
- User-facing release note: authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`, under `release/releases/notes/`.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **D-7177-Extractor replaces the Stage-5 extractor design (S5-D2).** A section ends at the next H2/H3 heading or a break line; the two-blank-line terminator is removed; the return stays `Optional[str]`. There are no record types, no per-caller rendering change, no mirror WARNING and no new `failed` source for whitespace. The Stage-5 design's D-7177-1 leading-blank skip is not applied: once no whitespace ends a section it has no reading effect, and skipping it would change the text every caller receives and the present-and-empty control arm Stages 4 and 5 recorded | scope lock D-7177-Extractor; A6.5 review on #8777 (PRF-1, FM-1, CD-1) | **APPLIED** — slice 1 |
| **DEV-2** | **The break line's definition.** The decision names "a `---` line"; it is implemented as three or more hyphens, indented at most three spaces, optional trailing spaces or tabs, CRLF-safe (`\r?` before the line end). `***` and `___` are not break lines, and HTML comments are not stripped: the decision names the hyphen line, and the observed separator footers are all of that shape | scope lock D-7177-Extractor and its Stage-6 fix (CRLF-safe detection); A6.5 FM-3 | **APPLIED** — slice 1 |
| **DEV-3** | **S5-D1 keeps every public name of the mirror, `extract_section_with_alias` and `extract_section_aliased` included.** The Stage-5 design deleted both; the hub's scope-lock reading keeps them, bound from the parser. So the parser gains `extract_section_with_alias` (returning the matched alias with the section, the contract the mirror's copy had), and `extract_section_aliased` delegates to it. The Stage-5 reference-cascade expectation of a post-0 count for `extract_section_with_alias` does not apply — the name's definition moves and its call sites stay | the hub's Stage-6 brief for #8696 (S5-D1 stands, every public name kept) | **APPLIED** — slice 1 |
| **DEV-4** | **CIAC-3 is restated.** The Stage-4 text asserted that "a Dependencies heading whose content the extractor cannot locate still yields a non-clean status — #7177's degraded verdict survives the rewrite", and its grep label named a degraded verdict. Under D-7177-Extractor that state is unreachable by construction, so the criterion now asserts the property that does survive — a doubled blank line reads the same targets and status as the single-blank form through the rewritten `parse_dependencies` — under the label `CIAC-3 blank-line-invariant extraction survives the directed parse`. The ID, the cards, the seam and the grep-for-a-label method are unchanged | scope lock D-7177-Extractor (AC5 restated "because the cannot-locate case no longer exists") | **APPLIED** — § Cross-Issue Acceptance Criteria; the arm lands in slice 1. **Confirmed** by the operator before Stage 9 (D-CIAC3-Restated) |
| **DEV-5** | **CIAC-1's test is structural, not a text search.** The Stage-5 arm asserted the parser's source contains no `native-dep-mirror`, which the parser's own docstring now names; the arm instead asserts no non-docstring string and no import in the parser names the mirror, with the same scan over the mirror as its sensitivity arm, plus the copy-alone loads | scope-lock Stage-6 fix (CIAC-1's test reconciled with the docstrings); A6.5 FM-2 | **APPLIED** — slice 1 |
| **DEV-6** | **The ADR is written `Proposed`, not `Accepted`**, and covers S5-D1 with D-7177-Extractor; the record types become a rejected alternative, and the new-module candidate stays the opposing view | scope-lock recorded alignment | **APPLIED** — Commit 0 |
| **DEV-7** | **The Stage-4 conditional rows are resolved and the matrix gains the rows Stage 5 and the scope lock added** — the shared-home ADR and its index row, `_epic_child_set.py`, the epic rollup-close audit, the chain-head ADR and the script-execution allowlist row; the two `STAGE5-SHARED-HOME` rows and the two `STAGE5-MODEA-DOC` rows resolved not-fired | Stage-5 designs (R3 on #8695, R1 on #8703); scope-lock alignments and Stage-6 fixes | **APPLIED** — § File Change Matrix |
| **DEV-8** | **The smoke workflow is an unconditional EDIT in slice 1** for its count-free label, not only `CONDITIONAL:NEW-BARE-SUITE` | Stage-5 design R3 on #8695, approved at the scope lock | **APPLIED** — slice 1 |
| **DEV-9** | **The mirror's load guard in `main()` sits after the `--verify-write-surface` dispatch**, not as its first statement, so `--help` and the write-surface introspection — neither reads a body — still run with no parser beside the tool; every body-reading path and the self-test still exit 2 first | Stage-6 B3 (minor adjustment) | **APPLIED** — slice 1 |
| **DEV-10** | **Only the shared-home ADR is written at Commit 0.** The scope-lock alignment reads "both new ADR records are written `Proposed` at Engineering Commit 0"; the hub's Stage-6 brief scoped this spoke to the shared-home record and left #6398's to its own slice, so the chain-head ADR is authored `Proposed` by slice 3 and takes the next number on this branch | the hub's Stage-6 brief for #8696 | **APPLIED** — slice 3 (`a0599135`): the chain-head ADR is written `Proposed`, provisionally 231, the next number on this branch after the shared-home record |
| **DEV-11** | **#6398's integration criterion INT-2 names "#7177's degraded verdict"** as a non-clean case; that verdict does not exist under D-7177-Extractor, and `parse_dependencies` returns only `clean` or `deferred` (slice 2), so INT-2's non-clean population is the `deferred` status — any status other than `clean` reads unmeasured. INT-1 and INT-2 are restated in § #6398 — change specification against those live statuses; the card's body is not edited | scope lock D-7177-Extractor; the hub's Stage-6 brief for #8704 | **APPLIED** — slice 3 (§ #6398 — change specification) |
| **DEV-12** | **The design's degraded handling is not built.** D-6397-4 returned `failed` for a degraded section and split `_segments_for_body` into a record-taking `_segments_for_section`; D-6397-6 warned only on `failed`. Under D-7177-Extractor no degraded verdict exists, so `parse_dependencies` keeps `clean` / `deferred`, `_segments_for_body` moves unchanged, and the position tool routes any status that is not `clean` (today `deferred`) into its unresolvable list. No status token is minted, because G3-14 counts only `clean` and `failed` | scope lock D-7177-Extractor; the hub's Stage-6 brief for #8700 | **APPLIED** — slice 2 |
| **DEV-13** | **The negated-label rule, and its fixture asserted.** D-6397-Negation is implemented as a same-line test on `blocked_by`-kind labels: the text from the start of the label's line must end in `not`, `no longer`, `never` or an `n't` contraction, markdown emphasis tolerated; such a label reads `relates`. The design's Change 1 step 4 and Change 5(b), which excluded the negation fixture so as not to lock the trap in, are superseded: the fixtures assert no edge. The rule is lexical — a negation separated from its label by other words is not recognised (residual, MEDIUM) | scope lock D-6397-Negation; A6.5 CD-1 | **APPLIED** — slice 2 |
| **DEV-14** | **Where unattributed references surface.** A6.5 FM-2 is applied on the parse record — `IssueRecord.dependencies_unattributed` and `dependencies_unattributed_count`, data only — as the hub's brief scoped it. The position tool does not list them; its unresolvable list carries the parse status only. Recorded as a finding for the operator in the Stage-6 output on #8700 | the hub's Stage-6 brief for #8700; A6.5 FM-2 | **APPLIED** — slice 2 |
| **DEV-15** | **The G3-07 Edge-source text is written to the code, not the design's literal.** D-6397-7's paragraph stated a narrower grammar (labels as segment heads only; prose never an edge) and a `failed` status for an unreadable section. The committed text names `parse_dependencies` as the authority and states the grammar's actual reach — a label matches mid-sentence with an optional colon, a segment runs to the next recognised label — plus the negated label, unattributed references and the `deferred` status | scope-lock Stage-6 fix (G3-07 matched to the code); A6.5 FM-3 | **APPLIED** — slice 2 |
| **DEV-16** | **The mirror self-test gains case 25** (a negated label is not mirror-eligible), so it passes 25 cases rather than the 24 this file's slice-2 note anticipated; the frozen mirror suite stays at 20 cases | A6.5 CD-1 ("add one mirror self-test case") | **APPLIED** — slice 2 |
| **DEV-17** | **AC5's `deploy.sh --check` limb is not run by this spoke.** `--check` appends to the operator-instance warn log, which is outside the Stage-6 spoke's write boundary; the FAIL-line diff against the `b1042eec` baseline stays at Stage 7, as § Verification Plan already assigns it | the Stage-6 brief's write boundary | **RECORDED** — Stage 7 |
| **DEV-18** | **No standing initiative stops the view.** The Stage-5 design's absorption rule said "with no standing labels at all, nothing is absorbed"; D-6398-Standing replaces that with a guard that fails loudly, so `derive()` raises and the run exits 1 with an error naming the label-description word. The EVG arm for that case is replaced by the AC3 guard arm and its control. The ADR states the consequence: an edit that drops the word makes the command fail rather than misreport | scope lock D-6398-Standing | **APPLIED** — slice 3 |
| **DEV-19** | **The parent rule follows the host's payload, not the design's literal.** The design read a missing `parent_issue_url` key as unreadable; the host omits the key for an issue with no parent, so a missing key is no parent and the member counts as unparented. The facet reads unmeasured only when no open issue carries the key while some issue reports sub-issues. `partition` gains a `status`, and the sum is asserted only when it is measured. The AC5 fixtures use the live shape and gain the keyless-member arm | scope-lock Stage-6 fix; A6.5 FM-1 | **APPLIED** — slice 3 |
| **DEV-20** | **Two edge facets added to schema v1.** `edges.section` (`present` / `absent`, through the parser's `extract_section_aliased` over `DEP_HEADING_ALIASES`) and `edges.native_blocked_by_open` (the REST `issue_dependencies_summary.blocked_by`). An absent section with open native blockers reads unmeasured, never "not blocked"; the native count adds no edge and feeds no sequence. Arm `CD-1` with its control | scope-lock Stage-6 fix; A6.5 CD-1 | **APPLIED** — slice 3 |
| **DEV-21** | **Two script-execution allowlist groups, not one.** The scope lock names the row for the new Python tool; the child-set module also advertises a `--self-test` that this release's verification runs, so it gets the same four-form group, as the A6.5 review's PR-1 offered. The section's header paragraph said one group did not come from the drain; it now names all three and why | scope-lock Stage-6 fix; A6.5 PR-1 | **APPLIED** — slice 3 (minor) |
| **DEV-22** | **The smoke step is unmasked and sits beside the mirror's step.** The design placed a plain step after the remaining-suites block; it is added after the native-dep-mirror step with `if: always()`, like the four hermetic suites around it, so an upstream red does not skip it. The verify-release-plan step's rationale counts move with it: "this step and the four below because all five" and "the five trailing suites" | Stage-6 B3 (minor adjustment) | **APPLIED** — slice 3 |
| **DEV-23** | **Where the taxonomy text sits.** The standing paragraph follows the finite-versus-standing paragraph, as designed, and adds the guard sentence. The `#### Derived chain-head view` subsection sits at the end of § Initiative Labels, after the usage-pattern paragraph, rather than directly after it, so the usage pattern stays under its section heading. The subsection adds one sentence on the cases that keep an epic a head | Stage-6 B3 (minor adjustment) | **APPLIED** — slice 3 |
| **DEV-24** | **Drill-down details the design left open.** The third level lists a node's open children; closed children count in its progress. A lone-epic head's members are its epic's open children, all in its tree. A finite epic's completed count is the children closed `completed`, as designed; a child closed with another reason counts in the total only. The audit's module path is a plain shell global, and its unloadable-module exit is 1, named on its exit-code line | Stage-6 B3 (minor adjustment) | **APPLIED** — slice 3 |
| **DEV-25** | **The Tier-A design artifact is declared in this file.** The Stage-5 design declared one Tier-A activated artifact — the taxonomy's derived chain-head view region — which Stage 13 G-CL6 reads from this file; Commit 0 did not carry the section, so it is added under § Implementation Sequence | Stage-5 design on #8703 (Tier-A table) | **APPLIED** — slice 3 |
| **DEV-26** | **`f23837a3` — the hub's exec-mode repair delivers one path the matrix did not declare.** After slice 3 the `Tool exec-mode gate` found three new files that begin with an interpreter line tracked 100644. The commit tracks `compute-chain-head-rollup.py` and its suite 100755, as their sibling tools and suites are, and adds an `imported-module` row for `_epic_child_set.py`, which the audit and the view load by path, to `core/deploy/allowlists/skip-tool-exec-mode-check.txt`. The mode changes touch only matrix paths; the allowlist is now the slice-3 `EDIT` row of § File Change Matrix. It is absent from § #6398 — change specification's file list because the repair followed that specification. Evidence: `check-tool-exec-mode.py` exits 0 with 0 findings and 7 exempt, and the CI `Tool exec-mode gate` passes at `f23837a3` | the hub's Stage-6 self-repair; recorded at DT iteration 1 for the #6398 Stage-7 finding F-03 | **APPLIED** — `f23837a3`; the matrix row at DT iteration 1 |
| **DEV-27** | **DT iteration 1 (Stage 6 Phase E).** The three Stage-7 passes (#8697, #8701, #8705) each returned PASS with Tier 1 fix-now findings; the hub routed six to Engineering, and none changes an acceptance criterion or a design decision. (1) #7177 F-01: the #7177 AC-1 verification row's note now says what the arm grades — `extract_section` returns the section after one, two or three blank lines — with the grep label unchanged, so `check-ac-binding.py --fetch` reads AC-1 `BOUND` and `VERDICT BOUND`. (2) #7177 F-02: the shared-home ADR's Consequences bullet and R-13 name "an H2 or H3 heading" where they named "a heading", as Decision 3 and the code read. (3) #6398 F-01: `derive()` reads the unparented facet and the partition unmeasured when the host serves neither `parent_issue_url` nor the sub-issue summary on any open issue, where it read them measured; this extends DEV-19's rule, and the tool's docstring, the suite's docstring and the FM-1 bullet of § #6398 — change specification state the new limb. `arm_ac5` gains the check and a control (the summary served at zero, no native child, stays measured); run against the base tool, exactly the new label fails. (4) #6398 F-02: `arm_ac3` asserts three drill levels — head, epic, open child — in the JSON and the Markdown, with a control; three mutants (no child rows, no children, no details block) each turn it red. The arm count stays 14. (5) #6398 F-03: the matrix row and DEV-26. (6) #6397 F-03: the smoke workflow's parser-suite step name and header comment name the direction-grammar arms, without a count, and § #7177 — change specification's smoke-label paragraph quotes the new strings. Also refreshed: the Header Status. Not acted on: #6397 F-01, the operator's call at Stage 9. The Change Description's refresh rule does not fire, because no issue or decision changes | the Stage-7 outputs on #8697, #8701 and #8705; the hub's DT-iteration brief for #8704 | **APPLIED** — `63fdc04c` (the view, its suite, the smoke workflow) and the DT plan commit (the shared-home ADR and this file) |
| **DEV-28** | **#6398 AC6 is read and recorded at Stage 13 close-out, not at Stage 8.** The restated AC6 asked for the operator's post-merge interim-board step to be read at Stage 8, which runs before the merge, so Stage 8 could not grade it (it returned `FLAG-UPSTREAM`). The read point moves to the Stage-13 close-out record for #6398, against the closed card; the criterion's content — retire the portfolio map, point the README at the view, keep the milestone lanes until #6443 ships — is unchanged. Re-pointed in every place this file stated it: the Implementation Sequence's post-merge row, § #6398 — change specification's AC6 paragraph, the Stage Applicability Matrix (the note moves from column 8 to column 13), the § Verification Plan AC-6 row (still a declared deferral, so the plan verifier reads it as one), and the Change Description's Issues resolved row and Downstream impact (the Stage 8 bullet, which carried only this step, is folded into the Stage 13 bullet). The card's body is not edited, following DEV-11's precedent, and the pull request's Issue References block is unchanged | pre-Stage-9 decision D-6398-AC6-ReadPoint (#8707), from the #6398 Stage 8 review on #8706 (Q-03) | **APPLIED** — DT iteration 2, this file |
| **DEV-29** | **DT iteration 2 (Stage 6 Phase E).** The operator's pre-Stage-9 decisions routed four changes to Engineering, and no other criterion or design decision changes. (1) D-6397-AC2-Gap: in the parser's direction grammar a `blocked_by` or `blocks` run ends at the first blank line after its first text; the rest, up to the next label, is unlabelled text beneath the heading (the heading's direction under a directional heading, otherwise no edge and an unattributed reference); blank lines between a label and its first text do not end it; a `relates` run is not ended. The negated-label rule accepts `_not_` and `__not__`. Two shapes were chosen beyond the decision's text and are stated so Stage 9 can see them: the run starts at its first text, so `Blocked by:` with its list one blank line below keeps the list's edges; and the bare-reference shim is not applied to the remainder, so a list after a `Blocks:` paragraph never becomes a blocker. Both read identically to the decision on the live backlog. `6397-AC2` gains five relation rows and four edge controls; against the base parser exactly the five new rows fail. Live, directed references 154 → 153 (only #7466 → #7889 removed, none added) and unattributed references 116 → 120 (#42's `Hard:` paragraph surfaces #43, #44 and #45, which stay directed from its first line, and #7466 → #7889); AC3 reads 0 cycle-resident milestones. (2) D-6398-Q01: a failed child-set read renders the node's open children unmeasured, and a lone-epic head's blocked facet unmeasured with null counts and a reason, where both read "No open children" and 0; the measured shape is unchanged. The suite gains `arm_q01` (15 arms); against the base tool only it fails, and each single-branch mutant turns only its own assertions red. (3) D-6398-AC6-ReadPoint: DEV-28. (4) D-CIAC3-Restated: recorded in § Decision Record, § Cross-Issue Acceptance Criteria and DEV-4. Also reconciled, because each stated what the code no longer does: G3-07's Edge-source paragraph in `core/schemas/gate-criteria-spec.md` (the segment end, the label-to-list blank line, the emphasised negation, the later-paragraph reference), the parser's grammar docstring and comments, the view's docstring, both suites' docstrings, § #6397 and § #6398 — change specification, the Change Description's #6397 row and Key decisions, the provenance note at the top of this file, and the Header Status. Evidence: § Verification Evidence → DT iteration 2 | pre-Stage-9 decisions on #8707, from the Stage 8 reviews on #8702 and #8706; the hub's DT-iteration brief for #8704 | **APPLIED** — `bd19879b` (the parser, the view, both suites, G3-07) and the DT plan commit (this file) |
| **DEV-30** | **The two ADR records are renumbered at the Stage-12 claim: the shared-home record 230 → 234, the chain-head record 231 → 235.** While this branch was in flight the mainline merged four core records from other releases at 230 through 233, so `renumber-adr.py --detect` read anchor 233 and both branch claims `DUPLICATE`. The pre-merge sync merged `origin/main` with no conflict (`adf9bffd`). The moves ran as `--renumber 230 234 --apply` (`007e330b`) and `--renumber 231 235 --apply` (`7e9e7932`), one commit each, because the tool refuses a second move on an uncommitted tree. Each move renamed the file, rewrote the record's title and heading, appended a line to the renumber log in `core/ADRs/README.md` and wrote a numbering-provenance note in the record's Status; the first also moved the release ADR index row to 234. R3 named no review site on either move, and R6 found nothing dangling. `core/ADRs/README.md` enters the branch diff only through those tool-written log lines; it is not a § File Change Matrix row, and the plan verifier's FCM-COVERAGE still passes. No entry for the chain-head record is added to that README, because it is curated, not an index (§ Verification Evidence → Plan step 3). `--stamp --apply` then resolved the three slug-token citations — the chain-head record's Related ADRs entry, the taxonomy's derived-view paragraph and the view's docstring — and `--stamp --check` reads 0 residual. One hand edit came before the stamp: the chain-head record's first numbering-provenance paragraph quoted its own slug token to describe it, which the stamp would have turned into a numbered citation describing itself as numberless; it now names the slug in prose, as the shared-home record's paragraph does. In this file, the text naming the provisional numbers as current is reconciled: the #6398 file list, the matrix note on rows added since Stage 4, the Change Description's Stage-12 bullet and the Header Status. The scope-lock alignment, the Commit-0 and slice-3 evidence rows and DEV-10 record numbers that were true when written, and stay as they are. `check-adr-numbers.py` reads contiguous 001..235 with no duplicate | the hub's Stage-12 sync brief for #8710; `release/references/pipeline/stage-12-execute.md` Phase A.5 and A.5.7 | **APPLIED** — `adf9bffd` (the sync), `007e330b` and `7e9e7932` (the moves), and the Stage-12 plan commit (the stamp, the provenance edit and this file) |
| **DEV-31** | **A second Stage-12 sync renumbers the two ADR records again: the shared-home record 234 → 236, the chain-head record 235 → 237.** Milestone 438 merged first (`e58a77f0`) and took ADR-234 and ADR-235 for its own two records, so this branch's claims collided again and #8811 read DIRTY. The second sync merged `origin/main` at `99c8b442` (`9a394380`). One file conflicted: `core/ADRs/README.md`, where both sides had appended renumber-log rows at the same tail — this branch's first-sync rows (230 → 234, 231 → 235) and the sibling's (232 → 234, 233 → 235). Both pairs are kept, in the order they were written. That README is curated, not projected, so it was merged by hand; the projected release index was regenerated with `generate-adr-index.py --write`, which changed nothing. No other path was changed on both sides (1 of the 30 incoming paths). `renumber-adr.py --detect` then read anchor 235, next-free 236, and both branch claims `DUPLICATE`. The moves ran as `--renumber 234 236 --apply` (`2e2ce58b`) and `--renumber 235 237 --apply` (`d9ef001a`), one commit each; before the second, `--detect` read 236 `BINDS`, and it was held fixed. Each move renamed the file, rewrote the record's title and heading, appended a renumber-log row and added a numbering-provenance paragraph beneath the earlier one. R3 rewrote the chain-head record's Related ADRs entry and the release index row on the first move, and the taxonomy's derived-view paragraph, the #6398 file list in this file and the view's docstring on the second. It treated each record's earlier provenance paragraph and its first-sync log row as records and left them alone, left the sibling's log rows to the sibling, and named no review site. R6 found nothing dangling and R7 no affected package. `--stamp --apply` resolved 0 tokens, because the first sync had already stamped them, and `--stamp --check` reads 0 residual. In this file the text naming 234 and 235 as current is reconciled: the Header Status, the #6398 file list, the matrix note on rows added since Stage 4 and the Change Description's Stage-12 bullet. DEV-30 records the first sync as it happened and is left as written. `check-adr-numbers.py` reads contiguous 001..237 with no duplicate | the hub's second Stage-12 sync brief for #8710; `release/references/pipeline/stage-12-execute.md` Phase A.5 and A.5.7 | **APPLIED** — `9a394380` (the sync), `2e2ce58b` and `d9ef001a` (the moves), and the Stage-12 plan commit (this file) |

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
