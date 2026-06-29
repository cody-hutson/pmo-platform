---
pack_name: pmo-platform
pack_version: "1.0"
applies_to: "PMO platform production-readiness review (skills, governance files, reference docs, pipeline stages, suite contracts)"
detection_patterns:
  - "**/release/skills/**"
  - "**/core/governance/**"
  - "**/core/**"
  - "**/core/rules/**"
  - "**/CLAUDE.md"
  - "**/core/rules/**"
default_when_no_match: false
dimension_count: 12
principal_dimensions_included: false
---

# PMO Platform — Dimension Pack

Production-readiness review dimensions for the **PMO platform** — the skills, governance files, reference docs, pipeline stages, and suite contracts that compose `pmo-platform/` and the workspace-global governance surface (`CLAUDE.md`, `core/rules/`).

This pack supplies 12 domain-specific dimensions organized into 4 areas (Pipeline Stages, Skill Architecture, Governance File Coherence, Suite Contracts), plus the 3 Principal Dimensions rendered from `build-reviewer/SKILL.md` at every invocation. Shared review discipline lives in [`core/disciplines/review-discipline-principles.md`](../../../../../core/disciplines/review-discipline-principles.md) and governs this pack like every other.

**Severity scale:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` per `review-discipline-principles.md` § Section 5. No Copilot-native aliases apply here.

---

## Review Dimensions

You must evaluate the platform against every dimension below. For each dimension, produce findings or provide explicit evidence-of-check per Anti-Laziness Rule #3. Dimensions are organized into four areas (A–D). Each area contains 3 dimensions.

---

### Area A — Pipeline Stages

The 13-stage improvement-to-deployment pipeline (per `release/references/pipeline/`) is the execution backbone. These dimensions audit its definitional completeness, gate integrity, and handoff mechanics.

#### PMO-D1 — Stage Definition Completeness

**What to check:**
- Every stage in `pipeline/` has all 10 required fields: Purpose, Reference Model Alignment, Persona, Inputs, Process, Outputs, Stage-Transition Gate, Automation Level, Gap Summary, Retro.
- Phase A / Phase B / Phase C structure (if applicable for a stage) is consistent across stages that claim to use it.
- Ticket lifecycle per stage is explicit (which tickets enter, which exit, what state transitions occur).
- Compression notes (e.g., Stage 10 + 11 compressed into Stage 9 + merge) are present and explain when compression does not apply.

**Specific areas of known risk:**
- Stages 10 and 11 compression — verify the compression section names the three exception cases (non-git deployment, Layer 2 propagation, destructive ops).
- Stage 5 Solutioning applicability matrix — verify the activation criteria are enumerable.
- Stage 13 Close — verify auto-close convention and manual-closure exception path are both specified.

**Root-cause requirement:** If a field is missing, identify which release introduced the stage and why the field was omitted. If a field is degenerate (e.g., "TBD" or one-line boilerplate), trace the drift to the authoring release.

#### PMO-D2 — Gate Criteria Integrity

**What to check:**
- Every stage-boundary gate documented in `gate-criteria-spec.md` has at least one structural metric (auto-checkable) and at least one judgment dimension (LLM-graded). Gates with only one of the two are incomplete.
- Gate IDs (G1-01 through G13-XX, and Checkpoint 1-4 IDs) are unique across the spec.
- Every gate referenced from `pipeline/` or `release-process.md` resolves to a real gate in `gate-criteria-spec.md`. Every gate in `gate-criteria-spec.md` is referenced at least once from a stage or the release-process rule.
- No orphan gates (defined but never invoked). No phantom gates (referenced but not defined).
- Each gate's pass-criterion threshold is observable (not "reviewer confidence"-style).

**Specific areas of known risk:**
- Gates added in recent releases (G7 for failure-mode discipline, G4 for reversibility) — verify they are referenced from both `pipeline/` and the skill that owns enforcement (pmo-qa-auditor).
- Gate-evaluation-spec.md and gate-criteria-spec.md coherence — the three-layer protocol in gate-evaluation-spec.md must match the criteria defined in gate-criteria-spec.md.

**Root-cause requirement:** Trace any orphan/missing gate to the release where the drift started. Distinguish renamed-gate (ID moved; reference stale) from deleted-gate (gate removed; reference orphan) from never-introduced-gate (reference names a gate that was never authored).

#### PMO-D3 — Handoff Coordinator and Inter-Stage Feedback Integrity

**What to check:**
- Every stage transition uses the `handoff-coordinator-spec.md` 5-phase protocol (contract validation, gate evaluation, transition routing, iteration tracking, trend reporting).
- Every inter-stage feedback path (downstream → upstream) uses the Tier 1 / Tier 2 / Tier 3 vocabulary from `release-process.md` § Inter-Stage Feedback Protocol. No bespoke feedback vocabularies invented at the stage level.
- `[ADJUST]` / `[SCOPE CHANGE]` / `[PLAN REJECTION]` tags appear wherever the protocol mandates them in commit messages, PR bodies, and sub-task comments.
- Handoff payloads defined in `stage-io-contracts.md` cover every boundary actually used in releases. Boundaries without defined contracts are gaps.
- Iteration caps are documented per boundary (`release-process.md` default = 2; boundary-specific overrides explicit).

**Specific areas of known risk:**
- DT↔Engineering loop — verify the Pass 1 / Pass N+1 routing rule is present in both Stage 6 and Stage 7.
- DT↔QA handoff — verify Handoff Payload field schemas are in `stage-io-contracts.md` and referenced from both Stage 7 and Stage 8.

**Root-cause requirement:** Trace missing handoff specs to the originating stage. For missing feedback tags, distinguish between "the release didn't need feedback at that boundary" and "feedback occurred but was logged without the mandated tag."

---

### Area B — Skill Architecture

Every skill under `release/skills/` carries structural conventions that make the skill discoverable, invocable, reviewable, and maintainable. These dimensions audit skill-level rigor.

#### PMO-D4 — SKILL.md Structural Conformance

**What to check:**
- Every `SKILL.md` has the canonical sections in order: YAML frontmatter with `name` and `description`, a purpose statement, mode definitions (if multi-mode), either `## Guardrails (Platform)` or an explicit cross-reference to CLAUDE.md platform guardrails, `## Domain-Specific Failure Modes` with ≥3 entries per `failure-mode-standard.md`, and a Reversibility Discipline section (or a declared report-only exemption with rationale).
- Structural regex per `failure-mode-standard.md` G7-01 through G7-05 passes for every `SKILL.md`.
- Cross-references to shared reference docs resolve (target file exists; target section exists at cited heading).
- Frontmatter `description` field is discoverability-optimized (user-facing phrases, not implementer jargon).

