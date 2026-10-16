---
title: ADR-219 — The egress prefix walk stops on the gated verb
status: Proposed — authored at Stage 6 Engineering under the release's Collective Review scope-lock; the transition to Accepted belongs to the Stage 13 ratification beat
date: 2026-10-16
release: hook-walk-adjudicates-every-operand
deciders: "Workspace owner (operator) — the outcome rendered at the release's Stage-4 gate (a gh api write behind a prefix command's option or operand is evaluated and recorded at the rule's current rollout phase, and no phase constant changes) and the Collective Review scope-lock (the secondary-locator design, with the independent adversarial review's condition that a record written by the look-ahead be distinguishable from one written by the head walk; each guard keeps its own wrapper vocabulary; one tracked payload corpus read by each suite's own harness). Design by the Stage 5 Solutioning spoke (a six-candidate design exploration); authored by the Stage 6 Engineering spoke"
tags: [block-egress-007, gh-api, command-position, prefix-command, option-arity, look-ahead, rollout-phase, fail-direction]
source_observations:
  - "At the Stage-4 pin 4babbba94f3ddf99a658d39fc0dbb7af0f664066, env -u NAME gh api -X POST <unlisted> exited 0 with no would-fire record, at the shipped phase and with the phase forced to enforce; env gh api -X POST <unlisted> exited 0 with one shadow record; the plain form exited 2. Of the measured shapes that put a prefix command's option, operand or an unlisted word between the prefix command and a real gh api write, 61 left no record at all — timeout 5, env a-b=1, nohup <word> and all nine documented sudo options among them."
  - "A per-command table of the options that take a separate argument was prototyped in three roles. As the terminator of the walk it stranded both synthetic-option shapes; as a clearing table it stranded an unlisted operand and an unlisted launcher; as a step-only overlay beside the locator it changed no verdict on 144 of 144 sampled payloads."
  - "Counting an invocation only the new locator finds as the command's first invocation turned the day-one refusal of a later head-position write into an allow: 31 of 144 sampled payloads on the prototype and 35 of 192 on the final text's one-line mutant. With the counter held still for a locator hit, 0 of 576 generated payloads moved from refusal to allow in either phase, and the final text equalled the prototype on 103 of 103 arms in both phases."
  - "The independent adversarial review rebuilt the final text from the design and measured it: the unmodified egress suite read 259 of 259 against it. Of the 20 would-fire records it wrote, 19 were one string once the timestamp was removed, whether the head walk found a real write, the look-ahead found a real write, or the look-ahead found a printed command; and a prose line in a heredoc body that opens with a prefix word was recorded."
  - "The replaced matcher, read at its last commit, gated on an anchored command position but took its path from an unanchored grep over the whole command, so for env -u X gh api <allowlisted> ; gh api -X POST <unlisted> it adjudicated the allowlisted path and allowed. The shipped hook refuses that command because its head walk cannot see the first segment's invocation. Holding the counter still keeps the shipped hook's verdict; it is not derived from the replaced matcher's."
---

# ADR-219 — The egress prefix walk stops on the gated verb

## Status

**Proposed** — authored at Stage 6 Engineering, after the operator's Collective Review scope-lock rendered the scope this record documents. The Stage 13 ratification beat owns the transition to Accepted; this record is not written Accepted at authoring.

**Numbering provenance.** Claimed as **219** against an anchor of **216** on `origin/main`, read from the repository's own ADR-numbering detector, which reported 217 and 218 as this branch's earlier claims; 217 and 218 are also held on sibling branches, and 219 on none at authorship (detection only, never binding). The number binds at the Stage-12 claim; should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. In-release prose cites this record by its slug token, which carries no number shape and resolves at the claim.

## Context

BLOCK-EGRESS-007 resolves command position by walking the head of each segment. It steps over compound-command keywords, variable-assignment prefixes and a bounded set of prefix commands, each followed by its own dash-led tokens, and reads the first token that is none of these as the command word. That token is the command word only when no option of the prefix command takes a separate argument and the prefix command has no operand of its own. Otherwise the walk lands on the option's argument (`env -u NAME`), on the prefix command's operand (`timeout 5`), or on an assignment only that command accepts (`env a-b=1`); it reads that word as the command, finds no gated verb, and moves on, and the `gh api` write behind it is never examined. The card proposed a per-prefix-command table of the options that take a separate argument, consulted by the walk.

