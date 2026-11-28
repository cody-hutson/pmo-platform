---
title: Release Plan — one-resolver-and-release-tool-routing (one resolver per data class, and the release tools route through it)
type: release-plan
plan_type: release
status: EXECUTING
release: versioned (bump-class minor; the concrete number binds only at the Stage-12 atomic claim)
milestone: one-resolver-and-release-tool-routing
release_class: novel
reversibility: MODERATE / Confidence HIGH — one resolver file, its configuration declaration, its tests, two guard and check consumers, a decision record and the release tools that call the resolver, on one branch, one pull request and one merge. With the switch shipped off nothing moves, so a single-PR revert restores every surface; a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `one-resolver-and-release-tool-routing`

**Milestone:** `one-resolver-and-release-tool-routing`. Two cards on a hard chain: **#8020** (one resolver per data class, with a switch that still returns today's homes) and **#8021** (the release tools route through it). The Stage-4 planning sub-task **#9202** carries the approved two-part plan, the Stage-4 plan gate's Decision Recorded, the `[BUNDLE AMENDMENT]`, and the two Collective Review Decision Recorded comments (round 1, the rulings; round 2, the scope lock). The Stage-5 design for #8020 is on **#9204** (the round-0 three parts, its adversarial design review, the revision-1 four-part delta, the revision-1 erratum and the focused adversarial re-review); #8021's design is on **#9222**. The Stage-6 Engineering sub-task for #8020 is **#9233**. This file is Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim: the branch and this file stay slug-primary while in flight, and the Header **Version** cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is recorded in § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch, `release/one-resolver-and-release-tool-routing`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial** — Commit 0, then #8020's slices, then #8021's. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9202 and is amended, in order, by: the Stage-4 plan gate's Decision Recorded; the `[BUNDLE AMENDMENT]`; the Collective Review round-1 Decision Recorded; the Stage-5 revision-1 deltas and errata; and the Collective Review round-2 scope-lock Decision Recorded, whose binding Stage-6 inputs are part of the specification. Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a resolver gains per-class functions behind a configuration switch that ships off, a configuration template and schema gain one opt-in key, and two consumers harden against the resolver's new failure contract and inputs, per the Bump-Class Selection Guide's rows for protocol and configuration changes within existing structure. No new skill and no new governance file. The concrete number binds at the Stage-12 atomic claim |
| **Date Created** | 2026-11-28 (Saturday, UTC) |
| **Release Manager** | Agent-assisted (release-hub, spawned Stage 6 Engineering spokes) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) |
| **Branch** | `release/one-resolver-and-release-tool-routing` |
| **PR** | opened in **draft** at Stage 6, after this commit |
| **Milestone** | `one-resolver-and-release-tool-routing` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-27, domain: software }`

Rationale (the Stage-4 Mode-B classification): every File Change Matrix path is an internal platform artifact, so the release is sourcing-exempt. The dominant change class is shell tooling plus configuration schema plus tests (`software`); the secondary class is `governance`, for the placement-standard edit and the decision record.

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0. `origin/main` had advanced from the Stage-4 baseline `8ed5e273` to `7499df9f`, the merge of the sibling release `issue-body-is-the-scope-of-record`. The highest version tag on the remote is `v5.14`; no `v5.15` or later tag exists.
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha <origin/main> --dry-run`), at both `8ed5e273` and `7499df9f`: **`v5.15`** each time.
3. `v5.15` is not in the claimed set (the tag arm binds, and it reads free) and equals the recomputed next-free: **PROCEED**. Residual, recorded rather than hidden: the sibling that just merged showed the same provisional slot, and its own atomic claim may take `v5.15` after this re-verify. Provisional-display is not a claim; under defer-to-merge this release is allocated the next free number at its own Stage-12 claim, and the Header cell above carries the placeholder so nothing here needs to change when that happens.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp one-resolver-and-release-tool-routing` — run after this file was written and before it was committed; its verdict line is recorded in the Engineering Commit 0 message and in § Verification Evidence.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | Stage 4 `8ed5e273`; branch cut at `7499df9f` (the window is the sibling merge of `issue-body-is-the-scope-of-record`; it touches one File Change Matrix path, `core/ADRs/README.md`, the overlap the Stage-5 design serialized behind it — § Deviation Log DEV-12) |

## Summary (30 seconds)

- **Scope:** two `size:L` cards on a hard chain, #8020 → #8021. Release Class **novel**. One branch, one PR (D-C SINGLE), serial Engineering (P0). Stage 5 activated for the whole release.
- **#8020** adds, in `core/deploy/lib-instance-path.sh`, one resolver per served class — working state per repository, working state install-scoped, and leak-risk — plus a run-class argument, the designated-main-checkout rule, a git-work-tree refusal for the per-user homes, and a switch, `operator.toml [adapters] governed_homes`, that ships off. With the switch off every resolver returns today's path by today's rungs. The switch is declared in the template and schema and catalogued in the configuration catalog; a decision record captures the contract; the two `core/deploy/deploy.sh` readers of the event-log path stop reading a refused path as a benign absence, with the file's line count held; and the commit-time PII guard's anchored read stops honoring the class resolvers' inputs.
- **#8021** routes the release tools that read or write hub state, the pipeline event log or the close-out registers through those functions, with each tool's own override cascade kept at today's precedence while the switch is off.
- **Behavior preservation is a matrix:** each consumer keeps its own cascade with the switch off (ADR-231 carried-forward clause 2); convergence is a switch-on property.

## Phase A0 — Triage→Design Re-Review (transcribed)

**G-PL5 cache read — MISS.** No `mode-r-briefing` comment was on #9202; PT-1..4 ran in full. **No Tier-0 premise problem.** Each card had one C2 row group, each routed Tier 1 [ADJUST], applied by the hub at the plan gate (§ Deviation Log DEV-1).

**Ticket-architecture reconciliation.** Both cards were Stage-2 approved on 2026-09-28 (Monday). Every governing surface they now sit under is newer: the operator layering review (2026-10-27), ADR-231 (accepted 2026-11-07, Saturday) and the placement standard (shipped 2026-11-07). The C2 rows below are the reconciliation.

| Card | Requirement | Classification | Delta |
|---|---|---|---|
| #8020 | AC-1 (one resolver per class + run-class argument) | C2 | name the served classes: working state per repository, working state install-scoped, leak-risk; Operator PMO content keeps its resolvers; Tool-owned is out of scope |
| #8020 | AC-2 (switch unset → today's path for every member) | C2 | "every member" is every register row resolving today through this resolver or the container, asserted per member on the default tier and on each override rung its consumers honor today |
| #8020 | AC-3 (switch set → `/local-state/` and the leak-risk home) | C2 | the leak-risk home is spelled in its XDG-rooted form, against a fixture repository and a fixture XDG root |
| #8020 | AC-4 (embargoed run → leak-risk home whatever the switch says) | C1 | verbatim; Stage 5 answered the isolation-key question |
| #8020 | AC-5 (switch declared in template and schema) | C1 | verbatim |
| #8020 | Proposed change (mechanism deferred to Stage 5) | C1 | carries the T3 abstraction-altitude and structural-premise riders into Stage 5 |
| #8020 | Risk (a wrong default moves state early) | C2 | add: no new member under the out-of-tree container; the U5 near-miss is asserted |
| #8021 | Evidence (14 event-log / 10 hub-state) | C2 | re-measured 15 / 10 at `8ed5e273` |
| #8021 | AC-1 (no listed tool builds a container path itself) | C2 | narrowed per D-FinopsStoreArm (A) to hub-state, event-log and register paths |
| #8021 | AC-2 (switch unset → each suite passes unchanged) | C2 | add the before/after parity comparison and its perturbed-path control |
| #8021 | AC-3 (switch set → reads and writes under the fixture's `/local-state/`) | C1 | verbatim |
| #8021 | Proposed change | C2 | record the per-tool route class in the Affected Files |
| #8021 | Risk (a missed call site) | C1 | verbatim; the wave-3 conformance test is the backstop |

**A0.5 / G-PL1 — CURRENCY-MISMATCH** on #8020's AC-1 and AC-3 and #8021's evidence line → Tier 1 [ADJUST]. **A0.6 / G-PL2:** both bodies pass G1-02, G1-04 and G1-05. **A0.7 / G-PL3 — SKIP** (the window from the release base to `origin/main` was empty at Stage 4). **A0.8 / G-PL4:** #8020 is a general card (pass-through); #8021 is admit-still-valid (four of the nine tools build a path in code at `35dbf418`, `7813457d` and `8ed5e273` alike).

## Dependency Graph

```
#8017 (CLOSED, placement standard) ──▶ #8020 ──▶ #8021
                                          │          ├──▶ #8026 (wave 3, conformance test)
                                          │          └──▶ #8031 (wave 5)
                                          ├──▶ #8025 (wave 3)  ├──▶ #8027 (wave 4)
                                          ├──▶ #8029 (wave 4)  ├──▶ #8030 (wave 5)
                                          └──▶ #8037 (wave 7)
