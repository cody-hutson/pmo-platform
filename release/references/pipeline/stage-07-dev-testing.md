<!-- reference-durability: allow-link -->
# Stage 7: Dev Testing

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
Independent quality review of implemented changes — the Layer 2 automated review that catches what Engineering's self-review misses. Produces a scored quality report with findings for human review, NOT auto-correction. Key principle: the reviewer must not be the author. Dev Testing runs with fresh context — not the implementing agent's conversation.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Developer-level testing; unit and integration verification | Independent quality review of PR content against AC and platform standards |
| Governance Focus | Test coverage, defect tracking | Quality scoring, escape detection, eval set results |
| Artifact Inputs | Source code, unit tests, build artifacts | PR with committed changes, verification plan, Engineering self-verification evidence |
| Artifact Outputs | Test results, defect reports, coverage metrics | Quality review report with LLM-graded assessment, eval set results, escape detection |

Key compression: Ref Model assumes automated test suites, CI pipelines, and runtime environments. Our platform is documentation and governance — "testing" = content quality review + structural validation + contract verification. The independent reviewer replaces the peer code reviewer of traditional software engineering.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 (accepts/rejects findings) |
| Quality reviewer (primary): QA Auditor Skill 11 | Single-output review, evidence audit | Mode 1, Mode 3 | Tier 1/2 split |
| Standards checker (secondary): Principal Eng Skill 9 | Implementation & Code Quality | Mode 3 (Tech Lead) | Tier 1 (Auto) |

Author-reviewer separation: Current state = fresh conversation session. Future state = eval scripts per the canonical eval-type taxonomy. Anti-pattern: running Dev Testing in the same session as Engineering.

## 4. Inputs
From Engineering: PR with committed changes, sub-task completion status, self-verification evidence, deviation log.
From Planning: release plan (verification plan, AC per issue, file change matrix).
From Solutioning (when activated): design specs, ADR decisions.
From QA (return path, when applicable): QA Return to Dev Testing payload per [DT↔QA Handoff Protocol](#dtqa-handoff-protocol) — triggers Pass N+1 full re-review.
Contextual: `core/rules/`, `principal-standard-checklist.md`, `regression-checks.md`, `grader.md`.

Set at Stage 7: quality review scores (1-5 per dimension), finding list with severity, escape rate, overall verdict (PASS/CONDITIONAL PASS/FAIL).

## 5. Process
**Phase A — Structural Review (Tier 1 Auto):** 7 deterministic checks — PR completeness (Blocker), layer boundary (Blocker), deployed copy sync (Blocker), sub-task completion (Warning), regression check (Warning), **deprecated-path scan for new-file deliverables (Blocker, conditional)**, **domain-practice provenance verification (Warning, conditional — per § Domain-Practice Provenance Verification Step below)**.

**Deprecated-path scan for new-file deliverables (Source: deprecated-path scan spec):** For each new file in the PR scope, execute a deterministic grep scan against the release's `Files Removed` list. The list is sourced from the release plan's explicit `Files Removed` section when present; otherwise derive via `git diff main..release/<milestone> --diff-filter=D --name-only`. For each match, classify as Tier 1 (Engineering re-author via `fix(dt):` commit per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol)) by default. **Exception:** matches where the PR body explicitly documents the reference as "intentional documentary reference to deprecated path with paired new-path fallback" are downgraded to Note severity (no routing). Tier escalation to Tier 2 (Scope Change) when re-author requires design revision; Tier 3 (Plan Rejection) when the removed path was load-bearing on the new file's premise.

**Cutover discipline:** Applies to all releases going forward.

**Domain-Practice Provenance Verification Step:** Phase A asserts that the release plan file (`release/releases/plans/v<X.Y>_RELEASE_PLAN.md`) carries a `domain_practice` provenance label authored by the Stage 4 Planning spoke's Domain-Best-Practice Sourcing-or-Flag Step. The label is verified for:

