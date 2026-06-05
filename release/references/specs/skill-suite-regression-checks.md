# Regression Checks — PMO Skill Suite

## Purpose

Per-skill behavioral regression baseline. Each entry declares an invocation test, a non-invocation test, a smoke output assertion, and a reference to the last-known-good benchmark.

This file complements pmo-qa-auditor's G-series gates: G-gates audit skill outputs against contracts (per-skill-output-contracts.md); regression-checks.md audits skill behavior against its own prior-version baselines.

## Entry format

```markdown
### <skill-name>
- **Invocation test:** <phrase that must trigger the skill>
- **Non-invocation test:** <phrase that must NOT trigger the skill>
- **Smoke output assertion:** <one-liner describing minimal valid output shape>
- **Regression iteration reference:** `release/skills/<skill>-workspace/iteration-<N>/benchmark.json`
```

## Maintenance

Populated by `pmo-skill-refiner`:
- Create-New workflow step 7 appends a new entry per newly-created skill.
- Refine-Existing workflow step 7 updates the `regression_iteration_reference` field + any changed invocation/assertion fields when a refinement alters the skill's behavior.

Pure description-optimization or eval-harness-only changes do NOT update this file — those are iteration-level adjustments without behavioral delta.

First-time creation: this file was created as the pmo-skill-refiner workflow executed step 7 for the canary skill. Future refiner invocations append to this file rather than create.

## Entries

### pmo-skill-refiner-selftest-canary
- **Invocation test:** "check the skill roster"
- **Non-invocation test:** "does prompt-builder have a .skill package" (keyword-overlap near-miss; routes to pmo-skill-editor or direct filesystem check, not the canary)
- **Smoke output assertion:** Output produces a paragraph with the word "skill directories" followed by a table containing at least one "Status: OK" row (positive case) OR at least one "Status: Folder Only / SKILL_LIST Only" row (drift case)
- **Regression iteration reference:** none currently; first operational baseline will be created at `release/skills/pmo-skill-refiner-selftest-canary-workspace/iteration-1/benchmark.json` per the canonical skill-workspace convention (see `standards/skill-workspace-location.md`). Demo-phase artifacts in the dated demo analysis directory were removed by commit 6bc8517 on 2026-05-02 (superseded; preserved in git history).
