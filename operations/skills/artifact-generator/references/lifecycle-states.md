<!-- reference-durability: allow-link -->
# Artifact Lifecycle States — artifact-generator Application Layer

This reference is the **application layer** for how artifact-generator stamps and
health-checks artifact lifecycle states. The **authoritative vocabulary** — the state set,
the legal transitions, and the frontmatter convention — is defined canonically in the
lifecycle-states canonical source at
[`core/standards/lifecycle-states-canonical.md`](../../../../core/standards/lifecycle-states-canonical.md)
§3.2 (Artifact Workflow). This file does **not** restate that state machine; it documents
only what the skill adds on top of it: how it stamps the canonical states on emit, the
zombie-detection pass, and the documentation-debt register. The skill body in `SKILL.md`
names this doc from Step 5 (Stage in 08-Generated/) and from the Artifact Health Check
section; read this doc before stamping any non-default lifecycle state or running a
health-check zombie pass, and read §3.2 of the canonical source for the full state table and
transition rules.

## Canonical vocabulary (summary — §3.2 is authoritative)

artifact-generator adopts the platform-canonical **Artifact Workflow** machine. Its
frontmatter field is **`artifact_state`**, and its value is one of the five canonical
bare-name states; in cross-machine prose the object-typed `Artifact-<STATE>` form is used
per the canonical Object-Typing Convention:

`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`

The skill needs only two facts from the canonical state machine to do its job, both stated
authoritatively in §3.2:

- **`DRAFT` (`Artifact-DRAFT`) is the on-emit default** — a freshly generated or freshly
  wrapped artifact is `Artifact-DRAFT`.
- **`ARCHIVED` (`Artifact-ARCHIVED`) is terminal** — a retired artifact is expected to be
  unreferenced, and `ARCHIVED` is reached only by a governed transition.

For the complete state semantics, the per-state meanings, and every legal transition
(including the `any → ARCHIVED` terminal edge), defer to
[`lifecycle-states-canonical.md`](../../../../core/standards/lifecycle-states-canonical.md)
§3.2 — that section is the single source of truth, and this doc must not diverge from it.

## How the skill stamps the canonical states

The skill's responsibility in this machine is narrow and deliberate:

1. **Stamp `artifact_state: DRAFT` on emit.** Every artifact the skill generates (Generate
   Mode) or wraps (Wrapper Mode) is written to `08-Generated/` with `artifact_state: DRAFT`.
   `Artifact-DRAFT` is the exact equivalent of the former `PENDING_REVIEW` staged state —
   the value was re-specced onto the canonical Artifact Workflow vocabulary, and every
   consumer that keyed on a staged artifact (the Promotion Workflow, the Artifact Health
   Check scan, the Auto-Archive Policy) now keys on `artifact_state: DRAFT`.
2. **Never stamp a later state at generation time.** The skill does not stamp `REVIEWED`,
   `APPROVED`, `PROMOTED`, or `ARCHIVED` on a freshly generated artifact. Every state past
   `DRAFT` is reached only through a transition a human or a downstream gate authorizes (per
   the canonical §3.2 transition table).
3. **Surface, do not self-advance.** The skill stamps the on-emit state and then surfaces the
   artifact and its state; it does not drive the lifecycle forward on its own. Promotion,
   review, and archival are operator- or gate-authorized transitions.

## Original-intent → canonical-state mapping

This skill was first specified with a `status:` field and a six-state Title-case set {Draft,
Review, Approved, Active, Superseded, Archived}. That set collided with the forward-binding
canonical Artifact Workflow. Per operator decision, the skill was re-specced onto the
canonical vocabulary. The intent of each original state maps onto the canonical five as
follows:

| Original state | Canonical state | Mapping rationale |
|---|---|---|
| Draft | `DRAFT` (`Artifact-DRAFT`) | Direct equivalent — the on-emit staged state. |
| Review | `REVIEWED` (`Artifact-REVIEWED`) | Direct equivalent — reviewed by an analytical skill / agent QA gate. |
| Approved | `APPROVED` (`Artifact-APPROVED`) | Direct equivalent — human-approved as ready for downstream consumption. |
| Active | `PROMOTED` (`Artifact-PROMOTED`) | An in-use artifact is one promoted from `08-Generated/` to its target project folder (01-07); the canonical `PROMOTED` state IS that promotion, so "Active = in use in its target folder" maps to `PROMOTED`. |
| Superseded | *(no canonical state)* | The canonical Artifact Workflow carries **no `Superseded` state.** Supersession is represented not as a frontmatter value but as a **documentation-debt signal** — a no-longer-current artifact still in a live (non-`ARCHIVED`) state is flagged for an `ARCHIVED`-transition recommendation in the debt register (see below). |
| Archived | `ARCHIVED` (`Artifact-ARCHIVED`) | Direct equivalent — retired, terminal. |

