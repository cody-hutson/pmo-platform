<!-- reference-durability: allow-link -->
---
title: ADR-133 — The material-edit test names an effect, not a field
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-15
release: skill-suite-conformance
deciders: "Workspace owner (D-1 rendered at the Stage-5 design gate, Option C elected); designed at Stage 5 Solutioning, authored at Stage 13 after the gap was surfaced at the close gate"
tags: [governance, skill-versioning, frontmatter, material-edit, version-field-semantics, skill-editor, reversibility-moderate]
source_observations:
  - "The originating card frames the two branches as mutually exclusive — 'One of the two is true.' They are not. They concern two different bullets, and the evidence establishes both are true simultaneously."
  - "The twelve skills were genuinely stale, but under the Behavior bullet rather than the Frontmatter bullet the card put in question. The v4.10 rewrite landed in one commit whose own message records a measured routing change — maximum Jaccard falling 0.733 to 0.188 across 1485 pairs — which falsifies the card's assumption that the no-bump was a deliberate cosmetic classification."
  - "The standard is independently defective in its frontmatter bullet. A v3.69 commit trimming two descriptions to fit a 1024-character bound changed no routing and was correctly not bumped; under the bullet as written, that correct call reads as a violation."
  - "The asymmetry is the whole defect: one bullet names a field, the adjacent bullet names an effect. Naming the field makes a length trim material."
  - "There is no exception to write. Nothing distinguishes a trigger rewrite from the Behavior bullet, because a trigger rewrite is that bullet. The repair is to stop the Frontmatter bullet double-counting the field that carries triggers."
  - "The correction set under a consistent reading is 17, not 12. Five further skills are live-stale on the identical mechanism and were never triaged by any card in the milestone, so the shipped fix is a point fix on a recurring class of 10 distinct events between 2026-06-06 and 2026-08-04."
  - "The recurring class has no forcing function. Nothing prevents the next description rewrite from repeating it; the automated-gate option that would was deferred on sequencing grounds, so the residual is real and named rather than closed."
---

# ADR-133 — The material-edit test names an effect, not a field

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is the mainline anchor plus one, derived at authoring time through the sanctioned allocator across **both** record directories rather than pre-allocated. Stage 5 explicitly declined to reserve a number, on the grounds that a reservation above a sibling's unmerged claim blocks the repository while a duplicate is merely tooled. Three concurrent pipelines were live at design time.

**This record was authored at Stage 13, not Stage 6, and that is a defect in its own right.** The plan declared it at line 214 and the verification row expected it present. It did not ship with the release it belongs to. The gap was caught at the close gate, after the release had already merged and tagged — which means the record's own release binds it correctly but its authoring lagged the code by one stage. Recorded here rather than smoothed over, because the mechanism that let it through is the subject of the consequences section below.

## Context

`core/standards/version-field-semantics.md` § Bump Rules lists the edits that oblige a skill's `version:` field to move. Two adjacent bullets in that list are in tension, and the tension is one-directional and load-bearing.

The first names a **field**: *frontmatter changes (description, name, other metadata fields)*. The second names an **effect**: *behavior changes (trigger phrases, mode definitions, …)*.

A skill's `description:` is the field that carries its trigger phrases. So a `description:` edit is caught by both bullets — once for touching the field, once for changing routing. When the two agree, nothing is visible. When they disagree, the field-naming bullet wins by construction, and it is wrong.

**Both halves of the originating question turned out to be true, which the card's framing excluded.** The card asserted that the affected skills were either genuinely stale or correctly unbumped, one of the two. The commit record establishes both propositions about different bullets:

- The twelve **were** stale — but under the Behavior bullet. The v4.10 rewrite landed as a single commit that removed and added trigger phrases and rewrote `Modes:` lists, and whose own message records the routing measurement: maximum Jaccard across 1485 pairs falling from 0.733 to 0.188. That is a deliberate, measured change to which requests reach which skill. It is not cosmetic, and the no-bump was not a considered cosmetic call.
- The standard **is** independently defective — in the frontmatter bullet. A v3.69 commit trimmed two descriptions to fit a 1024-character bound. It changed no routing and was correctly not bumped. Under the bullet as written, that correct call is a violation.

So the natural repair — write an exception distinguishing a trigger rewrite from the Behavior bullet — has nothing to distinguish. **A trigger rewrite *is* the Behavior bullet.** The defect is that the adjacent bullet double-counts the field that carries triggers.

## Decision

**(1) The material-edit test names an effect, never a field.** A frontmatter edit is material when it changes what the skill does or when it routes — that is, when it changes which requests reach this skill, or which skill a request reaches. It is not material merely because it touched a named field.

**(2) The two bullets are one test applied to one field, not two independent triggers.** A `description:` rewrite is material *via* the behavior bullet whenever it alters trigger phrases or mode definitions. Both can fire on the same edit; neither fires on the field alone.

