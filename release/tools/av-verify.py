#!/usr/bin/env python3
"""Region-scoped AV (Acceptance-Verification) invariant evaluator — QC4-05.

The pipeline's Stage-13 Post-Deploy Verification (QC4-05,
``release/governance/release-process.md`` Checkpoint 4) re-executes each
release-plan ``AV-N`` invariant against post-deploy ``main``. The historical
mechanism was a bare ``grep`` over the whole deliverable, which has **no model
of lexical context**: it cannot tell a token in executable code from the same
token inside a comment or a negation ("NOT localStorage"). That is a
verification-integrity defect — a correct artifact false-FAILs when the asserted
token appears only inside a disclaiming comment (proven in the originating
website trace), and the symmetric false-PASS is reachable.

This helper makes the comment-vs-code / negation ambiguity **structurally
unrepresentable**. An AV assertion declares:

  * ``region``   ∈ {code, comment, any} — the lexical region the match is
                  restricted to.
  * ``polarity`` ∈ {present, absent}    — whether the pattern MUST be found
                  (``present``) or MUST NOT be found (``absent``) in the region.

``av-verify.py`` resolves the target's comment/fence syntax from its extension,
builds a **code view** (comments — and, for markdown, fenced code blocks —
stripped) and a **comment view** (only comment/fence bytes), then applies the
regex only to the region the assertion declares. A ``region: code`` assertion
never sees comment (or fenced) bytes, so a match there can neither satisfy nor
violate it — the #99 ambiguity class is excluded by construction, not by author
diligence.

Design decisions (ADR-072 — region-scoped-av-invariant-verification):
  * ``region: any`` is byte-equivalent to the old whole-file grep and is the
    default for prose targets with no code/comment split — backward-compatible.
  * An unknown lexer combined with a ``code``/``comment`` region is **fail-loud**
    (exit 3), never a silent whole-file fallback: the mechanism must not silently
    degrade to the unsound behaviour it replaces. The author must add the lexer
    or declare ``region: any`` with intent.
  * Comment-stripping is line-oriented + block-aware and string-literal-naive
    (a ``#`` inside a string literal is treated as a comment). AV targets are
    governance/config, not code where ``#``-in-a-string is load-bearing; this is
    a documented bound and ``region: any`` is the escape hatch.
  * **Markdown (M-1, operator-locked):** the ``.md`` lexer isolates fenced code
    blocks (```` ``` ````/``~~~`` fences — info-strings, indented and
    nested/adjacent fences handled) as their own region so ``region: code``
    excludes fenced content, giving full ``.md`` soundness — a token inside an
    illustrative fenced block does not count as "in code" for an absence
    assertion.

CLI (implementation contract):

    av-verify.py --target <path> --pattern <ere>
                 --region <code|comment|any> --polarity <present|absent>
                 [--id AV-<n>] [--json]

Exit codes:
    0  PASS         — the region+polarity condition holds.
    1  FAIL         — the pattern violates the declared region+polarity.
                      (Non-blocking at Stage 13 per QC4-05 dispositions A/B/C.)
    3  UNVERIFIABLE  — unknown lexer for a code/comment region, OR the target
                      is missing. Fail-loud; treated as FAIL-to-route.

Stdlib only (``re``, ``sys``, ``argparse``, ``pathlib``, ``json``). Idempotent
and read-only — this tool never writes; it is a pure verdict. Python 3.9-safe.

Run the self-test:

    python3 release/tools/av-verify.py --self-test
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Exit codes (module constants so the self-test and callers share them).
EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_UNVERIFIABLE = 3

REGIONS = ("code", "comment", "any")
POLARITIES = ("present", "absent")


# --------------------------------------------------------------------------- #
# Lexer registry: per-extension comment syntax.
#
# Each entry declares how to split a file into a code view and a comment view.
# ``line`` is a list of line-comment prefixes; ``block`` is a list of
# (open, close) block-comment delimiter pairs; ``fenced_md`` flags the markdown
# fenced-code-block class (handled by the dedicated markdown splitter).
# --------------------------------------------------------------------------- #
_HASH = {"line": ["#"], "block": [], "fenced_md": False}
_SLASH = {"line": ["//"], "block": [("/*", "*/")], "fenced_md": False}
_NONE = {"line": [], "block": [], "fenced_md": False}
_MD = {"line": [], "block": [("<!--", "-->")], "fenced_md": True}

LEXERS = {
    ".py": _HASH,
    ".sh": _HASH,
    ".bash": _HASH,
    ".yml": _HASH,
    ".yaml": _HASH,
    ".toml": _HASH,
    ".js": _SLASH,
    ".ts": _SLASH,
    ".json5": _SLASH,
    ".json": _NONE,          # JSON has no comments → code view == whole file.
    ".md": _MD,
    ".markdown": _MD,
}


class UnknownLexer(Exception):
    """Raised when a code/comment region is requested for an unknown extension."""


def lexer_for(path: Path):
    """Return the lexer spec for ``path``'s extension, or ``None`` if unknown."""
    return LEXERS.get(path.suffix.lower())


