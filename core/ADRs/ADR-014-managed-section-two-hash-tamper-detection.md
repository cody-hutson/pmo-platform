---
title: ADR-014 — Two-hash separation for managed-section tamper detection (UPDATE cluster)
status: Accepted
date: 2026-06-03
deciders: "operator + Stage 5 Solutioning (managed-section tamper detection) + Stage 5 Collective Review scope-lock"
tags: [update, composition-surface, tamper-detection, security, hashing, back-compat]
source_observations:
  - Stage 5 Solutioning (managed-section tamper compares SOURCE sha, not installed content) — the source-vs-stored gate never inspects the installed body; an in-fence edit changes neither side, so a tampered security allowlist persists silently and the promised .backup-tampered- is never created
  - Stage 5 Solutioning — the spec was internally self-contradictory (§2.4 source-hash vs §2.5/§3.2 installed-content); a naive "hash installed body vs stored source-SHA" would false-positive on every token-bearing file every run
  - Stage 5 Collective Review scope-lock (2026-06-03) — two-hash design (new installed_sha marker via a compose.py subcommand); 6 gate-blocking Stage 7 DT cases; reconcile the spec contradiction in the same change
  - Source finding lineage: a hand-edit of api.github.com -> api.TAMPERED inside the egress-allowlist MANAGED fence survived ./update.sh ("0 regenerated"), no backup dir produced
---

# ADR-014 — Two-hash separation for managed-section tamper detection

## Status

Accepted at the Stage 5 Collective Review scope-lock (2026-06-03);
ratified into the release branch at the
UPDATE-cluster Engineering commit. This is the release's one security-relevant
(R-SEC) issue: the managed-section tamper-detection + backup contract that
`docs/UPDATE.md §6.3` and `composition-surface-spec.md §2.5` promised but the
code never implemented.

## Context

Composition-surface runtime files carry a MANAGED SECTION fence whose body is
regenerated from a repo source template + `operator.toml` token substitution,
plus an OPERATOR ADDITIONS section preserved verbatim across updates. The fence
recorded one hash, `managed_sha` = SHA-256 of the **source template**
(pre-substitution), written by `core/deploy/compose.py` and read by `update.sh`
Phase 3.

Two defects converged:

1. **The gate compared source-vs-stored, never the installed body.**
   `update.sh` skipped regeneration when `source_sha == stored_managed_sha`. The
   stored value IS the source-template hash, so a hand-edit *inside* the MANAGED
   fence (e.g. an egress/exec allowlist — a security boundary) changed neither
   the source nor the stored hash. The file was reported "unchanged", no
   `.backup-tampered-` was created, and the tampered content persisted until the
   *source template* happened to change. Reproduced empirically:
   `api.github.com → api.TAMPERED` inside the egress-allowlist fence survived
   `./update.sh` (`0 regenerated`), no backup directory.

2. **One hash cannot serve both roles.** For the three token-bearing files
   (egress / fs-boundary / script-execution allowlists carry `[OPERATOR_GITHUB]`
   in their managed body), the **installed** body is token-substituted and
   therefore can never equal the source-template hash — by design, with no
   tampering. A naive "hash the installed body, compare to the stored
   source-SHA" detector would false-positive on every token-bearing file on
   every run — a false-alarm storm worse than the silent gap. The spec encoded
   this confusion directly: §2.4 said `managed_sha` was the pre-substitution
   source hash (matching the code), while §2.5 / §3.2 said tamper detection
   compared the computed managed-section *content* against `managed_sha`. The
   two were mutually exclusive.

Tamper detection needs the **post-substitution** anchor; the regeneration
trigger needs the **pre-substitution** anchor. They are two different hashes,
and the bug was conflating them.

Additionally, `update.sh`'s Phase 3 local variable was named `installed_sha` but
held the **`managed_sha`** value — a name that became actively misleading once a
real `installed_sha` existed.

## Decision

Introduce a **second marker**, `# installed_sha:`, and separate the two roles.

### A. Two hashes, two roles

- `managed_sha` keeps its existing role: SHA-256 of the source template
  (pre-substitution); the **regeneration trigger** (source changed ⇒ regenerate).
- `installed_sha` (new): SHA-256 of the **post-substitution installed managed
  body** — the exact bytes `compose.py` writes as the fence body, with the three
  marker lines and the OPERATOR ADDITIONS section excluded and the trailing
  newline stripped (`content.rstrip()` domain). This is the **tamper anchor**:
  on each run `update.sh` re-hashes the live managed body and compares it to the
  stored `installed_sha`; a mismatch means the operator hand-edited inside the
  fence.

The fence marker order is fixed: `managed_sha` → `installed_sha` → `managed_at`.
The markdown-form files use the identical `<!-- installed_sha: <hex> -->`
wrapper as the other two markers.

### B. Single-sourced hash domain (no writer/reader drift)

The byte-domain that gets hashed is defined **once**, in
`compose.py:_extract_managed_body`, and consumed by both:

- the **writer** (`write_managed_file`), to decide what `installed_sha` covers, and
- the **reader**, a new `compose.py installed-sha --target <path>` subcommand
  (`update.sh` calls it via `lib_compose_installed_body_sha` in
  `lib-composition.sh`).

Because both callers share one extraction, the hash a writer stores and the hash
a reader computes cannot drift — the obvious latent regression of a parallel
hand-rolled awk/sed extractor is eliminated by construction. The round-trip
invariant (`installed_sha_of(freshly_written_file) == stored installed_sha`) is
asserted in `core/deploy/tests/test_compose.py`.

### C. Detection, backup, regeneration (independent of the source-SHA skip)

`update.sh` Phase 3 evaluates tamper **before** the source-SHA `unchanged` skip,
so it fires precisely in the case the skip used to swallow (source unchanged,
body tampered):

