---
title: Release-Process Fitness Audit — Dimension Rubric
purpose: The content SSOT for pmo-qa-auditor Mode F (release-process fitness audit) — the scored dimension rubric the audit grades the pipeline against.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Release-Process Fitness Audit — Dimension Rubric (Mode F content SSOT)

> The committed handoff artifact of the Pipeline-Definition-&-Fitness seam: that
> initiative evolves this file via governed edits (pmo-skill-editor; continuity
> per `release/references/protocols/process-fitness-cadence.md` §5). Mode F
> consumes it verbatim. The operator-local initiative roadmap references THIS
> file, never the reverse.

## 1. Dimension set (dual-source, reconciled)

Sources: the 9 pipeline-fitness disciplines + the hub spoke return-value schema
(the dual-source frame), reconciled against the Triage→Design re-review's
citation discipline and the gate-criteria census; 3 adds warranted (§4). One
content-source cite per row; the Frame(s) column maps each dimension to the
cadence-§5 external frame(s) it operationalizes — fitness-against-external-frames
without a second scoring machinery.

| # | Dimension | Content source | Frame(s) (per cadence §5) |
|---|---|---|---|
| 1 | Discovery discipline | `core/disciplines/discovery-discipline.md` | PMBOK 7 · Lean |
| 2 | Outcome statement | `release/references/specs/release-outcome-statement-template.md` | PMBOK 7 · Stage-Gate |
| 3 | Release-class differentiation | `release/references/specs/release-class-taxonomy.md` | Stage-Gate · ITIL 4 |
| 4 | Readiness scan | `release/references/specs/release-readiness-scan-spec.md` | Stage-Gate · CD |
| 5 | Adversarial review | `release/references/pipeline/stage-05-solutioning.md` A6.5 + `core/standards/review-composition-framework.md` §3 RC-5 | PMBOK 7 · CD |
| 6 | Fission | `release/references/protocols/fission-convention.md` | Lean |
| 7 | Documentation impact | `release/references/specs/ticket-information-architecture.md` (Doc-Impact field) + the stage-01/06/13 doc-impact steps | ITIL 4 |
| 8 | Bundle composition | `release/references/standards/bundle-composition-doctrine.md` | Lean · Stage-Gate |
| 9 | Decomposition review | `core/schemas/gate-criteria-spec.md` G2-11 / G3-12 / G3-15 + `release/references/standards/bundle-composition-doctrine.md` §11.8 | Lean |
| 10 | Hub-return schema | `release/references/how-to/hub-spoke-bridge.md` § Return Value to Hub (4-field closed enum) | DORA · CD |
| 11 | Traceability (ADD) | `core/schemas/stage-io-contracts.md` + the ticket lifecycle protocol (`release/references/specs/ticket-information-architecture.md`) | DORA · ITIL 4 |
| 12 | Evidence-quality (ADD) | CLAUDE.md evidence labels + `release/references/standards/triage-design-rereview.md` §2 citation discipline | PMBOK 7 |
| 13 | Gate-coverage (ADD) | `core/schemas/gate-criteria-spec.md` + per-stage shard §7 criteria | Stage-Gate · CD |

13 is the reconciliation output, not a cap — roster changes are governed by the
cadence-§5 continuity rule (note additions, rationale for removals, in the run's
SUMMARY.md).

## 2. Scoring anchors (1–5)

**Generic spine** (every dimension specializes this): **1 absent** · **2
partially codified** · **3 codified-unenforced** · **4 enforced** · **5 enforced
+ calibrated**. Per-dim cells specialize each level to an **observable state**;
the example evidence source for any cell is the dimension's §1 content-source
doc (plus the mechanical check — a grep, a gate-ID census, a live-run artifact —
that shows the state). Scores are RECORDED trend data under the cadence-§5
continuity rule, never gate verdicts.

**Worked example (the authoring pattern) — Dim 13 Gate-coverage, level 3:**
"codified and cited by ≥1 stage shard, but no gate-criteria-spec ID asserts it
(evidence: the discipline doc + a gate-ID grep showing absence)."

