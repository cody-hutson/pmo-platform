---
title: Decision-Health Audit Cadence
purpose: When-to-re-run cadence policy for the decision-health audit axis (event-bound triggers + 90-day fallback)
type: protocol
related: decision-audit-mode-spec.md (how-to-run machinery — core/skills/pmo-qa-auditor/references/), decision-audit-dimension-rubric.md (content SSOT — core/skills/pmo-qa-auditor/references/), architecture-conformance-cadence.md (sibling as-built architecture axis), process-fitness-cadence.md (sibling process-fitness axis), structural-audit-cadence.md (sibling structural axis), platform-health-audit-framework.md (sibling Anthropic Base-vs-Build axis — §2), analysis-workspace-standard.md (analysis-folder output convention — core/standards/)
effective-date: 2026-07-27
scope: The decision-health audit axis only — how the release hub and its spokes decide, scored against the hub's decision invariants and the platform's named decision failure modes. Not the as-built architecture axis (see architecture-conformance-cadence.md), not the process-fitness axis (see process-fitness-cadence.md), not the structural axis (see structural-audit-cadence.md), and not the Anthropic Base-vs-Build axis (see platform-health-audit-framework.md §2).
owner: PMO Cowork Platform Team
---
<!-- reference-durability: allow-link -->

# Decision-Health Audit Cadence

## §1 Purpose & Scope Boundary

This protocol defines **when to re-run** the **decision-health audit** — the recurring review
that reads a release window and checks how the hub and its spokes *decided*: whether decisions
were rendered where the governance says they are rendered, whether the evidence for them was
recorded, and whether the platform's own named decision failure modes were detected when their
signatures occurred. It is the *recurrence layer* (cadence policy) on top of the audit-execution
machinery; it does not restate that machinery.

The axis exists because the platform's other audit axes measure *outputs* — delivered work,
process conformance, corpus structure, catalog overlap. None measures the **conduct of the
decisions that produced them**. An agent can ship conformant artifacts through a decision
process that never rendered a gate, never recorded a rationale, and never noticed its own
named failure modes firing. That gap is what this axis reads.

**Scope boundary — cadence policy, not machinery.** The *how-to-run* (window resolution,
oracle derivation and pinning, evidence collection, the six-deliverable emission schema, the
committed-summary handoff schema) lives in
[`decision-audit-mode-spec.md`](../../../core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md);
the coverage-seam set, the per-seam grade vocabulary, and the coverage-index formula live in
`decision-audit-dimension-rubric.md` in the same directory. This doc adds only the
*when-to-re-run* trigger set, the time-based fallback, the output home, and the oracle-continuity
rule. Read the mode-spec and rubric for the how; read this for the cadence. `[INFERRED]`
Splitting cadence from machinery keeps each layer independently editable — a new trigger never
forces a machinery edit, and vice versa.

**Provisioning note.** The mode and this cadence protocol ship with the host decision; the
dimension rubric ships with the capability build. Until the rubric lands, an invocation reports
its unprovisioned state and stops rather than improvising a seam set — see the mode-spec §0. A
scheduled sentinel firing before that point surfaces the unprovisioned state, which is the
correct signal, not a failure.

**Axis boundary.** This is one of **five sibling audit-cadence axes** (see §7):

| Axis | Cadence doc | Conformance frame |
|---|---|---|
| **Decision-health** (this doc) | `decision-audit-cadence.md` | How the hub and spokes decide — hub decision invariants · named decision failure modes · decision-conduct disciplines |
| Architecture-conformance | `architecture-conformance-cadence.md` | Delivered work vs platform architecture (ADR corpus · cross-chain index · architecture-overview) |
| Process-fitness | `process-fitness-cadence.md` | PMBOK 7 · DORA · Stage-Gate · ITIL 4 · Lean · CD |
| Structural | `structural-audit-cadence.md` | Diátaxis · NARA · ISO 15489 · ADR · Keep-a-Changelog |
| Anthropic Base-vs-Build | `platform-health-audit-framework.md` §2 | Anthropic skill-catalog overlap |

The five axes are deliberately separate — distinct oracle rosters, distinct triggers — and
mutually cross-referenced so the full audit-cadence surface is discoverable from any one of them.

---

## §2 Event Triggers

A decision-health re-audit fires when **any** of the following occurs (fire at the trigger's
semantic moment — do not wait for the §3 fallback):

