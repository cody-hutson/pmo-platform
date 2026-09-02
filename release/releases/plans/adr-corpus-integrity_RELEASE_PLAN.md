---
title: Release Plan — adr-corpus-integrity
purpose: Stage-4 release plan for the ADR-corpus enforcement-integrity slice — where the ADR corpus records a decision, the surface that enforces it actually holds.
type: release-plan
plan_type: release
status: IN PROGRESS
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: adr-corpus-integrity — The Enforcing Surface Actually Holds

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Re-verified at Engineering Commit 0 per the authoritative-version-selection procedure: mainline anchor **v4.45** (concordant across `.version`, the tag set, and the latest `RELEASE_LOG` Deployment Log row), recomputed next-free minor **v4.46**, confirmed free at Commit 0 by the governed oracle `claim-version.sh --sha 539c4440 --bump minor --dry-run` and by an independent claimed-set probe (0 tags, 0 ledger rows). Verdict **PROCEED**. |
| **Date Created** | 2026-09-01 (Tuesday) |
| **Commit-0 Date** | 2026-09-01 (Tuesday) — the resolution instant for every load-bearing date this release writes |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/adr-corpus-integrity` |
| **PR** | opened as a DRAFT after the first Engineering spoke's commits; the release ships as a SINGLE PR with one merge gate |
| **Milestone** | `adr-corpus-integrity` (#344) |
| **Release Class** | `cross-cutting` — re-classified from `routine` at the Stage-4 Procedure-0 gate by operator decision (D-ReleaseClass) |
| **Composition** | capability-slice; Frame F1 (SAFe Feature-Slicing + Vertical Slice) |
| **Effective points** | **22** across **5** issues — within the 15–25 pt target band. `class_weight` for `cross-cutting` is not applied as a multiplier here; 22 is the raw Σ of the members' size labels (#4995 `size:L` 8 · #5080 `size:S` 2 · #5060 `size:M` 4 · #4929 `size:M` 4 · #6244 `size:M` 4). |
| **Branch topology** | **SINGLE** — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** for the `#4995 / #5080 / #6244` cluster — declared explicitly at the D-Gate rather than inherited as the undeclared default. Wave A's three members are measured-disjoint and parallel-safe; the serialization binds Wave A→B. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `539c4440fc1457e8d42d2bbe11c7be663baf596f` — the pinned baseline; every Engineering spoke branches from it |

**Stamp manifest.** The `**Version**` cell above is a machine-read manifest, not prose. It carries the literal `{{RELEASE_VERSION}}` token and nothing else; the bump-class determination and its narrative live in the `**Bump Class**` row beside it. The Stage-12 claim resolves that token at the merge SHA while renaming this file to `release/releases/plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md` (ADR-092). Asserted read-only at Commit 0 by `release/tools/claim-version.sh --verify-stamp adr-corpus-integrity`; a plan that fails that assertion is never committed, because Stage 12 could then neither resolve the version nor complete the rename.

## Release Outcome Statement

**AFTER** this release: where the ADR corpus records a decision, the surface that enforces it actually holds — the number binds without a corpus-wide sweep, the reconciliation tool's exemption spares what it *records* and sweeps what it *cites*, the generated release-module index has a regeneration checkpoint, and the ownership check can fail for the reason it was built.

**BEFORE:** ADR numbers commit to prose before they bind, so every concurrent allocation forces a corpus-wide citation sweep; the renumber sweep silently falsifies the records it should preserve; nothing asks whether the release-module index needs regenerating; and the shipped ownership check is zero-ESCALATE by construction.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Layer | Size | Stage 5 |
|---|-------|---------------------|-------|------|---------|
| 1 | #4995 | ADR numbers commit to prose before they bind — the citation-sweep blast radius | foundation | L (8) | APPLIED (#6504) |
| 2 | #5080 | `renumber-adr.py` dry run predicts rewrites the apply path leaves alone | infrastructure | S (2) | APPLIED (#6514) |
| 3 | #6244 | `renumber-adr.py` rewrites historical ADR numbers in Deviation Log prose | infrastructure | M (4) | APPLIED (#6522) |
| 4 | #5060 | Nothing asks whether a release added a `release/ADRs/` record | process | M (4) | APPLIED |
| 5 | #4929 | ADR-044 ownership reconciliation — Check 54 is zero-ESCALATE by construction | governance | M (4) | APPLIED |

**#4995 / #5080 / #6244 are one build at function granularity, and three cards.** They share one function and its call sites, not merely a file. The merge is of the *build*, not the tickets: #4995 owns the exemption predicate rewrite; #5080 and #6244 are fixture/regression slices gated on it. Stage 5 produced **one consolidated design spec** (#6504) covering the exemption population across all three facets, because #4995 AC5 is a design-level cross-issue invariant no single-issue design can state. Each issue number stays distinct and is marked as closed at Stage 13.

### Ratified premise corrections

These supersede the corresponding text in the Stage-4 planning comment and in the card bodies. **Issue bodies are left as historical record and are never amended (ADR-062).**

1. **A stale bare-token citation is NOT visible to the ADR index gate.** `check-adr-numbers.py` performs zero content reads — its entire input is one `d.glob("ADR-*.md")` keyed on `path.name`. No tool or workflow in a 100-file population reads a bare `ADR-NNN` out of prose. Only *path-bearing* citations are covered, by Check 14 / `check-release-links.py`. **Both** error directions are therefore unchecked by gates, which is the affirmative reason the sweep's review report is emitted unconditionally rather than only when it finds something.
2. **The exemption is not "line-wise but otherwise right."** It is keyed on one string that only the tool itself writes. Measured against the corpus at the baseline: of **175** lines that RECORD an ADR number, the current predicate protects **60 (34.3 %)**. The 115 unprotected lines include **5 of 5** tokens in ADR-103's own numbering-lineage block and **3 of 4** in ADR-121's. That reframing is what makes AC4's "widen at the level of the POPULATION" a single change rather than three patches.
3. **ADR-115's stale "six individually-verifiable steps" is not correctable in place.** The tool ships **seven** (R1–R7). ADR-115 is `Accepted` and ADR-118 § Decision (2) puts `## Decision` on a **closed** forbidden list, so the stale enumeration is PRESERVED there and restated in ADR-170 instead. The governed ADR-115 edit is narrowed to **one `## Related ADRs` bullet**.
4. **`release/ADRs/README.md` is an EDIT, not a READ.** The Stage-4 matrix listed it as a read-only input while the same matrix declared an ADR `add` under `release/ADRs/`. A release-module ADR add makes the projected index an edit. Left as declared, this release reproduces the v4.30 D-19 shape that `repo-integrity.yml`'s `adr-number-integrity` job catches at Stage 7.
5. **Direction 1 (late binding of citations) is selected; direction 2 (reservation) is rejected.** The `CONDITIONAL:D-MECHANISM` reservation-ledger row therefore **does not fire and is struck**, not left conditional. A row left CONDITIONAL after its condition resolves is an authoring defect (File Change Matrix contract rule 5).
6. **#4929 slice 2 is deferred to an existing owner, not to a new card.** AC5/AC6 are marked `[DEFERRED — out of release scope; blocked on #5053]` with their original text intact. #5053 already owns the root cause — a check whose mode resolver reads untracked instance paths cannot be flipped from a release branch — and Check 54 is its second confirmed instance.

## Release Class

**`cross-cutting`** — re-classified from the declared `routine` at the Stage-4 Procedure-0 gate, 2026-09-01 (Tuesday), by operator decision.

*All four `routine` conditions are falsified:*

| `routine` trigger | Verdict | Evidence |
|---|---|---|
| (a) all issues P3/P4 + `size:S`/`size:M` | ✗ | #4995 is **P2 + `size:L`** |
| (b) all change-spec files have ≥3 prior release touches | ✗ | `ADR-170-…md` is a new file with **0** touches |
| (c) zero new files added | ✗ | #4995 AC1 requires a superseding/amending ADR |
| (d) zero new D-class decisions | ✗ | #4995's mechanism choice is a genuine new D-class decision |

*What fires instead:* **`cross-cutting` trigger (a)** — the File Change Matrix declares **3** distinct unconditional `pipeline/stage-*.md` files (`stage-05-solutioning.md`, `stage-06-engineering.md`, `stage-12-execute.md`); threshold is ≥3. `novel` also fires (new reference record; ≥1 D-class decision; ≥1 Stage-5 ADR). Multi-trigger resolution ranks `cross-cutting` > `novel` > `routine`.

**Differentiation posture in force:**

| Dimension | Value |
|---|---|
| Engagement density | **Tight** — per-spoke completion surfaces a consolidated Decision Briefing; cross-D upstream-compatibility scan explicit at every D-decision |
| Stage 9 Plan Review depth | **Deep** — Collective Review N-way consistency + cross-D upstream compatibility + Tier-A design-artifact refresh gate G-CL6; PR diff review includes blast-radius assessment + design-spec conformance + Empirical Verification |
| Stage 5 activation bias | **ALL** — consistent with the independently-derived ACTIVATE rollup |
| Stage 13 outcome-window | **30-day** |

**Recorded margin caution.** The trigger-(a) count sits *exactly* at the ≥3 threshold with zero margin. Stage 5 confirmed #4995 does need `stage-05-solutioning.md` (the authoring beat where a number would otherwise enter prose is an FCM row in the Stage-5 handoff), so the count holds at 3 and the class stands. Re-classifying up was CHEAP (cheaper-to-stricter); any later walk-back to `novel` requires explicit risk acceptance per `reversibility-protocol.md`. The practical delta versus `novel` is **engagement density only** — Stage 9 depth is Deep and Stage 5 bias is ALL under either class.

## Implementation Sequence

Two waves. Max parallel width **3**. The `#4995 / #5080 / #6244` cluster is **P0 fully-serial**; the serialization binds Wave A→B, not within Wave A.

**Wave A — parallel (3 spokes, measured-disjoint write sets):**

| Position | Issue | Pts | Rationale |
|---|---|---|---|
| 1 | **#4995** | 8 | The blocking root, and Engineering Commit 0 (this plan). Two separable parts, both in this wave: **(i) the exemption rewrite** (AC4 + AC5) — one change to the exemption's *population* covering all three facets, plus wiring the dry-run reporting path as a third call site — which is the cluster's blocking edge; and **(ii) the sequencing decision** (AC1–AC3, AC6–AC7) — ADR-170 plus the `stage-12-execute.md` A.5.7 and `gate-criteria-spec.md` G-EX9 reconciliations, independent of #5080 / #6244. |
| 2 | **#5060** | 4 | Checklist item in `stage-06-engineering.md`. Fully independent. |
| 3 | **#4929 slice 1** | 4 | `Maintains-entity:` marker adoption in `per-skill-output-contracts.md`, scoped to the **19 entities** carrying a named Maintainer in `project-entity-model.md` § 6 rather than sweeping all 293 output rows. Fully independent. |

**Wave B — parallel (2 spokes), gated on #4995 part (i) landing on the release branch:**

| Position | Issue | Pts | Rationale |
|---|---|---|---|
| 4 | **#5080** | 2 | The dry-run/apply parity regression arm plus the V2 region guard. Fixture: a record with **≥2 prior hops** — the exemption cannot fire on a first move, so an arm pinned there is vacuously green and its control returns zero. |
| 5 | **#6244** | 4 | The Deviation-Log fixture and its discrimination arm. **Hard ordering constraint:** its arms are authored *after* the R6 verify path consults the classifier and excludes `AMBIGUOUS`. Landed earlier, a surviving ambiguous token makes R6's `dangling` set non-empty and reverts the whole staged move (exit 3), so every arm fails as a cascade rather than as itself. |

