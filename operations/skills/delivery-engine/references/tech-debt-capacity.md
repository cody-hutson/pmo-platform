<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
<!-- provenance: UNSOURCED-DOMAIN -->

# Tech-Debt Capacity

## Purpose

This document is the canonical source of **tech-debt capacity discipline** for the delivery-engine skill — how a sprint plan is held to the per-sprint tech-debt-allocation **floor**, how tech-debt items are prevented from quietly **aging** out of relevance, and how the **rework rate** consumed by carryover from prior incomplete work is tracked and alerted. It is read by **Mode D (Sprint Planning)**: Mode D reads the floor-enforcement discipline (allocation ratio + the 🟢/🟡/🔴 floor-RAG) when building a capacity model, the aged-debt detection threshold and its escalate/reclassify disposition rubric when scanning the in-plan debt items, and the rework-rate formula and its alert cutoff when carryover data is available.

This doc owns the tech-debt-budget **enforcement discipline**. It does **not** own — and does **not restate** — the numeric values it enforces:

- the **floor value (15% default, 15–20% range, "Non-negotiable minimum")** is owned by [`sprint-defaults.md`](sprint-defaults.md) §1.2 (Technical debt allocation); this doc references it **by role** and never re-quotes it as a divergent table;
- the **supply / effective-capacity calculation** is owned by [`capacity-model.md`](capacity-model.md) (available-hours derivation, the 60/20/20 split whose §5 "Improvement + tech-debt" slice independently names the same non-negotiable floor);
- the **buffer three-zone model and buffer-consumption RAG** are owned by [`estimation-standards.md`](estimation-standards.md) §4 / §4.1;
- the **ticket-aging tiers (>30/60/90 days)** are owned by the delivery-engine `SKILL.md` Mode A backlog scan.

**Sibling relationship.** This doc is the topical home for the **tech-debt budget**. Its siblings own adjacent axes: [`estimation-standards.md`](estimation-standards.md) owns **estimation** (the focus-factor table, the buffer three-zone model, the buffer-consumption RAG §4.1, the milestone-variance SPI RAG §7); [`capacity-model.md`](capacity-model.md) owns the **supply** calculation (effective capacity, context-switching, the 60/20/20 split); [`sprint-defaults.md`](sprint-defaults.md) owns sprint **cadence** parameters **and the 15% tech-debt-allocation numeric value** (§1.2). Where this doc needs the floor value, the supply figure, or the buffer model, it references each by its role and does not restate the value — the same single-source seam the cohort docs hold for the focus factor.

**Content provenance.** The **floor % (§1)** and the **aged-debt threshold (§2)** are **in-corpus-grounded** — both are adopted by reference from existing canonical sources (`sprint-defaults.md` §1.2 for the 15% floor; `SKILL.md` Mode A for the >90-day aging tier), not minted here. The **rework-rate cutoff (§3, >20%) and the ~30% runaway-accumulation reference are `UNSOURCED-DOMAIN` (KB-C04 Execution domain evidence), NOT corpus-grounded** — a survey of the delivery-engine and core reference set returns no rework-rate metric, so these two values are flagged **`[ASSUMPTION – CONFIRM]`** and carry an explicit not-computable negative path rather than a fabricated input. This honest split (two adopted, one domain-anchored-assumption) is the doc's grounding posture.

---

## 1. Capacity Floor

