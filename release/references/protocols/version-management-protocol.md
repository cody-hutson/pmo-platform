# PMO Skill Suite — Version Management Protocol

**Purpose:** Establish a rigorous, traceable versioning system for the 14-skill PMO platform, ensuring stability, auditability, and rapid rollback capability.

**Effective Date:** 2026-03-18
**Scope:** All 14 production skills + future skill additions
**Owner:** PMO Cowork Platform Team

---

## 1. Versioning Scheme

All PMO skills use **semantic versioning** in the format `MAJOR.MINOR`.

### Format
`vMAJOR.MINOR` (e.g., `v4.1`, `v1.0`)

### Increment Rules

| Change Type | Increment | When | Example |
|------------|-----------|------|---------|
| **MAJOR** | +1 | Structural changes: new execution modes, fundamental output format restructuring, core behavioral change, reference doc architecture overhaul, or breaking change to trigger conditions | v4 → v5 |
| **MINOR** | +0.1 | Refinements within existing structure: guardrail additions, wording improvements, bug fixes, reference doc additions, or non-breaking prompt optimization | v4 → v4.1 |

### Decision Tree
<!-- design-artifact: flow-class=decision-tree; name=version-management; depicts=release/references/protocols/version-management-protocol.md -->

When preparing a skill update, use this decision tree to determine version increment:

```
Is the change structural? (new mode, output format, reference architecture)
├─ YES → MAJOR increment (e.g., v4 → v5)
└─ NO → Is this a refinement or fix? (guardrail, wording, bug)
    ├─ YES → MINOR increment (e.g., v4 → v4.1)
    └─ NO → Verify change scope with owner before incrementing
```

### Initial Versions

- **Foundation skills (8):** Start at v4 (production-ready)
- **Automation skills (4):** Start at v1 (new to platform)
- **Onboarding skills (1):** Start at v1 (new to platform)
- **Artifact skills (1):** Start at v1 (new to platform)

---

## 2. Changelog Requirements

### File Name
`SKILL_CHANGELOG.md` — must live in the skill's directory alongside SKILL.md

### Location
```
skills/{skill-name}/
├── SKILL.md
├── SKILL_CHANGELOG.md ← Version record
├── references/
└── {skill-name}.skill (packaged)
```

### Template

Each changelog entry follows this template:

```markdown
## Version X.Y — YYYY-MM-DD

**Release Type:** MAJOR / MINOR
**Status:** Approved by [QA Auditor / Skill Editor]
**Regression Check:** [PASS / PASS WITH NOTES / FAIL]

### Changes
- [Specific change description]
- [Specific change description]

### Regression Check Details
- [Regression check performed (e.g., "Test command X produced output Y")]
- [Test output attachment or reference]

### Breaking Changes
None / [List if MAJOR version]

### Backward Compatibility
Full / [Specify if MINOR version has compatibility notes]

### Installation Notes
[Any special notes for deployers, e.g., "Run this after updating", "Requires the automation skills installed first"]

---
```

### Example Entry

```markdown
## Version 4.1 — 2026-03-18

**Release Type:** MINOR
**Status:** Approved by QA Auditor (2026-03-18)
**Regression Check:** PASS

### Changes
- Added artifact-gap-detection.md reference file for Section 8.5
- Enhanced Section 9 (Proactive Next Steps) with five sub-sections
- Expanded follow-up tag list with [ARTIFACT_GAP] tag
- Updated reference docs table to include new references

### Regression Check Details
- Tested with [PROJECT_KEY] transcript (March 17 standoff minutes) — produced 9 sections with new 8.5 and enhanced 9 ✓
- Tested with project status update email — no regression in Sections 1-8 ✓
- Verified [ARTIFACT_GAP] tags parsed correctly by Artifact Generator skill ✓

### Breaking Changes
None

### Backward Compatibility
Full — all existing output sections preserved; new sections are additive

### Installation Notes
New reference files (artifact-gap-detection.md and proactive-follow-up-tracking.md) must be present for skill to function. If upgrading from v4.0, download full v4.1 package.

---
```

