---
title: Pipeline Event Log Schema
purpose: Unified 10-field schema and 12 event-type enum for the additive append-only audit-trail capture surface at `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md`
applies_to: hub-spoke-bridge.md, release-personas.md (Stages 2-13), pipeline/stage-{02..09,12,13}.md §11, future skills release-planner / release-executor / principal-engineer
parallel_to: gate-evaluation-spec.md (calibration-data surface), handoff-coordinator-spec.md (iteration-log surface), decision-discipline.md § 4 (observation surface)
source: Stage 5 Solutioning + Collective Review scope-lock APPROVED 2026-05-16
framework_version_anchor: "v11.07a"
---
<!-- reference-durability: allow-link -->

# Pipeline Event Log Schema

> **Status:** Active (schema is published; capture begins one release after schema publication per § Cutover).

## 1. Purpose

Define the unified schema for `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md` — an additive, append-only event stream that captures decisions, escalations, self-repairs, gate outcomes, and other auditable events during automated pipeline execution.

The schema is the SOURCE OF TRUTH for pipeline events. Four existing audit surfaces continue as TYPED PROJECTIONS (read-models) of the same underlying behavior:

| Existing surface | Projection role | Authority preserved |
|---|---|---|
| `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md` | gate-outcome view | gate-evaluation-spec.md path writes; pipeline-event-log carries `projects_to:` pointer |
| `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md` | iteration view | handoff-coordinator writes; pipeline-event-log carries `projects_to:` pointer |
| The observation log (user auto-memory store) | operator-correction view | operator-write-only per [decision-discipline.md § 4.1 D-5](../../../core/disciplines/decision-discipline.md); pipeline-event-log REFERENCES by (date, domain, theme), never duplicates |
| Release-synthesizer Stage 13 self-learning | release-synthesis view | pipeline-event-log emits one `event_type=release-synthesis` row per release; the release-synthesizer JOINs against those rows. See § 11 for the synthesizer contract. |

Additive design (NOT retrofit) preserves author-authority across the 4 existing surfaces while filling the gap in events not previously captured anywhere.

## 2. Schema — 10 fields

The `pipeline-event-log.md` body is a markdown table. Header:

```markdown
| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
```

| # | Field | Type | Domain | Example |
|---|---|---|---|---|
| 1 | `ts_iso` | ISO8601 UTC timestamp | event time | `2026-05-15T14:22:01Z` |
| 2 | `version` | string | active Milestone tag | `v1.07a` |
| 3 | `stage` | int 1..13 | pipeline stage number | `5` |
| 4 | `event_type` | enum (see § 3) | top-level event category | `decision` |
| 5 | `event_subtype` | enum scoped to event_type (see § 3) | refinement of event_type | `scope-lock` |
| 6 | `actor` | enum: `hub` / `spoke:#N` / `operator` / `skill:NAME` | who emitted the event | `spoke:#N` |
| 7 | `subject` | string | reference to the entity acted upon | `#N`, `milestone:#N`, `release-level`, `sub-task:#N` |
| 8 | `reversibility` | enum: `CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE` | reversibility tier per [reversibility-protocol.md](../../../core/specs/reversibility-protocol.md) | `EXPENSIVE` |
| 9 | `outcome` | enum: `resolved` / `pending` / `escalated` / `superseded` | terminal state of the event | `resolved` |
| 10 | `payload` | inline event-specific details (≤ 300 chars) OR pointer | compact JSON-in-markdown or `; `-separated key:value pairs (pipe grammar per § 4.3a); longer content → pointer to existing surface | `projects_to:calibration-data.md; verdict:Approved; structural_pass:1.0` |

### 2a. Release join key (canonical)

The `version` column is the release join key. It carries the release's GitHub
Milestone SLUG, written at emission time. The slug is bound pre-claim, is 1:1
with the release, and does not move when a release is re-versioned mid-pipeline
(ADR-092). Writers ALWAYS pass the slug to `--version` (orchestration-playbook
§ 4a.2). The `vX.Y` shipped version is NOT a key: it is assigned at the Stage-12
ref-CAS, after emission has begun, and pre-cutover rows carry a provisional value
that is neither unique across releases nor stable within one.

**Resolving a row to a release (READ ladder — first match wins):**

1. `version` matches a `RELEASE_LOG` `Milestone` cell → that release. **[canonical]**
2. `subject` is `milestone:#N` → that milestone's release.
3. `version` matches a `RELEASE_LOG` `Version` cell → that release. **[legacy, may be
   ambiguous** — a legacy value can span releases; the row is release-INDETERMINATE
   when the match is not unique, and MUST be reported as such, never silently bound.**]**
4. otherwise → UNRESOLVED.

**Resolving a release to its rows (WRITE-side inverse):** read the release's
`RELEASE_LOG` row, take its `Milestone` cell → the slug → select rows whose
`version` equals it. The shipped-version binding is additionally recorded in the
log itself by the Stage-12 Phase B3.1 `d:version-claim` row (payload `claimed:` /
`prov:`), so the log is self-describing without the repo.

**Ambiguity is reported, never resolved by guessing.** Rung 3 exists so pre-cutover
history stays readable; it is explicitly non-unique and a consumer that needs 1:1
must treat a multi-match as INDETERMINATE. Rung 3 is deliberately EXCLUDED from any
gate that asserts an emission obligation — an ambiguous legacy match must never
count as satisfying an obligation.

**Scope truth.** 1:1 resolution is achievable only forward. Rows written before the
write-slug cutover carry a `vX.Y` value that genuinely spans multiple releases, and
no reader can undo that without mutating an append-only log (§ 4.1). Legacy rows are
best-effort-with-declared-ambiguity by design, not by defect.

