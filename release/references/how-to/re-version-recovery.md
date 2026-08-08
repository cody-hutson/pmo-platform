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
sibling release that won the slot**. This runbook **records** an orphan tag only when an
authority declares it abandoned *and* confirms a tag was actually pushed for it — never
by inferring "this version isn't the latest." It does not remove one: a version tag is
retained, because `refs/tags/v*` is protected at the repository host and the remote
delete is rejected for every account. That rule is owned by
`core/rules/git-workflow.md` § Tag Retention.

## The three residues and their dispositions

A re-version leaves damage on up to three surfaces. Each surface gets one fixed,
**forward-only** disposition — recovery is the inverse of claiming, done entirely
forward (no force-push, no `reset --hard`, no history rewrite).

| ID | Residue | Surface | Disposition | Forward-only mechanism |
|---|---|---|---|---|
| **R-1** | The orphan git tag of the abandoned version | The tag — the authoritative, CAS-claimed surface | **RETAIN AND RECORD** | None on this host, and none is possible. `refs/tags/v*` is protected at the repository host (`core/rules/git-workflow.md` § Tag Retention): the remote delete is rejected for every account, the owner included. Record the orphan in the ledger and transition its row to `tag-retained`. Retention is benign — the orphan points at a commit that stays reachable through its canonical tag. |
| **R-2** | Stale version labels baked into merged commit messages, the merged PR title, and the release branch name | History — immutable | **ACCEPT AS RESIDUAL, with documented provenance** | None. History cannot be rewritten forward-only (rewriting needs a force-push, which is denied). Record the labels in the ledger's `residual_labels` cell and the RELEASE_LOG note as the as-authored cosmetic build-record artifact they are. |
| **R-3** | A corpus row claimed under the abandoned version (RELEASE_LOG / RELEASE_INDEX / RELEASE_DIGEST / RELEASE_NOTES / CHANGELOG / `.version`) | The ledgers — conflict-resolved, not CAS | **ROLL FORWARD (amending edit)** | A plain forward `Edit` that restamps the row to the canonical version and self-documents the abandoned-version provenance. The v1.03 release-note frontmatter is the proven end-state exemplar (see Step 1). |

Why these three and not others: the founding architecture establishes that a release
has **two** version-claim surfaces — the **tag** (atomic CAS, authoritative) and the
**corpus ledgers** (conflict-resolved, not CAS) — plus a third **immutable** surface
(history). Recovery un-claims the abandoned version across exactly those surfaces: the
authoritative surface is *retained and recorded*, the conflict-resolved surface is
*rolled forward*, and the immutable surface is *documented*. The surface taxonomy is
unchanged by the host tag-protection control — only R-1's disposition verb moved, from
*reap* to *retain*, because the operation the earlier verb named is one the host
rejects.

## Step-by-step recovery (forward-only)

Work the steps in order. The durable record (R-3) is restamped first so the canonical
version is authoritative before the orphan tag's ledger row is settled.

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

### Step 2 — R-1 orphan-tag record (the tag is retained)

Skip this step entirely if `abandoned_tag_pushed = false` — there is no orphan tag to
record.

The tag is **not removed.** Run the detection pass, which reads the ledger, classifies
each authority-declared-abandoned tag against host policy, and settles its ledger row:

```bash
# Detect and record — reads RELEASE_REVERSIONS.md, classifies, deletes nothing:
bash release/tools/cleanup-orphan-state.sh --reap-orphan-tags --dry-run
```

The tool considers only a ledger row whose `disposition = tag-orphaned` (equivalently,
`abandoned_tag_pushed = true` with no `reaped_ref` yet) and refuses to touch a tag that
is the canonical version of a live RELEASE_LOG row. It then reads the host's tag policy
and takes one of three branches:

| Host policy | What the tool does |
|---|---|
| **Protected** — an active host ruleset covers the tag with a deletion rule | Classifies `RETAINED`, transitions the ledger row's `disposition` to `tag-retained`, issues **no** push. `--force` is not required, because nothing destructive is attempted. This is the branch that fires on the canonical repository. |
| **Provably unprotected** — the remote is not a policy-bearing host, or its policy was read and covers nothing | The pre-existing reap path applies unchanged, still behind the `--apply --force` double opt-in. Reaping here is an operator-gated exception to the retention rule, not the default. |
| **Undetermined** — the remote is a policy-bearing host whose policy could not be read | Nothing is attempted and no ledger row is transitioned. The tool names the reason and stops. Re-run where host policy is readable, or assert the host state explicitly with `--assume-unprotected` if you know the deployment carries no tag protection. |

If you are recovering a case the ledger does not yet cover, name the tag explicitly with
the pre-ledger fallback (the tool never guesses):

```bash
bash release/tools/cleanup-orphan-state.sh --reap-orphan-tags --abandoned <abandoned-tag> --dry-run
```

The record pass is **idempotent** — a row already settled carries no reap authority, and
a tag already absent from the remote is reported as a no-op, so the command is safe to
re-run.

**There is no manual equivalent, and none is needed.** Both remote-delete command forms
are rejected by the host ruleset for every account (`core/rules/git-workflow.md`
§ Tag Retention) — a hand-typed command fails exactly where the tool refuses to try. The recovery end state is the ledger row reading
`tag-retained`, which the detection pass writes.

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
- the abandoned tag is **present** on origin —
  `git ls-remote --tags origin <abandoned-tag>` returns its SHA. **An empty result is a
  verification FAILURE, not a success:** it means a version tag was deleted, which no
  procedure authorizes and the host is configured to prevent;
- the ledger row's `disposition` is `tag-retained` (or `row-reaped` for an R-3-only
  recovery, where `reaped_ref` is set).

## What recovery does NOT do

- **Never force-push to rewrite history.** The stale commit/PR/branch labels (R-2) are
  immutable; they are documented, not rewritten. `git push --force`, `git reset --hard`,
  and history rewrites are denied — recovery uses none of them.
- **Never delete a version tag.** `refs/tags/v*` is host-protected; the remote delete is
  rejected for every account, the owner included. An orphan tag is retained and recorded.
  `core/rules/git-workflow.md` § Tag Retention owns this rule and states its one
  host-conditional exception: on a deployment that provably carries no tag protection,
  reaping is an operator-gated exception rather than the default.
- **Never act on a tag that an authority has not declared abandoned.** A tag is even
  considered only when the ledger marks its row `tag-orphaned` (or the operator names it
  with `--abandoned`). Abandonment is never inferred from "not the latest version."
- **Never touch a tag that is the canonical version of a live release row.** The
  abandoned version of one release is frequently the live tag of the sibling that won
  the slot; the tool refuses such a tag even if it is wrongly declared abandoned.
- **Never auto-edit corpus prose from the tool.** The R-3 corpus roll-forward is
  Document-Tier-1 authoring, operator-gated; the tool reports a stale-version row, it
  does not rewrite it.

## Why there is no hook-blocked handoff for R-1

A hook-blocked → user-side handoff is warranted only when a **user-side equivalent that
works** exists. For a version-tag delete none does: the blocker is the host ruleset, not
a local hook, and the ruleset rejects the push for every account including the owner. A
handoff here would hand the operator a command guaranteed to fail — the exact failure
mode the handoff convention exists to prevent.

The distinction is worth stating because it was previously conflated. The **local
destructive-action hook** permits a plain non-force remote tag delete (only force-push
forms are in its blocked set), which made the operation look merely hook-gated. The
**host ruleset** is a separate, stricter mechanism that rejects the push server-side. A
permissive local hook says nothing about what the host will accept; only the host's
policy does, and this runbook reads it rather than inferring it.
