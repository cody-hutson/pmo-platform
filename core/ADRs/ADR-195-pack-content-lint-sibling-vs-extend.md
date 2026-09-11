---
title: "ADR-195 — The pack content-completeness lint is a sibling check over a shared reader, not a rule set inside the grammar check"
status: Accepted (rendered at the pack-conformance-and-parity Stage 5 Solutioning pass and carried into Engineering; the siting was discovered by measurement rather than chosen by preference)
date: 2026-09-10
release: pack-conformance-and-parity
deciders: Stage 5 Solutioning spoke (three-candidate design exploration, two eliminated on in-corpus evidence) + the operator at the Stage 5 wave-1 gate + Stage 6 Engineering on the check-number and register-row placement
tags: [packs, type-packs, deploy-check, content-completeness, grammar-conformance, extend-before-create, sibling-check, shared-primitive, control-arm, warn-mode, ADR-068, ADR-090, ADR-135, ADR-166, ADR-188]
source_observations:
  - "As measured at this record's authoring: the pack corpus spans 17 tracked manifests declaring 21 kinds, which project to 63 criteria tables and 21 field tables — 84 declaration sites in all. 51 of the 63 criteria tables omit the checks key entirely. Two independently-shaped readers agree on that figure; a fabricated key returns zero over the same 17 files, and the 12 tables that do carry the key are what proves the reader finds it where it is."
  - "Every declaration site across the six fixture packs the grammar check discriminates on — 32 sites, both discrimination fixtures included — is array-absent. A rule that fires on an absent array therefore fires on both of that check's control arms."
  - "The grammar check's control arm compares its sensitivity-arm rule-id list to a single literal by exact string equality, and the failing branch increments the issue counter OUTSIDE the warn-mode gate. Any added rule that fires on the nonconforming fixture appends to that comma-joined list and hard-fails the check on every mode, warn included."
  - "The grammar validator never descends into a criteria block's interior at all: the token checks occurs zero times in it, against live controls on the same reader over the same file, and its kind-level rule tests the criteria object's presence by truthiness over a required-field tuple that contains no nested key. The two rule sets are therefore disjoint by construction, not by convention."
  - "The operator baseline's system Python is 3.9 and carries no TOML parser in its standard library; the validator's own in-source comment states this as the reason it hand-rolls a section-scoped reader. A second tool reading the same manifests would therefore re-implement a hand-rolled dialect that can disagree with the first."
  - "The shipped pack corpus is content-complete at every declaration site, so a content lint over it reports zero findings on the day it ships. The empty-array sites all carry a block-level source; there are no array-absent sites in the shipped corpus at all."
  - "core/packs/ carries three manifests as measured at this record's authoring, two of which declare at least one kind; the third is the base pack and declares none."
supersedes: none
---

# ADR-195 — The pack content-completeness lint is a sibling check over a shared reader, not a rule set inside the grammar check

## Status

**Accepted** — rendered at the `pack-conformance-and-parity` Stage 5 Solutioning pass and carried into Engineering unchanged. The record exists because the determination was **forced by measurement**, not chosen by preference, and the next author reaching for the obvious shortcut needs to find the measured reason not to.

**Numbering provenance.** Authored at the next free number computed from the mainline anchor plus one, from a single anchor read shared with the sibling record this same release may author, so that two spokes could not compute next-free independently and collide. A branch-only claim on this number is detection-only and never binds for mainline purposes; if the mainline advances before merge, the merge-time renumberer moves this record and in-release prose citing the slug token `ADR-195` resolves correctly either way.

## Context

A kind declared in a type pack may carry no fields and no criteria. The grammar says that is **valid** — the thin-generic floor — so a completeness rule cannot declare such a kind invalid without contradicting the specification it is supposed to enforce. Content-completeness therefore has to live **beside** grammar-conformance rather than inside it. That much was settled against the shipped grammar before this release began, and it is a posture, not an architecture.

