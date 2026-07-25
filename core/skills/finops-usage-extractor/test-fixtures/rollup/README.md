# finops-usage-extractor — synthetic roll-up / attribution fixtures

These files are **fabricated** and used only by `rollup-attribution.sh --self-test`. They
contain **no real extracted values** — every `session_id`, `git_branch`, `cwd`, worktree,
timestamp, issue number, milestone (the non-real `v9.9`), and token count is invented (per
the CIAC-3 data-hygiene rule: the tooling's tests never read real `~/.claude/projects`
transcripts or real hub-state, and no real session-data value appears in any committed
artifact on this public repo).

## What each fixture exercises

`usage.jsonl` is a synthetic **store** (the extractor's output) — a `meta` line plus eight
`session` records, one per resolver outcome:

| session_id (…000000000N) | Attribution tier exercised | Expected `(work_item, tier)` |
|---|---|---|
| …001 | T2 release branch → milestone (reliable, local) | `(milestone:v9.9, branch-milestone)` |
| …002 | T2 chore branch → milestone (reliable, local) | `(milestone:v9.9, branch-milestone)` |
| …003 | T1 issue-event key (decision-event payload, local) | `(#4242, issue-event-keyed)` |
| …004 | T3 hub-state worktree join → milestone (local) | `(milestone:v9.9, hub-state-lineage)` |
| …005 | T4 unattributed — `git_branch: null` | `(unattributed, unattributed)` |
| …006 | T4 unattributed — auto `agent-*` branch, no hit | `(unattributed, unattributed)` |
| …007 | FM-1 multi-branch — `branch_switch: true` | `(multi-branch, unattributed)` |
| …008 | T-PR opt-in — `fix/*` branch resolved via the PR stub | `(#5151, pr-resolved)` |

Supporting synthetic surfaces:

- `hub-state/v9.9/sessions.md` — Surface C; its `worktree` column joins `…004`'s `cwd`
  basename to milestone `v9.9`.
- `pipeline-event-log.md` — Surface B; its decision row carries a `session:<composite>`
  payload whose worktree joins `…003`'s `cwd` basename to issue `#4242`. It also carries an
  ignored-event-type row and a no-matching-session row to exercise filtering.
- `pr-stub.tsv` — a tab-separated `branch → #N` stub the self-test feeds via `FINOPS_PR_STUB`
  so the opt-in T-PR path resolves deterministically without a network `gh` call.

`rollup.expected.json` is the **ground-truth oracle**: the per-session `(work_item,
work_item_kind, attribution_tier)` the resolver must reproduce (the `…008` row reflects the
opt-in PR-resolve outcome the self-test applies via the stub). This is the CIAC-1 primary
attribution-correctness check; the conservation identity (`Σ rollup == Σ session`) is the
secondary plumbing check.
