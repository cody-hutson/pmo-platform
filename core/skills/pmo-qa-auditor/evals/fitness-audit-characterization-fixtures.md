<!-- reference-durability: allow-link -->
# Mode F Characterization Fixtures — Release-Process Fitness Audit

```yaml
labeled_by: Stage-6 Engineering session (candidate labels)
label_date: 2026-07-10
independence: pending — labels adjudicated by the operator or a session that
  authored neither the rubric nor the mode text; Engineering drafts candidate
  labels; the operator confirms/corrects at the Stage-7 DT gate — the confirmed
  set is ground truth
```

Characterization fixtures, NOT κ-calibrated — regression-pinning for Mode F's
classification, scoring, evidence-bar, and banding behavior (the ≥30-item
calibration floor governs gating judges, which these are not; per the eval-writer
discipline). Acceptance per family: classification **≥4/5** ground-truth match ·
dimension-scoring **±1 on ≥4/5** · evidence-bar **exact** · banding boundary
**exact**. The deterministic families (evidence-bar, banding) are executed by
`scripts/fitness-audit-search-primitives.sh --self-test`, which parses the
tables below (SSOT: this file). The judgment families run at the Stage-7 DT gate
and in pmo-skill-editor Mode C regression.

**Durability note:** fixture inputs cite work items by TITLE + live search
procedure, never by number — numbers rot on renumber; titles + procedures
survive. Live-resolved evidence inputs use `LIVE:` tokens the self-test resolves
at run time.

## Family 1 — Classification (5 fixtures; judgment; ≥4/5)

Each fixture: the classifier receives the finding text, runs the §2 protocol
(3-variant search, scope-match judgment, band lookup), and must land on the
ground-truth classification. Adjudication compares classification + band +
`deep_dive_required` (the scope-match % itself may vary within the band).

### F-CLS-01

- **Input (finding):** "No pipeline stage invokes eval suites automatically;
  DT/QA runs are conversation-based with operator-triggered evals only."
- **Search variants:** "automated eval execution" · "evals automatically
  pipeline stages" · "eval invocation stage gates"
- **Candidate sibling (live-resolve by title):** the open story "Run evals
  automatically during pipeline stages with operator escalation only on
  failure"
- **Expected output:** classification ALREADY-TRACKED · band `80–100%` ·
  `deep_dive_required: false` · sibling cited
- **Ground-truth label (candidate):** ALREADY-TRACKED
- **Adjudication note:** near-verbatim capability overlap — topic, mechanism
  (stage-trigger registration), and outcome (automatic execution + escalation
  on failure) all match the sibling's stated scope.

### F-CLS-02

- **Input (finding):** "Release-process audit findings are not classified
  against the improvement backlog, and no automated action closes out audit
  findings that duplicate tracked work."
- **Search variants:** "audit findings classification backlog" ·
  "release-process fitness audit" · "audit finding duplicate tracked"
- **Candidate sibling (live-resolve by title):** the story "Add a
  Release-Process Fitness Audit mode (Mode F) to pmo-qa-auditor"
- **Expected output:** classification PARTIAL · band `40–60%` ·
  `deep_dive_required: false` · tracked-remainder note: covered = the
  UNTRACKED / PARTIAL / ALREADY-TRACKED classification against the backlog;
  uncovered = any automated duplicate-closeout action (the sibling is
  OBSERVE-only by posture)
- **Ground-truth label (candidate):** PARTIAL
- **Adjudication note:** first half of the finding is the sibling's core scope;
  the second half (automated closeout) is affirmatively outside its
  observational posture — a genuine remainder, not a wording gap.

### F-CLS-03

- **Input (finding):** "The release pipeline defines no rollback rehearsal —
  the documented rollback procedures are never exercised against a live
  release to verify they restore pre-release state."
- **Search variants:** "rollback rehearsal drill" · "rollback restore test" ·
  "rollback procedure verification"