```
if stored_installed_sha != "" and live_body_sha != stored_installed_sha:
    DRY_RUN  -> report "would back up + regenerate (tampered)"; count regenerated
    else     -> mkdir ${WORKSPACE_ROOT}/.backup-tampered-<utc-ts>;
                cp target into it; warn; lib_compose_regen; count regenerated
elif not FORCE_REGEN and source_sha == stored_managed_sha:
    unchanged
else:
    existing pre-update backup + regen path
```

The tamper backup root (`${WORKSPACE_ROOT}/.backup-tampered-<ts>/`) is distinct
from the existing `.backup-pre-update-<ts>` convention. The backup is the
load-bearing safety property (the dpkg `.dpkg-dist` precedent): an operator who
hand-edited a managed allowlist gets their edit recoverable rather than silently
overwritten. The misnamed `installed_sha` local was renamed to
`stored_managed_sha`.

### D. Back-compat — missing anchor ⇒ "unknown, not tampered"

Files installed before this marker existed carry no `installed_sha` line. The
detector treats a missing/empty `installed_sha` as "unknown, not tampered" (no
backup, no false alarm). The anchor self-heals: it is back-filled the next time
the file is legitimately regenerated (source change or `--force-regen`). No
separate migration step — `./update.sh --force-regen` once after upgrading
back-fills all anchors immediately. This avoids a false-positive storm on every
existing install the moment the fix ships.

The spec's §2.4 ⇄ §2.5/§3.2 contradiction is reconciled in the same change:
§2.4 gains an `installed_sha` row and a sharpened `managed_sha` row; §2.5 anchors
tamper on `installed_sha`; §3.2 splits the integrity check out of the
"If SHAs differ" branch into its own always-evaluated step; `docs/UPDATE.md`
§3.2/§4/§6.3 are updated to describe the now-true behavior + the `--force-regen`
back-fill.

## Consequences

**Positive:**
- The managed-section tamper gap (R-SEC) is closed: a hand-edited security
  allowlist is detected, backed up, and regenerated on the next `update.sh`,
  even when the source template is unchanged.
- No false positives on legitimate token substitution — the post-substitution
  anchor is the comparison, so token-bearing allowlists run clean every time
  (the original-bug class is impossible by construction).
- Writer/reader hash-domain drift is structurally impossible (one extraction,
  two callers).
- The docs match the code; the spec is internally consistent again.

**Negative / costs:**
- The on-disk fence format gains one line. The only readers are `compose.py`
  (rewrites the whole fence) and `update.sh` (grep-by-literal-prefix,
  offset-independent), and §2.4 mandates grep-by-literal — so no offset-based
  reader breaks. The marker line is inert to any pre-fix reader.
- Each Phase 3 iteration now shells out to `compose.py installed-sha` to compute
  the live body hash (one extra `python3` per surveyed file). Acceptable for a
  17-file survey run on demand.
- `.backup-tampered-` directories share the unbounded-growth limitation already
  tracked for `.backup-pre-update-` / hook logs (log-rotation deferred); tamper
  backups inherit the same deferral — noted, out of this change's scope.

## Alternatives Considered

- **Docs-align (rewrite §2.4/§2.5/§3.2 + UPDATE.md §6.3 to source-hash-only
  behavior; delete the tamper/backup promise)** — REJECTED. Documents the
  vulnerability instead of closing it; a tampered egress/exec security boundary
  would persist silently until the source template changed. Unacceptable for the
  release's one security-relevant issue.
- **Detect via re-derivation each run, no new marker (re-run substitution from
  current source + toml, hash, compare to live body)** — VIABLE but couples
  detection to source currency (a legitimate source change must be classed
  regen-not-tamper) and re-substitutes every run. The stored `installed_sha`
  anchor makes the per-run check a deterministic `hash(body) == stored` with no
  re-substitution and makes the states orthogonal/individually testable.
- **Immutable fence (chmod / re-deny via hook)** — REJECTED for this issue:
  prevention, not detection; does not satisfy the documented backup-on-tamper
  contract; larger surface. A candidate future hardening complement, not a
  substitute.

## Reversibility

CHEAP — `git revert` restores prior behavior. The new marker line is inert to
existing readers (grep-by-literal, offset-independent); back-compat is handled
by "missing ⇒ not tampered" so a revert leaves no half-state. No `operator.toml`
schema change, no governance or platform-state coupling. The change is confined
to `compose.py` (one write + one subcommand + one shared extractor), `update.sh`
(one Phase-3 branch + a rename), `lib-composition.sh` (one wrapper), and the
spec/UPDATE docs.

**Confidence:** HIGH — the two-hash separation was verified end-to-end against
the real `./update.sh` in a sandbox: tamper-injection fired the WARN + created
`.backup-tampered-<ts>/` with the tampered bytes + regenerated the file;
token-bearing clean runs produced no false tamper backup across repeated runs;
`--dry-run` reported without writing; the pre-marker back-compat fixture produced
no false alarm and `--force-regen` back-filled the anchor.

## Composition with other ADRs

- ADR-013 (detect_install_path session-resolution + COWORK_AVAILABLE seam) — the
  sibling UPDATE/SESSION clusters of the same install-blockers
  release; both land on the install/update tooling under the single-branch
  topology.
- ADR-008 (deploy.sh per-module array design) — the same `set -euo pipefail`
  discipline applies to the new Phase-3 branch (no bare failing command
  substitution in an assignment; `|| true`-guarded grep for the optional
  `installed_sha` line so a pre-marker install does not abort under `set -e`).
- ADR-010 (secrets-handling policy substrate) — closing the managed-section
  tamper gap hardens the security posture of the egress/exec allowlists for the
  public flip.
