---
title: External-Seam Conduct Discipline
purpose: The shape of an agent write to an external seam — a human-facing system the
  platform integrates with (a work-item record, a knowledge page, and their comment
  streams). Governs routing (record vs comment), the register prohibition, the
  authorship-not-staleness discriminator, the never-write field category, and the
  confidence gate. Platform-agnostic; names no vendor and no field.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
applies_to: any agent writing to an external seam (a work-item record or knowledge page
  in a connected system, and their comment streams); comms-writer; delivery-engine;
  daily-status; pmo-process-designer; intake-desk; health-check
parallel_to:
  - reconcile-dont-annotate.md        # same reconcile-vs-annotate family, different surface contract
  - decision-discipline.md            # §2.1.1 verify-before-recommend (stale-input recommendations)
  - review-discipline-principles.md   # no-status-theater sibling (documentation-without-resolution)
source: codification of an operator-confirmed behavioural contract authored for an agent
  operating on this class of seam; §2, §5 and §6 derive from it, §1, §3 and §4 close gaps
  it did not have to address. P2 / Reversibility CHEAP / Confidence HIGH
---

<!-- reference-durability: allow-link -->

# External-Seam Conduct Discipline

An **external seam** is a human-facing system of engagement the platform integrates with —
a work-item record, a knowledge page, and their comment streams. It is not the platform's
own work tracker, and the difference is not cosmetic: the two surfaces carry opposite
contracts, so the same act is diligence on one and noise on the other.

This discipline governs the **shape** of a write to that seam. It is deliberately silent on
whether a write may happen at all — that is a question of runtime permission and operator
configuration, and it is answered elsewhere. Where a write does happen, the six sections
below bind it.

**Instance detail stays out of this file.** Which systems this deployment connects to, which
fields are never-write there, and what the working budget resolves to are all instance state.
They live in the operator's own configuration and memory store per the memory↔corpus boundary
in [knowledge-architecture.md](knowledge-architecture.md) § 6, never in this corpus artefact.
A corpus copy of an instance fact is a shadow source of truth that drifts the moment the
deployment changes.

---

## § 1 — Routing: the record holds state, the comment addresses a person

**Durable state goes to the record's own field or body.** Not to a comment.

A comment is warranted **only when both** limbs hold:

1. it **addresses a person**, and
2. it **carries an ask or an answer**.

**Never narrate a state change the system's own changelog already records.** Moving a status,
reassigning an owner, or changing a date is recorded by the system, displayed in its history,
and attributed to the actor that made it. A comment restating it adds a second copy of a fact
the system already owns — one that diverges the moment anything moves again.

**The test.** *A comment that would still read correctly with no reader in mind is a register
entry, and it belongs in the record.* A comment written to a person reads as written to a
person; if the text works equally well addressed to nobody, it is state, not conversation.

---

## § 2 — The comment stream is not a register

- **One agent comment per record per run.** Updated in place on re-run; **never stacked**. A
  second agent comment below the first is the signature this section exists to prevent.
- **No dated log headers.** A date-led or heading-wrapped date opener is register formatting.
  The system already timestamps every comment.
- **No provenance narration.** Who generated it, which run, which pass, which model, which
  stage — none of it belongs in the comment. It is the platform's own audit vocabulary
  addressed to an audience that does not share it.
- **A working budget, stated as a ceiling, not a cap.** A comment that addresses one person
  with one ask is short. The budget's value resolves per deployment from operator config; a
  genuinely warranted detailed reply **may exceed it and say why**. Because the justification
  that makes exceeding it legitimate is not readable from the text itself, the budget is the
  one clause here that no mechanical check can adjudicate — see § 8.
- **Link, don't restate.** Where the content already exists at a durable home, the comment
  carries the pointer and the ask, not the copy.

---

## § 3 — Why the seam differs from the platform's own tracker

*This section states the root cause, so the idiom stops transferring.*

On the platform's own work tracker the comment stream **is** the audit trail of a governed
pipeline. The record body is a stable specification; stage evidence accrues beneath it as
timestamped comments; a dated, evidence-bearing comment is exactly right there, and it is
reinforced every time the pipeline runs.

