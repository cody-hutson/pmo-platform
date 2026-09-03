---
title: ADR-182 — Command-start position is resolved by a pre-match canonicalizer, not by a parser and not by a wider anchor
status: Proposed — flips to Accepted when the operator ratifies it at this release's Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-09-02
release: hooks-block-only-their-scope
deciders: "Workspace owner (ratified at the operator gate); the matcher-vs-parser evaluation was rendered at the Stage 5 solutioning gate and is recorded here at Stage 6 Engineering"
supersedes: none
tags: [architecture, security, hooks, command-position, lexical-matcher, canonicalization, blast-radius, false-positives, residual, fail-closed]
source_observations:
  - "Positional-axis differential re-measured at authoring, independently of the design comment it corroborates: 35 variants of one identical command against one identical absolute target, spread across the five miss families the originating card names plus the baseline family. Raw anchor 9/35; canonicalized 30/35; newly closed 21; regressed 0. Instrument: `/usr/bin/grep -E` with `ANCHOR_PREFIX_BASH` plus a bare deletion verb, and `/usr/bin/awk -f core/hooks/lib/command-position.awk`. The absolute-path invocation is deliberate — the local `grep` on the authoring host is ugrep, which can reject a pattern into a plausible zero."
  - "All three control arms were observed at authoring, not asserted. Sensitivity: the verb at start-of-line matches the raw anchor (True). Specificity: `echo hello world` matches neither raw nor canonicalized (False). Instrument-live: the canonicalizer returns text differing from its input on a prefixed payload (True), so a silently no-opping primitive could not have produced the differential. A first draft of the sensitivity arm used a prefix-word payload, which the RAW anchor is not supposed to match; it returned False and was corrected rather than reported."
  - "The 5 variants that remain unclosed at authoring are exactly the quoted-program-string family — `bash -c`, `sh -c`, `eval`, `alias`, and command substitution. That family is the `nested-shell` residual already carried in core/rules/bypass-mode-readiness.md with an explicit deferral decision, and `command-position.awk` names it in its own header under the heading for what it deliberately does not close. The residual is therefore pre-existing and re-stated here, not introduced."
  - "The four consuming hooks do not share one enforcement posture, which is why the blast radius had to be reasoned per consumer rather than once. Read from the sources at authoring: `block-destructive.sh` and `block-rm-prefer-trash.sh` each carry an explicit MODE-INDEPENDENT comment stating the hook declares no `MODE_FILE` and reads no mode file of any name; `block-egress.sh` and `block-fs-boundary.sh` each declare `readonly MODE_FILE=\"${HOOK_DIR}/.mode\"` and resolve it through a `get_mode()` whose unrecognized-value branch defaults to enforce."
  - "The false-positive axis was measured at authoring as a canonicalizer-boundary differential over a corpus of legitimate non-destructive payloads, including the variable-bearing operand shapes that the companion re-scope in this same release moves from refused to allowed. Newly blocked: 0. The arming sentinel fired in the same run, so the zero is a measured zero rather than an instrument that never engaged."
  - "The false-positive concern is not hypothetical for this cohort: quote-neutralization is what makes ordinary shapes such as a cleanup function echoed into a script file, a `sed` program containing a verb, and a `grep -E` alternation containing a verb resolve to allow. Two of those three shapes were refused BEFORE the canonicalization landed."
---
<!-- reference-durability: allow-link -->

# ADR-182 — Command-start position is resolved by a pre-match canonicalizer, not by a parser and not by a wider anchor

## Status

**Proposed.** Ratification flips this field at this release's Stage 9 Plan Review gate.

**Numbering provenance.** The number was READ from the allocation oracle at authoring, never reserved. The allocator reported an anchor on the mainline and the next free slot above it, and that slot is the one taken here. A set of branch-only claims on the same slot was reported alongside, labelled by the tool itself as detection-only; those claims are not consulted, because the next free number is `anchor + 1` and never `max(claimed) + 1`. Stepping past the allocator's answer to dodge a branch claim would land a **gap**, and the numbering integrity check fails a gap as readily as a duplicate. The claim binds at merge per ADR-115; if a sibling branch merges the same slot first, the merge-time renumber moves this record and writes its own provenance note. That is the governed mechanism operating correctly, not a defect.

