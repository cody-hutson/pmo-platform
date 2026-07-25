---
title: ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)
status: Accepted
date: 2026-05-17
release: stage-execution-and-process-discipline
deciders: "Cody Hutson (operator) + Stage 5 Solutioning spoke"
tags: [audit, baseline, release-ops, file-overlap, contention-scoring]
source_observations:
  - "The first cross-PR file-overlap audit (2026-05-01, the first ADR-001 application), conducted against audit-baseline SHA 690eaf71 using the hybrid baseline introduced by ADR-001 (20 most-recent merged PRs + 0 open PRs). The audit surfaced 4 HIGH-tier files (score >=3): RELEASE_LOG.md (5 PRs), governance roadmaps/release-process-fitness.md (3), engineering/evals/results/triage-design-rereview-instrumentation.md (3), and CLAUDE.md (3). During Stage 6 Engineering, manual post-hoc classification revealed 3 of the 4 HIGH-tier files were structurally append-pattern (every release / every retrospective / every instrumentation line adds a new entry rather than rewriting existing content) - these almost never conflict at merge time and require no mitigation. The 8-column contention schema (file_path, pr_number, pr_state, pr_title, pr_url, state_timestamp, file_domain, change_type) did not capture the append-vs-overlapping-edit distinction; SUMMARY.md Recommendation 4 surfaced this as a future-audit guidance gap, and the Retrospective Findings section recorded the schema enhancement as a candidate observation pending pattern recurrence. The cutpoint distribution validation (HIGH=4, MEDIUM=5, LOW=97) passed all D-3 thresholds; cutpoints (>=3 / 2 / 1) carried forward unchanged."
---

# ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)

## Status

Accepted (operator decision rendered at Stage 4 D-E 2026-05-17; Stage 5
spec authored at Stage 5 2026-05-17; ADR authored at Stage 6 per
Stage 5 spec § Decision). Numbered ADR-005 because ADR-002 / ADR-003 /
ADR-004 were taken between issue authorship (2026-05-02) and
Stage 4 (2026-05-16); the body's proposed "ADR-002 (or revised
ADR-001)" framing was mechanically unavailable at the numbering layer.
The body's substantive intent — preserve ADR-001 baseline; supersede-
from-cutover-onward with append-pattern detection — is honored without
modification to ADR-001.

## Context

[`ADR-001`](ADR-001-cross-pr-overlap-audit-baseline.md) established the
Cross-PR Overlap Audit baseline policy (hybrid: last-N merged PRs ∪ open
PRs at audit-start SHA; default N=20; long-format schema with 8 columns;
HIGH ≥3 PRs / MEDIUM = 2 PRs / LOW = 1 PR cutpoints). The first
application produced 4 HIGH-tier findings.

The SUMMARY.md § 3 table classified those 4 findings with a
manual annotation in the "Pattern" column: 3 of 4 were tagged
`Append-pattern` (RELEASE_LOG.md = 5 PRs all appending new release rows;
release-process-fitness.md = 3 PRs all inserting new § 3 rows;
triage-design-rereview-instrumentation.md = 3 PRs all appending
instrumentation log lines); 1 of 4 was tagged
`Co-located governance — multiple-section edits` (CLAUDE.md = 3 PRs each
editing different sections — Continuous Improvement / Governance File
Map / Layer-Domain tables).

The hand-annotation captured the operationally-load-bearing distinction.
The SUMMARY.md § 4 "Append-pattern files: do NOT mitigate as contention"
recommendation made the distinction explicit:

> 3 of the 4 HIGH-tier findings ... are **append-pattern files** —
> multiple PRs add new entries (rows, log lines, sections) without
> overwriting prior content. Append-pattern PRs almost never conflict
> at merge time.
>
> **Mitigation:** None. Append-pattern frequency is by design.

But the **schema did not encode the distinction**. The TSV columns
(`pr_number`, `pr_state`, `pr_title`, `pr_url`, `state_timestamp`,
`file_path`, `file_domain`, `change_type`) and the HIGH/MEDIUM/LOW tier
projection both treat all multi-PR files uniformly. SUMMARY.md § 4 +
§ 7 logged the distinction as an out-of-scope observation:

> Future audit may add line-range overlap analysis if pattern recurs
> (currently N=1; emergence threshold N=2 within 180 days per
> `decision-discipline.md` § 4.1).

Per the parent issue body + the Stage 13 retrospective,
the issue argues for codifying append-pattern detection at the schema
layer so future audits report `overlap_class` deterministically — both
to avoid over-reporting append-only files as HIGH contention (signal
dilution) and to direct bundle-time mitigation effort at line-range-
overlap files (the actual merge-conflict risk).

