---
title: Sub-Task Methodology
type: standard
purpose: K1 codified-knowledge cross-pipeline best-practices reference for how sub-tasks are used across the release pipeline — pipeline integration, creation rules, information requirements, writing/tracking practices, system/tool usage, and metrics/calibration. The best-practices layer atop the Stage 6 Phase A2 decomposition protocol (which it summarizes, not owns).
parallel_to:
  - release/references/pipeline/stage-06-engineering.md (owns the Phase A2 decomposition protocol this doc summarizes; §9 names the sub-task-methodology gap this doc closes)
  - release/references/standards/bundle-composition-doctrine.md (sibling cross-pipeline methodology standard)
  - release/references/standards/finding-disposition-framework.md (sibling cross-stage methodology standard)
  - release/references/standards/deferred-item-tracking.md (sibling release-boundary methodology standard)
reversibility: CHEAP (forward-only reference doc; additive; revisable in subsequent releases without breaking consumers)
consumers: "release/governance/release-process.md Stage 6 § (cross-ref); release/references/pipeline/stage-06-engineering.md Phase A2 (the protocol this layers on); Stage 7 Dev Testing + Stage 8 QA Testing + Stage 13 Close (sub-task lifecycle consumers); pmo-qa-auditor (audit-trail)"
last-updated: 2026-06-14
---
<!-- reference-durability: allow-link -->

# Sub-Task Methodology — Cross-Pipeline Best Practices

## § 1. Purpose + Scope

A **sub-task** is a GitHub sub-issue linked to a parent release issue, created at Engineering to decompose that issue into single-commit-sized units of implementable work. Sub-tasks are the unit at which a release issue becomes *executable*: the parent says *what capability lands*; its sub-tasks say *which file changes and logical units land it*, each closeable on its own commit.

This standard is the **best-practices layer on top of** the decomposition protocol. The protocol — the one-sentence rule for *when* a sub-issue is created and the set of special sub-tasks always generated — is owned by [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) Phase A2 and summarized here inline (§ 3, § 4). This doc adds the cross-cutting methodology the protocol does not carry: how sub-tasks flow through every downstream stage, what information they require at creation, how to write and track them, the `gh` tooling that operates on them, and the metrics that feed the Engineering eval set.

**In scope (this standard):**
- Pipeline integration — how a sub-task is created, validated, referenced, and reconciled across stages (§ 3).
- Creation rules — when to create one, granularity, and container selection (§ 4).
- Information requirements at creation (§ 5).
- Writing best practices (§ 6) and tracking best practices (§ 7).
- System and tool usage — the canonical `gh` / `gh api` sub-issue mechanics (§ 8).
- Metrics and calibration that feed the Engineering eval set (§ 9).

**Out of scope (owned elsewhere, summarized not duplicated here):**
- The Phase A2 decomposition *protocol mechanics* themselves — owned by [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) Phase A2. This doc summarizes the rule; it does not restate the protocol or supersede it.
- The sub-issue-vs-body-checklist *decision model* — owned by [`specs/ticket-information-architecture.md`](../specs/ticket-information-architecture.md); summarized in § 3.
- The Stage 5→6 *boundary contract* (what a Stage 6 spoke receives) — owned by [`solutioning-output-template.md`](solutioning-output-template.md) and the stage-IO schema.

## § 2. When This Applies

This standard applies whenever a release **decomposes an issue into sub-tasks** — which begins at Stage 6 Engineering and continues through every stage that reads sub-task state. It is consumed by:

