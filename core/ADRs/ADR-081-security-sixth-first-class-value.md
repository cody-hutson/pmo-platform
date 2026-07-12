<!-- reference-durability: allow-link -->
---
title: "ADR-081 — Security as the sixth first-class build-philosophy value"
status: Accepted
date: 2026-07-12
release: v3.73 build-security-hardening
deciders: "operator (S2 charter-amendment approval at Stage-4 Plan Review + Collective Review scope-lock, this release) + adversarial design review (GHSA-9cjm / GHSA-rw36 retro)"
tags: [build-philosophy, first-class-value, security, coverage-matrix, charter-amendment, GHSA-9cjm, GHSA-rw36, fail-closed]
source_observations:
  - "GHSA-9cjm (PreToolUse hook fail-open, ~7.3) and GHSA-rw36 (eval-viewer stored XSS, ~5.0) shipped to a public clone-to-install repo and were caught EXTERNALLY, not by any internal gate."
  - "build-philosophy.md enumerated FIVE first-class values with no Security; its gap-detector (an empty matrix cell is a named gap) fires only for cells that EXIST, so with no Security row a missing security enforcer can never surface as an empty cell — the charter's own gap-finder was structurally blind to the security class."
  - "domain-best-practices/software.md (the BP-coding guide) had ZERO security content and was n/a for the Hooks column — the exact surface the hook fail-open lived on."
---

# ADR-081 — Security as the sixth first-class build-philosophy value

## Status

**Accepted.** Ratified by the operator's approval of the S2 governance amendment at the v3.73 Stage-4 Plan Review ("S2 governance amendment — APPROVED + ADR authored in-slice") and re-confirmed at the Collective Review scope-lock (Security = 6th first-class value, ADR-081 → `core/ADRs/`, batch-ratified). Recorded at authoring because the deciding gate — operator approval of the value-elevation — already ran; the Deep Stage-9 review verifies implementation conformance, it does not re-decide the elevation. This ADR is the durable record of the charter amendment the approvals fixed.

## Context

The platform's build-philosophy charter ([`build-philosophy.md`](../disciplines/build-philosophy.md)) is a naming-and-routing spine: it names the first-class engineering values and makes their enforcement **coverage** across every toolkit surface (skills, agents, hub/spokes, hooks, slash-commands) visible in a philosophy × surface matrix, where an empty cell is a **named gap**. Two security advisories — **GHSA-9cjm-v22x-4x33** (the PreToolUse hooks failed OPEN on a missing `jq`, silently disabling the credential/egress/destructive/fs-boundary/MCP perimeter on a documented brew-only install) and **GHSA-rw36** (stored XSS in the eval-viewer) — shipped to a **public clone-to-install** repo and were caught by **external** review, not by any internal gate.

The upstream root cause is a charter gap, not only the two code defects. `build-philosophy.md` enumerated **five** values with **no Security**, and its gap-detector only fires for cells that *exist*. With no Security row, a missing security enforcer could never appear as an empty cell — the charter's own gap-finder was **structurally blind** to the entire security class. Compounding it, the coding-domain best-practice guide (`software.md`) carried **zero** security content and was marked `n/a` for the Hooks column — precisely the surface the hook fail-open lived on. A fix that only patched the two instances would leave the next new surface shipping with no security obligation, because nothing in the charter represented the class.

## Decision

Elevate **Security** to the **sixth first-class engineering value** in `build-philosophy.md`, alongside Scalability, Best-Practice-per-Domain, Maintainability, Simplicity, and Stability. Concretely:

**D1 — A first-class value row + a full coverage-matrix row.** Security gains a value-table entry (fail-closed controls · validated input · context-encoded output · injection denied by construction) and a philosophy × surface matrix row, so a missing security enforcer on any surface now surfaces as a **named GAP** the charter's gap-finder can see. The matrix row lands with honest GAP markings: **Hooks** populated (the real enforcers), **Agents** + **Hub / Spokes** GAP, **Skills** design-time with the output-encoding enforcer in flight, **Slash-commands** `n/a`.

