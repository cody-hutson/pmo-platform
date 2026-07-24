---
title: Concurrency Safeguards
purpose: The discipline governing concurrency between Claude Code sessions (interactive, worktree, scheduled, auto-mode) via behavioral conventions, building on the operations-bridge Concurrency Rule.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Concurrency Safeguards

> **Status:** Stage 6 Engineering
> **Reversibility tier:** CHEAP / Confidence: HIGH — new single reference doc; revert = delete the file.
> **Scope boundary:** Documented conventions ONLY. This protocol defines **NO** lock-file infrastructure, **NO** write queues, and **NO** PreToolUse lock hooks. `.claude/settings.json` is **explicitly OUT of scope** — this protocol adds no hook component. Enforcement is behavioral + git-native, not mechanical. Rationale: the release Risk clause + Operator Decision D-1.

---

## Purpose

Concurrency between Claude Code sessions (interactive sessions, worktree spawns, scheduled tasks, auto-mode) is managed by behavioral conventions — codified in [`operations-bridge.md`](../rules/operations-bridge.md) § Concurrency Rule. The base convention is sufficient for a single operator working sequentially. As automation grows — auto-mode, scheduled tasks, multiple concurrent Claude Code sessions — the likelihood of two sessions writing the same file rises. This document specifies the **detection, prevention, and recovery conventions** that contain that risk, tiered by the layer the contended file lives in.

**What this protocol is:**
- The single named source for the platform's concurrency-safeguard conventions.
- A tiered (Layer 1 / 2 / 3) allocation of safeguards to where recovery is hardest.
- The bridge-file write-safety convention (highest-risk class).

**What this protocol is NOT:**
- A lock-file mechanism, a write queue, or a PreToolUse enforcement hook (out of scope by design — see Scope Boundary above).
- A scheduler or session-manager implementation.
- A replacement for git's own conflict handling on Layer 1 (it *complements* it).

A future release MAY add an executable detection primitive (e.g., a branch-freshness assertion under `core/deploy/tools/`). This protocol is **self-contained** and does not depend on one; adding one is not a prerequisite for any safeguard here. `[INFERRED: D-1 self-containment constraint]`

## Concurrency Risk Assessment

`[SOURCE: 2026-03-28 Session 15 — operator-identified multi-agent overwrite risk]` `[SOURCE: operations-bridge.md § Concurrency Rule — "no file locking; convention is behavioral"]`

| Scenario | Likelihood today (single operator, sequential) | Likelihood near-term (auto-mode / scheduled / multi-session) | Impact if it occurs | Net priority |
|---|---|---|---|---|
| Tab-switch race on a Layer 1 file | Low | Low–Medium | Lost edit — **git-recoverable** | LOW |
| Concurrent Claude Code worktree + operations-mode session on the same Layer 1 file | Low | Medium | Silent overwrite / mirror drift — **git-recoverable** | MEDIUM (near-term) |
| Scheduled task fires during an interactive session | Very Low | Medium | Partial write — git-recoverable on Layer 1; unrecoverable on Layer 2/3 | MEDIUM (near-term) |
| Concurrent writes to a **Layer 3 bridge file** | Low | Medium–High | Lost session/portfolio/correction state — **NOT git-recoverable** (git-ignored) | **HIGH** |

**Key insight:** Layer 1 has `git revert` / `git checkout` as a universal safety net. Layer 2/3 are git-ignored — a concurrent overwrite there is **unrecoverable by git**. Safeguard ceremony is therefore allocated *inversely to recoverability*: lightest on Layer 1, heaviest on Layer 3.

## Tiered Safeguard Model

| Layer | Domain / examples | Git safety net? | Primary safeguard | Detection signal | Recovery path |
|---|---|---|---|---|---|
| **Layer 1 — git-managed** | Platform engineering · `core/`, `operations/`, `release/`, `CLAUDE.md`, `core/rules/`, `core/deploy/deploy.sh` | **YES** (tracked) | Worktree isolation + `git status` before any git op | Unexpected dirty/modified Layer 1 file after returning from an operations-mode session | `git checkout -- <file>` / resolve per operations-bridge.md Rule 4 |
| **Layer 2 — operational** | PMO operations · `projects/` (entire tree) | NO (git-ignored) | Single-writer-at-a-time convention | Expected-vs-actual content/timestamp mismatch | Re-derive from source artifacts; no git restore |
| **Layer 3 — bridge files** | `PORTFOLIO.md`, `SESSION_STATE.md`, `CORRECTIONS.md`, `SWAP_HANDOFF.md` (`projects/_config/`) | NO (git-ignored) | Sequenced single-writer + read-before-write + write-confirm | Stale `Last Updated` / `Captured at` vs. session reality; unexpected entries | Reconstruct from durable sources (git log, `gh`, project artifacts); operator-confirm |

Layer 3 is a strict subset of Layer 2 (git-ignored) but is broken out because it is **shared coordination state** read at session start by every session — corruption there silently mis-routes future work, so it carries the strictest convention.

## Detection

Detection is **conventional and conceptual** — no executable primitive is required or hard-cited.