**Specific areas of known risk:**
- Recently-refactored skills (e.g., skills that moved from inline rules to reference-doc cross-references) — verify the cross-reference path is correct post-rename.
- Skills without `## Guardrails (Platform)` — verify the skill explicitly inherits from CLAUDE.md rather than silently omitting.
- Multi-mode skills — verify mode list is coherent across frontmatter, body, and any skill-specific mode table.

**Root-cause requirement:** Trace any missing section to the skill's authoring release. For cross-reference breaks, distinguish stale-path (target moved) from stale-heading (target renamed section) from never-existed (target never authored).

#### PMO-D5 — Mode Definition Coherence

**What to check:**
- For every multi-mode skill: the mode list in `SKILL.md` matches the mode list in `per-skill-output-contracts.md` (same names, same count, same trigger descriptions).
- Each mode has trigger conditions, input shape, output shape, and a validation checklist entry in `per-skill-output-contracts.md`.
- No mode listed in one doc is missing from the other. No mode has a name-drift between docs.
- Mode-specific validation checks in `per-skill-output-contracts.md` are observable (structural regex or LLM-gradable), not impressionistic.

**Specific areas of known risk:**
- Skills that added modes in the most recent release — verify both docs were updated.
- Skills that deprecated or renamed a mode — verify references in other skills (chained-skill patterns) caught the rename.

**Root-cause requirement:** Trace any divergence to the release that last edited the mode list. Distinguish author-forgot-cross-ref-doc from author-changed-name-without-propagating.

#### PMO-D6 — Cross-Skill Contract Adherence

