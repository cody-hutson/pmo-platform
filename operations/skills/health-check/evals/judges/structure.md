<!-- Binary LLM judge — health-check `structure` mode (mode 9, v4 slice) -->
# Judge: `structure` mode (binary)

You are grading the output of the `health-check` skill run in `structure` mode against a
seeded fixture. Return **PASS** or **FAIL** with a one-line reason. This is a binary judge —
there is no partial credit.

## Inputs

- The fixture's ground-truth "Expected categorization" block for `structure` mode (the seeded
  structural violations + the seeded-clean records + the expected section for each).
- The skill's actual 5-section output, including its score block.

## PASS criteria — ALL runs

1. **All five section headers present, in order:** `## Confirmed`, `## Auto-Actionable`,
   `## Decisions`, `## Unknowns`, `## Rollup-Diffs`. (An empty section reads `_(none)_`.)
2. **Every finding carries a `[confidence: … · S…]` label**, and every decision-class item carries
   a reversibility tier.
3. **Zero seeded-clean records flagged** — records the fixture marks CLEAN do not appear as findings.
4. **Read-only:** no tracker and no Tier-1 file is written; every proposed change is staged or routed.

## The three audited limbs (AC-2)

5. **All three limbs are demonstrated in the output** — (a) entity present, (b) required fields
   populated, (c) required relationships valid. A run that reports only field violations, or only
   relationship violations, FAILs: the mode must show it audited all three.

## Finding format (AC-4)

6. **Every violation names the rule ID + the entity + the field or relationship that failed.**
   A **bare count** is an automatic FAIL — a finding that reports only a count
   (`4 records failed validation`) FAILs even when the count is correct, because the operator
   cannot act on it without re-deriving which record it means. The rule ID must be a real
   identifier from the schema doc, not invented.

## The score and its envelope (AC-3)

7. **`MM-0` is rendered as a single 0–100 number with all three factors broken out.** A bare score with
   no breakdown FAILs. The `completeness.*` names may appear as display labels; the `MM-*` identifiers
   must be present. **The breakdown obligation is per-factor and grain-specific — it is not a blanket
   numerator/denominator requirement:**
   - **`MM-1` and `MM-2` are ratios** at the entity-record grain. Each MUST carry its own numerator and
     denominator; a bare percentage for either FAILs.
   - **`MM-3` is Composed-Index Conformance — a per-project STATE** (`composed` / `partial` /
     `monolith`), **not** a link ratio and not "relationships valid". It MUST render as its state, and
     may additionally show the 0–100 factor projection it contributes to `MM-0`. **Rendering `MM-3` as a
     numerator/denominator ratio is an automatic FAIL.** That form is the zero-denominator trap the
     three-state definition exists to close: an unmigrated monolith has zero wiki-links, so a link ratio
     computes `0/0` and renders the least-migrated project as perfectly migrated. A criterion that
     *required* an n/d for `MM-3` would certify that defect rather than catch it, so this one does not.
   - A run that renders `MM-3` as a state **passes** this criterion; the absence of an `MM-3` numerator
     is never itself a finding.
8. **The entity-type coverage line is present** — how many entity types are in the denominator and
   how many are excluded. **This is load-bearing and its absence is an automatic FAIL even when a
   tier banner is present.** Once every storage tier holds a record the tier banner falls silent
   while most entity types remain unpopulated, so the type line is the only guard against a
   confident 100 over a tiny denominator.
9. **A tier banner, when rendered, is a LIST derived from the unpopulated tier set** — not a singular
   value, and carrying no hardcoded rule count. Zero unpopulated tiers ⇒ no banner, and the type
   line still renders.
10. **An unmeasurable factor renders `UNMEASURED`, never `0%`**, and any `UNMEASURED` factor makes
    `MM-0` render `UNMEASURED` rather than `0/100`.

## Routing (ordered, first-match-wins)

11. **A reference unresolvable because its target TIER is unpopulated** lands in `## Unknowns`,
    is excluded from the denominator, and is named in the coverage note — it is **NOT** reported as
    a per-record contradiction. This is routing row 1 and it outranks every per-record row.
12. **An entity referenced but absent** lands in `## Decisions` at `S3` (a contradiction finding).
    An entity merely expected-but-absent with nothing referencing it lands in `## Unknowns`.
13. **`## Auto-Actionable` admits a violation only when the correct value is DERIVABLE from the
    frozen schema.** A non-derivable value (an empty owner, an absent date) routes to `## Decisions`
    even though its confidence is HIGH. Confidence alone is not the gate.
14. **A single underlying gap is reported ONCE.** An empty required field that is also an empty
    reference slot instantiates no relationship rule — it is a presence failure, counted once in the
    fields factor (`MM-2`). Reporting it a second time as a relationship (limb c) violation is a
    double-report and FAILs. (`MM-3` is not the relationships factor — it is the composed-index state
    per criterion 7 — so the double-report test is against limb c's finding set, not against a score
    factor.)

## Stalled-migration escalation

15. **A stalled project emits a well-formed escalation.** Where the fixture seeds a project satisfying
    the stall predicate, the run emits a stalled-migration FAIL carrying **all four** of: (a) the
    **specific project**, named; (b) the **blocking factor**; (c) **both** parts of the two-part
    remediation link — the migration-enforcement protocol's procedure pointer **and** the
    `project-initiator` migration mode; (d) placement in `## Decisions`. Any one missing is a FAIL.
16. **A bare count, or a stall finding in `## Auto-Actionable`, is an automatic FAIL.** `2 projects have
    stalled migrations` FAILs even when the count is correct — it is a summary of findings that were
    never written. A stall finding routed to `## Auto-Actionable` FAILs **regardless of the confidence
    it carries and regardless of whether its target state is derivable**: the protocol imposes
    `## Decisions` on this finding class, so the derivability test governing every other L1 violation
    does not reach it.

## Boundary

17. **Where the stall predicate is not evaluable, no escalation is emitted** — and the stall dimension
    reads `UNMEASURED` with its precondition named, never *not stalled* and never a silently absent
    dimension. An escalation emitted without the required run history is out of contract.

## Verdict

`PASS` — every applicable criterion holds. Otherwise `FAIL` with the first violated criterion cited.
