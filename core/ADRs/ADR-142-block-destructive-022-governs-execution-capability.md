<!-- reference-durability: allow-link -->
---
title: "ADR-142 — BLOCK-DESTRUCTIVE-022 governs execution capability, and its widened arm graduates on a repo-derivable deadline"
status: Accepted
date: 2026-08-24
release: hooks-block-their-declared-subject
deciders: "operator (D-ScriptScope verdict + Collective Review scope-lock) + Stage 5 Solutioning spoke (design, measurement) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [block-destructive, script-execution-allowlist, progressive-rollout, warn-mode, drain, graduation-criterion, deploy-check, posix-shell-grammar, security-control-scope]
source_observations:
  - "The bypass was reproduced with a live sensitivity control, not cited: `bash /tmp/<script>.sh` returns exit 2 with BLOCK-DESTRUCTIVE-022 naming the path, and the SAME script by direct execution returns exit 0 with no rule firing and no drain row. Same session, same allowlist state; the only difference is the interpreter token."
  - "The rule's own block message reads 'Red Team C1 — script-laundering mitigation', and the laundering route it did not adjudicate is: make the file executable, drop the interpreter word."
  - "BLOCK-DESTRUCTIVE-022 is the second-highest-firing rule in the hook layer at 436 blocks, 28.0% of 1,556 over 2026-06-26 to 08-23, and it had no drain of any kind."
  - "The blocker was NOT the `*) continue` fallthrough in the verb case. Two arity guards rejected a bare `./x.sh` before the verb was ever resolved: one required >= 2 tokens, the other an operand after the verb. Neither is a property of the rule — both are the interpreter and source arms' operand arity, hoisted above the point where the arm is decided."
  - "The marginal allowlist cost for registered tooling is approximately zero, which falsifies the cost premise in the originating card. Pinned counting rule: 257 non-comment pattern lines reduce to 63 distinct tool identities after stripping one registered form prefix; 63 of 63 already match at least one direct-execution spelling, 0 do not. Controls: `./core/deploy/deploy.sh` matches, `/tmp/zzz-not-a-real-tool.sh` does not."
  - "Two denominators were in circulation for the same file (63 tools and 61 tools) and the delta is fully attributable to the reduction, not to the data: exactly two basename collisions, `*.test.sh` and `test-runner.sh`, each registered at both the deployed layout (.claude/hooks/tests/) and the source layout (core/hooks/tests/). A path reduction keeps them distinct; a basename reduction folds each pair into one."
  - "The operand-filter choice was decided by measurement over the documented-command corpus: the suffix filter and the source arm's wider filter find the SAME 15 real tokens, but the wider one adds 10 regex/awk-fragment false positives plus 1 unresolvable hard-block, and buys only extensionless-executable coverage — of which the repo has 0 of 181 exec-bit tracked files."
  - "BLOCK-EGRESS-007 already phases a widened surface through EGRESS_007_WIDENING_PHASE, and its drain holds 2 rows in total, one of them written by the hub during this release's own Stage 4. A rollout that accumulates no traffic can never graduate on evidence, and nothing surfaces the stall."
  - "The flip register states the structural cause outright: the shakedown-drain signal is 'git-ignored and absent in a fresh checkout / CI, so it is not readable by a pull-request agent'. Every row in that register reads DEFERRED."
  - "block-fs-boundary.sh:53 and block-shell-injection.sh:53 each DECLARE a WARN_LOG whose write is gated on the shared .mode, which is never in the writing position — so those drains are declared-but-dead and indistinguishable from absent. block-destructive.sh declared none at all."
  - "The false-positive surface of this rule family is shape-not-effect, measured on five independent firings during this release alone: `bash -n <path>` is blocked although -n is POSIX-defined as read-but-do-not-execute; an existing in-repo test suite was blocked while only being verified; BLOCK-SHELL-INJECTION-002 blocked a markdown table row carrying a backticked .sh path; a JSON payload argument carrying force-push TEXT tripped BLOCK-DESTRUCTIVE-001; and 3 of 5 control firings on the sibling slice were -022 itself."
---

# ADR-142 — BLOCK-DESTRUCTIVE-022 governs execution capability

## Status

**Accepted.** Authored at Engineering for the `hooks-block-their-declared-subject` release, against the operator's rendered D-ScriptScope verdict and the Collective Review scope-lock that added the enforcement surface.

