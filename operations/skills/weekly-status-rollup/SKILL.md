---
name: weekly-status-rollup
description: >
  Generates a weekly executive status roll-up across all active projects. Covers project health, key risks, decisions made/pending, and upcoming milestones. Writes back updated health indicators to PORTFOLIO.md. Triggers: "weekly roll-up", "weekly status", "SteerCo prep", "SteerCo update", "executive status", "portfolio summary", "portfolio health", "cross-project status."
version: v2.20
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---
<!-- reference-durability: allow-link -->

# Weekly Status Roll-Up Workflow

## Role

You produce the weekly executive summary across all active projects in the PMO portfolio.
This is the document that goes to leadership, steering committees, and cross-functional
stakeholders. It synthesizes the week's daily status updates, tracker changes, and
milestone progress into a single cohesive narrative.

After producing the summary, you write back the synthesized health data to PORTFOLIO.md,
keeping the portfolio dashboard current for downstream consumers (daily-status, project-
initiator, visualizations).

You are not summarizing transcripts or analyzing artifacts — that was done during the week
by the PPM Agent and daily status workflow. You are rolling up the results.

## Inputs

Read these files in order before generating:

1. **PORTFOLIO.md** — List of all active projects with governance models and key dates
2. For each active project:
   a. **PROJECT.md** — Current phase, milestones, health status
   b. **Daily Status Log** — This week's AM and PM updates (Monday through current day)
   c. **Daily Status Log carry-forward** — Current blockers, decisions, actions
   d. **Communications Tracker** — Key communications this week (escalations, exec messages)
   e. **RAID entries** — Any new or updated risks/issues from this week
3. **GitHub Issues** — Any improvement proposals created this week: `gh issue list --label "improvement" --json number,title,createdAt --created ">YYYY-MM-DD"` (where date = 7 days ago)

## Reference docs

This skill consumes governed reference docs by **role-name** — it does not restate their
content (duplicate-source-discipline; each doc owns its definitions). The Section 7 (Portfolio
Governance) sub-blocks and the Section 1 dominance check below cite these by role:

| Reference | Owner / module | Consumed by | What this skill reads from it |
|---|---|---|---|
| [`metric-registry.md`](references/metric-registry.md) | this skill (`weekly-status-rollup`) — intra-module | Section 1 health logic + Section 7 per-metric decision-rule validation + lag/lead audit | The cross-level metric → RAG-band → `WHEN…THEN…` decision-rule index. Each reported metric cites its governing rule verbatim from the registry row; this skill follows REFERENCED rows to their owning doc (`channel-formats.md`, `capacity-model.md`, `backlog-health.md`) for the live band rather than re-deriving thresholds. |
| [`watermelon-detection.md`](../../../core/skills/pmo-qa-auditor/references/watermelon-detection.md) | `pmo-qa-auditor` — **core module (via-public-api)** | Section 7 Watermelon Scan + the Section 1 dominance feedback | The **canonical home of the 8-signal watermelon set (W1–W8)** with severity tiers, false-positive filters, and the verdict-composition rule. This skill runs the signals **by reference** — it does **not** fork or restate them. The `operations → core` direction is the sanctioned cross-module flow enumerated in [`operations/README.md` § Cross-Module Dependencies](../../README.md) (markdown-doc-link reference per ADR-007; cross-module consumption posture per [ADR-028](../../../core/ADRs/ADR-028-operations-consume-core-safety-controls-via-public-api.md)). |
| [`capacity-model.md`](../delivery-engine/references/capacity-model.md) | `delivery-engine` — intra-module (operations) | Section 7 Capacity Dashboard synthesis | The §1 effective-capacity formula and §9 Demand-Supply Gap RAG bands. The cross-project capacity view aggregates per-project Capacity Utilization (whose registry row already references this doc) into a portfolio view; it does **not** restate the formula or bands. |

## Output Structure

> Any roll-up artifact persisted to `08-Generated/` is named per the artifact naming standard ([`../../../core/standards/artifact-naming-standard.md`](../../../core/standards/artifact-naming-standard.md): `_` segment separator, `-`-joined one-segment type slug from the controlled vocabulary, optional trailing ISO-8601 date, lowercase extension); versioning/status/lineage stay in frontmatter, never the filename.

### Section 1: Portfolio Health Dashboard

A quick-reference table covering all active projects:

```
| Project | Phase | Health | Sprint/Milestone | Days to Next Gate | Key Risk |
|---------|-------|--------|-----------------|-------------------|----------|
| [Name]  | [Phase] | 🟢/🟡/🔴 | [Sprint X / Phase Y] | [N] | [One-line] |
```

Health color logic:
- 🟢 GREEN: On track, no active blockers, milestone dates holding
- 🟡 YELLOW: At risk — active blockers exist but mitigation in progress, or timeline
  pressure without confirmed slip
- 🔴 RED: Blocked or slipped — confirmed timeline impact, unresolved escalations,
  or critical path broken

### Section 2: Per-Project Summary

For each active project, generate:

**[Project Name] — [Phase] — [Health Color]**

**This Week:**
- 3-5 bullet points covering what happened this week (from daily status updates)
- Focus on outcomes and movement, not activity descriptions
- Include specific numbers where available (bugs resolved, tests passed, decisions made)

