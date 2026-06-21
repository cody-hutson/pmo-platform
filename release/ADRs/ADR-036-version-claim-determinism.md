<!-- reference-durability: allow-link -->
---
title: "ADR-036 — Deterministic version-claiming: a host-agnostic capability (slug-primary identity, intent-to-bump, defer-to-claim, atomic compare-and-swap) bound to a config-selected repo_host adapter"
status: Accepted
date: 2026-06-21
release: release-version-claim-determinism
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + the architect-of-record at the Collective Review architecture elevation + operator at the 2026-06-20 ratification"
tags: [release-ops, versioning, version-claim, ref-cas, slug-primary, defer-to-merge, concurrency, pipeline-identity, repo-host-adapter, host-agnostic, config-selection]
source_observations:
  - "#950 — root observation: a long-running release's version is assigned at Stage 4 but not enforced until the Stage-12 merge tag, so a faster concurrent release can claim the same number first; the prevention+detection set this observation asks for is what this capability ships."
  - "Spike S-1 (ref-CAS, 2026-06-20) — adapter validation: a blind concurrent `git push <tag>` is server-rejected (`! [rejected] v2.15 -> v2.15 (already exists)`). This confirms the GitHub/git reference adapter's `atomic_claim()` is well-founded; in the elevated architecture the spike validates the *adapter*, not the contract."
  - "Spike S-2 (naming blast radius, 2026-06-20) — `release/tools/automated-closeout.sh` assumes `vX.Y-slug` milestones; the slug-primary identity rework's first tooling consequence lands there (coupled, kept separate as #1672)."
  - "Spike S-3 (grammar, 2026-06-20) — shipped forms are X.Y and X.Y.Z (`v2.06.1` is real); suffix forms (`vX.Yb`) never shipped, and the version validator is permissive. The grammar work is tighten + formalize, not 'add X.Y.Z'."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-036 — Deterministic version-claiming: a host-agnostic capability bound to a config-selected repo_host adapter

## Status

Accepted — operator-ratified 2026-06-20 (the decision predates ADR authoring; this ADR records it), then **elevated to host-agnostic** at the 2026-06-21 Collective Review by the architect-of-record. The ratifying gate is the Stage 5 N-way-consistency Collective Review per the Status enum in the release-ADR README ("Operator-ratified at Collective Review or equivalent gate"). The original ratification recorded a GitHub-concrete mechanism; the elevation recast that mechanism as one *adapter* and made the capability host-agnostic — this ADR records the elevated form.

Numbered as the next-free slot across `release/ADRs/` and `core/ADRs/`, re-verified at the authoring commit of this release with the platform-wide gap-free/unique check as the backstop. The ADR is referenced downstream **by slug** (`version-claim-determinism`), never by its number — the number is an authoring-time assignment, not a stable cross-reference handle (this is the same slug-primary principle the capability itself adopts, applied to ADR identity; a verified-free number was claimed by a faster concurrent release during this very engagement, which is exactly the failure mode this capability prevents).

This decision is reversed only by a **superseding ADR** (Nygard `Superseded` / `Deprecated` status, citing the superseding ADR) — never by an in-place edit of this immutable record. See `## Reversibility`.

## Context

The release pipeline assigns a version early but does not *claim* it until late, and version was baked into the pipeline's identity. Two structural defects follow.

**Defect 1 — a held-but-unclaimed window.** A version is assigned at Stage 4 (Planning) but is not enforced anywhere until the Stage-12 merge tag. Between those two stages the number is *reserved in intent only* — nothing prevents a second, faster release from reaching its own merge first and taking the same number. A long pipeline (the very thing a large, deliberate release is) is therefore the most exposed: the longer a release takes, the more likely a sibling claims its number in the gap. The originating evidence is a real re-version cascade where a release lost its assigned number to faster concurrent releases and had to be renumbered through several slots in flight.

**Defect 2 — ship-order ≠ tag-order.** Because the number is chosen at planning time, the order in which releases are *versioned* is decoupled from the order in which they *merge*. There is no architectural guarantee that the sequence of merges equals the sequence of version tags; the correspondence is a procedural hope, maintained by hand, and broken exactly when two releases race.

**The identity coupling that amplifies both.** Version was part of pipeline identity — the branch name, the plan filename, the milestone, and the in-flight commits all carried the concrete version. A re-version was therefore not a one-line change but a rename cascade across branch, plan, milestone, tooling, and commit history. This coupling is what makes a re-version expensive, and the expense is what makes losing the race costly rather than trivial.

