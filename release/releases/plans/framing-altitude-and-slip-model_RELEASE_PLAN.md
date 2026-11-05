---
title: Release Plan — framing-altitude-and-slip-model (one decision record for how a framing declares its altitude and how a framing slip is surfaced)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v5.02; the concrete number binds at the Stage-12 atomic claim)
milestone: framing-altitude-and-slip-model
release_class: novel
reversibility: CHEAP / Confidence HIGH before the Stage-13 ratification gate — drop the record commit before merge, or revert the single release merge after it; after ratification the record is immutable and is changed only by a superseding record. The register row is deleted with the revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `framing-altitude-and-slip-model`

**Milestone:** `framing-altitude-and-slip-model` (milestone 431), one card: **#7965** (`type:spike`, P3, size:S; parent epic #7540). The Stage-4 planning sub-task **#8749** carries the approved plan and the Stage-4 gate's Decision Recorded. The Stage-5 design (revision 0), the scope-lock rulings, the revised design (revision 1) and the scope-lock record are on **#8755**; the Phase A6.5 adversarial review is on **#8802**. This file is Engineering Commit 0, authored by the Stage-6 spoke on **#8757**.

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v5.02`** (the next-free minor recomputed at this commit). The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/framing-altitude-and-slip-model`, one pull request opened in **draft** at Stage 6 Phase C2, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — one card, one wave, one Engineering spoke. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel` — trigger (b), a D-class decision, and trigger (c), a Stage-5 ADR, fire; routine trigger (a) also fires, and novel wins by precedence. Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8749 (issuecomment-6663977799) and is amended by four records, in order: the Stage-4 Decision Recorded on #8749 (issuecomment-6664203145: plan approved, `novel`, SINGLE, P0, D-Amendments (A) with its `[BUNDLE AMENDMENT]`), the Stage-5 scope-lock rulings on #8755 (issuecomment-6665888629), the revised Stage-5 design on #8755 (revision 1, issuecomment-6666536076, which supersedes revision 0 wherever they differ), and the Stage-5 scope-lock record on #8755 (issuecomment-6666562696). The revised design's `### Output for Stage 6` Change 0 is applied here. Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a decision record is added, per the Bump-Class Selection Guide's "reference document addition or update"; no skill and no governance file changes. Provisional display `v5.02`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-05 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing — Stage 6 Engineering: Commit 0 (this file), then the decision record, then the register row |
| **Branch** | `release/framing-altitude-and-slip-model` |
| **PR** | opened in **draft** at Stage 6 Phase C2; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `framing-altitude-and-slip-model` (milestone 431) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-05, domain: governance }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform artifact — one decision record, one row and one Version History line in a core standard, and this plan — so no external body of practice is consumed. Dominant domain **`governance`**, classified from the File Change Matrix (Phase A3). Transcribed unchanged from the Stage-4 plan.

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `b1042eec` (`b1042eecd6294d4c460c109f2c4b8dd6ed9896a9`), equal to the Stage-4 baseline pin. This file is written on that base |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter: `release/tools/claim-version.sh --sha b1042eecd6294d4c460c109f2c4b8dd6ed9896a9 --bump minor --dry-run` (no tag pushed) | **`v5.02`** (exit 0; "would claim v5.02 (no tag pushed)"), equal to the Stage-4 planned provisional `v5.02` |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate and never authorize | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git tag -l 'v5.02' after git fetch --tags origin              (tag arm — binds)
             gh release list --limit 5                                     (Release arm; newest first)
             git show origin/main:release/releases/RELEASE_LOG.md, count of the literal 'v5.02'
                                                                           (ledger arm)
Denominator: every fetched tag (the highest v5 tags are v5.01 and v5.00); the five newest
             published Releases (v5.01, v5.00, v4.81, v4.80.1, v4.80); the ledger read from
             origin/main, never the worktree copy
Control - sensitivity: the same three reads on the v5.01 slot — 1 tag, 1 Release (the newest),
             7 ledger hits. Every arm returns non-zero, so a zero on the v5.02 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version has no
             near-miss class the probe must reject (PV-2c)
Extraction:  the whole local tag list, the Release list, and the whole ledger from origin/main
Result:      0 occupants of the v5.02 slot on every arm
Verdict:     CLEAN — v5.02 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** three sibling release heads, all bump-class minor and all recomputing `v5.02` (§ Cross-PR Overlap Audit → In-Flight Release Roster). The slot binds in merge order at the atomic claim; this is the expected Tier-S version-axis edge, not a HALT condition, because no sibling has merged and no `v5.02` tag exists.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp framing-altitude-and-slip-model`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-05`** (Thursday). It fills the decision record's `date:` frontmatter and its census entry under `source_observations:`.

**Census denominator, re-run at the release base** (revised design § Date Variable; Commit-0 checks): `git ls-files -- '*.md'` → 1502 files; `git grep -c -i -F altitude -- '*.md'` → 200 files and 810 lines (the per-file counts summed); `git grep -o -i -F altitude -- '*.md'` → 1090 occurrences — at `b1042eec`, identical to the Stage-5 baseline because the base has not moved.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria | **None, and the section is omitted** (the non-ceremony signal). Enumerated over the in-release card set `{#7965}`: a CIAC spans at least 2 issues, and the release has 1 |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, which is also the Commit-0 base) | § Cross-PR Overlap Audit → Baseline SHA, and § Baseline pin |

---

## Scope

One card: **#7965 — Decide how an epic's framing declares its altitude and how a slip is surfaced** (`type:spike`, P3, size:S; parent epic #7540). It delivers one decision record that decides how an epic's framing declares its operating altitude in ADR-211's term, defines the framing slip (an undeclared decision on a question whose declared predecessor in the framing's declared question order is still open, with a cited material-presupposition check as a secondary review-time limb), distinguishes it from every sense of "altitude" a recorded corpus census finds, decides where detection lives and whether it is mechanical or a review-time judgment, and applies the definition to the measured instance, the two recorded ADR cases, out-of-sample cases and must-not-surface cases.

