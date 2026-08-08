<!-- reference-durability: allow-link -->
---
title: "ADR-129 — The dependency-helper guard is mode-coupled for the mode-capable cohort; the always-enforce floor stays unconditional"
status: Proposed
date: 2026-08-08
release: hook-precision-and-boundaries
deciders: "operator (Collective Review scope-lock — adopt the readonly-snapshot counter-design; ship the uniform coupling and file the invariant defect separately) + Stage 5 Solutioning spoke (design) + independent adversarial design review (three parallel reviewers)"
tags: [security-hooks, PreToolUse, fail-closed, mode-coupling, dependency-resolution, degradation, GHSA-9cjm, GHSA-g9g6, supersedes-in-part]
source_observations:
  - "The prior posture left the shared dependency-lib guard fail-closed UNCONDITIONALLY: it runs before the mode read, before the bypass check, and before the action-scope short-circuit. A version-skewed install (new hooks plus a valid-but-stale dep-resolve.sh) therefore hard-blocked every Bash and Write in warn as well as enforce, with no mode or bypass escape, until the operator re-ran the installer."
  - "That over-block is fail-CLOSED and recoverable, but it blocks in modes where a rule match itself would not have blocked — which is the asymmetry the prior record named as an accepted residual and deferred to its own ADR."
  - "Nine of the thirteen dependency-guarded hooks have a mode surface. Three have none by design (credential-read, destructive, rm-prefer-trash) and one is a manually-run CLI tool, not a PreToolUse hook."
  - "A guard that sources the untrusted helper inside its own condition has already admitted that helper to the shell by the time the failure branch runs. A stale helper that additionally defines get_mode(){ printf off; } made a definition-hoist design exit 0 with 'degraded, .mode=off' while the mode file on disk read enforce — reproduced by the adversarial reviewer and independently re-reproduced during implementation."
  - "The floor's unconditional deny is real for an absent, unreadable or truncated helper, and NOT real for a syntactically-valid helper whose top level runs `exit 0`: that terminates the hook before the guard can rule, and `bash -n` cannot detect it because the syntax is valid. Pre-existing; tracked as its own defect."
---

# ADR-129 — The dependency-helper guard is mode-coupled for the mode-capable cohort

## Status

**Proposed.** Authored at Engineering for the `hook-precision-and-boundaries` release; ratified at that release's plan-review gate.

**Supersedes in part:** the *unconditional* fail-closed posture for the dependency-helper source guard recorded as D4 of [ADR-078](ADR-078-security-hook-dependency-resolution-posture.md). D4 remains the governing, unchanged record for hooks with no mode surface, and D4's body is deliberately not rewritten in place — it is the founding record of the posture, and the security patch it belongs to was reviewed against that text. ADR-078's D1, D2, D3, D5, D6, D7 and D8 are unaffected.

## Context

Each `PreToolUse` security hook sources a shared helper, `core/hooks/lib/dep-resolve.sh`, to resolve `jq` (and `python3`) from a fixed absolute-path allowlist. The helper is guarded: if it is absent, unreadable, unparseable or stale, the hook denies. That guard is necessarily the *first* gate in the file — the action-scope short-circuit needs the tool name, the tool name needs `jq`, and `jq` comes from the helper — so it precedes the mode read, the bypass check and the scope gate.

Denying unconditionally there is correct for a hook that always enforces. It is wrong for a hook that ships in `warn`. In `warn`, a genuine rule match only warns; a broken *install* then blocks harder than the violation the hook exists to catch. The practical shape is a version-skewed install — new hooks alongside a stale helper — which hard-blocks every Bash and Write until the operator reinstalls. Fail-closed, recoverable, and still wrong: the severity does not match the posture the operator selected.

Two forces constrain the fix. **(1)** The mode must be resolvable without the helper. It is: every hook reads its mode with `cat` and `tr` from PATH-pinned constants declared above the guard. **(2)** Degrading the mode-capable hooks must not amount to a silent, total disable of the security layer. It does not, because hooks with no mode surface keep denying — but that property was accidental, undeclared and untested, and the exact scope of it turns out to be narrower than it first appeared.

## Decision

