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

1. **Resolve the binding anchor: the mainline tree, not the working tree** (§ 2.1 states why, and is the authority for it — do not re-derive its argument here).
2. Enumerate every `ADR-NNN-*.md` filename across BOTH resolved directories **as they exist at that anchor**.
3. Parse each `NNN` (the `ADR-(\d+)-` prefix) and take the maximum across the **union** of both directories.
4. Add one; zero-pad to three digits (e.g. `071`).

**Invoke the shipped oracle rather than hand-rolling steps 1–4:**

```bash
python3 release/tools/renumber-adr.py --next-free      # anchor(origin/main) + 1
```

`--next-free` implements exactly this algorithm against the mainline anchor, and it reads the home set and the filename pattern from `check-adr-numbers.py` — the same constants § 1 resolves — so there is never a second parser to drift from the gate. Hand-rolling the enumeration is the fallback when the tool is unavailable, not the default; if you run it by hand, run it against the anchor (§ 2.1's fenced derivation), never against a bare working-tree listing.

**Why the union matters.** A convenience phrasing that reads "list `core/ADRs/ADR-*.md`, sort, take tail" computes the max from ONE directory. It passes by luck for exactly as long as the two directories' maxima coincide. The first time a release-side ADR is the global max, a single-directory tail allocates a number that already exists in the sibling directory → `check-adr-numbers.py` hard-fails `DUPLICATE`. Always allocate across the union.

Re-check the live anchor at scaffold time — the ADR sequence is active and may advance between sessions.

### 2.1 The binding anchor is the mainline — an unmerged claim does not bind the sequence

Re-checking the live max (above) guards **staleness across sessions**. It does not answer the harder question: *which tree do you take the max over?* A working clone can see numbers that are claimed on a sibling branch and not yet merged, and an author who steps past those claims lands the corpus in the failure state below.

**The rule: bind to the mainline only.** Take `max(global)` over the ADR files as they exist on the mainline branch (`origin/main`) and allocate the next slot above it. Scanning sibling branches, open pull requests, or another worktree is for **detection** — it tells you a renumber is likely, and it belongs in the hand-off — but it **never** moves the allocated number.

**Why stepping past an unmerged claim is the wrong remedy.** A number is *allocated at authorship* but *claimed at merge*. An unmerged claim therefore does not bind the sequence: the branch holding it may be rebased, renumbered, or abandoned. If two sibling claims are visible and the author steps above them to "avoid a collision", and this record merges first, the record lands **above the mainline max with a gap beneath it**. The contiguity gate fails a gap exactly as readily as a duplicate, so from that merge onward it fails **every** subsequent pull request — a strictly worse outcome than the collision that was being avoided. Pre-reserving a higher slot is no remedy for the same reason.

**A duplicate is the cheap failure; a gap is the expensive one.** A duplicate is resolved by the merge-time renumber in § 6 — the first record to merge keeps the number, the later claimant moves to the recomputed next-free slot, and its `## Status` carries the provenance note. That renumber routinely moves a record **downward**, and the corpus's own renumber log records live specimens of it. Allocating at the mainline next-free slot is therefore safe under **every** merge order; allocating above it is safe under only one.

Derive the anchor explicitly rather than trusting a working-tree listing:

```bash
git fetch origin
git ls-tree -r --name-only origin/main -- core/ADRs release/ADRs \
  | grep -oE 'ADR-[0-9]{3}' | sort -n | tail -1     # the binding anchor
```

The authoritative statement of this rule, with the corpus specimens behind it, is the **§ Renumber log** in `core/ADRs/README.md`. Read it there; this section applies it at allocation time rather than restating its evidence.

**What detection is for.** Having derived the number from the anchor, a sibling scan is still worth running: naming the visible unmerged claims in the hand-off tells the operator a merge-time renumber is likely and lets them sequence the merge deliberately. It changes the *report*, never the *number*.

## 3. Choose the target directory by decision scope

The number is global regardless of which directory the file lands in; the directory encodes the decision's SCOPE:

| Decision scope | Target directory |
|---|---|
| Cross-cutting, platform-wide | `core/ADRs/ADR-NNN-<kebab-title>.md` |
| Release-pipeline-scoped | `release/ADRs/ADR-NNN-<kebab-title>.md` |

When ambiguous, ask the operator or default to `core/ADRs/` and state the choice in the hand-off.

## 4. Scaffold from the canonical template

**Derive the section set; never restate it.** The body-section set and each section's requirement level are DEFINED once, in `core/schemas/adr-schema.md` §3, and every other surface CITES that section — an authority chain the schema itself states, and one this file is a named member of. The frontmatter fields are defined once in the same schema's §2. So this reference holds **no** section list and **no** section count of its own: a restated set is a shadow copy that goes stale the moment the schema is reconciled, and the scaffold would then emit a set the standard no longer requires.

Read the set at scaffold time. The section headers, in the schema's own order, are the first column of §3's table:

```bash
awk '/^## 3\. /{s=1;next} s&&/^#{2,3} /{exit} s' core/schemas/adr-schema.md \
  | grep -oE '`## [^`]+`' | tr -d '`'
```

The copy-paste rendering of that set — the fenced block an author can lift wholesale, with the per-section authoring hints — is `core/standards/adr-authoring-guide.md` § ADR template. Take the **set and its order** from the schema (the defining authority) and the **placeholder prose** from the guide's rendering; § 8 asserts the two agree rather than assuming it.

**Emit by section CLASS, not by row.** The pre-fill decision is a property of what a section *is*, so it survives any change to which sections exist:

| Section class | How the scaffold treats it | Why |
|---|---|---|
| **Status-restating** — the section whose content restates a derivable frontmatter value | **Pre-fill** from the frontmatter value. | Derivable, not decided. |
| **Decision-prose** — every section recording what was weighed, chosen, concluded, or accepted | **Labeled placeholder**, always emitted, never drafted. | The rationale is the operator's to write (No-invention). |
| **Cross-link** — the section carrying ADR-number-form links to sibling records | **Labeled placeholder.** | The links are the operator's; supersession links follow § 6. |
| **Designated reference block** — the provenance section named below | **Labeled placeholder**, emitted last, with the delete-if-unused instruction. | See the placement rules below. |

**Every section in the derived set is emitted — presence is unconditional.** Where a section's requirement level is *required, content conditional* (the schema states which), the conditionality attaches to what the section SAYS, never to whether it is there. The scaffold cannot know at scaffold time which branch of the content rule applies, and inferring it would be invention; so it emits the section with a placeholder naming both branches — record the options weighed, **or** declare the single forced approach — and lets the author choose. The asymmetry is decisive: an emitted section that turns out unneeded costs one line to delete and is visible while it sits there, whereas an omitted one is invisible debt that a corpus sweep later has to find and backfill on records that are by then immutable.

**Append the designated reference block last.** After the final section of the derived set, emit the ADR's designated reference block — a single H2 spelled exactly `## References`, per `adr-authoring-guide.md` § Issue references in ADRs. Two properties make the placement load-bearing rather than cosmetic:

- **The heading string is not a free choice.** Two independent gates classify reference placement and they do not recognize the same heading set; `## References` is chosen because it sits in their **intersection**, so a record carrying it satisfies both and needs no override marker for its provenance. The trailing cross-link section is recognized by **neither** — a provenance reference parked there is flagged exactly as if no block existed at all.
- **Last position is what makes the block a forcing function.** Both gates treat the first recognized heading as a *cut point*: everything below it counts as placed, everything above it does not. Emitting the block last therefore keeps legitimate provenance clean while still flagging a bare reference dropped into body prose or into an identity frontmatter field — the frontmatter sits above the cut by construction, which is why the scaffold needs no separate identity-field scanner.

Each line inside the block pairs the bare number with a summary noun phrase, because the summary is what still carries the meaning once the number no longer resolves. A record with no provenance reference **deletes the section** rather than shipping an empty heading — the placeholder says so.

**Population boundary.** `operations/templates/adr-template.md` governs a different population — ADR instances rendered inside a consuming project — under its own contract. The scaffold never reads it and never applies it: this procedure scaffolds platform ADRs only, at the homes resolved in § 1.

Do NOT restate the field rules in the skill or in the scaffolded file's comments beyond the template's own inline hints — reference the schema.

## 5. Pre-fill ONLY derivable metadata

Fill what is DERIVABLE without inventing; leave what must be DECIDED as placeholders.

| Field | Pre-filled value | Evidence label |
|---|---|---|
| `title` / H1 | `ADR-NNN — <human title>` (title stub from the operator's phrasing) | `[ASSUMPTION – CONFIRM]` on the stub wording |
| `status` | `Proposed` (enum default) | `[SOURCE]` (schema default) |
| `date` | today, `YYYY-MM-DD` (validate day-of-week) | `[SOURCE]` |
| `release` | current release slug or version | `[SOURCE]` / `[CONTEXT]` |
| `deciders` / `tags` / `source_observations` | stubs — `deciders` names a role or a literal name, never an account handle | `[ASSUMPTION – CONFIRM]` |
| section headers | every header in the set derived per § 4, in the schema's order, plus the designated reference block last | `[SOURCE]` (derived, not restated) |

**No identity field carries an issue reference.** `title:`, `release:` and `deciders:` say what the record IS, so a number that rots there corrupts identity rather than merely provenance — and there is no override marker for it. Name the release by its slug, the deciders by role or literal name, and put any originating issue reference in `source_observations:` or in the designated reference block, each with a summary noun phrase.

Every section BODY stays an author-fill placeholder. Never draft decision-prose from the conversation — every section recording what was weighed, chosen, concluded, or accepted is the operator's decision to own (CLAUDE.md No-invention).

## 6. Immutable-numbering + supersession walkthrough

- **Allocate the next free number, never reuse.** A number is never re-issued, even for a superseded ADR.
- **Never renumber an existing ADR.** Supersession is a reciprocal edge on the OLD ADR plus a NEW monotonic ADR — not a renumber or in-place overwrite (`core/ADRs/README.md` § Status enum; `adr-authoring-guide.md` § Supersession + immutability). For a **whole** supersession the reciprocal is the `Status:` transition (`Superseded by ADR-NNN`); for a **partial** one it is a `superseded_by:` frontmatter entry and the status stays `Accepted` (step 3 below; `adr-schema.md` §5). The body below `## Status` on the old ADR stays byte-frozen for the audit trail either way.
- **Supersession scaffold flow:**
  1. Allocate `max(global)+1` for the NEW (superseding) ADR.
  2. Scaffold the new ADR; in its `## Status` note it supersedes ADR-MMM; in `## Related ADRs` link ADR-MMM.
  3. Emit a one-line reminder for the operator to land the reciprocal on the OLD ADR. **Which reciprocal depends on the scope, and the two are not interchangeable** (`adr-schema.md` §5):
     - **Whole supersession** — stamp the OLD ADR's `## Status` with `Superseded by ADR-NNN`.
     - **Partial supersession** (a clause, rule, decision item, or substrate choice — the common case) — add `superseded_by: ADR-NNN in-part (<scope label>)` to the OLD ADR's frontmatter and **leave its `status:` reading `Accepted`**. Stamping `Superseded` here asserts a retirement the new ADR does not claim, and freezes a record that still binds.

     **Do NOT auto-edit the superseded ADR** in either case — that crosses into governed-change territory on an immutable `core/` record; the operator makes that edit.
- **Collision resolution at merge is the one mechanical exception** — if two branches claim the same `NNN`, the later claimant is renumbered to the next free slot with a `## Status` "Numbering provenance" note. **The skill does not perform this, and neither does the merge-time checker: the checker DETECTS a duplicate or a gap, it has never renumbered anything.** The move is performed by `release/tools/renumber-adr.py` at Stage-12 Phase A.5.7, which writes the provenance note as part of the move rather than leaving it to discipline. The skill's job is upstream of that: allocate against the mainline anchor (§ 2.1) so the number is correct under every merge order, and name any visible unmerged sibling claims in the hand-off so the operator can expect the renumber.

## 7. Hand-off summary (what to report)

After the file lands, report:
- the allocated number + the observed global max, **and the anchor the max was taken over** (so the operator can verify `max+1` across both directories against the tree that actually binds — see § 2.1);
- any visible unmerged sibling claims on the same number, named as a likely merge-time renumber — detection, not a reason the number moved;
- the file path at the resolved ADR home;
- a statement that the home was resolved dynamically (from `ADR_DIRS` or a both-dirs glob), not hardcoded;
- the list of sections awaiting the operator's prose;
- the § 8 self-check verdict — the structural assertions as the scaffold-time result, the lint result **stated as a baseline**, and the re-run the operator owes once the record is filled;
- the § 9 index registration performed, or the statement that none was owed;
- on a supersession scaffold, the reminder to stamp the superseded ADR's `## Status` (and the explicit note that the skill did not auto-edit it).

Write-first-speak-second: never report the ADR "scaffolded" until the file exists on disk and has been confirmed.

## 8. Conformance self-check

Runs on the file just written — after § 5 and **before** the § 7 hand-off, whose report carries its verdict. The point of the check is that "born conformant" is an *asserted, reported property of the run*, not a claim in a document: the scaffold verifies its own output and says what it found.

**8a — structural assertions (load-bearing at scaffold time).** These examine the shape the scaffold controls, so they are meaningful on an unfilled record:

| # | Assertion | How it fails |
|---|---|---|
| S1 | The emitted H2 set equals the set derived per § 4, **in the schema's order** | A dropped, added, renamed or reordered section |
| S2 | The schema's defining table and the guide's rendered template agree with each other | A divergence upstream — **stop and report it**; do not pick a winner and do not scaffold against a guess |
| S3 | The designated reference block is present, spelled exactly, and is the **last** H2 in the file | A missing block, a variant heading, or a block that is not last (which would move the cut point and let placed references read as unplaced) |
| S4 | No issue reference appears in an identity frontmatter field | Enforced as a rule by the lint in 8b, so S4 is a pre-check, not a second authority |

```bash
F=<the scaffolded file>
diff <(awk '/^## 3\. /{s=1;next} s&&/^#{2,3} /{exit} s' core/schemas/adr-schema.md \
        | grep -oE '`## [^`]+`' | tr -d '`') \
     <(grep -E '^## ' "$F" | grep -v '^## References$')          # S1: expect no diff
grep -E '^## ' "$F" | tail -1                                      # S3: expect '## References'
```

**8b — durability lint.** One already-shipped tool covers the status enum, stale anchors, the account-handle rule, and the identity-field issue-reference rule:

```bash
python3 release/tools/check-adr-durability.py --root . --files "$F"   # expect COUNT 0
```

**8c — reference placement, verified on the FILLED record.** Placement is a property of prose, so it is checked once the author has written some. The shared classifier takes its patterns from the pattern library; **read** them out rather than sourcing the library, so the check stays single-sourced without needing a script-execution allowlist entry:

```bash
LIB=core/hooks/lib/fragile-ref-patterns.sh
ISSUERE=$(sed -n "s/^ISSUEREF_RE='\(.*\)'$/\1/p" "$LIB")
HEXRE=$(sed -n "s/^HEXCOLOR_RE='\(.*\)'$/\1/p"  "$LIB")
MINW=$(sed  -n "s/^MIN_SELFDESCRIBE_WORDS=\([0-9]*\)$/\1/p" "$LIB")
[ -z "$ISSUERE" ] || [ -z "$MINW" ] && echo "SKIP — pattern library did not parse" && exit
REFLINE=$(grep -n '^## References$' "$F" | head -1 | cut -d: -f1); : "${REFLINE:=0}"
awk '{printf "%d\t%s\n", NR, $0}' "$F" \
  | awk -f core/hooks/lib/positional-issueref.awk \
        -v refline="$REFLINE" -v issuere="$ISSUERE" -v hexcolor="$HEXRE" -v minwords="$MINW"
```

An empty extraction reports a visible **SKIP**, never a pass — a check that examined nothing must not read green.

**8d — the vacuity qualifier, and why it is mandatory.** A freshly-scaffolded record carries **no author prose**, so 8b and 8c find nothing on it *whatever the scaffold emitted*. A scaffold that emitted no reference block at all also reports zero — which is precisely how the omission stayed invisible. **A zero over an empty file is a baseline, not evidence of conformance.** The hand-off therefore reports the 8a assertions as the scaffold-time result, states the 8b baseline **as a baseline**, and names the re-run of 8b + 8c on the filled record as the operator's beat. The discriminator between a real pass and a vacuous one is observable and should be reported with the verdict: the reference block was **detected** (`REFLINE` above zero), and the record carries at least one reference for the gates to have an opinion about.

## 9. Release-index registration

**The obligation is an outcome, not a mechanism: leave the release ADR index consistent with the file set the scaffold just extended.** A new record whose index row never lands is invisible to every reader who arrives through the index, and the omission is silent — nothing fails, so nothing surfaces it. Closing that at authorship is the same author-time-prevention argument as the rest of this procedure.

- **Scope — the release index only.** A scaffold landing in `release/ADRs/` registers into `release/ADRs/README.md`. A scaffold landing in `core/ADRs/` registers **nothing**: that module's README is a curated thematic document, not an index, and appending rows to it would destroy the curation and mint a second hand-maintained copy of the file set. Say so in the hand-off rather than silently doing nothing.
- **Mechanism — prefer the index's own generator.** If the index is produced by a generator, run it; the registration is then a projection and cannot drift. Only where no generator exists does the scaffold append the row itself, in the index's existing row shape. Stating the outcome and resolving the mechanism at runtime is what keeps this step correct if the index later becomes generated.
- **Registration is part of the same authorized act.** The explicit request that authorizes the scaffold authorizes this row for the file it just created — one trigger, one drafted package. It authorizes nothing else in that file: no reordering, no edits to other rows, no changes to any other index.
- **Report it.** The hand-off names the index touched and the row added, or states that none was owed. An unreported second write is the failure this step must not become.
