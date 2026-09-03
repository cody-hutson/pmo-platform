---
title: Architecture-Conformance Audit Cadence
purpose: When-to-re-run cadence policy for the as-built architecture-conformance audit axis (event-bound triggers + 90-day fallback)
type: protocol
automation_id: [architecture-conformance-sentinel]
related: architecture-conformance-mode-spec.md (how-to-run machinery — core/skills/pmo-qa-auditor/references/), architecture-conformance-dimension-rubric.md (content SSOT — core/skills/pmo-qa-auditor/references/), process-fitness-cadence.md (sibling process-fitness axis), structural-audit-cadence.md (sibling structural axis), platform-health-audit-framework.md (sibling Anthropic Base-vs-Build axis — §2), analysis-workspace-standard.md (analysis-folder output convention — core/standards/)
effective-date: 2026-07-25
scope: The as-built architecture-conformance audit axis only — delivered work (per the release record) vs the platform's architecture baseline (ADR corpus primary; the cross-chain index + architecture-overview secondary). Not the process-fitness axis (see process-fitness-cadence.md), not the structural axis (see structural-audit-cadence.md), and not the Anthropic Base-vs-Build axis (see platform-health-audit-framework.md §2).
owner: PMO Cowork Platform Team
---
<!-- reference-durability: allow-link -->

# Architecture-Conformance Audit Cadence

## §1 Purpose & Scope Boundary

This protocol defines **when to re-run** the **as-built architecture-conformance audit** — the
recurring review that reads the release record and checks *delivered* work against the
platform's stated architecture, detecting two drift classes the forward per-ticket
architecture-fit gate is structurally blind to: **conformance drift** (a delivery diverged
from the architecture/ADR it was meant to follow) and **cross-release fragmentation** (related
deliveries each solved the same problem under a different architecture across releases). It is
the *recurrence layer* (cadence policy) on top of the audit-execution machinery; it does not
restate that machinery.

**Scope boundary — cadence policy, not machinery.** The *how-to-run* (delivered-item
reconstruction, baseline mapping, the two-class detection, the confidence/severity model, the
artifact schemas) lives in [`architecture-conformance-mode-spec.md`](../../../core/skills/pmo-qa-auditor/references/architecture-conformance-mode-spec.md);
the scored dimension set + severity banding + fragmentation threshold live in
[`architecture-conformance-dimension-rubric.md`](../../../core/skills/pmo-qa-auditor/references/architecture-conformance-dimension-rubric.md).
This doc adds only the *when-to-re-run* trigger set, the time-based fallback, the output home,
and the baseline-continuity rule. Read the mode-spec + rubric for the how; read this for the
cadence. `[INFERRED]` Splitting cadence from machinery keeps each layer independently editable —
a new trigger never forces a machinery edit, and vice versa.

**Axis boundary.** This is one of **five sibling audit-cadence axes** (see §7):

| Axis | Cadence doc | Conformance frame |
|---|---|---|
| **Architecture-conformance** (this doc) | `architecture-conformance-cadence.md` | Delivered work vs platform architecture (ADR corpus · cross-chain index · architecture-overview) |
| Process-fitness | `process-fitness-cadence.md` | PMBOK 7 · DORA · Stage-Gate · ITIL 4 · Lean · CD |
| Structural | `structural-audit-cadence.md` | Diátaxis · NARA · ISO 15489 · ADR · Keep-a-Changelog |
| Anthropic Base-vs-Build | `platform-health-audit-framework.md` §2 | Anthropic skill-catalog overlap |
| Decision-health | `decision-audit-cadence.md` | How the hub and spokes decide — hub decision invariants · named decision failure modes · decision-conduct disciplines |

The five axes are deliberately separate — distinct benchmark rosters, distinct triggers — and
mutually cross-referenced so the full audit-cadence surface is discoverable from any one of
them.

---

## §2 Event Triggers