soft: in-repo-home-is-guarded (ships /local-state/ and its guard: gates the switch flip, not this merge)
soft: worktree-sessions-reach-in-repo-homes (shared files, see § Contention Map)
```

The edges were read from the native dependencies API at Stage 4: #8020 is blocked by #8017 (closed) and blocks #8021, #8025, #8027, #8029, #8030 and #8037; #8021 is blocked by #8020 and blocks #8026 and #8031. Circular chains: 0.

## Implementation Sequence

Amended by the Stage-5 revision-1 "Order of work" (§ Deviation Log DEV-6). One commit per change, each depending on the one before it:

0. **Engineering Commit 0** — this file, after the Commit-0 version re-verify.
1. **#8020, Change 1** — `core/deploy/lib-instance-path.sh`: the class resolvers, the switch, the run class, the designation rule and the work-tree refusal, appended as a new section; the event-log, needle and roster bodies moved to private today-arm functions with their public names kept as wrappers; the optional file argument on the one operator.toml reader; the header.
2. **#8020, Changes 2 and 3 together** — the switch in `core/config/operator.toml.template` and `core/config/operator-toml-schema.json` (the schema parity check needs both in one commit).
3. **#8020, Change 4** — `core/standards/instance-data-placement-standard.md`: the concept model, the switch sentence, and the S-01, S-04 and S-19 cells.
4. **#8020, Change 5** — `core/deploy/deploy.sh`: the decision-emission gate engine and Check 19 capture-then-check, twelve lines rewritten in place, line count held.
5. **#8020, Changes 6 and 7 together** — `core/hooks/git-pre-commit-pii.sh`'s anchored read and `core/hooks/tests/git-pre-commit-pii-env-inputs.test.sh` group A.
6. **#8020, Change 8** — `core/deploy/tests/test_lib_instance_path.sh`: the fixture sandbox and every `8020-*` arm, `CIAC-3` and `CIAC-4`.
7. **#8020, Changes 9 and 10 together** — the decision record in `core/ADRs/` (number taken immediately before the file is created) and its `core/ADRs/README.md` index entry.
8. **#8020, Change 11** — the `governed_homes` rows in `docs/platform-config-reference.md` and `core/schemas/platform-config-schema.md`.
9. **#8021** — one commit per tool class per its Stage-5 design on #9222: the code routings, the query-status checks, the header edits, the usage-extractor package rebuild, and the `CIAC-1`, `CIAC-2` and `8021-*` arms.
10. **Release-integrated verification** — a full self-test and install-regression run on the release head (`PMO_REGRESSION_EMIT=0`).

## Agent-Editability Read

**Derivation** — controls read at `8ed5e273` (Stage 4 and Stage 5 revision 1):

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh`, two `case` blocks invoking `always_block "BLOCK-AUTONOMY-001"`. Their arms project, in repository-relative form, onto the three governance basenames (`CLAUDE.md`, `OPERATIONS.md`, `RELEASE_PROTOCOL.md`) and the workspace root's own `.claude/` entries, which the repository does not track.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`, `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`, armed by `^skill_discipline_migrated_v10_2:[[:space:]]*true`.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| #8020 | every path in its File Change Matrix block | no | no (conjunct 1) | unconstrained | ordinary Engineering spoke |
| #8021 | every tool and test path in its block | no | no (conjunct 1; `scripts/` is outside the scope regex) | unconstrained | ordinary Engineering spoke |
| #8021 | `core/skills/finops-usage-extractor/SKILL.md` | no | no (conjunct 2: arming key absent) | unconstrained | ordinary Engineering spoke |
| #8021 | the package and its `.sha256` | no (generated) | no (generated) | unconstrained | produced by the package build |
| release | this file | no | no | unconstrained | first Engineering spoke (Commit 0) |

