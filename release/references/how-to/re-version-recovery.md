<!-- reference-durability: allow-version-ref -->
# How-To — Re-Version Recovery (post-tag collision)

A **re-version** is a release that changed its version mid-pipeline: a version was
claimed, then abandoned, then the release reshipped under a different version
(`vX claimed → abandoned → reshipped as vY`). This runbook is the **recovery**
doctrine — what to do when a version collision is caught **after** the prevention
and detection layers have already let an artifact through.

It is the standing companion to the machine-readable re-version ledger
(`release/releases/RELEASE_REVERSIONS.md`), which **records** each abandonment; this
runbook **acts** on what that ledger records.

## When this fires

The platform defends version identity in three layers, in order:

1. **Prevent** — the version is claimed by an atomic compare-and-swap on the git tag
   at merge time (defer-to-merge + ref-CAS). The loser of a CAS race recomputes the
   next-free version *before* it pushes, so in the steady state it never pushes a tag
   and leaves no orphan.
2. **Detect** — a pre-merge freeness check (Stage 9 re-check and the Stage 12 claim
   preflight) halts a release whose intended version was taken before the merge lands.
3. **Recover** — *this runbook.* The residual case, which arises only when:
   - prevention **and** detection both failed and a collision reached `main`; **or**
   - an operator directs a re-version **after** a tag was already pushed (a sibling
     claimed the slot between this release's plan and its tag — the dominant live
     pattern the ledger records); **or**
   - a **pre-instrumentation** abandoned artifact already sits on origin from before
     the determinism work existed.

Recover is **narrow by construction.** Under defer-to-merge + ref-CAS, an orphan tag
is rare — the common re-version abandons only a provisional *name* (no tag was ever
cut), and the version that was "abandoned" is usually the **live canonical tag of the
sibling release that won the slot**. This runbook reaps a tag **only** when an
authority declares it abandoned *and* confirms a tag was actually pushed for it — never
by inferring "this version isn't the latest."

## The three residues and their dispositions

A re-version leaves damage on up to three surfaces. Each surface gets one fixed,
**forward-only** disposition — recovery is the inverse of claiming, done entirely
forward (no force-push, no `reset --hard`, no history rewrite).

| ID | Residue | Surface | Disposition | Forward-only mechanism |
|---|---|---|---|---|
| **R-1** | The orphan git tag of the abandoned version | The tag — the authoritative, CAS-claimed surface | **REAP** | `git push --delete origin <abandoned-tag>` then `git tag -d <abandoned-tag>` (both non-force). A tag is a ref, not history — deleting an *unreferenced, declared-abandoned* tag removes a pointer and rewrites nothing. |
| **R-2** | Stale version labels baked into merged commit messages, the merged PR title, and the release branch name | History — immutable | **ACCEPT AS RESIDUAL, with documented provenance** | None. History cannot be rewritten forward-only (rewriting needs a force-push, which is denied). Record the labels in the ledger's `residual_labels` cell and the RELEASE_LOG note as the as-authored cosmetic build-record artifact they are. |
| **R-3** | A corpus row claimed under the abandoned version (RELEASE_LOG / RELEASE_INDEX / RELEASE_DIGEST / RELEASE_NOTES / CHANGELOG / `.version`) | The ledgers — conflict-resolved, not CAS | **ROLL FORWARD (amending edit)** | A plain forward `Edit` that restamps the row to the canonical version and self-documents the abandoned-version provenance. The v1.03 release-note frontmatter is the proven end-state exemplar (see Step 1). |

Why these three and not others: the founding architecture establishes that a release
has **two** version-claim surfaces — the **tag** (atomic CAS, authoritative) and the
**corpus ledgers** (conflict-resolved, not CAS) — plus a third **immutable** surface
(history). Recovery un-claims the abandoned version across exactly those surfaces: the
authoritative surface is *reaped*, the conflict-resolved surface is *rolled forward*,
and the immutable surface is *documented*.

## Step-by-step recovery (forward-only)

Work the steps in order. The durable record (R-3) is restamped first so the canonical
version is authoritative before the orphan tag is removed.

### Step 0 — Establish the canonical version and record the abandonment

1. Re-run the authoritative allocation rule (max published semantic version, with the
   orphan v3.x lineage excluded) at the release's merge SHA to confirm the free
   version the release **should** carry.
2. Append a row to the re-version ledger (`release/releases/RELEASE_REVERSIONS.md`) —
   one row per abandoned version — recording `slug`, `abandoned_version`,
   `final_version`, the `claimed_versions` sequence, `abandoned_tag_pushed`,
   `merge_sha`, `collided_with`, and `disposition`. Set:
   - `disposition = tag-orphaned` **only if** a tag was actually pushed for the
     abandoned version and that tag is **not** canonical for any live row;
   - `disposition = none` if the abandoned version was only a provisional name (no tag
     cut) or is the live canonical tag of the sibling that won the slot;
   - `disposition = unrecoverable` for a pre-instrumentation loss whose artifacts are
     already gone.

   The ledger producer (the Stage 13 close tooling) appends this row automatically when
   a re-version occurred; author it by hand only when recovering a case the producer
   did not capture.

### Step 1 — R-3 corpus roll-forward (the durable record first)

Restamp the canonical version across every surface the abandoned row touches:

- the RELEASE_LOG row (Version, Tag, and Merge-SHA cells),
- the RELEASE_INDEX row,
- the RELEASE_DIGEST entry,
- the release-note and release-plan frontmatter,
- CHANGELOG,
- `.version`.

