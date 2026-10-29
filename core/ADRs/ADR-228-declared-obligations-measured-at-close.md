---
title: ADR-228 — A declared obligation is measured over its population at close, and a shortfall closes only with an owner that names it
status: Proposed — ratified at this release's Stage 13 Phase A13
date: 2026-10-29
release: governance-obligations-measured
deciders: "Workspace owner (operator) — scope rendered at the release's Stage-5 Collective Review scope-lock, which adopted the independent adversarial review's counter-design (no unmeasurable declaration; an owner valid only where it names the population) and its plan-resolution and failure-mode refinements. Design by the Stage 5 Solutioning spoke; authored by the Stage 6 Engineering spoke"
tags: [gate-13, g-cl10, declared-obligation, population-record, owning-work-item, outcome-limbs, class-3, warn-mode]
source_observations:
  - "At the design baseline the gate-coverage register held 77 rows; the Surface cell's first word read ci on 34, prose on 23, deploy-time on 17, deploy on 2 and a split cell on 1. Every prose row was unwired: 15 carried no runner pointer and 8 pointed at a markdown file, while 12 ci rows pointed at an executable."
  - "Of the 22 register rows carrying the class 3-O marker, 5 were wired to deploy checks that measure them on every run, and 6 unwired class-3 rows carried no marker. The marker therefore did not select the rows nothing executes; the Surface cell did."
  - "Replaying the range rule over the 39 first-parent merges that touched the standard since 2026-06-01 enrolled 24 new prose rows and 3 modified ones, and 12 of the 39 merges would have produced subjects, so the shakedown has a population to read."
  - "Across 258 Release Outcome Statements read from milestone descriptions, one carried a limb-owner line; three of the platform's own source observations were a declared obligation that reached close with no measurement and no owner, and a three-limb Outcome whose third limb lost its owning work item to a re-home before close."
  - "The version stamp at a Stage-12 claim renames the release plan from its slug path to a versioned path and commits the rename before Stage 13 runs, so a close gate that reads the plan from the working tree at the slug path reads a file that no longer exists."
---

# ADR-228 — A declared obligation is measured over its population at close, and a shortfall closes only with an owner that names it

## Status

**Proposed** — authored at Stage 6 Engineering of `governance-obligations-measured`, after the operator's Collective Review scope-lock rendered the scope this record documents. It is ratified at this release's Stage 13 Phase A13 under Gate 13 criterion G-CL9's authored-by-this-release limb, and the ratification is recorded in the frontmatter `status:` field, never inferred from a review comment or from milestone closure.

**Numbering provenance.** Claimed as **228** against an anchor of **227** on `origin/main`, read from `release/tools/renumber-adr.py --next-free`. The number binds at the Stage-12 claim; should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. In-release prose cites this record by its slug token, `{{ADR:declared-obligations-measured-at-close}}`, which resolves at the claim.

## Context

ADR-162 admitted an obligation-shaped declaration onto the gate-coverage register as class 3-O, and Check 62 recomputes every register runner pointer on every run. That settles whether a named runner still carries its predicate. It settles nothing about whether the population an obligation ranges over was ever measured: a register row whose Surface cell reads `prose` names a procedure nothing executes, and a release could add one, close, and leave it at zero conformance with no work item carrying the gap. A milestone's Release Outcome Statement had the same shape one level up — a limb promised in the Outcome lost its owning work item to a re-home and closed undelivered and untracked, because nothing bound limbs to owners.

The platform already holds every piece such a check needs: the register's own in-cell bold-label idiom, the population-record form of `core/standards/gate-efficacy-standard.md` Requirement (c), the release plan's Verification Evidence section where Stage 13 writes per-check records, and a close-gate engine that resolves exactly one release's commit range and its membership. What was missing was the criterion that asks the question at close, and the declaration that tells it what to measure.

## Decision

1. **A new Gate-13 row, G-CL10**, not a limb on an existing row. No G-CL1..G-CL9 row owns "declared obligations are measured", and one concern per identifier keeps its own sink id, sentinel and flip decision.
2. **The runner extends the existing close-gate engine.** `core/deploy/tools/check-doc-gates.py` gains a `g-cl10` gate and `deploy.sh --check-doc-gates` a `g-cl10` branch, reusing the release-range resolver, the membership read, the per-subject report and its population guard, the warn-log sink, the committed sentinel, Check 28's deadline arm and self-test group DG. The engine stays offline; the wrapper does every GitHub read.
3. **The population is the register rows whose Surface cell leads with `prose`** — leading markup set aside — that the release added or modified: present at `<head>` with text, a `**Population:**` segment set aside, absent at `<base>`. Adding only the segment does not enrol an old row; rewording the obligation does.
4. **Each such row declares its population in-cell:** `**Population:** \`<name>\` — population: <member definition>; probe: \`<exact invocation, or a census definition>\`; threshold: <1–100>%`. The name is the row's key. The probe is accepted by its shape alone: an exact invocation opens on a file tracked at the release head or a tool on the engine's fixed allowlist, and a census definition reads `<kind> census — <definition>`; a probe matching neither is malformed, whatever its first word spells. **No obligation may be declared unmeasurable:** a population no instrument reaches is enumerated by hand in the census form the standard already defines, so `examined` and `conforming` are always numbers. A 0% threshold is malformed, because it admits the case the gate exists to fail.
5. **The record is the population-record block in the release plan's Verification Evidence**, at any heading depth, with `probe:` pinned ` @ <commit>` and followed by `conforming: <k>` and `owner: #<N>` or `owner: none`. The plan is found through its `milestone:` frontmatter, because the version stamp moves it before Stage 13 runs; an explicit `--plan` overrides.
6. **The Stage-13 spoke produces the number; the engine grades it.** The engine binds the record to the declaration by the probe string and a pin that contains `<head>`, and reads a sensitivity arm observed at one or more. It executes nothing from markdown.
7. **A shortfall closes only with a valid owner:** an open issue of this repository, not a pull request, not an issue of the closing release, **whose body or comment stream names the population**. Stage 13 posts the record on that owner, so the residual is written where the owner's own close will meet it.
8. **Arm (ii) binds Outcome limbs to owners.** The Outcome template gains a required `**Limb owners:**` line; each limb names at least one owning work item, which must resolve to an issue of this repository and must not have been closed as not planned or as a duplicate. An Outcome missing the line fails when its milestone's composition lock — or, absent the lock, its creation — falls on or after the date the line became required, and is out of scope before it. Whether a limb was attained stays G-CL7's question.
9. **Warn-mode initial,** as G-CL6 and G-CL8: rows written under `check: "g-cl10"` (W1), a repository-derivable deadline through `GCL10_ROLLOUT_ARMED` and Check 28's deadline arm (W2), sentinel `.github/g-cl10.enforce` reading `warn`. Arm-ii rows open `limbs:` so the drain counts each arm, and the flip needs evidence per arm.
10. **No introducing-release exemption.** Stage 13 runs after the merge, so the gate exists when the release that adds it closes.

