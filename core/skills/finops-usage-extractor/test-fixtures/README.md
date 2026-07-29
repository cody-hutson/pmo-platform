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
| `dimensions/proj-delta/…0004.jsonl` | **v1.2.0 analysis dimensions, partial-coverage case.** 4 assistant turns: 2 carry `attributionSkill`, 1 carries `attributionMcpServer`, so `by_skill` covers exactly half the session's tokens and `by_mcp` a quarter — the CIAC-2 case (`dimension_coverage` = `0.5` / `0.25`, chosen as exact binary fractions so the oracle is not float-fragile). Also **mixed-model** (2 turns each on 2 model ids, exercising `by_model` as a true partition rather than dominant/last), 3 distinct `tool_calls` names across 4 invocations, and 4 distinct `stop_reason` values including the reserved `"unknown"` for the turn that carries none. |
| `dimensions/proj-epsilon/…0005.jsonl` | **v1.2.0 analysis dimensions, fully-covered case + both seam legs.** 2 assistant turns, both attributed, so `dimension_coverage` = `1` on both best-effort dimensions and the reserved `"unknown"` bucket is present-but-zero (the always-present discipline). Turn 1 places `attributionSkill` at the **record top level** and `attributionMcpServer` under **`.message`**; turn 2 swaps them — so if either leg of the extractor's dual-probe source seam stopped firing, coverage would drop to `0.5` and the oracle would fail. |

**No `isSidechain: true` records in `dimensions/`** — deliberate: the self-test asserts
exactly one `subagent` record across the whole fixture corpus (`proj-gamma`'s), so a new
sidechain here would break an unrelated assertion. **Cache tiers satisfy
`ephemeral_1h + ephemeral_5m == total`** per session, which the self-test also asserts.

`usage.expected.json` is the oracle: the expected per-session projection the self-test
diffs the extraction against. Its v1.2.0 rows (`by_skill` / `by_mcp` / `by_model` /
`tool_calls` / `stop_reason` / `dimension_coverage`) were **hand-computed from the fixture
token values, not captured from a run** — an oracle derived from the code under test
asserts nothing about that code.
