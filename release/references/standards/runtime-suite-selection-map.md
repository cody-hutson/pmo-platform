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

Selection is **deterministic**: evaluate rows top-to-bottom; the **most-specific glob wins** (a more-specific row above a broader row takes precedence). The last row is the explicit no-match fallback — a change that matches no runtime path is an honest `test-run/suite-skip`, not a silent gap.

| # | Changed-path glob | Gating suite | Runner invocation | Sandbox | Notes |
|---|---|---|---|---|---|
| 1 | `core/deploy/compose.py`, `core/deploy/lib-composition.sh` | compose / composition units | `python3 -m pytest core/deploy/tests/test_compose.py` + `bash core/deploy/tests/test_lib_composition.sh` | none (hermetic) · resolution-sensitive (pytest) | composition surface (manifest-count tie-in). Both runners are hermetic by construction — pytest writes only under its `tmp_path` fixture and `test_lib_composition.sh` works inside its own `mktemp -d` — so no install path is reachable and there is nothing for an outer override to protect. Resolution-sensitive: `python3 -m pytest` resolves pytest from the per-user site, which a bare `HOME` override removes. |
| 2 | `core/deploy/**` (other) | deploy suite | the deploy `run:` steps in `.github/workflows/install-tests.yml` (sandbox / install / exit-propagation / version-skew) | self (per-test) · resolution-sensitive (PyYAML, transitive) | install/onboarding/update substrate |
| 3 | `core/hooks/**` | hook suite | `bash core/hooks/tests/test-runner.sh` (aggregates the per-hook `*.test.sh`) | self (per-runner) | security-hook regression |
| 4 | `release/tools/*.sh`, `release/tools/*.py`, `core/deploy/tools/*.py`, `core/deploy/tools/*.sh` | discovered tool self-tests | `python3 release/tools/check-selftest-coverage.py --run` (add `--reconcile` to also assert the manifest floor) | none (read-only) | self-test path. The tool set is **discovered**, not enumerated: the four globs above are the `# scope:` directives committed in `core/deploy/allowlists/selftest-coverage-manifest.txt`, and the gating set is derived from them by a dispatch predicate over each tool's own text. This row previously named a single tool (`check-doc-links.py`), which is the same enumerate-don't-discover drift the CI gate retired — the tool is still covered, now by discovery. Enforced pre-merge by the `selftest-discovery` job in `.github/workflows/release-tooling-smoke.yml`, so Stage 7 cites an enforced gate rather than a hand-run command. |
| 5 | `install.sh`, `update.sh`, `docs/scripts/**`, `core/CLAUDE.md.template`, `core/*.template`, `core/config/allowlists/**` | install/onboarding/update standing regression suite | `bash core/deploy/tests/run-install-regression.sh` | self (per-member, R-8) · resolution-sensitive (PyYAML, transitive) | the standing install/onboarding/update regression suite. Aggregates the install/onboarding/update deploy-test subset plus the hook-test floor; emits ONE `test-run` event for the whole suite (subject `suite:install-onboarding-update`). It is its own regression floor. |
| 6 | (no match) | NONE — emit `test-run/suite-skip` | n/a | n/a | doc / governance / spec change: no runtime suite (honest no-op, not a gap) |

When a change matches more than one row, the most-specific glob wins (e.g., a change to `core/deploy/compose.py` selects row 1, not the broader row 2). A change spanning multiple rows runs each selected suite and emits one `test-run` event per suite. Row 5 (the standing install/onboarding/update regression suite) is the install-substrate-wide gate; a change to the install/update entrypoints, the workspace-setup scripts, the CLAUDE.md/composition-surface templates, or the managed-section allowlist sources selects it and the suite emits a single `test-run` event for the aggregate verdict.

## 3. Sandbox requirement

A suite's **isolation** need and its **dependency-resolution** need are two independent properties, and the recipe is a function of both. Read them off the row's `Sandbox` cell in § 2.

**Axis 1 — isolation** (the token the cell opens with):