**Numbering provenance — `177 → 182`.** Held **ADR-177** branch-local; renumbered to **ADR-182** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 177. In-release citations that read "ADR-177" denote this record.

## Context

Four PreToolUse security hooks — `block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh`, `block-rm-prefer-trash.sh` — shared one byte-identical anchor for recognising the start of a command in shell text:

```
ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'
```

That anchor is **positional**. It recognises a command start at exactly two places: start-of-line, and immediately after `;`, `&` or `|`. A shell starts a command in many more positions than that. Grouping constructs, compound-command keywords, command-prefix words, `VAR=value` assignment prefixes, leading redirects and an escaped verb are all genuine command starts the anchor cannot see.

The consequence is the defect that motivated this record: **the verdict tracked lexical position rather than the action.** One identical command with one identical absolute target changed verdict depending on where it sat in the line. Wrapping it in a function body was sufficient to make it invisible, and nothing reported the skip. Because every one of the four hooks read the same anchor, all four inherited the same blind spot, and a fix applied to one of them would have closed instances while the generator persisted.

Two forces shaped the response rather than one.

**A lexical matcher over shell text has a coverage boundary by construction.** It approximates a grammar it does not parse. Widening it moves the boundary; it does not remove it. So the honest question was never "how do we make this complete" but "which boundary do we want, at what cost to a set of always-on security controls".

**False positives are the failure mode that actually matters here.** A guard that fires on ordinary work gets disabled by the operator, which is a worse security outcome than the gap it closed. Writing shell text as *content* — a cleanup function echoed into a script file, a `sed` program containing a verb, an alternation in a `grep -E` pattern — is routine in this repository. Any widening that treats such content as a command start is not a hardening; it is an outage with a security label on it.

## Decision

**Command-start detection across the four regex-anchored PreToolUse hooks is resolved by pre-match canonicalization of the input — not by a shell-grammar parser, and not by widening the anchor.**

`ANCHOR_PREFIX_BASH` is left byte-identical. One shared primitive, `core/hooks/lib/command-position.awk`, runs first and rewrites positions that ARE genuine command starts into positions the existing anchor already recognises, by inserting a separator in front of them. Rule patterns, rule IDs, block messages and the per-hook token extractors are untouched.

It ships as **one implementation the four hooks consume**, not as four copies that agree today. The shared primitive is the decision's structural half: four agreeing copies is precisely how this cohort drifted into a common blind spot, and a shared surface is what keeps a future fix from having to be applied four times and being applied three.

Two properties are what make the widening false-positive-safe rather than merely broader, and they are load-bearing rather than incidental:

1. **Insertion-only on the syntactic axis.** The canonicalizer does not delete, reorder or rewrite command text — the single exception is dropping one leading backslash at the verb position, so an escaped verb reads as the verb for both the regex and the token extractor. Anything the anchor matched before still matches. The change is additive, so no pre-existing coverage can be lost by construction rather than by test.
2. **Quote-neutralized command-start detection.** Structural characters inside a quoted span cannot open a segment, so shell text carried as *content* is not a command start and receives no insertion. This is the property that makes the ordinary shapes above resolve to allow — and two of the three measured shapes were refused *before* this change, so neutralization is what fixed them rather than what preserved them.

The command-prefix word set is a **bounded enumeration, never a wildcard**. An unlisted leading word is treated as the command, exactly as before.

## Alternatives Considered

Four options were weighed. The selected one is A3.

