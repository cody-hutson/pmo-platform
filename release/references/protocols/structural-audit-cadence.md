---
title: Structural Audit Cadence
purpose: When-to-re-run cadence policy for the structural audit axis (event-bound triggers + 90-day fallback)
type: protocol
related: AUDIT_FRAMEWORK.md (how-to-run methodology, Session 1 Structural & Behavioral Audit — core/standards/), process-fitness-cadence.md (sibling process-fitness axis), platform-health-audit-framework.md (sibling Anthropic Base-vs-Build axis — §2), architecture-conformance-cadence.md (sibling architecture-conformance axis), analysis-workspace-standard.md (analysis-folder output convention — core/standards/)
effective-date: 2026-06-29
scope: The structural audit axis only — Diátaxis conformance / NARA naming / ISO 15489 / orphan files / cross-reference integrity. Not the process-fitness axis (see process-fitness-cadence.md) and not the Anthropic Base-vs-Build axis (see platform-health-audit-framework.md §2).
owner: PMO Cowork Platform Team
---
<!-- reference-durability: allow-link -->

# Structural Audit Cadence

## §1 Purpose & Scope Boundary

This protocol defines **when to re-run** the **structural audit** — the recurring review that tests whether the repository's documentation structure still conforms to its structural reference frames (Diátaxis information typing, NARA / ISO 15489 naming, orphan-file detection, cross-reference integrity). It is the *recurrence layer* (cadence policy) on top of the audit-execution methodology; it does not restate that methodology.

**Scope boundary — cadence policy, not methodology.** The *how-to-run* a structural audit (the 7 audit dimensions, the ~30-min Session 1 "Structural & Behavioral Audit" that produces `AUDIT_STRUCTURAL.md`) lives in [`AUDIT_FRAMEWORK.md`](../../../core/standards/AUDIT_FRAMEWORK.md) (Session 1). This doc adds only the *when-to-re-run* trigger set, the time-based fallback, the output home, and the benchmark-continuity rule. Read `AUDIT_FRAMEWORK.md` for the dimensions; read this for the cadence.

**Continuous-vs-periodic layering.** Cross-reference integrity (one structural dimension) is already covered **continuously between audits** by the link-check CI gate; this 90-day cadence is the **periodic deep** structural audit across *all* structural dimensions (Diátaxis typing, naming conformance, orphan detection, plus cross-references). `[INFERRED]` The two are complementary, not redundant: CI catches a single broken link the moment it lands; the periodic audit catches structural drift the CI gate does not test (mis-typed docs, naming-convention erosion, accumulated orphans).

**Axis boundary.** This is one of **four sibling audit-cadence axes** (see §7):

| Axis | Cadence doc | Conformance frame |
|---|---|---|
| **Structural** (this doc) | `structural-audit-cadence.md` | Diátaxis · NARA · ISO 15489 · ADR · Keep-a-Changelog |
| Process-fitness | `process-fitness-cadence.md` | PMBOK 7 · DORA · Stage-Gate · ITIL 4 · Lean · CD |
| Anthropic Base-vs-Build | `platform-health-audit-framework.md` §2 | Anthropic skill-catalog overlap |
| Architecture-conformance | `architecture-conformance-cadence.md` | Delivered work vs platform architecture (ADR corpus · cross-chain index · architecture-overview) |

The four axes are deliberately separate — distinct benchmark rosters, distinct triggers — and mutually cross-referenced so the full audit surface is discoverable from any one of them.

---

## §2 Event Triggers

A structural re-audit fires when **any** of the following occurs (fire at the trigger's semantic moment — do not wait for the §3 fallback):

| Trigger | Condition |
|---|---|
| **T1** | A **milestone close affecting structural dimensions** — file moves, directory restructure, or any change to where content lives (the close-out touched the tree, not just content). |
| **T2** | A **release start** — a new release run begins, providing a natural checkpoint to confirm the structure is sound before the release's changes land. |
| **T3** | A **major taxonomy change** — a change to the label model, folder convention, or a naming standard that the structural frames are benchmarked against. |

`[INFERRED]` These triggers are the events that plausibly move structural conformance; routine single-file content edits do not qualify and are left to the §3 fallback.

---

## §3 90-Day Time-Based Fallback

Independent of the §2 events, a structural re-audit fires on a **90-day staleness clock**: if the most recent structural audit (the latest `analysis/tree-audit-YYYY-MM-DD/` folder, or an equivalent `last_audited` anchor) is **more than 90 days old**, the audit is due. `[INFERRED]` The fallback guarantees a floor on recurrence even when no §2 event fires — the same belt-and-suspenders shape the Anthropic axis uses (`platform-health-audit-framework.md` §2).

---

## §4 Analysis-Folder Output

A structural audit run emits one **dated analysis subfolder**:

```
analysis/tree-audit-YYYY-MM-DD/
```

per the in-repo [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md), **continuing the inaugural `tree-audit-2026-04-18` lineage** (the named exemplar in that standard). This is **operator working material, not shipped corpus**: the repo-root `analysis/` folder is git-ignored except its README, so the audit folder is **produced by an audit run at runtime, never authored as tracked content**. The date stamp uses **UTC** (`date -u +%Y-%m-%d`) — see §6 for the LOCAL-schedule / UTC-folder split.

Expected contents (per the analysis-workspace-standard §2 convention):

- `SUMMARY.md` — top-level report carrying the analysis frontmatter (`analysis_type: audit`, `work_item`, `created`, `sunset`, `status`); records the prior-audit baseline anchor and the current conformance read per frame.
- `issue-drafts/NNN-kebab-name.md` — drift findings in **observation format** (`observation.yml` 3-field schema — findings are observations until the operator triages them on GitHub).
- optional `_scores/` / `evidence/` support folders.

---

## §5 Benchmark Continuity

Each re-audit **continues the prior tree-audit's reference-frame roster** so results are comparable across runs rather than re-derived each time. The structural roster:

| # | Reference frame |
|---|---|
| 1 | Diátaxis (information-type conformance — tutorial / how-to / reference / explanation) |
| 2 | NARA (file/record naming conventions) |
| 3 | ISO 15489 (records management) |
| 4 | ADR (architecture-decision-record discipline) |
| 5 | Keep-a-Changelog (changelog structure) |

The roster is the **continuity contract**: a run measures the same frames the prior run did, and the `SUMMARY.md` records each frame's conformance read so drift between runs is visible. Adding a frame is itself a benchmark change (note it in the run's `SUMMARY.md`); removing one requires a rationale in the same place.