**Mixed-arity note for windowed reads.** `query-pipeline-event.sh --window N`
restricts to the trailing N DISTINCT `version` values. Post-cutover the column holds
slugs beside legacy versions, so a trailing-N window may span a different number of
real releases than N. Use `--release` (which resolves through this ladder) when the
question is "which rows belong to release X"; `--version` remains the raw-column
filter.

## 3. Event-Type Enum (12 values) with Subtypes

| `event_type` | Description | Allowed `event_subtype` values |
|---|---|---|
| `gate-outcome` | Stage-gate evaluation verdict | `g1-g2` / `g3-release-readiness` / `dt-pass` / `dt-conditional-pass` / `dt-return` / `qa-acceptance` / `qa-rejection` / `plan-review-go` / `plan-review-no-go` / `plan-review-readiness-scan` (applies to releases entering Stage 9 going forward) / `goal-conformance` (Stage 9 G-PR7 verdict ALIGNED/DIVERGED-WITH-RATIONALE/MISALIGNED; applies to releases entering Stage 9 going forward) |
| `decision` | D-class or scope-locking decision rendered | `d-class` / `adr-closed` / `adr-opened` / `scope-lock` / `a6-new-track-rationale` / `a7-bundle-amend` / `a7-bundle-rebundle` / `a7-bundle-defer` / `cross-d-upstream-compat` / `empirical-verification-finding` / `action-item-opened` / `action-item-started` / `action-item-resolved` / `action-item-cancelled` / `action-item-superseded` / `queued-pending-approval` / `approval-deferred` / `cascade-sweep-block` / `outcome-statement-authored` (Stage 3 Phase B3 emits one row per Milestone created with the Outcome Statement payload) / `delegation` (the hub's spawn-vs-hub-direct execution-path fork, emitted only when the delegation merit test in decision-discipline.md § 3.1 fires — never for routine template routing; payload convention below) / `recommendation-choice-delta` (captures a prior agent recommendation against the rendered operator choice at any decision moment — D-Gate, pause-to-learn E3 escalation, Stage 4 bundle, Stage 5 design, or routing; payload convention below) |
| `escalation` | Operator escalation per Inter-Stage Feedback Protocol | `tier-0` / `tier-1` / `tier-2` / `tier-3` |
| `self-repair` | Autonomous retry / escalate / rollback per [autonomous-execution-model.md](../../../core/disciplines/autonomous-execution-model.md) | `retry` / `escalate` / `rollback` |
| `iteration` | Inter-stage re-entry per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) | `dt-eng-pass-N` / `qa-dt-pass-N` (N is the post-increment pass count; Tier 1 fixes use pass-0) |
| `scope-change` | Tier 1 [ADJUST] / Tier 2 [SCOPE CHANGE] / Tier 3 [PLAN REJECTION] / redaction | `tier-1-adjust` / `tier-2-scope-change` / `tier-3-plan-rejection` / `redaction` |
| `re-review` | Phase A0 / Phase 0.5 re-review row appended to instrumentation log | `phase-a0-row` / `phase-0.5-row` |
| `deployment-status` | Per-file or per-target deploy outcome at Stage 12 | `deploy-skill` / `deploy-harness` / `deploy-package` / `deploy-rules-mirror` / `deploy-helper` |
| `release-synthesis` | Per-release Stage 13 row carrying learnings triple + QC4-05 verdict | `learnings-triple` / `qc4-05-result` / `qc4-06-result` (Stage 13 QC4-06 verdict ATTAINED/PARTIALLY-ATTAINED/NOT-ATTAINED; applies going forward) |
| `test-run` | Runtime code-test suite execution at Stage 6 (author self-verification) or Stage 7 (DT gate); the suite is selected per [`runtime-suite-selection-map.md`](runtime-suite-selection-map.md) | `suite-pass` / `suite-fail` / `suite-skip` |
| `spoke-launch` | Per-spoke startup-token reservation telemetry consumed by the quota-budget gate ([`quota-budget-protocol.md`](quota-budget-protocol.md) Checkpoint B); fired at spoke-launch time (Stage 5 / 7 / 8 parallel waves); `tokens_used:` rides the payload | `quota-reservation` |
| `session-retro` | Per-session self-retrospective row emitted by the `session-retro` skill at a session boundary — the SESSION-grained learning-capture sibling of the RELEASE-grained `release-synthesis` row; signal-only (payload convention below) | `learning` / `operator-feedback` (a learning derived from operator feedback with NO preceding recommendation — the surface the decision-anchored recommendation-choice-delta path structurally cannot emit) / `no-learning` (the EXPLICIT zero-state, never a silent omission) |

Subtypes outside the lists above are **invalid** — `append-pipeline-event.sh` rejects unknown subtypes with non-zero exit. Adding a subtype requires a governance change per `release/governance/release-process.md` § Inter-Stage Feedback Protocol Tier 2 / Tier 3.

**`recommendation-choice-delta` payload convention.** A `recommendation-choice-delta` row reuses the standard 10 columns (no new fields); the `version` + `stage` columns are the release/stage anchor, and the delta-tuple lives in `payload`, keyed `rec:` (the agent's prior recommendation) / `chose:` (the rendered operator choice; pair with the row's `outcome`) / `delta:` (one of `aligned` / `diverged` / `partial` / `operator-deferred` — `aligned` records the zero-delta state EXPLICITLY, never silently omitted) / `why:` (divergence rationale) / `via:` (provenance — one of `hub-d-gate` / `pause-to-learn-e3` / `stage4-bundle` / `stage5-design` / `routing` / `session-retro`). `actor` is `spoke:#N`, `hub`, or `operator` per the decision moment. The `session-retro` provenance value marks a delta the per-session retro surfaced retrospectively rather than one captured live at the decision moment; the row is otherwise identical, so the existing look-back read-model needs no change to see it. **Signal-only surface:** this subtype NEVER auto-mutates the toolkit; the look-back read-model (§ 11 `--event-subtype recommendation-choice-delta`) is detective-only, and an auto-promote of ≥3 same-pattern `diverged` rows yields an `improvement.yml` CANDIDATE via the governance gate (issue → plan → PR per "No ungoverned changes"), never an auto-change. PII per § 4.2; redaction reuses `event_type=scope-change, event_subtype=redaction`. Examples (≤ 300 chars, escaped-pipe per § 4.3a):

