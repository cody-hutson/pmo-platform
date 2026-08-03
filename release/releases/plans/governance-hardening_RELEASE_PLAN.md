---
title: Release Plan — governance-hardening (one authoritative release record, three projections, and the governance surfaces that depend on it)
type: release-plan
plan_type: release
status: ACTIVE
release: "{{RELEASE_VERSION}}"
milestone: 290-governance-hardening
release_class: routine
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `governance-hardening`

**Milestone:** `governance-hardening` (#290) · 10 members / 66 pts · **run 2**
**Version identity:** **slug-primary per ADR-092.** The branch is `release/governance-hardening`; every version reference in this plan is the `{{RELEASE_VERSION}}` token. The number binds at the **Stage-12 atomic claim**, at which point this file is renamed to `<version>_RELEASE_PLAN.md`. **No version is hardcoded anywhere in this release.**
**Topology:** D-C SINGLE — one release branch, one PR, one merge. This plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (operator-ratified). Stage-6 slices route one at a time in dependency order on the single branch. Force-push — including `--force-with-lease` — is prohibited on the shared branch under any multi-chip activity.
**Release class:** `routine` · **Stage-9 depth: Deep.**

> **Provenance.** This file transcribes the **Stage-4 Release Planning re-plan** posted on hub sub-task #4457, reconciled to the approved **Stage-5 Solutioning** design on #4467 (the design, two independent adversarial reviews, one Blocker-revision spoke, four rounds of acceptance-criteria authoring, and a bounded confirmation returning CLEAR TO EXIT). Where a Stage-5 finding superseded a Stage-4 assumption, the transcribed sections carry the **Stage-5** position and the § Deviation Log records the delta. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke (#4470).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` (binds at Stage-12 atomic claim; slug-primary per ADR-092) |
| **Date Created** | 2026-08-02 (Sunday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-hardening` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `governance-hardening` (#290) |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing.*

**Outcome.** The platform's release ledgers stop being four independent copies of one fact. `RELEASE_LOG.md` remains the authoritative **event** record and the release note remains the authoritative **narrative** record; `RELEASE_INDEX.md`, `RELEASE_DIGEST.md` and root `CHANGELOG.md` become **projections** emitted by a single tool that cannot read a clock, cannot read operator config, and cannot rewrite history. Around that root, nine further cards harden the governance surfaces that depend on the release corpus: retention and archival, the records-retention terminal decision, the overloaded `domain` token, the template-family taxonomy and registry, external-target knowledge placement, the self-improving-loop codification, and the intake gates' assumption that a human does the work.

**Issues resolved (10).** #4455 (root — one projector, three typed sources) · #3715 (bound the one surviving authoritative ledger) · #3387 (retention-purge terminal decision, rendered against the post-normalization taxonomy) · #3825 (`domain` token disambiguation registry) · #3196 ⊕ #4454 (merged work-package — the missing `template_family` families) · #3290 (template-registry hygiene) · #3413 (external-target knowledge axis) · #3556 (self-improving loop + backlog-hygiene codification; encode-then-evict) · #3816 (agent-led execution in intake gates).

**Key decisions.** The card's literal ask — *"make `RELEASE_LOG.md` the single authoritative record and generate the other three from it"* — is **rejected on measured grounds** and replaced with **two file sources plus two run-scoped inputs, one projector, per-field provenance**. The LOG carries neither a `# ` headline nor a `summary:`, so forcing the narrative onto it would import ~160 headlines and ~156 summaries into the exact file #3715 exists to bound. The projector emits **entries to stdout**, never files, because ~63 % of DIGEST headlines and ~60 % of CHANGELOG blocks carry legitimate post-emission operator edits that a whole-file regenerate would destroy.

**Reversibility.** **MODERATE / Confidence HIGH** overall. `git revert -m 1` of the release PR restores every file's bytes. It does **not** restore *provenance*: a reverted repo's next close-out writes by the old four-writer path. The mitigation is that **no history is regenerated** — the revert surface is one LOG cell plus tooling. One member (#3556) carries an **IRREVERSIBLE** action (memory eviction) executed as the release's last step, after the corpus write is on `main`.

**Downstream impact.** No runtime or skill behaviour changes for end users. Every historical INDEX row, DIGEST entry and CHANGELOG block is byte-identical at merge except a single `v3.69.1` `Release PR` reconciliation made **in the LOG**. Check 23 stays **warn-mode**; its flip to enforce is a staged post-merge decision on the check's own ≥3-day zero-false-positive condition, not something this release asserts.

`RELEASE_LOG.md` goes from **783,667 B to 148,558 B** — an 81 % reduction, 51,442 B inside its new 200 KB budget — and becomes readable end-to-end again rather than only grep-addressable. **Nothing is deleted.** The 147 relocated per-release narratives move to four archive segments *in the same directory*, so a recursive grep finds them exactly where it always did; every heading stays in the LOG with a pointer, so every link into it still resolves. Anyone who reads a release ledger sees a shorter file and one extra line per historical release saying where its detail went. The one tool that reads that detail — the FinOps velocity join — was changed in the same commit to read the segments too, and its basis is measurably unchanged. A new warn-mode gate reports the file's size on every `deploy.sh --check` run and says when the next archival chore is due.

The question of whether the platform should ever *delete* a generated artifact is now answered, in writing, for the first time. It was asked once before and settled without a record, which is why it came back. The answer is **no — archive is the permanent terminal**, and the reasoning is deliberately not "we never delete", because that is not true: the platform already purges in three other places. It is that the rule could not be written down. The field a retention clock would read is stamped on **zero** files, so the set of things eligible for deletion is empty; no retention value anywhere in the corpus has ever authorized destruction, so the clock itself would be invented; and the whole population in question is about **1 MiB against a 1.45 GiB workspace**, with nothing added to it in three months. Four checkable conditions are written down alongside the decision, so re-opening it later is a defined step rather than a fresh argument. Separately, the three projected ledgers get an explicit answer about their own size: they **do** owe something, but not a cleanup. Their records classification — shipped earlier in this same release — closes both ways a file can get smaller, because they hold content that exists nowhere else and a regenerate would silently destroy it. So their size is managed by **how they are read**, not by removing anything from them, and any future proposal to shrink them is a governance change rather than a tidy-up. **Nothing is deleted by this release.**

The word `domain` turned out to mean **six different things** in this corpus, and nothing said which was which. It classifies the kind of deliverable a release produces; where a project artifact came from; what content area a file is filed under; a kind of acceptance criterion, where it is an adjective and not a field at all; what canon family a template belongs to; and what subject a platform document is about. Two of the six are even called the same thing — *"three-domain classification"* — at their own definition files, with **no overlapping values**. There is now one page that lists all six, says which file owns each, and shows how to tell them apart, and each of those files carries one line pointing at it. **Nothing is renamed** — that was decided some time ago and stands; the fix is an index, not a migration, and every one of the 44 existing declarations is untouched.

The sixth meaning was found only because the list was rebuilt from a fresh sweep rather than copied from the ticket. Four earlier surveys of this same problem had missed it.

Underneath that, a real defect: **seven templates could not be given the provenance header every template is supposed to carry, and nobody owned fixing it.** The reason is that those seven already have a `domain` line — but it belongs to the *artifact they produce*, not to the template itself. A markdown file has one frontmatter block, and in these seven it is already spoken for. Adding the template's own header would have put two `domain` lines in one block, and YAML resolves that by **silently keeping the last one and discarding the first, with no error**. Two other pieces of work in this release were routing these seven templates here expecting the index to unblock them; an index cannot, and the first well-meaning bulk edit would have quietly stripped the provenance from every tracker and project page the platform creates. The decision is now written down: those seven are a named class, they are **not** exempt, and their header goes in a companion file beside the template — the same arrangement the platform already uses for spreadsheet templates, for the same reason. This release decides it and records why; it deliberately does not do the move, so the two dependent pieces of work now build against an answer instead of an assumption.

Alongside that, **twelve templates had no artifact family to belong to** — so they could not be given a provenance header even where their frontmatter was free, because the header requires a family name and the field only accepts names from the official list. The list did not have one for any of them. Twelve names now exist, one per template: the project charter, the change log, the lessons register, the artifact register, the clarification queue, and the seven shared pages the platform keeps for a person, a system, a vendor, a workstream, a decision, a cross-project dependency, and a per-project rollup. A thirteenth was added for a different reason — a report a release stage produces when it finishes checking something had nowhere sensible to be filed, because the closest existing category was the *plan* for a check rather than its *verdict*.

The count was re-tested rather than assumed. The obvious objection is that the six entity pages look alike — same headings, same shape — and might be one family rather than six. They share a page layout and nothing else: each carries a different set of required fields and a different lifecycle, five distinct ones across the six. The platform had already answered this question without writing the answer down, which is why three separate passes over the same files produced three different counts. Two trackers that render nearly identical tables have always been listed separately; three status formats are listed separately and then grouped once, further down, by what standard they follow. **The list is kept at the level of "what fields does this file have", and the grouping happens later.** That rule is now written down as a four-step test, so the next person asking "does this need a new entry?" gets the same answer.

The seven-file class from the paragraph above turned out to be **fourteen**. Counting the whole registry: fourteen templates carried their own header, fourteen carry the frontmatter of the thing they produce, and seven carried nothing at all — thirty-five in total, with no remainder. (Those last seven are dealt with further down; by the end of this release the split is twenty-one, fourteen, and none.) The seven originally named were the ones where the clash is *visible*, because they happen to carry a `domain` line that collides. The other seven have exactly the same problem — the slot is taken — with nothing to collide against, so a search for the collision never found them. **They are the seven this release actually fixes**: their headers now ship in companion files beside them. The seven with the visible clash are still waiting, as planned. This release also settles the two questions that decision deliberately left open — what the companion file is called and what goes in it — because seven of them now exist and the question stopped being theoretical. The answer is the full template filename with `.provenance.yml` on the end, carrying the complete header rather than a subset, and the older `.meta.yml` files are **not** a competing convention: they hold the produced artifact's details, not the template's. Both stay, neither is renamed. One consequence is written down in bold because it is easy to get wrong: any future count of "which templates have provenance" that looks only at the templates themselves will silently miss every companion file and report those templates as missing forever.

**The document that teaches the template lifecycle was using an example file that does not exist, and has never existed.** Anyone following it to see a worked example found nothing; the taxonomy separately listed that same missing file as present and unproblematic. The file was pointed at rather than written, because writing it cannot work: the document verifies its own example by looking for a template that has been through full approval, and no template ever has — approval requires evidence the template has been used at least once, which a brand-new file cannot have. So authoring the missing file would have moved the false claim rather than removed it. The example now points at a real template, and the pointer was changed everywhere at once: fourteen mentions across seven files, after which the old name returns nothing anywhere in the repository. A near-identical name belonging to a *different, real* file was deliberately left alone, and that near-collision is part of why authoring was the wrong branch.

Repointing alone would not have been enough. The worked example still showed an approved state no template holds, and its verification step still ran a search that comes back empty no matter what it points at. Both now show the truth: the example sits at the first lifecycle state because the evidence gate is unmet across the whole registry, and the verification finds the example by structure and then *reads* the state it is in rather than asserting one. **An example correctly parked because a gate is unmet is a faithful demonstration of the gate, not an embarrassment to it.** The identical broken check was found in a second place in the same document — introduced earlier in this same release when that section was rewritten for the companion-file convention — and was fixed in the same pass, because searching on the *failing behaviour* rather than on the missing filename is what surfaced it.

Two smaller corrections travel with it. The registry now lists every template it holds: one was missing, found by checking all thirty-five rather than trusting the count of two the ticket carried — the other had already been added earlier in this release. And the lifecycle document said its provenance header has **fourteen** fields while listing **fifteen**, twice, in two separate places inside itself. Fifteen is right; the wrong number appeared seven times across two documents and all seven were corrected together, because fixing some of them would have left one of those documents disagreeing with itself. One of the seven sat directly beside the word *verbatim*, which made it actively misleading to anyone copying the header.

Finally, **the last seven templates carrying no provenance at all now carry it.** These are not the hard cases — their frontmatter was simply empty, and they were waiting only for a family name to exist, which earlier work in this release supplied. Every one was read end-to-end and placed by hand rather than by a script, which mattered for one of them: it opens with a marker comment, and frontmatter has to be the very first line to be read as frontmatter at all, so its block goes above that marker rather than below it. The registry-wide picture is now twenty-eight of thirty-five templates provenanced, and the seven still outstanding are exactly the visible-clash class described above — a single, named, deliberately-deferred group rather than an unexplained remainder. The nineteen originally recorded as blocked have shrunk to those seven, because twelve of them were unblocked by other work inside this same release.

Packaged skills were rebuilt again for this, on the same mechanism and for the same reason as before. Nothing in any skill was edited by hand — the rebuild is needed because several skills carry copies of the template standards this release changed, and those copies are stamped in at build time. **A change can stale a package without touching the package, or the skill, at all**, which is why the check for it asks which shared documents were edited rather than which skill folders were.

**A convention belonging to a different repository was being remembered instead of read, and it had quietly gone out of date.** The platform is a toolkit that can be pointed at repositories other than its own. When it was, that repository's conventions ended up written down in the agent's memory — cached from an earlier session rather than read from the repository itself — and one of them drifted: the remembered note named a label the target repository no longer used, and the named label had in fact been deleted. Nothing forced a check before the remembered value was acted upon; it was caught only because an unrelated task happened to look at the live repository.

The obvious reading is that the note was in the wrong place, and the obvious fix is to give it a better one. **Both are wrong, and that is the finding.** The note did not hold one fact; it held two welded together — *"I ratify work with a status label"*, which is the operator's own working practice and perfectly fine to remember, and *"…and the label is called X"*, which is an observable property of somebody else's repository and must never be remembered at all. The rule that decides where a fact belongs looked at the half it could recognise, filed the note by that half, and the other half rode along as a passenger nobody owned and nothing ever refreshed. There was no step that took a fact apart before deciding where it went.

**So the fix is not a better place to keep the value. It is the removal of a value that can be kept.** A fact about another repository is now split before it is filed: the practice half is filed normally, and the half that describes the other repository gets no home anywhere — it is looked up fresh every single time it is used. The only thing still written down is the repository's **address**, which the configuration already held, and which is kept because you cannot look anything up without it. Nothing is cached, so nothing can go out of date; and because no stale answer can be served, the next time the other repository changes the platform **stops and says so** rather than answering confidently and wrongly. The deliberate cost is stated rather than buried: a session that cannot reach the other repository cannot answer the question and must halt. There is no offline fallback, because a fallback is the defect wearing a different hat.

One correction to the design travelled with the build. It proposed routing the lookup through an existing adapter interface. That interface turned out to be built for a single, unrelated job — claiming version numbers — and none of its four operations returns the kind of value a lookup needs. Pointing at it would have been exactly the failure being fixed: trusting a plausible-looking reference instead of checking it. **The lookup is now stated as three requirements it must satisfy, and the missing operation is written down as a named gap rather than papered over with a citation that does not hold.** Housekeeping travelled with it too: five pointers inside the memory contract still named a section number the boundary carried before another section was inserted ahead of it, and two of them still said "three" of something the corpus now has five of. All seven were corrected in the same pass, because a new paragraph citing the right section would otherwise have sat directly beside a bullet citing the wrong one.

**Two pieces of the platform's own account of itself were never written down, and the notes holding them could not be released.** When the platform's vision was codified into the corpus some months ago, six remembered notes were meant to be absorbed and then discarded. Four were. Two were not — and because the work that was supposed to absorb them had already been marked finished, nothing owned the remainder. The notes stayed in memory, flagged ready to discard, unable to be discarded, with nobody responsible for the gap.

The first missing piece is **how the platform improves itself**. It runs a loop: PMO work surfaces a problem, the problem becomes a ticket, the ticket goes through the same release pipeline as everything else, the fix ships, and the improved platform runs the next round of PMO work. Every part of that was already true and already enforced somewhere — but nothing said it was a *loop*, so a fresh reader could not see the shape. It is now written in the architecture overview, immediately after what the platform is and who it serves, so the three vision statements sit together under one heading rather than scattered. It is written as a table rather than a paragraph: each of the six steps names the file that actually enforces it, and each of those names is a working link. If one of those files is ever deleted or moved, the link stops resolving and the repository's own link checks say so — so the description cannot quietly outlive the machinery it describes.

The second missing piece is **four rules about not throwing away planned work**. They exist because the failure they prevent is specific and easy: an agent asked to tidy the backlog reaches for the nearest sizing rule, finds a queue of milestones that have not started yet, and recommends killing them as clutter. The rules say — do not measure a whole multi-role product backlog against a single delivery team's item-count target; do not call queued work "aspirational" or "zombie" on the strength of where it sits in the queue; recommend closing something only on evidence that it is delivered or no longer needed, never on its age; and never delete or rewrite the record of a milestone that was retired. They are placed on the page that already *produces* removal recommendations, so the restraint sits where the recommendation is made rather than in a separate document nobody opens on the way past.

Both words in that section's name were already taken, and the design's original reasons for using them were wrong in both cases — checked rather than inherited. **Retention** is defined elsewhere in the corpus as the *minimum* period a record is kept before it becomes eligible to be filed away, which is a period, not a restraint on a recommendation. And **zombie** is spent twice for two different things, one of them for backlog items, in the very file these rules point at one rule earlier. A survey of every alternative name found all of them occupied too, so a rename would have relocated the collision rather than removed it. The name stays, and the section now names both neighbours explicitly and says what makes it different from each.

**The two notes are not discarded by this release.** Discarding them is the only step in this release that cannot be undone by reverting it — the notes live outside the repository, so a revert restores every file and restores nothing else. It is therefore held until after the release is merged, gated on a check that the codified text is genuinely present in the two files it was meant to land in, and the note bodies are copied verbatim into the close-out record before anything is removed. That check was itself rebuilt. As designed it searched two whole directories for a phrase, and would have reported success on a hit inside a frozen test fixture and on a hit inside this very plan quoting the search text back at itself. It now reads the two destination files by name — a form nothing but the actual codification can satisfy.

**Cross-references.** Stage-4 re-plan #4457 · Stage-5 design + reviews #4467 · Stage-6 sub-task #4470 · milestone #290. Governing standards: `core/standards/duplicate-source-discipline.md` § 1 (register-or-remove), `core/standards/date-variable-convention.md` § Emission-Time Anchors, `core/standards/bypass-mode-readiness.md` § Shakedown.

---

## Scope

### Summary

Ten members. The release's **capability outcome**: *a fact about a release is written once, by one writer, from a declared source — and every surface that restates it is a projection whose provenance is declared, asserted at emission, and gated at merge.*

The bundle is a **164 % size breach** (66 pts against a 25-pt band), operator-directed as a single bundle. Its operational consequences are carried in the Risk Register (R-6), not re-litigated here.

### Members

| # | Issue | Type | Size | Surface |
|---|-------|------|------|---------|
| 1 | **#4455** collapse four ledger writers into one projection | story | XL·16 | `core/deploy/tools/generate_release_index.py`, `core/deploy/tools/lint_release_corpus.py`, `core/deploy/deploy.sh`, `release/tools/automated-closeout.sh`, `release/references/standards/release-corpus-schema.md`, `release/references/pipeline/stage-13-close.md`, `core/governance/RECORDS_POLICY.md`, the four ledgers, one new ADR |
| 2 | **#3715** bound the release-corpus append-only logs | story | L·8 | `release/releases/RELEASE_LOG.md`, archive segments, `release/tools/sweep-release-corpus.py` (new), `RECORDS_POLICY.md`, `RECORDS_ARCHIVE_LOG.md`, `estimate-usage.sh`, `release-corpus-schema.md` |
| 3 | **#3387** governed retention-purge terminal decision | task | M·4 | `core/governance/RECORDS_POLICY.md` (+ conditional BUILD-branch surfaces) |
| 4 | **#3825** disambiguate the overloaded `domain` token | task | M·4 | `core/specs/domain-token-registry.md` (new) + 8 pointer surfaces |
| 5 | **#3196 ⊕ #4454** missing `template_family` families (merged work-package) | task | S·2 + L·8 | `core/standards/template-taxonomy.md`, `core/standards/template-storage.md`, `operations/templates/README.md`, the 12 templates |
| 6 | **#3290** template-registry hygiene drift (D1/D2/D3/D4) | task | L·8 | `template-protocol.md`, `operational-artifact-template-standard.md`, `template-taxonomy.md`, `operations/templates/README.md`, 26-file sweep, 3 `.skill` rebuilds |
| 7 | **#3413** external-target knowledge axis | — | L·8 | `core/disciplines/memory-architecture.md`, `core/disciplines/knowledge-architecture.md`, one new ADR |
| 8 | **#3556** codify the self-improving loop + backlog-hygiene guardrails | task | M·4 | `core/disciplines/architecture-overview.md`, `release/references/standards/bundle-composition-doctrine.md`; memory eviction post-merge |
| 9 | **#3816** agent-led execution in intake gates | task | M·4 | `gate-checklists.md`, `gate-definitions.md`, `intake-style-guide.md`, `packages/delivery-engine.skill` rebuild |

---

## Dependency Graph

```
#4455 ──► #3715          HARD — archiving a generated view is work the normalization unwinds
#4455 ──► #3387          HARD (added at re-plan) — the retention question dissolves for three of four ledgers
#3715 ──► #3387          read-ordering, retained but no longer the binding edge
#3825 ──► #3290 (D3)     registry must exist before the D3 sweep populates domain: declarations
#3196 ──► #3290          shared registry row in operations/templates/README.md
#3196/#3290 ──► #4454    #4454 extends the taxonomy surface they settle
#3413 ──► #3556          encode-then-evict; #3556's eviction is IRREVERSIBLE and gated on merge-to-main
```

**Broken edge, recorded:** `#3825 → (7 `domain: managed` templates)` **does not hold** — a disambiguation registry indexes concepts; it does not resolve a duplicate-YAML-key collision, and #3825's own AC-4 forbids the rename that would. Either #3825 closes it explicitly or #3290's D3 acceptance criterion is authored at **19 of 26**, not 26 (R-2).

**#3816 has zero edges in either direction.**

---

## Implementation Sequence

**P0 fully-serial. One branch, one PR, one merge gate.** Commit order; a card's rework cost grows with the number of commits behind it, so the architectural root goes first.

| # | Card | Why here |
|---|---|---|
| 1 | **#4455** | Architectural root. Everything downstream reads a corpus it reshapes. |
| 2 | **#3715** | Hard edge from #4455. Archives the **one** ledger that survives as an authoritative record. |
| 3 | **#3387** | Hard edge from #4455. Renders the terminal against the settled records taxonomy. |
| 4 | **#3825** | Vocabulary layer. Must close the 7-template key-collision gap or hand it an owner. |
| 5 | **#3196 ⊕ #4454** | Merged work-package — one edit region on `template-taxonomy.md` § 6. |
| 6 | **#3290** | D1 / D2 / D4 + the D3 sweep (19 of 26 with #4454 landed; 26 only if step 4 closes the collision). |
| 7 | **#3413** | Discipline layer. ADR number allocated at commit time, never hardcoded. |
| 8 | **#3556** | Corpus write lands here; **eviction is a distinct post-merge step**. |
| 9 | **#3816** | Independent tail. Zero contention; a late change here cannot force upstream rework. |

---

## Stage Applicability Matrix

| Card | Stage 5 Solutioning | Stage 6 Eng | Stage 7 Dev Testing | Stage 8 Acceptance |
|---|---|---|---|---|
| #4455 | **APPLIED — NEW spec** (#4467) | APPLY | **APPLY** | APPLY |
| #3715 | **APPLIED — RE-SPEC** (#4468) | APPLY | **APPLY** | APPLY |
| #3387 | REUSE #4393 + revalidate | APPLY | N/A (decision-only) | APPLY |
| #3825 | REUSE #4381 + key-collision decision | APPLY | N/A (doc-only) | APPLY |
| #3196 | REUSE #4405 | APPLY *(merged pkg)* | N/A | APPLY |
| #4454 | APPLY — NEW spec | APPLY *(merged pkg)* | N/A (taxonomy rows only) | APPLY |
| #3290 | REUSE #4409 + re-baseline D3 | APPLY | **APPLY** (3 `.skill` rebuilds + 26-file sweep) | APPLY |
| #3413 | REUSE #4397 + `repo_host` read-path correction | APPLY | N/A | APPLY |
| #3556 | REUSE #4401 | APPLY | N/A (doc-only) | APPLY |
| #3816 | REUSE #4385 | APPLY | **APPLY** (`delivery-engine.skill` rebuild) | APPLY |

---

## Contention Map

| Shared surface | Cards | Degree | Resolution |
|---|---|---|---|
| `core/standards/template-taxonomy.md` | #3825 × #3196 × #3290 × #4454 | FOUR-way | Steps 4 → 5 → 6; the #3196 ⊕ #4454 merge reduces it to three writers |
| `core/governance/RECORDS_POLICY.md` | #4455 × #3715 × #3387 | THREE-way | Steps 1 → 2 → 3. **#4455 writes the derived-surface rows first** (INT-4) |
| the four release-corpus ledgers | #4455 × #3715 | 2-way | Steps 1 → 2 |
| `release/tools/automated-closeout.sh` | #4455 × #3715 | 2-way | Step 1 replaces three phases' content synthesis; step 2 touches only the LOG path |
| `core/deploy/deploy.sh` | #4455 × #3715 | 2-way | Step 1's edit is **Check 23's remediation string only** (the limb-narrowing edit was withdrawn at Stage 5); step 2 adds its own warn probe |
| `release/references/standards/release-corpus-schema.md` | #4455 × #3715 | 2-way | Steps 1 → 2 |
| `core/standards/template-protocol.md` | #3825 × #3290 | 2-way | Steps 4 → 6 |
| `operations/templates/README.md` | #3196 × #3290 | 2-way | Steps 5 → 6 — the `qa-acceptance-report-template.md` row is **shared work, authored once** |
| `operations/templates/*.md` (26 files) | #3290 × #4454 × #3825 | 3-way | Steps 4 → 5 → 6 |
| `core/schemas/gate-criteria-spec.md` | #3825 × #3816 | 2-way, low | #3816's arm is a confirm-unaffected read, not an edit |

---

## Risk Register

| ID | Risk | Owner | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|
| **R-1** | The v4.05 Stage-13 close-out was in flight at plan time and writes all four ledgers. | #4455, #3715 | MODERATE / HIGH | **CLEARED.** PR #4466 (v4.05 Stage-13) merged; the branch was recreated from `origin/main` at that merge. Re-check the LOG state histogram at branch time rather than trusting a pinned reading (audit-baseline discipline). |
| **R-2** | The 7 `domain: managed` templates are **not** unblocked by #3825. | #3825, #3290, #4454 | CHEAP / HIGH | Close it at step 4, or author D3's AC at 19 and name the residual owner. Not both silent. |
| **R-3** | Hand-authored `Theme` cells are not derivable from the LOG. **Downgraded EXPENSIVE → MODERATE at Stage 5**: the projector already round-trips every non-placeholder Theme byte-identically (structural per-field probe; control returns a mismatch on a corrupted cell). | #4455 | MODERATE / HIGH | The Theme round-trip gains the integrity limb it has never had (AC-3). |
| **R-4** | Check 47 and most of Check 32 do **not** retire. **Confirmed and widened at Stage 5**: the census is **1 retires · 7 survive**, and the card's own census omits Check 48. | #4455 | CHEAP / HIGH | Per-contract verdict table recorded in the ADR (AC-6). The Stage-5 limb-narrowing proposal was **withdrawn in full**. |
| **R-5** | #3556's memory eviction is IRREVERSIBLE and not git-revertable. | #3556 | **IRREVERSIBLE** / HIGH | Eviction is the release's last action, after the corpus write is on `main`. |
| **R-6** | 164 % size breach with a four-way and a three-way contention edge, one merge gate. | bundle | MODERATE / HIGH | Deep Stage-9 depth; root at commit 1; zero-edge card at the tail. |
| **R-7** | Quota exhaustion — demonstrated, not hypothesised. Four spokes in the prior run died holding finished work. | bundle | MODERATE / MEDIUM | Split-batch mandatory at the Stage-8 wave; **push and post incrementally** at every spoke. |
| **R-8** | A `.skill` package rebuild is missed and Check 7 fires at merge. | #3816, #3290 | CHEAP / HIGH | `core/deploy/tools/build-skill-packages.sh <skill>` in the same commit as the source edit. |
| **R-9** | ADR-number collision — next-free is **global** across `core/ADRs/` and `release/ADRs/` plus anything in flight. | #4455, #3413 | CHEAP / HIGH | Allocate at commit time via `release/tools/check-adr-numbers.py`; never hardcode. |
| **R-10** | **Probe-shape defect recurrence.** Fourteen instances across this release, committed by every party including the hub. | all | CHEAP / HIGH | Every count is re-run at the working baseline and **paired with a control shaped like the probe**. Units stated. Populations verified. |
| **R-11** | #3715's re-scope is a genuine spec change, not an edit — its shipped design assumed four ledgers; the surviving design is one. | #3715 | CHEAP / HIGH | RE-SPEC, not REUSE. |
| **R-12** | **A whole-file regenerate of DIGEST or CHANGELOG is the one irreversible-shaped mistake available in this release** — it destroys ~100 entries of hand-authored prose recoverable only from git. A projector that acquires a clock is the second. | #4455 | MODERATE / HIGH | Both are guarded **by construction**, not by instruction: the emitters are entry-scoped and write to stdout; the projector's anchors are required CLI arguments and its clock-freedom is asserted by a self-test that CI executes. |

---

## Cross-Issue Acceptance Criteria

Release-scoped predicates spanning ≥ 2 issues. Graded at Stage 9 Phase A3.6 / QC3.5 on the merged PR.

- [ ] **CIAC-1 (#4455 × #3715 — the ledger set):** exactly one of the four release-corpus ledgers carries an archive-segment family; the three derived surfaces carry none. *Method:* `git ls-files 'release/releases/*_ARCHIVE-*.md' 'CHANGELOG_ARCHIVE-*.md' | sed 's/_ARCHIVE-.*//' | sort -u` returns exactly `release/releases/RELEASE_LOG`. *Baseline polarity:* 0 stems today. *Control:* the same transform over `git ls-tree -r --name-only f3cfdebf` returns 4 stems.
- [ ] **CIAC-2 (#3196 × #3290 × #4454 — the template registry):** every template in `operations/templates/` has exactly one registry row, and every `template_family` value binds to a family that exists in the taxonomy.
- [ ] **CIAC-3 (#4455 × #3715 × #3387 — `RECORDS_POLICY.md`):** all four release-corpus ledger paths are classified in the disposition table and no two cards state a contradictory disposition for the same path. *Method:* `grep -oE 'RELEASE_LOG\.md|RELEASE_INDEX\.md|RELEASE_DIGEST\.md|CHANGELOG\.md' core/governance/RECORDS_POLICY.md | sort -u | wc -l` returns **4**. *Baseline polarity:* **1** (only `RELEASE_LOG.md` is named). *Control:* the file's table-row count is non-zero, so a 0 would mean a broken probe rather than a clean corpus.
- [ ] **CIAC-4 (#3413 × #3556 — the memory↔corpus boundary):** no residual owned by either card exists in **both** the corpus and the operator memory store, and #3556's eviction is observably **after** the corpus write reaches `main`.
- [ ] **CIAC-5 (#3825 × #3290 × #4454 — the `domain` token):** every `domain:` declaration created by the D3 sweep resolves to exactly one concept row in the registry, and **no template carries two `domain:` keys**. Regression guard — true today and must stay true.

---

## File Change Matrix

*Card-1 (#4455) rows are authoritative as of Stage-6 Commit 0; downstream cards' rows carry the Stage-4 intent.*

| Card | Path | Intent |
|---|---|---|
| #4455 | `core/deploy/tools/generate_release_index.py` | **edit** — extend into the projector: note-frontmatter reader, three entry renderers, `--emit`, required `--merge-anchor` / `--closeout-anchor` / `--repo-slug`, `--verify all`, Theme-integrity limb, row-order limb, header preservation, self-test extension |
| #4455 | `core/deploy/tools/lint_release_corpus.py` | **edit** — retire sub-check (c) only; reserve the identifier; (a)/(b)/(d)/(e) untouched |
| #4455 | `core/deploy/deploy.sh` | **edit** — Check 23's remediation string only (the destructive-regenerate instruction). **The Stage-5 limb-narrowing edit is WITHDRAWN**; Checks 32/47/48 are untouched |
| #4455 | `release/tools/automated-closeout.sh` | **edit** — three phases call the projector; caller-side fail-closed on empty emission; `phase_assert_derived_surfaces` gains its presence limb; slug well-formedness gate; `phase_transition_release_log` **unchanged** |
| #4455 | `release/references/standards/release-corpus-schema.md` | **edit** — Derived-Surface Contract table |
| #4455 | `release/references/pipeline/stage-13-close.md` | **edit** — Phase B: one source write plus three projections; anchors table unchanged |
| #4455 | `core/governance/RECORDS_POLICY.md` | **edit** — **explicit `Important`-class rows** for INDEX / DIGEST / CHANGELOG with a never-regenerated-whole disposition (INT-4 operator decision; **not** `Reference`, **not** `Transient`) |
| #4455 | `release/releases/RELEASE_LOG.md` | **edit** — one cell: the `v3.69.1` `Release PR` reconciliation. No other historical row touched |
| #4455 | `release/releases/RELEASE_INDEX.md` | **edit** — provenance marker only; no row regenerated |
| #4455 | `release/releases/RELEASE_DIGEST.md` | **edit** — provenance marker only |
| #4455 | `CHANGELOG.md` | **edit** — provenance marker only |
| #4455 | `.github/workflows/node-graph-tools-selftest.yml` | **edit** — add the projector to the self-test roster (a regression guard nothing executes is documentation) |
| #4455 | `release/ADRs/ADR-NNN-release-corpus-normalization.md` | **add** — number allocated at commit time, global-monotonic across both ADR homes |
| #3715 | `release/tools/sweep-release-corpus.py` | **add** — port from the prior run's preserved branch minus the four-ledger loaders; heading-class carve-out; table-chronology ordering; destination-side `verify()`; `--self-test` |
| #3715 | `release/releases/RELEASE_LOG.md` | **edit** — 147 `#### Deployment Log` bodies relocate; every heading retained with a pointer; the 8-column table untouched; all 8 `#### Release Learnings` blocks untouched |
| #3715 | `release/releases/RELEASE_LOG_ARCHIVE-{v1,v2,v3,version-less}.md` | **add** — 4 segments, one per major release family, confirmed at sweep time from the live family partition |
| #3715 | `core/governance/RECORDS_POLICY.md` | **edit** — the `RELEASE_LOG.md` disposition cell admits a same-directory archive segment. **Does not touch #4455's three `Important` rows** |
| #3715 | `core/governance/RECORDS_ARCHIVE_LOG.md` | **edit** — one row for this sweep |
| #3715 | `core/skills/finops-usage-extractor/scripts/estimate-usage.sh` (+ `.skill` / `.sha256`) | **edit** — the Velocity basis reads the ledger *and* its sibling segments |
| #3715 | `release/references/standards/release-corpus-schema.md` | **edit** — § Archive Segments declares the type and the reader rule |
| #3715 | `core/deploy/deploy.sh` | **edit** — Check 65, warn-mode hot-ledger budget probe (the chore's trigger) |
| #3387 | `core/governance/RECORDS_POLICY.md` (+ `core/artifact-workflow-protocol.md`, `operations/skills/generated-cleanup/SKILL.md` on the BUILD branch only) | per #4393 |
| #3825 | `core/specs/domain-token-registry.md` (**add**) + 8 pointer surfaces | per #4381 |
| #3196 ⊕ #4454 | `core/standards/template-taxonomy.md`, `core/standards/template-storage.md`, `operations/templates/README.md`, the 12 templates | merged work-package |
| #3290 | `template-protocol.md`, `operational-artifact-template-standard.md`, `template-taxonomy.md`, `operations/templates/README.md`, 26-file sweep, 3 `.skill` + `.sha256` rebuilds | per #4409 |
| #3413 | `core/disciplines/memory-architecture.md`, `core/disciplines/knowledge-architecture.md`, `core/ADRs/ADR-109-external-target-knowledge-scope.md` (**add**) | per #4397, with the `repo_host` read-path premise corrected at Stage 6 (D-13). Number allocated at commit time against a contiguous `001..108` union with the release's own PR the only in-flight claim; the filename carries the spec's `-scope` slug, not the Stage-4 row's `-axis` placeholder |
| #3556 | `core/disciplines/architecture-overview.md`, `release/references/standards/bundle-composition-doctrine.md`; operator memory store (**delete**, post-merge, IRREVERSIBLE) | per #4401. The Stage-4 row's conditional `core/disciplines/operating-model.md` branch is **NOT taken** (declined at Solutioning on consumer mismatch), and the guardrails' home resolved to the doctrine — the row is reconciled to the shipped change set (D-21). The eviction is scheduled in § Operational Deployment Manifest and is **not performed at Engineering** |
| #3816 | `gate-checklists.md`, `gate-definitions.md`, `intake-style-guide.md`, `packages/delivery-engine.skill` (+ `.sha256`) | per #4385 |
| *(all)* | `release/releases/plans/governance-hardening_RELEASE_PLAN.md` | **add** — this file, slug-primary per ADR-092 |

---

## Domain Practice Provenance

```
domain_practice: { source: N/A — pipeline-internal, date: 2026-08-02, domain: governance }
```

No external practice is load-bearing for this release. The governing standards are in-corpus: `duplicate-source-discipline.md`, `date-variable-convention.md`, `bypass-mode-readiness.md`, `records-management` policy, `template-taxonomy.md`, `blast-radius-protocol.md`.

---

## Deviation Log

| # | Stage-4 position | Superseding position | Source |
|---|---|---|---|
| D-1 | "`RELEASE_LOG.md` becomes the sole authoritative record; the other three are generated from it" | **Two file sources plus two run-scoped inputs.** The LOG carries neither a `# ` headline nor a `summary:`; the DIGEST's date is the close-out anchor, not the note's; the CHANGELOG needs a repo slug that is in neither file. | Stage-5 design + Blocker revision + two adversarial reviews (#4467) |
| D-2 | "Check 23 retires or becomes an idempotence assert; Check 32 narrows" | **1 retires · 7 survive.** Check 32 and Check 48 **survive unchanged** — the limb-narrowing was withdrawn in full, because a stdout-emitting projector guarantees entry *correctness*, never file *presence*. Check 47 untouched. | Stage-5 A6.5 B-2 + Blocker revision (#4467) |
| D-3 | Check 23 flips `warn` → `enforce` | **The flip is STAGED, not asserted.** `deploy.sh` records the flip condition in the check's own terms (≥3-day warn-log review, zero false positives, ten-check shakedown precedent). Asserting it here would be unfalsifiable at merge time. | Stage-5 AC-4 repair (#4467) |
| D-4 | R-3 Theme loss classified **EXPENSIVE** | **MODERATE.** The projector already round-trips every non-placeholder Theme cell byte-identically; the residual is that nothing *checks* it, which this card closes. | Stage-5 E-2 (#4467) |
| D-5 | `RECORDS_POLICY.md`: "reclassify INDEX / DIGEST / CHANGELOG as **derived artifacts**" | **Explicit rows at class `Important` with a never-regenerated-whole disposition.** The classification independent review falsified the derived-artifact reclassification: those three files hold 317 sole-copy fields (278,791 B, 35.9 %) with no source in the LOG. `Reference` is defined as *supersedable by re-acquisition*, which they are not. | **INT-4 operator decision, 2026-08-02** |
| D-6 | Card body: "seven machine contracts … six become unnecessary" | **Falsified.** There are **eight** (the census omits Check 48) and **exactly one** retires. The issue body is preserved as historical record per ADR-062; the correction lands in the ADR. | Stage-5 D-7 (#4467) |
| D-7 | Card body: `release/tools/generate_release_index.py`, `release/tools/lint_release_corpus.py` | Both live under `core/deploy/tools/`. **A1.5 translation recorded; the issue body is NOT rewritten** (ADR-062 — the body is historical record). | Stage-5 Phase A1.5 (#4467) |
| D-8 | #3715 design: the sweep's window is "the newest N blocks", ordering left implicit | **Ordering is taken from the LOG table's chronology, never from block position in the file.** The exit re-review flagged the ordering as load-bearing and unstated — a tail-order reading of the same window yields a materially different hot file. Measurement went further than the finding: the file's blocks are only *broadly* newest-first and the two readings diverge in the interior (first divergence at block index 82 of 156), so *stating* the ordering would still have left the rule resting on a convention. Keying on the table removes the dependency instead of documenting it. Both readings select the identical set at this release's boundary (symmetric difference ∅), so no measured figure moves. | Stage-6, from the Stage-5 exit re-review Major 2 |
| D-9 | #3715 design: stub cost modelled at "heading line + a ~90 B pointer sentinel"; projected hot ledger **154,253 B** | **148,558 B measured.** The implemented sentinel is one line, ~51 B for a `v1`/`v2`/`v3` segment name against the model's 90 B, and the preceding card's LOG reconciliation removed a further 52 B. The projection was a *model*; this is the *measurement*. It moves further inside the target, not outside it: headroom against the 200,000 B budget is **51,442 B**, not the projected 45,747 B. Archived-block count (**147**), segment count (**4**) and family partition are unchanged. | Stage-6 measurement |
| D-10 | #3715 design: `estimate-usage.sh` is the one consumer that must follow its content | **Correct, and it is not the only body reader — the other two are dispositioned rather than absorbed.** `produce-learnings-register.sh` is closed by the Release-Learnings carve-out (no tool edit needed). `phase_inject_outcome_field` requires a `**Result:**` line inside a `#### Deployment Log` block and hard-FAILs without one; **145 of 156** blocks carry that line and Deployment-Log blocks *are* swept, so a retro `--outcome` invocation against an archived release now fails loudly. That is the A6.5 pass's **M-3**, carried into Stage 6 open by the design owner's explicit decision, and **not** self-resolved here. It fails loudly rather than degrading silently, which is the better failure; the cheap remedy is named in the Stage-6 output. | Stage-5 A6.5 M-3, carried |
| D-11 | #3825 Stage-5 spec (#4381): **"No new ADR opened"** — assessed as N-ADR-2 + N-ADR-3 | **ADR-107 authored.** The spec's assessment was correct for the scope it saw: it was written 2026-07-31 and the key-collision **decision** was added to this card at the Stage-4 re-plan gate on 2026-08-02, after the spec closed. Re-assessed against the authoring guide, **T-ADR-2 fires** — the decision binds a contract two other cards must honour (a provenance sweep must not write inline into the seven; the same sidecar carries `template_family`), and T-ADR-1's rejected alternative (permanent exemption) must survive as rationale or it is re-litigated. N-ADR-3 does not apply: the placement convention governs the CSV case, ADR-050 governs the rename question, neither governs slot occupancy. The registry §3 remains the AC-graded surface; the ADR is the record it indexes. | Stage-6, from the Stage-4 re-plan scope addition (#4457) |
| D-12 | #3825 Stage-5 spec (#4381) D-3825-3: concept-2 declaration count **26**, with the census stated to reconcile *"exactly against the live sweep"* at `1 + 26 + 0 + 0 + 11 + 9 = 44` | **Concept 2 is 23, and the spec's own sum is 47, not 44.** Re-derived at this card's baseline by classifying all 44 declarations: concept 1 = **1**, concept 2 = **23**, concepts 3 and 4 = **0**, concept 5 = **11**, concept 6 = **9**; 23 + 11 + 9 + 1 = **44** against the live sweep, negative control `zzdomain:` = 0. The **26** is this release's signature defect — a figure measuring a different quantity than the proposition needed: 26 is the count of *headerless templates* from a sibling card, not of concept-2 declarations. **No design consequence**, and that is by construction: the same D-decision that carried the wrong number also ruled that the registry states **no count in prose**, so the error had no surface to propagate onto. Recorded because a number presented as reconciling, which does not, is the class of defect this release is about. | Stage-6 re-derivation |
| D-13 | #3413 Stage-5 spec (#4397): the read contract *"goes through the active `operator.toml [adapters].repo_host` adapter, per `repo-host-adapter-versioning.md`"* | **The cited interface cannot perform the read, and the spec is corrected rather than followed.** That standard specifies exactly **four** operations — `anchor()` / `claimed_set()` / `atomic_claim()` / `lineage()` — all scoped to version-claiming; they return versions and claim outcomes, never a referent. Re-derived at this card's baseline: the file returns **0** hits for `label\|milestone\|issue state\|referent` against a positive control of **44** hits for the four operation names, so the probe form resolves. §7.1 therefore states **three requirements on the read** (fresh at every use · through the host surface the `[adapters]` selector table names · nothing retained) and records the absent referent-read operation as a **named gap** owned by the adapter-interface work. **The selector half of the design survives** — which host is active is still `[adapters]`, and the address is still `[trackers.<id>].identifier`; only the delegation to a non-existent operation is withdrawn. Citing an interface that would not satisfy the read is the exact failure this card exists to remove. | Stage-4 re-plan (#4457) adversarial finding, re-derived and executed at Stage 6 |
| D-14 | #3413 Stage-5 spec (#4397): §7 subtree carries *"**8** external inbound pointers across **4** files"* in its table, and *"the **10** inbound pointers"* twice in its prose | **Nine, across four files** — and the spec was internally inconsistent before the corpus moved. Re-derived at this card's baseline by resolving each hit rather than counting grep lines: `#memory-corpus-boundary` **5** (memory-architecture ×3, stage-13-close ×1, memory-corpus-drift-audit ×1) · `#no-shadow-ssot` **2** (memory-architecture ×1, ADR-045 ×1 — a third raw hit is memory-architecture's **own** anchor definition, not an inbound pointer) · `#encode-and-evict` **1** · `#trigger-and-audit` **1**, which the spec's table omits entirely · `#drift-classes` **0** · `#two-tier-ssot` **0**. **No design consequence** — the figure supports the extend-over-create placement, and 9 supports it as well as 8 or 10. Recorded because a raw grep count over anchor strings silently includes the anchor's own definition line, which is the release's signature probe defect one surface over. | Stage-6 re-derivation |
| D-15 | #3413 change set: two files plus one ADR, additive only | **Seven in-file reconciliations travel with the `memory-architecture.md` edit.** Five citations read `knowledge-architecture.md §6` while linking to anchors that live in **§7** (the boundary was §6 before an intervening section was inserted), and two of those five also said *"the three drift classes"* where the corpus now carries **five**. Post-edit probe: `knowledge-architecture.md §6` → **0** residual, `§7` → **8**; `three drift classes` → **0**, `five drift classes` → **2**. Taken because the new §6 bullet cites §7.1 and would otherwise sit one bullet from a bullet miscounting the same file — reconcile-don't-annotate on a surface already open. **ADR-045 carries the same stale `§6` citation and is deliberately NOT touched** (immutable decision record, outside the change set); it is recorded as out-of-scope drift instead. | Stage-6, reconcile-don't-annotate |
| D-16 | #3556 Stage-5 spec (#4401) D-6 / Change 3a: `VERIFY-CORPUS` limb A is *"`grep -rln "self-improving loop" core/ release/` → ≥1 **authored** file (exclude `release/tools/tests/` by path)"*, asserted as *"the atomicity gate and AC-1 cannot disagree"* | **The gate on this release's only IRREVERSIBLE action false-passed, and is rebuilt at its shape rather than its threshold.** Re-derived at this card's baseline, a fourth independent reproduction: the unanchored form returns **2** files — the release plan (a row naming the card's own title) and a frozen test fixture — while the destination file contained **0** occurrences. Controls: `encode-then-evict` → **7** files and `self-referential` → **14**, so the two hits are real hits and not a broken pattern. Three limbs each sufficient on its own: the authored heading is title-cased and the probe is case-sensitive; `release/releases/plans/` sits **inside** the probe's own scan scope and the manifest quotes the probe text; and the stated exclusion names `release/tools/tests/`, which is not that path. Both limbs are now **anchored to the destination file the change writes to**, which deletes the failure class rather than patching it — a file-anchored count cannot be satisfied by a plan or a fixture and needs **no path-exclusion clause at all**. The card's corpus-wide acceptance method survives as a **secondary single-home check** in a self-excluding form (`--exclude-dir=tests --exclude-dir=plans`) that drops both self-authored surfaces *inside the command*, so quoting it cannot satisfy it. | Adversarial design review #4423 **PR-1** (Blocker), operator-dispositioned fix-in-place; re-derived at Stage 6 rather than transcribed |
| D-17 | #3556 Stage-5 spec (#4401): limb B stated as `grep -n "Backlog-Retention Guardrails" … → **1**` in D-6 and as `→ **≥1**` in Change 3a | **One stated form (`≥ 1`), and both limbs computed against the landed change set rather than asserted.** The change writes that string **twice** — the § 12 heading and the § 14 version-history row — so the strict `→ 1` is falsified by the design's own text and, read literally under `iff (A AND B)`, would have held **both** evictions: the opposite failure direction to D-16, inside the same predicate. Landed values recorded in the manifest: limb A = **1**, limb B = **2**. | Adversarial design review #4423 **PR-5**, carried in the same Tier-1 `[ADJUST]` |
| D-18 | #3556 Stage-5 spec (#4401) § Date Variable: **`${DOC_DATE_UTC}`**, 2 load-bearing positions | **`${AUDIT_DATE_UTC}`.** Re-derived at this card's baseline: `DOC_DATE_UTC` resolves in **0** files repo-wide; `AUDIT_DATE_UTC` resolves in **18** and is normative at `core/standards/date-variable-convention.md` § Variable schema, which states the Stage-5 spec **MUST** use it. Resolved `${AUDIT_DATE_UTC}` = **2026-08-03** (Monday, day-of-week validated) via `date -u +%Y-%m-%d` at this card's first commit, substituted at both positions — the doctrine's `last-updated:` field and its § 14 version-history Date cell. Hardcoding a date into the fix for a staleness defect would have reintroduced the defect. | Adversarial design review #4423 **PR-2**; the standard names Collective Review as the flagging surface for exactly this violation |
| D-19 | #3556 Stage-5 spec (#4401) Canonicalization 1: *"`RECORDS_POLICY.md` § Retention Schedule establish **retention** as the corpus's word for what is kept and on what basis"*; and BRG-2's stated reason, *"the platform's zombie vocabulary … keys on something else **entirely** … an artifact-lifecycle term"* | **Both groundings are false and are replaced in shipped text, after running for all four terms the survey the spec ran only for the term it rejected.** (a) `core/governance/RECORDS_POLICY.md:70` defines *retention* as a **preservation floor** — *"the **minimum** the record is preserved before it is *eligible* for disposition"*, keyed by record type, disposition never destruction. That is a period, not a restraint on a removal recommendation. (b) `operations/skills/delivery-engine/references/backlog-health.md:154` (§ 7 Anti-Patterns, "Backlog as graveyard") uses *zombie* for **backlog work items** — *"quarterly zombie hunts; enforce aging thresholds"* — in the very file BRG-1 names one rule earlier as its altitude counterparty. Re-survey over the authored corpus with controls: `retention` **37** files · `retirement` **28** · `zombie` **15** · `aspirational` **16**; present-term control **18**, absent-term control **0**. **Every candidate name is occupied**, so a rename relocates the collision rather than resolving it — and the literal is both the Peer-Spec Concept Ownership index key and limb B's anchor. Disposition: keep the compound name; § 12 carries a **two-neighbour** disambiguation clause covering both live collisions, BRG-2 names both live senses of *zombie* and states why neither licenses the label, and the Peer-Spec row carries the same two-neighbour distinction. The rules never depended on the wrong claims — but a false grounding in shipped text outlives the release. | Adversarial design review #4423 **PR-3** / **PR-4** (Major), operator-dispositioned *fix the rationale or re-canonicalize*; re-surveyed, then fixed in place |
| D-20 | #3556 Stage-5 spec (#4401) Change 3a: Phase B-OPS5 absorption reconciliation, inherited on its default subject | **The diff basis is bound explicitly in the manifest entry.** `stage-13-close.md` B-OPS5 scopes its stranded-set diff to *"every memory naming **that issue**"*, where *that issue* is the closing issue. #3556's two residual memories name the **originating** v3.76 codification issue, not #3556 — so on its default subject the gate computes an empty naming set and **passes vacuously**, structurally unable to detect the condition this card remediates. The manifest names the alternate basis at the point of execution. The general form (a remediation issue inherits the originating issue's naming set) is **not** absorbed — scope is locked — and is routed as an observation. | Adversarial design review #4423 **FM-2**, mitigation (a) |
| D-21 | #3556 Stage-4 row: `core/disciplines/architecture-overview.md` **(+ conditional `core/disciplines/operating-model.md`)** | **The conditional branch is NOT taken, and the second home is the doctrine — the § File Change Matrix and § Scope Members rows are reconciled to the shipped change set.** `operating-model.md` was declined at Solutioning on consumer mismatch (its declared subject is the *within-pipeline* composition view; its `consumers:` name the skill-build waves, Stage 6/7 and pmo-qa-auditor Mode B — no backlog-judging or vision-reading consumer), and placing vision content there would have produced exactly the scatter the card's own risk register warns about. The guardrails landed in `release/references/standards/bundle-composition-doctrine.md` § 12, which neither row named. A change matrix that omits a file the change writes is a Stage-9 defect, so the rows are fixed rather than annotated. | Stage-6, reconcile-don't-annotate |
| D-22 | #3556 reference implementation (the prior run's preserved branch, `4723c24c`): the loop section's routing sentence reads *"it routes through the same **13 stages** as any other backlog item"*, and its opening paragraph claims the loop is *"the reason the platform's own tooling is the pipeline's **most frequent input**"* | **Two inherited imprecisions corrected rather than carried, on a surface whose whole purpose is being citable.** (a) The sentence it paraphrases — `release/governance/release-process.md` § Pipeline Self-Governance — says *"routes through the same **stages**"*, and the same file records at `:29` that *"the 13-stage reference model compresses to **~10 operational stages** for git-native releases."* Stating a count the cited source itself qualifies converts a faithful citation into a claim the source does not make; the shipped text says *"the same stages"*. (b) *"Most frequent input"* is a superlative with no measurement behind it, and in this repository it is a tautology wearing an empirical costume — every item in the platform's own backlog is about the platform. Replaced by the structural claim it was standing in for: *"the platform's own use is a first-class source of its own backlog."* Reuse of a preserved reference implementation is a capacity lever, not a licence to inherit its claims unchecked. | Stage-6 re-derivation |

---

## Rollback

| Surface | What `git revert -m 1` of the release PR restores | What it does **not** restore |
|---|---|---|
| Tooling + corpus text (steps 1, 3–7, 9) | Everything. No data migration, no consumer state. **CHEAP / HIGH.** | — |
| #3715 archive segments | Full byte content — the sweep is move-only and git preserves both sides. **CHEAP / HIGH.** | — |
| #4455 derived-surface provenance | The files' **bytes**. | **Not the provenance.** A reverted repo's next close-out writes by the old four-writer path, and anything authored into a derived surface between merge and revert is regenerated away rather than conflict-flagged. Mitigated by D-8: no history is regenerated, so the revert surface is one LOG cell plus tooling. **MODERATE / HIGH.** |
| #3556 memory eviction | **Nothing** — the eviction is outside git. | The evicted memory. **IRREVERSIBLE / HIGH.** Gated on the corpus write being merged to `main`; executed as the release's last action. See § Operational Deployment Manifest. |

---

## Tier-A activated design artifacts

Read by Stage-13 `G-CL6` (design-artifact refresh-gate verification).

| Issue | Artifact | Flow class | Tier | Trigger | Storage |
|---|---|---|---|---|---|
| #3556 | `core/disciplines/architecture-overview.md` § The Self-Improving Loop | concept model | Tier-A (new) | `design-artifact-standard.md` § 7 Tier-A row 4 — a new architectural concept named in a governance file | embedded (centralization-test: 1 parent doc, below the 3-doc threshold) |

**Negative determination, recorded so the asymmetry reads as a decision.** The § 12 guardrails do **not** activate Tier-A: they add normative rules to an existing standard and introduce no new entity, relationship, actor, flow, or state, so there is no concept model to render. The three comparable post-`v11.28` normative additions to that same doctrine each introduced a new construct and none declared a design artifact.

---

## Operational Deployment Manifest — #3556 (memory eviction)

**Entry set:** 2 operator-memory files + their memory-index lines. **Atomic — see `EVICT-ATOMIC`.**
**Mechanism:** the encode-and-evict lifecycle at [`knowledge-architecture.md` § 7](../../../core/disciplines/knowledge-architecture.md) (ARCHIVE → VERIFY-CORPUS → EVICT → RE-POINT). No new mechanism is introduced; this manifest supplies **entries**.
**Executor:** Stage-13 Phase B-OPS, under operator authorization, gated by `G-CL5`. **Never Stage 6** — no step in this release's Engineering reads or writes the memory store.

### VERIFY-CORPUS — rebuilt at Stage 6, path-anchored on both limbs

> **The Stage-5 form of this gate false-passed and was rebuilt under the Tier-1 `[ADJUST]` amendment (D-16).** It was specified as an unanchored recursive search over `core/ release/` for a lowercase literal, qualified *in prose* as "an authored file, not a test fixture". Run verbatim at this card's pre-change baseline it returned **two** hits — a frozen test fixture and **this release plan**, whose own row names the card's title — so the gate would have greenlit an **irreversible** eviction while the destination file contained nothing. Three independent limbs each caused this: the authored heading is title-cased and the search was case-sensitive; `release/releases/plans/` lives inside the searched tree and the manifest quotes the search text, so the probe could match its own specification; and the stated fixture exclusion named a different path than the plan's. Reproduced independently by four agents with no shared memory.

Both limbs are now **anchored to the destination file the change writes to**. A corpus-wide hit count is not evidence that the intended file was written. Both limbs carry the **same stated form** (`≥ 1`), and both were **computed against the landed change set** rather than asserted — the Stage-5 spec stated one limb as `→ 1` in its design body and `→ ≥ 1` in its manifest, and the strict form is falsified by the design's own text (D-17).

| # | Memory surface | Codified to | VERIFY-CORPUS probe (from the repo root, against `origin/main`) | Required | Landed value |
|---|---|---|---|---|---|
| 1 | the platform-vision memory file + its memory-index line | `core/disciplines/architecture-overview.md` § The Self-Improving Loop | `grep -c "The Self-Improving Loop" core/disciplines/architecture-overview.md` | **≥ 1** | **1** |
| 2 | the product-vision memory file + its memory-index line | `release/references/standards/bundle-composition-doctrine.md` § 12 | `grep -c "Backlog-Retention Guardrails" release/references/standards/bundle-composition-doctrine.md` | **≥ 1** | **2** (§ 12 heading + § 14 version-history row) |

**Why file-anchoring is the fix and not merely a tightening.** A file-anchored count cannot be satisfied by a release plan, cannot be satisfied by a test fixture, and needs **no path-exclusion clause at all** — the exclusion rule that the false-pass defeated simply disappears. The failure mode was the gate's *shape*, not its threshold.

**Secondary check — single-home confirmation (AC-1 / AC-5, not the eviction gate).** The card's own acceptance method searches the corpus rather than a file. Run it in the self-excluding form below, which removes the two surfaces this release itself authors **inside the command**, so quoting the command anywhere cannot satisfy it:

```
grep -rln --exclude-dir=tests --exclude-dir=plans "self-improving loop" core/ release/
```

Required result: **exactly** `core/disciplines/architecture-overview.md`. Verified at Stage 6 in both the case-sensitive and case-insensitive forms — one lowercase occurrence of the literal is authored into the section body precisely so the card's stated case-sensitive method resolves as written; the title-cased heading alone would not have. At the pre-change baseline this command returns **no hits and exits 1**, so it now **fails closed**; control: the identical flags on an established corpus phrase return non-zero.

### `EVICT-ATOMIC`

The two entries are **ONE atomic set**. Both VERIFY-CORPUS limbs must pass before **either** entry proceeds to EVICT. On a partial pass: **evict neither**, mark the entry `HELD — partial corpus landing`, and re-home the unabsorbed residual per Phase B-OPS5 rather than leaving it stranded. Rationale: the shipped lifecycle's VERIFY-CORPUS gate is **per memory file**, so two independent passes can both succeed while only one residual is codified — which is the split-brain state this issue exists to close.

### `EVICT-GATE` (all three limbs required, in order)

1. `gh pr view <release-pr> --json state,mergeCommit` → `state == MERGED`, non-null merge SHA.
2. `git merge-base --is-ancestor <mergeCommit> origin/main` → exit 0.
3. `EVICT-ATOMIC` holds, evaluated against `origin/main` at that SHA — **never** a worktree, and never a branch commit.

**A branch commit never satisfies this.** Reverting the release PR restores every in-repo change but does **not** restore an evicted memory (risks **R-5** / **R-12**).

### Scope of the eviction — what this manifest does and does not authorize

**Authorized, and only this:** the two memory entries above, each bound to **its own** corpus write in the table. The eviction binds to #3556's codification, never to a sibling card's and never to the release in aggregate — #3413's Stage-6 output records, and the hub independently re-verified, that #3413 encodes **neither** of these two residuals.

**Not authorized by this manifest** (recorded explicitly, because an omission here reads as permission and the action cannot be undone): any memory holding a target repository's **address** (retained by decision under #3413 — move it to configuration, never delete it); any memory holding **operator-side practice** about a target (routed to normal homing under #3413; stays memory-SSOT); and any memory whose content is **not** demonstrably present in one of the two destination files named above.

### ARCHIVE — runs first, before any deletion

Paste both memory-file bodies and both memory-index lines verbatim into the Stage-13 sub-task comment. This is the recoverability control; the revert is not. Eviction reversibility: **IRREVERSIBLE by git** (the store is outside the repository) / **CHEAP by ARCHIVE + Trash** (the lifecycle moves files to Trash, not `rm`).

### Post-state verification and RE-POINT

File-absence + index-line-absence for both entries; then RE-POINT any surviving memory that references either evicted file to its corpus home (the home is already in hand from VERIFY-CORPUS).

### Phase B-OPS5 — diff basis bound explicitly for this entry

`stage-13-close.md` B-OPS5 scopes its stranded-set diff to *"every memory naming **that issue**"*, where *that issue* is the closing issue. **These two residual memories name the originating v3.76 codification issue, not #3556** — so B-OPS5 evaluated on its default subject computes an empty naming set and passes vacuously, structurally unable to detect the exact condition this card remediates.

> **B-OPS5 diff basis for this entry = the originating `knowledge-corpus-hygiene` (v3.76) codification issue and its milestone — not the closing issue.** Confirm at close that no memory naming that originating issue remains unabsorbed.

The general form — a remediation issue inherits the originating issue's naming set — is **not** absorbed here (scope is locked); it is routed as an observation (D-20).

**AC-6 is recorded here** and restated in the #3556 resolution comment: the encode-then-evict contract left blocked by the v3.76 close-out is discharged by these two entries.

---

## Identity Note (ADR-092)

This plan is **slug-primary**. Every version reference is the literal token `{{RELEASE_VERSION}}`. At the **Stage-12 atomic claim** the version number binds, this file is renamed to `<version>_RELEASE_PLAN.md`, and the token is resolved in the same commit. Any hardcoded version in this plan or in this release's authored files is a defect.
