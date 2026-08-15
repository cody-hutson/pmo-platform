---
title: Release Plan — check-fail-open-elimination (a broken measurement becomes distinguishable from a clean result)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: check-fail-open-elimination
release_class: novel
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-14, domain: software }
reversibility: MODERATE / Confidence HIGH
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — check-fail-open-elimination

> **Milestone:** `check-fail-open-elimination` (319) · **Release Class:** `novel` (Standard engagement / **Deep** Stage-9 review / Stage-5 activation bias ALL / 30-day outcome window) · **Version:** `{{RELEASE_VERSION}}` — **bound at the Stage-12 atomic claim (ADR-092); unbound through Stages 4–11** · **Scope:** 6 issues, 18 raw pts × 1.15 = **21 effective** (band 15–25, PASS) · **Topology:** D-C `SINGLE` · **Concurrency posture:** P0 fully-serial · One release branch, one PR, one merge gate · **Branch:** `release/check-fail-open-elimination` (slug-primary, no version stem).

This file is the Stage-4 release plan, committed as **Engineering Commit 0** on the release branch per the D-C SINGLE topology. It is reconciled with every decision rendered since that plan was written — the Stage-4 operator gate, the six Stage-5 design specs and their decision records, and the **Collective Review scope-lock**. Superseded Stage-4 statements are marked where they land rather than silently overwritten, so the record shows what moved and why.

## Issue References

Card index for this release. Every issue reference in this plan resolves against this table — including the File Change Matrix rows, whose Issue column indexes back here rather than making free-standing prose references. This block is positioned **before any reference in the file** because `block-fragile-refs.sh` rule `BLOCK-FRAGILE-REF-003` evaluates release-plan files positionally.

| Card | Size | Wave | One-line scope |
|---|---|---|---|
| #4907 | `size:M` | W1 | The umbrella. A degraded-state emit contract — a check reports its own measurement status — frozen as a rider on the probe-validity discipline, realized as a sixth emitter-family class member |
| #4890 | `size:S` | W2 | Check 56's M2 leg adopts the ADVISORY emitter class and its own check id, so a mode graduation is structurally unable to reach it |
| #4898 | `size:S` | W2 | Indicator 6 stops rendering an unmeasurable denominator as a clean absence; a two-layer guard separates read-integrity failures from label-gap understatement |
| #4908 | `size:M` | W3 | A design that claims a non-blocking posture must trace the aggregation rule that actually decides — a new conditional Stage-5 sub-step plus its gate criterion |
| #4458 | `size:M` | W3 | The count-vs-structure check stops reporting the whole baseline as false STALE under a path-scoped invocation; both legs root-caused, not one |
| #4705 | `size:S` | W3 | The version-freeness CI job injects a candidate, so the resolver's independent-candidate branch stops being unreachable |

**Marker cards named by this release but NOT in it.** #4912 is #4907's AC-4 generalization fixture — read, mapped, not edited. #5071, #5240 and #5249 are further instances of the same fail-open shape, deliberately unbundled (pulling them in breaches the 25-pt ceiling). #3711 is the closed card whose discharged acceptance criterion two stale `deploy.sh` comments still cite; #3820 / #3821 are the unrelated sibling cards that silently fixed two of #4907's five enumerated instances. #5269 is the in-flight sibling release PR that contends on the version slot.

## Release Identity — slug-primary, version unbound

The plan file, the branch, and all hub state are keyed on the milestone **slug**, never a version. Through Stages 4–11 this file carries an unresolved `{{RELEASE_VERSION}}` placeholder and **no baked version number anywhere**, per ADR-092: the version binds only at the Stage-12 atomic compare-and-swap, where git's ref CAS is the authority.

**Commit-0 version re-verify — PROCEED.** Run at Engineering Commit 0 against freshly fetched authoritative refs, as the D-Version determination's first arbitration rung requires. It is a single detect-and-HALT, not a retry loop.

| Arm | Probe | Observed | Control (sensitivity) |
|---|---|---|---|
| Tag freeness | `git ls-remote --tags origin 'refs/tags/v4.25*'` | **0** | the same predicate for the anchor returns **2** (annotated + peeled); 334 tags visible, so the extraction is non-empty |
| Ledger freeness | `git show origin/main:release/releases/RELEASE_LOG.md` line-anchored row probe | **0** | the anchor's row returns **1**; 1430 lines read |
| Sibling claim | `gh pr view` on the in-flight release PR | **OPEN, draft, unmerged** — the slot is not claimed | — |

Both authorities agree at the anchor. Recomputed next-free for bump-class `minor` **equals the Stage-4 provisional determination**, so the plan file is written at this slug-keyed path and nothing is baked. No HALT condition fired.

| Rung | Obligation |
|---|---|
| Engineering Commit 0 (this file) | Carry the placeholder; bake nothing. **Discharged — PROCEED, recorded above.** |
| Stage 9 | Mid-pipeline divergence re-check on the file-divergence axis; still non-binding |
| Stage 12 pre-merge | Freeness re-check across all arms |
| Stage 12 atomic claim | **The only binding moment.** Re-derive next-free; the git ref CAS is the authority |

## Release Outcome Statement

**AFTER** — A broken measurement is distinguishable from a clean result: every check reports degraded/unknown rather than silently passing.

**BEFORE** — Checks fail open — a missing label reads as "none scaffolded", a path-scoped invocation reports the entire baseline as false STALE (71 entries at the release base), and a version-freeness gate never injects a candidate.

**Success Indicator:** every ticket closes with its acceptance criteria verified, and the gate or check each one names demonstrates a real failure on a fixture before it is trusted.

## Reconciliation — what moved after the Stage-4 plan

