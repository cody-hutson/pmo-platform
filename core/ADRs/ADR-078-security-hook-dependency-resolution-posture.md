<!-- reference-durability: allow-link -->
---
title: "ADR-078 — Security-hook dependency-resolution posture: shared absolute-path resolver + mode-coupled fail-closed"
status: Accepted
date: 2026-07-11
release: unbound (bound at Stage 12)
deciders: "operator (remediation-scope approval + warn-vs-enforce posture decision, this session) + adversarial security review (GHSA-9cjm intake)"
tags: [security-hooks, PreToolUse, fail-closed, dependency-resolution, jq, GHSA-9cjm, fail-open, defense-in-depth]
source_observations:
  - "The PreToolUse security hooks pinned PATH=/usr/bin:/bin (anti-hijack) and hard-coded JQ=/usr/bin/jq, then exited 0 (fail-OPEN) when jq was unresolvable — silently disabling the perimeter on the documented `brew install jq` macOS install, where jq lands at /opt/homebrew/bin/jq and /usr/bin/jq does not exist."
  - "The resolution logic was duplicated inline across ~13 hooks, so the class drifted: a fix to one hook did not fix the others, and the next hook authored copied whichever neighbor it saw."
  - "The block message advertised CLAUDE_HOOK_BYPASS=1 as the recovery, but the bypass check ran AFTER the dependency gate and itself used jq — dead in exactly the missing-jq case it named."
  - "block-fs-boundary carried a SECOND fail-open of the same class: python3 was the sole `..`-normalizer, guarded by `[ -x ]` with an un-normalized fallback, so a missing/erroring python3 allowed workspace-boundary traversal."
---

# ADR-078 — Security-hook dependency-resolution posture

## Status

**Accepted.** Ratified this session by the operator's approval of the GHSA-9cjm remediation scope (full-class hardening) and the explicit warn-vs-enforce posture decision (warn hooks preserve warn semantics; enforce hooks fail closed). Recorded at authoring because the deciding gate — operator approval of the enumerated remediation plan — already ran; this ADR is the durable record of the posture those approvals fixed.

## Context

The `PreToolUse` security hooks (`core/hooks/block-*.sh`) parse their tool-call JSON with `jq`. To resist binary-hijack they pin `PATH=/usr/bin:/bin` and reference tools by absolute path. `jq`, however, is not a macOS system binary: the documented `brew install jq` places it at `/opt/homebrew/bin/jq` (Apple Silicon) or `/usr/local/bin/jq` (Intel), never `/usr/bin/jq`. The historical hooks hard-coded `JQ=/usr/bin/jq` and, when it was absent, `exit 0` — **fail-open**, silently disabling the whole perimeter (credential-read, egress, filesystem-boundary, MCP-write, destructive-command, and more) on a documented install. Reported as **GHSA-9cjm-v22x-4x33** and confirmed by adversarial review to be a **repo-wide class** (~13 hooks share the pattern), not a point bug; the review also found a distinct second fail-open (python3 path-normalization in `block-fs-boundary`) and a dead escape-hatch in the first-drafted fix.

Two forces shape the decision. **(1)** A security control that cannot evaluate its input must not silently ALLOW — but blanket fail-closed everywhere would over-block hooks that ship in *warn* mode (which never block on a rule match), and rejecting any non-root `jq` outright would make brew-only hosts unusable. **(2)** The resolution logic must have exactly one home, or the class re-drifts.

## Decision

**D1 — One shared resolver (`core/hooks/lib/dep-resolve.sh`).** All hooks resolve `jq` (and `python3`) through a single sourced helper that probes a **fixed absolute-path allowlist** (`/usr/bin`, `/opt/homebrew/bin`, `/usr/local/bin`) and **prefers a root-owned (uid 0) binary**, falling back to a user-owned one only when no root-owned candidate exists. The resolver **never widens `$PATH`** — doing so would reintroduce the exact binary-hijack the `PATH` pin prevents. `resolve_*` never exits; it returns a path or the empty string, so the caller controls the failure posture.

**D2 — Missing-dependency posture is mode-coupled.** When the parse dependency is unresolvable:
- **enforce** (and always-enforce hooks with no `.mode`): **fail CLOSED** (`exit 2`, `DEPENDENCY-MISSING`). A control that cannot parse its input must DENY.
- **warn / off**: **degrade** (`exit 0`, `DEPENDENCY-DEGRADED`). A warn-mode hook never blocks on a rule match, so a missing dependency must not block *harder* than a rule match would.
- **audit** hooks (non-blocking by nature): degrade (`exit 0`).

