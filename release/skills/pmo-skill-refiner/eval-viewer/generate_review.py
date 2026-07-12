#!/usr/bin/env python3
"""Generate and serve a review page for eval results.

Reads the workspace directory, discovers runs (directories with outputs/),
embeds all output data into a self-contained HTML page, and serves it via
a tiny HTTP server. Feedback auto-saves to feedback.json in the workspace.

Usage:
    python generate_review.py <workspace-path> [--port PORT] [--skill-name NAME]
    python generate_review.py <workspace-path> --previous-feedback /path/to/old/feedback.json

No dependencies beyond the Python stdlib are required.

SECURITY (GHSA-fxcr-7x63-3g94):
  - The HTTP server binds 127.0.0.1 and is UNAUTHENTICATED — a local, single-user review
    tool. Do not expose the port. Writes (POST /api/feedback) require a same-origin Host
    header plus a per-run CSRF token, which resists CSRF and DNS-rebinding.
  - Output/metadata files are read ONLY when they resolve INSIDE the workspace root; a
    symlink whose target escapes the workspace is skipped, never followed.
  - Embedded text is size-capped and passed through a best-effort secret/PII redaction
    pass before it is written into the served page or a shareable static HTML file.
    Redaction is best-effort, not a guarantee — treat generated HTML as sensitive.
"""

from __future__ import annotations

import argparse
import base64
import hmac
import json
import mimetypes
import os
import re
import secrets
import signal
import subprocess
import sys
import time
import webbrowser
from functools import partial
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse

# Files to exclude from output listings
METADATA_FILES = {"transcript.md", "user_notes.md", "metrics.json"}

# Extensions we render as inline text
TEXT_EXTENSIONS = {
    ".txt", ".md", ".json", ".csv", ".py", ".js", ".ts", ".tsx", ".jsx",
    ".yaml", ".yml", ".xml", ".html", ".css", ".sh", ".rb", ".go", ".rs",
    ".java", ".c", ".cpp", ".h", ".hpp", ".sql", ".r", ".toml",
    # secret-carrying text files — route through the redacting text path, not base64
    # (GHSA-fxcr 2b). A no-/rare-extension text file (e.g. id_rsa) is still caught by the
    # NUL-byte text sniff in embed_file's fallback branch.
    ".env", ".pem", ".key", ".crt", ".cer", ".pub", ".cfg", ".conf", ".ini",
    ".properties", ".tf", ".log",
}

# Extensions we render as inline images
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}