| # | Section | Stage-4 statement | Reconciled statement | Basis |
|---|---|---|---|---|
| 1 | Release Class | Declared `cross-cutting`; spoke recommended `novel` | **`novel`** — rendered at the Stage-4 operator gate. Zero of the three `cross-cutting` triggers fire (1 stage-spec file against ≥3; 0 of seven governance surfaces against ≥3; 2 dependency edges against ≥3). `effective_pts = round_half_up(18 × 1.15) = 21` ≤ 25 | Stage-4 gate decision D2 |
| 2 | Raw scope | Declared 16 pts | **18 pts.** The six scope rows sum to 18 against the issues' own `size:` labels; the prior amendment subtracted a removed card's points without re-summing. `16 × 1.3` and `18 × 1.15` both round to 21, which is why the error survived a recomputation that re-checked the product and not the operands | Stage-4 gate, hub-verified |
| 3 | #4705 disposition | Premise falsified by two merged mainline commits after filing | **RE-SCOPE, keep in bundle** — re-framed from *"the gate cannot detect a collision"* to *"the CI job never injects a candidate"*; severity P1 → P2; the satisfied criterion retained as a read-only regression guard | Stage-4 gate decision D3, Tier 2 |
| 4 | Concurrency posture | Undeclared | **P0 fully-serial** at Stage 6. The contention map concentrates on one file; posture parallelism is opt-IN | Stage-4 gate decision D4 |
| 5 | #4907 live instance set | AC-2 named instances {1, 2, 3, 4} | **{1, 2}.** Instance 4 shipped under an unrelated card ~17.5 h after this card's own reproduction anchor; instance 3 shipped under a second unrelated card ~3.3 h after the card was filed. Both narrowings established by ancestry, not inferred from timestamps. Instances 3, 4 and 5 are **regression arms, not build targets** | Stage-4 gate (Tier 1) + Stage-5 typed drift report (Tier 1) |
| 6 | #4907 primitive shape | The card asked which **one** of four prior-art mechanisms becomes the shared primitive | **The question was a category error, and naming it is the finding.** The four are orthogonal — emitter, transport, terminal-state token, partial-state token. Selected: the **composed contract**. Runner-up rejected on cross-surface reach | Stage-5 design D-1 |
| 7 | #4907 file surface | 6 paths in the Stage-4 matrix, including the telemetry tool | **5 paths.** The telemetry tool leaves this card's matrix — it is #4898's deliverable, and the primitive's whole value is that #4898 emits in its vocabulary rather than #4907 reaching into #4898's surface. **Stage-4 contention C-2 dissolves by design, not by drift** | Stage-5 design, Blast Radius |
| 8 | #4907 Change-2 deletion range | `deploy.sh:9853–9862` | **`:9853–9858`.** The stated range overshot the prose anchor by 4 lines into a live, load-bearing paragraph that continues past `:9866`. A mechanical range delete would have truncated it mid-argument and left the remainder orphaned. Raised by a Wave-2 spoke reading a range that was not its own; hub-verified before acceptance | Stage-5 Tier 1 [ADJUST], hub-verified |
| 9 | #4890 emitter class | Implied the new NOT-EVALUATED emitter | **ADVISORY, not NOT-EVALUATED.** M2 *measures*; what it cannot do is separate a description that legitimately lags membership from a real divergence. That is the ADVISORY predicate verbatim, so its mandated emitter is the existing advisory member | Stage-5 design for #4890, D-1 |
| 10 | #4890 check id | Unstated | **A new advisory-class id.** Keeping the shared id would write *"this check is never enforce-capable"* about an id that **is** enforce-capable, into the warn log the enforce-flip decision is read from — relocating the defect from a comment into an emitted record | Stage-5 design for #4890, D-2 |
| 11 | #4898 transport | W1 mandates a distinct exit code as the cross-process transport | **In-band, in the emitted line — and this is composition, not deviation.** That tool's consumer treats any non-zero exit as a hard failure, so an exit-code emit would convert a measurement outage into a **gate**, which the rider forbids in terms. **Transport is conditional on the KIND of condition:** a measurement outage never gates; an input failure may | Stage-5 designs for #4898 and #4458, resolved oppositely and both correctly |
| 12 | #4898 documentation surface | The card named the deploy-tools README | **The telemetry standard instead.** That README declares its coverage rule exhaustive over the deploy-tools directory's top level only, and this tool lives elsewhere; adding a row would violate that README's own invariant. The release-wide vocabulary criterion's graded surface is amended accordingly | Stage-5 Tier 1 [ADJUST] |
| 13 | #4908 obligation trigger | AC-2's method quotes one of the card's two Proposed-Change sentences | **Two-limb trigger.** Under the first limb alone, recall against the three known instances is 2 of 3 — the Wave-1 transport claim changes no set membership and would not have fired. With both limbs, recall is 3 of 3 | Stage-5 Tier 1 [ADJUST] |
| 14 | #4908 gate authority | Spoke recommended gate-blocking; hub counter-proposed a shadow → warn → enforce ladder | **GATE-BLOCKING**, operator-rendered. The hub's counter-case — a new obligation landing gate-blocking on day one carries no drain evidence behind it — is preserved as a recorded tradeoff, not re-argued | Collective Review decision D2 |
| 15 | #4458 root cause | The card named one leg | **Two independent legs.** A path-scoped invocation was measured returning `KNOWN=0 STALE=71` at both scopes tested, which the card's single named root cause does not explain. Fixing one leg alone could leave the other producing a different false clean | Stage-4 risk R-8, confirmed at Stage 5 |
| 16 | ADRs | None allocated | **ADR-134** allocated to #4907, re-derived against `origin/main` at Commit 0. **The other five cards each recorded a negative determination with rationale** — none is a skip | Stage-5 designs + § ADR Allocation |
| 17 | Scope | Six cards, unlocked | **LOCKED** — six cards as designed. No merge, split or drop; all File Change Matrices frozen. **Every card required correction; none required dropping** | Collective Review decision D1 |

