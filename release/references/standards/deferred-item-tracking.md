---
title: Deferred Item Tracking
purpose: K1 codified-knowledge standard for the Stage 13 close-out disposition of issues bundled-but-not-closed at release close — comment-trail pointer mechanism + extension of Phase A2 from one-bullet to enumerated procedure; ALSO (§13) mid-pipeline cross-stage deferral-validity criteria, per-gate "Deferred Items" accounting, ownership-transfer protocol, and a staleness rule for items deferred between stages mid-release
type: standard
parallel_to: ticket-information-architecture.md (the Stage 2 defer protocol this composes with at the release-boundary), label-taxonomy.md (the `status: deferred` label this consumes — zero new labels), release-corpus-schema.md (the chore-PR carrier this writes the disposition summary into)
reversibility: CHEAP (forward-only protocol; pre-cutover releases exempt; comment-trail is append-only and would not require migration if a future release supplements with a body-field surface)
consumers: "release/governance/release-process.md Stage 13 § Deferred item disposition (capture surface); pipeline/stage-13-close.md Phase A2 (procedure consumer); automated-closeout.sh (label-keyed query read-surface — `gh issue list --milestone X.Y --label \"status: deferred\"`); release-executor Mode D / D-FormFactor (B) (inherits the read pattern via script wrapping); pipeline/stage-05..12 §7 Stage-Transition Gate (the per-gate 'incoming deferred items accounted' clause per §13.8 — gated shards stage-05/06/07/08/09/12 carry it on the §7 Metrics line, PLATFORM-SATISFIED shards stage-10/11 carry the pass-through note); core/schemas/gate-evaluation-spec.md Assessment Output Template (cited render surface for the §13.8 evidence row, not edited)"
version: v12.12
---

<!-- reference-durability: allow-link -->

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

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥ 3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

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
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` |
| Cross-issue (closeout) | `automated-closeout.sh` (sibling release) | Reads `status: deferred` label via `gh issue list --milestone X.Y --label "status: deferred"` |
| Cross-issue (terminal-archive precedent) | Terminal-archive precedent | Distinct disposition pattern (terminal-archive — confirmed-obsolete); this standard's deferral path is the park-in-container default |
| Originating precedent | Cowork Execution Runbook precedent | Cowork Execution Runbook update deferred post-merge — the post-merge defer precedent |
| Source Stage 5 spec | Stage 5 Solutioning canonical spec | Stage 5 Solutioning canonical spec (relayed from mis-routed sibling ticket) |

## 13. Cross-stage deferral validity (mid-pipeline)

### 13.1 Scope + relationship to the release-boundary case (§1–§12) and Tier-0..3

§1–§12 above govern the **release-boundary** deferral — an issue bundled into a release but not closed at Stage 13. This section governs the **mid-pipeline** case the release-boundary scope explicitly excludes (§1 Out of scope, "mid-pipeline (Stage 4/5/6/7) deferrals"): a unit of in-scope work that a stage consciously moves to a *later named stage* of the same in-flight release (e.g., a Stage 5 design defers a sub-concern to Stage 7 implementation).

This section **cites, does not restate**, two existing surfaces per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md):

- **The release-boundary procedure (§1–§12 of this file) is the Stage-13 instance** of deferral. A mid-pipeline deferred item that survives to release close stops being a §13 item and becomes a §1–§12 `status: deferred` release-boundary defer (the terminal handoff — §13.6). §13 does not re-specify the label, the comment-template, or the de-milestone steps; it points to §1–§12 for them.
- **The Tier-0..3 Inter-Stage Feedback Protocol** in [`release-process.md`](../../governance/release-process.md) § Inter-Stage Feedback Protocol is the **escalation channel**, not a deferral mechanism. A valid mid-pipeline deferral is *not* an escalation — it is in-scope work consciously sequenced later. §13 routes *into* Tier-0..3 only when a deferral fails the validity test (§13.3) or goes stale (§13.7); it does not define a new escalation ladder.

The two adjacent gate surfaces §13 must **not collide with**: the Stage-12→13 boundary "Deferred items list" ([`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) + `gate-criteria-spec.md` G-EX8) is *release-boundary* accounting at one boundary; §13.8's accounting is *per-gate incoming* accounting at every mid-pipeline boundary. Distinct scope, cross-referenced — not duplicated.

### 13.2 What a mid-pipeline deferral IS (and is not)

