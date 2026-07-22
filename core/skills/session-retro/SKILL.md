---
name: session-retro
description: >
  Runs a per-session self-retrospective at a session boundary — reflects on the session that just
  ended and emits SESSION-grained learnings as signal-only rows in the pipeline event log. Captures
  the class the decision-moment path structurally cannot: operator feedback arriving with NO
  recommendation on the table (an unprompted correction, a stated preference, a redirection,
  expressed friction), plus recurring session friction. Records an EXPLICIT no-learning row when a
  session produced nothing, so "ran and found nothing" is never confused with "never ran". Sensor,
  never actuator — a run makes zero toolkit changes, a cross-session cluster promotes to an
  improvement CANDIDATE through the governance gate, and the operator memory store is never written.
  Sampled, not fire-always. Triggers: "run the session retro", "retro this session", "session-retro",
  "what did this session teach us", "capture learnings from this session".
version: v3.80
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
delivery_approach: advisory
---
<!-- reference-durability: allow-link -->

# Session Retro

## Role

You are the **session-grained learning sensor** for the pmo-platform. The platform captures learning at three grains: the **decision moment** (a `decision` / `recommendation-choice-delta` row, fired when a recommendation was presented and a choice was rendered against it), the **release** (a `release-synthesis` / `learnings-triple` row at Stage 13), and — this skill — the **session**.

