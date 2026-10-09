#!/usr/bin/env bash
# host-refusal-class.sh — the refusal-reason classifier for ONE host API response.
#
# SOURCED, never executed. It defines functions and returns: no main, no side effect
# at source time, no caller global read, and no `exit` anywhere, so a sourcing tool
# keeps control of its own flow. The house form of the other release/tools/lib/
# libraries (frontmatter-strip.sh, platform-toggle.sh).
#
# WHY A LIBRARY. Two tools classify host responses: the pre-launch gate's host-API
# evaluator (release/tools/host-api-axis-verdict.sh) and the close-out automation
# (release/tools/automated-closeout.sh). Two copies of one binding drift, so the
# binding lives here once and both tools source it. The evaluator fails closed when
# it cannot source this file; a consumer that sources it tolerantly must treat an
# absent classifier as "could not classify", never as "answered".
#
# THE RULE lives in release/references/standards/quota-budget-protocol.md § 4.3b —
# Refusal-reason classifier. This file implements that section's GitHub reference
# binding and does not restate the rule's rationale. Its load-bearing sentence: the
# class is decided by the refusal reason, never by the fact of failure.
#
# ─── THE CONTRACT (fixed; both consumers key on these spellings) ────────────────────
#
#   host_refusal_class <rest|graphql> <out-file> <err-file> <rc>
#       <out-file>, <err-file> and <rc> are the stdout, stderr and exit status of ONE
#       `gh api -i` call. Prints ONE line:
#           <class>\t<subclass>\t<status>\t<reason>
#         class     answered | refused-quota | failed-transport | failed-other
#         subclass  primary | secondary | unspecified | -
#         status    the HTTP status, or - when the response carried no status line
#         reason    one line and never empty; no TAB, '|' or newline; at most 120
#                   characters; never a URL, and never an account's numeric user ID
#       Returns 0 when it classified, whatever the class, and 2 when it could not
#       run: the wrong arity, a transport other than rest|graphql, an unreadable
#       file, a non-integer rc, or no /usr/bin/python3.
#
#   host_response_headers <out-file>
#       One "name<TAB>value" line per response header, names lower-cased and CR
#       stripped. A caller matches header NAMES exactly and never by substring: every
#       live response carries Access-Control-Expose-Headers, whose VALUE lists
#       Retry-After and the X-RateLimit-* names. Empty output for a response that
#       carried no status line. Returns 0, or 2 when it could not run.
#
#   host_response_body <out-file>
#       The body after the first blank line, CR stripped. Empty output for a response
#       that carried no status line. Returns 0, or 2 when it could not run.
#
# ─── THE BYTE LAYOUT ─────────────────────────────────────────────────────────────────
# `gh api -i` writes the status line with LF and the headers with CRLF, then one
# CRLF CRLF, then the body; a live response carries no LF LF pair. One parser serves
# all three functions. It reads with newline translation OFF and strips CR
# explicitly: a text-mode read translates CRLF on input and hides the very bytes it is
# parsing.
#
# ─── THE GITHUB BINDING (first match wins; the call's own response only) ────────────
#
#    #  transport  condition                                                class
#    1  both       no status line and gh exit 1                             failed-transport
#    2  both       no status line and any other exit (0; 4 unauthenticated;
#                  127 missing binary; ...)                                 failed-other
#    3  both       status line unparseable                                  failed-other
#    4  rest       2xx and exit 0, whatever the body text                   answered
#    5  graphql    2xx, exit 0 and a JSON body with no `errors` member,
#                  whatever the data text                                   answered
#    6  graphql    2xx whose body is not JSON                               failed-other
#    7  both       a quota-eligible error with x-ratelimit-remaining: 0     refused-quota primary
#    8  both       a quota-eligible error carrying retry-after              refused-quota secondary
#    9  both       a quota-eligible error whose message names a secondary
#                  rate limit or abuse detection                            refused-quota secondary
#   10  graphql    a 2xx whose errors[].type is RATE_LIMITED, not matched
#                  above                                                    refused-quota unspecified
#   11  both       status 429, or a quota-eligible error whose message says
#                  "API rate limit", not matched above                      refused-quota unspecified
#   12  both       everything else: 401; a 403 without quota signals; 404;
#                  422; any 5xx, a 5xx carrying retry-after included;
#                  GraphQL errors of any other type                         failed-other
#
# A QUOTA-ELIGIBLE ERROR is, for rest, status 403 or 429. For graphql it is status 403
# or 429, or a 2xx whose JSON body carries `errors`: the host documents that a GraphQL
# primary-limit refusal arrives as a 200 with an error message and
# x-ratelimit-remaining: 0, and a secondary one as a 200 or a 403. A rest-only rule set
# reads those as answered, which is why the transport is an argument.
#
# THE TWO BOUNDARY RULES. Rows 1 and 2, and the eligibility gate on rows 7 to 11, are
# what keep a class from contradicting the remedy it drives (quota: wait for the
# reset; transport: re-run; other: fix the input or the credential). A missing status
# line is transport only on gh exit 1, which is what a refused proxy and a DNS failure
# exit with; no credentials exits 4 before any request is made, and a missing binary
# exits 127. A 503 carrying Retry-After is transient routing, not a quota refusal.
#
# x-ratelimit-* headers on an ANSWERED response are readings, never refusal signals:
# rows 4 and 5 are evaluated before any quota row. Quota wording anywhere other than the
# refusing call's own response — a 2xx body that quotes a refusal, a comment, a log
# line, an agent-runtime notice — is never a refusal, because nothing but that response
# reaches the parser.
#
# PORTABILITY: bash-3.2 portable; /usr/bin/python3 standard library only, by absolute
# path; no jq.

