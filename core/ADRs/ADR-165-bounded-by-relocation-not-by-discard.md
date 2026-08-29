<!-- reference-durability: allow-link -->
---
title: "ADR-165 — An append-only log whose consumer needs its history is bounded by relocation, not by discard"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-29
release: warn-mode-gate-graduation
deciders: "Stage 5 Solutioning spoke (design, evidence-grounding) + operator ratification at Collective Review (D-10 fork resolution and warrant repair, D-11/D-23 ADR authorization, D-27 constant rename) + Stage 6 Engineering spoke (build, R1 re-grounding)"
tags: [records-management, retention, disposition, warn-mode, deploy-check, drain-evidence, byte-budget, least-destructive-disposition, reversibility-moderate, ADR-106, ADR-054, ADR-164]
source_observations:
  - "The shared deploy-check warn log has no rotation, no size cap, and no lifecycle. Twelve append sites across two variables resolve to one file; there are zero truncating writes and no rotation, age-check or prune logic anywhere in the script. Measured on the live instance: 97,055,630 B, growing since 2026-07-03."
  - "The three branches the ticket offered — size/age rotation retaining K generations, lifecycle truncation, and append-forever plus an operator-run prune tool — all discard records at their boundary, so they stand or fall together rather than as three independent options."
  - "The arithmetic rules that whole class out, and it is a contradiction rather than a tuning problem. The worst contiguous 30-day window measures 78,642,875 B. The longest day-denominated shakedown horizon a sibling gate depends on is 90 days. Any hot-file ceiling low enough to be a meaningful bound on a 97 MB file is one to two orders of magnitude below what a 90-day drain window requires, so the admissible set for a discarding ceiling is empty."
  - "The retention constant a discarding branch would have to canonicalize enumerates at zero sources. ADR-106 ran that survey against the whole corpus: 12 retention constants exist and every one is a preservation floor or a pre-disposition eligibility clock; not one is a post-archive destruction clock. The evidence-grounding standard rejects a canonicalization whose enumeration lists fewer than two sources."
  - "A never-delete doctrine cannot carry this decision, and ADR-106 says so in terms: three live purge terminals already exist for other artifact classes, so the framing that a purge terminal would depart from platform doctrine is false. The decision has to rest on measured feasibility and cost."
  - "The platform has already solved this exact problem shape once, on a record classified Vital/Permanent: the release-corpus sweep bounds the hot release ledger by a byte budget, relocating aged-out content into same-directory archive segments, and took that ledger from 783,719 B to 148,558 B without destroying a record."
  - "A rotation boundary implemented as a same-directory rename cannot lose a record: an append whose file descriptor is already open follows the inode into the segment, and the next append re-opens by path and creates a fresh hot file. Copy-then-truncate has a window in which appended records are destroyed."
---

# ADR-165 — Bounded by relocation, not by discard

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance.** Allocated at this Engineering commit as the next number above the **union** of the mainline anchor and this branch's own in-flight claims. `renumber-adr.py --detect` reported `ANCHOR 162 origin/main`, `NEXT-FREE 163`, and `CLAIMED-SET-BRANCH-ONLY 163,164 (detection only — never binds)`. The oracle anchors on mainline and cannot see a sibling's unmerged claim, so `--next-free` alone would have collided **twice** on this same branch. 165 was taken against the union and re-verified to report `BINDS`.

A concurrent release independently claims 163 and 164 against the same mainline anchor. That is correct behaviour by both sides — unmerged sibling claims are advisory — and whoever merges second renumbers. Taking the union number rather than jumping ahead to dodge the collision is deliberate: a gap blocks the repo, a duplicate is tooled.

## Context

### The defect

