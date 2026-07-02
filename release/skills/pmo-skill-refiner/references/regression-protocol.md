# Regression Protocol

## Usage

Defines how creating or modifying a PMO skill extends platform-level regression checks so new skills have an always-on behavioral baseline. The refiner automates this as step 7 in Create-New workflow and step 7 in Refine-Existing workflow — no manual intervention required.

---

## What is `regression-checks.md`?

A top-level regression check registry at `release/references/specs/skill-suite-regression-checks.md`. One entry per skill, declaring:

- An invocation test (phrase that must trigger the skill)
- A non-invocation test (phrase that must NOT trigger the skill)
- A smoke output assertion (one-liner describing minimal valid output shape)
- A reference to the latest-known-good benchmark (regression iteration baseline)

This file is the **behavioral regression layer** that complements pmo-qa-auditor's G-series gates. G-gates audit skill outputs for compliance with contracts; regression-checks.md audits skill behavior against its own prior-version baseline.

**Create-if-missing:** If `release/references/specs/skill-suite-regression-checks.md` does not yet exist on main when the refiner runs, the refiner creates it with a stub explaining the purpose before appending the first entry. The stub's shape is defined below.

---

## When the refiner extends it

| Workflow | Step | Trigger |
|---|---|---|
| Create-New | 7 | Any new skill creation produces a new entry |
| Refine-Existing | 7 | Any refinement that changes the skill's output contract, adds a mode, or alters decision-class behavior |

The refiner does NOT extend for:
- Pure description-optimization passes that don't alter the skill's output shape (the description text changed; behavior did not).
- Pure eval-harness changes with no skill-behavior delta (e.g., adding new assertions to evals.json).

These cases produce a new `iteration-<N>/` workspace folder but do not update the regression-checks.md entry.

---

## Entry format

Each entry is a third-level heading followed by 4 fields:

```markdown
### {{skill-name}}
- **Invocation test:** {{phrase that must trigger the skill}}
- **Non-invocation test:** {{phrase that must NOT trigger the skill — should route elsewhere or resolve without a skill}}
- **Smoke output assertion:** {{one-liner describing minimal valid output shape}}
- **Regression iteration reference:** `release/skills/{{skill}}-workspace/iteration-{{latest}}/benchmark.json` (last-known-good baseline)
```

**Field guidance:**

- **Invocation test** — should be from the 8–10 should-trigger queries used during description-trigger optimization. Pick the one with the highest measured trigger rate.
- **Non-invocation test** — should be a near-miss from the 8–10 should-not-trigger queries. Pick the one that shares the most keywords with the skill's domain but routes elsewhere. Easy distinguishers (pure off-topic queries) do not test the description boundary.
- **Smoke output assertion** — must be verifiable without running the full eval harness. Examples: "outputs a 7-section report with § Executive Narrative first", "produces ≥ 1 [SOURCE]-labeled claim", "contains at least one RAID prefix R-XYZ-001 or higher". Avoid subjective smoke assertions ("outputs are good").
- **Regression iteration reference** — path to the `benchmark.json` file from the iteration that the skill shipped at. This is the baseline against which future regressions are measured.

---

## Auto-update protocol

The refiner runs this as a literal Edit tool call after the refined SKILL.md lands. No manual intervention.

For a new skill (Create-New workflow step 7):
1. Derive invocation_test from Interview Q2 (highest-trigger-rate phrasing).
2. Derive non_invocation_test from the description-trigger optimization eval set (highest-keyword-overlap near-miss).
3. Derive smoke_output_assertion from Interview Q7 (Output Contract schema source).
4. Derive iteration_reference from the Create-New workflow step 5 benchmark.json path.
5. Edit-append the entry to `release/references/specs/skill-suite-regression-checks.md`.

For an existing skill (Refine-Existing workflow step 7):
1. Read the current `### <skill-name>` entry from regression-checks.md.
2. Update `regression_iteration_reference` to the latest workspace iteration.
3. Update `invocation_test` / `non_invocation_test` / `smoke_output_assertion` only if the refinement changed them (e.g., description optimization moved the highest-trigger-rate phrasing).
4. Edit-replace the entry in place.

---

## Stub shape (when file does not yet exist)

If `release/references/specs/skill-suite-regression-checks.md` does not exist on main when the refiner runs, create with:

```markdown
# Regression Checks — PMO Skill Suite

## Purpose

Per-skill behavioral regression baseline. Each entry declares an invocation test, a non-invocation test, a smoke output assertion, and a reference to the last-known-good benchmark.

This file complements pmo-qa-auditor's G-series gates: G-gates audit skill outputs against contracts; regression-checks.md audits skill behavior against prior-version baselines.

## Entry format

### <skill-name>
- **Invocation test:** <phrase that must trigger the skill>
- **Non-invocation test:** <phrase that must NOT trigger the skill>
- **Smoke output assertion:** <one-liner describing minimal valid output shape>
- **Regression iteration reference:** `release/skills/<skill>-workspace/iteration-<N>/benchmark.json`

## Entries

(Populated by pmo-skill-refiner Create-New workflow step 7 and Refine-Existing workflow step 7.)
```

---

## Relationship to pmo-qa-auditor

| Layer | Gate | Audits |
|---|---|---|
| Platform contracts | pmo-qa-auditor G1–G8 | Skill outputs against documented contracts (per-skill-output-contracts.md), evidence labels, reversibility tiers, failure-mode structure, etc. |
| Behavioral baseline | regression-checks.md (this file) | Skill behavior against its own prior-version baseline |

Complementary, not redundant. G-gates catch contract drift (output missing required section); regression-checks.md catches behavioral drift (skill stops triggering on what it used to trigger on, or starts triggering on what it shouldn't).

The refiner populates both in coordination:
- Workflow step 8 → registers per-skill-output-contracts.md (G1–G8 surface)
- Workflow step 7 → registers regression-checks.md (behavioral surface)

## Relationship to the mirror-sync check in deploy.sh --check

`deploy.sh --check` validates skill sync, package sync, duplicate detection, governance presence, and rules mirror sync. The mirror-sync check adds regression-checks.md presence verification — if a skill in the per-module arrays (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS` / `CANARY_SKILLS`) has no entry in regression-checks.md, --check flags a warning. The refiner's auto-update protocol is the mechanism that keeps the file in sync with the suite; the mirror-sync check adds the drift-detection safety net.

---

## Follow-ups (filed as issues, not in current scope)

- Mirror-sync follow-up: deploy.sh --check surfaces missing regression-checks.md entries.
- Per future issue: define the schema of `regression-checks.md` formally (JSON Schema or markdown frontmatter contract) so pmo-qa-auditor can validate it structurally.
- Per future issue: auto-populate initial regression-checks.md with entries for all 19 existing skills (one-time backfill; refiner handles going-forward skills only).
