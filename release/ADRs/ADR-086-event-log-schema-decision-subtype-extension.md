---
title: "ADR-086 — Event-log schema decision-subtype extension (cascade-sweep-block + session-retro)"
status: Accepted
date: 2026-07-19
release: pipeline-telemetry-tail (v3.80 provisional; bound at Stage 12)
deciders: "Stage 5 Solutioning spoke (design D-3301-A) chose the schema-side fork; operator elected D1 (author an ADR) at the Collective Review scope-lock 2026-07-19; Stage 6 Engineering authored it; operator ratifies at the Stage 9 plan-review gate"
tags: [release-ops, telemetry, event-log, schema-extension, enum, observability, co-owned-surface, ssot, ciac]
source_observations:
  - "The Stage-5 shard codifies a `decision` / `cascade-sweep-block` emission (stage-05-solutioning.md § 11), but the event-log schema's § 3 enum never mirrored the subtype, so append-pipeline-event.sh rejects the exact row the pipeline instructs its agents to emit. Live A/B at Stage 6: unfixed main exits 1 with `Invalid event_subtype`; the fixed branch validates and exits 0."
  - "The same release extends the same schema on a second axis: #2423 adds a net-new top-level `event_type=session-retro` for per-session self-retrospection. Two issues writing one schema file in one release makes the extension surface co-owned, which is what raised it to ADR threshold even though the #3301 change alone sat below it."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-086 — Event-log schema decision-subtype extension (cascade-sweep-block + session-retro)

## Status

Accepted — authored at Stage 6 Engineering; ratified at the operator's Stage 9 plan-review gate of the introducing release. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure; the operator confirmed the ratification explicitly at the decision gate of the release that amended this record.

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

   The static list is a **best-effort degradation path for the unreadable-schema case only**. It **is a verified mirror whenever the schema is readable**: `--self-test` compares the mirror against § 3 member-by-member in **both** directions — a member § 3 admits that the mirror lacks fails, and a member the mirror admits that § 3 lacks fails — so a one-sided edit to either site cannot ship green. When the schema is unreadable the comparison is not evaluable and the self-test reports it as an **explicit SKIP**, never a silent pass; failing closed there would defeat the availability mechanism under test. One limit remains, recorded here rather than asserted away:
   - **The representation question is settled.** The fallback list was originally keyed on rows carrying *literal* subtype tokens, so the `iteration` row — whose subtypes are a **prefix pattern** (`dt-eng-pass-N` / `qa-dt-pass-N`), deliberately validated by starts-with rather than by enum membership — contributed no line at all, and `iteration` dropped out of the fallback's derived event-type list entirely. It now carries a line with an **empty subtype field**, contributing **type membership only**: § 3 admits the type, so a strict mirror admits the type, and `validate_subtype`'s prefix short-circuit fires before the table lookup, so the empty field is never read. Both enum paths now report the same event-type count.
   - **The lockstep is verifiable, not automatically verified.** No CI workflow invokes `append-pipeline-event.sh --self-test`, so the guard is **hand-run**: the mechanism exists and is correct, but nothing fires it on a schedule or at a merge gate. The residual is therefore **invocation**, not verifiability — a materially narrower gap than the unverifiable state this clause originally recorded, and one that closes when the self-test suites are wired into CI. Until then, an author who never runs the self-test can still ship a one-sided edit.

   This decision closes the representation gap and narrows the enforcement gap; it does **not** claim to have automated the invocation. The guarantee is recorded at its true strength so that ratification hardens an accurate statement rather than a false one — the same discipline that motivated this clause's earlier amendment. Wiring the self-test suites into CI is tracked separately in the `### Issue References` block below.
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
- The § 3 ↔ fallback lockstep is a standing two-site obligation, now **assertion-verified whenever the schema is readable** rather than held by authoring convention alone. Any future subtype or event-type addition must still touch both sites in one commit; the fallback is a degradation mirror, never a second source of truth. What changed is the consequence of forgetting: a missed mirror update now fails `--self-test` with a message naming the exact divergent member, instead of staying invisible until the schema file is unreadable. The deferred representation question — whether the prefix-validated `iteration` row should contribute an event-type entry to the fallback — is **answered: yes**, as a line with an empty subtype field, because § 3 already admits the type and the prefix short-circuit makes the empty field unreadable in practice. The one remaining work item is **invocation**: no CI workflow runs the self-test, so the guard must be run by hand until the self-test suites are wired in.
- The `decision` enum grows by one member (19 → 20). No existing row, payload, or read-model changes semantics; no data migration.
- Cutover: the rule in Decision § 5 binds for pipeline events codified after this release's introducing merge SHA. Pre-existing shard-codified events that are absent from § 3 are not retroactively swept by this ADR — if another is found, it is a new intake following the same repair pattern.

## Reversibility

**CHEAP / Confidence HIGH.** The #3301 half is three additive lines (one enum member, one mirror token, one self-test assertion) with no data migration and no behavior change to existing rows; `git revert` of the release PR fully restores the prior state. The #2423 half adds a table row and is independently revertible. The only ordering constraint on a partial revert is the inverse of the build order: reverting #3301 while retaining #2423 is safe, but reverting the schema commit does re-break the codified `cascade-sweep-block` emission — the drift this ADR exists to close.

## Related ADRs

- No superseding or superseded relationship. This is the first ADR to govern the § 3 extension pattern itself; prior schema content was introduced without a dedicated architectural record, which is precisely the gap D1 elected to close before a second co-owner (#2423) touched the file.

## References

- #3301 — event-log schema rejects the codified `cascade-sweep-block` emission (the fork-A repair recorded here).
- #2423 — per-session self-retrospection; adds the net-new top-level `event_type=session-retro` to the same schema (the co-owned half; extends this ADR's pattern rather than superseding it).
- #2645 — reads the schema (telemetry read-models); no write, but bound by CIAC-1's "no read-model requires a subtype absent from § 3."
- #261 — release milestone `pipeline-telemetry-tail`, under which CIAC-1 grades the shared surface at Stage 9.
- #3712 — makes the fallback mirror strict (the `iteration` representation decision recorded in Decision § 2) and makes the `--self-test` lockstep guard bidirectional; the residual this record handed off, now closed.
- #3702 — the remaining residual: no CI workflow invokes the `release/tools` self-test suites, so the lockstep guard is verifiable but hand-run rather than automatically fired.
