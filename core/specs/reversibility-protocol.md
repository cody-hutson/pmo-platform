# Reversibility Protocol

## Purpose

This protocol operationalizes the reversibility principle named in `standards/principal-standard-checklist.md` §4 (Judgment Under Uncertainty) with a tier vocabulary that scales process weight to the cost of being wrong. It determines how much ceremony a decision-class output carries — from "just do it" for easily-undone work to "explicit multi-stakeholder sign-off" for commitments that cannot be reversed. All 22 PMO skills that produce decision-class outputs apply this protocol; pmo-qa-auditor G4 enforces it. `[SOURCE: standards/principal-standard-checklist.md §4]`

The principle itself is non-negotiable per `technical-leader-persona.md`: "Reversibility Determines Process Weight: Lightweight processes for reversible decisions, heavyweight for irreversible." This doc translates that principle into an auditable rubric. `[SOURCE: technical-leader-persona.md KB anchor]`

## Definition

**Reversibility** is the effort required to undo a decision if it turns out to be wrong. It is observed along two axes:

1. **Undo time** — hours, days, weeks, or never.
2. **Stakeholder impact** — whether reversal is a single-agent operation, or requires multi-party coordination, notification, or re-commitment.

Reversibility is **paired with but distinct from confidence**:

- **Reversibility** = *what-if-wrong cost*. How expensive is undoing this?
- **Confidence** = *how-likely-wrong*. How certain is the agent that the recommendation is correct?

Both travel together. A HIGH-confidence IRREVERSIBLE recommendation still requires a sign-off gate (because the downside of being wrong is absolute); a LOW-confidence CHEAP recommendation can still be executed immediately (because the cost of being wrong is trivial). Treating them as one dimension collapses information the operator needs to calibrate review rigor. `[INFERRED: from principal-standard-checklist.md §4 which names reversibility and confidence as separate PASS criteria]`

## The Four Tiers

Each tier is defined by observable thresholds — undo time plus stakeholder impact — so both the producing skill and the G4 auditor can evaluate them consistently.

### CHEAP (undo in hours)

**Observable indicators:**
- No data loss on reversal.
- No stakeholder notification required.
- Reversion is a single-agent action (operator or the skill itself).
- Change is visible only to the operator.

**Examples:** Editing a draft email. Renaming a tracker field locally. Rewriting a status bullet. Adjusting a local sprint plan before submission.

### MODERATE (undo in days, minor data loss acceptable)

**Observable indicators:**
- Affects a small cohort — one team, one project, one document version.
- Rework measured in hours-to-days.
- Stakeholder notification optional but expected if the change reversal would surprise them.

**Examples:** Committing a tracker schema change mid-sprint. Reassigning a ticket across teams. Revising an already-distributed project plan draft. Publishing a working-version Confluence page.

### EXPENSIVE (undo in weeks, stakeholder impact)

**Observable indicators:**
- Multi-team or multi-stakeholder coordination required to reverse.
- State has been published or committed externally.
- Rework measured in days-to-weeks.
- Reversal itself generates stakeholder friction (questions, re-alignment meetings, trust cost).

**Examples:** Changing a go-live date after stakeholder announcement. Restructuring a project's phase breakdown post-kickoff. Re-scoping a release after sub-tasks are in flight. Altering an approved RAID mitigation plan.

### IRREVERSIBLE (cannot undo)

**Observable indicators:**
- External commitment made.
- Data permanently lost or destroyed.
- Regulatory, contractual, or audit-of-record fact established.
- Rollback requires creating a **new forward-facing commitment**, not reversal of the original action.

**Examples:** Sending an exec communication. Approving a signed change request. Executing a data migration without reversible backup. Closing a project in the portfolio of record. Posting an escalation to leadership.

**Rationale for undo-time + stakeholder-impact thresholds:** Both are observable by the producing skill (it knows who the audience is and whether state has been committed) and auditable by pmo-qa-auditor G4 (it can evaluate whether a given recommendation crosses a visibility threshold). Purely subjective criteria — for example, "high risk" or "important" — were rejected as unauditable. `[INFERRED]`

## Process Weight by Tier

Process weight scales with tier. The lighter the tier, the less ceremony; the heavier the tier, the more gates.

