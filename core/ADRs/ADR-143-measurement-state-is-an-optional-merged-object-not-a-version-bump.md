<!-- reference-durability: allow-link -->
---
title: "ADR-143 — A schema gains a measurement state through one optional merged object, and the library enforces the absence rule"
status: Proposed — flips to Accepted at this release's operator gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-25
release: checks-see-whole-subject
deciders: "Stage 5 Solutioning spoke (design) + two independent adversarial design-review passes per card (one counter-design adopted at each) + operator (D-4 build-coupling; D-7 CIAC-1 scope; D-8 ADR authorization; D-10 counter-retention) + Stage 6 Engineering spoke (build)"
tags: [schema-v1, measurement-state, probe-validity, degraded-state, emitter-class, blast-radius, seam-design, extend-before-create, vocabulary-canonicalization]
source_observations:
  - "Two runs of the same tracer over the same corpus and target — one that never attempted a second-order traversal and one that attempted it and measured an empty result — emitted 751-byte envelopes differing at exactly ONE byte: the echo of the requested depth. Every other byte, including `second_order_count: 0`, was identical. The only discriminator a consumer had was an INPUT, not a measurement."
  - "The counter was ambiguous at two independent emit sites in the same file, not one. A fix scoped to the depth gate would have left the identical defect reachable from the structural-mode path."
  - "A version bump was rejected on blast radius and reversibility: it reds a `schema_version == \"1\"` assertion in three suites plus the library's own pre-emit skew guard, and drags a sibling tracer and its ADR into a release that plans for neither. The behavioural-tier option reaches the same outcome."
  - "The first seam design added two optional positional scalars, and the build-coupled sibling would then have added three more — twenty positionals across two cards. Its own stated test of a correct seam (a follow-on costs one caller line and zero library work) was failed by the sibling inside the same release."
  - "The object seam that replaced it relocated the absence guarantee from a library-enforced deletion to caller convention, and the key-name registry that replaced it checks NAMES while the rule lives in the VALUE space. Measured: a registered key with a wrong-typed value re-emitted the exact defect the card exists to remove — status `not-run` beside a present `0`."
  - "The same class manifested twice on real code: an empty-string reason interpolates as a PRESENT member, so `has(...)` returns true and the absence discriminator silently breaks."
  - "The naive derivation of a counter's name from its status key — the status key minus the `_status` suffix — is broken in BOTH directions on the only two real cases: it is a no-op for one card (the derived key is top-level, not a `stats` member, so the deletion never fires) and it DELETES the sibling card's population label. Corrected to `rtrimstr(\"_status\") + \"_count\"`."
  - "Capturing the pipeline's exit status could not distinguish an unreadable file from a clean no-match: `xargs` collapses `grep`'s rc=2 to rc=1, and both arms returned rc=1 with zero bytes out. A remedy built on that status would have been a broken probe inside the release about broken probes."
  - "A readability census over the enumerated list cannot see what the enumerator never produced. Measured on one fixture: a file behind a mode-000 directory yields an enumeration of 3 of 4 with a census of 0 — byte-identical to a complete scan."
---

# ADR-143 — A schema gains a measurement state through one optional merged object, and the library enforces the absence rule

## Status

**Proposed.** Authored at Stage 6 Engineering for the `checks-see-whole-subject` release, under the ADR authorization recorded at that release's wave-1 operator gate. It flips to Accepted when the operator ratifies it at the release gate; the flip is recorded in this file's `status:` field.

## Context

[ADR-134](ADR-134-degraded-state-emit-contract.md) established that a check must report its own measurement status rather than let a degraded measurement collapse into the clean one. It answered *what a check owes its reader*. It did not answer *how an already-shipped output contract acquires that obligation* — and that question has a wrong answer that looks obviously right.

The concrete instance: a tracer's `stats` block carried a counter whose zero meant two incompatible things. On a run that deliberately did not attempt the traversal, the zero meant *not computed*. On a run that attempted it and found nothing, the zero meant *measured empty*. Measured on a frozen corpus, the two envelopes differed at exactly one byte — the echo of the requested depth, which is an input the caller already knew and not a measurement the tool performed. A downstream review checklist read that counter as a blast-radius finding, so an unmeasured input could pass a gate that an ALL-conjunction rule then aggregated into an overall PASS.