| Token | Meaning | Caller-applied `HOME` override |
|---|---|---|
| `outer` | the runner writes into a real install path and establishes no sandbox of its own | **required** — `HOME=$(mktemp -d)` before invocation |
| `self (…)` | the runner establishes its own sandbox — a redirected deploy root, a redirected config root, or a per-probe `HOME` — and the parenthetical names which | **not required.** The named mechanism is what replaces it |
| `none (…)` | the runner is hermetic or read-only: it writes only inside its own `mktemp -d` or its test framework's temp fixture, and never reaches an install path | **not required**, and applying one is **not neutral** — see Axis 2 |

An unsandboxed run of an `outer` suite mutates a real install path and corrupts the operator's live `~/.claude/`. That is what the override is for. It is not a reason to apply it where Axis 1 reads `self` or `none`.

**Axis 2 — resolution sensitivity** (`· resolution-sensitive (<module>)` when present):

A `HOME` override relocates the Python **user base**. `site.USER_BASE` and `site.USER_SITE` are derived from `$HOME`, so overriding it drops the per-user `site-packages` directory out of `sys.path` entirely, and any module installed with `pip install --user` — directly, or transitively by anything the runner invokes — becomes unimportable. The runner then fails **before executing a single assertion**, for a reason that has nothing to do with the code under test. A bare override on a resolution-sensitive row does not isolate the suite; it removes a dependency the suite needs.

Where a row is marked resolution-sensitive, an applied override **MUST** be paired with a user-base pin, and **the pin must be computed before the override**:

```bash
# Compute the real user base FIRST, in its own statement.
USER_BASE="$(python3 -c 'import site; print(site.USER_BASE)')"
SBX="$(mktemp -d)"
HOME="$SBX" PYTHONUSERBASE="$USER_BASE" <runner>
```

The ordering is load-bearing, not a style point. Shell variable assignments in a command prefix take effect **left to right, in both `bash` and `zsh`**, so writing `HOME="$SBX" USER_BASE="$(python3 -c …)" <runner>` expands the substitution under the *already-overridden* `HOME` and pins a path that does not exist — reproducing the very failure the pin exists to prevent.

The obligation is on the **property**, not on one spelling: the pin must restore the interpreter's per-user site resolution. `.github/workflows/install-tests.yml` discharges the same property for its whole job by exporting the user-site on `PYTHONPATH`, which likewise survives `HOME` redirection. Both are instances of this one rule.

**A skipped override is never silently equivalent to a satisfied one.** Where Axis 1 reads `self` or `none`, what replaces the override is named in the row itself — the runner's own sandbox mechanism, or its hermeticity — so a reader sees *why* it was skipped rather than inferring that it was forgotten.

Two execution loci, same result surface:

1. **CI (authoritative).** The deploy and hook suites run as discrete steps in `.github/workflows/install-tests.yml`. Those steps apply **no caller-side `HOME` override** — each suite sandboxes itself per Axis 1 — and the workflow pins the user site for the job per Axis 2. The preferred evidence is the CI run result, carried in the `test-run` event payload as `projects_to:actions-run:<url>`.
2. **Local DT fallback.** When CI evidence is unavailable at review time, the Dev Testing spoke runs the selected runner locally under the recipe this section derives from that row's two axes, and records the pass/fail counts.

## 4. Selection → verdict → event

The selection outcome maps to a `test-run` event (per `pipeline-event-log-schema.md` § 3) and, at Stage 7, to the gate verdict:

| Suite result | Severity at Stage 7 A8 | Phase D verdict effect | `test-run` subtype |
|---|---|---|---|
| All selected suites pass | — (no finding) | no effect | `suite-pass` |
| Any selected suite fails | **Blocker** | FAIL (any Blocker → FAIL); routes to Engineering as Tier 1 `fix(dt):` when fixable-in-scope, else Tier 2/3 | `suite-fail` |
| No path matches (row 6) | — (not applicable) | no effect | `suite-skip` |
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
