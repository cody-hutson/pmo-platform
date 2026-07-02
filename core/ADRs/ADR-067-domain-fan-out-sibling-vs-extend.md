<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-067 — Domain-fan-out impact analysis ships as a sibling CLI reproducing the schema-v1 contract via a shared library, not as an in-place extension of blast-radius.sh"
status: Accepted
date: 2026-07-01
release: 80-solutioning-and-engineering-skill-modes
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Decision) + operator at the Collective Review scope-lock"
tags: [release-ops, stage-5, stage-6, solutioning, engineering, blast-radius, impact-analysis, tool-family, scanner-plug, schema-v1, sibling-vs-extend, domain-fan-out, precedent]
source_observations:
  - "Originating gap: the Stage-5 Phase A3.1 domain-aware impact-analysis method (import-graph / component-tree / solution-component-graph fan-out for non-doc domains) was admitted at SPEC level by #345, but every non-doc row read 'Method defined; tool deferred' — no runnable instrument existed. blast-radius.sh is markdown-tree-only (its SCANNED_TYPES carry no language-import model) and has no scanner-plug seam (grep for scanner/plugin/dispatch/domain returns zero hits beyond the SCANNED_TYPES array). #505 is the executable counterpart."
  - "Architecture fork: the executable instrument could EXTEND blast-radius.sh in place (a domain-keyed branch through its scan loop) or ship as a SIBLING CLI reproducing the schema-v1 contract. The extend option entangles the doc-corpus default path — the exact instrument the pipeline's own reflexive Stage-5 A3 depends on — putting a full-corpus regression behind a change that only needs to ADD a non-doc method. The Stage-4 plan pre-recorded the steer: prefer the sibling if Stage-5 design finds the extension entangles the default path."
  - "Schema-reuse-without-co-location cost (Stage-5 A6.5 self-review): a bare sibling DUPLICATES the schema-v1 emitter, so a future schema v1→v2 bump would have to update two emitters or they silently diverge. The refinement folded into the build: extract the emitter into a shared sourced library both tracers consume, so the contract is shared as a LIBRARY, keeping the default binary's behavior byte-identical while removing the two-emitter drift."
---

