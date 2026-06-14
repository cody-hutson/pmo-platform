# Canonical Skill Structure — PMO Skills

**Last Refreshed:** 2026-04-22

## §1 Purpose

This document is the canonical specification for every skill authored under `{operations,release,core}/skills/`. It closes the documented-but-not-enforced gap identified by the 2026-04-20 skill discipline audit and establishes the structural contract that dual-gate enforcement (`.claude/hooks/block-skill-direct-edit.sh` at edit-time + `deploy.sh --check` Checks 6-10 at deploy-time) guarantees. It governs Phase 1 of the Skill Discipline release; subsequent per-skill migration brings existing skills into compliance.

**Reversibility tier:** MODERATE — Confidence: HIGH. Enforcement gates are toggleable via `.claude/hooks/.mode` file flip and via migration-marker removal from a skill's frontmatter. The spec itself is per-commit revertable.

## §2 Scope of Enforcement

The forcing function per D-Creator targets **existing chained PMO skill modifications**, not new-skill creation. This boundary is explicit so non-enforcement is visible for future re-evaluation — silent non-enforcement is the pattern that produced the original gap.

### What IS enforced

| Surface | Gate | Mechanism |
|---|---|---|
| Existing-skill SKILL.md modifications | DUAL-GATE | `pmo-skill-editor` required (edit-time hook + deploy-time audit-trail) |
| Required frontmatter fields (name, description, version) | Deploy-time | `deploy.sh --check` Check 6 |
| Structure thresholds per §5 | Deploy-time | `deploy.sh --check` Check 6 (D-Refs threshold evaluation) |
| Version-field currency | DUAL-GATE | Covered by [version-field-semantics.md](version-field-semantics.md) per D-Version |
| `.skill` package freshness | Deploy-time | `deploy.sh --check` Check 7 |
| Canonical session path freshness | Deploy-time | `deploy.sh --check` Check 8 |
| Rules-mirror pair byte-identity | Deploy-time | `deploy.sh --check` Check 9 |
| Editor audit-trail on migrated skills | Deploy-time | `deploy.sh --check` Check 10 |

### What is NOT enforced (intentional non-enforcement boundary)

NEW skill creation. A skill may be authored via:

- `anthropic-skills:skill-creator` (Anthropic-provided scaffolder)
- `pmo-skill-refiner` Mode 2 "Create New" (PMO wrapper that applies 7-field injection + pre-handoff Principal Standard gate)
- Direct authoring

PMO tooling does NOT gate the NEW-skill authoring path. **Rationale:** per D-Creator Option A, new skills cannot yet have chained dependencies that require coherence enforcement; the forcing function applies to modifications of the existing-skill surface. Direct authoring does NOT automatically satisfy [principal-standard-checklist.md](principal-standard-checklist.md) or [failure-mode-standard.md](../specs/failure-mode-standard.md); those are checked at PR review time and at `pmo-qa-auditor` invocation, not by this spec.

### Excluded skills

`docx`, `pdf`, `pptx`, `xlsx`, `schedule` — Cowork-provided proprietary skills managed by Anthropic. They are outside PMO governance surface and are explicitly not registered in `deploy.sh` per-module arrays (`OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS`). Enforcement gates skip these by exclusion.

## §3 Required Frontmatter Fields

Every `{operations,release,core}/skills/<skill>/SKILL.md` MUST include YAML frontmatter at the file head with the following fields:

