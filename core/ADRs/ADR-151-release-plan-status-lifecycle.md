<!-- reference-durability: allow-link -->
---
title: "ADR-151 — A release plan's status field records the document's own lifecycle, not the release's deployment state"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-24
release: release-identity-and-plan-lifecycle
deciders: "Stage 5 Solutioning spoke (design, evidence-grounding) + hub Procedure 4 adversarial evaluation (re-probe, population correction) + Collective Review (scope-lock) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [release-corpus, frontmatter-schema, duplicate-source, close-out, plan-lifecycle, lint, ADR-092]
source_observations:
  - "Measured across the whole plan corpus at the release baseline: 179 plan files, 33 carrying a frontmatter `status:`, and every one of the 33 reading `ACTIVE`. Zero terminal values existed anywhere. This is not drift from a correct state — no plan had ever reached one, and the transition had never fired for any release in the history of the corpus."
  - "Nineteen of the affected plans belong to releases the ledger records as VERIFIED. A reader opening such a plan and reading `status: ACTIVE` would conclude the release was still running, and the plan is the surface most likely to be opened first."
  - "Two things were missing and they are separable: no schema, template or exemplar stated what a closed plan's status should read, and nothing performed the transition. An implementer told to 'transition the status to its terminal value' had nothing to copy."
  - "The root cause is deeper than 'close-out does not touch plan frontmatter'. No tracked file emits the plan frontmatter block at all — the plan template carries no YAML frontmatter, and the field propagates by copy-paste from the previous release's plan. Nothing wrote it, so nothing was ever going to transition it."
  - "THREE status surfaces exist, not one: the frontmatter field (33 files, one value), a body `| **Status** |` header-table row (36 files, 12 distinct free-prose values, template-mandated with a 6-value enum that is not obeyed), and the RELEASE_LOG `State` column. Twenty-two files carry two of these in disagreement."
  - "A single hand-made terminal exemplar existed in the corpus: one plan's BODY status row already read `CLOSED — Stage 13 close-out complete; RELEASE_LOG state VERIFIED`. It is the only observation available of a human facing this exact question with no schema to consult, and it agrees with both governance limbs below."
  - "Five of the status-carrying plans open with HTML marker comments ABOVE the frontmatter fence. A reader keying on 'the file opens with a fence' sees 28 of 33 and reports a clean result over a population five files short. This defect was reproduced independently three times during this release — by the design spoke, by the hub, and by the build — before it was made a binding implementation constraint."
  - "The semantically obvious home for the new assertion, the linter's `--check schema` mode, has ZERO live callers: its only occurrences are the tool's own usage docstring, historical corpus prose, and one agent-invoked skill checklist. A check placed there would have been green and enforcing nothing — the exact outcome the originating card's own acceptance criteria forbid."
---

# ADR-151 — A release plan's status field records the document's own lifecycle

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance — `142 → 151`.** Held **ADR-142** branch-local; renumbered to **ADR-151** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 142. In-release citations that read "ADR-142" denote this record.

## Context

The release corpus records one fact per release across several surfaces, and the schema that governs it carries an explicit Derived-Surface Contract: every restatement of a release fact either names its source in that register or is a defect. The `RELEASE_LOG.md` table row is the registered SOURCE for the release's deployment state, and its declared lifecycle is `DEPLOYED` (written at Stage 12) → `VERIFIED` (written at the Stage 13 chore PR).

Separately, and without ever being specified, release plan files began carrying a frontmatter `status:` field. It was authored `ACTIVE` and never changed. At the release baseline every one of the 33 plans carrying the field read `ACTIVE`, including plans for releases that had shipped, been verified, and closed months earlier.

Two questions had to be answered together, because answering either alone leaves the defect intact:

1. **What should a closed plan's `status:` read?** No schema, template or exemplar said. The field had no terminal value to transition *to*.
2. **What writes it?** Nothing did. The close-out never touched plan frontmatter, so even a defined value would not have been written.

The second question is where the naive framing breaks down. The field is not emitted by any tracked file — the plan template has no frontmatter block at all, and the block propagates by copy-paste from the previous release's plan. Nothing ever wrote it, which is why nothing was ever going to transition it.

## Decision

