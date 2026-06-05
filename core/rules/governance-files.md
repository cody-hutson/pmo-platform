---
paths:
  - "CLAUDE.md"
  - "pmo-platform/governance/**"
---

# Governance File Editing Rules

These files govern the platform. Extra caution applies.

## Before Editing
1. Confirm you're on a feature branch (never edit on main)
2. Read the current file content completely before making changes
3. Verify the change is part of an approved release plan or GitHub Issue

## Change Protocol
- All governance changes require GitHub Issue + user approval
- No "quick fixes" to governance files without paper trail
- The PR diff is the dry-run review — make it reviewable

## Cross-File Impact
When editing one governance file, check if the change affects others:
- CLAUDE.md change → does pmo-platform/governance/OPERATIONS.md need updating?
- OPERATIONS.md change → do skills reference the changed section?
- RELEASE_PROTOCOL.md change → does release-process.md need updating?

## Post-Edit Verification
After committing governance changes:
1. `git diff main..HEAD` — review the full diff
2. Check no Layer 2/3 files were accidentally modified
3. Ensure evidence labels are present on all factual claims