**D1 — Couple the guard's severity to the hook's own mode, for hooks that have one.** For each of the nine mode-capable hooks, an unusable `lib/dep-resolve.sh` denies in `enforce` (`exit 2`, with the block message byte-identical to the prior posture) and degrades in `warn`/`off` (`exit 0`) after emitting a `[CLAUDE-HOOK:<hook>:LIB-MISSING] WARN (degraded, <mode-file>=<mode>)` notice on stderr. This is the posture ADR-078 D2 set for external dependencies and D6 set for internal primitives, now extended to the helper source itself.

**D2 — The notice is emitted in `off` as well as `warn`.** `off` disables *rule enforcement*, not *install-integrity reporting*. A silent degrade would leave an operator with nothing to notice and an agent with nothing to surface.

**D3 — Resolve the mode into a `readonly` snapshot ABOVE the guard; the failure branch reads the variable and never calls the function.** This is the load-bearing mechanic and the one that is easy to get wrong. Hoisting the mode-resolving function above the guard is not sufficient: the guard's own condition sources the helper into the current shell, so by the time the failure branch executes, the artifact under adjudication has had the opportunity to redefine that function and select the guard's verdict. A stale helper that also defines `get_mode(){ printf off; }` — syntactically valid, so the parse precheck passes it — yields `exit 0` and a notice reading `.mode=off` while the mode file on disk reads `enforce`. **The control is immutability, not ordering.** A sourced file cannot overwrite a `readonly`. Ordering was never the control; it only looked like it was.

**D4 — The always-enforce hooks are not touched.** `block-credential-reads.sh`, `block-destructive.sh` and `block-rm-prefer-trash.sh` have no mode surface, keep the unconditional deny, and keep the older, looser guard shape. The stricter detector is deliberately applied only to hooks that can degrade: on a hook that cannot, stricter detection converts a benign version-skew into an inescapable denial across Read, Bash, Write and Edit. Recorded so a later "make it uniform" sweep does not undo the reasoning by tidiness. `check-hook-dep-hardening.sh` CHECK-4 fails if one of the three acquires a mode-coupled guard.

**D5 — State the floor's guarantee at its true scope, and no wider.** The floor's deny holds for an **absent, unreadable or truncated** helper. It does **not** hold for a syntactically-valid helper whose top level runs `exit 0`: sourcing executes the file in the hook's own shell from inside the guard's condition, so a top-level exit terminates the hook before the guard can rule, and a syntax precheck cannot see it. This defect is pre-existing, is not introduced or widened here, and is tracked as its own work item; it is named in this record because the decision to degrade the mode-capable cohort was originally argued from a stronger claim than the evidence supports. The coupling stands on its own reasoning — enforce is untouched, and an adversary who can write `off` into a mode file could already disable the hook outright — not on a total-backstop premise. `hook-fail-closed.test.sh` prints the residual on every run so a green suite cannot be read as a total guarantee.

**D6 — Cohort membership is structural.** A hook is in the coupled cohort exactly when it declares both a mode file and a dependency guard. `check-hook-dep-hardening.sh` CHECK-5 asserts the conformance shape over that derived set, so a tenth mode-capable hook is covered the day it is added rather than the day someone remembers to add it to a list.

**D7 — The degrade branch takes no new external dependency.** It renders the mode-file name with shell parameter expansion rather than shelling out. This branch runs only after the install has been detected broken; it is the one place that must not assume another binary resolves.

**D8 — The guard consults the hook's own mode indirection, never a literal mode path.** The snapshot routes through the hook's mode-resolving function and its `MODE_FILE` variable. A hook later given its own dedicated mode file therefore carries its coupling across with no edit to the guard. Two hooks already read their own mode file rather than the shared one and are in the cohort for exactly this reason.

**Precedence is unchanged.** The gate order remains dependency guard, then bypass, then master-activation, then workspace scope, then the mode short-circuit, then the rule. No gate moved; a function definition moved, and one gate's severity became a function of a value that was already being read a few lines later. In particular the `off` short-circuit stays after bypass and master-activation, so a mode file cannot become a pre-bypass kill switch.

## Alternatives Considered

