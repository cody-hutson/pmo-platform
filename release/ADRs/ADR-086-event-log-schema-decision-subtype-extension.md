---
title: "ADR-086 — Event-log schema decision-subtype extension (cascade-sweep-block + session-retro)"
status: Proposed
date: 2026-07-19
release: pipeline-telemetry-tail (#261) (v3.80 provisional; bound at Stage 12)
deciders: "Stage 5 Solutioning spoke (#3301 design D-3301-A) chose the schema-side fork; operator elected D1 (author an ADR) at the Collective Review scope-lock 2026-07-19; Stage 6 Engineering authored it; operator ratifies at the Stage 9 plan-review gate"
tags: [release-ops, telemetry, event-log, schema-extension, enum, observability, co-owned-surface, ssot, ciac]
source_observations:
  - "The Stage-5 shard codifies a `decision` / `cascade-sweep-block` emission (stage-05-solutioning.md § 11), but the event-log schema's § 3 enum never mirrored the subtype, so append-pipeline-event.sh rejects the exact row the pipeline instructs its agents to emit. Live A/B at Stage 6: unfixed main exits 1 with `Invalid event_subtype`; the fixed branch validates and exits 0."
  - "The same release extends the same schema on a second axis: #2423 adds a net-new top-level `event_type=session-retro` for per-session self-retrospection. Two issues writing one schema file in one release makes the extension surface co-owned, which is what raised it to ADR threshold even though the #3301 change alone sat below it."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-086 — Event-log schema decision-subtype extension (cascade-sweep-block + session-retro)

## Status

Proposed — authored at Stage 6 Engineering; ratified at the operator's Stage 9 plan-review gate. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

`release/references/standards/pipeline-event-log-schema.md` is the declared source of truth for pipeline telemetry events. Its § 3 table enumerates the `event_type` values and, per type, the allowed `event_subtype` members (the table is the count — this record does not restate it, since both extensions below change it); the table carries its own governance rule — "Adding a subtype requires a governance change." `release/tools/append-pipeline-event.sh` validates against that table **data-driven at runtime** (`parse_schema_enum` scans the § 3 section and extracts the backticked tokens from column 3), with a static fallback mirror used only when the schema file is unreadable — a mirror the tool's own comment requires be "kept in lockstep with § 3."

Two independent facts converged in this release.

**First (#3301).** The Stage-5 shard `stage-05-solutioning.md` § 11 codifies a `decision` / `cascade-sweep-block` emission with a distinct payload (`triggers` / `files_swept` / `old_values` / `verdict`), and `core/skills/pmo-qa-auditor/references/cascade-completeness-detection.md` already names that event payload as one of three consumers of a single-source-of-truth swept-set table. But the subtype was never mirrored into § 3. The result is a schema that rejects an emission the pipeline elsewhere instructs its agents to produce. The drift was recorded and deferred once before (`release/releases/plans/v3.65.1_RELEASE_PLAN.md`) and re-verified live as unresolved at Stage 5 of this release.

**Second (#2423).** The same release adds per-session self-retrospection, which introduces a net-new top-level `event_type=session-retro` — a second, structurally different extension to the same file.

The #3301 Stage-5 design, reasoning about #3301 in isolation, concluded the change was below ADR threshold (a reconciliation of a drift to an established precedent) and provisionally recorded that #3301 would be the schema's only writer this release, on the `[ASSUMPTION – CONFIRM]` that #2423 reused the existing substrate with no new schema. The operator's Collective Review decision **D1 supersedes that assumption**: the ADR is scoped to both extensions, which makes `pipeline-event-log-schema.md` a **co-owned write surface** for the release. That co-ownership — not the size of either edit — is what puts the decision at ADR threshold, and it is the reason CIAC-1 grades the shared surface at Stage 9.

## Decision

**The event-log schema is extended in place, additively, on both axes; § 3 remains the single source of truth, read data-driven at runtime, and the tool's static list is maintained as its best-effort degradation mirror.**

1. **`cascade-sweep-block` is added to the § 3 `decision` subtype enum** (fork A, schema-side). This is the functional fix: because the validator parses § 3 at runtime, the enum addition alone makes the rejected emission valid.
2. **The tool's static fallback mirror is updated in the same commit**, in the same relative position. The mirror carries no independent authority — where the two disagree, § 3 wins, because the runtime parse takes precedence whenever the schema file is readable.

   **What is actually guaranteed, stated precisely.** The load-bearing guarantee is the **runtime parse**: whenever `SCHEMA_FILE` is readable — the normal case, including every in-repo and CI invocation — the validator's enum *is* § 3, so § 3 and the enforced enum cannot drift. That is a structural guarantee, not a convention.

   The static list is a **best-effort degradation path for the unreadable-schema case only**, and it is **not a verified mirror**. Two limits are recorded here rather than asserted away:
   - **It is known to diverge today.** The fallback list is keyed on rows carrying *literal* subtype tokens, so the `iteration` row — whose subtypes are a **prefix pattern** (`dt-eng-pass-N` / `qa-dt-pass-N`), deliberately validated by starts-with rather than by enum membership — contributes no line, and `iteration` therefore drops out of the fallback's derived event-type list entirely. Verified by A/B at this ADR's amendment: the same `--event-type iteration` row validates on the schema-driven path (exit 0) and is rejected as `Invalid event_type` on the fallback path (11 types vs § 3's 12).
   - **The lockstep is unenforced.** No CI workflow invokes `append-pipeline-event.sh --self-test`, and the self-test itself reports `enum source=static-fallback` and still **passes** when the schema is unreadable — so it would not surface a divergence even if it were wired. The two-site obligation in Consequences is therefore an **authoring convention** today, not a verified invariant; a future edit that updates § 3 and forgets the mirror ships green.

   This decision does **not** claim to close either gap. It records the guarantee at its true strength so that ratification hardens an accurate statement rather than a false one; closing the enforcement gap (wiring `--self-test` into CI) and the `iteration` divergence are separate work items.
3. **`session-retro` is added as a net-new top-level `event_type` row** by #2423, later in the same release. An enum member inside an existing row and a new table row are structurally disjoint edits, so the two writes do not overwrite one another.
4. **Ordering is load-bearing, not precautionary: #3301 lands first** (Wave A) so that #2423 extends a § 3 that already carries the precedent, and so a single merged schema satisfies CIAC-1.
5. **The extension pattern is the general rule going forward — on the type/subtype axis only.** A new distinct pipeline event belongs in § 3 — as a subtype under an existing `event_type` when it refines one, or as a new `event_type` row when it does not — plus the fallback mirror. It does not belong in a stage shard alone, and it is not to be collapsed into a generic catch-all subtype to avoid a schema change.

   **Scope bound (do not over-read this clause).** § 5 governs the **type/subtype axis** and nothing else. Following it makes an emission's *classification* valid; it does **not** make the emission writable end-to-end, because the payload is validated on a separate axis this ADR does not decide. Concretely: the pipe guard still rejects a multi-value payload notation such as `triggers:[T2|T3]`, so a codified event whose payload uses that form remains unwritable even with its type and subtype correctly mirrored into § 3. Reconciling the § 11 payload notation against the § 4.3 pipe-free constraint is **out of scope here** and is tracked as its own intake — an author following § 5 should expect a valid classification, then verify the payload separately.

### Why fork (A) schema-side, and not (B) re-point the stage shard

The alternative was to leave § 3 untouched and re-point `stage-05-solutioning.md` § 11 at the generic `d-class` subtype. Four grounded reasons decided it:

- **Source-of-truth direction.** The schema self-declares as SSOT and mandates a governed change to add a subtype. The drift is that the SSOT lacks a real, distinct, already-codified audit event — the correct repair completes the SSOT rather than deleting a legitimate telemetry event to match an incomplete one.
- **Queryability.** `cascade-sweep-block` carries a payload no existing `decision` subtype fits. Collapsing it into `d-class` destroys "how many sweeps fired, with what verdict" as an answerable question — directly counter to the thesis of a telemetry release.
- **Blast-radius asymmetry (decisive).** The subtype is already load-bearing beyond § 11: the pmo-qa-auditor cascade-completeness reference names the § 11 `cascade-sweep-block` payload as a consumer. Fork (A) leaves every existing reference valid at the cost of two additive edits; fork (B) would additionally force a reconciliation of that consumer *and* break the established precedent.
- **Established precedent.** The sibling Stage-5 subtype `cross-d-upstream-compat` is codified in **both** `stage-05-solutioning.md` § 11 and schema § 3. `cascade-sweep-block` is the identical shape and was simply never mirrored. Fork (A) restores the existing pattern; fork (B) would fork it.

## Alternatives Considered

- **(B) Re-point `stage-05-solutioning.md` § 11 to the generic `d-class` subtype** — rejected for the four reasons above. It resolves the validation error by removing the signal rather than by recording it, and it leaves a stage-side workaround that a future subtype cannot reuse.
- **(C) Relax the validator to warn-not-reject on unknown subtypes** — rejected: the tool is a correctly-locked control. Loosening enforcement to avoid a governed schema change would let arbitrary undeclared subtypes into the log, destroying the enum's value as a queryable contract and converting a caught error into silent data drift. The governed change is cheap; the enforcement is the asset.
- **(D) Give each stage shard its own subtype namespace** — rejected: it fragments the audit surface across shards, breaks the single-table query model that the § 11 read-models depend on, and would strand the existing pmo-qa-auditor consumer.
- **(E) Split the two extensions across two releases to avoid a co-owned surface** — rejected: the edits are structurally disjoint and CIAC-1 already grades the merged result, so serialization within one release is sufficient. Deferring #2423's row would also defer the capability the release exists to deliver.

## Consequences

- The codified `cascade-sweep-block` emission validates; the pipeline can emit the row it is instructed to emit. Verified at Stage 6 by A/B against unfixed `main` (exit 1 → exit 0) and by `--self-test` PASS reporting `enum source=schema-§3-data-driven`.
- `pipeline-event-log-schema.md` is a **co-owned surface for this release**, so the two writers must stay serialized (#3301 → #2423) and are graded together under CIAC-1 at Stage 9.
- A regression guard now exists for the § 3 parse path: `--self-test` asserts `validate_subtype "decision" "cascade-sweep-block"`, so a future edit that drops the token from § 3 — or breaks the parser that reads it — fails the self-test rather than silently falling back to the static mirror.
- The § 3 ↔ fallback lockstep is a standing two-site obligation **held by authoring convention, not by a gate**. Any future subtype or event-type addition must touch both sites in one commit; the fallback is a degradation mirror, never a second source of truth. Because nothing verifies it (Decision § 2), a missed mirror update is invisible until the schema file is unreadable — and the mirror already carries one known divergence (`iteration`). Wiring `--self-test` into CI, and deciding whether the prefix-validated `iteration` row should contribute an event-type entry to the fallback, are separate work items this ADR deliberately does not fold in.
- The `decision` enum grows by one member (19 → 20). No existing row, payload, or read-model changes semantics; no data migration.
- Cutover: the rule in Decision § 5 binds for pipeline events codified after this release's introducing merge SHA. Pre-existing shard-codified events that are absent from § 3 are not retroactively swept by this ADR — if another is found, it is a new intake following the same repair pattern.

## Reversibility

**CHEAP / Confidence HIGH.** The #3301 half is three additive lines (one enum member, one mirror token, one self-test assertion) with no data migration and no behavior change to existing rows; `git revert` of the release PR fully restores the prior state. The #2423 half adds a table row and is independently revertible. The only ordering constraint on a partial revert is the inverse of the build order: reverting #3301 while retaining #2423 is safe, but reverting the schema commit does re-break the codified `cascade-sweep-block` emission — the drift this ADR exists to close.

## Related ADRs

- No superseding or superseded relationship. This is the first ADR to govern the § 3 extension pattern itself; prior schema content was introduced without a dedicated architectural record, which is precisely the gap D1 elected to close before a second co-owner (#2423) touched the file.

### Issue References

- #3301 — event-log schema rejects the codified `cascade-sweep-block` emission (the fork-A repair recorded here).
- #2423 — per-session self-retrospection; adds the net-new top-level `event_type=session-retro` to the same schema (the co-owned half; extends this ADR's pattern rather than superseding it).
- #2645 — reads the schema (telemetry read-models); no write, but bound by CIAC-1's "no read-model requires a subtype absent from § 3."
- #261 — release milestone `pipeline-telemetry-tail`, under which CIAC-1 grades the shared surface at Stage 9.