```markdown
| 2026-06-29T14:00:00Z | v2.39 | 4 | decision | recommendation-choice-delta | hub | milestone:#N | CHEAP | resolved | rec:bundle-A+B; chose:bundle-A-only; delta:diverged; why:B-blocked-on-dep; via:stage4-bundle |
| 2026-06-29T14:00:01Z | v2.39 | 5 | decision | recommendation-choice-delta | spoke:#N | #N | CHEAP | resolved | rec:new-subtype; chose:new-subtype; delta:aligned; via:stage5-design |
```

**`test-run` payload convention.** A `test-run` row reuses the standard 10 columns (no new fields); the suite specifics live in `payload`, keyed `suite:` / `selected-by:` (the [`runtime-suite-selection-map.md`](runtime-suite-selection-map.md) row that matched) / `pass:` / `fail:` / `env:` / `sha:`. `stage` is `6` (author self-verification) or `7` (DT gate); `outcome` is `resolved` for pass/skip and `escalated` for a fail routed to Engineering. Examples (≤ 300 chars, escaped-pipe per § 4.3a):

```markdown
| 2026-06-13T14:00:00Z | v1.12 | 7 | test-run | suite-pass | spoke:#N | #N | CHEAP | resolved | suite:hook-suite; selected-by:glob-3; pass:268; fail:0; env:sandbox-home-tmp; sha:abc1234 |
| 2026-06-13T14:00:01Z | v1.12 | 7 | test-run | suite-fail | spoke:#N | #N | CHEAP | escalated | suite:deploy-suite; selected-by:glob-2; pass:24; fail:1; env:sandbox-home-tmp; sha:def5678 |
| 2026-06-13T14:00:02Z | v1.12 | 6 | test-run | suite-skip | spoke:#N | #N | CHEAP | resolved | suite:NONE; selected-by:no-match; reason:doc-only-change; sha:9abcdef |
```

**`session-retro` payload convention.** A `session-retro` row reuses the standard 10 columns (no new fields); the session-grained learning lives in `payload`, keyed `session:` (an opaque session handle — never a transcript path, never operator content) / `source:` (what produced the signal — one of `correction` / `preference` / `redirection` / `friction` / `delta`) / `theme:` (a short kebab-case clusterable key — **the only field the cross-session cluster read-model tokenizes**, so it carries the pattern identity) / `domain:` (the surface the learning touches) / `learning:` (one abstracted sentence). `actor` is `skill:session-retro`; `subject` is `session:<handle>`; `stage` is the pipeline stage the session was working in, or `13` for a non-pipeline conversational session (the retro is session-grained, not stage-grained — the column is an anchor, not a claim). `version` is the active release tag.

**Signal-only surface, and the boundary that makes it one.** A `session-retro` row is a SENSOR reading, never an actuator: emitting one creates zero toolkit changes, and a cross-session cluster (§ 11.5, `cluster_min` ≥ 3 spanning ≥ 2 versions) yields an `improvement.yml` CANDIDATE through the governance gate (issue → plan → PR per "No ungoverned changes"), never a direct edit. The retro NEVER writes the operator's auto-memory store (operator-write-only per § 5.3) — the memory corpus is a promotion TARGET reachable only through that gate, never a write target of the retro itself.

**Explicit zero-state.** A session that produced no learning emits a `no-learning` row rather than nothing, so "the retro ran and found nothing" is distinguishable from "the retro never ran" — the same discipline as `delta:aligned` above and the release-synthesis explicit-N/A markers (§ 11.3). A `no-learning` row carries `session:` + `reason:` and carries **no `theme:`** — enforced at both ends, not left to emitter discipline: `append-pipeline-event.sh` rejects a `theme:` label on a `no-learning` row, and the synthesizer skips `no-learning` rows by subtype before clustering. So it contributes no cluster signal **by enforcement**, and a mis-emitted row cannot leak one.

**PII (§ 4.2 applies unchanged, and bites hardest here).** The retro reflects over session content, so every payload field is an ABSTRACTION, never a quotation: no verbatim operator text, no external-stakeholder names, no Cowork-owned Layer 2 content, no transcript excerpt. `learning:` states the pattern, not the utterance that revealed it. Examples (≤ 300 chars, escaped-pipe per § 4.3a):

```markdown
| 2026-07-22T22:10:00Z | v3.80 | 6 | session-retro | operator-feedback | skill:session-retro | session:a1b2c3 | CHEAP | resolved | session:a1b2c3; source:correction; theme:read-before-edit; domain:corpus-edit; learning:operator redirected a pattern-sweep toward per-file reading |
| 2026-07-22T22:10:01Z | v3.80 | 6 | session-retro | learning | skill:session-retro | session:a1b2c3 | CHEAP | resolved | session:a1b2c3; source:friction; theme:worktree-cwd-guard; domain:release-ops; learning:git writes needed an explicit cwd guard to stay in the worktree |
| 2026-07-22T22:10:02Z | v3.80 | 13 | session-retro | no-learning | skill:session-retro | session:d4e5f6 | CHEAP | resolved | session:d4e5f6; reason:below-sampling-threshold-no-novel-signal |
```