## Decision

**Extend the `contention-matrix.tsv` schema with 2 columns; classify
each contended file by `overlap_class`; preserve ADR-001 baseline
unchanged for the SUMMARY.md and any audit anchored at a
pre-cutover SHA.**

### Schema extension (additive — does not modify ADR-001 columns)

Two new columns appended to the long-format schema:

| Column | Type | Semantics |
|---|---|---|
| `line_ranges` | JSON array of `[start, end]` tuples | Post-diff coordinates of hunks added/modified by this PR on this file. One tuple per hunk. Empty array `[]` for pure-deletion PRs. Format: extracted from `@@ -A,B +C,D @@` hunk headers; `start = C`, `end = C + D - 1`. |
| `overlap_class` | enum: `append-pattern` | `line-range-overlap` | `single-pr` | Per-file classification derived from `line_ranges` across all PRs touching the file. See § Computation rule below. |

Long-format preserved (one row per `(PR, file)` pair); `overlap_class`
is per-file, repeated across that file's rows (denormalized for
readability; downstream consumers MAY project unique). Backward
compatibility: pre-cutover audits remain valid under the 8-column
schema; new audits add the 2 columns.

### Computation rule (binary classification with zero-tolerance overlap)

For each `file_path` appearing in ≥2 distinct `pr_number` rows:

1. Build the set `R(f)` of `line_ranges` arrays per PR touching the
   file. Each element is a list of `[start, end]` tuples in post-diff
   coordinates relative to the PR's own merge-base.
2. Compute pairwise overlap on `R(f)`: for every pair of PRs `(P_i,
   P_j)`, check whether **any** hunk in `P_i` overlaps **any** hunk in
   `P_j`. Two hunks `[s1, e1]` and `[s2, e2]` overlap iff
   `max(s1, s2) <= min(e1, e2)`.
3. Classification:
   - **`append-pattern`** — ALL pairs of PRs are disjoint (zero
     pairwise overlap across all hunk pairs).
   - **`line-range-overlap`** — AT LEAST ONE pair of PRs has at least
     one overlapping hunk pair.
   - **`single-pr`** — file appears in exactly 1 distinct `pr_number`
     row (no pairwise computation possible; classification is trivial).

The threshold is **0% pairwise overlap** = `append-pattern` (zero-
tolerance rule). Selected from 3 candidates (0% / <10% / <25%) per
ADR-005 § Evidence-Grounding artifact in the Stage 5 spec —
0% is the only threshold that matches the empirical SUMMARY.md
§ 3 hand-classification across all 4 HIGH-tier findings.

**Coordinate-shift limitation** (acknowledged): post-diff coordinates
shift as PRs merge sequentially. The audit operates at a baseline SHA
per ADR-001 § Decision (SHA pin captured in SUMMARY.md
`audit_baseline_sha:` field); each PR's `line_ranges` are derived from
that PR's `gh api repos/.../pulls/<N>/files` `patch` field, which is
anchored at the PR's merge-base. This produces conservative classification
(may report `line-range-overlap` for PRs whose ranges would have been
disjoint in the post-merge file). The conservatism is the safer error
direction — false positives prompt extra operator inspection; false
negatives (missed real overlap) would erode the audit's signal.

### Canonical implementation (script)

Add a new tool: `pmo-platform/engineering/tools/check-line-range-overlap.py`.
Python stdlib only (precedent: `check-doc-links.py`); `gh` CLI for
PR-files API access. Invocation:

```bash
python3 pmo-platform/engineering/tools/check-line-range-overlap.py \
  --baseline-sha <SHA> \
  --pr-list <comma-separated PR numbers> \
  --files <comma-separated file paths> \
  [--output-format tsv|json] \
  [--include-merged] [--include-open]
```

The script:
1. For each `(PR, file)` pair in the cross product of `--pr-list` and
   `--files`, fetches `gh api repos/<owner>/<repo>/pulls/<N>/files`
   filtered to that file path.
2. Parses the `patch` field's hunk headers (`@@ -A,B +C,D @@`) to
   extract `[C, C+D-1]` tuples; emits `line_ranges` JSON array per PR.
3. Computes `overlap_class` per file per the algorithm above.
4. Emits TSV (default) or JSON with the 2 new columns appended to the
   ADR-001 8-column schema.

The script is **OPTIONAL for small audits**. When the audit scope is
≤3 PRs on ≤2 files, the SUMMARY.md author MAY hand-classify by
inspecting `gh pr diff <N> -- <file>` output. ≥3-PR cases on the same
file SHOULD delegate to the script (reproducibility risk grows with
PR count). The SUMMARY.md methodology section MUST document whether
classification was script-derived or hand-classified.

