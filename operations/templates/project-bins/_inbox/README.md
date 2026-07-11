# _inbox/ — the single drop point

Every file arriving for this project lands here first. `_inbox/` is the **only** documented drop point; file-router classifies each file and routes it into a closed-set bin (`1-Governance`, `2-Delivery`, `3-Operations`, `4-Evidence`, `5-Reference`) on a confident match.

**`_unsorted/`** — the no-match / low-confidence hold. A file that file-router cannot confidently classify is **held here and flagged, never guessed** into a bin. Items in `_unsorted/` await operator review (tracked in `_unsorted/_queue.md`).

**Post-sweep state:** after a daily sweep run, `_inbox/` is empty except for `_unsorted/` — every confidently-classified file has been routed out, and only the flagged holds remain.

This is a transient control folder, not a content bin — it has no `manifest.yml`. Routing authority is `operations/skills/file-router/SKILL.md` (+ `references/routing-patterns.md`).
