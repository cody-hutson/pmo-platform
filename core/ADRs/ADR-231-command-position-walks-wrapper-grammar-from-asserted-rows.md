<!-- repo-integrity: allow-issue-ref — limb 1: the precedent number cited under Related ADRs is a principle number, not an issue in this repository -->
---
title: ADR-231 — The command-position canonicalizer walks each wrapper's own option grammar from an asserted copy of the script-walk rows, matches a prefix word on its basename, and serves a frozen un-widened view to the allow-on-match exits
status: Proposed — authored at Stage 6 Engineering for the guards-judge-every-spelling-alike release. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter status field, never inferred from milestone closure.
date: 2026-11-04
release: guards-judge-every-spelling-alike
deciders: "Workspace owner (ratification at this release's Stage 13 close gate); mechanism chosen at Stage 5 Solutioning against a scored candidate matrix and adopted at the release's Collective Review scope-lock, which also rendered the allow-on-match exits decision as the masked exit view"
tags: [architecture, security, hooks, command-position, canonicalizer, wrapper-grammar, reversibility-moderate]
source_observations:
  - "The shared canonicalizer stopped at a wrapper's first flag and matched a prefix word as an exact token, and its word set omitted three transparent wrappers and the compound-command condition keywords. A guarded verb reached through a wrapper's separate-argument option, an absolute-path wrapper, a wrapper outside the set, or an if/while/until condition was therefore not resolved, and the anchored rules of the four consuming hooks reached ALLOW without their allowlists or denylists being consulted."
  - "The script-execution rule already carries a per-wrapper option grammar in getopt notation, one row per wrapper (the BLOCK-DESTRUCTIVE-022 walk). The arity of an option is a fact about a program, not about shell grammar, so the same facts drive both walks; a field-for-field copy asserted equal by a suite arm reuses the facts without adding a runtime file to four always-on hooks' load path."
  - "Two exits in the deletion hook ALLOW on a match against the canonical text — a whole-line git exemption and a no-target exit. A canonicalizer that resolves a new command start widens those exits too, turning a refusal into an allow, which is the opposite of the intended direction and is invisible to a widening-only differential that measures newly-blocked payloads."
  - "The word-boundary git rules are not position-anchored, so an inserted separator that lands between git and its subcommand when a wrapper row consumes git as an option value or a positional removes a match the rules had before. That is a refuse-to-allow movement on commands that never run git, declared as a precision improvement rather than left unstated."
  - "Two rules read the canonical text anchored on an assignment rather than a verb: the PATH-manipulation rule and the anti-injection rule of block-destructive. The canonicalizer marked only the command word, so an assignment its prefix walk stepped over — handed to a wrapper, behind another assignment or a redirection, after a keyword, at a condition position, inside a group — never sat where the anchor reads, and the same assignment was refused in plain form and admitted in every other spelling."
---

# ADR-231 — The command-position canonicalizer walks wrapper grammar from asserted rows, matches on basename, and serves a frozen view to the allow-on-match exits

## Status

**Proposed** — authored at Stage 6 Engineering for the `guards-judge-every-spelling-alike` release, per the Stage-6 ADR-authoring precedent. Ratification is the operator's at the Stage 13 close gate and is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering.** This record's number was derived at Engineering Commit 0 against the mainline anchor, per the rule ADR-115 ratifies and ADR-181 extends: an enumerate-and-parse over both ADR directories returned anchor 228 and next-free 229. A sibling release held 229 branch-local and merged first, so the number was reconciled when the mainline was merged into this release branch, as the provenance note below records; in-release citations use the slug token `{{ADR:command-position-walks-wrapper-grammar-from-asserted-rows}}`, which binds at the Stage-12 claim.

**Extends ADR-187.** ADR-187 decided that command-start detection across the four regex-anchored PreToolUse hooks is resolved by pre-match canonicalization — not by a parser, and not by widening the anchor — with one shared implementation, insertion-only on the syntactic axis and quote-neutralized. All of that stands. This record widens the canonicalizer's reach to the faces ADR-187's first implementation left open, and narrows two of ADR-187's stated properties that the widening makes untrue as written.

**Numbering provenance — `229 → 231`.** Held **ADR-229** branch-local; renumbered to **ADR-231** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 229. In-release citations that read "ADR-229" denote this record.

## Context

ADR-187's canonicalizer resolved a command start past a bounded set of prefix words, but it stopped at a wrapper's first flag, matched a prefix word as an exact token, and listed neither three transparent wrappers (`nice`, `stdbuf`, `timeout`) nor the compound-command condition keywords (`if`, `while`, `until`). A guarded verb reached through any of four faces — a wrapper's separate-argument option, an absolute-path wrapper basename, a wrapper outside the set, or a condition position — was therefore not reached, and the anchored rule of each of the four consuming hooks concluded the invocation was not its business. On an always-enforce credential-read rule that is an admitted class with no rollout phase to soften it.

