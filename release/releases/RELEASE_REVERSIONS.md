<!-- reference-durability: allow-version-ref -->
# RELEASE_REVERSIONS

Machine-readable re-version ledger. A re-version is a release that **changed its
version mid-pipeline** (`vX claimed → abandoned → reshipped as vY`) — the collision
class the version-claim-determinism capability exists to prevent, made queryable so
the collision rate is measurable over time.

This ledger is the fourth release-corpus surface beside RELEASE_LOG (the per-release
audit trail), RELEASE_INDEX (the release index), and RELEASE_DIGEST (the version-family
digest). Where those record what *shipped*, this records what was *claimed-then-abandoned*
on the way there.

## Schema

```
GRAIN:   one row per ABANDONED version (NOT one per release).
         A release that abandoned two versions (e.g. v1.18 AND v1.19 before
         landing v1.20) contributes TWO rows — one per abandoned version. This
         grain lets the recovery doctrine iterate abandoned versions one-per-row
         with no multi-value parsing.

KEY:     (slug, abandoned_version) is the composite key. `slug` is the durable
         capability identity (the version is payload — a single release can carry
         v2.12 → v2.14 → v2.12, so the version is never a stable key). `slug`
         is also the join key back to the RELEASE_LOG / RELEASE_INDEX row.

APPEND-ONLY (producer):   rows are only ever APPENDED, chronological-recent-first,
         by automated-closeout.sh phase `append_reversions` at the Stage 13 chore
         PR — and only when a re-version occurred. A historical row is never
         rewritten or deleted by the producer.

MUTABLE CELLS (consumer): the `disposition` and `reaped_ref` cells are the ONLY
         cells the recovery-doctrine reaper may transition in place, keyed on
         (slug, abandoned_version), header-column-resolved (not by ordinal). Every
         other cell is immutable once written. This is the one sanctioned in-place
         mutation in the ledger; it is NOT a row rewrite.

COLUMNS (typed):
  slug                  string (kebab)   Durable capability slug — join key to RELEASE_LOG.
  abandoned_version     vX.Y | vX.Y.Z    The version claimed then abandoned by THIS release.
                                         The grain column — one row per value.
  final_version         vX.Y | vX.Y.Z |  The version this release actually shipped (the
                        version-less     surviving claim). Matches its RELEASE_LOG Tag.
  claimed_versions      ordered list     The full claim sequence including the final, in
                        vA → vB → vC      order, with repeats preserved (a round-trip such
                                         as v2.12 → v2.14 → v2.12 keeps both v2.12s).
                                         abandoned_version is, by construction, a value in
                                         claimed_versions[0:-1] that differs from final_version,
                                         de-duplicated (see DERIVATION below).
  abandoned_tag_pushed  true | false |   Was a git tag actually pushed for abandoned_version
                        unknown          by THIS release before it abandoned the version? The
                                         reaper's R-1 gate. `false` when the version was only a
                                         provisional NAME (no tag cut — the pre-tag re-version
                                         path); `unknown` only for pre-instrumentation rows.
  merge_sha             40-hex |         The merge SHA of THIS release's canonical row (the
                        (unrecoverable)  reaper's re-create source if a reap was wrong — recover
                                         the SHA by joining slug → RELEASE_LOG Merge SHA cell).
  collided_with         comma-list of    The sibling release(s) (slug@vX) whose claim forced the
                        slug@vX | —      re-version — the version the sibling took and who took it.
                                         `—` if self-recompute with no identified sibling.
  resolved_at_stage     S9 | S12 |       Where the final re-version settled (Stage 9 re-check,
                        pre-merge        Stage 12 claim-retry / A.5.6c relabel, or pre-merge).
  disposition           enum (below)     Lifecycle of THIS abandoned claim. Producer writes
                                         none / tag-orphaned / unrecoverable; the recovery
                                         reaper transitions to tag-reaped / row-reaped.
  residual_labels       free text | —    The accepted-as-residual immutable build-record labels
                                         (branch name, PR title, commit messages) that retain the
                                         as-authored abandoned-version label. History — never
                                         rewritten, only documented.
  reaped_ref            SHA | PR# | —    Back-reference the reaper fills when it reaps the orphan
                                         (the cleanup commit/PR). `—` until reaped.
  date                  YYYY-MM-DD       Re-version resolution date (UTC) = this release's
                                         RELEASE_LOG date.

DISPOSITION ENUM (closed set) ↔ FIELD MAPPING (the reaper reads this, unambiguously):
  none           ≡ abandoned_tag_pushed=false                       — no orphan artifact; the
                                                                       abandoned version was only a
                                                                       provisional NAME (no tag cut),
                                                                       OR the version is a live tag of
                                                                       a SIBLING release (canonical
                                                                       elsewhere — never reap). Nothing
                                                                       for the reaper to do.
  tag-orphaned   ≡ abandoned_tag_pushed=true  AND reaped_ref=—       — an orphan tag of THIS release's
                                                                       abandoned version exists on origin
                                                                       and is NOT canonical for any live
                                                                       row. The reaper READS this to find
                                                                       what to reap.
  tag-reaped     ≡ reaped_ref set (was tag-orphaned)                 — the reaper deleted the orphan tag;
                                                                       reaped_ref records the cleanup ref.
                                                                       WRITTEN BY the reaper.
  row-reaped     ≡ reaped_ref set (an abandoned-version corpus row   — an abandoned-version corpus row was
                   was rolled forward)                                 rolled forward to the canonical
                                                                       version. WRITTEN BY the reaper.
  unrecoverable  ≡ pre-instrumentation loss                          — the abandoned artifacts predate the
                                                                       determinism work and are lost (the
                                                                       v1.03 boundary case). The reaper
                                                                       READS this (records, never reaps).

DERIVATION — abandoned_versions from a claim sequence (handles the round-trip case):
  abandoned set = { every DISTINCT version in claimed_versions[0:-1] (the sequence
                    EXCLUDING its last element) that differs from final_version }.
  This is positional (drop the last element), NOT set-minus over the whole sequence —
  so a round-trip v2.12 → v2.14 → v2.12 (final v2.12) yields abandoned = {v2.14} (one
  row), correctly KEEPING v2.12 as the final while recording v2.14 as abandoned.
  Each member of the abandoned set is one row.
```