### Changelog Maintenance Rules

1. **One entry per version** — never rewrite history; create a new version instead
2. **Record at time of approval** — not during development
3. **Regression check is mandatory** — FAIL is acceptable only if followed by hotfix version
4. **Retain all entries** — even old versions, for audit trail
5. **Include specific evidence** — test output, test data identifiers, dates

---

## 3. Update Workflow

This is the authoritative sequence for updating any skill in the production suite.

### Step 1: Edit Skill (Skill Editor Mode A)
1. Skill Editor loads the skill's SKILL.md
2. Applies targeted edits to prose, guardrails, reference docs, or execution logic
3. **Does NOT increment version yet**
4. Saves updated SKILL.md to staging location (e.g., a `staging/` directory)

### Step 2: Run Regression Tests (Skill Editor Mode C)
1. Skill Editor identifies which tests apply to the change:
   - **Guardrail change?** → Run guardrail-specific tests
   - **Reference doc change?** → Test with sample input that exercises that reference
   - **Prompt refinement?** → Test with historical data that exercises that prompt
   - **New mode or section?** → Create tests for new behavior
2. Execute regression tests on the updated skill
3. Document test names, inputs, outputs, and results in a **Test Report** file:

   ```markdown
   # Regression Test Report — {Skill Name} {proposed version}

   **Date:** YYYY-MM-DD
   **Updated By:** [Editor name]
   **Test Environment:** [e.g., "Cowork staging, with the full skill suite installed"]

   ## Test Summary
   | Test Name | Status | Evidence |
   |-----------|--------|----------|
   | [Test name] | PASS / FAIL | [Brief output or reference] |
   | [Test name] | PASS / FAIL | [Brief output or reference] |

   ## Findings
   - [If PASS: no regressions detected]
   - [If FAIL: specific failures and root cause analysis]

   ## Rollback Assessment
   [If FAIL: can this be fixed with an immediate hotfix, or does it require major rework?]
   ```

4. **If PASS:** Proceed to Step 3
   **If FAIL:** Stop, fix root cause, re-test (return to Step 2)

### Step 3: QA Auditor Validation
1. QA Auditor receives:
   - Updated SKILL.md (from staging)
   - Regression Test Report
   - Old SKILL.md (for diff review)
2. QA Auditor performs independent validation:
   - Spot-check 2-3 critical regression tests
   - Review guardrails for correctness and completeness
   - Verify reference docs are coherent and complete
   - Check for side effects on other skills
3. QA Auditor records approval in a **QA Sign-Off** form:

   ```markdown
   # QA Sign-Off — {Skill Name} {proposed version}

   **QA Auditor:** [Name]
   **Date:** YYYY-MM-DD
   **Status:** APPROVED / APPROVED WITH CONDITIONS / REJECTED

   ## Validation Checklist
   - [ ] Regression tests reviewed and spot-checked
   - [ ] Guardrails verified for logical soundness
   - [ ] Reference docs coherent and complete
   - [ ] No obvious side effects on other skills
   - [ ] Changelog format correct
   - [ ] Version number appropriate for change type

   ## Findings
   - [Specific findings or conditions]

   ## Approval
   Approved for version increment and deployment on [YYYY-MM-DD].
   ```

4. **If APPROVED:** Proceed to Step 4
   **If APPROVED WITH CONDITIONS:** Address conditions before Step 4
   **If REJECTED:** Return to Step 1

### Step 4: Version Increment
1. Increment version number in SKILL.md frontmatter:
   ```yaml
   ---
   version: X.Y
   name: skill-name
   description: ...
   ---
   ```

2. Update SESSION_STATE.md skill registry:
   ```markdown
   | Skill Name | Current Version | Phase | Notes |
   |-----------|----------------|-------|-------|
   | [Skill] | vX.Y | [Phase] | [Update notes if MAJOR] |
   ```