**Second worked example — Dim 10 Hub-return schema, level 4:** "the 4-field
closed-enum return schema is stated at its definitional home AND spoke prompts
carry it verbatim; hub routing consumes only the closed enum (evidence:
`release/references/how-to/hub-spoke-bridge.md` § Return Value to Hub + the
spoke-template return block instructing the schema)."

| # | Dimension | 1 — absent | 2 — partially codified | 3 — codified-unenforced | 4 — enforced | 5 — enforced + calibrated |
|---|---|---|---|---|---|---|
| 1 | Discovery discipline | No discovery activity at stage entries; premises unexamined | Discovery named in some stage docs; no activation triggers or output set | Triggers + the 5-output set codified; no stage-entry check asserts them | Stage-entry checks require discovery outputs when activation triggers fire | Activation + output quality tracked across releases; triggers re-tuned on evidence |
| 2 | Outcome statement | Releases carry no AFTER/BEFORE outcome statement | Outcomes stated free-form in some plans; no template | Template codified; plans omit or truncate fields without a gate firing | Plan-gate checks require the template's fields (AFTER / BEFORE / Actors / Success Indicator) | Success Indicators re-read at the Stage-13 outcome window; template evolved on measured gaps |
| 3 | Release-class differentiation | All releases processed identically; no class taxonomy | Classes named informally; no trigger conditions | Taxonomy + triggers codified; class not consistently declared or consumed | Class declared per release with trigger evidence; per-class posture applied downstream | Class capacity weights re-calibrated from release history |
| 4 | Readiness scan | No pre-run readiness check; milestones start on request | Ad-hoc readiness questions; no spec'd check set | Scan spec codified; runs optional or skipped without record | Readiness GO/NO-GO with per-finding dispositions runs before a milestone starts | Scan check set re-tuned on escape analysis across runs |
| 5 | Adversarial review | Designs ship with no adversarial pass | Occasional ad-hoc critique; no composition rule | A6.5 + RC-5 codified; launches inconsistent or verdicts unrecorded | Adversarial review fires per design with recorded findings + dispositions | Finding yield / escape rate measured; review composition re-weighted |
| 6 | Fission | Oversized tickets ship whole; no split protocol | Splitting ad-hoc; no parent/child bookkeeping | Convention + oversize predicates codified; routing not recorded in live runs | Predicates fire with recorded 3-outcome routing; fission steps executed on split | Predicate thresholds re-calibrated from decomposition outcomes |
| 7 | Documentation impact | Doc updates ad-hoc; no per-ticket declaration | Some tickets name affected docs; no field or stage step | Doc-Impact field + stage steps codified; declarations unresolved at close without a gate | Declared docs land with the motivating change; a close-gate resolves every declaration | Doc-impact escape rate measured; the field taxonomy evolved |
| 8 | Bundle composition | Releases assembled by convenience; no doctrine | Size bands known informally; capability coherence unstated | Doctrine's steps + shapes codified; bundles composed without recorded step evidence | Bundle rationale records capability statement + dep walk + size verdict per doctrine | Size targets / class weights calibrated from shipped-bundle data |
| 9 | Decomposition review | No oversize detection at any gate | Oversize noticed informally; no predicate or routing enum | Composite-OR predicate + 3-outcome routing codified; routing decisions unrecorded in live runs | Predicate fires at Triage/Bundle with recorded routing per the 3-outcome enum | Predicate hit-rate + split outcomes tracked; thresholds re-tuned |
| 10 | Hub-return schema | Spoke returns free-form; hub parses prose | Some spokes share a return shape; not specified | 4-field closed-enum schema codified; spokes deviate without detection | Schema at its definitional home AND spoke prompts carry it verbatim; hub consumes only the closed enum | Return-value conformance measured across spokes; enum evolved via governed edits |
| 11 | Traceability | Stage outputs unlinked; work-item state unrecoverable from artifacts | Some stages name inputs/outputs; no boundary contracts | Boundary contracts + lifecycle protocol codified; artifacts skip fields without detection | Contracts consumed at stage entry; lifecycle transitions recorded per protocol | Traceability breaks measured (rollup-vs-commit divergence class); contracts versioned on evidence |
| 12 | Evidence-quality | Claims carry no source discipline | Label vocabulary exists; used sporadically | 5-label vocabulary + citation discipline codified; unlabeled claims pass unflagged | Labels enforced at review surfaces; unlabeled factual claims rejected | Label accuracy spot-audited; citation quality validated mechanically |
| 13 | Gate-coverage | Disciplines have no enforcing gate criteria | Some stages state criteria; no per-discipline mapping | Codified and cited by ≥1 stage shard, but no gate-criteria-spec ID asserts it | Each audited discipline maps to ≥1 gate ID that fires in live runs | Gate escape rate per criterion tracked; criteria re-tiered (warn→enforce) on evidence |