## Collision rate (the measurable AC)

The collision rate is `(re-version count) / (release count)` over a window. Both
counts are grep-able from the corpus. The numerator slug class includes `.`, a
leading digit, and uppercase so every real slug shape is counted — a version-prefixed
slug (`v1.03-bundle-and-related`, dotted) and a milestone-derived slug
(`05-ROLE-sustain-coverage-router`, leading digit + uppercase) both match. The
denominator counts ALL releases including the version-less ones (a version-less
release is itself frequently a collision outcome, so it must not be dropped):

```bash
# Re-version rows (the collision history) — one per abandoned version:
grep -E '^\| [A-Za-z0-9.-]+ \| ' release/releases/RELEASE_REVERSIONS.md | grep -v -- '---'

# Re-version count (rows) — numerator. The [A-Za-z0-9.-] class matches dotted,
# leading-digit, and uppercase slugs (every shape the live corpus carries):
RX=$(grep -cE '^\| [A-Za-z0-9.-]+ \| v' release/releases/RELEASE_REVERSIONS.md)

# Release count — denominator. Anchor on the trailing State + Date columns (every
# RELEASE_LOG release row has them), NOT a digit-led Version, so the 7 version-less
# releases are NOT dropped:
REL=$(grep -cE '\| (VERIFIED|DEPLOYED) \| [0-9]{4}-[0-9]{2}-[0-9]{2} \|$' release/releases/RELEASE_LOG.md)

echo "re-version rate = $RX abandoned-version rows / $REL releases"

# What the recovery reaper must act on (orphan / unrecoverable dispositions).
# Pipe-split fields (leading `|` makes field 1 empty): 2=slug 3=abandoned_version
# 10=disposition. Match the disposition column by its position in the data rows:
awk -F'|' '$10 ~ /tag-orphaned|unrecoverable/ {gsub(/ /,"",$2); gsub(/ /,"",$3); print $2, $3, $10}' \
  release/releases/RELEASE_REVERSIONS.md
```

