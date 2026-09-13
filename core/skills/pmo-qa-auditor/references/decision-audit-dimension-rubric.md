---
title: Decision-Health Audit — Dimension Rubric
purpose: The content SSOT for pmo-qa-auditor Mode J (decision-health audit) — the coverage-seam set, the coverage-state and grade vocabularies and their assignment predicates, the coverage-index formula and its instrumentation-ceiling companion, and the run-over-run comparability guard.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Decision-Health Audit — Dimension Rubric (Mode J content SSOT)

> Mode J (`decision-audit-mode-spec.md`) consumes this file verbatim — the coverage-seam set,
> the two vocabularies and their predicates, the index formula, the ceiling term, and the
> comparability guard all live here and nowhere else. The mode-spec defines **zero** seams
> locally; that constraint is what makes *"the emitted set equals the rubric set"* a set-equality
> assertion over two extractions rather than a prose judgment. When-to-run authority is
> [`release/references/protocols/decision-audit-cadence.md`](../../../../release/references/protocols/decision-audit-cadence.md).
> Re-tuning any predicate, value, or term is an edit to THIS file only (governed edit;
> continuity per the cadence doc §5).

## 1. What this rubric scores — the coverage-seam set

A **seam** is a decision class the platform's own governance says is made somewhere, paired with
the surface where evidence for it would appear. Each row is scored independently per run.

**Column contract — every column is mandatory, and the order is fixed:**

| Column | What it holds |
|---|---|
| `DS-id` | the seam's stable identifier (grammar below) |
| Seam name | the decision class, named in the governance's own terms |
| Decision class | which decision-conduct taxonomy the class belongs to |
| **Emitting surface** | the concrete surface where evidence for this seam would appear |
| Evidence key | the `select` predicate that pulls this seam's rows, paired with the `denom` rule that defines what the window owed it |
| Baseline source | the corpus rule that establishes the obligation, cited by **delimiter plus stable key** |

**A row whose emitting surface does not resolve is not a valid seam.** This is a shape
constraint rather than a run-time check, and it is what makes the mode-spec's honesty rule —
a non-graded seam is reported *with its emitting surface named* — satisfiable by construction.

**Identifier grammar.** `DS<n>`, with **no reuse of a retired id**. Ids are stable opaque keys
and nothing downstream reads the ordinal: the comparability guard (§3) compares identifier
**sets**, and the oracle pin diffs **membership**. Contiguity is deliberately **not** required —
the governing cadence protocol permits a seam to be retired with a rationale, and requiring both
contiguity and no-reuse would leave that operation with no satisfying assignment: leaving the
gap violates contiguity, and renumbering reoccupies a retired id and silently re-keys every
prior run's pin.

**Baseline sources are cited by delimiter plus stable key, never by line ordinal.** A cell names
*the `EMISSION-CONTRACT` block, the rows whose `event_type` and `event_subtype` match this seam's
selector* — not the rows' positions. These citations are a run-time **resolver**, not historical
provenance, so an ordinal that shifts when anything above it changes would silently re-point the
predicate rather than merely dating a reference.

**The shared denominator rule, stated once so no cell restates it.** Every seam's `denom`
resolves against the obligation class the matched source rows already carry. For each matched
row tagged `MUST`, the window owes **one occasion per completed release in it** — the block's
own partition predicate is *structural guarantee in a completed release, not observed
frequency*, so a `MUST` row is total over completed releases. For each matched row tagged
`CONDITIONAL`, the window owes **one occasion per firing of that row's gate that the window's
own record independently evidences**. A seam's cell therefore names only the occasion classes
it carries *beyond* this rule. Resolving the denominator from the matched rows' own obligation
tags — rather than from an enumeration held here — is what keeps a later obligation from
entering the block and escaping every seam's denominator unnoticed (§4.8).

