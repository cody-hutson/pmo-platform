---
title: "ADR-104 — Complementary reference pairs are registered in a dedicated allowlist registry, and the canonical copy ships into the package at its repo-relative path"
status: Proposed — to be ratified at the operator's Stage 9 plan-review gate for the check-enforcement-fidelity release. The flip to Accepted is verified against this file's `status:` field, never assumed from milestone closure.
date: 2026-07-30
release: check-enforcement-fidelity (version bound at Stage 12)
deciders: "operator (Stage 5 Collective Review decision gate + the Phase A6.5 decision record) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 independent adversarial design reviewer"
tags: [duplicate-source-discipline, complementary-reference-pair, skill-packaging, deploy-checks, registry, single-source-of-truth, extend-before-create, fail-closed]
source_observations:
  - "The drift check that discovers same-basename duplicates scans skill-local references/ trees only — its population glob matches paths under a skills directory's references/ subtree, so a canonical schema under the shared schema tree is not in the scanned population at all. A canonical/skill-local pair is therefore invisible to the one check whose job is to find exactly that shape, and its invisibility is structural rather than an allowlist decision."
  - "Registering the pair in the byte-identity template-sync registry would assert the opposite of the declared relationship, and would also make the pair MORE invisible rather than less: the drift check's registration test exempts by basename, so any registration of that basename makes the check skip it entirely. The obvious reuse is not merely inferior here — it regresses the very visibility the work exists to create."
  - "The packager already extracts the template-sync map out of the deploy script at runtime rather than holding its own copy. The header of the helper that does so records the drift incident that produced the rule: a prior release registered a reference in one copy of a duplicated array and not the other, and the package rebuild errored at release-cut. Any design that re-creates a second copy of a shared registry re-opens that class."
  - "The two builders that stage a skill for packaging — the packager's per-skill build and the deploy script's staging build that the freshness check hashes against — are kept aligned only by a prose comment declaring them byte-aligned. Recomputing the content manifest with and without a hand-injected member at authoring produced two different hashes, which is the mechanism by which a one-sided injection would make the package permanently stale and unfixable by rebuilding."
  - "Two of the four trackers that both copies of the pair define had already diverged in field content at authoring — one copy carrying fields the other does not — while the pair's own consuming skill resolves a conflict by preferring whichever copy defines the tracker. A registry that can express only exclusive ownership cannot describe that region, and listing those trackers as exclusively owned by either copy would flip a live, currently-passing pair to FAIL."
  - "The packager's registry-driven injection loop iterates the record set and returns success on an empty iteration, so an absent registry file yields a silent no-op; the drift check reading the same file fails closed. One deleted file would therefore disable the fix and its detector together — a fail-open shipped by a release whose theme is instruments that cannot fire."
---
<!-- reference-durability: allow-link -->

# ADR-104 — Complementary reference pairs are registered in a dedicated allowlist registry, and the canonical copy ships into the package at its repo-relative path

## Status

Proposed — to be ratified at the operator's Stage 9 plan-review gate for the check-enforcement-fidelity release. The flip to Accepted is verified against this file's `status:` field, never assumed from milestone closure.

This record covers **two decisions that are one decision**: the registration mechanism for a complementary reference pair, and how a registered pair resolves into a shipped skill package. The second consumes the registry the first creates, and the first's ownership fields exist to serve the second, so splitting them into two records would separate a schema from its only reason for having that shape.

**Scope note — what this record does not cover.** The same release also widens the gate-efficacy standard's scope boundary to admit prose-declared normative predicates as a third governed gate class. That decision was tested against the ADR threshold at Solutioning and recorded as **below it** — CHEAP reversibility, HIGH confidence, and no cross-cutting governance surface in the threshold's named set — so it is documented inline in its own design output rather than here. It is named in this note so a future reader can see the disposition was reasoned rather than overlooked.

## Context

The platform's duplicate-source discipline gives a same-basename pair exactly three dispositions: register it as a byte-identical mirror and gain drift enforcement, consolidate it to one canonical source with cross-references, or record a per-domain exemption with rationale. A **complementary** pair fits none of them.

The live instance is a schema document that exists twice — once as the canonical schema in the shared schema tree, once as a skill-local reference beside the skill that consumes it. The two copies are **not** duplicates and are not meant to converge: the canonical copy defines the full tracker set, the skill-local copy defines a body of integrity rules the canonical copy does not carry, and the consuming skill's own resolution rule tells a reader to prefer whichever copy defines the tracker in question. Consolidation would delete a real division of labour; mirror registration would assert byte-identity the corpus explicitly denies; an exemption would record only that the pair is allowed, not what each copy owns — which is the fact every consumer actually needs.

**The forces:**

