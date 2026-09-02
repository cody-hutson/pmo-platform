<!-- reference-durability: allow-link -->
---
title: "ADR-141 — The operator-instance runtime-state home is a workspace-root sibling, not a tenant of the operator's personal area"
status: Accepted
date: 2026-08-23
release: operator-instance-home-and-install-scaffold
deciders: "operator (home-class ratification; isolation-key scope; slice-9 retention) + Stage 5 Solutioning spoke (design) + independent adversarial review (Blocker) + Collective Review (scope-lock) + Stage 6 Engineering spoke (build, re-derivation)"
supersedes: ADR-096 in-part (stated store default)
tags: [operator-instance, path-resolution, workspace-layout, migration, supersession, ADR-017, ADR-046, ADR-096, runtime-state, path-leak-detector]
source_observations:
  - "The canonical default nested platform-written runtime state inside the operator's personal area, while the workspace's other non-repo members sat at the workspace root as first-class siblings. The nested member was the only one a level deeper, and it was the only one the platform wrote to on its own schedule."
  - "The nesting was never ratified. The distribution-architecture ADR fixes this content class as workspace-relative and explicitly warns against mixing derived internals into the user's content tree; it names no personal-area leaf. The leaf traces to a repository-reorganization working note, elaborated in the workspace-setup reference, and hardened into documentation from there."
  - "A full tracked-reference sweep at the release baseline returned 60 files / 159 occurrences over a 1,741-file denominator, partitioned 14 immutable / 46 live by a path-prefix rule. The surface is not a one-line default flip."
  - "The resolver carries THREE executable literals, not one: the base resolver, its explicit-workspace-root variant, and the evals-results accessor's own inline default, which is deliberately not composed on the other two. Flipping only the base strands the third."
  - "Six further executable defaults live in the FinOps subsystem, none of which sources the resolver. Their override chain is correct; the leaf literal is simply duplicated. Shipping them after the flip would leave the resolver pointing at the new home while the store silently kept writing to the old one, with no error and no failing test."
  - "The PII pre-commit guard resolves BOTH the needle file and its severity dial from the relocating base. On an un-migrated instance the flip therefore invalidates the guard's data and its escalation path in the same instant, and the guard classifies a configured instance as a fresh clone — taking the branch that cannot block at any mode. The relocation makes the guard quieter, not louder."
  - "An adversarial review found that the first-specified hardening addressed only the branch predicate and not the dial, so it would have printed a blocking message and then exited zero. It also found that any fixture asserting the intended behaviour could only place the dial where the hook still read it — the fallback rung — so the fixture would have passed while the field case failed."
  - "The install validator's workspace-layout assertion required the personal area to exist. Once the installer stopped creating it, that gate failed a healthy install; the failure was caught by an end-to-end regression that runs a real sandboxed install, not by any file-change matrix."
---

# ADR-141 — The operator-instance runtime-state home is a workspace-root sibling

## Status

**Accepted.** Authored at Engineering for the `operator-instance-home-and-install-scaffold` release, against the operator's ratification of the home class at Stage 5 and the Collective Review scope-lock.

## Context

The operator workspace holds a cloned package directory and several non-repo members. Most of those members are first-class siblings at the workspace root. One was not: the platform's own runtime-state family — hub-state, ambient-intake run-logs, the people roster, the PII needle file, evals results, the FinOps store, exemption lists and `.mode` posture files — defaulted to a leaf nested inside the operator's **personal** area.

That is backwards along the axis that actually matters. The personal area is the one part of the workspace an operator is entitled to treat as their own; it holds correspondence, notes, and working material. The runtime-state family is written and read by the platform on its own schedule and is not authored by anyone. Nesting the second inside the first made the platform a tenant of the operator's private area, and made that area read as partly platform-managed when it is not.

The placement was never decided. The distribution-architecture ADR already fixes this content class as workspace-relative and explicitly warns against mixing derived internals into the user's content tree — it names no personal-area leaf. The leaf came from a repository-reorganization working note and propagated into the workspace-setup reference, which then argued for it as a deliberate exception. A convention acquired that way is a convention nobody chose.

## Decision

**The operator-instance runtime-state family's canonical default is `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/` — a first-class sibling of the workspace's other non-repo members. The personal area is entirely operator-owned: the platform creates nothing inside it, reads nothing from it, and writes no runtime state there.**

Four things this decision deliberately does **not** change:

1. **The override seam.** The environment overrides and the `operator.toml [paths]` override fields resolve exactly as before, at the same precedence. An operator who set an explicit home is unaffected.
2. **The single-resolver invariant.** `core/deploy/lib-instance-path.sh` remains the one site that spells the leaf. Consumers call it rather than inlining a default.
3. **The out-of-tree security posture.** The home stays outside the package tree and git-ignored, so a repository commit still cannot reach it.
4. **Create-once seeding.** Provisioning remains skip-if-exists, dry-run-aware, and rollback-recorded.

**Isolation key — decided, not built.** The instance home takes no target-derived namespace segment in this release. The question of whether a future multi-target deployment needs one is recorded as settled in principle and deferred in construction; nothing in the current surface presumes a key, and no path gained a segment.

## Decision kernel (version-agnostic)

Platform-written runtime state is a peer of the operator's content, never a tenant of it. Where a path family lands is decided by **who writes it**, not by how private it is: authored content and machine-written state get separate homes even when both are operator-local and both are git-ignored.

## Supersession

