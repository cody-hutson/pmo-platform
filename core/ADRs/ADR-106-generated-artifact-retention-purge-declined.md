<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-106 — Archive is the permanent terminal for generated artifacts, and the derived release ledgers carry a read-path volume obligation, not a disposition one
status: Proposed
date: 2026-08-03
release: governance-hardening
deciders: "Workspace owner — the ratify-vs-build fork was rendered directly by the operator at the Stage-5 Wave B briefing (RATIFY; the build branch declined). The derived-ledger disposition was added to the card's acceptance criteria after that briefing and is decided here against the post-normalization corpus. Designed at Stage 5 (Principal Engineer — Architecture Assessment); authored at Stage 6."
tags: [records-management, retention, disposition, generated-artifacts, release-corpus, derived-surfaces, least-destructive-disposition, iso-15489, reversibility-moderate]
source_observations:
  - "Generated-artifact cleanup terminates at archive-before-delete. No governed retention-purge terminal exists for the generated class, and the prior adjudication of that question produced no durable record of why — which is why the question returned a second time."
  - "The framing that motivated the card — that a purge terminal would depart from platform doctrine — is false. Three live purge terminals already exist for other artifact classes. The decision therefore cannot rest on 'the platform never deletes'; it has to rest on measured feasibility and cost."
  - "The purge-scope predicate is not computable against live state. The archival-timestamp fields the predicate would key on are stamped on zero files, against a positive control of 883 for a sibling field, so the eligible set is empty for the whole live population."
  - "A retention constant for the build branch cannot be grounded. The corpus carries retention values, and every one is a preservation floor or a pre-disposition eligibility clock; not one is a post-archive destruction clock. The value class being canonicalized enumerates at zero sources."
  - "The reclaim is roughly 1 MiB against a workspace of roughly 1.45 GiB, with nothing archived in the three months before the survey. The cost side of the trade is measured, not assumed."
  - "The release corpus was normalized in this same release: the authoritative record was bounded by an archival sweep, and the three derived ledgers were explicitly classified Important with a never-regenerated-whole disposition because they hold sole-copy fields with no source in the authoritative record."
  - "The derived ledgers' volume was handed to this card as a named input on a rationale that was subsequently falsified — they were described as having no retention question, when in fact records management does reach them. The routing survived; the reason did not."
---

# ADR-106 — Archive is the permanent terminal for generated artifacts, and the derived release ledgers carry a read-path volume obligation, not a disposition one

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes in-flight pull-request claims, not only what is on the mainline. Allocated at commit time: `release/tools/check-adr-numbers.py` reported a contiguous `001..105` with no duplicates, so this ADR takes **106**. Referenced by **slug** (`generated-artifact-retention-purge-declined`), never by integer, so the number re-resolves if a concurrent release claims 106 first.

**Two decisions, one record.** This ADR settles two questions that arrived at the same card from different directions: whether a retention-purge terminal is built for generated project artifacts (§ Decision 1), and whether the three derived release ledgers owe a volume obligation of their own (§ Decision 2). They are recorded together because they are one question asked of two artifact classes — *does this class owe an obligation to get smaller?* — and because the second was added to the card's acceptance criteria expressly so it would be answered against the records taxonomy the first is reasoning from. The scope widening beyond the slug is recorded here rather than left implicit.

## Context

### The generated-artifact question

The generated-artifact lifecycle runs `lint → promote → archive` with no hard-delete terminal. Archive *is* the terminal: a file is moved to the staging tree's `_archived/` bin or flipped to an archived lifecycle state **in place**, and is never hard-deleted. A prior release considered a retention-purge terminal — hard-deleting archived generated artifacts after a retention window under an operator sign-off gate — and deliberately omitted it. The operator declined to ratify never-delete as the *permanent* terminal at that point and opened a governed issue instead, so the question returned with no record of the first adjudication's reasoning. Producing that record is the point of this ADR: without it, the question returns a third time.

**The framing the card inherited is false, and saying so is load-bearing.** The card reads as though a purge terminal would break a platform invariant. It would not. Three live purge terminals already exist for other classes: the analysis-workspace staleness tool offers a per-item interactive purge to the OS trash, the communications lifecycle auto-purges an archived message after a short fixed window, and the secrets-handling policy carries its own destruction path. A corpus probe returned 21 hits across 11 files, against a positive control of 58 hits across 14 files for the archive-terminal vocabulary, so the probe discriminates. The card is right that no terminal covers the *generated* class. It is wrong that building one would be novel. Any reasoning that rests on "we never delete" would not survive a reader applying it in six months, so this decision does not rest on it.

