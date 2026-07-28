---
title: "ADR-099 — Event-log payload pipe grammar (escaped `\\|` as the canonical multi-value separator)"
status: Proposed
date: 2026-07-27
release: decision-telemetry-emission (#295) (v3.98 provisional; bound at Stage 12)
deciders: "Operator rendered D-1 (WIDEN, fork A) at the Wave-1 Decision Briefing; the Stage 5 Solutioning spoke (#4056) selected the mechanism (candidate A2) after falsifying the hub's original candidate rule against all 8 consumers; Stage 6 Engineering (#4057) authored it; operator ratifies at the Stage 9 plan-review gate"
tags: [release-ops, telemetry, event-log, schema, payload-grammar, validation, guard, observability, ssot]
source_observations:
  - "`stage-05-solutioning.md` § 11 codifies a `decision` / `cascade-sweep-block` emission whose payload carries a multi-value trigger list separated by pipes, but `append-pipeline-event.sh` rejected every payload containing a pipe — so the pipeline instructed an emission its own validator refused. Verified live: the § 11 literal payload exits 1 on unfixed main."
  - "The guard being replaced was a single substring test for `|`. It is simultaneously over-broad (it rejects a character that is parse-safe in most positions) and under-broad (it admits a payload ending in `\" |\"`, and admits newlines — both verified to break the row). Widening the grammar without re-deriving admissibility would have preserved two known holes."
  - "A per-consumer probe of all 8 event-log readers falsified the assumption that every consumer splits on the shared delimiter: `rollup-attribution.sh` split on a BARE pipe and silently dropped the `session:` join token, losing issue-grain FinOps attribution. That single counter-example moved the canonical form from the bare pipe to the escaped pipe."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-099 — Event-log payload pipe grammar (escaped `\|` as the canonical multi-value separator)

## Status

Proposed — authored at Stage 6 Engineering; ratified at the operator's Stage 9 plan-review gate of the introducing release. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

The pipeline event log is a markdown table whose rows consumers split on the canonical column delimiter `" | "` (space-pipe-space). `release/references/standards/pipeline-event-log-schema.md` constrained the `payload` cell to be pipe-free, and `release/tools/append-pipeline-event.sh` enforced that with a single substring test.

Three facts converged.

**First, the schema contradicted a stage shard it governs.** `release/references/pipeline/stage-05-solutioning.md` § 11 codifies a `decision` / `cascade-sweep-block` emission whose payload carries a multi-value trigger list using a pipe separator. The pipeline therefore instructed an emission its own validator rejected — the payload-axis half of a schema↔stage-shard drift class whose type/subtype half [ADR-086](ADR-086-event-log-schema-decision-subtype-extension.md) closed. ADR-086 § 5 bounded itself explicitly to the type/subtype axis and handed this payload axis off to a separate intake; this record is that intake's resolution.

**Second, the schema contradicted itself on the rule being changed.** Two sites described payloads as "pipe-escaped" while three convention blocks cited the same section as mandating "pipe-free". Neither phrasing described the enforced behavior, which was a blanket rejection.

**Third, the guard was wrong in both directions.** A substring test for `|` is over-broad — it rejects a character that leaves row arity intact in most positions — and under-broad, because two payload forms it *admits* do break the row: a payload ending in `" |"` forms the delimiter at the row-trailing junction, and a payload containing a newline emits a two-physical-line row. Widening the grammar while preserving those holes would have authored a knowingly-vacuous guard.

A per-consumer probe of all eight event-log readers established the constraint that decides the mechanism. Seven split on the shared `" | "` delimiter and are indifferent to a pipe inside the payload; the eighth (`core/skills/finops-usage-extractor/scripts/rollup-attribution.sh`) split on a **bare** pipe, truncating the payload and silently dropping the `session:` join token that carries issue-grain FinOps attribution. Because `payload` is the last of the ten columns, an intra-payload split can only append spurious trailing fields — it can never shift a pre-payload column — so the failure is a silent false-negative, never a mis-read.

## Decision

The payload grammar admits the **backslash-escaped** `\|` as the canonical multi-value separator; the **bare** `|` remains reserved.

Admissibility is defined by a **row-integrity invariant** — the assembled row must be exactly one physical line splitting into exactly ten fields under `" | "` — rather than by a character blacklist.

The escaped form is chosen over the bare form on two independent axes. On the parsing axis, one consumer splits on a bare pipe. On the rendering axis, the log is a markdown surface, where a bare pipe renders a spurious cell break and `\|` renders a literal pipe. The escaped form is safe on both axes; the bare form is safe on neither. It is chosen over a `/` separator because `/` is already a value character inside the very payloads under design (the `verdict:` field renders its alternatives with slashes), so a `/` list separator would be ambiguous. It is chosen over an HTML entity because the log is grepped directly.

The writer does not rewrite author input: a bare pipe is **rejected with an actionable message** naming the escaped form, never silently normalized. Normalization was considered and rejected — it would rewrite the emitter's payload and reopen the payload length-cap ordering, since escaping grows the string.

The consumer that splits on a bare pipe is migrated to the shared delimiter as a required co-change in the same release, so the hazard and its mitigation ship together.

## Consequences

**(a)** The emission § 11 codifies validates end-to-end, closing the payload-axis half of the schema↔stage-shard drift class. The shard's literal source text becomes writable verbatim, so the shard itself needs no amendment.

**(b)** Validation **tightens** net. Two previously-admitted row-corrupting payloads — one ending in `" |"`, and one containing a newline or carriage return — are now rejected. The grammar loosens on exactly one axis (the escaped separator) and tightens on two.

**(c)** Every consumer that reads the payload must split on the shared `" | "` delimiter. The one that split on a bare pipe is migrated as a required co-change; a future consumer that reintroduces a bare-pipe split silently reopens the same attribution-loss path.

**(d)** Payload-convention blocks authored in the schema must escape enum-alternative notation or state the runtime form. This is enforced by the guard and by `--self-test`, not by convention — a convention block specifying an unwritable payload now fails loudly at authoring time with a message naming the fix.

**(e)** The invariant is delimiter-derived, so a future column change re-derives admissibility rather than re-litigating a character list. The `--self-test` asserts the row-arity invariant directly, not merely the predicate, so a predicate that drifts away from the delimiter contract fails the test rather than shipping green.

**(f)** [ADR-086](ADR-086-event-log-schema-decision-subtype-extension.md) § 5's scope-bound text remains true and is deliberately left unedited: the bare-pipe example it cites is still rejected under this grammar. This record resolves the axis § 5 handed off; an ADR is superseded by a new ADR, never rewritten.

## Reversibility

**CHEAP / Confidence HIGH.** The guard is a self-contained block; a revert restores prior behavior. Already-emitted escaped payloads survive a revert and remain readable, because consumers do not re-validate on read — so there is no data migration in either direction.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Admit the **bare** pipe, reject only the space-delimited delimiter | Breaks the one consumer that splits on a bare pipe, and renders a spurious cell break in the markdown table. Safe on neither axis. |
| Admit the escaped form but **normalize** a bare pipe to it on write | Lossy — rewrites the emitter's payload — and reopens the length-cap ordering, since escaping grows the string by one byte per pipe. |
| Normalize pipes to `/` on write | `/` is already a value character in the same payloads (the `verdict:` alternatives), so a `/` list separator would be ambiguous against them. |
| Encode as the HTML entity `&#124;` | Unreadable in the raw log, which the schema specifies is grepped directly; zero precedent anywhere in the corpus. |
| Keep the blanket pipe rejection and amend the stage shard instead | Leaves the guard's two row-corrupting holes open, and forces every future multi-value payload through a workaround rather than fixing the grammar once. |
