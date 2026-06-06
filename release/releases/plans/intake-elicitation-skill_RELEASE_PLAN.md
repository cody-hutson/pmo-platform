# Release Plan — intake-elicitation-skill

Version-less release. Milestone `intake-elicitation-skill`. Release Class `novel`. Branch topology SINGLE.
Plan approved at the Procedure 0 gate on 2026-06-06 (operator-ratified). This file is the Engineering Commit 0
transcription of the approved Stage 4 plan; the issue and sub-task numbers it cites are listed in the Source
references block at the end.

## Summary (30 seconds)

Single-issue, version-less release delivering a new conversational intake-elicitation skill (`intake-elicitor`)
in the operations module. Class `novel` (trigger (a): introduces a new skill). Branch topology SINGLE — one issue,
one release branch, plan committed as Engineering Commit 0. Stages 5–13 all apply (no SKIPs); Stage 5 Solutioning
is the load-bearing stage because the issue explicitly defers skill modes, technique-library content, MVP type set,
and the work-item-type-system registry-binding mechanism to Stage 5. File-change count is about six paths: one new
skill directory (SKILL.md plus references plus evals), one deploy.sh registration line, one new package, one
intake-style-guide funnel pointer, and one new ADR. Top risks: scope-creep "do-everything elicitor", a soft coupling
to the unshipped work-item-type system, and intake-ownership overlap with project-initiator and ppm-agent. One C2 /
G-PL2 weak-body finding at planning: the issue body's Affected Files names registration "in SKILL_LIST", but that
array was renamed; deploy.sh deprecates SKILL_LIST in favor of per-module arrays (OPERATIONS_SKILLS). That was routed
Tier 1 [ADJUST] as an input correction carried to Stage 5/6 per the intake-substrate-drift discipline — not a body
amendment. Domain-practice: the change matrix is all platform-internal skill artifacts, so the matrix carries the
pipeline-internal exemption; but the skill's elicitation-technique content draws on the external
requirements-elicitation domain, so it was flagged SHIP-WITH-FLAG for Stage 5 to source. No C3 (premise-rejection).

## Stage 4 Planning record

### Phase A0 Re-Review + Currency Gates

Re-review artifact header: release milestone `intake-elicitation-skill` (version-less); stage 4; spoke author Stage 4
Release Planning spoke; re-review date 2026-06-06; issue body revision 2026-06-06T06:57:31Z; triage decision date
2026-06-06 (Stage 2 Triage, APPROVED, P3); effort tier standard (no `size:` label, but scope touches a skill, so
Standard tier is forced; not Complex — single issue, additive blast radius).

Per-requirement re-review verdicts:

- AC1 (proposes correct type plus hierarchy place; re-routes on reclassification; method is at least three worked
  transcripts): Class C1 — survives verbatim. Verifiable-predicate AC with a named method; satisfies the 5-test rule
  test T3. No existing elicitation skill on the roster; prompt-builder is the cited technique-meta precedent.
- AC2 (elicits type/level-specific field set; method is bug/story/initiative transcripts differing): Class C1 —
  survives verbatim. Aligns with applying the 5-test rule live; the issue-template set is the current static-field
  corpus the skill elicits against.
- AC3 (output passes the 5-test rule before logging): Class C1 — survives verbatim. Direct citation of the 5-test
  rule, unchanged at HEAD.
- AC4 (emits a logged item, never a tracked scratch file; method is inspect output contract): Class C1 — survives
  verbatim. The originating session is itself the learning: a scratch draft was committed for lack of a funnel, and
  the AC directly closes that.
- AC5 (MVP covers agreed types; design binds to the type registry so new types need no rewrite; method is read
  output contract plus registry-binding section): Class C2 — refine at Stage 5. The work-item-type system is
  `status: proposed` and OUT of scope; the registry does not yet exist, so the binding is necessarily a design seam
  toward it, not a binding to a shipped artifact. Logged Tier 1 [ADJUST]: AC5's "binds to the type registry" must be
  read as "binds to the current type set with a parameterization seam that the type system will populate later." No
  issue-body rewrite.
