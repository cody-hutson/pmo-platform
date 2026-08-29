<!-- reference-durability: allow-link -->
---
title: "ADR-163 — Post-merge skill deployment is a local git hook in the existing hook home, installed by the existing install function"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-29
release: skill-surface-sync
deciders: "Stage 5 Solutioning spoke (design, divergent generation, evidence-grounding) + hub verification (worktree-hazard and uninstalled-hook re-probe) + Stage 6 Engineering spoke (build, allowlist re-derivation)"
tags: [skill-deployment, git-hook, deploy-automation, drift, core-hooks, setup-workspace, worktree, script-execution-allowlist]
source_observations:
  - "A CI runner structurally cannot reach the deploy target. The install paths are `$DEPLOY_ROOT/.claude/skills` and `$DEPLOY_ROOT/Library/Application Support/Claude/local-agent-mode-sessions`, with `DEPLOY_ROOT` defaulting to `$HOME`. Measured: 0 of 22 workflows invoke `deploy.sh --deploy` or `--all`; sensitivity control 13 of 22 invoke `deploy.sh` in validator form; the single workflow touching install-path tokens pins `cowork_install_path = \"/tmp/ci-cowork\"`, a sandbox. Approach A is falsified, not merely doubted."
  - "A git-hook home already exists and is data-driven. `core/hooks/git-pre-commit-pii.sh` is a git hook living there, and `install_hooks()` iterates `core/hooks/*.sh` with no per-file loop edit, single-sourced across three call sites (fresh bootstrap, re-bootstrap, and the `--refresh-hooks` path `update.sh` delegates to). Creating a second git-hook home would fork the answer to 'where does a git hook live' across two trees."
  - "A worktree shares the primary checkout's hooks directory. Measured: in a linked worktree `--git-dir` resolves to `.git/worktrees/<name>` while `--git-common-dir` resolves to `.git`, and this repo additionally sets `core.hooksPath` EXPLICITLY to the primary checkout's `.git/hooks`. Ungated, a merge performed inside a `release/*` worktree would push UNMERGED release-branch skills into the operator's live install path."
  - "The platform's one existing git hook has never been installed in this checkout. Measured unfiltered: `.git/hooks/` holds 14 entries, all `.sample`, zero active hooks; control arm `.git/refs/heads` holds 120 entries, so the empty read is real. An earlier filtered probe returned only `.` and `..` and read as 'the directory is empty' — the corrected form plus its control is what this observation rests on."
  - "`deploy.sh` already accepts explicit skill names. `cmd_deploy`'s manual branch installs each named skill's `.skill` package via `populate_full_roster_packages`. No new flag is owed, so the file is not modified by this decision — which also removes the last file this work would have shared with a concurrently-sequenced sibling card."
  - "`detect_changed_skills()` is a stateless `last-tag..HEAD` diff, and `deploy.sh` says so in its own words: on a release branch it re-lists every skill whose source changed since the last tag on every run. That is correct for a manual release-time deploy and wrong for a per-merge trigger, where the question is what THIS merge brought in."
  - "No hook entrypoint carries a script-execution-allowlist row. Measured at authoring: 0 of the 22 `core/hooks/*.sh` entrypoints appear among the 281 non-comment allowlist entries; sensitivity arm fires (`deploy.sh` 4, `build-skill-packages.sh` 4, `blast-radius.sh` 8); specificity arm returns 0. The population is hook entrypoints, not the single-file precedent."
---

# ADR-163 — Post-merge skill deployment is a local git hook

## Status

**Proposed.** Authored at Stage 6 for the `skill-surface-sync` release as the first commit of the post-merge-deploy card, against the operator's standing authorization to record this decision. Ratification is the Stage 9 Plan Review gate, recorded in the `status:` field above.

## Context

A skill's git source and its installed copy drift apart whenever a merge lands and nobody runs the deploy. Until this decision the only mechanism keeping them in sync was the operator remembering to run `deploy.sh --deploy` after a merge — a manual step with a documented history of being skipped, and no surface that reports when it was.

Three approaches were on the originating card: a GitHub Action on `push: main`, a local `post-merge` git hook, and a Cowork-side watcher. The card left the selection to design and named it as the work's first acceptance criterion, so the decision is the deliverable, not an implementation detail of one.

Two facts constrain the answer and neither was on the card. The deploy target lives under the operator's `$HOME`, which no hosted runner can reach. And the platform already owns both a git-hook home and a data-driven hook-install loop, so the question is not "what new mechanism do we build" but "does this extend a seam we already have."

## Decision

**Post-merge skill deployment is a local `post-merge` git hook, shipped in the existing hook home and installed by the existing install function.** Four sub-decisions, each of which a future editor could plausibly undo without this record:

1. **Approach B over A, C and D.** A is eliminated on feasibility — a CI runner cannot reach the install path. C (a Cowork-resident watcher) is eliminated on the layer boundary: it is Layer 2, git-ignored and Cowork-owned, and the platform repo has no delivery surface for it. D — a generated fourth candidate that extends the existing SessionStart skew notifier from advisory to self-repairing — survives the hard constraints and loses the trade-off matrix on upstream compatibility: it would silently convert the platform's one advisory SessionStart hook into an actuator, contradicting that hook's own stated contract that it never auto-applies.

