<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Rigor is invariant of scaffolding; close-completeness is asserted by a scaffold-independent gate
status: Accepted
date: 2026-06-28
release: 91-release-notes-conformance
deciders: "Workspace owner"
tags: [pipeline, release, governance, close-out, invariant, rigor-invariance, scaffold-independent, reversibility-cheap]
---

# ADR-048 — Rigor is invariant of scaffolding; close-completeness via a scaffold-independent gate

## Status

**Accepted.**

Number **048** — next gap-free after 047; binds atomically at Stage 12.

## Context

A work-item scaffold (the Procedure 1 Sub-Task Template) determines WHICH tasks exist for a release. Two coupled defects let the same scaffold also determine the *rigor* of close-out:

- The Sub-Task Template binds a stage's *metadata* (Purpose / Inputs / Outputs), not its canonical Phase checklist — so an abbreviated body can silently drop a codified step.
- The close-completeness gate (the Procedure 7 Step 4 output-set verification) is itself **hub-narrative-executed** — it fires only if the hub remembers to run Procedure 7. An abbreviated scaffold therefore drops a codified step *and* the gate that would have caught it, and the release self-reports complete against its own abbreviated checklist.

A prior release's incomplete close (a missing published GitHub Release, surfaced only by later manual review) is the motivating instance. An earlier slice made the note-content and published-body sub-checks path-independent, but the *output-set-completeness* invariant itself stayed scaffold/hub-memory-dependent — a recorded deferral. The completeness invariant needs an enforcement that does not depend on the scaffold, the sub-task body, or a hub session being in the loop.

## Decision

**Rigor is an invariant of scaffolding: a scaffold selects tasks; it never attenuates the rigor of any task's codified Phase checklist.** Every codified Phase step runs whether or not the scaffolded body names it, and whether the stage runs as a spawned spoke or hub-direct. Three mechanisms make the invariant hold without depending on the hub remembering it:

1. **Codify the principle at the scaffolding seam** — a named Rigor-Invariance Principle in Procedure 1, a bind-by-reference line and a canonical-checklist attestation in the Sub-Task Template, and a hub-direct≡spoke equivalence clause (collapsing stages waives no codified Phase step). The attestation is the human-readable forcing function.

2. **Assert completeness with a scaffold-independent gate** — `deploy.sh --check` **Check 48** (plus a verdict-driven `--check-close-completeness` CI probe sharing one body) asserts the complete canonical Stage-13 output-set on main for every `VERIFIED` `RELEASE_LOG` row at/after a cutover. The gate fires on a plain checkout with no scaffold, no sub-task body, and no hub session — it reads main's state, not the execution path that produced it. That is scaffold-independence by construction, and it is the machine backstop the principle names.

3. **Compose, never duplicate** — Check 48 is an *umbrella invariant* that delegates each sub-assertion to the engine that already owns it (note-content to the corpus lint, body-drift to the body-drift tool, companion-presence to the same path resolution the companion-presence check uses). It re-implements none of them; it aggregates them under one contract: "all codified close steps fired, regardless of scaffold." It sits beside the companion-presence check rather than folding into it, so that check's in-flight warn-mode shakedown stays undisturbed while Check 48 owns the VERIFIED-full-set-completeness contract.

The gate ships warn-mode-initial and dormant-by-default (a cutover sentinel keeps it from retroactively flagging historical rows), with the cutover anchored strictly **after** the introducing release's merge — a release never gates its own close (the reflexive-pipeline-loop discipline). A regression proves the invariant: a deliberately-abbreviated scaffold (a VERIFIED row missing a Stage-13 output) is still caught before the release can be reported complete.

## Alternatives Considered

- **Full transcription of the Phase checklist into every sub-task body** — rejected: drift-prone (every stage-spec edit must re-sync every scaffold) and the copy itself becomes the new abbreviation surface. Bind-by-reference is the lower-drift default; transcription remains a permitted fallback.
- **Extend the existing companion-presence check in place** — rejected: it conflates two distinct contracts (DEPLOYED-companion-presence vs VERIFIED-full-set-completeness, which additionally covers note-content and body-drift) and disturbs that check's in-flight warn-mode shakedown.
- **Wrap the Step 4 commands in a script the hub must call** — rejected: a script the hub can forget to call is still scaffold/hub-invoked, which is the defect. Only a gate that reads main's state independently of the execution path is scaffold-independent.
- **A server-side pre-receive / branch-protection gate** — rejected: no governed, portable Git-host hook surface, and it is not reproducible from a clone.

## Consequences

- Close-completeness becomes a machine-checkable invariant independent of agent memory and CI-enforceable, reusing proven tooling with no logic duplication.
- The principle generalizes the existing "a direct merge does not waive the close outputs" clause from the merge-ahead case to **all** hub-direct execution.
- The gate inherits the companion-presence check's LOG-row blind spot — a close that never wrote its `RELEASE_LOG` row is invisible to it. LOG-row presence remains the responsibility of the close-time Step 4 table. This is an accepted, documented residual.
- One always-on check is added, but warn-mode-initial and cutover-scoped, so there is zero blocking impact until an operator opts in — and no historical false-positive storm.

## Reversibility

**CHEAP / Confidence HIGH.** The doc changes and the check are additive — `git revert` removes them atomically. The check ships warn-mode-initial and dormant (non-blocking until an operator sets the cutover and commits the enforce sentinel), so reverting it has no live-contract impact to unwind. Confidence is HIGH that a scaffold-independent gate is the right mechanism: it is the only option that asserts completeness without the scaffold, the body, or a hub session in the loop, which is precisely the property the defect requires.

## Related ADRs

- [ADR-019 — Specialists compose, not absorb](ADR-019-specialists-compose-not-absorb.md): the same compose-not-duplicate principle at the skill layer that this ADR applies to the close-completeness check — reuse a capability by delegation, never by fork.
- [ADR-032 — Release-corpus public-vs-instance split](ADR-032-release-corpus-public-vs-instance-split.md): the release-corpus mechanism (templates, schema, tools, deploy checks) is the public surface into which this gate ships, while per-release content stays operator-instance.

## Provenance

Decision lineage, for audit only — not load-bearing on the decision above (it reads version-agnostically). Source: the incomplete-close observation tracked under #1290; the scaffold-independent completeness gate is the slice that builds the previously-recorded deferral.
