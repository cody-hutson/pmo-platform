<!-- reference-durability: allow-link -->
# pmo-ocm-lead — Composition & Lifecycle Reference

This reference holds the granular composition contract for `pmo-ocm-lead`: the verbatim mode → composed-`change-management`-mode citation map (the Stage 5 load-bearing deliverable) and the lifecycle-gate dependency model the modes enforce. The SKILL.md `## Modes` section is the operating contract; this file is the detailed citation surface it derives from. Both are consumed by the composing skill via invocation, never re-implemented (ADR-019).

## 1. Mode → composed `change-management` mode map (with evidence)

Every `pmo-ocm-lead` mode is a **role-level orchestration** over one or more `change-management` modes, invoked through the `core/` registry skill-chain (ADR-007) — never inline-reimplemented. The composed `change-management` modes are owned by `change-management`; the line citations below pin the live source as of the v2.12 build.

| pmo-ocm-lead mode | Composes `change-management` mode(s) | Evidence (`change-management/SKILL.md`) |
|---|---|---|
| **Mode 1 — Change Impact** | **Mode A** (Change Impact Assessment); ingests an existing matrix via **Mode E** (Change Matrix Ingestion) when one is supplied | `:158` (A), `:288` (E) |
| **Mode 2 — Training & Adoption** | **Mode B** (Training Plan) + **Mode G** (Adoption Tracking — ADKAR barrier/timing, champion ratio, sponsor engagement) | `:183` (B), `:338` (G) |
| **Mode 3 — Readiness Go/No-Go** | **Mode C** (Readiness Checklist → READY / CONDITIONAL / NOT READY) | `:207` (C) |
| **Mode 4 — Hypercare & Adoption Outcome** | **Mode D** (Hypercare Plan — tiered risk register, SLA-compliance, exit gate) + **Mode G** (adoption-outcome / deployed-vs-adopted) | `:231` (D), `:338` (G) |
| **Mode 5 — Change Comms Program** | **Mode F** (CM Communications Schedule — the *schedule*; Mode F routes individual drafts to `comms-writer` via its `[COMMS]` handoff) | `:313` (F) |

Coverage vs. the issue's worked examples: Impact→A, Training→B, Readiness→C, Hypercare→D, Comms→F — all honored, with Mode E folded into impact entry (matrix ingestion) and Mode G folded into training and hypercare (adoption instrumentation). `change-management` Mode D's exit gate (`:256`) and the Mode G deployed-vs-adopted failure mode are the cited hardening Mode 4 carries forward.

## 2. Lifecycle-gate dependency model

The role's defining value is the **gated lifecycle** — the cross-mode ordering no single `change-management` mode enforces. The dependency edges:

```
Mode 1 (impact) ──┬─→ Mode 2 (training/adoption)
                  └─→ Mode 3 (readiness)          [readiness depends on impact completeness — FM-2]
Mode 2 (training/adoption) ─→ Mode 3 (readiness)  [readiness depends on training completeness — FM-5]
Mode 3 (readiness verdict) ─→ Mode 4 (hypercare)  [hypercare depends on the readiness verdict — FM-5]
Mode 2 (Mode G adoption instrumentation) ─→ Mode 4 (adoption-outcome horizon)
Mode 5 (comms) anchored across all gates         [each comms milestone names its upstream artifact dependency]
```

Two intra-mode gates carry the same discipline:
- **ADKAR-ordering gate (Mode 2, FM-1):** Knowledge/Ability training (composed Mode B) is gated on `Awareness ≥4 ∧ Desire ≥4` from the composed Mode G ADKAR assessment. Training below the barrier is deferred; the Awareness/Desire intervention is sequenced first; the training is re-gated when the barrier clears.
- **Deployed-vs-Adopted gate (Mode 4, FM-4):** before each adoption KPI's horizon the verdict is NO-DATA = "deployed, not yet proven", never MET; hypercare stays open while any SLA event is OPEN past its committed resolution.

A whole-program request runs the modes in lifecycle order (1 → 2 → 3 → 4 → 5) as one coherent workflow; a direct single-mode ask whose upstream artifacts are absent triggers push-to-resolve (the downstream mode invokes its upstream mode first — FM-5).

## 3. Compose-not-absorb posture (ADR-019)

`pmo-ocm-lead` is the resolved **overlap pair** OCM Lead ↔ change-management (one of the 4 named ADR-019 overlap pairs). It holds no standalone change mechanics — every impact, training, readiness, hypercare, adoption, and comms function is invoked on `change-management` and its output consumed. The `## Composition` table in SKILL.md is the contract; every change claim in an output cites the composed mode it derives from, or it is dropped before output. Routing depth stays ≤2 (operator/router → `pmo-ocm-lead` → `change-management`). `change-management` is not on the 4-skill cascade allowlist — the same posture the live `pmo-technical-program-manager` operates under; the allowlist governs unattended Tier-2 auto-cascades (C1–C7), not a Specialist's documented chained call.
