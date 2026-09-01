---
title: Release Plan — portfolio-tier-framework-pack
purpose: Stage-4 release plan for the portfolio-tier methodology framework pack — a portfolio governance framework gets a home at its own altitude, without disturbing the project-tier pack grammar.
type: release-plan
plan_type: release
status: EXECUTING
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: portfolio-tier-framework-pack — A Portfolio Framework Gets an Altitude of Its Own

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against a three-arm claimed set (origin tag refs · published GitHub Releases · mainline release-ledger version rows); `anchor()` = **v4.45**, recomputed next-free = **v4.46**, free on all three arms with live sensitivity and specificity controls. |
| **Date Created** | 2026-09-01 (Tuesday) |
| **Commit-0 Date** | 2026-09-01 (Tuesday) — the resolution instant for every load-bearing date this release writes |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/portfolio-tier-framework-pack` |
| **PR** | opened as a DRAFT after the Engineering commits; the release ships as a SINGLE PR with one merge gate |
| **Milestone** | `portfolio-tier-framework-pack` |
| **Release Class** | `novel` — confirmed at the Stage-4 D-ReleaseClass gate; robust under scope (a) |
| **Composition** | capability-slice — a Phase-0 design spike plus the umbrella it unblocks |
| **Effective points** | **10** raw across **2** issues (#3616 `size:S` = 2 · #2577 `size:L` = 8). `class_weight` for Release Class `novel` = 1.15, so `effective_pts` = round_half_up(10 × 1.15) = **12** — below the 15–25 target band. **Under-target was accepted, not mitigated by bundling**, at the Stage-4 R7 disposition: the alternative was adding unrelated scope to reach a points band, which is bin-packing rather than capability-coherence composition. |
| **Branch topology** | **SINGLE** — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** — rule-determined by the default-when-undeclared clause, and independently forced by the hard #3616 → #2577 edge, which serializes the entire pipeline rather than a single wave. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `539c4440fc1457e8d42d2bbe11c7be663baf596f` — the pinned baseline; every Engineering spoke branches from it |

**Stamp manifest.** The `**Version**` cell above is a machine-read manifest, not prose. It carries the literal `{{RELEASE_VERSION}}` token and no other text; the Stage-12 claim resolves it at the merge SHA while renaming this file to `release/releases/plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md` (ADR-092). Asserted read-only at Commit 0 by `release/tools/claim-version.sh --verify-stamp portfolio-tier-framework-pack`; a plan that fails that assertion is never committed, because Stage 12 could then neither resolve the version nor complete the rename. The bump-class determination lives in the `**Bump Class**` row beside it, deliberately — not in the Version cell.

## Release Outcome Statement

**AFTER** this release: a portfolio-tier governance framework has a declared altitude, a selector, and a home for its artifact shapes — and the project-tier pack grammar is provably untouched.

**BEFORE:** portfolio-tier governance frameworks (PMI Standard for Portfolio Management; SAFe Lean Portfolio Management) have **no home**. The methodology-pack architecture is scoped to project-tier `delivery_approach` archetypes; `portfolio_framework` resolves to zero occurrences across the config, schema, and spec surfaces; and #2577's own body carries an unresolved *"Open design conflict"* naming two mutually-exclusive homes for its deliverable.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Type | Size | Priority | Stage 5 |
|---|-------|---------------------|------|------|----------|---------|
| 1 | #3616 | Define the portfolio-tier methodology framework pack shape + absorption set (spike) | `type:spike` | S | P4 | APPLY (activation bias ALL) |
| 2 | #2577 | Portfolio-tier methodology framework pack (PMI reference) — extend foundation to portfolio altitude | `type:story` | L | P3 | APPLY — input **is** #3616's Stage-6 output |

**Scope composition = D-Q1 (a) BOTH cards.** The operator rendered (a) on 2026-09-01, diverging from both the Stage-4 spoke's and the hub's recommendation of (b) spike-only. The consequences (a) carries are tracked as live risks R1/R2 below — carried, not re-litigated.

### Composition Lock

Stamped at **Stage 4 Planning entry · 2026-09-01 · sub-task #6446**. Membership is #3616 + #2577 and does not change during this release. Per operator decision **D-S5-3(α)**, #2577 is engineered as **one unsliced umbrella**: its S1–S4 slices are **commit sequencing on the single branch, NOT milestone membership**. No child cards are created and the lock stays intact.

## Release Class

**`novel` — confirmed at the Stage-4 D-ReleaseClass gate.** Trigger (b) fires (≥1 D-class decision in the release plan: D-Q1, D-Q2, D-Q3, D-Q4, D-Q5, plus the recurring D-Version / D-Concurrency and the five Stage-5 D-S5-N); trigger (c) fires (≥1 Stage-5 ADR under D-Q4(i)); trigger (a) fires (a new corpus record). `cross-cutting` does not fire on any of its three limbs. Multi-trigger resolution (`cross-cutting` > `novel` > `routine`) selects `novel`.

**Differentiation posture:** engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** (load-bearing, not decorative — the spike's entire substance is the Stage-5 design act) · Stage 13 outcome-window **30-day**.

## Implementation Sequence

The serialization spans the **entire pipeline**, not a wave boundary: #2577's Stage-5 input *is* #3616's Stage-6 output.

| # | Issue | Work | Gate |
|---|-------|------|------|
| 1 | **#3616** | Author the core-scope ADR recording the pack-shape + content-location decision; post the slice plan to #2577; author #2577's File Change Matrix rows and AC-4 Verification Plan row (AI-002) | must reach Stage-6 merge on this branch before #2577 enters Stage 5 |
| 2 | **#2577** | One unsliced umbrella, committed in the S1 → S2 → S3 → S4 sequence below on the same branch | Stage 8 grades AC-1..AC-7 plus INT-1/INT-2 |

**#2577 commit sequence (D-S5-3(α) — sequencing, not membership).** S1 altitude declaration → S2 selector → S3 artifact shapes → S4 registry wiring. S2's schema wording cites the §5B section S1 introduces, which is what fixes the order.

## Stage Applicability Matrix

| Stage | #3616 | #2577 | Basis |
|-------|-------|-------|-------|
| 5 Solutioning | **APPLY** | **APPLY** | The spike's deliverable *is* a design decision. `novel` sets activation bias ALL. |
| 6 Engineering | **APPLY** | **APPLY** | #3616 authors the ADR + this plan as Commit 0; #2577 builds the umbrella. |
| 7 Dev Testing | **REDUCE → doc-conformance** | **APPLY** | #3616 ships no executable surface, but real rungs run: `check-adr-numbers.py` + `check-adr-durability.py`. Not a skip. |
| 8 QA Testing | **APPLY** | **APPLY** | Per-criterion verdicts; #3616 AC-3 graded MET-by-citation per D-Q3(ii). |
| 9 Plan Review | **APPLY — Deep** | **APPLY — Deep** | `novel` → Deep per the class mapping. |
| 10 Dry Run | **APPLY** | **APPLY** | |
| 11 Snapshot | **APPLY** | **APPLY** | |
| 12 Execute | **APPLY** | **APPLY** | |
| 13 Close | **APPLY** | **APPLY** | Deployable close class, **plus** the additive Artifact-Acceptance Record block for the slice-plan knowledge deliverable. |

**`deliverable_state` declaration.** #3616 → `artifact-accepted` (its definition of done *is* the ADR at its declared canonical path plus the slice-plan comment; no Layer-2 propagation target). #2577 → `artifact-accepted` for the template subtree and `deployed-copy-synced` only if a consumer skill declares a runtime read-path against the framework subtree in this release, which the Stage-5 design does not.

## File Change Matrix

Path-first columnar form; verbs per the `add | edit | delete` enum.

```
# ── #3616 — the shape record (D-Q4(i) ratified at Stage 4; the gated row is PROMOTED here to a firm obligation) ──
core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md   add
release/releases/plans/portfolio-tier-framework-pack_RELEASE_PLAN.md               add

