<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
---
title: ADR-045 — Memory SSOT model — the generalized cross-surface read/write contract across all four memory types
status: Proposed (supersedes ADR-029; flips to Accepted at the Stage 9 review)
date: 2026-06-26
release: 16-knowledge-management-discipline
deciders: "Workspace owner (architecture refined + ratified at the Stage 9 review); design authored at Stage 5 Solutioning"
supersedes: ADR-029
tags: [architecture, knowledge-management, memory, ssot, cross-surface, four-type-memory, no-shadow-ssot, contract, reversibility]
---

# ADR-045 — Memory SSOT model — the generalized cross-surface read/write contract

## Status

**Proposed — supersedes [ADR-029](ADR-029-memory-corpus-ssot-boundary.md).** ADR-029 resolved one boundary — the SSOT cut between codified *Knowledge* and the operator memory store — as a deliberate first slice of a four-type memory architecture, and named its own revisit trigger: *"When the unified read/write contract is ratified, re-open this ADR to reconcile the Knowledge cut into it."* This ADR is that reconciliation. It generalizes ADR-029's Knowledge cut into a single cross-surface contract spanning all four memory types (Work / Knowledge / People / Learning). Flips to Accepted at the Stage 9 review.

## Context

The platform holds memory across several surfaces — the codified corpus, the operator auto-memory store (`~/.claude/memory/`), governance context files, operational state and trackers, the operator-local people roster, and `operator.toml`. ADR-029 ratified the SSOT for **one** pair (codified Knowledge ↔ the memory store) and explicitly deferred the rest: a unified cross-surface read/write contract, the People surface, the operational-state lifecycle, and active-use adoption were *named* but unresolved. With the memory-type taxonomy and four-axis reconciliation now in place ([`knowledge-architecture.md §2.1`](../disciplines/knowledge-architecture.md#four-type-reconciliation)) and the people-capability/coverage graph shipped ([`people-coverage-graph.md`](../disciplines/people-coverage-graph.md)), the remaining surfaces can be brought under one contract.

## Decision

1. **One cross-surface contract governs read-vs-write for every memory surface.** [`core/disciplines/memory-architecture.md`](../disciplines/memory-architecture.md) is the SSOT *contract surface*: a per-surface table enumerating every surface with its memory-type(s), reader(s), writer(s), write-authority (Autonomy Tier), update cadence, read-only/auto-write/operator-write-only class, and trigger. It is the one place an agent consults to decide read-vs-write and where a fact belongs.

2. **The no-shadow-SSOT invariant generalizes from the Knowledge cut to all four types** — moved **verbatim** from ADR-029 § The memory architecture and [`knowledge-architecture.md §6`](../disciplines/knowledge-architecture.md#no-shadow-ssot):

   > **No-shadow-SSOT invariant.** A fact has exactly one source of truth — the SSOT surface of its memory type. No surface holds a second, shadowing copy of another surface's SSOT. A shadow copy can drift, and an agent reading it lets the copy silently override its owner. Codified Knowledge appears in memory only as a pointer to its corpus home (a temporary eviction-pointer while an encode issue is in flight, or a durable cross-reference), never as a duplicate of the governed text.

3. **The per-type SSOT homes are fixed** (each unchanged from where it already lives — this ADR assigns, it does not relocate): **Work** → the operational surface (the `projects/` tree + state files); **Knowledge** → the codified corpus when universal (the K1 class — ADR-029's Knowledge cut, preserved); **People** → the operator-local roster (`people-roster.yaml`) plus `CLAUDE.md §Workspace Owner` for identity, never repo-tracked; **Learning** → the operator auto-memory store, which remains the graduation source for Knowledge.

4. **The encode-and-evict lifecycle becomes the Knowledge instance of a general graduation lifecycle.** ADR-029's VERIFY-CORPUS-gated, archive-first encode-and-evict path is preserved unchanged as the Knowledge↔corpus graduation; the contract frames it as one type's instance of the cross-surface flow rule (a fact moves to its SSOT home, then any non-SSOT copy is reduced to a pointer).

5. **The contract is the index, not the union of every surface spec.** It holds one row per surface and cites each surface's normative home (the People graph view, the operational-tracker inventory, the Knowledge↔corpus boundary) rather than copying it — copying a home's fields into the contract would itself be a shadow SSOT. The enforcement gate (a `deploy.sh --check` analog) is **deferred** to a follow-up, matching ADR-029's warn-mode-initial posture for Check 36.

## Consequences

- **One home for the read/write decision.** An agent no longer reasons per-surface from scattered rules; the contract table is the single lookup. The shadow-SSOT drift vector ADR-029 closed for the Knowledge cut is now closed for all four types under one invariant.
- **ADR-029 is preserved as a historical record.** It is not rewritten in place (immutable-ADR posture); it carries a supersession pointer to this ADR, and its Knowledge cut + no-shadow invariant move into this contract verbatim. The Knowledge↔corpus boundary, lifecycle, and Check 36 remain operative — this ADR generalizes, it does not retract.
- **Extensible by construction.** A new memory surface or type is added as a contract row with its SSOT home; the invariant holds unchanged. The contract cites rather than copies, so each surface's normative spec stays single-home.
- **Doc-only at this version.** The contract ships as a discipline doc plus one citing consumer; no executable surface changes. The enforcement gate is a tracked follow-up, not a release gate.

## Reversibility

**CHEAP / Confidence HIGH.** The contract doc, this ADR, the supersession pointer, and the citing-consumer + link edits are additive doc/governance changes — `git revert -m 1` restores ADR-029 as the operative record and removes the contract. No schema, skill binding, or executable surface is touched. Confidence is HIGH that a cross-surface contract belongs in one document: the four-type taxonomy and the shipped people-graph are in place, and ADR-029 itself specified this reconciliation as its revisit trigger.

## Related ADRs

- [ADR-029 — Memory SSOT model — corpus-SSOT for codified Knowledge](ADR-029-memory-corpus-ssot-boundary.md): **superseded by this ADR.** The Knowledge cut this contract generalizes; its no-shadow invariant moves here verbatim and its encode-and-evict lifecycle becomes the Knowledge instance of the general graduation flow.
- [ADR-040 — Leadership-owner fields are typed Person refs with an external free-text fallback](ADR-040-leadership-owner-person-ref.md): governs the People surface's write-authority (operator-write-only; refs resolve through a clarification path, never silently auto-created) that the contract's People row cites.
