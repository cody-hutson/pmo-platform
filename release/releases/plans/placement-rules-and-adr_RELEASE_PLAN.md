---
title: Release Plan — placement-rules-and-adr (Non-tracked data is homed by its risk class)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v5.02; the concrete number binds at the Stage-12 atomic claim)
milestone: placement-rules-and-adr
release_class: cross-cutting
reversibility: EXPENSIVE once ratified / Confidence MEDIUM — one superseding ADR, one standard, one config selector and wording on governance surfaces, on one branch with one merge. Before merge every slice drops by branch revert (CHEAP); after merge and before the Stage-13 ratification a revert of the merge restores every file, because nothing moves and no runtime write path changes (MODERATE); once the ADR is ratified it changes only by a superseding ADR (EXPENSIVE). A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `placement-rules-and-adr`

**Milestone:** `placement-rules-and-adr` (milestone 428), wave 1 of the parent epic #8005. The Stage-4 planning sub-task **#8663** carries the approved plan (three parts), the Stage-4 gate's Decision Recorded and the Collective Review scope-lock Decision Recorded. The Stage-5 designs and their independent Phase A6.5 adversarial reviews are on **#8665** (#8016), **#8666** (#6627), **#8668** (#8017) and **#8670** (#8018). This file is Engineering Commit 0, authored by the first Stage-6 spoke on **#8671** (#8016).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v5.02`** (the next-free minor recomputed at this commit). The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/placement-rules-and-adr`, one pull request opened in **draft** after slice 1 (#8016) lands, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — Commit 0 and slice 1 (#8016, sub-task #8671), then slice 2 (#6627), slice 3 (#8017) and slice 4 (#8018), one Engineering spoke at a time, each syncing the release branch before it starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `cross-cutting` — trigger (c), three native in-bundle compositional edges (four with #6627's); Stage 9 review depth **Deep** (§ Release Class declaration).