# --------------------------------------------------------------------------- #
# Markdown fenced-code-block splitting (M-1, operator-locked).
#
# A fenced code block opens with a line whose first non-whitespace run is a
# fence of >= 3 backticks or >= 3 tildes, optionally indented up to 3 spaces,
# optionally followed by an info-string. It closes with a fence line of the SAME
# character, indented up to 3 spaces, at least as long as the opener, and with
# no trailing content (per CommonMark). Backtick info-strings may not contain a
# backtick. "Nested" fences are handled correctly by CommonMark's rule that only
# a same-or-longer fence of the same char closes the block — an inner shorter or
# different-char fence is just content. Adjacent blocks (close then immediately
# reopen) are handled because closing resets the state machine on the next line.
# --------------------------------------------------------------------------- #
_FENCE_OPEN_RE = re.compile(r"^(?P<indent> {0,3})(?P<fence>`{3,}|~{3,})(?P<info>[^\n]*)$")


def _is_md_fence_close(line, fence_char, fence_len):
    """True iff ``line`` closes an open fence of ``fence_char`` × ``fence_len``."""
    m = re.match(r"^(?P<indent> {0,3})(?P<fence>[`~]{3,})[ \t]*$", line)
    if not m:
        return False
    fence = m.group("fence")
    return fence[0] == fence_char and len(fence) >= fence_len


def split_markdown(text):
    """Split markdown ``text`` into (code_view, comment_view).

    * ``code_view``    — text with HTML comments AND fenced code blocks removed
                         (their lines/spans blanked so line numbers are stable).
    * ``comment_view`` — the removed HTML-comment and fenced-block bytes only.

    Fenced blocks are treated as a non-code region so ``region: code`` excludes
    them (M-1). HTML comments are stripped first (span-based, may be multi-line),
    then fenced blocks are stripped line-oriented on the comment-free text.
    """
    # 1) Strip HTML comments span-wise first (they can wrap fence markers).
    comment_spans = []

    def _collect_html(match):
        comment_spans.append(match.group(0))
        # Preserve newlines inside the comment so line indices stay aligned.
        return re.sub(r"[^\n]", " ", match.group(0))

    no_html = re.sub(r"<!--.*?-->", _collect_html, text, flags=re.DOTALL)

    # 2) Line-oriented fenced-block strip on the HTML-comment-free text.
    code_lines = []
    fenced_lines = []
    in_fence = False
    fence_char = ""
    fence_len = 0
    for line in no_html.split("\n"):
        if not in_fence:
            m = _FENCE_OPEN_RE.match(line)
            if m:
                in_fence = True
                fence = m.group("fence")
                fence_char = fence[0]
                fence_len = len(fence)
                fenced_lines.append(line)      # the opening fence line
                code_lines.append("")          # blank in code view (stable lines)
                continue
            code_lines.append(line)
        else:
            fenced_lines.append(line)
            code_lines.append("")
            if _is_md_fence_close(line, fence_char, fence_len):
                in_fence = False
                fence_char = ""
                fence_len = 0
    # NB: an unterminated fence (no closing marker) runs to EOF — every
    # subsequent line is fenced content, matching CommonMark's behaviour.

    code_view = "\n".join(code_lines)
    comment_view = "\n".join(comment_spans + fenced_lines)
    return code_view, comment_view


