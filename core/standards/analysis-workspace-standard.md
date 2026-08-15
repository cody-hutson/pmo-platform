---
title: Analysis-Workspace Standard
purpose: Defines the in-repo git-ignored analysis workspace for read-once platform analysis (audits, reviews, gap analyses) — folder + frontmatter schema + sunset rule + the egress boundary governing what corpus content may cross onto a public issue/PR surface — so analysis stays operator working material, never shipped corpus.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: CLAUDE.md §Governance File Map (Program-scoped analysis row); operators and agents creating audit/review/gap-analysis artifacts; the analysis-folder convention cited across the disciplines
---
# Analysis-Workspace Standard

## Purpose

Read-once analysis — release analysis, backlog analysis, audits, reviews, gap analyses
about the platform itself — is **operator working material, not shipped platform
content**. It must not be committed to the repo, yet agents and operators need a
**known, in-repo location** to store and reference it without re-deciding placement
each time.

This standard defines that location, the artifact **frontmatter**, and the **sunset
rule** that prevents unbounded accumulation. It is the tracked *framework* for the
git-ignored `analysis/` workspace — the same framework-tracked / instances-ignored split
the platform already uses for initiative roadmaps
(`core/standards/initiative-roadmap-framework.md` tracked;
`<module>/governance/roadmaps/` instances git-ignored).

## 1. Location & mechanics

| Aspect | Rule |
|---|---|
| **Path** | The repo-root `analysis/` folder. Cross-cutting working material owned by no single module → sited at the root, parallel to the git-ignored `audit-output/` working dir. |
| **Tracked** | Only `analysis/README.md` (the in-folder signpost). The folder ships on clone so the location is always discoverable. |
| **Git-ignored** | Everything else under `analysis/` — every `<name>-YYYY-MM-DD/` subfolder and its contents. Enforced by `.gitignore` (`/analysis/*` with `!/analysis/README.md`). Operator-written analysis never enters git history. |
| **Scaffolding** | None required — the folder exists in the repo via the tracked README; there is no install/resolver step. |

**Scope boundary.** This workspace is for analysis **about the platform/repo** (release,
backlog, platform audits/reviews/gap analyses). It is **not** for:

- **Project** analysis → lives with the project (the Operations domain, `projects/`).
- **Operator personal / cross-cutting** analysis unrelated to the repo → the operator-local
  personal analysis space (outside the repo entirely; an operator-instance location, never tracked).

## 2. Folder convention

Each analysis is one **dated subfolder**: `<name>-YYYY-MM-DD/` (e.g.
`tree-audit-2026-04-18/`, `milestone-194-readiness-prework-2026-06-27/`). Expected
contents: a top-level `SUMMARY.md`; optional `_templates/` / `_scores/` / `_cache/` /
`evidence/` support folders; an optional `issue-drafts/` folder with `NNN-kebab-name.md`
files ready for `gh issue create`. Dating + naming keeps multiple analyses separable and
**links each to the work item it serves** (name the folder for the milestone/issue where
useful).

If an analysis produces a `recommendations.md`, each recommendation carries a per-rec
status badge per `core/standards/audit-recommendation-status-badges.md`
so shipped recommendations stop reading as open scope. That standard governs
*recommendation status*; this one governs *artifact lifecycle* (the sunset rule, §4).

## 3. Frontmatter

Every analysis artifact (at minimum its `SUMMARY.md`) carries:

```yaml
---
analysis_type: release | backlog | audit | review | gap-analysis | research | design | ...   # open enum
work_item: "<#issue | milestone-NNN | epic #NNN>"   # the work item this analysis serves — REQUIRED
created: YYYY-MM-DD
sunset: YYYY-MM-DD          # the date this artifact goes stale (see §4)
status: active | stale | archived          # set per §4 (active until sunset; then stale)
---
```

| Field | Required | Meaning |
|---|---|---|
| `analysis_type` | ✅ | The kind of analysis. **Open enum** — common values are `release` / `backlog` / `audit` / `review` / `gap-analysis` / `research` / `design`; add a lowercase-kebab type when none fits (validate shape, not a closed set — mirrors the `delivery_approach` / `work_item_type` / `deliverable_type` openness). |
| `work_item` | ✅ | The linked work item (issue / milestone / epic). **Analysis is linked to its work item** — this is the back-reference that lets a reader find why the analysis exists and whether it is still live. |
| `created` | ✅ | Authoring date (YYYY-MM-DD). |
| `sunset` | ✅ | The staleness date (§4). |
| `status` | ✅ | `active` → `stale` → `archived`. These values are **analysis-artifact-scoped** — they are field values in this frontmatter, not the cross-machine state vocabularies catalogued in `core/standards/lifecycle-states-canonical.md` (which excludes YAML field-value contexts from its collision rule). |

