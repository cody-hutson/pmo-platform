<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-031 — Autonomy-ceiling enforcement — unified payload-triggered hook supersedes the subagent-session-detection design
status: Accepted (operator-adopted at the v2.07 / 10-ambient-intake-automation Collective Review scope-lock; authored at Stage 6 per the ADR-007 / ADR-028 / ADR-029 Stage-6 ADR-authoring precedent)
date: 2026-06-19
release: 10-ambient-intake-automation (v2.07)
deciders: "Workspace owner (R-C5RECON resolution ratified at the v2.07 Stage 9 review); design resolved at Stage 5 Solutioning"
superseded_by: ADR-149 in-part (cross-domain bridge writes member)
tags: [architecture, security, hooks, autonomy-tiers, pretooluse, enforcement, supersession, ambient-intake, reversibility]
source_observations:
  - "core/standards/subagent-security-posture.md § 4 proposed block-subagent-tier-violation.sh triggered on 'any tool call from a subagent session (detected via session context)'; § 3 Mechanism 2 of the SAME document states the hooks 'do NOT read session-context fields (no session_id, no parent_session, no subagent_type)'. The §4 trigger is internally contradicted by §3."
  - "Empirical hook survey (2026-06-19): grep -rniE 'session_id|parent_session|subagent|transcript_path' core/hooks/*.sh → zero hooks in the suite read any session/subagent/transcript field. All blocking hooks trigger on the tool-call payload (tool_name + tool_input via stdin)."
  - "core/standards/subagent-security-posture.md § 3 Mechanism 2 itself flags that whether the harness even DELIVERS subagent tool calls to hooks is 'LOGICAL-INFERRED-UNTIL-EMPIRICALLY-TESTED' — so a hook keyed on subagent delivery rests on an unverified premise."
  - "C0 (#322) landed [automation].automation_level in operator.toml.template (v2.07) as a runtime-read ceiling, with a working runtime operator.toml-read precedent at core/hooks/notify-version-skew.sh."
---

# ADR-031 — Autonomy-ceiling enforcement: unified payload-triggered hook

## Status

**Accepted.** Operator-adopted at the v2.07 / `10-ambient-intake-automation`
Collective Review scope-lock; the design resolution (R-C5RECON) was reached at
Stage 5 Solutioning and the hook authored at Stage 6, per the Stage-6
ADR-authoring precedent set by ADR-007 / ADR-028 / ADR-029. This ADR records the
supersession of a previously-named design in a canonical standard; per the
ADRs/README repo-integrity discipline it references issues as bare `#N` with the
file-level `allow-issue-ref` marker above.

## Context

The platform's autonomy model classifies every agent action by an **Autonomy
Tier** (0 Manual → 3 Autonomous; the irreducible-human-tasks set is permanent
Tier 0). Through the ambient-intake C0 keystone the platform also gained a single
operator **`automation_level`** dial (`off` / `recommend` / `bounded_auto`),
documented as a *ceiling* (`effective = min(automation_level, per-action max)`)
with an irreducible Tier-0 floor. The dial shipped **advisory** — skills read it
and self-limit, but nothing mechanically prevents an action above the ceiling.
The card resolved here adds the **enforcement floor**: a PreToolUse hook that
makes the ceiling mechanically enforceable.

Two competing hook designs targeted that one enforcement surface:

