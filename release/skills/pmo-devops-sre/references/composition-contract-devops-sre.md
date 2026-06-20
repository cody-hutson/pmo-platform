<!-- reference-durability: allow-link -->
# DevOps / SRE — Composition Contract, Boundary & Worked-Output Reference

Reference detail for `pmo-devops-sre`. The SKILL.md `## Composition`, `## Modes`, `## Output Contract`, and `## Reversibility Discipline` sections are the authoritative contract; this file carries the per-mode invocation/autonomy mapping, the full decision-vs-execution boundary table (vs `release-executor` and the future `pmo-release-manager`), and the worked Mode 2 / Mode 3 output frames the SKILL.md summarizes. Read it when authoring a deploy-execution or rollback-trigger output, or when the request brushes the go/no-go decision surface.

## 1. Per-mode invocation + autonomy mapping (composed `release-executor` modes)

Every deploy/verify/rollback mechanism claim in a `pmo-devops-sre` output is sourced to one of these invoked modes — a mechanism claim with no composition reference is dropped before output (the compose-not-absorb contract, ADR-019). This Specialist invokes `release-executor`; it never re-implements the execution engine.

| `pmo-devops-sre` mode | Decision the Specialist adds (DevOps/SRE synthesis) | `release-executor` mode(s) invoked | Consumed from the composed mode | Autonomy tier of the action |
|---|---|---|---|---|
| **Mode 1 — Pipeline** | How the pipeline / gates / `rollout-cycle` (shadow→warn→enforce) are wired; which `deploy.sh` flags + auto-detect window apply. A config *recommendation*, not an execution. | **Mode B (Verify)** read-only checks, as inputs only (no destructive surface). | The current verified state; the Quality-Gate-Ladder configuration as read context. | **Tier 1 — Recommend** (operator approves before any config is applied). |
| **Mode 2 — Deploy-Exec** | Select the execution lineage; hand the approved plan to the engine; consume its gate-ladder + verification verdict; report deploy-mechanics status. Does **not** decide go/no-go; does **not** author the plan. | **Mode A (Execute Release)** chained with **Mode B (Verify Release)**. | Quality-Gate-Ladder result (T1→T2→T3); Mode A execution summary; Mode B verification verdict. | **Tier 3 — bounded by the Stage-9/12 operator gate** (autonomous only *after* the operator GO; never self-authorizing — Mode A halts without the plan/GO). |
| **Mode 3 — Reliability** | Detect + classify the regression signal; run Retry → Escalate; *propose* a rollback via a Decision Briefing; execute the rollback only after operator authorization. | **Mode C (Rollback)** for the mechanism (post-authorization only); **Mode B (Verify)** for post-incident re-verification. | Rollback mechanism (snapshot-restore / `git revert -m 1`); post-rollback verification verdict. | **Tier 3 for trigger-*detection*; Tier 0 for the rollback *decision*** (operator-authorized at every invocation per `autonomous-execution-model.md`). |

**Mode D (Close Release) is deliberately NOT invoked.** Close-out (Stage 13 milestone/log/INDEX/DIGEST/NOTES + chore PR) is release-tail orchestration reserved for the future `pmo-release-manager`. Composing Mode D would pull Mode 2 into the Release Manager's tail surface — the exclusion is a boundary statement, not an omission.

**Invocation mechanism.** Operator/hub-explicit Skill-tool invocation at cascade-depth 0→1→2 (operator/hub → `pmo-devops-sre` → `release-executor`, terminal). `release-executor` is **not** on the C7 auto-cascade allowlist (comms-writer / delivery-engine / tracker-manager / artifact-generator), and governance rule **C5** additionally bars auto-cascade to it because its outputs touch governance/state files — so the chain to `release-executor` is always operator/hub-explicit, never an automatic cascade. Depth stays ≤ 2 by construction (the C1 bound): `pmo-devops-sre` does not chain `release-executor` onward into a third skill.

## 2. Decision-vs-execution boundary ledger — who owns what

The line that keeps `pmo-devops-sre`, `release-executor`, and the future `pmo-release-manager` from cross-firing. `pmo-devops-sre` **composes** `release-executor` (does not subsume it) and is a **sibling** to the future Release Manager (deconflicted as a pair at Stage 7 when the RM is built).

