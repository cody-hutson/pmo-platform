---
title: Release Plan — engineering-harness-pages-published (the process catalog's first universe, with the tools and definitions that generate and check it)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.08; the concrete number binds at the Stage-12 atomic claim)
milestone: engineering-harness-pages-published
release_class: cross-cutting
reversibility: MODERATE / Confidence MEDIUM — one branch, one pull request and one merge; every card is file additions plus bounded edits, so reverting the merge restores the prior tree. Two things are not reversible and are gated on their own: the first push of page text to a public remote, and a claimed version tag, which is retained and recorded, never deleted.
---
# Release Plan — `engineering-harness-pages-published`

**Milestone:** `engineering-harness-pages-published` (milestone 437), pages milestone 1 of 3. Nine cards, **#8554 to #8562**. The Stage-4 planning sub-task **#8845** carries the approved plan (`#8845 comment 6842832893`), the Mode R readiness briefing it adopted (`#8845 comment 6842432477`), the adopted re-review rows (`#8845 comment 6843432966`), the plan gate's Decision Recorded (`#8845 comment 6843433386`) and the amendments recorded at scope lock (`#8845 comment 6859695714`). The Stage-5 designs are on sub-tasks **#8846** (#8554), **#8850** (#8555), **#8854** (#8556), **#8858** (#8557), **#8862** (#8558), **#8866** (#8559), **#8870** (#8560) and **#8874** (#8561); each carries the two Collective Review records and the Collective Review 2 scope lock. This file is Engineering Commit 0, authored by the first Stage-6 Engineering spoke, on sub-task **#8851**.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.08`** (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/engineering-harness-pages-published`, cut from the default branch at `29c60404`; one pull request, opened in **draft**; one merge into `main`, **by merge commit** (§ Delivery Strategy).

**Concurrency posture:** **P0 fully serial** at Stage 6 (D-7). Stages 5, 7 and 8 run in waves. A force push is not used on the shared branch.

**Release class:** `cross-cutting`; engagement **Tight**; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8845 and is amended, in order, by: the plan gate's Decision Recorded (D-1 to D-8); the Collective Review record on the Stage-5 sub-tasks (CR-1 to CR-4, with its binding list and its owner table); the owners' Stage-5 revisions, where the later revision governs; the Collective Review 2 scope lock (CR2-0 to CR2-6, with ten conditions); and the amendments comment on #8845, placed section by section below. Where the Stage-4 plan and a later record differ, the later record wins, and § Deviation Log names each such change. Every thread comment consumed was authored by the repository owner (author association OWNER).

> **Public-surface rule for this release.** No output of this release names a person, a handle, an absolute machine path, an external program, the location or the file names of the drafted working set, a roadmap file, or an install-measured figure. Pages state what is measured and by which script. This file follows the same rule: it calls the input "the drafted working set" and gives no figure measured on an install.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a new capability — tools, a CI check and a document tree. The rule-computed next-free re-verified at Engineering Commit 0 is `v5.08` (§ Commit-0 Version Re-Verify Record). The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-13 (Friday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file), then plan step 2 (the definitions pack; the two registers) |
| **Branch** | `release/engineering-harness-pages-published` |
| **PR** | opened in **draft** by the hub after its scan of the first commits; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `engineering-harness-pages-published` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-12, domain: software }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal platform artifact, so no external body of practice is consumed. Dominant domain **`software`** (tools and a workflow); secondary domain `governance` (three standards, four stage specifications, the catalog pages). Transcribed unchanged from the Stage-4 plan (Phase A1.5). One Stage-5 note stands beside it: the definitions pack and the registers are data and documents with no code symbol, so their impact read was a search and not an import graph.

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `29c60404` (`29c604045def22ebd21fb4a758c3bb56be277b20`), the same commit the Stage-4 baseline pins. The release branch was cut from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 29c604045def22ebd21fb4a758c3bb56be277b20 --bump minor --dry-run` (no tag pushed) | **`v5.08`** (exit 0; "would claim v5.08 (no tag pushed)") — equal to the Stage-4 roster's inferred next minor after `v5.07` |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each saved to a file in the run directory and read by a python3 line scan
             that compares exact version tuples
Denominator: 468 ls-remote lines (228 distinct versions, the highest v5.07); 233 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             3,084 lines
Control - sensitivity: the same scan on the v5.07 slot reads 2 tag lines, 1 Release line and
             6 ledger lines. Every arm returns non-zero on a claimed slot
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality)
Extraction:  every line of the three reads, the ledger read from origin/main (never the
             worktree copy)
Result:      0 occupants of the (5,8) slot on every arm
Verdict:     CLEAN — v5.08 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** one sibling release is open — `release-usage-measured-right` (#8821, draft, minor, head `8974f500`). It recomputes next-free to the same `v5.08` slot. That is a Tier-S serialization point resolved by merge order and the atomic claim, not a HALT at this rung (§ Cross-PR Overlap Audit → In-Flight Release Roster).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp engineering-harness-pages-published`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder and does not reproduce it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-13`** (Friday). This release creates no date-bearing load-bearing identifier, so the value has no consumer beyond this record.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6).

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-1` to `CIAC-5`) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA) and the Commit-0 base | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Card | What it delivers | Size |
|---|---|---|
| #8554 | The decision record for where the catalog tools live (no tracked surface) | S |
| #8555 | The definitions pack, its machine-readable file and the four page templates | M |
| #8556 | The generator, the validator, the element inventory and their shared library, with fixtures and self-tests | XL |
| #8557 | The overlay command, the registered measures, the executed-evidence rules | XL |
| #8558 | The CI workflow with three checks, its declarations and its readers in the stage specifications | M |
| #8559 | The pre-landing pass, and the publication gate tool | M |
| #8560 | The 48 harness pages, the index, the graph and the views | XL |
| #8561 | Tracked homes for the working assets: the two registers now (limb a), the retire manifest and the GO evidence later (limb b) | M |
| #8562 | The exit checks on the merge commit | S |

Raw 68 points; effective 88 under `cross-cutting`, against a ceiling of 25. **Kept as one** by operator decision, re-affirmed at the Stage-4 gate: the tools, the definitions they check against and the pages they generate are one capability.

### Exclusions

- The browse view, and the second and third universes, stay out. No pull-forward.
- Page seeding is not carried in this milestone.
- The registered in-repo run-state home is not provisioned by this release; the overlay root is passed explicitly, with no installer edit.
- Held register rows and dropped register columns are not kept (CR2-5). The private-source pattern is not tracked (CR2-4).
- Two comparison rows on one page, and one measure, are held out of this release; a work item is filed at close (CR2-3, CR2-6).
- No new page for the harness tool added after the pages were verified (D-7).

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-12)

Plan approved with all eight decisions as recommended. `[MODERATE · confidence: MEDIUM]`

