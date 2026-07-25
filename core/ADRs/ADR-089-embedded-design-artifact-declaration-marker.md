---
title: "ADR-089 — Embedded design-artifact declaration via a section-level HTML-comment marker"
status: Accepted
date: 2026-07-24
release: design-artifact-backfill (#291) (v3.87; bound at the Stage-12 tag-claim, re-rendered from provisional v3.86 after a concurrent claim)
deciders: "Stage 5 Solutioning spoke drafted the options analysis + trade-off matrix inline per the read-only Solutioning discipline; the Stage 6 Engineering spoke committed it; the operator ratifies at the design-artifact-backfill Collective Review scope-lock / Stage 9"
tags: [core, design-artifact, identification, embedded-marker, knowledge-corpus, standard-amendment, declaration-over-inference]
source_observations:
  - "`design-artifact-standard.md` §9 defined the default artifact placement as an embedded section in a parent doc where 'the parent doc IS the source-of-truth; no separate file exists' — carrying no marker, no frontmatter, and no naming convention, so an embedded artifact was indistinguishable from ordinary prose in the same file."
  - "A current-state survey (2026-07-24, commit 68736d5) proved identification cannot be rendering-based: three of the seven flow types (data-flow, concept-model, skill-flow) render as markdown tables, and four §2-cited artifact-bearing files (operating-model.md, stage-io-contracts.md, five-function-spine-and-process-flows.md, delivery-engine/SKILL.md) carry 0 fenced blocks and 0 Mermaid. Any fence/Mermaid count is structurally blind to them."
  - "The corpus already uses the HTML-comment directive-marker idiom heavily — 495 files carry a `<!-- key: value -->` marker (reference-durability / repo-integrity families) — so a section-level marker reuses an existing declaration mechanism rather than introducing a new class."
  - "The spike (#3614) surfaced that a parent-frontmatter index over an unqueryable set is a drift surface: a section added without a matching index entry silently goes missing. That is the failure mode the chosen mechanism must avoid."
---
<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->

# ADR-089 — Embedded design-artifact declaration via a section-level HTML-comment marker

## Status

Accepted — authored at Stage 6 Engineering of release `design-artifact-backfill` (v3.87) from the Stage-5 Solutioning draft; ratified at the operator's Collective Review scope-lock / Stage 9 plan-review gate and shipped in the merged release PR #3796. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

`design-artifact-standard.md` §9 gave an embedded design artifact — the platform's *default* artifact placement — **no marker, no frontmatter, and no naming convention.** The consequence is not cosmetic: the artifact set cannot be enumerated, so the six flow-type backfill children's completion conditions ("every existing platform `<flow-type>` process has a design artifact") are untestable in both halves, staleness is undetectable, and a reader-facing index would have to be hand-maintained.

Dedicated artifact files have a clean answer — the `depicts:` + `flow_class:` frontmatter fields §9 already specified and this release promotes from deferred to required. Embedded artifacts are the genuinely unsolved half, and a current-state survey (2026-07-24) showed why the obvious approach fails: identification **cannot be rendering-based.** Three of the seven flow types render as markdown tables, and four §2-cited files carry **0 fenced blocks and 0 Mermaid** — so any mechanism that inspects diagram *shape* (a fence count, a Mermaid count) is structurally blind to the heaviest artifact-bearing files. Identification must rest on an **explicit declaration**.

The declaration mechanism for embedded artifacts must therefore: (a) be machine-queryable with one grep; (b) distinguish an artifact section from ordinary prose in the same file; (c) carry the flow-class + depicts payload; and (d) not force the section into a machine-oriented shape that harms the human reading surface (the audience-separation concern raised on the spike).

## Decision

**An embedded design artifact declares itself with a section-level HTML-comment marker placed on its own line immediately below the artifact's section heading:**

```
<!-- design-artifact: flow-class=<one-of-7>; name=<artifact-name>; depicts=<path>[,<path>...] -->
```

The marker bounds the **declared region** — from the marker line to the next heading of the same or higher level — which *is* the artifact; everything else in the parent doc is ordinary prose. Discovery is the enum-anchored query `grep -rnE '<!-- design-artifact:[^>]*flow-class=(architecture|data-flow|agent-process|human-process|concept-model|skill-flow|decision-tree)\b' core operations release docs` — anchored on a real flow-class value and field-order-tolerant (`[^>]*`), so grammar and bracketed-example lines that quote the marker do not self-match (the `>` in `[^>]` is what excludes them; see the standard's § 9 / § 12.2). The mechanism reuses the corpus's dominant directive-marker idiom (495 files already carry `<!-- key: value -->` markers), so the parsing tooling pattern — and eventual hook/CI wiring — already exists.

**Options considered + trade-off matrix.**

| Dimension | **A. Section-level HTML-comment marker (CHOSEN)** | B. Parent-frontmatter `design_artifacts:` index | C. §9 canonical-heading convention |
|---|---|---|---|
| Machine-queryable | one `grep` | frontmatter parse | brittle regex on free-form heading text |
| Declaration↔artifact coupling (drift-resistance) | co-located under the heading | index in frontmatter, artifact 100s of lines below — add a section, forget the entry → silent miss | the heading *is* the artifact |
| Carries flow-class + depicts payload | inline in the marker | structured list | heading cannot carry payload without extra convention |
| Audience-neutral (human-invisible on GitHub) | HTML comment renders invisibly | frontmatter hidden | forces "Design Artifact:" into the reader-facing heading |
| Idiom fit (existing precedent) | 495-file directive-marker precedent | list-frontmatter exists but no per-section-index precedent | §4 deliberately does *not* force a heading form |
| Authoring cost | one line per artifact | one nested entry per artifact + keep index in sync | zero syntax, but rewrites headings |
| Tooling reuse (hook/CI) | same parser class as reference-durability / repo-integrity markers | new frontmatter-list parser | heading-text matcher (false-positive-prone) |
| Reversibility | MODERATE | MODERATE | MODERATE-EXPENSIVE (heading rewrites ripple to anchors/inbound links) |

**Why A over B.** B decouples the declaration from the artifact, reintroducing exactly the "index over an unqueryable set is a drift surface" failure the spike named — a projection that silently goes stale when a section is added without an index entry. A keeps the declaration welded to the artifact, visible in the same diff.

**Why A over C.** C pollutes the human reading surface and fails the audience-separation constraint; its heading-text parse is also the least reliable query. §4 already declines to force a heading form, so C would contradict a live section of the standard.

## Consequences

- (+) One idiomatic query enumerates all embedded artifacts; combined with `grep -rl '^depicts:'` for dedicated files, the full artifact set is machine-queryable — unblocking the six backfill children's completion tests, staleness detection, and a generated reader index.
- (+) Reuses existing marker tooling; a fast-follow hook/CI check (validate the `flow-class` enum + `depicts` path resolution) is a small additive step, not a new mechanism class.
- (+) Immune to the table-invisibility failure — discovery never inspects diagram shape, so a pure-table artifact (0 fences) is found and classified like any other.
- (−) One marker per embedded artifact must be authored and kept under its heading. Mitigated: co-location makes drift visible in the same diff, unlike a remote index.
- (−) A marker can be omitted at authoring time, and an unmarked artifact stays invisible. Mitigation: the fast-follow validation check plus the §7 design-artifact activation gate are where new artifacts get their marker; the backfill children are where existing ones do.

## Reversibility

**MODERATE · Confidence HIGH.** CHEAP pre-application — zero embedded artifacts are declared today, so reverting the mechanism before it is used changes nothing on disk. It crosses to MODERATE once embedded artifacts are marked under the rule, from which point a reversal must re-mark (strip the markers from) those sections. No data migration, no schema change; `git revert` of the introducing PR removes the §9 amendment and the new §12. The staged release ordering (do not author build artifacts until this mechanism is merged + stable) preserves the "nothing to migrate" property through Wave 1.

## Related ADRs

- **ADR-015** (centralized-diagram location) — the placement layer this decision sits atop. ADR-015 decided *where* dedicated artifacts live; ADR-089 decides *how* both dedicated and embedded artifacts are made identifiable. No conflict — ADR-089 is the identification layer over ADR-015's placement layer.
- No superseding or superseded relationship. This is the first ADR to govern design-artifact identification.

### Issue References

- #3725 — the Phase 0.5 identification-mechanism story this ADR is the design record for (promotes `depicts:` to required, adds the embedded-artifact marker + per-flow-type detection criteria).
- #3614 — the enumeration spike whose partial run surfaced that identification is the missing prerequisite, and whose operator input named the index-drift failure mode this decision avoids.
- #64 — the shipped `architecture-platform-structure.md` pilot the mechanism must (and does, after the Stage-6 backfill) identify.
- #3437, #3438, #3439, #3440, #3441, #3442 — the six flow-type backfill children whose completion conditions this mechanism makes testable.
- #291 — release milestone `design-artifact-backfill`, under which this record was authored.
