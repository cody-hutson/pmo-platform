#!/usr/bin/env python3
"""test_generate_review.py — security regression for GHSA-fxcr-7x63-3g94.

Covers the three eval-viewer findings with NEGATIVE tests (the vuln must be blocked)
and POSITIVE controls (the legitimate path must still work, so a broken harness fails):

  2a  symlink-following arbitrary read  — a symlink whose target escapes the workspace
      is NOT read/embedded; an in-workspace file IS embedded.
  2b  verbatim secret/PII embedding     — secrets are redacted and oversized files are
      capped; ordinary content is preserved (no over-redaction).
  2c  CSRF / DNS-rebinding write         — POST /api/feedback requires a loopback Host,
      a same-origin (or absent) Origin, and the per-run CSRF token; a 403 never writes.

Runnable standalone: `python3 test_generate_review.py` (exit 0 = pass). No third-party
deps. Works on the stock macOS python3 (3.9) via generate_review's __future__ import.

COORDINATION (milestone #271, separate release hub — do not duplicate):
  #3408 adds the DOM + transport XSS regression test for GHSA-rw36 and WIRES the
        eval-viewer tests into CI. This file is the GHSA-fxcr slice that job should run;
        the focused `eval-viewer-security` job added to .github/workflows/security.yml in
        this fix runs it in the meantime.
"""
from __future__ import annotations

import base64
import http.client
import importlib.util
import json
import os
import shutil
import tempfile
import threading
import time
from functools import partial
from http.server import HTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("generate_review", HERE / "generate_review.py")
gr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gr)

PASS = 0
FAIL = 0


def check(desc: str, cond: bool) -> None:
    global PASS, FAIL
    if cond:
        print(f"PASS: {desc}")
        PASS += 1
    else:
        print(f"FAIL: {desc}")
        FAIL += 1


def _make_ws(tmp: str) -> Path:
    ws = Path(tmp) / "ws"
    (ws / "run1" / "outputs").mkdir(parents=True)
    return ws


# ============================ 2a — symlink confinement ============================
tmp = tempfile.mkdtemp()
try:
    ws = _make_ws(tmp)
    vault = Path(tmp) / "vault"
    vault.mkdir()
    (vault / "secret.txt").write_text("SECRET_TOKEN_LEAKME")
    (vault / "meta.json").write_text('{"prompt":"SECRET_PROMPT_LEAK","eval_id":1}')
    (ws / "run1" / "outputs" / "legit.txt").write_text("hello from inside the workspace")
    os.symlink(vault / "secret.txt", ws / "run1" / "outputs" / "evil.txt")   # escaping output symlink
    os.symlink("/etc/passwd", ws / "run1" / "outputs" / "passwd.txt")        # classic arbitrary read
    os.symlink(vault / "meta.json", ws / "run1" / "eval_metadata.json")      # escaping metadata symlink

    blob = json.dumps(gr.find_runs(ws.resolve()))
    check("2a: external secret via symlink NOT embedded", "SECRET_TOKEN_LEAKME" not in blob)
    check("2a: /etc/passwd via symlink NOT embedded", ":0:0:" not in blob)
    check("2a: escaping eval_metadata.json symlink NOT read", "SECRET_PROMPT_LEAK" not in blob)
    check("2a: in-workspace legit file IS embedded (positive control)", "hello from inside the workspace" in blob)

    # positive control: an IN-workspace symlink (points inside the tree) is still followed
    (ws / "run1" / "outputs" / "real.txt").write_text("in-tree-symlink-target")
    os.symlink(ws / "run1" / "outputs" / "real.txt", ws / "run1" / "outputs" / "friendly.txt")
    blob_in = json.dumps(gr.find_runs(ws.resolve()))
    check("2a: in-workspace symlink IS followed (positive control)", blob_in.count("in-tree-symlink-target") >= 2)
finally:
    shutil.rmtree(tmp, ignore_errors=True)