# ── #2577 S1 — portfolio-framework altitude declaration ──
release/references/specs/methodology-parameterization-v1.md                        edit
release/references/specs/methodology-archetype-matrix.md                           edit

# ── #2577 S2 — portfolio-tier selector (deployment-global per D-S5-4) ──
core/config/operator.toml.template                                                 edit
core/schemas/platform-config-schema.md                                             edit
core/config/operator-toml-schema.json                                              edit

# ── #2577 S3 — PMI artifact shapes (the framework-keyed delta subdirectory) ──
operations/templates/portfolio-frameworks/pmi/portfolio-charter-template.md         add
operations/templates/portfolio-frameworks/pmi/strategic-alignment-matrix-template.md add
operations/templates/portfolio-frameworks/pmi/portfolio-roadmap-template.md         add
operations/templates/portfolio-frameworks/pmi/risk-profile-template.md              add
operations/templates/portfolio-frameworks/pmi/program-charter-template.md           add
operations/templates/portfolio-frameworks/pmi/benefits-realization-template.md      add
operations/templates/portfolio-frameworks/pmi/program-md-template.md                add

# ── #2577 S4 — registry wiring ──
operations/templates/README.md                                                      edit
core/standards/template-storage.md                                                  edit
core/standards/template-taxonomy.md                                                 edit
```

**Row notes, per the declared-vs-delivered authoring contract.**

- **The ADR row is PROMOTED to unconditional in this commit.** Stage 4 declared it `CONDITIONAL:d-q4-adr-ratified`. D-Q4 resolved to **(i) core-scope ADR** at the Stage-4 plan-approval gate, so contract rule 5 applies: the condition resolved at or before Engineering Commit 0, therefore the row moves into the unconditional set **in that commit**, carrying its now-concrete path. Leaving it CONDITIONAL after its condition fired would be an authoring defect indistinguishable from a condition that never fired.
- **ADR-170 is the number allocated at authorship, not reserved at plan time.** `release/tools/renumber-adr.py --next-free` returned **170** against `origin/main` @ `539c4440`. The number **claims at merge**, not here: a sibling release merging ahead of this branch renumbers it, and `check-adr-numbers.py` gates the result in CI. ADR numbering spans **both** `core/ADRs/` and `release/ADRs/`; the oracle is the authority, never the visibly-highest file.
- **No `core/ADRs/README.md` index row is owed.** That file states verbatim it is *"a curated thematic document, NOT an index — and that is a decision, not an omission."* A *release*-scope ADR would owe the generated index per ADR-117; a core-scope one does not.
- **The 7 artifact-shape rows are literal, not glob.** They conform to the governed naming convention `<artifact-family>-template.<ext>` (`template-storage.md` §2.2), and their set is grounded in #2577's own body — AC-4 names the four portfolio-tier shapes, and the Description adds the program-tier set (PROGRAM.md / program charter / benefits realization). A shape that legitimately does not ship requires a `## Deviation Log` row carrying the literal `NOT DELIVERED` and its declared path.
- **New-executable companion obligation: N/A** — the matrix carries no `*.sh` add, so no `core/config/allowlists/script-execution-allowlist.txt` row is owed.
- **`TEMPLATE_SYNC_MAP` registration is deliberately NOT in the matrix.** The registry's own rule is that sync-map registration follows the first consumer skill with a runtime read-path; no skill in this release declares one against the framework subtree, so registering now would create a mirror with no consumer.

