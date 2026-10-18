---
title: "ADR-220 — The depersonalization gate scans a bot's run on the same literals as a human's"
status: Proposed
date: 2026-10-16
release: dependabot-prs-merge-without-bypass
deciders: "Workspace owner (operator) — selected the mirror-and-delete option and the label-create option on 2026-10-16, from the Stage 5 design, and directed on 2026-10-17 that what the security fix still left open be resolved in this release; design by the Stage 5 Solutioning session (Principal Engineer persona); authored by the Stage 6 Engineering session; the distinct mirror name, the step-scoped binding and the fail-closed reads adopted at Stage 7 from the independent adversarial design review"
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

# ADR-220 — The depersonalization gate scans a bot's run on the same literals as a human's

## Status

**Proposed** — authored at Stage 6 Engineering Commit 0 of the `dependabot-prs-merge-without-bypass` release, from its Stage 5 design. The operator selected the mirror-and-delete option and the label-create option on 2026-10-16.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one, read from the repository's ADR-numbering detector. The detector reported sibling claims on this number and the two above it, all branch-only; per the numbering rule a branch claim is detection only and never binds, so this record takes the slot. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations use the slug token `{{ADR:depersonalization-gate-scans-bot-runs}}`, which carries no number shape and resolves at the claim.

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
2. **The name and email come from `OPERATOR_IDENTITY` on every run.** The value is mirrored into the Dependabot secret store under its own name, `OPERATOR_IDENTITY_DEPENDABOT`, and the scanning step reads the canonical name first and the mirror's name second. The Actions store holds the canonical copy and the Dependabot store holds the mirror, because the runs Dependabot starts can read only that store. The binding sits on the scanning step alone, so no other step of the job — the checkout action, whose pin Dependabot bumps — runs with the value in its environment.
3. **The actor no longer changes the literal set.** The bot exemption is deleted. Whether the actor is a bot now affects only a notice in the run summary, which states that the run was scanned on the same literals as a human run.
4. **The configuration check stays first and keeps its message.** It now also fires on a bot's run whose Dependabot-store mirror is absent, which makes the mirror's absence loud.
5. **On the canonical repository, an empty literal set is a failure** (an error annotation and a non-zero exit). Under decisions 1 and 2 that branch cannot be reached on canonical, so it becomes a guard against a future edit that re-arms the silent pass. On a fork it keeps its notice-and-pass behavior, because a fork may opt a dimension out.
6. **The gate's decisions live in its shared library** as functions with explicit parameters and no caller globals: the configuration check, the handle check, the literal-set resolution and the empty-set verdict, plus the three reads of the change below. The workflow calls them, and the committed fixture suite exercises them as effect. The suite also pins the workflow's call sites, pass arms and failing arms line by line, so an edit that keeps the call text but changes what an arm does fails the suite.
7. **The mirror's distinct name is the sequencing guard.** Workflow code that reads only `OPERATOR_IDENTITY` — the gate before this record, a revert to it, or a re-run of a run it recorded, which keeps that run's code and privileges — never sees a mirror stored as `OPERATOR_IDENTITY_DEPENDABOT`. Such code therefore keeps failing loud on a bot's run instead of meeting a present mirror with the exemption still in place, which would be the silent pass of decision 3's context. Setting the mirror before or after the merge, and withdrawing it before or after a revert, are all safe. The design first carried this as an ordering rule; the adversarial review showed a re-run reaches the old code whatever the order, so the guard moved into the name.
8. **The gate's three reads of the change fail closed.** Listing the changed files, extracting each file's added lines and scanning them can each run without evaluating anything. Each read reports that state as its own verdict, and the gate turns it into a red run, never a pass. The listing turns off git's quoting for high bytes, so such a name is scanned under its real name, and treats a name git still had to quote as unreadable. A file git renders as binary yields no lines: that is expected only for a compiled skill package, whose sources are scanned where they live, and anything else rendered binary — a NUL byte in the content, or a `-diff` entry the pull request adds to `.gitattributes` — fails. Only a path with nothing at it is skipped as deleted; a symlink, whose diff is its target text, is read like any file.

## Alternatives Considered

