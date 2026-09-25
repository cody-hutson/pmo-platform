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
<!-- design-artifact: flow-class=data-flow; name=runtime-suite-selection; depicts=release/references/pipeline/stage-06-engineering.md,release/references/pipeline/stage-07-dev-testing.md,release/references/pipeline/stage-08-qa-testing.md -->

> **Status:** Active. K1 cross-stage data contract. Maps a changed code path → the runtime test suite that gates it.

## 1. Purpose

The release pipeline's quality gates were designed for a documentation/governance corpus (content quality review + structural validation + contract verification). As the platform ships code with runtime implications (`core/deploy/`, `core/hooks/`), a changed code path must select the runtime test suite that gates it — **deterministically**, so any human or agent reads *what was tested* without re-deriving the mapping per release.

This map is the single source of truth for that selection. It is consumed by three surfaces:

- **Stage 6 Engineering self-verification (C4)** — the author runs the selected suite under the sandbox isolation below and emits a `test-run` event (`stage=6`) as self-verification evidence in the PR body before handoff to Dev Testing.
- **Stage 7 Dev Testing Phase A8 (runtime-suite gate)** — Dev Testing runs the selected suite as a gate input; a `suite-fail` is a Blocker (→ FAIL per Stage 7 Phase D).
- **The install/onboarding/update regression suite** — registers its own row (its suite is its own regression floor) and emits `test-run` events.

The map is keyed on **path-glob, not version**, so it stays accurate without manual updates as releases come and go (the "prefer durable structures over static examples" + "parameterize over hardcode" discipline). It does NOT overlap the skill-NAME-keyed Skill-to-Check Mapping in `core/standards/regression-checks.md` — that maps a *skill* to its contract-regression checks; this maps a *changed code path* to its runtime suite.

## 2. Selection table

Selection is **deterministic**. Three rules make it so: one glob grammar, a resolver that implements it, and one precedence rule. The last row is the explicit no-match fallback — a change that matches no runtime path records `test-run/suite-skip`, never a silent gap.

**Glob grammar.** A pattern in the *Changed-path glob* column is matched against the repository-relative path of each changed file — added, modified, renamed or deleted — and is anchored at the repository root:

- `*` matches any run of characters inside one path segment. It never matches `/`, so `release/tools/*.sh` names the tools directly under `release/tools/` and nothing below them.
- `?` matches one character other than `/`, and `[...]` matches one character from the set, never `/`.
- `**` is written only as a whole path segment. `/**/` matches zero or more whole directories, and a trailing `/**` matches every path below that directory, at any depth. A leading `**`, and a `**` that shares its segment with another character, are never written in this column: git reads a leading `**/` as "in every directory" and documents any other placement as invalid, so a pattern written either way would select one set under the reference resolver below and another under a matcher that implements only these rules.
- Every other character matches itself. A pattern with no wildcard names one path; when that path is a directory, the pattern also covers every path below it, as a trailing `/**` does.

**Resolver.** A matcher that implements this grammar is conformant. The reference resolver is git's pathspec with the `top` and `glob` magic words, applied to the change set. `--no-renames` lists both sides of a rename, so a path moved out of a row's reach still selects that row; the resolver sees deleted paths; and `top` gives the same answer from any working directory:

```bash
git diff --name-only --no-renames "$(git merge-base origin/main HEAD)" HEAD -- ':(top,glob)<pattern>'
```

Three common matchers are **not** conformant. A verification that uses one measures a different map:

| Matcher | How it departs from the grammar |
|---|---|
| Python `fnmatch`, or a git pathspec without the `glob` magic word | `*` crosses `/`, so `release/tools/*.sh` also matches the suites under `release/tools/tests/` and the fixtures below them |
| Python `PurePath.match` | it anchors at the right-hand end, and it reads `**` as `*`, so `core/deploy/**` matches only the direct children of `core/deploy/` |
| Python `Path.glob` over the checked-out tree | depending on the Python version, a trailing `**` yields directories and no files, and a deleted path is no longer on disk to be found |

**Precedence.** Row order does not decide. When more than one row matches a path, the row whose matching pattern has the **longest literal prefix** wins — the characters before the pattern's first `*`, `?` or `[`, with a wildcard-free pattern counting its full length. Rows that tie are all selected.

**Runner input.** Every selected runner runs with stdin on the null device. A runner that reads its inherited input can consume the rest of a caller's loop over the selected paths and end that loop early, while every suite it did run passes. The per-path runner forms in rows 6 and 7 therefore carry the redirect, and a caller gives a fixed runner the same redirect.

