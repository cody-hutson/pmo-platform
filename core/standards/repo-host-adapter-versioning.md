<!-- reference-durability: allow-link -->
---
title: repo_host Adapter — Version-Claim Operation Interface
purpose: Defines the four operations a repository-host adapter must provide for the host-agnostic deterministic-version-claiming capability — anchor / claimed_set / atomic_claim / lineage — with abstract, host-agnostic semantics (not a host mechanism), the config-selection binding to operator.toml [adapters].repo_host, and a GitHub/git v1 reference-adapter mapping. Interface spec only — the capability that consumes it is recorded in the version-claim-determinism ADR; the executable claim mechanism that calls these operations is a separate slice.
type: standards
composes_with: [../config/operator.toml.template, ../ADRs/ADR-017-distribution-architecture.md, ../ADRs/ADR-022-platform-config-vs-operator-toml-split.md, version-field-semantics.md]
reversibility: MODERATE (a new interface spec + one config-selector binding that already exists in the template) / Confidence HIGH — git revert restores prior state; the spec adds no runtime surface of its own (the executable claim mechanism that binds to it is a separate slice), and exactly one adapter (GitHub/git v1) implements it, so there is no multi-adapter migration to unwind.
---

<!-- repo-integrity: allow-issue-ref -->

# repo_host Adapter — Version-Claim Operation Interface

> Reversibility: MODERATE / Confidence: HIGH. The four-operation signature below is the load-bearing contract the executable claim mechanism binds to — do NOT change the operation set or its abstract semantics after a second adapter implements it without re-touching every adapter and the claim mechanism.
> Records: the `repo_host` adapter binding of the deterministic-version-claiming capability ratified in the version-claim-determinism ADR (slug `version-claim-determinism`). That ADR records *the capability*; this spec defines *the host interface* the capability is bound to.
> Selection: the active adapter is chosen by `operator.toml [adapters].repo_host` (cascade-resolved); v1 ships exactly one adapter (GitHub/git).

## 1. Why this interface exists

Deterministic version-claiming is a **host-agnostic capability**: a release declares a bump-class and a slug, defers the concrete version to the claim moment, and claims it atomically so that ship-order equals merge-order equals tag-order. *How* a version is anchored, enumerated, claimed, and classified is a property of the **repository host**, not of the capability. This spec is the seam between the two: it defines the four operations the capability needs from a host, in terms a host can satisfy by any means.

The contract is stated with **no host mechanism in it** — no specific CLI, no tag, no API call appears in the operation semantics in §2. A host adapter satisfies the four operations however its host allows; §4 gives the one shipped adapter (GitHub/git). This is what makes the versioning capability survive a host change: a future host adapter implements the same four operations, and the capability is unchanged.

This spec defines **only the interface**. The capability that consumes it is recorded in the version-claim-determinism ADR; the executable claim mechanism that *calls* these operations (the defer-to-claim retry loop) is a separate slice. No executable logic lives here.

## 2. The four operations (abstract, host-agnostic semantics)

A conforming `repo_host` adapter MUST provide exactly these four operations. The semantics are abstract — they describe *what* each operation returns, never *how* the host produces it.

### 2.1 `anchor() → version`

Returns the **highest claimed version in the mainline lineage**. Orphan lineages are excluded.

