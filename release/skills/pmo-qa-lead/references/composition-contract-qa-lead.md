<!-- reference-durability: allow-link -->
# QA Lead — Composition Contract & RECONCILE Boundary Reference

Reference detail for `pmo-qa-lead`. The SKILL.md `## Composition`, `## Modes`, `## Boundary`, and `## Output Contract` sections are the authoritative contract; this file carries the per-mode invocation mapping, the RECONCILE subsumption ledger (the QA-Lead-vs-auditor-hardening boundary stated per issue), the spec-surface-seam detail for Mode 2 / Mode 4, and a worked output. Read it when authoring a Mode 1–4 output or running as a release-QA spoke.

## 1. Per-mode invocation mapping (composed function-skill modes)

Every quality/verdict claim in a QA-Lead output is sourced to one of these invoked modes — a claim with no composition reference is dropped before output (the compose-not-absorb contract, ADR-019). This Specialist invokes; it never re-implements the review.

| QA-Lead mode | Decision the QA Lead adds (QA-leadership synthesis) | Composed mode(s) invoked | Consumed from the composed mode |
|---|---|---|---|
| **Mode 1 — Strategy** | The system-level test strategy + acceptance-scope plan; which risks are load-bearing on the quality posture; where effort concentrates. | `pmo-qa-auditor` **Mode E** (Platform Health Audit); `build-reviewer` *Complexity Assessment* dimension. | Systemic-risk signal over the suite (Mode E); production-readiness proportionality of the pack (Complexity Assessment). |
| **Mode 2 — Acceptance** | The program-level acceptance sign-off (ACCEPT / CONDITIONAL ACCEPT / REJECT); the fitness-beyond-literal-AC read; the Operator Override Record framing for any non-fix NOT-MET. | `pmo-qa-auditor` **acceptance review mode** (live). | Per-criterion verdicts (MET / NOT MET / PARTIAL / N-A / REINTERPRET / FLAG-UPSTREAM); 3-lane routing; Operator Override Record machinery. |
| **Mode 3 — Defect-Governance** | The fix-now / defer / accept disposition per finding; de-duplication across the two reviewers; the program-level defect posture. | `build-reviewer` **findings register + 6-deliverable output**; `pmo-qa-auditor` **Mode A / B**. | Severity, root cause, residual-risk register, remediation priority (build-reviewer); single-output + cross-output coherence findings (auditor A/B). |
| **Mode 4 — Dev-Test** | The dev-test gate decision (advance / iterate / block) bound to the Mode-1 strategy; which conformance gaps are gating vs. noise at the release altitude. | `pmo-qa-auditor` **dev testing mode** (live). | The structural → contract → content → integration eval-ladder result; Stage-7 severity vocabulary; the DT↔Engineering loop. |

**Invocation mechanism.** Manual Specialist-driven Skill-tool invocation at cascade-depth 0→1 (operator → QA Lead → composed function-skill, terminal). NOT the C7 auto-cascade allowlist (comms-writer / delivery-engine / tracker-manager / artifact-generator) — that allowlist governs PPM-triggered Document-Tier-2 auto-writes; neither `pmo-qa-auditor` nor `build-reviewer` is on it and neither is added. Depth stays ≤ 2 by construction (the C1 bound: a target refuses invocation at depth ≥ 2).

## 2. Mode 2 / Mode 4 compose the auditor's acceptance + dev-testing modes (D-QAL-1)

The auditor's **acceptance review** mode and **dev testing** mode are **live**, and Mode 2 / Mode 4 compose them directly — by name — through the invocation mechanism in §1.

**The auditor's mode set is read from its source, never restated here.** The `## Modes` table in [`core/skills/pmo-qa-auditor/SKILL.md`](../../../../core/skills/pmo-qa-auditor/SKILL.md) is the sole authority on which modes the auditor ships; this contract deliberately reproduces neither its membership nor its letter range. Cite an *individual* mode by name — with its letter as a convenience, as §1 does — but never restate the **set** as a literal or a letter range: a frozen mode-set claim goes stale a release after it is written and then misinforms every caller reading this contract to decide what it can compose against.

The **canonical spec-surfaces those auditor modes implement** remain the authority on the machinery itself, and Mode 2 / Mode 4 read them for the mechanics they consume:

- **Mode 2 → Stage-8 §B acceptance machinery** (`release/references/pipeline/stage-08-qa-testing.md`): the per-criterion verdict enum, the 3-lane routing, the Operator Override Record.
- **Mode 4 → Stage-7 §5 dev-testing ladder** (`release/references/pipeline/stage-07-dev-testing.md`): the structural → contract → content → integration eval ladder + the DT↔Engineering loop.

The QA Lead does **not** re-implement either auditor mode; building them inside this Specialist would violate the RECONCILE boundary (§3).

