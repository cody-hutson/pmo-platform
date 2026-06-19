<!-- reference-durability: allow-link -->
---
title: ADR-028 — Memory↔corpus SSOT boundary — corpus-SSOT for codified knowledge, pointer-only in memory
status: Accepted
date: 2026-06-19
release: 35-agent-discipline-codification (v2.05)
deciders: "Workspace owner (decision adopted at the v2.05 Collective Review scope-lock); design authored at Stage 5 Solutioning on sub-task #1298"
tags: [architecture, knowledge-management, memory, corpus, ssot, encode-and-evict, drift-detection, parameterize-over-hardcode, reversibility]
source_observations:
  - "2026-06-07 memory audit, failure mode #1 (shadow-SSOT inversion): toolkit-encodeable rules held in the auto-memory store as full copies duplicating shipped governance (9 memories duplicated CLAUDE.md / core/ rules). A copy can drift, and an agent reading the memory version lets memory silently override governance — memory had become a second source of truth over the toolkit."
  - "2026-06-07 memory audit, failure mode #2 (encode-and-evict rot): the capture-enhancement-with-memory-pointer pattern (remove_on_deploy) should evict a memory once the corpus encodes it, but eviction was a manual issue-AC that gets skipped, and the pointer's issue ref rots silently (the 2026-06-04 ledger pointed at issues that the repo re-versioning orphaned)."
  - "The platform had a knowledge-tier taxonomy (knowledge-architecture.md K1–K5) but no governed boundary contract between the operator memory store and the codified corpus: the taxonomy says what the tiers are, not which surface is the SSOT for each tier nor how knowledge moves from memory into the corpus reliably."
---

<!-- repo-integrity: allow-issue-ref -->

# ADR-028 — Memory↔corpus SSOT boundary

## Status

Accepted. Adopted at the v2.05 (`35-agent-discipline-codification`) Collective Review scope-lock; the design was authored at Stage 5 Solutioning on sub-task #1298 and implemented at Stage 6 per the ADR-007 / ADR-024 / ADR-027 precedent of Stage-6 ADR authoring. The boundary *mechanism* (corpus-SSOT for codified knowledge, pointer-only in memory, VERIFY-CORPUS-gated eviction) is HIGH-confidence; the standing-audit backstop ships warn-mode-initial.

## Context

The platform classifies knowledge into five tiers (`knowledge-architecture.md` §1, K1–K5) and assigns each tier an authoritative home (§3 placement model). What it lacked was a **boundary contract between the operator auto-memory store and the codified corpus**: the taxonomy names *what the tiers are*, but it did not name *which surface is the source of truth (SSOT) for a fact that could appear in two places*, nor *how a fact migrates from memory into the corpus reliably*.

Two failure modes, both observed in the 2026-06-07 memory audit, motivated the contract:

1. **Shadow-SSOT inversion.** Toolkit-encodeable rules were held in the auto-memory store as full copies that duplicated shipped governance (9 memories duplicated `CLAUDE.md` / `core/` rules). A copy can drift from the corpus, and an agent reading the memory copy lets memory silently override governance. The memory store had become a *second* source of truth over the toolkit.
2. **Encode-and-evict rot.** The `capture-enhancement-with-memory-pointer` convention (a `remove_on_deploy` pointer) is supposed to evict a memory once the corpus encodes its content, but eviction was a manual issue-AC that gets skipped — and the pointer's issue reference rots silently (the 2026-06-04 ledger pointed at issues the repo re-versioning later orphaned).

The decision is therefore: which surface is SSOT for each knowledge class, whether the memory store may hold a codified rule at all, and by what reliable mechanism a memory is evicted once its content is codified.

## Decision

**Codified (toolkit-encodeable) knowledge is SSOT in the corpus; the auto-memory store is SSOT for tacit/situated K5 only and may hold codified knowledge solely as a temporary eviction-pointer. Eviction is VERIFY-CORPUS-gated (encode-then-evict).**