Result: 0 floored, 0 gated. No path is floored or skill-gated.

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9 Plan Review | 10 Dry Run | 11 Snapshot | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|---|
| #8020 | **APPLY** — T3 (the body deferred the mechanism to Stage 5) and T4 (switch-carrier options); ran first | APPLY | APPLY (functional: resolver behavior) | APPLY (12 criteria) | release-scoped APPLY, Deep depth (novel) | APPLY (compressed, git-native) | APPLY (compressed, git-native) | APPLY | APPLY |
| #8021 | **APPLY** — whole-release activation, plus T6; ran after #8020's Stage 5 | APPLY | APPLY (functional: nine tools) | APPLY (4 criteria) | release-scoped | release-scoped | release-scoped | release-scoped | release-scoped |

No stage is skipped: both cards change behavior (resolution) and neither is trivial.

## Contention Map

**Within-release.** #8020 and #8021 share `core/deploy/tests/test_lib_instance_path.sh` (append-pattern arms, written serially under P0) and this file. The edge between them is an interface dependency: #8021 calls the functions #8020 adds, through the frozen interface v2 on #9204.

**#8021 call-site set** (re-measured at `8ed5e273`):

| File | Builds a container path in code | Route |
|---|---|---|
| `release/tools/automated-closeout.sh` | yes: hub-state leaf plus its own workspace-root cascade | code routing |
| `release/tools/check-event-record-integrity.sh` | yes: hub-state leaf; event log already through the resolver | code routing |
| `release/tools/produce-learnings-register.sh` | yes: the registers subfolder | code routing |
| `core/skills/finops-usage-extractor/scripts/rollup-attribution.sh` | yes: the container leaf inline (usage store, hub state, event log) | code routing (hub-state and event-log arms; the store arm is a release follow-up) |
| `release/tools/append-pipeline-event.sh` | no: the event-log resolver | names its repository to the event-log member |
| `release/tools/query-pipeline-event.sh` | no: the event-log resolver | names its repository; passes a refused path's status through |
| `release/tools/compute-cycle-time.sh` | no: through the query tool | header |
| `release/tools/compute-dora-metrics.sh` | no: through the query tool | checks the query tool's status, and header |
| `release/tools/synthesize-release-learnings.sh` | no: through the query tool | checks the query tool's status, and header |

**Cross-PR Overlap Audit (A4).** Baseline SHA `8ed5e273` at 2026-11-28T03:26Z. One open PR at Stage 4 (`issue-body-is-the-scope-of-record`), intersecting the Stage-4 matrix at 0 paths. The Stage-5 decision-record row added `core/ADRs/README.md`, the one overlap with that PR, serialized behind it; it merged before this commit (DEV-12).

**Sibling milestones in flight** (re-read at Commit 0):

| Sibling | File overlap with this matrix | Class |
|---|---|---|
| `worktree-sessions-reach-in-repo-homes` (draft PR open) | `core/deploy/lib-instance-path.sh` (two comment blocks in the telemetry and analysis region, which this release leaves untouched), `core/config/operator.toml.template` (one line in place, above the anchored line), the placement standard (rows this release does not edit) | **Tier-S serialization edge.** It merges first; this release re-baselines on it and re-reads every cited line by content |
| `in-repo-home-is-guarded` (draft PR open) | `core/hooks/git-pre-commit-pii.sh` and its env-inputs suite (inserts at lines this release does not edit) | ships `/local-state/` and its commit guard, which gate the **flip**, not this merge |
| `rollups-select-projects-by-portfolio` (draft PR open) | `core/deploy/deploy.sh` (conditional at its plan) | re-read the twelve rewritten lines by content before Stage 9 |
| `fs-boundary-judges-every-listed-verb-operand` (draft PR open) | none (hooks only) | — |

### In-Flight Release Roster

**Measured at:** `8ed5e273` · `2026-11-28T03:26:47Z` · **Population:** n=1 sibling (open `release/*` PRs, drafts included, plus remote `release/*` heads with no PR, minus this release)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `issue-body-is-the-scope-of-record` | `#9201` | `dd36fbed` | `minor` | `v5.15` | `v5.15` | — |

That sibling merged at 2026-11-28T15:31Z (merge `7499df9f`); the roster is the Stage-4 pinned measurement and carries no verdict. Stage 9 Phase A6.6 re-measures it fresh.

## File Change Matrix

One path per line, `<path>  <VERB>`. Amended at Commit 0 per § Deviation Log DEV-7 and DEV-8: the Stage-5 revision-1 write set for #8020 is carried in full, the fired conditional is promoted, and every unfired conditional is resolved with its basis recorded.

