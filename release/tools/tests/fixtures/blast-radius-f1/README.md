# blast-radius F1 fixture — frozen doc corpus + normalized golden

Fixture for test **F1** (default-path regression) in
`release/tools/tests/test_domain_blast_radius.sh`.

## What F1 asserts

`blast-radius.sh`'s doc-tracer output on a frozen 3-file corpus is unchanged, under a
normalized diff, from the output the pre-shared-lib-refactor tool produced on the same
corpus. In one line: the shared schema-v1 emitter refactor is a behaviour-preserving
no-op on the doc corpus.

## Why a committed golden and not a git-history recovery

F1 previously reconstructed the pre-refactor `blast-radius.sh` at run time by walking
`git log` for the newest blob lacking the shared-lib source line, then executing it.
That design had three defects, all of them live:

1. **It could not run offline or in a shallow checkout**, despite the suite's header
   claiming an offline, deterministic posture.
2. **Its classifier was pipe-fragile.** The recovery test was
   `git show <sha>:release/tools/blast-radius.sh | grep -q 'schema-v1-emit.sh'` under
   `set -o pipefail`. `grep -q` exits at the first match — line 33 of ~1400 — and closes
   the pipe, so `git show` takes SIGPIPE (141) and `pipefail` promotes that to the
   pipeline's status. The enclosing `if !` then reads a **matching** blob as
   *non-matching* and classifies a **post-refactor** blob as pre-refactor. Whether it
   fires depends on whether the blob fits the OS pipe buffer before the reader exits, so
   it tracked the tool's file size rather than anything about correctness.
3. **The misclassified blob then died silently.** A post-refactor blob sources
   `lib/schema-v1-emit.sh` relative to its own location; the recovery wrote it to a
   temp dir with no `lib/`, so it produced empty output, which `2>/dev/null` discarded.
   The empty-comparison path emitted `ok` — a PASS for an assertion whose subject
   never ran.

A committed golden removes the git dependency outright rather than hardening it. The
suite now makes **zero** `git` calls.

## Layout

```
fixtures/blast-radius-f1/
├── README.md              # this file — provenance, spec constants, regeneration log
├── verify-golden.sh       # build-time-once: committed golden vs the SPEC constants
├── corpus/                # THE SCANNED ROOT — exactly 3 files, nothing else, ever
│   ├── b.md
│   └── docs/
│       ├── a.md
│       └── target.md
└── normalized-golden.json # 751 B — deliberately OUTSIDE corpus/
```

**`normalized-golden.json` must never live inside `corpus/`.** `normalize()` does not
delete `stats.total_files_scanned`, so a golden written into the scan root is scanned by
the tool under test, inflating the count and adding a bogus first-order entry. The test
copies `corpus/` to a `mktemp` working directory and scans the copy, so the checkout is
never mutated and nothing is ever written into a scanned root at run time.

## Spec constants

The **input** is verified before the **output**, so a mismatch localizes to one named
corpus file rather than being blamed on the golden.

| Corpus path | Bytes | sha256 |
|---|---|---|
| `b.md` | 32 | `1167e054779d9b09c1b9f0d0b867866e746a3dca1aaaa4b0353d1eb7cdaaa668` |
| `docs/a.md` | 53 | `87ddd5d17f24b5990508083e522ef86ac1810fb03122d006fedec0985f9137fc` |
| `docs/target.md` | 27 | `0ef93b8480f6098b559cc9f7b6c4e8b48b9dc2ec6ddfb16df275497ca1344757` |

| Artifact | Bytes | sha256 |
|---|---|---|
| `normalized-golden.json` | **751** (trailing newline included) | `2ae110de972f292bc4ecf3a1c7bfa7e8af11f7feca978edc1cf5c44cc5c769c5` |

Structural expectations: `stats.total_files_scanned = 3`, `stats.first_order_count = 2`,
`stats.second_order_count = 0`, `schema_version = "1"`, and `cli_version` **absent**
(deleted by `normalize()`).

## Generation command — every degree of freedom is pinned