- **Layer 1:** Immediately after returning from an operations-mode session and **before any git operation**, run `git status` (and `git diff` if status is dirty). An unexpected modified/untracked Layer 1 file is the concurrent-write signal. This is the operational form of the operations-bridge.md Rule 4 trigger. A concrete, recognizable fingerprint of this signal is a Cowork-side link-normalization sweep that resolves a repo's relative markdown links from the **workspace root** (`~/Claude/`) rather than the **repo root** and rewrites them to a workspace-prefixed `](pmo-platform/…)` form: the primary then shows modified tracked `.md` files no in-session edit produced, and the rewritten links fail the dead-file-reference gate at PR time (the writer-side twin of the resolution bug the doc-link checker was already hardened against). Treat a dirty primary carrying `](pmo-platform/…)` link rewrites as this Layer-1 concurrent-write signal and resolve per operations-bridge.md Rule 4 before any git operation — the originating sweep runs off the git surface (operations domain), so this session-start observation, not a repo-side lint, is where it is caught.
- **Layer 1 mirror pairs:** For any byte-identical mirror pair across modular-monolith mirrors, `diff -q <left> <right>` returning non-empty/non-zero is the drift signal. (Deploy-time backstop: `./deploy.sh --check` — *only for pairs enrolled in the check's mirror-list configuration*; pairs not enrolled rely solely on the manual `diff -q`.)
- **Layer 2 / Layer 3:** Expected-state-vs-actual-state comparison. Examples: `SESSION_STATE.md` `Last Updated` older than the current session's known activity; `SWAP_HANDOFF.md` `Captured at` inconsistent with the last swap; `CORRECTIONS.md` carrying entries the session did not author. A mismatch is the signal that another agent wrote concurrently.

A future executable detection primitive (e.g., a branch-freshness assertion) MAY be cited here when it ships; its absence does not weaken any convention above.

## Prevention

- **Layer 1:** (a) Platform-engineering work always runs inside a worktree (under the workspace `.claude/worktrees/*`), never the primary checkout — physical isolation from any operations-mode session's working set. (b) The behavioral convention: **end any operations-mode session that holds open files in `projects/` before starting git operations on the primary checkout** (operations-bridge.md § Concurrency Rule). (c) When ≥2 sessions share one release-branch worktree, **serialize their commits** (one writer completes and commits before the next begins) rather than relying on bare `git commit` staging discipline.
- **Layer 2:** Single-writer-at-a-time. Do not run an interactive session that writes `projects/` while a scheduled/auto session that writes the same surface is active.
- **Layer 3 (write-safety convention — highest priority):**
  - Exactly **one agent owns a bridge-file write at a time**. Bridge files are never written by two sessions concurrently.
  - **Read-before-write, then write-confirm** (the CLAUDE.md write-first-speak-second rule already mandates the confirm step) — re-read the file immediately before writing so a concurrent change is detected pre-write, not lost post-write.
  - **Sequencing:** the session-end `SESSION_STATE.md` update happens **after** all other writes in the session. `SWAP_HANDOFF.md` is auto-written **only** at the account-switcher swap boundary — never hand-edited while a swap may fire.

## Recovery

- **Layer 1 (git is the net):** `git checkout -- <file>` restores the committed version. For an intentional change from another session, resolve per operations-bridge.md Rule 4 (review → commit if intentional → checkout if accidental → GitHub Issue for the boundary violation). **Mirror drift:** restore byte-identity by copying the canonical copy over the divergent mirror (or vice-versa, toward whichever is correct), then re-run `diff -q` to confirm clean.
- **Layer 2 / Layer 3 (no git restore):** Reconstruct from durable sources — `SESSION_STATE.md` from `git log` + `gh` + project artifacts; `PORTFOLIO.md` from per-project `PROJECT.md` files; `CORRECTIONS.md` from the operator; `SWAP_HANDOFF.md` regenerates automatically on the next swap. Reconstructed bridge-file state is **operator-confirmed** before it is treated as authoritative.

## Relationship to Existing Governance

- [`operations-bridge.md`](../rules/operations-bridge.md) § Concurrency Rule — the entry point that points here; defines the session-end-before-git convention and Rule 4 boundary-violation handling.
- [`CLAUDE.md`](<OPERATOR_INSTANCE_CLAUDE_MD>) — the canonical Layer/Domain model and the bridge-file roster this protocol tiers against; the write-first-speak-second rule (the read-before-write/confirm basis).
- [`git-workflow.md`](../rules/git-workflow.md) — Primary Checkout Discipline, worktree rules, and the Session-Start `git status` step that operationalizes Layer 1 detection.
- [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) — the workspace PreToolUse hook layer. This protocol deliberately adds **no** hook: hooks are reserved for the security-invariant class (destructive ops, credential reads, egress); concurrency is a behavioral/coordination concern and is governed by convention, not mechanism (D-1 + the release Risk clause).

## Change & Mirror-Pair Discipline

Any edit to the `operations-bridge.md` § Concurrency Rule MUST be applied to the canonical surface in the modular-monolith tree under `core/rules/operations-bridge.md`. If the deploy mechanism creates mirrors (per the active deploy configuration), apply edits **byte-identically** to all mirrored locations and verify with `diff -q` (silent / exit 0) **before** committing. `./deploy.sh --check` is the deploy-time backstop **only if the pair is enrolled in the check's mirror-list configuration**; until then the manual `diff -q` is the sole gate. This protocol document itself is single-instance (not mirrored).
