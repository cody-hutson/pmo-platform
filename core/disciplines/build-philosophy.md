---
title: Build-Philosophy Charter
purpose: The platform's first-class engineering values (Scalability, Best-Practice-per-Domain, Maintainability, Simplicity, Stability) plus two cross-cutting disciplines (read-before-edit, track-all-edits), and a philosophy × surface coverage matrix that maps each value to the artifact already enforcing it across every toolkit surface (skills, agents, hub/spokes, hooks, slash-commands). Names and routes; does not restate. An empty matrix cell is a named gap, not a silent omission.
type: reference
kind: disciplines
status: Canonical
reversibility: CHEAP / Confidence HIGH
version: v1.0
composes_with:
  - knowledge-architecture.md
  - ../standards/duplicate-source-discipline.md
  - ../specs/reversibility-protocol.md
  - review-discipline-principles.md
  - decision-discipline.md
consumers: "skill authors/reviewers (pmo-skill-refiner, pmo-skill-editor, build-reviewer, pmo-qa-auditor); Stage 4 Planning + Stage 5 Solutioning personas; hook / slash-command / agent authors; any contributor changing a toolkit surface"
---
<!-- reference-durability: allow-link -->

# Build-Philosophy Charter

## §Purpose

The platform is built on a small set of engineering values. Their *content* is already
codified — deeply — across the [`core/disciplines/`](README.md) docs, the
`core/standards/`, the [`core/ADRs/`](../ADRs/README.md) set, and the `core/hooks/`
guards. What was missing is a **spine**: a single surface that (1) names these values as
first-class and (2) makes their enforcement **coverage** across every toolkit surface
**visible and auditable**.

This charter is that spine. It is a **naming-and-routing instrument, not a restatement**:
each value's binding rule lives in its enforcing artifact, and this document points to it.
The load-bearing artifact is the **coverage matrix** (§Coverage matrix) — populating it is
the act that surfaces the toolkit's governance gaps.

> **Single-source discipline.** Per [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md),
> every cell in this charter is a **pointer** to where a value is enforced — never a copy
> of the rule. If a cell ever restates a rule body, that is a defect: it makes this charter
> a drift target and violates the maintainability value it codifies. Cite, do not duplicate.

## §The build philosophies

Five first-class values, plus two cross-cutting disciplines. (The disciplines are listed
separately because they apply to *every* domain and surface, rather than being a
best-practice of one domain.)

| # | Value | One-line principle (the rule lives in the cited enforcer, not here) |
|---|---|---|
| 1 | **Scalability** | Parameterize over hardcode; compose modular units; tier knowledge so the platform grows without re-architecture. |
| 2 | **Best Practice per Domain** | Each work domain — **coding**, **governance**, **process** — is built against its codified best-practice reference, applied at design and checked at review. |
| 3 | **Maintainability** | One source per fact; cite-don't-duplicate; minimal addition. A change should not create a second place that must be kept in sync. |
| 4 | **Simplicity** | Smallest change that achieves the goal; surgical edits; no presumptive feature build (YAGNI, with malleability work exempted). |
| 5 | **Stability** | Reversibility-tiered decisions; drift guards and canaries; version-skew + tamper detection; no silent failure. |
| D1 | **Read-before-edit** *(cross-cutting discipline)* | Read the target artifact fully before editing it; the specifier vouches, not just the executor. |
| D2 | **Track-all-edits** *(cross-cutting discipline)* | No ungoverned changes — every change to a governed surface routes through issue → plan → PR, with the diff/history as the audit trail. |

## §Coverage matrix (philosophy × surface)

Rows = the values + disciplines above. Columns = the five toolkit surfaces. Each cell
names the **enforcing artifact** (full path in §Enforcer citations) or flags a **GAP**
(no enforcer) / **thin** (covered only indirectly, e.g. through a host skill). `n/a` =
the value does not apply to that surface.

| Value \ Surface | Skills | Agents | Hub / Spokes | Hooks | Slash-commands |
|---|---|---|---|---|---|
| **Scalability** | `knowledge-architecture` · `universal-vs-localized-context` · ADR-006/007 | **GAP** | `methodology-parameterization-v1` | `composition-surface` boundary | **GAP** |
| **BP — coding** | `domain-best-practices/software` | thin | (Stage-5/7 review) | n/a | n/a |
| **BP — governance** | `domain-best-practices/governance` · `decision-discipline` | thin | `release-process` | n/a | n/a |
| **BP — process** | (`discovery`/`decision`/`review` disciplines) | **GAP** | pipeline `stage-*` · `release-process` | n/a | **GAP** · *no `process.md` domain doc* |
| **Maintainability** | `duplicate-source-discipline` · `reference-durability-standard` · `framework-corpus-discipline` | **GAP** | cite-not-duplicate (ADR-003) | Check 9/11/13 · `doc-link-maintenance-protocol` | rules-mirror (Check 9) |
| **Simplicity** | `software.md` §YAGNI · `principal-standard-checklist` | thin (ADR-020) | `release-process` Tier-1 `[ADJUST]` | minimal by design | **GAP** |
| **Stability** | `reversibility-protocol` · `version-field-semantics` · `failure-mode-standard` · `canonical-skill-structure` | **GAP** | reversibility in stage outputs | ADR-014 tamper · `bypass-mode-readiness` · version-skew | Check 30 quoting (partial) |
| **D1 — read-before-edit** | `review-discipline-principles` (anti-laziness 1/3/6/10) · `principal-standard-checklist` §C3 | **GAP** | review discipline | `block-skill-direct-edit` (narrow) | **GAP** |
| **D2 — track-all-edits** | `skill-deployment` dual-gate · `version-field-semantics` | thin | `release-process` self-governance | `bypass-mode-readiness` audit · Check 9/11/13 | rules-mirror (partial) |

