<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-101 — FinOps store schema versioning — a conditioned frozen-kind exemption permits a minor bump for a derived-cache field replacement
status: Proposed
date: 2026-07-27
release: agent-finops-intelligence ({{RELEASE_VERSION}})
deciders: "Workspace owner (D-SchemaVersioning rendered at the Stage-4 D-Gate; carried through the Collective Review scope-lock). Design resolved at the joint Stage-5 Solutioning for the store data-minimization and store-dimensions slices."
tags: [architecture, finops, token-spend, schema, versioning, semver, derived-cache, data-minimization, privacy, reversibility]
source_observations:
  - "The FinOps usage store schema states that a breaking change to a frozen record kind takes a MAJOR bump plus a coordination event across pinned consumers, which pin schema_version >= 1.1.0. The store data-minimization slice replaces session.cwd — a field of the frozen v1.0.0 session kind — with session.worktree (its basename only), so read literally the rule forces v2.0.0."
  - "The store is a DERIVED CACHE: a deterministic projection of local session transcripts, rebuildable at any time by extract-usage.sh --rebuild. The change is therefore a rebuild, not a data migration, and no operator data can be lost by it."
  - "The store is git-ignored, operator-local, and unpublished. Its sole in-repo reader of the changed field, rollup-attribution.sh, ships in the same pull request as the change, together with the attribution convention's T1/T3 rule text and every affected fixture. The coordination event the major-bump rule exists to force is therefore internal to that PR and has already occurred by the time the version ships."
  - "The schema's Versioning section as written records NO exemption, so applying one silently would be undocumented divergence from a published contract — the drift the platform's Stability value exists to guard."
---

# ADR-101 — FinOps store schema versioning: a conditioned frozen-kind exemption permits a minor bump for a derived-cache field replacement

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent (ADR-096 / ADR-097 / ADR-031). The decision was rendered by the workspace owner as **D-SchemaVersioning** at the Stage-4 D-Gate and carried through the Collective Review scope-lock. It flips to **Accepted** at this release's Stage-9 plan-review gate; per ADR-098's precedent, the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering.** Authored provisionally as **ADR-099** and renumbered to **ADR-101** at the Stage-9 GO gate, after the number space was recomputed globally across **both** homes (`core/ADRs/` + `release/ADRs/`) **plus in-flight pull-request claims**: `origin/main` had meanwhile taken `ADR-099` (`release/ADRs/ADR-099-mode-r-disposition-set-fit-test.md`) and an open release pull request claims `ADR-100`. `ADR-101` is the next free slot above both. The sibling decision authored in this same release renumbered in lockstep to **[ADR-102](../../release/ADRs/ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md)**. This is the platform's standing **later-claimant-renumbers** convention, forced by the gap-free CI gate (`release/tools/check-adr-numbers.py`); the renumber is recorded here rather than silently applied.

## Context

`core/schemas/finops-usage-store-schema.md` § Versioning states that an additive change is a minor bump, while **a breaking change to a frozen record kind is a major bump plus a coordination event** across the downstream consumers, which pin `schema_version >= 1.1.0`.

The store data-minimization slice replaces `session.cwd` — a field of the **frozen v1.0.0 `session` kind** — with `session.worktree`, its basename only. The motivation is data-minimization: the resolver consumes only `basename(cwd)`, so the absolute-path prefix is written to the store but never read back. Persisting it retains environment path detail with no functional use, an avoidable identifying surface on a store whose whole safety posture is "never let this reach the public repo".

Read literally, the rule forces **v2.0.0**, and then a second bump to v2.1.0 for the additive sub-aggregates shipping alongside. That is two bumps and a three-site re-pin for **zero safety gain**, because the property the major-bump rule protects — an unprepared consumer reading a field whose meaning silently changed — cannot occur here:

- the store is a **derived cache**, deterministically rebuildable from source, so the change is a rebuild rather than a data migration and no operator data can be lost;
- the store is **git-ignored, operator-local, and unpublished**, so there is no external or third-party consumer to coordinate with;
- the **sole in-repo reader** of the changed field ships in the **same pull request** as the change.

But the rule as written records **no exemption**. Applying one silently would be undocumented divergence from a published contract — strictly worse than either following the rule or amending it, because the next author cannot tell which rule is live.

A second, independent consequence surfaced during design and belongs on this record. Through v1.1.0 the version number doubled as a **phase marker**: extraction alone wrote `1.0.0` and a roll-up pass bumped it to `1.1.0`, so a consumer pinning `>= 1.1.0` was implicitly guaranteed the store held `rollup` records. This change alters the **extraction phase's own record shape**, so an extraction-only store is no longer v1.0.0-conformant and must report `1.2.0`. There is no semver that expresses "v1.2.0 session shape, no rollup kinds" — the option space is **forced, not chosen** — and the implicit guarantee is therefore retired.

## Decision

1. **One minor bump to v1.2.0**, carrying both the frozen-kind field replacement and the additive sub-aggregates that ship with it, recorded in **exactly one** Version-History row.

2. **Amend the schema's own § Versioning section** with a **conditioned frozen-kind exemption** naming three **conjunctive, individually falsifiable** conditions, all of which must hold at the time of the change:

   - **(i) Derived-cache condition** — the store is a derived cache, deterministically rebuildable from source by `extract-usage.sh --rebuild`, so the change is a rebuild rather than a data migration and no operator data can be lost by it.
   - **(ii) No-external-consumer condition** — no consumer outside this repository's tracked corpus reads the changed field. *If any external or unknown consumer reads it, this condition fails.*
   - **(iii) Same-PR condition** — every in-repo consumer of the changed field is updated in the same pull request, so the coordination event the major-bump rule exists to force is internal to that PR.

   **If any condition fails — in particular if a live consumer reads the changed field outside the same PR — the change takes the major bump and the coordination event, unchanged.**