- proposed-change / Affected Files (deploy.sh — "register in SKILL_LIST"): Class C2 — currency mismatch. deploy.sh
  records that the former single SKILL_LIST is replaced by per-module arrays and that references should name the
  per-module arrays, not SKILL_LIST. Registration for an operations skill is the OPERATIONS_SKILLS array. The
  Stage-13 close gate Check 5 (skill-roster-drift) asserts the arrays match on-disk dirs, so registration must land
  in OPERATIONS_SKILLS. Routed as a G-PL2 input correction surfaced to Stage 5/6, not a body amendment.

No C3 classification — no requirement rests on a stale premise, subsumption, best-practices conflict, or learnings
contradiction. The unshipped state of the type system is handled as a soft-dep design seam at AC5 (a C2 refinement),
not a C3 premise-rejection: this skill was designed to ship before the type system. Tier 0 Premise Rejection does not
fire.

G-PL1 (AC-currency gate): PASS with one [ADJUST]. ACs 1–4 reconcile against current state verbatim; AC5's
type-registry reference is forward-looking to an unshipped artifact, read at Stage 5 as a parameterization seam
against the current four-type set. No version/path refs in any AC are stale.

G-PL2 (pre-plan crisping gate): G1-02 Description actionable — PASS. G1-04 Proposed Change names files-or-protocols —
PASS-with-[ADJUST]; the named registration surface SKILL_LIST is stale (renamed to per-module arrays); corrected
target is OPERATIONS_SKILLS in deploy.sh, carried as an input correction into the Stage 5/6 work product, not an
issue-body rewrite. G1-05 AC verifiable — PASS; all five ACs are predicates with named verification methods.
G-PL2 verdict: body is crisp enough to plan against; one [ADJUST] routed as input correction; no crisping pre-gate
halt required.

Parallelization-Map currency check: PASS. The milestone description carries a Parallelization Map recorded
2026-06-06 (same-day as this Stage 4 entry): "Runs independently — no hard-block, no soft-couple at release scope;
no release branches as of 2026-06-06." Reconfirmed at A0 entry: open-PR set empty; no release branch exists. Map is
current; no [ADJUST].

### Domain-Practice Provenance Label

Split provenance: the change matrix is pipeline-internal, but the skill's technique content draws on an external
domain. The pipeline-internal exemption applies when the entire File Change Matrix consists of internal pmo-platform
artifacts; that predicate is satisfied for the matrix (new SKILL.md, references, deploy.sh, package, and
intake-style-guide are all platform-internal). However, the substantive content of the new skill — its dynamic,
technique-based elicitation library — is the platform's first encoding of the external requirements-elicitation
discipline (structured interviewing, laddering, the WHAT/HOW boundary as an elicitation technique, type/level
question sets). The platform does not yet encode that domain's best practice (the closest precedent, prompt-builder,
encodes prompt-engineering technique, a different domain). Mode A (pre-known) does not fire — no prior release
authored a requirements-elicitation technique encoding. The honest call was Mode B (SHIP-WITH-FLAG) for the content,
with the matrix exemption noted, keeping the flag visible for Stage 5 where the technique library is authored.

Stage 4 label (UNSOURCED-DOMAIN, SHIP-WITH-FLAG): change matrix is pipeline-internal (skill artifacts only), so the
matrix exemption applies; but the skill's elicitation-technique-library content is the platform's first encoding of
the external requirements-elicitation domain. Stage 5 Solutioning sources an authoritative elicitation reference when
authoring the technique library; Stage 7 Dev Testing verifies the dated flag is present.

Stage 5 upgrade (recorded in the Deviation Log below): upgraded to Mode A (sourced to IIBA BABOK Guide v3).

### Dependency Graph

Single node — no intra-release dependency edges. Soft external dependencies (OUT of scope, both `status: proposed`,
not in this milestone): the work-item-type system (soft — this skill ships an 80/20 MVP against the current four
work-item types and deepens as the type system lands; it does not block on it; the type system later populates the
parameterization seam this skill designs); and the idea-refinement-surface issue (soft, scope-overlap — this skill
carries the elicitation half; the other issue is expected to narrow to the commit guardrail; reconciliation is a
Triage concern, no Stage-4 action). A one-node graph needs no diagram.