**What does the deciding is measurement.** Three findings, each independently sufficient against the build branch:

1. **The scope predicate does not evaluate.** "Archived-past-retention" needs an archival timestamp. The only governed carriers of one — the promotion-state and lifecycle-change stamps — are present on **0** files across the live artifact population, against positive controls of 883 for the creation stamp, 52 for the superseded artifact-type field, and 5 for the lifecycle-state field, with an impossible-string negative control at 0. The eligible set is empty for 100% of the live population. A filesystem modification time is not a substitute: it is reset by checkout, sync and backup restore, so an irreversible action would key on a signal that silently lies.
2. **The retention constant cannot be grounded.** The corpus carries 12 retention constants. Every one is a preservation floor below which a record must be *kept*, or a clock that makes a record *eligible for a move*. **Not one authorizes destruction.** The evidence-grounding standard rejects a canonicalization whose current-state enumeration lists fewer than two sources; for the value class actually at issue — a duration after which a record is destroyed — the enumeration returns **zero**, against a positive control of 12 proving the survey finds retention values when they exist. The canonicalization is declined as a matter of method, not preference.
3. **The reclaim does not pay for the risk.** The archived generated population measured 42 files and roughly 1.06 MiB against a workspace of roughly 1.45 GiB — **0.07%** — with a control of 509 non-archived siblings confirming the population partition closes. Accretion clustered in two months and then stopped: nothing was archived in the three months before the survey.

**Audit-baseline note.** Finding 3 rests on a population that was accreting at zero when measured, and a default-to-small classification on a quiet population is not load-bearing on its own. The baseline is pinned — the survey commit, the survey date, and the full history of the archived tree — and the volume re-open trigger below is itself the standing re-check, so the finding cannot expire silently.

### The derived-ledger question

This release normalized the release corpus. Two changes underneath this card are the reason it was sequenced last:

- **The authoritative record was bounded.** An archival sweep relocated aged-out deployment-log bodies into four same-directory archive segments, taking the hot ledger from 783,719 B to 148,558 B. Each archived block keeps its heading plus a pointer in the parent, so every anchor still resolves.
- **The three derived ledgers were explicitly classified.** `core/governance/RECORDS_POLICY.md` now classifies the release index, the release digest and the changelog as class **Important** with the disposition **retained in place, never regenerated whole**, and a retention of *permanent while the corpus is live, no age-out*. The reason is that they are **projected but not reproducible**: they hold sole-copy fields whose only home is the file itself, so re-acquisition — which the `Reference` class licenses — would destroy the content that made them worth retaining.

The derived ledgers' *volume* was routed to this card as an explicit input when the sweep's target was re-scoped to the authoritative record alone. **The rationale offered for that routing was falsified within hours and is corrected here.** The three files were described as derived rather than smaller, and therefore as carrying no retention question. Independent review established the opposite: they hold sole-copy content with no source in the authoritative record, so records management does reach them. The routing stands and is strengthened. The reason given for it does not.

**Re-measured on the release branch, with the units stated:**

| Ledger | at the mainline (B) | on the branch (B) | delta (B) |
|---|---|---|---|
| `release/releases/RELEASE_INDEX.md` | 196,977 | 197,406 | +429 |
| `release/releases/RELEASE_DIGEST.md` | 398,144 | 398,606 | +462 |
| `CHANGELOG.md` | 182,251 | 182,810 | +559 |
| **total** | **777,372** | **778,822** | **+1,450** |

The +1,450 B is this release's own three entries, emitted one at a time by the projector — the expected growth of an append-only projection, not drift. *Control over the same span:* the authoritative record moved 783,719 B → 148,558 B, so the measurement distinguishes a swept file from an unswept one.

