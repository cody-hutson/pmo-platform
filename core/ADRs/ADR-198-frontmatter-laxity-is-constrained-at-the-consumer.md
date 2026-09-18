---
title: "ADR-198 — Frontmatter laxity is frozen at the shared reader and constrained at the consumer that declares a shape"
status: Accepted
date: 2026-09-11
release: deploy-tools-and-tests-batch
deciders: "Stage 5 Solutioning spoke (five-option design exploration on the parser limb; the comment-strip fork resolved on corpus measurement rather than on YAML semantics) + Phase A6.5 adversarial design review (two premise-rejection findings against the freeze block itself) + Collective Review (scope-lock; the discovery-key guard was admitted into scope) + Stage 6 Engineering spoke (build, mutation verification, corpus-equivalence floor)"
tags: [frontmatter, shared-parser, deploy-tools, join-key, fail-loud, silent-failure, behaviour-freeze, corpus-measurement, portfolio-composer]
source_observations:
  - "A shared frontmatter reader does not strip trailing `#` comments from values. A consumer joining on one of those values therefore resolves a WRONG key rather than a missing one, which the consumer's presence check is structurally unable to see — the value is present and non-empty."
  - "The obvious fix is not behaviour-preserving. Measured over the tracked corpus at the time of the decision, 639 of 6,664 parsed values carry a `#` and 543 carry it with no preceding whitespace — issue references, heading anchors, flow-list members. A naive split corrupts all 543."
  - "A YAML-faithful rule is not behaviour-preserving either. It still truncates real content in two release-plan `reversibility:` values and misses a `#` nested inside a quoted string inside a flow list, where a first-character quote guard does not reach."
  - "The reference implementation written to evaluate that rule got it wrong on the first four real shapes it met. A careful implementation breaking immediately is the strongest available argument that the transform is harder than it looks."
  - "The shipped rollup template authors a trailing `#` annotation on its own join-key line, and on eight others. The hazard is the template's default authoring shape, not a hypothetical."
  - "The same pollution on the DISCOVERY key fails worse than on the join key: the record does not fail to validate, it fails to MATCH, and the composer renders a surface missing that record at exit 0 with no diagnostic."
  - "The freeze block drafted to record this decision was itself wrong on two of three axes when probed against the live module — an internal-space key guard that is unreachable, and a quote-strip that re-strips after the slice. A durable record of current behaviour written from adjacent prose rather than from a probe reproduces the drift it exists to stop."
  - "The measured key denominator includes prose- and comment-derived pseudo-keys, because any flush-left line containing a colon is admitted as a key. That contaminant does not change the decision, but an unstated contaminant in a measured basis is re-derived from scratch by the next reader."
---

# ADR-198 — Frontmatter laxity is frozen at the shared reader and constrained at the consumer that declares a shape

## Status

Accepted. Ratified at the Collective Review scope-lock for the `deploy-tools-and-tests-batch` release and built in that release's Stage 6.

**Numbering provenance — `195 → 197`.** Held **ADR-195** branch-local; renumbered to **ADR-197** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 195. In-release citations that read "ADR-195" denote this record.

**Numbering provenance — `197 → 198`.** Held **ADR-197** branch-local; renumbered to **ADR-198** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 197. In-release citations that read "ADR-197" denote this record.

## Context

A platform accumulates one shared reader for a format precisely so that two checks cannot disagree about what the format means. That sharing is the reader's whole value, and it is also what makes every change to it expensive: a one-line edit changes what every consumer resolves, simultaneously and silently, with no gate watching the values themselves.

The forcing question arrived as a defect. A shared frontmatter reader treats a trailing `#` in a value as content rather than as a comment delimiter. One consumer uses such a value as a join key to another record. A line carrying an inline annotation therefore resolves to a key that is *present, non-empty, and wrong* — so the consumer's existing validation, which checks presence, passes it through to a join that silently fails to match. Wrong-value-rather-than-absent-value is the defect class a presence check cannot detect, which is why the fix is not simply a stricter presence check.