host_refusal_class() {
  [ "$#" -eq 4 ] || return 2
  case "$1" in rest|graphql) ;; *) return 2 ;; esac
  [ -r "$2" ] && [ -r "$3" ] || return 2
  case "$4" in ''|*[!0-9]*) return 2 ;; esac
  _hrc_run classify "$1" "$2" "$3" "$4"
}

host_response_headers() {
  [ "$#" -eq 1 ] && [ -r "$1" ] || return 2
  _hrc_run headers "$1"
}

host_response_body() {
  [ "$#" -eq 1 ] && [ -r "$1" ] || return 2
  _hrc_run body "$1"
}

# _hrc_run MODE ARGS... — the one parser behind the three public functions. Private:
# a caller uses the three functions above, whose argument checks this does not repeat.
_hrc_run() {
  [ -x /usr/bin/python3 ] || return 2
  /usr/bin/python3 - "$@" <<'PY' || return 2
import json, re, sys

URL_RE = re.compile(r"[A-Za-z][A-Za-z0-9+.-]*://\S*")
PATH_RE = re.compile(r"\brepos/\S+")
UID_RE = re.compile(r"(user ID)\s+\d+", re.I)


def read_text(path):
    # newline translation OFF, CR stripped explicitly (see the file header)
    with open(path, "r", encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read().replace("\r", "")


def clean(text, fallback):
    t = URL_RE.sub("<url>", str(text or ""))
    t = PATH_RE.sub("<path>", t)
    t = UID_RE.sub(r"\1 <id>", t)
    t = " ".join(re.sub(r"[\t\n|]+", " ", t).split())
    return (t or fallback)[:120]


def parse(out):
    """-> (has_status_line, status_or_None, [(name, value)], body)"""
    if not out.startswith("HTTP/"):
        return False, None, [], ""
    head, _, body = out.partition("\n\n")
    lines = head.split("\n")
    parts = lines[0].split()
    status = int(parts[1]) if len(parts) >= 2 and parts[1].isdigit() else None
    headers = []
    for line in lines[1:]:
        name, colon, value = line.partition(":")
        if colon:
            headers.append((name.strip().lower(), value.strip()))
    return True, status, headers, body


def classify(transport, out_path, err_path, rc):
    out = read_text(out_path)
    err = read_text(err_path)
    has_status, status, headers, body = parse(out)
    if not has_status:
        if rc == 1:                                                   # row 1
            last = ""
            for ln in reversed(err.split("\n")):
                if ln.strip():
                    last = ln.strip()
                    break
            return "failed-transport", "-", "-", clean(last.rsplit(": ", 1)[-1], "no response")
        return "failed-other", "-", "-", "no status line (exit %d)" % rc  # row 2
    if status is None:                                                # row 3
        return "failed-other", "-", "-", "unparseable status line"
    hdr = {}
    for name, value in headers:
        hdr.setdefault(name, value)
    ok2xx = 200 <= status < 300
    try:
        js, js_ok = json.loads(body), True
    except ValueError:
        js, js_ok = None, False
    has_errors = isinstance(js, dict) and "errors" in js
    if transport == "rest" and ok2xx and rc == 0:                     # row 4
        return "answered", "-", status, "HTTP %d" % status
    if transport == "graphql" and ok2xx:
        if not js_ok:                                                 # row 6
            return "failed-other", "-", status, "HTTP %d with a body that is not JSON" % status
        if rc == 0 and not has_errors:                                # row 5
            return "answered", "-", status, "HTTP %d" % status
    messages, types = [], []
    if isinstance(js, dict):
        if isinstance(js.get("message"), str):
            messages.append(js["message"])
        if isinstance(js.get("errors"), list):
            for e in js["errors"]:
                if isinstance(e, dict):
                    if isinstance(e.get("message"), str):
                        messages.append(e["message"])
                    types.append(e.get("type"))
    msg = " ".join(messages)
    eligible = status in (403, 429) or (transport == "graphql" and ok2xx and has_errors)
    fallback = "HTTP %d" % status
    if eligible and hdr.get("x-ratelimit-remaining") == "0":          # row 7
        return "refused-quota", "primary", status, clean(msg, fallback)
    if eligible and "retry-after" in hdr:                             # row 8
        why = "retry-after %s: %s" % (hdr["retry-after"], msg)
        return "refused-quota", "secondary", status, clean(why, fallback)
    if eligible and re.search(r"secondary rate limit|abuse detection", msg, re.I):  # row 9
        return "refused-quota", "secondary", status, clean(msg, fallback)
    if transport == "graphql" and ok2xx and "RATE_LIMITED" in types:  # row 10
        return "refused-quota", "unspecified", status, clean(msg, fallback)
    if status == 429 or (eligible and re.search(r"API rate limit", msg, re.I)):  # row 11
        return "refused-quota", "unspecified", status, clean(msg, fallback)
    return "failed-other", "-", status, clean(msg, fallback)          # row 12


def emit(text):
    sys.stdout.buffer.write(text.encode("utf-8", "replace"))


def main(argv):
    mode = argv[1] if len(argv) > 1 else ""
    if mode == "classify":
        c = classify(argv[2], argv[3], argv[4], int(argv[5]))
        emit("%s\t%s\t%s\t%s\n" % c)
        return 0
    if mode == "headers":
        _, _, headers, _ = parse(read_text(argv[2]))
        emit("".join("%s\t%s\n" % (n, v.replace("\t", " ")) for n, v in headers))
        return 0
    if mode == "body":
        emit(parse(read_text(argv[2]))[3])
        return 0
    return 2


try:
    sys.exit(main(sys.argv))
except SystemExit:
    raise
except Exception:
    sys.exit(2)
PY
}
