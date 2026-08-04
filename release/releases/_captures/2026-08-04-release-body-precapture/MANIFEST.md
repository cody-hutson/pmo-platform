# Release-body pre-capture manifest

Captured (UTC): `2026-08-04T16:08:15Z`

Raw published GitHub Release bodies, captured **before** the § 5.6 re-emit.
GitHub keeps no version history for a Release body, so after a re-emit these
files are the only record of what each public page said beforehand.

`<version>.published.md` is the body **byte-for-byte as GitHub returned it**
(`gh release view <v> --json body --jq .body`) — no transform, no trimming.
Integrity is verified against the companion `SHA256SUMS` (see § Verification).

The re-emit changes **only** the body. Title / createdAt / publishedAt /
target are recorded anyway: they cost nothing now and are unrecoverable later.

| Version | Bytes | Lines | SHA-256 | Drift at capture | Title | Created (UTC) | Published (UTC) | Target |
|---|---:|---:|---|---|---|---|---|---|
| `v3.67` | 6791 | 35 | `af8f39d5912aca1fe1a9ecb5b85f76b27f3c4d5129d6875d8cc5ff817d6d8fdb` | **DRIFT** (exit 1) | v3.67 — Intake now adapts to your project's methodology | 2026-07-10T19:46:17Z | 2026-07-10T20:03:59Z | `main` |
| `v3.69.1` | 1162 | 10 | `0f2b8d2342accad09b7111e4d129dd4aa9cf8238fddf31c8d1cf3d0a23aca7d0` | **DRIFT** (exit 1) | v3.69.1 — Security patch (GHSA-9cjm, GHSA-rw36) | 2026-07-11T22:42:35Z | 2026-07-11T22:42:37Z | `main` |
| `v3.72` | 929 | 10 | `840c1854575d07b889fc98eda7e8cf407c66bc1e061c1263ddd2bc6dfdc58a38` | **DRIFT** (exit 1) | v3.72 — The release orchestrator is safer and finishes cleaner | 2026-07-12T16:18:03Z | 2026-07-12T17:09:01Z | `main` |
| `v3.73` | 1568 | 14 | `093931ecb3e0fc404d112240a674d7edcc6bb8c6d2c947fdd6a2d3b5add5d836` | **DRIFT** (exit 1) | v3.73 — Security patch: hardened hooks and a safer eval-review tool | 2026-07-12T21:11:10Z | 2026-07-12T21:11:22Z | `main` |
| `v3.73.1` | 2077 | 24 | `db6f7fe33adc7028eae5669a15fa8912e4bdc50c8db71229740f3b31b1ddf6c6` | **DRIFT** (exit 1) | v3.73.1 — Security-hook fixes now reach workspaces you already installed | 2026-07-12T23:39:49Z | 2026-07-12T23:40:20Z | `main` |
| `v3.77` | 482 | 5 | `6e6d4a2d8c90d1a9be03214b9fb64024041b364c5ba844402a3d3d6ee613433c` | **DRIFT** (exit 1) | v3.77 — skill-hardening | 2026-07-17T04:58:05Z | 2026-07-17T05:15:40Z | `main` |
| `v3.84` | 7145 | 47 | `f55facc0c4b9d021cfdc1a682d3adbe9365c40b3282e7f069b82cccda2118d9f` | **DRIFT** (exit 1) | v3.84 — Two releases can now finish at the same time without tripping over each other | 2026-07-24T00:36:08Z | 2026-07-24T00:52:13Z | `1dd1ca01a8dbf471f389bdd8a388775b5899e4ea` |
| `v3.87` | 8005 | 74 | `1d9ab43037639948a616b865cbe666b66baa4d5403f7ac2149679cc4ac54cf2c` | **DRIFT** (exit 1) | v3.87 — design-artifact-backfill | 2026-07-25T01:31:54Z | 2026-07-25T02:01:33Z | `27c7d5efc0259946d5990e7706bbbcd41f64cd3d` |
| `v3.88` | 3283 | 32 | `147fd46c50c7b8d9a6fcad9e5dd9549b86cb93d7072e17203e074f58d5fd7aa3` | **DRIFT** (exit 1) | v3.88 — Deploy/tooling defect cleanup + XSS-sink hardening | 2026-07-25T01:54:54Z | 2026-07-25T02:09:09Z | `3368d98ebf4a2b822e2ebfb68a20aa07b486eb77` |
| `v3.91` | 6992 | 63 | `999f14a1b5a7fec47d55de5bce2ce86aca1c7945b8291406e22d286e073cc07d` | **DRIFT** (exit 1) | v3.91 — Cross-platform install foundation | 2026-07-25T16:44:01Z | 2026-07-25T17:10:47Z | `main` |
| `v3.95` | 11164 | 99 | `f64cea811f3e25fb2c0ec2d5b175d01d9b54bfda584551b2886c5a238be90258` | **DRIFT** (exit 1) | v3.95 — Set the platform's runtime posture in config — and keep it across updates | 2026-07-26T07:07:05Z | 2026-07-26T07:35:54Z | `main` |

## Verification

```bash
cd release/releases/_captures/2026-08-04-release-body-precapture && shasum -a 256 -c SHA256SUMS
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