## 4. Sunset rule (anti-buildup)

Analysis accumulates silently — old audits read as current, and the workspace becomes a
drift surface. The sunset rule bounds it:

1. **Set `sunset` at authoring.** Default: **`created + 90 days`**, OR **`work_item`
   close + 30 days**, whichever is **first**. (An analysis whose work item ships is stale
   30 days later; one whose work item lingers is stale at 90 days regardless.) An operator
   may set an explicit later `sunset` with a one-line reason in the artifact.
2. **Past `sunset` → `status: stale`.** `status` is operator-maintained: an artifact is
   authored `active` and advances to `stale` once its `sunset` passes (the operator flips
   it at review, or simply deletes the artifact) — until the §4 Enforcement automation
   flags it. A stale analysis is no longer current evidence; anything still needed from it
   should have been promoted to its work item or to governance (per the K5 promotion path
   in `core/disciplines/knowledge-architecture.md`: observation → pattern → (maybe) governance).
3. **Stale → archived or deleted.** Because the workspace is git-ignored, removal is a
   local delete (CHEAP, reversible only from local backups) — there is no history to
   prune and no CI to gate it.

> **Enforcement (how `stale` is detected).** This standard ships the convention +
> frontmatter; `status` is operator-maintained today (advanced to `stale` at review when
> `sunset` passes). The intended automation — a **deferred follow-up** — wires staleness
> into the **platform health-tooling / lint** surface: the health/lint pass flags every
> past-`sunset` artifact (and any analysis missing the required frontmatter) so staleness
> is *detected*, not relied upon, and a one-pass purge of stale artifacts becomes
> actionable. The folder being git-ignored means that pass is an operator-local health
> check, not a CI gate.

## 5. Knowledge-tier placement

Analysis is **contextual, fast-mutating working knowledge** — K5-adjacent on the
`core/disciplines/knowledge-architecture.md` tier model (situational,
not the universal K1 corpus). That is precisely why it is git-ignored: committing it would
embed contextual K4/K5 material in the tracked K1 surface. Durable findings graduate out of
`analysis/` via the K5 promotion path (into a work item, a governance change, or a
codified standard) — they are never left to rot in the workspace.

## 6. Egress boundary — what may cross onto a public surface

The workspace is git-ignored, so nothing in it reaches the repository tree. **Issue and
pull-request bodies and comments on the work tracker are a second, separate public
surface**, and a git-ignore rule says nothing about them. This section states what
analysis-corpus content may cross onto that surface. §1's Scope boundary governs what
belongs *in* the workspace; this section governs what may *leave* it.

The boundary is permissive on *derived* content and bounded on *verbatim* content,
deliberately. Grounding a finding in the corpus is what makes the finding checkable; a
blanket prohibition would remove the evidence a reader needs to overturn a wrong
conclusion.

**Permitted without qualification.** Findings and analysis written in the author's own
words. Derived quantities — counts, rates, distributions, N-of-M results, and the probe
records that produce them. Non-identifying citation anchors that let a reader locate the
source in their own copy: a path in a §6.1 sanctioned form, a heading, a line number, a
record or turn identifier. Reproducible commands, provided every path in them uses a §6.1
form.

**Permitted, bounded — verbatim corpus text.** Publish an excerpt only when the finding
does not survive paraphrase: when the exact wording *is* the evidence. One contiguous
excerpt per finding, no longer than the span that carries it, rendered as a blockquote or
fenced block with its citation anchor so the quoted region is delimited and attributable.
A sequence of excerpts that reconstructs a passage is bulk transcription regardless of how
it is split across findings or comments, and bulk transcription is never permitted.

**Prohibited — never published, quoted or paraphrased.** Any absolute operator-local path,
or any leak class named in §6.1. Any operator-identity value catalogued in
`core/standards/depersonalization-spec.md` §1. Any third-party name, client name, project
code, or internal-system name — including any needle the operator has declared in their
localized-context needle file. Any secret category in
`core/standards/secrets-handling-policy.md`.

