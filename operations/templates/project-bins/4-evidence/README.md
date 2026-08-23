# 4-Evidence/ — raw captured evidence (transcripts, emails, exports)

The original captured record for the project: meeting transcripts, email forwards, and raw exports. This is the source layer downstream trackers and syntheses cite. Consolidates the legacy Transcripts and Emails folders under one evidence bin.

**What lands here:** meeting transcripts (AM/PM testing, daily connects, weekly status, touch-base, steering); email forwards and comms digests; raw source exports.

**Sub-folders:** `Transcripts/` (AM-Testing, PM-Testing, Daily-Connects, Weekly-Status, Touch-Base, Topic-Sessions) · `Emails/`.

**Auto-write:** Yes (active project) — raw evidence routes without an approval gate. A cross-project write is always approval-gated.

**Extraction:** raw evidence routed here **triggers** the raw→tracked extraction — PPM Agent extracts decisions/actions/risks, tracker-manager writes the `source_inputs`/`source_ref` back-link, and the raw artifact carries a `GENERATES` edge to the entries it produced.

_Orientation only. Routing authority is `operations/skills/file-router/SKILL.md` (+ `references/routing-patterns.md`). This card is a derived view; if it ever disagrees with file-router, file-router wins._