| # | Alternative | Why rejected |
|---|---|---|
| **A1** | **Parse-based decision** — a real shell grammar consumed by all four hooks. | Trades one coverage boundary for another while adding materially more surface to four always-on security controls. A parser's failure modes are *less* characterized than the matcher's, not more: divergence from the real shell's grammar, evaluation cost on every Bash tool call, and a new dependency inside a PreToolUse path that is required to fail closed. The originating card's own risk register states the principle — a parser is not automatically safer than a matcher — and asks for the comparison to be measured rather than assumed. **Deferred, not refuted:** see the note below. |
| **A2** | **Widen the anchor regex itself.** | Measured wrong in the originating design's first draft, and the measurement is the reason this row exists. The regex gates *before* the tokenizer, so widening the tokenizer alone closes only a fraction of the positions; and widening the regex makes a loose pattern the deny authority, which is the mechanism by which false positives enter. The design that works keeps a loose presence pre-filter with the tokenizer as sole deny-authority — the inverse of this option. |
| **A3** | **Pre-match canonicalization.** **SELECTED.** | Additive on the syntactic axis and quote-neutralized, so it is false-positive-safe by construction on both axes rather than by calibration. It leaves the anchor, the rule patterns, the rule IDs and the block messages untouched, which bounds what a regression can reach. It is the only option of the four that widens coverage without moving deny authority into a looser surface. |
| **A4** | **Four per-hook point fixes.** | Four agreeing copies is exactly how this cohort acquired a common blind spot. It closes instances while the generator persists, and each partial fix makes the family look more protected than it is — the failure the originating card names directly. It also fails the card's own stated requirement of one implementation for the four consumers. |

**A1 remains the only path to the residual, so it is deferred rather than refuted.** The quoted-program-string family — a program string handed to another shell, and command substitution — cannot be closed by any lexical implementation, because the inner text is a program for a different shell rather than for this one. Nothing in this record forecloses a parser later; what it records is that a parser was not the right instrument for *this* coverage class, at *this* blast radius, on *this* evidence.

## Consequences

### Blast radius, per consumer

The four hooks do not share one enforcement posture, so the radius has to be reasoned four times rather than once. This is the part a reviewer must be able to check.

| Hook | Enforcement posture | Blast radius under canonicalization |
|---|---|---|
| `block-destructive.sh` | **Always-enforce, mode-independent.** The file states in as many words that it declares no `MODE_FILE` and reads no mode file of any name. | The largest rule set of the four. The canonicalized input feeds the rules anchored on `ANCHOR_PREFIX_BASH`. `ANCHOR_PREFIX_GIT` is a **word-boundary** anchor rather than a positional one and was never blind in this way; it is monotonically safe here, because the only characters the canonicalizer inserts are a separator and a non-alphanumeric sentinel, both already members of the boundary class — so canonicalization can *add* a word boundary for the git rules and can never remove one. |
| `block-rm-prefer-trash.sh` | **Always-enforce, mode-independent.** Same explicit declaration. | The verb regex **and** the target-token extractor both read the canonicalized form. They are atomically coupled by necessity: canonicalizing only one of them would either fire the gate and then extract nothing, or leave the regex gating on the raw text and render the change inert. |
| `block-egress.sh` | **Mode-capable.** Declares a `MODE_FILE` and resolves it through a `get_mode()` that defaults to enforce on an unrecognized value. | Same anchor path for its command-anchored rules. Its own quoted-argument neutralizer for the credential-exfiltration rule is deliberately *not* routed through the shared primitive: that path parses argument text, which canonicalization is not for. |
| `block-fs-boundary.sh` | **Mode-capable.** Same declaration and the same enforce-defaulting resolution. | Same anchor path. This is also the hook whose false-positive surface the companion re-scope in this release changes, which is why the false-positive control arm for this decision is graded after that change lands rather than before it. |

### Fail direction

Each hook canaries the primitive before trusting its output. The reason is specific and is the sharp end of this design: a truncated or corrupt copy of the primitive emits an **empty string**, which would take the hook's whole matcher with it — a fail-**open** strictly worse than the gap being closed.

