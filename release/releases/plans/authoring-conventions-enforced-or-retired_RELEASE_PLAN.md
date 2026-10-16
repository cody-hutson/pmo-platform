---
title: Release Plan — authoring-conventions-enforced-or-retired (each of seven named authoring conventions has a recorded disposition a reader can check)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.75; the concrete number binds at the Stage-12 atomic claim)
milestone: authoring-conventions-enforced-or-retired
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH — every card reverts with its own commits and `git revert -m 1` of the merge restores `main`; the qualifications are in § Rollback Strategy — five label descriptions are repository state a revert does not reach, two decision records once numbered and merged are superseded rather than deleted, and a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `authoring-conventions-enforced-or-retired`

**Milestone:** `authoring-conventions-enforced-or-retired` (ms#352). Stage-4 planning sub-task **#8161** carries the approved three-part plan and every decision record this file transcribes (the Stage-4 plan gate, its gate-passage proof, and the Collective Review scope-lock). The Stage-5 designs are on **#8195, #8199, #8203, #8207, #8211, #8215 and #8219**, their Phase A6.5 adversarial reviews on **#8275, #8277, #8280, #8283, #8286, #8288 and #8302**. The Stage-6 Engineering sub-tasks are **#8196, #8200, #8204, #8208, #8212, #8216 and #8220**; this file is Engineering Commit 0, authored by #8196's spoke.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.75`**. Recorded as a determination at the Stage-4 gate, where the allocation rule computed `v4.74`; `telemetry-is-computable` then claimed `v4.74` at its merge on 2026-10-09, and the operator recorded `v4.75` at the Collective Review scope-lock. The concrete version binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the release-version stamp placeholder. Both halves of the Commit-0 re-verify ran — § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one branch `release/authoring-conventions-enforced-or-retired`, one pull request opened in **draft** after the first card commit, one merge into `main`. **Concurrency posture:** **P0 fully serial** — seven slices in § Implementation Sequence order (#5185, #5089, #4220, #5052, #5290, #4023, #4022), each launched behind a fresh quota-budget check; the branch is synced with `main` by merge, never by rebase, and is never force-pushed.

**Release class:** `cross-cutting`, engagement density **Standard** (an operator override of the class default) — re-classified from `routine` at the Stage-4 gate; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8161 (three parts) and its decision records, plus the Collective Review scope-lock record on the same thread. The File Change Matrix, Contention Map, Cross-Issue Acceptance Criteria, Verification Plan, Tier-A declarations, Operational Deployment Manifest and Deviation Log carry the scope-lock's locked options and corrections, drawn from the seven Stage-5 designs and their Phase A6.5 reviews. **Where a design and the decision record differ, the decision record wins; each such reading is recorded in § Deviation Log.** Every thread comment consumed is `OWNER`-authored (Comment-Ingestion Trust Boundary). Line numbers below are positions at the Stage-4 baseline `4babbba9` unless a row says otherwise; every slice re-anchors by content at the branch base.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version: protocol text and reference documents; no new skill and no new governance file). Provisional display v4.75 (re-rendered from v4.74, which a sibling release claimed at its merge); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-10-16 (Friday) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) landed; slices 1–7 pending |
| **Branch** | `release/authoring-conventions-enforced-or-retired` |
| **PR** | #8396 — draft, opened after the first card commit (SINGLE topology); it transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `authoring-conventions-enforced-or-retired` (ms#352) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-08, domain: governance }`

**Domain classification.** Form **X** (sourcing-exempt): every row targets an internal platform artifact — governance, pipeline specification, standards, two pipeline tools and their fixtures, two decision records and two skill packages. Dominant domain `governance`; secondary `software` (the event-append tool, the integrity validator and their self-tests). Transcribed unchanged from the Stage-4 plan (Phase A1.5) and carried unchanged by every Stage-5 design (§ 5.7).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1–3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `20197085` (`201970851da959db01111ef155f2f96d6676bfeb`, the merge of the `v4.74` Stage-13 chore). The branch was created from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 201970851da959db01111ef155f2f96d6676bfeb --bump minor --dry-run` (the adapter's own `anchor()` and `claimed_set()`; no tag pushed) | **`v4.75`** (exit 0; "would claim v4.75 (no tag pushed)") — equal to the planned version |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.75'                      (tag arm — binds)
             gh api repos/<owner>/<repo>/releases --paginate --jq '.[].tag_name'   (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md                (ledger arm)
             each filtered for the v4.75 slot
Denominator: 436 ls-remote tag lines; 217 published Releases (paginated, so not truncated);
             the ledger at origin/main, 2723 lines
Control - sensitivity: the same three readers on the v4.74 slot — tag v4.74 (1 ref), Release v4.74
             (present), and 7 ledger lines naming v4.74. Every arm resolves and returns non-zero,
             so a zero on the v4.75 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple has
             no near-miss class the probe must reject
Extraction:  the full Release list and the full ledger read from origin/main (never the worktree copy)
Result:      0 occupants of the (4,75) slot on every arm
Verdict:     CLEAN — v4.75 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** three sibling release branches carry draft pull requests — `controls-fail-loud` (#7919), `ci-wiring-and-required-checks` (#8305) and `hook-walk-adjudicates-every-operand` (#8306) — each bump-class `minor` and each recomputing `v4.75` (the milestone's Parallelization Map, recorded 2026-10-15 at `20197085`; § Cross-PR Overlap Audit → In-Flight Release Roster). Merge order arbitrates the slot at the Stage-12 compare-and-swap; no sibling has claimed, so this is an enumeration, not a collision.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp authoring-conventions-enforced-or-retired`, run after this file was written and before it was committed; required exit 0. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal release-version stamp placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1..5`, CIAC-2 and CIAC-3 amended at the scope-lock) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan (with the scope-lock amendments and the seven-card AC baseline) | § Verification Plan |
| 5 | Release-version stamp manifest (the placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, `4babbba9`) and the branch-base re-pin | § Cross-PR Overlap Audit → Baseline SHA |

### Commit-0 pre-flight (risk R10 — the sanctioned-session path)

Run read-only at Commit 0, so a gate failure on the sanctioned path surfaces before slice 1 rather than inside it:

- `release/skills/pmo-skill-editor/SKILL.md` carries `## Mode A — Edit` (`:100`) and the editor-audit-trail trailer rule (`:509`); `core/deploy/tools/start-skill-editor-session.sh` (executable) is the sanctioned minter of the `.editor-session` sentinel, which `.gitignore` excludes for every module's skills tree.
- `release/skills/release-planner/SKILL.md` and `release/skills/release-hub/SKILL.md` each carry `skill_discipline_migrated_v10_2: true` at `version: v4.46`, so the skill gate binds the template edit (#5185) and the hub-contract edits (#4023) to a sanctioned session.
- `core/deploy/deploy.sh` Check 10 (`:8596`) reads the last non-merge commit touching a migrated skill's **`SKILL.md`**; both sanctioned slices edit their skill's `SKILL.md` (the `version:` field, and for #4023 the contract text), so each Mode A commit carries the `Skill-Editor-Audit-Trail:` trailer.
- **Verdict: PROCEED.** R10's early warning is discharged at Commit 0 with no edit.

---

## Scope

### Issues Included

Seven content members — 18 raw points; 0 in-release build edges.

| # | Issue | Title | Priority | Size | Labels |
|---|---|---|---|---|---|
| 1 | #5185 | Memory-eviction manifest entries have no safe ARCHIVE destination; the implied one is a public surface | P2 | M | cluster: process-protocol · improvement · type:task · project:platform-quality |
| 2 | #5089 | knowledge-architecture memory-boundary rule is cited as section 6 by half the corpus and section 7 by the other half | P3 | S | cluster: process-protocol · improvement · type:task · project:platform-quality |
| 3 | #4220 | Schema section 3 column 3 must carry no backticks — undocumented phantom-subtype trap | P3 | S | bug · cluster: templates-schemas · type:bug · project:platform-quality |
| 4 | #5052 | Reconcile the deliverable-class named list: registry carries support, project-schema does not | P3 | S | cluster: process-protocol · improvement · type:task · project:platform-quality |
| 5 | #5290 | Codify a size-label assignment rubric so G3-09 / G3-15 consume a reproducible value | P3 (recommended at the readiness sweep) | M | cluster: templates-schemas · improvement · type:task · project:platform-quality |
| 6 | #4023 | Formalize evidence-quality labeling on conversational release turns (~4% adherence) | unset (the template carries no priority field) | S | cluster: process-protocol · type:story · project:pipeline |
| 7 | #4022 | Signal-tag discipline is 18.8% adhered — decide: enforce at emission or retire the bracket-tag convention | unset (the template carries no priority field) | S | cluster: process-protocol · type:spike · project:pipeline |

**Acceptance criteria.** Each criterion's single home is its issue body; § Verification Plan binds each by ordinal and never restates it. The bodies carry the Stage-4 refinements (`[BUNDLE AMENDMENT]` comments of 2026-10-08); the scope-lock's later readings of a criterion are carried in the bound verification rows, and the bodies stay historical (DEV-31).

### Exclusions

- **No membership change** since the Stage-4 gate: seven cards, 18 raw points.
- **Follow-on stories filed by the hub after the scope-lock** are outside this release: #8375 (#4022's first check on the signal tags' declared surfaces) and #8376 (#4023's dated first reading of evidence labels on the hub's decision records).
- **Routed counter-designs and discoveries** are outside this release: #5089's explicit-id counter-design (#8228); the intake items the scope-lock approved for filing.
- **Explicit non-scope:** historical release records are never rewritten; an Accepted decision record's decision text is never edited (ADR-045 gains only its reciprocal supersession pointer and one Related-ADRs line); `core/governance/OPERATIONS.md` is not edited (D-5185-PHASE-REMOVED (i)); `core/deploy/deploy.sh` is not edited.

---

## Decision Record

### Stage-4 plan gate (operator, 2026-10-09)

| ID | Decision | Operator choice |
|---|---|---|
| D-ReleaseClass | Release Class | **`cross-cutting`, engagement density Standard** (an override of the class default, Tight, with its rationale recorded) |
| D-A0-Refinements | The Phase A0 criterion refinements as one batch | **Approve the batch** — 17 refinements across the seven cards, applied in place with one `[BUNDLE AMENDMENT]` comment each |
| D-OutcomeStatement | The Release Outcome Statement | **Approve the corrected draft**; published as the milestone's verbatim H3 |
| Plan approval (Phase B), ratifying D-Concurrency Posture | The Stage-4 plan | **Approve**, posture **P0 fully serial** |
| D-C (recorded) | Branch topology | SINGLE — one branch, one PR, one merge |
| Stage 5 (recorded) | Activation | ACTIVATE, release-wide (rule-determined); no stage skipped on any card |

### D-Version (recorded determination) and its re-render

- **At the Stage-4 gate:** versioned · bump-class `minor` · provisional `v4.74` (`anchor()` = `v4.73`; the claimed set held no `v4.74`). CHEAP / HIGH.
- **Re-rendered at the Collective Review scope-lock (operator, 2026-10-15):** `telemetry-is-computable` merged on 2026-10-09 and claimed `v4.74`, so this release plans at **`v4.75`**, the allocation rule's next-free value for a minor bump; bump-class `minor` stands under the rendered options. Three in-flight siblings recompute the same slot, and whichever claims first takes it. CHEAP.

### Collective Review scope-lock (operator, 2026-10-15)

Rendered in the hub session as four structured answers, each the hub's recommendation: the scope-lock package approved; D-4022 = (C); D-5089-FORM = D; and the earlier-release archive disposition = delete and re-post an abstracted record. No answer differed from its recommendation.

| Card | Locked |
|---|---|
| #5185 | **D-5185-ARCHIVE = C** — no archive by default; an operator-local copy for an elected entry — with the review's **CD-1** (the tie is the unit of eviction: one all-or-nothing row per tie with a planned count), **CD-2** (the absorption gate is a post-state test over the ties the manifest names) and **CD-3** (binding and naming assigned to the hub at the Tier 1 authorization). Basis: recoverability under A is bounded by a finite local Trash retention, the one fact the design named as moving it toward C. **D-5185-VALIDATION = V-A** (V-B and V-C are follow-ons, not built here). **D-5185-LIFECYCLE-RECORD = R-a.** **D-5185-PHASE-REMOVED = (i)**, a named residual on the three floored sentences. **D-5185-SCOPE accepted.** Every correction the review (#8275) lists under its Output for Stage 6 — A-1 through A-8 — is applied |
| #5089 | **D-5089-FORM = D** — name label, plain file link, no fragment; names delimited — with the requirement read as "a renumber cannot re-create the split". **D-5089-POPULATION = P3.** **D-5089-RULE-HOME = H1′.** **D-5089-AC3** reworded with the review's method correction. **D-5089-SCOPE accepted.** The explicit-id counter-design is routed to #8228 |
| #4220 | **D-4220-TWIN = (a)**, with the review's strengthened fixture (CD-1). **D-4220-RULE = A** as refined at the plan gate. The third same-class loop in the writer is recorded as a deferral, named by the new comment. The AC-1 and AC-2 wording refinements are approved |
| #5052 | **Direction (a′):** the project schema holds the list, with the rule stated at the list's home, one invariant row in the verification contract, and the registry's row-1 cue kept in derivation form. Both pipeline-spec example lists converted (T1); the third Stage-4 list recorded as retained. **D-5052-AC3** taken as a grading note, not a body rewording |
| #5290 | **Host H2.** The rubric's **method is ratified; its cut points are held as seeds**, out of the label grammar, the decision record and label state, until an ex-ante backtest has run. **Boundary B-3.** **Legacy labels L-2** |
| #4023 | **Fork (b).** **Runner E1** (`Runner: NONE` with a named-gap register row) plus a follow-on story carrying a dated first read (filed: #8376); a rendered slot (the review's CD-1) is an option for that story. The delivered disposition is named "restated with the surface it binds" |
| #4022 | **D-4022 = (C)**, with the decision record. The design's text is corrected for both event families and for which writer records most Tier 2 escalations; the follow-on story (filed: #8375) is not tied to a commit-message check as its first runner, and lists a Tier 2 slot on hub escalation records as an option |

**Corrections locked under every option** (spec corrections, not choices): each card's review corrections as listed in the Collective Review briefing — including one INT-2 end state shared by #5185 and #5089, the merge of #4220's INT-1 with CIAC-3, the #5089 CIAC-2 method amendment, and the #5185 register pointer repointed at the Stage 13 spec.

**Release-level.** Scope changes (Tier 2, escalation `ESC-CR`) accepted: the five spoke-raised changes (D-5185-SCOPE, D-5089-SCOPE, D-4220-TWIN, D-4023-SCOPE, D-4022-SCOPE) and the hub-detected paths the chosen options keep (the H1′ alignment files). Size labels kept (18 raw, 23 effective, band 15–25), the growth recorded at Commit 0 (DEV-12). Version provisional `v4.75`, bump-class `minor`. Before Stage 6: one `core/ADRs/README.md` disposition; new decision records written on slug tokens, numbered in Stage 6 order and bound at merge; a Tier-B design-artifact determination for #4220. The earlier-release archive comment: the operator deletes it and the hub posts an abstracted record. Stage 6 fully serial in the approved order, one branch and one pull request, each launch behind a fresh quota-budget check. The Collective Review prerequisites are recorded on the milestone's ledger as AI-008, AI-009 and AI-010.

### Recorded determinations (not gates)

- **D-Version** — versioned · `minor` · provisional `v4.75` (above); bound at the Stage-12 claim.
- **D-C** — SINGLE.
- **Stage 5** — ACTIVATE, release-wide; Stages 10 and 11 compressed under the git-native path.
- **Spoke effort** — every launch passes maximum effort explicitly.

---

## Dependency Graph

**Hard edges: none.** Three Stage-4 probes agree — the native dependency API (0 on all 14 reads, with a sensitivity arm on two issues known to carry edges), the documented hard-versus-soft scan over the milestone's members, and a full read of every card body and comment. **Zero circular chains** — trivially, since no directed hard edge exists.

**In-release ordering edges** (derived from shared files, not from dependencies):

```
#5185 --file-order--> #5089   knowledge-architecture.md (the boundary section), stage-13-close.md
                              Phase B-OPS, and the drift-audit how-to: #5185 rewrites the text,
                              #5089 then replaces link substrings it finds by content
#4023 --design-coupling-- #4022   one seam on the hub's per-emission contract; #4023 first
#5185, #5089, #4023, #4022 --register-- core/standards/gate-efficacy-standard.md: register rows
                              in one contiguous hunk after the class 3-O anchor row, in slice order
#4220, #5052, #5290           independent of every other card
```

**Parents.** #4022 and #4023 sit under the release-hub response-convention epic; the other five under the evergreen intake epic. Neither parent imposes an ordering.

---

## Implementation Sequence

**Topology:** D-C SINGLE, one branch, P0 fully serial. Every criterion arm with a runnable probe is observed before its fix, then after it.

| # | Slice | Stage-6 sub-task | Execution path | Why here |
|---|---|---|---|---|
| **0** | Engineering Commit 0 — this file | #8196 | ordinary Engineering spoke | The plan, with the Commit-0 re-verify (steps 1–3, then 3b) and the R10 pre-flight |
| **1** | #5185 | #8196 | ordinary spoke for the discipline, the Stage-13 spec, the how-to, the register and the two decision-record files; **sanctioned session** (`pmo-skill-editor` Mode A) for the release-plan template and the `release-planner` `version:` field; the package in its own commit | Leads: it rewrites the surface #5089's citations target, and it carries the first sanctioned-session write, so a gate failure surfaces at the first spoke |
| **2** | #5089 | #8200 | ordinary Engineering spoke | After #5185 — file order in three files |
| **3** | #4220 | #8204 | ordinary Engineering spoke | Independent |
| **4** | #5052 | #8208 | ordinary Engineering spoke | Independent |
| **5** | #5290 | #8212 | ordinary Engineering spoke | Independent |
| **6** | #4023 | #8216 | **sanctioned session** for the hub contract and its `version:` field; ordinary for the register row; the `release-hub` package in its own commit | Its surface is the most contended (two siblings edit the hub tree's package) |
| **7** | #4022 | #8220 | ordinary Engineering spoke | Last: its decision record cites the seam #4023 builds |

**Change specifications.** Each is the Stage-4 change specification of the card as its Stage-5 design refines it and the scope-lock locks it; the design comment is the spec anchor each slice reads directly.

- **Slice 1 — #5185** · M · design on #8195 (three parts), review on #8275. Locked: D-5185-ARCHIVE C with CD-1, CD-2 and CD-3; V-A; R-a; (i); D-5185-SCOPE; the review's A-1 to A-8.
  - `core/disciplines/knowledge-architecture.md`, § Encode-and-evict lifecycle and § Trigger + audit: the hosted-archive phase leaves the lifecycle block and the phase count leaves prose (the closing phase, RE-POINT, is named, not numbered). An **Archive-disposition rule** paragraph after the paragraph on how EVICT removes the file: the disposition is `none` by default and `operator-local` only where the operator elects it for a row, the operator — never the executor — making that copy outside the store and outside every git working tree before EVICT; the tie as the unit of eviction (one all-or-nothing row per tie, naming every corpus home and probe the card writes and the planned count of ledger rows citing the tie, stopped on a count mismatch); the split-first rule (an entry holding more than the encoding kept is split, the remainder left in the store with the tie removed, before it is listed; a ledger row citing more than one issue stops the row); the probe in its ref-anchored form, with the zero it reads at the merge base; and binding and naming by the hub at the Tier 1 authorization, with tie and count only on any public record. The ordering rationale, the RE-POINT pre-state sentence and the executor chain are reconciled; the close-time absorption reconciliation becomes a post-state test after EVICT and RE-POINT over every tie the manifest names; one sentence records the decision record. No heading and no explicit id is added, renamed or removed (CIAC-1, INT-1).
  - `release/references/pipeline/stage-13-close.md` Phase B-OPS: B-OPS5's input re-based on the post-state test; the memory-eviction paragraph's executor chain; one appended stop-rule sentence that carries the `archive-disposition` token the register pointer resolves against (review A-1). Both existing links stay byte-identical, so #5089's link-substring edit finds them by content (INT-2); no link and no section-number token is added.
  - `release/references/how-to/memory-corpus-drift-audit.md`: the executor chain in the remediation row and the posture word in the composition paragraph.
  - `core/standards/gate-efficacy-standard.md`: one class 3-O register row directly after the anchor row whose invariant begins "No surface of this install holds a resolved target-side referent", with `runner-def: release/references/pipeline/stage-13-close.md::archive-disposition` and its Check-62 falsification; its enforcement cell states what is gated on a tracked file (an entry's *name shape*) and that an entry's *content* is gated on no surface (review A-8).
  - `core/ADRs/ADR-NNN-memory-eviction-archive-disposition.md` (ADD, `status: Proposed`): the record, superseding ADR-045 in part — the archive-first property of its Decision item 4. `core/ADRs/ADR-045-cross-surface-memory-contract.md`: the reciprocal `superseded_by:` line and one Related-ADRs bullet; its decision text is untouched.
  - **Sanctioned session:** `release/skills/release-planner/references/release-plan-template.md` — a `### Memory Evictions (if applicable)` sub-table under the manifest heading, with the Layer-1 → Layer-2 boundary stated in the format and a worked example row per tie; a `## Memory-Eviction Entry Contract` section with its data-flow marker; usage rule 8; the skeleton's outer fence widened so the contract and every section after it render as markdown (review A-7). `release/skills/release-planner/SKILL.md`: the `version:` field only (DEV-21).
  - `packages/release-planner.skill` and `.sha256`: rebuilt in their own commit after the last edit to the skill tree.
  - `core/ADRs/README.md`: **no entry** — a curated thematic document (DEV-29). `core/governance/OPERATIONS.md`: **not edited** — the three floored sentences are a named residual (DEV-26).
- **Slice 2 — #5089** · S · design on #8199 (two parts), review on #8277. Locked: D-5089-FORM D, POPULATION P3, RULE-HOME H1′, AC-3 reworded.
  - Converted citations — a name label, delimited, over a plain file link with no fragment and no section number: `core/CLAUDE.md.template` (`:188`), `core/disciplines/external-seam-conduct.md` (`:40`, `:320`), `core/standards/gh-api-convention.md` (`:331`), `core/standards/universal-vs-localized-context.md` (`:18`, `:166`), `release/references/how-to/memory-corpus-drift-audit.md` (`:8`, `:29`, `:31`, `:108`, `:152`, `:154`, `:180`, `:183`; the fenced sample at `:88` is preserved), `release/references/pipeline/stage-13-close.md` (the two link substrings at `:244` and `:246`, located by content after slice 1), and `core/disciplines/memory-architecture.md` (P3: nine links on eight lines).
  - H1′: the citation-form rule stated once in `core/standards/reference-durability-standard.md`, beside its own anchor-resolution paragraph and marked as not detector-backed, the first authoring check's scope left alone; the surfaces that already state a form aligned to it — `release/references/how-to/intake-style-guide.md` (§ Section-anchor citations), `core/standards/design-artifact-standard.md` (§ Cross-Reference Protocol's example) and the spoke-prompt restatement in `release/references/how-to/hub-spoke-bridge.md` (Procedure 3); and in `core/standards/gate-efficacy-standard.md` the naming clause registered as a named gap with no pointer, with the posture an existing repository-integrity row states for anchors corrected.
  - Not edited: the two Accepted decision records, the terminal release records, the shell-string citations in `core/deploy/deploy.sh`.
- **Slice 3 — #4220** · S · design on #8203 (two parts), review on #8280. Locked: D-4220-TWIN (a) with CD-1; D-4220-RULE A.
  - `release/tools/append-pipeline-event.sh` `parse_schema_enum`: exclude every parenthetical span of a column-3 cell, then extract; a seeded self-test arm beside the lockstep assertion, with CD-1's control seed after an unclosed parenthesis; one stale comment; the third same-class loop named as a deferral by the new comment.
  - `release/tools/check-event-record-integrity.sh`: the same narrowing in its parser, and one self-test arm that binds its findings by name and prints a named OK line.
  - `release/tools/tests/fixtures/event-record/schema-s3-paren-seed.md` and `log-s3-paren-seed.md` (ADD): the CD-1 fixture — a nested span, a glue probe, a second span and an unclosed parenthesis, with two more log rows.
  - `release/references/standards/pipeline-event-log-schema.md` § 3: the column-3 authoring note (with the token-class clause, naming the `iteration` row as its case — review A-3), placed after the "Subtypes outside the lists above" paragraph; no table row is touched.
  - Expectations are bound by name, not by a delta or a literal count (review A-4); the mutation proof runs in place before the commit, unmutated first (A-2).
- **Slice 4 — #5052** · S · design on #8207 (two parts), review on #8283. Locked: direction (a′); T1.
  - `core/schemas/project-schema.md`: the ten named classes stated once, at the `deliverable_type` field reference (the root-schema line and rule V13 refer to it), with the membership sentence written as a definition (review CD-1) and one clause pointing at the gate spec's close-class block for `task-artifact`.
  - `core/specs/domain-token-registry.md` Concept 1 row: cites the schema as the list's holder; the row-1 cue kept in derivation form (review FM-3).
  - `release/references/pipeline/stage-04-planning.md` (the § 5.7 example list becomes a citation; its guide list a derivation) and `release/references/pipeline/stage-07-dev-testing.md` (the example list removed, its sentence already citing the Stage-4 paragraph). The third Stage-4 list (`:192` at the Stage-4 baseline) is recorded as a retained example.
  - One invariant row in the verification contract — every shipped guide's domain appears on the list line (§ Verification Plan → Release-Level Verification).
- **Slice 5 — #5290** · M · design on #8211 (three parts), review on #8286. Locked: H2; the method ratified and the cut points held as seeds; B-3; L-2.
  - `release/references/standards/bundle-composition-doctrine.md` § 3 Step 5: the size-class assignment sub-block — the method, the class table and its worked examples, with the cut points marked as seeds measured after delivery and untested before it (review CD-1 and corrections 1–2) — the point-scale pointer line, and a `## References` block carrying the worked examples' issue numbers, each with a one-line summary.
  - `core/schemas/gate-criteria-spec.md`: G3-09's self-repair string, at both sites, cites the rubric.
  - `core/specs/label-taxonomy.md` (B-3): the instance-model sentence restated — `size:*` is read by K1 gates and defined in the host; nothing is declared.
  - Not delivered: the common pack's five declared rows and the B-1 decision record (B-3); the estimation-standards host and the `delivery-engine` package (H2).
  - The five label descriptions are a post-merge, operator-authorized step (§ Operational Deployment Manifest, entry 2): under the seed posture each carries its point value and anchor in words, without cut-point numerals.
- **Slice 6 — #4023** · S · design on #8215 (two parts), review on #8288. Locked: fork (b); runner E1.
  - **Sanctioned session:** `release/skills/release-hub/SKILL.md` § Output Contract — the evidence-label requirement in the per-emission requirement list, in the rubric's surface-class terms, with its emission-time question, back-references, one failure-mode entry and the `version:` field; `release/skills/release-hub/references/decision-briefing.md` — one clause in item 1. The review's corrections 1–8 apply to the change text.
  - `core/standards/gate-efficacy-standard.md`: one named-gap register row (`Runner: NONE`), after the release's earlier rows.
  - `packages/release-hub.skill` and `.sha256`: rebuilt in their own commit after the last edit to the hub tree in this release (this slice; #4022 writes nothing there).
  - Not fired: `core/skills/pmo-qa-auditor/references/push-to-resolve-rubric.md` and its package; the `:190` limb of the charter-template row.
- **Slice 7 — #4022** · S · design on #8219 (three parts), review on #8302. Locked: D-4022 (C) with the record.
  - `release/governance/release-process.md` § Inter-Stage Feedback Protocol: the signal-tag disposition paragraph and table — each tag bound to its durable record and that record's class in the rubric's terms — with the measurement corrected for both event families and for which writer records most Tier 2 escalations.
  - `release/ADRs/ADR-NNN-signal-tags-bind-durable-surfaces.md` (ADD) and `release/ADRs/README.md`, regenerated by `python3 release/tools/generate-adr-index.py --write`, never hand-edited.
  - `core/standards/gate-efficacy-standard.md`: one named-gap register row, the last of the release's rows.

**A2 container determination (for each slice's spoke).** Every card's decomposition is multi-file and structure-changing, so the threshold predicate selects the GitHub sub-issue container; the per-card Stage-6 sub-tasks the hub scaffolded (#8196, #8200, #8204, #8208, #8212, #8216, #8220) are that container, with the change units enumerated in § File Change Matrix.

---

## Stage Applicability Matrix

**Stage 5 (activation-criteria matrix, `core/standards/planning-solutioning-handoff.md` § 4):**

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #4022 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T2 a release-hub skill file is a named candidate; T3 a protocol disposition; T4 options (A)/(B); T6 the file set is identified by the spike decision |
| #4023 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T2 a skill reference is named; T3 a standard binding surface classes; T4 fork (a)/(b); T6 the mechanism's host is undeclared |
| #4220 | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ACTIVATE | T4 two candidate narrowings with different coverage |
| #5052 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T3 which surface is authoritative; T4 directions (a)/(b); T6 third copies outside the card's file set |
| #5089 | ✗ | ✗ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T3 a cross-document reference form; T4 anchor forms; T6 a grep-discoverable population |
| #5185 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T2 a release-planner skill reference is in the write set; T3 an entry format; T4 options (1)/(2); T6 a second file named "possibly" |
| #5290 | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ACTIVATE | T2 one host candidate is a skill reference; T3 the mechanism deferred to Stage 5; T4 three hosts; T6 files "identified in Planning" |

**Release-level rollup: ACTIVATE.** Collective Review fired and scope-locked on 2026-10-15.

| Stage | #5185 | #5089 | #4220 | #5052 | #5290 | #4023 | #4022 | Basis |
|---|---|---|---|---|---|---|---|---|
| **5 — Solutioning** | APPLY (#8195; review #8275) | APPLY (#8199; #8277) | APPLY (#8203; #8280) | APPLY (#8207; #8283) | APPLY (#8211; #8286) | APPLY (#8215; #8288) | APPLY (#8219; #8302) | T2 · T3 · T4 · T6 fire; scope-lock 2026-10-15 |
| **6 — Engineering** | APPLY (#8196) | APPLY (#8200) | APPLY (#8204) | APPLY (#8208) | APPLY (#8212) | APPLY (#8216) | APPLY (#8220) | P0, § Implementation Sequence order |
| **7 — Dev Testing** | APPLY (#8197) | APPLY (#8201) | APPLY (#8205) | APPLY (#8209) | APPLY (#8213) | APPLY (#8217) | APPLY (#8221) | #5185: spec read and the reference-cascade sweep · #5089: corpus sweep with denominator and residual · #4220: runtime suite (both self-tests) and an adversarial seed · #5052: both entry points and the census · #5290: conformance and the backtest (AC-7) · #4023 and #4022: conformance against the design, with a sample turn for #4023 |
| **8 — QA** | APPLY (#8198) | APPLY (#8202) | APPLY (#8206) | APPLY (#8210) | APPLY (#8214) | APPLY (#8218) | APPLY (#8222) | 29 criteria; #5290 AC-6 graded after merge |
| **9 — Plan Review** | APPLY (#8223, release-scoped) | | | | | | | **Deep** (`cross-cutting`) |
| **10 — Dry Run** | COMPRESS (#8224, closed) | | | | | | | Git-native release (Stage Compression) |
| **11 — Snapshot** | COMPRESS (#8225, closed) | | | | | | | Git history is the snapshot |
| **12 — Execute** | APPLY (#8226) | | | | | | | Merge + atomic claim (versioned) + the `release-planner` and `release-hub` deploys, verified by content |
| **13 — Close** | APPLY (#8227) | | | | | | | 30-day outcome window; the seven cards are transitioned to closed at Stage 13 |

**No stage is skipped for any card.** Each card has a criterion whose pass depends on a tool reading the changed text, so a wrong edit has an observable effect. `[RECOMMENDED]` CHEAP / HIGH.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction and grouped by slice. A path edited by more than one card is listed under each card; § Contention Map carries the per-file writer set. Every row is unconditional at Commit 0: each Stage-4 row whose condition resolved is either promoted here or recorded as not fired (DEV-20).

```
# ── Release corpus (Engineering Commit 0) ──
release/releases/plans/authoring-conventions-enforced-or-retired_RELEASE_PLAN.md  ADD

# ── #5185 · slice 1 (option C with CD-1, CD-2, CD-3; R-a; the sanctioned session for the skill tree) ──
core/disciplines/knowledge-architecture.md  EDIT
release/references/pipeline/stage-13-close.md  EDIT
release/references/how-to/memory-corpus-drift-audit.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
core/ADRs/ADR-NNN-memory-eviction-archive-disposition.md  ADD
core/ADRs/ADR-045-cross-surface-memory-contract.md  EDIT
release/skills/release-planner/references/release-plan-template.md  EDIT
release/skills/release-planner/SKILL.md  EDIT
packages/release-planner.skill  EDIT
packages/release-planner.skill.sha256  EDIT

# ── #5089 · slice 2 (form D, population P3, rule home H1′) ──
core/CLAUDE.md.template  EDIT
core/disciplines/external-seam-conduct.md  EDIT
core/standards/gh-api-convention.md  EDIT
core/standards/universal-vs-localized-context.md  EDIT
release/references/how-to/memory-corpus-drift-audit.md  EDIT
release/references/pipeline/stage-13-close.md  EDIT
core/disciplines/memory-architecture.md  EDIT
core/standards/reference-durability-standard.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
release/references/how-to/intake-style-guide.md  EDIT
core/standards/design-artifact-standard.md  EDIT
release/references/how-to/hub-spoke-bridge.md  EDIT

# ── #4220 · slice 3 (twin (a), with the strengthened fixture) ──
release/tools/append-pipeline-event.sh  EDIT
release/references/standards/pipeline-event-log-schema.md  EDIT
release/tools/check-event-record-integrity.sh  EDIT
release/tools/tests/fixtures/event-record/schema-s3-paren-seed.md  ADD
release/tools/tests/fixtures/event-record/log-s3-paren-seed.md  ADD

# ── #5052 · slice 4 (direction a′; both pipeline-spec example lists converted) ──
core/schemas/project-schema.md  EDIT
core/specs/domain-token-registry.md  EDIT
release/references/pipeline/stage-04-planning.md  EDIT
release/references/pipeline/stage-07-dev-testing.md  EDIT

# ── #5290 · slice 5 (host H2, boundary B-3) ──
core/schemas/gate-criteria-spec.md  EDIT
release/references/standards/bundle-composition-doctrine.md  EDIT
core/specs/label-taxonomy.md  EDIT

# ── #4023 · slice 6 (fork b, runner E1; the sanctioned session for the hub tree) ──
release/skills/release-hub/SKILL.md  EDIT
release/skills/release-hub/references/decision-briefing.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
packages/release-hub.skill  EDIT
packages/release-hub.skill.sha256  EDIT

# ── #4022 · slice 7 (option C, with the decision record) ──
release/governance/release-process.md  EDIT
release/ADRs/ADR-NNN-signal-tags-bind-durable-surfaces.md  ADD
release/ADRs/README.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
```

- **Matrix size:** 39 distinct paths — 5 ADD (this plan, two decision records and #4220's two fixtures) and 34 EDIT. Every EDIT path exists at the branch base and every ADD path is absent (a per-path existence read; § Verification Evidence). The two decision-record ADD rows carry the `NNN` placeholder, which the extractor normalizes to a glob with a literal directory prefix and a literal slug, so the rows stay resolvable when the renumber tool moves a record at merge.
- **Growth over the Stage-4 matrix** (37 paths: 18 unconditional and 19 conditional): 10 conditional rows fired and are promoted here (the two decision records, the release-module index, the two pipeline-spec example lists, the label taxonomy and the four release-hub rows); 9 did not fire and are not carried (DEV-20); and the accepted scope changes add 11 paths — `core/standards/gate-efficacy-standard.md`, `release/skills/release-planner/SKILL.md` and ADR-045 (#5185); `core/disciplines/memory-architecture.md`, `core/standards/reference-durability-standard.md`, `release/references/how-to/intake-style-guide.md`, `core/standards/design-artifact-standard.md` and `release/references/how-to/hub-spoke-bridge.md` (#5089); `release/tools/check-event-record-integrity.sh` and the two fixtures (#4220). The decision record estimates "about nine"; the count by path is eleven (DEV-12).
- **Package cascade, resolved against the roster:** `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` with the 35 paths that exist or are this plan on stdin names `release-hub` and `release-planner` only (control: the release-plan template alone → `release-planner`; specificity: `core/disciplines/knowledge-architecture.md` alone → none). Both package pairs are declared, each rebuilt in its own commit after the last edit to its tree.
- **No new executable.** Every ADD row is markdown, so the new-executable companion obligation (an allowlist row and CI wiring) does not fire.
- **ADR index.** This release adds a record under `release/ADRs/` (#4022's), so `release/ADRs/README.md` is regenerated with `python3 release/tools/generate-adr-index.py --write` and declared EDIT above; confirmed with `--verify`. `core/ADRs/README.md` is a curated thematic document with no projector and receives no entry (DEV-29).
- **No path moves** — the intents are ADD and EDIT only; the mover set is empty.

#### Read-only inputs

```
core/hooks/block-autonomy-ceiling.sh  READ
core/hooks/block-skill-direct-edit.sh  READ
core/hooks/block-rm-prefer-trash.sh  READ
core/deploy/tools/start-skill-editor-session.sh  READ
core/deploy/tools/check-label-parity.py  READ
core/config/platform-config.toml.template  READ
core/standards/design-principle-register.md  READ
release/tools/check-release-links.py  READ
release/tools/verify-release-plan.sh  READ
release/tools/renumber-adr.py  READ
release/tools/generate-adr-index.py  READ
```

#### Release-wide explicit non-scope

```
core/deploy/deploy.sh  NOT EDITED
core/governance/OPERATIONS.md  NOT EDITED
core/ADRs/ADR-029-memory-corpus-ssot-boundary.md  NOT EDITED
core/ADRs/ADR-050-deliverable-domain-axis.md  NOT EDITED
core/ADRs/README.md  NOT EDITED
release/releases/RELEASE_INDEX.md  NOT EDITED
```

The repository-root `CHANGELOG.md` is not edited either; it stays out of the fence because the matrix extractor's path recognizer reads only rows under a module root, and a bare top-level row would read as uninterpreted rather than excluded.

Accepted decision records are treated as immutable in their decision text, following the precedent a prior release recorded when it left a stale citation untouched; a correction to one is a superseding or amending record. ADR-045 leaves this block — its reciprocal pointer is permitted hygiene on an Accepted record (DEV-25). `core/ADRs/README.md` is authored by no slice; the renumber tool alone may append its own log line to that file at the Stage-12 claim if it moves a record. The release ledger, index, digest and notes are written by the Stage 12 and Stage 13 chore pull requests, not by the release PR.

---

## Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `4babbba9`) and extended to the rows the scope-lock added. Neither control file is among the 39 files changed between `4babbba9` and the branch base `20197085` (0 changes under `core/hooks/`), so the derivation holds at Commit 0.

- **Tier-0 floor** (`core/hooks/block-autonomy-ceiling.sh`, `BLOCK-AUTONOMY-001`): projected onto tracked paths it names `core/governance/OPERATIONS.md`, `operations/OPERATIONS.md` and `release/governance/RELEASE_PROTOCOL.md`. **No write-set path intersects them** — the only floored candidate, `core/governance/OPERATIONS.md` (Stage-4 row 19), did not fire. `core/CLAUDE.md.template` is not floored: its basename is not `CLAUDE.md`.
- **Sanctioned-session gate** (`core/hooks/block-skill-direct-edit.sh`): `SKILL_SCOPE_RE` matches `<module>/skills/<name>/SKILL.md` and `references/*.md` of an armed skill; `release-planner` and `release-hub` are armed and neither is on the exemption list. **Four write-set paths match:** the release-plan template and `release-planner`'s `SKILL.md` (#5185), the hub contract and its briefing reference (#4023).

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Execution path |
|---|---|---|---|---|---|
| #5185 | `release/skills/release-planner/references/release-plan-template.md`, `release/skills/release-planner/SKILL.md` | no | yes (regex ✓ · armed ✓ · not exempt ✓) | sanctioned-session-required | `pmo-skill-editor` Mode A, one session |
| #5185 | `packages/release-planner.skill`, `.sha256` | no | build product — takes its source's class | sanctioned-session-required | produced by `bash core/deploy/tools/build-skill-packages.sh release-planner` |
| #5185 | the discipline, the Stage-13 spec, the how-to, the register, the new record, ADR-045 | no | no (regex ✗) | unconstrained | ordinary Engineering spoke |
| #4023 | `release/skills/release-hub/SKILL.md`, `release/skills/release-hub/references/decision-briefing.md` | no | yes | sanctioned-session-required | `pmo-skill-editor` Mode A, one session |
| #4023 | `packages/release-hub.skill`, `.sha256` | no | build product | sanctioned-session-required | produced by `bash core/deploy/tools/build-skill-packages.sh release-hub` |
| #4023 | the register row | no | no | unconstrained | ordinary Engineering spoke |
| #5089 · #4220 · #5052 · #5290 · #4022 | every row in their slices, including the charter template, the spoke-prompt guide, the two tools and their fixtures, the two pipeline specs, the release-module index and the new release record | no | no (regex ✗) | unconstrained | ordinary Engineering spoke |
| all | this plan | no | no | unconstrained | ordinary Engineering spoke (Commit 0) |

"Unconstrained" means no control refuses the write; it never means the change is ungoverned. `release/governance/release-process.md`, `core/schemas/gate-criteria-spec.md` and the charter template are governance surfaces whose edits are authorized by this plan's approval and reviewed in the release PR.

---

## Contention Map

### Within-release contention (derived from § File Change Matrix)

| File | Writers (slice order) | Nature | Resolution |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` | #5185, #5089, #4023, #4022 | register rows — one per card except #5089, which adds one named-gap row and corrects an existing row's anchor posture | one contiguous hunk after the class 3-O anchor row, in slice order; each later card inserts after the release's last row |
| `release/references/pipeline/stage-13-close.md` | #5185, then #5089 | #5185 rewrites two Phase B-OPS paragraphs and keeps their two links byte-identical; #5089 replaces those two link substrings | ordering, not a line conflict (INT-2) |
| `release/references/how-to/memory-corpus-drift-audit.md` | #5185, then #5089 | #5185 at the remediation row and the composition paragraph (`:149`, `:174`); #5089 at its eight citation lines | disjoint lines; #5185 first (INT-3) |
| `core/disciplines/knowledge-architecture.md` | #5185 | #5089 cites its headings and edits nothing in it | #5185 keeps every heading and id (INT-1) |
| `release/skills/release-hub/**`, `packages/release-hub.skill*` | #4023 | one skill tree, one binary package | one rebuild, after #4023's last edit |

Every other path in the matrix has exactly one claimant.

### Cross-release contention (the three open sibling pull requests at Commit 0)

| File | This release | `controls-fail-loud` (#7919, head `a3207e42`) | `ci-wiring-and-required-checks` (#8305, head `443acea5`) | `hook-walk-adjudicates-every-operand` (#8306, head `7301d635`) | Class · who lands first |
|---|---|---|---|---|---|
| `release/references/pipeline/stage-13-close.md` | #5185 and #5089 at Phase B-OPS | in its file list (the map places its insert after line 540) | in its file list (the map places its edits at 165 and 531) | — | append-pattern; any order — a `main` sync resolves it |
| `core/standards/gate-efficacy-standard.md` | four cards' rows after the class 3-O anchor row | in its file list (rows at 271 and 309, a tail append) | its Stage-4 matrix names it; not in its file list at head | — | append-pattern with a shared tail; any order |
| `release/references/how-to/hub-spoke-bridge.md` | #5089 (H1′, Procedure 3's restatement) | in its file list | in its file list | — | line ranges measured at #5089's slice; any order |
| `release/skills/release-hub/SKILL.md` | #4023 (the contract and its `version:` line) | in its file list (the `version:` line; the spawn-guard entry) | — | — | the `version:` line conflicts: whoever merges second takes the later claimed tag on that line |
| `packages/release-hub.skill`, `.sha256` | #4023 | rebuilt | rebuilt | — | binary — always conflicts: **rebuild after the `main` sync, never merge a package** |
| `release/ADRs/README.md` | #4022 (regenerated) | regenerated | — | — | derived surface: regenerate after the `main` sync; never hand-merge |
| the ADR number space | #5185's record at ADR-217 and #4022's at the next number after the branch's own claims | holds ADR-217 (core) and ADR-218 (release) as unmerged claims | — | conditional only (map) | duplicate at authoring, resolved at merge by `release/tools/renumber-adr.py`: the first to merge keeps its number |

**`hook-walk-adjudicates-every-operand` shares no matrix path** (0 of its 7 files). `telemetry-is-computable` merged as `v4.74`: its edits to five files this release also edits are now in the branch base.

---

## Cross-PR Overlap Audit

### Baseline SHA

**Stage-4 baseline pin:** `4babbba9` (`4babbba94f3ddf99a658d39fc0dbb7af0f664066`, 2026-10-08). **Branch base at Commit 0:** `20197085` (`201970851da959db01111ef155f2f96d6676bfeb`).

**Sibling-merge stale-pin trigger — run at Commit 0.** `git diff --name-only 4babbba9..origin/main` (61 commits, 39 files) intersected with the fenced path list of § File Change Matrix → **8 paths**: `core/standards/gate-efficacy-standard.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256`, `release/references/pipeline/stage-04-planning.md`, `release/references/pipeline/stage-13-close.md`, `release/references/standards/pipeline-event-log-schema.md`, `release/tools/append-pipeline-event.sh` and `release/tools/check-event-record-integrity.sh` — every one carried in by the `v4.74` merge. The milestone's Parallelization Map (recorded 2026-10-15 at `20197085`) records every edit anchor this release cites in those files as MATCH or MOVED and eight verification expectations as changed, none of them an edit anchor. Line numbers in this file are `4babbba9` positions; each slice re-anchors by content (DEV-37).

```
Probe:       git diff --name-only 4babbba9..origin/main, then an exact-line intersection with the
             35 matrix paths that exist or are this plan
Denominator: 39 changed files in the window; 35 matrix paths
Control - sensitivity: a path known to change in the window (release/releases/RELEASE_LOG.md) → 1
Control - specificity: NOT TRIGGERED — an exact-line intersection has no near-miss class
Extraction:  both lists read whole
Result:      8 intersecting paths
Verdict:     MEASURED — full population
```

### Open PRs and recently merged PRs

- **Merged since the Stage-4 pin:** `telemetry-is-computable` (#7901), merged 2026-10-09 and claimed `v4.74`; its hunks are in the branch base.
- **Open at Commit 0** (the open-PR list returned 3 of 3, all drafts): `controls-fail-loud` (#7919), `ci-wiring-and-required-checks` (#8305) and `hook-walk-adjudicates-every-operand` (#8306). The two newer ones opened their branches after the Stage-4 plan, which is risk R16 realised.

### Structural sub-audit

This release's mover set is **empty**: no file is renamed, relocated or deleted (population: the 39 matrix paths — 5 ADD, 34 EDIT, 0 deletes). Its structural surface is the version slot and the ADR number space; both are arbitrated at merge (§ Contention Map).

### In-Flight Release Roster

**Measured at:** `20197085` · 2026-10-16 · **Population:** n=3 siblings — open pull requests with a `release/*` head (drafts included), less this release; the three remote `release/*` heads besides this release's each carry a pull request.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `controls-fail-loud` | `#7919` | `a3207e42` | `minor` | `v4.70` | `v4.75` | `core/standards/gate-efficacy-standard.md`, `release/references/pipeline/stage-13-close.md`, `release/references/how-to/hub-spoke-bridge.md`, `release/skills/release-hub/SKILL.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256`, `release/ADRs/README.md` |
| `ci-wiring-and-required-checks` | `#8305` | `443acea5` | `minor` | `v4.74` | `v4.75` | `release/references/pipeline/stage-13-close.md`, `release/references/how-to/hub-spoke-bridge.md`, `packages/release-hub.skill`, `packages/release-hub.skill.sha256` |
| `hook-walk-adjudicates-every-operand` | `#8306` | `7301d635` | `minor` | `v4.75` | `v4.75` | none |

Recomputed next-free is a function of the bump-class and the claimed set, not of the release, so every `minor` release in flight reads `v4.75` today. This roster is a pinned measurement and carries **no verdict**; Stage 9 Phase A6.6 re-measures and renders it. `[SOURCE]`

---

## Integration Points

| # | Between | Shared surface | What must agree | Where it is checked |
|---|---|---|---|---|
| IP-1 | #5185 → #5089 | `core/disciplines/knowledge-architecture.md`, the boundary section's headings and ids | the sections #5089 names keep their headings and ids through #5185's rewrite | CIAC-1; INT-1 |
| IP-2 | #5185 → #5089 | `release/references/pipeline/stage-13-close.md` Phase B-OPS | #5185's text keeps the two links byte-identical; #5089 converts them to form D | CIAC-2; INT-2 |
| IP-3 | #4023 ↔ #4022 | the hub's per-emission contract and its package | one seam; one package rebuild; one decision narrative | CIAC-4; #4023's INT-1 as #4022 adopted it |
| IP-4 | #4220 ↔ #4022 | the event-type table's `scope-change` row and the writer's static mirror | the three tier subtypes stay extractable; the two-site lockstep holds | CIAC-3 (merged with #4220's INT-1) |
| IP-5 | #5089 → #5052, #5185, #5290 | every "this surface cites that one" pointer the release adds | one citation form (D), correct from every location the file is read from | CIAC-5; #5052's INT-1; #5290's INT-1 |
| IP-6 | #5089 ↔ #4023 | `core/CLAUDE.md.template` `:188`–`:190` | adjacent bullets edited by different cards stay intact — #4023 does not edit `:190`, so only #5089's `:188` changes | the diff at Stage 9 |
| IP-7 | #5290 ↔ the label-parity gate | the five live label descriptions | under B-3 no row is declared; the description written to the host equals the manifest's string | Stage 13 Phase B-OPS4 |
| IP-8 | this release ↔ three open sibling PRs | the files in § Contention Map and two binary packages | hunks stay disjoint; packages are rebuilt, never merged; the ADR numbers bind at merge | Stage 7 / 8 entry checks; Stage 9 Phase A6.5 |
| IP-9 | this release ↔ its own run | the deployed `release-planner` and `release-hub` skills | an edit made here changes behaviour only after the next deploy; the run does not depend on it | not a check — a planning constraint |

**Integration acceptance criteria adopted at the scope-lock** (one text per pair, so Stage 9 counts each triple once):

- [ ] **INT-1 (#5185 → #5089, on `core/disciplines/knowledge-architecture.md`, the boundary section's heading lines):** After #5185's rewrite the section carries exactly the headings and explicit ids it carried at the merge base — each once, none added — so every section #5089's converted citations name still exists under the heading text they name. *Gradable from PR content: the section's heading lines at head equal those at the merge base. Grades at Stage 8 Phase B under the standard per-criterion verdict enum.*
- [ ] **INT-2 (#5185 → #5089, on `release/references/pipeline/stage-13-close.md` Phase B-OPS — the shared end state):** The two paragraphs #5185 rewrites cite the boundary discipline through exactly two links. #5185's hunks add no link and no section-number token and leave both link substrings byte-identical to the merge base, so #5089 finds them by content; after #5089 both are in form D — a name label with no section number, over a plain file link with no fragment — and the stop-rule sentence #5185 appends refers to the section the preceding link names, inside which the archive-disposition rule sits. *Gradable from PR content: the two links and the appended sentence at head. Grades at Stage 8 Phase B under the standard per-criterion verdict enum.*
- [ ] **INT-3 (#5185 → #5089, on `release/references/how-to/memory-corpus-drift-audit.md`):** #5089's hunks leave the two lines #5185 edits exactly as #5185 wrote them, and after both cards no prose line of the file outside its fenced sample cites the authority's boundary section or its sub-sections by number. *Grades at Stage 8 Phase B.*
- **#4220's INT-1** is merged into CIAC-3 (one criterion for the triple); **#4023's INT-1** is adopted by #4022 with the amendments its design proposed (the record and its class per tag; "an operator-facing emission of the release hub"; "no second prose emission-time question"); **#5052's INT-1** and **#5290's INT-1** bind their citation sites to form D.

---

## Risk Register

Owner is the role that holds the mitigation. Severity is stated as likelihood × impact; no dates.

| # | Class | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|
| R1 | Scope | Stage 5 designed against card bodies Phase A0 found stale on six of seven cards | Discharged | — | `D-A0-Refinements` rendered at the plan gate; every design re-read its card after the edit | — |
| R2 | Contention | Three open sibling PRs touch files this release edits; two binary packages are touched by two of them and by this release | High (already true) | Low per file — hunks are disjoint; Medium for the packages | Place each card's rows as specified; sync `main` at Stage 7 and Stage 9 entry by merge, never by force-push; rebuild packages after every sync | Stage 6 / 7 spokes |
| R3 | Dependency | Four releases contend for the version slot `v4.75`, and **this release writes a version literal**: the `version:` fields of `release-planner` (#5185) and `release-hub` (#4023) carry `v4.75` — "nothing hard-codes the number" no longer holds (DEV-21) | High | Low–Medium — the claim is atomic; a lost slot leaves two fields naming another release's tag | Commit-0 re-verify; Stage-12 pre-merge freeness check; if the claim binds another number, a sanctioned re-edit of each `version:` field and a rebuild of its package ride the Stage-12 stamp chore | First Stage 6 spoke; Stage 12 spoke |
| R4 | Scope | #5185 removes the hosted-archive phase. The name appears in the phase list, a phase count, the absorption gate's input, two how-to lines, three floored operations-governance sentences and ADR-045's Decision item 4. A partial edit leaves the lifecycle half-renamed | Medium | Medium | Treat it as a delete-class reference cascade: the design's three invocations searched before and after over the same population, both counts recorded; the three floored sentences a named residual; ADR-045 superseded in part by the new record with its reciprocal pointer, its decision text intact (DEV-25) | Stage 6 and Stage 7 for #5185 |
| R5 | Scope | #5089's proposed link form did not deliver the criterion's promise | Discharged | — | Form D locked; AC-3 reworded; CIAC-2's method amended | — |
| R6 | Scope | #5052 direction (b) would reverse a recorded decision | Discharged | — | Direction (a′) locked | — |
| R7 | Rollback | #5290's label descriptions are repository state; a reverted commit does not un-write them | Certain if AC-6 runs | Low — the pre-state is five empty strings | Run post-merge from the manifest, operator-authorized, with the pre-state recorded; the inverse is the same call with an empty description | Operator at Stage 13 |
| R8 | Scope | #5290 AC-3, authored literally, fails a required gate (issue references outside a reference block) | Discharged | — | Criterion reworded at the plan gate; the examples' numbers sit in a `## References` block | — |
| R9 | Scope | #4022's enforcement pulled into this release would raise the bump-class and enter the most contended files | Discharged | — | (C) locked; the implementation is the follow-on story (#8375) | — |
| R10 | Dependency | Sanctioned-session writes: two certain (the release-plan template and the hub contract), each needing the skill-editor path, its commit trailer, a version-field edit and a package rebuild | Certain | Low–Medium | The Commit-0 pre-flight (PROCEED); one package commit per skill after its last edit; the package-freshness and audit-trail deploy checks run at Stage 7 | Stage 6 spokes |
| R11 | Scope | The deployed `release-planner` and `release-hub` skills do not change until the next deploy | Certain | Low | Verify each edit by reading the source and, for #4023, by a sample turn at Stage 7 | Stage 7 spokes |
| R12 | Capacity | The usage window is shared by several concurrent release sessions | High | Medium — a deferred launch, not lost work | One spoke in flight; Checkpoint B at every launch; commit-channel spokes push after every coherent commit | Hub |
| R13 | Scope | Re-classification raised ceremony on a release bundled as `routine` | Discharged | — | Rendered at the plan gate (`cross-cutting`, Standard density) | — |
| R14 | Scope | New durable-corpus text trips the reference-durability, issue-reference, operator-memory-reference or depersonalization gates | Medium | Low–Medium | Prose-first authoring; numbers confined to reference blocks; no store path, entry file name or identity string on an added line; this plan carries no markdown link | Stage 6 spokes |
| R15 | Scope | Over-building the #4023 forcing function into a new mechanism | Discharged | — | E1 locked: a named-gap row and the existing seam | — |
| R16 | Contention | Siblings still in planning at Stage 4 name files this release edits once their matrices exist | **Realised** — two now carry pull requests | Low–Medium | § Contention Map at Commit 0; Stage 9 Phase A6.6 re-measures | Stage 9 spoke |
| R17 | Dependency | The ADR number space: this release authors two records while `controls-fail-loud` holds ADR-217 and ADR-218 as unmerged claims | Certain at authoring | Low — the renumber tool resolves a duplicate at merge; a gap is the expensive failure | Number from `python3 release/tools/renumber-adr.py --next-free` against the mainline anchor, in Stage 6 order; never step above a branch claim; cite the records by slug token in prose; bind at merge (DEV-29) | Stage 6 spokes; Stage 12 spoke |
| R18 | Capacity | This release's Stage 6 launched under an operator override of a quota-budget DEFER; an interruption at the usage limit can strand a slice mid-edit | Medium | Low — banked commits survive | Push after every coherent commit; a re-spawn resumes from the release branch (DEV-11) | Stage 6 spokes; hub |

**Rollback complexity in one line:** every in-repo change reverts with its commits; the only action that does not is the five label descriptions, whose inverse is recorded. No memory eviction is scheduled. `[SOURCE]`

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Topology** | D-C SINGLE — one branch, `release/authoring-conventions-enforced-or-retired`, cut from `origin/main` at `20197085` when Stage 6 opened |
| **Implementation approach** | Sequential, posture P0: one Engineering spoke at a time, in § Implementation Sequence order |
| **Pull request** | One draft release PR, opened after the first card commit. Title in the governed grammar: `release(authoring-conventions-enforced-or-retired): <imperative summary>`. Milestone, labels and assignee set at creation |
| **Issue References block** | **All seven cards are carried as plain references** (`References #N`) in the PR body's Issue References block; each is transitioned to closed at Stage 13. No close-family verb sits next to an issue number anywhere in the PR body, and none in any commit message (DEV-30) |
| **Commit order** | Commit 0: this file (after the version re-verify; the stamp-manifest assertion runs after the write and before the commit). Then one or more commits per card in sequence. Each skill's package in its own commit after the last edit to its tree. Then verification-evidence commits |
| **Commit messages** | `release(authoring-conventions-enforced-or-retired): <description> (#N)`; a mid-flight minor correction carries the `[ADJUST]` tag — the convention this release adjudicates is honoured while it stands |
| **Skill-tree edits** | Each through `pmo-skill-editor` Mode A in a sanctioned session minted by `core/deploy/tools/start-skill-editor-session.sh`, with the `Skill-Editor-Audit-Trail:` trailer: the release-plan template and `release-planner`'s `version:` field (#5185); the hub contract, its briefing reference and `release-hub`'s `version:` field (#4023) |
| **Where each package rebuild lands** | `release-planner` after #5185's session; `release-hub` after #4023's session. Each is rebuilt again after any `main` sync that brings in a sibling's change to the same tree — a package is never merged |
| **Mainline sync** | `git fetch origin main` then `git merge origin/main` on the release branch at Stage 7 entry and Stage 9 entry, and whenever a sibling in the roster merges. Never a force-push |
| **Review approach** | Single PR for the whole release; the diff is the dry run; Stage 9 review depth Deep |
| **Deployment mechanism** | Git merge, the standard skill deploy for `release-planner` and `release-hub`, and the manifest under § Operational Deployment Manifest |
| **Stage 12** | The atomic claim is passed the stamp slug explicitly — other in-flight plans carry an unresolved stamp at the plans root, so derivation would be ambiguous and would decline. The claim's ADR step binds the two records' numbers (`renumber-adr.py --detect`, then reconcile if needed, then `--stamp`, then `--stamp --check`) |
| **Stacked-base cleanup posture** | N/A — a single branch has no stacked base |
| **Stage 12 / 13 chore pull requests** | The ledger row, index, digest and release notes are written there, not in the release PR |

---

## Verification Plan

Every method cell carries its probe literally, reproducible from the cell alone. A method whose command is a `bash …` tool run is not executed by the plan-driven executor `release/tools/verify-release-plan.sh`, whose runnable-verb set is closed to read-only queries by design; such a row reads SKIP there, and its guarantee lives in the tool's own CI-invoked self-test. Rows marked `[DEFERRED — …]` name the stage and surface that grade them; each card's Stage-6 spoke promotes its own deferred rows by Tier 1 `[ADJUST]` when its locked text fixes a literal. The issue bodies stay historical: the scope-lock's readings are carried in the bound rows below (DEV-31).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #4022 | AC-1 | `grep -c -i -F "signal-tag disposition" release/governance/release-process.md` at least 1 [READER-GRADED — the paragraph names the selected option, (C) restate the binding surface, and its rationale; graded at Stage 8 with the Collective Review decision record on the card] | at least one match; baseline 0 |
| #4022 | AC-2 | `grep -c -i -F "signal-tag disposition" release/governance/release-process.md` at least 1 [READER-GRADED — for each tag the paragraph names the record it binds and that record's class in the rubric's terms, and its runner label states that no gate executes it] | at least one match; baseline 0 |
| #4022 | AC-3 | `git ls-files "release/ADRs/*signal-tags-bind-durable-surfaces.md"` names one path [READER-GRADED — the follow-on story is filed (#8375) and its number sits only in the record's `## References` block with a summary phrase] | one path; baseline none |
| #4022 | AC-4 | [DEFERRED — graded at Stage 8 by reading the disposition paragraph and the record's `source_observations:`: the adherence measured on the declared surfaces, with numerator, denominator and surface for each tier, corrected for both event families, and why the conversational-turn sample does or does not bear on it] | the statement is present and names its denominators |
| #4023 | AC-1 | [DEFERRED — graded at Stage 8 from the Collective Review decision record on the card (fork (b), runner E1, the disposition "restated with the surface it binds"), with the structural half read from the hub contract at head: the evidence-label requirement, its emission-time question, its failure-mode entry and the named-gap register row] | branch (b) recorded; the structural half present |
| #4023 | AC-2 | [DEFERRED — promoted at #4023's slice to a count of the rubric's class terms in `release/skills/release-hub/SKILL.md` (the design's V-4 pair), after the review's correction to the surface clause; until then graded by reading] | the bound surface class is named in the rubric's terms |
| #4023 | AC-3 | `grep -c -F "Evidence quality labels" core/CLAUDE.md.template` expect 1 [READER-GRADED — the bullet, the hub requirement and the rubric state the same conversational-turn expectation] | exactly one bullet; baseline 1 |
| #4023 | AC-4 | [DEFERRED — graded at Stage 8 by reading the hub contract for the restated baseline with its denominator and the one-sentence target; the outcome read is the follow-on story's (#8376), in the release's 30-day window] | both present in the host |
| #4220 | AC-1 | `grep -c -F "column-3 parenthetical seed" release/tools/append-pipeline-event.sh` at least 1 | the seeded arm exists under that label; baseline 0; observed failing on the unnarrowed parser and passing after the narrowing (the slice's in-place mutation proof) |
| #4220 | AC-2 | `bash release/tools/append-pipeline-event.sh --self-test` [the validator's own self-test, `bash release/tools/check-event-record-integrity.sh --self-test`, runs beside it] | both PASS; the writer's lockstep line reads OK in both directions at the count the same self-test prints on the merge base, and the validator prints the new arm's named OK line; each new arm fails when its parser's narrowing is reverted |
| #4220 | AC-3 | `grep -c -F "Column 3 authoring constraint" release/references/standards/pipeline-event-log-schema.md` expect 1 | exactly one note, whose line carries no pipe character; baseline 0 |
| #5052 | AC-1 | `grep -c -w -F "enterprise-platform" core/specs/domain-token-registry.md` expect 0 [READER-GRADED — the schema holds the one list at its `deliverable_type` field reference and the registry cites it] | 0 · baseline 1 · control: `grep -c -w -F "task-artifact" core/specs/domain-token-registry.md` → 1 |
| #5052 | AC-2 | [DEFERRED — graded at #5052's slice by the region-scoped two-hop probe review #8283 A-3 specifies, with the baseline as its sensitivity arm: each of `security`, `support` and `task-artifact` is reached from both entry points] | both entry points agree on all three |
| #5052 | AC-3 | [DEFERRED — graded at Stage 8 by reading the registry's Concept 1 row under the grading note D-5052-AC3 records: the row states which surface holds the named-class list, no sentence in it or in the § 4 `deliverable_type` row names a different surface as that list's authority, and the Owning-file cell still names the owner of the `domain:` field] | the named authority is the surface that holds the list |
| #5052 | AC-4 | [DEFERRED — a before-and-after census over the population the design fixes (`core` and `release/references/pipeline`, decision records excluded), each remaining line classified; the third Stage-4 list is a retained example; review A-4's key-value arm is added] | no new copy · baseline 11 lines in 8 files at the Stage-4 pin |
| #5089 | AC-1 | `grep -c -F "## §7 Memory↔corpus boundary" core/disciplines/knowledge-architecture.md` expect 1 | one heading; baseline 1 — the section is § 7 |
| #5089 | AC-2 | `grep -c -F "knowledge-architecture.md) § 6" core/standards/gh-api-convention.md` expect 0 [READER-GRADED — the Stage 7 corpus sweep states its denominator and its residual for every other live citing file under population P3] | zero · baseline 1 · control: `grep -c -F "knowledge-architecture.md" core/standards/gh-api-convention.md` → 4 |
| #5089 | AC-3 | [DEFERRED — graded at Stage 7 under the reworded criterion (D-5089-AC3 with review #8277's method correction): converted citations name the cited section by its heading text, delimited, with no section number in the label or the link and no fragment; the method counts the cited family's section-number tokens on the converted lines, adds one name-resolution row per cited heading, seeds the guard probe with one must-flag line, and reads the charter template with the doc-link primitive] | zero section-number tokens of the family on converted lines; every named heading resolves |
| #5185 | AC-1 | `grep -c -i -F "archive disposition" release/skills/release-planner/references/release-plan-template.md` at least 1 [READER-GRADED — the entry format states the disposition where the entry is authored: `none` by default, `operator-local` only where the operator elects it, and no value that names a public surface] | at least one; baseline 0 · control: `grep -c -F "Operational Deployment Manifest" release/skills/release-planner/references/release-plan-template.md` → 1 |
| #5185 | AC-2 | `grep -c -F "pasted verbatim into the Stage-13" core/disciplines/knowledge-architecture.md` expect 0 | zero · baseline 1 · control: `grep -c -F "VERIFY-CORPUS" core/disciplines/knowledge-architecture.md` → 8 at the branch base |
| #5185 | AC-3 | `grep -c -i -F "memory-eviction entry" release/skills/release-planner/references/release-plan-template.md` at least 1 [READER-GRADED — the worked example carries artifact, trigger, executor and archive disposition, and enumerates the evicted entries by tie: one all-or-nothing row per tie with its planned count] | at least one; baseline 0 |
| #5185 | AC-4 | `grep -c -F "Layer-1 → Layer-2 boundary" release/skills/release-planner/references/release-plan-template.md` at least 1 — promoted from deferred by the Stage-5 design [READER-GRADED — the format itself names the boundary] | at least one; baseline 0 · control: `grep -c -F "Layer 2" release/skills/release-planner/references/release-plan-template.md` → 2 |
| #5290 | AC-1 | [DEFERRED — promoted at #5290's slice to five fixed-string counts on the doctrine, one per class row of the size-class table (the design's contract row 1)] | each of the five classes present once |
| #5290 | AC-2 | [DEFERRED — graded at Stage 8 by reading the five class rows: each names at least one non-point observable] | five of five |
| #5290 | AC-3 | `grep -c -E "^## References[[:space:]]*$" release/references/standards/bundle-composition-doctrine.md` expect 1 [READER-GRADED — the reference block carries the worked examples' issue numbers, two per class, each with a summary; each cited issue reads closed on the host; the issue-reference validity check over the branch range exits 0] | 1; baseline 0 |
| #5290 | AC-4 | `grep -c -F "Apply size label per label-taxonomy.md" core/schemas/gate-criteria-spec.md` expect 0 [READER-GRADED — both G3-09 sites cite the doctrine's rubric section] | 0 · baseline 2 · control: `grep -c -F "G3-09" core/schemas/gate-criteria-spec.md` → 12 |
| #5290 | AC-5 | `grep -c -E "^Total story points .*assignment rubric" release/references/standards/bundle-composition-doctrine.md` expect 1 | 1 · baseline 0 · control: `grep -c -E "^Total story points" release/references/standards/bundle-composition-doctrine.md` → 1 |
| #5290 | AC-6 | [DEFERRED — repository state written after merge from § Operational Deployment Manifest, entry 2; graded at Stage 13 Phase B-OPS4 by the label read] | five rows, each with a non-empty description of at most 100 characters stating the class's points and anchor in words, without cut-point numerals while the cut points are held as seeds; baseline five empty |
| #5290 | AC-7 | [DEFERRED — run at Stage 7 as the ex-ante backtest review #8286 CD-1 specifies: shut issues from fully covered milestones, stratified by delivered band and drawn by issue number; two independent raters on a history-free tree export; rater-against-rater and rater-against-delivered agreement, with each miss's direction] | at least 7 of 10 exact and 10 of 10 within one class (the criterion's bar); the backtest's readings recorded beside it |

**AC baseline** (re-read at Commit 0; unchanged in number since the Stage-4 pin — the plan-gate refinements and the scope-lock add or remove no criterion):

`ac_baseline: { #4022: 4, #4023: 4, #4220: 3, #5052: 4, #5089: 3, #5185: 4, #5290: 7, read_at: 20197085 }`

Coverage: 29 rows for 29 criteria, in each card's list order. No row restates its criterion. `[SOURCE]`

### Release-Level Verification

- [ ] **File integrity** — the release diff touches only paths in the fenced matrix; a scope assertion at Stage 9 over the non-scope block: `git diff --name-only origin/main...HEAD -- core/deploy/deploy.sh core/governance/OPERATIONS.md core/ADRs/ADR-029-memory-corpus-ssot-boundary.md core/ADRs/ADR-050-deliverable-domain-axis.md` expect 0. ADR-045 is no longer in this assertion: its reciprocal pointer is a declared EDIT (DEV-25).
- [ ] **Content correctness** — the five cross-issue criteria; both tools' self-tests (#4220); the plan verifier over the committed plan, including its CIAC lint.
- [ ] **Cross-reference validity** — the link checker over the touched files, anchors included; the doc-link primitive over the governed scope; the plan-depth lint on this file.
- [ ] **Source-to-deployed** — `bash core/deploy/deploy.sh --check`: read package freshness (Check 7), the editor audit trail (Check 10), doc links (Check 14) and register runner resolution (Check 62) from that run.
- [ ] **Gates on the PR** — reference durability, issue-reference validity, dead file reference, depersonalization, operator-memory reference, PR-title convention, parser-clean body, ADR number integrity and ADR durability.
- [ ] **Reference cascade (#5185)** — the removed phase name searched before and after over the same population, both counts recorded: `git grep -n -w -F "ARCHIVE" -- .`, `git grep -n -i -F "archive-first" -- .` and the wide net `git grep -n -i -e "archive" --and -e "evict" -- .`, each classified by reading every line (the design's Cascade-Sweep, part 2); the live-lifecycle class falls to the named residual only.
- [ ] **Register (#5185)** — `grep -c -F "archive-disposition" release/references/pipeline/stage-13-close.md` reads exactly 1 (the stop-rule sentence), and Check 62 reads CLEAN with one more pointer than at the branch base.
- [ ] **Deliverable-class invariant (#5052, (a′))** — every shipped guide's domain under `core/standards/domain-best-practices/` appears on the schema's list line; the branch base reads 4 of 6, which is the row's sensitivity arm.
- [ ] **Decision records** — `python3 release/tools/check-adr-numbers.py`, `python3 release/tools/generate-adr-index.py --verify` → `COUNT 0`, and the ADR durability lint over both new records.
- [ ] **Domain provenance** — the `domain_practice` label survives in this file (Stage 7 checks presence and the in-label class).

---

## Cross-Issue Acceptance Criteria

Five release-scoped cohesion constraints. None rides a dependency edge. Graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5185 × #5089 on `core/disciplines/knowledge-architecture.md` § 7 heading):** After #5185 rewrites the encode-and-evict lifecycle, the boundary section that #5089's citations target still exists exactly once under its stable heading and id. *Method:* `grep -c -F "Memory↔corpus boundary {#memory-corpus-boundary}" core/disciplines/knowledge-architecture.md` expect 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5185 × #5089 on `release/references/pipeline/stage-13-close.md` § Phase B-OPS):** The Phase B-OPS text #5185 rewrites cites the boundary discipline in the form #5089 standardizes — a name label carrying no section number, over a plain file link with no fragment — rather than by a bare section number. *Method:* `grep -c -E 'knowledge-architecture\.md. § [^0-9][^]]*\]\([./]*core/disciplines/knowledge-architecture\.md\)' release/references/pipeline/stage-13-close.md` at least 2. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#4220 × #4022 on `release/references/standards/pipeline-event-log-schema.md` § 3 `scope-change` row and the writer's static mirror):** After both cards, each of `tier-1-adjust`, `tier-2-scope-change` and `tier-3-plan-rejection` is written in that row's column 3 as a backticked token outside every parenthetical span, so the narrowed parser still extracts all three; each stays on the writer's static-mirror line, which the writer's own lockstep assertion holds to the extracted enum in both directions on every CI run. A retirement, if a later story chooses one, changes the row there and not here. *Method:* `grep -c -E '^. .scope-change. [^(]*.tier-1-adjust. / .tier-2-scope-change. / .tier-3-plan-rejection.' release/references/standards/pipeline-event-log-schema.md` expect 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#4022 × #4023 on the hub's engagement contract):** The two convention dispositions name the surface each binds in the rubric's own class terms, and where both select enforcement they extend one seam rather than two parallel mechanisms. *Method:* declared, verification deferred to #4022 AC-2 and #4023 AC-2. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#5089 × #5052 × #5185 × #5290 on the cross-reference form):** Every cross-reference this release authors from a citing surface to a section of another document uses the single link form #5089's design selects, so the three cards that add a "this surface cites that one" pointer do not reintroduce a bare section number. *Method:* declared, verification deferred to #5089 AC-3, #5052 AC-1, #5185 AC-1 and #5290 AC-5. *Graded at Stage 9 QC3.5 on the merged PR.*

**Amendments at the scope-lock** (DEV-18, DEV-19). CIAC-2's method now asserts the criterion's two halves in one command — a name label with no section number, over a plain file link — where it counted a substring that passed on two fragments resolving nowhere and would read 0 under form D (review #8277 FM-4). It reads 0 at the branch base and 2 once #5089 converts the two links, so it is a target the integrated release must reach rather than a guard. CIAC-3's method is #4220's INT-1 assertion, where it counted one subtype's substring (review #8280 FM-5): the row's column 3 must open with the three tier tokens, with no opening parenthesis anywhere before them on the row, so a token moved inside a parenthetical or dropped fails it; the static-mirror half is the writer's lockstep, which the plan-driven executor does not run (it runs no `bash` tool) and CI does. The triple is now counted once. CIAC-1 and CIAC-3 each read 1 at the branch base and are guards; a seeded conforming row reads 1 under CIAC-3's pattern and two near-misses — the tokens inside a parenthetical, and one token missing — read 0.

**Lint record (Gate 4 criterion G4-06), re-run on this file at Commit 0:** § Verification Evidence.

---

## Quota Budget

**Verdict:** PASS for the serial posture the hub declared (one spoke in flight), per `quota-budget-protocol.md` Checkpoint A, recorded at Stage 4. A parallel wave is not budgeted: width 2 reads WARN and width 3 or more reads FAIL against a shared-window envelope.
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 7 designs + 7 adversarial reviews · Stage 7: 7, plus the backtest raters for #5290 AC-7 · Stage 8: 7.
**Per-spoke cost estimate:** about 5% of one five-hour usage window per planning or stage spoke (hub-supplied prior-run calibration), treated as a floor — the planning spoke itself drew roughly 2.8 times that figure.
**Assumed/stated remaining usage-window envelope:** stated per launch by the hub; this Stage-6 launch was taken under an **operator override of a Checkpoint B DEFER** — the usage window read 66% and rising at 23:36Z on 2026-10-15, the host API read PROCEED, `W_max` 1 (DEV-11).
**Estimated cumulative draw % (worst parallel batch):** not applicable to the serial posture; the Stage-4 table (width 1: 5% of a window) stands.
**Routing:** PASS → proceed, one spoke at a time; a wave is admitted only if Checkpoint B returns PROCEED at that launch.
**Aggregate launches (a capacity figure, not a schedule):** Stage 5 × 7, Stage 5 Phase A6.5 × 7, Stage 6 × 7, Stage 7 × 7 plus the backtest raters, Stage 8 × 7, and one each for Stages 9, 12 and 13 — **40** launches after Stage 4, the Stage-4 figure of 33 corrected for the seven adversarial reviews it omitted (DEV-24). The run spans window resets by construction; the hub's resume pointer is refreshed at every gate.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton, and gates on the host-API quota as a second axis combined DEFER-dominant (§ 4.3b). Bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`cross-cutting`** — re-classified from `routine` at the Stage-4 plan gate (operator, 2026-10-09). Trigger (b) fires: the File Change Matrix changes three of the six rule-defining surfaces — `release/governance/release-process.md` (#4022), `core/schemas/gate-criteria-spec.md` (#5290) and the charter template `core/CLAUDE.md.template` (#5089). With #5052's T1 rendered, trigger (a) now fires as well: three `pipeline/stage-*.md` files are in the matrix (`stage-04-planning.md`, `stage-07-dev-testing.md`, `stage-13-close.md`). The `novel` trigger (b) also fires (five design decisions); the highest-ceremony fired class governs.

- **Differentiation posture:** Engagement density **Standard** (an operator override of the class default, Tight: all five design decisions converged on one Collective Review, so per-spoke briefings add no decision surface) · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.
- **Size bound:** `effective_pts: raw 18 × 1.3 = 23.4 → 23 (round-half-up) — within band 15-25`.
- **History:** `routine` (as bundled) → `cross-cutting` (Stage-4 gate).

---

## Release Outcome Statement

The operator-approved statement, verbatim from the milestone description:

**AFTER** — Each of the seven authoring conventions this release names has a recorded disposition a reader can check: it is enforced by a mechanism that fails or warns, restated with the surface it binds, or explicitly retired. For the signal-tag convention the enforce-or-retire decision is recorded with its rationale and its follow-on story filed; carrying that decision out is the story's work.

**BEFORE** — Seven conventions are declared in the corpus and not reliably followed, with no disposition either way: signal tags appeared on 18.8% of the conversational turns an audit sampled and formal evidence labels on about 4%, and five more — a section citation, a named-value list, a parser's authoring constraint, an archive destination and a size label — each exist in two disagreeing forms or with no stated rule.

**Actor(s):** hub + the class-appropriate spokes; the operator renders five design decisions at the Collective Review scope-lock.

**Success Indicator:** at Stage 13 every one of the seven cards' recorded dispositions is present on `main`, and the three command-graded cross-issue criteria read MET.

The three command-graded criteria are CIAC-1, CIAC-2 and CIAC-3, each amended or kept at the scope-lock (§ Cross-Issue Acceptance Criteria).

---

## Evidence Grounding

Each Stage-5 design carries its own Evidence-Grounding block on its sub-task, and the plan does not restate them. The #5185 canonicalizations are transcribed here because the scope-lock changed two of them, and Stage 6 implements the locked form.

| # | Canonicalization (#5185) | Design's canonical choice (#8195) | Locked form (the scope-lock) |
|---|---|---|---|
| 1 | The memory-eviction entry format and how an entry is identified | one row per entry, identified by tie, corpus home and `k of n` | **one all-or-nothing row per tie** (review CD-1): the tie, every corpus home and every probe the card writes, and the planned count of ledger rows citing the tie; no row binds to one particular entry, so nothing reads entry content at the irreversible step. Survey: 8 of 222 plans schedule an eviction, in six shapes (design part 2) |
| 2 | The archive-disposition value set | a closed set with no public member; membership the operator's | **`{none, operator-local}`** under option C — `none` the default, `operator-local` where the operator elects it for a row; the closure and the exclusion of any public value are the design's |
| 3 | The sub-section heading | `### Memory Evictions (if applicable)` — the plural-noun, parenthetical-condition form of its one sibling, `### Schema Migrations (if applicable)` | unchanged |
| 4 | The executor phase chain | `VERIFY-CORPUS → EVICT → RE-POINT` at all three sites | unchanged — the hosted copy is not a phase under C either, because an elected copy is the operator's act ahead of EVICT, not an executor phase |

**Survey re-read at the branch base.** The four files the canonicalizations touch carry the Stage-5 baselines unchanged at `20197085`: the template reads 0 for the entry format's three probe strings, the discipline reads 1 for the public-vehicle sentence and 8 for its control (§ Verification Plan). `[SOURCE]`

---

## Tier-A Activated Design Artifacts

A declaration names its marker in prose rather than reproducing it, so this file is never counted as a marker's host.

| Card | Artifact path | Flow class | Trigger | Tier | G-CL6 obligation |
|---|---|---|---|---|---|
| #5185 | `release/skills/release-planner/references/release-plan-template.md` § Memory-Eviction Entry Contract — its data-flow marker, name `memory-eviction-manifest-entry`, depicting the template, the discipline and the Stage-13 spec, is authored in slice 1 | data-flow | a contract added to an output-format file, with one producer (Stage 4 planning) and consumers (the Stage-13 executor; the hub at the Tier 1 authorization) — `core/standards/design-artifact-standard.md` § 7, data-flow row | A — new | Stage 13 G-CL6 confirms the section exists on the branch with its marker and a non-trivial diff, and that every path it depicts resolves |
| #5290 | `release/references/standards/bundle-composition-doctrine.md` § 3 Step 5 — the size-class table, marker name `size-class-assignment`, authored in slice 5 | decision-tree | a class-to-routing table cited as canonical by a gate and five labels | A — new | listed here; read at Stage 13 |
| #4220 | **Tier-B determination (owed at Commit 0): NOT ACTIVATED.** The schema's § 3 carries the data-flow artifact `pipeline-event-row-identity` (added by `telemetry-is-computable`, now in the base), depicting the writer, the front-cluster reader and the Stage-4 and Stage-5 specs | — | #4220 narrows the writer's column-3 enum extraction (no subtype enters or leaves the enum; every producer→consumer pair the artifact depicts is unchanged) and adds one paragraph of authoring guidance inside the § 3 region — content the artifact does not reflect, of the single-file additive-prose class `design-artifact-standard.md` § 7 exempts | — | none; slice 3 re-confirms when it edits the region `[INFERRED — read of the artifact and the design at the branch base]` |
| #5052 | **Tier-B determination: NOT ACTIVATED.** `stage-04-planning.md` carries no marker; the schema artifact above depicts it only as a producer of its § 11 emission. `stage-07-dev-testing.md` carries two process artifacts, at its iteration loop and its QA return | — | #5052's edits are the § 5.7 example and guide lists in the Stage-4 spec and the `:69` example list in the Stage-7 spec — outside every depicted region | — | none `[INFERRED — the markers' regions read at the branch base]` |

#5089, #4023 and #4022 declare no artifact (their designs' activation checks ran; #5089's change is the doc-cleanup class).

**Existing artifacts in the write set, not refreshed:** the discipline's concept model and its `evict-execution-path` flowchart (the flowchart's declared region starts after VERIFY-CORPUS has passed and is not edited — design part 1, Design artifacts); the Stage-13 spec's close-class decision tree and its Layer-1 dual-write sequence (the Phase B-OPS paragraphs lie outside both).

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback method | Complexity |
|---|---|---|
| #5185 | revert its commits; then rebuild the `release-planner` package. A merged, numbered record is never deleted: a revert after merge deprecates it | Low–Medium — #5089 is authored on top of it in three files |
| #5089 | revert its commits | Low — label and link edits, one rule paragraph and its alignments |
| #4220 | revert its commits | Low — two tools and two fixtures, isolated; the self-tests prove the reverted state |
| #5052 | revert its commits | Low — declarative files, no runtime reader |
| #5290 | revert its commits; **separately** restore the five label descriptions to empty if the post-merge step has run | Low in-repo; one extra operator call for the labels |
| #4023 | revert its commits; rebuild the `release-hub` package | Low–Medium |
| #4022 | revert its commits; the follow-on story stays open and is re-pointed or shut by the hub | Low |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|---|---|---|
| **Partial revert** | one card's change is wrong and isolated | revert that card's commits on a fix branch, through a PR; rebuild affected packages |
| **Full restore** | systemic failure after merge | revert the merge commit through a PR; re-run the skill deploy; restore the label descriptions. The version tag is **retained and recorded** as claimed-then-withdrawn — it is never deleted |
| **Forward fix** | a minor, well-understood defect | fix branch and PR; the default for anything found after Stage 13 |

**Rollback-infeasibility statement.** Nothing in this release is IRREVERSIBLE. The label descriptions are the only state a `git revert` does not restore, and their inverse is one recorded call (MODERATE at worst, CHEAP in practice). The two decision records are reversible by a later superseding record. `[SOURCE]`

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `release/skills/release-planner/` + `packages/release-planner.skill` (#5185); `release/skills/release-hub/` + `packages/release-hub.skill` (#4023) | the user-local skills mirror + the Cowork install | the standard skill deploy for each skill, plus the package build | `./deploy.sh --check` Checks 1, 2, 7, 12 and 13 read clean for both skills |
| 2 | the five `size:*` label descriptions (#5290 AC-6) | repository state on the host | under B-3, five literal label-edit calls whose strings come from the merged rubric — each the class's point value and anchor in words, without cut-point numerals while the cut points are held as seeds; pre-state recorded as five empty strings | the label read returns five size rows, each with a non-empty description of at most 100 characters |
| 3 | the composed workspace charter from `core/CLAUDE.md.template` (#5089's `:188` label) | the operator workspace's charter | the composition surface's regeneration (`./update.sh` or `./deploy.sh --deploy`) | the composed charter carries the converted label · listed by #5089's design at the hub's discretion and recommended as owed by its review (#8277); the hub confirms at Stage 12 |

**Memory eviction: none scheduled by this release.** #5185 defines the rule and encodes no memory entry of its own — enumerated over the entry classes {skill copy, schema migration, content sync, memory eviction, repository-state write}: classes 1 and 5 present, plus the charter composition; memory eviction absent.

**`deliverable_state: deployed-copy-synced`** — reached at Stage 12 when entry 1 verifies by content.

### Schema Migrations

N/A — enumerated over {event-log columns, the subtype enum, the payload registries, the RELEASE_LOG field grammar, the label grammar}: #4220 leaves the enum's membership unchanged, #5052 changes a list's home and not its values' shape, and #5290 declares no label row.

---

## Stage 9 Disclosures

The residuals this release names and does not close, stated so the Stage-9 goal-conformance check reads them as disclosed, not missed.

| # | Residual | What stays true after merge | Source |
|---|---|---|---|
| 1 | **The CORRECTIONS instance's own archive step** | `core/governance/OPERATIONS.md` (`:695`, `:703`, `:709` at the Stage-4 pin) still describes an archive step ahead of eviction, and two of its sentences cite the knowledge lifecycle's former archive-first posture by analogy; the file is Tier-0-floored and its CORRECTIONS step needs its own decision | D-5185-PHASE-REMOVED (i); design #8195 gap G2 |
| 2 | **Entry content on a hosted surface** | No gate reads a hosted body for entry content; the prohibition is reviewer-detected there and on tracked files alike for content (a tracked file's gate matches an entry's *name shape*) | D-5185-VALIDATION = V-A; V-B and V-C are follow-ons |
| 3 | **Recoverability is bounded by the Trash** | An eviction made under the default disposition is recoverable until the operator's Trash is emptied, and not after | D-5185-ARCHIVE basis; design Q1 |
| 4 | **#5089's frozen residual** | two Accepted decision records and the terminal release records keep their section-number citations; the shell-string citations in `core/deploy/deploy.sh` are correct and not markdown | the card's amended AC-2 |
| 5 | **#5290's cut points** | the rubric's numbers are seeds until the ex-ante backtest has run | the scope-lock |

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **#5185 criterion refinements** at the plan gate: Affected Files make the discipline primary and add the template and the how-to; AC-3 requires enumeration by tie, not by content; the coordination with the eviction-blocker card is struck as discharged | D-A0-Refinements (Stage-4 plan gate) | **APPLIED** to the body, with its `[BUNDLE AMENDMENT]` comment |
| **DEV-2** | **#5089 criterion refinements:** AC-2 scoped to live, mutable surfaces with the frozen residual named and the second population added; AC-3's method reworded to the gate's own resolver | D-A0-Refinements | **APPLIED** |
| **DEV-3** | **#4220 criterion refinement:** AC-2's first alternative reworded to "exclude every parenthetical span, then extract" | D-A0-Refinements | **APPLIED** |
| **DEV-4** | **#5052 criterion refinements:** AC-1 records what direction (b) would cost; AC-2 names all three missing values; AC-3 covers the Owning-file cell; AC-4 becomes a before-and-after census over a stated population | D-A0-Refinements | **APPLIED** |
| **DEV-5** | **#5290 criterion refinements:** AC-3's examples described by their properties with their numbers in a reference block; AC-6 assigned to an operator-authorized post-merge step; two line citations refreshed | D-A0-Refinements | **APPLIED** |
| **DEV-6** | **#4023 criterion refinement:** AC-1's standing position is (b), (a) admissible only as a recorded reversal; AC-4's mechanism host to be selected at Stage 5 | D-A0-Refinements | **APPLIED** |
| **DEV-7** | **#4022 criterion refinements:** a third option (C) added to AC-1's set; AC-3 states the filer and the moment of the follow-on story; AC-4 measured on the declared surfaces | D-A0-Refinements | **APPLIED** |
| **DEV-8** | **Re-classification `routine` → `cross-cutting`**, engagement density Standard as an operator override of Tight | D-ReleaseClass (Stage-4 plan gate) | **APPLIED** — § Release Class declaration |
| **DEV-9** | **The corrected Release Outcome Statement** replaces the declared one | D-OutcomeStatement | **APPLIED** — § Release Outcome Statement |
| **DEV-10** | **D-Version re-render `v4.74` → `v4.75`** at the Collective Review scope-lock (`telemetry-is-computable` claimed `v4.74` at its merge on 2026-10-09); the Commit-0 version half re-verified `v4.75` free and equal to next-free | The scope-lock record (release-level) | **APPLIED** — § Commit-0 Version Re-Verify Record |
| **DEV-11** | **This Stage-6 launch ran under an operator override of a quota-budget Checkpoint B DEFER** (`quota-budget-protocol.md` § 4.5): the usage window read 66% and rising at 23:36Z on 2026-10-15; the host API read PROCEED; `W_max` 1. The protocol requires the override in this Deviation Log | The operator, through the hub's launch brief | **RECORDED** — risk R18; every coherent commit is pushed as it lands |
| **DEV-12** | **Size kept, growth recorded:** labels kept at 18 raw / 23 effective (band 15–25) while the matrix grew from 37 paths (18 + 19 conditional) to 39 distinct paths at Commit 0 — 10 conditional rows promoted, 9 not fired, 11 paths added by the accepted scope changes. The decision record's "about nine paths" is eleven by path | The scope-lock record (release-level: size) | **RECORDED** — § File Change Matrix |
| **DEV-13** | **D-5185-SCOPE (Tier 2, `ESC-CR`) accepted:** `core/standards/gate-efficacy-standard.md` (the register row check 4.9 owes), `release/skills/release-planner/SKILL.md` (the `version:` field) and `core/ADRs/ADR-045-cross-surface-memory-contract.md` (R-a's reciprocal pointer) | The scope-lock record | **APPLIED** — § File Change Matrix |
| **DEV-14** | **D-5089-SCOPE (Tier 2) accepted:** population P3 adds `core/disciplines/memory-architecture.md`; rule home H1′ adds `core/standards/reference-durability-standard.md` and the register, plus the hub-detected alignment files the option keeps — `release/references/how-to/intake-style-guide.md`, `core/standards/design-artifact-standard.md` and `release/references/how-to/hub-spoke-bridge.md` | The scope-lock record | **APPLIED** |
| **DEV-15** | **D-4220-TWIN (a) (Tier 2) accepted:** the integrity validator and two new fixtures join the matrix, with the review's strengthened fixture content (CD-1) | The scope-lock record | **APPLIED** |
| **DEV-16** | **D-4023-SCOPE (Tier 2) accepted:** the register gains #4023's named-gap row | The scope-lock record | **APPLIED** |
| **DEV-17** | **D-4022-SCOPE (Tier 2) accepted:** the register gains #4022's named-gap row | The scope-lock record | **APPLIED** |
| **DEV-18** | **D-5089-FORM = D** (name label, plain file link, no fragment; names delimited), read as "a renumber cannot re-create the split". Consequences carried here: CIAC-2's method amended (form D writes no fragment, so the Stage-4 substring count would read 0), and #5089 AC-3's method reworded with its review's correction | The scope-lock record; review #8277 FM-4 and PR-5 | **APPLIED** — § Cross-Issue Acceptance Criteria; § Verification Plan |
| **DEV-19** | **CIAC-3 merged with #4220's INT-1** — one criterion for the (#4220 × #4022 × `scope-change` row) triple, graded by the writer's lockstep, so Stage 9 counts it once | The scope-lock record (corrections locked under every option); review #8280 FM-5 | **APPLIED** |
| **DEV-20** | **Stage-4 conditional rows resolved at Commit 0.** *Promoted (fired):* row 20 (`CONDITIONAL:D-5185-LIFECYCLE-RECORD` — R-a; as #5185's concrete record row), row 21 and row 23 (`CONDITIONAL:D-4022-PROTOCOL-CHANGE` — (C) with the record, and the regenerated release-module index), rows 24 and 25 (`CONDITIONAL:D-5052-THIRD-COPIES` — T1), row 29 (`CONDITIONAL:D-5290-BOUNDARY` — B-3, one sentence) and rows 31–34 (`CONDITIONAL:D-4023-MECHANISM-HUB` — fork (b)). *Not fired, not carried:* row 19 (`CONDITIONAL:D-5185-PHASE-REMOVED` — (i)), row 22 (`core/ADRs/README.md` — curated, DEV-29), rows 26–28 (`CONDITIONAL:D-5290-HOST-ESTIMATION` — H2), row 30 (`CONDITIONAL:D-5290-DECLARE-ROWS` — B-3), rows 35–37 (`CONDITIONAL:D-4023-RUBRIC-NOTE` — no rubric note), and row 8's `:190` limb. **NOT DELIVERED:** row 20's second arm — #5052's direction-(b) decision record, under the row's `core/ADRs/ADR-NNN-*.md` glob — because (a′) was locked | The scope-lock record; `stage-04-planning.md` § 6 rules 5 and 7 | **APPLIED** — § File Change Matrix |
| **DEV-21** | **R3 corrected — this release writes version literals.** The `version:` fields of `release-planner` (#5185, an output-contract change classed material by `core/standards/version-field-semantics.md` § Bump Rules) and `release-hub` (#4023) carry the provisional `v4.75`, so the Stage-4 line "nothing in this release hard-codes the number" no longer holds. If the Stage-12 claim binds another number, a sanctioned re-edit of each field and its package rebuild ride the Stage-12 stamp chore. Precedent note: two earlier releases kept a pre-claim skill's field unchanged and stamped it after the claim; the locked D-5185-SCOPE puts the field in this release's matrix instead, and the hub can redirect | The scope-lock record (D-5185-SCOPE); review #8275, Evidence | **APPLIED** — risk R3 |
| **DEV-22** | **The sibling-PR state in the plan's fourth hub act is stale:** `telemetry-is-computable` (#7901) merged as `v4.74` on 2026-10-09; `controls-fail-loud` (#7919) is open and a draft; two further siblings now carry draft pull requests (#8305, #8306) | Live host state at Commit 0 | **CORRECTED** — § Cross-PR Overlap Audit |
| **DEV-23** | **Discovery X4 withdrawn:** the memory eviction it named as owed since `v4.19` already ran — the decision record on that release's close-out sub-task records it executed operator-side with no archive retained | Design #8195 drift row 2 and S4 | **WITHDRAWN** |
| **DEV-24** | **The Stage-4 aggregate-launch line corrected 33 → 40**, adding the seven Phase A6.5 adversarial reviews it omitted. The hub named "the launch note's file count (33)"; no file count of 33 appears in the plan, and this line is the only count of 33 the plan states for itself (the other 33 is a sibling's file count, now merged) — read so, and the hub can redirect | The hub's Commit-0 instruction | **CORRECTED** — § Quota Budget |
| **DEV-25** | **R4's "Accepted decision record" is ADR-045,** not ADR-029: ADR-029 reads `Superseded by ADR-045` and is frozen; ADR-045 is Accepted and its Decision item 4 names the archive-first path. Under R-a, ADR-045 leaves the release-wide non-scope block and the Stage-9 file-integrity assertion, and joins the matrix for its reciprocal `superseded_by:` line and one Related-ADRs bullet — permitted hygiene on an Accepted record | Design #8195 drift row 3 and R-S4; the scope-lock (R-a) | **APPLIED** — § File Change Matrix; § Verification Plan → Release-Level |
| **DEV-26** | **Stage-4 row 19 re-sized from one analogy to three sentences** (`core/governance/OPERATIONS.md:695`, `:703`, `:709` at the Stage-4 pin), and left as a named residual under D-5185-PHASE-REMOVED (i) | Design #8195 drift row 4; the scope-lock | **RECORDED** — Stage 9 Disclosure 1 |
| **DEV-27** | **Row 7 extended:** the how-to's second #5185 line (`:174`, the lower-case posture word an upper-case sweep does not return) changes with `:149` | Design #8195 drift row 5 | **APPLIED** — slice 1 |
| **DEV-28** | **Tier-B design-artifact determinations owed at Commit 0:** #4220 — `pipeline-event-row-identity` not activated; #5052 — its Stage-4 and Stage-7 edits lie outside every depicted region, not activated | The scope-lock record (release-level); review #8280 FM-4 | **RECORDED** — § Tier-A Activated Design Artifacts |
| **DEV-29** | **Decision records on slug tokens, numbered in Stage 6 order, bound at merge.** #5185's record takes ADR-217 (`release/tools/renumber-adr.py --next-free` against the mainline anchor ADR-216); #4022's takes the next number after the branch's own claims; `controls-fail-loud` holds ADR-217 and ADR-218 as unmerged, advisory claims, and nothing steps above them, because a gap is the expensive failure. Prose cites each record by its slug token; the Stage-12 claim binds the numbers. **`core/ADRs/README.md` disposition (one, per the ADR authoring guide):** no entry — it is a curated thematic document with no projector, and the file set itself is the authoritative list | The scope-lock record (release-level); `release/tools/renumber-adr.py` (the binding rule) | **APPLIED** |
| **DEV-30** | **Delivery Strategy's Issue References row corrected:** all seven cards are carried as `References #N`; none uses a close keyword in the PR body, and each is transitioned to closed at Stage 13 | The hub's launch brief | **APPLIED** — § Delivery Strategy |
| **DEV-31** | **Verification Plan amendments** (the issue bodies stay historical): #5185 AC-4 promoted from deferred to its probe; #5089 AC-3 carried under the reworded method; #5052's rows carry its design's contracts with review A-3's grading notes; #4220 AC-2 promoted to the two self-tests with name-bound expectations (review A-4); #4022 AC-3 promoted to the record's presence plus the filed story; #5290's rows carry the seed posture (AC-6) and the backtest (AC-7); the AC baseline re-read at the branch base | The scope-lock record; each card's design, Plan-file content owed at Commit 0 | **APPLIED** — § Verification Plan |
| **DEV-32** | **#5185's locked form supersedes its design's literal text where the corrections reach it:** option C's value set and wait-for-operator branch; CD-1's one row per tie; CD-2's post-state absorption test; CD-3's hub binding and naming; review A-1 (the register pointer at the Stage-13 spec on a token present only in the stop-rule sentence), A-3 (the ref-anchored probe with its merge-base zero), A-4 (split first; a multi-issue ledger row stops), A-5, A-6, A-7 (the template's outer fence widened in the same session) and A-8 (the coverage wording: an entry's name shape is gated on a tracked file, its content on no surface; the template restates the value set and the restatement's registration is recorded as named debt) | The scope-lock record | **APPLIED** — slice 1 |
| **DEV-33** | **#5052's readings:** D-5052-AC3 taken as a grading note; the third Stage-4 example list (`stage-04-planning.md:192` at the Stage-4 pin) retained as an example. Forward note: review A-6 (the S-6 present-tense reconciliation also reaching `release/references/specs/methodology-parameterization-v1.md`, or S-6 dropped) is #5052's slice's to settle within its locked corrections; a path it adds enters this matrix by Tier 1 `[ADJUST]` in that slice | The scope-lock record; review #8283 A-4 and A-6 | **RECORDED** |
| **DEV-34** | **#5290's readings:** the method ratified and the cut points held as seeds, out of the label grammar, any decision record and label state until the ex-ante backtest has run, so the five descriptions carry words rather than cut-point numerals (review CD-1); under B-3 the common pack's rows and the B-1 decision record are not delivered — neither was in the Stage-4 matrix; L-2 is a triage disposition, not a commit | The scope-lock record; review #8286 | **RECORDED** |
| **DEV-35** | **#4023's readings:** fork (b) with runner E1; the follow-on story with a dated first read is filed (#8376), with the rendered slot as one of its options; the push-to-resolve rubric and the charter template's `:190` limb are not edited | The scope-lock record | **RECORDED** |
| **DEV-36** | **#4022's readings:** (C) with the decision record; the design's measurement text corrected for both event families and for which writer records most Tier 2 escalations; the follow-on story (#8375) not tied to a commit-message check as its first runner, a Tier 2 slot on hub escalation records among its options | The scope-lock record | **RECORDED** |
| **DEV-37** | **Baseline re-pin:** the Stage-4 pin `4babbba9` → the branch base `20197085` (61 commits, 39 files; 8 matrix paths changed, all by the `v4.74` merge). Line anchors in this file are Stage-4 positions; each slice re-anchors by content | The sibling-merge stale-pin trigger (Stage 4) | **RECORDED** — § Cross-PR Overlap Audit → Baseline SHA |
| **DEV-38** | **The Commit-0 pre-flight ran read-only** for the sanctioned-session risk (R10) the plan names | Risk R10 | **RECORDED** — § Commit-0 Version Re-Verify Record → pre-flight |

---

## Documentation Impact

| Issue | Declared docs (the body's Documentation Impact field, as refined) | Status | Lands in |
|---|---|---|---|
| #5185 | `core/disciplines/knowledge-architecture.md` (the lifecycle and the archive-disposition rule) · the release-plan template (the entry format) · `release/references/pipeline/stage-13-close.md` and the drift-audit how-to cite the rule | UPDATED — the discipline, the Stage-13 spec and the how-to in `f2d33b7b`; the template in `ff0731a0`, packaged in `8df84bb1` | slice 1 |
| #5089 | the citing documents named in § Implementation Sequence; the rule's home in the durability standard | pending | slice 2 |
| #4220 | `release/references/standards/pipeline-event-log-schema.md` § 3 (the authoring note) | pending | slice 3 |
| #5052 | `core/schemas/project-schema.md` and `core/specs/domain-token-registry.md` | pending | slice 4 |
| #5290 | `release/references/standards/bundle-composition-doctrine.md` (the rubric) and its two citing surfaces | pending | slice 5 |
| #4023 | the hub contract and its briefing reference | pending | slice 6 |
| #4022 | `release/governance/release-process.md` (the disposition) and the decision record | pending | slice 7 |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification, extended at Stages 7, 8 and 12.*

| Check | Result |
|---|---|
| **Commit-0 version half** | Both fetches exit 0; the adapter's dry run recomputes **`v4.75`** for bump-class `minor` at `20197085`; the slot is free on all three claimed-set arms (probe record above). **No HALT** |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp authoring-conventions-enforced-or-retired` → **exit 0**, *"verify-stamp OK — authoring-conventions-enforced-or-retired carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s)); package-consequence checks not exercised"* (its pre-flight: the manifest stales 0 packages). Control: the same verb on a slug with no plan (`authoring-conventions-enforced-or-retired-zz`) → exit 1, `NO PRE-CLAIM PLAN`. Exactly one literal placeholder in this file (the Header `**Version**` cell) |
| **CIAC lint (G4-06) on this file** | `release/tools/verify-release-plan.sh --ciac-lint` on this file → exit 0: `CIAC-LINT-SUMMARY declared=5 parsed=5 clean=3 declared-deferral=2 flagged=0` — equal to the Stage-4 author's report. CIAC-3's first draft here, a `bash` self-test as the method, read `FLAG not-runnable:bash`; it was rewritten to a single `grep` before this commit |
| **Plan-driven executor at Commit 0** | `release/tools/verify-release-plan.sh --format=md --stage4-comment <the Stage-4 plan comment, parts 1–3> <this file>`, pre-commit, read-only (no event write). Parse: 29 per-issue records (the AC baseline's 29), CIAC-1..5, the matrix and the provenance label all indexed. **By construction at Commit 0:** the presence probes keyed on text no slice has written read FAIL (pre-implementation), the five declared ADDs read not-delivered over the empty range `20197085..20197085`, and two `bash` rows and one `git ls-files` row read UNRUNNABLE (outside the executor's verb set). CIAC-1 and CIAC-3 read PASS (guards); CIAC-2 reads 0, its target. PROV-PRESENCE and PROV-GRAMMAR PASS (Form X, date 2026-10-08) |
| **Matrix parse** | the first run read `declared=62 interpreted=61 … uninterpreted=1`: the bare top-level `CHANGELOG.md` row, whose first segment the extractor's path recognizer does not list. The row moved out of the non-scope fence into prose before this commit |
| **Survival rows 1–5 (independent read)** | The executor's PROV-DELTA row reads `prov-no-loss`, but on this host its set-difference is not trustworthy: BSD awk rejected the multi-line `-v have=` value three times in the run (`newline in string`), the shape a prior release measured as a broken probe. Re-derived with the executor's own five patterns, line-wise: the Stage-4 comment carries 4 elements (label 1 · File Change Matrix 4 · CIAC 11 · Verification Plan 1; the stamp is named there, never reproduced) and this file carries all 5 (label 1 · File Change Matrix 11 · CIAC 19 · Verification Plan 9 · stamp 1) — 0 lost |
| **Matrix paths** | 39 distinct paths: the 34 EDIT paths exist at `20197085` and the 5 ADD paths are absent (a per-path existence read of the whole list) |
| **Baseline re-pin** | `4babbba9..20197085`: 61 commits, 39 files, 8 matrix paths (probe record in § Cross-PR Overlap Audit) |
| **In-flight roster** | 3 siblings, all `minor`, all recomputing `v4.75`; EDITSET ∩ FCM = 7, 4 and 0 paths |
| **Package cascade** | `release-hub` and `release-planner` only, with a control and a specificity arm |
| **R10 pre-flight** | PROCEED — § Commit-0 Version Re-Verify Record → pre-flight |
| **Slice 1 (#5185) — criterion probes** | Commits `f2d33b7b`, `70b28be5`, `ff0731a0`, `8df84bb1`. AC-1 reads **3** in the template (0 at the base; control `Operational Deployment Manifest` 1 → 1). AC-2 reads **0** in the discipline (1 at the base; control `VERIFY-CORPUS` 8 at the base, 10 at the head — the two added mentions are the archive-disposition rule's). AC-3 reads **3** (0 at the base). AC-4 reads **1** (0 at the base; control `Layer 2` 2 → 2). Each criterion's READER-GRADED clause is graded at Stage 7 |
| **Slice 1 — CIAC guards and INT-2** | CIAC-1 reads 1, as at the base: the boundary section keeps its heading and id. CIAC-2 reads 0, as at the base — its target of at least 2 lands with slice 2. The Stage-13 spec's three links into the discipline are byte-identical to the base (3 and 3, the same multiset), so slice 2 finds them by content |
| **Slice 1 — register pointer** | `archive-disposition` reads exactly 1 in the Stage-13 spec (0 at the base): the stop-rule sentence, which the new class 3-O row's `runner-def:` pointer resolves against |
| **Slice 1 — reference cascade** | Three searches over the tracked tree, branch base `20197085` against `8df84bb1` (the counts are pinned there: this row itself quotes the searched tokens, so a later re-run reads this plan higher), every hit classified by reading the line. `[REFCASCADE: git grep -n -w -F "ARCHIVE" -- . over the tracked tree → pre 75 / post 72]`: the live-lifecycle class falls 8 → 0 (the discipline 5, the Stage-13 spec 2, the how-to 1); the named residual stays at 2 lines (the floored CORRECTIONS sentence in `core/governance/OPERATIONS.md` and its projection row in `core/specs/operational-artifact-inventory.md`); this plan adds 5; every other hit is unchanged and is either the unrelated communications-and-meetings `ARCHIVE` state or a decision record. `[REFCASCADE: git grep -n -i -F "archive-first" -- . over the tracked tree → pre 18 / post 23]`: the live class falls 4 → 2, the same named residual; ADR-045 adds 1 (its Related-ADRs line naming the superseded property), the new record adds 2, this plan adds 4. `[REFCASCADE: git grep -n -i -e "archive" --and -e "evict" -- . over the tracked tree → pre 47 / post 69]`: lines describing an archive phase fall 8 → 0 outside the three floored operations-governance sentences, which stay; the 7 lines added in live files state the archive-disposition rule (the discipline 3, the Stage-13 spec 1, the template 2, the register 1); the decision records add 11 and this plan 12 |
| **Slice 1 — ADR numbering, stamp and durability** | `renumber-adr.py --detect`: anchor 216 on `origin/main`, next-free 217, ADR-217 `BINDS` as a branch claim; a sibling branch's 217 and 218 are detection-only. `--stamp` dry run: 3 slug tokens across 2 files over 10 in-scope files, no refusal. The durability lint, delta-scoped over the two records, reads two R6 findings (warn-mode), both caused by the slug token in ADR-045's `superseded_by:` line; once the Stage-12 stamp resolves it the entry reads `ADR-217 in-part (Decision item 4)`, which the R6 grammar parses and which reciprocates ADR-217's `supersedes:` `[INFERRED — the lint's grammar and reciprocity rule read at its source]` |
| **Slice 1 — sanctioned session** | One `pmo-skill-editor` Mode A session over the template and `release-planner`'s SKILL.md, its audit-trail trailer on `ff0731a0`, ended with no sentinel left in the tree. Fences: one four-backtick pair now encloses one three-backtick pair; at the base the mermaid block's closing fence ended the three-backtick skeleton early. Mode C mechanical probes over the 30 added lines read 0 with every planted control firing; the agent-editability suite, which grades the template, reads 30 passed and 0 failed |
| **Slice 1 — package** | `build-skill-packages.sh release-planner` in its own commit `8df84bb1`: sidecar `a749854e` → `e33be4f9`; the packaged template and SKILL.md are byte-identical to source; `deploy.sh --check-package-freshness` reads 55 of 55 content-fresh |
| **Slice 1 — public-surface scans** | Over the 1,001 lines the branch adds: the operator-memory-reference gate's pattern reads 0 (control 3 of 3); identity, local-path, store-name and bypass-token probes read 0 (controls 7 of 7) |
| **Slice 1 — links** | `check-doc-links.py --require-targets` over the nine slice files: 0 broken (its self-test passes 11 fixtures). `check-release-links.py --check-anchors --images` over the same set: 0 broken; 19 anchor findings, warn-mode, every one on a link target that predates the slice |
| **Slice 1 — runtime suite (C4)** | No slice-1 path matches selection rows 1–7 of `release/references/standards/runtime-suite-selection-map.md`, so the map selects `suite-skip`. The `test-run` event that records it is not written by this spoke: the event log is operator-instance state outside the spoke's write scope, so the row — validated with the writer's `--dry-run` — is handed to the hub to emit. The template is nonetheless an input the agent-editability suite reads — a path the map does not route — and that suite was run directly (above) |
| **Slice 1 — deploy-time checks** | `core/deploy/deploy.sh --check` at `8df84bb1`, exit 1 with 6 issues, none from this slice. Check 6 OK for `release-planner`; Check 7 OK, all 55 packages content-fresh; Check 10 OK, `release-planner` at `ff0731a0`; Check 14 OK, no broken cross-reference in scope; Check 62 OK, all 35 register pointers resolve — one more than at the base, since the new class 3-O row is the only added pointer (the raw `runner-def:` token count in the register file rises 35 → 36, the `runner-src:` count stays 4). The 6 issues: 4 `DRIFT` rows for `release-planner` (installed copy, its `references/`, its package, the user-local mirror), expected because nothing is deployed from this branch and Stage 12 redeploys it; and 2 `FAIL` rows on surfaces the branch does not touch, with `origin/main` still at the branch base — Check 47's published-Release-body drift (13 findings) and Check 63's count-structure findings in `SECURITY.md`, `core/references/reference/operator-instance-home-and-isolation-key.md` and `release/references/standards/release-notes-standard.md` |
| **Slice 1 — ADR index** | N/A for slice 1 — it adds a record under `core/ADRs/` only; the release's one record under `release/ADRs/` lands with slice 7 |

---

## Change Description

*Authored at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, before the Stage-9 draft→ready transition. Not authored at Commit 0: no slice has landed, so there is no outcome to describe yet.*

---

## Issue References

The seven content members of this milestone are transitioned to closed at Stage 13 by the close-out on the merged PR, not by an auto-close keyword in the PR body.

- **#5185** — the memory-eviction manifest had no safe archive destination and implied a public one; this release fixes the archive disposition where the entry is authored and makes the tie the unit of eviction.
- **#5089** — the memory-boundary rule was cited under two section numbers; this release converts the citations to a name-label form a renumber cannot split.
- **#4220** — a parenthetical in the event schema's column 3 could create a phantom subtype; this release narrows both parsers and states the constraint.
- **#5052** — the deliverable-class list lived in two disagreeing places; this release gives it one home.
- **#5290** — size labels had no assignment rubric; this release adds one, with its cut points held as seeds.
- **#4023** — evidence labels on conversational turns had no stated obligation; this release restates it with the surface it binds.
- **#4022** — the signal-tag convention had no recorded disposition; this release records (C), the binding surface restated.
- **#8375 and #8376** — the follow-on stories for #4022 and #4023, filed by the hub.
- **#8228** — the routed explicit-id counter-design from #5089's review.
- **#7901, #7919, #8305 and #8306** — the sibling release pull requests in § Cross-PR Overlap Audit.
- **#8161, #8195, #8199, #8203, #8207, #8211, #8215, #8219, #8275, #8277, #8280, #8283, #8286, #8288, #8302 and #8196–#8227** — the Stage-4, Stage-5 (designs and reviews) and Stage-6 to Stage-13 hub sub-tasks carrying the plan source, the designs, their reviews and the decision records.
