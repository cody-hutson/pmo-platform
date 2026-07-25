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

**The `Stop`-per-turn problem, and the sentinel.** `Stop` fires at every assistant-turn boundary, not once per session. Without a guard, an activated hook would re-trigger the retro on every turn — and, worse, the retro's own final turn would re-trigger it, which is an infinite loop. The hook therefore writes a once-per-session sentinel keyed by session id (under the hook state directory, alongside the other hook-local state files) and exits immediately as a no-op if the sentinel already exists. The sentinel is written BEFORE the block decision is emitted, so even a failure mid-retro cannot loop.

**Fail-open, always.** Any error in the hook — unreadable config, missing state directory, malformed stdin — exits 0 with no decision. A telemetry trigger must never be able to wedge a session. There is no failure mode in which this hook blocks work.

## 5. The activation boundary (D2(a))

The hook **script** and its **settings-template registration** ship in the release. The hook **activation** does not, and this is a governance boundary rather than an implementation gap:

- `enabled = false` is the shipped default, so the hook is a no-op even where it is registered.
- `mode = "warn"` is the shipped default, so even after `enabled = true` the first posture observes and records without interrupting — the standard warn-mode-initial shakedown before flip-to-enforce.
- No live `.claude/settings.json` is modified by the release. The template is the seed for a fresh install; an existing instance is unaffected until the operator acts.

Turning the trigger on is therefore two deliberate operator edits (`enabled = true`, then later `mode = "enforce"`) to an operator-instance file, each reversible in one line. Nothing in the release makes a session behave differently.

## 6. Calibration

`min_tool_calls = 12` / `min_turns = 4` are **initial values, not measured ones** — no session-size distribution has been collected, because this is the release that starts collecting it. Treat them as `[CALIBRATE-AFTER-3]`: after a warn-window of real sessions, compare the fire/skip verdicts the hook recorded against the operator's own read of which sessions were worth reflecting on, and tune. Emitting a precise-looking threshold as though it were measured would be exactly the synthesized-precision failure the platform's telemetry standards reject; it is declared here as a starting point instead.
