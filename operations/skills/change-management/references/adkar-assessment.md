# ADKAR Assessment Reference

## Purpose

This reference owns the runnable **ADKAR barrier-assessment capability** — the
assessment procedure, the ADKAR Assessment Table output contract, and the
training-timing validation finding. The ADKAR **methodology** — the 1-5 scoring scale,
the barrier-point rule, the per-element interventions, and the ADKAR-gated
training-timing rule — is owned by `adkar-framework.md` (the ADKAR
single-source-of-truth) and consumed here by reference, not restated. Mode G (Adoption
Tracking) emits the assessment; the Mode B (Training Plan) timing-validation hook runs
the timing check.

This is the capability-orchestration sibling of `adkar-framework.md`, in the same
relationship that `impact-assessment.md` (Mode A) and `readiness-checklist.md` (Mode C)
hold to the framework doc: those references apply the canonical scale and barrier rule
without redefining them, and so does this one. Restating the scale, the barrier rule,
or the training-timing gate here would be a duplicate-source-discipline violation
(register-or-remove) — the framework doc is the only place those are defined.

## When to run

- **Mode G assessment** runs when the Mode A methodology selection (SKILL.md Step 2.5)
  includes ADKAR, or on an explicit barrier-assessment request ("run an ADKAR barrier
  assessment", "where is each group stuck on adoption").
- **The Mode B timing-validation hook** runs when a training schedule exists alongside
  an ADKAR assessment — it reconciles the schedule against each audience's ADKAR
  sequence and emits a finding for any training scheduled ahead of its prerequisite
  ADKAR stage.

The assessment reads its impacted audiences from the Mode A impact assessment
(`impact-assessment.md`) and the schedule it validates from the Mode B training plan
(`training-plan.md`).

## Assessment Procedure

Execute the **Unified Assessment Procedure** in `adkar-framework.md §11` for the
scoring → barrier → champion flow (it is the deterministic, single-source procedure;
do not re-derive scoring or barrier logic here). The capability's additions on top of
that procedure are:

1. **Emit the ADKAR Assessment Table** (output contract below) — one row per impacted
   audience.
2. **Label every unsourced score `[ASSUMPTION – CONFIRM]`.** ADKAR scores must be
   grounded in observable behavior per `adkar-framework.md §2`; any score not backed by
   a cited observation is an assumption and is labeled as such (no invention).
3. **Carry a reversibility tier + confidence per row** (and per emitted finding), per
   the skill's Reversibility Discipline — required for pmo-qa-auditor G4.

The barrier stage and readiness verdict in each row are computed per
`adkar-framework.md §4` (the barrier is the first element scoring ≤3 in
A → D → K → Ab → R order; the verdict is derived from it). The intervention named in
each row is the per-element intervention for that barrier stage, read from
`adkar-framework.md §2`.

## ADKAR Assessment Table (output contract)

One row per impacted audience. This is the named artifact Mode G emits. It shares the
column spine of the `adkar-framework.md §3` scoring template and the
`readiness-checklist.md` ADKAR Readiness Summary Table, and adds the two columns the
capability and the skill's discipline require (Intervention and
Reversibility · Confidence).

| Column | Source / Rule | Notes |
|---|---|---|
| **Impacted Audience** | from the Mode A impact assessment | a specific named functional group — never "all users" (inherits the audience-blind guardrail) |
| **A / D / K / Ab / R** | scored 1-5 per `adkar-framework.md §2` scale, grounded in observable behavior | `[ASSUMPTION – CONFIRM]` on any unsourced score |
| **Barrier Stage** | first element ≤3 in A → D → K → Ab → R order, else "None" | computed per `adkar-framework.md §4` |
| **Intervention** | the `adkar-framework.md §2` per-element intervention for the barrier stage | applied by reference — the action for that stage, not a new rule |
| **Readiness** | NOT READY / CONDITIONAL / READY | derived per `adkar-framework.md §4` (barrier ⇒ NOT READY; any element at 4 with none ≤3 ⇒ CONDITIONAL; all 5 ⇒ READY) |
| **Reversibility · Confidence** | tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) + confidence (HIGH / MEDIUM / LOW) per the skill's Reversibility Discipline | required for pmo-qa-auditor G4 |

Table shape (one row per audience):

