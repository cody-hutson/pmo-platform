<!-- reference-durability: allow-link -->
# Artifact Lifecycle States — artifact-generator Application Layer

This reference is the **application layer** for how artifact-generator stamps and
health-checks artifact lifecycle states. A generated artifact carries **two orthogonal state
fields**: `lifecycle_state` (content-maturity, Domain C) and `promotion_state`
(promotion-location). The **authoritative vocabularies** and the operational protocol — the
two-concern model, the legal transitions, the `promotion_state` field, and the deprecation of
the legacy single-field Artifact Workflow machine — are defined canonically in
[`core/artifact-workflow-protocol.md`](../../../../core/artifact-workflow-protocol.md) (the
operational-protocol home), with the content-maturity vocabulary at
[`core/schemas/frontmatter-schema.md`](../../../../core/schemas/frontmatter-schema.md) § Category 2
and the promotion-location field at the same schema's § Domain C. The `Artifact-<STATE>`
object-typed naming convention for cross-machine prose lives at
[`core/standards/lifecycle-states-canonical.md`](../../../../core/standards/lifecycle-states-canonical.md)
§3.2. This file does **not** restate those state machines; it documents only what the skill
adds on top of them: how it stamps the entry states on emit, the zombie-detection pass, and
the documentation-debt register. The skill body in `SKILL.md` names this doc from Step 5
(Stage in 08-Generated/) and from the Artifact Health Check section; read this doc before
stamping any non-default state or running a health-check zombie pass, and read
`core/artifact-workflow-protocol.md` for the full two-concern model and transition rules.

## Canonical vocabulary (summary — the reconciled model is authoritative)

artifact-generator stamps **two orthogonal fields** on a generated artifact:

- **`lifecycle_state`** — content-maturity (Domain C): `draft → validated → published → stale
  → archived`. Defined at `core/schemas/frontmatter-schema.md` § Category 2 and
  `release/references/how-to/domain-c-lifecycle-protocol.md`. (The legacy `REVIEWED` / `APPROVED`
  content states reuse the existing `approval_state` field — `under-review` / `approved` — per
  the 3-way mapping below; no third maturity field is minted.)
- **`promotion_state`** — promotion-location: `staged → promoted → archived-in-place`. Defined
  at `core/schemas/frontmatter-schema.md` § Domain C and `core/artifact-workflow-protocol.md` §4.

In cross-machine prose the object-typed `Artifact-<STATE>` form is used per the canonical
Object-Typing Convention (`lifecycle-states-canonical.md` §2). The legacy single-field Artifact
Workflow machine (`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`) is **deprecated** (see
`core/artifact-workflow-protocol.md` §5): it conflated content-maturity and promotion-location
onto one field, and those concerns are split across the two fields above (the artifact-state RCA).

The skill needs only two facts from these machines to do its job:

- **`lifecycle_state: draft` + `promotion_state: staged` are the on-emit defaults** — a freshly
  generated or freshly wrapped artifact is `Artifact-DRAFT` content, staged in `08-Generated/`.
- **`lifecycle_state: archived` is the content terminal** — a retired artifact is expected to be
  unreferenced, and `archived` is reached only by a governed transition. (The `08-Generated/`
  staging-sweep terminal is the separate `promotion_state: archived-in-place`.)

For the complete state semantics, the per-state meanings, the two-concern model, and every
legal transition, defer to
[`core/artifact-workflow-protocol.md`](../../../../core/artifact-workflow-protocol.md) — that
doc is the operational source of truth, and this doc must not diverge from it.

## How the skill stamps the canonical states

The skill's responsibility in this machine is narrow and deliberate:

1. **Stamp `lifecycle_state: draft` + `promotion_state: staged` on emit.** Every artifact the
   skill generates (Generate Mode) or wraps (Wrapper Mode) is written to `08-Generated/` with
   `lifecycle_state: draft` (content entry) + `promotion_state: staged` (location). This pair is
   the exact equivalent of the former `PENDING_REVIEW` staged state — re-specced onto the
   reconciled two-field model — and every consumer that keyed on a staged artifact (the
   Promotion Workflow, the Artifact Health Check scan, the Auto-Archive Policy) now keys on
   `promotion_state: staged` (staging is a location fact).
