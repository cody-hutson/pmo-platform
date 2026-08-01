---
title: Domain-Token Registry
purpose: The single index of every concept the bare token `domain` names as a declared or declarable field in this corpus — each concept mapped to its owning file, its value space, and the pattern by which its instances are declared.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: readers and agents resolving which `domain` axis a given declaration refers to; the six owning files, each of which points here; design spokes classifying a deliverable's domain; any future convention-linter dimension asserting registry coverage
composes_with: frontmatter-schema.md, project-schema.md, template-protocol.md, template-taxonomy.md, platform-doc-frontmatter-standard.md, gate-criteria-spec.md
---
# Domain-Token Registry

## 1. Purpose and scope

The bare word `domain` names **six distinct concepts** in this corpus. They share a token and nothing else: their value spaces are disjoint or only accidentally overlapping, their owning files sit in four different folders, and two of them are not fields at all. A reader who meets `domain:` in one file and carries that meaning into another will read the wrong axis.

This registry is the **single enumerating source** for that overload. Each concept has exactly one row naming its owning file, its value space, and the pattern by which an instance is declared. Every other `domain`-disambiguation surface in the corpus points here rather than duplicating this table.

**No field is renamed.** `core/ADRs/ADR-050-deliverable-domain-axis.md` settled that direction: it rejected reusing or renaming the bare name, minted the non-colliding name `deliverable_type` for the new field, and prescribed a disambiguation note as the fix for the pre-existing overload. This registry is that note. Renaming a shipped `domain` field would require superseding ADR-050, not a scope note — and the live radius is worse than it looks, because one of these concepts is mid-migration on its own value vocabulary and a second rename would collide with it inside the migration window.

### Scope boundary

**In scope:** the markdown corpus under `core/`, `release/`, and `operations/`, plus the `.meta.yml` sidecar files that carry declarations for CSV artifacts. Nothing outside those three module roots declares this token.

**Out of scope, stated so the boundary is a decision rather than an omission:**

- **Prose and heading senses of the bare word that carry no field.** Three live ones exist; they are named in § 3 so a reader who meets them stops looking for a row here.
- **Compound tokens** — `deliverable_type`, `domain_practice`, `value_domain`, `file_domain`. These are deliberately non-colliding and are also recorded in § 3.
- **Renaming, migrating, or reconciling any concept's value vocabulary.** This registry *surfaces* a vocabulary split where one is live; it does not resolve one.

### How to read a row

A row answers one question: *given a `domain` I just met, which concept is it, and who defines it?* The `Declaration pattern` column is the machine-checkable form of that answer — see § 4. The `Not to be confused with` column names the nearest sibling and the one test that separates them, because every real confusion in this corpus is between two specific concepts, not among all six.

---

## 2. The registry

