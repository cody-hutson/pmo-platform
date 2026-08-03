<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-105 — The release corpus has two typed file sources and two run-scoped inputs, one projector, and per-field provenance — not one authoritative ledger
status: Accepted
date: 2026-08-02
release: governance-hardening
deciders: "Workspace owner — the single-source counter-design was surfaced explicitly at Collective Review and REJECTED on measured grounds; INT-4 (the RECORDS_POLICY classification) was decided directly by the operator. Designed at Stage 5 across a design pass, two independent adversarial reviews and a Blocker-revision pass; authored at Stage 6."
tags: [architecture, release-corpus, duplicate-source-discipline, provenance, date-anchors, records-management, canonicalization]
source_observations:
  - "RELEASE_LOG.md, RELEASE_INDEX.md, RELEASE_DIGEST.md and CHANGELOG.md each record the same fact on every release, and the close-out wrote all four through four independent code paths. A fact with four writers drifts; the platform's own duplicate-source-discipline forbids the shape."
  - "The originating ticket's remedy — make the LOG authoritative and generate the other three from it — is not implementable as stated. The LOG carries neither a `# ` headline nor a `summary:`, so it cannot source the DIGEST headline or the CHANGELOG summary."
  - "The DIGEST's date was never sourced from the release note either: it is the close-out run anchor, and the note's own `date:` is written FROM that same anchor one phase later. Naming the note as the DIGEST's date source inverted the direction of derivation."
  - "The CHANGELOG entry additionally needs a repository slug, which is in neither typed file and was resolved from operator config with a bare-repo-name fallback that would ship a permanently broken URL."
  - "The duplication's measurable cost is a permanent 13-version grandfathering enumeration hard-coded into the INDEX checker. It exists only because one fact had two writers sampling two clocks."
  - "The ticket's claim that six of seven machine contracts become unnecessary is falsified. There are eight, and exactly one retires — six of the eight never read a derived surface at all."
  - "The three derived files hold 317 sole-copy fields with no source anywhere else, so `derived` here does not imply `reproducible`, and a whole-file regenerate is a destruction event."
---

# ADR-105 — The release corpus has two typed file sources and two run-scoped inputs, one projector, and per-field provenance — not one authoritative ledger

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes **in-flight pull-request claims**, not only what is on `origin/main`. Allocated at commit time: `release/tools/check-adr-numbers.py` reported a contiguous `001..104` with no duplicates, so this ADR takes **105**. Per the recorded convention, the later claimant renumbers if a contention materializes before merge.

## Context

Four files in the release corpus record the same fact on every release — *release X shipped, containing Y, at SHA Z*. All four were written at Stage 13, and until this release **each was written by its own code path**: four phases of the close-out script synthesised four entries, independently, from four separately-resolved sets of values.

`core/standards/duplicate-source-discipline.md` § 1 forbids exactly this shape, and its register-or-remove rule had never reached this surface. The consequence is not hypothetical. It is measurable, and it is already in the repository:

**The `DATE_ANCHOR_GRANDFATHERED` enumeration in `core/deploy/tools/generate_release_index.py` is a permanent, hard-coded, 13-version exemption list.** It exists because the INDEX emitter sampled the close-out clock while the checker asserted the INDEX Date equal the LOG's merge date. Every close-out that crossed a UTC midnight manufactured a finding **by construction** — the check reported the design working correctly, and in doing so lost the ability to report anything else. The emitter was fixed; the thirteen already-shipped rows could not be, because rewriting them would forge an audit trail. **One fact, two writers, two clocks, and a scar that cannot be removed.** That is the duplication's real cost — not the count of machine contracts, which is what the originating ticket measured.

### What the originating ticket got wrong, and why it matters here

The ticket's remedy was *"`RELEASE_LOG.md` is the single authoritative release record, and the other three are generated from it."* Three premises in that sentence are false, and one of them changes the design.