**What Stage 5 established about this bundle, carried forward because it changes how Stage 8 must grade.** The premises held; the *proposed mechanisms and the acceptance criteria* repeatedly did not. Three cards carried acceptance criteria that would have certified the very defect they were written to eliminate — one unrunnable as written (a control arm over a population of zero), one whose proposed discriminator produced four false positives at the release base, one satisfiable by a still-broken tool. **A criterion is a measurement too.** Stage 8 grades against criteria; on this release the criteria themselves are part of what is under test.

## Dependency Graph

Directional. An edge means *upstream must land first, because downstream's content or grading depends on it.*

```
#4907 ──(subsumption; #4907 AC-2 grades this card's output)──▶ #4890
  │
  └────(subsumption; #4907 AC-2 grades this card's output)──▶ #4898

#4908   (no in-bundle edge — self-declared independent, verified)
#4458   (no in-bundle edge — different failure axis)
#4705   (no in-bundle edge)

External, SATISFIED:  #3711 ──▶ #4890
```

**Edge count: 2 hard directional edges.** Both originate at #4907, and the coupling is *grading*, not merely preference: #4907's AC-2 cannot close until #4890's and #4898's surfaces satisfy it. Building either instance before the convention exists produces a local guard the primitive was designed to subsume.

**#4458 is the odd card out on the fail-open axis.** It fails *closed* — a false STALE, a false alarm, the opposite direction from a silent green. It belongs here under the broader theme (*a check's verdict does not mean what it claims*) but does not inherit the degraded-state convention as a build dependency. It does, however, **consume** the new emitter: its design routes Check 63's degraded status through it. Fully parallel; consumer, not dependent.

**Native dependency-link probe: BROKEN — reported unusable, not clean.** The sensitivity arm (six control issues chosen because several carry body-declared dependencies) returned zero on all six, so *"these cards carry no native edges"* cannot be distinguished from *"this endpoint does not reflect edges in this repository."* Nothing is asserted about native dependency state anywhere downstream. Every edge above is derived from issue-body text, which is independently sufficient for sequencing.

## Implementation Sequence

Dependency-ordered, in three waves, dispatched **P0 fully-serial** — one Engineering spoke at a time, the next waiting until the prior commit lands on the release branch. The waves govern sequencing; the posture governs concurrent write access.

| Wave | Cards | Why this wave | Parallel-safe within wave? |
|---|---|---|---|
| **W1** | **#4907** | Sole foundation. Establishes the convention and the shared primitive W2 inherits. Nothing else can be graded until it exists | n/a (singleton) |
| **W2** | **#4890**, **#4898** | Both are instances of W1's convention and must adopt its vocabulary. **Zero file overlap with each other** after the Stage-5 matrices froze | **Yes** (by file surface; serialized anyway under P0) |
| **W3** | **#4908**, **#4458**, **#4705** | Independent of the convention and of each other. Placed after W2 to keep `core/deploy/deploy.sh` edits serialized behind #4890 | **Yes** (by file surface; serialized anyway under P0) |

**Concurrence with the declared internal sequence.** The milestone declares a strict chain; the wave form is a valid linearization of the same DAG that does not serialize cards with no edges between them. Every edge the chain encodes is preserved.

**Delivery strategy.** Single release branch, one PR, one merge — per the milestone-is-one-PR discipline. This plan file commits as **Engineering Commit 0** on that branch under D-C SINGLE topology.

## Stage Applicability Matrix

Stages 5–8 are per-issue; Stages 9–13 are release-scoped singletons.

| Card | S5 | S6 | S7 | S8 | Note |
|---|---|---|---|---|---|
| #4907 | APPLY | APPLY | APPLY | APPLY | Design-heaviest card. Consumer enumeration is design work, not build work |
| #4890 | APPLY | APPLY | APPLY | APPLY | AC-2 is an explicit dynamic proof; S7 is load-bearing and cannot be reduced |
| #4898 | APPLY | APPLY | APPLY | APPLY | S7 needs two fixtures whose outputs must differ. The tool already ships a self-test suite — extend it, do not author a parallel harness |
| #4908 | APPLY | APPLY | **REDUCE** → doc-conformance | APPLY | No executable surface. Run the replay and its control as a doc-conformance pass; do not author tests |
| #4458 | APPLY | APPLY | APPLY | APPLY | S5 root-caused both legs before either was fixed |
| #4705 | APPLY | APPLY | APPLY | APPLY | Its sensitivity arm (*a passing run is not evidence*) is the whole card |

**No stage is skipped outright for any card.** One REDUCE, justified by absence of an executable surface, not by change size. **S9 Plan Review: APPLY — Deep.** Stages 10 and 11 are N/A for the Claude Code path (PR review *is* the dry run; git history *is* the snapshot).

## File Change Matrix

Consolidated from the six Stage-5 design specs, reconciled to the Stage-5 and Collective-Review decisions. **21 distinct paths.**

