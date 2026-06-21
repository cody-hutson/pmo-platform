<!-- reference-durability: allow-link -->
---
title: "ADR-037 — Version slot as a cross-release contended axis (extends ADR-024) via a version-slot virtual-path token on the unchanged serialize() predicate"
status: Proposed
date: 2026-06-21
release: release-version-claim-determinism
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [release-ops, cross-release, versioning, version-claim, contention-scoring, contended-axis, virtual-path-token, parallelization, adr-024-extension]
source_observations:
  - "Originating gap (the version-as-contended-axis slice): the shipped cross-release impact model serializes concurrent releases on a path-intersection predicate (serialize(R₁,R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅, owned by the Stage-3 Bundle spec §A9.6.1). The version number is not a path, so it is invisible to that predicate and to the three gates built on it (Stage 4 A4 / Stage 9 G-PR9 / Stage 12 Phase A.5). The version namespace is a contended concurrent-release resource exactly analogous to the file/structural axes already modeled, and must be modeled as a first-class contended axis."
  - "Founding capability clause: the version-claim-determinism capability's fifth invariant (defense-in-depth: detect early, recover residual) names the version slot as a contended resource detectable by the same machinery as file-surface overlap. This ADR records the model extension that implements that naming; the founding ADR explicitly defers the model extension itself to this slice and is not edited for it (immutable record)."
  - "Stage 5 adversarial review correction (claim-key normalization): the canonical version grammar (version-grammar.sh) accepts leading-zero components (v2.06 is a shipped tag) and decides slot identity only on the parsed integer tuple via version_parse. The claim-key must therefore key on that integer tuple, not on the raw display string, or a v2.06-vs-v2.6 pair mints two tokens and silently misses a real collision (a false negative)."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-037 — Version slot as a cross-release contended axis (extends ADR-024)

## Status

Proposed — flips to Accepted at this milestone's Collective Review scope-lock (the same Status-enum gate the release-ADR README names: "Operator-ratified at Collective Review or equivalent gate"; the same pattern ADR-024 and ADR-036 followed).

Numbered as the next-free slot across `release/ADRs/` and `core/ADRs/`, resolved at the authoring commit of this release with the platform-wide gap-free/unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop — confirmed contiguous `001..036` at authoring, so this ADR is `037`. The ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle. This is the same slug-primary identity principle the parent capability rests on, applied to ADR identity.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this immutable record, exactly as this ADR extends ADR-024 by a new record rather than mutating it.

## Context

The cross-release impact model (recorded in the cross-release-impact-model ADR, [ADR-024](ADR-024-cross-release-impact-model.md)) serializes concurrent releases on a **path-intersection** predicate. Its detection substrate — the mover-classifier, the `SURFACE(R)` ref-form sweep, and the serialization predicate — is owned by the Stage-3 Bundle spec (`release/references/pipeline/stage-03-bundle.md` §A9.6.1). The predicate is:

```
serialize(R₁, R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅
```

Its operands are path-sets. The **version number a release intends to claim is a contended concurrent-release resource** — two in-flight releases racing for the same version slot collide exactly as two releases editing the same file do — but the version is not a path, so it never enters `SURFACE(R)` or any sibling's `EDITSET`, and the predicate (and the three gates built on it: the Stage 4 A4 structural sub-audit, the Stage 9 G-PR9 GO-currency check, and the Stage 12 Phase A.5 semantic GO-invalidation check) is structurally blind to it.

The parent capability (slug `version-claim-determinism`) makes the version slot a first-class concern: its fifth invariant (defense-in-depth — detect early, recover residual) names the version slot as a contended resource that should be **detected early** by the same machinery as file-surface overlap, with the atomic compare-and-swap claim at the merge tag as the authoritative resolver. The founding ADR (slug `version-claim-determinism`) records that naming but explicitly **defers the model extension itself to this slice**, which implements it against ADR-024 and the §A9.6.1 substrate and authors the reciprocal back-reference — the founding ADR's immutable record is not edited for it. This ADR records that model extension.

## Decision

Treat the version slot as a contended axis on the **existing** cross-release machinery by injecting a reserved **version-slot virtual-path token** into the predicate's operands — **Candidate C (virtual-path injection)**. The operator, the operand types, the verdict vocabulary, and all three downstream gates are unchanged; only the *contents* of the two operand sets gain one synthetic token each.

1. **The token.** Each release contributes a version-slot virtual-path token `Δversion/<claim-key>` to the predicate operands. `<claim-key>` is the release's provisional-display version — the **intent-to-bump** value bound at the Stage 4 D-Version gate per the founding `version-claim-determinism` ADR (a release in-pipeline declares a bump-class + provisional display, not a bound `vX.Y`) — **canonicalized to the integer tuple `<major>.<minor>.<patch>` that `version_parse` (`release/tools/version-grammar.sh`) produces**: leading zeros stripped, an absent patch coerced to `0`.

