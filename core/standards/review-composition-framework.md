---
title: Review Composition Framework
purpose: The framework consolidating cross-stage review composition and agent-correction discipline — how review-class work composes across pipeline stages.
type: standard
framework_version_anchor: "v11.13"
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: review-class skills composing across stages; build-reviewer and pmo-qa-auditor; framework-catalog.md (the review-composition-framework INTERNAL row); the agent-correction discipline
---
<!-- reference-durability: allow-link -->
# Review Composition Framework

**Origin:** Review Composition Framework umbrella initiative (consolidates 11 fragmenting issues identified at 2026-04-24 audit).
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).
**Primary consumers:** Review-class skills ([`build-reviewer`](../../release/skills/build-reviewer/SKILL.md), [`pmo-qa-auditor`](../skills/pmo-qa-auditor/SKILL.md), [`pmo-skill-editor`](../../release/skills/pmo-skill-editor/SKILL.md) Mode D); Stage 5 Solutioning spokes when composing per-stage reviews; future role-skill review surfaces.
**Secondary consumers:** [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) and [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) for cross-stage review composition; [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) for the human-inherited mitigation pool referenced by § 8.
**Status:** Canonical
**Introduced:** km-governance-and-efficacy
**Cutover:** The forcing function applies to downstream review-surface integrations going forward; the release authoring this framework is exempt from its own forcing function (reflexive-pipeline-loop discipline).
**Cross-references:** see § 9 Boundaries + Cross-References and the framework-catalog registry row at [`framework-catalog.md`](../specs/framework-catalog.md).

---

## §1 Purpose + Scope

The platform has accumulated substantial review infrastructure — [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) (the anti-laziness rules + 6-deliverable structure), [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) (named gates G1 / G2 / G3 / G-PR / G-EX / G-CL / G-BR), [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) (3-layer assessment), [`build-reviewer`](../../release/skills/build-reviewer/SKILL.md)'s 12 dimensions, [`pmo-qa-auditor` § 2. Gate Results Table](../skills/pmo-qa-auditor/SKILL.md) (its gate set, read from the auditor rather than restated as a letter range here), [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) (5-phase orchestration) — but lacks a **structural framework** that defines WHICH review fires at WHICH stage with WHAT posture, detail, focus, output, and authority. Current state: review structure is implicit per-skill; the same review object (e.g., dependencies, acceptance criteria, findings) is examined at multiple stages without explicit composition rules; agent-specific failure modes (self-preference bias, hallucinated specificity, context anxiety) have no human-review equivalent and are not addressed at the framework level.

This framework:

- **Organizes** existing review infrastructure under a 7-dimensional taxonomy (§ 2).
- **Catalogs** named review types as full 7-dim tuples (§ 3 Review Catalog).
- **Maps** which catalog entries fire at which pipeline-stage × posture cells (§ 4 Review Map).
- **Defines** composition rules for when the same review object is examined at multiple stages with different parameters (§ 5).
- **Adds** a per-dimension judge-vs-operator agreement Calibration Ledger (§ 6) — rolling agreement < 0.9 flags rubric (not judge) for revision.
- **Specifies** a forcing function for downstream consumers to apply the framework (§ 7).
- **Establishes** an Agent-Correction Layer (§ 8) addressing 3 novel agent-only failure modes + referencing ≥ 6 of the human-inherited mitigations from [`review-discipline-principles.md § 1`](../disciplines/review-discipline-principles.md).
- **Bounds** scope explicitly (§ 9).

### In scope

- Cross-stage review composition rules.
- Per-dimension calibration mechanism for judge-vs-operator agreement.
- Agent-specific failure-mode framework at REQUIREMENT level (implementations deferred to downstream issues).
- Cross-reference seams between this framework and existing reference docs ([`review-discipline-principles.md`](../disciplines/review-discipline-principles.md), [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md), [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md)).

### Out of scope

- Implementation of the 3 novel agent failure-mode mechanisms (cross-family judge wiring, citation-grep tool, exit-branch templates). Deferred per the umbrella issue body §Out of Scope; spawned as separate downstream issues only when operator decides.
- Modifications to existing review-class skill SKILL.md files (build-reviewer / pmo-qa-auditor / pmo-skill-editor). Integration is BY REFERENCE only; skill-side citations are separate downstream work tracked outside.
- Pipeline-stage modifications to [`.claude/rules/release-process.md`](../../release/governance/release-process.md) or [`pipeline/`](../../release/references/pipeline/) docs.
- Disposition (close / relabel / de-milestone) of the 11 fragmenting issues that motivated this framework. Operator-driven post-cutover at their discretion.
- Generalization to non-PMO contexts.

---

## §2 Goal — 7-Dimensional Review Taxonomy

Every review the platform composes is classifiable against these 7 dimensions. The taxonomy is consolidating, not replacing: existing reviews (gates, QC checkpoints, skill modes) project onto these dimensions; this framework names the dimensions and supplies the worked examples that ground them.

| # | Dimension | Enum values | What it answers |
|---|---|---|---|
| 1 | **WHEN** | Stages 1-13 | At which point in the 13-stage pipeline does the review fire? |
| 2 | **WHAT** | artifact / decision / output / finding / process | What kind of thing is being reviewed? |
| 3 | **WHO / POSTURE** | self / peer / adversarial / expert / cross-cutting | Who reviews, and from what stance? |
| 4 | **DETAIL** | structural / surface / substantive / forensic / holistic | How deep does the review go? |
| 5 | **FOCUS** | correctness / completeness / coherence / alignment / risk / cost / reversibility / scope / ordering | What axis is the review optimizing along? |
| 6 | **OUTPUT** | gate / scorecard / findings / recommendations / triage | What does the review produce? |
| 7 | **AUTHORITY** | gating / advisory / calibration / audit | What does the review's output authorize? |

