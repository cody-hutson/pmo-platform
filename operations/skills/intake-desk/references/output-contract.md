<!-- reference-durability: allow-link -->
# Output Contract

How the desk emits a well-formed, correctly-typed work item to the configured work
tracker — never a tracked scratch file. This is the contract that closes the
originating defect (a scratch draft committed for lack of a funnel). The type
registry and the field-derivation contract are in `references/type-map.md`; the loop
that produces the rendered body is in `references/elicitation-loop.md`.

The contract is framed in two layers: a **tool-agnostic intake-emit process** (the
same regardless of target tracker), and an **MVP target binding** (GitHub Issues
today) that carries the tool-specific mechanics. The intake process and the
elicitation are the same across tools; only the documentation to the corresponding
work item is what each tracker accommodates.

## The emit invariant

The skill has NO write path to a tracked file. The only persistence paths are (1) the
work item logged to the configured tracker **after** an explicit binary approval, or
(2) the chat-returned copy/paste body block when the tracker CLI is unavailable or the
user declines auto-create. There is no `08-Generated/` staging file, no scratch `.md`
in the repo, no temp file left in the tree. The single mutable artifact at emit is a
throwaway body file passed to the tracker CLI via a process-local temp path that is
not committed.

## The tool-agnostic intake-emit process

This sequence is identical regardless of target tracker. The section titles use "work
tracker" / "work item" / "item reference", not a specific tool's nouns.

1. **Render.** Build the item body against the target type's field set — derived at
   use time from its `.github/ISSUE_TEMPLATE/<type>.yml` per `references/type-map.md`
   (all required fields populated, or explicitly marked `[ASSUMPTION – CONFIRM]` for
   deferrable fields, or "None — …" where the template allows it). Include the
   owned-assumption block (see § Assumptions-as-owned-items) so every unresolved
   unknown is a stage-owned body item before confirm. Carry structured-field values
   that a freeform body cannot set per § Structured-field carriage. **Render the title
   as an informative summary** per [`intake-style-guide.md`](../../../../release/references/how-to/intake-style-guide.md) §7 —
   names the object + the change, no `[...]:` type/category prefix (type is on the
   label, not the title).
2. **Gate.** Run the 5-test (T1–T5 per `references/elicitation-loop.md`) as the clarity
   gate, **plus a title-informativeness check** against `intake-style-guide.md` §7
   (no bracket prefix; names object + change; not a bare slug) before the confirm.
   If any test fails and cannot be resolved after one re-elicitation, route to
   the observation tier rather than emit a malformed typed item.
3. **Confirm (AskUserQuestion).** Present the rendered body plus the 5-test verdict,
   then obtain an explicit binary approval via AskUserQuestion (see § Confirm gate).
   The skill proposes; the human confirms what gets logged. This is Autonomy Tier 1 —
   no auto-emit without the binary approval. State the reversibility tier on the emit
   recommendation (a logged item is CHEAP — close or delete it).
4. **Log.** On approval, write the confirmed body to a process-local temp file and run
   the configured tracker's create command (the MVP binding is GitHub — see below)
   with the title (an informative summary per [`intake-style-guide.md`](../../../../release/references/how-to/intake-style-guide.md) §7 —
   no type/category prefix; type travels on the label, not the title) and the labels
   the type declares.
5. **Read back.** Read the created item and confirm it landed — state is open, the
   labels are present, and the in-body-carried structured fields are present. A
   read-back mismatch halts and reports which field failed to land.
6. **Report.** Report the item reference (URL / ID) to the user.

## Confirm gate (AskUserQuestion) + auth capture

- **The confirm gate uses AskUserQuestion** with a binary option set — e.g. options
  **"File it as shown"** / **"Let me edit first"**. The skill renders the full item
  body in the message preceding the question so the user reviews the actual payload,
  then answers the binary. AskUserQuestion is used here because the decision is
  genuinely binary and discrete — the correct condition for reaching for it (it is a
  mechanism, not a trigger).
- **Auth capture also uses AskUserQuestion.** When the skill needs the user to
  authorize the actual create call (the externally-observable mutation), it captures
  that authorization with a binary AskUserQuestion — e.g. **"Create the item now"** /
  **"Give me the copy/paste block instead"** — making auth easy and binary rather than
  a free-text confirmation the agent has to parse.
- **No auto-emit, ever.** The only persistence paths remain the post-approval logged
  item or the copy/paste-ready body. There is no write path to a tracked scratch file
  (the originating-defect invariant).