| Skill | Role | Owns | Does NOT own | Relationship to `pmo-devops-sre` |
|---|---|---|---|---|
| **`release-executor`** (shipped) | function-skill — the execution *engine* | The deploy/verify/rollback/close **mechanisms** — Quality-Gate Ladder, snapshot/write-verify, Mode A execute, Mode B verify, Mode C rollback, Mode D close, Mode E/F notes/publish, Mode G pattern-review | The **role-level decision** of *which* deploy to run, *when* a reliability signal warrants rollback, *how* the pipeline is configured — it executes an approved plan; it is not a DevOps/SRE | **Composed (invoked, never absorbed).** The engine; `pmo-devops-sre` is the role that drives it for deploy-mechanics + reliability. C5-barred from auto-cascade → invoked operator-explicitly |
| **`pmo-devops-sre`** (this skill) | role Specialist | **Deploy *mechanics* + reliability/rollback *trigger* ownership** — pipeline config (Mode 1), deploy-execution orchestration (Mode 2), reliability response + rollback-trigger (Mode 3) | The **go/no-go *decision*** (operator / future RM / Stage-9 gate); release-tail / close-out (RM / `release-executor` Mode D); the execution *mechanism* (`release-executor`); the *design* of what ships (Stage 5) | — (this skill) |
| **`pmo-release-manager`** (#213/#214, **future** — NOT in this release) | role Specialist | The **go/no-go decision** (#214 evidence-compilation / Go-No-Go preparation) and the **release-tail orchestration** (#213 deployment-execution *capability* at the RM altitude, close-out) | The deploy *mechanics* + reliability *triggers* (those are DevOps/SRE) | **Sibling, named collision surface.** Both compose `release-executor`. Line = **decision-vs-execution**: RM decides go/no-go + orchestrates the tail; DevOps/SRE runs deploy mechanics + owns reliability/rollback triggers. **Trigger-deconflict as a pair at Stage 7** when the RM is built |

**The decision-vs-execution line, stated precisely (the "no false cross-fire" target):**
- A request about **"is this safe to ship / should we go" / "compile the go-no-go evidence" / "close the release"** → Release Manager (decision + tail). **NOT** `pmo-devops-sre`.
- A request about **"run the deploy / push the release through the pipeline / configure the rollout / we have a regression, trigger the rollback"** → `pmo-devops-sre` (mechanics + reliability triggers).
- The seam: `pmo-devops-sre` **executes the decision the Release Manager / operator already made**; it never *makes* the go/no-go. Mirror image of `release-executor`'s own posture ("the plan was the decision; the skill is the executor") one altitude up.

**Why this is not absorption (vs `release-executor`):** `release-executor` stops at *executing an approved plan + its gates*. `pmo-devops-sre` begins one altitude up — it owns the *DevOps/SRE judgment* (which deploy, how the pipeline is wired, when a reliability signal warrants a rollback proposal) that `release-executor` explicitly excludes (it has no model of reliability thresholds, pipeline configuration, or incident response; it executes the plan it is handed). The two are layered, not overlapping; `pmo-devops-sre` composes the mechanism rather than re-deriving it.

## 3. Worked Mode 2 output (illustrative — deploy execution)

> **Audience:** operator. **Action:** deploy executed per Stage-9 GO.
> **Gate confirmed:** Stage-9 GO present + PR #N approved [SOURCE: release PR review state] — precondition satisfied before chaining the engine.
> **Lineage:** git-native PR-merge surface.
> **Execute:** `release-executor` Mode A applied the approved plan; Quality-Gate Ladder T1 (schema) PASS, T2 (cross-ref) PASS, T3 (operator GO) PASS [SOURCE: release-executor Mode A summary].
> **Verify:** `release-executor` Mode B verdict = VERIFIED [SOURCE: release-executor Mode B].
> **Reversibility:** EXPENSIVE · confidence: HIGH — reversal requires a coordinated rollback after downstream consumers read the new state; rollback plan = `git revert -m 1` of the release PR.
> **Autonomy:** Tier 3, bounded by the Stage-9/12 operator gate (executed under the standing GO; this skill did not self-authorize).

## 4. Worked Mode 3 output (illustrative — rollback trigger)

> **Audience:** operator. **Decision Briefing — rollback proposal (awaiting authorization).**
> **Signal:** post-deploy verification FAIL on the reservation read-path [SOURCE: release-executor Mode B] — Dimension 2 content-correctness mismatch; classified as a regression (not a flaky check; reproduced twice).
> **Retry → Escalate:** Retry was not applicable (the failure is a content regression, not a transient); escalated to a rollback proposal.
> **Blast radius:** 2 downstream consumers of the reservation read event; the release is live.
> **Rollback posture:** `release-executor` Mode C snapshot-restore (Cowork lineage) OR `git revert -m 1` of the release PR (git-native) — mechanism owned by `release-executor`, not re-implemented here.
> **Reversibility:** EXPENSIVE · confidence: MEDIUM — a rollback after the release was live; a misread signal would compound the incident.
> **Autonomy:** rollback *decision* is Tier 0 (operator-only). **Authorize?** Only on explicit GO does this skill compose `release-executor` Mode C; it does not auto-initiate.

These are illustrative — the values are not platform facts; they show the required shape (audience-framing, every mechanism claim sourced to a composed `release-executor` mode, the operator gate load-bearing on every state-mutating action, reversibility tier + confidence + autonomy tier on the decision-class item).
