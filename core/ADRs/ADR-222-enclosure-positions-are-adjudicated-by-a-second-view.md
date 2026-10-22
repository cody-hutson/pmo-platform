---
title: ADR-222 — Enclosure positions are adjudicated by a second view
status: Proposed — authored at Stage 6 Engineering under the release's Collective Review scope-lock; the transition to Accepted belongs to the Stage 13 ratification beat
date: 2026-10-16
release: hook-walk-adjudicates-every-operand
deciders: "Workspace owner (operator) — scope rendered at the release's Stage-5 Collective Review scope-lock: close the enclosure fail-open; include the two adjacent fail-opens the design found, with the independent adversarial review's correction; a phased rollout in which new findings enter at the warn phase and a later graduation decision is owed; the unmilestoned sibling card for the grouping and xargs shapes kept separate. Design by the Stage 5 Solutioning spoke (an eight-candidate design exploration); authored by the Stage 6 Engineering spoke"
tags: [block-destructive-022, script-execution, command-position, enclosure, command-substitution, second-view, here-document, phased-rollout, fail-direction]
source_observations:
  - "At the Stage-4 pin 4babbba94f3ddf99a658d39fc0dbb7af0f664066, 147 of 258 measured payloads made the real shells (bash 3.2 and zsh 5.9, with marker scripts) run a script missing from the allowlist. The hook refused 34, recorded 17 and neither refused nor recorded 96. A shell interpreter or source inside a command substitution, backticks, a process substitution or a parenthesised group was allowed with nothing recorded, at the shipped phases and with both rollout phases forced to enforce."
  - "Two single-pass splitter forms were built and measured at the pin. Making the parenthesis and the backtick separators moved 7 of 178 payloads out of refusal and broke two tracked arms; opening a segment only after an opener moved 6 and broke one. An enclosure is the operand of the command around it as often as it contains a command."
  - "The design's final text, measured at the pin: 0 of 258 payloads moved out of refusal at the shipped phases or forced, 117 of the 147 executions were refused and 10 recorded, and the unmodified tracked suite read 672 of 673. The one changed arm asserted an allow on a command both shells execute."
  - "Two adjacent fail-opens share the cause. A carrier's quoted-argument exemption was inherited by a command inside an enclosure: echo $(bash -c 'cd /tmp; bash <unlisted>') was allowed while the same text behind a semicolon was refused. The here-document pre-pass read the receiver from the line head, so it excised a body that an interpreter inside an enclosure executes."
  - "The independent adversarial review rebuilt the hook from the design's edit blocks and found it equal to the recorded digest; over 204 payloads of its own and 1,033 corpus commands nothing left refusal. With the close enforcing, 294 merged pull-request bodies passed inline went from 1 refusal to 5 and from 24 bodies with a would-fire row to 48. A run of 500 parenthesis characters took about 17 s on the final text against 0.1 s on the pin, so the two work budgets bound positions and copied bytes, not time."
  - "The review also found two first-view corners the design had called untouched: adding the openers to the here-document pre-pass's scan spends its shared work budget sooner, and the receiver conjunction keeps in place a carrier's unquoted substitution that reads a here-document through cat, where nothing runs. Both move toward refusal."
---

# ADR-222 — Enclosure positions are adjudicated by a second view

## Status

**Proposed** — authored at Stage 6 Engineering, after the operator's Collective Review scope-lock rendered the scope this record documents. The Stage 13 ratification beat owns the transition to Accepted; this record is not written Accepted at authoring.

**Numbering provenance.** Claimed as **218** against an anchor of **216** on `origin/main`, read from the repository's own ADR-numbering detector, which reported 217 as this branch's earlier claim and 217 and 218 also held on sibling branches (detection only, never binding). The number binds at the Stage-12 claim; should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. In-release prose cites this record by its slug token, which carries no number shape and resolves at the claim.

**Numbering provenance — `218 → 222`.** Held **ADR-218** branch-local; renumbered to **ADR-222** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 218. In-release citations that read "ADR-218" denote this record.

## Context

BLOCK-DESTRUCTIVE-022 splits a command on `;`, `&`, `|` and newline, and walks each segment's command position to the script it executes. An enclosure — `$( )`, backticks, `<( )`, `>( )`, `( )` — is not a separator, so the verb inside it never starts a segment, and the walk never looks at it. The hook's own comment recorded that `$(bash <script>)`, `` `bash <script>` ``, `cat <( bash <script> )` and `echo "$(bash <script>)"` were allowed and said closing it was a widening "tracked separately"; no tracker existed.

