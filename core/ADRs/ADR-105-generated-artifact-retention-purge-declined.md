---
title: "ADR-105 — Archive is the permanent terminal for generated artifacts; a retention-windowed purge is declined"
status: Accepted — rendered by the operator at the Stage 5 Collective Review for the governance-hardening release, 2026-07-31 (Friday). Ratifies never-delete-archive as the permanent terminal for `domain: generated` artifacts and declines the build branch.
date: 2026-07-31
release: governance-hardening (version bound at Stage 12)
deciders: "operator (Stage 5 Collective Review decision gate — the fork was reserved to the operator by the evaluation's own terms) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 independent adversarial design reviewer"
tags: [records-management, retention, disposition, generated-artifacts, never-delete, archive-terminal, iso-15489, least-destructive-disposition, re-open-triggers, declined-mechanism, reversibility-moderate]
source_observations:
  - "PURGE-SCOPE PREDICATE IS NOT COMPUTABLE. Command: `grep -rl <field> <operations-workspace> | wc -l` for each of `promotion_state`, `lifecycle_changed`, `archived-in-place`. Observed: 0, 0, 0. Controls proving the sweep reaches the tree and does not match indiscriminately: `created` 883, the legacy `artifact_type` 52, `lifecycle_state` 5, an impossible string 0. Baseline: operations workspace as measured 2026-07-31 at repo commit c4dde614. FALSIFIER: any later sweep returning a non-zero `promotion_state` population — at which point the eligibility conjuncts become evaluable and precondition T-C(i) is on its way to satisfied. VERIFICATION SCOPE: this measurement is taken in the operations workspace, which is outside this repository (git-ignored Layer 2). It is NOT verifiable from the repo and is recorded as the design spoke measured it; the reviewing spoke and the hub each recorded the same qualifier rather than dropping it."
  - "RECLAIM IS NEGLIGIBLE AND ACCRETION HAD STALLED. Command: `find <operations-workspace> -path '*08-Generated*_archived*' -type f | wc -l`, the same with `-exec cat {} + | wc -c`, and `du -sk <operations-workspace>`. Observed: 42 archived files / 1,113,189 bytes against a workspace total of 1,522,892 KB — 0.07 percent. Control proving the path pattern discriminates: 509 non-archived siblings, and 42 + 509 reconciles to the 551 total. Modification-time census: 14 in 2026-03, 28 in 2026-04, none in the three months to the measurement date. Baseline: 2026-07-31 at repo commit c4dde614. FALSIFIER: trigger T-A below — the same population re-measured above 100 MiB or above 5,000 files. VERIFICATION SCOPE: operations workspace, outside this repository; not verifiable from the repo; recorded as measured."
  - "THE DISPOSITION LEDGER THE GATE WOULD READ IS UNWIRED. Command: read `core/governance/RECORDS_ARCHIVE_LOG.md`, then `grep -rIn --include='*.sh' --include='*.py' 'RECORDS_ARCHIVE_LOG' .`. Observed: the table's only row is the literal seeded-empty placeholder, and executable writers number 0. Control proving a wired log looks different under the identical command form: the pipeline event log returns a double-digit executable-hit count. Yet at least 42 archival moves demonstrably occurred, so the policy's every-move-is-logged rule is presently unenforced. Baseline: repo commit fe743fe7, re-confirmed at authoring. FALSIFIER: a non-zero writer count under the same grep."
  - "NO POST-ARCHIVE DESTRUCTION CLOCK EXISTS — N=0, stated in its narrow and correct form. Command (structural column census, NOT a value-alternation grep): `awk -F'|' 'NR>=71 && NR<=90 && NF>4 {print $4\" -> \"$5}' core/governance/RECORDS_POLICY.md`. Observed: 14 data rows; every retention period is either a preservation floor (Permanent, at-least-three-years, project-lifetime-plus-one-year) or a pre-disposition eligibility clock (ten business days, until-graduated-or-expired); zero are clocks after which a record is destroyed. The census DOES surface one destruction disposition — the external-reference row's discard-if-superseded-externally, an operator call at project close keyed on external supersession, not a clock — which is why the claim is scoped to clocks rather than to destruction generally. Control demonstrating why the structural form was chosen: the value-alternation grep the design spec proposed returns 12 by construction, missing the discard row and one other whose wording differs from the four variants it hardcodes; re-running it later reads unchanged regardless of what was added. Baseline: repo commit fe743fe7. FALSIFIER: any row in that column pair stating a duration after which a record is destroyed."
  - "THE PURGE-PRECEDENT CENSUS, CLASSIFIED RATHER THAN COUNTED. Command: `grep -rIn --include='*.md' --include='*.sh' --include='*.py' --include='*.toml' -iE '\\b(hard[- ]?delete|purge|destruction clock|retention[- ]purge)\\b' core/ operations/ release/ docs/`. Raw observation at repo commit fe743fe7: 25 hits across 12 files, having been 21 across 11 at commit c4dde614 — the growth is entirely this evaluation's own release plan naming its subject, which is the direct demonstration that a raw hit count is not a measurement of the corpus. Classification of the 25: 8 assert never-delete; 9 are one tool counted across three files; 5 are this evaluation's own paperwork; 1 is a historical memory-deletion note; 1 is a declared-but-unwired terminal; 1 is a different-sense match. Surviving genuine terminals after applying the same wiring test the platform applies to its own ledger: ONE. FALSIFIER: a second executable that performs a records-disposition destruction on governed artifacts."
  - "TRIGGER T-A HAS NO AUTOMATED EVALUATOR, AND THAT IS RECORDED RATHER THAN PAPERED OVER. Command: `grep -rIln --include='*.sh' --include='*.py' -E '_archived' .` and a follow-up for size or count operations over that path. Observed: one file mentions the path at all, and zero executables perform a size or count measurement over it. Control proving the probe reaches: three shell/python files in the repo do perform size measurement elsewhere. Baseline: repo commit fe743fe7. This is why the trigger table below names an owner and a cadence explicitly: a reversal condition with no evaluator is not a reversal condition."
