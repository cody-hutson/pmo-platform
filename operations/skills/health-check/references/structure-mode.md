<!-- reference-durability: allow-link -->
# Health-Check `structure` Mode — Entity-Completeness Audit

The execution contract for mode 9 (`structure`, the v4 slice): which entity/field/relationship
checks run, how the completeness score is composed, what the denominator is, and where each
finding class routes. `SKILL.md` § Modes is the authority for *which* modes exist; this doc
carries the `structure` contract once.

## 1. Purpose & boundary

`structure` audits the **schema-conformance axis** — does this project's data satisfy the frozen
entity model and its field schemas? — as distinct from the **drift axis** every other mode audits
(does tracked state still match its canonical sources?). A record can be perfectly current against
every source and still be structurally incomplete; a record can be schema-perfect and badly stale.
The two axes are orthogonal, which is why `structure` is excluded from the `full` sweep (§ 7 of
`mode-intents.md` carries the declared membership; the reason is stated in `SKILL.md`).

**Three-surface disambiguation — the standing terminology hazard.** `SKILL.md` § Name
disambiguation names three "health check" surfaces. This mode is the **first** one (the project-state
auditor) operating on a new axis. It is **not** the document-ecosystem integrity engine in
[`core/specs/health-check-specification.md`](../../../../core/specs/health-check-specification.md),
and it does not run that engine's index queries — it *consumes* one of that spec's check definitions
by reference (§ 10) and runs none of its checks.

**Population — entity records, never files.** Every count in this mode is over **entity records**.
The boundary axiom in
[`core/disciplines/project-entity-model.md`](../../../../core/disciplines/project-entity-model.md) § 2
is binding: *a logical entity is a data record the PMO tracks; the file(s) that persist it are a
separate concern.* A file-grain ratio never enters a score factor here. The Project entity ⊇
`PROJECT.md`; a Milestone has no single backing file at all.

## 2. What is audited

Three limbs, per entity in the expected set (§ 5):

| Limb | Question | Rule authority |
|---|---|---|
| **(a) entity present** | does a record for this entity type exist at its declared `storage_tier` home? | `project-entity-model.md` § 7 Storage-Location Map |
| **(b) required fields populated** | is every `✅`-required field present and non-empty on each record? | `entity-field-schemas.md` § 3.0 (Core) + § 3.N (per-entity) |
| **(c) required relationships valid** | does every populated typed reference resolve to an existing record? | `entity-field-schemas.md` § 4 (X-rule table) |

**Rule authority is cited by ID, never transcribed.** This doc names rule *classes* and cites
[`core/schemas/entity-field-schemas.md`](../../../../core/schemas/entity-field-schemas.md) as the
authority; it copies no rule text and **hardcodes no rule count**. A rule added to that file is
picked up with zero edit here. Reading a rule and applying it as written is the whole contract —
this mode adds no interpretation layer over the schema.

**Optional fields never enter a denominator.** A `⚪` field absent is not a violation.

## 3. Axis-1 carrier resolution (V-CORE-03)

V-CORE-03 is applied **exactly as the rule states**. The rule itself resolves the carrier per entity
(the annotation is the discriminator, not its punctuation) and resolves the enum from the section
header, the entity's own Axis-1 V-rule row, or a delegation. This mode reads that rule and applies
it; it does not re-derive the carrier and it does not key on any lexical form of its own.

Only two conditions the rule does not decide are declared here:

1. **A delegating entity.** Where a section delegates Axis-1 to Axis-2 rather than enumerating a
   machine, the delegating rule governs and the enum-membership limb does not apply. Report the
   record once under the governing rule — never twice.
2. **An unresolvable carrier.** If neither the annotation nor the restatement row resolves a carrier
   for an entity, that is a **schema-surface finding** against the schema doc — never a record
   defect. It routes to `## Decisions` naming the section, and no record is scored down for it.

## 4. Completeness score

