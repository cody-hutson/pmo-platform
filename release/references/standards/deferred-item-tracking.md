---
title: Deferred Item Tracking
purpose: K1 codified-knowledge standard for the Stage 13 close-out disposition of issues bundled-but-not-closed at release close — comment-trail pointer mechanism + extension of Phase A2 from one-bullet to enumerated procedure
type: standard
parallel_to: ticket-information-architecture.md (the Stage 2 defer protocol this composes with at the release-boundary), label-taxonomy.md (the `status: deferred` label this consumes — zero new labels), release-corpus-schema.md (the chore-PR carrier this writes the disposition summary into)
reversibility: CHEAP (forward-only protocol; pre-cutover releases exempt; comment-trail is append-only and would not require migration if a future release supplements with a body-field surface)
consumers: "release/governance/release-process.md Stage 13 § Deferred item disposition (capture surface); pipeline/stage-13-close.md Phase A2 (procedure consumer); automated-closeout.sh (label-keyed query read-surface — `gh issue list --milestone X.Y --label \"status: deferred\"`); release-executor Mode D / D-FormFactor (B) (inherits the read pattern via script wrapping)"
version: v12.12
---

# Deferred Item Tracking

## 1. Purpose

The PMO platform already defines the Stage 2 Triage defer protocol — `status: deferred` label applied at Triage, milestone removed, issue stays OPEN, re-triage required before re-bundling. That protocol fires BEFORE bundling. Until this standard, no protocol fired for the symmetric case at the release-boundary: an issue that WAS bundled into a release (Stage 3), the release shipped (Stage 12), but the issue was NOT closed at Stage 13. The Cowork Execution Runbook precedent — deferred post-merge — is the canonical post-merge defer precedent.

This standard codifies a thin extension to the existing infrastructure: it does NOT introduce new labels, body fields, or pipeline events. The `status: deferred` label is the same one the Stage 2 protocol applies; the Stage 2 defer execution semantics are unchanged; the release-boundary application is the new layer. The Stage 13 Phase A2 step extends from one-bullet ("confirm tracked, not blocking close") to an enumerated procedure that enumerates → labels → de-milestones → posts a canonical comment trail → summarizes in the Stage 13 chore PR body.

**Scope:** Release-boundary deferrals at Stage 13 close — issues bundled into a release but not closed when the release closes. Per-issue current-state is the body-level `status: deferred` label; per-issue history is the comment trail.

**Out of scope:** Pre-bundle defers at Stage 2 (governed by [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) § Stage 2 Triage — unchanged); per-issue Outcome tracking on multi-PR releases (the release-level `**Outcome:**` field per [`decision-outcome-tracking.md`](decision-outcome-tracking.md) is release-scoped, not issue-scoped); terminal-archive disposition per the closed-as-NOT_PLANNED precedent (a distinct disposition pattern — see § 4 below).

## 2. Existing infrastructure (cited verbatim, not duplicated)

The Phase A0 re-review at the release-plan sub-task established that the convention is NOT green-field. The following infrastructure is ALREADY shipping; this standard cites without duplicating per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md).

**`status: deferred` label** per [`label-taxonomy.md` line 36](../../../core/specs/label-taxonomy.md):

> `status: deferred` — Triaged, deferred to backlog — re-triage required for milestone bundling

Color `FBCA04` (amber). Applied at Triage (Stage 2); removed at re-triage (returns to `status: proposed` or `status: approved`). This standard reuses the same label at the release-boundary — no new label is introduced.

**Stage 2 defer state-transition** per [`ticket-information-architecture.md` line 232](../specs/ticket-information-architecture.md):

> Deferred → `status: deferred` applied; Milestone removed; issue stays OPEN. Re-triage required before re-bundling (returns to `status: proposed` for full re-evaluation, or `status: approved` if priority/scope unchanged).

**Stage 2 defer execution** per [`ticket-information-architecture.md` line 500](../specs/ticket-information-architecture.md):

