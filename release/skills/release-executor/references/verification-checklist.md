# Release Verification Checklist

## Purpose

This checklist governs post-deployment verification for PMO platform releases. The release-executor skill (Mode B) follows this checklist to validate that the deployed release is correct, complete, and functioning. Verification evidence is persisted in the release plan's Verification Evidence section.

## Verification Dimensions

Five dimensions must be verified for every release. Each dimension has specific check methods and PASS/FAIL criteria.

### Dimension 1: File Integrity

**Question:** Do the deployed files match the expected content?

| Check | Method | PASS Criterion | FAIL Criterion |
|-------|--------|---------------|---------------|
| Git-tracked files match main | `git status` on main after pull | Clean working tree; HEAD matches expected merge commit | Uncommitted changes; HEAD doesn't match |
| Skill files match repo source | `diff release/skills/[name]/SKILL.md "[INSTALLED_PATH]/[name]/SKILL.md"` per changed skill | No differences | Any difference = deployment incomplete |
| Layer 2 propagated files match source | `diff [source] [target]` per manifest entry | No differences | Any difference = propagation incomplete |
| Version tag exists | `git tag --list 'vX.Y'` and `gh release view vX.Y` | Tag present locally and on remote | Tag missing |

### Dimension 2: Content Correctness

**Question:** Does the file content achieve what the release intended?

| Check | Method | PASS Criterion | FAIL Criterion |
|-------|--------|---------------|---------------|
| New sections present | Read file; verify sections listed in release plan exist | All planned sections present with content | Missing sections |
| Removed content absent | Read file; verify deletions listed in release plan are gone | Deleted content absent | Deleted content still present |
| Modified content correct | Read file; verify modifications match release plan specifications | Content matches specification | Content diverges from specification |
| No unintended changes | `git diff vX.(Y-1)..vX.Y -- [file]` for each changed file | Only planned changes visible | Unplanned changes present |

### Dimension 3: Cross-Reference Validity

**Question:** Do references between files remain valid after the release?

| Check | Method | PASS Criterion | FAIL Criterion |
|-------|--------|---------------|---------------|
| File path references resolve | For each `reference/[file].md` reference in changed skills, verify target exists | All referenced files exist | Broken reference (file path doesn't resolve) |
| Skill cross-references valid | For each skill that references another skill by name, verify referenced skill exists | All referenced skills exist at installed path | Referenced skill missing |
| Governance file references valid | For each governance file reference in CLAUDE.md or core/rules/, verify target exists | All referenced governance files exist | Broken governance reference |
| Version references current | For any version number embedded in files, verify it matches current release | Version numbers match vX.Y | Stale version number from prior release |

### Dimension 4: Skill Invocation

**Question:** Do changed skills produce expected behavior when invoked?

| Check | Method | PASS Criterion | FAIL Criterion |
|-------|--------|---------------|---------------|
| Skill loads without error | Invoke skill in Cowork; observe load behavior | Skill loads; no error messages | Skill fails to load; error displayed |
| Output structure correct | Invoke skill with standard input; check output sections | Expected sections present in output | Missing sections or malformed output |
| Mode selection works | For multi-mode skills, invoke each mode | Each mode produces mode-specific output | Wrong mode output or mode not recognized |
| Reference file integration | Invoke skill that reads a changed reference file | Skill reflects updated reference content | Skill uses stale content |

**Note:** Skill invocation verification requires manual execution by the user in Cowork. The agent provides the verification script (which skills to invoke, what inputs to use, what to check), and the user executes and reports results.

### Dimension 5: Output Contract Compliance

**Question:** Does the release maintain compliance with platform output contracts?

| Check | Method | PASS Criterion | FAIL Criterion |
|-------|--------|---------------|---------------|
| Evidence quality labels present | Sample outputs from changed skills | Factual claims tagged per evidence-quality.md | Untagged claims in output |
| Follow-up tags valid | Sample outputs that should emit tags | Tags match follow-up-tags.md vocabulary | Unrecognized tags or missing tags |
| Push-to-resolve compliance | Sample outputs checked for anti-patterns | No task dumping, recommendation without action, or placeholder artifacts | Anti-pattern detected in output |
| Output format compliance | Sample outputs checked against output-format.md | Standard sections present (header, summary, body, next actions) | Missing required sections |

## PASS/FAIL Criteria Summary

| Dimension | All Checks PASS | Any Check FAIL |
|-----------|----------------|---------------|
| **File Integrity** | Release deployed correctly | Re-execute failed deployment step; re-verify |
| **Content Correctness** | Release content matches plan | Investigate divergence; fix forward or document exception |
| **Cross-Reference Validity** | No broken references | Fix broken references on main; tag patch release if needed |
| **Skill Invocation** | Skills function correctly | Diagnose failure; fix forward or rollback affected skill |
| **Output Contract Compliance** | Platform contracts maintained | Log as defect; schedule fix in next release |

**Release-level verdict:**
- All 5 dimensions PASS = Release verified. Proceed to Stage 13 Close.
- Dimensions 1-3 PASS, Dimension 4 or 5 has minor failures = Release verified with conditions. Document exceptions; schedule fixes.
- Any Dimension 1-3 FAIL = Release NOT verified. Fix or rollback required before Close.

## Verification Evidence Format

Evidence is persisted in the release plan's Verification Evidence section:

```markdown
## Verification Evidence — vX.Y

**Verified by:** [Agent/User]
**Verification date:** [YYYY-MM-DD (Day)]
**Verdict:** PASS / PASS WITH CONDITIONS / FAIL

### Dimension Results

| # | Dimension | Result | Method | Notes |
|---|-----------|--------|--------|-------|
| 1 | File Integrity | PASS/FAIL | [method used] | [any notes] |
| 2 | Content Correctness | PASS/FAIL | [method used] | [any notes] |
| 3 | Cross-Reference Validity | PASS/FAIL | [method used] | [any notes] |
| 4 | Skill Invocation | PASS/FAIL | [method used] | [any notes] |
| 5 | Output Contract Compliance | PASS/FAIL | [method used] | [any notes] |

### Exceptions (if PASS WITH CONDITIONS)
| Exception | Severity | Remediation Plan | Target Date |
|-----------|----------|-----------------|------------|
| [description] | Minor/Major | [plan] | [date] |
```