| `DS-id` | Seam name | Decision class | Emitting surface | Evidence key (`select` · `denom`) | Baseline source |
|---|---|---|---|---|---|
| **DS1** | **Routing-point decision** — a decision rendered at a hub routing point is recorded with its outcome | operator-gate ∪ deterministic-rule · operator-in-loop | event log · `decision`/\* less the subtypes DS3, DS4 and DS6 claim | **select:** `event_type=decision` ∧ `event_subtype` ∉ (the DS3, DS4 and DS6 selectors) · **denom:** the shared rule over every matched row, with no occasion class beyond it | the `EMISSION-CONTRACT` block, the rows whose `event_type` · `event_subtype` match this seam's selector, keyed by each row's `gate` value; plus the per-stage Audit-Trail-Capture tables for the `decision` subtypes the block delegates to a stage spec |
| **DS2** | **Gate verdict** — a stage or release gate's verdict is recorded with its evaluation | composed-specialist ∪ operator-gate · operator-in-loop at the release gate | event log · `gate-outcome`/\* | **select:** `event_type=gate-outcome` · **denom:** the shared rule, plus one occasion per stage-gate the release actually traversed whose stage spec assigns it a `gate-outcome` row | the `EMISSION-CONTRACT` block, rows matching this seam's selector, keyed by `gate`; the per-stage Audit-Trail-Capture tables; [`core/schemas/gate-evaluation-spec.md`](../../../schemas/gate-evaluation-spec.md) § the verdict contract |
| **DS3** | **Finding raise-and-disposition** — every finding raised is tiered and resolved to a sink, and the disposition is recorded | operator-gate ∪ composed-specialist · operator-in-loop | event log · `escalation`/\*, `scope-change`/\*, `iteration`/\*, `decision`/ the action-item lifecycle subtypes together with `queued-pending-approval`, `approval-deferred` and `empirical-verification-finding`; **and** the hub-state action-item ledger for the window's milestones | **select:** the union of those loci, plus the ledger's action-item rows · **denom:** the shared rule, plus one occasion per tiered finding the window's deviation logs and stage sub-tasks record | the `EMISSION-CONTRACT` block, rows matching this seam's selector, keyed by `gate`; [`core/standards/hub-action-tracking.md`](../../../standards/hub-action-tracking.md) § the action-item scan cadence and its close-time attestation gate; [`release/skills/release-hub/SKILL.md`](../../../../release/skills/release-hub/SKILL.md) § the sink-disposition invariant this seam measures |
| **DS4** | **Recommendation-choice delta** — the agent's prior recommendation is recorded against the rendered choice, the zero-delta case included | operator-gate · operator-in-loop | event log · `decision`/`recommendation-choice-delta` | **select:** `event_type=decision` ∧ `event_subtype=recommendation-choice-delta` · **denom:** the shared rule, plus one occasion per decision moment named by the `via:` provenance enum, **resolved from that enum at run time** rather than from any list held here | the `recommendation-choice-delta` payload convention in [`release/references/standards/pipeline-event-log-schema.md`](../../../../release/references/standards/pipeline-event-log-schema.md), keyed by the subtype name — its `via:` provenance enum and its rule that the aligned state is recorded explicitly and never silently omitted; plus the `EMISSION-CONTRACT` block rows matching this seam's selector, keyed by `gate` |
| **DS5** | **Self-repair election** — each retry, escalate or rollback is recorded at the moment it is elected | deterministic-rule · **no operator in the loop** (rollback excepted — operator-authorized) | event log · `self-repair`/\* | **select:** `event_type=self-repair` · **denom:** the shared rule, plus one occasion per recovery the window's own record independently evidences — a suite failure routed back to Engineering, an escalation row, an iteration pass beyond the first, a recorded spoke re-spawn | the `EMISSION-CONTRACT` block, rows matching this seam's selector, keyed by `gate`; [`core/disciplines/autonomous-execution-model.md`](../../../disciplines/autonomous-execution-model.md) § Emission — the governing rule that matched row delegates to, which is where the `escalate` and `rollback` loci are named |
| **DS6** | **Delegation fork** — each spawn-versus-hub-direct merit fork is recorded with the merit condition that fired | deterministic-rule · **no operator in the loop** | event log · `decision`/`delegation` | **select:** `event_type=decision` ∧ `event_subtype=delegation` · **denom:** the shared rule, restricted to the **independently-evidenced** merit forks. Routine template routing is **not** in the denominator — silence there is correct by rule, not a shortfall | the `EMISSION-CONTRACT` block, the row matching this seam's selector, keyed by `gate`; [`core/disciplines/decision-discipline.md`](../../../disciplines/decision-discipline.md) § the delegation merit test and its reviewability clause, which is the rule that decides which forks are owed a row |
| **DS7** | **Launch admission** — each spoke launch's admission verdict is recorded with the axis and the basis that produced it | deterministic-rule · **no operator in the loop** (surfaced on any non-`PROCEED`) | event log · `spoke-launch`/\*; **and** the hub's rendered admission-verdict line for that launch | **select:** `event_type=spoke-launch` · **denom:** the shared rule, plus one occasion per `Agent`-tool spoke launch in the window, constructible from the stage sub-tasks the window's releases created together with the recorded re-spawns | [`release/references/standards/quota-budget-protocol.md`](../../../../release/references/standards/quota-budget-protocol.md) § the Checkpoint-B rendering obligation, whose own terms are that silence is a failure rather than a pass; the schema enum row for this seam's locus, which carries the no-producer declaration; plus the `EMISSION-CONTRACT` block rows matching this seam's selector, keyed by `gate` |