- **Candidate sibling:** none above trivial match (searches return keyword
  noise — pipeline sub-tasks whose bodies mention rollback steps — not a
  rollback-rehearsal capability item)
- **Expected output:** classification UNTRACKED · band `0–25%` ·
  `deep_dive_required: false`
- **Ground-truth label (candidate):** UNTRACKED
- **Adjudication note:** verified at authoring (2026-07-10): no work item
  proposes exercising rollback procedures; nearest matches are release
  sub-tasks that merely contain the word.

### F-CLS-04

- **Input (finding):** "Per-stage §7 Judgment (1-5) gate scores are rendered in
  stage outputs but recorded nowhere; no cross-release trend of stage-gate
  judgment quality exists."
- **Search variants:** "judgment scores recorded" · "stage gate metrics trend" ·
  "gate score trend releases"
- **Candidate sibling (live-resolve by title):** the open story "Run evals
  automatically during pipeline stages with operator escalation only on
  failure"
- **Expected output:** classification PARTIAL (provisional — borderline) ·
  band `25–40%` · `deep_dive_required: true` · a Deep-Dive Queue row emitted
  (`dispatched` column blank)
- **Ground-truth label (candidate):** PARTIAL (borderline)
- **Adjudication note:** topic overlaps (stage-gate quality machinery) but
  mechanism (trigger registration vs score recording) and outcome (escalation
  vs trend visibility) diverge — exactly the ambiguity band the deep-dive
  exists for.

### F-CLS-05

- **Input (finding):** "Issue acceptance criteria have no typed assertion
  contract; AC grading at QA is free-form per session."
- **Search variants:** "acceptance assertion framework" · "acceptance criteria
  contract QA" · "typed assertion AC grading"
- **Candidate sibling (live-resolve by title):** the closed story "Build
  acceptance assertion framework for QA Testing"
- **Expected output:** classification ALREADY-TRACKED · band `80–100%` ·
  `deep_dive_required: false` · the closed sibling cited
- **Ground-truth label (candidate):** ALREADY-TRACKED
- **Adjudication note:** the enum classifies TRACKING state, not open/closed —
  shipped work is tracked work; the search runs `--state all` precisely so
  closed siblings surface.

## Family 2 — Dimension scoring (5 fixtures; judgment; ±1 on ≥4/5)

Each fixture: the scorer receives the described corpus state, scores the named
dimension per rubric §2 anchors, and must land within ±1 of ground truth.
States below are real platform states, checkable at label_date.

### F-DIM-01 — Dimension 1, Discovery discipline

- **Input (corpus state):** the discovery discipline doc exists with activation
  triggers + a 5-output set; the workspace-global rules name it a universal
  preference; no gate-criteria ID asserts discovery outputs at any stage entry.
- **Ground-truth score (candidate):** 3 (codified-unenforced)
- **Adjudication note:** the level-3 anchor verbatim — codified, cited, no
  asserting gate ID.

### F-DIM-02 — Dimension 6, Fission

- **Input (corpus state):** the fission convention + the Composite-OR oversize
  predicates with 3-outcome routing are codified in the gate-criteria spec;
  Triage/Bundle runs record routing decisions in live summary comments; the
  predicate thresholds carry an open calibrate-after-3 marker (not yet
  re-tuned from outcomes).
- **Ground-truth score (candidate):** 4 (enforced)
- **Adjudication note:** predicates fire with recorded routing (level 4);
  re-calibration from decomposition outcomes has not happened (not level 5).

### F-DIM-03 — Dimension 10, Hub-return schema

- **Input (corpus state):** the 4-field closed-enum return schema is stated at
  its definitional home; spoke prompt templates carry it verbatim; hub routing
  consumes only the closed enum; no cross-spoke conformance measurement
  exists.
- **Ground-truth score (candidate):** 4 (enforced)
- **Adjudication note:** the rubric's second worked example — enforced by
  template + consumption; calibration absent.

### F-DIM-04 — Dimension 12, Evidence-quality

