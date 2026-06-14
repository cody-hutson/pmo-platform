# Change-Methodology Selection Reference

## Purpose

This reference is the authoritative source for selecting the applicable change
methodology — or methodology **combination** — for a given change context. It is
consumed by the change-management skill's Mode-Selection Step 2.5 (Modes A — Impact
assessment, C — Readiness checklist, D — Hypercare plan) and by artifact-generator. It
owns the cross-methodology selection judgment (which of ADKAR / Kotter / Lewin / Bridges
/ 7-S applies, and how they compose), the delivery-approach → methodology-combination
mapping (the authoritative promotion of the `impact-assessment.md` seed table), and the
runnable selection procedure.

It is the **selector over** the five methodology references — each of which owns its own
internals and is the single source of truth for them: `adkar-framework.md` (the ADKAR
scoring scale and barrier-point rule), `kotter-8-step.md` (the 8-step sequence),
`lewin-3-stage.md` (the 3-stage change-state frame and Force-Field), `bridges-transition.md`
(the 3-zone psychological transition), and `mckinsey-7s.md` (the 7-element alignment
diagnostic). This doc does **not** restate those internals; it decides among them and
points to each for the depth.

## 1. The Layered Model (the organizing spine)

The five methodologies are **not five competing options** — they are **layers of one
change**. A real change usually selects a **combination**: one frame, one or more
operational layers, and the alignment cross-section as needed. This is why the selector
outputs a *combination*, not a single pick — the layers compose by construction, and the
seed table (§4) proves it (Waterfall → Lewin + ADKAR; Scrum → ADKAR + Bridges; SAFe →
Kotter + 7-S + ADKAR).

| Methodology | Layer | Unit of change | Temporal shape | Select when |
|-------------|-------|----------------|----------------|-------------|
| **Lewin (3-Stage)** | FRAME (the substrate) | The change state | State model (Unfreeze → Change → Refreeze) | You need the simplest change-state frame, or the foundational map to situate the others — **the frame the others operationalize**. See `lewin-3-stage.md` §1, §7. |
| **Kotter (8-Step)** | ORG-PROCESS | The organization (top-down) | Sequence (8 steps) | Leading a large, top-down, urgency-driven transformation through the organization. See `kotter-8-step.md` §11. |
| **ADKAR** | INDIVIDUAL-BEHAVIORAL | The individual (per person/group) | Sequence (5 elements) | You need to know *whether each group is ready* and where each is blocked — per-group readiness scoring (what people are *doing*). See `adkar-framework.md` §1, §4. |
| **Bridges (Transition)** | INDIVIDUAL-PSYCHOLOGICAL | The person's psychology (transition) | Phase model (Ending → Neutral Zone → New Beginning) | Identity/loss/emotional disruption is the dominant risk, and the change keeps failing to "take" despite good execution — what people are *feeling*; **runs underneath any structural layer**. See `bridges-transition.md` §6. |
| **McKinsey 7-S** | ALIGNMENT cross-section | The org's seven elements | Static snapshot (no sequence) | Diagnosing whether the seven org elements (Strategy/Structure/Systems/Shared-Values/Skills/Style/Staff) are mutually consistent before, during, or after a change — read at any point. See `mckinsey-7s.md` §6. |

**The spine principle:** these are *layers* of one change, not five mutually-exclusive
methods. **Lewin is the FRAME** — the Unfreeze → Change → Refreeze substrate the others
operationalize. **Kotter** is the org-process layer that drives a top-down transformation
through that frame. **ADKAR** is the individual-behavioral layer (per-group readiness
state). **Bridges** is the individual-psychological layer (the inner transition, running
underneath the structural layers). **7-S** is the alignment cross-section, a static
snapshot read at any stage. A major change usually selects **a frame + one or more
operational layers + the cross-section as needed** — not one method to the exclusion of
the rest.

### The meta-frame mapping (Lewin is the substrate)

The operational methodologies each map onto Lewin's three stages — they are
different-altitude operationalizations of the *same* Unfreeze → Change → Refreeze arc.
This mapping is adopted byte-consistent from `lewin-3-stage.md` §1 and `kotter-8-step.md`
§11 so the docs agree:

| Methodology | Unfreeze | Change | Refreeze |
|-------------|----------|--------|----------|
| **Kotter (8-Step)** | Steps 1-4 | Steps 5-7 | Step 8 |
| **ADKAR** | A, D | K, Ab | R |
| **Bridges (Transition)** | Ending | Neutral Zone | New Beginning |
| **7-S** | Alignment cross-section read at any stage — not stage-bound | | |

