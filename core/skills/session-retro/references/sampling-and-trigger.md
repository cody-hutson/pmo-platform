---
title: Session Retro — Sampling Contract and Trigger Mechanism
purpose: Reference detail for the session-retro sampling threshold and its optional Stop-hook trigger — the operator.toml config surface, the fire/skip predicate, the once-per-session sentinel, and the activation boundary that keeps the shipped hook inert.
type: reference
status: ACTIVE
reversibility: CHEAP (config + skill) / MODERATE (hook activation) — Confidence HIGH / MEDIUM respectively
---
<!-- reference-durability: allow-link -->
# Session Retro — Sampling Contract and Trigger Mechanism (reference)

Two separable things live here. **Sampling** decides *whether a given session is worth reflecting on* — it binds the skill on every automatic invocation. **Triggering** decides *what invokes the skill* — a manual ask, or the optional `Stop` hook. The skill is fully functional with no hook installed; the hook only automates the timing.

## 1. Why sampling is load-bearing, not a nicety

The event log is append-only and permanent. A row emitted for a session that taught nothing can never be deleted — only redacted — and it permanently sits in the denominator of every cross-session read-model built on this surface. A retro that fires on every session degrades within a quarter into a session counter whose real patterns are buried under noise.

The operator's framing — "almost per session" — is therefore a **ceiling with a floor under it**, not "nearly always". The threshold is the control that keeps the surface worth reading. It is evaluated BEFORE reflection (SKILL.md Step 1 precedes Step 2 deliberately): reflecting first creates a sunk-cost pull toward emitting something.

## 2. Config surface — `operator.toml` `[session_retro]`

Operator-instance config (Layer 2), read by BOTH the hook (fire/skip) and the skill (emit/no-op). It mirrors the `[automation]` block's conventions: plain-language values, an inert default, and a warn-then-enforce posture.

| Key | Type | Default | Meaning |
|---|---|---|---|
| `enabled` | bool | `false` | ACTIVATION gate for the automatic trigger. `false` = the `Stop` hook is a no-op. **Manual invocation is unaffected at any value.** |
| `mode` | `"off"` / `"warn"` / `"enforce"` | `"warn"` | Hook posture. `off` = never fire. `warn` = evaluate the sampling predicate and record the verdict, but do NOT interrupt the session. `enforce` = actually re-enter the agent to run the retro. |
| `sample` | `"all"` / `"almost_all"` / `"significant_only"` | `"almost_all"` | Which sessions clear the threshold (§ 3). |
| `min_tool_calls` | int | `12` | Tool-call floor for the triviality predicate. |
| `min_turns` | int | `4` | Conversational-turn floor for the triviality predicate. |

An absent `[session_retro]` block resolves to these defaults, which means **an instance that has never heard of this feature runs no retro and is not interrupted**. That is deliberate: the inert default is the activation boundary (§ 5).

## 3. The sampling predicate

**Input source — where `tool_calls` and `turns` come from.** Both are derived from the **transcript** the `Stop` payload points at (`transcript_path`), not from payload counters. This binding is load-bearing: the payload carries a session identifier and a transcript pointer, and it has never carried `tool_call_count` or `turn_count`. A predicate written against those two invented fields read zero on every axis and therefore skipped every session at the shipped default — the hook could not fire under any setting. The pinned payload contract lives at `core/hooks/tests/fixtures/stop-payload.json`, and the hook's self-test asserts those two keys are **absent** as a negative control.

| Quantity | Derivation |
|---|---|
| `tool_calls` | count of `tool_use` content blocks in the transcript JSONL |
| `turns` | count of **distinct request identifiers** across the transcript — one API request is one assistant turn |

`turns` is deliberately **not** a count of assistant-role JSONL entries. The transcript records one entry per *content block* (thinking, text, tool use), so assistant entries run roughly three times the true turn count; counting them would make `min_turns` fire about three times earlier than the operator's setting reads. Both quantities are derived line-oriented, without a JSON parser, so a missing dependency cannot wedge a `Stop`.

