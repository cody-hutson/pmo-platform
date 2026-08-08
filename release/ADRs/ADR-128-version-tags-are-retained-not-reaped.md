<!-- reference-durability: allow-link -->
---
title: "ADR-128 — Version tags are retained, not reaped: the retention rule is homed beside the branch-deletion rule, and the recovery tool reads host policy rather than assuming it"
status: Accepted — ratified at the `hub-spoke-execution-safety` release close gate on 2026-08-08, when the operator executed the three enforcement preconditions and milestone #301 transitioned to closed (2026-08-08T17:48:12Z). Authored at Stage 6 Engineering. Ratification is recorded here because this file's `status:` field is the authority; it is never inferred from milestone closure.
date: 2026-08-06
release: hub-spoke-execution-safety
deciders: "Workspace owner — ratified at this release's close gate on 2026-08-08; the premise inversion was rendered at the Stage-4 planning gate, the placement and reaper-shape decisions were designed at Stage 5 Solutioning, adversarially reviewed at Phase A6.5, and authored at Stage 6"
tags: [architecture, release-tooling, ref-lifecycle, tag-retention, host-policy, rule-versus-enforcement, fail-closed, doctrine-home, reversibility-cheap]
source_observations:
  - "Two independent observations converged on the same reading: an uncodified no-tag-deletion policy was overriding a codified REAP disposition on a live orphan tag. Both grepped the documentation corpus for the policy text and correctly found zero hits."
  - "The premise was inverted by host state. The policy is not uncodified — it is enforced by an active repository ruleset targeting version tags with a deletion rule and a non-fast-forward rule. The grep was sound; its denominator was documentation-only, so it structurally could not observe host configuration."
  - "The ruleset carries an empty bypass-actor list and reports that the current user can never bypass it. So the codified REAP disposition is not merely discouraged — it is unexecutable by any account, the repository owner included."
  - "The ruleset's creation date is the date this repository went public. The control was stood up as part of public-flip hardening and was never authored as corpus text, which is precisely why no corpus search could find it."
  - "The blast radius is wider than the runbook the observations named. Two rollback procedures put a remote tag deletion at step five of an eight-step sequence, and one of them additionally asserts in durable prose that the tag can be deleted and grades that deletion cheap. Both claims are false, and both fire mid-rollback under time pressure."
  - "The recovery tool is not naively broken. Its refusal classifier correctly matches a host rule-violation rejection and correctly rejects a transport failure, so it degrades safely. What it does is demand a destructive-action double opt-in in order to receive a refusal that was knowable in advance without any network call."
  - "An adversarial reviewer established that the redundancy of the specific orphan tag is symmetric evidence: no information to recover and no ambiguity to resolve is exactly the condition under which deletion is safe. A general rule justified by a fact that argues both ways is how an over-broad rule enters a corpus."
---

# ADR-128 — Version tags are retained, not reaped: the retention rule is homed beside the branch-deletion rule, and the recovery tool reads host policy rather than assuming it

## Status

**Accepted** — authored at Stage 6 Engineering for the `hub-spoke-execution-safety` release, per the Stage-6 ADR-authoring precedent. It was ratified at that release's close gate on 2026-08-08, when the operator executed the three enforcement preconditions and milestone #301 transitioned to closed; the release shipped as **v4.18**. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** Allocated as the next free slot over the union of both ADR directories, which are a single numbering space, verified with the corpus checker and cross-checked against every branch on the remote rather than by reading the highest filename. The number is allocated at authorship and bound at merge; if a sibling merges ahead of this record, the reconciliation is tooled and this Status block will carry the provenance note.

**Numbering provenance — `120 → 121`.** Held **ADR-120** branch-local; renumbered to **ADR-121** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 120. In-release citations that read "ADR-120" denote this record.

**Numbering provenance — `121 → 123`.** Held **ADR-121** branch-local; renumbered to **ADR-123** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 121. In-release citations that read "ADR-121" denote this record.

**Numbering provenance — `123 → 127`.** Held **ADR-123** branch-local; renumbered to **ADR-127** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 123. In-release citations that read "ADR-123" denote this record.

**Numbering provenance — `127 → 128`.** Held **ADR-127** branch-local; renumbered to **ADR-128** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 127. In-release citations that read "ADR-127" denote this record.

## Context

