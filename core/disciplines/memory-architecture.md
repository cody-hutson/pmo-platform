<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Memory Architecture — the unified cross-surface read/write contract
purpose: The single SSOT contract enumerating every memory surface with its memory-type(s), reader(s), writer(s), write-authority (Autonomy Tier), update cadence, read-only/auto-write/operator-write-only class, and trigger — the one place an agent consults to decide read-vs-write and where a fact belongs.
type: reference
reversibility: CHEAP / Confidence HIGH
consumers: "core/rules/governance-files.md (citing consumer — the AC-satisfying ≥1 reference); core/governance/OPERATIONS.md (§Memory Read/Write Contract pointer); core/CLAUDE.md.template (Context File Hierarchy pointer); knowledge-architecture.md §2.1 (the type-axis authority this contract cites)"
owner: "operator-class: Workspace owner ([OPERATOR_NAME]) — per km-governance-framework §2.4 (forward-only)"
glossary_anchor: "knowledge-architecture.md §2.1 four-memory-type model (canonical Work / Knowledge / People / Learning type axis)"
---

# Memory Architecture — the unified cross-surface read/write contract

## §1 Purpose + position {#purpose}

This document is the **single cross-surface SSOT contract** for platform memory: the one place an agent consults to decide **read-vs-write** for a given memory surface, and **where a fact belongs** when it could live in more than one. It enumerates every current memory surface with its memory-type(s), reader(s), writer(s), write-authority (Autonomy Tier), update cadence, read/write class, and the trigger that fires a read or write.

It **composes with — and does not restate —** its neighbors:

- [`knowledge-architecture.md`](knowledge-architecture.md) classifies *knowledge* by universality (the K1–K5 axis) and names the four-memory-type model; its [§2.1 four-memory-type model and four-axis reconciliation](knowledge-architecture.md#four-type-reconciliation) is the **type-axis authority** this contract cites (single-home — the type definitions and the four-axis composition live there, not here).
- [`knowledge-architecture.md §6`](knowledge-architecture.md#memory-corpus-boundary) is the **Knowledge cut** — the corpus↔memory boundary, the encode-and-evict lifecycle, and the three drift classes.
- [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) (superseded by [ADR-045](../ADRs/ADR-045-cross-surface-memory-contract.md)) ratified the Knowledge cut; **ADR-045** generalizes that cut into this cross-surface contract across all four memory types.

The pairing is deliberate: `knowledge-architecture.md` **classifies** knowledge; this document **governs cross-surface read/write flow** over the four memory types it classifies. They are sibling disciplines.

---

## §2 The cross-surface contract table {#contract-table}

This is the **normative core**. Every current memory surface is a row. The columns are the eight contract dimensions: `surface` · `memory-type(s)` · `reader(s)` · `writer(s)` · `write-authority (Autonomy Tier)` · `update cadence` · `class` · `trigger`. The `class` enum is **read-only | auto-write | operator-write-only**; the `write-authority` column binds to the canonical Autonomy Tier 0–3 enum in [`autonomy-tiers.md`](../specs/autonomy-tiers.md) (do not invent a parallel authority vocabulary). The memory-type values are the Work / Knowledge / People / Learning set defined in [knowledge-architecture.md §2.1](knowledge-architecture.md#four-type-reconciliation).

| surface | memory-type(s) | reader(s) | writer(s) | write-authority (Autonomy Tier) | update cadence | class | trigger |
|---|---|---|---|---|---|---|---|
| **Codified corpus** (`core/`, `release/skills/*/SKILL.md` + `references/`, `core/rules/`) | Knowledge | all agents | Claude Code (via git PR) | **Tier 1** (operator approves the plan; PR-review is the gate) | release-cadence (version-anchored) | **operator-write-only** | a governed change (Issue + plan + PR) per No-Ungoverned-Changes |
| **`CLAUDE.md`** (+ `core/CLAUDE.md.template` seed) | Knowledge | all agents | Claude Code (via git PR) | **Tier 1** | monthly / structure-change | **operator-write-only** | drift detected vs. evidence (Document Tier 4) → propose → approve → write |
| **`core/governance/OPERATIONS.md`** | Knowledge | all agents | Claude Code (via git PR) | **Tier 1** | when protocols evolve | **operator-write-only** | governed change to PMO protocols |
| **`~/.claude/memory/`** store (+ `MEMORY.md` index) | Learning | all agents (loaded via `autoMemoryDirectory`) | Claude Code (operations) / auto-memory | **Tier 2** within bounded memory-write affordance; **Tier 1** for eviction | per-correction / on-emergence; evict at encode issue's Stage-13 | **operator-write-only** (Layer-2; an Eng PR cannot mutate it — ADR-029 + operations-bridge Rule 1) | a tacit/situated K5 learning captured; OR encode-and-evict at graduation |
| **`projects/_config/CORRECTIONS.md`** | Learning | both (Cowork + Claude Code) | Claude Code (operations) | **Tier 1** (operator gives the correction) | on every correction (Tier 1.7) | **operator-write-only** | operator issues a behavioral correction |
| **`projects/_config/SESSION_STATE.md`** | Work | session-start readers | Claude Code (operations) | **Tier 2** (auto-write at session boundary) | session-end / session-start | **auto-write** | session start (read) / session end (write per Session-End Checklist) |
| **`projects/_config/PORTFOLIO.md`** | Work | Claude Code (read for context) | Cowork (writes health data) | **Tier 2** (Cowork-owned bridge) | after any project state change | **auto-write** (by Cowork; **read-only** from Claude Code per operations-bridge.md) | a project's state changes (Cowork writes; Claude Code reads only) |
| **`projects/_config/SWAP_HANDOFF.md`** | Work | session-start (when newer than last activity) | account-switcher harness | **Tier 3** (harness auto-writes at swap) | auto at swap boundary | **auto-write** (harness; do not hand-edit) | an account-switcher swap occurs |
| **`projects/[Project]/PROJECT.md`** | Work | all agents (project context) | Claude Code (operations) | **Tier 1** (Document Tier 4 drift-detection) | per processing cycle | **operator-write-only** (drift → propose → approve) | drift detected vs. project evidence |
| **Operational trackers** (`projects/[Project]/04-PMO-Operations/` — Daily Status Log, Comms Tracker, Open Meetings, Transcript Register, RAID Log, …) | Work | the owning skills (tracker-manager, ppm-agent, comms-writer, delivery-engine) | the owning skill | **Tier 2** (auto-write, Document Tier 2) · **Tier 1** for RAID Log (Document Tier 1) | per the OPERATIONS.md Operational Artifacts cadence column | **auto-write** (RAID Log = operator-write-only / Document Tier 1) | post-transcript / post-meeting / on-send (per artifact) |
| **People surface** (operator-local `people-roster.yaml`; graph view [`core/disciplines/people-coverage-graph.md`](people-coverage-graph.md)) | People | comms-writer / tracker-manager / ppm-agent / delivery-engine (read-only over the roster) | operator (roster); ambient graph maintenance is Tier 1 | **Tier 1** (clarification queue; never auto-create per ADR-040) | ambient / event-driven (roster-touch · owner write · name surface · ref-miss) | **operator-write-only** (roster never repo-tracked — PII) | a who-does-what / coverage / ref-resolution need (the roster + the shipped read-time graph view govern this; the graph composes the roster, never forks it) |
| **`operator.toml`** (operator-config: identity values, adapters) | Work (config substrate the Work + People types draw on) | all agents (config-resolution) | operator | **Tier 1** | as config changes | **operator-write-only** | an operator-config value changes (K2/K3 parameter source per knowledge-architecture §3) |

**Reading note.** A surface may carry more than one memory-type and more than one Document-Tier (Work spans Tier-1 RAID + Tier-2 trackers); the cells name the *dominant* value with the spread parenthesized. This is the composite-multi-entity discipline already used in [`operational-artifact-inventory.md`](../specs/operational-artifact-inventory.md) §4(a) — a composite cell, not a collision.

**Surface-enumeration completeness.** The row set is the union of: (a) the four [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Context File Hierarchy tiers (CORRECTIONS / SWAP_HANDOFF / OPERATIONS / PROJECT / PORTFOLIO); (b) the `~/.claude/memory/` store; (c) the OPERATIONS.md Operational Artifacts table (collapsed to one "operational trackers" row with the spread named — the contract is a surface-level SSOT map, not a per-tracker schema, which is [`tracker-schemas.md`](../schemas/tracker-schemas.md)'s job — single-home); (d) the K1 corpus + `CLAUDE.md.template`; (e) the People surface; (f) `operator.toml`. The `08-Generated/` staging area is deliberately a **transient working surface, not a memory surface** — it holds pre-approval drafts, not durable memory — and is therefore out-of-table (see [§6](#composition-boundaries)).

---

## §3 The no-shadow-SSOT invariant {#no-shadow-ssot}

This invariant is absorbed **verbatim** from [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) § The memory architecture and [knowledge-architecture.md §6](knowledge-architecture.md#no-shadow-ssot), which ratified it for the Knowledge cut. This contract is the SSOT *contract surface* — it absorbs the invariant the ADR ratified rather than re-deriving it:

> **No-shadow-SSOT invariant.** A fact has exactly one source of truth — the SSOT surface of its memory type. No surface holds a second, shadowing copy of another surface's SSOT. A shadow copy can drift, and an agent reading it lets the copy silently override its owner. Codified Knowledge appears in memory only as a pointer to its corpus home (a temporary eviction-pointer while an encode issue is in flight, or a durable cross-reference), never as a duplicate of the governed text.

The contract **generalizes** the invariant from the Knowledge cut (ADR-029's scope) to **all four memory types**: each row's `class` column plus the per-type SSOT verdict in [knowledge-architecture.md §2.1](knowledge-architecture.md#four-type-reconciliation) together enforce "exactly one SSOT per fact" across every surface. The per-type SSOT homes are: **Work** → the operational surface (`projects/` tree + state files); **Knowledge** → the codified corpus (when universal — the K1 class); **People** → the operator-local roster (`people-roster.yaml`) + `CLAUDE.md §Workspace Owner` for identity, never repo-tracked PII; **Learning** → the operator auto-memory store (`~/.claude/memory/`), which is also the graduation source for Knowledge.

---

## §4 Read protocol {#read-protocol}

Reads are governed by the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) **Context File Hierarchy** and **Session Management** sections — this contract cites that read order and does not restate it. The session-start read order (most-to-least specific) is: SESSION_STATE.md → SWAP_HANDOFF.md (when newer than last session activity) → CLAUDE.md → CORRECTIONS.md → OPERATIONS.md → the relevant PROJECT.md. More-specific surfaces override less-specific ones on the same claim.

Two contract-level read rules layer on top of that order:

1. **Read the SSOT, not a shadow.** When a fact appears on more than one surface, read it from the surface this table names as its SSOT (the `class` + the §3 per-type SSOT home). A memory entry that points to a corpus home is read as a *pointer* — follow it to the corpus; do not treat the pointer text as authoritative.
2. **Staleness defers to the owner.** A surface's own staleness rule (e.g., the SESSION_STATE.md 2-business-day staleness flag) governs whether its read is trusted; a stale read is flagged, not silently consumed.

---

## §5 Write protocol {#write-protocol}

A write is permitted only to a surface this table marks writable for the writing agent, at or below the surface's declared Autonomy Tier. The `class` enum maps to write-authority and approval gate as follows:

| `class` | Who writes | Autonomy Tier (per [`autonomy-tiers.md`](../specs/autonomy-tiers.md)) | Approval gate (per File Management Protocol) |
|---|---|---|---|
| **read-only** | no agent writes this surface in this direction | — | n/a (a write to a read-only surface descends to its owner's path) |
| **auto-write** | the owning agent/skill writes directly, then confirms | **Tier 2** — bounded auto within declared scope | Document Tier 2 — no approval gate; confirmation step never skipped |
| **operator-write-only** | written only on operator authorization (a correction, an approved plan, a governed PR) | **Tier 1** (drafts; operator approves) or higher for governed-corpus surfaces | Document Tier 1 / Document Tier 4 — propose → approve → write |

Three contract-level write rules:

1. **Write-first-speak-second.** Never report a surface "written" before the write is executed and confirmed (CLAUDE.md guardrail). Generalizes to any externally-observable state mutation.
2. **No shadow on write.** Do not write a fact to a non-SSOT surface as a second copy. A learning that generalizes into reusable Knowledge **graduates** into the corpus and is then evicted to a pointer (the encode-and-evict lifecycle — [knowledge-architecture.md §6](knowledge-architecture.md#encode-and-evict)); it is not duplicated into both.
3. **Layer boundary holds.** An engineering PR cannot mutate a Layer-2 operator surface (`~/.claude/memory/`, `projects/`); those writes are operator-side per [`operations-bridge.md`](../rules/operations-bridge.md). The PORTFOLIO.md bridge is Cowork-write / Claude-Code-read.

---

## §6 Composition boundaries {#composition-boundaries}

This contract is the cross-surface **index**, not the union of every surface's full spec. It holds **one row per surface** and points at the surface's normative home rather than copying it (single-home / no-shadow-SSOT — copying another home's fields into this table would itself be a shadow SSOT):

- **The Knowledge↔corpus boundary is preserved, not relocated.** This contract governs which surface owns a fact; it does **not** move codifiable knowledge into memory. The corpus stays SSOT for codified Knowledge; memory holds it only as an eviction-pointer (the [knowledge-architecture.md §6](knowledge-architecture.md#memory-corpus-boundary) boundary is authoritative).
- **The People surface's normative spec is its own home.** This table enumerates the People *row*; the read-time composition contract for the people-capability/coverage graph is [`people-coverage-graph.md`](people-coverage-graph.md) (a read-only VIEW over the operator-instance `people-roster.yaml`, composed not absorbed, never repo-tracked). This contract cites the shipped graph — it does not describe a new surface.
- **Operational-tracker lifecycle fields live in their inventory.** The "operational trackers" row's per-artifact lifecycle (eviction / archive / cadence detail) is governed by [`operational-artifact-inventory.md`](../specs/operational-artifact-inventory.md) and the OPERATIONS.md Operational Artifacts table. This contract names the row; it does not duplicate the per-tracker schema.
- **The `08-Generated/` staging area is out-of-table.** It is a transient pre-approval working surface, not a durable memory surface — noted here to forestall a "missing row" reading.
- **Enforcement gate: DEFERRED.** A `deploy.sh --check` analog (a "memory-write-respects-contract" detector, sibling to Check 36 `memory-corpus-tie-drift`) is a follow-up, not part of this contract's first version. The contract ships doc-only; a follow-up improvement Issue carries the enforcement gate (warn-mode-initial, matching ADR-029's posture for Check 36).

---

## §7 Related references + provenance {#references}

- **Type-axis authority** — [`knowledge-architecture.md §2.1`](knowledge-architecture.md#four-type-reconciliation): the four-memory-type model (Work / Knowledge / People / Learning) and the four-axis reconciliation (type × K1–K5 × Context-Tier × Document-Tier). This contract's `memory-type(s)` column draws from there.
- **Knowledge cut** — [`knowledge-architecture.md §6`](knowledge-architecture.md#memory-corpus-boundary): the corpus↔memory SSOT assignment, the no-shadow invariant origin, the encode-and-evict lifecycle, the three drift classes.
- **Ratifying ADRs** — [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) (the Knowledge cut, superseded) and [ADR-045](../ADRs/ADR-045-cross-surface-memory-contract.md) (this cross-surface contract; supersedes ADR-029).
- **Write-authority enum** — [`autonomy-tiers.md`](../specs/autonomy-tiers.md): the Autonomy Tier 0–3 definitions the `write-authority` column binds to.
- **Read order** — the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Context File Hierarchy + Session Management sections.
- **Operational-tracker inventory** — [`operational-artifact-inventory.md`](../specs/operational-artifact-inventory.md) (the tracker-row lifecycle) + [`tracker-schemas.md`](../schemas/tracker-schemas.md) (the per-tracker schema).
- **People surface** — [`people-coverage-graph.md`](people-coverage-graph.md) (the shipped read-time graph view over the operator-instance roster).
- **Layer boundary** — [`operations-bridge.md`](../rules/operations-bridge.md): the Layer-1 / Layer-2 write boundary this contract's §5 Rule 3 cites.

<!-- repo-integrity: allow-issue-ref -->

> Issue numbers below are **traceability pointers, not load-bearing references** — repository re-versioning renumbers them. Each entry leads with a self-describing name so the reference survives the number; if a number no longer resolves, locate the work by its name. This block is the *only* place in this document where issue numbers appear; the body reads complete without them.

- **This contract** — the unified cross-surface memory read/write SSOT doc. *Sliced from the cross-surface memory-architecture epic (#1071), child 2 (the SSOT) — issue #1074.*
- **Type taxonomy it cites** — the memory-type taxonomy + four-axis reconciliation inserted at `knowledge-architecture.md §2.1`. *Issue #1073.*
- **People surface it cites** — the shipped people-capability/coverage graph. *Reconciled-and-cited per #1075 (people-graph already shipped — cite, do not build).*
- **Memory↔corpus boundary it preserves** — the boundary-contract parent that this contract does not relocate. *Issue #530.*
- **Broader epic** — the cohesive cross-surface memory-architecture epic and its cluster. *Epic #1071 + cluster #1073–#1077.*
