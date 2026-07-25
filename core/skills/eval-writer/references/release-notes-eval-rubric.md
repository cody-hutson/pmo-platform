---
name: release-notes-eval-rubric
description: Binary pass/fail rubric for user-facing release notes, covering the 14 lint checks from release-notes-standard.md § 3.2. Used by eval-writer as a worked playbook and consumed by Stage 13 Close lint, release-executor Mode E, and pmo-qa-auditor.
title: Release Notes Eval Rubric — Binary PASS/FAIL
purpose: The binary pass/fail rubric for user-facing release notes, covering the 14 lint checks from release-notes-standard.md § 3.2, owned by eval-writer and consumed by Stage 13 Close lint, release-executor Mode E, and pmo-qa-auditor.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
source_standard: release/references/standards/release-notes-standard.md § 3.2
---
<!-- reference-durability: allow-link -->

# Release Notes Eval Rubric — Binary PASS/FAIL

## Purpose

Binary PASS/FAIL rubric for user-facing release notes at `pmo-platform/releases/notes/vX.Y_RELEASE_NOTES.md`. Owned by `eval-writer`; consumed by:

- Stage 13 Close `lint_release_corpus.py` (mechanical structural checks per `release-notes-standard.md § 3.2`)
- [`release-executor`](../../../../release/skills/release-executor/SKILL.md) Mode E (self-lint pre-presentation per Mode E Step 4)
- [`pmo-qa-auditor`](../../pmo-qa-auditor/SKILL.md) (when invoked on a release note as audit target)

The rubric is **structural** — content judgment stays with operator review per [`release-notes-standard.md`](../../../../release/references/standards/release-notes-standard.md) § 2.5 Rule 3.

## Scope

Applies to user-facing release notes for releases entering Stage 13. Pre-cutover notes authored before the `release-notes-standard.md` runbook + template restructure are exempted per the `PRE_CUTOVER_EXEMPT_VERSIONS` set inside `lint_release_corpus.py`.

Check 14 (L14) has no version floor — it evaluates only a release whose closer declared it schema/format-changing, so there is no historical population to exempt.

## The 14 Lint Checks (Binary)

Each check produces a single token `PASS` or `FAIL` with a one-sentence rationale citing the file:line or the §-anchor that failed.

### Existing checks 1-8 (from `release-notes-standard.md § 3.2`)

| ID | Check | Method | PASS criterion |
|---|---|---|---|
| L1 | File exists at canonical path; version matches Milestone | `[ -f pmo-platform/releases/notes/v<X.Y>_RELEASE_NOTES.md ]` + `frontmatter.version == milestone.version` | both PASS |
| L2 | ISO 8601 date present | regex `^\d{4}-\d{2}-\d{2}` on first non-blank prose line (after frontmatter and H1) | regex matches |
| L3 | Headline ≤80 chars, single line | first `^# ` line; `len(body) ≤ 80` | both PASS |
| L4 | Summary present, ≤2 sentences | first paragraph after the `YYYY-MM-DD · vX.Y` line; sentence count ≤ 2 (count `.` outside code blocks) | both PASS |
| L5 | Section 6a present with KaC label OR plain-capability lead | header `## What changed for everyone using the platform` (or release-specific variant) present; ≥1 bullet OR explicit "No user-visible behavior changes" placeholder | present + non-empty (per L9 specifically) |
| L6 | Section 7 (Known limits) present with both sub-bullets | header `## Known limits` present; at least one bullet + a `Report issues at <channel>` line | both present |
| L7 | No standalone vague-filler bullets | Section 6a body grep for `^\s*-\s*(Various improvements\|Bug fixes\|Minor enhancements)\s*\.?\s*$` (case-insensitive) | zero matches |
| L8 | No strikethrough in note body | grep for `~~.+?~~` across entire file | zero matches |

### New checks 9-14 (mechanically implemented in `lint_release_corpus.py --check note-content`; checks 9-13 invoked by `deploy.sh` Check 20, check 14 flag-gated at Stage 13)

| ID | Check | Method | PASS criterion |
|---|---|---|---|
| L9 | Section 6a presence | Section 6a header present + ≥1 bullet OR explicit "No user-visible behavior changes — see operator detail below" placeholder string match | one branch satisfied |
| L10 | Banned-jargon scan in Section 6a | Section 6a content (between section header and next `##` header) grep for §2.4 banned-jargon list (14 literal terms + 4 regex patterns) | zero matches |
| L11 | "Why it matters" beat per bullet | each Section 6a bullet contains `\*Why it matters:\*` literal OR `<!-- impact:foundational -->` HTML-comment marker | every bullet matches one branch |
| L12 | File-path purity in 6a | Section 6a bullet bodies grep for `pmo-platform/` or `.claude/` outside markdown-link parentheses | zero matches |
| L13 | Whole-body link purity (published Surface 1) | every markdown-link target in the published (frontmatter-stripped) body is absolute — `https://`, `#`, or `mailto:`; repo-relative targets (`../`, `release/`, `core/`, `docs/`, `.claude/`, `pmo-platform/`) render broken on the GitHub Release page (release-notes-standard.md §5.1/§5.3 Surface-1 link rule) | zero repo-relative targets |
| L14 | Schema/format sample block (advisory) | for a release declared schema/format-changing per release-notes-standard.md §2.8: body contains ≥1 fenced block positioned outside the Section 6a bullet span, OR carries `<!-- sample-block: n/a — <reason> -->` | one branch satisfied — **advisory: a FAIL is reported but does not block the close** |