### §2.1 Concept-model — Tier-A activated design artifact

```
                       Review Composition Taxonomy (7 dimensions)

         ┌─────────────────────────────────────────────────────────────────┐
         │                       A composed review                         │
         │                                                                 │
         │   ┌────────┐  ┌────────┐  ┌──────────────┐  ┌────────┐          │
         │   │ WHEN   │  │ WHAT   │  │ WHO/POSTURE  │  │ DETAIL │  ...     │
         │   │ (1-13) │  │ (5 vs) │  │ (5 vs)       │  │ (5 vs) │          │
         │   └────────┘  └────────┘  └──────────────┘  └────────┘          │
         │                                                                 │
         │   ┌────────┐  ┌────────────┐  ┌──────────────┐                  │
         │   │ FOCUS  │  │ OUTPUT     │  │ AUTHORITY    │                  │
         │   │ (9 vs) │  │ (5 vs)     │  │ (4 vs)       │                  │
         │   └────────┘  └────────────┘  └──────────────┘                  │
         │                                                                 │
         │           ↓ projects onto                                       │
         │                                                                 │
         │   Review Catalog entry (named tuple, RC- prefix)                │
         │           ↓ surfaces at                                         │
         │   Review Map cell (stage × posture)                             │
         │           ↓ composes via                                        │
         │   Composition Rules (when same object reviewed multiple stages) │
         │           ↓ calibrates via                                      │
         │   Calibration Ledger (per-dimension judge-vs-operator)          │
         │                                                                 │
         └─────────────────────────────────────────────────────────────────┘
```

**Worked example per dimension** (one composed review used as a probe across all 7 dimensions):

| Dim | Value | Worked example (Stage-3 Bundle Capacity Review) |
|---|---|---|
| WHEN | Stage 3 (Bundle) | Fires at Stage 3 Phase A capacity assessment, before the operator approves the Milestone composition. |
| WHAT | artifact = milestone composition | The review object is the proposed Milestone's set of issues + dependency graph + file-contention map. |
| WHO/POSTURE | peer | Performed by the Stage 3 Bundle spoke (peer to the operator who approves; not the operator). |
| DETAIL | structural | Verifies declared dependencies are in compatible states; verifies no circular cycles; verifies version assignment + bundle rationale present. |
| FOCUS | capacity + ordering | Are file contentions resolvable through sequencing? Is the bundle size within capacity heuristics? |
| OUTPUT | scorecard | Produces a per-criterion PASS/FAIL row (one row per Gate-3 criterion in `gate-criteria-spec.md` § Gate 3) plus an aggregated capacity score. |
| AUTHORITY | gating | Operator approval required before Stage 4 Planning may begin; gate failure blocks transition without override. |

The same probe (a real platform review) classifies cleanly against all 7 dimensions — confirming the taxonomy is COMPLETE for routine reviews. Reviews that fail to classify against one or more dimensions are flagged as candidates for either (a) refinement of the review's design, or (b) extension of the dimension enum (governance-mediated; not unilateral by a spoke).

### Dimension enum value justifications

- **WHEN = Stages 1-13** — verbatim alignment with [`release-process.md`](../../release/governance/release-process.md) 13-stage pipeline. No choice; this is the pipeline.
- **WHAT = artifact / decision / output / finding / process** — enumerates the 5 things that can be reviewed: artifacts (files, comments, schemas), decisions (D-decisions, scope-locks, gate decisions), outputs (spoke comments, briefings, change summaries), findings (review outputs being meta-reviewed), and processes (multi-step procedures themselves under review).
- **WHO/POSTURE = self / peer / adversarial / expert / cross-cutting** — covers the 5 review postures named in the persona/process literature and grounded in [`review-discipline-principles.md § 7`](../disciplines/review-discipline-principles.md). Self = the agent that produced the output reviews it; Peer = another agent at same authority tier; Adversarial = explicitly looking for failure; Expert = persona-specialized authority (e.g., Principal Engineer at Stage 5); Cross-cutting = whole-release scope.
- **DETAIL = structural / surface / substantive / forensic / holistic** — coarse to fine. Structural = "does it conform to schema/format"; Surface = "does it look right" (low-confidence, fast); Substantive = "does the content match its goal" (the default); Forensic = "exactly where did this go wrong" (root-cause depth); Holistic = "is the whole consistent" (cross-component).
- **FOCUS = correctness / completeness / coherence / alignment / risk / cost / reversibility / scope / ordering** — 9 named focus axes; each maps to existing platform concerns. Reversibility composes with [`reversibility-protocol.md`](../specs/reversibility-protocol.md); scope composes with the CLAUDE.md scope guardrails; ordering applies to dependency sequencing.
- **OUTPUT = gate / scorecard / findings / recommendations / triage** — 5 named output forms. Gate = binary PASS/FAIL; Scorecard = scaled rating (1-5 per [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md)); Findings = enumerated defects per [`review-discipline-principles.md § 5(a)`](../disciplines/review-discipline-principles.md); Recommendations = actionable suggestions per [`decision-discipline.md`](../disciplines/decision-discipline.md); Triage = classification + routing.
- **AUTHORITY = gating / advisory / calibration / audit** — 4 named authority tiers. Gating = blocks progression (PASS required); Advisory = surfaces concerns but does not block; Calibration = generates data for future-rubric-tuning (not blocking); Audit = retrospective, post-deploy review.

