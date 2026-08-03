---
title: Domain-Token Registry
purpose: The single index of every concept the bare token `domain` names in this corpus — each concept mapped to its owning file, its value space, and how its instances are declared.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: readers and agents resolving which `domain` axis a given declaration refers to; the six owning files, each of which points here; design spokes classifying a deliverable's domain
composes_with: frontmatter-schema.md, project-schema.md, template-protocol.md, template-taxonomy.md, platform-doc-frontmatter-standard.md, gate-criteria-spec.md, project-entity-model.md
---
<!-- reference-durability: allow-link -->
# Domain-Token Registry

## §1 Purpose + scope

The bare token `domain` names **six different concepts** in this corpus. Nothing is wrong with any one of them; what was missing was a single place that says which is which. This file is that place. A reader who finds a `domain` and does not know which axis it is on resolves it here, in one lookup.

**No field is renamed.** ADR-050 settled that direction: the pre-existing `domain`-named fields keep their names, and the ambiguity is resolved by **indexing, not by migration**. This registry is the disambiguation surface ADR-050 prescribed. A proposal to rename any of them is a change to that decision and takes the governed supersession path — it is not an editing choice available to a reader of this file.

**Scope boundary.** This registry maps the markdown corpus under `core/`, `release/` and `operations/`, **plus** the `.meta.yml` and provenance sidecars that carry frontmatter for files whose own frontmatter slot is unavailable (see §3). Nothing outside those three module trees declares the token: a sweep over `docs/`, `packages/` and the repository-root markdown returns zero declarations. The boundary is stated so §5's coverage claim is true against a named population rather than silently false against an unnamed one.

**What this registry is not.** It is not a schema — it validates nothing and no gate reads it. It is a lookup. Each concept's *definition* lives in its owning file and is cited here, never restated; where this registry and an owning file disagree, the owning file wins and this registry is the thing that is stale.

## §2 The registry

| # | Concept | What the token means here | Value space | Owning file | Declaration pattern | Instance carriers | Not to be confused with |
|---|---|---|---|---|---|---|---|
| 1 | **Deliverable-class** | What kind of deliverable a release or project produces — the abstract class that design-aware mechanisms branch on to select the matching best-practice guide. | Open. Named classes: `software`, `governance`, `web`, `data`, `enterprise-platform`, `hardware`, `process`, `support`; a free domain name is permitted where no guide exists yet, and is itself the demand signal for authoring one. | `release/references/pipeline/stage-04-planning.md` § 5.7. Where a project declares one, `core/schemas/project-schema.md` `deliverable_type` is the authoritative source this field reads. | A `domain:` key nested inside a `domain_practice: { … }` provenance label. | Release plan files under `release/releases/plans/`. | **Concept 6**, which shares the values `governance` / `software` / `process` / `support`. Concept 1 classifies the **deliverable**; concept 6 classifies the **document**. |
| 2 | **Artifact-provenance** | Where a project artifact instance came from — the generated-vs-source boundary. | `source` \| `managed` \| `generated`. `A` / `B` / `C` are **deprecated aliases** of those three; readers may find either vocabulary during the migration window, writers emit the human-readable value. | `core/schemas/frontmatter-schema.md` § Category 6. | A `domain:` key in an operational artifact's frontmatter whose value is in the live-or-deprecated union. | Project artifacts in a project's numbered folders; the tracker and project-page templates that seed them, and those templates' `.meta.yml` sidecars; the document-index test fixtures; skill documentation quoting an emitted block. | **Concept 5.** Both are called *"three-domain classification"* at their own owning files. Concept 2 classifies an artifact **instance**; concept 5 classifies a **template structure**. These two are the corpus's only genuine key collision — see §3. |
| 3 | **Content-area tag** | The content-filing area a project content file belongs to, for graph clustering and filtering. | `governance` \| `design` \| `testing` \| `operations` \| `transcripts` \| `comms` \| `synthesis` | `core/schemas/frontmatter-schema.md` § Category 7, Tag Taxonomy. | **None as a key.** The token appears only inside the tag pattern `delivery/{domain}`, where `{domain}` is a placeholder for one of the values above — never a field name. | The `tags:` array of project content files. | **Concept 1**, which shares the value `governance`. Concept 3 is a filing tag on one file; concept 1 is a class on a whole deliverable. |
| 4 | **Behavioral/domain predicate** | An adjective naming a class of acceptance-criterion outcome — one not reducible to a single file-content or system-state assertion without losing the criterion's meaning. **Not a field.** | n/a — adjectival. | `core/schemas/gate-criteria-spec.md`, criterion G1-05a (admissible AC pattern (d)) and the G3-05 self-repair branch. | **None** — adjectival prose. | Acceptance-criterion bullets written in the pattern-(d) form: an outcome declaration paired with a `method:` declaration of how it is verified. | **Every other row.** This is the only entry that is not a field, which is why a field-shaped probe never finds it and a reader may conclude it does not exist. |
| 5 | **Template-provenance** | The three-domain classification of a **template structure** — which canon family governs it, and who consumes its rendered output. | `project` \| `software` \| `platform-internal` (closed). | `core/standards/template-protocol.md` § 4.2 defines the field; `core/standards/template-taxonomy.md` § 2 carries the classification rule and the boundary test. | A `domain:` key inside an L4 provenance header — a frontmatter block that also carries `artifact_type: template`. | The provenance header of a canonical template: **inline** where the template's frontmatter slot is free, in a **sidecar** where it is not (see §3). | **Concept 2** — see that row and §3. Also **concept 1**, which shares the value `software` on a different axis. |
| 6 | **K1 platform-doc frontmatter** | The subject domain an authored platform-reference document under `core/**` belongs to. | Open. Live values: `governance`, `facilitation`, `software`, `process`, `support`. | `core/standards/platform-doc-frontmatter-standard.md` § 6 (RECOMMENDED tier); § 9 names it typical for the `discipline`, `how-to` and `reference` classes. | A `domain:` key in the frontmatter of an authored `core/**` reference document. | `core/**` documents of class discipline / how-to / reference. | **Concept 1**, which shares most of its live values. Concept 6 says what a **document is about**; concept 1 says what a **release builds**. |

