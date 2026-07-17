---
title: ADR Helper — Scaffolding Procedure
purpose: Reference detail for adr-helper's Scaffold mode — the worked number-allocation walkthrough and immutable-numbering mechanics behind the SKILL.md contract.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# ADR Helper — Scaffolding Procedure (reference)

This reference expands the operational detail of the adr-helper `## Mode: Scaffold` step and the immutable-numbering rule. The SKILL.md body carries the contract; this file carries the worked mechanics and the number-allocation walkthrough. Read it when executing a scaffold or when validating an allocation against the global sequence.

## 1. Resolve the ADR home dynamically

The ADR-home directory set is authoritative in exactly one place: the `ADR_DIRS` tuple in `release/tools/check-adr-numbers.py`.

```python
# release/tools/check-adr-numbers.py
ADR_DIRS = ("core/ADRs", "release/ADRs")
```

- **Preferred mechanism:** read that constant (the single git-tracked source of the home set) so the skill inherits any future relocation for free.
- **Fallback mechanism:** glob both `core/ADRs/ADR-*.md` and `release/ADRs/ADR-*.md` relative to the repo root.

Either mechanism resolves the home at runtime. **Never bake `core/ADRs/` into the skill as a literal path** — the "read the home dynamically" requirement (parent-issue AC 4) exists so the skill survives a per-module ADR relocation without a code edit.

## 2. Allocate `max(global) + 1` across BOTH directories

The ADR number space is a single global, gap-free, append-only sequence across `core/ADRs/ ∪ release/ADRs/` — monotonic across the platform, NOT per-module (both READMEs' § Naming convention; enforced by `check-adr-numbers.py`, which fails DUPLICATE / GAP / MALFORMED).

Allocation algorithm:

1. Enumerate every `ADR-NNN-*.md` filename across BOTH resolved directories.
2. Parse each `NNN` (the `ADR-(\d+)-` prefix).
3. Take the maximum across the **union** of both directories.
4. Add one; zero-pad to three digits (e.g. `071`).

```
core/ADRs   max = ADR-070
release/ADRs max = ADR-066
global max  = max(070, 066) = 070
next        = 071  →  ADR-071
```

**Why the union matters (the latent-defect the parent-issue AC method hides).** The AC's convenience phrasing — "list `core/ADRs/ADR-*.md`, sort, take tail" — computes the max from ONE directory. It passes by luck only while the two directories' maxima coincide (today core's 070 ≥ release's 066). The first time a release-side ADR is the global max, a single-directory tail allocates a number that already exists in the sibling directory → `check-adr-numbers.py` hard-fails `DUPLICATE`. Always allocate across the union.

Re-check the live global max at scaffold time — the ADR sequence is active and may advance between sessions.

## 3. Choose the target directory by decision scope

The number is global regardless of which directory the file lands in; the directory encodes the decision's SCOPE:

| Decision scope | Target directory |
|---|---|
| Cross-cutting, platform-wide | `core/ADRs/ADR-NNN-<kebab-title>.md` |
| Release-pipeline-scoped | `release/ADRs/ADR-NNN-<kebab-title>.md` |

When ambiguous, ask the operator or default to `core/ADRs/` and state the choice in the hand-off.

## 4. Scaffold from the canonical template

Use the copy-paste template in `core/standards/adr-authoring-guide.md` § ADR template. The frontmatter fields are defined once in `core/schemas/adr-schema.md §2`; the body sections are the six required sections from `adr-schema.md §3` with `## Alternatives Considered` inserted before `## Consequences` (the Nygard-classic section required by the ADR issue template) — seven sections total in the template:

| # | Section | Pre-fill or placeholder |
|---|---|---|
| 1 | `## Status` | Pre-fill: restate `Proposed`. |
| 2 | `## Context` | Placeholder — operator writes the forces/problem. |
| 3 | `## Decision` | Placeholder — operator states the decision actively. |
| 4 | `## Alternatives Considered` | Placeholder — operator records the rejected options (the load-bearing section). |
| 5 | `## Consequences` | Placeholder — operator writes the trade-offs. |
| 6 | `## Reversibility` | Placeholder — operator picks CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE + rationale. |
| 7 | `## Related ADRs` | Placeholder — operator adds ADR-number-form cross-links. |

Do NOT restate the field rules in the skill or in the scaffolded file's comments beyond the template's own inline hints — reference the schema.

## 5. Pre-fill ONLY derivable metadata

Fill what is DERIVABLE without inventing; leave what must be DECIDED as placeholders.

| Field | Pre-filled value | Evidence label |
|---|---|---|
| `title` / H1 | `ADR-NNN — <human title>` (title stub from the operator's phrasing) | `[ASSUMPTION – CONFIRM]` on the stub wording |
| `status` | `Proposed` (enum default) | `[SOURCE]` (schema default) |
| `date` | today, `YYYY-MM-DD` (validate day-of-week) | `[SOURCE]` |
| `release` | current release slug or version | `[SOURCE]` / `[CONTEXT]` |
| `deciders` / `tags` / `source_observations` | stubs | `[ASSUMPTION – CONFIRM]` |
| section headers | the 7 headers above | `[SOURCE]` (template) |

Every section BODY stays an author-fill placeholder. Never draft Context / Decision / Consequences prose from the conversation — that is the operator's decision to own (CLAUDE.md No-invention).

## 6. Immutable-numbering + supersession walkthrough

- **Allocate the next free number, never reuse.** A number is never re-issued, even for a superseded ADR.
- **Never renumber an existing ADR.** Supersession is a `Status:` transition on the OLD ADR (`Superseded by ADR-NNN`) plus a NEW monotonic ADR — not a renumber or in-place overwrite (`core/ADRs/README.md` § Status enum; `adr-authoring-guide.md` § Supersession + immutability). The body below `## Status` on the old ADR stays byte-frozen for the audit trail.
- **Supersession scaffold flow:**
  1. Allocate `max(global)+1` for the NEW (superseding) ADR.
  2. Scaffold the new ADR; in its `## Status` note it supersedes ADR-MMM; in `## Related ADRs` link ADR-MMM.
  3. Emit a one-line reminder for the operator to stamp the OLD ADR's `## Status` with `Superseded by ADR-NNN`. **Do NOT auto-edit the superseded ADR** — that crosses into governed-change territory on an immutable `core/` record; the operator makes that edit.
- **Collision resolution at merge is the one mechanical exception** — if two branches claim the same `NNN`, the later claimant is renumbered to the next free slot with a `## Status` "Numbering provenance" note. The skill does not perform this; it allocates against the live tree and the merge-time checker catches the race.

## 7. Hand-off summary (what to report)

After the file lands, report:
- the allocated number + the observed global max (so the operator can verify `max+1` across both directories);
- the file path at the resolved ADR home;
- a statement that the home was resolved dynamically (from `ADR_DIRS` or a both-dirs glob), not hardcoded;
- the list of sections awaiting the operator's prose;
- on a supersession scaffold, the reminder to stamp the superseded ADR's `## Status` (and the explicit note that the skill did not auto-edit it).

Write-first-speak-second: never report the ADR "scaffolded" until the file exists on disk and has been confirmed.
