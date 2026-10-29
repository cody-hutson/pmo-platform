---
title: Release Plan — governance-obligations-measured (Declared obligations are measured at close)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.81; the concrete number binds at the Stage-12 atomic claim)
milestone: governance-obligations-measured
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH — additive edits to tracked governance, schema, standard, discipline and pipeline files, one new sentinel, one new ADR and additive check arms in two engines, on one branch with one merge, so reverting the merge restores main byte-for-byte. Every new gate ships warn-mode, so no gate blocks on revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `governance-obligations-measured`

**Milestone:** `governance-obligations-measured` (milestone 347). The Stage-4 planning sub-task **#8577** carries the approved plan and the Stage-4 gate's Decision Recorded. The Stage-5 designs and their independent adversarial reviews are on **#8578** (#4919), **#8582** (#5286), **#8586** (#5062) and **#8590** (#4417); the Collective Review scope-lock Decision Recorded is on **#8582**. This file is Engineering Commit 0, authored by the first Stage-6 spoke on **#8579** (#4919).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.81`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/governance-obligations-measured`, one pull request opened in **draft** after the first card lands, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — #4919 → #5286 → #5062 → #4417, one Engineering spoke at a time, each syncing `origin/main` before it starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `cross-cutting` — re-classified from `novel` at the Stage-4 gate; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8577 and is amended by four records, in order: the Stage-4 Decision Recorded on #8577 (plan approved; cross-cutting; #4444 removed; D-DocImpact crisped; D-4919-Routing to #5903; P0; SINGLE; minor), the four Stage-5 designs, their four Phase A6.5 adversarial reviews, and the Collective Review scope-lock Decision Recorded on #8582 (scope hard-locked through Stage 9; the A6.5 remedies folded into Stage 6 as instructions; the three matrix-cascade gates rendered (A); #5286's CD-1 adopted; D-5062-Posture (A′) with a recorded override). Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): protocol text added and modified, per the Bump-Class Selection Guide. Provisional display `v4.81`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092). It rises to major only if a card selects a skill behavioural change, and none does |
| **Date Created** | 2026-10-29 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Commit 0, #4919 and #5286 landed; #5062, #4417 follow in serial order |
| **Branch** | `release/governance-obligations-measured` |
| **PR** | #8599 — opened in **draft** at Stage 6 Phase C2 after #4919's slice; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `governance-obligations-measured` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-28, domain: governance }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform governance, schema, standard, discipline, pipeline-spec or deploy-tooling artifact, so no external body of practice is consumed. Dominant domain **`governance`**; secondary domain software (the `deploy.sh` and Python engine arms). Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `b1aaa77e` (`b1aaa77e9210a5c70d0e31cce885ddbc4aae3720`), equal to the Stage-4 baseline pin. The release branch was cut from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha b1aaa77e9210a5c70d0e31cce885ddbc4aae3720 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v4.81`** (exit 0; "would claim v4.81 (no tag pushed)") — equal to the planned display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan that compares exact version tuples
Denominator: 450 ls-remote lines (226 distinct versions); 224 published Releases (under the
             5000 limit, so not truncated); the ledger at origin/main, 2,871 lines
Control - sensitivity: the same scan on the v4.80.1 slot — 2 tag lines, 2 Release lines and
             10 ledger lines. Every arm returns non-zero, so a zero on the v4.81 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality,
             so v4.8.1 and v4.810 are different tuples, not prefixes)
Extraction:  26,350 bytes of ls-remote output, 22,283 bytes of Release list and 924,883 bytes
             of ledger read from origin/main (never the worktree copy)
