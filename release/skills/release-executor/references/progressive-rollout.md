# Progressive Governance Rollout

## Purpose

This reference defines the **executor realization** of the platform's progressive-rollout
convention — how the executor applies the rollout phases to governance rules and to the
quality-gate ladder. A new governance rule should not flip straight to blocking in-flight
releases the day it ships. Instead it advances through the rollout phases so the operator
observes its real hit-rate against live releases before it ever halts one.

**Canonical source for the phase enum and the per-phase contract:**
`core/standards/progressive-rollout-convention.md`.
That pipeline-wide convention OWNS the phase enum (`shadow → warn → enforce → removed`)
and the per-phase 4-element contract (observable behavior · telemetry contract · advance
criteria · retreat trigger). This reference does **not** re-define that vocabulary (per the
duplicate-source register-or-remove rule in `core/standards/duplicate-source-discipline.md`
the enum lives in exactly one canonical home — the convention); it cites the convention for
the phase definitions and owns the **executor-specific machinery**: the per-rule / per-gate
`rollout-cycle` attribute, the executor's `would-fail` dispatch, the JSONL outcome-log
persistence surface, the gate-ladder short-circuit seam, and the operator-gated advance
procedure as the executor runs it. The `## Quality-Gate Ladder` section in `SKILL.md` is the
canonical definition of the gates this model wraps.

> **Executor scope note (3 of 4 phases).** The executor's `rollout-cycle` attribute ranges
> over the first three phases — `shadow`, `warn`, `enforce` — because the executor dispatches
> a *running* mechanism's `would-fail` verdict. The convention's terminal fourth phase,
> `removed` (decommission), is not an executor `rollout-cycle` value: a `removed` mechanism
> no longer runs, so there is no verdict to dispatch. The executor reference is therefore a
> 3-of-4 realization of the 4-phase convention; the `removed` phase is owned by the
> convention and the touchpoint phase-out schema, not dispatched here.

This is a **generalization of a pattern the platform already runs**, not a new scheme —
see the "Precedent and non-divergence" section below. The single net-new addition the
executor model contributed over the prior two-state precedent is the `shadow` cycle (silent
observation); the convention then lifted that vocabulary pipeline-wide and added the
terminal `removed` phase.

## Executor dispatch by phase (`shadow` / `warn` / `enforce`)

The phase enum and the per-phase contract are defined canonically in
`core/standards/progressive-rollout-convention.md`
— read it for the authoritative observable-behavior / telemetry / advance-criteria /
retreat-trigger contract of each phase. This section is the **executor-specific dispatch**:
how the executor turns a rule's or gate's `rollout-cycle` value into a run-time action.

