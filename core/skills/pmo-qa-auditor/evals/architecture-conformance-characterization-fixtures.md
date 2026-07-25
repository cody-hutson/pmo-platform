<!-- reference-durability: allow-link -->
# Mode I Characterization Fixtures — As-Built Architecture-Conformance Audit

```yaml
labeled_by: Stage-6 Engineering session (candidate labels)
label_date: 2026-07-25
independence: PENDING — candidate labels authored at Stage 6; independent
  adjudication runs at the Stage-7 DT gate (the DT session authored neither the
  rubric nor the mode text). Ground truth is set on that concurrence at the
  Stage-9 gate; until then these are candidate labels.
```

Characterization fixtures, NOT κ-calibrated — regression-pinning for Mode I's
classification, severity-banding, fragmentation-counting, and evidence-bar
behavior (the ≥30-item calibration floor governs gating judges, which these are
not; per the eval-writer discipline). Acceptance per family: classification
**≥4/5** ground-truth match · severity-banding **exact** on the boundary set ·
**fragmentation exact** (one finding per fragmented group + zero issues) ·
evidence-bar **exact**.

**Durability note:** fixture inputs cite work items by TITLE + live search
procedure, never by number — numbers rot on renumber; titles + procedures
survive. Live-resolved evidence inputs use `LIVE:` tokens the self-test resolves
at run time.