| Card | Path | Intent |
|---|---|---|
| #4907 | `core/disciplines/review-discipline-principles.md` | MODIFY — the PV-7 measurement-state rider in § 8.1, the § 8.2 record field, § 8.3 row 13, and the § 8.4 count and class-ordinal reconciliation |
| #4907 | `core/deploy/deploy.sh` | MODIFY — a sixth emitter-family class member adjacent to the advisory member; 9 divergent state-token spellings reconciled; the obsolete block-level M2 comment replaced |
| #4907 | `core/deploy/tests/test_g1_form_family.sh` | MODIFY — **coordinated edit, declared not absorbed.** The harness extracts a `deploy.sh` region verbatim and executes it; its assertion matches the space-form token and must be re-spelled in the same commit |
| #4907 | `core/deploy/tools/README.md` | MODIFY — three tool rows restate the degraded state in the frozen vocabulary, replacing three divergent prose renderings. **Row 67 is shared with #4890 — see the Contention Map** |
| #4907 | `release/references/how-to/hub-spoke-bridge.md` | MODIFY — cascade only: two literal element-series enumerations extend to the new rider |
| #4907 | `core/ADRs/ADR-134-degraded-state-emit-contract.md` | **ADD** — the D-1 primitive selection and the rejected-alternative grounds |
| #4890 | `core/deploy/deploy.sh` | MODIFY — the M2 call site and its adjacent call-site comment; two extraction sentinels |
| #4890 | `core/deploy/tests/test_check56_m2_advisory.sh` | **ADD** — the AC-2 dynamic proof, six arms, emitters deliberately **not** stubbed |
| #4890 | `.github/workflows/install-tests.yml` | MODIFY — one named step; the suite is invoked by explicit named step, not by glob |
| #4890 | `core/config/allowlists/script-execution-allowlist.txt` | MODIFY — **companion obligation**, four invocation-form rows for the added script |
| #4890 | `core/deploy/tools/README.md` | MODIFY — row 67's M2 clause; the current text is false today |
| #4898 | `release/tools/compute-close-class-telemetry.sh` | MODIFY — a two-layer guard: deterministic read-integrity, then a corroborative population cross-check; state and token emit vars; new self-test arms |
| #4898 | `release/tools/tests/test_close_class_telemetry.sh` | MODIFY — a new denominator-integrity group with arm-presence, mutation and extraction controls |
| #4898 | `release/references/standards/close-class-telemetry.md` | MODIFY — **the real doc surface**, three in-file statements |
| #4898 | `.github/workflows/release-tooling-smoke.yml` | MODIFY — cascade only: the stated arm count, at two occurrences |
| #4908 | `release/references/pipeline/stage-05-solutioning.md` | MODIFY — a conditional Phase A4.3 pointer, a new section carrying its block schema and load-bearing test, and the gate criterion that forces it |
| #4908 | `core/disciplines/review-discipline-principles.md` | MODIFY — **one `## See also` bullet**, the reciprocal pointer the cross-issue cohesion criterion grades. Nothing else in the file is touched |
| #4458 | `core/deploy/tools/check-count-structure.py` | MODIFY — scope resolver, reconciliation predicate, a scope record and its input-failure exit |
| #4458 | `core/deploy/deploy.sh` | MODIFY — Check 63 branches the scope record **before** reading any counter, per the Register-A binding rule; degraded routes through the new emitter |
| #4458 | `core/deploy/tools/README.md` | MODIFY — row 76: path-scoped semantics, the scope record, the state tokens |
| #4458 | `core/deploy/tools/run-count-structure-fixtures.sh` | MODIFY — a scope arm |
| #4458 | `core/deploy/tests/fixtures/count-structure-fixtures.txt` | MODIFY — scope-arm fixture cases |
| #4705 | `.github/workflows/version-freeness.yml` | MODIFY — the arm step, plus the header comment whose assignment claim, open-bug clause and falsification recipe the change makes stale |
| #4705 | `core/standards/gate-efficacy-standard.md` | MODIFY — one register row only |
| #4705 | `core/deploy/deploy.sh` | MODIFY — a hermetic witness triple appended to the existing self-test group. **No emitter, no check number, no mode dial** |
| #4705 | `core/deploy/tests/test_version_freeness_injection.sh` | **ADD** — the live arm suite |
| #4705 | `core/config/allowlists/script-execution-allowlist.txt` | MODIFY — **companion obligation**, four invocation-form rows for the added script |
| — | `release/releases/plans/check-fail-open-elimination_RELEASE_PLAN.md` | This file — Engineering Commit 0, then accreted through the release |

Machine-readable path list for deterministic Stage 7 / 8 / 9 chip extraction — **21 paths, one per line**:

```
.github/workflows/install-tests.yml
.github/workflows/release-tooling-smoke.yml
.github/workflows/version-freeness.yml
core/ADRs/ADR-134-degraded-state-emit-contract.md
core/config/allowlists/script-execution-allowlist.txt
core/deploy/deploy.sh
core/deploy/tests/fixtures/count-structure-fixtures.txt
core/deploy/tests/test_check56_m2_advisory.sh
core/deploy/tests/test_g1_form_family.sh
core/deploy/tests/test_version_freeness_injection.sh
core/deploy/tools/README.md
core/deploy/tools/check-count-structure.py
core/deploy/tools/run-count-structure-fixtures.sh
core/disciplines/review-discipline-principles.md
core/standards/gate-efficacy-standard.md
release/references/how-to/hub-spoke-bridge.md
release/references/pipeline/stage-05-solutioning.md
release/references/standards/close-class-telemetry.md
release/releases/plans/check-fail-open-elimination_RELEASE_PLAN.md
release/tools/compute-close-class-telemetry.sh
release/tools/tests/test_close_class_telemetry.sh
```

**New-executable companion obligation.** The matrix carries two `ADD` rows for tracked `*.sh` files, and each therefore carries its `script-execution-allowlist.txt` companion rows — four invocation forms per script, the established pattern. No new tracked executable is added by #4907 or #4458.

**Explicitly NOT edited, stated so the omission reads as a boundary rather than a miss.** The three deliberately-mutated control-arm fixture surfaces — `core/deploy/tools/check-count-structure.py`'s in-source control strings, `core/deploy/tests/fixtures/count-structure-fixtures.txt`'s stated-cardinality cases, and `core/hooks/testdata/count-structure-fixtures.txt` — carry a **wrong count on purpose**, to prove the count-vs-structure predicate detects and discriminates. Mechanically updating them to match the live figure would silently break both control arms and make that check report a passing control on a probe that no longer discriminates. **Stage 6 must not run a find-and-replace across them.** #4458's edits to two of those paths are scope-arm additions, not count updates.

