---
title: Reference Durability Standard
purpose: The standard requiring durable-corpus files to survive repo migration, milestone renumbering, and history rewrites — the reference-form ladder, the self-containment test, and the override-marker allowlist.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the reference-durability PreToolUse hook (Write/Edit on durable-corpus paths); deploy.sh reference-durability check; the reference-durability CI workflow; every author of governance/standard/spec/discipline/schema/SKILL.md content
---
# Reference Durability Standard

## Purpose

Durable-corpus files — governance rules, standards, specs, disciplines, schemas, skill SKILL.md files, and committed release-plan files — must survive the events the platform actually performs: repository migration, milestone re-bundling and renumbering, and history rewrites. A reference that resolves today but breaks on a renumber is a latent defect baked into the corpus. This standard codifies how to author a reference so it survives those events, and defines the enforcement primitives that catch fragile references at authoring time.

The governing rule, stated unconditionally: a durable-corpus entry must read completely on its own, carry no markdown link sequence, and carry no release-version or version-cutover apparatus as a load-bearing reference. When a banned reference is needed for meaning, rewrite it as an inline summary — remove it, do not relegate it to a footnote.

## The durability ladder

When an author needs to reference other information, prefer the highest rung that still carries the meaning. Higher rungs survive more of the events the platform performs.

| Rung | Form | Why it is durable | Guidance |
|---|---|---|---|
| 1 (most durable) | Prose rule — state the rule unconditionally, inline | survives every rename, renumber, and migration; reads on its own | Preferred everywhere. Example: "All changes go through PRs — no direct commits to the main branch." |
| 2 | Self-describing boundary — name the concept or file by its content | a renamed file is re-findable by its described role | Example: name "the spoke-commit-discipline rulebook" rather than a path. |
| 3 | Registry entry — point to a catalog row keyed by a stable name | the catalog is the indirection that absorbs churn | Example: "the token's row in the operator-instance vocabulary table." |
| 4 | Version label — a release identifier as a narrative marker | survives a renumber only if the git log corroborates; rots in rule text | Acceptable in release notes and release plans as a narrative identifier; banned as a load-bearing reference in governance rule text. |
| 5 | Issue number — a bare issue reference | breaks on renumber and migration; resolving-today is a separate property | Confine to a designated reference block, and summarize the referenced content inline so the meaning survives even if the number does not. |
| 6 (least durable) | Commit hash or repository URL | breaks on any history rewrite or repository move | Provenance footnote at most; never load-bearing. |

The ladder is a preference order, not a permission list. Rungs 4 through 6 are progressively fragile; use them only when no higher rung carries the meaning, and always pair a low-rung reference with an inline summary so the prose still reads if the reference rots.

## The self-containment test

A durable-corpus entry passes the self-containment test when all of the following hold:

- It contains zero markdown link sequences.
- It contains zero release-version or version-cutover apparatus used as a load-bearing reference.
- It reads completely on its own — an operator who cannot resolve any external reference still understands the rule.

Generic, version-agnostic placeholders inside code spans (for example a release-plan filename template written with a bracketed placeholder for the version segment) are version-agnostic and acceptable — they name a shape, not a specific release. State every rule unconditionally: a durable rule does not carry a version-cutover clause in its own text, because the clause itself is a fragile reference that rots on renumber.

Removal, not demotion: when a reference fails the test, rewrite it as an inline summary at rung 1 or 2. Do not move a fragile reference into a footnote and call it resolved — the footnote is still fragile.

## The flagged classes

The detector flags three classes wholesale plus one positional rule. It deliberately does NOT attempt to classify an issue reference as inline-grammar versus provenance-footnote — that classification cannot be separated lexically with acceptable precision, so the detector never makes it.

### Class L — markdown links

Any markdown link sequence on a net-new or modified line in a durable-corpus file is flagged, except inside a fenced code block (the detector strips fenced blocks before scanning). The remediation is to summarize the linked content inline (rung 1–2) or, when an external reference is genuinely required, to declare a per-file override marker.

### Class V — version-cutover apparatus

The version-cutover idiom — the prose that says a rule applies to releases after a given version, or that a given version is itself exempt — is flagged. This is the apparatus the platform is removing from durable rule text, because it rots on renumber. The Class V detector keys on the cutover idiom by its semantic phrasing, not on a fixed column position, and bounds its proximity window so that a benign sentence mentioning a version number does not match. A line that merely names a current version in passing is not cutover apparatus and is not flagged.

### Positional issue-reference rule

A bare issue reference is permitted in a durable-corpus file ONLY inside a designated reference block. The recognized block headers are an "Issue References" heading, a "References" heading, a "Related" heading, a "Provenance" heading, or a "Source" / "Sources" / "Source(s)" heading, at any heading level. The match ends at the heading word, so a heading that continues past it — "Related ADRs" is the one that matters in practice — is NOT a recognized block: a bare issue reference is prohibited under that heading outright, and cross-ADR links use the ADR identifier form instead. An issue reference appearing OUTSIDE a recognized block is flagged as misplaced.

