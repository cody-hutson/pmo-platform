<!-- reference-durability: allow-link -->
---
title: ADR-116 — The ADR deciders carve-out is name-only; the account handle is never sanctioned
status: Accepted — ratified by the operator at the Stage 13 close gate for the `adr-corpus-conformance` release, 2026-08-05, shipped as v4.11. The flip is verified against this file's `status:` field, never inferred from milestone closure.
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Workspace owner (ratified at the consolidated Wave-1 gate and re-ratified at this release's Stage 13 close gate); reconciliation designed at Stage 5 Solutioning, authored at Stage 6"
tags: [architecture, adr, governance, depersonalization, public-surface, security, immutability, reversibility-moderate]
source_observations:
  - "Two shipped gates read the same carve-out incompatibly. The depersonalization gate suppressed the WHOLE deciders line on an ADR path, so an account handle written there passed; the ADR durability lint's handle rule fired on that same line. One line, two opposite verdicts, both defensible readings of the text as written."
  - "The corpus had already answered the question by action before it answered it in prose. A depersonalization-hygiene commit dated 2026-07-25 rewrote three handle-carrying deciders lines to the literal-name form, and its message states the reason as a durability handle-rule violation, citing the depersonalization spec's carve-out section. Two further lines in the same commit expanded an operator-name token to the literal name."
  - "Live probe over the governed non-record surfaces at the release baseline: every surface that STATES the rule states it name-only, and ZERO surfaces sanction the handle on a deciders line. Deriving command in the Decision section; the single apparent counter-example returned by the specificity arm was read and found to be a permitted-hygiene row describing replacement OF the handle BY the name."
  - "The one governing surface that licensed the wider reading was a rule file whose depersonalization row omitted the deciders line from its handle statement while a paragraph two below it already said the handle is never permitted — a self-contradiction inside one file, not a genuine second policy."
  - "ADR records are supersede-not-edit. A handle written into a ratified record is not removable by ordinary means, and the record ships to every downstream deployment of the platform corpus."
  - "The recommendation to close the operator-email and collaborator dimensions of the same gate with the same guard was offered at design time and DECLINED. The un-carved set therefore holds the handle only; two fixtures pin the remaining dimensions as characterization rather than endorsement."
---

# ADR-116 — The ADR deciders carve-out is name-only; the account handle is never sanctioned

## Status

**Accepted** — ratified by the operator at the Stage 13 close gate for the `adr-corpus-conformance` release, 2026-08-05, shipped as **v4.11**. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The ratification was rendered at Stage 13, not at Stage 9 as this record originally promised: no pipeline stage performs that flip, and the promise is a spec gap tracked outside this record rather than a property of this decision. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** Derived at Engineering Commit 0 against the mainline anchor per the rule recorded in [ADR-115](../../release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md): the mainline held 109, this release's earlier records took 110 and 111, so this one takes 112.

**Why this record exists at all.** The decision it states was rendered, implemented, and gated in this release — but it had **no durable home**. Its rationale lived only in stage commentary, which is not a corpus surface. This record is the one thing in the bundle that was decided and not written down.

**Numbering provenance — `112 → 116`.** Authored branch-local as **ADR-112**; renumbered to **ADR-116** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 112. In-release citations that read "ADR-112" denote this record.

## Context

The platform's depersonalization policy forbids operator identity in the governed corpus, with one carve-out: the operator's **literal name** is permitted in the `deciders:` frontmatter field of an ADR, and there only. The carve-out exists because an ADR without a decider is not a decision record — attribution is the field's entire content.

**The carve-out was under-specified in exactly the way that matters, and two shipped gates diverged on it.** One gate read "the `deciders:` line is carved out" and suppressed the **whole line**, so an account handle written there passed unflagged. The other read "the *name* is carved out" and fired on the handle. The same line drew opposite verdicts from two required gates. Reconciling them was unavoidable, and reconciling them was impossible without first answering the question the carve-out had left open: **does the carve-out permit the operator's name, or the operator's identity in whatever form the author chose to write it?**

That is not a lint-configuration question. It is a **public-surface policy** question — this repository is public, and the answer determines what identity data ships in every copy of the corpus.

**The corpus had already answered it by action.** A depersonalization-hygiene commit dated 2026-07-25 rewrote three handle-carrying `deciders:` lines to the literal-name form, giving as its reason a durability handle-rule violation and citing the depersonalization spec's carve-out section. That commit is the decisive precedent: faced with the exact ambiguity, the platform resolved it toward the name and away from the handle, and left the reason in the record. What was missing was not the decision — it was the **rationale in a durable place**, so that the next reader would not re-litigate it from the lint's behaviour.

**The one surface that appeared to license the wider reading was self-contradictory rather than a genuine second policy.** A governing rule file's depersonalization row omitted the `deciders:` line from its statement of the handle rule, while a paragraph two below it already said the handle is never permitted. That is one file disagreeing with itself, not two policies in tension.

## Decision

**The ADR `deciders:` carve-out is NAME-ONLY. It permits the operator's literal name and nothing more. The account handle is never sanctioned — on any line, `deciders:` included.**

Three consequences follow directly, and all three are now true of the shipped gates:

1. **Both gates block the handle on a `deciders:` line.** The divergence is closed by narrowing the suppression from line-scope to name-scope, not by making both gates strict — a mixed line carrying a name *and* a handle resolves to blocked, while a line carrying only the name passes both.
2. **The carve-out is a value exemption, not a line exemption.** The `deciders:` line is exempt *for one value*. Every other identity dimension on that line is governed exactly as it would be anywhere else.
3. **The rule is stated, not inferred.** A reader must be able to learn the policy from the corpus rather than from a lint's behaviour, because a lint's behaviour is evidence of what is currently enforced and not of what is intended.

**The evidence shape, stated as a derivation rather than a count** — a frozen count in an immutable record rots, and this one is checkable on demand:

```bash
# Every governed non-record surface that STATES the rule (sensitivity arm: non-zero)
git ls-files -- 'core/**' 'release/**' '.github/**' \
  | grep -vE '^(core|release)/ADRs/ADR-|^release/releases/|tests/fixtures/' \
  | tr '\n' '\0' | xargs -0 grep -lniE 'deciders' \
  | xargs grep -lniE 'literal *name|name-scoped|name-only|never the handle|no operator handle'
```

At the release baseline every such surface states the rule **name-only**, and **zero** sanction the handle. The rule this record ratifies is therefore the reconciliation of a corpus that already agreed with itself everywhere except one self-contradicting file.

## Alternatives Considered

| Option | Verdict | Why |
|---|---|---|
| **Name and handle both permitted on `deciders:`** | **Rejected** | The genuine alternative, and the one the wider gate reading would have ratified. It is rejected on the argument in the next section: the handle is an account identifier, the record carrying it is immutable, it ships to every downstream deployment, and the widening is not undoable. |
| **Handle only, no literal name** | **Rejected** | It inverts the depersonalization policy's own ordering. A handle is a live account identifier and therefore *more* sensitive on a public surface than a person's name, not less — this option maximizes exactly what the policy minimizes. |
| **Withdraw the carve-out entirely; use a role or a token** | **Rejected** | Attribution is the `deciders:` field's whole content, and the corpus previously carried an operator-name token that the 2026-07-25 commit expanded precisely because the token conveyed nothing. Withdrawing the carve-out would either empty the field or reintroduce the token. It is also a larger change than the ambiguity warrants. |
| **Leave the carve-out ambiguous and make the two gates agree by configuration** | **Rejected** | It makes the gates consistent without deciding anything, so the next reader still cannot learn the policy from the corpus — and the next gate added would diverge again from the same under-specified text. Agreement between enforcers is a *consequence* of a decided policy, not a substitute for one. |
| **NAME-ONLY** | **SELECTED** | It matches the decisive precedent, matches every governed surface that states the rule, closes the gate divergence at its cause rather than its symptom, and takes the conservative side of a one-way door. |

## The determining argument

The four candidate readings are all internally coherent. What decides between them is an **asymmetry in the cost of being wrong**, and it has four parts that compound:

1. **The handle is an account identifier, not a name.** It resolves to a live account with a profile, a history, and a contribution graph. A name identifies a person; a handle identifies a person *and* hands the reader an index into everything else that account has done.
2. **The record is immutable.** ADRs are supersede-not-edit. A handle written into a ratified record is not removed by editing it — removing it means either a superseding record (which does not unpublish the original) or a governed exception to immutability.
3. **It ships everywhere.** The corpus is distributed to every downstream deployment of the platform. A widening does not affect one repository; it affects every copy, including copies made before anyone reconsiders.
4. **A revert does not undo it.** This is the decisive part. Nearly every other decision in this release is textually reversible — the gate criterion, the pipeline sub-step, the tool, the section set. **The public-surface widening is the one cost in this bundle that `git revert` does not undo**, because the exposure happens on publication, not on merge, and history remains readable after the revert.

Where three of four factors would counsel caution on their own, the fourth removes the option of deciding it later. A reversible decision can be taken on the balance of argument; an irreversible one is taken on the conservative side unless the argument for widening is overwhelming. It is not — the wider reading buys convenience for authors who would otherwise type a name.

## Consequences

**Easier.** Two required gates now return the same verdict on the same line, so a contributor no longer has to know which gate they are arguing with. The rule is learnable from the corpus rather than inferable from tool behaviour. The self-contradicting rule file is reconciled — the narrow statement was already there, and the omission that licensed the wider reading is gone.

**Harder.** An author who writes their handle out of habit gets a blocked build rather than a silent pass. That is the intended cost, and it is cheap: the remedy is to write the name.

**The declined widening, recorded rather than implied.** The design work recommended closing two adjacent dimensions of the same gate — the operator email and collaborator names on a `deciders:` line — with the same name-scoped guard. **That recommendation was offered and declined.** The un-carved set therefore holds **the handle only**, and the other two dimensions remain whole-line-suppressed on an ADR path.

This is an **enforcement residual, not an oversight**, and the distinction is load-bearing for whoever reads this next: the residual is a scope decision that was taken deliberately, so a future reader finding it should not treat it as a bug to be quietly fixed. It is recorded in three places — a named paragraph in the depersonalization spec, a comment on the guard itself, and two test fixtures whose own prose says they are characterization rather than endorsement. Because the fixtures now *demonstrate* the gap rather than merely describing it, it is more visible than before, which is the correct direction for a residual to move.

**Not changed.** No existing ADR record's `deciders:` value is edited by this decision — the three that carried the handle were already rewritten by the 2026-07-25 precedent commit. The durability lint's handle rule is untouched: it always fired on the handle, and it was the other gate that moved. No warn-mode posture is flipped.

## Reversibility

**MODERATE / Confidence HIGH — and asymmetric, which is the point.**

**Narrowing is cheap to reverse.** Everything this record ships is text and gate configuration: a revert restores the prior suppression scope, and nothing downstream depends on the narrower reading having been in force.

**Widening would not have been.** Had the opposite decision been taken, a `git revert` would restore the *policy* but not the *exposure* — handles published into an immutable, publicly-distributed corpus stay readable in history and in every copy already taken. That asymmetry is why the conservative reading is the correct default here even though both readings were defensible, and it is recorded so that a future proposal to widen has to answer it rather than rediscover it.

**The residual is separately reversible.** Closing the operator-email and collaborator dimensions is additive to this decision and needs no supersession — it narrows the same guard further along axes this record does not govern.

## Related ADRs

- [ADR-118](ADR-118-adr-section-set-and-durability-hygiene-carve-out.md) — the ADR section set and the durability-hygiene carve-out, authored in this same release. Its permitted-hygiene list contains the row that makes the 2026-07-25 precedent commit legal on ratified records: replacing an operator handle with the sanctioned literal name changes the *rendering* of the `deciders:` fact and not the fact. This record supplies the public-surface rationale that record does not carry, and the two compose without overlap — ADR-118 governs what may be edited, this one governs what may be written.
- [ADR-115](../../release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md) — the merge-time numbering decision, also authored in this release. Cited for its reversibility contrast rather than its subject: that decision is textually reversible, this one is not, and the two together are why this bundle's reversibility posture is not uniform.
- [ADR-032](ADR-032-release-corpus-public-vs-instance-split.md) — the public-versus-instance corpus split. This record is that boundary applied to one field: the `deciders:` value is corpus content that ships, so what it may contain is a public-surface question rather than a local formatting preference.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — canonical-spec-edit-wins. Applied here: the originating ticket framed the work as a gate-agreement reconciliation, and the public-surface policy question it did not name was decided against live state at the consolidated design gate rather than by amending the ticket body.