**Why #5080 and #6244 are verifiers, not writers.** Their ACs are behavioural assertions over the tool's output, not demands to author a predicate. Under the one-writer model each contributes fixtures and regression arms against the predicate #4995 landed, which preserves per-issue traceability without a second hand on the shared function. Stage-4 recorded a named residual on that framing — *"if the Deviation-Log case needs a different mechanism than the continuation-line case, #6244 becomes a second writer"* — and Stage 5 **discharged it**: both facets resolve to two rows of one registry consumed by one classifier, so the Wave A→B serialization stands unchanged.

**Intra-#4995 build order (single writer on `release/tools/renumber-adr.py`):**

1. Add `PROVENANCE_FREEFORM_RE`, `HOP_SENTENCE_RE`, `RECORD_MARKER_RE`, `DEVIATION_LOG_HEADING_RE`; keep `PROVENANCE_RE` and `RENUMBER_LOG_SENTENCE_RE` **byte-unchanged**.
2. Add the `RECORD_OPENERS` + `AMBIGUOUS_SECTIONS` registries and `classify_lines(text)` — the single exemption authority.
3. Reduce `is_historical_numbering_line(line)` to a shim delegating to `classify_lines`. **Run `--self-test`; the `provenance/sweep-exempts-every-hop` arm must be green before proceeding.**
4. `rewrite_citations` → `(text, count, review)`; `AMBIGUOUS` skipped and collected.
5. R6 verify → consume `classify_lines`; `AMBIGUOUS` excluded from the dangling set and carried into the report.
6. Dry-run reporting block → call `rewrite_citations` and discard the text (**call site 3**), mirroring the R6 projected-region strip **before** counting; print `would rewrite` / `exempt (record)` / `REVIEW` plus the divergence-disclosure line.
7. Emit the `R3 REVIEW:` block on **every** path, including zero sites.
8. Add `--stamp [--apply] [--check]`; refuse with zero mutation on an unresolvable/ambiguous slug or a token in link position.
9. Self-test arms; behavioural arms in `release/tools/tests/test_renumber_adr.sh`.
10. Docs: `stage-12-execute.md` A.5.7 · `gate-criteria-spec.md` G-EX9 · `adr-helper/SKILL.md` · `stage-05-solutioning.md` · ADR-170 · one `## Related ADRs` bullet in ADR-115 · `repo-integrity.yml:610`.

## Stage Applicability Matrix

**Stage 5 activation — release-level rollup: ACTIVATE.** Activation is all-or-nothing per release; per-issue triggers are recorded because they drive how much Solutioning each card needs.

| Issue | T1 new-file | T2 skill-logic | T3 structural | T4 multi-approach | T5 gov ≥3 | T6 blast-radius | Verdict |
|---|---|---|---|---|---|---|---|
| #4995 | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE |
| #5080 | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ACTIVATE (rollup — thin pass) |
| #6244 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE |
| #5060 | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ACTIVATE (rollup — minimal) |
| #4929 | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ | ACTIVATE |

T5 reads ✗ across the board: the four governance roots are `CLAUDE.md`, `core/rules/*.md`, `core/governance/*.md`, `release/governance/*.md`, and this release touches **zero** paths under them — `gate-criteria-spec.md` is `core/schemas/`, and the stage shards are `release/references/pipeline/`.

**Stages 6–13 applicability:**

| Issue | S5 | S6 | S7 DT | S8 QA | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #4995 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #5080 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #6244 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #5060 | YES | YES | YES | YES | YES | YES | YES | YES | YES |
| #4929 | YES | YES | YES | YES | YES | YES | YES | YES | YES |

**No stage is skipped for any issue, and both skip candidates were examined rather than defaulted.** #5060 at Stages 7–8 was the strongest candidate — a checklist item in a spec file has no code path — and is retained because its AC4 is a *negative functional* assertion ("verify the item does not introduce a blocking gate — confirm no `deploy.sh` check or CI job is added"), which is precisely the class of claim Dev Testing exists to falsify. #5080 at Stage 5 fires only T6 and has a determinate mechanism; it is retained because activation is all-or-nothing and the honest treatment is a thin pass, not a skipped one. Stages 9–13 are release-scoped singletons.

## File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>` columnar-in-fence form.

```
# ── Unconditional ──────────────────────────────────────────────
release/tools/renumber-adr.py                                                       edit
release/tools/tests/test_renumber_adr.sh                                            edit
.github/workflows/repo-integrity.yml                                                edit
release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md                             edit
release/ADRs/README.md                                                              edit
release/references/pipeline/stage-12-execute.md                                     edit
release/references/pipeline/stage-05-solutioning.md                                 edit
release/references/pipeline/stage-06-engineering.md                                 edit
core/skills/adr-helper/SKILL.md                                                     edit
core/schemas/gate-criteria-spec.md                                                  edit
core/schemas/per-skill-output-contracts.md                                          edit
packages/adr-helper.skill                                                           edit
packages/adr-helper.skill.sha256                                                    edit
release/ADRs/ADR-170-adr-citations-bind-at-the-claim-not-at-authorship.md           add
release/releases/plans/adr-corpus-integrity_RELEASE_PLAN.md                         add
```

**Skill-package companion rows (declared at Engineering Commit 0 + 4, not at Stage 4).** `core/skills/adr-helper/SKILL.md` is a rostered skill, so editing it obliges rebuilding its `.skill` package and committing the archive plus its `.sha256` content baseline in the **same** pull request — a beat the `skill-package-freshness` gate enforces pre-merge. Those two files are a derived consequence of a declared row rather than new scope, but they are **delivered files**, and a delivered file absent from the matrix is precisely the defect corrected three times above (AI-003 / AI-005 / AI-009). Declaring them rather than leaving a fourth instance of the same class. Surfaced by a structured delivered-vs-declared probe over the matrix, not by reading it: sensitivity — a known-declared path resolved declared; specificity — a fabricated path resolved in neither the declared nor the delivered set.

**Three Stage-4 matrix corrections, applied at Commit 0 and recorded rather than silently absorbed.** Each was measured against source by the hub before this transcription.

| ID | Correction | Basis |
|---|---|---|
| **AI-003** | `release/ADRs/README.md` promoted **READ → EDIT** | The Stage-4 matrix listed the projected release-module index as a read-only input while the same matrix declared an ADR `add` under `release/ADRs/`. A release-module ADR add regenerates that index, so it is an edit. Left as declared, this release reproduces the v4.30 D-19 shape the `adr-number-integrity` CI job catches at Stage 7 (`repo-integrity.yml`, `--verify` exits 1 on MISSING / ORPHAN / DRIFT). |
| **AI-005** | `release/tools/tests/test_renumber_adr.sh` promoted to **EDIT** | Absent from the Stage-4 matrix (0 occurrences in the plan comment and 0 in its FCM block, against a sensitivity arm of other `release/tools/` paths present). It is CI-enforced at `.github/workflows/repo-integrity.yml:587` and hard-fails the job at `:598-608`; it is allowlisted at `core/config/allowlists/script-execution-allowlist.txt:309-312`. Every behavioural arm for #4995 / #5080 / #6244 lands here. Undeclared, those edits evade Stage-8 grading. |
| **AI-009** | `.github/workflows/repo-integrity.yml` promoted to **EDIT** | Absent from the Stage-4 matrix. Line **610** emits `"ADR renumber — six-step move verified end-to-end"` while the tool ships **seven** R-steps. This site sits structurally OUTSIDE the cluster design's cascade-sweep population (`*.md` plus two named scripts), so no `*.md` sweep can reach it — 0 of the 1,294 corpus `.md` files are workflows. |

**`CONDITIONAL:D-MECHANISM` — struck, not carried.** Stage 4 declared a conditional `<reservation-ledger-surface>  add  CONDITIONAL:D-MECHANISM` row that fires only if #4995 selects direction 2 (reservation). Stage 5 selected **direction 1** (late binding of citations), so the condition resolved *false* and the row is removed rather than left conditional. Per File Change Matrix contract rule 5, a row left CONDITIONAL after its condition resolves is an authoring defect — it is indistinguishable from a row whose condition never fired and buys exemption from the delivery check for the price of one token. **No new file is added by the selected direction:** `--stamp` is a new mode inside the existing `renumber-adr.py`, and the Tier-A design artifact embeds in `stage-12-execute.md` (below the § 3 centralization threshold).

### Read-only inputs

```
core/ADRs/ADR-092-plan-file-claim-time-stamping.md                READ
core/ADRs/README.md                                               READ
release/tools/generate-adr-index.py                               READ
release/tools/check-adr-numbers.py                                READ
core/deploy/tools/check-ownership-collision.py                    READ
core/disciplines/project-entity-model.md                          READ
core/rules/bypass-mode-readiness.md                               READ
core/deploy/deploy.sh                                             READ
core/config/allowlists/script-execution-allowlist.txt             READ
```

### Release-wide explicit non-scope

```
# The 188 existing release plans are the file CLASS the exemption must reach,
# NOT files this release edits. #6244 governs the predicate that reads them;
# it rewrites none of them. Its fixture plan is synthetic and lives only
# inside a $(mktemp -d) topology.
release/releases/plans/**/*_RELEASE_PLAN.md                       NOT EDITED
# The operator-instance mode file is not repo-tracked and cannot be delivered
# by a release PR. #4929 AC5/AC6 are deferred against #5053 for this reason.
ownership-collision.mode                                          NOT EDITED
```

**New-executable companion obligation: N/A — enumerated over the `add` rows.** The matrix carries two `add` rows and neither is a tracked executable: `ADR-170-…md` is a markdown record and this plan file is markdown. `renumber-adr.py` and `test_renumber_adr.sh` are `edit` rows on already-established, already-allowlisted paths, so no `core/config/allowlists/script-execution-allowlist.txt` companion row is owed. The allowlist is carried as a READ input precisely so a reviewer can confirm the existing four registration forms for `test_renumber_adr.sh` are untouched — a future *move* of that file would break them.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: governance }`

*Classification rationale (A3-time, from the matrix):* every path is an internal pmo-platform artifact, so the release is **sourcing-exempt** and takes Form X verbatim. Dominant domain is **`governance`** — the schema, pipeline-spec, ADR, and skill surfaces; the secondary domain is **`software`**, carried by `release/tools/renumber-adr.py`, its test suite, and the CI workflow, which are nonetheless the release's load-bearing change. Sourcing-exempt does not make the release domain-less. No external practice is consumed, so no Mode-B→A upgrade is available and the label travels unchanged into Stage 13's close-class rung 1.

## Contention Map

Computed over declared **write-class** sets only; READ and NOT-EDITED rows are excluded from the obligation set per File Change Matrix contract rule 3.

| Path | Class | Claimants | Resolution |
|---|---|---|---|
| `release/tools/renumber-adr.py` | **MULTI-WAY x3** | #4995, #5080, #6244 | **Co-authorship, not ordinary contention.** One writer (#4995), two verifiers. Wave A→B serialization; P0 fully-serial posture. |
| `release/tools/tests/test_renumber_adr.sh` | **MULTI-WAY x2** | #5080 (ACT A14 parity/region arms), #6244 (ACT 4 Deviation-Log fixture) | Disjoint acts, each seeding its own `origin<N>` / `wt-<N>` per the suite's established per-scenario pattern. Additive; no shared fixture state. |
| `release/references/pipeline/stage-12-execute.md` | **MULTI-WAY x2** | #4995 (unconditional), #6244 (conditional) | #4995's A.5.7 rewrite lands in Wave A; #6244 re-reads the section as it then stands. |
| `.github/workflows/repo-integrity.yml` | single | #4995 (the AI-009 step-count string) | — |
| `release/ADRs/README.md` | single | #4995 (projector regeneration after the ADR-170 add) | Regenerated by `generate-adr-index.py --write`, never hand-edited. |
| `core/schemas/gate-criteria-spec.md` | single in-release | #4995 (G-EX9 stamp limb + step-set restatement) | **Cross-milestone: see R2.** |
| `core/schemas/per-skill-output-contracts.md` | single | #4929 | — |
| `core/skills/adr-helper/SKILL.md` | single | #4995 | — |
| `release/ADRs/ADR-115-…md` | single | #4995 (one `## Related ADRs` bullet) | — |
| `release/references/pipeline/stage-05-solutioning.md` | single | #4995 | — |
| `release/references/pipeline/stage-06-engineering.md` | single | #5060 | — |
| `release/ADRs/ADR-170-…md` (add) | single | #4995 | — |