| Tier | Process weight | Required output elements | Required gates |
|---|---|---|---|
| **CHEAP** | Lightweight | State the tier. No further ceremony. | None — the agent proceeds. "Just do it." |
| **MODERATE** | Light+ | State the tier. Surface the key assumption or tradeoff in ≤1 sentence. Invite a single-reviewer pass before execution. | Single-reviewer confirm (the operator). |
| **EXPENSIVE** | Substantive | State the tier. Document rationale (≥2 sentences: why this over alternatives). State rollback plan. Name the stakeholder cohort affected. | Operator review + rollback-plan assertion. Escalation path named if operator delegation is unclear. |
| **IRREVERSIBLE** | Heavy | State the tier. Document rationale. State that rollback is **infeasible**, or name the new forward-facing commitment required to counteract. Name the sign-off authority. Pair with explicit confidence level and downside description. | Operator sign-off required. Cannot be auto-executed by another skill in a chain. Pre-execution simulation or dry-run strongly recommended. |

**Weight ties to tier, not to output size.** A single-sentence recommendation can be IRREVERSIBLE ("I recommend sending this as-is to the CEO"); a 500-word plan can be CHEAP (a draft nobody has seen). The tier reflects downstream commitment, not authoring effort. `[INFERRED]`

**Interaction with existing CLAUDE.md guardrails:** The "No ungoverned changes" guardrail in CLAUDE.md already treats governance-file changes as IRREVERSIBLE-class work (GitHub Issue + plan + approval + dry-run + snapshot). This protocol generalizes that pattern — governance files are not the only IRREVERSIBLE surface; the tier vocabulary is the universal mechanism. `[SOURCE: CLAUDE.md § Quality Standards — "No ungoverned changes"]`

### In-place bias — prefer the lower-tier fix

When a fix can be done in place, do not propose a repository move, clean-room rebuild, or rip-and-replace as the remedy. The bias is a tier-selection rule, not a preference: an in-place edit is typically CHEAP or MODERATE, while a move/rebuild/replace pulls the work up to EXPENSIVE or IRREVERSIBLE (it discards history, breaks references, and forces re-validation of everything downstream). Reaching for the big move when the in-place edit would do inflates the reversibility tier — and an over-proposed migration reads as a deferral technique, substituting a large reversible-looking project for the small fix actually asked for.

The test is **what the change does to existing state**, not how large the operation looks: an edit that rewrites content in place — including a history rewrite that operates on the existing repository rather than relocating it — stays in-place and keeps its lower tier. A *move* is relocating the work to a new home (new repo, new tree, fresh seed) and abandoning the old one; that is the higher-tier path and is justified only when an in-place fix is genuinely impossible, not merely when it is faster to start fresh. Default to the in-place fix at its true (lower) tier; escalate to a move only with the EXPENSIVE/IRREVERSIBLE ceremony the higher tier requires and an explicit statement of why in-place was rejected.

## Application to Skill Outputs

### Decision-class outputs (in scope)

A skill's output element is **decision-class** if it:

- Recommends an action the user should take (e.g., "I recommend sending this on Tuesday").
- Frames a decision with options and a preferred path.
- Proposes a plan or sequence of steps the user is expected to execute.
- Escalates an issue requiring user judgment or authority.

Every decision-class item must carry a reversibility tier label.

### Non-decision-class outputs (out of scope)

An output element is **not** decision-class if it is:

- An observation or finding ("I notice X").
- A status summary ("Y is now complete").
- An evidence citation with `[SOURCE]` label.
- A question posed to the user (a question escalates but does not decide).

These items do not require a tier label. A skill that produces **only** non-decision-class outputs is a **report-only skill** and declares this explicitly (see Report-Only Opt-Out below).

### How to apply the tier to an output

For each decision-class item, the producing skill labels the tier using one of these formats — any is acceptable, pick what reads cleanest in context:

- **Inline label:** `Recommendation (MODERATE · confidence: HIGH): Ship on Tuesday.`
- **Trailing label:** `Ship on Tuesday. [MODERATE · confidence: HIGH]`
- **Structured column:** In a table or section with a dedicated `reversibility` or `tier` column, populate the value.
- **Structured decision frame:** In a multi-field decision frame (e.g., ppm-agent Section 5 Decisions Needed), fill the reversibility field with the tier value.

The format is flexible; the **presence of a tier label on every decision-class item is not**. Outputs that omit tier labels on decision-class items will FAIL pmo-qa-auditor G4 (see G4 Gate Check below).

### Sizing process weight to the tier

The producing skill scales its own output to match the tier:

- **CHEAP:** Label the tier and proceed. No additional ceremony.
- **MODERATE:** Label the tier, surface the key assumption in one sentence, invite operator review.
- **EXPENSIVE:** Label the tier, document the rationale, state the rollback plan, name the affected stakeholder cohort.
- **IRREVERSIBLE:** Label the tier, document the rationale, state that rollback is infeasible or name the counter-commitment required, name the sign-off authority, pair with an explicit downside description.

If the skill cannot produce the required elements for the tier it has assigned (e.g., cannot name a rollback plan for an EXPENSIVE item), that is a signal to re-examine whether the recommendation is ready — not a signal to downgrade the tier to skip the gate.

## Confidence Pairing

Every reversibility tier is paired with a **confidence level** from the three-value set: `HIGH` / `MEDIUM` / `LOW`.

**Recommended format:** `[TIER] · confidence: [HIGH|MEDIUM|LOW]`

Examples:
- `[CHEAP · confidence: HIGH]` — easy to undo, agent is certain. Execute immediately.
- `[MODERATE · confidence: LOW]` — undoable in days, but the agent is unsure. Single-reviewer pass catches the uncertainty early.
- `[IRREVERSIBLE · confidence: HIGH]` — cannot undo, agent is certain. Sign-off gate is still required because the downside of being wrong is absolute.
- `[IRREVERSIBLE · confidence: LOW]` — cannot undo, agent is unsure. Do not proceed without explicit operator sign-off and, ideally, a dry-run.

### Confidence is a separate dimension from evidence-quality labels

CLAUDE.md § Universal Preferences enumerates **evidence-quality labels** on factual claims: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. These categorize **where a claim came from** (source of knowledge). Confidence categorizes **how certain the agent is that the recommendation is correct** (certainty of judgment).

- A `[RECOMMENDED]` item with `confidence: LOW` is a recommendation the agent is flagging as uncertain — the operator should scrutinize it.
- A `[RECOMMENDED]` item with `confidence: HIGH` is a recommendation the agent is confident about — the operator can move faster.
- Collapsing confidence into the evidence label would hide the two-axis signal (reversibility × confidence) that the principal-standard-checklist already names as distinct.

**The two label systems are orthogonal and co-exist.** A single item can carry both: a factual claim uses an evidence label; a decision-class item uses a reversibility tier plus confidence level; a decision-class item grounded in a cited source may carry all three.

`[SOURCE: CLAUDE.md § Universal Preferences — Evidence quality labels]`

## From Label to Gate (Confidence-Driven Disposition)

The Confidence Pairing above gives the operator a **label** to read. This section promotes that label into a **gate** the agent evaluates *before* acting on a decision-class item — the active counterpart to the passive pairing. Where the pairing *displays* reversibility × confidence, the gate *acts on* them: it returns a disposition — **PROCEED**, **PAUSE-TO-LEARN**, or **ESCALATE** — by reading the action's reversibility tier (this doc's four tiers) against a confidence **signal**, modulated by the action's autonomy tier (`autonomy-tiers.md` Tier 0–3).

**This section adds a disposition. It changes none of the four tiers, the Process-Weight table, the In-Place Bias, the decision-class scope, or the pairing format above — the gate *reads* them.** The execution-time consumer of the PAUSE-TO-LEARN disposition is `../disciplines/autonomous-execution-model.md` § Pause-to-Learn Pattern (the 3rd pre-action sibling to Retry and Escalate). The full mechanism — the confidence signal sources, the threshold matrix, the bounded learn-loop, and the anti-theater guard — is specified canonically in `decision-confidence-protocol.md`; this section is the reversibility-side promotion that protocol names, not a restatement of it.

### The confidence signal (not a self-report)

The gate does **not** read the agent's verbalized self-confidence ("I'm 90% sure") — that is the least-trustworthy signal and is rejected as an input. It reads a **consistency signal** collapsed to one of three ordinal states, per `decision-confidence-protocol.md` § 1:

- **`CONVERGENT`** — independent cross-checks corroborate the conclusion and the weakest evidence label is ≥ `[INFERRED]`. No load-bearing gap; proceed-eligible.
- **`DIVERGENT`** — independent paths disagree, or a *named* gap exists that would change the conclusion.
- **`UNGROUNDED`** — the conclusion rests on an unverified `[ASSUMPTION – CONFIRM]` on a load-bearing claim with no corroborating path.