The rule is a lexical matcher by decision. It reads raw argv and is deliberately not routed through the shared command-position canonicalizer, which suppresses delimiters inside `$( )`. An enclosure plays two roles a splitter cannot tell apart: in `echo $(bash <script>)` it contains a command, and in `bash "$(pwd)/<script>"` it is part of the operand of a command the walk already adjudicates. Two exemptions written for the head of the line — who opened the quote a segment sits inside, and who receives a here-document — were read only at the line head, so a command inside an enclosure inherited them.

## Decision

1. **Two views.** The shipped segmentation runs first. A second view of the same segments opens one command position after every `(` and every backtick, appends the rest of the segment, cuts it at that position's own closer, and runs the same walk there. The cut is scanned locally from a fresh quote state; when no closer is found or the scan's step budget is spent, the text is left whole, which adjudicates more rather than less. A segment start the first view adjudicated is not adjudicated again. An opener behind an odd run of backslashes is a literal character to the shell and opens nothing. The predicate is two characters, so every construct that opens with one of them is reached with no list of constructs to keep complete.

2. **The two adjacent fail-opens close with the cause they share.** A segment start the first view suppressed, as interior to a carrier's quoted argument, is re-opened in the second view, where the command that owns the quote can sit inside an enclosure. The here-document pre-pass reads the receiver twice — from the last separator before the operator, as before, and from the innermost enclosure still open at the operator — and a body is excised only when both readings are carriers. This fix has two measured limits, stated rather than argued away: it does not reach a receiver behind a line continuation, because the pre-pass reads physical lines; and it newly flags a carrier's unquoted substitution that reads a here-document through `cat`, where nothing runs.

3. **Every arm runs at a second-view position, each at its own phase.** A direct execution or a non-shell interpreter there is recorded at that arm's rollout phase, so the fail-open is not reborn the day either arm graduates.

4. **A phased rollout for the always-enforce arms' new reach.** A shell interpreter or `source` finding at a second-view position — including the `xargs` standard-input deny and the here-document receiver conjunction — is routed to a third family of the rule's rollout constants, which enters at `warn`: the call proceeds with a would-fire row (arm `shell-enclosure`) and a notice on stderr. At `enforce` it is refused exactly as a first-view finding is, and an unrecognised phase value falls through to `enforce`. The router is a pass-through at a first-view position, so a first-view shell or `source` finding still reaches the adjudicator unconditionally; a suite arm asserts that, where the shipped arms' unedited call sites used to carry it. The deploy-time graduation check reads the new family through one word in its family list and one line naming the family's `arm` value, so the warn phase cannot outlive its review window unaddressed. A later graduation decision is owed.

5. **One constant key on every row a second-view position writes: `pos: "enclosure"`.** It says where a row came from, and not whether the text at that position is executed, which a lexical matcher cannot know: no structural key the hook holds separates a real invocation from prose at the same position. Rows from the first view are unchanged.

6. **Two declared work budgets.** At most 512 positions per command and at most 262,144 bytes of appended remainder; past either, a position is not opened or is opened without its remainder. Both degrade toward "this position is not seen". They bound positions and copied bytes, not time.

7. **The receiver conjunction reports like the rule's other phased findings.** Its row names the receiver read from the enclosure, and at `warn` it prints the notice the other phased arms print. The design's text named the line-head carrier and printed nothing; the independent review asked for this correction if the phased option was taken, and it was.

8. **Not decided by this record.** The graduation of the third family. The unmilestoned sibling card for a parenthesised group and an `xargs` form stays separate. The positions the walk does not reach — a `case` arm, `coproc` — the carried quote state's desynchronisation, the line continuation, the here-document receiver behind a group opener and a per-command work ceiling are each routed to their own card.

## Alternatives Considered