An architecture-conformance re-audit fires when **any** of the following occurs (fire at the
trigger's semantic moment — do not wait for the §3 fallback):

| Trigger | Condition |
|---|---|
| **T1** | A **release closes** (Stage 13 Close) — a new release entered the release record (`RELEASE_LOG.md` + `notes/`), adding delivered items to audit against the architecture baseline. This is the primary event: the audit re-runs on the fresh delivered-item set after each ship. |
| **T2** | A **pipeline-definition or architecture-definition change** — an edit to the architecture baseline itself (an ADR added/superseded, a `cross-chain-architecture-map.md` chain added/renamed, an `architecture-overview.md` structural change) that re-bases what "conformant" means. |
| **T3** | A **baseline change** surfaced by another axis — a structural or process-fitness audit, or a manual Platform Architecture Review, files a finding implying delivered work may have diverged; the conformance axis re-runs to confirm as-built. |

`[INFERRED]` These triggers are the events that plausibly move conformance of delivered work
against the architecture baseline; routine content edits (typo fixes, single-doc wording) do
not qualify and are left to the §3 fallback.

---

## §3 90-Day Time-Based Fallback

Independent of the §2 events, an architecture-conformance re-audit fires on a **90-day
staleness clock**: if the most recent conformance audit (the latest
`analysis/architecture-conformance-YYYY-MM-DD/` folder, or the `baseline_date` anchor in the
committed conformance-summary surface — §4) is **more than 90 days old**, the audit is due.
`[INFERRED]` The fallback guarantees a floor on recurrence even in a quiet period where no §2
event fires — the same belt-and-suspenders shape the other three axes use.

---

## §4 Output — analysis folder + committed summary surface

An architecture-conformance audit run emits **two** surfaces:

**(a) A dated analysis subfolder** (operator working material, not shipped corpus):

```
analysis/architecture-conformance-YYYY-MM-DD/
```

per the in-repo [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md).
The repo-root `analysis/` folder is git-ignored except its README, so the audit folder is
**produced by an audit run at runtime, never authored as tracked content**. The date stamp
uses **UTC** (`date -u +%Y-%m-%d`) — see §6 for the LOCAL-schedule / UTC-folder split. Expected
contents (per the analysis-workspace-standard §2 convention): `SUMMARY.md` (analysis
frontmatter + baseline-freshness anchor + the stated fragmentation confidence bound + the
conformance scorecard), `findings-register.md` (the `{item, baseline, classification,
severity, confidence, evidence, root-cause}` rows + the `## Fragmentation Groups` table + the
single `## Coverage Gap` aggregate row), `issue-drafts/NNN-kebab-name.md` in observation
format, optional `_scores/` / `evidence/` support folders.

**(b) A committed conformance-summary surface** (tracked; ships in the repo):

```
release/releases/architecture-conformance-summary.md
```

Unlike the analysis folder, this small headline surface is **committed** — present on every
clone, seeded with an "awaiting first run" state, overwritten by each audit run
(single-record-overwrite). It carries the conformance posture, classification counts, the
fragmentation-group count + confidence bound, the `baseline_sha` / `baseline_date` anchor, and
a pointer to the latest analysis folder. It exists so a **deployed consumer** (the health-check
skill) can read the conformance flag off any instance — not only the producing one. Schema:
mode-spec §7b.

**Emitted counts carry probe records.** The conformance scorecard, the classification and fragmentation-group counts, and the single `## Coverage Gap` aggregate row each state the denominator examined and the control that proves the probe detects, per [`review-discipline-principles.md`](../../../core/disciplines/review-discipline-principles.md) § 1 Rule 15 + § 8 Probe Validity — `PV-6` binds an emitting instrument, so a run whose output states only a finding count cannot be read as "zero divergences" rather than "nothing examined".

---

## §5 Baseline Continuity

Each re-audit **continues the prior audit's baseline roster** so results are comparable across
runs rather than re-derived each time. The architecture-conformance baseline (priority order —
CD-A):

| # | Baseline | Priority |
|---|---|---|
| 1 | The ADR corpus (`core/ADRs/` + `release/ADRs/`) — per-decision, unit-matched to per-delivery conformance | **PRIMARY** |
| 2 | `cross-chain-architecture-map.md` — the management-chain roster (referenced by chain name), a routing aid for World-B operational-chain deliveries | secondary |
| 3 | `architecture-overview.md` — the narrative current-state baseline | secondary |
| 4 | `actor-model-and-governance-as-contract.md` — the target-architecture statement (forward-looking; consistency reference only) | reference |

The roster is the **continuity contract**: a run maps deliveries against the same baseline set
the prior run did, records the `baseline_sha` / `baseline_date` anchor, and states each run's
conformance read so drift between runs is visible. Adding a baseline source is itself a
baseline change (note it in the run's `SUMMARY.md`); removing one requires a rationale in the
same place. Because the ADR corpus is PRIMARY, a delivery with no governing ADR and no chain
mapping degrades to `no-governing-baseline` **gracefully** (a coverage signal, not a failure).

---

## §6 Mechanism (HYBRID)

The cadence runs as a **HYBRID** of manual event-triggers and an automated staleness sentinel —
the same split the other three axes run:

- **Manual (event-driven).** The §2 triggers (T1–T3) fire **manually at their semantic
  moment** — the operator or spoke who closes a release, lands an architecture-definition
  change, or receives a baseline-change signal invokes the audit. The audit executor is
  `pmo-qa-auditor` **Mode I** (the how-to-run home). Findings are observations for human
  routing; the audit **auto-files nothing**.
- **Automated (time-driven).** The §3 90-day fallback is a scheduled **staleness sentinel** that
  checks the age of the latest `analysis/architecture-conformance-*` anchor (or the committed
  summary's `baseline_date`) and routes a due-audit signal to an observation draft. The routine is
  registered as `architecture-conformance-sentinel` in
  [`core/automations/registry.md`](../../../core/automations/registry.md); how it fires resolves at
  fire time from the operator's `[adapters].scheduler`.

**Inherited conventions** (from the sibling-axis precedents — do not unify):

- The sentinel **schedule is evaluated in the user's LOCAL timezone**, while the audit-folder
  date stamp uses **UTC** (`date -u`). This LOCAL-schedule / UTC-folder split is intentional.
- The sentinel's completion notification is **per-run**, so a due/overdue result self-routes to
  an observation issue-draft rather than relying on a conditional ping.

**`[ASSUMPTION – CONFIRM]`** Sentinel **registration** (creating the scheduled job) is an
**operator-instance build step** (Stage 12), not committed corpus — the
registration carries an instance-local path and is not portable. This tracked doc states the
**policy** (a 90-day staleness sentinel exists and behaves as above); the instance owns the
registration.

---

## §7 Cross-References (5-Axis Set)

This cadence is one axis of a five-axis audit-cadence set; all five mutually cross-reference:

- **Sibling — process-fitness axis:** [`process-fitness-cadence.md`](process-fitness-cadence.md) (PMBOK 7 / DORA / Stage-Gate / ITIL 4 / Lean / CD).
- **Sibling — structural axis:** [`structural-audit-cadence.md`](structural-audit-cadence.md) (Diátaxis / NARA / ISO 15489 / ADR / Keep-a-Changelog).
- **Sibling — Anthropic Base-vs-Build axis:** [`platform-health-audit-framework.md`](platform-health-audit-framework.md) §2 (Anthropic skill-catalog overlap cadence).
- **Sibling — decision-health axis:** [`decision-audit-cadence.md`](decision-audit-cadence.md) (how the hub and spokes decide — the retrospective complement to the forward per-decision gates).
- **Machinery (how-to-run):** [`architecture-conformance-mode-spec.md`](../../../core/skills/pmo-qa-auditor/references/architecture-conformance-mode-spec.md) — the run mechanics this cadence schedules.
- **Content SSOT (what-is-scored):** [`architecture-conformance-dimension-rubric.md`](../../../core/skills/pmo-qa-auditor/references/architecture-conformance-dimension-rubric.md) — the dimension set + severity banding + fragmentation threshold.
- **Output convention:** [`analysis-workspace-standard.md`](../../../core/standards/analysis-workspace-standard.md) — the analysis-folder home, frontmatter, and sunset rule.

**Relationship to the forward gate.** This axis is the **retrospective** complement to the
forward, per-ticket architecture-fit gate (the Stage-5 SR-G architecture gate + the Stage-2
acceptance-fit gate **G2-13**, [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md)
— shipped and enforcing). The forward gate holds new work pre-merge, one ticket at a
time; this axis reads the release record after the fact and catches the cross-release
fragmentation the forward gate is structurally blind to. The two are complementary, not
redundant.

**Operator-local roadmap relationship.** `[INFERRED]` Any architecture-conformance *initiative
roadmap* is an operator-local instance (git-ignored per the roadmap framework-tracked /
instances-ignored split). This cadence doc is the committed home for the conformance recurrence
policy; the operator-local roadmap references *this doc* rather than the reverse.

---

## §8 Reversibility

**CHEAP** (confidence: **HIGH**). This protocol adds a new tracked doc plus non-destructive
cross-reference edits to three sibling frameworks. The only runtime artifacts are git-ignored
analysis folders, an operator-instance sentinel registration, and the committed conformance-
summary surface (overwritten in place per run). Undo = delete the doc and revert the cross-ref
lines (minutes, no data loss, no stakeholder impact).

---

**End of cadence protocol.**