### Implementation Sequence

Single issue, trivial sequence: all applicable stages (5 → 6 → 7 → 8 → 9 → 12 → 13) run in pipeline order for the
one issue. Within Stage 6 Engineering, the natural file order is: (1) author the SKILL.md plus references; (2)
register in OPERATIONS_SKILLS; (3) build the package; (4) update intake-style-guide to point intake at the skill as
the funnel; plus the ADR authored alongside the implementation.

### Stage Applicability Matrix

All of Stages 5–13 apply; zero SKIPs.

- Stage 5 Solutioning — APPLY (load-bearing). The issue explicitly defers skill modes, technique-library content, MVP
  type set, and the registry-binding mechanism to Stage 5. The `novel` class sets Stage-5 activation bias to ALL.
- Stage 6 Engineering — APPLY. Authors the new skill, registers it, builds the package, updates the funnel doc. The
  only stage that mutates files.
- Stage 7 Dev Testing — APPLY. A new skill carries a functional surface. DT exercises the elicitation loop against at
  least three entry-altitude transcripts and verifies the output contract emits a logged item, never a scratch file;
  also verifies the domain-practice flag is present and dated.
- Stage 8 QA Testing — APPLY. Independent verification of the five ACs plus Principal Standard plus the
  failure-mode standard (at least three domain-specific failure modes required for any skill).
- Stage 9 Plan Review — APPLY (Deep). `novel` sets Stage 9 review depth to Deep (blast-radius plus design-spec
  conformance plus Empirical Verification). GO/NO-GO is an operator gate.
- Stage 12 Execute — APPLY. Deploys the skill, rebuilds the package, runs deploy.sh --check (Check 5 roster-drift,
  Check 7 package-freshness, Check 12 mirror-sync). Operator gate.
- Stage 13 Close — APPLY (30-day window). Release-corpus close (RELEASE_LOG/INDEX/DIGEST rows) plus Documentation
  Impact resolution (Check 28). `novel` sets a 30-day outcome window. The issue is marked closed at Stage 13.

Note on Stages 10/11: deploy-and-verify activities for a skill release fold into Stage 12 Execute; the Stage 10
(Dry Run) and Stage 11 (Snapshot) specs exist and are reconciled at scaffolding rather than dismissed as absent.

### File Change Matrix

| Path | Intent | Notes / grounding |
|---|---|---|
| `operations/skills/intake-elicitor/SKILL.md` | ADD | The skill definition: elicitation loop plus technique library plus per-type/level field maps. Frontmatter `name` plus `description` (upstream minimum) plus `version` plus `license`; no migration marker at birth. At least three domain-specific failure modes (five authored) plus Principal Standard checklist. |
| `operations/skills/intake-elicitor/references/elicitation-loop.md` | ADD | The four-phase loop plus the altitude model plus the type/hierarchy re-routing rule plus the 5-test rule applied live. |
| `operations/skills/intake-elicitor/references/type-map.md` | ADD | The type-registry seam — current four-type set, intake hierarchy, per-type/level required-field map keyed to the issue templates. The single file the type system later repoints. |
| `operations/skills/intake-elicitor/references/technique-library.md` | ADD | BABOK technique cards adapted to a single-user, async, agent-mediated context plus a when-to-apply selector. |
| `operations/skills/intake-elicitor/references/output-contract.md` | ADD | The emission contract — confirm-before-emit gate, the gh-issue-create mechanics with the dropdown-to-label map, the Severity-in-body convention, the Observation-tier fallback, the no-gh fallback, and the never-a-tracked-scratch-file invariant. |
| `operations/skills/intake-elicitor/evals/evals.json` | ADD | At least three entry-altitude worked transcripts (bug/story/initiative) plus a Mode B 5-test case plus at least two negative-trigger guards vs file-router and ppm-agent. Drives Stage 7/8. |
| `core/deploy/deploy.sh` | EDIT | Register `intake-elicitor` in the OPERATIONS_SKILLS array (alphabetical, between file-router and pmo-process-designer) — NOT SKILL_LIST (deprecated). This corrects the issue body's stale "register in SKILL_LIST" reference. Check 5 (roster-drift) then reconciles the array against the new on-disk dir. |
| `packages/intake-elicitor.skill` | ADD | Build the package via the repo packaging tool. License injected at build. Check 7 (package-freshness) is release-blocking. |
| `core/ADRs/ADR-016-intake-elicitor-type-registry-seam.md` | ADD | The type-registry parameterization seam ADR (forward-coupled to the work-item type system). Authored as a file alongside the implementation. |
| `release/references/how-to/intake-style-guide.md` | EDIT | Name `intake-elicitor` as the intake funnel — one link-free durable-prose sentence (the file has no allow-link marker). Preserve the 5-test rule and existing structure. |

