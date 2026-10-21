---
title: "ADR-220 — The depersonalization gate settles its scope first, scans every run on the same literals, and fails closed on a change it cannot scan"
status: Accepted — operator-ratified at the dependabot-prs-merge-without-bypass Stage 13 Close ratification beat (Phase A13), 2026-10-18
date: 2026-10-16
release: dependabot-prs-merge-without-bypass
deciders: "Workspace owner (operator) — selected the label-create option on 2026-10-16, directed on 2026-10-17 that what the security fix still left open be resolved in this release, and at the Stage 9 review on 2026-10-18 selected the scope-first design with no Dependabot-store copy over the mirror option first chosen; design by the Stage 5 Solutioning session (Principal Engineer persona); authored by the Stage 6 Engineering session; the distinct mirror name, the step-scoped binding and the fail-closed reads adopted at Stage 7 from the independent adversarial design review"
tags: [depersonalization, repo-integrity, ci-gate, dependabot, secrets, c6-personal-data, fail-loud, handle-resolution, shared-library]
source_observations:
  - "Every Dependabot pull request in the repository's history failed the Depersonalization gate on the bot's own commit (8 of 8), each with the annotation that OPERATOR_IDENTITY is unset on the canonical repository. Five of the eight changed no file in the gate's C6 scope; they failed only because the fail-loud block runs before the scope filter."
  - "On both pull requests where a maintainer later pushed to the bot's branch, the gate passed on the maintainer's commit. Only the triggering actor differed between the failing run and the passing one."
  - "GitHub's Dependabot troubleshooting guidance states that a workflow Dependabot starts receives only Dependabot secrets, never Actions secrets, and that a re-run keeps the original run's privileges. Re-running therefore cannot clear the gate."
  - "When the actor was a bot, the gate emptied both its operator literals and its handle literal. With COLLABORATOR_NAMES unset, which is the live solo-operator state, the pattern set was then empty and the gate exited 0 reporting nothing to match. Of the 1,000 most recent pull-request runs, none came from a bot other than Dependabot, and Dependabot always died at the fail-loud block first, so that silent pass was never exercised."
  - "The ADR durability gate in the same workflow already resolves the operator handle from github.repository_owner, which its own comment calls bot-invariant and fork-correct. Of the 1,000 most recent pull-request runs, 998 had the repository owner as actor, so moving the depersonalization gate to the owner is behavior-neutral for human runs today."
  - "No ADR recorded the original choice of github.actor. The only written reason compared it against git config user.name and the commit author, never against the repository owner."
supersedes: none
---

# ADR-220 — The depersonalization gate settles its scope first, scans every run on the same literals, and fails closed on a change it cannot scan

## Status

**Accepted** — operator-ratified at the `dependabot-prs-merge-without-bypass` Stage 13 Close ratification beat (Phase A13), 2026-10-18, as one record of a decision rendered per record. Authored at Stage 6 Engineering Commit 0 of that release as `Proposed`, from its Stage 5 design. The operator selected the label-create option on 2026-10-16 and, at the Stage 9 review on 2026-10-18, the scope-first design with no Dependabot-store copy, in place of the mirror option first selected. The ratification is recorded in this file's frontmatter `status:` field and is never inferred from a review comment or from milestone closure. The decision this record documents shipped in **v4.77**.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one, read from the repository's ADR-numbering detector. The detector reported sibling claims on this number and the two above it, all branch-only; per the numbering rule a branch claim is detection only and never binds, so this record takes the slot. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations use the slug token `ADR-220`, which carries no number shape and resolves at the claim.

**Numbering provenance — `217 → 220`.** Held **ADR-217** branch-local; renumbered to **ADR-220** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 217. In-release citations that read "ADR-217" denote this record.

## Context

The depersonalization gate (Gate 1 of the repository-integrity workflow) blocks a pull request that adds the operator's identifying values, or a known collaborator's full name, to a file under the C6 governance domains. It matches three literal classes: the operator's GitHub handle, the operator's name and email (one per line, from the `OPERATOR_IDENTITY` secret), and an optional list of collaborator names (`COLLABORATOR_NAMES`).

Its first step is a configuration check. On the canonical repository, an unset `OPERATOR_IDENTITY` fails the job loud, because a personal-data control that scans nothing cannot be told apart from one that passed. That check deliberately runs before the scope filter: it asserts the control is configured, independent of what the pull request changed.

