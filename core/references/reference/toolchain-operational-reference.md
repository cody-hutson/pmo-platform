---
title: Toolchain Operational Reference
purpose: Factual lookup for non-obvious operational behaviors of the toolchain the platform's cross-cutting work runs on — the GitHub CLI, zsh, GitHub's repository/Projects surfaces, and a known third-party Claude plugin. Each entry is the general mechanic an agent consults mid-task to avoid a silent failure.
type: reference
status: ACTIVE
layer: 1
reversibility: CHEAP / Confidence HIGH
consumers: Any agent performing gh-CLI, git, GitHub-Projects, or workflow-file work (release-pipeline spokes, hub orchestration, repo-maintenance sessions).
---
<!-- reference-durability: allow-link -->

# Toolchain Operational Reference

Technical descriptions of the machinery the platform operates and how it behaves — facts to stand on while working, not goal-oriented procedures (those are how-to guides) and not enforced rules (those are standards). Each section captures a non-obvious behavior that produces a silent failure if unknown: a command that hangs, a shell expansion that eats an argument, a clean-up that leaves residue, a UI that ignores a synthetic action, or a third-party hook that blocks a write. The mechanic is stated generally — it holds on the underlying tool for any operator, independent of any one repository, project, or run.

## gh CLI — background-shell hang and the `--paginate` cursor variable

On macOS, `gh` CLI calls hang for roughly a minute each when run in a **detached or background shell** — anything the harness auto-backgrounds, including a long `for`-loop or a command launched in the background. The credential helper blocks on the OS keychain with no interactive session available to unlock it, so the first call in the loop never returns: the job produces zero output and appears to run indefinitely.

**The tell that it is the keychain stall, not rate-limiting:** a single *foreground* `gh` call returns instantly even while a backgrounded loop is stalled. Rate-limiting would slow the foreground call too; foreground-fast plus background-stalled is the signature of the keychain block.

**How to apply.**
- Never run `gh` inside a loop the harness will auto-background. Prefer one foreground call over many.
- For **bulk reads**, issue a single foreground GraphQL call with multiple aliased nodes (`gh api graphql -f query=...`) rather than one CLI call per item. Build the query string with a text tool such as `awk` rather than a shell loop, so the command stays in the foreground.
- For **more than ~100 items**, paginate with `gh api graphql --paginate`. The cursor variable name is load-bearing: it **must be named exactly `$endCursor`** —
  ```graphql
  query($endCursor: String) {
    ... nodes(first: 100, after: $endCursor) { pageInfo { hasNextPage endCursor } ... }
  }
  ```
  Any other name (for example `$cursor`) makes `--paginate` silently refetch the first page forever with no error, ballooning the output until the process is killed. Rename it to `$endCursor` and a multi-page dataset fetches cleanly in one foreground batch.
- For **bulk writes** (for example `gh issue edit`), run small foreground batches of sequential commands — a handful per shell invocation, no loop keyword — rather than one loop over all targets.
- If a job has already backgrounded and stalled, kill it (`pkill -9 -f "gh "`) and expect any output file it produced to be empty.

The magnitude is observable at scale — a backgrounded multi-item fetch loop can stall for the better part of an hour producing nothing, and a mis-named cursor can grow an output file into the hundreds of megabytes — but the rule does not depend on any particular figure: foreground-and-batch, and name the cursor `$endCursor`.

## zsh `:r` word-modifier eats `$var:path` in `git show`

The Bash tool runs commands under **zsh**, which applies history word-modifiers to a parameter expansion when a `:` immediately follows the variable and the next character is a modifier letter (`r`, `e`, `h`, `t`, `s`, and friends). The construct `git show "$SHA:release/..."` is therefore parsed as `$SHA` with the `:r` ("remove extension") modifier applied, leaving `$SHA`-without-extension followed by the stray `elease/...` — an invalid `ref:path`. `git show` errors, and piped into `grep` it yields a silent empty result: a false "the content is missing" verdict.

**The tell:** the same command succeeds for a path whose first letter is *not* a modifier letter (for example a path starting with `C`) and fails for one that starts with `r`/`e`/`h`/`t`/`s`. That asymmetry means the modifier is firing, not that the content is absent. Double-quoting does **not** prevent it — only the variable-immediately-before-`:` form triggers it.

**How to apply.**
- Use a **literal** ref instead of a variable: `git show <sha>:release/...` is not subject to the modifier.
- Or separate the path from the ref: `git show "$SHA" -- <path>`, or quote the path independently `git show "$SHA":"<path>"`.
- Or check out the ref and read the working tree.
- When a `git show "$var:path"` verification returns zero or empty, re-run it with a **literal `<sha>`** before concluding the content is absent.

