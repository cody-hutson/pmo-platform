<!-- reference-durability: allow-link -->
---
title: "ADR-148 — The tool-coverage engine hosts a second invariant whose population is the directory, never the manifest"
status: Accepted
date: 2026-08-28
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (six-option design exploration; four eliminated on hard constraints before scoring) + Stage 6 Engineering spoke (build, corpus re-derivation, nine-arm mutation verification)"
tags: [selftest-coverage, documentation-coverage, population-source, discovery-vs-enumeration, inherited-filter, denominator-identity, arm-e, ADR-119]
source_observations:
  - "A coverage rule stated over a directory shipped with no mechanical enforcement, and reopened twice before an arm existed to hold it. At the moment enforcement was written the rule was already violated by two tools."
  - "One engine now hosts two hard invariants over the SAME directory with DIFFERENT populations: 33 tools by the self-test manifest, 36 by the directory listing. The gap is not a defect in either — it is what the two rules respectively mean."
  - "The engine offers four candidate population sources. Three are wrong for the new invariant, and the most tempting of them is wrong in a way that measurement cannot reveal: ctx.scope_members equals the directory population exactly today."
  - "That equality is a coincidence of the current manifest, not a property. The two tools it would silently drop are non-dispatchers that were never on the manifest floor, so the engine's own anti-narrowing arm structurally cannot notice their loss."
  - "The governing ADR for this engine states the covered set is DISCOVERED, never enumerated. A hand-declared literal glob therefore reads as a violation of the file's own stated principle, to a reader who has not measured the four sources."
  - "The one narrowing the anti-narrowing arm deliberately leaves possible — a scope directive deleted together with its manifest lines in the same diff — is exactly the move that would shrink the wrong population without any arm firing."
  - "A mutation routing the new arm's population through ctx.scope_members was written and run. It is detected by exactly one of nine arms; without that arm the trap ships green."
---

# ADR-148 — The tool-coverage engine hosts a second invariant whose population is the directory, never the manifest

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, alongside the arm it governs.

## Context

`core/deploy/tools/README.md` carries a coverage rule stated over a directory: every file matching `core/deploy/tools/*.py` or `core/deploy/tools/*.sh`, top level only, carries exactly one inventory row keyed by its exact backticked basename. The rule was written to be exhaustive and it publishes its own by-hand re-derivation. What it did not have was a gate. It reopened twice before enforcement existed, and at the moment enforcement was written it was open again — 36 tools in the directory, 34 rows in the table.

Enforcement is a new hard arm inside the existing self-test coverage engine rather than a second tool, and that placement is not the decision recorded here. It follows from the engine already owning a bidirectional committed-set-versus-live-set reconcile, a hermetic fixture harness, and a CI caller whose path filter already reaches the README; the alternatives were generated and lost on measured grounds recorded below.

**The decision is which set the new arm counts.** The engine offers four candidate population sources, and they are not interchangeable:

| Source | What it means | Count over this directory |
|---|---|---|
| Literal directory globs | every top-level `*.py`/`*.sh` on disk | **36** |
| `ctx.discovered` | advertisers of `--self-test`, minus written exclusions | **33** |
| `ctx.expected` | the committed manifest floor | **33** |
| `ctx.scope_members` | unfiltered glob of the manifest's `# scope:` directives | **36** |

The originating defect report warns against exactly one of these — the self-test manifest — and the warning is correct as far as it goes: an arm that inherited that filter would enforce over 33 tools while reporting green over an assumed 36, reproducing inside the enforcement mechanism the very defect class the coverage rule exists to close.

**The warning does not reach the source that will actually tempt the next maintainer.** `ctx.scope_members` equals the directory population *exactly* today. It is already computed, already on the context object, and measurement cannot distinguish it from the right answer. But it is derived from the manifest's `# scope:` directives, so deleting `# scope: core/deploy/tools/*.sh` silently shrinks it. The engine's anti-narrowing arm would catch the ten `.sh` advertisers this directory has on the manifest floor — and would **not** catch `cross-module-audit.sh` or `run-count-structure-fixtures.sh`, which dispatch nothing and were therefore never on the floor at all. The new arm would then report green over a population two tools smaller, and no arm anywhere would have fired.

