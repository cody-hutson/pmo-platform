<!-- reference-durability: allow-link -->
# Release Manager — Composition Contract, Boundary & Worked-Output Reference

Reference detail for `pmo-release-manager`. The SKILL.md `## Composition`, `## Modes`, `## Output Contract`, and `## Reversibility Discipline` sections are the authoritative contract; this file carries the per-mode invocation/autonomy mapping, the full decision-vs-execution boundary ledger (vs `release-planner`, `release-executor`, and the sibling `pmo-devops-sre`), and the worked Mode 1 / Mode 2 / Mode 3 output frames the SKILL.md summarizes. Read it when authoring a go/no-go briefing, a deploy-tail status report, or a close-out disposition, or when the request brushes the deploy-mechanics / rollback surface.

## 1. Per-mode invocation + autonomy mapping (composed `release-planner` + `release-executor` modes)

Every plan/execute/verify/close mechanism claim in a `pmo-release-manager` output is sourced to one of these invoked modes — a mechanism claim with no composition reference is dropped before output (the compose-not-absorb contract, ADR-019). This Specialist invokes `release-planner` + `release-executor`; it never re-implements the planning or execution engine.

| `pmo-release-manager` mode | Decision the Specialist adds (Release-Manager synthesis) | Composed mode(s) invoked | Consumed from the composed mode | Autonomy / Reversibility |
|---|---|---|---|---|
| **Mode 1 — Go/No-Go Evidence (Stage 9)** | Bind the plan evidence + verification readiness into a GO / NO-GO recommendation for the Stage-9 operator gate. Decides *what the evidence says*; does not self-authorize. | [`release-planner` § Mode A — Backlog Analysis](../../release-planner/SKILL.md) / [`release-planner` § Mode B — Release Planning](../../release-planner/SKILL.md) (read-only) **+** [`release-executor` § Mode B — Verify Release](../../release-executor/SKILL.md) read-only checks | The dep-graph; the Critical Path ([`release-planner` § Mode B — Release Planning](../../release-planner/SKILL.md) → its **Step 5c — Critical-path emit (CPM longest-chain)**); the Risk Register and Cross-Milestone Validation ([`release-planner` § Mode B Output Format](../../release-planner/SKILL.md) → the emitted plan's `## Risk Register` and `## Cross-Milestone Dependency Validation` sections); the read-only verification readiness from `release-executor` Mode B | **Tier 1 — Recommend.** Briefing mutates no state → **CHEAP**; operator GO is the ratification |
| **Mode 2 — Deploy Execution (Stage 12)** | Confirm the gate (Stage-9 GO + approved plan + Dry-Run Record); hand the plan to the engine; consume its gate-ladder + execution result; drive the publish. Does **not** author the plan; does **not** re-run the ladder. | [`release-executor` § Mode A — Execute Release](../../release-executor/SKILL.md) chained with [`release-executor` § Mode F — Publish Release (Layer-1 Dual-Write Surface 1)](../../release-executor/SKILL.md) | Quality-Gate-Ladder result (T1→T2→T3); Mode A execution summary; Mode F publish verdict | **Tier 3 — bounded by the Stage-9/12 operator gate** (autonomous only *after* the GO; Mode A self-halts without the plan/GO). **MODERATE-to-EXPENSIVE** |
| **Mode 3 — Close-out (Stage 13)** | Gate the close on the DEPLOYED row + tag; read the issue-closure audit; render the per-open-issue disposition; authorize the Mode D Apply; optionally drive the note prose-fill. Does **not** re-implement the close-out script. | [`release-executor` § Mode D — Close Release](../../release-executor/SKILL.md) — its **Step 2.5** issue-closure audit — optionally [`release-executor` § Mode E — Author Release Note](../../release-executor/SKILL.md) | The issue-closure audit verdict (clean / N open + list); the planned diffs; the carry-forward disposition; the close outcome | **Tier 3 — bounded by Mode D's operator Apply gate.** **MODERATE/HIGH** → **IRREVERSIBLE** once a downstream release consumes the VERIFIED row |

**Mode C (Rollback) is deliberately NOT invoked.** The rollback *trigger* is `pmo-devops-sre`'s reliability surface, the rollback *decision* is Tier-0 operator-only, and the rollback *mechanism* is `release-executor` Mode C — this Specialist defers all three. Composing Mode C would pull the Release Manager into the deploy-mechanics/reliability surface the boundary below assigns to `pmo-devops-sre`. The exclusion is a boundary statement, not an omission.

**Invocation mechanism.** Operator/hub-explicit Skill-tool invocation at cascade-depth 0→1→2 (operator/hub → `pmo-release-manager` → `release-planner` | `release-executor`, terminal). Neither composed skill is on the C7 auto-cascade allowlist (comms-writer / delivery-engine / tracker-manager / artifact-generator), and governance rule **C5** additionally bars auto-cascade to `release-executor` because its outputs touch governance/state files — so the chain to the composed skills is always operator/hub-explicit, never an automatic cascade. Depth stays ≤ 2 by construction (the C1 bound): `pmo-release-manager` does not chain a composed skill onward into a third skill.

## 2. Decision-vs-execution boundary ledger — who owns what

The line that keeps `pmo-release-manager`, its two composed function-skills, and the sibling `pmo-devops-sre` from cross-firing. `pmo-release-manager` **composes** `release-planner` + `release-executor` (does not subsume them) and is a **sibling** to `pmo-devops-sre` (the pair is trigger-deconflicted; this build closes the seam `pmo-devops-sre` flagged from its side).

| Skill | Role | Owns | Does NOT own | Relationship to `pmo-release-manager` |
|---|---|---|---|---|
| **`release-planner`** (shipped) | function-skill — the planning engine (read-only) | The plan/dep-graph/CPM/Risk-Register/Cross-Milestone-Validation **mechanisms**; the authoritative release-plan file | The **go/no-go *decision***; any state mutation beyond the plan file (read-only by contract — [`release-planner` § Operating Principles](../../release-planner/SKILL.md)) | **Composed (invoked, never absorbed).** The go/no-go evidence substrate; the Release Manager binds its read-only evidence into the recommendation |
| **`release-executor`** (shipped) | function-skill — the execution *engine* | The deploy/verify/close/publish **mechanisms** — Quality-Gate Ladder, snapshot/write-verify, Mode A execute, Mode B verify, Mode C rollback, Mode D close, Mode E/F notes/publish, Mode G pattern-review | The **role-level decision** of *whether* the release ships, *when* it is done — it executes an approved plan; it is not a Release Manager | **Composed (invoked, never absorbed).** The engine; the Release Manager sequences and authorizes it for the tail. C5-barred from auto-cascade → invoked operator-explicitly |
| **`pmo-release-manager`** (this skill) | role Specialist | The **go/no-go decision** (evidence assembly / recommendation), the **deploy authorization + tail sequencing** (Stage 9 → 12 → 13), the **close-out disposition** | The deploy *mechanics* + reliability *triggers* (those are `pmo-devops-sre`); the execution *mechanism* (`release-executor`); the *design* of what ships (Stage 5); the *plan* (`release-planner` Mode B) | — (this skill) |
| **`pmo-devops-sre`** (shipped) | role Specialist | The deploy **mechanics** (pipeline/gate/rollout-cycle wiring), the post-deploy verification *read*, the reliability/rollback **trigger** | The **go/no-go *decision***; the release-tail orchestration / close-out (those are the Release Manager) | **Sibling, named collision surface.** Both compose `release-executor`. Line = **decision-vs-execution**: the Release Manager decides go/no-go + sequences the tail; `pmo-devops-sre` runs the deploy mechanics + owns reliability/rollback triggers |

**The decision-vs-execution line, stated precisely (the "no false cross-fire" target):**
- A request about **"is this safe to ship / should we go" / "assemble the go-no-go evidence" / "drive the deploy" / "close the release"** → `pmo-release-manager` (decision + tail).
- A request about **"configure/run the deploy pipeline / set up the rollout / we have a regression, trigger the rollback / is the deploy healthy"** → `pmo-devops-sre` (mechanics + reliability triggers).
- The seam: the Release Manager **assembles the evidence, makes the go/no-go the operator ratifies, and sequences the function-skills that execute it**; `pmo-devops-sre` **runs the deploy mechanics on the go/no-go the operator / Release Manager already made**. The ambiguous overlap (*"drive the deploy"* vs *"run the deploy"*) resolves by **altitude**: the Release Manager *authorizes + sequences*; `pmo-devops-sre` *runs the mechanism it is handed*.

**Why this is not absorption (vs `release-planner` + `release-executor`):** `release-planner` stops at *producing read-only plan evidence*; `release-executor` stops at *executing an approved plan + its gates / verifying / closing*. `pmo-release-manager` begins one altitude up — it owns the *Release-Manager judgment* (does the evidence say GO, is the gate satisfied, what disposition does each open issue take at close) that neither composed skill produces. The three are layered, not overlapping; the Release Manager composes the mechanisms rather than re-deriving them.

## 3. Worked Mode 1 output (illustrative — go/no-go evidence)

> **Audience:** operator. **Decision Briefing — Go/No-Go recommendation (awaiting Stage-9 ratification).**
> **Scope:** v[X.Y] bundles N issues across milestone #M [SOURCE: `release-planner` Mode B plan].
> **Dep / critical path:** chain length 4, no cross-milestone violations [SOURCE: `release-planner` Mode B `### Critical Path` + `### G3-07 Status` = PASS].
> **Risk register:** 1 open MODERATE risk (mitigation owned, due [RECOMMENDED date]); 0 EXPENSIVE+ [SOURCE: `release-planner` Mode B `## Risk Register`].
> **Verification readiness:** `release-executor` Mode B read-only checks = ready (no blocking post-state drift) [SOURCE: `release-executor` Mode B].
> **Recommendation:** **GO** — load-bearing evidence clears; the one open MODERATE risk is mitigated and not blocking.
> **Reversibility:** CHEAP · confidence: HIGH — the briefing mutates no state; the operator GO is the ratification.
> **Autonomy:** Tier 1 — Recommend (operator ratifies at the Stage-9 gate; this skill does not self-authorize the deploy).

## 4. Worked Mode 2 output (illustrative — deploy execution)

> **Audience:** operator. **Action:** deploy-tail driven per Stage-9 GO.
> **Gate confirmed:** Stage-9 GO present + approved plan with Dry-Run Record [SOURCE: release plan + PR review state] — precondition satisfied before chaining the engine.
> **Execute:** `release-executor` Mode A applied the approved plan; Quality-Gate Ladder T1 (schema) PASS, T2 (cross-ref) PASS, T3 (operator GO) PASS [SOURCE: `release-executor` Mode A summary].
> **Publish:** `release-executor` Mode F emitted the Surface-1 release-notes publish [SOURCE: `release-executor` Mode F verdict].
> **Reversibility:** EXPENSIVE · confidence: HIGH — reversal requires a coordinated rollback after downstream consumers read the new state; rollback *mechanism* = `release-executor` Mode C (`git revert -m 1` of the release PR git-native / snapshot-restore Cowork), rollback *decision* = Tier-0 operator + `pmo-devops-sre` (this skill does not initiate it).
> **Autonomy:** Tier 3, bounded by the Stage-9/12 operator gate (executed under the standing GO; this skill did not self-authorize).

## 5. Worked Mode 3 output (illustrative — close-out disposition)

> **Audience:** operator. **Close-out disposition (awaiting Apply authorization).**
> **Deploy-landed gate:** DEPLOYED row present in `RELEASE_LOG.md` [SOURCE: `release-executor` Mode D pre-flight] — this row is the gate; Stage-12 confirmed before close. Annotated tag v[X.Y] recorded present [CONTEXT: the same pre-flight *records* tag state and does not gate on it — the tag blocks later, at the GitHub-Release publish phase].
> **Issue-closure audit (Step 2.5):** 2 open on milestone #M [SOURCE: `release-executor` Mode D Step 2.5]:
> - #A — auto-close-anomaly (shipped in the release PR, close-keyword missed) → **close at apply** (operator-authorized).
> - #B — bundled-but-unshipped (scope deferred) → **defer to carry-forward** (status-deferred label, milestone removed, stays OPEN).
> **Planned diffs:** RELEASE_LOG DEPLOYED → VERIFIED, INDEX + DIGEST append, NOTES scaffold, chore PR, Milestone close [SOURCE: `release-executor` Mode D dry-run].
> **Reversibility:** MODERATE · confidence: HIGH at close — chore PR revertable via `git revert <merge-SHA>`, Milestone re-openable, per-issue closures reversible. Escalates to **IRREVERSIBLE** once a downstream release consumes this VERIFIED row as its baseline.
> **Autonomy:** Tier 3, bounded by Mode D's operator Apply gate. **Authorize close?** Only on explicit GO does this skill authorize the Mode D Apply.

These are illustrative — the values are not platform facts; they show the required shape (audience-framing, every mechanism claim sourced to a composed `release-planner` / `release-executor` mode, the operator gate load-bearing on every state-mutating action, the per-open-issue close-out disposition, reversibility tier + confidence + autonomy tier on every decision-class item).