## §Systemic finding — the Agents surface is the under-governed column

The matrix's headline is read **down the Agents column**: agents (skill-embedded
subagents) inherit their host skill's discipline *indirectly* but have **no
agent-specific enforcement** for Scalability, process best-practice, Maintainability,
Stability, or read-before-edit. [ADR-020](../ADRs/ADR-020-agent-script-promotion-ladder.md)
(agent-script promotion ladder) is the natural anchor to extend. **Slash-commands** are
the second-thinnest column (GAP on Simplicity and partial on Track-all-edits for
unregistered commands).

These empty cells are the **prioritized gap backlog** — not omissions. Three are already
in flight under the Knowledge-Architecture initiative (epic `knowledge-corpus`): the
**process** best-practice domain doc, the **read-before-edit** general-enforcement
codification, and the skill **sourcing** posture (ADR-022, below). The Agents-column gaps
are logged for sequencing, not silently dropped (per the auto-logging rule in
[`OPERATIONS.md`](../governance/OPERATIONS.md)).

## §Enforcer citations

Full relative paths for each cell reference above (single-sourced here so the matrix stays
terse):

- **Scalability** — [`knowledge-architecture.md`](knowledge-architecture.md), [`universal-vs-localized-context.md`](../standards/universal-vs-localized-context.md), [ADR-006](../ADRs/ADR-006-skill-to-module-map.md) / [ADR-007](../ADRs/ADR-007-core-module-boundary.md), [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md).
- **BP — coding** — [`domain-best-practices/software.md`](../standards/domain-best-practices/software.md).
- **BP — governance** — [`domain-best-practices/governance.md`](../standards/domain-best-practices/governance.md), [`decision-discipline.md`](decision-discipline.md), [`release-process.md`](../../release/governance/release-process.md).
- **BP — process** — pipeline [`stage-*.md`](../../release/references/pipeline/), [`release-process.md`](../../release/governance/release-process.md), [`discovery-discipline.md`](discovery-discipline.md) / [`decision-discipline.md`](decision-discipline.md) / [`review-discipline-principles.md`](review-discipline-principles.md). *Domain doc `core/standards/domain-best-practices/process.md` is a GAP (pending).*
- **Maintainability** — [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md), [`reference-durability-standard.md`](../standards/reference-durability-standard.md), [`doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md), [`framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md), [ADR-003](../ADRs/ADR-003-operating-model-composition.md).
- **Simplicity** — [`domain-best-practices/software.md`](../standards/domain-best-practices/software.md) §YAGNI, [`principal-standard-checklist.md`](../standards/principal-standard-checklist.md), [`release-process.md`](../../release/governance/release-process.md) (Tier-1 adjust), [ADR-020](../ADRs/ADR-020-agent-script-promotion-ladder.md).
- **Stability** — [`reversibility-protocol.md`](../specs/reversibility-protocol.md), [`version-field-semantics.md`](../standards/version-field-semantics.md), [`failure-mode-standard.md`](../specs/failure-mode-standard.md), [`canonical-skill-structure.md`](../standards/canonical-skill-structure.md), [ADR-014](../ADRs/ADR-014-managed-section-two-hash-tamper-detection.md), [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md). Skill↔Anthropic sourcing posture: [`anthropic-base-vs-build-registry.md`](../specs/anthropic-base-vs-build-registry.md) (ledger) governed by [ADR-022](../ADRs/ADR-022-skill-sourcing-coupling-posture.md) (skill sourcing-coupling posture).
- **D1 — read-before-edit** — [`review-discipline-principles.md`](review-discipline-principles.md), [`principal-standard-checklist.md`](../standards/principal-standard-checklist.md), [`block-skill-direct-edit.sh`](../hooks/block-skill-direct-edit.sh) (skill-edit-path only; general enforcement is a GAP, in flight).
- **D2 — track-all-edits** — [`skill-deployment.md`](../rules/skill-deployment.md), [`release-process.md`](../../release/governance/release-process.md), [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md), [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md) (Check 9/11/13).

## §Applying the charter (review-wiring)

The charter is **consulted, not memorized**. When work changes a toolkit surface, the
relevant **column** is the checklist:

- **Stage 4 Planning / Stage 5 Solutioning** — when a release touches a surface, the
  Solutioning persona reads that surface's column and confirms each applicable value is
  satisfied or its gap is acknowledged.
- **Review skills** — [`build-reviewer`](../../release/skills/build-reviewer) and
  [`pmo-qa-auditor`](../skills/pmo-qa-auditor) treat the column as a review dimension for
  the surface under change.
- **Per-surface authoring** — skill/agent/hook/command authors check their surface's
  column at authoring time.

A value with a **GAP** in the relevant cell is a known, accepted limitation — review notes
it rather than re-discovering it. A *newly* discovered empty cell is filed per the
auto-logging rule, then added here.

## §Maintenance

- **New enforcer lands** → update the cell to point to it (was GAP → now cited).
- **New surface** → add a column; assess each value against it.
- **New value/discipline** → add a row; assess each surface against it.
- **Cite-only invariant** → cells reference; they never restate. The enforcer remains the
  single source of its rule (this is the Maintainability value applied to the charter
  itself).

This charter is K1 codified-knowledge per
[`knowledge-architecture.md`](knowledge-architecture.md); it composes with — and does not
restate — the disciplines and standards it routes to.