Result:      0 occupants of the (4,81) slot on every arm; the highest claimed tag is v4.80.1
Verdict:     CLEAN — v4.81 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** none. 0 open pull requests and 0 remote `release/*` heads other than this release's own (§ Cross-PR Overlap Audit → In-Flight Release Roster).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp governance-obligations-measured`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-10-29`** (Thursday). Every later card that writes a date-bearing identifier consumes this value and writes no other literal: #5286's `GCL10_ROLLOUT_ARMED`, its `LIMB_OWNERS_REQUIRED_FROM` and its ADR `date:`; #4417's `CLOSEOUT_ANCHOR_ROLLOUT_ARMED` and its `date-variable-convention.md` Version History date. #4919's edits carry no date.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-4` | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as Stage 5 resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, which is also the Commit-0 base) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Title | Disposition |
|---|---|---|---|
| #4919 | P3 | Verification-by-declaration: the platform accepts a control's artifact as evidence the control acted (the class card) | carried; Stage-5 design on #8578 with the A6.5 remedies CD1, CD2, CD3 and PR-1 |
| #5286 | P2 | Declared obligations ship with zero conformance and no owner, and close-out never measures them | carried; Stage-5 design on #8582 with PR-1, FM-2..FM-6 and the adopted CD-1 |
| #5062 | P3 | Documentation Impact was absent on a shipped card, and nothing upstream of Stage 13 asserts the field's presence | carried, narrowed per the operator render of 2026-10-28; Stage-5 design on #8586 with CD-5, PR-2, FM-2, FM-3 and FM-5 |
| #4417 | P3 | CHANGELOG and RELEASE_DIGEST both declare the close-out anchor but nothing checks they agree | carried; Stage-5 design on #8590 with CD-1, CD-2, CD-3, FM-4 and FM-5 |

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| #4444 — Design-Principle Conformance forced at render time | At the cross-cutting weight the five-card bundle measured 22 × 1.3 = 29 against the 25-point ceiling; #4444 is the only member whose fix lives on the D-Gate rendering surface | the approved backlog under epic #5867 (`[BUNDLE AMENDMENT]` on #8577) |
| #4919's open question — must a release plan's verification-row control arm be subject-discriminating? | D-4919-Routing (A): it concerns the plan-authoring standard, not this release's gate surfaces, and the bundle is at its band ceiling | #5903, as an evidence comment; #7899 named there as the mechanical consumer |
| #4179's Documentation Impact back-fill (#5062 AC-1/AC-2) | Operator render of 2026-10-28: out of scope under G-CL8's issue-scope rule; the warn entry stands; the back-fill branch is dropped | recorded here (§ Deviation Log DEV-2) |
| The note-date writer defect behind the three resident close-out anchor divergences (#4417) | D-ResidentFindings (A): ship warn-mode with v4.24, v4.43 and v4.45 resident | #4327, as evidence |
| G-CL8's drain trigger and the H2-heading class (#5062 F-1, F-2) | outside #5062's narrowed scope | #8114, as evidence (Row L ownership names the population `doc-impact-gradable-in-bundled`) |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-10-28)

| Decision | Rendered |
|---|---|
| Plan + Release Outcome Statement | **Approved**: four limbs, each naming its owning card; now the `### Release Outcome Statement` H3 of the milestone description |
| D-ReleaseClass | **Cross-cutting; #4444 leaves the milestone** for the approved backlog under epic #5867. 18 × 1.3 = 23, in band |
| D-DocImpact | **Crisp before Stage 5.** #4919's Documentation Impact heading lost its DRAFT suffix; #4417's prose became one `path \| action \| reason` row. Both read PASS under `check-doc-gates.py`'s `eval_issue` (before: OUT-OF-SCOPE and FAIL) |
| D-4919-Routing | **To #5903**, as an evidence comment; #7899 named there as the mechanical consumer |
| D-Concurrency | **P0**, fully serial |
| D-C Branch Topology | **SINGLE**, `release/governance-obligations-measured` |
| D-Version | A recorded determination, not a gate: minor, provisional `v4.81`, re-verified at Engineering Commit 0 (above) and bound at the Stage-12 claim |
| Carried | #5062 narrowed per the 2026-10-28 Mode R render. GitHub write rule for this run: pipeline records post under the gate that authorizes them; any other write is shown to the operator as exact text first |

### Collective Review scope-lock (operator, 2026-10-29)

| Decision | Rendered |
|---|---|
| Scope-lock | **Approved.** Scope hard-locked through Stage 9; Engineering authorized |
| Phase A6.5 remedies | **Folded into Stage 6 as instructions.** #4919: CD1, CD2, CD3, PR-1. #4417: CD-1, CD-2, CD-3, FM-4, FM-5. #5062: CD-5, PR-2, FM-2, FM-3, FM-5. #5286: PR-1 and the FM-2..FM-6 refinements |
| D-5286-MatrixCascade | **(A)** all 7 paths: the sentinel, the ADR, `gate-evaluation-spec.md`, two paragraphs of `release-process.md`, `stage-03-bundle.md`, `bundle-composition-doctrine.md` and the tools README |
| D-5062-MatrixCascade | **(A)** all 4 paths: `bundle-issues-parser.py`, `field-lifecycle-matrix.md`, `release-process.md` (its G3 field-list paragraph) and the tools README |
| D-DocImpactScope | **(A)** #4417's Documentation Impact gains three `update` rows (body edited; reads PASS under `eval_issue`) |
| D-ResidentFindings | **(A)** ship warn-mode with v4.24, v4.43 and v4.45 resident; the note-date writer defect routed to #4327 |
| #5286 CD-1 | **Adopted.** `probe: none` is removed from the `**Population:**` grammar: an obligation no instrument can measure is enumerated by hand census (the § *Population shortfall* census form), and an owner is valid only when its body or comments name the population; close-out posts the record there. #4919's register row therefore carries a census definition |
| D-5062-Posture | **(A′)** G3-20 blocks cards not yet `status: bundled`; on a re-bundle, already-bundled cards are advisory; one read-only parser pass over the approved queue runs before the next bundle session. Override recorded for the N-way posture row (§ Deviation Log DEV-3) |
| N-way consistency | Aligned: the `G-CL10` identifier, the single v2.22 schema entry, the one Documentation Impact grammar, the register segment grammar. Resolved: `runner-def` (not `runner-src`) per #4417's CD-2. Overridden: new-gate initial posture |

---

## Dependency Graph

```
native edges (GraphQL blockedBy): 0 on all four cards
parents: #5867 (#5286, #4919) · #8114 (#5062) · #6428 (#4417)
soft / compositional (order the work, block nothing):
  #4919 -> #5286   G-PR4 names G-CL10 and G-CL10 names G-PR4 (CIAC-2); #5286 cites #4919's class
  #4919 -> #4417   the new check's falsification fixture applies the observed-acting rule
  #4919 -> #5062   G3-20's register row states where its control is observed acting
  #5286 -> #5062   #5062's live G3-20 row carries the Population segment #5286's grammar parses
  #5062 -> Stage 13 of this release: AC-4 counts the g-cl8 rows this release's own close writes
cross-milestone (Tier-B soft / file-contention; none in flight):
  ms#398 stage-assertions-reconcile   #5903 extends review-discipline § 8 (PV-2f is taken)
  ms#400 obligation-runners-declared  #6225..#6227 edit the gate-efficacy register
  ms#421 plan-verifier-never-passes-unread-rows   #7899 reads the Expected column
```

---

## Implementation Sequence

Single branch `release/governance-obligations-measured`, posture **P0 (fully serial)**. Each card is its own Stage-6 spoke, syncs `origin/main` first, and pushes each coherent slice on landing.

| Step | Card | Size | Why here | Key edits (as Stage 5 resolved them) |
|---|---|---|---|---|
| **0** | Commit 0 | — | Plan file, carrying the Commit-0 Survival Set | this file |
| **1** | #4919 | M | Names the class every later card's falsification practises | review-discipline § 8 rider **PV-2f** · stage-09 **Phase A4** (control census line, observed-acting lines with an independent second observation, the release learning bound inline) · **G-PR4** refined in place naming `G-CL10`, its self-repair, and the release's single **v2.22** schema entry · `gate-evaluation-spec.md` G-PR4 judgment anchor · gate-efficacy **accepts-artifact-as-action** class paragraph + one register row (census-form Population) + consumer reference + version row |
| **2** | #5286 | L | The release's centre; cites #4919's class | **G-CL10** (new Gate-13 row) + self-repair + disposition row, appended to the v2.22 entry · stage-13 **Phase A14** + A14.1 · Outcome template `**Limb owners:**` REQUIRED (template major) · `**Population:**` grammar paragraph (census form, no `probe: none`) + 2 register rows + flip row · engine `g-cl10` arms in `check-doc-gates.py` + `deploy.sh --check-doc-gates` wrapper, owner helper, constants, DG self-test arms · sentinel `.github/g-cl10.enforce` (`warn`) · the ADR · cascade surfaces |
| **3** | #5062 | M | Upstream gate; shares the engine and the spec with #5286 | **G3-20** (two rows) appended to v2.22 · `stage-03-bundle.md` home (blocks at `status: bundled`, per D-5062-Posture (A′)) · `stage-02-triage.md` **A4.9** advisory read · engine `grade_declaration()` split · parser `doc_impact` field · 2 register rows · cascade surfaces |
| **4** | #4417 | S | Smallest, most isolated | projector `--verify-closeout-anchors` mode · new `deploy.sh --check` entry `closeout-anchor-consistency` (warn; own dial; written sink; ARMED deadline) + self-test limbs · register, flip and version rows · re-point the close-out comments · three doc-cascade rows |

### #4919 — change specification (the first card; Stage-5 design on #8578, A6.5 remedies adopted)

**Files:** `core/disciplines/review-discipline-principles.md`, `release/references/pipeline/stage-09-plan-review.md`, `core/schemas/gate-criteria-spec.md`, `core/schemas/gate-evaluation-spec.md`, `core/standards/gate-efficacy-standard.md`. Four slices in anchor-before-pointer order (PV-2f; stage-09; the two schema files; gate-efficacy), so Check 62 resolves at every head.

**One rule, four owners, cite-not-restate.** The **name** (the accepts-artifact-as-action class) lives in gate-efficacy; the **evidence form** (observed acting, PV-2f) in § 8; the **procedure** (Phase A4) in stage-09; the **criterion** (G-PR4) in gate-criteria-spec. None restates another's predicate.

**The adopted A6.5 remedies, as this card applies them:**
- **CD3 — PV-2f limb (1) is the path, limb (2) is the input.** Limb (1) names only where the control runs (loading context, runner, entry point, scope); a fixture exercised through the control's own entry point on its run path observes that path, consistent with PV-2d. Limb (2) decides whether the input is one the control must act on; for a step whose action reaches live state only it can reach, that input is the live state or a sandboxed copy reached through the same entry point. The fixture sentence that contradicted PV-2 and PV-2d is not carried.
- **CD1 — an independent second observation.** Each Phase A4 observed-acting line's `via` is either (i) an artifact the control's own run wrote on its run path, authored by a party other than the hub (a CI job run and its log line, the Stage-7 Dev Testing record, a block output captured in the operator's session), or (ii) a read the grader re-executes at Phase C where it is reachable, comparing the live result with the recorded one (the G-PR12 live cross-check shape). A line meeting neither is *recorded, not observed* and leaves G-PR4's structural limb unsatisfied.
- **CD2 — a census line and a presence probe.** One `**Phase A4 control census:**` line per Stage 9 records the classification itself (every register risk, split into control-backed and owner-act ids). G-PR4's structural limb becomes deterministic given the census: every register risk id appears in it, and every `control` id carries an observed-acting line whose `via` is form (i) or (ii). Classification soundness moves to the judgment dimension. The owner-act boundary is defined: a mitigation whose effect depends on a control rendering a verdict rests on that control. The register row's population is a **presence census** (census-versus-line count), named as presence so a percentage is not read as adequacy; per #5286's CD-1 it carries no `probe: none`.
- **PR-1 — the completed Aggregation-Trace** (below); the register row's Posture cell states the property the evaluator delivers: a NO-GO recommendation input the operator weighs at Phase C, never an evaluator HOLD.
- **PR-4 disposition:** G-PR4's `Type` / `Check` / `Automation` cells are retained (`field` / `structural` / `auto`), as D-4 selected and as the v2.22 header's "NO criterion ID … re-typed" requires; the v2.22 bullet states that `structural` covers presence over the recorded census and that classification soundness is the judgment dimension's read.

**Completed Aggregation-Trace (per `stage-05-solutioning.md` § 5.8; extends the design's trace to the rules that decide).**

| Evaluand | Consuming rule | Rule (verbatim) | Effect on the aggregate |
|---|---|---|---|
| G-PR4, refined (structural limb) | `core/schemas/gate-evaluation-spec.md` § Gates 7→8 through 12→13, over the stage-09 § 7 Metrics line (8 metrics: G-PR1..G-PR7 plus incoming deferred items) | "Consume each `pipeline/stage-NN-*.md` §7 (Stage-Transition Gate) Metrics line directly. Each named metric verified against GitHub/file state." | A missing census, an uncovered risk, a control id with no line, or a line whose `via` is the hub's own reading reads G-PR4 FAIL: one failing metric of 8 |
| The metrics pass rate | `gate-evaluation-spec.md` § Decision Matrix | "≥ 80% \| ≥ 3.0 \| ≥ 2 \| **PROCEED WITH CAVEATS** (list failing metrics)" | 7 of 8 = 87.5% (6 of 7 = 85.7% with G-PR7's judgment metric set aside) → PROCEED WITH CAVEATS naming G-PR4. **G-PR4 alone never produces an evaluator HOLD**; HOLD needs the pass rate under 80% or a judgment average under 3.0 |
| *risk assessment quality* scored 1 (a wrong path, or an unsound classification) | `gate-evaluation-spec.md` § Decision Matrix | "= 100% \| ≥ 3.0 \| 1 \| **PROCEED WITH CAVEATS** (flag critical-weakness dimension)"; "any \| any \| 1 (multiple) \| **HOLD**" | One floor-1 dimension → PROCEED WITH CAVEATS, flagged. HOLD only with several floor-1 dimensions |
| GO | `stage-09-plan-review.md` Phase C table, GO row | "All quality gates passed, no unresolved blockers, risk accepted" | A control-backed risk with no independent observed-acting line is not *accepted* under Phase A4. The withholding power is the operator's Phase C reading of "risk accepted", not the evaluator's recommendation |
| GO WITH CONDITIONS | `stage-09-plan-review.md` Phase C table and its boundary rule | "Minor items accepted with documented rationale; conditions must not require code changes" · "Conditions are documentation, tracking, or process items only." | The most likely landing place for an unobserved control-backed risk: the operator may accept it with documented rationale as a process condition (an observation to take where the control first runs); a condition that needs a code change is a NO-GO |
| NO-GO | `stage-09-plan-review.md` Phase C table, NO-GO row | "Unresolved blockers, unacceptable risk, quality below threshold" | An unaccepted control-backed disposition is a NO-GO **recommendation input** the operator weighs |
| The register row's Posture | `core/standards/gate-efficacy-standard.md` § Requirement (b), prose form | "`advisory` here means *no pre-merge blocking status check* — it does not mean unimportant, and it says nothing about the authority of a pipeline stage-gate that runs it" | Posture reads advisory, and states the stage-gate effect in the trace's terms: a NO-GO recommendation input weighed at Phase C (PR-1), not "withholds GO" |
| PV-2f | `review-discipline-principles.md` § 8.1 verdict rule | "zero + any required element above not established -> INDETERMINATE, naming the missing element" | A zero resting on an arm not observed on its run path reads INDETERMINATE naming PV-2f; the CLEAN line is unchanged, because PV-2f qualifies "observed" in PV-2 and adds no conjunct |
| The new register pointer | `core/deploy/deploy.sh` Check 62 (`register-runner-resolution`) | "FAIL: register-runner-resolution — … " under enforce; WARN under warn | CLEAN count +1 (`runner-def` only). Deleting stage-09's Phase A4 record template gives `UNRESOLVED` |
| The new `prose` register row | G-CL10 arm (i), landing with #5286 (#8582 D-3/D-6, with CD-1) | — (not on the branch at #4919's commit) | In this release's G-CL10 population. Its census is measured at Stage 13 from this release's own Stage-9 comment set: `examined` = the census's control ids, `conforming` = those with an independent observed-acting line. An owner is needed only below 100%, and only one whose body or comments name `stage9-control-backed-dispositions` |

**Trace date:** 2026-10-29 at `b1aaa77e`.

**Downstream contract (what the siblings grade against):** the class literal `accepts-artifact-as-action` (gate-efficacy, the paragraph after class-3 limit 7); the rule `observed acting` with its evidence form at § 8 **PV-2f**; G-PR4 names `G-CL10` and carries no population, threshold or owner test; the v2.22 entry is opened by #4919 and the siblings append to it; the register row's population name is `stage9-control-backed-dispositions`; `PV-2f` is taken (relayed to #5903).

### #5286 — change specification (the second card; Stage-5 design on #8582, CD-1 and the A6.5 refinements adopted)

**Files:** the ADR (ADR-228, cited in-release as `{{ADR:declared-obligations-measured-at-close}}`), `core/deploy/tools/check-doc-gates.py`, `core/deploy/deploy.sh`, `.github/g-cl10.enforce`, `core/schemas/gate-criteria-spec.md`, `release/references/pipeline/stage-13-close.md`, `release/references/specs/release-outcome-statement-template.md`, `core/standards/gate-efficacy-standard.md`, and the D-5286-MatrixCascade (A) surfaces: `core/schemas/gate-evaluation-spec.md`, `release/governance/release-process.md` (two paragraphs), `release/references/pipeline/stage-03-bundle.md`, `release/references/standards/bundle-composition-doctrine.md`, `core/deploy/tools/README.md`. Slices in the design's order: the ADR; the engine with its fixtures; the wrapper, sentinel and DG arms; the criterion, Phase A14 and the template; the register; the cascade.

**What lands.** Gate 13 criterion **G-CL10**, warn-mode, run at Stage 13 **Phase A14** by `deploy.sh --check-doc-gates --gate g-cl10` (`--list` first). Arm (i): every gate-coverage register row whose Surface leads with `prose` that the release added or modified carries a `**Population:**` segment, and the release plan's Verification Evidence carries its population record — bound to the declaration by probe and a pin containing the release head — which meets the threshold or names an open owning work item outside the release whose body or comments name the population. Arm (ii): every limb of the milestone's Release Outcome Statement names an owning work item on the new required `**Limb owners:**` line (Outcome template 2.0). The engine stays offline and runs no declared probe; the wrapper reads the milestone, release membership and each owner's issue and comments.

**The adopted remedies, as this card applies them:**
- **CD-1:** `probe: none` is not in the grammar — the engine reads it as malformed (fixture CL10-X); a population no instrument reaches carries a census definition (#4919's row is the live case, CL10-CN its fixture). An owner is valid only when its body or comment stream names the population (CL10-NN, CL10-CM), and Phase A14 step (2) posts the record on the owner.
- **PR-1:** with no `--plan`, the engine finds the one plan whose `milestone:` frontmatter names the release, wherever the version stamp moved it, and withholds an obligation as `record-unresolved` naming the candidates otherwise (CL10-PF, DG-12); Phase A14 step (3) carries A5's `--plan` clause.
- **FM-2:** the owner read carries `state_reason`; a limb whose every owner closed as not planned or a duplicate FAILs `limb-owner-abandoned` (L-6), and an open non-member owner reads `carried-by-nonmember #N` (L-1b).
- **FM-3:** arm (ii)'s cutover reads the milestone's Composition Lock date before its creation date (L-8); template § 10 states the key.
- **FM-4:** every arm-ii subject, and so every arm-ii warn-log detail, opens `limbs:` (L-10, DG-13); the flip row's blocker asks for each arm's FAIL path exercised.
- **FM-5:** the ADR gives host-side reach as the eliminating reason for an engine-executed probe; Phase A14 step (2) reads the probe first, runs it under the hook layer with no bypass, and records a refused probe `state: not-run` (CL10-NR).
- **FM-6:** the record is found at any heading depth anywhere in the plan (CL10-H, under the plan's H2 section); a Surface cell's leading markup is set aside (CL10-K); a `\|` probe binds to a `|` record (CL10-E); A14.1 and the AAR text name the H2 `## Verification Evidence` section.

### #5062 — change specification (the third card; Stage-5 design on #8586, CD-5, PR-2, FM-2, FM-3 and FM-5 adopted)

**Files:** `core/deploy/tools/check-doc-gates.py`, `release/tools/bundle-issues-parser.py`, `core/schemas/gate-criteria-spec.md`, `release/references/pipeline/stage-03-bundle.md`, `release/references/pipeline/stage-02-triage.md`, `core/standards/gate-efficacy-standard.md`, and the D-5062-MatrixCascade (A) surfaces `core/schemas/field-lifecycle-matrix.md`, `release/governance/release-process.md` (its Stage-3 Gate list) and `core/deploy/tools/README.md`. Slices in the design's order: the engine split; the parser; the criterion; stage-03; stage-02; the register; the cascade.

**What lands.** Gate 3 criterion **G3-20**: at the `status: bundled` transition a card's Documentation Impact declaration is gradable under the G-CL8 grammar — present means gradable, not a heading. The grammar is implemented once, as `grade_declaration()` factored out of the G-CL8 engine, and the parser reads it into a per-issue `doc_impact` (`gradable` · `ungradable` · `misheaded` · `absent` · `not-evaluated`) on the parse Stage 3 already runs, so the bundle gate and the close gate cannot disagree. Triage reads the same value early and advisory (**A4.9**). Two register rows split by locus of input: the machinery (CI) and the live gate (`prose`, population `doc-impact-gradable-in-bundled`, threshold 100%).

**The adopted remedies, as this card applies them:**
- **D-5062-Posture (A′) with FM-1 / CD-1:** G3-20 blocks a candidate not yet labelled `status: bundled`; a member a re-bundle, an amendment or a cascading re-bundle evaluates again carries an advisory verdict, as does a kind-form card. The design's "forward-only by construction" sentence is not carried into either the criterion or the Stage-3 row.
- **FM-2 / CD-3:** the GD-PARITY arm holds `grade_declaration` and `eval_issue` to one verdict by stubbing the four resolution functions to "resolved" over every fixture body (58, the retire bodies included), never by a list of message phrases; the un-stubbed `unresolved` pair stays (gradable at Bundle, failing at close); a mixed fixture pins the detail order, which is declaration order and is unchanged.
- **FM-3, option (a):** the kind-form derivation is kept for detection and G3-20 is recommend tier for F2 — its verdict is recorded and never excludes the card. § Kind-Form Applicability's rule sentence names G3-20 as the one Gate 3 criterion that adopts it, and gains G3-20's disposition row. Mode A's bundleability pre-filter does not route a kind-form card to its parse, so the Stage-3 row reads a kind-form candidate by the parser over its number.
- **FM-5:** `not-evaluated` withholds the verdict and is neither a failure nor a pass; an engine that cannot be loaded is **one** NOT-EVALUATED finding for the batch, resolved once; a raise on one body withholds that card's verdict alone. The criterion, its Self-Repair row and the Stage-3 row read the same way.
- **CD-5:** the designed Row L probe exited 1 on the live population and printed every bundled card. The parser gains a separate `--doc-impact-population` mode, with a `--label` source, which prints one `MEMBER` line per issue G3-20 applies to and one `SUMMARY` line with the examined and conforming counts, and exits 0 on a completed run; Row L's probe is that one command. It was run once at Stage 6, read-only (§ Verification Evidence). **For Stage 13:** the record is measured once, at this release's close, by that probe. G3-20 lands with this merge, so by then it has evaluated **0** bundling candidates and the record reads the legacy declaration-grammar debt; below 100% it needs #8114, whose comment stream names the population, as its owner. The declared observable — a G3-20 verdict recorded per candidate in the bundle rationale of the first post-merge Stage 3 run — is the owner's observed-acting item, read once.
- **PR-2:** the field-lifecycle matrix's Documentation Impact row reads `U` at Triage and `R/U` at Bundle, so the repair the Self-Repair row instructs before the transition is licensed.

**Not done here (A′'s one-shot sweep, documented and not run):** before the first bundle session after merge, one read-only parser pass over the `status: approved` queue hands the operator the per-card repair list — `python3 release/tools/bundle-issues-parser.py --label "status: approved" --doc-impact-population`, every `MEMBER` line not reading `gradable` carrying its repair. It is an operator action the hub carries as a Stage 13 follow-up on the F-1 owner, #8114.

### #4417 — change specification

Carried by its own Stage-5 design (#8590) and its own Stage-6 sub-task; its slice records its change specification and evidence in this file when it lands. The File Change Matrix below already carries every path its design and its scope-lock render name.

---

## Stage Applicability Matrix

| Card | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Note |
|---|---|---|---|---|---|---|---|---|
| #4919 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | Class name + evidence form + procedure + criterion; no executable change |
| #5286 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | New Gate-13 row G-CL10 with an engine runner; an ADR authored at Stage 6 |
| #5062 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | Home: Bundle (G3-20); Triage A4.9 advisory read. AC-4 is graded at Stage 13 |
| #4417 | ✅ (ran) | ✅ | ✅ | ✅ | release | release | release | Projector verify arm + a new warn-mode deploy check |

No card skips: Stage 5 bias is ALL under cross-cutting, and every card ships a check or a criterion. Stages 10–11 compress (git-native).

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. A shared path is listed once, under the first card that edits it; the cards that edit it are named after the verb.

```
# ── Engineering Commit 0 ──
release/releases/plans/governance-obligations-measured_RELEASE_PLAN.md  ADD
# ── shared surfaces (serial: #4919, #5286, #5062, #4417) ──
core/standards/gate-efficacy-standard.md  EDIT  all four cards
core/schemas/gate-criteria-spec.md  EDIT  4919 G-PR4 + v2.22 entry · 5286 G-CL10 · 5062 G3-20
core/schemas/gate-evaluation-spec.md  EDIT  4919 G-PR4 anchor · 5286 Gate-13 anchor
core/deploy/deploy.sh  EDIT  5286 g-cl10 wrapper · 4417 new check entry
core/deploy/tools/check-doc-gates.py  EDIT  5286 g-cl10 arms · 5062 grade_declaration split
core/deploy/tools/README.md  EDIT  5286 · 5062 · 4417
release/governance/release-process.md  EDIT  5286 two paragraphs · 5062 G3 field-list paragraph
release/references/pipeline/stage-03-bundle.md  EDIT  5286 Outcome field list · 5062 G3-20 home
# ── #4919 ──
core/disciplines/review-discipline-principles.md  EDIT
release/references/pipeline/stage-09-plan-review.md  EDIT
# ── #5286 (runner close-gate-engine SELECTED; D-5286-MatrixCascade (A)) ──
release/references/pipeline/stage-13-close.md  EDIT
release/references/specs/release-outcome-statement-template.md  EDIT
release/references/standards/bundle-composition-doctrine.md  EDIT
.github/g-cl10.enforce  ADD
core/ADRs/ADR-228-declared-obligations-measured-at-close.md  ADD
# ── #5062 (home Bundle G3-20 SELECTED; Triage A4.9 SELECTED; D-5062-MatrixCascade (A)) ──
release/references/pipeline/stage-02-triage.md  EDIT
release/tools/bundle-issues-parser.py  EDIT
core/schemas/field-lifecycle-matrix.md  EDIT
# ── #4417 (projector arm and re-point both fire; D-DocImpactScope (A)) ──
core/deploy/tools/generate_release_index.py  EDIT
release/tools/automated-closeout.sh  EDIT  comments only
release/references/standards/release-corpus-schema.md  EDIT
core/standards/date-variable-convention.md  EDIT
```

#### Read-only inputs

```
release/releases/RELEASE_LOG.md  READ
.github/ISSUE_TEMPLATE/improvement.yml  READ
core/hooks/lib/fragile-ref-patterns.sh  READ
core/deploy/tools/check-doc-links.py  READ
```

#### Release-wide explicit non-scope

```
release/skills/release-planner/references/release-plan-template.md  NOT EDITED
packages/release-planner.skill  NOT EDITED
core/governance/RECORDS_ARCHIVE_LOG.md  NOT EDITED
core/rules/bypass-mode-readiness.md  NOT EDITED
release/references/how-to/hub-spoke-bridge.md  NOT EDITED
release/references/pipeline/stage-08-qa-testing.md  NOT EDITED
core/standards/design-principle-register.md  NOT EDITED
release/tools/verify-release-plan.sh  NOT EDITED
```

**The Stage-4 conditional rows are resolved at this commit.** `5286-runner-close-gate-engine` is SELECTED (the engine row); `5286-runner-closeout`, `5286-runner-fixture` and `5286-plan-template-section` are RULED OUT, so the release-plan template row and the `skill-member-touched` package rows do not fire and leave the matrix. `5062-home-bundle` is SELECTED as the home and `5062-home-triage` as the A4.9 advisory read, so both stage specs are edited. `4417-projector-arm` and `4417-repoint-4666-comment` fire. Every `keep-4444` and `4444-mechanism-*` row leaves with #4444 (§ Deviation Log DEV-1). The cascade rows rendered at the scope-lock are added (DEV-4).

**Non-scope reasons.** The release-plan template and its package: #5286 declares its population on the register row, not in the template (Agent-Editability note; R-6 closed). `RECORDS_ARCHIVE_LOG.md`: out of scope per the Stage-4 render; its worked instance routes individually. `bypass-mode-readiness.md`: generated, and no hook changes. `hub-spoke-bridge.md`, `stage-08-qa-testing.md`, `design-principle-register.md` and `verify-release-plan.sh`: #4444's surfaces, which left with it.

**Zero `ADD` rows for executables** → the new-executable companion obligation (an allowlist row and CI wiring) does not fire. **No path is renamed, moved or deleted** → the mover set is empty. **Four `pipeline/stage-*.md` files** are edited (stage-02, stage-03, stage-09, stage-13), so cross-cutting trigger (a) fires.

### Agent-Editability Read

Transcribed from the Stage-4 derivation, controls read at `b1aaa77e`, and re-applied to the paths Stage 5 and the scope-lock added. The Tier-0 floor's surviving union is the basenames `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md`; no matrix path carries one. The sanctioned-session gate's first conjunct needs a `*/skills/<name>/` segment; no matrix path carries one, because the plan-template row was ruled out.

| Card | Write-set paths | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| #4919 | review-discipline · stage-09 · gate-criteria-spec · gate-evaluation-spec · gate-efficacy | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #5286 | gate-criteria-spec · stage-13 · Outcome template · gate-efficacy · check-doc-gates.py · deploy.sh · the sentinel · the ADR · release-process (governance file) · stage-03 · bundle-composition-doctrine · gate-evaluation-spec · tools README | ∅ | ∅ — conjunct 1 false | `unconstrained` (the governance-file protocol applies to `release-process.md`: unconstrained is not ungoverned) | ordinary Engineering spoke |
| #5062 | check-doc-gates.py · bundle-issues-parser.py · gate-criteria-spec · stage-03 · stage-02 · gate-efficacy · field-lifecycle-matrix · release-process · tools README | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #4417 | generate_release_index.py · deploy.sh · gate-efficacy · automated-closeout.sh · release-corpus-schema · date-variable-convention · tools README | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |

---

## Contention Map

**Within release (serial P0 order resolves every row):**

| File | Cards | Overlap class | Resolution |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` | all four | different sections (the class-3 limits paragraph, register rows, flip rows, version rows); append-pattern in the register | one register-row block per card, appended in serial order |
| `core/schemas/gate-criteria-spec.md` | #4919 (G-PR4), #5286 (Gate 13), #5062 (Gate 3) | different gate tables; **one** Versioning entry | #4919 opens the release's single **v2.22** entry; #5286 and #5062 append to it (CIAC-1, CIAC-3) |
| `core/schemas/gate-evaluation-spec.md` | #4919 (G-PR4 anchor), #5286 (Gate-13 anchor) | different lines of a non-append file | serial |
| `core/deploy/deploy.sh` · `core/deploy/tools/check-doc-gates.py` | #5286, #4417 · #5286, #5062 | separate check blocks and self-test groups; one engine split | serial |
| `release/governance/release-process.md` · `release/references/pipeline/stage-03-bundle.md` · `core/deploy/tools/README.md` | #5286, #5062 (and #4417 for the README) | different paragraphs and rows | serial |

**Latent cross-milestone overlaps (none in flight):** #5903 and #7016 latent on review-discipline § 8; #6225..#6227 latent on the gate-efficacy register. All are re-checked at Stage 9 Phase A6.5 / G-PR8 and Phase A6.6.

## Cross-PR Overlap Audit

### Baseline SHA

`b1aaa77e9210a5c70d0e31cce885ddbc4aae3720` — the Stage-4 Phase A0 pin, re-read unchanged by all four Stage-5 designs, and the Commit-0 base: the release branch is cut from exactly this commit.

### In-Flight Release Roster

**Measured at:** `b1aaa77e` · `2026-10-29T03:25Z` (Engineering Commit 0) · **Population:** n=0 sibling(s)

**None in flight at `b1aaa77e` / Engineering Commit 0.** Probe: open pull requests, limit 200 → 0 (control: the same reader on merged pull requests, limit 3 → 3); remote heads → 1, `main` only, so 0 remote `release/*` heads (control: the `main` head itself is returned). This is a pinned measurement with no verdict; Stage 9 Phase A6.6 re-measures it.

### Structural sub-audit

No file is renamed, moved or deleted, so the mover set is empty. `SURFACE(R)` is the version-slot token `Δversion/minor@v4.80.1` only.

---

## Risk Register

| # | Risk | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| R-1 | Release Class under-declared | Operator | **Closed at the Stage-4 gate:** cross-cutting; #4444 left; `effective_pts` 18 × 1.3 = 23 recorded with the `[RECLASSIFY]` comment on #8577 | CHEAP / HIGH |
| R-2 | The release fails its own G-CL8 and pushes the `g-cl8` row count toward the threshold #5062 AC-4 reads | Hub → Stage-13 spoke | D-DocImpact (A) crisped #4919 and #4417; D-DocImpactScope (A) added #4417's cascade rows; #5062's own omissions are recorded (DEV-5) so the close reader sees what G-CL8 does not grade | CHEAP / HIGH |
| R-3 | #5062's two `update` rows were alternatives, so the unchosen one would FAIL G-CL8 | Stage-5 / Stage-6 spokes | **Resolved by design:** both stage specs are edited (stage-03 home, stage-02 A4.9), so both rows resolve by a real change | CHEAP / HIGH |
| R-4 | `gate-efficacy-standard.md` is a rebase hotspot (16 commits in 14 days); a four-way serial edit risks a mid-flight conflict | Stage-6 spokes | Serial P0; each card syncs `origin/main` first; G-PR8/G-PR9 re-check at Stage 9 | MODERATE / MEDIUM |
| R-5 | A new criterion or check ships "specified, not yet emitting", reproducing the defect this release exists to close | Stage-6 spokes | CIAC-1; every new gate declares a written sink and a deadline (W1/W2) | CHEAP / HIGH |
| R-6 | #5286's population declaration lands in the plan template and needs a sanctioned skill session | Stage-5 spoke | **Closed:** declared on the register row; the template row is ruled out | CHEAP / HIGH |
| R-7 | #4919's § 8 extension collides with #5903 extending the same section | Hub | `PV-2f` is claimed here and the claim is posted on #5903; whichever lands second reconciles at Stage 9 A6.5 | MODERATE / MEDIUM |
| R-8 | Milestone description out of schema (Outcome H2, no `**Class:**`, no map) | Hub | **Closed:** the Phase-B1 PATCH landed (Outcome H3 with a `Limb owners:` line, `**Class:** cross-cutting` with Rationale, Parallelization Map) | CHEAP / HIGH |
| R-9 | Quota: parallel Stage-5/7/8 batches against an unstated envelope | Hub | Checkpoint B at every launch | CHEAP / MEDIUM |
| R-10 | Rollback entanglement: shared files make a per-card revert non-isolated | Hub | Whole-release revert of the merge commit (`git revert -m 1`); per-card forward fix preferred | MODERATE / HIGH |
| R-11 | A register row's Surface cell misstates what executes it, so G-CL10 classifies it by its cell (#5286) | Reviewer at design-review check 4.9 | Named in G-CL10's "what it does not detect"; reviewer-owned | CHEAP / MEDIUM |
| R-12 | #4919's census population is measured only at this release's Stage 13, from its own Stage-9 comment set; below 100% it needs an owner whose body or comments name `stage9-control-backed-dispositions` (#4919) | Stage-13 spoke | Census measured per G-CL10's record form; an owner named only on a shortfall, and only one that names the population; no owner is pre-named | CHEAP / MEDIUM |
| R-13 | G3-20's day-one block rate (63% of the approved queue would fail) (#5062) | Operator | **Rendered:** D-5062-Posture (A′) — blocks only cards not yet bundled; re-bundles advisory; one read-only parser pass before the next bundle session | CHEAP / MEDIUM |
| R-14 | Engine-path coupling: the parser loads the engine's grammar by path (#5062) | Stage-6 spoke | A parity arm and a `not-evaluated` outcome when the engine cannot load (DI-9) | CHEAP / MEDIUM |

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5286 × #5062 × #4919 on `core/schemas/gate-criteria-spec.md`):** No criterion this release adds or refines carries the "specified, not yet emitting" disclosure; each names a runner that writes its verdict. *Method:* `grep -c -F "specified, not yet emitting" core/schemas/gate-criteria-spec.md` at most 14. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm: the same command at the plan baseline returns 14, a non-zero read of the same target. The release's version-history entry must not quote the phrase.
- [ ] **CIAC-2 (#4919 × #5286 on `core/schemas/gate-criteria-spec.md`):** The acceptance-moment criterion (#4919, refined G-PR4: was the control observed acting?) and the close-moment criterion (#5286, Gate 13: is the obligation measured?) each cite the other's identifier, and neither restates the other's predicate. *Method:* declared, verification deferred to core/schemas/gate-criteria-spec.md. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#4919 × #5286 × #5062 × #4417 on `core/standards/gate-efficacy-standard.md`):** Every normative predicate or gate this release adds or modifies has a gate-coverage register row: either a `runner-def:` pointer that Check 62 resolves, or a named-gap row that states its declared observable. *Method:* declared, verification deferred to core/standards/gate-efficacy-standard.md. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#5286 × #4417 on `core/deploy/deploy.sh`):** Each runner this release adds ships a sensitivity fixture that goes red on a seeded defect and a specificity fixture that stays silent on the near-miss. That is the release practising its own observed-acting rule on itself. *Method:* declared, verification deferred to core/deploy/deploy.sh. *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 body read `declared=4 parsed=4 clean=1 declared-deferral=3 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6.

---

## Verification Plan

**AC baseline:** the per-card acceptance-criterion counts read at `b1aaa77e`. #4444's four rows and its baseline entry leave with the card (DEV-1). #5062 AC-1 and AC-2 carry rows marked DEFERRED by the operator render; AC-3 is retargeted to the home Stage 5 selected (a pre-authorized path change).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #5286 | AC-1 | `grep -c -F "owning work item" core/schemas/gate-criteria-spec.md` at least 1 | at least 1 (baseline 0 at b1aaa77e; same-file control "G-CL9" reads 24) |
| #5286 | AC-2 | `grep -c -i "obligation" release/references/pipeline/stage-13-close.md` at least 3 | at least 3 (baseline 2 unrelated lines; same-file control "G-CL9" reads 2) |
| #5286 | AC-3 | declared, verification deferred to the sensitivity fixture of the runner Stage 5 selects (0% conformance and no owner must FAIL), re-run at Stage 7 | FAIL on the synthetic release |
| #5286 | AC-4 | declared, verification deferred to the specificity fixture of the same runner (0% conformance with a named owner must PASS), re-run at Stage 7 | PASS on the synthetic release |
| #5286 | AC-5 | `grep -c -F "owning work item" release/references/specs/release-outcome-statement-template.md` at least 1 | at least 1 (baseline 0; same-file control "AFTER" reads 37) |
| #5062 | AC-1 | [DEFERRED — dropped by the operator render of 2026-10-28; the disposition is recorded as out of scope under the G-CL8 issue-scope rule and the warn entry stands] | n/a |
| #5062 | AC-2 | [DEFERRED — dropped by the same render with the back-fill branch] | n/a |
| #5062 | AC-3 | `grep -c -F "Documentation Impact declaration gradable" release/references/pipeline/stage-03-bundle.md` at least 1 | at least 1 in the Stage-5 home, the bundle stage spec (baseline 0; same-file control "G3-05" reads 3) |
| #5062 | AC-4 | declared, verification deferred to Stage 13 Phase A11, the g-cl8 row count in the shared deploy-check warn log against the threshold of 10 | a stated count (plan-time baseline 8) |
| #4919 | AC-1 | `grep -c -F "observed acting" release/references/pipeline/stage-09-plan-review.md` at least 1 | at least 1 at Phase A4 / G-PR4 (baseline 0; same-file control "risk" reads 11) |
| #4919 | AC-2 | `grep -c -F "observed acting" core/disciplines/review-discipline-principles.md` at least 1 [READER-GRADED — the class is named in core/standards/gate-efficacy-standard.md beside the class-3-O limits list and cited, not restated] | at least 1 (baseline 0); reader limb graded at Stage 8 |
| #4919 | AC-3 | `grep -c -F "verify a guard fires where it will execute" release/references/pipeline/stage-09-plan-review.md` at least 1 | at least 1 (baseline 0; the same phrase reads 1 in release/releases/RELEASE_LOG.md) |
| #4417 | AC-1 | declared, verification deferred to the self-test arm Stage 5 names for a seeded post-declaration divergence, re-run at Stage 7 | finding names the version and the disagreeing surfaces |
| #4417 | AC-2 | declared, verification deferred to the same self-test run with no network access | completes offline |
| #4417 | AC-3 | declared, verification deferred to the self-test arm where two surfaces agree and the third diverges | flagged |
| #4417 | AC-4 | declared, verification deferred to the self-test arm over a grandfathered divergent version | silent |
| #4417 | AC-5 | declared, verification deferred to the flip-decision row for the new check in core/standards/gate-efficacy-standard.md | warn posture, written sink and deadline stated |

`ac_baseline: { #5286: 5, #5062: 4, #4919: 3, #4417: 5, read_at: b1aaa77e }`

**Null and threshold rows carry a same-target control** (AC-Binding Limb 2): every count row names a control read with the same instrument on the same file, and that control returns non-zero at the baseline.

### Release-Level Verification

These checks use tools or shapes outside the plan verifier's runnable set, so each is declared deferred to the Stage-6 C4 run that executes it; the commands and observed results land in § Verification Evidence as each card's slice lands.

| Check | Verification Method | Expected |
|---|---|---|
| Doc-link integrity | [DEFERRED — the doc-link checker over each card's edited files, with the plan-depth lint on this plan, run at Stage 6 C4; result in § Verification Evidence] | no new broken link |
| Register runner resolution (CIAC-3) | [DEFERRED — the Check 62 line of a deploy-check run, at Stage 6 C4 per card; result in § Verification Evidence] | CLEAN, pointer count = baseline + each card's new pointers |
| No new deploy-check FAIL lines | [DEFERRED — a deploy-check run, at Stage 6 C4 per card, compared against the baseline's FAIL lines] | no FAIL line the baseline lacks |
| CIAC authoring lint | [DEFERRED — the plan verifier's CIAC lint over this file, at Stage 6 A1 and Stage 9 A3.6] | declared=4 parsed=4 flagged=0 |
| Package consequence | [DEFERRED — the package resolver reading each changed path on STDIN, at Stage 6 C4 per card] | empty — no rostered skill's package is staled |
| Count-structure lint (Check 63) | [DEFERRED — the count-structure primitive over each edited file, at Stage 6 C4 per card] | no new FLAG against the baseline |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential (P0 serial; contention-driven) |
| Commit strategy | Commit 0 (this plan), then one or more commits per card in sequence order, each pushed on landing (Write-Early); messages carry the `governance-obligations-measured:` prefix and a reference-only `(#N)` |
| Review approach | Single release PR, draft until Stage 9 Phase A8 |
| Deployment mechanism | Git merge, then `./deploy.sh --deploy` mirror refresh. No skill package fires |
| Stacked-base cleanup | N/A (single branch) |

The PR body is parser-clean: the four cards carry a close keyword only in the PR body's dedicated Issue References block, as the Stage-6 brief lists them; no close-family verb precedes an issue number anywhere else in the body, the title or any commit message.

---

## Rollback Strategy

| Scope | Method | Complexity |
|---|---|---|
| Whole release | `git revert -m 1 <merge>` restores `main` byte-for-byte. Every new gate ships warn-mode, so no gate blocks on revert | Low |
| Per card | Forward fix preferred: the shared files entangle the cards (R-10) | Medium |
| #4417 alone | Reverting its check arm and its projector mode is isolated | Low |
| #4919 alone | Additive text plus one register row; its commits revert cleanly before #5286 lands, and after that by forward fix (G-CL10 names G-PR4) | Low |
| Version tag | Retained and recorded per Tag Retention; never deleted | — |

---

## Quota Budget

**Verdict:** WARN (conservative), per quota-budget-protocol.md Checkpoint A, transcribed from Stage 4.
**Parallel-eligible spokes per parallel stage:** Stage 7: 4 · Stage 8: 4 (Stage 6 is serial).
**Per-spoke cost estimate:** size-bucket ordinal bands (L ×1 moderate–high, M ×2 low–moderate, S ×1 lowest), heuristic.
**Assumed remaining usage-window envelope:** unstated at spoke time; conservative default.
**Routing:** WARN → window-aware launch; Checkpoint B re-validates at every launch.

---

## Release Class declaration

**`cross-cutting`** — re-classified from `novel` at the Stage-4 gate (`[RECLASSIFY novel → cross-cutting]` on #8577). Trigger (a) fires: the File Change Matrix edits four `pipeline/stage-*.md` files (stage-02, stage-03, stage-09, stage-13). Under the multi-trigger rule cross-cutting outranks novel. `effective_pts: 18 × 1.3 = 23`, inside the 15–25 band. Differentiation posture: engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed from the milestone description at Engineering Commit 0.

**AFTER** — When a release declares a governance obligation, close-out measures it against its stated population, and a gap closes only with a named owner. A control offered at Stage 9 as discharging a risk must have been observed acting where it runs. Two obligations that nothing checked are now checked before they drift: a work item's Documentation Impact declaration, and the close-out date that the changelog, the digest and the release note share.

**BEFORE** — The platform accepts a control's artifact as evidence the control ran. A declared obligation can ship at zero conformance with no owner and still close verified. A Stage-9 residual can rest on a guard that never fires on its path. Nothing upstream of the close checks the Documentation Impact field or the three close-out dates.

**Actor(s):** platform engineering session (hub plus class-appropriate spokes).

**Success Indicator:** At Stage 13 this release's own close-out records a measured value or a named owning work item for each obligation it declares, and its own G-CL8 run reads every card in scope with no ungradable declaration.

**Limb owners:** measured at close → #5286 · observed acting at Stage 9 → #4919 · Documentation Impact checked upstream → #5062 · close-out dates agree → #4417.

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| Every matrix path | **Repository-only** — none is under a skills tree or in the rules mirror set, so no installed copy exists | none required |
| `core/deploy/deploy.sh` and the two engines | Run from the repository at deploy and check time; nothing is copied | none required |

**`deliverable_state: deployed-copy-synced`** — the release declares no Layer-2 propagation target, which this state admits ("or the release declares no propagation target").

### Schema Migrations

N/A — enumerated over data-file formats, register and ledger schemas, the pipeline-event-log schema, the deploy-check warn-log row shape and the gate-criteria schema columns; none migrates. `gate-criteria-spec.md` takes a non-breaking minor version (2.21 → 2.22) with no column or header change, and the warn-log rows the new gates write use the existing shape.

### Memory Evictions

N/A — enumerated over memory eviction, memory re-point and archive disposition; no codification card in this release is tied to an auto-memory entry, so nothing is evicted.

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Run by the Stage-6 spoke on #8579 after this file was written and before it was committed, on base `b1aaa77e`.

| Check | Command | Observed |
|---|---|---|
| Stamp manifest (step 3b) | `bash release/tools/claim-version.sh --verify-stamp governance-obligations-measured` | exit 0 — "verify-stamp OK … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries exactly 1 literal placeholder (python count) |
| CIAC authoring lint (A1) | `bash release/tools/verify-release-plan.sh --ciac-lint release/releases/plans/governance-obligations-measured_RELEASE_PLAN.md` | exit 0 — `CIAC-LINT-SUMMARY declared=4 parsed=4 clean=1 declared-deferral=3 flagged=0`; CIAC-1 CLEAN, CIAC-2..4 DECLARED. G4-06 holds on the committed plan |
| Full verifier (RED arm) | `bash release/tools/verify-release-plan.sh release/releases/plans/governance-obligations-measured_RELEASE_PLAN.md` | exit 3 — **5 PASS / 10 FAIL / 20 SKIP / 0 UNRUNNABLE / 0 ERROR over 35 records** (23 per-issue, 4 cross-issue, 8 always-on). Every runnable per-issue row (7) reads FAIL against the baseline tree — each row's sensitivity arm for its later GREEN. CIAC-1 PASS (14, at most 14). `FCM-COVERAGE` PASS: `declared=35 interpreted=35 obligations=3 excluded=12 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; FCM-1..3 FAIL pre-commit (this file, the sentinel and the ADR — this file delivers at this commit, the other two with #5286). `PROV-PRESENCE` / `PROV-GRAMMAR` PASS (Form X) |
| Doc links | `python3 core/deploy/tools/check-doc-links.py --target-paths release/releases/plans/governance-obligations-measured_RELEASE_PLAN.md --require-targets` | exit 0, no findings, over a file carrying 0 markdown links (python count: 0 inline, 0 reference definitions) — the file names paths in backticks and links nothing |

### Stage 6 — #4919 (C4 self-verification)

Run by the Stage-6 spoke on #8579 at head `55a48478` (the card's last content commit), against baseline copies read from `origin/main` `b1aaa77e`. Engine: `python3` line scans (the workstation `grep` is a shim), plus the repository's own runners. Every arm states its subject-discriminating control.

| ID | Binds | Method | Observed | Control |
|---|---|---|---|---|
| Plan rows | AC-1, AC-2, AC-3 | `bash release/tools/verify-release-plan.sh` on this file | AC-1 PASS (count 5); AC-2 limb 1 PASS (count 1), row UNRUNNABLE by design — its reader limb is graded at Stage 8; AC-3 PASS (count 1). Roll-up 8 PASS / 6 FAIL / 20 SKIP / 1 UNRUNNABLE / 0 ERROR over 35 records | each row read FAIL at Commit 0 on the baseline tree (its sensitivity arm); the 6 FAIL are the later cards' rows and their two ADDs, still RED by design |
| V-1 | AC-1 + PV-2b | stage-09 region from the `**Phase A4 —` line to the line opening `**Phase A6.5` | region 20 lines: "observed acting" 2, census label 1, observed-acting label 1; whole file "observed acting" 5 (region < whole — bounded); the hyphenated `observed-acting` token sits on 1 line, the fenced template | baseline: region ABSENT (reported absent, not 0); the A3.7 region (19 lines) carries 0 |
| V-2 | AC-1 + CIAC-2 | the first row opening `\| G-PR4 \|` in gate-criteria-spec | names "observed acting" and `G-CL10`; carries none of "threshold", "owning work item", "population:"; cells `field` / `structural` / `auto` retained | the G-PR3 row: neither token; the baseline G-PR4 row: neither token |
| V-3 | AC-2 | review-discipline span from the line opening `      PV-2f` to the line opening `PV-3` | 52 lines: "observed acting" 1, "accepts-artifact-as-action" 1 | the PV-2e span (105 lines): 0 and 0; baseline: no PV-2f line, "observed acting" 0 in the whole file |
| V-4 | AC-2 | gate-efficacy, the paragraph between class-3 limit 7 and `### Requirement (b′)` | 1 paragraph: the class 1, "observed acting" 1; the limits list (7 lines) carries neither | baseline: 0 non-blank lines between limit 7 and (b′) — the paragraph absent |
| V-5 | AC-3 | the Phase A4 region | the learning phrase exactly 1; 0 version tokens, 0 issue references, 0 markdown links | the same phrase in `release/releases/RELEASE_LOG.md` at `origin/main`: 1 line (the probe finds its source); mutation — the phrase dropped from the region → 0 |
| V-6 | durability | the fragile-reference detectors of `core/hooks/lib/fragile-ref-patterns.sh` (LINK, CUTOVER, URL, ISSUEREF), translated to `python3`, over the card's added non-fenced lines (87) | review-discipline 0 hits; gate-evaluation-spec 0; gate-efficacy 0; stage-09: 3 link hits, all on pre-existing links of the two modified lines, under the file's `allow-link`; gate-criteria-spec: 2 link hits (`allow-link`) and 1 cutover hit, the v2.22 entry's cutover bullet (`allow-version-ref`) | planted `v4.03 is exempt` line → CUTOVER 1; planted link and `#4919` → 1 each; near-miss `**v2.22 changes (non-breaking — minor` → 0 |
| V-7 | CIAC-3 | `bash core/deploy/deploy.sh --check`, the Check 62 line | `OK: all 47 gate-coverage register resolution pointer(s) resolve` — CLEAN at 47 | baseline register: 46 pointers, 0 naming the new anchor (head: 47, 1). **Mutation arm NOT-EVALUATED at Stage 6, routed to Stage 7:** running Check 62's computation from a run-directory copy was refused by the script-execution allowlist (`BLOCK-DESTRUCTIVE-022`), and a full `deploy.sh --check` over a mutated tree would append a false `register-runner-resolution` row to the operator's shared warn log, which is the gate's own flip evidence. `[INFERRED]` outcome: the anchor sits on exactly one line of stage-09, the template, and Check 62's R1 test is a fixed-string presence read of the anchor, so deleting that line reads `UNRESOLVED` naming this row |
| V-8 | INT-2 (#5286) | #5286's `**Population:**` regex over the register | 1 row names `stage9-control-backed-dispositions`; it parses: threshold 100, probe a presence census (not `none`), no `;` in the member definition; the row has 5 cells; Surface leads `prose`; 1 segment in the register, unique | near-misses do not parse: an ASCII hyphen for the em-dash, and the threshold without `%` |
| V-9 | CIAC-1 | lines carrying "specified, not yet emitting" in gate-criteria-spec | 14; the v2.22 entry quotes it 0 times | baseline 14 |
| V-10 | INT-3 | `**Schema version:**` and version-entry headers | one `**Schema version:** 2.22`; one `**v2.22 changes` entry; one `**v2.21 changes` (history kept) | mainline read 2.21 with 0 v2.22 entries |
| V-11 | Check 63 | `python3 core/deploy/tools/check-count-structure.py --path <file>`, each of the five files | `FAIL=0 KNOWN=0 STALE=0` on each (gate-efficacy: 4 pairs examined) | `--self-test`: sensitivity examined 1 flagged 1, specificity examined 1 flagged 0 |
| V-12 | links | `python3 core/deploy/tools/check-doc-links.py --target-paths <the five files> --require-targets`; `python3 release/tools/check-release-links.py --check-anchors --diff-base origin/main --files <the five files and this plan>` | no broken link, no broken anchor, over 171 inline links in the five files | `check-doc-links.py --self-test`: 12 fixtures pass |
| Deploy check | no new FAIL line | the same `deploy.sh --check` run | 2 issues: `release-body-drift` (logged-release bodies) and `count-structure` (`SECURITY.md`, `core/references/reference/operator-instance-home-and-isolation-key.md`, `release/references/standards/release-notes-standard.md`) — neither subject is a file this release touches `[INFERRED: attribution by subject file; no baseline run was taken]` | — |
| Package consequence | C4 | the six changed paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled | `release/skills/release-planner/SKILL.md` → `release-planner` |
| ADR index | C4 | did this card add a record under `release/ADRs/`? | ADR index: N/A — this card adds no record under `release/ADRs/` | — |
| Runtime suite | C4 | `runtime-suite-selection-map.md` over the six paths | the no-match row: `test-run/suite-skip` emitted (`spoke:#8579`, payload `suite:NONE; selected-by:no-match; reason:doc-only-change`) | typed read-back: 0 before, 1 after |
| Mirror pairs | C4 | do the six paths include a mirror-pair member? | no — no `core/rules/` path is edited, so neither mirror-pair link form nor path-set parity applies | — |

**`deliverable_state` for #4919:** `deployed-copy-synced` — every path is repository-only, so the release declares no propagation target for it.

### Stage 6 — #5286 (C4 self-verification)

Run by the Stage-6 spoke on #8583 over its six content commits (49168dd3, 3bce42ba, 3be12c00, 4dcf8d2b, dc9312e8, 355782dc), against baselines read from `origin/main` `b1aaa77e`. Engine: `python3` line scans and the repository's own runners. Every arm states its subject-discriminating control.

| ID | Binds | Method | Observed | Control |
|---|---|---|---|---|
| Plan rows | AC-1, AC-2, AC-5 | `bash release/tools/verify-release-plan.sh` on this file | AC-1 PASS (count 3), AC-2 PASS (count 5), AC-5 PASS (count 5); AC-3 and AC-4 declared-deferred to the fixtures below. Roll-up 13 PASS / 1 FAIL / 20 SKIP / 1 UNRUNNABLE / 0 ERROR over 35 records; FCM-2 (the sentinel) and FCM-3 (the ADR) now PASS | the FAIL is #5062's AC-3 and the UNRUNNABLE #4919's reader-graded AC-2, both by design; each #5286 row read FAIL at Commit 0 |
| E-1 | AC-3, CIAC-4 | `python3 core/deploy/tools/check-doc-gates.py --self-test` | PASS, 0 failures. CL10-S (a `prose` row declaring 100%, record `conforming: 0` of 3, `owner: none`) → FAIL `unowned: none`; CL10-P (the same record, `owner: #7`, an open non-member whose body names the population) → PASS `owned-residual #7`; the two fixtures differ in exactly one line, asserted by a difflib comparison | mutation: CL10-S's owner set to `#7` → CL10-S red (3 arms); the owner rule turned to PASS → CL10-S, CL10-T2, CL10-Z red; an unmutated copy → 0 G-CL10 arms red |
| E-2 | AC-4, CD-1 | the same suite | CL10-M (member owner), CL10-C (closed), CL10-PR (pull request), CL10-NF (not found), CL10-OR (other repository), CL10-NN (open non-member whose body names a different population) each FAIL; CL10-U (unreadable owner) NOT-EVALUATED; CL10-CM (owner naming the population only in a comment) PASS; CL10-X (`probe: none`) FAILs as malformed; CL10-CN (a census probe) PASS | mutation: the naming test dropped → CL10-NN red; `probe: none` re-admitted → CL10-X red |
| E-3 | design arms | the same suite | CL10-T (3/3) PASS; CL10-D (no declaration), CL10-R (no record), CL10-B (record bound to another probe), CL10-PO (pin outside the release), CL10-RM (labels out of order), CL10-0 (0% threshold) FAIL; CL10-PU (unfetched pin) and CL10-RU (unresolved plan) NOT-EVALUATED; CL10-N (segment-only change) and CL10-V (a `ci` row) not enrolled; CL10-DW graded from the worktree and, without the worktree repair, `declaration-missing`; CL10-NR (`state: not-run`) unmeasured and carried by an owner | CL10-L: the `--list` enumeration and the grade agree in count; CLI-1..3 drive the command line |
| E-4 | PR-1, FM-2..FM-6 | the same suite | CL10-PF: the plan resolves through `milestone:` frontmatter, 0 or 2 declaring plans → `record-unresolved` naming them. L-1, L-1b (`carried-by-nonmember #7`), L-2, L-3, L-4, L-5, L-6 (`limb-owner-abandoned`) and its control, L-7, L-8 (Composition Lock read before creation), L-9, L-10 (every arm-ii subject opens `limbs:`); CL10-K (`**prose**` Surface enrols), CL10-H (record under the H2 section), CL10-E (`\|` binds to `|`) | mutation: lock date ignored → L-8 red; abandoned owner accepted → L-6 red; markup strip dropped → CL10-K red |
| E-5 | AC-3, AC-4, CIAC-4 (emit path) | `bash core/deploy/deploy.sh --self-test`, group DG | PASS. DG-9: the CL10-S fixture through the real engine and `_dg_report` verdicts `FINDINGS 1 2` and writes exactly one `g-cl10` row naming `obligation:dg-pop` and `unowned: none`; DG-10: the CL10-P fixture verdicts `CLEAN 2` and writes none; DG-11: one subject for a population of two → NOT-EVALUATED; DG-12: a plan renamed after `<head>` is found by `milestone:` and graded, and a slug no plan declares withholds the obligation; DG-13: an unowned limb writes one row whose detail opens `limbs:` | mutation: DG-10 pointed at the CL10-S record → `DG-10 … got 'FINDINGS 1 2'` and `DG-10 an owned obligation must write no g-cl10 row`, both red |
| E-6 | AC-1 | python line scans, gate-criteria-spec | lines carrying `owning work item` 3; lines opening `\| G-CL10 \|` exactly 2 (criterion, Self-Repair) | baseline 0 and 0; `\| G-CL9 \|` reads 2; the plain token `G-CL10` reads 14 here and 2 at the baseline, so it is not used as the AC probe |
| E-7 | AC-2 | stage-13-close | `obligation` (case-insensitive) on 5 lines; `--check-doc-gates --gate g-cl10` on 1 line (two occurrences, the `--list` and the grade, in one paragraph) | baseline 2 and 0; `--gate g-cl8` reads 1 |
| E-8 | AC-5 | the Outcome template | `owning work item` on 5 lines; `**Limb owners:**` once inside the § 2.1 fence; `**Template version:** 2.0` once | baseline 0; `AFTER` reads 35 (baseline 32) |
| E-9 | CIAC-1, INT-3 | gate-criteria-spec | `specified, not yet emitting` on 14 lines, 0 inside the v2.22 entry; one `**v2.22 changes` entry, one `**Schema version:** 2.22`; the entry's ID list reads `G-CL1..G-CL10` | baseline 14 |
| E-10 | CIAC-2, INT-1 | the G-CL10 and G-PR4 rows | G-CL10 names G-PR4; G-PR4 names G-CL10 and carries none of `threshold`, `owning work item`, `population:` | — |
| E-11 | INT-2 | the engine's own register functions over the register at `b1aaa77e`, HEAD and the worktree | `prose` rows in the release range: 1 (#4919's `stage9-control-backed-dispositions`), lacking a segment: 0 — the back-fill is zero edits. Register rows 77 → 78 → 80; Surface `prose` 23 → 24; the two new rows read `deploy-time`; the G-CL10 limits sentence names the accepts-artifact-as-action class in #4919's spelling | base `prose` rows 23 (non-zero), all outside the range |
| E-12 | live | `bash core/deploy/deploy.sh --check-doc-gates --gate g-cl10 --pr 8599 --list` at `355782dc` | exit 0: one SUBJECT, `obligation:stage9-control-backed-dispositions` at 100% with its census probe; four LIMBs, each owned by its card; four OWNER lines; no `declaration-missing`. `--list` writes nothing | the grade was not run against the PR: its record does not exist before Stage 13, so it would only write false `g-cl10` rows to the shared warn log |
| E-13 | CIAC-3 | `bash core/deploy/deploy.sh --check`, the Check 62 line | `OK: all 51 gate-coverage register resolution pointer(s) resolve` — CLEAN at 51 | #4919's head read 47; the two new rows add two `runner-def:` and two `runner-src:` pointers. Mutation arm (an anchor deleted → `UNRESOLVED`) is routed to Stage 7 in a warn-log-redirected sandbox, as #4919's was: a full `--check` over a mutated tree would append a false `register-runner-resolution` row to the shared warn log |
| E-14 | W2 | the same run, Check 28 arm 3 | `OK: g-cl10 shakedown — within the review window (0d of 60d)`; the N/A line names G-CL10 | `g-cl6` and `g-cl8` lines unchanged |
| E-15 | deploy check | the same run | 2 issues, both present at #4919's run: `release-body-drift` and `count-structure` (`SECURITY.md`, `operator-instance-home-and-isolation-key.md`, `release-notes-standard.md`) — no subject is a file this release touches. Check 14: no broken cross-ref in scope; Check 63 controls PASS | — |
| E-16 | durability | the fragile-reference detectors translated to `python3`, over the lines #5286 added (59e8ad6b..head) to durable-corpus files | LINK hits only in files carrying `allow-link`; one CUTOVER hit, the v2.22 cutover bullet `#4919` opened, under `allow-version-ref`; no URL hit; ISSUEREF hits only in this plan, whose root the reference-durability allowlist exempts | planted link, cutover, URL and `#4919` → 1 each; near-miss `template 2.0 is exempt` → 0 |
| E-17 | links, counts | `check-doc-links.py --require-targets` over the eleven edited markdown files; `check-count-structure.py --path` on each | no broken link; `FAIL=0` on the ten files in the lint's scope (the `KNOWN` entries are baseline rows); this plan sits outside it, so its run reads NOT-EVALUATED over zero files, not clean | `check-adr-durability.py --diff-base origin/main` on ADR-228: COUNT 0; its self-test 156/156 |
| Package consequence | C4 | the 13 changed paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled | `release/skills/release-planner/SKILL.md` → `release-planner` |
| ADR index | C4 | did this card add a record under `release/ADRs/`? | ADR index: N/A — this card adds no record under `release/ADRs/`; ADR-228 is under `core/ADRs/`, whose README is curated and has no projected region | — |
| Runtime suite | C4 | `runtime-suite-selection-map.md` over the changed paths | row 4 (`core/deploy/tools/*.py`): `python3 release/tools/check-selftest-coverage.py --run` → ARM A PASSED 78 of 78, `test-run/suite-pass` emitted (`spoke:#8583`; typed read-back 0 → 1). Row 2 (`core/deploy/**`): `deploy.sh --self-test` (E-5) and `test_deploy_path_literals.sh` (10 passed, 0 failed, bash 3.2) run locally; the remaining deploy `run:` steps are the PR's `Shell harness (macOS)` and install-suite jobs | the PR's Ubuntu self-test job fails on `release/tools/cleanup-orphan-state.sh` alone (two active-exclusions cases); `check-doc-gates.py --self-test` reads PASS there |
| Mirror pairs | C4 | do the changed paths include a mirror-pair member? | no — no `core/rules/` path is edited | — |

**`deliverable_state` for #5286:** `deployed-copy-synced` — every path is repository-only, so the release declares no propagation target for it.

### Stage 6 — #5062 (C4 self-verification)

Run by the Stage-6 spoke on #8587 over its seven content commits (01ea3544, d1156982, ed27a27f, f64c02c8, 827f6175, e809f829, 93103447), against baselines read from #5286's head `31ea4119` and `origin/main` `b1aaa77e`. Engine: `python3` line scans and the repository's own runners. Every arm states its subject-discriminating control.

| ID | Binds | Method | Observed | Control |
|---|---|---|---|---|
| Plan rows | AC-3 | `bash release/tools/verify-release-plan.sh` on this file | AC-3 PASS (count 2); AC-1 and AC-2 SKIP (DEFERRED by the render); AC-4 SKIP (deferred to Stage 13). Roll-up 14 PASS / 0 FAIL / 20 SKIP / 1 UNRUNNABLE / 0 ERROR over 35 records | AC-3 was the roll-up's one FAIL at `31ea4119`; same-file control `G3-05` reads 3; the UNRUNNABLE is #4919's reader-graded AC-2, by design |
| V-1 | AC-3 | stage-03 lines carrying `G3-20` ∧ `**Block**` ∧ `absent` | 1 (the A1 row) | sensitivity: `G3-05` ∧ `**Block**` → 1. Specificity: the same predicate over stage-02 → 0, over an input that carries `G3-20` ∧ `absent` on 1 line (A4.9) — the near-miss is present, so the zero is not vacuous |
| V-2 | AC-3 | gate-criteria-spec lines opening `\| G3-20 \|` | 2 (criterion, Self-Repair); the criterion row splits into 9 cells | `\| G3-19 \|` reads 2; baseline 0 |
| V-3 | AC-3, live | `python3 release/tools/bundle-issues-parser.py --issues 4179,5286,4201 --output-format json` | `absent` · `gradable` (3 rows) · `ungradable` (no row) | the same three bodies through `eval_issue` with resolution held resolved: OUT-OF-SCOPE · PASS · FAIL |
| V-4 | machinery | `check-doc-gates.py --self-test`; `bundle-issues-parser.py --self-test` | engine PASS, 0 failures (G-CL10's arms included); parser SELF-TEST OK | mutation, each from an unmodified copy: resolution folded into `grade_declaration` → 2 GD-PARITY arms red; an unknown action passed → 2 red; section-means-gradable → DI-3, DI-4, DI-8, DP-2, DP-3 red; tolerant heading → DI-5, DI-6 red; unloadable engine read `gradable` → DI-9 red; sub-task admitted to the population → DP-1..DP-3 red; unmutated copies → 0 red on these arms |
| Byte identity | Change 1 invariant | pre-split and post-split `eval_issue` over every open `status: bundled` and `status: approved` body, against the repository and the range `b1aaa77e..31ea4119`, retire rows graded | 632 bodies, 632 byte-identical `(verdict, detail)` pairs, 0 differ (verdict mix 413 FAIL / 161 OUT-OF-SCOPE / 58 PASS) | the comparator reports a detail whose findings are reordered as different |
| V-5 | blast radius | `test_bundle_issues_parser.py`; `test_g1_06_priority_carrier.sh`; `test_g1_form_family.sh` | TEST OK (clean-or-deferred 39/40, priority resolved 22/40); 32 passed / 0 failed; 41 passed / 0 failed | the CI precision probe is a workflow step, read at Stage 7 |
| V-6 | CIAC-3 | `bash core/deploy/deploy.sh --check`, the Check 62 line | `OK: all 53 gate-coverage register resolution pointer(s) resolve` | #5286's head read 51; Row M adds one `runner-def:` and one `runner-src:`. stage-03 tokenizes to 0 `RC-NN` and 0 check-bank ids (control: `deploy.sh` → `RC-20`, `RC-26`). The mutation arm (delete `parse_documentation_impact` → `UNRESOLVED`) is routed to Stage 7's warn-log-redirected sandbox, as #4919's and #5286's were |
| V-7 | INT-2 | `bash core/deploy/deploy.sh --check-doc-gates --gate g-cl10 --pr 8599 --list` at `93103447` | exit 0: 2 SUBJECTs — `obligation:doc-impact-gradable-in-bundled` at 100% with its probe, beside #4919's — 4 LIMBs, 4 OWNERs, no `declaration-missing`; Row M not listed (its Surface leads `CI`) | — |
| Row L probe | CD-5 | `python3 release/tools/bundle-issues-parser.py --label "status: bundled" --doc-impact-population`, run once, read-only | exit 0; 226 `MEMBER` lines (210 `req`, 16 kind-form); `SUMMARY … examined=226 conforming=50 not_evaluated=0 out_of_population=44`; 50 gradable / 134 ungradable / 23 misheaded / 19 absent | an independent dump of the same label read 270 issues (226 + 44), 13 of them `sub-task`; the A6.5 review counted 226 applicable and 50 gradable by another method |
| V-9 | CIAC-1 | `specified, not yet emitting` lines in gate-criteria-spec | 14; 0 inside the v2.22 entry | baseline 14 |
| INT-1 | Row M | the row's text | names the `accepts-artifact-as-action` class and places its observation in CI and at every Mode A parse, never on the fixtures' existence | — |
| INT-3 | v2.22 | `**Schema version:**` and version-entry headers | one `**Schema version:** 2.22`; one `**v2.22 changes` entry, its header naming G3-20; its ID list reads `G3-01..G3-20` and `G-CL1..G-CL10`, and `G3-01..G3-19` no longer appears in it | — |
| INT-4 | shared engine | #5286's arms after this card's split | engine self-test PASS with every G-CL10 arm; `deploy.sh --self-test` PASS, group DG (DG-1..DG-13) included; stage-03's `**Limb owners:**` line present once | — |
| Durability | B2 | the fragile-reference detectors of `core/hooks/lib/fragile-ref-patterns.sh` (LINK, CUTOVER, URL, ISSUEREF), translated to `python3`, over the 26 lines this card added to 7 markdown files | 3 hits, each on a modified pre-existing line under its file's marker: the v2.22 cutover bullet (`allow-version-ref`), the release-process Gate line's existing cutover text (`allow-version-ref`), the stage-03 § 7 line's existing link (`allow-link`); 0 URL; 0 ISSUEREF | planted link, cutover, URL and an issue number → 1 each; near-miss `G3-01..G3-20 and status: bundled (doc_impact)` → 0 |
| Links, counts | C4 | `check-doc-links.py --require-targets` over the 7 edited markdown files; `check-release-links.py --roots core release --check-anchors --diff-base origin/main --files <the 7>`; `check-count-structure.py --path` on each | no finding; 0 broken links and 0 anchor findings on added lines; `FAIL=0` on all 7 (release-process `KNOWN=1`, a baseline row) | the release-links engine with no diff base reports 1 pre-existing missing anchor in the field-lifecycle matrix, not on a line this card touched |
| Deploy check | no new FAIL line | the same `deploy.sh --check` run | 2 issues: `release-body-drift` and `count-structure` (`SECURITY.md`, `operator-instance-home-and-isolation-key.md`, `release-notes-standard.md`) — the same two #4919 and #5286 recorded; Check 14 OK; Check 28 template arm OK and the three shakedown lines OK | — |
| Package consequence | C4 | the 9 changed paths on STDIN to `bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` | empty — no rostered skill's package is staled | `release/skills/release-planner/SKILL.md` → `release-planner` |
| ADR index | C4 | did this card add a record under `release/ADRs/`? | ADR index: N/A — this card adds no record under `release/ADRs/` | — |
| Runtime suite | C4 | `runtime-suite-selection-map.md` over the 9 paths | row 4 (`release/tools/*.py`, `core/deploy/tools/*.py`): `python3 release/tools/check-selftest-coverage.py --run` → ARM A PASSED 78 of 78. Row 2 (`core/deploy/**`, the tools README): `deploy.sh --self-test` PASS and `test_deploy_path_literals.sh` 10 passed / 0 failed. `test-run/suite-pass` emitted (`spoke:#8587`; typed read-back 0 → 1) | #5286's row reads back on the same query (1) |
| Mirror pairs | C4 | do the changed paths include a mirror-pair member? | no — no `core/rules/` path is edited | — |
| AC-4 | AC-4 | deferred to Stage 13 Phase A11 | the `g-cl8` row count across the shared warn log's segment set, before and after the A11 run, against the threshold of 10 (plan baseline 8) | — |

**`deliverable_state` for #5062:** `deployed-copy-synced` — every path is repository-only, so the release declares no propagation target for it.

---

## Deployment Execution Log

Populated during Stage 12, per the execution checklist.

---

## Change Description

Authored at Stage 6 Phase C1 by the first Engineering spoke, before the draft pull request opened; each later card refreshes **Issues resolved** and, where its slice changes them, **Key decisions** and **Downstream impact**. Operator-facing; the user-facing release note is a separate Stage-13 artifact.

### Outcome

This release stops the platform from accepting a control's artifact as evidence that the control acted, and makes a declared governance obligation something close-out measures rather than something a release asserts. At Stage 9 a risk that rests on a hook, gate, check or deploy step is accepted only once that control was observed acting where it runs, recorded on a census line and an independently observed line per risk. At Stage 13 every obligation the release declares is measured over its stated population, and a shortfall closes only with a named owner that carries it. Two obligations nothing checked before — a work item's Documentation Impact declaration, and the close-out date the changelog, digest and release note share — gain checks upstream of the close.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #4919 | The accepts-artifact-as-action class is named; PV-2f states what observing a control acting takes; Stage 9 Phase A4 and G-PR4 apply it with a census line and an independent second observation | DONE (landed at Stage 6) |
| #5286 | Gate 13 G-CL10 measures every declared obligation at close and requires an owner that names the population for a shortfall; the Outcome template binds each limb to an owner | DONE (landed at Stage 6) |
| #5062 | Gate 3 G3-20 asserts at Bundle that a card's Documentation Impact is gradable under G-CL8's grammar, read through the one grammar the close gate uses; Triage reads it early and advisory | DONE (landed at Stage 6) |
| #4417 | A new warn-mode deploy check compares the close-out anchor date across the release digest, the changelog and the release note | PENDING (its Stage-6 card) |

### Key decisions

- **D-ReleaseClass:** cross-cutting; #4444 left the milestone. Four stage specs are edited, and 18 × 1.3 = 23 points sits inside the band.
- **D-4919-Routing:** the plan-row control question went to #5903, which owns control-arm authoring discipline.
- **Scope-lock remedies:** each card's adversarial-review remedies were folded into Stage 6. For #4919 that means a census line, an independent `via`, the path/input split in PV-2f, and a Posture cell that states what the evaluator actually does with an unsatisfied G-PR4.
- **#5286 CD-1:** no obligation may be declared unmeasurable; one no instrument reaches is enumerated by hand census, and a shortfall's owner counts only when its body or comments name the population. The gate finds the release plan by its `milestone:` frontmatter, because the version stamp moves it before Stage 13 runs, and the Outcome's limb owners are required from the date the milestone's composition was locked.
- **D-5062-Posture (A′):** G3-20 blocks cards not yet bundled and is advisory on a re-bundle, with the posture divergence recorded as an override. A kind-form card's G3-20 verdict is advisory too, because that family carries no FAIL authority, and an engine outage withholds the verdict once for the batch rather than failing every card.

### Reversibility

**CHEAP — HIGH confidence.** `git revert -m 1` of the merge commit restores `main` byte-for-byte; every new gate ships warn-mode, so nothing blocks on revert, and the version tag is retained, never deleted.

### Downstream impact

- Every later Stage 9 records a Phase A4 control census and one independently observed line per control-backed risk; this release's own Stage 9 is the first worked example.
- Every later Stage 13 runs G-CL10 over the register rows its release adds or modifies; `#5903` takes the next free § 8 identifier, because `PV-2f` is now taken.
- Bundle sessions read G3-20's verdict per card; release close reads the new anchor-agreement check's warn rows.
- Before the first bundle session after merge, one read-only pass over the approved queue — `python3 release/tools/bundle-issues-parser.py --label "status: approved" --doc-impact-population` — hands the operator the per-card repair list, so the repairs land before the session rather than inside it. It is not run by this release; the hub carries it as a Stage 13 follow-up on #8114.

### Cross-references

- Release plan: this file, top section.
- Milestone: `governance-obligations-measured`.
- User-facing release note: authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`, under `release/releases/notes/`.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **#4444 removed at the plan gate** (refresh outcome *amend*). Its Implementation Sequence row, Stage Applicability row, matrix rows (`keep-4444` ×3, `4444-mechanism-plan-lint`, `4444-mechanism-fixture`), four Verification rows, `ac_baseline` entry, Contention-Map parentheticals and option-(B) Outcome limb are dropped | Stage-4 Decision Recorded on #8577; `[BUNDLE AMENDMENT]` on #8577 | **APPLIED** |
| **DEV-2** | **#4179's disposition** — out of scope under G-CL8's issue-scope rule; its warn entry stands. #5062 AC-1 and AC-2 (the back-fill branch) are recorded DEFERRED; AC-4 is unconditional | operator render, 2026-10-28 (carried by the Stage-4 gate) | **RECORDED** — § Verification Plan |
| **DEV-3** | **Collective Review N-way override** on the new-gate initial posture row, for G3-20: "Override: convention new-gate initial posture accepted as diverged because Gate-3 presence criteria block at the gate (G3-05 precedent), while warn-initial binds deploy-time and close gates. Deviation logged for Stage 13 retrospective." | Collective Review scope-lock Decision Recorded, D-5062-Posture (A′) | **RECORDED** for the Stage-13 retrospective |
| **DEV-4** | **Matrix paths added beyond the Stage-4 matrix:** D-5286-MatrixCascade (A) — `.github/g-cl10.enforce`, the ADR, `core/schemas/gate-evaluation-spec.md`, `release/governance/release-process.md` (two paragraphs), `release/references/pipeline/stage-03-bundle.md`, `release/references/standards/bundle-composition-doctrine.md`, `core/deploy/tools/README.md`; D-5062-MatrixCascade (A) — `release/tools/bundle-issues-parser.py`, `core/schemas/field-lifecycle-matrix.md`, `release/governance/release-process.md` (its G3 field-list paragraph), `core/deploy/tools/README.md`; D-DocImpactScope (A) — `release/references/standards/release-corpus-schema.md`, `core/standards/date-variable-convention.md`, `core/deploy/tools/README.md`; #4919's `core/schemas/gate-evaluation-spec.md` (its G-PR4 judgment anchor; one row shared with #5286). The Stage-4 conditional rows are resolved as § File Change Matrix states | Collective Review scope-lock; the four Stage-5 designs | **APPLIED** — § File Change Matrix |
| **DEV-5** | **#5062's own Documentation Impact is incomplete under the render.** It omits `core/schemas/gate-criteria-spec.md`, `core/standards/gate-efficacy-standard.md` and its cascade files, and its stage-02 row resolves through the Triage A4.9 advisory read, not the triage-home condition its reason names. The body is not edited, per the 2026-10-28 render; recorded so the close reader sees what G-CL8 does not grade | #5062 Stage-5 design F-3 / R4; the 2026-10-28 render | **RECORDED** |
| **DEV-6** | **The A6.5 remedies adopted at the scope-lock, applied as Stage-6 instructions, per card.** #4919: CD1 (independent second observation), CD2 (census line and presence probe; the owner-act boundary defined with it), CD3 (PV-2f limb (1) path, limb (2) input), PR-1 (completed Aggregation-Trace; Posture restated); PR-4 is not adopted as a re-type — G-PR4's cells are retained and the v2.22 bullet states that `structural` covers presence over the census. #5286: PR-1, FM-2..FM-6 refinements, and CD-1 (no `probe: none`; hand census; owner names the population). #5062: CD-5, PR-2, FM-2, FM-3, FM-5. #4417: CD-1, CD-2, CD-3, FM-4, FM-5 | Collective Review scope-lock Decision Recorded | **APPLIED** per card as its slice lands; #4919's in § Implementation Sequence |
| **DEV-7** | **#4919 AC-1 re-anchored** (G-PL1): "the Stage-9 GO-residual criteria" names no surface; residual acceptance lives at Phase A4, G-PR4 and the Phase C1 risk acceptance | Stage-4 plan Phase A0.5; Stage-4 gate | **RECORDED** — the card body stays as historical record |
| **DEV-8** | **#4919's open plan-row question routed out** (D-4919-Routing (A)) to #5903 as evidence, with #7899 named as the mechanical consumer; #4919's acceptance criteria are unchanged | Stage-4 Decision Recorded | **RECORDED** |
| **DEV-9** | **#5286 — implementation choices inside the design, each Tier 1 [ADJUST].** (a) G-CL9 was missing from three Gate-13 enumerations (`stage-13-close.md` Phase A tree and judgment-dimension note, `gate-evaluation-spec.md` non-omission note); it is restored beside G-CL10 in the same lines. (b) Counts and enumerations the new row makes stale, reconciled in the same edits: the close-class disposition block (ten close gates, eight no-ops, "the warn-mode gates (`G-CL8`, `G-CL9`, `G-CL10`)", ten dispositions), the stage-13 close-class diagram, the Outcome template's `purpose:` line and its anti-pattern count. (c) The owner read is a directory of each owner's issue JSON and comment bodies (`--owners-dir`) rather than the design's four-column TSV, because CD-1's naming test needs the owner's text and the engine stays offline. (d) The register runner pointers name the arms' entry points `eval_gcl10_obligations` and `eval_gcl10_outcome_limbs` as the design does; each maps over its arm's subjects. (e) FM-1's secondary remedy — an empty population passing as such — is not adopted: it was not among the scope-lock's adopted remedies, so `examined: 0` stays unmeasured and needs an owner, as the design states. (f) The INT-2 back-fill reads "every `prose` row in the release range", per the adversarial review's precision note: that set is #4919's one row, which already carries a parsing segment, so the back-fill is zero edits and the 23 `prose` rows already on `main` are untouched | Stage-5 design on #8582, its A6.5 review and the scope-lock; the Stage-6 brief | **APPLIED** — § Verification Evidence (#5286) |
| **DEV-10** | **#5062 — implementation choices inside the design and its adopted remedies, each Tier 1 [ADJUST].** (a) FM-3 is applied as its option (a): G3-20 is recommend tier for a kind-form card, and the edit reaches § Kind-Form Applicability — its rule sentence names G3-20 and it gains G3-20's disposition row — a passage of `gate-criteria-spec.md` outside the design's Change 3 list, in a file already in the matrix. (b) CD-5(i) needed a parser change the design did not specify: a separate `--doc-impact-population` mode and a `--label` source. The main parse path's exit codes are unchanged; the label listing exits 2 at the 5000 result cap rather than report a population it cannot vouch for; the new mode reads any `type:` label as kind-form, because the licensed kind set is not resolved there (stated in the parser's docstring). (c) The design's `eval_issue` message sentence ("grammar findings, then resolution findings") misdescribed the shipped order; the split keeps the shipped order — line-level findings, then each row's finding in declaration order — byte-identical over 632 live bodies, and the mixed fixture pins it. A placeholder-path pair is added to GD-PARITY, because no prior fixture exercised that grammar check. (d) Row M carries `runner-def:` on the parser and `runner-src:` on the stage-03 read, as the design specifies: the `runner-def`-only rule binds pointers at a `deploy.sh` runner, and stage-03 carries no `RC-NN` or check-bank id. (e) The A′ approved-queue pass is documented (§ #5062 change specification; Change Description → Downstream impact) and not run. (f) The release-process Stage-3 Gate list entry names G3-20's posture and does not restate its predicate | Stage-5 design on #8586, its A6.5 review and the scope-lock; the Stage-6 brief | **APPLIED** — § Verification Evidence (#5062) |

---

## Issue References

- **#4919** — verification-by-declaration: a control's artifact accepted as evidence that it acted (the class card). Closes through the release PR's Issue References block.
- **#5286** — declared obligations measured at close. Closes through the release PR's Issue References block.
- **#5062** — Documentation Impact checked upstream (narrowed). Closes through the release PR's Issue References block.
- **#4417** — close-out anchors agree. Closes through the release PR's Issue References block.
- **#4444** — removed at the plan gate; returned to the approved backlog under epic #5867.
- **#8577 · #8578 · #8579 · #8582 · #8586 · #8590** — the Stage-4 sub-task (plan and gate record), the four Stage-5 sub-tasks (designs, adversarial reviews, scope-lock), and the first Stage-6 sub-task.
- **#5867 · #8114 · #6428** — the parent epics.
- **#5903 · #7899** — the plan-row control question's owner and its mechanical consumer; #5903 also holds the `PV-2f`-is-taken note.
- **#4327** — owner of the note-date writer defect behind the resident close-out anchor divergences.
- **#4179** — the originating Documentation Impact instance, out of scope under G-CL8's issue-scope rule.
- **#7841** — consumes the observed-acting text; not pre-named as an owner.