### Step 5: Update Changelog
1. Add new entry to SKILL_CHANGELOG.md (top of file, above older entries)
2. Fill in:
   - Version number
   - Date (approval date from QA Sign-Off)
   - Release type (MAJOR or MINOR)
   - Status (QA Auditor name + date)
   - Regression Check result (PASS / PASS WITH NOTES / FAIL + remediation)
   - Changes list
   - Regression test evidence
   - Breaking changes (if MAJOR)
   - Backward compatibility note

### Step 6: Package .skill File
1. Create a .zip archive containing:
   - SKILL.md (updated with new version)
   - references/ (all updated reference files)
   - SKILL_CHANGELOG.md (with new entry)
2. Name it: `{skill-name}-v{X.Y}.skill` (e.g., `pmo-ppm-agent-v4.1.skill`)
3. Place in the `skills/` directory

### Step 7: Preserve Old Version
1. Extract previous .skill file from skill-archive/
2. If no archive exists yet, create a `skill-archive/` directory
3. Rename old .skill file with version suffix: `{skill-name}-v{old-version}.skill`
   - Example: `pmo-ppm-agent-v4.0.skill`
4. Place in skill-archive/ directory with metadata file:

   ```markdown
   # {skill-name}-v{old-version}.skill — Backup Record

   **Version:** {old-version}
   **Superseded By:** v{new-version} on {date}
   **Archive Date:** {archive date}
   **Reason Archived:** Replaced with v{new-version}

   ## Restoration Command
   If rollback needed: Copy this .skill file back to skills/ directory and reinstall.

   ## SHA256 Checksum
   [Optional: hash of backup file for integrity verification]
   ```

### Step 8: Update Skill Registry
Update SESSION_STATE.md:

```markdown
## Skill Version Registry
| Skill | Current Version | Phase | Notes |
|-------|----------------|-------|-------|
| [Updated Skill] | vX.Y | [Phase] | Updated [date]: [brief change summary] |
```

---

## 4. Rollback Procedure

### When to Rollback

Rollback is triggered when:
1. **Post-deployment regression detected** — New version exhibits unexpected behavior in production that doesn't match regression test results
2. **Critical bug discovered** — v4.1 breaks a workflow that was working in v4.0
3. **QA Auditor finds issue** — Issue not caught in regression tests (rare; indicates test gap)
4. **User-reported issue** — Feature broken or guardrail missing

Rollbacks are NOT triggered by:
- "I'd prefer the old version" without evidence of actual regression
- Minor output wording differences
- Changes to optional reference material

### Rollback Decision Matrix

| Scenario | Decision | Authority |
|----------|----------|-----------|
| Critical bug, user work blocked | Rollback immediately | PMO Lead |
| Moderate issue, affects 1-2 projects | Rollback + hotfix plan | PMO Lead + Skill Editor |
| Minor issue, acceptable workaround exists | Keep current, create hotfix ticket | Skill Editor |
| No clear regression, user perception issue | Keep current, gather evidence | QA Auditor |

### Rollback Steps

#### Phase 1: Verification (< 1 hour)

1. **Reproduce the issue**
   - Document exact conditions: input, skill configuration, expected vs. actual output
   - Attach evidence (screenshots, output samples, transcript excerpt)

2. **Verify regression is real**
   - Re-run the same input against the old version (from skill-archive/)
   - Confirm old version produces correct output
   - If old version also produces issue, root cause is elsewhere — STOP rollback

3. **Assess blast radius**
   - How many projects are affected?
   - Which outputs are broken?
   - Are workarounds available?

4. **Document findings** in a **Rollback Request** form:

   ```markdown
   # Rollback Request — {Skill Name}

   **Requested By:** [Name]
   **Date:** YYYY-MM-DD
   **Current Version:** vX.Y
   **Proposed Rollback Target:** vX.Y-1

   ## Issue Description
   [Clear, reproducible description]

   ## Evidence
   - Input: [Sample data or conditions]
   - Expected output: [What should happen]
   - Actual output with vX.Y: [What actually happens]
   - Actual output with vX.Y-1: [Confirmation that old version works]

   ## Blast Radius
   - Number of affected projects: [#]
   - Affected outputs: [List]
   - Workarounds available: Yes / No

   ## Decision
   [ ] Rollback approved
   [ ] Rollback denied — keep current, create hotfix

   Approved By: [PMO Lead]
   Date: [YYYY-MM-DD]
   ```