When in doubt about which methodology a change needs, **locate the change in Lewin's
three stages first**, then pick the finer lens for the stage that carries the dominant
risk.

## 2. The Selection Axes

The selector decides on **five orthogonal axes**, each grounded in the methodologies'
own published characteristics. The axes are **read (inferred) from the change context** —
the impact assessment, the `delivery_approach`, and the stakeholder/risk picture — not
asked as five separate questions. The agent infers them and asks the user only when the
unit-of-change or dominant-risk is genuinely undeterminable from the available context.

| # | Axis | Values (enum) | What it tells the selector |
|---|------|---------------|----------------------------|
| 1 | **Unit-of-change** (PRIMARY) | individual-behavioral · individual-psychological · org-process · org-state · org-alignment | The primary axis — it most cleanly separates the five. individual-behavioral → ADKAR; individual-psychological → Bridges; org-process → Kotter; org-state → Lewin; org-alignment → 7-S. |
| 2 | **Delivery-approach** | Waterfall · Scrum · SAFe · PRINCE2 · Kanban · Hybrid · Lean | The project's delivery cadence (the `delivery_approach` enum, owned by `methodology-archetype-matrix.md` — the canonical home of the enum). Keys the combination in §4 Table B. |
| 3 | **Org-scope** | individual · team · org-wide | Whether the change lands on one person, a team, or the whole organization. org-wide top-down → add Kotter; per-group → add ADKAR. |
| 4 | **Time-horizon** | single cutover · multi-increment · continuous | The temporal shape of the rollout — front-loaded cutover vs iterative increments vs continuous absorption. |
| 5 | **Dominant-risk** | readiness-gap · resistance-and-grief · mis-alignment · momentum-and-sequencing · reversion | The risk most likely to sink the change — the **tie-breaker** the delivery-approach axis alone cannot supply (it decides *when to add Bridges*). readiness-gap → ADKAR; resistance-and-grief → Bridges; mis-alignment → 7-S; momentum-and-sequencing → Kotter; reversion → Bridges + a strengthened Refreeze/Reinforcement. |

Axis (1) is primary because it is the axis the five methodology references all chose to
differentiate on (each methodology's §when-to-use keys off unit-of-change). Axis (5) is
the tie-breaker the seed table lacks — delivery-approach alone cannot decide whether a
grief/reversion risk is present, which is a risk judgment, not a cadence fact.

## 3. Selection Table A — Unit-of-change → primary methodology(ies)

The primary selector. Read the unit-of-change axis (axis 1) from the change context and
take the row. Each row names the methodology that **owns** that unit plus the typical
**co-selections**, and cross-links the owning methodology's deep doc for internals.

| Unit-of-change | Primary methodology (owns this unit) | Typical co-selections | Owning deep doc (read for internals) |
|----------------|--------------------------------------|-----------------------|--------------------------------------|
| **individual-behavioral** — "is each group ready" (per-group readiness state) | **ADKAR** | + Bridges underneath when the risk is resistance/grief; + Lewin as the frame | `adkar-framework.md` §1, §4 (scale + barrier-point) |
| **individual-psychological** — emotion/identity/grief is the dominant risk; "successful go-lives keep failing to stick" | **Bridges** | + ADKAR for the behavioral scoring it runs underneath | `bridges-transition.md` §6 (when-to-use), §2-§4 (zones) |
| **org-process** — lead a large top-down transformation, urgency-driven | **Kotter** | + ADKAR per-group readiness; + Lewin as the frame | `kotter-8-step.md` §11 (when-to-use), §1-§9 (steps) |
| **org-state** — need the simplest change-state frame + a feasibility read | **Lewin / Force-Field** (the substrate) | operationalize with the layers above (Kotter/ADKAR/Bridges) inside its stages | `lewin-3-stage.md` §1 (frame), §4 (Force-Field) |
| **org-alignment** — diagnose whether the 7 org elements are mutually consistent before/after | **7-S** (a cross-section) | run alongside whichever sequence is chosen; re-run after to confirm no pair broke | `mckinsey-7s.md` §4 (21-pair diagnostic), §6 (when-to-use) |

A change frequently presents **more than one** unit-of-change (e.g. a cutover that is both
individual-behavioral and individual-psychological). Take **every** matching row, then let
§5 combination logic assemble the layers — do not force the change into a single row.

## 4. Selection Table B — Delivery-approach → methodology-combination (the promoted seed table)

The **authoritative home** for the delivery-approach → methodology-combination mapping.
This table promotes and extends the "Primary Framework" column formerly carried in
`impact-assessment.md`'s Methodology Variation Table — which now points here (see
§Reconciliation). Read the `delivery_approach` axis (axis 2) and take the row.