The pairing's `confidence: [HIGH|MEDIUM|LOW]` label remains the operator-facing display; the gate consumes the `CONVERGENT|DIVERGENT|UNGROUNDED` signal state. A proceed decision must be able to cite *which* observable source produced `CONVERGENT` — a proceed that can only cite a feeling has bypassed the gate.

### The disposition matrix (reversibility × signal, autonomy-modulated)

There is no defensible single global cutoff: the same signal proceeds when being wrong is cheap and escalates when being wrong is irreversible. The cell action is a function of the confidence signal (rows) and this doc's reversibility tier (columns), conforming cell-for-cell to `decision-confidence-protocol.md` § 2.2:

| Signal ↓ / Reversibility → | CHEAP | MODERATE | EXPENSIVE | IRREVERSIBLE |
|---|---|---|---|---|
| **CONVERGENT** | PROCEED | PROCEED | PROCEED (state rollback) | PROCEED **only at Autonomy Tier 0/1** (operator sign-off already gates it); else ESCALATE |
| **DIVERGENT** | PROCEED (cost trivial) | PAUSE-TO-LEARN | PAUSE-TO-LEARN → ESCALATE if unresolved | ESCALATE (never auto-proceed) |
| **UNGROUNDED** | PAUSE-TO-LEARN | PAUSE-TO-LEARN | ESCALATE | ESCALATE |

Disposition vocabulary (three values — each routes to an existing surface):

- **PROCEED** — act, carrying the reversibility tier label per § How to apply the tier above. The existing process-weight for the tier still applies (a CONVERGENT IRREVERSIBLE at Tier 0/1 still owes its sign-off gate — the gate does not waive the IRREVERSIBLE ceremony, it confirms the signal does not *block* the already-gated action).
- **PAUSE-TO-LEARN** — do **not** act yet; hand to `../disciplines/autonomous-execution-model.md` § Pause-to-Learn Pattern, which injects a *new external signal* to close the named gap, is **bounded**, and **has an exit** (resolve → re-enter this matrix; budget exhausted → ESCALATE).
- **ESCALATE** — surface a Decision Briefing per `../disciplines/autonomous-execution-model.md` § Escalate Pattern. For the IRREVERSIBLE column on a non-`CONVERGENT` signal this **is** the existing sign-off gate — the row formalizes that IRREVERSIBLE never auto-proceeds, which the Process-Weight table and the `[IRREVERSIBLE · confidence: LOW]` pairing example above already require. No new behavior; the matrix makes the existing rule queryable.

### Autonomy-tier modulation

The matrix above is read against `autonomy-tiers.md` via two cross-axis invariants — inherited from the axis specs, not invented here (conforming to `decision-confidence-protocol.md` § 2.3):

- **I1 — IRREVERSIBLE never auto-proceeds on a non-`CONVERGENT` signal.** A `DIVERGENT`/`UNGROUNDED` IRREVERSIBLE action routes to ESCALATE; a `CONVERGENT` IRREVERSIBLE still requires the operator sign-off the Tier-0 gate already imposes. This mirrors this doc's own rule (IRREVERSIBLE requires sign-off regardless of confidence — § Confidence Pairing) and `autonomy-tiers.md` § Boundary Tests (IRREVERSIBLE actions cannot be Tier 3).
- **I2 — the gate lowers ceremony, never raises autonomy.** A cell may force a PAUSE or an ESCALATE, but it can **never** grant an action a higher autonomy tier than `autonomy-tiers.md` already permits. A `CONVERGENT` signal does not promote a Tier-1 draft into a Tier-3 auto-write — confidence is a brake, not an accelerator. This blocks the gate becoming a self-elevation path.

**Anti-theater anchor:** a PAUSE disposition is load-bearing only if the learn-loop injects a *new* signal, is *bounded*, and *has an exit* — defined and guarded in `../disciplines/autonomous-execution-model.md` § Pause-to-Learn Pattern and `decision-confidence-protocol.md` § 5. A pause that merely re-reads what the agent already had is theater, and the guard flags it.

`[SOURCE: decision-confidence-protocol.md §§ 1–2 — the canonical signal + threshold model this promotion conforms to]`

## Report-Only Opt-Out

Some skills produce outputs that are entirely non-decision-class — for example, a daily status rollup that only summarizes what happened, with no recommendations. Applying the reversibility check to such a skill would produce false-positive FAIL findings (zero decision-class items detected could mean "correctly report-only" or "silently omitted decisions it should have produced"). The opt-out mechanism distinguishes the two cases.

