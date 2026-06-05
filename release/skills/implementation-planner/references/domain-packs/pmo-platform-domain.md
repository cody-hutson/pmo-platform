---
pack_name: pmo-platform
pack_version: 1.0
applies_to: "PMO platform remediation planning (skills, governance files, reference docs, pipeline stages, suite contracts)"
detection_patterns:
  - "**/release/skills/**"
  - "**/core/governance/**"
  - "**/core/**"
  - "**/core/rules/**"
  - "**/CLAUDE.md"
default_when_no_match: false
rt_types_supported: [RT-1, RT-2, RT-3, RT-4, RT-5, RT-8]
operator_profile_default: "Senior Program Manager / Technical Program Manager familiar with PMO platform architecture (Layer 1 Engineering / Layer 2 Operations boundary, 13-stage pipeline, governance file hierarchy). Executes changes on a release branch via git; primary checkout is read-only."
severity_scale_native: "CRITICAL..LOW"
sequencing_rules_ref: "#governance-first-sequencing"
batch_limits: { max_records: 5, max_files: 3 }
principal_dimensions_included: true
---

# Implementation-Planner — PMO Platform Domain Pack (v1.0)

This pack parameterizes `implementation-planner` for PMO platform remediation planning — findings registers produced by `build-reviewer` run against PMO skill definitions, governance files, reference documentation, pipeline-stage specifications, and suite contracts (per build-reviewer's Area A-D dimensions).

**Registry:** [`README.md`](README.md) — pack schema, domain-detection rules, fallback-banner spec.

---

## Pack Input Expectations

Input: findings register from `build-reviewer` invoked with `--pack=pmo-platform`. Register format:

- Each finding: `Finding-ID`, `Dimension` (per pmo-platform review taxonomy — skill-conformance, governance-coherence, reference-integrity, pipeline-fidelity, etc.), `Severity` (CRITICAL / HIGH / MEDIUM / LOW — see Severity Scale Native below), `Affected Files` (SKILL.md paths, governance-file paths, reference-doc paths), `Root Cause` (with review-discipline-principles.md Section 2-3 `[systemic pattern]` → `[proximal cause]` → `[observable signal]` chain), `Evidence` (file-line citations), `Recommended Resolution`.
- Register may also include Residual Risks from prior releases (tracked in prior release plans' Residual Risks sections).

Findings in this pack most commonly map to RT-1 (text correction), RT-2 (additive clarification — e.g., new constraint added to a governance section), RT-3 (reference addition), and occasionally RT-5 (multi-document coordination across the `core/rules/` ↔ `core/rules/` mirror pair, or across multiple skill SKILL.md files that share a pattern).

---

## Severity Scale Native (CRITICAL..LOW)

The pmo-platform pack uses a 4-tier named severity scale (matches the generalized scale in review-discipline-principles.md Section 5). The planner emits both the native CRITICAL..LOW token AND the CS-equivalent per `SKILL.md § Severity Normalization`.

| CRITICAL..LOW | CS Equivalent | Meaning |
|---|---|---|
| CRITICAL | CS4 | Would cause governance breach, platform-behavior regression, or pipeline failure if unresolved |
| HIGH | CS3 | Materially degrades correctness, conformance, or safety discipline |
| MEDIUM | CS2 | Noticeable defect with a workaround |
| LOW | CS1 | Cosmetic, stylistic, or low-impact drift |

Implementation Record Metadata convention: `Severity (validated): HIGH [CS3 equivalent]` — native token first, CS equivalent in brackets. Downstream reporting (e.g., release plan Risk Register) uses the native token; the CS equivalent is preserved for cross-pack audit compatibility.

---

## RT-6 Applicability

**N/A for pmo-platform pack by default.** The platform has no runtime-extract analog to Copilot's `Runtime_Constitutional_Minimum_Set.md`. If a future release introduces a derived artifact (e.g., a compiled `agent-processing-contracts` view aggregating across skill SKILL.md files), this pack's version increments to v1.1 and `rt_types_supported` adds RT-6 with a pack-specific Extract Specifics section.

Until then, invocations of this pack that attempt to classify a finding as RT-6 will fail at SKILL.md Step 2 (Classify the Remediation Type) — RT-6 is not in `rt_types_supported`. The planner routes such findings to RT-4 (section addition to an existing file) or RT-5 (multi-document coordination if the target is cross-cutting) instead.

---

## RT-7 Applicability

**N/A for pmo-platform pack by default.** Manifest-equivalents for pmo-platform (`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`, `release/releases/plans/`) are `release-executor` territory, not `implementation-planner` territory. Proposed manifest updates (e.g., a new RELEASE_LOG entry, a release plan's Verification Evidence section) surface as RT-2 (additive clarification to a section) or RT-4 (new section added) on the relevant governance file, with the release-executor skill responsible for the final population at Stage 12.

Same routing rule as RT-6: invocations attempting RT-7 classification fail at Step 2.

---

## #governance-first-sequencing (Sequencing Rules)

These rules govern batch ordering within a pmo-platform-pack invocation.

1. **Governance-file fixes first.** Changes to `CLAUDE.md`, `core/governance/OPERATIONS.md`, `release/governance/RELEASE_PROTOCOL.md`, and `core/rules/` apply before any downstream skill or reference-doc fix that depends on the updated governance. Governance is the upstream source of truth for skills and reference docs.
2. **Reference-doc fixes before consuming-skill fixes.** E.g., if `review-discipline-principles.md` needs a correction before `build-reviewer/SKILL.md` can reference the corrected section, apply the reference-doc fix first. Same logic for `failure-mode-standard.md`, `reversibility-protocol.md`, `pipeline/`, etc.
3. **Schema fixes before consumer fixes.** Field-level changes to `release/references/schemas/per-skill-output-contracts.md` or the handoff-coordinator schemas apply before individual SKILL.md consumers that reference those fields are updated.
4. **Independent skill fixes parallelize.** Fixes to unrelated SKILL.md files with no cross-skill dependency can land in the same batch.
5. **Rules-mirror coordination.** `core/rules/` and `core/rules/` are byte-identical mirrors per skill-deployment.md. Edits MUST apply to both in the same commit via RT-5 coordination (Coordination Constraint: `diff -q` reports no differences post-edit).

---

## Calibration Context (pmo-platform)

The person executing this plan is a Senior Program Manager / Technical Program Manager familiar with the PMO platform architecture (Layer 1 Engineering / Layer 2 Operations boundary; 13-stage pipeline; governance file hierarchy: CLAUDE.md → OPERATIONS.md → RELEASE_PROTOCOL.md → PROJECT.md).

The operator executes changes on a feature branch under `<OPERATOR_INSTANCE_WORKTREES_PATH>/<branch>/`; the primary checkout (`${HOME}/Claude/`) is read-only for Claude Code sessions per `core/rules/git-workflow.md` Primary Checkout Discipline. Pre-commit hooks + PR review serve the roles CI/CD and automated tests would in a conventional codebase.

Plan records emit Edit-ready specs consumable by Claude Code's native Edit tool; RT-6 and RT-7 Bash blocks are not expected outputs for this pack (see RT-6/RT-7 Applicability above). The operator's working mode is surgical: one RI per Edit, immediate write-verify via Read after each Edit, halt on any mismatch.

The primary concern is precision and non-regression, not speed. A plan that takes twice as long to execute but introduces zero defects is vastly preferable to a fast plan that creates cascading issues — especially given the Rules-mirror coordination constraint (item 5 in Sequencing Rules above): a mismatched edit pair creates a drift the next deploy.sh --check will surface.

---

## Pack Version Log

- **v1.0 (2026-04-19):** Initial authorship per the pluggable-domain Spec 3 Stage 5 design. Mirrors `copilot-builder-domain.md` pack structure; RT-6 and RT-7 N/A for this domain; CRITICAL..LOW severity scale native; `#governance-first-sequencing` rules section authored.