> ⚠️ **G-PR11 CANNOT SEE THIS RELEASE'S PRIMARY DELIVERABLE — a tooling gap found by running the checker, not by reading it.** `release/tools/verify-release-plan.sh`'s FCM path recognizer matches only paths whose first segment is `core` · `release` · `docs` · `packages` · `projects` · `roadmaps` · `.github` · `.claude`. **`operations/` is absent from that set**, so every `operations/**` row in the matrix above returns no path and is **dropped before classification**. Measured against this matrix: **31 declaration rows authored → 21 recognized → 10 silently dropped**, and the dropped set includes **all 7 artifact-shape ADDs** — the exact files AC-4, INT-1 and CIAC-1 all assert on. The checker's own counters reconcile to this reading precisely (`declared=21`, `excluded=12`, `obligations=2`), and the drop is invisible in its report: it emits `uninterpreted=0 pathless=0` and FCM-COVERAGE reads **PASS**.
>
> **Consequence for Stage 9:** G-PR11's verdict on this release is **PASS-over-a-partial-population, not a clean delivery assertion.** It asserts 2 obligations (the ADR and this plan) out of 9 declared ADDs. The remaining 7 must be graded from AC-4's own named-set probe, which does resolve them. This is recorded here rather than left for Stage 9 to discover, and it compounds **R1** — the matrix is both authored late *and* only partially machine-readable. Tracked as **R10**; the fix belongs to the checker's own card, not to this release.

### Read-only inputs

```
core/ADRs/ADR-069-methodology-pack-composing-unit.md          READ
core/ADRs/ADR-070-methodology-pack-composition-grammar.md     READ
core/ADRs/ADR-050-deliverable-domain-axis.md                  READ
core/ADRs/ADR-018-work-item-type-layer.md                     READ
core/schemas/work-item-type-schema.md                         READ
core/packs/                                                   READ
docs/scripts/setup-workspace.sh                               READ
```

### Release-wide explicit non-scope

```
core/packs/                                                   NOT EDITED
core/packs/_common/pack.toml                                  NOT EDITED
core/packs/scrum/pack.toml                                    NOT EDITED
core/packs/kanban/pack.toml                                   NOT EDITED
core/schemas/project-schema.md                                NOT EDITED
operations/templates/operations-tiers/                        NOT EDITED
roadmaps/                                                     NOT EDITED
```

**Why each non-scope row is there, not merely absent.** `core/packs/**` is the subject of #2577's restated **AC-5**, graded mechanically by `git diff --stat core/packs/` returning empty on the merged PR — the non-disturbance is a *deliverable*, so it is declared rather than assumed. `core/schemas/project-schema.md` carries no V-rule because **D-S5-4** made `portfolio_framework` deployment-global at v1. `operations/templates/operations-tiers/` is candidate home (iii), rejected in the ADR and therefore explicitly untouched. `roadmaps/` is untouched per **D-Q2(D)** — the capability ships roadmap-unhomed for now, revisited at Stage 13 (AI-004).

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: governance }`

Sourcing-exempt — every matrix path is an internal pmo-platform artifact, so no external sourcing step fires. Sourcing-exempt does not make the release domain-less: classified `governance` from the matrix evidence, which targets corpus records, config schema, and specs rather than application source. Carried **UNCHANGED** from Stage 4 (Form **X — EXEMPT**); no Mode-B → Mode-A upgrade is owed, because Stage 4 emitted Form X rather than Mode B.

## Contention Map

**⚠️ The Stage-4 contention map was a BROKEN PROBE, not a clean result — and it is recorded as unusable rather than passed forward.** At Stage 4, #3616 declared no repository file and #2577's Affected Files list was self-declared *"provisional until"* the spike resolved. A zero-overlap finding between an empty set and an explicitly non-authoritative set is uninformative: the subject arm and the control arm both returned zero **for the same reason** — neither member's surface had been determined. A specificity arm over an empty input is vacuous, not passing (PV-2 / PV-5).

**The probe becomes valid HERE, at Commit 0, because this plan is where #2577's surface is first determined.** Re-run against the File Change Matrix above:

| Path | Class | Claimants |
|---|---|---|
| `release/releases/plans/portfolio-tier-framework-pack_RELEASE_PLAN.md` | single | #3616 (Commit 0) |
| `core/ADRs/ADR-170-*.md` | single | #3616 |
| every #2577 S1–S4 path | single | #2577 |

**Within-release contention: NONE.** Denominator = **17 declared delivery rows** (2 owned by #3616, 15 by #2577), extracted from the matrix fence above; all 17 parsed as `<path> <verb>` with **zero uninterpreted rows**. Subject arm — `#3616 ∩ #2577` = **0 shared paths**. **Sensitivity arm:** the same set-intersection instrument run over the whole declared set against itself returns **17**, so the instrument resolves non-empty inputs and the subject zero is a true empty rather than an extraction failure. **Specificity arm:** the same instrument intersected against a fabricated path (`operations/templates/portfolio-frameworks/zzz-not-selected/x-template.md`) returns **0**. Both arms live, neither vacuous — this zero is a result, unlike Stage 4's.

