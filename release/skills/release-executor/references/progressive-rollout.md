# Progressive Governance Rollout

## Purpose

This reference defines the **three-cycle progressive-rollout model** the executor
applies to governance rules and to the quality-gate ladder. A new governance rule
should not flip straight to blocking in-flight releases the day it ships. Instead it
advances through three cycles — **shadow → warn → enforce** — so the operator observes
its real hit-rate against live releases before it ever halts one. The `## Quality-Gate
Ladder` section in `SKILL.md` is the canonical definition of the gates this model wraps;
this reference is the canonical definition of the rollout cycles, the per-rule
`rollout-cycle` attribute, the outcome-log persistence surface, and the operator-gated
advance procedure.

This is a **generalization of a pattern the platform already runs**, not a new scheme —
see the "Precedent and non-divergence" section below. The single net-new addition is the
`shadow` cycle (silent observation), which the existing two-state precedent does not have.

## The three-cycle model

A rule or gate evaluated by the executor reports a **verdict** — `pass` or `would-fail`
(the rule's predicate found a violation). The rule's `rollout-cycle` decides what the
executor *does* with a `would-fail` verdict:

| Cycle | Executor behavior on a `would-fail` verdict | Blocks the release? | Operator-visible at run time? | Persists the hit? |
|---|---|---|---|---|
| `shadow` | Evaluate the rule, append a hit line to the rule's outcome-log, continue **silently** | No | No — silent; log only | Yes (`cycle: "shadow"`) |
| `warn` | Evaluate, **emit an operator-facing notice** at run time, AND append a hit line | No | Yes — notice in the run output | Yes (`cycle: "warn"`) |
| `enforce` | Evaluate; on a `would-fail` verdict **block** (and, inside the gate ladder, short-circuit) with the rule's actionable finding | Yes | Yes — hard stop | A blocked release is its own record; logging is optional |

A `pass` verdict is a no-op in every cycle: the rule found no violation, nothing is
logged, nothing is surfaced, the release proceeds.

The operator-facing notice a `warn`-cycle hit emits at run time reads:

```
⚠ <rule-id> would block: <reason>; currently warn-cycle — release proceeds.
```

## The `rollout-cycle` attribute

Every governance rule and every gate the executor evaluates carries a `rollout-cycle`
attribute the executor reads at evaluation time to choose log-only / notice / block.

- **Allowed values:** `shadow`, `warn`, `enforce`.
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

This model is a generalization of two patterns already in the corpus — it deliberately does
**not** invent a divergent scheme:

- **The hook-layer mode file.** The platform's security-hook layer already runs an
  `enforce` / `warn` / `off` mode for several hooks, with per-hook `*-warn-log.jsonl`
  persistence and a "Shakedown → Enforce Transition Checklist" as the advance gate. The
  Hook Layer Reference under the core rules set is the canonical description. This model
  reuses that mode vocabulary, that persistence location and shape, and that advance-gate
  pattern.
- **Per-criterion warn-to-enforce in the gate-criteria spec.** The platform's gate-criteria
  schema already rolls individual criteria out `warn → enforce` with dedicated
  `core/hooks/<name>-warn-log.jsonl` files and the same shakedown checklist as the flip
  authority. This model formalizes that ad-hoc inline disposition into the named
  `rollout-cycle` attribute.

The single net-new element is the **`shadow` cycle** — silent, persisted-but-not-surfaced
observation — which neither precedent carries (their `warn` is operator-reviewable after
the fact, so it cannot serve as the silent-observation tier). Everything else — the
persistence convention, the advance-checklist shape, the inline-attribute home, the
fail-safe-to-`enforce` default — is reused verbatim from the precedents so an operator
brings existing muscle-memory to it.

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