**Default on doubt: abstract.** The corpus is the evidence; the public surface gets the
finding. An excerpt you cannot justify under the bounded rule is an excerpt to paraphrase.

**Why the rule is stated ahead of the work.** Editing a published issue or comment does not
scrub its edit history, and a tracker's issue surface is world-readable independently of the
repository tree. Crossing this boundary is IRREVERSIBLE, so it is bounded in advance rather
than adjudicated afterward.

**Enforcement — stated, not implied.** Three layers cover this boundary and none covers all
of it.

1. `core/hooks/block-scope-segregation.sh` refuses private- or PII-marked content bound for
   a destination the operator has declared `scope: public`, on the needle classes it can
   detect and within the coverage boundary recorded in
   `core/standards/public-repo-vs-operator-instance-taxonomy.md` §2b.
2. `core/hooks/block-gh-path-leak.sh` (rule `BLOCK-GH-PATH-001`) refuses the §6.1 path
   classes on the authoring session's own tracker writes. It reads its own mode file
   `.gh-path-leak-mode` and **ships at `warn`** — it records and surfaces, it does not
   block. Read it as available, never as in force.
3. Everything else — verbatim non-needle prose at volume — is convention-backed. There is
   no detector for it, and no reading of this section should assume one.

Both hooks are PreToolUse hooks and are therefore subject to the **four-condition coverage
boundary** stated in `core/rules/bypass-mode-readiness.md` — loading, bypass,
master-activation class, and mode. Naming fewer than four overstates the coverage. Condition
1 (loading) is the one that most often fails in practice and it is **not** remedied by any
mode setting: a session rooted in a repo worktree resolves no hook wiring at all until the
operator runs the workspace-setup script's hook-wiring re-home. That step is operator-run,
outside this repository's reach, and its completion is reported by the install validator's
`INSTALL-HOOK-WIRING-REHOME` check. Until it has run on a given instance, layers 1 and 2 are
not active there — a mode change cannot substitute for it.

### 6.1 Sanctioned path forms

Any path published onto a public surface — in prose, in a command, in a citation anchor, or
in a brief an orchestrator emits to a spawned session — uses one of four forms:

| # | Form | Shape |
|---|---|---|
| P1 | Repo-relative | `core/hooks/block-gh-path-leak.sh` |
| P2 | `$HOME`-relative | `$HOME/Claude/pmo-platform` |
| P3 | Sanctioned default-expansion | `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/…` |
| P4 | A registered operator-instance path token | `<OPERATOR_INSTANCE_ANALYSIS_PATH>/…` |

Three forms are prohibited, and they are exactly the classes the shared detection primitive
`core/deploy/tools/path-leak-patterns.sh` flags: an absolute machine path carrying a
username segment; a bare relative operator-instance path with no rooting prefix; and any
form the primitive's exemption predicate does not clear. The permitted list is derived as
the set-complement of the detector's active classes, so a form on one list is off the other
**for every class the detector knows about**.

**Where that derivation does not reach, stated rather than glossed.** A path form the
detector does not model is on neither list — it is not permitted by P1–P4 and it is not
flagged. The known instance is a harness-supplied ephemeral scratch directory, whose parent
on a default install carries the operator's username in a path-mangled segment the machine
pattern does not match. Publish such a directory **by its relative name only** — the
variable name plus the unique directory, never the resolved absolute path. Treat any other
unmodelled form the same way: reduce it to a relative name, or abstract it.

A line that legitimately must carry a flagged form — a worked example of the leak itself —
declares the per-line `path-leak: allow` marker the primitive already honors.

That marker is the **only** way to exempt a home-path-shaped string, and the username in the
path buys nothing: a home path is flagged whatever account name it carries — `user`, `alice`,
`testuser` and any other plausible-looking fixture name are detected exactly like a real
operator's, on both the `/Users/` and `/home/` forms. A username can never distinguish a
fixture from a real path, because the two are the same string. So a test fixture, a rendered
brief, or a `gh` body that must embed a home path carries the marker on that line; there is no
file-scope escape on the runtime surfaces, and the deploy check's path-portability allowlist is
reserved for files that *define* the detection, never extended for fixture convenience.