**Cross-PR contention (A4), baseline-pinned.** Zero open PRs at `539c4440` / 2026-09-01, sensitivity arm on `--state merged` returns rows. Recorded with its pin per audit-baseline discipline: a PR opened after this instant is invisible to this measurement by construction, and the population is re-checked at Stage 9 Phase A6.5.

**In-flight release roster.** n=0 siblings in flight at `539c4440`. Exactly one remote `release/*` head exists (`release/operational-folder-enforcement-migration`), verified an ancestor of `origin/main` — merged, therefore not in flight.

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#3616 × #2577 on the pack content-location path):** the filesystem location #3616 records as its shape decision is the same location at which #2577's portfolio-tier artifact shapes ship — the two issues do not disagree about where pack content lives. *Method:* extract the decided directory-pattern token from the merged ADR's § Decision D1 limb, then assert every #2577-delivered artifact-shape file resolves beneath it. *Control arm (so a zero cannot be produced by an unresolvable path):* run the same containment probe against a framework directory the decision did **not** select and observe a non-zero mismatch. *Graded at Stage 9 QC3.5 on the merged PR.*

The criterion above is owed **because scope (a) was chosen**. It was pre-authored at Stage 4 for exactly this branch — under (b) zero cross-issue criteria were constructible, because one member yields zero issue-pairs. *(This paragraph deliberately does not open with a `CIAC-N` token: the section parser reads a leading bolded `CIAC-N` as the start of another entry, and an earlier draft of this note produced a phantom second CIAC row with empty method and expected cells.)*

## Verification Plan

**AC baseline:** #3616 → **4** completion conditions · #2577 → **7** acceptance criteria (AC-5 restated 2026-09-01 under the Tier-1 [ADJUST] of D-S5-2) · plus **2** integration criteria (INT-1, INT-2) authored at Stage 5. **Total 13 rows.**

`ac_baseline: { #3616: 4, #2577: 7, INT: 2, read_at: 539c4440fc1457e8d42d2bbe11c7be663baf596f }`

| Issue | AC | Verification Method | Expected Result |
|-------|----|---------------------|-----------------|
| #3616 | AC-1 | `grep -cE 'ADR-069\|ADR-070' core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md` — both grammar ADRs cited — plus `grep -cE '^\*\*D[1-4] ' ` on the same file for the four decision limbs | ≥2 ADR citations; **4** decision limbs |
| #3616 | AC-2 | `grep -cE 'core/packs/<framework_id>/\|flat root\|operations-tiers/_config' core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md` — all three rejected homes enumerated in § Alternatives Considered, each with its disqualifier — plus `grep -c 'SELECTED'` on the same file | ≥3 rejected homes; exactly **1** SELECTED |
| #3616 | AC-3 | **MET-by-citation per D-Q3(ii).** Named read of #374 live state (`state CLOSED` · `stateReason NOT_PLANNED` · label `status: rejected` · `closedAt 2026-07-01T00:28:08Z`) and of #2577's Description § Absorbs, which independently carries *"the PMI artifact shapes of #374"* | absorption recorded on both cards; scope question answered 2026-07-01, not re-decided |
| #3616 | AC-4 | named read of #2577's comment stream for the posted slice plan | slice plan present on #2577, framed as commit sequencing under D-S5-3(α) |
| #2577 | AC-1 | `grep -cE 'portfolio_framework\|portfolio-framework' release/references/specs/methodology-parameterization-v1.md` — the altitude is declared — plus `grep -cE 'orthogonal\|compose' ` on the same file, asserting the two axes are stated orthogonal rather than nested | non-zero for both; the new section is an additive sibling, not an edit to the existing one |
| #2577 | AC-2 | `grep -c 'PMI' release/references/specs/methodology-archetype-matrix.md` plus a named read of the matched row | non-zero; the row is a portfolio-framework row, not a `delivery_approach` row |
| #2577 | AC-3 | `grep -c 'portfolio_framework' core/config/operator.toml.template core/schemas/platform-config-schema.md core/config/operator-toml-schema.json` | non-zero for all three. **BEFORE state re-verified at `539c4440`: 0 / 0 / 0** — the capability is genuinely unshipped |
| #2577 | AC-4 | `ls operations/templates/portfolio-frameworks/pmi/ \| grep -cE '^(portfolio-charter\|strategic-alignment-matrix\|portfolio-roadmap\|risk-profile\|program-charter\|benefits-realization\|program-md)-template\.md$'` — asserts the **named** set, strengthened from the slice plan's bare glob count, because a count of 7 passes even when the wrong 7 files exist whereas a named-set match cannot | **7**. *Control arm:* the same instrument against a framework directory the decision did **not** select (`operations/templates/portfolio-frameworks/zzz-not-selected/`) returns **0** while the selected one returns 7 — so a zero cannot be produced by an unresolvable path |
| #2577 | AC-5 | `git diff --name-only <base>..<merge> -- core/packs/ \| grep -c .` — the count form of the criterion's own `git diff --stat core/packs/`, stated so the assertion is a number rather than an eyeballed empty string | **0**. *Control arm:* the same instrument against `operations/templates/` on the same merged PR must return non-zero, proving it reports changes when changes exist — so the required zero is a measurement, not a silent no-op |
| #2577 | AC-6 | worked example: resolve a project configured with `delivery_approach` only and no `portfolio_framework`; diff the resolved output against the same resolution at `539c4440` | byte-identical. Holds by construction — no existing template, pack, or selector is edited |
| #2577 | AC-7 | duplicate-source-discipline: `grep -rc 'global default → portfolio → program → project → individual' core/ release/` — the resolution-precedence chain must appear at its existing single home and **not** be restated beside the new selector | the chain's occurrence count is **unchanged** from its pre-release value; the selector cites the precedence, never re-defines it |
| #2577 | INT-1 | *integration criterion (Stage-5 Phase A4.2).* Extract the directory-pattern token from the merged ADR § Decision D1, then enumerate #2577's added artifact-shape files and confirm containment; assert **zero** artifact-shape files under `core/packs/` or at the `operations/templates/` flat root | all 7 contained; zero outside |
| #2577 | INT-2 | *integration criterion (Stage-5 Phase A4.2).* Confirm #2577's diff touches no file under `core/packs/**`, and that no `pack.toml` declares a `portfolio_framework`, `axis`, or `family` key | zero `core/packs/**` files in the diff; zero new keys |

