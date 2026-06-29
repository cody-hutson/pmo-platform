---
title: Root-Cause Analysis (RCA) Method
purpose: The invokable method for root-causing a defect or failure — a thin entry point that consumes the root-cause FORMAT, the systemic-pattern categories, and the failure-mode template where they already live, rather than relocating them
applies_to: delivery-engine (Mode A/C/E/G), intake-desk (hand-off), define/triage stages, failure-mode authoring
parallel_to:
  - ../disciplines/review-discipline-principles.md
  - ../disciplines/discovery-discipline.md
  - ../disciplines/decision-discipline.md
  - ../standards/failure-mode-standard.md
source: promoted from the observation that root-cause analysis existed as a scattered principle with no invokable method, surfaced while building the intake front door — the open question "where is root cause performed today?" had no answer as a usable method, only as a scattered principle across review-discipline-principles.md / failure-mode-standard.md / decision-discipline.md
---

<!-- reference-durability: allow-link -->

# Root-Cause Analysis (RCA) Method

The invokable method for root-causing a defect or failure. Root-causing exists across the platform as a *scattered principle* — the root-cause **format** lives in [`review-discipline-principles.md` §2](review-discipline-principles.md), the systemic-pattern **categories** live in [§3](review-discipline-principles.md), and root-cause **as a field** lives in the [`failure-mode-standard.md`](../standards/failure-mode-standard.md) 5-field template — but none of those is a *callable procedure* a stage can hand off to. This method is that procedure. It is a thin entry point: it **invokes** the existing format and categories as its output contract; it does **not** redefine or relocate them.

**Distinction from the review-discipline ROOT-CAUSE FORMAT it consumes.** [`review-discipline-principles.md` §2](review-discipline-principles.md) defines *what a valid root cause looks like* (the chain `[systemic pattern] → [proximal cause] → [observable signal]` + the rejection threshold). This file defines *how you produce one for a given defect* — the 6 steps, the trigger predicate, and the invocation points. The format is the output contract; this method is the production procedure. The two are referenced by [`decision-discipline.md` §intro](decision-discipline.md), which places root-cause chains in the review audience.

---

## Section 1 — Scope and Applicability

### 1.1 What is RCA-class work?

RCA-class work takes a *defect or failure* — a bug, a regression, a gate failure, an incident, a recurring symptom — and produces a **root-cause record**: an observable signal, a causal chain in the required format, a systemic-pattern classification, a falsification test, a reversibility-tagged remediation scope, and a routing disposition. It is the act of answering *"why did this fail?"* with a chain that terminates at a systemic pattern, not at the symptom.

RCA fires at **activity-exit** — after a defect or failure has surfaced and there is something to root-cause. This is the inverse temporal anchor of `discovery-discipline.md`, which fires at activity-**entry** (before an artifact exists, asking *"what should this be?"*). The two compose: discovery surfaces what might fail ahead of authoring; RCA explains what *did* fail after it surfaced.

### 1.2 Relationship to the sibling meta-protocols

Parallel, not extension. Each sibling governs a distinct activity-class at a distinct temporal anchor and audience:

| Sibling | Activity-class | Primary question | Temporal anchor |
|---|---|---|---|
| `discovery-discipline.md` | Discovery | "What should this be? What don't we know?" | Before the artifact exists (activity-entry) |
| `decision-discipline.md` | Decision | "What should we choose?" | At the recommendation point |
| `review-discipline-principles.md` | Review | "Is this correct?" | After the artifact exists |
| `../standards/failure-mode-standard.md` | Failure-mode authoring | "What fails, why, and how?" | Pre-authoring (skill spec definition); enforced at G7 |
| `root-cause-analysis.md` (this file) | **RCA** | **"Why did this fail?"** | **After a defect/failure surfaces (activity-exit)** |