1. **Presence:** the release plan must contain a single-line `domain_practice:` label (within the `### Release Class declaration` H3 or a sibling `### Domain Practice Provenance` H3, per the Stage 4 placement convention).
2. **`date` field populated:** the label's `date` field must be a `YYYY-MM-DD` value (mandatory in BOTH Mode A and Mode B, so staleness is detectable).
3. **`source` field present:** one of three legitimate forms:
   - Mode A — a citation URL or repo-relative path
   - Mode B — the literal token `UNSOURCED-DOMAIN` paired with a `rationale` sub-field
   - Software / governance / pipeline-internal exemption — the literal token `N/A — pipeline-internal release`, per the Stage 4 pipeline-internal exemption

**Verification command:**
```bash
grep -nE "^[[:space:]]*domain_practice:" release/releases/plans/v<X.Y>_RELEASE_PLAN.md
```

**Failure classification:**

| Finding | Severity | Routing |
|---|---|---|
| Label absent | Warning | Tier 1 — Engineering adds the label via `fix(dt):` commit; flags the domain-detection follow-up if the auto-detection mechanism is the gap |
| Label present, `date` field missing or malformed | Warning | Tier 1 — Engineering refreshes the label via `fix(dt):` commit |
| Label present, Mode B `UNSOURCED-DOMAIN` with no `rationale` sub-field | Warning | Tier 1 — Engineering adds rationale via `fix(dt):` commit |
| Label present, Mode B `UNSOURCED-DOMAIN` with rationale — but rationale does not name the unresolved domain | Note | Logged; no routing (the explicit UNSOURCED-DOMAIN flag with any rationale satisfies the disclosure obligation) |

**Phase B — Contract Review (Tier 1/2):** 3 checks — AC verification per issue (LLM-graded, Blocker), stage input consumption (LLM-graded, Warning), stage output completeness (Deterministic, Warning).

**Phase C — Content Quality Review (Tier 2 Recommend):** 5 scored dimensions — clarity (1-5, threshold 3), accuracy (1-5, threshold 3), internal consistency (1-5, threshold 4, Blocker), convention depth (1-5, threshold 3), escape detection (count).

**Phase D — Report Assembly (Tier 1 Auto):** Compile findings, classify (Blocker/Warning/Note), calculate escape rate, render verdict: PASS (no blockers, all ≥ threshold) / CONDITIONAL PASS (no blockers, 1-2 below) / FAIL (any blocker).

**Phase E — Human Review + Iteration Routing (Tier 3):** Review findings, accept or override with rationale. Route per verdict: PASS/CONDITIONAL PASS → advance to Stage 8. FAIL with Tier 1 findings → return to Engineering per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol); Engineering fixes via Phase E, DT re-enters at targeted re-review scope. FAIL with Tier 2/3 findings → escalate to operator per inter-stage feedback protocol. On Pass 2+, DT executes targeted re-review (per iteration protocol), then re-enters Phase D for updated verdict before returning to Phase E.

