<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- reference-durability: allow-link -->
# Memory↔corpus drift audit

> Standing how-to for auditing the auto-memory store (`~/.claude/memory/`) against the codified corpus for SSOT drift. It is the human-runnable companion to `deploy.sh --check` Check 36 (`memory-corpus-tie-drift`) — run it on demand to reproduce what the standing backstop reports continuously.

**Governing contract:** [`core/disciplines/knowledge-architecture.md` §7 Memory↔corpus boundary](../../../core/disciplines/knowledge-architecture.md#memory-corpus-boundary) (the two-tier SSOT assignment, the no-shadow-SSOT invariant, the encode-and-evict lifecycle). **Decision record:** [ADR-029](../../../core/ADRs/ADR-029-memory-corpus-ssot-boundary.md), generalized across all four memory types by [ADR-045](../../../core/ADRs/ADR-045-cross-surface-memory-contract.md). **Sibling pattern:** the single-source + enforced-rebuild deploy check on the skill↔reference surface — this is the same idea on the memory↔corpus surface.

---

## 1. Purpose

The memory↔corpus boundary contract assigns codified (toolkit-encodeable) knowledge to the corpus as its single source of truth, and permits the auto-memory store to hold codified knowledge only as a temporary eviction-pointer. Over time five drift conditions accumulate against that contract — three at the issue-tie boundary, plus two reference-integrity conditions (a downstream dangling wikilink and an upstream stranded ledger pointer) closed alongside the RE-POINT lifecycle step and the close-time absorption reconciliation. This procedure detects all five, reproducibly, so an operator (or a reviewer reading a memory audit) can confirm the store is in contract — or generate the exact remediation list.

The audit is **read-only**. It deletes nothing and edits nothing. Remediation (eviction, re-tie, or filing an encode issue) is a separate, operator-authorized step routed per §4.

## 2. The load-bearing rule — resolution-failure, never digit-match

Re-versioning renumbers issues. An eviction-pointer that cited a given issue number last quarter may now point at a renumbered or retired number. **A dead reference is therefore detected by reference-resolution-failure — never by comparing issue-number magnitude.** Probing whether an issue number is "below the current max" is meaningless: a low number can be live and a high number can be retired. Only a resolution probe (`gh issue view N`) is load-bearing. Every command below probes resolution; none compares digits.

## 3. The five drift classes

| Class | Definition | Detection (reproducible) |
|---|---|---|
| **deployed-but-not-evicted** | a memory's tied issue is CLOSED, the corpus encoding is present on `main`, but the memory file still exists | `gh issue view N --json state` == `CLOSED` **AND** a corpus grep of the encoded phrase succeeds **AND** the memory file is still present ⇒ flag |
| **dead-ref tie** | a memory's eviction-pointer cites an issue # that no longer resolves (re-versioning renumbered it away) | `gh issue view N` returns NOT_FOUND / non-zero (resolution-failure) ⇒ flag. NEVER digit-match |
| **untied-encodeable** | a memory the §1 Q1 classifier marks K1-encodeable, but carrying no issue tie and no corpus pointer | memory body matches encodeable signatures (discipline / reference / methodology / gate / CI) with no `#N` tie and no corpus-path pointer ⇒ flag for operator routing |
| **dangling-wikilink-to-evicted-memory** | a surviving memory body links a `[[target]]` whose `<target>.md` no longer exists — left dangling by an EVICT that did not RE-POINT (downstream gap) | for each `[[target]]` wikilink → if `$MEM/<target>.md` is absent ⇒ flag (re-point to its corpus home or drop, per §7 RE-POINT). Local-only (no `gh`); warn-only routing signal, never a FAIL |
| **ledger-pointer-to-closed-issue** | a `MEMORY.md` ledger ("Temporary enhancement pointers") row ties a `#N` that is CLOSED yet the memory was not absorbed/evicted — the partial-absorption residue (upstream gap) | scan the ledger section; for each row's resolving `#N` tie where `gh issue view N --json state` == `CLOSED` ⇒ flag (re-home to a live issue per Phase B-OPS5). Disambiguated from `deployed-but-not-evicted` by file-section (ledger row vs standalone topic file) |

### 3a. Per-class commands

Set the store root once (the canonical Layer-2 memory path):

```bash
MEM="${HOME}/.claude/memory"
```

**deployed-but-not-evicted** — for each memory carrying a `#N` tie, confirm the issue is CLOSED, the corpus has the encoded phrase, and the file still exists:

```bash
# Enumerate memory files that carry an issue tie, extract the first #N per file.
grep -rlE '#[0-9]+' "$MEM" | while read -r f; do
  n=$(grep -oE '#[0-9]+' "$f" | head -1 | tr -d '#')
  [ -n "$n" ] || continue
  state=$(gh issue view "$n" --json state --jq .state 2>/dev/null) || continue
  if [ "$state" = "CLOSED" ]; then
    # Replace ENCODED_PHRASE with the rule's encoded heading/phrase for this memory.
    if grep -rqs "ENCODED_PHRASE" core/ release/ && [ -f "$f" ]; then
      echo "deployed-but-not-evicted: $f (tie #$n CLOSED, corpus present, file still present)"
    fi
  fi
done
```

**dead-ref tie** — for each `#N` tie, flag when the probe fails to resolve (never compare magnitude):

```bash
grep -rlE '#[0-9]+' "$MEM" | while read -r f; do
  for n in $(grep -oE '#[0-9]+' "$f" | tr -d '#' | sort -u); do
    if ! gh issue view "$n" --json number >/dev/null 2>&1; then
      echo "dead-ref tie: $f cites #$n which does not resolve (resolution-failure)"
    fi
  done
done
```

**untied-encodeable** — surface memories that read as codifiable but carry no tie and no corpus pointer (heuristic; routes for operator judgment):

```bash
grep -rLE '#[0-9]+|core/|release/|CLAUDE\.md' "$MEM" | while read -r f; do
  if grep -qiE 'discipline|reference|methodology|gate|CI|protocol|standard' "$f"; then
    echo "untied-encodeable (candidate): $f matches encodeable signatures with no #N tie and no corpus pointer"
  fi
done
```

**dangling-wikilink-to-evicted-memory** — for each `[[target]]` wikilink, flag when `<target>.md` is absent under the store (the downstream RE-POINT backstop; local-only, no `gh`):

```bash
grep -rlE '\[\[[a-z0-9_]+\]\]' "$MEM" | while read -r f; do
  grep -oE '\[\[[a-z0-9_]+\]\]' "$f" | sort -u | while read -r wl; do
    t="$(printf '%s' "$wl" | sed -E 's/^\[\[(.+)\]\]$/\1/')"
    [ -n "$t" ] || continue
    if [ ! -f "$MEM/$t.md" ]; then
      echo "dangling-wikilink-to-evicted-memory: $(basename "$f") links [[$t]] which no longer exists (re-point or drop per §7 RE-POINT)"
    fi
  done
done
```

**ledger-pointer-to-closed-issue** — scan the `MEMORY.md` ledger section; flag any row tying a resolving-but-CLOSED issue (the upstream partial-absorption backstop; resolution-probing):

```bash
awk '/^## Temporary enhancement pointers/{b=1;next} /^## /{b=0} b&&/^- /{print}' "$MEM/MEMORY.md" | while read -r row; do
  for n in $(printf '%s\n' "$row" | grep -oE '#[0-9]+' | tr -d '#' | sort -u); do
    gh issue view "$n" --json number >/dev/null 2>&1 || continue   # non-resolving = dead-ref's job
    if [ "$(gh issue view "$n" --json state --jq .state 2>/dev/null)" = "CLOSED" ]; then
      echo "ledger-pointer-to-closed-issue: ledger row ties #$n (CLOSED, not evicted) — re-home to a live issue per Phase B-OPS5"
      break
    fi
  done
done
```

`gh` unavailable or unauthenticated ⇒ the three resolution-probing classes (deployed-but-not-evicted, dead-ref tie, ledger-pointer-to-closed-issue) degrade to SKIP (same posture as Check 36); the two local-only scans (untied-encodeable, dangling-wikilink-to-evicted-memory) still run.

## 4. Routing per class

| Class | Routing |
|---|---|
| **deployed-but-not-evicted** | Add the memory to the next release's **Phase B-OPS operational-deployment manifest** (ARCHIVE → VERIFY-CORPUS → EVICT). The corpus write already landed, so this is a clean eviction. |
| **dead-ref tie** | Operator decision: re-tie the pointer to the renumbered issue (if the encode is live) or evict (if the encoding already landed). Do not guess the new number — resolve it from the corpus encoding or the milestone. |
| **untied-encodeable** | File an encode issue (the `improvement.yml` intake) so the rule gets a corpus home; until then the memory legitimately remains the SSOT. |
| **dangling-wikilink-to-evicted-memory** | RE-POINT the surviving memory's `[[wikilink]]` to the corpus location now owning the evicted knowledge (the durable cross-reference form), or DROP the link (leaving prose intact) when the knowledge was split/absorbed with no single citable home. Operator-authorized memory edit (the §7 RE-POINT step), never a deploy-check action. |
| **ledger-pointer-to-closed-issue** | Re-home the stranded memory: re-tie its ledger pointer to a still-open codification issue, or file a new encode issue. The close-time gate (Phase B-OPS5) blocks a release's close until each unmatched memory is re-homed. |

## 5. Reproduce this session's findings (worked run)

The 2026-06-07 memory audit that motivated the contract found shadow-SSOT copies (codified rules held in full in memory) and rotted eviction-pointers (a ledger tied to issues the re-versioning orphaned). To reproduce the *shape* of that finding against the current store:

```bash
MEM="${HOME}/.claude/memory"
# 1) Shadow-SSOT candidates: memory bodies that quote codified governance verbatim
#    (a heading or invariant phrase that also lives in the corpus).
grep -rlE 'No-shadow-SSOT|Universal Preference|core/rules|deploy\.sh Check' "$MEM"
# 2) Rotted eviction-pointers: any #N tie that no longer resolves (run the dead-ref
#    block in §3a). The audit reproduces the finding when it lists the same files
#    the 2026-06-07 session flagged — confirming the procedure detects real drift.
```

A clean store returns no rows from §3a and only legitimate pointers from §5; a drifted store returns the remediation list §4 consumes. Check 36 emits the identical five classes continuously, so this manual run and the standing backstop agree by construction — the fixture self-test (`core/deploy/tests/test_check36_drift_classes.sh`) pins the two reference-integrity detectors against labeled fixtures.

## 6. Composition

This procedure is the audit half of the encode-and-evict contract; the **Stage-13 Phase B-OPS** step (gate `G-CL5`) is the executor half — including the RE-POINT reconciliation after EVICT and the Phase B-OPS5 close-time absorption reconciliation. The two compose exactly as the skill↔reference single-source contract composes its procedure with its enforced-rebuild check: the procedure tells you *what is out of contract*; the executor (operator-authorized, archive-first, VERIFY-CORPUS-gated) brings it back into contract.

## References

<!-- repo-integrity: allow-issue-ref -->

- **Contract:** `core/disciplines/knowledge-architecture.md` §7; **decision:** ADR-029, generalized by ADR-045.
- **Standing backstop:** `core/deploy/deploy.sh` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial); fixture self-test `core/deploy/tests/test_check36_drift_classes.sh`.
- **Executor:** `release/references/pipeline/stage-13-close.md` §5 Phase B-OPS (gate `G-CL5`) + Phase B-OPS5 (close-time absorption reconciliation).
- **Provenance:** see the `## Provenance` block in `knowledge-architecture.md` §7 (the lifecycle's canonical home).
