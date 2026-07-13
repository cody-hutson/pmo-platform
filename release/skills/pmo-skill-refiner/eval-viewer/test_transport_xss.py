#!/usr/bin/env python3
"""test_transport_xss.py — transport-boundary regression for GHSA-rw36-5pf9-w2vc.

generate_review.generate_html() serializes untrusted eval data with json.dumps() and
splices it into a `const EMBEDDED_DATA = {...};` assignment INSIDE viewer.html's inline
<script>. json.dumps escapes `"` but NOT `< > &`, so a value containing `</script>` would
break out of the script context. The fix escapes `& < >` to `\\u0026 \\u003c \\u003e`,
keeping the JSON inert at the parser boundary while staying LOSSLESS (JS decodes the
\\uXXXX escapes back to the original characters at runtime).

This asserts that boundary directly (A1-A3) and cross-checks the sibling HTML emitter
generate_report.py, which neutralizes its own untrusted input via html.escape (A4) — the
"both eval-viewer emitters encode untrusted data" parity the GHSA-rw36 remediation cites. It is ADDITIVE to
test_generate_review.py (GHSA-fxcr: symlink-read / redaction / CSRF), which does NOT
exercise the generate_html transport boundary or generate_report at all.

Runnable standalone: `python3 test_transport_xss.py` (exit 0 = pass). No third-party deps.
Runs on the stock macOS python3 (3.9) via each module's __future__ import.

  PRE-FIX  (eb90e67^):  raw </script> / < / > survive in EMBEDDED_DATA  -> UNSAFE -> exit 1
  POST-FIX (current):   \\u003c/\\u003e/\\u0026 escaped, lossless round-trip -> SAFE -> exit 0
"""
from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


gr = _load("generate_review", HERE / "generate_review.py")
grep = _load("generate_report", HERE.parent / "scripts" / "generate_report.py")

PASS = 0
FAIL = 0


def check(desc: str, cond: bool, detail: str = "") -> None:
    global PASS, FAIL
    if cond:
        print(f"PASS: {desc}")
        PASS += 1
    else:
        print(f"FAIL: {desc}" + (f"  -- {detail}" if detail else ""))
        FAIL += 1


# --- Payload corpus (each embedded in an attacker-reachable field) -------------------
SCRIPT_BREAKOUT = "</script><script>alert(1)</script>"   # discriminator: RED pre-fix
IMG_ONERROR = "<img src=x onerror=alert(1)>"             # discriminator: RED pre-fix
BARE_METACHARS = "& < >"                                  # discriminator: escaped to \uXXXX
U2028_U2029 = "line para sep"                   # coverage: handled by ensure_ascii
ESCAPED_QUOTE = 'he said "hi" \\ bye'                     # coverage: JSON quote/backslash escaping

runs = [
    {
        "id": "run-1",
        "prompt": SCRIPT_BREAKOUT,
        "eval_id": 1,
        "outputs": [{"name": "o.txt", "type": "text", "content": IMG_ONERROR}],
        "grading": {
            "summary": {"pass_rate": 0.5, "passed": 1, "failed": 1, "total": BARE_METACHARS},
            "expectations": [{"text": ESCAPED_QUOTE, "passed": True, "evidence": U2028_U2029}],
        },
    }
]
benchmark = {
    "metadata": {"skill_name": "s", "timestamp": SCRIPT_BREAKOUT, "evals_run": [IMG_ONERROR]},
    "notes": [BARE_METACHARS, IMG_ONERROR],
    "run_summary": {"with_skill": {}, "without_skill": {}, "delta": {"pass_rate": SCRIPT_BREAKOUT}},
    "runs": [],
}

_EMBED_RE = re.compile(r"const EMBEDDED_DATA = (\{.*\});")


def _extract_embedded(html: str) -> str:
    for line in html.splitlines():
        if "const EMBEDDED_DATA =" in line:
            m = _EMBED_RE.search(line)
            if m:
                return m.group(1)
    raise AssertionError("EMBEDDED_DATA assignment not found in generated HTML")


