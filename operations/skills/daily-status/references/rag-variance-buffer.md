# RAG, Variance & Buffer Status — daily-status reference

> Consumed by `daily-status` SKILL.md `## RAG, Variance & Buffer Status`. This reference carries the full per-mode wiring, the four formula-driven lines (Formula-RAG / Milestone variance (SPI) / Buffer-consumption zone / Metric-anomaly flag), and the REQUIRED negative paths. The SKILL.md section is the short stub that points here; this file is authoritative for the detail.

When a status update carries a schedule color, a milestone-progress figure, or a buffer
figure, compute it from the documented formula and cite the threshold — never assign a color
by feel. This wires the **AM / PM / Daily Connect Prep** modes to four formula-driven
lines, all of which **surface** the registry's computed state. The thresholds, bands, and
decision rules are owned by the registries listed in **Inputs entry 6** (of SKILL.md) and are read **by
role** — this reference restates none of their numbers.

**Surfacing, not recommending (load-bearing — preserves the `## Reversibility Scope` opt-out).**
Every line below reports the registry's documented `WHEN…THEN…` rule as the *source's* rule,
attributed to the source. This skill does not issue first-person recommendations, escalations,
or proposed actions (those belong to ppm-agent / pmo-qa-auditor). Report the color, the figure,
and the source's rule verbatim — e.g. *"milestone variance 🟡 YELLOW (SPI 0.92; band 0.85 ≤ SPI
< 0.95 per metric-registry SPI row) — registry rule: watch milestone, flag at next status,"* and
**never** *"I recommend you escalate."* The `SG-2 [RECOMMENDED]` label remains the marker for
the edge case where a surfaced date or priority is genuinely the agent's own.

## Formula-RAG (schedule color)

Compute the schedule RAG from the **Schedule Performance Index (SPI)**, banded per the
metric-registry **SPI row** (which references the platform-canonical Schedule-RAG standard).
SPI = earned schedule value ÷ planned schedule value; *"X% behind schedule" ⇒ SPI = 1 − X/100*
(8% behind ⇒ 0.92). Read the live 🟢 / 🟡 / 🔴 band from the SPI row, classify the figure, and
report the color **with the band cited** — this replaces any by-feel color in the status line.
Report the registry's `WHEN…THEN…` decision rule as the registry's rule (not a recommendation).

## Milestone variance (SPI)

Report the SPI figure alongside the color. **Name it "milestone variance (SPI)" or "milestone
slip" — NEVER "Schedule Variance"** (that label is reserved against the EVM Schedule-Variance
cost figure; this is the SPI *index*). Use the metric-registry SPI-row bands by reference. On a
PM update, report the SPI delta versus the AM figure; in Daily Connect Prep, surface the figure
as a prep line so the meeting opens on the formula-derived color, not a verbal feel.

## Buffer-consumption zone

When an iteration-buffer consumption figure is available, name the active zone from
`estimation-standards.md §4.1` (Buffer-Consumption Banding) — 🟢 / 🟡 / 🔴 on the **fraction of
the iteration buffer consumed** — and report its `WHEN…THEN…` rule as the source's rule. This is
**orthogonal** to the §4 (a/b/c) reserve-ownership zones: report **how much of the buffer is
burned** (consumption), never **which reserve owns the risk** (ownership). The zone line is
**conditional on a buffer figure existing** — see the negative paths below.

## Metric-anomaly flag

Flag a surfaced metric as an anomaly when it is either **(i) structurally implausible** — outside
its metric's defined domain (e.g., an SPI ≤ 0 or implausibly high for a daily milestone read, a
buffer-consumption fraction < 0 or > 1.0, a milestone %-complete that moved backward with no
re-baseline note, a velocity reported as a single point rather than a range) — or **(ii)
band-contradicting** — a value the source tracker reports as 🟢 while the computed RAG is 🟡 / 🔴
(the watermelon green-masking premise). Check against the registry's **existing** per-metric
domains and RAG bands — author no new anomaly thresholds. **Surface** the anomaly for the reader
(in Daily Connect Prep, as a PMO-internal prep-note outside the Teams-ready body, like the
unprocessed-Comms-Tracker prep-note); never auto-correct, re-triage, or adjudicate it — that
strategic judgment is ppm-agent / pmo-qa-auditor, not this formatting pass.

## Per-mode wiring

| Mode | Formula-RAG | Milestone variance (SPI) | Buffer-consumption zone | Anomaly flag |
|------|-------------|--------------------------|-------------------------|--------------|
| **AM Status Update** | Compute the schedule RAG from SPI when a milestone baseline is readable from PROJECT.md; cite the band; replace any by-feel color in the status line. | Report the SPI figure alongside the color. | Report the zone if an iteration-buffer figure is available. | Flag any structurally-implausible / band-contradicting metric surfaced into the update. |
| **PM Status Update** | Recompute against the day's delta; the progress-delta line carries the updated color + cited band. | Report SPI + the delta vs the AM figure. | Report the zone + consumption delta. | Same. |
| **Daily Connect Prep** | Surface the current schedule RAG + cited band so the meeting opens on the formula-derived color. | Surface the variance figure as a prep line. | Surface the zone as a prep line. | Surface anomaly flags as a PMO-internal prep-note (outside the Teams-ready body). |

**Phase-adaptation composition.** These lines compose with the `## Phase Adaptation` table, they
do not override it. In **Cutover** (per-milestone cadence) the milestone-variance line is *more*
central — the per-milestone update carries the SPI + RAG. In **Hypercare** the buffer/variance
lines may be N/A (no active sprint buffer) → the missing-input negative path fires.

**Negative paths (REQUIRED — never fail silently, never fabricate a color or zone).**

- **No milestone baseline (SPI not computable):** do NOT fabricate a RAG. Emit
  `milestone variance: not computable — no schedule baseline` and flag the missing baseline as a
  status gap (matches `estimation-standards.md §7` Application rule).
- **No buffer figure available:** state `buffer consumption: not available` — do NOT invent a
  zone, and never default the band to GREEN on absent input (matches `estimation-standards.md
  §4.1` Application rule).
- **Missing milestone %-complete but baseline present:** flag `[ASSUMPTION – CONFIRM]` and do not
  color.
- **Project's Daily Status Framework defines no RAG / variance / buffer section:** surface the
  figures in the nearest applicable line and note the Framework gap — do not silently drop them
  and do not force-inject a template section the Framework lacks.
- **Anomaly with no clean resolution:** flag-and-surface — never auto-correct, never re-triage.
