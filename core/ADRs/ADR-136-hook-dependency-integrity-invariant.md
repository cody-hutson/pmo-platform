<!-- reference-durability: allow-link -->
---
title: "ADR-136 — A sourced dependency must attest its contract out of process; a guard that its own subject can terminate is not a guard"
status: Accepted
date: 2026-08-15
release: hooks-enforce-under-adversity
deciders: "operator (Stage-4 plan gate; Collective Review scope-lock) + Stage 5 Solutioning spoke (design, D1-D7) + hub adversarial evaluation (R1/R2 verified rather than accepted)"
supersedes: ADR-130 in-part (D5 residual)
tags: [security-hooks, PreToolUse, fail-closed, dependency-resolution, integrity, attestation, immutability, GHSA-9cjm, supersedes-in-part]
source_observations:
  - "A dep-resolve.sh containing only `exit 0` is syntactically valid, so a `bash -n` precheck passes it; the top-level exit then terminates the hook from inside the guard's own condition, so the guard never reaches its deny branch and the hook exits 0. Reproduced against all three always-enforce hooks."
  - "The same silent allow reproduces for a second shape the originating card did not name: a helper that defines resolve_jq and THEN runs `exit 0`. The class is broader than one fixture."
  - "A `bash -n` precheck PASSES the exit-0 fixture, PASSES a semantically-empty file, and PASSES define-then-exit; it catches only truncation. The entire valid-syntax corruption class is outside what a syntax check can detect, by construction."
  - "Validating the helper out of process and requiring a sentinel was pre-registered as Alternative 5 of the mode-coupling record and rejected there on scope, not merit, pending bash-3.2 validation and a fork-cost measurement. Both are discharged here: the arm matrix runs green on bash 3.2.57, and the measured cost is ~3.6 ms per hook invocation over three 60-iteration runs."
  - "An out-of-process probe ALONE is insufficient: a helper that passes the probe and exits on the real in-process source still yields exit 0. Reproduced. The real source cannot be eliminated, because the hook needs the helper's functions in its own shell."
  - "When a sourced file terminates the shell, the `2>/dev/null` redirection on the source is still in effect while the EXIT trap body runs, so a trap writing to stderr is silently swallowed — exit 2 with no message. Isolated by differential probe: identical logic with and without the redirection."
  - "The helper and the hook that sources it have identical ownership and identical write permissions in the deployed bundle. Anyone able to replace the helper can replace the hook, so no in-process check can be a security boundary against that writer."
  - "A checksum manifest measures ~9.9 ms per hash — roughly 2.7x the attestation probe — and converts every un-regenerated helper edit into total agent lockout, which is the release's highest-severity risk rather than a mitigation of it."
---

# ADR-136 — A sourced dependency must attest its contract out of process

## Status

**Proposed.** Authored at Solutioning for the `hooks-enforce-under-adversity` release; ratified at that release's plan-review gate.

**Supersedes in part:** D5 of [ADR-130](ADR-130-lib-missing-guard-is-mode-coupled.md), which stated the always-enforce floor's guarantee at its true — narrower — scope and named the valid-syntax `exit 0` residual as pre-existing and tracked separately. That residual is closed here. D5's *reasoning* stands unchanged and is not rewritten in place: it was correct when written, and the mode-coupling it justified was argued on independent grounds. ADR-130's D1-D4 and D6-D8 are unaffected, and the mode-capable cohort is not touched.

**Numbering provenance — `134 → 135`.** Held **ADR-134** branch-local; renumbered to **ADR-135** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 134. In-release citations that read "ADR-134" denote this record.

**Numbering provenance — `135 → 136`.** Held **ADR-135** branch-local; renumbered to **ADR-136** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 135. In-release citations that read "ADR-135" denote this record.

## Context

Every PreToolUse security hook sources a shared helper to resolve `jq` and `python3` from a fixed absolute-path allowlist. The helper is guarded, and the guard is necessarily the first gate in the file: the action-scope short-circuit needs the tool name, the tool name needs `jq`, and `jq` comes from the helper. The guard's shape has been, verbatim: test readability, source the helper inside the condition, then check that an expected function resolves.

That shape has a hole its own comments describe as closed. The precheck it relies on verifies that the helper **parses**; it never verifies that the helper **means** what the hook expects. A helper whose entire content is `exit 0` parses perfectly — and because `.` executes the file in the hook's own shell, the top-level exit terminates the hook **from inside the guard's own condition**, before the failure branch can run. The hook exits 0. A security control that cannot evaluate its input has allowed.