2. **Extend `core/hooks/`; do not create `core/deploy/hooks/`.** The hook body ships at `core/hooks/git-post-merge-deploy.sh`, following the naming of the one sibling git hook already in that home. A second git-hook home would be an unregistered duplicate source under the register-or-remove rule. The price is a bounded three-occurrence documentation sweep as the hook count moves; that price is paid.

3. **Derive the changed-skill set from `ORIG_HEAD`, and call the already-supported named-deploy form.** The hook computes its own list and passes it to `deploy.sh --deploy <names>`, so **`deploy.sh` is not modified by this decision.** The diff base falls back `ORIG_HEAD` → `HEAD@{1}` → the no-args form, so the hook degrades to today's behaviour rather than to silence. Three limitations of the named form are handled rather than discovered later: a merge that deletes a skill forces the no-args form (manual mode does not clean deleted skills); names are filtered against on-disk existence (an unresolvable name is fatal to `cmd_deploy`); composition surfaces are out of the deploy's scope by construction and the hook does not claim to refresh them.

4. **Gate on primary-checkout ∧ `main`.** The hook runs only when `--git-dir` equals `--git-common-dir` and `HEAD` is `main`. The first conjunct is the discriminator for "this is the primary checkout, not a linked worktree" — a path-literal comparison is not, because the repo points worktrees at the primary's hooks directory deliberately. Without this gate, a merge inside a release worktree would deploy unmerged skills over the operator's working install.

**No `script-execution-allowlist.txt` row is owed for the hook.** The allowlist governs script execution reached through the agent's Bash tool. This script is executed by **git**, as `.git/hooks/post-merge`; the installer only symlinks it. Its regression test is already matched by the shipped `core/hooks/tests/*.test.sh` patterns. The rule that would demand a row has a false antecedent here, and the corpus agrees uniformly: no hook entrypoint carries a row.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| **A — GitHub Action on `push: main`** | Feasibility ceiling, measured rather than assumed. The deploy targets sit under the operator's `$HOME`; a hosted runner has no route to them. The one workflow that touches install-path tokens writes a `/tmp` sandbox. |
| **C — Cowork-side polling watcher** | Governance conformance. A Cowork-resident watcher is Layer 2 — Cowork-owned and git-ignored — and Layer 1 has no surface that can ship it. |
| **D — SessionStart reconcile (auto-repairing skew notifier)** | Survived the hard constraints; lost the matrix on upstream compatibility. It would invert a shipped advisory posture into an actuator, and it fires on every session start rather than once per merge. **Not discarded — it is the correct owner of the residual**, and its kill-reason is specific to the host proposed, not to the idea. |
| **A second hook home at `core/deploy/hooks/`** | Would avoid the documentation cascade and an inert deployed copy, at the cost of splitting the git-hook answer across two trees. Rejected as an unregistered duplicate source; the cascade is three occurrences and cheap. |

## Consequences

**Positive.** Drift created by a merge the hook observes now closes without operator action. The install seam created here is reusable — the platform's existing pre-commit git hook, which has a documented-but-manual install and is measurably not installed in this checkout, can now be installed by the same function. `update.sh` inherits the repair path for free through the `--refresh-hooks` delegation, so existing operators receive it on their next update with no new step.

**Negative, and stated rather than deferred.** The install function gains one block whose target root differs from its siblings' — they write the workspace hooks directory, this one writes the repo's. The asymmetry is mitigated by resolving through `rev-parse` rather than a path literal, and by an explicit comment, but it is real. The hook also lands an inert copy in the deployed hooks directory, because the install loop is data-driven over `core/hooks/*.sh`; this is the existing condition for the sibling git hook, so the change adds a second instance of a harmless status quo rather than a new one.

**The bounding consequence: the hook is inert until installed, and this ADR does not close that.** It repairs only merges observed by an installed hook — not drift from a merge that predates the install, nor a machine where the operator never re-runs setup or update. Nothing currently reports when the hook is absent. That residual is explicitly out of scope here and is tracked separately; readers should not read this record as claiming the drift class is closed.

**Mode is a spec requirement, not a nicety.** The file ships `100755`. Three independent aggregates — the installed-hooks doctor check, the install-layout validation check, and the source-tree QA check — each iterate a hook set and fail on any member lacking the executable bit, so a `644` file flips all three from pass to fail.

## Reversibility

**CHEAP** (confidence **HIGH**). Three independent layers, any one of which suffices: removing the symlink disables the mechanism instantly with no repository change; reverting the commit restores every file, the change being additive and touching no shared surface; and if the installer aborts mid-run its exit trap replays the recorded rollback operations in reverse, removing the symlink. A partial ship is safe — the script and its test without the install wiring is an inert, uninstalled file. An environment variable opt-out is also provided for a single merge.

## Related ADRs

- **ADR-150** — establishes that the script-execution allowlist governs execution *capability* and widens its arm to direct execution. Consulted here and found not to change the determination: widening altered which spellings of an agent Bash invocation are caught, not whether git's internal hook execution is one.
- **ADR-030** — records an earlier observation of the `core/hooks/` population. Its `source_observations` figure is a dated record and is deliberately not updated by this decision.
