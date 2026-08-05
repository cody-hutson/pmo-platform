---
title: Session Retro — Emission Contract
purpose: Reference detail for the session-retro emission step — the per-field payload contract, the subtype decision rule, the PII abstraction ladder, and the worked invocations behind the SKILL.md Step 3 contract.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Session Retro — Emission Contract (reference)

The SKILL.md body carries the contract; this file carries the field-level mechanics. The **authoritative** schema is `release/references/standards/pipeline-event-log-schema.md` § 3 (`session-retro` row + payload convention) — this reference expands how to *apply* it, and restates nothing the schema owns.

## 1. Choosing the subtype

Exactly one subtype per row. The decision is about the signal's ORIGIN, not its importance.

| Ask | Then |
|---|---|
| Did the signal come from the operator, with **no recommendation on the table** at that moment? | `operator-feedback` |
| Did the signal come from the work itself — recurring friction, a re-done step, a protocol that fought the task — or from a recommendation↔choice delta the live path missed? | `learning` |
| Did the session produce no novel signal? | `no-learning` (exactly one row; see § 4) |

The `operator-feedback` / `learning` split is not a severity ranking. It exists so a read-model can answer "what is the platform learning from the operator directly, versus from its own friction?" — which is the whole point of decoupling capture from the decision moment. Mis-filing collapses that distinction.

## 2. Field-by-field

| Key | Required | Content | Hard rule |
|---|---|---|---|
| `session:` | YES | An opaque session handle | NEVER a transcript path, a file path outside the platform tree, or anything that identifies the session's content |
| `source:` | YES on `learning` / `operator-feedback` | One of `correction` / `preference` / `redirection` / `friction` / `delta` | Closed set — do not mint values |
| `theme:` | YES on `learning` / `operator-feedback`; **absent** on `no-learning` | Short kebab-case pattern key | The ONLY tokenized field (§ 11.8). It IS the "this is an instance of that pattern" claim |
| `domain:` | YES on `learning` / `operator-feedback` | The surface the learning touches (e.g. `release-ops`, `corpus-edit`, `planning`) | Recognized by the parser, not tokenized |
| `learning:` | YES on `learning` / `operator-feedback` | ONE abstracted sentence | No quotation marks, no names, no verbatim text |
| `reason:` | YES on `no-learning` | Why nothing was emitted | Short, mechanical |

Column values outside `payload` are fixed by the schema: `actor` = `skill:session-retro`; `subject` = `session:<handle>`; `reversibility` = `CHEAP`; `outcome` = `resolved`; `stage` = the stage the session was working in, or `13` for a non-pipeline conversational session.

**`version` = the active release's MILESTONE SLUG — never a `vX.Y`.** It is the release join key per `pipeline-event-log-schema.md` § 2a, and the writer **rejects** a version-shaped value: the shipped version binds only at the Stage-12 claim, after emission has begun, so it is neither unique across releases nor stable within one. The worked invocations below use `pipeline-telemetry-tail` as a concrete slug — substitute the slug of the release the session is actually working in. A session with **no release context at all** passes the reserved literal `(none)`.

**Payload limits (§ 4.3, enforced by the tool):** ≤ 300 characters, no `|` character. A learning that will not fit in 300 characters is not abstracted enough — compress it, do not add a pointer.

## 3. Choosing a `theme:` key

The theme carries the entire cluster signal, so it is the field most worth thinking about.

1. **Query the existing keys first.** `query-pipeline-event.sh --event-type session-retro` and read the themes already in use.
2. **Reuse when the pattern genuinely matches.** A near-miss reuse fabricates a cluster; a needless new key hides a real one. Both are failures — the test is whether a reader seeing both rows would call them the same recurring pattern.
3. **Name the pattern, not the incident.** `read-before-edit` is a pattern. `fixed-the-sweep-script` is an incident.
4. **Kebab-case, ≥ 4 characters, no stopwords.** The tokenizer requires ≥ 4 characters and drops platform-generic terms (`release`, `stage`, `milestone`, …), so a theme built from those tokenizes to nothing and silently never clusters.

## 4. The explicit zero-state

