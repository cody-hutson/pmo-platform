---
title: ADR-013 — detect_install_path session-resolution policy + COWORK_AVAILABLE seam (SESSION cluster)
status: Accepted
date: 2026-06-03
deciders: "operator + Stage 5 Solutioning spokes (session-resolution cluster) + Stage 5 Collective Review scope-lock"
tags: [deploy, session-resolution, release-ops, install-blockers, error-handling, bash-set-e]
source_observations:
  - Stage 5 Solutioning (detect_install_path session-tiebreaker) — config-resolution ladder + Check-8 re-point
  - Stage 5 Solutioning (deploy.sh hardcoded fallback session-path) — structured-error fallback; remove the last literal session UUID
  - Stage 5 Solutioning (skill deploy hard-fails without a Cowork path) — COWORK_AVAILABLE flag-guard; user-local mirror stays unconditional
  - Stage 5 Collective Review scope-lock (2026-06-03) — shared "structured-signal, NOT bare die" contract for the cluster; Check-8 consolidation
  - Source finding lineage: an orphaned Cowork session out-ranked the live session on directory mtime, deploying skills into a dead path
---

# ADR-013 — detect_install_path session-resolution policy + COWORK_AVAILABLE seam

## Status

Accepted at the Stage 5 Collective Review scope-lock (2026-06-03);
ratified into the release branch at the
session-resolution Engineering commits. The three sibling fixes that compose
this contract (config-first resolution ladder + Check-8 re-point; structured-
error fallback removing the last literal UUID; the `COWORK_AVAILABLE` flag-guard)
land as one serialized cluster on `core/deploy/deploy.sh` under the single-branch
topology.

## Context

`core/deploy/deploy.sh` `detect_install_path()` resolves the Cowork
skills-plugin install path without hardcoded UUIDs by enumerating session dirs
under `skills-plugin/` and, when two or more fingerprinted candidates exist,
picking the most-recently-modified directory (`ls -dt … | head -1`).

Three structural defects converged on this one function:

1. **mtime is not a correctness signal.** An orphaned session (a stale UUID left
   by a Cowork plugin reinstall, app update, or re-auth) keeps its Cowork-provided
   skills, so it passes the fingerprint filter and can out-rank the live session
   on mtime — causing the deploy to write skills into a dead path. This is the
   originating finding (an orphaned session selected over the live one).

2. **A hardcoded fallback session UUID was frozen into the repo.** The zero-
   candidate branch assigned a literal `…/skills-plugin/<UUID>/<UUID>/skills`
   path. A Cowork session UUID is per-install runtime state, never a repo
   constant, so the value was meaningless on any machine but the one that
   authored it — and it was the last literal session UUID in the tree, a public-
   safety and reference-durability liability.

3. **The terminal `die` hard-failed a supported install case.** The function
   ended in `[[ -d "$INSTALL_PATH" ]] || die`. Because the script runs
   `set -euo pipefail` and the installer calls the deploy phase as its last
   statement, that `exit 1` propagated and deployed zero skills on a
   Claude-Code-CLI-only machine with no Cowork session — even though the
   user-local `~/.claude/skills` mirror needs no Cowork session at all.

Additionally, the canonical-session-path freshness check (Check 8) grepped
`skill-deployment.md` for a literal `skills-plugin/<uuid>/<uuid>` pair. The doc
is fully tokenized (`[SESSION_UUID]`), so the grep matched nothing and the check
was permanently inert; worse, the bare command-substitution assignment
`c8_doc_path=$(grep … | head -1)` returns non-zero on no match and, under
`set -euo pipefail`, aborted `--check`/`--check --warn` at Check 8.

## Decision

Separate two concerns and give each a single owner, joined by one shared seam.

### A. Resolution — which path, or none (a deterministic ladder; mtime demoted)

`detect_install_path` resolves via an ordered ladder; mtime is a logged last
resort, never the primary signal:

1. **Config base (authoritative).** Read `[paths].cowork_install_path` from
   `operator.toml` using the established deploy-script reader idiom (the same one
   that resolves the audit-tracker repo). The base is captured at clean install
   (before any orphan exists), so it is orphan-immune. When set, enumerate
   sessions under that base; otherwise fall back to the default search root.
2. **Single candidate.** If exactly one session resolves, use it.
3. **Fingerprint + skill-count.** Among fingerprinted candidates, prefer the one
   with the most deployed skill directories — the live session carries the full
   PMO roster, a stale one lags. This is a stronger signal than mtime and is
   deterministic whenever the live session is fuller than the orphans.
4. **Logged mtime (last resort).** Only on a skill-count tie, fall back to mtime
   BUT log explicitly that a non-authoritative heuristic was used.
5. **Structured terminal.** If nothing resolves, set `INSTALL_PATH=""` and
   `return 2` — NOT a bare `die`. The function never exits the process; the
   caller decides whether to warn-and-continue or abort.

The zero-candidate hardcoded fallback UUID is removed (the structured terminal
replaces it): the zero-candidate branch yields an empty `INSTALL_PATH`, which the
structured terminal converts to `return 2`. This deletes the last literal session
UUID from the repo.

Check 8 is re-pointed to validate the detected `INSTALL_PATH` against the
`operator.toml [paths].cowork_install_path` base (the real canonical source),
not the tokenized doc. Config absent is a `SKIP` (the absence of an optional
override is not drift), not a WARN. This also removes the inert doc-grep that was
tripping `set -e`.

