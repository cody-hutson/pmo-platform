#!/usr/bin/env python3
"""render_fixture.py — emit a payload-laden static eval-viewer page for the DOM test.

Builds a runs[] + benchmark structure whose attacker-reachable fields carry XSS
payloads, then calls generate_review.generate_html() (imported BY PATH — eval-viewer/
is not a package) to render viewer.html with EMBEDDED_DATA injected. dom_xss_test.js
loads the emitted file in jsdom and asserts the payloads land inert.

Payloads are placed in the EXACT fields the GHSA-rw36-5pf9-w2vc render-sink fix
(eb90e67) hardened — the fields that were interpolated RAW pre-fix and are now
escapeHtml()/Number()/escapeAttr()-encoded. Fields that were ALREADY escaped pre-fix
(exp.text, metadata.skill_name, notes) are included as escaped-both CONTROLS: they must
stay inert on BOTH trees, so a payload there proves the already-hardened path holds.

Usage:  python3 render_fixture.py <output.html>

Runs on the stock macOS python3 (3.9) via generate_review's __future__ import.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GEN = HERE.parent / "generate_review.py"  # eval-viewer/generate_review.py

_spec = importlib.util.spec_from_file_location("generate_review", GEN)
gr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gr)


def IMG(loc: str) -> str:
    """A body-context structural payload. Raw interpolation into an innerHTML sink
    materializes a real <img> ELEMENT (with an onerror handler); escapeHtml()/Number()
    lands it as inert TEXT. The onerror never fires in jsdom (no resource load), so the
    ELEMENT's presence — not execution — is the load-bearing discriminator (B1)."""
    return f"<img src=x onerror=window.__xssFired('{loc}')>"


def ATTR(loc: str) -> str:
    """An attribute-context breakout payload. The leading `\"` closes a quoted attribute
    (e.g. title=\"...\") so the trailing <img> escapes the attribute and becomes an
    ELEMENT. escapeHtml() does NOT encode the quote (body encoder only), so this is inert
    ONLY under escapeAttr() — it is the discriminator that proves the attribute-context
    hardening, not merely body escaping."""
    return f'1"><img src=x onerror=window.__xssFired(\'{loc}\')>'


# --- runs[]: drives renderGrades via showRun(0) -> #grades-content -------------------
runs = [
    {
        "id": "run-with_skill-1",
        "prompt": "structural payload smoke test",
        "eval_id": 1,
        "outputs": [{"name": "o.txt", "type": "text", "content": "inert output body"}],
        "grading": {
            # summary.passed/failed/total: RAW string-concat pre-fix -> Number()||0 post-fix.
            "summary": {"pass_rate": 0.9, "passed": IMG("grades-summary-passed"), "failed": 0, "total": 1},
            # exp.text / exp.evidence: escapeHtml() on BOTH trees (control — must stay inert).
            "expectations": [
                {"text": IMG("grades-exp-text-CONTROL"), "passed": True, "evidence": IMG("grades-exp-evidence-CONTROL")},
            ],
        },
    }
]

# --- benchmark: drives renderBenchmark() -> #benchmark-content ------------------------
benchmark = {
    "metadata": {
        "skill_name": IMG("bench-skill_name-CONTROL"),   # escapeHtml() both trees (control)
        "timestamp": IMG("bench-timestamp"),             # RAW pre-fix
        "evals_run": [IMG("bench-evals_run")],           # RAW pre-fix (.join)
        "runs_per_configuration": IMG("bench-rpc"),      # RAW pre-fix
    },
    "run_summary": {
        "with_skill": {"pass_rate": {"mean": 0.9, "stddev": 0.1},
                       "time_seconds": {"mean": 1.0, "stddev": 0.1},
                       "tokens": {"mean": 100, "stddev": 5}},
        "without_skill": {"pass_rate": {"mean": 0.5, "stddev": 0.2},
                          "time_seconds": {"mean": 2.0, "stddev": 0.2},
                          "tokens": {"mean": 200, "stddev": 10}},
        # delta.*: RAW pre-fix -> escapeHtml(String(...)) post-fix.
        "delta": {"pass_rate": IMG("bench-delta_pr"),
                  "time_seconds": IMG("bench-delta_ts"),
                  "tokens": IMG("bench-delta_tok")},
    },
    "notes": [IMG("bench-note-CONTROL")],   # escapeHtml() both trees (control)
    "runs": [
        {
            "eval_id": 1,
            "eval_name": "Eval One",
            "configuration": IMG("bench-config"),   # -> configLabel: RAW pre-fix (case-mangled but still an element)
            "run_number": ATTR("bench-run_number"),  # RAW pre-fix in <td> body AND title="..." attribute
            "result": {"pass_rate": 0.9, "passed": 9, "total": 10, "time_seconds": 1.2, "errors": 0},
            # evidence in the per-assertion title attr: escapeHtml() pre-fix (leaks the quote!)
            # -> escapeAttr() post-fix. Proves body-encoding is insufficient in attr context.
            "expectations": [
                {"text": "assertion one", "passed": True, "evidence": ATTR("bench-evidence-attr")},
            ],
        }
    ],
}

# previous_feedback non-empty forces init()'s SYNCHRONOUS path (skips fetch("/api/feedback")),
# so the page renders hermetically in jsdom with no network. previous_outputs left empty so
# renderPrevOutputs() returns early.
previous = {"run-with_skill-1": {"feedback": "prior note (forces sync init path)", "outputs": []}}


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: render_fixture.py <output.html>", file=sys.stderr)
        return 2
    html = gr.generate_html(runs, "eval-viewer-dom-xss", previous, benchmark, "")
    Path(sys.argv[1]).write_text(html, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