A rule or gate evaluated by the executor reports a **verdict** — `pass` or `would-fail`
(the rule's predicate found a violation). The rule's `rollout-cycle` (one of the convention's
first three phases) decides what the executor *does* with a `would-fail` verdict:

| Phase (`rollout-cycle`) | Executor behavior on a `would-fail` verdict | Blocks the release? | Operator-visible at run time? | Persists the hit? |
|---|---|---|---|---|
| `shadow` | Evaluate the rule, append a hit line to the rule's outcome-log, continue **silently** | No | No — silent; log only | Yes (`cycle: "shadow"`) |
| `warn` | Evaluate, **emit an operator-facing notice** at run time, AND append a hit line | No | Yes — notice in the run output | Yes (`cycle: "warn"`) |
| `enforce` | Evaluate; on a `would-fail` verdict **block** (and, inside the gate ladder, short-circuit) with the rule's actionable finding | Yes | Yes — hard stop | A blocked release is its own record; logging is optional |

This dispatch table is the executor's realization of the convention's per-phase **observable
behavior** element, specialized to the release-execution context (the action being gated is a
release; the short-circuit is over the quality-gate ladder Tiers). It does not restate the
convention's telemetry / advance / retreat contract — that lives in the convention.

A `pass` verdict is a no-op in every cycle: the rule found no violation, nothing is
logged, nothing is surfaced, the release proceeds.

The operator-facing notice a `warn`-cycle hit emits at run time reads:

```
⚠ <rule-id> would block: <reason>; currently warn-cycle — release proceeds.
```

## The `rollout-cycle` attribute

Every governance rule and every gate the executor evaluates carries a `rollout-cycle`
attribute the executor reads at evaluation time to choose log-only / notice / block.

- **Allowed values:** `shadow`, `warn`, `enforce` — the first three phases of the canonical
  enum in `core/standards/progressive-rollout-convention.md`.
  The terminal `removed` phase is not a `rollout-cycle` value (a decommissioned mechanism
  has no `would-fail` verdict to dispatch — see the Executor scope note in Purpose).
- **Default:** `enforce`. A rule that declares no `rollout-cycle` keeps its full blocking
  teeth — adoption of this model is **behavior-preserving** for every existing rule, and
  the gate ladder ships every gate at `enforce`.
- **Fail-safe to `enforce`:** when the attribute is absent, empty, or unparseable, the
  executor defaults to `enforce`, never to `shadow` or `warn`. A silent default could mask
  a real block the operator expected; the safe failure direction is to keep blocking. This
  mirrors the always-block posture the platform reserves for its highest-confidence
  destructive-operation guards.

The attribute lives **inline on the rule or gate it governs** — for the quality-gate
ladder, it is the `rollout-cycle` column on the gate table in the `## Quality-Gate Ladder`
section in `SKILL.md`. It is not a separate central registry: a registry would duplicate
the gate table's per-row authority and drift from it. Each rule owns its own cycle.

## The outcome-log (hit-log)

Shadow-cycle and warn-cycle hits persist to a per-rule append-only log so the operator can
review a rule's hit-rate before advancing it.

- **Path:** `core/hooks/<rule-id>-rollout-log.jsonl` — one log per rule, named for the
  rule it tracks. This reuses the established `core/hooks/` location and the per-rule
  `*-log.jsonl` convention the platform's warn-mode hooks already use, so an operator
  drains these logs with the same muscle-memory. The `-rollout-log` suffix (rather than
  `-warn-log`) signals that the line carries a `cycle` field spanning both `shadow` and
  `warn`, where the precedent warn-logs carry warn only.
- **Format:** append-only JSONL, one line per `would-fail` hit. Fields:

| Field | Meaning |
|---|---|
| `ts` | ISO-8601 timestamp of the hit |
| `rule-id` | the rule or gate that produced the hit |
| `cycle` | `shadow` or `warn` (the cycle the rule was in when the hit fired) |
| `verdict` | `would-fail` (the predicate found a violation that a later `enforce` cycle would block on) |
| `reason` | the rule's specific finding text — what would have blocked |
| `release` | the release identifier the hit fired during |

- **Rotation:** the rollout-logs are append-only and grow unbounded. Log rotation for
  this surface is deferred and folds into the platform's existing warn-log rotation
  follow-up rather than a new file-specific mechanism — do not author a separate rotation
  scheme here.

## Seam with the quality-gate ladder

The progressive-rollout model **wraps** the quality-gate ladder. The ladder (defined in
the `## Quality-Gate Ladder` section in `SKILL.md`) is a three-tier sequence — T1 schema
validation → T2 cross-reference integrity → T3 stakeholder approval — that fires in order
and short-circuits on the first failure. The `rollout-cycle` attaches **per gate Tier** as
the gate table's `rollout-cycle` column, and one shared gate-evaluation routine dispatches
each Tier's `would-fail` result through the cycle:

```
for tier in [T1, T2, T3]:                 # the gate ladder, in order
    verdict = evaluate(tier)              # the gate's pass / would-fail predicate
    if verdict == would-fail:
        cycle = tier.rollout_cycle        # default enforce
        if cycle == "shadow":
            log(tier, "shadow")           # append hit line; observe
            continue                      # ladder CONTINUES — no short-circuit
        if cycle == "warn":
            log(tier, "warn")
            notice(tier)                  # operator-facing run-time notice
            continue                      # ladder CONTINUES — no short-circuit
        if cycle == "enforce":
            emit_finding(tier)            # the 5-field actionable finding
            BLOCK                         # halt the release
            short-circuit                 # downstream tiers do NOT run
    # pass → next tier
```

**The load-bearing rule:** a `shadow` or `warn` gate **does NOT short-circuit** the ladder
— it logs (and, for `warn`, notices) and the ladder continues to the next Tier. Only an
`enforce` gate fails-and-short-circuits. This preserves the ladder's "fires in order,
short-circuits on first failure" invariant exactly — because that invariant is now scoped
to `enforce` gates — while making each gate independently roll-out-able. A gate can be
deployed at `shadow`, watched, advanced to `warn`, watched again, then advanced to
`enforce` where it gains its short-circuit teeth.

**Seam contract.** The gate ladder owns the Tier ordering, each Tier's pass/would-fail
predicate, and the actionable-finding text. This rollout model owns the `rollout-cycle`
attribute, the log-only / notice / block dispatch, and the outcome-log. The single shared
object is the gate-evaluation routine, whose live (git-native) invocation point is the
Tiered Quality-Gate Ladder in `references/execution-checklist.md`.

## The testable transition (worked example)

The acceptance behavior — *a new governance rule deployed in shadow cycle logs but does
not block; it transitions through warn to enforce* — is a concrete three-step walk:

1. **Shadow.** Author a rule with `rollout-cycle: shadow`. Run a release that would violate
   it. The executor appends
   `{ts, rule-id, cycle: "shadow", verdict: "would-fail", reason, release}` to
   `core/hooks/<rule-id>-rollout-log.jsonl`; the release **proceeds**; there is **no**
   run-time notice. The operator now has hit data with zero release disruption.
2. **Warn.** The operator reviews the log, runs the Advance Checklist below, and bumps the
   rule to `rollout-cycle: warn`. The next violating release writes the **same** log line
   with `cycle: "warn"` **plus** an operator-facing ⚠ notice at run time; the release
   **still proceeds**.
3. **Enforce.** The operator bumps the rule to `rollout-cycle: enforce`. The next violating
   release **blocks** with the rule's actionable finding; inside the gate ladder it
   **short-circuits** the downstream Tiers.

At no point is advancement automatic — each bump is an operator decision recorded by the
attribute change (see the Advance Checklist).

## Advance Checklist (shadow → warn → enforce)

This checklist is the executor's concrete operationalization of the convention's per-phase
**advance-criteria** element (see `core/standards/progressive-rollout-convention.md`
§ "The per-phase contract" and § "Advance is an operator decision") — the convention states
the criteria; this checklist is how the executor walks them step by step.

Advancement is an **operator decision, never auto-promoted by hit-count.** Auto-promotion
by a numeric hit threshold is a deliberate non-goal: a low hit-count does not establish
that the remaining hits are false positives, and the operator's judgement on the log is the
gate. This checklist mirrors the platform's existing warn-to-enforce shakedown transition
for security hooks — the same pattern, with one extra `shadow → warn` rung the two-state
precedent lacks.

Before bumping a rule's `rollout-cycle` one step (`shadow → warn`, or `warn → enforce`):

- [ ] The rule has accrued enough live hits in its current cycle to judge its hit-rate
      (at least one full release cycle, longer for low-frequency rules).
- [ ] `core/hooks/<rule-id>-rollout-log.jsonl` has been reviewed end-to-end — every hit is
      either a genuine violation the rule should catch, or a false positive that has been
      addressed (the rule's predicate tightened, or the case added to the relevant
      allowlist).
- [ ] No unaddressed false-positive remains — a rule that still mis-fires on a legitimate
      release must not advance toward `enforce`.
- [ ] For the `warn → enforce` step specifically: the operator confirms the rule is ready
      to **halt** a release on this finding, and that the actionable-finding text tells the
      next operator exactly how to fix the violation.
- [ ] The operator records the advance by editing the rule's `rollout-cycle` value (the
      attribute change is the audit record of the decision).

