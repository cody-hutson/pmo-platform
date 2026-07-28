---
title: FinOps Reporting Contract — the C4 reporting + trends phase
purpose: Progressive-disclosure detail for finops-usage-extractor's report-usage.sh — the windowed session-to-work-item join, per-field capability detection, the coverage-label and provenance rules, the trend bucketing and characterization gate, the CLI semantics, and the self-test assertion map.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# FinOps reporting contract (the C4 phase)

Progressive-disclosure detail for `scripts/report-usage.sh`. SKILL.md states the
phase and its four structural rules; this file states how each is computed and why
the obvious alternative is wrong. The store schema is authoritative for record
shapes (`core/schemas/finops-usage-store-schema.md`) and the attribution algorithm
is `core/standards/finops-attribution-convention.md`. Neither is restated here.

## 1. The windowed join — why a report cannot read `rollup.tokens`

A `rollup` row is a **whole-store aggregate**. Its only timestamp, `rolled_up_utc`,
is the roll-up *computation* time and is identical across every row of one run, so
it cannot express a data window: filtering on it is all-or-nothing. There is no
`window_start` / `window_end`, and `tokens` / `session_count` are unbounded totals.

A windowed, work-item-sliced figure is therefore computed as:

1. Invert `rollup.session_ids[]` into a map
   `session_id -> {work_item, work_item_kind, attribution_tier, reproducible}`.
2. Filter `session` records on `started_utc`. ISO-8601 compares chronologically as
   a string, so the bound is a lexicographic prefix comparison — the same property
   the extractor's deterministic sort already relies on.
3. Re-sum the four cost-relevant leaves (`input + output + cache_creation.total +
   cache_read`) over **`session` records only**. `subagent` records are an
   attribution drill-down already inside their session's total and are never added
   on top (the schema's summation invariant).
4. A windowed session with no map entry lands in an explicit **`(not-rolled-up)`**
   bucket — distinct from `unattributed`, which means the resolver ran and could
   not resolve. This one means the resolver never saw the session. Never dropped,
   never folded into another bucket.
5. Row provenance travels through the join unchanged: `attribution_tier` and
   `reproducible` verbatim from the rollup row; `token_source` **recomputed over
   the filtered subset** using the extractor's own rule (`heuristic_turns == 0` ->
   `exact`; `>= turns` -> `heuristic`; else `mixed`).

Two alternatives were rejected. Reading `rollup.tokens` and filtering
`rolled_up_utc` is wrong under any window (see above). Re-running the C2 resolver
over the windowed sessions is correct but duplicates the entire ordered resolver
and its hub-state / event-log surfaces — a second copy of the attribution
algorithm that would drift from the first.

**Conservation.** The sum of all rendered rows — including `unattributed`,
`multi-branch` and `(not-rolled-up)` — equals the sum of `session.tokens` over the
window. Necessary, not sufficient: it proves nothing was dropped or
double-counted, not that any individual attribution is correct.

## 2. Capability detection — never the version string

Availability is probed **per field on the windowed `session` records**, never from
`meta.schema_version`. Two independent reasons:

- From schema v1.2.0 the version no longer encodes which phase has run — both
  extraction and roll-up emit the same value — so it cannot answer "are the
  analysis dimensions present?".
- The roll-up rewrites `meta.schema_version` unconditionally on every pass, so a
  consumer gating on it is reading a value the last writer stamped, not a
  capability.

The canonical **"a roll-up has run"** predicate is therefore
`any(.record == "coverage")` — that run-level record is emitted exactly once per
roll-up run and is mandatory. When it is absent the work-item dimension renders an
explicit unavailability line naming the fix, and every other dimension still
renders.

A dimension absent from every session in the window renders
`UNAVAILABLE: dimension absent from every session in window ...` — **never a silent
omission**, because an omitted by-skill section reads as *"no skill spend"*, which
is a false zero rather than a missing capability. `meta.schema_version` appears in
the report header as provenance only.

## 3. Coverage-label honesty

`by_skill` and `by_mcp` are **best-effort**: the source population is partial.
Their coverage lives at `session.dimension_coverage.by_<x>` as a two-field object
`{covered_token_fraction, basis}` on a **token basis** —
`1 - (by_X."unknown" / session total)`. Every coverage read funnels through one
accessor, and the aggregate over a session set is the token-weighted mean, which
is exactly `1 - sum(unknown) / sum(total)`.

Enforcement is structural rather than conventional:

- The coverage clause is **concatenated into the section-header string** inside one
  `section_header` function, called from one `emit_dim_table` that both the
  markdown and the JSON path consume. A best-effort header without `coverage:` is
  unrepresentable, not merely forbidden — there is no second emit path.