---

## §3 Review Catalog

The Review Catalog names every recurring composed review with the prefix `RC-<WHEN>-<short-name>`. The naming scheme establishes a new namespace distinct from gate IDs (`G3-08` names a gate CRITERION, not a whole review), QC IDs (`QC4-05` names a checkpoint criterion), Mode letters (`Mode D` names a skill mode), or persona names (`Stage 5 Principal Engineer` names a role-stance combination). Catalog entries carry the FULL 7-dim tuple.

**Seed catalog (one entry minimum per pipeline stage 1-13; AC-3 mandate):**

| ID | Name | WHEN | WHAT | WHO | DETAIL | FOCUS | OUTPUT | AUTHORITY |
|---|---|---|---|---|---|---|---|---|
| RC-1-intake-readiness | Intake Quality Gate (G1) | Stage 1 | artifact (issue body) | peer | structural | completeness + verifiability | gate | gating |
| RC-2-triage-decision | Triage Decision Review (G2) | Stage 2 | decision (priority + Approved/Deferred/Rejected) | peer | substantive | correctness + ordering | gate | gating |
| RC-3-bundle-capacity | Bundle Capacity Review (G3) | Stage 3 | artifact (milestone composition) | peer | structural | capacity + ordering | scorecard | gating |
| RC-4-release-plan-coherence | Release Plan Coherence Review | Stage 4 | artifact (release plan + change-spec matrix) | peer | substantive | coherence + completeness | findings | gating |
| RC-5-blast-radius-revalidation | Blast-Radius + Dependency Re-Validation (QC2) | Stage 5 | decision (design + implicit deps) | adversarial | substantive | risk + completeness | findings | gating |
| RC-5-adversarial-design-review | Independent Adversarial Design Review (Phase A6.5) | Stage 5 | output (Stage 5 spoke output artifact) | adversarial | substantive | risk + correctness + reversibility | findings | advisory |
| RC-5-collective-design-coherence | Collective Review Cross-Issue Coherence | Stage 5 (release-level) | output (set of Solutioning outputs) | cross-cutting | holistic | coherence + alignment | findings | gating |
| RC-6-engineering-self-check | Engineering Self-Review Pre-PR | Stage 6 | artifact (PR change-set) | self | substantive | correctness | findings | advisory |
| RC-7-dt-pass-1 | DT Pass 1 Quality Review | Stage 7 | output (Engineering PR + AC evidence) | adversarial | substantive | correctness + completeness | findings | gating |
| RC-8-qa-acceptance | QA Acceptance Review (QC3) | Stage 8 | output (DT-cleared PR) | expert | substantive | correctness + completeness + alignment | gate | gating |
| RC-9-plan-review | Plan Review Final Gate | Stage 9 | output (release plan + PR + DT/QA evidence) | expert | holistic | risk + reversibility + cumulative-risk | gate | gating |
| RC-10-dry-run-validation | Dry-Run Validation (when compression exceptions apply) | Stage 10 | process (deployment procedure) | peer | substantive | correctness | findings | gating |
| RC-11-snapshot-verification | Snapshot Verification (git-native — automatic) | Stage 11 | process (git history) | self | structural | completeness | gate | gating |
| RC-12-execute-readiness | Execute Readiness Pre-Merge | Stage 12 | artifact (PR metadata + main divergence) | peer | structural | completeness | gate | gating |
| RC-13-post-deploy-verification | Post-Deploy Verification (QC4) | Stage 13 | output (deployed state) | peer | structural | correctness + completeness | gate | gating |
| RC-13-close-postmortem | Close-Time Postmortem + Learnings | Stage 13 | process (release execution) | cross-cutting | forensic | risk + cost + scope | findings | audit |
| RC-13-design-artifact-refresh | Design-Artifact Refresh-Gate (G-CL6) | Stage 13 | artifact (Tier-A activated artifacts) | self | structural | completeness | gate | gating |

**Naming convention rule:** RC-prefix entries are reserved for COMPOSED reviews (named bundles of the 7-dim tuple). Gate criteria (`G3-08`), QC checkpoints (`QC4-05`), skill modes (`Mode D`), and persona-roles (`Stage 5 Principal Engineer`) remain owned by their respective specs. The Review Catalog references them as sub-components, but does not rename them.

**Catalog extension:** New named reviews enter via a row append + cross-update to § 4 (Review Map cell-reference). Catalog entries are governed via standard "No ungoverned changes" protocol (Issue + plan + approval before append).

---

## §4 Review Map — Tier-A activated design artifact

The Review Map matrix specifies which Catalog entries fire at which pipeline-stage × posture cells. Rows = pipeline stages 1-13. Columns = the 5 postures from § 2 WHO dim. Cell content = catalog refs (RC-* IDs) + a short cell-specific posture preamble.

**Matrix capacity:** 13 stages × 5 postures = 65 cells. AC-3 requires ≥ 1 named review per stage (13 minimum cells populated). The seed Map below populates 30+ cells across the diagonal of "where review actually happens at each stage" — leaving room for the matrix to grow as new RC-* catalog entries land at the periphery (e.g., expert posture at Stages 6 / 10 / 12, currently sparse).