1. **Keep the unconditional deny (the prior posture).** Rejected: it over-blocks in modes where a rule match never blocks, and the prior record itself deferred this evolution to a successor ADR rather than defending the residual indefinitely.
2. **Hoist the mode-resolving function above the guard and call it inside the failure branch.** Rejected on demonstrated failure. It relocates the circularity from definition *ordering* to definition *integrity* rather than escaping it, because the guard's condition sources the untrusted helper before the branch runs. Its only advantage over the adopted design was leaving the normal path byte-unchanged — a property with no user-visible value, traded here against a correctness property with a reproduced failure.
3. **Couple only the version-skew case; keep absent and corrupt unconditional.** More conservative, and rejected on cost rather than principle: it restructures one condition into staged checks across nine files and leaves those nine internally inconsistent with their own stated posture, for a narrowing whose benefit is bounded by the floor that still denies.
4. **Force `enforce` inside the guard when the mode file is absent.** Rejected: it creates two mode semantics inside one hook, and diverges the moment a hook is given its own mode file.
5. **Validate the helper in a subshell that must print a sentinel after its checks, then source it for real.** This is the actual fix for the residual in D5 — a self-exiting helper kills the subshell before the sentinel is printed, so the guard trips. Rejected *for this record* on scope, not on merit: it reaches into all thirteen carriers including the security floor, and needs bash-3.2 validation plus a fork-cost measurement on every tool call. Routed to the work item tracking that defect.
6. **Extract the guard into a shared library.** Rejected: a guard library cannot guard itself, and it adds a second file to the partial-install failure surface — enlarging the very population this change exists to make survivable.
7. **Fold the guard into the existing master-activation helper, which is already sourced at every call site.** Rejected on the precedent the workspace-scope library states in its own header: two guards whose "I could not read my input" branches point in opposite directions must not share a function, because the next reader will harmonize them and silently break one.
8. **Defer the guard past the action-scope short-circuit.** Structurally infeasible: action scope needs the tool name, the tool name needs `jq`, and `jq` comes from the helper being guarded.
9. **Move the bypass check above the guard, so the advertised recovery works literally.** Rejected for this release: it touches all thirteen carriers including the floor, and a working recovery already exists — a bundle reinstall from the operator's own terminal, which the hooks do not gate. Corrected in the registry documentation instead.

## Consequences

- **+** A version-skewed install no longer over-blocks in `warn`/`off`. The residual the prior record named is closed for the case that record described.
- **+** The enforce posture, the block message, the master-activation gate's position and fail-open sourcing, and the precedence chain are all unchanged. Every existing enforce-mode assertion in the test suite continues to match without edit.
- **+** The guard's verdict is now independent of the artifact the guard is adjudicating — a property the prior posture had by accident (it read no state at all) and a definition-hoist design would have lost.
- **+** Two invariants became statically asserted rather than conventionally observed, and the behavioral matrix is derived from a glob rather than a name-list.
- **+** Two hooks that guarantee the floor had no dependency-guard coverage at all and now do.
- **−** An **absent** helper still produces a total block via the always-enforce three. Named, intended, and the reason the cohort can degrade — not a partial fix.
- **−** A hook in `warn`/`off` is unprotected while the helper is broken. Bounded by the floor's deny and by the reinstall instruction carried in the notice itself.
- **−** The guard shape is now deliberately non-uniform across the carriers: the stricter detector on the nine, the older shape on the three. Recorded here so the asymmetry reads as a decision rather than as drift.
- **−** The floor's deny is narrower than "unconditional" suggests — see D5. Printed on every test run rather than left to be rediscovered.
- **−** The normal path now resolves the mode once before the guard instead of only later. On the three hooks that previously read their mode inline, the later read was replaced by the snapshot, so those are net-neutral; the rest add one read of a small file per invocation.

## Reversibility

**CHEAP · confidence HIGH.** Reverting the merge restores the unconditional deny — the *safe* direction — and the prior record becomes the governing text again, coherently. There is no security regression on revert, and no data or state migration to unwind. The only loss is the re-introduction of the over-block this record exists to remove.

## Related ADRs

- [ADR-078](ADR-078-security-hook-dependency-resolution-posture.md) — the security-hook dependency-resolution posture. **Superseded in part** (D4 only, and only for hooks with a mode surface). D2's external-dependency mode-coupling and D6's internal-primitive mode-coupling are the direct precedents this record extends to the helper source itself; D7's stricter detector is applied here to the mode-capable cohort only.
- [ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md) — the generated hook registry. The documentation changes accompanying this decision are made in the source fragments and the index regenerated, never hand-edited.
