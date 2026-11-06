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
| `per-response/proj-zeta/…0006.jsonl` | **v2.0.0 counting unit — a response written across several lines counts once.** Three API responses on six assistant lines: a three-block response (thinking, text, tool_use) attributed to a skill, a one-line response, and a two-line response that repeats one `tool_use` block. Each response's usage counts once (the self-test's `three-block` arm), the repeated `tool_use` id counts one `Read` call, and `by_skill` covers exactly half the tokens (`0.5`). The three-block response's last line carries a **deliberately lower** `cache_read_input_tokens` — 97 against 98 on its first two lines — so the per-field maximum (98) is the recorded value and a last-line-wins merge, which would read 232 instead of 233, fails: the value pins the order-independence of the max-merge. |
| `per-response/proj-eta/…0007/subagents/agent-00000000000000007.jsonl` | **Partial streaming output.** The real spawned-agent layout (`<session-uuid>/subagents/agent-<id>.jsonl`), every record a sidechain: one response whose first line carries a partial `output_tokens` of 2 and whose last line carries the final 25. The store records 25 on both the `session` and the `subagent` record (the self-test's `partial-output` arm). |
| `per-response/subagents/agent-afixture-no-final-output.jsonl` | **Incomplete-response flag.** A spoke-shaped transcript, every record a sidechain, with eight API responses. A to D are write shapes measured in real spawned-agent transcripts: A — a snapshot line, then the final usage and the stop reason on its last line (complete; the near-miss); B — thinking and tool_use, no stop reason on either line; C — one tool_use line with no stop reason and a 120-token snapshot; D — one closing `end_turn` line. Of these, exactly B and C are incomplete. E, F and G carry no stop reason and each fails exactly one evaluability clause — E has no `stop_reason` key, F no `message.id`, G no usage block — so each counts in `unevaluated_responses`, and deleting that clause would count it incomplete. H carries the `stop_reason` key only at the record's top level, the second placement the extractor reads, so it is evaluable and incomplete. The self-test's `no-final-output` arm asserts `[3, 3]` (incomplete, unevaluated) on both the `session` and the `subagent` record. Among A to D, a ≤10-token threshold would count 1 incomplete, the visible-character floor 0 and an any-line-null test 3. G is usage-less, so the session reads `token_source: mixed`. |

**No `isSidechain: true` records in `dimensions/`** — deliberate: the self-test asserts
exactly three `subagent` records across the whole fixture corpus (`proj-gamma`'s and the
partial-output and no-final-output transcripts'), so a new sidechain here would break an
unrelated assertion.
**Cache tiers satisfy `ephemeral_1h + ephemeral_5m == total`** per session, which the
self-test also asserts.

**Stems are one namespace across every subdirectory.** `session_id` is the filename stem,
and the self-test rejects a duplicate `session_id` across the whole tree (assertion 3), so
a new fixture needs an unused stem; the next UUID ordinal is `0008`. **The pre-v2.0.0
fixtures are id-less on purpose:** their assistant lines carry no `message.id`, so each
line is its own response and their oracle rows did not change at the v2.0.0 counting-unit
correction. Being id-less, they cannot be evaluated by the incomplete-response flag
either: their 7 responses that carry no stop reason count in `unevaluated_responses`,
never as incomplete. The oracle's projection carries neither count, so their rows did not
change for that either; the `no-final-output` arm asserts both counts directly. **Earlier lines of a per-response fixture carry `stop_reason: null`**, as every
assistant line of a real transcript carries the key, so a reader that keys on the field's
presence meets the real line shape.

`usage.expected.json` is the oracle: the expected per-session projection the self-test
diffs the extraction against. Its v1.2.0 rows (`by_skill` / `by_mcp` / `by_model` /
`tool_calls` / `stop_reason` / `dimension_coverage`) and its three per-response rows were
**hand-computed from the fixture token values, not captured from a run** — an oracle
derived from the code under test asserts nothing about that code.
