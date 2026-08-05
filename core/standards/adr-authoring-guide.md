---
title: ADR Authoring Guide — When to Write, Copy-Paste Template, Supersede-Not-Edit Policy
purpose: The canonical authoring guide for Architecture Decision Records — the when-to-write / when-NOT rubric, the copy-paste ADR markdown template + one worked example, and the supersede-not-edit immutability policy. This is the guide the ADR schema (§6 Boundary) and the roadmap framework designate as the owner of ADR mechanics/policy.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: core/standards/initiative-roadmap-framework.md (cites for ADR mechanics/policy); release/ADRs/README.md + core/ADRs/README.md (when-to-write pointer); release/references/pipeline/stage-05-solutioning.md (ADR-when-to-write rubric); .github/ISSUE_TEMPLATE/adr.yml (authoring reference); adr-helper skill (consumes the template)
parallel_to: adr-schema.md (the data contract — field + body-section list; this guide references it, does not restate it), decision-discipline.md (governs decision-class briefings, NOT ADR authoring)
---
<!-- reference-durability: allow-link -->
# ADR Authoring Guide — When to Write, Template, Supersede-Not-Edit Policy

An **Architecture Decision Record (ADR)** captures a single structurally-load-bearing decision and the rationale behind it — including the rejected alternatives — as an immutable, append-only record. This guide owns the **policy + ergonomics** of ADRs: *when* to write one (and when not), the copy-paste *template* + a worked example, and the *supersede-not-edit* immutability rule.

The **field + body-section data contract** (which frontmatter fields exist, their types + allowed values, the required body sections and their order) is owned by [`core/schemas/adr-schema.md`](../schemas/adr-schema.md). This guide's template *references* that schema for the field list — one source of truth — and does not restate it. The boundary is defined at [`adr-schema.md` §6](../schemas/adr-schema.md).

## When to write an ADR

Write an ADR when **any** of the following triggers fires. Each trigger is grounded in the shipped ADR corpus (a corpus witness is named so the threshold is calibrated against real records, not abstract judgment).