# --------------------------------------------------------------------------- #
# Generic (non-markdown) comment splitting: line + block comments.
# --------------------------------------------------------------------------- #
def _strip_block_comments(text, block_pairs):
    """Blank every block-comment span; collect the removed spans.

    Newlines inside a span are preserved so line numbers stay aligned. Returns
    (code_text, [removed_span, ...]). Naive: does not honour string literals
    (documented bound — AV targets are governance/config, not string-heavy code).
    """
    removed = []
    for open_delim, close_delim in block_pairs:
        pattern = re.compile(
            re.escape(open_delim) + r".*?" + re.escape(close_delim), re.DOTALL
        )

        def _blank(match):
            removed.append(match.group(0))
            return re.sub(r"[^\n]", " ", match.group(0))

        text = pattern.sub(_blank, text)
    return text, removed


def _strip_line_comments(text, line_prefixes):
    """Blank from each line-comment prefix to EOL; collect the removed tails.

    Returns (code_text, [removed_tail, ...]). String-literal-naive by design.
    """
    if not line_prefixes:
        return text, []
    removed = []
    out_lines = []
    # Longest prefix first so "//" wins over a hypothetical "/".
    prefixes = sorted(line_prefixes, key=len, reverse=True)
    for line in text.split("\n"):
        cut = None
        for prefix in prefixes:
            idx = line.find(prefix)
            if idx != -1 and (cut is None or idx < cut):
                cut = idx
        if cut is None:
            out_lines.append(line)
        else:
            removed.append(line[cut:])
            out_lines.append(line[:cut])
    return "\n".join(out_lines), removed


def split_generic(text, spec):
    """Split ``text`` per a generic ``spec`` (block then line) → views."""
    code_text, block_removed = _strip_block_comments(text, spec["block"])
    code_text, line_removed = _strip_line_comments(code_text, spec["line"])
    comment_view = "\n".join(block_removed + line_removed)
    return code_text, comment_view


def build_views(path, text, region):
    """Return (code_view, comment_view) for ``text`` at ``path``.

    Raises ``UnknownLexer`` when ``region`` needs a lexer the extension lacks.
    For ``region == 'any'`` no lexer is required (whole-file path).
    """
    if region == "any":
        return text, text  # whole-file; neither view is consulted for 'any'.
    spec = lexer_for(path)
    if spec is None:
        raise UnknownLexer(path.suffix or "(no extension)")
    if spec["fenced_md"]:
        return split_markdown(text)
    return split_generic(text, spec)


# --------------------------------------------------------------------------- #
# Evaluation core.
# --------------------------------------------------------------------------- #
def evaluate(path, text, pattern, region, polarity):
    """Evaluate one assertion. Returns (verdict, matched_lines).

    verdict ∈ {'PASS', 'FAIL'}. ``matched_lines`` is the list of (lineno, text)
    that the pattern hit inside the selected view (1-indexed on the view, which
    is line-aligned to the source for code/any; comment-view lines are the
    extracted comment fragments). Raises ``UnknownLexer`` to signal exit 3.
    """
    rx = re.compile(pattern)
    code_view, comment_view = build_views(path, text, region)
    if region == "code":
        view = code_view
    elif region == "comment":
        view = comment_view
    else:  # any
        view = text

    matched = []
    for i, line in enumerate(view.split("\n"), start=1):
        if rx.search(line):
            matched.append((i, line))
    found = bool(matched)

    if polarity == "present":
        verdict = "PASS" if found else "FAIL"
    else:  # absent
        verdict = "PASS" if not found else "FAIL"
    return verdict, matched


def run_assertion(target, pattern, region, polarity, av_id=None):
    """Resolve exit code + a result dict for one assertion.

    Returns (exit_code, result_dict). Missing target or unknown lexer → exit 3.
    """
    path = Path(target)
    result = {
        "id": av_id,
        "target": str(target),
        "pattern": pattern,
        "region": region,
        "polarity": polarity,
        "verdict": None,
        "matched_lines": [],
        "reason": None,
    }
    if not path.is_file():
        result["verdict"] = "UNVERIFIABLE"
        result["reason"] = "target-missing"
        return EXIT_UNVERIFIABLE, result

    text = path.read_text(encoding="utf-8")
    try:
        verdict, matched = evaluate(path, text, pattern, region, polarity)
    except UnknownLexer as exc:
        result["verdict"] = "UNVERIFIABLE"
        result["reason"] = "unknown-lexer:%s" % exc
        return EXIT_UNVERIFIABLE, result

    result["verdict"] = verdict
    result["matched_lines"] = ["%d:%s" % (n, line) for n, line in matched]
    return (EXIT_PASS if verdict == "PASS" else EXIT_FAIL), result