The posture is read from the hook's own mode file (jq-free `cat`/`tr`), so a hook classifies correctly regardless of `jq`.

**D3 — Escapes evaluated before the gate.** The `.mode=off` short-circuit and the `CLAUDE_HOOK_BYPASS=1` escape hatch are evaluated **before** the dependency gate and are made dependency-optional, so both remain reachable when `jq` is missing — fixing the dead-escape-hatch defect. (`CLAUDE_HOOK_BYPASS` must be set before launching the agent; a mid-session Bash attempt to set it is itself denied by the anti-injection rules.)

**D4 — The helper source itself fails closed.** Each hook tests the helper's readability *before* sourcing (`[ ! -r ] || ! . || ! command -v resolve_jq`) and exits 2 on any failure. This is required because macOS's bash 3.2 exits 1 on a failed `source` even inside an `if !` condition, and exit 1 (unlike exit 2) is NON-blocking in the `PreToolUse` contract — a missing helper would otherwise fail OPEN.

**D5 — A CI guard prevents re-drift.** `core/hooks/tests/check-hook-dep-hardening.sh` (Security workflow, job `hook-dep-hardening`) fails the build if any hook hard-codes `/usr/bin/jq`, carries the legacy blanket fail-open message, or calls `resolve_jq` without sourcing the helper.

## Alternatives rejected

1. **Per-hook inline resolution (status quo, patched hook-by-hook)** — leaves the class intact; the duplication is the maintainability root cause that produced the vulnerability and would reintroduce it.
2. **Widen `$PATH` to include the Homebrew dirs** — the simplest way to "find jq", and the wrong one: it reopens the binary-hijack the `PATH` pin exists to close.
3. **Uniform fail-closed for every hook regardless of mode** — over-blocks warn-mode hooks (a missing dependency would block *harder* than a rule match), and turns a missing prerequisite into a total tool-use DoS with no graceful mode.
4. **Reject any non-root `jq` outright** — hardens the trust oracle but makes every brew-only host (jq user-owned under `/opt/homebrew`) hard-block on every tool call. D1's *prefer* root-owned, *fall back* to user-owned keeps brew-only hosts functional while hardening the common case; the residual (a user-writable `jq` as oracle) is within the existing single-OS-user trust boundary and documented below.

## Consequences

- **+** The fail-open class is closed across the hook suite from one resolver, and a CI guard keeps it closed.
- **+** The escape hatches (`.mode=off`, `CLAUDE_HOOK_BYPASS`) are real in the missing-dependency case, and a missing/corrupt helper fails closed rather than open.
- **+** `block-fs-boundary`'s second fail-open is closed: `..` tokens are rejected independent of python3, and normalization fails closed when python3 is unresolvable.
- **−** **A deliberate fail-policy split remains by design:** enforce/always-enforce hooks fail closed on missing jq while warn/off hooks degrade to exit 0. This is intended (warn never blocks), but means a missing-jq host is not uniformly protected — the warn-mode surface is fail-open until jq is installed. Named residual, not a defect.
- **−** On a host lacking `/usr/bin/jq`, the resolver selects a **user/group-writable** `jq` (`/opt/homebrew/bin`) as its oracle. An attacker who can write there can re-silence the jq-dependent perimeter — but that write capability already lets them shadow any tool the operator runs, so it is within the existing trust boundary. Mitigated by root-owned preference; fully closing it (vendored/pinned root-owned jq) is deferred.
- **−** `block-autonomy-ceiling`'s Tier-0 always-block floor is bypassed if its `.autonomy-mode` is later promoted warn→enforce while jq is unresolvable; flagged for the promotion decision.

## Reversibility

**CHEAP** / Confidence **HIGH**. The change is confined to `core/hooks/` (the shared helper, the hook preambles, tests) plus one CI job and one `setup-workspace.sh` check; a single-PR revert restores the prior behavior. The reverted-to state is the *vulnerable* one, so revert is a rollback of the fix, not a safe fallback.

## Related ADRs

- None at kernel altitude — this is the founding record for the security-hook dependency-resolution posture. Future hooks that parse tool-call input inherit D1–D4 by sourcing `lib/dep-resolve.sh`; the CI guard (D5) enforces it.