| # | Trigger | Corpus witness |
|---|---|---|
| T-ADR-1 | A **structurally load-bearing** decision with ≥2 viable options where the *rejected* options must survive as rationale — a choice future readers will otherwise re-litigate without the record. | ADR-027 (Release-Class weighting vs. per-issue Tier — rejected alternatives recorded); ADR-005 (append-pattern detection vs. line-overlap scoring — six alternatives A–F recorded). |
| T-ADR-2 | A decision that **binds a contract** across modules, stages, or artifacts — a boundary, an enum, or a resolution ladder that others must honor. | ADR-007 (core module boundary); ADR-016 (intake front-door boundary + handoff contract); ADR-062 (substrate-vs-canonical precedent). |
| T-ADR-3 | A decision that **supersedes or amends** a prior ADR — immutability forces a new record rather than an in-place edit (see § Supersession + immutability). | ADR-045 (supersedes ADR-029); ADR-046 (supersedes-in-part ADR-012's location clause). |

The governing question is: *"Is this an architecture **decision** whose rejected alternatives or cross-artifact contract must be preserved?"* If yes and a trigger fires, write the ADR. The cross-frame meta-discipline (how the ADR *form* is applied across frames) is a separate concern — this guide governs *whether* to write one.

## When NOT to write an ADR

Do **not** write an ADR in the following cases — the record would be ceremony that outweighs the decision, and (for the last case) would create duplicate-source debt.

| # | Non-trigger | Why not |
|---|---|---|
| N-ADR-1 | A **single forced approach** — one reasonable option, with no rejected alternatives worth preserving. | Nothing to re-litigate; the design spec plus the commit message already carry the decision. A release whose decisions each had a single reasonable approach needs no ADR. |
| N-ADR-2 | A **reversible, low-blast-radius mechanical change** — a doc repoint, an index-row backfill, a typo fix, any CHEAP-and-obvious edit. | The record would outweigh the decision. (This guide's own reference repoints and an index-row backfill are the exemplar: they ship as ordinary Stage-6 edits, no ADR.) |
| N-ADR-3 | A **decision already governed by an existing ADR or standard** — restating it mints a parallel record. | Cite the existing ADR (e.g., "per ADR-023") instead of authoring a duplicate. Duplicate-source debt is a maintenance liability, not a decision record. |

## ADR template (copy-paste)

Copy the block below into `core/ADRs/ADR-NNN-<kebab-title>.md` (cross-cutting, platform-wide decisions) or `release/ADRs/ADR-NNN-<kebab-title>.md` (release-pipeline-scoped decisions). `NNN` is the next free number in the platform-wide monotonic sequence (enforced by `release/tools/check-adr-numbers.py`; the number is claimed at merge, and a collision is resolved by renumbering with a provenance note — see § Supersession + immutability).

The **frontmatter fields and their allowed values are defined once** in [`adr-schema.md` §2](../schemas/adr-schema.md) — fill each field per that contract; the template does not restate the field rules. The **body sections are the seven required sections defined once** in [`adr-schema.md` §3](../schemas/adr-schema.md), in the order given there. The block below renders that set as a copy-paste template; the schema states each section's **requirement level** and this guide does not restate it — read the level there, author it here. The set is a **minimum**: an ADR may carry additional H2 sections beyond the seven (§3.1).

```markdown
---
# Fields + allowed values per core/schemas/adr-schema.md §2 (do not restate here — fill per the contract).
title: ADR-NNN — <human title>          # matches the H1 below
status: Proposed                        # Proposed | Accepted | Deprecated | Superseded (Nygard leading token; optional prose tail)
date: YYYY-MM-DD                        # decision / authoring date
release: <release-slug-or-version>      # the release the decision was rendered in
deciders: "<who decided, in prose>"     # e.g. operator + Stage 5 spoke + reviewers
tags: [<discovery>, <tags>]
source_observations:
  - "<the grounding observation / evidence this decision rests on>"
---

# ADR-NNN — <human title>

## Status

<Restate the status. When Superseded, cite the superseding ADR here — see adr-schema.md §5.>

## Context

<The forces / problem the decision addresses. What made a decision necessary?>

## Decision

<The decision, stated actively: "We will …" / "The platform adopts …">

## Alternatives Considered

<Every ADR carries this section; its CONTENT is what varies (adr-schema.md §3.1).
Where >=2 viable options were weighed: each option evaluated, with why it was rejected. This is
the load-bearing case — it is why the ADR exists, and the rejected options survive here so future
readers do not re-litigate them.
Where a single forced approach existed — an ADR written under T-ADR-2 or T-ADR-3 rather than
T-ADR-1 — say so: "Single forced approach; no viable alternative was weighed." That is a
conformant section. An ABSENT section is not.>

## Consequences

<Resulting trade-offs — positive AND negative. What becomes easier; what becomes harder.>

## Reversibility

<One of CHEAP | MODERATE | EXPENSIVE | IRREVERSIBLE (+ optional rationale) per
core/specs/reversibility-protocol.md.>

## Related ADRs

<Cross-ADR composition / supersession links, in ADR-number form (ADR-005) — never issue #N.>
```

The template's `never issue #N` note is scoped to **cross-ADR links** — a sibling ADR is always addressable by its own number, which outlives the issue that occasioned it. It is not a blanket prohibition on issue references anywhere in an ADR. Where an issue reference is legitimate, § Issue references in ADRs below states which zone it belongs in, the reference block that holds it, and the narrow criterion under which the repository-integrity override marker is warranted.

### Durability rules (enforced by the ADR durability lint)

The authoring rules below keep an ADR readable after the events the platform actually performs — history rewrites, corpus growth, and repository moves. They are enforced by a repository-integrity lint, [`release/tools/check-adr-durability.py`](../../release/tools/check-adr-durability.py), which runs as a job on every pull request that touches an ADR and carries a `--self-test` covering each rule. The same lint enforces one further rule — the identity-frontmatter rule in § Issue references in ADRs below. That rule is about *placement*, not prose durability, so it is stated there rather than in this table.

| Rule | Write this | Not this |
|---|---|---|
| **Status enum** — the `status:` value's leading token is one of the four Nygard tokens defined in [`adr-schema.md` §2](../schemas/adr-schema.md). A prose tail after the token (a ratification anchor, a supersession pointer) is permitted and expected. | `status: Proposed (flips to Accepted at the Stage 9 review)` | `status: Draft` |
| **No stale anchors** — durable prose carries no hardcoded commit SHA and no live corpus-population count. A commit hash is the durability ladder's least-durable rung, and a population count is false the next time the corpus grows. Cite the deriving command instead of a number, summarize a change instead of naming its hash, or anchor the fact historically ("as of authoring, …"). A **fixed-cardinality design constant is not a stale anchor** — a matrix's column count, a taxonomy's members, a policy ceiling, a retention window. Those are authored to be stable, and the lint deliberately does not flag them; the rule's subject is a number that names a population which *grows*. | "the standards roster, derived by the command the deployment rules publish" · "a stage count fixed by the pipeline's own definition" | "the 44 skills" · "8 files" · "11 release-standards" · "resolved by commit `a1b2c3d`" |
| **No operator handle** — the sanctioned ADR carve-out permits the operator's literal **name** on a `deciders:` line and nothing more. The GitHub **handle** is never sanctioned, on any line, including `deciders:`. | `deciders: "Ada Lovelace (operator) + Stage 5 spoke"` | `deciders: "ada-lovelace + Stage 5 spoke"` |

The stale-anchor rule exempts, by construction: fenced code blocks (a worked command example is not durable prose); the `source_observations:` frontmatter block (the schema defines it as point-in-time grounding evidence, so pinning it is correct); a line carrying an explicit historical anchor; a number introduced by a **ceiling** word, which states a bound the corpus is authored to stay under rather than a measurement of it ("per-doc files stay under 500 lines"); and any `Superseded` or `Deprecated` record, which is frozen for the audit trail under the supersede-not-edit policy below. A file that genuinely needs a pinned anchor declares the marker `<!-- adr-durability: allow-anchor -->` once, as an HTML comment anywhere in the file — a deliberate, auditable declaration, exactly as the reference-durability markers work. The marker never suppresses the handle rule.

**Read the gate as a partial net, not a proof.** The stale-anchor count rule matches a **closed vocabulary** of population nouns, so it is deliberately high-precision and incomplete: a live count expressed with a noun outside that vocabulary — or with a compound the vocabulary cannot span — is invisible to it. The corpus mints new compound population nouns as it grows, so the gap widens in *vocabulary*, not merely in volume, and no closed list can be kept complete against that. **A green gate is therefore not evidence that an ADR carries no live count.** The habit is the actual guarantee: cite the deriving command rather than its output, and the number cannot go stale whether or not any lint notices it. The lint's own module docstring states the admitted shapes, the three classes it deliberately excludes, and the command to re-derive the bound — read it there rather than inferring coverage from a passing run.

The lint currently reports without blocking. It locks a clean baseline rather than creating one, so it graduates to blocking only after the ADR corpus has had its full structural-conformance pass and the usual warn-log shakedown has run.

### Issue references in ADRs (placement, the reference block, and the marker criterion)

An ADR is durable corpus and outlives the tracker it was authored beside. A bare issue number sits on **rung 5** of the durability ladder in [`reference-durability-standard.md`](reference-durability-standard.md): it breaks on renumber and on repository migration, and it resolves at all only for a reader who has the tracker in front of them. That standard therefore permits a bare `#N` in a durable file **only inside a designated reference block, and only alongside a summary noun phrase** — the summary is what still carries the meaning once the number no longer does.

The template's `never issue #N` note and that rung-5 permission are the same rule read at two scopes, not a contradiction. Every issue reference in an ADR falls into exactly one of four zones, and the zone decides the rule.

| # | Zone | Rule | Why this zone |
|---|---|---|---|
| 1 | **Cross-ADR links** — `## Related ADRs`, supersession pointers | ADR-number form (`ADR-005`). **Never `#N`.** | A sibling ADR is rung 2 and travels with this record; the issue that occasioned it does not. |
| 2 | **Provenance** — the `source_observations:` frontmatter block, or the designated reference block below | A bare `#N` is **permitted at rung 5**, and **must** carry a summary noun phrase on the same line. | [`adr-schema.md` §2](../schemas/adr-schema.md) defines `source_observations:` as point-in-time grounding evidence, so pinning it is correct rather than rot. The summary is what survives the number. |
| 3 | **Identity frontmatter** — `title:`, `release:`, `deciders:` | **Never `#N`.** Name the release by its slug, the deciders by role or literal name, the record by its title. **No marker suppresses this** — there is no override path, only the rewrite. | An identity field says *what this record is*. A number that rots there corrupts identity, not merely provenance. Enforced as rule **R4** by the durability lint, which exempts only fenced renderings, `source_observations:` (not an identity field), and frozen records. |
| 4 | **Body prose** — `## Context`, `## Decision`, `## Alternatives Considered`, `## Consequences` | State the fact. A bare `#N` here is a rung-5 reference outside a designated block, so it is **prohibited** — rewrite it as a summary, or move it to the reference block. | The positional rule is the one construct in the durability standard with **no** override marker: rewriting inline is the only remedy (its removal-not-demotion rule). |

**The designated reference block.** An ADR's designated reference block is a single H2 section, spelled exactly:

```markdown
## References
```

Place it **after `## Related ADRs`**, as the last section of the file. The required body sections are a minimum, not a closed set ([`adr-schema.md` §3.1](../schemas/adr-schema.md)), so a `## References` section is a conformant addition rather than an extra-schema one. Every line inside it pairs the bare number with a summary noun phrase — `#N — the intake ticket that framed the two-limb criterion`, never a bare number alone, because a line that is only a number is exactly the reference that stops carrying meaning on renumber. An ADR with no provenance issue references omits the section rather than shipping an empty heading.

**Why `## References` specifically.** Two independent gates evaluate placement — the repository-integrity issue-reference gate and the reference-durability detector — and they do **not** recognize the same heading set. `Issue References`, `References`, `Provenance`, `Source` and `Sources` are recognized by **both**; `Related` and `Source(s)` are recognized by the issue-reference gate **only**. `## References` therefore sits in the intersection: an ADR that carries it satisfies both gates and needs no override marker for its provenance, whereas an ADR relying on `## Related` would pass one gate and be flagged by the other. That is the whole reason this guide names one heading rather than offering the recognized set as a menu.

`## Related ADRs` is deliberately in **neither** set. Zone 1 prohibits a bare `#N` there outright, and because these gates treat the first recognized heading as a *cut point* — everything below it counts as placed — recognizing `## Related ADRs` would lift the cut above that section and make a gate accept exactly the placement this guide forbids.

**When the override marker is warranted.** The file-level marker `repo-integrity: allow-issue-ref` (wrapped in an HTML comment) suppresses the issue-reference gate for the **whole file** — placement *and* validity, so a 404, a redirect, a transferred issue, and a pull-request number all pass unexamined once it is present. It is warranted only when **both** limbs hold:

- **Limb 1 — demonstration or synthetic necessity.** The file must *display* an issue-reference construct as its subject matter — self-documentation, a template, a worked example, a test fixture — **or** its numbers are synthetic or out-of-repo and cannot resolve by construction. Carrying provenance is not demonstration.
- **Limb 2 — remedy exhaustion.** Neither remedy is available: the reference cannot be relocated into a designated reference block, because it is inline subject matter rather than provenance; **and** it cannot be replaced by an inline summary without destroying what the file is for.

**Declaration obligation.** A marker declared under this criterion carries a trailing rationale on the same line, inside the comment, naming which limb applies — for example, a marker followed by `— limb 1: the numbers below are synthetic fixture ids, not repo issues`. A bare marker with no rationale is not a declaration, it is a silenced warning, and a reviewer cannot tell the two apart without it. The form is already practiced in the deploy test suite; the obligation makes it the rule.

**An ADR essentially never qualifies.** An ADR's legitimate issue references are *provenance*, and provenance has two sanctioned homes — `source_observations:` and `## References`. Limb 1 therefore fails for essentially every ADR, and reaching for the marker is the signal that a reference belongs in one of those homes instead. The marker is not an ADR-authoring tool.

**The adoption ratchet.** Marker adoption is measured, never asserted — derive both numbers over the same population, and record the ratio rather than either figure:

```bash
ADR_TOTAL=$(ls core/ADRs/ADR-*.md release/ADRs/ADR-*.md | wc -l)
ADR_MARKED=$(git grep -lE 'repo-integrity:[[:space:]]*allow-issue-ref' \
               -- 'core/ADRs/ADR-*.md' 'release/ADRs/ADR-*.md' | wc -l)
# adoption ratio = ADR_MARKED / ADR_TOTAL
```

The rule is monotonic: **the ratio must not increase across a release**, and every net-new marker must carry a rationale naming its limb. Reducing the existing population is a corpus sweep, graded on that sweep and not on any single authoring change. Taking the numerator over a directory glob rather than the `ADR-*.md` glob mixes populations — the ADR READMEs are not ADRs — so both arms use the same glob above.

## Worked example

A condensed real ADR (distilled from [ADR-005](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md), the canonical worked exemplar named in both ADR READMEs). Trimmed to show the shape; the live record carries the full detail.

```markdown
---
title: ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)
status: Accepted
date: 2026-05-17
release: stage-execution-and-process-discipline
deciders: "operator + Stage 5 Solutioning spoke"
tags: [audit, baseline, release-ops, file-overlap, contention-scoring]
source_observations:
  - "The first cross-PR file-overlap audit (2026-05-01) surfaced 4 HIGH-tier files; manual
     classification revealed 3 of 4 were structurally append-pattern (new rows appended, never
     rewritten) and almost never conflict at merge — but the 8-column schema could not express it."
---

# ADR-005 — Append-pattern aware cross-PR contention scoring (extends ADR-001)

## Status

Accepted (operator decision at Stage 4 D-E 2026-05-17; ADR authored at Stage 6 per the Stage 5 spec).

## Context

ADR-001 established the Cross-PR Overlap Audit baseline (HIGH ≥3 / MEDIUM 2 / LOW 1 PRs). Its first
application flagged 4 HIGH-tier files, but 3 were append-pattern — the schema treated all multi-PR
files uniformly, over-reporting append-only files as contention and diluting the signal.

## Decision

Extend the contention-matrix schema with two columns (`line_ranges`, `overlap_class`); classify each
contended file by pairwise hunk overlap; preserve the ADR-001 baseline unchanged for pre-cutover audits.

## Alternatives Considered

- (A) Schema extension + zero-tolerance threshold + canonical script — SELECTED (all surfaces agree).
- (B) Schema-only, no script — REJECTED (≥3-PR hand-classification is not reproducible).
- (C) Script-only, no schema column — REJECTED (overlap_class must persist as a durable artifact).
- (E) Modify ADR-001 in place — REJECTED (violates the "ADR-001 unchanged" constraint).
- (F) Renumber ADR-002 — REJECTED (ADR numbering is append-only; breaks cross-references).

## Consequences

Positive: future audits surface actionable (line-range-overlap) contention; append signal preserved
without dilution; ADR-001 baseline byte-preserved. Negative: coordinate-shift conservatism; a new
script joins the audit toolchain; unified-diff edge cases surface as warnings.

## Reversibility

CHEAP — additive at the schema layer (two columns appended; pre-cutover audits unaffected); the
script is a single new file; revert is a `git revert` on the release merge plus two file deletes.

## Related ADRs

Extends ADR-001 (baseline preserved unchanged). Both remain operative: ADR-001 as the 8-column
baseline, ADR-005 as the 10-column enrichment.
```

## Supersession + immutability

**ADRs are immutable once Accepted.** A ratified ADR is an append-only record. To change a decision, **do not edit the Accepted ADR** — author a **new** ADR that supersedes it, and update only the superseded ADR's `## Status` block to point forward (`Superseded by ADR-NNN`) per [`adr-schema.md` §5](../schemas/adr-schema.md). The body below `## Status` is frozen **against decision revision** — the narrow class of durability-hygiene edits that an Accepted record may still receive, and the closed list of edits it may not, are defined in the carve-out at the end of this section. The Nygard `Deprecated` / `Superseded` statuses (see both READMEs' Status-enum table) are the *only* status mutations a live ADR receives after acceptance. Renumbering at merge (collision resolution) is a mechanical exception, and it is recorded in a `## Status` "Numbering provenance" note (specimens: ADR-005, ADR-028/029, ADR-032, ADR-033).

This composes with [`adr-schema.md` §5](../schemas/adr-schema.md), which owns the *representation* — how supersession is expressed in frontmatter and prose: (a) `status:` begins with `Superseded` (optionally `Superseded by ADR-NNN`); (b) the `## Status` block cites the superseding ADR; (c) `## Related ADRs` carries the link. This guide owns the *policy* (supersede-not-edit); the schema owns the representation. Live specimen: ADR-029 (`status: Superseded by ADR-045`), whose `## Status` records that the record remains unchanged for audit trail — the policy is already practiced; this guide codifies it.

### Durability-hygiene edits on an Accepted ADR (the immutability carve-out)

Immutability protects the **decision**, not the bytes. Editability has three states, keyed on the existing `status:` field — no new field, no new vocabulary:

| `status:` leading token | Editability |
|---|---|
| `Proposed` | **Freely editable.** Not yet ratified, so there is no audit trail to protect. |
| `Accepted` | **Durability-hygiene only** — the carve-out below. |
| `Superseded` / `Deprecated` | **Frozen.** No edits at all. The record exists to preserve what was decided and why it stopped applying. |

The **frozen edge** of this partition is the one the durability lint already implements: its whole-file exemption covers `Superseded` / `Deprecated` records only, and it scans every `Accepted` one — so **every finding it reports asks for an edit to an Accepted ADR**. It does not implement the `Proposed`/`Accepted` edge at all; a `Proposed` record is scanned exactly as an `Accepted` one, because that edge governs who may edit, not what the lint reports. The carve-out grants no new permission. It states the reading the shipped tooling already operates under, and that this guide's own enforce-flip clause already assumes when it gates the flip on a full structural-conformance pass.

**The boundary is RECORD vs. REVISE.**

- An edit that **records** something the decision already contained — or removes an anchor that has since rotted — is hygiene. It leaves the decision exactly where it was.
- An edit that **revises** what the decision *was* requires a new ADR that supersedes the old one. Always. There is no in-place path.

**Permitted on an `Accepted` ADR.** An **open** list: each entry is an instance of the invariant, not a special case, so a new hygiene class is admissible if and only if it passes the record-vs-revise test.

| Permitted | Why it is hygiene |
|---|---|
| Removing a stale anchor — a hardcoded commit SHA, a live corpus-population count — or anchoring it historically | What is repaired is the *citation*, not the decision. |
| Adding a required body section that is missing | The section records what the decision already weighed; it does not change what was decided. |
| Normalizing a section heading to its canonical string, or promoting recall content from H3 to its H2 position | Pure relocation of content that is already in the record. |
| Depersonalization — replacing an operator handle with the sanctioned literal name | The `deciders:` fact is unchanged; only its rendering is. |
| Repointing a link or path after a corpus move | The referent is unchanged. |

**Forbidden on an `Accepted` ADR.** A **closed** list. Anything here requires supersession, never an in-place edit:

1. The **decision** itself — what was chosen.
2. The **alternatives** that were weighed, or their verdicts. Adding a *missing* `## Alternatives Considered` section is permitted above; rewriting one that is already there is not.
3. The **consequences** — including softening a negative one.
4. The **status** value, other than the Nygard `Deprecated` / `Superseded` transitions.

The asymmetry is deliberate. The permitted list is open so that a new hygiene class does not need a governance change; the forbidden list is closed so that the hard edge sits on the side that protects the audit trail.

**No fabrication.** Where an Accepted ADR is missing its `## Alternatives Considered` section, record **only** alternatives evidenced by that ADR's own artifacts — its `## Context` / `## Decision` prose, its `source_observations:`, or the release named in `release:`. Where the artifacts do not evidence what was weighed, **do not reconstruct it**: write the single-forced-approach declaration, or record the alternatives with an explicit provenance note naming the evidence used. Inventing alternatives for a ratified architecture record is fabrication, not hygiene — and a backfill sweep that reconstructs plausible options across a corpus of Accepted records is a fabrication engine, not a conformance pass. This is a hard rule, not guidance.

**Reconcile; do not annotate.** A hygiene edit repairs the text in place. It does not add an edit-history note, a changelog block, or a `corrected on YYYY-MM-DD` marker to the record — that would put mutable content inside the immutable artifact, and git already carries the edit history.

**Frozen stays frozen.** A `Superseded` or `Deprecated` record receives no hygiene edits at all, not even the permitted ones. Its stale anchors are part of what it preserves.

## Related

- [`core/schemas/adr-schema.md`](../schemas/adr-schema.md) — the ADR data contract (frontmatter fields + body sections + supersession representation). This guide's template references it; the two are paired (policy/ergonomics here, data contract there) per its §6 Boundary.
- [`core/ADRs/README.md`](../ADRs/README.md) and [`release/ADRs/README.md`](../../release/ADRs/README.md) — the core-module and release-module ADR indexes; each carries the Status enum, the Reversibility tier table, and the § Repo-integrity authoring discipline (author ADRs to those gates).
- [`core/disciplines/decision-discipline.md`](../disciplines/decision-discipline.md) — the sibling discipline for **decision-class briefings** (recommendations the operator acts on). It does **not** govern ADR authoring; this guide does. Cross-referenced to keep the boundary explicit.
- [`release/references/pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) — the Stage 5 process where ADRs are materialized during a release (the `adr-opened` / `adr-closed` audit-trail events cite this guide's when-to-write rubric).
- [`core/specs/reversibility-protocol.md`](../specs/reversibility-protocol.md) — the four-tier reversibility enum used by the `## Reversibility` section.