**The score is `MM-0`.** Its definition, its factors, its grain and its status bands are owned by
[`core/standards/migration-enforcement-protocol.md`](../../../../core/standards/migration-enforcement-protocol.md) § 4
and are **cited here, never redefined**. This mode computes them; it mints no competing metric family.

```
MM-0 = MM-1 × MM-2 × MM-3     each factor as a fraction of 1, product rendered 0–100
```

| Factor | Metric | Render label (display only) | Counting unit |
|---|---|---|---|
| entities present | **`MM-1`** | `completeness.entities_present` | entity record |
| fields populated | **`MM-2`** | `completeness.fields_populated` | entity record |
| relationships valid | **`MM-3`** | `completeness.relationships_valid` | project (a state) |

The `completeness.*` names are **render labels carrying no definition** — they appear in output for
human readability and in no cross-reference. `MM-0`–`MM-3` are the load-bearing tokens.

**Grain (binding, per the protocol's grain declaration).** All three factors are computed over the
**entity-record** population. `MM-2` consumes the Frontmatter Completeness check definition as its
definitional source of truth and **projects it onto the entity grain**; the file-grain population
that check is natively defined over does **not** travel with it. `MM-0` never multiplies an
entity-grain ratio by a file-grain one.

**Stated property (from the protocol, not invented here).** The product form means any single factor
at 0 forces `MM-0 = 0`. A project with complete frontmatter and no entity extraction reads 0, not 33.

## 5. Denominator model — the expected set

The formula is fixed; **what it is measured over determines whether the number means anything.** The
denominator is the derived expected set `E1 ∪ E2 ∪ E3`, machine-derived and reproducible:

- **E1 — structurally required.** The `Project` entity, exactly one, `id` = the audited project.
  Always in the denominator.
- **E2 — referenced.** Any entity type at which ≥1 *populated* typed reference on a present record
  points, per the § 4 X-rule table. Deterministic, L2.
- **E3 — present.** Any entity type with ≥1 record in scope, even where nothing references it.

**Everything else is EXCLUDED and NAMED** — never silently dropped from a denominator. A project
with no Vendor is not incomplete; it is a project with no Vendor, and the report says so.

**E1 has three states, not two:**

| E1 state | Behaviour |
|---|---|
| `present` | the audit runs and scores normally |
| `present-but-malformed` | the audit **runs and scores**; each failure is itemised as its own finding |
| `absent` | the audit **cannot run** — surfaced in `## Unknowns` with what was searched, never scored `0` |

**Structural exclusions, declared with their reason.** A constraint whose `on-unresolved` disposition
defers enforcement to lifecycle automation (the dangling-reference-on-delete class) is excluded from
the relationships denominator and named in the coverage note. Optional (`⚪`) fields never enter the
fields denominator.

## 6. Coverage envelope — the render contract

**The score never renders as a bare number.** Every factor carries its numerator and denominator, and
the excluded set is enumerated. This extends the same degradation discipline
[ADR-051](../../../../core/ADRs/ADR-051-health-check-mcp-primary-source-set.md) § 4 applies to a
missing connector: *reduce coverage, never silently downgrade rigor.*

```
Completeness (MM-0): 72/100
  MM-1  entities-present      8/9   (89%)   completeness.entities_present
  MM-2  fields-populated     41/45  (91%)   completeness.fields_populated
  MM-3  relationships-valid  15/17  (88%)   completeness.relationships_valid
Coverage envelope: 9 of 19 entity types in denominator · 10 excluded (not-expected: 0 records, 0 inbound refs)
[TIER UNPOPULATED: cross-project-shared, portfolio-level] — targets unresolvable by tier, not by record
```

Three render rules, each load-bearing:

1. **The entity-type coverage line is mandatory and is the primary guard.** It states how many of the
   roster's entity types are in the denominator and how many are excluded. **Never render the tier
   banner without the type line.** Once every storage tier holds at least one record the tier banner
   goes quiet *while most entity types remain unpopulated* — at that point the type line is the only
   thing distinguishing a real 100 from a confident 100 over a denominator of three. A run that omits
   it is a FAIL.
2. **The tier banner is a list derived from the tier set**, not a singular value and not a hardcoded
   count. Zero unpopulated tiers ⇒ the banner is omitted entirely; the type line still renders.
3. **A factor that could not be measured renders `UNMEASURED`, never `0%`.** `UNMEASURED` is a
   factor-level degradation state. An empty denominator yields `UNMEASURED` and routes to
   `## Unknowns` — it never renders as 100%, because a ratio over an empty population reports an
   untouched project as a finished one. **Any `UNMEASURED` factor makes `MM-0` render `UNMEASURED`,
   never `0/100`.**

## 7. Rule-class → section routing

**Ordered, first-match-wins.** The order is load-bearing: more than one row can match a single fact,
and without a precedence rule a structural tier gap would be reportable as a per-record contradiction.
Tier-unpopulated is row 1 for exactly that reason.

| # | Rule class | `on-unresolved` | Section | Confidence | Band |
|---|---|---|---|---|---|
| 1 | L2 unresolvable **because the target tier is unpopulated** | — | `## Unknowns` + **excluded from denominator** + coverage note | n/a | n/a |
| 2 | Referential constraint deferred to lifecycle automation | `DEFER-G8` | **structurally excluded**; declared in the coverage note | n/a | n/a |
| 3 | L1 V-rule PASS | — | `## Confirmed` | HIGH | `S0` |
| 4 | Entity **referenced but absent** | — | `## Decisions` | HIGH | **`S3`** |
| 5 | Entity expected via E3 but absent, nothing referencing it | — | `## Unknowns` | n/a | n/a |
| 6 | L1 FAIL, correct value **derivable** from the frozen schema | — | `## Auto-Actionable` + `TRACKER_UPDATES:` | HIGH | `S1` |
| 7 | L1 FAIL, value **not derivable** | — | `## Decisions` | HIGH | `S2` |
| 8 | L2 X-rule FAIL | `BLOCK-WRITE` | `## Decisions` — refuse output, route to `owning_agent` | HIGH | `S2` |
| 9 | L2 X-rule FAIL | `WARN-HEALTH` | `## Decisions` — the disposition routes here by name | MEDIUM | `S2` |
| 10 | L3 judgment | — | `## Decisions` (agent-recommend → operator-confirm) | MEDIUM/LOW | per finding |

This table **consumes** the `on-unresolved` disposition enum defined in `entity-field-schemas.md` § 2
and its § 7 failure-handling table; it authors no parallel mapping. `S3` is reached in-rule and not by
fork: a referenced-but-absent entity **is** a contradiction finding — a reference asserts a record that
does not exist — which is the only path to `S3` the confidence framework permits.

**`## Rollup-Diffs` is used for exactly one class:** a Project-entity field failure whose value
persists in `PROJECT.md` (a Document Tier 1/4 file) → a staged diff carrying a reversibility tier,
never a live write. Every other structural finding targets a Tier-2 tracker or an embedded row and
routes via `TRACKER_UPDATES:`. This mirrors the `rollup`-mode bridge-file boundary; it is not a new rule.

## 8. Confidence & band projection

[`references/confidence-framework.md`](confidence-framework.md) owns the base rule; this is a
projection onto it, not a fork.

A structural finding compares a record to a **schema**, not to a second observation. The projection:
**the frozen field schema is the corroborating second source** — the record (local) plus
`entity-field-schemas.md` § 3 (local) are two reliable observations, which is what HIGH requires. The
framework's own worked example makes the reading explicit: HIGH means two reliable observations, not
two matching values — the same way it grades a rule that contradicts a stated value.

**The `## Auto-Actionable` filter is derivability, not confidence.** Almost every L1 violation is
HIGH, so a HIGH gate alone would admit nearly all of them and become a tautology. The operative test
is whether the *correct value* is derivable from the frozen schema. That rule is stated in
`SKILL.md` § Output Structure — the authoritative surface — and restated here only as a pointer.
A `BLOCK-WRITE` or `WARN-HEALTH` disposition routes to `## Decisions` regardless of confidence.

## 9. Finding format

**Every violation names the rule ID + the entity + the field or relationship that failed. A bare
count is a FAIL.**

```
V-CORE-05 · RAID Item R-PROJ-040 · owning_agent empty                      [confidence: HIGH · S2]
V-CORE-07 · Decision DEC-004 · relationships[1].target unresolved          [confidence: MEDIUM · S2]
V-CORE-03 · Milestone M-002 · lifecycle_state "in-flight" not in Axis-1 enum [confidence: HIGH · S2]
```

`4 records failed validation` is not a finding — it is a summary of findings that were never written.
The operator must be able to act on each line without re-deriving which record it means.

## 10. Migration telemetry

The four metrics `MM-0`, `MM-1`, `MM-2` and `MM-3` are **defined** in
[`core/standards/migration-enforcement-protocol.md`](../../../../core/standards/migration-enforcement-protocol.md) § 4.
This mode is their computing instrument. Each is computed at its declared grain:

| Metric | What this mode computes | Grain |
|---|---|---|
| `MM-1` | referenced entities resolving to a materialized record at their `storage_tier` home ÷ referenced entities. **File-backed entities only** — an embedded or computed entity has no independent artifact to detect | entity record, per project |
| `MM-2` | records with all required fields present ÷ records in scope, the required set resolved from the § 3 rules | entity record, per project |
| `MM-3` | the three-state per-project value (`composed` / `partial` / `monolith`) and its factor projection | project |
| `MM-0` | the product of the three factor values, rendered 0–100 | per project, composite |

**`MM-3` is a state, not a link ratio** — reported as its state, with the factor projection feeding
`MM-0`. An unmigrated monolith has zero links, so a naive ratio would compute `0/0` and render the
least-migrated project as perfectly migrated. `monolith` is pinned to a 0 factor for that reason.

**The stall dimension renders `UNMEASURED`, never *not stalled*.** The stall predicate is defined over
`N` consecutive runs and is therefore evaluable **only once `N` runs are recorded**. That precondition
is cross-run state, and where no prior-run source exists the predicate is specified but not evaluable.
Fewer than `N` recorded runs yields *no verdict*, which is not the verdict `not stalled`. Report it as
a coverage note in `## Unknowns` naming what was searched.

## 11. Extension seam — stalled-migration escalation (RESERVED)

**Reserved, not implemented. This mode emits no migration escalation.**

The escalation contract is owned by the migration-enforcement protocol § 3.4. When an escalation
consumer fills this seam, its emission must satisfy both halves of that contract:

- the FAIL **names the specific project**, never a bare count, and
- it **carries a remediation link** to the protocol's procedure pointer, and
- it routes to `## Decisions` — **never `## Auto-Actionable`**, regardless of the confidence assigned,
  because a migration remediation is an EXPENSIVE operator-gated write on a tree with no version history.

The seam is a named hook point so it can be filled without re-architecting the mode. Nothing in this
card implements it.

## 12. Degradation

**Never crash. Never fabricate a record.** Mirrors the skill's contract-absent posture elsewhere.

| Condition | Behaviour |
|---|---|
| A storage tier holds no records | that tier's targets are excluded from the denominator, the tier is named in the banner, and the affected factor degrades toward `UNMEASURED` |
| No entity records at all in scope | every factor `UNMEASURED`; `MM-0` `UNMEASURED`; a `## Unknowns` coverage note naming the searched population |
| The corpus is unreadable or a record fails to parse | surfaced in `## Unknowns` with what was searched and why it could not be read — never counted as a violation and never skipped silently |
| An entity type has no schema section | a **schema-surface** finding in `## Decisions`, never a record defect |

A coverage note states **what was searched** and **why it could not be measured**. Absence is a third
value alongside pass and fail; collapsing it into either is the error these rules exist to prevent.