An external seam inverts **both** halves:

| | Platform's own tracker | External seam |
|---|---|---|
| The record body is… | a stable specification | **the state** — mutated in place, versioned by the system |
| The comment stream is… | the audit trail | **conversation between people** |
| A dated evidence block is… | the required artefact | noise to every human reading the record |

Neither idiom is wrong. The failure is carrying one across a contract boundary, and nothing in
an agent's context marks where that boundary sits — which is what this document is for.

---

## § 4 — Additive-only vs reconcile: the discriminator is authorship, not staleness

- **Human-authored text is never overwritten**, however stale. Add beside it, and address the
  discrepancy to its author.
- **Stale agent- or system-authored state is reconciled in place**, per the reconcile-don't-
  annotate default.
- **Staleness alone never authorizes an overwrite**, and **freshness never protects
  agent-authored text from reconciliation**. The axis is who wrote it, not when.
- **Where authorship cannot be determined, treat the text as human-authored** and add rather
  than replace. The platform does not control the seam's history and cannot restore what it
  silently replaced.

This is the limb of the reconcile-don't-annotate default that does not survive the transfer to
a human-facing surface. That discipline governs an artifact the platform owns, where
reconciling in place is the whole point; here, ownership of the text is the precondition.

---

## § 5 — Never-write fields

A **category, not a list**. Two classes are never written by an agent:

- **Fields carrying human judgment** — an assessment, a rating, a priority call, a narrative
  the record's owner wrote.
- **Fields recording commitments made off-agent** — a date agreed in a meeting, an owner
  assigned by a person, a scope accepted in a conversation the agent was not part of.

**The specific field set resolves per deployment from operator config.** This document names
no field, because a field name is instance state: it is true of one deployment's configured
systems and false of the next, and a corpus copy of it is stale on arrival.

When a field's class is unclear, it is never-write. The cost of not writing is a proposal the
operator accepts; the cost of writing is a human's judgment silently replaced on a surface
other people read.

---

## § 6 — Confidence gates every write

| Confidence | Action |
|---|---|
| **HIGH** | **write** |
| **MEDIUM** | **propose** — draft it, surface it, let a person send it |
| **LOW** | **ask** |

**One `[ASSUMPTION – CONFIRM]` in a draft caps it at MEDIUM.** A draft resting on an
unconfirmed assumption is proposed, never written — because the write is visible to people
outside the session who have no way to see that a value was a guess.

The confidence value lives in the agent's reasoning and has no representation in the outgoing
payload, so nothing downstream can recover it. This section is the only gate on that axis.

---

## § 7 — Domain-specific failure modes

### Register-idiom transfer — PROC

- **Signature:** an agent comment on an external record opens with a bold or heading-wrapped
  date, and a second such comment sits below the first from an earlier run.
- **Conditional:** do NOT post a dated, evidence-bearing log entry when the destination is an
  external seam rather than the platform's own work tracker, because on that surface the
  record body is the state and the comment stream is conversation, so a register entry is
  noise to every human reading the record.
- **Root cause:** the idiom is correct and continuously reinforced on the platform's own
  tracker; nothing in the agent's context marks the contract boundary at which it stops being
  correct, so it transfers by default rather than by decision.
- **Mitigation:** route the content to the record's field or body; post a comment only where
  § 1's two-limb test holds; update the single prior agent comment instead of adding one.
- **Principal-vs-junior:** a junior posts the same well-formed block it would post on the
  platform tracker. A principal asks *who reads this, and what do they do with it* before
  choosing the surface.

### Changelog restatement — OUT

- **Signature:** a comment whose body says a status, assignee, or date moved — a transition the
  system's own history already records and displays.
- **Conditional:** do NOT narrate a field transition in a comment when the destination system
  records that transition in its own changelog, because the comment adds a second,
  immediately-divergent copy of a fact the system already owns.
- **Root cause:** the agent treats the comment stream as its own audit trail rather than
  reading the destination system as already having one.
- **Mitigation:** make the field change and stop. Where a person needs to know, the comment
  carries the **ask** the change raises, not the transition.