The shared deploy-check warn log is append-only with no ceiling. Twelve append sites across two variables resolve to one file through the operator-instance path resolver; there are zero truncating writes, and no rotation, size-check, age-check or prune logic exists anywhere in the script. On the live instance the file measures **97,055,630 B** and has grown continuously since `2026-07-03`. Every append carries `2>/dev/null || true`, so at disk exhaustion the failure mode is *lost warn records*, not a visible error: the log degrades quietly at exactly the point its size becomes the problem.

### Why the fork as posed could not be resolved

The ticket offered three branches: **(a)** size/age rotation retaining K generations, **(b)** truncation at a lifecycle point, **(c)** append-forever with an operator-run prune tool. They read as independent options. They are not — **all three discard records at their boundary**, so they stand or fall as one class, and one measurement decides the class.

**A sibling card in the same release wave drains this file to decide whether a warn-mode gate may graduate.** That drain's horizon is the gate-rollout escalation constant: **90 days**. The live log's **worst contiguous 30-day window is 78,642,875 B**, starting `2026-07-17`. So a discarding ceiling would have to satisfy two constraints at once:

- low enough to be a meaningful bound on a 97 MB file — single-digit MB, which is what "solve the growth problem" means here; and
- at or above ~78.6 MB *per 30 days* to preserve a 90-day drain window.

**The intersection is empty.** This is not a tight constraint to be tuned; it is a contradiction. A discarding rotation cannot satisfy both cards at any budget, and a rotation policy that resolved the growth ticket by breaking the graduation it was meant to enable would have shipped a regression wearing the shape of a fix.

### The warrant this record does NOT rest on, stated because the first draft did

An earlier draft of this design argued from `core/governance/RECORDS_POLICY.md` § *Disposition Rules* — *"The platform does not destroy records"* — and cited ADR-106 as the precedent for declining a purge terminal. **That text is real and that citation is real, and the argument is still wrong**, because ADR-106's own reasoning forecloses it:

> The framing that motivated the card — that a purge terminal would depart from platform doctrine — is **false**. **Three live purge terminals already exist** for other artifact classes … The decision therefore **cannot rest on "the platform never deletes"**; it has to rest on **measured feasibility and cost**.

Those three terminals are enumerated there: the analysis-workspace staleness tool's per-item interactive purge to the OS trash, the communications lifecycle's auto-purge of an archived message after a short fixed window, and the secrets-handling policy's destruction path. A corpus probe at that survey's baseline returned 21 hits across 11 files against a positive control of 58 hits across 14 files, so the probe discriminated.

**ADR-106 pre-emptively rejects exactly the argument it was being cited for.** Reaching for the doctrine would have repeated, in citation form, the grounding failure ADR-106 exists to prevent. It is recorded here rather than quietly dropped, because a reader who finds the doctrine reading persuasive should find its refutation in the same place.

Records policy is therefore admitted below as a **cost input** — a discarding terminal for this class would require a governed amendment, and that is a real price — never as the warrant.

## Decision

**The warn log is bounded by relocating the hot file whole into a numbered same-directory segment once it passes a byte budget. Nothing is ever discarded; retention is permanent.**

The mechanism is four rules and one obligation.

**1. The boundary is a rename, and that is load-bearing rather than incidental.** A same-directory `mv` is atomic and **cannot lose a record**: an append whose file descriptor is already open follows the **inode** into the segment, and the next append re-opens by path and creates a fresh hot file. Copy-then-truncate has a window in which appended records are destroyed. This single property is what makes a rotation boundary recoverable by concatenating the family back together — and therefore what reclassifies the change from **IRREVERSIBLE** to **MODERATE / HIGH**.

The same property carries idempotence and concurrency without a flag. The rotating helper runs inside command substitution, i.e. a **subshell**, so an "already rotated this run" variable would not propagate to the parent and a flag-based guard would be *silently* broken. None is needed: after the move the hot file is absent, the size test fails, and a second call is a natural no-op. Two concurrent runs may both observe over-budget; one move wins and the other fails on a missing source. No record is lost in any ordering.

