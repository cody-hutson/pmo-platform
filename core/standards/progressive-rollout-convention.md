<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Progressive-Rollout Convention — pipeline-wide

**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Status:** LIVE (milestone `71-autonomy-phaseout-foundation`, v2.12).
**Owns:** the canonical phase enum, the per-phase 4-element contract, and the in-platform audit table for progressive rollout of a governance mechanism.

## Purpose

A governance mechanism — a hook, a deploy-check, a release-executor quality gate, or any predicate that can block, warn, or observe — should not flip straight to blocking the day it ships. It advances through named **rollout phases**, each phase strictly less disruptive than the next, so the operator observes the mechanism's real hit-rate against live work before it ever halts anything.

This convention is the **pipeline-wide canonical definition** of those phases. It is the single home of the phase enum and the per-phase contract; any mechanism that graduates from observe → warn → block cites this convention rather than re-defining the vocabulary. It exists because the platform previously ran **two non-unified rollout ladders** — a 3-cycle `shadow/warn/enforce` model scoped to the release-executor, and a separate `warn/enforce/off` mode machine for the security-hook layer and `deploy.sh --check` — with no pipeline-wide convention and no terminal decommission phase. This convention lifts the established vocabulary to pipeline scope and adds the terminal rung the autonomy-phase-out telos requires.

The companion phase-out schema (the operator-touchpoint inventory) consumes this convention's enum as the domain of its `current_phase` field — the load-bearing consistency contract between the two. Whatever this convention names is what that schema's `current_phase` takes verbatim.

## The phase enum (canonical)

```
shadow → warn → enforce → removed
```

These four values — `shadow`, `warn`, `enforce`, `removed` — are the canonical rollout-phase vocabulary for the whole platform. A mechanism advances **one rung at a time** (never skipping a rung forward) and retreats **one rung at a time** (the CHEAP inverse single edit), except that the terminal `removed` phase re-enters at `shadow`, never silently back at `enforce`.

- The first three phases (`shadow`, `warn`, `enforce`) preserve the existing platform vocabulary verbatim — zero rename of any LIVE usage.
- The fourth phase, `removed`, is the terminal decommission rung. Neither pre-existing ladder had it. It is the autonomy-phase-out telos: the whole foundation exists so a human touchpoint can graduate to `removed` (fully automated or retired).

Rejected: `dark / canary / GA`. That vocabulary is for traffic-percentage rollout (serving N% of requests) and is a poor semantic fit for governance-rule rollout (a rule either observes, warns, or blocks — there is no "5% of releases" dimension); adopting it would also orphan two LIVE usages. See the Evidence-Grounding artifact below.

## The per-phase contract (4 elements per phase)

Every phase is defined by four contract elements: **observable behavior** (what happens at run time), **telemetry contract** (what is recorded), **advance criteria** (what must hold to move to the next phase), and **retreat trigger** (what moves back a rung). All four elements are stated inline per phase below so the contract stands on its own.

### shadow

- **Observable behavior:** The mechanism evaluates its predicate, logs a `would-fire` hit, takes **no** action, and surfaces **nothing** at run time. The action proceeds exactly as if the mechanism were absent.
- **Telemetry contract:** Append-only JSONL hit-log; each line carries `{ts, rule-id, phase: "shadow", verdict: "would-fire", reason, context}`. The established log surface is `core/hooks/<rule-id>-rollout-log.jsonl` (the release-executor realization) / `<rule-id>-warn-log.jsonl` (the hook layer), reusing the platform's per-rule `*-log.jsonl` convention.
- **Advance criteria (→ warn):** The operator reviews the hit-log end-to-end; at least one full observation cycle has accrued; every hit is either a genuine catch or an addressed false-positive (predicate tightened or case allowlisted). **Operator-decided — never auto-promoted by hit-count.**
- **Retreat trigger (← prev):** None — `shadow` is the entry rung. Retreat from `shadow` is `off` / un-deploy (the absence state, not a phase).

### warn

- **Observable behavior:** The mechanism evaluates; on a hit it **emits an operator-facing notice** at run time AND logs, but does **not** block. The action proceeds.
- **Telemetry contract:** The same JSONL surface with `phase: "warn"`, PLUS a run-time notice in the standard form `⚠ <rule-id> would block: <reason>; currently warn — proceeds.`
- **Advance criteria (→ enforce):** The operator confirms readiness to **halt** on this finding; the actionable-finding text tells the next operator exactly how to fix the violation; no unaddressed false-positive remains. Operator-decided.
- **Retreat trigger (← shadow):** Bump back to `shadow` (a single edit) when the warn-notices prove noisy or premature; this restores silent observation.

### enforce