1. **The four surfaces were not hand-maintained.** The close-out already wrote all four programmatically. The defect was *no single projection*, not *no automation* — which makes the work a collapse-four-writers refactor rather than a build-three-generators project.
2. **The LOG cannot be the single source.** It carries neither a `# ` headline nor a `summary:` field. Forcing the narrative onto it would mean importing roughly 160 headlines and 156 summaries into a file that is already ~96 % prose and is the exact file a sibling card in this same release exists to bound.
3. **"Six of seven contracts become unnecessary" is false in both terms.** There are **eight** (the census omits the close-completeness check entirely), and **exactly one** retires. Six of the eight never read a derived surface at all — one of them compares a *published GitHub Release body* to an *in-repo note*, and retiring it on the ticket's arithmetic would have removed a live, unrelated control.

## Decision

**The release corpus has two typed FILE sources, two RUN-SCOPED inputs, one projector, and per-field provenance.**

### 1. Sources are typed, and provenance is per FIELD

| # | Source | Kind | Authoritative for |
|---|---|---|---|
| 1 | `release/releases/RELEASE_LOG.md` | file — event + execution record | the release fact and the **merge anchor** |
| 2 | `release/releases/notes/*_RELEASE_NOTES.md` | file — narrative record | the headline **seed** and the `summary:` **seed** |
| 3 | the close-out run anchor | run-scoped input (not a file) | the **close-out anchor** carried by the DIGEST, the note's own `date:`, and the CHANGELOG |
| 4 | the repository slug | run-scoped input (not a file) | the CHANGELOG Release URL |

No fact acquires two homes. The *release* fact is written once, in the LOG. The *narrative* fact is written once, in the note. The *theme* fact is written once, in the INDEX. That satisfies the register-or-remove rule by **consolidation** — the standard's own first-preference remedy — rather than by registering an exception.

**The INDEX is explicitly a hybrid surface:** derived on five columns, and the authoritative source of its own `Theme` column. Theme cannot move: a substantial minority of Theme-carrying rows have no release note at all, and of those that do, **zero** match their note's `summary:` — the two are independently authored prose in different registers, addressed to different readers.

### 2. The projector is clock-free and config-free BY CONTRACT

`core/deploy/tools/generate_release_index.py` is extended into the projector. Every non-file input is a **required CLI argument** — `--merge-anchor`, `--closeout-anchor`, `--repo-slug` — for every surface, whether or not that surface consumes it. Omitting any is an argparse error, never a fallback.

This is the decision's load-bearing clause, and it is a direct response to the scar in § Context. **A defaulted input is an ambient source wearing a parameter's name**, whether that ambient source is a clock or an operator config file. A projector that can reach a clock can become the second writer of a fact that already has one. A projector that cannot, never can. The module's import allow-list and the absence of any clock callsite are asserted structurally — by an AST parse, under `--self-test`, executed by CI — and never by a substring probe, because the substring `date` occurs dozens of times in that file and cannot discriminate.

The merge anchor is additionally **asserted equal** to the LOG cell it relays, so the argument is load-bearing rather than decorative: a caller that substituted a clock sample fails at the emit rather than silently minting the next grandfathering entry.

### 3. The projector emits ENTRIES, never FILES

`--emit {index,digest,changelog}` writes **one entry to stdout**. The calling close-out phase performs the insertion. The projector never rewrites a ledger, and `--self-test` asserts it cannot.

This is a measured safety property, not a stylistic preference. The **majority** of historical DIGEST headlines and CHANGELOG blocks have diverged from their emitted seed — those divergences are real editorial content, authored by the operator after emission, existing nowhere else. A whole-file regenerate destroys them, and it surfaces as a **clean diff rather than a conflict**, so nothing flags it. It is the one irreversible-shaped action this design makes available, and it is closed by construction.

The verification posture follows the same measurement rather than a preference for symmetry:

| Surface | Verify scope | Why |
|---|---|---|
| INDEX | whole file, plus a Theme round-trip limb and a row-order limb | never hand-edited outside `Theme` |
| DIGEST | the closing entry only | most historical entries carry legitimate post-emission edits |
| CHANGELOG | the closing entry only | likewise |

A whole-file verify on the DIGEST or CHANGELOG would be **red by construction on most rows** — reproducing, on two more surfaces, precisely the failure this release's own precedent spent a release removing.

