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

## 2.1 Detecting the form — two predicates over two populations

The rule above prevents the corruption where it originates. Detecting it needs
**two** predicates, because the failure has two observable surfaces and neither
one can see the other.

|  | **Call-site predicate** | **Artifact-body predicate** |
|---|---|---|
| Observes | a source line passing an `@`-prefixed value to the *literal-value* parameter | a published body that is a single token beginning with `@` |
| Population | the tracked corpus | the host's work-item and change-request bodies |
| Denominator obtained by | the version-control file listing | the count of artifacts the enumeration returned |
| Catches | the cause, before it runs | the effect, after it published |
| Cannot see | a call issued outside the corpus — an ad-hoc shell, a scratch script, a hand-typed command | a body corrupted by any other mechanism, or any artifact the enumeration did not reach |

**Rule.** Neither predicate subsumes the other, and neither may be reported alone
as "the sweep". A corpus clean under the call-site predicate can still have a
corrupt body published by an untracked call; a body population clean under the
artifact-body predicate says nothing about a call site that has not yet run.

**Call-site predicate — a literal-value parameter carrying a file reference.**
Three properties are load-bearing, and each was chosen against a survey of the
forms actually present rather than invented:

- **Case discriminates.** The type-converting parameter differs from the literal
  one only by case, and it is the *correct* form. A case-insensitive match
  reports every correct call in the corpus as a defect.
- **The field name is not part of the predicate.** The first witnessed instance
  corrupted a description; the second corrupted a body. A predicate bound to one
  field name is blind by construction to the third.
- **Fenced code blocks are excluded** — the same convention the corpus's
  link-resolution primitive already applies. Without it, the WRONG example in
  § 2 above is reported as its own finding and this file cannot document the
  rule it carries.

```
(?<![\w-])(?:-f|--raw-field)[= ]\s*[A-Za-z_][\w.\[\]-]*=@
```

**Artifact-body predicate — a body that is a file reference rather than a body.**
Applied to the published body text, never to the command that posted it: a body
whose whitespace-stripped form is a single token beginning with the sigil, where
the remainder reads as a file reference.

```
^@\S+$   AND   the remainder is '-', or contains '/', or ends in .<1-6 alnum>
```

The file-reference qualification is what separates a lost body from an ordinary
mention, and the stdin token is included because the type-converting parameter
accepts it — so the literal parameter can post it verbatim. **Residual, stated
rather than hidden:** a bare mention whose handle itself ends in a dot-suffix
satisfies this predicate. It is characterised, not eliminated — a matched body
is read before it is called a finding.

**Rule — both predicates report a denominator and two arms; neither reports a
bare zero.** A zero is evidence only when it arrives with:

1. the **denominator**, and how that population count was obtained;
2. a **sensitivity arm** — a seeded positive of each shape the predicate exists
   to catch, observed flagged. The arm is *seeded* rather than borrowed from the
   population, because a healthy population legitimately holds no positive and a
   probe that has never fired has demonstrated nothing;
3. a **specificity arm** — the correct type-converting form carrying the same
   `@` value, and a legitimate literal-value parameter on a non-`@` scalar, each
   observed **not** flagged.

A zero whose sensitivity arm also returned zero is a **broken probe** and is
reported as unusable, not as a clean population (§ 7.2).

**The measured counts belong to the run, not to this file.** Record the
denominator, the arms and the findings in the change's own verification record.
A count written into this section is stale at the next artifact.

## 2.2 What no automated control covers — the artifact-body surface

**Rule.** State the coverage a control actually has. This failure publishes to a
surface the repository's content controls do not read, and a remediation that
implies otherwise is worse than none.

The two controls that scan for personal data both take a **repository**
population, and the division between them is stated in their own configuration:

- the **changed-file content gate** reads the file delta of a change request,
  intersected with the governance domains. Its population is tracked file
  content;
- the **commit-message gate** reads the messages in that same commit range. Its
  own header records why it exists — the content gates never read a commit
  message.

Both are described at [`git-workflow.md`](../rules/git-workflow.md)
§ Repository-Integrity Gates, which is their governed home.

A work-item or change-request **body is neither.** It is host state, not
repository state: it never appears in a file delta and never appears in a commit
message. No content gate can reach it, and no scan of the corpus — scheduled or
otherwise — will ever surface it.

One control does reach the body surface: the agent-side pre-write guard that
reads a posted body (inline, or the file behind a type-converting or body-file
parameter) and refuses a write carrying an operator-local path. **Its limits are
its own, and they are stated where it lives:** it fires only on the agent's own
tool calls, never on a hand-typed command or a web-UI edit; it ships in a warn
posture; it depends on wiring an instance may not have loaded; and it matches a
**path-leak** pattern rather than this failure's mechanism. A body lost to the
literal-value parameter whose path does not match that pattern passes it in
silence.

**Consequence, stated plainly.** The artifact-body predicate in § 2.1 is a
**measurement, not a gate.** It makes a recurrence countable against a stated
denominator. It prevents nothing, it is registered in no verdict, and it must
never be cited as coverage the content gates do not have.

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
- **This file is the durable home for the typed-vs-raw field rule, superseding
  the per-agent behavioral memory that carried it first.** Both incidents above
  were captured as an agent-memory correction before any standard existed; that
  capture is the *bridge*, and this file is the *destination*. Per
  [knowledge-architecture.md](../disciplines/knowledge-architecture.md) § 6, the
  pointer runs one way — a memory entry may hold a temporary pointer to its
  corpus home, and the corpus never points back. The tied memory is evicted once
  this standard ships (encode-then-evict; the corpus write lands first), so the
  rule has exactly one home and cannot drift into a shadow copy.
- The verify-before-recommend discipline in `CLAUDE.md` § Universal Preferences —
  post-mutation read-back is its write-side twin. That rule says verify against
  the canonical source before acting on a claim; this one says verify against the
  canonical source before believing your own write.
