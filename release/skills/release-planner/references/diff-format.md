# Diff Output Format

## Purpose

This document defines the standard format for presenting file change diffs in dry-run previews, release plans, and PR descriptions. The format is designed for human readability — not raw `git diff` output — while preserving enough detail for accurate review.

## Summary Format

Every diff output begins with a summary section:

```markdown
## Change Summary

| Metric | Count |
|--------|-------|
| Files affected | [N] |
| Files created | [N] |
| Files modified | [N] |
| Files deleted | [N] |
| Sections added | [N] |
| Sections modified | [N] |
| Sections removed | [N] |
| Net lines added | [+N] |
| Net lines removed | [-N] |
```

## Section-Level Diff

For each affected file, present changes at the section level (not line level). This is the primary review format.

### Format for Modified Files

```markdown
### [File Path]
**Change type:** Modified
**Issues:** #N, #M
**Risk:** Low / Medium / High
**Blast radius:** [N] files reference this file

#### Section: [Section Name]
**Change:** Added / Modified / Removed / Moved

**Before:**
> [Relevant excerpt of current content — enough context to understand the change.
> Use blockquote formatting. Truncate long sections with "[...N lines...]"]

**After:**
> [Relevant excerpt of proposed content — same scope as "Before".
> Use blockquote formatting. Highlight key changes with **bold**.]

**Rationale:** [Why this change is being made — links to issue #N]
```

### Format for New Files

```markdown
### [File Path] (NEW)
**Change type:** Created
**Issues:** #N
**Risk:** Low / Medium / High

#### Content Summary
[Brief description of what the new file contains — 2-3 sentences]

#### Key Sections
- [Section 1]: [Brief description]
- [Section 2]: [Brief description]
- [Section N]: [Brief description]

**Full content:** Available in PR diff for detailed review.
```

### Format for Deleted Files

```markdown
### [File Path] (DELETED)
**Change type:** Deleted
**Issues:** #N
**Risk:** [Typically Medium-High — deletion is harder to reverse]

**Reason for deletion:** [Why this file is being removed]
**References to update:** [Files that reference this file and need updating]
**Content preserved in:** [Git history / archived location / N/A]
```

## Presentation Rules

| Rule | Rationale |
|------|-----------|
| **Section-level, not line-level** | Reviewers care about semantic changes, not character diffs |
| **Before/after pairs** | Side-by-side context enables faster review than unified diff |
| **Rationale per section** | Every change must explain why, not just what |
| **Risk rating per file** | Focuses reviewer attention on highest-risk changes |
| **Blast radius notation** | Alerts reviewer to downstream impact |
| **Truncation with line count** | Long sections truncated with "[...N lines...]" to keep diff readable |
| **Bold key changes** | Within "After" blocks, **bold** the specific words/phrases that changed |

## Scope Guidelines

| Diff Scope | Format |
|-----------|--------|
| **Small release (1-3 files)** | Full section-level diff for all files |
| **Medium release (4-10 files)** | Section-level diff for modified files; content summary for new files |
| **Large release (10+ files)** | Summary + section-level diff for high-risk files only; content summary for remaining |

## Integration with PR Body

When the diff format is used in a PR body (Stage 6 Engineering), it follows the PR template structure:

```markdown
## Summary
[1-3 bullet points describing the release]

## Implementation Table
| Issue | Files Changed | Change Type | Status |
|-------|-------------|------------|--------|
| #N | [files] | [types] | Complete |

## Key Changes (Section-Level Diff)
[Section-level diffs for the most significant changes]

## Verification Evidence
[How changes were verified during engineering]
```

## Non-Git Diff Contexts

For changes that deploy outside git (GitHub Projects configuration, external system settings), use this format:

```markdown
### [System/Component]
**Change type:** Configuration change
**Deployment mechanism:** GitHub API / Manual / Script

**Current state:**
> [Description or screenshot of current configuration]

**Proposed state:**
> [Description of proposed configuration]

**Rollback method:** [How to reverse this change]
**Verification method:** [How to confirm the change was applied correctly]
```
