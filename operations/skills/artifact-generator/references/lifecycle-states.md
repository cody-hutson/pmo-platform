# Artifact Lifecycle States

This reference defines the artifact lifecycle that artifact-generator stamps and tracks:
the six lifecycle states, the legal transitions between them, the zombie-detection rule,
and the documentation-debt-register rule. The skill body in `SKILL.md` names this doc from
Step 5 (Stage in 08-Generated/) and from the Artifact Health Check section; read this doc
before stamping any non-default lifecycle state or running a health-check zombie pass.

## The six lifecycle states

Every artifact the skill emits carries a `status:` frontmatter field whose value is the
artifact's lifecycle state, drawn from this closed six-state set:

| State | Meaning | Set by |
|-------|---------|--------|
| `Draft` | Freshly generated and staged in 08-Generated/; not yet reviewed. The on-emit default for every generated and every wrapped artifact. | The skill, at generation time |
| `Review` | Circulated for review; a reviewer is actively reading it before it is accepted. | A human or a downstream review gate |
| `Approved` | Reviewed and accepted as ready; cleared to be promoted out of 08-Generated/ into its target folder. | A human reviewer |
| `Active` | Promoted into its target folder and in use as the current authoritative version of that artifact. | A human or the Promotion Workflow |
| `Superseded` | Replaced by a newer artifact; no longer the current version but not yet retired. | A human or the skill when it emits a replacement |
| `Archived` | Retired; retained for historical reference only. Terminal state. | A human or the auto-archive process |

`Draft` is the exact equivalent of the former `PENDING_REVIEW` staged state — the value
was renamed to fit the lifecycle vocabulary, and every consumer that keyed on a staged
artifact (the Promotion Workflow, the Artifact Health Check scan, the Auto-Archive Policy)
now keys on `status: Draft`.

## Legal transitions

The default forward path runs straight down the set:

```
Draft ──► Review ──► Approved ──► Active ──► Superseded ──► Archived
```

| From | To | Trigger | Authority |
|------|----|---------|-----------|
| (none) | `Draft` | New artifact generated or external artifact wrapped | The skill |
| `Draft` | `Review` | Artifact circulated for review | Human / review gate |
| `Review` | `Approved` | Reviewer accepts the artifact as ready | Human |
| `Approved` | `Active` | Artifact promoted out of 08-Generated/ into its target folder and put into use | Human / Promotion Workflow |
| `Active` | `Superseded` | A newer artifact replaces this one | Human / the skill on replacement |
| `Superseded` | `Archived` | Superseded artifact retired | Human / auto-archive |
| any | `Archived` | Out-of-band retirement (terminal) | Human / auto-archive |

Two off-path edges are legal because review and replacement are not always linear:

| From | To | Trigger | Authority |
|------|----|---------|-----------|
| `Review` | `Draft` | Reviewer sends the artifact back for rework (the REVISE action) | Human |
| `Approved` | `Draft` | An approved-but-not-yet-promoted artifact needs rework before promotion | Human |

Forbidden transitions:

- `Archived` to any state. Archived is terminal; to bring retired content back, generate a
  new artifact rather than resurrecting the archived one.
- Any forward skip that bypasses review. The skill never stamps `Review`, `Approved`,
  `Active`, `Superseded`, or `Archived` at generation time — generation always produces
  `Draft`, and every later state is reached only through a transition a human or a
  downstream gate authorizes.

The skill's responsibility in this machine is narrow and deliberate: it stamps `Draft` on
emit, and it may stamp `Superseded` on an artifact when it generates that artifact's
replacement. Every other transition is a human or governed-process decision; the skill
surfaces the artifact and its state, it does not self-advance the lifecycle.

## Promotion and the lifecycle

Promotion (the move from 08-Generated/ to a target folder, per the Promotion Workflow in
`SKILL.md`) is the `Approved` to `Active` transition. An artifact is eligible for promotion
once it is `Approved`; promotion both moves the file and advances its state to `Active`.
The Auto-Archive Policy's 10-business-day staging timeout sweeps artifacts that are still
`Draft` (never advanced past the on-emit state) out of the staging area — it does not touch
`Active` artifacts that have been promoted.

## Zombie detection — the unreferenced-over-30-days rule

