---
title: Release Plan — governance-hardening (one authoritative release record, three projections, and the governance surfaces that depend on it)
type: release-plan
plan_type: release
status: ACTIVE
release: "{{RELEASE_VERSION}}"
milestone: 290-governance-hardening
release_class: routine
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `governance-hardening`

**Milestone:** `governance-hardening` (#290) · 10 members / 66 pts · **run 2**
**Version identity:** **slug-primary per ADR-092.** The branch is `release/governance-hardening`; every version reference in this plan is the `{{RELEASE_VERSION}}` token. The number binds at the **Stage-12 atomic claim**, at which point this file is renamed to `<version>_RELEASE_PLAN.md`. **No version is hardcoded anywhere in this release.**
**Topology:** D-C SINGLE — one release branch, one PR, one merge. This plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (operator-ratified). Stage-6 slices route one at a time in dependency order on the single branch. Force-push — including `--force-with-lease` — is prohibited on the shared branch under any multi-chip activity.
**Release class:** `routine` · **Stage-9 depth: Deep.**

> **Provenance.** This file transcribes the **Stage-4 Release Planning re-plan** posted on hub sub-task #4457, reconciled to the approved **Stage-5 Solutioning** design on #4467 (the design, two independent adversarial reviews, one Blocker-revision spoke, four rounds of acceptance-criteria authoring, and a bounded confirmation returning CLEAR TO EXIT). Where a Stage-5 finding superseded a Stage-4 assumption, the transcribed sections carry the **Stage-5** position and the § Deviation Log records the delta. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke (#4470).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` (binds at Stage-12 atomic claim; slug-primary per ADR-092) |
| **Date Created** | 2026-08-02 (Sunday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-hardening` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `governance-hardening` (#290) |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing.*

**Outcome.** The platform's release ledgers stop being four independent copies of one fact. `RELEASE_LOG.md` remains the authoritative **event** record and the release note remains the authoritative **narrative** record; `RELEASE_INDEX.md`, `RELEASE_DIGEST.md` and root `CHANGELOG.md` become **projections** emitted by a single tool that cannot read a clock, cannot read operator config, and cannot rewrite history. Around that root, nine further cards harden the governance surfaces that depend on the release corpus: retention and archival, the records-retention terminal decision, the overloaded `domain` token, the template-family taxonomy and registry, external-target knowledge placement, the self-improving-loop codification, and the intake gates' assumption that a human does the work.

**Issues resolved (10).** #4455 (root — one projector, three typed sources) · #3715 (bound the one surviving authoritative ledger) · #3387 (retention-purge terminal decision, rendered against the post-normalization taxonomy) · #3825 (`domain` token disambiguation registry) · #3196 ⊕ #4454 (merged work-package — the missing `template_family` families) · #3290 (template-registry hygiene) · #3413 (external-target knowledge axis) · #3556 (self-improving loop + backlog-hygiene codification; encode-then-evict) · #3816 (agent-led execution in intake gates).

**Key decisions.** The card's literal ask — *"make `RELEASE_LOG.md` the single authoritative record and generate the other three from it"* — is **rejected on measured grounds** and replaced with **two file sources plus two run-scoped inputs, one projector, per-field provenance**. The LOG carries neither a `# ` headline nor a `summary:`, so forcing the narrative onto it would import ~160 headlines and ~156 summaries into the exact file #3715 exists to bound. The projector emits **entries to stdout**, never files, because ~63 % of DIGEST headlines and ~60 % of CHANGELOG blocks carry legitimate post-emission operator edits that a whole-file regenerate would destroy.

**Reversibility.** **MODERATE / Confidence HIGH** overall. `git revert -m 1` of the release PR restores every file's bytes. It does **not** restore *provenance*: a reverted repo's next close-out writes by the old four-writer path. The mitigation is that **no history is regenerated** — the revert surface is one LOG cell plus tooling. One member (#3556) carries an **IRREVERSIBLE** action (memory eviction) executed as the release's last step, after the corpus write is on `main`.

**Downstream impact.** No runtime or skill behaviour changes for end users. Every historical INDEX row, DIGEST entry and CHANGELOG block is byte-identical at merge except a single `v3.69.1` `Release PR` reconciliation made **in the LOG**. Check 23 stays **warn-mode**; its flip to enforce is a staged post-merge decision on the check's own ≥3-day zero-false-positive condition, not something this release asserts.

`RELEASE_LOG.md` goes from **783,667 B to 148,558 B** — an 81 % reduction, 51,442 B inside its new 200 KB budget — and becomes readable end-to-end again rather than only grep-addressable. **Nothing is deleted.** The 147 relocated per-release narratives move to four archive segments *in the same directory*, so a recursive grep finds them exactly where it always did; every heading stays in the LOG with a pointer, so every link into it still resolves. Anyone who reads a release ledger sees a shorter file and one extra line per historical release saying where its detail went. The one tool that reads that detail — the FinOps velocity join — was changed in the same commit to read the segments too, and its basis is measurably unchanged. A new warn-mode gate reports the file's size on every `deploy.sh --check` run and says when the next archival chore is due.

The question of whether the platform should ever *delete* a generated artifact is now answered, in writing, for the first time. It was asked once before and settled without a record, which is why it came back. The answer is **no — archive is the permanent terminal**, and the reasoning is deliberately not "we never delete", because that is not true: the platform already purges in three other places. It is that the rule could not be written down. The field a retention clock would read is stamped on **zero** files, so the set of things eligible for deletion is empty; no retention value anywhere in the corpus has ever authorized destruction, so the clock itself would be invented; and the whole population in question is about **1 MiB against a 1.45 GiB workspace**, with nothing added to it in three months. Four checkable conditions are written down alongside the decision, so re-opening it later is a defined step rather than a fresh argument. Separately, the three projected ledgers get an explicit answer about their own size: they **do** owe something, but not a cleanup. Their records classification — shipped earlier in this same release — closes both ways a file can get smaller, because they hold content that exists nowhere else and a regenerate would silently destroy it. So their size is managed by **how they are read**, not by removing anything from them, and any future proposal to shrink them is a governance change rather than a tidy-up. **Nothing is deleted by this release.**

The word `domain` turned out to mean **six different things** in this corpus, and nothing said which was which. It classifies the kind of deliverable a release produces; where a project artifact came from; what content area a file is filed under; a kind of acceptance criterion, where it is an adjective and not a field at all; what canon family a template belongs to; and what subject a platform document is about. Two of the six are even called the same thing — *"three-domain classification"* — at their own definition files, with **no overlapping values**. There is now one page that lists all six, says which file owns each, and shows how to tell them apart, and each of those files carries one line pointing at it. **Nothing is renamed** — that was decided some time ago and stands; the fix is an index, not a migration, and every one of the 44 existing declarations is untouched.

The sixth meaning was found only because the list was rebuilt from a fresh sweep rather than copied from the ticket. Four earlier surveys of this same problem had missed it.

Underneath that, a real defect: **seven templates could not be given the provenance header every template is supposed to carry, and nobody owned fixing it.** The reason is that those seven already have a `domain` line — but it belongs to the *artifact they produce*, not to the template itself. A markdown file has one frontmatter block, and in these seven it is already spoken for. Adding the template's own header would have put two `domain` lines in one block, and YAML resolves that by **silently keeping the last one and discarding the first, with no error**. Two other pieces of work in this release were routing these seven templates here expecting the index to unblock them; an index cannot, and the first well-meaning bulk edit would have quietly stripped the provenance from every tracker and project page the platform creates. The decision is now written down: those seven are a named class, they are **not** exempt, and their header goes in a companion file beside the template — the same arrangement the platform already uses for spreadsheet templates, for the same reason. This release decides it and records why; it deliberately does not do the move, so the two dependent pieces of work now build against an answer instead of an assumption.

**Cross-references.** Stage-4 re-plan #4457 · Stage-5 design + reviews #4467 · Stage-6 sub-task #4470 · milestone #290. Governing standards: `core/standards/duplicate-source-discipline.md` § 1 (register-or-remove), `core/standards/date-variable-convention.md` § Emission-Time Anchors, `core/standards/bypass-mode-readiness.md` § Shakedown.

---

## Scope

### Summary

Ten members. The release's **capability outcome**: *a fact about a release is written once, by one writer, from a declared source — and every surface that restates it is a projection whose provenance is declared, asserted at emission, and gated at merge.*

The bundle is a **164 % size breach** (66 pts against a 25-pt band), operator-directed as a single bundle. Its operational consequences are carried in the Risk Register (R-6), not re-litigated here.

### Members

| # | Issue | Type | Size | Surface |
|---|-------|------|------|---------|
| 1 | **#4455** collapse four ledger writers into one projection | story | XL·16 | `core/deploy/tools/generate_release_index.py`, `core/deploy/tools/lint_release_corpus.py`, `core/deploy/deploy.sh`, `release/tools/automated-closeout.sh`, `release/references/standards/release-corpus-schema.md`, `release/references/pipeline/stage-13-close.md`, `core/governance/RECORDS_POLICY.md`, the four ledgers, one new ADR |
| 2 | **#3715** bound the release-corpus append-only logs | story | L·8 | `release/releases/RELEASE_LOG.md`, archive segments, `release/tools/sweep-release-corpus.py` (new), `RECORDS_POLICY.md`, `RECORDS_ARCHIVE_LOG.md`, `estimate-usage.sh`, `release-corpus-schema.md` |
| 3 | **#3387** governed retention-purge terminal decision | task | M·4 | `core/governance/RECORDS_POLICY.md` (+ conditional BUILD-branch surfaces) |
| 4 | **#3825** disambiguate the overloaded `domain` token | task | M·4 | `core/specs/domain-token-registry.md` (new) + 8 pointer surfaces |
| 5 | **#3196 ⊕ #4454** missing `template_family` families (merged work-package) | task | S·2 + L·8 | `core/standards/template-taxonomy.md`, `core/standards/template-storage.md`, `operations/templates/README.md`, the 12 templates |
| 6 | **#3290** template-registry hygiene drift (D1/D2/D3/D4) | task | L·8 | `template-protocol.md`, `operational-artifact-template-standard.md`, `template-taxonomy.md`, `operations/templates/README.md`, 26-file sweep, 3 `.skill` rebuilds |
| 7 | **#3413** external-target knowledge axis | — | L·8 | `core/disciplines/memory-architecture.md`, `core/disciplines/knowledge-architecture.md`, one new ADR |
| 8 | **#3556** codify the self-improving loop + backlog-hygiene guardrails | task | M·4 | `core/disciplines/architecture-overview.md` (+ conditional `operating-model.md`); memory eviction post-merge |
| 9 | **#3816** agent-led execution in intake gates | task | M·4 | `gate-checklists.md`, `gate-definitions.md`, `intake-style-guide.md`, `packages/delivery-engine.skill` rebuild |

---

## Dependency Graph

```
#4455 ──► #3715          HARD — archiving a generated view is work the normalization unwinds
#4455 ──► #3387          HARD (added at re-plan) — the retention question dissolves for three of four ledgers
#3715 ──► #3387          read-ordering, retained but no longer the binding edge
#3825 ──► #3290 (D3)     registry must exist before the D3 sweep populates domain: declarations
#3196 ──► #3290          shared registry row in operations/templates/README.md
#3196/#3290 ──► #4454    #4454 extends the taxonomy surface they settle
#3413 ──► #3556          encode-then-evict; #3556's eviction is IRREVERSIBLE and gated on merge-to-main
```

**Broken edge, recorded:** `#3825 → (7 `domain: managed` templates)` **does not hold** — a disambiguation registry indexes concepts; it does not resolve a duplicate-YAML-key collision, and #3825's own AC-4 forbids the rename that would. Either #3825 closes it explicitly or #3290's D3 acceptance criterion is authored at **19 of 26**, not 26 (R-2).

**#3816 has zero edges in either direction.**

---

## Implementation Sequence

**P0 fully-serial. One branch, one PR, one merge gate.** Commit order; a card's rework cost grows with the number of commits behind it, so the architectural root goes first.

| # | Card | Why here |
|---|---|---|
| 1 | **#4455** | Architectural root. Everything downstream reads a corpus it reshapes. |
| 2 | **#3715** | Hard edge from #4455. Archives the **one** ledger that survives as an authoritative record. |
| 3 | **#3387** | Hard edge from #4455. Renders the terminal against the settled records taxonomy. |
| 4 | **#3825** | Vocabulary layer. Must close the 7-template key-collision gap or hand it an owner. |
| 5 | **#3196 ⊕ #4454** | Merged work-package — one edit region on `template-taxonomy.md` § 6. |
| 6 | **#3290** | D1 / D2 / D4 + the D3 sweep (19 of 26 with #4454 landed; 26 only if step 4 closes the collision). |
| 7 | **#3413** | Discipline layer. ADR number allocated at commit time, never hardcoded. |
| 8 | **#3556** | Corpus write lands here; **eviction is a distinct post-merge step**. |
| 9 | **#3816** | Independent tail. Zero contention; a late change here cannot force upstream rework. |

---

## Stage Applicability Matrix

| Card | Stage 5 Solutioning | Stage 6 Eng | Stage 7 Dev Testing | Stage 8 Acceptance |
|---|---|---|---|---|
| #4455 | **APPLIED — NEW spec** (#4467) | APPLY | **APPLY** | APPLY |
| #3715 | **APPLIED — RE-SPEC** (#4468) | APPLY | **APPLY** | APPLY |
| #3387 | REUSE #4393 + revalidate | APPLY | N/A (decision-only) | APPLY |
| #3825 | REUSE #4381 + key-collision decision | APPLY | N/A (doc-only) | APPLY |
| #3196 | REUSE #4405 | APPLY *(merged pkg)* | N/A | APPLY |
| #4454 | APPLY — NEW spec | APPLY *(merged pkg)* | N/A (taxonomy rows only) | APPLY |
| #3290 | REUSE #4409 + re-baseline D3 | APPLY | **APPLY** (3 `.skill` rebuilds + 26-file sweep) | APPLY |
| #3413 | REUSE #4397 + `repo_host` read-path correction | APPLY | N/A | APPLY |
| #3556 | REUSE #4401 | APPLY | N/A (doc-only) | APPLY |
| #3816 | REUSE #4385 | APPLY | **APPLY** (`delivery-engine.skill` rebuild) | APPLY |

---

## Contention Map

| Shared surface | Cards | Degree | Resolution |
|---|---|---|---|
| `core/standards/template-taxonomy.md` | #3825 × #3196 × #3290 × #4454 | FOUR-way | Steps 4 → 5 → 6; the #3196 ⊕ #4454 merge reduces it to three writers |
| `core/governance/RECORDS_POLICY.md` | #4455 × #3715 × #3387 | THREE-way | Steps 1 → 2 → 3. **#4455 writes the derived-surface rows first** (INT-4) |
| the four release-corpus ledgers | #4455 × #3715 | 2-way | Steps 1 → 2 |
| `release/tools/automated-closeout.sh` | #4455 × #3715 | 2-way | Step 1 replaces three phases' content synthesis; step 2 touches only the LOG path |
| `core/deploy/deploy.sh` | #4455 × #3715 | 2-way | Step 1's edit is **Check 23's remediation string only** (the limb-narrowing edit was withdrawn at Stage 5); step 2 adds its own warn probe |
| `release/references/standards/release-corpus-schema.md` | #4455 × #3715 | 2-way | Steps 1 → 2 |
| `core/standards/template-protocol.md` | #3825 × #3290 | 2-way | Steps 4 → 6 |
| `operations/templates/README.md` | #3196 × #3290 | 2-way | Steps 5 → 6 — the `qa-acceptance-report-template.md` row is **shared work, authored once** |
| `operations/templates/*.md` (26 files) | #3290 × #4454 × #3825 | 3-way | Steps 4 → 5 → 6 |
| `core/schemas/gate-criteria-spec.md` | #3825 × #3816 | 2-way, low | #3816's arm is a confirm-unaffected read, not an edit |

---

## Risk Register

| ID | Risk | Owner | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|
| **R-1** | The v4.05 Stage-13 close-out was in flight at plan time and writes all four ledgers. | #4455, #3715 | MODERATE / HIGH | **CLEARED.** PR #4466 (v4.05 Stage-13) merged; the branch was recreated from `origin/main` at that merge. Re-check the LOG state histogram at branch time rather than trusting a pinned reading (audit-baseline discipline). |
| **R-2** | The 7 `domain: managed` templates are **not** unblocked by #3825. | #3825, #3290, #4454 | CHEAP / HIGH | Close it at step 4, or author D3's AC at 19 and name the residual owner. Not both silent. |
| **R-3** | Hand-authored `Theme` cells are not derivable from the LOG. **Downgraded EXPENSIVE → MODERATE at Stage 5**: the projector already round-trips every non-placeholder Theme byte-identically (structural per-field probe; control returns a mismatch on a corrupted cell). | #4455 | MODERATE / HIGH | The Theme round-trip gains the integrity limb it has never had (AC-3). |
| **R-4** | Check 47 and most of Check 32 do **not** retire. **Confirmed and widened at Stage 5**: the census is **1 retires · 7 survive**, and the card's own census omits Check 48. | #4455 | CHEAP / HIGH | Per-contract verdict table recorded in the ADR (AC-6). The Stage-5 limb-narrowing proposal was **withdrawn in full**. |
| **R-5** | #3556's memory eviction is IRREVERSIBLE and not git-revertable. | #3556 | **IRREVERSIBLE** / HIGH | Eviction is the release's last action, after the corpus write is on `main`. |
| **R-6** | 164 % size breach with a four-way and a three-way contention edge, one merge gate. | bundle | MODERATE / HIGH | Deep Stage-9 depth; root at commit 1; zero-edge card at the tail. |
| **R-7** | Quota exhaustion — demonstrated, not hypothesised. Four spokes in the prior run died holding finished work. | bundle | MODERATE / MEDIUM | Split-batch mandatory at the Stage-8 wave; **push and post incrementally** at every spoke. |
| **R-8** | A `.skill` package rebuild is missed and Check 7 fires at merge. | #3816, #3290 | CHEAP / HIGH | `core/deploy/tools/build-skill-packages.sh <skill>` in the same commit as the source edit. |
| **R-9** | ADR-number collision — next-free is **global** across `core/ADRs/` and `release/ADRs/` plus anything in flight. | #4455, #3413 | CHEAP / HIGH | Allocate at commit time via `release/tools/check-adr-numbers.py`; never hardcode. |
| **R-10** | **Probe-shape defect recurrence.** Fourteen instances across this release, committed by every party including the hub. | all | CHEAP / HIGH | Every count is re-run at the working baseline and **paired with a control shaped like the probe**. Units stated. Populations verified. |
| **R-11** | #3715's re-scope is a genuine spec change, not an edit — its shipped design assumed four ledgers; the surviving design is one. | #3715 | CHEAP / HIGH | RE-SPEC, not REUSE. |
| **R-12** | **A whole-file regenerate of DIGEST or CHANGELOG is the one irreversible-shaped mistake available in this release** — it destroys ~100 entries of hand-authored prose recoverable only from git. A projector that acquires a clock is the second. | #4455 | MODERATE / HIGH | Both are guarded **by construction**, not by instruction: the emitters are entry-scoped and write to stdout; the projector's anchors are required CLI arguments and its clock-freedom is asserted by a self-test that CI executes. |

---

## Cross-Issue Acceptance Criteria

Release-scoped predicates spanning ≥ 2 issues. Graded at Stage 9 Phase A3.6 / QC3.5 on the merged PR.

- [ ] **CIAC-1 (#4455 × #3715 — the ledger set):** exactly one of the four release-corpus ledgers carries an archive-segment family; the three derived surfaces carry none. *Method:* `git ls-files 'release/releases/*_ARCHIVE-*.md' 'CHANGELOG_ARCHIVE-*.md' | sed 's/_ARCHIVE-.*//' | sort -u` returns exactly `release/releases/RELEASE_LOG`. *Baseline polarity:* 0 stems today. *Control:* the same transform over `git ls-tree -r --name-only f3cfdebf` returns 4 stems.
- [ ] **CIAC-2 (#3196 × #3290 × #4454 — the template registry):** every template in `operations/templates/` has exactly one registry row, and every `template_family` value binds to a family that exists in the taxonomy.
- [ ] **CIAC-3 (#4455 × #3715 × #3387 — `RECORDS_POLICY.md`):** all four release-corpus ledger paths are classified in the disposition table and no two cards state a contradictory disposition for the same path. *Method:* `grep -oE 'RELEASE_LOG\.md|RELEASE_INDEX\.md|RELEASE_DIGEST\.md|CHANGELOG\.md' core/governance/RECORDS_POLICY.md | sort -u | wc -l` returns **4**. *Baseline polarity:* **1** (only `RELEASE_LOG.md` is named). *Control:* the file's table-row count is non-zero, so a 0 would mean a broken probe rather than a clean corpus.
- [ ] **CIAC-4 (#3413 × #3556 — the memory↔corpus boundary):** no residual owned by either card exists in **both** the corpus and the operator memory store, and #3556's eviction is observably **after** the corpus write reaches `main`.
- [ ] **CIAC-5 (#3825 × #3290 × #4454 — the `domain` token):** every `domain:` declaration created by the D3 sweep resolves to exactly one concept row in the registry, and **no template carries two `domain:` keys**. Regression guard — true today and must stay true.

---

## File Change Matrix

*Card-1 (#4455) rows are authoritative as of Stage-6 Commit 0; downstream cards' rows carry the Stage-4 intent.*

| Card | Path | Intent |
|---|---|---|
| #4455 | `core/deploy/tools/generate_release_index.py` | **edit** — extend into the projector: note-frontmatter reader, three entry renderers, `--emit`, required `--merge-anchor` / `--closeout-anchor` / `--repo-slug`, `--verify all`, Theme-integrity limb, row-order limb, header preservation, self-test extension |
| #4455 | `core/deploy/tools/lint_release_corpus.py` | **edit** — retire sub-check (c) only; reserve the identifier; (a)/(b)/(d)/(e) untouched |
| #4455 | `core/deploy/deploy.sh` | **edit** — Check 23's remediation string only (the destructive-regenerate instruction). **The Stage-5 limb-narrowing edit is WITHDRAWN**; Checks 32/47/48 are untouched |
| #4455 | `release/tools/automated-closeout.sh` | **edit** — three phases call the projector; caller-side fail-closed on empty emission; `phase_assert_derived_surfaces` gains its presence limb; slug well-formedness gate; `phase_transition_release_log` **unchanged** |
| #4455 | `release/references/standards/release-corpus-schema.md` | **edit** — Derived-Surface Contract table |
| #4455 | `release/references/pipeline/stage-13-close.md` | **edit** — Phase B: one source write plus three projections; anchors table unchanged |
| #4455 | `core/governance/RECORDS_POLICY.md` | **edit** — **explicit `Important`-class rows** for INDEX / DIGEST / CHANGELOG with a never-regenerated-whole disposition (INT-4 operator decision; **not** `Reference`, **not** `Transient`) |
| #4455 | `release/releases/RELEASE_LOG.md` | **edit** — one cell: the `v3.69.1` `Release PR` reconciliation. No other historical row touched |
| #4455 | `release/releases/RELEASE_INDEX.md` | **edit** — provenance marker only; no row regenerated |
| #4455 | `release/releases/RELEASE_DIGEST.md` | **edit** — provenance marker only |
| #4455 | `CHANGELOG.md` | **edit** — provenance marker only |
| #4455 | `.github/workflows/node-graph-tools-selftest.yml` | **edit** — add the projector to the self-test roster (a regression guard nothing executes is documentation) |
| #4455 | `release/ADRs/ADR-NNN-release-corpus-normalization.md` | **add** — number allocated at commit time, global-monotonic across both ADR homes |
| #3715 | `release/tools/sweep-release-corpus.py` | **add** — port from the prior run's preserved branch minus the four-ledger loaders; heading-class carve-out; table-chronology ordering; destination-side `verify()`; `--self-test` |
| #3715 | `release/releases/RELEASE_LOG.md` | **edit** — 147 `#### Deployment Log` bodies relocate; every heading retained with a pointer; the 8-column table untouched; all 8 `#### Release Learnings` blocks untouched |
| #3715 | `release/releases/RELEASE_LOG_ARCHIVE-{v1,v2,v3,version-less}.md` | **add** — 4 segments, one per major release family, confirmed at sweep time from the live family partition |
| #3715 | `core/governance/RECORDS_POLICY.md` | **edit** — the `RELEASE_LOG.md` disposition cell admits a same-directory archive segment. **Does not touch #4455's three `Important` rows** |
| #3715 | `core/governance/RECORDS_ARCHIVE_LOG.md` | **edit** — one row for this sweep |
| #3715 | `core/skills/finops-usage-extractor/scripts/estimate-usage.sh` (+ `.skill` / `.sha256`) | **edit** — the Velocity basis reads the ledger *and* its sibling segments |
| #3715 | `release/references/standards/release-corpus-schema.md` | **edit** — § Archive Segments declares the type and the reader rule |
| #3715 | `core/deploy/deploy.sh` | **edit** — Check 65, warn-mode hot-ledger budget probe (the chore's trigger) |
| #3387 | `core/governance/RECORDS_POLICY.md` (+ `core/artifact-workflow-protocol.md`, `operations/skills/generated-cleanup/SKILL.md` on the BUILD branch only) | per #4393 |
| #3825 | `core/specs/domain-token-registry.md` (**add**) + 8 pointer surfaces | per #4381 |
| #3196 ⊕ #4454 | `core/standards/template-taxonomy.md`, `core/standards/template-storage.md`, `operations/templates/README.md`, the 12 templates | merged work-package |
| #3290 | `template-protocol.md`, `operational-artifact-template-standard.md`, `template-taxonomy.md`, `operations/templates/README.md`, 26-file sweep, 3 `.skill` + `.sha256` rebuilds | per #4409 |
| #3413 | `core/disciplines/memory-architecture.md`, `core/disciplines/knowledge-architecture.md`, `core/ADRs/ADR-NNN-external-target-knowledge-axis.md` (**add**) | per #4397 |
| #3556 | `core/disciplines/architecture-overview.md` (+ conditional `operating-model.md`); operator memory store (**delete**, post-merge, IRREVERSIBLE) | per #4401 |
| #3816 | `gate-checklists.md`, `gate-definitions.md`, `intake-style-guide.md`, `packages/delivery-engine.skill` (+ `.sha256`) | per #4385 |
| *(all)* | `release/releases/plans/governance-hardening_RELEASE_PLAN.md` | **add** — this file, slug-primary per ADR-092 |

---

## Domain Practice Provenance

```
domain_practice: { source: N/A — pipeline-internal, date: 2026-08-02, domain: governance }
```

No external practice is load-bearing for this release. The governing standards are in-corpus: `duplicate-source-discipline.md`, `date-variable-convention.md`, `bypass-mode-readiness.md`, `records-management` policy, `template-taxonomy.md`, `blast-radius-protocol.md`.

---

## Deviation Log

| # | Stage-4 position | Superseding position | Source |
|---|---|---|---|
| D-1 | "`RELEASE_LOG.md` becomes the sole authoritative record; the other three are generated from it" | **Two file sources plus two run-scoped inputs.** The LOG carries neither a `# ` headline nor a `summary:`; the DIGEST's date is the close-out anchor, not the note's; the CHANGELOG needs a repo slug that is in neither file. | Stage-5 design + Blocker revision + two adversarial reviews (#4467) |
| D-2 | "Check 23 retires or becomes an idempotence assert; Check 32 narrows" | **1 retires · 7 survive.** Check 32 and Check 48 **survive unchanged** — the limb-narrowing was withdrawn in full, because a stdout-emitting projector guarantees entry *correctness*, never file *presence*. Check 47 untouched. | Stage-5 A6.5 B-2 + Blocker revision (#4467) |
| D-3 | Check 23 flips `warn` → `enforce` | **The flip is STAGED, not asserted.** `deploy.sh` records the flip condition in the check's own terms (≥3-day warn-log review, zero false positives, ten-check shakedown precedent). Asserting it here would be unfalsifiable at merge time. | Stage-5 AC-4 repair (#4467) |
| D-4 | R-3 Theme loss classified **EXPENSIVE** | **MODERATE.** The projector already round-trips every non-placeholder Theme cell byte-identically; the residual is that nothing *checks* it, which this card closes. | Stage-5 E-2 (#4467) |
| D-5 | `RECORDS_POLICY.md`: "reclassify INDEX / DIGEST / CHANGELOG as **derived artifacts**" | **Explicit rows at class `Important` with a never-regenerated-whole disposition.** The classification independent review falsified the derived-artifact reclassification: those three files hold 317 sole-copy fields (278,791 B, 35.9 %) with no source in the LOG. `Reference` is defined as *supersedable by re-acquisition*, which they are not. | **INT-4 operator decision, 2026-08-02** |
| D-6 | Card body: "seven machine contracts … six become unnecessary" | **Falsified.** There are **eight** (the census omits Check 48) and **exactly one** retires. The issue body is preserved as historical record per ADR-062; the correction lands in the ADR. | Stage-5 D-7 (#4467) |
| D-7 | Card body: `release/tools/generate_release_index.py`, `release/tools/lint_release_corpus.py` | Both live under `core/deploy/tools/`. **A1.5 translation recorded; the issue body is NOT rewritten** (ADR-062 — the body is historical record). | Stage-5 Phase A1.5 (#4467) |
| D-8 | #3715 design: the sweep's window is "the newest N blocks", ordering left implicit | **Ordering is taken from the LOG table's chronology, never from block position in the file.** The exit re-review flagged the ordering as load-bearing and unstated — a tail-order reading of the same window yields a materially different hot file. Measurement went further than the finding: the file's blocks are only *broadly* newest-first and the two readings diverge in the interior (first divergence at block index 82 of 156), so *stating* the ordering would still have left the rule resting on a convention. Keying on the table removes the dependency instead of documenting it. Both readings select the identical set at this release's boundary (symmetric difference ∅), so no measured figure moves. | Stage-6, from the Stage-5 exit re-review Major 2 |
| D-9 | #3715 design: stub cost modelled at "heading line + a ~90 B pointer sentinel"; projected hot ledger **154,253 B** | **148,558 B measured.** The implemented sentinel is one line, ~51 B for a `v1`/`v2`/`v3` segment name against the model's 90 B, and the preceding card's LOG reconciliation removed a further 52 B. The projection was a *model*; this is the *measurement*. It moves further inside the target, not outside it: headroom against the 200,000 B budget is **51,442 B**, not the projected 45,747 B. Archived-block count (**147**), segment count (**4**) and family partition are unchanged. | Stage-6 measurement |
| D-10 | #3715 design: `estimate-usage.sh` is the one consumer that must follow its content | **Correct, and it is not the only body reader — the other two are dispositioned rather than absorbed.** `produce-learnings-register.sh` is closed by the Release-Learnings carve-out (no tool edit needed). `phase_inject_outcome_field` requires a `**Result:**` line inside a `#### Deployment Log` block and hard-FAILs without one; **145 of 156** blocks carry that line and Deployment-Log blocks *are* swept, so a retro `--outcome` invocation against an archived release now fails loudly. That is the A6.5 pass's **M-3**, carried into Stage 6 open by the design owner's explicit decision, and **not** self-resolved here. It fails loudly rather than degrading silently, which is the better failure; the cheap remedy is named in the Stage-6 output. | Stage-5 A6.5 M-3, carried |
| D-11 | #3825 Stage-5 spec (#4381): **"No new ADR opened"** — assessed as N-ADR-2 + N-ADR-3 | **ADR-107 authored.** The spec's assessment was correct for the scope it saw: it was written 2026-07-31 and the key-collision **decision** was added to this card at the Stage-4 re-plan gate on 2026-08-02, after the spec closed. Re-assessed against the authoring guide, **T-ADR-2 fires** — the decision binds a contract two other cards must honour (a provenance sweep must not write inline into the seven; the same sidecar carries `template_family`), and T-ADR-1's rejected alternative (permanent exemption) must survive as rationale or it is re-litigated. N-ADR-3 does not apply: the placement convention governs the CSV case, ADR-050 governs the rename question, neither governs slot occupancy. The registry §3 remains the AC-graded surface; the ADR is the record it indexes. | Stage-6, from the Stage-4 re-plan scope addition (#4457) |
| D-12 | #3825 Stage-5 spec (#4381) D-3825-3: concept-2 declaration count **26**, with the census stated to reconcile *"exactly against the live sweep"* at `1 + 26 + 0 + 0 + 11 + 9 = 44` | **Concept 2 is 23, and the spec's own sum is 47, not 44.** Re-derived at this card's baseline by classifying all 44 declarations: concept 1 = **1**, concept 2 = **23**, concepts 3 and 4 = **0**, concept 5 = **11**, concept 6 = **9**; 23 + 11 + 9 + 1 = **44** against the live sweep, negative control `zzdomain:` = 0. The **26** is this release's signature defect — a figure measuring a different quantity than the proposition needed: 26 is the count of *headerless templates* from a sibling card, not of concept-2 declarations. **No design consequence**, and that is by construction: the same D-decision that carried the wrong number also ruled that the registry states **no count in prose**, so the error had no surface to propagate onto. Recorded because a number presented as reconciling, which does not, is the class of defect this release is about. | Stage-6 re-derivation |

---

## Rollback

| Surface | What `git revert -m 1` of the release PR restores | What it does **not** restore |
|---|---|---|
| Tooling + corpus text (steps 1, 3–7, 9) | Everything. No data migration, no consumer state. **CHEAP / HIGH.** | — |
| #3715 archive segments | Full byte content — the sweep is move-only and git preserves both sides. **CHEAP / HIGH.** | — |
| #4455 derived-surface provenance | The files' **bytes**. | **Not the provenance.** A reverted repo's next close-out writes by the old four-writer path, and anything authored into a derived surface between merge and revert is regenerated away rather than conflict-flagged. Mitigated by D-8: no history is regenerated, so the revert surface is one LOG cell plus tooling. **MODERATE / HIGH.** |
| #3556 memory eviction | **Nothing** — the eviction is outside git. | The evicted memory. **IRREVERSIBLE / HIGH.** Gated on the corpus write being merged to `main`; executed as the release's last action. |

---

## Identity Note (ADR-092)

This plan is **slug-primary**. Every version reference is the literal token `{{RELEASE_VERSION}}`. At the **Stage-12 atomic claim** the version number binds, this file is renamed to `<version>_RELEASE_PLAN.md`, and the token is resolved in the same commit. Any hardcoded version in this plan or in this release's authored files is a defect.
