<!-- reference-durability: allow-link -->
# Architecture-Conformance Summary (committed hand-off surface)

> **Producer:** `pmo-qa-auditor` Mode I (As-Built Architecture-Conformance Audit) — overwrites
> the headline block below on each run (single-record-overwrite). **Consumer:** the
> `health-check` skill `full` sweep reads this committed file to surface a platform-context
> conformance flag off any instance. This file **ships in the repo** (tracked) precisely so
> the health-check flag is not satisfied vacuously off the producing instance — the full
> read-once audit lives in the git-ignored `analysis/architecture-conformance-YYYY-MM-DD/`
> folder; this is the durable committed mirror of that folder's SUMMARY headline. Schema:
> [`architecture-conformance-mode-spec.md`](../../core/skills/pmo-qa-auditor/references/architecture-conformance-mode-spec.md)
> §7b. When-to-run: [`architecture-conformance-cadence.md`](../references/protocols/architecture-conformance-cadence.md).

## Latest run

| Field | Value |
|---|---|
| Status | **AWAITING FIRST RUN** — no architecture-conformance audit has run on this instance yet |
| Audit date (UTC) | _(none)_ |
| `baseline_sha` | _(none)_ |
| `baseline_date` | _(none)_ |
| Conformance posture | _(none — awaiting first run)_ |
| Conformant / drift / fragmentation-candidate / no-baseline | _(none)_ |
| Fragmentation groups (candidate) | _(none)_ |
| Fragmentation confidence bound | Candidate-grade, ADR-citation-bounded — the release record does not carry architecture-followed for un-ADR'd deliveries (mode-spec §2 / §4b) |
| Latest analysis folder | _(none — `analysis/architecture-conformance-YYYY-MM-DD/` produced at first run)_ |

## How health-check reads this

`health-check` `full` reads the **Status** and the classification counts above:

- **AWAITING FIRST RUN** → health-check surfaces a `## Unknowns` coverage note ("architecture-
  conformance audit has not run on this instance — platform-altitude context unavailable").
- Open conformance-drift / fragmentation-candidate flags → health-check surfaces a run-header
  line + a labeled `## Unknowns` row, explicitly marked **platform-altitude context, not
  project drift** (health-check audits a single project; this flag is platform-scope).

health-check **composes** this flag by reading the committed surface — it never re-runs the
platform audit (compose-not-absorb, ADR-019). See
[`operations/skills/health-check/references/conformance-surface.md`](../../operations/skills/health-check/references/conformance-surface.md)
for the consumer-side read contract.