- **Principal-vs-junior:** a junior documents the change. A principal makes the change and asks
  the question the change raises.

### Staleness read as an overwrite licence — INPUT

- **Signature:** a human-authored field is replaced with agent-derived content, justified by
  the prior value being out of date.
- **Conditional:** do NOT overwrite text in an external record when its author was a person,
  because staleness is not an authorization and the platform cannot restore what it silently
  replaced on a system whose history it does not control.
- **Root cause:** the reconcile-don't-annotate default is correctly internalized but its scope
  is over-read — that default governs *agent- and system-authored* state, and the authorship
  limb is the part that does not survive the transfer to a human-facing seam.
- **Mitigation:** apply § 4 — reconcile agent/system-authored state in place; add beside
  human-authored text and address the discrepancy to its author. Where authorship is
  undeterminable, treat it as human.
- **Principal-vs-junior:** a junior sees a wrong value and corrects it. A principal asks whose
  value it is before deciding whether correcting it is theirs to do.

### Silent write under an unconfirmed assumption — HAND

- **Signature:** a write lands on an external record carrying a value the agent inferred, with
  no `[ASSUMPTION – CONFIRM]` surfaced to anyone.
- **Conditional:** do NOT write to an external seam when the value rests on an unconfirmed
  assumption, because the write is visible to people outside the session who have no way to
  see that it was a guess.
- **Root cause:** the confidence signal is held in the agent's reasoning and has no
  representation in the payload, so nothing downstream can catch it — § 6 is the only gate.
- **Mitigation:** apply § 6 — one assumption caps the draft at MEDIUM, and MEDIUM proposes
  rather than writes.
- **Principal-vs-junior:** a junior writes the best available value. A principal writes what it
  knows and asks for what it does not.

---

## § 8 — Hook: `block-external-seam-shape.sh`

This section is the hook's registry block. `block-external-seam-shape.sh` is **not** a member
of the bypass-mode security registry — it is a conduct hook, owned by this discipline, and it
declares so in its own `# hook-owner:` header line. The registry-external ownership pattern,
and the reason a conduct hook takes it rather than a per-hook readiness shard, are recorded in
the architecture decision record `{{ADR:external-seam-hook-owned-by-its-discipline}}` — the
readiness check classifies a hook as bypass-mode **iff** its declared owner is that hook's own
readiness shard, so a discipline owner and a shard cannot both be true of one hook.

| Field | Value |
|---|---|
| **Hook** | `core/hooks/block-external-seam-shape.sh` |
| **Owner** | this document (`core/disciplines/external-seam-conduct.md`) |
| **Matcher** | the harness's structured connected-system tool surface. The platform's own shell/CLI surface is **out of scope, unconditionally** — the platform's own tracker is reached that way, and excluding it is what makes the register prohibition **true** rather than merely strict |
| **Surface key** | a **write verb** in the tool name **and** a comment-class noun. Keyed on the verb because a verb is a property of the operation, not of a vendor; the verb vocabulary is the platform's own shipped MCP write-verb set. A noun-only key would match read-family tool names, which carry no content field and would trip the extraction arm on every read |
| **Scope** | the authored payload's own content fields. No vendor name, no server identifier, and no tool-name allowlist enters the hook — over-fitting to one system is what would defeat reuse |
| **Mode** | own mode file `.seam-shape-mode` (`warn` \| `enforce` \| `off`); initial **`warn`**. Deliberately **not** the shared cohort file: a flip-to-enforce here must promote this rule on its own evidence rather than dragging unrelated hooks with it |
| **Master-activation class** | `workflow` — inert while master activation is off |
| **Rule registry** | `BLOCK-SEAM-SHAPE-001..099` |

### Rule registry

