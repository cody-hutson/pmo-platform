---
title: "ADR-021 — Liveness oracle: all-process lsof cwd snapshot, fail-closed"
status: Accepted
date: 2026-06-11
release: v1.11-cleanup-orphan-state-reliability
deciders: "Stage 5 Solutioning (Principal Engineer — Architecture Assessment) + operator at Collective Review scope-lock"
tags: [architecture, release-tooling, safety, liveness, worktree-lifecycle]
source_observations:
  - "Session worktrees of live Claude sessions were removed mid-execution by cleanup sweeps (self-reap and sibling-reap classes); the failure is the cwd-deleted error in the running session."
  - "Git worktree lock files are NOT a liveness signal on this platform: live sessions were observed holding worktrees with no lock present (operator-observed 2026-06-04; re-confirmed at design time — a minority of worktrees carry locks while multiple sessions are live)."
  - "Host validation at design time: the all-process cwd snapshot (lsof -a -d cwd -Fcn) completed in 0.26 s over 675 processes with zero stderr, and live sibling sessions appeared in the map holding their session worktrees."
---

# ADR-021 — Liveness oracle: all-process lsof cwd snapshot, fail-closed

## Status
Accepted — operator-ratified at the v1.11 Collective Review scope-lock (2026-06-11),
as amended there: renumbered from the spec's ADR-020 draft (a number collision with
the v1.09 agent-script promotion-ladder ADR), and extended with the apply-time
re-verification plus the Consequences additions below.

## Context
The orphan-state sweep must treat "held by a live process" as a hard non-eligible
state for worktree removal. Eligibility heuristics (branch pattern, merged state,
dirty check, attached test) cannot prove a tree idle; a merged-clean worktree can
be a live session's working directory, and removing it deletes that session's cwd
mid-run. One failure class this closes by construction: a live session that
detached its worktree HEAD post-merge (the documented post-merge cleanup pattern)
is clean + detached and therefore REMOVE-eligible under every pre-existing
heuristic. The oracle must not key on git lock files (observed absent for live
sessions), must not infer from recency, must work with zero cooperation from the
session harness, and must degrade safely where unavailable.

## Decision
Liveness = "some live process has its current working directory at or under the
candidate worktree path." Mechanism: ONE all-process snapshot per run via
`lsof -a -d cwd -Fcn` (binary resolved by absolute path: /usr/sbin/lsof on macOS,
/usr/bin/lsof on Linux — the script's pinned PATH cannot see /usr/sbin), parsed
into a (pid, command, cwd) map; candidates match by physical-path prefix. A
self-canary validates every scan: the script's own cwd MUST appear in the map
(the script's own process holds it), otherwise the oracle declares itself
unavailable. Fail-closed: when unavailable, any worktree that would otherwise be
REMOVE is reclassified "SKIP — liveness oracle unavailable (fail-closed)". A live
skip is never overridden by --force (classification-side protection; the apply
phase acts only on action == "REMOVE"). The SELF guard remains a separate,
oracle-independent clause ahead of the live clause (defense-in-depth when the
oracle is down; the script's own process would otherwise satisfy the live test).

Apply-time re-verification (scope-lock amendment): the classification-time map
ages across the multi-minute branch/remote apply phases, git porcelain does NOT
refuse removal of a clean live-held tree, and the post-apply verify pass detects
survivors — never wrongful removals. The map is therefore rebuilt once at the
worktree-apply-loop entry and every row still REMOVE is re-checked: a fresh hit
rewrites the row in place to the live-session skip, and an oracle unavailable at
re-check time converts residual REMOVEs fail-closed. The residual exposure is
the seconds between the re-check and the porcelain call.

## Alternatives Considered
- Git lock-holder ∩ process table: refuted empirically — locks absent for live
  sessions (under-detection re-introduces the reap risk).
- mtime recency: prohibited by the requirement itself (liveness is knowable, not
  a guess).
- Harness registry/heartbeat: no writer exists; a registry nobody writes
  under-detects 100 %.
- fuser per worktree root: subtree-blind on macOS (misses holders cwd'd in
  subdirectories) without an O(dirs) walk.
- claude-PID-scoped lsof (strongest surviving alternative): fewer processes
  scanned, but pins a process name (version-fragile) and structurally misses
  non-claude holders (operator shells, editors) that produce the identical
  cwd-deleted failure. The all-process scan is a strict detection superset at
  measured negligible cost (0.26 s).
- All-fd liveness predicate (`lsof -Fn` without `-d cwd`, adversarial
  counter-design): a strict detection superset covering open-fd holders, but
  measured at 6.99 s / 25,807 fd rows on this host at the time (27× the cwd scan) and
  carries a starvation risk the cwd predicate avoids (indexer/daemon fds can
  pin trees indefinitely). Documented as the re-triage target of the 30-day
  monitoring criterion below, not adopted now.
- /proc cwd walk: no /proc on the deploy host (macOS); documented as the natural
  Linux fallback seam if lsof ever proves unavailable there.

## Consequences
- A worktree held by ANY same-user process (not only Claude sessions) is
  protected — deliberately broader than the originating incident class, because
  removing any process's cwd produces the same failure.
- Hosts without lsof at either canonical path never remove worktrees (fail-closed)
  until the oracle is restored; branches remain sweepable.
- The snapshot is point-in-time. With the apply-time re-check, the residual
  TOCTOU window is the seconds between the re-check and the porcelain call;
  there is no further backstop for a holder arriving inside that window (the
  post-apply verify pass detects survivors, never wrongful removals).
- Non-covered holder classes (accepted residual): the predicate is
  cwd-at-or-under only — it cannot see open-fd holders (editor buffers, log
  tails) or absolute-path operators whose cwd is elsewhere. The dirty-skip
  covers the uncommitted-work subset; the residual is clean trees under
  absolute-path use.
- The self-canary is necessary-not-sufficient: it witnesses that the scan ran
  and parsed (binary present, format intact), not that the process enumeration
  is complete. A same-user process lsof cannot stat is silently absent with
  exit 0. Fail-closed posture plus the apply-time re-check bound the exposure;
  no stronger cheap witness exists on macOS without root.
- 30-day outcome-window monitoring criterion: any reap incident in the Stage 13
  outcome window where the affected session's cwd was OUTSIDE the removed tree
  re-triages the oracle definition toward the all-fd predicate (whose cost and
  starvation trade-offs are recorded under Alternatives).
- Report vocabulary gains "SKIP — live session (pid N, command)" and a top-level
  JSON "liveness_oracle" field; the skip label names the holder so the operator
  can release a tree deliberately (quit the holder) rather than forcing.

## Reversibility
CHEAP — classification-side plus one additive apply-loop re-check; a revert
restores prior behavior. Confidence HIGH on mechanism (host-validated), MEDIUM
on cross-platform variance until a Linux host exercises the path.

## Related ADRs
None upstream. Platform-global monotonic numbering continues from ADR-020 (core).