**The sole-copy finding survives the sweep, and the probe has to span the segments to show it.** Across the entire authoritative record — the hot ledger **and** all four archive segments — `Theme` appears on **0** lines and `summary:` on **0** lines. *Control:* the word-bounded token `Milestone` appears on **10** lines across that same population (2 in the hot ledger, 2 + 1 + 5 + 0 across the four segments), so the probe finds what is there. The control is the reason the population matters: run against the hot ledger alone it returns **2**, because the sweep moved 8 of the 10 into segments. After an archival sweep, any claim of the form *"field X has no source in the ledger"* must be probed across the segment family, or it silently under-measures its own control.

## Decision

### Decision 1 — Archive is ratified as the permanent terminal for generated artifacts

**No retention-purge terminal is built.** Archive is the permanent terminal for `domain: generated` artifacts: a file is moved to the archived bin or flipped to an archived lifecycle state in place, and is never hard-deleted. The platform's least-destructive-disposition stance already states that disposition is a move or a redaction that preserves the record's presence, and that deletion of a record file is an independent operator-authorized decision-class outside records-policy scope. That text is correct under this outcome and is **not amended** — the policy carries the stance; this ADR carries the record of why the question was re-asked and re-answered.

The decision is a commitment with named reversal conditions, not a permanent closure. Any one of **T-A**, **T-B** or **T-D** re-opens it. **T-C is a precondition on building**, not an independent trigger: until it holds, the build branch is unspecifiable regardless of the others.

| ID | Trigger | Checkable predicate |
|---|---|---|
| **T-A** | Volume | The archived generated tree on any operator instance exceeds **100 MiB** OR **5,000 files**. Set at roughly 100× the measured state on both axes, so the trigger fires well before the population becomes operationally material but far above accretion noise. Two axes because the failure shapes differ — a few large exports (bytes) versus many small reports (inode and scan cost) — and either alone would miss the other. |
| **T-B** | Compliance | A regulatory regime attaches that owes a mandated destruction clock. Inherited verbatim from the predecessor records-classification decision rather than minted here; that ADR already names this trigger and its amendment path. |
| **T-C** | Substrate readiness (**precondition**) | All three hold: (i) the promotion-state stamp is present on ≥90% of the live generated population; (ii) the records archive log has at least one executable writer **and** a non-zero row count; (iii) the records-classification table carries an **explicit** row for post-sweep archived generated artifacts rather than resolving them through the default. Each is a measured gap today. |
| **T-D** | Content sensitivity | A generated-artifact class is identified that must be destroyed **for cause** — client personal data, credentials, or contractually bound data. Routes **first** to the existing redaction rule, which preserves the record's presence; escalates to deletion only if redaction is demonstrably insufficient. |

### Decision 2 — The derived release ledgers carry a volume obligation, and it is a read-path obligation

**The release index, the release digest and the changelog carry a volume obligation that is distinct from the authoritative record's — distinct in kind, not merely in degree.** They are not exempt. The alternative reading — that a projected view has no volume question because it can be re-acquired — is **rejected**, because it is the reading the classification in force already forecloses: these three are `Important` precisely because they are *not* supersedable by re-acquisition.

The distinction is exact, and it follows from the dispositions already shipped:

| | The authoritative record | The three derived ledgers |
|---|---|---|
| Records class | Vital | **Important** |
| Retention | Permanent | Permanent while the corpus is live — **no age-out** |
| Disposition | retained in place **or in a same-directory archive segment** | **retained in place; never regenerated whole** |
| Relocate bytes to an archive segment? | **Available** — the sweep, triggered on a byte budget over the hot file | **Closed** — no age-out, so nothing becomes archival-eligible |
| Regenerate the file from its source? | not applicable — it *is* the source | **Closed** — a whole-file regenerate is a destruction event, not a refresh |
| Volume is therefore bounded on the | **write path** | **read path** |

A ledger has exactly two ways to get smaller: relocate content to an archive segment, or regenerate itself from a source. **The classification closes both for these three** — the first by granting no age-out, the second by naming a whole-file regenerate a destruction event that surfaces as a clean diff rather than a conflict, so nothing flags it. Neither closure is a gap to be filled later. Each is the direct consequence of the sole-copy finding: there is no source to regenerate from, and content that never ages out never becomes eligible to move.

**So the obligation lands on the reader, not on disposition.** It is a consumption constraint, not a records constraint. Consumers of these three files read them **targeted** — a version's row, a version's entry, a named section — never whole. The write path is already governed and already minimal: the projector emits one entry at a time to standard output and never rewrites a ledger. The read path is what remains ungoverned, and that is where the obligation sits.

