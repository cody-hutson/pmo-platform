---
title: Decision-Health Audit Mode Spec — pmo-qa-auditor Mode J
purpose: The machinery spec for pmo-qa-auditor Mode J (decision-health audit) — window resolution, oracle derivation and pinning, evidence collection, and the two emission schemas. When-to-run authority and content SSOT live at their cited homes.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Decision-Health Audit Mode Spec — pmo-qa-auditor Mode J

> When-to-run authority: [`release/references/protocols/decision-audit-cadence.md`](../../../../release/references/protocols/decision-audit-cadence.md).
> Content SSOT: `decision-audit-dimension-rubric.md` (same directory). Machinery only — this
> spec defines no coverage seam, no grade anchor, no index formula, and no cadence rule of
> its own.

Mode J audits **how the release hub and its spokes decide** across a release window —
whether decisions were made where the governance says they are made, whether the evidence
for them was recorded, and whether the platform's own named decision failure modes were
detected when they occurred. It is the decision-process sibling of Mode I: same input class
(the release record), same emission class (a git-ignored dated audit folder plus a committed
summary handoff), same OBSERVE-only mutation posture, same cadence-protocol shape. The two
differ in exactly one respect — which corpus oracle the run scores against. Mode I scores
delivered work against the architecture baseline; Mode J scores decision conduct against the
hub's invariants and named failure modes.

**Host decision of record:** [ADR-103](../../../ADRs/ADR-103-decision-audit-host-qa-auditor-mode-j.md).

## 0. Provisioning state (read this first)

This spec ships **ahead of** the content SSOT it cites. The host decision and the capability
build are separate work items: the host decision registers the mode, this spec, and the
cadence protocol; the capability build authors `decision-audit-dimension-rubric.md` (the
coverage-seam set, the per-seam grade vocabulary, and the coverage-index formula) and fills
the run machinery against the shipped event-log schema.

**Until the rubric exists, a Mode J invocation reports its own unprovisioned state and stops.**
It does not improvise a seam set, does not score against an ad-hoc rubric, and does not emit a
partial scorecard — a fabricated baseline is worse than an absent one, because a later run
would silently measure drift against noise. The check is mechanical: resolve the rubric path;
if it is absent, emit the unprovisioned notice naming the missing file and the work item that
lands it, and terminate. §§1–7 below define the machinery that becomes live once it lands.

## 1. Consumption map (anti-duplication contract)

| Machinery | SSOT | Mode J's use |
|---|---|---|
| Coverage-seam set + per-seam grade vocabulary + coverage-index formula | `decision-audit-dimension-rubric.md` | scored verbatim; **zero locally-defined seams**. This is the constraint that makes the capability-versus-scorecard consistency check mechanical rather than a prose judgment |
| **Oracle (PRIMARY): the hub's decision invariants** | `release/skills/release-hub/SKILL.md` | the sink-disposition invariant every hub finding must satisfy; derived at run time (§3), never enumerated here |
| **Oracle (PRIMARY): the named decision failure modes** | the `## Domain-Specific Failure Modes` sections of the release-orchestration skills | the detection oracle — was each named failure mode caught when its signature occurred? Derived and pinned per run (§3) |
| **Oracle (SECONDARY): the decision-conduct disciplines** | [`core/disciplines/decision-discipline.md`](../../../disciplines/decision-discipline.md) + [`core/disciplines/autonomous-execution-model.md`](../../../disciplines/autonomous-execution-model.md) | the decision-class taxonomy and the retry / escalate / rollback posture a run classifies observed conduct against |
| Release-record readers | [`release/releases/RELEASE_LOG.md`](../../../../release/releases/RELEASE_LOG.md) per-release entries + the per-release notes | window bounds and the per-release decision surface (§2) |
| Event-stream reader | the pipeline event log, queried by window | the per-decision evidence rows (§4). The query tool and the log schema are owned by the telemetry-emission work; this spec reads them, it does not define them |
| Observation format | the observation issue template (three fields: what is missing / what good looks like / which file or section) | applied to every issue draft |
| Severity / confidence enum | [`core/disciplines/review-discipline-principles.md`](../../../disciplines/review-discipline-principles.md) §5 severity plus the platform confidence enum | reused verbatim; no new vocabulary coined |
| Root-cause format | `review-discipline-principles.md` §2 — systemic pattern, then proximal cause, then observable signal | every finding carries the full chain |
| Six-deliverable output structure | `review-discipline-principles.md` | the emission shape (§6); this spec does not restate the six |
| Analysis-folder conventions | [`core/standards/analysis-workspace-standard.md`](../../../standards/analysis-workspace-standard.md) | folder naming, frontmatter, and the sunset rule |
| Batch query limits | [`core/rules/git-workflow.md`](../../../rules/git-workflow.md) § Batch CLI Query Limits | applied to every backlog and release-record search |

