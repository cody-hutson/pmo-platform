<!-- reference-durability: allow-link -->
# Doc-Corpus-Reorg Ref-Form Protocol

> **Source:** Stage 5 Solutioning support — the rewrite-surface enumeration for documentation-corpus moves and renames.
> **Consumer surfaces:** [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) Phase A3.2 (firing trigger + obligation) · [`release/references/templates/design-review-checklist.md`](../templates/design-review-checklist.md) Section 1 check 1.6 (exit-gate confirmation).

---

## 1. What this is + when it fires

This protocol is the **method-body** for enumerating the complete reference-rewrite surface of a **doc-corpus reorg** — any change that **moves or renames at least one durable-corpus file**: relocation across directories, a directory rename, or a module-subtree move. When such a change is under design, every reference that names a moving file must be rewritten; this protocol gives the canonical set of reference *forms* a rewrite must catch, so the rewrite is **complete-by-construction** rather than discovered-incomplete at the exit gate.

**It fires when:** the change under design moves or renames at least one durable-corpus file (the path of a referenced file changes).

**It does NOT fire when:** the change is an in-place content edit — no path changes, no file relocates or is renamed. For an in-place edit there is no rewrite surface to enumerate, so this protocol is omitted entirely. Omission when no file moves is the correct non-ceremony signal — writing "N/A" for every form is itself ceremony noise; the absence of the table is the signal that nothing moved (the same omission discipline the Cascade-Sweep block and the conditional gate criteria follow).

**Why a distinct protocol — division of labor.** Three nearby disciplines each answer a *different* question; this protocol exists because none of them answers the rewrite-surface question for a moving file set:

| Discipline | Question it answers | Why it is not this protocol |
|---|---|---|
| Blast-radius CLI ([`blast-radius-protocol.md`](blast-radius-protocol.md)) | "Which files mention X today?" — **inbound** referrers to one **static, extant** target. | A moving file does not exist at its new path yet, and the tool has no "outbound-from-the-mover" mode. It discovers inbound mentions of a target that stays put; it cannot enumerate the rewrite surface of a *set* of files that are relocating. |
| Cascade-Completeness Sweep (stage-05 § 5.6) | "Where else does this OLD **value** appear?" — a count / enumeration / threshold **value** change (`N → M`). | A reorg changes a **path** (`path → path'`), not a value. § 5.6 fires on value-occurrence; this protocol fires on path-shape. They are isomorphic in *shape* (sweep + table + disposition + verdict) but orthogonal in *trigger*. |
| Link-resolution (the doc-link maintenance protocol + its deploy-check check) | "Does this link resolve to a file that exists today?" — link **liveness**. | Liveness is a post-hoc property of one link; this protocol is the pre-edit enumeration of every syntactic form a reference can take so the rewrite covers them all. A link can resolve today and still be a form a naive rewrite would have missed. |

This protocol is the **path-form** sweep for a **moving set**. It is the structural-enumeration analog of § 5.6's value-occurrence sweep, and it is deliberately built in the same shape (a parameterized sweep command per form, a disposition table, and a verdict line) so a reviewer reads it with the same muscle memory.

---

## 2. The six canonical ref-forms

Each form is a **syntactic shape a path reference to a moved file can take**, defined by *where the referrer sits relative to the moving file set*. Forms F1–F5 partition the rewrite surface by referrer position; F6 is an orthogonal overlay that fires when a participant is also under a byte-identity mirror. The completeness argument is in § 6.

