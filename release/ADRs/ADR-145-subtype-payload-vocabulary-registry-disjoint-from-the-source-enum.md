<!-- reference-durability: allow-link -->
---
title: ADR-145 — Subtype payload vocabularies are declared in a registry disjoint from the `--source` enum
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-24
release: pipeline-spec-self-consistency
deciders: "Workspace owner. Design decision rendered at Stage 5 Solutioning for the QC4 payload-vocabulary card and accepted by the hub at Procedure 4; the card's own proposed remedy was prohibited by the surface it targeted, which is why this record exists rather than a one-line table edit."
supersedes: none
tags: [architecture, release-pipeline, event-log, schema, registry, payload-validation, charset-contract, extend-before-create, reversibility-cheap]
source_observations:
  - "The card was born invalid. Its Proposed Change — add rows to the § 11.8 `--source` table — is prohibited by that section's own Scope paragraph, and the prohibition was authored three days BEFORE the card was filed. This is not drift: a stale card was right once, this one never was."
  - "The prohibition carries its reason, and the reason is mechanical. Column 1 of the § 11.8 table is the `--source` enum that `synthesize-release-learnings.sh` validates its `--source` argument against, at two hardcoded sites with a rejection arm asserted in its own self-test. A third value there is rejected by the read tool."
  - "The literal remedy also ships a silent regression, proven by execution. Two of the three documented `qc4-06-result` labels are snake_case; the registry parser's label-token charset had no underscore. Registering the row as described registers `verdict` alone, then REJECTS the tool's own shipped conforming fixture — the card's acceptance criterion fails on the card's own evidence."
  - "The drop is silent by construction. A narrower charset in the registry parser does not error on an unmatchable token; it yields no token. The label vanishes from the declared set and the payload carrying it is then reported as unrecognized — a failure whose message points at the payload rather than at the parser."
  - "The charset defect is general, not QC4-specific. The schema already declares snake_case payload labels on two other subtypes today; either would be silently dropped if ever registered. The write-side extractor's charset already admits underscore, so the two halves of one gate disagreed."
  - "The chosen sub-heading depth is forced, not stylistic. The registry parser bounds its scan by the § 11.8 heading and terminates on a heading of depth three or less, so a sibling `### 11.9` section terminates the scan and registers nothing, while a `####` sub-heading inside § 11.8 does not. Proven by execution on a fixture, both arms."
  - "The card's stated deferred decision was not open. The read tool filters `--source release-synthesis` to the `learnings-triple` subtype, so a QC4 row is excluded at the query layer before tokenization. Whether a QC4 verdict participates in cross-release clustering has exactly one admissible answer, and it is enforced rather than chosen."
  - "The vocabulary was declared and unenforced, not undeclared. The Stage-13 emit table already named the payload tokens for both QC4 subtypes; nothing bound them, so both subtypes were emittable precisely BECAUSE they were unregistered."
---

# ADR-145 — Subtype payload vocabularies are declared in a registry disjoint from the `--source` enum

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `145` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py`. The oracle reported `ANCHOR 141 origin/main` and `NEXT-FREE 142`; `--detect` reported `CLAIMED-SET-BRANCH-ONLY 142,143,144 (detection only — never binds)` with all three claims `BINDS`. Those three are already bound on this same release branch by the records authored in earlier builds, so `145` is this branch's contiguous next, with the mainline reaching `ADR-141` and no hole beneath any claim. The number was deliberately **not** reserved at design time — the oracle is a *read*, not a reservation, which is why three Stage-5 spokes in this release independently specified the same number. Sibling unmerged release branches may claim overlapping numbers; those claims are **detection-only and do not bind**, and stepping past them to be safe would land a gap. The asymmetry is the whole rule: a duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole.

## Context

`pipeline-event-log-schema.md` § 11.8 is a single table doing two jobs at once, and until now nobody had to notice.

Its column 1 is the `--source` enum for `synthesize-release-learnings.sh` — a closed, hardcoded set of pattern-detect grains. Its columns 2 and 3 are the payload-label registry that `append-pipeline-event.sh` parses to decide which labels a row may carry: column 2 declares the `(event_type, event_subtype)` scope, column 3 declares the recognized set. The write tool keys off column 2 and never reads column 1; the read tool validates against column 1 and never reads the table at all.

The two jobs coincided because every declared vocabulary happened to belong to a pattern-detect grain. Then the Stage-13 emit table declared payload vocabularies for two `release-synthesis` subtypes — `qc4-05-result` and `qc4-06-result` — that are **not** grains. The synthesizer filters `--source release-synthesis` to the `learnings-triple` subtype, so a QC4 row never reaches its clustering machinery.

That produced the defect the card names, in the inverted form the card states it: those two subtypes are **emittable only because they are unregistered**. Their vocabularies were documented in the Stage-13 emit table and enforced nowhere, so the payload gate short-circuited to pass on every QC4 emission. A vocabulary that is declared in prose and unenforced in the gate is not a vocabulary; it is a comment.

The obvious remedy — declare them in § 11.8 like everything else — is **prohibited by § 11.8's own Scope paragraph**, and the prohibition is not decorative. A third column-1 value would be rejected by the read tool at two hardcoded sites, and a duplicated column-1 value would give one `--source` two rows while the read tool's contract for that source is single-valued. Both sub-forms make the document contradict the tool.

So the constraint set is: the vocabulary must be declared where the write tool parses it, must not appear as a `--source` value, and must not require the parser to change shape.

## Decision

**§ 11.8's table is a `--source` selection registry. A subtype's payload vocabulary is a different concept, and gets a different table.**

Subtype payload vocabularies for non-grain subtypes are declared in `#### 11.8.1`, a sub-table **inside** § 11.8 whose column 1 is a **registry key, not a `--source` value**. It is parsed by the same column-2 filter rule as the table above it, and read by no `--source` consumer. The `--source` enum stays exactly as it was.

