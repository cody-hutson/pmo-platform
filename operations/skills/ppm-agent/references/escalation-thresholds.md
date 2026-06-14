<!-- reference-durability: allow-link -->
# Escalation Thresholds

## Purpose

Canonical reference for how the PPM Agent scores RAID risks and issues, routes a scored item to the correct escalation tier, and auto-escalates an open RAID item when it goes stale. This document is the **doc-of-record** for two things the PPM Agent owns: the **score → tier routing** (which escalation tier a given exposure score maps to) and the **age-based auto-escalation thresholds** (when a stale item is warned versus escalated). The OPERATIONS.md Stale-RAID Auto-Escalation Protocol references the age thresholds and routing defined here rather than restating the numbers.

The risk-scoring **scale** itself — the 5×5 probability × impact grid, the probability percentage ranges, and the impact dimensions — is owned by the delivery-engine RAID-templates reference (`../../delivery-engine/references/raid-templates.md`, Section 5) and is consumed by delivery-engine Mode G. This document **references that scale, it does not re-derive it.** Re-authoring the scale here would create an unregistered content duplicate of a single source — a duplicate-source-discipline violation that would let the two skills drift on identical scores. What this document adds on top of the shared scale is the routing layer: the score-band → escalation-tier partition and the age axis, both of which are the PPM Agent's concern.

**Consumed by:** PPM Agent SKILL.md Section 6 (Top risks surfacing) and Section 9.4 (Stale follow-ups); the OPERATIONS.md Stale-RAID Auto-Escalation Protocol (cites this as doc-of-record for age thresholds and routing).

> **Why the line-1 `allow-link` marker is present (and must stay).** This file is K1 codified-knowledge (it lives under `*/skills/*/references/`), which makes it durable corpus. It carries net-new markdown links to a cross-skill source — the references to `raid-templates.md` in this Purpose, in Section 1, and in Section 6. The Reference Durability Standard flags any markdown link on a net-new line in a durable-corpus file as a **Class L** finding (see `../../../../core/standards/reference-durability-standard.md`, "Class L — markdown links" and "The override-marker and allowlist mechanism"). The sanctioned suppressor for Class L is exactly the line-1 `<!-- reference-durability: allow-link -->` marker. That marker is **mandatory here, not stylistic**: the reference-durability CI workflow is a required status check, so without the marker this file would fail the gate and block the PR. Do **not** remove the marker to "match the sibling refs in this directory" (none of them carry it) — the siblings carry no cross-skill links; this file does, and the standard, not the directory, governs.

---

## 1. Risk Scoring Matrix (probability × impact = 1–25)

The scoring **scale** is the delivery-engine 5×5 P×I scale. The probability scale (1–5, with percentage ranges) is defined in [`raid-templates.md` Section 5.1](../../delivery-engine/references/raid-templates.md), and the impact scale (1–5, with the schedule/budget/scope/quality/strategic dimensions) is defined in [`raid-templates.md` Section 5.2](../../delivery-engine/references/raid-templates.md). **Do not duplicate those definition tables here — read them at the source.** An exposure score is the arithmetic product `Probability × Impact`, an integer in the range 1–25.

The product grid below is reproduced as a **routing aid only**: it visualizes which score-band (and therefore which escalation tier, per Section 2) every P×I combination lands in. The cell values are pure arithmetic (P × I); the *definitions* of what each P and I level means stay at the source above.

| **P ↓ \ I →** | **I1** | **I2** | **I3** | **I4** | **I5** |
|---|---|---|---|---|---|
| **P5** | 5 | 10 | 15 | 20 | 25 |
| **P4** | 4 | 8 | **12** | 16 | 20 |
| **P3** | 3 | 6 | 9 | **12** | 15 |
| **P2** | 2 | 4 | 6 | 8 | 10 |
| **P1** | 1 | 2 | 3 | 4 | 5 |

The two **12** cells (P4 × I3 and P3 × I4) are the acceptance-criteria cell; both land in the **Program** band (Section 2). Because P and I are integers in 1–5, every product is an integer, so a score always falls inside exactly one band with no fractional value between bands.

---

## 2. Score → Tier Routing (the band boundaries — this document's canonical contribution)

The band edges are adopted **verbatim** from the delivery-engine Exposure Score Interpretation table ([`raid-templates.md` Section 5.4](../../delivery-engine/references/raid-templates.md)) so the two skills never drift on routing for any score. delivery-engine publishes **five** score-bands keyed to owner levels; the PPM Agent routes against the same five band edges, named as an explicit ordered escalation ladder.

The org hierarchy the PPM Agent escalates within has four canonical tier names — **Team / Project / Program / Portfolio** (per `competency-model.md`). delivery-engine's 5th band (15–19, "Program Manager + Sponsor", Red) sits between the Program and Portfolio org tiers: it is a distinct, named escalation **step** — **Program-Critical (Sponsor-engaged)** — not a 6th org tier and not a silent fold into Portfolio. Naming it as its own step is load-bearing for the age axis (Section 3): it keeps the partition a **total, ordered, 5-step ladder** so an age bump is unambiguous and never skips Sponsor engagement.