---
<!-- reference-durability: allow-link -->

# ADR-105 — Archive is the permanent terminal for generated artifacts; a retention-windowed purge is declined

## Status

**Accepted** — the operator rendered RATIFY at the Stage 5 Collective Review for the `governance-hardening` release on 2026-07-31 (Friday). The record was authored at Stage 6 on 2026-08-01 (Saturday).

*Numbering provenance.* The number was allocated at Engineering commit time, not at design time: the ADR-numbering checker reported a contiguous sequence topping at 104 across both ADR directories at the authoring commit, and no in-flight pull request carried a competing claim. Per the merge-time claim rule the ADR indexes record, a number is allocated at authorship but **claimed at merge**, so this record is referenced everywhere by its **slug** (`generated-artifact-retention-purge-declined`) and never by its integer. If a sibling merges ahead of it, the file renumbers and the references do not move.

## Context

The generated-artifact lifecycle terminates at **archive-before-delete**: an unreviewed staged artifact ages out into an in-tree `_archived/` segment, and a promoted artifact is flipped to an archived content state in place. Neither terminal deletes. A prior release built that cadence and **deliberately omitted** a hard-delete step; at that release's review gate the operator declined to ratify never-delete-as-the-terminal and instead opened a governed evaluation of whether a retention-windowed purge — a retention window plus an explicit operator sign-off gate, hard-deleting only archived-past-retention generated artifacts — was warranted.

This record is the outcome of that evaluation. It is the **second** adjudication of the same doctrine. The first produced no durable record of its reasoning, which is precisely why the question returned; not writing this record would guarantee a third cycle.

### The card's warrant does not survive, and correcting it strengthens the decision

The evaluation was framed as though a purge terminal would depart from platform doctrine. It would not, and saying so plainly matters more than defending the doctrine — because "we never delete" is the argument a reader would apply in six months, and it is the argument that would not survive them checking.

