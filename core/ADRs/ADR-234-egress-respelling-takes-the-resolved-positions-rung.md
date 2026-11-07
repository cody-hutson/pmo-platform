---
title: ADR-234 — BLOCK-EGRESS-007 reads a respelled gh api write as the shell resolves it, and rungs it by the position the shell resolves it to
status: Proposed — authored at Stage 6 Engineering for the guards-judge-every-spelling-alike release. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter status field, never inferred from milestone closure.
date: 2026-11-04
release: guards-judge-every-spelling-alike
deciders: "Workspace owner (operator) — the rung doctrine, the counter rule, the join rule and the per-class rungs adopted as recommended at the release's Collective Review scope-lock; the unparseable-branch reader, the derived fast path, the parse-boundary guard and the residual successors rendered at the inter-stage decision on the Stage-5 delta, which also folded the attached and clustered short-flag class into the card. Design by the Stage 5 Solutioning spoke and its bounded delta, reviewed by an independent adversarial design review; authored by the Stage 6 Engineering spoke"
tags: [block-egress-007, gh-api, command-position, spelling-invariance, rollout-phase, fail-direction, unparseable, reversibility-moderate]
source_observations:
  - "At the Stage-4 pin, six spellings reached an unlisted gh api write past the rule's own walk with no record, at the shipped phase and with the phase forced to enforce, while the plain form was refused from day one: a leading redirection, a line continuation between the verb and its subcommand, a backslash-escaped verb, a brace-expanded command word, an ANSI-C-quoted verb, and arguments supplied on standard input to a list-builder. Three more were found at the class level — a continuation inside a prefix command's option run, an escaped prefix word, and a case-variant command word — and a tenth at the Stage-5 delta: a method or field flag written in its attached or clustered short form."
  - "The replaced matcher's pattern needed whitespace after --method, yet the shipped hook already refused gh api --method=DELETE <unlisted> on day one. The shipped classifier therefore already gave a respelling of the head write the day-one rung; the readiness text's sentence that a deny is a widening exactly when the replaced matcher could not have produced it was false of the shipped code."
  - "The plainly spelled env gh api -X POST <unlisted> is recorded, not refused, at the shipped phase. No prefix-position respelling can therefore be refused by a spelling repair without graduating the phase, which the progressive-rollout convention reserves to the operator."
  - "Two naive repairs each withdraw a shipped refusal. Counting a respelled invocation as the command's first invocation moves a later plain write from refused to recorded. Joining every continuation turns a refused env -u X then backslash-newline then gh api -X POST <unlisted> into a prefix position, recorded."
  - "The independent adversarial review found the design repaired one of the rule's adjudication gates and left two keyed on the plain spelling: the unparseable branch's reachability test, which none of the day-one spellings passes, so each was admitted whenever the command also carried a construct the scanner cannot tokenize; and the fast-path gate, which skipped a verb split by quote characters and two adjacent ANSI-C strings. It also traced that ending an ANSI-C span at the first unescaped quote moves an implicit-POST or later-invocation write to an unlisted path from refused to recorded."
  - "At this card's Stage-6 entry the egress suite read 423 of 423, and with this card's arms and corpus rows run against the pre-change hook in the worktree's hook layout it read 89 failures out of 528, every one of them this card's own arm or the re-pointed pin; with the change in place it read 528 of 528."
---

# ADR-234 — BLOCK-EGRESS-007 reads a respelled write as the shell resolves it, and rungs it by the resolved position

## Status

**Proposed** — authored at Stage 6 Engineering for the `guards-judge-every-spelling-alike` release. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance.** This record was authored at the next free number computed from the mainline anchor plus one, advanced past the slot the release's own first record already holds on this same branch. A branch claim is detection-only and never binds for mainline purposes, but a same-branch claim is a file that already exists, and taking its number would be a duplicate rather than a claim. Citations use the slug token `ADR-234`, which carries no number shape and resolves at the claim.