RCA is **review-class adjacent** — it produces findings with root causes, the same artifact shape review produces — but it is narrower: review audits a *whole artifact* for correctness across many dimensions; RCA root-causes a *single defect or failure* down to its systemic pattern. A skill performing both cites both files. Cross-reference between the siblings and this file; no inheritance.

### 1.3 What RCA is NOT

Five negative bounds (each maps to one anti-pattern in § 5):

- RCA is NOT symptom logging — recording *what broke* without the proximal cause and systemic pattern is a symptom-only record, which `review-discipline-principles.md` §2 rejects.
- RCA is NOT an intake activity — intake **captures** a defect and **hands off** the root-causing (per [ADR-016 §3](../ADRs/ADR-016-intake-front-door-architectural-boundary.md)); the causal walk needs processing context intake does not gather.
- RCA is NOT pattern promotion on a sample of one — a single defect's root cause is a *finding*, not a *pattern*; promotion to a failure-mode entry gates on the emergence rule (N≥2 same signature).
- RCA is NOT redefining the root-cause format — the format and the 5 categories live in `review-discipline-principles.md`; this method cites them, and editing them here would break their ~36 inbound references.
- RCA is NOT mandatory for a well-understood one-line fix — when the cause is obvious and the fix is a point-correction, the omission is the correct non-ceremony signal (see § 2 non-fires).

---

## Section 2 — When this fires (the trigger predicate)

RCA fires conditionally — when a defect or failure surfaces that needs a cause before it can be remediated, promoted, or routed. The discipline activates workspace-wide per the CLAUDE.md Universal Preferences activation clause; the conditional triggers below identify the discrete activity boundaries.

| Trigger | Example | Who invokes |
|---|---|---|
| **Defect / bug intake** | A `bug`-type work item lands with an unknown cause | `intake-desk` hands off — emits `[ASSUMPTION – CONFIRM] <unknown cause> — owner: root-cause — to close: RCA per core/disciplines/root-cause-analysis.md`; does NOT root-cause inline (per [ADR-016 §3](../ADRs/ADR-016-intake-front-door-architectural-boundary.md)) |
| **Post-failure / post-surprise** | A gate fails, a release regresses, an incident occurs | `delivery-engine` Mode E (Execution Control Tower) for a slip/regression; the pipeline stage that owns the failure |
| **Systemic finding needing a cause** | A backlog scan surfaces a systemic issue ("42% of tickets lack AC"); a DoR check finds "fix the bug" with no success definition | `delivery-engine` Mode A (Backlog Scan → RAID entry for a systemic issue), Mode C (DoR gate), Mode G (RAID origination) |
| **Recurring symptom (N≥2)** | Two or more same-signature defects | Promote the RCA output to a [`failure-mode-standard.md`](../standards/failure-mode-standard.md) entry (the RCA root cause becomes the "Root cause" field) |
| **Triage of a root-cause-owned assumption** | A `bug`-type issue at triage carries an open `owner: root-cause` assumption from intake | The define/triage stage routes the assumption to this method for closure before bundling |

**Non-fires (omission = correct, per the non-ceremony pattern).** A well-understood one-line fix with an obvious cause (a typo, a known-flaky test) does not need the 6-step walk — root-causing it is ceremony. A *feature request* has no failure to root-cause. When RCA does not fire, no root-cause record is produced; the omission is explicit, not silent.

---

## Section 3 — The Method (6 steps)

Each step names what it consumes from where. The method does not duplicate the cited content; it sequences it.

1. **State the observable signal.** Record what was actually seen — the symptom — verbatim, with evidence (`file:line` / log line / reproduction). This is the *observable signal* terminal of the required chain per [`review-discipline-principles.md` §2](review-discipline-principles.md). A signal without evidence is not yet a signal; fetch the evidence first.

2. **Establish the causal chain.** Walk symptom → proximal cause → systemic pattern using the **required format** in [`review-discipline-principles.md` §2](review-discipline-principles.md): `[systemic pattern] → [proximal cause] → [observable signal]`. This method does NOT redefine the format — it invokes it. **Reject a chain that terminates at the observable signal** (per the §2 rejection threshold): "the link is broken" is a symptom; "the reference was not updated when the section was renamed, so every citation of that section now dangles" is a root cause.

