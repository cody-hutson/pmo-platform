<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- reference-durability: allow-link -->
# Memory↔corpus drift audit

> Standing how-to for auditing the auto-memory store (`~/.claude/memory/`) against the codified corpus for SSOT drift. It is the human-runnable companion to `deploy.sh --check` Check 36 (`memory-corpus-tie-drift`) — run it on demand to reproduce what the standing backstop reports continuously.

**Governing contract:** [`core/disciplines/knowledge-architecture.md` §6 Memory↔corpus boundary](../../../core/disciplines/knowledge-architecture.md#memory-corpus-boundary) (the two-tier SSOT assignment, the no-shadow-SSOT invariant, the encode-and-evict lifecycle). **Decision record:** [ADR-029](../../../core/ADRs/ADR-029-memory-corpus-ssot-boundary.md). **Sibling pattern:** the single-source + enforced-rebuild deploy check on the skill↔reference surface — this is the same idea on the memory↔corpus surface.

---

## 1. Purpose

The memory↔corpus boundary contract assigns codified (toolkit-encodeable) knowledge to the corpus as its single source of truth, and permits the auto-memory store to hold codified knowledge only as a temporary eviction-pointer. Over time three drift conditions accumulate against that contract. This procedure detects all three, reproducibly, so an operator (or a reviewer reading a memory audit) can confirm the store is in contract — or generate the exact remediation list.

The audit is **read-only**. It deletes nothing and edits nothing. Remediation (eviction, re-tie, or filing an encode issue) is a separate, operator-authorized step routed per §4.

## 2. The load-bearing rule — resolution-failure, never digit-match

Re-versioning renumbers issues. An eviction-pointer that cited a given issue number last quarter may now point at a renumbered or retired number. **A dead reference is therefore detected by reference-resolution-failure — never by comparing issue-number magnitude.** Probing whether an issue number is "below the current max" is meaningless: a low number can be live and a high number can be retired. Only a resolution probe (`gh issue view N`) is load-bearing. Every command below probes resolution; none compares digits.

## 3. The three drift classes

| Class | Definition | Detection (reproducible) |
|---|---|---|
| **deployed-but-not-evicted** | a memory's tied issue is CLOSED, the corpus encoding is present on `main`, but the memory file still exists | `gh issue view N --json state` == `CLOSED` **AND** a corpus grep of the encoded phrase succeeds **AND** the memory file is still present ⇒ flag |
| **dead-ref tie** | a memory's eviction-pointer cites an issue # that no longer resolves (re-versioning renumbered it away) | `gh issue view N` returns NOT_FOUND / non-zero (resolution-failure) ⇒ flag. NEVER digit-match |
| **untied-encodeable** | a memory the §1 Q1 classifier marks K1-encodeable, but carrying no issue tie and no corpus pointer | memory body matches encodeable signatures (discipline / reference / methodology / gate / CI) with no `#N` tie and no corpus-path pointer ⇒ flag for operator routing |

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

`gh` unavailable or unauthenticated ⇒ the two resolution-probing classes degrade to SKIP (same posture as Check 36); the untied-encodeable scan is local-only and still runs.

## 4. Routing per class

| Class | Routing |
|---|---|
| **deployed-but-not-evicted** | Add the memory to the next release's **Phase B-OPS operational-deployment manifest** (ARCHIVE → VERIFY-CORPUS → EVICT). The corpus write already landed, so this is a clean eviction. |
| **dead-ref tie** | Operator decision: re-tie the pointer to the renumbered issue (if the encode is live) or evict (if the encoding already landed). Do not guess the new number — resolve it from the corpus encoding or the milestone. |
| **untied-encodeable** | File an encode issue (the `improvement.yml` intake) so the rule gets a corpus home; until then the memory legitimately remains the SSOT. |

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

A clean store returns no rows from §3a and only legitimate pointers from §5; a drifted store returns the remediation list §4 consumes. Check 36 emits the identical three classes continuously, so this manual run and the standing backstop agree by construction.

## 6. Composition

This procedure is the audit half of the encode-and-evict contract; the **Stage-13 Phase B-OPS** step (gate `G-CL5`) is the executor half. The two compose exactly as the skill↔reference single-source contract composes its procedure with its enforced-rebuild check: the procedure tells you *what is out of contract*; the executor (operator-authorized, archive-first, VERIFY-CORPUS-gated) brings it back into contract.

## References

<!-- repo-integrity: allow-issue-ref -->

- **Contract:** `core/disciplines/knowledge-architecture.md` §6; **decision:** ADR-029.
- **Standing backstop:** `core/deploy/deploy.sh` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial).
- **Executor:** `release/references/pipeline/stage-13-close.md` §5 Phase B-OPS (gate `G-CL5`).
- **Provenance:** #530 (parent); Stage 5 spec on sub-task #1298; sibling pattern #316.