**Key Risks & Blockers:**
- Active blockers from carry-forward (with age in business days)
- New risks identified this week
- Escalations in progress

**Decisions Made This Week:**
- Decisions closed (from DEC-### entries that moved to MADE status)
- Include decision-maker and impact

**Decisions Pending:**
- Open DEC-### entries with deadlines
- **Overdue blocking-decision escalation (thresholded + routed).** For each open
  DEC-### entry, compute the overdue clock `today − Deadline` in **business days** (carries
  `[INFERRED: today − Deadline]`; the deadline-keyed clock per
  `../ppm-agent/references/proactive-follow-up-tracking.md` §Aging "starts from the deadline
  date"). The escalation fires only for **blocking-class** decisions (the entry's
  `blocking: true` field — go/no-go, launch-sequence, and similar gating decisions). Apply the
  two-stage, due-date-keyed ladder:
  - **WARN at `> 3 business days` past due** — emit a `[RECOMMENDED]` nudge to the
    decision-maker in the rollup output. **No tier change** (parallel to the Stale-RAID
    Warning band).
  - **ESCALATE at `> 5 business days` past due** — emit an **escalation action** that bumps the
    decision **one tier up** the existing routing ladder in
    `../ppm-agent/references/escalation-thresholds.md` §2 (Team → Project → Program →
    Program-Critical/Sponsor → Portfolio). The escalate action names the decision, the
    decision-maker, the breached `5bd` threshold, and the routed tier. This consumes the
    existing tier ladder by reference — it does **not** author a parallel tier scheme.
  - **Coverage gap on absent `blocking`:** a DEC-### entry with no `blocking` field → treat as
    **non-blocking** (no escalation) and flag the missing classification as a coverage gap on
    first encounter; **never** silently default to blocking.
  - **Cross-skill ownership (mirrors the Stale-RAID split):** this skill **surfaces** the
    overdue-decision escalation in the roll-up; `ppm-agent` (which owns DECISION escalations) is
    the **router**; `delivery-engine` Mode G is where the decision artifact is updated. See the
    OPERATIONS.md **Overdue-Decision Escalation Protocol**. Reversibility **CHEAP** /
    recommend-tier — a flag + routed tag the operator reviews; never auto-decides the decision
    or mutates the tracker without approval (carry the tier per § Reversibility Discipline).

**Next Week Focus:**
- Top 3 priorities for next week
- Upcoming milestones or deadlines
- Required actions or decisions

**Dual-Framing Bridge (conditional):**
Only include when `PROJECT.md` has `dual_framing_enabled: true`.

```
Agile Track: [Sprint progress, velocity, backlog health]
Waterfall Track: [Milestone status, phase gate progress, deliverable status]
Both tracks converge on: [single unified priority or action]
```

### Section 3: Cross-Project Items

- Dependencies between projects
- Shared resource conflicts
- Items that affect multiple projects

### Section 4: Process Health

- File Router performance this week (files classified, misclassifications corrected)
- Tracker Manager stats (updates applied, rejected, evidence gate blocks)
- Unclassified queue status (items pending, age)
- Improvement proposals submitted (from GitHub Issues with `improvement` label created this week)

### Section 5: Looking Ahead (2-Week View)

- Milestones in the next 14 calendar days (across all projects)
- Required decisions with deadlines
- Scheduled meetings (SteerCo, phase gates, reviews)
- Resource or scheduling conflicts

### Section 6: Portfolio Write-Back

After producing the executive summary (Sections 1-5), update PORTFOLIO.md with the
synthesized data. This step keeps the portfolio dashboard current without manual intervention.

**What gets written back:**

For each active project in PORTFOLIO.md:

1. **Portfolio Health Summary table** — Update the row:
   - `Phase`: Current phase from this week's analysis
   - `Health`: 🟢/🟡/🔴 as determined in Section 1
   - `Critical Path Item`: Top blocker or next milestone from Section 2
   - `Go-Live`: Updated if date changed during the week (evidence-tagged)

2. **Health Indicators table** — Update each dimension:
   - `Schedule`: Status + 1-line evidence from this week
   - `Scope`: Status + 1-line evidence
   - `Quality`: Status + 1-line evidence
   - `Stakeholders`: Status + 1-line evidence
   - `Integration Risk`: Status + 1-line evidence (if applicable)

3. **Top Risks** — Replace with current top risks from RAID Log (max 5), citing source

4. **Last Updated** — Set to today's date

**Write-back rules:**
- Only update fields where the weekly analysis produced new evidence
- Tag every changed field with the evidence source: `[SOURCE: Daily Status 3/17]`, `[SOURCE: RAID R-PPM-052]`, etc.
- If a field hasn't changed this week, leave it as-is (don't rewrite identical content)
- If health color changes (e.g., 🟢 → 🟡), note the reason inline
- Present the proposed PORTFOLIO.md changes as a summary for user approval before writing
- Format: "PORTFOLIO.md Update: [N] fields changed for [Project Name]. [1-line summary of most significant change]."

**Human-in-the-loop checkpoint:**
After producing the executive summary and before writing to PORTFOLIO.md, present:
```
📊 Portfolio Write-Back Summary:
- [Project 1]: Health 🟡→🟢 (all blockers resolved this week). Phase unchanged.
- [Project 2]: Phase "Testing" → "Issue Resolution". 3 risk updates.
Approve these changes to PORTFOLIO.md? (Or provide corrections)
```
Wait for user confirmation before writing. If running as a scheduled task, produce the
summary and changes as a draft — flag for approval at next interaction.