> Defer: sets `status: deferred` label (removes `status: proposed`), removes Milestone assignment if any, leaves issue OPEN. Cluster label applied. Re-triage required for re-bundling.

**Stage 2 defer Automation-vs-Agent row** per [`ticket-information-architecture.md` line 622](../specs/ticket-information-architecture.md):

> Stays at Proposed (no field change — issue stays OPEN). Stays at 2-Triage. Agent → `status: deferred` (removes `status: proposed`); Milestone removed. Agent → today's date.

**Terminal-archive precedent (distinct disposition pattern):** The terminal-archive case was closed-as-NOT_PLANNED + milestone-tagged-as-historical-record. This is **terminal-archive** — confirmed obsolete + milestone-as-evidence. It is NOT the same as a deferral that re-enters Stage 2 Triage (open + re-triage). Per the least-destructive-disposition discipline, park-in-container (the deferral path) is the default; terminal-archive is reserved for items confirmed obsolete via operator decision.

## 3. Stage 13 close-out procedure

Extends [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) Phase A2 from one bullet ("Deferred item disposition (confirm tracked, not blocking close)") to an enumerated procedure. Stage 13 spoke executes the steps below before the Phase B chore PR is created.

**A2.1 — Enumerate bundled-but-not-closed issues:**

```bash
gh issue list --milestone "v<X.Y>-<slug>" --state open \
  --repo {REPO} --json number,title,labels
```

A zero-row result is the clean-close case — proceed to A2.3 with `Deferred items: none (clean close)`.

**A2.2 — For each bundled-but-not-closed issue `#N`:**

1. Apply `status: deferred` label, remove the pre-deferral status label:
   ```bash
   gh issue edit <N> --add-label "status: deferred" \
     --remove-label "status: bundled" --remove-label "status: in-progress"
   ```
2. Remove the milestone assignment (Stage 2 defer semantics — issue is no longer bound to the closing release):
   ```bash
   gh issue edit <N> --remove-milestone
   ```
3. Post the canonical comment trail (template in § 4 below). The comment IS the pointer — the milestone is removed, so the originating-release link lives in the comment.
4. Verify the Projects Status field stays Proposed per the Stage 2 defer state-transition row at [`ticket-information-architecture.md` line 622](../specs/ticket-information-architecture.md) — Status does not change on defer; the issue stays OPEN.

**A2.3 — Disposition summary in two surfaces** (per Stage 5 spec Finding 2):

| Surface | Content | Voice |
|---|---|---|
| Stage 13 sub-task comment | FULL enumeration: one row per deferred issue (number, title, reason, link to comment-trail). | Operator-readable record; complete audit. |
| Stage 13 chore PR body | Compact summary: `Deferred items: <list with #N links>` OR `Deferred items: none (clean close)`. | Release-corpus-integrated; visible at PR review. |

The two surfaces serve different consumers — the sub-task comment is the durable audit-trail; the chore PR body integrates the disposition into the release-corpus narrative.

## 4. Canonical comment template (pointer mechanism)

Per Stage 5 spec Finding 1, the pointer mechanism is **Comment trail** (rejected alternative: body field — see § 5 below for rationale). The 3-line template:

```
## Deferred from v<X.Y> at Stage 13 (date YYYY-MM-DD)
Reason: <one-line rationale>
Re-entry: Stage 2 Triage for v<X.Y+1> or later per ticket-information-architecture.md L232
```

**Multi-occurrence semantics:** An issue can be bundled → deferred → re-triaged → bundled-into-next-release → deferred-again over time. One comment is posted per defer event — the full deferral history accumulates as an append-only comment series.

**Date resolution:** the `YYYY-MM-DD` placeholder resolves at posting-time per `date -u +%Y-%m-%d` — runtime resolution, not commit-time. No `${AUDIT_DATE_UTC}` variable substitution needed.

**Quote-block discipline:** the template is plain markdown — `## Deferred from …` renders as an H2 in the comment thread, making the deferral visible in the GitHub issue's table-of-contents (timeline view).

