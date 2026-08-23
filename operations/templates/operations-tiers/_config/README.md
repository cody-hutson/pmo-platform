# _config/ — program-scoped operational config

Operational config shared across every project in this workspace, plus the portfolio-level entity home. Operator-owned, git-ignored.

**What lands here:** `PORTFOLIO.md` (cross-project health), `SESSION_STATE.md` (session handoff), `CORRECTIONS.md` (**platform-wide** behavioral redirects only), `SWAP_HANDOFF.md` (cross-account handoff, auto-written), and `releases/` (pre-git release plans). The Portfolio and Program records live here too — a Program is classified by its `program_id` frontmatter and embedded in its parent config, so there is no dedicated program folder.

**What does not:** project-scoped behavioral redirects — those belong in `projects/[Project]/CORRECTIONS.md`, which overrides this file on the same claim. Git-tracked governance also does not belong here; it lives in the platform repo.

**Not seeded at install.** Install provisions this folder and this card; the member files above are created by the skills that own them, on first use. An absent member file is a normal fresh-workspace state, not a defect.

**Authority:** `pmo-platform/CLAUDE.md` § Governance File Map, *Program-scoped (ops config)* row, and § Operational Tier Taxonomy & Naming Conventions.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._