Two properties make this worse than an ordinary detection gap. First, the guard is evaluated **before** the operator bypass, so the failure is not recoverable from inside a session in either direction — neither the block nor the allow. Second, the deny is the property on which nine other hooks were permitted to degrade: the floor's unconditional denial is the stated basis for coupling the mode-capable cohort. A floor that silently allows removes that basis retroactively.

The question this record answers is not "how do we detect a corrupt helper" — several mechanisms do that. It is: **how does a guard rule on an artifact that can terminate the guard?** Any design that evaluates the helper by sourcing it inside a condition inherits the defect, no matter how strict the conditions are.

## Decision

**D1 — The threat model is corruption and partial installation, not in-process compromise. Say so, and design to it.** The helper and the hook that sources it are co-located with identical ownership and write permissions; a writer who can replace one can replace the other. Once arbitrary code runs in the hook's shell it holds the hook's full authority, so no in-process check is a boundary against it. The population this guard defends against is therefore the real one: an interrupted copy, a disk-full write that lands valid syntax, a stale or partial deploy, a version-skewed bundle, and non-adaptive tampering. Stating the model is load-bearing rather than throat-clearing: it is what makes the expensive, lockout-prone integrity-manifest option unnecessary, and what keeps the record from claiming a guarantee it cannot hold.

**D2 — The helper attests its contract OUT OF PROCESS, before it is admitted to the hook's shell.** The guard first evaluates the helper inside a command substitution. A top-level exit there terminates the child, never the hook. The subshell emits a contract token as the **final** term of a conjunction, and that token is printed **by the hook's own code** — reachable only if control **returned** from the source and every contract term held. A helper that exits can never produce it. The helper's own stdout is discarded during the source, so it cannot forge the token either. **This inverts the guard's relationship to its subject: the artifact must now prove it is sound, rather than the guard proving it is broken.** An absence of evidence becomes a denial by construction, which is what fail-closed means.

**D3 — The expected contract value is captured `readonly` above any source.** Immutability, not ordering, is the control — a sourced file cannot overwrite a `readonly`. This is [ADR-130](ADR-130-lib-missing-guard-is-mode-coupled.md) D3's primitive applied to the second value the guard's verdict now depends on. The attestation helper is additionally marked `readonly -f`, which a redefinition attempt is refused against.

**D4 — An EXIT trap covers the in-process source, because that source cannot be eliminated.** The hook needs the helper's functions in its own shell, so after attestation it sources for real. A helper swapped between the two evaluations — a reinstall landing during a live session — could still exit there. An EXIT trap armed **before** the source and disarmed only once the contract is proven converts any premature termination of the guard region into a deny. **The trap writes to a saved copy of stderr on a dedicated descriptor.** When a sourced file terminates the shell, the redirection suppressing the source's diagnostics is still in effect while the trap body runs, so a trap writing to plain stderr is silently swallowed: exit 2 with no message. A deny nobody can read is a materially worse outcome than a loud one, and this is the single most easily-missed detail in the implementation.

**D5 — The three mechanisms are layers, not candidates.** Each closes a gap demonstrated to survive the others: attestation alone loses to a helper that exits on the second evaluation; the trap alone yields a message-less deny and cannot detect wrong semantics that return control; the `readonly` capture alone protects a value the other two must first be able to reach. Selecting one and discarding two ships a guard with a reproduced hole.

**D6 — The contract token is a breaking-change signal, and its skew is caught statically.** The token is bumped only when the helper's contract changes, and every carrier is edited in the same commit. Because a skewed token denies every matching tool call across the floor — and the operator bypass cannot clear it — a static check asserts the token agrees across the helper and every carrier, so skew introduced in the repository cannot reach a deploy. **The lockout vector is created by this decision and is mitigated by this decision; it is not left implicit.**

**D7 — The floor stays mode-independent, and the mode-capable cohort is untouched.** No mode is consulted in the guard. Coupling one of the three would void the basis on which the nine were allowed to degrade, and the conformance check fails on it. The nine retain the same in-condition source and the same syntax precheck, and therefore the same corruption exposure; that is a knowing scope boundary, recorded so a green release is not read as closing the class.

## Decision kernel (version-agnostic)