def main() -> int:
    html = gr.generate_html(runs, "s", None, benchmark, "")
    literal = _extract_embedded(html)

    # A1 — breakout neutralized: no raw script-context-breaking sequence in the literal.
    low = literal.lower()
    check("A1: no raw '</script' survives in EMBEDDED_DATA", "</script" not in low,
          "script-context breakout possible")
    check("A1: no raw '<script' survives in EMBEDDED_DATA", "<script" not in low)
    check("A1: no raw '<img' survives in EMBEDDED_DATA", "<img" not in low)

    # A2 — metachar escaping: zero raw < > & in the literal (each escaped to \uXXXX).
    check("A2: zero raw '<' in EMBEDDED_DATA", literal.count("<") == 0, f"count={literal.count('<')}")
    check("A2: zero raw '>' in EMBEDDED_DATA", literal.count(">") == 0, f"count={literal.count('>')}")
    check("A2: zero raw '&' in EMBEDDED_DATA", literal.count("&") == 0, f"count={literal.count('&')}")
    check("A2: escaped forms present (\\u003c/\\u003e/\\u0026)",
          "\\u003c" in literal and "\\u003e" in literal and "\\u0026" in literal)

    # A3 — fidelity: the escaping is LOSSLESS (json.loads decodes \uXXXX back to the
    # original chars), so a legitimate < or & in eval output is preserved, not corrupted.
    # Guards against a safe-but-wrong "strip all metachars" regression.
    loaded = json.loads(literal)
    check("A3: EMBEDDED_DATA is valid JSON (round-trips)", isinstance(loaded, dict))
    check("A3: prompt round-trips losslessly (real </script> preserved)",
          loaded["runs"][0]["prompt"] == SCRIPT_BREAKOUT)
    check("A3: output content round-trips losslessly (real <img> preserved)",
          loaded["runs"][0]["outputs"][0]["content"] == IMG_ONERROR)
    check("A3: bare metachars round-trip losslessly ('& < >')",
          loaded["runs"][0]["grading"]["summary"]["total"] == BARE_METACHARS)
    check("A3: U+2028/U+2029 round-trip losslessly",
          loaded["runs"][0]["grading"]["expectations"][0]["evidence"] == U2028_U2029)
    check("A3: quote/backslash round-trip losslessly",
          loaded["runs"][0]["grading"]["expectations"][0]["text"] == ESCAPED_QUOTE)

    # A4 — sibling parity: generate_report.py (html.escape) also neutralizes an injection
    # payload in its own untrusted fields (query / description / skill_name). Both eval-
    # viewer HTML emitters encode untrusted data — encoding is not author-discretion.
    report_data = {
        "original_description": IMG_ONERROR,
        "best_description": "clean",
        "history": [{
            "iteration": 0,
            "description": SCRIPT_BREAKOUT,
            "train_results": [{"query": SCRIPT_BREAKOUT, "should_trigger": True, "triggered": True, "correct": True}],
            "test_results": [{"query": IMG_ONERROR, "should_trigger": True, "triggered": True, "correct": True}],
            "train_accuracy": 1.0, "test_accuracy": 1.0, "accuracy": 1.0,
        }],
        "holdout": 0,
    }
    report_html = grep.generate_html(report_data, False, IMG_ONERROR)
    check("A4: sibling generate_report neutralizes raw '<img' (html.escape)",
          "<img src=x onerror" not in report_html)
    check("A4: sibling generate_report neutralizes raw '<script>alert' (html.escape)",
          "<script>alert(1)" not in report_html)
    check("A4: sibling generate_report emits the escaped entity form (&lt;img)",
          "&lt;img src=x onerror" in report_html)

    print("\n================================")
    print(f"Total: {PASS + FAIL}  PASS: {PASS}  FAIL: {FAIL}")
    print("================================")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