- **Port the egress splitter: the parenthesis and the backtick as separators.** The precedent the card's launch named. Rejected on measurement: it moved existing refusals to allow and broke two tracked arms. The egress splitter neutralises quotes first and feeds a boundary ladder; this one feeds an operand walk that needs the whole segment.
- **One splitter, a new segment after each opener.** Rejected on measurement: an enclosure that is the operand of a first-view command is cut off its verb, and refusals moved to allow.
- **Test every token against the operand domain when a segment holds an enclosure.** Rejected: the rule adjudicates execution capability, not mention, and read-only commands that name a script would be refused.
- **Route this rule through the shared canonicalizer.** Rejected: the canonicalizer suppresses delimiters inside `$( )` by design, and this rule is deliberately not routed through it; changing either moves the anchored rules of four always-on guards.
- **A shared segmentation library, or a shell-grammar parser.** Rejected: the two guards' splitters have different contracts, and a parser replaces the primitive every arm traverses, out of proportion to the class.
- **Declare and pin today's verdicts.** The card's other branch. Not taken: the scope-lock closed the fail-open.
- **Pair backticks, so a closing backtick opens no position.** Rejected: pairing needs the carried quote state to be right, and one literal backtick inside single quotes shifts every later pair, so a real opener is read as a closer. The view pairs nothing and declares the cost.
- **Enforce on landing.** Not taken. The review measured the over-match on merged pull-request bodies passed inline as several times what the commit-message corpus suggested, and the scope-lock chose a phased rollout. What the warn phase measures is how often the close would refuse, not how often it would be right.
- **Shell and `source` arms only at a second-view position.** Rejected: a direct execution or a non-shell interpreter inside an enclosure would go unrecorded, and the fail-open would return the day either arm graduates.
- **A richer structural key on each second-view row.** Rejected: measured, no value of it separates a real invocation from prose.
- **A comment skip.** Built and measured, and left out: the first view models no comments, and an unquoted here-document body evaluates a substitution on a line that begins with `#`.
- **Classify a position before paying for it, under one command-wide budget**, and **narrow `source` at a second-view position to the token after the verb.** The review's counter-designs; not adopted at the scope-lock.

## Consequences

**Positive.** A shell interpreter or `source` inside `$( )`, backticks, `<( )`, `>( )` or `( )` reaches the same walk as one behind a separator, and a direct execution or a non-shell interpreter there is recorded at its arm's phase. The two adjacent fail-opens close with it. A construct added to the language later that opens with either character is reached with no edit. A drain row says which population it belongs to.

**Negative.** At the `warn` phase the fail-open is recorded, not refused, until the graduation decision. The view adjudicates text it cannot tell from a command: a quoted argument of a command outside the carrier set, a here-document body left in place, a comment, text after a closing backtick, a quoted argument that follows an unquoted enclosure in a carrier's argument list, an array literal, and an escaped dollar under a non-carrier. Those draw would-fire rows now and refusals once the phase graduates; after an inline code span a sentence's full stop is the dot command's spelling, so such a row can name a path such as `/`. It does not reach: a verb behind a compound-command keyword or a brace that the prefix walk does not read; a `case` arm; `coproc`; a backtick substitution nested through escaped backticks; quoting the cut does not model, such as ANSI-C quoting or a `)` inside a parameter expansion; an apostrophe in a nested double-quoted string, which turns the carried quote state over; a carrier at the head of an unquoted substitution, whose exemption a later program string inherits; a here-document receiver behind a line continuation; and anything past either budget. The position ceiling counts every opener, quoted or escaped, so an author can spend it: enough openers of inert text ahead of a substitution leave it unseen. The list is the limits known and measured, not a closed set. Two first-view corners move toward refusal, as the review found. A long run of openers is slow, and a command hook that passes the harness's timeout does not block; the first view has finished before the second starts, so a stall loses only the second view's own findings. The two pending graduations' drains gain rows from enclosure positions, each carrying the position key, so a graduation decision should read the two populations separately. A third graduation decision is owed.

## Reversibility

MODERATE. A revert of the change's commits restores the single view, and an instance runs the restored hook only after the hook publisher republishes the bundle. Advancing the third family to `enforce` is a one-word edit, and retreating it to `shadow` is another; an advance refuses, on every instance, text the warn phase only recorded.

## Related ADRs

- ADR-150 — the rule governs execution capability. Its alternative A10 kept the shipped arms' call sites byte-preserved; this record routes the shell and `source` call sites through a router that is a pass-through at a first-view position, which a suite arm asserts, so that the second view can carry its own rollout phase.
- ADR-187 — command position is canonicalized, not parsed. Its first non-claim stands: this rule is still not routed through the canonicalizer, which still suppresses delimiters inside `$( )`.
- ADR-205 — a refusal record carries structure, never the command; the position key is structure.
- {{ADR:script-wrapper-walk-reads-option-grammar-from-rows}} — the prefix walk the second view runs at each position, read unchanged.

## References

- #7028 — the card: the enclosure fail-open had no tracker while the shipped readiness text said it was tracked separately.
- #7637 — the unmilestoned sibling card for a parenthesised group and an `xargs` form, kept separate at the scope-lock.
- #7026 — owns the graduation decisions on the two earlier phased arms, whose drains gain rows from enclosure positions.
- #8316 — owns the command positions the walk does not reach, among them a `case` arm and `coproc`.
- #8317 — owns the carried quote state's desynchronisation, among it an apostrophe in a nested double-quoted string.
- #8320 — owns the line continuation that segments a command, and the here-document receiver behind one.
- #8326 — owns the here-document false positives, among them a receiver behind a group opener.
- #8327 — owns a per-command work ceiling for the segment and enclosure passes.
