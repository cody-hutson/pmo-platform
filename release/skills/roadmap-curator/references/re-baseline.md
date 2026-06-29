<!-- reference-durability: allow-link -->
# Mode B — Re-baseline (operator-gated)

The point-in-time mode that re-opens the **ratified initiative set itself**. It re-runs the full
consolidation arc and presents a fresh evidence package for the operator to ratify. **Nothing goes live
until the operator ratifies.** This is the ONLY path that may change the ratified set; Mode A never does.

## When it fires

- **Operator-explicit only** ("re-baseline the initiative set", "re-run the consolidation"), OR
- surfaced by Mode C / Mode A when **≥ N `initiative:`-drift signals** accumulate (issues that fit no
  initiative, recurring label-vs-capability conflicts). The accumulation **surfaces a recommendation** to
  the operator; it does not auto-trigger Mode B.

Mode B never auto-fires.

## The full consolidation arc

Re-run the complete arc (this is the reference implementation the v0 baseline encoded):

1. **Freeze** — snapshot the full backlog at a pinned commit + bounded window (audit-baseline discipline:
   record the anchor so the re-baseline is reproducible).
2. **Per-issue analysis** — theme + effort + value + priority + dependency edges, each from the issue body
   (source of truth), with evidence-quality labels.
3. **Dependency graph** — build the graph; run topological sort + critical-path (CPM); detect cycles. Reuse
   the dependency-analysis machinery the release-planner/executor siblings use; do not re-implement it.
4. **Initiative discovery** — cluster the themed work into candidate initiatives.
5. **Ratify** — the operator confirms (or revises) the candidate initiative set. **This is the gate.** The
   set is not "ratified" until the operator says so.
6. **Capability-slicing** — apply the 7-step vertical-capability-slice method to each ratified initiative.
7. **Horizon scoring** — score each slice into Now / Next / Later by **dependency-floor + value/effort**,
   sequence-not-time. No date field participates.
8. **Roadmap authoring** — author/refresh the §3 Now/Next/Later (and the §3a Identified Gaps with the §7.4
   4-case diagnostic) framework-conformant per
   [`core/standards/initiative-roadmap-framework.md`](../../../../core/standards/initiative-roadmap-framework.md).

## The operator-ratification gate

- Present the **evidence package**: the candidate (possibly revised) initiative set, the dependency graph,
  the slice breakdown, the horizon scoring, and a **diff against the prior ratified set** (what was added /
  merged / split / renamed / removed, with rationale per change).
- **Reversibility:** adopting a re-baselined set is **EXPENSIVE → IRREVERSIBLE** — the ratified set is the
  spine every Mode A placement, board field, and roadmap row reads downstream. State the tier, document
  rationale (≥2 sentences per set change), and either state the rollback plan or name the counter-commitment
  (a follow-on re-baseline that supersedes). Name the sign-off authority: the operator.
- **Nothing is written live until the operator ratifies.** On ratification, the new set becomes the
  read-only spine Mode A reads, and the board + roadmap are updated to the ratified set. Absent
  ratification, the prior set stands unchanged.

## Establishing a baseline from cold (degraded → confirmed)

Mode B is also the path to **establish** the baseline when it is unconfirmable (Mode A was running
queue-only / Mode C read-only). Run the arc, ratify the set with the operator, populate the board ids in
`operator.toml [projects]` (per [`board-reference-contract.md`](board-reference-contract.md)) and the
ratified-set pointer — after which Mode A's full auto-write enables on subsequent runs.

## Invariants asserted by this mode

- The set changes **only** via operator ratification — never silently, never in Mode A.
- The arc is reproducible (pinned freeze anchor + bounded window).
- Horizons are sequence-not-time.
- Re-baseline adoption carries an EXPENSIVE/IRREVERSIBLE tier + operator sign-off.
- The prior set stands unchanged unless and until the operator ratifies a replacement.
