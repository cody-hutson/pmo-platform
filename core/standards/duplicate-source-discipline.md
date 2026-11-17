---
title: Duplicate-Source Discipline — Register or Remove
purpose: "The register-or-remove discipline for content reused across files: duplicated content joins the enforced mirror set, consolidates to one canonical source, is registered as an allowed exception, or is registered as a complementary pair with machine-checkable section ownership. It also names which side is authoritative when a document and the tree it describes or governs disagree."
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: deploy.sh Check 9 / Check 11 / Check 13 (mirror-set + template-sync registries), Check 13b (complementary-pair ownership registry), Check 68 (hub-state enum-parity registry), and Check 83 (enumeration ↔ population markers, § 1.1); authors of any content reused across files; CLAUDE.md §Prefer durable structures
---
<!-- reference-durability: allow-link -->
# Duplicate-Source Discipline — Register or Remove

## Purpose

Defines the platform's discipline for content reused across multiple files: any duplicated content either (a) joins the registered mirror set and gains byte-identity enforcement, (b) is consolidated to a single canonical source with cross-references replacing former duplicate sites, (c) is registered in a per-domain exemption list with rationale, or (d) is registered as a complementary pair whose division of labour is declared as machine-checkable section ownership. Establishes the canonical home for the **register or remove** rule, consolidating three implicit anti-duplication guardrails in [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) into a single statement. It also states which side is authoritative when a written convention and the live practice it governs disagree (§ 1.2), a case that reaches past the content-reuse scope of § 3.

This is option (a) per the originating initiative's Stage 5 — documentation-only at current platform scale. Scan-based enforcement (future Check 14) is deferred per §6 escalation triggers; the **CONFLICT** with `anthropic-skills:skill-creator` convention that scan-based enforcement would introduce is preserved here for future re-evaluation, not resolved by enforcement today.

## §1 Principle — register or remove

Content MUST NOT exist in two or more files within `core/` / `release/` or `.claude/` unless one of four conditions holds:

1. **Registered as a mirror.** Both copies are listed in the platform's mirror registry and gain byte-identity enforcement under `deploy.sh --check` Check 9 / Check 11 / Check 13 (see §2). The system enforces drift detection.
2. **Consolidated to a canonical source.** Content lives in exactly one file; former duplicate sites are replaced with cross-references (markdown link to the canonical source).
3. **Registered exemption.** A per-domain exemption is documented in the principle that owns the duplicated surface (e.g., legitimate parallel structures across SKILL.md files governed by [canonical-skill-structure.md](canonical-skill-structure.md); see §3). A second worked instance: the decision-confidence trigger predicate is stated in both `core/specs/decision-confidence-protocol.md` `§ 1.0 — The objective trigger predicate` and `core/rules/decision-time-adherence.md` `§ 1 — What fires a checkpoint`, because the rule is deployed to the running agent and the spec is not, so the rule cannot cite its way out. An edit to the predicate must land on both surfaces in the same change, and the full record — the necessity, and why conditions 1, 2 and 4 are unavailable — is documented once in that spec's `§ 1.0` and is not restated here.
4. **Registered as a complementary pair.** The two copies share a basename but are **not** copies of each other: each exclusively owns a declared set of sections, and a third declared set is shared by both. The pair is registered in `core/deploy/allowlists/complementary-reference-pairs.txt` with its division of labour stated as machine-checkable section ownership, and `deploy.sh --check` Check 13b asserts that ownership on every run — each exclusively-owned section present in its owner and **absent** from its peer, each shared section present in both, and a shared section whose content has drifted reported as a distinct finding. This is distinct from condition 1: condition 1 registers **sameness** (byte-identity, Check 13); condition 4 registers **complementarity**. A pair that should be byte-identical does not belong here, and a complementary pair does not belong in `TEMPLATE_SYNC_MAP`. Unlike condition 3, the exemption is not prose — it is asserted mechanically, so a deliberate split and an accidental fork are distinguishable to the gate surface. See [ADR-104](../ADRs/ADR-104-complementary-reference-pair-registration.md).

Unregistered duplicate content is governance debt. The longer it persists, the higher the drift risk: one copy is updated, the other becomes silently stale, and downstream consumers act on the stale read. The register-or-remove rule forecloses that path.

### §1.1 The enumeration case — a document lists or counts a population that changes

A **hand-maintained enumeration** is a document's copy of a population's membership: a list of the files a directory holds, or a stated count of them. When the population changes and the copy does not, the copy keeps reading as authoritative while it is wrong. It is reconciled toward the population — **the population is the fact, and the enumeration moves**. That is the opposite default to § 1.2, *The convention case — a written rule and live practice disagree*, and neither case's rule decides the other's.