---

## §6 Mechanism (HYBRID)

The cadence runs as a **HYBRID** of manual event-triggers and an automated staleness sentinel — the same split the Anthropic axis runs (`platform-health-quarterly-audit` + `platform-health-drift-watch`, `platform-health-audit-framework.md` §2):

- **Manual (event-driven).** The §2 triggers (T1–T3) fire **manually at their semantic moment** — the operator or spoke who closes a structure-affecting milestone, starts a release, or lands a taxonomy change invokes the audit.
- **Automated (time-driven).** The §3 90-day fallback is an [`mcp__scheduled-tasks`](../../../core/governance/OPERATIONS.md) **staleness sentinel** that checks the age of the latest `analysis/tree-audit-*` anchor and routes a due-audit signal to an observation draft.

**Inherited conventions** (from the Anthropic-axis precedent — do not unify):

- The sentinel **schedule is evaluated in the user's LOCAL timezone**, while the audit-folder date stamp uses **UTC** (`date -u`). This LOCAL-schedule / UTC-folder split is intentional.
- The sentinel's completion notification is **per-run** (`notifyOnCompletion`), so a due/overdue result self-routes to an observation issue-draft rather than relying on a conditional ping.

**`[ASSUMPTION – CONFIRM]`** Sentinel **registration** (creating the `mcp__scheduled-tasks` job) is an **operator-instance build step** (Stage 12), not committed corpus — the registration carries an instance-local path and is not portable. This tracked doc states the **policy** (a 90-day staleness sentinel exists and behaves as above); the instance owns the registration.

---

## §7 Cross-References (4-Axis Set)

This cadence is one axis of a four-axis audit-cadence set; all four mutually cross-reference:

- **Sibling — process-fitness axis:** [`process-fitness-cadence.md`](process-fitness-cadence.md) (PMBOK 7 / DORA / Stage-Gate / ITIL 4 / Lean / CD).
- **Sibling — Anthropic Base-vs-Build axis:** [`platform-health-audit-framework.md`](platform-health-audit-framework.md) §2 (Anthropic skill-catalog overlap cadence).
- **Sibling — architecture-conformance axis:** [`architecture-conformance-cadence.md`](architecture-conformance-cadence.md) (delivered work vs the platform architecture baseline — the retrospective complement to the forward per-ticket architecture-fit gate).
- **Methodology (how-to-run):** [`AUDIT_FRAMEWORK.md`](../../../core/standards/AUDIT_FRAMEWORK.md) Session 1 — the Structural & Behavioral Audit dimensions this cadence schedules.
- **Output convention:** [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md) — the analysis-folder home, frontmatter, and sunset rule.
- **Continuous complement:** the link-check CI gate is the continuous between-audit detector for the cross-reference-integrity dimension (§1 layering note).

**Governance cross-ref (consistency surface).** `[ASSUMPTION – CONFIRM]` The session-start *lightweight drift check* (the "Context drift detection" universal preference in `CLAUDE.md`) and this *periodic deep structural audit* are complementary halves of one discipline — the lightweight check runs every session on key governance claims; this audit runs the deep structural sweep every 90 days / on §2 events. An additive cross-reference paragraph in the `CLAUDE.md` "Context drift detection" preference pointing to this cadence is the intended consistency-surface touch. **`CLAUDE.md` is a governance file and lives outside this repo from a Stage-6 spoke's vantage; that edit is therefore flagged here as a governance touch for the Stage-9 review — it is NOT made by this spoke.**

---

## §8 Reversibility

**CHEAP** (confidence: **HIGH**). This protocol adds a new tracked doc plus non-destructive cross-reference edits to a sibling framework (and a flagged-but-deferred additive governance paragraph). The only runtime artifacts are git-ignored analysis folders and an operator-instance sentinel registration. Undo = delete the doc and revert the cross-ref lines (minutes, no data loss, no stakeholder impact).

---

**End of cadence protocol.**