1. **The standard's deferred design** — `core/standards/subagent-security-posture.md
   § 4` proposed `block-subagent-tier-violation.sh`, triggered on *"any tool call
   **from a subagent session** (detected via session context)"* and reading an
   approval-evidence comment on the parent sub-task.
2. **The card's design** — a hook (`block-autonomy-ceiling.sh`) triggered on the
   **tool-call payload** and reading the `automation_level` ceiling.

These are not co-equal candidates. **The §4 design rests on a trigger signal the
hook layer cannot read.** § 3 Mechanism 2 of that *same* document states the
hooks "do NOT read session-context fields (no `session_id`, no `parent_session`,
no `subagent_type`)", and an empirical survey of the hook suite found **zero**
hooks reading any session/subagent/transcript field — every blocking hook
triggers on the tool-call payload. A hook keyed on subagent-session detection
would be a **false-enforcement floor**: it could not fire as specified. The same
document even flags that whether the harness *delivers* subagent tool calls to
hooks at all is unverified. The payload trigger, by contrast, is the universal
signal all hooks already use, and reading `operator.toml` at runtime has a
working precedent (`notify-version-skew.sh`).

The corpus must name exactly **one** design for this surface. Leaving §4 naming a
phantom `block-subagent-tier-violation.sh` while the card ships
`block-autonomy-ceiling.sh` would be a duplicate-source contradiction.

## Decision

**Ship ONE hook — `block-autonomy-ceiling.sh` — payload-triggered, reading the
`automation_level` ceiling, that ALSO absorbs the §4 contract's substance (the
Tier-0-always-block floor and the Tier-0/1/2/3 gating table) as its rule set. The
§4 `block-subagent-tier-violation.sh` subagent-session-detection design is
superseded. The §4 subagent-only approval-evidence rows (Tier-1/2/3 "ALLOW only
if approval evidence / cascade_scope / standing authorization") are Phase-2
deferred — they need a session/approval signal the payload does not carry.**

1. **Name + trigger.** The canonical hook is `block-autonomy-ceiling.sh` — it
   conforms to the suite's `block-<concern>.sh` convention, describes the actual
   function (enforce the autonomy ceiling), and is collision-free. It triggers on
   the tool-call payload for the mutation matchers `Bash` / `Write` / `Edit` /
   `mcp__.*` (Read / WebFetch are non-mutating, out of scope). It gates
   parent-session AND subagent-session calls identically without depending on the
   unreadable `subagent_type` field — superior coverage to the subagent-only
   design, on a feasible substrate. The narrower `block-subagent-tier-violation.sh`
   name is rejected: §2's baseline row puts parent-session tool calls in-scope for
   the hook surface, so a "subagent" name mis-describes scope.

2. **Irreducible Tier-0 floor (always-block, mode + level independent).** Checked
   FIRST. Blocks regardless of `automation_level` and regardless of the hook's
   mode — the always-enforce class, mirroring `block-rm-prefer-trash`'s
   permanence. It enforces only the **payload-detectable** subset of the
   irreducible set: governance-file modification and cross-domain bridge writes
   (resolved from the Write/Edit `file_path` + `cwd`). The remaining irreducible
   classes — financial transactions, account creation, security-permission
   modification, and the Stage 9 / Stage 12 gates — are NOT mechanically
   detectable from a tool payload and stay **operator-irreducible by convention**,
   documented but not hook-enforced. Destructive-outside-workspace (item 8) is
   already owned by `block-rm-prefer-trash` and is NOT duplicated.

3. **Ceiling check (permissive default).** For mutations not caught by the Tier-0
   floor, the hook computes the action's required tier from a conservative
   **declared-mapping table** seeded from `autonomy-tiers.md` observable
   indicators (governance path → Tier 0; `08-Generated/` staging → Tier 2;
   stakeholder-facing write → Tier 1; `mcp__*` write-verb → Tier 1) and blocks
   (mode-gated) only when the required tier **exceeds** the ceiling. An
   **unmapped action is ALLOWED** — the load-bearing false-positive mitigation:
   C5 gates *every* mutation, so a deny-default would break the platform's routine
   work, whereas an un-gated action still runs through the 7 existing safety
   hooks. This inverts `block-destructive`'s deny-bias deliberately — deny-bias is
   retained only for the bounded, enumerated, high-confidence Tier-0 set.

4. **Own mode file + warn-initial.** The hook reads its **own** `.autonomy-mode`
   (not the shared `.mode`), shipping `.autonomy-mode.template` = `warn`. It has
   the highest false-positive risk of any hook (it gates every mutation), so its
   shakedown→enforce lifecycle is decoupled from the shared-`.mode` cohort and it
   ships warn-mode-initial per the suite shakedown convention. The Tier-0 floor
   always blocks regardless of mode.

5. **Session-stable cache.** The dial is session-stable, so it is resolved ONCE at
   SessionStart by `prime-autonomy-ceiling-cache.sh` (numeric ceiling cached at
   `${HOME}/.cache/pmo-platform/autonomy-ceiling`); the PreToolUse hook reads the
   cache rather than grep-ing `operator.toml` on every call, with a direct-resolve
   fallback so a missing cache never drops the ceiling.

6. **Corpus reconciliation.** `subagent-security-posture.md § 4` is rewritten to
   name `block-autonomy-ceiling.sh`, re-scope its trigger to the payload, mark it
   RESOLVED-in-v2.07, keep the Tier-0 row LIVE, mark the Tier-1/2/3 approval-
   evidence rows Phase-2 deferred, and point its mode reference at `.autonomy-mode`.
   `autonomy-tiers.md § Outbound consumers` "Future PreToolUse hooks" row is
   annotated with the resolved name + payload trigger (coordinated with C0's
   `[automation].automation_level` row that lands in the same file this release).

**Rejected alternatives.** (a) **Retain `block-subagent-tier-violation.sh` and
defer entirely** until a session signal exists — rejected: it leaves C0's dial
unenforced indefinitely on a premise (`subagent_type` readability) that is not
just absent but contradicted by the suite's own design, and the payload-triggered
floor is buildable today. (b) **Two separate hooks** (ceiling + subagent-tier) —
rejected: it leaves the corpus naming two designs for one surface and ships a
second hook that cannot fire. (c) **Infer tier from a `cascade_scope` /
approval-evidence signal in the payload, or require every skill to emit an
`autonomy_tier:` frontmatter field** — both rejected: neither signal exists in a
raw tool-call payload today (the `autonomy_tier:` frontmatter is itself a *future*
outbound), so both reproduce the unavailable-signal trap.

## Alternatives Considered

This record already carries an explicit **Rejected alternatives** paragraph at the end of § Decision, and § Context weighs the competing hook designs that targeted the same enforcement surface. Recorded here in the canonical section, selected option first:

| Option | Verdict | Why |
|---|---|---|
| **One payload-triggered `block-autonomy-ceiling.sh`** absorbing the §4 contract's substance | **SELECTED** | The payload trigger is the universal signal every hook already uses, and reading `operator.toml` at runtime has a working precedent. It gates parent-session and subagent-session calls identically without depending on the unreadable `subagent_type` field — superior coverage on a feasible substrate. |
| **The standard's deferred `block-subagent-tier-violation.sh`** (subagent-session detection) | Rejected | It rests on a trigger signal the hook layer cannot read: the same document states hooks do not read session-context fields, and a survey of the suite found zero hooks reading any session / subagent / transcript field. It would be a false-enforcement floor — it could not fire as specified. The narrower name also mis-describes scope, since parent-session tool calls are in-scope for the surface. |
| **(a) Retain the §4 design and defer entirely** until a session signal exists | Rejected | Leaves the autonomy dial unenforced indefinitely on a premise that is not merely absent but contradicted by the suite's own design, while the payload-triggered floor is buildable today. |
| **(b) Ship two separate hooks** (ceiling + subagent-tier) | Rejected | Leaves the corpus naming two designs for one surface and ships a second hook that cannot fire. |
| **(c) Infer tier from a `cascade_scope` / approval-evidence payload signal, or require every skill to emit an `autonomy_tier:` frontmatter field** | Rejected | Neither signal exists in a raw tool-call payload today (the frontmatter field is itself a future outbound), so both reproduce the unavailable-signal trap. |

One further alternative was weighed inside the selected design and is recorded in § Decision item 3: an **unmapped action is ALLOWED** rather than denied. A deny-default would break routine work because the hook gates every mutation, so the deny-bias of `block-destructive` is deliberately inverted here and retained only for the bounded, enumerated Tier-0 set.

## Consequences

- **Every mutation tool call now passes through `block-autonomy-ceiling.sh`** —
  the dominant blast surface. The required-tier determination is the main
  false-positive risk, mitigated by permissive-default + warn-mode-initial + the
  own mode file. The hook registers LAST per matcher, so the safety barriers
  evaluate first and are unaffected.
- **The corpus names one design.** `block-subagent-tier-violation.sh` no longer
  appears as a live proposal; both prior occurrences (in
  `subagent-security-posture.md`) are reconciled.
- **Tier-0 enforcement is real but bounded.** Governance-file and cross-domain
  writes are mechanically blocked at any level/mode; the non-payload-detectable
  irreducible classes remain convention-enforced. Documentation across C0's
  inline dial doc, §4, and the autonomy-tiers Outbound row is consistent on this
  scoping and never claims unqualified hard-enforcement.
- **A Phase-2 carry-forward is owed.** The subagent-only approval-evidence gating
  (Tier-1/2/3) is revisitable when/if `subagent_type` + an approval-evidence input
  become readable hook inputs (paired with the `pipeline-event-log.md`
  `event_subtype: subagent-invocation` substrate extension). Stage 13 files the
  carry-forward `improvement.yml`.
- **Composition is additive.** C5 does not re-implement destructive / fs-boundary
  / rm enforcement; it adds the autonomy-tier dimension the suite lacked and
  cross-references the existing hooks for the rest.

## Reversibility

**MODERATE** at ship, trending toward the warn-mode flip being the operative
control. The hook ships warn-mode-initial behind its own `.autonomy-mode`, so the
ceiling check is reversible by a single-file mode flip and the operator gates the
warn→enforce transition after shakedown. The doc supersession (rename + re-scope
in `subagent-security-posture.md` §4) is CHEAP to revert (revert the release PR).
The Tier-0 always-block floor is the one piece live-on-merge regardless of mode,
but it covers only the two payload-detectable classes already constrained
elsewhere (governance writes by `block-destructive` BLOCK-DESTRUCTIVE-019 in
non-worktree cwds; cross-domain writes by the operations-bridge rules), so its
incremental blast radius is small and bounded.

## Related ADRs

- **ADR-028** (operations consume core safety-controls via-public-api) — sibling
  pattern: one-owner-of-truth for a safety control; this ADR resolves
  one-named-design-of-truth for an enforcement surface.
- **ADR-029** (memory corpus-SSOT boundary) — same release-family Stage-6
  ADR-authoring precedent + the no-shadow-SSOT / one-source discipline applied to
  a design name rather than a memory fact.
- **ADR-020** (agent-script promotion ladder) — automation-governance sibling;
  C5 is the enforcement realization of the autonomy dial the promotion ladder and
  `autonomy-tiers.md` classify.

## References

- C5 enforcement-hook card (the authoritative AC contract): `#1163`.
- C0 `automation_level` dial keystone (the ceiling this hook reads): `#322`.
- Design source rewritten by this decision: `core/standards/subagent-security-posture.md` § 4 (Hook Contract — RESOLVED in v2.07).
- Tier framework + irreducible-human-tasks set this hook enforces: `core/specs/autonomy-tiers.md` § Irreducible Human Tasks + § Outbound consumers.
- Hook-layer conventions (exit-2 block, structured reason, mode-gating, always-enforce class, shakedown→enforce): `core/rules/bypass-mode-readiness.md`.