**Fallback and fail-quiet.** If the transcript is absent, unreadable, or implausibly large, the hook falls back to a per-session `Stop` tally as the turn proxy, with `tool_calls` unknown (0). If the predicate then does not pass, the session **skips**. Unknown session size always resolves toward *skip*, never toward *fire* — a telemetry trigger must not fire on noise.

Given the session's observed `tool_calls` and `turns`:

| `sample` | Runs when | Reading |
|---|---|---|
| `all` | always | Every session, including trivial ones. Accepts the noise cost. |
| `almost_all` (default) | NOT (`tool_calls` < `min_tool_calls` AND `turns` < `min_turns`) | Skips only sessions that are trivial on BOTH axes — a long conversation with few tools still runs, and so does a short burst of heavy tool work. This is the operator's "almost per session". |
| `significant_only` | `tool_calls` >= `min_tool_calls` AND `turns` >= `min_turns` | Substantial sessions only. |

The predicate is deterministic and computed from session metadata alone — no content inspection, no model call. That is what makes it cheap enough to evaluate on a hook.

**Manual override.** An explicit operator ask ("run the session retro") runs the retro regardless of the predicate. The threshold governs automatic firing; it never overrides a direct instruction.

**A skip emits nothing.** Not a `no-learning` row — nothing. `no-learning` means "reflected, found nothing"; a skip means "did not reflect". Logging skips would re-create exactly the volume the threshold exists to suppress.

## 4. Trigger mechanism — why `Stop`, not `SessionEnd`

The load-bearing constraint: **a shell hook cannot make the agent reason.** The retro requires reflection over the session, which only the agent can do.

| Candidate | Verdict |
|---|---|
| `SessionEnd` | REJECTED — session-terminal and correct in principle, but it cannot re-enter the agent loop. It is a cleanup hook; it can run a script, not a reflection. Using it would force deferred reflection at the *next* session start, which needs catch-up machinery and reflects on a session whose context is gone. |
| **`Stop`** (selected) | A `Stop` hook can return `{"decision":"block","reason":"…"}`, which re-enters the agent — the only supported way to get a reflection at a session boundary. It also receives the session identifier and transcript pointer on stdin, so the triviality predicate is computable cheaply. |
| No hook (skill only) | Always available and always correct; simply not automatic. This is the floor the design keeps: the skill ships fully usable with the hook inert. |

**What a `Stop` hook can and cannot observe.** It **cannot** observe session-terminality. Every `Stop` is structurally identical, and the last one in a session is identifiable only in hindsight — by which time the session is gone. Any design that claims to fire "at the session boundary" from `Stop` alone is claiming an unobservable, and that is precisely how the code and this document could once agree with each other while agreeing with nothing that could actually happen.

So the fire point is stated explicitly rather than implied:

> **The hook fires at the FIRST `Stop` at which the session clears the sampling threshold** — a threshold *crossing*, not the last turn of the session.

This is the latest point that is both **observable** and **guaranteed to occur**. Waiting longer trades "fires early" for "may never fire", and never-firing is the defect this design closes. The honest tradeoff: under `almost_all` with the shipped floors, a session fires as soon as *either* axis clears, which is earlier than an ideal end-of-session retro. Moving the fire point later needs no new dial — raise `min_tool_calls` / `min_turns`, or select `significant_only` (§ 6 calibration).

**Per-turn re-evaluation.** Because `Stop` fires every assistant turn, the predicate is evaluated on **every** turn until it passes. A session that is trivial at turn 1 and substantial at turn 20 fires at turn 20. This is not an optimization detail — it is the correctness property. Evaluating once and remembering the answer would decide the predicate at turn 1, structurally the least substantive turn of any session, and freeze it there.

**The sentinel is written on the FIRE path only.** Without a guard, an activated hook would re-trigger the retro every turn — and the retro's own final turn would re-trigger it, an unbounded loop. The hook therefore writes a once-per-session **fire** sentinel keyed by session id (under the hook state directory, alongside the other hook-local state files) and exits immediately as a no-op when it already exists. Two rules make that guard correct rather than merely present:

- It is written **before** the block decision is emitted, so a retro that fails midway cannot loop.
- It is written **only when the hook fires**. A skip writes **nothing**, leaving the decision open for the next `Stop`. A guard written on the skip path is what froze the predicate at turn 1.

The guard carries exactly one meaning — *this session has fired*. It is not also the sampling memo. The harness additionally supplies its own re-entry flag (true precisely when the agent is continuing *because* a `Stop` hook blocked), which the hook honours as a second, independent guard; a hand-rolled substitute for it must never be overloaded with a second job.

**Fail-open, always.** Any error in the hook — unreadable config, missing state directory, malformed stdin — exits 0 with no decision. A telemetry trigger must never be able to wedge a session. There is no failure mode in which this hook blocks work.

## 5. The activation boundary (D2(a))

The hook **script** and its **settings-template registration** ship in the release. The hook **activation** does not, and this is a governance boundary rather than an implementation gap:

- `enabled = false` is the shipped default, so the hook is a no-op even where it is registered.
- `mode = "warn"` is the shipped default, so even after `enabled = true` the first posture observes and records without interrupting — the standard warn-mode-initial shakedown before flip-to-enforce.
- No live `.claude/settings.json` is modified by the release. The template is the seed for a fresh install; an existing instance is unaffected until the operator acts.

Turning the trigger on is therefore **three** deliberate operator steps — `enabled = true`, then an observation window, then `mode = "enforce"` — against an operator-instance file, each reversible in one line. Nothing in the release makes a session behave differently.

### 5.1 Activation conditions

These are the concrete preconditions the hook class requires before each step. They are stated here, at the capability, rather than in the class-level ADR, which delegates them.

**Before `enabled = true`:**

| Condition | Why |
|---|---|
| The sampling predicate reads a source the `Stop` payload actually carries | Otherwise the predicate reads zero on every axis and the hook can never fire |
| The predicate is re-evaluated every turn, and the guard is written on the fire path only | Otherwise the decision is frozen at turn 1 and the session can never become eligible |
| A guard test drives a real multi-`Stop` sequence and asserts a fire at a real threshold crossing | A test that drives the hook once, against a pure function, with a fixture built from the code's own premise cannot falsify that premise — which is how both defects survived |

**Before `mode = "enforce"`:**

| Condition | Why |
|---|---|
| Payload-label validation rejects unrecognized labels | An unrecognized label is swallowed into the preceding field and tokenized as signal |
| `no-learning` rows are excluded by enforcement, not convention | A mis-emitted row must not be able to contribute cluster signal |
| Operator-facing prose states the real fire point and the real activation steps | The docs must not claim an unobservable |
| **The verdict log holds at least one would-fire row** | This is the warn window, and it is checked by the hook itself |

The last one is enforced, not advisory: in `enforce` mode with an empty verdict log, the hook **degrades to warn** for that invocation and records a `warn-window-unsatisfied` verdict instead of interrupting. Degrading rather than refusing is deliberate — a refusal that emits nothing is observationally identical to the bug this design closes, whereas a degrade that records *why* is observable. The floor is stronger than it looks: the verdict log only accrues a row when the predicate **passes**, so one row proves an end-to-end path (activation → derivation → predicate → verdict) actually worked on a real session. It is a fixed internal floor, not a dial; the operator already controls the window's length by choosing when to flip the switch.

## 6. Calibration

`min_tool_calls = 12` / `min_turns = 4` are **initial values, not measured ones** — no session-size distribution has been collected, because this is the release that starts collecting it. Treat them as `[CALIBRATE-AFTER-3]`: after a warn-window of real sessions, compare the fire/skip verdicts the hook recorded against the operator's own read of which sessions were worth reflecting on, and tune. Emitting a precise-looking threshold as though it were measured would be exactly the synthesized-precision failure the platform's telemetry standards reject; it is declared here as a starting point instead.