OPERATIONS.md funnel pointer is DEFERRED (not in MVP): the issue says intake-style-guide "and/or" OPERATIONS.md, and
the style guide alone satisfies the AC. The OPERATIONS.md pointer touches a byte-identical mirror pair (Check 9), so
it is held as a clean follow-up rather than doubling blast radius for marginal benefit.

### Contention Map

Within-release contention: NONE. Single issue — no two change-specs claim the same file.

Cross-PR Overlap Audit baseline: audit-baseline date 2026-06-06; baseline population zero open PRs (verified empty);
last-merged anchor `main` at commit `2fa2240`; no release branch exists. Result: zero cross-PR contention at
baseline; none of the change-matrix paths is touched by any open or in-flight PR. This is not an audit milestone, so
the empty-population audit-baseline policy does not force an empty-population D-decision here; nonetheless the
empty-set finding is anchored to SHA `2fa2240` / 2026-06-06 and was re-checked at Engineering Commit 0 (re-check
verdict in the Deviation Log). Re-check trigger: if any release branch or PR touching the matrix paths appears before
Stage 12, re-run the audit.

### Risk Register

| # | Risk | Likelihood / Impact | Mitigation | Owner | Reversibility |
|---|---|---|---|---|---|
| R1 | Scope-creep — "do-everything elicitor." The technique library plus type coverage balloon beyond an MVP. | Med / High | 80/20 MVP — Stage 5 fixes the agreed highest-frequency type set (against the current four types) and a bounded technique library; coverage grows incrementally post-ship. Stage 9 Deep review checks the MVP boundary held. | Stage 5 Solutioning plus operator at Stage 9 | CHEAP |
| R2 | Soft coupling to the unshipped type system. The skill designs a parameterization seam toward a type registry that is proposed and unshipped. | Med / Med | Bind the MVP to the current four-type set with a documented seam, not to the unshipped registry (AC5 [ADJUST]). Stage 5 verifies the type-system state at session entry, designs against today's substrate, surfaces any drift as input correction. | Stage 5 Solutioning | CHEAP |
| R3 | Intake-ownership overlap with project-initiator / ppm-agent. The elicitor's "front door that produces typed work items" could blur ownership. | Med / Med | Stage 5 delineates ownership explicitly: the elicitor produces a typed work item (front-door); ppm-agent processes existing artifacts; project-initiator scaffolds/closes projects. Distinct verbs, distinct trigger sets. Stage 5 runs a cross-skill trigger-collision check so the new triggers do not poach ppm-agent's processing surface. | Stage 5 Solutioning plus Stage 8 QA | CHEAP |
| R4 | Rollback complexity. | Low / Low | New skill is purely additive — a new directory, one array line, one new package, one funnel-pointer edit. No existing skill or governance contract is modified destructively. Rollback = revert the PR plus deploy clean-up plus remove the array line. | Stage 12 Execute / Stage 13 | CHEAP |
| R5 | Stale registration target (SKILL_LIST). The issue body points registration at a renamed array. | Realized / Low | Corrected in the File Change Matrix: register in OPERATIONS_SKILLS. Carried as Stage 5/6 input correction (not a body amendment). Check 5 roster-drift catches any miss at deploy. | Stage 6 Engineering | CHEAP |
| R6 | Unsourced elicitation-technique domain. The technique library is the platform's first encoding of the requirements-elicitation domain; shipping it un-sourced risks ad-hoc technique quality. | Med / Med | SHIP-WITH-FLAG at Stage 4; Stage 5 sources an authoritative elicitation reference (done — IIBA BABOK Guide v3) and upgrades the label to Mode A; Stage 7 verifies the dated flag; Stage 9 surfaces it. | Stage 5 Solutioning | CHEAP |