**Extends ADR-226 and keeps its constraints.** ADR-226 decided that the egress rule's head walk stays its own, that a gh api write behind a prefix command is located by a domain-test look-ahead and recorded at the rule's current phase, and that no phase constant moves. All of that stands. This record decides how the rule reads a write whose verb, position or flag is written in a spelling the shell resolves to the plain one.

**Numbering provenance — `230 → 232`.** Held **ADR-230** branch-local; renumbered to **ADR-232** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 230. In-release citations that read "ADR-230" denote this record.

**Numbering provenance — `232 → 234`.** Held **ADR-232** branch-local; renumbered to **ADR-234** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 232. In-release citations that read "ADR-232" denote this record.

## Context

A shell resolves many spellings of one command to the same command word, subcommand and flags. A redirection word is no argv word, wherever it stands. A backslash-escaped, brace-expanded, ANSI-C- or locale-quoted command word names the same program as its plain spelling, and so, on a case-insensitive volume, does a different letter case. A backslash-newline is removed before any word is read. A verb split by quote characters is one word. And gh's own flag parser reads a short flag written attached (`-XPOST`, `-X=POST`) or clustered after its one boolean flag (`-iX POST`) exactly as it reads the separate form.

The rule read every one of those in its plain spelling only, in three places: the tokenized walk, the unparseable branch's reachability test, and the fast-path gate in front of both. A write the plain-form day-one deny refuses was therefore admitted, with no record, when a respelling reached it — the defect class of a check keyed on spelling rather than on the action, which does not mediate every access.

Two facts shaped the response. First, a respelling at a prefix position cannot be refused by a spelling repair at all, because its plain twin is itself only recorded there at the shipped phase; refusing it is the phase graduation another card owns. Second, every naive repair has a way of withdrawing a shipped refusal — through the first-invocation counter, through a continuation join, and through a command crossing the scanner's parse boundary into the looser classifier — so the repairs had to be shaped so that none of those can happen.

## Decision

**(1) A respelling takes the rung of the position the shell resolves it to.** A write at the head of a segment the replaced anchor admitted — the command's first counted invocation, with an explicit write method — is refused from day one in every spelling the rule resolves; every other position is a widening and follows the rollout phase. No phase constant moves, and each guard keeps its own walk: the rule is not routed through the shared canonicalizer, whose insertions would read every prefix, keyword and subshell position as a head and so graduate the phase as a side effect.

**(2) A respelled invocation never advances the first-invocation counter.** It counts on its own counter, and it is refused on day one only when no counted invocation precedes it and it is the first respelled one. Every verdict the shipped hook gave an invocation it could already resolve is kept, and a respelled read before a plain write leaves that write refused — the one declared asymmetry, stricter than the plain twin and never looser. An invocation the head walk reaches only behind the append form of a prefix assignment, which the walk steps over as it steps over the plain `NAME=value` form, is held the same way: it advances neither first-invocation counter, so a later write at the head of a segment keeps its day-one refusal, and a read written behind that form before a write leaves the write refused where its `NAME=value` twin records it — the same asymmetry, in the same strict direction.

**(3) A continuation is joined unless the line it would join earns a verdict of its own.** The keep rule holds when that line carries an adjacent gh api pair and its first word is neither `api` nor a dash-led word without a slash; such a line is a fresh command start in the shipped hook, and joining it would make it a prefix position. A join is never made inside a comment or on an even backslash run.

**(4) Arguments on standard input stay a residual.** The hook cannot see them, so no lexical repair recovers the write, and the only verdicts available are fail-closed policies that belong with the graduation evidence.

**(5) The case fold reaches the verb and a prefix word, never the subcommand and never a reserved word,** and the walk folds, unescapes or brace-expands a token only when it reaches that token directly — never the first token after a prefix command's option run, which may be that option's argument.

**(6) The unparseable branch reads the same spellings, at its own positions only.** A second reader is joined to the unchanged shipped test by one `||` line, and the shipped test runs first, so every refusal it makes stands. The reader reads each piece with the walk's own helpers, in the physical lines and in a view with every continuation joined, passes over no keyword, assignment or prefix word, and stops at the existing parse cap.

