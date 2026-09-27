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
| 3 | `core/hooks/**` | hook suite | `bash core/hooks/tests/setup-ci-layout.sh` then `bash .claude/hooks/tests/test-runner.sh`, both from the checkout root, both every time and in that order: the first materializes the deployed hook layout at the checkout's `.claude/` — a snapshot the runner grades, so the runner line on its own after a source edit grades old code — and the runner aggregates every per-hook `*.test.sh`. The full harness takes several minutes, so give the runner a tool budget of at least ten minutes. The source-tree runner `core/hooks/tests/test-runner.sh` resolves no allowlist and cannot return a clean verdict | self (per-runner) | security-hook regression |
| 4 | `release/tools/*.sh`, `release/tools/*.py`, `core/deploy/tools/*.py`, `core/deploy/tools/*.sh` | discovered tool self-tests | `python3 release/tools/check-selftest-coverage.py --run` (add `--reconcile` to also assert the manifest floor) | none (read-only) | self-test path. The tool set is **discovered**, not enumerated: the four globs above are the `# scope:` directives committed in `core/deploy/allowlists/selftest-coverage-manifest.txt`, and the gating set is derived from them by a dispatch predicate over each tool's own text. This row previously named a single tool (`check-doc-links.py`), which is the same enumerate-don't-discover drift the CI gate retired — the tool is still covered, now by discovery. Enforced pre-merge by the `selftest-discovery` job in `.github/workflows/release-tooling-smoke.yml`, so Stage 7 cites an enforced gate rather than a hand-run command. |
| 5 | `install.sh`, `update.sh`, `docs/scripts/**`, `core/CLAUDE.md.template`, `core/*.template`, `core/config/allowlists/**` | install/onboarding/update standing regression suite | `bash core/deploy/tests/run-install-regression.sh` | self (per-invocation redirected roots; the durability member's R-8 detective) · resolution-sensitive (PyYAML, transitive) | the standing install/onboarding/update regression suite. Aggregates the install/onboarding/update deploy-test subset plus the hook-test floor; emits ONE `test-run` event for the whole suite (subject `suite:install-onboarding-update`). It is its own regression floor. Prevention is per invocation: members pass redirected roots (`--workspace-root`, `--config-root`; `update.sh` derives the deploy root from the former). The detective this cell names is `test_upgrade_config_durability.sh`'s R-8: a before/after manifest of the live install's `.claude/skills` whose subject is the account home rather than `$HOME`, and which reports a skip when that subject holds no files. Five other members carry live-install proofs of their own, and each still takes its subject from `$HOME` — `test_refresh_surfaces.sh` for two subjects — so under a caller-applied `HOME` override each compares an empty subject with itself; this cell does not name them. The verdict line carries the § 4 stamp. |
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

**What a `self (…)` parenthetical names, and in what order.** It names what *prevents* a write to a live install path — a redirected root or a per-probe `HOME` — first. A before/after manifest of a live path is a *detective*: it reports a write after it happened, so on its own it cannot stand in for the override, and a cell that names one names it after the preventive mechanism. A cell names a detective only when that detective is evidence under the override it stands in for: its subject is resolved independently of `$HOME`, and it reports a skip rather than a pass when that subject holds no files. A detective whose subject derives from `$HOME` is emptied by the very override it would replace, and one whose subject is absent compares empty with empty; neither is named.

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

The obligation is on the **property**, not on one spelling: the pin must restore the per-user site resolution of **the interpreter that imports the named module**, so it is computed with that interpreter. For row 1's pytest that is the `python3` on `PATH`, which `python3 -m pytest` runs. For `PyYAML (transitive)` it is `/usr/bin/python3`, which `deploy.sh` invokes by absolute path, so on rows 2 and 5 the recipe's first statement reads `/usr/bin/python3` where it reads `python3`. On a host where the two interpreters differ, a pin computed from the wrong one restores nothing. `.github/workflows/install-tests.yml` discharges the same property two ways: its shell-harness job exports the `/usr/bin/python3` user site on `PYTHONPATH` for the whole job, which likewise survives `HOME` redirection, and its install-regression job's override step sets `PYTHONUSERBASE` from `/usr/bin/python3` before the override. All are instances of this one rule.

**A skipped override is never silently equivalent to a satisfied one.** Where Axis 1 reads `self` or `none`, what replaces the override is named in the row itself — the runner's own sandbox mechanism, or its hermeticity — so a reader sees *why* it was skipped rather than inferring that it was forgotten.

Two execution loci, same result surface:

1. **CI (authoritative).** The deploy and hook suites run as discrete steps in `.github/workflows/install-tests.yml`. Those steps apply **no caller-side `HOME` override** — each suite sandboxes itself per Axis 1 — and the shell-harness job pins the user site per Axis 2. One exception is deliberate: the install-regression job also runs row 5's runner under the row-5 recipe, a fresh `HOME` with the user base pinned first, as the observer of the override half of its verdict, beside a probe that the durability member's R-8 catches a write to the subject it watches. The preferred evidence is the CI run result, carried in the `test-run` event payload as `projects_to:actions-run:<url>`.
2. **Local DT fallback.** When CI evidence is unavailable at review time, the Dev Testing spoke runs the selected runner locally under the recipe this section derives from that row's two axes, and records the pass/fail counts, plus the runner's verdict-line stamp verbatim where it prints one (§ 4).

## 4. Selection → verdict → event

The selection outcome maps to a `test-run` event (per `pipeline-event-log-schema.md` § 3) and, at Stage 7, to the gate verdict:

| Suite result | Severity at Stage 7 A8 | Phase D verdict effect | `test-run` subtype |
|---|---|---|---|
| All selected suites pass | — (no finding) | no effect | `suite-pass` |
| Any selected suite fails | **Blocker** | FAIL (any Blocker → FAIL); routes to Engineering as Tier 1 `fix(dt):` when fixable-in-scope, else Tier 2/3 | `suite-fail` |
| No path matches (row 6) | — (not applicable) | no effect | `suite-skip` |
| Suite selected but runner errors (infra) | Warning | logged; operator / CI investigates (not an Engineering code fix) | `suite-fail` with `reason:runner-error` |

A failing runtime suite is the strongest possible "the code does not work" signal — stronger than any content-quality dimension — so it is a Blocker, consistent with Stage 7 Phase D's "any blocker → FAIL".

**Verdict-line stamp.** The row-5 runner appends a bracketed stamp to its verdict line: `… — VERDICT <PASS|FAIL> [env: <E>; skipped: <S>]`. The stamp never changes the verdict. It records the environment the verdict was produced in, so two runs of one tree can be told apart, and it counts the proofs that produced no evidence. When a caller pointed the members' live-install subject away from the account home, a second bracket follows: `[r8: caller]`.

| Field | Values | Produced by | Consumed by |
|---|---|---|---|
| `env` | `home-account` (`HOME` is the account's home in the user database) · `home-override` (a caller redirected `HOME`) · `home-unresolved` (the user database could not be read) | the row-5 runner, once per run | the Stage 7 A8 **Test-results** `Env` cell, verbatim; the same vocabulary serves every row, with the DT spoke recording it where a runner does not stamp · the runner's `test-run` event payload (`env:`) · Stage 8 runtime-evidence citations |
| `skipped` | the number of member arms that reported `SKIP` — arms that produced no evidence, such as a live-install proof whose subject holds no files | the row-5 runner, summed from each member's summary line (`N passed, M failed, K skipped`) | the same three consumers; a PASS whose `skipped` is non-zero rests partly on arms that asserted nothing, and says so |
| `r8` (the second bracket, present only when set) | `caller` — `PMO_REGRESSION_LIVE_HOME` named something other than the account home, so the members' live-install proofs watched the caller's subject | the row-5 runner, from the subject it was handed | the same three consumers (payload `r8:caller`); a run that carries it proves nothing about the live install |

## 5. Cutover

Applies to releases entering Stage 6 / Stage 7 going forward.

## 6. References

- [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 — the `test-run` event type + subtypes the gate emits
- [`../pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 5 Phase C C4 — the author self-verification consumer
- [`../pipeline/stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) § 5 Phase A8 — the Dev Testing gate consumer
- [`../../../core/standards/regression-checks.md`](../../../core/standards/regression-checks.md) § Skill-to-Check Mapping — the distinct skill-NAME-keyed regression bank (not overlapped by this map)
- [`../../tools/append-pipeline-event.sh`](../../tools/append-pipeline-event.sh) — the `test-run` event writer
