---
name: pmo-bad-missing
description: FIXTURE — an agent definition that omits the `tools:` frontmatter field entirely. Check 46 finding (a). Not a real agent; lives under core/deploy/tests/fixtures/.
model: opus
---

# pmo-bad-missing (Check 46 fixture)

This fixture has no `tools:` field. The agent-tools-list-conformance check must
flag it as finding (a) — an un-enumerated persona is an unbounded tool surface.