Four forces met on a Dependabot pull request:

- **A run Dependabot starts receives only Dependabot secrets.** Actions secrets are not exposed to it, and a re-run keeps the original run's privileges. The configuration check therefore failed on every such run, whatever the pull request changed, and the pull request could merge only after a maintainer push or an administrator bypass.
- **Behind that block sat a silent pass.** The handle was resolved from the run's actor, and when the actor was a bot the gate emptied the handle and the operator's name and email, on the reasoning that an actor-derived literal would otherwise resolve to the bot. With the collaborator list unset, the pattern set was then empty and the gate exited 0 with nothing matched. Any bot run that got past the configuration check would have passed without scanning anything.
- **The handle had two resolutions in one workflow.** The ADR durability gate resolves the same handle from the repository owner, which does not vary with who triggered the run. The actor resolution varies by construction, and that variation is the defect.
- **Mirroring the secret alone does not fix it.** With the identity secret in the Dependabot store and the actor exemption left in place, the configuration check passes, the literal set empties, and every Dependabot run goes green unscanned. That converts a false red into a silent pass, which is the trade the gate exists to refuse.

## Decision

1. **The handle comes from the repository owner on every run** (`github.repository_owner`, bound through `env:`), never from the actor. This is the resolution the ADR durability gate already uses, so the workflow carries one resolution of one fact.
2. **The name and email come from `OPERATOR_IDENTITY`, in the Actions store only.** There is deliberately no copy in the Dependabot secret store. The binding sits on the scanning step alone, so no other step of the job — the checkout action, whose pin Dependabot bumps — runs with the value in its environment.
3. **The actor no longer changes the literal set.** The bot exemption is deleted. Whether the actor is a bot now affects only a notice in the run summary. Every run that scans, scans on the same literals.
4. **The scope is settled first, and the configuration check follows it.** The gate lists the changed files and applies the C6 scope filter before it reads the identity. A pull request that changes no file in the gate's domains passes there, measured, without reading the identity — so a Dependabot PR outside those domains passes on the bot's own run. A pull request that does change such a file reaches the configuration check. A run Dependabot starts cannot read Actions secrets, so on such a change it fails closed, as a human run with the secret unset does. It stays red until a maintainer's push re-runs the gate with the canonical secret and scans the change.
5. **On the canonical repository, an empty literal set is a failure** (an error annotation and a non-zero exit). Under decisions 1 and 4 that branch cannot be reached on canonical, so it becomes a guard against a future edit that re-arms the silent pass. On a fork it keeps its notice-and-pass behavior, because a fork may opt a dimension out.
6. **The gate's decisions live in its shared library** as functions with explicit parameters and no caller globals: the configuration check, the handle check, the literal-set resolution and the empty-set verdict, plus the three reads of the change below. The workflow calls them, and the committed fixture suite exercises them as effect, executes the scanning step's own run block against a fixture repository, and pins the workflow's call sites, ordering, pass arms and failing arms line by line.
7. **The gate's three reads of the change fail closed.** Listing the changed files, extracting each file's added lines and scanning them can each run without evaluating anything. Each read reports that state as its own verdict, and the gate turns it into a red run, never a pass. The listing turns off git's quoting for high bytes, so such a name is scanned under its real name, and treats a name git still had to quote as unreadable. A file git renders as binary yields no lines: that is expected only for a compiled skill package, whose sources are scanned where they live, and anything else rendered binary — a NUL byte in the content, including one on an added line past the 8000 bytes git inspects, or a `-diff` entry the pull request adds to `.gitattributes` — fails. Only a path with nothing of this repository's content to read is skipped — nothing at it, a real directory that replaced a file (its files are scanned under their own names), or a submodule's checkout — and never a symlink, whose diff is its target text and is read like any file. An added line whose content starts with `++` is extracted like any other. A scan that reports a match but prints no line reads as unreadable, not as a hit or a miss.

## Alternatives Considered