The work item behind this record was filed as a governance contradiction: an **uncodified** no-tag-deletion practice appeared to be overriding a **codified** REAP disposition in the re-version recovery runbook, on a live orphan tag that was the recovery tooling's only real payload in the ledger's entire history. Two observations reached that reading independently, and both grounded it the same way — a search across the documentation corpus for the policy text, returning zero hits outside the ledger row that asserted it.

**The premise is inverted, and the inversion is the whole point of this record.** The practice is not uncodified. It is enforced at the repository host by an active ruleset that targets tags, matches the version-tag ref pattern, and carries a `deletion` rule and a `non_fast_forward` rule. Its bypass-actor list is empty and it reports that the current user can never bypass it, so **no account can delete a version tag on the remote — the repository owner included.** The ruleset was created on the day this repository went public, as part of public-flip hardening. It was never authored as corpus text, which is exactly why a corpus search could not find it: the search was sound, and its denominator could not see host configuration.

That reframes the defect from the one filed into a materially better one. The runbook does not lose an argument to an unwritten rule; **it prescribes an operation the repository actively rejects.** A runbook step that cannot execute is a worse thing to ship than a policy conflict, and its remedy is unambiguous.

Three further facts shape the decision, and each moves it somewhere the filed card did not point.

**The blast radius is not the runbook.** The recovery runbook is the surface the observations named, and it is the least urgent of them. Two *rollback* procedures — one of them in the cross-cutting disciplines tier, which the other cites as its authority — put a remote tag deletion at **step five of an eight-step rollback**, invoked under time pressure after a bad release, by an agent operating under operator authorization. It will run four steps, hit step five, and be rejected, with no instruction for what comes next. One of the two additionally asserts in durable prose that the tag *can* be deleted and grades that deletion **CHEAP**. Both halves are false, and a false factual claim in durable corpus is the kind that gets copied forward.

**The tool is not naively broken, so "delete the reap path" is the wrong remedy shape.** The recovery tool's refusal classifier correctly matches a host rule-violation rejection and correctly declines to match a transport failure; on refusal it writes no state and leaves the tag intact. There is no correctness defect and no data-loss risk. What there *is* is an **affordance** defect: the runbook instructs the operator to clear a double opt-in — a gate justified as guarding a destructive, moderately-reversible action — in order to receive a refusal that was knowable in advance without any network call. Training an operator to clear a destructive-action gate for a guaranteed no-op erodes that gate everywhere it is used, including on the branch-delete path that shares the machinery.

**The redundancy of the motivating tag argues both ways, and must not carry the rule.** The specific orphan is a duplicate annotated tag of its predecessor — same target commit, same tag message, cut under a minute later by a repeat invocation of the claim tool — so it points at no distinct content. That makes retaining it costless. It also makes *deleting* it costless: "no information to recover and no ambiguity to resolve" is precisely the condition under which deletion is safe. It is symmetric evidence and settles nothing. The deliverable here is **general doctrine**, and a general rule justified partly by a fact that argues both ways is how an over-broad rule enters a corpus. The host control settles the disposition on its own, and it is sufficient.

## Decision

**(1) The retention rule is homed in the git-workflow rule, beside the branch-deletion rule — extended, not created.**

A new `## Tag Retention` section in `core/rules/git-workflow.md` owns the fact and the rule; the recovery runbook, the autonomous-execution rollback pattern, and the partial-deployment recovery standard **cite it and never restate it**.

The decisive argument is the risk this rule most needs to avoid, turned into the mechanism that avoids it. A blanket *"we never delete refs"* would be **false** — that same file deletes merged branches by design, locally and on the remote, as a numbered step of its own PR process. Putting tag-retention in the same file as the branch-deletion rule makes the **ref-class asymmetry self-documenting**: a reader who opens the file to change how refs are removed meets both rules in the same place. The citation itself runs one way — this section points at the branch-deletion step, not the reverse — so the adjacency, not a reciprocal cross-reference, is what does the work. Two adjacent rules in one file beat two rules in two files that never meet. The asymmetry itself is stated as a reason, not an exception — a branch is working state expected to disappear once merged, whereas a version tag is the atomically claimed record that a version resolved to a commit.

The placement also reaches where a release-scoped home cannot. The worst dead path is in the cross-cutting disciplines tier; doctrine homed in a release how-to cannot govern it without inverting authority. And an agent executing a rollback never opens the re-version runbook — the two procedures share no entry point.