3. **Classify the systemic pattern.** Assign exactly one of the five categories in [`review-discipline-principles.md` §3](review-discipline-principles.md): **Design flaw** / **Implementation gap** / **Interface mismatch** / **Governance failure** / **Capacity shortfall**. The category is the bridge to remediation — a design flaw and an implementation gap demand different fixes.

4. **Test the root cause (falsification).** Apply the counterfactual: *"if this root cause were removed, would the symptom still recur?"* If yes, the chain is incomplete — re-walk from step 2; the named cause is a waypoint, not the root. A root cause that survives the counterfactual is the stopping point.

5. **Determine reversibility + scope of the fix.** Tag the remediation's reversibility tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE per [`reversibility-protocol.md`](../specs/reversibility-protocol.md)) paired with a confidence level, and state whether the fix is **point** (this instance only) or **systemic** (the pattern class). A systemic pattern with a point-only fix is a deferral, not a resolution — name it as such.

6. **Route the output.** Emit the root-cause record to its consumer:
   - a **finding** (review / audit context) — carries the record per the `review-discipline-principles.md` §5 findings-register shape;
   - a **failure-mode entry** — when the symptom is recurring (N≥2 same signature), the root cause becomes the "Root cause" field of a new [`failure-mode-standard.md`](../standards/failure-mode-standard.md) 5-field entry;
   - a **remediation work item** — when intake handed off an `owner: root-cause` assumption, the closed RCA is the evidence that closes it.

---

## Section 4 — Invocation Points (who calls this method, and from where)

The method is bound to its callers by **citation, not import** — each surface gains a reference to this file; it does not embed the method.