**2. The budget is byte-denominated and the segment count is an output of the rule, never an input.** The rule *shape* is adopted from the shipped release-corpus precedent, which is the platform's own answer to this problem shape on a record classified **Vital/Permanent**. The *magnitude* — 16 MiB — is derived from the measured append rate: at the trailing-12-day rate (0.83 MB/day) rotation fires about every 19 days, at the lifetime rate (1.69 MB/day) about every 9. The worst observed single day (14,569,803 B) stays under one budget, so even a peak day rotates at most once. No headroom or hysteresis constant is declared, and the divergence from the precedent is reasoned: the sweep needs a floor because it moves *part* of a file and would otherwise re-breach on the next append; this moves the **whole** file, so post-rotation size is 0 by construction and hysteresis is structurally unnecessary.

**3. Segments are keyed by a zero-padded 5-digit monotonic sequence.** Two corpus conventions were available and neither is adopted, on a property of *this* record rather than a preference. A **family** key needs a semantic partition the warn log does not have — its rows are check findings, not release-scoped blocks. A **calendar-quarter** key is defensible but decouples the segment boundary from the byte budget, so a quarter with a 78 MB burst and a quarter with 3 MB would produce wildly unequal segments and the budget would stop binding. A monotonic sequence makes the segment boundary *identical to* the budget boundary, which is precisely the count-is-an-output property the precedent names as its reason to be byte-denominated. Zero-padding to five digits makes lexical order equal numeric order, so a plain glob sorts correctly without `sort -n` — whose interaction with `comm` produces silently wrong set differences. **Residual, stated rather than left to be discovered:** at 100,000 segments that property breaks. At the measured rate that is roughly 26–52 segments a year.

**4. Consumer patterns must admit digits.** Segment filenames carry digits, and a `[a-z-]` character class is blind to every one of them — a class of defect this corpus has already been bitten by once. Any pattern matching the family uses a digit-admitting class.

**The obligation: every drain reads the family, never the hot file.** The shared read surface echoes the segments oldest-to-newest with the hot file always last. A drain that opens the hot path directly is not committing a style violation — it produces a **plausible wrong answer**: after the first rotation its counts collapse to the current window, and a flip register would read *"drain drained"* when the log had merely rotated. That is a gate arming on evidence nobody reviewed, which is the failure mode this whole release exists to prevent. ADR-106 measured exactly this on the release ledger — a control returning **2** against a true population-wide count of **10**, because a sweep had moved 8 rows into segments — and states the rule generally: after an archival sweep, any claim of the form *"field X has no source"* must be probed across the segment family or it silently under-measures its own control.

### Subordinate rulings

**The append-path silence is retained, with the rationale recorded and one observable added.** All twelve append sites keep `2>/dev/null || true` verbatim. Making a `--check` run fail *because a log write failed* converts an observability problem into a merge-blocking one, which is strictly worse than a lost advisory row; editing twelve sites also multiplies the blast radius sixfold for no gain. Instead the choke point emits one notice when it detects the pathological state — hot file present, over budget, move failed. **That notice goes to stderr**, because the helper is consumed via command substitution and a stdout emit would be captured into the caller's variable, corrupting the very path it is warning about. It touches the finding counter on no path, so the aggregate verdict — computed solely from that counter — returns exactly what it returned before.

**The cross-card retention invariant is held by derivation, not by comparison.** The retention constant is *assigned from* the gate-rollout escalation constant rather than from a literal, so the `>=` relation cannot be broken by an edit and no runtime assertion is owed. Under permanent retention the day count is a declared **lower bound the implementation exceeds without limit**, not a disposition clock; nothing in the script deletes a warn-log byte, and a reader must not infer from the day count that something does. The previous shape declared a number that nothing read and nothing enforced — a declaration with no firing surface, which is the exact defect class this release closes.

