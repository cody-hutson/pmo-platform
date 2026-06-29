<!-- Binary LLM judge — health-check `comms` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `comms` mode (binary)

You are grading the output of the `health-check` skill run in `comms` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `comms`'s load-bearing behavior is classifying each communication's lifecycle state (stale-SENT, obsolete-DRAFT, unsent-READY) and routing closures to `/comms-writer` (status only) without ever auto-applying.

## PASS criteria (ALL must hold)

1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **Every seeded comms drift surfaced** and routed by confidence/band: a stale-SENT awaiting response, two-source corroborated and recent → `## Auto-Actionable` with a `TRACKER_UPDATES:` row (status-only); an unsent-READY past its window → `## Auto-Actionable` or `## Decisions` per confidence; an obsolete-DRAFT whose obsolete-vs-reschedule is an operator call → `## Decisions`.
3. **Lifecycle classification correct** — a SENT item awaiting a response past its window is not read as closed; a DRAFT for a passed event is flagged obsolete; a READY item never sent is flagged unsent.
4. **`TRACKER_UPDATES:` block present iff there is an `## Auto-Actionable` item**, and the block carries status-only actions (the skill never drafts or sends the comm — it routes to `/comms-writer` on approval).
5. **No inferred response** — the output does NOT assert a response was received where no source attests it (cautious bias on inferring a response).
6. **Zero seeded-clean comms flagged** (a recent, no-response-needed item is not a finding).
7. **Every finding carries a `[confidence: … · S…]` label.**

## FAIL triggers (any one)

- A seeded comms drift not surfaced, or routed to the wrong section (especially a stale-SENT or unsent item silently dropped).
- A `TRACKER_UPDATES:` block that applies (sends/drafts) a comm rather than emitting a status-only proposal routed to `/comms-writer`.
- A response asserted where no source attests it (fabricated lifecycle transition).
- A seeded-clean comm flagged (false positive).
- Missing/reordered section header, or `TRACKER_UPDATES:` inconsistent with `## Auto-Actionable`.

## Verdict

`PASS` — all seeded comms drifts correctly classified and routed, status-only updates, no inferred response, zero clean false-flags. Otherwise `FAIL` with the first violated criterion cited.