**Ticket lifecycle:** Claim: set Stage→7-DevTesting. Execute: Pass 1 = A-E. Pass 2+ = targeted re-review per iteration protocol → D → E. Resolve: post quality report (with iteration history if applicable), route per final verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Tracking (handoff payload format); Handoff (DT↔QA protocol). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Quality Review Report: section scores, finding list with severity and routing tier classification, escape rate, overall verdict. Report terminates with the structured Handoff Payload per [DT↔QA Handoff Protocol §Forward Handoff](#dtqa-handoff-protocol) — this is Stage 8's authoritative input. Downstream: PASS/CONDITIONAL PASS → to Stage 8 (quality report + PR). FAIL with Tier 1 findings → classified finding list to Engineering for iteration (per [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol)). FAIL with Tier 2/3 findings → escalation package to operator. Pass 2+ reports: appended "Iteration N" section with re-verification results and updated verdict. On QA return path: DT emits Return-to-QA Verified signal per [DT↔QA Handoff Protocol §Return Path](#dtqa-handoff-protocol) after confirming fix.

Stage 7 does NOT produce: design decisions (Stage 5), acceptance verdicts (Stage 8), deployment actions (Stage 12). Stage 7 does NOT fix findings — it classifies and routes them.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all files reviewed, all AC checked, no unresolved Blockers, quality scores ≥ threshold (or override documented), escape rate logged, report posted.
Judgment (1-5): review thoroughness, finding quality, independence (escape count > 0 expected), report clarity.
Calibration: precision tracking, escape-to-QA rate, time-to-complete. Threshold adjustment after 3+ releases.

## 8. Automation Level
Overall Tier 1/2 mix. Structural checks (A1-A5) automatable now (deterministic). Content quality (C1-C4) requires LLM grading. Human decision stays Tier 3. Leverages existing infrastructure: `principal-standard-checklist.md`, `regression-checks.md`, `grader.md`, `run_eval.py`.

## 9. Gap Summary
6 gaps. Key: no eval runner for quality assertions (P2), no dedicated Dev Testing skill mode (P2), fresh-context separation not enforceable (P3).

## 10. Retro
To be populated after execution.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `dt-pass` / `dt-conditional-pass` / `dt-return` | DT verdict rendered at end of Phase A review; ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` | `spoke:#N` (DT spoke) |
| `iteration` | `dt-eng-pass-N` | DT↔Eng iteration counter post-increment per DT↔Engineering Iteration Loop Protocol below; ALSO captured in `iteration-log.md` — payload carries `projects_to: iteration-log.md:<row-anchor>` | `hub` |
| `scope-change` | `tier-1-adjust` | Escape detected during deprecated-path scan or AC re-check; routed as Tier 1 finding to Engineering for `fix(dt):` commit | `spoke:#N` |

Cutover discipline: Applies to all releases going forward — this stage emits these events for any release at Stage 7.

## DT↔Engineering Iteration Loop Protocol

This protocol instantiates the general [Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol) for the Stage 6 (Engineering) ↔ Stage 7 (Dev Testing) boundary. It defines how DT findings route back to Engineering, how Engineering responds, and how DT re-reviews — iterating until the quality gate passes or escalation triggers.

### Loop Flow

```
Pass 1: DT full review (Phases A–D) → Quality Review Report
  ↓
Finding classification → route per severity and scope
  ↓
┌─ Tier 1 findings (Minor Adjustment) → Engineering fixes on release branch
│   Engineering commits with fix(dt): convention, [ADJUST] tag per the inter-stage feedback protocol
│   ↓
│   Pass 2+: DT targeted re-review (affected assertions + regression)
│   ↓
│   Clean → advance to Stage 8
│   New findings → re-classify and loop
│
├─ Tier 2 findings (Scope Change) → escalate to operator
│   [SCOPE CHANGE] signal per the inter-stage feedback protocol
│   Operator decides: adjust plan or proceed with deviation documented
│
└─ Tier 3 findings (Plan Rejection) → escalate to operator
    [PLAN REJECTION] signal per the inter-stage feedback protocol
    Operator re-runs upstream stage for affected issue(s)
```

### Finding Classification

DT classifies each finding by severity (Blocker/Warning/Note per Phase D) AND by routing tier:

| Finding Severity | Routing | Feedback Tier | Action |
|---|---|---|---|
| Blocker — fixable within scope | Engineering | Tier 1 (Minor Adjustment) | Engineering fixes, DT re-reviews |
| Blocker — requires scope change | Operator | Tier 2 (Scope Change) | Operator decides adjustment |
| Blocker — plan fundamentally unworkable | Operator | Tier 3 (Plan Rejection) | Operator returns to upstream stage |
| Warning — fixable within scope | Engineering | Tier 1 (Minor Adjustment) | Engineering fixes, DT re-reviews |
| Warning — requires judgment call | Operator | Tier 2 (Scope Change) | Operator decides accept or fix |
| Note | Logged | — | No action required; tracked for calibration |

**Classification rule:** "Fixable within scope" = the fix does not change acceptance criteria, does not require new files outside the change matrix, and does not alter the design approach. When uncertain, classify as Tier 2 (over-escalate per the inter-stage feedback protocol escalation rule).

### Targeted Re-Review (Pass 2+)

After Engineering commits fixes, DT runs a targeted re-review — not a full re-run:

| Scope | What re-runs | What does NOT re-run |
|---|---|---|
| Fixed findings | Re-verify specific assertions that failed in prior pass | Assertions that passed and were not in the blast radius of fixes |
| Regression | Re-run structural checks (Phase A) that could be affected by new commits | Phase C scoring on unchanged content |
| New scope | If Engineering fix touched files not in the original finding, extend review to those files | Full Phase A–D on the entire PR |

**Pass 2+ report format:** Appended section in the Quality Review Report — "Iteration N" with: findings addressed, re-verification results, new findings (if any), updated verdict.

### Escalation Threshold

If the DT↔Engineering loop exceeds **3 iterations** (Pass 1 + 2 re-reviews) without reaching PASS or CONDITIONAL PASS:

1. DT stops the loop and escalates to the operator with `[ESCALATION: ITERATION LIMIT]` signal.
2. Escalation package includes: iteration history (findings per pass, fixes per pass, persistence pattern), hypothesis on root cause (upstream spec issue, systemic quality gap, or DT calibration drift).
3. Operator triages: (a) return to Planning/Solutioning for the affected issue(s), (b) override DT findings with documented rationale, (c) adjust DT thresholds if calibration drift is confirmed.

**Rationale:** 3 iterations is the threshold — not a hard cap. The operator may authorize additional iterations if the convergence trend is positive (finding count decreasing). The threshold exists to surface issues that indicate upstream problems rather than Engineering-fixable defects.

### Engineering Commit Convention for DT Fixes

| Element | Convention |
|---|---|
| Prefix | `fix(dt):` |
| Description | Specific fix, not generic ("correct evidence label on Stage 4 AC" not "fix DT findings") |
| Issue reference | `(#N)` for the parent issue the finding relates to |
| Signal tag | [ADJUST] per the inter-stage feedback protocol Tier 1 |
| Example | `fix(dt): correct evidence label on Stage 4 AC [ADJUST]` |

Engineering MAY batch multiple Tier 1 fixes into a single commit when they address the same finding category. Each batch commit lists all findings addressed.

### Iteration Tracking

| Metric | Where Tracked | Purpose |
|---|---|---|
| Iteration count per release | Quality Review Report, Iteration N sections | Calibration: high counts signal upstream quality issues |
| Per-finding lifecycle | Quality Review Report (found → routed → fixed → re-verified) | Traceability: every finding has a resolution |
| Findings by tier per pass | Quality Review Report summary | Pattern detection: persistent Tier 2+ findings signal design gaps |
| Cumulative iteration data | [calibration-data.md](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md) | Cross-release calibration: iteration trends inform threshold adjustment |

### Automation Trajectory

| Aspect | Current State | Target State |
|---|---|---|
| DT pass execution | Conversation-based, operator triggers DT session | Eval runner auto-executes (per the canonical eval-type taxonomy) |
| Finding classification | LLM-graded during report assembly | Rule-based for structural, LLM for content |
| Engineering fix routing | Operator relays findings to Engineering session | Agent-to-agent handoff with structured finding payload |
| Re-review trigger | Operator triggers DT re-review session | Auto-triggered on `fix(dt):` commit detection |
| Escalation | Operator monitors iteration count | Auto-escalation at threshold with structured package |

## DT↔QA Handoff Protocol

This protocol defines the paired handoff formats at the Stage 7 (Dev Testing) ↔ Stage 8 (QA Testing) boundary:
- **Forward handoff:** Stage 7 → Stage 8 — the structured quality-report payload Stage 8 consumes as Phase A input.
- **Return path:** Stage 8 → Stage 7 — the QA-initiated iteration variant when Phase C Lane 2 findings require DT re-review before Engineering fix.

Both formats are human-readable (markdown) AND machine-parseable (stable headings, fixed-schema tables, ID-keyed findings). This supports current operator review and the future skill-chain automation trajectory.

Relationship to other protocols:
- Instantiates the general [Inter-Stage Feedback Protocol](../../governance/release-process.md#inter-stage-feedback-protocol) at the DT↔QA boundary.
- Composes with the [DT↔Engineering Iteration Loop Protocol](#dtengineering-iteration-loop-protocol) — the return path enters that loop as its QA-initiated variant.
- Preserves the layered review model: QA findings re-enter the quality layer (Stage 7) before reaching the fix layer (Stage 6); QA does not route directly to Engineering.

### Forward Handoff: Stage 7 → Stage 8

Stage 7's terminal report section is the **Handoff Payload** — a structured block at the end of the Quality Review Report under the exact H3 heading `### Output for Stage 8`. Stage 8 Phase A Entry Validation extracts required fields from this section; it is the authoritative interface between the stages.

#### Required fields

| Field | Type | Source | Purpose (for Stage 8) |
|---|---|---|---|
| Verdict | Enum: `PASS` / `CONDITIONAL PASS` / `FAIL` | Phase D | Phase A entry gate (only `PASS` / `CONDITIONAL PASS` advance) |
| Iteration count | Integer ≥ 0 | Iteration history | Calibration + escape analysis |
| PR reference | SHA or `#N` or branch @ SHA | Branch state | Confirms PR still mergeable |
| Files reviewed | List of repo-relative paths (with line ranges when scoped) | Phase A1 | Scope anchor for acceptance review |
| AC map | Table: `AC · Issue # · Verdict (PASS / PARTIAL / NOT VERIFIED) · Evidence` | Phase B | Primary input for Phase B acceptance review |
| Findings | Table: `F-ID · Severity · Dimension · Routing tier · Origin · Status · Evidence · Recommendation` | Phase D | Context for Phase B and escape detection |
| Escape summary | Table: `Origin stage · Count` | Phase D | Stage 7 escape count + calibration |
| Downstream attention | List of F-IDs flagged for Stage 8 scrutiny (may be `None`) | Phase E | Focuses Stage 8 review |
| Cross-issue notes | Markdown bullets (may be `None`) | Phase E | Release-level context |

#### Format conventions

| Convention | Rule | Rationale |
|---|---|---|
| Heading anchor | Section heading is exactly `### Output for Stage 8` | Stable parse anchor |
| Verdict line | First non-heading line: `**Verdict:** <enum> — <one-line rationale>` | Deterministic top-line extraction |
| Table schemas | Column order and header text exactly as specified above | Consistent extraction across releases |
| Finding IDs | `F-NN` (zero-padded preferred, `F-N` acceptable) | Stable cross-iteration reference |
| Evidence citations | Inline code for paths/commands, markdown link for URLs | Separates reference from narrative |
| Enum values | Exact casing from schema — no synonyms | Deterministic enum parse |
| Severity vocabulary | `Blocker` / `Major` / `Minor` / `Cosmetic` / `Informational` | Matches persona and the routing protocol |
| Routing tier values | `Tier 1` / `Tier 2` / `Tier 3` / `—` (Notes) | Per the inter-stage feedback protocol and the iteration-loop classification |
| Origin stage | `S4` / `S5` / `S6` / `S7 (pass N)` / `S8 (return)` | Enables escape provenance |

**Severity vocabulary reconciliation (Phase D ↔ Findings table):** Phase D's `Blocker / Warning / Note` are verdict-severity buckets (3-bucket) used to render the overall pass/fail verdict. The Findings-table `Severity` column reports finding-level severity using the 5-bucket vocabulary (`Blocker / Major / Minor / Cosmetic / Informational`). DT skills emitting findings into the Handoff Payload MUST translate at report-assembly time as follows:

| Phase D verdict bucket | Findings-table severity | Rule |
|---|---|---|
| Blocker | Blocker | 1:1 — verdict-blocking findings remain Blockers in the Findings table |
| Warning | Major OR Minor | Judgment call at report assembly — Major when the warning names a specific quality defect with remediation, Minor when it is a convention or clarity observation |
| Note | Cosmetic OR Informational | Cosmetic for presentation/style observations, Informational for context-only notes that carry no remediation expectation |

Phase D's verdict line continues to use the 3-bucket vocabulary; only the Findings table uses the 5-bucket vocabulary. A report with `Blocker/Warning/Note` in its Findings `Severity` column fails parse validation — DT must translate before emitting.

#### Example (abbreviated)

```markdown
### Output for Stage 8

**Verdict:** PASS — no blockers, all AC met, all quality scores at or above threshold.

**Iteration count:** 0 (Pass 1 only)
**PR reference:** release/vX.Y-<capability-slug> @ <SHA>
**Files reviewed:**
- release/governance/release-process.md (lines 27-51)
- release/governance/release-process.md (mirror)

**AC map:**
| AC | Verdict | Evidence |
|---|---|---|
| AC1 | PASS | §Inter-Stage Feedback Protocol, lines 27-51 |
| AC2 | PASS | Tier 1/2/3 definitions, lines 43-59 |
| AC3 | PASS | Signal tags `[ADJUST]` / `[SCOPE CHANGE]` / `[PLAN REJECTION]` |
| AC4 | PASS | Boundary generalization paragraph |

**Findings:**
| F-ID | Severity | Dimension | Tier | Origin | Status | Evidence | Recommendation |
|---|---|---|---|---|---|---|---|
| F-01 | Cosmetic | Convention depth | — | S6 | Open | Tier 3 parenthetical names Planning/Solutioning | Accept as-is; generalization paragraph mitigates |
| F-02 | Informational | Escape detection | — | S6 | Open | New signal tags — first platform use | Accept; first real-world usage will validate |

**Escape summary:**
| Origin | Count |
|---|---|
| S4 | 0 |
| S5 | 0 |
| S6 | 0 |

**Downstream attention:** None — all findings are Cosmetic / Informational.

**Cross-issue notes:** the DT-Eng iteration loop will specialize this protocol at DT↔Engineering; no blocking dependency.
```

#### Parse contract

Stage 8 Phase A treats `### Output for Stage 8` as the authoritative input. Any claim not present in this section must be reconstructed from the full report narrative — the handoff payload is the single source of truth for the stage boundary. When Phase A cannot extract a required field, the entry gate fails and Stage 8 posts a [ADJUST] signal per the inter-stage feedback protocol Tier 1 requesting an amended handoff; DT amends in-place (no full re-review required for format-only corrections).

#### Validation against empirical output

This format codifies the established convention — closed Stage 7 reports consistently produce Summary / Detail / Evidence / Decisions & Recommendations / Output for Stage 8 sections, with `Verdict:` as the lead of the Output block and findings with F-IDs, severity, and recommendations. This protocol formalizes that shape and adds the missing `Routing tier` and `Origin` columns to the findings table, plus the explicit `AC map` and `Escape summary` tables. Retrofit of prior reports is not required; the contract binds from this protocol forward.

### Return Path: Stage 8 → Stage 7

When Stage 8 Phase C produces a Lane 2 (AC Gap) finding, the release cannot advance until the gap closes. Per the layered review model, QA findings re-enter the quality layer (DT) before reaching the fix layer (Engineering) — QA does not route directly to Engineering. This preserves the independent-reviewer invariant at every transition.

#### QA → DT Return Handoff

Stage 8 posts a structured `### QA Return to Dev Testing` section on the relevant sub-task with these required fields:

| Field | Type | Purpose |
|---|---|---|
| Trigger lane | Enum: `Lane 2` (Lane 1 logs only; Lane 3 escalates to Stage 9) | Confirms routing reason |
| QA finding ID | `QF-NN` | Stable reference across iterations |
| Failed AC | Table: `AC · Issue # · Verdict (NOT MET / PARTIAL) · Evidence of gap` | DT's re-review anchor |
| DT-side hypothesis | One line (optional) | Why QA thinks DT missed — aids calibration |
| Requested scope | Always `Full re-review (per the loop protocol)` | Binds DT scope explicitly |
| Return timestamp | ISO-8601 | Iteration history |
| QA iteration count at return | Integer | Informs composed-loop escalation |

#### DT scope on QA returns

When DT receives a QA return, DT executes a **full re-review** (all Phase A–D assertions against the full PR diff), not the targeted re-review of the native DT-Eng iteration loop. Rationale:

- QA findings are by definition DT escapes — DT's prior pass missed an AC gap that QA detected.
- Targeted re-review assumes fix isolation. On a QA return the trigger is NOT a fix — it is a miss. Targeted scope on a miss would compound the miss.
- Full scope catches correlated misses — if DT miscalibrated one dimension, related dimensions in the same review may also be affected.

This boundary-specific rule does not change the DT-Eng loop's targeted default for the native DT↔Engineering loop (whose input is a fix, not a miss). When the full-scope rule ships, the targeted/full distinction retires and all DT re-reviews become full scope — this protocol aligns with that target state already.

#### DT processing after return

DT runs Pass N+1 (where N = DT's iteration count prior to the QA return). Three outcomes:

| Outcome | Action | Signal |
|---|---|---|
| DT confirms the QA finding as a DT escape | Add QF-NN to findings with `Origin: S8 (return)`, classify via routing-tier rule, route per the iteration-loop protocol (Engineering fix via `fix(dt):` commit) | Enter the DT-Eng loop |
| DT disputes the QA finding (disagrees AC is unmet) | Post `[SCOPE CHANGE]` signal per the inter-stage feedback protocol Tier 2 — operator adjudicates. DT does NOT unilaterally close a QA finding | Escalation to operator |
| DT discovers additional escapes during full re-review | Add to findings with `Origin: S7 (pass N+1 full)`; include in the iteration loop and report in the Verified signal | Continue in the DT-Eng loop |

#### DT → QA Verified Signal

When DT's post-return iteration reaches `PASS` or `CONDITIONAL PASS`, DT posts a `### Return to QA — Verified` section on the sub-task with:

| Field | Type | Purpose |
|---|---|---|
| QA finding ID(s) closed | List of `QF-NN` | Traceability to Stage 8 Phase C findings |
| Resolution commits | SHA list per the fix(dt): convention | Audit trail |
| DT re-review verdict | Enum: `PASS` / `CONDITIONAL PASS` | QA Phase A re-entry gate |
| Scope executed | `Full re-review` | Confirms full re-review alignment |
| Additional findings surfaced | Count (may be 0) with F-ID list | QA attention flag for Pass M+1 |
| DT iterations contributed | Integer | Composed-loop calibration input |

The Verified Signal augments the original Forward Handoff (it does not replace it). Its `verdict` (enum: `PASS` / `CONDITIONAL PASS`), `DT iterations contributed` (integer), and `Origin` labels applied to newly surfaced findings follow the forward-handoff enum vocabulary so that QA Phase A can extract them with the same parser. QA Pass M+1 entry validation re-checks the original Handoff Payload (the 9 required handoff fields remain authoritative) plus the Verified Signal closures — it does NOT validate the Verified Signal as a standalone handoff payload. The Verified Signal's 6 fields above are the complete contract for the signal itself; the re-entry gate passes when (a) the original Handoff Payload still parses, (b) each listed QA finding ID is marked closed with a resolution commit, and (c) the DT re-review verdict is `PASS` or `CONDITIONAL PASS`.

#### Integration with DT-Eng iteration loop

The return path composes with the DT-Eng iteration loop as its QA-initiated variant:

```
Stage 8 Phase C Lane 2 → QA Return to DT (this protocol)
  ↓
DT Pass N+1: Full re-review (per the full re-review rule)
  ↓
┌─ Confirms finding → enter the DT-Eng iteration loop
│   Engineering fix (fix(dt): commit) → DT targeted re-review (per the full re-review rule)
│   DT PASS → Return to QA — Verified (this protocol)
│   ↓
│   QA Phase D Pass M+1 (full re-review per Stage 8 §5 Phase D)
│
├─ Disputes finding → [SCOPE CHANGE] to operator (per the inter-stage feedback protocol Tier 2)
│
└─ Finds new escape during full re-review → enter the DT-Eng iteration loop for the new finding
    Include in Verified signal when closing
```

#### Iteration caps

| Loop | Cap | Rationale |
|---|---|---|
| DT↔Engineering iteration loop | 3 iterations | Finding-count convergence surfaces Engineering-fixable defects vs. upstream issues |
| QA Phase D (Stage 8 §5) | 2 QA Pass cycles | Per existing Stage 8 definition: more than 2 QA passes signals systemic issue |
| Composed (QA→DT→Eng→DT→QA) | No separate cap — each loop caps independently | Whichever inner cap fires first triggers its own escalation |

When any cap fires, the enclosing loop escalates per the inter-stage feedback protocol (Tier 2 for calibration drift; Tier 3 if the miss indicates a planning defect).

#### Automation trajectory

| Aspect | Current State | Target State |
|---|---|---|
| QA return trigger | Operator relays Lane 2 finding to DT session | Auto-trigger on Lane 2 finding in QA report |
| Return payload | Markdown section drafted by QA skill | Structured payload emitted by QA skill chain |
| DT scope enforcement | Operator confirms full re-review scope | Eval runner enforces full scope on QA-originated triggers |
| Verified signal | Markdown comment | Structured payload consumed by QA skill chain |
| Calibration detection | Operator notices recurring QA escapes | Auto-detect DT calibration drift from escape trend in calibration-data.md |