**(2) The R-1 disposition becomes RETAIN AND RECORD, and the hook-blocked handoff is deleted rather than reworded.**

The runbook's step-two reap procedure becomes detection-only; its step-four verification **inverts** — the end state asserts the tag is *present* and its ledger row reads `tag-retained`, and an absent tag is a verification **failure**, not a success.

The hook-blocked user-side handoff is **deleted**, and the reason is worth recording because the section previously looked sound. That convention requires a **user-side equivalent that works**; here none exists, because the blocker is the host ruleset rather than a local hook, and it rejects the push for every account. The section's closing claim — that a plain non-force remote tag delete is permitted by the local destructive-action hook — is *true of the local hook and irrelevant to the host*. **Conflating a permissive local hook with an unread host policy is the root cause of the whole defect**, and the replacement text names the two mechanisms separately so the conflation cannot recur.

**(3) The tool READS host policy, in three states, and indeterminacy fails CLOSED.**

A preflight resolves, per tag, one of `protected` / `unprotected` / `undetermined`, and each maps to a distinct outcome:

- **protected** — classify RETAINED, transition the ledger row to `tag-retained`, issue no push, and **do not require the double opt-in**, because nothing destructive is attempted;
- **unprotected** — the pre-existing reap path, unchanged, still behind `--apply --force`;
- **undetermined** — attempt nothing, transition nothing, and name the reason.

**The third state is the decision.** A two-state preflight has to fold indeterminacy into one of the other two, and folding it into `unprotected` — failing open — would drop through to the reap path's "double opt-in required; tag delete is moderately reversible" message on exactly the credential class that cannot read host policy: a non-owner would get the pre-fix experience *plus* a wasted call, and be told a deletion is moderately reversible on a repository where it cannot execute at all. **A preflight that fails open into the defect it fixes is not a fix.**

Failing closed costs nothing on a genuinely unprotected deployment, because two arms preserve the capability without a host query. A remote that is **not a policy-bearing host** — a local path, or any non-host URL — resolves `unprotected` *determinately*, since no such ruleset can exist there; no network call is made. And an operator who knows their deployment carries no tag protection asserts it with an explicit flag, the same shape the tool already uses for naming an abandoned tag: state the authority the tool refuses to infer.

That first arm is also why the existing self-test suite survives intact. The reap fixtures push to a local bare-directory remote, so they take the determinately-unprotected arm **on its merits, not by an exemption**. Two new cases cover the new branches, and both are negative-control-verified: reintroducing the fail-open defect makes the undetermined case fail, including on the assertion that the tag was deleted under force.

**(4) The rule is host-conditional, and says so once, in one place.**

Doctrine that says a version tag is *never* reaped, shipped beside a tool that retains a working reap path, would recreate this record's own thesis in the opposite direction — a codified rule overridden by a shipped tool. So the rule states its own discriminator: where tag protection is configured the reap path is unreachable and the tooling reports the tag retained; where it is **provably** not configured, reaping is an operator-gated exception to the rule rather than the default; where host policy cannot be read, nothing is attempted. A reader who finds tool and rule apparently disagreeing resolves it at the rule — the tool reads the host, the rule states the intent. One authority, one discriminator, no second opinion.

**(5) The ledger's disposition enum gains a terminal `tag-retained`; only the canonical row is corrected.**

`tag-orphaned` remains the producer's honest **detection** state, and `tag-reaped` remains in the enum, reachable on a deployment whose host does not protect tags. `tag-retained` is a **consumer transition** — the mutation class the ledger's schema already sanctions — and it de-authorizes the row for any future attempt by construction, because the tool selects only on `tag-orphaned`.

Exactly **one** row is corrected: the orphan's own. The sibling rows of that re-version event carry the same residual text, and a sweep to remove the stale phrase from all of them would have been wrong. `residual_labels` is **event-scoped in practice — every multi-row event in the ledger carries identical text across its rows, several naming a version other than the row's own.** Rewriting the siblings would have made that event the only divergent one, destroyed the linkage between the orphan and the claim cascade that produced it, and spent an immutability exemption on three edits that were never needed. The convention is now stated in the schema block so the next reader does not "fix" it.

## Alternatives Considered

**Home the rule in the recovery runbook (rejected — wrong authority direction).** Doctrine homed in a release how-to cannot govern a cross-cutting discipline, and an agent mid-rollback never opens the re-version runbook. It would leave the two worst dead paths unreached.