```
| Impacted Audience | A | D | K | Ab | R | Barrier Stage | Intervention | Readiness | Reversibility · Confidence |
|-------------------|---|---|---|----|----|--------------|--------------|-----------|----------------------------|
| <named group>     | 1-5 | 1-5 | 1-5 | 1-5 | 1-5 | <stage or None> | <§2 intervention> | NOT READY / CONDITIONAL / READY | <tier> · <confidence> |
```

## Training-Timing Validation

The **gate** is owned by `adkar-framework.md §6` (the ADKAR-gated training-timing rule:
deliver Knowledge/Ability training only when Awareness ≥4 AND Desire ≥4 for the group)
and applied in the training plan by `training-plan.md` "Step 2: ADKAR Sequencing
Validation". This capability does not redefine the gate — it **runs the check against an
actual training schedule and emits a structured finding**, which neither the framework
doc nor the training-plan doc does on its own (they state the rule; they do not produce
the finding from a schedule).

A finding fires when, for an audience, a Mode B **Knowledge/Ability training activity is
scheduled before its prerequisite ADKAR stage is met** — i.e., the activity is scheduled
while `Awareness <4 OR Desire <4` for that audience. Finding format (one per violation):

```
FINDING (Training-Timing): <Audience> — <training activity> scheduled <date / T-minus> but
  ADKAR gate unmet: Awareness=<n> / Desire=<n> (barrier: <stage>).
  Remediation: defer <activity>; run <§2 Awareness/Desire intervention> first; re-gate when A≥4 ∧ D≥4.
  Reversibility: <tier> · confidence: <level>   [RAID: R-CM-### when escalated]
```

The remediation names the `adkar-framework.md §2` intervention for the unmet
Awareness/Desire stage (executive messaging / burning-platform narrative for Awareness;
WIIFM framing / involvement in design / address fears / peer champions for Desire). When
the finding becomes a tracked RAID item, it carries the `R-CM-###` prefix per the
skill's RAID ID namespacing.

## Worked Example (capability output)

The regression fixture for ADKAR scoring lives in `adkar-framework.md §12` (three named
groups). Re-use that fixture by reference rather than inventing a parallel one (a second
fixture would drift from the regression source). Reading that fixture's scores
(Warehouse Ops: A=4, D=2, K=3, Ab=2, R=1 — barrier at Desire), the capability output is:

ADKAR Assessment Table (Warehouse Ops row):

```
| Impacted Audience | A | D | K | Ab | R | Barrier Stage | Intervention | Readiness | Reversibility · Confidence |
|-------------------|---|---|---|----|----|--------------|--------------|-----------|----------------------------|
| Warehouse Ops     | 4 | 2 | 3 | 2  | 1  | Desire       | WIIFM framing, involvement in design, address fears, peer champions | NOT READY | MODERATE · HIGH |
```

Training-Timing finding (if Knowledge training were scheduled for Warehouse Ops):

```
FINDING (Training-Timing): Warehouse Ops — Knowledge training scheduled T-2wk but
  ADKAR gate unmet: Awareness=4 / Desire=2 (barrier: Desire).
  Remediation: defer the Knowledge training; run WIIFM framing + involvement in design first;
  re-gate when A≥4 ∧ D≥4.
  Reversibility: MODERATE · confidence: HIGH   [RAID: R-CM-### when escalated]
```

(Scores are read from the `adkar-framework.md §12` fixture; the barrier and readiness
are computed per §4; the intervention is read from §2 — none of it is redefined here.)

## Cross-references

| Reference | What it supplies to this capability |
|-----------|--------------------------------------|
| `adkar-framework.md` | the **methodology source** — §2 scoring scale, §4 barrier-point rule, §6 ADKAR-gated training-timing rule, §11 Unified Assessment Procedure, §12 worked-example regression fixture. This capability consumes all of these by reference. |
| `impact-assessment.md` | supplies the impacted audiences and their five-dimension severity (Mode A); the assessment scores those audiences. |
| `training-plan.md` | supplies the training schedule the timing validation checks, and owns "Step 2: ADKAR Sequencing Validation" (the gate this capability runs against a schedule). |
| `readiness-checklist.md` | Mode C's readiness application of the same `adkar-framework.md §4` rule — kept consistent because both consume the single source. |
