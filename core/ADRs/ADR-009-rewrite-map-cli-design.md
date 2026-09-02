---
title: ADR-009 — Rewrite-map CLI design (--from-path/--to-path mode for check-doc-links.py)
status: Accepted (architectural intent at the module restructure; implementation followed). Rule 2 (V1/V2 workspace-rooted prefix tables driving the resolver's bare-prefix workspace-root fallback) superseded-in-part by ADR-085 — that fallback is retired; the rewrite-map CLI (Rules 1/3/4/5) remains in force.
date: 2026-05-27
deciders: "operator + Stage 5 Solutioning spoke + adversarial review"
superseded_by: ADR-085 in-part (Rule 2)
tags: [architecture, tooling, doc-link-maintenance, check-14-15, emit-only, fail-safe]
source_observations:
  - Stage 5 spec (Check 14/15 + reference inventory tooling extension)
  - Adversarial review — 2 Blocker findings (FM-1 EMIT-ONLY non-enforcement, PR-2 8 vs 14 count contradiction) + 4 Major findings + 5 Minor
  - D-Check15 operator-ratified disposition 2026-05-27: Check 15 RETIRED from v2 deploy.sh; fallback wrapper as an operator-instance optional
---

# ADR-009 — Rewrite-map CLI design

## Status

Accepted as architectural intent at P2-T5 (this ticket commits `check-doc-links.py` byte-identical to source at `core/deploy/tools/`); ADR-009 codifies the Wave E extension strategy. Implementation owned by P2-T8 spoke. Spec authored at Stage 5 sub-task; ADR substance ratified at adversarial review + Collective Review APPROVE WITH OVERRIDES 2026-05-27.

**Superseded in part by [ADR-085](ADR-085-canonical-link-resolution-rule.md)** (canonical markdown link-resolution rule). Rule 2's V1/V2 workspace-rooted prefix tables and the resolver bare-prefix **workspace-root fallback** they drove are **retired**: a bare `core/…` link from a non-root file now reads broken (matching GitHub's rendered-blob behavior), and the leading-`/` form is the sanctioned workspace-rooted anchor. The rewrite-map CLI (Rules 1, 3, 4, 5) is unaffected and remains in force. This record stays unchanged for audit trail; the historical decision follows.

## Context

This release reorganizes the workspace structure such that documentation cross-references move from flat `pmo-platform/reference/*` to module-prefixed `pmo-platform-v2/{core,operations,release}/{disciplines,schemas,standards,specs}/*`. Existing `check-doc-links.py` (at `core/deploy/tools/check-doc-links.py` post-Wave-C) detects broken refs but cannot emit rewrite suggestions. Wave E extends it with `--from-path X --to-path Y` mode that emits a rewrite map (source ref → target ref) for consumption by Wave E path-rewrites + cross-module audit + cleanup tickets.

Per adversarial review:
- **PR-2 (Blocker — count contradiction):** Stage 5 spec Summary claimed "8 paths" while Surface 3 enumerates 14 — internal self-contradiction; resolution: as of that review, 14 patterns is the empirical truth.
- **PR-1 (Major — heterogeneous prefix abstraction):** 4 v1 prefixes + 4 v2 prefixes collapsed into one tuple; the abstraction works but obscures repo-boundary in failure messages.
- **PR-3 (Blocker — EMIT-ONLY non-enforcement):** Spec names file mutation as "Catastrophic" but mitigation is "code review at Stage 6 verifies EMIT-ONLY semantics" — non-structural. Best-practice requires executable test fixture verifying mtime/content-hash unchanged after invocation.
- **FM-2 (Major — prefix-anchor false-positive):** `new_path = to_path + target_path_only[len(from_path):]` works for direct-segment-substitution but FAILS for restructuring renames (e.g., `pmo-platform/reference/explanation/` → `core/disciplines/` drops the `explanation/` segment but string-concat preserves it).
- **D-Check15 operator-ratified:** Check 15 RETIRED from v2 deploy.sh; release-corpus integrity moves to external tool (GitHub Releases per Layer-1 dual-write) OR operator-instance fallback wrapper at P2.5-T1.

## Decision

**`check-doc-links.py` extension at Wave E follows four structural rules:**

