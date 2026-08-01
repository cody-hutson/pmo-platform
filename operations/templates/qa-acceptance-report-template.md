---
artifact_type: template
template_family: Acceptance report / Stage verdict report
domain: software
canonical_path: operations/templates/qa-acceptance-report-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-03
updated: 2026-08-01
generated_by: release-pipeline {{RELEASE_VERSION}}
reviewer: N/A
canon: PMBOK 7 §Quality + ISO/IEC/IEEE 29119-3 §Test Completion Report
canon_compat: none
version: "{{RELEASE_VERSION}}"
supersedes: N/A
superseded_by: N/A
---
<!-- repo-integrity: allow-issue-ref -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered acceptance-report instances — an instance starts at the H1 below. -->
# QA Acceptance Report Template — PMO Reference

## Purpose

This file provides the canonical template for the **Acceptance Report** emitted by
Stage 8 (QA Testing) of the release pipeline. The Stage-8 QA spoke renders one
report instance per issue from this template, per
`release/references/pipeline/stage-08-qa-testing.md` §6 Outputs.

The report answers one question — *does this PR satisfy its originating issue's
acceptance criteria?* — and carries all six §6-Outputs sections (acceptance
matrix, acceptance score, fitness assessment, Stage-7 escape log, lane
distribution, overall verdict), organized top-to-bottom as **three reader tiers**
so a verdict-first reader can stop after Tier 1, a reviewer reads Tier 2, and an
auditor or downstream agent parses Tier 3.

- **Verdict values** are the six-value per-criterion enum defined in
  `stage-08-qa-testing.md` §5 (the SSOT). This template is a strict **consumer**
  of that enum and introduces no verdict value of its own.
- **Matrix columns** and the **acceptance-score roll-up** are the co-design
  contract with the `acceptance` assertion type
  (`core/skills/eval-writer/references/acceptance-assertion-type.md` §5): the
  framework *produces* the per-criterion verdicts and score, this template
  *renders* them. The columns below are exactly that type's §5 columns so the
  report and the framework agree by construction.

---

## Reader-Tier Structure (the H2 spine)

Every rendered report instance carries these three H2 tiers **in order**. Each
§6-Outputs section is homed in exactly one tier:

| Tier | Reads in | Sections homed here |
|---|---|---|
| Tier 1 — Acceptance Verdict | 30 seconds | overall verdict · acceptance score |
| Tier 2 — Acceptance Detail | 2 minutes | acceptance matrix · fitness assessment · lane distribution |
| Tier 3 — Evidence & Machine Record | deep-dive | per-criterion evidence · Stage-7 escape log · machine-readable acceptance block |

**Reader-contract invariant:** each tier is self-consistent read alone. Tier 1's
verdict never contradicts Tier 2's matrix (the score is derived from the matrix);
Tier 3's machine block is a byte-faithful projection of Tier 2's matrix rows. A
rendering that violates this is a QA finding.

---

## Acceptance-Matrix Columns (co-design contract)

The acceptance matrix is the per-criterion output of the `acceptance` assertion
type. These are its **stable, machine-parseable** columns — the report renders
exactly these so the report and the framework agree (source:
`acceptance-assertion-type.md` §5):

| Column | Values / shape | Source |
|---|---|---|
| `AC-ID` | `AC-N` (or `INT-N` for integration ACs) | order-derived, stable |
| `Criterion` | the AC item verbatim (the contractual text) | issue body |
| `Verdict` | one of the six `stage-08-qa-testing.md` §5 values | verdict-projection table |
| `Evidence` | what the grader found in PR content (cite / quote) | grader output |
| `Severity` | `Blocker \| Warning` — **present only when `NOT MET`** | verdict-projection table |
| `Drift-rationale` | required-when-present — populated **only** for the three drift verdicts | verdict-projection table |
| `Disposition` | `fix-now \| defer \| accept` — the Stage-8 Finding-Disposition axis (operator-rendered; advisory in the matrix) | Stage-8 §5 Finding Disposition Framework |

**Verdict enum (the `Verdict` column domain), verbatim from `stage-08-qa-testing.md` §5:**

```
MET | NOT MET | PARTIAL | N/A-WITH-RATIONALE | REINTERPRET-WITH-RATIONALE | FLAG-UPSTREAM
```