- **Observable behavior:** The mechanism evaluates; on a hit it **blocks** the action with a 5-field actionable finding (and, inside a gate ladder, short-circuits the downstream tiers).
- **Telemetry contract:** A blocked action is its own record; hit-logging is optional. Block events MAY be captured per the mechanism's existing block-log (`<rule-id>-block-log.jsonl`).
- **Advance criteria (→ removed):** The mechanism has run clean at `enforce` long enough that its catches are reliably true-positive AND the gated human-touchpoint is ready to be **retired** (the phase-out target — this is the seam with the touchpoint phase-out schema). Operator-decided.
- **Retreat trigger (← warn):** Bump back to `warn` (a single edit) — this restores non-blocking observation immediately. This is the documented CHEAP rollback of an over-eager block.

### removed

- **Observable behavior:** The mechanism (or the human gate it guarded) is **decommissioned** — the predicate no longer runs; the touchpoint it enforced is fully automated or deleted. This is the convention's terminal rung.
- **Telemetry contract:** Decommission is recorded **once** in the audit trail / phase-out record (the touchpoint-inventory row flips `current_phase: removed` with a dated decommission note). There is no ongoing run-time telemetry — the mechanism is gone.
- **Advance criteria:** None — terminal.
- **Retreat trigger:** Re-introduce as `shadow` (**NOT** a silent jump back to `enforce`). Re-instating a removed mechanism re-enters the ladder at the bottom so its renewed hit-rate is re-observed before it can block again. This is the load-bearing safety property of having a named terminal phase.

## Advance is an operator decision

Advancement is always an **operator decision, never auto-promoted by a numeric hit-count threshold.** A low hit-count does not establish that the remaining hits are false positives; the operator's judgement on the log is the gate. The operator records each advance by editing the mechanism's phase value — the attribute change IS the audit record of the decision. Retreat is the inverse single edit. This mirrors the platform's existing warn-to-enforce shakedown transition for security hooks, with one extra `shadow → warn` rung the two-state precedent lacks and the terminal `removed` rung neither precedent has.

## Reversibility framing

Each phase transition is a reversibility-tiered decision per [reversibility-protocol.md](../specs/reversibility-protocol.md). Advancing toward `enforce` / `removed` raises the stakes (a wrong `enforce` blocks live work; `removed` decommissions a gate); the retreat trigger is the CHEAP inverse single-edit in every case except `removed`, whose re-entry is deliberately routed back to `shadow` rather than a cheap jump to `enforce`. Pair each advance decision with a confidence level (HIGH / MEDIUM / LOW) per the protocol.

## In-platform audit table (existing usages × per-phase conformance)

This table records every existing in-platform rollout usage against the canonical 4-phase contract. Per-phase status: ✅ implemented · ⚠ partial · ❌ absent. The `N-of-4` column counts realized phases; the verdict is `PARTIAL` for any usage below 4-of-4.

| Usage | Home | Phase vocab today | shadow | warn | enforce | removed | N-of-4 | Verdict | Reconciliation action |
|---|---|---|:--:|:--:|:--:|:--:|:--:|---|---|
| release-executor quality-gate ladder | `release/skills/release-executor/references/progressive-rollout.md` + `SKILL.md` `rollout-cycle` column | `shadow/warn/enforce` (3-state) | ✅ | ✅ | ✅ | ❌ | **3-of-4** | **PARTIAL** | Re-point to this convention as canonical enum source; gains `removed` vocabulary by reference |
| security-hook layer (shared `.mode`) — `block-egress.sh`, `block-mcp-writes.sh`, `block-shell-injection.sh`, `block-fs-boundary.sh` | `core/hooks/.mode` + fragments under `core/rules/bypass-mode-readiness/` | `warn/enforce/off` (2-state-plus-off) | ❌ | ✅ | ✅ | ❌ | **2-of-4** | **PARTIAL** | Audit-reference only; the `shadow` retrofit of the hook layer is explicitly OUT OF SCOPE (see below). The convention records the gap; it does not close it |
| `deploy.sh --check` checks (warn-mode-initial) | `core/hooks/deploy-check.mode` + `deploy.sh` mode-gating (`!= "off"`) | `warn/enforce/off` (2-state-plus-off) | ❌ | ✅ | ✅ | ❌ | **2-of-4** | **PARTIAL** | Audit-reference only; same out-of-scope retrofit boundary as the hook layer |
| `block-autonomy-ceiling.sh` (own `.autonomy-mode`) | `core/hooks/.autonomy-mode` | `warn/enforce/off` (2-state-plus-off, own mode file) | ❌ | ✅ | ✅ | ❌ | **2-of-4** | **PARTIAL** | Audit-reference only; note its split posture (Tier-0 floor always-enforce, ceiling check warn-mode-initial) |

