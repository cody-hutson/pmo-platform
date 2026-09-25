<!-- repo-integrity: allow-issue-ref — limb 1: synthetic fixture ids, not repo issues -->
<!-- Test FIXTURE for verify-release-plan.sh: the #N tokens below are synthetic release-plan test data, not references to real work items. -->
# vTEST Release Plan — the native scope family

> Fixture for `release/tools/tests/test_verify_release_plan.sh` group G17, arms V6848-AC1 and V6848-AC4: every scope row is graded against the release diff a test seam supplies, never against git.

## File Change Matrix

```
release/tools/verify-release-plan.sh  EDIT
release/tools/tests/test_verify_release_plan.sh  EDIT
```

## Verification Plan

**#980 — the native scope family**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `git diff --name-only origin/main...HEAD -- core/skills/` expect 0 | nothing changed under core/skills/ · control: AC-3 |
| AC-2 | `git diff --name-only origin/main...HEAD -- . ':!release/'` expect 0 | every changed path sits under release/ · control: AC-3 |
| AC-3 | `git diff --name-only origin/main...HEAD -- release/tools/` expect 2 | control: the same instrument reaches the changed paths |
| AC-4 | `git diff --name-only origin/main...HEAD -- release/references/` expect 0 | deliberately failing on the mixed seam |
| AC-5 | `git diff --name-only origin/main...HEAD -- '*/SKILL.md'` expect 0 | a glob pathspec |
| AC-6 | `git diff origin/main...HEAD -- release/tools/ \| grep -c y` expect 0 | a pipeline: outside the grammar |
| AC-7 | `git diff --name-only 18e3e787..HEAD -- core/` expect 0 | a pinned range: not the release diff |
| AC-8 | `git diff --name-only origin/main...HEAD -- ':(top)CLAUDE.md'` → empty | no comparator: outside the grammar |
| AC-9 | `git diff --name-only origin/main...HEAD -- release/references/` expect 0 (at least 1 path elsewhere) | two comparators that disagree: graded on neither |
| AC-10 | `git diff --name-only origin/main...HEAD -- <skill-dir>` expect 0 | a placeholder pathspec names no path |
| AC-11 | `git diff --name-only origin/main...HEAD -- core/skils/` expect 0 | a typo: the pathspec selects nothing |
| AC-12 | `git diff --name-only origin/main...HEAD -- core/skils/` at least 0 | control: the selects-nothing guard reads only an == or <= assertion |
| AC-13 | `git diff --name-only origin/main...HEAD -- core/skills/` expect 0; `python3 release/tools/check-adr-numbers.py` confirms the numbering | a second command that did not run: never a pass |