**Composes with:** [ADR-130](ADR-130-lib-missing-guard-is-mode-coupled.md) (this hook's mode-independence is the basis on which the mode-capable cohort was permitted to degrade, and this record does not disturb it) and the progressive-rollout convention (which owns the ladder; this record adds a forcing function to it, not a new ladder).

## Context

`BLOCK-DESTRUCTIVE-022` describes itself as guarding *"Bash subprocess script execution not in `.claude/script-execution-allowlist.txt`"*, and its block message names *"Red Team C1 — script-laundering mitigation"*. It matched only invocations carrying a `bash`, `sh`, `zsh`, `source` or `.` token at command position.

Direct execution — `./x.sh`, the ordinary way to run an executable script — carries no such token. It was matched by no rule in any hook. The allowlist was therefore bypassable with no quoting trick, no variable, and no separator game: make the file executable and drop the interpreter word.

That is a control whose stated scope exceeded its enforced scope, inside a milestone convened to close exactly that class. **The question it raised is not a defect report with an obvious patch — it is a scope question**, and the two answers have genuinely different costs. Narrowing the claim is free and leaves the rule's own name and message over-claiming. Widening the enforcement is correct and lands on a rule already responsible for 28% of the layer's blocks, with no measurement surface of any kind.

Two further facts shaped the answer rather than merely decorating it.

**The mechanism hiding direct execution was not where it appeared to be.** The verb `case` ends in `*) continue`, which reads like the whole story. It is not: a bare `./x.sh` is one token, and two arity guards rejected it *before* the verb was resolved. Neither guard expresses anything about the rule — both are the interpreter and source arms' operand arity applied ahead of the point where the arm is chosen. Any fix that only touched the `case` would have changed nothing.

**The obvious rollout mechanism has an in-repo counterexample.** `BLOCK-EGRESS-007` already phases a widened surface behind a per-rule constant and a drain. That drain holds two rows in total. It cannot graduate on evidence, and nothing anywhere reports that it has stalled — the pipeline stays green while the control silently permits. The flip register names the cause plainly: the drain is git-ignored and absent in CI, so no pull-request agent can read it. Copying `-007`'s mechanism without adding something would have reproduced `-007`'s outcome.

## Decision

**The script-execution allowlist governs EXECUTION CAPABILITY, not interpreter invocations only.** Direct execution is in scope. The rollout of that widening is phased; the scope change is not.

Five parts, each of which a future editor could plausibly undo without this record:

1. **A third arm (`exec`) whose trigger is the shell's own discriminator.** POSIX Shell Command Language § 2.9.1.1: a command name containing at least one slash is used directly as a pathname, otherwise the shell performs a `PATH` search. The slash *is* the execute-this-file test. It is the last branch of the existing verb `case`, so `/bin/bash` and `/bin/.` keep resolving to their own arms, and every `PATH`-resolved utility is excluded by construction rather than by enumeration.

2. **Operand filter `*.sh|*.bash`, written as a separate `case`.** Not a reuse, widening, or narrowing of either shipped arm's expression.

3. **The arity guards are reordered, not deleted.** Walk command position → resolve the verb → apply per-arm arity.

4. **Phase-gated at `warn` behind a per-rule three-value constant** (`shadow` | `warn` | `enforce`), writing every would-fire to `destructive-warn-log.jsonl` — this hook's first drain — with the write gated on that constant **alone**, never on a mode dial.

5. **A graduation criterion split by readability, enforced by `deploy.sh` Check 71.** The evidence arm — the `DESTRUCTIVE_022_EXEC_REVIEW_ROWS` threshold, declared in the hook — reads the git-ignored drain and can trigger nothing. The deadline arm (armed 2026-08-24, review at 60 days, escalation at 90) reads a committed constant and today's date, is repo-derivable, and carries the teeth: at 90 days with the phase unchanged, Check 71 increments `ISSUES` and `--check --strict` exits 1.

## Consequences

**The generalizable pattern, and the reason this record exists at all: make the forcing function repo-derivable and let the evidence stay operator-local.** A gate whose advance depends on a git-ignored drain can never be advanced by anything in the pipeline. A gate whose *deadline* depends only on a committed constant can force the decision that reads the drain. That asymmetry is the whole graduation design, and the next rule that needs a drain should inherit it rather than rediscover `-007`'s stall.

**Doing nothing becomes the one unavailable option.** Every way of turning Check 71 green is a recorded decision — advance the phase, retreat it, or re-date the arming constant — and the edited line is itself the audit record.

**A zero drain is a finding.** Zero rows classifies as INSTRUMENTATION-SUSPECT, not "no evidence yet", and sends the reader to the must-flag control to distinguish a quiet surface from a disconnected one.

**The rule is no longer uniformly always-enforce, and documents that said so were corrected.** The hook still reads no mode file; one *arm* of one rule is phase-gated. A "block-destructive exercised without false positives" checkbox can no longer be ticked for the rule as a whole from a run in which one arm cannot produce a block.

**Check 71 is the first mechanism in the platform that can detect a stalled rollout**, and it does so without depending on the signal the flip register identifies as its own blocker.

**One named residual, inherited rather than introduced.** An extensionless target escapes every arm: `./x` on the exec arm and `bash /tmp/evil` on the interpreter arm, for the same suffix-anchoring reason. It is one residual across three arms, recorded once and pinned by test so that widening any arm to cover it is deliberate.

**The stated cost premise was falsified, and the direction matters.** The originating card predicted that "every hook, deploy script, and test helper" would need an allowlist entry. Under the pinned counting rule, 63 of 63 registered tool identities already match a direct-execution spelling. The marginal cost is small, and the false-positive surface under the chosen filter is *narrower* than the interpreter arm's, not wider.

## Alternatives rejected

Recorded because each is the intuitive choice, and a future editor who meets one without this record will read the shipped answer as an oversight.

| # | Rejected | Why, on measurement |
|---|---|---|
| A1 | **Interpreter-only scope** (narrow the claim instead of widening the enforcement) | Leaves the rule's own name and message — *"Red Team C1 — script-laundering mitigation"* — claiming coverage of a laundering route it does not adjudicate. That is this milestone's subject restated inside the milestone. |
| A2 | **Reuse the `source` arm's operand filter** (`/*\|./*\|../*\|~/*\|*.sh\|*.bash`) — the obvious "we already have a filter" move | Identical true-positive set (15 real tokens) and strictly worse elsewhere: +10 regex/awk-fragment false positives, +1 unresolvable hard-block. It buys only extensionless coverage, and the repo has 0 of 181 exec-bit tracked files without a recognised suffix. It would also leave the exec arm **wider than the interpreter arm** — a fresh asymmetry between arms of one rule, the mirror image of the defect the sibling slice removed. **This is the specific edit this table exists to prevent.** |
| A3 | **No operand filter** (adjudicate every slash-bearing command word) | +62 false positives and 27 unresolvable hard-blocks on the same corpus, against the same 15 true positives. The unresolvable class has no allowlist remedy, so it converts false positives into unfixable ones. |
| A4 | **Unify the three operand filters into one expression** | Forbidden in both directions by the shipped comment on the source arm, for reasons that still hold: narrowing drops `/*`, `~/*` and `*.bash`; widening opens a false-positive surface with no defect behind it. Three separate `case` expressions mean an edit to one cannot silently retarget another. |
| A5 | **Enforce immediately** | Skips the card's own AC-3 precondition (assess the false-positive surface *before* rollout) on the layer's second-highest-firing rule, which had no measurement surface at all. Five shape-not-effect false positives were observed in this release alone. |
| A6 | **Gate the arm on the shared `.claude/hooks/.mode`** | The dial is a cohort instrument: flipping it to tune one arm of one rule would simultaneously soften seven unrelated hooks. This hook's mode-independence is also the basis on which that cohort was permitted to degrade. |
| A7 | **A boolean rollout flag instead of a three-value enum** | A boolean offers on and off. The enum offers a rung *below* `warn` — keep measuring, stop emitting — so a noisy warn phase does not force a choice between notice spam and going blind. Retreat must be as cheap as advance. |
| A8 | **A row-count graduation criterion alone** (the `-007` shape) | Unevaluable by anything in the pipeline: the register states the drain is git-ignored and absent in CI. `-007`'s two rows are the demonstration. A criterion nothing can read forces nothing. |
| A9 | **Record the criterion in the registry entry and stop** (no `deploy.sh` check) | A registry entry is read by people who already remembered to look. It cannot distinguish a rollout that is progressing from one that has stalled, which is precisely the state `-007` has been in. |
| A10 | **Route both existing arms through the new verdict wrapper** for symmetry | The binding constraint was byte-preservation of the two shipped arms. An indirection whose `widening=0` branch only delegates buys symmetry of appearance and spends it on editing call sites that had no reason to change. The exec arm delegates to the shared adjudicator at `enforce` instead, so both block messages keep exactly one definition. |

## Reversibility

**MODERATE · confidence MEDIUM.** Retreating the rollout is a one-line phase edit and is CHEAP. The semantic scope change is the part that is not: reversing it later means re-adjudicating every allowlist row written under the new reading. The D-Gate tiered it MODERATE for that reason and this record does not soften it.
