<!-- reference-durability: allow-link -->
---
title: "ADR-119 — Self-test coverage is discovered against a declared scope, floored by a committed manifest, and gated by a thin caller over a committed engine"
status: Accepted — ratified by the workspace owner at the `ci-selftest-and-check-hardening` (v4.13) close gate, 2026-08-07. Authored at Stage 6 Engineering; the flip is recorded in this `status:` field, never inferred from milestone closure.
date: 2026-08-05
release: ci-selftest-and-check-hardening
deciders: "Workspace owner (ratified 2026-08-07 at the v4.13 close gate); the discovery-over-enumeration direction and the two-glob scope widening were rendered at the Mode R readiness gate and at Collective Review, designed at Stage 5 Solutioning, authored at Stage 6"
tags: [architecture, ci, gate-efficacy, discovery-over-enumeration, single-engine, thin-caller, derived-surface, self-test, reversibility-cheap]
source_observations:
  - "Three independent verification spokes in one prior release converged on the same finding from disjoint scopes and without coordination: no CI workflow ran the release tooling's --self-test suites. Convergence from disjoint scopes is what separates a systemic gap from a one-tool oversight."
  - "The gap is not merely a missing gate; it is the mechanism whose absence let two real defects reach acceptance review in that same release. Both were defects a self-test would have caught, and both survived because the self-test was a claim someone had run by hand rather than a gate anything enforced."
  - "The workflow that hosted the only automated self-test runner did so through a hardcoded six-tool roster, against twenty-two eligible tools in that tree. The roster is the same enumerate-don't-discover failure the gap itself is made of, sitting one level up, inside the fix's own file."
  - "The tool that a SIBLING card in this same release adds new recall cases to was absent from that roster. Its new self-tests would have shipped unenforced — the drift is not hypothetical, it was already producing a live miss at the moment the roster was read."
  - "Counting advertisers by `grep -l -- --self-test` counts files whose only occurrence is comment prose. That naive predicate produced two wrong published figures for this tree before a dispatch-shaped predicate was written; one file it counted returns `rc=2 unrecognized arguments` when actually invoked."
  - "A meta-assertion computed from the same source as the set it checks asserts nothing: 'advertises but is not discovered' is the empty set by construction. The obvious build of the requirement is the vacuous one."
  - "The first enablement run surfaced exactly one failure across fifty-seven discovered tools, and it was a predicate false positive rather than a regression — a comment matched the dispatch shape. A gate whose first run is nearly clean is a gate whose triage discipline will be tested by the rare case, not the common one."
  - "One tool hard-exits at load, before its argument parser is reached, unless `gh` resolves at a macOS Homebrew path. On a Linux runner its `--self-test` is unreachable, and the tempting remedy — dropping it from the discovered set — is precisely the remedy the originating card forbids."
---

# ADR-119 — Self-test coverage is discovered against a declared scope, floored by a committed manifest, and gated by a thin caller over a committed engine

## Status

**Accepted** — ratified by the workspace owner at the `ci-selftest-and-check-hardening` (v4.13) close gate, 2026-08-07. Authored at Stage 6 Engineering for that release, per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** Allocated as the next free slot over the union of both ADR directories, which are a single numbering space, verified by the corpus checker rather than by reading the highest filename. As with every ADR, the number is allocated at authorship and bound at merge; if a sibling merges ahead of this record, the reconciliation is tooled and this Status block will carry the provenance note.

## Context

A platform can advertise a self-test on every tool it ships and still have no idea whether any of them pass. That was the actual state: the tools carried `--self-test` suites, releases recorded them as PASS, and almost nothing executed them. A recorded PASS was a claim about a command someone typed, with no artifact and no gate behind it.

The single automated runner that did exist made the point sharper rather than softer. It ran a **hardcoded roster** of six tools out of twenty-two eligible ones in that tree. A roster is not a small version of coverage; it is a different thing that resembles coverage. It cannot grow when a tool grows a self-test, and it cannot shrink when a tool loses one, so the gap between what it claims and what is true widens monotonically and silently. That drift was already live: the roster omitted a tool that a sibling card in this very release adds new test cases to, so those cases would have shipped unenforced.

So the decision is not "add a CI job". Any roster-shaped job would reproduce the defect. The decision is about **where the covered set comes from**, and it has three parts that are easy to conflate and must not be:

1. **What runs** — the set must be derived from the tools themselves, not typed anywhere.
2. **How that derivation is prevented from quietly narrowing** — because the first thing anyone will want to do when enablement turns something red is to shrink the scope, and that is the one remedy that must not work.
3. **Where the logic lives** — because a discovery loop written inline in a workflow is reachable only by a remote CI trigger, which means the only way to exercise it locally is to re-implement it, and a re-implementation passes while the real gate diverges. This repository has already root-caused that exact class once, in a different gate, and extracted a shared library because of it.

There is a fourth constraint that looks like an implementation detail and is not. One tool genuinely cannot run on a Linux runner: it pins `PATH` and resolves `gh` at macOS Homebrew locations at load time, above its argument parser, so `--self-test` is unreachable there. A naive single-runner job goes red for a reason that is not a defect — and the obvious fix is to drop the tool from scope, which is exactly the forbidden move. The runner problem must therefore have an answer that is not a coverage decision, or it will be resolved as one.

## Decision

**(1) The covered set is DISCOVERED from a declared scope, never enumerated.**

Scope is declared as `# scope:` globs in one committed manifest. Membership within that scope is decided by a predicate over each tool's own text — does it *dispatch* on `--self-test`, not does it *mention* the string. A tool that grows a self-test is covered with **zero workflow edits**; a tool that loses one fails the gate. No roster, count, glob or predicate appears in any workflow YAML.

The dispatch-versus-mention distinction is load-bearing, not pedantry. The naive predicate counts comment prose and produced two wrong published figures for this tree; one file it counted returns "unrecognized arguments" when actually invoked. The predicate is also deliberately **recall-biased**, and that asymmetry is the design: a false negative is an unenforced self-test — the defect this record closes — and it is silent, while a false positive is one line in an exclusions file carrying a written reason, and it is loud. **Precision belongs in the exclusions file, never in the regex.** Tightening the predicate to kill a false positive re-opens the silent class.

**(2) The anti-narrowing guarantee is a COMMITTED MANIFEST FLOOR, not reviewer vigilance.**

The same manifest that declares the scope also carries the expected path set, with each `# scope:` directive sitting **immediately above the paths it produces**. A manifest path that still exists on disk but is no longer discovered is a hard failure that names every dropped path. Narrowing a glob therefore cannot green a build on its own: greening it requires deleting the listed paths in the same diff, directly beneath the directive that was narrowed, in the reviewer's eye at review time.

This is also what makes the meta-assertion non-vacuous. The two sides are **independently sourced** — the discovered set from a runtime glob, the floor from a committed artifact — so they can disagree. Computing both from one grep would make "advertises but is not discovered" the empty set by construction, which is the obvious build of the requirement and asserts nothing.

**(3) The gate logic is a committed, locally-invocable, self-testing engine; the workflow is a THIN CALLER.**

The engine is committed, runs offline from a clean checkout, and carries its own `--self-test`, which the job runs **before** the engine is trusted to gate — a broken engine must not be able to green the gate, and one whose discovery silently returned the empty set would otherwise report "0 of 0 passed" and look green forever. This extends the platform's existing single-engine discipline rather than introducing a convention.

The engine is written in **Python rather than shell** for a reason specific to this gate: one engine runs on two runners, and BSD/GNU divergence in `sed`, `grep`, `sort` and `find` would produce two different discovered sets *silently*. A secondary benefit, recorded so it is not mistaken for the reason: `python3 <path>.py` falls outside the shell-execution hook rule, so no execution-allowlist entry is required. That ordering matters — "it dodges an allowlist entry" is a bad reason to choose a language and would invert the dependency.

**(4) Runner affinity is declared AT THE TOOL.**

A tool that genuinely requires a specific runner says so in its own header comment; the engine partitions the discovered set by that declaration and asserts the partition is **total and disjoint**, so a typo'd declaration cannot silently drop a tool off both runners. A tool's runner requirement is a property of the tool. Putting it in the workflow would re-create a roster; putting it in the exclusions file would let a runner constraint masquerade as a coverage decision — which is how the forbidden narrowing gets made without anyone deciding to make it.

**(5) A failing self-test has exactly four dispositions, and narrowing the scope is not one of them.**

Runner-environment (declare the runner at the tool), genuine regression (fix it, or file it and record the issue reference), predicate false positive (exclude it with the quoted match that caused it), non-hermetic self-test (make it hermetic). Every first-enablement failure is classified into one of the four. `[narrowed the glob]` maps to no class, so it cannot be recorded as a valid disposition.

**(6) The `tests/` trees are OUTSIDE this scope — as a decision, not an emptiness claim.**

