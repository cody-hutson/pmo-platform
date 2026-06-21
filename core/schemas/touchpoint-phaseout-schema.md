<!-- repo-integrity: allow-issue-ref -->
# Operator-Touchpoint Inventory + Phase-Out-Plan Schema

**Status:** Canonical
**Owner:** `core/schemas/touchpoint-phaseout-schema.md`
**Layer:** 1 (Engineering, git-tracked)
**Type:** schema-spec doc (the K1 *grammar*; the populated inventory + phase-out plan is a K4 *instance*, operator-local and git-ignored)
**Establishing milestone:** `71-autonomy-phaseout-foundation`
**Architectural basis:** see the Design rationale section below (placement in `core/schemas/`; grammar tracked, instance operator-local; `current_phase` references the progressive-rollout convention's enum by name; structural validation by a skip-when-absent deploy-check).

---

## 0. What this document is (and is NOT)

This is the **grammar** for two coupled artifacts that together let the platform run the autonomy phase-out telos — graduating a human gate from a hard stop to fully automated, observably and reversibly:

1. The **touchpoint-inventory schema** — the field-set that enumerates every point in the 13-stage pipeline where agent execution pauses for human judgment (an approval, a GO/NO-GO, a scope-lock, a review-comment, a Tier-0 premise rejection).
2. The **phase-out-plan schema** — the per-pilot planning overlay (success criteria, SLO, FMEA risks, rollback path, phase sequence) that governs how a single touchpoint advances toward `removed`.

Both schemas live in **one doc** because they are one coherent contract: the phase-out plan's rows key on the inventory's `touchpoint_id`. Splitting them would force a cross-file foreign-key seam with no offsetting benefit.

| This document IS | This document is NOT |
|---|---|
| The **grammar** (field set, types, requiredness, structural predicates) an instance is validated against. | A populated inventory. The populated rows (≥1 per pipeline stage) are a K4 instance, authored operator-local and git-ignored — never committed to this corpus (template purity per ADR-012). |
| K1 codified-knowledge (the shape is universal — every deployment's pipeline has touchpoints). | K4 instance data. One deployment's specific touchpoints, phases, dates, and pilot selections are operator-local planning data. |
| A contract a structural check (`deploy.sh --check` Check 39) validates an instance against. | An enforcement surface for the *content* of an operator's phase-out decisions. Advancement stays an operator judgment call. |

**The schema↔instance split.** The reusable grammar is tracked here; the populated instance is operator-local. This mirrors the established platform pattern (the work-item type-pack meta-schema: "the grammar every type-pack conforms to" is tracked K1; "a project's declared kinds are operator-local … never authored into this git-tracked corpus"). The instance home is the operator-local roadmaps tree (the git-ignored `*/governance/roadmaps/` seam) or an operator-local analysis path; it is never in the PR. AC1/AC3/AC5 are satisfied by spoke evidence against that instance, not by a corpus diff.

---

## Design rationale

Why this artifact takes the shape it does — the durable placement and contract decisions, version-agnostically:

- **Home is `core/schemas/`.** Per the `core/schemas/` charter, this tree holds the typed-format contracts that agents and gates validate documents and handoffs against — exactly what this doc is (a field-set an instance is structurally checked against), as distinct from a normative "what good looks like" standard. Its peers are `core/schemas/work-item-type-schema.md` and `core/schemas/entity-field-schemas.md`.
- **Grammar tracked, instance operator-local.** Only the reusable grammar lives here; the populated inventory + phase-out plan is operator-instance planning data (one deployment's specific touchpoints, phases, dates, and pilot selections — not template content), so it stays operator-local and git-ignored. This is the same grammar-vs-instance split the roadmap-instance descope posture applies, and the reason a template downloader receives the contract rather than one operator's data.
- **`current_phase` references the phase enum by name.** The progressive-rollout convention is the single home of the rollout-phase vocabulary; this schema consumes it by reference (§1), so a rename of a phase value propagates without re-authoring this schema.
- **Structural validation by a skip-when-absent deploy-check.** A `deploy.sh --check` validates an instance structurally (field/enum shape, not the content of the operator's judgment); it skips cleanly when the instance is absent — a fresh clone or CI has no operator-local file — and ships warn-mode-initial through the shared deploy-check mode machinery, dogfooding the early phases of the very convention this schema serves.

---

## 1. The `current_phase` enum — referenced by name, not redefined here

Both schemas carry a `current_phase` field (and the phase-out plan a `target_phase` and an ordered `phase_sequence`). The **domain** of all three is the canonical rollout-phase enum owned by the progressive-rollout convention at `core/standards/progressive-rollout-convention.md`. That convention is the single home of the phase vocabulary; this schema consumes it by reference and does **not** redefine it (parameterize-over-hardcode — reference the source of truth, never embed the changing value as authoritative; register-or-remove — the enum lives in exactly one canonical home).

The convention's enum, summarized inline so this schema stands on its own:

```
shadow → warn → enforce → removed
```

- `shadow` — the mechanism evaluates and logs a `would-fire` hit but takes no action and surfaces nothing at run time.
- `warn` — on a hit it emits an operator-facing notice and logs, but does not block.
- `enforce` — on a hit it blocks the action with an actionable finding.
- `removed` — the terminal decommission rung: the mechanism (or the human gate it guarded) is retired. Re-instating a `removed` mechanism re-enters at `shadow`, never silently back at `enforce`.

Advancement is one rung at a time and is **always an operator decision, never auto-promoted by a numeric hit-count.** Retreat is the inverse single edit, except `removed`, whose re-entry routes back to `shadow`. The authoritative per-phase contract (observable behavior · telemetry · advance criteria · retreat trigger) lives in the convention; consult it there. If the convention ever renames a phase value, only this summary updates — the contract (reference-by-name) is already correct, so no `current_phase` field re-authoring is required.

### 1.1 Subject-disambiguation note (CDF-1) — read before populating `current_phase`

The progressive-rollout convention applies the phase enum to a **governance mechanism** (a hook, a deploy-check, a quality gate) — `enforce` there means *the mechanism blocks*. This schema reuses the **same phase values** to describe the **touchpoint's automation state** — the **inverse-autonomy reading** of the convention's mechanism-rollout ladder. The subject is the human touchpoint, not a blocking mechanism:

| Phase value | Mechanism reading (the convention's subject) | Touchpoint reading (THIS schema's subject) |
|---|---|---|
| `shadow` | mechanism observes silently, takes no action | the touchpoint's phase-out is being trialled — the agent runs the step in the background while the human gate still stands |
| `warn` | mechanism emits a notice but does not block | the human gate still stands, but the agent surfaces its own would-be decision alongside for comparison |
| `enforce` | mechanism blocks the action | **the human is still in the loop — the gate is live and hard** (this is the touchpoint's *current, un-phased-out* state) |
| `removed` | mechanism is decommissioned | **the gate is automated or retired** — the human touchpoint no longer fires |

The load-bearing inversion: a touchpoint at `current_phase: enforce` means the **human still gates** (maximum operator engagement); a touchpoint at `current_phase: removed` means the **gate is gone** (full automation — the phase-out telos achieved). Read against autonomy tiers, `enforce → removed` IS a Tier-0-human-gate becoming Tier-3-autonomous (or retired). Every existing human gate in the inventory starts at `current_phase: enforce` (they all currently hard-gate); the whole point of the phase-out plan is to move a chosen few toward `removed` through `shadow` and `warn`.

---

## 2. Touchpoint-inventory schema (16 fields)

One row per operator touchpoint. The instance carries ≥1 touchpoint per pipeline stage (≥13 rows — AC1 floor). The 16 fields, in order:

| # | Field | Type | Required | Purpose |
|---|---|---|---|---|
| 1 | `touchpoint_id` | string (stable key, e.g. `TP-S02-triage-approval`) | YES | Primary key; phase-out-plan rows key on it. Format: `TP-S<NN>-<slug>` (`S<NN>` = pipeline stage; `Sxx` for cross-stage). |
| 2 | `stage` | enum (pipeline stage `1`–`13`, or `cross-stage`) | YES | Which stage the touchpoint sits in. The row axis of the AC5 phase-state matrix; the ≥1-per-stage floor keys on it. |
| 3 | `touchpoint_name` | string | YES | Human label for the touchpoint. |
| 4 | `description` | string | YES | What the human does at this point (the judgment they render). |
| 5 | `autonomy_tier` | enum `{0,1,2,3}` per `core/specs/autonomy-tiers.md` | YES | Current operator-engagement level (0 = manual … 3 = autonomous). |
| 6 | `interaction_modality` | enum `{AskUserQuestion, chat-approval, GO/NO-GO, review-comment, scope-lock, premise-rejection}` | YES | The mechanism through which the human acts (the "How" per the engagement charter's touchpoint contract). |
| 7 | `reversibility_tier` | enum `{CHEAP, MODERATE, EXPENSIVE, IRREVERSIBLE}` per `core/specs/reversibility-protocol.md` | YES | Reversibility of the underlying action. Gates phase-out eligibility — CHEAP touchpoints pilot first. |
| 8 | `current_phase` | enum := the phase enum from `core/standards/progressive-rollout-convention.md` (§1; CDF-1 §1.1) | YES | The touchpoint's automation state. Column axis of the AC5 matrix. Existing hard gates = `enforce`. |
| 9 | `irreducible_human` | bool | YES | `true` iff the touchpoint appears in the autonomy-tiers irreducible-human-tasks list — it must **never** phase out. An `irreducible_human: true` row may not carry `automation_candidate: true`. |
| 10 | `automation_candidate` | bool | YES | Eligible for phase-out at all. Mutually exclusive with `irreducible_human: true`. |
| 11 | `target_phase` | enum := the phase enum (§1) | NO | The desired end-state phase for an `automation_candidate`. `—` when not a candidate. |
| 12 | `telemetry_signal` | string | NO | What to observe in `shadow`/`warn` to judge readiness to advance. The SLO source for the phase-out plan; the telemetry-contract seam with the convention's per-phase telemetry element. |
| 13 | `phaseout_plan_ref` | string (FK → a phase-out-plan `touchpoint_id`, or `—`) | NO | Links an inventory row to its phase-out plan. Populated only for touchpoints with an authored plan (the 3 pilots). |
| 14 | `owner` | string (a **role**, never a person) | YES | Who owns the phase-out decision for this touchpoint. |
| 15 | `notes` | string | NO | Free text — ambiguity flags, cross-stage span notes, Grade-C candidate touchpoints. |
| 16 | `last_phase_advanced` | date (`YYYY-MM-DD`) or `—` | YES | When this touchpoint last advanced a phase (e.g., `shadow → warn`). `—` if never advanced. |

### 2.1 Phase-state roll-up matrix (AC5) — regeneration rule

The instance carries a **phase-state matrix** at the top of the inventory for <30-second reviewer comprehension. It is a **derived roll-up**, regenerated from the rows — never hand-maintained:

- **Rows:** each `stage` value present in the inventory (13+).
- **Columns:** each `current_phase` enum value (`shadow`, `warn`, `enforce`, `removed`).
- **Cells:** the count of touchpoint rows with that `(stage, current_phase)` pairing.
- **Regeneration rule:** `group-by stage × current_phase, count`. Re-run this group-by whenever any row's `stage` or `current_phase` changes; the matrix is the output, the rows are the source of truth. A matrix cell that disagrees with a row-level count is a regeneration miss, not a real state.

---

## 3. Phase-out-plan schema (the per-pilot FMEA overlay)

The phase-out plan is the second schema in this doc. Each row is the plan for advancing **one** touchpoint toward its `target_phase`, keyed on `touchpoint_id` (a foreign key into the inventory). The instance authors a plan row for each of the 3 CHEAP pilot touchpoints (§4). Per-row fields:

| Field | Type | Requirement | Structural predicate (Check 39 / §5) |
|---|---|---|---|
| `touchpoint_id` | FK → an inventory `touchpoint_id` | Resolves to a real inventory row | The value matches an inventory row's field 1. |
| `success_criteria` | string (a **testable** predicate) | Measurable — a comparison or measurable verb | Contains one of `≥ <= >= == exactly zero` or an equivalent measurable predicate. |
| `slo` | string (**quantitative**) | A number plus a unit | Numeric value + unit present (e.g., `0 missed gates over 10 releases`). |
| `risks` | list, **≥2 entries**, each FMEA-conformant | ≥2 risks; each carries severity + likelihood + detectability + mitigation | Each risk row has all four FMEA sub-fields populated. |
| `rollback_path` | ordered list (imperative steps) | Numbered/`-` list of imperative steps | At least one ordered step, imperative verb-led. |
| `phase_sequence` | ordered enum list (a subset of the §1 enum, in order) | The sequenced removal order, ending at `target_phase` | Each element is a §1 phase value, in advancing order (e.g., `shadow → warn → enforce → removed`). |
| `current_phase` | enum := the phase enum (§1) | The plan row's current state (mirrors the inventory row) | Per §1 / CDF-1 §1.1. |

### 3.1 FMEA risk sub-structure

Each of the ≥2 risks per plan row is FMEA-conformant — the structure that makes a risk prioritizable (RPN = severity × likelihood × detectability):

| Sub-field | Domain | Meaning |
|---|---|---|
| `severity` | `{1–5}` or `{Low, Med, High}` | Impact if phasing out this touchpoint causes a miss. |
| `likelihood` | `{1–5}` or `{Low, Med, High}` | Probability of that failure occurring. |
| `detectability` | `{1–5}` or `{Low, Med, High}` | Whether telemetry (field 12 `telemetry_signal`) catches it before harm. |
| `mitigation` | string | The specific guardrail that lowers severity/likelihood or raises detectability. |

**RPN = severity × likelihood × detectability** is the prioritization output (higher = more urgent to mitigate before advancing). Detectability is telemetry-backed via the inventory's `telemetry_signal` field — a risk you cannot observe in `shadow`/`warn` is a high-detectability-number (hard-to-catch) risk and a reason not to advance.

---

## 4. The 3 CHEAP pilot touchpoints

The phase-out plan pilots on the **cheapest-to-reverse** touchpoints first (CHEAP per the reversibility protocol). The three pilots, fixed at design:

1. **Stage 2 Triage approval** (`TP-S02-triage-approval`) — Triage already auto-executes without per-action approval; a natural `shadow` candidate. CHEAP.
2. **Stage 3 Bundle scope-confirm** (`TP-S03-bundle-scope`) — bundle-composition confirmation; reversible via the existing re-bundle protocol. CHEAP.
3. **Stage 13 Close verify** (`TP-S13-close-verify`) — close-out verification; a mechanical post-GO step. CHEAP.

Each pilot's inventory row sets `automation_candidate: true`, a `target_phase`, a `telemetry_signal`, and a `phaseout_plan_ref`; each pilot's phase-out-plan row carries the full §3 field set with ≥2 FMEA risks.

---

## 5. Structural-check predicates (AC6) — what `deploy.sh --check` Check 39 validates

The instance is operator-local and git-ignored, so the structural check is **skip-when-absent**: with no instance present (a fresh clone, CI, or any machine without the operator-local file), Check 39 SKIPs cleanly and never fails. When an instance IS present, Check 39 validates it **structurally** (field presence + type/enum shape — not the *content* of the operator's judgment) and runs **warn-mode-initial** through the shared deploy-check mode machinery (dogfooding the `shadow`/`warn` phase of the very convention this release ships). The predicates:

- **P1 (inventory field presence):** every inventory row carries all 10 required fields (1–10 minus the optional 11–13/15; required = `touchpoint_id`, `stage`, `touchpoint_name`, `description`, `autonomy_tier`, `interaction_modality`, `reversibility_tier`, `current_phase`, `irreducible_human`, `automation_candidate`, `owner`, `last_phase_advanced`).
- **P2 (enum conformance):** `current_phase` / `target_phase` ∈ the §1 enum; `autonomy_tier` ∈ `{0,1,2,3}`; `reversibility_tier` ∈ `{CHEAP, MODERATE, EXPENSIVE, IRREVERSIBLE}`; `interaction_modality` ∈ its enum.
- **P3 (mutual exclusion):** no row has both `irreducible_human: true` and `automation_candidate: true`.
- **P4 (FK integrity):** every phase-out-plan `touchpoint_id` resolves to an inventory `touchpoint_id`; every inventory `phaseout_plan_ref` that is not `—` resolves to a plan row.
- **P5 (phase-out-plan field presence):** every plan row carries `success_criteria`, `slo`, `risks` (≥2), `rollback_path`, `phase_sequence`, `current_phase`.
- **P6 (FMEA shape):** every risk carries `severity`, `likelihood`, `detectability`, `mitigation`.

Check 39 is a **structural** gate only. It does not grade whether a `success_criteria` is *good* or a phase-out decision is *wise* — that is operator judgment, never auto-promoted (per the convention's advance-is-an-operator-decision rule).

---

## 6. Inventory methodology (how the instance is produced)

The inventory is an analysis-class deliverable — the output of a **census** (not a sample) of where humans sit in the pipeline loop. The instance carries this methodology header so a re-run can reproduce and audit it.

### 6.1 Unit of analysis + sampling frame

- **Unit of analysis:** one operator touchpoint = a point in the pipeline where agent execution pauses for human **judgment** (an approval, GO/NO-GO, review-comment, scope-lock, or Tier-0 premise rejection). A pure status read is NOT a touchpoint — only a point carrying an operator decision.
- **Sampling frame (census, exhaustive — five sources, triangulated):**
  1. The 13 pipeline stage specs `release/references/pipeline/stage-01..13-*.md` — each "Phase B (Human)" block, stage-transition gate, or operator-decision block.
  2. `core/specs/engagement-charter.md` §2 — the When/Where/What/How touchpoint declarations (the canonical touchpoint-contract surface).
  3. `release/references/how-to/hub-spoke-bridge.md` — the Decision-Briefing procedures and the enumeration of operator touchpoints reserved for genuine judgment gates (Stage 9 GO/NO-GO, Stage 4 D-decisions, Collective Review scope-lock, Tier-0 premise rejection, inter-stage feedback).
  4. `core/specs/autonomy-tiers.md` — the irreducible-human-tasks list (rows that get `irreducible_human: true`).
  5. `release/governance/release-process.md` — the Collective Review Protocol and Inter-Stage Feedback Protocol gates.
- **Coverage target:** ≥1 touchpoint per pipeline stage (the AC1 floor, ≥13 rows). The frame is bounded and small enough to enumerate exhaustively.

### 6.2 Coding scheme

For each touchpoint in the frame, populate the 16 fields by reading the source: `stage` from the file; `interaction_modality` from the named mechanism (AskUserQuestion / GO-NO-GO / review-comment); `autonomy_tier` from the stage's tier; `reversibility_tier` by classifying the underlying action against the reversibility protocol; `irreducible_human: true` iff the touchpoint is in the autonomy-tiers irreducible list; `current_phase: enforce` for every existing human gate (they all currently hard-gate) unless the source says otherwise.

**Ambiguity rules:** a touchpoint spanning two stages (e.g., Collective Review at the 5→6 boundary) is coded to the **earlier** stage with the span noted in `notes`. An unclear modality defaults to `chat-approval` with a flag in `notes`.

### 6.3 Evidence-grading rubric + load-bearing bar

Each row carries an evidence grade and a `file:line` citation:

- **Grade A** — the touchpoint is explicitly named in a stage spec's Phase B / gate block or in engagement-charter §2 (direct citation).
- **Grade B** — the touchpoint is inferred from a named mechanism (e.g., an `AskUserQuestion` call) without an explicit "Phase B" label.
- **Grade C** — the touchpoint is inferred from prose only.

**Minimum load-bearing grade = B.** A row counts toward the ≥1-per-stage floor only at Grade A or B. Grade-C-only candidates are recorded in `notes`; they do not satisfy the floor on their own.

### 6.4 Validity threats (stated before any findings)

| Threat | Mechanism | Mitigation |
|---|---|---|
| Coverage gap | A touchpoint may live in a SKILL.md or hook, not a stage spec. | Triangulate all five frame sources, not the stage specs alone; record the frame sources in the instance so the gap is auditable. |
| Selection bias | Richly-documented stages yield more rows than terse ones. | Enforce the ≥1-per-stage floor as a completeness check — a zero-row stage is a coding failure, not a real absence. |
| Reproducibility | A hand-classified inventory is not byte-reproducible. | Pin the grep commands + a baseline SHA in the instance header; record the grade + `file:line` per row so each coding decision is inspectable. |
| Construct drift | What counts as a "touchpoint" can expand mid-survey. | Fix the unit-of-analysis up front: a touchpoint carries an operator *decision*, not a status read. |

---

## 7. Reversibility

Authoring and reverting this schema + its instance is **CHEAP** (HIGH confidence). The tracked half reverts via a PR revert (one schema doc + one taxonomy reciprocity line + the Check 39 block). The operator-local instance is an operator file delete. No tracked consumer depends on the schema except the release-class-taxonomy future-sibling line, which reverts in the same PR.

---

### Sources

- `#164` — the progressive-rollout convention (`core/standards/progressive-rollout-convention.md`) whose phase enum this schema's `current_phase` consumes by name. Same milestone (`71-autonomy-phaseout-foundation`).
- `#165` — this schema's parent task: define the operator-touchpoint inventory + phase-out-plan schema (units 1+2).