**The record is authored `Proposed`** and is ratified to `Accepted` at the Stage-13 ratification gate. It registers one class-3-O named-gap row in the gate-efficacy standard's gate-coverage register (Change 2).

Graded against #7965's four acceptance criteria at body revision **2026-11-05T17:08:32Z** (the in-place D-Amendments rewrite of AC-2, AC-3 and AC-4; the count stays 4).

### Stage-4 Phase A0 re-review (summary)

G-PL5 Mode R cache-read **HIT** (`rows_source: mode-r-cache`; all four currency operands equal). Nine adopted rows: 0 C3, 5 C2 (AC-2, AC-3, AC-4, Risk 3, the Parallelization Map), the rest C1. G-PL1 PASS with one Tier 1 [ADJUST] (the SA-G1 citation in the card's Evidence); G-PL2 PASS; G-PL3 SKIP (no release branch, so the formal window is empty by identity); G-PL4 documented pass-through. The Parallelization Map was stale and was re-derived; the currency decision was CONVERGENT → refresh outcome (2) amend, applied by the hub as the `[BUNDLE AMENDMENT]` (AI-001). The full re-review artifact is the Stage-4 comment on #8749.

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-05)

| ID | Decision | Rendered |
|---|---|---|
| D-PlanApproval | Plan approved as posted; the Release Outcome Statement kept, with the Actor-line wording fix in D-Amendments (d) | approved |
| D-ReleaseClass | Release Class | `novel` (routine trigger (a) also fires; novel wins by precedence) |
| D-C | Branch topology | SINGLE |
| D-Concurrency | Stage-6 posture | P0, fully serial |
| D-Amendments | Phase A0 C2 deltas and description corrections | (A) apply all — #7965's AC-2, AC-3 and AC-4 rewritten in place, the blast-radius risk bullet replaced, the SA-G1 citation updated; milestone description corrections (a) to (d) under `[BUNDLE AMENDMENT]` |
| — | D-Version (recorded determination) | minor → provisional v5.02; re-verified at Commit 0, Stage 9 A6.6 and the Stage-12 atomic claim |

### Stage-5 scope-lock rulings (operator, 2026-11-05)