Those suites are bare-invocation entry points rather than `--self-test` dispatchers, and folding them in would conflate two unrelated conventions in one predicate and discard per-suite context that is load-bearing (runner-specific requirements, paired precision probes, named rationale). **The premise must be stated precisely, because the imprecise version is tempting and wrong: that tree is not empty of dispatch — at least one committed suite there does carry a real one.** The boundary is a scope decision. So the record does not merely state it: a warn-level arm names every committed suite no workflow runs, on every in-scope PR, which is strictly more than silence and more than a coordination note.

## Alternatives Considered

**Discovery written inline in the workflow YAML.** Rejected. It would be the only recent gate in this repository to re-encode its own predicate in YAML, against a stated single-engine rule. More concretely, it would be unreachable locally: the only way to exercise it would be to re-implement it, and a re-implementation passes while the real gate diverges. That is not speculation — this repository already extracted a shared decision library after that exact failure in a different gate.

**A shell engine instead of Python.** Rejected on cross-runner determinism, which is the disqualifier rather than a preference: one engine, two runners, and the shell text utilities diverge BSD-to-GNU in ways that would produce two different discovered sets with no error. The macOS runner's shell also lacks associative arrays, making the set arithmetic clumsy where it most needs to be exact.

**Folding the check into the existing deploy-check entry point.** Rejected on three counts. It would re-introduce this release's most contended file for no capability gain; that entry point is pinned to macOS for its BSD dependencies, which would drag the Python tools off the cheap Linux runner they use today; and it is exactly the append-another-check accretion the platform's own extend-before-create review exists to catch.

**Retro-fitting `--self-test` onto the `tests/` suites so the existing predicate reaches them.** Rejected. It changes many files to satisfy a predicate, inverting means and ends, and a suite whose only entry point is `--self-test` is a worse CLI than one invoked plainly.

**A composite action.** Rejected: zero in-repo precedent, and it would be the first, for no gain.

**Keeping the four hand-listed `<tool> --self-test` steps alongside the new job.** Rejected. Each is exactly what discovery now does; keeping them is duplicate execution *and* a second enumeration — the same argument that retires the roster applies to a hand-listed step, and applying it to one while sparing the other would be a half-fix.

## Consequences

The marginal cost of a new self-testing tool becomes **zero workflow edits** — one manifest regeneration. The retired roster was O(n) forever; the manifest is O(n) in *data*, which is the point: it is the floor, and its growth is the signal.

The debt this creates is honest and self-announcing: two committed config files that need regeneration discipline. Regeneration has a single supported path, and a new advertiser that lands without it fails loudly rather than accruing silently. The debt retired is larger: one hardcoded roster, four duplicate step definitions, and one hardcoded self-test row in the runtime-suite selection contract — the same anti-pattern in a third location, which would have been a half-fix to leave standing while deleting its sibling.

The gate is **path-filtered**, so its repo-wide reconciliation arm is sampled at in-scope-change time rather than continuously. A new advertiser added under a tree this workflow does not watch, in a PR touching nothing in scope, is not seen until the next in-scope change. Widening the filter to all shell and Python files was considered and rejected: it would trigger this job on nearly every PR. **The residue is bounded by the trigger, not by the scan**, and it is stated here rather than left for someone to discover.

Two properties are asserted by precision probes rather than assumed, because a guard nothing exercises cannot fire: that a deliberately broken self-test fails the gate via that tool's own named assertion, and that narrowing a scope directive fails the floor and names the dropped paths. Each probe runs a **control arm first** on the unmutated copy — a detection whose control also fires proves nothing.

## Reversibility

**CHEAP** · confidence **HIGH**. Reverting is deleting one job, one engine and two config files, and restoring the previous roster job from git history. No data migrates, no external system holds state, and no other gate's behavior changes. The scope is widened or narrowed by editing `# scope:` directives — a reviewable, one-line-per-glob operation whose consequences are visible in the same diff by construction.

The one asymmetry worth naming: the *convention* it sets — coverage is derived, floored by a committed artifact, and gated by a thin caller — is cheaper to keep than to unwind once other gates cite it, because each citation is a second place that would need re-deciding. That is a property of conventions generally, not a hidden cost of this one.

## Related ADRs

- The ADR number-claim binding rule (allocation at authorship, binding at merge) governs this record's own numbering and is cited in its Status block.
- The derived-surface contract precedent — a ledger projected from its declared source and verified by re-derivation at a check — is the same shape this record applies to a *covered set* rather than to a document, and it predates this decision.
