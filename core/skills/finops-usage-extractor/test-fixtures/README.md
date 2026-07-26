# finops-usage-extractor — synthetic test fixtures

These files are **fabricated** synthetic Claude Code session transcripts used only by
`extract-usage.sh --self-test`. They contain **no real extracted values** — every
`sessionId`, `gitBranch`, `cwd`, timestamp, and token count is invented (per the CIAC-3
data-hygiene rule: the tooling's tests never read real `~/.claude/projects` transcripts,
and no real session-data value appears in any committed artifact on this public repo).

| Fixture | Exercises |
|---|---|
| `proj-alpha/…0001.jsonl` | Exact multi-turn session — cache-write tier split (`ephemeral_1h + ephemeral_5m == total`), tool-use counts, `token_source: exact`. |
| `proj-beta/…0002.jsonl` | Legacy usage-less record with `gitBranch: null` — the `ceil(words/0.75)` heuristic fallback (3 words → 4 tokens), `token_source: heuristic`, null-branch capture (not dropped). |
| `proj-gamma/…0003.jsonl` | In-transcript sidechain (`isSidechain: true`) — `subagent` drill-down record + `subagent_count: 1`; the session total is the whole-file total (inclusive of the sidechain). |

`usage.expected.json` is the oracle: the expected per-session projection the self-test
diffs the extraction against.