What survives a **classified** probe, rather than a counted one, is **one wired terminal, one declared-but-unwired, and one different-sense match**:

- **Wired (one).** The analysis-workspace staleness scan offers a per-item interactive archive / purge / skip choice, where purge moves the item to the operating system's trash rather than unlinking it. It has no non-interactive mutation path, ships no continuous-integration gate because the workspace it scans is not tracked, and degrades to a user-side handoff when the trash utility is unavailable. This is a genuine precedent and the only one.
- **Declared but unwired (one).** A communications-archive state in the operations governance file declares an automatic purge after a stated number of business days. The declaring string occurs exactly once in the corpus and has **zero executable writers**. Held to the same wiring test this platform applies to its own disposition ledger — which it correctly calls declared-but-unenforced on identical evidence — this is a declaration, not a terminal.
- **A different sense of the word (one).** A secrets-handling row instructs an operator to purge credential entries as part of a rotation procedure. That is credential hygiene, not records disposition over governed artifacts.

**A single genuine precedent is weaker ground for "building one would be routine" than three would be.** The correction therefore makes the decision below *easier* to defend, not harder — and recording the over-claim's replacement here, rather than the over-claim itself, is the point: this record is immutable, so an error in it cannot be edited out.

**One durability lesson is recorded with it.** The raw probe count moved between the design baseline and this authoring baseline **because this evaluation's own release plan names its subject four times**. A count a card's own paperwork inflates is not evidence about the corpus. The classification above, and the wiring test that produces it, are what this record commits to — never the hit count.

### The three measured facts the decision rests on

1. **The purge-scope predicate is not computable.** "Archived-past-retention" needs an archival timestamp. The only governed carriers of one are stamped on **no** live artifact, against controls in the high hundreds proving the sweep reaches the population. The eligibility set is empty for the entire live population, so a mechanism built to the card's own scope would select nothing.
2. **The retention constant cannot be grounded.** The corpus's retention values are, without exception, either preservation floors or clocks that make a record *eligible for a move*. A destruction clock would be the platform's first, and the evidence-grounding standard rejects a canonicalization whose current-state enumeration returns fewer than two sources. This is a **methodological** result, not a preference — and it is stated in its narrow, survivable form: N=0 holds for post-archive destruction **clocks**, not for destruction generally. The corpus does carry one destruction disposition, an operator call at project close for external reference material superseded at its source, and the census command recorded in this file's grounding block is the **structural** one that finds it rather than the value-alternation grep that cannot.
3. **The reclaim is a rounding error.** The archived generated population measured well under one percent of the operations workspace, and nothing had been archived into it for a quarter at the time of measurement.

**Scope of verification, stated rather than implied.** Facts 1 and 3 are measurements of the operations workspace, which lives outside this repository and is not tracked. **They are not verifiable from the repo.** They are recorded as the design spoke measured them, with the same qualifier the reviewing spoke and the release hub each attached rather than dropped. Fact 2, the precedent census, the ledger's wiring state, and the trigger-evaluator probe are all in-repo and re-runnable — their commands are in this file's grounding block and in § Consequences.

## Decision

**Archive is the permanent terminal for `domain: generated` artifacts. No retention-windowed purge is built.**

Four conditions are named below under which this answer re-opens. Each is an **observable predicate with a named evaluator and a stated cadence** — a reversal condition nobody evaluates is not a reversal condition, and the reversibility tier this record claims depends on the triggers being real.

### No artifact class becomes purgeable

This decision introduces **no** purgeability anywhere. It therefore composes with any concurrent amendment that widens a retention row or names a same-directory archive segment as a disposition destination: **moving** bytes from a live file into an archive segment beside it is a move, and moves are what the disposition stance already permits. It is not a destruction, and this record does not make it one.

The consequence is an invariant a reader can check after any such amendment lands: **no artifact class reads as both never-deleted and purgeable**, because under this decision none reads as purgeable at all. No carve sentence is required, because there is nothing to carve around.

### Re-open triggers

