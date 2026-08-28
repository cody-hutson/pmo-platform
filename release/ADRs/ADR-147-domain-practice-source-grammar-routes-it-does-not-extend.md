<!-- reference-durability: allow-link -->
---
title: ADR-147 — The domain_practice source grammar is a closed three-form set that ROUTES the unmatched case, and survival across Commit-0 is asserted absolutely rather than only by delta
status: Accepted — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-25
release: pipeline-spec-self-consistency
deciders: "Workspace owner. Design decision rendered at Stage 5 Solutioning for the Commit-0 provenance-survival card and accepted by the hub at Procedure 4. Recorded because the card's own filing shows authors re-litigating the same question, and because the mechanism decision turns on a vacuity argument that is invisible from the acceptance criterion as originally worded."
supersedes: none
tags: [architecture, release-pipeline, provenance, domain-practice, closed-grammar, route-not-extend, commit-0, both-arms, probe-validity, reversibility-cheap]
source_observations:
  - "The symptom is live, not dormant. v4.37_RELEASE_PLAN.md, merged 2026-08-23, carries ZERO domain_practice labels — a 284-line, 22-heading, well-formed plan — while v4.35 and v4.36 each carry one. The planning stage had recorded the symptom as having stopped recurring; it had not. Denominator 39 v4 plans, no sampling."
  - "A delta-only mechanism is vacuous on the shape that actually recurred, and this was demonstrated rather than argued. v4.37's plan was hub-authored directly, so its Stage-4 sub-task comment carried no label EITHER. Comment 0, plan 0, set-difference empty: the acceptance criterion as literally worded reports CLEAN on the one release that failed."
  - "The non-conformant source population is 5 of 81 labels (6.2%), and every one of the five had a codified home already. Classified against each plan's own File Change Matrix: four are entirely-internal matrices that take the pipeline-internal exemption verbatim, and the fifth is a prose instruction quoting the pattern inside a Risk-Register cell."
  - "Minting a fourth token would fire a 3-to-4 count cascade into two files OUTSIDE this release's File Change Matrix — stage-07-dev-testing.md and release-process.md both state 'one of three legitimate forms' — converting a behavioural change into a structural one. Sweep denominator 1,206 tracked markdown files; control arm (files containing 'Mode A') returned 157, so the sweep discriminates."
  - "Only an element whose serialization is FROZEN by a named schema is mechanically comparable across the two surfaces. Run by hand on v4.31 before mechanising: 0 casualties across 6 grammar-bearing elements and 9 section-shaped ones, but the naive token-level probe produced TWO false positives — the baseline pin and the version determination — both of which resolved to legitimate re-renderings rather than losses."
  - "The dash codepoint is already uniform, which makes normalization prophylactic rather than corrective: 85 of 85 exemption-token occurrences use U+2014, with zero U+2013 or ASCII-hyphen variants. Normalization exists so a future typographic slip is never reported as a semantic finding."
  - "The label has eight consuming surfaces and the most consequential one fails QUIETLY. The Stage-13 close-class resolver reads domain at rung 1; with no label it falls through to its default branch, which the close spec itself names as the failure mode — a wrong close that nobody notices."
---

# ADR-147 — The `domain_practice` `source:` grammar is a closed three-form set that ROUTES the unmatched case, and survival across Commit-0 is asserted absolutely rather than only by delta

## Status