**What this decision explicitly does not authorize.** No sweep, no archive segment, no regenerate, no truncation and no compaction pass for these three files. Any future proposal to reduce their byte count is a change to their records classification and takes the governed-amendment path — it is not an engineering optimization, and it must not be undertaken as one. This is stated because a byte total that keeps growing is a standing invitation to treat it as a cleanup task, and the classification's whole point is that for these three files, cleanup is destruction.

**Consistency with the classification, asserted and checkable.** This decision writes **zero rows** into `core/governance/RECORDS_POLICY.md`. It is the reading of a disposition already in force, not an amendment to it — adding a pointer sentence would restate a stance the file already holds and would put a second writer into a file another card in this release is amending, for no informational gain. The assertion is verifiable as an authorship property of the diff rather than a prose judgment: every hunk in that file on this branch is attributable to the archival-sweep card, and none to this one.

**Re-open trigger for Decision 2.** **T-E** — either (i) a consumer is introduced that must read any of the three **whole** rather than targeted, which converts the read-path obligation into a real cost the read side cannot absorb; or (ii) the sole-copy finding is retired, meaning every field in all three acquires a source outside the file, at which point `Reference` becomes the correct class, re-acquisition becomes genuinely available, and the volume question can be re-asked on different terms. Both are checkable by inspection. Deliberately no byte threshold: minting one would repeat the N=0 grounding failure recorded above, and the growth rate here is a projector emitting one entry per release, which is bounded by the release cadence rather than by anything a threshold would catch earlier.

## Alternatives considered

**Build the terminal as the card frames it** — a retention window plus an operator sign-off gate, hard-deleting archived-past-retention generated artifacts. **Rejected as not specifiable**, on three independently sufficient grounds: the scope predicate evaluates to the empty set for the whole live population, the retention constant enumerates at zero sources, and the reclaim is 0.07% of the workspace. This is not a declined option; it is an option that cannot be written down today.

**Build in the analysis-workspace shape** — clone the existing staleness tool: opt-in, interactive only, one operator keystroke per item, purge to the OS trash and never a recursive remove. This is the strongest alternative and it deserves its full case. No doctrine is broken, since the platform already purges elsewhere; the template exists, is reviewed and self-tests, so marginal build cost is genuinely low; the operator's revealed preference was to examine the purge seriously rather than wave it away; the archived bin has no terminal at all, so whatever enters it stays forever by construction; and the workspace is not small, so the intuition that storage does not matter here is not automatically safe. **Rejected on an asymmetry that would still be true in six months.** Deletion is cheap in the analysis workspace *because a rule requires durable findings to be promoted out before disposal* — the workspace carries an explicit expiry field and a promotion path, and what remains is a working artifact whose findings already left. **No equivalent rule exists for generated artifacts.** Nothing requires durable content to be promoted out before the age-out sweep, both trees are git-ignored so neither has version history as a safety net, and the archived copy may therefore be the **only surviving copy of a stakeholder-facing deliverable**. Separately, the template's own documented constraint is that it can never be a continuous-integration gate, because the tree it scans is git-ignored — so shipping that shape and calling it a *governed* terminal with an enforceable sign-off would be governance theater, with an interactive prompt standing in for a gate the platform cannot verify.

**Ratify bare, with no conditions.** Dominated: identical cost, strictly less durable. A decision record without its re-open conditions is a snapshot, and the reason this question returned at all is that the first adjudication left no record.

**Close the question with no record.** Rejected: it leaves the question open for a third cycle, which is the failure this ADR exists to end.

**Fix the substrate first** — wire the archive log, backfill the stamps, add the explicit classification row — and then re-ask. Real, but a different card: it touches a packaged skill and the whole live artifact population. It is correctly expressed as precondition **T-C** on the build branch rather than as this card's deliverable.

**For Decision 2, ratify that the derived ledgers carry no volume obligation** on the ground that a regenerable view has no retention question. **Rejected as inconsistent with the corpus.** These files are not regenerable without loss — that is the finding that produced their `Important` classification in the first place, three commits before this one. Ratifying their exemption on a regenerability premise would contradict a disposition shipped in the same release.

## Consequences

