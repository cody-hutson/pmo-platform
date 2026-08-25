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

A committed golden removes the git-**history** dependency outright rather than hardening
it: the suite makes **zero** `git log` and **zero** `git show` calls, so no arm depends on
a deep clone. It is not zero `git` calls — the tool under test asks `rev-parse
--is-inside-work-tree` whether its scan root is a work tree, and `--regenerate-golden`
stamps `rev-parse --short HEAD` into the log row below. Both are index/HEAD reads that
resolve in a shallow clone; neither walks history. The precise accounting lives in the
suite's own file header.

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
└── normalized-golden.json # 883 B — deliberately OUTSIDE corpus/
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
| `normalized-golden.json` | **883** (trailing newline included) | `ec46e8a7cd67b2b9e6bf742340f1272a812374cf302f2390b28ec4c7aa461ecb` |

Structural expectations: `stats.total_files_scanned = 3`, `stats.first_order_count = 2`,
`stats.second_order_count = 0`, `stats.second_order_status = "fetched"`,
`stats.unreadable_files = 0`, `stats.scan_scope = "all-files"`,
`stats.scan_scope_status = "not-run"`, `schema_version = "1"`, and both `cli_version`
and `stats.scan_scope_status_reason` **absent** (deleted by `normalize()`).

Two of those are worth reading together, because they are the point of the fields.
`second_order_status = "fetched"` beside `second_order_count = 0` says the depth-2 run
**measured** the second-order surface and found it empty — a claim the bare `0` could not
make and which a `--depth=1` run, whose counter is now **absent**, cannot be confused
with. `scan_scope_status = "not-run"` says tracked scoping was deliberately not attempted
here, because the runtime root is a `mktemp` copy and not a work tree; `scan_scope`
records that the count therefore covers the **all-files** population.

## Generation command — every degree of freedom is pinned

```bash
# $CORPUS = a mktemp COPY of fixtures/blast-radius-f1/corpus  (see the scan-root bullet)
#   WORK="$(mktemp -d)"; cp -R release/tools/tests/fixtures/blast-radius-f1/corpus "$WORK/corpus"
#   CORPUS="$WORK/corpus"
# $OUT = any directory OUTSIDE $CORPUS
release/tools/blast-radius.sh \
    --format=json \
    --depth=2 \
    --root="$CORPUS" \
    "docs/target.md" \
  | jq -S 'del(.scanned_at, .scan_root, .stats.elapsed_seconds, .cli_version, .stats.scan_scope_status_reason)' \
  > "$OUT/normalized-golden.json"
```

Each flag is load-bearing, because each one is inside the compared surface:

- **`jq -S` is required.** Key order is in the bytes. Without it the digest changes and
  the byte count does not.
- **`--depth=2` is required.** `depth` is an emitted field. `--depth=1` and `--depth=3`
  each produce a different digest at the same byte count.
- **`$OUT` must be outside `$CORPUS`.** A stray file in the scan root moves
  `total_files_scanned`.
- **The scan root must be a `mktemp` COPY, not the in-repo `corpus/`.** This is the sixth
  degree of freedom and the newest. `blast-radius.sh` now scopes its enumeration to
  git-tracked files when the scan root is a work tree, and emits `stats.scan_scope` /
  `stats.scan_scope_status` saying which population it measured. Run against the in-repo
  path the tool sees a tracked root and emits `tracked` / `fetched`; run against the copy
  — which is what `regenerate_golden()` and the F1 test both do — it sees a non-git root
  and emits `all-files` / `not-run`. Those are different goldens. Pointing the recipe at
  the in-repo corpus produces an **881 B** artifact against a sanctioned **883 B** one,
  and the mismatch diagnostic below names `jq -S`, `--depth`, and a polluted scan root —
  none of which is the cause.
- **The deletion set must match `normalize()` in the test.** It carries five fields, not
  four; `stats.scan_scope_status_reason` is the fifth. An unwidened set here emits a
  **982 B** golden against the sanctioned 883 B.
- **The file ends with a trailing newline** (`jq`'s default). The byte count includes it.
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
> discriminate: measured on the 751-byte predecessor of this artifact, four distinct
> constructions landed on exactly that byte count with four different digests. Treat
> *size matches but digest differs* as the **highest**-suspicion signal, not the lowest —
> it is the signature of a missing `jq -S`, a wrong `--depth`, a polluted scan root, or
> (since #5074) a **git-tracked scan root where the recipe calls for a `mktemp` copy**.

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
| 2026-08-25 | #5260 + #5074 — blast-radius.sh now emits stats.second_order_status (PV-7a Register A) so a not-computed second-order result is distinguishable from a measured-empty one, plus stats.unreadable_files, stats.scan_scope and stats.scan_scope_status (tracked-vs-all-files enumeration scoping). The F1 corpus is a non-git mktemp copy, so it correctly reports scan_scope=all-files / scan_scope_status=not-run; the depth-2 run is MEASURED, so second_order_status=fetched and second_order_count stays present at 0, and total_files_scanned stays 3. normalize() now also deletes the scan-root-class-dependent scan_scope_status_reason. | b39a8dc7 | 883 | `ec46e8a7cd67b2b9` |