## 2. Window resolution

A run audits a **release window** — a contiguous span of the release record, not an arbitrary
date range. Resolving it is the first machinery step because every later step is scoped by it.

1. **Bound the window by release-record anchors.** The window is `(from_release, to_release]`,
   each identified by its release-log row. A caller may supply either bound; an unsupplied
   `to_release` defaults to the most recent row in a terminal state, and an unsupplied
   `from_release` defaults to the `to_release` of the most recent prior audit as recorded in
   the committed summary surface (§7b) — so consecutive runs tile the record without gaps and
   without overlap.
2. **Resolve each bound to a merge anchor.** Each release-log row carries its merge commit;
   that anchor, not the row's date, is the window's real boundary. Dates in the release record
   are reporting dates and are not reliable ordering keys, because release version numbers are
   slot identifiers rather than sequence ordinals — a higher-numbered release may have merged
   first. **Order the window by merge anchor, never by version number.**
3. **Record the resolved window in both emitted surfaces**: both bounds, both merge anchors,
   and the count of releases the window spans.
4. **Refuse a window that cannot be resolved.** A bound that does not resolve to a release-log
   row, or a window whose anchors do not order, reports INDETERMINATE naming the unresolvable
   bound. It never silently widens to "everything" or narrows to "the latest release".

## 3. Oracle derivation and pinning

**The oracle set is derived at run time and pinned. It is never hardcoded, and no artifact of
this mode carries an oracle cardinality.** This is a standing requirement, and it exists
because the observation that motivated it is self-exemplifying: the capability's own intake
carried a cached count of named failure modes that did not reconcile against a live structured
count of the same sources. A frozen cardinality is invalidated silently by a single new entry,
which is exactly the class of decay a decision audit exists to surface. An audit that inherits
that failure mode cannot credibly report it.

**Derivation:**

1. **Resolve the oracle-source roster from the corpus**, never from an inline list. The roster
   is the set of release-orchestration skill definitions that declare a named failure-mode
   section; resolve it by scanning the release module's skill directories for that section
   heading rather than by naming files.
2. **Count each source with a section-scoped probe, not a whole-file match.** The entries are
   the third-level headings *between* the failure-mode section heading and the next
   second-level heading. A whole-file heading count over-counts, because these files carry
   third-level headings in several other sections.
3. **Run a control on every derivation.** Assert that the section-scoped count is strictly less
   than the whole-file count for at least one source. If the two are equal everywhere, the
   section boundary is not doing its work and the probe has degenerated to a file-wide match —
   report INDETERMINATE rather than proceeding on a probe that has not been shown to bound.
4. **Derive the invariant oracle the same way** — read the hub's stated decision invariants
   from the hub skill definition at the pinned anchor, rather than carrying a restatement.

**Pinning:** record, in both emitted surfaces, the content hash of each oracle source, the
derivation date, and the derived per-source counts, mirroring the freshness anchor Mode I
carries. A finding that rests on the oracle set is reproducible only against that pin.

**Gradability:** a search across this mode's artifacts for a fixed named-failure-mode count
must return nothing. That is a mechanical assertion, not a reading exercise.

## 4. Evidence collection

For each release in the window, collect the decision surface from four sources, in priority
order. Every collected item carries its source so the evidence bar (§5) is checkable.

| # | Source | What it yields | Priority |
|---|---|---|---|
| 1 | The pipeline event log, queried by window | per-decision rows — the decision, self-repair, scope-change, and iteration event families | **PRIMARY** — the only source with per-decision granularity |
| 2 | The release log's per-release deployment sections | the decisions a release recorded about itself | primary |
| 3 | The ADR corpus entries whose release field falls in the window | the decisions that crossed the ADR bar | primary |
| 4 | The deviation logs inside each release plan in the window | the decisions taken *against* the plan, which are the ones most likely to be unrecorded elsewhere | secondary |

**Stated limitation, carried into every run's summary.** The event stream is the only
per-decision source, so seams with no emission are **blind, not clean** — an unemitted seam
produces no rows, and no rows is indistinguishable from no failures unless the distinction is
stated. Every seam whose evidence count is zero reports as `no-evidence` with the emitting
surface named, never as a passing grade. This is the single most important honesty constraint
in the mode: a coverage index computed over a partly-blind stream reads as health when it is
measuring silence.

