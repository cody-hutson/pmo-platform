# Module APIs — pmo-platform

> Consolidated cross-module API reference. Canonical detail lives at each module's `README.md § Public API` section; this document summarizes for cross-module consumers.

<!-- module-apis.md is a derived navigation surface. Canonical detail: operations/README.md § Public API + release/README.md § Public API + core/README.md § Public API. On any change to a module's Public API section, update this enumeration. -->

## 1. About this document

- **Audience:** Cross-module developers (operations / release / core), external integrators (post-public-flip).
- **Purpose:** Single navigation surface answering "what's the public API surface of each module?"
- **Authority model:** Canonical API detail lives at per-module `README.md § Public API`. This document enumerates with a 1–2 line summary plus link; it does NOT re-document the canonical detail.
- **Recommended reading path:** Browse Section 2 / 3 / 4 → click through to the per-module README for canonical detail → return for cross-module composition patterns (Section 5) or versioning conventions (Section 6).
- **Living-document status:** Updated when a module ships a new public skill, public reference, or new template. The canonical source of truth is the per-module README; this document is a derived index.
- **Modular-monolith stance:** The three modules ship as a single repository (Architecture Choice: modules now, extraction possible later if a module proves independent). Module-extraction readiness is documented at each module's `README.md § Future-Extraction Readiness`; this document does not surface extraction-readiness verdicts.

## 2. Operations module public API

