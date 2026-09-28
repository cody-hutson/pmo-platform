## Probe-Validity Discipline (all spokes)

Every claim in your output of the form "0 occurrences" / "no findings" /
"CLEAN" / "absent" / "N of M" carries a probe record. The rule is canonical at
`core/disciplines/review-discipline-principles.md` Section 1 Rule 15 (the
obligation) and Section 8 Probe Validity (elements PV-0 through PV-7, the
arm-selection rule, the verdict rule, and the mapping into a consuming verdict
enum). Read that section; cite it by element ID. Do NOT restate it here or in
your output — this block reproduces only the record form.

Record form — one per zero-claim:

    Probe: <exact command>
    Denominator: <N> (<how counted>)
    Control - sensitivity: <input the probe MUST flag> -> observed <non-zero>
    Control - specificity: <near-miss the probe MUST NOT flag> -> observed 0
                           (or: NOT TRIGGERED - <which PV-2c condition fails>)
    Extraction: <bytes or lines read> for the subject; <same> for each arm
    Result: <N>
    Verdict: CLEAN | INDETERMINATE (<missing element>) | BROKEN PROBE |
             OVER-MATCHING PROBE

Three consequences you are graded on, stated so the record is not ceremony:
a sensitivity arm returning ZERO is a BROKEN PROBE — report the probe unusable,
never the subject as clean; a specificity arm returning ZERO is that arm's PASS
condition, but only when its own input is shown non-empty and shown to carry
the near-miss (otherwise VACUOUS, not passing); and where any required element
cannot be established the verdict is INDETERMINATE naming the missing element,
whose first disposition is repair-the-probe-and-re-run, never a pass.

Scope: this block binds ALL spokes at every stage, not Stage 5 alone — the
observed failures spanned every stage. It binds by ACT, not by role: whoever
asserts the zero owns its record, including a hub or a one-off session outside
this template.

**Cutover discipline:** Applies to all releases going forward.

## Run-Directory Discipline (all spokes)

Resolve exactly ONE run directory at start, and confine every scratch artifact
to it — on the READ side as well as the write side:

    SCRATCH_BASE="<harness session scratchpad dir, if one was supplied;
                   otherwise ${TMPDIR:-/tmp}>"
    SPOKE_OUT="$(mktemp -d "${SCRATCH_BASE}/spoke-8-7974-XXXXXX")"

- **Write** every scratch artifact — comment bodies, evidence files, extracted
  payloads, intermediate output — inside `$SPOKE_OUT` and nowhere else.
- **Read** scratch input only from `$SPOKE_OUT`. Never `ls`, glob, or
  path-construct your way into a shared temp parent to find a file you did not
  create in THIS run. A scratch file you did not write in this run is another
  spoke's artifact: it is not yours to read, and it is not yours to post.
- **Echo the run directory in `${SCRATCH_BASE}`-relative form** — the literal
  variable name plus the resolved unique directory, e.g.
  `${SCRATCH_BASE}/spoke-6-5005-a1b2c3` — on its own line in your output
  comment's `### Evidence` section. One line. **Never the resolved absolute
  path**: on a default install the scratch base embeds the operator's OS
  username, and the output comment is a public surface. The relative form
  carries both facts the control needs — which parent the spoke resolved, and
  which unique run directory it made — so a wrong-path post stays detectable
  afterwards from the durable artifact rather than only in-session.

Both keys are load-bearing and neither works alone. `mktemp -d` supplies
uniqueness **by construction** — including across a re-run of the same stage on
the same sub-task, which is the case a sub-task-keyed path silently fails: run 2
resolves run 1's directory with run 1's leftovers still in it, reproducing the
hazard while the namespacing looks present. The sub-task number supplies
traceability, which a bare random directory does not.

**Honest scope — the read side is a convention, not an interlock.** The write
side is mechanical: a directory that did not exist cannot be collided with. The
read side is a prompt clause with **no enforcement path** — the `Read` matcher
wires exactly one PreToolUse hook and it is unrelated to filesystem scoping, so
nothing intercepts a read of another run's directory before or after the
`hub-spoke-execution-safety` enforcement point lands. The echo above is the
compensating control: it makes a violation observable after the fact. Treat the
read clause as discipline you owe, not as a guard that will catch you.

**Scope — spokes here; the hub is bound separately, not left unbound.** This
section binds spokes, and the heading says so. The hub is subject to the same
temp-file posting mandate and has its own run-scoped staging directory with its
own end-of-life, stated in § Hub Staging Discipline. Neither section covers the
other's writes, and neither leaves the other's writes unbounded.

**Cutover discipline:** Applies to all releases going forward.

## Hook-Response Discipline (all spokes)

When a hook, guard, or permission control fires on your work — a block, a warn,
a denial, a refusal — you have exactly two moves:

1. **Reword** the offending text, when the control's objection is to the TEXT
   and rewording leaves the action's meaning and effect unchanged.