Two candidate sites exist for the constraint, and they are not equivalent:

- **The parser**, which every consumer shares. A fix here is one line and covers every present and future consumer at once.
- **The consumer**, which is the only site that knows the value has a *declared shape* at all. The parser cannot distinguish a polluted value from a legitimate one, because to the parser they are both just strings.

The parser fix is the intuitive one, and measurement rejected it. Under the tracked corpus at the time of the decision, a naive comment strip corrupts 543 values whose `#` carries no preceding whitespace — issue references, heading anchors, flow-list members — and a YAML-faithful rule, which only strips a whitespace-preceded `#`, still truncates genuine content in measured non-template files and still misses a `#` nested inside a quoted string inside a flow list. Both forms change roughly ninety resolved values across every consumer, in one commit, with nothing asserting the before-and-after. A silent corpus-wide behaviour change is the wrong shape of fix for a defect whose entire complaint is silence.

There is a second force, discovered while writing the record rather than while designing the change. The block drafted to freeze the parser's current behaviour was itself wrong on two of three axes when probed against the live module: it claimed an internal-space guard excludes prose lines from becoming keys, when that guard's enclosing condition can never be true for the lines that reach it; and it claimed a value loses exactly one surrounding quote pair, omitting that the value is stripped *again* afterward, so inner padding does not survive. Both clauses had been restated from the module's own older prose, which is itself the thing that had drifted. A freeze block that is wrong is worse than no freeze block: it invites the next maintainer to "repair" a dead guard into reachability, which changes resolved keys corpus-wide with nothing watching.

## Decision

**Where a shared parser is deliberately lax and one consumer's key carries a declared shape, the constraint belongs at that consumer, not in the parser.**

Concretely, three commitments:

1. **The parser's laxity is frozen, not fixed.** Its value semantics — a `#` is content; the value loses one matching quote pair and is then re-stripped; escapes are not interpreted; any flush-left line containing a colon becomes a top-level key, including a comment line — are recorded as a decision at the declaration site, with the measured corpus basis that makes it a decision rather than an omission.

2. **The freeze is anchored by tests, not by prose.** Each frozen clause carries a named assertion in the reader's own self-test, so a future well-meaning tightening fails a test instead of shipping. Those assertions are a tripwire, not a discriminator, and say so: they pass on both arms of such a change by design, because the behaviour they pin is already shipped.

3. **Every clause in the freeze is established by a probe against the live module, never restated from adjacent prose.** A record of current behaviour that is written by reading the documentation reproduces the documentation's drift. Where a guard is dead, the record says it is dead and says that repairing it is the behaviour change — because the alternative is a maintainer discovering an obviously-broken condition and correcting it in good faith.

The consumer that declares a shape validates that shape and fails loudly on a polluted value, naming the offending value, the charset it violates, and why an inline comment on that line is content rather than a comment. Where the same pollution can reach a *discovery* predicate — a key that decides whether a record is seen at all — the guard additionally distinguishes *nothing here* from *something here whose key was polluted*, because the silent-skip failure is strictly worse than the wrong-join failure: it produces a smaller result set at a clean exit status, and a missing row does not announce itself.

## Decision kernel (version-agnostic)

When a shared parser is deliberately lax and one consumer's key carries a **declared shape**, the constraint belongs at that consumer, not in the parser. Tightening the parser changes every consumer's resolved values simultaneously and silently — including values that were never wrong — trading a loud, locatable failure for a corpus-wide behaviour change no gate is watching. The consumer that declares the shape is the only site able to distinguish a polluted value from a legitimate one, and therefore the only site able to fail loudly about it. Where the parser's laxity is a decision rather than an omission, freeze it with named tests, and establish every frozen clause by probing the implementation rather than by restating its documentation.

## Alternatives Considered

Four alternatives were weighed; all four were rejected, and the first two on measurement rather than on preference.

