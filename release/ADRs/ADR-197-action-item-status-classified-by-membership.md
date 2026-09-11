---
title: "ADR-197 — The action-item gate classifies status by membership; the residue is a state, never a verdict"
status: Accepted
date: 2026-09-07
release: closeout-correctness-batch
deciders: "Stage 5 Solutioning spoke (design + canonicalization matrices) + its adversarial review (precedence and mechanism findings) + operator decision at Collective Review scope-lock (retain the blocking fifth state) + Stage 6 Engineering spoke (build, mutation probes, corpus re-derivation)"
tags: [procedure-7a, action-item-gate, hard-gate, fail-open, membership-classification, status-enum, alias-read-rule, enum-parity, stage-13-close]
source_observations:
  - "The shipped predicate was `if ($11==\"open\" || $11==\"in-flight\") u++`, with an implicit `else` meaning terminal. Every value the gate could not read fell into that else and was counted resolved, in a gate whose whole purpose is that no open row leaks across a release boundary."
  - "Measured at authoring across the operator-instance ledger corpus: 1545 AI rows over 63 ledgers; 49 rows whose arity is not the schema's 13; 51 rows carrying a status in neither the enum nor the alias table, spread over 8 ledgers."
  - "The witness that reproduces live is arity, not vocabulary. One ledger's four rows sit at arities 7 and 8 under a 13-column header, so field 11 does not exist and reads empty; the shipped predicate returned TOTAL=4 UNRES=0 and reported RESOLVED. The word `open` sits at field 6 and the gate never reads it."
  - "Three parties published three different mechanisms for those same four lines before one of them ran the gate's own awk with the gate's own field separator. Two of the three descriptions would have produced a fixture reproducing a condition that does not occur."
  - "A second arity mechanism is not an empty field at all: with FS=' [|] ' the row-terminating ' |' never matches the separator, so on an 11-column row it stays glued to the last field and $11 reads `open |`. At authoring, arity-11 was the largest single non-conformant arity class, so a test bounded at 'arity below 11' would have left the biggest live class unexercised."
  - "Uppercase bare `OPEN` at field 11 measured 0 rows at authoring, with 408 lowercase `open` as the sensitivity arm — the case-variant class named in the originating defect report had been normalised out of the corpus by the time the fix was built, while the defect itself was untouched at every predicate site."
  - "Precedence was decided against the corpus rather than argued: 3 of the 8 ledgers carrying an unadmitted status ALSO carry open rows, the largest of them 181 rows with 48 open against 2 unreadable."
  - "Reflexive safety measured before arming the second blocking state: 0 of the 8 affected ledgers belongs to an open milestone, and the introducing release's own ledger does not exist, so its verdict is NOT-RECORDED."
---

# ADR-197 — The action-item gate classifies status by membership; the residue is a state, never a verdict

## Status

**Accepted.** Authored at Engineering for the `closeout-correctness-batch` release, alongside the predicate correction, the standard's read-rule amendment, and the self-test arms that grade both.

**Numbering provenance.** Claimed as **195** against an anchor of **194** on `origin/main`, read from the repository's own ADR-numbering tool rather than computed as one past the highest number visible on this branch. Branch-local claims do not bind; the number binds at the Stage-12 claim, and in-release prose cites this record by slug rather than by number.

**Numbering provenance — `195 → 197`.** Held **ADR-195** branch-local; renumbered to **ADR-197** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 195. In-release citations that read "ADR-195" denote this record.

## Context

The Stage-13 close runs a HARD GATE over the release's action-item ledger. The gate exists because a milestone once closed with open commitments recorded against it, and its contract is that a `status:open` row cannot cross a release boundary silently.

The gate read `status` by comparing it against the two non-terminal values and treating everything else as terminal. That is a comparison, not a classification, and its `else` branch is a verdict the gate never measured. Four distinct inputs land in it and all four are reported as *resolved*: a value the enum does not admit at all, the same value in different case, a value drawn from some other register, and a value the gate never reached because the row's column count does not match the schema the column index assumes.

The last of these is what made the defect live rather than theoretical. A ledger whose rows are short has no field at the status index; the field reads empty, empty is neither of the two compared values, and the whole ledger reports resolved. The gate never sees the word it is looking for and never says so.

Two facts about the surrounding standard shaped what a fix could look like. First, the standard admits a small alias table so that ledgers seeded under an earlier vocabulary remain readable without being rewritten — closed-release audit records that a rewrite would falsify. Those aliases are live in quantity, so a gate that refused them would block every legacy re-run and contradict the standard it enforces. Second, an enum-parity check registers the authoring enum's table and asserts it against the ledger template, so widening what authors may write is a change with its own downstream consumers.

## Decision

**Classify `status` by membership in a recognised set, and give the residue its own state.**

The recognised set is the status enum **union** the standard's status aliases, compared **case-folded**. A value outside that set is **unclassifiable**: it counts toward neither the resolved population nor the unresolved one, and it BLOCKS the close. It is not attestable — the attestation mechanism licenses a ledger that is *absent*, never one that is *unreadable*.

Three sub-decisions carry as much weight as the main one.

**The reading vocabulary is wider than the authoring enum, and that gap is deliberate.** Authors write the enum; the gate reads the enum plus the aliases. Stating it this way is what lets the alias read-rule and the enum-parity check coexist: the registered authoring surface is untouched, and the widening lands only where a reader needs it. A future author who asks "why doesn't the gate just use the enum?" meets the answer here rather than re-litigating it.

