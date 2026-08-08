---
title: Git Workflow — pmo-platform
purpose: The git workflow rules for pmo-platform — branching, commit-message, primary-checkout, worktree, PR-process, and repository-integrity-gate discipline.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Git Workflow — pmo-platform

## Repository
- Remote: github.com/[OPERATOR_GITHUB]/pmo-platform (private)
- Default branch: main
- All changes go through PRs — no direct commits to main

## Branching Convention
- Feature (with tracked issue): `feature/#N-description` (e.g., `feature/16-github-feature-strategy`)
- Feature (cross-cutting, no single parent issue): `feature/description`
- Fix: `fix/description`
- Release: `release/<slug>` (slug-primary / pre-claim — the milestone/theme slug, no version stem; the version binds only at the Stage-12 claim, never in the branch name; ADR-092)
- Branch names: lowercase, hyphenated, descriptive
- **Deprecated:** `feature/imp-XXX-description` — legacy from IMPROVEMENTS.md bridge era. Use `feature/#N-description` with the GitHub issue number.
- **Note:** Branch naming is for readability and traceability only. It does NOT create a GitHub Development sidebar link. The `closes #N` keyword in the PR body is the mechanism that links PRs to issues.

## Commit Messages
- Format: `<slug>: Description of change` (or `release(<slug>): …`) for release commits — slug-primary / pre-claim (the release branch carries no version stem; the version binds at the Stage-12 claim, ADR-092)
- Format: `fix: Description` or `feat: Description` for non-release commits
- Include issue reference when applicable: `feat: Description (#N)`
- **Deprecated:** `IMP-XXX` references in commit messages. Use `#N` (GitHub issue number).
- Never use --no-verify. Respect pre-commit hooks.

## Primary Checkout Discipline

The primary checkout at `${HOME}/Claude/` is READ-ONLY for Claude Code sessions. It is the user's Finder-visible view of the latest merged main; the user depends on it showing current-state, merged content.

