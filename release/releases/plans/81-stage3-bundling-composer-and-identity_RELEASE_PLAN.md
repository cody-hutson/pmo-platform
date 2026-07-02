# Release Plan — 81-stage3-bundling-composer-and-identity (milestone #166)

**Status:** APPROVED at plan-approval gate 2026-07-01 (release-hub Mode O, Procedure 0).
**Version:** provisional / **rule-determined at Stage 12**. The earlier provisional (v3.51) was **published by a parallel release during this run**; in-flight branches also claim v3.52/v3.53. The authoritative version binds at **Stage 12 B3** via `claim-version.sh` (re-anchored against the then-current mainline) — currently next-free ≈ **v3.54**. This branch + plan are intentionally **version-agnostic** to avoid version-branch collision.
**Release Class:** novel · Standard engagement `[ASSUMPTION – CONFIRM]`.
**Concurrency:** P0 fully-serial (operator-approved). **Build order:** #25 → #30 → #52 → #415.

## (a) Release Outcome Statement
Stage 3 Bundling becomes a self-contained, self-triggering composer: (a) detects when to bundle via a queue-depth monitor (#30); (b) derives milestone sequence from the dep graph, feeding the live G3-07 gate (#52); (c) carries a bundle-composer identity distinct from Stage-4 planning (#25); (d) declares each release's version-identity mode — versioned/versionless — reconciled against the version-grammar SSOT (#415).

## (b) Bundle + sizes — 22 pts (band 15–25 ✓; doctrine map XS1/S2/M4/L8/XL16)
| Issue | Scope | Size | Pts |
|---|---|---|---|
| #52 | milestone-position derivation tool | L | 8 |
| #415 | version-or-versionless identity — **core only** (enforcement fissioned to #3016) | L | 8 |
| #30 | Stage-3 queue-depth monitor | M | 4 |
| #25 | bundle-composer decision-record (ADR-019) | S | 2 |
| | | **Total** | **22** |

## (c) Dependency graph + build order
Zero hard in-bundle edges (only #415→#3016 exits the bundle). CPM chain length 0. Build order (P0 fully-serial): **#25 → #30 → #52 → #415**.

## (d) Serialization + scope-lock (ratified 2026-07-01 — see planning sub-task #3062)
- **deploy.sh --check numbers (highest live = 51):** #52 → **Check 52**, #30 → **Check 53**.
- **Stale `deploy.sh:1967` registry repair:** owned by **#30** (higher-number card, one edit); **preserve dormant Checks 11 & 30 verbatim**.
- **#415 conditions:** adopt shipped `version-less` spelling (or equivalence note); scope AC4 verification to `version-grammar.sh` only (a live `validate_version()` exists in `automated-closeout.sh:279`).
- **stage-03-bundle.md** #415 (§4/§6/§7) vs #30 (A7/T1 region ~line 203) — line-disjoint; second-to-land rebases.

## (e) D-Gate decisions (RESOLVED)
- D-Concurrency Posture → **P0 fully-serial**. D-#25 → **BUILD** the ADR-019 record. D-Version → **rule-determined** (re-anchors at Stage 12).

## (f) Risk register (top)
R1 deploy.sh check-number collision → #52=52 / #30=53 · MOD. R4 versionless↔version-grammar empty-string trap → AC4 forbids feeding empty to the live gate `version_canonical` · MOD. R3 `versionless`/`version-less` spelling drift · HIGH. R5 #52 self-test fixture load-bearing (idempotency over prose + Kahn's orientation) · MED. R6 #30 warn-noise (queue=29≥5, fires first run) → actionable summary + enforce-flip plan · MED. R7 #3016 covers closeout `--version` entry-gate · LOW. R8 body-parse dep completeness (accepted residual).

## (g) Quota Budget (Checkpoint A)
PASS (advisory). Checkpoint B re-gates each runtime wave.

## (i) Stage-applicability matrix
| Card | S5 | S6 | S7 | S8 |
|---|---|---|---|---|
| #52 | Yes | Yes | Yes | Yes |
| #415 | Yes | Yes | Yes | light |
| #30 | light | Yes | Yes | light |
| #25 | SKIP | Yes | light | SKIP |
