---
title: Release Process-Fitness Audit Cadence
purpose: When-to-re-run cadence policy for the release process-fitness audit axis (event-bound triggers + 90-day fallback)
type: protocol
automation_id: [process-fitness-sentinel]
related: AUDIT_FRAMEWORK.md (how-to-run methodology — core/standards/), structural-audit-cadence.md (sibling structural axis), platform-health-audit-framework.md (sibling Anthropic Base-vs-Build axis — §2), architecture-conformance-cadence.md (sibling architecture-conformance axis), analysis-workspace-standard.md (analysis-folder output convention — core/standards/)
effective-date: 2026-06-29
scope: The release process-fitness audit axis only — PMBOK 7 / DORA / Stage-Gate / ITIL 4 / Lean / CD frame conformance of the release pipeline. Not the structural axis (see structural-audit-cadence.md) and not the Anthropic Base-vs-Build axis (see platform-health-audit-framework.md §2).
owner: PMO Cowork Platform Team
---
<!-- reference-durability: allow-link -->

# Release Process-Fitness Audit Cadence

## §1 Purpose & Scope Boundary

This protocol defines **when to re-run** the release **process-fitness audit** — the recurring review that tests whether the release pipeline still conforms to the external delivery-process reference frames it is benchmarked against (PMBOK 7, DORA, Stage-Gate, ITIL 4, Lean, CD). It is the *recurrence layer* (cadence policy) that sits **on top of** the audit-execution methodology; it does not restate that methodology.

**Scope boundary — cadence policy, not methodology.** The *how-to-run* an audit (the 7 audit dimensions, scoring, PASS/PARTIAL/FAIL, the session chain) lives in [`AUDIT_FRAMEWORK.md`](../../../core/standards/AUDIT_FRAMEWORK.md). This doc adds only the *when-to-re-run* trigger set, the time-based fallback, the output home, and the benchmark-continuity rule. Read `AUDIT_FRAMEWORK.md` for the dimensions; read this for the cadence. `[INFERRED]` Splitting cadence from methodology keeps each layer independently editable — a new trigger never forces a methodology edit, and vice versa.

**Axis boundary.** This is one of **five sibling audit-cadence axes** (see §7):

| Axis | Cadence doc | Conformance frame |
|---|---|---|
| **Process-fitness** (this doc) | `process-fitness-cadence.md` | PMBOK 7 · DORA · Stage-Gate · ITIL 4 · Lean · CD |
| Structural | `structural-audit-cadence.md` | Diátaxis · NARA · ISO 15489 · ADR · Keep-a-Changelog |
| Anthropic Base-vs-Build | `platform-health-audit-framework.md` §2 | Anthropic skill-catalog overlap |
| Architecture-conformance | `architecture-conformance-cadence.md` | Delivered work vs platform architecture (ADR corpus · cross-chain index · architecture-overview) |
| Decision-health | `decision-audit-cadence.md` | How the hub and spokes decide — hub decision invariants · named decision failure modes · decision-conduct disciplines |

The five axes are deliberately separate — distinct benchmark rosters, distinct triggers — and mutually cross-referenced so the full audit surface is discoverable from any one of them.

---

## §2 Event Triggers

A process-fitness re-audit fires when **any** of the following occurs (fire at the trigger's semantic moment — do not wait for the §3 fallback):

| Trigger | Condition |
|---|---|
| **T1** | A **major change** to the release pipeline definition — `release/governance/release-process.md` or any `release/references/pipeline/stage-*.md` (stage added/removed/re-sequenced, gate semantics changed). |
| **T2** | A **retrospective surfaces a Tier-2+ process-fitness concern** — a recurring or systemic process gap (not a one-off), per the review-discipline systemic-pattern threshold. |
| **T3** | A **new methodology archetype is added** — a new `delivery_approach` or type-pack (e.g., a new operating model beyond the current Scrum default) that the pipeline must be re-benchmarked against. |

`[INFERRED]` These triggers are the events that can plausibly move conformance against the §5 reference frames; routine content edits (typo fixes, single-doc wording) do not qualify and are left to the §3 fallback.

---

## §3 90-Day Time-Based Fallback

Independent of the §2 events, a process-fitness re-audit fires on a **90-day staleness clock**: if the most recent process-fitness audit (the latest `analysis/release-process-audit-YYYY-MM-DD/` folder, or an equivalent `last_audited` anchor) is **more than 90 days old**, the audit is due. `[INFERRED]` The fallback guarantees a floor on recurrence even in a quiet quarter where no §2 event fires — the same belt-and-suspenders shape the Anthropic axis uses (quarterly cadence + reactive triggers, `platform-health-audit-framework.md` §2).

---

## §4 Analysis-Folder Output

A process-fitness audit run emits one **dated analysis subfolder**:

```
analysis/release-process-audit-YYYY-MM-DD/
```

per the in-repo [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md). This is **operator working material, not shipped corpus**: the repo-root `analysis/` folder is git-ignored except its README, so the audit folder is **produced by an audit run at runtime, never authored as tracked content**. The date stamp uses **UTC** (`date -u +%Y-%m-%d`) — see §6 for the LOCAL-schedule / UTC-folder split.

Expected contents (per the analysis-workspace-standard §2 convention):

- `SUMMARY.md` — top-level report carrying the analysis frontmatter (`analysis_type: audit`, `work_item`, `created`, `sunset`, `status`); records the prior-audit baseline anchor and the current conformance read per frame.
- `issue-drafts/NNN-kebab-name.md` — drift findings in **observation format** (`observation.yml` 3-field schema — findings are observations until the operator triages them on GitHub).
- optional `_scores/` / `evidence/` support folders.

---

## §5 Benchmark Continuity

Each re-audit **continues the prior audit's reference-frame roster** so results are comparable across runs rather than re-derived each time. The process-fitness roster:

| # | Reference frame |
|---|---|
| 1 | PMBOK 7 (principles + performance domains) |
| 2 | DORA (delivery + operational performance metrics) |
| 3 | Stage-Gate (phase-gate decision discipline) |
| 4 | ITIL 4 (service-management / change-enablement) |
| 5 | Lean (flow, waste reduction) |
| 6 | CD — Continuous Delivery (deployment-pipeline discipline) |

The roster is the **continuity contract**: a run measures the same frames the prior run did, and the `SUMMARY.md` records each frame's conformance read so drift between runs is visible. Adding a frame is itself a benchmark change (note it in the run's `SUMMARY.md`); removing one requires a rationale in the same place.

