---
title: ADR-171 — The frontmatter is the status value; Stage 13 owns the flip
status: Proposed — flips to Accepted when the operator ratifies it at this release's Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-09-01
release: adr-corpus-status-integrity
deciders: "Workspace owner (ratified at the operator gate); determination rendered at the Stage 5 D-gate, implemented at Stage 6 Engineering"
supersedes: none
tags: [architecture, governance, adr-corpus, status, lifecycle, ratification, schema, durability-lint, immutability, pipeline-gates]
source_observations:
  - "Corpus measurement at authoring (2026-09-01, release branch): 170 ADR records across core/ADRs/ and release/ADRs/. Frontmatter `status:` parsed 170 of 170 and the `## Status` body section parsed 170 of 170 — non-empty extraction asserted on both surfaces over the whole denominator, so a zero from either is a real absence rather than a failed read."
  - "Before the reconciliation this record accompanies, the two surfaces disagreed on 30 records: frontmatter leading token `Accepted` while the body restated `Proposed`. The disagreement set was single-shaped — no other combination occurred. An independent arithmetic cross-check agreed: body-`Proposed` 67 minus frontmatter-`Proposed` 37 equals exactly that 30."
  - "The predicate's control arms both fired at authoring: five sensitivity arms covering every body token shape the corpus writes (`**Proposed.**`, unbolded `Proposed.`, unbolded `Proposed — …`, `**Proposed — supersedes …**` with prose inside the bold, and a long-form frontmatter ratification tail), and specificity arms that stayed silent on agreeing records with extraction asserted non-empty on each."
  - "Stage 9 was falsified as the flip owner by its own record: at authoring, 16 records still reading frontmatter `Proposed` carried a promise naming a Stage-9 flip, and none of them had received one. A seventeenth named Stage 5. The shipped-release cross-check resolved a known-shipped release as SHIPPED and a fabricated one as no-evidence, so the test discriminates."
  - "`check-adr-durability.py` scopes its status rule to the frontmatter value explicitly — its R1 docstring names 'the `status:` frontmatter value's LEADING token', and its scan loop stops at the first match with the comment that frontmatter `status:` is the first one while body restatements are prose. The enforcing tool already drew the line this record ratifies."
  - "The edit had corpus precedent before this release: a prior release's commit rewrote one record's body `## Status` from a Proposed forward-promise to an Accepted statement while its frontmatter already read `Accepted`, and edited that frontmatter line's prose tail while preserving its leading token. That commit also added a provenance annotation which the authoring guide's later 'Reconcile; do not annotate' clause now forbids — it is precedent for the DIRECTION, and a counter-precedent for the SHAPE."
  - "`G-CL9` has asserted the landed flip at Gate 13 since well before the originating card was filed. The card's reproduction was scoped to Gate 9 and did not reach it, which is why the card records that no criterion asserts the transition."
---
<!-- reference-durability: allow-link -->

# ADR-171 — The frontmatter is the status value; Stage 13 owns the flip

## Status

**Proposed.** Ratification flips this field at this release's Stage 9 Plan Review gate.

**Why this record does not ratify at the gate it establishes.** The decision below moves the `Proposed → Accepted` performing beat to Stage 13 Close, and that beat carries the standard cutover discipline: it applies to releases entering Stage 13 strictly after its introducing release merges, and the introducing release is exempt because it cannot fire its own new gate. This release is that introducing release, so its own operator gate is the one it ran under. Stating this is cheaper than leaving a reader to wonder why the record establishing a Stage-13 owner names a Stage-9 gate for itself.

**Numbering provenance.** The number was READ from the allocation oracle at authoring, never reserved: the numbering integrity check reported a contiguous sequence with no duplicates and no gaps over the union of both ADR homes, and the next free slot above this branch's own prior claim is the one taken here. The claim binds at merge per ADR-115; if a sibling branch claims the same slot first, the merge-time renumber moves this record and writes its own provenance note.

## Context

An ADR states its status twice. The frontmatter carries a `status:` field constrained to the four Nygard tokens, and the body carries a `## Status` section. `adr-schema.md` §3 gives that section exactly one contract — it *restates* `status:`. Nothing in the schema grants the body an independent allowed-values rule.

Two defects followed from leaving that relationship implicit, and both were visible on the mainline.

**The two surfaces drifted apart.** Records accumulated in which the frontmatter read `Accepted` while the body still opened `Proposed` — two authoritative-looking statements of one field, disagreeing inside one file. Because the corpus is immutable by default and the authoring guide's forbidden list closes over "the status value", it was genuinely unclear whether repairing the body was permitted hygiene or a forbidden status edit. That ambiguity is why the drift persisted rather than being swept: an editor who could not tell which reading governed correctly declined to act.

**The transition had a verifier and no performer.** Scaffolded records promised their own ratification at a named review — most often "flips to Accepted at this release's Stage-9 plan-review gate". No pipeline phase was bound to perform that flip. A prior card closed this gap with a *detective* remedy, and the gap recurred, because a verification step downstream of an unowned action does not give the action an owner. `G-CL9` is that detective remedy and it works as specified; what was missing sat upstream of it.

The two questions are one contract over one field — which surface carries the value, and who moves it — so they are recorded together rather than split.

## Decision

**D1 — The frontmatter `status:` field is the value-bearing surface. The `## Status` body is a projection of it.**

