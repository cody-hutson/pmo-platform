<!-- reference-durability: allow-link -->
# Decision Briefing — the hub's operator-engagement contract (Mode R and Mode O)

How the hub engages the operator at any human touchpoint. **Every obligation in this file — the briefing shape, the adversarial-evaluation rule, the information-sufficiency gates, and the channel rule — binds Mode R and Mode O alike.** Where a section names a Mode O mechanism, read its Mode R counterpart: a spoke output stands for a composed-check verdict. Elaborates `## Mode O` and `## Output Contract` in [`../SKILL.md`](../SKILL.md); cites `release/references/how-to/hub-spoke-bridge.md` § Operating Principle for the worked examples.

> **Path convention in this file.** A repo path written as **text** (`core/…`, `release/…`) names a file that is **not deployed with this skill** — it resolves in the repository and would fail from the installed tree, so it is deliberately not a link. A **markdown link** names a file that *is* deployed beside this one and resolves at runtime. Everything this file needs in order to decide whether to open an operator gate is reachable by the second kind.

## Principle

At every human touchpoint the hub distills spoke outputs + release state into a **decision-ready briefing**, and never routes to the next action until the operator has rendered every decision in it. The briefing covers:
1. **Decisions required** — skip recommendations, accepted risks, scope changes, disposition choices, trade-offs. Each carries: context · spoke recommendation · hub evaluation (concur / diverge + rationale) · final recommendation · **reversibility tier + confidence** (`CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE` paired with `HIGH` / `MEDIUM` / `LOW`, per `## Output Contract` requirement 5 in [`../SKILL.md`](../SKILL.md)) · routing impact.
2. **Findings that change the release plan** — new risks, dependency shifts, scope expansions.
3. **Status summary** — what completed, quality assessment, blockers.
4. **Action items surfaced at this routing point** — per `core/standards/hub-action-tracking.md`.
5. **Events emitted this routing point** — the `pipeline-event-log.md` rows this routing point wrote, one line per emission. Subsection format: `| event_type | event_subtype | actor | subject | payload (leading token) |`. Emission is mandatory per [`orchestration-playbook.md`](orchestration-playbook.md) **Procedure 4a**; this subsection is its forcing function — it makes the write observable in the operator-facing artifact, exactly as item 4 does for the action-item scan. When the routing point genuinely rendered no decision, it reads *"No decision rendered at this routing point — no event emitted"*. **Omission is a structural defect**, and a subsection claiming rows the log does not contain is a worse one — the log is the evidence, the briefing is the claim. Event type/subtype mapping is canonical in `core/standards/hub-session-continuity.md` § 3.2; this file does not duplicate it.

## Adversarial evaluation (R1)

Spokes recommend from deep implementation context; the hub interrogates each recommendation against release-wide concerns + disconfirming evidence. **Concurrence requires empirical verification** — the hub either runs the verification itself (reads the cited file / runs the cited command / samples the cited data) and cites the result, or it diverges pending operator clarification. Concurrence-without-verification is a non-compliant briefing.

## Gate 0 — gate-eligibility precondition (runs before the sufficiency gates)

