---
title: ADR-238 — The deletion guard judges every segment of a command line, keeps no exit that allows on a match, and refuses a deletion or Trash call that does not name all its targets on its line
status: Proposed
date: 2026-11-13
release: deletion-guard-judges-every-segment-and-target
deciders: "Workspace owner (Stage-4 plan gate; Collective Review scope lock; Stage-13 ratification); design chosen at Stage 5 Solutioning against a scored candidate matrix and amended at the scope lock"
tags: [architecture, security, hooks, deletion-guard, segment-walk, reversibility-moderate]
supersedes: ADR-235 in-part (Decision 3)
source_observations:
  - "The deletion guard allowed a whole line when a git command sat at any command start, or when a deletion verb at a command start named no operand, so a deletion, a Trash call or a Finder delete in another segment of the same line went unjudged."
  - "Its rm-family step judged one verb, picked by priority, so a second rm-family verb on the line could go unjudged with no exit firing at all."
  - "A Trash program on the reference host documents operand-less options that empty the Trash, one of them with no confirmation; a Trash call with no operand was matched and given no verdict."
  - "The segment walk reads one line at a time, so the operands of a call continued onto the next line with a trailing backslash sat in a record the call's segment never reached, and the backslash itself was read as an operand."
  - "At the Stage-6 build, through the suite runner under the CI layout, the change moved the suite's two named neutrality pins from allow to refuse and moved no existing payload arm from refuse to allow; 21 apparatus arms bound to the removed exits and views were retired or re-based."
---

# ADR-238 — The deletion guard judges every segment of a command line, keeps no exit that allows on a match, and refuses a deletion or Trash call that does not name all its targets on its line

## Status

**Proposed** — authored at Stage 6 Engineering for the `deletion-guard-judges-every-segment-and-target` release, per the Stage-6 ADR-authoring precedent. Ratification is recorded in this file's frontmatter `status:` field at Stage 13, which is where it must be verified, and is never inferred from milestone closure.

**Numbering provenance.** Claimed as **238** against an anchor of **237** on `origin/main`, read from `release/tools/renumber-adr.py --detect` at this record's authoring commit. A branch claim is detection-only and never binds; a sibling release in flight may claim the same slot, and should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Citations from other branch-authored artifacts use the slug token `{{ADR:deletion-guard-judges-every-segment}}`, which carries no number shape and resolves at the claim.

**Supersedes ADR-235 in part — decision 3 only.** ADR-235 decided that the deletion hook's two exits that allow on a match read a frozen, un-widened view of the canonicalizer, so that widening command-start detection could not turn a refusal at those exits into an allow. This record removes both exits, so the view they read loses its only consumer. ADR-235's decisions 1, 2 and 4 stand unchanged, and so does the principle its decision 3 protected: an exit that allows on a match must never read a widened view.

## Context

The deletion guard refuses a permanent deletion outside the workspace root, and a Trash or Finder move whose target lies outside it. Two of its steps returned an allow for the whole command line before every segment had been judged. Step 1 exited on a `git` command at any command start, on the reasoning that version-controlled deletes are recoverable through git history; its anchor accepts the start of the line and every position after a separator, so a `git` segment exempted every other segment. Step 2 exited when the deletion verb it matched named no operand, before the Trash and Finder steps ran; and it judged one rm-family verb, chosen by priority, so a second one could pass with no exit firing. Step 3 matched a Trash call with no literal operand and issued no verdict.

ADR-235 had already fenced these exits from the canonicalizer's widening by pointing them at a frozen view. That kept their verdicts stable, but it did not close the laundering they performed on ordinary command lines: a compound line that mixes a `git` command with a deletion is common agent work, and it silently lost the containment check.

A Trash program needs a further rule. The keg-only Homebrew `trash` on the reference host documents options that empty the Trash, and one that skips their confirmation; they take no operand. A Trash call that names no operand can therefore act on what the line does not show, so it cannot be judged by its operands at all.

## Decision

**(1) No exit allows on a match.** A segment whose command word is `git`, bare or by absolute path, is never judged as a deletion, because no step reads a segment whose command word is not its own verb. Every other segment on the line is judged as if the `git` segment were absent, except that the Finder step reads every quoted Finder path on the line, the `git` segment's own text included.

**(2) Every rm-family verb is judged on its own segments.** `rm`, `rmdir` and `unlink` are each judged wherever they sit at a command start. A segment that names no operand ends nothing.

**(3) A verb that does not name all its targets on its line is refused under the strict policy, and so is a deletion or Trash verb on a command that carries a line continuation.** A Trash segment is refused with `BLOCK-TRASH-003` when it names no operand under the walk's skip rules, and an `rm`, `rmdir` or `unlink` segment of the same kind with `BLOCK-TRASH-001`, judged after every other step so that a refusal of a real target elsewhere on the line names that target. A line continuation — outside the quoted here-document bodies the pre-pass removes, a line that ends in an odd run of backslashes — is decided by one rule rather than form by form. The hook reads such a command twice, as judged and with every continuation joined, and refuses it when either reading carries a deletion or Trash verb in a spelling the hook recognises: `BLOCK-TRASH-003` for a Trash call or a Finder delete, else `BLOCK-TRASH-001`, judged last. Its reach is an enumeration, not a closed class: a continuation that splits the command word; one between a wrapper option and its argument, or after a wrapper, keyword or assignment-shaped word; one after each redirection form, complete or with its word on the next line; a run of three backslashes; and a backslash that ends a comment, after which the next line runs as its own command. Its boundary is an over-block: any multi-line command with a continuation and a deletion or Trash verb in either reading is refused, whatever the shell would join. The walk's earlier per-form readings of a continued segment — its last word a continuation backslash, or at its end a redirection without its word or a both-streams redirection followed only by a separator and one blank — stay in place and refuse first where they fire. No new rule ID is introduced.