## Contention Map

### Within-release

| ID | Pair | Shared file | Class | Resolution |
|---|---|---|---|---|
| **C-1** | #4907 × #4890 | `core/deploy/deploy.sh`, Check 56 M2 region | **line-range-overlap (HIGH) → resolved to disjoint at Stage 5** | The two cards' Stage-5 matrices partition the region cleanly: #4907 replaces the **block-level** comment and inserts the new emitter far above; #4890 replaces the **call-site** comment, changes the call, and adds two sentinels. Neither touches the other's lines. Wave ordering W1→W2 plus P0 serial dispatch is the belt; the partition is the braces |
| **C-2** | #4907 × #4898 | `release/tools/compute-close-class-telemetry.sh` | **DISSOLVED by design** | The telemetry tool left #4907's matrix at Stage 5. The Stage-9 contention re-measure should read C-2 as *resolved-by-design*, not as an unmeasured baseline row |
| **C-3** | #4907 × #4890 × #4458 | `core/deploy/tools/README.md` | **append-pattern (LOW), except row 67** | Distinct table rows merge cleanly at different offsets. **Row 67 is the exception and is a coordination note, not a scope change:** #4907 appends a rider sentence after the scan-state sentence; #4890 replaces the M2 clause in the same row. Apply as two targeted in-row edits, **never as competing row rewrites** — the risk is a whole-row regeneration by the second writer silently discarding the first. #4898 dropped out of this file entirely at Stage 5 |
| **C-4** | #4907 × #4908 | `core/disciplines/review-discipline-principles.md` | **NET-NEW at Stage 5, disjoint-range (LOW)** | #4907 edits § 8 and the element-series enumeration; #4908 adds one `## See also` bullet at the file's tail. Different sections, no overlap. Recorded because the Stage-4 map predates #4908's matrix |
| **C-5** | #4907 × #4458 × #4705 | `core/deploy/deploy.sh` | **disjoint-range (LOW)** | #4907 at the emitter helpers and the Check 56 block comment; #4458 in the Check 63 block; #4705 in the self-test group and one check header. Non-overlapping hunks in a file of over thirteen thousand lines |
| **C-6** | #4890 × #4705 | `core/config/allowlists/script-execution-allowlist.txt` | **append-pattern (LOW)** | Two independent four-row appends for two different scripts |

### Cross-release

**Baseline pin (audit-baseline discipline):** `origin/main` @ `8f48357f`, which is also this release's base. **Population: n=1 sibling** — one open draft release PR on a different milestone, touching 17 files.

| Contended path | `overlap_class` | Disposition |
|---|---|---|
| `core/deploy/deploy.sh` | **disjoint-range** | LOW. Structurally contended, operationally clean — zero range intersection between the sibling's hunks and this release's target regions |
| `core/standards/gate-efficacy-standard.md` | **disjoint-range, offset-shifting** | LOW-MODERATE. The sibling appends a row above the row #4705 must edit, shifting it. **Re-locate that row by content, never by line number**, and update it rather than annotating it |
| Version slot | **Tier-S serialization edge** | Both releases contribute the same token. Arbitrated by the three rungs in § Release Identity; the Commit-0 rung has **discharged PROCEED** |

**Baseline-pin residual, stated plainly.** This roster carries **no verdict**. A sibling that branches, pushes or opens a PR after the pin is invisible to it. Stage 9 re-measures this population fresh pre-GO and renders the contention verdict; this table is that phase's baseline input, never its substitute.

## ADR Allocation

Re-derived against `origin/main` at Commit 0 — **not** against the worktree, and **not** reserved at Stage 5. The reservation was deliberately deferred because a sibling release PR was in flight, and reserving above an unmerged sibling's claim blocks the repo: a gap is unrecoverable, a duplicate is tooled.

**Measurement:** the numbering oracle (`release/tools/renumber-adr.py --next-free`) returns **133**. Independent cross-check against `origin/main` across **both** ADR directories: 132 records, max `ADR-132`, contiguous through the tail — so 133 is next-free by two methods that agree. The in-flight sibling PR adds **no** ADR record (it edits the numbering tool itself), so the number is uncontended.

| ADR | Card | Home | Subject |
|---|---|---|---|
| **ADR-134** | #4907 | `core/ADRs/` | The degraded-state emit contract: a check's emitted state set carries a distinct member for every reachable state of its predicate, degraded and clean never share a member, and the degraded member never gates |
| 134 | — | — | Free at Commit 0 |

**The other five cards each recorded a negative ADR determination with rationale** — a threshold evaluated, not a step skipped. The most instructive is #4890's: once the umbrella's ADR lands, its own decision is no longer non-obvious, because that card *applies* the contract rather than deciding it. **Numbering is global across both directories in one sequence.**

## Risk Register

