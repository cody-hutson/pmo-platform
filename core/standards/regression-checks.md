---
title: PMO Agent Suite — Regression Checks
purpose: The regression test bank the Skill Editor runs after any skill edit to verify the edit did not break cross-skill contracts, output quality, or behavioral requirements.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: pmo-skill-editor (Regression-check mode after any skill edit); pmo-skill-refiner; the cross-skill contract verification harness
---
# PMO Agent Suite — Regression Checks

## Purpose

Regression test bank for the Skill Editor. After any skill edit, the editor runs relevant checks from this list to verify the edit didn't break cross-skill contracts, output quality, or behavioral requirements.

This document is derived from production experience building the PMO Agent Suite through Phases 1-9 and represents 35+ regression checks organized by category with skill-to-check mapping for efficient testing workflows.

**Scope (distinct from the per-skill regression baseline).** This is the **PMO Agent Suite** regression bank — content/contract/behavior checks the Skill Editor runs after a skill edit. It is intentionally distinct from `release/references/specs/skill-suite-regression-checks.md` ("Regression Checks — PMO **Skill Suite**"), which is the per-skill invocation/non-invocation/smoke-output baseline maintained by `pmo-skill-refiner`. Different basename, different purpose: this bank audits an edit against cross-skill contracts; that baseline audits a skill against its own prior-version behavior. The two are not duplicates and are not single-sourced to each other.

## How to Use