- "Mainline lineage" is the sequence of versions that belong to the published, forward line of the platform — the line a new release extends. A version that exists but is *not* part of that forward line (an abandoned or parallel-experiment lineage) is an **orphan** and MUST NOT be returned as the anchor.
- `anchor()` answers "what does a new release build on top of." It is the basis for computing the next-free version, but it is **not** the next-free version itself (that is the claim mechanism's job, computed against `claimed_set()`).
- **Determinism requirement:** `anchor()` MUST be a pure read of authoritative host state at call time. It is recomputed at the claim moment; an adapter MUST NOT cache a stale anchor across the held-but-unclaimed gap (the entire point of the capability is that this value can move between planning and claim).
- The "how" of `anchor()` — max-semver scan, a host's "latest release" pointer, a published-sequence walk — is an **adapter-internal detail**, deliberately out of the capability's architecture. Two adapters MAY compute the anchor by entirely different means and still conform.

### 2.2 `claimed_set() → set<version>`

Returns **all versions currently claimed or in-flight** — the complete set that a candidate next-free version MUST avoid.

- The set is the union of every surface on which a host records a claim: settled claims and in-flight ones (a release that has claimed but not yet fully closed). An adapter MUST include in-flight claims, because the held-but-unclaimed window is exactly where a naive implementation would miss a contender.
- `claimed_set()` is the freeness oracle: next-free is the lowest version of the requested bump-class not in `claimed_set()`. The **defense-in-depth detection** layer (planning-time and pre-merge freeness checks) reads `claimed_set()`; so does the claim mechanism, immediately before the atomic claim.
- **Determinism requirement:** like `anchor()`, `claimed_set()` MUST be a fresh read of authoritative host state at call time — never a planning-time snapshot reused at claim time.

### 2.3 `atomic_claim(version, release_ref) → OK | COLLISION`

**Compare-and-swap claim** of `version` for `release_ref`. Returns `OK` if this call claimed `version`; returns `COLLISION` if `version` was already claimed by someone else.

- This is the **single authoritative gate** of the capability. It MUST be atomic at the host: two concurrent `atomic_claim(v, …)` calls for the same `v` MUST NOT both return `OK`. The host — not the adapter, not the caller — is the arbiter; the adapter exposes the host's atomicity, it does not simulate it with a read-then-write (which would race).
- `release_ref` identifies the release making the claim (so the claim is attributable). `version` is the candidate the caller computed from `anchor()` + `claimed_set()` immediately before calling.
- **The caller's obligation on `COLLISION`:** recompute next-free (re-read `anchor()` + `claimed_set()`) and retry. The claim MUST NEVER overwrite an existing claim — `atomic_claim` has no force path. The recompute-and-retry loop is what makes ship-order = merge-order = tag-order an architectural guarantee: the caller that wins the compare-and-swap is the one that gets the number, in the order the host arbitrates (which is merge order).
- **Failure discrimination (caller-side, stated here so adapters surface it):** a `COLLISION` is the *only* outcome that retries. A host-side failure that is **not** a collision (a network error, an authentication/signing failure, a permission denial) MUST be surfaced as a hard error and **halt** — never silently retried as if it were a collision. An adapter MUST therefore distinguish "the version was already claimed" (→ `COLLISION`, retry) from "the claim operation itself failed" (→ error, halt).

### 2.4 `lineage(version) → MAINLINE | ORPHAN`

Classifies `version` as belonging to the **mainline lineage** or an **orphan lineage**.

- This is the classifier `anchor()` and `claimed_set()` use to exclude orphan versions. A version on an abandoned or parallel-experiment line is `ORPHAN`; a version on the published forward line is `MAINLINE`.
- `lineage()` exists so the capability never anchors on, or treats as a competitor, a version that is not actually part of the line a release extends. Without it, a stray orphan tag could inflate the anchor or block a free number.
- The "how" — reachability from a mainline ref, membership in a published sequence, a recorded lineage tag — is again an **adapter-internal detail**.

## 3. Config-selection (the existing seam — no new mechanism)

The active `repo_host` adapter is selected by **user configuration**, at the seam that already exists. No new selector, file, or resolution path is introduced.

- **Selector:** `operator.toml [adapters].repo_host`. The template ships `repo_host = "github"` with the comment *"Valid: "github" (GitHub via gh) — additional hosts gated on their adapter tickets. Default: "github""* — that comment is the extraction-ready pattern: a new host becomes a new allowed value, gated on its own adapter ticket, with no change to this interface.
- **Resolution:** the value is **cascade-resolved** per the Platform-Config Resolution Protocol — global → portfolio → program → project → individual — so an operator, program, or project may select a host adapter at the appropriate altitude, with the install-level default as the floor.
- **Default:** `github`. A fresh install runs the capability end-to-end with no operator action, against the v1 GitHub/git adapter (§4).
- **Adding a host:** a future host adapter (a) implements the four operations of §2 against its host, (b) adds its value to the `[adapters].repo_host` allowed set, and (c) ships under its own adapter ticket. The capability, the claim mechanism, and this interface are unchanged — only a new implementation is added behind the selector.

This binding is faithful to the platform's config-home decisions:

- the distribution-architecture decision ([ADR-017](../ADRs/ADR-017-distribution-architecture.md) §S2) names `operator.toml` as the home for "identity, paths, methodology, **adapters**" — so a host-adapter selector belongs in `operator.toml [adapters]`, not a new file;
- the platform-config-vs-operator.toml split decision ([ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md)) consolidates the host-adapter selectors into the `operator.toml [adapters]` table (`repo_host` / `ticketing` / `kb` / `ai_tool`), each with a v1 default;
- both selectors ship on the `adapter-config-foundation` release, which is the foundation this selector extends.

## 4. GitHub/git v1 reference adapter (the only adapter shipped)

Exactly one adapter ships in v1. It satisfies the §2 interface with GitHub/git mechanism. This is a **reference mapping** — it shows how the abstract operations bind to concrete host capability; it is not part of the contract (a different adapter binds differently).

| Operation (abstract, §2) | GitHub/git v1 implementation |
|---|---|
| `anchor()` | the host's **latest published release** pointer (`gh api repos/{REPO}/releases/latest`). It returns the current top of the mainline lineage and **self-excludes** an orphan version lineage that is not reachable as a published release. |
| `claimed_set()` | the **union** of git tags ∪ published Releases ∪ the deployed/verified rows of the release log. The union is required because a claim is recorded on more than one surface and an in-flight claim may appear on one before the others. |
| `atomic_claim(version, release_ref)` | **push a signed version tag** for `release_ref` at `version`. The host's git **ref compare-and-swap rejects** a colliding push (`! [rejected] <version> -> <version> (already exists)`) → mapped to `COLLISION`; a successful push → `OK`. A non-rejection push failure (network / signing / permission) → hard error, **not** `COLLISION`. The empirically-validated primitive (the ref-rejection on a blind concurrent push) is this operation's foundation. |
| `lineage(version)` | **mainline-reachability / published-sequence membership** — a tag reachable on the mainline line and present in the published release sequence is `MAINLINE`; an unreachable/parallel tag (an orphan version lineage) is `ORPHAN`. |

**Adapter discipline (binds the executable slices):** executable slices of the capability call the **named operations** above (`anchor()` / `claimed_set()` / `atomic_claim()` / `lineage()`). They MUST NOT inline `gh` / `git` commands into host-agnostic capability code — the host mechanism lives **only** inside the adapter. This keeps the "anchor decision" (how the highest claimed version is determined) an adapter-internal detail rather than an architectural choice, and keeps the capability portable.

## 5. Conformance checklist (for a new `repo_host` adapter)

A new adapter conforms when all of the following hold:

1. **All four operations present** — `anchor()`, `claimed_set()`, `atomic_claim(version, release_ref)`, `lineage(version)` — with the §2 abstract semantics.
2. **`atomic_claim` is host-atomic** — two concurrent claims of the same version cannot both return `OK`; there is no force/overwrite path; the host arbitrates.
3. **Collision vs failure discriminated** — only an already-claimed version returns `COLLISION`; an operation failure (network / auth / signing / permission) returns a hard error that halts, never a silent retry.
4. **Fresh reads** — `anchor()` and `claimed_set()` read authoritative host state at call time; no planning-time snapshot is reused at claim time.
5. **Orphan exclusion** — `anchor()` and `claimed_set()` exclude orphan-lineage versions via `lineage()`.
6. **Selector value registered** — the adapter's name is an allowed value of `operator.toml [adapters].repo_host`, shipped under its own adapter ticket; the default remains `github`.
7. **No host mechanism leaks** — host commands appear only inside the adapter; capability code calls the named operations.

## 6. Provenance

- Capability + adapter-binding decision: the version-claim-determinism ADR (slug `version-claim-determinism`) — records the host-agnostic capability (five invariants), the `repo_host` adapter binding, and the GitHub/git v1 reference adapter; this spec is the interface that decision references.
- Config-home: [ADR-017](../ADRs/ADR-017-distribution-architecture.md) §S2 (operator.toml as adapters home) + [ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md) (the `[adapters]` selector table) + the `adapter-config-foundation` release.
- Selector + comment-pattern: [`operator.toml.template`](../config/operator.toml.template) `[adapters].repo_host`.
- The four-operation interface and the GitHub/git reference mapping were locked at the Collective Review architecture elevation (the host-agnostic recast of the originally-ratified GitHub-concrete mechanism); the cross-slice "adapter discipline" contract (executable slices call named operations; no inlined `gh`/`git`) is locked alongside it.