### Section 7: Portfolio Governance

Sections 1–6 surface and write back portfolio **state**. Section 7 applies portfolio
**governance discipline** to that state: it catches green-on-the-outside-red-on-the-inside
projects, audits the metric set's balance, reports the investment mix, validates every
reported metric against its governing rule, and synthesizes a portfolio capacity view.
All five sub-blocks consume governed reference docs **by role** (see `## Reference docs`) —
they do not restate thresholds, signals, or formulas.

Run Section 7 over **every** active project — including a single-project portfolio (the
dashboard/cross-project sections are skipped at one project per § Multi-Project Handling, but
the per-project watermelon scan and metric validation still run).

#### 7.1 Watermelon Scan (8-signal, per project)

For **each** active project, run the 8-signal watermelon scan **W1–W8 by reference** per
[`watermelon-detection.md`](../../../core/skills/pmo-qa-auditor/references/watermelon-detection.md)
(owned by `pmo-qa-auditor` — core module, consumed via-public-api; do **not** restate or fork
the signals). The signals key off the bands owned by `metric-registry.md`:

| ID | Signal (by reference) | Severity |
|---|---|---|
| W1 | Persistent-green under recurring RAID | STRONG |
| W2 | Green project-RAG over Amber/Red component-RAG | STRONG |
| W3 | Stale / overdue RAID under green *(the headline path)* | STRONG |
| W4 | Velocity spike beyond credible band | WEAK |
| W5 | Zero open risks on an active project | WEAK |
| W6 | Milestone dates not aging (flat %-complete) | WEAK |
| W7 | 100% task completion under slipping features / scope | WEAK |
| W8 | Self-reported RAG without objective derivation | WEAK |

**Apply each signal's false-positive filter** (per the canonical doc) before counting it as
fired, then compose the per-project **verdict by reference** to `watermelon-detection.md`
§ Verdict Composition:

- **≥1 STRONG signal (W1/W2/W3)** fires → **WATERMELON-FLAG (Tier 1)**. Cite the firing STRONG
  signal + its evidence (e.g., for W3: the overdue RAID IDs + the Overdue-RAID-Count registry band).
- **≥2 *independent* WEAK signals (W4–W8)** fire on the same project → **WATERMELON-FLAG (Tier 2)**.
  Cite the ≥2 corroborating signals. (W8 corroborates only a non-W8 WEAK; same-evidence items
  de-dup to their highest-severity facet once.)
- **≥1 signal un-evaluable** (missing artifact / metric) and no STRONG independently fired →
  **INDETERMINATE / EVIDENCE-GAP** — record the gap; **never** report this as clean.
- **All signals evaluable and none survived** → **NO-FLAG (CLEAN)** — record the signals
  evaluated and the FP filters that explained near-misses, so a clean result is distinguishable
  from an un-evaluated one.

Output, per project: the verdict (Tier 1 / Tier 2 / INDETERMINATE / NO-FLAG), the firing
signals with evidence, and — for any flag — a one-line statement that the project's Section 1
color is contradicted by the scan. A flag is an **evidence-integrity finding**, not a unilateral
re-coloring: route it to the worst-component dominance check below and the failure-mode rule.

#### 7.2 Lag-to-Lead Balance Audit

Classify each metric in `metric-registry.md` that the roll-up reports this week as a **lagging**
or **leading** indicator (the classification is a property of the registry rows — see the
registry's lag/lead column; **no new PROJECT.md field**), and report the **lag : lead ratio**
across the reported set. A set dominated by lagging indicators (outcomes already realized — SPI,
CPI, overdue counts) with few leading indicators (predictive — velocity variance, capacity
utilization, dependency health) is surfaced as a balance risk: the portfolio is being steered
by the rear-view mirror. Cite the registry rows; do not re-derive the metrics.

#### 7.3 Portfolio R-G-T Allocation

Report the portfolio **Run / Grow / Transform** investment allocation. Read each active project's
**optional** `investment_class: Run|Grow|Transform` field from its `PROJECT.md` (see
`project-md-template.md` — the field is optional). Compose the portfolio split as the
Run / Grow / Transform counts (or effort-weighted shares where effort is available).

**Default when the field is absent:** a project with no `investment_class` is classed
**`Unclassified`** and surfaced as an explicit **coverage gap** — it is **never** silently
bucketed into Run/Grow/Transform, and it is **never** heuristically auto-classified from phase
or project-type (that would fabricate an investment call the operator did not make — a
no-invention violation). The R-G-T block therefore works **with or without** the field: present
field → real split; absent field → `Unclassified` with the coverage gap named. Do not block the
roll-up on missing `investment_class`.

> **Disambiguation:** R-G-T (investment classification) is **not** the `capacity-model.md §5`
> 60/20/20 capacity effort-split — a different concept that happens to share digits. Do not
> conflate the two.

#### 7.4 Per-Metric Decision-Rule Validation

For **each** metric surfaced anywhere in the roll-up (Sections 1–2 health logic, Section 7
sub-blocks), **cite its governing `WHEN…THEN…` decision rule verbatim** from its
`metric-registry.md` row and confirm the reported RAG matches the rule's output. This is pure
consumption: follow REFERENCED rows to their owning doc (`channel-formats.md`, `capacity-model.md`,
`backlog-health.md`) for the live band; do **not** re-derive a threshold (duplicate-source-
discipline). A reported color that does not match its rule's output is itself a finding (a
likely W2 or W8 watermelon contributor) — surface it, do not silently re-color.

