<!-- reference-durability: allow-link -->
# Program Coordinator — Composition & Reversibility Reference

This reference holds the granular composition contract for `pmo-program-coordinator` and its skill-specialized reversibility tier vocabulary. The SKILL.md `## Composition` and `## Reversibility Discipline` sections are the operating contract; this file is the detailed surface they derive from. Both are consumed by the composing skill via invocation, never re-implemented ([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)).

## 1. Composition contract

The Coordinator **composes** two function-skills by **invoking them through the `core/`-registry skill-chain** (runtime chaining), and **re-implements neither** — per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md) (a Specialist composes a shared function-skill by *invoking* it, **not** by copying its logic). The composed skills are read-only to this Specialist; their input contracts, validation, and approval gates are owned by them. The Coordinator adds only the **cross-surface reconciliation** layered on their outputs.

| Composed function-skill | What the Coordinator invokes it for | Interface invoked (owned by the composed skill — NOT re-implemented here) |
|---|---|---|
| [`tracker-manager`](../../tracker-manager/SKILL.md) | The **validated tracker write** — emit `TRACKER_UPDATE` blocks, consume the consolidated change summary for operator approval | The `TRACKER_UPDATE` / `TRACKER_UPDATES` engine (validate → consolidate → present → execute on approval → log). Tier-1 targets stay approval-gated; the Coordinator never bypasses that gate. |
| [`daily-status`](../../daily-status/SKILL.md) | The **status cadence** — generate the Teams-ready update that surfaces carry-forward state | **AM Status Update** · **PM Status Update** · **Daily Connect Prep** (the three cadence modes; each reads the project's Daily Status Update Framework). |

**Compose-not-absorb boundary (ADR-019):** the Program Coordinator does **not** re-derive any tracker-validation logic, change-summary consolidation, or status-template formatting. When a mode "composes `tracker-manager`", it **emits a `TRACKER_UPDATE` block and consumes the consolidated change summary** — it does not re-implement schema validation or the write. When a mode "composes `daily-status`", it **chains to** `daily-status` and consumes the generated update — it does not re-implement the Framework's section-by-section sourcing. The single source for each function stays the function-skill; the Coordinator forks none of it. (Enforced by the DT-3 compose-not-absorb review gate and the cross-skill false-positive harness.)

**Cross-boundary influence (CS-15, calibrated in Phase 1):** the Coordinator is one of the two Phase-1 calibration cases for CS-15 (cross-boundary influence between composed skills). The calibrated rule: **when the `tracker-manager` state and the `daily-status` carry-forward disagree, the Coordinator must surface that divergence as a data-integrity signal for operator adjudication — name the tracker entry, name the carry-forward line, and state the disagreement — rather than silently reconciling to one surface or letting the two run as disconnected passes.** This is the defining behavior of the role (the reconciliation) and the reason CS-15 was deferred to a composing Specialist for calibration: the cross-boundary edge only exists where one composed skill's output (tracker state) feeds another's invocation (the status that should reflect it).

## 2. Reversibility tier vocabulary

These are the skill-specialized instances of the canonical tiers in [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md). Every decision-class output — enumerated per mode in the SKILL.md `## Reversibility Discipline` — carries a tier + confidence.

**Tier vocabulary:**
- **CHEAP** (undo in hours, no stakeholder impact) — the dominant tier here: a tracker correction routed for approval, a carry-forward reconciliation. State the tier, proceed to the approval gate.
- **MODERATE** (undo in days, small cohort) — a reconciliation that changes a reported status a stakeholder has already seen. State the tier, surface the assumption, invite a single-reviewer pass.
- **EXPENSIVE / IRREVERSIBLE** — rare for this role (the Coordinator does not commit irreversible state — the trackers are approval-gated and the status is a message); if a reconciliation would alter an audit-of-record tracker entry, treat it as EXPENSIVE+, name the sign-off authority, and route explicitly.

Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. Because the Coordinator's writes are approval-gated, most calls are CHEAP — but a divergence adjudication the operator acts on without re-checking is exactly where a wrong CHEAP call propagates, so the tier + confidence are stated even on the cheap path.