**(7) The fast-path gate is derived from the transformations it guards:** the command is tested with its quote characters and `$` removed, for a `gh` in either letter case or a backslash, which is a superset of what any of the rule's locators can resolve. The removal is one pass of `tr` in the C locale, linear in the command's length, and a failure of that pass sends the command to the full scan: the gate runs on every command that reaches the rule, a pattern substitution over the whole command grows superlinearly on bash 3.2, and a hook that outlasts the runtime's timeout does not block.

**(8) An ANSI-C span changes what it says, never where it ends.** It is decoded only where it ends at the shipped scanner's terminator; a span whose body ends in an odd backslash run there is read exactly as before, so no command crosses the parse boundary in either direction.

**(9) A method or field flag is read in each form gh's parser accepts** — separate, attached, clustered after the boolean `-i`, and `--long=value` — so it sets what its plain spelling sets and its value is never taken for the path.

**(10) A quoted `<` or `>` is content, never a redirection.** The scanner carries each through the redirection strip as a stand-in and puts it back afterwards, so the strip reads the redirection grammar as the shell does, on unquoted operators only.

## Alternatives Considered

- **Route the rule through the shared canonicalizer.** Rejected: the canonicalizer's command-start insertions would read every prefix, keyword and subshell position as a segment head and so graduate the widening phase as a side effect, and its quote-preserving output does not match this rule's quote-dropping tokenizer.
- **Consume only the canonicalizer's redirect and escape faces through a new output mode.** Rejected: it supplies two of the faces the rule needs, inherits the canonicalizer's final shape, and serializes behind it — the strongest surviving alternative, losing on coupling.
- **A new shared word-normalization library.** Rejected: a new startup dependency in a mode-capable hook with one consumer, the ground on which the earlier walk decisions also rejected a shared word library.
- **Graduate the phase.** Rejected: the phase is the operator's and its graduation card's, and it would also refuse every look-ahead text row the rule declares as over-evaluation.
- **Count respelled invocations like plain ones.** Rejected: it withdraws shipped refusals.
- **Join every continuation**, and **a two-pass join** (the physical view first, then the joined view for invocations the physical line did not resolve). The first withdraws shipped refusals; the second also reaches the option-argument continuation that stays a residual, at the cost of an outer loop and per-line state in a security hook, for a sub-shape that could only reach the record — the strongest surviving alternative to decision 3.
- **Rewrite the unparseable test with its own spelling grammar** (rejected: a second spelling grammar in one hook can drift from the walk's), **run the repaired walk over the part of the command it can tokenize** (rejected: the walk's rungs differ, so today's refusals there would move to recorded or allowed), and **declare the untokenizable population a residual of every day-one class** (rejected: a one-construct bypass of every class is not a residual any owner should inherit).
- **Declare and pin the parse-boundary movement instead of guarding it** — end an ANSI-C span where the shell ends it and accept the refused-to-recorded movement of some unlisted writes as a named exception — and **guard by re-running the pre-change scan** (rejected: two scanners and a coupling of decoding to path classification). The guard chosen keeps the acceptance criterion's literal zero; reversing it to declare-and-pin is a one-line edit.
- **Read a quoted `<` or `>` as a redirection, as the quote-erased text alone would.** Rejected: a quoted word that begins with `>` would be dropped and a write behind it allowed, and a quoted field that begins with `<` would hand its flag the path; both are movements the shell does not make.

## Consequences

**Positive.** At the head of a segment, a write reached through a leading redirection, a continuation between the verb and its subcommand, an escaped, brace-expanded, ANSI-C-quoted or case-variant verb, or an attached or clustered method flag is refused from day one, in a command the scanner can tokenize and in one it cannot. Behind a prefix command each of those spellings is recorded, as its plain twin is. A write behind the append form of a prefix assignment is recorded as its `NAME=value` twin is, with the counter held as decision 2 states. No verdict of an invocation the shipped hook could resolve moves, and no shipped day-one refusal is withdrawn.

**Declared movements.** Tightenings: a method value behind a redirection, on a continued line, or ANSI-C-quoted; an escaped subcommand; and the respelled twin of every command the unparseable class already refuses, a read included. Precision improvements: a redirection or a continuation among the operands, an ANSI-C- or locale-quoted path the shell resolves to an allowlisted one, a clustered short flag's separate value no longer taken for the path, and an explicit read method beside a field flag, now a read. Two declared over-refusals: a heredoc body line shaped like a quotation line — a bare `>`, one word, then a gh api call — reads as the redirection the shell would read on a command line; and a backslash or a brace group inside a quoted command word, prefix word or subcommand, or an ANSI-C span that decodes to a backslash ahead of the verb, is read as its unquoted twin, refused at the head of a segment and recorded behind a prefix word, though the shell runs a command or subcommand named with those literal characters, which does not exist, so no write is involved.

**Residuals.** Arguments on standard input, a continuation that leaves a prefix command's option argument or operand at the head of the verb's line, zsh's `=command`, a pathname-pattern command word, and a respelled verb in an untokenizable command above the parse cap are admitted with no record, and are owned by the card for this rule's unrecorded spellings. Every respelled write behind a prefix command is recorded and becomes a refusal when this rule's widened surface graduates. A nested, sequence, escape-bearing or all-empty brace group, a brace group whose expansion is past the brace step's bound (which the step reads as written, as the shipped hook reads every brace group, so that a group whose words share a long prefix or suffix cannot make the step build text faster than the command grows), an ANSI-C escape outside the decoded set, a redirection written against the word before it, and an escaped or brace-expanded method value are declared and are owned by that card as well. One cost residual is accepted too: the constant-multiple class, steps of the rule that cost more than the shipped hook on the same command at every timed size while growing no faster than it, whose follow-up is the card that makes a guard hook block the tool call when it times out or fails.

**Neutral.** The rule's word list, its two pattern lines and every record key are unchanged: a respelled write behind a prefix command is a head-walk row or a look-ahead row like any other, and the unparseable record keeps its feature set.

## Reversibility

MODERATE. A revert of the change's commits restores the plain-spelling reads, and an instance runs the restored hook only after the hook publisher republishes the bundle; records already written keep their shape. Each repair sits behind one marked line, so a single repair can be withdrawn without the others. The parse-boundary guard reverses to declare-and-pin with a one-line edit, which would also need an operator-accepted exception for the movement it allows.

## Related ADRs

- ADR-226 — the egress prefix walk stops on the gated verb. This record keeps its look-ahead, its counter rule for look-ahead hits and its fixed phase, and extends each to respelled spellings.
- ADR-187 — command position is canonicalized, not parsed. This rule stays outside the canonicalizer, and the canonicalizer's own redirection handling is asserted beside this rule's in a parity table rather than shared.
- ADR-205 — a refusal record carries structure, never the command. The unparseable record a respelled twin writes is the shipped record, feature set included.
- ADR-206 — egress allowlist rows declare their match domain. A respelled write's path is matched against the rows declared for gh api paths, like any other.
- ADR-227 — the sibling guard's decision on the same grammar problem; each guard keeps its own vocabulary.
- ADR-235 — the shared canonicalizer's wrapper-grammar walk in the same release, whose redirection handling the parity table declares.

## References

- #8315 — the card: BLOCK-EGRESS-007's own command-position walk was evaded by alternate spellings, so a write the plain-form day-one deny refuses was admitted.
- #8650 — owns the respelled spellings this rule admits with no record, so that no rollout phase can refuse them.
- #6195 — the egress rule's widened-surface graduation, which turns every recorded spelling behind a prefix command into a refusal.
- #6194 — the egress drain's countability, whose populations gain the respelled rows.
- #8314 — the shared canonicalizer's wrapper-grammar walk, the sibling card in the same release.
- #8660 — makes a guard hook block the tool call when it times out or fails, instead of letting it through; the follow-up for the constant-multiple cost class this rule accepts as a residual.