Inside a reference block, an issue-reference line must additionally be self-describing: it must carry a summary noun phrase alongside the bare number, so the referenced content survives even when the number rots on renumber. A reference-block line that contains a bare number with no accompanying summary is flagged — this operationalizes the ladder's rung-5 "summarize content inline" requirement, which no other primitive enforces. The self-describing check is a line-shape heuristic (is there enough non-number content on the line), not a semantic classifier — it stays out of the inline-versus-footnote distinction the detector refuses to make.

This positional rule gives the durability discipline intrinsic coverage of the issue-reference class. It composes by position with any separate issue-reference-validity gate: the validity gate asks whether a reference resolves today; this rule asks whether a reference is placed and summarized so it survives a renumber. The two are disjoint properties and both run.

### Class U — raw ledger URLs

A raw GitHub issue, pull-request, or milestone URL — the `github.com/<owner>/<repo>/issues/<id>` form and its `pull` and `milestone` siblings — is the durability ladder's least-durable rung: a repository URL that breaks on any history rewrite or repository move. It is flagged on a net-new or modified line in a durable-corpus file. The detector keys on the `{issues,pull,milestone}` path-segment set after any owner and repository name, and anchors the segment so a bare repository URL with no third path segment does not match. The remediation is to summarize the referenced content inline (rung 1–2) rather than carry the URL, or, when an external reference is genuinely required, to declare the per-file override marker.

The ref-permitted ledger surfaces — the five named in the universal-vs-release-pipeline split rule — are categorically exempt from this class: a ledger URL is native provenance on those surfaces, exactly as a bare issue reference is. The exemption is a path property, not a per-file marker, mirroring how the sibling validity gate exempts the release-tracking tree. Class U ships warn-mode-initial: a finding is reported but does not fail the gate until the operator's flip-to-enforce at a release close.

## The override-marker and allowlist mechanism

Because the flagged classes are flagged wholesale, the escape valves are path-based and marker-based, NOT grammar-based.

### Per-file override marker

A durable-corpus file that legitimately needs a flagged construct — for example an external upstream-catalog link that genuinely cannot be summarized inline — declares a per-file override marker once, as an HTML comment anywhere in the file. The markers are:

```
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-url -->
```

A present marker suppresses the corresponding class for that file: matches are still reported for visibility, but they do not fail the gate. The `allow-url` marker suppresses Class U; it is distinct from `allow-link` so a file that legitimately carries summarized links does not silently also suppress the raw-URL prohibition. This mirrors the parser-clean override pattern. A marker is a deliberate, auditable declaration that a specific file needs a specific class — it documents why the file carries the construct, not a wish to silence warnings.

### Path allowlist

The path allowlist is authored at `core/config/allowlists/reference-durability-allowlist.txt`: one glob per line, a leading `#` introduces a comment, and a trailing slash matches a directory. That repo path is the single source an author edits, and it is what the CI gate and the deploy-time saturation check both read directly.

The PreToolUse hook reads a different copy. It is a hook-tier composition surface, so the installer writes it to the workspace agent-config root — `<workspace>/.claude/reference-durability-allowlist.txt` — and the hook resolves it there at runtime, beside the other hook allowlists. Two consequences follow. First, an edit to the repo file does not reach the hook until the composition surfaces are reinstalled; `./update.sh` does that, and the skill/harness deploy path deliberately does not. Second, the deployed copy is regenerated from the repo file, so an operator who edits the deployed copy in place loses that edit on the next install — author in the repo, then reinstall. Seed entries cover historical-by-design corpus (the release archive) and files that are link-resolution maps by design. Allowlist additions document why the path is exempt — the rationale records the structural reason the path carries flagged constructs, not a desire to silence the gate.

## Enforcement primitives

Three primitives enforce this standard, all warn-mode-initial per the harness shakedown-to-enforce ladder.

| Primitive | Surface | Posture |
|---|---|---|
| Agent-harness hook | PreToolUse on Write and Edit to durable-corpus paths | warn-mode-initial via the shared harness mode file; logs to a per-hook warn-log; in enforce-mode blocks with a teaching message |
| Deploy-check check | the deploy-check run | warn-mode-initial via the deploy-check mode file; reports the saturation snapshot via the standard warn-or-issue helper |
| CI workflow | every pull request; the job's path predicate selects which changed files to scan | scans added lines only (the net-new delta), so pre-existing corpus does not fail an unrelated PR; fails on net-new violations |

The hook and deploy-check report the current saturation; the CI workflow is the gatekeeper that enforces the delta — no NEW fragile references versus the base. The hook honors a per-hook mode file and a per-hook warn-log so hook-time and deploy-time logs stay separate, matching every existing harness hook.