### B. Command response to "none" — warn and continue (the COWORK_AVAILABLE seam)

A module-level boolean `COWORK_AVAILABLE` (initialized `false` at the top of the
script, beside `INSTALL_PATH=""`, so it is always defined under `set -u`) is the
shared seam between resolution and command behavior. `cmd_deploy` resolves the
path non-fatally and sets `COWORK_AVAILABLE=true` only when a usable Cowork path
exists. It then guards the Cowork-target write blocks (the skill copy + verify,
supplementary content, references mirror), the package loop, and the deleted-
skill Cowork warning behind `COWORK_AVAILABLE`. The user-local mirror
(`deploy_skill_user_local`, the `~/.claude/skills` mirror) and the user-local
half of canonical-template injection stay **unconditional** — they read no
session path and are correct with no Cowork session present.

`sync_canonical_templates_to_runtime` gates only its install-target write block
on `COWORK_AVAILABLE`; the user-local write block always runs, and the canonical-
source-missing failure stays unconditional (a missing canonical is a genuine
repo-integrity failure, not a Cowork-presence issue).

The genuine-failure terminal `die` (on accumulated deployment failures) stays —
but with the guards in place, a no-Cowork run produces no Cowork-target failures,
so it exits 0 after mirroring user-local skills.

## Consequences

**Positive:**
- Deterministic, orphan-immune resolution when config is present; the skill-count
  tiebreaker disambiguates live-vs-orphan where mtime could not.
- The last literal session UUID is gone — public-safe and machine-agnostic.
- A Claude-Code-CLI-only machine (no Cowork) gets its user-local skills and exits
  0; the installer completes instead of hard-failing with zero skills.
- Check 8 is meaningful again (re-pointed to the real source of truth) and no
  longer aborts `--check` under `set -e`.

**Negative / costs:**
- `detect_install_path` is coupled to the `operator.toml` contract (acceptable —
  the same contract already governs other paths in this script).
- A module-level `COWORK_AVAILABLE` flag is mild shared state across the cluster;
  this ADR documents the seam so future readers understand it.
- `cmd_check` and `cmd_report` also call `detect_install_path` and now degrade
  gracefully with no Cowork session (an improvement; their Check 8/12/13 already
  guard on `INSTALL_PATH` presence).
- If `setup-workspace.sh` did not auto-populate `cowork_install_path`, day-one
  fresh installs would lean on the fingerprint/skill-count/mtime ladder until the
  session is unambiguous; correctness holds at the single-candidate rung. (The
  install-time token resolution maps `[COWORK_INSTALL_PATH_BASE]` to this field,
  so the field is populated at setup.)

## Alternatives Considered

- **`.canonical-session` marker file** — REJECTED. No Cowork-side API to write it;
  a deploy-side self-marking write is circular on the first multi-candidate run.
  No existing surface precedent.
- **Documented-path priority (grep the canonical UUID from skill-deployment.md)**
  — REJECTED. Infeasible: the doc is token-only; nothing to grep. Couples
  detection to governance-doc format even if a UUID were restored.
- **Skill-count alone as the primary** — REJECTED as primary, retained as ladder
  rung 3. Heuristic, not authoritative; a freshly-orphaned session can momentarily
  tie. Config resolution is the authoritative rung 1.
- **Remove the terminal `die` only (leave the loop interleaving Cowork writes with
  the user-local mirror)** — REJECTED for the flag-guard's half. It does not work:
  the loop body still fails on an empty `INSTALL_PATH` and hits the accumulated-
  failures `die`, and template injection into `~/.claude/skills` is collateral-
  damaged. The flag-guard is the smallest change that is actually correct.

## Reversibility

CHEAP — the changes are per-function and per-region in `detect_install_path`,
`cmd_deploy`, `sync_canonical_templates_to_runtime`, and Check 8, plus a module-
level flag init. `git revert` restores the prior behavior. The `operator.toml`
schema is unchanged (the `cowork_install_path` field already existed; this ADR's
fixes only read it). No governance or platform-state coupling.

**Confidence:** HIGH — the ladder's live-vs-orphan disambiguation was verified
against a real multi-session machine (four fingerprinted candidates; the skill-
count rung selected the live session, not an orphan); the `set -e` abort of the
old Check-8 doc-grep was reproduced and confirmed removed.

## Composition with other ADRs

- ADR-008 (deploy.sh per-module array design) — the same `set -euo pipefail`
  discipline and empty-array/`set -e` safety constraints apply to the new ladder
  code (bash 3.2-safe, `|| true`-guarded probes, no bare failing command
  substitution in an assignment).
- ADR-010 (secrets-handling policy substrate) — removing the last literal session
  UUID aligns with the personal-data / public-safety posture for tracked source.

## References

- COWORK_AVAILABLE gate seam (the flag-guard half of this cluster:
  "skill deploy hard-fails without a Cowork path; user-local mirror never
  reached"), engineered in the same SESSION cluster on `core/deploy/deploy.sh`.
- Companion ADR: [`ADR-014-managed-section-two-hash-tamper-detection.md`](ADR-014-managed-section-two-hash-tamper-detection.md) (sibling install-blockers ADR on this release branch).
- Stage 5 Collective Review scope-lock (2026-06-03) — shared "structured-signal, NOT bare die" contract for the session-resolution cluster.