| Field | Type | Required | Enforcement | Purpose |
|---|---|---|---|---|
| `name` | string | YES | Check 6 (presence); validated against skill-dir name | Skill identifier |
| `description` | multi-line string | YES | Check 6 (presence); length ≤ 1024 chars per existing rule | Trigger description consumed by the harness |
| `license` | string (SPDX id, `BUSL-1.1` for PMO skills) | YES | `quick_validate.py` (presence); guards the selftest canary | Declares the skill's distribution license; PMO skills ship under Business Source License 1.1 |
| `version` | string matching `^v[0-9]+\.[0-9]+(-[a-z]+)?$` | YES | Check 6 (presence) + dual-gate per [version-field-semantics.md](version-field-semantics.md) | Release-tag-at-last-material-edit |
| `skill_discipline_migrated_v10_2` | bool | YES post-migration | Gate-activation marker (hook + Check 10 skip pre-migration) | Signals per-skill opt-in to live gates; set by per-skill migration commits |
| `delivery_approach` | string | RECOMMENDED | Check 6 warn if missing on delivery-sensitive skills | Declarative delivery posture (advisory vs decisive) |
| `principal_standard_pass` | string | RECOMMENDED | `pmo-skill-refiner` pre-handoff evidence | Scoring Guide tier per [principal-standard-checklist.md § Single Source Rule](principal-standard-checklist.md#single-source-rule) — use vocabulary (PASS / CONDITIONAL PASS / FAIL), not numeric ratios |

Additional frontmatter fields are allowed; unknown fields are ignored by enforcement.

**Migration marker semantics.** The `skill_discipline_migrated_v10_2: true` field is the activation signal for per-skill gate enforcement. Skills WITHOUT the marker pass through the hook (exit 0) and through Check 10 (skipped). This is non-breaking-on-legacy by design: the gate activates per skill as per-skill migration commits land.

## §4 File Layout Requirements

### Mandatory at skill root

- `SKILL.md` — entry point; contains frontmatter + skill body
- `LICENSE` — NOT committed in the skill source tree; the canonical Business Source License 1.1 is **injected into every `.skill` package at package-build time** at `<skill>/LICENSE`, byte-identical to the repo-root `/LICENSE`. This satisfies the BSL conspicuous-display requirement on every distributed artifact and is enforced by `release/tools/check-skill-licenses.py` (CI gate `skill-license-check.yml`). Vendored-dependency licenses under a different license (e.g. `pmo-skill-refiner`'s Apache-2.0 eval/optimization harness) MUST be path-scoped to their own subtree — `eval-viewer/LICENSE.txt` — with a root `NOTICE` describing the split, so the injected root `LICENSE` remains the unambiguous package license.

### Conditional

- `reference/<topic>.md` — REQUIRED per §5 threshold. Multiple reference files may be present; they are bundled into the `.skill` package at `references/` at package-build time.

### Optional (author discretion)

- `scripts/` — utility scripts invoked by the skill
- `agents/` — agent-definition files (supplementary-tree skills listed in `deploy.sh` `SUPPLEMENTARY_SKILLS` get full-tree deployment)
- `assets/` — static assets
- `eval-viewer/` — eval viewer subtrees

### Forbidden at skill root

- `.editor-session` — runtime-only sentinel written by `pmo-skill-editor` at Mode A entry; committed artifacts of this file MUST NOT land in git. The workspace-root `.gitignore` excludes the per-module sentinel globs `operations/skills/*/.editor-session`, `release/skills/*/.editor-session`, and `core/skills/*/.editor-session`.

## §5 When Reference Files Are REQUIRED

A skill MUST have a non-empty `reference/` subdirectory (≥1 `*.md` file) when ANY of the following three conditions are true (per D-Refs Option B):

1. `wc -l SKILL.md` > **400**
2. `wc -c SKILL.md` > **25600** (25 KB)
3. The `## Domain-Specific Failure Modes` section has **≥ 4** entries (regex `^### .+ — (TRIG|INPUT|PROC|OUT|HAND)`, per [failure-mode-standard.md](../specs/failure-mode-standard.md)) **AND** the skill had `references/*.md` files in its baseline `.skill` package tarball

### Exemption

Skills listed in `.claude/skill-editor-exemption-list.txt` are exempt from the threshold. Initial list contains `pmo-skill-refiner-selftest-canary` (canary-by-design; deliberately minimal). Operator additions follow the "No ungoverned changes" protocol (CLAUDE.md Guardrails) via a tracked GitHub Issue.

### Worked examples (from the 2026-04-20 audit Finding 3)

- `ppm-agent` — 654 lines, 40 KB, 4 failure modes, baseline had 8 refs → REQUIRED (all 3 criteria)
- `release-executor` — 341 lines, 22 KB, 4 failure modes, baseline had 3 refs → REQUIRED (criterion 3 only; below line/size)
- `daily-status` — 226 lines, 13 KB, 3 failure modes, baseline had 0 refs → NOT required (all criteria fail)
- `pmo-skill-refiner-selftest-canary` — 125 lines, 9 KB, 3 failure modes → EXEMPTED (list)

### Measurement protocol

- Measure SKILL.md source file, not the packaged tarball
- Use the exact regex above for failure-mode entry counts
- Baseline package contents retrievable via `git archive <baseline-tag> pmo-platform/packages/<skill>.skill | tar xO`

## §6 Versioning Rules

Version semantics — including bump criteria, backfill policy, and maintenance protocol — are defined in [version-field-semantics.md](version-field-semantics.md). This spec ratifies the dual-gate enforcement mechanism; the semantic rules live in that document.

**Enforcement (DUAL-GATE per D-Version Option C):**

- **Edit-time:** Hook `BLOCK-SKILL-EDIT-001` rejects direct SKILL.md edits to migrated skills → edits flow through `pmo-skill-editor`, which is responsible for version-field maintenance per that doc's contract.
- **Deploy-time:** `deploy.sh --check` Check 6 asserts the `version:` field is present and matches the format regex. Currency assertions per [version-field-semantics.md](version-field-semantics.md) are expected to live alongside the framework Check 6 establishes.

## §7 Failure-Mode Discipline

Every skill must document ≥3 domain-specific failure modes per [failure-mode-standard.md](../specs/failure-mode-standard.md). Each entry uses the 5-field template (Signature, Conditional, Root cause, Mitigation, Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

**Structural validation** is already enforced by `pmo-qa-auditor` gate G7. This canonical spec ratifies that gate and extends deploy-time enforcement: Check 6 FAILs if `## Domain-Specific Failure Modes` is missing or has <3 entries.

## §8 Reversibility Discipline

Decision-class outputs from any skill (recommendations, plans, escalations, proposed actions) must declare a reversibility tier + confidence per [reversibility-protocol.md](../specs/reversibility-protocol.md) — CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE × HIGH / MEDIUM / LOW.

Enforcement lives at skill-output-audit time (`pmo-qa-auditor` gate G4), not at deploy-time. This spec cross-references the protocol so skills authored or migrated under this spec adopt it by default.

## §9 Canonical Exemplars

### Currently-canonical (pre- migration)

The audit's `has-references-currently` cohort (Finding 1) — five skills whose baseline reference subtrees survive at head:

- `build-reviewer/` — dimension-packs architecture + shared-review-discipline cross-reference
- `eval-writer/`
- `implementation-planner/`
- `pmo-skill-refiner/`
- `prompt-builder/`

These are the reference examples for structure + `reference/` subtree patterns until per-skill migration restores the lost-references cohort.

### Post-migration exemplars

Once migration restores the lost references, the following skills will demonstrate full canonical structure:

- `ppm-agent/`, `delivery-engine/`, `project-initiator/`, `weekly-status-rollup/`

### Explicit non-exemplars

- **Pre-migration lost-references cohort (13 skills per audit Finding 1).** Their currently-rendered structure is NOT canonical reference — the audit documents why.
- **`pmo-skill-refiner-selftest-canary`.** Permanently exempted. A deliberately-minimal smoke test; not a structural reference.

### Principal Standard alignment

When a skill's output is evaluated against [principal-standard-checklist.md](principal-standard-checklist.md), use [Scoring Guide vocabulary](principal-standard-checklist.md#single-source-rule) (PASS / CONDITIONAL PASS / FAIL) — not embedded numeric ratios. The checklist's competency count may evolve; Scoring Guide semantics are stable.

## §10 Revision History & Governance

This canonical spec is itself a governance document. Modifications require the "No ungoverned changes" protocol (CLAUDE.md Guardrails): GitHub Issue → implementation plan → branch + PR → diff review → merge. Versioned by git history; no `## Version History` ledger in the file body (git is authoritative).

### Revision log (external)

| Release | Issue | Summary |
|---|---|---|
| — | release issue | Initial canonical spec. Published alongside dual-gate enforcement infrastructure (`block-skill-direct-edit.sh` hook + `deploy.sh --check` Checks 6-10). |

---

**Document Owner:** PMO Engineering
**Status:** Active
**Cross-references:** [version-field-semantics.md](version-field-semantics.md) · [principal-standard-checklist.md](principal-standard-checklist.md) · [failure-mode-standard.md](../specs/failure-mode-standard.md) · [reversibility-protocol.md](../specs/reversibility-protocol.md)