**A control must not evaluate an artifact in a context that artifact can terminate.** Where in-process evaluation is unavoidable, the control must (a) obtain a positive attestation from an out-of-process evaluation first, (b) hold the values its verdict depends on in storage the artifact cannot write, and (c) install an interceptor that converts premature termination of the evaluation region into the control's deny, on a diagnostic channel the evaluation cannot suppress. Absence of a positive attestation is a denial, never a pass.

## Alternatives Considered

1. **Keep `bash -n` and tighten it.** Rejected as a category error, and prohibited by the originating card. A syntax check verifies parsing; the defect is semantic. Measured: the precheck passes the `exit 0` fixture, passes a semantically-empty file, and passes define-then-exit — it catches only truncation. It is also the control the defect defeats, so hardening it hardens the wrong thing.

2. **Post-source invariant check alone** — require the helper to define a sentinel and return a value, checked after sourcing. Rejected on the second-order failure: if the helper exits at its top level, control never reaches the post-source check. This is the strongest-looking of the card's three candidate directions and the one that fails most quietly, because it reads as strictly stronger than the shape it replaces while being equally terminable.

3. **Pre-source `readonly` capture alone** — the mode-coupling record's C-1 primitive. Rejected as necessary but not sufficient. It defeats a helper that *overwrites* the guard's decision; it does nothing about one that *terminates* the guard before the decision is read. Adopted as D3, in composition rather than in isolation.

4. **Integrity-check the helper against a checksum manifest.** Strongest on the accidental-corruption class and genuinely tempting. **Rejected on measured cost and on risk direction.** It measures roughly 2.7x the attestation probe per hook invocation. More decisively, it makes every legitimate helper edit whose manifest was not regenerated a **total agent lockout** across the floor's Read, Bash, Write and Edit matchers — with no bypass, recoverable only from the operator's own terminal. That is the highest-severity risk in this release's register, and this option maximizes exactly it. A control whose failure mode is worse than the defect it closes is not a control. The contract token retains most of the version-skew detection at a fraction of the cost, with a static pre-merge check as its safety.

5. **Extract the guard into a shared library.** Rejected on the reasoning the prior record already established: a guard library cannot guard itself, and it adds a second file to the partial-install failure surface — enlarging the very population the change exists to make survivable. The cost is a guard duplicated across three carriers; the conformance check is the anti-drift instrument in place of extraction.

6. **Stop sourcing entirely — call the helper out of process for its values.** Genuinely closes the residual in D1, since nothing untrusted ever enters the hook's shell. Rejected on blast radius and on this release's constraint that the change be additive: it rewrites how every carrier obtains its dependencies, alters the healthy path materially, and reaches beyond the three hooks in scope. Recorded as the successor design if the residual ever becomes real.

7. **Move the bypass check above the guard so the advertised recovery works literally.** Rejected for the same reason the prior record rejected it: it touches every carrier including the floor, and a working recovery already exists in a bundle reinstall the hooks do not gate. Not reopened here.

## Consequences

**Positive.** The floor's deny now holds for the classes it was documented to hold for and did not: valid-syntax semantic corruption, define-then-exit, version skew, and a helper swapped mid-guard. The guarantee stated in the hook registry becomes true rather than aspirational. A residual that three artifacts printed on every test run becomes an assertion. The guard's verdict no longer depends on any value the adjudicated artifact can write or reach. The deny message now carries its own recovery instruction and the fact that the operator bypass will not clear it, so the block is self-explaining at the moment it fires.

**Negative, named.**

- **A new lockout vector.** A skewed contract token denies every matching tool call across the floor, and the bypass cannot clear it. Mitigated statically (D6), not eliminated. A skew introduced by a partial *deploy* rather than a commit remains recoverable only from the operator's terminal.
- **~3.6 ms added per hook invocation** on roughly 7.3 ms of existing per-hook cost: one additional fork and one additional evaluation of the helper. Bounded to the three floor hooks.
- **The helper is evaluated twice per invocation.** Harmless for a definitions-only file, and a constraint on it forever: the helper must remain side-effect-free at its top level. Stated here because nothing else enforces it.
- **The guard region is longer and duplicated across three carriers.** Deliberate, per Alternative 5.
- **The residual is narrowed, not closed.** An adaptive helper that satisfies the out-of-process attestation and then strips the interceptor on the in-process source still yields an allow. That is a compromise rather than a corruption, and per D1 a writer with that access can replace the hook itself. Named in the registry documentation rather than left to be rediscovered — the same discipline the prior record applied to the defect this one closes.
- **The nine mode-capable hooks keep the identical exposure.** Deliberate scope boundary; in `warn`/`off` their silent allow is additionally indistinguishable from their intended degrade.