| ID | Severity | Risk | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| **R-1** | HIGH | **Version contention.** An in-flight sibling release PR is a plausible claimant of the same slot | Expected under slug-primary identity, not exceptional — a lost race costs a recomputation, not a rename cascade. Three rungs arbitrate; rung 1 has **discharged PROCEED**. **Do not treat the slot as owned** | CHEAP · HIGH |
| **R-2** | HIGH → **MODERATE** | **C-1 same-region contention** on the Check 56 M2 block | Downgraded at Stage 5: the two cards' matrices partition the region into disjoint line sets. Wave ordering plus P0 serial dispatch remains in force | MODERATE · HIGH |
| **R-3** | HIGH → **RESOLVED** | **#4705's premise was falsified** by merged mainline after filing | Tier 2 [SCOPE CHANGE] rendered at the Stage-4 gate: re-scope, keep in bundle. The residual is real and governance-named as a precondition on any future enforce flip | CHEAP · HIGH |
| **R-4** | MODERATE → **RESOLVED** | **#4907's live-instance set was stale** — a spoke reading AC-2 literally would build a fixture for an instance that already passes and report a vacuous green | Narrowed twice with ancestry evidence, {1,2,3,4} → {1,2}. Instances 3, 4 and 5 are regression arms | CHEAP · HIGH |
| **R-5** | MODERATE | **Cross-PR row shift** on the gate-efficacy register | Re-locate by content, never by line number. Reconcile the row; do not annotate it | CHEAP · MEDIUM |
| **R-6** | MODERATE → **RESOLVED** | **The declared size was wrong** | Corrected to 18 raw / 21 effective. Band disposition unchanged (PASS) — a correctness fix, not a re-bundle trigger | CHEAP · HIGH |
| **R-7** | MODERATE | **Output-vocabulary blast radius.** Every card except #4458 changes an emitted output state. If any consumer-enumeration criterion is waived, a downstream consumer keying on the old two-state output breaks silently — the exact failure class this release exists to eliminate | **Do not waive any consumer-enumeration criterion.** Each requires a recorded non-empty count. Enforced release-wide by CIAC-2. Discharged so far: #4907 enumerated 14 consumers across 4 outputs, #4890 11 across 4, #4898 17 across 4 | MODERATE · HIGH |
| **R-8** | MODERATE → **RESOLVED** | **#4458 may have two defects, not one** | Confirmed at Stage 5: two independent legs. Both root-caused before either is fixed | CHEAP · MEDIUM |
| **R-9** | LOW → **RESOLVED** | Release Class fired zero of its declared triggers | Re-rendered `novel` at the Stage-4 gate | CHEAP · HIGH |
| **R-10** | LOW | **The native dependency-link probe is BROKEN** (sensitivity arm returned zero). Whether these cards' edges are natively mirrored is **unmeasured**, not clean | Assert nothing about native-dep state downstream. The body-derived graph is independently sufficient. Worth an observation-tier intake | CHEAP · HIGH |
| **R-11** | LOW → **MODERATE after W2 adopts** | **Rollback of the shared vocabulary.** Reverting after downstream consumers adapt strands two adopted tokens with no frozen home | Additive by construction: Register A is frozen with zero renames, so no live consumer changes meaning, and the terminal-token reconciliation is confined to one file plus one test harness. A post-adoption revert costs a **token-orphaning**, not a behavior regression. **Named residual, accepted at this tier** | MODERATE · HIGH |
| **R-12** | MODERATE | **The verbatim-extraction test harness is the one real implementation hazard.** It extracts a `deploy.sh` region byte-for-byte and executes it, and the re-spellings sit inside that region | Re-spell and re-run the harness in the **same commit**. Marker lines must not move — moving or renaming one makes extraction fail loudly. **Stage 7 must exercise it as a named arm** | CHEAP · HIGH |
| **R-13** | MODERATE | **A new obligation ships gate-blocking on day one with no drain evidence behind it**, which is how false-failure debt accumulates | Operator-rendered and recorded rather than re-argued. The mitigation is the obligation's own two-limb trigger with an explicit does-NOT-fire set and an introducing-release exemption | MODERATE · MEDIUM |

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints. Each spans ≥2 cards, requires no dependency edge, and is graded on the **merged PR** at Stage 9.