| Rule | Fires on | Section it reaches |
|---|---|---|
| `BLOCK-SEAM-SHAPE-001` | **Dated log header** — the first non-blank line is a date-led line, bare or wrapped in bold/heading markup | § 2 |
| `BLOCK-SEAM-SHAPE-002` | **Provenance narration** — an agent/automation authorship or run-index idiom | § 2 |
| `BLOCK-SEAM-SHAPE-003` | **State-change narration** — a field-transition restatement | § 1 |
| `BLOCK-SEAM-SHAPE-004` | **Budget exceeded** — payload word count above the resolved budget. **Permanently warn-only**, on its own per-rule constant: § 2 states the budget as a ceiling a warranted reply may exceed, and the justification that makes exceeding it legitimate is absent from the payload. A hook that blocked on word count alone would enforce something this discipline does not say | § 2 |
| `BLOCK-SEAM-SHAPE-010` | **Extraction empty or unparseable** on an in-scope surface — fail-loud, never silent-allow. Detector integrity, not a discipline section |

### Coverage — stated as a ceiling, because it is one

The hook reaches **§ 2 substantially, § 1 partially, and § 3 / § 4 / § 5 / § 6 not at all.**

- **Register *stacking*** (a second dated comment below the first) is a property of the
  record's comment **history**. A pre-tool-use hook sees one outgoing payload and cannot read
  it.
- **§ 3** is rationale; there is nothing to detect.
- **§ 4 is unreachable in principle** — its discriminator is the *authorship of the text being
  overwritten*, and the hook sees only the outgoing payload.
- **§ 5 is unreachable** — the never-write field set resolves from operator config, and the
  hook is deliberately configuration-blind.
- **§ 6 is unreachable** — confidence lives in the agent's reasoning, not in the payload.

**The discipline is the rule; the hook is a register-shape detector for the part with a payload
signature.** Sections 3, 4, 5 and 6 are prose-declared normative predicates with **Runner:
NONE** — no gate executes them, and saying so is the point: a miss is countable rather than
invisible. The load-bearing enforcement for those sections is this document's citation in the
skill definitions that write to a seam.

### Limitations

- **The shell/CLI surface is uncovered, full stop.** A seam write issued through a vendor CLI
  or a raw HTTP call does not reach this hook. That exclusion is deliberate — it is what keeps
  the platform's own tracker out of scope — and it is a genuine residual, not one bounded by a
  neighbouring control. The egress guard is not that bound: its upload rule fires only toward a
  non-allowlisted host, it reads the shared cohort mode file, and neither of its rules reaches a
  vendor CLI at all.
- **No mode-file template ships.** The hook's mode reader returns `warn` when the file is
  absent, so the shipped default is the absent-file default. This matches the sibling hook that
  also ships without one.
- **Writing `off` to the deployed mode file is an operator action, not an agent action.** The
  runtime mode file sits beside the deployed hooks, inside a path the autonomy-ceiling floor
  blocks unconditionally. The kill switch is genuinely CHEAP — one line in one file — but the
  governed form is the Hook-Blocked → User-Side Handoff template, not an agent write.

---

## § 9 — Composition

| Surface | Relationship |
|---|---|
| [reconcile-dont-annotate.md](reconcile-dont-annotate.md) | **SIBLING.** Same reconcile-vs-annotate family, different surface contract. That discipline's default governs an artifact the platform owns; this one governs a human-facing external seam, where the discriminator is **authorship, not staleness** (§ 4). Neither restates the other. |
| [decision-discipline.md](decision-discipline.md) § 2.1.1 | Verify-before-recommend. Upstream of § 6: a value derived from a stale input is not HIGH confidence, whatever the draft asserts. |
| [review-discipline-principles.md](review-discipline-principles.md) | No-status-theater. § 1 and § 2 are its external-seam instance: a comment that recaps a state the system already records is theater on a surface where people are the audience. |
| [knowledge-architecture.md](knowledge-architecture.md) § 6 | The memory↔corpus boundary. Owns the rule that the instance detail this document deliberately omits — which systems, which fields, which budget value — belongs in the operator's own store, never here. |
| [`decision-time-adherence.md`](/core/rules/decision-time-adherence.md) | Carries the checkpoint that surfaces this discipline at the moment a write to a seam is about to happen. That index owns when the checkpoint fires and what is emitted; this document owns what the write must look like. |
| [`CLAUDE.md.template`](/core/CLAUDE.md.template) § Universal Preferences | Carries a one-line signpost citing this discipline. The signpost is a pointer, not a mechanism — the mechanisms are the skill bindings, the checkpoint, and the hook. |