**Accepted** — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `147` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py`. The oracle reported `ANCHOR 141 origin/main` and `NEXT-FREE 142`; `--detect` reported `CLAIMED-SET-BRANCH-ONLY 142,143,144,145,146 (detection only — never binds)` with all five claims `BINDS`. Those five are bound on this same release branch by records authored in earlier builds of this release, so `147` is this branch's contiguous next, with the mainline reaching `ADR-141` and no hole beneath any claim. The number was deliberately **not** reserved at design time — the oracle is a *read*, not a reservation, and three Stage-5 spokes in this release independently specified `142` for exactly that reason. Sibling unmerged release branches may claim overlapping numbers; those claims are **detection-only and do not bind**, and stepping past them to be safe would land a gap. The asymmetry is the whole rule: a duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole.

## Context

The `domain_practice` provenance label is determined once, at Stage 4 Phase A1.5, and read back from the **plan file** by eight downstream surfaces — most consequentially the Stage-13 close-class resolver, which reads `domain:` at rung 1. Between the determination and every one of those reads sits a single manual step: the Commit-0 transcription, where the Stage-4 sub-task comment becomes the durable plan file.

Nothing asserted that the label survived that step, and two independent failures followed from it.

**The label goes missing, and it went missing again during this release's own planning.** The prior record of the defect had been read as historical — recent plans carried the field, so the symptom looked dormant, and the release plan said so. It was false at the branch head. `v4.37_RELEASE_PLAN.md`, merged one day before the design ran, carries **zero** `domain_practice` labels across 284 lines and 22 headings, with `v4.35` and `v4.36` each carrying one. The dormancy premise was retired on live evidence and the design was built against a recurrence, not a memory of one. The consumer that loses most is the one that fails most quietly: with no label, the close-class resolver falls through to its default branch, which the close spec itself names as *a wrong close that nobody notices*.

**The obvious mechanism cannot catch the case that motivated it.** The natural reading of "the field is emitted at Stage 4 and dropped at Commit-0 transcription" is a set-difference between the two surfaces. Run against `v4.37`, that mechanism reports **CLEAN** — because `v4.37`'s plan was hub-authored directly rather than transcribed from a spoke comment, so the Stage-4 sub-task carries a thin *"output of record"* stub and the producer surface is empty too. Comment 0, plan 0, difference empty. A check whose only limb passes on the exact release that failed is not a check, and this is the same vacuity class the sibling `fcm-delivery` family names in its own header: *an absent matrix must never read as "no declared ADDs, therefore no violations."*

**Separately, the `source:` field had drifted out of any set.** A census of the whole plan corpus found **81** conformant single-line labels, of which **5** carry a `source:` value matching none of the three forms the planning spec codifies. The filing had recorded one of them as *"a fourth form"* and left extend-versus-route as an explicit operator call. The census resolves it: the population is a class, not an instance, and — decisively — **every one of the five had a codified home already**. Four sit on entirely-internal File Change Matrices and are simply the pipeline-internal exemption spelled differently (including one that is a single-word truncation of the token); the fifth is a prose *instruction* quoting the label pattern inside a Risk-Register cell, which is not a label at all.

The recurring authored case — *"in-repo precedent governs; no external practice consulted"* — reads like a genuine gap in the vocabulary. It is not. The spec already separates two properties that partition it with no residue: **sourcing-exempt** is a fact about *where the deliverable's files live*, and **domain-classified** is a fact about *what informed the design*.

## Decision

**Part 1 — the `source:` grammar is closed at exactly three forms, and the unmatched case ROUTES.**

Normalize before matching (trim; fold any dash used as the `N/A` separator to a single U+2014), then match exactly one of: **Form A — SOURCED** (a URL, or a repo-relative path ending in a tracked extension, optionally followed by an anchor or parenthetical qualifier; `name:` companion required); **Form B — UNSOURCED** (exactly `UNSOURCED-DOMAIN`; `rationale:` companion required); **Form X — EXEMPT** (exactly `N/A — pipeline-internal release`).

Any other value is **non-conformant and routes to one of the three** — it does not mint a fourth. The routing rule for the recurring case is stated normatively: when the File Change Matrix is entirely internal pmo-platform artifacts the release is sourcing-exempt and takes **Form X verbatim**; when the matrix is not entirely internal but in-repo precedent nonetheless governed the design, that precedent **is** a repo-relative citation and takes **Form A**, naming the concrete path.

Normalization is **prophylactic, not corrective**: 85 of 85 exemption tokens already use U+2014. It exists so that a future typographic slip is never reported as a semantic finding — the class of false positive that erodes trust in a control faster than a missed detection does.

**Part 2 — survival is asserted absolutely, and the delta is the secondary limb.**

A sixth always-on check family, `provenance-survival`, is added to `release/tools/verify-release-plan.sh`, wired exactly as `fcm-delivery` is. It emits four records: `PROV-COVERAGE` (unconditional, carrying `labels_found`, `plan_lines`, `delta_source`, and the delta limb's scope), `PROV-PRESENCE`, `PROV-GRAMMAR`, and `PROV-DELTA`.

**`PROV-PRESENCE` reads the plan alone and does not care what the comment said.** That is the load-bearing limb, and it is the one that fires on the `v4.37` shape.

`PROV-DELTA` compares only **rows 1–5** of the Commit-0 Survival Set — the elements whose serialization is frozen by a named schema. This bound is empirical, not stylistic. The comparison was run by hand end-to-end on `v4.31` before anything was mechanised: zero real casualties, but the naive token-level probe produced **two false positives** — the baseline pin and the version determination — each of which resolved on inspection to a legitimate re-rendering. Rows 6–9 are re-rendered prose between the two surfaces, so a token comparison of them manufactures findings rather than finding them. They are reviewer-read **by design**, and the split is stated in the coverage record so a reader sees the limb's scope instead of inferring it.

**Part 3 — the delta limb's evidence seam is defaulted rather than refused.**

`fcm-delivery` refuses its caller-supplied determinism seam against a live release plan, because a live git-derived source exists and honoring authored evidence would be an off-switch on a control that can run without it. That refusal is deliberately **not** copied here: **no host-reachable source exists for a GitHub comment**, so the same refusal would not harden this limb — it would delete it. The risk is neutralized by the **direction of the default** instead: absent evidence yields a **named SKIP, never PASS**, so withholding the comment cannot manufacture a pass.

**Part 4 — the enumeration has one normative home.** The Commit-0 Survival Set is normative in the planning spec's Outputs section; the transcription step in the hub-and-spoke bridge **cites** it and deliberately states no second one.

## Alternatives Considered

**A2 — extend the vocabulary with a fourth token** (`N/A — in-repo precedent governs`). **Rejected**, and this was the closest call. It is what the original filing proposed, and the case genuinely recurs. It fails on three counts. First, the case it names is **not distinct from a codified form**: all five observed values classify cleanly onto Form X or Form A against their own File Change Matrix, so the new token would sit on top of two existing forms *with no discriminator between them* — re-creating the authoring ambiguity one level up, which is the state that produced the drift. Second, it fires a **3-to-4 count cascade into two files outside this release's matrix**, converting a behavioural change into a structural one. Third, a shipped token is honored by every future plan, so retiring it later is a corpus-wide re-classification: **MODERATE** reversibility against Form-routing's **CHEAP**.

**A3 — a free-form prefix grammar** (`N/A — <any reason>`). **Rejected on governance conformance.** It absorbs all five variants with no routing argument, which is its appeal, and it makes `source:` unparseable against any set — which is precisely the state the original finding names as the defect. A grammar that accepts everything is not a grammar.

**A4 — presence only; assert the key exists and drop the `source:` grammar.** **Rejected on the never-FAIL rule.** It is the cheapest option and the field's busiest consumer reads `domain:` rather than `source:`. But a predicate that cannot reject any value cannot fail, which converts a real control into a control-shaped assertion — the exact defect class this release exists to remove.

**B2 — a delta-only comparison**, matching the acceptance criterion as literally worded. **Rejected, demonstrated rather than argued**: run against `v4.37` it reports CLEAN, because both surfaces are empty. This alternative is the reason Part 2 exists in the shape it does.

**B4 — a new standalone `check-plan-provenance.sh`.** **Rejected on extend-before-create plus a blast-radius ceiling.** `verify-release-plan.sh` demonstrably covers the capability — `fcm-delivery` is the identical producer-to-consumer join shape, always-on, with a corpus gate, a mandatory coverage record and a fail-closed ladder. A new executable additionally forces an execution-allowlist companion row in four forms, CI wiring, and a new self-test dispatch: a structural-tier change where a behavioural-tier one suffices.

**B3 — strengthen the existing Stage-7 grep step instead.** **Not discarded — routed as a follow-up.** It is the strongest surviving alternative. It was not chosen because a spec step cannot read the Stage-4 comment, so it cannot satisfy the comparison at all, and both of its files sit outside this release's matrix. It becomes *more* attractive after this ADR ships, not less: once `provenance-survival` exists, the Stage-7 grep is a weaker, stale-pathed second statement of one rule, and consolidating it is the natural next move.

**Full enumeration of the Survival Set in the hub-and-spoke bridge** rather than a pointer. **Rejected on a shipped decision of record** — the v4.13 Deviation Log considered exactly this pair of homes and chose the planning spec on an attestation argument: a step in that section is re-affirmed by every release's canonical-checklist attestation and the plan-readiness gate, while the alternative is affirmed by neither. Restating it would also mint a second normative home for one rule.

## Consequences

**A plan that today exits 0 will exit 3 if its provenance label is absent or non-conformant.** The aggregation rule in `verify-release-plan.sh` is ANY-FAIL-OR-ERROR, and three of the four new records can FAIL while two can ERROR. This is the intended teeth: the obligation moves from transcriber discipline to a gate, at Stage-6 C4 self-verification, which is **not** optional. Stage 7's re-run is optional and its Phase-A verdict is unchanged when Dev Testing does not re-run — stated so the change is not mistaken for a Stage-7 gate.

**`SCHEMA_VERSION` moves 2 to 3.** A fourth record source enters the emitted stream, so every consumer sees record ids it has never seen. No verdict value is added and no record field is renamed, so the Gate-6 verification-evidence grep contract is preserved; the bump is exactly the detectable signal that constant exists to give.

**Behaviour outside the plan corpus is byte-unchanged.** On a non-plan target the family emits one named SKIP and returns, contributing nothing to the aggregate. That inertness is what bounds the change.

**The count of legitimate `source:` forms stays at three**, so the two out-of-matrix specs stating *"one of three legitimate forms"* remain correct verbatim and no cascade fires. This is a direct consequence of routing rather than extending, and it is the concrete cost A2 would have imposed.

**Two residuals are accepted rather than hidden.** The Stage-7 grep becomes a redundant and weaker second statement of one rule — a duplicate-source condition this ADR creates and deliberately routes rather than absorbing. And **98 of 178 shipped plans carry no label at all**, each unclassifiable at the close-class rung-1 read; this release backfills exactly one, on its acceptance criterion's name. A corpus-wide backfill is rule-derivable but is separate work with its own reversibility profile.

**A known ambiguity is surfaced rather than resolved.** A plan that quotes the label pattern in prose *with* `source:` inside a brace body satisfies presence, contrary to the discriminator the Stage-7 spec states. Rather than invent a placement assertion — which the serialization-tolerance clause forbids, since typographic setting is not part of the schema — the coverage record reports every match's line number and the grammar limb grades the first, leaving a visible decision for the reviewer.

## Reversibility

**CHEAP · Confidence HIGH.**

Every element reverts as one unit on a single branch: two in-place spec edits, one additive check family in one tool, one backfilled label with its Deviation-Log row, one regression group with its fixtures, and this record. The check family is one function plus one `main()` wiring block and reverts as a single hunk; reverting it restores the prior exit-code behaviour exactly, because no verdict value or record field was changed. Nothing here touches an operator-local or git-ignored surface, and no file is moved or renamed.

The one asymmetry worth naming: the **grammar** is cheaper to revert than a fourth token would have been. Tightening a three-form set that the spec already codifies leaves every conformant plan conformant under both the old and the new wording, so there is no corpus to re-classify on revert — which is precisely the reversibility argument that decided against A2.

Confidence is HIGH because the decision rests on a whole-population census with both arms run, taken at `8dc00db1` and reproducible by re-running the extractor over `git ls-files release/releases/plans/` filtered to `*_RELEASE_PLAN.md`: at that anchor the corpus yielded 81 conformant labels, of which the proposed grammar accepted 76 and rejected exactly the 5 non-codified values, while a fabricated control value was rejected by all three forms. The population grows, so the figures are anchored to that commit rather than stated as current; what does not change with the population is the shape of the result — a grammar that discriminates in both directions.

## Related ADRs

- **ADR-092** — version identity binds at the Stage-12 atomic claim. The reason a release plan is slug-primary while in flight and versioned only after the claim, and therefore the reason the stale `plans/v<X.Y>_RELEASE_PLAN.md` path form reconciled by this release resolves for no in-flight plan.
- **ADR-062** — canonical-spec edit wins over substrate mutation. Why the originating card's body was left as historical record while every correction landed in the design and in this record.
- **ADR-146** — supersession is an append; integrity is a dated read-only sweep. The sibling record from this same release; both cards land producer-to-consumer join checks, and both were required to enumerate a whole population with a denominator and a specificity arm rather than assert a single write.