```bash
# $CORPUS = fixtures/blast-radius-f1/corpus   $OUT = any directory OUTSIDE $CORPUS
release/tools/blast-radius.sh \
    --format=json \
    --depth=2 \
    --root="$CORPUS" \
    "docs/target.md" \
  | jq -S 'del(.scanned_at, .scan_root, .stats.elapsed_seconds, .cli_version)' \
  > "$OUT/normalized-golden.json"
```

Each flag is load-bearing, because each one is inside the compared surface:

- **`jq -S` is required.** Key order is in the bytes. Without it the digest changes and
  the byte count does not.
- **`--depth=2` is required.** `depth` is an emitted field. `--depth=1` and `--depth=3`
  each produce a different digest at the same byte count.
- **`$OUT` must be outside `$CORPUS`.** A stray file in the scan root moves
  `total_files_scanned`.
- **The file ends with a trailing newline** (`jq`'s default). 751 bytes includes it.
- **Generate from the current `blast-radius.sh`.** Byte-equality with the pre-refactor
  blob is a verified property, not a build dependency — `git show` is not required.

## `cli_version` is normalized away, deliberately

`blast-radius.sh` declares `readonly CLI_VERSION` and emits it in the envelope. It is a
tool-identity label, not behaviour, so it is not the subject of F1's assertion. Left
inside the compared surface, a pure `CLI_VERSION` bump would red F1 on a no-op change
with "regenerate the golden" as the prescribed remedy — which turns the regeneration
protocol below from a deliberate, reviewed act into routine ceremony, defeating the one
control this fixture leans on.

Stripping it gives up the guarantee that the field is *emitted at all*. That guarantee is
recovered by the **S6 raw-envelope skeleton guard** in the test, which asserts on the
un-normalized output and would catch the field disappearing. `jq del()` on a missing key
is a silent no-op, so neither the value diff nor a key-set guard on the *normalized*
surface can see a normalized-away field vanish — only a raw-surface guard can.

## Verifying the fixture

```bash
bash release/tools/tests/fixtures/blast-radius-f1/verify-golden.sh
```

Exits non-zero on any mismatch and prints the localizing diff.

> **Verify, do not adopt.** The spec is the authority; the generated artifact is the
> claim under test. If a generated golden does not match the byte count **and** digest
> above, that is a **finding to report** — never a constant to update. Size alone cannot
> discriminate: four distinct constructions of this artifact land on exactly 751 bytes
> with four different digests. Treat *size matches but digest differs* as the
> **highest**-suspicion signal, not the lowest — it is the signature of a missing
> `jq -S`, a wrong `--depth`, or a polluted scan root.

## Regeneration protocol

Regeneration is never automatic and never silent. It exists for one case: a **deliberate**
change to `blast-radius.sh`'s doc-corpus output, where the new output is correct and the
golden is the stale side. Building the fixture for the first time is **not** that case.

```bash
BLAST_RADIUS_GOLDEN_REGEN_REASON="#NNNN — <what changed in blast-radius.sh, and why the new output is correct>" \
  bash release/tools/tests/test_domain_blast_radius.sh --regenerate-golden
```

The flag refuses to run without the reason. A regeneration produces a golden diff **and**
a Regeneration Log row below, both visible in the PR diff.

**Stated limit, not over-claimed:** nothing mechanical prevents someone regenerating the
golden to turn a real regression green — that is what PR review is for. What this design
guarantees is that doing so cannot be *silent*: it takes a deliberate flag, a written
reason, a golden diff, and a log row, all in the same diff.

### Regeneration log

| Date | Reason | Producing SHA | Bytes | sha256 (16) |
|---|---|---|---|---|
| 2026-08-06 | Initial fixture creation — replaces the `git show <sha>:…` history recovery. Golden generated from current `blast-radius.sh`; verified byte-identical to the pre-refactor blob and to the pre-fan-out-cap tool on the same corpus, 30/30 across 3 unrelated scan roots. | (this PR) | 751 | `2ae110de972f292b` |
