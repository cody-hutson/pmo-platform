---
title: Runtime Suite Selection Map
purpose: K1 cross-stage data contract mapping a changed code path to the runtime test suite that gates it. Deterministic (most-specific glob wins); an un-matched path is an explicit `test-run/suite-skip`, not a silent gap.
applies_to: pipeline/stage-06-engineering.md (C4 self-verification), pipeline/stage-07-dev-testing.md (Phase A8 runtime-suite gate), the install/onboarding/update regression suite
parallel_to: pipeline-event-log-schema.md (the event record the gate emits), finding-disposition-framework.md (sibling cross-stage data contract)
source: Stage 5 Solutioning + Collective Review scope-lock (v1.12)
framework_version_anchor: "v1.12"
---
<!-- reference-durability: allow-link -->

# Runtime Suite Selection Map

> **Status:** Active. K1 cross-stage data contract. Maps a changed code path → the runtime test suite that gates it.

## 1. Purpose

The release pipeline's quality gates were designed for a documentation/governance corpus (content quality review + structural validation + contract verification). As the platform ships code with runtime implications (`core/deploy/`, `core/hooks/`), a changed code path must select the runtime test suite that gates it — **deterministically**, so any human or agent reads *what was tested* without re-deriving the mapping per release.

This map is the single source of truth for that selection. It is consumed by three surfaces:

- **Stage 6 Engineering self-verification (C4)** — the author runs the selected suite under the sandbox isolation below and emits a `test-run` event (`stage=6`) as self-verification evidence in the PR body before handoff to Dev Testing.
- **Stage 7 Dev Testing Phase A8 (runtime-suite gate)** — Dev Testing runs the selected suite as a gate input; a `suite-fail` is a Blocker (→ FAIL per Stage 7 Phase D).
- **The install/onboarding/update regression suite** — registers its own row (its suite is its own regression floor) and emits `test-run` events.

The map is keyed on **path-glob, not version**, so it stays accurate without manual updates as releases come and go (the "prefer durable structures over static examples" + "parameterize over hardcode" discipline). It does NOT overlap the skill-NAME-keyed Skill-to-Check Mapping in `core/standards/regression-checks.md` — that maps a *skill* to its contract-regression checks; this maps a *changed code path* to its runtime suite.

## 2. Selection table

Selection is **deterministic**: evaluate rows top-to-bottom; the **most-specific glob wins** (a more-specific row above a broader row takes precedence). Row 5 is the explicit no-match fallback — a change that matches no runtime path is an honest `test-run/suite-skip`, not a silent gap.

| # | Changed-path glob | Gating suite | Runner invocation | Sandbox | Notes |
|---|---|---|---|---|---|
| 1 | `core/deploy/compose.py`, `core/deploy/lib-composition.sh` | compose / composition units | `python3 -m pytest core/deploy/tests/test_compose.py` + `bash core/deploy/tests/test_lib_composition.sh` | HOME→/tmp | composition surface (manifest-count tie-in) |
| 2 | `core/deploy/**` (other) | deploy suite | the deploy `run:` steps in `.github/workflows/install-tests.yml` (sandbox / install / exit-propagation / version-skew) | HOME→/tmp | install/onboarding/update substrate |
| 3 | `core/hooks/**` | hook suite | `bash core/hooks/tests/test-runner.sh` (aggregates the per-hook `*.test.sh`) | HOME→/tmp | security-hook regression |
| 4 | `core/deploy/tools/check-doc-links.py` | doc-link primitive self-test | `python3 core/deploy/tools/check-doc-links.py --self-test` | none (read-only) | self-test path |
| 5 | (no match) | NONE — emit `test-run/suite-skip` | n/a | n/a | doc / governance / spec change: no runtime suite (honest no-op, not a gap) |

When a change matches more than one row, the most-specific glob wins (e.g., a change to `core/deploy/compose.py` selects row 1, not the broader row 2). A change spanning multiple rows runs each selected suite and emits one `test-run` event per suite.

## 3. Sandbox requirement

All mutating suites run with `HOME` overridden to a `mktemp -d` path (`HOME=$(mktemp -d)` before invocation) so the suite cannot touch the operator's live `~/.claude/` install. This is a HARD requirement — an unsandboxed run mutates a real install path and corrupts the operator's live workspace. Read-only runners (row 4) need no sandbox.

Two execution loci, same result surface:

1. **CI (authoritative).** The deploy and hook suites run as discrete steps in `.github/workflows/install-tests.yml`. The preferred evidence is the CI run result, carried in the `test-run` event payload as `projects_to:actions-run:<url>`.
2. **Local DT fallback.** When CI evidence is unavailable at review time, the Dev Testing spoke runs the selected runner locally under the `/tmp` HOME-override and records the pass/fail counts.

## 4. Selection → verdict → event

The selection outcome maps to a `test-run` event (per `pipeline-event-log-schema.md` § 3) and, at Stage 7, to the gate verdict:

| Suite result | Severity at Stage 7 A8 | Phase D verdict effect | `test-run` subtype |
|---|---|---|---|
| All selected suites pass | — (no finding) | no effect | `suite-pass` |
| Any selected suite fails | **Blocker** | FAIL (any Blocker → FAIL); routes to Engineering as Tier 1 `fix(dt):` when fixable-in-scope, else Tier 2/3 | `suite-fail` |
| No path matches (row 5) | — (not applicable) | no effect | `suite-skip` |
| Suite selected but runner errors (infra) | Warning | logged; operator / CI investigates (not an Engineering code fix) | `suite-fail` with `reason:runner-error` |

A failing runtime suite is the strongest possible "the code does not work" signal — stronger than any content-quality dimension — so it is a Blocker, consistent with Stage 7 Phase D's "any blocker → FAIL".

## 5. Cutover

Applies to releases entering Stage 6 / Stage 7 going forward.

## 6. References

- [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 — the `test-run` event type + subtypes the gate emits
- [`../pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 5 Phase C C4 — the author self-verification consumer
- [`../pipeline/stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) § 5 Phase A8 — the Dev Testing gate consumer
- [`../../../core/standards/regression-checks.md`](../../../core/standards/regression-checks.md) § Skill-to-Check Mapping — the distinct skill-NAME-keyed regression bank (not overlapped by this map)
- [`../../tools/append-pipeline-event.sh`](../../tools/append-pipeline-event.sh) — the `test-run` event writer