**(4) The hook reads one view.** It makes one default-view run of the canonicalizer on the command as judged, in the assignment form its three sibling consumers use, and one more only on a command that carries a line continuation, over that command's joined reading (decision 3). Its canary keeps the two probes that check that view. The canonicalizer keeps its exit and both views, now unconsumed.

**(5) Refusal precedence is unchanged.** The rm-family step, then the Trash step, then the Finder step, then the target-less rm-family limb.

**(6) Every reader of the segment walk goes through one helper,** so an argument the walk needs, such as a Trash install location to strip from a first token, is passed to the targets, directories and target-less readers at once.

## Alternatives Considered

- **Scope the two exits rather than delete them** — exit only when every segment is `git`, or when no other guarded verb appears on the line. Rejected: its predicate restates the whole segment walk as a second copy that must be kept equal to the first, and it keeps an exit that allows on a match, the class ADR-235 decision 3 had to fence.
- **One segment dispatcher** emitting every guarded verb and its operand-or-bare marker in line order. Rejected: refusal precedence becomes positional, so the rule ID of an existing refusal on a multi-verb line can change, and it edits a sibling card's step in the same release.
- **Per-segment command-word records in the shared canonicalizer, for all four anchor hooks.** Rejected on blast radius: it edits the shared primitive a sibling release was rewriting at the same stage.
- **Reuse the destructive-command hook's own segment loop.** Rejected on blast radius: it couples to an always-enforce file under rewrite.
- **Let a target-less rm-family verb carry no verdict of its own** (it deletes nothing). Rejected at the plan gate in favour of the refusal, which matches the card's expected behaviour and refuses an operand the walk skipped as shell structure rather than passing it.
- **Keep the both-view read and the third canary probe.** Rejected: the probe would fail an always-enforce hook closed on a canonicalizer property the hook no longer reads.
- **Retire the exit and both views from the canonicalizer in this release.** Deferred: the views are pinned in two sibling suites, one of them in a sibling release's write set.

## Consequences

- **Positive.** A compound line that mixes a `git` command, a target-less deletion verb or a flags-only Trash call with a deletion now keeps its containment check. A canonicalizer widening can only add command starts to judge; it can no longer turn a refusal into an allow anywhere in this hook. Two exits and one view fewer.
- **Declared moves, allow to refuse.** The suite's two neutrality pins (a `sudo`-prefixed git command beside a deletion, and a `sudo`-prefixed target-less `rm` before a Trash call). A commit message carried by a here-document the quoted here-document pre-pass declines — inside a command substitution with a deletion-verb line it cannot mask, under an unquoted delimiter, or on a command that pipes elsewhere — is judged as command text once the whole-line `git` exit is gone. A Trash call on a line that ends in a separator and a continuation backslash, followed by a plain command, moves from allow to refuse under the continuation rule of decision 3.
- **Declared over-blocks.** A help or version request of either verb family; a lone flags-only `rm`; any multi-line command with a line continuation and a deletion or Trash verb in either reading, among them a Trash call legitimately continued onto a second line of inside operands, a Trash call on a line that continues past a later command or after a separator, and an inside Trash call at the start of a line after a comment that ends in a backslash or after a run of three backslashes; a Trash call on a line that ends in a both-streams redirection, a separator and exactly one blank, which the canonicalizer renders as it renders the dropped continuation.
- **Declared residuals.** A Trash call that carries an option emptying the Trash together with at least one inside operand is judged by its operands alone and allowed; the option's reach beyond the line is not read. The joined reading of decision 3 reads the line after a comment that ends in a backslash as part of that comment, although the shell runs it as its own command, so a deletion or Trash verb on it that only joining would reveal — a command word a continuation splits, or a wrapper and its option spread over continued lines — is seen by neither reading.
- **Dependency.** Commit messages carried by a top-level quoted here-document stay allowed only through the quoted here-document pre-pass, which reads the body as data for a recognised receiver; a decline there keeps the body judged.
- **Debt created.** The canonicalizer's exit and both views remain as unconsumed code, pinned in two sibling suites, until a follow-up retires them.

## Reversibility

**MODERATE · Confidence HIGH.** Revert the commit and republish the hook bundle, verified by hash. The exit removal, the single-view read and the canary change ship in one commit and revert together: restoring an exit while the hook reads only the widened view would put an exit that allows on a match onto that view, the refusal-to-allow class ADR-235 decision 3 fences.

## Related ADRs

- **ADR-235** — superseded in part (decision 3, the frozen view for the allow-on-match exits); decisions 1, 2 and 4 stand.
- **ADR-187** — command-start detection is a canonicalizer, not a parser; unchanged.
- **ADR-181** — an ADR citation binds at the Stage-12 claim; this record is cited by slug token until then.

## References

- `#8122` — the card this record decides: the deletion hook stopped judging a compound command before every segment.
- `#7644` — the quoted here-document pre-pass that heredoc-borne commit messages rely on.
- `#8123` — the sibling card that recognises the keg-only Trash location, which the single walk helper of decision 6 passes to every reader.
