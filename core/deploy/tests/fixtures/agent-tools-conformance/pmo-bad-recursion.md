---
name: pmo-bad-recursion
description: FIXTURE — an agent definition whose `tools:` list includes the recursion surface (Agent). Check 46 finding (b). Not a real agent; lives under core/deploy/tests/fixtures/.
model: opus
tools: Read, Grep, Agent
---

# pmo-bad-recursion (Check 46 fixture)

This fixture lists `Agent` in its `tools:` enumeration. The
agent-tools-list-conformance check must flag it as finding (b) — a spoke that can
spawn sub-spokes is precisely the recursion-prohibition surface the check hardens.