Reconciliation therefore runs **body → frontmatter, and never the inverse**. Repairing a body restatement that no longer matches its source is **permitted durability hygiene**: the record's status is the same before the edit and after it, so nothing about what was decided moves, which is the record-vs-revise invariant's own definition of hygiene. Editing the frontmatter `status:` *value* remains on the closed forbidden list, and editing it toward `Proposed` would silently de-ratify a decision the operator already ratified — the inverse edit is not merely disallowed, it is destructive.

A now-false forward-looking clause in the body ("flips to Accepted at …") is removed as a **rotted anchor** under the permitted list's existing first entry. Where a record already states its ratification in landed form, that text is preserved verbatim and only the leading token changes. **No ratification date, authority, or gate absent from the record is ever introduced** — a reconciliation that invents an anchor is fabrication wearing hygiene's clothes.

**D2 — Stage 13 Close owns the `Proposed → Accepted` transition, as a Tier-0 operator-authorization beat.**

Stage 13 gains the *performing* phase; `G-CL9` remains the *verifying* criterion at the same gate. Co-locating them is the point of the decision. The beat prepares the record set, blocks on operator authorization rendered **enumerated per record**, and then writes the frontmatter field and its body restatement **in the same commit** — because under D1 a flip that lands on one surface only re-creates the first defect while purporting to fix the second.

The transition is a ratification an agent may not render unilaterally. An agent may prepare and present the edit set; it may not apply one absent this gate. **A flip applied without it is a governance defect regardless of whether the resulting status is correct.**

## Alternatives Considered

**Stage 9 Plan Review owns the flip — rejected on evidence, twice over.** It is the stage the scaffolded promises already named, so adopting it would have required no record edits at all. It fails on two independent grounds. Empirically, every record that named it was still waiting: the promise had been made repeatedly and honored never, which is as direct a falsification as this corpus can produce. Structurally, Stage 9 is *pre-merge* — a record flipped there reads `Accepted` on a branch that can still be abandoned or rolled back, so the gate would mint ratifications for decisions that never ship. That second objection is the decisive one, because it would still hold even if the historical record were clean.

**Remove the promise entirely and let each record be ratified ad hoc — rejected.** This was tempting because it deletes the failing mechanism rather than repairing it. But the corpus is overwhelmingly promise-carrying, and stripping the promise would leave every `Proposed` record with no named owner at all. It converts a stuck-flip defect, which is at least visible in the record, into a silent one. Trading a loud failure for a quiet one is not a fix.

**Treat the body as independently authoritative and reconcile frontmatter → body — rejected as both wrong and dangerous.** No surface in the corpus grants the body status authority: the schema calls it a restatement, the authoring guide's editability table keys on the YAML field, and the shipped lint classifies body restatements as prose in as many words. Beyond being unsupported, this direction would have rewritten ratified decisions back to `Proposed` — a silent mass de-ratification. Direction is not a stylistic choice here; it is the whole safety property.

**Mint a new standalone conformance check for status agreement — rejected in favour of extending the existing lint.** The durability lint already owns ADR field-level conformance, already walks the whole corpus, and already carries the frozen-record exemption plumbing the new rule needs. A second surface would have forked the status-token grammar, which is precisely the divergence class this record exists to close.

## Consequences

**The permitted list grows by one entry, and stays open.** Body-to-frontmatter reconciliation joins it as an instance of the invariant rather than a special case. The forbidden list is untouched and stays closed.

**A standing detector now exists.** `R7 STATUS-AGREEMENT` reports any record whose two surfaces disagree. It is deliberately not delta-scoped — its population was reconciled to zero when it shipped, so it can be a standing invariant over whatever the caller scanned, delta-scoped at the CI surface and whole-corpus at release verification. Frozen records are exempt on the established ground that they can never be edited to conform.

**Ratifying a record narrows its own future editability, and the tooling cannot see that.** Under the authoring guide's editability table a `Proposed` record is freely editable while an `Accepted` one is hygiene-only. The flip therefore moves a record between those regimes. The lint does not implement that edge — it scans both statuses identically — so the narrowing is governance-visible and tooling-invisible. This is stated here so a later editor meets it as a documented consequence rather than discovering it by being refused.

**The exemption population is unchanged by D1.** The lint's whole-file exemption keys on the frontmatter status *leading token*. D1 changes no leading token in frontmatter, so the set of records the lint polices is identical before and after. D2 does change leading tokens when a flip lands, and a record moving to a frozen token would leave the policed population — which is why the frozen exemption is stated as a deliberate, reasoned boundary rather than an incidental one.

## Reversibility

**CHEAP · Confidence HIGH** for D1. The reconciliation is in-place prose repair plus one lint rule; reverting is a single revert on the release merge, and no decision content is at stake because no record's status value moved.

**MODERATE · Confidence HIGH** for D2. Reverting the ownership move is a spec edit, so the mechanical cost is low — but any ratification already rendered under the beat is an operator decision that a revert does not and should not undo. The reversal restores the previous state of *having no owner*, which is the defect; so the realistic path away from this decision is a successor ADR naming a different owner, not a rollback.

## Related ADRs

- **ADR-115** — an ADR number is allocated at authorship and bound at merge. This record follows that discipline for its own number.
- **ADR-170** — partial supersession is a reciprocal frontmatter edge, not a status value. Its companion in the same release, and the same underlying principle read on a different field: the frontmatter carries the machine-readable fact, and the body restates rather than competes.
- **ADR-029** — frozen and unedited by this decision. Its two status surfaces already agree, so it never entered the reconciliation set on its own merits, independent of its frozen posture.