Any one of **T-A / T-B / T-D** re-opens the question. **T-C is a precondition on building, not an independent trigger** — until it holds, the build branch is not specifiable no matter which other trigger fired.

| ID | Trigger | Observable predicate | Evaluator | Cadence | Basis |
|---|---|---|---|---|---|
| **T-A** | Volume | Size or file count over the archived-generated segments — the legacy `08-Generated/**/_archived/` and the successor `**/_generated/_archived/`, as a union — exceeds **100 MiB** or **5,000 files** on any operator instance. | The **workspace owner**, in the `operator-class` role the records policy already declares as its owner. The predicate is a records-disposition question over a records population, so it inherits that owner rather than minting a new one. | **Quarterly**, aligned with the quarterly rhythm the records policy already runs for its other age-out sweep. | Set at roughly one hundred times the measured state on both axes, so the trigger fires well before the population is operationally material and well above accretion noise. Two axes because the failure shapes differ — a few large exports versus many small reports — and either axis alone would miss the other. Deliberately not derived from an existing platform constant: none governs an archive-population size, so borrowing one would be false precision. |
| **T-B** | Regulatory | A regulatory regime attaches that owes a mandated destruction clock. | Externally event-driven — the regime's attachment **is** the observation; no polling is required. Routed to the **workspace owner** for the amendment. | On attachment. | **Inherited verbatim, not minted.** The records policy and its founding decision record already name this exact trigger and its amendment path; this record adopts it rather than creating a second one that could drift from it. |
| **T-C** | Substrate readiness (**precondition on building**) | All three: (i) the archival-location field is stamped on at least 90 percent of the live generated population; (ii) the disposition archive log has at least one executable writer **and** a non-empty table; (iii) the records classification table carries an **explicit** row for a post-sweep archived artifact rather than resolving it through the default. | (i) the **workspace owner**, same population and same occasion as T-A. (ii) and (iii) are **in-repo and reader-checkable** — any contributor, review, or continuous-integration job can evaluate them from the tracked corpus with no operator ritual. | (i) quarterly, with T-A. (ii)/(iii) on demand. | Each conjunct is a measured gap recorded in this file's grounding block. Until all three hold, the eligibility set is either empty or keyed on an ungoverned signal such as filesystem modification time — which is reset by checkout, sync, and restore, so an irreversible action would key on a signal that silently lies. |
| **T-D** | Content sensitivity | A generated-artifact class is identified that must be destroyed **for cause** — client personal data, credentials, or contractually bound data. | Externally event-driven, on discovery. Routed to the **workspace owner**. | On discovery. | Routes **first** to the existing redaction rule, under which redaction preserves the record's presence; it escalates to deletion only if redaction is demonstrably insufficient for the cause at hand. |

**What this record does and does not do about T-A's evaluator.** It names the owner and the cadence, so the trigger is auditable rather than ownerless. It does **not** wire an automated evaluator, and no executable in this repository measures that population today. The lapse signal is therefore stated so a future reader can detect it: **the archived population measuring above either threshold with no corresponding intake observation filed** means the cadence was not run. The cheapest wiring, should the operator want teeth, is to extend the existing analysis-workspace staleness scan with a read-only size and count report over the same segments — it adds no mutation path and no continuous-integration gate, which is why it is the natural seam. That extension is **routed as follow-up work, not built here**; building it inside a decision record would be scope creep, and the decision does not depend on it.

## Alternatives Considered

**B — build the retention-windowed purge as the evaluation framed it: a retention window plus an operator sign-off gate, hard-deleting archived-past-retention generated artifacts. REJECTED on feasibility, not on preference.** Three independent, individually sufficient blockers: the scope predicate is uncomputable against live state; the retention clock has no start-time source, because the ledger that would supply it is unwired and empty while dozens of archival moves demonstrably occurred; and the retention constant fails evidence grounding at zero sources. B is not *declined* — it is **not specifiable** today. Writing its predicate out in full is what proved that: every eligibility conjunct that depends on an archival timestamp evaluates false for the entire live population.

