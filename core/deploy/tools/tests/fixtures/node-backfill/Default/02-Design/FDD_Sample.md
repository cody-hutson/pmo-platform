---
type: fdd
managed_by: ppm-agent
---
# FDD — Fixture Sample (partial frontmatter, non-canonical)

Fixture for the idempotence + append-absent-keys path. This file ALREADY carries a
partial frontmatter block (`type`, `managed_by`). The tool must append only the
9 ABSENT core keys (never overwriting `type`/`managed_by`), and a second run must
produce zero further changes. Synthetic content only.