#### Phase 2: Execution (15-30 min)

1. **Retrieve old version**
   ```
   From: skill-archive/{skill-name}-v{old-version}.skill
   ```

2. **Restore skill**
   - In Claude Code: Upload {skill-name}-v{old-version}.skill to the skills panel
   - Or in Cowork: Run /install-skill {skill-name}-v{old-version}

3. **Update skill registry**
   - Update SESSION_STATE.md to revert version number
   - Add note: "Rolled back from vX.Y on [date] due to [issue]"

   ```markdown
   | Skill Name | Current Version | Phase | Notes |
   |-----------|----------------|-------|-------|
   | [Skill] | vX.Y-1 | [Phase] | Rolled back from vX.Y on [date]: [issue summary] |
   ```

4. **Verify rollback**
   - Re-run failed test case on rolled-back skill
   - Confirm original behavior restored
   - Document verification results in Rollback Request form

#### Phase 3: Post-Rollback (Ongoing)

1. **Create hotfix ticket**
   ```markdown
   # Hotfix: {Skill Name} vX.Y Regression

   **Issue:** [Summary of what broke]
   **Blocked Version:** vX.Y
   **Rollback Target:** vX.Y-1
   **Root Cause:** [To be determined]
   **Estimated Fix:** [Date or "TBD"]

   **Resolution Plan:**
   1. Skill Editor investigates root cause
   2. Apply minimal fix to vX.Y code
   3. Create vX.Y.1 hotfix version
   4. Run full regression test suite
   5. QA Auditor approves vX.Y.1
   6. Users reinstall vX.Y.1

   **Progress:**
   - [ ] Root cause identified
   - [ ] Fix applied
   - [ ] Regression tests PASS
   - [ ] QA Auditor approval
   - [ ] vX.Y.1 deployed
   ```

2. **Preserve rolled-back version**
   - Move vX.Y .skill file to skill-archive/ with metadata:
   ```markdown
   # {skill-name}-vX.Y.skill — Rolled Back

   **Version:** X.Y
   **Rolled Back:** [YYYY-MM-DD] due to [issue]
   **Replaced By:** vX.Y.1 (hotfix)
   ```

3. **Communicate to users**
   - Send notification: "Rolled back from vX.Y to vX.Y-1 due to [issue]. Hotfix vX.Y.1 planned for [date]."
   - No action required from users; skill automatically uses old version

4. **Hotfix cycle**
   - Skill Editor applies minimal fix to the regression
   - Version becomes vX.Y.1 (next MINOR increment)
   - Run full regression tests (not just regression-specific tests)
   - QA Auditor approves vX.Y.1
   - Users reinstall vX.Y.1

---

## 5. Backup Strategy

### Archive Directory Structure

```
skill-archive/
├── pmo-artifact-generator-v1.0.skill
├── pmo-artifact-generator-v1.0-metadata.md
├── pmo-change-management-v4.0.skill
├── pmo-change-management-v4.0-metadata.md
├── pmo-comms-writer-v4.0.skill
├── pmo-comms-writer-v4.0-metadata.md
├── [... one backup per skill ...]
└── ARCHIVE_MANIFEST.md ← Central index
```

### Naming Convention

**Active Version (Production):**
```
{skill-name}.skill
```
Example: `pmo-ppm-agent.skill` (always current, always v4.1)

**Archived Version:**
```
{skill-name}-v{version}.skill
```
Example: `pmo-ppm-agent-v4.0.skill` (historical backup)

### Metadata File

Each archived .skill file has a companion metadata file:

```markdown
# {skill-name}-v{version}-metadata.md

**Skill:** {Full Name}
**Version:** {X.Y}
**Archive Date:** {YYYY-MM-DD}
**Reason:** [Original deployment / Superseded by vX.Y+1 / Rolled back]
**SHA256:** {hash for integrity verification}
**Installation Command:** `/install-skill {skill-name}-v{version}`

## Restoration Steps
1. Download {skill-name}-v{version}.skill from this archive
2. In Claude Code: Upload to skills directory
3. Update SESSION_STATE.md version field to {version}
4. Reload skill in Cowork interface

## Changelog Reference
See {skill-name}-v{version}-changelog.md for complete change history up to this version.
```

### Retention Policy

**Minimum Retention:** Keep last 2 versions of each skill

**Example Timeline:**
- v4.0 — Original release (2026-03-18)
- v4.1 — Minor enhancement (2026-04-01)
- v4.2 — Bug fix (2026-04-10)

Archive: Keep v4.1 and v4.0
Delete: (none — both within last 2)

If v4.3 released: Delete v4.0, keep v4.2 and v4.1

**Long-Term:** After 12 months, archive to historical record (separate location) and remove from active skill-archive/

### Archive Manifest

Central index file at `skill-archive/ARCHIVE_MANIFEST.md`:

```markdown
# Skill Archive Manifest

**Last Updated:** YYYY-MM-DD
**Retention Policy:** Keep last 2 versions per skill; minimum 12-month history

## Archive Index

| Skill | Version | Archive Date | Reason | Checksum |
|-------|---------|--------------|--------|----------|
| Artifact Generator | v1.0 | 2026-03-18 | Original release | abc123... |
| PPM Agent | v4.0 | 2026-03-18 | Superseded by v4.1 | def456... |
| PPM Agent | v4.1 | 2026-04-01 | Current production version | ghi789... |
| [Skill] | [Ver] | [Date] | [Reason] | [Checksum] |

## Restoration Guide

To restore a previous version:
1. Locate skill in table above
2. Download {skill-name}-v{version}.skill from this directory
3. Follow restoration steps in {skill-name}-v{version}-metadata.md

## Integrity Verification

To verify archive integrity (preventing tampering):
```bash
sha256sum {skill-name}-v{version}.skill
# Compare output to Checksum column above
```

---
```

---

## 6. Operational Procedures

### Before Each Deployment

**Checklist:** One week before any version update release

- [ ] All current skills installed and tested
- [ ] SESSION_STATE.md skill registry current
- [ ] skill-archive/ directory initialized with backups of all current versions
- [ ] ARCHIVE_MANIFEST.md created and current
- [ ] QA Auditor assigned and available
- [ ] Skill Editor regression test harness prepared

### During Each Skill Update

**Workflow:**

1. Skill Editor develops update in staging location
2. Skill Editor runs regression tests (Mode C)
3. Skill Editor submits Test Report to QA Auditor
4. QA Auditor reviews and approves (or requests changes)
5. Upon approval, Skill Editor increments version
6. Skill Editor updates SKILL_CHANGELOG.md
7. Skill Editor packages new .skill file
8. Skill Editor archives old version to skill-archive/
9. Skill Editor updates SESSION_STATE.md registry
10. User installs new .skill file in production Cowork environment

### After Each Skill Update

**Validation (First 24 hours):**

1. User runs skill with typical workflow input
2. User verifies output quality matches regression test results
3. If regression detected → Initiate rollback procedure (Section 4)
4. If no regression → Mark version as "production verified" in SESSION_STATE.md

**Weekly Check (Ongoing):**

- Review RAID log for skill-related issues
- If issue detected → Create hotfix ticket with reproducible case
- Archive metrics: any rollbacks or hotfixes this week? Document in IMPROVEMENTS.md

---

## 7. Version Management Template Files

### SKILL_CHANGELOG.md Template

Keep this template in the skill-archive/ directory as a reference:

```markdown
# {Skill Name} — Version Changelog

Use this template for each version entry.

## Version X.Y — YYYY-MM-DD

**Release Type:** MAJOR / MINOR
**Status:** Approved by [QA Auditor name]
**Regression Check:** PASS / PASS WITH NOTES / FAIL

### Changes
- [Specific change]
- [Specific change]

### Regression Check Details
- [Test name]: [Input], [Expected], [Actual] — [Status]

### Breaking Changes
None / [List]

### Backward Compatibility
Full / [Specify]

### Installation Notes
[Any special instructions]

---
```

### Rollback Request Template

```markdown
# Rollback Request — {Skill Name}

**Requested By:** [Name]
**Date:** YYYY-MM-DD
**Current Version:** vX.Y
**Proposed Rollback Target:** vX.Y-1

## Issue Description
[Concise, reproducible description]

## Evidence
**Input:** [Sample or conditions]
**Expected:** [Correct behavior]
**Actual (vX.Y):** [Broken behavior]
**Actual (vX.Y-1):** [Verification that old version works]

## Blast Radius
Projects affected: [#]
Workarounds: Yes / No

## Decision
[ ] Approved — rollback to vX.Y-1
[ ] Denied — keep vX.Y, create hotfix

Approved By: _____________ Date: _________
```

---

## 8. Governance & Escalation

### Approval Authority

| Action | Authority | SLA |
|--------|-----------|-----|
| MINOR version update | QA Auditor | 24 hours |
| MAJOR version update | PMO Lead + QA Auditor | 48 hours |
| Hotfix (vX.Y.Z) | Skill Editor + QA Auditor | 4 hours |
| Rollback decision | PMO Lead | 1 hour |

### Change Request Log

Maintain a log of all version changes for audit purposes:

```markdown
# Skill Version Change Log — 2026

**Purpose:** Complete audit trail of all skill version changes

| Date | Skill | From | To | Type | Reason | Approved By | Status |
|------|-------|------|----|----|--------|-------------|--------|
| 2026-03-18 | PPM Agent | v4.0 | v4.1 | MINOR | Artifact gap detection + proactive tracking | QA Auditor | DEPLOYED |
| 2026-03-19 | Delivery Engine | v4.0 | v4.0 | — | No changes yet | — | CURRENT |
| [Date] | [Skill] | [From] | [To] | [Type] | [Reason] | [Name] | [Status] |
```

### Escalation Path

**Issue discovered in production:**

1. **Hour 0:** User reports issue → File Rollback Request
2. **Hour 0-1:** PMO Lead and QA Auditor review → Make rollback decision
3. **Hour 1-2:** If rollback approved, execute Phase 2 (Execution)
4. **Hour 2-4:** Create hotfix ticket, assign to Skill Editor
5. **Hour 4-24:** Skill Editor develops and tests hotfix
6. **Hour 24-48:** QA Auditor approves vX.Y.Z hotfix version
7. **Hour 48:** Users reinstall vX.Y.Z

---

## 9. References

**Related Documents:**
- SESSION_STATE.md — Skill version registry (current versions)
- IMPROVEMENTS.md — Change requests and feature proposals
- Per-skill SKILL_CHANGELOG.md files
- QA Auditor report (validation baseline)

**Key Files:**
- `skill-archive/` — Backup storage
- `version-management-protocol.md` — This file
- Individual skill directories: `SKILL.md`, `SKILL_CHANGELOG.md`

---

## 10. Change Log for This Protocol

**Version 1.0 — 2026-03-18**

**Release Type:** MAJOR (initial protocol)
**Status:** Approved for deployment
**Effective:** Immediately upon skill deployment

### Contents
- Semantic versioning scheme (MAJOR.MINOR)
- Changelog requirements and template
- 8-step update workflow (Skill Editor → QA Auditor → deployment)
- Rollback procedure (decision, execution, post-rollback)
- Backup strategy and retention policy
- Operational procedures and escalation path

### Applicability
- All 14 current PMO skills
- All future skill additions
- All version updates from 2026-03-18 forward

---

**Document Owner:** PMO Cowork Platform Team
**Last Updated:** 2026-03-18
**Next Review:** 2026-06-18 (after 3 months of operational use)