**C — build in the analysis-workspace shape: opt-in, interactive-only, per-item prompt, purge to the operating system trash rather than an unlink, operator-local, no continuous-integration gate. REJECTED — and it deserves its strongest case stated before the rebuttal.**

The case for C is real. No doctrine is broken, because the platform already purges in the one wired place named above. The template exists, is reviewed, and self-tests, so marginal build cost is genuinely low. The operator's revealed preference at the prior release was to examine the purge seriously rather than wave it away. The archived segment has no terminal at all — whatever enters it stays forever by construction — and a retention decision taken while the number is small is cheaper than one taken under pressure.

It nonetheless does not prevail, on two grounds:

- **The gate would be unverifiable.** The template's own documented constraint is that no continuous-integration workflow can ship for it, because the workspace it scans is not tracked. Shipping that shape and calling it a **governed** retention-purge terminal with an enforceable sign-off gate would be governance theater: the gate would be an interactive prompt the platform cannot observe.
- **The asymmetry that will still be true in six months.** Deletion is cheap in the analysis workspace **because a rule already moved the durable content out before disposal** — analysis artifacts carry an explicit expiry field and a promotion path under which durable findings graduate out rather than being left to rot. **No equivalent rule exists for generated artifacts.** Nothing requires a generated artifact's durable content to be promoted out before the age-out sweep, and neither population has version history to recover from. Absent that rule, purging the archived segment risks destroying the **last surviving copy of a delivered, stakeholder-facing artifact**. That asymmetry — not "we never delete" — is the operative reason.

**A — ratify with no conditions. REJECTED as dominated.** Identical cost to the decision above and strictly less durable: a decision record without its re-open conditions is a snapshot, and a snapshot is what produced the second cycle this record exists to end.

**E — close the question with no record. REJECTED.** It leaves the reasoning nowhere and guarantees a third cycle, which is the failure mode already observed once.

**F — fix the substrate first (wire the ledger, backfill the archival-location stamps, add the missing classification row), then re-ask. REAL, but a different decision.** Each of those touches a packaged skill or the whole live artifact population. F is correctly expressed as **precondition T-C** on the build branch rather than as this record's deliverable.

## Consequences

**Positive.**

- The question stops being re-litigated. Two prior passes produced no durable record of *why*; this one records the reasoning, the measurements, and the conditions under which the answer changes.
- The reasoning is **re-runnable rather than asserted**. Each grounding observation in this file's frontmatter carries its command, its observed value, its pinned baseline, and the falsifier that would overturn it — and marks explicitly whether it is verifiable from this repository or was measured in the untracked operations workspace. The two commands that would not have survived re-examination were replaced before this record was written: the classified-instance form supersedes the raw hit count, and the structural column census supersedes the value-alternation grep. Their replacements are:

  ```sh
  # Retention-constant census — structural, not value-alternation.
  # Prints every (retention period -> disposition location) pair; discovers wordings
  # a hardcoded alternation cannot, which is the property the earlier form lacked.
  awk -F'|' 'NR>=71 && NR<=90 && NF>4 {print $4" -> "$5}' core/governance/RECORDS_POLICY.md

  # Purge-precedent census — classify before concluding.
  # The raw count is the INPUT, never the finding; classify each hit, then apply the
  # wiring test (>=1 executable writer) before calling any hit a live terminal.
  grep -rIn --include="*.md" --include="*.sh" --include="*.py" --include="*.toml" \
    -iE '\b(hard[- ]?delete|purge|destruction clock|retention[- ]purge)\b' \
    core/ operations/ release/ docs/

  # Wiring test, applied uniformly to every surface this record characterizes.
  grep -rIn --include="*.sh" --include="*.py" -i "<the declaring string>" .
  ```