Two facts shaped the response.

**The option arity of a wrapper is data the platform already holds.** The script-execution rule walks each wrapper's own options from a one-row-per-wrapper table in getopt notation (`script_wrapper_row`). Re-deriving that grammar a second way would be a second thing to keep right; the facts are a property of each program, not of this walk, so they transfer.

**Two exits in the deletion hook allow on a match.** A whole-line `git` exemption and a no-target exit both read the canonical text and exit 0 when they match. Every command start the canonicalizer newly resolves widens those exits in lockstep, so a widening that correctly adds a refusal elsewhere simultaneously converts a refusal at those two exits into an allow. A differential that measures only newly-blocked payloads cannot see this direction.

## Decision

**(1) The canonicalizer walks each wrapper's own option grammar from a field-for-field copy of the script-walk rows, asserted equal by a suite arm.** `command-position.awk` carries the wrapper rows (`WROW`/`WOPT`/`WLARG`/`WNOX`/`WSPLIT`/`WLSPLIT`/`WLONG`/`WPOS`) copied byte-for-byte from `script_wrapper_row` in `block-destructive.sh`, and a parity arm (`WRAPROWS-PARITY`) fails CI when any field, or the wrapper key set, diverges. Copying rather than extracting to a shared runtime file is deliberate: a runtime file would add a dependency and a fail-closed canary to four always-on hooks' load path, the cost ADR-226 and ADR-227 rejected at their own scope-locks. The copy's drift is made impossible-to-ship, not merely detected, by the parity arm plus the mutants beside it.

**(2) The set gains the six missing words and a prefix word is matched on its basename.** `nice`, `stdbuf`, `timeout`, `if`, `while` and `until` join the enumeration, which is now equal to the script walk's (eleven wrappers, nine keywords), so the six parity-table declarations that deferred these words to a card retire. A prefix word is normalized before lookup — one leading backslash and full-token quotes dropped, then the basename taken — so `/usr/bin/env`, `\sudo` and `"sudo"` resolve as the wrapper they name. The lookup comes after two tests of the token as written: an assignment word and a redirection are recognized as what they are first, the order the script walk already uses, so an assignment whose value is a path and a redirection whose attached target is one are never read as the wrapper their last path segment names (`X=/usr/bin/timeout` is an assignment and `>/tmp/timeout` a redirection, and neither consumes the word behind it as a duration). The set stays a bounded enumeration: an unlisted leading word is the command, exactly as before, so an omission leaves an invocation un-adjudicated (the status quo) and never admits an evasion the pre-change hook would have caught.

**(3) The allow-on-match exits read a frozen, un-widened view.** The canonicalizer gains one additive output mode — the EXIT VIEW — that applies the same quote mask and the same `;` insertions as the default output but by the prefix walk as it stood before the wrapper grammar: the original fourteen words, matched as exact tokens, each stepped as one token. The deletion hook's git exemption and its no-target exit read the exit view, so they keep the verdicts they have today and the widening of the default output cannot turn a refusal there into an allow. The per-segment closure of the line-laundering those exits leave is a separate card's scope and is not implemented here. A version-skew canary probe in each consumer — a wrapper carrying a separate-argument option, resolved only by the walk that reads wrapper grammar, and in the deletion hook a third probe asserting the exit view does NOT expose that verb — makes a stale or damaged copy fail the hook closed rather than silently serving the pre-change walk.

**(4) Every assignment the default walk skips is marked, so a rule anchored on an assignment reads it at a command start.** The default output gains a fifth transformation, (e): a `; ` before each assignment word the prefix walk steps over — `NAME=value`, or its append form `NAME+=value`, which bash and zsh also read as an assignment word — and before each `NAME=value` operand a wrapper's own grammar consumes (`env`'s), never at offset 1. The two rules anchored on an assignment rather than a verb — `BLOCK-DESTRUCTIVE-020` (PATH manipulation) and `BLOCK-DESTRUCTIVE-023` (anti-injection) — then read an assignment handed to a wrapper, placed behind another assignment or a redirection, after a compound-command keyword or `!`, at a condition position, or inside a group, exactly as they read it at a command start; their own lines additionally read a declaration builtin's argument list and the append operator, which is rule text rather than canonicalizer text. The tightening of the anti-injection rule's spellings is declared, not incidental: the rule shares the PATH rule's shape, so (e) reaches both. (e) is insertion-only and acts only on tokens the walk already resolved as assignments, so the quote mask is untouched and no rule anchored on a verb gains or loses a match: the verb already carries its own insertion from (a), and no verb pattern can match an assignment token. **The exit view does not carry (e)** — it applies only the command-start insertions of (3) — so the allow-on-match exits are unchanged by this item, which a differential arm in the deletion hook's suite pins against a copy of the canonicalizer with (e) removed. Nor does the exit view step over the append form: its walk keeps the `NAME=value` test it had, because the appending spelling reaching the allow-on-match exits would turn a refusal there into an allow. An assignment behind more than ten prefix-run tokens is not marked: the cap a guarded verb carries applies to an assignment too.