- [ ] **CIAC-1 (#4907 × #4890 × #4898 on the degraded-state token vocabulary):** every degraded or unknown state token emitted by the Check-56 M2 leg and by Indicator 6 is drawn from the vocabulary the convention records — no third spelling, and no emitter inventing a local token. The deploy-tools README rows for the touched tools state the degraded state in that same vocabulary. **Amended for #4898:** its graded surface is the telemetry standard, not that README — that tool structurally cannot gain a row there under the README's own coverage rule. *Method:* extract the sanctioned token set from the governing discipline and assert the extraction is **non-empty**; then grep each emitter and each graded row for a degraded-state token outside that set; assert zero out-of-set tokens. *Control:* the same grep against a deliberately out-of-vocabulary fixture string returns non-zero.
- [ ] **CIAC-2 (all check-bearing cards on the release's verification evidence):** the milestone's own Success Indicator holds for every one. For each card, the merged PR carries a recorded run in which the check reports **non-clean on a degraded or defective fixture** (sensitivity arm, observed non-zero) **and** a paired run in which it reports **clean on a genuinely-clean fixture** (specificity arm, observed zero). **A card whose evidence carries only the clean arm has not satisfied this.** *Method:* read the PR's verification-evidence section; assert one sensitivity arm and one specificity arm recorded per card, each with its observed result quoted.
- [ ] **CIAC-3 (#4907 × #4890 on the Check-56 M2 comments):** after both cards land, **no comment in `core/deploy/deploy.sh` asserts that M2 must route through the warn emitter unconditionally, and none cites the closed card's acceptance criterion as a live constraint.** That card closed; the constraint is discharged, and leaving it in place would ship a comment misstating a governing dependency. **The criterion is split cleanly:** #4907 reconciles the **block-level** comment, #4890 the **call-site** comment. Both halves must land. *Method:* grep for the constraint phrasings; assert zero hits. *Control (sensitivity):* the same grep at the release base returns **non-zero** — verified, both phrasings are present today.
- [ ] **CIAC-4 (#4907 × #4908 on the two governing-doc obligation homes):** the degraded-state convention and the aggregation-trace obligation occupy **distinct homes that cross-reference rather than restate** each other. Both are obligations *about checks* and are adjacent enough to invite duplication; two competing normative statements of what a check owes its reader is a duplicate-source breach. *Method:* read both sections; assert each names the other by reference and neither restates the other's normative content.

## Verification Plan

| Card | Verification method | Expected result |
|---|---|---|
| #4907 | Read the governing discipline for the rider; run the token-spelling census with both arms; run the verbatim-extraction harness; run the doc-link and count-vs-structure checks | The rider is present and names the sanctioned mechanisms. The space-form emit count goes to **0** from 8; the hyphen-form emit count rises correspondingly (sensitivity arm: a generic emit-string predicate over the same file returns non-zero, so the zero is usable). The extraction harness passes with its assertion re-spelled. The surviving block comment opens at a paragraph boundary and reads as complete prose |
| #4890 | Run the six-arm dynamic-proof harness with the emitters **unstubbed** | The subject arm reports zero escalation under enforce mode; the sensitivity arm proves the harness *can* observe gating (non-zero); the specificity arm proves the mode file is actually read. **Without the sensitivity arm the subject's zero is a broken probe** |
| #4898 | Run the new denominator-integrity group; construct a degraded fixture and a genuinely-clean fixture | The two produce **different** output, and the clean fixture still reports clean. The true-zero rendering is **deliberately unchanged** — that is a clean absence and it stays |
| #4908 | Replay each of the three known instances against the obligation **as originally authored**; run the control | Recall 3 of 3 under the two-limb trigger; the explicit does-NOT-fire set returns zero |
| #4458 | Run the check path-scoped and unscoped; assert the scope record is branched before any counter is read | The false-STALE population goes to zero under path scope; an input-deficient population **exits 3** rather than reporting a vacuous clean |
| #4705 | Run the injected-candidate arm live and the hermetic witness triple | The gate reports a collision on a colliding candidate and passes on a free one. **A passing run alone is not evidence** — the sensitivity arm is the card |
| Release-wide | `bash core/deploy/deploy.sh --check`; `python3 release/tools/check-adr-numbers.py` | Zero genuine `FAIL:` lines (operator-instance drift in the instance-path checks is not a release failure); ADR numbering contiguous with ADR-134 present |

**Regression arms (#4907 AC-3) — three already-fixed instances, none a build target.** Assert the terminal-state path still fires on a malformed primitive emit; that an unreadable pack and a vocabulary shortfall each still surface as a recorded degradation rather than a silent exit 0, **and that an absent pack still does not**; and that the release resolver still separates *no release in flight* from *in flight but unidentified* from *identified but wrong*. For all three, assert the wording conforms to the recorded convention rather than merely predating it.

## Rollback Strategy

**Reversibility is not uniform across this release — treat it per phase.**

- **Git-revertible (CHEAP):** every card is a revert-clean edit to tracked files. There are no file moves, renames, or directory restructures anywhere in the matrix, so the structural-path-move sweeps are correctly N/A rather than passed. Rollback = revert the release merge commit.
- **After W2 adopts the vocabulary (MODERATE):** reverting the convention strands the two adopted call sites, leaving two tokens with no frozen home. The cost is a token-orphaning, not a behavior regression — see R-11.
- **Partial ship is safe.** W1 alone leaves the corpus strictly more consistent than today: four spellings of one state collapse to one, and a check that contradicted itself becomes self-consistent.
- **Version:** no rollback surface — nothing is claimed until the Stage-12 atomic claim.

## Issue Disposition

All six cards are **marked as closed at Stage 13** via the mandated automated close-out path. No close-family verb paired with an issue reference appears in any section of this plan, or in any section of the release PR body outside its designated Issue References block.

## Engineering Notes

**A2 container determination, recorded rather than assumed.** The threshold predicate is evaluated from the change matrix: #4907's decomposition is 5 file-level units and the work is multi-file and structure-changing, so the predicate selects the **GitHub sub-issue container** on its literal reading. The release nonetheless runs its Stage-6 decomposition through the **per-issue stage sub-task already scaffolded by the hub**, with the change units enumerated in this matrix and rendered as PR-body checklist rows at PR assembly. Creating five further sub-issues per card is outside the enumerated scope any wave carries, and would duplicate a container the hub already owns. Recorded as a documented determination so the container choice reads as a decision rather than an omission.

**PR assembly is not Wave 1's.** Under P0 fully-serial dispatch with three waves on one branch, the release PR — including the Change Description section, the documentation-impact resolution table, and the consolidated verification evidence — is assembled once, after the last wave lands. Wave 1 creates the branch and commits; it does not open the PR.

## Deviation Log

| # | Deviation from the Stage-4 / Stage-5 baseline | Source | Disposition |
|---|---|---|---|
| **(a)** | **Commit-0 version re-verify — PROCEED.** Recomputed next-free for bump-class `minor` equals the Stage-4 provisional determination; the slot is unclaimed on both authoritative arms and the in-flight sibling PR is unmerged. No HALT condition fired | Commit 0 | **Recorded determination.** Re-verified at Stage 9 and again at the Stage-12 atomic claim |
| **(b)** | **Branch named `release/check-fail-open-elimination`, slug-primary, no version stem** | Commit 0 | **Applied** |
| **(c)** | **#4907's as-built file surface is 6 paths, not the 5 its frozen matrix states.** The sixth is the verbatim-extraction test harness, whose assertion matches the space-form token that the same commit re-spells. The Stage-5 design **mandates** the co-edit in its own implementability finding and consumer enumeration but did not carry it as a matrix row | Commit 0 | **Declared, not absorbed.** The path is in the machine-readable list above, which is the extraction contract Stage 7/8/9 read. Not a scope change: the edit is compelled by the change the matrix already declares |
| **(d)** | **#4907's Change 1 touches a fifth anchor in the governing discipline** beyond the four its mechanism named — the § 8.1 element-series enumeration and its section heading, plus two class-ordinal statements in § 8.4 that the added covered class makes false | Commit 0 | **Declared, in-file, additive.** Leaving them would have shipped a document asserting seven covered classes and then calling the next class *"a 7th class"* — an internally false statement authored by this very edit. The § 5.6 cascade sweep did not catch them because its pattern matched shape counts, not ordinal class labels. **Cascade-sweep gap surfaced to the hub** |
| **(e)** | **Stage-4 contention C-2 dissolves and a net-new C-4 appears.** The telemetry-tool overlap the Stage-4 map anticipated is removed by design; a new low-severity overlap on the governing discipline appears because #4908's matrix postdates that map | Stage 5 | **Applied.** The Stage-9 contention re-measure should read C-2 as resolved-by-design rather than as an unmeasured baseline row |
| **(f)** | **The M2 advisory-class card's AC-2 harness is committed but was NOT executed at Engineering.** The script-execution guard blocks any invocation of a tracked `*.sh` that is absent from the **deployed** allowlist, and the deployed copy is a token-resolved mirror that lags the tracked source this commit edits. The four invocation-form rows landed in the tracked allowlist; the mirror syncs at deploy | Engineering | **Surfaced, not routed around.** No bypass variable was set, no path was re-spelled, and no second tool was tried; the parse-only form is refused by the same lexical matcher. **AC-2's dynamic proof is therefore owed to Stage 7**, which also has the CI step this commit wires. What WAS verified at Engineering: AC-1 statically, AC-3 dynamically with a mutation control on the pre-fix file, the highest-risk consumer harness at 19/19, and the new harness's embedded probe compiled |
| **(g)** | **That harness pulls the emit region's INPUT-building block from `deploy.sh` at run time by content anchor**, rather than pasting it in as a static copy as the design's placeholder note directed | Engineering | **Declared implementation choice, contract preserved.** The design's binding constraints are that the placeholder is filled from those lines, that arm semantics and the sensitivity-before-subject dependency hold, and that no emitter is stubbed — all three are met. A static paste would drift from the shipped extractions silently, and drift in the input builder is precisely what makes a green arm meaningless. Anchored marker-free, for the same contention reason as the per-function emitter anchors; Arm A carries the loud guard if an anchor moves |
| **(h)** | **Arm F reports its denominator instead of pinning it to the literal the design quoted.** The arm asserts the denominator is non-empty, the subject is 0, and the sensitivity arm is at least 1 | Engineering | **Declared.** A pinned count turns a class-regression arm into a count-drift alarm that reddens on any unrelated leg landing, and the tool-row corpus deliberately states no such cardinality for this very reason. The observed figures are recorded in the Stage-6 evidence rather than frozen in the assertion |
| **(i)** | **The emit-region opening sentinel sits above the whole membership-branch conditional**, not immediately above the M1 leg comment | Engineering | **Applied — required for the region to be executable.** The design directs the marker upward so the extracted region carries both legs; placing it between the branch's `else` and the M1 comment would extract a fragment whose closing keyword has no opener, so the harness could not run it. Above the conditional the extraction is balanced and both legs are in scope, which is what the sensitivity arm depends on |
| **(j)** | **The telemetry-denominator card lands TWO new functions where its design named one.** Alongside the denominator corroborator, the slot-6 state resolution is extracted into its own function rather than left as an inline branch | Engineering | **Declared, and compelled by the design's own acceptance evidence.** That design requires the true-zero and unlabelled-sub-task fixtures to compare *emitted strings*, and the emitter is defined far below the self-test block, so an inline branch is unreachable offline. The only alternative is to recompute the branch inside the test — a second copy of the contract, which is the duplicate-denominator breach the file's separate marker arrays exist to prevent. One resolver, one composition point, driven by both the live path and every fixture |
| **(k)** | **Two conditions beyond the design's twelve-row state map are handled.** A measurable-denominator collapse that coincides with unlabelled candidates, and a failed cross-check on the zero branch, each get a distinct reason under an already-frozen token | Engineering | **Declared, in scope by the card's stated intent.** Both are the card's own defect: left unhandled, each renders a clean-absence string over a denominator that is demonstrably not clean. No token is coined — both map to `NOT-EVALUATED`, which the map already sanctions for "nothing usable was measured" |
| **(l)** | **A fourth anchor in the state-contract standard is reconciled beyond the three the design named.** Its § 7 exit-code list asserted that an unresolvable milestone exits 2 | Engineering | **Applied — reconciled, not annotated.** That claim was already false, and the § 4 language this change adds states the opposite explicitly, so leaving it would ship a document that contradicts itself in two adjacent sections as a direct result of this edit. Corrected to state the in-band disposition and why it is not an exit code |
| **(m)** | **A self-inflicted defect was found by the live arm and is recorded rather than quietly fixed.** The resolver's tab-separated return collapsed its empty-reason field, because tab is IFS whitespace, so a clean measured rate emitted an EMPTY slot 6 — and the permissive eight-slot grammar accepts a blank slot without complaint | Engineering | **Fixed, with the missing assertion added.** The first fixture suite passed while the live run emitted a blank indicator: every assertion in the state-grammar loop was vacuously satisfied by an empty string. An absent reason now travels as `-`, the loop asserts non-emptiness before anything else, the measured-rate shape is asserted positively, and the emitter refuses to publish a blank slot. This is the release's own thesis reproducing inside its own Stage 6, caught by the arm that ran against real data |
| **(n)** | **The row-limit saturation guard covers BOTH Indicator-6 reads, where the design scoped it to the label-scoped one.** The cross-check shares the same row bound and can saturate independently | Engineering | **Declared — one `or` clause, no new state and no new reason string.** A truncated cross-check can only shrink the candidate set, so it can only LOSE a flag: precisely the fail-open direction this release exists to eliminate, reintroduced by the guard itself. Widening the existing condition rather than adding a branch keeps the emitted vocabulary unchanged |
