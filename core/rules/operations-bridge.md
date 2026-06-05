# Operations Bridge — File Interaction Rules

## Organizational Model
The PMO platform operates as two departments:
- **Engineering** (Claude Code / Code tab): owns `pmo-platform/`, organized by function
- **Operations** (Cowork / Cowork tab): owns `projects/`, organized by tier (portfolio/program/project)

Connected via the 13-stage deployment pipeline (see release-process.md).

## Layer Classification
- **Layer 1 (Git-Tracked, Engineering):** CLAUDE.md, `pmo-platform/` (entire tree),
  `.claude/settings.json`, `.claude/rules/`, `.gitignore`, `README.md`, `deploy.sh`
- **Layer 2 (Git-Ignored, Operations):** `projects/` (entire tree),
  `.claude/skills/` (deployment target), `.claude/settings.local.json`, `memory/`

## Cross-Domain Read Access
Claude Code MAY READ these Layer 2 files for context:
- `projects/_config/PORTFOLIO.md` — cross-project health data
- `projects/_config/SESSION_STATE.md` — session continuity
- `projects/_config/CORRECTIONS.md` — active behavioral redirects

Claude Code does NOT WRITE to any Layer 2 file.

## Rules for Claude Code
1. NEVER modify Layer 2 files. They are the Operations domain.
2. Cross-domain reads are read-only. Never write to `projects/` files.
3. Improvements are tracked as GitHub Issues (not files). No bridge file mechanism needed.
4. If `git diff` shows a Layer 1 file was modified outside git (by Cowork):
   a. Review the diff — is the change intentional?
   b. If intentional: `git add [file] && git commit -m "fix: incorporate Cowork change"`
   c. If accidental: `git checkout -- [file]` to restore committed version
   d. Create a GitHub Issue for the boundary violation

## Concurrency Rule
Close Cowork before starting git operations. Both tools access the same filesystem.
No file locking between them. Convention is behavioral — close Cowork, do git work,
reopen Cowork when done.

For deployment operations, use `./deploy.sh --deploy` after merging to main.
This copies changed skills from pmo-platform/ to the Cowork install path.

Concurrent-session risk grows with auto-mode, scheduled tasks, and multi-session
usage. After switching back from Cowork and before any git operation, run
`git status` / `git diff` — an unexpected dirty Layer 1 file is the detection
signal (resolve per Rule 4 above). Full detection / prevention / recovery
conventions, the per-layer (1 git-managed / 2 operational / 3 bridge-file)
safeguard model, and the bridge-file write-safety convention are specified in
`pmo-platform/reference/how-to/concurrency-safeguards.md`.