- **Mirror the secret and change nothing else.** Rejected: the configuration check passes, the exemption empties the literal set, and with the collaborator list unset the gate exits 0 unscanned on every Dependabot run. It meets the letter of "a verdict" and is a silent pass.
- **Handle-only on Dependabot runs.** Skip the configuration check only when the actor is Dependabot, scan the owner handle, and announce the name and email as dark. It needs no out-of-tree step and no second copy of personal data. Rejected because it has no fail-loud arm on bot runs, so a missing configuration becomes structurally unknowable there, and because it leaves the name and email unscanned on any bot run that changes a scanned file. **Correction to the original rationale:** the design said that dark dimension falls on exactly the pull-request class that motivated this record. It does not, today. The only manifests Dependabot can bump inside the scanned domains sit inside a compiled skill package's content set, so the package-freshness gate keeps that class red until a maintainer pushes a rebuild, and that push re-runs this gate on the Actions store over the whole pull request. The real advantage of the selected option is self-sufficiency: a bot's run is scanned without depending on another gate's posture, including for a future manifest outside a package.
- **Scan the handle always, scan the identity when it resolves, and emit an error annotation but continue when it does not.** Rejected: on a required check, an error annotation with a zero exit lets the pull request merge with the name and email unscanned. It is the handle-only option with the dark dimension hidden behind a red-looking annotation, and it breaks the gate's fail-loud posture.
- **Run the gate on `pull_request_target`, which receives Actions secrets.** Rejected on three grounds. The acceptance criterion is written against a Dependabot `pull_request` run. On that trigger the checkout is the base ref, so the gate would scan the wrong content unless it checked out the head, and this job sources a shell library from its checkout with secrets in scope, which is the untrusted-checkout pattern GitHub's own guidance warns against. And one required context would be fed by two trigger paths.
- **Run the scope filter before the configuration check, with no mirror.** A Dependabot pull request that changes no scanned file would pass, and one that does would fail closed until a run holding the canonical identity scanned it. It needs no second copy of personal data and no store coupling, and it never leaves content dark: an unscanned in-scope change fails rather than passes. Not chosen: it stops detecting a misconfigured secret on every out-of-scope pull request, since the configuration check is meant to be independent of content, and it keeps every in-scope bot run dependent on a maintainer push. The independent adversarial review re-opened this option against the corrected premise above; the operator's selection stands, and the review's other remedy, the distinct mirror name of decision 7, removed the sequencing risk that weighed against the mirror.
- **Resolve the handle from the owner on bot runs and from the actor otherwise.** Rejected: the smallest diff, but it keeps two resolutions of one fact inside one job.
- **Scan the owner and, on a human run, the actor as well.** Rejected: it adds a collaborator's own handle only on runs that collaborator triggers, which is the least useful moment to scan it. Collaborators are covered by name through the collaborator list.

## Consequences

- **+** A Dependabot run gets the same scan, and so the same verdict, as a human run on the same content.
- **+** The configuration check keeps a fail-loud arm on bot runs: a missing mirror is loud, not dark.
- **+** The latent silent pass is closed for every bot, not only Dependabot: no actor can empty the literal set on canonical, and an empty set fails.
- **+** The handle is resolved once across the workflow, and the depersonalization gate restores the handle block on an ADR `deciders:` line on bot runs, which the name-only carve-out relies on.
- **+** The gate's decisions are now reachable by the fixture suite, which also executes the scan step's own run block against a fixture repository and grades it by exit status, closing a shadow-source gap: before this, the literal resolution was provable only by a live remote run.
- **+** The order of setting the mirror, merging, reverting and withdrawing the mirror is not load-bearing: no ordering of them pairs the mirror with code that exempts bot runs.
- **+** A changed file the gate cannot read — a quoted name, a binary rendering outside the compiled packages, a failed listing, diff or scan — fails the run.
- **−** The identity now lives in two write-only stores, under two names. Absence of the mirror is loud. A value changed in one store only is silent: bot runs scan the stale value while human runs scan the new one. The same holds for a collaborator list later set in the Actions store only, and its summary notice then misreads as solo-operator mode. The secrets-handling policy carries the two-store update procedure; a deploy-time detector comparing the two stores is an optional follow-up.
- **−** A second copy of C6 personal data exists, in an encrypted store. Exposure is limited to the one step that binds it, the gate's own scan, which runs the gate's shell and git and no dependency or action code.
- **−** A changed file whose name git must quote — one carrying a `"`, a backslash or a control character — fails the gate as unreadable until renamed, in any directory: the listing reads every changed file before the scope filter.
- **−** A compiled skill package passes the gate unread. Its coverage rests on the package being built from sources the gate scans, which the package-freshness gate asserts for rostered packages only.
- **−** Every change to the identity value now costs one out-of-tree operator step per store.
- **−** A collaborator's own GitHub handle is no longer scanned on runs that collaborator triggers. Collaborators remain covered by name.

## Reversibility

CHEAP — revert the change in-tree, and delete the Dependabot-store mirror (`gh secret delete OPERATOR_IDENTITY_DEPENDABOT --app dependabot`) so no unused copy of C6 data stays behind. The order does not matter: the reverted gate reads only `OPERATOR_IDENTITY`, which the Dependabot store does not hold. Once this record is numbered and merged it is never deleted; it is superseded or deprecated instead, because the ADR-number sequence is gap-free.

## Related ADRs

- ADR-116 — the ADR `deciders:` carve-out is name-only; the handle stays blocked on that line. This record restores that handle block on bot runs, where the exemption had emptied the handle.
- ADR-010 — the secrets-handling policy substrate. This record adds the canonical-and-mirror note to its storage matrix and a two-store update procedure to its rotation table.
- ADR-181 — citation binding: this record is cited by its slug token until the claim binds its number.

## References

- #8092 — the card this record resolves: Dependabot security pull requests could not merge without an administrator bypass, partly because the depersonalization gate failed every run Dependabot started.