**`delegation` payload convention.** A `delegation` row reuses the standard 10 columns (no new fields); the fork lives in `payload`, keyed `chose:` (the elected execution path — one of `spoke` / `hub-direct`) / `unit:` (what was delegated — `stage-<N>` or `procedure-<N>`) / `merit:` (which merit condition fired — one of `context-boundary` / `budget-forced` / `recovery`, per `decision-discipline.md` § 3.1) / `quota:` (the Checkpoint-B verdict in force, per `quota-budget-protocol.md` § 4 — that enum is **cited, never restated here**; present only when `merit:budget-forced` fired, omitted rather than written as a noise value) / `why:` (a one-line kebab rationale). `actor` is always `hub` — the hub is the only spawner, per the recursion prohibition. `reversibility` is `CHEAP`: a delegation choice is undone by re-running the unit on the other path. `outcome` is `resolved`. Every row opens `payload` with the release-stable `ms:#<milestone-number>;` token per the orchestration playbook § 4a.2. PII per § 4.2 — `why:` states the structural reason, never operator text.

**Emitted at a merit fork only.** Silence is the correct signal for routine template routing (the sub-task exists, its dependency is met, the quota verdict was `PROCEED`, and the spawn is the template's default). A consumer that cannot name which merit condition fired has not established a fork and must not emit. The test itself is owned by `decision-discipline.md` § 3.1; this block is the write-side contract, not a second copy of the criterion.

**A `delegation` row at stage 4 MUST carry a `milestone:#N` subject.** The Stage-4 plan-survival denominator in `compute-front-cluster-telemetry.sh` counts distinct non-`milestone:` `decision` subjects at stage 4 and is **subtype-blind**, so a Stage-4 delegation row keyed `sub-task:#N` would silently enter that population as a phantom planned subject — and, carrying no scope-change of its own, it lands in the numerator as a survivor as well as the denominator, so it can only bias the shipped rate **upward**, never downward, with no error raised anywhere. The constraint costs nothing: the only Stage-4 delegation is the release-scoped planning spoke. Examples (≤ 300 chars, escaped-pipe per § 4.3a):

```markdown
| 2026-07-28T06:38:10Z | decision-telemetry-emission | 6 | decision | delegation | hub | issue:#N | CHEAP | resolved | ms:#N; chose:spoke; unit:stage-6; merit:context-boundary; why:rename-is-a-graph-op-needs-branch-context |
| 2026-07-28T06:41:02Z | decision-telemetry-emission | 5 | decision | delegation | hub | milestone:#N | CHEAP | resolved | ms:#N; chose:hub-direct; unit:stage-5; merit:budget-forced; quota:REDUCE-scope; why:window-cannot-absorb-a-third-parallel-spoke |
| 2026-07-28T07:02:44Z | decision-telemetry-emission | 5 | decision | delegation | hub | sub-task:#N | CHEAP | resolved | ms:#N; chose:spoke; unit:stage-5; merit:recovery; why:prior-spoke-terminated-at-usage-cap-nothing-salvageable |
```

## 4. Constraints

### 4.1 Append-only

- Writers MUST use `release/tools/append-pipeline-event.sh` — direct edits are forbidden.
- Enforcement: `deploy.sh --check` Check 19 (pipeline-event-log integrity) validates the file's row count against `pipeline-event-log-write.log` invocation count. Drift = direct edit; flag at Check 19 (warn-mode initial; flip-to-enforce per [bypass-mode-readiness.md](../../../core/rules/bypass-mode-readiness.md) Shakedown protocol).

### 4.2 PII discipline

Allowed in `payload`:

- Workspace owner handle (`{OWNER}`)
- Milestone numbers (`milestone:#N`)
- Issue / PR numbers (`#N`, `#N`)
- File paths under `pmo-platform/`, `.claude/`, or `~/.claude/`
- Commit SHAs (`abc1234`)
- Stage numbers + event subtype labels
- Cross-surface anchors (`projects_to:calibration-data.md:row-N`)

Disallowed:

- External-stakeholder names
- Customer data
- Cowork-owned Layer 2 content
- Operator-personal data beyond the workspace-owner handle

### 4.3 Payload format

- ≤ 300 characters per row (single-row PIPE_BUF safety on POSIX append)
- Compact JSON (`{"key":"value"}`) OR `; `-separated key:value pairs (`key:value; key:value`); pipe grammar per § 4.3a
- Longer content → pointer to existing surface (e.g., `comment:https://github.com/{REPO}/issues/<N>#issuecomment-N`)

### 4.3a Payload pipe grammar (multi-value fields)

The `payload` cell is the **last of the 10 columns**, so a stray delimiter inside it
appends spurious trailing fields; it can never shift a pre-payload column. Readers
split on the canonical delimiter `" | "` (space-pipe-space).

**Row-integrity invariant.** A payload is admissible iff the assembled row is exactly
one physical line and splits into exactly 10 fields under `" | "`.

| Form | Status |
|---|---|
| `\\|` (backslash-escaped) | **Canonical multi-value separator.** Admitted. |
| `\|` (bare, unescaped) | **Reserved.** Rejected. |
| `" \| "` (space-delimited) | Rejected — it *is* the column delimiter. |
| payload ending in `" \|"` | Rejected — forms the delimiter at the row-trailing junction. |
| newline / carriage return | Rejected — a row is one physical line. |

**Why escaped and not bare.** The log is a markdown table. A bare `|` renders a
spurious cell break, and one consumer (`rollup-attribution.sh`) splits on a bare `|`
rather than on `" | "`, truncating the payload. `\|` is safe on both the parsing and
the rendering axis; bare `|` is safe on neither.

**Separator selection.** Use `\|` for multi-value *lists* (`triggers:[T1\|T2\|T3]`).
Do **not** repurpose `/`: it is already a value character inside payloads
(`verdict: <UPDATE>/<PRESERVE>/<N/A>`), so a `/` list separator would be ambiguous.
Key:value pairs remain `; `-separated.

**Authoring a payload convention.** A convention block that renders enum alternatives
in `{a|b}` notation MUST either escape them (`{a\|b}`) or state the runtime form
(`chose:spoke`). Enforcement: `append-pipeline-event.sh` § 4.3a guard + `--self-test`.

Rationale and alternatives: ADR-100.

### 4.4 One row per event

- Multi-event composites (e.g., a self-repair retry sequence) emit one row per attempt
- The final row's `outcome` carries the terminal state (`resolved` after success; `escalated` after retry exhaustion)

### 4.5 Concurrency

- `append-pipeline-event.sh` uses atomic single-row append via shell `>>` (POSIX guarantees single-writer safety when row size < PIPE_BUF / 4096 bytes — satisfied by § 4.3 constraint)
- Concurrent readers safe (append-only file, no locking required)

## 5. Cross-References to 4 Existing Surfaces

### 5.1 calibration-data.md

Event types `gate-outcome` carry `projects_to: calibration-data.md:<row-anchor>` in payload when the gate-outcome was ALSO captured in calibration-data's 12-column row.

Example:

```markdown
| 2026-05-15T14:22:01Z | v1.07a | 2 | gate-outcome | g1-g2 | spoke:#N | #N | CHEAP | resolved | projects_to:calibration-data.md; verdict:Approved; structural_pass:1.0 |
```

calibration-data continues to be authored by the gate-evaluation-spec.md path. Pipeline-event-log adds a STREAM row referencing it.

### 5.2 iteration-log.md

Event types `iteration` carry `projects_to: iteration-log.md:<row-anchor>` when the iteration was ALSO captured in iteration-log's 9-column row.

iteration-log continues to be authored by handoff-coordinator Phase 4. Pipeline-event-log adds a stream row referencing it.

### 5.3 The observation log (user auto-memory; REFERENCE only, never duplicate)

Pipeline-event-log MAY carry a `cited: <date>/<domain>/<theme>` pointer in payload as a REFERENCE to an existing observation entry.

- Pipeline-event-log NEVER duplicates observation content into payload (Layer boundary discipline; the observation log lives in the user auto-memory store, not under `pmo-platform/`).
- Pipeline-event-log NEVER auto-writes to the observation log (per [decision-discipline.md § 4.1 D-5](../../../core/disciplines/decision-discipline.md) operator-write-only contract).

Example:

```markdown
| 2026-05-15T16:00:00Z | v1.07a | 5 | escalation | tier-0 | spoke:#N | #N | EXPENSIVE | resolved | pt:none-c3-found; decision:proceed; cited:2026-05-11/release-ops/cutover-date-discipline |
```

### 5.4 Release-synthesizer Stage 13 self-learning (see § 11)

Event type `release-synthesis` emits one row per release at Stage 13. The release-synthesizer reads pipeline-event-log via [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) (`--event-type release-synthesis --event-subtype learnings-triple`) to compose the per-release learnings triple (surprise / would-change / watch-for) into the sibling H4 block in `RELEASE_LOG.md`. Full synthesizer contract: § 11.

Coordinate (NOT fold) — different milestone, different temporal anchor. Pipeline-event-log is the underlying event stream; the synthesizer at [`synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) is the release-synthesis read-model + pattern-detection process layered on top.

Example:

```markdown
| 2026-05-16T15:00:00Z | v1.07a | 13 | release-synthesis | learnings-triple | hub | release-level | CHEAP | resolved | surprise:retro-X; would-change:retro-Y; watch-for:retro-Z; feeds:release-synthesizer-when-shipped |
```

## 6. Worked Example: Cross-Surface JOIN for an Issue

> "To retrieve all events for issue #N in release v1.07a — including the rows in projected surfaces — run:
>
> ```bash
> ./release/tools/query-pipeline-event.sh --subject "#N" --version v1.07a
> grep -h '#N' <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md \
>                <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/iteration-log.md
> ```
>
> Combined output: gate-outcome rows (from calibration-data), iteration rows (from iteration-log), plus the unified-stream rows from pipeline-event-log. For Stage 13 release retrospective, pipe pipeline-event-log to `awk -F'\\|' '{print $4, $5, $6, $7}'` for stage/subtype/actor/subject summary."

## 7. Retention / Archival Policy

| Aspect | Policy |
|---|---|
| **Active retention** | 6 months OR last 12 releases (whichever covers MORE rows) — appended in-place to `pipeline-event-log.md` |
| **Quarterly archive** | Rows older than 6 months migrate to `pipeline-event-log-archive-YYYY-QN.md` (same directory, same schema); preserves grep/query semantics. Archive trigger: first calendar day of each quarter (Jan 1 / Apr 1 / Jul 1 / Oct 1) |
| **Permanent retention** | Archive files retained ≥ 3 years per ISO 15489-1:2016 Vital classification (audit trail = vital record) |
| **Destruction policy** | None. Append-only forever; archive moves preserve content per the least-destructive-disposition discipline |
| **Operator override** | Operator MAY redact a specific row via `[REDACTED for <reason>]` replacement of payload field — preserves row presence (audit trail) while removing content. Redaction emits a new `event_type=scope-change, event_subtype=redaction` row referencing the redacted row |

Cross-reference: `pipeline-event-log.md` and its archives carry the Vital classification per the records-management policy.

## 8. Cutover

**Effective:** Events occurring on or after the first release entering Stage 2 after schema publication.

**The schema's own publishing release is exempt.** Rationale: the schema and capture surface ship in that release; applying the rule to its own pipeline run would create a reflexive-pipeline loop (the capture surface cannot capture events for the release that introduces it). Pattern documented in the observation log (2026-05-11, theme `cutover-date-discipline-on-self-modifying-pipeline-edits`, emergence-pending).

**Pre-cutover releases:** exempt. No backfill of historical events. `pipeline-event-log.md` starts empty post-merge; first writes occur during the first release after schema publication.

**Schema-publication vs. capture-start:**

- At schema publication: schema published (this file); helpers shipped (`append-pipeline-event.sh`, `query-pipeline-event.sh`); empty `pipeline-event-log.md` shipped with header row only; empty `pipeline-event-log-write.log` shipped.
- At the first post-publication release: writes begin at Stage 2 entry; first quarterly archive fires no earlier than 6 months later.

## 9. Future-Automation Context

Schema and capture surface are agent-agnostic. The `actor` enum (`hub` / `spoke:#N` / `operator` / `skill:NAME`) survives the planned hub→skill transition.

| Consumer | Today | Future |
|---|---|---|
| Primary writer | hub via `hub-spoke-bridge.md` Procedures 4/5/7 step exits | `release-planner` skill, `release-executor` skill |
| Stage 4/5 writes | Stage 4/5 spokes for D-class + Tier 0 + re-review | unchanged (spokes always allowed) |
| Stage 6 writes | Engineering spokes for self-repairs + [ADJUST] commits | unchanged |
| Stage 12 writes | Hub for deploy events + retries | `release-executor` skill |
| Stage 13 synthesizer | [`synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) invoked by the Stage 13 spoke + closeout-automation (per § 11) | unchanged; pattern-detect mode optionally promoted to Platform Health Audit |
| Cross-release pattern detection | Manual grep / awk | Platform Health Audit |

## 10. References

- [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) — the capture surface (this schema describes it)
- [`release/tools/append-pipeline-event.sh`](../../tools/append-pipeline-event.sh) — write helper
- [`release/tools/query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) — read helper (extended with `--event-subtype` per § 11)
- [`release/tools/synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) — synthesizer (per § 11)
- [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log-write.log`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log-write.log) — write invocation log (consumed by `deploy.sh --check` Check 19)
- [`core/disciplines/decision-discipline.md`](../../../core/disciplines/decision-discipline.md) — § 4 pattern cache infrastructure; § 4.1 D-5 observation-log per-write operator approval
- [`release/governance/release-process.md`](../../governance/release-process.md) — 13-stage pipeline; Inter-Stage Feedback Protocol (Tier 0/1/2/3); QA checkpoints
- [`core/disciplines/autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) — Retry / Escalate / Rollback patterns
- [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md) — CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE tiers
- [`core/schemas/gate-evaluation-spec.md`](../../../core/schemas/gate-evaluation-spec.md) — calibration-data schema (gate-outcome projection)
- [`core/schemas/handoff-coordinator-spec.md`](../../../core/schemas/handoff-coordinator-spec.md) — iteration-log schema (iteration projection)
- [`core/standards/duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) — § 1 register-or-remove rule (rationale for merging § 11 here vs standalone `learnings-synthesis.md`)
- [`automation` roadmap](<OPERATOR_INSTANCE_ROADMAPS_PATH>/automation.md) § 1 Capability Outcome (operator-local) — "audit-trail capture" gap-closing
- Stage 5 Solutioning capture-surface — design ancestry (capture surface)
- Stage 5 Solutioning synthesizer — synthesizer design ancestry (relayed at first comment)
- Collective Review capture-surface — scope-lock APPROVED 2026-05-16 (capture surface)
- Collective Review synthesizer scope-lock — § 11 N-way consistency disagreement APPROVED 2026-05-23 (synthesizer + MERGE)

## 11. Release Synthesizer Contract

### 11.1 Synthesizer overview

The release synthesizer composes per-release learnings into a structured H4 block in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` and runs cross-release pattern detection. It is a CONSUMER of `release-synthesis/learnings-triple` events captured in [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per § 3 / § 5.4 — it does NOT write to that capture surface. The implementation is [`release/tools/synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh), composing over [`query-pipeline-event.sh`](../../tools/query-pipeline-event.sh) (with the `--event-subtype` filter).

The synthesizer is invoked at three surfaces:

1. The Stage 13 spoke at every release close (per-release mode), AFTER `append-pipeline-event.sh` has emitted the `release-synthesis/learnings-triple` row for the release, BEFORE the Stage 13 chore PR commits to `RELEASE_LOG.md` corpus-navigation update.
2. The `automated-closeout.sh` sibling capability — close-out automation which wraps the synthesizer invocation.
3. The operator or a quarterly audit (pattern-detect mode), ad-hoc.

### 11.2 Mode enum

| Mode flag | Trigger | Output | Invoker |
|---|---|---|---|
| `--mode per-release --version vX.Y` | At every Stage 13 close (post-learnings-triple-emit) | Renders the `#### Release Learnings vX.Y` sibling H4 block on stdout | Stage 13 spoke OR closeout-automation |
| `--mode pattern-detect --window N` | Release-count interval N (default 5) OR on-demand OR quarterly cron | Renders cross-release pattern report (markdown) on stdout; with `--apply`, files Issues via `gh issue create` | Operator (ad-hoc), quarterly audit, OR closeout-automation when `--with-pattern-scan` is set |
| `--self-test` | Stage 7 DT verification + post-deploy verification | Validates parsing, sentinel detection, per-release-block emit, pattern-detect emit; no side effects | Stage 7 spoke, `deploy.sh --check` (future Check) |

Per [`compute-cycle-time.sh`](../../tools/compute-cycle-time.sh) sibling pattern, the synthesizer:
- Is `PATH`-pinned to `/usr/bin:/bin` (per `bypass-mode-readiness.md` BLOCK-DESTRUCTIVE-020).
- Uses `/usr/bin/python3` stdlib only for payload parsing and clustering.
- Carries a built-in `--self-test` that exercises real data from `pipeline-event-log.md`.

### 11.3 Sibling H4 block schema

Per D-SchemaAdditivity (A) operator-approved at the D-Gate Resolution 2026-05-23, the synthesizer emits the following block IMMEDIATELY AFTER the existing `#### Deployment Log vX.Y` block in `RELEASE_LOG.md`:

```markdown
#### Release Learnings vX.Y

**Synthesized at:** <YYYY-MM-DDTHH:MM:SSZ>
**Source events:** N `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`vX.Y`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `<ts1>`[, `<ts2>`, …]

**Surprise:** <verbatim `surprise:` field from event payload(s); if N=1 single field; if N>1 joined with `; ` separator + per-row attribution `[from <ts>]`>
**Would-change:** <same composition rule for `would-change:` field>
**Watch-for:** <same composition rule for `watch-for:` field>

**Explicit-N/A markers (per AC8):** <count of source events whose triple fields were `N/A — no novel learning this release`; if N=N_total, the block renders the full triple as `N/A — no novel learning this release` without composition>
```

The three fields — `surprise`, `would-change`, `watch-for` — are inherited from the established `release-synthesis/learnings-triple` payload convention, in active use across captured events. The synthesizer does NOT rename these fields; it composes them into a reader-facing H4 block.

Field rationale (AC3 — ≥3 named fields with aggregation rationale per field):

| Field | Why this name | Aggregation rationale | Reading pattern supported |
|---|---|---|---|
| `surprise` | "What we did NOT predict at Stage 5 Solutioning / Stage 9 GO" — highest-signal class for forward-prediction calibration | Across multiple events (the pattern-detect mode), `surprise` clusters surface RECURRING blind spots — predictable-in-hindsight patterns the platform fails to anticipate | Operator at Stage 9 Plan Review of next release: "what did the last release surprise us about?" → reduces optimism bias in next release's risk register |
| `would-change` | "What we would do differently if we ran this release again" — actionable retro signal | Aggregating `would-change` across releases surfaces RECURRING wishes that justify protocol changes; ≥3 same-domain entries → auto-promotion trigger per § 11.5 | Operator at quarterly audit: "what did we keep wishing we had done differently?" → directly feeds the improvement backlog |
| `watch-for` | "What bears watching in subsequent releases as a downstream consequence of this one" — propagation signal | Aggregating `watch-for` validates whether expected consequences materialized (feeds calibration: were we right that X would surface?) | Stage 4 Planning agent for next release: "what did the prior release flag for us to monitor?" → seeds risk register without operator re-derivation |

### 11.4 Pattern-detection trigger modes (AC4)

All three modes. The synthesizer is mode-agnostic; trigger surfaces vary:

| Mode | Trigger surface | Cadence | Default threshold | Operator override? |
|---|---|---|---|---|
| **Release-count interval** | Stage 13 spoke OR closeout-automation when `--with-pattern-scan` is set; fires when `(release_count % N) == 0` | Every Nth release | **N=5** (CALIBRATE-AFTER-3 — operator tunes at any Stage 9 Plan Review) | YES — per-invocation `--window N` flag |
| **On-demand** | Operator invocation: `./synthesize-release-learnings.sh --mode pattern-detect --window 5` | Ad-hoc | N/A — operator specifies | YES — operator chooses window |
| **Quarterly audit** | Cron or scheduled task on the 1st calendar day of each quarter (Jan 1 / Apr 1 / Jul 1 / Oct 1) — aligned with § 7 quarterly archive trigger | 4×/year | Trailing 1 quarter (matches § 7) | YES — operator runs additional ad-hoc passes |

`--window N` defaults to trailing N **distinct versions** (not rows) so per-release qc4-05-result rows don't dominate the cluster signal. `--window-by-row` switches to N rows for explicit row-count semantics.

### 11.5 Auto-promotion criteria (AC5)

When pattern-detect mode identifies a cluster of ≥`cluster_min` same-domain signals in the trailing window, AND the cluster spans ≥2 distinct version tags, AND the `--apply` flag is set, the synthesizer files a GitHub Issue via `gh issue create` with labels `improvement`, `auto-promoted-pattern`, `status: proposed`.

Auto-promotion trigger predicate:

```
emit Issue if (
  cluster_size >= cluster_min                              # default cluster_min=3
  AND cluster spans >= 2 distinct version tags             # not a single-release noise burst
  AND cluster_keyword length >= 4 chars                    # excludes pronouns / stopwords
  AND cluster_keyword NOT in synthesizer stopword list     # see § 11.5 stopwords
)
```

The conservative ≥3 threshold (above the N=2 operator-driven emergence rule for the observation log per `decision-discipline.md` § 4.1) reflects that the synthesizer auto-files Issues without operator pre-approval. Operators can tune the threshold via `--cluster-min N` per invocation.

Stopwords: a minimal default list ships in `synthesize-release-learnings.sh` (~40 high-frequency terms — common English function words, platform-internal terms like `release` / `stage` / `milestone`, and the three field labels themselves). Out-of-scope drift to a `core/config/allowlists/synthesizer-stopwords.txt` external file is deferred to a future release when false-positive volume warrants.

Issue body template (auto-populated):

```markdown
**Auto-promoted from synthesizer pattern-detect**

**Pattern:** <cluster_keyword>
**Cluster size:** <N> events spanning versions <v1, v2, …, vN>
**Field:** <surprise | would-change | watch-for>
**Source events (pipeline-event-log.md):**
- ts `<ts1>`, version `<v1>`, payload excerpt: <…cluster_keyword…>
- …

**Triage instruction:** Review per `intake-style-guide.md` 5-test rule; reclassify or close-as-not-planned if false-positive.
```

The `auto-promoted-pattern` label gates the schema-maintenance trigger in § 11.6.

### 11.6 Schema-maintenance trigger (AC6)

Event-bound + metric-bound (not calendar-only):

```
fire schema-review if (
  count(gh issue list --label "auto-promoted-pattern" --state closed
                      --search "closed-as:not-planned"
                      --search "closed:>=<today-90d>")
  >= 3
)
```

I.e.: if 3+ auto-promoted Issues are closed-as-not-planned in any trailing 90-day window, the schema produces too many false positives and warrants review. Trigger fires from quarterly audit run output OR from operator manual check. Review scope on trigger: stopword list, cluster-min threshold, aggregation method (consider semantic-similarity scoring).

The trigger COMPOSES with existing platform cadences:
- 90-day window matches § 7 quarterly archive trigger (single durable cadence anchor)
- ≥3 threshold matches [`release-process.md`](../../governance/release-process.md) QC4-05 systemic-escalation threshold (single durable count anchor)

### 11.7 Forward-compatibility + cutover (AC7)

The sibling H4 block is **additive**. Consumer code MUST tolerate its absence on any release that lacks the `#### Release Learnings vX.Y` block.

| Consumer | Behavior on missing block |
|---|---|
| `release-planner` Mode B (next-release plan composition) | `grep -A 5 "#### Release Learnings v<prior>" RELEASE_LOG.md` returns empty; defaults to "No prior-release learnings available (pre-cutover release)" prose |
| Stage 9 Plan Review *Empirical Verification* subsection | Cites "Prior-release learnings: N/A (pre-cutover)" when no block exists for `v<prior>` |
| Quarterly audit (pattern-detect mode) | Queries `pipeline-event-log.md` directly (event surface is older); does NOT depend on `RELEASE_LOG.md` H4 block presence |
| Synthesizer per-release on a missing version | Emits an N/A block (forward-compatible fallback) rather than failing |

**Cutover-applicability rule:** the synthesizer emits the H4 block in RELEASE_LOG.md for releases that enter Stage 13 going forward. **The rule's own publishing release is EXEMPT** — its Stage 13 close emits the release-synthesis/learnings-triple event per the existing capture-start protocol but does NOT trigger the synthesizer (a rule's own shipping release cannot fire it without a reflexive-pipeline loop).

