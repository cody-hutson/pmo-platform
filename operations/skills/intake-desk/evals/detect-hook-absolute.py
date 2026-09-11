#!/usr/bin/env python3
"""Sentence-scoped detector for the two claim classes at issue in #6394.

Re-derived from the Stage-5 D1 probe record: newlines are collapsed to spaces
BEFORE sentence splitting, so a claim spanning a line break stays one unit.
A line-scoped matcher under-counts here — every in-scope claim in the corpus
wraps across a line break.

Two modes, deliberately NOT complements of each other:

  observ  -- sentences asserting that a control does not OBSERVE the
             `gh issue create` payload, as an unqualified property.
             This is the FALSE class the card corrects. Expect 0 after the fix.

  enforce -- sentences asserting there is no mechanical ENFORCEMENT behind
             Mode C's Tier-0 floor. This is the TRUE class and the card's
             own preserved operative conclusion. Expect a FLOOR (>=1), never
             an equality -- the build rewrites some of this prose, so an
             equality arm fails on a correct build.

The `observ` predicate is lexical but not circular: it keys on three general
signatures of an unqualified non-observation claim, not on the four strings
this build happens to edit. A sensitivity fixture written independently of the
corpus fires on it.

  R1  predicative non-detectability asserted of the action
      ("... is not payload-detectable")
  R2  the bare adjectival form ("non-payload-detectable <thing>")
  R3  an unqualified hook-negation on an observation/firing verb
      ("the hook never sees it", "no hook fires on this create")

R3 deliberately does NOT match an ANAPHORIC determiner ("that hook", "this
hook", a named hook path), because a predicate scoped to a just-named hook is
the correct form the fix adopts -- that is the whole point of the card.

The enumerated form "hard-blocks only (the) payload-detectable Tier-0 classes
(governance-file writes / cross-domain bridge paths)" is NOT matched by any
arm: it is a scoped-true description of one hook's blocking set. Three such
sentences are fenced DO-NOT-EDIT in this build.

Usage:
    python3 detect-hook-absolute.py <observ|enforce|fence> <file> [<file>...]
    python3 detect-hook-absolute.py --self-test
"""

import re
import sys

# --- R1: predicative non-detectability asserted of the action ---------------
R1 = re.compile(r"\b(?:is|are|was|were|be|being|been)\s+(?:\*{0,2})not(?:\*{0,2})\s+"
                r"(?:\*{0,2})payload-detectable\b", re.I)

# --- R2: the bare adjectival form ------------------------------------------
R2 = re.compile(r"\bnon-payload-detectable\b", re.I)

# --- R3: unqualified hook-negation on an observation / firing verb ----------
# Matches: "the hook never sees it" / "no hook fires on this create" /
#          "a hook does not see the call" / "the hook never fires on it"
# Does NOT match an anaphoric or named scope: "that hook never fires",
#          "this hook does not fire", "block-gh-path-leak.sh never fires".
R3 = re.compile(
    r"(?<!\bthat\s)(?<!\bthis\s)"
    r"\b(?:no|the|a|any)\s+hooks?\s+"
    r"(?:(?:ever|never|does\s+not|do\s+not|doesn't|don't|will\s+not|won't|cannot|can't)\s+)+"
    r"(?:\*{0,2})(?:see|sees|seeing|observe|observes|observing|fire|fires|firing|"
    r"detect|detects|detecting|match|matches|matching)\b",
    re.I,
)

# --- enforcement-absence class (TRUE; the preserved operative conclusion) ---
ENFORCE = re.compile(
    r"(?:no\s+mechanical\s+(?:hook\s+)?(?:enforcement|backstop)"
    r"|no\s+mechanical\s+backstop\s+for\s+this\s+create"
    r"|skill-level\s+self-limit"
    r"|there\s+is\s+no\s+mechanical\s+enforcement"
    r"|nothing\s+else\s+catches\s+the\s+miss"
    r"|never\s+rely\s+on\s+the\s+hook\s+as\s+the\s+backstop)",
    re.I,
)

# --- the fenced scoped-true class (must stay at 3 in SKILL.md) -------------
# NOTE: TWO intervening-token classes defeat a literal matcher here, and each
# one independently under-counts the fence:
#   (a) an optional determiner -- "hard-blocks only THE payload-detectable";
#       this is why a literal probe for "only payload-detectable" returns 2
#       where the true figure is 3.
#   (b) markdown emphasis markers -- "hard-blocks **only the payload-detectable
#       Tier-0 classes**" -- which sit BETWEEN the words a naive \s+ expects to
#       be adjacent.
# Both are tolerated below. A fence count that disagrees with 3 is a probe
# defect until proven otherwise.
_EM = r"[*_`]*\s*"  # markdown emphasis / code markers plus surrounding space
FENCE = re.compile(
    r"\bhard-blocks?" + r"\s*" + _EM + r"only" + r"\s*" + _EM
    + r"(?:the" + r"\s*" + _EM + r")?payload-detectable" + r"\s*" + _EM + r"Tier-0\b",
    re.I,
)