**Pairwise overlap — all 10 ordered pairs enumerated, none omitted:**

```
#4995 x #5080 : release/tools/renumber-adr.py, release/tools/tests/test_renumber_adr.sh
#4995 x #6244 : release/tools/renumber-adr.py, release/tools/tests/test_renumber_adr.sh,
                release/references/pipeline/stage-12-execute.md
#4995 x #5060 : DISJOINT
#4995 x #4929 : DISJOINT
#5080 x #6244 : release/tools/renumber-adr.py, release/tools/tests/test_renumber_adr.sh
#5080 x #5060 : DISJOINT
#5080 x #4929 : DISJOINT
#6244 x #5060 : DISJOINT
#6244 x #4929 : DISJOINT
#5060 x #4929 : DISJOINT
```

Six DISJOINT results are load-bearing, so both arms ran on the same instrument: **sensitivity** — the known-overlapping pair `#5080 × #6244` returned a non-empty set; **specificity** — the known-disjoint pair `#5060 × #4929` returned empty. A zero from an instrument whose control arm also returned zero would be a broken probe; it did not.

**The `renumber-adr.py` overlap is finer than a file.** Function-level, with the Stage-5 disposition applied:

| Object | Line(s) at baseline | #4995 | #5080 | #6244 |
|---|---|---|---|---|
| `is_historical_numbering_line` (the predicate) | 512 | **writes** (reduced to a shim) | reads | reads / asserts |
| `classify_lines` + the two registries (new) | new | **writes** | asserts against | asserts against |
| `PROVENANCE_RE` / `RENUMBER_LOG_SENTENCE_RE` | 233, 236 | **preserved byte-unchanged**; demoted to registry rows | reads | reads |
| `rewrite_citations` (call site 1) | 524–534 | **writes** (gains a `review` out-parameter) | asserts | asserts |
| R6 zero-dangling verify (call site 2) | 1104–1107 | **writes** (consumes the classifier) | asserts | **precondition-asserts** |
| dry-run reporting block (call site 3 — no call site at baseline) | 972–981 | **writes** (adds the call + the region strip) | asserts | reads |
| `self_test()` arms | 1249–1324 | **writes** (extends) | **writes** (adds 4 arms) | **writes** (adds 3 arms) |

**Cross-PR contention: none.** Open PRs = **0**, re-measured live at the pinned baseline. Per audit-baseline discipline the pin is recorded alongside the zero, because a single PR appearing later invalidates it silently.

### In-Flight Release Roster

**Measured at:** `539c4440fc1457e8d42d2bbe11c7be663baf596f` · 2026-09-01 · **Population:** n=**0** in-flight sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |

`none in flight at 539c4440 / 2026-09-01`. One remote `release/*` head exists — `release/operational-folder-enforcement-migration` — and it is **excluded with evidence, not silently omitted**: the ancestor test `git merge-base --is-ancestor` exits **0**, so the branch is already merged and undeleted, and its own editset relative to `main` is empty. A merged-but-undeleted head satisfies the roster's naive population predicate (a remote `release/*` head carrying no open PR) while contributing no in-flight surface, so recording the exclusion with its ancestor test is what keeps the zero honest.

## Risk Register

| ID | Risk | Class | Sev | Reversibility / Confidence | Owner-stage | Mitigation |
|---|---|---|---|---|---|---|
| **R1** | **Shared-predicate silent merge.** Three cards write one function. Parallel spokes would each rewrite the exemption from a different premise. Git reports no conflict — last-writer-wins produces a *semantically* wrong predicate that passes every textual check | dependency + contention | **HIGH** | CHEAP / HIGH | Stage 6 | One-writer-two-verifiers sequencing (Wave A→B); **P0 fully-serial** posture declared explicitly at the D-Gate rather than defaulted; **CIAC-1** grades the single-predicate invariant on the merged PR |
| **R2** | **Cross-milestone semantic collision on G-EX9.** #4762 (milestone #321 `adr-corpus-status-integrity`, verified OPEN) edits the same `gate-criteria-spec.md` G-EX9 row. The collision is deeper than a shared row: #4762 re-targets the *verify* predicate (`provenance_head`) while #4995 widens the *sweep-exemption* side — and `PROVENANCE_RE` is the shared input to both roles | dependency (cross-milestone) | **MEDIUM** | CHEAP / MEDIUM | Stage 5 → Stage 12 | **DISCHARGED at design.** `PROVENANCE_RE` is **preserved as a named module symbol** — no rename, regex byte-unchanged, role narrowed from *the* predicate to `RECORD_OPENERS` row 1. The two G-EX9 edits are **line-disjoint by construction**: #4995 appends the exemption / parity / stamp obligations; #4762 re-keys the provenance predicate in the Method column, which this release does not touch. Merge-order constraint stands — whichever merges second re-reads the row as it then stands. Confirmed at Stage 9 (AI-006) |
| **R3** | **#4929 slice 2 is structurally un-gradeable in this release.** ACs 4–6 require a ≥3-day warn-mode review over the *adopted* corpus (cannot start until slice 1 is on `main`) and an `ownership-collision.mode` operator-instance file that is not repo-tracked | scope | **HIGH** | CHEAP / HIGH | Stage 4 → before Stage 8 | **RESOLVED at D4.** AC5/AC6 marked `[DEFERRED — out of release scope; blocked on #5053]` with original text intact; **no parallel card created** — #5053 already owns the root cause and Check 54 is its second confirmed instance, which discharges that card's open assumption. AC4 stays in-release as a warn-mode triage over slice 1's own adoption |
| **R4** | **#4995's direction was undecided at Stage 4**, and the two directions have materially different blast radii | scope | **MEDIUM-HIGH** | MODERATE / MEDIUM | Stage 5 | **DISCHARGED.** Direction 1 selected on measured grounds; the direction-2 conditional row is struck at Commit 0 rather than carried |
| **R5** | **Widening the exemption risks the inverse defect.** A genuine live citation inside a Deviation Log row would stop being swept and go stale. The two cases are lexically identical, so the fix must discriminate on position or intent rather than on the token | scope / correctness | **MEDIUM** | CHEAP / HIGH | Stage 5 → Stage 7 | The third verdict is the answer: `AMBIGUOUS` **names the site and does not rewrite it**, so the sweep never guesses. The discrimination control arm is **mandatory** — **CIAC-2** carries it as a specificity limb, and the review block is emitted on every path including zero sites because after ratified premise 1 it is the *only* detector for the un-swept side |
| **R6** | **Reflexive-pipeline hazard.** This release modifies the very tool its own Stage 12 may invoke. A concurrent claim on ADR-170 would force a renumber run by the predicate this release just rewrote, which could corrupt this release's own audit trail | rollback / correctness | **HIGH** | CHEAP / HIGH (revert = one function + its call sites, one file) | Stage 12 | Governed and available: `python3 release/tools/renumber-adr.py --self-test` **before** any Stage-12 renumber, plus G-EX9's completion-mode self-repair (the tool is idempotent and performs only outstanding steps). The prior `[ASSUMPTION – CONFIRM]` that changing the tool mid-renumber is forbidden was **discharged as ungoverned** against a structured scan returning zero rule-stating hits; the corpus states the opposite explicitly — *"a tool is not a gate, and the introducing release uses it at Engineering Commit 0."* This is a sequencing note, not a bundling prohibition |
| **R7** | **ADR-170 is provisional.** Per ADR-115 the number binds only at merge, and this release is *about* that hazard | dependency | LOW-MEDIUM | CHEAP / HIGH | Stage 6 → Stage 12 | **Re-verified at Engineering Commit 0** against `git ls-tree origin/main` across BOTH ADR directories — the worktree checker PASSes on a number already taken on the mainline, so the mainline read is the authority. Two independent methods agree (see § Authorized ADRs). Additionally **dogfooded**: this release carries `{{ADR:<slug>}}` indirection for its own record wherever direction 1 provides one |
| **R8** | **The dry run diverges from apply in more ways than #5080 names.** Beyond the missing exemption, the dry-run block applies no projected-region handling, and out-of-scope index files are not enumerated at all | scope (discovered) | MEDIUM | CHEAP / MEDIUM | Stage 5 | **DISCHARGED by enumeration.** Stage 5 measured the full set: **8** divergences (V1–V8). **V1 + V2 are repaired** (both over-predict, both exemption-class, both at call site 3). **V3–V8 are disclosed**, not silently omitted — the dry run gains a closing line naming exactly which steps it enumerates and which it does not. A full plan-parity refactor is routed to Recommendations rather than smuggled into a five-card bundle |
| **R9** | **The `AMBIGUOUS_SECTIONS` heading regex misses a live corpus form.** The Stage-5 row `^#{1,6}\s+Deviation Log\b` matches 64 of 69 heading-shaped lines; one of the five misses is a genuine section heading (`## 11. Stage 5 Deviation Log`), defeated by the numeric prefix | correctness | **MEDIUM** | CHEAP / HIGH | Stage 6 | **AI-007.** Loosen the registry row to tolerate a numeric or ordinal prefix, and add a self-test arm pinning that heading form. The trade is settled by the asymmetry the registry exists for: a false positive only makes a region *named*; a miss *rewrites* |
| **R10** | **The stated parity mechanism closes V1 and leaves V2 open at the same magnitude.** The dry run calling `rewrite_citations` and discarding the text is the apply path minus the write for V1 — but R6's verify path strips the projector-owned region before checking, and the dry-run block does not | correctness | **MEDIUM** | CHEAP / HIGH | Stage 6 | **AI-008.** Mirror the R6 treatment — `if rel in PROJECTED_INDEXES: lines = _strip_projected_region(lines)` — **before** counting. Two lines, already written elsewhere in the same file. Graded by the `dryrun/region-excluded` self-test arm, which is the only grader: CIAC-1's probe detects the first limb only |
| **R11** | **Arms landed before R6 is wired fail as a cascade, not as themselves.** A surviving `AMBIGUOUS` token makes R6's dangling set non-empty and reverts the whole staged move to exit 3 | sequencing | MEDIUM | CHEAP / HIGH | Stage 6 | The #6244 arms are authored after the R6 wiring step, and each opens with a precondition arm (`the move exits 0`) that names that cause in its own label, so a failure reads as itself |
| **R12** | **Fixture vacuity.** `_in_scope_files` drops non-UTF-8 and out-of-diff files from sweep scope, so a fixture that never entered scope passes "unchanged" for the wrong reason and the whole act is a broken probe | correctness (test) | MEDIUM | CHEAP / HIGH | Stage 6 | Every behavioural arm is preceded by a **dry-run scope-membership arm** asserting the fixture is in scope — the idiom the suite already owns. The first-move negative control is likewise mandatory: without it a green parity arm is unfalsifiable |