- **The pair is structurally invisible to the check that should see it.** The drift check that discovers same-basename duplicates scans skill-local reference trees only. The canonical tree is not in its scanned population, so the pair cannot be surfaced by widening an allowlist — the population itself has to change.
- **The obvious reuse regresses the goal.** Registering the pair in the byte-identity template-sync registry would assert the opposite of the declared relationship *and* make the pair less visible, because the drift check's registration test exempts by **basename**: registering that basename makes the check skip it entirely.
- **Whatever declares the ownership has a second consumer.** The packager needs the same declaration — to know which canonical to inject, or which sections to vendor. A registry that lives as an array inside the deploy script would force the packager to extract a bash array out of another script at runtime, which is the idiom whose own helper header records the drift incident that produced the rule against it.
- **A deployed skill is currently making citations it cannot resolve.** The shipped package carries only the skill-local copy, while the skill's instructions cite the canonical path. Inside the package those citations resolve to nothing, so the skill blocks writes it should permit.
- **The two package-staging paths are held in agreement by a comment.** The packager's per-skill build and the deploy script's staging build — the one the always-enforce freshness check hashes against — are declared byte-aligned in prose and enforced by nothing. A change applied to one and not the other makes the staged hash and the committed sidecar disagree *by construction*.

## Decision

**1. A fourth disposition — the registered complementary pair.** The duplicate-source discipline gains a fourth condition alongside mirror-registration, consolidation, and exemption: a same-basename pair spanning the canonical corpus and a skill-local reference tree may be **registered as complementary**, when and only when its division of labour is declared as **machine-checkable section ownership**. Prose asserting that two copies are complementary is not sufficient; the claim has to be a thing a check can read.

**2. The declaration lives in its own registry file under the deploy allowlists directory**, one record per pair, field-separated by a multi-character delimiter, read **directly** by every consumer. The multi-character separator is forced rather than chosen: section-anchor fields legitimately contain a colon-space sequence, so any single-character or whitespace separator would split a real anchor. The registry is a single source read by both of its consumers; neither consumer holds a second copy of it.

**3. The record declares three ownership regions, not two.** Alongside the sections each copy owns **exclusively**, the record carries a third field naming the sections the two copies **share**. This field is not optional cleanliness: two of the shared trackers had already diverged in field content at authoring, and a schema able to express only exclusive ownership cannot describe that region — listing those sections as exclusively owned by either copy would flip a live, currently-passing pair to FAIL. The shared field is what makes the only real drift surface visible instead of unrepresentable.

**4. Package resolution ships the canonical, rather than vendoring sections out of it.** A registered pair resolves into the shipped skill package by copying the canonical file into the package **at its repo-relative path**. This is the operation the packager already performs for template-sync entries, so it introduces no new operation class; and because the canonical lands at the path the skill's instructions already cite, those citations resolve verbatim with **no edit to the skill's instruction text**.

**5. The injection is expressed as a template-sync-map entry, never as a hand-coded injection into one builder.** The packager extracts that map from the deploy script at runtime, so a map entry is consumed by **both** staging paths from one source and the two stay aligned by construction. A hand-coded injection into the packager alone would leave the deploy script's staging build — the one the freshness check hashes against — un-injected, making the package permanently stale and unfixable by rebuilding. The live residual this substitutes in is narrower and checkable: the template-sync source resolver matches on **basename**, and this basename exists at two paths, so the resolver's disambiguation must be verified rather than assumed.

**6. The packager fails closed on a missing or unreadable registry.** Its record loop returns success on an empty iteration, so an absent file would otherwise be a silent no-op while the drift check reading the same file fails closed — one deleted file disabling the fix and its detector together. Absence is an error at both consumers.

**The extend-before-create determination, recorded as the gate requires:** *net-new registry file because in-place registration is infeasible — the byte-identity registry's membership semantics assert the opposite of this pair's declared relationship and its basename-scoped exemption would reduce rather than increase the pair's visibility; the skill catalog is keyed by skill name rather than by a path pair and declines by its own charter to store an axis with another home; and a frontmatter-based self-declaration would introduce a corpus-wide contract collision with an enforced document-frontmatter standard for a governed population of one.*

## Alternatives Considered

**Registration mechanism (the first decision).** Five candidates were generated across the extend-seam and new-abstraction bands, and three were eliminated on hard-constraint breach rather than on score:

| Candidate | Disposition |
|---|---|
| An inline tuple array declared in the deploy script, read by the drift check | **Viable but not selected.** Narrowest surface — one file — and it mirrors an existing in-script tuple registry. Rejected on the second consumer: the packager would have to extract a bash array out of another script at runtime, which is the exact idiom whose helper header records the drift incident that produced the rule against it. Re-opening that class to save one file is a bad trade. |
| **A dedicated registry file under the deploy allowlists directory** | **SELECTED.** Mirrors the established allowlist convention, and there is an exact in-repo precedent for a single allowlist file read directly by two independent consumers, whose header states the governing principle verbatim — a second copy would be a shadow source of truth that could drift silently. |
| Self-describing frontmatter in each copy, with the checker discovering pairs by scanning | **Eliminated — blast-radius ceiling.** A new corpus-wide frontmatter contract collides with the enforced platform document-frontmatter standard and its exemption allowlist. A structural-tier solution for a governed population of one. |
| Registering the pair in the existing byte-identity template-sync registry | **Eliminated — triple breach.** Membership in that registry *means* byte-identity, which the corpus explicitly denies for this pair; the drift check's registration test exempts by basename, so registering it would make the pair **more** invisible and regress the visibility criterion; and its tuple carries no field for section ownership, making the ownership criterion unsatisfiable by construction. |
| Extending the skill catalog with a reference-pair column | **Eliminated — governance conformance.** The catalog's own charter declines to store any axis that has another home, and its key is a skill name rather than a canonical-to-skill-local path pair. Per-section ownership lists in a catalog cell would make it the second registry the catalog ADR forbids. |

