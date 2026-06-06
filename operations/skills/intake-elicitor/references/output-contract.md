# Output Contract

How the skill emits a well-formed, correctly-typed work item to the GitHub Issue tracker — never a tracked scratch
file. This is the contract that closes the originating defect (a scratch draft committed for lack of a funnel). The
type set and field maps are in `references/type-map.md`; the loop that produces the rendered body is in
`references/elicitation-loop.md`.

## The emit invariant

The skill has NO write path to a tracked file. The only persistence paths are (1) the GitHub issue created via
`gh issue create` after explicit user confirmation, or (2) the chat-returned copy/paste body block when `gh` is
unavailable. There is no `08-Generated/` staging file, no scratch `.md` in the repo, no temp file left in the tree.
The single mutable artifact at emit is a throwaway body file passed to `gh` via standard input or a process-local
temp path that is not committed.

## The four-step contract

1. **Render.** Build the issue body against the identified type's field set (all required fields populated, or
   explicitly marked `[ASSUMPTION – CONFIRM]` for deferrable fields, or "None — …" where the template allows it).
   Carry the structured-field values that have no label home as labeled body lines (see the dropdown-carriage rules
   below).
2. **Gate.** Run the 5-test (T1–T5 per `references/elicitation-loop.md`). If any test fails and cannot be resolved,
   route to the Observation tier (`observation.yml`) rather than emit a malformed typed item.
3. **Confirm.** Present the rendered body plus the 5-test verdict. Obtain explicit user confirmation. The skill
   proposes; the human confirms what gets logged. This is Autonomy Tier 1 — no auto-emit without confirmation. State
   the reversibility tier on the emit recommendation (a created issue is CHEAP — close or delete it).
4. **Emit.** Write the confirmed body to a process-local temp file and run `gh issue create` against the repository
   with the title (carrying the type prefix) and the labels that have a structured home (see below). Capture and
   report the created issue URL.

## GitHub Issue-Form fields vs the create command (the load-bearing mechanism)

Three of the four templates (`bug.yml`, `improvement.yml`, `adr.yml`) are GitHub Issue **Forms** with structured
fields, including required **dropdowns**. The create command used at emit (`gh issue create -F <body-file>`) writes a
freeform markdown body plus labels; it does NOT populate Issue-Form dropdown field-IDs. A naive `-F` create therefore
ships an item whose required dropdown (a bug's Severity, an improvement's Category) is empty even though the body
prose mentions the value. The only structured carriers a `-F` create can set are **labels**. The rules below close
that gap.

### Dropdown-to-label / dropdown-in-body map

The authoritative label mapping is the platform label taxonomy. Apply it as follows:

| Type | Structured field | Has a label home? | Carriage at emit |
|---|---|---|---|
| `bug` | Severity (P1–P4) | NO — no severity label exists | **Severity-in-body:** first body line `**Severity:** P2 — Material` so a Triage reader and the close gate recover it. |
| `bug` | (auto-labels) | YES — `bug` + `status: proposed` | Pass `--label "bug" --label "status: proposed"`. |
| `improvement` | Category (Skill Update / Protocol / Structure / Documentation / Enhancement / Tracker Schema / Routing Rules) | YES — but applied by Triage, not at intake | **Category-in-body:** first body line `**Category:** Skill Update` AND pass only `--label "status: proposed"`. Triage (Stage 2) applies the matching category label at CER Resolve per the taxonomy — the elicitor does NOT pre-apply it. The category-to-label map for Triage is: Skill Update → `skill-update`; Protocol → `protocol`; Structure → `structure`; Documentation → `documentation`; Enhancement → `enhancement`; Tracker Schema → `tracker-schema`; Routing Rules → `routing-rules`; no-fit fallback → `improvement`. |
| `improvement` | Priority (optional) | NO label at intake | Priority-in-body if the user gave one; otherwise omit (Triage validates priority). |
| `observation` | (none) | YES — `observation` + `status: proposed` | Pass `--label "observation" --label "status: proposed"`. |
| `adr` | Status (Proposed/Accepted/…) | NO status-value label | **Status-in-body:** the Status field is the first body field; pass `--label "adr" --label "status: proposed"`. |

The principle: every required structured field maps to a label where one exists, or to a labeled first-line body
convention where none exists. This mirrors the platform's existing emitter, which carries a category as a label on the
`gh issue create` it runs; here the category has no intake-time label home, so it is carried in the body for Triage to
label — which is the taxonomy-faithful path, not a thinner one.

### Severity-in-body convention (bug)

A bug's Severity dropdown is required by the form but has no corresponding label. Render the bug body with Severity as
the labeled first line:

```
**Severity:** P2 — Material

## Reproduction Steps
1. …
```

so the value is recoverable by a Triage reader and the Stage 13 close gate even though the dropdown field-ID is empty
on a `-F` create. The same first-line-label convention carries an improvement's Category and an ADR's Status.

### Observation-tier fallback (the unrepresentable-field escape)

When a required structured field cannot be faithfully represented by either a label or an agreed body convention — or
when the 5-test fails and the user cannot fix the gap at authoring time — do NOT emit a malformed typed item. Escalate
to the Observation tier: render the item as an `observation.yml` (what is missing / what good looks like / file or
section affected), emit with `--label "observation" --label "status: proposed"`, and tell the user it was filed as a
placeholder for Triage to promote when enough context exists. This is the platform's codified response to "template
fields cannot be populated" — route to Observation rather than ship a structurally-incomplete item.

## The emit command shape

After confirmation, with the rendered body in a process-local temp file:

- `bug`: `gh issue create -F <body> --title "[Bug]: <summary>" --label "bug" --label "status: proposed"`
- `improvement`: `gh issue create -F <body> --title "[<Category>]: <summary>" --label "status: proposed"` (Triage
  applies the category label; the title prefix carries the Category value per the template's title convention)
- `observation`: `gh issue create -F <body> --title "[Observation]: <summary>" --label "observation" --label "status: proposed"`
- `adr`: `gh issue create -F <body> --title "[ADR]: <summary>" --label "adr" --label "status: proposed"`

Read back the created issue after emit (`gh issue view <new> --json state,labels,body`) and confirm state is open,
the labels are present, and the body carries the in-body-carried structured fields — then report the URL. A read-back
mismatch halts and reports which field failed to land.

## No-`gh` fallback

If `gh` is unavailable, or the user declines auto-create, return the copy/paste-ready issue body in a fenced block
plus the exact `gh issue create` command (including the `--label` flags and the in-body Severity/Category/Status
lines), and state clearly that the item was NOT auto-filed. This is the only non-emit path; it still produces a
logged-item-ready artifact, not a scratch file written to the tree.

## Provenance

This block is the single designated home for issue identifiers cited by this file.

- Originating skill issue (never a tracked scratch file): #412
- Forward-coupled work-item type system (later extends the type/label map): #409