| Invocation point | Trigger surface | Binding (how it cites RCA) |
|---|---|---|
| **`delivery-engine`** ([`operations/skills/delivery-engine/`](../../operations/skills/delivery-engine/SKILL.md)) | Mode A (backlog scan → systemic finding), Mode C (DoR — "fix the bug" with no cause), Mode E (Execution Control — a slip/regression), Mode G (RAID entry for a systemic issue) | **Invokes** this method to produce the cause before originating a RAID entry or a remediation. The SKILL.md cites `core/disciplines/root-cause-analysis.md` as the procedure (see the skill's RAID / Execution-Control mode bodies). |
| **`ppm-agent`** ([`operations/skills/ppm-agent/`](../../operations/skills/ppm-agent/SKILL.md)) | A processed transcript / triage / status pass surfaces a defect or blocker with an unknown cause (Output §6 Top risks origination, §7 Dependencies and blockers) | **Invokes** this method when it owns the processing context (root-cause the defect before originating an `R-PPM-###` RAID entry), OR **hands off** `owner: root-cause` when the cause needs a context ppm-agent lacks. ppm-agent **processes existing** items (per [ADR-016 §3](../ADRs/ADR-016-intake-front-door-architectural-boundary.md)) — it is the inverse of intake's authoring boundary, so the inline invoke is in-scope here (it is barred only at the intake front door). |
| **`pmo-devops-sre`** ([`release/skills/pmo-devops-sre/`](../../release/skills/pmo-devops-sre/SKILL.md)) | Mode 3 (Reliability) classifies a regression signal (verification FAIL / post-deploy drift / reliability-threshold breach) ahead of a rollback proposal | **Originates** an RCA record on the regression — the root-cause becomes evidence in the rollback Decision Briefing so the same regression does not recur. Composition-safe: RCA produces the *cause*; the rollback *decision* stays operator-only and the rollback *mechanism* stays `release-executor` Mode C (no boundary crossed). |
| **failure-owning pipeline stage(s)** ([`release/governance/release-process.md`](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol; Stages 7/8/12/13) | A gate fails or a downstream stage finds the build unworkable (Tier 2 [SCOPE CHANGE] / Tier 3 [PLAN REJECTION]); a post-deploy regression triggers Rollback at Stage 12/13 | The stage that **owns** the failure **invokes** this method to root-cause it before re-running the upstream stage or proposing rollback. Inverse temporal anchor to the Tier-0 discovery binding (discovery = activity-entry premise-rejection; RCA = activity-exit failure root-causing). |
| **`intake-desk`** ([`operations/skills/intake-desk/`](../../operations/skills/intake-desk/SKILL.md)) | A `bug`/defect item lands; an unknown root cause surfaces | **Hands off** — emits `owner: root-cause` and cites this method; does NOT perform RCA inline (per [ADR-016 §3](../ADRs/ADR-016-intake-front-door-architectural-boundary.md)). |
| **define / triage stages** | A `bug`-type issue at triage with an open `owner: root-cause` assumption | Routes the RCA-owned assumption to this method for closure before bundling. |
| **`failure-mode-standard.md`** (downstream consumer, not a caller) | N≥2 same-signature → promote | Consumes RCA output as the "Root cause" field of a new anti-pattern entry. |

**Review-class skills are method-linked transitively, not by direct citation.** `build-reviewer`, `pmo-qa-auditor`, and `pmo-qa-lead` already cite [`review-discipline-principles.md`](review-discipline-principles.md); its §2 Rule 4 ("no symptom-only findings") IS the review-side enforcement of this method's step 2 (per §5.1). A review that produces findings therefore *uses* RCA per-finding without a redundant `root-cause-analysis.md` citation. This is the intended format-via-review-discipline boundary — recorded here so the linkage is auditable, NOT a coverage gap requiring a skill edit.

Activation is workspace-wide via the CLAUDE.md Universal Preferences clause. The conditional triggers in § 2 identify when the method fires; the invocation points above identify *who* fires it.

---

## Section 5 — Composition with Sibling Meta-Protocols

RCA composes with — does not replace — the siblings. Each composition direction is named.

### 5.1 Composition with `review-discipline-principles.md`

**Direction:** RCA consumes review-discipline's format and categories. RCA is the production procedure; review-discipline §2/§3 is the output contract. A review that produces findings *uses* RCA per-finding (Rule 4 "no symptom-only findings" is the review-side enforcement of this method's step 2). Cross-reference rule: an RCA record cites `review-discipline-principles.md` §2 for its chain format and §3 for its category.

### 5.2 Composition with `../standards/failure-mode-standard.md`

**Direction:** RCA feeds the failure-mode template. When a defect recurs (N≥2 same signature), step 6 routes the root cause into the "Root cause" field of a 5-field failure-mode entry. RCA is the upstream producer; the failure-mode entry is the durable downstream record of the *pattern*. Cross-reference rule: a failure-mode entry whose "Root cause" field was produced by an RCA pass may cite this method.

### 5.3 Composition with `discovery-discipline.md`

**Direction:** Inverse temporal anchors. Discovery fires at activity-**entry** (*"what should this be? what might fail?"*); RCA fires at activity-**exit** (*"why did this fail?"*). A post-failure context (`discovery-discipline.md` §3.3) is the hand-off seam: discovery surfaces *whether the failure exposed a premise problem* (a Tier 0 candidate); RCA root-causes the *defect itself*. Cross-reference rule: a post-failure RCA that surfaces a decayed premise routes that premise to discovery's open-question register.

### 5.4 Composition with `decision-discipline.md`

**Direction:** RCA is review-class, parallel to decision-class. `decision-discipline.md` §intro places root-cause chains in the reviewer audience. An RCA output that recommends a remediation hands the *decision* (which remediation, at what reversibility tier) to decision-discipline. Cross-reference rule: a remediation decision derived from an RCA record cites the RCA artifact in its evidence.

---

## Section 6 — Anti-Patterns

Three RCA-specific anti-patterns, each authored per the 5-field template in [`failure-mode-standard.md`](../standards/failure-mode-standard.md). Each carries one category tag (TRIG / INPUT / PROC / OUT / HAND).

### 6.1 Symptom-only closure — PROC

- **Signature (observable signal):** An RCA record closes at the observable signal ("the link is broken", "the test failed") with no proximal cause and no systemic-pattern classification — step 2 and step 3 are skipped, and the record reads as a one-line symptom note.
- **Conditional:** do NOT close an RCA at the observable signal when the proximal cause and systemic pattern have not been established, because a symptom-only record produces a point-fix that lets the pattern recur — the exact failure [`review-discipline-principles.md` §2](review-discipline-principles.md) rejects, and the reason RCA exists as a method rather than a log.
- **Root cause:** Closure pressure + the symptom being the most visible artifact. Recording what broke feels like progress; walking the chain to the systemic pattern is several harder steps, so the agent stops at the visible terminal.
- **Mitigation:** Treat step 4's falsification test as the stop condition, not step 1's signal. After naming a cause, ask *"if removed, would the symptom recur?"* — a "yes" means the chain is incomplete. A record that has not classified the systemic pattern (step 3) is not a closed RCA.
- **Principal response vs. junior response:** Principal walks symptom → proximal → systemic, classifies the pattern, and produces a fix scoped to the pattern class. Junior records "the link was broken, fixed it" and the same broken-reference pattern surfaces three more times because the systemic cause (refs not updated on rename) was never named.

### 6.2 RCA-at-intake (boundary violation) — HAND

- **Signature (observable signal):** A defect with an unknown cause lands at the intake front door, and the intake conversation performs the causal walk inline — eliciting reproduction details, forming hypotheses, classifying the pattern — instead of emitting `owner: root-cause` and stopping.
- **Conditional:** do NOT perform the RCA causal walk inside the intake interview when a defect's cause is unknown, because intake **authors-and-hands-off** (per [ADR-016 §3](../ADRs/ADR-016-intake-front-door-architectural-boundary.md)) — RCA is a *processing* act that needs context (logs, history, the codebase) the intake conversation does not gather, and root-causing inline both over-runs the intake loop and produces a thinner cause than a processing surface would.
- **Root cause:** Helpfulness over-reach at the front door — having surfaced a defect, root-causing it feels like finishing the job; the agent conflates *capturing* the defect (intake's verb) with *processing* it (delivery-engine / ppm-agent's verb).
- **Mitigation:** At intake, when a defect's cause is unknown after one re-elicitation, emit `[ASSUMPTION – CONFIRM] <unknown cause> — owner: root-cause — to close: RCA per core/disciplines/root-cause-analysis.md` and stop. The downstream processing surface invokes this method with the context intake cannot gather.
- **Principal response vs. junior response:** Principal emits a clean `owner: root-cause` hand-off and lets the processing stage root-cause with full context. Junior interviews the user for a stack trace, guesses at the cause, and files a bug whose stated cause the processing stage must discard and redo.

### 6.3 Pattern-of-one inflation — OUT

- **Signature (observable signal):** A single defect's RCA record is promoted to a [`failure-mode-standard.md`](../standards/failure-mode-standard.md) anti-pattern entry — a new failure-mode is authored on the evidence of one occurrence, with no second same-signature instance.
- **Conditional:** do NOT promote a single defect to a failure-mode entry via RCA when only one same-signature instance exists, because the emergence rule (N≥2 same signature) gates promotion — a pattern with one member is a *finding*, not a *pattern* (per [`review-discipline-principles.md` §3](review-discipline-principles.md): "a pattern with fewer than 2 member findings is a single finding, not a pattern — demote it").
- **Root cause:** Pattern-hunger + the failure-mode template being the most durable home available. A clean root cause feels like it deserves permanence, so the agent reaches for the anti-pattern catalog before the second instance has appeared.
- **Mitigation:** Route a single-instance RCA to a *finding* (step 6 finding path), not a failure-mode entry. Hold it as a finding until a second same-signature instance surfaces; only then does the emergence rule authorize a failure-mode entry whose "Root cause" field this RCA fills.
- **Principal response vs. junior response:** Principal files the single instance as a finding and waits for emergence before authoring an anti-pattern. Junior authors a failure-mode entry on a sample of one, inflating the catalog with a "pattern" that never recurs and diluting the catalog's signal.

---

## Section 7 — Consumer Binding

The protocol applies workspace-wide per the CLAUDE.md Universal Preferences activation clause. Specific pipeline-instance owners invoke RCA at the surfaces below.

| Consumer | RCA activity | Output consumed by | Failure mode if RCA not applied |
|---|---|---|---|
| `delivery-engine` Mode A | Root-cause a systemic backlog finding before originating a RAID entry | RAID Log entry (R-DE-### systemic risk) | A systemic risk is logged as a symptom ("42% lack AC") with no cause, so the remediation treats the symptom and the pattern recurs |
| `delivery-engine` Mode E | Root-cause a slip / regression surfaced mid-execution | Drafted escalation + recommended adjustment | The escalation names the slip but not its cause; the same slip recurs next sprint |
| `intake-desk` | Hand off an unknown-cause defect (`owner: root-cause`) — does NOT perform RCA | Downstream processing stage | Intake root-causes inline with thin context, or drops the unknown |
| define / triage | Close a root-cause-owned assumption before bundling | Stage 3 bundling decision | A bug bundles into a release with its cause still unknown; Stage 7/8 surfaces the gap at higher cost |
| `failure-mode-standard.md` authoring | Supply the "Root cause" field for a promoted (N≥2) anti-pattern | Skill `## Domain-Specific Failure Modes` section | The anti-pattern's "Root cause" field is symptom-only, failing G7 content quality |
| `ppm-agent` (Output §6 / §7) | Root-cause a processed defect/blocker before originating a RAID entry, OR hand off `owner: root-cause` | `R-PPM-###` RAID entry, or the downstream processing stage that closes the hand-off | A processed defect is logged as a symptom with no cause (or the blocker is surfaced bare), so the remediation treats the symptom and the defect recurs |
| `pmo-devops-sre` Mode 3 | Root-cause a regression signal before proposing a rollback | Rollback Decision Briefing (the cause is the briefing's evidence) | A rollback is executed without a root-cause record, so the same regression recurs after the next deploy |
| failure-owning pipeline stage (7/8/12/13) | Root-cause a gate failure / post-deploy regression before upstream re-run or rollback | The Tier 2/3 feedback escalation, or the Stage 12/13 rollback authorization | A gate-failure return names the symptom but not the cause; the upstream stage re-runs against an unidentified root cause and the failure re-surfaces at higher cost |

---

## See also

- [`review-discipline-principles.md`](review-discipline-principles.md) — §2 the required root-cause FORMAT this method invokes; §3 the systemic-pattern categories (step 3); §5 the findings-register shape (step 6 finding path). **Cited, never relocated.**
- [`../standards/failure-mode-standard.md`](../standards/failure-mode-standard.md) — the 5-field template; downstream consumer of RCA output (step 6 failure-mode path).
- [`discovery-discipline.md`](discovery-discipline.md) — inverse temporal anchor (activity-entry vs RCA's activity-exit); post-failure composition seam.
- [`decision-discipline.md`](decision-discipline.md) — RCA is review-class, parallel to decision-class; remediation decisions derived from RCA cite the RCA record.
- [`../specs/reversibility-protocol.md`](../specs/reversibility-protocol.md) — reversibility-tier vocabulary for step 5.
- [`../ADRs/ADR-016-intake-front-door-architectural-boundary.md`](../ADRs/ADR-016-intake-front-door-architectural-boundary.md) — §3 the intake hand-off contract that emits `owner: root-cause`.