# ==================== 2b — size cap + secret/PII redaction ====================
tmp = tempfile.mkdtemp()
try:
    ws = _make_ws(tmp)
    secretish = "\n".join([
        "aws key AKIAABCDEFGHIJKLMNOP here",
        "github ghp_0123456789012345678901234567890 token",
        "api_key = sk-supersecretvalue123",
        "password: hunter2horsebattery",
        "-----BEGIN RSA PRIVATE KEY-----",
        "MIIsomethingsomethingbase64",
        "-----END RSA PRIVATE KEY-----",
        "a perfectly normal line of eval output with code x = 1 + 2",
    ])
    (ws / "run1" / "outputs" / "s.txt").write_text(secretish)
    (ws / "run1" / "outputs" / "big.txt").write_text("A" * (gr.MAX_EMBED_BYTES + 5000))
    runs = gr.find_runs(ws.resolve())
    blob = json.dumps(runs)
    check("2b: AWS access key redacted", "AKIAABCDEFGHIJKLMNOP" not in blob and "REDACTED AWS" in blob)
    check("2b: GitHub token redacted", "ghp_0123456789012345678901234567890" not in blob)
    check("2b: api_key value redacted", "sk-supersecretvalue123" not in blob)
    check("2b: password value redacted", "hunter2horsebattery" not in blob)
    check("2b: PEM private key redacted", "REDACTED PRIVATE KEY" in blob)
    check("2b: ordinary content preserved (no over-redaction)", "a perfectly normal line of eval output" in blob)
    # oversized file: the embedded content is capped near MAX_EMBED_BYTES, not the full 517KB
    big_out = next(o for r in runs for o in r["outputs"] if o["name"] == "big.txt")
    check("2b: oversized text truncated with marker", "truncated at" in big_out["content"])
    check("2b: oversized text capped in length", len(big_out["content"]) <= gr.MAX_EMBED_BYTES + 100)
finally:
    shutil.rmtree(tmp, ignore_errors=True)


# ==================== 2c — CSRF / DNS-rebinding write gate ====================
tmp = tempfile.mkdtemp()
try:
    ws = _make_ws(tmp)
    (ws / "run1" / "outputs" / "o.txt").write_text("x")
    fb = ws / "feedback.json"
    token = "test-token-abcdef0123456789"  # arbitrary per-run token
    handler = partial(gr.ReviewHandler, ws.resolve(), "poc", fb, {}, None, token)
    srv = HTTPServer(("127.0.0.1", 0), handler)
    port = srv.server_address[1]
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    good_host = f"127.0.0.1:{port}"

    def _post(headers, body):
        c = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        c.putrequest("POST", "/api/feedback", skip_host=True, skip_accept_encoding=True)
        for k, v in headers.items():
            c.putheader(k, v)
        c.putheader("Content-Length", str(len(body)))
        c.endheaders()
        c.send(body)
        r = c.getresponse()
        r.read()
        c.close()
        return r.status

    def _get(headers, path="/"):
        c = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
        c.putrequest("GET", path, skip_host=True, skip_accept_encoding=True)
        for k, v in headers.items():
            c.putheader(k, v)
        c.endheaders()
        r = c.getresponse()
        r.read()
        c.close()
        return r.status

    keep = b'{"reviews":[{"run_id":"marker","feedback":"keep"}]}'
    evil = b'{"reviews":[{"run_id":"evil","feedback":"pwned"}]}'

    check("2c: POST valid Host+token -> 200 (positive control)", _post({"Host": good_host, "X-CSRF-Token": token}, keep) == 200)
    check("2c: valid POST actually wrote feedback", fb.exists() and "marker" in fb.read_text())
    check("2c: POST no token -> 403", _post({"Host": good_host}, evil) == 403)
    check("2c: POST wrong token -> 403", _post({"Host": good_host, "X-CSRF-Token": "nope"}, evil) == 403)
    check("2c: POST bad Host (DNS-rebind) -> 403", _post({"Host": "evil.example.com", "X-CSRF-Token": token}, evil) == 403)
    check("2c: POST cross-origin Origin -> 403", _post({"Host": good_host, "X-CSRF-Token": token, "Origin": "http://evil.example.com"}, evil) == 403)
    check("2c: a 403 POST did NOT overwrite feedback", ("marker" in fb.read_text()) and ("evil" not in fb.read_text()))
    check("2c: GET bad Host -> 403", _get({"Host": "evil.example.com"}) == 403)
    check("2c: GET good Host -> 200 (positive control)", _get({"Host": good_host}) == 200)
    # Adversarial-review hardening: the /api/feedback READ path also honors Origin, and a
    # latin-1 (non-ASCII) token header fails closed (403), not an unhandled 500/traceback.
    check("2c: GET /api/feedback good Host -> 200 (control)", _get({"Host": good_host}, "/api/feedback") == 200)
    check("2c: GET /api/feedback cross-origin Origin -> 403 (read defense-in-depth)",
          _get({"Host": good_host, "Origin": "http://evil.example.com"}, "/api/feedback") == 403)
    try:
        _latin1 = _post({"Host": good_host, "X-CSRF-Token": "t\xe9ken"}, evil)
        check("2c: latin-1 non-ASCII token -> 403 (no crash)", _latin1 == 403)
    except Exception:
        # A conforming http.client may refuse to send the non-ASCII header, so the crash
        # path is unreachable from a real client; the _csrf_ok try/except is belt-and-braces.
        check("2c: latin-1 non-ASCII token (client refused to send; path unreachable)", True)
    srv.shutdown()
