<!-- reference-durability: allow-link -->
---
title: ADR-146 — Supersession is an append-only event with a two-id vocabulary, and log integrity is validated by a read-only cutover-dated population sweep
status: Accepted — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-24
release: pipeline-spec-self-consistency
deciders: "Workspace owner. Design decision rendered at Stage 5 Solutioning for the event-record integrity card and accepted by the hub at Procedure 4; the card's own headline evidence was falsified during design, which is why this record exists rather than a repair."
supersedes: none
tags: [architecture, release-pipeline, event-log, supersession, integrity-validation, cutover, read-only, both-arms, probe-validity, reversibility-cheap]
source_observations:
  - "The supersession mechanism already existed and sat entirely outside the enforcement boundary. Six rows carry `decision/decision-superseded` with `outcome=superseded` on this very milestone; the subtype is undeclared in § 3 and absent from the writer's mirror, so the tool rejects it, and none of the six carries a write-log entry. They were written by direct edit. An improvised mechanism outside the gate is worse than an absent one: the rows exist, nothing validates them, and § 4.1 now forbids editing them."
  - "The card's headline number was itself an instance of the card's own thesis. It reported 20 malformed rows and named their line numbers. Re-derived against the real population: 0 of 2,686. All 20 carry the canonical escaped separator § 4.3a admits and split to exactly 10 fields. The original probe counted BARE pipes — the precise defect the card's own comment names."
  - "The card's own acceptance criterion passed while the failure it exists to catch was happening. `A reconciliation reports 1:1 across the full population` was measured at 13 of 13, zero gaps either direction, while 12 of those 13 rows carried a terminal status whose terminal event was never emitted. It is a PRESENCE predicate; the failure is CURRENCY."
  - "A row count nets two opposite failures into one smaller number. Check 19 compares row counts and sees 109 discrepancies where a SHA1 content join, run in both directions, sees 134 row-without-entry PLUS 25 entry-without-row = 159. All 25 have a row at the same timestamp with different bytes, so they are in-place mutations of an append-only log, not lost rows — and the count could not see that either."
  - "An un-dated validator over this surface is born failing. § 4.1 forbids editing and § 7 makes the log Vital, so the 54 measured pre-existing violations are permanently unrepairable. A check that fails on its first run and every run after is muted within a week, which costs more than it ever caught."
  - "The writer could not host the check, and the reason was a live data-loss defect rather than a design preference. `append-pipeline-event.sh --self-test` appended to the live log and reverted by truncating to a line count captured before its own write. Reproduced under load: 3 of 240 concurrent rows destroyed, and the self-test ALSO false-failed, because its +1 delta assertion is itself a race."
  - "The reader had no way to attribute a write to its own identifier. Nine flags, four exact-equality column filters, one substring filter on `subject`, and nothing that looks at the payload column where decision ids actually live — so the playbook's instruction to `grep the specific decision ID` had no structured form at all."
---

# ADR-146 — Supersession is an append-only event with a two-id vocabulary, and log integrity is validated by a read-only cutover-dated population sweep

## Status

**Accepted** — ratified by the operator at the v4.40 release close gate (2026-08-28). The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `146` was derived at Engineering time, immediately before this file was authored, via `release/tools/renumber-adr.py`. The oracle reported `ANCHOR 141 origin/main` and `NEXT-FREE 142`; `--detect` reported `CLAIMED-SET-BRANCH-ONLY 142,143,144,145 (detection only — never binds)` with all four claims `BINDS`. Those four are already bound on this same release branch by records authored in earlier builds, so `146` is this branch's contiguous next, with the mainline reaching `ADR-141` and no hole beneath any claim. The number was deliberately **not** reserved at design time — the oracle is a *read*, not a reservation. Sibling unmerged release branches may claim overlapping numbers; those claims are **detection-only and do not bind**, and stepping past them to be safe would land a gap. The asymmetry is the whole rule: a duplicate is mechanically renumberable by this same tool at merge time, whereas a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole.

## Context

The pipeline event log is the platform's audit surface: append-only by § 4.1, Vital by § 7, written by one tool and read by another. Three things were true of it at once, and each one hid the next.

**Supersession was being performed, and it was being performed outside the gate.** Six rows already carried `decision/decision-superseded` with `outcome=superseded` — on this card's own milestone. The subtype is not declared in § 3 and not present in the writer's static mirror, so `append-pipeline-event.sh` rejects it outright. The rows exist anyway, and none of them carries a write-log entry. They were written by hand. That is not an absent mechanism; it is an improvised one that routes around its own enforcement, which is strictly worse, because the record now contains rows that no gate has ever seen and that § 4.1 forbids anyone from correcting.

**The card's evidence for the second problem was wrong in exactly the way the card was about.** It reported 20 malformed rows and listed their line numbers. Re-derived against the real population: **0 of 2,686**. Every one of the 20 carries the canonical `\|` escaped separator that § 4.3a explicitly admits, and every one splits to exactly 10 fields under the canonical delimiter. The original probe had counted **bare pipes** — which § 4.3a permits to exceed 11 — and this is the precise defect the card's own filing names in its prose. The problem was real; the measurement of it was an instance of it.