2. **Never self-advance either field at generation time.** The skill does not advance
   `lifecycle_state` past `draft` (to `validated` / `published` / `archived`, or the
   `approval_state` signals `under-review` / `approved`) or `promotion_state` past `staged` (to
   `promoted` / `archived-in-place`) on a freshly generated artifact. Every later state is
   reached only through a transition a human or a downstream gate authorizes (per the
   `core/artifact-workflow-protocol.md` transition tables).
3. **Surface, do not self-advance.** The skill stamps the on-emit state and then surfaces the
   artifact and its state; it does not drive the lifecycle forward on its own. Promotion,
   review, and archival are operator- or gate-authorized transitions.

## Original-intent → canonical-state mapping

This skill was first specified with a `status:` field and a six-state Title-case set {Draft,
Review, Approved, Active, Superseded, Archived}. That set collided with the forward-binding
canonical vocabulary. Per operator decision, the skill was re-specced — and, per the
artifact-state RCA, the conflated single field is now **split across the two orthogonal fields**
(`lifecycle_state` for content-maturity, `promotion_state` for promotion-location). The intent
of each original state maps onto the reconciled model as follows:

| Original state | Reconciled field/value | Mapping rationale |
|---|---|---|
| Draft | `lifecycle_state: draft` + `promotion_state: staged` (`Artifact-DRAFT`) | Direct equivalent — the on-emit content entry, staged in `08-Generated/`. |
| Review | `approval_state: under-review` (`Artifact-REVIEWED`) | Reviewed by an analytical skill / agent QA gate — the approval signal, on the existing `approval_state` field (no third maturity field minted). |
| Approved | `approval_state: approved` (`Artifact-APPROVED`) | Human-approved as ready for downstream consumption — the approval signal on `approval_state`. |
| Active | `promotion_state: promoted` (`Artifact-PROMOTED`) | **This row IS the carve made concrete.** An in-use artifact is one promoted from `08-Generated/` to its target project folder (01-07); promotion is a **location** fact, not a content state, so "Active = in use in its target folder" maps to `promotion_state: promoted`. Content-maturity (`lifecycle_state`) is independent — a promoted file is equally `published` before and after the move. |
| Superseded | *(no state value — a debt signal)* | Neither machine carries a `Superseded` state. Supersession is represented not as a frontmatter value but as a **documentation-debt signal** — a no-longer-current artifact still in a live (non-archived) `lifecycle_state` is flagged for a `lifecycle_state: archived`-transition recommendation in the debt register (see below). |
| Archived | `lifecycle_state: archived` (`Artifact-ARCHIVED`) | Content terminal — retired. (Distinct from the staging-sweep location terminal `promotion_state: archived-in-place`.) |

**Why "Superseded" is a debt signal, not a state.** The reconciled content machine
(`draft → validated → published → stale → archived`) deliberately has no superseded state.
Rather than fork the machine to add one, the skill detects supersession (e.g., when it emits a
replacement for an artifact, or when an artifact is observed to be no longer current) and
surfaces it in the documentation-debt register as work to do: transition the superseded
artifact to `lifecycle_state: archived` (`Artifact-ARCHIVED`). This keeps the frontmatter
vocabulary aligned with the canonical content machine while preserving the original intent (a
replaced artifact must not silently linger as governance debt).

## Promotion and the lifecycle

Promotion — the move from `08-Generated/` to a target folder, per the Promotion Workflow in
`SKILL.md` — is the **`promotion_state: staged → promoted`** transition (the physical move).
Content-maturity is independent: a `published` artifact may still be `staged`, and promotion
sets `promotion_state: promoted` without changing `lifecycle_state`. The Auto-Archive Policy's
10-business-day staging timeout sweeps artifacts that are still `promotion_state: staged` (never
moved out of the staging area), setting `promotion_state: archived-in-place` — it does not touch
`promotion_state: promoted` artifacts that have already been promoted.

## Zombie detection — the unreferenced-over-30-days rule

A **zombie artifact** is an artifact that no live artifact references and that has not itself
been referenced for more than **30 days**. Zombie detection is a health-check pass that flags
these artifacts so the operator can reclaim stale documents instead of letting orphaned
artifacts accumulate as governance debt.

