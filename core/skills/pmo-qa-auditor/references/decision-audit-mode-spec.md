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

## 1. Consumption map (anti-duplication contract)

| Machinery | SSOT | Mode J's use |
|---|---|---|
| Coverage-seam set + the coverage-state and grade vocabularies with their assignment predicates + the coverage-index formula and its instrumentation-ceiling companion + the comparability guard | `decision-audit-dimension-rubric.md` | scored verbatim; **zero locally-defined seams**. This is the constraint that makes the capability-versus-scorecard consistency check mechanical rather than a prose judgment |
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

**Step 0 — the rubric-absence guard (runtime, not a provisioning state).** Resolve the rubric
path before deriving anything. The rubric ships, so its absence is not an expected state — but
a partial deploy, a mirror that did not sync, or a package built before it landed all produce
one. On absence, emit the notice naming the missing file and **terminate**. Do not improvise a
seam set, do not score against an ad-hoc rubric, and do not emit a partial scorecard: a
fabricated baseline is worse than an absent one, because a later run would silently measure
drift against noise.

**Derivation:**

1. **Resolve the roster of oracle sources from the corpus by a frozen structural predicate**,
   never from an inline list and never from an unstated reading. All three conjuncts are
   machine-checkable: **c1** the file is a `SKILL.md` under the release module's skill tree;
   **c2** its skill name is a member of the deployed release-skill roster held in the deploy
   script; **c3** the file carries the named failure-mode section heading. The predicate is
   frozen rather than left to the scanner's judgment because defensible readings of a
   roster rule select different source sets, and two runs deriving different sets from one rule
   compare incomparable indices — a worse failure than an encoded count, which is at least
   visible. Conjunct **c2** excludes the self-test canary by construction: it is a deliberately
   non-conformant permanent fixture, and scoring decision health against an artifact built to
   fail is not a matter of taste. The predicate's full canonicalization, including what it
   costs, is recorded in the rubric's reconciliation record.
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

**Pinning:** record, in both emitted surfaces and per oracle source, the repo-relative path, the
content hash, the entry count, and the **entry-title set**; plus the **roster membership set**
as a whole and the derivation date. This mirrors the freshness anchor Mode I carries and extends
it on the membership axis. A finding that rests on the oracle set is reproducible only against
that pin.

**Roster-delta notice.** Read the prior pin from the committed summary surface (§7b) and emit a
notice naming any oracle source **added or removed** since it. The continuity rule makes adding
a source an oracle change; that rule is mechanically enforceable only if a run can *see* the
change, which is what the membership field of the pin is for — a pin carrying only hashes and
counts cannot be diffed for membership, so two runs would compare indices over different rosters
and read the difference as decision-health movement.

**Why the hash field is the half that earns its keep.** A source's content can change while its
entry count and its ordered entry-title set stay identical. That is not a hypothetical: it was
measured on a live sibling release editing one of these sources. A derivation that is merely
cardinality-free reports no drift in that case and is wrong.

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

### Per-seam collection binding

The rubric declares which seams exist and what each one is; this table binds each **declared
identifier** to the collection mechanics a run executes for it — which of the four sources above
it queries, and whether it must additionally read a surface outside the event log. **No seam is
defined here.** A seam's name, decision class, emitting surface, evidence key and baseline
source live in the rubric and are not restated; if this table and the rubric ever disagree on
which identifiers exist, the rubric is right and the run refuses (see the set-equality assertion
below).

| `DS-id` | Event-log query the run issues | Additional surface the run must read |
|---|---|---|
| `DS1` | the `decision` family, less the subtypes `DS3`, `DS4` and `DS6` claim | — |
| `DS2` | the `gate-outcome` family | — |
| `DS3` | the `escalation`, `scope-change` and `iteration` families, plus the `decision` subtypes this seam claims | the hub-state action-item ledger for the window's milestones |
| `DS4` | the `decision` family restricted to this seam's subtype | the payload convention's provenance enum, read at run time to resolve the occasion classes |
| `DS5` | the `self-repair` family | — |
| `DS6` | the `decision` family restricted to this seam's subtype | — |
| `DS7` | the `spoke-launch` family | the hub's rendered admission-verdict line for each launch in the window |

**Two bindings read a surface the event log does not carry, and both are load-bearing.** `DS3`'s
ledger sits at an operator-instance path, so it is non-retrievable on a fresh clone — the seam's
event-log locus stands alone there, and a run in that position says so in its summary rather
than grading the ledger half silently. `DS7`'s rendered verdict line is produced at every launch
under a standing obligation but is **ephemeral**: it is not queryable at audit time, so it
confers no instrumentation under §3's declared-producer test even though it is named here as the
surface a run should read where the session record still holds it.