- **Mirror the identity into the Dependabot store, keep the configuration check first.** Selected at Stage 5 and engineered through Stage 8, with the adversarial review's refinement of a distinct mirror name to make the set/merge/revert order irrelevant. Not chosen at the Stage 9 review. It scans a bot's in-scope run without a maintainer push, and keeps the configuration check independent of content. But it adds a second store of C6 personal data and a two-store coupling whose drift is silent. Its coverage gain is also small today: the only manifests Dependabot can bump inside the scanned domains sit inside a compiled skill package's content set, so the package-freshness gate keeps that class red until a maintainer pushes a rebuild anyway, and that push re-runs this gate with the canonical secret.
- **Mirror the secret and change nothing else.** Rejected: the configuration check passes, the exemption empties the literal set, and with the collaborator list unset the gate exits 0 unscanned on every Dependabot run. It meets the letter of "a verdict" and is a silent pass.
- **Handle-only on Dependabot runs.** Skip the configuration check only when the actor is Dependabot, scan the owner handle, and announce the name and email as dark. Rejected: it passes a bot's in-scope change with the name and email unscanned. The selected design fails such a change closed instead.
- **Scan the handle always, scan the identity when it resolves, and emit an error annotation but continue when it does not.** Rejected: on a required check, an error annotation with a zero exit lets the pull request merge with the name and email unscanned.
- **Run the gate on `pull_request_target`, which receives Actions secrets.** Rejected on three grounds. The acceptance criterion is written against a Dependabot `pull_request` run. On that trigger the checkout is the base ref, so the gate would scan the wrong content unless it checked out the head, and this job sources a shell library from its checkout with secrets in scope, which is the untrusted-checkout pattern GitHub's own guidance warns against. And one required context would be fed by two trigger paths.
- **Apply the scope-first order only to runs Dependabot starts.** It would keep early misconfiguration detection on human pull requests that change no scanned file. Not chosen: it branches the gate's order on the actor, the property decision 3 removes from every other decision.
- **Resolve the handle from the owner on bot runs and from the actor otherwise.** Rejected: the smallest diff, but it keeps two resolutions of one fact inside one job.
- **Scan the owner and, on a human run, the actor as well.** Rejected: it adds a collaborator's own handle only on runs that collaborator triggers, which is the least useful moment to scan it. Collaborators are covered by name through the collaborator list.

## Consequences

- **+** A Dependabot pull request that changes no file in the gate's domains passes on the bot's own run, with a measured verdict and no maintainer push.
- **+** No second copy of C6 personal data exists, and there is no cross-store coupling to drift. No ordering of merging and reverting can pair a copy with code that exempts bot runs, because there is no copy.
- **+** The latent silent pass is closed for every bot, not only Dependabot: no actor can empty the literal set on canonical, and an empty set fails.
- **+** The handle is resolved once across the workflow, and the depersonalization gate keeps the handle block on an ADR `deciders:` line on every run, which the name-only carve-out relies on.
- **+** The gate's decisions are reachable by the fixture suite, closing a shadow-source gap: before this, the literal resolution was provable only by a live remote run.
- **+** A changed file the gate cannot read — a quoted name, a binary rendering outside the compiled packages, a failed listing, diff or scan — fails the run.
- **−** A Dependabot pull request that changes a file in the gate's domains stays red until a maintainer pushes to its branch. Today that class is a manifest inside a rostered skill package, which needs that push for its rebuild anyway.
- **−** A misconfigured identity secret, or a re-bound handle, is no longer reported on a pull request that changes no scanned file: both checks follow the scope filter. Each is reported, as a failure, on the next pull request that does.
- **−** A changed file whose name git must quote — one carrying a `"`, a backslash or a control character — fails the gate as unreadable until renamed, in any directory: the listing reads every changed file before the scope filter.
- **−** A compiled skill package passes the gate unread. Its coverage rests on the package being built from sources the gate scans, which the package-freshness gate asserts for rostered packages only.
- **−** A collaborator's own GitHub handle is no longer scanned on runs that collaborator triggers. Collaborators remain covered by name.

## Reversibility

CHEAP — revert the change in-tree; there is no out-of-tree state to withdraw. Once this record is numbered and merged it is never deleted; it is superseded or deprecated instead, because the ADR-number sequence is gap-free.

## Related ADRs

- ADR-116 — the ADR `deciders:` carve-out is name-only; the handle stays blocked on that line. This record keeps that handle block on every run, where the exemption had emptied the handle on bot runs.
- ADR-010 — the secrets-handling policy substrate. This record notes in its storage matrix that the gate's identity lives in the Actions store only, with no Dependabot-store copy.
- ADR-181 — citation binding: this record is cited by its slug token until the claim binds its number.

## References

- #8092 — the card this record resolves: Dependabot security pull requests could not merge without an administrator bypass, partly because the depersonalization gate failed every run Dependabot started.