| # | Ref-form | Definition (relative to the moving file set) | Current-corpus binding + where it appears | Why a naive sweep misses it |
|---|---|---|---|---|
| **F1** | **Module-rooted literal** | A reference written as a repo-root-relative path beginning with a module root — `core/…`, `release/…`, or `operations/…`. | Module-rooted under the modular monolith (one module root per reference). This is the anchor form the others are derived from. | The obvious form — usually caught. It is listed first because the remaining forms are defined as departures from it; a rewrite map keyed only on this shape misses every relative form below. |
| **F2** | **Relative-inbound** | A `[text](../…/<mover>.md)` link from a referrer in a *sibling or cousin* directory whose `../` chain resolves *into* the mover's old location. | The dominant relative form corpus-wide; appears wherever one reference doc links a peer doc by a relative `../` path. | The path string carries no module prefix and uses `../` segments, so a rewrite map keyed on the F1 module-rooted shape never matches it. This is the historically dominant undercount. |
| **F3** | **Root-escape** | A relative link whose `../` chain climbs *past the module root* to a repo-root file (for example `../../README.md`, `../../SECURITY.md`, `../../SKILL.md`) — or, inversely, a deep referrer reaching the mover through a long `../../../…` chain. | Repo-root targets reached by a 2-deep escape, plus the deepest 3-, 4-, and 5-segment chains that exist in the corpus. | Depth-bounded sweeps silently truncate the deepest chains (the blast-radius CLI is hard-capped at depth 4, so it cannot see a chain deeper than that). Climbing *past* the module boundary also defeats any module-scoped grep. The F2/F3 sweep MUST NOT inherit a depth cap. |
| **F4** | **Mover-internal-outbound** | References that live *inside the moving files themselves*, pointing OUT to non-moving files — these break because the **referrer's own base path changes** when the file relocates. | Every moving `.md` with relative `[text](<../relative-path>)` links to files that stay put; pipeline and reference shards carry many outbound links each. | Inbound-only discovery never opens the mover's *own* outbound links. This is the form the inbound-discovery tool structurally cannot reach — when the mover's base directory changes, every relative outbound link inside it must be recomputed. |
| **F5** | **Retained-sibling → mover** | A reference from a file that **stays behind** in the mover's *old* directory, pointing at a now-moved sibling via the old short relative form (`[text](<sibling.md>)` or `[text](<./sibling.md>)`). | Any retained file in the old directory that keeps a short relative link after a sibling relocates out of that directory. | The retained file is not in the "moved files" list, so a mover-scoped rewrite never opens it; the short relative link looks intra-directory and reads as low-risk. (This is the retained-sibling form that a prior reorg surfaced only at collective review.) |
| **F6** | **Governed mirror-pair** | A reference (or the moving file itself) that participates in a **byte-identity-enforced mirror**, where a move or edit on one half must be reflected on the partner or a deploy-check reports DRIFT. | Live governed mirror mechanisms, enforced by `core/deploy/deploy.sh --check`: (a) the **rules-mirror** `MIRROR_PAIRS` set — `core/rules/<f>.md` mirrored to the workspace `~/.claude/rules/<f>.md` (source-to-workspace, plus the release-process and OPERATIONS pairs), enforced by Check 9; (b) the **template-sync** `TEMPLATE_SYNC_MAP` canonical-to-runtime set, enforced by Check 13; (c) the **harness-mirror** `HARNESS_LIST`, enforced by Check 11 (currently empty); (d) the `*.template` only-if-not-exists seed files (eight on disk). | A mover may relocate one half of a mirror without the partner, or rewrite a reference in one half and not the byte-identical twin, producing silent DRIFT at the next `deploy.sh --check`. In the byte-identity case this is not a *link* at all — invisible to any link-resolution sweep. The F6 sweep cross-checks the moving set against the deploy-check mirror maps directly, so it does not depend on link discovery. |

This six-member table is the **canonical set**. The bindings are stated against the current modular-monolith layout: F1 is module-rooted (`core/|release/|operations/`); the F2/F3 sweep is uncapped in `../` depth (it must not inherit any tool depth cap, which is the truncation defect this protocol exists to prevent); and the F6 rules-mirror binding is the live `core/rules ↔ ~/.claude/rules` source-to-workspace mapping defined by the deploy-check mirror set.

---

## 3. Per-form sweep commands

One reproducible sweep per form, parameterized by the old/new path pair of the moving file set. Parameterize before running:

```bash
# The moving file set — set these for the reorg under design.
OLD_DIR="release/references/pipeline"          # the directory the file(s) leave
NEW_DIR="release/references/explanation"        # the directory the file(s) arrive in
MOVERS=( "stage-05-solutioning.md" )            # basenames of every moving file
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
```

**F1 — module-rooted literal.** Find every repo-root-relative reference to each mover by its old module-rooted path:

```bash
for m in "${MOVERS[@]}"; do
  grep -rnoE "(core|release|operations)/[A-Za-z0-9_./-]*${m}" \
    --include='*.md' --include='*.sh' --include='*.json' --include='*.yml' --include='*.toml' \
    core/ release/ operations/
done
```

**F2 / F3 — relative-inbound + root-escape (uncapped depth).** Find every relative `[text](<../relative-path>)` link, at ANY `../` depth, that resolves to a mover's old location. Do NOT bound the `../` chain — the deepest chains are exactly the ones a capped sweep truncates:

```bash
for m in "${MOVERS[@]}"; do
  grep -rnoE "\]\((\.\./)+[A-Za-z0-9_./-]*${m}" --include='*.md' core/ release/ operations/
done
# Root-escape audit: relative links that climb past a module root to a repo-root file.
grep -rnoE "\]\((\.\./){2,}[A-Za-z0-9_.-]+\.(md|template)" --include='*.md' core/ release/ operations/
```

**F4 — mover-internal-outbound.** Open each moving file and list its OWN relative outbound links; every one must be recomputed against the new base directory:

```bash
for m in "${MOVERS[@]}"; do
  echo "== ${OLD_DIR}/${m} outbound relative links =="
  grep -noE "\]\((\.\./|\./)[A-Za-z0-9_./-]+\.(md|sh|template)" "${OLD_DIR}/${m}"
done
```

**F5 — retained-sibling → mover.** Scan the files that STAY in the old directory for short relative links to a moved basename (the retained siblings a mover-scoped rewrite never opens):

```bash
for m in "${MOVERS[@]}"; do
  grep -rnoE "\]\((\./)?${m}\)" --include='*.md' "${OLD_DIR}/"
done
```

**F6 — governed mirror-pair.** Cross-check each mover against the live deploy-check mirror maps; flag any mover that is a mirror half (its partner needs a second, byte-identical rewrite):

```bash
for m in "${MOVERS[@]}"; do
  echo "== mirror membership for ${m} =="
  grep -nE "${m}" core/deploy/deploy.sh \
    | grep -iE "MIRROR_PAIRS|TEMPLATE_SYNC_MAP|HARNESS_LIST"
  find core/ release/ operations/ -name "${m}.template"
done
```

The sweep commands are the reproducible evidence for the output table. Re-running a cited sweep against the release branch must return the rows the table enumerates; a hit not enumerated in the table is a finding.

---

## 4. Output table schema

The protocol's output is a single table — one row per (ref-form × occurrence) — plus a verdict line. It is deliberately **isomorphic to the Cascade-Sweep block** (stage-05 § 5.6) so a reviewer reads it with the same muscle memory.

```markdown
### Doc-corpus-reorg ref-form enumeration (per doc-corpus-reorg-ref-forms.md)

**Moving file set:** <OLD_DIR>/<mover> → <NEW_DIR>/<mover> (one line per mover)
**Sweep date:** <YYYY-MM-DD> at commit <short SHA>

| Form | Referrer (file:line) | Occurrence (quoted reference) | Disposition | Rationale |
|---|---|---|---|---|
| F1 | `<path>:<n>` | `<quoted ref>` | REWRITE / N/A | <one-line reason> |
| F2 | ... | ... | ... | ... |
| F3 | ... | ... | ... | ... |
| F4 | ... | ... | ... | ... |
| F5 | ... | ... | ... | ... |
| F6 | `<mover>` | `<mirror map + partner>` | MIRROR-SYNC / N/A | <one-line reason> |

**Verdict:** <REWRITE count> / <N/A count> / <MIRROR-SYNC count>
```

**Disposition values:**

| Disposition | Meaning |
|---|---|
| **REWRITE** | The reference names a moving file (or lives inside one) and must be edited to the new path as part of this reorg. |
| **N/A** | A sweep hit that is not a real rewrite target — a coincidental basename match, a reference already pointing at the new path, or a mention inside a fenced historical snapshot. Every N/A row carries a reason naming why it is not a rewrite. |
| **MIRROR-SYNC** | (F6 only) The mover is a mirror half; the partner needs a byte-identical rewrite or relocation so the deploy-check mirror does not DRIFT. |

**Completeness test (the enumeration is incomplete if any holds):**

