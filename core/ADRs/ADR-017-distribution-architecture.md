---
title: ADR-017 — Distribution architecture: four lifecycle surfaces, version-posture acquisition, and package multiplicity over shared config/state
status: Accepted
date: 2026-06-07
deciders: "operator (distribution-perspective directive 2026-06-07) + distribution-architecture analysis (post the path-portability trigger recorded below)"
tags: [architecture, distribution, install, deploy, config, xdg, operator-instance, dev-workflow, public-repo-boundary]
source_observations:
  - "Operator directive 2026-06-07 — think about the platform from a distribution perspective: an install package puts the toolkit in place for a Claude-Code user; ties into version-durability and user-config; creates an install-path (users) vs a clone-path (builders), and the operator is in the small set that does BOTH on one device and must manage it properly."
  - "#504/#528/#529 path-portability trigger — deploy.sh resolved operator-instance paths via an orphan `PMO_INSTANCE_PATH` (never set) instead of canonical `CLAUDE_WORKSPACE_ROOT`; surfaced that path resolution was not checkout-independent, which is the enabling prerequisite for one operator to run two checkouts safely."
  - "No ADR records how clone-path and install-path relate; ADR-013 covers install-path *resolution* only, ADR-012 covers instance-content de-scope only, ADR-008 covers the deploy engine only — the decision spine above them is unrecorded."
  - "Three initiative/epic anchors already implement slices (#338 packaging, #14 onboarding journey, #364 multi-tenant deploy) with no shared architectural decision they cite."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-017 — Distribution architecture: four lifecycle surfaces, version-posture acquisition, and package multiplicity over shared config/state

## Status

**Accepted** 2026-06-07 — at the operator's PR #539 review. Filed as proposed-ADR issue #537 and committed here as the decision record per the core-ADR convention (the path ADR-013 / ADR-014 / ADR-016 followed). Authored in response to the operator's distribution-perspective directive and the #504/#528/#529 path-portability finding.

This ADR records the **architectural decision spine** that three existing initiative anchors already implement slices of but none cite: #338 (repo → public packages), #14 (external-user onboarding journey), #364 (multi-tenant skills-distribution model). It does **not** introduce new mechanism work or a new initiative; it gives the existing `initiative:portability-distribution` initiative the decision record it has been missing.

## Context

The `pmo-platform` repo is, simultaneously, two things with conflicting requirements:

- **A versioned, publicly-shareable PMO *package*** that a Claude-Code user installs to put the toolkit in place. This use wants a pinned/stable version, read-only platform files, reproducible installs, and zero leakage of any one operator's environment into the shared package.
- **The working tree the developer builds in.** This use wants to edit HEAD, run the 13-stage release pipeline, use worktrees and branches, hold local config, and iterate fast.

The operator is in the small set that does **both on one device** — building the platform *and* dogfooding it for real PMO work — and explicitly flagged the need to "manage this situation properly."

There is no recorded decision on how these two uses relate. The pieces exist but the spine does not:

- **ADR-013** decides install-path *resolution* (the `detect_install_path` ladder reading `operator.toml [paths].cowork_install_path`, the `COWORK_AVAILABLE` seam) — one mechanism, not the model.
- **ADR-012** de-scopes instance *content* to operator-local — one surface's boundary, not the model.
- **ADR-008** decides the deploy *engine* (per-module skill arrays) — the mechanism that produces the runtime, not the model.
- **CLAUDE.md** classifies files by **domain** (Engineering `pmo-platform/` vs Operations `projects/`) and **layer** (Layer 1 Platform / Layer 2 Operations / Layer 3 Bridge), an *ownership + git-status* cut — but says nothing about the *install/update lifecycle* cut this ADR needs.

The forcing function: #504/#528/#529 exposed that operator-instance path resolution went through an **orphan variable** (`PMO_INSTANCE_PATH`, never set anywhere) rather than the canonical `CLAUDE_WORKSPACE_ROOT`. Path resolution that is not checkout-independent makes it unsafe for one operator to run two checkouts (a dev clone and a daily-use install) against one config + one data store — which is exactly the situation the operator is in.

## Decision Drivers