| # | Concept | What the token means here | Value space | Owning file | Declaration pattern | Instance carriers | Not to be confused with |
|---|---|---|---|---|---|---|---|
| 1 | **Deliverable-class** | The abstract domain class of the deliverable a release or project produces — *what kind of thing is being built*. Downstream design-aware mechanisms branch on this one signal. | Open. Live values: `software`, `governance`, `process`, `support`, `web`, `data`, `enterprise-platform`, `hardware`. A free domain name is permitted where no guide exists yet, and that absence is itself the demand signal for authoring one. | `release/references/pipeline/stage-04-planning.md` § 5.7 — the `domain:` class field. Where a project declares it, `core/schemas/project-schema.md`'s `deliverable_type` is the authoritative upstream source this field reads. | **Not a bare `domain:` line.** Conjunction: **(a) path** — a release plan under `release/releases/plans/`, or PROJECT.md frontmatter · **(b) form** — the `domain:` key *inside* an inline `domain_practice: { … }` label, or the non-colliding key `deliverable_type:` · **(c) value** — a domain-class name. | The `domain_practice` label carried in a release plan; the `deliverable_type` frontmatter field of a PROJECT.md. Never a standalone `domain:` line. | **Concept 6.** They share the values `governance`, `software`, `process`, `support`. Test: concept 1 classifies *what is being built*; concept 6 classifies *what a `core/**` reference doc is about*. |
| 2 | **Artifact-provenance** | Origin classification of a project **artifact instance** — where the artifact came from and therefore which trust and lifecycle rules govern it. | `source` \| `managed` \| `generated`. **`A` / `B` / `C` are DEPRECATED aliases** of those three, live only inside an open migration window; readers may find either vocabulary, writers emit the human-readable value. | `core/schemas/frontmatter-schema.md` § Category 6. | Conjunction: **(a) path** — a project operational artifact under a project's numbered folders, or a template / skill / test fixture that carries or illustrates one · **(b) value** ∈ {`source`, `managed`, `generated`, `A`, `B`, `C`} · **(c) required sibling** — a frontmatter block **without** an `artifact_type: template` key. | The frontmatter of a project operational artifact; the schema's own worked examples; frontmatter blocks emitted by artifact-writing skills; doc-index test fixtures; `.meta.yml` sidecars beside CSV templates. | **Concept 5.** Both are called *"three-domain classification"* at their own owning files, and both appear in `operations/templates/`. Test: the sibling key `artifact_type: template`. A template's provenance header carries it; a body-level artifact-provenance declaration does not. Value alone does **not** separate them, and neither does path. |
| 3 | **Content-area tag** | The content-filing area a delivery file belongs to — a navigation and retrieval tag, not a property of the artifact's origin. | `governance` \| `design` \| `testing` \| `operations` \| `transcripts` \| `comms` \| `synthesis`. | `core/schemas/frontmatter-schema.md` § Tag Taxonomy. | **Never a `domain:` key.** It is a **path segment inside a tag**: `delivery/{domain}` (equivalently `delivery/<domain>`), appearing as an element of a `tags:` array. It does not and cannot match a declaration sweep for `domain:`. | The `tags:` array of a delivery content file. | **Concept 1.** They share the value `governance`. Test: concept 3 only ever appears as a segment of a `delivery/…` tag inside a list; concept 1 is a classification of the deliverable itself. |
| 4 | **Behavioral/domain predicate** (adjectival) | An **acceptance-criterion outcome class**, used as an adjective — an AC that asserts a behavioral or domain outcome not reducible to a single file-content or system-state assertion without losing the AC's meaning. It is admitted only when paired with a declared verification method. | `n/a — adjectival`. This concept has no value space because it is not a field. | `core/schemas/gate-criteria-spec.md` — criterion G1-05a pattern (d), and the G3-05 self-repair menu. | `none — adjectival prose`. This concept is **never** declared as a key and will never appear in a declaration sweep. | The prose of the gate-criteria specification and the AC-authoring guidance that cites it. | **Every other row.** This is the only sense that is not a field at all. If you are looking at a `domain:` key, it is not this concept. |
| 5 | **Template-provenance** | Three-domain classification of a **template structure** — which canon family and audience the template's *rendered output* serves. A property of the template, not of any instance made from it. | `project` \| `software` \| `platform-internal`. Closed enum. | `core/standards/template-protocol.md` § 4.2 — the normative field-definition row. The classification rule it applies lives at `core/standards/template-taxonomy.md` § 2. | Conjunction: **(a) path** — a markdown template under `operations/templates/`, or a sibling `.provenance.yml` for a CSV template · **(b) value** ∈ {`project`, `software`, `platform-internal`} · **(c) required sibling** — the key `artifact_type: template` in the same provenance header. | The provenance header at the top of a markdown template; a sibling `.provenance.yml` for CSV templates; the protocol's own rendered exemplar. | **Concept 2** — see that row's test, which is the same test read from the other side. Also **not** the PMBOK Performance-Domain axis that lives in the same taxonomy file (§ 3 of this registry). |
| 6 | **K1 platform-doc frontmatter** | The subject domain an authored platform-reference doc under `core/**` belongs to — what the document is *about*. | Open. Live values: `governance`, `facilitation`, `software`, `process`, `support`. | `core/standards/platform-doc-frontmatter-standard.md` § 6 — a RECOMMENDED field; § 9 names it typical for the `discipline`, `how-to`, and `reference` classes. | Conjunction: **(a) path** — an authored reference doc under `core/` · **(b) value** — open · **(c) required sibling** — frontmatter carrying that standard's core field set (`title` / `purpose` / `type` / `status` / `reversibility`) and **no** `artifact_type: template` key. | The frontmatter of authored platform-reference docs under `core/`, concentrated on the discipline / how-to / reference classes. | **Concept 1** — see that row's test. Note also that the standard defining this field elsewhere asserts a field set disjoint from `frontmatter-schema.md`'s and assigns `domain` to that other side; the two statements are in tension, and the tension is why this concept went unnoticed by several prior surveys. |

