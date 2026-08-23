# projects/ — the operations workspace

The operations domain (Layer 2). Everything under this folder is operator-owned working content, git-ignored in its entirety, and organized by **tier** — portfolio → program → project.

**What lands here:** one folder per project (`[Project]/`, Title-case); the program-scoped operational config in `_config/`; the cross-project shared-entity store in `_pmo/`; closed projects in `Archive/`.

**What does not:** platform-engineering content — governance, skills, schemas, standards, deploy tooling. That is Layer 1 and lives in the tracked platform repo. A governance file authored here is misplaced by construction.

**Path convention in these cards:** paths are written workspace-rooted (`pmo-platform/core/...`, `projects/_config/...`), resolved from the workspace root that contains both this folder and the platform repo.

**Authority:** `pmo-platform/CLAUDE.md` § Governance File Map (placement) and § Platform vs. Working Content Boundary (layers); `pmo-platform/core/governance/OPERATIONS.md` (protocols).

_Orientation only. These seed cards describe where things go; they never override the governance files they cite. If a card ever disagrees with its cited authority, the authority wins._