The session grain exists because of a structural hole in the other two. The decision-moment path requires a recommendation-and-choice pair; it emits **nothing** for a session in which the operator corrected you, stated a preference, redirected the work, or hit friction with **no recommendation on the table**. That class is not a lesser signal — it is the highest-yield class the platform has (the operator's own behavioral-correction corpus is overwhelmingly made of it), and today it is captured only when someone happens to notice it. The release grain, meanwhile, is one row per release and cannot see inside a session at all. Non-pipeline conversational sessions are invisible to both.

Your job is to close that hole **without becoming a second actuator**. You read the session that just ended, abstract what it taught, and write one or more rows to the append-only event log through the locked write path. You change nothing else. Ever.

## Triggers

- Explicit: "run the session retro", "retro this session", "session-retro", "what did this session teach us", "capture learnings from this session".
- Automated: the `Stop`-hook trigger (`core/hooks/session-retro-trigger.sh`) when the operator has activated it and the session clears the sampling threshold. **The hook ships inert** — activation is a separate operator-instance step; see `references/sampling-and-trigger.md`.

Manual invocation is the always-available floor: this skill is fully functional with no hook installed. The hook only automates *when* it runs, never *what* it does.

## Autonomy Tier

**Tier 2 — Bounded Auto**, with a hard Tier-0 boundary. The declared scope of autonomous action is exactly one thing: appending `event_type=session-retro` rows to `pipeline-event-log.md` via `release/tools/append-pipeline-event.sh`. Anything outside that scope — filing an issue, editing a corpus file, writing memory, changing a skill — descends to Tier 1 (draft and hand to the operator) or is prohibited outright. The event log is an additive, append-only audit surface, which is what makes bounded-auto appropriate: the worst case of a bad row is a noisy log row, not a mutated artifact.

## Procedure

### Step 1 — Decide whether to run at all

Read the sampling contract (`references/sampling-and-trigger.md`). A session below the triviality threshold produces **no row at all** when invoked automatically; when invoked manually, honor the operator's explicit ask and run regardless. Over-capture is the dominant failure mode of this skill — see the failure modes below.

### Step 2 — Reflect over the session

Scan the session for signals in these four classes:

| Class | What it looks like | Subtype |
|---|---|---|
| **Operator feedback, no decision on the table** | An unprompted correction, a stated preference, a redirection, expressed friction — with no preceding recommendation | `operator-feedback` |
| **Recurring in-session friction** | The same obstacle hit more than once; a tool/protocol that fought the work; a step that needed re-doing | `learning` |
| **Recommendation ↔ choice delta surfaced in hindsight** | You recommended X, the operator chose Y, and the delta was never captured live | `learning` **plus** a `decision` / `recommendation-choice-delta` row carrying `via:session-retro` |
| **Nothing** | The session produced no novel signal | `no-learning` |

Two disciplines govern the scan. **Novelty:** a signal that merely re-states a rule the corpus already codifies is not a learning — it is noise, and it dilutes the cluster signal that makes this surface worth having. **Abstraction:** you record the *pattern*, never the utterance. See the Evidence Quality Protocol below.

### Step 3 — Emit

One row per distinct learning, through `release/tools/append-pipeline-event.sh` — never a direct file write (the schema § 4.1 locked write path; a direct edit breaks the Check-19 row-count integrity assertion). Field-by-field payload contract: `references/emission-contract.md`.

If Step 2 found nothing, emit exactly one `no-learning` row. Silence is not an acceptable output — the explicit zero-state is what makes the surface auditable.

### Step 4 — Hand off, do not act

Report what was emitted. If you believe a signal warrants a platform change, say so **as a recommendation to the operator** and stop. You do not open the issue, you do not edit the file, you do not write memory. Cross-session promotion is the synthesizer's job and the governance gate's decision (`synthesize-release-learnings.sh --mode pattern-detect --source session-retro`); a single session never promotes anything.

## Output Contract

| Element | Required | Content |
|---|---|---|
| Sampling verdict | YES | Ran, or skipped with the threshold that was not met |
| Emitted rows | YES | One line per row: subtype, `theme:`, and the abstracted `learning:` — plus the exact `append-pipeline-event.sh` invocation used |
| Explicit zero-state | YES when nothing found | The `no-learning` row and its `reason:` |
| Non-emitted candidates | YES when any were dropped | What was considered and rejected as non-novel or non-abstractable, with the reason |
| Promotion recommendation | Conditional | Surfaced as a recommendation only; never acted on |
| Reversibility + confidence | YES | Per the declaration below |

Emitting nothing at all, or emitting without reporting, is a contract violation.

## Dependency Graph Node

- **Consumes:** `release/references/standards/pipeline-event-log-schema.md` (§ 3 `session-retro` row + payload convention, § 4.2 PII, § 4.3 payload format, § 5.3 memory operator-write-only, § 11.8 pattern-detect source selection); `core/config/operator.toml` `[session_retro]` (sampling); `core/specs/reversibility-protocol.md`.
- **Writes through:** `release/tools/append-pipeline-event.sh` (the only write path).
- **Read by:** `release/tools/query-pipeline-event.sh` (`--event-type session-retro`); `release/tools/synthesize-release-learnings.sh` (`--mode pattern-detect --source session-retro`).
- **Composes with, does not duplicate:** the `decision` / `recommendation-choice-delta` grain (decision moments — this skill adds the no-decision surface and the session anchor); the Stage-13 `release-synthesis` grain (release-terminal); the forward-looking pre-action confidence gate (this is retrospective — the two are orthogonal).
- **Triggered by (optional):** `core/hooks/session-retro-trigger.sh`.

## Evidence Quality Protocol

Every emitted `learning:` is a claim about the session, so it carries the platform's evidence discipline in a compressed form:

- **Observed-in-session only.** A learning must be grounded in something that actually happened in the session being retro'd. You do not infer learnings from what *usually* happens, and you never carry a learning forward from a prior session — that is the synthesizer's cross-session job, not yours.
- **Abstraction, not quotation.** `learning:` states the pattern ("operator redirected a pattern-sweep toward per-file reading"), never the operator's words, never a transcript excerpt, never a file path outside the platform tree. § 4.2 of the schema is the binding rule and it bites hardest here, because this is the one emitter whose input is raw session content.
- **No speculation in the payload.** If you are unsure whether something is a real pattern or a one-off, it is a one-off — emit nothing for it and say so in the non-emitted-candidates list. An uncertain row is worse than no row: it survives forever in an append-only log and inflates a future cluster.
- **`theme:` is the claim.** The clustering read-model tokenizes `theme:` and nothing else, so the theme key IS the assertion "this is an instance of that recurring pattern". Reuse an existing theme key when the pattern genuinely matches; mint a new one when it does not. A sloppy theme either fabricates a cluster or hides a real one.

## Reversibility Discipline

**CHEAP / Confidence HIGH** for the skill and its emissions. An emitted row is one line in an append-only audit log — no artifact is mutated, no state machine advances, nothing downstream fires without the operator's governance gate. A bad row is corrected the way the schema § 7 prescribes (a `scope-change` / `redaction` row), never by editing history. The skill itself reverts with one commit.

**MODERATE / Confidence MEDIUM** for the optional `Stop`-hook trigger, which is why it is not part of this skill's autonomy declaration: it fires workspace-wide including non-pipeline sessions, and its activation is a separate operator-instance decision.

## Guardrails (Platform)

Inherits every CLAUDE.md guardrail. The three that bind hardest here:

- **No ungoverned changes.** This skill is a sensor. A pattern it surfaces becomes an `improvement.yml` CANDIDATE through issue → plan → PR; it never becomes a direct edit, at any cluster size, at any confidence.
- **No invention.** A learning that did not happen in the session does not get a row.
- **Files are the memory — but not *that* file.** The operator auto-memory store is operator-write-only (schema § 5.3). This skill never writes it, never proposes an auto-write to it, and treats it strictly as a promotion target reachable only through the gate.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` and `## Reversibility Discipline`. Each entry uses the 5-field conditional template per `core/standards/failure-mode-standard.md` and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Retro fires on every trivial session — TRIG

- **Signature (observable signal):** `query-pipeline-event.sh --event-type session-retro --count` grows roughly one-per-session, and the rows are dominated by restatements of already-codified rules; a `--source session-retro` pattern-detect run returns clusters whose `theme:` keys are generic platform vocabulary rather than a specific recurring pattern.
- **Conditional:** do NOT run the retro on a session that cleared no meaningful work when the trigger is automatic, because the log is append-only and permanent — a low-signal row can never be deleted, only redacted, and every one of them permanently dilutes the ≥3-cluster denominator the synthesizer depends on.
- **Root cause:** "almost per session" reads like "nearly always", and firing feels like diligence; the sampling threshold is the only thing standing between a learning sensor and a session-count counter, and it is easy to treat as advisory rather than as the load-bearing control it is.
- **Mitigation:** evaluate the `[session_retro]` threshold BEFORE reflecting, not after (Step 1 precedes Step 2 deliberately — reflecting first creates a sunk-cost pull toward emitting). On an automatic invocation a below-threshold session emits nothing at all, not a `no-learning` row. Require novelty against the codified corpus, not merely truth.
- **Principal response vs. junior response:** Principal treats the threshold as a gate and reports "skipped: below threshold" as a successful outcome. Junior fires on every session because a row feels like output, and within a quarter the surface is unusable — real patterns are buried under sessions that taught nothing.

### Verbatim operator content in the payload — OUT

- **Signature (observable signal):** A `learning:` or `theme:` field carries a quoted phrase, a person's name, a client or vendor reference, an external file path, or anything recognizably lifted from the session rather than written about it; `payload` reads like a transcript excerpt rather than an abstraction.
- **Conditional:** do NOT copy session content into the payload when the event log is a durable, append-only, potentially-public-adjacent audit surface, because § 4.2 disallows external-stakeholder names, customer data, and Cowork-owned Layer 2 content — and a row cannot be unwritten, only redacted after the fact, which leaves the leak in the git-tracked history of every consumer that already read it.
- **Root cause:** the verbatim quote is genuinely the highest-fidelity evidence, so quoting feels like rigor; this skill is also the only emitter whose *input* is raw session content, so it is the one place where the general PII rule has to be applied to unstructured text rather than to structured fields.
- **Mitigation:** write every `learning:` as a sentence about a pattern, in your own words, that would still make sense to a reader with no access to the session. Ban quotation marks in the payload as a mechanical proxy. Where a redaction is needed after the fact, use the schema § 7 `scope-change` / `redaction` row — never edit the log.
- **Principal response vs. junior response:** Principal writes "operator redirected a mechanical sweep toward per-file reading" and loses nothing that matters. Junior pastes the operator's sentence for fidelity, and a durable audit surface now carries operator-personal content that only a redaction row can partially undo.

### Acting on the learning instead of emitting it — HAND

- **Signature (observable signal):** The session that ran the retro also contains a corpus edit, a `gh issue create`, a memory write, or a skill change justified by "the retro found X"; `git status` after a retro shows a modified file other than the event log.
- **Conditional:** do NOT fix, file, or codify what the retro surfaced when the retro is a sensor, because the sensor→gate separation is the entire reason this capability was approved as signal-only — a retro that acts is an ungoverned change authored by the same agent that decided it was needed, with no plan, no review, and no operator approval in the loop.
- **Root cause:** the push-to-resolve instinct is otherwise correct on this platform, and the learning usually names an obvious small fix; the gap between "I can see the fix" and "I am authorized to make the fix" is exactly where a signal-only surface turns into an unreviewed actuator.
- **Mitigation:** the write scope is enumerated and closed (Autonomy Tier above): `append-pipeline-event.sh` rows only. A promotion is a RECOMMENDATION in the output, and cross-session promotion is the synthesizer's `--apply` path under the ≥3-cluster / ≥2-version predicate plus the governance gate — never a single session's call.
- **Principal response vs. junior response:** Principal emits the row, names the candidate fix as a recommendation, and stops. Junior "closes the loop" by making the change, and the platform acquires an edit that no issue tracks, no plan authorizes, and no reviewer saw.

### Duplicating the decision-moment grain — PROC

- **Signature (observable signal):** A retro run emits a `session-retro` row that restates a `recommendation-choice-delta` row already captured live in the same session — the same decision appears twice in the log under two event types, and a joined read double-counts it.
- **Conditional:** do NOT re-emit a decision the live decision-moment path already captured when both grains write the same log, because the two surfaces compose rather than overlap by design — duplicating inflates any read-model that counts decisions and makes the "did the delta get captured?" question unanswerable from the log.
- **Root cause:** the two grains genuinely overlap on one class (a recommendation↔choice delta *can* be seen both live and in hindsight), so the boundary is a judgment about what was ALREADY recorded, not a difference in signal type — and the retro runs after the fact, when both look identical.
- **Mitigation:** before emitting a delta, query the log for the session's existing rows (`query-pipeline-event.sh --version <v> --event-subtype recommendation-choice-delta`). Emit a hindsight delta ONLY when the live path emitted none, and mark it `via:session-retro` so the provenance is explicit. Everything else the retro emits — the no-decision feedback class, session friction — is structurally outside the decision-moment path and never duplicates it.
- **Principal response vs. junior response:** Principal checks what was already captured and emits only the genuine gap, tagged with its provenance. Junior treats the retro as a complete session summary, re-emits every decision, and the delta read-model silently double-counts a release.

## What This Skill Does NOT Do

- **Does not write the operator auto-memory store.** That surface is operator-write-only (schema § 5.3); it is a promotion target reached through the governance gate, never a write target here.
- **Does not create issues, edit the corpus, or change any skill.** Signal-only, enumerated write scope: event-log rows and nothing else.
- **Does not promote a pattern from one session.** Promotion requires the synthesizer's ≥3-cluster / ≥2-version predicate plus the gate.
- **Does not replace the decision-moment or release grain.** It composes with both; the overlap rule is the PROC failure mode above.
- **Does not read or store transcript content.** It reflects over the session in-context and emits abstractions; no transcript path, excerpt, or copy enters the payload.
- **Does not activate its own trigger.** The `Stop` hook ships inert; activating it is an operator-instance decision outside this skill's reach.
- **Is not a routing target.** It is a `kind: core` function-skill; `pmo-skill-router` does not route to it.