- A form row is absent for a form that has occurrences in the moving set (verifiable: re-run that form's sweep against the release branch — if it returns hits the table does not enumerate, the enumeration is incomplete).
- A sweep command is missing or irreproducible for any form present.
- A row carries no disposition, or an N/A / MIRROR-SYNC row carries no rationale.
- The verdict line is absent.
- All six forms are addressed: a form with genuinely zero occurrences is shown as a single `N/A — no occurrences in the moving set` row, not silently dropped (the table proves each form was considered).

---

## 5. Composition (non-overlap)

This protocol's six-form set does not duplicate any existing governed enumeration; each neighbor solves an adjacent but distinct problem.

- **Reference-durability ladder** ([`reference-durability-standard.md`](../../../core/standards/reference-durability-standard.md)) ranks references by *fragility — should this reference exist at all*, on a six-rung ladder. This protocol ranks path-references by *syntactic form for a mechanical rewrite*. Different axis, different question; a reference can be high on the durability ladder and still take any of F1–F6's syntactic shapes.
- **Cascade-Completeness Sweep** (stage-05 § 5.6) sweeps OLD-**value** occurrences after a count / enumeration / threshold change (`N → M`). This protocol sweeps path-**form** occurrences after a file move (`path → path'`). § 5.6 fires on a value change; this fires on a path change. The two compose: a single change could in principle trigger both, and each emits its own block.
- **Blast-radius CLI** ([`blast-radius-protocol.md`](blast-radius-protocol.md)) discovers inbound referrers to one static, extant target. This protocol enumerates the rewrite surface of a moving set — including the mover's own outbound links and byte-identity mirror partners, which inbound discovery structurally cannot reach.
- **Link-resolution** (the doc-link maintenance protocol) polices whether a link is alive today. This protocol polices whether the rewrite covered every form before the edit. Liveness is downstream of rewrite-completeness, not a substitute for it.

No existing home enumerates path-rewrite ref-forms for a doc-corpus mover, so this protocol is a net-new placement in `release/references/protocols/` next to its natural sibling, the blast-radius protocol — not a duplicate of any of the above.

---

## 6. Completeness-by-construction

The set is exhaustive by the following construction. Every path reference *to* or *from* a moving file falls into exactly one position class:

- The referrer addresses the mover by an absolute / module-root path → **F1**.
- The referrer addresses the mover by a relative path from a sibling or cousin that resolves inward → **F2**.
- The referrer addresses the mover by a relative path that climbs past the module root (or is a deep chain reaching the mover) → **F3**.
- The reference lives inside the mover, pointing out → **F4**.
- The reference lives inside a retained old-directory sibling, pointing at the mover → **F5**.

F1–F5 therefore partition the rewrite surface **by referrer position relative to the mover** — every reference has exactly one position. **F6 is an orthogonal overlay**, not a sixth position: it fires when *any* F1–F5 reference, or the moved file itself, participates in a byte-identity mirror, because a mirror partner needs a second rewrite that link mechanics alone never surface. Position-exhaustiveness across F1–F5, plus the mirror overlay F6, is the construction argument: a reference that is neither addressed-by-some-path nor living-inside-a-relevant-file does not name a moving file at all, and a mirror obligation that link-resolution would miss is exactly what F6 captures.

The practical consequence: a Stage 5 spoke that emits all six form rows with dispositions has produced a rewrite specification Engineering can execute without rediscovering missed forms, and the exit gate (the design-review-checklist Section 1 confirmation check) **confirms** the six-form table is present and grounded rather than **discovering** an undercount after the rewrite is built.

---

## 7. See also

- [`release/references/pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) — Phase A3.2 firing trigger + obligation (canonical consumer).
- [`release/references/templates/design-review-checklist.md`](../templates/design-review-checklist.md) — Section 1 check 1.6 exit-gate confirmation (canonical consumer).
- [`release/references/protocols/blast-radius-protocol.md`](blast-radius-protocol.md) — inbound-discovery for a static target (adjacent, non-overlapping).
- [`core/standards/reference-durability-standard.md`](../../../core/standards/reference-durability-standard.md) — the durability ladder (orthogonal axis).
- [`release/tools/blast-radius.sh`](../../tools/blast-radius.sh) — the inbound-discovery CLI.
