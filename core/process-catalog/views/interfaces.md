---
title: Interfaces
purpose: Sub-process boundaries, hand-offs between sub-processes and external system roles, per universe
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Interfaces

Where the pieces meet: each sub-process's entry and exit, the hand-offs its page declares, and every external system role and external trigger with the pages and steps that touch it.

| Universe | Sub-process pages | Boundary rows | Hand-offs | External roles | External triggers |
|---|---|---|---|---|---|
| Engineering harness | 11 | 25 | 17 | 4 | 3 |

## Engineering harness

### Sub-process boundaries

The Entry and exit rows of each sub-process page, criteria cut to 24 words.

| Sub-process | Value stream | Side | Criteria |
|---|---|---|---|
| [install-platform](../engineering-harness/install-platform.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Entry | A clone with its marker files, on macOS with `python3`, `shasum`, `git` and `jq` (exit 78 / 69 / 66 otherwise); `./install.sh` run from … |
| [install-platform](../engineering-harness/install-platform.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Exit | `.workspace-setup.state` carries `verification_passed: true`; `deploy.sh` reported the full roster deployed; `validate-install.sh` Mode A is PASS (the documented fourth command); the next step is the … |
| [update-platform](../engineering-harness/update-platform.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Entry | A workspace previously bootstrapped (`operator.toml` present, else exit 65); the clone pulled to the newer version; `./update.sh` run from the clone root with the … |
| [update-platform](../engineering-harness/update-platform.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Exit | Exit 0 with ≥ 1 regeneration, skill deploy, hook refresh, settings delta or legacy retirement; or 64 with none; or 75 naming an absent … |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Entry | The script runs from the repository root with one of: no arguments (bare), artifact names, `--all`, or `--release <slug>` with named targets or `--no-targets` … |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Exit | Every selected artifact is byte-identical at its targets (copy verified, residual assertion clean), the rules mirror is laid down, the summary line is printed … |
| [verify-session-setup](../engineering-harness/verify-session-setup.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Entry | A session starts with a project root that resolves `<workspace>/.claude/settings.json`, rendered from the template at install and re-rendered by `update.sh` Phase 5d; the SessionStart … |
| [verify-session-setup](../engineering-harness/verify-session-setup.md) | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) | Exit | The session is running; each hook exited 0 (warn mode) with its notice written to stderr, or silently; a skew notice, when present, names … |
| [run-check-suite](../engineering-harness/run-check-suite.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Entry | The dispatcher receives `--check` (optionally `--warn`, which clears `STRICT`); `validate_workspace` passes; `detect_install_path` may return non-zero without aborting; errexit is disabled for the check body … |
| [run-check-suite](../engineering-harness/run-check-suite.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Entry (mode) | `DEPLOY_CHECK_MODE` resolved from the shared mode file, else `warn`; a per-check `<check-id>.mode` file outranks it in both directions; `off` skips every mode-gated check … |
| [run-check-suite](../engineering-harness/run-check-suite.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Exit | `All checks passed.` and exit 0 when `ISSUES` is 0; otherwise `N issue(s) found.` and exit 1 under STRICT, exit 0 under `--warn`; every … |
| [run-check-probes](../engineering-harness/run-check-probes.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Entry (CI) | A pull request opened, synchronized, reopened or marked ready, or a push to main, on a workflow whose trigger matches (three probe workflows are … |
| [run-check-probes](../engineering-harness/run-check-probes.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Entry (pipeline or operator) | Stage 13 Phase A8.2 runs the decision-emission probe and the deployment rule names `--report` as Stage 13 evidence; the operator runs `--check-lifecycle` or `--self-test` … |
| [run-check-probes](../engineering-harness/run-check-probes.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Exit | One exit code per the probe's contract table (0 clean; 2 advisory; 3 withheld; 4 asserted nothing; 1 blocking or unexpected), consumed by the … |
| [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Entry | A review window is reached — Check 71 or 74 prints GRADUATION-DUE, a gate's own `2–3 release` threshold elapses, or the hook checklist's three … |
| [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) | Exit | The gate's flip-decision row carries a closed-set token with its rationale and, where a flip happened, the committed default, sentinel token, mode-file value or … |
| [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) | [observe-platform](../engineering-harness/observe-platform.md) | Entry | A registered routine's task fires on the operator's scheduler (the row declares the cadence; the instance resolves it), an out-of-band drift signal, or an … |
| [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) | [observe-platform](../engineering-harness/observe-platform.md) | Exit | A dated audit folder (or a due-signal draft) exists under the operator-instance analysis path with its observation drafts, and the operator has rendered PROMOTE … |
| [run-security-scan](../engineering-harness/run-security-scan.md) | [observe-platform](../engineering-harness/observe-platform.md) | Entry | Monday 06:00 UTC on the default branch (`schedule: cron '0 6 * * 1'`); the routine is admitted by its registry row, whose cadence … |
| [run-security-scan](../engineering-harness/run-security-scan.md) | [observe-platform](../engineering-harness/observe-platform.md) | Exit | Seven job conclusions recorded on the run; the operator has read them; the workflow created nothing else |
| [run-session-retro](../engineering-harness/run-session-retro.md) | [observe-platform](../engineering-harness/observe-platform.md) | Entry (automatic) | A Stop event in a session that loaded the workspace-scope settings, with `[session_retro] enabled = true` and `mode` not `off`; the session clears the … |
| [run-session-retro](../engineering-harness/run-session-retro.md) | [observe-platform](../engineering-harness/observe-platform.md) | Entry (manual) | The operator asks for the retro; the threshold never overrides a direct instruction |
| [run-session-retro](../engineering-harness/run-session-retro.md) | [observe-platform](../engineering-harness/observe-platform.md) | Exit | At least one `session-retro` row appended (a `no-learning` row when nothing was found) and the output report rendered; on a sampled skip, nothing at … |
| [measure-platform-usage](../engineering-harness/measure-platform-usage.md) | [observe-platform](../engineering-harness/observe-platform.md) | Entry | The operator asks a spend, budget or compliance question by name, or, for the two auditors, a scheduled run on the schedule seam (none … |
| [measure-platform-usage](../engineering-harness/measure-platform-usage.md) | [observe-platform](../engineering-harness/observe-platform.md) | Exit | A report printed to stdout or written to the project's generated-artifact folder with its method and provenance; for the extractor, the store rewritten or … |

### Hand-offs between sub-processes

The `precedes` and `triggered_by` links whose two ends are sub-processes, as the pages declare them.

| Sub-process | Link | Other sub-process |
|---|---|---|
| [install-platform](../engineering-harness/install-platform.md) | precedes | [update-platform](../engineering-harness/update-platform.md) |
| [update-platform](../engineering-harness/update-platform.md) | is triggered by | [verify-session-setup](../engineering-harness/verify-session-setup.md) |
| [update-platform](../engineering-harness/update-platform.md) | precedes | [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | is triggered by | run-execute |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | is triggered by | [install-platform](../engineering-harness/install-platform.md) |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | is triggered by | [update-platform](../engineering-harness/update-platform.md) |
| [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) | precedes | [verify-session-setup](../engineering-harness/verify-session-setup.md) |
| [verify-session-setup](../engineering-harness/verify-session-setup.md) | precedes | [update-platform](../engineering-harness/update-platform.md) |
| [run-check-suite](../engineering-harness/run-check-suite.md) | is triggered by | run-engineering |
| [run-check-suite](../engineering-harness/run-check-suite.md) | is triggered by | run-close |
| [run-check-suite](../engineering-harness/run-check-suite.md) | precedes | [run-check-probes](../engineering-harness/run-check-probes.md) |
| [run-check-probes](../engineering-harness/run-check-probes.md) | is triggered by | run-close |
| [run-check-probes](../engineering-harness/run-check-probes.md) | precedes | [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) |
| [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) | is triggered by | run-close |
| [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) | is triggered by | [run-check-suite](../engineering-harness/run-check-suite.md) |
| [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) | precedes | [run-security-scan](../engineering-harness/run-security-scan.md) |
| [run-session-retro](../engineering-harness/run-session-retro.md) | precedes | [measure-platform-usage](../engineering-harness/measure-platform-usage.md) |

### External system roles

Each `external:` actor, with the pages whose `actors` name it and the Steps rows that name it.

| Role | Pages | Steps |
|---|---|---|
| `external:desktop-app` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) · [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) | — |
| `external:repo-host` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [verify-session-setup](../engineering-harness/verify-session-setup.md) · [notify-version-skew](../engineering-harness/notify-version-skew.md) · [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [run-check-suite](../engineering-harness/run-check-suite.md) · [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) · [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) · [run-check-probes](../engineering-harness/run-check-probes.md) · [run-single-check-probe](../engineering-harness/run-single-check-probe.md) · [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [reconcile-gate-posture](../engineering-harness/reconcile-gate-posture.md) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) · [observe-platform](../engineering-harness/observe-platform.md) · [run-security-scan](../engineering-harness/run-security-scan.md) · [run-security-jobs](../engineering-harness/run-security-jobs.md) · [route-scan-verdicts](../engineering-harness/route-scan-verdicts.md) | [run-security-jobs](../engineering-harness/run-security-jobs.md) (fire-workflow) |
| `external:scheduler` | [observe-platform](../engineering-harness/observe-platform.md) · [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) · [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) · [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) | — |
| `external:work-tracker` | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [run-check-suite](../engineering-harness/run-check-suite.md) · [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) | — |

### External triggers

| Trigger | Pages it triggers |
|---|---|
| `external:fresh-clone` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [install-platform](../engineering-harness/install-platform.md) · [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) |
| `external:newer-release` | [update-platform](../engineering-harness/update-platform.md) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) |
| `external:repo-host` | [run-security-jobs](../engineering-harness/run-security-jobs.md) |