- **Supersedes** the unratified nested-home convention as stated in the workspace-setup reference's private-area section and the repository-reorganization working note it derives from. That section now records the reversal rather than the convention.
- **Supersedes in part** the FinOps usage-store ADR's stated store default, which spells the retired leaf. That ADR is a historical record and is not edited; this ADR is the current authority for the default it names.
- **Does not supersede** the distribution-architecture ADR's placement decision. This decision **realigns with** it: workspace-relative placement, derived internals kept out of the user's content tree. That ADR never named the leaf this one retires.

## Alternatives Considered

| Alternative | Disposition |
|---|---|
| Move the whole personal-area family, including the operator's analysis and harness directories | Those are operator **working material**, not machine-written state — the same distinction that decided this move argues against moving them. Only the runtime-state member relocates. |
| Retarget the duplicated inline defaults in place rather than converging them | Convergence is the correct end state, but the un-converged FinOps executables resolve through a correct override chain and only duplicate the leaf. Converging them is a wider diff than this release should carry; they were flipped in lockstep and their convergence is routed to a follow-on. |
| Close the both-forms detection window in the same release | **Rejected at design, then adopted by operator decision — this is what shipped.** The reasoning against it is real and still stands: closing the window narrows the predicate, so a bare legacy-form path is no longer flagged on any consuming surface and an instance that has not migrated loses protection on that form. Both the designing spoke and the hub recommended deferring it. The operator weighed that residual risk at Stage 5 and deliberately accepted it, keeping the slice in-release. What makes the acceptance safe is not that the objection went away but that the precondition is gated elsewhere: it cannot be verified from inside the release — no gate here can see an operator's filesystem — so it converts to an **explicit operator attestation at the Stage 12 Execute gate**. If that attestation cannot be given, the slice is dropped in isolation as a single self-contained revert, and re-opening the window is a one-member addition that is safe at any time. |
| Detect the un-migrated state with a marker file written by the installer | Cleaner, but it covers a strictly smaller set: an operator who deploys the new resolver **without** running the installer never gets the marker, and that is precisely the case the guard exists to catch. |

## Migration

**Copy-first, and the delete is never a commit.** The procedure is `copy → flip → verify → delete`. Only the flip is a change to this repository. The copy and the delete are acts on the operator's filesystem.

1. **Copy** the contents of the previous home to `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/`. Copy, do not move — the originals are the rollback.
2. **Flip** — deploy this release. The resolver now returns the new home.
3. **Verify — by positive assertion, never by absence of complaint.** Confirm that the needle file resolves to an existing file at the new home carrying at least one non-comment line, and that the roster and hub-state surfaces are present. "The guard did not complain" is **not** evidence: after an un-copied flip the guard is quieter, not louder, which is the failure mode this step exists to catch.
4. **Delete** the originals only after step 3 passes.

**The needle-continuity step is the load-bearing one.** The PII pre-commit guard resolves both its needle file and its `warn|enforce|off` dial from this base. Until the copy lands, both are unreadable at the new home. This release hardens the guard so that state is loud rather than silent: an instance presenting with the new home absent and the previous home present is classified as **un-migrated rather than fresh**, takes the fail-closed branch, and reads its dial from the previous home so a deliberate `enforce` survives the move. That hardening is a migration aid, not a substitute for the copy — it makes a violation observable, it does not move any data.

**Ordering constraint.** The copy must precede deployment of this release on the instance. The commit boundary alone does not discharge the risk: merging the flip does not move an operator's data, it changes what the next deploy resolves.

**Reverse procedure.** While the originals still exist, rollback is: revert the flip, and the previous home is already populated. Once the originals are deleted, rollback requires copying the data back — the git revert alone does not restore it.

## Consequences

- The installer no longer creates the personal area at all. It never had a reason to beyond housing this family.
- The install validator's layout assertion asserts the instance home instead of the personal area. A gate that required a directory the installer had stopped creating would fail every healthy install.
- The path-leak detector recognized **both** leaf forms while the corpus was being rewritten onto the new form, and the retired form is then **dropped from the recognized set in this same release** — the migration window opens and closes inside this release rather than outliving it. Adding the new form was measured to cost zero new findings in the only gating consumer. Retiring the old one moves the other way: it narrows the predicate, so a bare legacy-form path is no longer flagged on either consuming surface. That narrowing rests on a precondition no gate in this release can observe, and it is therefore governed by an **explicit operator attestation at the Stage 12 Execute gate** — the closure ships only if that attestation is given, and is otherwise reverted in isolation, leaving the rest of the release intact.
- The resolver retains exactly one spelling of the retired leaf, in a named accessor whose sole purpose is the un-migrated detection above. It is a deliberate, greppable removal target, not residue.
- Two ADRs now state a default this decision has moved. Both are historical records and are left as written; this ADR is where the current value lives.

## Reversibility

**EXPENSIVE · confidence MEDIUM.** The repository change is a clean revert. The filesystem migration is not: once an operator deletes the originals, no git operation restores them. That asymmetry is why the delete is specified as the last step, gated on a positive verification, and is present in no commit.

## Related ADRs

- The distribution-architecture ADR — realigned with, not superseded.
- The roadmap-instance in-repo home ADR — the executed precedent for relocating one family member's canonical default across the SSOT surfaces, and the origin of the authored-content-versus-runtime-state distinction this decision applies.
- The FinOps usage-store ADR — superseded in part, on its stated store default only.
- The release-corpus public-versus-instance split ADR — its deferred corpus migration targets this family's home; sequencing was assessed and found moot, as no migration is scheduled.
