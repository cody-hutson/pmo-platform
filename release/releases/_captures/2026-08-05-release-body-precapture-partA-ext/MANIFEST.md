# Release-body pre-capture manifest

Captured (UTC): `2026-08-05T13:32:31Z`

Raw published GitHub Release bodies, captured **before** the § 5.6 re-emit.
GitHub keeps no version history for a Release body, so after a re-emit these
files are the only record of what each public page said beforehand.

`<version>.published.txt` is the body **byte-for-byte as GitHub returned it**
(`gh release view <v> --json body --jq .body`) — no transform, no trimming.
Integrity is verified against the companion `SHA256SUMS` (see § Verification).

The re-emit changes **only** the body. Title / createdAt / publishedAt /
target are recorded anyway: they cost nothing now and are unrecoverable later.

| Version | Bytes | Lines | SHA-256 | Drift at capture | Title | Created (UTC) | Published (UTC) | Target |
|---|---:|---:|---|---|---|---|---|---|
| `v1.07` | 8041 | 55 | `a3efbbfc6b23b13201b714baa08c0de53afdfbca2f8dfdefebca36bfabcfca7e` | **DRIFT** (exit 1) | v1.07 — declarative-workitem-type-model | 2026-06-07T23:22:59Z | 2026-06-07T23:41:14Z | `main` |
| `v1.11` | 7376 | 59 | `c51aa8c0929d0d64145ef58c5ad84b68d52d92fdf8f7058cdbfedac83e17228b` | **DRIFT** (exit 1) | v1.11 — cleanup-orphan-state reliability | 2026-06-12T22:33:21Z | 2026-06-12T22:39:18Z | `38f97d314c9499104f49d43b0c0345d7ed99921b` |
| `v1.13` | 10662 | 63 | `0790a63a005dc4e59d8a71d62ead91e2f8dbdc516f3eaca1ffb415f1b650d301` | **DRIFT** (exit 1) | v1.13 — runtime test-gating substrate, machine-readable test-run surface, and standing regression suite | 2026-06-13T20:56:44Z | 2026-06-13T21:11:50Z | `main` |
| `v1.16` | 8992 | 53 | `1276d783fe91ac3179d01d577b8f3307a992ac774699a7319047b8ad4fd40437` | **DRIFT** (exit 1) | v1.16 — Delivery-capacity and lifecycle gating | 2026-06-14T01:45:33Z | 2026-06-20T15:24:27Z | `main` |
| `v1.19` | 5858 | 40 | `461adbc18c75d3fc0efbc3511515d0e7bce6b03fbc491d9cd42611abec229290` | **DRIFT** (exit 1) | v1.19 — SIOR escalation discipline | 2026-06-14T08:24:23Z | 2026-06-14T08:51:58Z | `main` |
| `v1.20` | 8519 | 45 | `8417824b9585f3dbaf717abf8eb67b0df2dfc55483295a0689ea85453674830b` | **DRIFT** (exit 1) | v1.20 — Project health and RAID escalation are now consistent and predictable | 2026-06-14T08:41:33Z | 2026-06-14T09:00:49Z | `626b9926270216c639b7c7c13727c0648733028f` |
| `v1.21` | 7170 | 42 | `ab6d649910b59177dd00af67a58e283d16a3f82e7ad804967a95239328f7d36c` | **DRIFT** (exit 1) | v1.21 — governance-as-code quality gates | 2026-06-14T19:00:45Z | 2026-06-14T19:12:01Z | `62595481ef14bb4f37dd841809f5ca8b1568ce45` |
| `v1.22` | 10411 | 50 | `592674b5b81c5099c28792f56927f62e825f021c1b1ccaed8b7cabc8e5b4a42a` | **DRIFT** (exit 1) | v1.22 — deploy-toolchain-defect-cleanup | 2026-06-14T19:38:27Z | 2026-06-14T20:08:59Z | `edb99eb6313f6d991edc7ee0c231c918654c94fb` |
| `v1.23` | 9208 | 46 | `dcd46e5a57695699fbc5fe563a3fc8458f65098eb1b53666b1b24d307e1d41c4` | **DRIFT** (exit 1) | v1.23 — change-management methodology toolkit + intake & sub-task standards | 2026-06-14T19:48:06Z | 2026-06-14T20:25:19Z | `main` |
| `v1.24` | 7533 | 44 | `f8137ed4cbccb699ccd6cac5690f48e5d9851e7d844b808a642b7fe6d2addc83` | **DRIFT** (exit 1) | v1.24 — Triage backlog-hygiene checks that silently returned nothing are fixed | 2026-06-14T20:27:41Z | 2026-06-14T20:41:41Z | `10977af642da65c1bbb2b35332ff3cba70cf5bb4` |
| `v2.04` | 7237 | 46 | `003257c8813ca24967a8fa806c68a82373915724ff33d001dbf295f1c8ca9d4e` | **DRIFT** (exit 1) | v2.04 — Close-out registers (ADR-032 design + combined register template) | 2026-06-20T20:01:38Z | 2026-06-20T20:06:43Z | `cc10af42dfb2d4771b74107513c0e9cdd050486b` |
| `v2.09` | 7559 | 48 | `4ff5689751a678bace5f6b6ec5d3594a14fa2a1c239ecb03fd5bcbd851f4d05b` | **DRIFT** (exit 1) | v2.09 — Deploy and release tooling health: checks that were silently passing now actually run | 2026-06-20T20:42:44Z | 2026-06-20T21:21:19Z | `main` |
| `v2.14` | 4818 | 44 | `e03fd0e07cd560f9e62d75480091103c48413a075b544e9fc37c77f069d3bc56` | **DRIFT** (exit 1) | v2.14 — autonomy-phaseout-foundation | 2026-06-21T01:30:48Z | 2026-06-21T02:10:29Z | `main` |
| `v2.15` | 7514 | 59 | `0253c8a1204eb2c6ba31db8ccea1b442ff3f88932abcbc9d4ec4a026ebefc531` | **DRIFT** (exit 1) | v2.15 — The role-Specialist suite is now GA — ask for a role, get routed to it | 2026-06-21T03:44:34Z | 2026-06-21T04:04:05Z | `main` |
| `v2.18` | 9243 | 54 | `47df16f52c799bd04200a637b825d3dd1599d59a6a10ab10cf46586540291f5e` | **DRIFT** (exit 1) | v2.18 — Hybrid projects can declare two methodologies; co-management decoupled into generic dual-framing | 2026-06-22T00:09:37Z | 2026-06-22T01:40:29Z | `main` |
| `v2.22` | 5745 | 44 | `f04904ddd8f1b74b8e88976136aa4c2ba7690930dcbd57e3f097212ca3cbc642` | **DRIFT** (exit 1) | v2.22 — One canonical meeting agenda and recap format, plus a facilitation-techniques library | 2026-06-25T16:07:02Z | 2026-06-26T18:10:10Z | `main` |
| `v2.25` | 7204 | 47 | `ece1c865cea8674a11b5676fe00128ad81c27c863cf332f6d6aa7218d52b3241` | **DRIFT** (exit 1) | v2.25 — Orchestration disciplines move into the reference the platform reads at runtime | 2026-06-26T14:18:15Z | 2026-06-26T18:10:11Z | `main` |
| `v2.26` | 4035 | 40 | `39c08b26133cd8278ddc8b10eed92b72d9eb8318a616db30f876e76ff770507b` | **DRIFT** (exit 1) | v2.26 — people-graph activation | 2026-06-26T18:08:11Z | 2026-06-26T18:09:39Z | `main` |