**A release plan's frontmatter `status:` field records the plan DOCUMENT's own working life, and never the release's deployment state.** The enum is closed at three members:

| Value | Meaning |
|---|---|
| `ACTIVE` | The plan is a live working reference for a release still in flight. |
| `CLOSED` | The plan's working life ended — the release it plans reached its close. |
| `ABANDONED` | The plan was never fulfilled; the release it planned did not ship. |

The terminal value is **`CLOSED`**. The field tier is **OPTIONAL and forward-only**. The transition `ACTIVE` → `CLOSED` is performed at Stage 13 by a named close-out phase, never by hand. The enum's single home is the release-corpus schema's Plan-status lifecycle subsection; any other surface stating these values is a defect under the Derived-Surface Contract rather than a second authority.

## Why `CLOSED`, and not the words that first suggest themselves

`VERIFIED` and `SHIPPED` were both rejected, and the ground is the schema's own rule rather than taste.

The ledger's `State` column is the registered source for the release's deployment state, keyed on the same triggering event — the Stage 13 close. Putting `VERIFIED` in the plan's frontmatter would place a second copy of that fact in a second file, which is precisely the restatement the Derived-Surface Contract exists to prevent. A reader could no longer tell the plan's own state from a stale copy of the ledger's, and the two would drift the moment a close-out half-completed. `SHIPPED` is a softer form of the identical error.

`CLOSED` names a **different fact**: the document's lifecycle event at Stage 13 Close. Because it is a different fact, no restatement occurs and the contract is satisfied rather than waived. It also has the only corpus evidence available — the sole hand-made exemplar, written by a human facing this question with no schema to consult, chose exactly this word and anchored it to the ledger rather than copying it.

`SUPERSEDED` and `DEPRECATED` were rejected on a cited scope guard, not a preference: the platform doc-frontmatter standard that owns those values explicitly scopes release plans out of its own enum, delegating them to the release-corpus schema. `FINAL` and `HISTORICAL` were rejected as invention over observed convention — zero instances, no precedent.

The casing is UPPERCASE by frequency dominance within the governed population, which is absolute: every live instance is uppercase and none is lowercase. The schema's pre-existing lowercase `abandoned` declaration carried **zero** instances, so normalizing it to `ABANDONED` invalidates no file.

## Why the enum is closed at three, and why the field stays optional

The three members are jointly exhaustive over how a plan stops being a live working reference: it closed, or it was abandoned. Nothing else terminates a plan, so the enum does not grow per release, and a value outside the set is an enum violation rather than an extension — the checker fails loudly on one instead of treating it as a silent non-terminal.

The field is OPTIONAL because the majority of the historical plan corpus carries no `status:` at all. Promoting it to required would fail the entire historical corpus at Tier 1 and contradict the schema's own forward-only adoption rationale. Both assertions below are therefore **conditional on the field being present**, which is what preserves the tier. Promotion remains available once utility is proven, matching the pattern the schema already uses for two other optional fields.

## Why the transition lives where it does, and why the ordering is load-bearing

The transition is performed by a **new, separate phase in the existing close-out driver, positioned after the Deployment-Log cluster and before the plan-identity lint**. Three properties of that placement are decisions, not incidental detail.

**A separate phase rather than a fold into an adjacent one.** The driver already records, verbatim, why an earlier phase was extracted rather than folded into the ledger-transition function: a second writer there re-creates a three-writer collision that the extraction removed. Folding this write into the plan-identity lint would be worse still on two counts — that phase is a read-only gate whose failure paths return before any write could occur, and its version-less early-skip would silently skip the transition for exactly the releases whose plans live under the unversioned home and need it just as much.

**Before the plan-identity lint, and that ordering IS the interlock.** The close-out flips the ledger row to `VERIFIED`, then flips the plan to `CLOSED`, then runs the plan-identity lint — which now also asserts that a plan whose ledger row reads `VERIFIED` carries `status: CLOSED`. If the transition phase ever returns success *without writing* — the silent no-op that is this whole defect's signature — the lint observes `VERIFIED` alongside `ACTIVE` for that version and halts the close before the chore PR is created. Both edits are on disk and uncommitted at that point, so the lint reads them. This costs nothing: it reuses machinery that already exists and already version-scopes its findings, and it needs no change to the output-set manifest. Placing the phase after the lint forfeits the interlock entirely.