An enumeration of a population that changes is remedied as the table below orders it, the most preferred first:

| Remedy | When it applies | Register-or-remove condition |
|---|---|---|
| **Cite** the population's home instead of copying it | The default. A reader can follow a reference to the directory, registry or record that holds the members | Condition 2 — one canonical source, a reference at the former copy |
| **Derive** the copy with a projector, declared by a `derived-surface:` header | The copy must exist inline, and generating it is proportionate | Condition 2 — one canonical source, and a copy no one edits by hand |
| **Mark** the copy with an enumeration marker | A reader needs the members inline, and a generator would be disproportionate for hand-written prose | Condition 1 — a registered copy whose drift is asserted mechanically |

A **closed set** — one that changes only by a governed decision, such as the autonomy tiers — needs none of these. An enumeration whose population is already bound by a re-derived census record is **cited, not marked**: the census is its binding, and a marker would put a second copy of the census's resolver beside it. The suite steps of `.github/workflows/install-tests.yml` are the worked instance: the workflow cites the install-regression runner's member array and the gate-efficacy standard's § Exit-consumer and executor census rather than carrying a marker.

**The marker.** It is a single line, directly above the enumeration's preamble, or directly above the enumeration when it has none:

```text
<!-- enumerates: <glob> <relation> -->
<!-- enumerates: core/hooks/block-*.sh list -->
```

- **Glob.** Repository-relative, with no leading `/`, no `..` segment and no `**`. A wildcard (`*`, `?` or `[…]`) matches within one path segment and never across a `/`, and the glob is matched against the tracked files.
- **Relation.** `count` — the line beneath the marker states one cardinal, and it must equal the number of files the glob matches. `list` — the items must name exactly those files. `subset-of` — every item must name one of them; a file the list leaves out is not drift, so `subset-of` never asserts completeness.
- **Binding.** Under `list` and `subset-of`, at most one line of prose (the preamble) may sit between the marker and the list or table it binds.
- **Keys.** A file the glob matches is keyed by the path segments its wildcards match: the basename for `core/hooks/block-*.sh`, the directory name for `operations/skills/*/SKILL.md`. An item is keyed by its first link target, resolved against the document's own directory (a leading `/` resolves from the repository root), read at the same segments. An item whose link points outside the glob's literal segments names no member, so it reads as extra. An item with no link is keyed by its first code span, written as the same segments joined by `/`.

**What the check does not detect.** An enumeration with no marker; one in an exempt tree (the frozen release corpus, the deliberate-defect fixture trees, `packages/` and `.github/`); a population no glob expresses; a relation that filters rows; an inline comma-separated list under `list` or `subset-of`; an enumeration outside markdown; whether an item's description is still true; and completeness under `subset-of`.

**Runner: NONE — a registered named gap.** Whether an enumeration of a changing population was cited, derived or marked when it was written is a judgment no gate observes: an unmarked enumeration is invisible to every check. The gate-coverage register in [`gate-efficacy-standard.md`](gate-efficacy-standard.md) records the gap and the observable that stands in for it — a diff that adds such an enumeration with neither a citation nor a marker. A marked enumeration is read by `deploy.sh --check`'s enumeration-drift check, deploy-time only, whose `--self-test` also runs in CI through the selftest-discovery job; that check asserts each marker, never this procedure.

### §1.2 The convention case — a written rule and live practice disagree

A **written convention** is a rule a governed document states about the tree it governs — where a file lives, what a sidecar is named, which field a record carries. **Live practice** is what the tree actually does. When the two are found to disagree, the disagreement is settled by the owning document — not by the report that surfaced it, and not by whichever side is cheaper to change — in this order.