**Adapter-validation evidence (folded from the spikes).** A spike empirically confirmed that the central primitive the GitHub/git reference adapter relies on — a server-side rejection of a colliding tag push (a compare-and-swap on the tag ref) — actually fires: a blind concurrent push of an already-claimed tag is rejected by the host. In the elevated architecture this validates the *adapter's* `atomic_claim()` implementation, not the contract itself (the contract names the operation abstractly). Two further spikes mapped the rework surface: the closeout tooling assumes a version-prefixed milestone name (the first tooling consequence of slug-primary identity, kept as a separate coupled ticket), and the shipped version grammar is X.Y / X.Y.Z with suffix forms that never shipped — so the grammar work is *tighten and formalize*, not *extend*.

## Decision

Adopt **deterministic version-claiming as a host-agnostic capability**, defined by five invariants stated without reference to any particular host's mechanism, and **bind it to a host through a config-selected `repo_host` adapter**. The GitHub/git mechanism is one *adapter implementation* of the capability, not the capability itself.

### The five invariants (the host-agnostic contract)

The contract text names no host mechanism (no `gh`, no `git`, no tag): a different host adapter satisfies the same five invariants by different means.

1. **Slug-primary identity.** The capability slug is the durable through-line of a release: the milestone is `<slug>`, the branch is `release/<slug>`, the plan is `<slug>_RELEASE_PLAN.md`. The version *leaves* pipeline identity entirely and is stamped only at the moment of claim. Identity is the slug; the version is an outcome.

2. **Intent-to-bump, not a number.** The release plan declares a **bump-class** (major / minor / patch) and a **provisional-display** version for human readability. It binds **no concrete version**. The provisional display is explicitly not a reservation.

3. **Defer-to-claim.** The concrete version binds only at the **claim** moment (the merge), never at planning. Until the claim, the release has a bump-class and a slug, not a number.

4. **Atomic compare-and-swap claim.** At claim, the adapter computes the next-free version against authoritative state and claims it through a compare-and-swap operation that the host **rejects** on collision. On a COLLISION result the claim **recomputes next-free and retries** — it **never overwrites** an existing claim. This is what makes ship-order = merge-order = tag-order an *architectural guarantee* rather than a procedural hope: the merge that wins the compare-and-swap is the merge that gets the next number, in merge order, by construction.

5. **Defense-in-depth (detect early, recover residual).** The atomic claim is the single authoritative gate, but it is reinforced on both sides: planning-time and pre-merge **freeness checks** detect a likely collision early (cheap, advisory), and a **recovery doctrine plus a machine-readable ledger** resolve the residual edge cases that survive the gate (auditable, after-the-fact). Detection reduces the rate of collisions; the atomic claim guarantees correctness when one happens anyway; recovery + ledger make any residual divergence visible and reconcilable.

### The `repo_host` adapter binding

The capability is bound to a host through a small, abstract interface — the `repo_host` adapter — defined in the net-new standard `core/standards/repo-host-adapter-versioning.md` (authored in this same slice). The adapter exposes **four operations with abstract semantics** (no host mechanism in the semantics):

| Operation | Abstract semantics |
|---|---|
| `anchor()` | The highest claimed version in the **mainline lineage**; orphan lineages are excluded. |
| `claimed_set()` | All versions currently claimed or in-flight (the set next-free is computed against). |
| `atomic_claim(version, release_ref)` | Compare-and-swap claim of `version` for `release_ref`; returns OK or COLLISION. |
| `lineage(version)` | Whether `version` belongs to the mainline lineage or an orphan lineage. |

Executable slices of this capability call these named operations; they do **not** inline a host's commands. The "anchor decision" (how the highest claimed version is determined) is therefore **out of the architecture** — it is an internal detail of a given adapter's `anchor()` implementation, not an architectural choice the capability makes.

### Config-selection of the adapter

The active adapter is selected by user configuration at the existing onboarding seam — **no new selection mechanism is invented**. The selector is `operator.toml [adapters].repo_host` (default `github`; the template comment "additional hosts gated on their adapter tickets" is the extraction-ready pattern). The value is **cascade-resolved** per the Platform-Config Resolution Protocol (global → portfolio → program → project → individual). This binding is faithful to the existing config-home decisions:

- the distribution-architecture decision (ADR-017) §S2 names `operator.toml` as the home for "identity, paths, methodology, adapters" — so a host-adapter selector belongs in `operator.toml [adapters]`;
- the platform-config-vs-operator.toml split decision (ADR-022) consolidates the host-adapter selectors into the `operator.toml [adapters]` table (`repo_host` / `ticketing` / `kb` / `ai_tool`), each with a v1 default;
- the `adapter-config-foundation` release is the foundation those selectors ship on.

### The GitHub/git v1 reference adapter (the only adapter shipped)

Exactly one adapter ships in v1, satisfying the abstract interface with GitHub/git mechanism:

| Operation | GitHub/git v1 implementation |
|---|---|
| `anchor()` | the host's "latest published release" (returns the current top of the mainline lineage; self-excludes an orphan version lineage that is not reachable as a published release). |
| `claimed_set()` | the union of git tags, published Releases, and the deployed/verified rows of the release log. |
| `atomic_claim()` | push a signed version tag; the host's ref compare-and-swap **rejects** a colliding push, which the retry loop catches and recomputes from (the spike-validated primitive). |
| `lineage()` | mainline-reachability / published-sequence membership (distinguishing the mainline line from an orphan tag lineage). |

### Grammar

The canonical version grammar is **X.Y** and **X.Y.Z**; suffix forms are **eliminated**. (The three-component hotfix form is real and shipped; the suffix forms never shipped. The grammar work is to tighten and formalize the canonical two forms, not to add a new one.)

### The two claim surfaces

There are two surfaces where a claim is recorded, and they are **not** equally atomic: the **tag is the authoritative, compare-and-swap-protected surface**; the corpus ledgers (the release log, index, digest, and changelog) are **conflict-resolved**, not compare-and-swap-protected (the conflict-resolution doctrine for them is a separate slice of this same capability). When the two disagree, the tag wins. A machine-readable ledger makes any residual divergence auditable.

## Alternatives Considered

- **(A) Reserve-early** — assign *and* claim the number at Stage 4 (Planning). **REJECTED.** It re-introduces a held resource and its cleanup problem: when a reserved release slips or is abandoned, the reserved number must be reclaimed and any orphan claim cleaned up. It recreates the held-but-unclaimed pathology in a different place (now the resource is held *too early* rather than *too long*), and it still does not guarantee ship-order = tag-order, because the reservation order is the planning order, not the merge order.

- **(B) Detect-and-recover only** — keep the Stage-4 assignment and add collision detection plus cleanup, with no atomic claim. **REJECTED.** It leaves the race in place and only *cheapens* the cleanup after a collision happens; it never delivers the ship-order = merge-order = tag-order guarantee, because nothing makes the winning merge the number-holder by construction. Detection without an authoritative atomic gate is a mitigation, not a fix.

- **(C) GitHub-concrete mechanism as the architecture** — record the original ratified form, in which the architecture *is* "push a signed tag and rely on git ref-CAS," with the anchor decision (max-semver vs `releases/latest`) as a first-class architectural choice. **REJECTED — superseded by the adapter abstraction.** Binding the capability to one host's mechanism makes versioning non-portable (a host change would be an architecture change), and it elevates an adapter-internal detail (how `anchor()` is computed) to an architectural decision. The elevated form keeps the capability host-agnostic and demotes the mechanism — and the anchor decision — into a swappable adapter.

- **The selected approach** (host-agnostic five-invariant capability + config-selected `repo_host` adapter) is the only option that (a) eliminates the held-but-unclaimed window, (b) makes ship-order = merge-order = tag-order an *architectural* guarantee, and (c) keeps the capability portable across hosts — the deciding property the rejected alternatives each lack.

## Consequences

**Positive:**
- **The held-but-unclaimed window is eliminated** — a version binds only at the atomic claim, so there is no interval in which a number is reserved-but-unenforced.
- **Ship-order = merge-order = tag-order becomes an architectural guarantee** — the merge that wins the compare-and-swap is the merge that gets the next number, by construction, not by hand.
- **Commits stop carrying stale pre-merge versions** — version is stamped at claim, not at cut, so in-flight commits do not bake in a number that may not survive the race (this composes with the shipped `.version`-at-claim stamping behavior).
- **Portability** — because the capability is host-agnostic and the mechanism lives in a config-selected adapter, the versioning capability **survives a host change**: switching `[adapters].repo_host` to a future host adapter retains the capability without re-deciding the architecture.