# --------------------------------------------------------------------------- #
# Self-test — synthetic fixtures proving both verdict directions + edge cases.
# --------------------------------------------------------------------------- #
def _self_test():
    """Assert the evaluator on in-memory fixtures. Returns 0/1.

    Covers: the #99 false-FAIL fix, the symmetric false-PASS guard, ``region:
    any`` grep-equivalence (AC-4 regression anchor), markdown fenced-block edge
    cases (info-string, indented, nested/adjacent), HTML comments, and the
    fail-loud unknown-lexer path.
    """
    failures = []

    def check(label, path_suffix, text, pattern, region, polarity, expect_verdict,
              expect_exit=None):
        # Write to a temp path so extension resolution is exercised end to end.
        import tempfile
        import os
        fd, tmp = tempfile.mkstemp(suffix=path_suffix)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as fh:
                fh.write(text)
            code, result = run_assertion(tmp, pattern, region, polarity)
        finally:
            os.unlink(tmp)
        if result["verdict"] != expect_verdict:
            failures.append(
                "[%s] expected verdict %s, got %s (matched=%r)"
                % (label, expect_verdict, result["verdict"], result["matched_lines"])
            )
        if expect_exit is not None and code != expect_exit:
            failures.append(
                "[%s] expected exit %d, got %d" % (label, expect_exit, code)
            )

    # 1) The #99 false-FAIL fix (.js): localStorage only in a // comment,
    #    region:code polarity:absent → PASS (comment invisible to code view).
    check(
        "js-comment-absent-PASS", ".js",
        "// ADR: this module deliberately does NOT use localStorage\n"
        "const store = new MemoryStore();   // in-memory only\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 2) Symmetric false-PASS guard (.js): localStorage genuinely in code,
    #    region:code polarity:absent → FAIL (a real violation is caught).
    check(
        "js-code-absent-FAIL", ".js",
        "// comment mentioning localStorage in prose\n"
        "const raw = window.localStorage.getItem('k');\n",
        r"localStorage", "code", "absent", "FAIL", EXIT_FAIL,
    )
    # 3) present-in-code but only in a comment → FAIL (does not falsely PASS).
    check(
        "js-comment-present-FAIL", ".js",
        "// we could use localStorage here\n"
        "const store = new MemoryStore();\n",
        r"localStorage", "code", "present", "FAIL", EXIT_FAIL,
    )
    # 4) region:any is byte-equivalent to grep — the comment token DOES match
    #    (AC-4 regression anchor: 'any' reproduces whole-file grep).
    check(
        "any-grep-equivalent-FAIL", ".js",
        "// mentions localStorage in a comment\nconst x = 1;\n",
        r"localStorage", "any", "absent", "FAIL", EXIT_FAIL,
    )
    # 5) Markdown HTML comment: token only in <!-- -->, region:code absent → PASS.
    check(
        "md-html-comment-absent-PASS", ".md",
        "# Design\n<!-- ADR: deliberately NOT localStorage -->\n"
        "The store is in-memory only.\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 6) Markdown fenced block (plain fence): token only inside a fenced example,
    #    region:code absent → PASS (M-1: fenced content excluded from code view).
    check(
        "md-fenced-plain-absent-PASS", ".md",
        "# Example\n```\nconst x = localStorage.getItem('k');\n```\n"
        "Prose says nothing about it.\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 7) Markdown fenced block WITH info-string (```js): still excluded.
    check(
        "md-fenced-infostring-absent-PASS", ".md",
        "# Example\n```js\nlocalStorage.setItem('k', v);\n```\n"
        "Body text only.\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 8) Markdown INDENTED fence (up to 3 spaces): still recognised + excluded.
    check(
        "md-fenced-indented-absent-PASS", ".md",
        "- item:\n   ```js\n   localStorage.clear();\n   ```\n"
        "Trailing prose.\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 9) Markdown NESTED/adjacent fences: an outer ```` ```` block containing an
    #    inner ``` fence as content; token inside → excluded from code view.
    check(
        "md-fenced-nested-absent-PASS", ".md",
        "# Doc\n````markdown\n```\nlocalStorage.getItem('k');\n```\n````\n"
        "After the block.\n",
        r"localStorage", "code", "absent", "PASS", EXIT_PASS,
    )
    # 10) Markdown token genuinely in PROSE (not fenced, not commented):
    #     region:code absent → FAIL (prose IS the code view for markdown).
    check(
        "md-prose-absent-FAIL", ".md",
        "# Doc\nThis paragraph uses localStorage in the running text.\n",
        r"localStorage", "code", "absent", "FAIL", EXIT_FAIL,
    )
    # 11) Markdown region:comment finds the token in a fenced block (comment
    #     view for md includes fenced bytes) → present PASS.
    check(
        "md-comment-view-present-PASS", ".md",
        "# Doc\n```js\nlocalStorage.setItem('k', v);\n```\n",
        r"localStorage", "comment", "present", "PASS", EXIT_PASS,
    )
    # 12) Fail-loud: unknown extension + region:code → UNVERIFIABLE / exit 3.
    check(
        "unknown-lexer-exit3", ".xyz",
        "some localStorage text\n",
        r"localStorage", "code", "absent", "UNVERIFIABLE", EXIT_UNVERIFIABLE,
    )
    # 13) Python line comment (#): token only after # → region:code absent PASS.
    check(
        "py-comment-absent-PASS", ".py",
        "# note: not using os.environ here\nvalue = settings.get('k')\n",
        r"os\.environ", "code", "absent", "PASS", EXIT_PASS,
    )
    # 14) JSON has no comments: code view == whole file; token present → PASS.
    check(
        "json-present-PASS", ".json",
        '{"key": "localStorage"}\n',
        r"localStorage", "code", "present", "PASS", EXIT_PASS,
    )

    if failures:
        print("av-verify self-test: FAIL")
        for f in failures:
            print("  - " + f)
        return 1
    print("av-verify self-test: PASS (14 cases: #99 fix, false-PASS guard, "
          "any-equivalence, md fenced info-string/indented/nested, html-comment, "
          "prose, fail-loud unknown-lexer, py/json)")
    return 0


# --------------------------------------------------------------------------- #
# CLI.
# --------------------------------------------------------------------------- #
def build_parser():
    parser = argparse.ArgumentParser(
        description=(
            "Region-scoped AV invariant evaluator (QC4-05). Restricts a regex "
            "match to a declared lexical region so a comment-vs-code / negation "
            "ambiguity cannot produce an incorrect verdict."
        )
    )
    parser.add_argument("--target", help="deliverable file the assertion checks")
    parser.add_argument("--pattern", help="regex (ERE) asserted against the region")
    parser.add_argument(
        "--region", choices=REGIONS,
        help="lexical region to restrict the match to",
    )
    parser.add_argument(
        "--polarity", choices=POLARITIES,
        help="present = pattern MUST be found; absent = MUST NOT be found",
    )
    parser.add_argument("--id", default=None, help="stable AV-<n> id (optional)")
    parser.add_argument(
        "--json", action="store_true",
        help="emit a JSON result object for the qc4-05-result event payload",
    )
    parser.add_argument(
        "--self-test", action="store_true",
        help="run built-in synthetic fixtures and exit",
    )
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)

    if args.self_test:
        return _self_test()

    missing = [
        name for name in ("target", "pattern", "region", "polarity")
        if getattr(args, name) is None
    ]
    if missing:
        print(
            "av-verify: missing required argument(s): %s "
            "(need --target --pattern --region --polarity, or --self-test)"
            % ", ".join("--" + m for m in missing),
            file=sys.stderr,
        )
        return EXIT_UNVERIFIABLE

    exit_code, result = run_assertion(
        args.target, args.pattern, args.region, args.polarity, av_id=args.id
    )

    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        head = result["verdict"]
        loc = " [%s]" % result["id"] if result["id"] else ""
        print("%s%s: %s region=%s polarity=%s target=%s"
              % (head, loc, result["pattern"], result["region"],
                 result["polarity"], result["target"]))
        if result["reason"]:
            print("  reason: %s" % result["reason"])
        for ml in result["matched_lines"]:
            print("  match: %s" % ml)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