A **zombie artifact** is an artifact that no live artifact references and that has not
itself been referenced for more than **30 days**. Zombie detection is a health-check pass
that flags these artifacts so the operator can reclaim stale documents instead of letting
orphaned artifacts accumulate as governance debt.

The rule:

1. **Last-referenced date.** For each artifact, compute the most recent date on which any
   other tracked artifact, tracker, PROJECT.md, or status output cited it — by filename or
   by an explicit reference. When nothing references the artifact, its last-referenced date
   is its own `created` date.
2. **Zombie flag.** Flag the artifact as a zombie when its last-referenced date is more
   than 30 days before the scan date AND its lifecycle state is not `Archived`. An
   `Archived` artifact is already retired, so an unreferenced `Archived` artifact is
   expected and is not a zombie.
3. **Flag, do not transition.** Zombie detection never changes an artifact's state on its
   own. The operator decides whether a flagged artifact is genuinely orphaned (transition
   it toward `Archived`) or simply quiet-but-current (leave it, or re-reference it). The
   recommended action and its reversibility tier are recorded in the documentation-debt
   register, not applied automatically.

The 30-day threshold is the artifact-skill realization of the platform documentation-debt
anti-pattern (orphaned-artifact accumulation) and aligns with the platform-wide 30-day
source-artifact staleness threshold defined in the health-check specification under the
core specs set.

## Documentation-debt register

The **documentation-debt register** is the named health-check output that lists the
artifacts the operator should action so debt does not silently accumulate. It is produced
or refreshed on every health-check scan and covers two populations:

1. **Zombie artifacts** — unreferenced for more than 30 days (per the zombie-detection rule
   above).
2. **Superseded-not-Archived artifacts** — artifacts whose lifecycle state is `Superseded`
   but that were never transitioned to `Archived`, so a replaced artifact still sits in a
   live state.

An artifact that is both a zombie and superseded-not-archived is listed once, with both
debt signals noted. Each row carries the artifact name, its current lifecycle state, the
debt signal, the days since last reference, the recommended action, and a reversibility
tier paired with a confidence level:

| Artifact | Lifecycle State | Debt Signal | Days Unreferenced | Recommended Action | Reversibility · Confidence |
|----------|-----------------|-------------|-------------------|--------------------|----------------------------|

When the register is empty, report it explicitly as `none (no zombies, no
superseded-not-archived artifacts)` — the honest no-debt signal — rather than omitting it.
The register is itself a generated artifact: it stages in 08-Generated/ with `status:
Draft` like any other output, and it is the operator's worklist, not an automatic
remediation. Every recommended-action row is a decision-class item and must carry its
reversibility tier per the Reversibility Discipline section of `SKILL.md`.

## Relationship to the platform-canonical lifecycle vocabularies

The platform maintains a canonical registry of lifecycle-state vocabularies in the core
standards set (the lifecycle-states-canonical source). That registry already defines an
Artifact Workflow state machine under the object-type prefix `Artifact-`, whose states are
`Artifact-DRAFT`, `Artifact-REVIEWED`, `Artifact-APPROVED`, `Artifact-PROMOTED`, and
`Artifact-ARCHIVED`, carried in an `artifact_state` frontmatter field, with a stated
forward-binding contract that the future implementation use those names verbatim.

The state set in this doc is the skill-level emit-time lifecycle the parent card specified:
the field is `status:`, the values are the Title-case six-state set above, and the on-emit
default is `Draft`. It overlaps the canonical Artifact Workflow on `Draft`/`Approved`/
`Archived`, and it differs from it on the field name (`status` versus `artifact_state`), on
the casing, and on the membership — this set carries `Review`, `Active`, and `Superseded`
where the canonical machine carries `REVIEWED`, `PROMOTED`, and no superseded state.

This divergence is a known ticket-versus-architecture gap, not a silent fork. Reconciling
the two — whether by registering this `status:` set in the canonical registry as a distinct
or aliased machine, or by re-aligning the skill onto the canonical `artifact_state` /
`Artifact-` vocabulary — is a governance decision that belongs to the operator at release
review, and it is flagged there. Until that reconciliation is decided, this doc is the
authoritative source for the `status:` field artifact-generator stamps, and a consumer
reading the `status:` field should resolve its values against this doc.