The **tech-debt capacity floor** is the per-sprint minimum slice of sprint capacity reserved for tech-debt paydown. Its value — **15% default, 15–20% range, "Non-negotiable minimum"** — is owned by [`sprint-defaults.md`](sprint-defaults.md) §1.2 (Technical debt allocation) and is referenced here **by role**; this doc enforces the floor and does not restate the number. (`capacity-model.md` §5 independently names the same slice a "Non-negotiable floor" within the 60/20/20 steady-state split; the per-sprint 15% floor here and the 20% steady-state apportionment there are two lenses on the same capacity, per `capacity-model.md` §5's own framing — the 15% is the per-sprint minimum, the 20% the steady-state target — not a contradiction.)

**Allocation ratio.** The metric this section bands is the **tech-debt allocation ratio**:

```
Tech-debt allocation ratio = tech-debt-allocated capacity ÷ sprint capacity
```

where *tech-debt-allocated capacity* is the slice of the sprint plan assigned to tech-debt items and *sprint capacity* is the focus-adjusted figure from `capacity-model.md`. The floor breach is **binary at the floor line** (15%); the RAG below adds a methodology-aware watch zone above it.

### 1.1 Floor RAG (allocation vs floor)

A 🟢/🟡/🔴 RAG on the **allocation ratio against the floor** (mirrors the cohort RAG technique — `estimation-standards.md` §4.1 / §7 — applied here to the floor, not to buffer burn or schedule):

| Band | Allocation ratio | Reading | `WHEN…THEN…` decision rule |
|---|---|---|---|
| **🟢 GREEN** | **≥ 0.15 (the floor)** | At or above the non-negotiable floor — the tech-debt slice is intact | WHEN allocation ≥ floor THEN healthy — tech-debt slice intact; plan normally |
| **🟡 YELLOW** | **≥ 0.15 but below the methodology's upper guidance** *(e.g. the 15–20% Scrum/SAFe upper band)* | At the floor minimum but below this methodology's target band | WHEN floor ≤ allocation < methodology-upper THEN watch — at the minimum, not at target for this methodology; protect the slice and note the gap to target |
| **🔴 RED** | **< 0.15 (under floor)** | **Capacity over-committed to new features** — the named failure state | WHEN allocation < floor THEN flag "tech debt under floor — capacity over-committed to new features"; require an explicit PM override (declared + RAID-logged) or re-scope to restore the slice |

**Boundary anchoring (normative — both boundaries adopt existing in-corpus values, neither is invented).** The **0.15 RED boundary directly adopts** the `sprint-defaults.md` §1.2 floor value (the 15% non-negotiable minimum) — it is not a new number. The **methodology-upper edge of the 🟡 band adopts** the same row's 15–20% range upper bound (and the per-methodology variation already encoded in `sprint-defaults.md` §6 — Scrum 15–20% / SAFe Enabler 20–30%). The skill therefore carries **one** 15% floor, not a second competing one.

**Methodology calibration.** The floor's per-methodology target reads the **existing** `delivery_approach` PROJECT.md enum (`Scrum | Kanban | XP | Waterfall | PRINCE2 | SAFe | Hybrid | Custom`) and the per-methodology tech-debt approach already tabled in `sprint-defaults.md` §6 (Scrum 15–20% / Kanban Intangible Class of Service / SAFe Enabler 20–30% / Lean refactoring-continuous). There is **no `tech_debt_floor` config field** and this doc does not introduce one (config-field discipline: a survey of `operator.toml.template` + `project-schema.md` finds only `delivery_approach`). When `delivery_approach` is **absent**, default to the canonical 15% floor and label the methodology `[ASSUMPTION – CONFIRM]`.

**Naming guard (normative).** Name this metric **"tech-debt floor"** / **"tech-debt allocation ratio"** — **NEVER "tech-debt budget overage" or "debt RAG."** The metric name stays aligned with the canonical `sprint-defaults.md` "Technical debt allocation" label. This floor-RAG is **orthogonal to** two sibling RAGs and must not be conflated with either: it is distinct from the `estimation-standards.md` §4.1 **buffer-consumption** banding (which bands *buffer burn*, consumed ÷ iteration-buffer) and from the `capacity-model.md` §9 **demand-supply** RAG (which bands *demand vs supply*). Three orthogonal RAGs, each owned by its topical doc.

**PM override is a declared exception, not a config key.** A sprint plan that allocates below the floor is honored **only** if the PM override is **explicitly declared and logged as a RAID item** (per `raid-templates.md` — never a silent flag and never a new frontmatter key). A silent under-floor plan is flagged 🔴 RED.

**Application / negative-path rule.** When the plan states a tech-debt allocation, compute the ratio, name the active band and its decision rule, and cite the canonical floor source. When **no tech-debt allocation is stated**, the floor cannot be verified — flag it, default to requiring ≥ the 15% floor, and name the canonical source; never default the band to GREEN on absent input.

---

## 2. Aged-Debt Detection

Tech-debt items must not quietly age out of relevance. The aging threshold for tech-debt items is **adopted by reference at >90 days** from the delivery-engine `SKILL.md` Mode A backlog-scan aging tier (the outer band of its existing >30/60/90-day ticket-aging model) — it is not a tech-debt-specific number minted here. On an aged-item hit (a tech-debt item open >90 days), Mode D emits a **disposition proposal** rather than a silent flag, routed through the **existing** RAID / SIOR escalation machinery (`raid-templates.md` §7 SIOR; the "overdue actions auto-escalate within 1 business day" rule):

| Disposition | When | Output |
|---|---|---|
| **Escalate** (pull into the current sprint) | The debt is still relevant and its cost is rising | A tracked RAID Action with an owner + due date (per `raid-templates.md` — never a silent flag) |
| **Reclassify — close as superseded** | The debt no longer applies (code path retired, requirement changed) | A close recommendation with the superseding evidence |
| **Reclassify — accept as permanent** | The debt is a deliberate, owned residual | An accepted-residual note, reversibility-tier-tagged (per CLAUDE.md reversibility discipline) |

**"Debt cannot quietly age out" rule.** This is enforced by the **existing** auto-escalate-overdue mechanism (`raid-templates.md` overdue-action escalation) applied to aged tech-debt items — an item past the >90-day threshold without a recorded disposition escalates to the PM, exactly as an overdue RAID action does. The three-way disposition rubric (escalate / supersede / accept) is the one genuinely-new content piece here — a decision rubric, not a numeric threshold.

**Application / negative-path rule.** When item open-dates are available, evaluate each in-plan tech-debt item against the >90-day threshold and attach a disposition to every aged hit. When **no aged-item data exists** (no open-dates captured), state that aging cannot be computed and recommend capturing item open-dates; never assume items are fresh on absent input.

---

## 3. Rework-Rate Tracking

The **rework rate** is the share of sprint capacity consumed by rework from prior incomplete work (carryover that returns as rework rather than as net-new delivery):

```
Rework rate = capacity consumed by rework from prior incomplete work ÷ total sprint capacity
```

**Alert cutoff = > 0.20** `[ASSUMPTION – CONFIRM]` — a rework rate above 20% triggers a Mode D alert. The **~30% accumulation figure** is the runaway-rework anti-pattern reference (the level at which un-floored debt compounds into systemic rework) `[ASSUMPTION – CONFIRM]`. **Both values are `UNSOURCED-DOMAIN` (KB-C04 Execution domain evidence), NOT corpus-grounded** — a survey of the delivery-engine and core reference set returns **no** rework-rate metric or threshold, so they are flagged for operator confirmation rather than presented as canonical. This is the doc's single genuine assumption; the floor (§1) and aging threshold (§2) are in-corpus-adopted by contrast.

**Input-acquisition step (required — the metric has no input source in the current data model).** Rework-rate input depends on retrospective data that may not be systematically captured. Mode D acquires the input explicitly and never fabricates it:

1. **If rework is tracked** — a `rework` / `carryover-rework` label, or a retrospective field recording rework capacity — read it and compute the rate.
2. **If rework is NOT tracked** — Mode D **does not fabricate a rate**. It emits:

   ```
   rework rate: not computable — no rework-capture source
   ```

   and recommends establishing the input (a retro-capture field for rework capacity). This mirrors the cohort's "no baseline → variance not computable" negative-path pattern (`estimation-standards.md` §7 application rule): name the missing input, recommend establishing it, never default to a fabricated figure.

---

## Floor → Ranking Contract (consumed by the classification/ranking work)

This section is the **contract surface** the sibling classification/prioritization work (`tech-debt-classification.md`) consumes by role. This doc's capacity floor sets the **budget**; the ranking work ranks what fills it. The ranking work reads four named outputs from this doc and does **NOT** re-derive the floor:

| # | Output | Definition | What the ranking work does with it |
|---|---|---|---|
| **(a)** | **Floor %** | The per-sprint floor, by role from `sprint-defaults.md` §1.2 (the 15% non-negotiable minimum) | The target line the ranking work ranks items up to — never re-derived |
| **(b)** | **Allocation ratio** | tech-debt-allocated ÷ sprint capacity (§1) | The current fill level against the floor |
| **(c)** | **Under-floor deficit** | `max(0, floor − allocation-ratio) × sprint capacity` — the capacity below the floor | The capacity the ranking must fill |
| **(d)** | **Aged-item set** | The items >90 days (§2), each pre-flagged with its escalate / reclassify disposition | The aged-debt candidates the ranking work prioritizes into the deficit |

**Contract semantics.** The ranking work ranks tech-debt items (Fowler quadrant × Cost of Delay) **to fill the under-floor deficit (c) up to the floor (a)**, drawing from the aged-item set (d) and the broader debt backlog; the ranking work does **not** re-derive the floor or restate the capacity discipline. The ownership seam: `tech-debt-capacity.md` owns the *budget/floor*; `tech-debt-classification.md` owns the *classification/prioritization*. The ranking work references (a)–(d) by role.

---

## Applicability

Per [`applicability-framework.md`](../../../../core/disciplines/applicability-framework.md).
The tech-debt capacity disciplines below are a **contextual** practice (org-scale +
methodology axes) — they apply to the capacity of a *managed delivery team* running
time-boxed sprints, not to the single-operator platform running the PMO.

- **Universality:** contextual            # org-scale axis + methodology axis
- **Applies when:** the capacity being floored/aged/rework-tracked is that of a **managed
  delivery team** (`org_scale ∈ {small-team, multi-team}`) on a time-boxed track
  (`delivery_approach ∈ {Scrum, XP, SAFe, Hybrid (iterative), Custom (timeboxed)}`) — the
  agile squads a TPM plans for in Mode D.
- **Contraindicated when:** **CI-5** — do **NOT** apply the floor-RAG, aged-debt disposition,
  or rework-rate alert to the **single-operator PMO's own throughput** (the operator is not a
  sprint team; the platform's own improvement allocation is governed by its release process,
  not by a sprint floor); also **CI-4** for the per-sprint floor mechanics on non-time-boxed
  (Waterfall/PRINCE2) tracks, where tech-debt paydown is phase-scheduled rather than
  sprint-allocated (calibrate via the `delivery_approach` enum per §1).
- **On conflict:** `decision-discipline.md` M1 (contextual localization); co-manifestation
  when `dual_framing_enabled: true` — produce both the agile floor framing and the phase-gate
  framing rather than forcing one.

---

## Version History

| Version | Change |
|---------|--------|
| v2.01 | Initial — tech-debt capacity floor (§1, allocation ratio + 🟢/🟡/🔴 floor-RAG, floor value referenced by role from `sprint-defaults.md` §1.2), aged-debt detection (§2, >90d adopted from `SKILL.md` Mode A; escalate/reclassify disposition via `raid-templates.md`), rework-rate tracking (§3, >20% alert `[ASSUMPTION – CONFIRM]` KB-C04 domain + not-computable negative path), and the floor→ranking contract for the classification/ranking work. Created per the Stage-5 design. |