> Canonical: [`operations/README.md § Public API`](../operations/README.md#public-api). This section summarizes.

**Audience:** PMO practitioner (Senior Program Manager, Technical Program Manager, PMO Director).

### Skills (17 invocation)

| Skill | Mode | Description |
|---|---|---|
| [`artifact-generator`](../operations/skills/artifact-generator/) | invocation | Produces PMO project artifacts; stages in `08-Generated/`. |
| [`change-management`](../operations/skills/change-management/) | invocation | Plans and tracks organizational change for go-lives. |
| [`comms-writer`](../operations/skills/comms-writer/) | invocation | Stakeholder communications across email / Teams / Confluence. |
| [`daily-status`](../operations/skills/daily-status/) | invocation | AM / PM Teams-ready daily status updates. |
| [`delivery-engine`](../operations/skills/delivery-engine/) | invocation | Backlog → release-readiness; DoR / DoD gates; sprint planning. |
| [`file-router`](../operations/skills/file-router/) | invocation | Classifies and routes incoming files in the PMO workspace. |
| [`intake-desk`](../operations/skills/intake-desk/) | invocation | Conversational intake front door — elicits typed, level-aware work items from a raw idea. |
| [`pmo-knowledge-manager`](../operations/skills/pmo-knowledge-manager/) | invocation | Knowledge Manager Specialist — captures / structures / routes / stewards knowledge assets; composes artifact-generator + file-router. |
| [`pmo-ocm-lead`](../operations/skills/pmo-ocm-lead/) | invocation | OCM Lead Specialist — sequences a go-live's change program (impact → training → readiness → hypercare); composes change-management. |
| [`pmo-process-designer`](../operations/skills/pmo-process-designer/) | invocation | Converts business context into structured requirements / processes. |
| [`pmo-technical-analyst`](../operations/skills/pmo-technical-analyst/) | invocation | Reviews technical artifacts (FDDs, integration specs) with TPM judgment. |
| [`pmo-tier-1-support`](../operations/skills/pmo-tier-1-support/) | invocation | Tier-1 Support Specialist — first-line triage; resolves from a known issue / runbook or escalates to tier-2. |
| [`pmo-tier-2-support`](../operations/skills/pmo-tier-2-support/) | invocation | Tier-2 Support Specialist — root-causes escalated issues and authors the runbook (RCA + knowledge-loop close). |
| [`ppm-agent`](../operations/skills/ppm-agent/) | invocation | Strategic PMO brain — pushes actionable items to resolution. |
| [`project-initiator`](../operations/skills/project-initiator/) | invocation | Project lifecycle scaffolding (init + closure). |
| [`tracker-manager`](../operations/skills/tracker-manager/) | invocation | Generic update engine for operational trackers. |
| [`weekly-status-rollup`](../operations/skills/weekly-status-rollup/) | invocation | Weekly executive status across active projects. |

### Public references

- [`operations/OPERATIONS.md`](../operations/OPERATIONS.md) — module governance.
- [`core/disciplines/applicability-framework.md`](../core/disciplines/applicability-framework.md) — applicability framework (universal-discipline; consumed by operations + release modules; canonical home per the duplicate-source-discipline resolution).
- [`core/disciplines/context-lifecycle-model.md`](../core/disciplines/context-lifecycle-model.md) — context lifecycle model (universal-discipline; canonical home per the duplicate-source-discipline resolution).
- [`operations/skills/<skill>/references/`](../operations/skills/) — skill-internal template references (consumable cross-module per the Pattern-P2/P3 carry-forward contract).

### Public templates

[`operations/templates/`](../operations/templates/) ships these canonical templates (the registry of record is [`operations/templates/README.md`](../operations/templates/README.md)): RAID Log, Project Plan, Test Plan, FRD, FDD, Comms Plan, Training Plan, hypercare-plan, raid-log-template, communications-tracker-template, open-meetings-tracker-template, key-terms-glossary-template, dual-framing-bridge-template, milestone-tracker-template, sprint-tracker-template, transcript-register-template, daily-status-log-template, daily-status-update-framework-template, executive-status-report-prompt-template, raid-templates, requirements-template, project-md-template. The **project-data-architecture** family (v3.37) adds the composed-index `project-md-composed-index-template`, six `_pmo/` shared-entity templates (`person`/`system`/`vendor`/`workstream`/`decision`/`dependency`-entity-template), and six typed-plan templates under `plan-templates/` (`comms`/`training`/`hypercare`/`cutover`/`change-management`/`raid`).

### Cross-module dependencies

`operations` → `core` ONLY. Prohibited: any reference into `release/`. See `operations/README.md § Cross-Module Dependencies` for the permitted-reference enumeration.

## 3. Release module public API

> Canonical: [`release/README.md § Public API`](../release/README.md#public-api). This section summarizes.

**Audience:** Platform builder (engineering, release manager, DevOps).

### Skills (7 invocation, 1 source-only canary)

| Skill | Mode | Description |
|---|---|---|
| [`release-planner`](../release/skills/release-planner/) | invocation | Plans the release lifecycle (backlog analysis, bundling, dry-run). |
| [`release-executor`](../release/skills/release-executor/) | invocation | Executes approved release plans (deploy, verify, rollback, close). |
| [`build-reviewer`](../release/skills/build-reviewer/) | invocation | Production-readiness review of governed document packs. |
| [`implementation-planner`](../release/skills/implementation-planner/) | invocation | Converts build-reviewer findings into remediation plans. |
| [`pmo-skill-editor`](../release/skills/pmo-skill-editor/) | invocation | Edit / audit / regression-test any skill. |
| [`pmo-skill-refiner`](../release/skills/pmo-skill-refiner/) | invocation | Create / refine PMO-platform skills (wraps Anthropic scaffolder). |
| [`pmo-release-manager`](../release/skills/pmo-release-manager/) | invocation | Release Manager Specialist — owns the release tail (go/no-go, deploy authorization, close-out); composes release-planner + release-executor. |

Canary (not part of Public API, source-only): [`pmo-skill-refiner-selftest-canary`](../release/skills/pmo-skill-refiner-selftest-canary/).

### Public references

**Governance:**

- [`release/governance/RELEASE_PROTOCOL.md`](../release/governance/RELEASE_PROTOCOL.md) — release lifecycle protocol.
- [`release/governance/release-process.md`](../release/governance/release-process.md) — 13-stage pipeline definition.

**Pipeline shards** (13 stage specifications, [`release/references/pipeline/`](../release/references/pipeline/)):

[`stage-01-intake.md`](../release/references/pipeline/stage-01-intake.md), [`stage-02-triage.md`](../release/references/pipeline/stage-02-triage.md), [`stage-03-bundle.md`](../release/references/pipeline/stage-03-bundle.md), [`stage-04-planning.md`](../release/references/pipeline/stage-04-planning.md), [`stage-05-solutioning.md`](../release/references/pipeline/stage-05-solutioning.md), [`stage-06-engineering.md`](../release/references/pipeline/stage-06-engineering.md), [`stage-07-dev-testing.md`](../release/references/pipeline/stage-07-dev-testing.md), [`stage-08-qa-testing.md`](../release/references/pipeline/stage-08-qa-testing.md), [`stage-09-plan-review.md`](../release/references/pipeline/stage-09-plan-review.md), [`stage-10-dry-run.md`](../release/references/pipeline/stage-10-dry-run.md), [`stage-11-snapshot.md`](../release/references/pipeline/stage-11-snapshot.md), [`stage-12-execute.md`](../release/references/pipeline/stage-12-execute.md), [`stage-13-close.md`](../release/references/pipeline/stage-13-close.md).

**How-to** ([`release/references/how-to/`](../release/references/how-to/)):

- [`hub-spoke-bridge.md`](../release/references/how-to/hub-spoke-bridge.md) — hub-and-spoke release bridge procedures.
- [`intake-style-guide.md`](../release/references/how-to/intake-style-guide.md) — intake authoring style guide.
- [`implementation-execution-pattern.md`](../release/references/how-to/implementation-execution-pattern.md) — Stage 6 implementation workflow.
- [`domain-c-lifecycle-protocol.md`](../release/references/how-to/domain-c-lifecycle-protocol.md) — Domain-C lifecycle protocol.

**Standards** ([`release/references/standards/`](../release/references/standards/)):

- [`bundle-composition-doctrine.md`](../release/references/standards/bundle-composition-doctrine.md) — vertical-capability slice doctrine for milestone bundling.
- [`decision-outcome-tracking.md`](../release/references/standards/decision-outcome-tracking.md) — Stage 13 decision-outcome capture standard.
- [`deferred-item-tracking.md`](../release/references/standards/deferred-item-tracking.md) — deferred-issue disposition protocol.
- [`deployment-cycle-time.md`](../release/references/standards/deployment-cycle-time.md) — cycle-time metric standard.
- [`partial-deployment-recovery.md`](../release/references/standards/partial-deployment-recovery.md) — Stage 12 partial-failure recovery.
- [`pipeline-event-log-schema.md`](../release/references/standards/pipeline-event-log-schema.md) — pipeline event-log schema.
- [`release-corpus-schema.md`](../release/references/standards/release-corpus-schema.md) — release-corpus document schema.
- [`release-notes-standard.md`](../release/references/standards/release-notes-standard.md) — Stage 13 release-notes authoring standard.
- [`release-notes-voice-guardrails.md`](../release/references/standards/release-notes-voice-guardrails.md) — voice / tone guardrails for release notes.
- [`solutioning-output-template.md`](../release/references/standards/solutioning-output-template.md) — Stage 5 spoke output template.
- [`triage-design-rereview.md`](../release/references/standards/triage-design-rereview.md) — Stage 4 / Stage 5 entry re-review standard.

**Protocols** ([`release/references/protocols/`](../release/references/protocols/)):

- [`blast-radius-protocol.md`](../release/references/protocols/blast-radius-protocol.md), [`fission-convention.md`](../release/references/protocols/fission-convention.md), [`improvement-review-process.md`](../release/references/protocols/improvement-review-process.md), [`mixed-release-solutioning-routing.md`](../release/references/protocols/mixed-release-solutioning-routing.md), [`subsumption-convention.md`](../release/references/protocols/subsumption-convention.md), [`version-management-protocol.md`](../release/references/protocols/version-management-protocol.md).

**Specs** ([`release/references/specs/`](../release/references/specs/)):

- [`methodology-archetype-matrix.md`](../release/references/specs/methodology-archetype-matrix.md), [`methodology-parameterization-v1.md`](../release/references/specs/methodology-parameterization-v1.md), [`release-class-taxonomy.md`](../release/references/specs/release-class-taxonomy.md), [`release-outcome-statement-template.md`](../release/references/specs/release-outcome-statement-template.md), [`release-personas.md`](../release/references/specs/release-personas.md), [`release-readiness-scan-spec.md`](../release/references/specs/release-readiness-scan-spec.md), [`skill-suite-regression-checks.md`](../release/references/specs/skill-suite-regression-checks.md), [`stage-to-skill-mode-mapping.md`](../release/references/specs/stage-to-skill-mode-mapping.md), [`ticket-information-architecture.md`](../release/references/specs/ticket-information-architecture.md).

**Templates** ([`release/references/templates/`](../release/references/templates/)):

- [`design-review-checklist.md`](../release/references/templates/design-review-checklist.md) — Stage 5 design-review checklist.

**Tools** ([`release/tools/`](../release/tools/)):

- [`append-pipeline-event.sh`](../release/tools/append-pipeline-event.sh) — append pipeline event-log row.
- [`automated-closeout.sh`](../release/tools/automated-closeout.sh) — Stage 13 automated close-out helper.
- [`blast-radius.sh`](../release/tools/blast-radius.sh) — blast-radius analysis.
- [`bundle-issues-parser.py`](../release/tools/bundle-issues-parser.py) — bundle-issue parser.
- [`check-line-range-overlap.py`](../release/tools/check-line-range-overlap.py) — cross-PR / cross-branch line-range overlap analyzer.
- [`cleanup-orphan-state.sh`](../release/tools/cleanup-orphan-state.sh) — orphan branch / worktree sweeper.
- [`compute-cycle-time.sh`](../release/tools/compute-cycle-time.sh) — cycle-time computation.
- [`query-pipeline-event.sh`](../release/tools/query-pipeline-event.sh) — pipeline event-log query helper.
- [`synthesize-release-learnings.sh`](../release/tools/synthesize-release-learnings.sh) — cross-release pattern synthesizer.

**ADRs** ([`release/ADRs/`](../release/ADRs/)):

- [`ADR-001-cross-pr-overlap-audit-baseline.md`](../release/ADRs/ADR-001-cross-pr-overlap-audit-baseline.md), [`ADR-002-modular-pipeline-stages-split.md`](../release/ADRs/ADR-002-modular-pipeline-stages-split.md), [`ADR-005-append-pattern-aware-cross-pr-contention-scoring.md`](../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md).

### Cross-module dependencies

`release` → `core` ONLY. Prohibited: any reference into `operations/`. See `release/README.md § Cross-Module Dependencies` for the permitted-reference enumeration.

## 4. Core module public API

> Canonical: [`core/README.md § Public API`](../core/README.md#public-api). This section summarizes.

**Audience:** BOTH PMO practitioners AND platform builders (the shared kernel).

### Skills (4 invocation)

| Skill | Mode | Description |
|---|---|---|
| [`prompt-builder`](../core/skills/prompt-builder/) | invocation | Builds / improves prompts of every kind (Claude prompts, SKILL.md, agent prompts). |
| [`pmo-qa-auditor`](../core/skills/pmo-qa-auditor/) | invocation | Reviews skill outputs against the principal-contributor standard. |
| [`eval-writer`](../core/skills/eval-writer/) | invocation | Authors rigorous eval suites for AI agents, skills, LLM systems. |
| [`pmo-skill-router`](../core/skills/pmo-skill-router/) | invocation | Capstone suite router — classifies a role-shaped request against [`core/skills/registry.md`](../core/skills/registry.md) and routes it to the correct role-Specialist. |

### Public references

**Templates:**

- [`core/CLAUDE.md.template`](../core/CLAUDE.md.template) — depersonalized workspace-root template.
- [`core/config/`](../core/config/) — settings templates + allowlist configuration.

**Security hooks** ([`core/hooks/`](../core/hooks/), 10 PreToolUse hooks + 3 SessionStart hooks):

- [`block-credential-reads.sh`](../core/hooks/block-credential-reads.sh) — block Read-tool access to credential files.
- [`block-destructive.sh`](../core/hooks/block-destructive.sh) — block destructive git / rm operations.
- [`block-egress.sh`](../core/hooks/block-egress.sh) — block credential egress + network upload.
- [`block-fs-boundary.sh`](../core/hooks/block-fs-boundary.sh) — block file ops outside the workspace boundary.
- [`block-mcp-writes.sh`](../core/hooks/block-mcp-writes.sh) — block MCP write tools without allowlist entry.
- [`block-rm-prefer-trash.sh`](../core/hooks/block-rm-prefer-trash.sh) — redirect workspace deletions to Trash.
- [`block-shell-injection.sh`](../core/hooks/block-shell-injection.sh) — block shell-injection patterns in slash-command arguments.
- [`block-skill-direct-edit.sh`](../core/hooks/block-skill-direct-edit.sh) — gate skill-edit invocations through `pmo-skill-editor`.
- [`allowlist-add.sh`](../core/hooks/allowlist-add.sh) — atomic allowlist append helper.
- [`audit-mcp-usage.sh`](../core/hooks/audit-mcp-usage.sh) — one-shot seeder for the MCP write-tool allowlist (not a tool-call-time hook).
- [`notify-version-skew.sh`](../core/hooks/notify-version-skew.sh) — SessionStart notice when local `.version` lags the latest published release.

**Disciplines** ([`core/disciplines/`](../core/disciplines/)):

- [`decision-discipline.md`](../core/disciplines/decision-discipline.md) — Decision Discipline Framework.
- [`discovery-discipline.md`](../core/disciplines/discovery-discipline.md) — Discovery Discipline Framework.
- [`review-discipline-principles.md`](../core/disciplines/review-discipline-principles.md) — Review Discipline Principles.
- See [`core/disciplines/README.md`](../core/disciplines/README.md) for the full enumeration of explanation docs (architecture-overview, autonomous-execution-model, context-lifecycle-model, execution-framework, knowledge-architecture, operating-model, etc.).

**Schemas** ([`core/schemas/`](../core/schemas/)):

- [`agent-processing-contracts.md`](../core/schemas/agent-processing-contracts.md), [`entity-field-schemas.md`](../core/schemas/entity-field-schemas.md), [`field-lifecycle-matrix.md`](../core/schemas/field-lifecycle-matrix.md), [`frontmatter-schema.md`](../core/schemas/frontmatter-schema.md), [`gate-criteria-spec.md`](../core/schemas/gate-criteria-spec.md), [`gate-evaluation-spec.md`](../core/schemas/gate-evaluation-spec.md), [`handoff-coordinator-spec.md`](../core/schemas/handoff-coordinator-spec.md), [`navigation-layer-schema.md`](../core/schemas/navigation-layer-schema.md), [`per-skill-output-contracts.md`](../core/schemas/per-skill-output-contracts.md), [`project-schema.md`](../core/schemas/project-schema.md), [`routing-rules.md`](../core/schemas/routing-rules.md), [`sqlite-index-schema.md`](../core/schemas/sqlite-index-schema.md), [`stage-io-contracts.md`](../core/schemas/stage-io-contracts.md), [`tracker-schemas.md`](../core/schemas/tracker-schemas.md).

**Specs** ([`core/specs/`](../core/specs/)):

- [`anthropic-base-vs-build-registry.md`](../core/specs/anthropic-base-vs-build-registry.md), [`autonomy-tiers.md`](../core/specs/autonomy-tiers.md), [`engagement-charter.md`](../core/specs/engagement-charter.md), [`framework-catalog.md`](../core/specs/framework-catalog.md), [`health-check-specification.md`](../core/specs/health-check-specification.md), [`label-taxonomy.md`](../core/specs/label-taxonomy.md), [`operational-artifact-inventory.md`](../core/specs/operational-artifact-inventory.md), [`reversibility-protocol.md`](../core/specs/reversibility-protocol.md), [`terminology-glossary.md`](../core/specs/terminology-glossary.md).

**Standards** ([`core/standards/`](../core/standards/)):

- Cross-module discipline + framework standards: [`agent-handoff-framework.md`](../core/standards/agent-handoff-framework.md), [`AUDIT_FRAMEWORK.md`](../core/standards/AUDIT_FRAMEWORK.md), [`canonical-skill-structure.md`](../core/standards/canonical-skill-structure.md), [`date-variable-convention.md`](../core/standards/date-variable-convention.md), [`depersonalization-spec.md`](../core/standards/depersonalization-spec.md), [`design-artifact-standard.md`](../core/standards/design-artifact-standard.md), [`doc-link-maintenance-protocol.md`](../core/standards/doc-link-maintenance-protocol.md), [`duplicate-source-discipline.md`](../core/standards/duplicate-source-discipline.md), [`evidence-grounding-standard.md`](../core/standards/evidence-grounding-standard.md), [`failure-mode-standard.md`](../core/standards/failure-mode-standard.md), [`framework-corpus-discipline.md`](../core/standards/framework-corpus-discipline.md), [`hub-action-tracking.md`](../core/standards/hub-action-tracking.md), [`hub-session-continuity.md`](../core/standards/hub-session-continuity.md), [`initiative-roadmap-framework.md`](../core/standards/initiative-roadmap-framework.md), [`km-governance-framework.md`](../core/standards/km-governance-framework.md), [`lifecycle-states-canonical.md`](../core/standards/lifecycle-states-canonical.md), [`operational-artifact-template-standard.md`](../core/standards/operational-artifact-template-standard.md), [`per-stage-shard-standard.md`](../core/standards/per-stage-shard-standard.md), [`planning-solutioning-handoff.md`](../core/standards/planning-solutioning-handoff.md), [`practice-efficacy-framework.md`](../core/standards/practice-efficacy-framework.md), [`principal-standard-checklist.md`](../core/standards/principal-standard-checklist.md), [`process-flow-diagram-standards.md`](../core/standards/process-flow-diagram-standards.md), [`public-repo-gitignore-template.md`](../core/standards/public-repo-gitignore-template.md), [`regression-checks.md`](../core/standards/regression-checks.md), [`review-composition-framework.md`](../core/standards/review-composition-framework.md), [`skill-workspace-location.md`](../core/standards/skill-workspace-location.md), [`subagent-security-posture.md`](../core/standards/subagent-security-posture.md), [`template-protocol.md`](../core/standards/template-protocol.md), [`template-storage.md`](../core/standards/template-storage.md), [`template-taxonomy.md`](../core/standards/template-taxonomy.md), [`universal-vs-localized-context.md`](../core/standards/universal-vs-localized-context.md), [`upstream-reference-catalog.md`](../core/standards/upstream-reference-catalog.md), [`version-field-semantics.md`](../core/standards/version-field-semantics.md).

**Rules** ([`core/rules/`](../core/rules/), 10 operational rules):

- [`analysis-mandate.md`](../core/rules/analysis-mandate.md), [`bypass-mode-readiness.md`](../core/rules/bypass-mode-readiness.md), [`decision-time-adherence.md`](../core/rules/decision-time-adherence.md), [`doc-link-maintenance.md`](../core/rules/doc-link-maintenance.md), [`git-workflow.md`](../core/rules/git-workflow.md), [`governance-files.md`](../core/rules/governance-files.md), [`harness-deployment.md`](../core/rules/harness-deployment.md), [`operations-bridge.md`](../core/rules/operations-bridge.md), [`rename-reference-cascade.md`](../core/rules/rename-reference-cascade.md), [`skill-deployment.md`](../core/rules/skill-deployment.md).

**Governance** ([`core/governance/`](../core/governance/)):

- [`OPERATIONS.md`](../core/governance/OPERATIONS.md) — cross-module operations governance.
- Initiative-roadmap *instances* are authored operator-local (`<OPERATOR_INSTANCE_ROADMAPS_PATH>`), not tracked here — see [`initiative-roadmap-framework.md`](../core/standards/initiative-roadmap-framework.md) and [ADR-012](../core/ADRs/ADR-012-roadmap-instance-descope.md).

**Deploy infrastructure** ([`core/deploy/`](../core/deploy/)):

- [`deploy.sh`](../core/deploy/deploy.sh) — platform deployment script.
- [`tools/`](../core/deploy/tools/) — deploy-time check helpers (check-doc-links.py, check-version-anchors.py, cross-module-audit.sh, generate_release_index.py, lint_release_corpus.py).

**ADRs** ([`core/ADRs/`](../core/ADRs/)):

- [`ADR-003-operating-model-composition.md`](../core/ADRs/ADR-003-operating-model-composition.md), [`ADR-004-five-function-spine.md`](../core/ADRs/ADR-004-five-function-spine.md), [`ADR-006-skill-to-module-map.md`](../core/ADRs/ADR-006-skill-to-module-map.md), [`ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md), [`ADR-008-deploy-sh-per-module-array-design.md`](../core/ADRs/ADR-008-deploy-sh-per-module-array-design.md), [`ADR-009-rewrite-map-cli-design.md`](../core/ADRs/ADR-009-rewrite-map-cli-design.md).

### Cross-module dependencies

**Core depends on NO other module.** This is the architectural invariant per [`core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md). See `core/README.md § Cross-Module Dependencies` for the PROHIBITED-reference enumeration.

## 5. Cross-module composition patterns

This section enumerates the canonical composition patterns by which `operations` and `release` skills consume `core` capability. These are not enumeration — they are the navigation guide for "how do consumer-module skills compose with the shared kernel?"

### Pattern A — `operations → core` consumption

Operations skills consume core disciplines (decision / discovery / review), core skills (prompt-builder, pmo-qa-auditor, eval-writer), core hooks (security enforcement), and core schemas (handoff contracts).

**Concrete examples:**

- `operations/skills/daily-status` consumes [`core/disciplines/decision-discipline.md`](../core/disciplines/decision-discipline.md) for verdict-rendering discipline, [`core/hooks/block-destructive.sh`](../core/hooks/block-destructive.sh) for security enforcement during file writes, and [`core/skills/pmo-qa-auditor`](../core/skills/pmo-qa-auditor/) for output audits.
- `operations/skills/tracker-manager` consumes [`core/schemas/tracker-schemas.md`](../core/schemas/tracker-schemas.md) for the tracker-update contract and [`core/disciplines/discovery-discipline.md`](../core/disciplines/discovery-discipline.md) for ambiguity-resolution discipline.

### Pattern B — `release → core` consumption

Release skills consume core schemas (gate-criteria-spec, handoff-coordinator-spec), core skills (pmo-qa-auditor for gate audits, eval-writer for Stage 7 DT), core deploy infrastructure (deploy.sh, check tools), and core disciplines.

**Concrete examples:**

- `release/skills/release-planner` consumes [`core/schemas/gate-criteria-spec.md`](../core/schemas/gate-criteria-spec.md) for G3 Release-Readiness evaluation criteria and [`core/skills/pmo-qa-auditor`](../core/skills/pmo-qa-auditor/) for gate-audit verdicts.
- `release/skills/release-executor` consumes [`core/deploy/deploy.sh`](../core/deploy/deploy.sh) for Stage 12 skill deployment and [`core/deploy/tools/check-doc-links.py`](../core/deploy/tools/check-doc-links.py) for post-deploy doc-link verification.

### Pattern C — `release → operations` boundary (PROHIBITED)

**Release MUST NOT reference operations.** This is the canonical anti-pattern enforced by `core/ADRs/ADR-007-core-module-boundary.md`.

**Documentary cross-references** between release and operations are permitted ONLY when classified as `via-public-api` — that is, the release-side reference points at an entry in the operations module's explicit Public API enumeration (Section 2 above), not at internal operations content. Per the audit framework, all such references go through the Cat-6 `via-public-api` classification.

**Audit enforcement:** the architectural invariant (0 code-import cycles between modules) is codified in [`../core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md). Re-verify at any SHA by running [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh) — output writes to `audit-output/` (gitignored) by default.

### Pattern D — Composition through shared schemas

Cross-module composition often flows through `core/schemas/` and `core/standards/` — both consumer modules read the same canonical contract, producing aligned outputs without direct module-to-module coupling. Example: `operations/skills/comms-writer` and `release/skills/release-planner` both consume [`core/standards/agent-handoff-framework.md`](../core/standards/agent-handoff-framework.md) to produce handoff payloads that downstream skills can parse uniformly.

## 6. Versioning + breaking-change conventions

Each module ships its own version (per-module `README.md § Versioning`). Canonical version-bump triggers live in the per-module README; this section summarizes the cross-module versioning contract.

### Module versions (per-module README)

- **Operations:** see [`operations/README.md § Versioning`](../operations/README.md#versioning).
- **Release:** see [`release/README.md § Versioning`](../release/README.md#versioning).
- **Core:** see [`core/README.md § Versioning`](../core/README.md#versioning).

### Cross-module breaking-change cascades

- **`core` MAJOR bump** → `operations` AND `release` MUST re-test against the new major. Pre-1.0 (current state): consumer modules pin to `core 0.X`. Post-public-flip: cross-module consumers MAY pin to a major version explicitly.
- **`operations` MAJOR bump** → no automatic cascade to release / core (modules are independent consumers).
- **`release` MAJOR bump** → no automatic cascade to operations / core.

### Pre-flip vs. post-flip posture

| Posture | Module version | Cross-module pin |
|---|---|---|
| **Pre-public-flip** | Advisory only — operator-driven coordination | Not load-bearing |
| **Post-public-flip** | Load-bearing — consumers MAY pin | Load-bearing |

### Per-release tracking

Cross-module version bumps and breaking-change records land in [`CHANGELOG.md`](../CHANGELOG.md) at the repository root, prefixed by the module name (e.g., `(core)`, `(operations)`, `(release)`). Each release plan (under `release/`) summarizes the in-release version bumps as part of the Stage 13 close.

## See also

- Per-module READMEs: [`operations/README.md`](../operations/README.md), [`release/README.md`](../release/README.md), [`core/README.md`](../core/README.md).
- Module governance: [`operations/OPERATIONS.md`](../operations/OPERATIONS.md), [`release/governance/RELEASE_PROTOCOL.md`](../release/governance/RELEASE_PROTOCOL.md), [`core/governance/OPERATIONS.md`](../core/governance/OPERATIONS.md).
- Architectural decisions: [`core/ADRs/ADR-006-skill-to-module-map.md`](../core/ADRs/ADR-006-skill-to-module-map.md) (skill-to-module map), [`core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md) (core-module boundary invariant).
- Cross-module audit tool: [`../core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh) — regenerates the cycle-prevention verdict at any SHA.
- Modular-monolith vision + future-extraction posture: each module's `## Future-Extraction Readiness` section in its README documents the per-module self-containment invariants.
