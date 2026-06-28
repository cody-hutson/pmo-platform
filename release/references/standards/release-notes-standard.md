<!-- reference-durability: allow-link -->
# Release Notes Standard — User-Facing Notes (Runbook + Template)

## Purpose

Defines the canonical structure, voice, and content rules for **user-facing release notes** produced at Stage 13 Close. Every pmo-platform release emits exactly one user-facing note at `release/releases/notes/vX.Y_RELEASE_NOTES.md`, in addition to the engineering-facing `RELEASE_LOG.md` row and the implementation-facing release plan file.

**Three-artifact chain.** Release notes are the user-facing third artifact in the Outcome (pre-execution intent, per the Stage 3 outcome-statement spec → see [`release-outcome-statement-template.md`](../specs/release-outcome-statement-template.md)) → Change Description (post-engineering operator-facing, per the Stage 6 Change Description Protocol → see [`release/governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Change Description Protocol) → Release Notes (post-merge user-facing, this standard, Stage 13) chain. Outcome anchors WHAT WILL CHANGE; Change Description summarizes WHAT DID CHANGE for the operator; Release Notes communicate WHAT IT MEANS for the user.

This document is both a **runbook** (guidance for authoring a note — tone, depth, topic selection) and a **template** (Part 1: a copy-paste scaffold the agent literally copies as its starting draft). The frontmatter contract is defined separately in [release-corpus-schema.md](release-corpus-schema.md) and composed in at authoring time.

## Audience

Notes serve two audiences with one document, layered.

**Layer A — Anyone using the platform.** Project leads who consume status outputs, anyone who invokes a skill, anyone who reads project artifacts. They want a one-line answer to *"did anything change for me?"* and a path to action if it did. They will not open `core/rules/` or read git diffs. Layer A content uses plain language and the user-observability filter (§2.1).

**Layer B — The workspace operator.** The person auditing what shipped, when, and why. They want enough operator-grade detail to confirm the release plan was executed faithfully. Layer B content uses narrative — not raw audit trail — and links to `RELEASE_LOG.md` for the dense audit record.

The two layers are physically separated in the note (Sections 6a vs. 6b — see Part 1 Template). Layer A appears above Layer B. A reader who only needs the user-facing answer stops at the end of Section 6a; an operator continues to Section 6b for the audit narrative.

## Definition

A user-facing release note is a versioned markdown file that answers, in plain language:

1. What changed for me, the platform user, in this release?
2. Does this affect me?
3. Do I need to do anything?
4. What if it breaks?
5. Where do I report problems?

The note is NOT:

- An engineering audit trail (that is `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` + release plan files)
- A commit log (git history is canonical)
- A marketing announcement
- An exhaustive list of every change — completeness is a non-goal; user-relevance is the goal

## File Location, Naming, Frontmatter

- Path: `release/releases/notes/vX.Y_RELEASE_NOTES.md`
- One file per release, no patches
- Filename version matches the Milestone version exactly (e.g., `v1.03_RELEASE_NOTES.md`)
- No subfolders; notes are flat in `releases/notes/`
- Frontmatter schema: see [release-corpus-schema.md](release-corpus-schema.md). Required fields (6): `version`, `date`, `type`, `issues`, `pr`, `links`. Optional fields (7): `reversibility-tier`, `themes`, `summary`, `requires_action`, `breaking`, `components`, `followups`. Five of the seven optional fields exist specifically to make the release-notes corpus searchable by agents — see [release-corpus-schema.md §Field-utility notes for agent search](release-corpus-schema.md#field-utility-notes-for-agent-search).

---

## Part 1 — Template (copy-paste scaffold)

Copy the block below as the starting draft for any release note. Inline guidance lives in HTML comments (`<!-- agent: ... -->`) — strip them before commit (Stage 13 lint enforces).

```markdown
---
version: vX.Y
date: YYYY-MM-DD
type: note
issues: ["#N", "#M"]
pr: "#PRN"
links:
  plan: release/releases/plans/vX.Y_RELEASE_PLAN.md
  log_anchor: "#vX-Y-slug"
reversibility-tier: CHEAP | MODERATE | EXPENSIVE | IRREVERSIBLE
themes: ["cluster:<name>", ...]
summary: "<one-sentence ≤140 chars; plain language; agent-search target>"
requires_action: true | false
breaking: true | false
components: ["<canonical-name>", ...]
followups: ["#A", "#B"]
---

# <Headline — user-visible capability, ≤80 chars>

YYYY-MM-DD · vX.Y

<Summary — 2 sentences max. Impact before mechanism. JTBD framing.>

<!-- agent: Include the skip-gate only if the release does not affect everyone using the platform. Omit otherwise. -->
> **Skip the rest** unless you <specific trigger>.

<!-- agent: Section 4 — Who this affects. Omit when scope is universal (everyone). -->
## Who this affects

- <role / plan tier / environment>

<!-- agent: Section 5 — only if requires_action=true. Place ABOVE 6a per directive-before-explanation rule. -->
## What you need to do

1. <step>
2. <step>

## What changed for everyone using the platform

<!-- agent: SECTION 6a — Layer A.
  - Max 5–7 bullets.
  - Apply the user-observability filter (§2.1): include only changes a user can OBSERVE through their interaction with the platform. If the filter removes everything, write "No user-visible behavior changes — see operator detail below" and omit the bullet list.
  - Each bullet:
      (a) one-sentence plain-language WHAT
      (b) *Why it matters:* beat with one-sentence consequence
      (c) NO internal IDs as primary nouns
      (d) NO file paths in the bullet body (link via inline anchor text)
      (e) NO banned jargon (§2.4)
  - Keep-a-Changelog labels (Added / Changed / Deprecated / Removed / Fixed / Security) are OPTIONAL in 6a — use only when ≥2 bullets share a label. Otherwise lead with the capability. -->

- **<Capability>.** <one-sentence what>. *Why it matters:* <one-sentence consequence for the user>.

## Known limits

- <boundary condition, scope limit, known gap>

Report issues at <single channel>.

<!-- agent: Section 8 — Reversibility. Required when state mutates. Omit when additive-only. -->
## Reversibility

<TIER> / <CONFIDENCE>. <one-sentence rollback path>. <window>.

---

<!-- agent: SECTION 6b — Layer B (Operator and engineering detail).
  - Filter-failing changes live here (foundations not directly observable, schema bumps, mirror-pair byte-identity, audit-trail cleanups, cutover-clause discipline).
  - Narrative, not bullet-paragraph dumps. Max 1 paragraph per theme.
  - Heavy detail belongs in RELEASE_LOG.md and the release plan, not here. Link to those for the audit trail.
  - Banned-jargon list (§2.4) does NOT apply to 6b — operator-grade terms allowed.
  - Omit this section entirely when the release has no operator-grade additions to surface. -->

### Operator and engineering detail

**<Theme A>** — <narrative paragraph>.

**<Theme B>** — <narrative paragraph>.

For full implementation detail see the [RELEASE_LOG.md entry](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>#<anchor>) and [the release plan](https://github.com/{REPO}/blob/main/release/releases/plans/<file>.md).

### References

- Milestone: [vX.Y-slug](https://github.com/{REPO}/milestone/<N>)
- Integration PR: [#PRN](https://github.com/{REPO}/pull/PRN) at `<merge-sha>`
- Closed issues: [#A] · [#B] · ...
- Follow-up: [#X] (...) · [#Y] (...)
```

---

## Part 2 — Runbook

### 2.1 The user-observability filter

Before any bullet enters Section 6a, apply this test:

> **Can a user observe this change through their interaction with the platform — skill output, file behavior, agent response, command behavior, or visible artifact?**

| Test result | Where the content goes |
|---|---|
| YES — user can observe it | Section 6a (Layer A — user-facing) |
| NO — operator-grade detail only | Section 6b (Layer B — operator-facing) OR omit entirely and link to RELEASE_LOG.md |
| BORDERLINE — surface a hint in 6a, full detail in 6b | Both, with the 6a entry written for the user, 6b for the operator |

**Examples of filter-failing content** (belongs only in 6b or omitted from the note):
- Schema version bumps with no observable behavior change
- Mirror-pair byte-identity preservation
- Reflexive-pipeline self-exemption clauses
- Audit-trail backfill (N links added to LOG)
- Frontmatter additions to existing files
- Cutover-effective-date clauses (mention only if the release in question is user-visible; otherwise note in 6b)

**Grounding:** PostgreSQL release-notes principle — *"The release notes do not contain changes that affect only a few users or changes that are internal and therefore not user-visible."* The user-facing note answers "what changed for me"; the engineering record (`RELEASE_LOG.md` + release plan) answers "what shipped."

### 2.2 The "Why it matters" beat

Every Section 6a bullet ends with `*Why it matters:*` followed by one plain-language consequence. The mechanism is the WHAT; the consequence is the WHY.

**Pattern:**
> **<Capability>.** <one-sentence what>. *Why it matters:* <one-sentence consequence for the user>.

**Worked — good:**
> **Cross-milestone dependency check.** Bundle planning now validates dependency edges against milestone position before approving a bundle. *Why it matters:* sequence violations are caught at Bundle time, not after Engineering burns effort on an unimplementable plan.

**Worked — bad:**
> Gate G3-07 cross-milestone sequence validation added to release-planner Mode A Step 4.5; halts Bundle finalization on FAIL without registered exception per gate-criteria-spec.md.

(The "bad" example is the mechanism with no consequence. A reader cannot tell whether to care.)

**Escape hatch.** When a change is genuinely foundational with no user-observable consequence but is significant enough to mention in 6a anyway (rare), mark the bullet with the HTML comment `<!-- impact:foundational -->` immediately after the bullet body. Lint check 11 honors the marker as a Pass.

### 2.3 Layered disclosure — content-type to section mapping

| Content type | Section |
|---|---|
| New user-visible capability | 6a |
| Behavior change with user-visible impact | 6a |
| Bug fix affecting user interaction | 6a |
| Action required by user (migration, setup) | 5 (and `requires_action: true`) |
| Breaking change (deprecation, removal, state-mutating default) | 5 + 6a, and `breaking: true`; trigger Stage 9 Plan Review per §2.5 Rule 3 |
| Foundational additions, no immediate visible effect | 6b |
| Doc-internal corrections | 6b |
| Schema versions, mirror-pair checks | 6b |
| Cutover-clause discipline (for releases that triggered it) | 6b |
| Audit-trail backfill | RELEASE_LOG.md only (omit from the note) |

### 2.4 Banned-jargon list

The agent MUST NOT use the phrases below in Section 6a (Layer A). They MAY appear in Section 6b (Layer B) when the operator-grade detail genuinely requires them.

| Banned in 6a | Plain-language equivalent for 6a |
|---|---|
| reflexive-pipeline self-exemption | (move concept to 6b; usually has no user impact) |
| mirror byte-identity | (move concept to 6b) |
| warn-mode posture / warn-mode initially | "logged but not blocking" |
| cutover effective date | "applies to releases after vX.Y" |
| reversibility tier (as standalone phrase) | (use the tier value itself: CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) |
| schema vX.Y → vX.Z | (omit version arithmetic; describe the behavior change) |
| all-or-nothing rule | (describe the actual behavior) |
| structurally gate-blocking / gate-blocking | "stops the release until fixed" |
| reflexive | (move to 6b or omit) |
| sub-window mutability | (move to 6b) |
| disjoint scope | (omit; describe what each scans instead) |
| forward-only | "applies to new files only" (when user can observe) OR move to 6b |
| reflexive-pipeline loop | (move to 6b) |
| collective review CR-X / CR-Y | (move to 6b) |

The list grows over time. Additions require operator approval; deletions require explicit justification (the term has become unambiguous to all Layer A readers).

### 2.5 Voice rules

These three rules govern how an agent (or skill) authors a release note. They are structural — not stylistic preferences. Violations are caught at Stage 9 Plan Review and Stage 13 Close lint.

#### Rule 1 — Fabricate-or-omit

When a template section has no grounded input from the release content, the agent **omits the section** rather than generalizing.

- An empty `Fixed` category is more honest than `Fixed — various issues addressed`.
- An absent Section 4 (Who this affects) is appropriate when the release applies to everyone — do not invent an audience to fill the section.
- An absent Section 8 (Reversibility) is appropriate when no state mutates — do not invent a rollback path.
- An empty Section 6a is appropriate when the release has no user-visible content (the §2.1 filter removed everything) — write *"No user-visible behavior changes — see operator detail below"* and let Section 6b carry the release.

The presence of a section is itself a claim. Empty sections weaken every other claim in the note.

#### Rule 2 — Voice constraint

The agent may use the **structural voice**:

- "X is now available."
- "Y is fixed."
- "Z is deprecated and will be removed in v1.05."
- "The default for Q has changed from A to B."

The agent may NOT author:

- Named first-person voice ("I think this will help…", "Sarah from Finance loves this…")
- Customer quotes or testimonials
- Named credit ("Built by the agents team", "Thanks to a contributor for catching this")
- Marketing-style enthusiasm ("We're so excited to ship this!", "This is going to be huge")
- Stability promises the change cannot support ("This bug won't happen again", "Now bulletproof")
- Invented percentages or impact metrics

Any named-voice content requires verified human attribution and human authorship — agents cannot synthesize it.

#### Rule 3 — Review surface

For any release shipping one of the following, a human gate at Stage 9 Plan Review confirms the note before the merge that publishes it:

- Deprecation
- Breaking change
- State-mutating default change
- Removal of a previously-available capability
- New restriction (rate limit, permission, audit log)

For purely-additive releases without state mutation, Stage 13 Close lint is sufficient — no separate human note-review gate.

The frontmatter `breaking: true` flag is the structural signal for Rule 3 activation; setting it triggers the Stage 9 review automatically.

### 2.6 Specificity rule

Applies to every bullet in Sections 4, 5, 6a, 6b, 7, 8.

Replace adjectives with measured fact where possible. Where no measurement exists, name the concrete behavior change instead of a quality adjective.

**Good:** *"Report generation dropped from 12s to 3s on portfolios with ≥10 projects."*
**Good (no measurement available):** *"Risk register now re-sorts when the date filter changes."*
**Bad:** *"Performance improvements."*
**Bad:** *"Better handling of edge cases."*

The single most-criticized pattern in the release-notes literature is the "various improvements" / "bug fixes and minor improvements" anti-pattern. The specificity rule is the structural defense against it.

### 2.7 Anti-patterns (Never)

- "Various improvements", "bug fixes", or "minor enhancements" as a standalone bullet
- Leading with the engineering mechanism instead of user impact
- Customer story or named credit the agent cannot verify
- Stability promises without supporting evidence
- Boilerplate opening repeated verbatim across releases
- Breaking change buried inside an `Added` list
- Internal Issue ID as the primary noun (`Closes #N` as a bullet)
- Wall of unbroken paragraphs longer than ~5 lines
- Invented severity, percentages, or impact metrics
- Silent state-mutating migration with no rollback path stated
- Section 6a listing every change in the release including ones with no user impact (violates §2.1 filter)
- Section 6a bullets missing the "Why it matters:" beat (§2.2)
- Banned-jargon term (§2.4) appearing in Section 6a content
- File paths inside Section 6a bullet bodies (link via inline anchor text instead)
- Use of strikethrough in a generated artifact (per CLAUDE.md `No strikethrough in generated artifacts`)

---

## Part 3 — Enforcement

### 3.1 Stage 9 Plan Review (human gate)

When a release contains any Review-Surface trigger per Voice Rule 3 (or sets `breaking: true`), the operator reviews the draft note as part of the PR diff before merge. The note is treated as a release artifact, not a separate concern.

### 3.2 Stage 13 Close lint (mechanical)

Before Milestone close, the agent — operating via [release-executor Mode E](../../skills/release-executor/SKILL.md) — lints the note against the Must-Have Checklist below by invoking the [release-notes eval rubric](../../../core/skills/eval-writer/references/release-notes-eval-rubric.md). Mechanical structural checks 9-13 are enforced by [deploy.sh Check 20](../../../core/deploy/deploy.sh) via [`lint_release_corpus.py --check note-content`](../../../core/deploy/tools/lint_release_corpus.py). Note-presence drift across released versions is enforced by [deploy.sh Check 26](../../../core/deploy/deploy.sh) (per Check 26 AC#3). Lint failures block Milestone close.

**Existing checks:**

1. File exists at `release/releases/notes/vX.Y_RELEASE_NOTES.md` and version matches the Milestone version.
2. ISO 8601 date present.
3. Headline ≤80 chars, single line.
4. Summary present, ≤2 sentences.
5. Section 6a present with at least one Keep a Changelog label OR plain-capability lead.
6. Section 7 (Known limits) present with both sub-bullets (known-limits + report-issues channel).
7. No standalone "various improvements" / "bug fixes" / "minor enhancements" bullets.
8. No strikethrough (per CLAUDE.md `No strikethrough in generated artifacts`).

**New checks (implemented in `core/deploy/tools/lint_release_corpus.py` under `--check note-content`; invoked by `deploy.sh` Check 20):**

9. **Section 6a presence.** Section 6a present with ≥1 bullet OR explicit "No user-visible behavior changes" placeholder. Empty Section 6a without the placeholder is a lint failure.
10. **Banned-jargon scan.** Section 6a content (between the section header and the next `##` header) contains no entries from §2.4 banned-jargon list. Case-insensitive match (14 literal terms + 4 regex patterns for parameterized forms). Failure → lint error citing the matched term and the §2.4 plain-language replacement.
11. **"Why it matters" beat presence.** Each bullet in Section 6a contains either `*Why it matters:*` text OR the `<!-- impact:foundational -->` HTML comment marker. Failure → lint error citing the offending bullet.
12. **File-path purity in 6a.** Section 6a bullet bodies contain zero raw `pmo-platform/...` or `.claude/...` paths. Inline anchor text via markdown links (e.g., `[the new index table](path)`) is permitted; bare paths in prose are not.
13. **Whole-body link purity (Surface-1 link resolvability).** Every markdown-link target in the frontmatter-stripped note body — the exact bytes that publish to the GitHub Release page (Surface 1) — is absolute (`https://`, `http://`, an intra-page `#anchor`, or `mailto:`). A repo-relative target (`](../`, `](./`, `](release/`, `](core/`, `](docs/`, `](.claude/`, `](pmo-platform/`) resolves in the file tree but 404s on the published Release page, so it is a lint failure citing the target and line number. This is the whole-body successor to check 12's 6a-only scope: it catches a repo-relative link anywhere in the body, including the Section 6b operator-detail block. The rule keys on "renders on the Release surface" — it is NOT a blanket ban on relative links in the committed file (the note file legitimately lives in `release/releases/notes/`, so a relative link is correct *in the file*); it requires absolute URLs only for the body that publishes to Surface 1. Use the absolute `https://github.com/{REPO}/blob/main/...` form for in-repo targets that must render on the Release page.

**Forward-only from the cutover release.** Pre-cutover notes are exempt — the lint maintains explicit exempt sets inside the script (`PRE_CUTOVER_EXEMPT_VERSIONS` for checks 9-12; `NOTE_LINK_EXEMPT_VERSIONS` for check 13's link rule) to handle the version-tuple/chronology mismatch (some releases carry higher version-tuples than the cutover release but shipped earlier, because major version signals work-mode rather than chronology). Checks 9-12 floor at the lowest live family; check 13 floors at `NOTE_LINK_CUTOVER` (the release that introduces it), so the historical notes carrying the legacy Section-6b template link are not retroactively failed. Warn-mode initial per the established Check 14/15/18/19 shakedown precedent; flip-to-enforce after ≥3-day warn-log review with zero false positives.

### 3.3 Eval rubric

The note is "verifiably helpful" per the research grounding. A binary pass/fail eval rubric owned by the [eval-writer skill](../../../core/skills/eval-writer/SKILL.md) scores notes against the Must-Have Checklist; the rubric file lives at [release-notes-eval-rubric.md](../../../core/skills/eval-writer/references/release-notes-eval-rubric.md). The rubric covers all 13 lint checks (existing checks 1-8 + checks 9-12 added at the cutover release + check 13 whole-body link purity). [release-executor Mode E](../../skills/release-executor/SKILL.md) invokes the rubric pre-presentation per Mode E Step 4. Calibration corpus is the set of post-cutover notes under `release/releases/notes/` (per the `PRE_CUTOVER_EXEMPT_VERSIONS` set in `lint_release_corpus.py`).

---

## Part 4 — Worked Examples

### 4.1 Good — additive routine release (self-test)

> ```markdown
> ---
> version: v1.18
> date: 2026-05-17
> type: note
> issues: ["#N"]
> pr: "#NNN"
> links:
>   plan: release/releases/plans/v1.18_RELEASE_PLAN.md
>   log_anchor: "#v1-18-release-notes-runbook-template"
> reversibility-tier: CHEAP
> themes: ["cluster:documentation", "cluster:templates-schemas"]
> summary: "Release notes now follow a layered runbook+template; agent-search frontmatter expanded."
> requires_action: false
> breaking: false
> components: ["release-notes-standard.md", "release-corpus-schema.md", "Stage 13 Close"]
> followups: []
> ---
>
> # Release notes now have a layered structure and a copy-paste template.
>
> 2026-05-17 · v1.18
>
> User-facing release notes are now authored from a standardized template with a two-layer structure: a short user-facing section that anyone can read, and an operator-facing section underneath for engineering audit detail. Five new optional frontmatter fields make the release-notes corpus searchable by agents.
>
> ## What changed for everyone reading release notes
>
> - **New layered structure.** Each release note now opens with a short "for everyone" section, followed by an "operator and engineering detail" section underneath. *Why it matters:* you get the user-facing answer in 30 seconds without scrolling through engineering audit detail.
> - **"Why it matters" on every user-facing bullet.** Each user-facing bullet now states the consequence in plain language, not just the mechanism. *Why it matters:* you can tell whether a change applies to you without inferring it.
> - **Historical notes unchanged.** Only releases from v1.18 forward use the new format. *Why it matters:* prior notes stay as authored; no archive disruption.
>
> ## Known limits
>
> - Historical notes pre-v1.18 are not rewritten.
> - The lint runs in "logged but not blocking" mode initially; after a short shakedown the operator flips it to blocking.
>
> Report issues at https://github.com/{REPO}/issues with the `cluster: documentation` label.
>
> ## Reversibility
>
> CHEAP / HIGH confidence. `git revert <sha>` reverses the integration PR; the new optional frontmatter fields are additive. No historical notes modified. Standard 7-day rollback window.
>
> ---
>
> ### Operator and engineering detail
>
> **Standard restructure** — `release-notes-standard.md` reorganized as a runbook + template (Parts 1–4). New §2.1 user-observability filter (PostgreSQL principle), §2.2 "Why it matters" beat pattern, §2.3 content-type-to-section mapping, §2.4 banned-jargon deny-list. Existing voice rules (Rules 1–3) and specificity rule preserved.
>
> **Frontmatter schema additions** — five new optional fields added to `release-corpus-schema.md`: `summary`, `requires_action`, `breaking`, `components`, `followups`. Schema additions are additive and forward-only; pre-v1.18 notes remain conformant.
>
> **Lint implementation** — Stage 13 Close mechanical checks 9–12 (Section 6a presence, banned-jargon scan, "Why it matters" beat per bullet, file-path purity) implemented in `lint_release_corpus.py` `check_note_content()` and wired into `deploy.sh` Check 20. Warn-mode initial per Check 14/15/18/19 shakedown precedent; flip-to-enforce after ≥3-day review.
>
> For full implementation detail see the [RELEASE_LOG.md entry](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>) and [the release plan](release/releases/plans/v1.18_RELEASE_PLAN.md).
>
> ### References
>
> - Issue: [#N](URL)
> - Integration PR: [#NNN](https://github.com/{REPO}/pull/NNN)
> ```

### 4.2 Good — breaking release with directive-first ordering

> # API tokens renamed: 1-week migration window opens today
>
> 2026-06-04 · v2.0
>
> A new token format ships today and replaces the old format on 2026-06-11. Every script that authenticates against the platform API needs one update.
>
> **Who this affects**
> - Any custom skill or external script that authenticates against the platform API
>
> **What you need to do**
> 1. Regenerate your token in Settings → API → Regenerate.
> 2. Replace the old token wherever it is referenced.
> 3. Verify by running `<your script> --health-check`.
>
> **What changed for everyone using the platform**
>
> - **Token format changed.** Tokens moved from `pmo_<16hex>` to `pmo_<32hex>`. *Why it matters:* the new format carries a stronger signature and resists guessing attacks.
> - **Old format accepted through 2026-06-11.** *Why it matters:* you have a 1-week migration window. After 2026-06-11, requests with the old format fail with HTTP 401.
>
> **Known limits + where to report**
> - None at release time.
> - Report issues at https://github.com/{REPO}/issues with the `auth-token` label.
>
> **Reversibility**
> Tokens are regeneratable on demand; the old token can be re-issued via Support before 2026-06-11. After 2026-06-11, only new-format tokens work.

### 4.3 Bad — counter-example (pre-restructure pattern)

> # v1.03 release
>
> 2026-05-22
>
> This release includes various improvements and bug fixes to make the platform better and more reliable.
>
> **What changed**
> - Various improvements
> - Bug fixes
> - Closes #N, #N, #N, #N
> - 30% faster
>
> Thanks for using pmo-platform! We hope you enjoy this release.

**Why it fails:**
- Engineering-style headline (no user-visible capability named)
- No JTBD framing in summary
- "Various improvements" violates §2.6 specificity rule
- Internal Issue IDs as primary nouns (`Closes #N` as bullet) — anti-pattern in §2.7
- Invented percentage (30% faster) with no measurement → §2.5 Rule 2 violation
- Named voice ("Thanks for using…") → §2.5 Rule 2 violation
- No Who-this-affects, no Known-limits, no Report-issues channel
- No categorized change-type structure
- No "Why it matters" beat on any bullet → §2.2 violation

---

## Part 5 — Layer-1 Dual-Write Mechanism

Part 5 codifies the **Layer-1 dual-write mechanism** for pmo-platform release announcements. The release note authored at Stage 13 per Parts 1–4 above does not stand alone — its content emits to **three downstream surfaces** with different audiences, lengths, and update mechanisms. This Part documents the surface fan-out: what each surface is, what content it carries, when it is written, and how the three writes coordinate to maintain a single source of truth.

**Anti-pattern disambiguation.** The "dual-write" framing in this Part refers to **publication dual-writes** — emitting a single source to multiple read-only consumer surfaces with deterministic transforms. This is structurally distinct from **state-persistence dual-writes** — two writers mutating the same authoritative file — which is the `execution-framework.md` FM-EF-3 anti-pattern. The two share a name but address different concerns; readers triggering FM-EF-3 alarms when reading Part 5 should stop at this paragraph.

### 5.1 Three emit surfaces (data-flow surface table)

The single `release/releases/notes/vX.Y_RELEASE_NOTES.md` file (authored once at Stage 13 per §3.2 above) emits to three downstream surfaces:

| # | Surface | Location | Audience | Role | Privacy | Length target | Format |
|---|---|---|---|---|---|---|---|
| 1 | **GitHub Releases** | `gh release create v<X.Y> --notes-file <path>` → `https://github.com/<owner>/<repo>/releases/tag/v<X.Y>` | Anyone with repo read access (public after Phase 4 public-flip) | **Canonical public surface** — discoverable via the Releases tab; queryable via `gh release list` | Public post-flip (private pre-flip) | Full (mirrors Sections 1–8 of `vX.Y_RELEASE_NOTES.md`) | GitHub-flavored Markdown; release-tag metadata + tag-target SHA |
| 2 | **CHANGELOG.md** | `CHANGELOG.md` at repo root (created by the sibling CHANGELOG.md scaffold ticket) | Offline / raw-git readers; package-manager-style discovery | **In-repo fallback** — exists for users who cannot reach GitHub Releases UI (raw-git clones, archived snapshots, offline reviews) | Tracks repo privacy (public/private follows repo state) | Lightweight — 5-15 lines per release (capability headlines + Keep-a-Changelog labels); see §5.3 length convention notes | Plain markdown, [Keep-a-Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/); newest-first ordering |
| 3 | **Operator-instance RELEASE_LOG.md** | `<OPERATOR_INSTANCE_LOG_PATH>` — see footnote below | Operator only; PMO platform engineering audit consumers | **Full pipeline-context audit trail** — release plan link, deployment log, verification evidence, decision-outcome capture | **Always private** — operator-instance, not in repo (post-extraction) | Full audit (~50-100 lines per release; includes Cycle-Time, Outcome, deployed-files manifest) | Tabular row + visible-H4 Deployment Log block per [`stage-12-execute.md § Phase B5`](../pipeline/stage-12-execute.md) emit format |

**Surface roles (memorable framing):**
- Surface 1 (Releases) = **what users discover**
- Surface 2 (CHANGELOG) = **what users grep**
- Surface 3 (RELEASE_LOG) = **what the operator audits**

**Frontmatter handling (Surface 1).** Surface 1 publishes the note's **body** (Sections 1–8), not the file verbatim — the leading YAML frontmatter is stripped (`sed '1,/^---$/d; 1,/^---$/d'`) so the machine metadata does not render on the Releases UI. The committed `vX.Y_RELEASE_NOTES.md` is the source of record; the Release page is the rendered copy people read. The emit therefore uses `--notes "$BODY"`, not `--notes-file <path>`.

> **Footnote on `<OPERATOR_INSTANCE_LOG_PATH>`:** This path resolves to `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` until the extraction lands. Post-extraction, it resolves to the operator-instance path declared in that release (typically `~/Claude/personal/pmo-instance/RELEASE_LOG.md`). The path-shift is a one-time event captured in the release plan deviation log; pre-extraction readers MUST use the in-repo path, post-extraction readers MUST use the operator-instance path.

This data-flow table is the **Tier-A activated design artifact** per [`design-artifact-standard.md § 7`](../../../core/standards/design-artifact-standard.md) (data-flow class, single producer × 3 consumers). It is embedded here in the standard rather than centralized per [`design-artifact-standard.md § 3`](../../../core/standards/design-artifact-standard.md) (single-doc reference, below the ≥3-parent-doc centralization threshold).

### 5.2 Single source-of-truth principle

The dual-write mechanism is **NOT triple-authoring**. The operator (or `release-executor` Mode E per §3.3 above) authors `vX.Y_RELEASE_NOTES.md` ONCE at Stage 13. Three surface emits then derive from that single file via deterministic transform rules:

| Surface | Transform from `vX.Y_RELEASE_NOTES.md` |
|---|---|
| GitHub Releases (1) | Full file body verbatim (excluding YAML frontmatter; GitHub renders frontmatter as raw text). Title = `vX.Y — <headline>` (the H1 headline text, leading `# ` stripped, prefixed with the version and an em-dash). |
| CHANGELOG.md (2) | Append a new `## [vX.Y] - YYYY-MM-DD` section at top-of-file under "Unreleased" containing 5-15 lines extracted from `vX.Y_RELEASE_NOTES.md` Section 6a using Keep-a-Changelog labels. Transform is **lossy by design** — operator-grade detail (Section 6b) stays in the canonical note + RELEASE_LOG. |
| `<OPERATOR_INSTANCE_LOG_PATH>` (3) | Append row + visible-H4 Deployment Log block per [`stage-12-execute.md § Phase B5`](../pipeline/stage-12-execute.md) emit format and Stage 13 chore PR `DEPLOYED → VERIFIED` transition. **Already-codified mechanism;** dual-write does not modify it. |

**Principle statement:**

> The user-facing release note at `release/releases/notes/vX.Y_RELEASE_NOTES.md` is the **single source of truth** for release-notes content. The dual-write mechanism emits the same content to three surfaces with per-surface transforms applied at emit time — never re-authoring. When content needs to change post-emit, the canonical file changes first; the surfaces re-emit from the updated source via the same transform rules (see §5.6 Post-VERIFIED corrections).

### 5.3 Per-surface length + format conventions

| Surface | Length convention | Format constraint | Section-mapping from canonical note |
|---|---|---|---|
| **GitHub Releases** | Full — no truncation; mirrors entire `vX.Y_RELEASE_NOTES.md` body (Sections 1-8 + References) | GitHub-flavored Markdown; tag = `v<X.Y>`; title = `vX.Y — <headline>` (the H1 headline prefixed with the version and an em-dash); body = file contents excluding YAML frontmatter | All sections (1-8 + References) |
| **CHANGELOG.md** | **5-15 lines per release** (median target 8 lines). Cap rule: ≤15 lines total across all change-type sections; releases requiring >15 lines apply the length-budget escape-hatch below. | Keep-a-Changelog 1.1.0: `## [vX.Y] - YYYY-MM-DD` H2 per release + `### Added/Changed/Deprecated/Removed/Fixed/Security` H3 per category present | **Section 6a only** (Layer-A user-facing bullets). Each Section 6a bullet → one CHANGELOG line under the applicable Keep-a-Changelog label. Section 6b never replicates to CHANGELOG. |
| **`<OPERATOR_INSTANCE_LOG_PATH>`** | Full audit — ~50-100 lines per release (existing convention) | Tabular row + visible-H4 Deployment Log block (existing format) | Cross-references the canonical note path; does not duplicate body content |

**CHANGELOG line shape (one bullet per change, per existing standard's voice rules):**

```
- **<Capability>.** <one-sentence what>. *Why it matters:* <one-sentence consequence>. ([#N](https://github.com/{REPO}/issues/N))
```

**Linked Issue references are MANDATORY in CHANGELOG.md** (provides traceability when raw-git readers cannot reach GitHub Releases). The line-shape uses fully-qualified GitHub URLs of the form `[#N](https://github.com/{REPO}/issues/N)` — readers seeing the literal placeholder `[#N](...)` in this standard MUST perform URL substitution at emit time (replace `N` with the actual issue number in both the link text and the URL).

**Length-budget escape hatch.** The 5-15 line cap is a soft target; the per-bullet shape mandate (capability + WHAT + *Why it matters* beat + linked issue) typically produces 2-4 visual markdown lines per bullet, so a release with ≥6 bullets may exceed 15 lines. When that happens, the operator MUST choose one of:

1. **Trim** — drop bullets with the lowest user-impact severity until the cap holds; the canonical note (Surface 1) carries the full bullet set.
2. **Link out** — write a single CHANGELOG entry pointing to the canonical note (`See [v<X.Y> release notes](release/releases/notes/v<X.Y>_RELEASE_NOTES.md) for full change list.`) and skip per-bullet enumeration entirely.
3. **Drop the beat** — for the affected release ONLY, emit `**<Capability>.** <one-sentence WHAT>. ([#N](...))` without the *Why it matters* beat in CHANGELOG.md. The beat stays present in Surface 1 (GitHub Releases) at full length. This option preserves bullet cardinality at the cost of dropping the inherited §2.2 voice rule for CHANGELOG only; the operator must document the trade-off in the Stage 13 sub-task comment.

The default is option 1 (Trim). Option 2 fires automatically when a release has >10 Section 6a bullets. Option 3 requires explicit operator authorization per release.

### 5.4 Stage 12 + Stage 13 emit sequence (D-DualWriteEmitSequence — Option A selected)

Selected at Stage 5 Solutioning per the dual-write release plan D-DualWriteEmitSequence: **Option A — Sequential GitHub Releases first → CHANGELOG append → RELEASE_LOG `VERIFIED` transition.**

| Option | Sequence | Failure-mode profile | Verdict |
|---|---|---|---|
| **(A) Sequential — Releases → CHANGELOG → RELEASE_LOG** | `gh release create` (or `gh release edit`; see retry semantics §5.5) → CHANGELOG append commit on Stage 13 chore-PR branch → RELEASE_LOG `DEPLOYED → VERIFIED` transition on same chore-PR branch | Surface 1 fails → surfaces 2+3 never written → operator retries from clean state. Surface 2 fails → Surface 1 already public but easily re-edited. Surface 3 lands last (chore-PR merge IS the durable commit). | **SELECTED** |
| **(B) Sequential — RELEASE_LOG → CHANGELOG → Releases** | RELEASE_LOG transition → CHANGELOG append → `gh release create` | If RELEASE_LOG lands but `gh release create` fails, audit trail shows release complete while public surface is missing — **observable inconsistency**. | REJECTED |
| **(C) Parallel emit with reconciliation barrier** | Fire all three emits concurrently; reconcile in barrier step | Requires implementing a barrier the existing chore-PR mechanism does not have. | REJECTED |

**Option A rationale:**

> The canonical emit sequence is **GitHub Releases → CHANGELOG.md → RELEASE_LOG `VERIFIED`**, in that order. The sequence places the public-facing emit (Releases) first because failure of the public surface BEFORE the audit trail records `VERIFIED` keeps the audit trail honest: a release is "VERIFIED" only when all three surfaces have landed. The operator-instance RELEASE_LOG `VERIFIED` transition is the **last** mutation because it is the durability anchor — the chore-PR merge that contains it is what closes the release. Operators reading the RELEASE_LOG can trust that `VERIFIED` implies all three surfaces are present.

**Stage-anchored sequencing (Surface 1 at Stage 12; Surfaces 2+3 at Stage 13).** The three surfaces emit at two stage anchors because they have mechanically-distinct execution surfaces — Surface 1 is a GitHub API mutation against an existing tag (requires `git tag` to be pushed first, which happens at Stage 12 Phase B); Surfaces 2+3 are git commits that land via the Stage 13 chore PR per the chore-PR convention:

```
Stage 12 — Execute (existing per pipeline/stage-12-execute.md)
├── Phase B — `gh pr merge` → main; annotated tag `v<X.Y>` pushed
├── Phase B5 — RELEASE_LOG row authored at DEPLOYED state (existing per the chore-PR convention)
└── SURFACE 1 EMIT (NEW — after tag push, after Phase B5)
       Mechanism: `gh release create v<X.Y>` per §5.5 view-then-create-or-edit pattern
       Output: canonical public surface live at https://github.com/<owner>/<repo>/releases/tag/v<X.Y>

Stage 13 — Close (existing per pipeline/stage-13-close.md)
├── Phase A — Verification (QC4-01..06; G-CL6; G-CL7; G-CL8)
├── Phase B — chore PR (existing per the chore-PR convention)
│   ├── Commit 1: SURFACE 2 EMIT (NEW)
│   │   Mechanism: edit CHANGELOG.md at repo root per §5.3 transform rule
│   │   Output: Keep-a-Changelog entry under newest release H2
│   ├── Commit 2: SURFACE 3 EMIT
│   │   Mechanism: edit RELEASE_LOG.md row state DEPLOYED → VERIFIED
│   │   Output: visible-H4 Deployment Log block updated
│   └── Commit 3: existing chore-PR scope (INDEX + DIGEST + RELEASE_NOTES per stage-13-close.md § Phase B)
└── Phase C — Milestone close (Standing-GO Tier-1)
```

**Pipeline-shard codification:** The Stage 12 + Stage 13 pipeline shards (`release/references/pipeline/stage-12-execute.md` + `release/references/pipeline/stage-13-close.md`), the `release-executor` SKILL.md Mode update, and the `hub-spoke-bridge.md` Stage 12/13 chip pattern amendments are owned by the sibling pipeline-shard codification ticket. Readers seeking the pipeline-execution detail consult that ticket's deliverables; this standard records the contract (sequence, transforms, failure semantics) only.

### 5.5 Idempotency + retry semantics — Surface 1 view-then-create-or-edit pattern

Surface 1 (`gh release create`) is **NOT independently idempotent** — re-running with a tag that already has a release returns HTTP 422 (`Validation Failed: already_exists`), not a silent update. The idempotent operations are `gh release edit` (existing release) and `gh release upload --clobber` (existing assets).

To compose Surface 1 into an idempotent SEQUENCE, the emit MUST follow a 3-state state machine (`gh release view` discriminates between create-vs-edit before mutation):

| State | Pre-condition | Action | Post-condition |
|---|---|---|---|
| **State 0 — no release for tag** | `gh release view v<X.Y>` returns "release not found" (exit code 1) | `gh release create v<X.Y> --notes-file <canonical-note-path> --title "vX.Y — <headline>" --target <merge-sha>` — on success → State 2; on transient failure (network / 5xx) → retry once → on second failure → HALT and escalate Tier 2 [SCOPE CHANGE] per [`release-process.md § Inter-Stage Feedback Protocol`](../../governance/release-process.md) | release present at desired content; auditable via `gh release view` |
| **State 1 — release exists; content may differ** | `gh release view v<X.Y> --json body` returns body content (any value) | Compare returned body against canonical note body (excluding frontmatter). If MATCH → State 2 PASS no-op. If DIFFER → `gh release edit v<X.Y> --notes-file <canonical-note-path>` (idempotent) → State 2 | release present at desired content |
| **State 2 — release present with current content** | view + diff verification passes | No mutation needed; PASS; proceed to Surface 2 emit | sequence complete for Surface 1 |

**Why the state machine matters:** Without the view-then-create-or-edit pattern, a Stage 12 retry-after-partial-success would fail on `already_exists` regardless of cause — exactly the operational class the dual-write mechanism is designed to avoid. The state machine treats the SEQUENCE as idempotent even when the individual `gh release create` call is not.

**Failure-handling state machine for the full 3-surface emit:**

| State | Action on failure | Recovery |
|---|---|---|
| Surface 1 lands (State 2); Surface 2/3 not started | Continue to Surface 2 | N/A — happy path |
| Surface 1 fails after retry (HALT in State 0 → transient) | Tier 2 [SCOPE CHANGE]; operator decides: fix `gh` auth / network, re-run from State 0; or accept-as-residual (rare) | CHEAP — no surface state corrupted; release tag pushed but no Release object exists |
| Surface 1 lands; Surface 2 written; Surface 3 not started | Continue to Surface 3 (chore-PR commit captures both 2+3 atomically) | N/A — single chore-PR commit handles 2+3 together |
| Surface 1 lands; chore-PR fails to merge | Re-create chore-PR (idempotent; same branch, same diff) | CHEAP — branch is intact, no surface state corrupted |

### 5.6 Post-VERIFIED corrections (single-source-of-truth re-emit procedure)

The §5.2 principle promises that "when content needs to change post-emit, the canonical file changes first; the surfaces re-emit from the updated source via the same transform rules." This subsection specifies the concrete re-emit procedure for the **post-VERIFIED state** (release shipped; operator discovers prose error days later):

1. **Author the correction.** Edit canonical `release/releases/notes/vX.Y_RELEASE_NOTES.md` on a `fix/release-notes-vX.Y` branch with PR (governed per "No ungoverned changes" — small commit, single-file scope; PR title `fix(release-notes): correct v<X.Y> <field>`).
2. **Re-emit Surface 1 (GitHub Releases).** After PR merge, run `gh release edit v<X.Y> --notes-file release/releases/notes/vX.Y_RELEASE_NOTES.md` against the existing release object. This invocation is idempotent (see §5.5 State 1 → State 2 transition); no view-then-edit dance required because the release definitely exists.
3. **Re-emit Surface 2 (CHANGELOG.md) — conditional.** If the correction is user-visible (touches Section 6a bullets), edit CHANGELOG.md in a second commit on the same `fix/release-notes-vX.Y` branch to mirror the corrected wording. If the correction is operator-grade only (Section 6b), no CHANGELOG mutation needed (Section 6b never replicates to CHANGELOG per §5.3).
4. **Surface 3 (RELEASE_LOG.md) — no action.** The RELEASE_LOG entry recorded the deployment event (timestamp, SHA, tag, deployed files), not the prose body. RELEASE_LOG remains unchanged by post-VERIFIED prose corrections; the canonical note path is already cross-referenced.

**Reversibility note:** Post-VERIFIED corrections are CHEAP / HIGH confidence — `git revert` of the correction PR restores the prior state; `gh release edit` re-applies cleanly.

### 5.7 Voice-rule preservation across surfaces

The existing standard's three voice rules (§2.5 Rules 1-3: fabricate-or-omit / voice constraint / review surface) apply uniformly to the canonical note. Per-surface deltas:

| Voice rule | GitHub Releases (Surface 1) | CHANGELOG.md (Surface 2) | RELEASE_LOG.md (Surface 3) |
|---|---|---|---|
| **Rule 1 — Fabricate-or-omit** | INHERITED — full note body emits verbatim; cannot fabricate at emit time | **TIGHTENED** — 15-line cap means more aggressive omission; operator may NOT pad CHANGELOG to look fuller; empty change-type label is omitted entirely | INHERITED — existing RELEASE_LOG convention |
| **Rule 2 — Voice constraint** | INHERITED | INHERITED — CHANGELOG line shape preserves *Why it matters:* beat from Section 6a (unless escape-hatch option 3 fires per §5.3) | INHERITED — operator-grade voice acceptable per existing convention |
| **Rule 3 — Review surface** | INHERITED + **AMPLIFIED** — public surface; any Voice-Rule-3 trigger (deprecation / breaking change / state-mutating default / removal / new restriction) MUST be reviewed at Stage 9 BEFORE merge | INHERITED — same Stage 9 gate covers CHANGELOG content because the note IS the source | INHERITED |

**Banned-jargon list (§2.4) applies to Section 6a of canonical note → applies to CHANGELOG.md by derivation.** Section 6b operator-grade jargon stays in canonical note + RELEASE_LOG only; CHANGELOG never sees it (5-15 line cap structurally prevents it).

**Illustrative example.** See [`_examples/dual-write-illustrative-v2.01.md`](_examples/dual-write-illustrative-v2.01.md) for a worked back-cast of an example release through all three surface transforms — Surface 1 GitHub Release body, Surface 2 CHANGELOG.md entry, Surface 3 RELEASE_LOG row + visible-H4 Deployment Log block.

---

## Must-Have Checklist

Every release note must satisfy all of these:

- [ ] Frontmatter present per [release-corpus-schema.md](release-corpus-schema.md): required fields populated; optional fields populated where applicable
- [ ] `summary:` frontmatter field present (encouraged; will become required after N=3 post-cutover notes per schema's promotion rule)
- [ ] ISO 8601 date in Section 2; version matches Milestone exactly
- [ ] Headline ≤80 chars, names a user-visible capability (not engineering noun)
- [ ] Summary ≤2 sentences, leads with impact before mechanism
- [ ] Plain language in Section 6a — no internal IDs as primary nouns; no skill names as headers
- [ ] Section 4 present when scope is non-universal; absent when universal
- [ ] Section 5 present when release contains breaking change, deprecation, migration, or required-setup feature
- [ ] Section 6a present with ≥1 bullet OR explicit "No user-visible behavior changes" placeholder
- [ ] Every Section 6a bullet contains the "Why it matters:" beat (§2.2) OR carries the `<!-- impact:foundational -->` escape-hatch marker
- [ ] No banned-jargon term (§2.4) appears in Section 6a content
- [ ] No file paths in Section 6a bullet bodies — use inline anchor text instead
- [ ] Whole-body link purity — every markdown-link target in the published (frontmatter-stripped) body is absolute (`https://`, `#anchor`, or `mailto:`); no repo-relative `](../` / `](release/` / `](core/` link anywhere in the body (it would 404 on the GitHub Release page)
- [ ] Section 7 (Known limits) present with both Known-limits and Report-issues sub-bullets
- [ ] Section 8 (Reversibility) present when state mutates
- [ ] Section 6b (Operator and engineering detail) present when release has operator-grade additions to surface; omitted when not
- [ ] References block at note foot (milestone, PR, issues, follow-ups)
- [ ] Specificity rule (§2.6) passed per bullet — no "various improvements" or equivalent vague filler
- [ ] Voice constraint (§2.5 Rule 2) passed — no named-voice content fabricated by agent
- [ ] Review-surface gate (§2.5 Rule 3) satisfied — `breaking: true` flag set if applicable; Stage 9 review confirmed if triggered
- [ ] HTML-comment template guidance stripped before commit

## Cross-References

- [release-corpus-schema.md](release-corpus-schema.md) — frontmatter contract (required + optional fields, validation discipline, agent-search field-utility notes)
- [<OPERATOR_INSTANCE_ANALYSIS_PATH>/release-notes-research-2026-05-10/SUMMARY.md](<OPERATOR_INSTANCE_ANALYSIS_PATH>/release-notes-research-2026-05-10/SUMMARY.md) — source corpus for the 2026-05-10 grounding (7-exemplar teardown + Keep a Changelog + ProductPlan/Appcues/Archbee + Engineering Interface framework)
- [release/governance/release-process.md Stage 13 Close](../../governance/release-process.md) — wires the note into the release pipeline
- [release/governance/RELEASE_PROTOCOL.md](../../governance/RELEASE_PROTOCOL.md) — cross-references this standard from the canonical release protocol
- [release/references/pipeline/stage-12-execute.md](../pipeline/stage-12-execute.md) — Part 5 Surface 1 emit anchor (post-Phase-B5; pipeline-shard codification owned by the sibling ticket)
- [release/references/pipeline/stage-13-close.md](../pipeline/stage-13-close.md) — adds note-output to the Stage 13 checklist; Part 5 Surfaces 2+3 emit anchor (pipeline-shard codification owned by the sibling ticket)
- [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) — canonical source for the six change-type labels; Part 5 §5.3 references it as the CHANGELOG.md format authority
- [design-artifact-standard.md](../../../core/standards/design-artifact-standard.md) — Part 5 §5.1 data-flow surface table activated as Tier-A design artifact per § 7 criteria
- [execution-framework.md FM-EF-3](../../../core/disciplines/execution-framework.md) — state-persistence dual-write anti-pattern; Part 5 disambiguates publication dual-writes from state-persistence dual-writes
- PostgreSQL release-notes principle — *"The release notes do not contain changes that affect only a few users or changes that are internal and therefore not user-visible."* The §2.1 user-observability filter operationalizes this rule.
- NN/G two-level progressive disclosure — the 6a/6b split applies this principle (the literature's "three+ depth levels confuses readers" finding bounds the layering to exactly two visible levels in a single note).

## Reversibility

The runbook+template restructure is reversible by reverting the establishing PR. Reversion restores the prior prose-only standard. Schema additions are additive optional fields — historical notes remain conformant either way. No data migration. **Tier: CHEAP / HIGH confidence.**

The prior version of this standard (the original baseline) is preserved in git history; reverting this PR restores it intact.

**Part 5 — Layer-1 Dual-Write Mechanism (added in the dual-write release).** Part 5 is reversible by git revert of the establishing PR. Reversion restores the 4-Part structure (Template / Runbook / Enforcement / Worked Examples). CHANGELOG.md at repo root and the Stage 12/13 chip patterns are owned by independent PRs and remain unchanged by reverting Part 5 alone — those follow their own reversal paths. **Tier: CHEAP / HIGH confidence.** The path-shift event for Surface 3's <OPERATOR_INSTANCE_LOG_PATH> is captured in the operator-instance extraction's release plan deviation log as a one-time event; Part 5 stays valid regardless of which side of the extraction the reader is on.