### Operator Decisions (ratified)

D-ReleaseClass: `novel` (ratified). Trigger (a) fires unambiguously — at least one issue introduces a new skill. No
`routine` trigger holds (a new file is added; design uncertainty is surfaced and deferred to Stage 5).
`cross-cutting` does not fire (matrix touches zero pipeline-stage files and at most one governance file, far below the
threshold of three). `hotfix` does not fire (no P1/P2 defect against a deployed release). Differentiation posture:
engagement density Standard / Stage 9 Deep / Stage 5 activation bias ALL / Stage 13 outcome-window 30-day.
Reversibility CHEAP / Confidence HIGH.

D-C Branch Topology: SINGLE (ratified). One issue, so no per-issue-PR parallelism benefit from OPTION-A; SINGLE is the
default; the plan commits as Engineering Commit 0 on the release branch; all applicable stages commit to that one
branch. Upstream-compatibility check (required because the release creates a skill): the skill-creator convention is
`name` plus `description` only, and the directory layout is SKILL.md plus optional references plus optional evals
(confirmed against the in-repo precedent prompt-builder); the PMO `version` field is a documented extension to the
upstream minimum, applied identically regardless of topology — an extension, not a conflict. Reversibility CHEAP /
Confidence HIGH.

### Delivery Strategy / Verification Plan / Rollback Strategy

Delivery Strategy (SINGLE): one release branch off `main`; the Stage 4 plan committed as Engineering Commit 0 by the
first Stage 6 Engineering spoke; all applicable stages commit sequentially to that branch; worktree discipline (the
Engineering spoke operates in its session worktree directly, no nested worktree; detach at session end to release the
branch lock). Stage 12 deploys via deploy.sh --deploy plus a mandatory package rebuild plus deploy.sh --check
(Checks 5/7/12). Stage 13 lands the release-corpus rows and resolves Documentation Impact (Check 28); the issue is
marked closed at Stage 13. Version-less: no version tag; the platform `.version` stays `v3.19`.

Verification Plan: AC-driven (Stage 7/8) — worked transcripts for at least three entry altitudes each yield a
correctly-typed item with correct hierarchy placement plus a re-route on reclassification (AC1); the three
transcripts capture different field sets (bug → reproduction/environment; story → AC/value; initiative →
outcomes/domain) (AC2); sampled output passes the 5-test rule before logging (AC3); the output contract emits a
logged item, never a tracked scratch file (AC4); the output contract plus registry-binding section show the MVP
covers the agreed types and binds to the current type set via a parameterization seam with no skill rewrite needed
for new types (AC5). Skill-quality gates: Principal Standard checklist plus at least three domain-specific failure
modes (five authored) plus a cross-skill trigger-collision check vs ppm-agent and file-router. Deploy-time (Stage
12): Check 5 (roster-drift), Check 7 (package-freshness), Check 12 (user-local mirror sync), Check 6
(canonical-structure plus version-field present/format). Flag verification: Stage 7 confirms the domain-practice
label is present, dated, and Mode A with a citation.

Rollback Strategy: reversibility tier CHEAP (additive new skill — no destructive change to any existing skill or
governance contract). Mechanism: revert the release PR (single-PR revert restores prior state) → removes the new
skill dir, the OPERATIONS_SKILLS array line, the package, and the funnel-pointer edits; then deploy.sh --deploy
reconciles the runtime mirror (Check 12 confirms removal); worktree prune if a lock lingers. No data migration, no
downstream consumer to unwind, no schema change. Operator-authorized per the release rollback protocol.