### 4. Provenance is declared, asserted at emission, and gated at merge — and custody transfers after

- **Declared** — a `<!-- derived-surface: … -->` marker at the head of each derived file names its source, its projector, the **anchor** it carries, the custody rule and the never-regenerate prohibition.
- **Asserted at emission** — the calling phase treats a non-zero exit **or an empty emission** as a failure, never a silent no-op insertion. The close-out's `assert_derived_surfaces` phase FAILs on an absent closing entry.
- **Gated at merge** — the presence limbs of the completeness checks stay at **full strength**.

**Custody, stated plainly:** provenance holds at emission; the file owns its content afterwards. A historical DIGEST or CHANGELOG entry edited after emission is that file's own content and is not drift. A hand-edit to any of the INDEX's five derived columns fails the drift check; a hand-edit to INDEX `Theme` is sanctioned and newly protected.

### 5. No history is regenerated

Every pre-existing INDEX row, DIGEST entry and CHANGELOG block is byte-identical at merge. The single genuine live drift is reconciled **in the LOG**, in place, never by regenerating the INDEX.

`DATE_ANCHOR_GRANDFATHERED` **stays exactly as it is, and is now CLOSED.** Under one writer, with no clock reachable from the write path, a new member cannot be *required*. Closure was previously asserted only in prose, and a comment is not a guard: `--self-test` now asserts that every enumerated member is a **pre-reconciliation** release, so a member added for a release that closed afterwards fails — which is the standing "do not add a version here; fix the emitter" instruction made executable. **The enumeration remains the membership mechanism**; a date-cutoff *membership* form was deliberately rejected by the original author because it can silently widen, and that reasoning still holds. The named constant is the assertion's bound and nothing more.

### 6. The three derived ledgers are records, classified `Important`

`core/governance/RECORDS_POLICY.md` gains **explicit** rows for all three, in both the classification table and the retention schedule, with a **never-regenerated-whole** disposition.

They are **not** `Reference` — that class is defined in the policy as *supersedable by re-acquisition*, and for these files re-acquisition **means regeneration**, which is the destruction. They hold **317 sole-copy fields** whose only home is the file itself. Classifying them by their emit path alone would have resolved them to the policy's `DEFAULT = Reference` row and made the destructive act permitted at exactly the moment this change made it possible.

## Machine-contract census — per contract, read from code

The ticket's aggregate claim is replaced by a per-contract verdict. **1 retires · 7 survive** (one carrying a *staged* posture flip).

| # | Contract | Verdict | Basis |
|---|---|---|---|
| 1 | LOG↔INDEX parity (`deploy.sh` Check 23) | **SURVIVES · flip STAGED, not taken** | Not vacuous: the INDEX is append-written per release, so a missed append or a hand-edit still diverges. Normalization removes the *false*-positive class warn-mode was justifying — but the flip's own precondition is a post-merge observation window, which no release can satisfy inside its own merge. |
| 2 | release-corpus completeness (Check 32) | **SURVIVES UNCHANGED** | Its INDEX and DIGEST limbs are **presence** assertions. A projector writing to stdout guarantees the *correctness of an emitted entry*; **presence in a file** is a property of the caller's insertion, which this design deliberately leaves in the shell. The two are different propositions and only the first is newly guaranteed. |
| 3 | release-body drift (Check 47) | **SURVIVES UNCHANGED** | Compares the *published GitHub Release body* against the *in-repo note*. **Neither surface is a ledger.** |
| 4 | close-completeness (Check 48) | **SURVIVES UNCHANGED** | Omitted from the ticket's census entirely. Its three ledger limbs are presence assertions — same reasoning as #2. |
| 5 | `lint_release_corpus.py` sub-check (c) — INDEX row count | **RETIRES** (identifier reserved) | Its entire content was `index_rows < log_rows`, strictly weaker than Check 23's coexistence limb, which names the drifted version rather than a count and also catches a same-count-different-set INDEX. |
| 6 | `claim-version.sh` DEPLOYED enumeration | **SURVIVES UNCHANGED** | Reads the LOG (a source) for version-freeness. Never touched a derived surface. |
| 7 | close-out head-append + row-match | **SURVIVES** | Operates on the LOG. The derived-surface idempotency guards survive unchanged as append-idempotency. |
| 8 | the `**Velocity:**` accessor | **SURVIVES UNCHANGED** | Parses the LOG's H4 prose. Source-side. |

