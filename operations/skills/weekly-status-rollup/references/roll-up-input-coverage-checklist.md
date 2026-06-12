# Roll-Up Input-Coverage Checklist

## Purpose

Pre-synthesis coverage check for the weekly roll-up. Run it at input collection, after
the Inputs reads and before any Section 1–6 synthesis. The roll-up reports on whatever
substrate exists; this checklist is the mechanism that makes the substrate's gaps
visible BEFORE they convert into implied-GREEN health, missed sibling exposure, or an
unauditable write-back. The skill's failure-mode entries name this checklist as their
mitigation mechanism; this file is its single source.

## Step 1 — Substrate-presence pass (per input)

| # | Input | Present means | On absence |
|---|---|---|---|
| 1 | PORTFOLIO.md | Active-project list readable with governance models | STOP — no roll-up without the project roster |
| 2 | PROJECT.md (per project) | Phase, milestones, health fields populated | Mark the project NOT ASSESSED; name it in Section 1 |
| 3 | Daily Status Log (per project) | ≥1 entry inside the reporting window | Run Step 2 day-coverage enumeration; never infer a quiet week |
| 4 | Carry-forward tracker (per project) | Blockers / decisions / actions current within the window | Flag staleness next to every item carried from it |
| 5 | Communications Tracker (per project) | Window's escalations and exec messages readable | Note "comms not assessed" in the project's Section 2 summary |
| 6 | RAID entries (per project) | New/updated entries for the window retrievable | Note "RAID not assessed"; skip that project in the Step 4 sweep and say so |

When the whole per-project substrate for the window is missing (no log entries, no
tracker updates), the roll-up is at the substitution boundary: surface the gap and
route the backlog to ppm-agent / daily-status first, or produce a partial roll-up that
names the uncovered days — never synthesize the week directly from raw artifacts.

## Step 2 — Day-coverage enumeration (Daily Status Log)

1. Enumerate the expected log days for the reporting window (Monday through the run
   day) per project.
2. Mark each day PRESENT (≥1 AM or PM entry) or ABSENT.
3. An ABSENT day is NO DATA — never "no movement," never implied-GREEN.

## Step 3 — Coverage consequences for synthesis

- Label uncovered days in Sections 1–2 ("Tue–Wed: no daily log — not assessed").
- Derive health colors from covered evidence only; a color that would rest on an
  ABSENT day's silence is not derivable.
- Exclude from the Section 6 write-back every field whose supporting evidence falls
  inside a coverage gap — a PORTFOLIO.md row never carries health derived from NO DATA.

## Step 4 — Sibling-reference sweep (cross-project propagation)

1. For each project's new and updated RAID entries and aged carry-forward blockers,
   scan the entry content for sibling-project references: shared named resources,
   dependent milestone dates, integrations both projects consume.
2. On a hit, the item is cross-project: place the full item in Section 3 with both
   projects named; each affected project's Section 2 summary carries only the
   "see Cross-Project" pointer plus its project-specific impact.
3. Propagate to BOTH projects' rows in the Section 6 write-back proposal — the
   sibling's Top Risks or affected Health Indicator cites the same RAID source — so
   no downstream per-project read reports clean state while the exposure is on the
   record under the originating project.

## Step 5 — Record the result

State the coverage outcome in the roll-up itself: days covered per project, inputs
not assessed, sibling-sweep hits propagated. A roll-up that ran the checklist clean
says so in one line; a roll-up with gaps names them where leadership reads.