| Stage | Self | Peer | Adversarial | Expert | Cross-cutting |
|---|---|---|---|---|---|
| **1 Intake** | Author drafts → re-reads own body before submit | **RC-1-intake-readiness** (Intake Quality Gate, G1; structural completeness check) | — | — | — |
| **2 Triage** | — | **RC-2-triage-decision** (priority + Approved/Deferred/Rejected) | — | — | — |
| **3 Bundle** | — | **RC-3-bundle-capacity** (G3 scorecard; capacity + ordering) | — | — | — |
| **4 Planning** | Spoke re-reads own change-spec matrix for self-coherence | **RC-4-release-plan-coherence** (peer review against governance) | — | — | — |
| **5 Solutioning** | Spoke validates own design against M1/M2/M3 ceremonies; M2 Opposing View per `decision-discipline.md` § 2.2 is a within-spoke ceremony, NOT an independent-reviewer adversarial cell | **RC-5-blast-radius-revalidation** (QC2 re-check after solutioning reveals deps) | **RC-5-adversarial-design-review** (Phase A6.5 independent-reviewer adversarial review; separate `pmo-adversarial` agent reviews Stage 5 spoke output BEFORE Collective Review entry; advisory findings) | Principal-Engineer persona per `release-personas.md` § Stage 5 | **RC-5-collective-design-coherence** (post-Solutioning release-level scope-lock) |
| **6 Engineering** | **RC-6-engineering-self-check** (pre-PR self-review against AC + governance) | — | — | — | — |
| **7 Dev Testing** | — | — | **RC-7-dt-pass-1** (Layer 2 automated review — adversarial by design per `pipeline/stage-07-dev-testing.md`) | — | — |
| **8 QA Testing** | — | — | — | **RC-8-qa-acceptance** (QC3; acceptance authority per `pipeline/stage-08-qa-testing.md`) | — |
| **9 Plan Review** | — | — | — | **RC-9-plan-review** (final operator gate — Tier 3 human-only per `release-process.md` Stage 9) | — |
| **10 Dry Run** | — | **RC-10-dry-run-validation** (when compression exceptions apply) | — | — | — |
| **11 Snapshot** | **RC-11-snapshot-verification** (git history is the snapshot — self-attestation via `git log`) | — | — | — | — |
| **12 Execute** | — | **RC-12-execute-readiness** (PR metadata + main-divergence pre-merge check) | — | — | — |
| **13 Close** | **RC-13-design-artifact-refresh** (G-CL6 self-attestation per `design-artifact-standard.md § 8`) | **RC-13-post-deploy-verification** (QC4) | — | — | **RC-13-close-postmortem** (forensic — release-wide learnings) |

**Cell posture-preamble conventions:**

- **Self cells:** the agent that produced the output is the reviewer. Sufficient ONLY where the review object's risk class is low + structural (Stages 1 / 6 / 11 / 13-G-CL6). Insufficient at Stages 2-3-5-7-8-9-12-13-QC4 — those stages require peer / adversarial / expert / cross-cutting posture per cell.
- **Peer cells:** another agent at the same authority tier reviews. Default posture for routine gates.
- **Adversarial cells:** the reviewer explicitly looks for failure. Stage 5 M2 Opposing View and Stage 7 DT are the canonical adversarial cells.
- **Expert cells:** persona-specialized authority. Stage 8 QA and Stage 9 Plan Review are expert by design.
- **Cross-cutting cells:** whole-release scope. Stage 5 Collective Review (post-Solutioning scope-lock) and Stage 13 Close Postmortem are the canonical cross-cutting cells.

**Gating default per WHO × WHEN intersection:** AUTHORITY = `gating` for cells where WHO = `adversarial` × WHEN ∈ {2, 3, 5, 7, 8, 9, 12, 13} (existing gate criteria); `advisory` elsewhere; `calibration` for all cells with active ledger (currently RC-7-dt-pass-1 × FOCUS=correctness per § 6); `audit` for retrospective cells (RC-13-close-postmortem).

**Sparse-cell semantics:** A `—` in a cell means "no named composed review fires here under the current Map." It does NOT mean "no review happens" — it means the review (if any) is not a recurring composed unit warranting a catalog entry. Sparse cells are routine review-design candidates as the Catalog grows.

---

## §5 Composition Rules

When the same review object is examined at multiple pipeline stages, the Composition Rules specify what DIFFERS across stages (DETAIL × FOCUS × AUTHORITY parameters) and how late-stage findings inform earlier-stage rubric tuning (via § 6 Calibration Ledger, not via in-band feedback).

### §5.1 Worked examples table (≥ 3 rows; AC-6 mandate)

| # | Object | Earlier Stage | (DETAIL × FOCUS × AUTHORITY) Earlier | Later Stage | (DETAIL × FOCUS × AUTHORITY) Later | Composition rule |
|---|---|---|---|---|---|---|
| CR-1 | **Dependencies** | Stage 2 (Triage G2-04) | structural × completeness × gating | Stage 5 (Solutioning QC2) | substantive × completeness + ordering × gating | Same object; Earlier verifies declared dep-state compatibility from body `FS+0d` refs; Later re-validates after solutioning reveals NEW implicit deps (blast-radius). Earlier is data-driven; Later is design-revealed. |
| CR-2 | **Acceptance criteria (AC)** | Stage 1 (Intake gate G1-05a) | structural × verifiability × gating | Stage 8 (QA QC3-04) | substantive × completeness × gating | Same object; Earlier verifies AC has verifiable-verb prefix + named predicate; Later verifies implementation evidence satisfies the AC. Earlier is presence-test; Later is satisfaction-test. |
| CR-3 | **Findings** (in a review output) | Stage 7 (DT Pass 1 Findings) | substantive × correctness × gating | Stage 8 (QA acceptance) / Stage 9 (Plan Review) | holistic × cumulative-risk × gating | Same object; Earlier produces per-artifact findings with root-cause format; Later aggregates findings into cumulative-risk + gates release. Earlier is per-issue; Later is release-wide. |
| (template) | `<object>` | Stage `<N>` | `<D> × <F> × <A>` | Stage `<M>` | `<D> × <F> × <A>` | `<why same object reviewed at multiple stages; what differs; what stays the same; how late-stage informs earlier-stage tuning>` |

