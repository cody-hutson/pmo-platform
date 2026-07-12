---
title: Design-Principle Register — Agent Operating Principles
purpose: The auditable index of agent-operating design principles the hub's Decision Briefing is checked against — the structural twin of the upstream-reference catalog's Anthropic-compatibility axis.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the hub's Decision Briefing (agent-operating-principles audit axis); build-reviewer and pmo-qa-auditor; upstream-reference-catalog.md (structural twin)
---
<!-- reference-durability: allow-link -->
# Design-Principle Register — Agent Operating Principles

**Origin:** the decision-rendering-standardization milestone (Decision Briefing conformance-audit keystone). **Tier:** K1 codified-knowledge reference (per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md)). **Primary consumer:** the Operator Decision Gate's `### Design-Principle Conformance` subsection at Stage 4 (per [`hub-spoke-bridge.md` § D-Gate Template](../../release/references/how-to/hub-spoke-bridge.md)). **Secondary consumers:** the Stage 8 QA Design-Principle Conformance dimension; the per-gate-class framing directive `principles_emphasis` field (per [`engagement-charter.md`](../specs/engagement-charter.md)).

## Purpose

This register makes the hub's Decision Briefing auditable along the **agent-operating-principles** axis — the structural twin of [`upstream-reference-catalog.md`](upstream-reference-catalog.md), which makes the Anthropic-compatibility axis auditable. Each entry is an **index** of a design principle already defined in a governing document; a D-Gate or QA verdict scores an option ALIGNED / `**CONFLICT.**` / N-A against the entries whose `scope_predicate` matches the option's change surface, citing the entry id + its `governing_doc`.

## Index-only discipline (invariant)

Every entry's `statement` is a faithful index of a principle **already defined at its `governing_doc`**. No entry originates a principle. If a principle's normative home moves, update `governing_doc`; never let the register become the source. This mirrors the upstream catalog's index-not-originator discipline.

## Schema (per-entry)

| Field | Type | Purpose |
|---|---|---|
| `principle_id` | `DP-N` | Stable identifier (DP = Design Principle). Referenced by D-Gate/QA verdicts and by the per-gate-class framing directive `principles_emphasis` field. |
| `name` | string | Short principle name. |
| `statement` | string | One-line normative statement — indexed from `governing_doc`, never originated here. |
| `governing_doc` | `path:line` | Exact pin to the normative source where the principle is defined (the AC-1 resolution target + the Check 45 drift-guard target). |
| `scope_predicate` | string | The class of design surface where this principle's conformance is load-bearing (drives whether a D-Gate option must render a verdict for it). |
| `conflict_reversibility_default` | enum | Default reversibility tier a CONFLICT against this principle carries, gating annotate-vs-HALT: `CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE`. |
| `last_verified_date` | ISO date | Most recent `governing_doc` resolution check. |
| `last_verified_commit` | short SHA | Commit at verification. |

## Entries

The seed set indexes the platform's first-class engineering values + cross-cutting disciplines, defined in [`build-philosophy.md`](../disciplines/build-philosophy.md) §The build philosophies. Each `governing_doc` was verified resolving on the commit below.

| `principle_id` | `name` | `statement` (indexed from `governing_doc`) | `governing_doc` | `scope_predicate` | `conflict_reversibility_default` | `last_verified_date` | `last_verified_commit` |
|---|---|---|---|---|---|---|---|
| DP-1 | Scalability | Parameterize over hardcode; compose modular units; tier knowledge so the platform grows without re-architecture. | core/disciplines/build-philosophy.md:48 | option touches parameterization, hardcoded values, knowledge-tier placement, or module composition | MODERATE | 2026-06-22 | b84ddb6 |
| DP-2 | Best Practice per Domain | Each work domain — coding, governance, process — is built against its codified best-practice reference, applied at design and checked at review. | core/disciplines/build-philosophy.md:49 | option introduces or modifies coding / governance / process work that has a codified best-practice reference | MODERATE | 2026-06-22 | b84ddb6 |
| DP-3 | Maintainability | One source per fact; cite-don't-duplicate; minimal addition — a change should not create a second place that must be kept in sync. | core/disciplines/build-philosophy.md:50 | option creates or duplicates a fact-bearing surface (a value, rule, or schema that could need syncing) | MODERATE | 2026-06-22 | b84ddb6 |
| DP-4 | Simplicity | Smallest change that achieves the goal; surgical edits; no presumptive feature build (YAGNI, malleability work exempted). | core/disciplines/build-philosophy.md:51 | option adds a structure, feature, or step beyond the smallest change achieving the goal | CHEAP | 2026-06-22 | b84ddb6 |
| DP-5 | Stability | Reversibility-tiered decisions; drift guards and canaries; version-skew + tamper detection; no silent failure. | core/disciplines/build-philosophy.md:52 | option changes a runtime / governance surface where reversibility, drift, version-skew, or silent failure is in play | EXPENSIVE | 2026-06-22 | b84ddb6 |
| DP-6 | Read-before-edit | Read the target artifact fully before editing it; the specifier vouches, not just the executor. | core/disciplines/build-philosophy.md:54 | option specifies an edit to an existing artifact | MODERATE | 2026-07-12 | 3ec10c1 |
| DP-7 | Track-all-edits | No ungoverned changes — every change to a governed surface routes through issue → plan → PR, with the diff/history as the audit trail. | core/disciplines/build-philosophy.md:55 | option modifies a governed surface | MODERATE | 2026-07-12 | 3ec10c1 |
| DP-8 | Security | Controls fail closed when they cannot evaluate their rule; untrusted input is validated and output is context-encoded at its sink; injection surfaces are denied by construction. | core/disciplines/build-philosophy.md:53 | option adds or edits a security control, a fail-closed / input-validation / output-encoding / injection surface, or a toolkit surface's security posture | EXPENSIVE | 2026-07-12 | 3ec10c1 |

*[Extensible: additional entries accrue as new design surfaces appear; each new entry indexes an existing normative source, never originates a principle.]*

## Drift-check protocol

`deploy.sh --check` Check 45 (warn-mode initial) resolves every entry's `governing_doc` `path:line` to a real, non-empty line; an unresolvable target is flagged as drift (repoint to the principle's current normative line). Stage 13 Close re-verifies and bumps `last_verified_date` / `last_verified_commit`. A governing_doc whose `last_verified_date` is older than 90 days when cited in a verdict has the verdict note the staleness — the principle may still hold, but the entry needs re-verification (same hygiene as the upstream catalog).

## Cross-references

- D-Gate consumer: [`hub-spoke-bridge.md` § D-Gate Template — Design-Principle Conformance](../../release/references/how-to/hub-spoke-bridge.md)
- QA consumer: [`stage-08-qa-testing.md` § Design-Principle Conformance dimension](../../release/references/pipeline/stage-08-qa-testing.md)
- Structural-defect convention: [`decision-discipline.md` § 5 G2](../disciplines/decision-discipline.md) (omission-without-explicit-N/A on a scope-matching surface)
- Localization parent: [`decision-discipline.md` § 2.1](../disciplines/decision-discipline.md) (Mechanism 1 — Localization Check)
- Indexed charter: [`build-philosophy.md`](../disciplines/build-philosophy.md)
- Twin catalog: [`upstream-reference-catalog.md`](upstream-reference-catalog.md)

## Cutover

Applies to all D-decisions and Decision Briefings going forward.
