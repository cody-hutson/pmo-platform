---
title: Data flow
purpose: Artifacts and records with the pages and steps that produce and consume them, per universe
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Data flow

Artifacts and records named in the ICOM tables and the Steps rows of the activity pages, with the pages and steps that produce and consume each. Matching is conservative: two items match when their names are equal after link markup, parentheticals, code-span marks, outer punctuation and a leading article are dropped and the name has two or more words, or when they name the same code span or file. A match needs a producer and a consumer at different places. A "Produced by" place is a step or an ICOM table whose text names the item as an output; it may read, check or run the item rather than produce it.

| Universe | Items | Records matched | Artifacts matched | Items matched | Items unmatched |
|---|---|---|---|---|---|
| Engineering harness | 1646 | 34 | 3 | 103 | 1543 |

## Engineering harness

### Named records (code spans and file names)

| Record | Produced by | Consumed by |
|---|---|---|
| `$CLAUDE_EFFORT` | [verify-session-config](../engineering-harness/verify-session-config.md) (parse-launch-payload) | [verify-session-config](../engineering-harness/verify-session-config.md) (ICOM) |
| `.gitleaks.toml` | [run-security-jobs](../engineering-harness/run-security-jobs.md) (scan-change-for-secrets) | [run-security-jobs](../engineering-harness/run-security-jobs.md) (ICOM) |
| `.version` | [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (ICOM) | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (ICOM) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (ICOM) · [notify-version-skew](../engineering-harness/notify-version-skew.md) (ICOM, locate-version-file) |
| `.workspace-setup.state` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (ICOM, verify-and-record-state) | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (route-by-state-marker) · [validate-install](../engineering-harness/validate-install.md) (assert-state-and-config) |
| `<workspace>/.claude/.version` | [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (refresh-version-snapshot) | [notify-version-skew](../engineering-harness/notify-version-skew.md) (locate-version-file) |
| `CHANGED_HARNESS` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (ICOM, classify-named-artifacts) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) |
| `CHANGED_PACKAGES` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (ICOM) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) |
| `CHANGED_SKILLS` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (ICOM, classify-named-artifacts, select-full-roster, scan-ground-truth-drift) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) |
| `CLAUDE.md` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (ICOM, compose-context-and-settings) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (guard-repo-root) | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (verify-and-record-state) · [validate-install](../engineering-harness/validate-install.md) (assert-context-files) |
| `DELETED_SKILLS` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (ICOM) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM, warn-deleted-skills) |
| `DEPLOY_RELEASE_SLUG` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (parse-release-flags) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) |
| `FAILURES` | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (copy-skill-to-session-path, carry-supplementary-content) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (fail-on-deployment-failures) |
| `INSTALL_PATH` | [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (resolve-session-install-path) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) |
| `MANUAL` | [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) (ICOM, emit-binding-records) | [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) (register-routine-task) |
| `SKILL.md` | [measure-context-budget](../engineering-harness/measure-context-budget.md) (flag-bloat-candidates) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (carry-supplementary-content) · [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) (verify-skill-sync) · [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) (ICOM, verify-canonical-structure, detect-mode-invocation-drift) · [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) (ICOM) |
| `[adapters].scheduler` | [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) (register-routine-task) | [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) (ICOM, read-selector) |
| `__before_fp` | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (snapshot-deployed-footprint) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (count-changed-footprint) |
| `audit_baseline_date` | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (load-registry-and-baseline) | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (ICOM) |
| `audit_baseline_sha` | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (load-registry-and-baseline) | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (ICOM) |
| `core/hooks/*.sh` | [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (refresh-hook-bundle) | [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (ICOM) |
| `deploy.sh` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (enter-skill-deploy) | [validate-install](../engineering-harness/validate-install.md) (run-deploy-check) · [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) (ICOM) · [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) (ICOM) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) (commit-enforce-default) |
| `enabled` | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (read-activation-config) | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (ICOM) |
| `fired/<session-id>` | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (write-fire-sentinel) | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (check-fire-sentinel) |
| `latest_version` | [notify-version-skew](../engineering-harness/notify-version-skew.md) (parse-latest-tag) | [notify-version-skew](../engineering-harness/notify-version-skew.md) (compare-and-notify) |
| `lib/dep-resolve.sh` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (install-hook-bundle) | [verify-session-config](../engineering-harness/verify-session-config.md) (resolve-json-reader) |
| `mode` | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (read-activation-config) | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) (ICOM) |
| `operator-pre-existing` | [validate-install](../engineering-harness/validate-install.md) (assert-state-and-config) | [validate-install](../engineering-harness/validate-install.md) (ICOM) |
| `operator.toml` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (ICOM) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) (ICOM, regenerate-on-source-change) | [validate-install](../engineering-harness/validate-install.md) (assert-state-and-config) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) (ICOM, preflight-update) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) (ICOM, resolve-session-install-path) · [notify-version-skew](../engineering-harness/notify-version-skew.md) (ICOM, resolve-repo-identity) · [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) (ICOM, read-selector) |
| `operator_github` | [notify-version-skew](../engineering-harness/notify-version-skew.md) (resolve-repo-identity) | [notify-version-skew](../engineering-harness/notify-version-skew.md) (ICOM) |
| `platform-config.toml` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (choose-hook-activation) | [verify-session-config](../engineering-harness/verify-session-config.md) (ICOM) |
| `references/` | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (ICOM) | [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) (ICOM) |
| `session-retro` | [emit-session-learnings](../engineering-harness/emit-session-learnings.md) (ICOM) | [emit-session-learnings](../engineering-harness/emit-session-learnings.md) (synthesize-cross-session-patterns) |
| `settings.json` | [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (ICOM) | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) (verify-and-record-state) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) (ICOM) |
| `skills_changed` | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (count-changed-footprint) | [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) (print-summary) |

### Artifacts by name (two or more words, equal after normalization)

| Artifact | Produced by | Consumed by |
|---|---|---|
| cache json | [notify-version-skew](../engineering-harness/notify-version-skew.md) (fetch-latest-release) | [notify-version-skew](../engineering-harness/notify-version-skew.md) (parse-latest-tag) |
| drift items | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (re-enumerate-roster-and-diff) | [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) (classify-drift) |
| exit code | [run-required-subset](../engineering-harness/run-required-subset.md) (ICOM) | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) (decide-workflow-gate) · [run-required-subset](../engineering-harness/run-required-subset.md) (decide-subset-gate) |