**INT-1 / INT-2 are fully gating members of the existing Stage-8 machinery** — graded at Stage 8 Phase B using the Stage-8 per-criterion verdict enum verbatim, with no parallel grading path and no invented verdict values. A NOT MET on either triggers the Stage-8 Step-0 hard-precedence gate (fix-now, or a recorded Operator Override Record). Stage 9 Phase A3.5 groups both under the #3616 → #2577 chain, which is genuinely multi-node — so the single-node `N/A` degeneracy does **not** apply and this release will emit a real CHAIN verdict.

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity — `core/deploy/deploy.sh --check` Check 14 (doc-link integrity) on every modified `.md`
- [ ] Skill Invocation — **N/A**, enumerated over the skill roster: no `SKILL.md` or skill `references/` file is in the matrix, so no `.skill` package rebuild is owed and the `skill-package-freshness` gate has no subject
- [ ] Output Contract Compliance
- [ ] ADR conformance — `python3 release/tools/check-adr-numbers.py` and `python3 release/tools/check-adr-durability.py`, exit 0 both

**Runtime-suite selection: no-match row.** The change surface is doc / governance / spec / config-schema only, matching none of rows 1–5 of the runtime-suite selection map. The honest no-op is a `test-run` / `suite-skip` emission, not a fabricated suite pass.

## Risk Register

