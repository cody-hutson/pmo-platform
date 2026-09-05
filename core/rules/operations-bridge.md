---
title: Operations Bridge — File Interaction Rules
purpose: The file-interaction rules bridging the Engineering (Claude Code) and Operations (Cowork) domains — layer classification, ownership boundaries, and the concurrency rule connecting the two.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
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

Claude Code does NOT WRITE to any Layer 2 file. The two domains are **sibling
directories, not nested**, and the boundary is enforced asymmetrically because the
risks are asymmetric: an Operations session writing into `pmo-platform/` puts content
into a **public git repository** and is blocked unconditionally, while an Engineering
session writing into `projects/` cannot reach the repository at all and is a
layer-ownership signal rather than a disclosure control. Both remain prohibited to the
agent; only the enforcement severity differs.

**The agent is not the only writer, and the distinction is the point.** The
installer and the update path ARE sanctioned Layer-2 seed-writers, under
install-if-missing semantics with operator additions preserved: the skills mirror,
the operator-instance surfaces, and the operations context anchor. Claude Code the
agent is not a sanctioned writer of any of them, and the autonomy-ceiling control
enforces the difference — a `Write` or `Edit` to a context-file basename is
blocked unconditionally, while the installer's own write of the same path is not.
The narrow, accurate invariant is that the package never writes operator
**content**; seeding a managed file the operator then extends is a different act.

## Context-Load Contract

What an operations-rooted session loads, stated rather than left implied:

- The workspace charter resolves by ancestor walk-up from any session root beneath
  the workspace root.
- The operations context anchor at `projects/CLAUDE.md` resolves from `projects/`
  down. It is installer-produced, pointer-only, and agent-unwritable.
- Context files **accumulate**, ancestor-first and nearest-last. The anchor adds
  to the charter; it does not displace it. This is a measured property of the
  runtime, not an assumption — an anchor under a nearest-wins model would have
  been a regression rather than an improvement.
- The anchor names the operational procedure set — the platform governance file,
  the session-state and corrections surfaces, and the active project's context —
  and restates none of it. Any procedure appearing there in full is a shadow SSOT
  and is removed.
- **The anchor's paths resolve relative to the anchor's own location**, never to
  the session's working directory. A session that loads it may be rooted at any
  depth beneath it.

The resolution layer and the instruction layer are separate claims: the runtime
resolves **context files**, and a procedure file is read only because a resolved
context file instructs the agent to read it. The anchor exists to make the second
layer reachable from roots where the first may not carry the charter.

### Which deployed rules an operations session loads

The deployed rules mirror at `<deploy-root>/.claude/rules/` is laid down by
`deploy.sh --deploy`. It carries every mirror member, because the Claude Code
(platform engineering) branch loads the whole directory. An operations session
loads a **subset**, and the subset is defined by a criterion rather than by an
enumeration — an enumeration in a context file drifts from the set the moment a
member is added or reclassified.

> **`conduct`-class:** a rule whose normative subject is the agent's own conduct —
> what it may conclude, decide, or do next. **Operational test:** *could a session
> that cannot write `pmo-platform/`, cannot create a branch, and cannot run a
> deploy still violate this rule?* If yes, it is `conduct`. Everything else is
> `engineering` — a platform-engineering mechanism the operations branch does not
> operate.

The classification is carried as the third field of the single mirror pair-set
declaration in `core/deploy/deploy.sh` (`mirror_pair_set()`), co-located with the
set it annotates rather than held in a parallel list, so it cannot drift from that
set. It is invisible to the mirror-pair-parity extractor by construction, which
splits on the first separator and reads field 1.

The artifact an operations session actually reads is
`<deploy-root>/.claude/rules/_operations-index.md` — generated by the carrier from
the `conduct`-class rows, rewritten in full on every deploy, and therefore derived
rather than maintained. **This file is where the criterion is stated; the index is
where the current members are listed.** Neither the charter nor the operations
anchor restates either one.

## Rules for Claude Code
1. NEVER modify Layer 2 files. They are the Operations domain. The correct response to
   needing one changed is to relaunch the work in the operations workspace, where it is
   in-domain — not to cross-write from a repo checkout.
2. Cross-domain reads are read-only. Never write to `projects/` files. Enforced as a
   mode-gated layer-discipline signal (`BLOCK-AUTONOMY-004`), because the target sits
   outside the repository and no write there can reach git. The converse direction — an
   Operations session writing into `pmo-platform/` — is the one that CAN, and it is an
   unconditional Tier-0 block (`BLOCK-AUTONOMY-002`) that no mode or automation level
   relaxes. See `core/specs/autonomy-tiers.md` § Irreducible Human Tasks items 7 / 7a.
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
`core/disciplines/concurrency-safeguards.md`.

The `platform-health` scheduled tasks (pmo-qa-auditor Mode E — see OPERATIONS.md
§ Platform Health Audit Protocol) are a Claude-Code-authored mode with a scheduled
writer that targets the operator-instance analysis path (a Layer 2 surface, git-ignored);
its output never lands in Layer 1, so it raises no Layer-1-dirty detection signal.