**Why "Superseded" is a debt signal, not a state.** The canonical §3.2 set is a
forward-binding contract — implementations must use its five state names verbatim, and it
deliberately has no superseded state. Rather than fork the canonical machine to add one, the
skill detects supersession (e.g., when it emits a replacement for an artifact, or when an
artifact is observed to be no longer current) and surfaces it in the documentation-debt
register as work to do: transition the superseded artifact to `Artifact-ARCHIVED`. This keeps
the frontmatter vocabulary aligned with the canonical contract while preserving the original
intent (a replaced artifact must not silently linger as governance debt).

## Promotion and the lifecycle

Promotion — the move from `08-Generated/` to a target folder, per the Promotion Workflow in
`SKILL.md` — is the **`APPROVED` → `PROMOTED`** transition. An artifact is eligible for
promotion once it is `Artifact-APPROVED`; promotion both moves the file and advances its
state to `Artifact-PROMOTED`. The Auto-Archive Policy's 10-business-day staging timeout
sweeps artifacts that are still `Artifact-DRAFT` (never advanced past the on-emit state) out
of the staging area — it does not touch `Artifact-PROMOTED` artifacts that have been promoted.

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
   30 days before the scan date AND its `artifact_state` is not `ARCHIVED`. An
   `Artifact-ARCHIVED` artifact is already retired, so an unreferenced `Artifact-ARCHIVED`
   artifact is expected and is not a zombie.
3. **Flag, do not transition.** Zombie detection never changes an artifact's state on its
   own. The operator decides whether a flagged artifact is genuinely orphaned (transition it
   toward `ARCHIVED`) or simply quiet-but-current (leave it, or re-reference it). The
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
   otherwise no longer current but still sit in a live (non-`ARCHIVED`) state, so a replaced
   artifact was never transitioned to `Artifact-ARCHIVED`. Because the canonical Artifact
   Workflow has no `Superseded` state, this population is detected (not read from a
   frontmatter value) and is actioned as an `ARCHIVED`-transition recommendation.

An artifact that is both a zombie and a no-longer-current-but-live artifact is listed once,
with both debt signals noted. Each row carries the artifact name, its current
`artifact_state`, the debt signal, the days since last reference, the recommended action, and
a reversibility tier paired with a confidence level:

| Artifact | Artifact State | Debt Signal | Days Unreferenced | Recommended Action | Reversibility · Confidence |
|----------|----------------|-------------|-------------------|--------------------|----------------------------|

When the register is empty, report it explicitly as `none (no zombies, no
no-longer-current-but-live artifacts)` — the honest no-debt signal — rather than omitting it.
The register is itself a generated artifact: it stages in `08-Generated/` with
`artifact_state: DRAFT` like any other output, and it is the operator's worklist, not an
automatic remediation. Every recommended-action row is a decision-class item and must carry
its reversibility tier per the Reversibility Discipline section of `SKILL.md`.

## Canonical vocabulary adoption

This skill **adopts the platform-canonical Artifact Workflow** (the `artifact_state` field
and the five states `DRAFT / REVIEWED / APPROVED / PROMOTED / ARCHIVED`) defined at
[`lifecycle-states-canonical.md`](../../../../core/standards/lifecycle-states-canonical.md)
§3.2, per operator decision on the originating card. The earlier divergence — a skill-local
`status:` field with a six-state Title-case set — is **resolved**, not an open
ticket-versus-architecture gap: the field, the casing, and the membership now match the
canonical contract verbatim, and the one state with no canonical equivalent (Superseded) is
expressed through the documentation-debt register rather than as a frontmatter value. This
file is the application layer over §3.2; the canonical source remains the authoritative home
for the vocabulary and the state machine, and this doc defers to it on any point of state
semantics.