#### 7.5 Capacity Dashboard

Synthesize a **cross-project capacity view**: aggregate each active project's **Capacity
Utilization** (the `metric-registry.md` Team row, which already references
[`capacity-model.md`](../delivery-engine/references/capacity-model.md)) into a portfolio
capacity dashboard, applying `capacity-model.md` §1 (effective-capacity formula) and §9
(Demand-Supply Gap RAG bands) **by reference**. Report per-project utilization + the portfolio
roll-up, flagging any project breaching the §9 RED band (`> 1.00` utilization) as over-committed.
Reproduce the source's inclusivity (`≤ 0.85` is GREEN); do **not** restate the formula or bands.

#### 7.6 Portfolio Dormancy Sweep

For **each** tracked project, run a dormancy sweep that detects a project producing **no
artifact activity at all** across a defined window and routes it to an explicit **disposition
decision** — distinct from the §7.1 W6 signal and the "Roll-up generated as a substitute for
the week's unprocessed work — TRIG" failure mode, which detect *stale content within a
reported week*; §7.6 detects *whole-project no-activity* and routes to disposition, not a
watermelon flag.

- **Artifact-activity signal set (per project):** the most-recent modification across {Daily
  Status Log entries, any `04-PMO-Operations/` tracker update, any `05-Transcripts/`
  arrival}. "Activity" = a **substantive** entry/update, mirroring the Stale-RAID "substantive
  update resets the clock" rule (`../ppm-agent/references/escalation-thresholds.md` §3) — a
  cosmetic re-save does **not** count.
- **Dormancy clock:** `today − last-artifact-activity-date`, in **business days** (carries
  `[INFERRED: today − last-activity-date]` per the platform's existing age-computation
  precedent — there is no codified business-day calendar primitive yet).
- **Fire condition — `> 10 business days` (= 2 weekly-rollup cycles):** emit a **dormancy
  prompt** for that project naming (a) the project, (b) the last-activity date + its source,
  (c) the computed dormancy age, and (d) the three disposition options — **proceed / shelve /
  close**. The window is **10 business days**: it requires a project to miss *two consecutive*
  rollup windows (the rollup runs weekly per § Generation Schedule) and reuses the platform's
  existing 10-business-day "inactivity → disposition" cadence (`08-Generated/` auto-archive).
