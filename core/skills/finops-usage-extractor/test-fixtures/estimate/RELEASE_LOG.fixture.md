# RELEASE_LOG — synthetic fixture

> **SYNTHETIC.** Every version, point count, class, and figure below is fabricated for
> `estimate-usage.sh --self-test`. No real release is described. The file exercises the
> `**Velocity:**` grammar governed at `release/references/standards/release-velocity-tracking.md`
> — including the rows that must **fail to parse and be excluded**, never defaulted.
>
> Parsed shape: a `#### Deployment Log <version>` heading, then the first `**Velocity:**`
> line beneath it, from which `planned <N> pts` and `class <release-class>` are read.

## Release Ledger (synthetic)

The `| Version | Milestone | ... |` ledger is the **alias source**. A roll-up work item may
be keyed on the milestone slug (canonical since ADR-092) while a Deployment-Log heading
carries the version form, so a velocity entry reachable under only one key would drop its
release out of the estimator basis as `P7 unkeyable`. Each entry is therefore emitted under
both keys. The two rows below exercise the two normalizations:

- `v9.94` ↔ `v9.94-alpha-slug` — a **`vX.Y-` stem is stripped** from a Milestone cell, so
  the alias is `alpha-slug`, not `v9.94-alpha-slug`.
- `gamma-slug (version-less)` ↔ `v9.90` — a Version cell of the form `<slug> (version-less)`
  contributes only its **leading whitespace-delimited token**, so the alias is `gamma-slug`.

Neither alias adds a Deployment-Log heading, so the comparable population is unchanged —
aliasing adds keys, never values.

| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.94 | v9.94-alpha-slug | #9001 | #9101 | aaaa111 | v9.94 | shipped | 2020-01-01 |
| gamma-slug (version-less) | v9.90 | #9002 | #9102 | bbbb222 | — | shipped | 2020-01-02 |

## Deployment Log

#### Deployment Log v9.94
**Velocity:** planned 18 pts / delivered 18 pts (1.00); files-changed 22; allocation 18/0/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v9.94`).

#### Deployment Log v9.93
**Velocity:** planned 20 pts / delivered 20 pts (1.00); files-changed 31; allocation 16/4/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v9.93`).

#### Deployment Log v9.92
**Velocity:** planned 16 pts / delivered 16 pts (1.00); files-changed 19; allocation 16/0/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v9.92`).

#### Deployment Log v9.91
**Velocity:** planned 14 pts / delivered 14 pts (1.00); files-changed 12; allocation 8/6/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v9.91`).

#### Deployment Log v9.90
**Velocity:** planned 12 pts / delivered 12 pts (1.00); files-changed 15; allocation 12/0/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v9.90`).

#### Deployment Log v9.85
**Velocity:** planned 12 pts / delivered 12 pts (1.00); files-changed 6; allocation 0/12/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.85`).

#### Deployment Log v9.84
**Velocity:** planned 10 pts / delivered 10 pts (1.00); files-changed 5; allocation 0/10/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.84`).

#### Deployment Log v9.83
**Velocity:** planned 10 pts / delivered 10 pts (1.00); files-changed 7; allocation 2/8/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.83`).

#### Deployment Log v9.82
**Velocity:** planned 8 pts / delivered 8 pts (1.00); files-changed 4; allocation 0/8/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.82`).

#### Deployment Log v9.81
**Velocity:** planned 8 pts / delivered 8 pts (1.00); files-changed 3; allocation 0/8/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.81`).

#### Deployment Log v9.80
**Velocity:** planned 6 pts / delivered 6 pts (1.00); files-changed 3; allocation 0/6/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.80`).

#### Deployment Log v9.73
**Velocity:** planned 14 pts / delivered 14 pts (1.00); files-changed 40; allocation 6/6/2 pts (feature/debt/protocol-slack); class cross-cutting (mechanism: `compute-release-velocity.sh v9.73`).

#### Deployment Log v9.72
**Velocity:** planned 12 pts / delivered 12 pts (1.00); files-changed 33; allocation 6/6/0 pts (feature/debt/protocol-slack); class cross-cutting (mechanism: `compute-release-velocity.sh v9.72`).

#### Deployment Log v9.71
**Velocity:** planned 10 pts / delivered 10 pts (1.00); files-changed 28; allocation 4/6/0 pts (feature/debt/protocol-slack); class cross-cutting (mechanism: `compute-release-velocity.sh v9.71`).

#### Deployment Log v9.70
**Velocity:** planned 8 pts / delivered 8 pts (1.00); files-changed 21; allocation 4/4/0 pts (feature/debt/protocol-slack); class cross-cutting (mechanism: `compute-release-velocity.sh v9.70`).

#### Deployment Log v9.63
**Velocity:** planned 8 pts / delivered 8 pts (1.00); files-changed 11; allocation 8/0/0 pts (feature/debt/protocol-slack); class wide-dispersion (mechanism: `compute-release-velocity.sh v9.63`).

#### Deployment Log v9.62
**Velocity:** planned 6 pts / delivered 6 pts (1.00); files-changed 9; allocation 6/0/0 pts (feature/debt/protocol-slack); class wide-dispersion (mechanism: `compute-release-velocity.sh v9.62`).

#### Deployment Log v9.61
**Velocity:** planned 6 pts / delivered 6 pts (1.00); files-changed 8; allocation 6/0/0 pts (feature/debt/protocol-slack); class wide-dispersion (mechanism: `compute-release-velocity.sh v9.61`).

#### Deployment Log v9.60
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 5; allocation 4/0/0 pts (feature/debt/protocol-slack); class wide-dispersion (mechanism: `compute-release-velocity.sh v9.60`).

#### Deployment Log v9.51
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 4; allocation 4/0/0 pts (feature/debt/protocol-slack); class thin-population (mechanism: `compute-release-velocity.sh v9.51`).

#### Deployment Log v9.50
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 4; allocation 4/0/0 pts (feature/debt/protocol-slack); class thin-population (mechanism: `compute-release-velocity.sh v9.50`).

#### Deployment Log v9.41
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 2; allocation 4/0/0 pts (feature/debt/protocol-slack); class thin-population (mechanism: `compute-release-velocity.sh v9.41`).

#### Deployment Log v9.40
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 2; allocation 4/0/0 pts (feature/debt/protocol-slack); class thin-population (mechanism: `compute-release-velocity.sh v9.40`).

#### Deployment Log v9.31
**Velocity:** class routine; 3 delivery slices (synthetic narrative row carrying no `planned N pts` figure — must be EXCLUDED as `unkeyable`, never defaulted to 0).

#### Deployment Log v9.30
**Velocity:** N/A — synthetic content-only row; no sizing performed (must be EXCLUDED as `unkeyable`, never defaulted).

#### Deployment Log v9.10
**Velocity:** planned 4 pts / delivered 4 pts (1.00); files-changed 1; allocation 4/0/0 pts (feature/debt/protocol-slack); class routine (mechanism: `compute-release-velocity.sh v9.10`). The matching rollup row carries a zero four-leaf total, so P5 excludes it regardless of this keyable row.

<!-- NOTE: milestone:v9.20 deliberately has NO Deployment Log entry here — it exercises
     the "no release-log row at all" exclusion path (reason: unkeyable). -->