The architectural question this record answers is narrower and was not visible until it was measured: **where does the content lint physically go?** A pack-grammar check already exists, already runs a validator over the live pack root, and already owns a `PACK-*` rule namespace. "Extend what exists" is the platform's standing preference and the obvious answer.

**The obvious answer is unavailable, and the reason is mechanical.**

The grammar check runs a **discrimination control before its live-corpus run** — a sensitivity fixture that must produce exactly one named rule id, and a specificity fixture that must produce none. It asserts the sensitivity result by comparing the emitted rule-id list to a single literal **by exact string equality**, and the branch that fires on inequality increments the issue counter **outside** the warn-mode gate. That branch is unconditional by design: a check that cannot be shown to discriminate must not report a clean corpus.

Now measure what a content rule would do to that fixture set. Every one of the 32 declaration sites across the six fixture packs is **array-absent** — the fixtures exist to exercise pack *grammar* and say nothing about content, so they declare no content. A completeness rule keyed on silence therefore fires on the sensitivity fixture **and** on the specificity fixture. On the sensitivity arm it appends its own id to the comma-joined list, which stops equalling the literal; on the specificity arm it turns an expected zero into a non-zero. **Adding the rules in place hard-fails the grammar check on every mode, warn included, from the first commit.**

A third force pushes the other way. The primitive that reads pack manifests is the only one in the tree, and it exists because the operator baseline's system Python carries no TOML parser: the reader is hand-rolled and section-scoped. A second tool reading the same files would re-implement that dialect, and two hand-rolled readers of one grammar can disagree about what a manifest says — which is the worst possible failure for a pair of gates whose whole job is to agree about pack content.

So the two obvious moves are each blocked by a different constraint, and the constraints point in opposite directions.

## Decision

**Split the layers. `extend` the primitive; `net-new` the check.**

- **The primitive is extended.** The existing pack-reading validator gains a new content-validation mode and a distinct `PACKC-*` rule namespace. One pack reader, one hand-rolled dialect, one place where "what this manifest says" is decided. Nothing is forked.
- **The check is net-new.** The content lint registers as its **own** `deploy.sh` check, with its own check id, its own resolvable mode, and — critically — **its own discrimination fixture pair**. The grammar check's fixtures, exit codes, rule ids and control-arm equality assertion are untouched.

Three properties follow, and they are the reason the split is worth a record rather than a comment.

**D1 — The grammar check's behaviour is unchanged by construction, not by testing for it afterwards.** Because the `PACKC-*` rules live outside the grammar validation mode, the string the control arm compares stays exactly what it was. There is no regression to detect because there is no path by which one could occur.

**D2 — The two namespaces are separately identifiable, and that is machine-readable rather than cosmetic.** The check that consumes rule ids extracts them from the emitter's output and asserts on the resulting string by exact equality. Sharing the `PACK-` prefix would make the grammar and content sets indistinguishable in the one place a human reads them — the log line and the warn-log detail field — and would make any future control-arm assertion silently ambiguous. A distinct prefix carrying the existing family-plus-ordinal shape inside it is the safer choice; the more consistent-looking choice is the less safe one.

**D3 — The check ships `warn`, and its graduation is one committed token.** The mode resolves through the per-check decoupling the platform already uses at three live checks, and the flip is a **committed default**, never a runtime mode file — flipping via a mode file would arm a blocking gate with no repository record of the arming. **A second check id is not a bespoke mode flag; it is the platform's own per-check mechanism used as designed.**

**And one thing the decision deliberately does not do.** It does not weaken the grammar section's existing prohibition on an array-scoped rule. That prohibition remains exactly correct **for any rule added inside the grammar check**, and this record is the reason it can be honoured while a silence-scoped rule still ships: the content rule escapes the prohibition by being sited elsewhere with its own fixtures, not by the prohibition being wrong.

## Alternatives Considered

Three options were generated; two are rejected on in-corpus evidence, and both rejections are recorded so they are not re-litigated.