**Positive.**

- The question stops being re-litigated. Two prior cycles produced no durable record of *why*; this one does, with each leg tied to a probe that can be re-run rather than to a stance that has to be trusted.
- The reasoning is grounded where a reader will check it. The zero-source enumeration for a destruction clock, the zero-stamp field population and the sole-copy field survey are all re-runnable in one command each, so the decision ages into evidence rather than into assertion.
- **A release-level risk retires.** The two records-management cards in this release were modelled as a potential hard write-collision on the records policy, conditional on this card resolving to build. It does not. The contention downgrades to pure read-ordering with the archival-sweep card as sole writer of that file, and that card's amendment lands unopposed and unmodified.
- The derived ledgers get an explicit answer rather than an implicit one. Their bytes were previously governed by nothing: the sweep excluded them and the classification did not speak to volume. Naming the obligation and locating it on the read path closes a gap that would otherwise have surfaced as an ad-hoc compaction attempt.

**Negative, and accepted.**

- The archived generated population has no terminal. It grows, slowly, forever, until T-A fires. This is the cost of the least-destructive posture and it is accepted with the number measured rather than assumed.
- The derived ledgers keep growing at one entry per release. The read-path obligation constrains how they are consumed; it does not reduce them. A future consumer that genuinely needs a whole-file read has no cheap answer available, and T-E is the trigger that surfaces that rather than a mechanism that prevents it.
- **Three substrate gaps are recorded here and deliberately not fixed here.** The records archive log declares that every archival move is logged, holds zero rows and has zero executable writers against a control of dozens for a comparable wired log, while dozens of archival moves demonstrably occurred; no classification row covers a post-sweep archived generated artifact, so it resolves through the default; and the promotion-state and lifecycle-change stamps are present on zero live artifacts although the model shipped. Each is routed to a following release. Two of the three are edits to the records policy, and making them inside this release would recreate the exact write-collision this decision retires.

**Verification.** The claims above are checkable by: re-running the ADR-numbering tool for contiguity and uniqueness; asserting the records policy carries zero content changes attributable to this card; confirming the retired sentence in the artifact-workflow protocol no longer resolves; and confirming this ADR references its own decision by slug rather than by integer.

## Reversibility

**Artifact: CHEAP / Confidence HIGH.** One new decision record plus one reconciled sentence. Reverting the release restores the prior state exactly, and the governed forward path is a successor ADR under the immutable-ADR rule rather than an edit to this one.

**Commitment recorded: MODERATE / Confidence HIGH.** Once consumers rely on the disposition stance, introducing a destruction clock later is a governance-gated amendment rather than a free edit. **The five named triggers are what hold this at MODERATE rather than EXPENSIVE** — the reversal path is pre-specified and checkable, so re-opening is a bounded governed act rather than a re-litigation from scratch.

Confidence is HIGH because each leg was forced by a measured constraint — a zero-stamp field population, a zero-source enumeration for the value class, a 0.07% reclaim, and a sole-copy survey that closes its own control — and not by preference.

**Rollback infeasibility is not claimed here, because nothing irreversible is done.** The irreversible tier belongs to the branch this ADR declines. Had it been built, rollback would have been infeasible: the target population is git-ignored, so no version history exists to restore from; recovery would depend entirely on an OS-trash window the platform neither owns nor can verify; and regeneration is not equivalent, because an artifact's own inputs may themselves have been archived and the generating skill version may no longer exist. That statement is recorded so a future reader can see the tier the declined option carried.

## Related ADRs

- **ADR-054** — the predecessor adjudication, which established the four-class records taxonomy and rejected a *policy-wide* destruction clock. This ADR narrows that to a single artifact class and **inherits its regulatory amendment trigger (T-B) rather than minting a second one**. Lineage spans both ADR homes; numbering is global across them by design, so the lineage remains traversable.
- **ADR-080** — the project folder-taxonomy migration, which opened an additive-union window over the generated-artifact staging bin. Any future scope predicate for a purge must accept the union of both bin names, not only the newer one.
- **ADR-105** — the release-corpus canonicalization shipped earlier in this same release. It establishes the per-field provenance model and the derived-surface contract that Decision 2 reasons from, and it is the change that made the derived ledgers' sole-copy content visible as a records question rather than a projection detail.
