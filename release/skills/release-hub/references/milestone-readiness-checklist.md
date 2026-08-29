<!-- reference-durability: allow-link -->
# Milestone Readiness Checklist (Mode R)

Elaborates the `## Composition` contract in [`../SKILL.md`](../SKILL.md). The SKILL.md is authoritative;
this file is the worked checklist, composition map, disposition table, and output schema. **Every check
is owned by a composed skill/spec — the hub sequences and rolls up; it implements no check here.**

## The nine checklist groups

| # | Group | Sub-checks | Owning skill / spec (composed) |
|---|---|---|---|
| **1** | Triage readiness | `1a` status = Approved · `1b` DoR completeness (fields, AC, type + roadmap) · `1c` Decision Date + priority | triage-analysis capability → `intake-desk` Mode B (5-test) + `delivery-engine` DoR |
| **2** | Dependencies | `2a` dep validity (compatible states; no Rejected blocker) · `2b` acyclic + ordered · `2c` **cross-milestone leaks** | `release-planner` (dep-graph / cross-milestone validation) |
| **3** | Staleness | `3a` PT-1 stale-assumption (per-issue) · `3b` milestone currency (bundle drift since creation) | `triage-design-rereview` PT-1 |
| **4** | Architecture | `4a` PT-3 best-practices / ADR conflict · `4b` PT-4 learnings contradiction · `4c` design-readiness | `triage-design-rereview` PT-3 / PT-4 |
| **5** | Duplication | `5a` **PT-2 subsumption** (already shipped) · `5b` similarity vs backlog · `5c` intra-milestone overlap | `triage-design-rereview` PT-2 + triage-analysis similarity |
| **6** | Bundle coherence | Release Outcome Statement present · coherent theme (not bin-packed) · size band 15–25 pts · **`backward-dep-walk-performed`** — did the composition run doctrine **Step 3**, walking each member's deps backward to discover *unbundled* prerequisites? Distinct from group 2, which validates the graph of what is **already** bundled and so cannot tell a walk that found nothing from a walk that never ran · **`older-milestone-prerequisite-check`** — did it run doctrine **Step 4**, scanning already-open older milestones for prerequisites the slice depends on? | `bundle-composition-doctrine` |
| **7** | Methodology-neutrality & structural-cascade | `7a` **methodology-neutrality** — does the work hardcode a methodology archetype into the methodology-neutral toolkit, vs. ship it as a config-selected pack? · `7b` **structural-cascade** — if the work proposes a rename/restructure, compute its blast radius and reconcile it against the agreed operational-taxonomy direction (meaning lives in frontmatter, not folder location) | `bundle-composition-doctrine` (frame-pluggability) + [`ADR-033`](../../../../core/ADRs/ADR-033-methodology-conditional-skill-activation.md) |
| **8** | Backlog-altitude ownership & subsumption | `8a` **candidate-epic narrowing** — resolve the open epics sharing the card's `project:` label (a scoping filter; **emits no finding on its own**) · `8b` **native parent** — is the card a native sub-issue child of a candidate epic (read the card's child→parent edge directly) · `8c` **epic-composition pull-in** — is the card enumerated in a candidate epic's composition / pull-in table · `8d` **cross-epic similarity** — re-read group 5 `5b`'s similarity hits for the *ownership* signal (a similar OPEN issue under another epic), citing that owner rather than re-running similarity | `release-planner` (its backlog read **extended to cross-epic ownership** — owns `8a`–`8c`) + group 5 `5b`'s existing similarity owner (owns `8d`) |
| **9** | Problem-validity & abstraction-altitude | `9a` **problem-validity** — classify each card's problem-evidence provenance (`PV-A` observed-pain · `PV-B` framework-driven · `PV-C` article-imported · `PV-D` unsourced); a single push-classified card is **logged, not escalated** — the finding is bundle-level **push-dominance** (`PV-B`+`PV-C`+`PV-D` ≥ ½ the cards) · `9b` **abstraction-altitude** — does the card's stated remediation sit at the abstraction band the live architecture should own? Compare the card's implied band against the nearest platform seam's (`point-fix` / `extend-seam` / `new-abstraction`) and emit the mismatch direction (too-low / too-high). **EXCLUDES the methodology-archetype sub-case, which is group `7a`'s** (see the routing rule below). Distinct from group 8's *backlog* altitude (the hierarchy ladder) — this is *abstraction* altitude (seam bands). | [`triage-design-rereview`](../../../references/standards/triage-design-rereview.md) **§ 11** (its premise re-review **extended** with the premise-provenance + abstraction-altitude lens), which cites [`design-exploration.md`](../../../references/standards/design-exploration.md) §2 for the band vocabulary |

