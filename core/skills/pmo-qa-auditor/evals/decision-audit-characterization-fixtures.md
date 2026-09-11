<!-- reference-durability: allow-link -->
# Mode J Characterization Fixtures — Decision-Health Audit

```yaml
labeled_by: Stage-6 Engineering session (candidate labels)
label_date: 2026-09-11
independence: PENDING — candidate labels authored at Stage 6; independent
  adjudication runs at the Stage-7 DT gate (the DT session authored neither the
  dimension rubric nor the mode text). Ground truth is set on that concurrence at
  the Stage-9 gate; until then these are candidate labels.
```

Characterization fixtures, NOT κ-calibrated — regression-pinning for Mode J's window
resolution, roster derivation, coverage-state assignment, classification, index arithmetic,
and evidence-bar behavior (the calibration floor governs gating judges, which these are not;
per the eval-writer discipline). Acceptance per family is stated in that family's heading.

**Durability note:** fixture inputs cite work items by TITLE plus a live search procedure,
never by number — numbers rot on renumber; titles and procedures survive. Live-resolved
evidence inputs use `LIVE:` tokens the self-test resolves at run time.

**Family-identifier note (load-bearing for one of this release's own criteria).** Families
carry letter identifiers rather than ordinals, and headings keep digits away from the scored
nouns. That is not house style: this mode's artifacts are scanned for an integer adjacent to
the oracle and coverage-class nouns, and a numbered family heading trips that scan on an
adjacency carrying no cardinality at all. Letter ids keep the scan's added-line population
clean without weakening any fixture.

**Family CTL is the one worth reading first.** It is a fixture whose expected outcome is that
the audit **refuses to run**. Without it, the derivation's bounding control is a line of prose
that nothing exercises — and a control arm nothing exercises is indistinguishable from one that
cannot fail.

## Family WIN — window resolution (deterministic; exact)

Pins the mode-spec §2 rule that a window never silently widens or narrows.

### F-WIN-01 — resolvable window
- **Input:** both bounds supplied, each resolving to a release-record row carrying a merge anchor.
- **Expected output:** the window resolves; both bounds, both merge anchors, and the span count
  are recorded in both emitted surfaces.
- **Ground-truth label (candidate):** resolved.

### F-WIN-02 — unresolvable bound → INDETERMINATE
- **Input:** a lower bound naming a release with no release-record row.
- **Expected output:** **INDETERMINATE**, naming the unresolvable bound. The run does **not**
  widen to the whole record and does **not** narrow to the latest release.
- **Ground-truth label (candidate):** INDETERMINATE.

### F-WIN-03 — version-ordered versus anchor-ordered trap
- **Input:** two releases whose version identifiers order one way and whose merge anchors order
  the other — the shape a slot-identifier scheme produces when a higher-numbered release merges
  first.
- **Expected output:** the window orders by **merge anchor**. A run that orders by version
  identifier fails this fixture.
- **Ground-truth label (candidate):** anchor-ordered.

## Family ORC — roster derivation (deterministic; exact)

Pins the mode-spec §3 predicate: the roster is resolved from the corpus, never from an inline
list, and the pin records membership as well as content.

### F-ORC-01 — roster under the structural predicate
- **Input:** a corpus tree carrying release-module skill definitions, some declaring the named
  failure-mode section and some not, with the deploy roster present.
- **Expected output:** the derived roster is exactly the set satisfying all three conjuncts —
  the path shape, membership in the deployed release-skill roster, and presence of the
  failure-mode section heading. No file is named inline anywhere in the emitted artifacts.
- **Ground-truth label (candidate):** predicate-derived roster.

### F-ORC-02 — the self-test canary is present and correctly excluded
- **Input:** the same tree, with the deliberately non-conformant self-test canary skill present
  under the release module and absent from the deployed roster.
- **Expected output:** the canary is **excluded**, and it is excluded by the roster conjunct
  rather than by being named. A run that scores health against a fixture built to fail this
  fixture.
- **Ground-truth label (candidate):** canary excluded.

### F-ORC-03 — a source acquires the section mid-window → roster-delta notice
- **Input:** a prior pin recording one membership set; a current tree in which one further
  source has acquired the failure-mode section.
- **Expected output:** a **roster-delta notice** naming the added source, and the run notes the
  oracle change in its `SUMMARY.md` per the cadence continuity rule. The membership field of
  the pin is what makes this detectable; a pin carrying only hashes and counts cannot produce it.
- **Ground-truth label (candidate):** roster-delta emitted.

### F-ORC-04 — content drift at constant entry count
- **Input:** one source whose content changes between two anchors while its entry count and its
  ordered entry-title set stay identical.
- **Expected output:** the pin's **content hash** differs and the run reports drift. A
  derivation that is merely cardinality-free reports no drift here and is wrong — this fixture
  is the one that proves the hash field, not the count field, is doing the work.
- **Ground-truth label (candidate):** drift detected on the hash field.

## Family CTL — the derivation control arm (deterministic; exact)

### F-CTL-01 — degenerate section boundary → INDETERMINATE, not a silent pass
- **Input:** a seeded corpus in which **every** source's section-scoped entry count equals its
  whole-file heading count.
- **Expected output:** **INDETERMINATE.** The equality everywhere means the section boundary is
  not bounding and the probe has degenerated to a file-wide match; the run reports that rather
  than proceeding on a larger, plausible, wrong set.
- **Ground-truth label (candidate):** INDETERMINATE.
- **Why this fixture exists:** it is the negative control for the whole derivation. The
  bounding assertion is the only thing standing between a correct derivation and one that was
  never shown to bound, and the two are byte-indistinguishable in the emitted artifacts.

### F-CTL-02 — non-degenerate boundary → proceed
- **Input:** a corpus in which at least one source's section-scoped count is strictly less than
  its whole-file heading count.
- **Expected output:** the control passes and the run proceeds. This is F-CTL-01's positive arm;
  a run that reports INDETERMINATE here has a control that cannot pass, which is as broken as
  one that cannot fail.
- **Ground-truth label (candidate):** proceed.

## Family COV — coverage-state discrimination (deterministic; exact)

Pins the rubric §2 ordered predicate. Every fixture below turns on the distinction between a
measurement gap and a measured zero.

### F-COV-01 — no declared writer, no rows → `uninstrumented`
- **Input:** a seam none of whose loci is named by a corpus rule declaring a writer.
- **Expected output:** coverage state **`uninstrumented`**, and **no grade at all**.
- **Ground-truth label (candidate):** `uninstrumented`.

### F-COV-02 — writer declared, no occasions, no rows → `unexercised`
- **Input:** a seam with a declared writer and a window owing it no occasions.
- **Expected output:** coverage state **`unexercised`**, and **no grade at all**. It is **not**
  carried in the residual-risk register — nothing was owed.
- **Ground-truth label (candidate):** `unexercised`.

### F-COV-03 — writer declared, occasions owed, zero rows → `measured` / `partial` (REQUIRED NEGATIVE CONTROL)
- **Input:** a seam with a declared writer, a window owing it occasions, and no rows arriving.
- **Expected output:** coverage state **`measured`**, grade **`partial`**. It must **not**
  render `unexercised` and must **not** render `uninstrumented`.
- **Ground-truth label (candidate):** `measured` / `partial`.
- **Why this fixture is required rather than optional:** this is the emitter existing, rows
  being owed, and none arriving — the most actionable state the audit produces. Both other
  placements read benign: `unexercised` says nothing happened, which inverts the truth, and
  `uninstrumented` says known blind spot, which excuses a live emission failure. Without this
  fixture the state the coverage axis was widened to expose can silently regress into the
  benign class, and nothing would notice.

### F-COV-04 — a locus whose only surface is an ephemeral render → `uninstrumented`
- **Input:** a seam whose only candidate locus is a rendered line the corpus explicitly declares
  emits nothing.
- **Expected output:** **`uninstrumented`.** A render that emits nothing has no declared writer,
  so it confers no instrumentation — the declared-producer test excludes it directly rather than
  by a separate qualifier.
- **Ground-truth label (candidate):** `uninstrumented`.

### F-COV-05 — an occasion class that cannot be read → not `unexercised`
- **Input:** a seam with a declared writer, whose occasion classes include at least one whose
  evidencing surface is not retrievable at audit time.
- **Expected output:** that occasion class resolves **`indeterminate`**, never zero; the seam
  therefore may **not** render `unexercised`, and it **retains** residual-risk register
  membership.
- **Ground-truth label (candidate):** not `unexercised`; register membership retained.
- **Why this fixture exists:** it is the denominator-side negative control. Without it,
  *"not observable from here"* and *"measured, and it was zero"* share one value, and a seam
  that was blind in exactly this window would exit the register asserting it was merely quiet.

## Family CLS — classification (judgment; ≥4/5 ground-truth match)

### F-CLS-01 — recorded and evidenced decision → conformant
- **Input:** a window in which a decision was made where the governance says it is made, with
  evidence recorded against it.
- **Expected output:** classification **conformant**; recorded, no finding row.

### F-CLS-02 — an undetected named failure mode → finding
- **Input:** a window in which a named decision failure mode's signature occurred and nothing
  detected it.
- **Expected output:** a **finding** carrying the full root-cause chain, a severity, and an
  orthogonal confidence tag.

### F-CLS-03 — no rows means no grade
- **Input:** a window in which a seam produced no evidence rows.
- **Expected output:** the seam carries a non-graded coverage state and **no grade**. A run that
  renders any non-graded state as a passing grade fails this fixture.

### F-CLS-04 — two-release recurrence → exactly one systemic pattern
- **Input:** the same decision failure signature in two releases in the window.
- **Expected output:** **exactly one** systemic pattern for the group — never one per release,
  never none for a real recurrence.

### F-CLS-05 — evidence-bar failure → unpinnable observation
- **Input:** a candidate finding whose only citation matches none of the four bar forms.
- **Expected output:** it is **not** emitted as a finding; it is reported as an unpinnable
  observation with the missing input named.

## Family IDX — index arithmetic and comparability (deterministic; exact)

### F-IDX-01 — distribution renders an index
- **Input:** a seeded distribution across the coverage vocabulary and the grade vocabulary.
- **Expected output:** the index is the fully-captured count over the rubric's whole row count.
  Both terms are obtained by counting rubric rows; no literal appears in the emitted artifacts.

### F-IDX-02 — a partially-captured seam does not count toward the headline
- **Input:** a distribution in which a seam is graded `partial`.
- **Expected output:** that seam contributes **zero** to the index numerator and **one** to the
  denominator. A run that credits partial capture toward the headline fails this fixture.

### F-IDX-03 — identifier-set change → `re-based`, not trended
- **Input:** two runs whose rubric identifier sets differ.
- **Expected output:** the second run renders the index **`re-based`** and states the seam-id
  delta. It does **not** trend across the discontinuity.

### F-IDX-04 — coverage-vocabulary change is an oracle change
- **Input:** two runs across a rubric edit that changed the coverage vocabulary without changing
  the seam-id set.
- **Expected output:** the comparability guard correctly does **not** fire — its trigger is a
  seam-id set change — and the run instead notes the oracle change in its `SUMMARY.md` per the
  cadence continuity rule. The **distribution render** is not trended across that boundary.

## Family CEIL — the ceiling term (deterministic; exact)

### F-CEIL-01 — a blind class present → index below ceiling
- **Input:** a distribution carrying a seam with no declared writer.
- **Expected output:** `coverage_index < instrumentation_ceiling`.

### F-CEIL-02 — no blind class → ceiling renders full
- **Input:** a distribution in which every seam has a declared writer.
- **Expected output:** the ceiling renders full, whatever the index reads.

### F-CEIL-03 — no declared writer anywhere → both terms read zero, and the ceiling does not throw
- **Input:** a distribution in which nothing has a declared writer.
- **Expected output:** index **0**, ceiling **0**, no division by zero.
- **Honesty note on this arm:** the division-by-zero limb is **vacuous by construction**, not
  load-bearing — both ratios divide by the rubric's whole row count, which is non-zero for any
  populated rubric. It is retained because it pins the degrade-safely behavior against a future
  denominator change, and it is labelled vacuous here so a reader does not mistake it for a
  live guard that has been exercised.

### F-CEIL-04 — index above ceiling → a finding, not an error (REQUIRED NEGATIVE CONTROL)
- **Input:** a seeded window in which evidence rows arrive for a seam no corpus rule declares a
  writer for.
- **Expected output:** the run **surfaces a finding** naming the undeclared producer. It does
  **not** report an arithmetic error and does not clamp either term. The relation between the
  two ratios is a detector, not an invariant.
- **Why this fixture is required rather than optional:** the relation held by construction under
  an earlier definition of the ceiling, so nothing exercised the violated branch. Defining the
  ceiling on the declared-writer predicate makes the branch reachable, and a reachable branch
  with no fixture is an untested path in the arithmetic the whole surface reports.

## Family EVB — the evidence bar (deterministic; exact)

One positive fixture per citation form the bar admits — a file path with a line or section
anchor, an event-log row identified by its window and key, a release-record row identified by
its release, and a runnable command with its output — each expected to **pass**.

### F-EVB-NEG-01 — an unanchored file path
- **Input:** a citation naming a file with no line or section anchor.
- **Expected output:** **FAIL** the bar; reported as an unpinnable observation.

### F-EVB-NEG-02 — a prose location
- **Input:** a citation reading *"observed during the review"* with no resolvable surface.
- **Expected output:** **FAIL** the bar; reported as an unpinnable observation.

**Both negative fixtures must FAIL.** A bar that admits everything and a bar that was never
exercised produce identical emitted artifacts, and the pass rate recorded in the summary is
meaningless without an arm that can lower it.