**No count appears in this table or anywhere in this document.** Rows key on concept, not on declarations, so the declaration population may grow or shrink without any row changing. A population change is a zero-row-edit event; only a **new concept** or a **moved owning file** edits a row. That property is the whole reason this registry is concept-keyed — see § 5.

---

## 3. Names that are not overloads

Recorded so a reader who meets one of these stops searching for a row above.

### Deliberately non-colliding compound tokens

| Token | What it is | Why it is not an overload |
|---|---|---|
| `deliverable_type` | The project-level field for concept 1. | This is the **non-colliding name** ADR-050 minted precisely to avoid the overload. It is concept 1 under a distinct token. |
| `domain_practice` | A structured label carried in a release plan, recording the deliverable's domain and the provenance of its best-practice sourcing. | A compound token. Its **inner** `domain:` key is concept 1; the outer token collides with nothing. A line-wrap of this object is the most common false positive in a declaration sweep — see § 6. |
| `value_domain` | The schema-theory sense: *the set of values a field may take*. | A term of art about fields in general, unrelated to any concept above. |
| `file_domain` / `idx_files_domain` | A column and its index in the document-ecosystem SQLite cache. | Storage-layer projections **of concept 2**. Same concept, different surface, non-colliding name. |

### Adjacent senses of the bare word — deliberately **not** registry concepts

These are live uses of the bare word `domain` that carry **no field and no declaration**. They are excluded because a row's `Declaration pattern` column would be empty and unfalsifiable for them, which would make § 4's pass condition meaningless. They are named here instead.

| Sense | Where it lives | Why it is out of scope |
|---|---|---|
| **PMBOK 7 Performance Domain** | `core/standards/template-taxonomy.md` § 3, which anchors each project-domain template family to exactly one of the eight Performance Domains the PMBOK 7 standard defines. | A heading-and-prose axis imported from an external standard, never a declared field. **This is the sharpest live adjacency in the corpus**: it sits in the same file as concept 5's classification rule, and one § 2 table row of that file names both senses in a single cell. A reader there is genuinely at risk; that is why it is called out rather than left silent. |
| **Decision domain / authority domain** | The Stakeholder-Register decision-owner lookup in `core/schemas/tracker-schemas.md`, and the status-reporting skill that consumes it. | The *area of authority* a named decision-owner covers. Appears only as a placeholder inside a lookup expression and in warning prose; never declared. |
| **Observation-log partition** | The `<date>/<domain>/<theme>` pointer form used to reference an observation entry, and the analogous partition segment in memory-file naming. | A partition key in the operator memory store, which lives outside this corpus entirely. Never declared in a repo file. |

---

## 4. Reconciliation

Run both sweeps. The first covers the markdown corpus; the second covers the sidecar carriers, which the first structurally cannot return.

```bash
grep -rEn "^\s*domain:" core/ release/ operations/ --include="*.md"
grep -rEn "^\s*domain:" core/ release/ operations/ --include="*.meta.yml"
```

**Pass condition.** Every line the two sweeps return satisfies exactly one of:

1. it matches exactly **one** concept row's `Declaration pattern` — evaluated as the **full conjunction** of that row's factors (path **and** value **and** required sibling key), never on the value alone; or
2. it is listed in § 6 as a known non-declaration.

**And** every row's `Owning file` path resolves on disk.

**The verdict is coverage — zero unmapped, zero dangling — not count equality.** No number is asserted here, so no number can go stale here. A line that matches the sweep but satisfies neither condition is a genuine finding: either a concept is missing from § 2, or a new false-positive shape belongs in § 6.

**Why the conjunction is not optional.** Two concepts share both a value token and a path prefix. `domain: software` occurs as concept 5 in a template and as concept 6 in a platform-reference doc; concepts 5 and 6 both have instances under `core/standards/`. Neither value nor path alone separates them — only the sibling-key factor does. A single-factor matcher silently degrades this check from deterministic to judgment-graded.

---

## 5. Update trigger

Amend this registry when any of the following occurs. The first two edit a row; the third edits a row's `Owning file`; the fourth edits § 3.

1. **A new `domain` concept appears** — a declaration whose (concept × owning file) pair is not already mapped by any row. Add a row; do not stretch an existing row's value space to absorb it.
2. **A concept's value space changes** — a value is added, removed, or migrated. Update that row's `Value space` cell, and if a migration is in flight, say so in the cell rather than picking one vocabulary silently.
3. **An owning file moves or is renamed.** Update the `Owning file` cell **and** re-check that file's pointer back to this registry — the two are a pair, and a move that fixes only one direction leaves a dangling half.
4. **A new adjacent sense of the bare word appears** that a reader could mistake for a concept. Add it to § 3's second table with its exclusion reason.

**What does *not* trigger an update:** a change in how many declarations exist. Adding or removing instances of an already-mapped concept changes no row. This is the designed property, not an oversight.

**Intended automation.** A convention-linter dimension asserting registry coverage — flagging any declaration unmatched by a `Declaration pattern` and unlisted in § 6, and any row whose `Owning file` does not resolve — is specified but **not yet built**. Until it exists, § 4's command is the manual equivalent and is deliberately copy-pasteable so staleness is detectable without tooling.

---

## 6. Known non-declarations

Lines that the § 4 sweeps return but that are **not** an instance of any concept. Listing them is what makes § 4's pass condition adjudicable: without this channel, a coverage claim has no way to say *"matched, but not an instance"* and degrades on first contact into either a fabricated row or a silently tolerated failure.

Match on the **quoted text**, not on a line number — line numbers drift.

| Carrier | Matched text | Why it matches | Why it is not an instance |
|---|---|---|---|
| Any release plan under `release/releases/plans/` | a line matching `domain: <value> }` — beginning with `domain:` and **ending in a closing brace** | The inline `domain_practice: { … }` object wrapped across two lines, leaving its `domain:` key at the start of a line. The opening brace is on the preceding line. | The token is the compound `domain_practice` (§ 3), not the bare `domain`. **The closing brace on the matched line is the tell**, and it is the durable key — the value varies by release, the brace does not. Counting these as concept 1 would contradict § 3's own classification of that compound. |
| `core/standards/dual-format-document-model.md` | `domain: <source \| managed \| generated>` | A schema block that specifies the field, inside a `source:` mapping. | It declares concept 2's **enum**, not a value. A value-space specification is the definition of a concept, not an instance of it. |
| `core/standards/template-protocol.md` | `domain: project \| software \| platform-internal` | The copy-pasteable YAML schema block in § 4.1 of the file that owns concept 5. | Same class as the row above: it declares concept 5's **enum**, not a value. Note that the *rendered exemplar* further down the same file carries a real value and **is** an instance of concept 5 — the two lines in one file are deliberately classified differently. |

**How to add a row here.** A new entry is warranted only when a line matches the sweep and is genuinely not an instance — a wrapped compound, a value-space specification, or a quoted illustration of the regex itself. When in doubt, the question to ask is: *does a reader who follows this line reach a real classification of a real artifact?* If not, it belongs here.