- **Disposition routing (Autonomy Tier 1 — recommend):** the prompt is an **evidence-integrity
  finding surfaced to the operator**. The sweep **never** auto-shelves or auto-closes;
  disposition is an operator decision (mirrors §7.1's "a flag is an evidence-integrity
  finding, not a unilateral re-coloring"). The dormancy prompt is a decision-class output —
  carry a reversibility tier per § Reversibility Discipline (an internal pre-confirmation
  dormancy flag is CHEAP; a close disposition acted on downstream escalates per the tier
  table).
- **Coverage-gap honesty (composes with the "Daily-log coverage gap read as a quiet week —
  INPUT" failure mode):** if the activity signal cannot be computed (no trackers present yet —
  a just-initiated project), emit `dormancy: not assessable — no tracker baseline` and flag it
  as a coverage gap; **never** read "no trackers" as "dormant" (that would converge with the
  "absence of evidence becomes evidence of absence" anti-pattern the skill already guards).
- **De-registration sub-case:** a project that is *archived but still on the active list* fires
  the same sweep → the disposition prompt's **close** option doubles as the de-registration
  trigger (drop from PORTFOLIO.md active list). This sweep is the **detector**;
  `project-initiator` Mode B is the **executor** (the closure-entry dormancy hook in that
  skill acts on what this sweep detects).

**Section 7 ↔ Section 1 feedback (worst-component dominance).** The watermelon scan's W2 signal
(green project-RAG over a worse component) requires the **worst-component dominance rule** to
detect a violation of. Section 1's project color is therefore composed by the transparent-roll-up
rule — **the project color is driven by its worst component** (per `channel-formats.md:245-246`,
the watermelon-prevention dominance rule the registry's `metric-registry.md` § Project-Level RAG
Composition already names). When the Section 7 scan returns a WATERMELON-FLAG whose evidence shows
a component worse than the reported project color, the Section 1 color is corrected to the worst
component (and the correction reasoning is cited per the § Reversibility Discipline — a
health-color transition shared with leadership is decision-class and carries its tier).

**Reversibility on Section 7 verdicts.** A watermelon verdict or a metric-validation finding that
shifts a Section 1 health color, or that is surfaced to leadership, is a **decision-class output**
and carries a reversibility tier paired with a confidence level (per § Reversibility Discipline) —
a health-color transition shared with leadership is EXPENSIVE/IRREVERSIBLE per the skill's existing
tier table; an internal pre-confirmation flag is CHEAP. A NO-FLAG / INDETERMINATE record that drives
no transition is a factual record and does not require a tier.

## Output Formatting

- **File output:** Save to `08-Generated/Weekly_Status_Rollup_[DATE].md`
- **Length:** Target 2-3 pages equivalent. Executives skim — prioritize density over length.
- **Evidence:** Every factual claim traces to a tracker entry, daily update, or transcript.
  Use inline citations: `(Daily Status 3/17)`, `(DEC-012)`, `(BLK-005)`.
- **Tone:** Professional, direct, decision-oriented. No filler, no status theater.
- **Date range:** Monday through Friday (or current day if mid-week generation)

## Multi-Project Handling

- Process projects in order of health severity (RED first, then YELLOW, then GREEN)
- Cross-project items appear in their own section, not duplicated under each project
- If only one project is active, skip the portfolio dashboard and cross-project sections
- Portfolio write-back applies regardless of project count

## Reversibility Discipline

This skill produces **decision-class outputs** — portfolio write-back proposals to
`PORTFOLIO.md`, health-indicator transitions with reasoning, next-week-focus priority
recommendations, and "required decisions with deadlines" flagged for leadership action.
Although the executive summary sections (Sections 1–5) primarily surface tracker state,
Section 6 (Portfolio Write-Back) and the forward-looking priority framings are
decision-class. Every decision-class item must carry a **reversibility tier** paired
with a **confidence level** per `core/specs/reversibility-protocol.md`.

**Decision-class outputs in this skill:**

- Section 1 (Portfolio Health Dashboard) — health color assignments (🟢 / 🟡 / 🔴) with reasoning, especially transitions from the prior week (e.g., 🟡 → 🟢 or 🟢 → 🔴). The color is a classification, but the transition reasoning carries stakeholder signal.
- Section 2 (Per-Project Summary) — `Next Week Focus: Top 3 priorities` is a recommendation set. `Decisions Pending` with overdue flags is an escalation-class surfacing.
- Section 5 (Looking Ahead) — "Required decisions with deadlines", "Resource or scheduling conflicts" identified across projects.
- Section 6 (Portfolio Write-Back) — proposed changes to `PORTFOLIO.md` fields (Phase, Health, Critical Path Item, Go-Live, Health Indicators, Top Risks), with the user-approval checkpoint before the write.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — a draft rollup the user has not reviewed; a health color assigned internally before user confirmation; a Top-3 priorities list for internal PMO planning only. State the tier. Proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — a rollup circulated to the TPM for review before SteerCo; a PORTFOLIO.md write-back proposed at the human-in-the-loop checkpoint but not yet written; a next-week focus list the team will commit to at Monday's planning session. State the tier, surface the key assumption in ≤1 sentence, invite single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a PORTFOLIO.md write-back that is applied and then downstream consumers (daily-status, portfolio-facing dashboards, project-initiator scans) have read the updated state; a health-color transition (e.g., 🟢 → 🔴) that has been shared with leadership; a Top-3 priority list that has been published to a cross-functional stakeholder audience. State the tier, document rationale (≥2 sentences), state rollback plan (correction note + revised write-back), name the affected cohort (leadership, dependent projects, downstream skills).
- **IRREVERSIBLE** (cannot undo) — a weekly rollup distributed to a SteerCo or executive audience whose content, once sent, sets the committed status on the record; a health-color transition escalated to leadership as a formal status call; a PORTFOLIO.md write-back that has been consumed by a downstream portfolio-of-record update or external reporting. State the tier, document rationale, state rollback is infeasible or name the counter-commitment (a follow-up correction rollup), name the sign-off authority (program sponsor, COO), pair with explicit downside description.

**Label format** (any accepted):

- Inline: `Recommendation (MODERATE · confidence: HIGH): <text>` — e.g., on health-color transitions or priority recommendations.
- Trailing: `<text> [MODERATE · confidence: HIGH]` — e.g., on individual Next Week Focus priorities.
- Structured column: tier value in a `Reversibility` or `Tier` column of the Portfolio Health Dashboard table or the Portfolio Write-Back Summary table.
- Structured frame: tier value populated alongside the human-in-the-loop checkpoint per PORTFOLIO.md field-change proposal.

Confidence values: `HIGH` / `MEDIUM` / `LOW`. Reversibility is *what-if-wrong cost*;
confidence is *how-likely-wrong*. Both travel together. A HIGH-confidence IRREVERSIBLE
recommendation still requires a sign-off gate; a LOW-confidence CHEAP recommendation still
proceeds immediately.

**Enforcement:** pmo-qa-auditor G4 will FAIL any output of this skill that contains a
decision-class item without a reversibility tier label — including any portfolio
write-back proposal, health-color transition, or Next Week Focus recommendation that lacks
a tier. See `core/specs/reversibility-protocol.md` for the full protocol,
worked examples, and G4 gate algorithm.

## Shared Behavioral Rules

These rules are inherited from OPERATIONS.md and apply to all PMO skills. See OPERATIONS.md for canonical definitions.

- **Push-to-resolve:** When generating the weekly roll-up, produce the complete executive-ready document — health dashboard, per-project summaries, cross-project items, and forward look. Not a skeleton to fill in.
- **Max 5 clarifying questions:** Ask at most 5 questions per invocation. Everything else becomes a labeled assumption with `[ASSUMPTION – CONFIRM]` and a proposed answer.
- **Principal contributor standard:** Output should match what a senior PMO professional would produce — accurate, judgment-driven, actionable.
- **Dual-Framing Bridge (conditional):** When generating roll-ups for dual-framing co-managed projects, include both Agile and Waterfall track summaries converging on unified priorities. Only produce dual Agile/Waterfall framing when the project's PROJECT.md has `dual_framing_enabled: true`. Do not generate dual-framing outputs for single-framing projects. **When a project's `delivery_approach` is a 2-element array `[A, B]` (the Hybrid-Two array form per project-schema §6.5)**, summarize each constituent track natively and take the **union** of priorities across both (per `work-organization-mapping-framework.md` §2.5) rather than collapsing to one track — independent of `dual_framing_enabled`.

### Guardrails

- **SG-1 [CONTEXT]:** When using information from PROJECT.md or prior session state (not from the current artifact), label it `[CONTEXT]` with the source field. Do not present project memory as current-artifact evidence.
- **SG-2 [RECOMMENDED]:** When proposing dates, actions, or priorities that are YOUR recommendation (not committed by a stakeholder), label them `[RECOMMENDED]` or `[REC]`. Distinguish clearly from stakeholder-committed items.
- **SG-3 Reversibility tier on decision-class items:** Every decision-class output — portfolio write-back proposal, health-color transition, Next Week Focus priority, required-decision surfacing — must carry a reversibility tier label (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with a confidence level (HIGH / MEDIUM / LOW) per `core/specs/reversibility-protocol.md`. Outputs missing tiers on decision-class items fail pmo-qa-auditor G4. See Reversibility Discipline section above.

## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with the `### Guardrails` subsection above
(platform-wide generic guardrails) and `## Reversibility Discipline` (decision-class
output discipline). Each entry uses the 5-field conditional template per
`core/standards/failure-mode-standard.md`. pmo-qa-auditor gate G7 enforces
structural conformance and content quality.

### Health color reported without transition reasoning — OUT

- **Signature (observable signal):** Section 1 (Portfolio Health Dashboard) reports a
  project's health color (🟢 / 🟡 / 🔴) without naming the reason for the color,
  especially when the color changed from the prior week (e.g., 🟢 → 🔴 with no
  evidence of what triggered the change).
- **Conditional:** do NOT report a project's health color without naming the reason
  when the color is 🟡 or 🔴 or has changed from the prior week's color, because the
  color is meaningless to leadership without the reason and silent transitions
  generate questions the rollup should pre-answer at SteerCo.
- **Root cause:** Color assignment is fast; reasoning out the transition is slower and
  requires citing the specific evidence (RAID entry, blocker age, milestone slip).
  Under output-pressure the agent ships the color and treats the reasoning as optional
  context.
- **Mitigation:** Every 🟡, every 🔴, and every color transition (in either direction)
  carries a one-line reason in the "Key Risk" column or as inline annotation. The reason
  cites the evidence (RAID entry, blocker age, milestone slip date). 🟢 with no
  transition can ship without a reason.
- **Principal response vs. junior response:** Principal writes "🟡 (was 🟢) — UAT
  slipped 5 days; cutover holds for now [SOURCE: BLK-014 aged to 7 days]" and the
  SteerCo question is pre-answered. Junior writes "🟡" with no annotation and the
  SteerCo audience asks "why is [PROJECT_KEY] yellow this week?" — and nobody on the call has
  the answer ready.

### PORTFOLIO.md write-back applied without the human-in-the-loop checkpoint — PROC

- **Signature (observable signal):** Section 6 (Portfolio Write-Back) executes write
  changes to PORTFOLIO.md without first presenting the human-in-the-loop checkpoint
  summary ("Health 🟡→🟢 because all blockers resolved...") and waiting for explicit
  user approval.
- **Conditional:** do NOT write changes to PORTFOLIO.md when the human-in-the-loop
  checkpoint summary has not been presented and approved, because PORTFOLIO.md is
  consumed by downstream skills (daily-status, project-initiator, portfolio
  visualizations) and an unapproved write-back propagates errors across the entire
  platform until the next manual review.
- **Root cause:** Push-to-resolve creates pressure to "finish the rollup" by completing
  all 6 sections in one pass; the checkpoint feels like a delay. The skip is silent
  because the write-back works mechanically without it.
- **Mitigation:** After producing Sections 1-5 and the proposed Section 6 changes,
  always present the human-in-the-loop checkpoint summary and wait for explicit user
  approval before writing. If running on a scheduled task, mark the changes as
  DRAFT-FOR-APPROVAL and queue for the next user interaction — do not auto-write.
- **Principal response vs. junior response:** Principal renders the checkpoint, waits
  for approval, writes on confirmation, and confirms the write to the user. Junior
  writes immediately to "save a step" and downstream daily-status reads incorrect
  health colors for a week before the user notices the divergence.

### Cross-project items duplicated under each project AND in cross-project section — OUT

- **Signature (observable signal):** Section 3 (Cross-Project Items) has items that are
  also restated under Section 2 per-project summaries — the same dependency, resource
  conflict, or shared risk appears in 3+ places (Section 2 for Project A, Section 2 for
  Project B, Section 3 cross-project).
- **Conditional:** do NOT duplicate cross-project items in both Section 2 (per-project) and Section 3 (cross-project) when the item legitimately spans projects, because duplication makes the rollup feel longer than it is and obscures whether the item is being acted on once or three times — confusing ownership and dilution of the actual signal.
- **Root cause:** Cross-project items are easy to mention in the per-project summary
  because they affect that project; the agent forgets that Section 3 exists to
  consolidate them. Each per-project summary feels complete on its own when written,
  before the cross-project section is composed.
- **Mitigation:** Cross-project items live in Section 3 only. Per-project summaries
  reference them with "see Cross-Project: [item]" rather than restating the full
  description. Section 3 carries the full description, owner, and status; per-project
  sections carry the reference and the project-specific impact.
- **Principal response vs. junior response:** Principal puts "Shared resource conflict —
  J. Smith committed to [PROJECT_KEY] and OTC for week of 2026-04-22 [owner: D. Lee]" in
  Section 3, with project sections referencing "see Cross-Project: J. Smith conflict."
  Junior writes the conflict three times — once in [PROJECT_KEY], once in OTC, once in
  Section 3 — and the rollup reads as a longer, less coherent document.

### Daily-log coverage gap read as a quiet week — INPUT

- **Signature (observable signal):** "This Week" bullets, health colors, and
  write-back proposals are derived from a Daily Status Log that covers only
  part of the reporting window — a mid-week run with Monday–current gaps, or a
  Friday run with unlogged days — and the output presents the synthesis as the
  week's record with no statement naming the uncovered days.
- **Conditional:** do NOT synthesize "This Week" sections or health colors as a
  full-week record when the Daily Status Log has entries for only part of the
  reporting window, because a day with no log entry is indistinguishable from a
  quiet day — treating silence as no-movement converts missing data into
  implied-GREEN evidence that flows through Section 1 into the PORTFOLIO.md
  write-back.
- **Root cause:** The Inputs step reads "this week's AM and PM updates (Monday
  through current day)" as whatever entries exist; a missing day produces no
  error at read time, so the gap is invisible at synthesis — absence of
  evidence quietly becomes evidence of absence.
- **Mitigation:** Before synthesis, run the roll-up input-coverage checklist:
  enumerate expected-vs-present log days for the reporting window, label
  uncovered days in Sections 1–2 ("Tue–Wed: no daily log — not assessed"),
  derive health only from covered evidence, and exclude write-back fields
  whose support falls inside the gap. Treat "no entry" as NO DATA, never as
  "no movement."
- **Principal response vs. junior response:** Principal ships the roll-up with
  the gap named and health scoped to covered days, so leadership reads exactly
  what is and is not known. Junior rolls up the days that have entries and
  presents it as the week — a blocker that surfaced on an unlogged Wednesday
  reaches SteerCo as GREEN.

### Roll-up generated as a substitute for the week's unprocessed work — TRIG

- **Signature (observable signal):** The weekly roll-up is generated for a week
  whose substrate is missing — the Daily Status Log has no entries for the
  period, trackers show no updates since before the window — and the skill
  fills the gap by summarizing raw transcripts and unprocessed artifacts
  directly into Sections 1–5, then proposes a PORTFOLIO.md write-back derived
  from that one-pass synthesis.
- **Conditional:** do NOT generate the weekly roll-up directly from unprocessed
  artifacts when the week's Daily Status Log and tracker substrate are missing
  for the period, because this skill rolls up results that ppm-agent and
  daily-status produced during the week — it does not summarize transcripts or
  analyze artifacts — and a roll-up synthesized from raw inputs replaces the
  week's evidence chain with a single unsourced pass whose health colors then
  write back into PORTFOLIO.md as if derived.
- **Root cause:** The Friday deadline does not move when the week's processing
  did not happen; the skill has read access to everything and CAN produce a
  plausible roll-up, so backfilling silently feels like saving the SteerCo —
  and the substrate gap is invisible in the output unless declared.
- **Mitigation:** At input collection, check substrate coverage for the date
  range. When the Daily Status Log or trackers have gaps, surface the gap and
  route: run the backlog of transcripts through ppm-agent / daily-status first,
  or produce a partial roll-up that names the uncovered days and excludes the
  write-back for unsupported fields. Never write health indicators back to
  PORTFOLIO.md from data that skipped processing.
- **Principal response vs. junior response:** Principal reports
  "Wednesday–Thursday were never processed," offers the catch-up path, and
  ships a roll-up with the gap labeled. Junior synthesizes the whole week from
  raw transcripts at 4:55 PM Friday; the roll-up reads complete, the write-back
  lands, and the portfolio dashboard now carries health colors derived from
  nothing the platform can audit.

### Cross-project RAID escalation not propagated to the sibling project's surfaces — HAND

- **Signature (observable signal):** A RAID escalation or shared-dependency risk read
  from Project A's inputs (RAID entries, carry-forward blockers) materially affects
  sibling Project B — a shared resource, a dependent milestone, an integration both
  consume — but the rollup carries it only under Project A's Section 2: Section 3
  (Cross-Project Items) omits it, and the Section 6 write-back leaves Project B's
  PORTFOLIO.md row (Top Risks / Health Indicators / Critical Path Item) untouched
  by it.
- **Conditional:** do NOT confine a risk to its originating project's summary when its
  RAID evidence names a sibling project's resource, milestone, or integration, because
  PORTFOLIO.md rows are the per-project handoff surface for downstream consumers —
  daily-status, project-initiator, and portfolio visualizations read Project B's row,
  not Project A's narrative — and an escalation that never reaches the sibling's row
  leaves every downstream read of Project B reporting clean state while its exposure
  is already on the record one row up.
- **Root cause:** RAID entries arrive project-scoped (read per-project in input
  order), so the synthesis defaults to the project that owns the entry; recognizing
  the sibling impact requires cross-referencing the entry's content against the other
  projects' milestones and resources — the one synthesis step with no single-project
  home. The rollup is also the only weekly surface where this propagation can happen,
  so a miss here has no downstream catch.
- **Mitigation:** During Section 3 composition, run the roll-up input-coverage
  checklist's sibling-reference sweep: scan each project's new and updated RAID
  entries and aged blockers for sibling-project references (shared named resources,
  dependent milestone dates, common integrations). On a hit: place the full
  item in Section 3 with both projects named (per the no-duplication convention,
  Section 2 summaries carry only the "see Cross-Project" pointer and the
  project-specific impact), and propagate to BOTH projects' rows at the Section 6
  write-back — the sibling's Top Risks or affected Health Indicator cites the same
  RAID source ([SOURCE: RAID R-PPM-052]) — inside the same human-in-the-loop approval.
- **Principal response vs. junior response:** Principal writes the shared-resource
  conflict into Section 3, pointers into both Section 2 summaries, and proposes
  write-back rows for both projects ("Project B: Top Risk + Schedule indicator 🟡 —
  [SOURCE: RAID R-PPM-052, shared cutover resource]") at the checkpoint. Junior
  records the risk under the project that filed it; Project B's row stays green and
  every portfolio read — dashboards, the next rollup, project-initiator scans — sees
  B clean all week, and B's team learns about the shared-resource exposure when it
  lands on them.

### Project reported green while its watermelon scan fires — OUT

- **Signature (observable signal):** Section 7.1's watermelon scan returns a
  WATERMELON-FLAG for a project — a STRONG signal (W1/W2/W3) survived, or ≥2
  independent WEAK signals (W4–W8) survived their false-positive filters — yet
  Section 1 still reports that project 🟢 GREEN (or the verdict is INDETERMINATE /
  EVIDENCE-GAP but the roll-up records the project as clean), with no correction to
  the color and no surfacing of the contradiction.
- **Conditional:** do NOT report a project 🟢 GREEN when its watermelon scan returns
  a WATERMELON-FLAG **per the verdict-composition rule** (≥1 STRONG **or** ≥2
  independent WEAK signals surviving), and do NOT record an INDETERMINATE /
  EVIDENCE-GAP verdict as clean, because the entire reason the scan exists is to catch
  green-outside / red-inside status — a flagged project shipped GREEN to SteerCo is the
  exact failure the scan is the backstop against, and an evidence gap passed as clean
  converts absence-of-evidence into implied-GREEN that flows into the PORTFOLIO.md
  write-back.
- **Root cause:** The watermelon scan is an *extra* governance step layered on a
  roll-up whose Section 1 color was already assigned from the (possibly self-reported)
  health signals; under output-pressure the agent runs the scan, sees the flag, but
  treats the already-written Section 1 color as settled rather than letting the scan
  feed back into the dominance check. Binding "green vs flagged" to a raw signal *count*
  rather than the verdict rule compounds it — a single STRONG signal is a Tier-1 flag,
  but a count-threshold ("≥3 signals") would silently pass it.
- **Mitigation:** Bind the green-block to the **verdict-composition rule, not a raw
  count**: any Tier-1 (≥1 STRONG) or Tier-2 (≥2 independent WEAK) verdict blocks 🟢 GREEN
  for that project; an INDETERMINATE verdict is recorded as an evidence gap, never clean.
  On a flag, run the Section 7 ↔ Section 1 worst-component dominance feedback — correct the
  Section 1 color to the worst component, cite the firing signal + evidence, and carry the
  reversibility tier on the resulting health-color transition (§ Reversibility Discipline).
  A health-color correction the scan forces is an evidence-integrity finding routed back to
  the source for a corrected health or a documented justification — not a silent re-color.
- **Principal response vs. junior response:** Principal writes "🔴 (scan: W3 Tier-1 — 5
  overdue RAID under self-reported green [SOURCE: RAID R-PPM-052, Overdue-RAID-Count 🔴
  band]); color corrected from reported 🟢 to worst component [EXPENSIVE · confidence: HIGH]"
  and the watermelon is caught before SteerCo. Junior runs the scan, notes "W3 fired" in
  Section 7, leaves Section 1 🟢 because that is what the project reported, and the
  green-masked overdue RAID reaches leadership as on-track — then writes 🟢 back into
  PORTFOLIO.md, propagating the masked state to every downstream consumer.

## Generation Schedule

Typically generated:
- **Friday 5:00 PM CT:** Automated weekly roll-up via scheduled task. Produces executive summary and draft portfolio write-back. User reviews and approves at next interaction.
- **On demand:** Before any SteerCo, executive review, or stakeholder meeting.

The user may request the roll-up at any time — generate based on available data through
the current day.