The obvious remedy is to add the field and bump the schema version, on the reasoning that a new field is a contract change. Three things make that wrong here, and they generalise.

**A version bump is the expensive-to-reverse direction, for a change whose whole point is additive.** The bump reds a `schema_version` assertion in three test suites and in the emitting library's own pre-emit skew guard, and it pulls a sibling tracer — which shares the library but not the defect — plus that tracer's own ADR into a release scoped for neither. Every field a v1 consumer could previously read is still emitted on every path it could previously read it. The single exception *is the defect being fixed*.

**The seam shape matters more than the field.** A first design added two optional positional parameters to the shared emitter. Its own stated test of a correct seam was that a follow-on card should cost one caller line and zero library work — and the build-coupled sibling card, in the same release, would have added three more positionals, taking the function to twenty. A seam that fails its own test against the very next consumer is not a seam; it is a precedent for a third revision.

**Moving a guarantee is not the same as keeping it.** Replacing the positionals with one free-form object bought the seam back, and quietly demoted the absence rule from a library-enforced deletion to a caller convention. The mitigation offered — a registry of permitted key names — bounds the *key* space, while the rule it replaced lived in the *value* space. Measured, a registered key carrying a wrong-typed value re-emitted the original defect: a non-measuring status beside a present `0`. The same class had already appeared independently, on a different member, where an empty-string reason interpolated as a present-but-empty member and silently broke `has(...)` as an absence test. That is N=2 on caller-side value defects against a key-only guard, on real code, before the change had shipped.

## Decision

**An output contract acquires a measurement state through ONE optional trailing object merged into the stats block — not through a version bump and not through per-field positional parameters. The non-measuring absence rule is enforced by the LIBRARY, generically, keyed on the ratified `_status` name suffix and the frozen non-measuring set; it is never delegated to caller convention. The status vocabulary is adopted verbatim from the closed register; a population that the register cannot describe gets its own labelled field rather than a coined register member.**

Four limbs, each load-bearing.

**1. Optional field over version bump.** The schema version does not move. The emitter gains exactly one optional trailing parameter — a JSON object, defaulting to empty — for this entire class of change, and does not gain another. A caller that passes only the original arguments receives a byte-identical envelope, which is what leaves the sibling tracer and its ADR at zero lines changed.

**2. One merged object, not N positional scalars.** Each card assembles its own object; they merge at a single call site and the library merges once. There is no positional ordering to get wrong and no dependency on which card lands first. The cost — a free-form object can carry a typo'd key that a positional cannot — is paid by a closed registry of permitted key names, enforced library-side with an internal-error exit.

**3. The absence rule is a line in the library, not a rule in a table.** After the merge, any member whose key ends `_status` and whose value is in the frozen non-measuring set forces its governed counter out of the emit. The library needs no per-caller knowledge: the suffix is the ratified discriminator, the non-measuring set is corpus-frozen, and the counter's name derives from the status key. A member whose value is JSON null is likewise dropped, and a `_reason` member whose value is the empty string is dropped rather than emitted — an empty reason means the caller failed to compute one, and dropping it makes that failure *detectable* instead of silently truthy.

The derivation is `rtrimstr("_status") + "_count"`, and the naive `rtrimstr("_status")` is forbidden. Measured against the only two real cases it is broken in opposite directions: a no-op on one (the derived name is a top-level key, not a stats member, so the deletion never fires and the hazard survives) and actively destructive on the other (it deletes a population label the sibling emits on every path). This is the single most breakable line in the mechanism.

**4. A population label is not a measurement state.** The register can say *whether* a measurement happened. It has no member for *"measured, over a different population."* A tool that can enumerate two different populations therefore emits a separate, explicitly-labelled scope field alongside the register-valued status, and the counter it governs is never deleted — it is genuinely measured on every path. Forcing that fact into the register would be mis-vocabulary; the graded-literal check is scoped to `_status`-suffixed fields precisely so a population label is not graded as a sixth register token.