### §5.2 Composition principle

When the same object reviewed at multiple stages produces different verdicts (e.g., Stage 2 says deps OK; Stage 5 finds an unregistered implicit dep), the LATER verdict wins for the object's current state. The EARLIER review is not invalidated retrospectively — it answered the question correctly given the information available at that stage. The composition rule TYPE (structural vs substantive) MUST differ: if both stages applied the same DETAIL value to the same object, one of them is redundant (governance-mediated removal).

### §5.3 Late-stage → earlier-stage tuning mechanism

Late-stage observations DO inform earlier-stage rubric tuning, but NOT in-band (during the active release). The mechanism is calibration-driven:

1. The § 6 Calibration Ledger records judge-vs-operator agreement per (dimension × stage) cell.
2. When the rolling agreement metric for a cell drops below 0.9 over a 5-release window, the framework REQUIRES rubric revision at the dimension's earlier-stage cells via a `[CALIBRATE-AFTER-N]` annotation in the relevant Review Catalog entry.
3. Rubric revisions apply via standard governance protocol (Stage 5 spec → operator approval → Stage 6 commit on next release).

The mechanism is **NOT real-time feedback** between active-release stages. It IS calibration-driven rubric maintenance across releases — the framework's defense against "review rot" where rubrics get repeatedly applied without re-calibration against operator judgment.

---

## §6 Calibration Ledger Schema

