This is a spawned Claude Code session — you have no memory of
the hub. The hub session will consume your output from the
sub-task comment after you finish. Stay within scope and do
not spawn additional spokes yourself.

You are executing Stage 8 (QA Testing) for
#7959 in Milestone work-nature-and-axis-model (cody-hutson/pmo-platform). Your sub-task is #7974.
**Invocation model parameter (stated by the hub):** `opus`.

Environment: no `gh` CLI; reach GitHub through the GitHub MCP tools (`mcp__github__issue_read`,
`mcp__github__pull_request_read`, `mcp__github__get_commit`, `mcp__github__list_commits`,
`mcp__github__search_issues`, `mcp__github__search_pull_requests`, `mcp__github__add_issue_comment`;
load each with ToolSearch `select:<name>` if it is not loaded). Large tool results are saved to files;
read them by character slices. A repo tool that shells out to `gh` runs with a fixture or connector
substitute, recorded as a deviation. This environment has no `pipeline-event-log.md`; list the event
rows you owe in your output. The local clone is shallow (its history starts 2026-06-05); read an
absent commit through `mcp__github__get_commit`.

**This stage has two parts, in a fixed order.** Part 1 is a blind re-code that must finish before
you read anything about this release. Part 2 is the acceptance review. The read order below is split
accordingly. **Do not read ahead of Part 1's boundary**, even to plan Part 2.

Read these first (Part 1 needs only these):
1. README.md (repo overview)
2. core/rules/ (all files)
3. Sub-task #7974's **body only** (not its comments)
4. This brief in full, including the codebook it carries

Read these only after Part 1's codes are hashed (Part 2):
5. Issue #7959 (graded body revision 2026-09-27T23:01:38Z; AC-1..AC-6) and its comments
6. release/references/pipeline/stage-08-qa-testing.md (the canonical checklist: § 5 Phases A–E, § 6 Outputs)
7. core/skills/pmo-qa-auditor/SKILL.md § Mode H — Acceptance Review and § Mode H — Acceptance Report, core/skills/pmo-qa-auditor/references/acceptance-review-mode-spec.md, core/skills/eval-writer/references/acceptance-assertion-type.md, and operations/templates/qa-acceptance-report-template.md — your method (the skill is not deployed in this session; apply it from the repository text)
8. The Stage 7 output on #7973 ({{S7_COMMENTS}}), whose `### Output for Stage 8` is your DT→QA Handoff Payload, and the hub's routing record on #7973 if one is present
9. The change under acceptance: draft PR #8004 at head `{{HEAD}}` and its three files at that head — `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md`, `core/standards/gate-efficacy-standard.md`, `release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md`
10. The Stage 6 output on #7972 (comments 5861342230, 5861372837, 5861382523) and the hub's verification record there (5861464095)
11. The design and its binding amendments: #7971 comments 5858980491, 5859002126, 5859019340 and 5860663381

## Persona