### How a skill declares report-only

A report-only skill includes an explicit statement in its SKILL.md — in the mode definition or output contract section — that reads:

> **Reversibility scope:** This skill does not produce decision-class outputs (recommendations, plans, escalations, or proposed actions). The reversibility tier check per `core/specs/reversibility-protocol.md` does not apply to this skill's outputs.

pmo-qa-auditor G4 reads the skill's SKILL.md before evaluating the output. If the opt-out is present, G4 skips the reversibility check for that skill's outputs cleanly.

### What triggers the opt-out (and what doesn't)

**Valid report-only skills** produce outputs that are purely observational, summarizing, or evidentiary. Examples of candidate report-only patterns: a status rollup that narrates completed work; a tracker read-out that lists current state without suggesting changes; a pure classification skill that labels items without recommending action.

**Invalid report-only claims:**
- A skill that produces "next actions" in its output — those are decision-class; the skill is not report-only.
- A skill that produces "items requiring your action" — those are decision-class.
- A skill that surfaces options with a preferred path — that is decision-class.

If any output element meets the decision-class definition, the skill is not report-only, and the opt-out must not be used.

### Mode-scoped opt-out

A multi-mode skill may be report-only in some modes and decision-class in others. In that case, the opt-out statement is scoped to the specific modes — for example: *"Mode A (status rollup) is report-only. Mode B (triage report) produces decision-class outputs and applies the reversibility tier check."*

### Operator-default behavior when opt-out is absent

If a skill's SKILL.md does not declare report-only and G4 finds zero decision-class items in an output, G4 records a **Minor remediation finding** (not a FAIL): "Consider declaring this skill report-only in SKILL.md, or confirm decision-class items were not silently omitted." This keeps the gate honest without producing a false FAIL.

`[SOURCE: Stage 5 Solutioning Finding 1]`

## Relationship to Other Principles

### Principal standard checklist

This protocol is the **operationalization** of `standards/principal-standard-checklist.md` §4 (Judgment Under Uncertainty). The checklist's PASS criterion "reversibility is stated" becomes, under this protocol, "reversibility tier is labeled." The checklist's "confidence level is stated" becomes "confidence level is paired with the tier in the [HIGH|MEDIUM|LOW] format." No criteria change — the vocabulary gets sharper. `[SOURCE: standards/principal-standard-checklist.md §4]`

### Failure-mode discipline

Failure-mode discipline asks **"under what conditions does this skill fail to produce useful output?"** and is a precondition check at the skill level — does the skill run at all? Reversibility is an item-level label applied to decision-class outputs *after* the skill has determined it can run.

The two are independent dimensions:
- A skill can produce IRREVERSIBLE recommendations without being in a failure mode.
- A skill can be in a failure mode (producing nothing useful) regardless of whether its would-be outputs were reversible.

Composition is clean. See `failure-mode-standard.md` (sibling reference doc) for the failure-mode discipline spec.

### Review-discipline principles

Review-discipline governs **the output form of review skills** — thoroughness, evidence-bearing, anti-laziness rules. Reversibility governs the **labeling of any decisions the reviewer recommends**.

A review skill (e.g., pmo-qa-auditor, build-reviewer) produces an audit report. Review-discipline shapes the report's overall form (the 7-section extraction format, finding location references, no-PARTIAL-verdict rule). Reversibility applies to each remediation recommendation *inside* the report — each "here's what to change" carries its own tier and confidence level.

The two stack vertically: review-discipline is a structural contract for the output; reversibility is an item-level label within that output. See `review-discipline-principles.md` (sibling reference doc) for the review-discipline spec.

### Composition summary

For a single skill output, all three principles may apply:

1. **Failure-mode** (precondition): does the skill run? Governed by the skill's SKILL.md header.
2. **Review-discipline** (output form, review skills only): does the output follow the required shape? Governed by the review skill's output contract.
3. **Reversibility** (item level, decision-class items): does each decision-class item carry a tier label paired with a confidence level? Governed by this protocol.

No semantic overlap. No composition conflict. `[INFERRED: from Stage 5 Decision 7 composition test]`

## G4 Gate Check (pmo-qa-auditor)

pmo-qa-auditor G4 (Evidence Quality) enforces this protocol. The full algorithmic spec lives in `skills/pmo-qa-auditor/SKILL.md` G4 section — this doc summarizes the decision criteria.