| Delivery approach | Recommended suite combination | Why this combination | Out-of-suite native practice (named, not mapped) |
|-------------------|-------------------------------|----------------------|--------------------------------------------------|
| **Waterfall** | **Lewin + ADKAR** | Front-loaded: Lewin frames the staged change; ADKAR scores per-group readiness at each phase gate. | — |
| **Scrum** | **ADKAR + Bridges** | Per-increment readiness (ADKAR) + the psychological transition the iterative change drives (Bridges), assessed each sprint. | — |
| **SAFe** | **Kotter + 7-S + ADKAR** | Org-wide transformation cadence (Kotter) + alignment across trains (7-S) + per-group readiness (ADKAR). | — |
| **PRINCE2** | **ADKAR within the stage-gate** | ADKAR scores readiness at each stage boundary; Lewin frames the staged arc if the change is org-wide. | **Benefits Management** is the PRINCE2-native change-benefit apparatus — *outside this suite*; see PRINCE2 / delivery-approach guidance. Do not map it onto a suite methodology. |
| **Kanban** | **ADKAR on the flow** | Continuous per-item readiness scoring (ADKAR) as work crosses the impact threshold. | **STATIK** (Systems Thinking Approach to Introducing Kanban) is the Kanban-native change-initiation method — *outside this suite*; see Kanban / delivery-approach guidance. Do not map it onto ADKAR. |
| **Hybrid** | **7-S + the per-stream combination** | 7-S checks alignment across streams; agile streams take the Scrum row, waterfall streams the Waterfall row. | "Phased stream integration" is the integration *approach*, not a suite methodology — name it as the integration mechanism, not a change methodology. |
| **Lean** | **ADKAR + Bridges on continuous absorption** | Continuous change absorption: ADKAR for behavioral adoption, Bridges for the ongoing transition. | **Respect-for-People** + **improvement/coaching kata** are the Lean-native change practices — *outside this suite*; see Lean / delivery-approach guidance. Do not map them onto a suite methodology. |

**Coverage boundary (honesty rule):** where one of the five suite methodologies applies,
the table states the suite combination. Where the delivery approach has a *native* change
practice outside this five-methodology suite (Benefits Management, STATIK,
Respect-for-People + kata, phased-stream integration), the table **names it as
"outside this suite"** rather than dropping it silently or force-mapping it onto a suite
methodology. Forcing STATIK onto ADKAR (or Benefits Management onto any suite method)
would misrepresent the selector's coverage — see the §Anti-Patterns "Force-mapping an
out-of-suite framework" row.

## 5. Combination Logic (how the layers compose)

The compose-don't-pick engine. Apply these rules to assemble the final combination from
the §3/§4 outputs:

```
(a) FRAME FIRST.
    Lewin is the default substrate — pick it as the frame UNLESS the change is purely
    individual (one group, no org-state shift), in which case the frame is implicit and
    the operational layer stands alone.

(b) ADD THE OPERATIONAL LAYER BY ORG-SCOPE.
    org-wide top-down            -> add Kotter
    per-group readiness          -> add ADKAR
    both (lead the org AND score each group) -> add Kotter + ADKAR
      (they meet at Kotter Steps 5-6 — empower + short-term wins ~ ADKAR Ability/Desire)

(c) ADD BRIDGES WHENEVER dominant-risk = resistance-and-grief OR reversion.
    Bridges runs UNDERNEATH any structural layer. It addresses the two seams:
      un-grieved Ending      <-> ADKAR Desire stall
      incomplete New Beginning <-> ADKAR Reinforcement regression
    (the psychological layer that unblocks a stuck behavioral state).

(d) ADD 7-S WHENEVER the change spans multiple org elements
    (e.g. Structure + Systems + Staff all move) to check alignment before/after.

(e) NEVER select two methodologies that own the SAME layer for the same scope
    (e.g. Kotter AND a second org-process method, or ADKAR AND a second
    individual-behavioral method). That is redundancy, not combination.
```

**Canonical pairings** — the proven combinations, cross-checked against the §4 seed table
and the sibling complementarity notes:

| Combination | When it applies | Compose-point (cited) |
|-------------|-----------------|-----------------------|
| **Lewin + ADKAR** | Staged change needing a frame + per-group readiness (the Waterfall default) | ADKAR's A/D/K/Ab/R map onto Lewin's three stages (`lewin-3-stage.md` §1) |
| **ADKAR + Bridges** | Per-group readiness where grief/identity is the risk (the Scrum default) | Desire ↔ Ending and Reinforcement ↔ New Beginning seams (`bridges-transition.md` §6) |
| **Kotter + ADKAR** | Org-wide transformation + per-group readiness | Meet at Kotter Steps 5-6 ≈ ADKAR Ability/Desire (`kotter-8-step.md` §11) |
| **Kotter + 7-S + ADKAR** | Org-wide transformation needing alignment + readiness (the SAFe default) | 7-S diagnoses the alignment Kotter Step 5 realigns (`mckinsey-7s.md` §6) |
| **Lewin + ADKAR + Bridges** | Staged change, per-group readiness, grief-dominant risk | All three operationalize Lewin's frame; Bridges runs underneath ADKAR |

## 6. The Selection Procedure (runnable — the engine Step 2.5 calls)

The deterministic flow an agent (or SKILL Step 2.5) executes. It ties §§1-5 into a
runnable selection.

```
1. HONOR EXPLICIT CHOICE.
   If the user named a methodology or combination (e.g. "use ADKAR", "Kotter + 7-S"),
   VALIDATE it is coherent per §5 (flag if they picked two methods that own the same
   layer for the same scope) and use it. Skip steps 2-5.

2. READ THE AXES (§2) from the change context:
   - unit-of-change  <- the impact assessment (what is changing for whom)
   - delivery_approach <- the project (the methodology-archetype-matrix.md enum)
   - org-scope, time-horizon, dominant-risk <- the stakeholder / risk picture
   Ask the user only if unit-of-change or dominant-risk is genuinely undeterminable.

3. RUN TABLE A (§3) on unit-of-change -> primary methodology(ies) + co-selections.
   (Take EVERY matching unit-of-change row; a change may present more than one.)

4. RUN TABLE B (§4) on delivery_approach -> methodology-combination + rationale,
   then RECONCILE A ∩ B:
   - if A and B agree, the combination is their union;
   - if they DISAGREE, the dominant-risk axis (§2 axis 5) breaks the tie —
     name WHICH axis won and why.

5. APPLY §5 COMBINATION LOGIC to assemble the final combination:
   frame (Lewin, unless purely individual)
   + operational layer(s) by org-scope (Kotter and/or ADKAR)
   + Bridges if dominant-risk = resistance-and-grief OR reversion
   + 7-S if the change spans multiple org elements.
   Enforce rule (e): never two methods on the same layer for the same scope.

6. EMIT THE SELECTION:
   - the chosen methodology-COMBINATION (never a bare single pick unless the context
     genuinely warrants one);
   - a one-line rationale per chosen methodology;
   - the relative-path pointer to each chosen methodology's deep doc, so the consuming
     mode reads the right internals.
```

Output is a **named combination with cited rationale** — the consuming mode (A/C/D) then
reads each chosen methodology's deep doc for its internals.

## 7. Worked Example — selecting for a real change

A fully-worked run of the §6 procedure on one named change: an **ERP/WMS cutover for
Warehouse Ops and Buying & Planning, on a Waterfall delivery, where the dominant risk is
resistance-and-grief** (the team has lived in the legacy system for years). This
demonstrates the procedure and serves as the regression fixture.

**Step 2 — Read the axes:**

| Axis | Read value | Source |
|------|-----------|--------|
| Unit-of-change | individual-behavioral **and** individual-psychological | Two functional groups must adopt new behaviors (behavioral) and let go of a long-held legacy way of working (psychological) |
| Delivery-approach | Waterfall | Phase-gated ERP program |
| Org-scope | org-wide-ish (two functions, top-down sponsor) | Warehouse Ops + Buying & Planning |
| Time-horizon | single cutover | One go-live date |
| Dominant-risk | resistance-and-grief | The legacy system is identity-laden; comparable go-lives kept reverting |

**Step 3 — Table A (unit-of-change):**
- individual-behavioral → **ADKAR** (per-group readiness scoring)
- individual-psychological → **Bridges** (the transition under the cutover)

**Step 4 — Table B (delivery-approach) + reconcile A ∩ B:**
- Waterfall → **Lewin + ADKAR** (frame the staged change; score readiness at phase gates)
- Reconcile A ∩ B: A contributes Bridges (the psychological unit); B contributes the Lewin
  frame. They do not conflict — the **dominant-risk axis (resistance-and-grief) adds
  Bridges** on top of the Waterfall default. No tie to break; the axes are additive here.

**Step 5 — §5 combination logic:**
- (a) frame first → **Lewin** (the change is org-state-shifting, not purely individual)
- (b) operational layer by scope → **ADKAR** (per-group readiness; the sponsor leads but
  the live risk is group adoption, so ADKAR over Kotter here)