**(3) The does-not-bump list gains the cosmetic case explicitly** — a frontmatter edit that changes neither behavior nor routing: a length trim to fit a character bound, a reflow, a typo.

**(4) The value written is the release at which the material edit occurred, not the release doing the correcting.** The field's definition is *the platform release tag at which this skill was last materially edited*. Stamping the in-flight release would assert a validation that never happened. The twelve therefore take `v4.10` — the release of the trigger rewrite — not the release that repaired the field.

Each rule carries a worked instance in the standard: the v4.10 trigger rewrite for the material case, the v3.69 length trim for the cosmetic one.

## Alternatives Considered

Six options were generated at Stage 5 and four scored.

**A — correct the twelve files only.** Rejected. It asserts the edits were material while leaving the over-broad frontmatter bullet standing, so the length-trim class stays mis-classified and the next correct no-bump still reads as a violation.

**B — amend the standard only.** Rejected. It asserts the edits were non-material, which the commit record directly contradicts: the v4.10 commit documents a measured routing change. The option is refuted by evidence, not merely disfavoured.

**C — split the bullet: correct the twelve under the Behavior bullet AND repair the over-broad Frontmatter bullet. CHOSEN.** The only survivor both branches' evidence supports simultaneously, at a cost of exactly one file more than A.

**D — C extended corpus-wide to all seventeen live-stale skills.** Rejected for this release, and it is the architecturally complete answer. The five additional skills were never triaged by any card in the milestone and the release was under hard scope lock, so including them would have shipped five unratified corrections. Offered at Stage 5 as an operator-override variant and not taken. **The five remain stale and are named debt, not silent residue.**

**E — record the determination, correct nothing.** Rejected. The evidence establishes a real one-directional defect; leaving twelve false self-descriptions standing fails the correction criterion outright.

**F — ship an automated conformance gate enforcing the bump on a description change.** Rejected *for this release only*, on sequencing rather than merit. It would land a new check on `core/deploy/deploy.sh` — the most contended file in the release, already carrying a serialization edge with a sibling card and a large concurrent insertion, in the same release in which another card was repairing the close path itself. **F is the durable fix and its deferral is the residual risk below.**

## Consequences

**The contract binds across three surfaces.** Every `SKILL.md` in all three modules; `pmo-skill-editor`'s classification duty when it adjudicates whether an edit bumps; and Checks 6 and 10, which read the field and its audit trail. A future change to the bump rule touches all three.

**The recurring class still has no forcing function, and this is the principal residual.** Nothing mechanically prevents the next `description:` rewrite from landing without a bump. The rule is now correct and the twelve instances are repaired, but correctness of a written rule is not enforcement of it — the corpus shows ten distinct occurrences of this exact class between 2026-06-06 and 2026-08-04, all of which a written rule was already nominally in force for. Option F is the answer and it is deferred, not closed.

**Five skills remain live-stale on the identical mechanism** — outside this release's scope lock, untriaged by any card, and now recorded here so the number is not lost. Under Option D they would take their own release values (`v3.69` ×2, `v3.70` ×2, `v3.77` ×1), which is itself further confirmation that "the release of the material edit" is the correct rule: a single current-release stamp cannot express five different answers.

**This record's own lateness is evidence for a gap the release did not close.** The verification row that was supposed to guarantee it — *"contiguous, no duplicates, no gaps, with the new ADR present"* — is executed by a tool that validates the numbering of records that exist and cannot fail on one never authored. The clause after the comma is a prose expectation the check does not encode, so a shipped record and a forgotten one produce byte-identical output. That is precisely the defect class this release was built to close, appearing in the release's own verification plan. It is named here and routed as follow-up work rather than repaired in a close-out commit.

## Reversibility

**MODERATE.** Confidence **HIGH**.

The two halves are separably revertible and only one is expensive. Reverting the rule change alone is cheap — one bullet and one list entry in a single standard, with no cascade. Reverting the twelve field corrections is what carries the cost: it re-stales twelve skill packages and returns the corpus to describing itself falsely, which is the condition this release existed to end.

Confidence is HIGH because the decision rests on two commits whose own messages record the distinguishing evidence — a measured routing change in one, a character-bound trim in the other — rather than on inference about authorial intent.

## Related ADRs

- **ADR-006 — Skill-to-module map.** Defines the three-module decomposition this contract spans; *"every `SKILL.md` in all three modules"* resolves through that map rather than through directory convention.
- **ADR-036 — Deterministic version-claiming.** Governs how a platform release tag is allocated. Rule (4) above writes such a tag into a skill's `version:` field, so the value's meaning is inherited from that allocation rather than redefined here.

**No supersession.** This record amends no prior ADR. Stage 5's N-ADR-3 check confirmed that no existing ADR or standard governed the field-vs-effect distinction, which is why the record was warranted rather than an amendment.