```
# ── #8020 — one resolver per class, the switch, the run class ──
core/deploy/lib-instance-path.sh  edit
core/config/operator.toml.template  edit
core/config/operator-toml-schema.json  edit
core/deploy/tests/test_lib_instance_path.sh  edit
core/standards/instance-data-placement-standard.md  edit
core/ADRs/ADR-243-class-homes-switch-and-designation.md  add
core/ADRs/README.md  edit
docs/platform-config-reference.md  edit
core/schemas/platform-config-schema.md  edit
core/deploy/deploy.sh  edit
core/hooks/git-pre-commit-pii.sh  edit
core/hooks/tests/git-pre-commit-pii-env-inputs.test.sh  edit
# ── #8021 — route the release tools through the resolver ──
release/tools/automated-closeout.sh  edit
release/tools/check-event-record-integrity.sh  edit
release/tools/produce-learnings-register.sh  edit
core/skills/finops-usage-extractor/scripts/rollup-attribution.sh  edit
release/tools/append-pipeline-event.sh  edit
release/tools/query-pipeline-event.sh  edit
release/tools/compute-cycle-time.sh  edit
release/tools/compute-dora-metrics.sh  edit
release/tools/synthesize-release-learnings.sh  edit
core/skills/finops-usage-extractor/SKILL.md  edit
# ── #8021 — generated by the package build from the edited skill ──
packages/finops-usage-extractor.skill  edit
packages/finops-usage-extractor.skill.sha256  edit
# ── release record ──
release/releases/plans/one-resolver-and-release-tool-routing_RELEASE_PLAN.md  add
```

The decision record's number was taken by `release/tools/renumber-adr.py` immediately before the file was created (`--next-free` 243; `--detect` → BINDS), and the commit that adds it re-spelled its row here. Should the mainline claim 243 first, the renumbering tool moves the record at merge and this row with it.

#### Read-only inputs

```
core/ADRs/ADR-231-non-tracked-data-homed-by-risk-class.md  READ
core/standards/hub-session-continuity.md  READ
core/deploy/tools/check-operator-toml-schema.sh  READ
core/deploy/tests/run-install-regression.sh  READ
core/deploy/tests/test_check19_event_log_integrity.sh  READ
core/skills/finops-usage-extractor/scripts/rank-command-templates.sh  READ
.github/workflows/release-tooling-smoke.yml  READ
.github/workflows/install-tests.yml  READ
.github/workflows/decision-emission.yml  READ
release/references/pipeline/stage-13-close.md  READ
.gitignore  READ
```

#### Release-wide explicit non-scope

```
core/deploy/composition-surface-manifest.sh  NOT EDITED
core/deploy/lib-composition.sh  NOT EDITED
docs/scripts/setup-workspace.sh  NOT EDITED
core/deploy/tools/path-leak-patterns.sh  NOT EDITED
core/deploy/tools/check-enum-parity.sh  NOT EDITED
core/standards/depersonalization-spec.md  NOT EDITED
core/deploy/tests/test_instance_path_roundtrip.sh  NOT EDITED
release/tools/tests/test_resolver_routing.sh  NOT EDITED
core/config/allowlists/script-execution-allowlist.txt  NOT EDITED
core/skills/finops-usage-extractor/scripts/estimate-usage.sh  NOT EDITED
core/skills/finops-usage-extractor/scripts/extract-usage.sh  NOT EDITED
core/skills/finops-usage-extractor/scripts/report-usage.sh  NOT EDITED
release/tools/compute-front-cluster-telemetry.sh  NOT EDITED
release/tools/compute-middle-cluster-telemetry.sh  NOT EDITED
local-state/README.md  NOT EDITED
```