The rule:

1. **Last-referenced date.** For each artifact, compute the most recent date on which any
   other tracked artifact, tracker, PROJECT.md, or status output cited it — by filename or
   by an explicit reference. When nothing references the artifact, its last-referenced date
   is its own `created` date.
2. **Zombie flag.** Flag the artifact as a zombie when its last-referenced date is more than
   30 days before the scan date AND its `lifecycle_state` is not `archived`. An
   `Artifact-ARCHIVED` artifact is already retired, so an unreferenced `Artifact-ARCHIVED`
   artifact is expected and is not a zombie. (Zombie detection keys on content-retirement —
   `lifecycle_state` — not on promotion-location.)
3. **Flag, do not transition.** Zombie detection never changes an artifact's state on its
   own. The operator decides whether a flagged artifact is genuinely orphaned (transition it
   toward `lifecycle_state: archived`) or simply quiet-but-current (leave it, or re-reference it). The
   recommended action and its reversibility tier are recorded in the documentation-debt
   register, not applied automatically.

The 30-day threshold is the artifact-skill realization of the platform documentation-debt
anti-pattern (orphaned-artifact accumulation) and aligns with the platform-wide 30-day
source-artifact staleness threshold defined in the health-check specification under the core
specs set.

## Documentation-debt register

The **documentation-debt register** is the named health-check output that lists the artifacts
the operator should action so debt does not silently accumulate. It is produced or refreshed
on every health-check scan and covers two populations:

1. **Zombie artifacts** — unreferenced for more than 30 days (per the zombie-detection rule
   above).
2. **No-longer-current-but-live artifacts** — artifacts that have been superseded or are
   otherwise no longer current but still sit in a live (non-archived) `lifecycle_state`, so a
   replaced artifact was never transitioned to `Artifact-ARCHIVED` (`lifecycle_state: archived`).
   Because the Domain-C content machine has no `Superseded` state, this population is detected
   (not read from a frontmatter value) and is actioned as a `lifecycle_state: archived`-transition
   recommendation.

An artifact that is both a zombie and a no-longer-current-but-live artifact is listed once,
with both debt signals noted. Each row carries the artifact name, its current
`lifecycle_state` (content-maturity), the debt signal, the days since last reference, the
recommended action, and a reversibility tier paired with a confidence level:

| Artifact | Lifecycle State | Debt Signal | Days Unreferenced | Recommended Action | Reversibility · Confidence |
|----------|-----------------|-------------|-------------------|--------------------|----------------------------|

When the register is empty, report it explicitly as `none (no zombies, no
no-longer-current-but-live artifacts)` — the honest no-debt signal — rather than omitting it.
The register is itself a generated artifact: it stages in `08-Generated/` with
`lifecycle_state: draft` + `promotion_state: staged` like any other output, and it is the
operator's worklist, not an automatic remediation. Every recommended-action row is a
decision-class item and must carry its reversibility tier per the Reversibility Discipline
section of `SKILL.md`.

## Canonical vocabulary adoption

This skill **adopts the reconciled two-field model** — `lifecycle_state` (content-maturity,
Domain C) + `promotion_state` (promotion-location) — defined operationally at
[`core/artifact-workflow-protocol.md`](../../../../core/artifact-workflow-protocol.md), with the
content-maturity vocabulary at `core/schemas/frontmatter-schema.md` § Category 2, the
promotion-location field at the same schema's § Domain C, and the `Artifact-<STATE>` naming
convention at [`lifecycle-states-canonical.md`](../../../../core/standards/lifecycle-states-canonical.md)
§3.2. The legacy single-field Artifact Workflow machine that conflated those two concerns is
**deprecated** (the artifact-state RCA; see the protocol §5). The earlier divergence — a skill-local
`status:` field with a six-state Title-case set — is **resolved**, not an open
ticket-versus-architecture gap: the fields, the casing, and the membership now match the
reconciled canonical model, and the one state with no value equivalent (Superseded) is
expressed through the documentation-debt register rather than as a frontmatter value. This
file is the application layer over the reconciled model; the canonical sources above remain the
authoritative homes for the vocabularies and the two-concern protocol, and this doc defers to
them on any point of state semantics.
