---
title: Build-Philosophy Charter
purpose: The platform's first-class engineering values (Scalability, Best-Practice-per-Domain, Maintainability, Simplicity, Stability, Security, Portability) plus two cross-cutting disciplines (read-before-edit, track-all-edits), and a philosophy × surface coverage matrix that maps each value to the artifact already enforcing it across every toolkit surface (skills, agents, hub/spokes, hooks, slash-commands). Names and routes; does not restate. An empty matrix cell is a named gap, not a silent omission.
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

Seven first-class values, plus two cross-cutting disciplines. (The disciplines are listed
separately because they apply to *every* domain and surface, rather than being a
best-practice of one domain.)

| # | Value | One-line principle (the rule lives in the cited enforcer, not here) |
|---|---|---|
| 1 | **Scalability** | Parameterize over hardcode; compose modular units; tier knowledge so the platform grows without re-architecture. |
| 2 | **Best Practice per Domain** | Each work domain — **coding**, **governance**, **process** — is built against its codified best-practice reference, applied at design and checked at review. |
| 3 | **Maintainability** | One source per fact; cite-don't-duplicate; minimal addition, and **extend-before-create** — a change should not create a second place that must be kept in sync, so extend existing infrastructure before building net-new (net-new must be justified against the in-place alternative). |
| 4 | **Simplicity** | Smallest change that achieves the goal; surgical edits; no presumptive feature build (YAGNI, with malleability work exempted). |
| 5 | **Stability** | Reversibility-tiered decisions; drift guards and canaries; version-skew + tamper detection; no silent failure. |
| 6 | **Security** | Controls fail closed when they cannot evaluate their rule; untrusted input is validated and output is context-encoded at its sink; injection surfaces are denied by construction. |
| 7 | **Portability** | The governed core binds to an external system only through an adapter; the external system's model lives inside that adapter and never redefines a governed concept; host mechanism never leaks into host-agnostic capability text. Litmus: does the governed concept survive a substrate swap? |
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
| **BP — coding** | `domain-best-practices/software` *(skill-wired)* | thin | (Stage-5/7 review) | `software §Security` · `dep-resolve` · `hook-fail-closed.test` | n/a |
| **BP — governance** | `domain-best-practices/governance` *(skill-wired — `pmo-program-manager` · `release-planner`)* · `decision-discipline` | thin | `release-process` | n/a | n/a |
| **BP — process** | `domain-best-practices/process` *(skill-wired — `pmo-scrum-master` · `pmo-release-train-engineer`)* · (`discovery`/`decision`/`review` disciplines · `ticket-architecture-reconciliation`) | thin | pipeline `stage-*` · `release-process` | n/a | n/a |
| **BP — change** | `framework-catalog` + `change-management/references` suite *(skill-self-bundled — no shared guide; ADR-057)* | thin | (Stage-5 design-consume) | n/a | n/a |
| **Maintainability** | `duplicate-source-discipline` · `reference-durability-standard` · `framework-corpus-discipline` | **GAP** | cite-not-duplicate (ADR-003) · extend-before-create (SR-G6 §7.2) | Check 9/11/13 · `doc-link-maintenance-protocol` | rules-mirror (Check 9) |
| **Simplicity** | `software.md` §YAGNI · `principal-standard-checklist` | thin (ADR-020) | `release-process` Tier-1 `[ADJUST]` | minimal by design | **GAP** |
| **Stability** | `reversibility-protocol` · `version-field-semantics` · `failure-mode-standard` · `canonical-skill-structure` | **GAP** | reversibility in stage outputs | ADR-014 tamper · `bypass-mode-readiness` · version-skew | Check 30 quoting (partial) |
| **Security** | `domain-best-practices/software §Security` *(design-time)* · `semgrep/rules/template-context-xss` (R1/R2/R3) · `security.yml` semgrep job | **GAP** | **GAP** *(secure-SDLC checklist not yet codified)* | `lib/dep-resolve` · `check-hook-dep-hardening` (static) · `hook-fail-closed.test` (behavioral) · ADR-078 / ADR-081 | n/a *(runtime security enforced at the Hooks perimeter, not per prompt-file command)* |
| **Portability** | `Check 42` host-binding-leak (scans `SKILL.md` + `references/`) · `knowledge-architecture` §4.1 · `repo-host-adapter-versioning` §5 | **GAP** | thin (`Check 42` spec-text scan; no design-time adapter gate) | n/a *(hooks are the host-mechanism perimeter — the adapter analogue; host binding is their function, not a leak)* | **GAP** |
| **D1 — read-before-edit** | `review-discipline-principles` (anti-laziness 1/3/6/10) · `principal-standard-checklist` §C3 | **GAP** | review discipline | `block-skill-direct-edit` (narrow) | **GAP** |
| **D2 — track-all-edits** | `skill-deployment` dual-gate · `version-field-semantics` | thin | `release-process` self-governance | `bypass-mode-readiness` audit · Check 9/11/13 | rules-mirror (partial) |