Two properties of the rule constrain the fix. Every position behind a prefix command is a widening under the rule's progressive rollout — the verb is never at the head of the segment — so a write found there follows the rule's current rollout phase, which records it and takes no action, and is refused only once that phase graduates. And the rule's rollout classifier counts the invocations the walk resolves: the first one, at the head of a segment opened where the replaced anchor admitted a command start and carrying an explicit write method, is refused from day one, and every later one is a widening.

## Decision

1. **A secondary locator behind the walk, terminated by the gated verb.** The head walk is unchanged, so every segment it already resolved is resolved identically. When a segment's head resolved through a prefix command and the walk did not land on the gated verb, the locator looks for the first adjacent `gh` and `api` words later in the same segment and adjudicates that invocation. It is a domain test, not a table of which options take an argument: nothing the locator passes over — an option, an option's argument, an operand, an assignment, a launcher outside the prefix set — is interpreted, so none of it can end the search before the verb. A table fails open on the first option it omits; the domain test has nothing to omit.

2. **A locator hit does not advance the first-invocation counter.** Counting it would move a later write at the head of a segment out of the day-one refusal and into the rollout phase: a refusal withdrawn by a change meant only to add evaluation. Holding the counter still keeps the shipped hook's verdict for every invocation the head walk resolves. That is the safe direction, and it is a property of the shipped hook, not a reconstruction of the replaced matcher, which adjudicated a different path for some of these commands.

3. **A locator hit follows the rule's current rollout phase; the phase does not move.** At the shipped phase the hit writes a would-fire record and takes no action; at `warn` it also prints a notice; at `enforce` it is refused like any other widening. This record changes no phase constant: the graduation belongs to the rule's own graduation card.

4. **A row written for a locator hit says so: `pos: "look-ahead"`.** The would-fire row carries one added structural key, `pos` with the value `look-ahead`. A row written for an invocation the head walk resolves carries no `pos` key, as every row written before this decision does. The key says which locator found the verb, not whether the words there are executed: a lexical matcher cannot know that, and a printed command behind a prefix word and a real write read the same to it. The key rides the rule's own would-fire drain, which this hook alone writes, and follows the sibling guard's position key. A refusal record — the block log at `enforce`, or the warn-mode record — keeps the record contract unchanged and carries no `pos` key.

5. **Each guard keeps its own vocabulary.** The prefix words stay where they are, and the locator adds no word and no table. The sibling guard's suite compares the word lists of every copy and reads this rule's from the two pattern lines after its one wrapper `case`, which this decision does not edit.

6. **The differential lives in the one tracked payload corpus.** The rule's rows join the release's tracked corpus, read by this rule's own suite through its own harness: every row runs through the shipped hook and must return its recorded verdict, and two detectors are shown able to fire — the hook with the locator removed moves the look-ahead rows to allowed, and the hook with the counter advanced for a locator hit moves day-one refusals toward allow.

7. **Not decided by this record.** The rollout phase's graduation. A separate phase constant for locator hits, and a field recording the shape of what the locator passed over — the review's further counter-design steps, not adopted at the scope-lock. Positions this rule's own walk does not reach at all, which the plain form's day-one refusal misses too — a leading redirection, a line continuation between the two words, an escaped, brace-expanded or ANSI-C-quoted verb, arguments that arrive on standard input — each owned by its own card. The shared canonicalizer's own prefix skip, which has the same option gap for the anchored rules, owned by its own card. And an invocation the walk resolves earlier in a command, which already moves a later head-position write into the rollout phase; that predates this record and is evidence for the graduation card.

## Alternatives Considered