**Negative / costs:**
- **The slug-primary rework** — moving version out of pipeline identity reworks the closeout tooling (the version-prefixed-milestone assumption is the first surface; kept as a separate coupled ticket), the branch/plan conventions, and the Stage-4 D-Version gate (re-scoped from "pick a number" to "declare a bump-class"). This is real, multi-surface work.
- **Two claim surfaces** — the tag is compare-and-swap-authoritative, but the corpus ledgers are conflict-resolved, not compare-and-swap-protected. A residual divergence between the authoritative tag and the ledgers is possible; the ledger-side conflict-resolution doctrine and the machine-readable ledger are the mitigations, and the tag remains the single source of truth.

**Coordinating (~):**
- This capability **coordinates with the shipped `.version`-stamping behavior** at the claim point (it consumes that behavior rather than coordinating with concurrent work — the stamping work has shipped). The grammar is tightened to the canonical X.Y and X.Y.Z forms, with suffix forms eliminated.

## Reversibility

**Tier: EXPENSIVE to reverse — Confidence: HIGH.**

Distinguish two reversibilities so a reader does not conflate them. The **ADR record** is cheap to supersede — a status flip plus a new ADR. The **architecture this ADR ratifies is EXPENSIVE to reverse once the claim mechanism ships** — by then slug-primary identity has reworked the branch / plan / milestone conventions, the closeout tooling, and the Stage-4 D-Version gate; unwinding to a version-primary, reserve-at-Stage-4 model is a multi-surface migration touching live pipeline conventions, tooling, and in-flight releases (days-to-weeks, stakeholder-visible re-tooling) — the EXPENSIVE tier per the reversibility protocol. The ADR's tier is the *architecture's* tier — EXPENSIVE — because that is the commitment the ADR makes.

Confidence is **HIGH**: the tier rests on named downstream surfaces (the claim mechanism, the closeout-tooling rework, and the branch/plan conventions), each verified to exist; the ref-CAS spike confirms the reference adapter's central primitive is real, so the architecture is not speculative.

**Counter-commitment:** the decision is reversed **only by a superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the superseding ADR), authored through the same pipeline + immutable-ADR path — not by an in-place edit of this record.

## Related ADRs

- **The version-as-contended-axis extension** — the fifth invariant treats the version slot as a contended resource detected by the same machinery as file-surface overlap. That machinery is the cross-release impact model (recorded in the cross-release-impact-model ADR, [ADR-024](ADR-024-cross-release-impact-model.md)), whose detection substrate — the mover-classifier, the `SURFACE(R)` ref-form sweep, and the serialization predicate `serialize(R₁, R₂) := EDITSET(R₂) ∩ SURFACE(R₁) ≠ ∅` — is owned by the Stage-3 Bundle spec (`release/references/pipeline/stage-03-bundle.md` §A9.6.1). ADR-024 records the decision that introduced the contention axis; the Stage-3 Bundle spec owns the axis mechanics. This decision *names* the version slot as a further contended axis on that same machinery; the **model extension itself is authored in the version-as-contended-axis slice** (#1674), which implements it against ADR-024 and the Stage-3 Bundle §A9.6.1 substrate and authors the reciprocal back-reference into ADR-024 (this immutable record is not edited for it). The cross-reference between this ADR and the #1674 successor is anchored on the slug, not on either ADR number.

- **Config-home decisions** — the `repo_host` adapter selector lives in `operator.toml [adapters]` per the distribution-architecture decision [ADR-017](../../core/ADRs/ADR-017-distribution-architecture.md) §S2 (operator.toml is the home for "identity, paths, methodology, adapters"), and the selector table is consolidated by the platform-config-vs-operator.toml split decision [ADR-022](../../core/ADRs/ADR-022-platform-config-vs-operator-toml-split.md); both ship on the `adapter-config-foundation` release.

- **Foundation slices (this release).** The capability is delivered across the release-version-claim-determinism milestone: the allocation rule (#1673, the "what is next-free" definition the adapter computes against), the canonical grammar SSOT (#1676, the integer-tuple parser every version comparison sources), the version-as-contended-axis extension (#1674), and the atomic claim mechanism (#1675, which realizes invariants 3–4). These foundation tickets cite this founding decision **by slug**; the slug, not the ADR number, is the durable cross-reference handle.