def sentences(text):
    """Collapse newlines, then split on sentence terminators.

    Collapsing FIRST is load-bearing: every in-scope claim in this corpus
    spans a line break, and a line-scoped probe returns a plausible zero.
    """
    flat = re.sub(r"\s+", " ", text)
    # Split after . ! ? when followed by whitespace + a capital/quote/backtick,
    # or at the end. Abbreviation-tolerant enough for this corpus.
    parts = re.split(r"(?<=[.!?])\s+(?=[A-Z\"'`*\[(])", flat)
    return [p.strip() for p in parts if p.strip()]


def scan(path, mode):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    sents = sentences(text)
    hits = []
    for s in sents:
        if mode == "observ":
            which = [n for n, r in (("R1", R1), ("R2", R2), ("R3", R3)) if r.search(s)]
            if which:
                hits.append((",".join(which), s))
        elif mode == "enforce":
            if ENFORCE.search(s):
                hits.append(("ENF", s))
        elif mode == "fence":
            if FENCE.search(s):
                hits.append(("FENCE", s))
    return sents, hits


def main(argv):
    if len(argv) >= 2 and argv[1] == "--self-test":
        return self_test()
    if len(argv) < 3:
        print(__doc__)
        return 2
    mode = argv[1]
    if mode not in ("observ", "enforce", "fence"):
        print("mode must be observ | enforce | fence", file=sys.stderr)
        return 2
    total = 0
    for path in argv[2:]:
        sents, hits = scan(path, mode)
        print("%-70s mode=%-7s sentences=%-5d hits=%d" % (path, mode, len(sents), len(hits)))
        for tag, s in hits:
            print("    [%s] %s" % (tag, s[:300]))
        total += len(hits)
    print("TOTAL %s hits: %d" % (mode, total))
    return 0


def self_test():
    """Sensitivity + specificity arms, inline so the detector proves itself."""
    must_flag = [
        # wrap-crossing case: the newline is INSIDE the claim
        "Mode C's hazardous action is `gh issue create`, which is neither a\ngovernance-file write nor a cross-domain bridge path, so it is **not\npayload-detectable — the hook never sees it**.",
        "and Mode C's `gh issue create` is not payload-detectable, so the hook\nnever fires on it.",
        "which is false for the non-payload-detectable `gh issue create` path.",
        "and Mode C's `gh issue create` is not payload-detectable, so **no hook\nfires on this create**.",
        "A hook does see the call.".replace("does see", "does not see"),
    ]
    must_not_flag = [
        # the three fenced scoped-true forms
        "When the operator flips it warn→enforce, the hook hard-blocks **only the\npayload-detectable Tier-0 classes** — governance-file writes and cross-domain\nbridge paths — because those are decidable from the tool-call payload.",
        "the C5 enforcement hook (CLOSED) hard-blocks only payload-detectable Tier-0\n(governance-file writes / cross-domain bridge paths), and Mode C's `gh issue\ncreate` is neither, so the Tier-0 floor here is a skill-level self-limit only.",
        "the C5 hook (CLOSED) hard-blocks only payload-detectable Tier-0\n(governance-file writes / cross-domain bridge paths), and Mode C's `gh issue\ncreate` is neither, so that hook does not fire on this create.",
        # enforcement-absence near-misses (TRUE class; must not read as observ)
        "Mode C's create hazard has NO mechanical hook backstop.",
        "The Tier-0 floor is a skill-level self-limit only.",
        "Never rely on the hook as the backstop for a Mode-C create.",
        # correctly-scoped anaphoric predicate (the shape the fix adopts)
        "Mode C's `gh issue create` is neither, so that hook does not gate this\ncreate.",
    ]
    ok = True
    sens = 0
    for t in must_flag:
        flat = re.sub(r"\s+", " ", t)
        if R1.search(flat) or R2.search(flat) or R3.search(flat):
            sens += 1
        else:
            ok = False
            print("SENSITIVITY MISS: %s" % flat[:140])
    spec = 0
    for t in must_not_flag:
        flat = re.sub(r"\s+", " ", t)
        if R1.search(flat) or R2.search(flat) or R3.search(flat):
            ok = False
            print("SPECIFICITY FALSE POSITIVE: %s" % flat[:140])
        else:
            spec += 1
    # the specificity fixture must itself be non-empty under a DIFFERENT arm,
    # or a zero there proves nothing
    enf_in_spec = sum(1 for t in must_not_flag if ENFORCE.search(re.sub(r"\s+", " ", t)))
    fence_in_spec = sum(1 for t in must_not_flag if FENCE.search(re.sub(r"\s+", " ", t)))
    print("sensitivity arm: %d/%d flagged (must be %d)" % (sens, len(must_flag), len(must_flag)))
    print("specificity arm: %d/%d clean (must be %d)" % (spec, len(must_not_flag), len(must_not_flag)))
    print("specificity fixture shown non-empty: ENFORCE matches=%d, FENCE matches=%d"
          % (enf_in_spec, fence_in_spec))
    print("SELF-TEST: %s" % ("PASS" if ok and sens == len(must_flag) else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