| Trigger | Condition |
|---|---|
| **T1** | A **release closes** (Stage 13 Close) — a new release entered the release record, adding a decision surface to audit. This is the primary event: the audit re-runs on the fresh window after each ship. |
| **T2** | A **decision-oracle change** — an edit to what the audit scores against: the hub's stated decision invariants, a named decision failure mode added to or removed from a release-orchestration skill, or a change to the decision-conduct disciplines. This re-bases what "healthy" means, so prior grades are no longer comparable without a re-run. |
| **T3** | A **decision-evidence surface change** — a change to the pipeline event log's schema, its emission points, or its query surface. The audit's primary evidence source moved; a seam that was blind may now be readable, or the reverse. |
| **T4** | A **surprise** — a decision failure that reached the operator without the pipeline catching it, or a release whose retrospective surfaced a decision defect. The axis re-runs to establish whether the failure was a one-off or a signature the oracle already names and the process missed. |

`[INFERRED]` These triggers are the events that plausibly move decision health; routine content
edits do not qualify and are left to the §3 fallback. T4 is the axis-distinctive trigger — the
other cadence axes have no equivalent, because a decision failure is observable at the operator
surface in a way a structural or conformance drift is not.

---

## §3 90-Day Time-Based Fallback

Independent of the §2 events, a decision-health re-audit fires on a **90-day staleness clock**:
if the most recent decision-health audit — the latest dated audit folder, or the audit-date
anchor in the committed summary surface (§4) — is **more than 90 days old**, the audit is due.
`[INFERRED]` The fallback guarantees a floor on recurrence even in a quiet period where no §2
event fires; it is the same belt-and-suspenders shape the four sibling axes use, and the
interval matches theirs deliberately so the audit family shares one staleness horizon.

---

## §4 Output — analysis folder + committed summary surface

A decision-health audit run emits **two** surfaces:

**(a) A dated analysis subfolder** (operator working material, not shipped corpus):

```
<OPERATOR_INSTANCE_ANALYSIS_PATH>/decision-audit-${AUDIT_DATE_UTC}/
```

per the in-repo [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md).
The analysis workspace is git-ignored except its README, so the audit folder is **produced by a
run at runtime, never authored as tracked content**. The date stamp resolves at run time in
**UTC** (`date -u +%Y-%m-%d`) — see §6 for the LOCAL-schedule / UTC-folder split. Expected
contents: `SUMMARY.md` (analysis frontmatter, the resolved window with both merge anchors, the
oracle pin, the coverage scorecard, and the evidence-bar pass rate), `findings-register.md`
(the finding rows plus a `## Systemic Patterns` table and a single `## Coverage Gap` aggregate
row), and `issue-drafts/NNN-kebab-name.md` in observation format.

**(b) A committed decision-health summary surface** (tracked; ships in the repo):

```
release/releases/decision-health-summary.md
```

Unlike the analysis folder, this small headline surface is **committed** — present on every
clone, seeded with an awaiting-first-run state, overwritten by each run
(single-record-overwrite). It carries the decision-health posture, the coverage index, the
classification counts, the count of seams reporting no evidence, the oracle pin, the resolved
window, the audit date, and a pointer to the latest analysis folder.

**Why the committed surface is load-bearing.** The analysis folder is git-ignored, so anything
that cites only the folder — a tracked acceptance criterion, a downstream consumer, or the
window-defaulting rule in the mode-spec — has no oracle on any instance but the producing one.
The committed surface is what makes a tracked criterion gradable and what lets a run on a fresh
clone resolve where the previous window ended. Schema: mode-spec §7b.

---

## §5 Oracle Continuity

Each re-audit **continues the prior audit's oracle roster** so results are comparable across
runs rather than re-derived from scratch. The decision-health oracle (priority order):

| # | Oracle | Priority |
|---|---|---|
| 1 | The release hub's stated decision invariants — the sink-disposition rule every hub finding must satisfy | **PRIMARY** |
| 2 | The named decision failure modes declared by the release-orchestration skills | **PRIMARY** |
| 3 | The decision-conduct disciplines — the decision-class taxonomy and the retry / escalate / rollback posture | secondary |
| 4 | The recorded decision artifacts — ADRs, plan deviation logs, and release-log decision prose | reference |