**Six of the eight never read a derived surface.** The duplication's cost was the grandfathering scar, not the contract count — and that scar goes vestigial under one writer.

## Alternatives considered

**A — One source: import headline, summary and theme into the LOG as structured fields.** This is what the ticket literally asks for, it produces a genuinely single authoritative file, and it makes `Theme` recoverable if the INDEX were ever lost. **Rejected**, and surfaced explicitly at Collective Review rather than decided silently, because it is a content migration of ~160 headlines, ~156 summaries and every theme cell; it breaks all four field-positional consumers of the LOG's schema; and it grows the exact file a sibling card in this release exists to bound. It optimizes for a file count while degrading the two properties the release actually needs — a bounded LOG and a stable field-positional schema.

**B — A two-column `RELEASE_THEMES` sidecar, making the INDEX 100 % derived.** Genuinely close. It would remove the hybrid-surface concept entirely and give `Theme` a home that survives the INDEX being rebuilt. **Rejected** because it adds a fifth artifact to a change whose thesis is that there are too many, and because the hybrid declaration costs one table row. Recorded here so a future release can flip cheaply.

**C — Build a sibling projector module rather than extending the existing one.** **Rejected**: the existing module already owns the LOG parser, the Theme round-trip, the orphan guard, the grandfathering set and the `--verify` contract the drift check invokes; a sibling forks the parser or needs cross-directory import surgery. **D — Extend and rename.** Rejected: it converts a zero-mover release into a mover, firing three structural gates, for a naming benefit. The module name understating its scope is recorded as **accepted debt**, stated in its own docstring; a rename is a legitimate follow-on.

**E — Let the projector sample its own clock, or read the operator config for the slug.** **Rejected on this repository's own precedent.** A sibling fix in this same code path removed an operator-local `date.today()` fallback for exactly this reason: it *"produced a plausible-looking wrong row rather than an error, and it fired silently."* A projector clock would take one fact with one sampling site and give it three.

## Consequences

**Positive.** The release fact has one writer. Growth is O(1) write paths per release instead of O(4). The grandfathering enumeration stops accreting and its closure is a tested property rather than a comment. Two live defects are closed that no ticket named: a bare regenerate deleted the INDEX header paragraph declaring its own date anchor, and `Theme` had no integrity guard anywhere in the platform. Entry synthesis moves out of untestable shell heredocs into a module with a self-test that CI executes.

**Negative / accepted.** The module's name understates its scope. The projector gains four required arguments, so its CLI is no longer minimal — the caller must pass values it already holds. Insertion remains in the shell, which is deliberate but means generator-correctness and file-presence stay separate propositions requiring separate gates.

**Reversibility: MODERATE / confidence HIGH.** `git revert -m 1` restores every file's bytes. It does **not** restore provenance: a reverted repository's next close-out writes by the old four-writer path, and anything authored into a derived surface between merge and revert is regenerated away rather than conflict-flagged. The mitigation is § 5 — because no history is regenerated, the revert surface is one LOG cell plus tooling.

## References

- [`release-corpus-schema.md § Derived-Surface Contract`](../references/standards/release-corpus-schema.md) — the register this ADR decides
- [`stage-13-close.md § Phase B`](../references/pipeline/stage-13-close.md) — one source write plus three projections
- [`RECORDS_POLICY.md`](../../core/governance/RECORDS_POLICY.md) — the `Important` classification and the never-regenerated-whole disposition
- [`duplicate-source-discipline.md`](../../core/standards/duplicate-source-discipline.md) — the register-or-remove rule this satisfies by consolidation
- [`date-variable-convention.md § Emission-Time Anchors`](../../core/standards/date-variable-convention.md) — the merge / close-out / emission anchor taxonomy
