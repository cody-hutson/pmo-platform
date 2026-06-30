---
title: Audit-Recommendation Status-Badge Standard
purpose: Defines the per-recommendation status-badge convention (OPEN / BUNDLED / SHIPPED / DEFERRED / REJECTED) maintained at merge-time so shipped audit recommendations stop reading as open scope.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: audit/review recommendations.md authors; release-planner and triage (so shipped recommendations stop reading as open scope); CLAUDE.md §Audit-baseline discipline
---
# Audit-Recommendation Status-Badge Standard

## Purpose

Audit and review `recommendations.md` artifacts list their recommendations as a flat list with no per-recommendation status indicator. Recommendations frequently ship same-day as the audit that surfaced them, yet the file keeps reading as forward-looking — so downstream readers (release planners, hub agents, anyone mining an audit for open scope) re-propose work that already shipped. A per-recommendation **status badge**, maintained at merge-time, fixes this: each recommendation carries a token that says where it sits in the delivery lifecycle, and the token is advanced by the pipeline stage that owns the state change.

This standard defines the closed 5-badge enum and the merge-time maintenance protocol. It does not gate, and is not gated by, retroactive backfill of existing operator-local audit files (see § Scope boundary).

## The 5-badge enum

Every recommendation in a `recommendations.md` carries exactly one badge. The enum is closed — these five tokens are the complete set; no other badge form is valid.

| Badge | Meaning | Set when | Transitions from |
|---|---|---|---|
| `[OPEN]` | Recommendation is live, not yet committed to a release bundle | At audit authoring — the default state of every new recommendation | — (initial state) |
| `[BUNDLED v<release>]` | Recommendation is committed to a named release bundle, not yet shipped | At Bundle, when the recommendation's tracked work item joins a versioned Milestone | `[OPEN]` |
| `[SHIPPED ✓ #<n>]` | Recommendation shipped; `#<n>` is the closing work-item number | At Close (merge-time), when the recommendation's work item closed in the release | `[BUNDLED v<release>]` (or directly from `[OPEN]` when shipped without a prior bundle row) |
| `[DEFERRED #<n>]` | Recommendation consciously deferred; `#<n>` is the carry-forward work-item number | At Bundle or Close, when the recommendation is deferred to a later cycle | `[OPEN]` or `[BUNDLED v<release>]` |
| `[REJECTED]` | Recommendation will not be actioned (superseded, invalid, or out-of-scope) | At triage or review, on a documented reject decision | any non-terminal state |

Notes on the badge tokens:

- The `v<release>` segment in `[BUNDLED v<release>]` is a version label written as a narrative marker (the rendered badge names the concrete bundle version, e.g. `[BUNDLED v<minor-release>]`) — it names the bundle the recommendation rides, not a load-bearing reference.
- The `#<n>` segment in `[SHIPPED ✓ #<n>]` and `[DEFERRED #<n>]` is a literal format placeholder for the closing or carry-forward work-item number — substitute the actual number when the badge is set (the rendered badge reads `[SHIPPED ✓ #<closing-work-item>]`). The placeholder `<n>` is not itself a live reference.

## Merge-time maintenance protocol

Badges are not maintained on a separate cadence — they transition at the pipeline stage that owns the corresponding state change, so the badge is always a side effect of work that is already happening. The owning stage and trigger for each transition:

| Transition | Owning stage / moment | Trigger |
|---|---|---|
| → `[OPEN]` | Audit authoring | A new recommendation is written into `recommendations.md` |
| `[OPEN]` → `[BUNDLED v<release>]` | Bundle | The recommendation's work item joins a versioned Milestone |
| `[BUNDLED v<release>]` / `[OPEN]` → `[SHIPPED ✓ #<n>]` | Close (merge-time) | The recommendation's work item closed in the release |
| `[OPEN]` / `[BUNDLED v<release>]` → `[DEFERRED #<n>]` | Bundle or Close | The recommendation is deferred to a later cycle |
| any non-terminal → `[REJECTED]` | Triage or review | A documented reject decision is recorded |

**Terminal vs. non-terminal states.** `[SHIPPED ✓ #<n>]` and `[REJECTED]` are terminal — a recommendation in either state does not re-enter the flow. `[OPEN]`, `[BUNDLED v<release>]`, and `[DEFERRED #<n>]` are non-terminal: a deferred recommendation re-enters the flow in a later cycle (re-triaged, then re-bundled), and a bundled recommendation advances to shipped or deferred at Close.

**The release-time forcing function.** The Close half of this protocol — advancing a recommendation to `[SHIPPED ✓ #<n>]` or `[DEFERRED #<n>]` once its work item closes in the release — is wired into the close-out protocol as a release-time maintenance beat (the Stage 13 audit-recommendation badge-update step). That beat is the forcing function that keeps shipped recommendations from re-reading as open scope. It operates on operator-local audit files at release time and is non-blocking for milestone close (see § Scope boundary).

## Scope boundary

This standard, and the close-out beat that enforces its release-time half, define a **convention plus a protocol hook**. They do not perform, and are not gated by, retroactive backfill of existing audit files.

The audit `recommendations.md` files live under the operator-instance `analysis/` tree, which is git-ignored operator-local content — it is not part of the tracked repository. Retroactive backfill of badges into existing `analysis/<audit>/recommendations.md` files is therefore an **operator-local follow-up, outside repo scope, and not gated by this standard**. An agent operating on the tracked repository cannot reach those files; the durable platform deliverable is the convention and the protocol hook, and the backfill is operator discretion performed in the operator-instance workspace.

New audits author their recommendations with badges from the outset (every new recommendation starts `[OPEN]`); existing audits are brought into conformance at the operator's discretion, not as a gated step of any release.