Self-document the abandoned version in the row's note so the provenance survives. The
exemplar is the v1.03 release note
(`release/releases/notes/v1/v1.03-bundle-and-related_RELEASE_NOTES.md`): its frontmatter
carries `issues: []` plus a leading `#`-comment block explaining that the per-issue
numbers "did not survive the repository re-versioning" — an empty list meaning *no
recoverable numbers, not zero scope.* Generalize that pattern: the row states the
canonical version, and a note records what was abandoned and why.

This is **Document-Tier-1 authoring** — it is operator-gated and lands via the Stage 13
chore PR (or a dedicated `chore/<slug>-reversion-recovery` PR if the release is already
closed). The reaping tool **detects** a stale-version row and reports it, but **never**
edits corpus prose on its own.

### Step 2 — R-1 orphan-tag reap (only if a tag was pushed for the abandoned version)

Skip this step entirely if `abandoned_tag_pushed = false` — there is no tag to reap.

Preview first, then apply, gated on the ledger:

```bash
# Preview — reads RELEASE_REVERSIONS.md, lists what it WOULD reap, mutates nothing:
bash release/tools/cleanup-orphan-state.sh --reap-orphan-tags --dry-run

# Apply — requires BOTH --apply AND --force (double opt-in; a tag delete is
# MODERATE-reversibility — re-pushable from the recorded merge_sha, but it
# transiently breaks any reference that resolved the tag):
bash release/tools/cleanup-orphan-state.sh --reap-orphan-tags --apply --force
```

The tool authorizes a reap only for a ledger row whose `disposition = tag-orphaned`
(equivalently, `abandoned_tag_pushed = true` with no `reaped_ref` yet), refuses to reap
a tag that is the canonical version of a live RELEASE_LOG row, and on success transitions
that ledger row's `disposition` to `tag-reaped` and writes the cleanup reference into
`reaped_ref`.

If you are recovering a case the ledger does not yet cover, name the tag explicitly with
the pre-ledger fallback (the tool never guesses):

```bash
bash release/tools/cleanup-orphan-state.sh --reap-orphan-tags --abandoned <abandoned-tag> --apply --force
```

The reap is **idempotent** — a tag already absent from origin is reported as a no-op,
so the command is safe to re-run. It requires network reachability to `origin`; a
transport failure is reported distinctly from a policy refusal (a transport failure is
retry-safe; a refusal means stop — the tag is protected or in use).

**Manual equivalent** (for the no-ledger or hook-blocked path — both non-force):

```bash
git push --delete origin <abandoned-tag>   # delete on origin FIRST
git tag -d <abandoned-tag>                  # then delete locally — only after origin succeeds
```

Delete origin **first** and the local tag **only after** origin succeeds. Deleting the
local tag while the origin delete failed would leave origin and local divergent (origin
keeps the tag, local loses it — the inverse of the intended state).

### Step 3 — R-2 residual-label documentation

Record the immutable branch name, PR title, and commit-message labels that retain the
as-authored abandoned version in the ledger's `residual_labels` cell and the RELEASE_LOG
note, described as the as-authored cosmetic build-record artifact. **No mutation** —
these are history.

### Step 4 — Verify

Confirm the end state:

- the release notes are present at the canonical version;
- the RELEASE_LOG row reads VERIFIED at the canonical version (no `(unrecoverable —
  re-versioned)` smear);
- the RELEASE_INDEX and RELEASE_DIGEST entries name the canonical version;
- the published GitHub Release exists at the canonical tag;
- the abandoned tag is **absent** from origin —
  `git ls-remote --tags origin <abandoned-tag>` returns empty;
- the ledger row's `disposition` is `tag-reaped` (or `row-reaped` for an R-3-only
  recovery) and `reaped_ref` is set.

## What recovery does NOT do

- **Never force-push to rewrite history.** The stale commit/PR/branch labels (R-2) are
  immutable; they are documented, not rewritten. `git push --force`, `git reset --hard`,
  and history rewrites are denied — recovery uses none of them.
- **Never reap a tag that an authority has not declared abandoned.** A tag is reaped
  only when the ledger marks its row `tag-orphaned` (or the operator names it with
  `--abandoned`). Abandonment is never inferred from "not the latest version."
- **Never reap a tag that is the canonical version of a live release row.** The
  abandoned version of one release is frequently the live tag of the sibling that won
  the slot; the tool refuses to reap such a tag even if it is wrongly declared abandoned.
- **Never auto-edit corpus prose from the tool.** The R-3 corpus roll-forward is
  Document-Tier-1 authoring, operator-gated; the tool reports a stale-version row, it
  does not rewrite it.

## Hook-blocked → user-side handoff

If a reap step is blocked by a security hook and there is no tool-side alternative,
hand the equivalent off to the operator with the standard template — cite the blocking
hook file and rule ID, present the one-click command, state the effect and its
reversibility tier, and state the post-execution verification:

> ⛔ **Hook-blocked, user-side handoff** — `<hook-file-path>:<RULE-ID>` blocked
> `deleting the abandoned orphan tag`.
>
> **Run in your terminal:**
> ```bash
> git push --delete origin <abandoned-tag> && git tag -d <abandoned-tag>
> ```
> **Effect:** removes the abandoned version's orphan tag from origin and locally.
> Reversibility: **MODERATE** (re-pushable from the row's recorded merge SHA in hours,
> but transiently breaks any reference that resolved the tag).
> **After you run it:** the recovery will re-check `git ls-remote --tags origin
> <abandoned-tag>` is empty and transition the ledger row to `tag-reaped`.

A plain non-force `git push --delete <tag>` is permitted by the destructive-action hook
(only force-push forms are blocked), so this handoff fires only in genuinely restricted
contexts (for example, when the script-execution allowlist does not cover the invoking
path); the operator runs the manual non-force commands above.