**Totality and disjointness — stated so they can be falsified.** Every decision-bearing
`(event_type · event_subtype)` the schema enum carries belongs to **exactly one** row above.
Disjointness holds by the admission predicate's third conjunct (§4.6) and is checkable by
intersecting the seven selector sets pairwise. Totality holds because DS1's selector is a
**complement**: it claims every `decision` subtype the other rows do not, so a subtype added
to the schema lands in DS1 rather than falling through unmeasured. Both are stated as
machine-checkable assertions rather than as prose judgments, and §4.8 specifies the fixture
family that is required to exercise them.

**Why DS1 is one seam rather than two.** The operator-rendered routing decisions and the hub's
rule-determined recorded determinations share the **same** locus, `decision`/`d-class`, and the
admission predicate forbids assigning one locus to two seams. The distinction is not lost: the
`actor` column separates them on every row, and a run reports that split *within* the seam. The
predicate is doing real work here — it cut a distinction the author wanted to keep.

The seam set is **the reconciled set (§4), not a cap** — roster changes are governed by the
cadence-doc §5 continuity rule (note additions, rationale for removals, in the run's
`SUMMARY.md`).

## 2. Coverage state and grade — two orthogonal axes

The axes are separate and the separation is load-bearing: **coverage state is mechanical**,
derived from the corpus and the window without judgment, while **grade is observational** and
applies **only** to a `measured` seam. A seam in any other coverage state takes **no grade at
all** — it is unmeasured, not badly graded.

### 2.1 Coverage state — resolved in this order

The values are total and disjoint by construction. Evaluate in order; the first match wins.

| Order | Value | Predicate | Takes a grade? |
|---|---|---|---|
| 1 | **`measured`** | `rows(s,W) > 0` **∨** ( `instrumented(s)` **∧** `occasions(s,W) > 0` ) | **yes** — `captured` \| `partial` |
| 2 | **`uninstrumented`** | not `measured` **∧** `¬instrumented(s)` | **no** |
| 3 | **`unexercised`** | not `measured` **∧** `instrumented(s)` **∧** `occasions(s,W) = 0` | **no** |

`measured` reads *"the seam was measurable over this window"*, not *"evidence arrived"*.
Evidence presence lives entirely on the grade axis, where `captured` versus `partial` already
distinguishes it.

**Why the first predicate carries a disjunct — the state that has nowhere else to go.** Take a
seam that is instrumented, whose window owed it occasions, and for which no rows arrived: the
emitter exists, rows were owed, and none came. That is the most actionable state this audit
produces, and both other placements read benign — `unexercised` says nothing happened, which
inverts the truth, and `uninstrumented` says known blind spot, which excuses a live emission
failure. The disjunct routes it to `measured` / `partial`, where a reader sees it as a shortfall
and where the findings register carries it.

**A non-graded state is never a passing grade.** That constraint is inherited verbatim and is
not weakened by there being more than one such state: neither `uninstrumented` nor `unexercised`
is ever written as a grade, in the emitted artifacts or in prose.

**Of the non-graded states, only `uninstrumented` is blind.** It means the platform cannot
see this decision class at all, and it is what the residual-risk register carries.
`unexercised` means a writer exists and the window simply owed nothing — quiet, not blind, and
not a residual risk. Reporting them as one number would render a live blind spot and an
uneventful window identically.

### 2.2 `instrumented(s)` — the declared-producer test