| Audience | Role with respect to sub-tasks |
|---|---|
| Stage 6 Engineering spoke | **Producer** — decomposes the parent issue, creates the sub-issues, writes their bodies, and closes each on completion. |
| Stage 7 Dev Testing | **Validator** — checks that each closed sub-task's claimed change actually landed and verifies per the parent's acceptance criteria. |
| Stage 8 QA Testing | **Reference consumer** — reads the sub-task trail as the per-change audit record while assessing the parent against acceptance criteria. |
| Stage 13 Close | **Reconciler** — confirms every sub-task is closed (or its deferral is recorded) before the parent closes; reconciles planned-vs-actual sub-task count. |
| Operator | Reviews the decomposition at the Phase A1–A2 checkpoint; renders scope-change decisions when sub-tasks are added mid-implementation. |
| `pmo-qa-auditor` | Audit-trail consumer — the sub-task lifecycle is the evidence that work was decomposed, tracked, and closed cleanly. |

It does **not** apply to a single-commit release issue that needs no decomposition (no sub-tasks created), nor to the parent-issue triage/bundling stages that precede Engineering.

## § 3. Pipeline Integration

Sub-tasks are **cross-cutting**: they are created at one stage and read at four. The lifecycle:

| Stage | What happens to the sub-task |
|---|---|
| **Stage 6 — Engineering (created)** | The spoke decomposes the parent per the Phase A2 rule (summarized below), creates one sub-issue per unit linked to the parent, writes each body (§ 5), implements, and **closes each sub-task immediately on completion** (§ 7). |
| **Stage 7 — Dev Testing (validated)** | DT independently verifies that each closed sub-task's change landed on the release branch and the parent's acceptance criteria are met. A sub-task whose change is missing or wrong becomes a Tier 1 finding routed back to Engineering. |
| **Stage 8 — QA Testing (referenced)** | QA reads the sub-task trail as the per-change record while assessing the parent against acceptance criteria; the trail is reference evidence, not a re-decomposition surface. |
| **Stage 13 — Close (reconciled)** | Close confirms every sub-task is closed before the parent closes; any sub-task deferred rather than completed is recorded per [`deferred-item-tracking.md`](deferred-item-tracking.md). Planned-vs-actual sub-task count is reconciled here (§ 9). |

**The decomposition rule (Phase A2, summarized inline per reference-durability).** Engineering creates **one sub-issue per file-level change or logical unit**. Three **special sub-tasks are always generated** regardless of the change set: a **sync** sub-task (deployed-copy sync), a **plan-update** sub-task (release-plan implementation notes / Change Description), and a **verification** sub-task (Layer 1 self-verification). The authoritative rule — including native-dependency mirroring when a parent's body dependencies also apply to a sub-task — is owned by [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) Phase A2; this doc is the best-practices layer on top of it and does not restate the protocol in full.

**Sub-issue vs. body checklist (decision model, summarized).** A sub-issue is a *first-class, separately-trackable, separately-closeable* work item with its own number, lifecycle, and metadata; a parent-body checklist (`- [ ]`) is a *lightweight in-line marker* with no independent lifecycle. Use a sub-issue when the unit needs its own commit, its own closure event, and its own visibility in milestone rollups; use a body checklist for trivial, non-separately-tracked steps within a single sub-task. The full decision model lives in [`specs/ticket-information-architecture.md`](../specs/ticket-information-architecture.md) and is summarized at the container-selection threshold in § 4.