- The records policy is **not amended**. Its disposition rules already state the destruction stance as none and already route file deletion to an operator-authorized decision class outside their own scope. Under this outcome that text is already correct, and adding a pointer sentence would restate a stance the file holds — the duplicate-source failure the platform's own discipline forbids. This record carries *why the question was asked and answered*; the policy carries the stance.
- One stale sentence is reconciled rather than annotated. The generated-artifact protocol previously said a retention-windowed purge, if ever wanted, would be a scope expansion under its own governed evaluation. That evaluation happened and resolved here, so the sentence now states the outcome and points at this record by slug.

**Negative, stated rather than implied.**

- **The archived generated segment still has no terminal.** Whatever enters it stays by construction. That is the accepted cost, bounded by T-A rather than by hope — and T-A's honesty depends on the cadence above actually being run.
- **Two of the four triggers evaluate over a population no automated check can reach**, because it lives outside the tracked repository. T-B and T-D are externally event-driven and fire on their own; T-C(ii) and T-C(iii) are in-repo and reader-checkable; **T-A and T-C(i) depend on a human looking.** Naming the owner and the cadence is what makes them auditable; it is not what makes them automatic.
- **Three substrate gaps are recorded here and left open**, each routed as follow-up rather than fixed inside a decision record: the disposition archive log's every-move-is-logged rule is declared but has no executable writer; the live artifact population never migrated onto the archival-location field the model shipped; and the records classification table carries no explicit row for a **post-sweep** archived artifact.
- **That last gap is genuinely unsettled, and this record does not pretend otherwise.** Three independent readers of the same policy text reached three different conclusions about which class a post-sweep archived artifact holds — the classification row keys on the artifact being *unreviewed*, which a file that has completed the sweep is not, while a composition note elsewhere in the same file states that the policy classifies swept artifacts, and the disposition destinations are demonstrably shared across classes, which argues class travels with the record rather than with its location. **The ambiguity does not bear on this decision**: under it the archived population is never destroyed regardless of which class it holds. Closing the gap is an edit to the classification table and is routed as follow-up; no sibling amendment is asked to change on account of it.

## Reversibility

**Artifact: CHEAP / Confidence HIGH.** One new decision record plus one reconciled sentence. Reverting the release merge restores the prior state exactly, and the governed forward path for changing the decision is a successor record under the supersede-not-edit rule.

**Commitment recorded: MODERATE / Confidence HIGH — contingent, and the contingency is named.** Once consumers rely on the disposition stance, introducing a destruction clock later is a governance-gated amendment rather than a free edit. **The four named triggers are what hold this at MODERATE rather than EXPENSIVE**: the reversal path is pre-specified and checkable, so re-opening is a bounded governed act rather than a re-litigation from scratch.

That grade is honest **only while the triggers are evaluated**. Two of them fire on external events and two are checkable from the tracked corpus, but the volume trigger and the substrate-readiness stamp conjunct both need the named owner to look at the named cadence. **If that evaluation lapses, the honest tier is EXPENSIVE**, because half the reversal path would then exist only as prose — the same declared-but-unwired shape this record diagnoses twice in its own § Context. The tier is stated with its condition so a future reader can grade it against what actually happened rather than against what was intended.

Confidence is HIGH because each leg was forced by a measured constraint — an unstampable eligibility field, zero groundable destruction clocks, a sub-one-percent reclaim — and not by preference.

## Related ADRs

- [ADR-054](../../release/ADRs/ADR-054-records-classification-retention-model.md) — the records classification and retention model, and the predecessor adjudication. It rejected a **policy-wide** destruction clock; this record answers the narrower **single-class** question and **inherits** its regulatory amendment trigger as T-B rather than minting a second one. Both remain operative.
- [ADR-080](ADR-080-project-folder-taxonomy-closed-5-bin-set.md) — the project-folder taxonomy migration that renames the generated staging bin under an additive window with existing-project migration deferred. Any future purge-scope predicate must therefore accept the **union** of the legacy and successor paths, which is why T-A's predicate names both.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — extend-before-create. The determination here is **extend**: this decision uses the existing decision-record mechanism and the existing archive-terminal invariant text, adding no parallel policy document, no new tool, and no new retention specification.