**The interlock is a backstop, not the only defence.** The transition phase re-reads the file from disk after writing and fails when the re-read does not confirm `CLOSED`. This matters because the lint's assertion is conditional on the plan joining to its ledger row through one of the existing identity oracles, and that join does not resolve for every plan in the corpus. The primary guarantee is the write-then-re-read; the lint is the completeness check behind it.

## Why the check lives in the plan-identity check and not the schema check

The semantically obvious home was the linter's file-level schema check — it is the Tier-1 schema surface and enum validation already lives there. **That home is wrong, and the linter's own comments say why.** The schema check has zero live callers; every occurrence of it is a docstring, historical prose, or a checklist row. The file already records this exact lesson about another check: one dispatched only under a mode nothing invokes runs solely inside its own acceptance test — *green, and enforcing nothing*.

The assertions therefore fold into the plan-identity check, the only plan-scoped check with live automated callers: the close-out phase that blocks the close, and a per-PR advisory CI step. This requires no new CLI surface and no new caller to register — and, decisively, **no edit to the deployment script**, whose only invocation of this linter is an unrelated mode. That is a designed property: wiring the schema check to fire would have required a new check block in a file contended across three concurrent releases, and would have coupled this change to the very instrument that would detect a bad edit to it.

## Consequences

**The body `| **Status** |` row is registered as non-authoritative rather than swept.** It is a real duplicate — 36 files, 12 free-prose values, 22 of them disagreeing with the frontmatter field — but sweeping free prose across 36 files is a distinct piece of work. The register-or-remove rule is satisfied by *registering* it: the Derived-Surface Contract now names it a non-authoritative narrative annotation and states that on any disagreement the frontmatter field governs. It is named and demoted rather than left to silently contradict the enum. Its retirement is routed to a follow-up.

**Any reader of this field must locate frontmatter comment-tolerantly.** This is stated unconditionally in the schema and enforced by a regression arm that seeds the marker-comment shape and requires the check to fire on it. A strict reader scores zero on that arm while every other arm stays green, so the tolerance cannot silently regress.

**A second undeclared frontmatter dialect remains open.** Every one of the plans in scope carries a `type:` value absent from the schema's enum and from the linter's own value set, and none carries the schema-required `version:` field. This shares a root cause with the defect fixed here — nothing emits or validates plan frontmatter — but reconciling it is materially larger and is routed out, together with the template gap that generates it. Until that ships, every new plan's frontmatter is still copy-paste.

**Rollback is CHEAP.** A revert restores the swept plan files and the source edits. Nothing here gates its own detection: the checker is exercised by seeded fixtures and by an independent suite, neither of which depends on the corpus state the sweep produced.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Terminal value `VERIFIED` | Same word, same file set, same triggering event as the ledger's `State`. A second copy of a registered fact — the defect the Derived-Surface Contract exists to prevent. |
| Terminal value `SHIPPED` | A near-synonym of the above; the same category error in softer form, and with no corpus precedent. |
| Reuse the platform doc-frontmatter enum (`DEPRECATED` / `SUPERSEDED`) | That standard's own scope guard delegates release plans to this schema. A fulfilled plan was completed, not deprecated. The rejection is cited, not assumed. |
| `FINAL` / `HISTORICAL` | Clean on duplication and adequate semantically, but zero instances and no precedent — invention over observed convention. |
| Home the check in the file-level schema check | Zero live callers. It would be green and enforcing nothing, which the originating acceptance criteria explicitly forbid. |
| Fold the write into the existing ledger-transition or plan-identity phase | Re-creates a writer collision the driver's own comments record removing; and the lint phase is a read-only gate that returns before any write, with a skip path that would silently exempt version-less releases. |
| Sweep the body `**Status**` row in this change | 36 files of free prose is a distinct piece of work well past this change's size. Registering and demoting the surface satisfies the single-home requirement without it. |
| Make `status:` a required field | Fails the entire historical corpus at Tier 1 and contradicts the schema's own forward-only rationale. Optional-now, promotable-later matches two existing fields. |