**Volume re-open trigger (T-A′), on ADR-106's two-axis construction.** Total on-disk bytes do not shrink under this decision. The commitment is re-opened when the segment family exceeds **1 GiB** on the byte axis **or 500** on the file-count axis. Two axes because the failure shapes differ — a few very large segments versus many small ones — and either alone would miss the other.

## Consequences

**Positive.**

- The hot file — the surface the ticket is filed against — drops from ~97 MB to at most 16 MiB, a roughly 5.8× reduction, while the record count is unchanged.
- The cross-card contract is satisfied **structurally rather than numerically**: permanent retention is unconditionally ≥ any horizon, so no number has to be negotiated between two cards, and a later change to either card's horizon cannot break it.
- **Zero new files** outside this record: no prune tool, no script-execution allowlist entry, and therefore no cross-milestone dependency edge on the two open cards that own that allowlist. The conditional edge the ticket anticipated never forms.
- Twelve append sites are untouched, so the blast radius is two changed lines behind one new block, and the two writer variables are unified at one choke point that did not previously exist.
- Segments are **immutable once written**, which makes a real follow-up available that was not available before: an instance-backup path can snapshot the hot file alone and let segments persist unsnapshotted, instead of re-copying the whole history on every update.

**Negative, and accepted.**

- **Total on-disk bytes do not shrink.** This is the one axis on which a discarding rotation would genuinely have done better, and it is accepted with the same posture ADR-106 took for the archived generated tree — *"it grows, slowly, forever"* — mitigated by a named, checkable volume re-open trigger rather than by a discard clause. The cost is bounded by the append rate, which is decelerating.
- **The instance-backup amplification is not fixed here and may be made slightly worse.** Seventeen instance-update snapshots hold ~1.38 GB, roughly 89% of the instance footprint. That is a different mechanism and is out of scope. **This design creates a new predicate for whoever writes that card**: if the snapshot path copies the *directory* or globs the warn-log basename, it will now copy the hot file **plus every segment** — total bytes unchanged, file count up. If it copies the single named file, amplification drops by roughly 83% for free. Establishing which of the two it does is that card's first task.
- **The budget magnitude rests on one instance's measured rate.** The rule shape is grounded in a shipped precedent; the number is a projection from 56 days of a single operator instance. It is recorded as derived, not as calibrated, and it is the value most worth revisiting once a second instance exists.
- **Adopting the orphaned pre-relocation log as segment `00000` is one-way.** It is a move of ~70 MB of operator-instance state that cannot land in a pull-request diff and cannot be rehearsed by reading one, which is why the release's dry-run stage stays uncompressed. The orphan is **two** files, not one, and the merged family carries a **12-day instrumentation gap** that a drain must declare rather than read as twelve quiet days.

**Neutral.**

- The warn log has no explicit row in the records-classification table and resolves through the default. That is a substrate gap ADR-106 already named, and it is deliberately routed to a following release rather than amended here — same reasoning, same routing, and it avoids a second writer on a file another card is already amending.
- The archive log the policy expects every archival move to be recorded in has zero rows and zero executable writers. This design produces archival moves; whether they are logged depends on that unbuilt writer. Recorded, not filled.

## Alternatives considered