Matches the reflexive-pipeline-loop discipline of prior protocol introductions: pipeline-event-log capture, Phase A.5 main-divergence pre-check, Stage 12/13 chore-PR convention, Phase A.6 mergeStateStatus polling, Phase B0 dependent-PR pre-merge check, Phase J.5 rebuild-then-commit hygiene, Stage 13 orphan state cleanup, G-CL6 design-artifact refresh-gate.

### 11.8 Pattern-detect source selection (`--source`)

Pattern-detect is **source-parameterized**, not source-fixed. The same trailing-window + cluster + auto-promotion machinery (§ 11.4 / § 11.5) runs over either grain; only the input filter and the clustered field-set differ. This is a REUSE of the shipped ≥ 3-cluster engine, not a second cluster implementation — a second implementation would be the producer/producer-disagreement failure the Indicator-4 pointer discipline already rejects.

| `--source` | Input filter | Labels recognized in payload | Field(s) clustered | Zero-state excluded from clustering |
|---|---|---|---|---|
| `release-synthesis` (default — the pre-existing behavior, unchanged) | `--event-type release-synthesis --event-subtype learnings-triple` | `surprise` / `would-change` / `watch-for` | all three | a field equal to the literal `N/A — no novel learning this release` |
| `session-retro` | `--event-type session-retro` | `session` / `source` / `theme` / `domain` / `learning` / `reason` | `theme` ONLY | a `no-learning` row (`theme:` is REJECTED on it at emit time and the row is skipped by subtype at read time, so it contributes nothing **by enforcement**) |