| ID | Rendered |
|---|---|
| D-S5-Route | (A) revise at Stage 5, then lock |
| D-S5-Measure | (a) a declared question-dependency order, with the material-presupposition judgment as a secondary review-time check and the comparison set reduced to enumerated open questions |
| D-S5-ProvisionalExit | a re-test of each provisional decision when its open question is answered, in the provisional declared form and in the register row |
| D-S5-AC4Arm | genuine declared ladder-altitude moves, one meaning of "declared", a near-miss case inside the definition's domain, and the case table re-coded under the citation rule |
| D-S5-Home | (a) split by moment: the design-time arm extends the design-review checklist § 4 and the Stage-4 Phase A0 re-review (authored by R6's build card, no file change in this release); the framing-time and cut-time arms stay the registered named gap; the per-decision observable follows the decision-time-adherence token form |
| D-S5-Coverage | explicit Current State, Future State and Gap Map sections in the record |
| D-S5-Minors | PRF-3, PRF-4, FM-4, FM-5, FM-6 folded in, including the step that writes the population key into R6's build-card body before the drafting card closes |

### Stage-5 scope lock (hub-verified, 2026-11-05)

Every ruling applied and all twelve A6.5 findings dispositioned as applied (none held) in the revised design. **Hub determination (Tier 1 [ADJUST]):** FM-2 mitigation 3, the blind re-code of the case table, moves to Stage 8, where an independent coder produces the agreement (hub action item AI-003). **AUTHORIZE ENGINEERING**, conditional on the Stage-8 blind packet. Scope locked; P0, single branch, one draft PR.

---

## Dependency Graph

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #7965 | P3 | bundled | (none — root) | — |

**Artifact relationship graph**

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #7965 | GENERATES | `core/ADRs/ADR-230-framing-declares-its-altitude-and-surfaces-the-slip.md` | #7965 → file | File Change Matrix (add) |
| #7965 | GENERATES | one register row and one Version History row in `core/standards/gate-efficacy-standard.md` | #7965 → file | File Change Matrix (edit; Stage-5 `S5-REGISTERS-NAMED-GAP` fired) |
| ADR-211 | CITED BY | #7965 | ADR-211 → #7965 | the altitude term and the continuity rule |
| #7965 | FEEDS | R6's follow-on build card, drafted by #8100 | #7965 → #8100 | consumer edge, not a build edge |

- **Inbound:** none. Native `blockedBy` 0; the body reads "None blocking."
- **Outbound:** none native (`blocking` 0). #8100 is blocked by #7961 and #7962 (ms#430), not by #7965.
- **Soft / coordination:** #7960 shares ADR-211's altitude term; #7963 writes the Framing carry; #6902 and #7539 are related inputs; ms#420's #6390 is a semantic neighbour, not a duplicate.
- **Critical path:** none — the bundle has no in-release dependency edge (chain length 0).

---

## Implementation Sequence

The release is a single card and runs strictly serial (P0).

| Order | Stage | Actor | Work | Exit |
|---|---|---|---|---|
| 1 | 5 Solutioning | Stage-5 spoke (base Solutioning; ADR deliverable), the A6.5 adversarial round, then the revision spoke | decide the declaration's form and place; the measure behind "one level below its question"; the detection home, mechanical vs review-time, with its runner or a registered gap; the sense census with probe and denominator; the case set; placement and slug; the T3 riders | done — AUTHORIZE ENGINEERING (revision 1, scope locked) |
| 2 | 6 — Commit 0 | Stage-6 spoke | version re-verify (steps 1–3); write this plan with the Commit-0 Survival Set and the revised design's Change 0; `claim-version.sh --verify-stamp framing-altitude-and-slip-model`; commit | `--verify-stamp` exit 0 |
| 3 | 6 — the record | same spoke | author the record at `renumber-adr.py --next-free` (230 at `b1042eec`), `status: Proposed`, per the revised design's Change 1; prose citations elsewhere use the record's slug token, never in a link target | the record committed |
| 4 | 6 — the register row | same spoke | Change 2: one class-3-O named-gap row at the register tail and one Version History line, re-read at the base first; open the draft PR | draft PR open |
| 5 | 6 — verify | same spoke | C4: `verify-release-plan.sh` families, ADR number and durability lints, doc-link checks, the consumer-identifier and handle grep; § Change Description | C4 PASS |
| 6 | 7 · 8 | DT, QA spokes | Stage 7 REDUCE battery, including `domain_practice`; Stage 8 AC-1..AC-4 by named read plus the blind re-code of the AC-4 case table | per-criterion verdicts; k of 15 |
| 7 | 9 → 12 | hub + spokes | Deep review; A6.5 and A6.6 re-measure of the ADR and version slots; merge, atomic claim, renumber if 230 is taken, `--stamp`, `--stamp --check` | zero residual slug tokens |
| 8 | 13 | hub + spokes | ratification: `status:` Proposed → Accepted on the chore PR, read from the record; the #8100 notification and the #7960 and #7963 coordination notes; release notes; 30-day window | G-CL gates |

**Change specification — #7965**

- **Files:** § File Change Matrix.
- **Change:** the decision record (Change 1); one class-3-O named-gap register row and one Version History line (Change 2); this plan (Change 0).
- **Acceptance criteria:** AC-1..AC-4 at body revision 2026-11-05T17:08:32Z (count 4).
- **Complexity:** Medium — a judgment-grade decision on small-N evidence; at Stage 6 the only non-transcription step is the census denominator.
- **Dependencies:** none in-release and none inbound.

**Lifecycle Definition (new artifact: the ADR)** — per `RELEASE_PROTOCOL.md` § Lifecycle Definition Requirement: (1) growth — fixed size, one record per decision; (2) size discipline — the ADR schema's seven sections plus the three coverage sections and `## References`; (3) cleanup trigger — supersession by a later record; (4) archive path — none; a superseded record stays in place marked Superseded; (5) ownership — the workspace owner, who owns the epic-framing epic; (6) exit — superseded, never deleted. Adoption into the framing and review surfaces is follow-on work owned by R6's build card.

### Agent-Editability Read

Controls read at `b1042eec` (the Stage-4 comment on #8749 carries the derivation): the Tier-0 floor in `core/hooks/block-autonomy-ceiling.sh` reduces in-repo to three basenames at any depth (`CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`); the sanctioned-session gate in `core/hooks/block-skill-direct-edit.sh` scopes `SKILL.md` and skill `references/` paths. No write-set path intersects either.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| release | `release/releases/plans/framing-altitude-and-slip-model_RELEASE_PLAN.md` | no | no | unconstrained | — | Engineering Commit 0 |
| #7965 | `core/ADRs/ADR-230-framing-declares-its-altitude-and-surfaces-the-slip.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #7965 | `core/standards/gate-efficacy-standard.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #7965 | `core/ADRs/README.md` (CONDITIONAL; `renumber-adr.py` R4 log append) | no | no | unconstrained | unconstrained | Stage-12 merge reconciliation |

There are no `delete` rows. `unconstrained` means no control refuses the write; the change is still governed through the issue, the plan and the PR.

---

## Stage Applicability Matrix

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #7965 | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | **T1:** a new ADR carrying a named rule. **T3:** the declaration's form and where it sits in the framing is a convention downstream framing surfaces will carry. **T4:** detection home × mechanical vs review-time. **T2:** no skill path. **T5:** 0 governance files. **T6:** the write set is enumerable with conditionals declared. |

**Riders recorded against #7965** (Stage 4, carried; Stage 5 dispositions): **§ 3.1 abstraction altitude** — the seams are named: declaration and order → ADR-211's altitude slot and carry; value → the `general_level` enum; design-time detection → the design-review checklist § 4 and Stage-4 Phase A0; framing-time and cut-time detection → R6's framing method; observable → `decision-time-adherence.md` § 3; runner → a sibling register row. No point solution. **§ 3.2 structural premise** — SR-G1: the ADR pattern was reviewed and retained (D-class, MODERATE after ratification; extra H2s are schema-admissible). **SR-G6** — extend for the declaration and detection; `net-new because in-place is infeasible:` for the row only — ADR-211's continuity row triggers on the cut or a later stage acting on a slice and compares parent and slice framings, so it cannot see an intra-framing slip, and rewriting it would alter an obligation another record owns. **SR-G7 applies to Change 2** — the register's aggregated evaluand set gains one member, traced to Check 62 (no pointer, so outside its population) and G-CL10 arm (i) (a member; warn posture).

| Stage | #7965 | Basis |
|---|---|---|
| **5 — Solutioning** | ACTIVATE: base Solutioning with an ADR deliverable, plus an adversarial review round and one revision | T1/T3/T4; activation bias ALL (novel); the Research-Methodology Design variant does not fire |
| **6 — Engineering** | APPLY | Commit 0 (plan) + the record + the register row; P0 |
| **7 — Dev Testing** | REDUCE | No executable surface. The doc-conformance battery (§ Verification Plan, release-level), including the `domain_practice` verification Stage 7 always runs |
| **8 — QA** | APPLY (per-criterion, by named read) + blind re-code of the AC-4 case table (C1–C15; agreement k of 15; threshold 12) | AC-1..AC-4 verdicts against the record; the AC-4 case table is checked for its must-not-surface arm; the blind packet is pasted into the Stage-8 brief by the hub (AI-003) |
| **9 — Plan Review** | APPLY (release) | Deep (`novel`). G-PR7 against the Outcome Statement. A6.5 divergence; A6.6 in-flight re-measure of the ADR and version slots |
| **10 — Dry Run** | PLATFORM-SATISFIED | The PR diff is the dry run |
| **11 — Snapshot** | PLATFORM-SATISFIED | Git history is the snapshot |
| **12 — Execute** | APPLY (release) | Merge commit. Atomic claim with `--stamp-slug framing-altitude-and-slip-model`. `renumber-adr.py` reconciliation if slot 230 is taken, then `--stamp` and `--stamp --check`. No Layer-2 deploy |
| **13 — Close** | APPLY (release) | Ratification gate: `status: Proposed → Accepted`, read from the record's own `status:` line, because Check 58 is advisory-only. The #8100 notification before the G-CL10 record is taken; the #7960 and #7963 notes. 30-day outcome window |

Totals: 0 stages skipped, 1 at REDUCE, 2 platform-satisfied. Parallel-eligible spokes: Stage 5: 1 · Stage 7: 1 · Stage 8: 1.

### Tier-A activated design artifacts

| Artifact path | Flow class | Trigger | Activation | G-CL6 obligation |
|---|---|---|---|---|
| `core/ADRs/ADR-230-framing-declares-its-altitude-and-surfaces-the-slip.md` § Decision (the framing tree, plus the senses and case tables) | Concept model | a new concept (*framing slip*) named in a governance file (the register row) | A NEW | Refresh at Stage 13 only if the concept text changes |

---

## File Change Matrix

```
# ── Engineering Commit 0 (plan transcription) ──
release/releases/plans/framing-altitude-and-slip-model_RELEASE_PLAN.md                 add
# ── #7965 Change 1 — the decision record (placement core/ADRs/ per Stage 5 D7; number = renumber-adr.py --next-free at authoring, reconciled at merge) ──
core/ADRs/ADR-230-framing-declares-its-altitude-and-surfaces-the-slip.md               add
# ── #7965 Change 2 — one class-3-O named-gap row at the register tail and one Version History line (CONDITIONAL:S5-REGISTERS-NAMED-GAP fired at Stage 5; promoted at Commit 0) ──
core/standards/gate-efficacy-standard.md                                               edit

# ── CONDITIONAL — resolved FALSE at Stage 5 (placement is core/ADRs/; no curated README entry); NOT DELIVERED, recorded in § Deviation Log ──
CONDITIONAL:S5-PLACEMENT-RELEASE     release/ADRs/ADR-NNN-framing-declares-its-altitude-and-surfaces-the-slip.md   add
CONDITIONAL:S5-PLACEMENT-RELEASE     release/ADRs/README.md                                                         edit
CONDITIONAL:S5-CURATED-README-ENTRY  core/ADRs/README.md                                                            edit
# ── CONDITIONAL — slot 230 is taken at merge; renumber-adr.py R4 appends a Renumber-log line (resolves at Stage 12) ──
CONDITIONAL:ADR-RENUMBER-AT-MERGE    core/ADRs/README.md                                                            edit
```

#### Read-only inputs

```
core/ADRs/ADR-211-design-axes-and-cut-patterns-key-on-work-nature.md   READ
core/schemas/adr-schema.md                                             READ
core/standards/adr-authoring-guide.md                                  READ
core/rules/decision-time-adherence.md                                  READ
release/references/templates/design-review-checklist.md                READ
release/tools/renumber-adr.py                                          READ
release/tools/check-adr-durability.py                                  READ
release/tools/claim-version.sh                                         READ
```

#### Release-wide explicit non-scope

```
core/disciplines/discovery-discipline.md                               NOT EDITED
core/disciplines/architecture-evaluative-lens.md                       NOT EDITED
core/disciplines/work-organization-mapping-framework.md                NOT EDITED
core/rules/decision-time-adherence.md                                  NOT EDITED
release/references/templates/design-review-checklist.md                NOT EDITED
release/references/pipeline/stage-04-planning.md                       NOT EDITED
release/references/standards/triage-design-rereview.md                 NOT EDITED
```

The seams in the non-scope block above are named for R6's build card (the revised design's D5 and Blast Radius); none is edited in this release.

**New-executable companion obligation:** N/A — enumerated over the two unconditional `add` rows and the one unconditional `edit` row (all Markdown) and the four CONDITIONAL rows (all Markdown); no `.sh` is added.

**Deliverable-domain classification (A3):** `domain: governance`. Every row is a pmo-platform governance or decision artifact: an ADR, a standard and a plan.

---

## Integration Points

- **Upstream inputs:** ADR-211 § Terms (Altitude) and § Continuity rule (Accepted); #7540 R6 and its measured instance, as #7540 quotes it; ADR-173 § Alternatives and ADR-184 § Rejected.
- **Downstream consumers:** #8100 drafts R6's follow-on build card from this record (the framing-method step; the design-review checklist § 4 item and the Phase A0 line, with the row split; the decision-time-adherence index row; the lens pointer). #7960's altitude entry shares the term. #7963 writes the Framing carry.
- **Mechanical seams:** the ADR number space (`check-adr-numbers.py`, plus `renumber-adr.py` with `--next-free`, `--detect` and `--stamp`); the version claim (`claim-version.sh`); the gate-coverage register (Check 62 reads resolution pointers only; G-CL10 arm (i) reads `prose`-surface rows); Stage-13 ratification and Check 58 (advisory).

### Contention Map

**Within the release:** none — one card (denominator 1, so no pair exists).

| Surface | Siblings touching it (heads read live at Commit 0) | overlap_class (ADR-005) | Resolution |
|---|---|---|---|
| `core/ADRs/ADR-230-…md` (unconditional add) | none on this path | single-pr | — |
| ADR number slot 230 (virtual; one global sequence across both ADR directories) | `guards-judge-every-spelling-alike` (#8651; `core/ADRs/` 230 and 231), `composition-method-host-decision` (no PR; `core/ADRs/` 230), `sequencing-layer-foundation` (#8811; `release/ADRs/` 230) | Tier-S serialization | author at the mainline next-free (230); the first to merge binds and later claimants renumber at merge (`renumber-adr.py`, ADR-115); prose citations use the slug token, so a move costs no citation sweep |
| version slot `Δversion/5.2.0` (virtual) | all three siblings (minor, recomputed `v5.02`) | Tier-S serialization | the Stage-12 atomic claim in merge order; the Commit-0 re-verify ran (PROCEED) |
| `core/standards/gate-efficacy-standard.md` register tail and Version History tail | none open (no sibling head touches the file) | single-pr | re-read at the base before the append |
| `core/ADRs/README.md` § Renumber log (CONDITIONAL) | #8651 (+1 line, Renumber log) | append-pattern | informational; keep-both at merge |
| the plan file | none | single-pr | — |

---

## Cross-PR Overlap Audit

### Baseline SHA

`b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` (`origin/main` at the Stage-4 audit start, 2026-11-05T16:32:46Z). Unmoved at Commit 0. **Sibling-merge revalidation predicate** (Stage 9 G-PR9 and Stage 12 A.5): `git log b1042eec..origin/main --name-status --find-renames`, intersected with SURFACE(R) = { `core/ADRs/ADR-*-framing-declares-its-altitude-and-surfaces-the-slip.md`, `core/standards/gate-efficacy-standard.md`, `core/ADRs/README.md`, `Δversion/5.2.0`, the ADR slot }.

### In-Flight Release Roster

**Measured at:** `b1042eec` · Commit 0, 2026-11-05T19:09Z · **Population:** n=3 sibling(s) (`gh pr list --state open --limit 500` → 2 open PRs, both with a `release/*` head, drafts included; `git ls-remote --heads origin 'refs/heads/release/*'` → those two heads plus one head with no PR)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `guards-judge-every-spelling-alike` | `#8651` | `fc556c66` | `minor` | `v4.82` (stale) | `v5.02` | `core/ADRs/README.md` (CONDITIONAL, append-pattern); ADR slot 230 (`core/ADRs/` 230, 231) |
| `sequencing-layer-foundation` | `#8811` | `00785cd4` | `minor` | `v5.02` | `v5.02` | ADR slot 230 (`release/ADRs/` 230) |
| `composition-method-host-decision` | `—` | `c0c91afa` | `minor` | `v5.02` | `v5.02` | ADR slot 230 (`core/ADRs/` 230) |

No verdict is rendered here; Stage 9 A6.6 re-measures. Two of the three are new since the Stage-4 roster (n=1), and both hold slot 230 on their branches (§ Deviation Log DEV-8).

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner | Reversibility |
|---|---|---|---|---|---|---|
| R1 | ADR slot 230 is taken first by a sibling (three sibling heads hold 230 on their branches) | High | Low | Author at `--next-free`; prose citations via the record's slug token; at merge `renumber-adr.py` reconciles, then `--stamp` and `--stamp --check` | Stage-12 hub | CHEAP |
| R2 | v5.02 is claimed by a minor-intent sibling | High | Low | Commit-0 re-verify (the tag arm binds; PROCEED); Stage-9 A6.6; the atomic claim recomputes | Stage-6 spoke; Stage-12 hub | CHEAP |
| R3 | "One level below its question" becomes a fifth sense of altitude, colliding with ADR-211 and #7960 | Medium | Medium | Resolved at Stage 5 (D-S5-Measure (a)): the slip is measured in steps of the framing's declared question order, never in altitude; "altitude" appears in the definition only as the level at which the framing states its question | Stage-5 spoke | MODERATE |
| R4 | Self-referential validation on small N | Medium | Medium | Out-of-sample, near-miss and must-not-surface cases (C4–C15); the Stage-8 blind re-code with threshold 12 of 15; below it AC-4 is NOT MET and returns to Engineering | Stage-5, Stage-8 spokes | CHEAP |
| R5 | Measured-instance identifiers reach this public repository | Low | High | Cite only as #7540 quotes it; a pre-push grep on the record, the plan and the PR body; the depersonalization gate | Stage-6 spoke; Stage-9 hub | MODERATE |
| R6 | Scope widens into `discovery-discipline.md` (#7960 § 4.3), the lens, the checklist or the decision-time-adherence index | Low | Medium | `NOT EDITED`; those seams are R6's build card's; a widening is a Tier 2 [SCOPE CHANGE] and re-runs the overlap audit | Stage-6 spoke → hub | CHEAP |
| R7 | The named-gap row widens the write set to `gate-efficacy-standard.md` | Resolved | Low | Fired at Stage 5 and promoted at Commit 0; a tail append, kept both ways at merge | Stage-6 spoke | CHEAP |
| R8 | The Stage-13 ratification flip is omitted (the record stays `Proposed`) | Medium | Medium | Stage 13 reads the record's own `status:` line; Check 58 is advisory | Stage-13 hub | CHEAP |
| R9 | Line-number citations rot inside the record | Medium | Low | The record cites sections and anchors, not lines | Stage-6 spoke | CHEAP |
| R10 | Siblings merge to `main` mid-pipeline (baseline-pin staleness) | High | Low | Stage 9 A6.5 / A6.6; Stage 7/8 entry checks; Stage 12 A.5 | Stage-9 hub | CHEAP |
| R11 | The Stage-8 blind re-code falls below threshold late in the release | Medium | Low | The record already states the threshold and the consequence; the change is a text edit returned to Engineering under Phase E | Stage-8 spoke; Stage-6 spoke | CHEAP |
| R12 | The named gap stays open: no runner until R6's build card ships the framing-method step and the design-time items | High | Low | The row's observable is a dated line appended at a Stage-13 close, so a skipped test shows as t below k and a skipped re-test as r below q; the row states it cannot emit until the framing method records altitude, question order and decisions | workspace owner | CHEAP |

**Rollback complexity:** low. A single merge commit adds one file and edits one standard, all Markdown, with no runtime or Layer-2 effect.

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential — one card |
| Commit strategy | Commit 0 = this plan; then the record; then the register row and Version History line; then the Change Description and Verification Evidence. Each slice is committed and pushed as it lands (write-early). Stage 7 and 8 fix-ups land as separate commits. A merge-time renumber commit is added only if the slot collided |
| Review approach | One release PR, `release(framing-altitude-and-slip-model): …`, from `release/framing-altitude-and-slip-model`, opened in draft at Stage 6. The close keyword for #7965 appears only in the PR body's Issue References block; every other surface says #7965 is marked closed at Stage 13 |
| Topology · posture | D-C SINGLE · P0 fully serial; no force-push, `--force-with-lease` included |
| Deployment mechanism | Git merge commit plus the Stage-12 atomic claim; no Layer-2 deploy |
| Merge-time order (Stage 12) | merge; atomic version claim; `renumber-adr.py --detect`, then the reconciliation if slot 230 is taken; `renumber-adr.py --stamp`; `--stamp --check`; RELEASE_LOG chore PR |

---

## Verification Plan

`ac_baseline: { #7965: 4, read_at: b1042eecd6294d4c460c109f2c4b8dd6ed9896a9 }` (body revision **2026-11-05T17:08:32Z**, counted as the `- [ ]` lines of the issue body). An amendment to any of the four criteria obliges an update to its row in the same change. Each AC row points at a heading of the record; the record is `core/ADRs/ADR-230-framing-declares-its-altitude-and-surfaces-the-slip.md` (its number is reconciled at merge by `renumber-adr.py`, whose branch-scoped citation sweep rewrites this path).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7965 | AC-1 | declared, verification deferred to Stage 8 per-criterion acceptance review: a named read of the record's `### Terms` and `### The declaration` against ADR-211 § Terms (Altitude) and #7960's altitude entry | MET when the record cites ADR-211's altitude term, decides only the declaration's form and place in the framing, defines no second vocabulary, and states that the cut-basis card's altitude entry uses the same term |
| #7965 | AC-2 | declared, verification deferred to Stage 8: a named read of the record's `### Distinctions` and its census entry under `source_observations:` (probe, denominator) | MET when every sense the census finds is distinguished, with the abstraction band, hierarchy-ladder placement, SA-G1 scope altitude and pmo-architect's rungs as the minimum |
| #7965 | AC-3 | declared, verification deferred to Stage 8: a named read of the record's `### The framing slip and its measure`, `### Declared moves and the continuity rule`, `### Where detection lives` and `### Mechanical or review-time`, plus the gate-coverage register row | MET when the record states the home, mechanical vs review-time with its reason, the measure used and how it stays inside ADR-211's term, why the lens's altitude circle is not the home, the registered named gap, and the declared-move vs slip distinction |
| #7965 | AC-4 | declared, verification deferred to Stage 8: a named read of the record's `### Applying the definition`, plus the blind re-code — before opening the record, this plan, #8755's comments, #8802, the release PR or any other milestone-431 issue (its own sub-task body excepted), the Stage-8 spoke re-codes C1–C15 from the codebook sections and the *Case input* column pasted into its brief, and reports agreement k of 15, each disagreement with its reason, and its read order | MET when every case carries a verdict, the must-not-surface arm includes a declared ladder-altitude move, and k is at least 12. A verdict is surfaced or not surfaced, conditional with its condition stated, or INDETERMINATE with its missing element stated. If k is below 12 → NOT MET, returned to Engineering to record the figures in the case section and state the review-time limb unvalidated |

### Release-Level Verification (Stage-7 REDUCE battery; Stage-6 C4 runs it first)

| Check | Runner | Expected |
|---|---|---|
| ADR number contiguity | `python3 release/tools/check-adr-numbers.py` (CI `adr-number-integrity`) | no duplicate, no gap |
| ADR durability lint | `python3 release/tools/check-adr-durability.py --files <record> --diff-base origin/main` (CI, warn-mode) | no finding on added lines; a seeded `#N`-in-`title:` mutant flags R4 |
| ADR schema | the seven sections present (`core/schemas/adr-schema.md` § 3), the three coverage sections after `## Related ADRs`, `## References` last; `status:` leading token `Proposed` | all present |
| Slug-token residue | `renumber-adr.py --stamp --check` (Stage 12, after stamping) | zero residual tokens; no token in a link target |
| Doc links and plan depth | `check-release-links.py --plan-depth-lint` (release PR) | workspace-rooted links only |
| Plan families | `verify-release-plan.sh` (`provenance-survival`, `fcm-delivery`) | PASS; promoted or NOT DELIVERED rows recorded |
| Change 2 — pointer-free row | Check 62's own pointer pattern over the new row | 0 on the new row; non-zero on a row that carries a pointer, as the control |
| `domain_practice` presence | Stage 7 provenance verification | label present, Form X, `domain:` in-label |
| Depersonalization | `repo-integrity.yml`, and the Stage-6 pre-push grep for consumer identifiers and the operator handle | 0, with a control arm |
| **Blind re-code (Stage 8)** | the AC-4 row's method | k at least 12 of 15 |
| Check 58 | `deploy.sh --check` lists the record as Proposed with a flip promise | advisory and expected; the Stage-13 ratification settles it |

**ADR index:** N/A — this release adds no record under `release/ADRs/` (`core/ADRs/README.md` is curated and has no projector).

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A).
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: 1 · Stage 7: 1 · Stage 8: 1.
**Per-spoke cost estimate:** the `size:S` band, the lowest (source: heuristic).
**Assumed/stated remaining usage-window envelope:** UNSTATED — the conservative default applies [ASSUMPTION – CONFIRM].
**Estimated cumulative draw % (worst parallel batch):** about 5–8% (the Stage-5 spoke plus one refuter, run serially) — a projection, not a measurement.
**Routing:** PASS: proceed.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant per `quota-budget-protocol.md` § 4.3b. Checkpoint A stays usage-window-only. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`novel`.** Triggers fired: novel (b), at least one D-class decision (the record itself plus this plan's D-gates); novel (c), a Stage-5 ADR. Routine (a) **also fires**: all issues are P3 and size:S. Routine (c) and (d) fail (a file is added; D-class decisions exist). No cross-cutting trigger fires: 0 stage files, 0 rule-defining surfaces, 0 in-bundle edges. Novel dominates by precedence (cross-cutting > novel > routine).

- **Differentiation posture:** engagement density **Standard** · Stage 9 review **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.
- **Size bound:** 2 raw × 1.15 (novel) = 2 effective, under the 15–25 target; kept as a gating-only single-item slice (doctrine § 3 Step 5), so there is no over-scope flag.

---

## Release Outcome Statement

Transcribed from the milestone description (Actor line as amended under D-Amendments (d)).

**AFTER** — The platform has one decision record, ratified at this release's close, that states how an epic's framing declares the altitude it operates at — using ADR-211's altitude term, the level on the work-organization ladder at which a framing states its question — and how a design decided one level below the question it answers is surfaced: where detection lives, whether it is mechanical or a review-time judgment, and how a slip differs from a declared altitude move under ADR-211's continuity rule. The record is applied to the measured instance's roster-and-channel case and to the two recorded ADR cases, and states whether each would have been surfaced.

**BEFORE** — "Altitude" carries four senses in the corpus and none of them names the slip pattern. In the measured instance an item criticised its predecessor for specifying a verifier before knowing the channel, then repeated the same error one level up, and nothing surfaced it. ADR-211 makes altitude part of the framing an epic carries but does not say how it is declared or how a slip shows.

**Actor(s):** a Stage-5 Solutioning spoke (base Solutioning; deliverable = a decision record); the operator at Stage 9 and at the Stage-13 ratification gate.

**Success Indicator:** At Stage 13 the record reads Accepted on `main` and states, for each of the three recorded cases, whether its definition would have surfaced the slip.

---

## Rollback Strategy

| Issue | Rollback Method | Rollback Complexity |
|---|---|---|
| #7965 | Before merge: drop the record commit and the register-row commit, or close the draft PR. After merge, before ratification: `git revert` of the merge commit. After ratification (Accepted): author a superseding record, because an Accepted record is immutable | Low, rising to Medium over time |

| Strategy | Trigger | Procedure |
|---|---|---|
| Partial revert | the record is wrong before ratification | Revert the record commit and the Change 2 commit. If `renumber-adr.py` moved the record, the revert also removes its Renumber-log line |
| Full restore | systemic failure after merge | Revert the merge commit and record the rollback; the version tag is retained, never deleted (`core/rules/git-workflow.md` § Tag Retention), and the withdrawal is recorded in the re-version ledger. After the Stage-12 chore PR this plan sits at its versioned path under `release/releases/plans/v5/`, and the revert must name that renamed path |
| Forward fix | the definition needs recalibration after ratification | A superseding record; R6's build card re-reads it |

**Layer-2 effect:** none, so no deploy rollback is needed.

---

## Operational Deployment Manifest

N/A — enumerated over skill trees, rules mirrors, hooks, templates, config, packages and harness artifacts; the write set contains none of them. ADRs and standards are not deployed to Layer 2. Schema migrations: none. Memory evictions: none.

---

## Action items

| id | owner | category | description | status |
|---|---|---|---|---|
| AI-001 | hub | deferred-edit | The D-Amendments `[BUNDLE AMENDMENT]`: #7965's AC-2, AC-3 and AC-4 rewritten in place, the blast-radius risk bullet replaced and the SA-G1 citation updated; the milestone description's corrections (a) to (d) | resolved — applied by the hub (#7965 body revision 2026-11-05T17:08:32Z; the milestone description carries the map recorded 2026-11-05 and the amended Actor line); entered in § Deviation Log at this commit (DEV-1) |
| AI-002 | operator | deferred-edit | Replay the staged pipeline-event rows on the operator instance (the Stage-4 `re-review/phase-a0-row`, the Stage-5 `decision/cascade-sweep-block`, and any this Stage-6 spoke holds) | open |
| AI-003 | hub | decision-to-post | Paste the Stage-8 blind packet into the Stage-8 brief: the record's `### The slip test` and `### Declared moves and the continuity rule`, and the *Case input* column of C1–C15; nothing else; with the read exclusions of the AC-4 row | open, due at Stage 8 launch |
| AI-004 | hub | cross-issue-merge | Stage-13 notification to #8100 (R6), posted **before** the G-CL10 record is taken: it names `framing-slip-test-records`; requires #8100's drafting step to write that key into R6's build-card body before #8100 closes; lists the build card's scope (the framing-method step; the design-review checklist § 4 item and the Phase A0 line, with the row split; the decision-time-adherence index row; the lens pointer) | open, not yet due |
| AI-005 | hub | cross-issue-merge | Stage-13 coordination notes: #7960 (R5 — the same term, an offer to align its value set with the assignment rule, and the ladder's coarseness below Milestone) and #7963 (R7 — the Framing carry carries the parent's altitude line and its unhanded open questions, in order) | open, not yet due |

---

## Deviation Log

| # | Severity | Deviation | Authority / rationale |
|---|---|---|---|
| DEV-1 | minor | The D-Amendments body amendment (AI-001): #7965's AC-2, AC-3 and AC-4 were rewritten in place to carry the Stage-4 Phase A0 C2 deltas (the count stays 4), the blast-radius risk bullet was replaced, and the SA-G1 evidence citation was updated; the milestone description took corrections (a) to (d) under `[BUNDLE AMENDMENT]`. The `ac_baseline` body revision therefore moves from the Stage-4 read (2026-10-02T22:53:13Z) to **2026-11-05T17:08:32Z**, with the count unchanged at 4 | Stage-4 gate D-Amendments (A), #8749 issuecomment-6664203145 |
| DEV-2 | minor | `CONDITIONAL:S5-REGISTERS-NAMED-GAP` fired (the review-time branch registers a named gap; Stage-5 watch item (ii) hit) and is promoted at this commit to the unconditional row `core/standards/gate-efficacy-standard.md  edit` | Revised design R4 and Change 0 item 1; stage-04-planning.md § 6 FCM contract rule 5 |
| DEV-3 | minor | Both `CONDITIONAL:S5-PLACEMENT-RELEASE` rows — `release/ADRs/ADR-NNN-framing-declares-its-altitude-and-surfaces-the-slip.md` (add) and `release/ADRs/README.md` (edit) — are NOT DELIVERED — Stage 5 D7: the record is placed in `core/ADRs/` | Revised design D7 and Change 0 item 1 |
| DEV-4 | minor | `CONDITIONAL:S5-CURATED-README-ENTRY` — `core/ADRs/README.md` (edit) — is NOT DELIVERED — Stage 5 D7: no curated entry (ADR-211, the precedent, has none). `CONDITIONAL:ADR-RENUMBER-AT-MERGE` on the same path is kept and resolves at Stage 12 | Revised design D7 and Change 0 item 1 |
| DEV-5 | informational | Case verdicts against the card's evidence: the card cites ADR-173 and ADR-184 as recurrences of the pattern, but under the chosen definition ADR-173 is **not an instance** (the presupposed question was answered by a settled criterion; contradicting a settled answer is the recursive defect class) and ADR-184 is **conditional** (surfaced only if the framing had carried an open question the placement constrains, and that entry was cited) | Revised design D-Cases C3 and C4; Change 0 item 5 row 3 |
| DEV-6 | minor | Stage-5 revision 1 under the scope-lock rulings: all twelve A6.5 findings (#8802) applied per the revised design's § Finding Dispositions; the revised design supersedes revision 0 wherever they differ, and the record is transcribed from it alone | Scope-lock rulings, #8755 issuecomment-6665888629; scope lock, #8755 issuecomment-6666562696 |
| DEV-7 | minor | The blind re-code of the AC-4 case table is added to the Stage-8 row of § Stage Applicability Matrix and to the AC-4 row of § Verification Plan (method and expected result), on ADR-211's precedent (its release ran a blind re-code at Stage 8 with a 7-of-9 threshold); the threshold here is 12 of 15 | FM-2 mitigation 3; hub determination at the scope lock (Tier 1 [ADJUST]); Change 0 items 3 and 4 |
| DEV-8 | informational | Two sibling release heads new since the Stage-4 roster now hold ADR slot 230 on their branches: `composition-method-host-decision` (no PR; `core/ADRs/` 230) and `sequencing-layer-foundation` (#8811; `release/ADRs/` 230). With #8651 that makes three branch-side claims on 230. The resolution is unchanged — author at the mainline next-free, renumber at merge | Contention re-read at Commit 0 (`git ls-remote` and `gh pr list`) |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit(s) | Notes |
|---|---|---|---|---|
| #7965 | None — no documentation impact (rationale: the deliverable is the decision record; the framing and review surfaces that adopt it are follow-on cards) | NONE | — | the record and its register row are the deliverable |

**Deliverable state:** `artifact-accepted` — the record at its declared canonical path, with its Artifact-Acceptance Record row populated in § Verification Evidence at Stage 13 (a task-class deliverable; no deployed copy).

---

## Verification Evidence

Populated at C4 self-verification (Stage 6), then re-run at Stage 7.

### Engineering Commit 0 — Stage 6 A1

- **Commit-0 step 3b** — `bash release/tools/claim-version.sh --verify-stamp framing-altitude-and-slip-model` → exit **0**, "verify-stamp OK — framing-altitude-and-slip-model carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". Sensitivity arm (PV-2a mutation form): the same file with the placeholder replaced by a literal version → exit **1**, "verify-stamp TOKEN-LESS PLAN"; the original was restored from a run-directory copy, re-counted at exactly one placeholder, and re-checked at exit 0.
- **A1 CIAC lint on the plan** — `bash release/tools/verify-release-plan.sh --ciac-lint <this plan>` → `CIAC-LINT-SUMMARY declared=0 parsed=0 clean=0 declared-deferral=0 flagged=0`, exit 0 — consistent with the population of one card (Survival-Set row 3). Gate verdict: **PROCEED**.
- **Plan links** — this file carries no markdown link sequence (a count of the link-opening sequence over the file → 0; the same count over the release-planning template's exemplar file is non-zero), so the plan-depth lint has nothing to grade here.

---

## Change Description

Authored at Phase C1 once the record and the register row land; until then this section records the in-flight state. **Outcome so far:** Engineering Commit 0 — this plan, transcribed from the approved Stage-4 plan with the revised Stage-5 design's Change 0.

---

## Baseline pin

`origin/main` @ `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9` (2026-11-05T16:32:46Z), the Stage-4 audit-start baseline; unmoved at Commit 0.

---

## Issue References

- #7965 — the one member: the spike deciding how a framing declares its altitude and how a framing slip is surfaced
- #8749 — Stage-4 Release Planning sub-task: the approved plan and its gate record
- #8755 — Stage-5 Solutioning sub-task: the design, the scope-lock rulings, the revised design and the scope-lock record
- #8802 — the Phase A6.5 adversarial design review
- #8757 — Stage-6 Engineering sub-task
- #7540 — the epic-framing epic (parent): R6 and the measured instance
- #8100 — the card drafting R6's build card
- #7960 — the cut-basis card, sharing the altitude term
- #7963 — the framing-to-cut card, which writes the Framing carry
- #6902, #7539 — context gathering across the hierarchy; the grouping tier above epic
- #8651, #8811 — in-flight sibling release pull requests