## §Systemic finding — the Agents surface is the under-governed column

The matrix's headline is read **down the Agents column**: agents (skill-embedded
subagents) inherit their host skill's discipline *indirectly* but have **no
agent-specific enforcement** for Scalability, Maintainability,
Stability, or read-before-edit. [ADR-020](../ADRs/ADR-020-agent-script-promotion-ladder.md)
(agent-script promotion ladder) is the natural anchor to extend. **Slash-commands** are
the second-thinnest column (GAP on Simplicity and partial on Track-all-edits for
unregistered commands).

These empty cells are the **prioritized gap backlog** — not omissions. Two remain
in flight under the Knowledge-Architecture initiative (epic `knowledge-corpus`): the
**read-before-edit** general-enforcement codification and the skill **sourcing** posture
(ADR-023, below); the **process** best-practice domain doc has since shipped
([`domain-best-practices/process.md`](../standards/domain-best-practices/process.md)),
completing the three best-practice domain guides. The Agents-column gaps
are logged for sequencing, not silently dropped (per the auto-logging rule in
[`OPERATIONS.md`](../governance/OPERATIONS.md)).

The newly-added **Security** row (value 6, per [ADR-081](../ADRs/ADR-081-security-sixth-first-class-value.md)) extends this backlog: its **Agents** and **Hub / Spokes** cells are GAP (no agent-level enforcement, and the secure-SDLC checklist is not yet codified), while its **Hooks** cell is the **first populated Security enforcer** — `lib/dep-resolve` + the static `check-hook-dep-hardening` guard + the behavioral `hook-fail-closed.test`, governed by ADR-078 / ADR-081. Security is therefore introduced *with* a proven enforcer, not as a naming-only row — the root-cause fix for a charter that was structurally blind to the security class (a matrix with no Security row can never surface a missing security enforcer as an empty cell).

The **Portability** row (value 7, per [ADR-098](../ADRs/ADR-098-portability-seventh-first-class-value.md)) extends this backlog on both thin columns at once: its **Agents** and **Slash-commands** cells are GAP (neither surface is inside the `Check 42` scan set, so a host tool prescribed as *the* mechanism in an agent definition or a command prompt is invisible), and its **Hub / Spokes** cell is thin — `Check 42` scans the pipeline and governance *spec text*, but no design-time gate scores the work under design for adapter-boundary conformance. Its **Skills** cell is populated by a real enforcer: `Check 42` covers every `SKILL.md` and skill `references/` file, so Portability — like Security before it — is introduced *with* a working detector rather than as a naming-only row.

The three **BP-domain-guide × Skills** cells were a distinct case from the empty cells
above: they named an enforcer (`domain-best-practices/{software,governance,process}.md`)
that no skill consumed. That case is now **closed** — each guide is both shipped *and*
skill-wired, cited as a design-time anchor by its consuming skills: five for software,
eight for governance, four for process. No BP-domain guide remains authored-but-unconsumed.

## §Enforcer citations

Full relative paths for each cell reference above (single-sourced here so the matrix stays
terse):

