<!-- reference-durability: allow-link -->
---
title: "ADR-191 — A conduct-class hook is owned by its discipline and takes no readiness shard"
status: Proposed (authored at Stage 5 Solutioning; operator-rendered as decision D-SHARD option (a) at the Stage-5 Decision Briefing; ratification flip at the release's Stage-13 close)
date: 2026-09-05
release: external-seam-conduct-binds
deciders: Stage 5 Solutioning spoke (four-candidate design exploration on registry membership) + independent adversarial review (which attacked and confirmed the central premise) + operator decision D-SHARD + Stage 6 Engineering
tags: [hooks, bypass-mode-readiness, hook-registry, conduct-discipline, external-seam, ownership, ADR-030]
source_observations:
  - "The card's acceptance criteria asked for a per-hook readiness shard AND a hook-owner line naming the new discipline. The readiness check classifies a hook as bypass-mode IFF its declared owner is its own shard, so the two requirements are not independent and cannot both be satisfied."
  - "The check's reverse arm iterates the shard set and flags any shard whose backing script does not declare it as owner. Shipping both a shard and a discipline owner therefore produces a finding, while the acceptance criteria separately require a clean check."
  - "The registry's own header scopes its membership to security invariants that make it safe to run the agent in a no-prompt mode. The hook under design enforces a conduct rule about the shape of a human-facing comment, which is not that class."
  - "Several block-prefixed hooks already ship owned by a discipline or standard document rather than by a shard, so the standalone-ownership pattern is shipped rather than hypothetical."
  - "Two independent measurements of the standalone-hook population disagreed with each other and with the registry's own hand-maintained enumeration, in the output of agents reading that enumeration. The decision was re-grounded on the check's derivation predicate rather than on any tally."
supersedes: none
---

# ADR-191 — A conduct-class hook is owned by its discipline and takes no readiness shard

## Status

**Proposed** — authored at Stage 5 Solutioning and rendered by the operator as decision **D-SHARD, option (a)**, at the Stage-5 Decision Briefing. It flips to Accepted at the release's Stage-13 close per the ratification gate; the file's own `status:` field is the authority for whether that flip has landed, not a green close-out check.

**Numbering provenance.** This record was authored at the next free number, which is the mainline anchor plus one. A claim visible only on a branch is detection-only and never binds. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations use the slug token `{{ADR:external-seam-hook-owned-by-its-discipline}}`, which carries no number shape and resolves at the claim.

## Context

The platform's `PreToolUse` hook layer has two ownership shapes, and until this release the difference between them had never been forced into the open.

A hook can be a **member of the bypass-mode readiness registry**: it carries a per-hook source fragment under that registry's fragment directory, the fragment is its declared owner, and the generated index carries a row for it. Or it can be **registry-external**: it declares some other document — a rule, a standard, a discipline — as its owner, ships no fragment, and is documented wherever that owner lives.

Membership is not a label anyone assigns. It is **derived**: the completeness check classifies a hook as bypass-mode **if and only if** its declared owner is its own per-hook fragment. A reverse arm then iterates the fragment set and flags any fragment whose backing script does not declare it as owner.

This release adds a hook that enforces a **conduct** discipline — the shape of an agent's write to a human-facing external seam. Its card asked for two things at once: a per-hook readiness shard, **and** a `# hook-owner:` line naming the new discipline. Those are not independent requirements. Declaring the discipline as owner makes the hook non-bypass by derivation, at which point the shard maps back to no declaring script and surfaces as a finding — against a card that separately requires a clean check.

The brief was unsatisfiable, and the design's job was to say so rather than silently pick a limb.

## Decision

**A hook that enforces a conduct discipline declares that discipline as its `# hook-owner:` and ships no per-hook readiness shard.** The bypass-mode registry stays scoped to the security invariants its own header names.

The shard's *intent* — a discoverable field table and rule registry for the hook — is satisfied by an equivalent block **inside the owning discipline**, which is already how every existing registry-external hook is documented. A reader who finds the hook finds its owner in the hook's own header line; a reader who finds the discipline finds the hook's field table and rule registry in it.

Three consequences follow directly and are stated so a later reader does not have to re-derive them:

1. **Registry membership does not change.** A registry-external hook does not join the security set, so no membership count in the registry's fragments moves.
2. **The registry's fragment enumeration of registry-external hooks *does* change**, and so does any cohort list the new hook joins — its master-activation class, and the own-mode-file list if it carries its own mode file. Those are the cascade surfaces, and the generated index must be regenerated in the same change.
3. **Ownership sits with the document that defines the rule.** A hook whose owner is a shard inside a registry it does not belong to is owned by a document that does not state the rule it enforces.

## Alternatives Considered

| Option | Disposition | Reason |
|---|---|---|
| Make the hook a registry member, owned by its own shard | **Rejected** | It forces the owner to be the shard, contradicting the card's own `# hook-owner:` requirement and making the discipline a non-owner of its own enforcement. It also places a conduct rule inside a registry whose membership predicate is no-prompt-mode safety. |
| Make it a registry member **and** re-scope the registry's charter from security to security-plus-conduct | **Rejected** | The honest version of the option above, and more expensive: it cascades every membership count in the registry's fragments and rewrites the registry's charter — a governance change made as a side effect of adding one hook. |
| Ship a literal shard **and** accept the resulting finding | **Rejected** | The check is advisory today, so the finding would report rather than fail — but the card requires a clean check, and shipping a known finding to satisfy the letter of an acceptance criterion is paperwork over substance. It also becomes a hard failure the moment the operator flips the check cohort to enforce. |
| Ship no hook at all | **Rejected** | An acceptance criterion mandates one. It survives only as the rollback target. |

## Consequences

**Positive.** Ownership and definition are the same document, so a rule and its enforcement cannot drift apart. Every future conduct-class hook takes this path with zero edits to any shared registry file — which is the property the drop-in registry design was built for. The registry's charter stays one sentence.

**Negative, and stated plainly.** The generated index carries no row for a registry-external hook, so a reader who treats that index as the complete hook inventory will under-count. That is a pre-existing property of every registry-external hook, not one this record introduces, and the registry's own header states the scoping — but this record adds another instance of it.

**A second negative, which is the one worth watching.** The registry's enumeration of registry-external hooks is **hand-maintained**, while membership itself is derived. That asymmetry has now mis-cascaded more than once, including in the output of agents reading the enumeration in order to update it. The enumeration is exactly derivable — a hook is registry-external precisely when its declared owner does not resolve under the fragment directory — and replacing it with a derivation pointer would end the cascade permanently. This record does not do that; it names it as the follow-on the pattern argues for.

## Reversibility

**CHEAP · confidence HIGH.** Reversing means one edit to the hook's owner line plus adding a fragment, and re-running the index generator. Nothing downstream binds to the choice: no path, no rule ID, and no test depends on where the hook is documented. The rejected re-scoping option is the expensive one precisely because it is not reversible this way — it would have to be un-cascaded across every membership count and the registry's charter.

## Related ADRs

- The drop-in hook-registry record — establishes the generated index, the per-hook fragment convention, and the derivation that makes membership a property of declared ownership rather than of a hand-maintained list. This record is a direct consequence of that derivation being load-bearing.