1. Identify which skill was modified
2. Look up that skill's required checks in the Skill-to-Check Mapping table
3. Add all applicable cross-skill (XC-##) checks
4. Run each check against a representative test artifact
5. Record PASS/FAIL with evidence in your test report
6. If any FAIL: diagnose whether the failure is edit-related or pre-existing
7. For edit-related failures: revert, fix, and re-test before committing

## Check Categories

### Category 1: Evidence Quality (EQ-01 through EQ-06)

**Applies to:** All skills

These checks ensure all factual claims, inferences, assumptions, and recommendations are properly tagged and traceable.

**EQ-01:** All factual claims in output are tagged with `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, or `[RECOMMENDED]`
- Intent: No naked claims
- Validation: Scan output for sentences containing dates, names, metrics, status, decisions, risks, or commitment-level assertions. Each must have exactly one tag.
- Failure mode: Unmarked claim appears in output (e.g., "The phase ends on March 22" without a tag)

**EQ-02:** `[SOURCE]` tags include specific citation
- Intent: Reader can verify the claim immediately
- Validation: For each `[SOURCE]` tag, confirm it includes artifact reference (e.g., timestamp, Jira field, document section, transcript marker)
- Failure mode: `[SOURCE]` tag with no citation (e.g., "[SOURCE] The team is blocked" is invalid; must be "[SOURCE: Jira PROJ-123, status comment] The team is blocked")

**EQ-03:** `[INFERRED]` tags include reasoning chain
- Intent: Reader understands how the claim was derived
- Validation: For each `[INFERRED]` tag, confirm it shows at least 2 steps of logic (e.g., "If A happened (SOURCE) and B is standard practice (CONTEXT), then C is likely")
- Failure mode: `[INFERRED]` with no reasoning (e.g., "[INFERRED] Risk is high" without explaining the inference)

**EQ-04:** `[ASSUMPTION – CONFIRM]` tags include proposed answer AND basis
- Intent: Stakeholder can confirm or correct; not open-ended questions
- Validation: For each `[ASSUMPTION – CONFIRM]` tag, confirm it proposes a specific answer and states the basis for the proposal
- Failure mode: "[ASSUMPTION – CONFIRM] How many testers are available?" is invalid; must be "[ASSUMPTION – CONFIRM] Assuming 3 testers from QA team (basis: team roster, needs confirmation)" or similar

**EQ-05:** No untagged factual claims in any section
- Intent: Complete traceability
- Validation: Re-scan entire output for any missed factual claims that lack tags
- Failure mode: A claim like "The sprint ends Friday" appears without any tag

**EQ-06:** `[RECOMMENDED]` dates clearly distinguished from stakeholder-committed dates
- Intent: PMO doesn't inadvertently turn recommendations into commitments
- Validation: Any date tagged `[RECOMMENDED]` must use language like "I recommend," "suggest," "propose," or similar. Stakeholder-committed dates must be tagged `[SOURCE]` or `[CONTEXT]`.
- Failure mode: Recommended date presented as if confirmed (e.g., "[RECOMMENDED] Go-live is April 15" reads as confirmed)

---

### Category 2: Push-to-Resolve (PTR-01 through PTR-06)

**Applies to:** All Tier 1 and Tier 2 skills (PPM, DE, CW, CM, TA, PD)

These checks enforce the "push-to-resolve" principle: no action items without full context, no vague follow-ups, no open questions beyond 5.

**PTR-01:** No action items without full resolution packages
- Intent: Stakeholders have what they need to act
- Validation: For each action item, confirm it specifies: (a) WHO is responsible, (b) WHAT exactly they're doing, (c) BY WHEN, (d) context/background sufficient to start work
- Failure mode: "A decision needs to be made on the architecture" (missing: decision owner, timeline, decision options, decision criteria)

**PTR-02:** No "a meeting should be scheduled" without drafted agenda, audience, objective, and time window
- Intent: Avoid meeting tax; provide ready-to-act guidance
- Validation: If output suggests scheduling a meeting, confirm the output includes: meeting title, attendees (by role/name), objective, agenda outline, and proposed time window
- Failure mode: "Schedule a design review meeting" without agenda or attendees specified

**PTR-03:** No "an email should be sent" without drafted email with audience, subject, body, and READY/NOT READY label
- Intent: Reduce friction for communication
- Validation: If output suggests sending an email, confirm it includes a **draft** with: To/Cc recipients, subject line, body text, and a READY or NOT READY assessment
- Failure mode: "Send an update to the team about the delay" without a draft email included

**PTR-04:** Follow-up communications are fully drafted, not flagged
- Intent: Drafts are immediately actionable
- Validation: If output routes to Comms Writer (CW) for an email or Teams message, confirm the CW skill uses READY/NOT READY assessment (not just a flag to CW)
- Failure mode: Routing to CW with "[Follow-up to CW: draft an email to stakeholders]" — CW must receive the draft from upstream or be given full context to draft it

**PTR-05:** RAID entries include all required fields
- Intent: RAID log is consistently filled and actionable
- Validation: Each RAID entry produced must include: (a) unique ID (R-[SKILL]-###), (b) description, (c) probability (%, clear basis), (d) impact (business-level statement), (e) trigger/symptom, (f) identified owner, (g) mitigation strategy with owner, (h) deadline or review cadence
- Failure mode: Risk entry with description and probability, but no owner or mitigation

**PTR-06:** Max 5 clarifying questions; everything else is `[ASSUMPTION – CONFIRM]`
- Intent: Enforce CLAUDE.md universal preference; avoid question fatigue
- Validation: Count total clarifying questions in output. If more than 5, confirm the remaining ones are reframed as assumptions with proposed answers.
- Failure mode: 8 open questions posed in output

---

### Category 3: Output Structure (OS-01 through OS-07)

**Applies to:** Varies by skill (see Skill-to-Check Mapping table)

These checks ensure output follows agreed contracts per skill.

**OS-01:** All required sections present per skill's output contract
- Intent: Completeness per skill definition
- Validation: Against skill's documented output contract (reference: per-skill-output-contracts.md), confirm all mandated sections are present
- Failure mode: PPM skill produces output without Executive Narrative section (if contract requires it)

**OS-02:** Section ordering matches contract
- Intent: Readers find information predictably
- Validation: Compare output section sequence to documented contract sequence
- Failure mode: RAID Log appears before Evidence Quality Summary when contract specifies reverse order

**OS-03:** Gate results use 3-level scale where applicable
- Intent: Avoid ambiguous pass/fail on gates
- Validation: Any gated decision (e.g., "Is design ready for dev?") uses exactly one of: PASS / CONDITIONAL PASS / FAIL
- Failure mode: Gate shows "PASS with concerns" instead of "CONDITIONAL PASS"

**OS-04:** Change Summary appended when skill produces artifact updates
- Intent: Tracker Manager knows exactly what changed in operational documents
- Validation: If skill output includes instructions to update tracker, plan, or log, confirm a "Change Summary" section shows: what changed, where, why, and evidence source
- Failure mode: Tracker update instruction provided without a Change Summary section

**OS-05:** Executive narrative is 6-10 lines and decision-grade
- Intent: PPM can quickly brief leadership
- Failure mode: Narrative is 2 lines (too brief) or 20 lines (not executive)

**OS-06:** Summary sections are 3-5 lines/sentences
- Intent: Design Engineer, Comms Writer, TA, PD outputs are scannable
- Validation: Count lines in summary sections (if contract requires one)
- Failure mode: Summary is 12 sentences (too detailed)

**OS-07:** Mode & Inputs section present with `[SOURCE]` labels on all inputs
- Intent: Output is reproducible and traceable to input artifacts
- Validation: Output includes a section showing which mode the skill ran in and what input artifacts were used (with source labels)
- Failure mode: Output is produced with no indication of what artifacts were analyzed

---

### Category 4: Cross-Skill Contracts (XC-01 through XC-08)

**Applies to:** All skills that emit or consume follow-up artifacts

These checks verify that hand-offs between skills maintain contract integrity.

**XC-01:** Follow-up tags use correct format: Context/Source/Scope/Inputs/Constraints
- Intent: Target skill receives actionable routing information
- Validation: If output includes a follow-up tag (e.g., `[Follow-up to CW: ...]`), confirm it includes: (a) context (why this follow-up?), (b) source (where did this originate?), (c) scope (what exactly?), (d) inputs (what artifacts?), (e) constraints (deadline, decision gates, etc.)
- Failure mode: `[Follow-up to CW: Draft an email]` without context on why/deadline/constraints

**XC-02:** Follow-up tags route to correct target skill per dependency graph
- Intent: Routing is consistent with documented skill dependencies
- Validation: Cross-reference output follow-ups against the PMO Agent dependency edges (reference: `registry.md`). Confirm no routing to non-existent skills or circular chains.
- Failure mode: Follow-up routed to "Requirements Designer" when no such skill exists

**XC-03:** RAID entries use correct skill prefix
- Intent: Accountability is clear; RAID log is parseable
- Validation: All RAID IDs follow format R-[SKILL]-### where [SKILL] is one of: PPM, DE, CW, CM, TA, PD, QA, SE
- Failure mode: Risk entry labeled "R-DES-001" (wrong prefix for Design Engineer)

**XC-04:** Evidence quality labels propagate correctly upstream-to-downstream
- Intent: Downstream skills inherit evidence quality and don't act on uncertain inputs
- Validation: If upstream skill (e.g., PPM) marks a claim as `[ASSUMPTION – CONFIRM]`, confirm downstream skill (e.g., CW) receiving that output marks related output as NOT READY until assumption is confirmed
- Failure mode: PPM assumes team capacity at "[ASSUMPTION – CONFIRM]", DE produces a schedule as if capacity is confirmed, CW marks output READY when it should be NOT READY

**XC-05:** Max-depth-2 routing constraint respected
- Intent: Prevent deep skill-call chains; keep output simple
- Validation: No skill should route to another skill that itself routes to a third skill (max 2-hop chains: Skill A → Skill B → Skill C, but B routes must not further invoke C)
- Failure mode: PPM routes to DE; DE routes to CW; CW routes to TA (3-hop chain)

**XC-06:** Dual-Framing Bridge produces dual framing only when dual_framing_enabled = true
- Intent: Dual-Framing Bridge (cross-team framing) is applied only when justified
- Validation: If output includes Dual-Framing Bridge framing (dual perspective: sponsor view + PMO view), confirm PROJECT.md has `dual_framing_enabled: true`
- Failure mode: Dual framing produced when dual_framing_enabled is false or not set

**XC-07:** Comms Writer READY/NOT READY assessment correctly evaluates evidence quality
- Intent: CW prevents low-confidence outputs from being sent
- Validation: If CW output contains claims marked `[ASSUMPTION – CONFIRM]`, confirm output is marked NOT READY; if all claims are `[SOURCE]` or `[CONTEXT]`, confirm output can be marked READY
- Failure mode: CW marks email READY even though it contains unconfirmed assumptions

**XC-08:** Dual output produced when required; exceptions properly applied
- Intent: Artifact-centric outputs (files) are always produced; dual output is available when stakeholder context allows
- Validation: Per skill contract, confirm dual output (file + paste block) is produced unless an exception applies (e.g., CW email/Teams exception: output goes to file only)
- Failure mode: DE produces file but no paste block (if contract requires both)

---

### Category 5: Guardrails (GR-01 through GR-07)

**Applies to:** All skills

These checks prevent common failure modes and enforce workspace policies.

**GR-01:** No status theater
- Intent: Output drives decisions/actions; avoids recaps without substance
- Validation: Scan output for sentences that recap status without proposing an action, decision, or risk. Confirm each status element either (a) triggers an action, (b) informs a decision, or (c) identifies a risk.
- Failure mode: "The design phase is 60% complete" stated without context about whether that's on track, behind, or flagging a concern

**GR-02:** No fabricated data
- Intent: Respect CLAUDE.md universal preference; only use data from artifacts or label assumptions
- Validation: Every metric, name, date, and status in output must be traceable to a source artifact or labeled `[ASSUMPTION – CONFIRM]`
- Failure mode: "The team consists of 5 engineers and 2 QA" when the actual roster is not known

**GR-03:** No `[INSERT]` or `[TBD]` placeholders in outputs
- Intent: Outputs are complete and ready to act
- Failure mode: "Notify [INSERT NAME] by [TBD DATE]"

**GR-04:** No more than 5 clarifying questions
- Intent: Enforce CLAUDE.md universal preference
- Validation: Same as PTR-06; count questions and confirm max is 5
- Failure mode: 7 open questions in output

**GR-05:** No passive risk voice
- Intent: Risks are actionable; named, owned, with mitigations
- Validation: Scan for risk language. Confirm every risk statement includes: (a) named risk, (b) identified owner, (c) mitigation strategy
- Failure mode: "There may be integration challenges" without naming what challenges, who owns resolution, or how to mitigate

**GR-06:** Day-of-week validated on all date references
- Intent: Respect CLAUDE.md universal preference; dates are reliable
- Validation: For each date mentioned (e.g., "March 22"), confirm the day-of-week is correct (e.g., March 22, 2026 is a Friday). Spot-check 2-3 dates.
- Failure mode: "March 22 (Tuesday)" when March 22, 2026 is actually a Friday

**GR-07:** Consistent vendor labeling
- Intent: Avoid confusion in RAID logs and artifact references
- Validation: If one person from a firm (e.g., "Consultant from Acme Consulting") is labeled with their firm, confirm all people from that firm use the same convention throughout output
- Failure mode: One consultant labeled "John from Acme", another just as "Sarah" when both are from same firm

---

### Category 6: Skill-Specific Checks (SS-01 through SS-10)

**Applies to:** Individual skills as noted

These checks verify skill-unique behaviors and output contracts.

**SS-01 (PPM):** Produces structured tracker update instructions for Tracker Manager
- Intent: Tracker updates are unambiguous and complete
- Validation: If PPM output includes tracker updates, confirm instructions specify: (a) which tracker (project plan, RAID log, dependency register, etc.), (b) which row/entry, (c) which field, (d) new value, (e) reason for change
- Failure mode: "Update the tracker with new timeline" without specifying which tracker row and which field

**SS-02 (PPM):** Transcript processing produces tags, 3-sentence summary, and participants for Transcript Register
- Intent: Transcripts are consistently registered for cross-project knowledge
- Validation: When PPM processes a transcript, confirm output includes: (a) topic tags, (b) 3-sentence summary, (c) participant list (by role, with names if known)
- Failure mode: Transcript summary is 8 sentences; participant list is incomplete

**SS-03 (PPM):** Proactive behavior: surfaces follow-ups approaching deadline and unresolved patterns
- Intent: PPM is forward-looking; catches slipping commitments early
- Validation: When running PPM against project state, confirm output calls out: (a) any follow-ups with deadlines within 3 days, (b) any patterns of unresolved items (e.g., 3+ risks with same root cause)
- Failure mode: Critical follow-up due tomorrow is not flagged in PPM output

**SS-04 (DE):** All 7 modes produce correct output structure
- Intent: Design Engineer modes are consistent and complete
- Validation: Run DE in each of its 7 modes (see Design Engineer skill definition) and confirm each produces its documented output structure
- Failure mode: Mode 3 (e.g., "capacity modeling") produces output without the required "Capacity Matrix" section

**SS-05 (DE):** Sprint planning includes capacity modeling
- Intent: Schedule is grounded in team capacity
- Validation: When DE produces a sprint plan, confirm it includes: (a) team roster with capacity (hours/week), (b) work items with estimated effort, (c) capacity utilization math, (d) note if over/under capacity
- Failure mode: Sprint plan lists tasks without capacity analysis

**SS-06 (CW):** All 8 communication types available and correctly formatted
- Intent: CW can handle any communication need
- Validation: Confirm CW skill documentation lists 8 communication types and that all 8 are available in skill (e.g., email, Teams, Slack, meeting agenda, status report, announcement, escalation, all-hands brief)
- Failure mode: Only 5 communication types are implemented

**SS-07 (CW):** Multi-audience capability produces send-order guidance
- Intent: When one message goes to multiple audiences, CW advises on sequence
- Validation: When CW produces a message for multiple audiences (e.g., sponsor first, then team), confirm output includes send-order guidance (e.g., "Send to sponsor by EOD Tuesday, team by EOD Wednesday")
- Failure mode: Multi-audience message with no send-order guidance

**SS-08 (CM):** Mode F (future-state planning) produces T-minus schedule
- Intent: Implementation planning is timeline-driven
- Validation: When CM Mode F is run, confirm output produces a T-minus schedule (e.g., "T-30: Design complete", "T-20: Build begins", etc.) with dates and owners
- Failure mode: Mode F output is sequential list without T-minus framing

**SS-09 (TA):** Risk matrix covers all 6 dimensions
- Intent: Technical risk is comprehensively evaluated
- Validation: When TA produces a risk assessment, confirm it covers all 6 dimensions: (a) integration, (b) data, (c) performance, (d) security, (e) environment (infrastructure), (f) operational (process/people)
- Failure mode: TA risk assessment omits the "operational" dimension

**SS-10 (PD):** Bidirectional process-requirements linking enforced
- Intent: Requirements traceability is maintained in both directions
- Validation: When PD output includes process maps and requirements, confirm: (a) each requirement maps to one or more process steps, (b) each process step is traceable to a requirement, (c) chain integrity metrics are calculated (e.g., "% of requirements mapped")
- Failure mode: Orphaned requirement (not linked to any process step)

### Category 7: Registered Corpus Predicates (RCP-01 through RCP-03)

**Applies to:** any edit touching one of the corpus documents the **Trigger table** below
enumerates — the documents named by those **class-3-V rows** of the gate-coverage register
in `core/standards/gate-efficacy-standard.md` whose runner is `pmo-skill-editor` Mode C,
and no others. A class-3 row whose predicate is encoded somewhere else puts **no** RCP
check in scope: the register's other class-3 rows resolve against their own
runner-definition files, so an edit touching one of *those* documents runs whatever that
row's runner defines, not the checks below. Read the scope off the trigger table, never off
the class-3 population.

**Why these live here, and why deleting one is a defect.** The register names
`pmo-skill-editor` **Mode C** as the runner for three prose-declared predicates. A
register row whose named runner does not itself carry the predicate is a runner that
cannot fail — it satisfies the convention's letter while asserting nothing, which is the
`unresolvable-runner` defect `gate-efficacy-standard.md` § *Runner resolution* defines.
Encoding the three predicates here is what makes that register claim **true rather than
asserted**. The check IDs below are the register's **resolution anchors for those three
rows**: each class-3-V row that names Mode C declares `runner-def:` pointing at this file
plus the anchor it must contain, and `deploy.sh --check` Check 62 recomputes that
resolution on every run. This file is **one** resolution target in the register, never the
whole set — a class-3-O row resolves against whatever file defines *its* runner, and a
named-gap row correctly carries no pointer at all. Deleting or renaming `RCP-01`,
`RCP-02`, or `RCP-03` therefore turns Check 62 red rather than silently re-opening the
gap.

**Trigger table** — keyed on the **edited file**, not on a skill, because each predicate
is a property of a corpus document rather than of a skill's output:

| Edited file | Run |
|---|---|
| `core/schemas/tracker-schemas.md`, its `tracker-manager` skill-local half, or `operations/templates/sprint-tracker-template.md` | RCP-01 |
| `operations/skills/delivery-engine/references/estimation-standards.md` | RCP-02, RCP-03 |

Every RCP check **fails closed**: a check that was not run is a FAIL, not a pass. Report
the verdict per check with the evidence that produced it — never "no issues found"
without naming what was compared.

**RCP-01 (tracker-schemas ↔ sprint-tracker-template):** calibration-path column headers equal the governing schema's field names, **in order**
- Intent: a positional writer fills the column it intends to. Order — not merely membership — is the property that makes the template safe to write against.
- Validation: extract the calibration-path column headers from `operations/templates/sprint-tracker-template.md` under `## Estimate-Actual Pairs`, and the corresponding field names from `core/schemas/tracker-schemas.md` § Tracker 10. Compare them as **ordered sequences**. An unordered-but-complete header set is a **FAIL**.
- Failure mode: two headers are swapped, the set still matches, an order-blind comparison reports PASS, and the next writer fills two columns backwards.

**RCP-02 (estimation-standards §8):** the §8 grant table is complete against both consumers
- Intent: the grant table is the contract between §8 and the skills that read it; a table that has drifted from its consumers grants nothing reliable.
- Validation: diff the §8 grant table against what each consumer actually reads. An element a consumer reads that the table does not grant is `used-but-not-granted`; a granted element no consumer exercises is `granted-but-unused`; an element read as a condition but rendered nowhere is `used-but-unobservable`. Each is a **FAIL**, and an **unrun diff is a FAIL, not a pass**.
- Failure mode: a consumer's instruction text gains a read of a §8 element with no matching grant row, and the edit ships because the diff was never run.

**RCP-03 (estimation-standards §8.6.2):** exactly one literal corpus-wide per §8 negative-path element
- Intent: "rendered verbatim" is only falsifiable while a single literal exists to compare against. Two literals make the claim unverifiable in both directions.
- Validation: for each §8 negative-path element, count the **distinct** literals corpus-wide. More than one is a **FAIL** — an abbreviated, relabelled, or reflowed copy counts as a second literal.
- Failure mode: a second, reflowed copy of the §8.3 `estimation bias: not computable …` fenced literal is introduced into a consumer's instruction text, and each copy is checked only against itself.

### Category 8: Tool Anchor Resolution (ANC-01 through ANC-02)

**Applies to:** any edit to a repo-root anchor assignment — the
`REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"` idiom — in a shell tool under
`release/tools/` or `core/deploy/tools/`.

**Reachability — read this before treating the category as a trigger.** This
document's consumers run it after a **skill** edit, and no consumer of this
document edits shell tools under those trees. These two checks therefore have
**no reachable trigger here**. The category is a **citation surface**: the
enforcement lives in the executable self-test named under *Coverage surface*
below, and this entry records the invariant so it is discoverable alongside its
sibling corpus predicates. Treating it as an enforced trigger would reproduce
the fail-open the category exists to close.

**Coverage surface — stated adjacent to the implementation, so the declaration
cannot drift from what enforces it.** The predicate is implemented as the anchor
arms of the `--self-test` in `release/tools/compute-release-velocity.sh`, which
the self-test coverage engine **discovers** rather than enumerates, and which the
release-tooling smoke workflow executes pre-merge. That workflow's runner
partition is total and disjoint, and this tool sits on the **ubuntu partition
only**. The consequence is stated rather than implied: the primary-checkout half
of the invariant is CI-gated, and the **worktree half has no CI backstop** — it
is verified by an operator run. The always-on arm is git-independent and does
catch the defect in both contexts, so the class cannot silently reappear; but the
redundancy is single-sided and a reader should not assume otherwise.

**Trigger table** — keyed on the **edited file**, not on a skill, because the
invariant is a property of a tool's source rather than of a skill's output:

| Edited file | Run |
|---|---|
| `release/tools/*.sh`, `release/tools/lib/*.sh` | ANC-01, ANC-02 |
| `core/deploy/tools/*.sh` | ANC-01, ANC-02 |

Both ANC checks **fail closed**: a check that was not run is a FAIL, not a pass,
and an assertion whose own liveness control did not run is a FAIL rather than a
green result.

**ANC-01 (repo-root anchor resolves to the repository root):** a tool's computed repo root is the root under which that tool's own directory sits at its repo-relative path
- Intent: the anchor scopes git queries and path joins. An anchor that overshoots does not error — it resolves to *some* directory, and the queries it feeds return empty or wrong answers that read as legitimate output.
- Validation: run the executable self-test named under *Coverage surface* above. This entry **cites** that check as its runner and does not restate the predicate as an independently-enforced rule. The predicate that check implements is a resolution identity: the computed root joined to the tool's repo-relative directory must be the **same directory** as the tool's own directory, compared by identity rather than by string; and where git is available, the computed root must additionally equal the working-tree root discovered from the tool's own directory.
- Failure mode: the anchor walks one level too far, and the signature is layout-dependent. From a primary checkout it lands outside any repository, the git query returns nothing, and the signal degrades to `N/A` behind a `|| true` — invisible. From a worktree it lands in the worktrees directory, whose git toplevel is the **primary checkout**: a *different working tree* that answers successfully with the wrong answer. This dual signature is why "is the computed root inside a git repository" is **not** a sufficient test — it passes the worktree case.

**ANC-02 (the anchor assertion carries a liveness control):** the check asserting ANC-01 also asserts that a known-bad anchor is REJECTED, through the same predicate implementation
- Intent: an assertion that cannot fail is a decoration. The liveness control is what distinguishes a regression guard from one.
- Validation: confirm the good-anchor arm and the known-bad-anchor arm invoke **one** predicate implementation and assert on its observed verdict — not two independently-spelled inline tests. The shared implementation is the property being checked: it makes the pair two-sided, so a predicate mutated to always-accept fails the control arm while one mutated to always-reject fails the assertion arm. Two separate inline tests do **not** satisfy this check.
- Failure mode: the control arm is written as a standalone filesystem comparison. Because the bad anchor's joined path does not exist in any layout, that arm is **constant-true** — it passes even with the assertion arm deleted entirely, and a later change to the predicate silently turns the guard into a no-op that still reports PASS.

**Anti-pattern — a textual depth-vs-dot-count check is not an acceptable
implementation of ANC-01.** Comparing a file's directory depth against the length
of the `..` run in its anchor **fails closed against working scripts**. Each false
positive `cd`s from an already-walked intermediate variable, so its *effective*
walk equals its depth and the spelling is legitimately shorter than the depth;
when this was last measured across every anchor assignment in the repository, the
correct-but-compound anchors in the flagged set outnumbered the single genuine
defect six to one. The check must test **resolution behaviour**, never spelling.

---

## Skill-to-Check Mapping

This table shows which checks apply to each skill. Use this table to select tests for regression after editing a skill.

| Check ID | Category | PPM | DE | CW | CM | TA | PD | QA | SE |
|----------|----------|-----|----|----|----|----|----|----|-----|
| EQ-01 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| EQ-02 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| EQ-03 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| EQ-04 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| EQ-05 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| EQ-06 | Evidence Quality | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| PTR-01 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| PTR-02 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| PTR-03 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| PTR-04 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| PTR-05 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| PTR-06 | Push-to-Resolve | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| OS-01 | Output Structure | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OS-02 | Output Structure | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| OS-03 | Output Structure | ✓ | ✓ |   | ✓ | ✓ |   |   |   |
| OS-04 | Output Structure | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| OS-05 | Output Structure | ✓ |   |   |   |   |   |   |   |
| OS-06 | Output Structure |   | ✓ | ✓ | ✓ | ✓ | ✓ |   |   |
| OS-07 | Output Structure | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-01 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-02 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-03 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-04 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-05 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-06 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-07 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XC-08 | Cross-Skill | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-01 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-02 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-03 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-04 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-05 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-06 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GR-07 | Guardrails | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| SS-01 | Skill-Specific | ✓ |   |   |   |   |   |   |   |
| SS-02 | Skill-Specific | ✓ |   |   |   |   |   |   |   |
| SS-03 | Skill-Specific | ✓ |   |   |   |   |   |   |   |
| SS-04 | Skill-Specific |   | ✓ |   |   |   |   |   |   |
| SS-05 | Skill-Specific |   | ✓ |   |   |   |   |   |   |
| SS-06 | Skill-Specific |   |   | ✓ |   |   |   |   |   |
| SS-07 | Skill-Specific |   |   | ✓ |   |   |   |   |   |
| SS-08 | Skill-Specific |   |   |   | ✓ |   |   |   |   |
| SS-09 | Skill-Specific |   |   |   |   | ✓ |   |   |   |
| SS-10 | Skill-Specific |   |   |   |   |   | ✓ |   |   |

---

## Quick-Reference: Skill Edit Checklists

Use these quick checklists after editing a skill to select your regression test set.

### After editing PPM (Project/Program Manager)
Run all EQ checks + PTR-01, PTR-02, PTR-03, PTR-04, PTR-05, PTR-06 + OS-01, OS-02, OS-03, OS-04, OS-05, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-01, SS-02, SS-03

**Total: 35 checks**

### After editing DE (Design Engineer)
Run all EQ checks + PTR-01 through PTR-06 + OS-01, OS-02, OS-03, OS-04, OS-06, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-04, SS-05

**Total: 37 checks**

### After editing CW (Comms Writer)
Run all EQ checks + PTR-01 through PTR-06 + OS-01, OS-02, OS-04, OS-06, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-06, SS-07

**Total: 35 checks**

### After editing CM (Change Manager)
Run all EQ checks + PTR-01 through PTR-06 + OS-01, OS-02, OS-03, OS-04, OS-06, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-08

**Total: 36 checks**

### After editing TA (Technical Architect)
Run all EQ checks + PTR-01 through PTR-06 + OS-01, OS-02, OS-03, OS-04, OS-06, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-09

**Total: 36 checks**

### After editing PD (Process Designer)
Run all EQ checks + PTR-01 through PTR-06 + OS-01, OS-02, OS-04, OS-06, OS-07 + XC-01 through XC-08 + GR-01 through GR-07 + SS-10

**Total: 35 checks**

---

## Running Regression After Edit

### Standard Procedure

1. **Identify modified skill** — Note the skill name (PPM, DE, CW, CM, TA, or PD)

2. **Select test set** — Use the Quick-Reference checklist above to list all applicable checks

3. **Prepare test artifact** — Use a known-good [PROJECT_KEY] artifact (e.g., recent meeting transcript, current RAID log, draft design doc). Ensure artifact is representative of how skill is typically used.

4. **Run modified skill** — Execute skill against test artifact with documented input parameters

5. **Evaluate each check** — For each check in your test set:
   - Read the check definition and validation criteria
   - Scan the skill output for the condition being tested
   - Record PASS or FAIL
   - **If FAIL:** Note the specific evidence (quote from output, missing section, etc.)

6. **Diagnose failures** — For each FAIL:
   - Is this failure related to the edit you made?
   - Is this a pre-existing failure (unrelated to your change)?
   - If edit-related: What specifically caused the failure?

7. **Decision gate:**
   - **All PASS:** Proceed to commit
   - **Edit-related FAIL(s):** Revert edit or fix the skill, then re-test
   - **Pre-existing FAIL(s):** Document in a separate issue; may proceed if edit is unrelated to failure

### Test Report Template

```
## Regression Test Report
**Date:** [date]
**Skill Modified:** [skill name]
**Edit Summary:** [1-2 sentences on what was changed]

### Test Set (X checks)
[List all checks from Quick-Reference checklist]

### Results

| Check | Status | Evidence |
|-------|--------|----------|
| EQ-01 | PASS | All claims tagged ✓ |
| EQ-02 | FAIL | [SOURCE] tag on line 12 lacks citation |
| ... | ... | ... |

### Summary
- Total checks: X
- PASS: X
- FAIL: X
  - Edit-related: X
  - Pre-existing: X

### Decision
[Proceed to commit / Revert and fix / Document pre-existing issues]
```

---

## Reference: Skill Definitions

The regression checks above reference several skill definitions and cross-project artifacts. For context:

- **Skill Definitions:** See `/mnt/Claude/_Implementation/Skills/[SkillName]/SKILL.md`
- **Dependency edges:** See `core/skills/registry.md` for skill-to-skill dependency edges and routing rules
- **Output Contracts:** See `/mnt/Claude/_Implementation/Staging/per-skill-output-contracts.md` for detailed output structure requirements per skill and mode
- **[PROJECT_KEY] Project Context:** See `/mnt/Claude/Projects/[PROJECT_KEY] Implementation/PROJECT.md` for current project state (phase, team, dual_framing_enabled flag, etc.)
- **CLAUDE.md:** See `/mnt/Claude/CLAUDE.md` for workspace-wide preferences and universal rules

---

## Maintenance & Updates

This regression check bank is maintained based on production experience. When a new failure mode is discovered in testing:

1. Document the failure (what broke, how it broke)
2. Identify the check that should have caught it (or note if no check exists)
3. If no check exists, add a new check to the appropriate category
4. Update this file and re-run the regression suite against all skills

---

**Document Version:** 1.0
**Last Updated:** 2026-03-18
**Status:** Reference for PMO Skill Editor use
