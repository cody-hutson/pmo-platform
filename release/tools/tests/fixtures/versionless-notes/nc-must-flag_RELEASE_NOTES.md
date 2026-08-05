---
version: nc-must-flag
date: 2026-08-03
type: note
issues: []
pr: 0
links: []
---
# Negative-control fixture — MUST FLAG

Slug-keyed (version-less) name. Its single Section 6a bullet deliberately omits
the required impact beat and carries no foundational marker, so a lint that can
actually read this file MUST emit exactly one NOTE-NO-WHY-IT-MATTERS naming it.

## What changed for everyone using the platform

- **A change with no impact beat.** This bullet deliberately omits the required beat, which is the single property under test.

## Known limits

- Known limits: this file is a test fixture and describes no shipped behaviour.
- Report issues: open an issue on the platform repository.