| # | Decision | Rendered |
|---|---|---|
| D-1 | Release Class | `cross-cutting` — engagement Tight, Stage 9 review Deep |
| D-2 | Tool home (#8554) | Beside the deploy tools, with this repository's paths as argument defaults and no path literal outside those defaults. No ADR |
| D-3 | Overlay home (#8557) | A narrowly ignored subfolder of the repository's run-state home, holding repository-scoped figures only |
| D-4 | Published registers | Controls register: rows sourced to a tracked file only; `tacit` rows and rows naming a private source are held back. ID registry: every row, with a page-less node treated as unpublished |
| D-5 | GO evidence | This file: pull-request-head results in § Verification Evidence; the merge-commit re-run in its Deployment Execution Log at close-out. Measured cost is recorded as measure and script; the figure stays in local run state. The retire manifest lives on #8561 |
| D-6 | Sizes and scripts | #8561 S → M; #8557 M → XL. Only measurement scripts that pass the placement admission test land; #8557 owns them and #8561's manifest gains a row for them |
| D-7 | Concurrency; the tool added after verification | Stage 6 fully serial. No new page: the tool joins an existing page's `depicts` list during re-verification if a page's activity runs it; otherwise a follow-up is filed at close |
| D-8 | CI gate at first ship (#8558) | A failing exit from first ship, on every pull request and on push to `main`, not registered as a required check; registration waits for a recorded specificity reading |

D-Version is a recorded determination: bump class `minor`; the number is the next-free at the Stage-12 claim.

### Collective Review (operator, 2026-11-13) — Adjust

| # | Decision |
|---|---|
| CR-1 | Adjust: seven designs revised on their sub-tasks; each revision followed by an adversarial review of the delta |
| CR-2 | CI gate posture, re-rendered: the failing exit from first ship stays, unregistered. A reader is named: a Stage 12 or Stage 13 read of the push-to-`main` run, repaired in the close-out pull request. Anchor-only rewrites get a stated scope status at Stages 7 and 8. A Tier 2 scope change: the stage-specification sentences join the File Change Matrix under #8558 |
| CR-3 | One required section of the activity page is renamed to a neutral title before first publication. #8555 owns the title; #8559 applies it in its scripted pass |
| CR-4 | The first push of page text is IRREVERSIBLE and takes an explicit operator sign-off inside Stage 6: the Engineering session returns one unpushed commit, the hub scans it, a fresh reader reads the final pages and generated files, the operator signs, then it is pushed |

**Binding on every revision.** *Register:* all nine host-configuration rows are held back; any row naming an operator-private source in any kept cell is held back; eight columns; a scripted export with no hand edits; the rule ships as a script that runs before the step-2 push and as a standing validator load check. *Tools:* the structure view and the `documented_by` index ship; the shared reader gains an additive function; an unknown cited control ID is a failure; a missing register is a not-evaluated exit. *Overlay and measures:* fixtures are synthetic only; the event-log population is defined by a positive host check with no repository name in the rule. *CI:* a third job runs the page validator. *Pages:* line numbers are stripped from citation labels and prose; a citation that conversion refuses is demoted to a whole-file link; zero-row view sections are omitted. *Release:* this plan declares a merge commit.

**Owners of the shared conventions** (one owner each; every other design adopts the owner's posted value): the published controls register and the ID registry → #8561 · the tool-side contracts, rule codes and exits → #8556 · the pack's content and rules table, the neutral section title → #8555 · the executed-evidence rule and measure inputs → #8557 · the CI workflow and its reader → #8558 · the pre-landing pass and the push gate → #8559 · the landing → #8560.

### Collective Review 2 (operator, 2026-11-13) — scope locked with conditions

| ID | Decision | Tier |
|---|---|---|
| CR2-0 | Lock with conditions. One hub-supplied scan expression serves both the pack scan and the publication gate; the two publication-gate repairs from the newest pre-landing review are added as gate rows in the commit that lands the gate tool and are graded at Stage 7; four closing addenda (pack, tools, CI, landing) are accepted without a paired adversarial review, with Stages 7 and 8 as the check | MODERATE |
| CR2-1 | Verdict rule for a page-wide `conformant`: every step must run, strict reading (a call whose job can only report not-evaluated credits nothing) | CHEAP before the first push |
| CR2-2 | The operator signs every pre-merge push that changes a page, a generated file or the catalog README | IRREVERSIBLE per push |
| CR2-3 | Two comparison rows on one page are held out of this release; a work item is filed at close. The roll-up of the page above it is re-assessed by hand | IRREVERSIBLE once pushed |
| CR2-4 | The private-source pattern stays untracked, with a privately compared digest. The operator places the file and its digest. The widening of an existing gate is not taken | CHEAP |
| CR2-5 | Held register rows and dropped columns are not kept | MODERATE |
| CR2-6 | Accepted as recommended: the neutral section title (**Step profile**); six registry columns; the four path-token rows dropped; the verdict-support rule as written; one measure held out of this milestone; a moved-only firing is `benign-shape`; the chip-pattern block is added; a citation no command repairs is a Warning at Stage 7; no lowered-value check in this milestone; the five further clauses in the design-artifact standard | CHEAP |

**Conditions carried into the Stage 6 briefs.**

1. One hub-held expression per scan class, given to every step that scans; the lists are read without regard to case or spacing.
2. Before the first push: the fetched commit is exactly one commit on the remote release head, and its signature state matches the branch's. Both are gate rows from the gate tool's commit on, and hub procedure until then.
3. The landing roll-up is restated for CR2-1 before the landing session starts.
4. The hub's read before each Stage 12 launch is checked against the CI contract's hold route; one hold-repair sub-task is opened before the first Stage 12 run.
5. Register: the README names the narrowed-range case; the digest is required whenever the pattern arm runs; the manifest count follows CR2-4.
6. Evidence: the strict reading of CR2-1; one rule for a step that names several mechanisms; the child's start and search path; the step counts of the `conformant` pages pinned.
7. Tools: the session that lands the tools runs the repository's reference gates over its own files before returning its commit; register scripts run with no repository-location variable set.
8. A requirement one contract places on another after that other's last revision is written into the receiving step's brief.
9. The clone used for page work is given the repository's commit identity and passes the gate tool's preflight before any commit is made in it.
10. Surface-register row IDs and the files a sibling release also edits are re-read against the default branch before each commit; this release takes the next free ID.

### Settled by the operator's decisions, or withdrawn by the owner

- The option to widen an existing gate is not taken (CR2-4). The one adjustment that depended on it was withdrawn by its owner and is not carried.
- The hand-workload sentence proposed in the first pre-landing design is not carried: its owner replaced that item and posted no successor sentence.
- A page-wide `conformant` follows the strict reading of CR2-1, and one measure is held out of this milestone (CR2-6). This file restates no count either decision may move.
- Integration acceptance criteria are not copied here; the owners reworded or added rows in their own Stage-5 outputs (sub-tasks #8854, #8858 and #8866).

---

## Dependency Graph

Native blocked-by edges, read at Stage 4: 24, acyclic, all inside the milestone. `A → B` reads "A blocks B".

```
#8554 → #8555 #8556 #8557 #8558 #8561 #8562
#8555 → #8556 #8559 #8560 #8562
#8556 → #8557 #8558 #8559 #8560 #8562
#8557 → #8559 #8560 #8562
#8558 → #8559 #8562
#8559 → #8560 #8562
#8560 → #8562
#8561 → #8562
```

Critical path (depth 6): #8554 → #8555 → #8556 → #8557 → #8559 → #8560 → #8562.

**Two edges the native graph does not carry:** the generator cannot run without the ID registry or the controls register, so #8561 is split in sequence into limb **a** (the two registers, landing with #8555) and limb **b** (the retire manifest and the GO evidence, landing late). The card, its criteria and its closure stay one.

**Cross-milestone edges.** Hard: none. The registered in-repo run-state home is not a prerequisite: the overlay root is passed explicitly.

---

## Implementation Sequence

Single branch `release/engineering-harness-pages-published`, one pull request, serial commits.

| Step | Card | What lands | Notes |
|---|---|---|---|
| 0 | — | Engineering Commit 0: this file | Commit-0 version re-verify and stamp-manifest assertion |
| 1 | #8554 | the decision record, as a comment on the card | no tracked file |
| 2 | #8555 + #8561a | the definitions pack, `pack.json`, four page templates; the ID registry and the controls register from the scripted export; one surface-register row for the private-source pattern and its digest | two commits, returned unpushed; the hub scans them with its own lists and pushes |
| 3 | #8556 | generator (with the impact query, the anchor-conversion command and re-resolution), validator, element inventory, shared library; the kinds table; fixtures; self-test registration; the standard's clauses; the pack's rules table and `rule_codes` | **owns the anchor-conversion command and the re-resolution logic (N-7)** |
| 4 | #8557 | the overlay command, the executed-evidence rules and their fixtures, the registered measures and the measures register, the surface-register row and one ignore rule | edits both pack files; adds its rule codes to the rules table and to `rule_codes` |
| 5 | #8558 | the workflow with three checks; the gate declarations, the gate-coverage rows; the stage-specification readers; the close-out tool's merge-wait guard; the chip-pattern block | on a catalog that holds no page, each of the three checks fails as not evaluated, by design |
| 6 | — | merge `main` | the sibling release first, where it has merged |
| 7a | #8559 | the publication gate tool's commit | read by the scan before its push. **The publication head is the release-branch head after plan step 7a, this card's tool commit** |
| 7b–7c | #8559 | the pre-landing pass: convert at the verification commit, re-resolve forward, re-verify, re-point pack links, rewrite evidence rows to measure-and-script form, apply the section rename, the README how-to-read note | the tool commit; then sessions in a clone with no remote, none of which pushes; the CR-4 hold between the gate and the push. The clone is given the repository's commit identity and passes the preflight before any session commits in it |
| 8 | #8560 | 48 pages at `status: ACTIVE`; the regenerated index, graph and views | flip and rebuild in the clone with no remote; the pushed commit is built beside the unpushed pre-landing commit and left on a local ref; no push by this step. The landing session passes the clone preflight before its first commit and compares its diff with the hub's manifest |
| 9 | #8561b | the retire manifest (on the card, 12 rows); pull-request-head GO evidence in § Verification Evidence | |
| 10 | #8562 | rehearsed on the pull-request head at Stages 7 and 8; run on the merge commit at Stage 12; recorded and marked closed at Stage 13 | the pull request references #8562 without a closing keyword |

**The signature rule (CR-4, as CR2-2 rules it).** The operator signs **every push that changes a page, a generated file or the catalog README**, before the merge. Each such push is one unpushed commit returned to the hub, scanned by the hub with its own term lists, read by a fresh reader, and signed. The push of page text is IRREVERSIBLE: a public remote keeps what it has received, and no later commit withdraws it.

**Stage 12, for this release.** Before each launch the hub brings the head up to the tip of the default branch and reads the Landing Contract's ten rows on it, unless it is the commit Stage 8 read; a repair it routes from that read is the release's one hold repair. Phase A.5.8 runs its check only (§ Delivery Strategy, Publication hold).

**When Stage 12 merges `main` again:** run the generator (it rewrites moved citations), run the impact query from the publication head to the new head, and re-verify only the pages it returns, moving their `last_verified_commit`. A non-empty return is a Tier 1 [ADJUST] recorded in § Deviation Log, not a re-plan. #8559's first criterion and all of #8562 are graded at that final head.

**The pre-landing workload, as Stage 4 measured it on the drafted pages** (at `29c60404`, 589 commits past the pages' verification commit): 435 bare line fragments across 50 cited files on 44 pages; 408 unique at the verification commit and convertible by tooling, 19 on repeated text, 8 blank-edged; of the 408, at the baseline head, 228 current, 175 moved, 4 gone, 1 ambiguous; 30 of 48 pages depict a file changed since verification. Each count is of the drafted pages and is re-read at the publication head.

### Agent-Editability Read

**Derivation** — controls read at commit `29c60404` (transcribed from the Stage-4 plan; the write-set classes are unchanged by the Stage-5 matrices, which add the stage specifications, one release tool and the bridge reference).

- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh`. Projected union inside the repository: any tracked file whose basename is `CLAUDE.md`, `OPERATIONS.md` or `RELEASE_PROTOCOL.md`.
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — a path under a module's `skills/<name>/` that is `SKILL.md` or a file under `references/`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| #8555, #8561a, #8559, #8560 | `core/process-catalog/**`; one tool file; one row of a standard | no | no | unconstrained | ordinary Engineering spoke |
| #8556 | `core/deploy/**`, `core/config/allowlists/**`, `core/standards/design-artifact-standard.md` | no | no | unconstrained | ordinary Engineering spoke |
| #8557 | `core/standards/**`, `core/deploy/**`, `core/process-catalog/**`, `.gitignore` | no | no | unconstrained | ordinary Engineering spoke |
| #8558 | `.github/workflows/**`, `core/standards/gate-efficacy-standard.md`, `release/references/pipeline/**`, `release/references/how-to/hub-spoke-bridge.md`, `release/tools/automated-closeout.sh` | no | no | unconstrained | ordinary Engineering spoke |
| #8554, #8562 | none | — | — | no write set | — |

Unconstrained means no control refuses the write, not that the change is ungoverned: the standards and the stage specifications are governed surfaces and ride this approved plan.

---

## Stage Applicability Matrix

| Card | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | Notes |
|---|---|---|---|---|---|
| #8554 | yes (the decision record) | no — no tracked surface | no | yes, read-graded | no ADR at MODERATE |
| #8555 | yes | yes | yes | yes | |
| #8556 | yes | yes | yes | yes | |
| #8557 | yes | yes | yes | yes | |
| #8558 | yes | yes | yes | yes | |
| #8559 | yes | yes | yes | yes | |
| #8560 | yes (class bias ALL) | yes | yes | yes | |
| #8561 | yes, light | yes (limbs a and b) | yes | yes | |
| #8562 | no — verification, no design | no — its record is written at close | yes, rehearsal on the pull-request head | yes, rehearsal | graded on the merge commit; marked closed at Stage 13 |

Stages 9 to 13 run at release scope for all nine. Plan Review depth: Deep.

---

## File Change Matrix

The rows are the owner contracts' final matrices, as the scope lock leaves them: **6 + 51 + 31 + 8 + 2 + 66 + 3 = 167 surfaces by owner count**, plus this file. The catalog README is counted once, under #8559. Two paths are counted by two owners each and appear once in the fence below: `core/standards/design-artifact-standard.md` (#8556 and #8560) and `core/standards/instance-data-placement-standard.md` (#8557 and #8561). The fence therefore holds 165 distinct surfaces and this file.

```
# ── #8555 (6) ──
ADD   core/process-catalog/definitions/definitions-pack.md
ADD   core/process-catalog/definitions/pack.json
ADD   core/process-catalog/definitions/templates/L0-universe.md
ADD   core/process-catalog/definitions/templates/L1-value-stream.md
ADD   core/process-catalog/definitions/templates/L2-sub-process.md
ADD   core/process-catalog/definitions/templates/L3-activity.md
# ── #8561 (3: 2 ADD, and 1 EDIT counted here and shared with #8557) ──
ADD   core/process-catalog/definitions/controls-register.tsv
ADD   core/process-catalog/definitions/id-registry.tsv
EDIT  core/standards/instance-data-placement-standard.md
# ── #8556 (51: 4 tool files, 1 definitions file, 40 fixture files, 6 edits) ──
ADD   core/deploy/tools/build-process-catalog.py
ADD   core/deploy/tools/check-process-catalog.py
ADD   core/deploy/tools/build-element-inventory.py
ADD   core/deploy/tools/_process_catalog.py
ADD   core/process-catalog/definitions/element-kinds.tsv
ADD   core/deploy/tools/fixtures/process-catalog/README.md
ADD   core/deploy/tools/fixtures/process-catalog/pack.json
ADD   core/deploy/tools/fixtures/process-catalog/element-kinds.tsv
ADD   core/deploy/tools/fixtures/process-catalog/id-registry.tsv
ADD   core/deploy/tools/fixtures/process-catalog/controls-register.tsv
ADD   core/deploy/tools/fixtures/process-catalog/controls-register-fail.tsv
ADD   core/deploy/tools/fixtures/process-catalog/private-pattern.txt
ADD   core/deploy/tools/fixtures/process-catalog/definitions-pack.md.txt
ADD   core/deploy/tools/fixtures/process-catalog/probe-source.yml.txt
ADD   core/deploy/tools/fixtures/process-catalog/pages/pass/*.md.txt
ADD   core/deploy/tools/fixtures/process-catalog/pages/fail/*.md.txt
ADD   core/deploy/tools/fixtures/process-catalog/sources/*.txt
EDIT  core/deploy/tools/README.md
EDIT  core/deploy/allowlists/selftest-coverage-manifest.txt
EDIT  core/deploy/allowlists/skip-tool-exec-mode-check.txt
EDIT  core/config/allowlists/script-execution-allowlist.txt
EDIT  core/deploy/tools/_frontmatter.py
EDIT  core/standards/design-artifact-standard.md
# ── #8557 (31: 8 measure files, 1 register, 20 fixture files, 2 edits; the placement standard is listed above) ──
ADD   core/deploy/tools/process-catalog-measures/workflow-run-history.py
ADD   core/deploy/tools/process-catalog-measures/secret-scan-range.py
ADD   core/deploy/tools/process-catalog-measures/flip-decision-rows.py
ADD   core/deploy/tools/process-catalog-measures/gate-rollout-deadlines.py
ADD   core/deploy/tools/process-catalog-measures/scheduled-audit-folders.py
ADD   core/deploy/tools/process-catalog-measures/event-log-population.py
ADD   core/deploy/tools/process-catalog-measures/event-log-deploy-status.py
ADD   core/deploy/tools/process-catalog-measures/event-log-deploy-replay.py
ADD   core/process-catalog/definitions/measures.tsv
ADD   core/deploy/tools/fixtures/process-catalog/measures.tsv
ADD   core/deploy/tools/fixtures/process-catalog/measures/fixture-count-rows.py.txt
ADD   core/deploy/tools/fixtures/process-catalog/measures/planted-measures.json
ADD   core/deploy/tools/fixtures/process-catalog/measure-cases/*.json
ADD   core/deploy/tools/fixtures/process-catalog/workflows/fixture-probe.yml.txt
ADD   core/deploy/tools/fixtures/process-catalog/workflows/fixture-other.yml.txt
EDIT  .gitignore
# ── #8558 (8: 1 ADD, 7 EDIT) ──
ADD   .github/workflows/process-catalog-check.yml
EDIT  core/standards/gate-efficacy-standard.md
EDIT  release/references/pipeline/stage-12-execute.md
EDIT  release/references/pipeline/stage-07-dev-testing.md
EDIT  release/references/pipeline/stage-08-qa-testing.md
EDIT  release/references/pipeline/stage-13-close.md
EDIT  release/tools/automated-closeout.sh
EDIT  release/references/how-to/hub-spoke-bridge.md
# ── #8559 (2) ──
EDIT  core/process-catalog/README.md
ADD   core/deploy/tools/check-process-catalog-publication.py
# ── #8560 (66: 63 ADD, 3 EDIT; the design-artifact standard is listed above) ──
ADD   core/process-catalog/engineering-harness/*.md
ADD   core/process-catalog/INDEX.md
ADD   core/process-catalog/graph.json
ADD   core/process-catalog/views/*.md
EDIT  release/references/pipeline/stage-02-triage.md
EDIT  release/references/pipeline/stage-05-solutioning.md
# ── this file ──
ADD   release/releases/plans/engineering-harness-pages-published_RELEASE_PLAN.md
```

**How the globs count.** #8556: `pages/pass/*.md.txt` is 7 files, `pages/fail/*.md.txt` is 22, `sources/*.txt` is 2; with the nine named fixture files that is 40. #8557 adds to the same fixture tree, and its files are counted under #8557, not #8556: one pass page (`fixture-activity-measured.md.txt`) and five fail pages (`fail-evidence-inline-figure`, `fail-evidence-verdict`, `fail-evidence-wording`, `fail-evidence-coverage`, `fail-evidence-coverage-none`, each `.md.txt`), and under `measure-cases/` eight case files (one per measure file, named by its stem) and `overlay-inputs.json`; with the fixture register, the two fixture sources and the two fixture workflow files that is 20. #8560: `engineering-harness/*.md` is 48 pages and `views/*.md` is 13 views. The generated surfaces are first written at step 7 by the pre-landing pass and stay counted under #8560, whose own step changes each page's `status` line and regenerates the rest.

**Edits to a file another card owns** (not counted again): #8557 adds to the generator, the library, the validator, both pack files and the L1 to L3 templates; #8558 adds to the two catalog tools and the tools README; #8559 adds to the tools README, the self-test coverage manifest and the script-execution allowlist; step 3 writes `rule_codes` into `pack.json` and the rules table into the pack document; six cards each contribute a section to the catalog README.

**CONDITIONAL rows.** None remain. The Stage-4 plan's conditional rows are resolved: the two stage-specification edits fire (#8560, one clause each); the measure scripts are in scope as the eight above; `.gitignore` fires (one rule); the four path-token and resolver rows are dropped (CR2-6); no installer edit is made.

#### Read-only inputs

- READ `core/deploy/tools/check-doc-links.py` and `core/deploy/allowlists/doc-link-target-paths.txt` (run, not edited).
- READ `core/ADRs/ADR-224-system-documentation-is-a-generated-process-catalog.md` (cited, not edited).
- READ the drafted working set: the pages, the tools, the pack, the registry and the controls register, outside the tracked tree. It has one writer and no stage of this release writes to it; Engineering copies from it into the release branch and edits the copies.

#### Release-wide explicit non-scope

- NOT EDITED `.github/workflows/release-tooling-smoke.yml` and `.github/workflows/operator-memory-ref.yml`: #8558 adds a new workflow file, and the widening of the memory-reference gate is not taken.
- NOT EDITED `docs/scripts/setup-workspace.sh`, `core/deploy/lib-instance-path.sh`, `core/standards/depersonalization-spec.md`, `core/config/operator.toml.template` and `core/config/operator-toml-schema.json`: the overlay takes no path token and no resolver (CR2-6).

**Mirror pairs:** none. No path above is in `mirror_pair_set()`.

**New-executable companion obligation.** The matrix adds no `*.sh`. The five Python tools take script-execution allowlist lines all the same, by their owners' contracts: four forms for each of the four #8556 files, and four for the publication gate tool — 20 lines for the release, in `core/config/allowlists/script-execution-allowlist.txt`. CI wiring: `.github/workflows/process-catalog-check.yml` runs the generator's check, the citation re-resolution and the page validator; the tools' self-tests are registered in `core/deploy/allowlists/selftest-coverage-manifest.txt`.

**Deliverable domain:** `software`, with `governance` secondary. **Deliverable state:** every row is a tracked corpus file with no propagation target, except the allowlist row, which the installer provisions (§ Operational Deployment Manifest).

---

## Contention Map

**Within the release** (single branch, so contention is ordering, not merge conflict):

| File | Cards | Resolution |
|---|---|---|
| `core/process-catalog/README.md` | #8555 #8556 #8557 #8558 #8559 #8561 | serial; one section per card, written under #8559 at step 7; the README never lists pages |
| the generator | #8556 (base, impact, conversion) · #8557 (overlay command) · #8558 (summary text and check arms) | serial in that order |
| the validator | #8556 · #8557 (the evidence rules) · #8558 (summary text, the depicted-file arm) | serial |
| the fixture folder | #8556 #8557 | additive |
| `pack.json` and the pack document | #8555 (create) · #8556 (`rule_codes`, the rules table) · #8557 (its codes, one link) | serial; each step that edits them runs the pack scan before its commit is returned |
| the 48 pages | #8559 (convert) · #8560 (land, `ACTIVE`) | consecutive steps |
| `core/standards/design-artifact-standard.md` | #8556 · #8560 | serial |
| `core/standards/instance-data-placement-standard.md` | #8561a (one row, step 2) · #8557 (one row and one line, step 4) | serial; each takes the next free row ID on the fetched default branch at its commit |

---

## Cross-PR Overlap Audit

### Baseline SHA

Stage-4 baseline: `29c60404` (`29c604045def22ebd21fb4a758c3bb56be277b20`). Commit-0 base: the same commit — `origin/main` had not moved when the branch was cut.

Population at Stage 4: open pull requests and remote `release/*` heads — one of each, the same release. Re-read at Commit 0: one open pull request (`gh pr list --state open --limit 100` returned 1).

| Shared file | This release | The sibling's hunks | Overlap class |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` | #8558: gate-coverage rows and a disposition row | four single-line hunks, one at the end of the gate-coverage table | line-range overlap at the table's tail |
| `core/standards/instance-data-placement-standard.md` | #8561a and #8557: one surface-register row each | one row appended at the register's tail | line-range overlap, **and an ID collision**: each would mint the next surface ID |
| `core/config/allowlists/script-execution-allowlist.txt` | #8556, #8559: allowlist forms per new tool | one insertion mid-file | append pattern |
| `.gitignore` | #8557: one rule | one insertion | line-range overlap if this release appends at the same place |
| `.github/workflows/release-tooling-smoke.yml` | none | nine hunks | avoided by design |

**Merge order:** the sibling first, then this release merges `main` at step 6 and re-reads its surface IDs. If this release reaches Stage 12 first, the sibling re-baselines the same tables; either order works, simultaneous does not. **Rule for this release (condition 10):** surface-register row IDs and the files the sibling also edits are re-read against the default branch before each commit.

### In-Flight Release Roster

**Measured at:** `29c60404` · Stage 4, and re-read at Commit 0 · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|
| `release-usage-measured-right` | #8821 (draft) | `8974f500` | minor | `v5.08` | the four files above |

A pinned measurement, no verdict. Both releases are `minor`, so both compute the same next-free slot: a version-slot serialization edge (Tier-S), settled by the atomic claim at whichever merge comes second.

### Structural sub-audit

Neither release declares a rename, a relocation or a delete. Structural (Tier-S): the version slot only.

---

## Risk Register

| # | Risk | Class | Severity | Owner | Mitigation |
|---|---|---|---|---|---|
| R-1 | Operator-private content reaches a public file through the controls register | scope / public surface | **High** | #8561, the hub | the scripted export holds a failing row whole; the register rules run before the step-2 push and at every validator load; the pattern arm runs privately with the holder's digest; no harness page cites a held control ID |
| R-2 | The measurement scripts the pages cite read install-wide data | scope | **High** | #8557 | only measures whose inputs any reader of the repository can reproduce are registered; a row that rests on an install-wide store carries a marker and supports no verdict |
| R-3 | The drafted tools are prototypes of a different layout | dependency | High | #8556 | every root is an argument with this repository's path as its default; a relocation arm runs each tool outside any repository |
| R-4 | The citation check fires on release pull requests that move cited text | cross-cutting | High | #8558 | a failing exit, unregistered; the failing summary names the one-command remedy; a named reader at Stages 12 and 13; a stated scope status for anchor-only rewrites |
| R-5 | Publication-head drift: the re-baseline grows with every merge to `main` | dependency | Medium | hub | the pinned head; the Stage 12 refresh rule in § Implementation Sequence; a short gap between GO and merge |
| R-6 | Unpublished universes leak into the output | scope | Medium | #8556, #8561 | the ID registry is published whole in six columns; a registered node with no page is treated as unpublished; zero-row view sections are omitted |
| R-7 | Non-page Markdown under the catalog folder is read as pages | contention | Medium | #8555, #8556 | page discovery is by registered universe folder; reserved folder names live in the tools; fixtures are kept as text files |
| R-8 | Sibling merge order: standards tables appended by both releases, with a surface-ID collision | contention | Medium | hub | merge order above; condition 10 |
| R-9 | Size: effective 88 against a ceiling of 25, landing more than 150 files in one pull request | scope | Medium | operator | kept as one by decision; Deep review; the generated files are reviewed through the generator |
| R-10 | Rollback after a branch-protection registration would leave a required context nothing reports | rollback | Medium | operator | D-8: no registration inside this release |
| R-11 | A null result read as clean | verification | Medium | Stages 7, 8 | every null carries its control arm; #8562 repeats each on the merge commit |
| R-12 | Measured cost cannot be assembled at close if stages do not record their draw | process | Low | hub | per-stage draw goes to the hub's local run state, never to a comment or a tracked file |
| R-13 | Page text, once pushed, cannot be withdrawn | public surface | **High** | operator, hub | CR-4 and CR2-2: one unpushed commit, the hub's scan, a fresh reader, the operator's signature, for every such push |

**Top five:** R-1, R-13, R-2, R-3, R-4.

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8556 × #8560 on `core/process-catalog/graph.json`):** no generated file is committed without the generator that produces it, and the committed index, graph and views equal a fresh run over the committed pages. *Method:* declared, verification deferred to #8556 AC-2, #8560 AC-3. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#8555 × #8559 × #8560 on `core/process-catalog/engineering-harness/check-backlog-hygiene.md`):** a published page that links the definitions pack links it at its tracked home. *Method:* `grep -c -F "](/core/process-catalog/definitions/pack.json" core/process-catalog/engineering-harness/check-backlog-hygiene.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#8555 × #8556 × #8561 on `core/process-catalog/definitions/pack.json`):** the pack's controls-register pointer names a tracked file, and the validator fails loud when that file is absent. *Method:* declared, verification deferred to #8555 AC-2, #8556 AC-4, #8561 AC-2. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#8557 × #8559 × #8560 on `core/process-catalog/engineering-harness`):** every executed-evidence row on a published page is in measure-and-script form, any script it cites is a tracked file, and no page carries an inline executed figure. *Method:* declared, verification deferred to #8557 AC-3, #8559 AC-1, #8560 AC-4. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#8558 × #8560 × #8562 on `.github/workflows/process-catalog-check.yml`):** the three catalog checks run on the pull request that lands the pages and report on the final head — at step 5 the three names are present, each failing, each summary reading NOT EVALUATED; after the pages land each passes with a non-zero examined count. *Method:* `grep -c -F "pull_request" .github/workflows/process-catalog-check.yml` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## Verification Plan

### Per-Issue Verification

**AC baseline:** read on the live card bodies at Engineering Commit 0, after the scope-lock adjustments — #8554 3 · #8555 4 · #8556 10 · #8557 6 · #8558 10 · #8559 7 · #8560 6 · #8561 3 · #8562 7 — **56 criteria** (44 at the Stage-4 read). One row per criterion; each card's own criterion text stays on the card.

`ac_baseline: { #8554: 3, #8555: 4, #8556: 10, #8557: 6, #8558: 10, #8559: 7, #8560: 6, #8561: 3, #8562: 7, read_at: 29c604045def22ebd21fb4a758c3bb56be277b20 }`

Each owner posted its changed verification rows under "Verification rows that change" on its Stage-5 sub-task; the latest revision governs. The rows below name the method the live criterion states and cite the owner for its detail: #8556 → sub-task #8854 (Revisions 1 to 4; where its row names three codes reading 0, read "`PCK001` and `PCK002` read 0 and no `R2` line is printed") · #8557 → sub-task #8858 (Revisions 1 to 3; the manual run in Revision 1's row for the fourth criterion is withdrawn) · #8558 → sub-task #8862 (Revisions 1 to 4) · #8559 → sub-task #8866 (Revisions 1 to 3) · #8560 → sub-task #8870 (Revision 1's table, as Revisions 2 and 3 change it) · #8561 → sub-task #8874 (Revisions 1 to 4).

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8554 | AC-1 | [DEFERRED — a named read of the decision comment on the card, graded at Stage 8] | chosen and rejected option, each with its retrofit cost |
| #8554 | AC-2 | [DEFERRED — the same read] | the cards whose scope changes are named, the adoption-profile epic among them |
| #8554 | AC-3 | [DEFERRED — a card-link read] | an ADR card only if the decision is EXPENSIVE or IRREVERSIBLE |
| #8555 | AC-1 | [DEFERRED — a name search over the tracked pack, schema and templates at Stage 7, the term supplied by the hub and never written into a tracked file or a comment; first run by the step-2 session before its commit is returned] | 0 · control: the same search over a control file → 1 |
| #8555 | AC-2 | [DEFERRED — a real load once the validator lands at step 3: the validator's registers-only command with the pattern arm not run, and the same command on a copy of the pack with one key removed] | exit 0 with both pack parity codes reading 0 and no register finding line; the copy exits as not evaluated, naming the key |
| #8555 | AC-3 | [DEFERRED — the depersonalization job on the pull request] | green |
| #8555 | AC-4 | [DEFERRED — a named read of the pack's sections and, from step 3, its rules table at Stage 8; the two parity links read clean, each with a failing arm] | cites decision 12 and § 13, restates neither |
| #8556 | AC-1 | [DEFERRED — the generator self-test and its emission-mutant arm, in CI and at Stage 7; plus, at Stage 7, one emit call deleted in a full copy of the tool folder] | pass; the mutant fails it, and the mutated copy exits 1 naming the arm while the unmutated copy exits 0 |
| #8556 | AC-2 | [DEFERRED — two generator runs and a diff at Stage 7, graded at a head where pages are present, or by the determinism arm; on an empty catalog the build stops as not evaluated] | byte-identical |
| #8556 | AC-3 | [DEFERRED — the impact arms of the self-test] | page and parent returned; 0 pages for an undepicted file · control: the depicted-file arm → at least 1 |
| #8556 | AC-4 | [DEFERRED — the validator self-test] | no failure on the good fixture; at least 1 on the broken one |
| #8556 | AC-5 | [DEFERRED — the behavioural single-reader arm of the self-test is the grader; a lexical search of the four tool files for a second frontmatter parser is a secondary signal] | 0 · control: the shared-reader import → 1 |
| #8556 | AC-6 | [DEFERRED — the stale-page fixture pair] | stale on the changed file; not stale on the unchanged one |
| #8556 | AC-7 | `grep -c -F "until the generator ships" core/standards/design-artifact-standard.md` expect 0 [READER-GRADED — the card's two other phrases also read 0 in § 13] | 0 · control: the same command on the release base → 1 (read at Stage 4; the other two phrases also read 1 each) |
| #8556 | AC-8 | [DEFERRED — the self-test's conversion and demotion arms, in a temporary repository whose cited file differs between its two commits] | the anchor is computed at the page's verification commit; a refused citation is demoted and listed; a citation whose path is absent at that commit fails the run; a page with no bare fragment is byte-identical |
| #8556 | AC-9 | [DEFERRED — the self-test's repeated-line fixture pair] | repeated text is refused by conversion and read ambiguous by re-resolution; unique text converts and reads current |
| #8556 | AC-10 | [DEFERRED — the relocation arm of each tool's self-test] | exit 0 outside any repository with every root passed, and no default path in the output; an omitted required root exits as not evaluated, naming it |
| #8557 | AC-1 | [DEFERRED — the overlay command run with its root passed, then an ignore check on the written path, at Stage 7] | the path is reported ignored |
| #8557 | AC-2 | [DEFERRED — the inline-figure fixture pair in the validator self-test] | fail on the inline figure; pass on the measure-and-script form |
| #8557 | AC-3 | [DEFERRED — the validator over the catalog] | no finding of that rule · control: the failing fixture of AC-2 |
| #8557 | AC-4 | [DEFERRED — the generator's self-test: the measure-case, decoy-install, source-check and runtime arms, in a clean room with synthetic fixtures] | each registered measure's report equals its literal expected text; a second run is byte-identical; the decoy is not read; a planted measure reading outside what it was handed fails |
| #8557 | AC-5 | [DEFERRED — the validator's self-test: the verdict fixture pair and the coverage fixtures] | a verdict with no supporting row fails and the same page with one passes; short coverage fails with its reason; a clause on a row with no linked workflow, or with a workflow that is not an input, fails |
| #8557 | AC-6 | [DEFERRED — the generator's self-test: the source-check, runtime and measure-case arms] | a measure outside the closed lists fails the register load naming the rule; one inside loads and runs; each case gives the same report under two hash seeds |
| #8558 | AC-1 | [DEFERRED — the job's self-test fixtures, in CI] | fail on a hand-edited generated file; pass on an untouched catalog |
| #8558 | AC-2 | [DEFERRED — the generator self-test's arms G3 and G3b] | fail on a frontmatter edit the output carries without regeneration; pass on an edit to `last_verified_commit` alone |
| #8558 | AC-3 | [DEFERRED — fixture runs] | fail on a deleted and on a moved cited line; pass after regeneration |
| #8558 | AC-4 | [DEFERRED — a fixture run] | 0 findings on an uncited-line edit · control: the AC-3 arms |
| #8558 | AC-5 | [DEFERRED — a read of a failing run summary at Stage 8] | reports on every pull request and on push to `main`; the summary names the remedy |
| #8558 | AC-6 | [DEFERRED — the validator self-test's depicted-file arm] | fail when a depicted file is deleted; pass when nothing a page depicts or cites changes |
| #8558 | AC-7 | [DEFERRED — arm G8, and the two check listings on the release pull request] | each of the three checks fails as not evaluated when no page is discovered, and passes where pages are present and clean |
| #8558 | AC-8 | [DEFERRED — a read of the Stage 12 specification, the gate-coverage register and this release's Stage 12 output] | Phase A.5.8 and the Phase B1.2 block are specified, registered and recorded with each command's exit |
| #8558 | AC-9 | [DEFERRED — the self-test arm for the sources-changed read, and this release's own Stage 7 output] | an edited cited text is listed; a moved-only text lists nothing |
| #8558 | AC-10 | [DEFERRED — the close-out self-test's group 4e arms (k) and (j)] | a wait ending on a failing not-required check names it; a wait ending on pending required checks reads as before |
| #8559 | AC-1 | [DEFERRED — the staleness command with its fail-on-any option and the impact query from each page's `last_verified_commit` to the head, graded at the pull-request head at Stage 8] | exit 0 and no page · control: the impact query from the verification commit returns at least 38 pages |
| #8559 | AC-2 | [DEFERRED — the re-resolution check over the pages] | 0 findings · control: a planted bare fragment → 1 |
| #8559 | AC-3 | [DEFERRED — the publication gate's probe command at the head, classes `ws-name`, `ws-path` and `untracked-root-link`] | each 0 · control: the drafted pages read their pinned non-zero counts |
| #8559 | AC-4 | [DEFERRED — a named read of the README at Stage 8] | the how-to-read note is present; no page is listed |
| #8559 | AC-5 | [DEFERRED — a tracked-file count for the unmatched listing under the catalog] | 0 |
| #8559 | AC-6 | [DEFERRED — the validator's label and prose line-reference findings and the probe classes `line-label` and `line-prose`] | each 0 · control: the drafted pages |
| #8559 | AC-7 | [DEFERRED — a log read of the commits that added the harness pages on the remote release branch, and existence reads in a fresh clone] | one ID, equal to the signed ID; the pre-flip commit and the work branch's first commit are on no remote ref · control: the same log read for the catalog README prints a different ID |
| #8560 | AC-1 | [DEFERRED — the folder listing against the harness rows of the registry] | no missing and no extra page (48) |
| #8560 | AC-2 | [DEFERRED — a frontmatter read through the shared reader] | 48 of 48 `ACTIVE` |
| #8560 | AC-3 | [DEFERRED — two generator runs and a diff] | byte-identical |
| #8560 | AC-4 | [DEFERRED — the validator over the catalog] | no failure · control: #8562 AC-1's planted page |
| #8560 | AC-5 | [DEFERRED — the link checker over the catalog, requiring targets] | 0 findings · control: a planted dead link → 1 |
| #8560 | AC-6 | [DEFERRED — the impact query on a one-file diff] | at least 1 page; 0 for an undepicted file |
| #8561 | AC-1 | [DEFERRED — a named read of the manifest comment on the card] | 12 rows, each with a home and a promoting milestone; no row writes the name of a file that is not tracked. The card's criterion still counts eleven: the twelfth row follows CR2-4 and the count is the hub's to reconcile on the card |
| #8561 | AC-2 | [DEFERRED — page filename stems against the registry] | no unregistered page · control: a planted stem → 1 |
| #8561 | AC-3 | [DEFERRED — two scans over the evidence path] | 0 · control: a planted name → 1 |
| #8562 | AC-1 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | the validator reads no failure; at least 1 on a planted page |
| #8562 | AC-2 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | the generator self-test passes |
| #8562 | AC-3 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | two runs identical to each other and to the committed output |
| #8562 | AC-4 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | 0 link findings · control: a planted dead link → 1 |
| #8562 | AC-5 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | both scans clean · control: a planted name → 1 |
| #8562 | AC-6 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | the catalog checks green on the merge commit |
| #8562 | AC-7 | [DEFERRED — run on the merge commit at Stage 12 and recorded at Stage 13; rehearsed on the pull-request head at Stages 7 and 8] | the measure and its script recorded; the figure kept in local run state |

**The pack scan, at every push of this release.** Before any step's commit is returned, the step runs the scan the Pack Contract defines (its Addendum 2: rules S-1 to S-10 and the class-by-file-group table), with one hub-held expression per class. The hub re-runs it with its own lists before the push. Until the publication gate tool is tracked the hub runs the same ten rules from a private script; from then on the tool is the only implementation.

### Release-Level Verification

| Check | Method | Expected |
|---|---|---|
| Corpus checks | `bash core/deploy/deploy.sh --check` | exit 0 |
| Reference gates over each step's own files | [DEFERRED — the repository's PR-time checkers, run locally by each Engineering session before its commit is returned and in CI on the pull request] | no finding |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential, posture **P0** at Stage 6; waves at Stages 5, 7 and 8 |
| Commit strategy | Commit 0 (this file) → step 2 in two commits (the pack; the registers and one surface-register row) → one or more commits per later step. Every Engineering session returns its commits unpushed; the hub scans and pushes |
| Review approach | One pull request for the milestone. Topology **SINGLE**. Draft until the Stage-9 gate. Title `release(engineering-harness-pages-published): …`. The Issue References block carries a closing keyword for #8554 to #8561 and a plain reference for #8562 |
| Merge method | **`merge`** — the release merges by merge commit, declared at Commit 0. #8559's seventh criterion and the publication gate read commit IDs on the release branch, which a squash would replace |
| Rebase | None on the shared branch. If `main` advances, merge `origin/main` (step 6, and again at Stage 12 under the refresh rule) |
| Publication hold | **Publication hold — yes.** Phase A.5.8 runs its check only; a repair before the merge is routed by the hub and pushed under the pre-landing later-push rule |
| Signature | The operator signs every push that changes a page, a generated file or the catalog README (§ Implementation Sequence) |
| Deployment mechanism | Git merge. No skill package changes. The script-execution allowlist reaches a workspace through the installer's hook-tier provisioning (§ Operational Deployment Manifest) |
| Stacked-base cleanup | N/A under SINGLE |

**Where each stage records its draw.** Per-stage draw is an install-measured figure, so it goes to the hub's local run state, never to a sub-task comment or a tracked file. The close-out figure is assembled from the usage extractor's per-release row; this file records only what was measured and by which script (D-5).

---

## Rollback Strategy

- **Per card.** Every card is file additions plus bounded edits; a revert of its commits restores the prior state. #8560's generated output reverts with its pages. Partial ship is not safe after step 3: the tools read the pack.
- **Whole release.** Revert the merge; the version tag is retained and the rollback recorded. One residue outside git: the overlay's local content, which is harmless and local. No required context is registered by this release, so a revert leaves no context that nothing reports.
- **What a revert does not undo.** Page text and register rows that reached the public remote stay in its history. That is why each such push is signed first.

---

## Quota Budget

**Verdict:** WARN `[ASSUMPTION – CONFIRM]` (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 8 · Stage 7: 8 · Stage 8: 9
**Per-spoke cost estimate:** ordinal band by size label — three `highest` (XL); four `low–moderate` (M); the rest `lowest` (source: heuristic; no bucket is superseded by telemetry in this plan)
**Assumed/stated remaining usage-window envelope:** `UNSTATED` — conservative default applied; no figure is synthesized
**Estimated cumulative draw % (worst parallel batch):** not rendered — the basis is `UNSTATED`
**Routing:** WARN: window-aware timing and split batches. Recommended wave width 3 to 4, the XL cards in different waves.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — and is the load-bearing gate.

---

## Release Class declaration

- **Class: `cross-cutting`** (D-1). Trigger (c) fires on 24 in-bundle edges; triggers (a) and (b) do not fire on the Stage-4 matrix. The substance agrees: a repository-wide CI check, a new non-tracked surface, standards edited, and a sibling to sequence. The Stage-5 matrices add four stage-specification edits under #8558 and two under #8560 (the Tier 2 scope change of CR-2), which does not lower the class.
- **Posture:** engagement Tight · Stage 9 **Deep** · Stage 5 bias **ALL** · Stage 13 outcome window 30-day.
- **Size:** raw 68, effective 88; kept as one with rationale.

---

## Release Outcome Statement

**AFTER** — The process catalog at `core/process-catalog/` holds its first universe, the engineering harness (hooks, deploy checks, CI gates and the tooling that runs them): one page per node, the generated index, graph and views, and the generator and validator that produce and check them. A pull request that changes generated output without regenerating it, or that moves text a page cites, fails CI. Pages state what they measure and which script measures it; the figures themselves are generated per install into a git-ignored overlay. Planning reads current-state pages for harness changes instead of reading "the catalog holds no pages yet".

**BEFORE** — ADR-224 and the design-artifact standard's § 13 define the catalog, but `core/process-catalog/` holds only its README. The pages, the generator, the validator and the definitions they check against exist only as a working set outside the tracked tree, so nothing on main can generate, check or cite a page.

**Actor(s):** operator; planning, engineering and close-out agents.

**Success Indicator:** the milestone's exit-check card reads every check met on the merge commit: the validator passing the published pages, the generator's self-test passing, two regenerations identical, every link resolving at the published location, the depersonalization and project-name scans clean, and the catalog checks green.

**Limb owners:** harness pages, index, graph and views in the catalog → #8560 · generator and validator → #8556 · the definitions they check against → #8555 · CI fails un-regenerated output or a moved citation → #8558 · per-install figures in a git-ignored overlay → #8557 · planning reads current-state harness pages → #8560

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/config/allowlists/script-execution-allowlist.txt` — `surfaces:` the script-execution allowlist, 20 added lines for the five catalog tools | the workspace's provisioned copy of that allowlist | the installer's hook-tier provisioning, operator-run after the merge and the primary's fast-forward | the provisioned copy carries the 20 lines; a catalog tool runs agent-side without a guard refusal |

No skill is deployed, no mirror member changes, and no hook file changes.

### Schema Migrations

N/A — enumerated over the classes {data-schema change, frontmatter-schema change, config-key change, log-record shape change}. One new machine-read file is added (`core/process-catalog/definitions/pack.json`) and no existing schema changes; no operator configuration key is added (the path-token rows are dropped).

### Memory Evictions

N/A — enumerated over the classes {memory eviction, memory re-point}; none present in this release.

---

## Deviation Log

| ID | Stage | Deviation | Basis |
|---|---|---|---|
| DEV-1 | 6 (Commit 0) | The File Change Matrix is the owners' final matrices (167 surfaces by owner count), replacing the Stage-4 plan's range of 108 to 151. The conditional rows are resolved | the amendments comment on #8845; the Collective Review 2 scope lock |
| DEV-2 | 6 (Commit 0) | The AC baseline is 56 criteria, not the Stage-4 read's 44: #8556 gained three, #8557 two, #8558 five and #8559 two at scope lock. The Verification Plan carries one row for each | the scope-lock adjustment comments on the cards |
| DEV-3 | 6 (Commit 0) | This file carries sections the Stage-4 comment did not title: § Delivery Strategy (with the merge method, the publication hold and the signature row), § Operational Deployment Manifest (with the allowlist `surfaces:` row), § Release Outcome Statement and § Deviation Log. Each amendment is placed in the standard section the stage specifications expect, as the amendments comment leaves the hub and this file to do | the amendments comment on #8845; the release-plan template |
| DEV-4 | 6 (Commit 0) | The publication head is redefined: the release-branch head after plan step 7a, replacing "the release branch's last merge of `main` before plan review". Step 7 is split into 7a and 7b–7c | sub-task #8866, Revision 2 |
| DEV-5 | 6 (Commit 0) | Three method notes the owners left for the plan and the card bodies do not carry are placed in the Verification Plan: #8556's method restatements for criteria 1, 2 and 5; #8559's first-criterion method; and #8561's twelve-row manifest reading. #8557's fixture paths, which its card adjustment left to the plan, are in the File Change Matrix | the scope-lock adjustment comments on #8556, #8557, #8559 and #8561 |
| DEV-6 | 6 (Commit 0) | CIAC-5's expected state is reworded to the CI owner's "5, reporting" row; its method stands. CIAC-1 to CIAC-4 are carried as the Stage-4 plan wrote them, with the two measured counts in CIAC-2 left on the plan comment | sub-task #8862, Revision 2 |
| DEV-7 | 6 (Commit 0) | The two re-review instrumentation rows this plan owes (the Stage-4 re-review row; #8555's Phase 0.5 row: 6 rows, 4 C1, 2 C2, 0 C3) are not written by this commit. The re-review standard names an operator-instance file for them, outside the tracked tree, which an Engineering session does not write. The rows are returned to the hub | `release/references/standards/triage-design-rereview.md` § 8 |
| DEV-8 | 6 (Commit 0) | #8561's limb a carries one EDIT the Stage-4 plan did not list: one surface-register row in the placement standard, for the private-source pattern and its digest | sub-task #8874, Revision 4; CR2-4 |
| DEV-9 | 6 (Commit 0) | This file was committed with the plan verifier exiting 3, where the Stage-6 brief asked for exit 0. Exit 0 is not reachable at Commit 0 for a release whose files land in later commits: the verifier grades the matrix's ADDs, one live per-issue row and two live cross-issue rows against a tree that does not yet hold their subjects. The two Commit-0 rungs the bridge defines both pass (the version half and the stamp manifest), and so does the stage-06 A1 lint. The commit stays local and unpushed; whether the gate before the push is the two rungs or the full verifier is returned to the hub | § Verification Evidence; `release/references/how-to/hub-spoke-bridge.md` Procedure 0, steps 1 to 3b |

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

- **Version re-verify:** PROCEED at `v5.08` (§ Commit-0 Version Re-Verify Record).
- **Stamp manifest (step 3b):** `release/tools/claim-version.sh --verify-stamp engineering-harness-pages-published`, run after this file was written and before it was committed → exit 0, "verify-stamp OK — … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))".
- **CIAC authoring lint (stage-06 A1):** `release/tools/verify-release-plan.sh --ciac-lint` on this file → exit 0, `CIAC-LINT-SUMMARY declared=5 parsed=5 clean=2 declared-deferral=3 flagged=0`.
- **Plan verifier — exit 3 at Commit 0, not 0 (DEV-9).** `release/tools/verify-release-plan.sh`, run on this file before the commit with the Stage-4 comment supplied for the provenance delta. Read by record:
  - provenance-survival: 4 of 4 PASS (label present, grammar conformant as Form X, no loss against the Stage-4 comment).
  - declared deferrals: 55 per-issue rows and 3 cross-issue criteria read SKIP, as declared.
  - per-issue: 1 FAIL — #8556 AC-7, whose phrase leaves the standard at step 3; its own expected cell records that the release base reads 1.
  - integration: 2 ERROR — CIAC-2 and CIAC-5; each names a file a later step adds (a page at step 7, the workflow at step 5), so the matcher has no file to read.
  - fcm-delivery: 47 FAIL, one for each unconditional ADD of the matrix, this file among them; none had been committed when the verifier ran. The coverage record reads `declared=65 interpreted=64 obligations=47 uninterpreted=1 pathless=0`. The one uninterpreted row is `EDIT .gitignore`: the recogniser reads no repository-root file, so the row is declared and cannot be interpreted.
  - the Release-Level corpus check was not part of that run; it is run once, directly, on the step-2 head, and its result is in the Stage-6 output comment on sub-task #8851.
  Every non-pass above traces to a file that a later commit of this release delivers, or to the recogniser limit named. No row was rewritten to make the exit 0.
- **ADR index:** N/A — this release adds no decision record.