- **Input (corpus state):** the 5-label evidence vocabulary is a
  workspace-global universal preference; review surfaces enforce it (an
  evidence-quality gate rejects unlabeled factual claims); mechanical citation
  validation exists only for the fitness-audit surface, not platform-wide.
- **Ground-truth score (candidate):** 4 (enforced)
- **Adjudication note:** enforced at review surfaces (level 4); mechanical
  validation is not yet a platform-wide calibration loop (not level 5).

### F-DIM-05 — Dimension 13, Gate-coverage

- **Input (corpus state):** the gate-criteria census exists and its warn-mode
  gates fire in live runs for readiness/decomposition disciplines; several
  audited disciplines (discovery, evidence-quality) have no asserting gate ID.
- **Ground-truth score (candidate):** 3 (codified-unenforced)
- **Adjudication note:** the level-3 worked example generalized — the census is
  codified and partially firing, but per-discipline coverage is incomplete, so
  the DIMENSION (coverage of disciplines by gates) sits at 3.

## Family 3 — Evidence-bar (12 fixtures; deterministic; exact)

Machine-parseable table — `--self-test` reads it. `LIVE:` tokens resolve at run
time (keeping this file durable across renumber/re-tag); `NONE:` marks an input
that is a citation candidate matching no form. Expected verdict = the §4
deterministic checks only (form regex + resolution); aptness is judgment,
out of self-test scope.

| Fixture | Form | Input | Expected |
|---|---|---|---|
| EB-01 | CF-1 | core/schemas/gate-criteria-spec.md:217 | PASS |
| EB-02 | CF-1 | core/rules/git-workflow.md:196 | PASS |
| EB-03 | CF-1 | release/references/protocols/process-fitness-cadence.md:57 | PASS |
| EB-04 | CF-2 | CMD:grep -n "^### Mode F" core/skills/pmo-qa-auditor/SKILL.md → 1 match | PASS |
| EB-05 | CF-2 | CMD:git log --oneline -1 -- core/skills/pmo-qa-auditor/SKILL.md → one commit line | PASS |
| EB-06 | CF-3 | LIVE:highest-issue | PASS |
| EB-07 | CF-3 | LIVE:latest-release | PASS |
| EB-08 | CF-4 | LIVE:head-sha | PASS |
| EB-09 | CF-4 | LIVE:root-sha | PASS |
| EB-10 | CF-1 | core/standards/analysis-workspace-standard.md:9 | PASS |
| EB-11 | NONE | general observation across the corpus | FAIL |
| EB-12 | CF-1 | core/standards/nonexistent-evidence-file.md:12 | FAIL |

`LIVE:` token resolution (documented for reproducibility): `highest-issue` →
the hash-prefixed number of the repo's highest-numbered issue (`gh issue list
--state all --limit 1 --json number`); `latest-release` → the latest published
release version tag (`gh release list --limit 1`); `head-sha` → `git rev-parse
--short HEAD`; `root-sha` → the repo's root commit (`git rev-list
--max-parents=0 HEAD`, first line). EB-12 matches the CF-1 regex but fails
resolution (file absent) — the regex-pass/resolution-fail control. EB-11
matches no form — the no-form control.

## Family 4 — Banding boundary (6 fixtures; deterministic; exact)

Machine-parseable table — `--self-test` reads it and computes band membership
from the rubric §3 Banding table via the interval-closure rule (bands
`[lower, upper)`; final band closed). These pin the boundary semantics the
FM-7 rider requires to be unambiguous.

| Fixture | Scope-match % | Expected band | Expected classification | Expected deep_dive_required |
|---|---|---|---|---|
| BND-01 | 24 | 0–25% | UNTRACKED | false |
| BND-02 | 25 | 25–40% | PARTIAL (provisional — borderline) | true |
| BND-03 | 40 | 40–60% | PARTIAL | false |
| BND-04 | 41 | 40–60% | PARTIAL | false |
| BND-05 | 79 | 60–80% | PARTIAL | false |
| BND-06 | 80 | 80–100% | ALREADY-TRACKED | false |