## Verification

```bash
cd release/releases/_captures/2026-08-05-release-body-precapture-partA-ext && shasum -a 256 -c SHA256SUMS
```

`SHA256SUMS` is emitted in the canonical `<sha>  <filename>` format, so
verification is a single `shasum -c` with no parsing step. (An earlier
revision of this tool told the reader to re-derive the digests by
field-splitting the table above on backticks; that snippet silently picked
up the **Target** column instead of the SHA column and reported spurious
mismatches. A verification command that does not verify is worse than none,
because it reads as evidence.)

## Provenance

Written by `release/tools/capture-release-bodies.sh`, which **refuses to
overwrite an existing capture** at both the directory and the file level.
A re-run after a re-emit would otherwise replace these pre-repair bodies with
post-repair ones and leave an artifact that still looked complete.

## Relationship to the 2026-08-04 capture — this directory is HALF of one set

The Part A pre-capture is **29 bodies across two sibling directories**:

| Directory | Bodies | Scope |
|---|---:|---|
| `../2026-08-04-release-body-precapture/` | 11 | the originally-confirmed drifted set |
| `2026-08-05-release-body-precapture-partA-ext/` (this one) | 18 | the mechanical link-depth additions |

**Why two directories rather than one.** The 18 were *not* appended to the
2026-08-04 directory, because appending is not possible: the capture tool's
directory-level guard aborts (exit 1) the moment the destination holds any
`*.published.txt`, and there is no `--force`. That refusal is the tool working as
designed, not an obstacle routed around — its own header prescribes this exact
resolution ("A genuinely new capture goes in a NEW dated directory … it preserves
the earlier capture, which is always the correct outcome"). Had the guard been
bypassed, the run would additionally have **truncated** the 2026-08-04
`SHA256SUMS` and `MANIFEST.md`, destroying the integrity record for the original
11 while leaving a directory that still looked complete.

A reader verifying the full set runs `shasum -a 256 -c SHA256SUMS` in **each**
directory; neither manifest covers the other's files.

## Drift character of these 18 (measured, not assumed)

All 18 published bodies drifted from their in-repo note by the **same mechanical
cause**: v4.06's archival sweep foldered 110 notes into major-version buckets and
correctly rewrote their in-repo relative links from `../` to `../../`, while the
already-published Release bodies kept the pre-foldering depth. Measured across
all 18 (denominator 18): every published body holds `](../RELEASE_LOG.md` (18/18)
and none holds `](../../RELEASE_LOG.md` (0/18); every origin/main note holds
`](../../RELEASE_LOG.md` (18/18) and none holds `](../RELEASE_LOG.md` (0/18).

**16 of 18** differ by that link token alone. **2 of 18 — `v1.22` and `v2.26` —
carry one additional delta**: a leading blank line present in the
frontmatter-stripped note and absent from the published body (`diff` hunk `1d0`).
That is whitespace, not content; both remain mechanical re-emits. It is recorded
here because "a single token" is true of 16 of these files, not of all 18, and a
Stage 12 re-emit that assumes uniformity would be reasoning from a false premise.