- **An arity table as the walk's terminator** — the card's literal proposal: the walk consumes an option and its separate argument, and the first non-option token is the command. Rejected on measurement: it fails the card's own criterion that an option missing from the table must not strand the command, and both synthetic-option shapes were left unrecorded. Its failure direction is open on omission, across programs and platforms whose option sets differ.
- **A clearing table, scanning only after an unknown option** — the opposing view. Its strength is precision: text behind a prefix command is not evaluated. Rejected: an operand or a launcher the table does not know strands the command exactly as an unknown option does, a mis-recorded arity fails open, the table differs per platform, and the change is several times larger. The two survivors differ on one branch — what to conclude at a word that is neither an option nor a known operand — and that branch produces both the precision and the strand, so the two cannot be separated.
- **A step-only arity overlay beside the locator.** Built and collapsed into the decision: it changed no verdict, so it would add an inert table to a security surface.
- **Extend the shared canonicalizer.** Rejected: this rule is deliberately not routed through it, so the change would not reach the walk, and it would move the anchored rules of four always-on guards.
- **A shell-grammar parser.** Rejected: out of proportion to this coverage class, for the reasons the canonicalizer record gives.
- **Scan every segment for the pair, behind a prefix command or not.** Rejected on the false-positive ground the canonicalizer record states: text adjudicated as a command is an outage with a security label on it. This decision accepts that cost only where the walk was diverted by a prefix command, and states it below.
- **A locator that counts its own hits.** Rejected on measurement: it withdraws day-one refusals of later writes in the same command.
- **A shared wrapper-vocabulary library.** Not taken at the scope-lock: under this decision the only shareable fact is a word list, the two guards' lists differ on purpose, and a shared file would add a startup dependency to two always-on guards.

## Consequences

**Positive.** A `gh api` write behind a prefix command's own option, option argument, operand or an unlisted word is located and evaluated at the rule's current phase, where it was not evaluated at all, and is refused once the phase graduates. A new option, a new platform's option set or a new launcher needs no edit to the hook. No verdict of an invocation the head walk resolves changes, and no day-one refusal is withdrawn.

**Negative.** The locator does not model the prefix command's grammar, so a `gh api` pair that is only text behind a prefix word is evaluated as a write: a printed command (`env X=1 echo gh api -X POST <path>`, an `xargs -I{} echo …` dry run), and a prose line in a heredoc body, because each body line is a segment and several prefix words are also English words (`time`, `command`, `exec`, `env`, `nice`). Such a row reads the same as a row for a real write except that `pos` says the look-ahead found it; it does not say the words are text. At the shipped phase each is a record, and once the phase graduates each is a refusal, so the graduation decision should read the look-ahead rows apart from the rest. What the rule reaches is literal adjacent `gh` and `api` words at a position its walk resolves, with the method, fields and path it reads from the command's own text; anything else is undetermined, not covered. Known instances, not a closed set: a command carried as a string for another program to run (`bash -c '…'`, `env -S '…'`, `eval`), a command word that is a variable (`$GH api …`), a leading word outside the prefix set, and the positions the walk does not reach that the previous section names. A refusal record carries no `pos` key.

**Neutral.** The rule's word list is unchanged, and so are the two pattern lines the sibling suite's parity arm reads.

## Reversibility

MODERATE. A revert of the change's commits removes the locator, and an instance runs the restored hook only after the hook publisher republishes the bundle; rows already written keep their `pos` key. A graduation of the rule's phase, which this record does not make, refuses on every instance what the shipped phase only records.

## Related ADRs

- ADR-187 — command position is canonicalized, not parsed. This rule is still not routed through the canonicalizer, and the bounded prefix set that record fixes is the canonicalizer's own.
- ADR-205 — a refusal record carries structure, never the command. The position key is structure; its consumers still select shadow rows by their `phase` key.
- ADR-206 — egress allowlist rows declare their match domain. A locator hit's path is matched against the rows declared for gh api paths, like any other path.
- {{ADR:script-wrapper-walk-reads-option-grammar-from-rows}} — the sibling guard's decision on the same grammar problem, by per-wrapper option rows; each guard keeps its own mechanism, and that suite's parity arm reads this rule's word list.
- {{ADR:enclosure-positions-are-adjudicated-by-a-second-view}} — the sibling guard's position key, which this record's key follows.

## References

- #7004 — the card: a separate-argument option in the egress prefix-command walk hid the gated command behind it.
- #6195 — the egress rule's graduation card, which owns the phase decision and holds the evidence on an earlier invocation that moves a later write into the rollout phase.
- #6194 — the egress drain's countability, whose reader meets one more row variant.
- #8315 — owns the spellings this rule's own walk does not reach, which the plain form's day-one refusal misses too.
- #8314 — owns the shared canonicalizer's prefix skip and its incomplete wrapper set.