**Why `theme:` only.** Free-text `learning:` prose would cluster on incidental vocabulary and manufacture patterns out of shared phrasing — the same over-capture noise the sampling threshold exists to suppress. `theme:` is an author-chosen kebab-case key, so a cluster of ≥ 3 same-`theme` rows across ≥ 2 versions is a real recurrence of the same pattern rather than a vocabulary coincidence. The remaining labels are recognized so the parser terminates each field cleanly; they are not tokenized.

**This table is the single authority for the recognized-label set.** `append-pipeline-event.sh` PARSES the "Labels recognized in payload" column from this table and rejects any other segment-opening label at emit time; `synthesize-release-learnings.sh` reads to the same set. Restating the set in either tool instead of reading it here is what produced the drift where the schema listed five labels and the tool enforced six — `append-pipeline-event.sh` now asserts its static fallback against this table in `--self-test`, so a one-sided edit on the write path fails rather than ships. `synthesize-release-learnings.sh` does NOT: its label set is a static `SOURCE_CONTRACT` literal that is never read from, nor checked against, this table, so a read-side drift passes `--self-test` silently. Holding that literal in step with this table is a manual obligation, recorded as a PARTIAL acceptance condition in the v3.101 release.

**Why an unrecognized label is a defect, not a curiosity.** The reader terminates each payload field at the next recognized label. An unrecognized label is therefore swallowed into the **preceding** field's content and tokenized as if it were signal — one stray label after `theme:` turned a single real cluster into three. Because the log is append-only, such a row can never be deleted, only redacted. Enforcement is two-sided but bounded to the `;`-separated segment grammar both tools implement: the write-side gate splits the payload on `;` and rejects a stray label that opens a segment, and the read side terminates a field at a recognized label or at any `;`-opened label token and discards the content that follows. A stray label joined by any other separator opens no segment, so the write gate never sees it and the read side never terminates on it — it is swallowed into the preceding field verbatim and tokenized (a `theme:` value renders as `over-building mood:excited`). Over the 94 printable-ASCII separators a payload can carry, `;` is the only one the write gate rejects and the only one on which the read side returns a correct cluster count; of the remainder, 30 inflate one real cluster into three and 63 destroy the genuine `theme` token outright. Closing that residue is recorded as a PARTIAL acceptance condition in the v3.101 release. **Scope:** only the two `--source` grains in this table declare a label set and are validated. Event types absent from this table carry open free-form payload keys and are deliberately NOT label-validated.

The auto-promotion predicate, the ≥ 2-distinct-version requirement, the `--apply` gate, and the `improvement.yml` CANDIDATE body are shared verbatim across both sources — a session-retro cluster promotes through exactly the same governance gate, never a direct change.