There is a second reason this needs a record rather than a comment. ADR-119, which governs this engine, decides that *the covered set is discovered from a declared scope, never enumerated*. A reader who meets Arm E's two hand-declared literal globs and has not measured the four sources will reasonably read them as a violation of the file's own stated principle — and "fix" them by routing through `ctx.scope_members`, reproducing the exact trap this arm was written to avoid, in the code written to avoid it. That is the canonical shape of a decision that will look like a defect later.

## Decision

**Arm E's population is declared as two literal globs on the tool itself and is filtered by nothing.** Not by `advertises()`, not by the manifest's `# scope:` directives, not by the exclusions file. The globs sit beside a comment carrying all four measured counts and the reason each of the other three is refused.

This does not overturn ADR-119's discovery-over-enumeration decision; it **scopes** it. That decision is about how a rule's population is derived *from the rule's own declared scope*. Arm E honours it exactly — its population is a glob, so a tool added tomorrow is covered with zero edits to the arm — but the scope it derives from is **the rule Arm E enforces**, which is stated over the directory, and not the scope of the rule Arm A enforces, which is stated over the manifest. One engine, two rules, two declared scopes. Sharing an engine is not sharing a population.

The exclusions file is refused for an additional, independent reason: a `--self-test` suppression is not a documentation exemption. Applying it would drop `build-skill-packages.sh`, which *is* documented, and manufacture an orphan-row false positive.

**The arm asserts the relationship between the two denominators rather than assuming it.** It emits both counts on every run and then asserts an identity that explains their difference: `directory − manifest == non-dispatchers ∪ excluded`. Any member of the delta that is neither a written exclusion nor a tool lacking a `--self-test` dispatch is a divergence nothing accounts for, and it hard-fails naming the tool.

That identity is not decoration. It is non-vacuous exactly where the anti-narrowing arm stops: a narrowing carried out *correctly* — the directive deleted **and** its manifest lines deleted in the same diff — greens the manifest-floor arm by construction, and lands here.

## Decision kernel (version-agnostic)

> When one engine hosts more than one invariant, each invariant's population belongs to the rule it enforces, not to the engine that runs it. A population source that is already computed, already in scope, and numerically equal to the right answer today is the most dangerous kind of wrong: equality that holds by coincidence of current configuration cannot be distinguished from equality that holds by construction, and measurement will not tell them apart. Declare such a population literally at its point of use, record the measured counts of every source you refused and why, and — where two populations legitimately differ — assert the identity that *explains* the difference rather than the difference itself. An assertion that the two numbers are unequal is satisfied by any divergence; an assertion that the delta is exactly the set the rules predict fails the moment a divergence appears that nothing accounts for. Where a decision will read as a violation of a principle the surrounding code states, the record is part of the change: a future maintainer restoring the apparent principle is the failure mode.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| Route the population through `ctx.scope_members` | **Rejected** | Equals the directory population today, so it looks safe and measures safe. It is manifest-derived: narrowing a `# scope:` directive shrinks it silently, and the two non-dispatching tools in this directory were never on the manifest floor, so the anti-narrowing arm structurally cannot catch their loss. A mutation implementing this option is caught by exactly one of the nine arms shipped with this change. |
| Route through `ctx.discovered` or `ctx.expected` | **Rejected** | The filter the originating defect report names. Enforces over 33 while reporting green over 36 — the defect class the rule exists to close, reproduced in the mechanism. |
| Filter by the exclusions file | **Rejected** | A `--self-test` suppression is not a documentation exemption. Would drop a documented tool and manufacture an orphan-row false positive. |
| A standalone checker plus a new CI step | **Rejected** | A second engine over the same corpus re-opens the two-parsers drift the platform's own index generator exists to prevent, and adds a workflow step, a path-filter audit, and — if homed in the tools directory — a self-referential row for the checker itself, the reflexivity that already retired one of this card's acceptance criteria. |
| Generate the README table from the tool set (a derived surface) | **Rejected** | Measured: the table's rows carry 37,819 characters, of which the derivable row key is 813. Roughly 98% is irreducibly hand-authored prose, so the regenerate-and-diff posture a derived surface requires cannot hold; the "projector" would become a merge tool preserving hand-written cells — a different, unshipped mechanism. |
| Append a leg to an existing documentation checker | **Rejected** | The count-structure checker asserts a *stated cardinality* against an adjacent structure, and this README's rule forbids storing a count anywhere in the file, so its predicate has nothing to bind to. The link checker traces link targets, not directory membership. Neither owns the population. |
| Ship the arm in shadow (warn) first | **Rejected** | Shadow mode is for predicates that deliberately over-include, where a raw hit is not yet a finding. This is an exact-basename set comparison between two artifacts inside the repository — nothing to over-match, nothing to reconcile. A warn arm reproduces the defect the card names, one level up. |
| Prose only: strengthen the rule's wording | **Rejected** | This is the status quo, and the gap has already reopened twice under it. |