- **Scalability** — [`knowledge-architecture.md`](knowledge-architecture.md), [`universal-vs-localized-context.md`](../standards/universal-vs-localized-context.md), [ADR-006](../ADRs/ADR-006-skill-to-module-map.md) / [ADR-007](../ADRs/ADR-007-core-module-boundary.md), [`methodology-parameterization-v1.md`](../../release/references/specs/methodology-parameterization-v1.md).
- **BP — coding** — [`domain-best-practices/software.md`](../standards/domain-best-practices/software.md).
- **BP — governance** — [`domain-best-practices/governance.md`](../standards/domain-best-practices/governance.md), [`decision-discipline.md`](decision-discipline.md), [`release-process.md`](../../release/governance/release-process.md).
- **BP — process** — [`domain-best-practices/process.md`](../standards/domain-best-practices/process.md), pipeline [`stage-*.md`](../../release/references/pipeline/), [`release-process.md`](../../release/governance/release-process.md), [`discovery-discipline.md`](discovery-discipline.md) / [`decision-discipline.md`](decision-discipline.md) / [`review-discipline-principles.md`](review-discipline-principles.md) / [`ticket-architecture-reconciliation.md`](ticket-architecture-reconciliation.md).
- **BP — change** — [`framework-catalog.md`](../specs/framework-catalog.md) (the change-methodology registry rows) + the [`change-management/references/`](../../operations/skills/change-management) suite; **skill-self-bundled, no shared `domain-best-practices/change.md`** per [ADR-057](../ADRs/ADR-057-change-domain-best-practice-self-bundled.md).
- **Maintainability** — [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md), [`reference-durability-standard.md`](../standards/reference-durability-standard.md), [`doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md), [`framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md), [ADR-003](../ADRs/ADR-003-operating-model-composition.md). Extend-before-create enforcer: [`stage-05-solutioning.md §7.2 SR-G6`](../../release/references/pipeline/stage-05-solutioning.md) (Stage-5 pipeline-stage gate; Hub/Spokes surface), decided in [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md).
- **Simplicity** — [`domain-best-practices/software.md`](../standards/domain-best-practices/software.md) §YAGNI, [`principal-standard-checklist.md`](../standards/principal-standard-checklist.md), [`release-process.md`](../../release/governance/release-process.md) (Tier-1 adjust), [ADR-020](../ADRs/ADR-020-agent-script-promotion-ladder.md).
- **Stability** — [`reversibility-protocol.md`](../specs/reversibility-protocol.md), [`version-field-semantics.md`](../standards/version-field-semantics.md), [`failure-mode-standard.md`](../standards/failure-mode-standard.md), [`canonical-skill-structure.md`](../standards/canonical-skill-structure.md), [ADR-014](../ADRs/ADR-014-managed-section-two-hash-tamper-detection.md), [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md). Skill↔Anthropic sourcing posture: [`anthropic-base-vs-build-registry.md`](../specs/anthropic-base-vs-build-registry.md) (ledger) governed by [ADR-023](../ADRs/ADR-023-skill-sourcing-coupling-posture.md) (skill sourcing-coupling posture).
- **Security** — [`domain-best-practices/software §Security`](../standards/domain-best-practices/software.md), [`dep-resolve.sh`](../hooks/lib/dep-resolve.sh), [`check-hook-dep-hardening.sh`](../hooks/tests/check-hook-dep-hardening.sh) (static grep guard) / [`hook-fail-closed.test.sh`](../hooks/tests/hook-fail-closed.test.sh) (behavioral, glob-derived), [ADR-078](../ADRs/ADR-078-security-hook-dependency-resolution-posture.md) / [ADR-081](../ADRs/ADR-081-security-sixth-first-class-value.md). The context-aware output-encoding enforcer is the `§Security` **Output encoding** standard plus the custom [`template-context-xss.yml`](../security/semgrep/rules/template-context-xss.yml) ruleset (R1 transport-taint · R2 raw-HTML DOM sink · R3 script-context placeholder) wired as the [`security.yml`](../../.github/workflows/security.yml) `semgrep` job — it populates the Security × Skills cell; Agents + Hub/Spokes stay GAP (no agent-level or secure-SDLC-checklist security enforcer yet).
- **Portability** — [`knowledge-architecture.md`](knowledge-architecture.md) §4.1 (the HOST-BINDING-LEAK class + the canonical adapter-seam rule), [`repo-host-adapter-versioning.md`](../standards/repo-host-adapter-versioning.md) (§2 the four host-agnostic operations, §5 the adapter conformance checklist), [`operator.toml.template`](../config/operator.toml.template) `[adapters]` (the config-selection seam), [ADR-017](../ADRs/ADR-017-distribution-architecture.md) / [ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md) (adapters-home + selector table), [ADR-036](../../release/ADRs/ADR-036-version-claim-determinism.md) (the host-agnostic capability precedent), [ADR-098](../ADRs/ADR-098-portability-seventh-first-class-value.md) (this value's elevation). Automated enforcer: `Check 42` host-binding-leak in [`deploy.sh`](../deploy/deploy.sh) via [`check-host-binding.py`](../deploy/tools/check-host-binding.py) + [`skip-host-binding-check.txt`](../deploy/allowlists/skip-host-binding-check.txt) (warn-mode initial). The **path-axis** sibling (`Check 43` path-portability) is enforced under **Scalability** / DP-1's parameterize-over-hardcode, not here — the two leak axes route to distinct principles by design.
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