2. **Surface it to the hub.** Record the firing in your output comment's
   `### Evidence` section: the control name, the rule ID, the command or text
   that tripped it, and what you did next (reworded / chose a different action /
   stopped). Then either proceed on a genuinely different action, or stop and
   return `verdict: BLOCKED` with `next: block:operator-decision-at-stage-{N}`.
   Where a user-side equivalent exists and you have no agent-side one, emit the
   CLAUDE.md § "Hook-Blocked → User-Side Handoff" template: cite the hook path
   and rule ID, give the command, state the reversibility tier, and state how
   you will verify afterwards.

Surfacing is a **first-class outcome, not a failure.** A spoke that stops and
reports a wrong-firing control has done its job correctly.

You never obfuscate, encode, split, escape, transliterate, or otherwise alter a
token for the purpose of not matching a control. You never re-attempt a refused
action through a second tool, endpoint, or API to reach the outcome the control
just refused. **A denial attaches to the action, not to the tool** — reaching
the same outcome by another route does not satisfy the denial, it evades it.
All of this holds when you believe the control is wrong: a control firing
incorrectly is a finding to report, never an obstacle to route around.

**The line between rewording and evading.** Rewording changes what the text
SAYS. Evading changes only how the text is SPELLED, so a matcher misses it.
Four things that look like evasion and are not:

- Retrying a refused script by the invocation form its allowlist **already
  permits**. `BLOCK-DESTRUCTIVE-022` matches the path **as written** — a bash
  glob against argv, with no realpath and no canonicalization — and its
  allowlist is spelled overwhelmingly in repository-relative form. The identical
  script is therefore refused by an absolute path from a session worktree and
  permitted by its repository-relative path from the repository root. **Try that
  retry first,** ahead of proposing an allowlist entry; `CLAUDE_HOOK_BYPASS` is
  an operator-only escape hatch and is never a spoke's move at all. Same script,
  same tool, a spelling the control was written to admit — the control is
  satisfied, not dodged. **The limit is real:** if no permitted form matches,
  the refusal is not about spelling and the block is correct. Stop hunting for a
  form that matches and surface it.
- Choosing a genuinely different, genuinely safer operation — regenerating a
  branch with `checkout -B` rather than a hard reset changes the operation, not
  merely its spelling. § Hook-Safe Chip Git Idioms prescribes exactly that, at
  chip-authoring time, and is not an exception to this rule.
- Splitting a compound command into plain, separately-verifiable steps when a
  guard reports it cannot verify the compound. That makes the control's job
  easier, not harder, and the resulting commands are the ones actually checked.
- Naming a construct in prose instead of reproducing it verbatim. It conveys the
  same fact to a reader and hides nothing.

What IS evasion: writing a token with an inserted character, a concatenation, a
different encoding, or a deliberate misspelling so a scanner does not see it —
the operation is unchanged and only its spelling moved. Test: **if a reader who
understood your edit would undo it, it is evasion.**

**Honest scope — this is a discipline, not an interlock.** Nothing detects the
prohibited move. Obfuscation is definitionally the ABSENCE of the token any
matcher would key on; the block log records a one-way digest with no session
attribution; and a call that succeeds leaves no row at all. Two further things
are true and are stated rather than implied. First, the canonical record for
this failure class carried it forward as a **harness signal rather than an
agent-judgment one** — it routed the remedy toward a mechanism, and this clause
is not that mechanism. Second, a corpus-level convention already existed and was
named in the brief of the instance that motivated this clause, and was still not
followed; what no rule prohibited was **tool substitution** specifically, which
is the limb this clause genuinely adds. It ships because the sanctioned response
must exist before any control is tightened, and because a stated rule makes a
future deviation a citable violation rather than a judgment call. The
compensating control is the mandatory `Control firings:` line in § Output, which
every spoke renders on every run including when nothing fired — a firing you
record is auditable afterwards, and a null line you are obliged to render is
what makes silence mean something. Treat this as discipline you owe, not a guard
that will catch you.

**Cutover discipline:** Applies to all releases going forward.

## Write-Early Discipline (all spokes)

Produce output early and bank it as you go. A spoke that front-loads its reading
and writes only at the end produces **nothing** when interrupted; a spoke that
wrote early survives the same interruption with work banked. Order your work so
an interruption costs you the least-valuable part.

The form depends on your output channel:

- **Commit channel (Stages 6 / 12 / 13)** — commit and push each coherent slice
  rather than saving one terminal push. A pushed commit is durable, and a
  re-spawn resumes from the release branch with your banked work present.
- **Comment channel (Stages 5 / 7 / 8)** — your output comment is ONE atomic
  write by design, and post-then-edit is wrong on a public repository (edit
  history is permanent and unscrubable). Your form is **ordering, not
  incrementality**: finish the load-bearing analysis before the elaborative
  reads, and accrue composed output into `$SPOKE_OUT` as evidence lands.

**Honest scope — a discipline, not an interlock, and bounded.** Nothing asserts
this per launch. For a comment-channel spoke it bounds loss **within a resumable
session only** — it does not bank work across a re-spawn, because a fresh spawn
resolves a fresh run directory and § Run-Directory Discipline forbids reading
another run's artifacts. Full rule and the observed failure it encodes:
§ Per-Account Usage Window Constraint, mitigation 6.

**Cutover discipline:** Applies to all releases going forward.