The deploy and install consumers other than the two `deploy.sh` event-log reads are wave-3 and wave-4 scope (#8025, #8027). The two cluster-telemetry tools reach the log only through the query tool. `/local-state/` and its README ship with `in-repo-home-is-guarded`. The five formerly conditional rows above are non-scope because their conditions did not fire (DEV-8).

**New-executable companion obligation:** no `add` row is a tracked executable script, so no allowlist row is owed. The resolver test already runs in CI through `core/deploy/tests/run-install-regression.sh` in `install-tests.yml`, and is allowlisted in all four invocation forms.

## Risk Register

| ID | Risk | Severity | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| R1 | **Interface churn.** Five later slices (#8025, #8027, #8029, #8030, #8037) and #8021 consume #8020's interface | High | Frozen interface v2 on #9204, recorded in the decision record; adversarial design review and focused re-review | MODERATE / MEDIUM |
| R2 | **Early state move.** A switch that defaults on, or a doc that says to flip it, before `/local-state/` and its guard exist sends writes to a home with no README and no commit guard | High | Ships off; an absent, empty or blank switch reads as off; no header, template comment or doc tells an operator to set it; CIAC-3 asserts it | EXPENSIVE if it fires / HIGH |
| R3 | **Override-precedence regression.** The three hub-state cascades differ today (closeout, integrity, rollup) | High | With the switch off each consumer's cascade is reproduced at its current precedence (ADR-231 carried-forward clause 2); `8020-AC2` pins every resolver-level rung, CIAC-1 every consumer-held rung | MODERATE / HIGH |
| R4 | **Live-state writes during testing.** Five concurrent hubs use these tools | High | Fixture-only arms: `HOME`, the config root, the workspace root and both XDG bases at a fixture root, direct overrides unset; a content-keyed nonce detector over the shared live surfaces (including the live designated checkout's ignored `local-state/` and `analysis/`), a modification-time detector over the live config root only; the live operator config is never written | CHEAP to prevent, MODERATE if missed / HIGH |
| R5 | **Merge timing.** This release changes tools sibling hubs run at Stages 12 and 13 | High | It must not merge while any sibling sits between its Stage-12 merge and its Stage-13 close-out (hub AI-001); a plain merge, never an admin bypass | MODERATE / HIGH |
| R6 | **Missed call site** | Medium | 0 unlisted release-tool builders at Stage 4; deploy and install consumers are wave 3; the usage-store family and the swallow-idiom lint are release follow-ups | MODERATE / MEDIUM |
| R7 | **Deployed-copy reachability** of `rollup-attribution.sh` | Medium | Checkout discovery on the `rank-command-templates.sh` precedent; package rebuilt in the same PR | CHEAP / HIGH |
| R8 | **Sibling file contention** on the resolver, the template, the placement standard, `deploy.sh` and the PII guard | Medium | Siblings merge first; this release re-baselines on each and re-reads every cited line by content; `deploy.sh` holds its line count and `anchors resolve --check` is re-run after each sibling merge and on the PR head (R-v1-Lines) | CHEAP / HIGH |
| R9 | **Version slot** shared with a sibling | Low | Defer-to-merge: the Stage-12 atomic claim settles it | CHEAP / HIGH |
| R10 | **Scope growth** under D-ResolverScope (A) | Medium | Stage 5 re-sized at L; the operator kept L knowingly at the scope lock (DEV-11) | CHEAP / MEDIUM |
| R11 | **Embargoed-run class propagation.** No tool carries a run's class this release | Medium (latent until cutover) | The `--run-class` argument ships; the positive, fail-closed run-class record is a reserved contract the leak-risk migration card implements | MODERATE / MEDIUM |
| R12 | **Rollback complexity** | Medium | § Rollback Strategy | MODERATE / HIGH |
| R13 | **The live event log written by a modified writer before merge** | High | Hub AI-002: until this release merges, every event-log row is emitted from tool copies identical to `origin/main`; hub AI-003: every Stage 6–8 run of the install-regression runner sets `PMO_REGRESSION_EMIT=0` | CHEAP / HIGH |
| R14 | **A refused event-log path read as a benign absence** (the swallow idiom) | Major | `deploy.sh`'s two sites capture then check (PR-1, `8020-PR1`); the calling pattern puts the check at each consumer's outermost assignment; the swallow-idiom lint for the conformance card is a release follow-up | CHEAP / HIGH |

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8020 × #8021 on `core/deploy/tests/test_lib_instance_path.sh`):** With the switch at its shipped default, every routed tool resolves the same hub-state, event-log and register paths as the pre-change code on the same fixture inputs, and produces byte-identical output, on the default tier and on each override rung the tool honors today. The resolver can return no container leaf it could not return before, and a control arm that perturbs one resolved path is caught by the same comparison. *Method:* `grep -c -F "CIAC-1 switch-off parity" core/deploy/tests/test_lib_instance_path.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#8020 × #8021 on `core/deploy/lib-instance-path.sh`):** No routed tool constructs a hub-state, event-log or register path in executable code; each obtains it from a function the resolver defines. The arm scans the nine tools' non-comment lines for a path assembled from the container leaf or the hub-state, evals-results or registers leaf. It excludes header documentation and the self-test literals that pin each rung's expected value, and its control plants one assembled path in a fixture copy and must be flagged. *Method:* `grep -c -F "CIAC-2 single resolution site" core/deploy/tests/test_lib_instance_path.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#8020 × #8021 on `core/config/operator.toml.template`):** The switch ships off in the template and in the schema's default, and an absent or empty switch reads as off. No header, template comment or doc this release changes tells an operator to set it. The arm checks the shipped value and scans the changed headers for a flip instruction, and its control seeds one in a fixture copy and must be flagged. *Method:* `grep -c -F "CIAC-3 default-off" core/deploy/tests/test_lib_instance_path.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#8020 × #8021 on the test environment of both cards' arms):** Every test arm either card adds or extends runs with HOME, the workspace root and both XDG bases pointed at a fixture root and the direct overrides unset, and shows that no file outside the fixture root changed. Its control writes one file outside the root and must be caught. *Method:* `grep -c -F "CIAC-4 sandbox parity" core/deploy/tests/test_lib_instance_path.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*

Each method is a label-presence probe; the arm's behavior is graded by the suite's own CI run (install-tests, through the install-regression runner). #8026's wave-3 conformance test may later absorb CIAC-2's arm.

Lint record (G4-06), from `release/tools/verify-release-plan.sh --ciac-lint` on the Stage-4 drafted plan, and re-run on this committed file at Stage-6 A1 (§ Verification Evidence):

    CIAC-LINT-SUMMARY	declared=4	parsed=4	clean=4	declared-deferral=0	flagged=0

**Integration criterion INT-1 (#8020 vs #8017).** On `core/standards/instance-data-placement-standard.md` (the class table and the Surface register), the resolver's served-member table and each member's governed home equal the register rows they name — S-01, S-02 (`release-runs-templates`), S-03, S-04, S-05/S-16, S-07, S-20, S-45, S-06/S-38, S-08, S-09, S-10/S-15/S-33 and S-19 — so no member resolves to a governed path the register does not state, and every served row's class matches its class function. Graded at Stage 8 Phase B.

## Verification Plan

**AC baseline.** The counts read at plan time against `8ed5e273`: #8020 5 · #8021 3. The counts the cards carry at Commit 0, after the plan-gate refinement and the scope-lock body text: #8020 12 · #8021 4. Each criterion is bound by its own row below; a later amendment of either side updates the other in the same change.

`ac_baseline: { #8020: 12, #8021: 4, read_at: 7499df9f74d5089d46f358956efb43104ef5787e }`

**Arm-label convention.** Test arms carry the labels below verbatim.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8020 | AC-1 | `grep -c -F "8020-AC1 one resolver per served class" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; it asserts the five class-resolver functions and the run-class argument, and that the Operator PMO content resolvers still answer as before (the diff carrying no hunk in their bodies is a Stage 8 named read) |
| #8020 | AC-2 | `grep -c -F "8020-AC2 switch unset" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; its per-member, per-rung pins and its perturbed-copy sensitivity row run in install-tests |
| #8020 | AC-3 | `grep -c -F "8020-AC3 switch set" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; fixture repository `local-state/` and fixture XDG roots |
| #8020 | AC-4 | `grep -c -F "8020-AC4 embargoed run" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; the leak-risk home is returned in both switch states |
| #8020 | AC-5 | `grep -c -F "governed_homes" core/config/operator-toml-schema.json` at least 1 | declared in the schema; the template line and the parity check (`check-operator-toml-schema.sh --repo-integrity`, its CI run) grade the rest |
| #8020 | AC-6 | `grep -c -F "8020-AC6 work-tree refusal" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; a planted in-tree leak-risk root fails loud |
| #8020 | AC-7 | `grep -c -F "8020-AC7 designated main checkout" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; a relocated-checkout fixture |
| #8020 | AC-8 | `grep -c -F "8020-AC8 fixture-root containment" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; its detector controls fire on their sensitivity inputs |
| #8020 | AC-9 | `grep -c -F "class-homes-switch-and-designation" core/ADRs/README.md` at least 1 | the index entry exists; the record's status and sections are a Stage 8 named read |
| #8020 | AC-10 | `grep -c -F "governed_homes" docs/platform-config-reference.md` at least 1 | the catalog row exists; its schema twin and the third-person wording are graded by the CIAC-3 arm |
| #8020 | AC-11 | `grep -c -F "8020-PR1 deploy.sh refusal" core/deploy/tests/test_lib_instance_path.sh` at least 1 | the arm is present; its mutation controls fail; `build-process-catalog.py anchors resolve --check` reads no moved or gone citation (its CI run) |
| #8020 | AC-12 | `grep -c -F "A4 structure" core/hooks/tests/git-pre-commit-pii-env-inputs.test.sh` at least 1 | group A is present; its positive rows fail against the guard as it stood before this release (Stage 7 runs them against `origin/main`'s guard) |
| #8021 | AC-1 | `grep -c -F "CIAC-2 single resolution site" core/deploy/tests/test_lib_instance_path.sh` at least 1 | no listed tool builds a hub-state, event-log or register path itself |
| #8021 | AC-2 | `grep -c -F "CIAC-1 switch-off parity" core/deploy/tests/test_lib_instance_path.sh` at least 1 | each tool's suite passes with no assertion weakened, and the before/after comparison is byte-identical on every rung |
| #8021 | AC-3 | [DEFERRED — graded at Stage 7 by the switch-set fixture rows #8021's design places in core/deploy/tests/test_lib_instance_path.sh] | each tool reads and writes under the fixture's `/local-state/` |
| #8021 | AC-4 | [DEFERRED — the 8021-CD1 arm lands with #8021's commits; graded at Stage 7 by that arm and each tool's self-test] | a refused event-log path makes the two consumers exit non-zero naming the read; output unchanged with the switch off |

**Before/after comparison (constraint 1).** Each routed tool's path-resolution entry point runs at the base commit and at the head on byte-identical fixture inputs and is compared byte for byte, on the default tier and on one row per override rung the tool honors today. Its control perturbs one resolved path in a fixture copy of the resolver and must be caught; a comparison whose control also matches is a broken probe. It runs once at Stage 7 on a full clone.

**Fixture pointing.** Every arm exports the fixture environment (§ Risk Register R4). No live path is passed to any tool.

## Delivery Strategy · Rollback Strategy

- **Branch and PR:** single branch `release/one-resolver-and-release-tool-routing`; Engineering Commit 0 is this file; ordered commits, #8020's slices then #8021's; one PR, opened in draft after Commit 0, merged once.
- **Stage 7/8:** one spoke per card, parallel-eligible after Engineering.
- **Stage 12:** a plain merge, in a quiet window (R5), with the schema `since` value restamped to the claimed version if the claim lands on a number other than the one authored (Collective Review fix package, R5 release item).
- **Rollback:** a single-PR revert of the merge commit restores the resolver, template, schema, consumers and tools. No data moves while the switch is off, and no new file lands in the container. A hub that synced main between the merge and the revert runs the new code until it re-syncs. Tier **MODERATE**, rollback feasible. A switch flipped before its guard shipped would make rollback EXPENSIVE (data to move back), which is why it ships off.

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A) [ASSUMPTION – CONFIRM] — basis UNSTATED, so the conservative default applies and no draw figure is rendered. PASS rests on the ordinal estimate: the worst batch is two `size:L` spokes, the smallest non-singleton batch a two-card release can form.
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 1 (serialized by the interface dependency) · Stage 7: 2 · Stage 8: 2
**Per-spoke cost estimate:** size-bucket ordinal band `size:L` = moderate–high (source: heuristic; no telemetry median used)
**Assumed/stated remaining usage-window envelope:** UNSTATED → the conservative default (W_max 2)
**Estimated cumulative draw % (worst parallel batch):** not synthesized; the basis is UNSTATED
**Routing:** PASS: proceed
**Note:** Checkpoint B re-validates at every `Agent`-tool launch, wave or singleton, at every stage, and also gates on the host-API axis at runtime. The bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Release Outcome Statement (approved at the Stage-4 gate)

**AFTER** — Every release tool that reads or writes hub state, the pipeline event log or the close-out registers gets its path from one resolver per data class, which takes a run class and sits behind a per-repository switch that ships off. With the switch off, every tool resolves exactly today's paths and keeps today's override order (ADR-231 carried-forward clause 2), but no tool spells a home itself any more, so a later cutover flips one switch per repository instead of editing each tool.

**BEFORE** — There is one container resolver, and four release tools build their own hub-state, register or container paths through override orders that differ, so two tools can resolve different hub-state roots under the same overrides and moving a home means editing every tool.

**Actor(s):** hub + novel-class spokes.

**Success Indicator:** at Stage 13, the CIAC-1 switch-off parity arm and the CIAC-2 single-resolution arm pass on the merged head, and the release's test runs changed no file outside their fixture roots (CIAC-4).

**Limb owners:** one resolver per class with the switch and run class → #8020 · tools obtain paths from the resolver → #8021 · switch-off parity → #8020, #8021.

## Release Class declaration

**Release Class:** novel (D-ReleaseClass). Trigger (b): at least one D-class decision in the plan (D-ResolverScope, D-FinopsStoreArm). Not cross-cutting: no pipeline stage file and none of the six rule-defining surfaces is edited, and the bundle carries one in-bundle edge. Not routine: both cards are `size:L` and new D-decisions exist. Per-class posture: engagement Standard, Stage 9 Deep, Stage 5 ALL, a 30-day outcome window.

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-27, Friday local)

Recorded on #9202: plan approved; Release Outcome Statement approved in the hub-revised form above; **D-ReleaseClass** novel; **D-ResolverScope (A)** — amend the resolver card to its full assignment; **D-FinopsStoreArm (A)** — narrow the routing card's first criterion, with the usage-store family a release follow-up. Recorded determinations (hub): **D-Version** versioned, WV-1, bump `minor`, provisional `v5.15`; **D-C** SINGLE; **D-Concurrency** P0. Hub-added commitments: AI-001 (no merge while a sibling sits between its Stage-12 merge and its Stage-13 close-out) and AI-002 (event-log rows emitted only from tool copies identical to `origin/main` until this release merges).

### Collective Review, round 1 (operator, 2026-11-27, Friday local)

Recorded on #9202: return both cards to Solutioning with rulings. **D-BlastTier** structural, accepted. **SC-1** a decision record for the resolver contract, accepted. **SC-2** two configuration-catalog rows, accepted. **PR-1** the two `deploy.sh` swallow sites, fixed in this release. **R4** the PII guard's anchored read, fixed in this release. **D-ConfigRoot (D)** split by arm. **CD-2** refuse a family-wide relocation under the governed arm. **CD-3** a positive, fail-closed run-class record. **CD-4** run-scoped members name their repository once the switch is non-empty. The fix package for both cards accepted with the disposition. Hub-added control AI-003: every Stage 6–8 brief sets `PMO_REGRESSION_EMIT=0`.

### Collective Review, round 2: scope lock (operator, 2026-11-28, Saturday UTC)

Recorded on #9202: scope hard-locked through Stage 9 and Engineering authorized. **D-RepoSource (ii)** — the target-checkout swap becomes a Stage-5 input to the platform-flip card. **Resolver card size** kept at L, with the rubric deviation recorded (DEV-11). Binding Stage-6 inputs: FM-B, FM-C, FM-D, FM-E, FM-F, INT-5 graded on the platform-flip card's Stage-5 input, the derived rows D-v1-HomePin, D-v1-WsRoot, D-v1-RepoAlways and D-v1-Token kept, R-v1-Lines, and `PMO_REGRESSION_EMIT=0` in every Stage 6–8 brief.

## Release follow-ups (Stage 9 ledger; filed at Stage 13)

| ID | Follow-up | Owner card or wave | Source |
|---|---|---|---|
| FU-1 | Route the usage-store path the four usage-extractor scripts build inline (the rollup's store arm, and the estimate, extract and report scripts) through the install-scoped resolver, before the wave-3 conformance test lands | the consumer-routing wave | D-FinopsStoreArm (A); `[BUNDLE AMENDMENT]` |
| FU-2 | A swallow-idiom lint for the conformance card: flag `local x="$(pmo_…)"`, `"$(pmo_…)/leaf"` and an unchecked capture inside a function a script without `-e` calls, over every switch-aware function; first sensitivity rows `core/deploy/tests/test_check19_event_log_integrity.sh` (its two live-log reads) and the PII guard's unanchored needle read | the conformance card (#8026) | PR-1's paired lint; FM-C (round-2 binding input) |
| FU-3 | The consumer-routing card's Stage-5 inputs: discovery consolidation (D-6); the PreToolUse scope-segregation hook's unanchored needle read; converting the telemetry and analysis wrappers needs their bodies moved to private today-arm functions first (erratum E1); the needle and roster accessors become switch-aware there | the consumer-routing card (#8025) | D-6; R4 coverage; erratum E1 |
| FU-4 | The anchored PII floor's leak-risk source after the leak-risk class cuts over: the container is not retired until it is decided | the leak-risk migration card (#8032) | D-v1-HomePin; FM-D |
| FU-5 | The target-checkout `--repo` swap at each run-scoped call site | the platform-flip card (#8034) | D-RepoSource (ii); INT-5 |

## Deviation Log

| ID | Stage | Deviation | Decision |
|---|---|---|---|
| DEV-1 | 4 | **Plan-gate body refinements.** #8020's body: the served-class set named; the switch-off criterion per member and per override rung; the leak-risk home in its XDG-rooted form with fixture roots; the work-tree refusal, designated main checkout, isolation-key answer and sandbox-parity criteria added; the no-new-member risk line. Criteria 5 → 8. #8021's body: evidence re-measured at `8ed5e273`; route class per listed file; first criterion narrowed to hub-state, event-log and register paths; the before/after parity comparison added to the switch-off criterion | operator, Stage-4 plan gate; applied by the hub under the `[BUNDLE AMENDMENT]` (issues added 0, removed 0) |
| DEV-2 | 4 | **Milestone-description sections.** The Release Outcome Statement, the release-identity line, `## Release Class` (novel), `## Parallelization Map (recorded 2026-11-27)` and the A6 quota line, appended after the Composition Lock block with the prior text intact | operator, Stage-4 plan gate; hub |
| DEV-3 | 4 | **D-ResolverScope (A).** #8020 carries the full resolver assignment ADR-231 and the placement standard give it — three served classes, the XDG-rooted leak-risk home, the work-tree refusal, the designated main checkout, the isolation-key answer, and this slice's share of the sandbox-parity and loud-failure obligations | operator, Stage-4 plan gate |
| DEV-4 | 4 | **D-FinopsStoreArm (A).** #8021's first criterion is narrowed to hub-state, event-log and register paths; the usage-store family is a release follow-up (FU-1) | operator, Stage-4 plan gate |
| DEV-5 | 5 | **Collective Review round 1 rulings.** Scope additions SC-1 (a decision record and its index entry), SC-2 (two configuration-catalog rows), PR-1 here (the two `deploy.sh` event-log reads, in place) and R4 here (the PII guard's anchored read and its env-inputs suite); D-ConfigRoot (D) (the governed arm reads every key through the config root and refuses a config-root sandbox with no XDG base); CD-2 (a set family-wide relocation is refused under the governed arm; one direct-override set per member); CD-3 (a positive, fail-closed run-class record, a reserved contract); CD-4 (run-scoped members require `--repo` once the switch is non-empty); the fix package (FM-1 the check at each consumer's outermost assignment; FM-2 a filesystem walk decides the work-tree refusal; PR-4 S-02 as its own member; FM-4 git's config and hook routes closed in the fixtures; FM-5 and FM-6 as written; the routing card's D-1 to D-6, CD-1, CD-2, FM-1 to FM-6 and PR-2). #8020's write set grows from 4 to 12 surfaces and its body gains four criteria (8 → 12); #8021 gains a fourth criterion | operator, Collective Review round 1; Stage-5 revision 1 |
| DEV-6 | 5 | **Implementation Sequence** re-ordered to the Stage-5 revision-1 order of work (§ Implementation Sequence) | Stage-5 revision 1, Tier 1 |
| DEV-7 | 6 | **File Change Matrix — #8020 rows.** The eight paths SC-1, SC-2, PR-1 and R4 add enter the unconditional set; `core/deploy/deploy.sh` leaves the release-wide non-scope block, rewritten in place with its line count held; `CONDITIONAL:NEW_RESOLVER_FUNCTION` fired and its row is promoted | Collective Review round 1; Stage-5 revision 1 |
| DEV-8 | 6 | **File Change Matrix — unfired conditionals resolved.** `NEW_PATH_TOKEN` did not fire (the switch is not an `operator_instance_*` key and no `[paths]` key is added), so `depersonalization-spec.md` is non-scope; `EVALS_CASCADE_REPOINTED` did not fire (no rename, and the switch-off arm is byte-identical), so `test_instance_path_roundtrip.sh` is non-scope; `NEW_TEST_SCRIPT` did not fire (every arm stays in the resolver test), so the new suite and its allowlist row are non-scope; `FINOPS_ARM_B` did not fire (D-FinopsStoreArm A), so the three usage-extractor scripts are non-scope. `SKILL_VERSION_BUMP` fired (the routing card's D-4: the skill's version bump, restamped at Stage 12) and `core/skills/finops-usage-extractor/SKILL.md` is promoted. `core/deploy/tests/test_lib_instance_path.sh` carries #8021's arms as well | Stage-5 designs on #9204 and #9222 |
| DEV-9 | 5 | **Round-2 D-RepoSource (ii).** The run-scoped release tools pass their own checkout as `--repo` (R1 kept at the call sites); the target-checkout swap becomes a Stage-5 input to the platform-flip card (#8034, FU-5). The decision record's entry-gating item therefore states the platform clause against that card's input, and INT-5 is graded on that input, not on a sentence in the record | operator, Collective Review round 2 |
| DEV-10 | 5 | **Round-2 binding Stage-6 inputs.** FM-B: the containment detector also watches the live designated checkout's ignored `local-state/` and `analysis/`. FM-C: the swallow-idiom lint is a release follow-up for the conformance card (FU-2), and `test_check19_event_log_integrity.sh` joins the decision record's consumer list. FM-D: the decision record gains a gating clause for the PII anchored floor's `HOME` pin (FU-4). FM-E: a missing resolver library is not read as a legitimate empty — that change sits in `release/tools/query-pipeline-event.sh`, #8021's file. FM-F: four wording fixes in frozen interface v2, applied in the resolver header and the decision record. The derived rows D-v1-HomePin, D-v1-WsRoot, D-v1-RepoAlways and D-v1-Token are kept. R-v1-Lines binds Stage 6 and Stage 7 | operator, Collective Review round 2 |
| DEV-11 | 5 | **Size-rubric deviation.** The size rubric reads the resolver card as XL by its second limb (the PII-guard hardening could ship on its own). The operator keeps it at L knowingly: the hardening is two surfaces the operator deliberately kept in this release, and L describes the release's capacity draw honestly | operator, Collective Review round 2 |
| DEV-12 | 6 | **Branch base.** The release branch was cut at `7499df9f`, not at the Stage-4 baseline `8ed5e273`. The window is the merge of `issue-body-is-the-scope-of-record`; of this matrix it touches only `core/ADRs/README.md`, the overlap the Stage-5 design had serialized behind it (that release's index entry now sits after this release's insertion point, so the two do not share a hunk). The release branch did not exist on the remote at Commit 0 (the hub's local branch sat at `8ed5e273`); Commit 0's push creates it, and `7499df9f` descends from `8ed5e273` on its first parent | Stage-6 spoke, recorded determination |
| DEV-13 | 6 | **Stage-6 spec steps not run by this spoke, with reason.** The A1–A2 operator checkpoint is discharged by the Collective Review scope lock, which authorized Engineering; the A2 decomposition container is this plan's Implementation Sequence plus the Stage-6 sub-task, with no new sub-issues created; the `test-run` event is handed to the hub as a payload rather than emitted (AI-002, R13); a full `deploy.sh --check` is not run locally (it appends to the live warn log) and CI runs it | Stage-6 brief; hub controls |

## Verification Evidence

### Engineering Commit 0

- **Stamp manifest (step 3b):** `release/tools/claim-version.sh --verify-stamp one-resolver-and-release-tool-routing` — its verdict line is quoted in the Commit 0 message.
- **Plan verifier, Commit-0 families:** `release/tools/verify-release-plan.sh` on this file (no `--emit-events`, so no event-log write; no row declares the deploy check) — the provenance-survival, fcm-delivery and per-issue families; and `--ciac-lint` on this file. Their summary lines are quoted in the Commit 0 message. The per-issue label-presence rows read their floors only once the arms land, so at Commit 0 they are expected to read short; the row set is the binding, not the count.

Later slices append their verification under this heading.
