# Wrapper Mode — Full Intake Procedure

<!-- reference-durability: allow-link -->

This reference holds the procedural detail for artifact-generator's **Wrapper Mode**. The mode model, the mode-discriminator table, and the metadata-header schema live in the [SKILL.md §Wrapper Mode](../SKILL.md) section; this file is the gate-by-gate intake procedure the agent runs once Wrapper Mode is selected.

Wrapper Mode ingests an *already-produced* external artifact (an Anthropic-skill output, a user upload) and runs only the PMO orchestration tail — prepend a metadata header, stage in `08-Generated/`, present for review. **It makes no runtime Anthropic call**: the Anthropic skill ran separately, before, and Wrapper Mode touches only the inert output. It is categorically distinct from a runtime `extends` coupling — see [ADR-023](../../../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md).

## Mode selection (recap)

Mode is content-driven and automatic — inferred from whether an artifact-to-wrap is present, exactly as the skill infers artifact *type* from the trigger. **No `mode=` argument and no new slash-command** for the human path. The chained path (`chained=true` from ppm-agent `[ARTIFACT_GAP]`) stays **Generate-Mode-only** (see §Chained-path boundary).

| Discriminator | Mode |
|---|---|
| Request names no existing artifact to wrap ("draft an exec status report") | **Generate Mode** (default, unchanged) — full Execution Flow Steps 1–6 |
| Request supplies an existing artifact to wrap (file path, pasted content, upstream Anthropic-skill output) — trigger verbs: "wrap", "stage this", "bring this into the project", "add a PMO header to", "ingest this runbook/PRD" | **Wrapper Mode** — Steps 5–6 only, plus the Step 4-W intake below |

Human invocation forms (natural-language, artifact-bearing):

- `Wrap <path-or-attachment> as a <catalog-type> and stage it` (explicit type)
- `Stage this runbook in 08-Generated/` (type inferred from content + filename)
- `Bring <Anthropic engineering/documentation output> into the project` (the route-out workflow tail)

## Step 4-W — Wrapper intake (replaces content-production Step 4 in Wrapper Mode)

Before staging, the wrapper:

1. **Reads the supplied artifact in full.** Read-before-edit applies — the specifier vouches for the content; you must see all of it before stamping a header on it.
2. **Does NOT mutate the artifact body.** Wrapper Mode is a *header-prepend + stage*, never a content rewrite. If the user wants the content *changed*, that is Generate / Revise, not Wrapper (see SKILL.md §What This Skill Does NOT Do).
3. **Runs the PMO output gates that can run on inert content** without re-authoring:
   - **No-internal-IDs scan** — strip or flag any internal `#NNNN`, milestone, or internal URL per the self-containment discipline.
   - **Evidence-label presence check** — flag missing evidence labels; do NOT fabricate them.
   - **Readiness / placeholder scan** — `[INSERT]` / `[TBD]` → flag for the user; do NOT auto-fill.
4. **Sets `confidence`** from the wrap context:
   - `HIGH` — the source is a trusted named skill output the user vouches for, clean of gate flags.
   - `MEDIUM` — the wrapper had to infer the catalog type, or a gate scan raised a flag.
   - `LOW` — content is partial or uncertain.
5. **Applies the Dual-Framing Bridge** (next section) when the resolved catalog type is dual-framed AND `dual_framing_enabled: true`.

## Dual-Framing Bridge in Wrapper Mode

When the wrapped artifact's resolved `artifact_type` is one of the dual-framed Waterfall/Agile types (Milestone Status Report, Sprint Review Summary, Phase Gate Review Package, etc. per the [catalog](artifact-catalog.md)) **AND** PROJECT.md carries `dual_framing_enabled: true`, the wrapper appends a **dual-framing addendum block** beneath the ingested content — an Agile framing and a Waterfall framing — rather than rewriting the body. This preserves the no-content-mutation invariant while satisfying the Dual-Framing Bridge contract. When the type is single-framed, or `dual_framing_enabled` is false/absent, the bridge is omitted (the correct non-ceremony signal).

## Metadata header (recap — schema lives in the SKILL.md)

Wrapper Mode writes the same frontmatter block as Generate Mode, extended by one new field-value (`source: external`) and one new field (`source_origin`), so the header round-trips through every existing consumer (Promotion Workflow, Artifact Health scan, auto-archive). `artifact_state` is always `DRAFT` (the `Artifact-DRAFT` canonical lifecycle state on emit; the former `PENDING_REVIEW` value, re-specced onto the canonical Artifact Workflow vocabulary) — **Wrapper Mode is never promoted on ingest**. Full schema and the Domain-C forward-map note are in the [SKILL.md §Wrapper Mode](../SKILL.md); the canonical state set, the application-layer stamping rules, and transitions live in [`lifecycle-states.md`](lifecycle-states.md).

## Chained-path boundary

The existing Chained Invocation Contract (`chained=true` from ppm-agent `[ARTIFACT_GAP]`) is **Generate-Mode-only** and is unchanged by Wrapper Mode. Wrapper Mode is **not** auto-cascaded — no upstream skill hands artifact-generator inert external content via the manifest today. The boundary is explicit: `[ARTIFACT_GAP]` → Generate Mode; external-artifact wrap → human-invoked Wrapper Mode. If a future cascade source emerges, a `source: external` manifest variant is the extension point (out of scope here).

## Related

- Mode model + schema: [SKILL.md §Wrapper Mode](../SKILL.md)
- Which-skill-to-call decision tree: [`core/standards/artifact-skill-routing.md`](../../../../core/standards/artifact-skill-routing.md)
- Route-out branch detail: [`tech-doc-routing.md`](tech-doc-routing.md) · [`prd-routing.md`](prd-routing.md)
- Sourcing posture (no runtime coupling): [ADR-023](../../../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md)