**The remaining problem was not the one that had been filed, and the criterion written to catch it could not.** The card proposed a reconciliation that "reports 1:1 across the full population." That predicate was measured at **13 of 13, zero gaps in either direction**, while **12 of those 13 rows** carried a terminal ledger status whose terminal event was never emitted. It is a *presence* predicate; the failure is *currency*. A gate that passes on stale data is worse than one that fails, because nothing prompts anyone to look at it.

Two existing integrity surfaces might have hosted a fix and neither could. `deploy.sh` **Check 19** compares row counts, and a count **nets**: it sees 109 discrepancies where a SHA1 content join run in both directions sees **134 row-without-entry plus 25 entry-without-row = 159**. All 25 orphan entries have a row at the same timestamp with different bytes, so they are in-place *mutations* of an append-only log — and the count could not see that either, because a rewrite does not move a row count. The writer's own `--self-test` was the other candidate, and it turned out to be actively destructive: it appended a sentinel to the **live** log and reverted by truncating back to a line count captured **before** its own write.

## Decision

**Part 1 — retiring a decision emits a new row; it never edits the old one.**

`decision/decision-superseded` is declared in § 3 and mirrored in the writer, with a `superseded:` / `by:` / `reason:` vocabulary registered as an **exact `(event_type, event_subtype)` key** in the § 11.8.1 registry. The superseded row is never mutated: § 4.1 forbids the edit, and the row-count parity control **structurally cannot see** an in-place cell rewrite, so a mutation is both prohibited and undetectable by the control that would otherwise catch it.

Three properties of the vocabulary are load-bearing rather than incidental.

*Label order is fixed by the rows already in the log.* `superseded:` names the retired decision and `by:` names the one retiring it. Reversing them would make every pre-existing supersession row non-conformant against its own newly-declared vocabulary, and would silently invert the meaning of every row a reader joins on.

*Ids are written verbatim.* Live data carries two incompatible decision-id conventions — sequential (`D-7`) and issue-keyed (`D-4767-Scope`). This row is a **join, not a rename**; canonicalizing here would break the join against the very rows it points at, and this subtype has no mandate to migrate an id namespace.

*The payload carries the vocabulary and nothing else.* Free-form `decision` subtypes open their payload with an `ms:#N;` token by playbook habit. This subtype declares a **closed** vocabulary, so that habit is rejected at emit — the two conventions cannot both hold, and the vocabulary is the one with teeth. The milestone remains carried by the `version` and `subject` columns, so nothing is lost.

**Part 2 — integrity is validated by a read-only population sweep in a separate tool.**

`release/tools/check-event-record-integrity.sh` runs five checks (row integrity, enum conformance, log↔write-log **content** reconciliation in both directions reported separately, ledger↔log id join **plus terminal-state agreement**, ledger row integrity and status enum). Every check prints its **denominator**: a finding count with no population is not a measurement.

It is **read-only by contract**, not by style. § 4.1 makes the log append-only and § 7 makes it Vital, so a validator that can write is one that can destroy the evidence it exists to protect — a claim with a worked example attached, since the writer's own self-test did exactly that.

The ledger row-integrity check is a **precondition** of the reconciliation, not an extension of it: `status` is read by column position, so on a field-shifted row that read returns some other column entirely and a state verdict computed on it would be meaningless. Malformed rows are reported **and excluded** from the reconciliation's denominator, with the exclusion printed rather than silently applied.

**Part 3 — the validator carries a cutover instant declared in the schema and parsed by the tool.**

Findings before the instant report `LEGACY` and do not gate; findings at or after it are violations. `LEGACY` means *does not gate*, never *not reported* — every legacy finding is printed with its denominator. The key lives in schema § 4.1 and the tool **parses** it rather than carrying a constant, which is the same single-authority pattern `parse_schema_enum` and `parse_schema_labels` already use, and the pattern whose absence let a tool drift from this document once already. A row whose timestamp cannot be parsed **grades anyway** — failing toward grading, because excusing a row because we cannot read its date would let a malformed row hide behind its own malformation.

**Part 4 — the self-test stops touching the live log.**

The writer's `--self-test` runs against a private temporary copy seeded from the live files, and asserts the live surfaces' reachability and writability **without appending**. This *removes* the mutation rather than guarding it.

## Alternatives Considered

**On the supersession shape.**

*`outcome: superseded` on an existing `d-class` row.* Rejected on measurement: `outcome=superseded` is **already overloaded** across five subtypes. On a `d-class` row it means "this row is dead", not "this row records a supersession", so a structured probe returns a mixed set and cannot answer the question the card asks.

*A new `event_type`.* Rejected because § 3 and `hub-action-tracking.md` § 3 both state the rule — subtypes are additive within an event_type — and the cost is a heading-count edit cascading through every downstream count, for nothing the chosen option does not already provide.

*A payload-only convention with no subtype.* Rejected because it is **unqueryable by construction**: no payload predicate existed, so the marker would be invisible to every structured read the platform ships, findable only by a raw `grep` that is `ugrep`-shimmed here and returns a plausible zero on a rejected pattern. That is "present but not findable" — the card's own defect, proposed as its remedy.

