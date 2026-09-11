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

| `DS-id` | Seam name | Decision class | Emitting surface | Evidence key (`select` · `denom`) | Baseline source |
|---|---|---|---|---|---|

*Rows are authored by the coverage-scorecard slice that fills this table. This file lands the
contract; the rows land against it.*

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