**Package resolution (the second decision).** Two options, decided by the operator at Collective Review:

- **Option A — ship the canonical into the package (SELECTED).** It is the operation the packager already performs; it requires zero edits to the skill's instruction text because the existing citations resolve verbatim at the repo-relative path; and it preserves the invariant that a package member is byte-equal to a source file, which both the package-integrity check and the freshness hash rest on.
- **Option B — vendor the needed sections at build time (REJECTED).** It introduces an operation class the packager has never performed (build-time content synthesis); it requires restating the citations a prior release had just repaired; and a synthesized member is by definition not byte-equal to any source file, which breaks the invariant above. **The honest case for it, weighed and set aside:** Option A ships the overlapping sections twice inside one package and introduces a top-level directory no other package carries. The operator weighed that cost explicitly and accepted it.

**A counter-design was raised and not adopted:** under Option A, delete the overlapping trackers from the skill-local copy so the registry becomes a true partition needing no shared field. It resolves the divergence at the root rather than describing it, and it is available only because Option A was chosen — but it deletes a substantial body of a skill-local reference, touches consumers outside the change matrix, and would falsify prose elsewhere describing that copy's contents. The shared-field schema is the minimal resolution; the deletion remains available as a follow-up.

## Consequences

**Positive.**

- A complementary pair becomes a **declared, machine-checkable** relationship rather than a prose claim. What each copy owns is readable by a check, not inferred by a reader.
- The pair's only genuine drift surface — the region both copies define — becomes representable, and therefore auditable, for the first time.
- The deployed skill's canonical citations resolve inside the shipped package, so writes it was blocking are unblocked without editing a single citation.
- The registry is a single source read by both consumers, so the drift class that a duplicated in-script array previously produced is not re-opened.
- Both package-staging paths consume the injection from one source, so the byte-alignment invariant between them is enforced by construction rather than asserted in a comment.
- Both consumers fail closed on an absent registry, so the fix and its detector cannot be disabled together by one deletion.

**Negative, stated rather than implied.**

- **A further registry surface.** The deploy tooling gains another registry alongside the byte-identity map, the schema map, and the existing allowlist family. The kill-reasons above justify it, but the surface area is real.
- **The overlapping sections ship twice inside one package.** This is Option A's accepted cost. It is bounded to the registered pair and does not generalize.
- **A top-level directory appears inside a skill package that no other package carries.** The packager's validators were read and constrain no directory, so this validates cleanly — but it is a new package shape.
- **One artifact now carries two concerns at different altitudes** — a governance ownership declaration and a build manifest — so a packaging need can force a governance-schema edit and vice versa. The obvious separation is genuinely blocked: moving the packaging half into the byte-identity registry would re-trigger the basename exemption and regress the visibility criterion. Recorded as a known schema-shaped question for a future release, not as a defect in this selection.
- **A live implementation risk replaces the eliminated one.** The template-sync source resolver matches on basename, and this basename exists at two paths; the resolver's disambiguation must be verified at implementation rather than assumed.
- **The gate that reads freshness in CI can report green on the staleness that matters here**, because a sibling change in the same release adds an advisory arm to it. Package freshness for this pair is therefore graded against the always-enforce deploy check, not against CI colour.

## Reversibility

**MODERATE / Confidence MEDIUM.**

The registration half alone is **CHEAP**: delete the registry file and revert the check passes; nothing migrates, and a registry with no consumer is inert. The package-resolution half is what raises the tier — reverting it requires restoring the prior package archive and its content-baseline sidecar **in the same commit** as the source revert, or the always-enforce freshness check fails in the opposite direction. There is no schema migration and no persisted state in either direction, which is why the tier is MODERATE rather than EXPENSIVE.

Confidence is MEDIUM rather than HIGH for one named reason: the resolver-disambiguation residual in decision 5 is verified at implementation, not at authoring.

## Related ADRs

- [ADR-038](ADR-038-registry-as-cmdb.md) — the skill catalog as the platform's configuration database; its "no second registry" and "no axis with another home" rules are the constraint that eliminated the catalog-extension candidate.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — extend-before-create; the gate whose determination is recorded verbatim in the Decision section above.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — compose rather than absorb; the same reuse-first posture applied one layer up, at the skill boundary.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — canonical-spec-edit-wins; why the edits land at the canonical governed home and no issue body is amended to match.