| # | Risk | Sev | Owner | Mitigation | Reversibility |
|---|------|-----|-------|-----------|---------------|
| **R1** | **#2577's change surface was undefined at Stage 4, and its File Change Matrix + AC-4 Verification Plan row are authored HERE, late.** Its body self-declares Affected Files provisional; AC-4 grades *"the location decided by the #3616 spike."* Stage 9 reads that matrix at **G-PR11**. | **HIGH** | Engineering (this commit) | Discharged in this plan — the matrix carries literal paths on every row and AC-4 carries a reproducible probe with a control arm. **Stage 9's G-PR11 read must NOT be presented as clean:** it is reading a matrix authored one stage late, against a design that landed at Stage 5, not a Stage-4 declaration that survived. | CHEAP |
| **R2** | **Composition-lock vs. late slices.** The lock is stamped (Stage 4 entry · 2026-09-01 · #6446). #2577's slice plan implies S1–S4. | **MEDIUM** | operator (D-S5-3) | **DISCHARGED at D-S5-3(α)** — #2577 is engineered as one unsliced umbrella; S1–S4 are commit sequencing on the single branch, not milestone membership. No child cards; lock intact; no re-bundle cycle. AI-003 closed. | CHEAP |
| **R3** | **Spike AC-3 asks a question settled before the spike existed.** #374 is CLOSED / `status: rejected`, its PMI artifact shapes absorbed into #2577 on **2026-07-01** (Wednesday). The spike was created 2026-07-17, sixteen days later. | **MEDIUM** | operator (D-Q3) | **D-Q3(ii) leave as-is** — Stage 8 grades AC-3 MET-by-citation against the 2026-07-01 absorption recorded on both #374 and #2577. No body edit. | CHEAP |
| **R4** | **Content-location decision space under-enumerated at two homes** when a third shipped 2026-08-23 (`operations/templates/operations-tiers/`). A spike deciding between two options when three exist decides wrongly by omission. | **MEDIUM** | Stage 5 spoke | **DISCHARGED** — Stage 5 enumerated all three, found all three disqualified on verified evidence, and selected a fourth (home (ii) extended with a framework-keyed subdirectory). The ADR records each rejection with its disqualifier. | CHEAP |
| **R5** | **No durable corpus artifact.** A grammar-altitude decision citable only from a GitHub comment has no authority a later slice can cite. | **MEDIUM** | operator (D-Q4) | **D-Q4(i)** — the shape decision lands as a core-scope ADR, matching the ADR-069/070 precedent. Row promoted to unconditional in this commit. | CHEAP |
| **R6** | **Roadmap-unhomed work carries no sunset criteria and no initiative review cadence.** Both members wear `project:methodology-packs` — the initiative label of a roadmap whose Out-of-Scope table excludes them. | **LOW** | operator (D-Q2) | **D-Q2(D)** — ship roadmap-unhomed; revisit after the slice plan exists. Tracked as AI-004, resolved at Stage 13. R6 stands for one release, accepted knowingly. | CHEAP |
| **R7** | **Release under-size vs. target** (12 effective pts against a 15–25 band). | **LOW** | operator | **Accepted, not mitigated by bundling.** Adding scope to reach a band is bin-packing; under-target with known scope beats on-target with invented scope. | n/a |
| **R8** | **A third orthogonal axis ships with no shared axis mechanism.** `delivery_approach` → `core/packs/`; `deliverable_type` → `core/standards/domain-best-practices/`; `portfolio_framework` → this decision. Three instances of one shape is past the platform's own N=2-within-180-days governance-promotion trigger. | **MEDIUM** | operator (D-S5-1) | **D-S5-1(C)** — ship the one-off design; route the general axis-mechanism question to a **discovery pass** (AI-005) asking what the three axes actually share **before** any mechanism is designed. Deliberately out of scope for this release; the ADR records the exclusion rather than leaving it silent. Choosing the one-off forecloses nothing — the design touches zero consumed grammar. | CHEAP for this release; the deferred mechanism is EXPENSIVE (see R9) |
| **R9** | **The cheap window on the `core/packs/` grammar is CLOSED.** ADR-069/070 each declare reversibility crosses to **EXPENSIVE** once the consumer read-refit (#2021) wires the pack consumers. #2021 closed **2026-07-24** (Friday) and the consumers are live. | **MEDIUM** | recorded, not mitigated | This is a **premise correction**, not an open risk: #2577's third comment argues the generalization is *"cheap to decide now and expensive later."* For the pack-grammar carrier that stopped being true five and a half weeks before this release. The design's response is to touch **no** pack grammar at all. | n/a — a recorded fact |

| **R10** | **The FCM delivery checker is blind to the entire `operations/` module.** `verify-release-plan.sh`'s path recognizer omits `operations/` from its first-segment set, so 10 of this matrix's 31 declaration rows — including **all 7 artifact-shape ADDs** — are dropped before classification, while the report reads `uninterpreted=0 pathless=0` and FCM-COVERAGE **PASS**. A silent drop that reports clean is worse than a loud failure. | **MEDIUM** | checker's own card (not this release) | **Recorded, not fixed** — the checker is another card's surface and repairing it here would widen this release's scope. Mitigated *within* this release by AC-4's named-set probe, which resolves all 7 files independently of the FCM family. Stage 9 must read G-PR11 as **PASS over 2 of 9 declared ADDs**, not as a clean delivery assertion. | CHEAP to fix (one alternation in one regex) |

**Severity counts:** HIGH 1 · MEDIUM 6 · LOW 2 (total 9).

## Delivery Strategy

| Aspect | Decision |
|--------|----------|
| **Implementation approach** | Sequential (dependency-ordered) — forced by the hard #3616 → #2577 edge |
| **Commit strategy** | One commit per coherent slice, pushed as it lands (write-early); Commit 0 is this plan file |
| **Review approach** | Single PR for the entire release, opened DRAFT at Stage 6 and transitioned ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge; no S-2 skill copy (no `SKILL.md` in the matrix); no manifest execution |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (Option A, default) — no stacked-base waves are planned |
| **Branch topology** | SINGLE (`release/portfolio-tier-framework-pack`) |
| **Concurrency posture** | P0 fully-serial; force-push prohibited on the shared release branch |

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|-------|-----------------|------------|
| #3616 | `git revert <commit>` — a new ADR file and a new plan file; no inbound references exist to a file that did not previously exist | **Low** — isolated additive change |
| #2577 | `git revert <commits>` — additive §5B section, additive matrix row, additive selector, net-new subtree, additive registry rows | **Medium** — five existing governance/schema surfaces are edited, and a partial revert would leave a half-declared selector (a selector in `operator.toml.template` with no `platform-config-schema.md` declaration, or vice versa). Revert S2's three files as one unit. |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert that issue's commits; #2577's S2 trio reverts atomically |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-commit>` — requires the merge to be a true two-parent merge commit, which the `merge` strategy provides |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per the rollback protocol |

**Whole-release rollback complexity: MODERATE** — raised from CHEAP by scope (a). Under (b) the release added one new file and mutated no existing corpus surface.

## Operational Deployment Manifest

**N/A — enumerated over the four Layer-1 → Layer-2 propagation classes** (skill `SKILL.md` copies, skill `references/` copies, `core/rules/` mirrors, `TEMPLATE_SYNC_MAP` registered templates); none present in this release. No `SKILL.md` or skill `references/` file appears in the matrix; no `core/rules/` file is edited; and `TEMPLATE_SYNC_MAP` registration is deliberately deferred until a consumer skill declares a runtime read-path against the framework subtree, per the registry's own registration rule.

### Schema Migrations

**N/A — enumerated over the schema surfaces the matrix touches** (`platform-config-schema.md`, `operator-toml-schema.json`, `work-item-type-schema.md`, `project-schema.md`). All changes are **additive declarations of a new optional field**; no existing field changes type, no enum member is removed, and a deployment with no `portfolio_framework` set resolves byte-identically to today. `project-schema.md` is untouched — D-S5-4 made the selector deployment-global at v1, so no V-rule is owed.

## Baseline Pin

`origin/main` @ `539c4440fc1457e8d42d2bbe11c7be663baf596f` (2026-08-30, Sunday). Every Engineering commit branches from it. Read by Stage 9 Phase A6.5 as the mid-pipeline divergence re-check anchor: concurrent releases merging to `main` during this release's Engineering / DT / QA window are **not** caught by the Stage-4 audit and are caught there.

## Quota Budget

**Verdict:** PASS (Checkpoint A). **Parallel-eligible spokes per parallel stage:** Stage 5: 1 · Stage 7: 1 · Stage 8: 1 — the hard #3616 → #2577 edge serializes every stage, so no stage has a parallel batch wider than one. **Per-spoke cost estimate:** low band. **Estimated cumulative draw:** one low-band spoke per stage against the envelope, well under the 50% PASS threshold. **Routing:** PASS — proceed; no split-batch or window-aware timing needed.

Checkpoint A is a plan-time estimate and advisory. The load-bearing gate is Checkpoint B, re-validated at every `Agent`-tool launch — wave or singleton, every stage.

## Operator Decisions Rendered

| Decision | Verdict | Rendered |
|----------|---------|----------|
| **D-Q1** Scope composition | **(a) BOTH cards** — #3616 + #2577 ship together | 2026-09-01, Stage-4 plan-approval gate (diverges from both recommendations of (b)) |
| **D-Q2** Roadmap placement | **(D)** ship roadmap-unhomed; revisit after the slice plan exists | 2026-09-01 — AI-004, resolved at Stage 13 |
| **D-Q3** Spike AC-3 currency | **(ii) leave as-is** — Stage 8 grades MET-by-citation | 2026-09-01 |
| **D-Q4** Spike deliverable form | **(i) core-scope ADR** | 2026-09-01 |
| **D-Q5** #3616 Triage gap | **APPROVE retroactively**; label left at `status: bundled` | 2026-09-01 |
| **D-ReleaseClass** | `novel` — confirmed | 2026-09-01 |
| **D-Version** | minor · provisional {{RELEASE_VERSION}} — recorded determination, not a gate | 2026-09-01; re-verified at Commit 0 |
| **D-Concurrency / D-C Topology** | P0 fully-serial · SINGLE | 2026-09-01 |
| **D-S5-1** Axis mechanism | **(C) route to a DISCOVERY pass** — ship the one-off design | 2026-09-01, Stage 5 — AI-005 |
| **D-S5-2** #2577 AC-5 unsatisfiable | **Tier-1 [ADJUST]**, applied — AC-5 restated as a mechanically-gradable `git diff --stat core/packs/` predicate | 2026-09-01, Stage 5 |
| **D-S5-3** Composition-lock conflict | **(α) one unsliced umbrella** — S1–S4 are commit sequencing, not membership | 2026-09-01, Stage 5 — AI-003 closed |
| **D-S5-4** Selector resolution scope | **deployment-global at v1** — no `project-schema.md` V-rule owed | 2026-09-01, Stage 5 |
| **D-S5-5** Two omitted surfaces | informational — absorbed into S2 and S4 | 2026-09-01, Stage 5 |

## Action-Item Ledger

| id | status | note |
|----|--------|------|
| AI-001 | done | D-Q2 rendered at the scaffold gate |
| **AI-002** | **discharged at this commit** | #2577's File Change Matrix rows and AC-4 Verification Plan row are authored above, with literal directory prefixes on every row and a reproducible AC-4 probe carrying a control arm |
| AI-003 | done | Discharged by D-S5-3(α) — no membership change, lock intact |
| AI-004 | open | Roadmap placement revisit; deferred to Stage 13 per D-Q2(D) |
| AI-005 | open | Axis-mechanism discovery pass; resolved at Procedure 7a |

## Deviation Log

| # | Declared | Disposition | Basis |
|---|----------|-------------|-------|
| — | — | none to date | No declared ADD has failed to ship. A row is owed here, carrying the literal `NOT DELIVERED` and the declared path, the moment one does. |

## Verification Evidence

**Stage 6 C4 self-verification** — run at Engineering Commit 2 via `bash release/tools/verify-release-plan.sh release/releases/plans/portfolio-tier-framework-pack_RELEASE_PLAN.md`.

**Roll-up: 9 PASS / 4 FAIL / 5 SKIP / 3 ERROR** over 13 per-issue rows; 0 declared-deferred. Every non-PASS is accounted for below — none is unexplained, and none is presented as clean.

| Verdict class | Rows | Reading |
|---|---|---|
| **PASS (9)** | #3616 AC-1, AC-2 · #2577 AC-7 · FCM-COVERAGE, FCM-1, FCM-2 · PROV-COVERAGE, PROV-PRESENCE, PROV-GRAMMAR | #3616's two criteria are verified against the delivered ADR. Both declared ADDs are confirmed `declared-add-delivered` against the diff. The `domain_practice` label is present and grammar-conformant (form X, 2026-09-01). |
| **FAIL (4)** | #2577 AC-1, AC-2, AC-3, AC-4 | **Expected, and correct.** These read the BEFORE state: #2577's engineering has not run, so the altitude section, the PMI matrix row, the selector, and the artifact shapes are all genuinely absent. A PASS here at this instant would be the defect. They convert to PASS as #2577's slices land. |
| **SKIP (5)** | #2577 AC-5 (`git` outside the executor's closed verb allowlist) · INT-1, INT-2, CIAC-1 (documented-decision / tool outside allowlist) · PROV-DELTA (no Stage-4 comment supplied as a producer surface) | Honest non-executions, each naming its reason. The executor declining to run a verb is a statement about the executor, not a defect in the method. |
| **ERROR (3)** | #3616 AC-3, AC-4 · #2577 AC-6 | `unclassified-method (no family match)`. All three are genuine documented-decision methods with no local runnable command — two are network reads of live GitHub state, one is a worked-example resolution. The classifier is keyword-driven with no declaration column, so a prose method cannot route to a family. **Not padded with keywords to make the ERROR disappear** — that would buy a verdict rather than earn one. |

**A false PASS was found and removed during this run.** An earlier draft of AC-4's method carried the backticked fragment `` `test -f` `` intending "test each named path". The executor extracts the first backticked span whose leading token is an allowlisted verb, so it ran `test -f` **with no operand** — which evaluates the non-empty string `-f` and exits 0. AC-4 reported **PASS while all seven files were absent.** The method was rewritten as a complete `ls | grep -cE` assertion over the *named* set, and AC-4 now correctly reports FAIL. Recorded because the failure mode generalizes: a command fragment quoted for readability becomes a runnable command that always succeeds.

**Two further authoring defects were found by running the checker and are fixed:** a phantom `CIAC-1` row with empty method and expected cells, caused by a following paragraph opening with a bolded `CIAC-N` token that the section parser read as a second entry; and both #3616 ADD rows classifying as *conditional* because an in-fence block label contained the word "un**conditional**", which the block-level `/CONDITIONAL/i` test matches case-insensitively. With both fixed, `conditional=0` and the two obligations assert as real unconditional deliveries.

**Release-level checks:** `python3 release/tools/check-adr-numbers.py` → **PASS** (170 ADRs, contiguous 001..170, no duplicates). `python3 release/tools/check-adr-durability.py` → exit 0, **zero findings on ADR-170** (two were found on first authoring — a hardcoded SHA and a live corpus count — and both were repaired rather than shipped). `release/tools/check-release-links.py` → 0 broken links; the plan carries **zero markdown links** (every path is in backticks), so the workspace-rooted-link obligation cannot be violated at the Stage-12 rename.

**Runtime suite:** `test-run` / **`suite-skip`** — the change surface is doc / governance / spec / config-schema only and matches the runtime-suite selection map's explicit no-match row. The honest no-op, not a fabricated suite pass.

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | N/A | no `SKILL.md` in the matrix |
| Manifest execution | | N/A | no Layer-2 propagation target |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Change Description

(Authored by the Stage-6 spoke at PR-creation time per the Change Description Protocol. Operator-facing, pre-merge. Distinct from the user-facing release note authored at Stage 13 Close.)

### Outcome

A portfolio governance framework gets an altitude of its own. The release records **where portfolio-tier pack content lives** — a framework-keyed subdirectory under the existing template registry — and settles the contradiction #2577 carried in its own body between "content of the pack" and "the neutral core". Both horns were wrong, and the record says why, with each rejected home carrying its verified disqualifier. For the operator at Stage 9, the reviewable substance is one decision record plus the umbrella built against it; the project-tier pack grammar is provably untouched, which is what makes the decision cheap to reverse.

### Issues delivered

| # | Outcome (one line) | Status |
|---|--------------------|--------|
| #3616 | The pack shape and content location are decided and recorded durably as ADR-170; the slice plan is posted, and #2577's File Change Matrix and AC-4 probe are authored | **DONE** |
| #2577 | The portfolio-framework altitude, selector, PMI artifact shapes, and registry wiring — engineered as one unsliced umbrella in the S1→S4 commit sequence | *pending its Engineering; this row is filled at PR assembly, not predicted here* |

### Key decisions

- **D-Q1 (a):** both cards ship together, diverging from both the spoke's and the hub's recommendation of spike-only. The consequences are carried as R1/R2, not re-litigated.
- **D-Q4 (i):** the shape decision lands as a core-scope ADR rather than a GitHub comment, so a later slice has something citable.
- **D-S5-1 (C):** the general axis-mechanism question is routed to a discovery pass rather than designed inline — the platform's third orthogonal axis ships as a one-off, and says so.
- **D-S5-3 (α):** #2577 is one unsliced umbrella; its slices are commit sequencing, so the Composition Lock stays intact.

### Reversibility

**MODERATE — HIGH confidence.** `git revert -m 1 <merge-commit>` for the whole release; per-issue reverts per the Rollback Strategy above, with #2577's S2 selector trio reverting as one unit.

### Cross-references

- Release plan: this file
- Milestone: `portfolio-tier-framework-pack`
- Shape record: `core/ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md` (number claims at merge)

## Change Log

| Date | Stage | Change |
|------|-------|--------|
| 2026-09-01 (Tuesday) | 6 — Engineering Commit 0 | Plan file authored on the release branch from the Stage-4 sub-task comment plus the hub's two follow-on comments and the Stage-5 design output. Carries the nine Commit-0 Survival Set elements. Transcription correction applied: #374's closure/absorption is dated **2026-07-01**, not the Stage-4 comment's 2026-06-29. Version re-verified: `anchor()` v4.45, next-free v4.46, free on three arms with live controls. |