**Rollback strategy.** Release-wide rollback is **CHEAP**: every change is additive-or-in-place in a single PR, with no data migration and no cross-repo surface. Release-level rollback = revert the single merge commit.

**The one asymmetric member, stated honestly.** #4995's exemption rewrite reverts to the *known* defective sweep behaviour rather than to an unknown state — that is what makes it cheap. The **token convention** is the part that hardens over time: it is CHEAP today and becomes **MODERATE** once a second release has authored `{{ADR:<slug>}}` tokens, because a revert would then strand unresolved tokens in shipped prose. The `--stamp --check` limb on G-EX9 bounds that, since no release can merge carrying an unresolved token. #4929's marker adoption is revert-safe because the `PRODUCE`-default means removing a marker restores producer semantics rather than orphaning a row. **No member requires a data or state rollback.**

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#4995 × #5080 × #6244 on `release/tools/renumber-adr.py`):** the apply path and the dry-run reporting path resolve the historical exemption through **one** named authority — the dry-run block references the exemption predicate identifier, and the file defines exactly one such predicate. A divergence between the two paths is the #5080 defect re-introduced (#4995 AC5 lifted to release scope). *Shared surface:* the exemption authority and its three call sites in `release/tools/renumber-adr.py`. *Method:* `python3 -c "import re; s=open('release/tools/renumber-adr.py').read(); d=s[s.index('if not apply_changes:'):]; d=d[:d.index('return 0')]; print('DRYRUN_CONSULTS', 'rewrite_citations' in d or 'classify_lines' in d); print('PREDICATE_DEFS', len(re.findall(r'^def is_historical_numbering_line', s, re.M)))"` — expected `DRYRUN_CONSULTS True` and `PREDICATE_DEFS 1`. *Control (same instrument, same target):* the pre-fix tool on this same probe returns `DRYRUN_CONSULTS False`, observed at the pinned baseline. **Limb 2, and the reason it is separate:** this probe grades the *historical-exemption* limb only and is structurally blind to the projected-region limb, so `dryrun/region-excluded` in `--self-test` is the only grader for that half. Both limbs must report. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#4995 × #6244 on the exemption population):** one exemption authority spares **all three** recorded-number classes — hard-wrapped provenance continuation lines, release-plan Deviation Log rows, and renumber-log sentences — while still sweeping a genuine live citation in each of those file classes. *Shared surface:* the `RECORD_OPENERS` / `AMBIGUOUS_SECTIONS` registries in `release/tools/renumber-adr.py`. *Method:* `python3 release/tools/renumber-adr.py --self-test` extended with one arm per facet (a three-line hard-wrapped provenance note whose lines 2–3 carry the old number; a Deviation Log row citing a single historical number; the ADR-103 combined-lineage head form), each asserted unchanged. *Null-arm control per AC-Binding Limb 2, same instrument and same fixtures:* a genuine live citation seeded into each of the same fixtures **must** be rewritten — expected non-zero. The paragraph-extent rule additionally carries its own negative control: **break the paragraph with a blank line and line 3 must revert to `CITE` and be rewritten**; without that arm the extent rule is indistinguishable from a blanket exemption. Without the discrimination arms the fix is indistinguishable from disabling the sweep on release plans. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#4995 × #5060 on `release/ADRs/README.md`):** this release is the first exercise of #5060's own checklist item — #4995 authors an ADR under `release/ADRs/`, so the Stage-6 question *"did this release add a record under `release/ADRs/`?"* must be answered in-branch and its answer acted on. The answer for this release is **YES**, so the generated index carries the ADR-170 row and reports zero drift. *Shared surface:* `release/ADRs/README.md`'s `ADR-INDEX` projected region and the `stage-06-engineering.md` checklist item. *Method:* `python3 release/tools/generate-adr-index.py --verify` — expected zero drift, plus a read of this plan's Stage-6 record confirming the recorded answer matches the directory the ADR actually landed in. *Control (same instrument, same target):* `release/ADRs/README.md` carries `<!-- ADR-INDEX:BEGIN -->` while `core/ADRs/README.md` does not — so the projector has a real region to verify against and a No answer would be genuinely load-bearing rather than vacuous. *Graded at Stage 9 QC3.5 on the merged PR.*

`INT-N` per-issue-pair integration ACs are authored at Stage 5 Phase A4.2 and grade per-issue at Stage 8. Three fired on this release's dependency edges: **INT-1** (#5080 ← #4995 — does the dry-run path reach its verdict by *calling* the authority rather than re-deriving a count, **and** does it strip the projected region before counting? both limbs); **INT-2** (#6244 ← #4995 — does the Deviation-Log fixture assert against a *registry row*, and does its discrimination arm assert a live citation elsewhere in the same file class is still rewritten? both limbs); **INT-3** (#6244 ← #4995 — does the fixture plan demonstrably enter sweep scope, and does the move exit 0? both are preconditions that fail *silently green* if unasserted).

## Verification Plan

**AC baseline** — per-issue acceptance-criterion counts as read at plan time, and the commit the read was taken against. Stage 9's AC-coverage read compares the emitted `AC-<n>` set against this line; without it that read has nothing to compare and emits `N/A — no baseline recorded`.

`ac_baseline: { #4995: 7, #5080: 3, #6244: 5, #5060: 4, #4929: 6, read_at: 539c4440fc1457e8d42d2bbe11c7be663baf596f }`