## Consequences

**A measuring status must retain its counter, and this is asserted with a control.** The absence rule deletes on a non-measuring status only. A clause that deleted every zero would pass every deletion assertion and destroy the entire purpose of the change, because a *measured empty* must still be reported as `0`. Every arm asserting deletion ships paired with a control arm asserting that a measured zero survives.

**Consumers gain a mandatory branch.** A counter with a sibling status field must never be read before the status. Absence — not any value — is the not-computed discriminator, which is what makes the rule sound: on a non-measuring status there is no value to misread.

**A clean status warrants less than it appears to.** The warrant is scoped to what the instrument actually measures — every *enumerated* member was read — and explicitly not to enumeration completeness. A readability census over an enumerated list structurally cannot see a file the enumerator never produced; measured, an incomplete enumeration and a complete one emit an identical record on that instrument. Enumeration completeness is a *different* field's job. Stating the narrower warrant in the durable contract is the point: publishing a completeness claim the mechanism cannot support would reproduce, in the fix, the class the fix exists to remove.

**A remedy that captures an exit status is not automatically a measurement.** The rejected alternative captured the scan pipeline's status and treated a non-clean value as degraded. Measured, `xargs` collapses the unreadable-file status into the no-match status, so the predicate could not discriminate at all. A measurement state must rest on an instrument that is *shown* to discriminate against a purpose-built fixture, not on a status code that some layer may already have flattened.

**The pre-register `partial` marker is not retired.** It predates the register and drives an exit code and four assertions. Retiring it buys nothing here, so the new status is set on that same path instead, and the two markers agree rather than compete. Consistency is bought by alignment, not by a rename.

**Known residual, named rather than discovered.** On the fallback enumeration path a directory that cannot be traversed removes files before any census sees them. Under the tool's error options that aborts the run rather than under-reporting — loud, but undiagnosable, because the diagnostic naming the directory is discarded. Capturing it is a routed follow-on, out of this release.

## Alternatives considered

| Alternative | Why not |
|---|---|
| **Bump the schema version and make every counter a `{value, status}` object** | Uniform by construction, and the most expensive direction to reverse. Reds a `schema_version` assertion in three suites and the library's own skew guard, and pulls a sibling tracer and its ADR into scope. A behavioural-tier change reaches the same outcome. |
| **Emit the status only on the degraded path** (mirroring the existing `partial` marker) | Cheapest: three files, no fixture regeneration. But a measured-empty run then carries no status at all, so a consumer must infer "measured" from *absence of a status* — precisely the derived-inference read this decision removes. Surfaced to the operator as the zero-churn option and declined. |
| **Reuse the existing partial/exit-code marker for the not-computed state** | Collapses two distinct register members into one: a sampled enumeration and a never-attempted one are different claims. It would also make every low-depth invocation exit non-zero, breaking existing callers, and a measurement outage must never gate. |
| **N optional positional scalars, one per field** | Self-documenting in the signature, and it fails its own seam test against the very next card in the same release: twenty positionals across two cards, with an ordering coupling between them. |
| **One object, with the absence rule left to callers plus a key-name registry** | Keeps the seam and loses the guarantee. Measured: a registered key with a wrong-typed value re-emits the original defect, and the empty-string variant of the same class had already appeared independently on another member. |

## References

- [ADR-134 — Degraded-state emit contract](ADR-134-degraded-state-emit-contract.md) — what a check owes its reader; this ADR is how a shipped contract acquires that obligation.
- [ADR-068 — Domain fan-out: sibling vs extend](ADR-068-domain-fan-out-sibling-vs-extend.md) — establishes the shared emitter as the single home of the output contract, which is the invariant limb 1 preserves rather than forks.
- [`core/disciplines/review-discipline-principles.md`](../disciplines/review-discipline-principles.md) § 8.1 — the closed status register, the absence-not-zero rule, and the never-gate rule this decision instantiates.
- [`release/references/protocols/blast-radius-protocol.md`](../../release/references/protocols/blast-radius-protocol.md) § 4 *Reading a count* — the consumer-facing statement of the mandatory branch and the scoped warrant.
