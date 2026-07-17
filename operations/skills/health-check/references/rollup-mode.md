<!-- reference-durability: allow-link -->
# Health-Check Rollup Mode

The `rollup` mode (mode 8, the v3 slice) drives the project↔portfolio **rollup contract**
on demand — **up-to-portfolio** (compose) or **down-through-project** (refresh) — so an
operator can refresh a rollup ad hoc instead of waiting for the scheduled cadence or
hand-editing rollup entities. It emits the same locked 5-section output as every other
health-check mode (`## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns`
/ `## Rollup-Diffs`) and is **read-only** by contract — it stages and routes, it never
writes a tracker or a bridge file itself.

This doc is the queryable spec for the three sub-modes + the rollup-contract field
mapping. The SKILL.md `## Modes` § Mode 8 is the authority for what the mode does; this
doc carries the full sub-mode + contract detail once.

## Sub-modes

| Invocation | Direction | What it does | Write routing |
|---|---|---|---|
| `rollup --scope portfolio` | up-to-portfolio | Audit per-project rollup-entity freshness vs PORTFOLIO.md, then **compose the PORTFOLIO.md proposal via `weekly-status-rollup` Section 6** (compose-not-absorb); re-home the staged proposal under `08-Generated/_health-check/`. | `## Rollup-Diffs` (staged, tiered; **never** a direct PORTFOLIO.md write) |
| `rollup --scope project --depth full` | down-through-project | Scan the project's sub-entities (Milestones / RAID Items / Plans / Resources) and propose a refreshed rollup entity. | `TRACKER_UPDATES:` block in `## Auto-Actionable` → `/tracker-manager` on approval |
| `rollup --scope project --depth status` | down-through-project | Quick refresh of the rollup entity's `status` fields only (lighter than `--depth full`). | `TRACKER_UPDATES:` block in `## Auto-Actionable` |

The three sub-modes have **distinct** behavior: `--scope portfolio` composes upward (and
routes the write to the portfolio owner); `--scope project --depth full` scans the full
sub-entity set downward; `--scope project --depth status` refreshes only the status fields.

## `--scope portfolio` — compose, not absorb

The portfolio direction's **native value-add is the freshness-drift audit**: for each
active project, is its rollup entity current against the sub-entities it summarizes, and
does PORTFOLIO.md reflect the latest per-project rollup entities? That audit is
health-check's own work and lands as findings in the 5-section output.

The **PORTFOLIO.md composition itself is not re-implemented here.** `weekly-status-rollup`
Section 6 (Portfolio Write-Back) is the live owner of composing PORTFOLIO.md from
active-project state — it builds the Portfolio Health Summary table, the Health Indicators
table, and the Top Risks set, presents a human-in-the-loop checkpoint, and never writes
without approval. `rollup --scope portfolio` **invokes** that owner and re-homes the staged
proposal under `08-Generated/_health-check/`, surfaced in `## Rollup-Diffs` with a
reversibility tier. Re-implementing the aggregation inside health-check would be the
*absorb* anti-pattern — see [`ADR-019 — Specialists compose, not absorb`](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md);
composition stays single-sourced in its owner, [`weekly-status-rollup`](../../weekly-status-rollup/SKILL.md).

## `--scope project` — sub-entity scan → rollup-entity refresh

The project direction refreshes **one** project's rollup entity from a scan of its
sub-entities. The sub-entity set is the project-entity model — **Milestones, RAID Items,
Plans, Resources** (per [`project-entity-model.md`](../../../../core/disciplines/project-entity-model.md)):

- **`--depth full`** scans all four sub-entity classes and proposes a fully-refreshed
  rollup entity.
- **`--depth status`** is the quick path — it refreshes the rollup entity's `status`
  fields only, not a full sub-entity re-derivation.

The rollup entity lives in the project's `04-PMO-Operations/` folder and is a
**Document-Tier-2 tracker**, not a Tier-1 file. Its proposed field changes therefore route
through a `TRACKER_UPDATES:` block in `## Auto-Actionable` (the same tracker-manager schema
every other mode emits) for `/tracker-manager` to apply **on approval** — they are **not**
placed in `## Rollup-Diffs` (which is reserved for the PROJECT.md / PORTFOLIO.md
proposals). The skill never applies the update itself.

