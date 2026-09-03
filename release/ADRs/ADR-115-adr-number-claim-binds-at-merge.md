<!-- reference-durability: allow-link -->
---
title: ADR-115 — An ADR number is allocated at authorship and bound at merge; only the mainline binds, and the reconciliation is tooled
status: Accepted — ratified by the operator at the Stage 13 close gate for the `adr-corpus-conformance` release, 2026-08-05, shipped as v4.11. The flip is verified against this file's `status:` field, never inferred from milestone closure.
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Workspace owner (ratified at this release's Stage 13 close gate); direction chosen at the Stage-4 gate, mechanism designed at Stage 5 Solutioning, authored at Stage 6"
tags: [architecture, adr, governance, concurrency, release-mechanics, tooling, portability, reversibility-moderate]
source_observations:
  - "Three collisions observed in the live corpus. v3.80: two releases each authored ADR-087; the later claimant renumbered by hand to ADR-088. v3.98: ADR-098 was authored independently by two releases while a third held 099 and a fourth took 100. A third release renumbered its ADR block twice inside a single Stage 5 as sibling branches merged ahead of it."
  - "Every claimant ran the contiguity checker and every claimant got PASS. The checker globs one working tree, so a PASS is not merely incomplete — it is a confident answer computed over the wrong population."
  - "The hand-performed recovery is reliably incomplete at exactly the step that makes it auditable. The v3.80 renumber landed the rename and the index fix; the record it produced carries no numbering-provenance note to this day, even though two governance surfaces already named that note as a required step."
  - "Measured renumber-commit footprint on the mainline: 30 commits, median 6 files / 15.5 insertions / 11 deletions; the named instance is 2 files and 4 lines. Across all 37 renumber events the moved number sat a median distance of 1 from the sequence frontier, maximum 7, with 32 of 37 within 3. No renumber has ever touched a well-cited record."
  - "The version-slot number space faced the same generator and solved it with an atomic ref compare-and-swap at the tag push. That primitive has no ADR analogue: an ADR number is a filename plus in-branch citations plus index rows, and no host offers a compare-and-swap over that object."
  - "The corpus already ratifies the binding rule in prose. The core ADR README's Renumber log states that an unmerged claim does not bind the sequence, and records a release ADR renumbering DOWNWARD from 100 to 099 for precisely that reason."
  - "A token form was independently found infeasible: an ADR-{{TOKEN}}-*.md filename is MALFORMED under the contiguity checker, so deferring the literal number weakens the very invariant the fix must preserve."
---

# ADR-115 — An ADR number is allocated at authorship and bound at merge; only the mainline binds, and the reconciliation is tooled

## Status

**Accepted** — ratified by the operator at the Stage 13 close gate for the `adr-corpus-conformance` release, 2026-08-05, shipped as **v4.11**. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The ratification was rendered at Stage 13, not at Stage 9 as this record originally promised: no pipeline stage performs that flip, and the promise is a spec gap tracked outside this record rather than a property of this decision. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number was derived at Engineering Commit 0 against the mainline anchor, per the rule the record itself ratifies — the mainline held 109 and this release's earlier record took 110, so this one takes 111. At that instant four sibling branches held unmerged claims on 110 through 114. Under the rejected `max(claimed_set) + 1` reading this record would have taken 115 and landed a four-number hole on the mainline. The record dogfoods its own decision, and the alternative it rejects was not hypothetical at the moment of authoring.

**Numbering provenance — `111 → 115`.** Authored branch-local as **ADR-111**; renumbered to **ADR-115** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 111. In-release citations that read "ADR-111" denote this record.

The move was one of a pair. The mainline claimed 110 and 111 together, this branch already held 112 and 113, and the two free slots were therefore 114 and 115 — so the assignment was **under-determined**: `{110 → 115, 111 → 114}` is equally legal under clauses (1) and (2), and the shipped contiguity rule returns the same verdict on both. It was *chosen*, not computed. § Decision (3) is the amendment that closes that discretion, and the record dogfoods its own tie-break in the same way it dogfoods its own binding rule.

## Context

ADR numbers are a single global, gap-free, append-only sequence across two directories, enforced on every pull request. The enforcement is worth keeping: contiguity is what makes a *missing* ADR detectable, and the corpus carries a running log whose entire content is which hole was real.

But the allocation rule and the enforcement rule are in structural tension, and the tension produces collisions on a schedule.

**The generator.** The checker globs a working tree. A branch that derives "next free" from what it can see gets a confident answer, and so does every sibling branch deriving at the same moment from the same visible state. All of them are right about what they can see, and all of them claim the same number. This is not a discipline failure that better instructions could fix — it is the arithmetic of a shared counter read without arbitration. Three separate releases have hit it; one of them renumbered twice inside a single stage as siblings merged ahead of it.

**The foreclosed workaround.** The obvious defence — reserve a slot above the visible claims — is not merely unhelpful, it is *worse*. Contiguity fails a gap exactly as readily as a duplicate. A branch that steps above a sibling's unmerged claim and then merges first lands a hole on the mainline, and from that merge onward the gate fails **every** subsequent pull request until someone fills it. A duplicate inconveniences one branch; a gap blocks the repository.

**The recovery is manual and reliably incomplete.** A governed recovery path already exists — rename, sweep the references, fix the index, add a `## Status` numbering-provenance note. Two surfaces document it. The one observed execution of it skipped the note, and the record produced still has no provenance to this day. That is the sharper defect: the path is not merely manual, it is manual *and* lossy at exactly the step that makes the move auditable.

**What is not the problem.** The blast radius is small and structurally bounded. Measured over 30 renumber commits on the mainline the median footprint is 6 files; the instance that motivated this card was 2 files and 4 lines. The reason is not luck: at renumber time the record has **not merged**, so its inbound citations are confined to its own branch diff. Across all 37 observed events the moved number sat a median distance of 1 from the sequence frontier. A renumber has never touched a well-cited record, and under the rule this ADR adopts it cannot — the record that loses the race is by construction the one that has not merged, and an unmerged record has no mainline citations. The problem to solve is therefore *arbitration and completeness*, not scale.

## Decision

**(1) An ADR number is allocated at authorship and BOUND AT MERGE. Only the mainline binds.**

Next-free is `anchor(origin/main) + 1` — the highest ADR number on the mainline, plus one. It is never `max(claimed_set) + 1`. An unmerged branch claim is **advisory**: the branch holding it may be rebased, renumbered, or abandoned, and the gate it must satisfy guards the mainline's contiguity rather than any branch's.

Scanning sibling branches, open pull requests, or another worktree remains worth doing — it tells the author a merge-time renumber is likely and lets the operator sequence the merge deliberately. It changes the **report**, never the **number**.

Allocating at the mainline next-free slot is safe under **every** merge order. Allocating above it is safe under exactly one. That asymmetry is the whole argument.

**(2) The reconciliation is tooled, gate-identified, and lossless.**

`release/tools/renumber-adr.py` performs the move in six individually-verifiable steps: refuse-or-proceed, `git mv`, branch-scoped citation sweep, index-surface update plus renumber-log append, `## Status` provenance note, and a zero-dangling verify that reverts the entire staged set rather than leaving a half-swept tree. Stage 12 Phase A.5.7 invokes it as the ADR-identifier dimension of the existing pre-merge freeness pre-check, and gate `G-EX9` asserts at the Gate-12 exit that a renumber which occurred was tooled and complete.

The provenance note is written **by the tool, not by discipline**. This is the load-bearing half of the decision. The note was already documented as a required step on two surfaces and was still skipped the one time the path ran; a step that survives being written down twice and missed once is not repaired by writing it down a third time.

**The refusal test is a DELTA, and that is what makes a multi-record reconciliation executable at all.** The step-1 predicate is the checker's own `evaluate()` — the tool and the gate can never disagree about what is legal — but it is asked on **both sides of the move**: refuse if this move *introduces* a violation the corpus does not already carry, or if it fails to *advance* toward a legal end state. Asking instead whether the post-move union is clean is only equivalent at a single collision; with `k > 1` no single move can satisfy it while the other `k − 1` stand, so every ordering refuses and the tooled path deadlocks against a plan it computed itself. The safety property is unchanged and is now stated exactly — the tool never creates a violation the gate would fail — but one move is no longer required to finish work that takes `k`. Each move is committed before the next, because the branch-scoped sweep below is only complete against a clean tree.

**The sweep is branch-scoped, and that is a correctness property rather than an optimization.** A corpus-wide substitution would rewrite legitimate references to whichever *other* record holds the old number — and at renumber time there always is one, because that is what made it a collision. In-scope is the set of files the branch added or modified against the mainline; out-of-scope is every mainline-unchanged file, whose citations belong to the record that merged first. The set is not merely a safe subset, it is **complete**: an unmerged record cannot be cited from a mainline-unchanged file.

**(3) When a reconciliation moves MORE THAN ONE record, the assignment is ORDER-PRESERVING.**

Clauses (1) and (2) determine *that* a record renumbers and *how*. With a single collision they also determine *to what*; with more than one they do not, and the residue is a free choice. So: sort the colliding records ascending by the number each currently claims, sort the free slots ascending from the merge union's frontier, and pair them positionally. A record that held a lower number than a sibling before the move holds a lower number after it. Both inputs are already derived — `--detect` collects the colliding set and `next_free()` computes the frontier — so this is a zip rather than a search, and the sort is total because branch-local numbers are distinct by construction. Where only one record moves the clause is vacuous.

**(3a) Which records move is settled BEFORE the ones that do are ordered. A branch claim the mainline does not hold, already sitting inside the free range, is HELD FIXED.**

The tie-break above orders the claims *being moved*; on its own it never says which claims those are, and treating every branch claim as needing reassignment is wrong on two counts. So: the merged union must occupy `1 .. anchor + k` where `k` is the number of claims this branch adds, which makes `anchor + 1 .. anchor + k` the slot set the branch has to end up holding. A claim already inside that set, on a number the mainline does not claim, is **already where it belongs** and is excluded from reassignment; the remaining slots are paired against the genuinely-colliding claims by the ascending rule in (3). Where every claim collides the sub-clause is vacuous and (3) is unchanged.

**Why holding it fixed is a correctness property and not a nicety.** Reassigning a claim that did not need to move costs a second provenance note, a second citation sweep and a second `§ Renumber log` entry on a record whose number was never in dispute — noise in the very audit trail (2) exists to keep clean. The sharper cost is that the plan stops being executable: handing out the free range from the bottom targets a slot that a *later row of the same plan* still occupies, so the first move is refused for overwriting and the reverse order is refused for the number the plan has not reached yet. An assignment no ordering can execute is not a tie-break outcome, it is a defect — and it is the shape this release's own reconciliation hit, where the tool printed four moves for a three-collision problem and the fourth targeted a record the plan itself was moving.

**Why a tie-break is needed at all: the gate cannot make this choice.** Every permutation of the same slot set is contiguous and duplicate-free, so the checker returns PASS on all of them with equal confidence. An assignment the gate cannot falsify is one that must be *computed* rather than *selected* — otherwise the platform re-acquires, at the reconciliation step, the exact defect this record was written about: a confident answer nothing downstream can distinguish from the wrong one. Sub-clause (3a) is the same argument one step earlier: the *membership* of the moving set is equally invisible to the gate, and a plan that is legal in aggregate can still be unexecutable in sequence.

**Why order-preservation rather than least displacement.** Least-total-displacement is the intuitive metric, and it is degenerate here for a structural reason rather than an accident of one case. The union's distinct numbers are contiguous from the base, so `k` colliding records take the `k` slots immediately above the union frontier, while every colliding number sits at or below that frontier by construction. Every target therefore lies strictly above every source, and the total `Σ targets − Σ sources` is invariant under permutation: a least-total rule selects nothing at all. Under the max norm the ascending pairing *is* the strict optimum, so the simpler rule that already yields it is adopted rather than a solver that would return the same answer.

The load-bearing reason is semantic, not metric. The sequence is append-only, so a lower number reads as *decided earlier*. An inverting assignment silently falsifies that reading, and — because the gate is indifferent — nothing in the corpus would ever record that it had. Order preservation is not a new principle introduced here; it is the principle clause (1) already applies at allocation, carried through the reconciliation so that the number a record ends with means what the number it was allocated meant.

**What this decision does not change.** Contiguity is retained, not relaxed. No token placeholder is introduced into ADR filenames. The checker's default verdict semantics, its command-line surface, and its continuous-integration invocation are byte-unchanged; the only addition is a pure `next_free()` function it did not previously expose, which the tool imports rather than re-deriving. There is never a second parser and never a second definition of the ADR home set.

## Alternatives Considered

Four directions were weighed at the design gate; the operator selected the third. Within it, five mechanisms were generated and narrowed before the survivor was specified. The tie-break in § Decision (3) was settled later — at this release's own reconciliation, which is what exposed the need for one — and its options are weighed in the last table below.

**On the direction:**

| Option | Verdict | Why |
|---|---|---|
| **(A) Defer-to-claim, mirroring the version adapter** | **Rejected** | The atomic primitive does not transfer, and the token form that would make deferral concrete was independently found to produce a MALFORMED filename under the contiguity checker — weakening the invariant the fix exists to preserve. Any non-token variant still terminates in a rename at merge, which is (C) plus extra machinery. Full falsifying evidence in § Portability conflict below. |
| **(B) Relax contiguity to monotonicity on branches** | **Rejected** | It destroys a genuine detection property and names nothing to replace it. Under monotonic-only, a hole is indistinguishable from a not-yet-merged claim — and the corpus's own renumber log exists precisely because "which hole was real" is a question this platform actually asks. |
| **(C) Formalize merge-time renumbering as a tooled, gate-identified step** | **SELECTED** | It is the only direction that repairs the observed defect. It preserves contiguity, it needs no arbitration primitive that does not exist, and it mechanizes the one step that discipline demonstrably fails to carry. |
| **(D) Do nothing; treat renumbering as recovery lore** | **Rejected** | The status quo. It has produced three collisions and one permanently unauditable record. |

**On the mechanism, within (C):**

| Option | Verdict | Why |
|---|---|---|
| **Manual with a written checklist** | **Rejected** | It cannot fix its own failure mode. The single observed defect *is* a checklist omission, on a checklist that was already written down twice. |
| **A shell sibling tool** | **Rejected** | It cannot import the number-space contract, so it would re-encode the home set and the filename pattern — the second-parser divergence class the platform's version tooling explicitly exists to prevent. It would also add script-execution allowlist entries that the Python form does not require. |
| **A write mode inside the contiguity checker** | **Partially adopted** | Adopted on the *read* half: the checker is the declared authority for the number space, so the tool imports its constants, its collector, and its verdict function. Rejected on the *write* half: the checker is a merge gate whose self-test is hermetic, and embedding a repository-mutating sweep in it would both give a gate a write path and destroy the hermeticity its self-test depends on. |
| **Folding ADR numbers into the version-claim adapter** | **Rejected** | It would break that adapter's own conformance contract. See § Portability conflict. |
| **A pre-merge bot that auto-renumbers a colliding branch** | **Rejected** | It reserves against the same moving population that produced the defect — the number can still be claimed between the bot's write and the merge — and it mutates a contributor's branch. |
| **A Python sibling importing the checker's contract** | **SELECTED** | Fixes the observed defect, introduces no second parser, adds no allowlist surface, leaves the gate's trust posture unchanged, and keeps the checker's hermetic self-test intact. |

**On the tie-break, within (3)** — weighed at this release's own reconciliation, where the candidate assignments were observed to be indistinguishable to the gate:

| Option | Verdict | Why |
|---|---|---|
| **Ascending pairing (order-preserving)** | **SELECTED** | Total, computed from inputs the tool already derives, and the one rule that preserves the append-only sequence's *decided-earlier* reading. It is also the strict max-norm optimum, so the metric-shaped answer and the semantic answer agree rather than having to be traded off. |
| **Least total displacement** | **Rejected — degenerate** | Every free slot lies strictly above every colliding number, so the total is permutation-invariant and the rule selects nothing. Measured on the observed reconciliation, both candidate assignments score identically. |
| **Least maximum displacement** | **Rejected as a restatement** | It does discriminate, and it returns the ascending pairing every time. Adopting it buys no additional determinism and expresses a one-line rule as an optimization over an assignment problem. |
| **Leave it to the operator at reconciliation time** | **Rejected** | The status quo this clause closes. Because the gate passes either way the choice is unreviewable, and at the observed instance it was asserted as determined when it was not. |

## Portability conflict

This decision **declines to mirror** the repository-host adapter precedent that the platform's build philosophy names as its host-agnostic-capability exemplar. The divergence is recorded rather than elided, with the evidence that falsifies the mirror.

**Mitigation 1 — the falsifying evidence, so a future adapter-shaped fix does not re-derive it.**

**(i) The atomic primitive does not transfer.** `atomic_claim()` is a compare-and-swap on a **single ref**; the host arbitrates it, and the adapter standard forbids simulating it with a read-then-write. An ADR number is not a ref — it is a **filename plus N in-branch citations plus three index surfaces**. No host offers a compare-and-swap over that object. Implementing `atomic_claim` for it would require exactly the read-then-write the adapter standard prohibits, so the mirror is not merely inconvenient: it would be **non-conformant with the interface it is mirroring**, on that interface's load-bearing property.

**(ii) The token form was already found infeasible.** A placeholder in the filename makes the record MALFORMED under the contiguity checker. A defer-the-literal-number scheme therefore weakens the invariant this decision preserves, and every non-token variant of (A) still ends in a rename at merge.

**(iii) The asymmetry is structural, not incidental — and `lineage()` inverts.** For versions, a pushed tag **is** authoritative, so `claimed_set()` must include in-flight claims *because they bind*, and an orphan is the exception to be filtered out. For ADR numbers the inverse holds: an unmerged claim **does not bind**, because the gate guards the mainline's contiguity rather than any branch's. The operation that carries the whole difference is `lineage()`, and its authority runs the opposite way. A mirror would have to invert the meaning of the one operation it shares, which is not a mirror.

**Mitigation 2 — the interface stays adapter-shaped even though the primitive differs.** The tool is expressed in the adapter's own vocabulary, so three of the four operations are already conformant and the migration surface is exactly one:

| Adapter operation | ADR-number binding |
|---|---|
| `anchor()` | The highest ADR number in the **mainline** sequence; branch-only claims excluded. **The binding oracle.** |
| `claimed_set()` | Mainline numbers ∪ every unmerged remote branch's claims. **Detection only** — it feeds the report, never the allocation. |
| `lineage(n)` | `MAINLINE` if the record exists on the mainline ref, else `BRANCH-CLAIM` — the analogue of the version adapter's `ORPHAN`, with **inverted authority** per (iii). |
| `atomic_claim(n, ref)` | **NOT IMPLEMENTABLE — declared non-conformant.** Replaced by `reconcile_at_merge(n) → BINDS \| RENUMBER(n')`: post-hoc reconciliation rather than compare-and-swap. **The merge is the arbiter.** |

A future host that *can* offer a compare-and-swap over a filename-plus-citations object supersedes this record and implements `atomic_claim` in place of `reconcile_at_merge`. The other three operations need no change.

## Consequences

**Easier.** The gap-landing failure mode becomes structurally unreachable: the binding oracle cannot return `anchor + 2`, so no author can step past a sibling claim into a hole. The lossy step is mechanized, so a renumber is auditable by construction rather than by remembering. Mainline contiguity is preserved without forcing in-flight branches to serialize. And the allocation rule now states its concurrency contract explicitly — what a branch may assume about its number between authoring and merge — where before it stated only an algorithm. A reconciliation moving more than one record yields one computable assignment instead of a set the gate cannot rank.

**Harder, stated plainly.** **This decision does not eliminate the renumber. It makes it cheap, complete, and auditable.** A release that authors an ADR now carries a conditional pre-merge step it did not carry before. Read against the originating requirement — that two branches merge "without a duplicate number *or a manual renumber*" — this satisfies the **"manual" qualifier only**, and that reading is stated here so it is graded as what it is rather than as a requirement nothing could meet. Eliminating the renumber outright requires an arbitration primitive that does not exist for this object, which is the finding recorded above.

**A second-order effect worth naming.** A branch that has not merged the mainline recently will legitimately see its own tree as non-contiguous, because the numbers its siblings claimed while it was away are absent locally. That local reading is not a defect and must not be treated as one — the property under enforcement is a property of the **merge result**. The tool's own verify step evaluates the simulated merge union for exactly this reason.

**Not changed.** Contiguity is retained. The contiguity checker's verdict semantics, arguments, and continuous-integration invocation are byte-identical; it gains one pure function and two self-test fixtures. No ADR filename gains a placeholder token. No existing ADR record is edited.

## Reversibility

**MODERATE / Confidence HIGH.** A `git revert` on the release merge restores the prior state textually — the tool is a new file, the pipeline sub-step and the gate criterion are additive, and the checker addition is a pure function nothing else depends on.

The two halves unwind at different costs, and the distinction is the honest one. The **decision** — that only the mainline binds — is CHEAP to supersede, because it is a rule and reverting it changes only what authors are told to do; the order-preserving tie-break in (3) and the hold-fixed sub-clause in (3a) sit on that same half and are CHEAP for the same reason. The **mechanism** becomes MODERATE once a second release has entered Stage 12 depending on `G-EX9`: reverting then strands a release mid-flight with a gate criterion its tooling no longer satisfies. Reverting the mechanism while keeping the rule is coherent and returns the platform to the manual recovery path; reverting the rule while keeping the mechanism is not, because the tool's refusal logic encodes the rule.

## Related ADRs

- [ADR-177](ADR-177-adr-citations-bind-at-the-claim-not-at-authorship.md) — **amends this record.** It leaves § Decision (1), (2) and (3) verbatim and adds the clause this record explicitly did not evaluate: *when* a number may enter branch-authored prose. Branch prose cites an in-release record by a slug-keyed token resolved at the Stage-12 claim, so a concurrent allocation costs a rename and an index update rather than a corpus-wide citation sweep. This record's § Portability conflict evidence is accepted there, not contested — it falsifies deferring the *filename*, and no filename is deferred. That record also widens the reconciliation tool's citation-sweep exemption from a line-wise shape test to a region population, and restates the tool's step enumeration, which § Decision (2) above states as six and which the shipped tool performs as seven.
- [ADR-036](ADR-036-version-claim-determinism.md) — deterministic version-claiming, the adapter precedent this record deliberately declines to mirror. Cited by slug (`version-claim-determinism`) per its own instruction. The divergence, its falsifying evidence, and the two mitigations are recorded in § Portability conflict above rather than left to be re-derived.
- [ADR-037](ADR-037-version-slot-cross-release-contended-axis.md) — the version slot as a cross-release contended axis. The ADR number is the same class of contended axis with the opposite arbitration rule, which is why it takes a different mechanism rather than an entry in the same one.
- [ADR-118](../../core/ADRs/ADR-118-adr-section-set-and-durability-hygiene-carve-out.md) — the ADR section set and the durability-hygiene carve-out, authored in this same release. This record is written to the section set that one defines, and the provenance note this record's tool writes lands inside `## Status`, which that record's carve-out makes a permitted hygiene edit rather than a forbidden body edit.
- [ADR-005](ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) — append-pattern-aware contention scoring. Its distinction between an append-pattern surface and a line-range overlap is what correctly classified this release's gate-registry edits as low-contention while isolating the single-line schema-version field as a genuine overwrite.
- [ADR-062](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) — canonical-spec-edit-wins. Applied here: the originating ticket argues for direction (A) and carries a citation-count estimate an order of magnitude above the measured figure. Both were superseded by live state at design time, and the ticket body was left as historical record rather than amended.