- **No environment leakage into the package.** The public, shared package must contain zero operator-local/install-environment paths (depersonalization-spec, ADR-010 public-safety posture). Local paths are *installed*, not committed.
- **Version durability.** A user on a pinned install must get reproducible behavior; the developer editing HEAD must not have in-flight, unreviewed changes silently affect their daily PMO operations.
- **Checkout-independent path resolution.** Paths must resolve identically whether run from a clone, a worktree, or an installed copy — the #529 fix (canonical `CLAUDE_WORKSPACE_ROOT`, no orphan vars, no checkout-relative assumptions) is the enabling prerequisite for everything here.
- **XDG Base Directory compliance.** Config / state / data / cache separation, already begun (`operator.toml` at `~/.config/pmo-platform/`).
- **Parameterize over hardcode** (CLAUDE.md) and **retain-the-frame / parameterize-the-instance** (ADR-012) — the package ships conventions and defaults; the operator's values resolve at install/runtime.
- **One operator, one identity.** Concurrent package checkouts must not force two divergent identities/configs or two project stores.

## Decision

Four decisions, layered from model → acquisition → multiplicity invariant → placement. Each is an architectural decision; the operational *application* of the multiplicity invariant — the operator who both builds and operates — is recorded as a consequence, not a decision.

### Decision 1 — The four distribution surfaces (the model)

