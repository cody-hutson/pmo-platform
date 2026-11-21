---
title: Controls — hook-rule
purpose: The 85 controls whose mechanism kind is hook-rule, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — hook-rule

85 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-001 | A Write/Edit whose resolved target is a governance file (workspace charter, OPERATIONS.md, RELEASE_PROTOCOL.md, .claude/settings.json, anything under .claude/hooks/ or .claude/rules/) is refused — Tier-0 floor, independent of mode and automation level | code-enforce | hook | `core/hooks/block-autonomy-ceiling.sh` | — |
| C-002 | A Write/Edit from an operations-workspace cwd into any working tree of the platform repository is refused — Tier-0 floor | code-enforce | hook | `core/hooks/block-autonomy-ceiling.sh` | — |
| C-003 | An action whose required Autonomy Tier exceeds the resolved [automation].automation_level ceiling is refused | code-off | hook | `core/hooks/block-autonomy-ceiling.sh` | — |
| C-004 | A Write/Edit from a platform-repository cwd into the operations workspace (projects/) is refused — layer-discipline signal | code-off | hook | `core/hooks/block-autonomy-ceiling.sh` | — |
| C-005 | Read-tool access to ~/.ssh/* is refused (public .pub keys allowed) | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-006 | Read-tool access to ~/.aws/* credentials is refused | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-007 | Read-tool access to ~/.config/gh/* auth config is refused | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-008 | Read-tool access to .env variants is refused (.env.example/.sample/.template allowed) | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-009 | Read-tool access to SSH private keys outside ~/.ssh is refused | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-010 | Read-tool access to *.pem / *.key / *.p12 / *.pfx / *.keystore is refused | code-enforce | hook | `core/hooks/block-credential-reads.sh` | — |
| C-011 | git push --force / -f is refused (--force-with-lease / --force-if-includes allowed) | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-012 | git reset --hard is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-013 | git clean -f / -fd is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-014 | rm on catastrophic system paths (/, /Users, /Applications, /Library, /System, /bin, /sbin, /usr, /etc, /var) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-015 | rm -rf of the bare home directory is refused (subpaths allowed) | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-016 | rm -rf .git is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-017 | rm -rf Projects/ (legacy uppercase project dir) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-018 | rm -rf projects/ (Layer 2 operations tree) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-019 | rm -rf pmo-platform/ (Layer 1 source tree) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-020 | git update-ref on main / master / HEAD is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-021 | git symbolic-ref HEAD to main / master is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-022 | git push with a plus-refspec (+main / +refs/heads/main) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-023 | git reflog expire / delete is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-024 | git filter-branch is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-025 | git filter-repo is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-026 | Write/Edit to .git/config, .git/hooks/*, .git/info/* is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-027 | Write/Edit whose resolved target is a Layer-1 primary-checkout path is refused (three target-keyed exemptions: repo-rooted worktree, git-ignored analysis subfolder, git-ignored roadmap instance) | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-028 | PATH manipulation in a Bash command (PATH=, export PATH, unset PATH) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-029 | alias / function override of critical tools (grep, jq, bash, sh, printf) is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-030 | Mid-session setting of CLAUDE_HOOK_BYPASS or PMO_SCOPE_GUARD_ROOT is refused (anti-injection) | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-031 | Bash execution of a script not in .claude/script-execution-allowlist.txt via a SHELL interpreter (bash/sh/zsh `<path>`) or via source / . `<file>` is refused | code-enforce | hook | `core/hooks/block-destructive.sh` | — |
| C-032 | Bash execution of a script via a NON-shell interpreter (python/python3/perl/ruby/node `<path>`) not in the script-execution allowlist is reported (rollout phase warn) | code-warn | hook | `core/hooks/block-destructive.sh` | — |
| C-033 | Bash direct execution of a slash-bearing command word (./path/script) not in the script-execution allowlist is reported (rollout phase warn) | code-warn | hook | `core/hooks/block-destructive.sh` | — |
| C-034 | A Write that creates a draft / scratch / proposal / working-notes file as a tracked repo file (path-shape test) is refused | code-off | hook | `core/hooks/block-draft-files.sh` | — |
| C-035 | Bash read of credential dirs (~/.ssh, ~/.aws, ~/.config/gh) is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-036 | Bash read of .env variants / SSH private keys / *.pem / *.key is refused (.env.example allowed) | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-037 | base64 encoding of credential dirs is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-038 | curl -X POST / -d / -F / -T to a non-allowlisted host is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-039 | wget --post-data / --post-file is refused (no allowlist) | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-040 | gh gist create is refused (public-share vector; no allowlist) | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-041 | gh api write to a non-allowlisted or unresolvable API path is refused (own allowlist .claude/egress-allowlist.txt; not verb-anchored) | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-042 | nc / ncat is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-043 | scp to a remote target is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-044 | rsync to a remote target is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-045 | ssh to a non-allowlisted host is refused (.claude/ssh-allowlist.txt) | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-046 | WebFetch to file:// / localhost / 127.0.0.1 is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-047 | WebFetch to a domain not in .claude/webfetch-allowlist.txt is refused | code-warn | hook | `core/hooks/block-egress.sh` | — |
| C-048 | An MCP comment payload to an external seam whose first non-blank line is a date-led log header is refused (register-shaped comment) | code-off | hook | `core/hooks/block-external-seam-shape.sh` | — |
| C-049 | An MCP comment payload carrying agent/automation provenance narration or a run index is refused | code-off | hook | `core/hooks/block-external-seam-shape.sh` | — |
| C-050 | An MCP comment payload that restates a field transition (state-change narration) is refused | code-off | hook | `core/hooks/block-external-seam-shape.sh` | — |
| C-051 | An MCP comment payload above the resolved word budget is reported — PERMANENTLY warn-only on its own per-rule constant | code-off | hook | `core/hooks/block-external-seam-shape.sh` | — |
| C-052 | An in-scope MCP seam write whose content extraction is empty or unparseable is refused (fail-loud detector integrity) | code-off | hook | `core/hooks/block-external-seam-shape.sh` | — |
| C-053 | A Write/Edit to a durable-corpus path that adds a markdown link sequence is refused (reference-durability Class L) | code-off | hook | `core/hooks/block-fragile-refs.sh` | — |
| C-054 | A Write/Edit to a durable-corpus path that adds version-cutover apparatus is refused (Class V) | code-off | hook | `core/hooks/block-fragile-refs.sh` | — |
| C-055 | A Write/Edit to a durable-corpus path that places a bare issue reference outside a designated reference block (positional issue-ref) is refused | code-off | hook | `core/hooks/block-fragile-refs.sh` | — |
| C-056 | A Write/Edit to a durable-corpus path that adds a raw repository-host issue/PR/milestone URL is reported (Class U, warn-mode-initial) | code-off | hook | `core/hooks/block-fragile-refs.sh` | — |
| C-057 | A Bash file-read verb (cat/head/tail/less/more/base64/xxd/od/hexdump/strings) whose resolved target is outside the roots in .claude/fs-boundary-allowlist.txt is refused | code-off | hook | `core/hooks/block-fs-boundary.sh` | — |
| C-058 | A Bash file-write verb (cp/mv/tee/dd) whose resolved source or target is outside the allowed roots is refused | code-off | hook | `core/hooks/block-fs-boundary.sh` | — |
| C-059 | A Bash operand refused by the guard cascade (xargs stdin sentinel, quoted structural construct, $(...)/backtick surface, literal .. traversal / no cwd / no normalizer) is refused | code-off | hook | `core/hooks/block-fs-boundary.sh` | — |
| C-060 | An expansion-bearing operand with no decidable literal prefix is ADMITTED and recorded — advisory, never blocks at any mode | code-off | hook | `core/hooks/block-fs-boundary.sh` | — |
| C-061 | A gh issue/PR/comment text (Bash) that carries an operator-local filesystem path needle is refused (public-surface path leak) | code-warn | hook | `core/hooks/block-gh-path-leak.sh` | — |
| C-062 | An MCP tool whose name matches the write-verb pattern and is not in .claude/mcp-write-allowlist.txt is refused | code-off | hook | `core/hooks/block-mcp-writes.sh` | — |
| C-063 | rm/rmdir/unlink with a resolved path OUTSIDE the workspace root, or unresolvable under strict policy, is refused | code-enforce | hook | `core/hooks/block-rm-prefer-trash.sh` | — |
| C-064 | rm/rmdir/unlink with a resolved path INSIDE the workspace root is refused and redirected to a Trash command | code-enforce | hook | `core/hooks/block-rm-prefer-trash.sh` | — |
| C-065 | trash / osascript Trash-verb with a resolved path outside the workspace root (other than a single auto-memory entry) is refused | code-enforce | hook | `core/hooks/block-rm-prefer-trash.sh` | — |
| C-066 | A tracker filing to an UNMAPPED destination while [trackers.*] are configured is refused (fail-closed routing default) | code-warn | hook | `core/hooks/block-scope-segregation.sh` | — |
| C-067 | A filing to a scope:public destination whose authored content extracted empty/unparseable is refused (fail-closed) | code-warn | hook | `core/hooks/block-scope-segregation.sh` | — |
| C-068 | A filing to a scope:public destination when the shared PII primitive is unavailable is refused (fail-closed) | code-warn | hook | `core/hooks/block-scope-segregation.sh` | — |
| C-069 | Private/PII-marked content (home path / phone / personal email / localized needle) bound for a scope:public destination is refused — always-block, mode-independent | code-enforce | hook | `core/hooks/block-scope-segregation.sh` | — |
| C-070 | A rendered Bash command with a script-execution token followed by a chain metachar (; \| && \|\|) leading into a command verb (curl/wget/nc/ssh/eval/python/node/...) is refused | code-warn | hook | `core/hooks/block-shell-injection.sh` | — |
| C-071 | A rendered Bash command with script execution and command substitution ($(...) or backtick) in argv is refused | code-warn | hook | `core/hooks/block-shell-injection.sh` | — |
| C-072 | A direct Write/Edit to a migrated skill's SKILL.md (or its references) outside an active pmo-skill-editor session is refused | code-off | hook | `core/hooks/block-skill-direct-edit.sh` | — |
| C-073 | A skill-file Write/Edit whose pmo-skill-editor session sentinel is absent, stale, or names a different skill is refused | code-off | hook | `core/hooks/block-skill-direct-edit.sh` | — |
| C-074 | At session launch, a resolved runtime model matching neither default_spoke_model nor chip_model family from platform-config [spoke_runtime] is reported | code-off | hook | `core/hooks/verify-session-config.sh` | 3 pages |
| C-075 | At session launch, a resolved effort other than the immutable directive value max is reported | code-off | hook | `core/hooks/verify-session-config.sh` | 3 pages |
| C-076 | At session launch with no payload .model (clear/compact/resume/recovery), a DEGRADED-verification notice is emitted rather than a silent pass | code-off | hook | `core/hooks/verify-session-config.sh` | 3 pages |
| C-077 | A git commit whose staged content carries a literal home-directory path, phone number, or personal-email pattern is refused (Tier-1 always-block); a hit on the operator-instance needle file is reported or refused per git-pre-commit-pii.mode | code-off | hook | `core/hooks/git-pre-commit-pii.sh` | — |
| C-078 | At a Stop boundary of a sampled, substantive session, a session retro is triggered before the session ends | code-off | hook | `core/hooks/session-retro-trigger.sh` | 3 pages |
| C-079 | A session is notified at launch when the deployed platform version is behind the source (version skew) — advisory, never blocks | code-warn | hook | `core/hooks/notify-version-skew.sh` | 3 pages |
| C-080 | (support) SessionStart cache primer resolving the autonomy-level ceiling for BLOCK-AUTONOMY-003 — asserts nothing itself | not-a-control | hook | `core/hooks/prime-autonomy-ceiling-cache.sh` | — |
| C-081 | (support) allowlist-add.sh — atomic, marker-aware allowlist appender used by the hooks' override paths; not a gate | not-a-control | hook | `core/hooks/allowlist-add.sh` | — |
| C-082 | (support) audit-mcp-usage.sh — after-the-fact scan of session logs for MCP write-tool invocations (BLOCK-MCP-001 coverage check); not a gate | not-a-control | hook | `core/hooks/audit-mcp-usage.sh` | — |
| C-083 | (support) run-fragile-ref-fixtures.sh / run-theme-token-fixtures.sh — fixture self-tests for the reference-durability detectors and the TH-3 theme-token lint; consumed by CI and Check 64 | not-a-control | hook | `core/hooks/run-fragile-ref-fixtures.sh` | — |
| C-084 | (automation) After a merge lands on main, changed skills are redeployed by running deploy.sh --deploy (never --check) | not-a-control | hook | `core/hooks/git-post-merge-deploy.sh` | — |
| C-452 | A git push whose new commits or annotated tags carry a literal home-directory path, phone number, or personal-email pattern (accepted homes excepted), in an added line, a commit or tag object, or a needle-file hit, is refused: the commit-time guard runs over every commit the push would publish, including the commits merge, cherry-pick, revert, rebase, stash and commit-tree make without pre-commit | code-enforce | hook | `core/hooks/git-pre-push-pii.sh` | — |
