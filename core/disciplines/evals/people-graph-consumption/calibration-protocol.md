# Calibration Protocol: people-graph-consumption

Validates the binary-judge layer (`judge_prompts/people-graph-read-resolution.md`). The deterministic runner layer needs no calibration — it is code-checkable and exact.

## Gold set

≥30 hand-labeled examples of skill output (across the 4 skills), each labeled PASS / FAIL against the four binary criteria (resolution fired from the graph / source is the graph / status filter applied / read-only). Store at `calibration/gold-set.json` (a separate operator-instance artifact — captured skill output may carry real names, so it is NOT committed; only this protocol and the de-identified fixture ship).

Composition: include adversarial negatives — outputs that resolve a *plausible but wrong* name (F-LOCAL-02), outputs that skip the status filter (F-LOCAL-04), and outputs that contain a graph-write phrase (F-LOCAL-03) — so the judge is calibrated against the exact failure surface, not only happy-path passes.

## Labeling rubric

Binary, mirroring the judge CRITERION. A labeler marks PASS only when all four hold; FAIL on any violation. Provide 2–3 worked PASS and FAIL examples per skill so labelers apply the criteria consistently.

## Metrics

- **Per-class precision and recall** (not raw accuracy — A-03): report precision/recall for the PASS class and the FAIL class separately. The FAIL-class recall is the load-bearing one — a judge that misses graph-write leaks or invented names is the dangerous failure.
- **Krippendorff α** against the human labels (A-07).

## Thresholds

- α ≥ 0.80 — reliable; single judge suffices.
- 0.67 ≤ α < 0.80 — tentative; add a second-family judge (e.g., a non-Claude family) and report agreement.
- α < 0.67 — rework the rubric, not the judge ensemble (A-10).

## Bias tests

- **Verbosity:** score-vs-length correlation; reject the judge if |r| > 0.3 (F-02). A read-only resolution answer can be terse — the judge must not reward longer outputs.
- **Self-enhancement:** judge model family ≠ agent model family (F-03) — Sonnet judging an Opus-class agent's output. If only a same-family judge is available, mark calibration "single-family — cross-family validation pending" and do not ship as fully calibrated (per eval-writer's HAND failure mode).
- **Position:** N/A — this is a single-output binary grade, not a pairwise comparison, so no order-swap test applies.

## Reversibility

The α/κ thresholds recommended here are a calibration recommendation the protocol author applies — **MODERATE · confidence: HIGH** per `core/specs/reversibility-protocol.md` (undo = re-set the threshold and re-run calibration; no shipped gate depends on it yet). Shipping a threshold as a release-gate criterion would escalate to EXPENSIVE — out of scope for this suite.