Classify every file by **where it sits in the install/update lifecycle**, independent of who owns it. This is an *orthogonal cut* across the CLAUDE.md Platform/Operations/Bridge layers — the same files, classified by lifecycle role rather than git-status/ownership. (Named "surfaces," not "layers," precisely to avoid colliding with CLAUDE.md's Layer 1/2/3.)

| Surface | What | Home | Versioned? | Produced / updated by | CLAUDE.md layer it cuts across |
|---|---|---|---|---|---|
| **S1 · Package** | The platform itself — `core/`, `release/`, `operations/`, skills, `deploy.sh`, hooks, templates. Universal, shared, reproducible. | the repo checkout (clone *or* installed copy) | **YES** (git tag / release) | `git pull` (dev) · `install.sh`/`update.sh` to a pinned tag (user) | Layer 1 (Platform) |
| **S2 · Config** | Operator choices — `operator.toml` (+ `operator.local.toml`): identity, paths, methodology, adapters. | XDG config `~/.config/pmo-platform/` | no (operator-owned, machine-local) | `setup-workspace.sh` at install · hand-edit · `update.sh` schema migration | Layer 2 (Operations), config subset |
| **S3 · State** | Operator-instance working content — projects, transcripts, roadmap *instances*, memory. The PMO *data*. | workspace `${CLAUDE_WORKSPACE_ROOT}` (default `$HOME/Claude`) + operator-instance dirs | no (operator-owned; never in the package repo — ADR-012) | the operator's daily work | Layer 2 (Operations), data subset |
| **S4 · Runtime deployment** | The *deployed* surface — skills mirrored to `~/.claude/skills`, rules mirrored, hooks active, Cowork session copy. **Derived** from S1. | `~/.claude/` (+ Cowork session path) | no (derived, regenerable) | `deploy.sh --deploy` | (derived from Layer 1; not separately named in CLAUDE.md) |

**Load-bearing invariant:** *S1 is the only versioned surface. S2–S4 are operator-owned and machine-local. S4 is **derived** from S1 and must always be regenerable — never hand-edited* (this is exactly what `deploy.sh` Check 9 mirror-discipline enforces). The seam between surfaces is `operator.toml` (S2): it is the single source of truth that tells S1's tools where S3 lives and how to produce S4.

This model is the durable statement of "no local filepaths in the repo": **local paths belong to S2/S3, resolved at install; S1 ships parameters and defaults, never an operator's resolved paths.**

### Decision 2 — Clone-path and install-path are both first-class, distinguished only by version-pinning posture

Two acquisition paths over the **same S1 package**:

- **Clone-path (builder / developer).** `git clone` → branches + worktrees → run the release pipeline → `git pull` to advance. **HEAD-tracking.** For those building the platform (for themselves or others). This is #338's package becoming the thing you clone.
- **Install-path (user).** Acquire a **pinned** version (release tag / packaged artifact) → `install.sh` → `deploy.sh` → use. **Pinned, not HEAD-tracking.** Updated by `update.sh` to a newer tag on the operator's schedule. This is #14's onboarding journey and #364's multi-tenant deploy.

The package is **byte-identical** between the two; what differs is only (a) **acquisition** (clone HEAD vs fetch a pinned tag) and (b) **update cadence** (`git pull` vs `update.sh` to a new tag). Both share one deploy engine (ADR-008), one resolution ladder (ADR-013), and one S2/S3 contract.

This is the standard **editable/development install vs production/pinned install** distinction from package ecosystems (e.g. `pip install -e .` / `npm link` vs pinned dependency versions): the developer edits in place and tracks HEAD; the user consumes a pinned, reproducible artifact. Adopting that well-trodden distinction (rather than inventing a bespoke one) is itself a decision driver.

### Decision 3 — The package surface is multiply-instantiable over a singular shared config + state; promotion between version postures is pipeline-mediated

S1 (Package) MAY be instantiated more than once on one machine — multiple checkouts of the byte-identical package, each at an independent version-pinning posture (Decision 2: HEAD-tracking ↔ pinned-tag). S2 (Config) and S3 (State) are **singular per operator and shared** across every package instance: one `operator.toml`, one `${CLAUDE_WORKSPACE_ROOT}` content store. A change moves from one posture to another **only through the release pipeline** — an instance advances by acquiring a new version (`git pull` / tag bump), never by an in-place edit that leaks across instances.

This fixes the surfaces' multiplicities at **1 : 1 : N (config : state : package)** and makes the pipeline the single seam through which package change reaches the shared surfaces. Two requirements are *entailments* of the invariant, not optional add-ons:

- **Checkout-independent resolution (#529).** Every S1 instance must resolve S2/S3 identically regardless of where the checkout physically lives — otherwise "shared" is a fiction.
- **Config-survives-update (#383).** A singular shared S2 means any instance's `update.sh` must preserve the config the others depend on — lossless round-trip is mandatory.

The concrete realization for the operator who both builds and operates is recorded under **Consequences → Application** — it is a workflow that *applies* this decision, not the decision itself.

### Decision 4 — State placement: operator content stays workspace-relative; only derived internals go to XDG state/cache (RECOMMENDED)

- **Keep S3 operator content workspace-relative** under `CLAUDE_WORKSPACE_ROOT` (default `$HOME/Claude`); **keep S2 config at XDG config** (`~/.config/pmo-platform/`). Rationale: the workspace *is* the operator's working directory — projects and transcripts are user-curated content they browse and navigate directly. XDG **state** (`~/.local/state`) is for app-internal state the user does *not* browse; burying user-facing project content there would be wrong.
- **Route truly-derived internals to XDG state/cache, not the workspace** — caches, event logs, telemetry, regenerable indexes belong in `~/.local/state/pmo-platform/` or `~/.cache/pmo-platform/`, not mixed into the user's content tree. (This is a refinement to apply as such artifacts are added; it is not a relocation of existing content.)

Net: `CLAUDE_WORKSPACE_ROOT` stays canonical for **content** (S3); XDG config for **choices** (S2); XDG state/cache for **derived internals** (a subset of S4). No mass migration.

## Alternatives Considered

**Decision 2 — acquisition model**

| Option | Decision | Rationale |
|---|---|---|
| **Two first-class paths over one package, distinguished by pinning posture (this ADR)** | **Chosen** | Matches the proven editable-vs-pinned distinction; one package, one deploy engine, one config contract; serves builders and users without divergence. |
| Single mode (everyone tracks HEAD) | Rejected | Users get unreviewed in-flight changes; no reproducibility; no version durability. |
| Single mode (everyone installs pinned; no editable mode) | Rejected | The platform cannot be *built* without an editable checkout; the pipeline needs it. |

**Decision 3 — package / config / state multiplicity**

| Option | Decision | Rationale |
|---|---|---|
| **Package plural at independent postures; config + state singular & shared; pipeline-mediated promotion (this ADR)** | **Chosen** | Fixes multiplicities at 1:1:N and gives one promotion seam; lets any number of concurrent checkouts (builder, user, or both at once) coexist without config/state divergence. |
| Per-instance config + state (each checkout its own) | Rejected | Divergent identity/config; multiplies the data store; violates "one operator, one source of truth." |
| Single instance only (no concurrent checkouts) | Rejected | The platform cannot be built and operated at once; forces destructive branch-switching in one tree, leaking in-flight work into live use. |

**Decision 4 — state placement**

| Option | Decision | Rationale |
|---|---|---|
| **Content workspace-relative; derived internals to XDG state/cache (this ADR)** | **Recommended** | Honors XDG intent (state = un-browsed internals) without burying user-curated content; minimal change. |
| Move all operator-instance content under `~/.local/state` | Rejected | Buries user-facing projects/transcripts in opaque state; hostile to direct navigation. |
| Everything workspace-relative (status quo, incl. caches/logs) | Rejected | Mixes regenerable internals into the user's content tree; no clean cache-clear boundary. |

## Consequences

### Positive
- The `initiative:portability-distribution` initiative gains the decision spine its three anchors (#338 / #14 / #364) implement; future slices cite one ADR rather than re-deciding ad hoc.
- "No local filepaths in the repo" becomes a *structural* statement (S1 ships parameters; paths live in S2/S3), not a recurring lint catch — closing the class #529 exemplifies.
- The multiplicity invariant gives one deterministic promotion seam (the pipeline) and fixes surface multiplicities at 1:1:N — concurrent checkouts coexist without config/state divergence.
- XDG posture is completed coherently (config vs state vs cache), enabling a clean `doctor`/`uninstall`/cache-clear story (#302).

### Negative / costs
- **Multi-surface boundary.** The S1↔S2↔S3↔S4 seams are referenced by `deploy.sh`, `setup-workspace.sh`, `update.sh`, hooks, and the install docs; re-drawing a surface boundary touches several files (this is why reversibility is MODERATE, not CHEAP).
- **Depends on #529 + #383.** The multiplicity invariant only *holds* once path resolution is checkout-independent (#529) and `operator.toml` survives updates losslessly (#383) — these are entailments of "singular shared config/state," not optional add-ons.
- **n=1 validation of the application.** The recommended realization (Application, below) is validated against one operator's workflow; revisit after a few release cycles (see Confidence).

### Application — the operator who both builds and operates (recommended realization)

The multiplicity invariant's motivating case is a single operator who both develops the platform and uses it for live work — the **N=2** instance (one HEAD checkout + one pinned checkout). The recommended realization, grounded in current practice (the operator asked for a recommendation):

- a **daily-use instance** at the release stream — today the operator's primary tree at `origin/main`, which already approximates a pinned-release posture because every merge clears the full pipeline; pin to release **tags** if `main` ever begins to carry un-released state;
- a **dev instance** at HEAD + worktrees for pipeline work;
- both reading the one shared S2 config + S3 state, with dev *testing* kept off production state (the pipeline's worktree isolation + fixtures already provide this);
- changes promoted **only through the pipeline** — *dogfood the release, not HEAD* — so in-flight work never reaches live operations.

This *applies* Decision 3; it is not a separate decision and asks for nothing the invariant does not already require (#529 + #383). The risk it manages: a *single* checkout switching branches between live work and building could let a half-built skill process real project data, or a dev-branch `deploy.sh --deploy` overwrite the S4 mirror — the two-instance realization isolates code-in-progress from live operations while config + data stay unified. **Confidence MEDIUM (n=1); revisit after a few release cycles.**

## Reversibility

**MODERATE / Confidence: Decisions 1, 2, 4 HIGH; Decision 3's invariant HIGH, its recommended *application* MEDIUM.**
- Decisions 1–4 are classification / posture / invariant decisions — adopting them is documentation + incremental conformance; reverting is editing this ADR and the docs that cite it (days, no data loss).
- Decision 3's invariant (1:1:N multiplicity, pipeline-mediated promotion) is HIGH-confidence and follows directly from the surface model. Its concrete *application* (Consequences → Application) is the only n=1 element — **MEDIUM** confidence, revisit after a few release cycles. Per the reversibility protocol, no step is irreversible.

## Composition with other ADRs and the initiative

- **ADR-013** (install-path resolution) — the resolution ladder is the S2→S4 "where does the runtime get produced" mechanism this ADR generalizes; ADR-013 stays the authority for *how* the path is resolved.
- **ADR-012** (instance de-scope) — names the S3 boundary (instance content operator-local, never in S1); this ADR places it in the lifecycle model.
- **ADR-008** (deploy per-module arrays) — the S1→S4 deploy *engine*; unchanged.
- **ADR-010** (secrets / public-safety) — the reason S2/S3 must never leak into S1.
- **#338** packaging, **#14** onboarding journey, **#364** multi-tenant deploy — the three anchors this ADR is the spine for; each should reference ADR-017 as its architectural foundation.
- **#22** (unified config) implements S2 consolidation; **#383** (lossless round-trip) protects S2 across updates (prerequisite for Decision 3); **#342/#44/#43/#341** implement the S1→S4 deploy mechanics portably; **#529** is the checkout-independent-resolution prerequisite for Decision 3.

## Forward-coupling / identified gap

The **install-path posture itself** — "fetch a pinned release tag → `install.sh` → `deploy.sh`," plus Decision 3's build-and-operate dual-instance application — does not appear to be ticketed as a discrete slice (the closest, #364, owns multi-tenant *deploy mechanics*; #14 owns the *journey*; neither owns the *pinned-tag acquisition + dual-instance discipline*). Filed as **#538** under the existing `initiative:portability-distribution` (milestone deferred to triage — `multi-tenant-distribution-model` or `cross-platform-install-experience`), **not** a new umbrella.