**Scale note (deviation, documented):** 1–5 deviates from
`core/skills/eval-writer/references/rubric-templates.md`'s binary/1–4 preference
on stated merits: scores are RECORDED trend data (never gate verdicts), the
pipeline's own per-stage §7 gate-metrics vocabulary is "Judgment (1-5)", anchors
are behavioral states (absorbing the verbosity-bias mechanism), and the
characterization fixtures pin drift (±1 on ≥4/5). Not a gate carve-out — Mode F
emits zero gate verdicts.

## 3. Banding (SSOT — classification mapping + borderline deep-dive band)

| Scope-match band (range string) | Classification | deep_dive_required |
|---|---|---|
| 0–25% | UNTRACKED | false |
| 25–40% | PARTIAL (provisional — borderline) | **true** |
| 40–60% | PARTIAL | false |
| 60–80% | PARTIAL | false |
| 80–100% | ALREADY-TRACKED | false |

The classifier emits the range STRING from this table; `deep_dive_required`
derives by string equality with the borderline row. Re-tuning = an edit to THIS
table only.

**Interval-closure rule (boundary semantics):** every band is **closed at its
lower bound and open at its upper bound** — `[lower, upper)` — except the final
band `80–100%`, which is closed at both ends (`[80, 100]`). So a scope-match of
exactly **25%** lands in `25–40%` (borderline — `deep_dive_required: true`),
exactly **40%** lands in `40–60%`, and exactly **80%** lands in `80–100%`
(ALREADY-TRACKED). Every value in [0, 100] maps to exactly one band; there are
no gaps and no overlaps.

Every PARTIAL carries a mandatory tracked-remainder note (sibling `#N` + covered
+ uncovered); ALREADY-TRACKED cites its sibling. Scope-match % is LLM judgment
(topic / mechanism / outcome, evidence-quoted) over the search primitives'
deterministic candidate set.

## 4. Reconciliation record (design provenance)

Sources: the 9 pipeline-fitness disciplines + the hub spoke return-value schema
(`release/references/standards/bundle-composition-doctrine.md` §8 Shape 1 names
both source sets); reconciled vs `release/references/standards/triage-design-rereview.md`
§2 and `core/schemas/gate-criteria-spec.md`:

- **vs re-review §2** — its D1/D2/D3 checks interrogate ONE TICKET at design
  entry; Mode F scores THE PIPELINE per discipline across runs; different unit
  of analysis → no duplication. §2's citation discipline SOURCES dim 12.
- **vs gate-criteria** — gates ENFORCE per-issue readiness; dim 13 MEASURES
  whether each discipline has an enforcing criterion (a coverage census over
  gate IDs); the audit consumes IDs and defines zero criteria.
- **3 adds warranted** — traceability, evidence-quality, gate-coverage: each
  names a platform discipline the 10 source docs exercise but do not score, with
  a live tracked source, targeting the platform's dominant gap class
  (codified-unenforced).

Full reconciliation record: the release's Stage 5 Solutioning design record for
the Mode F slice (this file is its committed output).