The Calibration Ledger records per-(dimension × stage) judge-vs-operator agreement over time. The ledger lives at [`<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/) (peer to the existing `results/calibration-data.md` which carries the distinct 12-column stage-gate calibration schema). The judge-calibration ledger is per-DIMENSION granularity, not per-STAGE-BOUNDARY.

### §6.1 Per-dimension ledger schema

Each dimension under active calibration gets a dedicated file at `judge-calibration/<focus>-<dimension>-stage-<N>-<short-name>.md`. The file's body is a markdown table with the following columns:

| Column | Type | Purpose |
|---|---|---|
| `date` | YYYY-MM-DD | When the calibration row was captured. |
| `release` | string (`vX.Y`) | Which release the judge-vs-operator pair occurred in. |
| `subtask` | `#NNNN` | The originating sub-task (DT / QA / Plan Review) where judge + operator both rated the same artifact. |
| `judge_verdict` | enum (`PASS` / `FAIL` / `CAVEATS`) | The LLM judge's verdict. |
| `operator_verdict` | enum (`PASS` / `FAIL` / `CAVEATS`) | The operator's verdict. |
| `agreement` | float [0,1] | 1.0 if verdicts match; 0.0 if disagreement. (Binary per-row; rolling computed in next column.) |
| `rolling_window_mean` | float [0,1] | Mean of `agreement` over the last 5 release windows. Recomputed on each row insertion. |
| `flag` | enum (`yes` / `no`) | `yes` when `rolling_window_mean < 0.9` AND ≥ 5 prior rows exist. Signals rubric-revision candidate. |

### §6.2 Agreement-metric mathematics

For 2-rater agreement (judge + operator), the row-level metric is binary verdict-match. Aggregated across rows, the metric escalates to **Cohen κ** (per [eval-writer `references/canonical-workflow.md` L49 platform precedent](../skills/eval-writer/references/canonical-workflow.md)). When the ledger expands to ≥ 2 judges (e.g., cross-family PoLL panel per [arXiv:2404.18796]), the metric escalates to **Krippendorff α**. The 0.9 threshold is loose by α/κ-purist standards (research papers typically use 0.8 for substantial agreement) but functions as a CALIBRATION TRIPWIRE not a quality bar — it flags rubric-revision opportunities, not judge replacement.

### §6.3 What the flag actually means

`flag = yes` does NOT mean the judge is "bad." It means the JUDGE-RUBRIC pair is producing systematic disagreement with operator judgment. Three possible root causes:

1. **Rubric drift** — the rubric is no longer expressing what the operator actually cares about. Fix: revise the rubric.
2. **Judge bias** — the judge model has systematic bias against (or for) the dimension. Fix: rotate judge model family (per § 8.1 cross-family requirement).
3. **Operator drift** — the operator's standard has shifted; the rubric still expresses the prior standard correctly. Fix: re-baseline the operator's stated standard, then revise the rubric.

The framework does NOT auto-classify which root cause applies. The flag SURFACES the gap; the operator + the rubric author diagnose.

### §6.4 What the ledger does NOT do (boundaries)

- The ledger does NOT replace [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) Layer 3 (Calibration) stage-gate accuracy tracking. That mechanism lives at [`calibration-data.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) with a 12-column stage-gate schema. The two ledgers cover distinct domains (per-dimension judge-vs-operator vs. per-stage-boundary accuracy).
- The ledger does NOT prescribe judge replacement. It SURFACES a rubric-revision opportunity; the operator decides whether to revise the rubric, rotate the judge, or accept the residual.
- The ledger is NOT a backfill artifact. New dimensions enter as they are operationally needed; the framework's seed populates one dimension (FOCUS=correctness × Stage 7 DT) to demonstrate the schema (per AC-7).

### §6.5 Cross-reference

The full schema, creation protocol, and seed dimension are documented at the directory README: [`<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/README.md`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/README.md). The seed dimension is [`focus-correctness-stage-7-dt.md`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/focus-correctness-stage-7-dt.md).

---

## §7 Forcing Function

The framework's enforcement model is layered, matching the platform's existing review-discipline enforcement pattern (Stage 5 design discipline + Stage 9 Plan Review + Stage 13 G-CL6 design-artifact refresh):

### §7.1 At Stage 5 — Solutioning

When a Stage 5 spoke proposes a NEW review (a review type not in the Catalog), the spoke MUST:

1. Specify the full 7-dim tuple (WHEN × WHAT × WHO × DETAIL × FOCUS × OUTPUT × AUTHORITY) for the new review.
2. Propose a Catalog ID per the `RC-<WHEN>-<short-name>` convention.
3. Propose a Map cell placement (or argue why no Map cell is appropriate — i.e., one-off review not warranting catalog entry).
4. If the review revises an existing Catalog entry's tuple, surface the change as a Tier 2 [SCOPE CHANGE] per [`.claude/rules/release-process.md`](../../release/governance/release-process.md) Inter-Stage Feedback Protocol; the change is NOT applied silently.

### §7.2 At Stage 9 — Plan Review

The operator verifies that any release introducing new review-class behavior (new gate, new QC checkpoint, new skill mode) has registered the corresponding RC-* Catalog entry + Map cell update in the PR diff. Missing registration is a Plan Review NO-GO.

### §7.3 At Stage 13 — Close

The Close spoke verifies the § 4 Review Map and § 3 Catalog are current with all Catalog additions / modifications introduced in the release. G-CL6 (design-artifact refresh-gate per [`design-artifact-standard.md § 8`](design-artifact-standard.md)) verifies the §2.1 and §4 Tier-A activated concept-model artifacts have been refreshed when the release's changes touch them.

### §7.4 Calibration cadence

The § 6 Calibration Ledger updates per-release at Stage 13 Close for dimensions under active calibration (initial: FOCUS=correctness × Stage 7 DT). When a dimension's rolling agreement drops below 0.9 over 5 releases, the framework requires a Stage 5 rubric revision in a subsequent release (per § 5.3 mechanism).

### §7.5 Reflexive-pipeline-loop exemption

The release authoring this framework is exempt from its own forcing function — Stage 5 spec authoring + Stage 6 Engineering implementing + Stage 9 Plan Review cannot fire the framework's requirements on the framework itself (the rule shipping in a release cannot fire on that release's own bundling without creating a reflexive loop). The forcing function activates for downstream review-surface integrations going forward.

---

## §8 Agent-Correction Layer

The Agent-Correction Layer addresses 3 **novel** agent-only failure modes that have no human-review equivalent + references ≥ 6 **human-inherited** mitigations from [`review-discipline-principles.md § 1`](../disciplines/review-discipline-principles.md)'s anti-laziness rules.

**Implementation status:** All 3 novel-mode mechanisms are specified at REQUIREMENT level only. Concrete implementations (cross-family judge wiring, citation-grep tool, exit-branch templates) are deferred to downstream issues NOT yet created — operator decides whether/when to spawn them.

### §8.1 N-1 — Self-preference bias

- **Failure-mode description:** Judge LLM systematically over-rates output from its own model family. Quantified at approximately +10% positive bias per [arXiv:2410.21819](https://arxiv.org/abs/2410.21819).
- **Observable indicator:** Same generator + judge from the same model family produces a systematically higher pass rate than a cross-family judge on identical artifacts. Detectable via A/B comparison (same artifact, two judge configurations) or longitudinal calibration ledger divergence.
- **Requirement-level mechanism:** Gating reviews (AUTHORITY=gating in the Catalog) REQUIRE generator and judge from different model families. E.g., a Claude-family generator's output is judged by a GPT-family or Gemini-family judge, NOT another Claude-family judge. Advisory and calibration reviews MAY use same-family judging with the bias acknowledged.
- **Verification-of-mitigation criterion:** Calibration ledger row for a (dimension × stage) cell shows judge-vs-operator agreement ≥ 0.85 baseline at AUTHORITY=gating tier. Cross-family judge agreement ≥ 0.85 baseline required for gating-class compositions; below threshold flags the RUBRIC (not the judge) for revision per § 6.3.
- **Implementation:** DEFERRED to downstream issue (cross-family judge wiring is non-trivial: requires runtime judge-family selection, model-family registry, and audit-trail of which judge family rated which artifact). Operator decides whether to spawn.
- **Prior art:** [`eval-writer/SKILL.md L212`](../skills/eval-writer/SKILL.md) mandates cross-family judging for eval-suite calibration (one slice of N-1). The framework's N-1 mechanism GENERALIZES this from eval-suite scope to whole-platform-review scope.

### §8.2 N-2 — Hallucinated specificity

- **Failure-mode description:** Agent fabricates `file:line` refs, quoted text, rule IDs, or other specifics under thoroughness pressure (e.g., to demonstrate evidence quality). Per [arXiv:2512.12117](https://arxiv.org/abs/2512.12117) on citation grounding, this is a documented agent failure mode distinct from generic hallucination — it is structured fabrication of verifiable-looking citations.
- **Observable indicator:** Citations do not resolve when checked. `grep <quoted text> <cited file>` returns 0 hits. Cited line numbers are out of file range. Quoted Rule IDs do not exist in the cited source.
- **Requirement-level mechanism:** All citations (file:line, quoted text, rule ID) in review FINDINGS MUST be programmatically verifiable. The review process embeds a CITATION-GREP pre-emit check: for each citation in the finding draft, run `grep` against the cited file and verify the cited text resolves. Unresolved citations either get corrected pre-emit OR removed pre-emit.
- **Verification-of-mitigation criterion:** Verification grep-step emits a `citation-integrity` sub-finding per release. Releases with ≥ 1 unresolved citation BLOCK enforce-mode AUTHORITY=gating. Warn-mode initially; flip to enforce after shakedown per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) precedent.
- **Implementation:** DEFERRED to downstream issue (citation-grep tooling is non-trivial: requires syntax-aware parsing to distinguish quoted text from prose, plus cross-file path resolution). Operator decides whether to spawn.
- **Prior art:** the verify-before-recommend discipline is the operator-validated principle from which this mode's requirement derives.

### §8.3 N-3 — Context anxiety

- **Failure-mode description:** Premature task wrap-up as the agent's token budget approaches its limit (Sonnet 4.5+). Reviewer marks dimensions as "checked" without supplying evidence to avoid running out of context window.
- **Observable indicator:** Review output truncates near the end of the token budget. Final dimensions carry less evidence density than initial ones. Sudden compaction of detailed analysis. Review terminates with bare "checked" claims instead of evidence.
- **Requirement-level mechanism:** Review templates have an explicit `unable_to_complete_with_quality` EXIT BRANCH. When token-budget pressure exceeds threshold (e.g., ≥ 80% of available budget consumed and remaining dimensions still require evidence-density), the reviewer MUST take the exit branch rather than emit shallow coverage. The exit branch's output explicitly states "review halted at <dimension N> due to context-budget pressure" and routes the residual review to a fresh session.
- **Verification-of-mitigation criterion:** Reviews ending with the exit branch PASS [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) Rule 3 (no finding-free dimensions). Reviews ending with token-budget-pressured truncation FAIL Rule 3.
- **Implementation:** DEFERRED to downstream issue (exit-branch templates are non-trivial: require runtime token-budget inspection + template injection per skill). Operator decides whether to spawn.
- **Prior art:** None — N-3 is the most novel of the 3 modes (no human equivalent exists; humans plan around fatigue, not token budgets).

### §8.4 Human-inherited mitigations (≥ 6 of the anti-laziness pool)

The Agent-Correction Layer inherits the anti-laziness rules from [`review-discipline-principles.md § 1`](../disciplines/review-discipline-principles.md). The 6 rules below are the highest-leverage subset for agent-context application; the full rule pool remains the canonical source and its cardinality is owned there, not restated here. Naming ≥ 6 satisfies AC-4's explicit requirement.

| Rule # | Human-context formulation | Agent-context application |
|---|---|---|
| **Rule 1** | "No surface-level passes" — every dimension terminates in concrete finding or concrete verification. | An agent reviewer that emits "section looks well-structured" without identifying a specific issue OR a specific verification statement violates Rule 1. Agent fix: require the review template to enforce per-dimension termination in either `{finding: ...}` or `{verification: ...}` — never both empty. |
| **Rule 2** | "No assumption of correctness" — prior remediation does not equal current correctness. | An agent reviewer that defers to a prior PR/issue/release outcome ("this was reviewed 3 times already, must be fine") violates Rule 2. Agent fix: review the target fresh regardless of history; prior sign-off is metadata, not evidence. |
| **Rule 3** | "No finding-free dimensions" — zero findings requires positive evidence, not absence of effort. | An agent reviewer that emits a dimension with no findings AND no verification statement violates Rule 3. Composes with N-3 (Context anxiety) — context-pressured truncation is the dominant cause of this violation. Agent fix: enforce the N-3 exit branch when context budget is insufficient for evidence-grade review. |
| **Rule 4** | "No symptom-only findings" — findings must identify root cause, not just symptom. | An agent reviewer that emits "test failed" without naming WHY violates Rule 4. Agent fix: review template embeds root-cause sub-field per finding; finding draft cannot serialize without root-cause field populated. |
| **Rule 7** | "No severity inflation" — severity is measured against thresholds, not vibes. | An agent reviewer that elevates a low-severity finding to medium to "draw attention" violates Rule 7. Agent fix: severity-class definition in review template is normative; review draft fails template validation if severity does not match observable indicators. |
| **Rule 12** | "Confidence-tiered evidence with file:line cites" — every finding declares its evidence-quality tier. | An agent reviewer that emits a finding without `[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]` label violates Rule 12. Composes with N-2 (Hallucinated specificity) — file:line cites MUST be programmatically verifiable; unverifiable cites are N-2 violations. Agent fix: review template enforces evidence-quality label per finding; citation-grep pre-emit check (N-2 mechanism) verifies file:line resolves. |

**Full pool reference:** The framework cites only the 6 rules above; the remaining 9 (Rules 5, 6, 8, 9, 10, 11, 13, 14, 15) apply equally to agent-context reviews and are loaded by reference per [`review-discipline-principles.md § 1`](../disciplines/review-discipline-principles.md). The 6 rules named here are the highest-leverage subset for the 3 novel agent failure modes' composition surface.

---

## §9 Boundaries + Cross-References

### §9.1 What this framework does NOT replace

| Adjacent doc | What it owns (NOT this framework's concern) |
|---|---|
| [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | The anti-laziness rules + 6-deliverable output structure + reviewer calibration mechanics + reviewer-posture anti-patterns. This framework REFERENCES that pool from § 8.4; does not duplicate. |
| [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) | The structured gate-criteria tables (G1-* / G2-* / G3-* / G-PR-* / G-EX-* / G-CL-* / G-BR-*). This framework COMPOSES those criteria into named composed reviews (§ 3 Catalog) and maps them to stage × posture cells (§ 4 Map); does not redefine. |
| [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) | The 3-layer assessment protocol (Metrics / Judgment / Calibration) + decision matrix + per-boundary metrics. This framework EXTENDS Layer 3 (Calibration) with per-dimension judge-vs-operator agreement (§ 6 Calibration Ledger); does not replace stage-gate accuracy tracking. |
| [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) | The 5-phase orchestration (contract validation / gate evaluation / transition routing / iteration tracking / trend reporting). This framework's reviews are CONSUMED by the orchestrator at stage boundaries; framework does not orchestrate. |
| [`design-artifact-standard.md`](design-artifact-standard.md) | The Tier-A / Tier-B activation + refresh-gate (G-CL6) mechanism. This framework EMBEDS 2 Tier-A activated concept-model artifacts (§ 2.1 + § 4); does not own the refresh-gate mechanism. |
| [`decision-discipline.md`](../disciplines/decision-discipline.md) | The M1 / M2 / M3 ceremonies + observation-log emergence-rule + Pattern Cache. This framework's reviews CONSUME those ceremonies at Stage 5 Solutioning; framework does not own the decision discipline. |
| [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | The R1 ↔ R3 ↔ R4 composition + canonicalization-evidence schema. This framework's § 3 Catalog + § 4 Map are canonicalizations subject to R1; framework does not own R1 enforcement. |
| build-reviewer / pmo-qa-auditor / pmo-skill-editor SKILL.md | Per-skill review implementations. This framework does NOT modify any skill SKILL.md per AC-5 integration-by-reference; skill-side citations are separate downstream work outside. |

### §9.2 Composition seam (per AC-5)

| Composed-with doc | What this framework references | What the other doc references |
|---|---|---|
| [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | § 8.4 cites ≥ 6 of the anti-laziness rules from § 1 of that doc. | "See also" pointer added at doc end → this framework § 8 Agent-Correction Layer. |
| [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) | § 3 Catalog references gate IDs as sub-components of composed reviews (e.g., RC-3-bundle-capacity inherits the Gate-3 criterion set). § 4 Map cell at Stage 3 × Peer references RC-3-bundle-capacity. | "See also" pointer added in preamble → this framework § 3 Review Catalog + § 4 Review Map. |
| [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) | § 6 Calibration Ledger EXTENDS Layer 3 (Calibration) with per-dimension granularity. | "See also" pointer added in preamble → this framework § 6 Calibration Ledger. |

### §9.3 Registry references

- [`framework-catalog.md`](../specs/framework-catalog.md) — registry row for this framework (INTERNAL class, applicability scope = cross-stage review composition + agent-correction discipline, tier = emerging, cadence = continuous).
- [`architecture-overview.md § Peer-Spec Concept Ownership`](../disciplines/architecture-overview.md) — concept-ownership row 29 for "Review Composition Framework + 7-dim taxonomy".

### §9.4 Cutover

- **This release:** authors the framework, populates the seed Catalog (16 RC-* entries), populates the seed Map (30+ cells), populates the seed Calibration Ledger (1 dimension), and adds 3 cross-reference pointers. This release is exempt from the framework's own forcing function per § 7.5 (reflexive-pipeline-loop discipline).
- **Going forward:** the framework's § 7 forcing function activates for downstream review-surface integrations. Stage 5 spokes proposing new review types MUST register Catalog entries + Map cells. Stage 9 Plan Review verifies registration. Stage 13 Close verifies G-CL6 refresh on the § 2.1 + § 4 Tier-A artifacts when touched.
- **Downstream skill integration:** SKILL.md citations to this framework are SEPARATE downstream work tracked outside this release's scope per AC-5 integration-by-reference. The 11 fragmenting issues remain open post-ship; per-issue disposition is operator-driven at Stage 13 close per the release-readiness checklist item.

### §9.5 Related references

- [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) — § 8.4 inherited mitigation pool.
- [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — § 3 Catalog composes these criteria.
- [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) — § 6 Calibration Ledger extends Layer 3.
- [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) — orchestrator consumes RC-* reviews at stage boundaries.
- [`design-artifact-standard.md`](design-artifact-standard.md) — § 2.1 + § 4 Tier-A activated artifacts governed by this standard.
- [`decision-discipline.md`](../disciplines/decision-discipline.md) — Stage 5 Solutioning ceremonies consumed by § 4 Stage 5 cells.
- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — R1 governs § 3 + § 4 canonicalizations.
- [`framework-corpus-discipline.md`](framework-corpus-discipline.md) — framework-tier classification + cadence + corpus-discipline rules.
- [`framework-catalog.md`](../specs/framework-catalog.md) — registry row + version anchor.
- [`<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/README.md`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/README.md) — per-dimension Calibration Ledger schema + creation protocol + seed dimension.
- [`<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/focus-correctness-stage-7-dt.md`](<OPERATOR_INSTANCE_EVALS_PATH>/judge-calibration/focus-correctness-stage-7-dt.md) — seed ledger demonstrating the schema with 3 synthesized rows.

---

**Document end.**
