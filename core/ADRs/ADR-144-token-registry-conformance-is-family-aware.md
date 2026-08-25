<!-- reference-durability: allow-link -->
---
title: "ADR-144 — Token-registry conformance is family-aware: the operator-token vocabulary carries two registry contracts, not one"
status: Proposed — flips to Accepted at this release's operator gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-24
release: checks-see-whole-subject
deciders: "Stage 5 Solutioning spoke (design) + two independent adversarial design-review passes (one Blocker each) + operator (scope decisions; ADR authorization) + Stage 6 Engineering spoke (build)"
tags: [depersonalization, token-registry, conformance-gate, probe-validity, gate-efficacy, evidence-grounding, scope-declaration]
source_observations:
  - "The conformance gate declared a subject — the operator-token vocabulary — and reached 241 of 1,097 of its occurrence lines, 22 percent. It reported clean over the other 78 percent on every run, and the output was byte-indistinguishable from a genuine clean result."
  - "The gate was narrowed on five independent axes, each sufficient on its own to hide the defect that motivated it: one hardcoded prefix, one file extension, three roots, and — larger than the other four combined — one bracket delimiter. Both of its limbs carried the same hardcoded pattern, so widening either alone would have left the other blind."
  - "The delimiter axis sat outside the originally measured denominator, because that denominator was itself derived with a square-bracket matcher. The surface was in neither the numerator nor the denominator of its own reachability figure."
  - "The premise the work item and the orchestrating brief both carried — that the vocabulary is one closed set — is false. The spec declares the square family closed and the angle family open and incrementally codified, in its own words, in two different sections."
  - "Applying one uniform unregistered-means-finding rule to both families would have raised 239 findings across 17 tokens the spec itself sanctions, and would have asserted in code a closedness the spec denies."
  - "A stored baseline of tolerated tokens was designed, approved, and then withdrawn: the file gating an authoring obligation is extendable by the very change that violates the obligation, in the same diff. The acceptance criterion written for it verified the bypass rather than the rule."
  - "No growth guard for such a file exists anywhere to inherit: across the whole workflow population, base-version reads, set-differences and line-count-against-base each measured zero, against a firing control of 36 allowlist-mentioning lines in the same extraction."
  - "The cited forward-ratchet precedent ratchets only because its tolerated set is empty by construction — a fixed filename and a line marker. The name was inherited; the mechanism was not."
---

# ADR-144 — Token-registry conformance is family-aware: the operator-token vocabulary carries two registry contracts, not one

## Status

**Proposed.** Authored at Stage 6 Engineering for the `checks-see-whole-subject` release. It flips to Accepted when the operator ratifies it at the release gate; the flip is recorded in this file's `status:` field.

## Context

The platform depersonalizes operator-identity and operator-instance values behind a token vocabulary, and a deploy-time check asserts that every token in tracked corpus is registered. That check is the mechanism that would have caught a shipped defect in which a resolver stored one token variant while its writer read another — a field written empty on every first install and re-prompted forever.

It could not have caught it. The check reached roughly a fifth of the surface it declared, and reported clean over the rest.

The narrowing was not a sampling artifact. It was five structural axes, and the check's own two limbs — the registry read and the usage scan — carried the *same* hardcoded pattern, so each axis blinded both limbs at once:

**Prefix.** The pattern named one prefix literally. The registry spans four. Two registered tokens were unmatchable by construction, and the count itself had already drifted: a fourth prefix landed after the work item was written, which is the drift a hardcoded vocabulary produces by existing.

**Extension.** The scan filtered on a single trailing extension, so a template file whose name ends in that extension plus a suffix was never read — and that file was one of the two the original defect's fix had to edit.

**Root.** The scan named three roots. The tree holding the resolver that carried the wrong variant was not among them.

**Delimiter.** Both limbs matched square brackets only. The corpus also writes registered-prefix tokens in angle-bracket form, and that entire surface — larger than the other four axes combined — was unmatchable by construction. It was invisible to the original reachability measurement too, because that measurement was derived with a square-bracket matcher: the surface appeared in neither the numerator nor the denominator of the figure meant to describe it.

The obvious remedy is to widen all five axes and keep the verdict rule. **That remedy is wrong, and the spec says so in its own words.**

The vocabulary is not one set. The square-bracket family is governed by a clause declaring the relevant tables the *closed registered set*, with anything absent classified as example-data. The angle-bracket family is governed by a different clause declaring that tokens *"inherit the same resolution-rule convention even when not yet codified"*, that *"codification is incremental"*, and that only **newly authored** tokens must add a row. One family is closed; the other is open by written policy.

A uniform rule over both would raise 239 findings across 17 tokens the spec explicitly sanctions — drowning the 13 genuine ones — and would encode in the gate a closedness the governing document denies. The gate and the spec would diverge on the first run, created by the fix.

## Decision

**Conformance over this vocabulary is family-aware, and any future gate over it must be.**

The gate derives its **prefix set and both delimiter families from the registry tables at runtime**, table-scoped to the first cell of a table row, and both limbs consume one derived value — so they are structurally incapable of disagreeing. Its **file scope is the tracked file set**: no extension allowlist, no root list. A new prefix, extension, root or registry row requires no edit to the check.