| Step | Score band | Escalation step name | Owner level (`raid-templates.md` §5.4) | RAG | Default response time | Routes to |
|---|---|---|---|---|---|---|
| **1** | **1 – 4** | **Team** | Team / SM | Green | Next scheduled review | Team lead / Scrum Master |
| **2** | **5 – 9** | **Project** | Project Manager | Yellow | 1–2 weeks | Project Manager |
| **3** | **10 – 14** | **Program** | Program Manager / RTE | Orange | 1–3 business days | Program Manager / RTE |
| **4** | **15 – 19** | **Program-Critical (Sponsor-engaged)** | Program Manager + Sponsor | Red | 1 business day | Program Manager + Sponsor |
| **5** | **20 – 25** | **Portfolio** | Portfolio Manager / Executive | Dark Red | 4–24 hours | Portfolio Manager / Executive |

**Routing rule (deterministic):** `step = band_of(P × I)` using the edges above. The five bands form a total, disjoint partition of 1–25 (no gaps, no overlaps — every integer score lands in exactly one step). The three org-tier *names* a routing surface reports are Team / Project / Program / Portfolio; **Program-Critical** is the Program-tier escalation step (Program owner + Sponsor co-own) that carries the Red severity delivery-engine assigns to 15–19. It is surfaced as its own step so that severity is never lost when a routing surface that only shows the four org-tier names collapses the five bands.

> **Acceptance-criteria trace (worked example, mandatory):** a RAID entry with **P3, I4** → `3 × 4` = **12** → band **10–14** → step **3 = Program** → routes to **Program Manager / RTE**, Orange RAG, 1–3 business-day response. ✓

---

## 3. Age-Based Auto-Escalation Thresholds (doc-of-record)

Age is an **orthogonal axis**, not a modifier of the exposure score. The exposure score measures *consequence-if-it-occurs* (a fixed property of the risk); age measures *how long the item has gone unattended* (a process-neglect signal). Folding age into the score would redefine the shared scale's semantics and silently fork it — so age fires as an independent escalation trigger that can **override the score-derived step upward**, never by mutating the score.

The thresholds are split by RAID type and are two-stage (warn, then escalate). **This document is the canonical home for these values.** A consuming protocol (for example the OPERATIONS.md Stale-RAID Auto-Escalation Protocol) references this table; it does not restate the numbers.

| RAID type | Age since last substantive update | Auto-action | Effect on routing |
|---|---|---|---|
| **Issue** | **> 14 days** | **Warning** — flag `[STALE-WARN]`; surface in PPM Agent Section 9.4 (Stale follow-ups) | No step change; advisory flag only |
| **Issue** | **> 30 days** | **Escalate** — flag `[STALE-ESCALATE]`; raise to the next step above the score-derived step; emit an escalation action | Overrides the score-derived step upward by exactly one step |
| **Risk** | **> 30 days** | **Warning** — flag `[STALE-WARN]`; surface in PPM Agent Section 9.4 | No step change; advisory flag only |
| **Risk** | **> 60 days** | **Escalate** — flag `[STALE-ESCALATE]`; raise to the next step above the score-derived step; emit an escalation action | Overrides the score-derived step upward by exactly one step |

**Combination rule (the override semantics):** final routing step = **max( score-derived step , age-derived step )**, where "max" is the higher position on the explicit 5-step ladder of Section 2:

```
Team (1) → Project (2) → Program (3) → Program-Critical/Sponsor (4) → Portfolio (5)
```

A **warning**-level age action never changes the step (advisory only). An **escalate**-level age action bumps the score-derived step up by exactly **one step on this 5-step ladder**. Because the ladder is the full five-step partition (not the four org-tier names), the bump is injective and unambiguous at every position — critically, a stale item whose score sits in the **Program** step (10–14) escalates to **Program-Critical (Sponsor-engaged)**, engaging the Sponsor; it does **not** jump straight to Portfolio and skip Sponsor engagement. An item already at **Portfolio** (step 5) stays at Portfolio (no step above it).

**What "age since last substantive update" means (the age clock).** Age = `today − Last Updated`, in **calendar days**, where `Last Updated` is the RAID entry's last-update field (per `raid-templates.md` Section 1.1). Because `Last Updated` is a manually-maintained field, the clock resets only on a **substantive** update — a status change, a score or step change, a new mitigation/resolution action, or owner-confirmed progress. A cosmetic touch (re-saving with no change of substance) does **not** reset the age clock; treating it as a reset would let the exact neglect this protocol detects be hidden by re-stamping the date. (Anchoring age to an immutable event log instead of a hand-editable field is the more robust long-term design; until that exists, "substantive update resets the clock" is the operative definition this doc-of-record owns.)

> **Acceptance-criteria age-interaction trace (worked example, mandatory):** the acceptance-criteria entry is a **risk** at age **45 days**. For a risk, 45 > 30 (warn) but 45 < 60 (escalate) → age action = **Warning** (advisory `[STALE-WARN]`), which does **not** change the step. Final routing = `max(Program, —)` = **Program**. ✓ The age-45 / score-12 pairing is precisely the case that tests that a sub-escalation age does not distort the score-derived routing.

