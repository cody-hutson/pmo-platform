<!-- reference-durability: allow-link -->
# Mode A — Incremental Maintenance (algorithm)

The default mode. Place new or changed work into the **stable, ratified** initiative → capability-slice
→ horizon, sync the operator's board fields + roadmap §3, and route anything uncertain to the operator
queue. The ratified initiative set is **read-only** throughout this mode — re-opening it is Mode B.

## Pre-flight

1. **Resolve the baseline** per `SKILL.md` § Baseline Resolution & Degradation:
   - board ids via `operator.toml [projects]` (see [`board-reference-contract.md`](board-reference-contract.md)),
   - the ratified initiative set via the operator-pointer (live `initiative:` label set, or operator-local `initiative-set-final.json`).
2. If the baseline is **unconfirmable**, switch to **queue-only**: every placement routes to the operator
   queue, zero silent board writes. Continue — do not hard-fail.
3. Load the ratified initiative set **read-only**. Hold its membership as an assertion target for every
   placement.

## Steps

### 1. Freeze the delta

Enumerate only the **new or changed issues since the last run** (a since-last-run watermark — e.g., issues
created/updated after the last Mode-A run timestamp). Do NOT enumerate the whole backlog; a full re-pass is
Mode B and risks eroding the ratified set. The frozen delta is the working set for the rest of the mode.

### 2. Theme-extract (from the body, not the label)

For each issue, derive its **capability theme from the issue body** — the source of truth — not from an
inherited candidate name, a title token, or a pre-existing `cluster:`/`initiative:` label. The label is a
hint to be verified in step 4, never the classifier. (Classifying by the name reproduces the
consolidation's documented candidate-name-inheritance failure mode.)

### 3. Assign into the ratified set

Place each issue into the existing **initiative → capability-slice → horizon**:
- **Initiative / slice** — match the extracted capability to the best-fitting initiative and its
  capability-slice in the read-only ratified set.
- **Horizon (Now / Next / Later)** — derive from **dependency-floor + value/effort**, sequence-not-time.
  No date field participates. (Reuse the dependency-analysis machinery the release-planner/executor
  siblings use for the dependency floor.)

**An issue that fits no initiative does NOT mint a new one.** Route it to the operator queue and increment
the Mode-C re-baseline-drift counter — "fits no initiative" is a re-baseline *signal*, not a license to
edit the set.

### 4. Adversarial-verify

Challenge every placement: "why this initiative and not its neighbor — by **capability**, not by name?"
Assign each placement an evidence-quality label (`[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]`) and
a confidence (HIGH / MEDIUM / LOW). Route to the **operator queue** (never a silent write) when:
- confidence is LOW, OR
- the body-derived capability conflicts with the issue's existing label/title, OR
- two initiatives fit comparably (a tie the operator should break).

Surface both readings on a queued conflict.

### 5. Emit board fields + roadmap §3 row

For confirmed placements only (HIGH/MEDIUM, no conflict), on a confirmed baseline:
- **Board fields** — write Initiative / Horizon / Value / Effort (and Status/Stage/Priority as applicable)
  via the **token-resolved ids** per [`board-reference-contract.md`](board-reference-contract.md). Never a
  literal id.
- **Label / milestone** — apply the `initiative:`/`cluster:` label (Tier 2 bounded-auto inside
  `cascade_scope`); **creating** a new label or milestone descends to **Tier 1** (operator confirm).
- **Roadmap §3 row** — **regenerate** the affected §3 Now/Next/Later row as a *projection* of the upstream
  surfaces (issue body → label → milestone → board fields → §3). Never hand-edit §3 as a second source.

The sync direction is fixed and one-directional. The §3 row is downstream of the board fields, not a
parallel input.

### 6. Report

Emit, per issue:
- the placement (initiative + slice + horizon + board fields),
- its evidence label + confidence,
- its **reversibility tier** (a single incremental field write is **CHEAP**; a batch across the board is
  **MODERATE**),

plus the **operator-queue list** (everything LOW/conflict, with both readings), and the updated
re-baseline-drift counter. On an unconfirmable baseline, the entire report is the operator queue (nothing
was written).

## Autonomy summary

| Action | Tier (confirmed baseline) | Tier (unconfirmable baseline) |
|---|---|---|
| Board field write (existing field, token-resolved) | Tier 2 bounded-auto (in `cascade_scope`) | Tier 1 (queue-only) |
| `initiative:`/`cluster:` label apply (existing label) | Tier 2 bounded-auto | Tier 1 (queue-only) |
| Label / milestone **creation** | Tier 1 (operator confirm) | Tier 1 |
| Roadmap §3 regeneration (projection) | Tier 2 (projection, not hand-edit) | — (read-only) |
| Initiative-set change | **Not permitted in Mode A** (Mode B + gate) | Not permitted |

## Invariants asserted by this mode

- The ratified initiative set is read-only; every placement's initiative ∈ the resolved set.
- Theme is body-derived; labels are verified, not trusted.
- Horizons are sequence-not-time (no date in the scoring path).
- §3 is a regenerated projection; sync is one-directional.
- LOW/conflict → operator queue, never a silent write.