## Consequences

### Properties of ADR-187 that narrow

ADR-187 is not edited; its text is the record of its own decision. This record states the two properties the widening makes untrue as written.

- **"Anything the anchor matched before still matches — the change is additive"** holds for a rule anchored on a **command position**. It does **not** hold for the **word-boundary git rules**: when a wrapper row consumes `git` as an option value or a positional, the inserted separator lands between `git` and its subcommand, and the rule no longer reads a git subcommand there. Each such command runs a different program under the user, variable or adjustment named `git` and never runs git, so the move from refused to allowed is a **declared precision improvement**, pinned by an arm beside a refused control that does run git.
- **"The canonicalizer can add a boundary for the git rules but never remove one"** (the in-hook comment at the primitive declaration) narrows to the same clause: an inserted separator *between* `git` and its subcommand breaks `git<space>push` even though no boundary character was removed.

The precision figure for the widened false-positive surface is the one this release's own false-positive control measures across the four consumers' verb union — it is not inherited from the script walk's 0-of-510 figure, which was measured over a different (interpreter-verb) population.

## Alternatives Considered

| # | Alternative | Why not |
|---|---|---|
| **A1** | **Membership only** — add the words, no option grammar. | A wrapper's separate-argument option becomes the command word, so a face stays open and the amended AC1 fails. |
| **A2** | **Dash-run skip** — step every dash-led token. | A describe-only option exposes a bare verb to the no-target exit, and a separate option value is read as the command word; both wrong. |
| **A3 (selected)** | **Copy the option rows, asserted by a parity arm.** | Closes the four faces with one implementation for the four consumers; drift fails CI; adds no runtime file. |
| **A4** | **Extract the rows to a shared runtime file.** | Same verdicts at a higher cost: a new load-path dependency and canary on four always-on hooks, a deploy surface, and coupling to the sibling card that edits the script walk. |
| **A5** | **Re-home the per-rule domain test into each consumer.** | Fails the single-implementation requirement and gives a locator's false positives across the anchored rules of four hooks. |

For the allow-on-match exits, the raw-read alternative (read the un-canonicalized command) was rejected because it reintroduces a quoted-content refuse-to-allow the quote mask exists to prevent; and bringing the per-segment-closure card into this milestone was rejected under the Composition Lock. The masked exit view is the third path, lock-neutral and carrying no new refuse-to-allow.

For the assignment-anchored rules (decision 4), three alternatives kept the canonicalizer as it was and changed the rule instead: matching the assignment at any word start (a loose pattern as the deny authority, which ADR-187 rejected, and one that refuses an assignment-shaped argument of an ordinary command), giving the rule a private prefix walk (a further copy of the vocabulary and its grammar, ADR-187's four-point-fix alternative), and encoding the prefix run into the rule's own expression (a regex copy of the bounded enumeration, which cannot carry a wrapper's option arity). A fourth marked an assignment only when it follows a wrapper word, and left the assignment-led, redirect-led, keyword-led and group-led positions admitted: an instance closed, not the class. Marking every skipped assignment at the single source is the one that closes the class and adds no vocabulary.

## Reversibility

**MODERATE · Confidence HIGH.** Reverting is a revert of the card's commits plus a republish of the hook bundle, verified by hash. The widening and the exit view ship in one commit, so they revert together; the ordering constraint is that the exit-view read must never be reverted while the widened walk stays deployed. A revert re-opens a measured coverage gap across four security controls rather than returning to a neutral state, which is why it is MODERATE rather than CHEAP. Decision 4 reverts on its own: removing (e) returns the two assignment-anchored rules to the plain form only and leaves decisions 1 to 3 intact, because the exit view never carried it.

## Related ADRs

- **ADR-187** — command-start detection is a canonicalizer, not a parser; one shared implementation, insertion-only, quote-neutralized. This record widens its reach and narrows two of its stated properties, as § Consequences records.
- **ADR-226** — the egress prefix walk stops on the gated verb. A sibling walk with its own vocabulary, kept separate for measured reasons.
- **ADR-227** — the script-wrapper walk reads its option grammar from rows in getopt notation, asserted rather than shared. This record copies those rows into the canonicalizer under that precedent (#7 — copies asserted, never silently drifting).
- **ADR-181** — an ADR citation binds at the Stage-12 claim, not at authorship; this record's number is cited by slug token until then.

## References

- `#8314` — the canonicalizer card this record decides.
- `#8444` — the PATH-manipulation card whose route through the canonicalizer is decision 4.
- `#8122` — the per-segment closure of the deletion hook's two allow-on-match exits; its own card, not implemented here.
- `#8491` — the sibling card that changes the script walk's split-scan logic, whose logic has a twin in this walk that the row-parity arm does not guard (it guards the rows, not the walker).