---

## 4. Worked Examples

Examples use parameterized RAID IDs (`R-PPM-###`) and a `[PROJECT_KEY]` placeholder rather than any real project key.

**Example 1 — Acceptance-criteria case (mandatory): score routes, age warns but does not bump.**
Risk `R-PPM-014` in `[PROJECT_KEY]`, **P3, I4**, age **45 days**.
- Score = `3 × 4` = **12** → band 10–14 → step 3 = **Program** (Program Manager / RTE, Orange, 1–3 business days).
- Age: risk at 45 days is > 30 (warn) and < 60 (escalate) → **Warning** (`[STALE-WARN]`), no step change.
- Final routing = `max(Program, —)` = **Program**. ✓

**Example 2 — Age escalation bumps the step (into the Program-Critical step, not past it).**
Issue `R-PPM-021` in `[PROJECT_KEY]`, **P3, I4**, age **33 days**.
- Score = `3 × 4` = **12** → step 3 = **Program**.
- Age: issue at 33 days is > 30 (issue-escalate) → **Escalate** (`[STALE-ESCALATE]`), bump up exactly one step → step 4 = **Program-Critical (Sponsor-engaged)** (Red, 1 business day).
- Final routing = `max(Program, Program-Critical)` = **Program-Critical (Sponsor-engaged)**. The bump lands on the Sponsor-engagement step — it does not skip to Portfolio. ✓

**Example 3 — Lower-score item that age escalates one step.**
Issue `R-PPM-021` in `[PROJECT_KEY]`, **P2, I3**, age **32 days**.
- Score = `2 × 3` = **6** → band 5–9 → step 2 = **Project**.
- Age: issue at 32 days is > 30 (issue-escalate) → **Escalate**, bump up one step → step 3 = **Program**.
- Final routing = `max(Project, Program)` = **Program**. ✓

**Example 4 — High score already at the top; age is irrelevant.**
Risk `R-PPM-007` in `[PROJECT_KEY]`, **P5, I5**, age **90 days**.
- Score = `5 × 5` = **25** → band 20–25 → step 5 = **Portfolio** (Portfolio Manager / Executive, Dark Red, 4–24 hours).
- Age: even an escalate-level age cannot bump above the top step → stays **Portfolio**.
- Final routing = **Portfolio**. ✓

---

## 5. Cross-Skill Contract

This section makes the cross-skill dependencies visible at deploy time, per the modular-monolith public-API discipline, and enumerates the maintenance couplings.

**Inbound reference (the scale source).** The probability/impact score *definitions* and the score-band *edges* are owned by [`raid-templates.md` Section 5](../../delivery-engine/references/raid-templates.md) (Sections 5.1 probability, 5.2 impact, 5.4 exposure-band interpretation). This document reuses the Section 5.4 band edges verbatim. Per the duplicate-source discipline the definition tables are referenced, not copied; per the Reference Durability Standard that election of a markdown link (a low-durability rung) over an inline summary (the preferred rung) is justified by the override clause — the full probability-percentage and impact-dimension definition tables cannot be faithfully summarized inline without re-creating the duplicate the discipline forbids — which is why this file carries the line-1 `allow-link` marker.

**Maintenance couplings (both must be honored on any change to the source):**
1. **Band-edge re-tune.** If delivery-engine re-tunes the `raid-templates.md` Section 5.4 band edges or response times, this document's Section 2 table must be re-synced so the two skills do not diverge on routing.
2. **Scale relocation.** If the shared scale is ever promoted to a kernel location (for example a future `core/standards/risk-scoring-scale.md` when a third consumer appears), the links in this document (Purpose, Section 1, this section) must be re-pointed to the new home and the link-resolution check re-run. This is the natural forcing function to convert the link into a more durable registry/self-describing reference at that time.

**Outbound consumers (doc-of-record).** The OPERATIONS.md Stale-RAID Auto-Escalation Protocol references Section 2 (routing) and Section 3 (age thresholds) as the canonical source for those numbers; PPM Agent SKILL.md Section 6 and Section 9.4 reference Section 2 and Section 3 for scoring-and-routing and stale-flag behavior respectively.

**ID prefix.** RAID entries this routing concerns carry the PPM Agent's `R-PPM-###` prefix when PPM-Agent-originated; delivery-engine uses its own `R-DE-###` namespace per the OPERATIONS.md RAID ID namespacing rule.

---

## Provenance

- **Doc-of-record relationship:** the OPERATIONS.md Stale-RAID Auto-Escalation Protocol consumes the age thresholds (Section 3) and routing (Section 2) defined here as their canonical source. This file is authored ahead of that protocol so the protocol references an existing table rather than restating the numbers.
- **Origin:** this reference was created to canonicalize the risk-scoring matrix, tier routing, and age-based auto-escalation thresholds the PPM Agent had no codified home for (PMO Upscale gap analysis, Domain 1 — escalation determinism; decomposed from the escalation-determinism improvement line (tracked as #269)).