1. **Two-tier SSOT assignment.** Local/situated knowledge (operator identity & attribution, accounts/systems, instance projects, local-machine config, corrections-to-the-agent) is SSOT in the auto-memory store (`~/.claude/memory/`) for tacit/corrective K5, and in the operator-local toolkit home (`operator.toml` / `CLAUDE.md §Workspace Owner` / `projects/`) for K2/K3/K4 config and state. Toolkit-encodeable/codified K1 knowledge is SSOT in the corpus (`core/`, `release/skills/*/SKILL.md` + `references/`, `core/rules/`, `CLAUDE.md`). The routing test is the existing §1 Q1 universality classifier — this introduces no new taxonomy.

2. **No-shadow-SSOT invariant.** A fact has exactly one source of truth. A memory entry holding a full copy of a codified rule is a *shadow SSOT* — prohibited. Codified knowledge appears in memory only as a pointer to its corpus home (a temporary eviction-pointer while an encode issue is in flight, or a durable cross-reference), never as a duplicate of the governed text.

3. **Encode-and-evict lifecycle, ordering structurally enforced.** ENCODE (corpus write lands on main) → ARCHIVE (memory body pasted verbatim into the Stage-13 sub-task comment, before any deletion) → VERIFY-CORPUS (confirm the corpus home contains the rule; eviction does **not** proceed if absent) → EVICT (Trash the memory file, trim the `MEMORY.md` index line, retire the pointer/ledger row). The VERIFY-CORPUS gate makes corpus-presence a *precondition of eviction*, so a naive "issue closed → delete" cannot lose content when the close preceded the corpus write. ARCHIVE-first makes even an erroneous eviction CHEAP-reversible.

4. **Trigger = Option C (hybrid): the Stage-13 Phase B-OPS step executes; a deploy check audits.** The PRIMARY executor is the existing Stage-13 `Phase B-OPS` operational-deploy step (gated by `G-CL5`), driven by the release plan's operational-deployment manifest under operator authorization. The STANDING BACKSTOP is a new `deploy.sh --check` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial) — the non-skippable standing audit that catches a forgotten manifest entry. A deploy *check* must never delete operator memory files (a validator that mutates Layer-2 is an over-reach), so the check audits and the operational-deploy step executes.

5. **Drift audit detects dead references by reference-resolution-failure, never digit-match.** Re-versioning renumbers issues, so issue-number identity is fragile. The audit probes `gh issue view N`; it never compares issue-number magnitude. The three drift classes are deployed-but-not-evicted, dead-ref tie, and untied-encodeable.

## Consequences

### Positive

- **Closes the shadow-SSOT drift vector:** codified rules live in exactly one place (the corpus), so the memory copy can no longer silently override governance.
- **Reuses shipped surfaces:** the executor is the existing Phase B-OPS step (gate `G-CL5`); the audit reuses the proven `deploy.sh --check` enforcement surface. No new pipeline phase; one new check.
- **Reliable eviction:** the standing Check 36 backstop fires on every `--check` regardless of whether a manifest entry was remembered, so the "skipped eviction" failure mode surfaces automatically.
- **Re-version-safe:** dead-ref detection by resolution-probe survives issue renumbering, where a digit-match heuristic would not.
- **Self-applying:** the contract's first eviction is the very memory that stated the routing rule informally (`feedback_memory_vs_codification_routing`), reduced to a pointer to the codified §6.

### Negative / cost

- **Eviction depends on an operator-side step for Layer-2:** the actual memory-file deletion cannot be performed by an engineering PR (`operations-bridge.md` Rule 1). It is executed operator-side at Stage-13 Phase B-OPS. Accepted: the Check 36 backstop guarantees a skipped eviction is detected, and the Stage-13 handoff makes the deletion an explicit operator step.
- **Check 36 carries a heuristic class:** the untied-encodeable class is a heuristic surface (it matches encodeable signatures), so it can over- or under-flag. Accepted: it routes for operator triage, not automatic action, and ships warn-mode-initial.
- **A network/auth dependency in the audit:** the dead-ref and deployed-but-not-evicted classes probe `gh issue view`, so they degrade to SKIP when `gh` is unavailable. Accepted: the check degrades gracefully rather than failing closed.

