<!-- reference-durability: allow-link -->
# Milestone Readiness Checklist (Mode R)

Elaborates the `## Composition` contract in [`../SKILL.md`](../SKILL.md). The SKILL.md is authoritative;
this file is the worked checklist, composition map, disposition table, and output schema. **Every check
is owned by a composed skill/spec — the hub sequences and rolls up; it implements no check here.**

## The seven checklist groups

| # | Group | Sub-checks | Owning skill / spec (composed) |
|---|---|---|---|
| **1** | Triage readiness | `1a` status = Approved · `1b` DoR completeness (fields, AC, type + roadmap) · `1c` Decision Date + priority | triage-analysis capability → `intake-desk` Mode B (5-test) + `delivery-engine` DoR |
| **2** | Dependencies | `2a` dep validity (compatible states; no Rejected blocker) · `2b` acyclic + ordered · `2c` **cross-milestone leaks** | `release-planner` (dep-graph / cross-milestone validation) |
| **3** | Staleness | `3a` PT-1 stale-assumption (per-issue) · `3b` milestone currency (bundle drift since creation) | `triage-design-rereview` PT-1 |
| **4** | Architecture | `4a` PT-3 best-practices / ADR conflict · `4b` PT-4 learnings contradiction · `4c` design-readiness | `triage-design-rereview` PT-3 / PT-4 |
| **5** | Duplication | `5a` **PT-2 subsumption** (already shipped) · `5b` similarity vs backlog · `5c` intra-milestone overlap | `triage-design-rereview` PT-2 + triage-analysis similarity |
| **6** | Bundle coherence | Release Outcome Statement present · coherent theme (not bin-packed) · size band 15–25 pts | `bundle-composition-doctrine` |
| **7** | Methodology-neutrality & structural-cascade | `7a` **methodology-neutrality** — does the work hardcode a methodology archetype into the methodology-neutral toolkit, vs. ship it as a config-selected pack? · `7b` **structural-cascade** — if the work proposes a rename/restructure, compute its blast radius and reconcile it against the agreed operational-taxonomy direction (meaning lives in frontmatter, not folder location) | `bundle-composition-doctrine` (frame-pluggability) + [`ADR-033`](../../../../core/ADRs/ADR-033-methodology-conditional-skill-activation.md) |
| **8** | Backlog-altitude ownership & subsumption | `8a` **candidate-epic narrowing** — resolve the open epics sharing the card's `project:` label (a scoping filter; **emits no finding on its own**) · `8b` **native parent** — is the card a native sub-issue child of a candidate epic (read the card's child→parent edge directly) · `8c` **epic-composition pull-in** — is the card enumerated in a candidate epic's composition / pull-in table · `8d` **cross-epic similarity** — re-read group 5 `5b`'s similarity hits for the *ownership* signal (a similar OPEN issue under another epic), citing that owner rather than re-running similarity | `release-planner` (its backlog read **extended to cross-epic ownership** — owns `8a`–`8c`) + group 5 `5b`'s existing similarity owner (owns `8d`) |

Groups 1 + 5 = the **triage-analysis capability** (a planned EXTEND on `intake-desk` + `delivery-engine`);
until it ships, the hub chains `intake-desk` + `delivery-engine` directly. Groups 3 + 4 + the PT-2 of group 5
= `triage-design-rereview`. Group 2 = `release-planner`. Group 6 = `bundle-composition-doctrine`.
Group 7 = `bundle-composition-doctrine` (its **frame-pluggability** discipline — methodology is config-selected,
not hardcoded) + **ADR-033** (methodology-conditional activation) — a **compose-only** architecture-conformance
gate carrying **zero inline logic** ([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)):
the group cites the composed owner's rule, it does not restate it.
Group 8 = `release-planner` (its cross-milestone backlog read **extended** to cross-epic ownership) for `8a`–`8c`,
plus group 5 `5b`'s existing similarity owner for `8d` — a **compose-only** backlog-altitude ownership gate carrying
**zero inline logic** (ADR-019, as above): the group cites the composed owner's rule, it does not restate it.
A finding requires a **card-specific** ownership edge (`8b`, `8c`, or a named similar open issue under another epic
via `8d`); a shared `project:` label alone is never a finding.

## Output schema (per requirement)

Mode R emits, per release-scoped requirement (AC / proposed-change / risk), a row in the
`triage-design-rereview` schema so Stage-4 Phase A0 can consume it as a cache-read:

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

**Disposition-set invariant (the fit test).** The set is **closed** — every finding carries a value from the table
above, never an ad-hoc label. Closed means *a finite named vocabulary*, not a fixed cardinality: **a new checklist
group maps onto an existing disposition unless it introduces a materially distinct operator action** — a different
thing for the operator to DO, with a different destination. Group 7 mapped (a neutrality/cascade C3 *is* a moved
architecture premise → **RE-CONFIRM**). Group 8 did not: moving live work to its owning epic is neither a fix-in-place,
nor a re-validation, nor the removal of already-completed work, nor a re-bundle — so it added **DROP-OR-REHOME**.
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
`3b` bundle currency, `6` coherence, `7` methodology-neutrality + structural-cascade, `8` backlog-altitude ownership). Because the output uses the C1/C2/C3 + PT schema, Phase A0 becomes a
**cache-read** of Mode R's findings rather than re-running them. The cache-read wiring in
`stage-04-planning.md` is a separate governed step; until it ships, Mode R runs standalone and emits the
briefing.
