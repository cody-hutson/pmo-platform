# Scaffold-Output Verification — Mode A

## Purpose

Verification procedure for the Mode A scaffold output. Run it after Step 4 (Generate
Starter Artifacts) and Step 5a (Post-Creation Validation), before presenting the Step 8
summary. The skill contracts every starter tracker as empty-but-properly-formatted; this
procedure is the per-artifact check that the generated files actually satisfy that
contract — structure present, operational state absent.

## Per-artifact verification table

| # | Artifact | Structure that must be present | Operational state that must be absent |
|---|---|---|---|
| 1 | `[Project]_Daily_Status_Log.md` | Carry-forward section headers: Active Blockers, Decisions Pending, Open Actions by Person, Deferred Items, Retest Queue, Recently Closed | Any `BLK-` or `DEC-` row; any named action item under Open Actions |
| 2 | `[Project]_Communications_Tracker.md` | Lifecycle policy text (ACTIVE → CORE → ARCHIVE) | Any `MSG-` entry |
| 3 | `[Project]_Open_Meetings_Tracker.md` | Section structure: Upcoming, Recently Completed, Recurring Cadences | Any `MTG-` entry |
| 4 | `[Project]_Transcript_Register.md` | Register column headers | Any `TR-` entry |
| 5 | `[Project]_RAID_Log.csv` | 14-column header row per the RAID schema | Any data row; any `R-`/`A-`/`I-`/`D-` prefixed RAID_ID |
| 6 | `Key Terms Glossary.csv` | Header row: Term, Definition, Context, Source | Any term row |
| 7 | `[Project]_Sprint_Tracker.md` (Agile/Hybrid only) | Sprint number, goal, capacity, velocity fields | Any populated sprint row |
| 8 | `[Project]_Milestone_Tracker.md` (Waterfall only) | Phase, milestone, planned/actual date, status, evidence columns | Any populated milestone row |
| 9 | `[Project]_Dual_Framing_Bridge.md` (dual-framing co-managed only) | Milestone-to-sprint mapping structure, dual-frame status fields | Any populated mapping row |

Step 4 items 7–8 (the Daily Status Update Framework and the Executive Status Report
Prompt) are prompt-framework templates — they legitimately carry template content and are
NOT checked for emptiness. Verify only that both files exist.

## Verification steps

1. **Existence pass.** Every artifact required by the project's governance model exists
   in `04-PMO-Operations/` under its standard name (rows 7–9 apply only when their
   governance condition holds).
2. **Structure pass.** For each artifact, the "must be present" column above is
   satisfied — headers, sections, and policy text per its template under the skill's
   `references/templates/` set.
3. **Emptiness pass.** For each tracker (rows 1–9), the "must be absent" column above
   returns zero matches. A single ID-bearing row is a contract breach: remove it before
   Step 8 — never ship it silently.
4. **PROJECT.md cross-check.** Frontmatter `status: ACTIVE` is set; governance-model
   conditional sections match the Required Inputs (Sprint Tracking, Phase-Gate Timeline,
   and Dual-Framing Bridge per the Step 3 conditional rules).
5. **Record the result.** Surface the verification outcome in the Step 8 summary
   alongside the Step 5a portfolio-validation count — artifacts verified, breaches
   found, corrections applied.

## Failure handling

A verification failure here is CHEAP to fix (regenerate the artifact from its template
before anything consumes it) and EXPENSIVE to skip — downstream skills read these
trackers as live operational state from day one, so fabricated rows become phantom
blockers, risks, and meetings in the first processing cycle. Fix before Step 8; never
present a summary that claims a clean scaffold without this procedure's evidence.