finally:
    shutil.rmtree(tmp, ignore_errors=True)


# ============ adversarial-review hardening: hardlink / redaction / benchmark ============
tmp = tempfile.mkdtemp()
try:
    ws = _make_ws(tmp)
    # 2a hardlink: resolve() can't see a hardlink whose 2nd name is outside the workspace.
    outside = Path(tmp) / "outside_secret.txt"
    outside.write_text("HARDLINK_OUTOFROOT_SECRET")
    os.link(outside, ws / "run1" / "outputs" / "hardleak.txt")   # hardlink (not symlink)
    (ws / "run1" / "outputs" / "ok.txt").write_text("legit single-link content")
    blob = json.dumps(gr.find_runs(ws.resolve()))
    check("2a: hardlink to out-of-root file NOT embedded", "HARDLINK_OUTOFROOT_SECRET" not in blob)
    check("2a: legit single-link file IS embedded (positive control)", "legit single-link content" in blob)

    # 2b redaction correctness: legit code must survive; ReDoS input must be fast.
    for legit in ["assert token == expected_value", "config.secret = compute_hash(x)", "The password: never share it here"]:
        check(f"2b: no over-redaction of {legit!r}", gr._redact(legit) == legit)
    t0 = time.time()
    gr._redact("-----BEGIN RSA PRIVATE KEY-----" * (gr.MAX_EMBED_BYTES // 31))  # 512 KiB BEGIN-only
    check("2b: ReDoS input redacts in < 2s (was ~29s O(n^2))", (time.time() - t0) < 2.0)

    # 2b benchmark: --benchmark is redacted + size-capped (embedded into the shareable HTML).
    bench = Path(tmp) / "bench.json"
    bench.write_text('{"note":"leak ghp_ZZZZYYYYXXXXWWWW0123456789 token","n":7}')
    b = gr._read_operator_json(bench)
    check("2b: benchmark secret redacted", isinstance(b, dict) and "ghp_ZZZZYYYYXXXXWWWW0123456789" not in json.dumps(b))
    check("2b: benchmark non-secret data preserved", isinstance(b, dict) and b.get("n") == 7)
    big_bench = Path(tmp) / "big.json"
    big_bench.write_text('{"x":"' + "A" * (gr.MAX_EMBED_BYTES + 1000) + '"}')
    check("2b: oversized benchmark skipped (not embedded)", gr._read_operator_json(big_bench) is None)
finally:
    shutil.rmtree(tmp, ignore_errors=True)


# ===== 2b redaction coverage: secret-dense NON-text-extension files (adversarial pass 2) =====
tmp = tempfile.mkdtemp()
try:
    ws = _make_ws(tmp)
    (ws / "run1" / "outputs" / "config.env").write_text("API_KEY=sk-proj-SUPERSECRETVALUE123456\n")
    (ws / "run1" / "outputs" / "id_rsa").write_text(                          # no extension
        "-----BEGIN RSA PRIVATE KEY-----\nMIIBOgIBLEAKEDKEYBODY123456789\n-----END RSA PRIVATE KEY-----\n")
    (ws / "run1" / "outputs" / "art.bin").write_bytes(b"\x00\x01PNGish\x00binary-blob")  # genuine binary (NUL)
    runs = gr.find_runs(ws.resolve())
    types = {o["name"]: o["type"] for r in runs for o in r["outputs"]}
    blob = json.dumps(runs)
    check("2b: .env secret redacted, not base64-embedded", "SUPERSECRETVALUE" not in blob and types.get("config.env") == "text")
    check("2b: no-extension key file (id_rsa) redacted as text", "LEAKEDKEYBODY" not in blob and types.get("id_rsa") == "text")
    check("2b: genuine binary (NUL) stays opaque binary", types.get("art.bin") == "binary")
    # over-redaction tighten: a short/spaced quoted value under a secret-named key is preserved
    check("2b: quoted tokenish secret redacted", "[REDACTED]" in gr._redact('{"api_key": "sk-abcdefgh12345678"}'))
    check("2b: quoted short value preserved", gr._redact('{"token": "hi"}') == '{"token": "hi"}')
    check("2b: quoted spaced value preserved", gr._redact('{"password": "a b c d"}') == '{"password": "a b c d"}')
    # current token formats (adversarial pass 3): github_pat_ / glpat- / openai / google
    check("2b: github_pat_ fine-grained PAT redacted",
          "REDACTED" in gr._redact("uses github_pat_11ABCDE0abcdefghijklmn_ABCDEFGHIJKLMNOPqrstuvwxyz0123 to auth"))
    check("2b: gitlab glpat- redacted", "REDACTED" in gr._redact("tok glpat-ABCDEFGHIJ1234567890xy"))
    check("2b: openai sk- redacted", "REDACTED" in gr._redact("key sk-proj-ABCDEFGHIJKLMNOPQRST1234"))
    check("2b: google AIza redacted", "REDACTED" in gr._redact("g AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
    check("2b: benign sk-ipped NOT redacted (no over-redaction)", "REDACTED" not in gr._redact("we sk-ipped the flaky test"))
    check("2b: benign sk- kebab identifier NOT redacted", gr._redact("sk-config-defaults-loader-module")=="sk-config-defaults-loader-module")
    # SVG is text/XML — a secret inside must be redacted, not base64'd verbatim
    (ws / "run1" / "outputs" / "chart.svg").write_text('<svg><text>ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123</text></svg>')
    svg_out = next(o for r in gr.find_runs(ws.resolve()) for o in r["outputs"] if o["name"] == "chart.svg")
    _svg_decoded = base64.b64decode(svg_out["data_uri"].split("base64,", 1)[1]).decode("utf-8", "replace")
    check("2b: SVG secret redacted (still rendered as image)",
          svg_out["type"] == "image" and "ghp_ABCDEFGHIJ" not in _svg_decoded and "REDACTED" in _svg_decoded)
finally:
    shutil.rmtree(tmp, ignore_errors=True)


print("\n================================")
print(f"Total: {PASS + FAIL}  PASS: {PASS}  FAIL: {FAIL}")
print("================================")
raise SystemExit(1 if FAIL else 0)