- An absent field renders `unknown (coverage field absent — treat as 0% verified)`.
  Never `100%`, never nothing.
- In JSON, `grade` and `coverage` are sibling **required** keys produced by the
  same function that builds the header.
- Each per-period trend row carries **that period's** coverage; a whole-window
  figure would hide period-to-period capture drift.

**The reserved `"unknown"` key is the uncovered remainder, not a dimension value.**
Every token-bearing `by_X` map carries it, always present and possibly zero, under
the conservation invariant `sum(by_X.*.tokens) == session.tokens`. Rendering it as
though it were a skill named "unknown" would report uncovered spend as covered. It
is lifted out of the row set entirely and rendered as an explicitly-labelled
uncovered-remainder artefact, alongside a `Not captured: N%` statement. For an
**exact** dimension the remainder is provably zero, so a zero row is suppressed as
noise; a non-zero one is fail-visible and always rendered.

## 4. Provenance — three layers

1. **The marker rides the numeral.** `12,340` is exact; `~12,340` is not. A figure
   pasted into a chat message or a spreadsheet cell carries its own provenance even
   when a tag column is dropped — the property a trailing tag alone lacks.
2. **An explicit tag column**, reusing the platform's evidence-label vocabulary:
   `exact` -> `[SOURCE: exact message.usage]`, `heuristic` -> `[INFERRED:
   ceil(words/0.75) fallback]`, `mixed` -> `[MIXED: N heuristic turn(s) of M]`, and
   the uncovered remainder -> `[UNCOVERED: reserved "unknown" bucket]`. Every
   work-item row additionally carries its attribution weighting, with the
   reliability grade taken from the attribution convention's own tier table.
3. **A mandatory header block** declaring the window, the store-resolution chain
   (**the path value is deliberately not printed** — it is an operator home path —
   so a figure stays reproducible without leaking it), the store's declared
   `schema_version` / `generator_version`, the session count, the no-proration
   bucketing rule, and the legend.

The invariant the self-test asserts: **no bare numeral.** Every token figure either
sits on a row tagged `[SOURCE: exact message.usage]` or carries a leading `~`.

## 5. Trend design

| Decision | Choice and rationale |
|---|---|
| Bucket key | `session.started_utc` — the only per-session time anchor at session grain. |
| Granularity | `--period day\|week\|month`, default `week`. |
| Week definition | **Monday-start UTC weeks labelled by start date** — not ISO week numbers, which carry week-53 / year-boundary ambiguity. The label sorts lexicographically = chronologically. |
| Boundary-spanning session | Assigned **wholly** to its `started_utc` bucket. **No proration** — proration needs per-turn timestamps, i.e. turn grain, which the store does not carry. Stated in the header, never silently applied. |
| Bucket set | **Dense.** Every bucket from window start to end is generated, then left-joined. An omitted empty bucket makes a gap read as continuity, so density makes "empty renders explicitly" structural rather than incidental. |
| Empty period | An explicit `0 ... (empty — no sessions in this period)` row, **excluded from direction**: a zero-spend week is usually an absence of work, not a spend trend, and including it lets a vacation read as a decline. |
| Partial period | The bucket containing today is tagged `(partial — period ends D; excluded from trend direction)`. Shown, because the operator wants today's number — but never a trend's last point, which is the classic false decline. |

**Direction requires at least 3 non-empty, complete periods.** Two points define a
line, not a trend. At n=2 the trend view still renders — per-period table, bucket
definition, per-period provenance — and only the *characterization* is withheld
(`TREND: INSUFFICIENT`). At n>=3, direction compares the mean of the first half
against the mean of the second half over complete buckets (with an odd count the
middle bucket is dropped), reported as `RISING` / `FALLING` / `FLAT` against a
plus-or-minus 10% band.

**The trend-characterization gate.** Direction is emitted **only** for a dimension
whose registry grade is `exact`. On a best-effort dimension the report renders
per-period volume and per-period coverage and emits no direction, no arrow and no
percentage delta, because a change in coverage is not separable from a change in
spend. Concretely: if coverage is 10% in week 1 and 30% in week 4, "skill X's spend
tripled" may be entirely a capture-rate change. This is a hard rule on the **same
registry** that drives the coverage label — a direction claim *is* a completeness
claim, so both share one enforcement point and there is no threshold to mis-tune.

Secondarily, when per-period coverage spreads by more than 10 percentage points an
explicit `COVERAGE-DRIFT` note is appended, so the capture-rate jump sits on the
same line as the volume jump. It is informational: the gate already prevents the
false claim, and the note explains why the direction is withheld.