### Rule 1: `--from-path X --to-path Y` two-flag CLI (NOT `--rewrite-map` JSON single-flag)

Adopt two-flag interface for the rewrite-map mode. Both flags MUST be provided together (asymmetry → exit 2 with stderr + stdout JSON error per Rule 4).

Rationale (vs adversarial CD-1 JSON single-flag alternative):
- Composable with shell loops at  invocation pattern
- argparse-natural; no JSON parser overhead at consumer
- Test fixture is two strings, not a JSON document

### Rule 2: Prefix-table with v1/v2 separation

Per adversarial PR-1, split the 8-prefix tuple into two named constants:

```python
V1_PREFIXES = (
    "pmo-platform/",
    ".claude/",
    "projects/",
    "memory/",
)
V2_PREFIXES = (
    "pmo-platform-v2/operations/",
    "pmo-platform-v2/release/",
    "pmo-platform-v2/core/",
    "pmo-platform-v2/docs/",
)
ALL_PREFIXES = V1_PREFIXES + V2_PREFIXES  # for resolver loop
```

Resolver logic unchanged (both resolve via `WORKSPACE_ROOT / path`); the split surfaces repo-boundary in failure messages.

### Rule 3: EMIT-ONLY enforced via test fixture (Fixture 6, NEW)

Per adversarial PR-3, EMIT-ONLY promoted from contract to executable test. Add to `run_self_test()`:

```python
def fixture_6_emit_only():
    """Verify scan_file_for_rewrite_map does NOT mutate target files."""
    import hashlib, os
    fixture_dir = "/tmp/check-doc-links-fixture-6"
    fixture_file = f"{fixture_dir}/source.md"
    os.makedirs(fixture_dir, exist_ok=True)
    with open(fixture_file, "w") as f:
        f.write("[link](../disciplines/decision-discipline.md)\n")
    pre_mtime = os.path.getmtime(fixture_file)
    pre_hash = hashlib.sha256(open(fixture_file, "rb").read()).hexdigest()

    scan_file_for_rewrite_map(
        fixture_file,
        from_path="pmo-platform/reference/explanation/",
        to_path="pmo-platform-v2/core/disciplines/",
        emit_format="tsv",
    )

    post_mtime = os.path.getmtime(fixture_file)
    post_hash = hashlib.sha256(open(fixture_file, "rb").read()).hexdigest()
    assert pre_mtime == post_mtime, "EMIT-ONLY violated: mtime changed"
    assert pre_hash == post_hash, "EMIT-ONLY violated: content hash changed"
    return True
```

Composes with existing Fixtures 1-5. Stage 7 DT verifies the assertion fires on regression.

### Rule 4: Asymmetric flag error → exit 2 + stderr AND stdout JSON

Per adversarial FM-3, asymmetric flag error emits:
- stderr: human-readable diagnostic
- stdout (when `--output-format json`): JSON error object `{"error": "asymmetry", "message": "..."}`
- stdout (when `--output-format tsv`): TSV comment line `#ERROR: asymmetry — --from-path and --to-path must be provided together`

Rationale:  batch consumer parses stdout; stderr-only emission is brittle for chained scripts.

### Rule 5: Prefix-anchor asymmetry warning (per FM-2)

Add `--check-rewrite-asymmetry` warning flag (default-enabled). Emits stderr warning when:
- `len(from_path.split("/")) != len(to_path.split("/"))`
- Operator must invoke tool ONCE PER restructuring pair (decompose multi-segment renames into multiple invocations OR accept the warning + manually verify the cascade)

Example trigger:
```
$ check-doc-links.py --from-path "pmo-platform/reference/explanation/" \
    --to-path "pmo-platform-v2/core/disciplines/"
# stderr: WARNING: from-path has 4 segments; to-path has 3 segments.
# Prefix-substitution will produce paths like:
#   pmo-platform-v2/core/disciplines/explanation/<file>
# which may not match the actual v2 layout. Verify cascade manually.
```

## Alternatives Considered

Each structural rule in § Decision states the shape it was chosen over; the alternatives are recorded per rule rather than as one option set.

