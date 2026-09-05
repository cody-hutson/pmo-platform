---
title: Governance File Editing Rules
purpose: The editing-protocol rules for platform governance files — the before-editing checks, the change protocol, and the extra-caution discipline that applies because these files govern the platform.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
paths:
  - "CLAUDE.md"
  - "pmo-platform/core/governance/**"
---

<!-- reference-durability: allow-link -->

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
- CLAUDE.md change → does core/governance/OPERATIONS.md need updating?
- OPERATIONS.md change → do skills reference the changed section?
- RELEASE_PROTOCOL.md change → does release-process.md need updating?

Before writing to **any** memory surface (a governance file, a state file, the auto-memory store, a tracker), consult [`memory-architecture.md`](/core/disciplines/memory-architecture.md) — the unified cross-surface contract — for that surface's read/write class (read-only / auto-write / operator-write-only) and its SSOT, so a write never creates a shadow copy of a fact another surface owns.

## Post-Edit Verification
After committing governance changes:
1. `git diff main..HEAD` — review the full diff
2. Check no Layer 2/3 files were accidentally modified
3. Ensure evidence labels are present on all factual claims