**Concept 4 and concept 3 have no `domain:` declarations at all** — concept 3 appears only as a placeholder inside a tag pattern, concept 4 only as an adjective. This is why the registry keys on **concept**, not on declaration: a per-declaration index is structurally incapable of representing either, and would drop two of six concepts on the floor.

## §3 The one key collision — payload-frontmatter templates

Of the six concepts, exactly two can meet in one file, and they do so in exactly one place: a **canonical template that carries the frontmatter of the artifact it produces**.

**The class.** A *payload-frontmatter template* is a template whose top-of-file YAML block is not metadata **about the template** — it is the born-entity frontmatter **of the artifact the template produces**, copied into the instance verbatim with its placeholders substituted. The block is the template's payload. Seven templates are in this class:

`operations/templates/communications-tracker-template.md` · `daily-status-log-template.md` · `milestone-tracker-template.md` · `open-meetings-tracker-template.md` · `project-md-composed-index-template.md` · `sprint-tracker-template.md` · `transcript-register-template.md`

Each carries a concept-2 `domain: managed` — correct, because the artifact each produces is managed knowledge. Each is also a template, and every template owes a concept-5 `domain:` in its L4 provenance header. **Two different entities, each legitimately owning a `domain` field, and one frontmatter slot between them.**

**Why this is structural, not lexical.** A markdown file has exactly one top-of-file frontmatter slot. In these seven it is occupied by payload. Writing the L4 provenance header into that same block would place two `domain:` keys in one YAML document, and duplicate keys resolve **last-wins with no error** — silently deleting the value that every artifact these templates produce is born with. The failure is invisible: no parser complains, no gate fires, and the loss surfaces only downstream as artifacts with the wrong provenance. This is why the collision must be resolved deliberately rather than discovered by a sweep.

**The resolution: these seven carry their L4 provenance header in a sidecar, never inline.** They are **not** exempt from provenance. The template protocol's frontmatter-placement convention already establishes the sidecar for precisely this predicate — its rule for CSV templates rests on the observation that *the file's own frontmatter position holds data, not metadata*, and routes provenance to a sibling file rather than abandoning it. A payload-frontmatter template is in the identical position: same predicate — the slot holds data — reached by a different cause. The corpus already runs the mirror of this convention on the payload side, carrying the produced artifact's frontmatter in a `.meta.yml` sidecar for the two CSV templates whose format cannot hold it inline.