### Cutpoint refinement (mitigation guidance)

The HIGH / MEDIUM / LOW score tiers (ADR-001 § Decision; thresholds
≥3 / 2 / 1 PRs) are PRESERVED unchanged. `overlap_class` is an
ADDITIONAL dimension that informs **mitigation recommendation**, not
the tier assignment:

| Score | overlap_class | Mitigation recommendation |
|---|---|---|
| HIGH (≥3) | `append-pattern` | None (informational only); SUMMARY.md § Recommendations notes "structurally HIGH, operationally LOW" |
| HIGH (≥3) | `line-range-overlap` | Sequence/scope-split mitigation strongly recommended (ADR-001 baseline guidance) |
| MEDIUM (2) | `append-pattern` | None (informational only) |
| MEDIUM (2) | `line-range-overlap` | Sequencing or risk-register entry recommended (ADR-001 baseline guidance) |
| LOW (1) | `single-pr` | None (no contention) |

The split preserves ADR-001's three-tier vocabulary while adding the
operationally-load-bearing axis. The "structurally HIGH, operationally
LOW" phrasing in SUMMARY.md § Recommendations is the canonical voice.

## Consequences

**Positive:**

- **Future audits surface actionable contention.** `overlap_class =
  line-range-overlap` files are the audit's real mitigation target;
  the schema makes this explicit rather than relying on per-audit hand
  annotation.
- **Append-pattern signal preserved without dilution.** RELEASE_LOG.md
  (Score 5 in the first audit) will continue to surface as a HIGH finding
  because every release Stage 13 appends a row — and that surfacing
  is informationally useful (audit confirms the Stage 13 append
  protocol is operating) — but mitigation effort is not directed at
  it.
- **ADR-001 baseline preserved.** The SUMMARY.md remains
  byte-identical; audits anchored at pre-cutover SHAs read under the
  pre-cutover schema (the 8 columns are unchanged); audits anchored at
  post-cutover SHAs read under the 10-column schema. No retroactive
  re-categorization needed.
- **Reproducibility improves.** The `check-line-range-overlap.py`
  script produces deterministic `overlap_class` output for a given
  baseline SHA + PR list + file list; re-runs against the same inputs
  produce byte-identical outputs.
- **Hand-classification fallback preserved.** Small audits (≤3 PRs)
  do not require script invocation; the per-pair overlap rule is
  inspection-tractable.

**Negative:**

- **Coordinate-shift conservatism (acknowledged).** Post-diff
  coordinates are anchored at each PR's merge-base, not at a global
  baseline. PRs whose ranges would be disjoint in the post-merge file
  may classify as `line-range-overlap` if their merge-base ranges
  collide. Mitigation: SUMMARY.md methodology section documents the
  conservatism; operator may downgrade specific findings with
  documented rationale.
- **Script becomes new audit infrastructure.** `check-line-range-
  overlap.py` joins the audit toolchain alongside the ADR-001 baseline
  collection (`gh pr list --state merged --limit N`). Tool maintenance
  is a non-zero cost. Mitigation: Python stdlib only + simple algorithm
  (≤200 lines per check-doc-links.py precedent); operates on existing
  `gh api` surface (no new dependencies).
- **Hunk parsing assumes standard unified-diff format.** The `gh api
  pulls/<N>/files` `patch` field returns standard unified diff; edge
  cases (binary files, very large diffs truncated by the API) may
  produce incomplete `line_ranges`. Mitigation: script emits a warning
  on truncated patches; operator inspects manually.

**Mitigation of negatives:**