**A new dedicated ref-retention file (rejected — extend before create).** The git-workflow rule already governs ref lifecycle and already documents host-enforced controls together with their enforcement mechanism. A net-new file duplicates that role, adds a deploy target and two lint targets, gains no capability, and — decisively — *loses* the adjacency that makes the branch/tag asymmetry visible.

**Home it in the release-governance protocol or the ledger's schema block (rejected — under-reach).** The ruleset covers every version tag, and the worst dead path is in the disciplines tier; neither surface can bind it. A machine-readable ledger's schema comment is also not where an agent mid-rollback looks.

**Split the fact from the disposition across two files (rejected — two homes for one fact).** They would drift.

**Remove the tool's tag arm entirely (rejected on three grounds).** The ruleset is *this repository's configuration*, not a property of git or of the platform, so deleting the arm bakes one deployment's host config into a portable tool. The arm carries three capabilities unrelated to reaping — orphan detection, the canonical-version guard, and the stale-version-row detector — all of which stay valuable. And it discards a nine-case test suite to remove code that already behaves correctly.

**Leave the tool alone and only fix the runbook (rejected — leaves the affordance defect).** Cheapest and defensible, but it keeps a destructive-action double opt-in standing in front of a guaranteed no-op, and that gate is shared machinery with the branch-delete path.

**Drop the double opt-in from the tag arm without a host query (rejected — removes a real guard where the deletion is real).** This was raised at adversarial review as the leanest counter-design, and its own honest cost disqualifies it: on an unprotected deployment, dropping the opt-in removes a genuine guard in front of a genuine deletion. The preflight keeps the opt-in exactly where a deletion can actually happen and drops it exactly where nothing is attempted, which is the better trade on the dimension the counter-design itself named.

**Delete the tag (rejected — and out of authorization).** It would require first amending or disabling an active ruleset on a public repository in order to perform an irreversible deletion, then restoring it. That is an operator decision taken outside any release procedure. Retention is also the right answer on the merits for this instance, though — per the Context above — that merit argument is deliberately **not** load-bearing for the general rule.

## Consequences

**Positive.** A runbook step that could never execute is gone. Two rollback procedures no longer strand an agent mid-recovery, and a false "can be deleted, cheap" claim leaves durable corpus. The retention fact has one home, cited by three surfaces, so it changes in one place. An operator on the canonical repository is told the outcome up front instead of clearing a destructive-action gate to learn it. And the destructive-action double opt-in stops being spent on a guaranteed no-op, which preserves its meaning where it still guards something.

**Negative, and named.** The tool gains a dependency on an external host CLI inside a release-close path; the preflight is honestly graded *conditional on a policy-bearing host and a policy-readable credential*, not portable without qualification. A credential that cannot read host policy now gets a refusal where it previously got a rejection — better information, but still not a completed operation. And the enum gains persisted vocabulary: adding `tag-retained` is CHEAP, but **removing** it once rows carry it is not, because the value is consumed by the ledger and by the tool's row selector. That asymmetry is the honest grade and is why the value is documented as terminal rather than transitional.

**Residual risk, not closed here.** Nothing in the corpus asserts the ruleset's continued existence, so the doctrine and the host can silently diverge. The preflight detects the change automatically and falls through to the reap path, and the rule/enforcement split means the doctrine remains true either way — but a deploy-check or CI assertion that an active tag-deletion rule covers version tags would close the gap properly. That is a follow-on intake item, deliberately out of this release's scope.

## Reversibility

**CHEAP · confidence HIGH** for the doctrine text, the runbook reconciliation, the two rollback corrections, and the tool's preflight branch — all are plain forward edits reverted by reverting the merge, and no host state, tag, or deployed artifact is mutated by any of them.

**MODERATE · confidence HIGH** for the enum extension specifically, once ledger rows carry `tag-retained`: reverting the vocabulary after rows adopt it orphans those rows against a reader that no longer knows the value. The two tiers are recorded separately rather than averaged, because averaging them would understate the one that actually binds.

**No tag is deleted by this decision or by the release that carries it**, and the release's verification treats a disappeared version tag as a failing outcome rather than a successful one.

## Related ADRs

- The atomic version-claim decision that establishes the tag as the authoritative, compare-and-swap-claimed version surface — the property this record's rationale rests on.
- The slug-primary release-identity decision that removes the version stem from branch and plan-file names, leaving the tag as the single place a version binds.