Rollback is the inverse single edit: bump the `rollout-cycle` back one step (for the gate
ladder, a one-line column-value change). Reverting a rule from `enforce` to `warn` restores
non-blocking observation immediately.

## Precedent and non-divergence

The full precedent survey — the platform's pre-existing rollout ladders, why the enum is a
lift of established vocabulary rather than a new scheme, and the rejection of
`dark / canary / GA` — is in the canonical `core/standards/progressive-rollout-convention.md`
§ "Evidence-Grounding" and § "The phase enum (canonical)". This reference does not restate
that argument.

The executor-scoped point that remains here: the executor's realization **reuses the
precedents' shapes verbatim** so an operator brings existing muscle-memory to it — the
per-rule `*-log.jsonl` persistence location and format, the inline-attribute home (the
`rollout-cycle` column on the gate table), the operator-gated advance-checklist shape, and
the fail-safe-to-`enforce` default all mirror the security-hook `.mode` family and the
gate-criteria per-criterion `warn → enforce` rollout. The executor model's one contribution
over those two-state precedents was the **`shadow`** cycle (silent, persisted-but-not-
surfaced observation); the convention subsequently lifted `shadow/warn/enforce` to pipeline
scope and added the terminal `removed` phase the executor does not dispatch.

## Out of scope

- **Retrofitting the security-hook mode file to a three-state shadow/warn/enforce.** Giving
  the security hooks a silent `shadow` tier touches runtime harness tooling governed by a
  separate gate and is not part of this rule. Do not edit the hook mode file or any hook
  script under this capability. Route a separate observation ticket if a security-hook
  shadow tier is later wanted.
- **Auto-promotion by hit-count threshold.** Advancement stays an operator decision per the
  Advance Checklist; canonicalizing a numeric auto-advance threshold is a deliberate
  non-goal here.
- **Log rotation for the rollout-logs.** Deferred and folded into the platform's existing
  warn-log rotation follow-up, not a new file-specific mechanism.