`instrumented(s)` must be decidable from the corpus without prose judgment, or the coverage
axis becomes an authoring choice and two runs compare incomparable indices. It is resolved at
**locus** grain, from the **emitting surface** and **baseline source** cells the §1 contract
already mandates. **It adds no column and no new corpus surface.**

`instrumented(locus)` holds when **either** limb holds:

- **i1** — a row inside the `EMISSION-CONTRACT` delimiters names that exact
  (`event_type` · `event_subtype`) pair;
- **i2** — a corpus rule names a **writer** for that locus: an `append-pipeline-event.sh`
  invocation bound to that `event_type`, or an event-log-schema enum row for that locus carrying
  **no** no-producer declaration.

`instrumented(s)` holds when **≥1 locus** of the seam is instrumented. Partial instrumentation
inside a measurable seam is a **grade** concern (`partial`), never a coverage-state one — the
same allocation §2.1's first predicate makes, applied one level down.

**Why the test asks for a writer rather than for an obligation.** The two questions are
different — *the class has an obligation* versus *the locus has a producer* — and only the
second decides whether evidence can arrive. A surface can carry a rendering obligation in
emphatic terms and state one sentence later that it emits no event at all; an obligation-shaped
list admits exactly that surface, and only reading the prose separates it from a real emit
point. The declared-producer form excludes it directly: a render that emits nothing has no
writer and fails the test. Both limbs resolve against independently-maintained surfaces, one of
which already carries a CI lint.

### 2.3 `occasions(s,W)` — and the measurement gap that is not a zero

`occasions(s,W)` is the count of times the window owed the seam a row, per the `denom` rule in
its evidence-key cell.

**A seam carrying any `indeterminate` occasion class may not render `unexercised`, and it
retains residual-risk register membership.** An occasion class resolves `indeterminate` — never
a measured zero — whenever its evidencing surface is not retrievable at audit time.

This is the denominator-side twin of §2.2's rule, and it exists because the two ways of arriving
at zero are not the same fact. *Nothing was owed* is a measurement; *the surface that would say
what was owed cannot be read from here* is a measurement gap. Collapsing them lets a seam that
was blind in exactly this window exit the register asserting it was merely quiet — the benign
reading this axis was widened to prevent, relocated from the coverage label to register
membership.

### 2.4 Grade — for a `measured` seam only

| Value | Meaning |
|---|---|
| **`captured`** | every occasion the window owed the seam is evidenced by a well-formed row |
| **`partial`** | the seam is measurable and its record is incomplete — rows missing against owed occasions, or present but malformed |

Per-seam behavioural anchors specialize these two values against each seam's own evidence key,
and are authored beside the rows they grade.

`rows(s,W)` is the set of event rows the seam's `select` predicate returns over the window —
the counterpart to `occasions(s,W)`, which §2.3 resolves from the same cell's `denom` rule. The
two are the numerator-side and denominator-side reads of one evidence key, and the grade is the
comparison between them.

**`captured` requires both limbs; `partial` is the failure of either.** A seam grades
`captured` when **every** occasion in `occasions(s,W)` is evidenced by at least one
corresponding row **and** every returned row is **well-formed** against its own payload
convention. Otherwise it grades `partial`.

**Well-formedness is the second limb, not decoration.** A delegation row carrying no merit
condition, or a delta row carrying no delta value, records that something happened without
recording what was decided — the seam observable in count and blind in content. Grading such a
row `captured` would let a complete-looking record stand in for a decided one, which is the
count-versus-content distinction this whole axis exists to keep.

### 2.5 Per-seam behavioural anchors

Each `captured` cell states the **observable state** a reader should be able to confirm; each
`partial` cell states that seam's own **diagnostic shortfall** — the coverage-gap shape to
expect — on top of the generic boundary above.