## 5. Pointer mechanism rationale (B vs A)

AC2 (linked-to-originating-release) requires "Deferred items linked to originating release (via milestone or issue reference)". The milestone is REMOVED at deferral per the existing Stage 2 protocol, so the originating-release link must live in another surface. Two mechanisms exist:

| Mechanism | Locus | Multi-occurrence | Audit-trail semantics | Body-schema impact |
|---|---|---|---|---|
| **(A) Body field** — `previous-milestone: v<X.Y>` line | Issue body | Single-occurrence (overwrites on second deferral) OR requires new append-list section | Body update protocol is **in-place** — conflicts with append-only audit-trail discipline | NEW append-list section needed (no precedent in body update protocol) |
| **(B) Comment trail** (CHOSEN) | Issue comments | Multi-occurrence naturally (one comment per defer event) | Composes with [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) § Stage Reviews: "Comments are append-only and never edited after posting — they form an immutable audit trail" | None |

**Why (B) Comment trail:**
- **Multi-occurrence native** — handles the bundled → deferred → re-bundled → re-deferred pattern without body-schema additions.
- **Composes with audit-trail discipline** — inherits the immutable-comment convention rather than requiring new body-update protocol.
- **Preserves single-canonical-source** — `status: deferred` label IS the body-level current-state signal; the comment trail is for history. No body-schema contention per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md).

**Reversibility tier:** `MODERATE · confidence HIGH`. Once N deferrals land with the comment-trail convention, switching to body-field would require migrating N comment-trails into N body sections. Convention bias once shipped.

## 6. Stage 2 re-entry (AC4)

AC4 (next-cycle-pickup) requires "Next release cycle picks up deferred items during Stage 2 (Triage) or Stage 3 (Bundle)". The existing Stage 2 defer protocol already covers this — per [`ticket-information-architecture.md` line 232](../specs/ticket-information-architecture.md):

> Re-triage required before re-bundling (returns to `status: proposed` for full re-evaluation, or `status: approved` if priority/scope unchanged).

This standard adds no new Stage 2 mechanics. Cite, don't duplicate. The hub's next-release planning sweep should include a step to enumerate `status: deferred` issues (`gh issue list --label "status: deferred"`) for re-triage consideration.

## 7. Consumer surfaces

| Consumer | Today | Mechanism |
|---|---|---|
| **`release/governance/release-process.md` Stage 13 §** (mirror-pair) | Capture surface — Stage 13 spoke invokes A2.1 → A2.3 procedure | Cross-reference to this standard from the release-process.md Stage 13 paragraph |
| **`pipeline/stage-13-close.md` Phase A2** | Procedure consumer — pipeline shard cross-references this standard for the enumerated procedure | Single-line cross-reference appended to Phase A2 bullet |
| **`automated-closeout.sh`** (sibling) | Closeout report consumer — reads via label-keyed query: `gh issue list --milestone X.Y --label "status: deferred"` | Forward-compatible composition — automated-closeout.sh reads the body-level signal (label), not the comment trail. Comment trail is for human-audit; label is for machine-query. |
| **`release-executor` Mode D / D-FormFactor (B)** | Inherits read pattern via script wrapping | Mode D wraps the script; deferred-item read flows through script → Mode D; no SKILL.md schema dependency |
| **Future next-release `release-planner` Mode A backlog scan** | MAY enumerate `status: deferred` issues as re-triage candidates for next release | Cross-reference from this standard's § 6 — no protocol change to release-planner |

## 8. Forward compatibility