Two provisional constants — the FLAT band and the coverage-drift threshold, both 10
— are `[RECOMMENDED]`, stated inline in the output, and calibratable downstream.
Neither is load-bearing; the gate does the honesty work structurally.

## 6. CLI semantics

- `--window N[d]` — the last N calendar days **inclusive of today** (so
  `--window 1` is today only). Mutually exclusive with `--since` / `--until`; both
  present -> exit 2.
- `--since D` means `started_utc >= D + "T00:00:00Z"`; `--until D` means
  `started_utc < (D plus one day) + "T00:00:00Z"`. **Both bounds are inclusive of
  the named day.** Bounds are UTC by definition, which is why the argument is
  date-only rather than full ISO.
- `--by` — there is deliberately **no `project` value**. The store carries no
  PMO-project field, so `--by project` exits 2 with a message saying exactly that
  and naming `--by worktree` as the directory dimension. The label discipline is
  three-layered — CLI vocabulary, column header, and an always-emitted legend line
  — so losing one still leaves two.
- `--json` — the machine shape. Diagnostics go to stderr; **zero files are
  written**, a deliberate data-hygiene posture: no artifact exists that could be
  accidentally staged.
- Exit codes match the sibling scripts exactly: `0` ok, `2` usage, `3` store
  unreadable, `4` store-not-git-ignored (the fail-closed public-repo exfil guard),
  `5` missing dependency. An **empty window exits 0** and says so — an empty result
  is an answer, not an error.
- Test-only clock override: `FINOPS_REPORT_NOW=YYYY-MM-DD`.

**Portability note (load-bearing).** On BSD `date` the `-v` adjustment must precede
the positional value; the wrong order returns *today* in the default format instead
of failing, which would silently widen the window rather than error. Every computed
bound is shape-validated and a malformed one is fatal.

## 7. Inherited helpers

Six helpers — `preflight_deps`, `generator_version`, `toml_val`, `workspace_root`,
`resolve_store`, `guard_store_git_ignored` — are lifted **verbatim** from
`rollup-attribution.sh`, which itself carries them verbatim from
`extract-usage.sh`. Converging all three onto a shared library was rejected for
this slice because it would pull this change into the two most-contended files in
the release; instead `--self-test` extracts each helper body from **both** files
and fails on any difference, so the duplication is a test-enforced invariant rather
than a latent fail-open. Convergence becomes a delete-and-source follow-up.

## 8. Self-test map

`--self-test` runs against `test-fixtures/report/` only — no operator store, no
network. **Every assertion fails closed:** a render that aborts, exits non-zero or
produces empty output is a FAIL, and each negative assertion is paired with a
positive control so an empty search space can never read as "no violations".

| ID | Asserts |
|---|---|
| SM-1 | The six inherited helpers are byte-identical to `rollup-attribution.sh`'s (an empty extraction is a FAIL, not a skip). |
| SM-1b | Store inside a git repo and not ignored -> exit 4; store outside any repo -> proceeds. |
| SM-2 / SM-2n | Every best-effort section header carries `coverage:` in markdown, JSON **and** the trend view; with the field deleted it renders the explicit unknown clause, never a number. |
| SM-3 | No bare numeral, over both the JSON model and the rendered markdown; a heuristic row and a `pr-resolved` row are present and visually distinct. |
| SM-3b | **The silent-zero regression.** The by-skill slice renders the fixture's known non-zero total, not `0` — the assertion that catches an accessor reading the `{turns, tokens}` wrapper as a bare tokens object. |
| SM-3c | The reserved `"unknown"` key never appears as a dimension row, and the uncovered-remainder artefact is present and non-zero. |
| SM-4 | No `/Users/` or `/home/` substring and no `project_dir` value in any render — against fixtures that deliberately contain both forms. |
| SM-5 | Conservation over the window; `subagent` records contribute zero; the `(not-rolled-up)` bucket exists. |
| SM-6 | Window bounds are inclusive of the named days and a single-day window selects exactly the expected set. |
| SM-7 | Empty period explicit, current period partial and excluded, a direction at n>=3, `INSUFFICIENT` at n=2. |
| SM-8 | **The gate.** A rising by-skill signal still yields `NOT CHARACTERIZED`; the coverage-drift note fires. |
| SM-9 / SM-9b | A pre-v1.2.0 store degrades to explicit `UNAVAILABLE` and still exits 0; a store with no `coverage` record renders the work-item dimension unavailable **despite** declaring a current `schema_version`. |
| SM-10 | The exit-code contract, including the `--by project` message and the empty-window exit 0. |
| SM-11 | `--json` matches `report.expected.json` modulo `generated_utc`. |