1. **Read the owning document first.** Where it states the rule for the case at hand, it already names the authoritative side, and practice is reconciled toward it: the file moves, the field is renamed, the sidecar is added. The report that surfaced the divergence — an observation, an audit finding, a review comment — is a directional input and not a second ruling. Re-deciding a case the document already decides is the defect this clause exists to stop. A convention the document names is not the stale state that `core/disciplines/reconcile-dont-annotate.md` tells an editor to reconcile to current state: the tree is the side out of date, and reconciling means moving the tree.
2. **Where the document is silent or ambiguous on the case, name the authoritative side in the document, in the same change that reconciles the other side.** Either side may win. When practice wins, the document is amended to state what practice does; when the rule wins, practice is reconciled to it; when the two turn out to govern different things, the document is amended to say so and practice stays. In every outcome the document ends by naming the case, so the next reader applies a rule instead of re-deciding it.
3. **Record the resolution.** The record names the divergence, the authoritative side and the section of the document that names it, what changed — practice, the document, both, or neither when the document already shows the reported divergence is not one — and why. A change that travels in a release records it on one line of that release's plan, opening with `**Adjudication record:**`; a change that travels outside a release, in a pull request no release plan covers, records it in an `Adjudication-Record:` trailer on the commit that resolves the divergence. The document holds the rule and the record holds the history, so the record never restates the rule. A resolution written only in a work-item thread, a pull-request body or a session transcript has no durable home.

**What this case does not govern.** A hand-maintained enumeration — a document's copy of a population's members or of their count — describes the tree rather than prescribing it, so it resolves the opposite way: the population is the fact and the copy moves (§ 1.1). This clause's rule never decides that case, and that case's rule never decides this one. The test between them is one question: does the passage say what the tree *is*, or what the tree *should be*?

**Where this case reaches** is wider than the rest of this document, and § 3 states it.

**Runner: NONE — a registered named gap.** Whether a resolver read the owning document before choosing a side is a judgment no gate observes. The gate-coverage register in [`gate-efficacy-standard.md`](gate-efficacy-standard.md) records the gap and the observable that stands in for it: the resolution's record. A divergence class whose resolved state is mechanically checkable may also carry a check of its own; that check asserts the class, never this procedure.

## §2 Registered enforcement layer

Six registered `deploy.sh --check` checks make up the enforcement layer today:

| Check | Surface | Enforcement | Source |
|---|---|---|---|
| **Check 9** — Rules-mirror sync | canonical source `core/rules/<name>.md` (for release-process.md the source is `release/governance/release-process.md`) ↔ deployed mirror `~/.claude/rules/<name>.md` | Byte-identity required; mismatch → DRIFT [SOURCE: `deploy.sh:1695`] | — |
| **Check 11** — Harness-mirror sync | `harness/<name>/` ↔ `~/.claude/<name>/` for every entry in `HARNESS_LIST` (currently `account-switcher`) | Byte-identity required on canonical files; operator-state files (per `HARNESS_OPERATOR_STATE` allowlist) preserved [SOURCE: `deploy.sh:1798`] | Per D-1.B |
| **Check 13** — Template-sync drift detection | `TEMPLATE_SYNC_MAP` byte-identity-enforced template pairs | Byte-identity required; matches Check 1 / Check 11 zero-FP posture [SOURCE: `deploy.sh:1929`] | — |
| **Check 13b** — Complementary-pair ownership | registered pairs in `core/deploy/allowlists/complementary-reference-pairs.txt` | Section-ownership assertion, **not** byte-identity: each exclusively-owned section present in its owner and absent from its peer; each shared section present in both, with content divergence reported as a distinct finding. An unregistered cross-tree same-basename pair is surfaced as a possible accidental fork. Warn-mode (shared cohort) | Condition 4 |
| **Check 68** — Hub-state enum parity | registered `(derived surface, field)` pairs in `core/deploy/allowlists/hub-state-enum-parity-map.txt` | **Value-set equality**, not byte-identity: the derived surface's `<field> enum:` declaration and the standard section that owns the enum must enumerate the identical set, and a `(N values)` cardinality on the owning heading must match the set beneath it. Two renderings of one enum are never byte-equal by construction — a slash-delimited list versus a markdown definitions table — so `TEMPLATE_SYNC_MAP` (Check 13) is structurally inapplicable and this is the registry that can hold the pair. The derived side is named in every finding, because "mismatch" alone leaves undecided which file moves. Warn-mode initial | Condition 1 |
| **Check 83** — Enumeration ↔ population | `<!-- enumerates: -->` markers in tracked markdown (§ 1.1), each binding an enumeration to the tracked files its glob matches | **Population correspondence**, not byte-identity: under `count` the stated cardinal equals the number of matching files, under `list` the items name exactly those files, and under `subset-of` every item names one of them. Warn-mode initial, on the check's own committed dial | Condition 1 (§ 1.1) |