| Compatibility concern | Resolution |
|---|---|
| Pre-cutover releases lack the enumerated A2 procedure | Stage 13 close runs the legacy one-bullet "confirm tracked" check; no backfill of comment-trails for pre-cutover deferrals (the Cowork Execution Runbook precedent stays as documented). |
| Future body-field surface (e.g., `previous-milestone:` line per § 5 alternative A) | Comment-trail history would coexist with body field — body would carry current-state, comments would carry history. Schema is additive at structural level. |
| `status: deferred` label color / description change | Schema-driven — depends on [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) line 36. If the taxonomy updates the label, this standard inherits without change. |
| Future Mode D refactor of the closeout script | The label-keyed query is the contract; the script's internals can refactor without affecting this standard. |
| Aggregation across mixed-cutover corpus | Consumers querying `status: deferred` need not distinguish pre/post cutover — the label is the same; the comment-trail presence varies per release boundary. |

## 9. Anti-Patterns

The following are **NOT** valid uses of this protocol:

- **Adding a new label for release-boundary deferrals.** The `status: deferred` label per [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) line 36 IS the canonical label. A parallel label (e.g., `status: deferred-from-release`) would duplicate state across two surfaces and violate [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md).
- **Closing a deferred issue at Stage 13.** Defer ≠ close. Closing would lose the issue from the re-triage candidate pool; the issue stays OPEN per [`ticket-information-architecture.md` line 232](../specs/ticket-information-architecture.md).
- **Conflating release-boundary defer with terminal-archive.** Terminal-archive was closed-as-NOT_PLANNED with milestone-as-evidence — a confirmed-obsolete disposition. Release-boundary defer is the opposite — the issue is not obsolete, just not shipped this release. Both patterns coexist; operator chooses based on issue state.
- **Editing the deferral comment after posting.** Per [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) § Stage Reviews: "Comments are append-only and never edited after posting". A correction warrants a follow-up comment, not an edit.
- **Skipping A2.2 step 2 (milestone removal).** Leaving the milestone assigned conflicts with the Stage 2 defer state-transition row at [`ticket-information-architecture.md` line 622](../specs/ticket-information-architecture.md) (Milestone removed). The closed milestone would carry an open `status: deferred` issue — a confusing mixed state for re-triage.
- **Posting the deferral comment via direct-to-main commit on a governance file.** The deferral comment lives on the GitHub issue, not in a governance file. The Stage 13 chore PR carries the disposition summary in the PR body per § 3 A2.3.

## 10. Cutover

**Applies to:** All releases entering Stage 13 going forward.

**Pre-cutover releases:** exempt. No backfill of historical deferrals as comment-trails; the Cowork Execution Runbook precedent stays as documented in its original release plan.

## 11. Failure modes