The first three (`MET / NOT MET / PARTIAL`) are the binary-gate outputs of a
**gradable** criterion. The last three (drift verdicts) are emitted **only** when
the criterion cannot be graded as-written; each carries the mandatory
`Drift-rationale` field and is **out of the Stage-8 Step-0 fix-now gate**.

**Footer roll-up (from `acceptance-assertion-type.md` §4):** `acceptance_score`
(all-drift-out) plus the per-verdict `acceptance_verdicts` counts.

**Acceptance-score formula (all-drift-out — the LOCKED formula, scope-lock 2026-07-03):**

```
acceptance_score = count(MET) / ( total_criteria − count(N/A-WITH-RATIONALE)
                                                − count(REINTERPRET-WITH-RATIONALE)
                                                − count(FLAG-UPSTREAM) )
```

- `PARTIAL` and `NOT MET` count as 0 in the numerator (binary discipline; a
  `PARTIAL`'s unmet remainder is separately keyed to the Stage-8 Step-0 gate).
- All three drift verdicts leave **both** numerator and denominator — none is a
  gradable commitment (uniform with `stage-08-qa-testing.md` §5, where every
  drift verdict sits out of the gate).
- The **score is RECORDED, not GATED** at authoring time; the **verdict** gates
  (Stage-8 Step-0 fixes `NOT MET` now). The score is the fitness signal Tier 1
  renders.

---

## Machine-Readable Acceptance Block

Tier 2's GFM matrix is the human read; the Tier-3 fenced `acceptance-matrix`
block is its machine twin — a byte-faithful projection for downstream agents and
humans to query without re-parsing prose. It reuses the machine-readable
result-schema discipline (stable keys, pipe-free / whitespace-free values, one
record per criterion, parseable by a fixed grammar without a parser library).

**Grammar (the parse contract):** a header line `# acceptance-matrix v1 · <meta
key:value · …>`; then one row per criterion as ` | `-separated `key:value`
fields with a **fixed key order** `id | verdict | severity | disposition |
evidence`. Verdict enum values use `_` for spaces (`NOT_MET`,
`N_A_WITH_RATIONALE`, `REINTERPRET_WITH_RATIONALE`, `FLAG_UPSTREAM`) so a value
never contains whitespace. A `grep '^id:'` yields every criterion; an
`awk -F'|'` splits fields deterministically.

- The `v1` version token makes the schema the contract: a later column addition
  is a `v2` a parser can branch on.
- The header's `score` and `met:n/total` are computed from the rows and **must**
  equal Tier 1's headline (the reader-contract invariant).
- This block mirrors the `acceptance` assertion type's `grading.json`
  `summary.acceptance_*` fields (the eval-framework-side data), so the report
  surface and the eval surface carry the same numbers.

### Relationship to the pipeline event log

The report's fenced `acceptance-matrix` block is a **distinct surface** from the
pipeline event-log's `gate-outcome` / `qa-acceptance` event-subtype, not the same
record. Per `release/references/standards/pipeline-event-log-schema.md`, the
`qa-acceptance` gate-outcome row (emitted when the QA verdict is rendered at Phase
B, per `stage-08-qa-testing.md` §11) is a **thin verdict-level** record on the
unified 10-field schema — its `payload` carries a `projects_to:` pointer to the
`calibration-data.md` row, not the full per-criterion matrix. The matrix block
here is the **per-criterion detail** the report renders. The relationship:

- The `qa-acceptance` event **records that a verdict happened** and points to
  where the calibration row lives.
- This `acceptance-matrix` block **carries the per-criterion verdicts and score**
  that the event's verdict summarizes.
- Both trace to one logical QA verdict; the event is the audit-log projection,
  this block is the report-facing per-criterion source, and the assertion type's
  `grading.json` `summary.acceptance_*` is the eval-framework data. Three
  surfaces, one verdict — kept consistent by the reader-contract invariant and
  the shared roll-up formula.

---

## Rendered-Report Scaffold

Copy the structure below into each report instance. Angle-bracket `<…>` tokens
are fill-in slots; `#T3-N` evidence anchors and `#NNN` deferral targets are
placeholders the renderer replaces. Fenced blocks render as real fenced blocks in
the instance.

---

# Acceptance Report — <issue #N> (<release vX.Y>)

<!-- Rendered by the Stage-8 QA spoke per release/references/pipeline/stage-08-qa-testing.md §6.
     Verdict values: stage-08-qa-testing.md §5 per-criterion enum (verbatim).
     Matrix columns + score: core/skills/eval-writer/references/acceptance-assertion-type.md §5/§4. -->

## Tier 1 — Acceptance Verdict (read in 30s)

**Overall verdict:** <ACCEPT | CONDITIONAL ACCEPT | REJECT | HOLD>
**Acceptance score:** <met>/<total> criteria MET · score <0.000>

_<one line — what this means: CONDITIONAL ACCEPT names the Override-Record count;
REJECT names the blocking-criterion count.>_

## Tier 2 — Acceptance Detail (read in 2min)

### Acceptance matrix

| AC-ID | Criterion | Verdict | Evidence | Severity | Drift-rationale | Disposition |
|---|---|---|---|---|---|---|
| AC-1 | <AC text verbatim> | MET | <what the grader found> | — | — | — |
| AC-2 | <AC text verbatim> | NOT MET | <what the grader found> | Blocker | — | fix-now |
| AC-3 | <AC text verbatim> | PARTIAL | <what the grader found; unmet remainder> | Warning | — | defer → #NNN |
| AC-4 | <AC text verbatim> | N/A-WITH-RATIONALE | <what the grader found> | — | <why not applicable> | accept |
| INT-1 | <integration AC text> | REINTERPRET-WITH-RATIONALE | <what the grader found> | — | <how re-read> | accept |

_(`Severity` populated only on `NOT MET`; `Drift-rationale` populated only for the
three drift verdicts; a `defer`/`accept` on a `NOT MET` or AC-blocking `PARTIAL`
row must carry the Operator Override Record pointer per `stage-08-qa-testing.md`
§5.)_

### Fitness assessment

<Does this meet needs? — the §1 fitness question. Records any Accept-dispositioned
NOT-MET / PARTIAL AC together with its Operator Override Record per
`stage-08-qa-testing.md` §5.>

### Lane distribution

| Lane | Count |
|---|---|
| Lane 1 — Standards | <n> |
| Lane 2 — AC gap | <n> |
| Lane 3 — Acceptance judgment | <n> |

## Tier 3 — Evidence & Machine Record (deep-dive)

### Per-criterion evidence

**#T3-1 (AC-1):** <what was found, cited to PR content>
**#T3-2 (AC-2):** <what was found, cited to PR content>
**#T3-3 (AC-3):** <what was found, cited to PR content — unmet remainder>
**#T3-4 (AC-4):** <what was found>  ·  Drift-rationale: <why not applicable>
**#T3-5 (INT-1):** <what was found>  ·  Drift-rationale: <how re-read>

### Stage-7 escape log

<count + list of defects that escaped Stage-7 Dev Testing and surfaced at QA
(§2 escape detection). "None" if no escapes.>

### Machine-readable acceptance block

```
# acceptance-matrix v1 · issue:#<N> · release:v<X.Y> · verdict:<ACCEPT|CONDITIONAL_ACCEPT|REJECT|HOLD> · score:<0.000> · met:<n>/<total>
id:AC-1  | verdict:MET                       | severity:-       | disposition:-           | evidence:T3-1
id:AC-2  | verdict:NOT_MET                    | severity:Blocker | disposition:fix-now     | evidence:T3-2
id:AC-3  | verdict:PARTIAL                    | severity:Warning | disposition:defer:#NNN  | evidence:T3-3
id:AC-4  | verdict:N_A_WITH_RATIONALE         | severity:-       | disposition:accept      | evidence:T3-4
id:INT-1 | verdict:REINTERPRET_WITH_RATIONALE | severity:-       | disposition:accept      | evidence:T3-5
```

<!-- end rendered-report scaffold -->

---

## Authoring Notes

- **One template, six sections, three tiers.** Do not drop a section — a report
  missing any of the six §6 outputs is incomplete. A tier with no content in a
  given section renders the section header with an explicit `None`.
- **The verdict is the gate; the score is a signal.** Stage-8 Step-0 fixes
  `NOT MET` now regardless of score. Tier 1 renders the score as fitness context,
  not a pass/fail line.
- **Cite by section, never by line number.** References to `stage-08-qa-testing.md`
  and `acceptance-assertion-type.md` name the section (§5 / §6 / §4) in prose so a
  re-heading does not rot the reference.
- **Never invent a verdict value.** The `Verdict` column domain is exactly the
  six-value `stage-08-qa-testing.md` §5 enum. If a criterion needs a value the
  enum does not carry, that is an upstream finding, not a new column value.