# MIME type overrides for common types
MIME_OVERRIDES = {
    ".svg": "image/svg+xml",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


def get_mime_type(path: Path) -> str:
    ext = path.suffix.lower()
    if ext in MIME_OVERRIDES:
        return MIME_OVERRIDES[ext]
    mime, _ = mimetypes.guess_type(str(path))
    return mime or "application/octet-stream"


# --- Security: confinement, size cap, redaction (GHSA-fxcr-7x63-3g94) ---

# Max bytes embedded from a single output file. Larger text is truncated with a visible
# marker; larger binary is skipped with a notice — so a huge (or maliciously large) file
# cannot balloon the served page or the shareable static HTML.
MAX_EMBED_BYTES = 512 * 1024          # 512 KiB — text
MAX_EMBED_BINARY_BYTES = 4 * 1024 * 1024  # 4 MiB — images/pdf/xlsx/binary data: URIs

# Best-effort secret/PII redaction. LINEAR-time patterns only (no catastrophic
# backtracking). NOT a guarantee — treat any generated HTML as sensitive regardless.
# PEM private key. The body is BOUNDED ({0,4096}?), never `.*?`-to-EOF: a lazy scan to EOF
# for every BEGIN with no matching END is O(n^2) — a ReDoS (adversarial-review finding: 512
# KiB of repeated BEGIN markers hung ~29s). A real key body is well under 4 KiB, and the
# bound plus a length-capped `[A-Z0-9 ]{0,40}` key-type keep this linear. _redact ALSO skips
# this pattern entirely when the text has no "-----END" marker (the BEGIN-only ReDoS input),
# so that case costs a single substring scan rather than a bounded scan per BEGIN.
_PEM_RE = re.compile(r"-----BEGIN [A-Z0-9 ]{0,40}PRIVATE KEY-----[\s\S]{0,4096}?-----END [A-Z0-9 ]{0,40}PRIVATE KEY-----")

_REDACTIONS = [
    (_PEM_RE, "[REDACTED PRIVATE KEY]"),
    (re.compile(r"\bAKIA[0-9A-Z]{16}\b"), "[REDACTED AWS ACCESS KEY]"),
    # GitHub: classic gh?_ tokens AND github_pat_ fine-grained PATs (GitHub's default since
    # 2022 — the classic-only pattern missed them; adversarial-review finding).
    (re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{22,})\b"), "[REDACTED GITHUB TOKEN]"),
    (re.compile(r"\bglpat-[A-Za-z0-9_-]{20,}\b"), "[REDACTED GITLAB TOKEN]"),
    # OpenAI keys are CONTIGUOUS alphanumeric after the prefix — restrict to [A-Za-z0-9]
    # (not `-`/`_`) so a benign kebab-case identifier like `sk-this-is-a-long-name` is not
    # mangled (adversarial-review over-redaction note; `sk-` is a common code/English prefix).
    (re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9]{20,}"), "[REDACTED OPENAI KEY]"),
    (re.compile(r"\bAIza[0-9A-Za-z_-]{35,}"), "[REDACTED GOOGLE API KEY]"),
    (re.compile(r"\b[sr]k_live_[A-Za-z0-9]{20,}\b"), "[REDACTED STRIPE KEY]"),
    (re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{8,}\b"), "[REDACTED SLACK TOKEN]"),
    (re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}\b"), "[REDACTED JWT]"),
    # secret-named key with a QUOTED value (config / JSON / env): redact a token-shaped
    # value (no whitespace, >=8 chars) so a short or spaced benign value like
    # `"password_hint": "your favorite color"` is preserved (adversarial-review over-
    # redaction note); a real quoted secret has no spaces.
    (re.compile(r"(?im)((?:api[_-]?key|secret|token|password|passwd|client[_-]?secret|authorization|bearer)[\"']?\s*[:=]\s*[\"'])([^\"'\s]{8,})([\"'])"),
     r"\1[REDACTED]\3"),
    # secret-named key with an UNQUOTED long token (>=16 tokenish chars) — catches .env
    # style `API_KEY=sk-...`. The length + charset floor avoids mangling ordinary code/prose
    # like `assert token == expected`, `secret = compute_hash(x)`, `password: never share`
    # (adversarial-review over-redaction finding).
    (re.compile(r"(?im)((?:api[_-]?key|secret|token|password|passwd|client[_-]?secret|authorization|bearer)\s*[:=]\s*)([A-Za-z0-9_\-./+=]{16,})"),
     r"\1[REDACTED]"),
]


def _redact(text: str) -> str:
    has_end = "-----END" in text
    for pat, repl in _REDACTIONS:
        if pat is _PEM_RE and not has_end:
            continue  # no END marker => no PEM block; skip the only bounded-scan pattern
        text = pat.sub(repl, text)
    return text


def _within_root(path: Path, root: Path) -> Path | None:
    """Resolve path and return it ONLY if it lies inside root (else None). Single
    confinement chokepoint (GHSA-fxcr 2a): a symlink whose target escapes the workspace
    resolves to an out-of-root path and is rejected, so it is never read. root MUST
    already be resolved by the caller (main()/find_runs pass a resolved root)."""
    try:
        resolved = path.resolve()
    except (OSError, RuntimeError):  # RuntimeError = symlink loop
        return None
    return resolved if resolved.is_relative_to(root) else None


def _within_root_file(path: Path, root: Path) -> Path | None:
    """_within_root plus a REGULAR-file + single-link check. Rejects a hardlink (st_nlink
    > 1) whose second name may live OUTSIDE the workspace: resolve() only follows symlinks,
    so a hardlink has no path component that escapes root and would otherwise be read
    verbatim (GHSA-fxcr 2a hardlink vector). Also rejects fifos/devices/dirs."""
    resolved = _within_root(path, root)
    if resolved is None:
        return None
    try:
        if not resolved.is_file() or resolved.stat().st_nlink > 1:
            return None
    except OSError:
        return None
    return resolved


def _safe_read_text(path: Path, root: Path) -> str | None:
    """Read text ONLY if path resolves inside root (regular, single-link); size-capped +
    redacted. None when the path escapes the workspace, is a hardlink, or cannot be read."""
    resolved = _within_root_file(path, root)
    if resolved is None:
        return None
    try:
        with open(resolved, "r", errors="replace") as fh:
            data = fh.read(MAX_EMBED_BYTES + 1)
    except OSError:
        return None
    if len(data) > MAX_EMBED_BYTES:
        data = data[:MAX_EMBED_BYTES] + f"\n\n[... truncated at {MAX_EMBED_BYTES} bytes ...]"
    return _redact(data)


def _safe_read_bytes(path: Path, root: Path, max_bytes: int = MAX_EMBED_BINARY_BYTES) -> bytes | None:
    """Read bytes ONLY if path resolves inside root (regular, single-link); capped at
    max_bytes. None when the path escapes the workspace, is a hardlink, cannot be read, or
    exceeds the cap."""
    resolved = _within_root_file(path, root)
    if resolved is None:
        return None
    try:
        with open(resolved, "rb") as fh:
            data = fh.read(max_bytes + 1)
    except OSError:
        return None
    return None if len(data) > max_bytes else data


def _read_operator_json(path: Path):
    """Read an OPERATOR-supplied JSON file (--benchmark). NOT workspace-confined — the
    operator names it and it may legitimately live outside the eval workspace — but size-
    capped + redacted before it is embedded into the served page and the shareable static
    HTML, so a secret in a benchmark file does not leak in the clear and a huge one cannot
    balloon the artifact (GHSA-fxcr 2b: the benchmark is embedded like any other text)."""
    try:
        with open(path, "r", errors="replace") as fh:
            data = fh.read(MAX_EMBED_BYTES + 1)
    except OSError:
        return None
    if len(data) > MAX_EMBED_BYTES:
        return None  # oversized benchmark — skip rather than embed a truncated/huge blob
    try:
        return json.loads(_redact(data))
    except (json.JSONDecodeError, ValueError):
        return None


def find_runs(workspace: Path) -> list[dict]:
    """Recursively find directories that contain an outputs/ subdirectory."""
    runs: list[dict] = []
    _find_runs_recursive(workspace, workspace, runs)
    runs.sort(key=lambda r: (r.get("eval_id", float("inf")), r["id"]))
    return runs


def _find_runs_recursive(root: Path, current: Path, runs: list[dict]) -> None:
    # Confinement (GHSA-fxcr 2a): never descend a directory (or dir symlink) whose target
    # escapes the workspace root.
    if _within_root(current, root) is None or not current.is_dir():
        return

    outputs_dir = current / "outputs"
    if _within_root(outputs_dir, root) is not None and outputs_dir.is_dir():
        run = build_run(root, current)
        if run:
            runs.append(run)
        return

    skip = {"node_modules", ".git", "__pycache__", "skill", "inputs"}
    for child in sorted(current.iterdir()):
        if child.is_dir() and child.name not in skip and _within_root(child, root) is not None:
            _find_runs_recursive(root, child, runs)


def build_run(root: Path, run_dir: Path) -> dict | None:
    """Build a run dict with prompt, outputs, and grading data. Every file read is
    confined to the workspace root and passes through size-cap + redaction (GHSA-fxcr)."""
    prompt = ""
    eval_id = None

    # Try eval_metadata.json (confined read)
    for candidate in [run_dir / "eval_metadata.json", run_dir.parent / "eval_metadata.json"]:
        raw = _safe_read_text(candidate, root)
        if raw is None:
            continue
        try:
            metadata = json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            metadata = None
        if isinstance(metadata, dict):
            prompt = metadata.get("prompt", "") or ""
            eval_id = metadata.get("eval_id")
        if prompt:
            break

    # Fall back to transcript.md (confined read)
    if not prompt:
        for candidate in [run_dir / "transcript.md", run_dir / "outputs" / "transcript.md"]:
            text = _safe_read_text(candidate, root)
            if text is None:
                continue
            match = re.search(r"## Eval Prompt\n\n([\s\S]*?)(?=\n##|$)", text)
            if match:
                prompt = match.group(1).strip()
            if prompt:
                break

    if not prompt:
        prompt = "(No prompt found)"

    run_id = str(run_dir.relative_to(root)).replace("/", "-").replace("\\", "-")

    # Collect output files (embed_file re-confines + caps + redacts each read)
    outputs_dir = run_dir / "outputs"
    output_files: list[dict] = []
    if _within_root(outputs_dir, root) is not None and outputs_dir.is_dir():
        for f in sorted(outputs_dir.iterdir()):
            if f.name in METADATA_FILES:
                continue
            if _within_root(f, root) is None:
                continue  # symlink escaping the workspace — skip, never read (2a)
            if f.is_file():
                output_files.append(embed_file(f, root))

    # Load grading if present (confined read)
    grading = None
    for candidate in [run_dir / "grading.json", run_dir.parent / "grading.json"]:
        raw = _safe_read_text(candidate, root)
        if raw is None:
            continue
        try:
            parsed = json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            parsed = None
        if parsed:
            grading = parsed
            break

    return {
        "id": run_id,
        "prompt": prompt,
        "eval_id": eval_id,
        "outputs": output_files,
        "grading": grading,
    }


def embed_file(path: Path, root: Path) -> dict:
    """Read a file and return an embedded representation. Confined to root; text is
    size-capped + redacted, binary is size-capped (GHSA-fxcr 2a/2b). A path that escapes
    the workspace, is unreadable, or exceeds the cap yields a skip notice, never a read."""
    ext = path.suffix.lower()
    mime = get_mime_type(path)

    if ext in TEXT_EXTENSIONS:
        content = _safe_read_text(path, root)
        if content is None:
            content = "(Skipped: unreadable or outside the workspace)"
        return {
            "name": path.name,
            "type": "text",
            "content": content,
        }

    if ext == ".svg":
        # SVG is text/XML, not opaque binary — a token/PEM in a <text> element or an XML
        # comment would otherwise ship base64-verbatim into the served page AND the static
        # HTML (image branch precedes the NUL sniff; adversarial-review 2b finding). Redact
        # the source, then render the REDACTED SVG (still an inline image).
        svg = _safe_read_text(path, root)
        if svg is None:
            return {"name": path.name, "type": "error", "content": "(Skipped: unreadable or outside the workspace)"}
        b64 = base64.b64encode(svg.encode("utf-8")).decode("ascii")
        return {"name": path.name, "type": "image", "mime": "image/svg+xml", "data_uri": f"data:image/svg+xml;base64,{b64}"}

    # Binary families (image / pdf / xlsx / other) all base64 a byte payload.
    raw = _safe_read_bytes(path, root)
    if raw is None:
        return {
            "name": path.name,
            "type": "error",
            "content": f"(Skipped: unreadable, outside the workspace, or larger than {MAX_EMBED_BINARY_BYTES} bytes)",
        }
    if ext in IMAGE_EXTENSIONS:
        return {"name": path.name, "type": "image", "mime": mime, "data_uri": f"data:{mime};base64,{base64.b64encode(raw).decode('ascii')}"}
    elif ext == ".pdf":
        return {"name": path.name, "type": "pdf", "data_uri": f"data:{mime};base64,{base64.b64encode(raw).decode('ascii')}"}
    elif ext == ".xlsx":
        return {"name": path.name, "type": "xlsx", "data_b64": base64.b64encode(raw).decode("ascii")}
    else:
        # Unknown extension: may still be a TEXT file carrying secrets (.env, .pem, .key,
        # id_rsa and other rare-/no-extension credential files). If the bytes are text-like
        # (no NUL byte), redact + embed as TEXT so secrets are not shipped base64-in-the-clear
        # into the served page AND the shareable static HTML — redaction keyed on
        # TEXT_EXTENSIONS alone missed the exact secret-dense file class the patterns name
        # (adversarial-review 2b gap). Genuine binary (NUL present) stays an opaque data: URI.
        if b"\x00" not in raw:
            text = _safe_read_text(path, root)
            if text is not None:
                return {"name": path.name, "type": "text", "content": text}
        return {"name": path.name, "type": "binary", "mime": mime, "data_uri": f"data:{mime};base64,{base64.b64encode(raw).decode('ascii')}"}


def load_previous_iteration(workspace: Path) -> dict[str, dict]:
    """Load previous iteration's feedback and outputs.

    Returns a map of run_id -> {"feedback": str, "outputs": list[dict]}.
    """
    result: dict[str, dict] = {}

    # Load feedback (confined read)
    feedback_map: dict[str, str] = {}
    feedback_path = workspace / "feedback.json"
    raw = _safe_read_text(feedback_path, workspace)
    if raw is not None:
        try:
            data = json.loads(raw)
            feedback_map = {
                r["run_id"]: r["feedback"]
                for r in data.get("reviews", [])
                if r.get("feedback", "").strip()
            }
        except (json.JSONDecodeError, ValueError, KeyError, AttributeError, TypeError):
            pass

    # Load runs (to get outputs)
    prev_runs = find_runs(workspace)
    for run in prev_runs:
        result[run["id"]] = {
            "feedback": feedback_map.get(run["id"], ""),
            "outputs": run.get("outputs", []),
        }

    # Also add feedback for run_ids that had feedback but no matching run
    for run_id, fb in feedback_map.items():
        if run_id not in result:
            result[run_id] = {"feedback": fb, "outputs": []}

    return result


def generate_html(
    runs: list[dict],
    skill_name: str,
    previous: dict[str, dict] | None = None,
    benchmark: dict | None = None,
    csrf_token: str = "",
) -> str:
    """Generate the complete standalone HTML page with embedded data. csrf_token is the
    per-server-run token the page must echo on POST /api/feedback (empty in --static
    mode, which has no server to write to)."""
    template_path = Path(__file__).parent / "viewer.html"
    template = template_path.read_text()

    # Build previous_feedback and previous_outputs maps for the template
    previous_feedback: dict[str, str] = {}
    previous_outputs: dict[str, list[dict]] = {}
    if previous:
        for run_id, data in previous.items():
            if data.get("feedback"):
                previous_feedback[run_id] = data["feedback"]
            if data.get("outputs"):
                previous_outputs[run_id] = data["outputs"]

    embedded = {
        "skill_name": skill_name,
        "runs": runs,
        "previous_feedback": previous_feedback,
        "previous_outputs": previous_outputs,
        "csrf_token": csrf_token,
    }
    if benchmark:
        embedded["benchmark"] = benchmark

    # Defense-in-depth transport escaping (GHSA-rw36-5pf9-w2vc): the placeholder sits
    # INSIDE an inline <script> block, and json.dumps does not escape &, <, or > — so a
    # value containing </script> would break out of the script context. Escaping them to
    # \\u00XX keeps the JSON inert at the parser boundary. (U+2028/U+2029 need no handling
    # here: json.dumps defaults to ensure_ascii=True, which already escapes them.) The
    # load-bearing XSS defense is per-sink escaping at render time in viewer.html; this is
    # the belt-and-suspenders transport layer.
    data_json = (
        json.dumps(embedded)
        .replace("&", "\\u0026")
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
    )

    return template.replace("/*__EMBEDDED_DATA__*/", f"const EMBEDDED_DATA = {data_json};")


# ---------------------------------------------------------------------------
# HTTP server (stdlib only, zero dependencies)
# ---------------------------------------------------------------------------

def _kill_port(port: int) -> None:
    """Kill any process listening on the given port."""
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True, text=True, timeout=5,
        )
        for pid_str in result.stdout.strip().split("\n"):
            if pid_str.strip():
                try:
                    os.kill(int(pid_str.strip()), signal.SIGTERM)
                except (ProcessLookupError, ValueError):
                    pass
        if result.stdout.strip():
            time.sleep(0.5)
    except subprocess.TimeoutExpired:
        pass
    except FileNotFoundError:
        print("Note: lsof not found, cannot check if port is in use", file=sys.stderr)

class ReviewHandler(BaseHTTPRequestHandler):
    """Serves the review HTML and handles feedback saves.

    Regenerates the HTML on each page load so that refreshing the browser
    picks up new eval outputs without restarting the server.
    """

    # Loopback origins accepted by the Host/Origin gates below.
    _LOCAL_HOSTS = {"127.0.0.1", "localhost", "::1", "[::1]"}

    def __init__(
        self,
        workspace: Path,
        skill_name: str,
        feedback_path: Path,
        previous: dict[str, dict],
        benchmark_path: Path | None,
        csrf_token: str,
        *args,
        **kwargs,
    ):
        self.workspace = workspace
        self.skill_name = skill_name
        self.feedback_path = feedback_path
        self.previous = previous
        self.benchmark_path = benchmark_path
        self.csrf_token = csrf_token
        super().__init__(*args, **kwargs)

    # --- CSRF / DNS-rebinding defenses (GHSA-fxcr 2c) ---
    def _host_ok(self) -> bool:
        """Reject a request whose Host header is not our loopback origin — the DNS-
        rebinding defense (a rebound attacker domain arrives in Host as itself, not
        127.0.0.1/localhost)."""
        host = self.headers.get("Host", "")
        hostname = host.rsplit(":", 1)[0] if ":" in host and not host.endswith("]") else host
        return hostname in self._LOCAL_HOSTS

    def _origin_ok(self) -> bool:
        """If Origin/Referer is present it MUST be our loopback origin (CSRF defense).
        Absent is allowed — same-origin non-CORS requests omit Origin; the CSRF token is
        the primary gate for those."""
        ref = self.headers.get("Origin") or self.headers.get("Referer")
        if not ref:
            return True
        try:
            return urlparse(ref).hostname in self._LOCAL_HOSTS
        except ValueError:
            return False

    def _csrf_ok(self) -> bool:
        provided = self.headers.get("X-CSRF-Token", "")
        if not self.csrf_token:
            return False
        try:
            return hmac.compare_digest(provided, self.csrf_token)
        except TypeError:
            # http.server decodes headers as latin-1; a non-ASCII byte makes compare_digest
            # raise. Fail CLOSED (a valid token is ASCII url-safe base64) — a clean 403, not
            # an unhandled per-request traceback.
            return False

    def do_GET(self) -> None:
        if not self._host_ok():
            self.send_error(403, "Forbidden")
            return
        if self.path == "/" or self.path == "/index.html":
            # Regenerate HTML on each request (re-scans workspace for new outputs)
            runs = find_runs(self.workspace)
            benchmark = None
            if self.benchmark_path and self.benchmark_path.exists():
                benchmark = _read_operator_json(self.benchmark_path)
            html = generate_html(runs, self.skill_name, self.previous, benchmark, self.csrf_token)
            content = html.encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == "/api/feedback":
            # Host is already checked above (DNS-rebind). Add the same-origin check to the
            # READ path so it does not silently depend on the browser's opaque-response
            # behavior for a cross-origin fetch (GHSA-fxcr 2c, defense-in-depth).
            if not self._origin_ok():
                self.send_error(403, "Forbidden")
                return
            data = b"{}"
            if self.feedback_path.exists():
                data = self.feedback_path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_error(404)

    def do_POST(self) -> None:
        if self.path == "/api/feedback":
            # CSRF / DNS-rebinding gate (GHSA-fxcr 2c): require our loopback Host, a
            # same-origin (or absent) Origin, AND the per-run CSRF token. A cross-site
            # "simple" POST (text/plain, no preflight) cannot read the token, so it 403s.
            if not (self._host_ok() and self._origin_ok() and self._csrf_ok()):
                self.send_error(403, "Forbidden (CSRF/host check failed)")
                return
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                if not isinstance(data, dict) or "reviews" not in data:
                    raise ValueError("Expected JSON object with 'reviews' key")
                self.feedback_path.write_text(json.dumps(data, indent=2) + "\n")
                resp = b'{"ok":true}'
                self.send_response(200)
            except (json.JSONDecodeError, OSError, ValueError) as e:
                resp = json.dumps({"error": str(e)}).encode()
                self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        else:
            self.send_error(404)

    def log_message(self, format: str, *args: object) -> None:
        # Suppress request logging to keep terminal clean
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and serve eval review")
    parser.add_argument("workspace", type=Path, help="Path to workspace directory")
    parser.add_argument("--port", "-p", type=int, default=3117, help="Server port (default: 3117)")
    parser.add_argument("--skill-name", "-n", type=str, default=None, help="Skill name for header")
    parser.add_argument(
        "--previous-workspace", type=Path, default=None,
        help="Path to previous iteration's workspace (shows old outputs and feedback as context)",
    )
    parser.add_argument(
        "--benchmark", type=Path, default=None,
        help="Path to benchmark.json to show in the Benchmark tab",
    )
    parser.add_argument(
        "--static", "-s", type=Path, default=None,
        help="Write standalone HTML to this path instead of starting a server",
    )
    args = parser.parse_args()

    workspace = args.workspace.resolve()
    if not workspace.is_dir():
        print(f"Error: {workspace} is not a directory", file=sys.stderr)
        sys.exit(1)

    runs = find_runs(workspace)
    if not runs:
        print(f"No runs found in {workspace}", file=sys.stderr)
        sys.exit(1)

    skill_name = args.skill_name or workspace.name.replace("-workspace", "")
    feedback_path = workspace / "feedback.json"

    previous: dict[str, dict] = {}
    if args.previous_workspace:
        previous = load_previous_iteration(args.previous_workspace.resolve())

    benchmark_path = args.benchmark.resolve() if args.benchmark else None
    benchmark = None
    if benchmark_path and benchmark_path.exists():
        benchmark = _read_operator_json(benchmark_path)

    if args.static:
        # Static mode has no server to POST to, so no CSRF token is meaningful.
        html = generate_html(runs, skill_name, previous, benchmark, "")
        args.static.parent.mkdir(parents=True, exist_ok=True)
        args.static.write_text(html)
        print(f"\n  Static viewer written to: {args.static}\n")
        sys.exit(0)

    # Kill any existing process on the target port
    port = args.port
    _kill_port(port)
    # Per-server-run CSRF token, embedded into the page and required on POST (GHSA-fxcr 2c).
    csrf_token = secrets.token_urlsafe(32)
    handler = partial(ReviewHandler, workspace, skill_name, feedback_path, previous, benchmark_path, csrf_token)
    try:
        server = HTTPServer(("127.0.0.1", port), handler)
    except OSError:
        # Port still in use after kill attempt — find a free one
        server = HTTPServer(("127.0.0.1", 0), handler)
        port = server.server_address[1]

    url = f"http://localhost:{port}"
    print(f"\n  Eval Viewer")
    print(f"  ─────────────────────────────────")
    print(f"  URL:       {url}")
    print(f"  Workspace: {workspace}")
    print(f"  Feedback:  {feedback_path}")
    if previous:
        print(f"  Previous:  {args.previous_workspace} ({len(previous)} runs)")
    if benchmark_path:
        print(f"  Benchmark: {benchmark_path}")
    print(f"\n  Press Ctrl+C to stop.\n")

    webbrowser.open(url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