## How To Invoke

### As Stage 13 Close lint (mechanical)

`deploy.sh --check` Check 20 invokes `python3 core/deploy/tools/lint_release_corpus.py --check note-content` which runs checks L9-L13 + structural subset of L1-L8. L14 is NOT part of the corpus-wide run — it evaluates only under `--sample-block-advisory <version>` at Stage 13, and its findings never change the lint's exit status. **Coverage gap:** L1-L8 are currently structural-only in `lint_release_corpus.py`; this rubric documents what FULL coverage looks like and what `eval-writer` can compose against when extending the lint.

### As Mode E self-lint (release-executor)

[`release-executor`](../../../../release/skills/release-executor/SKILL.md) Mode E Step 4 reads this rubric and applies L1-L14 to the draft prose pre-presentation. On any FAIL, Mode E iterates the draft once before presenting; persistent FAIL is surfaced inline in the operator-review gate at Step 5.

### As pmo-qa-auditor audit target

[`pmo-qa-auditor`](../../pmo-qa-auditor/SKILL.md) Mode A audits a release note by reading this rubric and producing per-check PASS/FAIL with evidence (cite line numbers). Composes with G4 reversibility tier check and G7 failure-mode discipline.

## Worked Examples (Calibration Set)

### Worked PASS — `vX.Y_RELEASE_NOTES.md`

All 14 checks PASS:

- **L1 ✓** — file at canonical path `pmo-platform/releases/notes/vX.Y_RELEASE_NOTES.md`; frontmatter version `vX.Y` matches Milestone `vX.Y-<milestone-slug>`
- **L2 ✓** — date `2026-05-23` on line 21
- **L3 ✓** — headline `Release pipeline gains outcome tracking, cycle-time, and automated close-out` (76 chars)
- **L4 ✓** — 1-sentence summary; impact-before-mechanism
- **L5 ✓** — Section 6a header present; 7 bullets
- **L6 ✓** — Section 7 header present; report-issues line present
- **L7 ✓** — zero standalone vague-filler bullets
- **L8 ✓** — zero strikethrough
- **L9 ✓** — Section 6a non-empty (7 bullets)
- **L10 ✓** — zero §2.4 banned-jargon matches in 6a
- **L11 ✓** — every 6a bullet ends with `*Why it matters:*` beat
- **L12 ✓** — no raw paths in 6a bullets (all paths inside markdown-link parentheses)
- **L13 ✓** — every markdown-link target in the published (frontmatter-stripped) body is absolute (`https://…` / `#anchor` / `mailto:`); zero repo-relative targets that would render broken on the GitHub Release page
- **L14 ✓** — release declared schema/format-changing; one fenced sample block present in Section 6b, none inside a Section 6a bullet

### Worked FAIL — synthetic counter-example

Operator-authored test fixture at [`core/skills/eval-writer/evals/fixtures/release-notes-bad-vX.Y_RELEASE_NOTES.md`](../evals/fixtures/release-notes-bad-vX.Y_RELEASE_NOTES.md). Designed to FAIL L4 (3-sentence summary), L7 (`- Various improvements` bullet), L10 (`reflexive-pipeline self-exemption` in 6a), L11 (bullet without `*Why it matters:*`), L12 (`pmo-platform/skills/foo/SKILL.md` raw path in 6a bullet body). Invoking this rubric on the fixture MUST produce 5 FAILs naming the specific checks.

## Output Contract

Rubric output (per Template-1 binary judge pattern from [`rubric-templates.md`](rubric-templates.md)):

```text
L1: PASS — File present at pmo-platform/releases/notes/vX.Y_RELEASE_NOTES.md; frontmatter version vX.Y matches Milestone vX.Y
L2: PASS — ISO 8601 date 2026-05-23 at line 21
L3: PASS — Headline length 76 chars
L4: PASS — Summary 1 sentence
L5: PASS — Section 6a present
L6: PASS — Section 7 present with both sub-bullets
L7: PASS — Zero vague-filler bullets
L8: PASS — Zero strikethrough
L9: PASS — Section 6a non-empty (7 bullets)
L10: PASS — Zero §2.4 banned-jargon matches in Section 6a
L11: PASS — Every Section 6a bullet carries "*Why it matters:*" beat
L12: PASS — Zero raw paths in Section 6a bullet bodies
L13: PASS — Every published-body link target absolute; zero repo-relative targets
L14: PASS — Sample block present in Section 6b (advisory check)

VERDICT: PASS (14/14)
```

On any FAIL, the per-check rationale cites the file:line and the §-anchor that failed; the overall VERDICT is `FAIL` with count `(N/14)`. A FAIL on L14 alone is advisory — it is reported and counted in the rubric score, but it never blocks the close. Example FAIL output:

```text
L4: FAIL — Summary at lines 23-25 is 3 sentences (release-notes-standard.md § 3.2 check 4 requires ≤2)
L7: FAIL — Vague-filler bullet at line 32 ("Various improvements") matches §2.6 banned pattern
L10: FAIL — Banned-jargon "reflexive-pipeline self-exemption" at line 35 matches §2.4 deny-list
L11: FAIL — Bullet at line 38 missing *Why it matters:* beat (no `<!-- impact:foundational -->` escape)
L12: FAIL — Raw path "pmo-platform/skills/foo/SKILL.md" at line 41 outside markdown-link parens

VERDICT: FAIL (9/14)
```
