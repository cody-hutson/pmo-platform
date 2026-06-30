---
title: Reconcile-Don't-Annotate Discipline
purpose: The default discipline for an agent touching an artifact that carries stale or
  contradictory state — reconcile it to current state, do not post a correction comment /
  [VERIFY] flag / banner and defer. Governs the reconcile-vs-annotate decision ON AN EDIT
  (the edit-time twin of verify-before-recommend's recommendation-time discipline).
type: discipline
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
applies_to: any agent editing an artifact (issue body, tracker, governance/corpus file,
  release plan); Stage 5/6 spokes; intake-desk; delivery-engine
parallel_to:
  - decision-discipline.md            # §2.1.1 verify-before-recommend sibling (stale-input recommendations)
  - review-discipline-principles.md   # no-status-theater sibling (documentation-without-resolution)
source: codification of an operator-confirmed discipline (origin issue in the References block;
  previously held as operator memory feedback_reconcile_dont_annotate); P2 / Reversibility MODERATE
  / Confidence HIGH
---

<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- This doc is the corpus home that the operator memory feedback_reconcile_dont_annotate self-demotes INTO; naming that memory (and the write-into-referenced-file memory) as provenance / a composes-with sibling is the deliberately-documented exception the allow-memory-ref marker covers. -->

# Reconcile-Don't-Annotate Discipline

When an agent touches an artifact that carries stale or contradictory state, the **default is to reconcile it to current state** — not to post a correction comment, a `[VERIFY]` flag, or a banner and defer. This is a *default posture* an agent adopts whenever it edits an artifact, not an invokable procedure a stage hands off to.

This discipline closes a specific gap. Three adjacent disciplines each govern a neighbouring surface but none governs the edit itself: `verify-before-recommend` (`decision-discipline.md` §2.1.1) governs recommendations derived from a stale input; `no-status-theater` governs status outputs that recap without resolving; `surgical-edits` governs minimal-change scoping. The reconcile-vs-annotate decision **on an edit** — when you are already touching the artifact — had no standing rule, so the habit of annotating-and-deferring reproduced because the local incentive (defer = safe-now) was unopposed.

---

## Section 1 — Default: reconcile to current state

When an agent touches an artifact carrying stale or contradictory state, the default is to **reconcile it to current state** — not to post a correction comment, a `[VERIFY]` flag, or a banner and defer. The reconcile-vs-annotate choice on an edit defaults to *reconcile*; annotation-and-deferral is the exception that must justify itself against the decision tree in Section 2, not the safe fallback.

---

## Section 2 — The 4-way decision tree

The default (reconcile to current state) resolves through four branches. The first three classify the edit; the fourth is the tie-break test that decides any ambiguous case.

- **Mechanical / unambiguous** (token swap, renumber, retitle) → **always fix, never defer.** "Richness" is not an excuse for a safe swap — a mechanical correction is always in scope for the agent already editing the file.
- **Needs design re-derivation you're not positioned to do** → write an **in-body authoritative reconciliation block** (read-first, in the body where a body-only reader lands), never a timeline comment, and **never leave a contradiction** (title says X, body says Y). The in-body block reconciles what it can and states what is open; it does not push the contradiction onto a future reader.
- **Genuinely out of scope** → **fix what you can + file a follow-up ticket.** A bare correction comment with no fix and no follow-up ticket is the anti-pattern (Section 4) — out-of-scope is a reason to ticket the remainder, not a reason to skip the fixable part.
- **Tie-break test:** *"Would a future agent reading only the body (not the timeline) be misled?"* If yes → **reconcile.** Weight deferred / diffuse harm **equally** to immediate edit risk — the cost of a future agent acting on a stale body is real, just deferred and diffuse, and loss-aversion must not be allowed to discount it relative to the immediate, attributable cost of an edit.

---

## Section 3 — Root cause (four reinforcing drivers)

The annotate-and-defer habit reproduces because four drivers, each locally rational, are collectively corrosive:

1. **Verification-cost avoidance.** Reconciling requires verifying that the target resolves to current state; a comment skips that verification. The comment is cheaper *now*, so it wins the local cost comparison.
2. **Fractal-rot / scope anxiety.** Pulling the thread reveals a rotted parent. A comment draws a stop-boundary that looks principled ("flagged for follow-up") without confronting the depth the reconciliation would expose.
3. **Externalized, time-deferred harm.** A bad edit's cost is immediate and attributable to the agent that made it; a deferral's cost is diffuse and lands on a *future* agent. Loss-aversion favours the deferral — the agent avoids the visible, owned risk and externalizes the invisible one.
4. **Annotation-as-theater.** A comment pattern-matches to "acted." Posting a note *feels* like progress and reads, in a timeline, like diligence — even when the body still contradicts it.

---

## Section 4 — Anti-pattern signature

**Correction-comment-as-diligence-theater.** A timeline comment ("stale — see canonical #N") posted *instead of* the body fix, on an artifact already being edited, where the fix was mechanical or in-scope. The tell: **the body still contradicts the comment after the agent moves on** — a future reader who reads only the body (not the timeline) is misled exactly as the tie-break test warns, and the comment served as theater rather than resolution.

This is the edit-surface instance of `no-status-theater`: a comment that documents a problem without resolving it, posted in place of the in-scope fix.

---

## Section 5 — Composition with sibling disciplines

This discipline composes with — does not duplicate — the disciplines that govern the neighbouring surfaces. Each direction is named.

- **`verify-before-recommend`** (`decision-discipline.md` §2.1.1 Audit-Snapshot Reconciliation) — **SIBLING.** Same stale-artifact family, opposite action surface. §2.1.1 governs stale-*input* recommendations (verify before you recommend from an aging artifact); this discipline governs the stale-artifact *edit* (when you are already touching the artifact, reconcile it rather than annotating-and-deferring). Recommendation-time vs edit-time twins; cross-referenced, not merged.
- **`no-status-theater`** (CLAUDE.md guardrail; `core/standards/principal-standard-checklist.md`) — **SIBLING.** A correction comment posted instead of the in-scope body fix is a status-theater instance at the edit surface (Section 4).
- **`surgical-edits`** (CLAUDE.md preference; `build-philosophy.md` Simplicity row) — **SHARPENS.** Minimal-change ≠ avoid-the-change. The smallest edit that achieves the goal still includes reconciling the contradiction you are touching; surgical scoping bounds *how much* you change, not *whether* you reconcile.
- **`write-into-referenced-file`** (CLAUDE.md "Surgical edits" family; operator memory) — **ALIGNED.** Develop the correction *into* the artifact, not onto a parallel surface (a timeline comment) — the same "edit the named file, not a sibling" posture, applied to the reconcile-vs-annotate choice.

---

## See also

- [`decision-discipline.md`](decision-discipline.md) — §2.1.1 Audit-Snapshot Reconciliation, the verify-before-recommend sibling (recommendation-time twin of this edit-time discipline); carries the inbound cross-reference.
- [`review-discipline-principles.md`](review-discipline-principles.md) — the no-status-theater sibling (documentation-without-resolution); a correction comment without a fix is its edit-surface instance.
- [`build-philosophy.md`](build-philosophy.md) — the Simplicity row (surgical-edits); minimal-change sharpens, it does not excuse, the reconciliation.

## References

- #413 — origin issue: *Adopt "reconcile-don't-annotate" discipline for stale/contradictory artifact state* (the operator-confirmed discipline body codified above).