- **Scope of this gate.** This AskUserQuestion confirm governs the **interactive**
  modes (A/B), where a human is present. The **non-interactive** ambient path
  (Mode C) substitutes a standing `automation_level` ceiling + a Tier-0 floor for the
  binary confirm — see § Mode C — non-interactive emit below. That substitution does
  NOT relax the interactive gate, and it does NOT touch the emit invariant.

## Mode C — non-interactive emit

Mode C (Ambient Auto-Log, `SKILL.md` § Mode C) drives the **same emit process above**
with **one substitution**: the human `AskUserQuestion` confirm is replaced by a
standing `operator.toml [automation].automation_level` ceiling plus the Tier-0
never-auto floor. Everything else — Render, Gate (5-test + title-informativeness),
Log, Read back, Report, and the § Structured-field carriage rules — is **reused
verbatim**. There is **no parallel emit schema** and **no new persistence surface**:
the § The emit invariant above holds absolutely for Mode C (the only persistence
paths remain the logged item or the chat-returned copy/paste body; no scratch `.md`).

**Confirm-gate substitution (per `automation_level`):**

- `off` — author nothing, create nothing; return a structured **"signal detected,
  held — dial is off"** record to the caller so the signal is surfaced, not dropped.
- `recommend` — run Render + Gate, then **surface** the rendered body **plus the exact
  `gh issue create` command** to the caller; do NOT run Log. (The `recommend`
  equivalent of the no-tracker fallback body, produced proactively.)
- `bounded_auto` — run the full create path (Render → Gate → Log → Read back →
  Report) **without** the AskUserQuestion, **unless** the Tier-0 floor forces
  surface-only.