**Set-equality assertion.** After deriving, the run asserts that the seam-identifier set it
emits **equals** the set the rubric declares — equality, not overlap, and both sides non-empty.
On inequality it reports INDETERMINATE naming the differing identifiers and does not score:
emitting a scorecard over a set the rubric does not declare would publish an index whose
denominator no one can reconstruct. This is the runtime half of the same single-definition-site
constraint the consumption map (§1) states.

**Stated limitation, carried into every run's summary.** The event stream is the only
per-decision source, so a seam **for which no producer is declared** is **blind, not clean** —
it can emit no rows, and no rows is indistinguishable from no failures unless the distinction is
stated. This is the single most important honesty constraint in the mode: a coverage index
computed over a partly-blind stream reads as health when it is measuring silence.

**Zero rows does not resolve to one state, and the rubric decides which.** A seam with no rows
is `uninstrumented` when no corpus rule declares a writer for any of its loci, and `unexercised`
when a writer exists and the window owed it nothing; and a seam that is instrumented, was owed
occasions, and produced nothing is **`measured` / `partial`** — a shortfall, not an absence.
Only the first of those is blind. Whichever state applies, the seam reports **with its emitting
surface named**, and a non-graded state is **never** rendered as a passing grade. The ordered
predicate that assigns the state lives in the rubric and is not restated here.

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
- **The residual risk register** carries every seam reporting `uninstrumented`, because a seam
  the platform cannot see is a residual risk rather than a finding. It does **not** carry an
  `unexercised` seam — a writer exists and nothing was owed, so there is no unmeasured risk to
  register. The one qualification is the measurement gap: a seam carrying any `indeterminate`
  occasion class may not render `unexercised` and **retains** register membership, because
  *the surface that would say what was owed cannot be read from here* is not the same fact as
  *nothing was owed*.
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
  window (both bounds and both merge anchors), the oracle pin (per-source path, content hash,
  entry count and entry-title set; the roster membership set; the derivation date), any
  roster-delta notice, the coverage scorecard rendered from the rubric, the classification
  counts, the coverage-state distribution with the `uninstrumented` and `unexercised` counts
  reported **separately** and the blind-versus-quiet distinction stated, the coverage index, the
  instrumentation ceiling, and the evidence-bar pass rate.
- **findings-register.md** — one row per finding:
  `| finding-id | release (version + merge anchor) | seam | oracle (invariant / named failure mode) | classification | severity | confidence | evidence | root-cause |`,
  plus a `## Systemic Patterns` table for cross-release recurrences and a single
  `## Coverage Gap` aggregate row for the `uninstrumented` seams. An `unexercised` seam is not a
  coverage gap — its writer exists and the window owed it nothing — and it is reported in the
  distribution rather than in that row.
- **issue-drafts/NNN-kebab-name.md** — observation format, three fields, ready for operator
  triage; never auto-filed.

**(b) The committed summary handoff** at `release/releases/decision-health-summary.md` —
tracked, present on every clone, seeded with an awaiting-first-run state and **overwritten**
by each run (single-record-overwrite, like a status snapshot). It carries the decision-health
posture, the coverage index, the **instrumentation ceiling**, the classification counts, the
coverage-state distribution with the `uninstrumented` and `unexercised` counts reported
**separately**, the oracle pin including its roster membership, the resolved window, the audit
date, and a pointer to the latest folder in (a).

**The ceiling is a rendered field, not a note.** A reader must be able to see the reachable
bound beside the index without reconstructing it, because a persistently sub-maximal index
below a sub-maximal ceiling is the instrumentation gap being reported honestly — not evidence
of ill decision-health. Rendering only the number invites exactly that misreading.

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

`evals/decision-audit-characterization-fixtures.md` carries the families, mirroring the per-mode
fixture precedent the sibling audit modes set. The families cover window resolution, roster
derivation, the derivation control arm, coverage-state discrimination, classification, index
arithmetic, the ceiling term, and the evidence bar.

**Four of them exist to prove a mechanism can fail**, and they are named here because a control
arm nothing exercises is indistinguishable from one that cannot fire:

- **the degenerate section boundary** — a corpus in which every source's section-scoped count
  equals its whole-file heading count must report INDETERMINATE, not proceed. This is the arm
  for §3 step 3.
- **instrumented, occasions owed, no rows** — must render `measured` / `partial`, never
  `unexercised` and never `uninstrumented`. Without it, the state the coverage axis exists to
  expose can silently regress into a benign class.
- **an occasion class that cannot be read** — must resolve `indeterminate` rather than zero, so
  the seam may not render `unexercised` and keeps its register membership.
- **evidence from an undeclared producer** — must surface a finding rather than an arithmetic
  error, which is the branch that makes the index-versus-ceiling relation a detector.

The classification family additionally covers a recorded and evidenced decision (expect
conformant), an undetected named failure mode (expect a finding), a zero-row seam (expect a
non-graded state and **no grade**), and a two-release recurrence (expect exactly one systemic
pattern).
