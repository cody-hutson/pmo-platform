---
title: Process Catalog (core/process-catalog/)
purpose: Orientation for the generated process catalog — what this folder holds, which files are written and which are generated, and where the rules that govern it live.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Process Catalog (`core/process-catalog/`)

The process catalog is the platform's system documentation: one page per process node (universe, value stream, sub-process, activity), with each activity's steps as rows in its page, and an index, a graph and cross-cutting views generated from the pages' frontmatter.

The catalog is a derived, descriptive index: skills, specs and code govern execution, and where a page disagrees with them the page is corrected. Agents execute from skills and specs; pages serve orientation, impact analysis, design and review.

The rules live in one place, [the design-artifact standard](../standards/design-artifact-standard.md), in its section on the generated process catalog: where pages live, the levels and what earns a node a page, page identity and frontmatter, link types, the generated surfaces, the lifecycle and retire step, and how a page cites its sources so that its references stay current. The decision behind the model is {{ADR:system-documentation-is-a-generated-process-catalog}}.

| Path | Written or generated |
|---|---|
| `README.md` (this file) | Written. Orientation only; it never lists pages. |
| `<universe-id>/<node-id>.md` | Written, or seeded from source and corrected: one page per node |
| `INDEX.md`, `graph.json`, `views/` | Generated from page frontmatter; never edited by hand |

Pages are published universe by universe. This file keeps the folder holding at least one tracked Markdown file, which the folder's entry in the shared link-check scope list requires.