**Tier-0 floor.** Before the Log step, classify the implied item against
[`core/specs/autonomy-tiers.md` § Irreducible Human Tasks](../../../../core/specs/autonomy-tiers.md)
(governance-file / financial / security-permission / RAID-close / …). On any hit,
downgrade to the `recommend` (surface-only) path even at `bounded_auto`. This floor is
a **skill-level self-limit** — the C5 enforcement hook (#1163) hard-blocks only the
payload-detectable Tier-0 classes (governance-file writes / cross-domain bridge
paths), and Mode C's `gh issue create` is not payload-detectable, so **no hook fires
on this create**. The classifier is the only guard; run it unconditionally.

**Non-interactive self-repair → observation downgrade.** With no operator to fix a
failed Gate, Mode C **re-authors once** from the structured signal input on a fixable
failure (a vague field, a non-informative title, a read-back mismatch). If it still
fails, it **downgrades to the observation tier** (the § Observation-tier fallback
below — reused, not reinvented): render as `observation.yml`, emit under the same
`automation_level` clamp, and record that it was filed as an observation placeholder
for Triage to promote. Never emit a malformed typed item; never silently drop the
signal.

**Honest note (do NOT soften):** substituting the per-item human confirm with a
standing dial is a **genuine reduction** of the confirm-gate guarantee (a per-item
approval becomes a standing class-authorization) — bounded (auto-create is
`bounded_auto`-only; Tier-0 never auto-files; the emit invariant is untouched) but
real, and with no mechanical hook backstop for the `gh issue create` path. It applies
to Mode C **only**; Modes A/B keep the per-item AskUserQuestion confirm unchanged.

## Assumptions-as-owned-items (in the render step)

The render step includes every unresolved unknown as a stage-owned assumption in the
body (per `references/elicitation-loop.md` § Assumptions-as-owned-handoff-items):
`[ASSUMPTION – CONFIRM] <assumption> — owner: <stage> — to close: <evidence/decision>`,
where `<stage>` is one of root-cause / research / dependency / design / architecture /
slicing / estimation / resourcing / triage. Group several into a dedicated
"Open assumptions (owned for downstream closure)" block. **Boundary:** the desk emits
owned assumptions; it does not investigate-and-close them. Who picks up an owned
assumption and how it closes downstream is a separate convention, out of this skill's
scope — this contract states the seam so a future downstream-closing convention has a
clean handoff.

## Structured-field carriage (tool-agnostic)

Where the target tracker has **structured fields a freeform body cannot set** (GitHub
Issue-Form dropdowns today; a Jira required field tomorrow), carry each structured
value via the tracker's structured channel where one exists (a label), or as a labeled
first body line where none exists (`**Severity:** P2 — Material`), and read back the
created item to confirm carriage. When a required structured field cannot be faithfully
represented, escalate to the **observation** tier rather than emit a malformed typed
item. This is the same precedent the platform already uses (an emitter carrying a
category as a `--label` on its create command).

## MVP target: GitHub Issues

The only configured tracker for the MVP is GitHub Issues. Emit via
`gh issue create -F <body-file>` against the matching `.github/ISSUE_TEMPLATE/<type>.yml`
field set, after the AskUserQuestion confirm. The GitHub-specific mechanics:

### Dropdown carriage (GitHub Issue Forms)

The templates `bug.yml` and `improvement.yml` are GitHub Issue **Forms** with required
**dropdowns**. `gh issue create -F <body-file>` writes a freeform markdown body plus
labels; it does NOT populate Issue-Form dropdown field-IDs. The only structured carriers
a `-F` create can set are **labels**. Carry the required dropdowns as follows (read each
template's `labels:` array for the default label set rather than hardcoding it):

| Type | Required structured field | Has a label home? | Carriage at emit |
|---|---|---|---|
| `bug` | Severity (P1–P4) | NO — no severity label exists | **Severity-in-body:** first body line `**Severity:** P2 — Material` so a Triage reader and the close gate recover it. |
| `bug` | (default labels) | YES — from the template `labels:` array | Pass the template's default labels (read from `bug.yml` `labels:`). |
| `improvement` | Category (the template's dropdown options) | YES — but applied by Triage, not at intake | **Category-in-body:** first body line `**Category:** <value>` AND pass only the non-category default label(s) from the template `labels:`. Triage (Stage 2) applies the matching category label at CER Resolve per `core/specs/label-taxonomy.md` — the desk does NOT pre-apply it. |
| `improvement` | Priority (optional) | NO label at intake | Priority-in-body if the user gave one; otherwise omit (Triage validates priority). |
| `observation` | (none) | YES — from the template `labels:` array | Pass the template's default labels (read from `observation.yml` `labels:`). |

### Severity-in-body convention (bug)

A bug's Severity dropdown is required by the form but has no corresponding label.
Render the bug body with Severity as the labeled first line:

```
**Severity:** P2 — Material

## Reproduction Steps
1. …
```

so the value is recoverable by a Triage reader and the Stage 13 close gate even though
the dropdown field-ID is empty on a `-F` create. The same first-line-label convention
carries an improvement's Category.

### Observation-tier fallback (the unrepresentable-field escape)

When a required structured field cannot be faithfully represented by either a label or
an agreed body convention — or when the 5-test fails and the user cannot fix the gap
after one re-elicitation — do NOT emit a malformed typed item. Escalate to the
observation tier: render the item as `observation.yml` (what is missing / what good
looks like / file or section affected), emit with the observation template's default
labels, and tell the user it was filed as a placeholder for Triage to promote when
enough context exists.

### The emit command shape

After the AskUserQuestion approval, with the rendered body in a process-local temp file
(pass the template's own default labels read from its `labels:` array; the shapes below
show the convention, not a hardcoded label list):

- `bug`: `gh issue create -F <body> --title "<informative summary>"` + the labels from `bug.yml`'s `labels:`. The title carries no `[Bug]:` prefix — type is on the `bug` label.
- `improvement`: `gh issue create -F <body> --title "<informative summary>"` + the non-category labels from `improvement.yml`'s `labels:`. Triage applies the category label; the Category value travels in the in-body `**Category:**` line only — **not** in the title (titles carry no type/category prefix).
- `observation`: `gh issue create -F <body> --title "<informative summary>"` + the labels from `observation.yml`'s `labels:`. The title carries no `[Observation]:` prefix — type is on the `observation` label.

Read back the created item after emit (`gh issue view <new> --json state,labels,body`)
and confirm state is open, the labels are present, and the body carries the
in-body-carried structured fields — then report the URL. A read-back mismatch halts and
reports which field failed to land.

## No-tracker fallback

If the configured tracker CLI is unavailable, or the user declines auto-create, return
the copy/paste-ready item body in a fenced block plus the exact create command
(including the label flags and the in-body Severity/Category lines), and state clearly
that the item was NOT auto-filed. This is the only non-emit path; it still produces a
logged-item-ready artifact, not a scratch file written to the tree.

## Parameterization is deferred

Plug-and-play parameterization of the target tracker (Jira / Smartsheet / etc.; types,
schemas, and fields per operator; install-time config) is **deferred** — the
tool-agnostic process layer above is the clean seam, but the parameterization is not
built here. The deferral pointers are in the § Provenance block.

## Provenance

This block is the single designated home for issue identifiers cited by this file.

- Originating skill issue (never a tracked scratch file): #412.
- Deferred target-tracker parameterization (multi-destination config / type system / install-time round-trip): #384, #409, #383.