**Seeding note (load-bearing — read before the fragmentation family).** The
release record carries a delivered item's identity + mechanism prose, NOT which
architecture each delivery followed (mode-spec §2 stated limitation). The
fragmentation family therefore runs on a **seeded fixture that supplies the
architecture-followed datum explicitly** — so it tests the deterministic
dedup/counting half ("two divergent deliveries under one key → exactly one
finding") in isolation from the non-deterministic inference the release record
cannot support. These fixtures validate **counting + zero-auto-file**, never the
claim "fragmentation detection is deterministic from the release record."

## Family 1 — Classification (5 fixtures; judgment; ≥4/5)

Each fixture: the classifier receives a seeded delivered-item record + its resolvable
baseline, runs the §3 baseline-mapping + §4a scoring, and must land on the ground-truth
classification (conformance-drift / conformant / no-governing-baseline).

### F-CLS-01 — conformance-drift (ADR baseline, PRIMARY)
- **Input (delivered item):** version `vX`, touched a skill whose capability is governed by a
  resolvable ADR; mechanism prose shows the delivery adopted the choice the ADR decided
  **against**.
- **Baseline (seeded):** the governing ADR (`LIVE:` resolve by title) — decision contradicted.
- **Expected output:** classification **conformance-drift** · dim-1 score 1 · severity per §3
  banding · baseline confidence HIGH (ADR citable) · evidence = ADR `path:line` + delivering commit.
- **Ground-truth label (candidate):** conformance-drift.

### F-CLS-02 — conformant (chain baseline, SECONDARY)
- **Input:** version `vX`, a delivery mapping to a management chain; mechanism prose honors the
  chain's governing data model + flow + gate.
- **Baseline (seeded):** the mapped chain (by chain name) in `cross-chain-architecture-map.md`.
- **Expected output:** classification **conformant** · dims 2–4 score 4 · no finding row (recorded).
- **Ground-truth label (candidate):** conformant.

### F-CLS-03 — no-governing-baseline (coverage signal, load-bearing surface)
- **Input:** version `vX`, a delivery touching an architecture-load-bearing surface (a schema)
  with no resolvable ADR and no chain mapping.
- **Baseline (seeded):** none resolves.
- **Expected output:** classification **no-governing-baseline** · severity capped MEDIUM ·
  tagged `coverage-signal` · **aggregated into the single `## Coverage Gap` row**, not a
  standalone finding.
- **Ground-truth label (candidate):** no-governing-baseline.

### F-CLS-04 — no-governing-baseline SUPPRESSED (non-load-bearing surface)
- **Input:** version `vX`, a routine doc-typo delivery, no architectural surface, no ADR/chain.
- **Baseline (seeded):** none resolves; surface is NOT load-bearing.
- **Expected output:** **no coverage-gap row at all** (§5 load-bearing gate — the volume control
  fires the signal only for load-bearing surfaces).
- **Ground-truth label (candidate):** suppressed (no finding, no coverage-gap entry).

### F-CLS-05 — conformance-drift, PARTIAL (dim score 2)
- **Input:** version `vX`, a delivery honoring most of a governing ADR but diverging on one
  sub-decision.
- **Baseline (seeded):** the governing ADR.
- **Expected output:** classification **conformance-drift** · dim-1 score 2 (partial) · severity
  HIGH iff load-bearing else MEDIUM.
- **Ground-truth label (candidate):** conformance-drift (partial).

## Family 2 — Severity-banding + orthogonality cell (6 fixtures; deterministic; exact)

Maps a `(dimension score, blast radius, baseline confidence)` triple to `(severity, confidence
tag)` per rubric §3. **The orthogonality cell is the load-bearing one:** low baseline confidence
must NEVER lower a high severity.

| ID | dim score | blast radius | baseline confidence | Expected severity | Expected confidence tag |
|---|---|---|---|---|---|
| F-SEV-01 | 1 | governed chain / ADR-load-bearing | HIGH | CRITICAL | HIGH |
| F-SEV-02 | 1 | single skill/doc | HIGH | HIGH | HIGH |
| F-SEV-03 | 2 | load-bearing | HIGH | HIGH | HIGH |
| F-SEV-04 | 2 | single non-load-bearing | MEDIUM | HIGH | MEDIUM tag |
| F-SEV-05 (orthogonality) | 1 | load-bearing | **LOW** | **CRITICAL** (NOT demoted) | **LOW** |
| F-SEV-06 (no-baseline cap) | n/a (no baseline) | load-bearing | LOW | **MEDIUM (capped)** | LOW · `coverage-signal` |

**F-SEV-05 is the F1 regression pin:** a genuine score-1 divergence on a load-bearing surface
is CRITICAL **even though** its baseline mapping is LOW-confidence — it surfaces as
`CRITICAL · confidence: LOW`, never diluted into MEDIUM. **F-SEV-06** is the distinct no-baseline
class cap (MEDIUM severity), which applies ONLY to the no-baseline class — it must not be
confused with F-SEV-05's baseline-EXISTS-but-LOW-confidence case.

## Family 3 — Fragmentation (the behavioral fixture; SEEDED; exact)

### F-FRAG-01 — two divergent deliveries → exactly one finding + zero issues (AC-4 / AC-8)
- **Seeded input (architecture datum supplied explicitly):**
  - Release `vX` delivers capability **K** citing architecture **α** (a specific ADR).
  - Release `vY` (`Y > X`) delivers the same capability **K** citing a **divergent** architecture
    **β**, with no reconciliation to α.
  - Both records share the capability key **K**; both cite an architecture (so the divergence is
    citable — the seeding condition).
- **Expected output:**
  - **Exactly ONE** `cross-release-fragmentation` finding for group K (not zero, not two) —
    tagged `detection: candidate (ADR-citation-bounded)`.
  - The `## Fragmentation Groups` table lists K once, with members `{vX→α, vY→β}`.
  - **ZERO GitHub issues created** — the run is report-only; the finding lands only in the
    findings-register + an `issue-drafts/NNN-*.md` observation, never `gh issue create`.
- **Ground-truth label (candidate):** one finding · zero issues.
- **Adjudication note:** this is the AC-4 "seeded fixture of two divergent deliveries yields
  exactly one fragmentation finding" AND the AC-8 "creates zero new GitHub issues." Deterministic
  because the architecture datum is seeded — the dedup/counting is exact.

### F-FRAG-02 — single delivery under a key → zero fragmentation findings
- **Seeded input:** only release `vX` delivers capability **K** (no sibling under K).
- **Expected output:** **zero** fragmentation findings for K (nothing to compare — dim-5 score 3,
  "single delivery under the key").
- **Ground-truth label (candidate):** zero findings.

### F-FRAG-03 — divergence among un-ADR'd members → recorded as unknown, NOT counted conformant
- **Seeded input:** two deliveries under key **K**, neither citing an architecture (both un-ADR'd);
  their architecture-followed is **unknown**.
- **Expected output:** **no** fragmentation finding fires (the divergence is not citable) AND the
  members are **recorded as `architecture-followed: unknown`** in the group table — **not** silently
  counted as conformant. The SUMMARY's confidence-bound statement covers this case.
- **Ground-truth label (candidate):** no finding · members flagged unknown (the honest-heuristic bound).

## Family 4 — Evidence-bar (deterministic; exact)

Reuses the CF-1..CF-4 forms (mode-spec §6). 10 PASS + 2 negative controls; regex + resolution
checked. Same shape as the Mode F evidence-bar family — a citation must match ≥1 form AND
resolve; the two negative controls (a non-resolving `path:line`, a non-read-only command) must
FAIL.

| ID | Citation | Form | Expected |
|---|---|---|---|
| F-EV-01 | `core/ADRs/ADR-019-specialists-compose-not-absorb.md:1` | CF-1 | PASS (resolve) |
| F-EV-02 | `grep -c "^### Mode" core/skills/pmo-qa-auditor/SKILL.md → 9` | CF-2 | PASS |
| F-EV-03 | `LIVE:` a resolvable release version ref (e.g. a tagged `vX.Y`) | CF-3 | PASS |
| F-EV-04 | a 7–40 hex commit SHA resolvable via `git cat-file -e` | CF-4 | PASS |
| F-EV-NEG-01 | `core/does-not-exist.md:999` | CF-1 | **FAIL** (no resolve) — negative control |
| F-EV-NEG-02 | `rm -rf /tmp/x` (not read-only-class) | CF-2 | **FAIL** — negative control |

The deterministic families (Family 2 severity-banding, Family 3 counting, Family 4 evidence-bar)
run at the Stage-7 DT gate and in pmo-skill-editor Mode C regression; Family 1 classification is
the judgment family adjudicated at Stage-7.