**The two populations are structurally distinguishable, not merely differently populated.** Every template whose frontmatter is its own provenance header carries an explicit marker telling a reader not to copy the block into a rendered instance; not one of the seven carries that marker, and one carries the opposite marker naming its block as the produced entity's born frontmatter. A template's class is therefore readable from the file, not inferred from whether a header happens to be present.

**What this decision binds.**

- **A provenance-header sweep must not insert an inline L4 header into any of the seven.** They are unblocked by the sidecar route, not by the inline one. A sweep that treats them as ordinary headerless templates reintroduces the silent deletion described above.
- **The same sidecar carries the template's `template_family`,** for the same reason and by the same route. The two fields are neighbours in one header; nothing about this class splits them.
- **A future coverage check over L4 provenance must read the sidecar as well as the inline block.** A check that reads only inline frontmatter will report these seven as un-provenanced forever.

**What this decision does not do.**

- **It renames nothing.** All six concepts keep their field names, and the `domain: managed` in each of the seven stays exactly where it is, byte for byte.
- **It does not perform the migration.** No sidecar file is created by the decision itself; authoring them is separate, sequenced work.
- **It does not settle the sidecar's filename form or field set.** Two forms are live in the corpus — a `.meta.yml` suffix in use today, and a `.provenance.yml` form declared by the template protocol with no files yet written to it. Reconciling them belongs to the work that generalizes the placement convention, not to this registry.

The full decision, its rejected alternatives and its consequences are recorded in **ADR-107**. This section is the index entry; that ADR is the record.

## §4 Deliberately non-colliding names

These look adjacent and are not overloads. They are listed so a reader who finds one stops searching.

| Name | What it is | Why it does not collide |
|---|---|---|
| `deliverable_type` | The project-level deliverable-domain axis on the project schema. | Named deliberately to avoid the bare token, per ADR-050. It is concept 1's authoritative source, not a seventh concept. |
| `domain_practice` | The Stage-4 provenance label recording whether external best-practice for a domain was sourced or flagged. | A compound name for a provenance record. It **contains** a concept-1 `domain:` key; it is not itself a `domain` field. |
| `value_domain` | Schema vocabulary for "the set of allowed values a field may take". | A mathematical sense of the word, unrelated to every concept above. |
| `file_domain`, `idx_files_domain` | Column and index names in the SQLite document-index projection. | Storage projections of concept 2. Same concept, different substrate — not a new axis. |

## §5 Reconciliation

Run:

```bash
grep -rEn "^\s*domain:" core/ release/ operations/ --include="*.md"
```

**Pass condition — coverage, not count.** Every declaration the sweep returns matches the `Declaration pattern` of exactly one §2 row, and every §2 row's `Owning file` resolves on disk. **No number is recorded here, and none should be added.** A count would freeze in the file the moment the next declaration lands, and the population moves on ordinary work — the coverage predicate stays true across that growth, which is the whole reason the registry keys on concept rather than on declaration.

Two checks that make the sweep honest:

- **Pair it with a negative control.** Run the same command against a token that cannot exist (`^\s*zzdomain:`) and confirm zero. A sweep returning zero for a real reason and a sweep returning zero because the pattern is broken look identical otherwise.
- **Extend it past `--include="*.md"` when checking concept 2.** That concept's instances also live in `.meta.yml` sidecars, which a markdown-only sweep never sees.

## §6 Update trigger

Re-derive this registry when any of the following happens:

- A `domain:` declaration is introduced whose concept or owning file is not already a §2 row.
- Any concept's **value space** changes — including the completion of the concept-2 alias migration, at which point `A` / `B` / `C` leave that row.
- Any **owning file** moves or is renamed.
- A **new key collision** appears: two concepts meeting in one file. §3 records the only one that exists today, and it is resolved; a second would need its own resolution, not an extension of that one.

**Derive it from a sweep, never from this file's own list.** The sixth concept was found only because a sweep was run instead of the prior enumeration being copied forward — four earlier surveys of this same overload missed it. Copying the concept list forward is the failure mode this trigger exists to prevent.

**Automation.** No check enforces this today; the trigger is honoured by authors and reviewers, and the §5 command is carried inline so staleness is one copy-paste from detectable. The intended home for automation is the platform-convention linter that already runs as the engine for residual conventions no other gate covers — a registry-coverage dimension flagging any declaration unmatched by a §2 pattern, and any row whose owning file does not resolve. That dimension is specified and routed as follow-up work; it is deliberately not built here, because adding an executable surface to a documentation change is the accretion this platform slows down on purpose.