- (c) dominant-risk = resistance-and-grief → **add Bridges** (run underneath ADKAR; attend
  the Desire ↔ Ending seam so the WIIFM framing lands on a grieved loss)
- (d) 7-S **not** triggered — the change moves process + staff, not the full seven elements
- (e) no two methods on the same layer — satisfied (one frame, one behavioral, one
  psychological)

**Step 6 — Emit:**

> **Selected combination: Lewin (frame) + ADKAR (per-group readiness) + Bridges (transition).**
> - **Lewin** — frames the Unfreeze → Change → Refreeze arc of the cutover and the
>   Force-Field feasibility read. → `lewin-3-stage.md`
> - **ADKAR** — scores Warehouse Ops and Buying & Planning readiness per element at each
>   phase gate; identifies the barrier point per group. → `adkar-framework.md`
> - **Bridges** — runs underneath ADKAR to address the grief of letting go of the legacy
>   system; works the Desire ↔ Ending seam so Desire interventions land. → `bridges-transition.md`
> - **7-S** — not selected (the change does not span the full seven org elements).

An agent reading only this document must reproduce this run: read the axes → ADKAR +
Bridges (Table A) → Lewin + ADKAR (Table B) → dominant-risk adds Bridges → emit Lewin +
ADKAR + Bridges with the per-methodology rationale and deep-doc pointers.

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Single-pick when the context is layered** | The selector forces ONE methodology when the change needs a combination (e.g. picks ADKAR alone for a grief-dominant cutover and omits Bridges) | Treating the five as mutually-exclusive options rather than layers; the seed table itself proves combinations are normal | Run §5 — pick the frame, then add operational layer(s) by scope and Bridges/7-S as the risk triggers; emit a combination, not a lone pick |
| **Picking two same-layer methodologies** | The combination names two methods that own the same layer for the same scope (e.g. ADKAR + a second individual-behavioral method, or Kotter + a second org-process method) | Conflating "more methodologies" with "more rigor"; redundancy dressed as thoroughness | Enforce §5 rule (e) — never two methods on the same layer for the same scope; one frame + one operational layer per scope + cross-sections as needed |
| **Delivery-approach as the only axis** | The selector reads Table B (§4) and stops, ignoring unit-of-change and dominant-risk → misses Bridges when grief is the real risk | Table B is the easiest axis to read (one project fact); the risk-judgment axes take more work | Always read all five axes (§2); the dominant-risk axis is the tie-breaker that decides when to add Bridges — Table B alone cannot supply it |
| **Force-mapping an out-of-suite framework** | STATIK / Benefits Management / Respect-for-People+kata is jammed onto a suite methodology to avoid saying "outside this suite" | Discomfort with naming a coverage gap; the urge to make every cell map to one of the five | Per §4 coverage-boundary rule, NAME the out-of-suite practice as "outside this suite" and route to its native guidance; never force-map it onto a suite method |
| **Skipping the frame** | The selector jumps straight to an operational method (Kotter/ADKAR) without situating the change in Lewin's stages | Operational methods feel more concrete than the meta-frame; the frame seems like overhead | Apply §5 rule (a) — frame first (Lewin) unless the change is purely individual; the frame is what tells you which stage carries the dominant risk |

## Behavioral Markers

| Dimension | Principal | Junior |
|-----------|-----------|--------|
| **Axis-reading** | Infers all five axes from the change context (impact assessment, delivery_approach, stakeholder/risk picture); asks the user only when unit-of-change or dominant-risk is genuinely undeterminable | Asks the user five separate questions, or reads only the delivery_approach and skips the risk axes |
| **Combination judgment** | Composes layers — emits a frame + operational layer(s) + Bridges/7-S as triggered, with a rationale per methodology | Single-picks one methodology and treats the others as rejected alternatives |
| **Frame-first discipline** | Selects the Lewin substrate first, then locates the dominant risk in its stages, then adds the finer lens | Jumps to an operational method (Kotter/ADKAR) without framing the change-state arc |
| **Risk-driven Bridges inclusion** | Adds Bridges whenever the dominant risk is resistance-and-grief or reversion — works the Desire ↔ Ending and Reinforcement ↔ New-Beginning seams | Omits Bridges because the delivery-approach row (Table B) did not name it, missing the psychological layer under a stuck behavioral state |
| **Coverage honesty** | Names out-of-suite frameworks (STATIK, Benefits Management, Respect-for-People+kata) as "outside this suite" and routes to native guidance | Force-maps an out-of-suite practice onto a suite methodology to make every cell resolve |
