---
name: pmo-skill-refiner-selftest-canary
description: >
  Smoke test for the pmo-skill-refiner factory — produced via the refiner's
  Create-New workflow during an AC demonstration. Reports the count of
  skill directories currently present in `release/skills/` and flags any
  that are missing from `deploy.sh` SKILL_LIST. Report-only (no decision-class
  outputs, no recommendations, no actions). Permanent fixture per ADR-04
  (Stage 5 design for ) — functions as an always-on smoke test that
  detects factory regressions. Use when the user wants to check skill-roster
  consistency ("check the skill roster", "count tracked skills", "audit
  skill deployment drift", "verify skills/ folder matches deploy.sh",
  "are all my skills deployed").
delivery_approach: n/a
principal_standard_pass: 6/8
version: v1.10-canary
license: BUSL-1.1
---

# PMO Skill Refiner Selftest Canary

A minimal report-only skill that verifies consistency between the `release/skills/` directory and `deploy.sh` SKILL_LIST. Produced by `pmo-skill-refiner` during an AC demonstration; preserved as a permanent smoke test per ADR-04.

## When to use

Use when the user wants a quick consistency check on the PMO skill roster — specifically the invariant that every skill directory present under `release/skills/` is also registered in `deploy.sh` SKILL_LIST (and vice versa for the non-SUPPLEMENTARY case). Typical triggers:

- "Check the skill roster"
- "Count tracked skills"
- "Audit skill deployment drift"
- "Are all my skills deployed?"
- "Does deploy.sh match the skills folder?"

Skip and route elsewhere when:
- Deep audit of skill content → route to `pmo-qa-auditor` Mode D (Document Management Compliance)
- Structural skill edits → route to `pmo-skill-editor`
- Creating a new skill → route to `pmo-skill-refiner`

## Workflow