## GitHub `refs/pull/*` survive a history rewrite

A `git filter-repo` rewrite plus a force-push of the default branch is **necessary but not sufficient** to scrub a repository's history before making it public. GitHub independently retains `refs/pull/N/head` for every pull request, each pinned to the **pre-rewrite** commits. The rewrite cannot touch those refs (they are GitHub-managed and pull requests cannot be deleted), so the old commit contents remain recoverable.

**Why it is easy to miss:** a normal `git clone` does not fetch pull refs, so the rewritten clone looks clean. Only `git clone --mirror` — or an explicit `git fetch origin 'refs/pull/*'` — reveals them. `git ls-remote --heads --tags` also misses them. On a public repository these refs are anonymously fetchable.

**How to apply.**
- Treat rewrite-and-force-push as insufficient on its own for a private-to-public flip when the repository has any pull-request history.
- The guaranteed-clean path is **delete-and-recreate**: build a clean tree on a single `git checkout --orphan` "initial public release" commit (squashing to a single commit also removes any commit-message residue that resists pattern-based redaction), create a fresh repository, and push only that seed. With no pull requests there are no pull refs.
- **Verify with `git clone --mirror`** (which fetches every ref and object) and confirm zero leaks across all refs before flipping the repository public.

## GitHub Projects v2 — view configuration is UI-only

When configuring **GitHub Projects v2 views through browser automation**, the *views* themselves — layout, group-by, sort, and filter — are not creatable or configurable through the API or the `gh` CLI; they exist only in the web UI. (Project *fields* and field *values* are API-creatable; only the views require the browser.)

**How to apply.**
- **Save with the keyboard (`⌘S`), not a synthetic button click.** A scripted left-click on the "Save view" / "Save to current view" control does not persist the change — GitHub ignores non-trusted (synthetic) click events on that control. The keyboard `⌘S` works reliably; blur the filter input first if focus is in it.
- **Verify the save with a cross-view reload, not a same-URL navigate.** Navigating to the same view URL is a single-page-app soft no-op that re-renders stale client state. To confirm a save persisted, navigate to a *different* view and back. After a real save the URL drops the transient query parameters it carried while dirty — parameters gone means the change was saved.
- **Unsaved-state indicator:** a dot on the "View" control (panel changes) or a discard/save pair in the toolbar (filter changes).
- **Filter syntax:** `field:Value`; multi-value OR is `field:A,B`; quote values containing spaces (`field:"A B"`). Avoid a trailing space — it keeps the view dirty.

## Third-party: the `security-guidance` plugin Write/Edit hook

This documents a **known interaction with a third-party Claude plugin (`security-guidance`), not platform-owned behavior** — it may change with the plugin and is not a guarantee the platform makes. The plugin ships a PreToolUse hook on `Write`/`Edit`/`MultiEdit` (its hook script lives under the plugin's own directory, for example `~/.claude/plugins/.../security-guidance/hooks/`) that blocks in two ways:

- **Path rule — GitHub workflow files.** Any write to a `.github/workflows/*.yml` path is blocked. The rule is path-based, not content-aware: it does not inspect whether the YAML is injection-safe, it blocks on the path alone.
- **Content rule — dangerous-code tokens in any file.** A fixed substring set (shell command-execution calls, dynamic code-eval, dynamic function construction, object deserialization, DOM HTML sinks, OS system calls) trips the hook in any file — including a Markdown document that merely *quotes* one of the tokens. Phrase such documentation *around* the literal tokens to avoid the match.

**Behavior is one-time per (file path + rule) per session.** The hook exits non-zero (exit 2) once, records the key in a per-session state file, and then **allows the identical retry** (exit 0). On a blocked workflow write you get exactly one reminder block; re-issuing the same write succeeds.

**The acknowledge-then-allow retry is the hook's design, not a bypass.** Re-issuing the identical write after the one-time block is the intended path — distinct from fabricating state to dodge a hook, which would be a bypass. For workflow files, also adopt the env-var indirection the hook (and the actionlint CI check) encourage: set the dynamic value in `env:` and reference `$FOO` in `run:`, never an inline `${{ ... }}` template expression inside a `run:` command, so a clean local design passes both the hook and CI.

## Related

- Git and worktree workflow rules: [`../../rules/git-workflow.md`](../../rules/git-workflow.md) — branching, PR process, worktree mechanics, and repository-integrity gates.
- Folder purpose and governance: [`README.md`](README.md).