## 3. RECONCILE subsumption ledger — QA-Lead vs auditor-hardening (the named S5 deliverable)

The auditor-hardening work and the QA-Lead Specialist sit on **opposite sides of the invocation seam**. The hardening work EXTENDS `pmo-qa-auditor` *itself* (new modes/detectors/gates INSIDE the auditor's SKILL.md); the QA Lead is a role-composer that INVOKES the auditor (including the very modes the hardening adds) and adds program-level QA leadership. The boundary is **INVOCATION (Specialist → function-skill)** vs. **INTERNAL-EXTENSION (hardening → auditor body)**. This Specialist makes **no edits to `pmo-qa-auditor`** — the auditor's hardened capabilities ship as-is and are inherited by invocation.

| Auditor-hardening item | What it does | Side of the seam | Relationship to QA-Lead |
|---|---|---|---|
| **Acceptance-review mode** (CLOSED, shipped) | EXTENDED `pmo-qa-auditor` with a Stage-8 acceptance mode (ingests AC, per-criterion verdicts) | INSIDE the auditor (shipped) | QA-Lead **Mode 2 INVOKES** this mode. QA-Lead does NOT author the acceptance mode. |
| **Dev-Testing mode** (CLOSED, shipped) | EXTENDED `pmo-qa-auditor` with a Stage-7 dev-test mode (ingests PR + plan, eval ladder, PR-comment) | INSIDE the auditor (shipped) | QA-Lead **Mode 4 INVOKES** this mode. QA-Lead does NOT author the dev-test mode. |
| **8 failure-mode detectors + RACI gate** (CLOSED, shipped) | EXTENDED the auditor's Mode E battery + G9 | INSIDE the auditor (shipped) | QA-Lead **Mode 1 INVOKES** Mode E for the systemic-risk signal. QA-Lead does NOT re-implement the detectors. |
| **KM scanning** — doc-debt / staleness (OPEN) | EXTENDS the auditor with KM-scanning capability | INSIDE the auditor | **Orthogonal** — no QA-Lead mode composes KM-scanning; fully off the compose-path. |
| **RACI validation gate** (CLOSED, folded into the detector-battery G9) | EXTENDED the auditor with G9 | INSIDE the auditor (shipped) | QA-Lead consumes G9 findings transitively via the auditor; does NOT re-implement the gate. |

**Subsumption statement (canonical):** `pmo-qa-auditor` owns the review/acceptance/dev-test/detector/RACI capabilities (the modes, gates, and detectors inside its SKILL.md, including those the hardening work adds). `build-reviewer` owns the production-readiness findings register + the 6-deliverable review discipline. `pmo-qa-lead` owns the program-level **QA-leadership synthesis** — the test strategy, the acceptance sign-off, the defect governance, the dev-test gate — and *composes* both function-skills for the review/finding substrate. The QA Lead does not subsume either; it composes them (ADR-019).

**The boundary in one sentence:** the hardening work sharpens `pmo-qa-auditor`'s own blade (modes / detectors / gates inside its SKILL.md); the QA-Lead Specialist invokes that blade and adds program-level QA leadership — it never reaches inside the auditor to re-implement what the hardening work builds there.

## 4. Worked Mode 2 output (illustrative)

> **Audience:** mixed. **Decision:** CONDITIONAL ACCEPT of the release pack.
> **Acceptance pass** [SOURCE: composed `pmo-qa-auditor` acceptance mode over the GitHub Issue AC]: AC-1 MET, AC-2 MET, AC-3 MET, AC-4 PARTIAL (the new gate ships warn-mode, not enforce — the AC says "enforced"), AC-5 MET, AC-6 N-A (out of this release's scope), AC-7 MET → **6/7 effective, AC-4 PARTIAL**.
> **Sign-off: CONDITIONAL ACCEPT** — the pack meets intent; AC-4's enforce-flip is the documented Shakedown→Enforce step, not a defect. **Fitness-beyond-AC:** the warn-mode posture is the correct calibration default per the bypass-readiness discipline, so the PARTIAL is a deliberate sequencing choice, not a gap.
> **Operator Override Record** (Stage-8 §B — referenced, not re-implemented): AC-4 enforce-flip deferred to the post-shakedown window; landing target named; sign-off authority = the operator.
> **Reversibility:** the ACCEPT authorizes the release to advance → **EXPENSIVE · confidence HIGH** (a shipped release is undone only by a new forward-facing commitment; the conditional carries the rollback posture = revert the deploy if the warn-log surfaces a true positive before flip).

This is illustrative — the values are not platform facts; it shows the required shape (audience-framing, every verdict sourced to the composed acceptance pass, the sign-off bound to the per-criterion verdicts, the Operator Override Record for the non-fix PARTIAL, and a reversibility tier + confidence on the ship-authorizing call).