**A1 — Strip comments in the shared parser, naively.** Split each value at the first `#`. Rejected on measurement: 543 corpus values carry a `#` with no preceding whitespace, and every one of them is truncated. This is not a trade-off, it is a corpus corruption.

**A2 — Strip comments in the shared parser, under the YAML rule.** Strip only a whitespace-preceded `#` outside a quoted scalar. Rejected on measurement, and the measurement is the point: the rule still truncates genuine content in measured non-template values, and it misses a `#` nested inside a quoted string inside a flow list, where a first-character quote guard does not reach. The reference implementation written to evaluate this option was wrong on the first four real shapes it encountered. Either form changes roughly ninety resolved values across every consumer with no assertion covering the change.

**A3 — An opt-in `strip_comments=` flag on the reader.** Rejected on principle, and the principle is the module's own: its stated premise is that two checks cannot disagree about what a value is. A flag forks the value semantics of exactly that module — one implementation, two behaviours — which inverts the reason the shared reader exists at all.

**A4 — Validate the key at the consumer, and additionally guard the discovery predicate.** **Selected.** Zero blast radius on the other consumers, because parse behaviour is byte-identical. Fails loud and fails locatably, naming the file, the value, and the remedy. The consumer is the only site that knows the key's shape, so it is the only site that can tell pollution from content.

## Consequences

**Positive.** The other consumers are behaviourally untouched, and that is asserted rather than claimed: a corpus-equivalence probe resolves every key in every tracked markdown file under the pre-change and post-change reader and compares the two maps for byte identity, with a seeded sensitivity arm proving the comparator reports a delta when one exists. A polluted key now halts with a diagnostic that names the remedy, instead of composing a wrong join at a clean exit. A polluted discovery key now halts instead of silently shrinking the result set. The parser's surprising behaviours are written down at the declaration site with their measured basis, so the next reader does not re-derive whether comments are legal in values — and the two most surprising of them are pinned by assertions.

**Negative, and worth stating plainly.** The constraint is now per-consumer: a second consumer that joins on a shaped key must add its own validation, and nothing forces it to. The parser stays lax, so a reader encountering it for the first time will still be surprised — the freeze block converts that surprise into a documented decision, which is a mitigation and not a cure. A record authored from a template whose annotations are inline will now fail loudly where it previously passed, which is the intended trade but is still a new failure mode for an author who was following the template; the failure message names the remedy, and the template's own convention is routed as a separate reconciliation. The freeze block itself is prose plus five assertions, and prose can drift again — the assertions are the half that cannot.

**On the measured basis.** The key denominator includes prose- and comment-derived pseudo-keys, because any flush-left line containing a colon is admitted as a key. That contaminant does not change the verdict — the value-side measurement that rejected A1 and A2 is unaffected by which lines produced the keys — but it is recorded here so the next reader does not have to rediscover it.

## Reversibility

**CHEAP.** The change is a docstring and a self-test case in the shared reader, and a validation branch plus a discovery guard in one consumer. Reverting restores the prior bytes exactly; no schema changed, no data migrated, no published artifact was mutated. The revert is self-announcing rather than silent: the new self-test cases fail on reverted code, so a partial revert turns the self-test discovery gate red instead of quietly restoring the wrong-join behaviour.

## Related ADRs

- **ADR-159** — the sibling posture on the *other* frontmatter transform. That record binds one body-strip implementation to a committed conformance fixture; the shared *block reader* this record governs is a different transform (it parses a block into a key→value mapping rather than emitting a body) and is bound to no such fixture. The two records agree on the kernel — one implementation, one behaviour — and that agreement is why the opt-in-flag alternative was rejected here.
- **ADR-179** — declares the cross-boundary key form for entity and tracker identifiers, and makes the join key the namespace root. Its grammar is the *declared shape* this record validates against; the shape's own home is that record, not this one.
- **ADR-181** — ADR citations bind at the claim rather than at authorship, which is why this record cites its siblings by number and its own release by slug.