**Nothing moves.** No file move, no resolver change, no runtime write-path change. Every running hub, this release's own included, keeps resolving hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>` until a later wave's cutover.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8663 (comments `issuecomment-6662725980`, `-6662728019`, `-6662730017`) and is amended by later records, in order: the Stage-4 Decision Recorded (`issuecomment-6662949622` — plan approved as recommended: D-input2 = B, D-input4 = B, D-hubstate-wording = A, D-ADR141-Scope = A whole, `cross-cutting`; D-Version, D-ADR032-Owner, SINGLE and P0 recorded), the four Stage-5 designs, their four Phase A6.5 adversarial reviews, and the Collective Review scope-lock Decision Recorded (`issuecomment-6666315814` — scope hard-locked through Stage 9; CR-1 to CR-6 and the listed additions). Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): one ADR, one reference-tier standard, protocol text inside existing structure and one config key, per the Bump-Class Selection Guide rows "Protocol text addition or modification" and "Reference document addition or update". Provisional display `v5.02`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-05 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering complete: Commit 0 and slices 1–4 (#8016, #6627, #8017, #8018) landed, each with its plan update, and § Change Description added; next, Stage 7 Dev Testing |
| **Branch** | `release/placement-rules-and-adr` |
| **PR** | #8817 — opened in **draft** at Stage 6 Phase C2 after slice 1; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `placement-rules-and-adr` |
| **Baseline pin** | `origin/main` `ac96b3ea` (the Stage-4 pin); Commit 0 is written on `b1042eec`, which adds only the v5.01 close-out records to the pin |
| **Parent epic** | #8005, wave 1 of 8 |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-05, domain: governance }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform artifact — ADRs, standards, disciplines, a rules mirror source, a how-to, a config template and its schema, `deploy.sh`, a schema reference and a docs catalog page — so no external body of practice is consumed. Dominant domain **`governance`**; secondary domain software (`deploy.sh` Check 33 and the schema declaration). Transcribed unchanged from the Stage-4 plan (Release Class declaration).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `b1042eec` (`b1042eecd6294d4c460c109f2c4b8dd6ed9896a9`) — the Stage-4 pin `ac96b3ea` plus the v5.01 Stage-13 close-out (7 release-record files, 0 in this matrix). This file is written on that base |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha b1042eecd6294d4c460c109f2c4b8dd6ed9896a9 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v5.02`** (exit 0; "would claim v5.02 (no tag pushed)") — equal to the Stage-4 provisional display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan comparing exact (major, minor) version
             tuples carrying no patch component
Denominator: 456 ls-remote lines (222 distinct versions; the highest is v5.01); 227 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             2,934 lines
Control - sensitivity: the same scan on the v5.01 slot — 2 tag lines, 1 Release line and
             7 ledger lines. Every arm returns non-zero, so a zero on the v5.02 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (tuple equality, so v5.0.2 and
             v5.020 are different tuples, not prefixes)
Extraction:  the whole ls-remote output, the whole Release list and the whole ledger
             (944,477 bytes) read from origin/main, never the worktree copy
Result:      0 occupants of the (5,2) slot on every arm
Verdict:     CLEAN — v5.02 is free and equals the recomputed next-free; no HALT
```

**Known concurrent claimants of the same slot:** the in-flight siblings that compute a minor bump (§ Cross-PR Overlap Audit → In-Flight Release Roster). The first to merge binds `v5.02` and the others recompute at their own claim; this is the Tier-S version-axis serialization point the Stage-4 audit recorded, and it is resolved by the atomic claim, not here.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp placement-rules-and-adr`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### ADR number

The new decision record's number was taken at this commit from `release/tools/renumber-adr.py --next-free` against the mainline anchor, and it is written **only** in machine-read positions: the record's filename, `title:` and H1, its `core/ADRs/README.md` heading and link, and the appended `superseded_by:` entries on ADR-017, ADR-032, ADR-046 and ADR-096. Every prose citation of the record, in every file of this release, is the slug token `{{ADR:non-tracked-data-homed-by-risk-class}}`, never inside a link target. This plan carries the number nowhere: its matrix row spells it `ADR-NNN`. Stage 12 binds it with `renumber-adr.py --detect`, `--renumber` on a collision, then `--stamp` and `--stamp --check`.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-05`** (Thursday). The one load-bearing date it takes is the new ADR's `date:` field (#8016 Stage-5 design, § Date Variable). Every other date in this release's artifacts is a fixed historical anchor and is written literally.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 and scope-lock conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-8` (CIAC-1 to CIAC-3 widened for D-hubstate-wording = A; CIAC-7 reworded per the #8016 Stage-5 design and its review FM-2) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as Stage 5 and the scope-lock resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA `ac96b3ea`) | § Header and § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Order | Issue | Title (abridged) | Size | Sub-task (Stage 6) |
|---|---|---|---|---|
| 1 | #8016 | Author the ADR that supersedes ADR-141: non-tracked data is homed by its risk class | M | #8671 |
| 2 | #6627 | Declare the release-corpus home selector and decide the corpus location | M | #8673 |
| 3 | #8017 | Codify the instance-data placement standard | M | per Procedure 1 |
| 4 | #8018 | Reconcile the governance surfaces that state where data lives to the placement standard | M | per Procedure 1 |

16 raw points → **effective_pts 21** (`cross-cutting` class weight 1.3), inside the 15–25 band. Card bodies were amended at the Stage 5 → 6 transition from their Stage-5 designs, adversarial reviews and the scope-lock; each amended body is that card's AC contract.

### Exclusions

- **Every later wave of #8005** — the resolver and switch, the carve-out hook change, the commit guard, the installer, the needle update, the migrations and the cleanup wave. This release decides and documents; it builds no mechanism.
- **Any file move, delete or resolver change** — release-wide explicit non-scope (§ File Change Matrix).
- **ADR-141's status transition on the release branch** — it lands at the Stage-13 ratification beat, in the chore PR (§ Delivery Strategy).
- **Cross-milestone writes the scope-lock did not authorize** — a relay to #8021 (moot under CR-5 (a)), a population-owner comment on #8029, and a #8005 map note that the release-hub playbook is unowned. Held as residuals for the hub.

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-05)

Answer, verbatim: *"Approve as recommended"*.

| Decision | Chosen |
|---|---|
| Plan + Release Outcome Statement | approve |
| D-input2 — where the leak-risk home lives | **B** — the install's per-user folder (exact subpath at Stage 5; settled by CR-2) |
| D-input4 — usage-telemetry home | **B** — install-level, beside the leak-risk home; derived per-repository rows stay admissible to `/local-state/telemetry/` (exact path settled by CR-1) |
| D-hubstate-wording | **A** — `core/standards/hub-session-continuity.md` joins #8018 as target wording only; today's `<OPERATOR_INSTANCE_HUB_STATE_PATH>` pointer stays the resolving path |
| D-ADR141-Scope | **A** — whole supersession |
| D-ReleaseClass | `cross-cutting` |

Recorded determinations: **D-Version** minor, provisional `v5.02`. **D-ADR032-Owner** — #8016 owns every ADR frontmatter and status edit (ADR-141, ADR-032, ADR-096, the README entry), appending, never replacing; #6627 fills the corpus-location decision item inside the new ADR. **D-C** SINGLE. **D-Concurrency** P0.

### Collective Review scope-lock (operator, 2026-11-05)

Answer, verbatim: *"Lock as recommended"*. Scope is hard-locked through Stage 9; an override needs a Decision Briefing with an impact assessment.

| ID | Decision | Chosen |
|---|---|---|
| CR-0 | Scope-lock | approve, with the choices below and the additions listed |
| CR-1 | Usage-telemetry home | **T2** `${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/` (realizes ADR-017 Decision 4) |
| CR-2 | Leak-risk home path | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/`, plus two build obligations in the ADR's Consequences (sandbox parity; a loud failure on an empty home), owned by #8020 and wave 4 |
| CR-3 | Main-checkout carve-out | **(a) enumerated** — `/local-state/`, `/analysis/<sub>/`, `/roadmaps/<name>`, with a register↔hook parity check owned by #8019 / #8029 (amends the epic's D1 "`/local-state/` only") |
| CR-4 | Release-corpus classification | **(W) widen** — the corpus is tracked repository content; #8016 widens the ADR-032 in-part label at slice 1, and #6627's item names ADR-032's drivers and the accepted cost |
| CR-5 | Reserved `local-state` corpus value | **(a) drop it** — the ADR records `tracked` in force; a non-tracked corpus home is decided by the change that builds its reader |
| CR-6 | `core/rules/operations-bridge.md` link | the allow-link marker |

**Additions inside the capability** (Tier 1 [ADJUST], applied to card bodies and to this plan at Commit 0): an ADR-017 in-part edge and an ADR-046 in-part edge; a `### Carried forward from ADR-141` subsection; ADR-141's whole-supersession status flip lands at the Stage-13 ratification beat with the new ADR's flip; a named-gap row in `core/standards/gate-efficacy-standard.md` (#8017 F-1, population per the #8017 review FM-1); `core/schemas/platform-config-schema.md` (#6627 F-1); the Classification Rule fix widened to step 2 (#8018 R1); the Stage-13 grading probe fixed per the #8016 review FM-2; #8017's surface register widened per its review PR-1, and — conditional on ms#429's own Collective Review of #7937 D-3 — a row for the FinOps store's preserved schema-snapshot file and its ignore rule.

---

## Dependency Graph

Native edges, GraphQL `blockedBy` / `blocking` (Stage 4, 2026-11-05; the #6627 edge added by the hub after plan approval):

```
#8016 ──▶ #8017 ──▶ #8018
  │                  ▲
  └──────────────────┘          (#8016 ▶ #8018 is also a native edge)
  │
  └──▶ #6627                    (native after the gate: "#6627 blocked by #8016")

#6627 ┄┄▶ #8017                 (soft ordering only: the standard cites the corpus decision)
outbound (later waves):  #8016 ▶ #8019   ·   #8017 ▶ #8020, #8022, #8024, #8029
inbound from outside:    none
```

The graph is a DAG (topological order #8016, #6627, #8017, #8018); 0 cycles.

---

## Implementation Sequence

One branch `release/placement-rules-and-adr`, ordered commits, merged once. Slices land strictly in this order (D-Concurrency P0):

| Order | Slice | Card | Depends on | Why here |
|---|---|---|---|---|
| 0 | Engineering Commit 0 — this plan file | — | plan approval + scope-lock | Procedure 0 § Canonical location; the Commit-0 version re-verify and the stamp-manifest assertion |
| 1 | The superseding ADR and its supersession pointers | #8016 | — | Wave 0 of the epic; every other slice cites it |
| 2 | `corpus_home` selector + the corpus-location decision item | #6627 | #8016 (native) | Fills its decision item in the ADR while the ADR is still `Proposed`; lands before the standard so #8017 cites a decision already on the branch |
| 3 | The placement standard | #8017 | #8016 (native); #6627 (soft) | Single writer of the standard; registers every surface against the ADR's class table |
| 4 | Governance-surface reconciliation | #8018 | #8016, #8017 (native) | Cites the standard; target wording keeps today's pointer |

**Commit-order change from the bundle's list (#6627 moved from 4th to 2nd)** — approved at the Stage-4 gate: each file has a single writer per slice.

### Slice 1 — #8016 (the superseding ADR)

**Source of truth:** the Stage-5 design on #8665 (`issuecomment-6664106989`, `-6664108930`, `-6664110961`; Output for Stage 6, Changes 1–5), as amended by its Phase A6.5 review (`issuecomment-6665479829`) and the scope-lock. The amended #8016 body is the AC contract.

- **New record** `core/ADRs/ADR-NNN-non-tracked-data-homed-by-risk-class.md`, `status: Proposed`: Context (the #8005 evidence); Decision — the class table, D1 to D8, a `### Carried forward from ADR-141` subsection (personal-area non-tenancy; every override honored today keeps resolving until its class's cutover, with each cutover stating how a family-wide override maps onto the class homes; one resolver per class is the only site that spells a home; skip-if-exists, dry-run-aware and rollback-recorded provisioning; the leak-risk class out of every tree), Layering inputs 1 and 2, the install-scoped telemetry home and a `### Release-corpus location` heading whose one placeholder sentence slice 2 replaces; Alternatives (D1 inside `.git/`, D1 per-worktree, the class-defined carve-out, the name, one shared log, the three rejected leak-risk homes, the two rejected telemetry homes, an in-part ADR-141 edge); Consequences, including the two CR-2 build obligations and the move-to-another-machine cost; Related ADRs; a `## References` block carrying every issue number.
- **D1's carve-out** is the CR-3 enumerated set — `/local-state/`, `/analysis/<sub>/`, `/roadmaps/<name>` — stated as an amendment of the epic's D1, with the hook's predicate kept static, a register↔hook parity check named by owner, and the channel scope stated (the file-write channel is guarded; the shell channel's missing write guard is the residual the hook's own rule already records as accepted).
- **`supersedes:`** `ADR-141 whole` plus in-part entries on ADR-017, ADR-032, ADR-046 and ADR-096. Labels are comma-free (the parser splits the field on commas) and name a structural referent. ADR-017's label covers Decision 4's workspace placement of leak-risk content and its routing of event logs; ADR-032's carries the CR-4 (W) widening; ADR-046's names Decision 4's runtime-state criterion; ADR-096's names the store's home and Decision 3's admission of a git-ignored in-repo path (the guard is tightened, not reused).
- **Reciprocal pointers, appended, never replacing:** ADR-017, ADR-032 and ADR-096 gain one `superseded_by:` entry each after their kept entries; ADR-046 gains the field. Each gains a Related ADRs (or, on ADR-017, composition) limb; ADR-046 gains its missing `## Related ADRs` section; ADR-096 gains the ADR-141 limb it lacked.
- **`core/ADRs/README.md`:** the record's thematic entry under § Distribution-architecture ADRs (a Status cell that points at the record's own `status:` field), and the ADR-032 entry's clause recording its in-part supersession, so no corpus migration reads as pending (#6627 finding F-3).
- **ADR-141 is not touched on the branch.** Its § 5.1 transition is Change 6 of the design, executed at Stage 13 Phase A13 (§ Delivery Strategy).
- **Spellings:** the out-of-tree container appears only rooted — `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` today, `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` as the target.

### Slice 2 — #6627 (selector + corpus location)

Per the Stage-5 design on #8666 and its review, under CR-4 (W) and CR-5 (a): `corpus_home` in `operator.toml.template` `[adapters]` with the default `tracked` (the section comment reworded: a placement selector is not an external surface); the matching declaration in `operator-toml-schema.json`; Check 33's adapter loop extended to the sixth selector (AC2's failing control is a Stage-7 fixture run, so no new script); `corpus-home-adapter-constraints.md` reconciled, CH-1..CH-4 unchanged; `docs/platform-config-reference.md` and its canonical `core/schemas/platform-config-schema.md` reconciled to six selectors; the ADR's Release-corpus location item filled — `tracked` in force, no reserved non-tracked value, the selector stated as not yet read with its consumer named, ADR-032's drivers named and their cost accepted; AC5's two live surfaces stop framing the corpus extraction as pending. No file moves; `check_paths()` behaviour unchanged.

### Slice 3 — #8017 (the placement standard)

Per the Stage-5 design on #8668 and its review, under the scope-lock: `core/standards/instance-data-placement-standard.md` with the ADR's class vocabulary (class names spelled as in the ADR's class table), the homes, the register of in-repo git-ignored homes (exactly `/local-state/`, `/analysis/`, `/roadmaps/`, held in parity with the carve-out hook's static set), the admission test, the telemetry home, the corpus row, the protections, the folder-plus-README idiom, the five-step checklist naming #8029 in a References block, a surface register covering the pinned fit/gap population and widened per review PR-1, and the future-token naming rule. The depersonalization spec's § 4 registry gains a `Class` column appended right of its first cell on all 17 rows, with no new `<OPERATOR_INSTANCE_…>` token in tracked text; the analysis-workspace standard, the taxonomy and the depersonalization spec cite the standard instead of restating placement (the depersonalization spec keeps its personal-area non-tenancy rule or points at the ADR subsection that carries it). `core/standards/gate-efficacy-standard.md` gains the checklist's named-gap row whose Population is a coverage census.

### Slice 4 — #8018 (governance-surface reconciliation)

Per the Stage-5 design on #8670 and its review, under the scope-lock: six surfaces — `core/CLAUDE.md.template` (Classification Rule steps 2 and 3), `core/disciplines/architecture-overview.md`, `core/disciplines/memory-architecture.md`, `core/rules/operations-bridge.md` (mirror pair; its link to the standard carries the allow-link marker under CR-6 and uses the leading-`/` form), `release/references/how-to/hub-spoke-bridge.md` (State Persistence row) and `core/standards/hub-session-continuity.md` (target wording only). Target-wording template: *"<data> is <class>; its governed home is <target home> per the placement standard; until this repository's cutover it still resolves to today's path through `<token>`."* The slice records the enumerated list of target-home statements and their today's pointers that AC1 grades.

**Integration points:** the slug token joins the ADR and every citing file; the class vocabulary joins the standard and the six surfaces (CIAC-2/3); `corpus_home` joins the template, the schema, Check 33, the ADR and the standard (CIAC-5/6); today's hub-state token joins the ADR's D5 switch and the hub-spoke bridge (CIAC-8).

---

## Stage Applicability Matrix

Stage 5 activation bias for `cross-cutting` is ALL; no card is trivial. Stages 7–8 apply to all four: each card's ACs are graded by executable checks (R6 reciprocity, ADR-number integrity, C70d/C70e, Check 9, Check 14, Check 33, the tolerance suite), not prose alone.

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 | Stage-5 outcome |
|---|---|---|---|---|---|---|
| #8016 | yes (done) | yes | yes | yes | release-scoped | whole edge at A13; ADR-017 and ADR-046 in-part edges; enumerated carve-out; carried-forward subsection; CR-2 obligations |
| #6627 | yes (done) | yes | yes | yes | release-scoped | `corpus_home`, default `tracked`, no reserved value; fixture-run control; schema reference added |
| #8017 | yes (done) | yes | yes | yes | release-scoped | four classes plus the install-scoped variant; three registered in-repo homes; Class column appended right; named-gap row |
| #8018 | yes (done) | yes | yes | yes | release-scoped | six surfaces with the target-wording template; Classification Rule steps 2 and 3 |

Parallel-eligible per parallel stage: Stage 5: 4 · Stage 7: 4 · Stage 8: 4 (Stage 6 is serial).

---

## File Change Matrix

```
# ── Engineering Commit 0 ──
release/releases/plans/placement-rules-and-adr_RELEASE_PLAN.md  add
# ── #8016 — the superseding ADR (slice 1) ──
core/ADRs/ADR-NNN-non-tracked-data-homed-by-risk-class.md  add
core/ADRs/ADR-017-distribution-architecture.md  edit
core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md  edit
core/ADRs/ADR-046-roadmap-instance-in-repo-home.md  edit
core/ADRs/ADR-096-finops-usage-store-and-data-home.md  edit
core/ADRs/README.md  edit
# ── #6627 — corpus_home selector + corpus location (slice 2; also fills one decision item in the slice-1 ADR) ──
core/config/operator.toml.template  edit
core/config/operator-toml-schema.json  edit
core/deploy/deploy.sh  edit
release/references/standards/corpus-home-adapter-constraints.md  edit
docs/platform-config-reference.md  edit
core/schemas/platform-config-schema.md  edit
release/references/standards/release-notes-standard.md  edit
core/references/reference/operator-instance-home-and-isolation-key.md  edit
# ── #8017 — the placement standard (slice 3) ──
core/standards/instance-data-placement-standard.md  add
core/standards/depersonalization-spec.md  edit
core/standards/analysis-workspace-standard.md  edit
core/standards/public-repo-vs-operator-instance-taxonomy.md  edit
core/standards/gate-efficacy-standard.md  edit
# ── #8018 — governance-surface reconciliation (slice 4) ──
core/CLAUDE.md.template  edit
core/disciplines/architecture-overview.md  edit
core/disciplines/memory-architecture.md  edit
core/rules/operations-bridge.md  edit
release/references/how-to/hub-spoke-bridge.md  edit
core/standards/hub-session-continuity.md  edit
# ── #8016 — Stage 13 Phase A13, on the Phase B chore PR (not the release PR) ──
core/ADRs/ADR-141-operator-instance-home-is-a-workspace-root-sibling.md  edit
```

#### Read-only inputs

READ — not edited: `release/tools/renumber-adr.py` · `release/tools/check-adr-durability.py` · `release/tools/check-adr-numbers.py` · `release/tools/claim-version.sh` · `core/deploy/tools/check-operator-toml-schema.sh` · `core/deploy/tools/path-leak-patterns.sh` · `core/deploy/tools/check-doc-links.py` · `core/deploy/lib-instance-path.sh` · `release/tools/automated-closeout.sh` · `release/tools/tests/test_corpus_home_tolerance.sh` · `.github/corpus-home-tolerance.arming` · `core/rules/bypass-mode-readiness/block-destructive.md` · `core/schemas/adr-schema.md` · `core/standards/adr-authoring-guide.md`.

#### Release-wide explicit non-scope

NOT EDITED: no resolver (`lib-instance-path.sh`), no hook, no installer or `update.sh`, no skill or package, no tool under `release/tools/`, no file move or delete, no change to where any running release writes.

**The Stage-4 conditional rows are resolved at this commit.** `D-HUBSTATE-WORDING-A` fired (gate D-hubstate-wording = A), so `core/standards/hub-session-continuity.md` is promoted. `STAGE5-INPART-EDGE` fired for ADR-046 (scope-lock addition, review CD-1), which is promoted, and did not fire for ADR-167 or ADR-178 (prose relations; both rows removed). ADR-017 enters as a new unconditional row (scope-lock addition). `NEW-TEST-SCRIPT` did not fire (#6627's AC2 control is a Stage-7 fixture run), so the allowlist row is removed. The scope-lock additions `core/standards/gate-efficacy-standard.md` and `core/schemas/platform-config-schema.md` enter as unconditional rows. **No CONDITIONAL row remains.**

**ADR-141's row** is an edit made outside the release pull request, in the Stage-13 ratification commit; the release diff leaves ADR-141 unchanged, and #8016 AC-2 grades both facts.

**Zero `add` rows for executables** → the new-executable companion obligation does not fire. **No path is renamed, moved or deleted** → the mover set is empty. **Packages:** none of these paths is a `TEMPLATE_SYNC_MAP` source, so no `packages/*.skill` rebuild is owed. **Rules mirror:** `core/rules/operations-bridge.md` is a mirror-pair member; the post-merge `./deploy.sh --deploy` re-lays its deployed copy.

### Agent-Editability Read

Derived at `ac96b3ea` (Stage 4) and re-read for the rows added here. Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh` BLOCK-AUTONOMY-001 — basenames `CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md` at any depth, plus untracked `.claude/` arms. Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — skill `SKILL.md` and `references/` paths only.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class |
|---|---|---|---|---|
| #8016 | the new ADR, ADR-017, ADR-032, ADR-046, ADR-096, `core/ADRs/README.md`; ADR-141 at Stage 13 | no | no | unconstrained |
| #6627 | the template, the schema, `deploy.sh`, the constraints standard, the catalog page, `platform-config-schema.md`, the two AC5 surfaces | no | no | unconstrained |
| #8017 | the new standard, the depersonalization spec, the analysis-workspace standard, the taxonomy, `gate-efficacy-standard.md` | no | no | unconstrained |
| #8018 | `core/CLAUDE.md.template` (basename is not `CLAUDE.md`), the two disciplines, `core/rules/operations-bridge.md` (the repo source, not the deployed copy), the hub-spoke bridge, `hub-session-continuity.md` | no | no | unconstrained |
| plan | this file | no | no | unconstrained |

All four cards are `unconstrained` — ordinary Engineering spokes. Every change is still governed (issue + approved plan + PR).

---

## Contention Map

**Within release (serial P0 order resolves every row):**

| File | Cards | Resolution |
|---|---|---|
| the new ADR | #8016 (author, frontmatter, every pointer edit) · #6627 (one decision item, body only) | Sequential commits, #8016 first; #6627 edits the body while the record is `Proposed`, replacing the placeholder sentence under `### Release-corpus location` |
| `core/standards/instance-data-placement-standard.md` | #8017 (author) · cited by #8018 and by #6627's decision | Single writer (#8017), after #6627's decision exists |

No other path is claimed by two cards.

---

## Cross-PR Overlap Audit

### Baseline SHA

`ac96b3ea123f6092070f29ca380ad159c1d87ab3` (`origin/main`, 2026-11-05T15:34Z) — the `<release-base>` for A0.7, G-PL4, the sibling-merge trigger and Stage 9 A6.5. Engineering Commit 0 is written on `b1042eec`; `git diff --name-only ac96b3ea b1042eec` lists 7 release-record files (`.version`, `CHANGELOG.md`, the log, index, digest, the v5.01 notes and plan), 0 of them in this matrix.

- **Open at Stage 4:** draft PR #8651 (ms#438) — 24 files, 1 in this matrix: `core/ADRs/README.md`, one appended line in another section (`overlap_class: append-pattern`, informational per ADR-005; settled by rebase at merge).
- **Not in flight but sharing files:** ms#381 and ms#414 — no branch at Stage 4.
- **Structural blast radius:** the mover set is empty, so `SURFACE(R)` reduces to the version-slot token `Δversion/minor` — a Tier-S serialization point on the version axis only, resolved by the atomic claim.
- **Sibling-merge trigger:** re-run `git log ac96b3ea..origin/main --name-status --find-renames` at Stage 9 entry and intersect with this matrix.

### In-Flight Release Roster

**Measured at:** `ac96b3ea` · `2026-11-05T15:34:06Z` (Stage 4) · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `guards-judge-every-spelling-alike` | `#8651` | `fc556c66` | `minor` | `v4.82` (stale) | `v5.02` | `core/ADRs/README.md` |

**Commit-0 observation (a pinned measurement, no verdict; Stage 9 Phase A6.6 re-measures and renders `CONTENTION-*`).** At `b1042eec`, Engineering Commit 0, the population is 4: open pull requests with a `release/*` head — #8651 (`guards-judge-every-spelling-alike`, head `fc556c66`), #8811 (`sequencing-layer-foundation`, head `00785cd4`) and #8814 (`stage-document-model-decision`, head `7d9b0015`) — plus the remote head `release/composition-method-host-decision` (`19a0afe8`) with no pull request. Against this matrix: #8651 still intersects at `core/ADRs/README.md` only; the other three intersect at 0 paths; none declares a rename or delete. Three of the four each add an ADR at the slot this release's new record takes (R-1). Bump-class and next-free for the three new siblings are not read here.

---

## Risk Register

| ID | Risk | Type | L | I | Mitigation | Owner |
|---|---|---|---|---|---|---|
| R-1 | ADR-number race: at Commit 0, three sibling branches each add a record at the slot this release's new ADR takes (#8651's branch, `sequencing-layer-foundation`, `composition-method-host-decision`) | dependency | High | Med | Number only in machine-read positions; prose uses the slug token; Stage 12 `--detect` → `--renumber` → `--stamp` → `--stamp --check` | Stage 6 / Stage 12 |
| R-2 | Supersession represented wrongly: a `whole` `superseded_by:`, a `status:` flip on an in-part target, or a replaced (not appended) pointer orphans an edge | scope | Med | High | D-1 (b): ADR-141's transition at A13; append-not-replace with the byte-prefix assertion; R6 graded on the whole-corpus run with a bound base (CIAC-7), never on the CI form alone (R-18) | #8016 Stage 6 / Stage 13 |
| R-3 | `corpus_home` added to the template without the schema declaration → Check 70 and the `operator-toml-schema` CI job fail | contention | High (if unmitigated) | Med | The schema row in this matrix; precedent `74a99050` | #6627 Stage 6 |
| R-4 | Registry class column inserted before the first cell, or a new angle token minted in tracked text → C70d/C70e fail | scope | Med | Med | Append right; no new tokens; examples as prose or `depersonalization-token: allow` | #8017 Stage 6 |
| R-5 | A bare relative spelling of today's container in a new file trips Check 43 and the `gh` path-leak hook | scope | Med | Med | Rooted or token spellings; `path-leak-patterns.sh --scan-file` on every new or edited file | every slice |
| R-6 | Target wording read as current state misleads every running hub before cutover | scope | Med | High | The target-wording template; CIAC-8 keeps today's pointer; the Success-Indicator qualifier | #8018 Stage 6 |
| R-7 | `operations-bridge.md` is a mirror pair; Check 9 reads drift until the post-merge deploy; a non-rooted link to the standard breaks at the mirror | contention | Med | Med | Leading-`/` link form with the allow-link marker (CR-6); post-merge `./deploy.sh --deploy`, Check 9 read by its own `FAIL:` lines | #8018 / Stage 12–13 |
| R-8 | Shared-file contention with ms#438 (`core/ADRs/README.md`, append) and with ms#381 / ms#414 if they start | contention | Med | Low | Rebase at merge; Stage 9 A6.5 re-check | Hub |
| R-9 | Downstream waits: ms#429 homes #7943/#7945 against the telemetry home; #8557 (ms#437) defers its overlay's class to the standard | dependency | High | Med | CR-1's path relayed to ms#429's hub; the standard lands with this milestone | Hub |
| R-10 | Scope creep into a corpus move | scope | Low | High | `tracked` default and no reserved value (CR-5 (a)); no file move in the matrix | #6627 Stage 6 |
| R-11 | Inert selector: `corpus_home` declared but read by nothing reads as delivered | scope | Med | Med | The ADR item states the selector is not yet read and names its consumer; AC3 grades the resolver's tiers independent of the selector | #6627 Stage 6 |
| R-12 | #8017 AC1 population drifts | scope | Med | Med | Population pinned at #8005's 2026-10-27T14:40:25Z body revision | #8017 Stage 6 |
| R-13 | Documentation Impact sections ungradable → G-CL8 FAIL at Stage 13 | scope | Low | Low | All four bodies parse `doc_impact: gradable` at Commit 0 | Hub |
| R-14 | The leak-risk home under a commonly-synced directory | scope | Low | High | Bound: the XDG data home, mode 0700 folders / 0600 files, and the resolver's git-work-tree refusal (the new ADR's Layering input 2 and class table) | #8016 |
| R-15 | Once Stage 13 ratifies the ADR, a wrong decision changes only by a superseding ADR | rollback | Low | High | Deep Stage 9 review; decisions rendered at the gate and the scope-lock | Operator at Stage 9 |
| R-16 | Version slot `v5.02` contested by in-flight siblings | contention | High | Low | Atomic claim binds; Commit-0 re-verify | Stage 6 / Stage 12 |
| R-17 | Reflexive edit: this run's own hub follows `hub-spoke-bridge.md` while slice 4 edits it | scope | Low | Med | The edit is the State Persistence row's wording only; today's pointer kept | #8018 Stage 6 |
| R-18 | R6 in CI resolves edges only inside the changed-file set: it silently skips a superseder-side edge whose far end is unchanged or frozen, and reports a kept target-side entry whose superseder is unchanged as "resolves to no ADR record". Measured on slice 1: the CI form over the five changed records reads **2** such rows (ADR-141 on ADR-032 and on ADR-096); ADR-046's entry on ADR-017 resolves because ADR-046 is in the changed set. They are expected, warn-mode and exit 0, and are not chased | tooling | High | Low | CIAC-7 and #8016 AC-5 grade on the whole-corpus run with a bound base; #8016 AC-2's citation is a direct read | Stage 7 / Stage 13 |
| R-19 | The Stage-12 stamp rewrites the ADR slug token to the record's number alone, so a citing file that carried the slug only as a token would read 0 on CIAC-4 after the stamp | tooling | Med | Low | The standard also names the record by its file-name ending in plain words: the slug reads 4 times before the stamp (3 tokens and the plain-words phrase) and once after it | Stage 6 / Stage 12 |

**Rollback complexity:** low before merge; MODERATE after merge and before ratification; EXPENSIVE after ratification (§ Rollback Strategy).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8017 × #8018 on the six reconciled surfaces):** every reconciled surface cites the placement standard. *Method:* `grep -l -F "instance-data-placement-standard" core/CLAUDE.md.template core/disciplines/architecture-overview.md core/disciplines/memory-architecture.md core/rules/operations-bridge.md release/references/how-to/hub-spoke-bridge.md core/standards/hub-session-continuity.md` expect 6. *Graded at Stage 9 QC3.5 on the merged PR.* Baseline at `b1042eec`: 0 of 6.
- [ ] **CIAC-2 (#8017 × #8018 on the leak-risk class name):** the standard and the six surfaces name the leak-risk class with one term. *Method:* `grep -l -i -F "leak-risk" core/standards/instance-data-placement-standard.md core/CLAUDE.md.template core/disciplines/architecture-overview.md core/disciplines/memory-architecture.md core/rules/operations-bridge.md release/references/how-to/hub-spoke-bridge.md core/standards/hub-session-continuity.md` expect 7. *Graded at Stage 9 QC3.5 on the merged PR.* Baseline: 0 of the six existing files; the standard does not exist yet.
- [ ] **CIAC-3 (#8017 × #8018 on the working-state class name):** the standard and the six surfaces name the working-state class with one term. *Method:* `grep -l -i -F "working state" core/standards/instance-data-placement-standard.md core/CLAUDE.md.template core/disciplines/architecture-overview.md core/disciplines/memory-architecture.md core/rules/operations-bridge.md release/references/how-to/hub-spoke-bridge.md core/standards/hub-session-continuity.md` expect 7. *Graded at Stage 9 QC3.5 on the merged PR.* Baseline: 1 of the six existing files (`hub-session-continuity.md`).
- [ ] **CIAC-4 (#8016 × #8017 on the ADR citation):** the standard cites the superseding ADR by its slug. *Method:* `grep -c -F "non-tracked-data-homed-by-risk-class" core/standards/instance-data-placement-standard.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* Graded on the token before the Stage-12 stamp; it holds after the stamp through the standard's plain-words file-name phrase (R-19).
- [ ] **CIAC-5 (#6627 × #8016 on the ADR's corpus decision):** an ADR records the `corpus_home` selector's location decision. *Method:* `grep -r -l -F "corpus_home" core/ADRs` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* Baseline 0 after slice 1 (the placeholder sentence omits the selector by design); control on the same instrument: `grep -r -l -F "corpus_home" release/references/standards` returns 1.
- [ ] **CIAC-6 (#6627 × #8017 on the corpus's declared home):** the standard states the release corpus's home and names its selector. *Method:* `grep -c -F "corpus_home" core/standards/instance-data-placement-standard.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-7 (#8016 × #6627 on the supersession pointers of ADR-017, ADR-032, ADR-046, ADR-096 and ADR-141):** every in-part edge the new ADR declares is reciprocated, every existing superseded_by entry is kept, and the ADR-141 whole edge is the one edge left pending until ratification. *Method:* declared, verification deferred to `release/tools/check-adr-durability.py` run over the whole corpus with no file list and its diff base bound to the release merge commit's first parent — at the release merge commit it reads exactly one R6 row, the pending ADR-141 whole edge, and at the Stage-13 ratification commit it reads none; the CI job's file-list form is not the grading instrument (R-18). *Graded at Stage 9 QC3.5 on the merged PR (the merge-commit arm) and at Stage 13 after the A13 commit (the ratification arm).*
- [ ] **CIAC-8 (#8016 × #8018 on today's pointer):** the hub-spoke bridge still resolves hub state through today's token while it names the target home — the ADR's D5 switch keeps today's homes until cutover. *Method:* `grep -c -F "OPERATOR_INSTANCE_HUB_STATE_PATH" release/references/how-to/hub-spoke-bridge.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* Baseline 3.

The CIAC lint on the Stage-4 draft read `declared=8 parsed=8 clean=7 declared-deferral=1 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6.

---

## Verification Plan

**AC baseline:** #8016 = **6** criteria, #6627 = **5**, #8017 = **7**, #8018 = **3**, read at `b1042eec` (bodies at `2026-11-05T18:52:58Z`, `2026-11-05T18:55:45Z`, `2026-11-05T18:58:48Z` and `2026-11-05T19:00:38Z` — the Stage 5 → 6 amendments). The Stage-4 baseline at `ac96b3ea` was 4 / 5 / 4 / 3; every row below is rebound to the amended bodies, in each body's criterion order.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8016 | AC-1 | `grep -r -l -E "^supersedes: ADR-141 whole, ADR-017 in-part [(].+[)], ADR-032 in-part [(].+[)], ADR-046 in-part [(].+[)], ADR-096 in-part [(].+[)]$" core/ADRs` expect 1 [READER-GRADED — the Decision records D1 to D8 with D1's carve-out as the enumerated set and its register-to-hook parity check, Layering inputs 1 and 2, the install-scoped telemetry home and a Carried forward from ADR-141 subsection; Related ADRs names ADR-045, ADR-109, ADR-167 and ADR-178 with their relation] | 1 — one record declares the full edge set (0 at the pin; control on the same instrument and directory: `^supersedes: ADR-012 in-part` reads 1) |
| #8016 | AC-2 | `git diff --name-only origin/main...HEAD -- core/ADRs/ADR-141-operator-instance-home-is-a-workspace-root-sibling.md` expect 0 [READER-GRADED — at the Stage 13 ratification beat, a direct read with the bound number shows ADR-141's status leading Superseded and citing the new record, its Status block citing it and a Related ADRs link, applied in the commit that ratifies the new record, with no other change] | 0 — the release PR leaves ADR-141 unchanged · control: the same instrument over the window that created the record, `git diff --name-only 744bdc7e^...origin/main -- <that path>` → 1 |
| #8016 | AC-3 | `grep -r -l -E "^. D1 . A folder in each worktree . " core/ADRs` expect 1 [READER-GRADED — the dot-git folder row for D1 is present too, and each rejected D1 option carries its reason] | 1 (0 at the pin) |
| #8016 | AC-4 | [DEFERRED — graded by the adr-number-integrity job in .github/workflows/repo-integrity.yml on the release PR, and re-bound at Stage 12 by renumber-adr.py, where the number binds] | no duplicate, no gap |
| #8016 | AC-5 | `grep -c -E "^superseded_by: ADR-046 in-part [(].+[)], ADR-[0-9]{3} in-part [(]" core/ADRs/ADR-017-distribution-architecture.md` expect 1 [READER-GRADED — ADR-032 and ADR-096 each carry the same appended in-part entry after their kept ADR-141 entry, and ADR-046 gains the field with that entry; each target's superseded_by value at the release base is a byte prefix of its value at the head; and the whole-corpus durability lint, with no file list and its diff base bound to the release merge commit's first parent, reads exactly the one pending ADR-141 R6 row at the release merge commit and none at the ratification commit] | 1 (0 at the pin; control on the same file: `^superseded_by: ADR-046 in-part` reads 1 at the pin). Stage 7 probes for the reader-graded limb: the same `grep -c -E` shape on ADR-032 (`^superseded_by: ADR-141 in-part [(].+, ADR-[0-9]{3} in-part [(]`), on ADR-096 (`^superseded_by: ADR-141 in-part [(]stated store default[)], ADR-[0-9]{3} in-part [(]`) and on ADR-046 (`^superseded_by: ADR-[0-9]{3} in-part [(]`), each expect 1; the byte-prefix assertion; and the two lint invocations of § Delivery Strategy |
| #8016 | AC-6 | `grep -r -l -F "Build obligation — sandbox parity" core/ADRs` expect 1 [READER-GRADED — the loud-failure obligation is present too, both name the resolver slice and the epic's fourth wave as owners with the resolver slice's issue in the References block, and the record does not claim a sandboxed install already isolates the per-user homes] | 1 (0 at the pin) |
| #6627 | AC-1 | `grep -c -F "corpus_home" core/config/operator.toml.template` at least 1 [READER-GRADED — the documented default keeps today's tracked corpus for an unconfigured install] | at least 1 (0 at the pin; control on the same file: `repo_host` reads non-zero) |
| #6627 | AC-2 | `grep -c -F "corpus_home" core/deploy/deploy.sh` at least 1 [READER-GRADED — a Stage 7 fixture run shows Check 33's adapter loop failing on a template with the selector removed and passing on the shipped template] | at least 1 (0 at the pin; control on the same file: `scheduler` reads non-zero) |
| #6627 | AC-3 | [DEFERRED — graded on the release PR by the required Close-out automation smoke (macOS) job of release-tooling-smoke.yml running test_corpus_home_tolerance.sh, citing fixtures D, C, A, A-prime and B; Stage 7 re-runs the suite locally; Stage 8 reads the decision record for the statement that the selector is not yet read] | PASS-SEAM-LANDED, arming sentinel armed unchanged |
| #6627 | AC-4 | `grep -c -E "^superseded_by: ADR-141 in-part.*, ADR-[0-9]{3} in-part" core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md` expect 1 [READER-GRADED — the Release-corpus location item names ADR-032's decision drivers and accepts their cost explicitly] | 1 (the entry lands at slice 1) |
| #6627 | AC-5 | [DEFERRED — Stage 8 reads release-notes-standard.md, operator-instance-home-and-isolation-key.md and the ADR-032 entry of core/ADRs/README.md for pending framing; Accepted ADR bodies and terminal release records are excluded] | none frames the corpus extraction as pending |
| #8017 | AC-1 | `test -f core/standards/instance-data-placement-standard.md` [READER-GRADED — every member of the pinned fit/gap population, the 18 surfaces at the parent epic's 2026-10-27T14:40:25Z body revision, and every member tracked code resolves under the instance resolver or writes under an in-repo git-ignored path, has a row with its class and home, or a row naming its owner] | exists; population covered |
| #8017 | AC-2 | `grep -c -F "install-provisions-every-home" core/standards/instance-data-placement-standard.md` at least 1 [READER-GRADED — the five checklist steps are present, the enforcing check is named in the References block, and gate-efficacy-standard.md carries the checklist's named-gap row whose Population is the coverage census] | at least 1 |
| #8017 | AC-3 | `grep -c -E "^. Token . Canonical default . operator.toml override field . Codified by . Class" core/standards/depersonalization-spec.md` expect 1 [READER-GRADED — a value from the standard's closed class vocabulary on each of the 17 registered rows, matching the standard's register, and no new operator-instance token in tracked text] | 1 (0 at the pin; control: the same pattern without the final Class cell reads 1) |
| #8017 | AC-4 | `grep -l -F "instance-data-placement-standard" core/standards/analysis-workspace-standard.md core/standards/public-repo-vs-operator-instance-taxonomy.md core/standards/depersonalization-spec.md` expect 3 [READER-GRADED — each cites the standard instead of restating placement rules] | 3 (0 at the pin) |
| #8017 | AC-5 | `grep -c -i -F "admission test" core/standards/instance-data-placement-standard.md` at least 1 [READER-GRADED — the repository's local-state home admits only its own release, run and operating state, the configuration it reads included; content about other areas of work never enters a repository's tree, ignored or not; how a derived row is admitted is stated] | at least 1 |
| #8017 | AC-6 | `grep -c -F "/.local/state}/pmo-platform/telemetry/" core/standards/instance-data-placement-standard.md` at least 1 [READER-GRADED — usage telemetry is classed install-scoped working state at that home, with derived per-repository rows admissible to the repository's local-state telemetry folder] | at least 1 |
| #8017 | AC-7 | `grep -c -F "/roadmaps/" core/standards/instance-data-placement-standard.md` at least 1 [READER-GRADED — the registered in-repo git-ignored homes are exactly local-state, analysis and roadmaps, and the standard states that the carve-out hook keeps a static set held in parity with that table by a check owned by the worktree-sessions slice and the placement-checklist check] | at least 1 |
| #8018 | AC-1 | `grep -l -F "instance-data-placement-standard" core/CLAUDE.md.template core/disciplines/architecture-overview.md core/disciplines/memory-architecture.md core/rules/operations-bridge.md release/references/how-to/hub-spoke-bridge.md core/standards/hub-session-continuity.md` expect 6 [READER-GRADED — each file states the classes it places consistently with the standard, names working-state homes by role, keeps today's resolving path beside each target home, and places no working state out of tree as its governed home, over the enumerated statement list the slice records] | 6 (0 at the pin) |
| #8018 | AC-2 | `grep -c -F "### Classification Rule" core/CLAUDE.md.template` expect 1 [READER-GRADED — step 3 no longer classes the out-of-tree container as tracked, and step 2 no longer classes the git-ignored contents of an in-repo home as inside the repository] | 1 |
| #8018 | AC-3 | [DEFERRED — graded by .github/workflows/link-check.yml on the PR and by a Stage 7 run of check-doc-links.py over the six files against a baseline of 0 findings] | no new broken link |

`ac_baseline: { #8016: 6, #6627: 5, #8017: 7, #8018: 3, read_at: b1042eec }`

**Null rows carry a same-target control** (AC-Binding Limb 2): #8016 AC-2's `expect 0` names a control on the same instrument and path that returns 1; every count row names a control on the same file or directory.

### Release-Level Verification

These checks use tools or shapes outside the plan verifier's runnable set, so each is declared deferred to the Stage-6 C4 run that executes it; the commands and observed results land in § Verification Evidence as each slice lands.

| Check | Verification Method | Expected |
|---|---|---|
| Close keywords in commit messages | [DEFERRED — check-commit-close-keywords.py against origin/main before every push] | exit 0 |
| ADR durability, whole corpus | [DEFERRED — check-adr-durability.py with and without a diff base, and its CI file-list form, at Stage 6 C4 per ADR slice] | the delta reads one R6 row (the pending ADR-141 whole edge) and no other rule; the CI form reads the R-18 rows only |
| ADR number integrity | [DEFERRED — check-adr-numbers.py and renumber-adr.py --detect at Stage 6 C4 per ADR slice] | PASS; the new record's claim BINDS against the mainline |
| Path-leak hygiene | [DEFERRED — path-leak-patterns.sh --scan-file on each new or edited file, at Stage 6 C4] | no new hit; a file's pre-existing hits are counted at its base |
| Doc-link integrity | [DEFERRED — check-doc-links.py over each slice's edited docs, and the plan-depth lint on this plan, at Stage 6 C4] | no new broken link |
| CIAC authoring lint | [DEFERRED — the plan verifier's CIAC lint over this file, at Stage 6 A1 and Stage 9 A3.6] | declared=8 parsed=8 flagged=0 |
| Slug-token stamp rehearsal | [DEFERRED — renumber-adr.py --stamp in its dry-run form on the release head, at Stage 6 C4 after slice 1] | every token resolves; 0 refusals; 0 tokens in link position |
| Package consequence | [DEFERRED — the package resolver reading each changed path on STDIN, at Stage 6 C4 per slice] | empty — no rostered skill's package is staled |
| Release-module ADR index | [DEFERRED — the Stage 6 C4 question: does this release add a record under release/ADRs/] | N/A — this release adds no record under release/ADRs/ |
| Deploy-time checks | [DEFERRED — Stage 12–13: ./deploy.sh --deploy re-lays the operations-bridge mirror; Check 9, Check 33 and Check 70 read by their own lines] | each check's own line reads OK |
| G-CL10 population record | [DEFERRED — Stage 13 Phase A14: § Verification Evidence carries the record the gate-efficacy register row declares, under a Population record heading named placement-member-census; examined = the distinct members the row's census probe returns, the resolver's own default and the one comment line excluded; conforming = members a surface-register row of the placement standard names] | examined 16, conforming 16 at the slice-3 head; re-measured at the merge commit |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential (P0 serial; one writer per file per slice) |
| Commit strategy | Commit 0 (this plan), then one or more commits per slice, each pushed on landing (Write-Early); subjects carry the `placement-rules-and-adr:` prefix and a reference-only trailing `(#N)` |
| Review approach | Single release PR, draft until Stage 9 Phase A8 |
| CI | Never merge with any red or unread check; the Stage-12 merge waits for every check, including `repo-integrity.yml` (ADR-number integrity, ADR durability, dead-file reference, depersonalization, `operator-toml-schema`), `link-check.yml` and `release-tooling-smoke.yml` |
| Stage 12 | Version claim (`claim-version.sh`, minor), then the ADR binding: `renumber-adr.py --detect`, `--renumber` on a collision, `--stamp`, `--stamp --check` |
| Post-merge | `./deploy.sh --deploy` (rules-mirror re-lay; no skill or package changes); primary checkout fast-forwarded |
| Stacked-base cleanup | N/A (single branch) |

**Stage 13 — Phase A13 carries two records, authorized one by one.** The operator is asked separately (1) to ratify the new ADR, `Proposed → Accepted`, and (2) to retire ADR-141. On a yes to both, one commit on the Phase B chore PR makes the new ADR's flip and three hunks on ADR-141, and nothing else on ADR-141: its `status:` becomes `Superseded by ADR-<bound number> (non-tracked platform data is homed by its risk class; this record remains for audit trail). Originally Accepted.`; a first `## Status` paragraph cites the superseding record by its bound number; and `## Related ADRs` gains a link line naming it as superseding this record whole (#8016 Stage-5 design, Output for Stage 6, Change 6). **On a no to (1)**, nothing is applied to ADR-141; the chore PR removes the four appended in-part entries (ADR-017, ADR-032, ADR-046, ADR-096), their Related ADRs or composition limbs, and the `core/ADRs/README.md` entry and ADR-032 clause, and routes the standard's and the reconciled surfaces' wording to the hub as a Tier 1 follow-up; both dispositions are written to § Verification Evidence.

**Stage 13 grading probe (the #8016 review FM-2 fix).** The diff base is bound concretely to the release merge commit's first parent (`<release-merge-sha>^1`), never to a placeholder or a merge-base that resolves to HEAD. The whole-corpus `check-adr-durability.py` (no file list) runs **twice** on that base: at the release merge commit it must read exactly the one pending ADR-141 R6 row — the sensitivity arm, showing the scope is non-empty — and at the A13 commit it must read none. Because the lint skips a frozen record before testing its citation, ADR-141's citation is graded only by the direct read with the bound number (#8016 AC-2). The byte-prefix assertion (#8016 AC-5e) grades that every kept `superseded_by:` entry survived.

The PR body is parser-clean: each card is named in the dedicated Issue References block; no close-family verb precedes an issue number anywhere else. The four cards are marked closed at Stage 13 through the close-out.

---

## Rollback Strategy

| Scope | Method | Complexity |
|---|---|---|
| Before merge | Revert or drop a slice on the branch | CHEAP / HIGH |
| After merge, before ratification | `git revert -m 1 <merge SHA>` restores every file. No data moved, no resolver changed; the `corpus_home` default reproduces today's behaviour, so an operator config that gained the key keeps working. ADR-141 was never touched | MODERATE / HIGH |
| After ratification | An Accepted ADR changes only by a superseding ADR | EXPENSIVE / MEDIUM |
| Version tag | Retained and recorded per Tag Retention; never deleted | — |

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A), transcribed from Stage 4.
**Parallel-eligible spokes per parallel stage:** Stage 5: 4 · Stage 7: 4 · Stage 8: 4 (Stage 6 is serial).
**Per-spoke cost estimate:** size-bucket band `size:M` = low–moderate for all four (heuristic).
**Assumed remaining usage-window envelope:** not stated at hub start → conservative default of half a window, because other hubs draw on the same account [ASSUMPTION – CONFIRM].
**Estimated cumulative draw (worst parallel batch):** ≈ 4 × 5% = 20% of a full window → ≈ 40% of the assumed half window.
**Routing:** PASS → proceed; Checkpoint B re-validates at every launch, on the usage-window axis and the host-API axis.

---

## Release Class declaration

**Class:** `cross-cutting` · **Dominant trigger:** (c) ≥3 in-bundle compositional edges — 3 native at Stage 4 (#8016→#8017, #8016→#8018, #8017→#8018), 4 with #6627's native edge added after the gate. Trigger (a) not fired: 0 `pipeline/stage-*.md` files in the matrix. Trigger (b) not fired: 2 of the 6 rule-defining surfaces (`hub-spoke-bridge.md`; `CLAUDE.md` through its template). Novel triggers (a) new standard + new ADR, (b) D-class decisions, (c) an ADR also fire; precedence `cross-cutting` > `novel`.
**Differentiation posture:** engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed from the milestone description at Engineering Commit 0 (milestone updated `2026-11-05T18:39:07Z`), with one spelling change: the leak-risk container is written in its rooted form (§ Deviation Log).

**AFTER** — Any agent or operator can look up, in one standard, the class and home of every kind of data the platform keeps out of git, and one ADR — Accepted at close — records why: working state is homed in a git-ignored `/local-state/` in the repo it belongs to (or, for install-wide state, an install-level home), and leak-risk content is homed out of tree in `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/`. The charter template, architecture overview, memory contract, operations bridge and hub-spoke bridge (and the hub-state standard, if D-hubstate-wording = A) state the same classes, cite the standard, and say where each kind of data resolves until its repository's cutover. The release corpus has a declared home behind a `corpus_home` selector that defaults to today's tracked corpus. Every later wave of #8005 builds against this one source.

**BEFORE** — Placement is decided surface by surface across ADRs that disagree: ADR-141 puts all instance data out of tree, ADR-046 puts roadmaps in the repo, and ADR-032 assigns the tracked release corpus to instance homes. No standard names the classes or gives a checklist for a new surface, and hub state lands in the out-of-tree container because the hub-state standard says so. The charter template's classification rule classifies that container as tracked.

**Actor(s):** operators and agents deciding where non-tracked data lives; the spokes that build waves 2–8 of #8005; ms#429 and ms#437, which home new surfaces against this standard.

**Success Indicator:** on the merged tree the standard lists every member of the pinned fit/gap population with its class and home; the five (or six) reconciled surfaces cite it and contain no statement placing working state out of tree **as its governed home**; the `corpus_home` selector is declared, validated by Check 33 and declared in the schema; and at Stage 13 close the new ADR is Accepted and ADR-141 carries the supersession D-ADR141-Scope selects.

**Limb owners:** the standard and its population → #8017 · the ADR, Accepted at close, and ADR-141's supersession → #8016 · the six surfaces → #8018 · the `corpus_home` selector, its check and its schema declaration → #6627.

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| `core/rules/operations-bridge.md` | Mirror pair — the deployed rules copy is re-laid after merge | `./deploy.sh --deploy`, then Check 9 read by its own `FAIL:` lines |
| Every other matrix path | **Repository-only** — none is under a skills tree or in the rules mirror set | none required |
| `core/deploy/deploy.sh` Check 33 | Run from the repository at check time and in CI | none required |

**`deliverable_state:`** `deployed-copy-synced` for the release (its one propagation target is the rules mirror); the ADR and the standard are knowledge deliverables that also reach `artifact-accepted` at their canonical paths, recorded at Stage 13.

### Schema Migrations

N/A — enumerated over data-file formats, register and ledger schemas, the pipeline-event-log schema, the operator configuration schema and the gate-criteria schema columns. The operator configuration schema gains one optional `[adapters]` key whose default reproduces today's behaviour; no stored value migrates.

### Memory Evictions

N/A — enumerated over memory eviction, memory re-point and archive disposition. No card in this release codifies a rule held in the operator's memory store whose eviction this release triggers; this wave decides and documents, and nothing it ships moves a home a memory entry points at.

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Run by the Stage-6 spoke on #8671 after this file was written and before it was committed, on base `b1042eec`.

| Check | Command | Observed |
|---|---|---|
| Stamp manifest (step 3b) | `bash release/tools/claim-version.sh --verify-stamp placement-rules-and-adr` | exit 0 — "verify-stamp OK … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries exactly 1 literal placeholder (python count) |
| CIAC authoring lint (A1) | `bash release/tools/verify-release-plan.sh --ciac-lint release/releases/plans/placement-rules-and-adr_RELEASE_PLAN.md` | exit 0 — `CIAC-LINT-SUMMARY declared=8 parsed=8 clean=7 declared-deferral=1 flagged=0`; CIAC-7 DECLARED, the other seven CLEAN. G4-06 holds on the committed plan |
| AC-Binding | `python3 release/tools/check-ac-binding.py --fetch release/releases/plans/placement-rules-and-adr_RELEASE_PLAN.md` | exit 0 — `VERDICT BOUND`; coverage 1–6 / 1–5 / 1–7 / 1–3 against the live bodies, every row BOUND. Sensitivity arm: an earlier draft that split #8016 AC-5 into suffixed rows read `ORDINAL-GAP` (missing ordinal 5) and was repaired to one row |
| Plan links | `python3 release/tools/check-release-links.py --files <this file> --plan-depth-lint --check-anchors`; `python3 core/deploy/tools/check-doc-links.py --target-paths <this file> --require-targets` | 0 broken, 0 depth-sensitive links; 0 findings. Sensitivity arms: both tools' `--self-test` pass, and a one-line dead-link fixture in the run directory reads 1 `broken-cross-ref` |
| Path-leak and spellings | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <this file>`; a python scan for a bare container leaf, a machine home-directory prefix and the new record's number | exit 0; 0 / 0 / 0 (sensitivity: a fixture line holding both bare leaves reads 2 on the same pattern) |

**A1 entry contract.** Every Planning-stage input is present in this file (sequence, per-card specs, matrix, delivery strategy, risks, verification, rollback), at Solutioning-level spec depth for all four cards. **A2 decomposition:** under hub-spoke, the decomposition is this file's Implementation Sequence and File Change Matrix with one Stage-6 sub-task per card (Procedure 1); the operator's plan approval and the scope-lock discharge the A1–A2 checkpoint. **A3 file-state snapshot:** every slice-1 path was read at `b1042eec`; none diverged from the Stage-5 baseline.

### Slice 2 — #6627 — Stage 6 C4

Run by the Stage-6 spoke on #8673 over commits `372dc2c8` (the selector, its declaration and Check 33, one commit for the template-to-declaration parity) and `02ea2e42` (the record's Release-corpus location item and the six reconciled documents), on the release head after slice 1 (`b21a3e99`). Every slice-2 path was read at `b21a3e99` before editing; none diverged from the Stage-5 baseline beyond slice 1's own record.

| Check | Command | Observed |
|---|---|---|
| Declaration parity, `[adapters]` | a python read of `core/config/operator-toml-schema.json` and of the template's `[adapters]` key lines | 6 declared keys equal the template's 6; `declaration_version` stays 1; the key is `opt-in`, enum `["tracked"]` on one line, `since` `5.02` (provisional; Stage-12 re-verify). The Check 70 primitive itself is refused to agent sessions (BLOCK-DESTRUCTIVE-022, no allowlist row), so its own verdict is read from deploy.sh Check 70 below and from the `operator.toml declared-schema gate` CI job |
| JSON parse | `python3 -c "import json; json.load(…)"` | parses |
| Check 33 predicate on fixtures | one plain `/usr/bin/grep -qE` per fixture with the loop's predicate for `corpus_home` | shipped template 0; key removed 1; key with no value 1; `""` 0 and an undeclared value 0 (declared boundaries). Control: the `scheduler` predicate on the key-removed fixture reads 0. The base loop carries no `corpus_home` token, so at the base the same fixtures raise nothing |
| deploy.sh Check 33 and Check 70 | `bash core/deploy/deploy.sh --check`, the instance path redirected to the run directory; each check's own lines read, never the run's exit | Check 33 `OK:` — the template parses, every field has a default, `[adapters]` present, `work_board` preserved. Check 70 `OK:` — its own self-test 9/9 arms (4 specificity silent, 5 sensitivity fired); C70c compared 53 declared keys against 53 template keys, 0 findings; C70b 0 literal emits; C70d 17 = 17 = 17; C70a 28 delivered keys against the live config, 0 misses (the opt-in key adds none). The run's two issues are pre-existing and outside this slice: Check 47's published-body drift, and Check 63's five count-structure rows, which read identically (same file, line and content hash) on the three files when run against the slice-1 head's copies |
| Corpus-home tolerance suite | `bash release/tools/tests/test_corpus_home_tolerance.sh` | exit 0, `verdict: PASS-SEAM-LANDED`; ARMED (structural and behavioural); R1–R8 PASS; R6 finds CH-1..CH-4 in the edited standard; the sentinel reads `armed`, unchanged |
| Install/onboarding/update regression (runtime-suite map rows 2 and 5: `core/deploy/**`, `core/config/*.template`) | `bash core/deploy/tests/run-install-regression.sh` | `INSTALL-REGRESSION: 3392 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`. `core/config/operator-toml-schema.json` matches no map row although setup and reconcile read it — a map gap, exercised here by the row-5 suite |
| ADR durability, whole corpus with diff base `origin/main` | `python3 release/tools/check-adr-durability.py --diff-base origin/main` | exactly 1 R6 row — the pending ADR-141 whole edge; no rule fires on the item's added lines. Sensitivity: the lint's self-test, 156/156 |
| ADR durability, whole corpus without a diff base | `python3 release/tools/check-adr-durability.py` | 24 rows, equal to the base's 24; 0 on the new record |
| ADR-number integrity | `python3 release/tools/check-adr-numbers.py` | PASS, contiguous, no duplicates |
| Slug-token stamp rehearsal | `python3 release/tools/renumber-adr.py --stamp` (dry run) | 18 tokens across 13 files over 15 in-scope files; 0 refusals; 0 in link position (slice 1 read 6 across 6) |
| No reserved non-tracked value (CR-5 (a)) | a python scan of the slice's added lines for `local-state` written as a value (quoted or backticked) | 0. Sensitivity: the same regex over the Stage-5 design's part 3 reads 9 lines. Specificity: the one added line carrying the path form `/local-state/` (a rejected alternative in the item) reads 0 |
| Path-leak scan, each edited file | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <file>` | no new hit; the template's one hit is pre-existing at the base (the projects-path key comment). Sensitivity: a run-directory fixture with a bare relative container path reads 1, exit 1; its prose-only line is not flagged |
| Doc links over the six edited documents | `python3 core/deploy/tools/check-doc-links.py --target-paths <files> --require-targets` | 0 findings. Sensitivity: a one-line dead-link fixture reads 1 `broken-cross-ref`; the tool's self-test passes |
| Close keywords in commit messages | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | CLEAN on every push. Sensitivity: the tool's self-test, 14/14 must-flag fired |
| Package consequence | the changed paths on STDIN to `build-skill-packages.sh --skills-for-paths` | empty. Sensitivity: a skill path on the same invocation names its skill |
| CIAC authoring lint and AC-Binding on this file | `verify-release-plan.sh --ciac-lint`; `check-ac-binding.py --fetch` | `declared=8 parsed=8 clean=7 declared-deferral=1 flagged=0`; `VERDICT BOUND`, #6627 AC-1..AC-5 bound |
| ADR index | — | N/A — this release adds no record under `release/ADRs/` |

**AC2's failing control is a Stage-7 fixture run** (DEV-25 gives its admitted form): the head loop's token list ends `scheduler corpus_home` and the base's ends `scheduler`; fixtures built in python from the shipped template; one plain predicate grep per fixture; pass when the shipped template reads 0, the key-removed and no-value fixtures read 1, and the empty-string and undeclared-value fixtures read 0 as declared boundaries; then Check 33's own `OK:` line on the branch head.

### Slice 3 — #8017 — Stage 6 C4

Run by the Stage-6 spoke on #8675 over commit `1409cd88` (the new standard and the four edited standards), on the release head after slice 2 (`ee524596`). Every slice-3 path was read at `ee524596` before editing; none diverged from the Stage-5 baseline (`b1042eec`), because no earlier slice touches them. The four edits were applied by one script whose every hunk asserts exactly one anchor match.

| Check | Command | Observed |
|---|---|---|
| Surface register shape (AC-1) | a python parse of the `S-NN` rows of the standard | 38 rows: 18 `fit/gap`, 7 `code`, 8 `registry`, 5 `design`; 0 malformed (each Class cell a closed-vocabulary term or the `Undecided` marker, both home cells filled); `Undecided` on S-32 and S-34 only. The 18 `fit/gap` rows are the 18 surfaces pinned at the parent epic's 2026-10-27T14:40:25Z body revision |
| Member census — the named-gap row's Population (AC-2, CD-1 (c)) | `git grep -n -o -E '(pmo_instance_path(_for)?( [^)]*)?\)\|PMO_INSTANCE_PATH[^/]*\})/[A-Za-z0-9._/-]+' -- '*.sh' '*.py' '*.yml' ':(exclude)**/tests/**'`, leaves extracted in python, each looked up as a backticked leaf in the register | 29 lines → 18 distinct leaves → 16 members (the resolver's own default in `lib-instance-path.sh` and one comment line in `deploy.sh` excluded); **16 of 16** named by a register row. Sensitivity: the same lookup with S-33 removed leaves `project-keys.txt` unnamed (15 of 16). Specificity: a leaf no member carries reads unnamed |
| The named-gap row parses under the close gate (G-CL10) | `register_rows` / `surface_word` / `parse_population` imported from `core/deploy/tools/check-doc-gates.py`, over the edited `gate-efficacy-standard.md` | register 89 → 90 rows; the new row reads surface `prose`, 5 cells, Population `placement-member-census`, probe on the invocation arm (first word `git`), threshold 100%; the 9 population names stay unique. Sensitivity: the same row at threshold 0% → `declaration-malformed` |
| Registry Class column (AC-3) | python: the header regex, the row regex reaching the last cell, and a token → class map built from the register's Resolves-today cells | header 1; 17 rows classed, 17 in the closed vocabulary; 0 register↔registry mismatches; no registered token named under two classes. Controls: the `origin/main` spec → header 0, classed 0; one registry cell flipped → 1 mismatch |
| Both registry readers still read 17 rows (R-4) | the `ANGLE_ROW` regex of `check-operator-toml-schema.sh` and the Check 44 row form, in python | 17 / 17 on the edited spec (17 / 17 at the base). Sensitivity: the column inserted left of the token cell → 0 / 0 |
| deploy.sh Check 70, Check 44, Check 62, Check 14, Check 50 | `bash core/deploy/deploy.sh --check`, the instance path redirected to the run directory; each check's own lines read, never the run's exit. The schema-check primitive is not invoked directly (BLOCK-DESTRUCTIVE-022; DEV-25) | Check 70 `OK:` — self-test 9/9 arms; C70c 53 = 53 keys, 0 findings; C70d **17 = 17 = 17**, 0 parity findings; C70a 0 misses. Check 44 `OK:` — no square token unregistered; its angle inventory is advisory. Check 62 `OK:` — all 61 register pointers resolve (the named-gap row carries none). Check 14 `OK:` — no broken cross-refs in scope. Check 50 `OK:`. C70e is a diff leg run by the `operator-toml-schema` CI job; its proxy is the next row. The run's 2 issues are pre-existing and outside this slice: Check 47 published-body drift, and Check 63's five count-structure rows, the same five locations slice 2 recorded |
| No new operator-instance token | python: every angle or square token on the slice's added lines (vs `origin/main`), against every such token in the tracked tree at `origin/main` | 17 distinct tokens on the added lines, 0 absent at the base (50 distinct at the base). Sensitivity: a seeded new spelling is absent from the base set |
| Per-issue verification rows (AC-1..AC-7) | the plan's commands, as python fixed-string counts | AC-1 file present; AC-2 `install-provisions-every-home` 3, the five step headings 5, #8029 in References 1, the census row 1; AC-3 header 1 (control without the Class cell 1); AC-4 3 of 3 standards cite it; AC-5 `admission test` 8; AC-6 the telemetry path 3; AC-7 `/roadmaps/` 8 |
| CIAC-2/3/4/6 on the standard | python counts | `leak-risk` and `working state` present (case-insensitive); the slug 4 (3 tokens and the plain-words file-name phrase); `corpus_home` 5 |
| ADR citation hygiene (INT-2) | python over the standard | 0 numbered new-record citations; 0 tokens in a link target; 0 markdown links; 0 bare container leaves |
| Slug-token stamp rehearsal | `python3 release/tools/renumber-adr.py --stamp` (dry run) | 22 tokens across 15 files over 20 in-scope files (slice 2 read 18 across 13); the standard 3, the depersonalization spec 1; 0 refusals |
| Reference cascade for the replaced placement paragraph (review PR-2) | `git grep -n -i -E 'why[- ]the[- ]home[- ]sits' -- .` | pre 2 (the paragraph and the PROJECTS row's back-reference) / post 0 |
| Path-leak scan, each new or edited file | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <file>` | the standard 0; depersonalization spec 1 → 0 (the WORKTREES row rooted); taxonomy 2 → 1 (§ 7.4 rewritten; the § 1 example cell is pre-existing and outside the slice); analysis-workspace 0 → 0; gate-efficacy 0 → 0. Sensitivity: a run-directory fixture with a bare container path → exit 1; its rooted twin → exit 0 |
| Reference durability on added lines | a python proxy over each file's added lines, the patterns read from `core/hooks/lib/fragile-ref-patterns.sh`, each file's allow-link marker honoured | 0 links outside an allow-link file, 0 cutover clauses, 0 raw URLs, 0 issue references outside a reference block, across 297 added lines. Sensitivity: each pattern fires on a seeded positive |
| Doc links | `python3 core/deploy/tools/check-doc-links.py --target-paths <the five files> --require-targets`; `python3 release/tools/check-release-links.py --roots core --files <the five files> --check-anchors` | 0 findings; 0 broken. Sensitivity: a one-line dead-link fixture → 1 `broken-cross-ref`; both tools' `--self-test` pass |
| Frontmatter (Check 50) | `python3 core/deploy/tools/check-doc-frontmatter.py --target-paths <the standard>,<the analysis standard>` | 0 findings; the tool's `--self-test` passes its falsification arms |
| Close keywords in commit messages | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | CLEAN before each push. Sensitivity: the tool's `--self-test` passes, the flagged-range arm included |
| Package consequence | the five paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty. Sensitivity: a skill path on the same invocation names its skill |
| Runtime suite | the runtime-suite selection map | `core/standards/**` matches no row → its no-match row: `test-run/suite-skip` |
| ADR durability and ADR index | — | N/A — this slice touches no ADR and adds no record under `release/ADRs/` |
| CIAC authoring lint and AC-Binding on this file | `bash release/tools/verify-release-plan.sh --ciac-lint <this file>`; `python3 release/tools/check-ac-binding.py --fetch <this file>` | `declared=8 parsed=8 clean=7 declared-deferral=1 flagged=0`; `VERDICT BOUND`, #8017 AC-1..AC-7 bound |

**Undecided rows, and why.** The census and the review's in-repo writers include two surfaces whose class the evidence does not settle: the operator methodology packs (configuration read while operating the repository, or operator configuration beside the platform's per-user configuration) and the hook runtime logs (state of the deployed hooks, or install-wide records of every session's working folder). Each reads `Undecided` — a marker, not a class — with the consumer-routing card named as the deciding change, which the amended AC-1 admits. No path token is registered for either.

### Slice 4 — #8018 — Stage 6 C4

Run by the Stage-6 spoke on #8677 over commit `33fa03d7` (the six surfaces), on the release head after slice 3 (`ac9b07ff`). Every slice-4 path was read end to end at `ac9b07ff` before editing; each was byte-identical to the Stage-5 baseline (`b1042eec`), because no earlier slice touches them. Fourteen Edit hunks applied the Stage-5 design as its adversarial review and the scope-lock amend it (DEV-38 to DEV-44).

| Check | Command | Observed |
|---|---|---|
| CIAC-1 | python fixed-string file count of `instance-data-placement-standard` over the six surfaces | 6 (base 0) |
| CIAC-2 | python case-insensitive file count of `leak-risk` over the standard and the six | 7 (base: 0 of the six) |
| CIAC-3 | python case-insensitive file count of `working state` over the standard and the six | 7 (base: 1 of the six) |
| CIAC-8 | python count of the bridge's lines carrying `OPERATOR_INSTANCE_HUB_STATE_PATH` | 3 (base 3) — the State Persistence row stays one line |
| #8018 AC-2 | python counts on the template: the `### Classification Rule` heading; the step-3 literal `unlisted root files default to Layer 1, except platform working state and leak-risk content`; the step-2 exception literal; the old step-3 literal `unlisted root files default to Layer 1.` | 1; 1 (base 0); 1 (base 0); 0 (base 1). Stage 7 greps the new step-3 literal, not the design's (DEV-44) |
| #8018 AC-3 — Check 14's primitive | `python3 core/deploy/tools/check-doc-links.py --target-paths <the six, comma-joined> --require-targets --output-format tsv` | exit 0, 0 findings. Sensitivity: a run-directory fixture with a missing rooted target and the bare `core/standards/…` form → 2 `broken-cross-ref`, exit 1; `--self-test` passes 12 fixtures |
| Dead-file-reference gate's reader | `python3 release/tools/check-release-links.py --roots core release --files <the five .md surfaces> --check-anchors --diff-base origin/main` | 0 broken links and 0 missing anchors on the added lines. Without the diff base: 0 broken and 14 missing-anchor warnings, all on lines this slice does not touch (the glossary `#term-*` anchors in the bridge, `#four-type-reconciliation` in the memory contract). `--self-test` passes |
| Path-leak scan, each edited file | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <file>` | exit 0 on all six. Sensitivity: a run-directory fixture with a bare relative container path → exit 1; its rooted twin → exit 0 |
| Bare container leaf; ADR token in a link target; machine home prefix | python over the six | 0 / 0 / 0 in every file, at head and at base. Sensitivity: a seeded line for each → 1 / 1 / 1. Specificity: both rooted spellings → 0 leaves |
| Reference durability on added lines | python proxy over the 39 added lines, the patterns read as text from `core/hooks/lib/fragile-ref-patterns.sh` | 12 link sequences, every one in a file carrying the allow-link marker except the template's one, which is not durable-corpus `*.md`; 0 cutover clauses; 0 tracker URLs; 0 issue references; 0 close-family verbs before a number. Sensitivity: each pattern fires on a seeded positive. Specificity: "until each repository's cutover" reads 0 on the cutover pattern |
| Allow-link marker (CR-6) | python count in `core/rules/operations-bridge.md` | 1 (base 0) |
| Rules-corpus budget (Check 78's primitive) | `/usr/bin/python3 core/deploy/tools/check-rules-budget.py --root . --output-format tsv` | `VERDICT WITHIN` — 9 members, 163,202 B of 204,800 B (162,002 B at the base); `operations-bridge.md` 9,322 B, under the per-file trigger |
| Slug-token stamp rehearsal | `python3 release/tools/renumber-adr.py --stamp` (dry run) | 23 tokens across 16 files over 26 in-scope files (slice 3 read 22 across 15): the overview's one token added; 0 refusals; 0 tokens in a link target |
| Package consequence | the seven changed paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty. Sensitivity: `core/skills/pmo-qa-auditor/SKILL.md` on the same invocation names `pmo-qa-auditor` |
| Runtime suite | the runtime-suite selection map | `core/CLAUDE.md.template` is named by map row 5, so the slice selects the install/onboarding/update standing regression suite, `bash core/deploy/tests/run-install-regression.sh`; the other five paths match the no-match row. Stage 7 ran row 5's suite at `9645f807`: `INSTALL-REGRESSION: 3392 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`. Corrected at the Stage-7 iteration (DEV-51): this row first recorded the no-match row and `test-run/suite-skip` |
| Close keywords in commit messages | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | CLEAN before each push. Sensitivity: `--self-test` passes, the flagged-range arm included |
| Mirror sync (C3) | — | deferred to the post-merge `./deploy.sh --deploy`, which re-lays the deployed copy of `core/rules/operations-bridge.md` (§ Operational Deployment Manifest); until then Check 9 reads it DRIFTED in warn mode. The spoke does not write the deployed copy |
| ADR durability and ADR index | — | N/A — this slice touches no ADR and adds no record under `release/ADRs/` |

#### Target-home statements and their today's pointers (#8018 AC-1)

The population #8018 AC-1 grades: every statement this slice adds or rewords in the six surfaces that names a class's governed home, directly or by reference, paired with the today's pointer beside it. **25 statements; no pointer cell is empty.** Statements the slice keeps verbatim — the resolving-path lines of `hub-session-continuity.md` (its § 7.3 default included) and the bridge's other hub-state lines — name today's path, not a governed home, and are outside the population.

| # | Surface and place | Data | Class | Governed home | Today's pointer beside it |
|---|---|---|---|---|---|
| 1 | template, Classification Rule step (4) | release and run state | Working state | the repository's registered in-repo homes; `/local-state/` | the same step: its registered token where one exists, hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, otherwise the resolver in `core/deploy/lib-instance-path.sh`, which returns today's container |
| 2 | template, step (4) | read-once analysis, roadmap instances | Working state | their own registered homes | the same sentence (their tokens already default in-repo) |
| 3 | template, step (4) | usage telemetry | Working state, install-scoped | an install-level home the standard names | the same sentence |
| 4 | template, step (4) | PII scan lists, people roster | Leak-risk | the XDG data path | the same sentence |
| 5 | overview, File Architecture tree | `analysis/` | Working state | `/analysis/` (today's home too) | the subsection's last paragraph: its token, which already defaults in-repo |
| 6 | overview, tree | `roadmaps/` | Working state | `/roadmaps/` (today's home too) | the same paragraph |
| 7 | overview, tree | `local-state/`, marked TARGET and not yet provisioned | Working state | `/local-state/` | the tree's container entry and the subsection's last paragraph |
| 8 | overview, Non-tracked platform data | release and run state, analysis, roadmap instances | Working state | `/local-state/`, `/analysis/`, `/roadmaps/` | the subsection's last paragraph: hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, analysis and roadmaps through their tokens, otherwise the resolver, which returns `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` |
| 9 | overview, same | usage telemetry | Working state, install-scoped | an install-level home the standard names | the same paragraph |
| 10 | overview, same | PII scan lists, people roster | Leak-risk | the XDG data path | the same paragraph |
| 11 | overview, Key Principle 7 | the platform's own working state | Working state | by reference to the subsection | the subsection's last paragraph |
| 12 | memory contract, Placement and resolution | working state | Working state | the registered in-repo homes; `/local-state/` | the same paragraph: registered token where one exists, hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, otherwise the resolver, which returns `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` |
| 13 | memory contract, same | usage telemetry | Working state, install-scoped | an install-level home | the same paragraph |
| 14 | memory contract, same | leak-risk content; the People roster row | Leak-risk | the XDG data path | the same paragraph; the roster through `pmo_people_roster()` |
| 15 | memory contract, § 6 bullet | hub state, event log, close-out registers | Working state | by reference to the placement standard | hub state's pointer by reference to `hub-session-continuity.md` |
| 16 | operations bridge, Layer Classification | working state | Working state | the registered in-repo homes; `/local-state/` | the same entry: registered token where one exists, hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, otherwise `core/deploy/lib-instance-path.sh`, which returns `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` |
| 17 | operations bridge, same | usage telemetry | Working state, install-scoped | an install-level home | the same entry |
| 18 | operations bridge, same | PII scan lists, people roster | Leak-risk | the XDG data path | the same entry |
| 19 | hub-spoke bridge, State Persistence row | hub-state runtime instance | Working state | `/local-state/` in the release's repository | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/*.md` |
| 20 | hub-spoke bridge, same | embargoed security-fix run | Leak-risk | homed with its class | `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, until the resolver takes a run's class |
| 21 | hub-state standard, § 2 Placement class and target home | runtime instance | Working state | `/local-state/` in the release's repository | `<OPERATOR_INSTANCE_HUB_STATE_PATH>` |
| 22 | hub-state standard, same | the event log Surface B reuses | Working state | by class | `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` |
| 23 | hub-state standard, same | embargoed security-fix run | Leak-risk | homed with its class | `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, until the resolver takes a run's class |
| 24 | hub-state standard, § 2 Layer classification | runtime instance | Working state | the standard's, by reference | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` |
| 25 | hub-state standard, § 9 | the placement standard's row | Working state | by reference | § 2's paragraph |

**Two statements name today's container and claim no governed home:** the template's step (3) and the overview tree's container entry name `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` as today's container and say it is never Layer 1, or never tracked. **Rows 3, 9, 13 and 17** place install-scoped working state at an install-level home outside every repository, as the standard's class table and CR-1 set it; no statement names today's out-of-tree container as a governed home.

### Slice 3, Stage-7 iteration 1 — #8017 — Stage 6 C4

Run by the Stage-6 spoke on #8675 over commit `844a5016` (both standards), on the release head after slice 4 (`9645f807`). It applies the Stage-7 Dev Testing findings F-01 to F-07 on #8683, using that output's exact fix text, and adds DEV-45 to DEV-49. § Slice 3 above stays as measured at `1409cd88`.

| Check | Command | Observed |
|---|---|---|
| Register completeness against a census that follows variables (F-01, F-02, F-03; AC-1) | a python census over every tracked, non-test shell, Python and workflow file that calls an instance-resolver function or reads `PMO_INSTANCE_PATH` (23 files). It covers the literal `<resolver>)/<leaf>` joins; every variable assigned from a resolver, followed transitively to each `$var/<leaf>` join; the named member resolvers; the composition manifest's instance and hub-state tiers; `resolve_check_mode`'s per-check family; and the update path's whole-container copy. Every code leaf is normalized to a member and looked up in that member's register row | **26 members.** At `9645f807`, 22 named and 4 not: `touchpoint-inventory.md`, `git-pre-commit-pii.mode`, `status-label-invariant-exemption-list.txt` and the update path's container copy. That is the sensitivity arm, and it equals the DT's F-01, F-02 and F-03. At `844a5016`, 26 of 26 named; 0 census leaves left unmapped. Sensitivity after the fix: with S-31's PII-dial clause removed, that member reads unnamed (25 of 26). Specificity: the resolver's own defaults (4 code lines) are not members; the near-miss bare `mode`, present in S-31's prose, names no member; a fabricated leaf names no row |
| Escape check: code that spells the container leaf instead of calling the resolver | `git grep -n -F` for the container leaf over the code files, comment lines dropped | every site maps to an existing row: the usage-store scripts → S-06, S-01, S-03; the installer's directory creation → S-01, S-11 to S-13; the install validator's instance arm → S-07 |
| Workspace-root writers, now that the `code` source covers them (F-03) | `git grep -h -o -E` for the first path segment joined to the two workspace-root variables, over the same code files | 11 distinct segments. `.claude`, the container, `projects`, `CLAUDE.md` and `.backup-pre-update-` have rows. `.backup-tampered-<ts>/` and `.workspace-validation/<ts>/` have none and are recorded for the hub (DEV-46). `knowledge/` is an empty folder the installer creates and both validators expect; no code writes into it |
| Register shape (AC-1) | a python parse of the `S-NN` rows | 41 rows, S-01 to S-41 contiguous: 18 `fit/gap`, 10 `code`, 8 `registry`, 5 `design`; 0 malformed; `Undecided` on S-32 and S-34 only; 0 CONDITIONAL |
| Registry Class column (AC-3) | the same parse's token → class map against the registry's last cell | 17 classed, 0 mismatches, no token under two classes; S-38 keeps S-06's class for the usage-store token. Control: one registry cell flipped → 1 mismatch |
| The named-gap row's census, as the row words it (F-04) | the row's probe verbatim, then python: the leaves, the row's exclusion, and each leaf looked up in the S-rows' code spans | 29 lines → 18 leaves → 16 members; 16 of 16 named. With S-11 removed → 15 of 16 (fires). Under the old "comment lines" wording, the same run reads 14 of 14 both with and without S-11, which is the defect F-04 names |
| The named-gap row under the close gate (G-CL10) | `register_rows` / `surface_word` / `parse_population` imported from `core/deploy/tools/check-doc-gates.py` | 90 rows; surface `prose`, 5 cells, Population `placement-member-census`, threshold 100%, with F-04's wording in its member definition; the 9 population names are unique. Control: threshold 0% → `declaration-malformed` |
| deploy.sh Check 70, Check 44, Check 62, Check 14, Check 50, Check 33 | `bash core/deploy/deploy.sh --check`, the instance path redirected to the run directory; each check's own lines read, never the run's exit | Check 70 `OK:` — self-test 9/9 arms (4 specificity silent, 5 sensitivity fired); C70c 53 = 53 keys; C70b 0 literal emits; C70d **17 = 17 = 17**, 0 parity findings; C70a 0 misses. C70e is the `operator-toml-schema` CI job's diff leg; this iteration changes no registry, template or declaration file. Check 44 `OK:`; Check 62 `OK:` — all 61 pointers resolve; Check 14, Check 50 and Check 33 `OK:`. The run's 2 issues are the pre-existing Check 47 (13 published-body drift findings) and Check 63 (the same five locations slice 2 recorded, none in this iteration's files) |
| Primary records behind F-06 | `gh api` reads of the sibling release's scope-lock record and its #7937 review | PA-009 renders D-3 as one preservation of the pre-fix store in a `prior/` directory (CD-2); CD-2 preserves into `<store>/prior/schema-<old>/usage.jsonl`, under an ignore rule for `prior/` |
| Path-leak scan, each edited file | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <file>` | exit 0 on both standards and on this file. Sensitivity: a run-directory fixture with a bare container path → exit 1; its rooted twin → exit 0 |
| Doc links | `python3 core/deploy/tools/check-doc-links.py --target-paths <both standards> --require-targets` | 0 findings. Sensitivity: a one-line dead-link fixture → 1 `broken-cross-ref`; `--self-test` passes |
| Reference durability and citation hygiene on the added lines | a python proxy, the patterns read from `core/hooks/lib/fragile-ref-patterns.sh` | 12 added lines, 0 on each of: links, tracker URLs, issue references outside `## References`, cutover clauses, numbered ADR citations, tokens in a link target, bare container leaves, machine home prefixes, and close-family verbs before a number. Sensitivity: each pattern fires on a seeded positive |
| Close keywords in commit messages | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | CLEAN before each push. Sensitivity: `--self-test` passes, the flagged-range arm included |
| Package consequence / runtime suite | the two paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths`; the runtime-suite selection map | empty (control: `core/skills/pmo-qa-auditor/SKILL.md` names its skill) / `core/standards/**` matches the no-match row → `test-run/suite-skip` |
| Cascade for the register's count and its conditional row | `git grep -n -E '3[8]-row\|one con[d]itional\|\*\*CON[D]ITIONAL\*\*\|con[d]ition names'` over this file and the standard (the bracket keeps the row from matching itself); the same pattern in python over the pull request's body | pre 4 at `9645f807` (§ Change Description's Outcome and #8017 row; S-38's marker and its References clause) / post 0; pull-request body 1 → 0. Preserved as measured: § Slice 3's register-shape row, DEV-27 and DEV-30 |
| Plan: stamp manifest / CIAC lint / AC-Binding / plan links | `claim-version.sh --verify-stamp`; `verify-release-plan.sh --ciac-lint`; `check-ac-binding.py --fetch`; `check-release-links.py --plan-depth-lint --check-anchors` and `check-doc-links.py --require-targets` | `verify-stamp OK` / `declared=8 parsed=8 clean=7 declared-deferral=1 flagged=0` / `VERDICT BOUND` / 0 broken, 0 depth-sensitive, 0 findings. Sensitivity: a dead link seeded into this file reads 1 broken and is removed before commit |

**The census stays 16 of 16.** S-39's member and the PII dial are reached through a variable, so the row's literal-form probe does not see them; that is the reach limit F-05 states in the row. The Stage-13 population record stays as § Release-Level Verification names it.

### Slice 4, Stage-7 iteration 1 — #8018 — Stage 6 C4

Run by the Stage-6 spoke on #8677 over commits `3a04f3d4` (the template's step (1)) and `c2a47308` (the hub-ruled register entries in the placement standard, a #8017 commit), on the release head after the slice-3 iteration (`c6c07f29`). It applies the Stage-7 Dev Testing findings F-01 and F-02 on #8685, using that output's exact fix text, and the hub's ruling on the two workspace-root writers DEV-46 recorded. It adds DEV-50 to DEV-52. § Slice 4 above stays as measured at `33fa03d7`, apart from its Runtime suite row, which F-02 corrects.

| Check | Command | Observed |
|---|---|---|
| #8018 AC-2 (F-01) | python counts on the template: the heading; the new step-(1) clause "except platform working state and leak-risk content, which step (4) classifies even where a listed tree such as"; the old step-(1) literal "if listed, use that layer."; the step-(2) and step-(3) exception literals; the old step-(3) literal | 1; 1 (0 at `9645f807`); 0 (1 at `9645f807`); 1 and 1, unchanged; 0. The clause names no layer: the only "Layer " token in step (1) is "Layer table", as before. No step is renumbered |
| CIAC-1, CIAC-2, CIAC-3, CIAC-8 | the slice-4 instruments, re-run at `c2a47308` | 6 / 7 / 7 / 3 lines (4 occurrences), equal to `9645f807`; base 0 / 0 / 1 / 3 |
| Runtime suite (map row 5) | `bash core/deploy/tests/run-install-regression.sh </dev/null`, from the worktree root, at `c2a47308`; the standard's path matches the no-match row | `INSTALL-REGRESSION: 3392 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`, verdict line at 2026-11-05T23:48:23Z; `git status --porcelain` and `--ignored` empty afterwards |
| #8018 AC-3 — Check 14's primitive | `python3 core/deploy/tools/check-doc-links.py --target-paths <the six surfaces and the standard> --require-targets` | 0 findings, exit 0. Sensitivity: a run-directory fixture with a missing rooted target → 1 `broken-cross-ref`, exit 1, while its live rooted link on the same line is not flagged; `--self-test` passes 12 fixtures |
| Path-leak scan | `bash core/deploy/tools/path-leak-patterns.sh --scan-file <file>` on the template, the standard and this file | exit 0 on each. Sensitivity: a run-directory fixture with a bare relative container path → exit 1; its rooted twin → exit 0 |
| Reference durability on the added lines | a python proxy, the patterns read from `core/hooks/lib/fragile-ref-patterns.sh` | the template's one rewritten line carries the step-(4) link it already carried (the template is not durable-corpus `*.md`); the standard's 3 added lines read 0 on links, tracker URLs, issue references outside `## References`, cutover clauses, close-family verbs before a number, numbered new-record citations, tokens in a link target and bare container leaves. Sensitivity: a fixture fires each of the eight; its `## References` entry is not counted |
| #8017 — the hub-ruled entries | python: options (a) and (b) read from the two fenced blocks of the slice-3 iteration's recommendation on #8675, and the References widening, counted in the standard | 1 / 1 / 1 (0 / 0 / 0 at `c6c07f29`); (a) sits in S-41's Resolves-today cell and (b) is the row directly after S-41. The only pre-fix lines absent at `c2a47308` are S-41's row, extended, and the #8027 References line, widened |
| #8017 — register shape | a python parse of the `S-NN` rows | 42 rows, S-01 to S-42 contiguous, 6 cells each: 18 `fit/gap`, 11 `code`, 8 `registry`, 5 `design`; `Undecided` on S-32, S-34 and S-42 |
| #8017 — workspace-root writers, following variables | a python census over the 41 tracked non-test shell, Python and workflow files and extensionless scripts that reference the workspace root: literal joins; every variable assigned from the root, followed transitively (63) to each `$var/<segment>` join and each `${var}-<suffix>` concatenation; Python joins. 176 joins, 14 first segments, each looked up as a rooted spelling in an S-row and, where none matches, read site by site | 0 unregistered writers at `c2a47308`; 2 at `c6c07f29` (`.backup-tampered-<ts>/`, reached through `tamper_backup` as well, and `.workspace-validation/<ts>/`, through `VALIDATION_DIR`). Sensitivity: S-42 dropped → 1. Specificity: `.claude`, `projects`, `CLAUDE.md` and both pre-update copy forms resolve to S-25 to S-27, S-11 to S-14 with S-18 and S-23, S-24 and S-40/S-41. The seven segments with no rooted S-row spelling write no unregistered data: today's container itself, the resolver's legacy default and path-leak fixtures, the root variable's own default expansion, the tracked checkout in a hook's case pattern, the empty `knowledge/` scaffold, a message-string ellipsis and a case glob |
| #8017 — the member censuses | the gate row's probe verbatim, each leaf looked up in the S-rows' code spans at `c6c07f29` and `c2a47308`; row survival for the variable-following census | 29 lines → 18 leaves, the same 17 carried at both revisions (the 18th is the resolver's own default, which the row excludes), so the row's 16 of 16 is unchanged; sensitivity: S-11 dropped → 16 carried. Every member-naming S-row survives byte for byte, so the 26 of 26 member census is unchanged |
| Close keywords in commit messages | `python3 core/deploy/tools/check-commit-close-keywords.py --base origin/main --head HEAD` | CLEAN before each push. Sensitivity: `--self-test` passes, the flagged-range arm included |
| Package consequence | the three paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty. Sensitivity: `core/skills/pmo-qa-auditor/SKILL.md` on the same invocation names `pmo-qa-auditor` |
| ADR durability and ADR index | — | N/A — no ADR is touched |

---

## Change Description

Authored at Stage 6 Phase C1 by the last Engineering spoke (#8677, slice 4), after every Engineering slice landed and before the draft pull request is marked ready-for-review. Operator-facing; the user-facing release note is a separate Stage-13 artifact. A Tier 1 [ADJUST] at Stage 7 or 8 that changes which issues land or which decision stands refreshes **Issues resolved**, **Key decisions** and **Downstream impact** in a later commit.

### Outcome

The platform now has one source for where every kind of data it keeps out of git lives. A superseding decision record, `status: Proposed`, classes that data by risk — working state in the repository it belongs to, install-scoped telemetry in the user's XDG state home, leak-risk content in the user's XDG data home outside every tree — and supersedes ADR-141 whole, with ADR-141's transition at the Stage-13 ratification. `core/standards/instance-data-placement-standard.md` is its operational half: the classes and homes, the three registered in-repo git-ignored homes, the admission test, the protections, a 41-row surface register and the five-step new-surface checklist. Six governance surfaces now cite the standard and keep today's resolving path beside each target home, and `operator.toml [adapters] corpus_home` declares the release corpus's home, `tracked` only. Nothing moves: no file, resolver or runtime write path changes, and every running hub keeps resolving hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #8016 | The superseding record, `Proposed`: the class table, D1 to D8 with the enumerated main-checkout carve-out, the carried-forward subsection and the CR-2 build obligations; appended in-part pointers on ADR-017, ADR-032, ADR-046 and ADR-096; ADR-141 untouched on this branch | DONE (landed at Stage 6; ratification and ADR-141's transition at Stage 13) |
| #6627 | `corpus_home` declared in the template and the schema and validated by Check 33, default and only value `tracked`, declared and not yet read; the record's corpus-location item; five documents stop framing a corpus migration as pending | DONE |
| #8017 | The placement standard with its 41-row register (two `Undecided`); the token registry's Class column on 17 rows; three standards cite it; the gate-efficacy named-gap row with its member census, 16 of 16 | DONE |
| #8018 | Six surfaces cite the standard, each target home with today's pointer beside it (25 statements); the charter's Classification Rule no longer classes the out-of-tree container or an in-repo home's git-ignored contents as tracked | DONE |

### Key decisions

Each is recorded in § Decision Record.

- **D-hubstate-wording = A** — the hub-state standard joined #8018 as target wording only; every runtime path keeps today's token.
- **D-ADR141-Scope = A** — whole supersession, its `status:` flip at the Stage-13 ratification beat, with a decline branch (DEV-2, DEV-13).
- **CR-1 and CR-2** — telemetry at `${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/`; leak-risk content at `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/`, with sandbox parity and a loud failure on an empty home as build obligations.
- **CR-3** — the main-checkout carve-out is the enumerated set `/local-state/`, `/analysis/<sub>/`, `/roadmaps/<name>`, held to the hook's static set by a parity check.
- **CR-4 and CR-5** — the release corpus is tracked repository content, and no non-tracked `corpus_home` value is reserved.
- **CR-6** — `core/rules/operations-bridge.md` carries the per-file allow-link marker for its rooted link to the standard.

### Reversibility

**EXPENSIVE once ratified — MEDIUM confidence.** Before merge any slice drops by a branch revert (CHEAP); after merge and before the Stage-13 ratification, `git revert -m 1` of the merge restores every file, because nothing moved and no runtime write path changed (MODERATE); once the record is Accepted it changes only by a superseding record. The version tag is retained, never deleted.

### Downstream impact

- **Stages 7 and 8:** grade each card from § Verification Plan; #8018 AC-1 is graded over the 25-row statement list in § Verification Evidence → Slice 4; INT-4's reserved-value limb is void under CR-5 (a).
- **Stage 12:** the version claim, then `renumber-adr.py --detect`, `--renumber` on a collision, `--stamp` and `--stamp --check` (23 tokens across 16 files at this head); three sibling branches hold the record's slot (R-1).
- **After the merge:** `./deploy.sh --deploy` re-lays the operations-bridge mirror, which Check 9 reads DRIFTED until then; each install's charter picks up the Classification Rule at its next `update.sh`.
- **Stage 13:** the operator ratifies the record and retires ADR-141, one decision each; the whole-corpus durability lint runs twice on the bound base (one R6 row at the merge, none after A13); G-CL10 records the `placement-member-census` population.
- **Later waves of #8005** build against the standard — the resolver and switch, the carve-out hook and its parity check, the commit guard, the installer, the needle update, the migrations — and the cleanup wave removes the "until each repository's cutover" clauses.
- **Open for the operator:** the layer of platform working state (the #8018 review's CD-1, C1 or C2) is undecided; the taxonomy's § 7.4 counts it in Layer 2, so the operations bridge's Rule 1 reads against a hub writing hub state (DEV-42).

### Cross-references

- Release plan: this file, top section.
- Milestone: `placement-rules-and-adr`.
- User-facing release note: authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`, under `release/releases/notes/`.

---

## Deviation Log

| ID | Stage | Deviation | Basis | Severity |
|---|---|---|---|---|
| DEV-1 | 4 → 6 | Commit order #8016 → #6627 → #8017 → #8018, not the bundle's list | approved at the Stage-4 gate | Minor |
| DEV-2 | 5 → 6 | ADR-141's whole-supersession transition moves off the release branch to Stage 13 Phase A13 | #8016 Stage-5 D-1 (b); scope-lock addition | Major |
| DEV-3 | 5 → 6 | ADR-017 and ADR-046 gain in-part edges (the epic named neither) | #8016 Stage-5 R2; review CD-1; scope-lock addition | Major |
| DEV-4 | 5 → 6 | The main-checkout carve-out is the enumerated set `/local-state/`, `/analysis/<sub>/`, `/roadmaps/<name>`, amending the epic's D1 "`/local-state/` only" | CR-3 (a) | Major |
| DEV-5 | 5 → 6 | The new ADR's Consequences carry two build obligations and drop the claim that a sandboxed install isolates the per-user homes | review CD-3; CR-2 | Major |
| DEV-6 | 5 → 6 | A `### Carried forward from ADR-141` subsection under `## Decision` replaces the one Neutral-consequence sentence | review CD-4; scope-lock addition | Major |
| DEV-7 | 5 → 6 | The ADR-032 in-part label widens to the corpus's classification and home, Decisions 2 and 3 and the Deferred-migration plan | CR-4 (W) | Major |
| DEV-8 | 5 → 6 | The isolation-key retirement is narrowed to working state; the leak-risk class keeps it deferred | review PR-4 | Minor |
| DEV-9 | 5 → 6 | The Decision headline reads "one home per repository or per install; working state's in-repo homes are the registered set D1 enumerates" | review FM-5 (ii) | Minor |
| DEV-10 | 5 → 6 | The README's ADR-032 entry gains the in-part-supersession clause (the Stage-5 sweep had marked it PRESERVE) | #6627 F-3; review FM-5 (i) | Minor |
| DEV-11 | 5 → 6 | The new record's number is written literally in the target-side `superseded_by:` fields, departing from Phase A5's letter | #8016 Stage-5 D-5 / R4; the approved plan | Minor |
| DEV-12 | 5 → 6 | The ADR-096 relation is stated as a tightened guard, not a reused one, and its label covers Decision 3's admission of an ignored in-repo path | review PR-1 (c); CD-1 | Minor |
| DEV-13 | 5 → 6 | A13 gains a decline branch for the four in-part pointers and the README edits | review PR-3 | Minor |
| DEV-14 | 5 → 6 | The Stage-13 grading probe binds its diff base, runs twice and adds a byte-prefix assertion; ADR-141's citation is graded by a direct read | review FM-2; scope-lock addition | Major |
| DEV-15 | 4 → 6 | CONDITIONAL rows resolved: `hub-session-continuity.md` and ADR-046 promoted; ADR-167, ADR-178 and the allowlist row removed; ADR-017, `gate-efficacy-standard.md` and `platform-config-schema.md` added | gate D-hubstate-wording = A; Stage 5; scope-lock additions | Minor |
| DEV-16 | 4 → 6 | CIAC-1 to CIAC-3 widened to the hub-state standard (expect 6 / 7 / 7); CIAC-7 reworded to the whole-corpus grading form | gate D-hubstate-wording = A; #8016 Stage-5 R5; review FM-2 | Minor |
| DEV-17 | 4 → 6 | R-18 is measured on slice 1 at 2 CI-form rows, not the design's 3: ADR-046 joined the changed set, so its entry on ADR-017 resolves | Stage-6 measurement | Minor |
| DEV-18 | 4 → 6 | The Outcome Statement's leak-risk container is transcribed in rooted form instead of the bare leaf | the plan's N4 spelling rule | Cosmetic |
| DEV-19 | 5 → 6 | The corpus-location item departs from the #6627 design's item text: no non-tracked value is reserved; ADR-032's two package-purity decision drivers are named and their cost accepted; the corpus is defined once, by its members (the reversions ledger and the log archives included), with the folder README and hub-state templates stated as not corpus; the resolver's out-of-tree fallback tier is named a transitional residual, not a home; the selector's granularity is left to its reader; the consumer is named by surface (the close-out tooling's corpus resolver), with no work-item number | CR-5 (a); CR-4 (W); #6627 review FM-3, FM-2 (1), P-2; plan R-11 and the § Exclusions relay residual | Minor |
| DEV-20 | 5 → 6 | The item keeps slice 1's `### Release-corpus location` heading instead of the design's retitle, because the record's Related ADRs and the README's ADR-032 clause cite the item by that name | the § Contention Map row for the new ADR | Cosmetic |
| DEV-21 | 5 → 6 | The configuration catalog's `[adapters]` heading reads "adapter selectors" rather than "host-adapter selectors"; no tracked file links to that heading's anchor | #6627 design N5 (a placement selector is not a host surface) | Cosmetic |
| DEV-22 | 5 → 6 | The release-notes standard's release-log row is reconciled whole — its label and audience, beside the new Privacy cell — so the row does not contradict itself; the illustrative example under `_examples/` still mirrors the old label and is left as a residual outside this matrix | #6627 review, out-of-scope note on that row | Minor |
| DEV-23 | 5 → 6 | The constraints standard also gains a note under the CH table on what "instance-corpus root" names today, a § 1 lead that no longer defines the corpus as the four probed paths, and a § 1 clause re-pointed from the never-written adapter design to the selector's reader; CH-1 to CH-4 are untouched | #6627 review FM-2 (2), FM-3; the same stale pointer the design retires in § 2 and § 6 | Minor |
| DEV-24 | 5 → 6 | The release-notes footnote and the isolation-key record's resolution paragraph each carry a "declared, not yet read" qualifier, and the footnote says readers use the in-repo path rather than that the token resolves there | #6627 review FM-1 (iii) and probe P-g | Minor |
| DEV-25 | 5 → 6 | AC2's Stage-7 fixture run is restated in a form the script-execution guard admits — the design's form executes the extracted loop from a run-directory file, which the guard refuses — and gains a fixture with an undeclared value, recorded as a declared boundary beside the empty-string fixture | BLOCK-DESTRUCTIVE-022 observed on slice 2; #6627 review FM-1 (v) | Minor |
| DEV-26 | 5 → 6 | The class names are spelled as the new record's class-table row labels — `Working state`, `Working state, install-scoped`, `Leak-risk`, `Operator PMO content`, `Tool-owned`, plus `Tracked repository content` and `Package content` — in the standard's tables, its closed vocabulary, every register Class cell, the naming-rule table and the 17 registry Class cells; the design's lowercase cells and its `working state (install-scoped)` form are not used | #8017 review FM-4 (1); the slice-1 handover | Minor |
| DEV-27 | 5 → 6 | The surface register grows from the design's 30 rows to 38: seven `code` rows (deploy-check mode files, methodology packs, the project-key scan list, hook runtime logs and state, skill-editor sentinels, skill iteration workspaces, the cross-module audit output) and one CONDITIONAL row; S-01, S-07, S-08, S-09, S-11 to S-13 and S-30 name their leaves in today's container; S-25 and S-26 name the user-level rules and skills mirrors. Two rows read `Undecided` — a marker, not a class — with the deciding change named by role (S-32 packs, S-34 hook logs); the completeness sentence is scoped to every surface tracked code resolves or writes today | #8017 review PR-1, CD-1 (a) and (b); scope-lock addition | Minor |
| DEV-28 | 5 → 6 | The gate-efficacy named-gap row's Population is `placement-member-census`, a coverage census of the members tracked code resolves under the instance resolver (a `git grep` probe), each conforming when a register row names it — not the design's `placement-surface-register` row count, which a skipped registration could not lower | #8017 review FM-1 and CD-1 (c); scope-lock addition | Minor |
| DEV-29 | 5 → 6 | The standard's corpus table carries `tracked` only; the design's reserved `local-state` row and INT-4's limb that classes it are void | CR-5 (a) | Minor |
| DEV-30 | 5 → 6 | The FinOps store's preserved prior-unit file is registered as S-38, marked CONDITIONAL on the release-usage-measured-right release's Collective Review of its D-3 (A): at this commit #8713 holds only that card's Stage-5 design and #8662 carries no scope-lock record | scope-lock addition (conditional) | Minor |
| DEV-31 | 5 → 6 | The admission test's first limb reads release, run and operating state — what a platform run produces, and the configuration it reads — and its record question reads "does every record concern only this repository?"; S-07 is classed by the identifier check and the admission test together | #8017 review PR-4 | Minor |
| DEV-32 | 5 → 6 | The registered-homes table gains a column naming what the main-checkout carve-out admits for each home, and its prose states the hook's static predicate, the parity check and that registering a home admits no write until the hook's set changes in the same change; checklist Step 4 names the hook's static set | CR-3 (a); #8017 review FM-2 | Minor |
| DEV-33 | 5 → 6 | The naming rule gains one token per class for a surface classed per instance and supersession through the registry on reclassification; its example is re-based on the close-out registers | #8017 review FM-3 | Minor |
| DEV-34 | 5 → 6 | S-02 registers the provisioned copies of the hub-state templates as Working state, with the shipped source named as package content in its home cell; S-17's retired copy is Tool-owned | #8017 review FM-4 (3) | Minor |
| DEV-35 | 5 → 6 | The depersonalization spec's placement paragraph keeps the personal-area rule and points it at the new record's carried-forward clause 1; the PROJECTS row's back-reference is re-pointed. `[REFCASCADE: git grep -n -i -E 'why[- ]the[- ]home[- ]sits' over the tracked tree → pre 2 / post 0]` | #8017 review PR-2; the slice-1 handover | Minor |
| DEV-36 | 5 → 6 | The install-scoped class keeps its telemetry path as its home; the review's class-root alternative is recorded, not adopted | CR-1; #8017 review CD-2 | Cosmetic |
| DEV-37 | 4 → 6 | Commit 0 omitted two Stage-5 plan amendments for #8017: R-19 and the CIAC-4 note are added here, with a Release-Level Verification row naming the Stage-13 population record `placement-member-census` | #8017 Stage-5 design, part 4 (Release-plan amendments) | Minor |
| DEV-38 | 5 → 6 | Working-state homes are named by role in the four surfaces that state the classes — the registered in-repo git-ignored homes of the repository the data belongs to, release and run state in `/local-state/`, analysis and roadmap instances in their own registered homes — not `/local-state/` alone; the overview's tree gains `analysis/` and `roadmaps/` beside the TARGET `local-state/`, and its subsection spells all three; the memory contract's "Two classes are kept out of git" reads "Two of the standard's four classes are data the platform itself writes and keeps out of git" | #8018 review PR-2 and CD-2; CR-3; the slice-1 handover | Minor |
| DEV-39 | 5 → 6 | The embargoed-run sentence on both hub-state surfaces gains its today's pointer — until the resolver takes a run's class, the run resolves through `<OPERATOR_INSTANCE_HUB_STATE_PATH>` like every other run, so the Resume Procedure reads it where it was written — matching the standard's S-19 row (option (a)). Option (b), dropping the sentence, is not taken: it is the only leak-risk mention on both surfaces, so CIAC-2 would read 5, and it carries INT-6's second limb | #8018 review FM-1 | Minor |
| DEV-40 | 5 → 6 | The resolution sentence reads "each surface still resolves to today's path through its registered token where one exists — hub state through `<OPERATOR_INSTANCE_HUB_STATE_PATH>` — and otherwise through the resolver in `core/deploy/lib-instance-path.sh`", in the template, the overview, the memory contract and the operations bridge. "Each surface … today's path" replaces the design's "every class … today's container", because the analysis and roadmaps tokens already default to their in-repo homes | #8018 review FM-2; DEV-38 | Minor |
| DEV-41 | 5 → 6 | The subject of step (4), of the step-(2) and step-(3) exceptions and of the operations-bridge entry is closed to platform working state and leak-risk content — the standard's classes for data the platform itself writes and keeps out of git — so step (4) no longer collides with step (1)'s Layer-table rows for tool-owned surfaces, and step (2)'s exception no longer reads as covering `projects/`. The operations-bridge entry is titled "(never tracked)" and drops the design's "and is not the Operations domain's `projects/` content" clause; the overview's subsection opens on the two classes and notes that the standard also places PMO content and tool-owned files, because the design's "data the platform keeps out of git is neither the product nor PMO content" contradicts the standard's own Purpose | #8018 review PR-1 and CD-1 (the closed subject); the amendment record on #8677 | Minor |
| DEV-42 | 5 → 6 | The layer of platform working state and leak-risk content is left as the scope-lock left it, undecided: no surface states a layer for it beyond "never Layer 1", none says "not Layer 2", and no clause is added to the operations bridge's Rule 1. The hub-state standard's § 2 Layer classification keeps its existing "Layer 2" for the runtime instance — the design's Change 6c deleted it — so it still agrees with the taxonomy's § 7.4 as slice 3 landed it | #8018 review CD-1 (C1 or C2 not chosen at the scope-lock); the amendment record on #8677, open item 1 | Minor |
| DEV-43 | 5 → 6 | The install-scoped telemetry home stays unspelled ("an install-level home the standard names") although CR-1 settled it, which keeps INT-3's "no surface spells the telemetry home" limb true; review CD-4 (fixing step (3)'s default) is not adopted | the amendment record on #8677 (spelling optional; CD-4 optional, not adopted); CR-1 | Cosmetic |
| DEV-44 | 5 → 6 | The step-(3) literal the design's post-edit check greps changed with the closed subject: Stage 7 greps `unlisted root files default to Layer 1, except platform working state and leak-risk content` (expect 1), and the plan's AC-2 row, which grades on the heading plus a read, is unchanged | DEV-41 | Cosmetic |
| DEV-45 | 7 → 6 | The surface register gains S-39, the operator-touchpoint inventory deploy Check 40 reads from the instance base (Working state; its home decided by the consumer-routing card); S-31 adds the PII commit hook's own dial; S-07 names the fourth allowlist the composition manifest provisions into today's container. The register's completeness now rests on a census that follows a variable to the resolver base: 26 of 26 members named | Stage-7 Dev Testing F-01 (Blocker) and F-02 on #8683 | Major |
| DEV-46 | 7 → 6 | S-40 and S-41 register the update path's and the installer's pre-update copies at the workspace root: the whole of today's container, which carries the PII scan lists and the roster (Leak-risk, by the mixing rule), and the charter, settings and retired hook-tier files (Tool-owned), both homed by the install-and-update card. The Source definition's `code` arm covers a workspace-root writer, and the register reads 41 rows. Two further workspace-root writers the same census found, the tamper backups and the install validator's artifact folder, are not registered by this iteration; they are recorded for the hub | Stage-7 Dev Testing F-03 on #8683 | Major |
| DEV-47 | 7 → 6 | S-38 is re-spelled in the `prior/` form and is no longer conditional: the sibling release's scope-lock, recorded after slice 3, renders D-3 as one preservation into a `prior/` directory under the store, and the row names the ignore rule that release adds without spelling a stem it has not yet written. DEV-30 stays as recorded at slice 3 | Stage-7 Dev Testing F-06 on #8683; the release-usage-measured-right scope-lock record on #8662 | Minor |
| DEV-48 | 7 → 6 | The registered-homes paragraph states the carve-out as the superseding record's set and says what the hook's static set holds today, `/analysis/<sub>/` and `/roadmaps/<name>`, with `/local-state/` joining it in the worktree-sessions slice's change | Stage-7 Dev Testing F-07 on #8683 | Minor |
| DEV-49 | 7 → 6 | The gate-efficacy census row excludes only a comment line whose leaf no code path resolves, which keeps 16 members and lets a missing S-11 lower the count, and it states the probe's reach limit for a member joined through a variable | Stage-7 Dev Testing F-04 and F-05 on #8683 | Minor |
| DEV-50 | 7 → 6 | Step (1) of the charter template's Classification Rule carries the deferral steps (2) and (3) carry — "except platform working state and leak-risk content, which step (4) classifies even where a listed tree such as `pmo-platform/` contains its home" — so the Layer table's `pmo-platform/` (entire tree) row no longer classes an in-repo home's git-ignored contents as Layer 1 before step (2) is reached. No step is renumbered, and the clause states no layer; the layer itself stays open (DEV-42) | Stage-7 Dev Testing F-01 on #8685, routed Tier 1 fix-now by the hub when it reopened #8677 | Major |
| DEV-51 | 7 → 6 | § Slice 4's Runtime suite row is corrected in place: map row 5 names `core/CLAUDE.md.template`, so the slice selected the install/onboarding/update standing regression suite, not the no-match row. The row carries Stage 7's run at `9645f807`; this iteration's run at `c2a47308` is in § Slice 4, Stage-7 iteration 1. The slice's owed `test-run/suite-skip` is replaced by `test-run` events | Stage-7 Dev Testing F-02 on #8685 | Minor |
| DEV-52 | 7 → 6 | The two workspace-root writers DEV-46 recorded for the hub are registered, in a #8017 commit: S-41's Resolves-today cell adds the tamper backups, and S-42 registers the install validator's per-run artifact folder as `Undecided`, decided by the install-and-update card, whose References line now names S-42. The register reads 42 rows, three `Undecided`. DEV-46 stays as recorded | the hub's ruling on the slice-3 iteration's recommendation on #8675 | Minor |

---

## Issue References

- #8005 — the parent epic (wave 1 of 8).
- #8016, #6627, #8017, #8018 — the four cards this release delivers.
- #8663 — the Stage-4 planning sub-task: the plan, the gate record and the scope-lock record.
- #8665, #8666, #8668, #8670 — the Stage-5 design sub-tasks and their adversarial reviews.
- #8671 — the Stage-6 sub-task for #8016, which authored this file.
- #8019, #8020, #8029, #8032 — later-wave cards this release names as owners of obligations it records.
