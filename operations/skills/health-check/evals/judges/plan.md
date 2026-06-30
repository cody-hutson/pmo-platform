<!-- Binary LLM judge — health-check `plan <name>` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `plan <name>` mode (binary)

You are grading the output of the `health-check` skill run in `plan <name>` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `plan`'s load-bearing behaviors are (1) auditing the **one named plan** for plan-promised vs trackers-reflected delta, and (2) **prompting "which plan?" when no name is supplied — never silently defaulting** (the AC-2 requirement).

This judge grades **two distinct invocations**:

## Invocation A — `plan Hypercare` (a name IS supplied)

### PASS criteria (ALL must hold)
1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **The audit is scoped to the named plan only** — it reports the named plan's promised items vs what the trackers reflect, not a sweep of every plan.
3. **Every seeded plan-delta surfaced** and routed: a promised item absent from the trackers AND corroborated absent by a second source → `## Auto-Actionable` (HIGH) with a `TRACKER_UPDATES:` row; a promised item that may have been deliberately superseded → `## Decisions` (MEDIUM, cautious bias); a promised item the tracker confirms delivered → `## Confirmed`.
4. **Cautious bias honored** — a missing promised item is not asserted as "failed"; the possibility of deliberate supersession is preserved for the operator.
5. **Zero seeded-clean (delivered) items flagged.**
6. **Every finding carries a `[confidence: … · S…]` label.**

## Invocation B — `plan` (NO name supplied)

### PASS criterion (the single load-bearing assertion)
- The mode returns an **actionable "which plan?" prompt** — it names the candidate plans it can see (or asks the operator to name one) and does **NOT** run an audit against a guessed/defaulted plan. A clean 5-section report produced against any auto-chosen plan is an automatic FAIL.

## FAIL triggers (any one)

- (A) A seeded plan-delta not surfaced, or routed to the wrong section.
- (A) A missing promised item asserted as failed/closed without preserving the supersession possibility.
- (A) A seeded-clean delivered item flagged (false positive).
- (B) The no-name invocation runs against a defaulted plan instead of prompting (the headline `plan` failure).
- Missing/reordered section header, or `TRACKER_UPDATES:` inconsistent with `## Auto-Actionable`.

## Verdict

`PASS` — (A) the named plan's deltas are correctly categorized with cautious bias and zero clean false-flags, AND (B) the no-name invocation prompts rather than defaulting. Otherwise `FAIL` with the first violated criterion cited.
