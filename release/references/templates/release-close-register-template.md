<!-- reference-durability: allow-link -->
# Release Close-Out Register — Template

> **Source:** Stage 13 Close, Phase A7 / Phase C close-out.
> **Consumer surface:** [`release/references/pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) § 6 Outputs. One register authored per release close; EXTENDS (does not replace) the machine-synthesized `#### Release Learnings v<X.Y>` H4 block in `RELEASE_LOG.md`.

---

## How to use

Author one register per release at Stage 13 close. Most fields are **pre-seeded from signals the pipeline already produced** — copy them in, then add operator judgment:

- The **learnings-triple** (`surprise` / `would-change` / `watch-for`) is already synthesized into the `#### Release Learnings v<X.Y>` block in `RELEASE_LOG.md` by `synthesize-release-learnings.sh` (Phase A7). Harvest it.
- The **Outcome** verdict (ATTAINED / PARTIALLY-ATTAINED / NOT-ATTAINED) is already produced by Phase A10 QC4-06. Copy it.

Single-operator scale: keep each field to a few lines. This register is a structured close-out view, not a ceremony. Both framework sections are filled from the same underlying release facts — answer "what did we learn / change" once and let it flow to both.

| When | Who | Output |
|---|---|---|
| Stage 13 close (Phase C), after Phase A7 synthesis + Phase A10 verdict | Stage 13 spoke / operator | One filled register, recorded with the release close-out (sub-task comment or release plan close-out section) |

---

## Part 1 — PMBOK-7 Lessons-Learned

> Source mapping: `surprise` → Situation + Lessons; `would-change`/`watch-for` → Next-cycle Actions; Outcome ← Phase A10 QC4-06.

**Situation** — What did this release set out to do, and what context/constraints shaped it? (Seed: the release `surprise` field + the Change Description.)
> <fill>

**Outcome** — What is the post-deploy result? State the Phase A10 verdict (ATTAINED / PARTIALLY-ATTAINED / NOT-ATTAINED) + one line of evidence.
> <fill — copy the QC4-06 verdict + narrative>

**Lessons** — What did this release teach that should inform future work? (Seed: `surprise`.)
> <fill>

**Next-cycle Actions** — What concrete carry-forward actions follow? (Seed: `would-change` + `watch-for`. Link any filed Issues.)
> <fill>

---

## Part 2 — Kerth Retrospective (compressed, single-operator)

*Prime Directive: "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time."*

**Q1 — What did we do well?** (Net-new positive framing; not in the triple.)
> <fill>

**Q2 — What did we learn?** (Seed: `surprise`.)
> <fill>

**Q3 — What would we do differently?** (Seed: `would-change` + `watch-for`.)
> <fill>

**Ritual of closure (one line):** Release v<X.Y> is closed; continuity preserved.

---

## See also

- [`release/references/pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) — § 6 Outputs (consumer surface); Phase A7 (the machine-synthesized learnings-triple this register harvests); Phase A10 (the QC4-06 Outcome verdict).
- [`release/tools/synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) — the script that composes the `#### Release Learnings v<X.Y>` block this register extends.
