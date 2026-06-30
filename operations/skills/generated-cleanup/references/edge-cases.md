# Generated Cleanup — Edge Cases and Worked Detail

Progressive-disclosure detail for `generated-cleanup/SKILL.md`. The SKILL.md body carries the contract (the three groups, the `promotion_state` archive split, the unconditional approval gate, the Auto-Archive composition, the conflation boundary). This file carries the implementation detail a junior implementer needs to reproduce the scan correctly without bloating the main body.

## The staleness derivation (Group 1, computed — not stamped)

There is no stamped `lifecycle_state: stale` to read on the promoted-and-stale population (`stale` is in the Domain-C enum but no producer stamps it on a promoted artifact — the artifact-generator Zombie Detection step is a flag that explicitly does NOT auto-transition). Derive it the way the platform already detects staleness:

1. **Compute the last-referenced date** for each promoted artifact — the most recent date on which any other tracked artifact (or a tracker, `PROJECT.md`, or status output) cited it, by filename or by an explicit reference. When no reference exists, the last-referenced date is the artifact's own `created` date.
2. **Flag as derived-stale** any promoted artifact whose computed last-referenced date is more than **30 days** before the scan date AND whose `lifecycle_state` is not already `archived` (an already-archived artifact is retired — re-proposing it is a no-op the skill must not produce).
3. **Surface recommend-only**, labeled `[INFERRED]` — never stamp `lifecycle_state: stale`, never auto-transition. The derived flag is paired with `promotion_state: promoted` (the intersection) to form Group 1.

This is the identical >30-day-unreferenced signal the artifact-generator Zombie Detection uses; `generated-cleanup` reuses the signal (recommend-only) rather than minting a new staleness definition.

**Why not read `lifecycle_state: stale` directly.** The enum *containing* a value does not mean any writer *sets* it. Reading `lifecycle_state == stale` returns a value nothing stamps on a promoted artifact, so the group would be inert and the staleness signal silently absent. Derive; do not read.

## Group 1 also surfaces stamped `lifecycle_state: superseded`

Separate from the derived-stale signal, a promoted artifact stamped `lifecycle_state: superseded` is a **real, stamped content-retirement signal** (`frontmatter-schema.md`: `superseded` lifecycle state shifts trust to `historical-record`). Group 1 surfaces those too, routed to the same content-retirement archive path (in place, no folder move). The two Group-1 inputs:

- `promotion_state: promoted` ∧ derived-stale (computed, `[INFERRED]`).
- `promotion_state: promoted` ∧ `lifecycle_state: superseded` (stamped, `[SOURCE]`).

Both are promoted files whose retirement is a content-maturity event — both take the content-retirement path.

## The Group-2 disjointness proof (approaching-timeout vs. the Auto-Archive sweep)

The artifact-generator Auto-Archive Policy automatically and ungated moves files that remain `promotion_state: staged` for more than **10 business days** to `08-Generated/_archived/` (setting `promotion_state: archived-in-place`). Group 2 must NOT duplicate or silently re-gate that sweep.

- **Group 2 population:** `promotion_state: staged` ∧ `lifecycle_changed` **under** the 10-business-day threshold (an early-warning surface).
- **Auto-Archive sweep population:** `promotion_state: staged` ∧ days-since-`lifecycle_changed` **over** the 10-business-day threshold.

The two populations are **disjoint** (under-10-bd vs. over-10-bd, partitioned at the same threshold). The >10-bd population is ceded to the sweep, which stays authoritative. A file the sweep has already claimed is `promotion_state: archived-in-place` (already in `_archived/`) — out of scope for Group 2 entirely. This is why Group 2 is neither dead logic (the sweep does not fire on the under-10-bd population) nor a silent re-gating (the gate applies only to files the sweep has not acted on).

**Out of scope (NOT undertaken here):** making `generated-cleanup` the *gated owner* of the staged-timeout archive (editing the Auto-Archive Policy to defer to it) changes a shipped automatic behavior and needs its own improvement Issue under "No ungoverned changes."

## The archive-action branch (worked, per `promotion_state`)

```
for each candidate:
    if candidate.promotion_state == "staged":
        # LOCATION SWEEP (the only legal source of archived-in-place)
        action = "move to 08-Generated/_archived/; set promotion_state: archived-in-place"
        # legal per artifact-workflow-protocol.md §4.1 (staged → archived-in-place)
    elif candidate.promotion_state == "promoted":
        # CONTENT RETIREMENT (in place — NO folder move)
        action = "set lifecycle_state: archived; set trust_category: historical-record"
        # NO move: artifact-workflow-protocol.md §4.1 has no promoted→archived-in-place;
        # frontmatter-schema.md requires promotion_state: promoted ⇒ folder ≠ 08-generated,
        # so moving it to _archived/ would relocate it backwards into staging.
    # NEVER delete. Both paths recoverable (recover from _archived/; or revert lifecycle_state in place).
```

A Group-3 (superseded) member takes the branch matching **its own** `promotion_state` — a staged superseded member is location-swept; a promoted superseded member is content-retired.

## Graceful degradation

- **No `artifact-lint` report found.** Group 3 (superseded) is reported "none — no artifact-lint report found"; the scan proceeds on Groups 1–2. Never re-derive the lineage graph to fill Group 3 — that is artifact-lint's job, consumed by data contract.
- **A candidate missing `promotion_state`.** `promotion_state` absent ⇒ not-yet-staged / not-applicable — the artifact is not a cleanup candidate (it has no promotion-location to act on); skip-with-note.
- **A candidate missing frontmatter and a sidecar.** Skip-with-note (listed in the proposal's unscannable list), never silently dropped, never invented.
- **A referenced surface absent in the deployed workspace** (a project's `08-Generated/`, a promoted folder, an override file). State the absence and proceed on what is present rather than erroring.

## What a clean scan reports

A scan with no candidates reports "no candidates across all three groups" — the honest no-finding signal — not an empty deliverable and not a fabricated candidate. Each group section is still present, reported "none."

## The conflation boundary (object-class table)

| Tool | Object class | Trigger | What it does |
|---|---|---|---|
| `generated-cleanup` (this skill) | generated **artifacts** (markdown + derivatives) under `08-Generated/` + promoted folders | on-demand `/generated-cleanup` + `/schedule` | proposes archive actions (location sweep / content retirement), operator-gated |
| `cleanup-orphan-state.sh` | orphaned git/runtime **state files** | a different, script-level trigger | removes orphaned state files (hardened for SIGPIPE-at-scale) |

They share the word "cleanup," not a contract. `generated-cleanup` never invokes, names as executor, or routes a recommendation through `cleanup-orphan-state.sh`.

## Sources

- `core/artifact-workflow-protocol.md §4 / §4.1` — the two-concern model + the legal-transition table (no `promoted → archived-in-place`).
- `core/schemas/frontmatter-schema.md` — `lifecycle_state` / `promotion_state` / `lifecycle_changed` / `trust_category` (`historical-record`); the `promotion_state: promoted ⇒ folder ≠ 08-generated` invariant; `archived` requires `historical-record`; `superseded` shifts trust to `historical-record`.
- `operations/skills/artifact-generator/SKILL.md` — the Auto-Archive Policy (the 10-bd staging timeout) + Zombie Detection (the >30-day-unreferenced derivation, recommend-only, no auto-transition).
- `operations/skills/artifact-lint/SKILL.md` § Output — the staged `08-Generated/artifact-lint-YYYY-MM-DD.md` report consumed for Group 3.
- `core/standards/lifecycle-states-canonical.md §3.2` — the deprecation of the legacy single-field workflow machine (no fallback read).
