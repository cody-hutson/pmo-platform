---
title: Automation Registry Schema — the routine-spec contract every automation registers into
purpose: The canonical data contract for a routine-spec row in the automation registry — the required fields, their closed value spaces and owning surfaces, the cross-field rules, the physical row grammar, and the rejection classes a conforming validator enforces. The registry data file and the registry gate cite this contract instead of restating the field list.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: core/automations/registry.md (the rows this contract governs); core/deploy/tools/check-automation-registry.sh (the validator that enforces it); the registry-currency gate (resolves its field list and value spaces here, never from a private copy); the scheduler adapter (reads a row's declared cadence and entrypoint at fire time)
---
<!-- reference-durability: allow-link -->
# Automation Registry Schema — the routine-spec contract

**Status:** Canonical. This document is the contract; the rows live at [`../automations/registry.md`](../automations/registry.md).

## 1. What this contract governs, and what it deliberately does not

An **automation** is a recurring platform routine: something the platform declares will run on a cadence, invoking a tracked entrypoint, under a declared governance ceiling. This schema is the **routine spec** — the WHAT. It is one third of a three-way decoupling recorded in the founding architecture decision for the registry:

| Concern | The question it answers | Where it is written | Who owns it |
|---|---|---|---|
| **WHAT runs** | which routine, on what cadence, invoking what | a routine-spec row in the registry, validated against this contract | the platform corpus (git-tracked, public) |
| **HOW it fires** | which backend actually triggers it | the `scheduler` selector on the operator-configuration adapter table, resolved by the scheduler adapter at fire time | the operator instance (git-ignored, restricted-permission) |
| **WHO governs** | how much it may do unattended | the operator-configuration automation-level dial (the effective value); a row carries only a declared default | the operator instance |

**The registry is an admission gate, not a description.** An automation is admitted only if it has a row that validates against this contract. A descriptive registry has no forcing function, so its coverage decays to whatever the last author remembered — which is the defect that motivated the registry, not a hypothetical.

## 2. Field contract

**Every field is REQUIRED. There are no optional fields and no default for an empty cell.** An entry that may omit its `automation_level_default` lets a gate assert *an automation exists* without asserting *the automation declares its ceiling* — which is the ungoverned-routine-ships-green failure the governance field is stored to prevent. An empty cell is a finding, never a default.

**Machine-parse contract.** This table is the single source for both the field names and their closed value spaces. A consumer reads it as: rows matching `^\| [0-9]+ \| \`` yield the field name from the backticked token in cell 2, in declaration order; when cell 4 (**Kind**) reads `ENUM`, cell 5 (**Value space**) yields the closed member set as its backticked tokens, separated by ` · `; when **Kind** reads `SHAPE`, cell 5 carries a shape rule rather than a member set. **No consumer restates the field list or re-declares an enum** — a second copy is a shadow source of truth that drifts the moment this table changes.

| # | Field | Required | Kind | Value space | Owning surface (cited, never restated here) |
|---|---|---|---|---|---|
| 1 | `id` | REQUIRED | SHAPE | matches `^[a-z][a-z0-9-]*$`, and is unique across all rows (it is the registry's primary key) | the skill-name shape carried by the registry-currency predicate at `../deploy/tools/check-registry-currency.sh`, the platform's existing machine-executed registry primary-key rule |
| 2 | `cadence` | REQUIRED | SHAPE | a 5-field cron expression, **or** the literal `event` | the cron forms already carried by the platform's cadence documents; the `event` limb is this contract's own literal for a routine with no schedule |
| 3 | `trigger` | REQUIRED | ENUM | `time-driven` · `event-driven` · `hybrid` | the cadence documents' own mechanism vocabulary, used verbatim rather than re-coined |
| 4 | `entrypoint` | REQUIRED | SHAPE | a bare backticked repo-relative path to a tracked file | the thin-bootstrap principle: a registration points at the tracked spec so it cannot drift from it |
| 5 | `automation_level_default` | REQUIRED | ENUM | `off` · `recommend` · `bounded_auto` | the `automation_level` key's `enum` array in `../config/operator-toml-schema.json` |
| 6 | `reversibility` | REQUIRED | ENUM | `CHEAP` · `MODERATE` · `EXPENSIVE` · `IRREVERSIBLE` | the four tier headings in `../specs/reversibility-protocol.md` |

### 2.1 How a validator resolves each value space

A value space is **PARSED** at run time from its owning surface when that surface exposes a machine-extractable declaration; otherwise it is a **LITERAL** set in the validator, cited in a comment and asserted by the validator's own self-test. This is the platform's existing rule for gate predicates — duplicate a parse, which fails loud, never a policy, which drifts silent.

Every PARSE arm is **cardinality-guarded**: an extraction returning an empty set or an unexpected size is a **scan-surface error**, never a finding storm and never a silent pass. The guard exists because a reformatted source once made an extractor return non-empty garbage that an emptiness check could not catch.

| Field | Resolution | Cardinality guard |
|---|---|---|
| `id` | LITERAL — the shape rule reused verbatim from its owning surface | not applicable (a shape, not a set) |
| `cadence` | LITERAL — a shape check | not applicable |
| `trigger` | LITERAL — the three tokens, prose-homed on their owning surface | not applicable |
| `entrypoint` | resolved against the tree at run time | not applicable |
| `automation_level_default` | **PARSE** from the operator-configuration key schema | exactly 3 members |
| `reversibility` | **PARSE** from the reversibility protocol's tier headings | exactly 4 members |

## 3. The three semantics a field name does not carry

These are stated rather than left to inference, because each is a determination a downstream consumer would otherwise make differently.

### 3.1 `cadence` is a declared default, never the effective schedule

The row states the cadence **the platform ships**. The **effective** schedule is instance-local, resolved by the scheduler adapter from the operator's own registration. The platform's intake-sweep standard says so in terms — the cadence is a registration parameter, operator-configurable, and not hardcoded in a tracked file — and the declared-default reading is the only one under which that sentence and a git-tracked `cadence` column are both true.

This is exactly symmetric with `automation_level_default`: **the row declares, the instance resolves.** An adapter that read `cadence` as the effective schedule would either overwrite the operator's registration on every deploy, or report drift against a value that was never meant to bind.

**Naming residual, stated rather than hidden:** `cadence` is a declared default but is not named `cadence_default`, an asymmetry with field 5. The field names are fixed by the founding decision and three consumers resolve against them, so the semantic is fixed here in the contract instead of by a rename.

### 3.2 `reversibility` is of the routine's ACTIONS, not of shipping its spec

The value is the reversibility tier of **the most-consequential action the routine emits at its declared `automation_level_default`**. It is *not* the `reversibility:` field in the entrypoint document's own frontmatter, which is a ship-time property of publishing that document.

The two differ on the very first row: the intake-sweep standard's frontmatter declares `MODERATE` for shipping the spec, while what the sweep *does* at `recommend` — draft, surface, advance a git-ignored cursor, append a git-ignored run record — is `CHEAP`. Unstated, the first two authors copy the frontmatter and the field means two things across rows on day one.

### 3.3 `automation_level_default` is a ceiling declaration, never an effective value

The effective autonomy is `min(automation_level, per-action max)`, with the operator's dial and the irreducible-human-task floor still applying above the row's declaration. A stored effective value would drift the instant the operator moved the dial.

## 4. The cadence × trigger matrix

The two fields are not independent. The matrix is **total** — every combination is either required or rejected, and no cell is undefined.

| `trigger` | Required `cadence` | Rejected |
|---|---|---|
| `time-driven` | a 5-field cron expression | the literal `event` |
| `event-driven` | the literal `event` | any cron expression |
| `hybrid` | a 5-field cron expression | the literal `event` |

### 4.1 Why `hybrid` requires a cron

A hybrid routine has a manual event limb *and* an automated time-driven limb. **One row registers one routine, and what it registers is the automated limb** — the manual limb needs no registration to fire, because an operator invoking it at its semantic moment *is* the trigger, while the automated limb is the one whose absence is silent. Silent absence is the failure the registry exists to make visible.

`hybrid` paired with `cadence: event` is therefore malformed by construction: it claims a hybrid routine with nothing automated about it, which is just `event-driven`.

This rule is load-bearing, not decorative. Every cadence document currently queued for migration into the registry declares both a manual limb and an automated sentinel, so without the rule each of those rows could be written cron-free and the registry would carry a set of hybrid routines none of which declares a schedule.

## 5. Row grammar — the physical form

Rows live in a single `## Routines` markdown table, six columns in the declaration order of § 2, mirroring the shape of the platform's existing configuration-item registry whose parser contract is already proven.

```
| id | cadence | trigger | entrypoint | automation_level_default | reversibility |
|---|---|---|---|---|---|
| `a-routine-id` | `0 6 * * *` | `time-driven` | `core/standards/some-spec.md` | `recommend` | `CHEAP` |
```

**Cell grammar, so a parser is not guessing:**

- **Every cell is a single backticked token with no prose tail** — `entrypoint` included. A table cell is a field, not a prose line; permitting a tail re-imports the ambiguity that makes a frontmatter value unusable as data.
- A cron expression contains no `|`, so no cell escaping is required.

**`entrypoint` is a bare path and never a markdown link, and the reason is measured rather than stylistic.** The value a consumer needs is the path *from the repository root*, because that is what resolves identically for the validator, the gate and the adapter regardless of where the registry file itself sits. A markdown link carrying that same root-relative path as its target is a **broken link** to the platform's link checker, which resolves a link relative to its source file and has no workspace-root fallback — that fallback is retired by ratified decision, and the checker carries a regression fixture asserting it stays retired. Wrapping the path in a link would therefore make every row a doc-link finding, while wrapping a *file-relative* path in a link would put a value in the cell that no consumer can use without knowing the registry's own location. A bare backticked path is the one form that is both resolvable and directly consumable.

## 6. Rejection classes

A conforming validator rejects exactly these classes. Each class is also a mandatory negative fixture in the validator's self-test: one malformed row per class, each of which must produce exactly that finding.

| Class | Field | Rejected because |
|---|---|---|
| **R-01** | any | an empty cell — REQUIRED means an empty cell is a finding, not a default |
| **R-02** | `id` | a character outside `[a-z0-9-]`, an uppercase letter, or a leading digit or hyphen |
| **R-03** | `id` | two rows sharing a primary key, which makes the join every consumer resolves against ambiguous |
| **R-04** | `cadence` | not 5 whitespace-separated fields, a character outside `[0-9*/,-]`, or a field outside its positional range |
| **R-05** | `cadence` | natural language — `daily`, `weekly`, `hourly` — resolvable by no adapter |
| **R-06** | `cadence` | a timezone suffix or an embedded zone name; the local-versus-UTC split is an adapter property, not a routine-spec one |
| **R-07** | `trigger` | any token outside the three, including case variants and the cadence documents' **display** forms — a row carries the token, not the prose label |
| **R-08** | `cadence` × `trigger` | the cross-field matrix in § 4 |
| **R-09** | `entrypoint` | the path resolves to no tracked file |
| **R-10** | `entrypoint` | an absolute path (also a depersonalization hazard), a home-relative path, a URL, or a path escaping the repository |
| **R-11** | `entrypoint` | prompt text or prose rather than a path — the thin-bootstrap anti-pattern this field exists to prevent |
| **R-12** | `automation_level_default` | a value outside the parsed enum; an autonomy-tier token, which is a different axis this contract cites rather than stores; the bare word `default`; a `min(...)` expression |
| **R-13** | `reversibility` | a value outside the parsed tier set; a lowercase variant; **a compound carrying a prose tail** |

### 6.1 Evaluation order

Several classes could fire on one value, so the order is fixed and the first match wins per field. **Empty first:** an empty cell yields R-01 for that field and suppresses that field's other checks, including the cross-field matrix, so an empty cell reports one finding rather than a cascade.

- `cadence`: the literal `event` is accepted outright; then R-05 (a natural-language word), then R-06 (a timezone form), then R-04 (cron shape and positional ranges).
- `entrypoint`: R-10 (absolute, home-relative, URL, or escaping) → R-11 (not path-shaped, which includes a markdown link) → R-09 (path-shaped but resolving to nothing).
- `id`: R-02 per row, then R-03 once every row is parsed.

### 6.2 Conformance is not coverage

This contract governs **conformance**: does every row that is present satisfy the field contract? It says nothing about **coverage**: does every automation that exists have a row? Coverage is a separate invariant over a different population, asserted by the registry-currency gate.

Keeping them disjoint is what makes a **partially-populated registry a valid state at every intermediate commit**. A validator that also asserted coverage would read red from the moment it shipped until the last consumer migrated — several waves of a red check nobody could fix, which is how a gate gets muted.

**Zero rows is a scan-surface error, not a pass.** The registry ships seeded, so an empty parse can only mean the file was deleted, relocated, or its table shape broke.

## 7. Sources of truth — what is cited, never stored

**A reviewer falsifies the decoupling by finding a stored field in the cited half.**

| Axis | Disposition | Authority when cited | Why it is not a field |
|---|---|---|---|
| the firing backend | **CITED** | the `scheduler` selector on the operator-configuration adapter table, read by the adapter at fire time | it is instance-local and permission-restricted; storing it writes a non-portable fact into public corpus, which is the host-binding leak the registry exists to close |
| the effective automation level | **CITED (computed)** | `min(automation_level, per-action max)` per the dial's ceiling semantic | a stored effective value drifts the instant the operator moves the dial |
| the routine's behavior contract | **CITED** | the tracked spec named by `entrypoint` | copying the contract into the row recreates exactly the drift the thin-bootstrap principle designs against |
| the autonomy tier | **CITED** | the platform's autonomy-tier specification | a second tier vocabulary is a parallel-vocabulary leak |
| a routine-to-routine dependency edge | **not expressible** | — | a known and accepted limit, recorded in § 8 rather than smuggled in as a seventh field |

## 8. Accepted limits

**No routine-to-routine dependency edge.** Routines do form a real graph — one routine's run record is another's input, one advances a cursor a second consumes. This contract has no field for that edge, so the graph is expressible only as prose inside the document named by `entrypoint`.

This is a limit of the *registry*, not a loss in the routine spec: a dependency edge is a relation **between** routines rather than a property **of** one, which is why the platform's other registry carries it as a separate column. The named extension point is a `dependencies` column in that same shape, and the moment to add it is when one routine's **registration** depends on another's — which no current routine's does.

**A self-firing entrypoint is identified by its own path, not by a field.** A routine whose entrypoint is a continuous-integration workflow is fired by its own host rather than by the operator's scheduler adapter. That is derivable from the `entrypoint` value and needs no field: an adapter reads the entrypoint, sees a workflow path, and does not register it on the operator's host scheduler. Adding a "who fires this" field would store the firing backend, which § 7 forbids.