The roster is the **continuity contract**: a run scores against the same oracle *sources* the
prior run did, records the oracle pin, and states each run's read so drift between runs is
visible. Adding an oracle source is itself an oracle change (a T2 trigger, and noted in the
run's `SUMMARY.md`); removing one requires a rationale in the same place.

**The roster names sources, never a cardinality.** The oracle *set* is derived from those
sources at run time and pinned per run — it is never carried as a count in this doc, in the
mode-spec, in the rubric, or in the skill definition. A frozen cardinality is silently
invalidated by a single new entry, and a decision audit that inherits that decay cannot
credibly report it. The derivation and the control that bounds it are specified in mode-spec §3.

---

## §6 Mechanism (HYBRID)

The cadence runs as a **HYBRID** of manual event-triggers and an automated staleness sentinel —
the same split the four sibling axes run:

- **Manual (event-driven).** The §2 triggers fire **manually at their semantic moment** — the
  operator or spoke who closes a release, changes a decision oracle, changes the evidence
  surface, or receives a surprise signal invokes the audit. The audit executor is
  `pmo-qa-auditor` **Mode J** (the how-to-run home). Findings are observations for human
  routing; the audit **auto-files nothing**.
- **Automated (time-driven).** The §3 90-day fallback is a scheduled **staleness sentinel** that
  checks the age of the latest dated decision-audit folder (or the committed summary's audit-date
  anchor) and routes a due-audit signal to an observation draft.

**Inherited conventions** (from the sibling-axis precedents — do not unify):

- The sentinel **schedule is evaluated in the operator's LOCAL timezone**, while the audit-folder
  date stamp uses **UTC**. This split is intentional.
- The sentinel's completion notification is **per-run**, so a due-or-overdue result self-routes
  to an observation issue draft rather than relying on a conditional ping.

**`[ASSUMPTION – CONFIRM]`** Sentinel **registration** (creating the scheduled job) is an
**operator-instance build step** (Stage 12), not committed corpus — the registration carries an
instance-local path and is not portable. This tracked doc states the **policy** (a 90-day
staleness sentinel exists and behaves as above); the instance owns the registration.

---

## §7 Cross-References (5-Axis Set)

This cadence is one axis of a five-axis audit-cadence set; all five mutually cross-reference:

- **Sibling — architecture-conformance axis:** [`architecture-conformance-cadence.md`](architecture-conformance-cadence.md) (delivered work vs the platform architecture baseline).
- **Sibling — process-fitness axis:** [`process-fitness-cadence.md`](process-fitness-cadence.md) (PMBOK 7 / DORA / Stage-Gate / ITIL 4 / Lean / CD).
- **Sibling — structural axis:** [`structural-audit-cadence.md`](structural-audit-cadence.md) (Diátaxis / NARA / ISO 15489 / Keep-a-Changelog).
- **Sibling — Anthropic Base-vs-Build axis:** [`platform-health-audit-framework.md`](platform-health-audit-framework.md) §2 (Anthropic skill-catalog overlap cadence).
- **Machinery (how-to-run):** [`decision-audit-mode-spec.md`](../../../core/skills/pmo-qa-auditor/references/decision-audit-mode-spec.md) — the run mechanics this cadence schedules.
- **Content SSOT (what-is-scored):** `decision-audit-dimension-rubric.md`, in the same skill `references/` directory — the coverage-seam set, per-seam grade vocabulary, and coverage-index formula. Authored by the capability build; cited here by path rather than by link until it lands.
- **Output convention:** [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md) — the analysis-folder home, frontmatter, and sunset rule.
- **Host decision of record:** [ADR-103](../../../core/ADRs/ADR-103-decision-audit-host-qa-auditor-mode-j.md) — why this axis hosts as a mode of the existing QA-auditor skill rather than as a standalone skill.

**Relationship to the forward gates.** This axis is the **retrospective** complement to the
forward, per-decision gates the pipeline already runs — the stage gates, the plan-review GO
gate, and the operator decision gates. Those hold a decision pre-merge, one decision at a time;
this axis reads the release record after the fact and catches the cross-release recurrence a
per-decision gate is structurally blind to: a failure mode that fires once in each of several
releases never trips any single gate.

**Relationship to the session-grained learning loop.** The session retrospective captures
learnings at the *session* boundary; this axis reads the *release* boundary. The two are
complementary grains of the same learning surface and neither subsumes the other — a decision
defect that spans releases is invisible at session grain, and a within-session correction never
reaches the release record.

---

## §8 Reversibility

**CHEAP** (confidence: **HIGH**). This protocol adds a new tracked doc plus non-destructive
cross-reference edits to four sibling framework docs. The only runtime artifacts are
git-ignored analysis folders, an operator-instance sentinel registration, and the committed
summary surface (overwritten in place per run). Undo = delete the doc and revert the
cross-reference lines (minutes, no data loss, no stakeholder impact).

---

**End of cadence protocol.**