They assert four different invariants, and the difference is what decides which registry a duplicate belongs in. Checks 9, 11 and 13 assert **byte-identity** on registered mirror surfaces — the condition-1 case where two copies are meant to be the same bytes. Check 13b asserts **section ownership**, the condition-4 case where two files share a basename and deliberately divide the content between them. Check 68 asserts **value-set equality**, a condition-1 case that byte-identity structurally cannot hold: two renderings of one enum — a slash-delimited list and a markdown definitions table — are never byte-equal by design, so a pair that must agree on *meaning* rather than *bytes* needs its own registry. Check 83 asserts **population correspondence**, a condition-1 case neither form can hold: its two sides are a document and a population of files, so there is no second document whose bytes or values could be compared, and the enumeration is graded against the files themselves.

**Why Check 68's surfaces restate rather than consolidate.** Condition 2 (*consolidate to a canonical source*) is the normal preference and is **wrong for this pair class**, on a property specific to it: the derived surfaces are **deployed and their contract is not**. The hub-state templates are copied wholesale into operator-instance runtime ledgers that are read without the repo open, and `release/skills/release-hub/references/orchestration-playbook.md` ships inside `packages/release-hub.skill` and is read from the deployed skill tree — while `core/standards/**` appears in no package and is not deployed at all. Replacing either restatement with a cross-reference would point a runtime reader at a file absent from their machine, trading a drift risk (which registration closes mechanically) for a resolvability failure (which nothing closes at read time). The general rule this instantiates: **restate when the derived surface is deployed and its contract is not; cite when the contract is at least as reachable as the surface restating it** — and a restatement is only ever a valid answer as *restate + register + mechanize*, never restate alone.

**Out of scope for these checks:**
- Content-level near-duplicates outside the registered mirror set (the gap this principle addresses).
- SKILL.md content duplicates across skills (governed by [canonical-skill-structure.md](canonical-skill-structure.md); see §3).

**Orthogonal:** `deploy.sh --check` Check 3 enforces filename-collision detection (APFS case-sensitivity duplicates in package staging); it covers a different duplicate class than this principle and complements rather than overlaps the register-or-remove rule.

## §3 Scope boundary

This principle covers **content-level duplicates outside the registered mirror set** within `core/` and `release/` (governance, reference/standards/specs/schemas/disciplines, releases) and `.claude/rules/` and workspace-root governance files (CLAUDE.md, README.md).

The convention case of § 1.2 reaches further than this scope: it applies wherever a governed document states a convention about the tree it governs — artifact placement, sidecar naming, template and corpus layout, `operations/templates/` included — and the content-reuse scope above does not narrow it.

**Out of scope — governed elsewhere:**
- **SKILL.md boilerplate across skills** is governed by [canonical-skill-structure.md](canonical-skill-structure.md) (the canonical home for skill-authoring discipline). Skills MAY share boilerplate text by design; this preserves compatibility with `anthropic-skills:skill-creator` convention. Any future scan-based enforcement (see §6) MUST exclude `<module>/skills/` from its scope.
- **Filename-collision duplicates** are covered by `deploy.sh --check` Check 3 (orthogonal — see §2 footer).
- **Layer 2 operational content** (`projects/`) is Cowork-managed and outside the engineering governance surface.

## §4 Authoring-time check (operative gate today)

The operative enforcement mechanism at current platform scale is the [CLAUDE.md "Pre-creation governance check" guardrail](<OPERATOR_INSTANCE_CLAUDE_MD>) (line 134):

> Before authoring a new file or artifact, search existing governance for a defined home for that data type. CLAUDE.md governance file map, OPERATIONS.md operational artifacts table, and `pipeline/` stage outputs are the canonical lookup surfaces — milestone descriptions, SKILL.md sections, and reference docs are common pre-defined homes. Authoring a parallel artifact when a governed home exists violates "No ungoverned changes" AND duplicates the governance contract. Cite the search result before drafting any new file.

This guardrail catches duplicate sources at authoring time before they enter the corpus. It is human-in-the-loop and judgment-based; no automated scan runs at deploy.

The companion guardrails this principle consolidates:

- **Intermediate-artifact discipline** ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 135) — sizing analyses, scratch breakdowns, and reorganization workings are absorbed into the target structure, not promoted to durable artifacts. Prevents stepping-stone artifacts from accumulating as parallel sources.
- **Prefer durable structures over static examples** ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 158) — decision tables, schemas, and parameterized templates are preferred over prose duplication. Prevents the "copy the table into both files" anti-pattern.

Together these three guardrails ARE the platform's anti-duplication enforcement at current scale. This principle doc is their single canonical statement.

## §5 Periodic audit

Operator review for emergent duplicate content occurs at:

1. **Stage 3 Bundle gate.** When bundling release scope, the Stage 3 Pre-creation governance check ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 134) covers duplicate-source-as-emergent-pattern. Newly proposed files are checked for canonical-home existence before authoring.
2. **Stage 4 Planning.** When contention maps surface during release planning, file-overlap-audit per `<OPERATOR_INSTANCE_ANALYSIS_PATH>/file-overlap-audit-<date>/` may incidentally surface content duplication along with file-edit contention.
3. **Opportunistic discovery.** Content drift discovered during normal operation (e.g., during `pmo-skill-editor` audits, `pmo-qa-auditor` reviews, governance file edits) is reported as a GitHub Issue per the [CLAUDE.md auto-logging rule](<OPERATOR_INSTANCE_CLAUDE_MD>).

No scheduled scan runs. The cadence is event-driven, not periodic.

## §6 Escalation trigger — future Check 14

Scan-based enforcement (option (b) per Stage 5 of the originating initiative) is deferred at current scale. Re-evaluation is warranted when ANY of the following triggers fire:

1. **Scale trigger.** Platform grows to ≥2× current governance / reference / rules file count (count baseline: SHA at merge of the originating initiative's implementation).
2. **Incident trigger.** ≥3 duplicate-source incidents surface in any 90-day window (incident = stale-read drift causing downstream defect; tracked via `gh issue list --search "is:issue label:bug duplicate-source in:title,body"`).
3. **Manual-review-failure trigger.** Operator manual review starts missing duplicates that subsequently cause drift incidents (signal: a duplicate-source incident is filed AFTER the duplicated content was reviewed at Stage 3 Bundle without being flagged).

When a trigger fires, the future deploy.sh hook is **Check 14** — NOT Check 13 (claimed by the template-sync-drift detection check). The numbering is reserved here to prevent collision at future Stage 4 planning.

### Pre-loaded design (CONFLICT mitigation preference order)

Scan-based enforcement would conflict with `anthropic-skills:skill-creator` convention — skills MAY share boilerplate text by design [SOURCE: convention review at the originating initiative's Stage 5, 2026-05-11]. When Check 14 ships, the CONFLICT MUST be resolved using the preference order rendered at the originating initiative's Stage 5:

1. **Preferred — scope-exclude `<module>/skills/` entirely.** Scan limited to `core/` and `release/` (governance, reference/standards/specs/schemas/disciplines, releases) + `.claude/rules/` + workspace-root governance files. Cleanest CONFLICT resolution; cleanly defers SKILL.md content discipline to [canonical-skill-structure.md](canonical-skill-structure.md).
2. **Section-exempt named SKILL.md boilerplate sections** (e.g., persona blocks, output-contract boilerplate) via section-anchor exemption registered in `.claude/duplicate-source-exemption-list.txt` (new file modeled on the skill-editor exemption list). Higher maintenance cost; consider only if Check 14 needs partial coverage of `skills/`.
3. **Document as PMO-only constraint with full exemption list.** Highest maintenance cost; consider only if (1) and (2) prove insufficient. Exemption list registered under "No ungoverned changes" protocol.

No exemption-list file is created. The principle doc names `.claude/duplicate-source-exemption-list.txt` as the future artifact (when Check 14 ships); creating an empty placeholder now would be ungoverned-theater (an enforcement surface with no enforcement behind it).

## §7 Cross-references

**Umbrella discipline (the broader authoring rule this register-or-remove principle is one facet of):**
- [minimal-addition-discipline.md](../disciplines/minimal-addition-discipline.md) — the **umbrella authoring discipline** (add the minimum that carries the meaning, in service of *simplicity*) that this register-or-remove rule is **one facet** of (the duplication facet).

**Consolidated guardrails (the three implicit anti-duplication rules this principle makes explicit):**
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 134 — Pre-creation governance check (operative gate)
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 135 — Intermediate-artifact discipline
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 158 — Prefer durable structures over static examples

**Registered-mirror enforcement (the existing 3-check enforcement layer):**
- [.claude/rules/skill-deployment.md](../rules/skill-deployment.md) — Check 9 documentation (rules-mirror sync)
- [.claude/rules/harness-deployment.md](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/harness-deployment.md) — Check 11 documentation (harness-mirror sync)
- [deploy.sh](../deploy/deploy.sh) line 1929 — Check 13 implementation (template-sync drift)

**Out-of-scope governance home (preserves `anthropic-skills:skill-creator` compatibility):**
- [canonical-skill-structure.md](canonical-skill-structure.md) — SKILL.md content discipline canonical home

**Establishing initiative:**
- Originating initiative — Generalized duplicate-source detection beyond known mirror pairs