## Consequences

**`--reconcile` gains a failure cause it did not have.** The arm sequence accumulates into a single disjunction, so a documentation gap now exits non-zero where previously it could not. The CI step invoking `--reconcile` carries no `continue-on-error`, so a pull request that adds a tool without a README row is red-walled — which is the capability this change exists to create.

**The gate cannot miss its own trigger.** Every mutation that can open the coverage gap — adding, deleting or renaming a tool, or editing the README — is a write under `core/deploy/tools/**`, which is an unconditional entry in the workflow's path filter on both event types. The gate is absent-is-pass on out-of-scope pull requests, and no in-scope change can be one of them.

**An arm that cannot measure does not report a pass.** A missing README under the real checkout is a hard failure. Under an explicit alternative root it reports `not-run` positively, with the counters **omitted rather than zeroed**, and does not move the exit code. This is load-bearing rather than cosmetic: the fixture harness creates the tools directory and writes no README, and several existing fixtures assert exact exit codes from this mode. Zeroing the counters there would let a tree that was never measured read as clean.

**The engine's thin-caller property survives.** The workflow gains no predicate, no glob, and no roster; the step that already invoked `--reconcile` reaches the new arm with no functional change. Only a stale step *label* enumerating the old arms is corrected.

**The coverage gap open at authoring time is closed in the same change.** Two rows were backfilled. Shipping the arm without them would have turned the gate red on arrival — the precise hazard this card's own dependency analysis raised against its predecessor.

**A cost worth naming.** Two populations over one directory is a genuine comprehension burden, and the identity assertion is the price of keeping it honest. Someone who narrows a scope directive correctly and completely will now be stopped by an arm whose subject is documentation coverage, which will read as unrelated until they read the message. That is the intended trade: the alternative is that the same action silently shrinks a population nothing re-measures.

## Reversibility

**CHEAP / Confidence HIGH.** One `git revert` restores prior behaviour. No schema, no allowlist entry, no new file in the enforcement path, no state written anywhere, and no published artifact mutated. The two backfilled README rows are additive prose and are independently revertible, though reverting them alone would turn the arm red rather than restore anything.

The revert is self-announcing: the nine arms shipped with the change fail on reverted code, so a partial revert turns the suite red rather than quietly restoring an unenforced rule.

The **ADR itself** is immutable by convention: superseding it is a Status transition plus a new record, never an in-place edit or a deletion.

## Related ADRs

- **[ADR-119](ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md)** — the governing decision for this engine: the covered set is discovered from a declared scope, never enumerated, and the workflow stays a thin caller. This record **extends** it and does not supersede it; ADR-119's status is unchanged. The extension is the part ADR-119 had no reason to state, because it governed one invariant: when a second invariant joins the engine, "the declared scope" becomes ambiguous, and the population belongs to the rule rather than to the engine.
- **[ADR-152](ADR-152-dry-run-predicts-apply-asserts-mode-branch-placement.md)** — a sibling in this release on the adjacent tool family, and the same posture in a different register: an invariant carried only by convention gets rediscovered one instance at a time. Its paired-arm discipline is why every failing arm here ships with a control that differs from it by one fact.
- **[ADR-153](ADR-153-one-frontmatter-strip-bound-to-a-conformance-fixture.md)** — the sibling decision that an invariant spanning multiple implementations must be executable rather than annotated. The same argument applied to a population rather than a transform: a comment naming which set to count cannot fail, and this record exists precisely because the comment beside the globs is not, by itself, the control.