## Alternatives Considered

- **A limb on G-CL4** — rejected: G-CL4 owns "evidence persisted", not a content verdict, and its mode is `block`, so the limb would block on day one.
- **A limb on G-CL7** — rejected: G-CL7 does not emit, and its arm has nothing to do with the register.
- **A limb on G-CL3** — rejected: G-CL3's own extension test is that it already owns the concern, and it does not own this one.
- **A standing deploy check with no Gate-13 row** — rejected: the obligation is a close criterion, and a `--check` run has no release context.
- **A phase in the automated close-out driver** — rejected: its phases write, its self-test is single-platform, and a hub-direct close runs no script.
- **A new engine** — rejected: a second resolver and sink for the same release context.
- **A review step only** — rejected: it cannot write a verdict or carry the sensitivity and specificity fixtures the release requires of each runner it adds.
- **Selecting the population by the class 3-O marker** — rejected: the marker selects wired rows and misses unwired ones; the Surface cell states what executes a row.
- **Every register row, or opt-in rows** — rejected: the first duplicates each implemented gate's own denominator; the second makes an undeclared obligation invisible, which is the failure itself.
- **A declaration in the release-plan template** — rejected: it needs a sanctioned skill session and puts the key away from the row it keys.
- **The engine runs the declared probe** — rejected for **host-side reach**: a probe may need the repository host or the operator's machine (an issue listing piped through a script is one), which an offline engine cannot reach. Running corpus-declared shell is not the eliminating reason, because the chosen design has the Stage-13 spoke run the same string under the hook layer, which refuses what it refuses and records the refusal.
- **A typed safe probe grammar** — deferred: list, member and rows populations sit outside the file-root grammar the standard can declare today.
- **Admitting `probe: none`** — rejected: an obligation with neither a query nor a number would close on an owner alone, which is the checkbox the card set out to prevent.
- **An owner valid by existence alone** — rejected: an open issue whose scope never names the obligation carries nothing after close; the residual would have a number but no home.

## Consequences

- Every release that adds or modifies a `prose` register row declares its population and records it at close; the record is measured, or owned by a work item that names it.
- Every Outcome limb names its owning work item, so a re-home that strips a limb's owner reads FAIL at close instead of vanishing.
- **Limits, stated:** (1) it grades the record and does not re-run the probe, so a record whose numbers its probe did not produce is the accepts-artifact-as-action class, bound by the probe pin and the sensitivity reading and left to review; (2) an obligation never written into the register is invisible to it; (3) a row whose Surface cell misstates what executes it is classified by its cell; (4) a limb missing from the owner line is invisible — Stage 9's goal-conformance read sees the AFTER prose; (5) the gate is advisory and deploy-time-only, so it adds no pre-merge teeth; (6) the population guard compares the listed subjects with the graded ones, and both come from one enumeration, so a row that enumeration misses is missed by both — the fixtures test the markup spellings the corpus carries.
- The census-form population record now has a second parser beside the standard's conformance suite; the label tuple is the same, and a Stage-7 arm asserts the two agree.

## Reversibility

**CHEAP.** Every edit is additive and the gate ships warn-mode, so reverting the merge strands no blocker; the template's required field reverts with it.

## Related ADRs

- ADR-162 — this record is the consumer relationship its boundary section assigns to class 3-O: ADR-162 keeps the at-authoring obligation and Check 62's runner resolution; this record adds the at-close measurement. Neither restates the other.
- ADR-129 — the close-class disposition table gains one explicit no-op row for G-CL10; ADR-129 itself is not edited.
- ADR-166 and ADR-167 — the warn-mode declaration carries a written sink and a repository-derivable deadline; G-CL10 takes both.
- ADR-181 — in-release prose cites this record by its slug token, which binds at the claim.

## References

- #5286 — the card: declared obligations ship with zero conformance and no owner, and close-out never measures them.
- #4919 — names the accepts-artifact-as-action class that limit (1) cites, and refines Gate 9 criterion G-PR4, which names G-CL10 as its close-moment counterpart.
