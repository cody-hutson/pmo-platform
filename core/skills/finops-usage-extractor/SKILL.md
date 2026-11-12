---
name: finops-usage-extractor
description: >
  Extracts per-session and subagent token-spend from local Claude Code sessions into the operator-
  local, git-ignored FinOps usage store, rolls it up to its work item, reports windowed spend and
  trends by work item, worktree, skill, MCP and model, and ESTIMATES a planned item's token cost
  from historical comparables — with a stated basis and confidence, declining below three
  comparables rather than implying false precision. Read-only; every figure carries its provenance
  and prints to stdout. Distinct from context-budget-auditor, which measures STATIC corpus
  footprint; this measures RUNTIME session spend. Triggers: "extract token usage", "refresh the
  finops store", "how much token spend", "run the finops extractor", "roll up token usage",
  "attribute token spend", "report token spend", "finops report", "spend by work item", "token
  spend trend", "where did the tokens go", "estimate token cost", "how many tokens will this
  take", "finops estimate", "token budget for this work item", "estimate vs actual token spend".
version: v5.08
license: BUSL-1.1
delivery_approach: advisory
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# finops-usage-extractor

## Purpose

Read-only extraction of runtime token spend from local Claude Code session transcripts into the operator-local usage store defined by `core/schemas/finops-usage-store-schema.md`. It sums each session's exact `message.usage` token dimensions (input / output / cache-write with tier split / cache-read) **once per API response** — a response's transcript lines grouped by `message.id`, each field max-merged — plus tool-use request counts and the cost-determining `service_tier`, and normalizes them into a versioned JSONL derived cache. Exact source counts are authoritative; the context-budget-auditor skill's `ceil(words/0.75)` heuristic is the fallback for records that lack `message.usage`.

This skill measures **runtime session spend** — distinct from context-budget-auditor, which measures **static corpus footprint**. It reuses that skill's estimation *method* (the word→token fallback), not its scanner.

## Scope

Four phases over one source (the local session store), one skill:

- **Extraction + normalization (C1).** `extract-usage.sh` parses local Claude Code session transcripts into the **v2.0.0** store (`meta` / `session` / `subagent` record kinds; `provider` reserved-optional). **Every token and turn figure is counted once per API response within one transcript file** — the transcript writes one line per content block and repeats the response's usage on each, and a partial streaming `output_tokens` loses to its final value. The unit stops at the file: a response that a resumed or forked session copies into a second transcript file is counted once in each, 2.52 % of per-response mass overall and 7.39 % of main-session mass (measured 2026-11-05); removing it needs a cross-file index, which a separate follow-up owns. **Stores built before v2.0.0 counted per transcript line and are inflated** (×2.33 cache-read, ×2.74 cache-write, ×1.78 output, ×3.35 uncached input over the corpus measured when the defect was found); they are identifiable by `meta.schema_version` 1.x, and the schema's § Counting unit states the factors and their limits. Per the data-minimization control at v1.2.0, the `session` record persists `worktree` — the working-directory **basename** — and never the full absolute path. Exact `message.usage` counts are primary; the word→token heuristic is the usage-less fallback. v1.2.0 also adds five **session-grain analysis sub-aggregates** the intelligence layer slices on — `by_skill` / `by_mcp` / `by_model` / `tool_calls` / `stop_reason` — plus `dimension_coverage`. Each token-bearing map reuses the identical four-leaf `session.tokens` shape (so *"which skill's cache-reads?"* is answerable) and carries an **always-present reserved `"unknown"` bucket** holding the uncovered remainder, which is what makes `Σ by_X.*.tokens == session.tokens` hold even where the source population is partial. `by_skill` / `by_mcp` are **best-effort** and MUST be rendered with their `dimension_coverage` label; `by_model` / `tool_calls` / `stop_reason` are exact by construction and deliberately carry no coverage entry. `by_model` is a true per-turn partition that **supersedes** the dominant/last `session.model` for cost-splitting a mixed-model session; `tool_calls` (client-side invocations by name) is a distinct sibling of `tool_use` (server-side requests) and is never folded into it.
- **Attribution + roll-up (C2).** `rollup-attribution.sh` reads that store and writes the additive `rollup` + `coverage` records (record kinds introduced at v1.1.0): it resolves each `session` to its owning work item, rolls per-session spend up to that work item (honoring the summation invariant), and emits a run-level attribution-health `coverage` record. The session→work-item mapping ALGORITHM — the ordered LOCAL-ONLY resolver (issue-event key → release/chore branch → hub-state lineage → `unattributed`, plus an opt-in network PR-resolve) — lives in `core/standards/finops-attribution-convention.md`; the record SHAPES live in the store schema. Milestone-grain is reliable from local data alone; issue-grain is best-effort (a decision-event key, or the opt-in `--resolve-prs` resolve); everything unresolved lands in an explicit `unattributed` bucket, fail-visible. Reliable issue-grain and a hub-vs-spoke role split need a hub-emitted spawn-ledger marker, which the store's **v1.2.0 analysis dimensions did NOT deliver** — it remains an open enhancement on the Agent-FinOps parent epic, and until it lands neither is available. The v1.2.0 `by_skill` dimension is a *weaker, best-effort* substitute for the skill question only; it does not separate hub from spoke.
- **Reporting + trends (C4).** `report-usage.sh` reads that store and renders an operator-facing spend report over a date window — sliced by work item, worktree, skill, MCP server and model — plus a period-bucketed trend view. It **writes nothing at all**: the report prints to stdout, so no artifact exists that could be committed. Four rules are structural rather than conventional, and each is enforced at a single code site: (1) **the windowed join** — `rollup` rows are whole-store aggregates with no time bounds, so a windowed figure inverts `rollup.session_ids[]` into a session→work-item map, filters `session` records on `started_utc` and re-sums, rather than reading `rollup.tokens`; (2) **coverage-label honesty** — the coverage clause is concatenated *into* the section header in the one renderer both output shapes consume, so an unlabelled best-effort slice is unrepresentable, and the reserved `"unknown"` bucket renders as an explicit uncovered remainder rather than a dimension value; (3) **provenance** — the marker rides the numeral (`12,340` exact, `~12,340` not), so it survives a paste that drops the tag column; (4) **the trend-characterization gate** — a direction is emitted only for an `exact`-grade dimension, because on a best-effort one a coverage change is not separable from a spend change. Availability is detected **per field on the windowed records**, never from `meta.schema_version`, and the "a roll-up has run" predicate is the presence of the `coverage` record. Full contract — the join algorithm, the rejected alternatives, the bucketing rules and the self-test map — in [`references/reporting-contract.md`](references/reporting-contract.md).
- **Estimation (C3).** `estimate-usage.sh` reads that store and produces a token-cost **estimate for a PLANNED work item** from historical comparables, with a stated basis and confidence. The store carries **no work-item size / type / scope field**, so every matcher is a join *out* of the store; the default join is **LOCAL and in-repo** — a `rollup` row keyed `milestone:vX.Y` joins `release/releases/RELEASE_LOG.md`'s governed `**Velocity:**` field for `(planned points, release class)`, so milestone-grain matching needs no network call. Issue-grain matching needs GitHub labels and is therefore **opt-in** (`--resolve-labels`), exactly as `--resolve-prs` is. The matching ladder is ordered and first-match-wins with a terminal fail-visible tier: **E1** explicit (`--like`) → **E2** class + points (default) → **E3** pooled tokens-per-point rate → **[opt-in] E-LBL** issue labels → **E4 DECLINE**. Four rules are structural: (1) **`N_min = 3` is a HARD floor** — below three comparables *no* estimate is emitted, because at n=2 the median **is** the mean (the outlier-robustness it was chosen for silently evaporates) and at n=1 dispersion is zero, so every confidence signal reads maximally tight; a decline is an answer, exit 0. (2) **Median, never the mean** — token spend is right-skewed; the mean renders only as a labelled *not-used* contrast so the skew stays visible. (3) **Confidence is a total, ordered function of `(n, rMAD)`**, capped down by evidence quality (best-effort token fraction, admitted non-reproducible rows, the pooled-rate tier, the network tier) — the label itself moves, it is not merely annotated; the 0.25 / 0.50 band edges are reused from this skill's own `coverage.health` bands so the estimator and the roll-up speak one vocabulary. (4) **`$` fires only on the presence of a `provider` record**, whose sole producer is the OFF-by-default connector that ships with no live endpoint — so **volume is the only reachable mode today and the header says so**, and the rate, when it exists, is derived from the record's own cost/token pair rather than any price table. `--delta` adds a **leave-one-out re-derivation**: rebuild a closed item's comparable set with that item excluded, run the identical estimator, and report `estimate → actual` with the signed delta and percentage error — zero writes, zero new records, zero schema surface. The roll-up-has-run predicate is the presence of the `coverage` record, never `meta.schema_version`. The band→telemetry cutover this phase feeds is governed at [`quota-budget-protocol.md`](../../../release/references/standards/quota-budget-protocol.md) § 5.1, with the substrate decision at [`ADR-102`](../../../release/ADRs/ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md).