### Rules
- Never `cd` into `${HOME}/Claude/` from a Claude Code session
- Never run `git checkout`, `git commit`, `git pull`, `git merge`, or other state-changing git operations in the primary
- All work happens inside a worktree at `${HOME}/Claude/.claude/worktrees/[name]/`
- To sync latest main into your worktree: `git fetch origin main && git merge origin/main` (within the worktree — no cd to primary)
- To READ files under `${HOME}/Claude/` for context: absolute paths are fine for Read/Grep; do NOT `cd` there
- **A spawned spoke has NO primary access.** A spoke launched via the Agent tool (Stage 6 / 12 / 13 content-modifying spokes per [`release/references/how-to/hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) § Worktree discipline) operates ONLY in its own worktree — it never `cd`s to, commits in, or otherwise mutates `${HOME}/Claude/pmo-platform` (the primary). The primary is out of a spoke's reach by construction; a spoke that reaches it (as in the 2026-06-20 stray-commit-then-reset incident) is a control-gap defect, not authorized behavior. The spoke prompt's own no-`cd`/never-primary clause is the enforcing surface.
- **Never restore a user's uncommitted change without asking.** An uncommitted deletion (`D <path>`) or modification in the primary is often deliberate in-progress cleanup the user will commit on their own schedule — not an accident. Do not `git restore` or `git checkout -- <path>` it. If a pending change is non-obvious, gather context (`git status`, `git log --oneline -n N -- <path>`) and ask; default to preserving the user's intent (leave a deletion deleted, a modification modified).
- **Diagnose by content before any irreversible discard.** A small working-tree diff on a detached or behind primary is frequently a stale draft a prior session left after the finalized version already merged via another PR. Compare the edit's text against `origin/main` (`git show origin/main:<path>`). If the content already lives on `origin/main` it is a redundant duplicate — not unlanded work and needs no PR; the clean fix is to drop it, but get explicit confirmation for the discard first. Never frame discarding a confirmed-redundant draft as "losing work" — state plainly that the content already exists on main.

### Worktree post-merge cleanup (critical)
After `gh pr merge` from within a worktree, DO NOT run `git checkout main && git pull` in the worktree — that claims main for the worktree and **blocks the primary** from checking out main. Use one of:
- `git checkout --detach` — detaches the worktree's HEAD, releasing main
- `git worktree remove $(pwd)` (from outside the worktree) — removes the worktree entirely
- Create a throwaway branch: `git checkout -b claude/post-merge-cleanup-$(date +%s)` — any branch name other than main

**Harness-spawned worktrees are not `EnterWorktree` sessions.** A worktree created by the spawned-session harness (under `.claude/worktrees/<name>/`) is not entered via the `EnterWorktree` tool, so `ExitWorktree` is a no-op against it — re-anchor manually (detach the HEAD or create a throwaway branch as above; prefer the `git branch -d` safety-belt over `-D` so an unmerged branch is not silently dropped). Do not depend on `ExitWorktree` to release main.

**Sweep-deletion safety (removing other sessions' worktrees).** When sweeping merged-no-active-work worktrees, sessions self-reap mid-task — a worktree present at scan time may be gone moments later. So: (a) re-pull / re-list the worktree set immediately before deleting each target, never act on a stale scan; (b) gate any force-removal on a clean dirty-check; (c) verify liveness per live process rather than by lock-file presence — lock files may be ABSENT even for a live session (`lsof -a -d cwd -p <pid>` for each live session PID is the load-bearing check; an absent lock file is not evidence the worktree is free). The automated `cleanup-orphan-state.sh` path (§ PR Process step 10) implements all three; hand-rolled sweeps must honor the same three.

### Post-merge primary sync
The primary checkout MUST always sit at `origin/main` — this is a standing invariant, not a courtesy. An unsynced primary (detached HEAD, behind, or dirty) actively breaks the user's local repo workflows; treat it as a defect to fix, not a state to work around. The invariant holds regardless of who merged the PR.

**Fast-forward by default.** After `gh pr merge` (and whenever the primary is found behind), sync it without asking, using `git -C ${HOME}/Claude` commands (no cd required):
```bash
git -C ${HOME}/Claude fetch origin main
git -C ${HOME}/Claude merge --ff-only origin/main   # fast-forward preserves working-tree state byte-for-byte
```
Then report briefly: "Primary synced to `<sha>`".

**Do not gate the sync on the presence of uncommitted state, and do not default to telling the user to run it themselves.** A fast-forward only touches paths that upstream changed; unstaged edits, deletions, and untracked files on *other* paths are preserved unchanged. The sync is the default; hedging is the error. Asking "what would you like to do about the primary?" when the only pending state is unrelated to the upstream changes is a hedge, not diligence.

**Stop and surface only on a real conflict** — verify path overlap before hedging, never on conditions that merely *look* like they could conflict:
- Fast-forward fails because local commits diverged → report and ask; do not force.
- An upstream change overlaps an uncommitted change on the **same** path → report the specific path; do not stash or discard (see the deletions rule under §Primary Checkout Discipline).
- An untracked file would be clobbered (git surfaces this explicitly) → report the specific files.

### Exception handling
If a preflight operation (e.g., "folder expected on main doesn't exist in my worktree") requires checking main state:
- Use `git -C ${HOME}/Claude fetch origin main` (fetches without cd, without touching branches)
- OR `git fetch origin main` within your worktree, then `git merge origin/main`
- OR read files via absolute path; no git state-change needed

## Worktree Scope — Domain Boundary

Worktrees are for **platform-engineering work** — changes that become a tracked-repo commit/PR (skill definitions, governance, references, hooks, deploy/CI, schemas). They are **not** for **operations-domain work** — the Layer-2, git-ignored operations tree (project artifacts, transcripts, communications drafts, tracker/status updates, project-processing runs). Operations-domain work runs in the operations domain **directly**, not from a platform worktree.

**Why.** A worktree adds branch/path overhead — branch confusion, path-relative file ops, stale context against the operations workspace — that buys nothing when the work never touches platform code. Isolating operations artifacts inside (or framing them against) a platform branch misfiles them.

**How to apply.**
- If a session opens in a worktree but the first task is operations-domain work, say so immediately and offer to exit the worktree (`ExitWorktree`) before proceeding.
- Default for operations-domain work: operate in the operations domain directly (never a worktree).
- A worktree is correct only when the task produces a platform-repo change (code, skills, governance, references, hooks, CI).
- If unsure, confirm before continuing — better to check than to run a whole operations task from the wrong working directory.

This is the worktree projection of the Layer-1 (Engineering) / Layer-2 (Operations) boundary in [operations-bridge.md](operations-bridge.md); §Primary Checkout Discipline above governs worktree *mechanics*, this section governs *which domain's work belongs in a worktree at all*.

## PR Process
1. Create feature branch from main
2. Make changes, commit with descriptive messages
3. Push branch: `git push -u origin [branch]`
4. Create PR: `gh pr create --title "..." --body "..." --milestone "<slug>" --label "label1,label2" --assignee "@me" --reviewer "OPERATOR" --project "PMO Pipeline"` (milestones are slug-named)
   - **Single-collaborator deployment — reviewer field expected empty:** GitHub silently no-ops a self-review request (`gh pr edit --add-reviewer <self>` or `--reviewer <self>`) when the PR author is the requested reviewer; the field simply stays empty. Do NOT treat an empty reviewer on a release PR as a pre-merge gap or Stage 12 blocker. The operator's Stage 9 GO decision IS the review-discipline artifact; the reviewer field is a routing convenience, not the discipline itself. Revisit only if the repository gains a second collaborator.
5. PR body MUST include `closes #N` for each issue the PR resolves
   - Multi-issue PRs: `closes #N, closes #M` (one keyword per issue)
   - Use `closes` as the standard keyword (not `fixes` or `resolves`) for consistency
   - This creates the GitHub Development sidebar link and auto-closes issues on merge
   - **PRs that do NOT fully resolve an issue (partial work, framing PRs, multi-release initiatives):** never omit-and-hope and never negate. Use `References #N` or `Related to #N` in the Issue References block — never a close-family verb anywhere near the reference. Those issues require manual closure at Stage 13.
   - **Parser-clean PR body discipline:** Close-family verbs (`close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`) followed by `#N` may appear in exactly ONE place in the PR body — the dedicated **Issue References** block at the bottom (per `.github/PULL_REQUEST_TEMPLATE.md`). Anywhere else (Summary, Implementation table cells, Deviation Log, Verification Evidence, test-plan checklists, sub-task enumerations) MUST use safe phrasing. GitHub's auto-close parser is lexical, not semantic: negation tokens do not disable it, and section context does not constrain it.
     - **Negation trap:** Never write `does not close #N`, `not closing #N`, `won't close #N`, or any negated form — the parser matches `close #N` regardless of preceding negation. Reframe positively with `References #N`, or "Issue #N stays open through the multi-release initiative."
     - **Verb-noun leak:** In checklist enumerations and sub-task descriptions, never write `close #N` even as part of a longer action phrase. Use `mark #N as closed`, `transition #N to closed`, `#N → Closed`, or `Issue #N closes at Stage 13`.
     - **Pre-submit spot-check:**
       ```bash
       grep -inE "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) +#?\[?[0-9]" pr-body-draft.md
       ```
       Any match outside the dedicated Issue References block needs scrutiny.
6. User reviews PR diff on GitHub (the diff IS the dry-run review)
7. User merges (or tells Claude Code to merge via `gh pr merge`)
8. Pull merged changes: `git checkout main && git pull origin main`
   - **Context check:** If operating in a worktree (cwd under `.claude/worktrees/*`), DO NOT run this step as written — it would claim main for your worktree and block the primary. Instead: `git checkout --detach` OR `git worktree remove` to release main. See §Primary Checkout Discipline.
9. Tag if release (signed-annotated; signing per `tag.gpgsign=true` repo policy — never bypass): `git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" vX.Y "$MERGE_SHA" && git push origin vX.Y`
   - **Release claim path:** for a *release* tag the version is claimed atomically at the merge SHA by [`release/tools/claim-version.sh`](../../release/tools/claim-version.sh) — the repo-host adapter's `atomic_claim()` (compute next-free + ref-CAS push per [`stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md) Phase B3), never hand-typed. This generic `git tag -a` form is the non-release / manual case.
10. Clean up branch: `git branch -d [branch]`
   - **Automated path (recommended):** Run [`./release/tools/cleanup-orphan-state.sh`](../../release/tools/cleanup-orphan-state.sh) `--spawn-task` (workspace-wide `claude/*` and `agent-*` sweep) or `--release-close <milestone-slug>` (the release branch — both `release/<slug>` and the version-prefixed `release/vX.Y-<slug>` form — **and the sibling Stage 12/13 corpus branches: `chore/<slug>-*`, `chore/vX.Y-<slug>-*`, and the version-prefixed `chore/vX.Y-stage-*` chore branches** (`chore/vX.Y-stage-12-release-log`, `chore/vX.Y-stage-13-corpus-update`) whose `vX.Y` is derived from the milestone slug's leading version token, anchored on the literal `-stage-` so `vX.Y` never over-matches `vX.YY`) to sweep merged-no-active-work branches across local + remote + worktrees in one invocation. Default mode is `--dry-run` (preview only); add `--apply` to execute removal. In `--apply`, the script runs four phases in order: (1) remove each REMOVE-action branch/worktree; (2) **resolve** — one bounded re-evaluation pass that removes local branches freed by this run's worktree removals, so a single `--apply` reaches fixed-point (no orphan branches left for a second run); (3) **verify** — re-check that each removed target (including resolve-pass removals) is actually gone, reclassifying any survivor to `SKIPPED — survived apply` so the report never silently claims a removal that did not hold; (4) **prune** — drop stale remote-tracking refs (`<remote>/<branch>`) whose server-side branch was already deleted (the usual case being auto-delete on PR merge) via `git remote prune`, so the report's remote view matches reality. `--force` (allows `git branch -D` + `git worktree remove --force`) requires both `--apply` AND `--force` — double opt-in. Two protective classifications are never removed and are not overridden by `--force`: the script's own runtime worktree (`SELF` action class) and any worktree held by a live process (`SKIP — live session (pid …)`, via a fail-closed process-liveness check). Removal mechanism is git porcelain only (`git branch -d`/`-D`, `gh api -X DELETE git/refs/heads/*`, `git worktree remove`, `git remote prune`) — zero `rm`/`rmdir`/`unlink` usage. Stage 13 spoke invokes this script automatically per [`release-process.md` § Stage 13 Orphan state cleanup](../../release/governance/release-process.md).
   - **Manual path (fallback, single branch):** `git branch -d [branch]` deletes a single local branch; `gh api -X DELETE repos/[OPERATOR_GITHUB]/pmo-platform/git/refs/heads/[branch]` deletes the remote ref. Use the manual path for one-off interactive cleanup; use the automated path for sweep-class operations.
   - In a worktree: delete the branch only AFTER step 8's detach/remove — `git branch -d [branch]` fails if the branch is currently checked out.

### PR Title Convention

A PR title must stand on its own: a reader should see the change **class**, the **milestone**, the **work item**, and a **description** without opening the PR. Titles follow one grammar:

```
type(scope): summary  (#N[, #M])
```

| Element | Rule | Lets a reader decode |
|---|---|---|
| `type` | REQUIRED. One of the closed set `release` · `feat` · `fix` · `chore` · `docs` · `refactor` · `ci` · `test` · `revert`. Same vocabulary as the `feat:` / `fix:` prefixes in §Commit Messages above. | the change class (the "chore / fix / feat" question) |
| `scope` | REQUIRED for release-pipeline PRs — the milestone/release identifier: the **slug pre-claim** for the release PR (e.g. `release-identity-and-plan-naming`), or the version once it is claimed for a post-claim Stage-13 chore PR (e.g. `v1.06`). Otherwise a short component slug (`ci`, `release-notes`, a skill name). Omit only for a genuinely repo-wide change, leaving `type: summary`. | the milestone / area |
| `summary` | REQUIRED. Concise and imperative. | the description |
| `(#N)` | OPTIONAL. Trailing issue/PR reference(s), **reference-only**. | the work item |

Worked examples, one per type:

- `release(release-identity-and-plan-naming): Solutioning protocols — finding-disposition framework` (release PR — slug-primary / pre-claim)
- `chore(v1.06): Stage 13 close-out — INDEX + DIGEST + NOTES (#N)` (post-claim close-out chore — version bound)
- `feat(git-workflow): add a governed PR-title convention + CI gate (#N)`
- `fix(ci): reference-durability always-run so the required check reports`
- `docs(release-notes): correct the v1.05 deployment date`
- `refactor(deploy): modularize the deploy.sh checks`
- `test(eval): add intake-desk trigger cases`
- `ci(repo-integrity): widen the depersonalization scope`
- `revert: feat(git-workflow) PR-title gate`

**Title `#N` is reference-only.** GitHub's auto-close parser scans the title as well as the body, so a `#N` in a title must never follow a close-family verb (`close` / `closes` / `fix` / `fixes` / `resolve` / `resolves`, and their tenses) — that would auto-close the issue straight from the title. Close-family verbs + `#N` stay confined to the body's dedicated Issue References block, exactly as the Parser-clean PR body discipline above requires; the title carries only the bare `(#N)` form.

**Enforcement.** The CI workflow `pr-title-convention.yml` validates the title on PR open/edit, mirroring the `pr-body-parser-clean.yml` body gate. It ships **warn-mode initial** — a non-conforming title is reported in the run summary but does not block the merge — giving the legacy bare `vX.Y: …` release shorthand a transition window; the canonical release-PR form is `release(<slug>): …` (slug-primary / pre-claim). Auto-generated titles (`Revert …`, `Merge …`) and bot authors are exempt. A title that legitimately cannot conform declares an override by adding `<!-- pr-title-convention: allow -->` anywhere in the PR body.

## Reference Durability

Durable-corpus files — governance rules, standards, specs, disciplines, schemas, skill SKILL.md files, and committed release-plan files — must survive the events the platform performs: repository migration, milestone re-bundling and renumbering, and history rewrites. When authoring durable-corpus content, state every rule unconditionally and inline, summarize referenced content rather than linking to it, and confine any unavoidable bare issue reference to a designated reference block with an inline summary so the meaning survives even if the number rots. This is the same shape as the parser-clean discipline above: an authoring discipline enforced at commit and PR time. The full ladder of reference forms, the self-containment test, and the override-marker and allowlist mechanism live in the reference-durability standard under the core standards set.

A PreToolUse hook on Write and Edit to durable-corpus paths, the reference-durability deploy-check check, and a paths-filtered CI workflow enforce this. The hook and check ship warn-mode-initial via the shared harness mode file; the CI workflow scans added lines only, so pre-existing corpus does not fail an unrelated PR. The detector flags four things: markdown link sequences; version-cutover apparatus (the prose that says a rule applies to releases after a given version, or that a given version is itself exempt); a bare issue reference placed outside a reference block or left content-free inside one; and a raw GitHub issue, pull-request, or milestone URL (the `github.com/owner/repo/issues/N` form and its `pull` and `milestone` siblings — a rung-6 reference that rots on any repository move). A file that legitimately needs a flagged construct declares a per-file override marker, an HTML comment naming the allowed class, once in the file — `allow-link`, `allow-version-ref`, or `allow-url`. The ref-permitted ledger surfaces (the five named in the universal-vs-release-pipeline split rule) are categorically exempt from the raw-URL class, so a ledger URL there needs no marker; and the raw-URL class ships warn-mode-initial, reported but not blocking until flip-to-enforce.

## Repository-Integrity Gates

<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
The PR-time gates in workflow `repo-integrity.yml` that are **registered as required checks in branch protection** block a merge to `main` when a changed file introduces an integrity violation; the workflow itself is the enumerating authority for both sets, and branch protection is the authority for which of them block. The blocking set is the three tabulated below. Each gate scans only files changed in the PR (pre-existing content is not re-flagged), and each gate has its OWN scope — they do not share one allowlist. Gates that run and report without blocking are listed under § Non-blocking integrity jobs.

| Gate | Scope (which changed files it checks) | Blocks when an in-scope file contains… | Override marker |
|---|---|---|---|
| Depersonalization | Source under `core/`, `release/`, `operations/`, `packages/` ONLY — the domains where personal data is forbidden. Project-meta files (`README.md`, `SECURITY.md`, `LICENSE`, `CONTRIBUTING.md`) and `.github/*` are out of scope: maintainer identity belongs there. | The operator's identifying values (handle resolved from the run actor; name/email from a configured identity input), or a known collaborator's full name. Personal data is handled per the secrets policy as Personal data (C6): kept outside the workspace or encrypted-at-rest, never inline in a tracked `core/`/`release/`/`operations/`/`packages/` file. One field-scoped exception: the operator's literal name on a frontmatter `deciders:` line inside an ADR (see the carve-out note below). | `<!-- repo-integrity: allow-depersonalization -->` |
| Issue-reference validity | Every changed markdown file (except this file and the PR template, which quote worked examples). | An issue reference (`#N`, or the deprecated `IMP-NNN`) that does not resolve to a real issue IN THIS REPO (checked by direct API resolution — a 404, a redirect to another repo, or a pull-request number all fail), OR a resolving reference placed outside a designated reference block (`### Issue References` / `### References` / `## Related` / `## Provenance` / `### Source(s)`). | `<!-- repo-integrity: allow-issue-ref -->` |
| Dead file reference | Documentation corpus broadly — `core/`, `release/`, `docs/`, `.github/`, and top-level files — because user-facing link integrity (including README and docs) matters everywhere. | A markdown `[text](path)` link or `![alt](path)` image whose target file is missing, or whose `#anchor` names a heading that does not exist in the target (anchors resolved by GitHub's heading-slug rules, including duplicate-heading `-1`/`-2` suffixes). | `<!-- repo-integrity: allow-dead-file-ref -->` |

Each failing run prints, in the run summary, the line-numbered matches, a link back to this section, and the override syntax — the failure teaches the rule.

**Validity vs. durability.** These gates check that a reference *resolves today, in this repo,* and *sits in a reference block*. A separate, complementary reference-durability discipline (the subsection above) governs whether a document still reads correctly after issues are renumbered or the repo is migrated — it asks you to lead with self-describing prose and demote a bare reference to a provenance footnote. The two are designed not to overlap: this gate says "make it resolve / move it into a reference block"; the durability discipline says "make the surrounding sentence stand on its own."

**CI configuration (one-time).** The depersonalization gate resolves the operator's own handle from the run's actor (no secret needed for the handle), and reads the operator's name/email and a collaborator-name list from repository secrets. When the PR is authored by a bot, operator-self matching is skipped (a bot push must not blind the scan). On the canonical repository, an unset identity or collaborator secret is a hard failure — a personal-data control that silently scans nothing is indistinguishable from a passing one (the same fail-loud posture the secret-scanning workflow uses). A fork opts out explicitly via a repository variable or a committed sentinel; the opt-out is announced in the run summary. Anchor checking in the dead-file-reference gate ships warn-mode initially (calibration), so a missing anchor is reported but does not fail the run until the calibration period closes.

**ADR `deciders:` carve-out.** The operator's literal name — and only the name — is permitted on a frontmatter `deciders:` line inside an ADR (`core/ADRs/**`, `release/ADRs/**`) — architect-of-record attribution on an owned repo. The exemption is name-scoped: it fires only when the changed file is an ADR **and** the added line matches `^deciders:` **and** the line carries no un-carved literal. It does not loosen the operator email, home/workspace paths, the GitHub handle **on any line, `deciders:` included**, ADR body lines, non-ADR files, or the collaborator dimension — all of those stay blocked. The handle is the un-carved literal the gate re-tests for, which is why this gate and the ADR durability lint's handle rule below agree on the same `deciders:` line. Exempted lines are reported in the run summary (via the same suppression channel as the line-scoped override), so the exemption is auditable, not silent. See [`core/standards/depersonalization-spec.md`](../standards/depersonalization-spec.md) §1.2, which owns the rule and records the enforcement residual on the email and collaborator dimensions.

**Non-blocking integrity jobs.** The same workflow carries additional jobs that report without blocking, so a new invariant can be calibrated against real traffic before it gates a merge. The **SIGPIPE-idiom** job is one of them, and it is non-blocking for a different reason than the rest: it is **enforcing** — it carries no warn-mode and exits non-zero on a finding — but a new job in this workflow is not automatically a required check, so until its context is registered in branch protection it turns red without stopping a merge. It scans added lines in changed `*.sh`/`*.bash` (whole-file when the file's git status is added or renamed, which closes the rename blind spot) for a writer piped into a short-circuiting reader — `any-writer | grep -q`, or `grep | head` — because under `pipefail` the reader exits on its first match, the writer's next write fails on the broken pipe, and its non-zero status becomes the pipeline's, so a *successful* match reports failure and an `if !` predicate silently inverts. That status is **141 only where SIGPIPE is fatal**; where the shell inherited the signal as `SIG_IGN` — which is what a GitHub-hosted runner hands a workflow step — the writer returns **1** instead, indistinguishable from the reader legitimately finding nothing. Diagnose this class by a non-zero status on a short-circuiting pipeline, never by hunting for 141. Exemptions use the same three tiers as the gates above: the idiom inside a single-quoted payload is content-exempt automatically; a deliberate retention declares `# sigpipe-idiom: allow — <reason>` on the line or the line above and is reported in the run summary's SUPPRESSED block; `# repo-integrity: allow-sigpipe-idiom` skips a whole file. Two more apply to ADR files. The **ADR-number integrity** job asserts the one global, gap-free `ADR-NNN` sequence across both ADR directories and blocks on a duplicate or a gap — it is whole-tree, because numbering is a global invariant. The **ADR durability** job is its lifecycle sibling: it lints ADR files changed in the PR, on added lines only, for the durability rules its own module docstring enumerates — a `status:` value whose leading token falls outside the four-token Nygard enum; a hardcoded commit SHA or a live corpus-population count baked into durable prose; the operator's literal GitHub handle; and a bare issue reference in an identity frontmatter field (`title:` / `release:` / `deciders:`), whose only remedy is to name the value directly and move the reference to `source_observations:` or to a designated `## References` block. The handle rule is deliberately stricter than the `deciders:` carve-out above: that carve-out sanctions the literal *name* on a `deciders:` line, never the *handle*, and this lint closes the gap a line-scoped skip would otherwise leave open. Fenced code blocks, the `source_observations:` frontmatter block, explicitly history-anchored lines, and frozen `Superseded`/`Deprecated` records are exempt from the stale-anchor rule by construction; a file that genuinely needs a pinned anchor declares `<!-- adr-durability: allow-anchor -->`, and `<!-- repo-integrity: allow-adr-durability -->` skips the file entirely. Both the operator handle and the repository it is derived from are resolved at run time, never written into the checker.

The ADR durability lint ships **warn-mode**, and its flip to enforce is **deliberately deferred**: it locks a clean baseline rather than creating one, so enabling it before the ADR corpus has had its full structural-conformance pass would turn CI red on pre-existing content. The flip becomes eligible only once that conformance pass has landed a clean baseline, and then only after the standard warn-log shakedown described in the bypass-mode readiness reference.

## Tag Retention

Version tags are permanent. A tag matching `refs/tags/v*` cannot be deleted or force-updated on the remote: the repository host enforces an active tag ruleset — named `protect-version-tags` on the canonical repository — carrying a `deletion` rule and a `non_fast_forward` rule, with no bypass actors declared. No account can override it, the repository owner included. The only way to remove a version tag is to first amend or disable that ruleset; that is an operator decision taken outside any release procedure, never a step inside one.

**This is a tag rule, not a ref rule.** Branches are swept routinely — § PR Process step 10 deletes merged branches by design, locally and on the remote. The asymmetry is deliberate. A branch is working state and is expected to disappear once it merges. A version tag is the atomically claimed record that a version resolved to a commit — the thing a release note, a deployment-log row, a downstream consumer, and the version-claim compare-and-swap all resolve against. Deleting one breaks whatever resolved it and erases the claim record itself.

**What this means for procedures.**

- No procedure may prescribe deleting a version tag on the remote. Neither `git push --delete origin <tag>` nor the `git push origin :<tag>` refspec form can succeed against a protected tag — a step naming either is a step that cannot run.
- A **local** tag delete (`git tag -d <tag>`) is unaffected; the ruleset governs the remote only. Dropping a local tag after a lost version claim stays correct.
- An orphan or superseded version tag is **retained and recorded**, not reaped. Record it in the re-version ledger and move on; an extra tag is one ref pointing at a commit that stays reachable through its canonical tag.
- Rollback does not delete the release tag. Revert the merge and record the rollback; the tag remains as the record that the version was claimed and then withdrawn.

**Rule versus enforcement — one authority, one discriminator.** The rule above is platform doctrine; the ruleset is this deployment's mechanical enforcement of it. On a deployment that has not configured tag protection the rule still governs, and the recovery tooling still carries a reap path for that case behind an explicit double opt-in — because the platform cannot assert what a differently-configured host permits, and tooling that refused unconditionally would bake one deployment's host configuration into a portable tool. The discriminator is the host, and the tooling reads it rather than assuming it: **where tag protection is configured the reap path is unreachable and the tooling reports the tag retained; where it is provably not configured, reaping is an operator-gated exception to this rule, never the default; where host policy cannot be read, nothing is attempted.** A reader who finds tooling and this rule apparently disagreeing resolves it here — the tool reads the host, this rule states the intent.

**Verifying the control.** This is host configuration, not corpus text — searching this repository will not find it. Read it live:

```bash
gh api repos/:owner/:repo/rulesets --jq '.[] | select(.target == "tag")'
```

An empty result means this deployment carries no mechanical enforcement, not that the rule does not apply.

## Session Start Checklist
Every Claude Code session begins with:
1. **Identify context.** Confirm `pwd` — if inside a worktree (`.claude/worktrees/*`), you're in the right place. If at `${HOME}/Claude/` directly or any other path, STOP — see §Primary Checkout Discipline before proceeding. All subsequent steps assume worktree context.
2. Verify clean working tree: `git status`
3. Check for Layer 2 file leakage: `git status` should show NO projects/ files
4. Check for Cowork modifications to Layer 1 files: `git diff` (if diff shows changes, resolve per operations-bridge.md)
5. Sync latest main into worktree: `git fetch origin main && git merge origin/main` — NOT `git checkout main && git pull` (that would claim main for the worktree; see §Primary Checkout Discipline)
6. Read CLAUDE.md for current workspace rules
7. Check projects/_config/SESSION_STATE.md for continuity context

## What NOT To Do
- Never force push: `git push --force` is denied in settings.json
- Never commit directly to main — always use a branch + PR
- Never `git add .` or `git add -A` — stage files explicitly
- Never commit Layer 2/3 files (they're gitignored, but verify with `git status`)
- Never `cd ${HOME}/Claude/` from a Claude Code session (Primary is read-only; see §Primary Checkout Discipline)
- Never run `git checkout main && git pull` inside a worktree (claims main, blocks primary; use `git fetch origin main && git merge origin/main` instead)
- Never use `gh issue list --limit N` (or any batch CLI command with a result-cap parameter) without verifying N ≥ total dataset size. Silent truncation produces misclassified state — see § Batch CLI Query Limits below.
- Never commit draft / scratch / proposal / working-notes content as tracked files in the public repo — see § Draft / scratch content below for where it belongs.
- Never delete a version tag on the remote — `refs/tags/v*` is host-protected and the push is rejected for every account, owner included; see § Tag Retention.

## Draft / scratch content — not in the public repo

Draft, scratch, proposal, exploratory, or working-notes content is NOT committed as a tracked file in the public repo. A half-formed idea has two sanctioned homes:

1. **The issue tracker** — the front door for anything heading toward a work item. Capture it with `observation.yml` and promote to `improvement.yml` once it is intake-ready (per [intake-style-guide.md § Sanctioned idea-refinement surface](../../release/references/how-to/intake-style-guide.md)). The `intake-desk` skill is the conversational funnel; it logs a well-formed item, never a scratch file.
2. **The git-ignored runtime tier** — the operator-instance working space (`projects/`, `personal/`, and the rest of the Layer-2 tree per [operations-bridge.md](operations-bridge.md) § Layer Classification) is git-ignored and is the home for operator working notes and pre-ticket exploration.

What this prevents: an agent improvising a `docs/proposals/…md` (or similar) draft into the tracked corpus before the idea is recognized as belonging in the tracker. This rule is enforced at commit/PR time by the draft-file guard (`core/hooks/block-draft-files.sh` + its repo-integrity CI gate); until that guard ships it is advisory-by-documentation.

## Batch CLI Query Limits

The `gh` CLI defaults to result caps that silently truncate when the dataset exceeds the limit. Examples:

- `gh issue list --limit 30` (default)
- `gh issue list --limit 1000` (an explicit ceiling the agent might choose)

A dataset of 839 open issues with `--limit 600` returns 600 results; the missing 239 issues are silently dropped. Misclassifying these as "closed" or "absent" produces downstream errors. (Trigger pattern: 2026-04-24 reorg, where 144 open tickets were misclassified before verification caught the truncation.)

**Rule (before any batch CLI operation):**

1. Compute the dataset size first:
   ```
   gh issue list --state all --json number --jq 'length'
   ```
2. Set `--limit` to ≥ dataset size (or use `--limit 5000` as a safe ceiling for the pmo-platform repo).
3. Verify the returned result count matches the computed dataset size before consuming the output.

**Applies to:** `gh issue list`, `gh pr list`, `gh project item-list`, `gh search`, `gh api` paginated endpoints, and any other batch query that supports `--limit` or paginated truncation. Same rule for any CLI tool with implicit result caps.