- Coordinate-shift conservatism is the safer error direction (false-
  positive line-range-overlap prompts extra operator inspection; false-
  negative would erode the audit's signal). The first audit had 0 cases where
  this would have mis-classified (verified in Evidence-Grounding
  survey).
- Script's footprint is small (Python stdlib; <200 LOC expected).
  Maintenance burden compares favorably to per-audit hand-parsing cost
  for ≥3-PR cases.
- Unified-diff edge cases (binary, truncated patches) surface as
  warnings, not silent failures; operator-routable.

## Alternatives Considered

- **(A) Schema extension + zero-tolerance threshold + canonical script
  (selected).** Composed design — schema column + algorithm in ADR-005 +
  reproducible script + inline prose in Stage 4 A4. All four surfaces
  agree.
- **(B) Schema-only extension (no script)** — REJECTED. Hand-
  classification of ≥3-PR cases is non-trivial (every pair must be
  inspected); reproducibility across audit re-runs depends on author
  precision. R1 Evidence-Grounding discipline demands reproducible
  survey commands; "hand-classify" is not a survey command.
- **(C) Script-only (no schema column)** — REJECTED. `overlap_class`
  must be persisted in `contention-matrix.tsv` so the SUMMARY.md
  methodology can cite it without re-running the script; the schema
  column is the audit's durable artifact.
- **(D) Inline-only (Stage 4 A4 prose; no schema, no script)** —
  REJECTED. Prose without schema makes the distinction non-auditable
  across releases (each spoke might apply the rule differently); prose
  without script makes ≥3-PR cases unreproducible.
- **(E) Modify ADR-001 in-place with append-pattern detection** —
  REJECTED. Conflicts with the parent issue body's explicit "ADR-001 unchanged"
  requirement; conflicts with operator D-E LOCKED constraint; would
  retroactively re-categorize the SUMMARY.md.
- **(F) Renumber existing ADR-002 to ADR-006 and slot append-pattern
  at ADR-002** — REJECTED. ADR sequence is append-only governance
  precedent; renumbering breaks cross-references in ADR-002 references
  in `operating-model.md`, `terminology-glossary.md`, multiple
  governance files, and the package `pmo-platform/skills/*` SKILL.md
  references that cite ADR-002 by number.
- **Threshold alternatives** — three candidates evaluated; see § R1
  Evidence-Grounding artifact in Stage 5 spec:
  - 0% (selected) — matches the empirical hand-classification 4/4
  - <10% — would re-classify CLAUDE.md (3 PRs, 3 disjoint
    section edits) as `append-pattern`; doesn't match SUMMARY.md § 5
    hand-classification (which retained CLAUDE.md as the genuinely-
    overlapping file)
  - <25% — over-broad; risks classifying real overlap cases as append

## Reversibility

CHEAP — the change is additive at the schema layer (2 new columns
appended; pre-cutover audits unaffected); the script is a single new
file. Revert path:

1. `git revert` on the release merge commit removes the
   2-column extension prose from `pipeline/stage-04-planning.md`,
   `core/rules/release-process.md`, and `pmo-platform/engineering/
   rules/release-process.md`.
2. Delete `pmo-platform/engineering/tools/check-line-range-overlap.py`.
3. Delete `pmo-platform/governance/adr/ADR-005-append-pattern-aware-
   cross-pr-contention-scoring.md`.

ADR-001 baseline is untouched; the SUMMARY.md is untouched. No
data migration required.

## Cutover

Applies to all releases going forward; audits anchored at pre-cutover
SHAs continue under the ADR-001 8-column schema.

ADR-005 supersedes ADR-001 for audits anchored at post-cutover SHAs;
audits anchored at pre-cutover SHAs continue to read ADR-001's
schema and recommendation discipline. Both ADRs remain operative —
ADR-001 as baseline (8-column schema), ADR-005 as enrichment
(10-column schema + `overlap_class` axis).

## References

- Predecessor ADR: [`ADR-001-cross-pr-overlap-audit-baseline.md`](ADR-001-cross-pr-overlap-audit-baseline.md) (baseline policy preserved unchanged).
- Originating empirical evidence: the cross-PR file-overlap audit, conducted 2026-05-01 against audit-baseline SHA `690eaf71` using the ADR-001 hybrid baseline. Audit findings: 4 HIGH-tier files (score ≥3) — `RELEASE_LOG.md` (5 PRs), `roadmaps/release-process-fitness.md` (3), `engineering/evals/results/triage-design-rereview-instrumentation.md` (3), `CLAUDE.md` (3); 5 MEDIUM-tier files (score = 2); 97 LOW-tier (informational only). The audit's cutpoint distribution validation (HIGH=4, MEDIUM=5, LOW=97) passed all D-3 thresholds, so the ≥3/2/1 cutpoints carried forward unchanged.
- Append-vs-overlap distinction (the substantive trigger for this ADR): during Stage 6 Engineering manual classification of the 4 HIGH-tier files, 3 of 4 (`RELEASE_LOG.md`, `release-process-fitness.md`, `triage-design-rereview-instrumentation.md`) were structurally append-pattern — every Stage 13 close, every retrospective entry, every instrumentation log line adds a new row rather than rewriting existing content. Append-pattern PRs almost never conflict at merge time, so flagging them as contention is a false-positive that inflates the HIGH count without representing merge risk. The fourth HIGH-tier file (`CLAUDE.md`) was a different pattern — co-located governance with multiple-section edits across PRs that occasionally do conflict — calling for bundle-time sequencing rather than schema enrichment. The audit recorded this distinction as a future-audit guidance gap (the 8-column schema could not express `overlap_class`); ADR-005 codifies the enrichment.
- Stage 6 spoke output (this Engineering execution): authored at Stage 6 per the spec § Decision.