| | |
|---|---|
| **IS** | A unit of work inside an issue's accepted scope, consciously moved from the stage that surfaced it to a specific later stage of the **same in-flight release**, recorded at the deferring gate with a rationale, an owner stage, and a target stage. |
| **IS NOT** | (a) A **scope cut** — work silently dropped with no target stage ("we'll probably never need it"). That is a rationalized scope-gap → route to Tier-0..3, not a deferral. (b) An **escalation** — a premise problem or scope change pushed *upstream*. That is Tier-0..3. (c) A **release-boundary defer** — an issue bundled-but-not-closed at Stage 13. That is §1–§12. (d) A **Stage 2 pre-bundle defer** — `status: deferred` applied at Triage before bundling. That is [`ticket-information-architecture.md`](../specs/ticket-information-architecture.md) § Stage 2 Triage. |

### 13.3 Valid-vs-rationalized test

A mid-pipeline deferral is **VALID** only if **all four** gates hold. If **any** gate fails, the item is a **scope-gap rationalized away** and must instead route to the Tier-0..3 protocol — Tier 1 [ADJUST] if locally fixable within the deferring stage, Tier 2 [SCOPE CHANGE] if the issue set / scope must move (operator decision).

| # | Gate (must ALL hold for VALID) | Failure signal (→ rationalized scope-gap) |
|---|---|---|
| **V1** | **In-scope, consciously sequenced.** The deferred work is within the issue's accepted scope and is being moved to a *later named stage*, not dropped. | "We'll probably never need it" / no target stage named → the work is being silently **cut**, not deferred. |
| **V2** | **Named owner stage.** A specific downstream stage (or the next release's Stage 2) is identified as the pickup point. | "Someone later" / target = "TBD" → no owner = no accountability = a scope-gap. |
| **V3** | **Does not block a downstream AC.** No acceptance criterion of *this* release depends on the deferred work being done *before* the stage that owns that AC. | A downstream AC cannot be satisfied without the deferred work → deferral would ship an unverifiable AC. **Must escalate (Tier-0..3), not defer.** |
| **V4** | **Recorded with rationale at the deferring gate.** The deferral is written into the deferring stage's sub-task output with a one-line rationale + target stage, so the §13.8 accounting row can pick it up. | Undocumented → invisible to the next gate → silent backlog accumulation (the exact failure this section targets). |

This mirrors — by deliberate analogy, **cited not copied** — the release-boundary file's § 9 anti-pattern "defer ≠ close" and FM4 "defer ≠ terminal-archive": at the release boundary the question is *defer vs. close*; mid-pipeline the question is *valid-defer vs. rationalized-cut*. Same disposition-honesty principle, different temporal anchor.

### 13.4 Deferral record — owner + target stage + tracking locus

When a mid-pipeline deferral is **created**, the deferring stage writes it into **its own sub-task output comment**, as a one-row-per-item table under the canonical section frame:

```markdown
**Deferred (mid-pipeline) — from Stage <D>:**
| Item | Rationale (1 line) | Target stage | Owner (pickup stage) | Blocks downstream AC? | Recorded |
|---|---|---|---|---|---|
| <what is deferred> | <why now-is-not-the-time> | Stage <T> | Stage <T> spoke | NO (V3 verified) | <YYYY-MM-DD> |
```

`Blocks downstream AC?` MUST read `NO` for every row — a `YES` means V3 failed and the item was never a valid deferral (it should have escalated). The `Recorded` date resolves at posting time via `date -u +%Y-%m-%d` — the same runtime-resolution discipline § 4 already uses for the comment template (cited, not re-specified). The tracking locus is the append-only sub-task comment trail — **no new label, no body field, no new pipeline-event subtype** (the same single-canonical-source posture as § 5).

### 13.5 Not-blocking-downstream-AC rule

V3 is restated here as a standalone gate because it is the one validity criterion whose violation is *unrecoverable at the boundary*: a deferral that blocks a downstream AC, if allowed through, ships a release whose AC cannot be verified when its owning stage runs. The rule: **a unit of work may be deferred only if no acceptance criterion of the current release depends on that work being complete before the stage that owns the AC executes.** If the dependency exists, the item is not deferrable — it is either done now or the AC/scope is renegotiated through Tier 2 [SCOPE CHANGE]. The §13.8 accounting row's `Blocks downstream AC?` column is the per-gate enforcement surface for this rule.

### 13.6 Ownership-transfer protocol

When the pipeline reaches a stage that is the `Target stage` of an open mid-pipeline deferred item, that stage's spoke MUST, at gate entry, do **one** of:

- **(a) Pick it up** — execute the deferred work and mark the item *resolved* in its own sub-task output (note the originating deferral record).
- **(b) Re-defer** — only if V1–V4 still hold for a **new, later** target stage; record a fresh deferral record (§13.4) with the new target. A re-defer is itself subject to the staleness rule (§13.7).

The transfer is tracked **in the sub-task comment trail** — the same append-only audit-trail mechanism the release-boundary case uses (cited from § 5 / § 6, not re-specified); no new label or body field is introduced. A target stage that silently drops an incoming deferred item (neither picks up nor re-defers) is the AP3 anti-pattern (§13.10).

**Terminal handoff to the release-boundary case.** The terminal owner of any item that survives mid-pipeline to release close is **the next release's Stage 2 Triage**: at Stage 13 the item becomes a `status: deferred` release-boundary defer and the **release-boundary procedure (§1–§12) takes over** — enumerate → label → de-milestone → comment trail → Stage 2 re-entry (§ 6). This is the explicit seam from the mid-pipeline case (§13) to the shipped release-boundary case (§1–§12).

### 13.7 Staleness rule

A mid-pipeline deferred item is **STALE** when the pipeline has advanced to **within N=2 stages of its target stage** and the item is still unresolved (example: target = Stage 9; pipeline now at Stage 7 → 2 stages out → flag). On stale-flag, the holding gate routes the item into the **existing Tier-0..3 protocol** (it does **not** invent a new ladder):

- **Tier 1 [ADJUST]** — if the item can still be absorbed by its target stage with a plan-note.
- **Tier 2 [SCOPE CHANGE]** — if staleness means the item now needs operator re-scoping (absorb / defer-to-next-release / drop).

The threshold is authored as **`N=2 [CALIBRATE-AFTER-3]`**. **N=2 is grounded in the platform's established "downstream tolerance before forcing an escalation" convention** — the default iteration cap of 2 in [`handoff-coordinator-spec.md`](../../../core/schemas/handoff-coordinator-spec.md) § Boundary-Specific Iteration Caps ("Two re-entries signal a systemic upstream issue; escalating forces a plan revisit"). The staleness decision is the same shape — *how much slack before forcing the item into the operator-visible escalation channel* — so it inherits the same N=2 default rather than inventing a number. (N=1 gives no runway to absorb or re-scope before the target gate; N=3 is the DT↔Engineering boundary-specific exception, not the general default, and would over-fire on routine forward-sequenced deferrals.) The `[CALIBRATE-AFTER-3]` marker — matching the existing calibration-marker discipline in `release-process.md` — lets the threshold tune against observed mid-pipeline-deferral data without a re-design.

### 13.8 Stage-transition-gate "Deferred Items" accounting row

Each mid-pipeline stage gate, at entry, **accounts for items deferred *into* it** (whose `Target stage` = this stage). The accounting **requirement** is expressed as a one-clause extension to the existing `## 7. Stage-Transition Gate` `Metrics:` line of each mid-pipeline shard — the canonical Gates-4+ criteria surface (Path B per [`gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) § Boundary Source Mapping, where each `pipeline/stage-NN-*.md` §7 Metrics line is parsed as the gate's pass conditions). The canonical clause, identical across shards:

```
... ; incoming deferred items accounted (every item whose Target stage = this stage,
per deferred-item-tracking.md §13, is picked up or re-deferred with rationale —
zero unaccounted incoming deferrals).
```

The runtime **evidence row** the spoke fills reuses the existing `gate-evaluation-spec.md` Assessment Output Template Metrics table (`| Metric | Threshold | Actual | Result |`) — **this section cites that template as the render surface and does not edit it** (single-source: the template owns the row format; §13.8 owns the metric definition):

```markdown
| Incoming deferred items accounted | =100% | <picked-up-or-re-deferred>/<incoming> | PASS/FAIL |
```

**PLATFORM-SATISFIED stages (10 Dry Run, 11 Snapshot)** have no `## 7. Stage-Transition Gate` and therefore no per-gate accounting to perform: incoming mid-pipeline deferrals pass *through* the compressed Stage 9→12 path to the **next real gate (Stage 12 Execute)**, which carries the accounting clause. Those two shards record this pass-through explicitly (a one-line note at the stage body) rather than a fabricated gate.

This accounting is distinct from the Stage-12→13 release-boundary "Deferred items list" (G-EX8): G-EX8 accounts for release-boundary defers at the *Execute→Close* boundary; §13.8 accounts for mid-pipeline defers arriving at *every* mid-pipeline gate. Cross-referenced, not duplicated (§13.1).

### 13.9 Composition + forward-compat (the deferred-re-evaluation-cadence seam)

This section is the **definition + per-gate-accounting + staleness** half of the cross-stage deferral surface. The **recurring re-evaluation cadence** half — a scheduled sweep that periodically resurfaces open deferred items for re-evaluation — is a separate, sequenced work item that **composes** with this one as follows:

- **§13 owns:** the *definition* of a cross-stage deferred item (§13.3 validity test), its *record format* (§13.4), the *per-gate accounting* (§13.8), the *ownership-transfer* (§13.6), and the *staleness flag + threshold* (§13.7).
- **The cadence work owns:** the *recurring trigger* that periodically re-surfaces open deferred items. That cadence **consumes** §13.7's staleness signal — §13.7 *produces* the flag; the cadence is the scheduled process that *reads* it and schedules re-evaluation. The cadence cites §13 for "what a deferred item is" rather than redefining it.

Forward-compat: §13 adds no schema field, no label, and no pipeline-event subtype, so a future cadence surface composes additively. If a future release introduces a body-field surface for deferral state (the § 5 alternative A), §13's comment-trail records coexist with it exactly as § 8 describes for the release-boundary case (body carries current-state, comments carry history).

### 13.10 Anti-Patterns

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), the following are **NOT** valid uses of the mid-pipeline deferral protocol. Each uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior) and a category tag (TRIG / INPUT / PROC / OUT / HAND). These are distinct from the § 11 release-boundary failure modes (which govern the Stage-13 §1–§12 case).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| **AP1** | **PROC** | Deferring work that blocks a downstream AC (V3 violation) | When a stage wants to move work to a later stage, do NOT defer it if any current-release AC depends on that work completing before the stage that owns the AC — that ships an unverifiable AC | "It's almost done, the later stage can finish it" optimism that ignores the AC→stage dependency; the gap only surfaces when the owning stage cannot verify its AC | §13.3 V3 + §13.5 make not-blocking-AC a hard validity gate; §13.8's `Blocks downstream AC?` column forces a `NO`; a `YES` routes to Tier 2 [SCOPE CHANGE] instead | Principal: checks V3 against the release's AC set, escalates via Tier 2 when a dependency exists. Junior: defers anyway → the target stage's gate fails AC verification, the release stalls mid-pipeline, the "deferral" is unwound under time pressure |
| **AP2** | **OUT** | Recording a deferral with target = "TBD" / "later" / no named owner stage (V2 violation) | When writing the §13.4 deferral record, do NOT leave the Target/Owner stage unnamed — an unnamed target is a silent scope-cut wearing a deferral's label | "I'll figure out where it lands later" — but no named pickup point means no gate ever accounts for it (§13.8 keys on `Target stage`), so it evaporates | §13.3 V2 requires a named owner stage; §13.4's table has no nullable Target/Owner column; §13.8 accounting cannot pick up an item with no target | Principal: names the specific target stage (or "next release Stage 2") before recording; if none can be named, treats it as a cut and routes to Tier-0..3. Junior: records "Target: TBD" → no gate claims it → the item silently disappears from the pipeline, re-surfaces later as a "new" gap |
| **AP3** | **HAND** | A target stage silently dropping an incoming deferred item (no §13.6 pickup or re-defer) | When the pipeline reaches a stage that is an open item's `Target stage`, that stage's spoke must NOT proceed without either picking the item up or re-deferring it with a fresh record | "It wasn't in my sub-task instructions, so it's not my job" — the handoff is invisible unless the receiving gate actively reads incoming deferrals (§13.8) | §13.6 makes pickup-or-re-defer mandatory at the target gate; §13.8's accounting clause makes "zero unaccounted incoming deferrals" a gate pass condition, so a silent drop fails the gate | Principal: at gate entry, enumerates items whose Target = this stage and dispositions each (pick up / re-defer). Junior: ignores the incoming deferral because it is not in the immediate task list → the item is lost at the handoff, the §13.8 accounting row reads FAIL or is never filled |
| **AP4** | **TRIG** | Routing a valid deferral through Tier 2 [SCOPE CHANGE] as if it were an escalation (over-escalation) | When all of V1–V4 hold, do NOT push the item upstream through the Tier-0..3 escalation channel — a valid deferral is in-scope sequencing, not a scope change | "Anything that changes when work happens is a scope decision the operator must make" conflation of *sequencing* with *scope* — but valid deferral is a stage-local Tier-1-or-below act | §13.1 + §13.2 separate deferral (in-scope sequencing) from escalation (Tier-0..3); §13.3 routes to Tier-0..3 only on a *failed* validity gate or §13.7 staleness, not on a valid defer | Principal: records a valid deferral inline (§13.4) and proceeds; escalates only on a failed gate or staleness. Junior: escalates every deferral to the operator as a scope change → escalation-channel noise, operator decision-fatigue, the in-scope sequencing the pipeline is designed to handle autonomously gets bottlenecked on human gates |

## Version History

| Version | Date | Change |
|---|---|---|
|  | 2026-05-23 | Initial authoring |
| v2.13 | 2026-06-20 | Add § 13 Cross-stage deferral validity (mid-pipeline) — valid-vs-rationalized test, deferral record, not-blocking-AC rule, ownership-transfer, staleness rule (N=2 [CALIBRATE-AFTER-3]), per-gate "Deferred Items" accounting clause across the mid-pipeline shard gates; cites §1–§12 as the Stage-13 instance + Tier-0..3 as the escalation channel |