## 5. Evidence bar

Every finding cites a reproducible location: a file path with a line or section anchor, an
event-log row identified by its window and key, a release-log row identified by its release,
or a runnable command with its output. A finding that cannot be pinned to one of those four
forms is not emitted — it is reported as an unpinnable observation with the missing input
named. Sample the emitted set before writing and record the aggregate pass rate in the summary.

## 6. Emission — the six-deliverable set

A run emits the review-discipline six-deliverable set into the dated audit folder. The six are
defined in `review-discipline-principles.md` and are not restated here; the mode-specific
bindings are:

- **Findings** carry the full root-cause chain, a severity, and a confidence, on the two-axis
  model — severity on its own axis, confidence on an orthogonal axis, so a high-severity
  finding under a low-confidence oracle surfaces as high-and-low rather than being diluted to
  medium.
- **Systemic patterns** are the cross-release recurrences: the same decision failure signature
  in two or more releases in the window.
- **The residual risk register** carries every seam reporting `no-evidence`, because an
  unmeasured seam is a residual risk rather than a finding.
- **Remediation priority** is ordered but never prescriptive — see the mutation posture below.

## 7. Artifact schemas

Mode J emits **two** surfaces — the full read-once analysis folder (git-ignored) and a small
committed handoff surface (tracked, so a consumer and a tracked acceptance criterion can read
it off any instance).

**(a) The dated audit folder** at
`<OPERATOR_INSTANCE_ANALYSIS_PATH>/decision-audit-${AUDIT_DATE_UTC}/` — operator-instance,
git-ignored, where `${AUDIT_DATE_UTC}` resolves at **run time** via `date -u +%Y-%m-%d`. The
literal token appears in this spec by design; a resolved date written into a spec is a defect.

- **SUMMARY.md** — analysis frontmatter per the analysis-workspace standard, plus the resolved
  window (both bounds and both merge anchors), the oracle pin (per-source content hashes,
  derivation date, derived per-source counts), the coverage scorecard rendered from the rubric,
  the classification counts, the count of seams reporting `no-evidence` with the blind-versus-
  clean distinction stated, and the evidence-bar pass rate.
- **findings-register.md** — one row per finding:
  `| finding-id | release (version + merge anchor) | seam | oracle (invariant / named failure mode) | classification | severity | confidence | evidence | root-cause |`,
  plus a `## Systemic Patterns` table for cross-release recurrences and a single
  `## Coverage Gap` aggregate row for the `no-evidence` seams.
- **issue-drafts/NNN-kebab-name.md** — observation format, three fields, ready for operator
  triage; never auto-filed.

**(b) The committed summary handoff** at `release/releases/decision-health-summary.md` —
tracked, present on every clone, seeded with an awaiting-first-run state and **overwritten**
by each run (single-record-overwrite, like a status snapshot). It carries the decision-health
posture, the coverage index, the classification counts, the `no-evidence` seam count, the
oracle pin, the resolved window, the audit date, and a pointer to the latest folder in (a).

**Why the committed surface is load-bearing, not decoration.** The analysis workspace is
git-ignored, so an acceptance criterion or a downstream consumer that cites only the folder
has no oracle on any instance but the producing one. The committed surface is what makes a
tracked criterion gradable and what lets the window's `from_release` default resolve on a
fresh clone.

## 8. Mutation posture

**OBSERVE-only.** A run writes the git-ignored dated folder, overwrites the committed summary
handoff, and echoes a summary in the invoking surface. It creates no work item, mutates no
backlog or registry, and edits no other tracked file. Findings are observations until the
operator triages them.

Run the observational self-check before emitting: scan the emitted artifacts for prescriptive
verbs and rewrite them into observed state plus evidence. Fix-shaped content belongs in the
issue drafts, in observation format — not in the findings register. A prescriptive audit
pre-empts the operator's triage authority and evades the intake templates' field scaffolding.

## 9. Fixtures and regression

The capability build lands `evals/decision-audit-characterization-fixtures.md`, mirroring the
per-mode fixture precedent the sibling audit modes set. Minimum families: a window with a
recorded and evidenced decision (expect conformant), a window with an undetected named failure
mode (expect a finding), a window with an unemitted seam (expect `no-evidence`, never a pass),
and a two-release recurrence (expect a systemic pattern).