## Rollup-contract field mapping

The rollup mode binds to the platform's per-project **portfolio-writeback rollup
contract** — a publishing schema plus the per-project rollup entity
`[Project]/04-PMO-Operations/[Project]_Rollup.md`. The contract's per-project publishing
fields, referenced by role-name (duplicate-source-discipline — the contract owns the
definitions):

| Contract field | Rollup meaning |
|---|---|
| `status` | The project's current health/phase signal (the `--depth status` refresh target). |
| `top_risks[]` | The top open RAID risks (from the RAID sub-entity scan). |
| `key_dependencies[]` | The cross-project / external dependencies the project publishes upward. |
| `capacity_signal` | The resource/capacity posture (from the Resources sub-entity scan). |
| `milestone_delta` | The change in milestone state since the last publish (from the Milestones sub-entity scan). |
| `completeness_score` | How complete the rollup entity's own fields are. |
| `last_published` | When the rollup entity was last refreshed upward. |

The contract standard is `core/standards/portfolio-writeback-contract.md` — its schema is
the SSOT for these fields; this doc maps to it by role-name and does not restate the
definitions.

## Contract-tolerant (graceful degradation)

The portfolio-writeback contract standard and the per-project rollup entity are
**in-flight** — owned by a separate milestone that has not yet shipped. The rollup mode is
therefore **contract-tolerant**, mirroring the skill's existing ADR-051 MCP-degradation
posture (reduce coverage, never silently downgrade rigor — see
[`ADR-051`](../../../../core/ADRs/ADR-051-health-check-mcp-primary-source-set.md)):

- When `core/standards/portfolio-writeback-contract.md` or a project's
  `[Project]/04-PMO-Operations/[Project]_Rollup.md` entity is **absent**, the mode
  surfaces a `## Unknowns` **coverage-gap** — e.g. "rollup entity not present for
  `<Project>`; the portfolio-writeback contract is not yet shipped — audited the
  sub-entities that are present; cannot compose the missing rollup entity" — stating what
  it searched and why it could not link.
- It **never fabricates** a rollup entity, and it **never crashes** on the missing
  contract. A missing entity is a surfaced gap, not a silent skip and not an invented file.
- The field mapping above binds by role-name, so it resolves cleanly the moment the
  contract standard and the rollup entity ship — no edit to this mode is required to
  activate the full contract.

## Bridge-file boundary (AC-3)

PORTFOLIO.md is a **Cowork-owned Layer-3 bridge file** (Claude Code reads it for context;
Cowork owns the writes). `rollup --scope portfolio` **stages** a composed PORTFOLIO.md
proposal in `08-Generated/_health-check/` for operator approval and surfaces it in
`## Rollup-Diffs` with a reversibility tier — it **never writes PORTFOLIO.md directly**.
The composition is routed to `weekly-status-rollup` (its Section 6 owns the write-back and
its own human-in-the-loop approval gate); health-check's output stays read-only on the
bridge file. This is the R-3 bridge-file boundary the release plan names, and it is the
same staged-diff discipline the `## Rollup-Diffs` section applies to every Tier-1-file
proposal.

## Argument grammar + unknown-value error (AC-5)

The load-bearing `rollup` / `--scope` / `--depth` argument parse is homed in the SKILL.md
`## Interactive & Scheduled Invocation` grammar (in-repo, PR-tracked), not in a separate
slash-command file. In brief: `--scope` ∈ {`portfolio`, `project`}; `--depth` ∈ {`full`,
`status`} and applies only to `--scope project` (default `full`). An **unrecognized
`--scope` or `--depth` value returns an actionable error naming the valid values and the
skill does not run against a guessed default** — the same no-silent-default discipline
`plan <name>` applies to a missing plan name. See the SKILL.md invocation grammar for the
authoritative parse contract.