**Modal finding (stated plainly):** the platform's modal rollout machinery is a **2-state-plus-off** ladder. The only 3-state usage is the release-executor's, and **nothing realizes the 4th (`removed`) phase**. This convention is forward-looking — it defines the full ≥4-phase ladder; existing usages are graded against it and found PARTIAL, with the gap recorded honestly rather than rounded toward "conformant." This is the audit-baseline + verify-before-recommend disciplines applied: record what IS realized, name what is NOT, round in neither direction.

**Audit-baseline:** the four rows above were re-verified LIVE at commit `f7eee93` (the v2.12 branch baseline, 2026-06-20) — `.mode.template` = `warn`, all four shared-`.mode` hooks present, `deploy-check.mode.template` = `warn`, `.autonomy-mode.template` present, and zero `removed`/`retired`/`sunset` rollout-phase occurrences corpus-wide. Re-check the substrate before relying on the verdicts in a later release.

## Composition with the autonomy framework

This convention does not stand alone — it composes with the platform's autonomy and gate-evaluation surfaces:

- [autonomy-tiers.md](../specs/autonomy-tiers.md) — the Tier 0–3 autonomy framework (the "WHO acts under what authorization" axis). The `enforce → removed` transition IS an autonomy-tier elevation: a Tier-0 human gate becoming Tier-3 autonomous (or retired). The phase ladder is the mechanism-rollout reading; the autonomy tier is the engagement reading of the same graduation.
- [reversibility-protocol.md](../specs/reversibility-protocol.md) — each phase transition is reversibility-tiered (see Reversibility framing above).
- [gate-evaluation-spec.md](../schemas/gate-evaluation-spec.md) — the gate-evaluation routine is the shared object the release-executor ladder dispatches each tier's `would-fire` result through. This convention is the upstream definition of the phase vocabulary that routine's rollout-aware dispatch consumes.
- [autonomous-execution-model.md](../disciplines/autonomous-execution-model.md) — the Retry / Escalate / **Rollback** patterns. The retreat-trigger element of each phase IS the Rollback pattern applied to rollout phase (retreat one rung restores the prior, less-disruptive behavior).

## Relationship to the release-executor realization

The pipeline-wide convention (this file) is the **parent definition**; the release-executor's `progressive-rollout.md` is the **executor-scoped realization**. This convention owns the phase enum, the per-phase contract, and the audit table. The executor reference owns its executor-specific machinery — the `rollout-cycle` column on the gate table, the gate-ladder short-circuit seam, the JSONL outcome-log — and cites this convention as its canonical phase-vocabulary source. The enum is NOT duplicated: per the [duplicate-source-discipline.md](duplicate-source-discipline.md) register-or-remove rule, the enum lives in exactly one canonical home (here), and the executor realization references it.

## Out of scope

- **Retrofitting the security-hook layer / `deploy.sh --check` to a three-state `shadow/warn/enforce`.** Giving the security hooks a silent `shadow` tier touches runtime harness tooling governed by a separate gate. This convention **records** that the hook layer is 2-of-4 PARTIAL; it does **not** close the gap. Do not edit the hook `.mode` files or any hook script under this convention. Route a separate observation ticket if a security-hook `shadow` tier is later wanted.
- **Editing the generated `core/rules/bypass-mode-readiness.md` index.** That file is generated (source = per-hook fragments under `core/rules/bypass-mode-readiness/`, rebuilt per ADR-030). If a per-hook fragment must cite this convention, edit the **source fragment**, never the generated index.
- **Auto-promotion by hit-count threshold.** Advancement stays an operator decision per the advance criteria; canonicalizing a numeric auto-advance threshold is a deliberate non-goal.
- **Migrating any existing usage to `removed`.** This convention defines the terminal phase; actually decommissioning a live touchpoint is the work of the phase-out schema and its per-touchpoint plan, not this convention.

## Evidence-Grounding (per the evidence-grounding standard)

This convention canonicalizes three conventions; each carries the 2-part artifact per [evidence-grounding-standard.md](evidence-grounding-standard.md). Survey performed at commit `f7eee93`, 2026-06-20.

### Canonicalization 1: the phase enum (`shadow / warn / enforce / removed`)

**Current-state enumeration:**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| `release/skills/release-executor/references/progressive-rollout.md` | `shadow`, `warn`, `enforce` (3-cycle) | 1 model | `:19-32` "the three-cycle model"; `:45` allowed values |
| `core/hooks/.mode.template` + `core/rules/bypass-mode-readiness/_cross-cutting.md` | `warn`, `enforce`, `off` (2-state-plus-off) | 1 model | `.mode.template` = `warn`; `_cross-cutting.md` mode section |
| `core/hooks/.autonomy-mode.template` (block-autonomy-ceiling) | `warn`, `enforce`, `off` (own mode file) | 1 model | `bypass-mode-readiness/block-autonomy-ceiling.md` Mode field |
| `deploy.sh --check` | `warn`, `enforce`, `off` | 1 model | `core/hooks/deploy-check.mode.template` = `warn`; `deploy.sh` default `warn` |
| any `removed` / `retired` / `sunset` / `dark` / `canary` / `GA` rollout phase | — | **0** | `grep -rniE "rollout.{0,15}(removed|retired|sunset)" core/ release/` → no rollout-phase match |