**What to check:**
- Every skill that emits RAID entries uses its declared prefix (`R-PPM-###`, `R-DE-###`, `R-CM-###`, `R-TA-###`, `R-PD-###`, `R-BR-###`, etc. per `per-skill-output-contracts.md` § Appendix: RAID Entry Prefix Reference).
- Every decision-class output carries a reversibility tier per `reversibility-protocol.md`.
- Follow-up tags (`[DELIVERY]`, `[COMMS]`, `[TECHNICAL]`, `[PROCESS]`, `[CHANGE]`) respect max-depth-2 and per-skill emit/cannot-emit rules in `per-skill-output-contracts.md` § Valid Tags by Skill.
- Evidence quality labels (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`) appear on factual claims per CLAUDE.md § Universal Preferences.
- Dual-output discipline per `per-skill-output-contracts.md` applies where required (skills producing paste-ready artifacts have both artifact + metadata).

**Specific areas of known risk:**
- RAID-prefix drift when a new skill joins the registry — new prefixes must be declared in `per-skill-output-contracts.md` § Appendix and not collide with existing prefixes.
- Reversibility tier omission on informational outputs — distinguish "informational output not subject to decision" (legitimately untiered) from "decision-class output missing tier" (G4 failure).

**Root-cause requirement:** Trace any contract drift to the release that introduced the divergence. For RAID-prefix collisions, identify which skill's prefix collided and whether the resolution is rename or appendix update.

---

### Area C — Governance File Coherence

The platform is governed by a hierarchy of context files (CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, CORRECTIONS.md, PORTFOLIO.md, PROJECT.md) across two domains (Engineering / Operations). These dimensions audit the boundary and hierarchy.

#### PMO-D7 — Layer Boundary Integrity

**What to check:**
- Layer 1 (Engineering, git-tracked, `pmo-platform/`) files are modified only from Claude Code sessions (via git worktrees and PRs). No Layer 1 file modified directly from Cowork.
- Layer 2 (Operations, git-ignored, `projects/`) files appear in `.gitignore` and do NOT appear in `git status` after a session.
- Layer 3 bridge files (today: `projects/_config/PORTFOLIO.md`) have documented write-rules for both agents (Cowork writes, Claude Code reads only per CLAUDE.md § Bridge Files).
- Classification in CLAUDE.md § Platform vs. Working Content Boundary matches actual file placements — no file is Layer 1 by classification but lives under `projects/`, and vice versa.
- `.gitignore` enforces Layer 2 boundary — `projects/` is ignored; no Layer 2 leakage to git.

**Specific areas of known risk:**
- Recently-added file at the boundary — verify which layer it belongs to before the next release.
- Skill-deployment target path under `<OPERATOR_INSTANCE_SKILLS_PATH>/` — verify it is classified Layer 2 in CLAUDE.md and git-ignored.

**Root-cause requirement:** Trace any boundary violation to the release/skill that crossed it. Distinguish miscategorization (file placed in wrong domain) from cross-domain write (Claude Code wrote to Layer 2 or Cowork wrote to Layer 1).

#### PMO-D8 — Context File Hierarchy Consistency

**What to check:**
- CLAUDE.md → RELEASE_PROTOCOL.md → CORRECTIONS.md → OPERATIONS.md → PROJECT.md → PORTFOLIO.md tier ordering per CLAUDE.md § Context File Hierarchy is reflected in the actual governance files (each file's scope matches its declared tier).
- Each governance file references its tier peers at the correct elevation (Tier-1 CLAUDE.md does not bind to Tier-3 PROJECT.md for workspace-global rules; Tier-4 PORTFOLIO.md does not override Tier-2 OPERATIONS.md).
- Analysis folder convention (`<OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-name>-YYYY-MM-DD/`) is followed for audits. Files not matching the convention either predate it (log as legacy) or are misplaced.
- Governance file placement matches CLAUDE.md § Governance File Map (workspace-global in root, program-scoped governance in `core/governance/`, program-scoped ops config in `projects/_config/`, project-scoped in `projects/[Project]/`).

**Specific areas of known risk:**
- Files that could plausibly live in multiple tiers (e.g., a reference doc that is both engineering and operational) — verify the tier rationale is explicit.
- Governance files created outside the sanctioned locations — require either relocation or governance-map update.

**Root-cause requirement:** Trace any hierarchy inversion to the release that introduced it. For misplaced governance files, identify whether the placement tier was miscategorized at authoring time or whether the file's scope has drifted since.

#### PMO-D9 — Universal Preferences Enforcement

**What to check:**
- Every rule in CLAUDE.md § Universal Preferences has at least one downstream enforcement point: either a skill that applies it or a gate that validates it.
- Orphan preferences (rules that no downstream file operationalizes) are flagged — a preference without an enforcer is aspirational, not governing.
- Enforcement points actually enforce (the skill's output conforms; the gate's criteria catch violations). Unused enforcers are flagged.
- CLAUDE.md § Guardrails (Hard Rejections) items fire at skill-output QA review (Checkpoint 3) — the guardrails are reachable from the pipeline, not orphan text.

**Specific areas of known risk:**
- Newly-added preferences in recent releases (context drift detection, domain-specific failure-mode discipline, reversibility discipline, review discipline, cascade approval, no ungoverned changes, parameterize over hardcode) — verify each has at least one enforcer referenced from a skill or a gate.
- Guardrails that require runtime detection infrastructure (e.g., `No fabricated owners, dates, metrics` requires fabricated-claim detection) — flag if the detector does not exist and a release has not scheduled it.

**Root-cause requirement:** For unenforced preferences, identify which downstream file should operationalize it and whether the enforcer was planned-but-deferred or was never scoped.

---

### Area D — Suite Contracts

The platform's skills emit structured outputs consumed by other skills and by humans. These dimensions audit the cross-skill output contracts and the registry that tracks them.

#### PMO-D10 — Output Contract Registration

**What to check:**
- Every `SKILL.md` listed in `registry.md` has a corresponding section in `per-skill-output-contracts.md`.
- Each contract section has all required subsections per the document's own format: mode table (if multi-mode), output contract sections (field list or section list), required elements, validation checklist, RAID prefix (if applicable).
- No contract is orphan (skill deleted but contract remains).
- No skill is missing a contract (skill exists but no section).
- Mode counts in contracts match mode counts in SKILL.md.

**Specific areas of known risk:**
- Recently-added skills — verify contract was added in the same release or scheduled immediately after.
- Recently-deprecated skills — verify contract section was removed or marked deprecated.
- Contracts doc's own version history — verify it reflects all structural additions.

**Root-cause requirement:** Trace any missing contract to the skill's release milestone. For orphan contracts, identify the deprecation release that should have removed them.

#### PMO-D11 — Evidence Label and Reversibility Tier Discipline

**What to check:**
- Every decision-class output documented in the platform carries both an evidence label (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`) and a reversibility tier (`CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE`) paired with a confidence level (`HIGH` / `MEDIUM` / `LOW`).
- pmo-qa-auditor Gate G2 (evidence labels) and Gate G4 (reversibility tiers) have active runbooks in `pmo-qa-auditor/SKILL.md` that enumerate their specific auto-checks.
- Sampled skill outputs (recent releases' PR diffs, recent operational outputs if accessible) conform to the labeling discipline.
- Decision-class vs. informational-class distinction is explicit — not every output requires a tier; the contract must name which outputs are decision-class for each skill.

**Specific areas of known risk:**
- Skills that produce recommendations in free-form prose — the tier can be omitted without visible break; verify the contract requires the tier and pmo-qa-auditor catches omissions.
- Conditional-tier emissions (e.g., "tier on MODERATE+ only") — verify the contract's threshold is explicit.

**Root-cause requirement:** Distinguish skill-authoring drift (skill's contract does not require labels) from runtime drift (contract requires labels but operator omits at invocation time). The former is a skill-authoring fix; the latter is a training/runbook fix.

#### PMO-D12 — Cross-Reference Integrity Across Reference Docs

**What to check:**
- Every `core/**/*.md` cross-referenced from CLAUDE.md, OPERATIONS.md, or a `SKILL.md` resolves: target file exists at the cited path, target section exists at the cited heading.
- Sample 20 cross-references from each reference doc; verify each resolves. Non-resolving references are findings.
- Internal cross-references within a single reference doc also resolve (section-to-section links).
- Stale aliases — when a reference doc has been renamed or moved, verify legacy paths in other files were updated.

**Specific areas of known risk:**
- Recently-renamed reference docs (e.g., any file moved during a refactor release).
- Docs under `core/schemas/` vs. `core/` — verify callers reference the correct location.
- Cross-references added in recent releases — verify they point to content that actually exists in the target.

**Root-cause requirement:** For broken references, distinguish renamed-section (section moved; reference stale) from removed-section (section deleted; reference orphan) from never-existed (reference names a section that was never authored).

---

## Pack-Specific Calibration Context

This pack targets the PMO platform's own operator (a Senior Program Manager / Technical Program Manager), who is simultaneously the platform's primary user and its primary author. Reviews calibrate to a tight feedback loop: findings either land as GitHub Issues (per the auto-logging rule) or as direct remediation commits in the next release. Noise cost is low relative to the Copilot-builder pack because fixes are self-applied; signal discipline still matters to keep the findings register actionable.

The primary deployment target is the workspace itself: the operator runs Claude Code sessions against `pmo-platform/` and Cowork against `projects/`. Reviews therefore test both the documentation (what is written) and the runtime enforcement (what gates catch). Findings that live only at the documentation layer without a gate or skill to operationalize them are a specific failure mode this pack surfaces (PMO-D9).

---

## Pack Start

Start the review with the highest-risk dimensions for this pack: PMO-D4 (SKILL.md conformance), PMO-D6 (cross-skill contracts), and PMO-D12 (cross-reference integrity) historically surface the most drift. Area D (Suite Contracts) is the highest-leverage area — failures there propagate through multiple skills. After pack-specific dimensions complete, the skill's `## Principal Dimensions` section applies to every finding register regardless of pack.