**Total 25 criteria across 5 issues.** Two of them (#4929 AC-5 / AC-6) are `[DEFERRED]` by ratified premise 6 and carry honest rows rather than being omitted — an omitted row is what lets a plan read clean by silence.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #4995 | AC-1 | `grep -c 'ADR-170' release/ADRs/ADR-170-adr-citations-bind-at-the-claim-not-at-authorship.md` resolves, and the record's `## Status` names the amendment of ADR-115 while its `## Decision` states the citation-time rule: `grep -c 'Amends ADR-115' release/ADRs/ADR-170-*.md`. Specificity arm, same instrument same target: `grep -c 'ZZQQ-NOT-A-STATUS' release/ADRs/ADR-170-*.md` | Record exists · `ADR-170` token **2** · `Amends ADR-115` **1** in `## Status` · `## Decision` states when a number enters branch-authored prose and what resolves it · specificity **0** |
| #4995 | AC-2 | `grep -c 'the branch diff' release/tools/renumber-adr.py` — the sweep resolves a slug against the on-disk ADR set within the branch diff, which is what confines a reconciliation's changed-file set to the record plus its index surfaces. Specificity arm, same instrument same target: `grep -c 'ZZQQ-NOT-IN-THIS-FILE' release/tools/renumber-adr.py`. The end-to-end topology arm — author at next-free, land a colliding number on a simulated mainline, assert the changed-file set — lands in `release/tools/tests/test_renumber_adr.sh` with the Wave-B slices, which own that file | Scope statement **10** · specificity **0**. Topology arm: changed-file set = the ADR file + index surfaces only, with the **pre-change tool as the sensitivity arm** yielding a strictly larger set — measured on the same fixture, not asserted |
| #4995 | AC-3 | `grep -c 'def _in_scope_files' release/tools/renumber-adr.py` = 1 — one branch-diff scope function, which is what makes branch-scoping a property of the tool rather than of an operator flag. Paired arm: `grep -c 'exclude-path' release/tools/renumber-adr.py` is non-zero, so the manual escape hatch still exists and is not what the new path depends on. Specificity arm: `grep -c 'ZZQQ-NOT-A-SCOPE-FN' release/tools/renumber-adr.py` | Scope function **1** · escape hatch **7** references, still present but not what the token path depends on · specificity **0**. A mainline file citing the old number for a *different* record needs no hand-written `--exclude-path`, because a slug resolves only to a file in this tree |
| #4995 | AC-4 | `grep -c '^def classify_lines' release/tools/renumber-adr.py` = 1 — one classifier over the registry, so all three facets are covered by one change rather than three patches. Paired arms, one per facet, each a named self-test arm: `grep -c 'exempt/wrapped-continuation-is-record' release/tools/renumber-adr.py`, `grep -c 'exempt/devlog-row-is-ambiguous' release/tools/renumber-adr.py`, `grep -c 'dryrun/region-excluded' release/tools/renumber-adr.py`. Specificity arm: `grep -c 'ZZQQ-NOT-AN-ARM' release/tools/renumber-adr.py` | Classifier definitions **1** · each facet arm ≥1 · specificity **0**. `--self-test` exits 0 with all three facet arms green. **Negative control per facet (mandatory):** the pre-fix tool sweeps or mis-predicts each fixture — a green arm whose control is also green is a broken probe |
| #4995 | AC-5 | `rewrite_citations` and the dry-run reporting path consult the **same** authority — structurally, by the dry run *calling* `rewrite_citations` and discarding the returned text, so a divergence is impossible without deleting a call. Method: CIAC-1's probe, both limbs (`DRYRUN_CONSULTS` and `dryrun/region-excluded`) | `DRYRUN_CONSULTS True` · `PREDICATE_DEFS 1` · `dryrun/region-excluded` green · control: the baseline tool returns `DRYRUN_CONSULTS False` |
| #4995 | AC-6 | `grep -n 'A.5.7' release/references/pipeline/stage-12-execute.md` resolves and the surrounding text matches ADR-170's decision — specifically that the stamp is the **last** step of the claim (`detect → reconcile → stamp → verify-zero-tokens`) and that every named review site is dispositioned. Specificity arm: `grep -c 'A.5.99' release/references/pipeline/stage-12-execute.md` | `A.5.7` **13** lines; the ordering and the review-disposition obligation are both stated · specificity **0** |
| #4995 | AC-7 | `grep -c 'G-EX9' core/schemas/gate-criteria-spec.md` resolves ≥1. Paired arms: `grep -c 'stamp --check' core/schemas/gate-criteria-spec.md` ≥1 for the new conjunct, and `grep -c 'complete on all seven steps' core/schemas/gate-criteria-spec.md` = 1 for the restated step set. Coordination limb (R2 / AI-006), **row-scoped so prose elsewhere cannot move it**: `grep -c 'G-EX9 .*Numbering provenance' core/schemas/gate-criteria-spec.md` — the criterion row still carries the shape predicate in its Method column, since a sibling release owns re-targeting it. Specificity arm: `grep -c 'G-EX99' core/schemas/gate-criteria-spec.md` | G-EX9 **11** lines · stamp limb **3** · seven-steps **1** (baseline `complete on all six steps` falls 2 → 1; the surviving occurrence is the append-only v2.8 changelog entry, correctly preserved) · coordination limb **1**, identical to baseline. Sensitivity: `G-EX9` rises 8 → 11 on the same instrument, so the limb's 1 is not a dead pattern · specificity **0** |
| #5080 | AC-1 | The dry run reports the same edit set the apply path performs. Method: shell-suite ACT A14 parity arms on a record with ≥2 prior hops — `PRE − POST == would_rewrite(<file>)` **and** `POST == exempt(<file>)` on the curated index and on the record file | Identity holds on both files. **Sensitivity:** the same arms on a *first* move are vacuously green (`exempt == 0` everywhere) — the mandatory `A14e` first-move control that separates "arm broken" from "tool regressed". **Scope, stated without inflation:** this AC closes **V1** of eight; V2 is repaired in the same commit as a recorded *scope extension*, not under AC-1 |
| #5080 | AC-2 | Where the two legitimately differ, the dry run **names** the exemption. Method: assert the per-file dry-run line carries a non-zero `exempt (record)` column, and that the closing divergence-disclosure line is present. `AC-2 is discharged by the exempt count being PRINTED, not by its being subtracted` — a file reported `would rewrite 0` is indistinguishable from a file with no citations | Non-zero `exempt (record)` on the index file · disclosure line present naming which steps the dry run enumerates and which it does not · **the R2 rename is named, not omitted** (it is disclosed by the `R1 PROCEED` line that executes before the dry-run block) |
| #5080 | AC-3 | A regression arm on a record with **≥2 prior hops**. Method: shell-suite ACT A14 three-hop chain — each hop one commit, since the tool refuses a dirty tree | Arms A14a–A14i present and green. **Measured margin, recorded so nobody optimizes it away:** *one* prior hop already reproduces the divergence; two is a deliberate margin that additionally exercises the lineage case. Do not reduce it. Stage 6 records the **observed** `PRE / would / exempt / POST` values; a mismatch against the derived table is a finding to report, never a number to edit |
| #6244 | AC-1 | `grep -c 'A15a AC1 SILENT CASE' release/tools/tests/test_renumber_adr.sh` ≥1 — the ACT-15 arm asserting a single-number historical Deviation Log row survives the sweep as a row literal. Specificity arm: `grep -c 'ZZQQ-NOT-AN-ARM' release/tools/tests/test_renumber_adr.sh` | Arm present ≥1 · specificity **0**. In-suite assertion: the row is byte-identical (1) and did not acquire the new number (0). **Precondition arms run first:** the fixture plan is demonstrably in sweep scope, and the move exits 0 — both fail *silently green* if unasserted |
| #6244 | AC-2 | `grep -c 'A15b AC2 DISCRIMINATION' release/tools/tests/test_renumber_adr.sh` ≥1 for the outside-the-section limb, plus `grep -c 'CLOSE BOUNDARY' release/tools/tests/test_renumber_adr.sh` ≥1 for the after-the-section limb. Specificity arm: `grep -c 'ZZQQ-NOT-AN-ARM' release/tools/tests/test_renumber_adr.sh` | Both arms present · specificity **0**. In-suite assertion: both citations swept, expected **non-zero**. The after-the-section site is the only one that distinguishes "the section opened" from "the section closed at the next same-or-higher heading" — without it the region rule could be implemented as open-and-never-close and every other arm would still pass |
| #6244 | AC-3 | `grep -c 'A15c AC3 COHERENCE' release/tools/tests/test_renumber_adr.sh` ≥1 — the ACT-15 arm asserting the incoherent-range case does not reproduce. Specificity arm: `grep -c 'ZZQQ-NOT-AN-ARM' release/tools/tests/test_renumber_adr.sh`. In-suite method: seed a range straddling swept and unswept tokens; assert coherence after, via a `python3` scan counting ranges whose low end exceeds their high end (the local `grep` is `ugrep`, and a rejected back-reference pattern yields a plausible zero) | Straddling range byte-unchanged (1) · incoherent ranges **0** · sensitivity: the general property arm would still fire on a *different* incoherent range, so the zero is not string-specific. **Residual recorded, not claimed as covered:** a range straddling swept and unswept tokens *outside* any record region is still split incoherently — the design fixes the Deviation-Log instance, not the range class |
| #6244 | AC-4 | `grep -c 'A15d AC4' release/tools/tests/test_renumber_adr.sh` ≥1 — the arms asserting the `R3 REVIEW:` block names the fixture plan, names the un-swept live row, and is emitted on a zero-site run. Paired arm on the emitter itself: `grep -c 'R3 REVIEW:' release/tools/renumber-adr.py` ≥1. Specificity arm: `grep -c 'ZZQQ-NOT-AN-ARM' release/tools/tests/test_renumber_adr.sh` | Arms present · emitter present · specificity **0**. In-suite assertion: the ambiguous site is named and unmodified, and the un-swept live row is named too (after ratified premise 1 that line is its **only** detector) · **zero-site control:** the block is emitted on a run with no ambiguous sites at all — a step that is silent when it finds nothing is indistinguishable from a step that did not run |
| #6244 | AC-5 | A regression arm on a record with ≥2 prior hops, since the surface only populates after a second renumber. Method: hop 2 of ACT 15 — a row recording hop 1 is authored by hand between the hops, then the second renumber runs | Second hop exits 0; the hop-1 row survives **byte-identical**; its current number was not silently advanced. **This is a *run*, not a string:** the row's `ADR-<current>` token is the live hazard, and hop 2 is the only moment it exists — a naive sweep rewrites it and the row becomes syntactically valid, internally consistent, and false |
| #5060 | AC-1 | `grep -c 'release/ADRs' release/references/pipeline/stage-06-engineering.md` — the stage spec carries a checklist item asking whether the release added a record under `release/ADRs/`. Sensitivity arm, same instrument same target: `grep -c 'Engineering' release/references/pipeline/stage-06-engineering.md` is non-zero. Specificity arm: `grep -c 'release/ZZQQ-ADRs' <same file>` | ≥1 match (was **0** at baseline) · sensitivity non-zero · specificity **0** |
| #5060 | AC-2 | Read the item; confirm both branches are named — Yes (regenerate the index in the same branch) and No (no action; recorded, not silent). Method: `grep -c 'generate-adr-index' release/references/pipeline/stage-06-engineering.md` ≥1 for the Yes arm, plus a read confirming the No arm is stated as a recorded answer rather than an omission | Both arms named in the item text · Yes arm names the projector command |
| #5060 | AC-3 | Confirm whether `core/ADRs/README.md` carries the symmetric trigger and state the finding. Method: `grep -c 'ADR-INDEX:BEGIN' core/ADRs/README.md` against `grep -c 'ADR-INDEX:BEGIN' release/ADRs/README.md` | `core/ADRs/README.md` → **0** (no projected fence, no projector; a curated thematic document by explicit decision) · `release/ADRs/README.md` → **non-zero**. A core-only release trips no projection trigger because there is none to trip, so the checklist item stays release-module-only. **Already discharged in-body 2026-08-30; re-run here as the control that makes the asymmetry a measurement rather than a recollection** |
| #5060 | AC-4 | The item introduces no blocking gate. Method: `git diff origin/main...HEAD -- core/deploy/deploy.sh .github/workflows/ \| grep -c 'adr-index\|release/ADRs'` over this release's diff, scoped to the checklist item's subject | **0** new `deploy.sh` checks or CI jobs attributable to #5060 · **control, same instrument same target:** the same diff scoped to `.github/workflows/repo-integrity.yml` returns non-zero for the AI-009 string edit, so the zero is a measured absence rather than an unresolvable path. Wording is a checklist *question*, not an assertion |
| #4929 | AC-1 | `core/schemas/per-skill-output-contracts.md` carries ≥1 `Maintains-entity: <E>` marker for every entity holding a named Maintainer in `project-entity-model.md` § 6. Method: parse both surfaces; assert the marker set covers the § 6 Maintainer set | Marker set covers all **19** § 6 Maintainer entities (baseline: **0** markers over 293 table rows). Any § 6 entity with no corresponding declared output is reported **as a finding, not a pass** · sensitivity: the § 6 table-row regex returns 19 on the same instrument |
| #4929 | AC-2 | `grep -c 'I3' core/deploy/tools/check-ownership-collision.py` ≥1 — the I3 collision predicate is present in the shipped checker. Paired arm: `grep -c 'Maintains-entity' core/schemas/per-skill-output-contracts.md` ≥1, so the predicate has a declared population to fire on (it is zero-ESCALATE by construction until markers exist). Specificity arm: `grep -c 'ZZQQ-NOT-A-PREDICATE' core/deploy/tools/check-ownership-collision.py` | Predicate present · marker population non-zero · specificity **0**. In-suite negative control: a fixture declaring a marker for an entity whose § 6 Maintainer is a different skill makes the post-adoption tool exit **1** and name the collision, while the **pre-adoption tool exits 0 on the identical fixture**. A predicate that cannot be made to fire is not a check |
| #4929 | AC-3 | Check 54's I1 predicate can fire. Method: negative control — a fixture § 6 cell resolving to ≥2 distinct maintainer skills | Exits **1** · control: a single-maintainer cell on the same instrument exits 0 |
| #4929 | AC-4 | The first full warn-mode run over the adopted corpus is triaged and its finding set recorded. Method: `./deploy.sh --check`; capture the Check 54 finding count and disposition each finding | Finding count captured and every finding dispositioned in the PR evidence block. **No flip occurs this release** — the run is a triage, and its output is the record. A count with no disposition is not a triage |
| #4929 | AC-5 | `[DEFERRED — out of release scope; blocked on #5053]` The enforce-flip is config, not a code change, and requires an `ownership-collision.mode` operator-instance file created after a ≥3-day warn-mode review that cannot begin until slice 1 is on `main` | **N/A this release**, recorded rather than graded. Routed to #5053, which owns the root cause: a check whose mode resolver reads an untracked instance path is unreachable from a release branch. Original criterion text intact in the issue body |
| #4929 | AC-6 | `[DEFERRED — out of release scope; blocked on #5053]` A new-skill build cannot pass Check 54 in enforce mode while declaring maintainer-write to an already-owned entity | **N/A this release**, recorded rather than graded. Same blocker as AC-5; the I3 fixture that would carry it exists (AC-2) but cannot be run under enforce mode from a release branch |

**Method-rendering obligation.** Every method cell must be mechanically classifiable, so no row reaches Stage 7 as an unreadable ERROR. A cell reading `[DEFERRED]` is a **standing obligation on the named card's Engineering spoke**, not a waiver: that spoke replaces its own rows with executable assertions **at its own commit**, when it knows the tokens its implementation introduces. Rendering them earlier would mean inventing symbol names for unlanded work and binding the implementation to a guess. The two `[DEFERRED]` rows above (#4929 AC-5 / AC-6) are the exception the Stage-7 entry condition permits **by name**: their subject is an operator-instance file outside the tree, so no card's landing in this release makes them executable.

**Seeded-failure discipline.** Every card delivering an entry point ships a seeded-failure run **and** a passing control run in the same evidence block. An entry point that cannot be made to fail is not a gate, and a green run alone does not distinguish the two. This release's load-bearing instance is the exemption: every widening arm carries a negative control showing the pre-fix tool swept or mis-predicted the same fixture.

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Mixed — Wave A parallel (3 measured-disjoint spokes), Wave B serial-gated on Wave A's #4995 part (i) |
| **Commit strategy** | One commit per issue slice, referencing the source issue; Engineering Commit 0 is this plan file |
| **Review approach** | Single PR for the entire release, one merge gate |
| **Deployment mechanism** | Git merge + S-2 skill copy + manifest execution |
| **Stacked-base cleanup posture** | N/A — enumerated over the topology set {SINGLE, OPTION-A, stacked}: topology is SINGLE, so no stacked-base wave exists to clean up |

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #4995 | `git revert <commit>` — one function plus a registry plus its three call sites, in one file | **Low**, with a named asymmetry: reverting restores the *known* defective sweep, not an unknown state. The token convention hardens to MODERATE once a second release authors tokens |
| #5080 | `git revert <commit>` — added test arms plus a two-line count guard | Low |
| #6244 | `git revert <commit>` — fixture and assertion text only; no production predicate | Low |
| #5060 | `git revert <commit>` — one checklist item in one spec file | Low |
| #4929 | `git revert <commit>` — marker adoption is revert-safe because the `PRODUCE` default means removing a marker restores producer semantics rather than orphaning a row | Low |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert the specific commits per the rollback protocol |
| **Full Restore** | Systemic failure | Revert the merge commit per the rollback protocol |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per the rollback protocol |

## Authorized ADRs

| Scope | Author | Allocation |
|---|---|---|
| **ADR citations bind at the claim, not at authorship** — an ADR number enters branch-authored prose only at the Stage-12 claim; before that an in-release record is cited as `{{ADR:<slug>}}`. The **filename keeps its literal number** (ADR-115 § Portability conflict (ii) is accepted, not re-argued). The stamp is the **last** step of the claim. The sweep's exemption population is **regions that record a number**, not lines that match the tool's own output. Where the classifier cannot decide, the sweep **names the site and does not rewrite it**. Branch-scoping is unchanged. | **#4995** — **amends** ADR-115; contests nothing it decided, and adds the citation-time clause ADR-115 explicitly did not evaluate | **ADR-170**, re-verified at Engineering Commit 0 by **two independent methods** against `git ls-tree origin/main` across BOTH `core/ADRs/` and `release/ADRs/` — the worktree checker PASSes on a number already taken on the mainline, so the mainline read is the authority. Method 1 (enumerate + parse): 171 paths → 169 records (the 2 non-matches are the two `README.md`), core 115 / release 54, **anchor 169 → next-free 170**, 0 duplicates, 0 gaps; sensitivity `ADR-115` present → True, specificity `ADR-170` present → False. Method 2 (governed oracle): `python3 release/tools/renumber-adr.py --next-free` → **170**. Both agree. **Provisional until the Stage-12 claim** — never hand-reserved. Two sibling milestones (`adr-corpus-status-integrity`, `hub-spoke-run-and-planning-discipline`) are concurrently in Stage-4 planning; an unmerged sibling claim is advisory, and whoever merges second renumbers. |

**Related records:** ADR-115 (amended) · ADR-092 (the precedent generalized from the version to the citation) · ADR-117 (projected index — the V2 treatment's authority) · ADR-118 (the durability carve-out that bounds the ADR-115 edit) · ADR-062 (issue bodies left as historical record).

**ADR-115's own edit, narrowed.** ADR-115 is `Accepted`, and ADR-118 § Decision (2) admits **durability-hygiene edits only**, with a **closed** forbidden list covering `## Decision`, alternatives-as-weighed, consequences, and non-Nygard status changes. The governed edit is therefore **one `## Related ADRs` bullet** pointing forward to ADR-170 — the same class as the link-repoint example ADR-118 names. Its stale *"six individually-verifiable steps"* sits in `## Decision` and is **not** correctable in place; ADR-170 restates the step set instead. That governance gap — a hygiene class for *"a count the record's own artifact has since falsified"* — is surfaced as an observation, not resolved here.

## Baseline Pin

`539c4440fc1457e8d42d2bbe11c7be663baf596f`

Every Engineering spoke branches from this SHA. It is the Stage-4 pin, the Stage-5 pin, and the Commit-0 pin; no re-baseline was required — `git rev-parse origin/main` at Commit 0 returns the identical value.

**Findings pinned here that a single later commit can invalidate silently**, per audit-baseline discipline, and which **must be re-read before Stage 9 relies on them**: the open-PR count (**0**) and the in-flight sibling-release population (**0**) — both are transiently-empty populations where a default-to-zero is not load-bearing on its own; the exemption-coverage census (**60 of 175** recorded-number lines protected, 34.3 %); the mainline ADR anchor (**169**); and the version claimed-set (max **v4.45**).

## Quota Budget

**Verdict:** WARN (per the quota-budget protocol, Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **5** (3 as executed — the `#4995 / #5080 / #6244` cluster was consolidated into one Solutioning design) · Stage 7: **5** · Stage 8: **5**
**Per-spoke cost estimate:** size-bucket ordinal band — #4995 `size:L` (moderate–high) · #6244 `size:M` (low–moderate) · #5060 `size:M` · #4929 `size:M` · #5080 `size:S` (lowest). Source: **heuristic**. No telemetry medians consumed — the per-bucket cutover requires n≥3 eligible comparables and no spoke-launch telemetry substrate was supplied.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota state was supplied at hub start. The conservative default applies; basis token `UNSTATED`.
**Estimated cumulative draw % (worst parallel batch):** **not computable** — the envelope basis is `UNSTATED`, and a percentage over an unknown denominator would be an invented number, not an estimate. The verdict is rendered from the band the protocol assigns to an unstated envelope rather than from a fabricated ratio.
**Routing:** **WARN → window-aware launch timing + quota-budgeting (split batch) recommended.** Concretely: split the 5-wide Stage-7 and Stage-8 batches into waves of ≤2, consistent with `W_max = 2` for an `UNSTATED` basis. Stage 6 is not a parallel stage and is P0-serial for the cluster regardless.
**Note:** Checkpoint B re-validates at **every** `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with **PROCEED / SERIALIZE / DEFER / REDUCE-scope** for a wave and the reduced **PROCEED / DEFER** form for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core` / `graphql` pools), read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

**The plan-time estimate is not the gate.** If the operator states a quota position, Checkpoint B supersedes this WARN on its own reading; this section surfaces capacity risk in the plan, it does not authorize or block a launch.

## Operational Deployment Manifest

Layer 2 file propagation targets for Stage 12/13:

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `core/skills/adr-helper/SKILL.md` | installed `adr-helper` skill copy | S-2 direct copy + `.skill` package rebuild via `core/deploy/tools/build-skill-packages.sh adr-helper`, package and its `.sha256` sidecar committed in the SAME PR | `diff` shows no differences; the `skill-package-freshness` CI gate is green |

### Schema Migrations

**N/A — enumerated over the classes reasoned over: data-schema changes, frontmatter-schema version bumps, event-log schema versions, and tracker-schema columns. None present in this release.** The `{{ADR:<slug>}}` citation token is a prose convention resolved by a tool mode, not a schema; it adds no field to any schema surface and no existing record requires migration. The 188 existing release plans carry literal numbers **by design** and are historical record — the convention is forward-only, and the `AMBIGUOUS` verdict is what protects them from a future sweep "fixing" them.

## Verification Evidence

### Stage 6 — #4995 (self-verification, at the branch head)

| Check | Invocation | Result |
|---|---|---|
| Exemption authority self-test | `python3 release/tools/renumber-adr.py --self-test` | **PASS.** The pre-existing double-move arm asserting the sweep exempts every hop is **unchanged and green**; 22 arms added beside it. |
| CI-enforced behavioural suite | `bash release/tools/tests/test_renumber_adr.sh` | **87 passed, 0 failed** — unchanged from the baseline count, so the widened exemption regressed nothing. |
| Seeded-failure discipline | 6 targeted mutants against the shipped source | **6 RED, 0 vacuous.** Reverting the shim to the old boolean; folding the third verdict into `CITE`; making the paragraph extent a blanket exemption; narrowing the canonical provenance detector; tightening the Deviation Log region row; and letting the stamp half-apply — each fails with named arms. |
| Single-authority probe (CIAC-1 limb 1) | `DRYRUN_CONSULTS` / `PREDICATE_DEFS` over the source | `DRYRUN_CONSULTS True` · `DRYRUN_STRIPS_REGION True` · `PREDICATE_DEFS 1` · `CLASSIFIER_DEFS 1`. **Control:** the pre-change tool returns `DRYRUN_CONSULTS False` at the pinned baseline. |
| Region-strip probe (CIAC-1 limb 2) | `dryrun/region-excluded` self-test arm | Raw **4** · rewrite-only **4** · region-stripped **2**. The middle column is the measurement that the rewrite call alone does not close the projected-region divergence. Sensitivity: prose outside the region still counts **2**. Specificity: an unfenced body is a no-op. |
| Citation-stamp gate limb | `python3 release/tools/renumber-adr.py --stamp --check` | **exit 0** — 0 residual tokens, 0 in link position, over **11** in-scope files. The denominator is non-zero, so the zero is a measurement rather than an empty scan. |
| ADR number space | `python3 release/tools/check-adr-numbers.py` | **PASS** — 170 ADRs, contiguous 001..170, no duplicates. |
| ADR durability lint | `check-adr-durability.py` over the new and edited records | `SCANNED 2` · `COUNT 0`. |
| Doc-link integrity | `check-doc-links.py` over all seven edited markdown surfaces | **0 rows.** Sensitivity arm on the same instrument: a seeded fixture with a missing target returned one `broken-cross-ref` row, so the zero is a measurement. |
| Skill-package freshness | `deploy.sh --check-package-freshness` | **55 rostered packages content-fresh.** `adr-helper`'s `.skill` and `.sha256` were rebuilt and committed in the same change as its `SKILL.md` edit. |
| Workflow parse | `yaml.safe_load` on the edited workflow | **OK.** `six-step` occurrences remaining: **0**; the replacement is present once; control arm counts 4 `ADR renumber` lines in the same file. |

### Stage 6 — #5080 (self-verification, at the branch head)

| Check | Invocation | Result |
|---|---|---|
| CI-enforced behavioural suite | `bash release/tools/tests/test_renumber_adr.sh` | **131 passed, 0 failed** (baseline **87**). ACT A14 contributes **44** arms, `A14a`–`A14i` plus a scope-membership precondition block. |
| Exemption authority self-test | `python3 release/tools/renumber-adr.py --self-test` | **PASS, exit 0.** The obligation-bearing double-move arm `provenance/sweep-exempts-every-hop` is **unchanged and green**; the five `dryrun/*` arms landed by #4995 are green and are **not duplicated** by this card. |
| Seeded-failure discipline | 6 targeted mutants against the shipped source, each restored byte-identical | **6 RED, 0 vacuous.** Dropping the exemption from the dry run → 5 RED (`A14a`/`A14b`/`A14c`); dropping the region strip → 1 RED (`A14i`); re-nesting the mechanism line under the `present` guard → 2 RED (`A14i`, `A14e`); dropping the disclosure line → 2 RED (`A14h`); making the renumber log overwrite instead of append → 4 RED (`A14a`, `A14f`); inflating `exempt` by one → 10 RED **including all three `A14e` limbs**, which is the arm that proves the first-move control is a control and not decoration. |
| Observed dry-run/apply values at hop 3 (`006 → 007`) | `--renumber 6 7` then `--renumber 6 7 --apply` on a record with two completed prior hops | Matched the Stage-5 derived table on every cell: `core/ADRs/README.md` **PRE 3 · would 1 · exempt 2 · REVIEW 0**; `release/ADRs/ADR-006-bravo.md` **PRE 3 · would 2 · exempt 1**; `design-note.md` and `plan-note.md` **PRE 2 · would 2 · exempt 0 · POST 0** each. The card's *"dry run says 2, apply says 0"* reproduces as the **two exempt tokens** on the curated index, and they are exactly the two classes it names — this record's own hop-2 entry and the seeded sibling release's claim history. |
| Post-apply token accounting | `cite_count` before and after, with the created tokens measured from the post-state | `POST(core) 3 = exempt 2 + 1` token the § Renumber-log append creates; `POST(record) 3 = exempt 1 + 2` tokens the provenance note creates. **The apply path creates `ADR-<old>` tokens on purpose** — that audit trail is the whole point of the exemption — so the parity is asserted as a partition of the tokens present at PRE, not as a naive `PRE − POST` difference. |
| Vacuous-pass guard | dry-run scope-membership arms, run **before** any "unchanged" claim | All four fixture files report a per-file dry-run line; `release/ADRs/README.md` is confirmed present in `origin/main...HEAD` by an independent `git diff --name-only` arm, so its **absence** from the count report is the region strip and not a file that fell out of scope. `_in_scope_files` silently drops non-UTF-8 files and this fixture seeds one. |
| Syntax | `ast.parse` on the tool; `bash -n` on the suite | **OK / OK.** |

### Stage 6 — #6244 (self-verification, at the branch head)

| Check | Invocation | Result |
|---|---|---|
| CI-enforced behavioural suite | `bash release/tools/tests/test_renumber_adr.sh` | **153 passed, 0 failed** (baseline **131**), RC 0. ACT 15 contributes **22** arms — two preconditions (`A15-P1` scope membership, `A15-P2` the move exits 0) plus `A15a`–`A15e`. Every arm passed on its first run; no arm was authored against an expectation that had to be revised after observing the tool, except the two counts recorded as DEV-18 and DEV-19, which were corrected **before** the run rather than after it. |
| Arm-namespace re-verification, run **before** authoring | enumeration of every first quoted argument to `assert_eq` / `assert_file` / `assert_nofile` / `ok` / `bad` in the suite | **141** real arm labels. ACT numbers **1 through 14 are all occupied**; `A15` count **0**, so the namespace was free. Sensitivity on the same instrument: `A13` → **15**, `A14` → **44** (non-zero, so the detector works). Specificity: `A16` → **0**, `A99` → **0**. Enumerating real labels rather than testing a name shape is the point — the shape test is what previously reported a false FREE on `A4`. |
| Exemption authority self-test | `python3 release/tools/renumber-adr.py --self-test` | **PASS, exit 0.** The obligation-bearing double-move arm `provenance/sweep-exempts-every-hop` is present and **unchanged** (OB-1). The three classifier arms the Stage-5 design listed as its step 5 — `exempt/devlog-row-is-ambiguous`, `exempt/devlog-section-closes-at-next-heading`, `exempt/devlog-heading-variants-are-sections` — had already landed with #4995 and were **verified, not re-authored** (DEV-17). |
| Observed classifier verdicts on the fixture plan | the tool's own `classify_lines` / `rewrite_citations` loaded from `release/tools/renumber-adr.py`, over the fixture plan body at `--renumber 4 6` | **PRE 5 · would 2 · REVIEW 3 · exempt 0.** The three Deviation-Log rows classify `AMBIGUOUS` (DEV-41 historical, DEV-43 straddling range, DEV-44 live); the citation **before** the section heading and the citation **after** the section's terminating heading both classify `CITE` and are swept. `exempt 0` is correct and is the discrimination result: this fixture carries no `RECORD_OPENERS` shape at all, so every spared token is spared by **position**, which is exactly what #6244 asks the sweep to do. |
| Two-hop behaviour (`004 → 006`, then `006 → 007`) | ACT 15, one commit per hop, with the mainline advancing between hops so each move is a genuine duplicate | Both hops exit **0**. At hop 1 the R3 REVIEW block names **3** sites in the fixture plan; at hop 2 it names exactly **1** — the row carrying the number that hop is moving. The three historical rows are inert at hop 2, so a hop-2 arm expecting the whole region would assert that the review block reports rows the sweep never looked at. |
| Vacuous-pass guard | `A15-P1`, run **before** any "unchanged" claim | The fixture plan reports exactly one per-file dry-run count line, so it is demonstrably in R3 scope. `_in_scope_files` drops non-UTF-8 files silently and this fixture seeds one via `author_B`; without this arm every "the row is unchanged" assertion below it would pass for the wrong reason. |
| Every zero carries a live control | per-arm sensitivity limbs on the same instrument | `A15a` / `A15e`: the same `grep` returns **non-zero** for the number each row really carries. `A15b`: the `plan_section` extract is non-empty and carries the swept number. `A15c`: the `python3` low>high detector returns **1** on a genuinely incoherent range and **0** on the post-state — a coherence probe whose control also returned zero would be broken. `A15d`: the zero-site control is a different **run** of the same emitter (ACT 3's apply, a worktree with no Deviation Log), not a re-read of this one. |
| Plan-cell ↔ arm-label agreement | every `grep -c '<target>'` in the five `#6244` Verification-Plan rows, resolved against the suite | **5 of 5** graded targets present — `A15a AC1 SILENT CASE` 2 · `A15b AC2 DISCRIMINATION` 2 · `CLOSE BOUNDARY` 1 · `A15c AC3 COHERENCE` 1 · `A15d AC4` 5. Every `ZZQQ-NOT-AN-ARM` specificity arm **0**. **0** stale `A14*` or `ACT 4` references remain in those rows, so no AC grades against an arm that does not exist. |
| Cascade update | `release/tools/tests/test_renumber_adr.sh:23` | `Assertions A1-A13` → `A1-A15`; the range was falsified first by A14 and again by ACT 15. The sibling cascade site `.github/workflows/repo-integrity.yml:610` already reads `seven-step move (R1..R7)` from the G-EX9 repair already on this branch, so it needed no edit (DEV-17). |
| Syntax | `bash -n` on the suite | **OK.** |
| Real-corpus non-touch | `git diff origin/main...HEAD -- release/releases/plans/` scoped to files other than this plan | **0.** ACT 15's fixture plan is synthetic and lives only inside the suite's `$(mktemp -d)`, so the File Change Matrix's `release/releases/plans/**/*_RELEASE_PLAN.md  NOT EDITED` non-scope row is respected. |

### CIAC-3 — the Stage-6 checklist answer, recorded

**Did this release add a record under `release/ADRs/`? YES** — `release/ADRs/ADR-170-adr-citations-bind-at-the-claim-not-at-authorship.md`.

Acted on in-branch: the projected index was regenerated with `python3 release/tools/generate-adr-index.py --write` (55 rows), and `--verify` reports **COUNT 0** — zero drift. The recorded answer matches the directory the ADR actually landed in, which is the second half of CIAC-3's method. Control confirming the answer is load-bearing rather than vacuous: `release/ADRs/README.md` carries the projected-region fence while `core/ADRs/README.md` does not, so a No answer would have had a real region to be right about.

This release is the **first exercise** of the checklist item another member of this milestone adds, and it is also the correction of the Stage-4 matrix row that had declared the index a read-only input.

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Deviation Log

| # | Deviation | Recorded at | Disposition |
|---|---|---|---|
| DEV-1 | The Stage-4 File Change Matrix declared `release/ADRs/README.md` as a read-only input while the same matrix declared an ADR `add` under `release/ADRs/`. | Engineering Commit 0 | **CORRECTED** — promoted to `edit` (AI-003). A release-module ADR add regenerates the projected index. |
| DEV-2 | The Stage-4 matrix omitted `release/tools/tests/test_renumber_adr.sh`, which is CI-enforced and hard-fails its job, and is where every behavioural arm for the cluster must land. | Engineering Commit 0 | **CORRECTED** — promoted to `edit` (AI-005). |
| DEV-3 | The Stage-4 matrix omitted `.github/workflows/repo-integrity.yml`, whose success message asserts a six-step move while the tool ships seven R-steps. The site sits structurally outside the cluster design's `*.md` cascade population. | Engineering Commit 0 | **CORRECTED** — promoted to `edit` (AI-009). |
| DEV-4 | The Stage-4 matrix carried a `<reservation-ledger-surface>  add  CONDITIONAL:D-MECHANISM` row whose condition resolved **false** when Stage 5 selected direction 1. | Engineering Commit 0 | **STRUCK**, not left conditional. A row left CONDITIONAL after its condition resolves is an authoring defect. |
| DEV-5 | The Stage-5 cluster design's `AMBIGUOUS_SECTIONS` heading row matched 64 of 69 heading-shaped lines; one miss (`## 11. Stage 5 Deviation Log`) is a genuine section heading defeated by its numeric prefix. | Engineering Commit 0 | **CORRECTED** — registry row loosened to tolerate a numeric or ordinal prefix, with a self-test arm pinning that heading form (AI-007 / R9). |
| DEV-6 | The Stage-5 cluster design argued the dry run calling `rewrite_citations` *is* the apply path minus the write. True for V1, **false for V2**: the R6 verify path strips the projector-owned region before checking and the dry-run block does not. | Engineering Commit 0 | **CORRECTED** — the projected-region strip is mirrored before counting (AI-008 / R10). |
| DEV-7 | The design specified the `--stamp` scope as `_in_scope_files(origin/main...HEAD)` — the same branch-diff scope the sweep uses. That scope includes the tool's own source, so literal `{{ADR:…}}` fixtures in `self_test()` made `--stamp --check` flag the tool itself: **10 residual tokens and 1 link-position refusal**, all of them test fixtures, which would have failed G-EX9 on every release that touches this tool. Found by running the gate limb live rather than by reading the design. | Stage 6 (#4995) | **CORRECTED WITHOUT NARROWING THE SPEC.** The declared branch-diff scope is kept intact and the fixture tokens are assembled at runtime instead of written as literals. Carving source files out of the scan was rejected: it would silently stop stamping a token in a test comment, which the originating card names as an affected artifact class. A reflexive self-test arm pins the property. Post-fix: **0 residual, 0 in link position, over 11 in-scope files**. |
| DEV-8 | The existing self-test arm `historical/exempt` asserted that an ordinary citation on the line *immediately after* a provenance-note head **is** swept — its stated purpose was a sensitivity control. Under the widened population that line is a hard-wrapped continuation of the note's paragraph and is correctly spared, so the arm's expectation moves from 1 rewrite to 0. | Stage 6 (#4995) | **EXPECTATION UPDATED, GUARANTEE PRESERVED.** This is a widening, not a narrowing: the arm's own fixture was shaped like the defect the card exists to fix, so its control was asserting the bug. The sensitivity guarantee moved to `exempt/broken-paragraph-reverts-to-cite`, where a blank line ends the paragraph and the following citation must still move, plus `exempt/block-opener-ends-the-run` for the table-row case. The obligation-bearing double-move arm is **untouched**. |
| DEV-9 | The design directed the `gate-criteria-spec.md` G-EX9 edit to be **line-disjoint** from a sibling release's edit to the same row. A markdown table row is a single line, so two edits to it cannot be textually disjoint. | Stage 6 (#4995) | **PARTIALLY SATISFIED, AND FLAGGED RATHER THAN CLAIMED.** The *semantic* mitigation is fully discharged: the provenance symbol is preserved by name with its pattern byte-unchanged, and the Method column's provenance predicate — the sibling's actual target — is not touched. The substantive additions were placed in a note block on their **own lines** below the Self-Repair table, so the row itself carries only a step-count correction, a pointer, and one appended conjunct. The residual is a one-line textual conflict that whichever merges second resolves by re-reading the row, which is the merge-order constraint already recorded on both cards. |
| DEV-10 | The Stage-5 design's implementation order for #5080 listed five steps, of which four had **already landed** in #4995's Engineering commits before this spoke started: the projected-region guard and the three-column report (`8a9994fb`), the five `dryrun/*` self-test arms (`8a9994fb`), and the `repo-integrity.yml` step-count string (`cd969378`). | Stage 6 (#5080) | **SCOPE NARROWED, NOTHING RE-AUTHORED.** The landed arms were read and verified to grade the four properties the design named (`dryrun/parity-*` ×2, `region-excluded`, `region-sensitivity`, `region-specificity`) rather than re-authored beside them — the design's own "beside #4995's, never replacing" phrasing anticipated coexistence, but re-authoring an arm that already exists is duplicate governance debt. This card's remaining delivery is ACT A14 plus the DEV-11 correction. |
| DEV-11 | The design's dry-run output contract specifies that a projected surface is *"reported by mechanism, not by count"* — an **additional** line naming the projector. As implemented the line sat **inside** the per-file `if not present: continue` guard, so it went silent in exactly the case it exists to disclose: a projected surface whose only `ADR-<old>` tokens are region rows strips to zero and skips the guard, leaving a reader told nothing about a file that visibly carries the old number on disk. | Stage 6 (#5080) | **CORRECTED.** Hoisted above the guard so it emits for every in-scope projected surface. This is the same doctrine `_log_review_block` already enforces for ambiguous sites — a step silent when it finds nothing is indistinguishable from a step that did not run — and it is what AC-2 (*name the exemption rather than silently over-predicting*) requires on the projected surface. Three lines moved; no predicate, count or exit code changed. `A14i` and the `A14e` mechanism limb grade it; mutant M3 re-nests it and both go RED. |
| DEV-12 | The design's parity identity `PRE − POST == would_rewrite(<file>)` is **arithmetically false against correct behaviour**, and its derived value table omitted the reason. R4's § Renumber-log append and R5's provenance note each write a *new* `ADR-<old>` token — that audit trail is the whole point of the exemption — so on the curated index `PRE 3` and `POST 3` while `would` is 1. | Stage 6 (#5080) | **REFORMULATED, GUARANTEE STRENGTHENED — not a number edited to fit.** The arms assert (a) a **partition** of the tokens present at PRE (`would + exempt + review == PRE`), and (b) a **survivor identity** once the created tokens are subtracted back out (`POST − appended == exempt`), with `appended` **measured from the post-state** rather than assumed. Every other derived cell in the Stage-5 table reproduced exactly. Stating the naive difference as the identity would have encoded the apply path's own audit record as a defect. |
| DEV-13 | The design's `A14i` assumed the projected surface would emit a per-file count line to assert against. It emits none: the region-stripped body carries **zero** tokens, so the `present` guard correctly skips the count report entirely. | Stage 6 (#5080) | **SATISFIED IN A STRONGER FORM.** The V2 limb is asserted as an **absence** with two arms that make the zero a measurement rather than an empty scan: sensitivity — the file demonstrably carries `ADR-006` on disk, so there *is* something to over-predict; and a discriminator — an independent `git diff --name-only origin/main...HEAD` arm proves the file is in the branch diff, so its absence from the report is the region strip and **not** a file that fell out of scope. Mutant M2 removes the strip and the arm goes RED. |
| DEV-14 | `R1 PROCEED` renders `old_path` / `new_path`, which are absolute (`root / …`), so the rename it discloses is printed as an absolute filesystem path rather than a repo-relative one. | Stage 6 (#5080) | **ARM MATCHED TO THE TOOL, TOOL LEFT ALONE.** The `A14h` sensitivity arm asserts the basenames, which is the shape the tool really emits. Recorded rather than fixed: the disclosure is correct and complete, and changing an operator-facing log line is outside this card's scope. Surfaced as an observation. |
| DEV-15 | The three #5080 Verification-Plan method cells describe shell-suite ACTs rather than executable one-liners, so the plan-verification executor grades them **SKIP** (`tool-invocation-outside-executor-allowlist` ×2, `no-executable-command-in-method`), while the sibling #6244 rows on the *same* file are executable (`grep -c '<arm label>' release/tools/tests/test_renumber_adr.sh`). | Stage 6 (#5080) | **FLAGGED, NOT REWRITTEN.** The arms' real verdict comes from the CI-gated suite (`repo-integrity.yml:587`, hard-failing at `:598-608`), so SKIP is not an unverified AC — but the asymmetry is a genuine authoring gap: an arm-presence one-liner is available for all three rows and would make them gradeable by the same executor that grades their siblings. Left for the hub rather than edited in place: rewriting a shared plan cell to satisfy the executor, mid-serialization and without the hub's call, would be exactly the silent-rewrite this deviation exists to avoid. |
| DEV-16 | The Stage-5 design names #6244's arms `A14a`–`A14g`. That namespace was **already occupied** when this spoke started: #5080's ACT `A14` landed at `4f3f2765` with 44 arms, `A14a`–`A14i`. A prior hub determination had reassigned the act to `A4`, which is also occupied — ACT 1 carries two bare-named `A4` provenance arms that a suffix-requiring probe cannot see. | Stage 6 (#6244) | **AUTHORED AS ACT 15**, per the hub's superseding determination. The namespace was re-verified free **before** authoring, by enumerating the **141** real arm labels (every first quoted argument to `assert_eq` / `assert_file` / `assert_nofile` / `ok` / `bad`) rather than by testing a name shape: ACT numbers **1 through 14 are all occupied** and `A15` returned **0**, against a same-instrument sensitivity control of `A13` → 15 and `A14` → 44. The three plan AC method cells naming `A14a` / `A14b` / `A14d` were reconciled to their `A15` labels. **Label-only — no test semantics moved**, and the agreement was re-measured after the edit: 5 of 5 graded targets resolve, 0 stale `A14*` or `ACT 4` references remain in the `#6244` rows. |
| DEV-17 | Two of the Stage-5 design's six implementation steps for #6244 had **already landed** on the branch before this spoke started. Step 5 (the three `self_test()` classifier arms) landed with #4995 at `8a9994fb` — `exempt/devlog-row-is-ambiguous`, `exempt/devlog-section-closes-at-next-heading`, `exempt/devlog-heading-variants-are-sections` are all present and green. The second half of step 6 (`repo-integrity.yml:610`'s stale "six-step" string) landed with the G-EX9 repair; the line already reads `seven-step move (R1..R7)`. | Stage 6 (#6244) | **SCOPE NARROWED, NOTHING RE-AUTHORED** — the same disposition as DEV-10. The landed arms were read and verified to grade the three properties the design named, rather than authored a second time beside themselves. Only the first half of step 6 remained: `test_renumber_adr.sh:23` still read `Assertions A1-A13`, a range A14 had already falsified and ACT 15 falsifies again; updated to `A1-A15`. |
| DEV-18 | The design's scope-membership arm asserts `grep -c 'fixture-milestone_RELEASE_PLAN.md'` on the dry-run output **equals 1**. That is arithmetically false against the real output shape: the `R3 REVIEW:` block names the same path **once per site**, so at hop 1 the basename appears on **4** lines — one per-file count line plus three site lines. | Stage 6 (#6244) | **REFORMULATED ONTO THE RIGHT DENOMINATOR, before the run rather than after it.** The arm now uses `dr_lines`, which keys on the per-file count line's `" in <path>  "` substring — the same instrument #5080's `A14` preconditions already use for this property. A basename count would have conflated "the file is in R3 scope" with "how many of its rows were named", so the arm would have been right about the property and wrong about what it counted. |
| DEV-19 | The design's AC-4 arm asserts the `R3 REVIEW:` block names the fixture plan **once**. The emitter writes one indented line **per ambiguous site**, and this fixture seeds three token-bearing rows inside the region, so the observed value at hop 1 is **3**. | Stage 6 (#6244) | **ASSERTED AT THE OBSERVED VALUE, WITH THE DENOMINATOR STATED IN THE LABEL** — the same class as DEV-18 and the same discipline as DEV-12: a count that disagrees with correct behaviour is reported, never edited to fit. The arm reads "one R3 REVIEW line per site". A companion hop-2 arm pins the complementary property at **1**: the review list is keyed on the number the hop is *moving*, so the three historical rows are correctly inert at hop 2 and an arm expecting the whole region there would assert that the block reports rows the sweep never looked at. |
| DEV-20 | The design places the act "after `A9` (`:374`), before `A7` (`:376`)" — a location chosen before #5080's ACT `A14` existed. `A14` introduced `dr_lines`, the reader for the dry-run per-file count line, and declared it act-local. | Stage 6 (#6244) | **PLACED AT END-OF-FILE, AFTER `A14`, AND THE LOCALITY COMMENT RECONCILED.** ACT 15 consumes `dr_lines` rather than duplicating it — a second copy of an output reader is the dry-run/apply divergence class in miniature, which is the defect this milestone exists to close. `A14`'s "local to this act on purpose" comment is amended to say the reader is shared by the two acts that parse the dry-run report; **no `A14` arm was moved, renamed or changed**. Acts are hermetic (own origin, own worktrees) so ordering carries no semantics, and `A14e` remains last within its own act. |
| DEV-21 | #6244's AC-3 method cell carried no executable one-liner, and the plan executor graded it **FAIL `command-exit-1`** rather than SKIP: `extract_command` found no allowlisted verb until the bare `` `grep` `` the prose mentions as an *instrument caveat*, ran it with no pattern, and read the resulting exit 1 as a failed assertion. The hub's reconciliation authorization was **label-only** over the three cells naming `A14a` / `A14b` / `A14d`, while its success criterion named **four** rows including AC-3. | Stage 6 (#6244) | **GAP CLOSED AND FLAGGED RATHER THAN ABSORBED.** AC-3 was given an arm-presence one-liner in the same shape as its three siblings (`grep -c 'A15c AC3 COHERENCE' …` ≥1, with the `ZZQQ-NOT-AN-ARM` specificity arm), and the descriptive method is retained after it. **No test semantics moved** — the arms it names already exist and are green — and the change corrects a *mis-grade*, not a real failure. Recorded because it exceeds the stated label-only scope. **AC-5 was deliberately NOT converted:** the same one-liner is available, but AC-5 grades an honest `no-executable-command-in-method` **SKIP**, it is not in the hub's four-FAIL success set, and its authoritative verdict is the CI-gated suite — the DEV-15 disposition, applied consistently. Only its stale `ACT 4` pointer was reconciled to `ACT 15`. |

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time. Operator-facing, pre-merge, ~60 lines. Distinct from the user-facing release note authored at Stage 13.)

## Change Log

| Date | Change | By |
|---|---|---|
| 2026-09-01 | Engineering Commit 0 — plan file authored on `release/adr-corpus-integrity` from the Stage-4 comment, carrying the Commit-0 Survival Set. Version re-verify **PROCEED** (anchor v4.45, next-free v4.46, free). ADR-170 re-verify **FREE** (anchor 169, two independent methods). Three File-Change-Matrix corrections applied (DEV-1/2/3); the direction-2 conditional row struck (DEV-4). | Stage-6 spoke (#6507) |
| 2026-09-01 | Stage 6 — #5080. ACT `A14` added to `release/tools/tests/test_renumber_adr.sh`: a three-hop `004 → 005 → 006 → 007` chain with the mainline advancing between hops, one hand-seeded sibling renumber-log entry, and 44 arms (`A14a`–`A14i` plus a scope-membership precondition block). Suite **131 passed, 0 failed** (baseline 87); `--self-test` green with `provenance/sweep-exempts-every-hop` unchanged. The dry-run projected-surface mechanism line hoisted above the per-file `present` guard (DEV-11). Six deviations recorded (DEV-10…DEV-15); six seeded mutants **6 RED, 0 vacuous**. | Stage-6 spoke (#6516) |
| 2026-09-02 | Stage 6 — #6244. **ACT 15** added to `release/tools/tests/test_renumber_adr.sh`: a two-hop `004 → 006 → 007` chain over its own origin, seeded so the anchor is 5 and the tool targets 006 — the gap that makes the straddling-range arm constructible at all. A synthetic release plan carries five addressable sites (a single-number historical row, a straddling range, a live citation inside the section, one before the section heading, and one after its terminating heading), and 22 arms grade them: `A15-P1`/`A15-P2` preconditions plus `A15a`–`A15e`. Suite **153 passed, 0 failed** (baseline 131); `--self-test` green with `provenance/sweep-exempts-every-hop` unchanged. `test_renumber_adr.sh:23` cascade-updated `A1-A13` → `A1-A15`. The five `#6244` Verification-Plan method cells reconciled from the `A14*` labels to the `A15*` labels actually authored, and AC-3 given an arm-presence one-liner (DEV-21). Six deviations recorded (DEV-16…DEV-21). | Stage-6 spoke (#6524) |