**MUST-pass, and logically prior to the numbered gates — it does not renumber them.** Before constructing a briefing or issuing an `AskUserQuestion` (or an equivalent in-chat mechanism), the hub classifies the candidate action and confirms it is **gate-eligible**. The sufficiency gates below fire only for a candidate that *survives* this one. Gate 0 asks *should this gate exist at all*; gates 1–5 ask *is it sufficiently informed*; [Gate 6](#gate-6--prompt-obligation-runs-after-the-sufficiency-gates) asks *this decision was handed over — where is its affordance*.

**The classification has two inputs, consulted in order. Both live here**, beside the gate that reads them, so classification never depends on a file that is absent from the installed skill tree.

**Input 1 — Stage-to-Autonomy-Tier mapping.** Resolve the candidate action's **Autonomy Tier**. An action whose effective tier is **Autonomy Tier 2 (Bounded Auto)** or **Autonomy Tier 3 (Autonomous, within an approved-plan / Standing-GO scope)** is **NON-gate-eligible** — the hub executes it and reports the observable state change.

| Stage | Autonomy Tier (pre-gate / post-gate) | Auto-launch via Agent tool? |
|---|---|---|
| Stage 2 Triage | Tier 2 | YES |
| Stage 3 Bundle | Tier 2 | YES |
| Stage 4 Planning | Tier 2 | YES |
| Stage 5 Solutioning | Tier 2 | YES |
| Stage 6 Engineering | Tier 0 (pre-scope-lock) → Tier 3 (post-scope-lock) | NO before Collective Review approval; YES after |
| Stage 7 Dev Testing | Tier 2 | YES |
| Stage 8 QA Testing | Tier 2 | YES |
| **Stage 9 Plan Review** | **Tier 0 (Manual; permanent — Irreducible Human Tasks item 4)** | **NEVER** |
| Stage 10 Dry Run (compressed) | (N/A — git-native) | N/A |
| Stage 11 Snapshot (compressed) | (N/A — git-native) | N/A |
| **Stage 12 Execute** | **Tier 0 (gate; Irreducible Human Tasks item 5) → Tier 3 (post-authorization)** | **NEVER at gate; YES for post-authorization deploy steps** |
| Stage 13 Close | Tier 3 (post Stage 12) | YES |

**Input 2 — Standing-GO Authorization list.** Stage 9 GO is the operator's irreducible release-authorization decision, and it authorizes whole-package execution of every mechanical state-flip downstream of GO — not a per-step gate. Each action below is **Tier-1 mechanical work under the standing GO** and is therefore **NON-gate-eligible** after Stage 9 GO: no per-step operator gate, no operator request.

| Action | Mechanism | Tier |
|---|---|---|
| Merge release PR to main | `gh pr merge <PR>` | Tier-1 (executed at Stage 12, Phase B) |
| Signed-annotated tag push | `claim-version.sh` atomic claim + signed tag | Tier-1 (executed at Stage 12, Phase B3) |
| Stage 12 chore PR merge (RELEASE_LOG row + visible-H4 Deployment Log) | `gh pr create` + `gh pr merge` | Tier-1 (executed at Stage 12, Phase B5) |
| Stage 13 chore PR merge (INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG VERIFIED transition) | `gh pr create` + `gh pr merge` | Tier-1 (Step 4 verification pre-conditions) |
| Step 4 completion-verification reads | the enumerated `gh api` / `git log` / `gh issue list` commands | Tier-1 (Step 4) |
| Step 4 gate-passage proof comment recording | `gh issue comment <stage-13-subtask>` | Tier-1 (Step 4) |
| **Milestone close** | `gh api repos/{REPO}/milestones/<N> -X PATCH -f state=closed` | **Tier-1 (Step 5)** |
| Step 6 orphan-state cleanup chip spawn | spawn the cleanup chip; the `--apply` is the operator's own gate | Tier-2 within Tier-1 (the spawn is hub Tier-1; the `--apply` is register row 12) |

The consequential, hard-to-reverse step (merge to main) executes under the Stage 9 GO at Stage 12; everything downstream is reversible mechanical state recording. **Operator agency carve-out:** the operator MAY perform any of these manually if they choose — the codification eliminates the *requirement*, not the *option*. The hub does not request them; it executes and reports.

**Gate-eligible iff** the action is one of the touchpoints enumerated in the **Hub Gate Register** ([`orchestration-playbook.md`](orchestration-playbook.md)) whose `Gate-eligible` column reads `yes` — **or** a genuinely novel / ambiguous situation the framework does not resolve.

- **"Tier" disambiguation (mandatory in the durable text).** "Tier" in this gate means **Autonomy Tier** (`core/specs/autonomy-tiers.md`). An **Inter-Stage-Feedback Tier-2 scope change** or **Tier-3 plan rejection** is **gate-eligible** — it escalates and produces a briefing — and is **NOT** a Bounded-Auto execution. The two Tier conventions point opposite directions at this action class; never write a bare "Tier 2/3" here.
- **Two MUST-pass exits:** **(a) NON-gate-eligible** → suppress the gate, execute the action under its standing authorization, and emit the declarative report form *"Doing X because [rule / Standing-GO row]. Next: Y"*, recording per the Decision Log Mechanism if a decision was implied. **(b) Gate-eligible** → proceed to gate 1. A candidate the hub cannot classify against either input is **treated as gate-eligible** (fail-safe toward operator visibility) AND flagged in the briefing as an unclassified touchpoint, so the register can be extended.
- **Reversibility cross-check (inherited).** An Autonomy-Tier-2/3-classified action that is **IRREVERSIBLE** cannot be auto-executed under Gate 0 — it re-enters the gate-eligible path per `core/specs/autonomy-tiers.md` Boundary Test 3. Gate 0 does not weaken the irreducible-human floor.
- **Warn→enforce posture.** Gate 0 ships **warn-mode-initial**, consistent with the gate-3 `[STRUCTURAL-DEFECT: unrendered-gate]` precedent below, and rides the `shadow→warn→enforce` ladder; its telemetry is the unauthorized-gate metric (`core/disciplines/decision-discipline.md` § 6, metric 5, target 0/release). In **shadow**, a suppressed-eligibility hit is logged only. In **warn**, the hub executes and emits the suppressed-gate notice — **except** that for a NON-gate-eligible action whose **reversibility is MODERATE or worse**, the notice is emitted **before** executing (*"suppressing gate for X under [Standing-GO row]; proceeding unless you object"*), so the control's weakest mode is weakest only where a mistake is cheap to undo; CHEAP mechanical state-flips keep the execute-then-notice behavior. In **enforce**, an attempt to render a NON-gate-eligible gate HALTS and converts to execute+report. Re-presenting a NON-gate-eligible action as a gate is the `FM-2` tier-inflation / governance-theater failure.

## The 5 information-sufficiency gates (satisfied before any `AskUserQuestion`)

A briefing is *information-sufficient* before it renders:
1. **Pre-load referenced spec content** — read the actual content of every spec / rule / schema / register entry the briefing cites, this session (not the title, not a remembered summary).
2. **Enumerate the full option space**, including **stance-implied options** — an option the operator's prior corrections / standing preferences imply must appear, even when the hub recommends a different one.
3. **Render the full briefing in chat BEFORE the structured prompt** — the `AskUserQuestion` options are a selection affordance over a briefing the operator has already read in full, never the first place the decision content appears.
   - **Self-gate (run it while composing, before the prompt leaves):** *for every decision this prompt asks the operator to render, is that decision's full item-1 content already rendered in chat — in this turn, or unchanged earlier in this exchange — above the prompt?* A decision whose content lives only in the option labels has not been briefed; render it first.
   - **Declared deferral (the legitimate consolidated-briefing form — preserved):** the hub MAY carry a decision forward to a later consolidated briefing instead of briefing it where it surfaces. To do so it states, in the turn where the decision surfaces, **what is pending and which touchpoint will carry the briefing — and that touchpoint must be operator-facing, one that actually reaches the operator, never an internal or self-directed check** — and opens **no** `AskUserQuestion` on it there. Deferring is a decision not to *prompt* yet — never a licence to prompt on unrendered content.
   - **The discriminator, stated totally.** Three predicates, and every combination of them named. The table is **total by construction**, which is the structural property: a taxonomy that names only the cases someone thought of acquires a silent pass for the case nobody did, and that is exactly how `abdication` went unnamed while occurring.

     | briefing rendered | prompt fired | consolidation touchpoint named | verdict |
     |---|---|---|---|
     | yes | yes | — | **compliant** |
     | no | yes | — | **skip** — defect (a prompt fired on unrendered content) |
     | — | no | yes, and operator-facing | **deferral** — legitimate |
     | **yes** | **no** | **no** | **`abdication`** — defect |
     | no | no | no | **silence** — defect (the decision never reaches the operator at all) |

   - **`abdication`** — a full briefing rendered, a decision named as the operator's, no prompt fired, and no consolidation touchpoint named — is typed **`[STRUCTURAL-DEFECT: abdicated-decision]`**, inheriting the warn-mode-initial posture of the `[STRUCTURAL-DEFECT: unrendered-gate]` marker. **Its severity sits with `silence`, not below `skip`:** both let the run advance past a decision the operator never got to render, and `skip` at least leaves an affordance. It reads as disciplined restraint — *"I'm not asking now; the run proceeds as recorded"* — which is why naming it is the fix. Deferring is a decision not to *prompt* yet; it is never a licence to advance on a decision that was handed over and then dropped.
4. **Stance-scan pre-check** — scan prior corrections / standing directives / the active correction set; confirm each stance-implied option is present, or explicitly excluded with a reason.
5. **Spec-content-loaded self-check** — confirm gate 1 actually happened for each citation; hold + load the source if not, rather than rendering on a remembered summary.

## Gate 6 — prompt obligation (runs after the sufficiency gates)

**MUST-pass.** A turn that names a decision as the operator's MUST end in exactly one of:

- **(a)** a structured prompt on that decision; **or**
- **(b)** a declared deferral naming the pending item **and** an operator-facing consolidation touchpoint; **or**
- **(c)** a Gate-0 reclassification to NON-gate-eligible, executed and reported.

A turn that names a decision as the operator's and does none of the three is **`[STRUCTURAL-DEFECT: abdicated-decision]`**.

**Gate 6 adds no asking.** Limb (b) is the declared deferral gate 3 already sanctions, and limb (c) is Gate 0's own NON-gate-eligible exit. The only outcome Gate 6 forbids is the residual third one — the decision handed to the operator and then left with no affordance at all. Where Gate 0 suppresses gates that should not exist, Gate 6 catches decisions that were named and never rendered; the two bracket the sufficiency core from opposite sides, and neither raises the engagement level on its own.

**Why this gate is numbered 6 and sits outside the block above.** The section title *"The 5 information-sufficiency gates"* is cited verbatim by surfaces outside this skill, and the ordinals `gate 3` / `gate 4` / `gate 5` are cited by others. Bracketing with Gate 0 and Gate 6 keeps every one of those citations valid — the numbered set still denotes 1–5 exactly, and no ordinal moves.

## Channel — three surfaces, three roles

Every operator-engagement event renders in **main-thread chat** (via `AskUserQuestion` or an equivalent structured in-chat mechanism). Keep the surfaces distinct:
- **Chip / `Agent` spawn** — work execution *after* a decision.
- **GitHub Issue comment** — decision recording *after* a decision (audit trail).
- **Main-thread chat** — rendering the decision *itself*.

Surface overload (engagement-via-chip, engagement-via-comment) is a structural defect. (Routine-engagement-vs-spawn classification table: `hub-spoke-bridge.md` § Channel.)