*Mutating the superseded row in place.* Rejected: § 4.1 forbids it, and 25 rows in the live log as of 2026-08-24 already show exactly this having happened while the row-count control did not move.

**On the validator's home.**

*Extend the writer's `--self-test`.* Rejected: it is a write-time tool at fixture scale that structurally cannot sweep a population, and its revert cycle was destructive under concurrency. Retained for the schema↔mirror lockstep, which is what it is good at.

*Extend the reader.* Rejected: its `--count` contract is consumed by the procedure under audit, and a validator sharing a codepath with the surface it validates is not an independent check.

*Extend `deploy.sh` Check 19.* Rejected on **release-scoped** grounds, and the distinction matters: Check 19 is exactly the count-based predicate this evidence falsifies, so it is the natural eventual consumer. But that file already carried two claimants and an integration criterion in this release, and a third would mint a second dependency edge on the release's most contended file for a benefit reachable independently. Routed forward rather than taken.

*A documented `python3` predicate in the playbook, with no tool.* Rejected: this card exists because hand-run probes produce plausible zeros. Prose cannot carry a precision probe and cannot fail CI.

**On the self-test fix.**

*Identity-based revert* (delete the sentinel by content) keeps the read-modify-write and its inode swap — it fixes the symptom and keeps the mechanism. *Advisory locking* imposes a contract on every caller, with an undefined failure mode on acquisition failure and silent defeat by any writer that ignores it. *Snapshot-and-restore* destroys concurrent appends by definition, which is the defect in a different costume. All three **guard** a mutation; the chosen option **removes** it, after which there is no lock to honour, no window to lose a row in, and no contract for a future caller to violate.

## Consequences

**For the next author adding a subtype.** A new non-grain subtype that owes a vocabulary extends by **one § 11.8.1 row + one `_FALLBACK_LABEL_SETS` line + one `CONDITIONAL` EMISSION-CONTRACT row**, and gains a validator arm only if it introduces a new invariant. Both mirrors are guarded bidirectionally, so a one-sided edit fails the writer's self-test naming the divergent token rather than shipping silently. Registering an exact `(type, subtype)` key binds that subtype **only** — siblings keep resolving empty and stay free-form, and that non-regression is asserted directly rather than left to inference.

**For anyone re-measuring this surface.** A committed fixture carries a canonical escaped-pipe row that **must pass**, paired with a bare-pipe row that must fail. Anyone who re-implements the bare-pipe count that produced this card's own wrong number fails on the pair. This is the durable form of the finding: the correction is a test, not a paragraph.

**For the Close gate.** A population sweep is added at Procedure 7, and a post-cutover violation blocks close. This is not redundant with the per-write assertion: a per-write check can only see writes that were *attempted*, and structurally cannot detect a row never emitted, a row edited in place afterwards, or a ledger whose status advanced while the log stayed silent.

**Accepted residuals, recorded rather than hidden.** Check 19 remains a row-count predicate and is therefore wrong by 50 discrepancies today; it is not fixed here, for the release-scoped reason stated above. The reconciliation will report 134 row-without-entry cases of which only 15 are *proven* direct edits — the writer appends the row before the write-log entry, so an interrupted write leaves the same signature, and the tool reports the class with its denominator without claiming a cause. Off-enum ledger statuses are reported, not repaired: the dominant off-enum values are verbatim the sibling namespace's enum, which makes it a confusability defect in a standard this card does not own.

**Nothing in the live population is repaired by this ADR, and that is a property rather than a shortfall.** Every measured violation predates the validator, § 4.1 forbids editing it and § 7 forbids deleting it. The cutover is what makes the tool shippable at all.

## Reversibility

**CHEAP** / confidence **HIGH**.

Every edit is additive: one enum member, one registry row, one mirror line, one reader flag, one new read-only file, one conditional contract row. The validator gates nothing outside its own `--self-test` until the cutover instant is bound, and it is read-only, so it cannot have damaged anything to undo. No emitted row depends on the new behaviour and no existing row changes meaning. Revert is `git revert` plus a manifest regeneration and a package rebuild — both mechanical, both regenerated rather than hand-edited.

The one asymmetry worth naming: the two mirror pairs must revert **together**. The lockstep assertions are bidirectional, so reverting one side of either pair leaves the writer's self-test red. Reverting the whole change restores a consistent state; reverting half of it does not.

## Related ADRs

- **ADR-145** — declares the § 11.8.1 subtype payload-vocabulary registry this record's Part 1 extends. That ADR created the seam; this one is its first consumer, and the extension cost it predicted (one table row, one mirror line, no parser change) is what was actually paid.
- **ADR-119** — establishes that self-test coverage is discovered with a committed manifest floor. It is why the new validator needs no CI workflow edit and why its manifest row is mandatory rather than optional.
- **ADR-092** — binds the release version at the Stage-12 compare-and-swap. It is the reason the cutover instant is set at merge rather than at authoring: the boundary is an event that has not happened yet while the change is being built.
- **ADR-086**, **ADR-100** — the prior architecture decisions governing this same event-log surface; this record is consistent with both and supersedes neither.
