---
title: gh api Convention — Typed-Field Writes and the Silent-Success Class
purpose: The field-write correctness discipline for agent-issued host-API calls — the two witnessed degenerate-value forms that a host API accepts and reports as success, the two pre-write guards that prevent them, and the post-mutation read-back that detects them.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: any agent session issuing a field write against the repository host (release-pipeline spokes at Stages 2, 6, 12, 13; intake and triage skills that mutate work-item fields; release-support tooling under release/tools/)
---
<!-- reference-durability: allow-link -->
# gh api Convention — Typed-Field Writes and the Silent-Success Class

**Origin:** two witnessed incidents (2026-05-27, 2026-08-06) sharing one signature — process-protocol codification of a rule previously held only as a per-agent behavioral memory.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Primary consumer:** any agent session that writes a field on a work item, milestone, or comment through the repository host's API.

> **Scope note — §4.1 adjudication (read this before reading the commands).**
> Every host command in this file is an **illustrative worked example** of a
> rule stated host-agnostically, per the §4.1 detection-signature exclusion (b)
> in [knowledge-architecture.md](../disciplines/knowledge-architecture.md#host-binding-leakage-class).
> This file does **not** specify the field-write *capability* — that belongs
> behind the `operator.toml [adapters]` seam. It specifies a **failure mode and
> a verification discipline**, which are host-agnostic properties. Each numbered
> section states its rule first, without naming a tool; the fenced blocks that
> follow record what one host's tooling was observed to do. Read the rule as
> binding and the command as an example.

## 1. The silent-success class

A field write can accept a **degenerate value** — a value that is syntactically
acceptable but semantically empty or unresolved — and still report success. The
write lands. The wrong content lands with it.

Both witnessed forms share one signature, and all three signals hold at once:

| Signal | What is observed |
|---|---|
| Exit status | `0` |
| Modification timestamp | `updated_at` moves |
| Field content | wrong |

Nothing in the response distinguishes a correct write from a corrupt one. The
success indicators are all present and all true — the call *did* succeed; it
succeeded at writing the wrong thing.

**Rule.** A field write's exit status is not evidence that the field holds the
intended value. Treat a successful write as an unverified claim until a
post-mutation read-back confirms the content (§ 6).

## 2. Form 1 — the unexpanded file-reference literal

**Observed 2026-05-27.** A milestone description was set from a file. The call
returned success and the description was replaced with the literal string
naming the file's path, not the file's contents. The corruption surfaced only
when a structural verification returned zero content markers.

**Rule.** When an interface offers both a *literal-value* parameter and a
*type-converting* parameter, only the type-converting one dereferences a file
reference. The literal parameter writes the reference itself as the value — it
has no error condition to report, because passing the string through verbatim is
exactly what it is for.

```bash
# WRONG — raw-field flag. Writes the literal string "@/path/to/body.md".
gh api -X PATCH repos/:owner/:repo/milestones/N -f description=@/path/to/body.md

# RIGHT — typed-field flag. Reads the file and writes its contents.
gh api -X PATCH repos/:owner/:repo/milestones/N -F description=@/path/to/body.md
```

## 3. Form 2 — the empty-from-unset variable

**Observed 2026-08-06.** A work item's milestone field was set from a shell
variable. The variable was empty. The API accepted the empty typed field,
**cleared** the field, and returned success — silent data loss, not merely
silent corruption.

The variable was empty because the lookup that populated it silently missed: the
population held 201 milestones and the query capped at 100 per page, so the
match sat past the cap and read as a genuine absence. One unpaginated read
became one cleared field, with a success status at every step.

```bash
# WRONG — $NUM is empty; the field is silently CLEARED.
gh api -X PATCH repos/:owner/:repo/issues/N -F milestone=$NUM
```

**Rule.** A degenerate value reaching a typed field is a *composition* failure,
not a call failure: the write is only as sound as the read that fed it. Both
halves need a guard — § 4 covers the value, § 5 covers the lookup.

## 4. Preventive rule 1 — guard the value before the write

**Rule.** Validate that a variable is non-empty *before* it becomes a
typed-field value. The check belongs at the call site, ahead of the write — not
in the error handling, which never fires.

```bash
[ -n "${NUM:-}" ]   || { printf 'refusing: NUM is empty\n'    >&2; exit 1; }
[ -s "$BODY_FILE" ] || { printf 'refusing: body file empty\n' >&2; exit 1; }
```

The file guard is `-s`, not `-f`: an existing-but-empty file passes an existence
test and then writes an empty field, which is Form 2 arriving by a different
route.

## 5. Preventive rule 2 — paginate the lookup that populates the value

**Rule.** Paginate any lookup that populates a typed-field value. A default page
cap truncates silently, so a miss past the cap is indistinguishable from a
genuine absence — and an absence, assigned to a variable, is Form 2.

```bash
# WRONG — default page cap; a match past the cap reads as "not found".
gh api "repos/:owner/:repo/milestones?state=all" --jq '.[] | select(.title=="'"$SLUG"'") | .number'

# RIGHT — paginate, so the denominator is the whole population.
gh api --paginate "repos/:owner/:repo/milestones?state=all" --jq '.[] | select(.title=="'"$SLUG"'") | .number'
```

This is the field-write consequence of the batch-query truncation rule in
[git-workflow.md](../rules/git-workflow.md) § Batch CLI Query Limits: that
section governs *reading* a truncated set; this one governs what happens when a
truncated read is then *written* somewhere.

## 6. Mandatory post-mutation read-back

**Rule.** Re-read the mutated field after every write and assert its content
structurally. Assert two things, not one: that the expected content is
**present**, and that no degenerate-value residue is **absent**.

**Worked example — the correct form, applied before this standard existed.** A
milestone-description write in the release that produced this document carried
a non-empty size guard *before* the write and a structural read-back *after*,
asserting content markers present and zero unexpanded-file-reference residue. It
is the positive exemplar for § 2, § 4 and § 6 simultaneously.

```bash
BACK=$(gh api "repos/:owner/:repo/milestones/N" --jq '.description')
printf '%s' "$BACK" | grep -q 'Release Outcome Statement' \
  || { printf 'read-back FAILED: expected marker absent\n' >&2; exit 1; }
printf '%s' "$BACK" | grep -q '@/' \
  && { printf 'read-back FAILED: unexpanded file-reference residue\n' >&2; exit 1; }
```

## 7. A read-back is only as good as its probe

A read-back that reports the wrong answer is worse than none — it converts an
open question into a false certainty. Three failure modes have been observed,
and each is a property of the *probe*, not of the write.

### 7.1 Wrong shape — a substring match from the wrong context

A claim that a version row existed in a ledger was checked with a plain
substring search. It matched **prose** elsewhere in the same file and returned a
false positive; the row itself was absent. The probe had to be re-shaped to
match the table row that actually carries the fact:

```bash
grep -cE '^\| v4\.15'   # anchored to the row structure, not to the token
```

**Rule.** Match the structure that carries the fact — a table row, a field
value, a heading — never a bare substring that may appear in any context.

### 7.2 Unproven sensitivity — a zero that could never have been non-zero

A comment write was verified with a case-sensitive search for
`version-independent` while the text read `Version-independent`. The search
returned zero and read as *content missing*. The content was present.

**Rule.** A zero is evidence only when the probe's **sensitivity arm** has been
run — a control that must return non-zero, proving the probe can fire at all. A
zero from a probe whose sensitivity was never demonstrated is not evidence of
absence; it is no evidence.

### 7.3 The shell can mangle the probe itself

In zsh, a `revision:path` argument passed unbraced has the `:r` history modifier
applied to it — the command silently mangles the path or fails, and the result
reads as a missing file rather than a malformed request. Brace-delimiting the
variable is required:

```bash
git show "$REV:release/references/pipeline/stage-06-engineering.md"    # zsh applies :r — silent mangle
git show "${REV}:release/references/pipeline/stage-06-engineering.md"  # correct
```

**Rule.** The verification command is as susceptible to silent misbehavior as
the mutation it checks. Verify the verifier: run its sensitivity arm, and read
its output rather than its exit status.

## 8. Validate operands before writing — the structural answer

**Worked example — the contrast case.** A pipeline-event append tool
**rejected** two calls outright: one for an unescaped field delimiter in the
payload, one for exceeding a 300-character field limit. Neither call could
produce a silent-success failure, because neither call ran. The refusal was
immediate, loud, and attributable.

**Rule.** This failure class lives precisely where operand validation is absent.
A tool that validates its operands *before* writing converts a silent corruption
into a loud refusal, and removes the class rather than mitigating it. When a
field write is issued repeatedly, put it behind a validating wrapper rather than
restating § 4 and § 5 at every call site — a guard that must be remembered at
each site will eventually be forgotten at one.

## 9. References

- [git-workflow.md](../rules/git-workflow.md) § Batch CLI Query Limits — the
  batch-query truncation rule whose failure feeds § 5. That section governs the
  read; this file governs the write that consumes it.
- [knowledge-architecture.md](../disciplines/knowledge-architecture.md#host-binding-leakage-class)
  § 4.1 — the host-binding leakage class this file is adjudicated against, and
  the exclusion (b) under which its worked examples are legitimate.
- Agent memory entry `feedback_gh_api_typed_vs_raw_field.md` — the per-agent
  behavioral record this standard supersedes as the durable platform-level home.
  The memory entry is the bridge; this file is the destination.
- The verify-before-recommend discipline in `CLAUDE.md` § Universal Preferences —
  post-mutation read-back is its write-side twin. That rule says verify against
  the canonical source before acting on a claim; this one says verify against the
  canonical source before believing your own write.