Per [`failure-mode-standard.md`](../../../core/specs/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **PROC** | Closing a deferred issue at Stage 13 instead of de-milestoning | When Stage 13 enumerates a bundled-but-not-closed issue, do NOT `gh issue close <N>` — defer ≠ close; closing loses the issue from the re-triage candidate pool | "Bundled-but-not-shipped looks like failure → close it to clean the milestone" rationalization — but the Stage 2 protocol explicitly leaves deferred issues OPEN | This standard § 3 A2.2 makes step 2 explicitly `--remove-milestone`, not close; cross-references [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) line 232 ("issue stays OPEN"); § 9 Anti-Patterns calls out the failure mode | Principal: enumerates → labels → de-milestones → posts comment trail; verifies issue still OPEN. Junior: closes the issue "to clean the milestone" → issue disappears from re-triage queue, gets re-created later as a duplicate, audit-trail fragmented across two issue numbers |
| FM2 | **OUT** | Adding a new `status: deferred-from-release` label instead of reusing `status: deferred` | When this protocol fires, do NOT create a parallel label — `status: deferred` per [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) line 36 IS the canonical label, regardless of whether the defer fires at Stage 2 or at Stage 13 release-boundary | "Stage 13 defer feels different from Stage 2 defer → it needs its own label" intuition — but the state is the same (deferred, awaiting re-triage); only the trigger differs | This standard § 2 cites the existing label verbatim; § 9 Anti-Patterns calls out the parallel-label trap; Stage 5 spec explicitly forbids new labels in the Phase A0 finding (ZERO new labels) | Principal: applies `status: deferred` regardless of defer trigger; reuses the closeout script's label-keyed query unchanged. Junior: creates `status: deferred-from-release` → splits the re-triage queue across two labels, closeout script misses half the deferred items, audit-trail bifurcated |
| FM3 | **HAND** | Editing the deferral comment after posting to "fix" the rationale | When the operator wants to correct or supplement a deferral rationale, do NOT edit the original comment — comments are append-only per [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) § Stage Reviews | "The original rationale was wrong / incomplete → fix it" convenience pressure — but the audit-trail composability of (B) Comment trail depends on append-only discipline | This standard § 4 establishes the template + § 5 cites the append-only discipline; § 9 Anti-Patterns calls out the edit-after-posting trap; correction warrants a follow-up comment ("Supersedes prior comment: <rationale>"), not an edit | Principal: posts a follow-up comment when correction is needed; preserves the original as the historical record. Junior: edits the original comment → audit-trail breaks (the edit is silent in the API; downstream consumers reading the comment series see the corrected version with no signal of revision) |
| FM4 | **TRIG** | Conflating release-boundary defer with terminal-archive pattern | When an issue is bundled-but-not-closed at Stage 13, do NOT default to NOT_PLANNED closure unless the issue is confirmed obsolete — defer (open + re-triage) is the default per the least-destructive-disposition discipline | "The issue didn't ship this release → it must not be needed → close it as NOT_PLANNED" rationalization, but the terminal-archive pattern is reserved for confirmed-obsolete items | This standard § 1 Scope distinguishes deferral from terminal-archive; § 2 cites terminal-archive as a distinct disposition pattern; § 9 Anti-Patterns calls out the conflation; the least-destructive-disposition discipline is the upstream behavioral rule | Principal: defaults to deferral (open + re-triage) unless operator explicitly confirms obsolescence + authorizes the terminal-archive pattern. Junior: closes as NOT_PLANNED "because it didn't ship" → loses the issue from re-triage queue, misclassifies a valid backlog item as obsolete |

## 12. Cross-references

| Surface | Reference | Role |
|---|---|---|
| `status: deferred` label definition | [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) line 36 | Canonical label — reused unchanged at release-boundary |
| Stage 2 defer state-transition | [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) line 232 | State-transition semantics; this standard composes at release-boundary |
| Stage 2 defer execution | [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) line 500 | Execution mechanics (label apply + milestone remove + leaves OPEN) |
| Stage 2 defer Automation-vs-Agent row | [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) line 622 | Field mutations (Status stays Proposed, Stage stays 2-Triage, label applied) |
| Stage 13 close procedure | [`release/governance/release-process.md`](../../governance/release-process.md) § Stage 13 § Deferred item disposition | Capture surface; Stage 13 spoke invokes this standard's procedure |
| Stage 13 pipeline shard | [`pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) § Phase A2 | Cross-reference to this standard for the enumerated procedure |
| Chore PR convention | [`release-process.md`](../../governance/release-process.md) Stage 13 § Chore PR convention | Disposition summary lands in the Stage 13 chore PR body, never direct-to-main |
| Single-source-of-truth discipline | [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) | Label IS the body-level current-state signal; no parallel label; no body field |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/specs/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` |
| Cross-issue (closeout) | `automated-closeout.sh` (sibling release) | Reads `status: deferred` label via `gh issue list --milestone X.Y --label "status: deferred"` |
| Cross-issue (terminal-archive precedent) | Terminal-archive precedent | Distinct disposition pattern (terminal-archive — confirmed-obsolete); this standard's deferral path is the park-in-container default |
| Originating precedent | Cowork Execution Runbook precedent | Cowork Execution Runbook update deferred post-merge — the post-merge defer precedent |
| Source Stage 5 spec | Stage 5 Solutioning canonical spec | Stage 5 Solutioning canonical spec (relayed from mis-routed sibling ticket) |

## Version History

| Version | Date | Change |
|---|---|---|
|  | 2026-05-23 | Initial authoring |