On canary failure the two always-enforce hooks DENY through the shared missing-primitive helper. The two mode-capable hooks deny in enforce mode and degrade to the raw command in warn mode — which is exactly their pre-canonicalization behaviour, so warn loses no coverage it already had. Unbalanced quotes make the internal mask unreliable, so the input is handed back byte-identical for the same reason: the consuming hook then behaves exactly as it did before, rather than acting on a mask that might be inverted.

### The bounded scope — three explicit non-claims

These are the point of the record, not a disclaimer attached to it. A decision record that overstates its coverage is worse than no record, because it converts an unmeasured area into a documented assurance and the next reader stops looking.

**1. This record does not claim coverage over `BLOCK-DESTRUCTIVE-022`.** That rule sits outside the scope of this decision. `core/hooks/block-destructive.sh` states the exclusion at its primitive declaration, verbatim:

```
BLOCK-DESTRUCTIVE-022 is deliberately NOT routed through this: its segment loop and
cumulative quote-parity tracking read "$COMMAND" directly and own their own lexical
model. Canonicalizing its input would pre-empt the parity machinery that catches a
script path carried inside a quoted program string.
```

The consequence for planning is the one that matters: work items describing that rule's behaviour arise from a **separate generator** and must not be sequenced behind this decision. Treating them as downstream of this record would idle work that can proceed independently.

**2. This is not class closure.** A lexical canonicalizer approximates a grammar it does not parse, and the residual is enumerated rather than gestured at: the quoted-program-string family (a program string handed to another shell, and command substitution), rule-local terminator classes, other deletion mechanisms such as a find-and-execute or find-and-delete invocation, and heredoc bodies. Every extension buys a bounded set of positions; none buys completeness. The systemic-hardening intent this record serves is **not** retired by it.

**3. The prefix-word set is a bounded enumeration, never a wildcard.** An unlisted leading word is treated as the command, exactly as before. The direction of that failure is the safe one and is worth stating explicitly: an omission from the set leaves an invocation un-adjudicated, which is the status quo, and can never admit an evasion that the pre-change hook would have caught.

### What the measured figure does and does not mean

The differential in `source_observations` measures the **positional axis in isolation** — the shared anchor plus a bare deletion verb. It is not a hook-level guarantee. Each rule adds its own terminator class on top of position, so a per-rule figure for the same variant set is lower than the positional figure and differs between rules. A reader who takes the positional number as an end-to-end coverage claim will overestimate what any one rule sees. The axis is stated here so that reading is not available.

### Consequences that are costs

Canonicalization introduces a per-invocation `awk` process into four always-on PreToolUse paths, and a shared primitive whose corruption is a single point of failure for four security controls — which is why the canary exists and why its fail direction is specified above rather than left to the implementation. It also creates a surface that must be reasoned about jointly: a future change to the primitive reaches four hooks with two different enforcement postures, so its blast radius is never local.

## Reversibility

**CHEAP · Confidence HIGH.** This record documents a decision whose implementation had already shipped when the record was written; the record itself adds no runtime behaviour. Reverting the *record* is one commit and changes nothing that executes.

Reverting the *decision* is a distinct and larger question, and stating the difference is the honest part: the canonicalizer is consumed by four security controls, so removing it would restore a measured coverage gap across all four at once. That reversal is **MODERATE · Confidence HIGH** — mechanically a revert, but it re-opens a known defect rather than returning to a neutral state, so the realistic path away from this decision is a successor record selecting A1, not a rollback.

## Related ADRs

- **ADR-115** — an ADR number is allocated at authorship and bound at merge; only the mainline binds. This record follows that discipline for its own number, as its Status section records.
- **ADR-130** — the dependency-helper guard is mode-coupled for the mode-capable cohort while the always-enforce floor stays unconditional. That split is the basis on which the two mode-capable consumers above are permitted to degrade in warn mode where the two always-enforce consumers must deny; the fail direction recorded here applies the same asymmetry to the canonicalizer canary.
- **ADR-005** — append-pattern-aware contention scoring. The shared primitive this record selects is a single-writer surface rather than an append-pattern one, which is why a change to it is a coordination event across four consumers and not an independent edit.