**Survey command:** `grep -rniE "rollout.{0,15}(removed|retired|sunset)" core/ release/` (terminal-phase survey); `cat core/hooks/.mode.template core/hooks/deploy-check.mode.template core/hooks/.autonomy-mode.template` (mode-vocabulary survey)
**Survey date:** 2026-06-20 at commit `f7eee93`

**Canonical choice:** `shadow / warn / enforce / removed`

**Canonical-choice justification:**
- Upstream convention: `shadow/warn/enforce` is the established platform vocabulary at 3+ LIVE homes (the release-executor model + the hook `.mode` family + `deploy.sh --check`); the executor's `progressive-rollout.md` "Precedent and non-divergence" section establishes shadow/warn/enforce as the platform's generalization-of-existing-pattern. The 4th phase `removed` is added per the milestone Outcome Statement ("shadow → warn → enforce → removed") — it is the decommission terminal the phase-out telos requires and the value the companion `current_phase` field consumes.
- `dark/canary/GA` rejected: 0 occurrences + traffic-percentage semantics misfit governance-rule rollout.

**Out-of-scope drift detected during survey:**
- `core/schemas/gate-evaluation-spec.md` — does NOT yet reference `rollout-cycle` / `shadow` despite being the gate-evaluation routine the executor ladder dispatches through. Routing: **next-release issue** (wiring `gate-evaluation-spec.md` to cite this convention is a follow-up, not in this milestone's AC set).

### Canonicalization 2: the doc path (`core/standards/progressive-rollout-convention.md`)

**Current-state enumeration:**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| `core/standards/` | cross-module authoring-standard corpus (evidence-grounding, reference-durability, duplicate-source-discipline, …) | 40+ files | `ls core/standards/` |
| `core/governance/` | OPERATIONS-class operating governance only | 2 files (OPERATIONS.md, README.md) | `ls core/governance/` |
| existing rollout doc | `release/skills/release-executor/references/` (skill-scoped) | 1 | `progressive-rollout.md` (executor-internal, not pipeline-wide) |

**Survey command:** `ls core/standards/ core/governance/`
**Survey date:** 2026-06-20 at commit `f7eee93`

**Canonical choice:** `core/standards/progressive-rollout-convention.md`

**Canonical-choice justification:**
- Documented rationale: the CLAUDE.md Governance File Map places knowledge-reference / standards content under the `core/` standards corpus, and `core/governance/` is reserved for OPERATIONS.md-class governance (the map lists only OPERATIONS there). A pipeline-wide authoring convention is a standard, co-located with its sibling disciplines (`evidence-grounding-standard.md`, `reference-durability-standard.md`).

**Out-of-scope drift detected during survey:** none.

### Canonicalization 3: the audit-table schema (per-phase ✅/⚠/❌ matrix + N-of-4 score)

**Current-state enumeration:**

| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| existing conformance-table patterns in corpus | per-criterion / per-check tables (deploy.sh checks; gate-criteria tables) | many | `core/schemas/gate-evaluation-spec.md`; `core/rules/skill-deployment.md` enforcement matrix |
| existing rollout-phase audit table | — | **0** | no prior table inventories usages × rollout-phase |

**Survey command:** `grep -rl "rollout" core/ release/ | xargs grep -l "| shadow"` (existing rollout-audit-table survey)
**Survey date:** 2026-06-20 at commit `f7eee93`

**Canonical choice:** per-phase ✅/⚠/❌ matrix with an explicit `N-of-4` realized-count and a `PARTIAL` verdict

**Canonical-choice justification:**
- Documented rationale: the platform's "prefer durable structures over static examples" + audit-baseline disciplines require a per-dimension matrix with an explicit realized/not-realized score rather than a prose claim or a binary pass/fail (which would mis-grade the 2-state usages — they DO implement warn+enforce correctly, they merely do not implement all four phases). The ✅/⚠/❌ + N-of-4 shape mirrors the per-check conformance tables already used in `deploy.sh --check` reporting.

**Out-of-scope drift detected during survey:** none.

---

### Sources

- `#164` — parent task: establish a pipeline-wide shadow→warn→enforce rollout convention (this file is its AC1/AC2/AC4 deliverable). Milestone `71-autonomy-phaseout-foundation`.
- `#165` — companion task: operator-touchpoint inventory + phase-out plan schema; its `current_phase` field consumes this convention's phase enum (the E1 consistency contract, #164 AC5).
- ADR-034 — records the lift-and-extend decision, the phase-name choice, and the `core/standards/` placement.