## Change Description

Outcome: the platform gains a conversational intake front door — a skill that meets an idea at any altitude, identifies
the correct work-item type and its place in the intake hierarchy, elicits the type- and level-appropriate fields,
applies the 5-test rule live, and emits a well-formed, correctly-typed work item to the GitHub Issue tracker (never a
scratch file). Before this release, intake was cold form-filling against fixed templates with no funnel, which had
already produced an improvised scratch file committed in the wrong place. After this release, the funnel exists and
the style guide names it.

Issues resolved: the conversational intake-elicitation skill issue is implemented by this release. It is marked closed
at Stage 13 (not at this PR's merge), so the ordered close-out is preserved.

Key decisions: a single new operations skill named `intake-elicitor`; two modes (Elicit and Triage-readiness check);
MVP bound to the current four work-item types via a `references/type-map.md` registry seam (the type system later
repoints the table with no SKILL.md rewrite); emission via `gh issue create` after a confirm gate, with a dropdown-to-
label map plus a Severity-in-body convention plus an Observation-tier fallback for fields that cannot be represented;
the elicitation technique content sourced to IIBA BABOK Guide v3 (upgrading the domain-practice label from
SHIP-WITH-FLAG to Mode A); one ADR records the type-registry seam mechanism.

Reversibility: CHEAP / Confidence HIGH — additive new skill; single-PR revert restores prior state.

Downstream impact: the deployed runtime skill roster gains one member; the package count gains one; intake-authoring
agents gain a named live-elicitation front door in the style guide. No schema change, no tracker-schema change, no
existing skill modified destructively.

Cross-references: see the Source references block below for the issue, sub-task, plan, design, and ADR numbers.

## Deviation Log

- Domain-practice label upgraded SHIP-WITH-FLAG (Stage 4, UNSOURCED-DOMAIN) → Mode A (Stage 5), sourced to IIBA BABOK
  Guide v3 — Elicitation and Collaboration knowledge area (Prepare / Conduct / Confirm), the Techniques chapter
  (interviews, workshops, observation, document analysis), and the Requirements Classification Schema (business /
  stakeholder / solution / transition requirement levels). This is the platform's first encoding of the
  requirements-elicitation domain; the BABOK admission to the K1 methodology corpus (beyond this skill's local use)
  is a separate governance act, flagged as a clean follow-up, not required for this skill to ship sourced.
- Cross-PR baseline re-checked at Engineering Commit 0 (2026-06-06): open-PR set empty; no release branch existed
  prior to this one; `main` unchanged at `2fa2240`. Zero cross-PR contention confirmed; the Stage 4 baseline holds.
- Two Stage 5 scope-lock conditions applied at Stage 6 (both land in Stage-6-authored files): (1) the output contract
  specifies the dropdown-to-label map, a Severity-in-body convention, and the Observation-tier fallback, and a fifth
  failure mode (emit-incomplete-typed-item, OUT) was authored; (2) the trigger string anchors every authoring verb to
  a work-item noun (the "help me file this" phrase is noun-anchored so it does not collide with file-router), and at
  least two negative-trigger eval guards were added.
- ADR authored as a file (ADR-016) alongside the implementation rather than filed as a separate backlog issue,
  consistent with the existing core ADR convention.

## Source references

This block is the single designated home for issue, sub-task, PR, and ADR identifiers cited by this plan. No other
section embeds a bare issue number.

- Issue (the conversational intake-elicitation skill): #412
- Sub-task — Stage 4 Release Planning (approved plan): #414
- Sub-task — Stage 5 Solutioning (accepted design plus scope-lock): #417
- Sub-task — Stage 6 Engineering (this implementation): #418
- Milestone: intake-elicitation-skill (#109)
- Soft external dependency — work-item type system (proposed, out of scope): #409
- Soft external dependency — idea-refinement surface (proposed, out of scope): #411
- ADR — type-registry parameterization seam: ADR-016
- Baseline anchor commit: 2fa2240