## Evidence-grounding (why every historical `disposition` is `none` or `unrecoverable`)

Every post-instrumentation abandoned version below is a **live tag of the SIBLING
release that won the slot** (probed `git ls-remote --tags origin <v>` 2026-06-21 —
each resolved as the canonical tag of the `collided_with` sibling), NOT an orphan of
the abandoning release. Under the defer-to-merge model the loser recomputed and the
winner's tag is canonical — so `abandoned_tag_pushed=false` and `disposition=none` are
grounded by the probe, not asserted. The reaper's canonical-version guard correctly
refuses to reap any of these (they are canonical for a live row). The sole exception
is the v1.03 boundary row: it predates the determinism work, its abandoned artifacts
are lost, and it is recorded `unrecoverable` (the reaper reads, never reaps it).

## Ledger

| slug | abandoned_version | final_version | claimed_versions | abandoned_tag_pushed | merge_sha | collided_with | resolved_at_stage | disposition | residual_labels | reaped_ref | date |
|---|---|---|---|---|---|---|---|---|---|---|---|
| pipeline-telemetry-tail | v3.80 | v3.83 | v3.80 → v3.83 | false | 4dcf8298c33b79bffc6efebebb7b53bafd631869 | close-out-reliability-hardening@v3.80, version-identity-and-parser-ssot@v3.81, governance-doc-reconciliation@v3.82 | S12 | none | branch release/v3.80-pipeline-telemetry-tail + 14 commit subjects retain as-authored v3.80 | — | 2026-07-23 |
| governance-doc-reconciliation | v3.81 | v3.82 | v3.80 → v3.81 → v3.82 | false | a0fe5e61de1894239133c18e55f9d1da63819f86 | close-out-reliability-hardening@v3.80,92-version-identity-and-parser-ssot@v3.81 | Stage-12-A.5.6c | none | branch name release/v3.81-governance-doc-reconciliation + on-branch commit subjects retain the as-authored v3.80/v3.81 provisional labels (pre-merge relabel; no v3.80 or v3.81 tag cut by this release); plan file renamed to v3.82-governance-doc-reconciliation_RELEASE_PLAN.md with the body H1 + Version line still reading v3.81 | — | 2026-07-22 |
| governance-doc-reconciliation | v3.80 | v3.82 | v3.80 → v3.81 → v3.82 | false | a0fe5e61de1894239133c18e55f9d1da63819f86 | close-out-reliability-hardening@v3.80,92-version-identity-and-parser-ssot@v3.81 | Stage-12-A.5.6c | none | branch name release/v3.81-governance-doc-reconciliation + on-branch commit subjects retain the as-authored v3.80/v3.81 provisional labels (pre-merge relabel; no v3.80 or v3.81 tag cut by this release); plan file renamed to v3.82-governance-doc-reconciliation_RELEASE_PLAN.md with the body H1 + Version line still reading v3.81 | — | 2026-07-22 |
| 92-version-identity-and-parser-ssot | v3.80 | v3.81 | v3.80 → v3.81 | false | e1bcb48fa4ba55cf6f6ce8403fdd76864054eb9d | close-out-reliability-hardening@v3.80 | Stage-12-A.5.6c | none | branch name release/v3.80-version-identity-and-parser-ssot + the on-branch commit subjects retain the as-authored v3.80 provisional label (pre-merge relabel; no v3.80 tag cut) | — | 2026-07-22 |
| 95-deploy-tooling-resolver-and-test-parity | v3.76 | v3.79 | v3.76 → v3.79 | false | 53c28fbe05107f41b3be8e8f0bfebde7c2124a96 | knowledge-corpus-hygiene@v3.76,pda-rollup-and-portfolio@v3.78 | Stage-12-A.5.6c | none | branch name release/v3.76-deploy-tooling-resolver-and-test-parity + 8 of 11 commit subjects retain the as-authored v3.76 provisional label (pre-merge relabel; no v3.76 tag cut) | — | 2026-07-17 |
| 79-qa-devtest-modes-and-automated-eval-execution | v3.67 | v3.68 | v3.66 → v3.67 → v3.68 | false | 3103304260d6b2b930e2477fa4825a220a61a369 | software-domain-templates@v3.66 + methodology-pack-catalog@v3.67 | Commit-0 + Stage-12-A.5.6 | none | none | — | 2026-07-10 |
| 79-qa-devtest-modes-and-automated-eval-execution | v3.66 | v3.68 | v3.66 → v3.67 → v3.68 | false | 3103304260d6b2b930e2477fa4825a220a61a369 | software-domain-templates@v3.66 + methodology-pack-catalog@v3.67 | Commit-0 + Stage-12-A.5.6 | none | none | — | 2026-07-10 |
| 66-release-identity-and-spec-hardening | v3.37 | v3.38 | v3.37 → v3.38 | false | 27ddc19bcba3d9c112baf864e87ee25fb4ac9c88 | 21-shared-entity-storage-layout@v3.37 | S12 | none | provisional v3.37 re-versioned forward at the Stage-12 pre-merge freeness check (A.5.6c) after the sibling claimed v3.37; no v3.37 tag cut by this release; plan file renamed to v3.38 + D-Version/R1 records updated; the four on-branch commit subjects retain the as-authored `docs(v3.37):` provisional prefix | — | 2026-07-01 |
| 64-hub-autonomy-conformance | v3.31 | v3.32 | v3.28 → v3.29 → v3.30 → v3.31 → v3.32 | true | bdadfae4592fa460ca33a354a5861043ec866338 | v3.28,v3.29,v3.30,v3.31 | S12 | tag-orphaned | v3.31 orphan tag left in place per no-tag-deletion; next release already past it | — | 2026-06-30 |
| 64-hub-autonomy-conformance | v3.30 | v3.32 | v3.28 → v3.29 → v3.30 → v3.31 → v3.32 | false | bdadfae4592fa460ca33a354a5861043ec866338 | v3.28,v3.29,v3.30,v3.31 | S12 | none | v3.31 orphan tag left in place per no-tag-deletion; next release already past it | — | 2026-06-30 |
| 64-hub-autonomy-conformance | v3.29 | v3.32 | v3.28 → v3.29 → v3.30 → v3.31 → v3.32 | false | bdadfae4592fa460ca33a354a5861043ec866338 | v3.28,v3.29,v3.30,v3.31 | S12 | none | v3.31 orphan tag left in place per no-tag-deletion; next release already past it | — | 2026-06-30 |
| 64-hub-autonomy-conformance | v3.28 | v3.32 | v3.28 → v3.29 → v3.30 → v3.31 → v3.32 | false | bdadfae4592fa460ca33a354a5861043ec866338 | v3.28,v3.29,v3.30,v3.31 | S12 | none | v3.31 orphan tag left in place per no-tag-deletion; next release already past it | — | 2026-06-30 |
| 34-terminology-and-controlled-vocabulary | v2.42 | v3.21 | v2.42 → v3.21 | false | 26c32a4e0e1888ab17c99a2de13166249090d7b2 | v3.20-release-corpus-verification-surface@v3.20 | S12 | none | branch + commit messages + PR #2487 title + plan filename retain as-authored v2.42 (no v2.42 tag cut; provisional NAME re-versioned forward at the Stage-12 atomic claim above the v3.20 mainline-spine frontier) | — | 2026-06-29 |
| 17-per-project-processing-orchestration | v2.39 | v2.40 | v2.39 → v2.40 | false | 9b50b403fa5ea5cf5ba11dc42a6f45b3b934dc01 | 60-audit-cadence-and-learning@v2.39 | S12 | none | re-versioned up to v2.40 above the sibling-claimed v2.39 tag (no v2.39 tag cut by this release); branch + commit messages retain as-authored v2.39 | — | 2026-06-29 |
| 69-triage-and-bundling-signals | v2.33 | v2.36 | v2.33 → v2.36 | false | 1a1d51af6f96875f782ce40325a5ba9e231e7643 | 40-initiative-roadmap-vocabulary-and-home@v2.33 | S12 | none | branch + commit messages retain as-authored v2.33 (siblings also held v2.34/v2.35 at the claim instant) | — | 2026-06-28 |
| 12-field-first-intake-enforcement | v2.14 | v2.12 | v2.12 → v2.14 → v2.12 | false | 28860f1c76cc7889a225d1f109b16ed6e185d831 | 71-autonomy-phaseout-foundation@v2.14 | S12 | none | branch + milestone named for provisional v2.12 | — | 2026-06-20 |
| 05-ROLE-sustain-coverage-router | v2.12 | v2.15 | v2.12 → v2.15 | false | b8ce4f3540035a28f8ebfffbadb05ca453c3e5c7 | 12-field-first-intake-enforcement@v2.12 | S12 | none | branch + milestone named for provisional v2.12 | — | 2026-06-20 |
| 05-ROLE-sustain-coverage-router | v2.13 | v2.15 | v2.12 → v2.15 | false | b8ce4f3540035a28f8ebfffbadb05ca453c3e5c7 | 63-finding-disposition-discipline@v2.13 | S12 | none | branch + milestone named for provisional v2.12 | — | 2026-06-20 |
| 05-ROLE-sustain-coverage-router | v2.14 | v2.15 | v2.12 → v2.15 | false | b8ce4f3540035a28f8ebfffbadb05ca453c3e5c7 | 71-autonomy-phaseout-foundation@v2.14 | S12 | none | branch + milestone named for provisional v2.12 | — | 2026-06-20 |
| 71-autonomy-phaseout-foundation | v2.12 | v2.14 | v2.12 → v2.14 | false | 404037103e265f6548fef106f1c38d9ba9694bd8 | 63-finding-disposition-discipline@v2.13 | S12 | none | branch + commit messages retain as-authored v2.12 | — | 2026-06-21 |
| deploy-toolchain-defect-cleanup | v1.20 | v1.22 | v1.20 → v1.21 → v1.22 | false | edb99eb6313f6d991edc7ee0c231c918654c94fb | health-and-raid-determinism@v1.20 | S12 | none | fresh v1.22 branch cut (no abandoned-label retained) | — | 2026-06-14 |
| deploy-toolchain-defect-cleanup | v1.21 | v1.22 | v1.20 → v1.21 → v1.22 | false | edb99eb6313f6d991edc7ee0c231c918654c94fb | governance-as-code-quality-gates@v1.21 | S12 | none | fresh v1.22 branch cut (no abandoned-label retained) | — | 2026-06-14 |
| health-and-raid-determinism | v1.18 | v1.20 | v1.18 → v1.19 → v1.20 | false | 626b9926270216c639b7c7c13727c0648733028f | cross-release-impact-model@v1.18 | S12 | none | branch release/v1.18 + build commits retain v1.18 | — | 2026-06-14 |
| health-and-raid-determinism | v1.19 | v1.20 | v1.18 → v1.19 → v1.20 | false | 626b9926270216c639b7c7c13727c0648733028f | sior-escalation-discipline-across-the-comms-triage-technical@v1.19 | S12 | none | branch release/v1.18 + build commits retain v1.18 | — | 2026-06-14 |
| comms-writer-artifact-generator-anthropic-offload-refactor | v1.15 | v1.17 | v1.15 → v1.17 | false | 79d8827d0fb57f671ad49c0a80acf9e376bc5a55 | platform-self-measurement-and-quality-method@v1.15 | S12 | none | branch + build commits retain as-authored v1.15 | — | 2026-06-14 |
| v1.03-bundle-and-related | v1.03 | unrecoverable | v1.03 → (unknown) | unknown | (unrecoverable) | — | pre-merge | unrecoverable | abandoned artifacts lost (pre-instrumentation) | — | 2026-06-02 |