The two families then take different verdicts:

- **Square-bracket family — closed, and gating.** A square token in tracked corpus whose name carries no table row is a finding, routed through the escalating emitter.
- **Angle-bracket family — open, and observed but not gated.** An un-codified angle token is sanctioned by the spec, so failing on it would fail correct work. The gate instead emits a **live-derived inventory** — corpus minus the codified table — through an emitter that is structurally non-escalating: no mode branch, no enforce path, and no reference to the issue counter anywhere in its body.

The inventory is **derived, never stored**. It reads no tolerated-set file, only the spec and the tree. This is the second half of the decision and it was reached by removing something already approved: a stored baseline of tolerated tokens was specified, then withdrawn, because a list that exempts a violation is editable by the change that commits the violation, in the same diff — so it buys the word "ratchet" and not the property. Deriving live also means the payload cannot drift from the registry, and its decline as tokens are codified is a real progress signal rather than a record of one.

The one obligation the spec's open family actually imposes — that a **newly authored** angle token carries a table row in the same change — is a property of a **diff**, not of a working tree. A deploy-time check has no diff, and this decision does not simulate one.

## Alternatives Considered

**Widen all five axes with one uniform closed-set rule.** Rejected: raises 239 findings the spec sanctions, and asserts a closedness the spec denies. It would make the gate and its governing document disagree on the first run.

**Widen four axes and defer the delimiter.** Rejected: leaves the single largest axis unreached — more occurrence lines than the other four axes combined — while reporting the check "widened".

**Widen all five and codify every un-codified angle token.** Rejected: breaches the release's declared registry non-scope, and would require inventing canonical defaults and override fields for tokens that have no consumer. Inventing a canonical value to satisfy a gate is the failure the evidence-grounding discipline exists to prevent.

**Stored ratchet baseline of tolerated tokens.** Approved, built into the design, then **rejected on adversarial review** — recorded here because the reversal is the load-bearing part. The tolerated-set file is extendable by the very change it gates; the acceptance criterion written for it asserted that a baselined token is *not* reported, which verifies the bypass rather than the rule; no growth guard exists anywhere in the platform's workflow population to constrain such a file, measured against a firing control; and the forward-ratchet precedent cited for it ratchets only because its tolerated set is empty by construction. A gate whose exemption list the violator may edit is not a ratchet. Further, any machinery strong enough to guard the list is strong enough to enforce the obligation directly, at which point the list is dead weight.

**Extract the check into a new standalone tool.** Rejected under extend-before-create: this is a predicate widening of an existing block, co-location is what keeps both limbs reading one derived source, and a net-new executable would incur an execution-allowlist row and CI wiring for no reach gained.

## Consequences

Reach is 100% of the declared subject; both delimiter families are scanned, across every tracked file. Gating coverage at ship is the square family — 644 of 1,097 occurrence lines.

**The angle family is observed, not gated, and this ADR says so rather than implying otherwise.** That sentence is the cost of the decision and it is stated plainly: at deploy time the open family is reported and never fails. This is a reduction in *claimed* enforcement, not in reach, and it replaces a gate that did not gate with an advisory that does not pretend to.

The check's declared scope is restated in the governing spec in the same change as the reach change, so the registry and the gate cannot drift apart again silently.

**The spec's same-change obligation on newly authored angle tokens carries no in-tree enforcement today, and none that any single file edit can create.** An arm at the pull-request surface — where a diff exists — would **report** such a violation and turn its check red: it is ENFORCING in that it exits non-zero. It would **not be BLOCKING**, because blocking requires the check to be registered as a required context in branch protection, and that is a repository-settings change made operator-side, outside the tree. Whether to add that arm is an open operator decision carried into Engineering; it is not in this release's change set. Without it the obligation is unenforced by machine, which is its state on the mainline today.

One clearing channel is disclosed rather than closed: administrator enforcement is off and the required-approving-review count is zero, so a direct push to the default branch presents no pull request and no pull-request gate runs at all — a property shared by every job on that workflow, including the ones that are required contexts. It is not fixable in the tree, and it is recorded rather than papered over.

Two residuals are recorded rather than closed. The exemption marker is a **line comment**, while the widened scan now reaches comment-less structured-data files where no line comment is syntactically expressible — so a legitimate token in such a file has no disposition path other than registering it. And the check ships **without a committed self-test**, in a surface where the platform has built five for sibling checks; its only falsification arm is a manual mutate-and-restore against a historical narrative comment, which a future comment cleanup would silently remove.

## Reversibility

**CHEAP.** The change is a predicate widening inside one existing block plus a scope declaration in the governing spec; the release ships as a single pull request, so a revert at commit granularity restores the prior behaviour. The committed default is warn-mode, so a wrong widening annotates rather than blocks — the blast radius of a bad call is a noisy log, not a broken deploy.

## Related ADRs

- **ADR-142** — whole-token matching is an engine-parity problem. Same release. Its corrected probe-form guidance is the standard this check's verification evidence is graded against, and the two decisions share a root: a matcher whose declared subject and actual reach had silently diverged.