A session that produced no novel learning emits **exactly one** `no-learning` row — not zero rows, and not one row per "thing considered".

```bash
./release/tools/append-pipeline-event.sh \
  --version pipeline-telemetry-tail --stage 13 \
  --event-type session-retro --event-subtype no-learning \
  --actor skill:session-retro --subject "session:d4e5f6" \
  --reversibility CHEAP --outcome resolved \
  --payload 'session:d4e5f6; reason:no-novel-signal-all-observations-already-codified'
```

This mirrors `delta:aligned` in the decision grain and the explicit-N/A markers in the release grain: the zero-state is recorded, never inferred from silence. A reader must be able to distinguish "the retro ran and found nothing" from "the retro never ran".

**Exception — the sampling skip.** A session skipped by the automatic sampling threshold emits **nothing at all**, not a `no-learning` row. The distinction matters: `no-learning` means "reflected, found nothing"; a skip means "did not reflect". Recording skips would re-create the every-session noise the threshold exists to prevent.

## 5. The abstraction ladder (PII, § 4.2)

Walk down until the statement is emittable:

1. **Verbatim** — "the operator said 'stop regexing across files and read each one'". **Never emit.**
2. **Paraphrased with specifics** — "operator objected to the find-and-replace across the 14 depersonalization files". Still carries incident detail; **do not emit**.
3. **Pattern statement** — "operator redirected a mechanical corpus sweep toward per-file reading". **Emit this.**

Level 3 loses nothing a cluster read-model needs: the theme carries the identity, the domain carries the surface, and the sentence carries the shape. Levels 1–2 add only content that § 4.2 disallows and that a redaction row can never fully undo.

## 6. Worked invocations

Operator feedback with no preceding recommendation (the AC6 class — the row the decision-moment path structurally cannot produce):

```bash
./release/tools/append-pipeline-event.sh \
  --version pipeline-telemetry-tail --stage 6 \
  --event-type session-retro --event-subtype operator-feedback \
  --actor skill:session-retro --subject "session:a1b2c3" \
  --reversibility CHEAP --outcome resolved \
  --payload 'session:a1b2c3; source:correction; theme:read-before-edit; domain:corpus-edit; learning:operator redirected a mechanical sweep toward per-file reading'
```

Session friction:

```bash
./release/tools/append-pipeline-event.sh \
  --version pipeline-telemetry-tail --stage 6 \
  --event-type session-retro --event-subtype learning \
  --actor skill:session-retro --subject "session:a1b2c3" \
  --reversibility CHEAP --outcome resolved \
  --payload 'session:a1b2c3; source:friction; theme:worktree-cwd-guard; domain:release-ops; learning:git writes needed an explicit cwd guard to stay in the worktree'
```

A hindsight recommendation↔choice delta — **only** when the live path emitted none for that decision (verify first; see the PROC failure mode in SKILL.md). This is a `decision` row, not a `session-retro` row; the retro's contribution is the `via:` provenance:

```bash
./release/tools/query-pipeline-event.sh --release pipeline-telemetry-tail --event-subtype recommendation-choice-delta   # verify absence FIRST

./release/tools/append-pipeline-event.sh \
  --version pipeline-telemetry-tail --stage 5 \
  --event-type decision --event-subtype recommendation-choice-delta \
  --actor skill:session-retro --subject "#N" \
  --reversibility CHEAP --outcome resolved \
  --payload 'rec:new-subtype; chose:new-event-type; delta:diverged; why:no-decision-class-fit; via:session-retro'
```

## 7. Verifying an emission

```bash
./release/tools/query-pipeline-event.sh --event-type session-retro                        # all rows
./release/tools/query-pipeline-event.sh --event-type session-retro --event-subtype operator-feedback
./release/tools/synthesize-release-learnings.sh --mode pattern-detect --source session-retro --window 5
```

The pattern-detect run is the cross-session read-model; a qualifying cluster is ≥ `cluster_min` (default 3) rows on one `theme:` spanning ≥ 2 distinct versions. Its `--apply` path files an `improvement.yml` CANDIDATE through the governance gate — that is the ONLY promotion route, and it is never this skill's call.