| `DS-id` | `captured` — the observable state | `partial` — the seam's diagnostic shortfall |
|---|---|---|
| **DS1** | Every completed release carries the rows its matched `MUST` obligations owe, and every conditional routing-point decision the release record evidences carries a row naming a subject and an outcome that both resolve against that record | a row whose subject or outcome does not resolve against the release record — the decision recorded as having happened, but not as having been *about* anything retrievable |
| **DS2** | Every completed release carries its release-gate verdict row, and every stage-gate the release traversed carries the verdict row its own stage spec assigns it | a release shipping with an unrecorded intermediate gate verdict — the release gate present, the stage gates it rests on silent |
| **DS3** | Every finding the deviation logs and stage sub-tasks record carries **both** a raise row and a terminal disposition — a row, or a resolved ledger entry — and every completed release's close-time attestation is recorded | a raised finding with no terminal disposition; **or** the ledger absent for a milestone whose window carries decision-class events, which the attestation vocabulary treats as *not recorded* rather than as a clean release |
| **DS4** | Every decision moment the `via:` enum names carries a delta row, **the aligned zero-delta case included** — the aligned row is what separates *the recommendation was adopted* from *nobody recorded anything* | rows appearing only where the choice diverged, so the aligned state is inferred from silence rather than read from a record |
| **DS5** | Every recovery occasion the window independently evidences carries its row at the elected pattern, one row per attempt, with the terminal outcome on the last row so the cap state is legible | an escalation row with no companion `escalate` row; **or** a retry sequence collapsed into a single row, which erases the cap state the per-attempt rule exists to preserve |
| **DS6** | Every independently-evidenced merit fork carries a `delegation` row naming which merit condition fired | a row omitting the merit condition — recording the fork without recording what made it one |
| **DS7** | Every spoke launch carries its admission row with the verdict and the basis in force, on both axes | a row recording a verdict with no basis token, which cannot tell a reader which axis produced it |

## 3. Coverage index, instrumentation ceiling, and comparability

### 3.1 The index

```
coverage_index = |{ s ∈ SEAMS(rubric) : coverage(s) = measured ∧ grade(s) = captured }| ÷ |SEAMS(rubric)|
```

Both terms are obtained by counting rubric rows at run time. **No literal appears anywhere.**

The headline counts only fully-captured seams. Crediting `partial` toward it would inflate
observability, which is the failure the mode's honesty constraint exists to prevent — an index
that reads as health while measuring silence. The full distribution renders **alongside** the
index, so movement from partial toward full capture stays visible even though the headline moves
only on complete capture.

**The index is a lower bound on decision-observability, by design.** A reader asking how much of
what happened got recorded reads the index; a reader comparing observability across windows
reads the ceiling and the distribution.

### 3.2 The ceiling

```
instrumentation_ceiling = |{ s ∈ SEAMS(rubric) : instrumented(s) }| ÷ |SEAMS(rubric)|
```

The ceiling is defined on `instrumented(s)`, which resolves purely from corpus surfaces and
**carries no window term**. It is therefore genuinely window-invariant and rises only as
instrumentation lands — which is what a reader watching a blind class become observable needs it
to do. A ceiling defined instead on the complement of `uninstrumented` would inherit the window
term through that value's own predicate, so a seam with no declared writer that happens to emit
in an active window would enter the ceiling and drop out of a quiet one: two runs, identical
instrumentation, different ceilings.

**`coverage_index > instrumentation_ceiling` is a detector, not an arithmetic error.** The
relation does not hold by construction under this definition, and that is the point: a run
observing it violated has found evidence arriving from a producer **no corpus rule declares**.
Surface it as a finding. Neither term is clamped.

### 3.3 Comparability guard

The index is comparable run-over-run **only while the rubric's seam-identifier set is
unchanged**. A changed set is an oracle change: the run renders the index as **`re-based`** and
states the identifier delta rather than trending across the discontinuity.

**The guard's trigger is an identifier-set change and is deliberately not widened.** A change to
this section's own vocabulary is a different axis, and the cadence protocol's continuity rule
already carries it — an oracle change noted in the run's `SUMMARY.md`, the same machinery that
carries a roster change. What must not be trended across such a boundary is the **distribution
render** and the ceiling term, not the index, whose arithmetic is unaffected by a relabelling.

### 3.4 Why the index is comparable — the four guards

Appended to §§3.1–3.3 rather than restating them: each guard below forecloses one concrete way
two runs could compute indices that are not comparable, and the first three are properties of
the seam content this rubric carries rather than of the arithmetic above.