Groups 1 + 5 = the **triage-analysis capability** (a planned EXTEND on `intake-desk` + `delivery-engine`);
until it ships, the hub chains `intake-desk` + `delivery-engine` directly. Groups 3 + 4 + the PT-2 of group 5
= `triage-design-rereview`. Group 2 = `release-planner`. Group 6 = `bundle-composition-doctrine` — composing its § 3 Steps **1** (Outcome Statement), **3** (backward dep walk), **4** (older-milestone prerequisites) and **5** (size band); the group cites those steps and carries no check logic of its own (ADR-019 compose-not-absorb), and it is the named runner for that method's class-3-O gate-coverage register row, so deleting a step token here turns `deploy.sh --check` Check 62 red rather than silently returning the method's dependency half to running only when someone remembers it.
Group 7 = `bundle-composition-doctrine` (its **frame-pluggability** discipline — methodology is config-selected,
not hardcoded) + **ADR-033** (methodology-conditional activation) — a **compose-only** architecture-conformance
gate carrying **zero inline logic** ([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)):
the group cites the composed owner's rule, it does not restate it.
Group 8 = `release-planner` (its cross-milestone backlog read **extended** to cross-epic ownership) for `8a`–`8c`,
plus group 5 `5b`'s existing similarity owner for `8d` — a **compose-only** backlog-altitude ownership gate carrying
**zero inline logic** (ADR-019, as above): the group cites the composed owner's rule, it does not restate it.
A finding requires a **card-specific** ownership edge (`8b`, `8c`, or a named similar open issue under another epic
via `8d`); a shared `project:` label alone is never a finding.
Group 9 = `triage-design-rereview` **§ 11** (its premise re-review **extended** with the premise-provenance +
abstraction-altitude lens) — a **compose-only** problem-validity and altitude gate carrying **zero inline logic**
([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)): the group cites the composed owner's
classes and citation discipline, it does not restate them. **The `7a` ↔ `9b` routing rule (one property, checked
once, so exactly one group claims any finding):** route to **`7a`** iff the too-low subject is a named
delivery/governance **methodology archetype** — an entry in, or a `Custom`-row candidate for,
[`methodology-archetype-matrix.md`](../../../references/specs/methodology-archetype-matrix.md) § 3 — whose correct
home is a config-selected pack behind the `delivery_approach` selector
([ADR-033](../../../../core/ADRs/ADR-033-methodology-conditional-skill-activation.md)); route to **`9b`** for every
other band mismatch. `9b` emits nothing when `7a` claims the finding. A card that trips both carries two findings and
one disposition (per the precedence ladder below).

## Output schema (per requirement)

Mode R emits, **per card**, a [`triage-design-rereview`](../../../references/standards/triage-design-rereview.md)
**§ 1 re-review artifact** — the **8 header-metadata fields** plus the **six-column per-requirement table**
(`Requirement · D1 finding · D2 finding · D3 finding · Classification · Delta or Premise-Problem Type`), one
row per release-scoped requirement (AC / proposed-change / risk). The row shape is **cited to § 1, never
restated here**, and § 2 Rule 3 binds it — every dimension produces a finding line, so a row carrying an
empty `D1` / `D2` / `D3` cell is non-conformant. **Machine consumer:** Stage-4 Phase A0's **G-PL5**
cache-read (`stage-04-planning.md`) adopts these rows instead of re-running PT-1..4; a table that is not the
six-column form, or that carries an empty dimension cell, is a cache MISS there.

The table below is **not the row schema** — it is the **value legend** for that table's `Classification` and
`Delta or Premise-Problem Type` columns. Three classification values, with the premise-problem types that
apply to C3 only:

| Class | Meaning | PT type (C3 only) |
|---|---|---|
| **C1** | Survives verbatim — confirmed correct/complete | — |
| **C2** | Needs refinement — local delta | — |
| **C3** | Should be challenged — premise problem | PT-1 stale-assumption · PT-2 subsumption · PT-3 best-practices conflict · PT-4 learnings contradiction |

## Disposition mapping (the roll-up)

Each finding maps to one disposition; the milestone verdict is GO only when none is blocking:

| Finding source | Disposition | Verdict impact |
|---|---|---|
| Group 1 or 2 fail | **FIX-FIRST** (approve / add AC / clear blocker) | NO-GO until cleared, then GO |
| Group 3 or 4 fail (C3 / PT-1,3,4) | **RE-CONFIRM** (premise moved → re-validate or re-triage) | NO-GO pending operator |
| Group 5 fail (PT-2 / similarity) | **DROP-OR-TRIM** (remove the shipped/dup issue from the milestone) | trim → re-evaluate |
| Group 6 fail | **RE-BUNDLE** (the unit itself isn't coherent) | NO-GO — re-bundle |
| Group 7 fail (neutrality / cascade — C3) | **RE-CONFIRM** (architecture premise moved → re-validate the neutrality design or reconcile the cascade blast-radius) | NO-GO pending operator |
| Group 8 fail (ownership / double-home — C3) | **DROP-OR-REHOME** (the work is live but mis-homed → move the card to its owning epic; **recommend-only** — Mode R names the owning epic and stops, it never de-bundles or re-parents) | NO-GO until rehomed → re-evaluate |
| Group 9 fail (problem-validity / abstraction-altitude — C3) | **RE-CONFIRM** (the premise needs operator re-validation before the release spends on it — for `9a`, is the problem real enough to fund?; for `9b`, is this the abstraction the live architecture should own? **recommend-only** — Mode R names the evidence class or the band mismatch and stops; it never re-triages, re-labels, de-bundles, or edits the card) | NO-GO pending operator |

**Disposition-set invariant (the fit test).** The set is **closed** — every finding carries a value from the table
above, never an ad-hoc label. Closed means *a finite named vocabulary*, not a fixed cardinality: **a new checklist
group maps onto an existing disposition unless it introduces a materially distinct operator action** — a different
thing for the operator to DO, with a different destination. Group 7 mapped (a neutrality/cascade C3 *is* a moved
architecture premise → **RE-CONFIRM**). Group 8 did not: moving live work to its owning epic is neither a fix-in-place,
nor a re-validation, nor the removal of already-completed work, nor a re-bundle — so it added **DROP-OR-REHOME**.
Group 9 mapped: a problem-validity or abstraction-altitude C3 **is** a premise the operator must re-validate before
the release spends on it — neither a fix-in-place, nor the removal of completed work, nor a relocation, nor a
re-bundle — so it takes the existing **RE-CONFIRM**, exactly as group 7 (the methodology-neutrality *sub-case* of
altitude) did.
The table above is the **authoritative** enumeration; the two `SKILL.md` restatements (Mode R Process roll-up ·
Output Contract requirement 4) are mirrors that must agree with it.

**Per-card precedence (one disposition per card).** When a card trips more than one group, the higher-precedence
disposition wins: **DROP-OR-TRIM > DROP-OR-REHOME > FIX-FIRST > RE-CONFIRM**. (RE-BUNDLE is milestone-level and is
evaluated once per bundle, not per card.) Terminal/mechanical dispositions outrank relocation, which outranks
in-place fixes. The load-bearing case: a card that is **both** already shipped (group 5 / PT-2) **and** owned
elsewhere (group 8) resolves to **DROP-OR-TRIM** — if the work is done, remove it; do not rehome completed work.

**GO** = every requirement C1/C2 with no blocking disposition. **NO-GO** = any blocking disposition, with
the per-finding disposition list as the operator's action set. Reversibility: **CHEAP** (read-only;
recommend dispositions, mutate nothing).

## Integration — replaces Stage-4 Phase A0 (superset)

Mode R is a strict superset of the per-issue Stage-4 Phase A0 re-review: it runs the same PT-1..4 at
milestone scope **and** adds the milestone-level checks Phase A0 never did (`2c` cross-milestone leaks,
`3b` bundle currency, `6` coherence, `7` methodology-neutrality + structural-cascade, `8` backlog-altitude ownership,
`9` problem-validity + abstraction-altitude). Because the output **is** the § 1 re-review artifact itself,
Phase A0 **is** a cache-read of Mode R's findings rather than a re-run of them. The hub relays the briefing
into the release's Stage-4 sub-task at `hub-spoke-bridge.md` Procedure 0 Step 5, carrying the currency
operands — a card-set fingerprint over the milestone's non-`sub-task` members, the milestone's `updated_at`
and description digest, the `main` head SHA, and `emitted_at`; Stage-4 Phase A0's **G-PL5** cache-read
(`stage-04-planning.md`) recomputes them and, on equality, adopts these rows instead of re-running PT-1..4.
**Mode R itself persists nothing — its read-only contract is unchanged.** Any operand mismatch, an absent
briefing, or a non-conformant table is a cache MISS and Phase A0 re-runs the re-review — the fallback, not a
failure. G-PL5 skips only the PT-1..4 re-review: the A0.5 reference-currency gate and the A0.8
empirical-repro gate always run, and an A0.8 `close-resolved` / `re-scope-changed` verdict supersedes that
card's rows.