## Usage

```
bash core/skills/finops-usage-extractor/scripts/extract-usage.sh [--rebuild | --incremental] [--self-test]
```

- **`--rebuild` (DEFAULT):** truncate + rewrite the entire store from source (idempotent by construction — deterministic record order, byte-identical across runs over unchanged source; atomic tmp-then-`mv`). At a counting-unit boundary — a store whose schema major version differs — it first keeps the prior store once, as `prior/schema-<old>/usage.jsonl` beside the store, readable with `STORE=<store>/prior/schema-<old>`.
- **`--incremental` (opt-in):** mtime-gated optimization — upsert only sessions whose transcript changed since the last extraction; one record per `session_id`, newest-wins. Falls back to `--rebuild` when the store declares another counting unit (another schema major version).
- **`--self-test`:** run the built-in assertions (heuristic estimator, cache-tier invariant, idempotence, the value oracle, the per-response arms (a three-block response counted once; a partial-output subagent response recorded at its final value), the counting-unit-boundary arm, and the v1.2.0 analysis-dimension invariants — reserved-bucket presence, `Σ by_X.*.tokens == session.tokens`, `Σ stop_reason.* == turns`, and the `dimension_coverage` projection) against the synthetic fixtures in `test-fixtures/` — no source or store access required.

The optional plan-gated provider connector (`scripts/provider-usage-connector.sh`) is **OFF by default** and never on the critical path — extraction completes fully from local session data alone.

Roll-up + attribution (run after extraction):

```
bash core/skills/finops-usage-extractor/scripts/rollup-attribution.sh [--emit] [--resolve-prs] [--self-test]
```