**Provenance.** [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 9 Gap Summary names "sub-task methodology reference (P2)" as a known gap (gap G-EX5, surfaced during a Stage 6 execution); this standard closes it.

## § 4. Creation Rules

**When to create a sub-task.** Create one whenever the parent issue's implementation comprises **more than one file-level change or more than one logical unit** of work — i.e., whenever the change set cannot land in a single coherent commit. A parent that lands in one commit needs no sub-tasks; its work is the commit itself.

**Granularity.** The default grain is **one sub-issue per file-level change or logical unit** (the Phase A2 rule). Bias toward single-commit-sized units: each sub-task should be completable and closeable on one commit. Two failure grains to avoid:
- **Too coarse** — a sub-task spanning several unrelated files or multiple design decisions cannot close on one commit and obscures which part failed at Dev Testing.
- **Too fine** — a sub-task per line or per trivial edit inflates the count, dilutes rollup signal, and inverts the cost of tracking against the value.

**Container selection (sub-issue vs. body checklist) — threshold:**

| Use a **sub-issue** when… | Use a **body checklist** (`- [ ]`) when… |
|---|---|
| The unit needs its own commit and its own closure event. | The step is trivial and rides inside another sub-task's commit. |
| The unit must appear independently in milestone rollups (§ 8). | The step needs no independent rollup visibility. |
| The unit may be validated/deferred/reconciled on its own at S7/S8/S13. | The step has no independent downstream lifecycle. |
| The unit carries its own dependencies or risk flags (§ 5). | The step carries no metadata of its own. |

When in doubt at the boundary, prefer the sub-issue: a separately-trackable unit degrades gracefully (it is simply closed), whereas a checklist item that should have been a sub-task is invisible to rollup and reconciliation.

**Special-sub-task generation.** Independent of the change set, always generate the three special sub-tasks named in § 3 (sync, plan-update, verification). They are part of every decomposition because every release performs deployed-copy sync, plan/Change-Description authoring, and Layer 1 self-verification — making them explicit sub-tasks keeps them trackable and reconcilable rather than implicit.

## § 5. Information Requirements at Creation

Every sub-task carries enough information at creation that an implementer (or a downstream validator) can act on it without re-reading the whole parent. Required fields are non-negotiable; optional fields are included when they apply.

| Field | Required? | What it captures |
|---|---|---|
| **File** | Required | The repo-relative path(s) the sub-task touches (e.g., `release/references/standards/foo.md`). For a logical-unit sub-task with no single file, name the unit. |
| **Action** | Required | The change class — `add` / `modify` / `delete` / `sync` / `verify` / `plan-update`. |
| **Change description** | Required | One actionable sentence: what changes and why, traceable to the parent's acceptance criteria. |
| **Commit group** | Required | The commit (or commit sequence) this sub-task closes on — so closure maps to a SHA. |
| **Dependencies** | Optional | Other sub-tasks or parent-body dependencies that must land first. When a parent-body `FS+0d` dependency also applies to this sub-task with native-meaningful semantics, mirror it into the sub-task's native `blocked-by` per the Phase A2 mirror rule. |
| **Complexity** | Optional | A coarse sizing signal (e.g., trivial / moderate / involved) when the unit is non-obvious — informs sequencing. |
| **Risk flags** | Optional | Any regression, contention, or reversibility flag carried from the Stage 5 blast-radius analysis (e.g., "high-traffic governance file — Stage 9 divergence re-check obligation"). |

The required four (File / Action / Change description / Commit group) make a sub-task self-describing and closeable; the optional three add the sequencing and risk context that the Stage 5 spec supplies when present.

**Commit-group enforcement posture:** the `Commit group` field is *advisory documentation*, not an automatically-enforced plan-vs-actual mapping — under single-agent-on-a-branch execution the commit-to-sub-task lineage is already reconstructable from B1 issue-referencing commit messages plus the SHA-naming closure comment (§ 7), so no dedicated verifier checks the declared group against the actual closing commits. The one signal that the reconstruction broke is a rollup-vs-commit-history divergence (§ 7 rollup-monitoring), which is a tracking defect to fix, not a silent gap. See [`pipeline/stage-06-engineering.md § 5`](../pipeline/stage-06-engineering.md) Phase B1 for the documented simplification.

## § 6. Writing Best Practices

A well-written sub-task reads cleanly at creation, at validation, and in the milestone rollup months later.

- **Clear, decodable title.** A reader should see the change class, the file, and the action without opening the sub-task. Pattern: `Stage 6 Engineering — <change-N>: <file> (<action>)` — e.g., `Stage 6 Engineering — change-2: release-process.md Stage 6 cross-ref (modify)`.
- **Actionable description.** State what to do, not what exists. "Append the cross-ref line after the documentation-impact beat" — not "the cross-ref is needed." A validator should be able to confirm the action from the description alone.
- **Traceable to the parent and the change spec.** Reference the parent issue and the Stage 5 change spec the sub-task implements, so the lineage parent → change spec → sub-task → commit is reconstructable. Keep durable-corpus reference forms self-describing per the reference-durability standard — confine any bare issue reference to a designated reference block.
- **Sized for single-commit completion.** If the description implies more than one commit, the unit is too coarse — split it (§ 4 granularity). A sub-task that cannot close on one commit is a writing defect, not just a tracking one.

## § 7. Tracking Best Practices

Tracking discipline is what makes the sub-task lifecycle trustworthy as audit evidence and as rollup signal.

- **Check-off discipline — close immediately on completion, not batched.** Close each sub-task the moment its commit lands, with a closure comment naming the SHA (§ 8). Batching closures to the end of the stage destroys the in-flight rollup signal (the parent looks stalled when it is not) and loses the SHA-to-sub-task mapping that Stage 7/8 rely on.
- **Rollup monitoring.** The parent issue reflects sub-task progress (closed / open) in its sub-issue rollup. Monitor it as the stage progresses: a parent whose rollup is N-of-M closed is the honest in-flight state. A divergence between the rollup and the actual commit history is a tracking defect to fix immediately.
- **Deviation tracking.** A **new sub-task added during implementation** — one not in the Stage 4/5 plan — is a **plan deviation**. Route it per the inter-stage feedback protocol: a minor in-scope addition is committed with rationale and logged; a scope-changing addition is flagged to the operator before it proceeds. Record the deviation so the planned-vs-actual count (§ 9) is reconcilable, and so the deviation frequency metric is real rather than silently absorbed.

## § 8. System and Tool Usage

GitHub sub-issues are operated through `gh` and the `gh api` sub-issue REST endpoint. The examples below are the canonical mechanics — they use **placeholder tokens** (`{REPO}`, `<PARENT>`, `<N>`, `v<X.Y>-<slug>`) for every issue number and identifier; substitute real values at invocation time, never commit a real issue number into this corpus.

### Creating a sub-issue and linking it to its parent

GitHub sub-issues use a dedicated REST endpoint (the sub-issue link is distinct
from a body checklist). The two-step pattern: create the child issue, then link
it to the parent by the parent's **internal issue id** (not its number).

```bash
# 1. Create the child issue (capture its number)
gh issue create --repo {REPO} \
  --title "Stage 6 Engineering — <change-N>: <file> (<action>)" \
  --label "sub-task" --milestone "v<X.Y>-<slug>" --assignee "@me"

# 2. Resolve the PARENT's internal id (the API id, not the #number)
gh api repos/{REPO}/issues/<PARENT> --jq '.id'

# 3. Link child → parent via the sub_issues endpoint (resolve the child id by number too)
gh api --method POST repos/{REPO}/issues/<PARENT>/sub_issues \
  -F sub_issue_id="$(gh api repos/{REPO}/issues/<N> --jq '.id')"
```

### Listing a parent's sub-issues (rollup monitoring)

```bash
gh api repos/{REPO}/issues/<PARENT>/sub_issues \
  --jq '.[] | {number, title, state}'
```

### Closing a sub-issue on completion (close immediately — do NOT batch)

```bash
gh issue close <N> --repo {REPO} \
  --comment "Done — <commit-SHA> on release/<slug>."
```

### Milestone-level visibility (all release sub-tasks at a glance)

```bash
gh issue list --repo {REPO} --milestone "v<X.Y>-<slug>" \
  --label "sub-task" --state all --json number,title,state
```

> **Endpoint-shape authoring note.** Verify the `/sub_issues` endpoint shape against the live `gh api` at author time. If the deployed `gh` / API surface differs, the documented fallback is a **body checklist** in the parent (`- [ ]` task-list), with the `/sub_issues` endpoint noted as the preferred mechanism when available. Keep all issue numbers as `<PARENT>` / `<N>` placeholders — never a real number (repo-integrity / self-containment).

**PR-body and commit-message integration.** Reference the parent issue (reference-only, never with a close-family verb outside the PR's dedicated Issue References block) in commit messages so each commit maps to the work it implements; the closure comment (above) carries the SHA back to the sub-task. The release PR body's per-issue status reflects the aggregate sub-task completion, not each sub-task individually.

**Milestone-level visibility.** All of a release's sub-tasks share the release milestone and the `sub-task` label, so the milestone view (last command above) is the single-pane rollup across every parent in the release.

## § 9. Metrics and Calibration

Sub-task metrics feed the **Engineering (Stage 6) eval set**: they are the calibration signal for how well decomposition was planned and executed. The four named Stage 6 calibration fields (per [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 7 Stage-Transition Gate) plus two derived rates:

| Metric | Definition | What it calibrates |
|---|---|---|
| **Sub-task accuracy** | Planned sub-task count vs. actual sub-task count (how close the Stage 4/5 decomposition estimate was). | Decomposition-planning quality. A large planned-vs-actual gap signals under-specified or over-specified planning. |
| **Deviation count by severity** | Count of mid-implementation deviations (new sub-tasks, re-scopes), bucketed by severity (minor / scope-change). | How well the plan anticipated the work; high counts signal planning gaps or emergent complexity. |
| **Verification coverage** | Fraction of sub-tasks whose change was independently verified at Dev Testing. | Self-verification thoroughness; low coverage signals a Layer 1 gap. |
| **Escape rate** | Defects that passed Engineering self-review and surfaced at Dev Testing or later. | Self-review effectiveness; the headline quality signal for the stage. |
| **Completion rate** *(derived)* | Fraction of created sub-tasks closed by stage end (vs. deferred/reconciled at Stage 13). | In-stage execution completeness. |
| **Deviation frequency** *(derived)* | Deviations per release (or per parent issue) over time. | Trend signal for planning maturity across releases. |

These metrics are computed at Stage 6 (planned-vs-actual, deviation count), confirmed at Stage 7 (verification coverage, escape rate), and reconciled at Stage 13 (completion rate, final deviation frequency). They **feed the Engineering eval set** as calibration data — the eval set uses them to score decomposition quality and self-review effectiveness across releases.

## § 10. Cutover + Version History

Applies to all releases going forward.

| Version | Date | Change |
|---|---|---|
| Initial | 2026-06-14 | Initial authoring — closes the sub-task-methodology reference gap (G-EX5, P2) named in [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 9 Gap Summary. |

## § 11. Related References

| Reference | Relationship to this standard |
|---|---|
| [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) Phase A2 | **Owns** the decomposition protocol this doc summarizes (one sub-issue per file-level change or logical unit; three always-generated special sub-tasks). |
| [`pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 9 Gap Summary | Names the sub-task-methodology gap (G-EX5) this doc closes. |
| [`release-process.md`](../../governance/release-process.md) Stage 6 § | Cross-references this doc from the governance-level Stage 6 section. |
| [`specs/ticket-information-architecture.md`](../specs/ticket-information-architecture.md) | Owns the sub-issue-vs-body-checklist decision model and the native-dependency mirror rule, summarized here. |
| [`solutioning-output-template.md`](solutioning-output-template.md) | Sister K1 standard; the Stage 5→6 output contract that hands the change spec to the Engineering spoke. |
| [`bundle-composition-doctrine.md`](bundle-composition-doctrine.md) | Sibling cross-pipeline methodology standard (bundle composition). |
| [`finding-disposition-framework.md`](finding-disposition-framework.md) | Sibling cross-stage methodology standard (finding disposition). |
| [`deferred-item-tracking.md`](deferred-item-tracking.md) | Sibling release-boundary methodology standard; owns the Stage 13 disposition of a sub-task deferred rather than completed. |