| Guard | What it is | The failure it forecloses |
|---|---|---|
| **G-A** | **The seam set is authored, not derived.** A run reads §1's rows; it does not compute them. | Two runs deriving different seam sets from one rule and each believing it complied — the incomparability class that motivated freezing the roster predicate in the first place. Nothing here is derived, so nothing here can be derived differently. |
| **G-B** | **Decision-class grain, with DS1 as complement.** A new emission obligation or a new schema subtype joins an existing seam rather than minting one. | Routine growth silently changing the identifier set, which would trip §3.3's guard on ordinary schema edits and make the index unusable in practice. |
| **G-C** | **Grade by the stated predicate over `select` ÷ `denom`, both carried in the evidence-key cell, with the denominator resolved from the matched rows' own obligation tags.** | Two runs computing different grades from one window because each built its own denominator — the incomparability defect relocated from the roster to the grade, which is where it would otherwise reappear. |
| **G-D** | **The comparability guard of §3.3** — a changed identifier set is an oracle change; the run renders `re-based` and states the delta. | Trending across a discontinuity. |

**The first run under this rubric is a `re-based` render.** The baseline the capability's own
intake cites is an operator-instance analysis artifact that no run, grader or reader can resolve
from this repository, so set-equality against it cannot be established by any run. That is
precisely the condition §3.3 converts into a `re-based` render, and it means the first run's
figures must not be read as a regression against that earlier anchor.

## 4. Reconciliation record (design provenance)

### 4.1 Cardinality-freedom — a shipped rule, stated at its shipped scope

**No artifact of this mode carries a hardcoded oracle cardinality** — not this rubric, not the
mode-spec, not the skill definition, not the cadence protocol. That is a standing rule stated at
every one of those surfaces and at the host decision of record, and it is restated here as the
rule it is rather than as this file's local election.

Its subject is **oracle** cardinality. This release additionally carries `seam` cardinality
under the same constraint, stated as this release's own addition rather than attributed to the
shipped rule. The digit clause is scoped to **bare cardinality integers** — an integer stating
how many members a named set has. Predicate comparators and quantifiers are exempt: a coverage
predicate that reads `rows > 0` or `occasions = 0` is not a cardinality, and neither is a
quantifier such as *at least one locus*. Identifier tokens of the `DS<n>` form and `file:line`
citations are likewise outside it.

**The coverage vocabulary is never stated as a count.** Name the values, or write *"the coverage
vocabulary"*.

This file therefore **diverges deliberately from its sibling rubric**, which closes its own
dimension section by stating that section's cardinality. The equivalent sentence here would be
exactly the construct the rule forbids, so the governed-change path that sentence carries is
preserved above and the number is not.

### 4.2 Resolving the roster of oracle sources

The roster is resolved at run time by a structural predicate, never from an inline list. All
three conjuncts are machine-checkable:

- **c1** — the file is a `SKILL.md` under the release module's skill tree;
- **c2** — its skill name is a member of the deployed release-skill roster held in the deploy
  script (which excludes the self-test canary by construction);
- **c3** — the file carries the named failure-mode section heading.

Entries are the third-level headings strictly between that heading and the next second-level
heading, with fenced blocks excluded. The invariant oracle is resolved separately and singly
from the release hub's own skill definition.

**Why a predicate at all, when the requirement only said "derive at run time".** Three
defensible readings of the shipped roster rule select three different source sets, and a
capability told to derive without a frozen predicate can derive any of them and believe it
complied. Two runs then compare indices computed over different rosters and read the difference
as decision-health movement. Freezing the predicate is therefore more load-bearing than freeing
the count — an encoded cardinality is at least visible, while an unfrozen predicate is not.

**The decisive conjunct is c2, and its purpose is the canary.** The self-test canary skill is a
deliberately non-conformant permanent fixture whose entire purpose is to be detected as broken.
Scoring decision *health* against an artifact built to fail is not a matter of taste. c2
excludes it on a corpus-held, independently-maintained basis rather than by naming it, which is
the resolve-from-the-corpus shape the host decision asks for.

**What the predicate costs, stated plainly.** It selects a superset of the pair of sources the
capability's intake named, so any figure recorded in the intake history is a subtotal rather than
a roster total. Nothing intended is lost; the recorded figure simply measured a narrower set than
the shipped rule specifies. Both are dated anchors and neither is encoded. A wider roster costs
scan effort, not correctness — an oracle entry whose signature does not occur in a window is
simply not exercised, and the residual-risk register is seam-keyed rather than oracle-keyed, so
roster width cannot inflate it.

