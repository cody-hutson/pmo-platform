<!-- reference-durability: allow-link -->
---
title: ADR-083 — Canonical install model (extends ADR-017)
status: Accepted
date: 2026-07-16
release: v3.75 knowledge-corpus-hygiene (provisional; binds at Stage 12)
deciders: "operator (install-model home decision at Collective Review) + Stage 5 Solutioning spoke (D-1 recommendation) + Collective Review scope-lock"
tags: [architecture, distribution, install, canonical-install, sourcing, public-repo-boundary, extends-adr-017]
source_observations:
  - "ADR-017 (Accepted 2026-06-07) records the four distribution surfaces and Decision 2 (clone-path vs install-path distinguished by version-pinning posture), but does NOT record the sourcing-canonicalization decision one axis up — whether the public acquires the platform by cloning the canonical upstream repository directly or by forking and self-hosting a divergent copy."
  - "The install docs (README / docs/) name a single canonical upstream repository as the install source and are identity-exempt; the release-target used to drive the pipeline is per-operator and stays tokenized. These are two distinct axes: where you install FROM (canonical, fixed) vs which repo you drive releases AGAINST (per-operator, tokenized)."
  - "A fresh reader of the design corpus could not find the canonical-install-vs-fork decision recorded anywhere; the distribution ADR (ADR-017) owns the surface + pinning axis only. Codifying the sourcing decision closes that gap without duplicating ADR-017."
---

# ADR-083 — Canonical install model (extends ADR-017)

## Status

**Accepted.** The install-model home was decided at Stage-5 Solutioning (D-1: a NEW ADR composing with ADR-017, chosen over amending ADR-017 in place — ADRs are immutable — and over recording the model as narrative only) and carried through the Collective Review scope-lock; it is recorded here at Stage-6 authoring. This ADR is the durable decision record for the **sourcing-canonicalization axis**. It **extends ADR-017** (which remains the authority for the distribution surfaces and version-pinning posture); it does not supersede or amend it — an orthogonal decision gets its own immutable record.

## Context

The platform repository is, simultaneously, a versioned publicly-shareable PMO package and the working tree its builders develop in. ADR-017 classified every file by its place in the install/update lifecycle (the four distribution surfaces) and established that the **clone-path** (builder, HEAD-tracking) and the **install-path** (user, pinned-tag) are both first-class over one byte-identical package, distinguished only by version-pinning posture (ADR-017 Decision 2).

What ADR-017 does **not** record is the **sourcing** question one axis up: when the public acquires the platform, do they acquire it from a **single canonical upstream repository** — clone or install directly from it and run it as-is — or do they **fork it and self-host** a divergent copy they maintain independently? That decision governs reproducibility, update flow, and where the install docs point, and it is orthogonal to the surface model and the pinning posture ADR-017 owns. Until now it was unrecorded in the corpus, so a fresh reader could not find the platform's stance on canonical-clone vs fork.

## Decision

**The platform distributes as a canonical install: the public clones the canonical upstream repository directly and runs it as-is — not fork-and-self-host.**

- **Canonical source, fixed.** The install docs (README / `docs/`) name **one** canonical upstream repository as the install source. That reference is hardcoded in the install docs (which are identity-exempt) and is the single reproducible origin every install resolves to. Cloning-and-running-as-is — optionally pinned to a release tag per ADR-017 Decision 2 — is the supported acquisition path.
- **Release target, per-operator.** *Where you install from* (canonical, fixed) is a distinct axis from *which repository you drive releases against* (per-operator). The release-target repository is parameterized (the `REPO=` target stays tokenized), so an operator running the pipeline against their own target does not change the canonical install source the public uses. Preserving this distinction keeps the public install reproducible while leaving the pipeline's target repository operator-configurable.
- **Composition with ADR-017.** This decision sits one level **above** ADR-017 Decision 2. Canonical-install is the *sourcing* decision (clone the canonical upstream vs fork); clone-path-vs-install-path is the *posture* decision (HEAD-tracking vs pinned-tag) over that same canonical source. Both hold together: a user takes the install-path (pinned tag) *of the canonical source*; a builder takes the clone-path (HEAD) *of the canonical source*.

## Alternatives Considered

| Option | Decision | Rationale |
|---|---|---|
| **Canonical install — clone the canonical upstream directly, run as-is (this ADR)** | **Chosen** | One reproducible source of truth; updates flow forward from a single upstream; the install docs point to one fixed origin; no divergence between what the public runs and what the platform ships. |
| Fork-and-self-host — each adopter forks and maintains a divergent copy | Rejected | Multiplies divergent copies with independent drift; breaks reproducibility (no single canonical version a user can pin to); update propagation becomes per-fork merge labor; the public install docs would have no single stable target. |

## Consequences

**Positive.**
- One reproducible, canonical origin for every install; a user can pin to a canonical release tag (ADR-017 Decision 2) and get byte-identical behavior.
- The install docs carry a single stable install source; the identity-exempt hardcoding of that concrete source is legitimate and bounded to README / `docs/` — it never enters `core/**`.
- The sourcing axis is now recorded, so future distribution slices cite this ADR rather than re-deciding canonical-vs-fork ad hoc.

**Negative / accepted.**
- The canonical upstream repository is a single origin every install depends on; mitigated by the standard git-distribution properties (clones are complete, tags are immutable) and by the per-operator `REPO=` seam that lets an operator drive releases against their own target without changing the public source.
- "Canonical install" is a convention, not a mechanically-enforced invariant; it is upheld by the install docs pointing to one source and by the depersonalization gate keeping the concrete upstream handle out of `core/**` (the concrete handle lives only in the identity-exempt install docs, never here).

## Reversibility

**CHEAP / Confidence HIGH.** Adopting this decision is documentation plus install-doc convention; reverting is editing this ADR and the docs that cite it (hours, no data loss). The decision follows directly from the reproducibility driver ADR-017 already establishes, so confidence is HIGH. Per the reversibility protocol, no step here is irreversible.

## Related ADRs

- **ADR-017** (distribution architecture — four surfaces, version-posture acquisition) — the **parent** this ADR extends. ADR-017 owns the distribution-surface model and the clone-path/install-path version-pinning posture (Decision 2); this ADR adds the orthogonal sourcing-canonicalization axis (canonical-clone vs fork) over that same package. ADR-017 is unchanged.
- **ADR-012** (roadmap / instance content de-scoped to operator-local) — the reason operator-instance content never ships in the canonical source, so a direct clone carries only the shared package.
- **ADR-010** (secrets / public-safety posture) — the reason the canonical source carries zero operator environment, which is what makes a direct clone reproducible and identity-clean.
