---
version: null
date: 2026-06-23
type: plan
issues: ["#1870", "#1875", "#1876"]
pr: null
links:
  note: null
  log_anchor: "#declarative-gating-model"
reversibility-tier: MODERATE
themes: ["cluster:templates-schemas"]
---

# declarative-gating-model Release Plan

**Milestone:** declarative-gating-model
**Release Class:** `novel` (operator-rendered at the Stage 4 Decision Gate, 2026-06-23). Basis: a new meta-schema construct (#1870) + a likely Stage-5 founding ADR + D-class plan decisions (D-Version, D-C topology, founding-ADR disposition) — three independent `novel` triggers.
**Version:** **version-less (theme-named)** — operator elected (Stage 4) to ship this research-led milestone WITHOUT a version tag (over the hub-recommended minor bump). No atomic version claim at Stage 12; release branch is `release/declarative-gating-model`; Stage 13 closes a theme-named milestone.
**Branch Topology:** `D-C SINGLE` (operator-rendered, 2026-06-23) — one release branch `release/declarative-gating-model`; only #1870 commits (the spikes produce findings comments, no commits). This plan is committed as the first Engineering commit (Commit 0).
**Differentiation posture (per `novel`):** Engagement density Standard; Stage 9 review depth Deep; Stage 5 activation bias ALL; Stage 13 outcome-window 30-day. Reversibility MODERATE / Confidence HIGH.

---

## Summary

A **3-item research-led release** that de-risks the declarative cross-methodology gating model. Two parallel research spikes (#1875 gate-landscape, #1876 schema-feasibility) produce **findings notes, no commits**; one story (#1870) is the **only repo-mutating work** — it edits `core/schemas/work-item-type-schema.md` plus a founding ADR. The defining asymmetry: the spikes reduce to a **Stage-5 Research-Methodology-Design shape** (per ADR-011) and **skip Stages 6/7/8/10/11/12 entirely**; #1870 runs the full engineering pipeline. Wave 1 (spikes, parallel) → Wave 2 (#1870, post-verdict). No hard blockers exist between any items — sequencing is **soft "feeds" ordering enforced by the wave structure**, not native GitHub blockers.

---

## Dependency Graph

Directional graph (→ = "feeds / must precede"). All edges are **soft ordering**; **zero hard GitHub blockers** (every issue body declares `Dependencies: None (hard blocker)`).

```
        #1875 (gate-landscape spike, size:M) ──┐
              │ (soft: composes inventory)     │
              ▼                                 │ (soft: both feed)
        #1876 (schema-feasibility spike) ──────┼──► #1870 (status-axis story, size:L)
              ▲                                 │
              └─ parallel siblings (Wave 1) ────┘
                                                │
                                                ▼
                                   [#1870 Stage-5 Solutioning consumes
                                    #1876's one-vs-two-construct verdict
                                    + version-bump/ADR finding]
```

| Edge | Type | Enforcement |
|---|---|---|
| #1875 → #1876 | **SOFT** (parallel, composes-where-available) | None needed — both launch together in Wave 1. #1876 uses #1875's inventory opportunistically, does not block on it. |
| #1875 → #1870 | **SOFT** (feeds design) | Wave sequence: #1870 Stage 5 must not start until Wave 1 lands. |
| #1876 → #1870 | **SOFT, load-bearing for Stage 5** | Wave sequence (hard procedural gate at the **Stage-5 boundary of #1870**, even though not a native issue blocker). |
| #1870 ↔ #1803 | **OUT OF SCOPE** | #1803 is the field-axis sibling, **not in this milestone**. Its flagged concurrent-edit collision with #1870 **does not apply this release**. |

The coupling is genuine but ordering-only — the spikes are research that *informs* #1870's design, not artifacts #1870 *imports*. The wave structure is the correct enforcement surface, not GitHub `blocked-by` links.

---

## Implementation Sequence

**Wave 1 — Research spikes (parallel, runnable now, no commits):**
1. **#1875** — Stage-5 Research-Methodology spike: cross-methodology gate landscape. Deliverable = findings note (per-archetype gate inventory + status/field/other classification + common-abstraction recommendation + feasibility verdict).
2. **#1876** — Stage-5 Research-Methodology spike: type-pack meta-schema modeling feasibility. Deliverable = feasibility finding (construct sketch + lifecycle_behavior/EAD composition + cycle-safety model + version-bump-vs-ADR + ADR-warranted verdict).

   Run **#1875 + #1876 concurrently** (parallel-safe — output channel is a findings comment, no file/commit contention).

**Wave-1 → Wave-2 gate (procedural, not a native blocker):** Both spikes' verdicts land — specifically #1876's **one-vs-two-construct verdict** and **version-bump/ADR finding**. This is the gate at **#1870's Stage-5 entry**.

**Wave 2 — Story (post-verdict, full pipeline, repo-mutating):**
3. **#1870** — relationship-conditioned status gating. Stage 5 consumes Wave-1 findings → authors design + founding ADR → Stage 6 edits the schema file + the ADR → Stages 7/8 verify → Stage 13 closes.

---

## Stage Applicability Matrix

The two spikes are **research artifacts** — they legitimately reduce to a Stage-5-flavored shape and skip the engineering/testing/execute stages because **their deliverable is a findings comment, not a commit** (both bodies: "Affected Files: None").

### #1875 — Spike: cross-methodology gate landscape (`type:spike`, size:M)

| Stage | Verdict | Rationale |
|---|---|---|
| 5 Solutioning | **APPLY (as the spike's primary mode)** | The spike *is* Stage-5-class work — the **Research-Methodology Design variant** (ADR-011). Its findings note IS the Stage-5 output. |
| 6 Engineering | **SKIP** | No code/schema change committed (`Affected Files: None`). |
| 7 Dev Testing | **SKIP** | No implementation to test. |
| 8 QA Testing | **SKIP** | No build artifact to QA. |
| 9 Plan Review | **REDUCE (findings acceptance)** | Operator/hub accepts the findings + feasibility verdict as the design-ready handoff. |
| 10/11 | **SKIP** | No shippable artifact. |
| 12 Execute | **SKIP** | Nothing to merge/tag. Mark #1875 as closed at Stage 13. |
| 13 Close | **APPLY (close-only)** | #1875 marked as closed at Stage 13; findings referenced from #1870's design. |

### #1876 — Spike: type-pack meta-schema modeling feasibility (`type:spike`, size:M)

| Stage | Verdict | Rationale |
|---|---|---|
| 5 Solutioning | **APPLY (as the spike's primary mode)** | Same Research-Methodology-Design shape (ADR-011). The technical-feasibility spike — its construct sketch, cycle-safety model, and version-bump-vs-ADR + ADR-warranted verdict are the load-bearing Stage-5 inputs to #1870. |
| 6 Engineering | **SKIP** | `Affected Files: None`. |
| 7 Dev Testing | **SKIP** | No implementation. |
| 8 QA Testing | **SKIP** | No build artifact. |
| 9 Plan Review | **REDUCE (verdict acceptance)** | Operator accepts the one-vs-two-construct + version-bump/ADR verdict. This verdict is the gate input to #1870's Stage 5. |
| 10/11 | **SKIP** | No shippable artifact. |
| 12 Execute | **SKIP** | Nothing to merge/tag. Mark #1876 as closed at Stage 13. |
| 13 Close | **APPLY (close-only)** | Marked as closed at Stage 13; verdict cited by #1870's design + the founding-ADR decision. |

### #1870 — Story: relationship-conditioned status gating (`type:story`, size:L)

| Stage | Verdict | Rationale |
|---|---|---|
| 5 Solutioning | **APPLY (full, gated on Wave 1)** | The only item that runs a *standard* Stage 5. Surfaces the exact schema construct, edge-resolution + cycle-safety rule, and version-bump-vs-ADR. Authors the founding ADR here. `novel`-class ⇒ Stage-5 activation bias = ALL. |
| 6 Engineering | **APPLY** | The repo-mutating work: edits `core/schemas/work-item-type-schema.md` and writes the founding ADR file. Single Engineering chip (SINGLE topology). |
| 7 Dev Testing | **APPLY** | Verify the schema construct against #1870's 6 ACs (grep the `criteria.gate` grammar for the new construct; archetype-neutrality; both worked instances; cycle-safety rule; axis1_state_machine binding; GitHub-adapter reference). Governance/schema "tests" = AC-assertion + `deploy.sh --check`. |
| 8 QA Testing | **APPLY** | Cross-output coherence: §7.2/§7.4/ADR-018 neutrality held; the ADR is durable-kernel per the slim-ADR discipline. |
| 9 Plan Review | **APPLY (Deep — `novel`)** | `novel` ⇒ Deep Stage-9: blast-radius + design-spec conformance + Empirical Verification. PR diff is the dry-run review. |
| 10/11 | **APPLY (as pipeline defines for a shipping item)** | #1870 produces a shippable schema edit → standard release-prep applies. |
| 12 Execute | **APPLY** | Version-less: no atomic version claim. Merge #1870's PR. |
| 13 Close | **APPLY** | #1870 marked as closed at Stage 13 with the release-corpus close. |

**Skip-justification summary:** Stages 6/7/8/10/11/12 are skipped for **both spikes** because a research spike emits a findings comment, not a tracked-file change. The spikes do **not** skip Stage 5: they *are* Stage-5 Research-Methodology-Design work (ADR-011). Stage 9 **reduces** (not skips) for the spikes. Only #1870 traverses the full 5→13 path.

---

## Contention Map

| File | #1875 | #1876 | #1870 | Within-release contention? |
|---|---|---|---|---|
| (findings comment only) | findings | findings | — | None — GitHub comments, no shared write surface |
| `core/schemas/work-item-type-schema.md` | — | — | **EDIT** | None *this release* (sole editor) |
| founding ADR (`core/ADRs/ADR-NNN-*.md`) | — | — | **ADD** (new file) | None (new file) |
| operator-local type-pack config (K4) | — | — | (out of git tree) | N/A — not tracked |

**Within-release contention: NONE.** Only #1870 commits, so there is no concurrent-edit collision inside this release.

**#1803 collision — explicitly N/A this release.** #1803 is NOT in this milestone; #1870 is the sole editor of `work-item-type-schema.md` here. (Forward note for whoever bundles #1803: sequence it against the now-shipped #1870 state.)

**Scope correction (Wave-1 accepted):** The original story body named three schema files. The Wave-1 boundary finding verified that `core/schemas/gate-criteria-spec.md` and `core/schemas/gate-evaluation-spec.md` are the **release-pipeline G1/G2/G3 triage gates** (zero type-pack-gate semantics) and **DROPPED them from the edit set**. The Stage-6 commit touches exactly one tracked schema file plus the new ADR.

---

## Risk Register

| ID | Risk | Class | Severity | Owner | Mitigation |
|---|---|---|---|---|---|
| R1 | **Wave-2 starts before Wave-1 verdict** — #1870 Stage 5 begins without #1876's verdict, forcing re-design. | dependency | **HIGH** | hub (routing) | Procedure-2 routing must NOT surface #1870's Stage-5 chip until both spikes' findings are accepted. |
| R2 | **Evaluation cycles in mutually-gating items** — A gates on B's status while B gates on A's (A↔B). | rollback / correctness | **HIGH** | design (#1870 Stage 5) | #1870 AC #4 requires a cycle-safety rule (detect-and-refuse). Gate-blocking at Stage 9. |
| R3 | **Release-pipeline-neutrality breach** — the construct accidentally couples to platform release-pipeline stages (§7.2 / ADR-018 kernel). | scope / correctness | **HIGH** | design + Eng (#1870) | Construct MUST express gates in methodology workflow statuses (`axis1_state_machine`, keyed off project `lifecycle`), never release-pipeline stages. Stage-9 Deep review verifies. |
| R4 | **Hardcoded-sprint-presumption** — the gate encodes cadence/sprint/phase semantics on the kind instead of keying firing off the project `lifecycle` (§7.4). | scope / correctness | MEDIUM | design (#1870) | Construct must be archetype-neutral and fire per project `lifecycle`. Stage-5 design + Stage-9 review check. |
| R5 | **One-construct-vs-two ambiguity** — if status-criteria and field-criteria don't unify, #1870's construct shape is uncertain until #1876 verdict. | dependency | MEDIUM | research (#1876) | #1876's explicit deliverable is the one-vs-two verdict. Wave sequence ensures #1870 designs against the resolved verdict. |
| R6 | **Founding-ADR over/under-production** — an ADR authored when not warranted (governance debt) or omitted when warranted. | scope | MEDIUM | architecture (#1870 Stage 5) | Per ADR-sliced-into-hub-spoke + slim-ADR discipline: ADR authored by #1870's Stage-5 spoke as a version-agnostic decision kernel, only if warranted. Operator confirms at Stage 9. |
| R7 | **Spike scope creep** — a spike drifts from findings into implementation. | scope | LOW | research (spikes) | Stage Applicability Matrix pins spikes to SKIP Engineering. Hub does not route a Stage-6 chip for #1875/#1876. |
| R8 | **Rollback complexity** — #1870 ships a meta-schema change consumed by gate-evaluating surfaces; a bad construct propagates. | rollback | LOW-MEDIUM | Eng (#1870) | Reversibility of the schema edit: MODERATE (git revert of the PR; no runtime data migration since adapter config is K4/operator-local). Single-PR isolation keeps the revert atomic. |
| R9 | **AC-currency drift** — #1870's AC cites `#409` (closed) grammar + section anchors that may have moved. | dependency | LOW | planning/Stage-5 | Currency gates at Stage-4 entry reconcile AC context against current schema state. Verify the cited section anchors still resolve before #1870 Stage 5. |

The three #1870-specific architectural constraints (R2 cycle-safety, R3 release-pipeline-neutrality §7.2/ADR-018, R4 hardcoded-sprint-presumption §7.4) are the gate-blocking ones — #1870 cannot pass Stage 9 with any of them unaddressed.

---

## Operator Decisions (D-decisions, recorded at Stage 4)

- **D-ReleaseClass:** `novel` (confirmed) — new meta-schema construct (#1870) + Stage-5 founding ADR.
- **D-Version:** **version-less (theme-named)** — operator elected to ship this research-led milestone WITHOUT a version tag (over the hub-recommended minor bump). Consequences: no atomic version claim at Stage 12; release branch `release/declarative-gating-model`; Stage 13 closes a theme-named milestone. Reversibility: CHEAP pre-Engineering / HIGH.
- **D-C Branch Topology:** SINGLE — only #1870 commits; spikes produce no commits. Reversibility: CHEAP / HIGH.
- **Founding ADR:** authored at #1870 Stage 5 (not pre-written), gated on #1876's ADR-warranted verdict. Per ADR-sliced-into-hub-spoke + slim-ADR discipline: version-agnostic decision kernel only. Reversibility: CHEAP pre-write / HIGH (immutable once merged → EXPENSIVE to retract, which is why the warranted-verdict gate precedes authorship).

**Authorization-scope enumeration (this plan's approval):** Operator approval of this Stage-4 plan authorized: (1) the wave structure + implementation sequence; (2) launching Wave-1's 2 parallel spikes as Stage-5 Research-Methodology spokes; (3) the Class `novel` confirmation; (4) version-less theme-named milestone; (5) SINGLE branch topology. It did **NOT** authorize: #1870's Stage-5 design content (separate Stage-5 review), the founding-ADR's *existence* (gated on #1876's verdict), or any schema edit (Stage-6, post-Stage-5).

---

## Quota Budget

**Verdict:** **PASS** (per quota-budget-protocol.md Checkpoint A). The only parallel wave is Wave-1 (2 size:M spikes); Stages 7/8 for #1870 are single-spoke (no parallel draw). Checkpoint B re-validates at runtime before the Wave-1 launch.

---

## Hub empirical verification (R1, Stage 4)

3 schema-file targets exist at plan time (work-item-type-schema 265L / gate-criteria-spec 629L / gate-evaluation-spec 298L) · ADR-011 present in `release/ADRs/` with gate-toothed §7.1 + §12 in stage-05 spec · both spikes declare `Affected Files: None` · scaffolding precedent confirmed — all CONCUR. (The Wave-1 boundary finding subsequently narrowed the edit set to `work-item-type-schema.md` only.)

---

## Out-of-scope discoveries (noted, not acted on)

- **#1803 forward-sequencing:** when the field-axis sibling #1803 bundles into a future release, it must be sequenced against the *now-shipped* #1870 state on `work-item-type-schema.md`.
- **Epic next slice:** post-Wave-1, the epic's design + founding-ADR + per-methodology children become sliceable on the verdict evidence (held out of this release).