**(a) Add the `PACKC-*` rules to the existing grammar validation mode.** *Rejected — it breaks the gate it extends.* This is the extend-before-create default and it fails on the exact-equality control arm described in § Context. Every fixture declaration site is array-absent, so the added rules fire on **both** discrimination arms, and the failing branch sits outside the warn-mode gate. The check would go red on every mode from the first commit.

**(b) Ship a standalone content-lint script.** *Rejected — it forks the pack reader.* The existing primitive carries the only baseline-compatible pack reader in the tree, hand-rolled precisely because the baseline interpreter has no TOML parser available. A second reader means a second hand-rolled dialect, and two readers of one grammar that can disagree about what a manifest says is a worse failure than either gate being absent.

**(c) Re-fixture the grammar check's six fixture packs so they carry content on all 32 surfaces.** *Rejected — it mutates a grammar gate's evidence base to satisfy a content rule.* It obliges fixtures that exist to say nothing about content to carry content provenance, and it makes a content change able to break a grammar gate's discrimination claim. The evidence base of a gate is not a shared workspace.

**Why the survivor is a split rather than a single verdict.** No single answer satisfies both constraints: the reader must be shared and the fixtures must not be. Splitting the layers is what lets each constraint be honoured at the altitude where it applies — reuse at the primitive, isolation at the gate.

## Consequences

**Positive.**

- The grammar check keeps its discrimination claim intact, and the claim is now protected structurally rather than by a regression test that has to be remembered.
- One pack reader survives, so the two gates cannot disagree about what a manifest says.
- The `PACKC-*` namespace admits further content rules with no change to either gate's registration, the way the grammar namespace already does.
- Log lines and warn-log rows distinguish a grammar finding from a content finding at a glance.

**Negative, and stated rather than smoothed.**

- **A second check to maintain.** Two check registrations, two modes, two fixture pairs. The cost is real; it is the price of the isolation that makes D1 true.
- **The content check ships with no firing population.** The corpus it validates is already content-complete, so the check is green on the day it ships and the specificity reading its own standard requires cannot be taken. That is why its flip is criterion-gated on a repository-derivable population threshold rather than on a date or a drain count — a gate with no sample is not a gate that works, it is a gate not yet observed.
- **Findings are non-blocking at ship; loss of discrimination is not.** The check shape adopted here carries its control-arm branch outside the mode gate, exactly as the grammar check does. So a content finding cannot fail a deploy while the check is in warn, but a content check that stops discriminating **can**. This is correct and intended, and it is recorded because "the check ships warn" is otherwise read as "nothing about it can fail the deploy."
- **A new prefix is a new identifier.** Once the check id, the mode name and the rule namespace are referenced by a register row, they acquire a rename cascade. Cheap while unshipped; not cheap afterwards.

## Reversibility

**MODERATE — HIGH confidence.** Cheap while unshipped: the whole decision is a file layout plus two registrations, and reverting the commit restores the prior state byte-for-byte. It crosses to MODERATE at the moment the check id, the mode name and the `PACKC-*` namespace are named by a gate-coverage register row and by a runner pointer, because from then on a rename is a cascade across the register, the standard, the schema and the check itself rather than a local edit.

## Related ADRs

- The **domain fan-out sibling-versus-extend** record and the **structural path-move extend-versus-sibling** record are the two prior instances of exactly this decision class on a shared primitive. This record joins that family; naming it is what keeps the third instance from being decided from scratch.
- The **armed-versus-enforcing** record governs the posture this check ships in: a gate ships armed — running, in warn — by a committed default, and arming and enforcement graduate separately.
- The **disposition-names-its-blocker** record governs the flip criterion's shape: a deferred flip names what blocks it, never a schedule.
- The **pack-configurable-versus-platform-fixed boundary** record is the immediate predecessor on this surface. Its observation block records the corpus as it stood when that record was authored and is preserved unrewritten; the figures in this record's own observation block are a later reading of the same population, not a correction to that one.