- **`--emit` (DEFAULT):** resolve every `session` to its work item and write the `rollup` + `coverage` records into the store (strip any prior ones, append fresh, preserve the store's `meta.schema_version` — never re-stamped; it names the counting unit). **LOCAL-ONLY** — no network, no `gh`. A store predating v1.2.0 (session records carrying `cwd`, not `worktree`) is **refused with exit 3** naming the rebuild command, rather than silently rolled up into an empty result. Idempotent over an unchanged store (byte-identical body modulo the `rolled_up_utc` metadata); session/subagent lines untouched.
- **`--resolve-prs` (OPT-IN):** additionally resolve `fix/*` / `feat/*` branches via a read-only `gh` PR→closing-issue query (network; non-reproducible). Absent → those sessions degrade to `unattributed`. Every resulting row is stamped `attribution_tier: pr-resolved` + `reproducible: false`.
- **`--self-test`:** run the ground-truth labeled-fixture attribution check (CIAC-1 primary), the conservation identity (secondary), coverage + health, multi-branch bucketing, idempotence, and the pre-v1.2.0 store-shape preflight (a legacy `cwd`-carrying store must be refused with exit 3) against the synthetic `test-fixtures/rollup/` set — no operator-store or network access.

Reporting + trends (run after extraction, and after roll-up for the work-item slice):

```
bash core/skills/finops-usage-extractor/scripts/report-usage.sh [--window N[d] | --since YYYY-MM-DD --until YYYY-MM-DD] [--by work-item|worktree|skill|mcp|model|all] [--trend] [--period day|week|month] [--json] [--self-test]
```

- **`--window N[d]` (DEFAULT 30):** the last N calendar days, inclusive of today. **Mutually exclusive** with `--since` / `--until`.
- **`--since` / `--until YYYY-MM-DD`:** the absolute window a retro or quarter close needs; **both bounds are inclusive of the named day**. Bucketed on `session.started_utc` (UTC).
- **`--by` (DEFAULT `all`):** the slice dimension. `work-item`, `worktree` and `model` are **exact**; `skill` and `mcp` are **best-effort** and always render their coverage label. There is deliberately **no `project` dimension** — the store carries no PMO-project field, and `--by project` exits 2 saying so. `worktree` is the session's working-directory **basename**: a filesystem directory name, NOT a PMO project.
- **`--trend` / `--period` (DEFAULT `week`):** the period-bucketed view. Weeks are Monday-start UTC weeks labelled by start date; the bucket set is **dense**, so an empty period renders as an explicit row rather than being omitted, and the period containing today renders tagged `(partial …)`. Both are shown and both are excluded from trend direction. A boundary-spanning session is assigned wholly to its `started_utc` bucket — no proration. Direction requires ≥3 non-empty complete periods; below that the table renders and the characterization is withheld. A dimension **absent from every session in the window** is gated, not zeroed: it renders `available: false` with its reason and an **empty** row set — so an exactness tag is unrepresentable rather than merely forbidden — and a non-empty period whose sessions all lack the field renders `measurable: false` / `figure "—"`. `0 [SOURCE: exact message.usage]` would make "we cannot measure this" indistinguishable from "we measured zero". The gate reuses the **same** predicate the slice sections use, so the two surfaces cannot drift.
- **`--json`:** the machine shape. Coverage, grade and provenance are **sibling required keys** on the same objects the markdown path renders — there is no second emit path that could drop them.
- **`--self-test`:** run the built-in assertions against the synthetic `test-fixtures/report/` set — no operator-store or network access. Every assertion **fails closed**: a render that aborts or emits nothing is a FAIL, and each negative assertion carries a positive control so an empty search space cannot read as a pass. Assertion map in [`references/reporting-contract.md`](references/reporting-contract.md) §8.
- **An aborted render never exits 0.** The renderer's status is captured, so a `jq` abort (a truncated store line, a malformed `tokens` value, a malformed `session.started_utc`) exits **3** with a named `FATAL` on **stderr**, and a zero status with empty stdout is fatal too. `rc=0` + empty stdout is byte-identical to the empty-window answer — and the empty-window answer is a *full report saying so*, never silence.

Estimation (run after extraction **and** roll-up — the comparable set is built from `rollup` rows):

```
bash core/skills/finops-usage-extractor/scripts/estimate-usage.sh [--class C --points N | --size XS|S|M|L|XL | --like WI[,WI...]] [--type T] [--tolerance N] [--include-nonreproducible] [--resolve-labels] [--delta WI] [--json] [--verbose] [--self-test]
```

- **`--class C` + `--points N` (the default path):** match milestone-grain comparables on `(release class, planned points ± tolerance)`, read from the release log's `**Velocity:**` field. **LOCAL** — no network.
- **`--size XS|S|M|L|XL`:** translated through the canonical point scale (`XS=1 / S=2 / M=4 / L=8 / XL=16`), which is **cited by role from `bundle-composition-doctrine.md` § 3 Step 5, never redefined here**. Mutually exclusive with `--points`. An out-of-set size is a **source-integrity violation → exit 2**, never coerced to a nearest bucket.
- **`--like WI,…`:** name the comparables explicitly (tier E1). The one path that works against a thin store on day one, and deterministic. Mutually exclusive with `--class` / `--points` / `--size`.
- **`--tolerance N` (DEFAULT `max(2, round(0.5 × points))`):** the points-band half-width. The floor of 2 is the point value of `size:S`, so the band is never narrower than one bucket step; the proportional half-width bands a 4-pt item and a 20-pt release equally well, which a fixed ±N does not. `[RECOMMENDED]`, printed inline.
- **`--include-nonreproducible`:** admit `pr-resolved` comparables (excluded by default). **Caps confidence at LOW** and stamps the whole output `reproducible: false` — a non-reproducible figure must never be read as a stable calibration datum.
- **`--resolve-labels` (OPT-IN / NETWORK / non-reproducible):** resolve issue-grain `size:` / `type:` labels via `gh`. **Off by default**, exactly as `--resolve-prs` is; caps confidence at LOW. A `gh` failure degrades to the local path rather than fabricating a thinner-but-plausible population.
- **`--delta WI`:** leave-one-out re-derivation for a *closed* work item already in the store — rebuild its own comparable set with it excluded, run the identical estimator, and report `estimate → actual`, the signed delta, the percentage error, and the estimate's basis + confidence. **Writes nothing**; the store is a derived cache and the estimator a pure function of it, so the counterfactual is exactly reproducible. This is the instrument that measures the estimator's **accuracy** (as opposed to its self-consistency) and the one that calibrates `quota-budget-protocol.md` § 5.1's cutover predicate. Two hard preconditions, both fail-closed: (1) the target must carry a **rollup row** (its measured actual) — a target with no rollup row, the default for any work item predating the store's coverage window, is **refused with exit 3** on stderr and renders nothing, never an unrequested forward estimate under prose asserting a back-test ran; and (2) when the point estimate is suppressed (below `N_min`, or above the rMAD ceiling) the **signed delta and % error are suppressed with it**, because either one recovers the withheld figure from `actual` in a single arithmetic step (`estimate = actual + delta`). A figure the estimator explicitly declined to emit must not be recoverable by arithmetic from the same output.
- **`--verbose`:** additionally list every excluded row with its **named** exclusion reason, so an unexpectedly thin population is diagnosable rather than mysterious.
- **`--json`:** the machine shape. Basis rows and the confidence label are produced by the **same** functions the markdown path uses, so an estimate without its basis is unrepresentable in either surface.
- **`--self-test`:** run the built-in assertions against the synthetic `test-fixtures/estimate/` set — no operator-store or network access. Every assertion **fails closed**, and each negative carries a positive control (the coverage-gate check pins `meta.schema_version` to `1.2.0` on purpose, so a version-based gate could not pass it).

## Cost-unit conversion

```
bash core/skills/finops-usage-extractor/scripts/convert-usage.sh --convert < objects.json
bash core/skills/finops-usage-extractor/scripts/convert-usage.sh --params
bash core/skills/finops-usage-extractor/scripts/convert-usage.sh --self-test
```

`convert-usage.sh` is the **one conversion** from per-response token totals to weekly points (wp) of one account. What a weekly point is, how tokens are counted, the conversion's terms and the pair rule are canonical in {{ADR:release-graph-cost-unit}}; the script implements that record and restates none of its calibrated values.

- **One implementation.** Every figure-producing tool — the per-release cost row (`release/tools/compute-release-velocity.sh --cost-row`) and the command-template ranking — calls this script for weekly points and never re-implements the weights, the bracket or `K`. A second conversion is a defect, not an optimization.
- **One numeric home.** It reads the bracket, `K` at both ends, the price-relative weights, the calibration model and the per-model axis only from the `[cost_unit]` section of the platform behaviour configuration, on two rungs: the shipped template, then the operator's individual `platform-config.toml`, which wins key by key. A packaged copy of this skill sits outside any checkout, so it reads the template through `PMO_SRC_ROOT` or `${CLAUDE_WORKSPACE_ROOT}/pmo-platform`.
- **Fail closed.** A numeric value absent at every rung, empty, non-numeric or not positive — or a bracket whose low end is not below its high end — exits **3** and names the key and the rungs read. The caller records an **unresolved** figure: never zero, and never a built-in constant.
- **`--convert` contract.** Stdin is a JSON array. Each element is a store `tokens` object, or `{"tokens": …, "by_model": {…}}` carrying the store's exact per-model split, which must sum to its tokens leaf by leaf. Stdout is one JSON object: `params` (the values used, and the rung they came from), `label` and `label_source`, and `pairs` in input order, each `{at_w_low, at_w_high, per_model, unprobed_models, own_window_models}`. `--params` prints the resolved values alone.
- **The pair is keyed by bracket end, never "low" and "high".** Each end uses its own `w` and its own `K`; no midpoint and no cross-end mix is ever formed. Which member is larger depends on the token mix — an output- or write-heavy figure is larger at the low-`w` end, because that end's `K` is smaller — so neither member is a lower bound, and a consumer must not sort the two into a range.
- **The per-model axis.** Over a split, a model with a recorded draw multiplier contributes at that multiplier, the calibration model at 1, and any other model at 1 while being named in `unprobed_models`. A model whose recorded weekly windows exclude the shared all-models window draws no weekly points and is listed in `own_window_models`, not summed. An object without a split reads `per_model: "not-split"`.
- **The calibration label** — `calibration: insufficient` or `calibration: sufficient` — is read from the latest dated seed or revisit line of the cost unit's row in the gate-coverage register (`core/standards/gate-efficacy-standard.md`), the line every calibration revisit leaves. An unreadable register reads `calibration: unresolved`, and the figures are still computed.
- **It writes nothing**: like the report and the estimator, it prints to stdout only.
- **Exit codes (this script's own):** `0` OK · `1` usage error or missing `jq` · `2` malformed input (not an array; a missing, non-numeric or negative leaf; cache-write tiers above their total; a split that does not sum) · `3` an unresolved value.
- **`--self-test`:** offline arms over temporary configurations with synthetic values only — never the shipped calibration, which the record moves by editing the numeric home alone — with both rung seams pinned in every arm.

## Promotion-candidate ranking

```
bash core/skills/finops-usage-extractor/scripts/rank-command-templates.sh [--window N[d]] [--top N] [--signals N] [--work-item REF] [--out-dir DIR]
bash core/skills/finops-usage-extractor/scripts/rank-command-templates.sh --self-test
```

`rank-command-templates.sh` reads the local session transcripts directly — the extractor's source root and walk, and the store schema's § Counting unit — and ranks the procedures agents keep retyping, Bash commands and tool inputs reduced to a closed-vocabulary shape, by repetition across sessions and by cost in weekly points at both bracket ends. It is the detector the promotion framework's §1 names: it suggests a rung and never decides one. Its report is local and derived only.

| Option | Default | What it controls |
|---|---|---|
| `--window N[d]` | 30 | days of transcripts, selected by file modification time |
| `--top N` | 25 | rows in `SUMMARY.md` |
| `--signals N` | 5 | Mode C caller-input records prepared |
| `--work-item REF` | `unlinked` | the report's `work_item:` frontmatter value |
| `--out-dir DIR` | the analysis home | the report root |

- **Where it runs.** The ranker needs the platform checkout, because it reads the command-start canonicalizer, the path resolver and the path-leak primitive there, and the checkout's tracked set. It takes `PMO_SRC_ROOT`, else the checkout it sits in, else `<workspace-root>/pmo-platform`; a deployed copy with none of the three exits **2**. Source: `FINOPS_SOURCE_ROOT`, else the session store under the Claude configuration directory. The default report home is `<OPERATOR_INSTANCE_ANALYSIS_PATH>`, resolved by `pmo_analysis_path_for` from the workspace root — `WORKSPACE_ROOT`, else `CLAUDE_WORKSPACE_ROOT`, else `operator.toml`'s `claude_workspace_root`, else the default root — so an install that sets the root only in `operator.toml` still reports under it. The home ships with the checkout; a missing home exits **3**, never created by the ranker.
- **How it ranks.** Every token outside the closed vocabulary — operators, listed command and subcommand words, flags listed for their own command, tracked paths — becomes a typed placeholder (`<ARG>`, `<PATH>`, `<SLUG>`, `<FLAG>`, `<CODE>`, `<HEREDOC>` and their kind). A flag after an interpreter's script operand is always `<FLAG>`, because the script defines it. Comments are stripped line by line, as the shell reads them, and heredoc bodies, substitutions and `${…}` are masked before tokenizing. Every command then passes once through the governed command-start canonicalizer, `core/hooks/lib/command-position.awk`, in one process per transcript file, so a command after a keyword, a wrapper or an assignment keeps its command word. A procedure is each segment's command and subcommand words joined by their operators, with its exact masked forms listed as variants. An occurrence costs its call and its result, each written once by the next response and re-read by every later response until a compaction, at 1.5 characters per token, converted by `convert-usage.sh` at both bracket ends; shares lead. A procedure ranks only when it appears in at least two sessions, each `tool_use` id counted once across files.
- **Memory.** It reads one transcript file at a time. A first pass reads each file only up to its first timestamped record, to fix the order; then each file is parsed, costed, keyed and folded into the procedure accumulators, and its records are released before the next file is read. Only the copied-id set, the accumulators and the session metadata outlive a file, so memory follows the largest file, not the window. The self-test's memory arm measures it.
- **Cost bound.** The attributed figures are checked against the measured usage: the tool tokens attributed to a response never exceed its measured context, and a segment's predicted re-reads never exceed its measured cache reads. A segment over the second bound is clamped to it. Violations are counted in `coverage.cost_bound_violations`, and above 5 % of segments the cost status reads `degraded`. A failed conversion writes the report with the cost `unresolved` and no Mode C record.
- **Stage and role.** A session's stage comes from the per-release cost row's own two stage patterns, a byte-for-byte copy a CI parity step holds equal. A session whose spawn input names `Milestone <slug>` is a `hub` and carries no stage; others are `main`, `nested` or `workflow-agent` by path.
- **What it writes.** One run folder, `command-template-ranking-<UTC date>/`; a same-day re-run takes `command-template-ranking-run<N>-<UTC date>/` and never overwrites one. It holds `SUMMARY.md` (the analysis frontmatter, the run, cost, controls and coverage lines, `## Top procedures`, `## Context patterns`, `## Signals prepared for intake`, `## Routing outcomes`), `candidates.json` (schema `rank-command-templates.candidates` 1.0.0) and `mode-c-signals.json`. The folder is reserved only after the same fail-closed `check-ignore` guard the extractor uses (exit **4**) and after the path-leak primitive finds no line of its classes in the rendered files (exit **3**, nothing written). It prints one summary line whose path is in token form. It never writes to the source transcripts or to the store.
- **Controls.** Before reading the window, every run checks the canonicalizer with the deployed hooks' own canary inputs, then replays the committed rank fixtures: the known-repeated control must rank in three sessions and neither near-miss may rank, else exit **3**. A window whose assistant records yield no tool call exits **3**; so does one where more than 5 % of Bash calls are unreadable, and above 1 % it warns. `--self-test` runs 25 arms over the committed fixtures with a sandboxed `HOME`; the `finops-selftest` CI job runs it and plants eight defects — four masking classes (the default, an unlisted flag, a flag after an interpreter's script, an unlisted command word), the session floor, the re-read term, an unpinned vocabulary word and a second file's records kept alive — each of which must fail its own control.

| Shape | Current | Suggested | Routable |
|---|---|---|---|
| a command word or script operand is a tracked path | `AS2+` | none — already a tracked tool | no |
| Bash with at least two segments other than `cd`, or carrying `<CODE>` or `<HEREDOC>` | `AS0` | `AS2` | yes |
| Bash with one segment other than `cd` | `AS0` | `AS1` | yes |
| a `Write` of a `.py`, `.sh` or `.js` file | `AS0` | `AS2` | yes |
| a harness tool input, an MCP call, any other tool | — | none — context pattern | no |

**Hand-off.** The records in `mode-c-signals.json` are the signals the workspace auto-logging rule routes through `intake-desk` Mode C. The ranker prepares them and files nothing itself, never reads `automation_level`, and never sets `release_context`, which is the hub's alone. Each record reads its class as efficiency, not user-visible, so Mode C holds every one below the filing threshold at every dial and the operator promotes. The invoking agent records the verdict Mode C returns for each record in `## Routing outcomes`: one row per record, expected `held — below the filing threshold`; a row still pending, or any other verdict, is a failed hand-off. A public surface carries the summary line, ids, family words and counts — never a procedure — per `core/standards/analysis-workspace-standard.md` § 6.

<!-- design-artifact: flow-class=data-flow; name=command-template-ranking; depicts=core/skills/finops-usage-extractor/scripts/rank-command-templates.sh,core/skills/finops-usage-extractor/scripts/convert-usage.sh,operations/skills/intake-desk/SKILL.md -->

| Step | Producer | Artifact | Consumer |
|---|---|---|---|
| walk and parse | ranker | per-response calls (each id once), result sizes, compaction segments | normalize |
| normalize | ranker, then `command-position.awk` | procedure and variant keys | controls, cost |
| controls | ranker | canary and format-health verdicts | gate: exit 3 |
| cost | ranker, then `convert-usage.sh` | `tokens`, then the `at_w_low` / `at_w_high` pairs and the calibration label | rank |
| write | ranker | three files (the `check-ignore` guard, the path-leak scan) | the operator; the ladder's consumers |
| route | invoking agent, then Mode C | held records | `## Routing outcomes` |

- **Exit codes (this script's own):** `0` written · `2` usage error, or not run from a checkout · `3` nothing written (source unreadable, report home missing, a canary failed, format health over its threshold, a path-leak class in the rendered report), **or** written with the cost unresolved · `4` the run folder is inside a repository but not ignored · `5` a missing dependency.
- **Dependencies (this script's own):** `python3` (shell tokenization and the transcript scan), `awk` (the canonicalizer), `git` (the tracked set and the guard) and `jq` (the conversion). A missing one exits **5**.

## Dependencies

- **`jq`** (REQUIRED) — the extractor parses session JSONL with `jq` throughout. Missing `jq` is a hard preflight failure (**exit 5**). Note: context-budget-auditor is pure-bash; `jq` is a genuinely new runtime dependency here, hence the explicit declaration + preflight.
- **`git`** (REQUIRED) — the fail-closed store guard uses `git check-ignore` to refuse writing a store path that is inside a repository but not git-ignored. Missing `git` fails the same preflight (**exit 5**).
- **`bash`** — bash-3.2-safe integer arithmetic (the reused context-budget-auditor heuristic is already bash-3.2-safe).

## Read-only posture

The extractor **never writes to** `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects` (the source transcripts). It writes exactly one path: `<resolved-store>/usage.jsonl` (via an atomic `usage.jsonl.tmp` → `mv`) — plus, once at a counting-unit boundary, the preserved prior store beside it, `<resolved-store>/prior/schema-<old>/usage.jsonl` (a hard link to the store it replaces, git-ignored like the store). The store path resolves from config (`operator.toml [paths].operator_instance_finops_store_path`, default `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/finops`) — no hardcoded operator path.

The reporting phase writes **nothing at all** — it reads the resolved store and prints to stdout. The **estimation phase writes nothing at all either** — it reads the resolved store *and the in-repo release log* and prints to stdout; `--delta` persists no estimate record, because the leave-one-out re-derivation obtains the same comparison from a pure function of the existing store. Read-only on the source transcripts **and** on the store. That is a deliberate data-hygiene posture, not an omission: with no output file there is no artifact that could be accidentally staged and committed. For the same reason the report never prints the **resolved store path value** (an operator home path) — only the resolution chain, which is what makes a figure reproducible.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | OK — extraction completed (or `--self-test` passed) |
| `2` | Usage error (unknown flag / bad invocation) |
| `3` | Source or store unreadable — the session-data root is missing/unreadable; **or** the store is unparseable and the render aborted (never a clean exit behind empty stdout); **or** the roll-up has not run; **or** a `--delta` target carries no rollup row; **or** a `--rebuild` at a counting-unit boundary could not preserve the prior store (left unchanged) |
| `4` | Store-not-git-ignored — the resolved store is inside a git repo but not ignored there; the write is refused (fail-closed public-repo exfil guard) |
| `5` | Missing dependency (`jq` or `git` not on PATH) |

## Domain-Specific Failure Modes

### Double-counting sidechain subagents — PROC

- **Signature (observable signal):** a work-item or session total that is visibly inflated — the store's `session.tokens` plus the session's `subagent.tokens` both counted, so a roll-up reads roughly double the true spend for any session that has sidechains.
- **Conditional:** do NOT add `subagent.tokens` on top of `session.tokens` when computing a session or work-item total, because `session.tokens` is already the whole-file total (inclusive of every in-transcript sidechain) and `subagent` records are a drill-down, not an additional summand.
- **Root cause:** the two record kinds look additive (both carry a `tokens` object of the same shape), so a summation that filters `.record=="session" or .record=="subagent"` silently double-counts sidechain spend.
- **Mitigation:** sum `session.tokens` ONLY (the four leaf integers `input + output + cache_creation.total + cache_read`); treat `subagent` records purely as an attribution drill-down. The schema's summation invariant states this; the `--self-test` idempotence check guards the per-session digest.
- **Principal response vs. junior response:** a principal reads the schema's summation invariant before writing any aggregation and encodes "session-only" once; a junior writes an intuitive `select(.record=="session" or .record=="subagent")` sum and ships a doubled total that only surfaces on sessions that happen to have sidechains.

### Summing a response once per transcript line — PROC

- **Signature (observable signal):** token figures and `turns` read about 2–3× high, by a ratio that differs by token type and by session class, so no single divisor recovers the true spend.
- **Conditional:** do NOT sum `message.usage` over a transcript's assistant records, because the transcript writes each content block as its own record and repeats the response's whole usage on each, so a response is counted once per block.
- **Root cause:** a record looks like a turn, but the billing unit is the API response (`message.id`): one response spans as many records as it has content blocks, and a spawned agent's first record can carry a partial streaming `output_tokens` whose final value arrives later.
- **Mitigation:** `per_response` groups a file's records by `message.id`, max-merges each usage field and hands the unchanged reducers one record per response; the self-test's `three-block` and `partial-output` arms discriminate, because a per-line sum, a last-line-wins merge and a first-line-wins merge each fail one of them.
- **Principal response vs. junior response:** a principal asks what one record represents before summing; a junior sums whatever carries usage.

### Dropping legacy null-`gitBranch` sessions — INPUT

- **Signature (observable signal):** the store's session count is lower than the source session-file count, and older sessions are silently absent — total spend under-reports because pre-attribution sessions were skipped.
- **Conditional:** do NOT skip or discard a session record when its `git_branch` is null, because a null branch is a legacy pre-field-introduction session whose spend is still real and must land in the store (attribution to a work item is C2's `unattributed` bucket, not a C1 drop condition).
- **Root cause:** conflating "cannot attribute to a work item" (a C2 concern) with "cannot extract" (a C1 concern) — the extractor treats a missing attribution key as a reason to skip rather than capturing null and deferring attribution.
- **Mitigation:** capture `git_branch: null` where the source lacks it; extract the session's tokens regardless; leave attribution entirely to C2. Never gate extraction on the presence of an attribution surface.
- **Principal response vs. junior response:** a principal separates extraction from attribution by contract and captures null fail-visibly; a junior filters `select(.gitBranch!=null)` at read time and silently loses every legacy session's spend.

### Presenting heuristic figures as exact — OUT

- **Signature (observable signal):** a downstream cost figure carries no provenance, so a ±25% heuristic estimate is indistinguishable from an exact provider count in the store and in any report built on it.
- **Conditional:** do NOT emit a session/subagent record without setting `token_source` (and `heuristic_turns`) when any turn was estimated via the fallback, because a consumer cannot otherwise exclude or flag heuristic-derived totals and will treat an approximation as an exact cost.
- **Root cause:** the fallback estimator produces integers in the same fields as the exact path, so without an explicit provenance flag the two are byte-identical downstream.
- **Mitigation:** always set `token_source` to `exact` / `heuristic` / `mixed` and record `heuristic_turns`; the fallback fires only for records lacking `message.usage`, and exact source counts are always primary when present.
- **Principal response vs. junior response:** a principal makes provenance a first-class field so a consumer can exclude heuristic totals; a junior lets the fallback fill the same fields silently and ships a store where approximate and exact cost cannot be told apart.

### Mis-parsing a harness-auto branch as a work item — INPUT

- **Signature (observable signal):** a `rollup` row books real spend to a `milestone:*` or `#N` the session never worked on, because a harness-auto `claude/<adjective-noun>` / `agent-*` branch name was force-parsed into a work item.
- **Conditional:** do NOT parse a `git_branch` into a work item unless it matches a reliable release-branch form — the slug-primary `release/<milestone-slug>` (T2s) or the version-form `release/vX.Y-*` / `chore/vX.Y-*` prefix (T2) — or the opt-in `fix/*` / `feat/*` PR path (T-PR), because a harness-auto worktree branch is an adjective-noun-hash with no work-item content, and coercing it fabricates an attribution. A slug-keyed `chore/<slug>-<suffix>` is NOT parseable either: no delimiter separates the slug from the stage suffix, so a parse there manufactures a key rather than reading one, and it correctly lands in `unattributed`.
- **Root cause:** conflating "the session has a branch" with "the branch names a work item" — the harness auto-branch class carries no work-item signal at all. The mirror-image error is treating one *spelling* of a real work-item branch as the only one: run keys have been slug-primary since ADR-092, so a predicate written for the version form alone drops the branch every content spoke actually builds on.
- **Mitigation:** only the T2 / T2s / T-PR forms parse from the branch string, and the slug arm is restricted to `release/` and ordered strictly BELOW the hub-state tier so a parsed guess can never override an authored key; the issue-event key (T1) and hub-state lineage (T3) resolve from local hub-state instead; everything else → `unattributed` with the reason recorded in `attribution_basis`.
- **Principal response vs. junior response:** a principal enumerates the branch classes (per `git-workflow.md`) and parses only the ones that encode a work item; a junior regexes a version out of any branch and silently mis-attributes every auto-worktree session.

### Silently collapsing a branch-switching session onto one branch — PROC

- **Signature (observable signal):** a session that spanned two branches (e.g. `release/vX.Y-a` then `fix/b`) has its ENTIRE token total booked to one milestone, over-crediting that work item and starving the other.
- **Conditional:** do NOT run a session through the branch tiers when `branch_switch == true`, because the store collapses `git_branch` to a single value and attributing the whole session to it mis-allocates the spend that belonged to the other branch(es).
- **Root cause:** the single-valued `session.git_branch` hides that the source records spanned multiple branches; a resolver reading only the collapsed value cannot see the switch.
- **Mitigation:** the multi-branch guard sits ABOVE the resolver — `branch_switch == true` routes the session to a distinct `multi-branch` bucket carrying `git_branches[]`, never to a single milestone; `coverage.multi_branch_token_fraction` surfaces the volume for review.
- **Principal response vs. junior response:** a principal treats branch attribution as unsafe whenever the branch is not single-valued and buckets it honestly; a junior attributes to whichever branch the extractor happened to keep.

### Presenting heuristic / network-derived attribution as authoritative — OUT

- **Signature (observable signal):** a downstream report cannot tell a deterministic `branch-milestone` attribution from a fuzzy `issue-event-keyed` one or a non-reproducible `pr-resolved` one, so a best-effort guess is consumed as ground truth.
- **Conditional:** do NOT emit a `rollup` row without its `attribution_tier` and `reproducible` provenance, and do NOT put the `--resolve-prs` network resolve on a path that must be reproducible, because a network PR-resolve is time-varying and a fuzzy event-key match is not id-equality — a consumer must be able to weight or exclude them.
- **Root cause:** every tier produces a `#N` / `milestone:*` in the same field, so without an explicit provenance tag a strong and a weak attribution are byte-identical downstream.
- **Mitigation:** every row carries `attribution_tier` (the 5-value enum) and `reproducible`; the default path is LOCAL-ONLY and reproducible; `pr-resolved` rows are `reproducible: false` and recorded in `coverage.pr_resolved_present`; the health threshold + `tier_distribution` let the downstream calibration slice tune the mix.
- **Principal response vs. junior response:** a principal makes provenance first-class so a consumer can exclude weak tiers; a junior ships a roll-up where a deterministic milestone and a network-guessed issue look identical.

### Rendering a best-effort dimension without its coverage label — OUT

- **Signature (observable signal):** a by-skill or by-MCP spend slice reads as a complete census — the rows sum to a plausible total and carry no caveat — so a planning or efficiency decision is made on a fraction of the corpus believed to be all of it.
- **Conditional:** do NOT render a `by_skill` / `by_mcp` slice without its `dimension_coverage` entry, because those dimensions are partially populated **by construction** (the source attributes only some turns), and an unlabelled slice is indistinguishable from an exact one.
- **Root cause:** a best-effort sub-aggregate and an exact one are **byte-identical in shape** — same `{turns, tokens}` wrapper, same four leaves — so partiality is invisible to a renderer unless a separate field carries it. The reserved `"unknown"` bucket keeps the arithmetic honest but says nothing about *confidence*; a renderer that drops the `"unknown"` row (as a "not a real skill" filter reasonably might) removes the only in-band signal.
- **Mitigation:** `session.dimension_coverage` is a stored projection carried per session, present for exactly the two best-effort dimensions and deliberately absent for the exact three; the always-present `"unknown"` bucket preserves `Σ by_X.*.tokens == session.tokens`; the extractor `--self-test` asserts label-and-bucket agree. When a slice aggregates several sessions, the label must aggregate with it — a per-session fraction collapsed to one unlabelled number is the same defect one level up.
- **Principal response vs. junior response:** a principal treats the coverage label as part of the datum and refuses to emit the slice without it; a junior renders the map because it is well-formed, and reports 17% of the spend as if it were 100%.

### Folding a client-side tool count into the frozen server-side `tool_use` — PROC

- **Signature (observable signal):** `tool_use.web_search_requests` climbs far above the provider's billed search count, or a consumer pinned to the v1.0.0 `tool_use` shape starts reading unexpected keys — the two tool dimensions have been merged into one field.
- **Conditional:** do NOT extend or nest the new `tool_calls` map inside `tool_use` when adding the client-side tool dimension, because `tool_use` is a **frozen v1.0.0 field** with a fixed two-key shape sourced from `message.usage.server_tool_use`, and reshaping it is a breaking frozen-kind change that the v1.2.0 versioning exemption does not cover (that exemption is claimed for exactly one field replacement, and is re-tested from scratch per change).
- **Root cause:** the names read as synonyms — both are "tools" — but they count different events from different sources: `tool_use` counts **server-side** requests the provider bills for; `tool_calls` counts **client-side** invocations by name from the turn content. Summing or nesting them produces a number that answers neither question.
- **Mitigation:** `tool_calls` ships as a **new sibling field**, never an extension; the schema's field notes state the distinction adjacently so the next author meets it at the point of temptation; CIAC-1's byte-unchanged predicate over the frozen kinds is the gate that catches a fold at review time.
- **Principal response vs. junior response:** a principal checks which record kinds are frozen and what the live exemption actually covers before touching an adjacent field, and pays one new field for it; a junior sees a `tool_use` object already present, nests the map inside it "to keep tools together", and silently breaks every pinned consumer plus the versioning claim.

### Reading `rollup.tokens` for a date window — PROC

- **Signature (observable signal):** every window reports the same total regardless of `--since` / `--until` — a one-week report and a one-year report agree to the token, and the figures match the store's lifetime spend.
- **Conditional:** do NOT read `rollup.tokens` (or `rollup.session_count`) to answer a date-range question, because `rollup` rows are **whole-store aggregates carrying no time bounds** — their only timestamp, `rolled_up_utc`, is the roll-up *computation* time and is identical across every row of one run, so filtering on it is all-or-nothing rather than a window.
- **Root cause:** the `rollup` record looks like the answer — it is already grouped by work item and already carries a `tokens` object — so the shape invites a `select(.record=="rollup")` + date filter that has nothing to filter on. The time anchor lives one record kind away, on `session.started_utc`.
- **Mitigation:** invert `rollup.session_ids[]` into a `session_id → {work_item, work_item_kind, attribution_tier, reproducible}` map, filter `session` records on `started_utc`, and **re-sum** over the filtered set; the provenance travels through the join unchanged, and a windowed session absent from every rollup row lands in an explicit `(not-rolled-up)` bucket rather than being dropped. The self-test reconciles Σ rendered rows against Σ `session.tokens` over the window.
- **Principal response vs. junior response:** a principal checks which record kind carries a *data* timestamp before designing the window and finds `rollup` has none; a junior groups by the record that is already grouped, ships a report whose window control does nothing, and the error is invisible because every number is individually correct.

### Rendering a best-effort slice without its coverage label — OUT

- **Signature (observable signal):** a by-skill or by-MCP table read as the complete skill breakdown — the rows sum to a plausible total, carry no caveat, and a planning or efficiency decision is made on a fraction of the spend believed to be all of it.
- **Conditional:** do NOT emit a `by_skill` / `by_mcp` slice without its `dimension_coverage` indicator, because those dimensions are partially populated **by construction** and an unlabelled partial slice mis-attributes the whole window's spend to whichever skills happened to be captured.
- **Root cause:** a best-effort sub-aggregate and an exact one are **byte-identical in shape**, so partiality is invisible to a renderer unless a separate field carries it — and a label emitted as a *second statement* after the header is one refactor away from being dropped, because nothing structurally binds the two.
- **Mitigation:** the coverage clause is concatenated **into** the section-header string inside a single `section_header` function, called from a single `emit_dim_table` that **both** the markdown and the JSON path consume — so a best-effort header without `coverage:` is unrepresentable, not merely forbidden. An absent coverage field renders `unknown (coverage field absent — treat as 0% verified)`, never `100%` and never nothing; per-period trend rows carry **that period's** coverage, since a whole-window figure would hide period-to-period capture drift.
- **Principal response vs. junior response:** a principal makes the label structurally inseparable from the figure and proves it with a test that counts best-effort headers and fails when the count of labelled ones differs; a junior adds a caveat line under the table, and the next person who reorders the emitter ships an unlabelled census.

### Characterizing a trend over a partially-populated dimension — OUT

- **Signature (observable signal):** a confident claim like "skill X's spend tripled" when what actually tripled was the **capture rate** — the underlying dimension was populated on 10% of sessions in the first period and 30% in the last.
- **Conditional:** do NOT emit a direction, arrow or percentage delta for a **best-effort** dimension, because a change in coverage is not separable from a change in spend without a coverage-stable baseline that the source does not provide.
- **Root cause:** a per-period series is arithmetically well-formed whether or not the population behind it is stable, so the trend math succeeds silently; the invalidity lives in the *sampling*, which the numbers do not expose.
- **Mitigation:** the trend gate keys on the **same registry entry** that drives the coverage label — direction is emitted only where `grade == "exact"`, so a direction claim and a completeness claim share one enforcement point and there is no threshold to mis-tune. Best-effort dimensions render per-period volume **and** per-period coverage, plus an explicit `COVERAGE-DRIFT` note when the spread exceeds the `[RECOMMENDED]` 10-percentage-point band, so the coverage jump sits on the same line as the volume jump.
- **Principal response vs. junior response:** a principal asks what the denominator did before reading the numerator and withholds the claim the data cannot support; a junior computes a delta because the series is there, and reports a capture-rate artifact as a spend trend.

### Rendering an unmeasurable dimension as a measured zero — OUT

- **Signature (observable signal):** a slice or trend table of clean `0`s carrying `[SOURCE: exact message.usage]` — the tool's strongest provenance claim — for a dimension the store does not contain at all. The operator reads "we spent nothing on MCP servers" from a store that simply never captured MCP attribution.
- **Conditional:** do NOT render a figure — least of all a provenanced `0` — for a dimension **absent from every record in the window**, because summing an absent field yields `0` with no error and no exit code, so "we cannot measure this" and "we measured zero" become the same output.
- **Root cause:** absence and zero are the same value after aggregation. `[] | add // 0` is `0`, and the provenance tag is computed from the *session's* turn counts, which are exact regardless of whether the dimension exists — so the strongest possible tag rides the weakest possible datum. The defect is invisible in review because the table looks perfectly well-formed.
- **Mitigation:** an availability gate (`unavail()`), applied at **both** grains — whole dimension and single period — and shared by the slice and trend renderers so the two surfaces cannot drift on what "present" means. When it fires the row set is **emptied** rather than zero-filled, which makes an exactness tag *unrepresentable* rather than merely forbidden; the reason is rendered in its place. The self-test asserts it against a fixture that deliberately carries sessions but zero carriers of the field, and pairs it with a positive leg proving a **present** dimension still renders — a gate that suppresses everything is not a gate.
- **Principal response vs. junior response:** a principal asks whether the denominator exists before reporting the numerator, and distinguishes *no data* from *no spend* in the artifact itself; a junior ships the zero because the query returned one, and the operator budgets against a dimension that was never captured.

### Disclosing a suppressed figure through its derived fields — OUT

- **Signature (observable signal):** an output that says `(suppressed)` where the estimate should be, and one line later prints a signed delta and a percentage error against a known actual — so the withheld figure is recoverable by one subtraction. The suppression is decorative.
- **Conditional:** do NOT render a **derived** field of a suppressed figure (a signed delta, a percentage error, a residual, a ratio) when the figure itself has been withheld, because each derivation is invertible against the value it is derived *from*, which is still on the page.
- **Root cause:** suppression is normally implemented at the point of *display*, one field at a time, while derived fields are computed upstream from the un-suppressed value and carried along independently. Nothing links them, so blanking the headline value looks complete — and the disclosure travels through a field nobody thought of as "the estimate".
- **Mitigation:** gate every derived field on the **same predicate** that gates the figure (`$show_point`), so they cannot come apart from it, and state the suppression rather than emitting a bare null — a silent null is indistinguishable from "not computed". The self-test asserts no-arithmetic-recovery in **both** output shapes, refuses to run unless the case really is a suppressed-estimate-with-a-real-actual (or the check is vacuous), and carries a positive control proving an un-suppressed run still emits both fields.
- **Principal response vs. junior response:** a principal asks what else on the page reconstructs the withheld value and suppresses the whole recoverable set; a junior blanks the one field that names the quantity and ships an output whose own arithmetic undoes the guard.

### Leaking an operator home path through the directory dimension — OUT

- **Signature (observable signal):** a rendered report, pasted into a ticket or a chat message, contains an absolute home path — or a path-mangled one such as a `-Users-…`-style directory name that reconstructs to the same thing.
- **Conditional:** do NOT render `session.project_dir` or `session.cwd` when slicing by directory, because `project_dir` is the `~/.claude/projects/<dir>` basename — which encodes the **full absolute working directory** as a slash-mangled name — and `cwd` (pre-v1.2.0 stores) is the raw absolute path; either one published on a public repo or in a ticket is a data-hygiene breach.
- **Root cause:** three fields plausibly answer "which directory?", and the two wrong ones are the *more* obvious choices — `project_dir` is present on every record including legacy ones, and `cwd` reads as the literal answer. Only `worktree` is the data-minimized basename.
- **Mitigation:** one accessor resolves `.worktree // basename(.cwd)`, so the rendered value is a **basename before and after** the v1.2.0 rename and no absolute path is emitted either way; `project_dir` is never read. The self-test asserts the negative against fixtures that **deliberately contain** a fabricated absolute path and a fabricated mangled one — a "contains no home path" assertion over a fixture with no home path in it proves nothing.
- **Principal response vs. junior response:** a principal picks the field by what it will *print* and pairs the negative assertion with a positive control; a junior renders `project_dir` because it is always populated, and ships a report that cannot be pasted anywhere.

### Estimating from a population too thin to support one — OUT

- **Signature (observable signal):** a confident single figure produced from one or two comparables — and the next similar work item costs 4× it. The estimate carried no visible hedge because the arithmetic reported none.
- **Conditional:** do NOT emit an estimate below **three** comparables, because at `n = 2` the median **is** the mean of the two — so the outlier-robustness the median was chosen for evaporates while the statistic keeps its name — and at `n = 1` dispersion is identically zero, so *every* confidence signal reports maximum certainty precisely where there is least.
- **Root cause:** the failure is silent because the statistics remain **well-formed** at any `n`: a median exists for one sample, a MAD exists for two, and both return a number without complaint. The invalidity lives in the *sample size*, which the output values do not expose — so a thin population produces a figure that looks **more** certain than a large one, not less.
- **Mitigation:** a **hard floor** at `N_min = 3` (the platform-wide calibration threshold, inherited from `gate-evaluation-spec.md` rather than privately invented), enforced as a terminal ladder tier that emits `INSUFFICIENT-COMPARABLES: n=<k> (3 required)` and **no figure at all** — not a wide range, not a LOW-confidence number. The decline exits 0 because it is an answer. The self-test asserts both legs: a 2-comparable store declines, and adding a third produces an estimate, so the decline is attributable to the floor and not to an unrelated failure.
- **Principal response vs. junior response:** a principal states that the data cannot answer the question and says what would make it answerable; a junior hedges — ships the number with a "low confidence" label — and the label is discarded the moment the figure is pasted into a plan.

### Averaging a right-skewed spend distribution — PROC

- **Signature (observable signal):** every estimate reads high, and consistently so. A handful of long exploratory or repeatedly-retried work items drag every figure up, and the estimates never come down because nothing in the output points at the outlier.
- **Conditional:** do NOT use the **mean** to summarize token spend, because spend is right-skewed and a single outlier moves a mean **without widening it** — so the estimate becomes *confidently* wrong rather than visibly uncertain.
- **Root cause:** the mean is the default summary statistic in most tooling and reads as the neutral choice, while the skew that invalidates it is a property of the *distribution* and not of any individual record. Nothing in a per-row view reveals it; the distortion is only visible when the centre and the spread are compared, which a mean-plus-range view does not do.
- **Mitigation:** median throughout, with **MAD** as its companion dispersion measure and `rMAD = MAD / median` as the normalized form (so one threshold applies across a 2-pt item and a 30-pt release). Standard deviation is rejected on a real property, not taste: it pairs with the mean and is single-outlier-sensitive, so pairing it with an outlier-robust centre would let one comparable drive the confidence label the median was chosen to protect. The mean is still **rendered** — explicitly labelled *not used*, alongside its ratio to the median — so the skew is visible rather than merely avoided. The self-test asserts the emitted figure is the median **and** differs from the mean on a deliberately right-skewed fixture; a mean-based regression fails it.
- **Principal response vs. junior response:** a principal picks the statistic from the shape of the distribution and shows the reader the shape; a junior averages because averaging is what one does to numbers, and never learns that the estimator is biased because every estimate is wrong in the same direction.

### Presenting best-effort comparables as firm evidence — OUT

- **Signature (observable signal):** a HIGH-confidence estimate whose basis is mostly `pr-resolved` or `issue-event-keyed` rows — comparables a re-run tomorrow would not reproduce. The provenance was in the output, but only in the footnotes.
- **Conditional:** do NOT let attribution provenance affect only the annotations, because a fuzzy-keyed or network-derived comparable is **weaker evidence** and must move the **confidence label itself** — a reader who trusts the label and skips the table would otherwise act on a firm-looking figure built from soft rows.
- **Root cause:** dispersion and provenance are independent axes, and a confidence function built on dispersion alone is *internally* consistent: a tight cluster of best-effort comparables genuinely does agree with itself. The estimate is precise and unreliable at the same time, and only the provenance axis distinguishes the two.
- **Mitigation:** `reproducible == true` is required by default (so `pr-resolved` rows are excluded outright), and four caps apply **after** the dispersion ladder and only ever move confidence **down**: `C-TIER` on the best-effort **token** fraction (a token basis, not a count basis, so one large soft comparable can trip it alone), `C-NONREPRO` when a non-reproducible row is admitted, `C-RATE` on the pooled-rate tier, `C-NET` on the opt-in label tier. Three independent channels carry the signal — the capped label, the per-row `attribution_tier` column, and the attribution-mix line — so losing one still leaves two. The self-test pins a set that scores HIGH on dispersion alone and asserts it renders MEDIUM, and a second that scores MEDIUM and renders LOW.
- **Principal response vs. junior response:** a principal downgrades the claim when the evidence is soft, and says which rows made it soft; a junior adds a caveat sentence under a HIGH label and treats the disclosure as the mitigation.

### Reading rollup rows from a store the roll-up never ran on — PROC

- **Signature (observable signal):** an estimate reporting zero or near-zero comparables against a store visibly full of sessions — or, worse, a `DECLINE` that reads as "insufficient history" when the real cause is that the comparable phase never ran.
- **Conditional:** do NOT gate the roll-up-has-run check on `meta.schema_version`, because **from v1.2.0 a store carries the same version whether or not the roll-up has run** — so a version test passes on an extraction-only store, the `rollup` filter matches nothing, and the comparable set comes back empty while the run still exits 0 and looks successful.
- **Root cause:** the version field *used* to encode which phase had run, and stopped doing so when the two phases converged on one version. The stale predicate keeps returning true, so the failure surfaces as a plausible-looking empty result rather than an error — the most expensive shape a silent failure can take, because the output is indistinguishable from a genuine answer.
- **Mitigation:** gate on the **presence of the run-level `coverage` record** — `any(.record == "coverage")` — which only the roll-up phase writes, and exit **3** with a named message pointing at `rollup-attribution.sh`. The self-test's negative control is the load-bearing part: its coverage-less fixture carries `meta.schema_version: "1.2.0"` **deliberately**, so a version-based gate would pass it and the assertion would fail. A control that merely omitted the version would not distinguish the two predicates.
- **Principal response vs. junior response:** a principal asks what an empty result would look like if the *upstream* step had not run, and gates on the artifact that step produces; a junior reads the version because it is right there in the file, and ships a tool that reports "no history" on a full store.

### Publishing a transcript literal through a normalized template — OUT

- **Signature (observable signal):** a ranking report, a Mode C record or a pasted report row carries a word, flag, path or value that appeared in a session transcript — a repository, a file name, a field name, an option a private script defines.
- **Conditional:** do NOT render a token outside the closed vocabulary, a tracked path or a typed placeholder, and do NOT render a flag that is not listed for its own command, because a denylist fails open on every literal shape nobody anticipated and report rows reach public surfaces by paste.
- **Root cause:** "strip what looks sensitive" fails open; and a flag class left open beside a closed command class lets a literal through in the one position nobody checked.
- **Mitigation:** allowlist masking with a closed flag list per command, every flag after an interpreter's script operand masked, and the vocabulary pinned by digest; the leak arm proves each class that renders a token of a Bash command or a harness-tool value — path, slug, the default, code, flag, interpreter flag, heredoc, comment, variable, command word, URL, glob and tool input — on a literal inside a ranking procedure; four CI probes break a class each; the path-leak primitive scans the rendered files before any is written. Accepted residuals: a coincidental tracked-path suffix renders as that public path; and the whole-shape classes (a number, a SHA, a UUID, an unparsed command) and the tool-name, MCP and key classes carry no literal the leak arm proves.
- **Principal response vs. junior response:** a principal closes every token class by construction and proves each class on a literal that reaches written output; a junior scrubs the literals they can picture and tests the masking on input that never reaches the report.

### Ranking copied history or a one-session repeat as a cross-session pattern — PROC

- **Signature (observable signal):** a procedure ranks with two sessions where one session only resumed or forked the other, or a polling loop inside one session ranks as a repeated procedure.
- **Conditional:** do NOT count a `tool_use` id twice across files or rank a procedure below two sessions, because resumed and forked sessions copy prior lines with their ids, and a loop within one session is not the framework's N=2 emergence.
- **Root cause:** the per-file counting unit the extractor uses is correct for spend and wrong for repetition: a copy is spend in each file but one act of retyping.
- **Mitigation:** a global dedupe of `tool_use` ids, oldest file first; the two-session floor; the copied-history and near-miss arms; the runtime canary refuses a run whose floor admits the near-miss fixtures, and a CI probe proves it.
- **Principal response vs. junior response:** a principal asks which unit the question counts — acts of retyping, not lines of spend — and dedupes on that unit; a junior reuses the spend unit and ranks every resumed session's history twice.

### Treating a suggested rung as a promotion decision — OUT

- **Signature (observable signal):** a promotion decision line or an intake item copies the ranker's suggested rung as the decision, with no evaluation of the framework's T-DET, T-VAR or T-RISK triggers or its counter-signals.
- **Conditional:** do NOT copy the rung into a promotion decision without the framework's §1 evaluation, because the judgment triggers and the counter-signals cannot be seen from transcripts, and scripting a judgment step end-to-end is the framework's judgment-laundering failure.
- **Root cause:** a ranked, costed row reads as a verdict; the rung beside it looks decided because it sits in a table.
- **Mitigation:** the rung is labelled suggested; the triggers the ranker cannot see are written as not evaluated; Mode C holds every candidate below the filing threshold, so the operator promotes; the framework's §1 keeps the decision with the author.
- **Principal response vs. junior response:** a principal treats the report as the evidence-gathering substrate of a split promotion and evaluates the triggers before deciding; a junior files the top row at its suggested rung.

## Guardrails (Platform)

- **Data hygiene (CIAC-3):** the store holds real session-data values (branch names, token counts, session UUIDs, `worktree` directory basenames — v1.2.0 replaced the full `cwd` path as a data-minimization control) that MUST NEVER be committed or published on this PUBLIC repo. The store is git-ignored operator-instance data; the fail-closed `check-ignore` guard (exit 4) is the runtime enforcement. This skill's `test-fixtures/` are **synthetic** (fabricated) — never real transcripts.
- **No-invention / evidence labels:** exact `message.usage` counts are `[SOURCE]`; heuristic figures are `[INFERRED]` and always flagged via `token_source`.
- **Reversibility:** MODERATE / Confidence HIGH — the store is a derived cache (operator-deletable; rebuilt from source); the schema freeze is the load-bearing stability control. The C2 attribution phase is additive (v1.1.0 `rollup` + `coverage`) and content-only; the `unattributed` bucket makes the resolver safe-by-construction (it never claims a grain it cannot deliver).
