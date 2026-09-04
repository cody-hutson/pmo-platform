<!-- repo-integrity: allow-issue-ref -->
# finops-usage-extractor — synthetic roll-up / attribution fixtures

> The `#4242` / `#5151` / `#9999` tokens below and in the sibling fixtures are **fabricated
> synthetic issue numbers** (test oracle data), not references to real repository issues.

These files are **fabricated** and used only by `rollup-attribution.sh --self-test`. They
contain **no real extracted values** — every `session_id`, `git_branch`, `worktree`,
timestamp, issue number, milestone (the non-real `v9.9`), and token count is invented (per
the CIAC-3 data-hygiene rule: the tooling's tests never read real `~/.claude/projects`
transcripts or real hub-state, and no real session-data value appears in any committed
artifact on this public repo).

## What each fixture exercises

`usage.jsonl` is a synthetic **store** (the extractor's output) — a `meta` line plus fourteen
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
| …009 | T3 join against a **slug-keyed** hub-state dir (sensitivity) | `(milestone:synthetic-slug-release, hub-state-lineage)` |
| …010 | T2-slug — slug-primary `release/<slug>` branch, no hub-state row | `(milestone:synthetic-slug-branch, branch-milestone)` |
| …011 | **Specificity** — slug-keyed `chore/` branch is deliberately unparsed | `(unattributed, unattributed)` |
| …012 | **Shadowing guard** — branch parses `<slug>-suffix`, hub-state authors `<slug>` | `(milestone:synthetic-slug-release, hub-state-lineage)` |
| …013 | **Sticky header bind** — hub-state file carrying the deployed managed-section fences | `(milestone:synthetic-managed-fence, hub-state-lineage)` |
| …014 | **Malformed-table rejection** — worktree is the prose column label a hardcoded `$5` read emitted | `(unattributed, unattributed)` |

Rows …009–…014 exercise **run-key recognition**. Run keys are slug-primary (ADR-092) with
legacy `vX.Y` read-only, on two independent axes — the hub-state directory basename and the
git branch name — and the shipped `v[0-9]` name-shaped predicates recognised neither slug
form. The directory axis is now recognised **structurally** (table shape, not name shape)
and the branch axis carries a slug arm ordered strictly **below** the authored hub-state
tier.

Supporting synthetic surfaces:

- `hub-state/v9.9/sessions.md` — Surface C; its `worktree` column joins `…004`'s
  `session.worktree` to milestone `v9.9`. **This is the legacy-run-key arm — keep it.**
  Together with the slug-keyed directories it is the two-form proof.
- `hub-state/synthetic-slug-release/sessions.md` — the canonical **slug-keyed** run
  directory. Carries `…009`'s join, `…012`'s shadowing-guard join, and one half of the
  collision pair.
- `hub-state/synthetic-collision-peer/sessions.md` — declares the same `worktree` key
  (`collide-wt`) as the directory above, so one key is claimed by two milestones. No
  session uses it, so the collision is observable without perturbing a graded resolution.
  The map builder sorts its `find` output so last-wins is deterministic and emits one
  stderr `WARNING:` so it is visible.
- `hub-state/synthetic-malformed/sessions.md` — **must contribute zero map entries.** It
  reproduces both live malformation shapes: a pipe table with no `session_id` header (the
  pre-fix `$0 !~ /session_id/` skip cannot skip it, so a hardcoded `$5` read the column
  label `Action` as a worktree), and a conforming header followed by a width-mismatched
  data row. `find -name sessions.md` matches a filename, not a well-formed table.
- `hub-state/synthetic-managed-fence/sessions.md` — the **sticky-header-bind** arm. This is
  the *deployed* shape of a hub-state file, not the in-repo `.template` shape: the
  composition step wraps the template body in managed-section and operator-additions
  fences at install, so those non-pipe lines sit between the table's separator row and its
  first data row. A parser that unbinds its column reference on a non-pipe line emits
  nothing for such a file — silently, with no error and no exit code. The in-repo template
  carries no fences, so this property is unreachable from tracked artifacts and only a
  fixture reproducing the composed shape can regress it.
- `pipeline-event-log.md` — Surface B; its decision row carries a `session:<composite>`
  payload whose worktree joins `…003`'s `session.worktree` to issue `#4242`. It also carries
  an ignored-event-type row and a no-matching-session row to exercise filtering.
- `pr-stub.tsv` — a tab-separated `branch → #N` stub the self-test feeds via `FINOPS_PR_STUB`
  so the opt-in T-PR path resolves deterministically without a network `gh` call.

`rollup.expected.json` is the **ground-truth oracle**: the per-session `(work_item,
work_item_kind, attribution_tier)` the resolver must reproduce (the `…008` row reflects the
opt-in PR-resolve outcome the self-test applies via the stub). This is the CIAC-1 primary
attribution-correctness check; the conservation identity (`Σ rollup == Σ session`) is the
secondary plumbing check.

## `count-once/` — FM-2 hub↔spoke count-once guard fixture

`count-once/usage.jsonl` is a dedicated synthetic store that models the FM-2 cross-file
overlap class: the same spoke spend appearing **both** as an in-transcript sidechain
`subagent` inside a hub session **and** as its own standalone `session`. It carries a hub
session (`…cc01`, whole-file total `140/70`, on `release/v9.9-synthetic-alpha`), a
`subagent` record inside it whose `subagent_id` is the spoke's id (`…cc02`, `100/50`), and
the spoke's own standalone `session` (`…cc02`, `100/50`, same branch). Both resolve to
`milestone:v9.9`.

`count-once/count-once.expected.json` is the oracle: the spoke's `150` tokens must be
counted **exactly once** — the standalone session is authoritative, so the roll-up excludes
the overlapping sidechain copy from the hub's contribution. The correct `milestone:v9.9`
roll-up total is **210** (hub-own `60` + spoke `150`), **not** the naive double-count **360**
(hub whole-file `210` + standalone `150`), and the collision surfaces as
`coverage.count_once_overlap = 1`. On the current separate-file hub-spoke model this overlap
never actually arises (a `subagent_id` is a sidechain-root uuid within the hub file, never a
standalone session-file stem), so the guard is inert in practice — the fixture forces the
collision to prove the guard is present and fail-visible for any future harness regression.
