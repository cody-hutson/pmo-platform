---
title: Structure
purpose: Depicted files by element kind, with the pages that depict them, per universe
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Structure

The repository files the pages depict, by element kind, with the pages that depict each. A file no page depicts is not listed here; the generator's `coverage` command reports those.

## Engineering harness

### Depicted files

| Element kind | Depicted file | Pages |
|---|---|---|
| skill | `core/skills/context-budget-auditor/SKILL.md` | [measure-platform-usage](../engineering-harness/measure-platform-usage.md) · [measure-context-budget](../engineering-harness/measure-context-budget.md) |
| skill | `core/skills/finops-usage-extractor/SKILL.md` | [measure-platform-usage](../engineering-harness/measure-platform-usage.md) · [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| skill | `core/skills/pmo-qa-auditor/SKILL.md` | [observe-platform](../engineering-harness/observe-platform.md) · [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) · [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) |
| skill | `core/skills/session-retro/SKILL.md` | [run-session-retro](../engineering-harness/run-session-retro.md) · [emit-session-learnings](../engineering-harness/emit-session-learnings.md) |
| skill | `core/skills/skill-compliance-auditor/SKILL.md` | [measure-platform-usage](../engineering-harness/measure-platform-usage.md) · [measure-skill-compliance](../engineering-harness/measure-skill-compliance.md) |
| skill-reference | `core/skills/session-retro/references/emission-contract.md` | [emit-session-learnings](../engineering-harness/emit-session-learnings.md) |
| skill-reference | `core/skills/session-retro/references/sampling-and-trigger.md` | [trigger-session-retro](../engineering-harness/trigger-session-retro.md) |
| skill-reference | `core/skills/skill-compliance-auditor/references/scenario-and-calibration-schema.md` | [measure-skill-compliance](../engineering-harness/measure-skill-compliance.md) |
| skill-asset | `core/skills/context-budget-auditor/scripts/measure-context-budget.sh` | [measure-context-budget](../engineering-harness/measure-context-budget.md) |
| skill-asset | `core/skills/finops-usage-extractor/scripts/estimate-usage.sh` | [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| skill-asset | `core/skills/finops-usage-extractor/scripts/extract-usage.sh` | [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| skill-asset | `core/skills/finops-usage-extractor/scripts/report-usage.sh` | [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| skill-asset | `core/skills/finops-usage-extractor/scripts/rollup-attribution.sh` | [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| skill-asset | `core/skills/skill-compliance-auditor/scripts/measure-skill-compliance.sh` | [measure-skill-compliance](../engineering-harness/measure-skill-compliance.md) |
| skill-asset | `release/skills/pmo-skill-refiner/scripts/run_eval_audit.py` | [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) |
| stage-spec | `release/references/pipeline/stage-13-close.md` | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| hook | `core/hooks/block-destructive.sh` | [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) |
| hook | `core/hooks/git-post-merge-deploy.sh` | [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) · [trigger-post-merge-deploy](../engineering-harness/trigger-post-merge-deploy.md) |
| hook | `core/hooks/notify-version-skew.sh` | [verify-session-setup](../engineering-harness/verify-session-setup.md) · [notify-version-skew](../engineering-harness/notify-version-skew.md) |
| hook | `core/hooks/run-theme-token-fixtures.sh` | [check-public-surface-hygiene](../engineering-harness/check-public-surface-hygiene.md) |
| hook | `core/hooks/session-retro-trigger.sh` | [observe-platform](../engineering-harness/observe-platform.md) · [run-session-retro](../engineering-harness/run-session-retro.md) · [trigger-session-retro](../engineering-harness/trigger-session-retro.md) |
| hook | `core/hooks/verify-session-config.sh` | [verify-session-setup](../engineering-harness/verify-session-setup.md) · [verify-session-config](../engineering-harness/verify-session-config.md) |
| hook-support | `core/hooks/deploy-check.mode.template` | [run-check-suite](../engineering-harness/run-check-suite.md) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) |
| workflow | `.github/workflows/automation-registry-check.yml` | [run-security-scan](../engineering-harness/run-security-scan.md) |
| workflow | `.github/workflows/close-completeness.yml` | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| workflow | `.github/workflows/decision-emission.yml` | [run-check-probes](../engineering-harness/run-check-probes.md) · [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| workflow | `.github/workflows/deploy-check-ci.yml` | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [run-check-probes](../engineering-harness/run-check-probes.md) · [run-required-subset](../engineering-harness/run-required-subset.md) |
| workflow | `.github/workflows/gate-posture-reconciliation.yml` | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [reconcile-gate-posture](../engineering-harness/reconcile-gate-posture.md) |
| workflow | `.github/workflows/release-corpus-completeness.yml` | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| workflow | `.github/workflows/security.yml` | [observe-platform](../engineering-harness/observe-platform.md) · [run-security-scan](../engineering-harness/run-security-scan.md) · [run-security-jobs](../engineering-harness/run-security-jobs.md) · [route-scan-verdicts](../engineering-harness/route-scan-verdicts.md) |
| workflow | `.github/workflows/skill-package-freshness.yml` | [run-check-probes](../engineering-harness/run-check-probes.md) · [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| workflow | `.github/workflows/version-freeness.yml` | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| deploy-tool | `core/deploy/tools/build-skill-packages.sh` | [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) |
| deploy-tool | `core/deploy/tools/check-adr-flip.py` | [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) |
| deploy-tool | `core/deploy/tools/check-approved-queue-depth.py` | [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-automation-registry.sh` | [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) |
| deploy-tool | `core/deploy/tools/check-canonical-structure.sh` | [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/check-citation-anchors.sh` | [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/check-count-structure.py` | [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) |
| deploy-tool | `core/deploy/tools/check-doc-frontmatter.py` | [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) |
| deploy-tool | `core/deploy/tools/check-doc-gates.py` | [run-single-check-probe](../engineering-harness/run-single-check-probe.md) |
| deploy-tool | `core/deploy/tools/check-doc-links.py` | [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) |
| deploy-tool | `core/deploy/tools/check-enum-parity.sh` | [check-orchestration-surfaces](../engineering-harness/check-orchestration-surfaces.md) |
| deploy-tool | `core/deploy/tools/check-extraction-contract.py` | [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) |
| deploy-tool | `core/deploy/tools/check-host-binding.py` | [check-public-surface-hygiene](../engineering-harness/check-public-surface-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-identity-conformance.py` | [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/check-issue-body-anchors.sh` | [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-label-parity.py` | [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-milestone-epic-membership.py` | [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-mirror-pair-parity.py` | [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) |
| deploy-tool | `core/deploy/tools/check-operator-toml-schema.sh` | [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) |
| deploy-tool | `core/deploy/tools/check-ownership-collision.py` | [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/check-registry-currency.sh` | [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) |
| deploy-tool | `core/deploy/tools/check-rules-budget.py` | [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) |
| deploy-tool | `core/deploy/tools/check-tool-exec-mode.py` | [check-public-surface-hygiene](../engineering-harness/check-public-surface-hygiene.md) |
| deploy-tool | `core/deploy/tools/check-work-hierarchy.py` | [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) · [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| deploy-tool | `core/deploy/tools/generate_release_index.py` | [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/lint_release_corpus.py` | [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) |
| deploy-tool | `core/deploy/tools/path-leak-patterns.sh` | [check-public-surface-hygiene](../engineering-harness/check-public-surface-hygiene.md) |
| deploy-tool | `core/deploy/tools/reconcile-gate-posture.py` | [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [reconcile-gate-posture](../engineering-harness/reconcile-gate-posture.md) |
| deploy-tool | `core/deploy/tools/resolve-automation-binding.sh` | [observe-platform](../engineering-harness/observe-platform.md) · [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) · [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) |
| deploy-script | `core/deploy/compose.py` | [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) |
| deploy-script | `core/deploy/composition-surface-manifest.sh` | [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) |
| deploy-script | `core/deploy/deploy.sh` | [engineering-harness](../engineering-harness/engineering-harness.md) · [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) · [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) · [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [run-check-suite](../engineering-harness/run-check-suite.md) · [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) · [check-skill-corpus-integrity](../engineering-harness/check-skill-corpus-integrity.md) · [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) · [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) · [check-public-surface-hygiene](../engineering-harness/check-public-surface-hygiene.md) · [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) · [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) · [check-orchestration-surfaces](../engineering-harness/check-orchestration-surfaces.md) · [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) · [run-check-probes](../engineering-harness/run-check-probes.md) · [run-single-check-probe](../engineering-harness/run-single-check-probe.md) · [run-required-subset](../engineering-harness/run-required-subset.md) · [report-platform-health](../engineering-harness/report-platform-health.md) · [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [review-warn-log-drains](../engineering-harness/review-warn-log-drains.md) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) |
| deploy-script | `core/deploy/lib-composition.sh` | [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) |
| deploy-script | `core/deploy/orchestrate.sh` | [update-platform](../engineering-harness/update-platform.md) |
| release-tool | `release/tools/append-pipeline-event.sh` | [run-session-retro](../engineering-harness/run-session-retro.md) · [emit-session-learnings](../engineering-harness/emit-session-learnings.md) |
| release-tool | `release/tools/check-release-body-drift.sh` | [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) |
| release-tool | `release/tools/compute-milestone-positions.py` | [check-backlog-hygiene](../engineering-harness/check-backlog-hygiene.md) |
| release-tool | `release/tools/query-pipeline-event.sh` | [measure-platform-usage](../engineering-harness/measure-platform-usage.md) |
| release-tool | `release/tools/sweep-release-corpus.py` | [check-release-corpus-integrity](../engineering-harness/check-release-corpus-integrity.md) |
| release-tool | `release/tools/synthesize-release-learnings.sh` | [emit-session-learnings](../engineering-harness/emit-session-learnings.md) |
| standard | `core/standards/composition-surface-spec.md` | [update-platform](../engineering-harness/update-platform.md) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) |
| standard | `core/standards/gate-efficacy-standard.md` | [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [run-check-suite](../engineering-harness/run-check-suite.md) · [check-control-layer-registries](../engineering-harness/check-control-layer-registries.md) · [run-check-probes](../engineering-harness/run-check-probes.md) · [run-required-subset](../engineering-harness/run-required-subset.md) · [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [review-warn-log-drains](../engineering-harness/review-warn-log-drains.md) · [reconcile-gate-posture](../engineering-harness/reconcile-gate-posture.md) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) |
| standard | `core/standards/scheduler-adapter-routine-firing.md` | [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) |
| schema | `core/schemas/automation-registry-schema.md` | [observe-platform](../engineering-harness/observe-platform.md) · [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) · [run-security-scan](../engineering-harness/run-security-scan.md) |
| schema | `core/schemas/finops-usage-store-schema.md` | [extract-token-spend](../engineering-harness/extract-token-spend.md) |
| rule | `core/rules/bypass-mode-readiness.md` | [engineering-harness](../engineering-harness/engineering-harness.md) · [run-platform-health-check](../engineering-harness/run-platform-health-check.md) · [graduate-gate-modes](../engineering-harness/graduate-gate-modes.md) · [review-warn-log-drains](../engineering-harness/review-warn-log-drains.md) · [flip-gate-to-enforce](../engineering-harness/flip-gate-to-enforce.md) |
| rule | `core/rules/doc-link-maintenance.md` | [check-corpus-conventions](../engineering-harness/check-corpus-conventions.md) · [review-warn-log-drains](../engineering-harness/review-warn-log-drains.md) |
| rule | `core/rules/harness-deployment.md` | [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) · [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) · [check-workspace-config-surfaces](../engineering-harness/check-workspace-config-surfaces.md) |
| rule | `core/rules/skill-deployment.md` | [deploy-merged-changes](../engineering-harness/deploy-merged-changes.md) · [trigger-post-merge-deploy](../engineering-harness/trigger-post-merge-deploy.md) · [select-deploy-targets](../engineering-harness/select-deploy-targets.md) · [deploy-skill-artifacts](../engineering-harness/deploy-skill-artifacts.md) · [run-check-suite](../engineering-harness/run-check-suite.md) · [check-deployed-skill-parity](../engineering-harness/check-deployed-skill-parity.md) · [report-platform-health](../engineering-harness/report-platform-health.md) |
| governance | `core/governance/OPERATIONS.md` | [observe-platform](../engineering-harness/observe-platform.md) · [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) |
| release-reference | `release/references/protocols/architecture-conformance-cadence.md` | [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) |
| release-reference | `release/references/protocols/decision-audit-cadence.md` | [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) |
| release-reference | `release/references/protocols/platform-health-audit-framework.md` | [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) · [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) |
| release-reference | `release/references/protocols/process-fitness-cadence.md` | [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) |
| release-reference | `release/references/protocols/structural-audit-cadence.md` | [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) |
| release-reference | `release/references/standards/pipeline-event-log-schema.md` | [check-orchestration-surfaces](../engineering-harness/check-orchestration-surfaces.md) |
| config | `core/config/platform-config.toml.template` | [verify-session-config](../engineering-harness/verify-session-config.md) |
| automation | `core/automations/registry.md` | [engineering-harness](../engineering-harness/engineering-harness.md) · [observe-platform](../engineering-harness/observe-platform.md) · [run-scheduled-audit](../engineering-harness/run-scheduled-audit.md) · [resolve-routine-binding](../engineering-harness/resolve-routine-binding.md) · [run-platform-health-audit](../engineering-harness/run-platform-health-audit.md) · [run-security-scan](../engineering-harness/run-security-scan.md) · [run-security-jobs](../engineering-harness/run-security-jobs.md) · [route-scan-verdicts](../engineering-harness/route-scan-verdicts.md) |
| doc | `docs/INSTALL.md` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [install-platform](../engineering-harness/install-platform.md) · [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) · [validate-install](../engineering-harness/validate-install.md) |
| doc | `docs/ONBOARDING_JOURNEY.md` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [install-platform](../engineering-harness/install-platform.md) |
| doc | `docs/UPDATE.md` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [validate-install](../engineering-harness/validate-install.md) · [update-platform](../engineering-harness/update-platform.md) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) · [verify-session-setup](../engineering-harness/verify-session-setup.md) · [notify-version-skew](../engineering-harness/notify-version-skew.md) |
| doc | `docs/scripts/setup-workspace.sh` | [engineering-harness](../engineering-harness/engineering-harness.md) · [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [install-platform](../engineering-harness/install-platform.md) · [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) · [update-platform](../engineering-harness/update-platform.md) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) · [trigger-post-merge-deploy](../engineering-harness/trigger-post-merge-deploy.md) |
| doc | `docs/scripts/validate-install.sh` | [install-platform](../engineering-harness/install-platform.md) · [validate-install](../engineering-harness/validate-install.md) |
| core-other | `core/CLAUDE.md.template` | [route-scan-verdicts](../engineering-harness/route-scan-verdicts.md) |
| core-other | `core/settings.json.template` | [engineering-harness](../engineering-harness/engineering-harness.md) · [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) · [verify-session-setup](../engineering-harness/verify-session-setup.md) · [notify-version-skew](../engineering-harness/notify-version-skew.md) · [verify-session-config](../engineering-harness/verify-session-config.md) · [run-session-retro](../engineering-harness/run-session-retro.md) · [trigger-session-retro](../engineering-harness/trigger-session-retro.md) |
| root-file | `.gitleaks.toml` | [run-security-jobs](../engineering-harness/run-security-jobs.md) |
| root-file | `doctor.sh` | [install-platform](../engineering-harness/install-platform.md) |
| root-file | `install.ps1` | [install-platform](../engineering-harness/install-platform.md) |
| root-file | `install.sh` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [install-platform](../engineering-harness/install-platform.md) · [bootstrap-workspace](../engineering-harness/bootstrap-workspace.md) |
| root-file | `qa.sh` | [install-platform](../engineering-harness/install-platform.md) |
| root-file | `update.ps1` | [update-platform](../engineering-harness/update-platform.md) |
| root-file | `update.sh` | [install-or-update-workspace](../engineering-harness/install-or-update-workspace.md) · [update-platform](../engineering-harness/update-platform.md) · [regenerate-composition-surfaces](../engineering-harness/regenerate-composition-surfaces.md) · [refresh-hook-bundle](../engineering-harness/refresh-hook-bundle.md) |