Two properties make this work, and both are invisible unless you read the parser rather than the spec:

1. **The scan is section-bounded, not table-bounded.** `parse_schema_labels` opens on the § 11.8 heading and closes on the next heading of depth three or less. A `####` sub-heading does not close it, so rows beneath `#### 11.8.1` register with **zero change to the parser's section-boundary or key logic**. A sibling `### 11.9` section would have closed the scan and registered nothing — measured, not assumed.
2. **The key already comes from column 2.** The parser derives `event_type/event_subtype` from the Input-filter cell and ignores column 1 entirely. So a registry key in column 1 costs nothing: the parser never looks at it, and the read tool never sees the sub-table.

**The registry parser's label-token charset is widened to `[A-Za-z0-9_-]`, and the contract is recorded.** The write-side payload extractor already admitted underscore; the registry parser did not. That disagreement between two halves of one gate is why the card's literal remedy would have registered one label of three. The widening is a **general fix**: the schema carries snake_case payload labels on other subtypes today that the narrow charset would have dropped just as silently. Run against the unmodified schema the widened parser produces byte-identical output — 5 registry keys under both charsets — so it cannot regress an existing registration. The widening landed in two steps: underscore first (the defect this card found), then the remaining case difference, because `[a-z0-9_-]` is a strict *subset* of the extractor's charset and satisfied § Consequences' superset contract only by the coincidence that every declared token is lowercase. The charset is now equal to the extractor's, so the contract holds by construction rather than by corpus accident.

**The clustered-field value for both QC4 rows is `none`, and the cell records enforcement rather than making a choice.** The read tool's query filter excludes QC4 rows before tokenization. Making a QC4 verdict cluster would require a third `--source` value, which the paragraph above prohibits and the read tool rejects. There is one admissible answer.

### The principle

**When one table's column set is serving two consumers with different contracts, the fix is a second table under the first heading — not a third value in the first column.**

Column 1 was load-bearing for the read tool and dead weight for the write tool. Adding a row to satisfy the write tool would have written into the read tool's closed enum. Splitting the table gives each consumer a surface it fully owns, at the cost of one sub-heading and no code.

## Alternatives Considered

Four candidates were executed against a scratch copy of the schema through a verbatim reproduction of the tool's decision path, not reasoned about. Each rejection below is a measured behaviour.

| # | Candidate | Measured behaviour | Verdict |
|---|---|---|---|
| **A** | **Rows appended to the § 11.8 `--source` table** — the card's literal Proposed Change | Registers `verdict` alone for `qc4-06-result`; the two snake_case labels are silently dropped and the tool's own shipped conforming fixture is then **REJECTED**. Separately, column 1 must carry something: a new value is a third `--source` value the read tool rejects, and a duplicate value gives one source two rows against a single-valued read contract. Both sub-forms defective, independently of the charset. | **REJECTED** — prohibited by § 11.8's own text, on its own stated grounds, and fails the card's acceptance criterion |
| **C** | **A sibling `### 11.9` section** | Executed: the `### ` heading **terminates** the parser's scan, and the fixture's post-11.9 row did not register at all. Fixing that means editing the parser's start/terminate pattern — strictly more tool change than option B, for an identical outcome. | **REJECTED** — more parser surface, no benefit |
| **D** | **Do not register; delete the vocabulary claims from the Stage-13 emit table** | Resolves the spec/tool disagreement in the opposite direction. Measured cost: the `qc4-06-result` `verdict` enum is load-bearing for the goal-attainment close gate, so deleting it makes an already-declared gate verdict free-form; and it contradicts this release's own Outcome Statement, whose third clause is that stage specs agree with *the event vocabularies they declare*. | **REJECTED** — moves the release away from its own outcome |
| **K** | **Kebab-rename the vocabulary instead of widening the charset** | Executed and **insufficient on its own**: with the registry kebab-cased the conforming payload still rejects, because the *payload* is snake_case too. The rename must therefore also reach the tool's fixture, the Stage-13 emit table, and a Stage-9 spec row carrying the same token on a different event type — a file outside this release's change matrix. And it leaves the underlying parser defect in place for the other snake_case labels already in the schema. | **REJECTED** — larger blast radius, crosses the release edit set, and fixes one symptom of a general defect |

**Why the charset widening is a fix and not an accommodation.** The write side already accepted underscore; the registry side did not. Any snake_case label was therefore unregisterable — silently. Option K would have papered over that asymmetry for one subtype while leaving it live for the others.