2. **Slot identity, not spelling.** The token keys on the parsed tuple, so `v2.06`, `v2.6`, and `v2.6.0` all parse to `(2, 6, 0)` and all mint the **same** token `Δversion/2.6.0`. Keying on the raw display string would mint two distinct tokens for `v2.06` vs `v2.6` and silently miss the collision — a false negative, the dangerous direction. Binding the token to `version_parse`'s tuple reuses the grammar's single parser rather than inventing a second normalizer (the one-grammar-one-parser anti-drift contract of the canonical-grammar slice).

3. **Where it goes.** `SURFACE(R)` gains `Δversion/<claim-key(R)>` (the slot R is claiming); each sibling `EDITSET(R')` gains `Δversion/<claim-key(R')>` (the slot R' intends to occupy). `Δversion/` is a reserved sentinel prefix that cannot collide with any real repo path, so the token is inert to real-path consumers and cannot be produced by a file edit — it exists only in the in-memory set the predicate evaluates.

4. **Predicate unchanged.** `serialize(R₁, R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅` is **not modified**. When two releases canonicalize to the same claim-key, the shared `Δversion/<k>` token makes the intersection non-empty and the pair is a serialization point on the (now version-inclusive) structural axis — flagged by the same machinery, the same Tier-S verdict, and the same three gates that flag a file-surface overlap. **No new predicate, no new edge type, no new gate logic.**

5. **Catch-point honesty + coverage boundary.** The version token inherits §A9.6.1's Stage-3-advisory / Stage-4-authoritative split (version assignment is a Stage-4 D-Version act, so the provisional version may be unassigned at Stage 3). The token fires authoritatively at Stage 4 A4 (provisional version bound) and re-confirms at G-PR9 / Phase A.5. It detects a collision only once **both** releases have bound **equal** canonicalized provisional-display strings; the **bump-class-relative race** (two releases both intending "the next minor off the same baseline" before either binds a concrete string, each binding next-free independently and order-dependently) is **not** caught by this axis — it is caught by the atomic compare-and-swap claim at merge. The axis is detect-at-planning defense-in-depth: a CURRENT version-axis verdict is **not** a claim guarantee (only the atomic claim is), so it adds early signal without false safety and without double-counting the authoritative resolver.

The executable mechanics live in the Stage-3 Bundle spec §A9.6.1 (Step 2a), which owns the predicate; this ADR records *that* the version slot is now a contended axis and *why* the chosen mechanism (Candidate C) was selected over the alternatives. This is the same ADR-024 ↔ §A9.6.1 division of labor that already exists: ADR-024 records the axis, §A9.6.1 owns the predicate.

## Alternatives Considered

- **(A) Extend `SURFACE`/`EDITSET` to a tagged-resource-set (typed surface) — REJECTED.** Re-type the operands from `Set[path]` to `Set[(kind, value)]`, add `kind=version`, and redefine `∩` as a same-kind match. This is a **structural-tier** change to a primitive that multiple consumers read verbatim — G-PR9 and the Stage-12 Phase A.5 check both quote `EDITSET(R₂) ∩ SURFACE(R₁)`, and both stage specs (03, 04) carry the path-set definition. It also silently changes the meaning of every *existing* structural-axis firing (the path-only case must now be expressed as `kind=path`), expanding the blast radius well past this slice. A behavioral-tier solution (Candidate C) achieves the same outcome without re-typing the shared primitive.

- **(B) Parallel version-freeness gate (separate predicate + Tier-V edge) — REJECTED.** Leave `serialize()` untouched and add a separate predicate `version_collide(R₁,R₂) := provisional-version(R₁) == provisional-version(R₂)`, emitted as a sibling Tier-V edge. This stands up a **second serialization predicate** that all three gates must each *separately* learn to call and keep in agreement with the first — re-creating the two-predicate-divergence hazard ADR-024 §H named for the `--merges` case (where a second, subtly-different predicate produced a false verdict). Candidate C reuses the one predicate the three gates already share, so the two predicates cannot drift because there is only one.

- **The selected approach** (Candidate C — virtual-path injection) is the **minimal-blast-radius** way to make a non-path resource detectable by a path-intersection predicate: it augments operand *contents* with a deterministic synthetic token and leaves the operator, the type signature, the verdict vocabulary, and all three gates untouched. The immutable-ADR extension pattern itself is precedented by ADR-005, whose title extends ADR-001 by title + back-reference; this ADR follows the same pattern (extend ADR-024 by a new record, never an in-place edit).

## Consequences

**Positive:**
- **Version contention becomes detectable by the existing machinery** — two in-flight releases targeting the same provisional version slot are flagged by the same predicate, verdict tier, and gates that flag a file-surface overlap.
- **Zero new gate logic** — the predicate, the operator, the verdict vocabulary, and the three downstream gates (A4 / G-PR9 / Phase A.5) are unchanged; they inherit version coverage for free because the token rides their existing `EDITSET ∩ SURFACE` computation. (G-PR8 is deliberately **not** modified: it is the syntactic File-Change-Matrix-touch check and does not read `SURFACE(R)`; version coverage at Stage 9 is delivered through G-PR9, preserving ADR-024's G-PR8-syntactic / G-PR9-structural split.)
- **The axis composes with — does not replace — the atomic claim.** It is a planning-time early-detection surface; the compare-and-swap claim at the merge tag remains the single authoritative resolver.

**Negative / costs:**
- **Map-legibility cost (the trade Candidate C pays for predicate-purity).** Because the version collision presents as a `Δversion/<claim-key>` token **inside a Tier-S `structural-blast-radius` edge** (the existing edge type is reused, no distinct edge type is minted), a version contention is, to an operator skimming the Parallelization Map, **indistinguishable in type from a genuine file-mover collision** — the reader must know the `Δversion/` sentinel convention to tell the two apart. Candidate B's discarded virtue is that a self-describing `Tier-V` edge would name itself "version contention" without the reader decoding a sentinel path. This cost is **accepted** to keep the predicate and the edge-type taxonomy unchanged (Candidate B's self-describing edge was rejected to avoid a second serialization predicate). Recorded here so a future maintainer inherits the trade-off, not just the winner.
- **Coverage boundary.** The token detects only the equal-bound-provisional-string case; the bump-class-relative race is left to the atomic claim (see Decision §5). The axis reduces collision *rate* early; it does not *guarantee* correctness — that is the atomic claim's job.

**Mitigation of negatives:** the version edge records its evidence as the intersecting `Δversion/<claim-key>` token + both releases' provisional versions, so a map reader who knows the convention can reproduce and distinguish it; the coverage boundary is stated inline in §A9.6.1 Step 2a so the early window is not advertised as more than it is; `git revert` of the single release PR restores prior state with zero data migration (the token rule is additive prose; the predicate is untouched).

## Reversibility

**Tier: CHEAP — Confidence: HIGH.**

Additive prose only — one token-minting rule + one claim-key canonicalization into §A9.6.1 Step 2a, one evidence-cell note + one reconfirm clause in the Parallelization Map, one clarifying clause each in G-PR9 / Phase A.5 / the Stage-4 A4 sub-audit, and this ADR + its README index rows. The predicate, the operator, the verdict vocabulary, and all three gates are unchanged, so nothing downstream must un-learn anything. `git revert` of the single release PR restores prior state with no data migration. Confidence is HIGH: every surface the token rides is verified to exist and quote the unchanged predicate, and the `version_parse` tuple normalizer the claim-key binds to is the shipped canonical-grammar SSOT.

## Related ADRs

- **Extends [ADR-024](ADR-024-cross-release-impact-model.md) (cross-release impact model).** ADR-024 introduced the structural-blast-radius contention axis and the `serialize(R₁,R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅` predicate (mechanics owned by the Stage-3 Bundle spec §A9.6.1). This ADR adds the version slot as a further contended axis on that same predicate via the version-slot virtual-path token, with the predicate, operator, and verdict tier unchanged.
- **Implements the version-as-contended-axis invariant of the founding `version-claim-determinism` ADR.** That ADR (slug `version-claim-determinism`) records the host-agnostic deterministic-version-claiming capability whose fifth invariant names the version slot as a contended resource; it explicitly defers the model extension to this slice and is not edited for it. The cross-reference between the two ADRs is anchored on the **slug**, not on either ADR number (the number is an authoring-time assignment; a verified-free number can be claimed by a faster concurrent release — the exact failure mode the parent capability prevents).
- **Predicate owner:** `release/references/pipeline/stage-03-bundle.md` §A9.6.1 (Step 2a — the executable token-minting rule). The gates that inherit the token: the Stage 4 A4 structural sub-audit (`stage-04-planning.md`), the Stage 9 G-PR9 GO-currency check, and the Stage 12 Phase A.5 semantic GO-invalidation check (`release/governance/release-process.md`).

### Issue References

- `#1674` — the version-as-contended-axis slice (the parent of this ADR): models the version number as a contended axis in the cross-release impact model, extending ADR-024. This ADR is the model-decision record for that slice; the executable mechanics land in §A9.6.1 Step 2a.