**Blast radius.** The helper has 51 first-order and 295 second-order referrers, and 17 hook scripts source it — the change is **Structural** on the impact scale. It is nonetheless **additive by construction**: the prior guard's conditions are retained verbatim and new terms appended, so every input that reaches a rule body today still reaches it. A healthy-lib negative control against the real shipped helper is mandatory in the test surface for exactly this reason; without it a false-positive guard ships green.

## Reversibility

**MODERATE · confidence HIGH.** Reverting the merge restores the prior guard cleanly — no data, state or vocabulary migration. But the revert direction is **toward** the defect: it re-opens a silent allow on a security floor, which is the unsafe direction, unlike the prior record whose revert was toward safety. A revert is therefore a decision requiring its own rationale, not a reflex. Execution cost is CHEAP; consequence is not.

## Related ADRs

- [ADR-130](ADR-130-lib-missing-guard-is-mode-coupled.md) — the mode-coupling record. **Superseded in part** (D5's residual only). Its Alternative 5 pre-registered this design and rejected it on scope pending bash-3.2 validation and a fork-cost measurement; both are discharged here. Its D3 immutability primitive is adopted as D3. Its D4 always-enforce boundary is preserved unchanged by D7.
- [ADR-078](ADR-078-security-hook-dependency-resolution-posture.md) — the founding dependency-resolution posture. D4's unconditional deny for hooks with no mode surface is the property this record makes true for the corruption class.
- [ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md) — the generated hook registry. The registry changes accompanying this decision are made in the source fragments and the index regenerated, never hand-edited.
- **[ADR-134](ADR-134-degraded-state-emit-contract.md) (degraded-state emit contract), `check-fail-open-elimination`** — allocated 133 alongside this record, merged to mainline as **ADR-134** while this branch was in flight. This record **conforms** to its decision kernel (a distinct emitted member for every reachable state of a predicate; clean and degraded may never share one) and to its register-freezing rule (the `LIB-MISSING` marker is kept unrenamed because live consumers grep it). It **diverges** on the gating obligation: that record governs reporting surfaces, where a measurement outage must never gate, while this one governs an enforcement surface, where a control that cannot evaluate its input must deny. The boundary is not new — the hook registry already records that the check cohort is a reporting cohort and the hook cohort an enforcement cohort, and warns that unifying them on consistency grounds re-couples a security guard to a dial it was deliberately removed from. It landed on 134; the reciprocal cross-reference should be added there.

## Numbering note

This record is **ADR-136**, not the ADR-133 its design specified. The design allocated 133 as `anchor(origin/main) + 1` when the mainline anchor was 132, and accepted a deliberate collision with two unmerged sibling claims on the recorded rule that *a gap blocks the repository whereas a duplicate is tooled*, and that an unmerged branch claim is advisory rather than binding.

Between that allocation and this authoring, **133 merged to mainline** under an unrelated subject (the material-edit test record, in the release ADR directory). A merged claim is binding, not advisory, so the rule that permits colliding with unmerged siblings does not reach it: taking 133 here would not be a tooled duplicate, it would be a genuine conflict with mainline. The anchor is therefore 133 and next-free is 134, which `release/tools/renumber-adr.py --next-free` independently returns.

Two unmerged siblings still held 133 at that moment — the degraded-state emit contract on `check-fail-open-elimination` and a gate-default record on `stage9-gate-integrity`. Both then collided with **mainline** rather than with each other, and both renumber at their own merge. This record did not reserve above them: 134 was next-free above the merged anchor, and no branch claimed it at the time.

**Then the same mechanism fired a second time.** `check-fail-open-elimination` merged during this branch's own Engineering run and its record took **134** — the very slot this one had just claimed. So the lineage is `133 → 134 → 135 → 136`: allocated at 133, moved to 134 when 133 merged beneath it, moved again to 135 when 134 merged beneath it, and a **third** time to 136 when `stage9-gate-integrity` merged during this branch's Stage-7 window and its own record took 135. Neither move is drift. A number is **allocated at authorship but claimed at merge**, which exposes any record on a long-lived branch to every sibling that merges ahead of it, and pre-reserving a higher slot is no remedy because the integrity gate fails a gap as readily as a duplicate. `release/tools/renumber-adr.py --next-free` returned 135 at the second move and 136 at the third, and the § Status provenance note records one hop each. Three moves, three different siblings — the allocation rule behaving correctly under sustained contention on a long-running branch, not drift.