## Consequences

**What this buys.** Two declared-but-unenforced vocabularies become enforced. A QC4 emission carrying an off-vocabulary label now fails at the write gate instead of appending a row that the reader will swallow into the preceding field and tokenize as signal. Because the log is append-only, a row that should not exist can only be redacted, never removed — which is why the gate is the right place and the reader is not.

**What it costs, stated plainly.** A currently-passing emission can start failing. `validate_payload_labels` short-circuits to pass on any pair that resolves to no declared set; both QC4 pairs resolved empty, so the gate could not reject them. After registration it can. The blast radius is zero today — no QC4 row exists across the log's history — and non-zero from the first QC4 emit, which is exactly why this lands before that emit rather than after.

**Consequence for the next writer, which is the point of recording this.** A subtype that owes a payload vocabulary without being a pattern-detect grain extends the registry by **one table row and one mirror line**. No `--source` change, no parser change, no read-tool change. The next release member in this same bundle adds a decision-supersession subtype and consumes exactly that seam.

**The charset contract is now a rule, not a coincidence.** The registry parser's token charset MUST remain a superset of the write-side extractor's. A narrower charset does not fail — it drops a declared label and then rejects the conforming payload, with an error message that points at the caller rather than at the parser. The contract is stated at both the schema and the parser, and the self-test carries a named assertion for the specific label that exposed it.

**Both arms are proven, and the guard is demonstrated capable of failing.** The registration is asserted by a conforming-payload accept **and** a paired off-vocabulary reject on each subtype, and the negative control confirms the widening stayed per-subtype: `verdict:` is now accepted on the QC4 subtypes and still rejected on `learnings-triple`. The schema-to-mirror lockstep was falsified in both directions — a one-sided edit to either surface exits non-zero and names the divergent tokens — and a deliberate re-narrowing of the charset was injected and caught.

**One residual, recorded rather than absorbed.** The registry parser bounds its scan by the § 11.8 heading and the next heading of depth three or less, and § 11.8 is the schema's **last** section. Any future end-of-file table with a backticked column 1 and an `--event-type` column 2 therefore registers whether or not its author intended it. That is pre-existing, but this decision makes it load-bearing, so § 11.8.1's lead-in states the `####`-inside-§ 11.8 requirement explicitly rather than leaving it implicit. A hard fix — an explicit end-of-registry sentinel — is a larger parser change than this decision justifies.

**A related gap is routed out rather than folded in.** Three further event vocabularies are documented and unenforced for the same reason, one event type over. Registering them is now cheap, because § 11.8.1 gives each a home and the widened charset makes their snake_case tokens registerable. Folding them in would widen this decision from two subtypes to five across three more event types, so it is routed as separate work.

## Reversibility

**CHEAP · confidence HIGH.** Three text-only edits across three tracked files plus this record: a sub-table appended inside § 11.8 and one re-scoped sentence in the schema; a widened character class, an extended static mirror, and a set of self-test assertions in the write tool; and one line of the Stage-13 emit table restated in backticked-token form. No schema migration, no data movement, no path move, no package rebuild, no new `--source` value, and no change to the read tool. Full rollback is a revert of the three source files, with the self-test as the oracle: the registry returns to two declared sets and the QC4 pairs return to resolving empty.

The one asymmetry worth naming: reverting after QC4 rows have been emitted would return those subtypes to unvalidated, which does not invalidate rows already written but does re-open the gap. No such row exists today, so the revert is currently clean in both directions.

## Related ADRs

| ADR | Relationship |
|---|---|
| [ADR-086](ADR-086-event-log-schema-decision-subtype-extension.md) | **Composes.** Governs subtype extension on this same schema surface. This record is its payload-vocabulary counterpart: ADR-086 admits a subtype into § 3, this one declares what a subtype's payload may carry. The two sites are disjoint, which is why a card adding a subtype and a card adding a vocabulary do not collide. |
| [ADR-100](ADR-100-event-log-payload-pipe-grammar.md) | **Composes.** Fixes the payload's pipe grammar; this record fixes its label vocabulary. Both harden the same field at the same write gate, on the same append-only-log rationale — only a write-side gate stops the bad row existing. |
| [ADR-094](ADR-094-extend-before-create.md) | **Composes.** The registry extends the existing section-bounded parse and the existing bidirectional lockstep rather than adding a second registry file or a second parser. A net-new registry would have created a second authority for one concept — the producer/producer disagreement the schema itself rejects. |
| [ADR-062](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) | **Composes.** Governs the direction of reconciliation when a card's stated remedy and the live canonical surface disagree. The surface was already correct and the card was authored against a state that had already changed, so the design moved to the surface and the card body stands as historical record. |
| [ADR-115](ADR-115-adr-number-claim-binds-at-merge.md) | **Composes.** The numbering rule this record's `## Status` block applies — allocate at authorship, bind at merge, take the contiguous next, never reserve past an unmerged sibling claim. |
| [ADR-117](ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md) | **Composes.** The derived-surface contract under which this record's index row is projected rather than hand-written. |