### 4.3 What the pin carries — membership, not only counts and hashes

The continuity rule makes adding an oracle source an oracle change. That is mechanically true
only if a run can *see* the change, so the pin records, per source: repo-relative path, content
hash, entry count, and the **entry-title set**; plus the roster membership set as a whole. A run
reads the prior pin from the committed summary surface and emits a **roster-delta notice**
naming any source added or removed.

**The content-hash field is the half that earns its keep.** A source's content can change while
its entry count and its ordered entry-title set stay identical — measured, not hypothesized, on
a live sibling release editing one of these sources. A derivation that is merely cardinality-free
reports no drift in that case and is wrong.

### 4.4 `instrumented(s)` — the canonicalization and what it binds

§2.2's declared-producer test is a canonicalization, recorded here beside the roster predicate
because it binds what *"the platform can see this decision class"* means for every future run of
this mode, and for any future audit axis borrowing this shape.

The rejected alternative is worth recording because it is the reading a later editor would
naturally reach for: resolving instrumentation from the obligation surfaces alone. Measured
against the seam set, that rule misclassifies seams whose obligations those surfaces *delegate*
rather than omit, and it admits a surface that declares in terms it emits nothing at all. The
declared-producer form asks the question that actually decides whether evidence can arrive.

### 4.5 Relation to the sibling audit mode

Mode I scores **delivered work** against the platform's architecture baseline; Mode J scores
**decision conduct** against the hub's invariants and its named decision failure modes.
Different unit of analysis, different baseline, no duplication. This rubric mirrors the sibling
rubric's four-section shape and its separation of a scored content set from the machinery that
consumes it; it diverges only where §4.1 records.

### 4.6 The seam-admission predicate, and what "decision-bearing" ranges over

A row is admitted to §1 when **all three** conjuncts hold. The predicate is recorded here
because it is what makes the §1 table falsifiable rather than curated.

- **a1 — declared obligation.** The decision class carries at least one emission obligation
  declared by a locatable corpus rule: a row inside the `EMISSION-CONTRACT` delimiters, or an
  obligation that block **delegates** to a governing discipline.
- **a2 — resolvable emitting surface.** Every `(event_type · event_subtype)` the row names is a
  member of the event-log schema's own enum, and every non-event surface resolves to a corpus
  path or a corpus-declared runtime path token. This is the machine-checkable reading of §1's
  validity clause — *a row whose emitting surface does not resolve is not a valid seam.*
- **a3 — disjoint locus set.** The row's locus set intersects no other row's. Two decision
  classes sharing a locus are **one** seam.

**Decision-bearing, and why the test is stated at subtype grain.** A locus is decision-bearing
when its rows record an **elected outcome** — a choice among available actions made by the
operator, the hub, or a spoke. Event types recording a produced artifact, an observed result, or
a reflection rather than an election are out, and the per-session retrospective is out on the
event log's own terms: it is declared a sensor, never an actuator, and the cadence protocol
states that the retrospective grain and this axis are complementary rather than subsuming.

The grain matters and is easy to get wrong. Stating the test at **event-type** grain while a2,
the selectors and the totality claim all operate at `(event_type · event_subtype)` grain would
admit a non-decision-bearing subtype inside an admitted type with no test applied to it. The
test is therefore applied per locus, not per type.

**a1 versus instrumentation are different questions, and §2.2 is the reason the distinction is
visible.** a1 asks whether the class carries an *obligation*; `instrumented(s)` asks whether the
locus has a *producer*. A seam admitted by a1 and classified `uninstrumented` by §2.2 is not a
contradiction — it is the audit reporting exactly the state it exists to report.

### 4.7 The row-generating rule, and the candidates it beat

The seam set is a **partition of the declared-emission-obligation population by decision
class** — the rows inside the `EMISSION-CONTRACT` delimiters together with the obligations that
block delegates or does not yet carry. The candidates weighed against it, and why each lost:

| Candidate rule | Why it lost |
|---|---|
| One row per decision-bearing locus in the schema enum | Derivable and total, but the span is a property of the **schema**, so ordinary schema growth changes the identifier set and trips §3.3's guard on every subtype addition. It also supplies no denominator — every one would be an authoring judgment. |
| One row per item in the hub's decision-class floor list | **No partition** — the list declares itself a floor rather than a ceiling, and is hub-scoped while this axis covers the hub *and* its spokes. |
| One row per cell of the hub's three-sink invariant | **No partition that can be measured** — no event row records which sink a decision took, so the split can be asserted but never observed, which is the unfalsifiable-probe shape the platform's own probe-validity discipline rejects. |
| One row per pipeline stage cluster | **Wrong grain** — this axis is decision-class-grained, and a decision class recurs across stages. |
| Reconstruct the earlier analysis artifact's own set | **Not available** — that artifact is operator-instance and unreadable from this repository, which is also why §3.4 records the first run as a `re-based` render. |

**The decisive line is the denominator.** A `captured`-versus-`partial` vocabulary is
comparable run-over-run only if both runs agree on how many occasions owed a row, and only the
selected rule takes that quantity from a surface that **already partitions obligations by
structural guarantee in a completed release** — which is exactly the question a denominator
asks. The second line is stability under growth: under the locus-per-row candidate, a single new
obligation shipping in the same release as this rubric would have changed the identifier set and
forced a `re-based` render on the very next run.

### 4.8 Membership resolves from the block; it is never transcribed

**A baseline-source cell names the source and the key, never the rows.** This is the §1 citation
contract applied to its most tempting violation: hand-copying the block's rows into the cells.
The copy is itself an authoring judgment, which silently reintroduces the exact defect the
row-generating rule was selected to eliminate — and no downstream check can see the difference
between a faithful copy and a lossy one.

That is not hypothetical. An earlier draft of this table transcribed the rows, and the
transcription dropped one block row from a seam's denominator and one provenance value from
another's. Both omissions produced a **false-clean rather than a miscount**: a window in which
the dropped gate fired and emitted nothing registered no occasion at all, so the seam graded
`captured` while a declared obligation went unmet. A count-only review cannot find that, because
nothing is miscounted.

Resolving membership from the block by delimiter and stable key closes both, and closes the
class rather than the instances — an obligation added under the block's own extension seam
reaches the matched rows without an edit here.

**The required source-completeness fixture family, specified here and not yet present.** Citing
the block by key removes the hand-copy; it does not by itself prove the resolution is complete,
so the arm that keeps this closed is a fixture family that **parses the block between its
delimiters**, asserts the union of the seams' matched rows **equals** the parsed row set,
asserts the same for the provenance enum against the payload convention, and carries a
**negative control** in which a row deleted from a copy of the block must make the family fail.
A parser for the block already exists and is self-tested, so the family is cheap to add.

**Until that family lands this section states an obligation rather than a shipped control, and
it says so deliberately.** The distinction is the whole subject of §4.9: a control that reads as
enforcement while functioning as a no-op is worse than no control at all. Recording the family
as required — and as absent — keeps that gap countable instead of invisible; asserting it as
present would reproduce, inside this rubric, exactly the false-clean the two omissions above
already produced once.

### 4.9 Relation to the deploy-time decision-emission check

The platform already carries a deploy-time check asserting that every verified release at or
after the emission cutover has at least one event row for **each `MUST` class in the same
`EMISSION-CONTRACT` block**, resolved through the same release join key. Its relation to this
rubric is recorded here so the two per-release emission verdicts read as **complements** rather
than as duplicates discovered to disagree later.

**Extend-before-create determination — `net-new because in-place is infeasible`.** Two grounds,
both read from that check's own declarations:

1. Its live arm is **operator-instance-resident**: its verdict input is the git-ignored event
   log, so in CI that arm verdicts SKIP and reports NOT-EVALUATED rather than passing. A rubric
   deriving its `MUST` limb from that verdict would be unresolvable on a fresh clone.
2. The capability this rubric adds is the **complement that check's own docstring declares out
   of bounds**: it asserts existence only, and states in terms that it cannot detect a wrong
   payload, a mis-keyed subject, or an event emitted for a decision never actually rendered.
   Those are precisely the well-formedness limb of §2.4 and the evidence-versus-occasion
   comparison of §2.3.

**What the division means in practice.** That check answers *did a row exist?* and stops. This
rubric answers *was the row owed, did it arrive, and does it record what was decided?* A reader
finding the two verdicts apparently disagreeing should reach for that division first: existence
without well-formedness is exactly the state one surface passes and the other grades `partial`.