- **Rule 1 — the CLI shape.** The `--rewrite-map` JSON single-flag interface (adversarial CD-1) was **not taken**; Rule 1 states its own rationale for the two-flag `--from-path` / `--to-path` form: composable with shell loops at the invocation pattern, argparse-natural with no JSON parser overhead at the consumer, and a test fixture that is two strings rather than a JSON document.
- **Rule 2 — the prefix table.** A single collapsed prefix tuple was **not taken**; per the adversarial review the collapsed abstraction works but obscures the repo boundary in failure messages, so the table is split into named V1/V2 constants.
- **The EMIT-ONLY contract.** Relying on Stage-6 code review to hold it was **not taken**; the adversarial review classified that mitigation as non-structural for a failure the spec itself names catastrophic, so an executable fixture asserting mtime and content-hash unchanged replaces it.
- **Asymmetric restructuring renames.** Silent prefix-substitution was **not taken**; because string concatenation preserves a segment a restructuring rename drops, the design adds a default-enabled asymmetry warning rather than guessing the correct cascade.

One adjacent disposition was operator-ratified rather than designed here: Check 15 is **retired** from the v2 deploy surface, with release-corpus integrity moving to an external tool or an operator-instance fallback wrapper, and the integrity-gap window accepted at Collective Review.

## Consequences

1. **Implementation contract:** Wave E spoke implements two-flag CLI + V1/V2 prefix split + Fixture 6 EMIT-ONLY assertion + dual-emission asymmetry error + asymmetry-warning flag. NOT in Wave C scope.

2. **Check 15 retirement (D-Check15 operator-ratified):** v2 deploy.sh removes Check 15 (release-corpus link integrity). Release-time integrity moves to external tool (GitHub Releases per Wave C Surface 1) OR operator-instance fallback wrapper at P2.5-T1 (operator-instance scope; NOT in Wave C). Integrity-gap window: Wave C close → P2.5-T1 ship. Operator accepted at Collective Review.

3. **Consumer pattern:** Wave E invokes `check-doc-links.py --from-path X --to-path Y --target-paths "pmo-platform-v2/<module>/**" --output-format json` per restructuring pair; parses stdout JSON; applies rewrites via separate executor tool (NOT via `check-doc-links.py` itself — EMIT-ONLY contract).

4. **Validation cycle-prevention re-check:** Validation audit re-runs `check-doc-links.py` against `pmo-platform-v2/core/` slice; ≥80 baseline cycle-violations expected per adversarial PR-3; resolved via Wave E rewrites before audit closes.

5. **Bootstrap workflow per D-PerEditTooling:** This ticket uses CURRENT pmo-platform `check-doc-links.py` for pre-edit reference inventory; the v2-extended tool ships at Wave E for post-Wave-E module-aware audit. The bootstrap mechanism prevents circular dependency (Wave C cannot run against pmo-platform-v2 BEFORE pmo-platform-v2 has the tool migrated; Wave C migrates the tool).

## Reversibility

**CHEAP** — CLI additions are non-breaking (existing modes continue to work). Two-flag interface is preserved across operator-instance forks. Fixture 6 is additive to self-test suite.

**Confidence:** HIGH — empirical mtime/content-hash assertion is mechanical and reproducible. Asymmetry-warning flag is informational, not behavior-changing.

## Composition with other ADRs

- ADR-006 (skill map) — supplies the per-module skill scope for v2 target-paths
- ADR-007 (core boundary) — supplies the file-placement boundary; rewrite-map mode operates on the boundary
- ADR-008 (deploy.sh per-module arrays) — sibling Wave E ADR; both fire at Wave E

## Implementation timing

- **Wave C (this ticket):** check-doc-links.py migrated byte-identical to source at `core/deploy/tools/`. ADR-009 codifies the Wave C close intent.
- **Wave E:** Implements Rules 1-5 (CLI extension + Fixture 6 + asymmetry handling).
- **Wave E consumer:** Consumer of `check-doc-links.py --from-path/--to-path` output for cross-module ref rewriting.
- **Validation:** Audits + cleanup re-runs against pmo-platform-v2/core/ slice.
- **P2.5-T1:** Operator-instance fallback wrapper `~/Claude/personal/pmo-instance/tools/check-release-corpus.sh` (optional; replaces retired Check 15).