### Reversibility

**CHEAP for the Layer-1 contract, MODERATE for the Layer-2 eviction.** The corpus section, the `CLAUDE.md.template` preference, this ADR, the how-to, and Check 36 are additive doc/governance edits — revert the release PR (`git revert -m 1`). Check 36 ships warn-mode and deletes nothing. The only non-git-reversible surface is the operator-side memory eviction: once a memory file is deleted it is recoverable only from local backup, so the Stage-13 handoff instructs the operator to back up `~/.claude/memory/` before evicting (ARCHIVE-first makes the content recoverable from the sub-task comment regardless).

## Options considered

### The boundary itself

| Option | Verdict | Why |
|---|---|---|
| (A) Corpus-SSOT; memory holds codified knowledge only as a pointer | **CHOSEN** | Eliminates the shadow-SSOT drift vector; codified knowledge has exactly one home; memory still serves its live-session affordance via a pointer. |
| (B) Allow full codified copies in memory as a convenience cache | Rejected | This *is* the shadow-SSOT drift vector — a cached copy drifts from the corpus and lets memory override governance, which is precisely failure mode #1. |

### The eviction trigger

| Option | Verdict | Why |
|---|---|---|
| (A) `deploy.sh --check` flags a memory whose tied issue is CLOSED | Rejected as sole mechanism | A deploy *check* must not delete operator memory files (Layer-2 mutation is an over-reach); A can detect but cannot execute. |
| (B) A Stage-13 step evicts memories tied to shipped issues | Rejected as sole mechanism | Fires only if the operator put the eviction in that release's manifest; a forgotten entry is a silent miss — the exact failure this contract closes. |
| (C) Hybrid — B executes (operator-authorized, archive-first, VERIFY-CORPUS-gated), A (Check 36) is the non-skippable standing audit | **CHOSEN** | Each surface gets its correct role; structurally identical to the #316 resolution (single-source executor + enforced-rebuild check) on the skill↔reference surface. |

## Related ADRs

- [ADR-007 — Core module boundary lock-in](ADR-007-core-module-boundary.md): the Stage-6 ADR-authoring precedent and the markdown cross-module reference posture this ADR follows.
- [ADR-027 — Release-bundle risk-weighting keys on Release Class](ADR-027-release-bundle-risk-weight-keys-on-release-class.md): the immediately-preceding ADR; same Stage-6-authored, additive-doc, `[CALIBRATE]`-honest shape.

## References

<!-- repo-integrity: allow-issue-ref -->

- **Canonical definition:** `core/disciplines/knowledge-architecture.md` §6 Memory↔corpus boundary (the two-tier SSOT table, the no-shadow-SSOT invariant, the encode-and-evict lifecycle, the three drift classes).
- **Universal Preference cross-ref:** `CLAUDE.md` § Universal Preferences — "Single-source-of-truth for knowledge".
- **Executor surface:** `release/references/pipeline/stage-13-close.md` §5 Phase B-OPS + gate `G-CL5` (operational-deployment-manifest-executed).
- **Audit surfaces:** `release/references/how-to/memory-corpus-drift-audit.md` (human-runnable) + `core/deploy/deploy.sh` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial).
- **Sibling pattern (cited, not re-derived):** #316 — single-source + enforced-rebuild deploy check on the skill↔reference surface; this ADR applies the same shape to the memory↔corpus surface.
- **Design + provenance:** #530 (parent — the boundary-contract card); Stage 5 Solutioning spec on sub-task #1298; the repo-integrity authoring discipline applied here per #426 (sub-task #1323).