| # | Alternative | Why rejected |
|---|---|---|
| A1 | **Size/age rotation retaining K generations** — the ticket's option (a) | Fails the arithmetic. To bound a 97 MB file meaningfully the ceiling must be single-digit MB; to preserve the 90-day drain window it must hold ≥ 78,642,875 B per 30 days. The admissible set is empty, so this is not a budget to be chosen badly — there is no budget to choose. It also requires canonicalizing a retention constant whose value class enumerates at **zero** corpus sources against a positive control of 12, which the evidence-grounding standard rejects as a matter of method. |
| A2 | **Lifecycle truncation — per-release or per-run reset** — the ticket's option (b) | Eliminated first and hardest. A per-release reset destroys the drain history that a sibling card *in the same wave* is being built to read. It is the same contradiction as A1 with the ceiling set to zero. |
| A3 | **Append-forever plus an operator-run prune tool** — the ticket's option (c) | Rejected on three counts. It discards, so it inherits A1's arithmetic. It creates a new executable, which needs a script-execution allowlist entry owned by two open cards in another milestone — minting a cross-milestone dependency edge out of a design choice. And it bounds the file only when the operator remembers to run it, which is the same unbounded-by-default posture the ticket is filed against. |
| A4 | **In-place compaction — deduplicate rows, carry an occurrence count** | Bounds the file without a prune tool, but destroys the per-occurrence timestamp. A sibling card's acceptance criterion partitions the drain by row shape and counts per-day occurrences; collapsing duplicates destroys exactly the signal being counted. |
| A5 | **Amend the records policy to authorize a destruction clock for this class, then discard** | The honest form of A1 — and the reason it is listed separately is that it is the only branch on which discarding is *specifiable* at all. Rejected on cost, not on doctrine: it requires a governed policy amendment, which is out of scope for a `size:S` bug card and unauthorized by this release's plan. Even granted the amendment, A1's arithmetic still holds, so the amendment would buy a branch that still cannot satisfy both cards. Paying a governance cost for an option that remains infeasible is the worst outcome on the table. |
| A6 | **Route rotation through the existing release-corpus sweep tool** — extend before create | The predicate genuinely holds: that tool bounds an append-only log by relocating content into same-directory archive segments. **Net-new because in-place is infeasible.** It parses markdown blocks keyed by an archived-pointer sentinel line, and a JSONL log has no block structure and nowhere to carry a sentinel; it resolves the repository root from its own path and operates on git-tracked corpus files, whereas this log is git-ignored operator-instance state outside the repository; and invoking it would mean either running Python from the deploy script on every check, or an operator-run tool — **and the operator-run form is exactly A3**. What *is* extended is cited rather than re-derived: the byte-denominated budget rule, count-is-an-output, destination-side conservation verification, and a segment inheriting its parent's records class. The rule shape is reused; only the mechanism is net-new. |

## References

- [`core/ADRs/ADR-106-generated-artifact-retention-purge-declined.md`](ADR-106-generated-artifact-retention-purge-declined.md) — the record this decision is grounded on twice over: it establishes that **three live purge terminals already exist**, so a never-delete doctrine cannot carry a decision and only measured feasibility and cost can; it reports the **N=0** enumeration for the destruction-clock value class against a positive control of 12; and it measures the **read-path volume obligation** a segment family creates (a control returning 2 against a true count of 10 when run on the hot file alone)
- [`release/ADRs/ADR-054-records-classification-retention-model.md`](../../release/ADRs/ADR-054-records-classification-retention-model.md) — the records-classification and retention model whose amendment path A5 would have to take
- [`core/governance/RECORDS_POLICY.md`](../governance/RECORDS_POLICY.md) — § *Disposition Rules* (disposition is a move or a presence-preserving redaction) and the retention schedule row showing a Vital/Permanent record bounded by a byte budget on its hot file. Admitted here as a **cost input**, never as the warrant
- [`release/tools/sweep-release-corpus.py`](../../release/tools/sweep-release-corpus.py) — the shipped precedent whose rule shape this extends: byte-denominated boundary, retained count as an output, destination-side conservation, and the headroom rationale this design deliberately diverges from
- [`core/ADRs/ADR-164-written-is-not-repo-derivable.md`](ADR-164-written-is-not-repo-derivable.md) — the sibling record in this same release. Its W1 axis (a drain-history criterion may be declared only where the sink is written) is the reason the read surface here is a shared symbol rather than a path, and its `INSTRUMENTATION-SUSPECT` vocabulary is what the merged family's 12-day instrumentation gap must be declared under
- [`core/standards/gate-efficacy-standard.md`](../standards/gate-efficacy-standard.md) — the flip-decision register whose G3-14 / G3-15 row names the gate-rollout constants this record's retention window is derived from