1. **Inventory `release/skills/`** via `ls` — produce the list of skill directory names.
2. **Parse `deploy.sh` SKILL_LIST** — read the array declaration and extract tracked skill names.
3. **Compare sets:**
   - Skills present in folder but missing from SKILL_LIST = deployment drift (skill exists but isn't deployed)
   - Skills in SKILL_LIST but missing from folder = orphan reference (SKILL_LIST cites a deleted skill)
4. **Report** — one paragraph (count summary) + one table (status per skill). No recommendations, no actions.

## Output Contract

See `core/schemas/per-skill-output-contracts.md` § Skill 12 — `pmo-skill-refiner-selftest-canary` for the canonical output schema.

Inline output shape:

```markdown
# Skill Roster Canary — <timestamp>

**Summary:** <N> skill directories in `release/skills/`. <M> entries in `deploy.sh` SKILL_LIST. <K> drift entries flagged.

| Skill | In Folder | In SKILL_LIST | Status |
|---|---|---|---|
| artifact-generator | ✓ | ✓ | OK |
| ... | ... | ... | ... |
```

## Dependency Graph Node

This skill's dependency edges are declared in its CI row in `core/skills/registry.md`.
- Upstream: `release/skills/` directory listing, `deploy.sh` SKILL_LIST array
- Downstream: User (review)
- Shared contracts: none (report-only; no follow-up tags emitted)
- RAID prefix: none (report-only)

## Evidence Quality Protocol

Every factual claim in this skill's outputs carries an evidence-quality label per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, or `[RECOMMENDED]`. This skill's internal analysis uses only `[SOURCE]` labels — every count and drift flag is derived directly from filesystem listing and parsed deploy.sh content, so assumption labels are not expected in normal operation.

## Reversibility Discipline

This skill produces report-only outputs. No decision-class items are emitted. pmo-qa-auditor G4 reversibility check is not applicable to this skill's outputs — G4 skip is intentional and declared here.

## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.

## Domain-Specific Failure Modes

### Hardcoded expected-count assumption — INPUT

- **Signature (observable signal):** The skill reports "drift detected" because it was written against a point-in-time expectation (e.g., "SKILL_LIST should have 20 entries") and the platform has since added a skill legitimately. The drift is a false positive.
- **Conditional:** do NOT compare the skill-directory count against a hardcoded expected number when the skill suite grows organically across releases, because hardcoded counts become stale between releases and produce false-positive drift reports that erode trust in the smoke test.
- **Root cause:** Writing the check once against a snapshot of the current state is easier than writing a relational check (folder-vs-SKILL_LIST comparison). Under authoring pressure, shortcut to static count.
- **Mitigation:** Always perform a set comparison between actual folder contents and actual SKILL_LIST contents. Never embed an expected-count constant. If the check needs a floor (e.g., "SKILL_LIST should have at least N entries"), make the floor a parameterized threshold with the threshold value sourced from a living config — not hardcoded in the skill body.
- **Principal response vs. junior response:** Principal writes the check as a pure set-comparison function; the count is reported but not asserted. Junior hardcodes "20" as the expected count and ships, then files noise issues when v4.0 legitimately adds a skill.

### Supplementary-skill absence misread as drift — PROC

- **Signature (observable signal):** The skill reports a canary drift for `prompt-builder` because it's in `SUPPLEMENTARY_SKILLS` array but being cross-checked against the main `SKILL_LIST` only — missing the SUPPLEMENTARY_SKILLS array in the comparison.
- **Conditional:** do NOT report drift based on `SKILL_LIST` comparison alone when `deploy.sh` has both `SKILL_LIST` and `SUPPLEMENTARY_SKILLS` arrays tracking deployed skills, because skills registered in SUPPLEMENTARY_SKILLS are still deployed — ignoring them produces false-positive drift reports for every supplementary skill.
- **Root cause:** The primary array (`SKILL_LIST`) is the obvious one; the supplementary array is easy to miss without reading deploy.sh end-to-end. Under time pressure, authors grep for "SKILL_LIST" and ignore the adjacent array.
- **Mitigation:** Parse both `SKILL_LIST` and `SUPPLEMENTARY_SKILLS` arrays from deploy.sh and union them before comparison. Document the dual-array check explicitly in the workflow so future edits preserve it.
- **Principal response vs. junior response:** Principal reads deploy.sh end-to-end and identifies all skill-tracking arrays before writing the check. Junior greps for the obvious one and ships.

### Reports drift in the middle of an in-flight refactor — TRIG

- **Signature (observable signal):** The skill runs during a Wave 2 or Wave 3 release window when skill-creator has been deleted but pmo-skill-refiner hasn't been added to SKILL_LIST yet (or vice versa mid-refactor). Reports drift even though the drift is a known intermediate state.
- **Conditional:** do NOT report drift as "action required" when an open PR on the current branch explicitly deletes or adds a skill, because drift mid-refactor is expected — flagging it as action-required generates noise issues for work already in progress.
- **Root cause:** The skill has no awareness of the release process or in-flight PRs. It treats the filesystem state as authoritative at every invocation, regardless of whether changes are being committed in the current session.
- **Mitigation:** In the output's Summary paragraph, include a check for uncommitted or staged changes affecting `release/skills/` or `deploy.sh` — if present, prefix the drift report with "⚠️ In-flight changes detected; drift report is transitional" and suggest re-running after the PR merges. This is a statelessness concession: the skill does not read open PRs, but it reads working-tree state which is a proxy.
- **Principal response vs. junior response:** Principal acknowledges the skill's statelessness and calibrates the output framing to be informational rather than alarming during known-unstable states. Junior treats every drift as a defect and produces noise that the operator has to triage.

### Canary self-status emitted as standalone consumer-facing artifact — OUT

- **Signature (observable signal):** A canary run produces its roster report or its own
  fixture status as a standalone consumer-facing artifact — a file written to disk or
  staged to a project folder, a stakeholder-styled "deployment health" deliverable, or a
  report augmented with recommendations or next actions — instead of the contracted
  inline two-section output (one summary paragraph + one drift table).
- **Conditional:** do NOT emit the canary's roster report or its own fixture status as a
  standalone consumer-facing artifact or augment it with recommendations or next actions,
  because the canary is a report-only permanent fixture whose output contract is one
  inline summary paragraph plus one drift table — a standalone or advisory artifact
  escalates smoke-test output into a production deployment-health product that consumers
  begin to act on.
- **Root cause:** The roster report superficially resembles a deployment-health
  deliverable, and suite-wide habits (artifacts staged for review, push-to-resolve,
  recommendations appended to findings) pull toward producing a durable consumer
  artifact. The fixture's narrower report-only contract is easy to override with the
  suite default.
- **Mitigation:** Render the report inline in conversation only, in the two-section
  Output Contract shape. Do not write the report to any file, do not stage it as an
  artifact, and do not append recommendations or actions; when drift is real, state the
  drift fact in the table and leave follow-up to the operator via the "Skip and route
  elsewhere" routing list (pmo-qa-auditor Mode D, pmo-skill-editor, pmo-skill-refiner).
- **Principal response vs. junior response:** Principal keeps the canary inside its
  fixture surface — inline two-section report, [SOURCE]-labeled counts, no artifact, no
  advice — and lets the operator route any follow-up. Junior "upgrades" the output to a
  polished deployment-health artifact with remediation steps; consumers start acting on
  fixture output, and the canary's smoke-test role quietly becomes a production reporting
  surface no one designed or reviews.

### Fixture-induced drift row passed to the consumer without [CANARY EXPECTED] annotation — HAND

- **Signature (observable signal):** The roster report's drift table contains a row
  caused by the canary's own permanent-fixture status — its source directory present
  under `release/skills/` while intentionally absent from the deployed-roster arrays
  and `packages/` (source-only per ADR-04) — rendered with the same Status value as a
  genuine factory-regression drift row, with no annotation distinguishing it.
- **Conditional:** do NOT hand a drift row to the report consumer without a
  `[CANARY EXPECTED]` annotation when the row is induced by the canary's own ADR-04
  fixture status rather than by roster drift, because the report's consumers — the
  operator reading the table, or a deep audit routed onward to pmo-qa-auditor Mode D —
  cannot distinguish fixture-induced signal from factory regression at the report
  boundary, and an unannotated expected row either triggers a noise escalation or
  trains the reader to skim past drift rows, masking the real regression the smoke
  test exists to catch.
- **Root cause:** The set comparison is honest — the fixture row IS a
  folder-vs-roster mismatch — and annotating it requires the canary to model its own
  exclusion as a known state rather than a finding. A report-only skill defaults to
  printing what the comparison returns; the annotation is boundary work on top of the
  comparison.
- **Mitigation:** Maintain the known-fixture predicate inside the workflow: a drift row
  whose subject is the canary itself (or any registered source-only fixture) renders
  with Status `[CANARY EXPECTED]` and one clause naming the basis ("source-only
  permanent fixture per ADR-04 — excluded from the deploy roster by design"). The
  Summary line then splits the count — "K drift entries flagged (J expected-fixture,
  K−J actionable)" — so the existing routing note (deep audit → pmo-qa-auditor Mode D)
  receives only actionable signal. The annotation stays report-internal: still no
  recommendations, no actions.
- **Principal response vs. junior response:** Principal annotates the expected row,
  splits the summary count, and the operator reads the table in five seconds with zero
  false escalations. Junior prints the raw set difference; the operator either
  escalates the canary's own row as a deploy defect (noise) or learns that "the drift
  table always has one row" — and the day a real skill goes missing from the roster,
  the genuine row inherits the learned shrug.

## Principal Standard Target

≥ 6/8 PASS at creation per `core/standards/principal-standard-checklist.md`.

Competencies this skill naturally strengthens:
- **Systems Thinking** — the set-comparison check requires modeling the skill deployment system (both SKILL_LIST and SUPPLEMENTARY_SKILLS).
- **Ruthless Clarity** — the output is a concrete count + table; no speculation.
- **Evidence-Based Execution** — all output facts are [SOURCE]-labeled from filesystem and deploy.sh content.
- **Judgment Under Uncertainty** — TRIG failure mode explicitly handles the "in-flight refactor" uncertainty case.
- **Operational Awareness** — knows not to produce recommendations (report-only); escalates via pmo-qa-auditor Mode D routing rather than taking direct action.
- **Learning & Escalation** — failure modes surface the ways the canary itself can mis-report.

Competencies this skill is at risk for:
- **Organizational Leverage** — low; the canary is a narrow utility that serves one check. Leverage compounds only over time as an always-on smoke test.
- **Mentorship & Culture** — not applicable; the canary is a tool, not a mentoring artifact.

## References

- Produced by: `pmo-skill-refiner` (Create-New workflow)
- AC demonstration (artifacts removed by a later commit; superseded, preserved in git history)
- Preservation rationale: ADR-04 from Stage 5 design of  (recommend keep as permanent smoke test)