**D2 — Introduced paired with its first enforcer, never naming-only.** The value ships with a proven enforcer: the behavioral `hook-fail-closed.test.sh` (glob-derived fail-closed meta-test) + the `software.md §Security` fail-closed standard + the static `check-hook-dep-hardening.sh` guard + the `lib/dep-resolve.sh` resolver. A value with no enforcer is a shelf document — the exact failure mode the retro indicts — so the `BP — coding × Hooks` cell is flipped `n/a` → enforced in the same change.

**D3 — Home in `core/ADRs/`.** `build-philosophy.md` is core-scoped and the value system is a platform-wide charter concern, not a release/pipeline (SDLC) decision, so this record lives in `core/ADRs/`, not `release/ADRs/`.

## Alternatives rejected

| Option | Trade-off | Verdict |
|---|---|---|
| **A. Security as a cross-cutting *discipline*, not a value** | Disciplines get a matrix row too, but the platform models disciplines as single-rule behavioral invariants (read-before-edit, track-all-edits) *without* a codified domain body. Security has a codified best-practice body (fail-closed / input-validation / output-encoding / injection) with authoritative sources — the hallmark of a **value** (cf. BP-per-Domain's coding/governance/process). | **Rejected** — misclassifies a domain-bodied value as a bare discipline. |
| **B. No charter change — enforce via CI/SAST only (tests + lints, no value row)** | Fixes the two instances but leaves the **structural blindness**: the next new surface still ships with no security obligation because nothing represents the class. | **Rejected** — leaves the upstream-blocking finding unaddressed. |
| **C. A separate `security-philosophy.md` doc** | Fragments the single coverage matrix that IS the charter's purpose (one surface making coverage visible). | **Rejected** — defeats the spine. |
| **D (chosen). 6th value + matrix row, paired with first enforcer** | Adds one row + a downstream cascade (README enum, DP register). Makes security GAPs first-class and auditable. | **Chosen.** |

## Consequences

- **+** Security GAPs on Agents / Hub-Spokes / Slash-commands become **named backlog**, not silent omissions; the charter's gap-finder can now see the security class.
- **+** The Hooks cell is the **first populated Security enforcer**; the paired `hook-fail-closed.test.sh` proves the value lands GREEN with an enforcer, not as a naming-only row.
- **+** The in-flight output-encoding enforcer (S1, this release) has a named home — the Security × Skills cell — to populate on landing, closing the GHSA-rw36 class at the charter level.
- **+** This ADR closes the residual ADR-078 §Consequences flagged: `block-autonomy-ceiling`'s Tier-0 floor no longer fails open under enforce when `jq` is unresolvable (the mode-aware dependency-gate fix is Security's first conformance case, shipped in this same slice).
- **−** The charter grows 5 → 6, cascading to every "five first-class values" restatement — reconciled in this change (`README.md` value enum, `design-principle-register.md` DP-6/DP-7 line pins + new DP-8).
- **−** The workspace-root `CLAUDE.md` "Build-philosophy coverage" bullet enumerates the five values and lives **outside this git repo**; it will read "five" until updated out-of-band, or reworded to cite the charter without enumerating. Flagged for the operator, not silently dropped.

## Reversibility

**CHEAP** / Confidence **HIGH**. The amendment is a naming/routing doc row plus a cascade of enumerations; removing it is a doc edit and a git revert of the single PR. The paired enforcer (the behavioral test) is additive — reverting the charter row does not remove the fail-closed protection the test locks.

## Related ADRs

- [ADR-078](ADR-078-security-hook-dependency-resolution-posture.md) — security-hook dependency-resolution posture (the fail-closed *fix*). ADR-081 elevates the *value system* that fix belongs to, and closes the `block-autonomy-ceiling` enforce-mode residual ADR-078 §Consequences named.