3. **The exemption is claimed per change, never standing.** The Version-History row for that version must name it, and the rationale must be recorded in an ADR. A later frozen-kind change re-tests all three conditions from scratch. The amendment carries an explicit anti-erosion sentence — *"nothing here makes minor bumps the default for frozen-kind changes"* — because the failure mode of a conditioned exemption is being read as a general licence one release later.

4. **The exemption's scope is exactly one field replacement, not the release.** Additive fields on a frozen kind are confirmed **not** breaking, on the schema's own v1.1.0 precedent (`session.branch_switch` / `session.git_branches` were added to the frozen `session` kind as a minor bump). Stating that scope explicitly is what keeps the exemption narrow.

5. **The version number stops encoding which phase has run.** Both phases emit `meta.schema_version = "1.2.0"`. The retired guarantee is **replaced, not dropped**: the canonical "a roll-up has run" predicate is the presence of the mandatory run-level record, `any(.record == "coverage")` (exactly one per roll-up run, always emitted). Consumers MUST gate on that predicate, never on `schema_version` alone. This is written into the schema in two places and binds the in-PR consumers.

6. **A runtime enforcement backs condition (i) rather than assuming it.** A **store-shape preflight** in the roll-up refuses a pre-v1.2.0 on-disk store with **exit 3** naming the rebuild command. Without it, upgraded code against an operator's existing store yields exit 0, an empty roll-up, and a `coverage` record certifying `health: OK` / 100 % attributed while every session's spend vanishes — a fail-open in the honesty instrument. Condition (i)'s "rebuild, not migration" is thereby enforced at runtime rather than trusted.

## Alternatives Considered

- **(A) Follow the rule literally — v2.0.0, then v2.1.0.** Two bumps, a three-site re-pin, and a formal coordination event with the same team inside the same PR. **Rejected:** cost with no safety return, and it teaches that the rule is satisfied by paperwork rather than by reasoning.
- **(B) Additive-only — add `worktree`, retain `cwd`.** No frozen-kind change at all, so no exemption needed. **Rejected:** it defeats the change's entire purpose. The acceptance criterion is that *no absolute working-directory path appears in any record*; retaining `cwd` keeps precisely the identifying surface being removed.
- **(C) Silent minor bump, no written exemption.** **Rejected:** this is the drift the Stability value guards. A published rule broken without record is worse than either following it or amending it, because the next author cannot tell which rule is live.
- **(D) Delete the frozen-kind→major rule entirely.** **Rejected:** the rule is load-bearing for a published schema. The problem is a missing exemption, not a wrong rule.
- **Selected: a conditioned, recorded exemption** — minimal, falsifiable, and self-limiting.

## Consequences

- **Positive.** One bump, one Version-History row, three pin sites re-pinned once. The rule becomes a queryable artifact a future spoke cites instead of re-deriving the same reasoning. The next frozen-kind change **with** a live consumer still takes the major bump, because condition (iii) fails for it — the exemption is written so that the expensive path remains the default for the case that actually warrants it.
- **Negative.** A conditioned exemption is a **judgment surface**: a future author could argue the conditions hold when they do not. That is why each condition is stated as an individually falsifiable predicate rather than a rationale, why the applied instance is recorded with per-condition evidence, and why the anti-erosion sentence is explicit.
- **Negative (second-order).** The version number stops encoding which phase has run, so consumers must gate on the `coverage` record. This is recorded in the schema and binds the in-PR consumers; a consumer that keeps gating on `schema_version` alone will read an extraction-only store as if it had rollup rows. The preflight does not catch that class — it is a consumer-side contract, enforced by review.
- **Bounded residual.** The exemption is claimed once, at v1.2.0. Its correct application at any future version is not guaranteed by this ADR — only made auditable by it.

## Reversibility

**MODERATE / Confidence MEDIUM.**

Version identity propagates into the emitted store, the Version History, and the consumer pin sites. Pre-merge, reversal is deleting the branch, with zero residue. Post-merge, reversal is a `git revert -m 1` of the release merge plus one `extract-usage.sh --rebuild` to resolve the on-disk field skew — **no data migration**, because the store is a derived cache and was never the source of truth. The revert instruction should also note the **reverse skew**: reverted code emitting `cwd` against a `worktree`-carrying store on disk. `--rebuild` is the default mode and resolves it; the new preflight makes only the *forward* skew loud.

**MEDIUM** confidence reflects that this is a judgment call on a governed rule rather than a mechanical rule application. If the operator prefers strictness, alternative (A) remains available and is merely more expensive — nothing here forecloses it.

## Related ADRs

- **ADR-096** — FinOps usage store, data home and schema authority. It **states the major-bump rule this ADR exempts**, and establishes the derived-cache posture condition (i) rests on.
- **ADR-097** — FinOps usage attribution convention. It **owns the T1/T3 rule text** restated against `session.worktree` by the change this ADR governs.
- **ADR-062** — substrate-vs-canonical. Why the originating issue bodies are not amended to match the design: they stand as historical record.
- **ADR-031** — the Stage-6 ADR-authoring precedent both FinOps ADRs follow.
