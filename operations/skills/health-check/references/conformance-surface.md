---
title: Architecture-Conformance Surfacing Contract — health-check consumer side
purpose: The read-only contract by which health-check `full` surfaces the platform-context architecture-conformance flag from the committed conformance-summary surface produced by pmo-qa-auditor Mode I.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Architecture-Conformance Surfacing Contract (health-check consumer side)

health-check is the **consumer**; `pmo-qa-auditor` **Mode I** (As-Built Architecture-Conformance
Audit) is the **producer**. health-check reads Mode I's committed output and surfaces a flag; it
never runs the audit and never writes the audit's output. This is compose-not-absorb
([`core/ADRs/ADR-019-specialists-compose-not-absorb.md`](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)),
the same seam `rollup` uses to compose `weekly-status-rollup`.

## 1. What is read (the committed surface)

health-check `full` reads **one committed, tracked file**:

```
release/releases/architecture-conformance-summary.md
```

This file **ships in the repo** — it is present on every clone, seeded with an `AWAITING FIRST
RUN` state, and overwritten by each Mode I run (single-record-overwrite). health-check reads it
**read-only**. The full, per-run read-once audit lives in the git-ignored
`analysis/architecture-conformance-YYYY-MM-DD/` folder; health-check does **not** read that
folder (it is operator-instance, often absent off the producing instance). Reading the
committed surface — not the git-ignored folder — is what makes the flag non-vacuous on any
instance.

## 2. Fields consumed

From the surface's `## Latest run` block, health-check reads:

| Field | Use |
|---|---|
| `Status` | `AWAITING FIRST RUN` → render the coverage note; otherwise render the flag |
| Conformance posture + classification counts (conformant / drift / fragmentation-candidate / no-baseline) | the run-header line + the `## Unknowns` row body |
| Fragmentation groups (candidate) + confidence bound | included in the flag, tagged candidate-grade |
| `baseline_date` | staleness read (a `baseline_date` older than the cadence's 90-day floor is itself surfaced as a coverage note) |
| Latest analysis folder pointer | the `## Unknowns` row's pointer for the operator to open the full audit |

## 3. How it renders (platform-context, never project drift)

- **Run-header line** (full mode only), when open drift/fragmentation flags exist:
  `[ARCH-CONFORMANCE: <N drift · M fragmentation-candidate> — platform-context]`.
- **A single `## Unknowns` row**, always labeled **"platform-altitude context, not this
  project's drift"**, citing the committed surface as `[SOURCE]` and pointing to the latest
  audit folder. Rationale for `## Unknowns`: the conformance read is platform-scope and cannot
  be linked to *this project's* canonical sources — it is context the operator should see, not a
  project-drift finding.

**Never `## Auto-Actionable`.** The flag is platform-scope, single-source, and not a
project-drift action — it is capped out of `## Auto-Actionable` by the same discipline that caps
any single-source finding (the confidence rule), and additionally by altitude (it is not this
project's state).

## 4. Degradation (contract-tolerant)

- **`AWAITING FIRST RUN` or file absent** → a `## Unknowns` coverage note: "architecture-
  conformance audit has not run on this instance — platform-context unavailable." Never fabricate
  a conformance read; never crash. (Mirrors the skill's ADR-051 MCP-degradation posture and the
  `rollup` contract-absent posture.)
- **`baseline_date` stale (> 90 days)** → surface the staleness as a `## Unknowns` note so the
  operator knows the platform-context read may lag; do not treat a stale read as current.

## 5. Boundary (what health-check must NOT do)

- MUST NOT re-run the conformance audit (that is the ADR-019 absorb anti-pattern — the audit is
  platform-altitude and Mode I owns it).
- MUST NOT write to `release/releases/architecture-conformance-summary.md` (Mode I is its sole
  producer).
- MUST NOT promote the flag to `## Auto-Actionable` or emit a `TRACKER_UPDATES:` entry for it.
- MUST label the flag platform-context in both render slots so it is never mistaken for this
  project's drift.
