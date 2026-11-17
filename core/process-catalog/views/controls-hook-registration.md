---
title: Controls — hook-registration
purpose: The 27 controls whose mechanism kind is hook-registration, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — hook-registration

27 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-085 | PreToolUse on matcher Bash runs .claude/hooks/block-destructive.sh | code-enforce | hook | `core/settings.json.template` | — |
| C-086 | PreToolUse on matcher Bash runs .claude/hooks/block-egress.sh | code-warn | hook | `core/settings.json.template` | — |
| C-087 | PreToolUse on matcher Bash runs .claude/hooks/block-gh-path-leak.sh | code-warn | hook | `core/settings.json.template` | — |
| C-088 | PreToolUse on matcher Bash runs .claude/hooks/block-shell-injection.sh | code-warn | hook | `core/settings.json.template` | — |
| C-089 | PreToolUse on matcher Bash runs .claude/hooks/block-rm-prefer-trash.sh | code-enforce | hook | `core/settings.json.template` | — |
| C-090 | PreToolUse on matcher Bash runs .claude/hooks/block-fs-boundary.sh | code-off | hook | `core/settings.json.template` | — |
| C-091 | PreToolUse on matcher Bash runs .claude/hooks/block-autonomy-ceiling.sh | code-enforce (floor) / code-off (ceiling) | hook | `core/settings.json.template` | — |
| C-092 | PreToolUse on matcher Bash runs .claude/hooks/block-scope-segregation.sh | code-enforce (-004) / code-warn | hook | `core/settings.json.template` | — |
| C-093 | PreToolUse on matcher Write runs .claude/hooks/block-destructive.sh | code-enforce | hook | `core/settings.json.template` | — |
| C-094 | PreToolUse on matcher Write runs .claude/hooks/block-skill-direct-edit.sh | code-off | hook | `core/settings.json.template` | — |
| C-095 | PreToolUse on matcher Write runs .claude/hooks/block-fragile-refs.sh | code-off | hook | `core/settings.json.template` | — |
| C-096 | PreToolUse on matcher Write runs .claude/hooks/block-draft-files.sh | code-off | hook | `core/settings.json.template` | — |
| C-097 | PreToolUse on matcher Write runs .claude/hooks/block-autonomy-ceiling.sh | code-enforce (floor) / code-off (ceiling) | hook | `core/settings.json.template` | — |
| C-098 | PreToolUse on matcher Edit runs .claude/hooks/block-destructive.sh | code-enforce | hook | `core/settings.json.template` | — |
| C-099 | PreToolUse on matcher Edit runs .claude/hooks/block-skill-direct-edit.sh | code-off | hook | `core/settings.json.template` | — |
| C-100 | PreToolUse on matcher Edit runs .claude/hooks/block-fragile-refs.sh | code-off | hook | `core/settings.json.template` | — |
| C-101 | PreToolUse on matcher Edit runs .claude/hooks/block-autonomy-ceiling.sh | code-enforce (floor) / code-off (ceiling) | hook | `core/settings.json.template` | — |
| C-102 | PreToolUse on matcher Read runs .claude/hooks/block-credential-reads.sh | code-enforce | hook | `core/settings.json.template` | — |
| C-103 | PreToolUse on matcher WebFetch runs .claude/hooks/block-egress.sh | code-warn | hook | `core/settings.json.template` | — |
| C-104 | PreToolUse on matcher mcp__.* runs .claude/hooks/block-mcp-writes.sh | code-off | hook | `core/settings.json.template` | — |
| C-105 | PreToolUse on matcher mcp__.* runs .claude/hooks/block-autonomy-ceiling.sh | code-enforce (floor) / code-off (ceiling) | hook | `core/settings.json.template` | — |
| C-106 | PreToolUse on matcher mcp__.* runs .claude/hooks/block-scope-segregation.sh | code-enforce (-004) / code-warn | hook | `core/settings.json.template` | — |
| C-107 | PreToolUse on matcher mcp__.* runs .claude/hooks/block-external-seam-shape.sh | code-off | hook | `core/settings.json.template` | — |
| C-108 | SessionStart on matcher (all) runs .claude/hooks/notify-version-skew.sh | code-warn | hook | `core/settings.json.template` | 1 page |
| C-109 | SessionStart on matcher (all) runs .claude/hooks/prime-autonomy-ceiling-cache.sh | not-a-control | hook | `core/settings.json.template` | — |
| C-110 | SessionStart on matcher (all) runs .claude/hooks/verify-session-config.sh | code-off | hook | `core/settings.json.template` | 1 page |
| C-111 | Stop on matcher (all) runs .claude/hooks/session-retro-trigger.sh | code-off | hook | `core/settings.json.template` | 3 pages |