**G4 reversibility check — summary:**

1. Read the skill's SKILL.md to determine whether the skill declares report-only (see Report-Only Opt-Out). If report-only, the reversibility check is N/A.
2. Identify decision-class items in the output under review (recommendations, plans, escalations, proposed actions).
3. For each decision-class item, check for an explicit reversibility tier label (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) in any accepted format.
4. If any decision-class item lacks a tier label, record a G4 failure finding with location, remediation text (including suggested tier and rationale), and the label format the skill should have produced.
5. If all decision-class items are labeled, G4 PASS on reversibility.

The check is LLM-evaluated, not regex-matched, because decision-class speech acts are too flexible for pattern matching alone. `[SOURCE: Stage 5 Decision 3]`

## Examples

### Strategic skill (ppm-agent) — multi-tier mix

A ppm-agent triage report Section 5 (Decisions Needed) typically carries a mix of tiers in a single output:

> **Decision 1:** Extend the sprint by 2 days to absorb the scope change.
> - **Tier:** `[MODERATE · confidence: HIGH]`
> - **Rationale:** Reversible within the current sprint if the scope change is deprioritized mid-sprint. Stakeholder notification to the PO, but no external commitment.
> - **Rollback:** Revert sprint dates in tracker; communicate to team.
>
> **Decision 2:** Change the go-live date from 2026-05-01 to 2026-05-15.
> - **Tier:** `[EXPENSIVE · confidence: MEDIUM]`
> - **Rationale:** Stakeholder announcement already issued; reversal requires a second announcement and re-alignment with dependent teams.
> - **Rollback:** Issue correction announcement; re-confirm downstream commitments.
> - **Affected cohort:** Program sponsor, dependent project leads (×3), customer success.
>
> **Decision 3:** Send the exec escalation email as drafted.
> - **Tier:** `[IRREVERSIBLE · confidence: HIGH]`
> - **Rationale:** Once sent, the escalation is on the record with leadership.
> - **Counter-commitment (rollback is infeasible):** If the escalation proves premature, a follow-up email withdrawing it would itself be a new commitment — not a reversal.
> - **Sign-off authority:** Program sponsor.
> - **Downside if wrong:** Trust cost with leadership; perception of over-escalation.

Three decisions, three tiers, three confidence levels. The operator calibrates review rigor accordingly.

### Operational skill (delivery-engine) — sprint-plan decisions

A delivery-engine sprint-plan revision recommendation:

> **Recommendation:** Rebalance the sprint by moving IMP-A from this sprint to the next. `[MODERATE · confidence: HIGH]`
>
> **Assumption surfaced:** This assumes IMP-A's dependency on IMP-B is not resolving within the current sprint. Confirm with the engineering lead before committing.

Single-reviewer pass before execution, per the MODERATE tier's required gate.

### Infrastructure skill (pmo-qa-auditor) — remediation recommendations

An audit report includes remediation recommendations — each is itself decision-class:

> **Finding F3:** The skill's output omits the reversibility tier on Decision 2.
>
> **Remediation:** Add the tier label `[MODERATE · confidence: HIGH]` after the Decision 2 recommendation text, matching the format used for Decision 1. `[CHEAP · confidence: HIGH]`

The remediation itself is CHEAP (a trivial text edit the user can make and reverse in seconds), so the label is lightweight and the process proceeds without ceremony.

### Report-only skill — opt-out

A hypothetical `status-rollup` skill that only narrates completed work declares in its SKILL.md:

> **Reversibility scope:** This skill does not produce decision-class outputs (recommendations, plans, escalations, or proposed actions). The reversibility tier check per `core/specs/reversibility-protocol.md` does not apply to this skill's outputs.

pmo-qa-auditor G4 detects the opt-out before scanning the output, and the reversibility check is skipped for this skill.

---

*This protocol is a foundation document. It is consumed by CLAUDE.md § Universal Preferences, `skills/skill-creator/SKILL.md` (Interview mode), `skills/pmo-qa-auditor/SKILL.md` (G4), `decision-confidence-protocol.md` (which composes this doc as its cost-of-error axis and promotes the § Confidence Pairing label toward the § From Label to Gate disposition), `../disciplines/autonomous-execution-model.md` § Pause-to-Learn Pattern (the execution-time consumer of the PAUSE-TO-LEARN disposition), and the 22 consumer SKILL.md files applying the tier discipline to their own decision-class outputs.*