# ADR-067 — Domain-fan-out impact analysis: sibling CLI + shared schema-v1 library (not an in-place extension)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the Status-enum gate the release-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 per the Stage-6 ADR-authoring precedent established by ADR-062 (substrate-vs-canonical) and its predecessors (core-module-boundary / operations-consume-via-public-api). Stage 5 produced the ADR *spec* (the design decision block in the #505 Stage-5 output); Engineering authored this record and closes the ADR before Stage-6 exit (the ADR-closure gate).

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/` (ADR-066 was the prior max across both directories), resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. This ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this record.

## Context

Stage-5 Phase A3 runs `release/tools/blast-radius.sh`, a doc-corpus inbound-reference tracer (markdown/sh/json/yml/toml path-string fan-out). Phase A3.1 makes the A3 impact-analysis *method* selectable by the deliverable's `domain:` class field: doc/governance keeps the markdown-tree tracer (the unconditional DEFAULT); code/software selects an import-graph fan-out; component/UI a dependency-tree; solution/platform a solution-component graph. The spec-level method was admitted, but for every non-doc domain the Authority cell read "Method defined; tool deferred" — there was no runnable instrument, only a manual opt-out record.

`blast-radius.sh` cannot serve the non-doc domains as written:
- Its `SCANNED_TYPES` are documentation/config file types; it has **no model of a code module's import graph** — it surfaces doc *mentions* of a file path, not the modules that `import` a symbol (the wrong set for code-impact purposes).
- It has **no scanner-plug seam**: a search for `scanner` / `plugin` / `dispatch` / `domain` returns zero hits beyond the `SCANNED_TYPES` array. Adding a domain-keyed branch would be a **fork of the core scan loop**, not a plug into an extension point.

That scan loop is the pipeline's own reflexive Stage-5 A3 instrument — every doc-corpus release runs it. A regression there is a full-corpus blast radius. So the design fork is load-bearing: **extend the default binary in place, or ship the new capability beside it?**

Three candidate architectures were generated and narrowed by hard-constraint elimination (not scoring):

1. **In-place extension** of `blast-radius.sh` — a `domain:`-keyed branch through its scan loop, reusing the emitter directly. **Eliminated (too low / point-fix):** it edits the default binary, so every reflexive doc-corpus A3 executes a modified script; the "extension" is a scan-loop fork (no seam exists) that breaches the regression-isolation constraint the default path makes load-bearing.
2. **A new `operator.toml [adapters]` impact-analysis adapter interface** selected by a config selector. **Eliminated (too high / over-abstraction):** a formal adapter interface + config selector for a single shipped scanner exceeds the change's risk budget; the `[adapters]` seam is for external-host surfaces (repo_host / ticketing / kb / ai_tool), not internal analysis methods — a category mismatch. Warranted only if ≥3 domain scanners ship (YAGNI today).
3. **A sibling CLI** at the tool-family seam (`release/tools/`, the established convention that each fan-out concern is its own allowlisted CLI). **Survivor.**

The Stage-5 A6.5 adversarial self-review then surfaced the sibling's one real cost: a bare sibling **duplicates** the schema-v1 emitter, creating two-emitter drift risk at the next schema version bump. This is the in-place candidate's only genuine advantage (single emitter) — and it is answerable without co-location, by extracting the emitter into a shared library.

## Decision

**Domain-fan-out impact analysis ships as a SIBLING CLI — `release/tools/domain-blast-radius.sh` — that reproduces the schema-v1 output contract via a SHARED LIBRARY, not as an in-place extension of `blast-radius.sh`.** Concretely:

1. **Sibling, not extension.** The new capability is a separate CLI keyed off the `domain:` class field via a `dispatch_scanner()` selector. The doc-corpus default tracer (`blast-radius.sh`) is not forked; its scan loop and behavior are unchanged. This gives the default path a **structural, mechanical no-regression guarantee** (the default binary's control flow is untouched) that an in-place branch could only assert-and-test.

2. **The schema-v1 contract is a shared LIBRARY, not a duplicated block.** The emitter — the `{path, reference_count, matches, is_mirror}` first-order object roll-up and the top-level envelope (`schema_version` / `cli_version` / `stats{…}` / `first_order[]` / `second_order[]` / `filtered_mirrors_detail[]`) — lives in one file, `release/tools/lib/schema-v1-emit.sh`, which BOTH tracers `source`. A schema v1→v2 bump edits that one library, not two divergent emitters. The library functions expose **explicit parameter signatures** (they read no caller globals); each tracer maps its own state onto the parameter list. `blast-radius.sh` is refactored to source the library for its emit — a behavior-preserving change verified byte-identical under a normalized diff.

3. **v1 ships one scanner; the plug-model is visible.** `--domain=software` is implemented (a code import-graph fan-out); `--domain=web` (component-tree) and `--domain=enterprise-platform` (solution-component graph) are honest not-implemented stubs (exit 5, mirroring the § 12 opt-out posture) — the plug-model is visible and the next wave has a named insertion point, with no speculative component/solution logic.

4. **The software domain does NOT over-claim full envelope parity.** The sibling emits the full schema-v1 shape, but three fields carry domain-specific meaning or are deliberately scoped out, documented in the tool header and here:
   - `first_order[].reference_count` is an **import/require/#include STATEMENT count** (a re-export counted once; a comment-only mention is NOT an edge), not the doc tracer's mention-line count.
   - `first_order[].is_mirror` is the **constant `false`** — mirror-pair suppression is a doc-corpus artifact; code imports have no mirror concept.
   - `second_order[].via` / `.depth` and `stats.second_order_count` are **scoped OUT for software v1**: `second_order` is `[]`, `second_order_count` is `0`. Depth-2 import-graph traversal is a named follow-on, not claimed here — the doc tracer populates `via`/`depth`; the software domain intentionally does not.
   - `stats.total_files_scanned` is the **code-file denominator** (the language-scoped candidate set the scanner searched), not the whole-corpus count the doc tracer reports.

   The contract test asserts these **semantics** (the reference_count unit, the is_mirror constant, the second-order scope-out, the code-file denominator), not merely key presence — a shape-identical payload with divergent field meaning would pass a key diff and break a consumer that reasons on meaning.

**Scope-of-precedent (reflexive cutover).** This precedent — the tool-family sibling pattern for a new fan-out concern, and the shared-library home for the schema-v1 contract — applies to future domain-fan-out tooling. The introducing release (this milestone) ships the pattern; it is not retroactively bound by it.

## Alternatives Considered

- **(A) In-place extension of `blast-radius.sh` — REJECTED.** Even a guarded early-return branch edits the default binary, so every doc-corpus A3 (the pipeline's own reflexive run) executes a modified script, and the guard itself is a new failure surface. `blast-radius.sh` has no scanner-plug seam, so the "extension" is a scan-loop fork. The one real advantage (a single emitter, no duplication) is captured instead by the shared library — which keeps the default binary's control flow byte-identical while removing the drift. This is the ADR's opposing view: it lost on default-path entanglement, not on close score.

- **(B) A new `operator.toml [adapters]` impact-analysis adapter interface — REJECTED.** A formal adapter interface + config selector for one shipped scanner is a category-mismatched over-abstraction: the `[adapters]` seam is for external-host surfaces (repo_host / ticketing / kb / ai_tool), not internal analysis methods. It exceeds the change's risk budget (the mirror image of the version-authority over-abstraction rejected in `design-exploration.md`). Warranted only when ≥3 domain scanners ship.

- **(C) A bare sibling with its own duplicated emitter (no shared library) — REJECTED.** This isolates the default path but duplicates the schema-v1 assembly, so a schema v1→v2 bump must update two emitters or they silently diverge — the exact duplicate-source failure the corpus disciplines exist to prevent. The shared library is the minimal answer: contract shared as a library, default binary untouched, one emit home.

- **The selected approach** — sibling CLI + shared `schema-v1-emit.sh` library + one shipped scanner with honest stubs — is the minimal-blast-radius codification: additive files (a new CLI, a new library, a new test) plus a behavior-preserving refactor of the default tracer to source the library, `git revert`-able with no data migration, reusing the established `release/tools/` tool-family convention rather than introducing a new gate or config seam.

## Consequences

**Positive:**
- **The default doc-corpus path carries a structural no-regression guarantee** — its control flow is untouched; the refactor to source the shared library is verified byte-identical under a normalized diff (the three non-deterministic fields deleted on both sides).
- **The schema-v1 contract has one home** (`release/tools/lib/schema-v1-emit.sh`) — a v1→v2 bump edits one file; the two-emitter drift risk is closed. Consumers that pin schema v1 (`design-review-checklist.md` §1/§3, the § 12 opt-out, `mixed-release-solutioning-routing.md` §6 C1) read output from either tracer identically.
- **The Stage-5 A3.1 code/software row now has a runnable counterpart** — the spec method is executable for the software domain; the opt-out record remains the fallback for domains whose scanner is a stub or cannot run.
- **The plug-model is visible with a named insertion point** for the component / solution scanners, without speculative logic.
- **The field-semantics contract is honest** — the software domain does not over-claim second-order or whole-corpus parity; the test asserts meaning, so a consumer cannot silently mis-read a field.

**Negative / costs:**
- A shared library introduces one `source` indirection into `blast-radius.sh` (bounded — the library has explicit signatures and its own no-op-regression test).
- The software scanner is grep-based language-native discovery, not a language toolchain's authoritative dependency graph — it can miss exotic import forms (dynamic imports, aliased re-exports through unusual syntax). The § 12 opt-out remains available when the grep model is insufficient; a toolchain-backed scanner is a future upgrade.
- Second-order for the software domain is deferred, so a consumer needing depth-2 import impact must run the manual trace (§ 12 worked example) until the follow-on ships. Stated explicitly here and in the tool header so the gap is a known scope boundary, not a silent undercount.

## Reversibility

**CHEAP / Confidence HIGH** — the change is additive (a new sibling CLI, a new shared library, a new test, four allowlist entries, an ADR record) plus a behavior-preserving refactor of `blast-radius.sh` to source the library. The refactor is verified byte-identical under a normalized diff, so a `git revert` of the release PR restores the prior inline emitter with no data migration and no consumer impact (the schema contract is unchanged). The reflexive-cutover clause means no prior release is retroactively bound.

## Related ADRs

- **ADR-062** (substrate-vs-canonical precedent) — establishes the Stage-6-ADR-authoring precedent and the role-string `deciders` convention this ADR follows; sibling Stage-5/6 architecture-decision record.
- **ADR-050** (deliverable-domain axis) — establishes the `domain:` class field this tool dispatches on; ADR-067 consumes that axis as the scanner selector.
- **ADR-005** (append-pattern-aware cross-PR contention scoring) — the release-scope ADR whose format this record follows.

### Issue References
Originating executable-counterpart deliverable: #505 (milestone `80-solutioning-and-engineering-skill-modes`). Spec-level method admission it makes runnable: #345 (closed). Epic rollup: #1186. The Stage-5 design that produced this ADR's spec is the #505 Stage-5 Solutioning output.