---

## §6 Mechanism (HYBRID)

The cadence runs as a **HYBRID** of manual event-triggers and an automated staleness sentinel — the same split the Anthropic axis runs (`platform-health-quarterly-audit` + `platform-health-drift-watch`, `platform-health-audit-framework.md` §2):

- **Manual (event-driven).** The §2 triggers (T1–T3) fire **manually at their semantic moment** — the operator or spoke who lands a pipeline change, closes a retro with a Tier-2+ concern, or adds a methodology archetype invokes the audit. The audit executor is `pmo-qa-auditor` **Mode F** (the how-to-run home); the latest audit folder's `## Deep-Dive Queue` is the dispatch read surface for borderline-band deep-dives, and the dispatching actor (the operator/spoke here, or the §3 sentinel's routed signal) writes the queue's `dispatched` column when it dispatches — the audit run itself never does.
- **Automated (time-driven).** The §3 90-day fallback is a scheduled **staleness sentinel** that checks the age of the latest `analysis/release-process-audit-*` anchor and routes a due-audit signal to an observation draft. The routine is registered as `process-fitness-sentinel` in [`core/automations/registry.md`](../../../core/automations/registry.md); how it fires resolves at fire time from the operator's `[adapters].scheduler`.

**Inherited conventions** (from the Anthropic-axis precedent — do not unify):

- The sentinel **schedule is evaluated in the user's LOCAL timezone**, while the audit-folder date stamp uses **UTC** (`date -u`). This LOCAL-schedule / UTC-folder split is intentional.
- The sentinel's completion notification is **per-run**, so a due/overdue result self-routes to an observation issue-draft rather than relying on a conditional ping.

**`[ASSUMPTION – CONFIRM]`** Sentinel **registration** (creating the scheduled job) is an **operator-instance build step** (Stage 12), not committed corpus — the registration carries an instance-local path and is not portable. This tracked doc states the **policy** (a 90-day staleness sentinel exists and behaves as above); the instance owns the registration.

---

## §7 Cross-References (5-Axis Set)

This cadence is one axis of a five-axis audit-cadence set; all five mutually cross-reference:

- **Sibling — structural axis:** [`structural-audit-cadence.md`](structural-audit-cadence.md) (Diátaxis / NARA / ISO 15489 / ADR / Keep-a-Changelog).
- **Sibling — Anthropic Base-vs-Build axis:** [`platform-health-audit-framework.md`](platform-health-audit-framework.md) §2 (Anthropic skill-catalog overlap cadence).
- **Sibling — architecture-conformance axis:** [`architecture-conformance-cadence.md`](architecture-conformance-cadence.md) (delivered work vs the platform architecture baseline — the retrospective complement to the forward per-ticket architecture-fit gate).
- **Sibling — decision-health axis:** [`decision-audit-cadence.md`](decision-audit-cadence.md) (how the hub and spokes decide — the retrospective complement to the forward per-decision gates).
- **Methodology (how-to-run):** [`AUDIT_FRAMEWORK.md`](../../../core/standards/AUDIT_FRAMEWORK.md) — the audit-execution dimensions this cadence schedules.
- **Output convention:** [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md) — the analysis-folder home, frontmatter, and sunset rule.

**Operator-local roadmap relationship.** `[INFERRED]` The release-process-fitness *initiative roadmap* is an **operator-local instance** (git-ignored per the roadmap framework-tracked / instances-ignored split, [`initiative-roadmap-framework.md`](../../../core/standards/initiative-roadmap-framework.md)). There is therefore **no in-repo roadmap section to cross-reference**; this cadence doc is the committed home for the process-fitness recurrence policy, and the operator-local roadmap references *this doc* rather than the reverse.

---

## §8 Reversibility

**CHEAP** (confidence: **HIGH**). This protocol adds a new tracked doc plus non-destructive cross-reference edits to a sibling framework; the only runtime artifacts are git-ignored analysis folders and an operator-instance sentinel registration. Undo = delete the doc and revert the cross-ref lines (minutes, no data loss, no stakeholder impact).

---

**End of cadence protocol.**
