<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-memory-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-029 — Memory SSOT model — corpus-SSOT for codified Knowledge within the four-type memory architecture
status: Superseded by ADR-045 (the cross-surface memory contract — the Knowledge cut here is reconciled into it; this record remains for audit trail). Originally Accepted (interim — resolved the Knowledge↔corpus cut of a larger memory architecture; see § Position in the broader architecture).
date: 2026-06-19
release: 35-agent-discipline-codification (v2.05)
deciders: "Workspace owner (architecture refined + ratified at the v2.05 Stage 9 review); design authored at Stage 5 Solutioning"
tags: [architecture, knowledge-management, memory, corpus, ssot, four-type-memory, encode-and-evict, drift-detection, extensible, reversibility]
source_observations:
  - "2026-06-07 memory audit, failure mode 1 (shadow-SSOT inversion): toolkit-encodeable rules held in the auto-memory store as full copies duplicating shipped governance (9 memories duplicated CLAUDE.md / core/ rules). A copy can drift, and an agent reading the memory version lets memory silently override governance — memory had become a second source of truth over the toolkit."
  - "2026-06-07 memory audit, failure mode 2 (encode-and-evict rot): the capture-enhancement-with-memory-pointer pattern (remove_on_deploy) should evict a memory once the corpus encodes it, but eviction was a manual issue-AC that gets skipped, and the pointer's issue ref rots silently (the 2026-06-04 ledger pointed at issues that the repo re-versioning orphaned)."
  - "The platform holds memory across several surfaces (corpus, ~/.claude/memory/, governance context files, operational state) but had no governed SSOT contract naming which surface owns a fact that could appear in more than one, nor how a fact migrates between surfaces reliably."
---

# ADR-029 — Memory SSOT model

## Status

**Superseded by [ADR-045](ADR-045-cross-surface-memory-contract.md)** (the generalized cross-surface memory read/write contract). ADR-045 is the reconciliation this ADR's Revisit trigger named: the SSOT assignment and the no-shadow invariant move verbatim into the unified contract ([`core/disciplines/memory-architecture.md`](../disciplines/memory-architecture.md)), and the encode-and-evict lifecycle becomes the Knowledge instance of the general graduation flow. This record remains unchanged for audit trail; the historical status follows.