**An unresolved row outranks an unclassifiable one.** The state token selects the operator's remedy, and the two remedies differ: disposition the row, versus normalise the value. A ledger that carries many open rows and a few unreadable ones is a disposition task. Ordering the residue first would render such a ledger as "normalise the value" and drop the open rows' owner-and-trigger enumeration — the enumeration that exists so the operator need not re-read the ledger the gate just read. Both sets are therefore carried in the same detail, so one pass covers both remedies.

**A row whose arity is not the schema's is unreadable, and it is not made readable by looking plausible.** Where a short row's status field is empty, and where an eleven-column row's last field carries the row-terminating pipe glued to it, both are refused. Stripping that pipe to recover a word that *looks* like a status would be the same positional assumption the gate's column-addressing rule already refuses: a field at index eleven of an eleven-column row is not the status column of a thirteen-column schema, whatever it happens to spell. The operator-facing detail prints the row's field count beside its raw value, so a mistyped word is distinguishable from a dropped column and the operator applies the right repair.

## Decision kernel (version-agnostic)

A predicate that decides membership by comparing against the members of one class **has not classified anything** — it has partitioned its input into "matched" and "everything else", and "everything else" is not a measurement. Where a gate emits a verdict, the residue of its comparison must be its own state with its own remedy, never folded into whichever verdict the comparison's `else` happens to reach. The failure is asymmetric and that asymmetry decides the direction: folding the residue into the passing verdict produces a gate that reports success it never established, which is worse than a gate that stops on input it cannot read.

Two corollaries follow, and both were live here. A count of what a predicate matched is evidence only alongside a count of what it could not classify. And a probe written to investigate such a predicate must run the program's own expression, with the program's own separators and flags, because a paraphrase reproduces the paraphrase's blind spots rather than the program's.

## Alternatives Considered

| Option | What the residue becomes | Verdict |
|---|---|---|
| **A — count unreadable rows into the unresolved subset** | part of the open count | **Rejected.** It reports a fraction of unresolved-over-total whose numerator includes rows whose state is unknown — asserting a count the gate cannot support, which is the same defect in the opposite direction. |
| **B — return non-zero immediately, with no state** | nothing | **Rejected.** It breaks the dispatcher's total classification and leaves the verification row rendering its "gate did not run" default on a run where the gate ran and blocked. A blocking verdict that reports as an unperformed one is worse than the silent pass. |
| **C — reuse an existing "cannot read" token** | an existing state's meaning | **Rejected.** Both candidate tokens already carry distinct meanings in the same tool — structural malformation of a different corpus, and *the gate did not run*. Reuse would conflate a status the predicate cannot read with a gate that never executed. |
| **D — a fifth state that SURFACES and is cleared by attestation** | an attestable condition | **Rejected by the operator at scope-lock.** It is cheaper: it leaves two standing non-blocking claims true and retires a package rebuild. But it makes a gate error dismissible by flag, and the originating defect is precisely a gate error that passed without anyone deciding it should. |
| **E — a fifth state that BLOCKS, with its own branch and no attestation path** | its own state and its own remedy | **Adopted.** |
| **F — widen the alias table to admit the remaining out-of-vocabulary values** | admitted | **Rejected, and deliberately not folded in.** Admitting a value changes what the vocabulary *means*, not how robustly it is read. One of the candidate values is semantically non-terminal, so aliasing it would require deciding whether that commitment is open or superseded — a governance question, and a separate decision from this one. |

## Consequences

The gate now blocks on a second condition, so a close over a drifted ledger stops where it previously passed. That was measured before it was armed: no affected ledger belongs to an open milestone, and the introducing release's own ledger does not exist, so no release in flight is blocked by the change. A ledger that drifts into the state later fails loudly, naming the offending row, its raw value, and its field count.

The verification row that renders the gate's verdict gains an arm for the new state and renders it with a count. Without the arm the state falls to the row's default and the gate-passage proof asserts the gate did not run — a false statement inside the artifact whose purpose is to record that it did. Emitting the unreadable-row count alongside the total keeps the new state consistent with the gate's founding argument, which is that a bare verdict without counts cannot distinguish "everything was resolved" from "nothing was ever recorded".

A cost worth naming: the recognised set is now spelled in three places — the canonical predicate in the hub reference, its implementation in the close-out tool, and the row enumerator that lists offending rows for the operator. That is the same cardinality the two-value comparison already carried, and a parity arm asserts the first two agree by running both over a shared fixture set. The third is bound to the second by an arm that grades the enumeration's content, not merely the verdict.

The gate's **verdict** cardinality is unchanged at three — surface, pass, block — because the new state renders as a block. Surfaces that count verdicts rather than states therefore remain correct and were deliberately left alone; only surfaces that count states were amended.

Row-arity conformance is explicitly **not** decided here. The corrected gate blocks a non-conformant row for the right reason with an imprecise diagnosis, which the field-count printout mitigates. A gate over row arity is a distinct evaluand with its own aggregation consequences, and folding it in would put two independent checks behind one state token.

## Reversibility

**CHEAP / Confidence HIGH.** Every element is a text change on tracked files with a self-test arm behind it, and reverting restores the prior verdict domain exactly. What reverting would also restore is the silent pass, which is the reason the decision is recorded rather than left implicit: a later reader who finds the residue branch inconvenient should meet the argument before removing it.

## Related ADRs

- `ADR-100` — the pipe-delimited column grammar this predicate addresses `status` under, and the source of the bare-pipe hazard the field separator exists to avoid. The membership defect is the second silent-pass path on the same gate, beside that one.
- `ADR-181` — ADR citations bind at the claim, not at authorship; this record is cited by slug in branch-authored prose and its number binds at the Stage-12 claim.