### The flagged-class patterns

The patterns are tuned during the warn-mode shakedown and validated against a checked-in corpus fixture with a labeled expected-match set, so precision is measurable rather than asserted. The fixture pairs true cutover clauses drawn from the real corpus with benign-prose negatives, and the hook plus check self-test asserts the match-set. Flip-to-enforce is gated on the fixture passing — a clean warn-log alone is insufficient, because a warn-log records only matches and is therefore blind to false negatives.

## CI trigger scope

The CI workflow runs on every pull request. It carries no path filter on its trigger. The decision about which changed files to scan is made inside the job by the durable-corpus path predicate, not by a trigger-level filter. When a pull request changes no durable-corpus file, the predicate selects nothing, the scan is empty, and the job completes successfully.

This matters because the workflow's job is a required status check on the main branch. A required check must report a result on a pull request, or the platform treats the check as required-but-absent and refuses to merge even when every other check is green. A trigger-level path filter would skip the workflow entirely on a pull request that touches only non-corpus files, so the required check would never report and the pull request would be blocked. Running on every pull request guarantees the required check always reports: it passes as an empty scan on a pull request outside the durable corpus, and it scans normally on a pull request that touches durable-corpus files. The selection behavior for durable-corpus pull requests is unchanged, because the path predicate inside the job is the single place that decides what gets scanned.

A common close-out scenario makes the difference concrete. A release close-out pull request edits the release log, the release notes, and the release index — files that sit outside the durable corpus and legitimately carry bare issue references that a separate issue-reference-validity gate handles. The durable-corpus path predicate excludes those files, so this workflow scans nothing and passes as an empty scan, while the required check still reports the result that lets the close-out pull request merge.

## Reference durability versus link resolution

Reference durability is a distinct discipline from link resolution. The two are orthogonal and both run; neither subsumes the other.

| Discipline | Owns | Question it answers |
|---|---|---|
| Link resolution (the doc-link maintenance protocol plus its deploy-check check) | does a markdown link resolve to a file that exists? | Is this link alive today? |
| Reference durability (this standard plus its hook, deploy-check check, and CI workflow) | should this reference exist at all in durable corpus, given it will break on renumber or migration? | Will this survive a rename, renumber, or migration? |

A link can be perfectly resolvable today (it passes the link-resolution check) yet be a durability violation (it fails this standard, because the rule is to summarize inline rather than link). Conversely a durable inline summary has no link to resolve. The link-resolution discipline polices link liveness; this standard polices whether a fragile construct belongs in durable corpus at all.

## Reflexive applicability

This standard governs the durable corpus, which includes the files that ship this standard itself. Every file that introduces or edits durable-corpus content is authored self-contained from the start — the standard must not be violated at the moment it is born. Authors of durable-corpus content read this standard before authoring, summarize inline rather than link, and confine any unavoidable low-rung reference to a designated reference block with an inline summary.

## Authoring around the gate (Stage 6 pre-check)

An author about to write or edit durable-corpus markdown applies four checks BEFORE the first write, so the content is clean at birth rather than fixed after a red gate. These are the author-time twin of the detector's flagged classes — the detector catches them at commit and pull-request time, but the cheaper moment is authoring time.

- **No numeric section-anchor deep-links.** A deep-link whose fragment is a numbered heading slug — a link target of the form `file.md` followed by a `#` and a numbered-heading anchor — rots the moment the heading is renumbered or reworded. Use a plain file link and name the target section in prose instead ("the durability-ladder section of the standard"), so a re-heading leaves the reference intact.
- **Spell out checklist-item references in prose.** Reference a list item by its worded position ("criterion 3", "the third rung") rather than a hash-prefixed positional number, so the reference survives a renumber of the list. A bare positional number is a latent defect baked against the current ordering.
- **No bare issue-number example numbers in prose.** When illustrating a construct, write "for example, an issue reference" rather than dropping a hash-prefixed literal number into running prose. Note that the detector strips fenced code blocks before scanning but does NOT strip inline code spans — so a hash-prefixed number is flagged even inside single-backtick spans; the durable form is to name the construct in words rather than show a literal instance of it.
- **Know the one construct that has no escape marker.** The per-file override markers — the `allow-link`, `allow-version-ref`, and `allow-url` HTML-comment markers — suppress their own classes for a file that legitimately needs them. The positional issue-reference rule has NO such per-construct override: a bare issue reference appearing OUTSIDE a recognized reference block (an "Issue References", "References", "Related", "Provenance", or "Source"/"Sources"/"Source(s)" heading) cannot be marker-suppressed. The only remedy is to rewrite it inline — move it into a reference block with a summary noun phrase, or de-reference it in prose so the meaning survives without the number.

These checks compose with the durability ladder above: each is the author-time application of preferring the highest rung that still carries the meaning, applied to the specific fragile constructs the detector flags.
