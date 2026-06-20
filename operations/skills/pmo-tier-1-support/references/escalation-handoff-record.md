<!-- reference-durability: allow-link -->
# Escalation Handoff Record (EHR) — Tier-1 → Tier-2 Support Contract

## Purpose

The **Escalation Handoff Record (EHR)** is the single load-bearing seam between
the support pair: [`pmo-tier-1-support`](../SKILL.md) **produces** it when it
escalates a problem out of first-line scope, and
[`pmo-tier-2-support`](../../pmo-tier-2-support/SKILL.md) **consumes** it as the
declared input to its root-cause analysis. It is defined **once, here** (under
its emitter, tier-1) and **referenced by name** from both skills — neither skill
redefines it, so the producer and the consumer cannot drift. The EHR *is* the
schema; the two skills are its two ends.

This single-sourcing is deliberate. The basename `escalation-handoff-record.md`
exists under exactly one skill (`pmo-tier-1-support`); tier-2 cites it by the
relative path above. A same-basename copy under both skills would be an
unregistered shared-reference collision (`deploy.sh` Check 13b) — so the contract
lives in one place and is read by reference.

## Storage and lifecycle

Per the Stage 5 design and the hub resolution, the EHR is a **staged artifact in
`08-Generated/`**, produced by composing
[`artifact-generator`](../../artifact-generator/SKILL.md) (Generate Mode → stage
with `artifact_state: DRAFT`). Staging — rather than an in-conversation hand-off
payload — gives every escalation an **auditable record** and matches
`artifact-generator`'s established staging contract. Tier-2 reads the EHR from
`08-Generated/`.

## Contract direction (one-way, asymmetric)

```
tier-1  ──emits──▶  EHR (08-Generated/)  ──consumed by──▶  tier-2
```

Tier-2 does **not** emit an EHR back to tier-1. Its terminal output is a
**resolution + an authored/updated runbook** that makes the *next* occurrence
first-line-resolvable — the loop closes through the knowledge base, not through a
return handoff.

## Schema

Eight fields: the four issue-named required-core fields
(`symptom · reproduction · what-was-tried · severity`) plus four justified
additions. Each field names what the **producer (tier-1)** writes and what the
**consumer (tier-2)** does with it.

| Field | Req? | Producer (tier-1) writes | Consumer (tier-2) uses for |
|---|---|---|---|
| `symptom` | **required** | The observable signal, verbatim — what the user/system actually saw | RCA Step 1 *"state the observable signal"* input |
| `reproduction` | **required** | Steps tier-1 took / the user reported to reproduce; or `[ASSUMPTION – CONFIRM] not reproduced — owner: tier-2` if it could not | RCA Step 1–2 reproduction anchor; a non-reproduced escalation is flagged, never silently dropped |
| `what-was-tried` | **required** | The known-issue lookups / runbook steps tier-1 attempted and their outcome (this is what makes the escalation *first-line-exhausted*, not lazy) | RCA Step 2 — rules out the proximal causes already eliminated; prevents tier-2 re-treading first-line ground |
| `severity` | **required** | Tier-1's severity read (CRITICAL / HIGH / MEDIUM / LOW per the `review-discipline-principles.md` §5 severity model) | RCA prioritization + reversibility framing input |
| `evidence` | **required** (justified) | `file:line` / log line / screenshot pointer backing the symptom | RCA Step 1 *"a signal without evidence is not yet a signal"* — the EHR carries the evidence so tier-2 does not re-fetch it |
| `escalation-reason` | **required** (justified) | One line: *why* this is out of first-line scope (novel / no runbook match / runbook stale / beyond Pattern-A autonomy) | Tier-2 triage — confirms the escalation was correct vs. a tier-1 lookup miss (closes the deconfliction loop empirically) |
| `searched-runbooks` | optional (justified) | Which runbooks / FAQs tier-1 checked (by id/path) and matched-vs-missed | Tier-2's **author-vs-update** runbook decision: a matched-but-stale hit → *update*; no match → *author new* |
| `environment` | optional (justified) | Platform / version / context where the symptom appeared | RCA reproduction context |

### Why the four additions are justified (not gold-plating)

- **`evidence`** is mandated by RCA Step 1 — the method tier-2 *runs* rejects an
  evidence-free signal. Putting it on the EHR is the difference between tier-2
  re-fetching evidence and consuming it.
- **`escalation-reason`** is the empirical artifact that lets tier-2 (and the
  Stage-7 cross-skill false-positive harness) confirm the deconfliction boundary
  was respected — that the escalation was a genuine novel problem, not a tier-1
  lookup miss.
- **`searched-runbooks`** directly feeds tier-2's author-vs-update runbook
  decision.
- **`environment`** is RCA reproduction context.

The four issue-named fields (`symptom · reproduction · what-was-tried ·
severity`) remain the **required core**; the additions are required/optional as
marked.

## Field-completeness gate (tier-1 emit-time)

Tier-1 does not emit an EHR with an empty required field. A missing `symptom`,
`reproduction`, `what-was-tried`, `severity`, `evidence`, or `escalation-reason`
is filled — and where a value is genuinely unknown (e.g., the issue could not be
reproduced), the field carries an explicit `[ASSUMPTION – CONFIRM]` with an owner,
never a blank. An EHR with blank required fields is an incomplete handoff that
forces tier-2 to re-elicit what tier-1 already had in hand.

## See also

- [`pmo-tier-1-support/SKILL.md`](../SKILL.md) — the **emitter** (Escalate step).
- [`pmo-tier-2-support/SKILL.md`](../../pmo-tier-2-support/SKILL.md) — the **consumer** (RCA method input).
- [`core/disciplines/root-cause-analysis.md`](../../../../core/disciplines/root-cause-analysis.md) — the RCA method tier-2 invokes; Step 1 mandates the evidence the EHR carries.
- [`core/disciplines/review-discipline-principles.md`](../../../../core/disciplines/review-discipline-principles.md) — §5 severity model for the `severity` field.
- [`artifact-generator/SKILL.md`](../../artifact-generator/SKILL.md) — the staging mechanism (`08-Generated/`, `artifact_state: DRAFT`) tier-1 composes to render the EHR.
