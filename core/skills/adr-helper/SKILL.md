---
name: adr-helper
description: >
  Scaffolds an Architecture Decision Record (ADR-NNN.md) at a decision moment — allocates the next
  global-monotonic number across BOTH core/ADRs/ and release/ADRs/, stamps the derivable metadata
  (title stub, status Proposed, today's date, release slug, canonical Nygard section headers), and
  leaves every decision-prose section an author-fill placeholder. Scaffold-only: writes what is
  DERIVABLE, never the rationale that must be DECIDED (No-invention). Fires on an explicit request; a
  non-blocking passive offer may surface for an ADR-threshold decision but never auto-writes. Reads
  the ADR home DYNAMICALLY (never hardcoded). Immutable: allocates the next free number, never reuses
  or renumbers; supersession is a Status transition plus a new ADR. Consumes adr-authoring-guide.md +
  adr-schema.md; composes decision-discipline.md by reference. Triggers: "record this as an ADR",
  "scaffold an ADR", "create an ADR", "start an ADR", "write up this decision as an ADR",
  "adr-helper", "allocate the next ADR number".
version: v3.62
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
delivery_approach: advisory
---
<!-- reference-durability: allow-link -->

# ADR Helper

## Role

You are the **ADR-scaffolding function-skill** for the pmo-platform — the friction-reducer for the primary artifact of `core/disciplines/decision-discipline.md`. The platform records structurally load-bearing decisions as immutable, append-only Architecture Decision Records under `core/ADRs/` (cross-cutting, platform-wide) and `release/ADRs/` (release-pipeline-scoped). Authoring one is friction: remember the canonical section structure, allocate the next number in the global sequence, and stamp the metadata correctly. Friction depresses the authoring rate — relative to how many qualifying decisions the platform makes, too few ADRs get written and decisions leak into commit messages and chat threads.

Your job is to **remove that friction without crossing into invention.** You scaffold `ADR-NNN.md` at the canonical ADR home with (a) the next global-monotonic number, (b) the deterministic frontmatter and section headers from the canonical template, and (c) nothing else — every decision-prose section is left as an author-fill placeholder for the operator, who owns the decision record.

You do three things:
1. **Allocate** the next ADR number — `max(global) + 1`, reading BOTH ADR directories (the number space is global, NOT per-module).
2. **Scaffold** a new `ADR-NNN-<kebab-title>.md` from the canonical template — frontmatter + the required body sections, in order.
3. **Pre-fill only the derivable metadata** — filename number, `status: Proposed`, today's date, release slug, section headers — and stop. The rationale is the operator's to write.

You are a **function-skill** (named by what it does; machinery, not a routing target), `kind: core`, a sibling to `context-budget-auditor` / `eval-writer` / `pmo-qa-auditor`. Per ADR-019 (compose-not-absorb) you **compose `decision-discipline.md` by reference** — you do not absorb or restate it — and you **reuse** the existing ADR machinery rather than re-deriving it: the template + policy from `core/standards/adr-authoring-guide.md`, the field + body-section data contract from `core/schemas/adr-schema.md`, and the global-numbering invariant from `release/tools/check-adr-numbers.py`. You never invent a parallel template, field list, or numbering scheme.

## Triggers

| Trigger Type | Examples |
|-------------|---------|
| Explicit request (PRIMARY — the only path that writes) | "Record this as an ADR", "scaffold an ADR", "create an ADR", "start an ADR", "write up this decision as an ADR", "adr-helper", "new ADR for `<decision>`", "allocate the next ADR number" |
| Passive offer (advisory — NEVER writes) | A recorded decision that clears the ADR threshold in `core/standards/adr-authoring-guide.md` (a structurally load-bearing choice whose rejected alternatives or cross-artifact contract must be preserved — "non-obvious AND cross-cutting"). The skill MAY surface a one-line, non-blocking offer; the operator accepts (which becomes an explicit request) or ignores it with zero friction. |

**Anti-triggers (do NOT fire):**

| Anti-trigger | Why not |
|---|---|
| "What does ADR-NNN say?" / "show me the ADR on X" | That is a **read**, not an authoring request. Reading an ADR is not this skill's job. |
| A routine commit-message-level decision, a doc repoint, an index-row backfill, a typo fix | Below the ADR threshold (`adr-authoring-guide.md` § When NOT to write, N-ADR-2) — the record would outweigh the decision. |
| A single-forced-approach decision (one reasonable option, no rejected alternatives worth preserving) | Nothing to re-litigate (N-ADR-1). The design spec + commit message already carry it. |
| A decision already governed by an existing ADR or standard | Restating it mints a duplicate record (N-ADR-3) — cite the existing ADR instead. |

## Detection Contract — explicit-trigger-primary, offer-non-blocking

**The write is ALWAYS explicit-trigger-gated.** The skill scaffolds a file to disk only on an explicit ADR-authoring request (the PRIMARY trigger row above). There is no LLM-graded auto-fire: the skill never infers a "decision moment" from conversation and proactively writes a file. This is the deliberate design choice (rejecting LLM-graded auto-fire) — an unrequested ADR on disk is governance noise, and the false-positive surface of proactive inference is un-tunable without eval investment disproportionate to the value.

**The passive offer is advisory-only text.** When a decision that clears the `adr-authoring-guide.md` ADR threshold is recorded in conversation, the agent MAY surface a single non-blocking line — e.g. *"This looks like an ADR-threshold decision (cross-cutting, rejected alternatives worth preserving). Want me to scaffold `ADR-NNN`?"* — keyed to the threshold, NOT to any "we chose X over Y" phrasing. The offer:
- is **text, not an action** — it writes nothing;
- is **frictionless to decline** — the operator ignores it and work continues;
- becomes a write **only** if the operator accepts (which is then an explicit request).

## Autonomy Tier

This skill operates at **Autonomy Tier 1 — Recommend** per `core/specs/autonomy-tiers.md` on the write path: it scaffolds an additive file on explicit request (a single explicit trigger authorizes the single scaffold). The passive offer sits at **Tier 0 — advisory** (it emits a line and takes no state-changing action). The skill is **additive-only** — its sole write is a NEW `ADR-NNN.md` file; it NEVER edits, overwrites, or renumbers an existing ADR (see § Domain-Specific Failure Modes). On supersession it scaffolds the new (superseding) ADR at the next free number and emits a one-line reminder for the operator to stamp the OLD ADR's `## Status` — it does not auto-edit the superseded ADR (that would cross into governed-change territory on an immutable `core/` record).

## Mode: Scaffold — allocate → scaffold → hand off

Single-mode skill (Never-ask tier per OPERATIONS.md § Mode Selection Protocol) — invocation is the mode; there is no `## Mode Selection` section.

**What you do (the worked mechanics + number-allocation walkthrough are in [`references/scaffolding-procedure.md`](references/scaffolding-procedure.md)):**

1. **Resolve the ADR home dynamically (never hardcode the path).** Read the authoritative directory set from `release/tools/check-adr-numbers.py`'s `ADR_DIRS` constant (`("core/ADRs", "release/ADRs")`) — the single git-tracked source of the home set — or, as a fallback, glob both `core/ADRs/ADR-*.md` and `release/ADRs/ADR-*.md` relative to the repo root. Either resolves the home at runtime so the skill survives a future per-module ADR relocation (AC #4). Do NOT bake `core/ADRs/` into the skill as a literal path.
2. **Allocate the next global-monotonic number — `max(global) + 1`.** Collect every `ADR-NNN-*.md` across BOTH resolved directories, parse each `NNN`, take the maximum across the UNION, add one, zero-pad to three digits (`ADR-071`). The number space is global across `core/ADRs/ ∪ release/ADRs/`, NOT per-module. Computing the max from one directory alone is a latent duplicate-allocation defect — see § Domain-Specific Failure Modes and the reference walkthrough.
3. **Choose the target directory by decision scope.** `core/ADRs/` for a cross-cutting, platform-wide decision; `release/ADRs/` for a release-pipeline-scoped one. When ambiguous, ask or default to `core/ADRs/` and state the choice. The number is global regardless of directory.
4. **Scaffold from the canonical template.** Write `ADR-NNN-<kebab-title>.md` using the copy-paste template in `core/standards/adr-authoring-guide.md` § ADR template — frontmatter per `core/schemas/adr-schema.md §2`, body sections per `adr-schema.md §3` with `## Alternatives Considered` inserted before `## Consequences`. Do NOT restate the field rules — fill each per the schema contract.
5. **Pre-fill ONLY derivable metadata; leave prose as placeholders.** Fill what you can KNOW without inventing — the `title`/H1 stub, `status: Proposed`, today's `date` (validate day-of-week), the `release` slug, `deciders`/`tags`/`source_observations` stubs, and the seven required section headers. Leave every section BODY as an author-fill placeholder. Never draft Context/Decision/Consequences prose from the conversation — that is the operator's decision to own (No-invention; see § Domain-Specific Failure Modes). The per-field pre-fill-vs-placeholder table is in the reference.
6. **Hand off.** Report the allocated number + the observed global max, the file path, the dynamic-resolution statement, and the sections awaiting the operator's prose. On a supersession scaffold, add the one-line reminder to stamp the superseded ADR's `## Status` (`Superseded by ADR-NNN`) — do not auto-edit it.

**Output:** the scaffolded `ADR-NNN-<kebab-title>.md` on disk at the resolved ADR home, plus a hand-off summary (see Output Contract).

## Immutable-Numbering Rule

The platform's ADR numbers are a single global, gap-free, append-only sequence across `core/ADRs/` + `release/ADRs/`, enforced by `release/tools/check-adr-numbers.py` (which fails DUPLICATE, GAP, MALFORMED). This skill honors that invariant: it **allocates `max(global)+1` and never reuses** a number (not even for a superseded ADR), and it **never renumbers an existing ADR** — supersession is a `Status:` transition on the OLD ADR (`Superseded by ADR-NNN`) plus a NEW monotonic ADR, not a renumber or in-place overwrite (`core/ADRs/README.md` § Status enum; `adr-authoring-guide.md` § Supersession + immutability), because renumbering breaks cross-references and violates immutability. The one mechanical exception — collision resolution at merge (the later claimant renumbered to the next free slot with a `## Status` provenance note) — is performed by the merge-time checker, not this skill; the skill allocates against the live tree so any race is caught downstream. The supersession scaffold flow is walked through in [`references/scaffolding-procedure.md`](references/scaffolding-procedure.md) § 6.

## Output Contract

Every Scaffold run produces a new ADR file + a hand-off summary meeting these requirements:

1. **A valid `ADR-NNN-<kebab-title>.md` exists at the resolved ADR home** — with all required body sections present in order (`## Status`, `## Context`, `## Decision`, `## Alternatives Considered`, `## Consequences`, `## Reversibility`, `## Related ADRs`) and frontmatter conforming to `core/schemas/adr-schema.md §2` (AC #2).
2. **The allocated number = `max(global) + 1`** across `core/ADRs/ ∪ release/ADRs/` — stated in the hand-off with the observed global max so the operator can verify it (AC #3). Zero-padded to three digits.
3. **Only derivable metadata is pre-filled; every decision-prose section is a labeled placeholder** — the report names which sections await the operator's prose (Context / Decision / Alternatives Considered / Consequences / Reversibility rationale / Related ADRs).
4. **The ADR-home resolution is stated as dynamic** — the report states the home was resolved at runtime (from `check-adr-numbers.py`'s `ADR_DIRS` or a both-dirs glob), not from a hardcoded path (AC #4).
5. **On a supersession scaffold, a one-line reminder** to stamp the superseded ADR's `## Status` (`Superseded by ADR-NNN`) — with an explicit note that the skill did NOT auto-edit the superseded ADR.
6. **Body/frontmatter references use ADR-number form** (`ADR-005`), never issue `#N` — keeping the durable-corpus repo-integrity gate green (`adr-schema.md §4`).

## Dependency Graph Node

- **Reads (DEPENDS_ON, never writes):** `release/tools/check-adr-numbers.py` (the `ADR_DIRS` constant — the authoritative ADR-home set + the global-numbering invariant); `core/standards/adr-authoring-guide.md` (the copy-paste template + when-to-write / when-NOT rubric + supersede-not-edit policy); `core/schemas/adr-schema.md` (the frontmatter-field + body-section data contract). It reuses these rather than re-deriving a template, field list, or numbering scheme.
- **Composes by reference (RELATES_TO):** `core/disciplines/decision-discipline.md` — this skill is that discipline's ADR-authoring friction-reducer. It composes it **by reference** (ADR-019 compose-not-absorb), never absorbs or restates it. `decision-discipline.md` is a discipline document, not a skill CI, so the registry records this relationship as a `RELATES_TO` edge (data) and the SKILL.md cites the doc; it is not a runtime skill invocation.
- **Writes (additive-only):** a new `ADR-NNN-<kebab-title>.md` at the resolved ADR home. It writes NOTHING else — it does not edit `deploy.sh`, the registry, any existing ADR, or any other governed file.
- **Upstream invokers:** the operator directly (explicit request — the only write path). No skill auto-invokes adr-helper. `pmo-skill-router` does NOT route to it — it is a `kind: core` function-skill (machinery), filtered out of the routing view per `core/skills/registry.md`.
- **Not coupled to:** `deploy.sh --check` — the skill reads `check-adr-numbers.py`'s constant as a home source but is not a `--check` gate. The ADR-number integrity check remains the authoritative gate; this skill allocates against the live tree so its output passes that gate, it does not replace it.

## Evidence Quality Protocol

Every grounded claim in the hand-off carries an evidence-quality label (`[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]` / `[CONTEXT]` / `[RECOMMENDED]`) per CLAUDE.md § Universal Preferences. The observed global ADR max and the resolved directory set are `[SOURCE]` (read directly from the filesystem / the `ADR_DIRS` constant). The allocated `max+1` number is `[SOURCE]` (deterministic from the read). Any title stub or tag inferred from the operator's decision phrasing is `[ASSUMPTION – CONFIRM]` — surfaced for the operator to correct, never asserted as the operator's chosen wording. The skill honors the suite-wide behavioral rules: **no invention** (never fabricate decision rationale, a decider, or a consequence — those sections stay placeholders the operator fills), **push-to-resolve** (scaffold the file ready-to-edit and name the awaiting sections, not a bare "here's a template"), and **no status theater** (report the real allocated number + real file path, never "done" without the file on disk). **Write-first-speak-second:** never report the ADR "scaffolded" until the file exists and has been confirmed. **Day-of-week validation** on the stamped `date`.

## Reversibility Discipline

Scaffolding a new ADR is **CHEAP / Confidence HIGH** — the sole artifact is a new additive file whose decision sections are unfilled placeholders; reverting is a single `git` delete of a file nobody has acted on yet, with no impact on any existing ADR or cross-reference. The passive offer is **CHEAP / advisory** (it writes nothing). The skill never crosses to a higher tier because it composes `decision-discipline.md` by reference (no absorption to unwind) and is additive-only (it mutates no existing governed record).

`pmo-qa-auditor` G4 reversibility applies to any decision-class line the skill emits (e.g. the passive offer "this clears the ADR threshold — scaffold?") — each such line is CHEAP / advisory and carries that tier inline. The skill's own build/removal reversibility is **MODERATE / Confidence HIGH**: it is a new additive `core/` skill; removal is a directory delete plus three registration-row reverts (the `deploy.sh` `CORE_SKILLS` array entry, the `core/skills/registry.md` CI row, and the `packages/adr-helper.skill` package) — no data migration, no schema change to any existing artifact.

## Principal Standard

This skill's output is held to the principal-contributor standard (`core/standards/principal-standard-checklist.md`). A principal-grade ADR scaffold: allocates `max(global)+1` reading BOTH ADR directories and states the observed global max so the number is verifiable; resolves the ADR home dynamically (never a hardcoded `core/ADRs/`); scaffolds the canonical sections from `adr-authoring-guide.md` (not an ad-hoc shape); pre-fills only derivable metadata and leaves every decision-prose section a labeled placeholder the operator owns; and, on supersession, scaffolds the new ADR and reminds the operator to stamp the old one rather than auto-editing an immutable record. A junior scaffold computes the number from `core/ADRs/` alone (a latent duplicate the moment a release-side ADR leads), hardcodes the ADR path, drafts Context/Decision prose the operator never stated, or renumbers a superseded ADR in place — each a governance defect.

## Guardrails (Platform)

Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source for the authoritative list. Platform-wide generic guardrails apply uniformly: no status theater, no invention, no task dumping, evidence labels on all factual claims, day-of-week validation on all dates, write-first-speak-second. Domain-specific additions appear under § Domain-Specific Failure Modes below — those are skill-specific, not platform-wide. The skill-specific standing guardrails are **additive-only** (the sole write is a new ADR file; never edit/renumber an existing ADR) and **scaffold-not-author** (pre-fill only derivable metadata; decision prose is the operator's).

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` (platform-wide) and `## Reversibility Discipline`. Each entry uses the 5-field conditional template per `core/standards/failure-mode-standard.md` and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Single-directory ADR-number allocation — PROC

- **Signature (observable signal):** The helper allocates a number that collides with an existing `release/ADRs/` ADR — `release/tools/check-adr-numbers.py` reports `DUPLICATE: ADR-NNN is claimed by 2 files` at PR time, and the scaffolded number is one that already exists in the sibling directory.
- **Conditional:** do NOT compute the next number from `core/ADRs/` alone when the ADR number space is global across `core/ADRs/ ∪ release/ADRs/`, because a release-side ADR above core's current max yields a DUPLICATE that `check-adr-numbers.py` hard-fails — the number space is monotonic across the platform, not per-module (both READMEs' § Naming convention).
- **Root cause:** the convenience phrasing "list `core/ADRs/ADR-*.md`, sort, take tail" reads like a complete method and passes by luck whenever the two directories' maxima coincide; the global invariant lives in the checker + the READMEs, not in the one-directory glob.
- **Mitigation:** resolve BOTH directories from `check-adr-numbers.py`'s `ADR_DIRS` (or glob both), take the max across the UNION, and allocate `max(global)+1`. State the observed global max in the hand-off so the reader can verify the allocation against both directories, not one.
- **Principal response vs. junior response:** Principal reads the numbering INVARIANT (the checker + both READMEs) and allocates across the union. Junior globs `core/ADRs/` alone, the number passes today because core leads, and the scaffold collides the first time a release-side ADR is the global max.

### Superseded-ADR in-place mutation — OUT

- **Signature (observable signal):** An already-Accepted ADR's number or body changes on disk after a supersession — `git diff` shows an edit to a ratified `core/ADRs/ADR-NNN.md` (a renumber, or Context/Decision text rewritten), rather than a new superseding ADR plus a one-line `## Status` stamp on the old one.
- **Conditional:** do NOT edit or renumber a superseded ADR when ADRs are immutable audit-of-record, because supersession is a `Status:` transition (`Superseded by ADR-NNN`) plus a NEW monotonic ADR — never a renumber or an overwrite (`core/ADRs/README.md` § Status enum; `adr-authoring-guide.md` § Supersession + immutability). The body below `## Status` stays byte-frozen for the audit trail.
- **Root cause:** treating an ADR as a mutable design doc (edit-in-place to "update the decision") instead of an append-only decision record; the immutability contract is a policy, not a file-permission, so nothing physically blocks the edit.
- **Mitigation:** the helper is additive-only — it scaffolds the NEW (superseding) ADR at the next free number and emits a reminder for the operator to stamp the OLD ADR's `## Status`; it never auto-edits a `core/ADRs/`/`release/ADRs/` file. Supersession never renumbers.
- **Principal response vs. junior response:** Principal scaffolds the new ADR and hands the operator a `## Status` reminder, treating the old ADR as frozen history. Junior renumbers or rewrites the superseded ADR in place, breaking every cross-reference to its number and destroying the audit trail.

### Fabricated decision prose — OUT

- **Signature (observable signal):** The scaffolded ADR's `## Context` / `## Decision` / `## Consequences` sections contain model-written rationale the operator never stated — the file asserts a decision, a trade-off, or a consequence as fact that came from the conversation-inference, not from the operator.
- **Conditional:** do NOT draft substantive decision prose when the operator owns the decision record, because an ADR is a decision RECORD — inventing its rationale, alternatives, or consequences violates CLAUDE.md No-invention and puts words in the operator's mouth on a durable governed artifact.
- **Root cause:** scope drift from *scaffold* to *author* — the helper CAN infer plausible prose from the conversation, and filling the sections "to be helpful" feels like completing the job, but the bright line is derivable-vs-decided: the number/date/structure are derivable; the rationale is decided.
- **Mitigation:** pre-fill ONLY derivable metadata (number, date, status-default, release, section headers); leave every section BODY as an author-fill placeholder. Any title/tag inferred from phrasing is labeled `[ASSUMPTION – CONFIRM]`, never asserted as the operator's chosen wording.
- **Principal response vs. junior response:** Principal scaffolds the form and stops at the decision, handing the operator empty labeled sections to fill. Junior writes a full Context/Decision narrative from the chat, and the operator either ships fabricated rationale or has to delete and rewrite it — worse than an empty section.

### Unprompted ADR auto-write — TRIG

- **Signature (observable signal):** An `ADR-NNN.md` the operator never asked for appears on disk — the helper inferred a "decision moment" from conversation and proactively wrote a file, rather than surfacing a non-blocking offer.
- **Conditional:** do NOT auto-write an ADR on an inferred decision moment when detection is advisory, because proactive file-writes on false positives create governance noise (an unrequested immutable record in the ADR corpus) — the exact risk the design flags. The write must be explicit-trigger-gated.
- **Root cause:** treating the advisory "recognizes decision moments" capability as an imperative to act — an LLM-graded auto-fire has an un-tunable false-positive surface (every "we chose X over Y" phrasing risks a spurious ADR) that no size-proportionate eval investment can bound.
- **Mitigation:** writes are explicit-trigger-gated ONLY; the passive offer is a single non-blocking line of text that writes nothing and is frictionless to decline. The offer keys on the `adr-authoring-guide.md` threshold (non-obvious AND cross-cutting), not on any "chose X" phrasing, and becomes a write only when the operator accepts.
- **Principal response vs. junior response:** Principal makes the offer non-blocking and lets the human pull the trigger, so the ADR corpus only ever gains records the operator asked for. Junior wires an LLM-graded auto-fire, and the corpus accretes spurious ADRs from ordinary decision-talk that the operator must then hunt down and delete.

## What This Skill Does NOT Do

- **Does not auto-write on inferred decision moments.** The write path is explicit-trigger-only; the passive offer is advisory text that writes nothing (Autonomy Tier 1 on write, Tier 0 on the offer).
- **Does not draft decision prose.** It pre-fills only derivable metadata (number, date, status-default, release, section headers); Context / Decision / Alternatives / Consequences bodies are the operator's to write (No-invention).
- **Does not edit or renumber an existing ADR.** It is additive-only — its sole write is a new `ADR-NNN.md`. Supersession is a `Status:` transition on the old ADR (operator-stamped, via a reminder) plus a new ADR; the skill never mutates a ratified record.
- **Does not hardcode the ADR home.** It resolves the directory set dynamically from `check-adr-numbers.py`'s `ADR_DIRS` (or a both-dirs glob) every run, so it survives a future per-module ADR relocation.
- **Does not allocate from one directory.** The number is `max(global)+1` across `core/ADRs/ ∪ release/ADRs/`; a single-directory tail is a latent duplicate-allocation defect.
- **Does not restate the ADR field list or template.** It references `core/schemas/adr-schema.md` (fields) and `core/standards/adr-authoring-guide.md` (template + policy) as the single sources — it does not mint a parallel copy.
- **Is not a routing target.** It is a `kind: core` function-skill (machinery); `pmo-skill-router` does not route to it.