| # | Changed-path glob | Gating suite | Runner invocation | Sandbox | Notes |
|---|---|---|---|---|---|
| 1 | `core/deploy/compose.py`, `core/deploy/lib-composition.sh` | compose / composition units | `python3 -m pytest core/deploy/tests/test_compose.py` + `bash core/deploy/tests/test_lib_composition.sh` | none (hermetic) · resolution-sensitive (pytest) | composition surface (manifest-count tie-in). Both runners are hermetic by construction — pytest writes only under its `tmp_path` fixture and `test_lib_composition.sh` works inside its own `mktemp -d` — so no install path is reachable and there is nothing for an outer override to protect. Resolution-sensitive: `python3 -m pytest` resolves pytest from the per-user site, which a bare `HOME` override removes. |
| 2 | `core/deploy/**` (other) | deploy suite | the deploy `run:` steps in `.github/workflows/install-tests.yml` (sandbox / install / exit-propagation / version-skew) | self (per-test) · resolution-sensitive (PyYAML, transitive) | install/onboarding/update substrate |
| 3 | `core/hooks/**` | hook suite | `bash core/hooks/tests/test-runner.sh` (aggregates the per-hook `*.test.sh`) | self (per-runner) | security-hook regression |
| 4 | `release/tools/*.sh`, `release/tools/*.py`, `core/deploy/tools/*.py`, `core/deploy/tools/*.sh` | discovered tool self-tests | `python3 release/tools/check-selftest-coverage.py --run` (add `--reconcile` to also assert the manifest floor) | none (read-only) | self-test path. The tool set is **discovered**, not enumerated: the four globs above are the `# scope:` directives committed in `core/deploy/allowlists/selftest-coverage-manifest.txt`, and the gating set is derived from them by a dispatch predicate over each tool's own text. This row previously named a single tool (`check-doc-links.py`), which is the same enumerate-don't-discover drift the CI gate retired — the tool is still covered, now by discovery. Enforced pre-merge by the `selftest-discovery` job in `.github/workflows/release-tooling-smoke.yml`, so Stage 7 cites an enforced gate rather than a hand-run command. |
| 5 | `install.sh`, `update.sh`, `docs/scripts/**`, `core/CLAUDE.md.template`, `core/*.template`, `core/config/*.template`, `core/config/allowlists/**` | install/onboarding/update standing regression suite | `bash core/deploy/tests/run-install-regression.sh` | self (per-member, R-8) · resolution-sensitive (PyYAML, transitive) | the standing install/onboarding/update regression suite. Aggregates the install/onboarding/update deploy-test subset plus the hook-test floor; emits ONE `test-run` event for the whole suite (subject `suite:install-onboarding-update`). It is its own regression floor. |
| 6 | `release/tools/tests/*.sh`, `release/tools/tests/*.py`, `core/deploy/tools/tests/*.sh`, `core/deploy/tools/tests/*.py` | the changed tool test suite | the matched suite, by its own bare invocation: `bash <path> </dev/null` for `.sh`, `python3 <path> </dev/null` for `.py` | none (a membership rule, not a description of each member: every member is hermetic or read-only by Axis 1, and a suite that is not gets a row of its own) | Tool test suites are bare-invocation entry points, not `--self-test` dispatchers, so row 4's discovery runner never executes them — the `tests/` trees sit outside the self-test scope by decision (ADR-119). The four patterns are the `TEST_SUITE_GLOBS` constant of `release/tools/check-selftest-coverage.py`, verbatim — the trees its Arm D surveils for workflow wiring — so a change to either is a visible decision on both. **Depth bound: one level.** The suites sit directly under `tests/`; everything deeper is `tests/fixtures/`, whose files are suite inputs — several are named after real tools — and are never run as suites. A change to a fixture, a library or a tool does not select the suites that read it: a path-keyed row cannot say which suites read a given input, and CI runs every workflow-named suite on any change under `release/tools/**` or `core/deploy/tools/**`. CI (authoritative) is the workflow step that names the suite; a suite no workflow names — Arm D of `check-selftest-coverage.py` reports it — runs locally at C4 / A8. |
| 7 | `core/skills/*/scripts/*.sh` | the changed skill script's self-test | `bash <path> --self-test </dev/null`, for a script that dispatches `--self-test` | none (a membership rule, not a description of each member: every member is hermetic or read-only by Axis 1, and a script that is not gets a row of its own) | Skill-owned scripts sit outside both declared tool trees, so row 4's discovery does not reach them; the self-test exclusions file names each one. The runner applies only to a matched script that ADR-119's advertise predicate accepts — `advertises()` in `release/tools/check-selftest-coverage.py`, a dispatch on `--self-test` rather than a mention of it. Any other matched script is a gap in this map: it records `test-run/suite-skip` with `reason:map-gap-no-self-test` and is never invoked. CI (authoritative) is the workflow that names a script's self-test; a script no workflow names runs locally at C4 / A8. |
| 8 | (no match) | NONE — emit `test-run/suite-skip` | n/a | n/a | No row matches the path, so the map selects no suite. For a doc, governance or spec change that is the honest no-op. A path that carries runtime behaviour — executable code, or an input a suite reads — and still lands here is outside this map's coverage: a gap in the map, not a no-op. |

