# rank/ — synthetic transcripts for the command-template ranker

These files are **fabricated** session transcripts read only by
`scripts/rank-command-templates.sh` (its `--self-test`, and the runtime canary every live run
replays first). Every value is invented: the home paths, user names, repositories, literals and
token counts below appear in no real transcript.

**The `.jsonl.fixture` suffix is load-bearing.** The extractor's self-test sweeps every `*.jsonl`
under `test-fixtures/`, and a transcript here would add sessions to its corpus-wide assertions.
The ranker stages each `*.jsonl.fixture` as `*.jsonl` into a temporary root before it reads one.

**Fabricated paths.** B's control carries a fabricated Linux-shaped home path; A's and C's carry a
fabricated non-home path holding the same kind of literal, because the PII pre-commit guard admits
no macOS-shaped home path into the tracked corpus. Each of those records also carries a
`fixtureNote` field holding the `path-leak: allow` marker, which the path-portability check honours
per line. The ranker never reads that field.

| File | Shape | Feeds |
|---|---|---|
| `sessions/proj-rank-a/…00a1.jsonl.fixture` (A) | Main session; first message `executing Stage 6`. The control (a `cd` into a fabricated path, then `gh issue view … \| head`); one response written on two lines that repeat one `tool_use` block; a once-only `printf` carrying a person and an address; three `sleep && gh run list` calls; a compaction boundary; then a `python3` heredoc carrying a literal | control, near-miss (both), dedupe, leak, cost, compaction, stage, parity |
| `sessions/proj-rank-a/…00a1/subagents/agent-…a1c3.jsonl.fixture` (C) | A spoke under A, every record a sidechain; first message `executing Stage 7`. The control (its `--jq` program carries a literal); `bash` running a tracked script; a `Write` of a `.py` file; `git status` with an unlisted flag; a `curl` | control, rung, leak, stage, cost, parity |
| `sessions/proj-rank-b/…00b2.jsonl.fixture` (B) | Main session with no stage in its first message. The control in a second variant (its `--json` field is a literal; `--repo` last); a verbatim copy of A's `printf` record (same message id, uuid and tool_use id); `bash` running the tracked script with an unlisted flag after its script operand; a `Write`; a comment line followed by `git status` | control, copied-history, comment, rung, leak, cost, parity |
| `sessions/proj-rank-d/…00d4.jsonl.fixture` (D) | A hub: an `Agent` spawn whose prompt names `Milestone <slug>`, while its first message names `Stage 5`. A `python3` heredoc; `echo ${#…}; git log`; a `for` loop; a `git commit` whose message is a heredoc inside `$( … )` with apostrophes in its body | stage (a hub carries no stage), heredoc, comment, canonicalizer, substitution |
| `sessions/proj-rank-d/…00d4/subagents/workflows/agent-…d4e5.jsonl.fixture` (E) | A workflow agent under D. `echo ${#…}; git log`, a `for` loop and the commit-message idiom again, so all three rank | stage (workflow role), comment, canonicalizer, substitution |
| `bound/proj-rank-bound/…00f6.jsonl.fixture` | One segment: a call whose 3,000-character result is re-read by responses whose measured context is 11 tokens | bound (the cost status degrades and the segment is clamped); staged on its own |

The five session files also feed the memory arm: the ranker reads them one at a time, and at most one
file's records may be alive at once.

## What ranks

Eight procedures appear in at least two sessions: the control `cd && gh issue view | head` (A, B,
C), `git status` (B, C), `bash core/skills/finops-usage-extractor/scripts/report-usage.sh` (B, C),
`Write <PATH>.py <CODE>` (B, C), `python3 <HEREDOC>` (A, D), `echo ; git log` (D, E), `for ; wc`
(D, E) and `git commit` (D, E). The near-misses stay below the two-session floor: `printf` occurs once, because
B's copy of A's record is dropped as copied history, and `sleep && gh run list` occurs three times
in one session.

## The leak table

The self-test's leak table names each literal, the masking class that must consume it and the
procedure it sits in. A literal in a ranking procedure proves its class: path (`fixtureuser`,
`otherfixture`, `agent-zz`), slug (`synthetic-owner`, `synthetic-repo`, `other-owner`), default
(`fixtureleakfield`), code (`fixturejqfield`), flag (`fixture-codename`), interpreter flag
(`fixture-interp-flag`), heredoc (`FIXTURE_SECRET_VALUE`, `FIXTURE_HUB_SECRET`), comment
(`fixturecommentword`) and variable (`FIXTURE_ARR`, and `fixturecommitword` inside a substitution). Three more sit in procedures that never rank
(the `printf` person and file, and the hub's milestone slug) and are asserted absent all the same.

## The cost oracle — hand-computed

The cost arm asserts the control's `tokens` against these values. They come from the fixture's
lengths, not from a run. An occurrence's call costs `t_c = (characters of the JSON-serialized tool
input + characters of the tool name) / 1.5` output tokens; its result costs `t_r = result
characters / 1.5`. Both are written once, `w = t_c + t_r`, by the next response in the same
compaction segment, split over that response's cache tiers (every writing response here carries
100 one-hour and 300 five-minute tokens, so one quarter and three quarters), and re-read by each of
the `R` later responses in the segment.

| Occurrence | input JSON | + name | `t_c` | result | `t_r` | `w` | `R` |
|---|---|---|---|---|---|---|---|
| A `ta1` | 154 | 4 | 316/3 | 22 | 44/3 | 120 | 4 (A's a3–a6; a7 and a8 lie past the compaction boundary) |
| B `tb1` | 182 | 4 | 124 | 18 | 12 | 136 | 4 (b3–b6, after the copied record that writes it) |
| C `tc1` | 140 | 4 | 96 | 18 | 12 | 108 | 4 (c3–c6) |

| Leaf | Value |
|---|---|
| `output` | 316/3 + 124 + 96 = 976/3 = 325⅓, rounded half-up = **325** |
| `cache_creation.total` | 120 + 136 + 108 = **364** |
| `cache_creation.ephemeral_1h` | 364 / 4 = **91** |
| `cache_creation.ephemeral_5m` | 364 × 3/4 = **273** |
| `cache_read` | 364 × 4 = **1456** |
| `input` | **0** |

Each result was padded so that `w` is a whole multiple of four, which keeps every cache leaf exact;
the output leaf is summed exactly and rounded half-up once, as every leaf is. The
weekly-point figures are not pinned here: they come from `convert-usage.sh --convert` over these
tokens, whose calibrated values the cost-unit record moves by editing the numeric home alone.