**Accepted (interim).** This ADR resolves **one boundary** — the SSOT cut between codified *Knowledge* and the operator memory store — within a larger, four-type memory architecture (see [§ The memory architecture](#the-memory-architecture-organizing-model) and [§ Position in the broader architecture](#position-in-the-broader-architecture-future-direction)). The decision and its mechanism are ratified for v2.05; the surrounding architecture — a unified cross-surface read/write contract spanning all four memory types — is tracked under the cohesive cross-surface memory-architecture epic and its cluster (see References), and this boundary is designed to **slot into** that contract when it lands.

Refined and ratified by the workspace owner at the v2.05 Stage 9 review; the boundary mechanism was authored at Stage 5 Solutioning. The mechanism (corpus-SSOT for codified Knowledge, pointer-only in memory, VERIFY-CORPUS-gated eviction) is HIGH-confidence; the standing-audit backstop ships warn-mode-initial.

**Numbering provenance.** Authored branch-local as ADR-028; renumbered to **ADR-029** at merge time, resolving a collision with `ADR-028-operations-consume-core-safety-controls-via-public-api` (which claimed 028 on `main` via the ADR-024→028 renumber during this release's engineering window). In-release citations that read "ADR-028" denote this record.

## Context

The platform holds memory across several loosely-coupled surfaces — the codified corpus, the operator-local auto-memory store (`~/.claude/memory/`), governance context files, and operational state/trackers. What it lacked was a **governed source-of-truth (SSOT) contract**: for a fact that could live in more than one surface, which surface *owns* it, and by what reliable mechanism a fact *migrates* between surfaces. The `knowledge-architecture.md` K1–K5 model classifies knowledge by *universality*; it does not assign an SSOT surface per memory type, nor govern cross-surface flow.

Two failure modes, both observed in the 2026-06-07 memory audit, motivated the contract:

1. **Shadow-SSOT inversion.** Toolkit-encodeable rules were held in the auto-memory store as full copies that duplicated shipped governance (9 memories duplicated `CLAUDE.md` / `core/` rules). A copy can drift from the corpus, and an agent reading the memory copy lets memory silently override governance. The memory store had become a *second* source of truth over the toolkit.
2. **Encode-and-evict rot.** The `capture-enhancement-with-memory-pointer` convention (a `remove_on_deploy` pointer) is supposed to evict a memory once the corpus encodes its content, but eviction was a manual issue-AC that gets skipped — and the pointer's issue reference rots silently (the 2026-06-04 ledger pointed at issues the repo re-versioning later orphaned).

This ADR does **not** attempt to specify the whole memory system at once. It resolves the **sharpest, first-needed boundary** — between codified Knowledge and the operator memory store — and *names* the surrounding architecture so the cut is legible as one slice, not a binary.

## The memory architecture (organizing model)

Memory is organized by **four memory types**, distinguished by *what the memory is for*. This is an axis orthogonal to the K1–K5 universality axis — the two are **reconciled, not stacked** (the reconciliation table is owned by the memory-type taxonomy work; see References).

| Memory type | What it holds | SSOT surface | Status in this ADR |
|---|---|---|---|
| **Work** | active projects, current decisions, open tasks | operational surfaces — the work tracker, `projects/`, session/state files | named; resolved by the cross-surface cluster |
| **Knowledge** | domain expertise, research, frameworks, reusable disciplines | the **codified corpus** (`core/`, `release/skills/*` + `references/`, `core/rules/`, `CLAUDE.md`) when universal (the K1 class) | **← resolved here** |
| **People** | contacts, companies, relationship context | none today — a net-new surface | named; deferred |
| **Learning** | patterns, mistakes, what works for the operator specifically | the operator auto-memory store (`~/.claude/memory/`) — the K5 tacit/situated class | named; the **graduation source** for Knowledge |

One invariant spans all four types:

> **No-shadow-SSOT invariant.** Every fact has exactly **one** source of truth — the SSOT surface of its memory type. No surface holds a second, shadowing copy of another surface's SSOT. A shadow copy can drift, and an agent reading it lets the copy silently override its owner.

This ADR is the **Knowledge cut** of that invariant: it fixes the SSOT for codified Knowledge (the corpus) and the relationship between the corpus and the operator memory store. The other three types' SSOT surfaces are *named* in the table and fully specified by the cross-surface contract under the broader cluster. The model is **extensible by construction** — a new memory type or level is added as a row with its own SSOT surface; the invariant holds unchanged.

## Decision

**Within the four-type model, codified Knowledge is SSOT in the corpus; the operator memory store is SSOT for the Learning type (tacit/situated K5) and may hold codified Knowledge only as a temporary eviction-pointer. A Learning that generalizes into reusable Knowledge *graduates* into the corpus, after which its memory copy is evicted to a pointer. Eviction is VERIFY-CORPUS-gated (encode-then-evict).**

1. **SSOT assignment (the Knowledge cut).** Codified, toolkit-encodeable Knowledge (the K1 class — general disciplines, reusable references, gate/CI behavior, methodology) is SSOT in the corpus. The Learning type (tacit/corrective/situated K5 — the `CORRECTIONS.md` class) is SSOT in the auto-memory store (`~/.claude/memory/`). Operator config and state (the K2/K3/K4 classes that the Work and People types draw on) are SSOT in the operator-local toolkit home (`operator.toml` / `CLAUDE.md §Workspace Owner` / `projects/`). The routing test is the existing `knowledge-architecture.md` §1 Q1 universality classifier — this ADR introduces no new taxonomy, only the SSOT assignment over the existing one.

2. **No-shadow-SSOT invariant** (stated above) — applied here to the Knowledge↔memory relationship: codified Knowledge appears in memory only as a *pointer* to its corpus home (a temporary eviction-pointer while an encode issue is in flight, or a durable cross-reference), never as a duplicate of the governed text.

3. **Graduation = the encode-and-evict lifecycle, ordering structurally enforced.** ENCODE (the corpus write lands on main) → ARCHIVE (the memory body is pasted verbatim into the Stage-13 sub-task comment, before any deletion) → VERIFY-CORPUS (confirm the corpus home contains the rule; eviction does **not** proceed if absent) → EVICT (Trash the memory file, trim the `MEMORY.md` index line, retire the pointer/ledger row). The VERIFY-CORPUS gate makes corpus-presence a *precondition of eviction*, so a naive "issue closed → delete" cannot lose content when the close preceded the corpus write. ARCHIVE-first makes even an erroneous eviction CHEAP-reversible. This is the Knowledge-cut instance of the general graduation lifecycle that the operational-state lifecycle work generalizes (see References).

4. **Trigger = Option C (hybrid): the Stage-13 Phase B-OPS step executes; a deploy check audits.** The PRIMARY executor is the existing Stage-13 `Phase B-OPS` operational-deploy step (gated by `G-CL5`), driven by the release plan's operational-deployment manifest under operator authorization. The STANDING BACKSTOP is a new `deploy.sh --check` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial) — the non-skippable standing audit that catches a forgotten manifest entry. A deploy *check* must never delete operator memory files (a validator that mutates Layer-2 is an over-reach), so the check audits and the operational-deploy step executes.

5. **Drift audit detects dead references by reference-resolution-failure, never digit-match.** Re-versioning renumbers issues, so issue-number identity is fragile. The audit probes whether a referenced issue still resolves; it never compares issue-number magnitude. The three drift classes are deployed-but-not-evicted, dead-ref tie, and untied-encodeable.

## Consequences

### Positive

- **Extensible, not binary.** The four-type model adds a memory type or level as a row under one invariant; this ADR's Knowledge cut *composes* with the Work / People / Learning SSOTs the cross-surface cluster resolves, rather than foreclosing them. A future reader sees a deliberate first slice, not a model that boxes memory in.
- **Closes the shadow-SSOT drift vector.** Codified Knowledge lives in exactly one place (the corpus), so the memory copy can no longer silently override governance.
- **Reuses shipped surfaces.** The executor is the existing Phase B-OPS step (gate `G-CL5`); the audit reuses the proven `deploy.sh --check` enforcement surface. No new pipeline phase; one new check.
- **Reliable graduation.** The standing Check 36 backstop fires on every `--check` regardless of whether a manifest entry was remembered, so the "skipped eviction" failure mode surfaces automatically.
- **Re-version-safe.** Dead-ref detection by resolution-probe survives issue renumbering, where a digit-match heuristic would not.
- **Self-applying.** The contract's first eviction is the very memory that stated the routing rule informally (`feedback_memory_vs_codification_routing`), reduced to a pointer to the codified §6.

### Negative / cost

- **Partial architecture by design.** Only the Knowledge↔corpus cut is resolved here; the unified cross-surface read/write contract, the People-memory surface, and the operational-state lifecycle are *named* but deferred (see References). Accepted: resolving the sharpest cut first, under a stated invariant the rest extend, is preferable to a speculative whole-system spec authored ahead of the cluster's Stage-5 work.
- **Eviction depends on an operator-side step for Layer-2.** The actual memory-file deletion cannot be performed by an engineering PR (`operations-bridge.md` Rule 1); it is executed operator-side at Stage-13 Phase B-OPS. Accepted: the Check 36 backstop guarantees a skipped eviction is detected, and the Stage-13 handoff makes the deletion an explicit operator step.
- **Check 36 carries a heuristic class.** The untied-encodeable class matches encodeable signatures, so it can over- or under-flag. Accepted: it routes for operator triage, not automatic action, and ships warn-mode-initial.
- **A network/auth dependency in the audit.** The dead-ref and deployed-but-not-evicted classes probe live issue state, so they degrade to SKIP when that probe is unavailable. Accepted: the check degrades gracefully rather than failing closed.

### Reversibility

**CHEAP for the Layer-1 contract, MODERATE for the Layer-2 eviction.** The corpus section, the `CLAUDE.md.template` preference, this ADR, the how-to, and Check 36 are additive doc/governance edits — revert the release PR (`git revert -m 1`). Check 36 ships warn-mode and deletes nothing. The only non-git-reversible surface is the operator-side memory eviction: once a memory file is deleted it is recoverable only from local backup, so the Stage-13 handoff instructs the operator to back up `~/.claude/memory/` before evicting (ARCHIVE-first makes the content recoverable from the sub-task comment regardless).

## Position in the broader architecture (future direction)

This ADR is a **deliberate first slice** of the cohesive cross-surface memory-architecture epic. When that cluster lands, this boundary is absorbed into the unified contract rather than standing alone. The cluster's named members (issue pointers in References):

- **Unified read/write contract** — the SSOT document that will host the four-type table as its normative core.
- **Memory-type taxonomy** — the four-axis reconciliation (Work / Knowledge / People / Learning ↔ K1–K5 / Tier 1–4 / Document-Tier 1–4).
- **People-memory surface** — the net-new home named but unresolved here.
- **Operational-state lifecycle** — eviction / archive / **graduation**; generalizes this ADR's encode-and-evict beyond the Knowledge cut.
- **Active-use adoption** — skills read+write memory through the contract.

**Revisit trigger.** When the unified read/write contract is ratified, re-open this ADR to reconcile the Knowledge cut into it: the SSOT assignment and the no-shadow invariant should move verbatim into the unified table, and the encode-and-evict lifecycle becomes the Knowledge instance of the operational-state graduation lifecycle. Until then, this ADR is the operative SSOT contract for the Knowledge↔corpus surface.

## Options considered

### The architectural framing

| Option | Verdict | Why |
|---|---|---|
| Present a four-type memory architecture and scope this ADR to the Knowledge cut | **CHOSEN** | Captures the real, extensible architecture; the current decision is one legible slice; future types/levels extend the model under one invariant. |
| Present the two-tier (memory vs corpus) split as the complete memory model | Rejected | It is one cut of a four-type architecture; presenting it as the whole forecloses the Work / People / operational surfaces and the multi-level future — a restrictive, non-scalable frame for a durable record. |

### The boundary itself

| Option | Verdict | Why |
|---|---|---|
| (A) Corpus-SSOT for codified Knowledge; memory holds it only as a pointer | **CHOSEN** | Eliminates the shadow-SSOT drift vector; codified Knowledge has exactly one home; memory still serves its live-session affordance via a pointer. |
| (B) Allow full codified copies in memory as a convenience cache | Rejected | This *is* the shadow-SSOT drift vector — a cached copy drifts from the corpus and lets memory override governance, which is precisely the first failure mode (shadow-SSOT inversion). |

### The eviction (graduation) trigger

| Option | Verdict | Why |
|---|---|---|
| (A) `deploy.sh --check` flags a memory whose tied issue is CLOSED | Rejected as sole mechanism | A deploy *check* must not delete operator memory files (Layer-2 mutation is an over-reach); A can detect but cannot execute. |
| (B) A Stage-13 step evicts memories tied to shipped issues | Rejected as sole mechanism | Fires only if the operator put the eviction in that release's manifest; a forgotten entry is a silent miss — the exact failure this contract closes. |
| (C) Hybrid — B executes (operator-authorized, archive-first, VERIFY-CORPUS-gated), A (Check 36) is the non-skippable standing audit | **CHOSEN** | Each surface gets its correct role; structurally identical to the skill↔reference single-source resolution (single-source executor + enforced-rebuild check) on that surface. |

## Related ADRs

- [ADR-007 — Core module boundary lock-in](ADR-007-core-module-boundary.md): the Stage-6 ADR-authoring precedent and the markdown cross-module reference posture this ADR follows.
- [ADR-027 — Release-bundle risk-weighting keys on Release Class](ADR-027-release-bundle-risk-weight-keys-on-release-class.md): the immediately-preceding ADR; same Stage-6-authored, additive-doc, `[CALIBRATE]`-honest shape.

## References

<!-- repo-integrity: allow-issue-ref -->

> Issue numbers below are **traceability pointers, not load-bearing references** — repository re-versioning renumbers them (this ADR's own 028→029 renumber is an instance of exactly that hazard). Each entry leads with a self-describing name so the reference survives the number; if a number no longer resolves, locate the work by its name. This block is the *only* place in this ADR where issue numbers appear, by design — the body reads complete without them.

- **Canonical definition** — `core/disciplines/knowledge-architecture.md` §6 Memory↔corpus boundary: the SSOT assignment, the no-shadow-SSOT invariant, the encode-and-evict lifecycle, and the three drift classes.
- **Universal Preference cross-ref** — `CLAUDE.md` § Universal Preferences, "Single-source-of-truth for knowledge".
- **Executor surface** — `release/references/pipeline/stage-13-close.md` §5 Phase B-OPS + gate `G-CL5` (operational-deployment-manifest-executed).
- **Audit surfaces** — `release/references/how-to/memory-corpus-drift-audit.md` (human-runnable) + `core/deploy/deploy.sh` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial).
- **Broader architecture** (this ADR is one slice) — the cohesive cross-surface memory-architecture epic and the cluster it organizes: the memory-type taxonomy + four-axis reconciliation, the unified read/write contract, the People-memory surface, the operational-state lifecycle, and active-use adoption. *Tracked as the cross-surface memory-architecture epic (#1071) + its cluster (#1073–#1077).*
- **Sibling pattern** (cited, not re-derived) — the skill↔reference single-source + enforced-rebuild deploy check; this ADR applies the same shape to the memory↔corpus surface. *Tracked as #316.*
- **Design + provenance** — the boundary-contract parent card, the Stage 5 Solutioning spec, and the repo-integrity authoring discipline applied here. *Tracked as #530 (parent), #1298 (Solutioning sub-task), #426 / #1323 (authoring discipline).*
