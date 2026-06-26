---
name: pmo-good
description: FIXTURE — a conformant agent definition with a `tools:` list and no recursion surface. Check 46 must NOT flag it. Not a real agent; lives under core/deploy/tests/fixtures/.
model: opus
tools: Read, Grep, Bash
---

# pmo-good (Check 46 fixture)

This fixture declares a `tools:` field with no recursion-surface tool (no Agent /
spawn_task / mcp__ccd_session__spawn_task). The agent-tools-list-conformance check
must produce zero findings against it.