When a path matches more than one row, the precedence rule above decides: a change to `core/deploy/compose.py` selects row 1, not the broader row 2, and a change to `core/deploy/tools/check-doc-links.py` selects row 4, not row 2. A change spanning multiple rows runs each selected suite and emits one `test-run` event per suite. Row 5 (the standing install/onboarding/update regression suite) is the install-substrate-wide gate; a change to the install/update entrypoints, the workspace-setup scripts, the CLAUDE.md/composition-surface and config templates, or the managed-section allowlist sources selects it and the suite emits a single `test-run` event for the aggregate verdict.

**Per-path runners.** Rows 6 and 7 fill in their runner once for each matched path, so three guarantees hold beside the runner-input rule above. A runner is applied only to a matched path present at `HEAD`: a matched path the change deletes records `test-run/suite-skip` with `reason:matched-path-deleted`, and no missing file is invoked. Row 7 runs `--self-test` only on a script that dispatches it, as its Notes cell states; any other matched script is a named gap in this map. And the Sandbox cell of both rows is a membership rule rather than a description of each member: a suite or script that is not hermetic or read-only by Axis 1 (§ 3) gets a row of its own, whose Sandbox cell names its isolation.

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

The selection outcome maps to a `test-run` event (per `pipeline-event-log-schema.md` § 3), at Stage 7 to the gate verdict, and to one reading in the outcome vocabulary the plan verifier emits:

| Suite result | Severity at Stage 7 A8 | Phase D verdict effect | `test-run` subtype | Reads as |
|---|---|---|---|---|
| All selected suites pass | — (no finding) | no effect | `suite-pass` | PASS |
| Any selected suite fails | **Blocker** | FAIL (any Blocker → FAIL); routes to Engineering as Tier 1 `fix(dt):` when fixable-in-scope, else Tier 2/3 | `suite-fail` | FAIL |
| No path matches (the no-match row) | — (not applicable) | no effect | `suite-skip` | a named SKIP |
| A matched path runs no suite: the change deletes it, or it is a row-7 script that does not dispatch `--self-test` | — (not applicable) | no effect | `suite-skip` with `reason:matched-path-deleted` or `reason:map-gap-no-self-test` | a named SKIP |
| Suite selected but runner errors (infra) | Warning | logged; operator / CI investigates (not an Engineering code fix) | `suite-fail` with `reason:runner-error` | can't run here (UNRUNNABLE) |

A failing runtime suite is the strongest possible "the code does not work" signal — stronger than any content-quality dimension — so it is a Blocker, consistent with Stage 7 Phase D's "any blocker → FAIL".

The **Reads as** column states each outcome in the plan verifier's own vocabulary — PASS, FAIL, SKIP, UNRUNNABLE and ERROR — so a runtime-suite result means the same thing to every gate that also reads plan verdicts. A suite that ran reads PASS or FAIL. A change that runs no suite reads a named SKIP, and carries its reason. A runner error, where zero units executed, reads can't run here: unverified, never a pass.

## 5. Cutover

Applies to releases entering Stage 6 / Stage 7 going forward.

## 6. References

- [`pipeline-event-log-schema.md`](pipeline-event-log-schema.md) § 3 — the `test-run` event type + subtypes the gate emits
- [`../pipeline/stage-06-engineering.md`](../pipeline/stage-06-engineering.md) § 5 Phase C C4 — the author self-verification consumer
- [`../pipeline/stage-07-dev-testing.md`](../pipeline/stage-07-dev-testing.md) § 5 Phase A8 — the Dev Testing gate consumer
- [`../../../core/standards/regression-checks.md`](../../../core/standards/regression-checks.md) § Skill-to-Check Mapping — the distinct skill-NAME-keyed regression bank (not overlapped by this map)
- [`../../tools/append-pipeline-event.sh`](../../tools/append-pipeline-event.sh) — the `test-run` event writer
