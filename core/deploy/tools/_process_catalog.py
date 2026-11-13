#!/usr/bin/env python3
"""_process_catalog.py — the shared library of the process-catalog tools.

PURPOSE
    One statement of everything the three catalog tools must agree on, so that
    the generator, the validator and the element inventory cannot disagree
    about what a root, a page, a citation or a register row is:

      * the DEFAULTS table — every root a tool reads or writes, as a named
        argument whose default follows its parent;
      * the one `git` wrapper every tool call goes through;
      * the loaders for the definitions pack, the ID registry, the controls
        register and the element-kinds table;
      * the register rules (one contiguous block, see REGISTER RULES below);
      * page discovery by layout, and the page model read through the shared
        frontmatter reader (`_frontmatter.py`) and nothing else;
      * the source-citation grammar, the fingerprint and re-resolution;
      * the source set of a page — the single place a path becomes files;
      * the generated surfaces: the graph, the index, the page regions the
        generator owns, and the cross-cutting views;
      * the census line every command prints last, and the summary block.

WHERE PATHS COME FROM
    Every root is an argument. Each default is a row of DEFAULTS, and a default
    follows its parent; no other line of the catalog tools names a path of this
    repository. The repository root is `--repo`, else the fourth parent of this
    file; no environment variable is read. A table that describes repository
    layout is a tracked data file reached through an argument. A path stored in
    a catalog file that names another catalog file is relative to the file that
    holds it. A tool finds its sibling modules and its fixtures relative to its
    own file.

USAGE
    A library: `from _process_catalog import ...` by the three catalog tools.
    python3 core/deploy/tools/_process_catalog.py --self-test

EXIT CODES (every catalog command)
    0  something was examined and nothing was wrong.
    1  findings.
    2  usage.
    3  not evaluated — an input could not be read, or nothing was examined.
       Never a pass.

Python 3.9 standard library only. The tools start `git` and no other program.
"""
from __future__ import annotations

import bisect
import hashlib
import importlib.util
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
from _frontmatter import frontmatter_end, frontmatter_lines, read_frontmatter  # noqa: E402

EXIT_CLEAN, EXIT_FINDINGS, EXIT_USAGE, EXIT_NOT_EVALUATED = 0, 1, 2, 3
STATUS_WORD = {EXIT_CLEAN: "pass", EXIT_FINDINGS: "fail", EXIT_NOT_EVALUATED: "not-evaluated"}
GENERATOR = "build-process-catalog.py"
LINK_CHECKER = "check-doc-links.py"

# ----------------------------------------------------------------------------------------------
# DEFAULTS — the one table of roots. A row is (name, parent, relative part, argument).
# A default follows its parent: passing a root moves every row beneath it, unless that row's own
# argument is passed. `fixtures` and `probe_source` are path prefixes inside a rule and are kept
# as repository-relative text; the other rows resolve to files and folders.
# ----------------------------------------------------------------------------------------------
DEFAULTS = (
    ("repo", None, None, "--repo"),
    ("catalog", "repo", "core/process-catalog", "--catalog-root"),
    ("definitions", "catalog", "definitions", "--definitions"),
    ("pack", "definitions", "pack.json", "--pack"),
    ("pack_document", "definitions", "definitions-pack.md", "--pack-document"),
    ("registry", "definitions", "id-registry.tsv", "--registry"),
    ("kinds", "definitions", "element-kinds.tsv", "--kinds"),
    ("fixtures", "repo", "core/deploy/tools/fixtures/process-catalog", "--fixture-root"),
    ("probe_source", "repo", ".github/workflows/operator-memory-ref.yml", "--probe-source"),
)
ROOT_HELP = {
    "repo": "the repository root (default: the fourth parent of the library file)",
    "catalog": "the catalog folder",
    "definitions": "the folder that holds the pack, the registry and the kinds table",
    "pack": "the definitions pack (JSON)",
    "pack_document": "the pack document whose marked tables mirror the pack's lists",
    "registry": "the ID registry",
    "kinds": "the element-kinds table",
    "fixtures": "the fixture tree's path prefix, as the register rules read it",
    "probe_source": "the file the pattern arm reads its probe words from",
}
TEXT_ROOTS = ("fixtures", "probe_source")


def default_part(name: str) -> str:
    return next(row[2] for row in DEFAULTS if row[0] == name)


VIEWS_FOLDER = "views"
RESERVED_FOLDERS = (default_part("definitions"), VIEWS_FOLDER)   # never a universe ID; never read as pages
INDEX_NAME, GRAPH_NAME, README_NAME = "INDEX.md", "graph.json", "README.md"
WORDS_PER_TOKEN = 0.75                                # the token estimate: one token per 0.75 words
INDEX_TOKEN_BUDGET = 4000
VIEW_SPLIT_WEIGHT = 6000
CRITERIA_WORDS = 24
DRAFT_MARK, SUPERSEDED_MARK = " (DRAFT)", " (superseded)"
NUMBER_SIGN = re.compile(r"#[0-9]")                   # the issue-reference gate's own token rule
CONTROL_ID = re.compile(r"\bC-\d{3,}\b")
CONTROL_RANGE = re.compile(r"\bC-(\d{3,})\s*(?:\bto\b|\bthrough\b|–)\s*C-(\d{3,})\b")


class Usage(Exception):
    """A usage error: exit 2, printed on standard error, no census."""


def add_root_arguments(ap, names) -> None:
    for name, _parent, _part, flag in DEFAULTS:
        if name in names:
            ap.add_argument(flag, dest="root_" + name, default=None, metavar="PATH", help=ROOT_HELP[name])


class Roots:
    """Resolved roots. Files and folders are absolute paths; `fixtures` and `probe_source` are text."""

    def __init__(self, values: dict):
        self.__dict__.update(values)
        self.catalog_rel = self.rel(self.catalog)

    def rel(self, path) -> str:
        """Repository-relative with forward slashes when inside the repository, else as given."""
        try:
            return Path(os.path.realpath(path)).relative_to(os.path.realpath(self.repo)).as_posix()
        except ValueError:
            return str(path)


def resolve_roots(a, require_catalog: bool = True) -> Roots:
    """T-1: a flag, else the default beneath the resolved parent. The repository root must be the top
    level of a git work tree and must hold the catalog root; either failure is NotEvaluated naming it."""
    given = lambda name: getattr(a, "root_" + name, None)   # noqa: E731
    values = {}
    repo = Path(given("repo")).resolve() if given("repo") else Path(__file__).resolve().parents[3]
    try:
        top = git(repo, "rev-parse", "--show-toplevel").decode("utf-8", "replace").strip() if repo.is_dir() else ""
    except NotEvaluated:
        top = ""
    if not top or os.path.realpath(top) != os.path.realpath(repo):
        raise NotEvaluated("the repository root (--repo) is not the top level of a git work tree: %s"
                           % (given("repo") or "the default beside the library"))
    values["repo"] = repo
    for name, parent, part, flag in DEFAULTS[1:]:
        if name in TEXT_ROOTS:
            raw = given(name)
            if raw is None:
                values[name] = part
            else:
                probe = Path(raw) if os.path.isabs(raw) else Path.cwd() / raw
                try:
                    values[name] = Path(os.path.realpath(probe)).relative_to(os.path.realpath(repo)).as_posix()
                except ValueError:
                    values[name] = raw
            values[name] = values[name].rstrip("/") if name == "fixtures" else values[name]
        else:
            values[name] = Path(given(name)).resolve() if given(name) else values[parent] / part
    roots = Roots(values)
    if require_catalog:
        inside = not roots.catalog_rel.startswith(("/", "..")) and not os.path.isabs(roots.catalog_rel)
        if not roots.catalog.is_dir() or not inside:
            raise NotEvaluated("the catalog root (--catalog-root) is not a folder of the repository%s"
                               % (": %s" % given("catalog") if given("catalog") else ""))
    return roots


# ----------------------------------------------------------------------------------------------
# git — the one wrapper. Every call passes the repository with -C and drops, from the child's
# environment, every variable `git rev-parse --local-env-vars` prints, so a caller's hook, rebase
# or wrapper cannot re-root a read. The list is read from git once per process.
# ----------------------------------------------------------------------------------------------
GIT_CLEARS_LOCATION = True        # a test seam: the decoy-variable arm switches it off as its control
_LOCATION_VARS = None


def location_vars() -> list:
    global _LOCATION_VARS
    if _LOCATION_VARS is None:
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        try:
            out = subprocess.run(["git", "rev-parse", "--local-env-vars"], capture_output=True, check=True,
                                 env=env, cwd=tempfile.gettempdir()).stdout
        except (OSError, subprocess.CalledProcessError) as e:
            raise NotEvaluated("git could not list its repository-location variables (%s)" % type(e).__name__)
        names = out.decode("ascii", "replace").split()
        if not names:
            raise NotEvaluated("git listed no repository-location variable")
        _LOCATION_VARS = names
    return _LOCATION_VARS


def git_run(repo, *args, data=None):
    """(return code, standard output as bytes). Raises NotEvaluated only when git cannot start."""
    env = dict(os.environ)
    if GIT_CLEARS_LOCATION:
        for name in location_vars():
            env.pop(name, None)
    env["LC_ALL"] = "C"
    try:
        proc = subprocess.run(["git", "-C", str(repo), "-c", "core.quotepath=off"] + list(args),
                              input=data, capture_output=True, env=env)
    except OSError as e:
        raise NotEvaluated("git could not be started (%s)" % type(e).__name__)
    return proc.returncode, proc.stdout


def git(repo, *args, data=None) -> bytes:
    """Standard output of a git call that must succeed; a non-zero return is NotEvaluated."""
    code, out = git_run(repo, *args, data=data)
    if code != 0:
        raise NotEvaluated("git %s failed (exit %d)" % (args[0], code))
    return out


class Tracked:
    """The list of tracked paths of one checkout — the index, read once. A folder is expanded from
    this list, never from the file system."""

    def __init__(self, repo, paths=None):
        if paths is None:
            paths = [p for p in git(repo, "ls-files", "-z").decode("utf-8", "surrogateescape").split("\0") if p]
        self.files = sorted(set(paths))
        self.set = set(self.files)
        self.base = {os.path.basename(f) for f in self.files}

    def under(self, folder: str) -> list:
        if folder in ("", "."):
            return list(self.files)
        prefix = folder.rstrip("/") + "/"
        lo = bisect.bisect_left(self.files, prefix)
        hi = bisect.bisect_left(self.files, prefix + "\U0010ffff")
        return self.files[lo:hi]

    def expand(self, entry: str) -> list:
        """The tracked files an entry names: itself, or every tracked file beneath it."""
        return [entry] if entry in self.set else self.under(entry)


def untracked_files(repo, folder_rel: str) -> list:
    """Untracked files that are not ignored, beneath a folder. An ignored file is never read."""
    out = git(repo, "ls-files", "-z", "--others", "--exclude-standard", "--", folder_rel)
    return sorted(p for p in out.decode("utf-8", "surrogateescape").split("\0") if p)


# ----------------------------------------------------------------------------------------------
# Sibling modules and plain file reads
# ----------------------------------------------------------------------------------------------
_SIBLINGS = {}


def sibling(file_name: str):
    """A sibling module with a hyphenated name, loaded by path from beside this file (T-4 b)."""
    if file_name not in _SIBLINGS:
        path = HERE / file_name
        try:
            spec = importlib.util.spec_from_file_location("_pc_" + re.sub(r"\W", "_", file_name), path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
        except Exception as e:              # noqa: BLE001 — any failure to load is the same not-evaluated state
            raise NotEvaluated("the sibling module %s could not be loaded (%s)" % (file_name, type(e).__name__))
        _SIBLINGS[file_name] = module
    return _SIBLINGS[file_name]


def read_text_strict(path, what: str) -> str:
    """UTF-8 text, strictly. An absent, unreadable or non-UTF-8 file is NotEvaluated naming `what`."""
    try:
        return Path(path).read_bytes().decode("utf-8")
    except OSError as e:
        raise NotEvaluated("%s could not be read (%s)" % (what, type(e).__name__))
    except UnicodeDecodeError:
        raise NotEvaluated("%s is not UTF-8 text" % what)


def write_text(path, text: str) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


# ----------------------------------------------------------------------------------------------
# The definitions pack. Shape is checked at load in every tool: a missing key, an unknown key or
# a malformed member is NotEvaluated naming the key. Unknown keys are refused at nine places.
# ----------------------------------------------------------------------------------------------
PACK_KEYS = ("pack_version", "id", "levels", "fields", "reserved_field_names", "enums", "tables",
             "navigation_markers", "forbidden_phrases", "contested_terms", "explain_on_first_use",
             "controls_register", "controls_register_rules", "summary_counts", "harness_features", "rule_codes")
PACK_OPTIONAL = ("views",)
PACK_ID_KEYS = ("pattern", "max_length")
PACK_LEVEL_KEYS = ("flow_class", "mermaid_required", "mermaid_node_limit", "token_budget", "required_sections")
PACK_ENUMS = ("doc_type", "status", "flow_class", "level", "lens_status", "actor_kinds", "trigger_kinds",
              "enforcement_class")
PACK_ENUMS_OPTIONAL = ("agent_state",)
PACK_SUMMARY_KEYS = ("level", "section", "rows")
PACK_REGISTER_KEYS = ("held_ids", "highest_minted_id", "kinds", "classes")
HELD_FORM = re.compile(r"^C-\d{3,}(?:\.\.C-\d{3,})?$")
MINTED_FORM = re.compile(r"^C-\d{3,}$")
POINTER_FORM = re.compile(r"^[^/~\\][^\\]*$")


def _keys(obj, where: str, required, optional=()):
    if not isinstance(obj, dict):
        raise NotEvaluated("pack key %s is not an object" % where)
    for key in obj:
        if key not in required and key not in optional:
            raise NotEvaluated("pack key %s is not a key the tools read"
                               % ("%s.%s" % (where, key) if where != "the pack" else key))
    for key in required:
        if key not in obj:
            raise NotEvaluated("pack key %s is missing" % ("%s.%s" % (where, key) if where != "the pack" else key))


def _strings(value, where: str, allow_empty: bool = False) -> None:
    if not isinstance(value, list) or (not value and not allow_empty):
        raise NotEvaluated("pack key %s is not a list with at least one entry" % where)
    if any(not isinstance(x, str) for x in value) or len(set(value)) != len(value):
        raise NotEvaluated("pack key %s holds an entry that is not a string, or one that repeats" % where)


def check_pointer(value, key: str) -> str:
    """T-2: a POSIX relative path with no leading `/` or `~`, no `..` segment and no backslash."""
    if not isinstance(value, str) or not value or not POINTER_FORM.match(value) or ".." in value.split("/"):
        raise NotEvaluated("pack key %s is not a path relative to the pack's own folder" % key)
    return value


def load_pack(path) -> dict:
    try:
        pack = json.loads(read_text_strict(path, "the definitions pack"))
    except ValueError:
        raise NotEvaluated("the definitions pack is not valid JSON")
    _keys(pack, "the pack", PACK_KEYS, PACK_OPTIONAL)
    _keys(pack["id"], "id", PACK_ID_KEYS)
    _keys(pack["enums"], "enums", PACK_ENUMS, PACK_ENUMS_OPTIONAL)
    for name, values in pack["enums"].items():
        _strings(values, "enums." + name)
    _keys(pack["levels"], "levels", pack["enums"]["level"])
    for name, level in pack["levels"].items():
        _keys(level, "levels." + name, PACK_LEVEL_KEYS)
        _strings(level["flow_class"], "levels.%s.flow_class" % name)
        _strings(level["required_sections"], "levels.%s.required_sections" % name)
    for key in ("fields", "reserved_field_names", "tables"):
        if not isinstance(pack[key], dict):
            raise NotEvaluated("pack key %s is not an object" % key)
    for name, spec in pack["fields"].items():
        if not isinstance(spec, dict) or not isinstance(spec.get("type"), str):
            raise NotEvaluated("pack key fields.%s names no type" % name)
    for name, columns in pack["tables"].items():
        _strings(columns, "tables." + name)
    _strings(pack["navigation_markers"], "navigation_markers")
    if len(pack["navigation_markers"]) != 2:
        raise NotEvaluated("pack key navigation_markers does not hold exactly two markers")
    for key, member in (("forbidden_phrases", "phrase"), ("contested_terms", "term")):
        if not isinstance(pack[key], list) or any(
                not isinstance(e, dict) or not isinstance(e.get(member), str) or not isinstance(e.get("severity"), str)
                for e in pack[key]):
            raise NotEvaluated("pack key %s holds an entry without a %s and a severity" % (key, member))
    for key in ("explain_on_first_use", "harness_features", "rule_codes"):
        _strings(pack[key], key, allow_empty=(key == "explain_on_first_use"))
    check_pointer(pack["controls_register"], "controls_register")
    rules = pack["controls_register_rules"]
    _keys(rules, "controls_register_rules", PACK_REGISTER_KEYS)
    for key in ("held_ids", "kinds", "classes"):
        _strings(rules[key], "controls_register_rules." + key)
    if any(not HELD_FORM.match(x) for x in rules["held_ids"]):
        raise NotEvaluated("pack key controls_register_rules.held_ids holds an entry that is not a held range")
    if not isinstance(rules["highest_minted_id"], str) or not MINTED_FORM.match(rules["highest_minted_id"]):
        raise NotEvaluated("pack key controls_register_rules.highest_minted_id is not a control ID")
    summary = pack["summary_counts"]
    _keys(summary, "summary_counts", PACK_SUMMARY_KEYS)
    level = pack["levels"].get(summary["level"]) if isinstance(summary["level"], str) else None
    if level is None or summary["section"] not in level["required_sections"] or summary["section"] not in pack["tables"]:
        raise NotEvaluated("pack key summary_counts.section is not a required section of its level with a table")
    if not isinstance(summary["rows"], dict) or not summary["rows"] or any(
            not isinstance(v, str) for v in summary["rows"].values()):
        raise NotEvaluated("pack key summary_counts.rows is not an object of row label to value")
    if "views" in pack:
        _keys(pack["views"], "views", (), ("state",))
        if "state" in pack["views"]:
            _keys(pack["views"]["state"], "views.state", (), ("stage_stream",))
            if not isinstance(pack["views"]["state"].get("stage_stream", ""), str):
                raise NotEvaluated("pack key views.state.stage_stream is not a node ID")
    return pack


def controls_register_path(pack: dict, pack_path, override=None) -> Path:
    """The register is reached by the pack's pointer, from the pack's own folder; an argument overrides it."""
    if override:
        return Path(override).resolve()
    return Path(pack_path).resolve().parent / check_pointer(pack["controls_register"], "controls_register")


def load_kinds(path) -> list:
    """The element-kinds table: `kind<TAB>pattern`, a Python regular expression searched on the
    repository-relative path. Order is significant: the first matching row wins."""
    lines = [l for l in read_text_strict(path, "the element-kinds table").split("\n") if l != ""]
    if not lines or lines[0].split("\t") != ["kind", "pattern"]:
        raise NotEvaluated("the element-kinds table does not open with the header kind<TAB>pattern")
    rows = []
    for n, line in enumerate(lines[1:], 2):
        cells = line.split("\t")
        try:
            if len(cells) != 2 or not cells[0]:
                raise ValueError
            rows.append((cells[0], re.compile(cells[1])))
        except (ValueError, re.error):
            raise NotEvaluated("the element-kinds table, line %d: not a kind and a pattern that compiles" % n)
    if not rows:
        raise NotEvaluated("the element-kinds table has no row")
    return rows


def classify_path(path: str, kinds: list) -> str:
    for kind, rx in kinds:
        if rx.search(path):
            return kind
    return "other"


def kind_order(kinds: list) -> list:
    order = []
    for kind, _rx in kinds:
        if kind not in order:
            order.append(kind)
    return order + (["other"] if "other" not in order else [])


# ==============================================================================================
# REGISTER RULES — one contiguous block. It is the Register Contract's rules module, carried here
# so the validator's register check and that module print the same lines. The text between the
# two rules of `=` is the module's, with these declared differences and no other:
#   1. Data from the pack. The held ranges, the highest minted ID, the kinds and the classes are
#      set at load from `controls_register_rules`; the class grammar is built from the pack's
#      classes (configure_register_rules, below the block).
#   2. Not carried: the module's own defaults table, its root helpers and its entry point. Their
#      work is the DEFAULTS table above and the validator's entry point.
#   3. The fixture-register test, which the module keeps in its entry point, is is_fixture_register
#      below the block, with the same predicate.
#   4. The file listing goes through the one git wrapper.
#   5. Lines the module does not print — the roots line, a pack-parity line and the census — are
#      printed by the validator, outside the block.
# One further change is the scope-lock condition: the pattern digest file is required whenever
# the pattern arm runs. A named constant in the block is the rule; the sentence describes it.
# ==============================================================================================
HEADER = ["control_id", "statement", "mechanism_kind", "mechanism_ref", "source_path",
          "enforcement_class_default", "enforcement_surface", "applies_to"]
REG_HEADER = ["id", "level", "universe", "parent", "title", "status"]
PROBE_WORDS = re.compile(r"\(([a-z_]+(?:\|[a-z_]+)+)\)_\[a-z\]")  # the gate's category list: read, never typed here
PROBE_SHAPES = ("%s_alpha_beta.md", "%s_alpha_beta", "%s_alpha12_beta_gamma.md", "%s_alpha_beta2",
                "%s_al9ha_beta_gamma_delta.md")
NEAR_MISS = ("", "A rule about how a change is reviewed before it merges.", "the operator note store",
             "core/rules/git-workflow.md")
KINDS = set()            # difference 1: set at load from the pack key, by configure_register_rules
CLASS_CELL = None        # difference 1: built at load from the pack's classes
FIXED_SURFACE = {"hook-rule": "hook", "hook-registration": "hook", "settings-permission": "runtime-permission",
                 "deploy-check": "deploy-run", "prose-rule": ""}
ID = re.compile(r"^C-(\d{3,})$")
FLOOR = 1                                          # control IDs are minted from C-001
B0, B1 = r"(?<![A-Za-z0-9_])", r"(?![A-Za-z0-9_])"
NAME = re.compile(B0 + r"[A-Za-z0-9_.\-/~]*[A-Za-z0-9_\-]\.[A-Za-z][A-Za-z0-9]*" + B1)   # any dotted ending
SETTINGS_KEY = re.compile(r"^[a-z][a-z_]*(?:\.[a-z][a-z_]*)+$")
SNAKE = re.compile(B0 + r"[a-z][a-z0-9]*(?:_[a-z0-9]+)+" + B1)
TREE_TOKENS = [re.compile(p) for p in (
    r"<[^<>\t]{1,60}>", r"\$?\{[^{}\t]{1,60}\}", r"\$[A-Za-z_][A-Za-z0-9_]*", r"%[A-Za-z_][A-Za-z0-9_]*%",
    B0 + r"[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+" + B1, r"~[A-Za-z0-9_\-]*/[A-Za-z0-9_.*\-/]*", r"\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/[A-Za-z0-9_.*\-/]+")]
DENY = [("instance-token", re.compile(r"<[A-Z][A-Z0-9_]*>")),
        ("machine-path", re.compile(r"(?:/Users/|/home/|/private/|/var/|/tmp/|/opt/|/Volumes/|/mnt/|/root/|/srv/|[A-Za-z]:\\)")),
        ("entity", re.compile(r"&(?:[a-z]+|#\d+);"))]
OBSERVED = [("date", re.compile(r"\b(?:19|20)\d\d-\d\d-\d\d\b")),
            ("figure", re.compile(r"(?i)(?<![\w\-])\d[\d,]*\s+(?:times|firings?|runs?|sessions?|rows?|tokens?|blocks?|hits?|events?|occurrences?)\b")),
            ("wording", re.compile(r"(?i)\b(?:here|this install|this machine|at this read|as observed|observed (?:on|in|at|here)|fired|last firing|firing evidence|mode file reads|currently (?:reads|set|in))\b"))]
LABELLED = re.compile(r"\b(?:Check|Stage|Step|Rule|Phase|Tier|Level|Mode) $")   # "Check 63 runs" is a label, not a figure
STATUS_WORDS = re.compile(r"(?i)\b(?:required|registered|merge gate|not a required)\b")
LABEL = re.compile(r"\[(?:SOURCE|INFERRED|CONTEXT|RECOMMENDED|ASSUMPTION)\b")
FORMS = [("number-sign", re.compile(r"#\d")),
         ("line-ref", re.compile(r"\(L\d+\)|#L\d+|\bL\d+(?:-L?\d+)?\b|(?i:\blines? \d+)|\.[A-Za-z]{1,5}:\d+\b")),
         ("work-item", re.compile(r"\bGH-\d+|\bIMP-\d+|(?i:\b(?:issues?|pull requests?|pulls?|PRs?)[ /#]*\d+)")),
         ("contact", re.compile(r"[A-Za-z0-9._+\-]+@[A-Za-z0-9\-]+\.[a-z]+|(?<![A-Za-z0-9_`/])@[A-Za-z][A-Za-z0-9\-]+"))]
EXTERNAL = [("address", re.compile(r"[A-Za-z][A-Za-z0-9+.\-]*://[^\s\"'<>)\]]*|\bmailto:\S+|\bwww\.[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+|\\\\[A-Za-z0-9]\S*")),
            ("host", re.compile(B0 + r"(?:[A-Za-z0-9\-]+\.)+(?:com|net|org|io|dev|app|ai|co|cloud|edu|gov|us|uk|internal|local|corp|lan)" + B1)),
            ("tracker-key", re.compile(B0 + r"[A-Z][A-Z0-9]{1,9}-\d+" + B1))]
DECL = re.compile(r"#\s*gate-efficacy:\s*posture=(\S+)(.*)")
REQUIRED = re.compile(r"required(?![A-Za-z-])(?!\(warn-mode-initial)")
CI_REF = re.compile(r"^([A-Za-z0-9_.\-]+\.ya?ml)#")
MATRIX = re.compile(r"^(.*\S) \(matrix: [^()]+\)$")


class NotEvaluated(Exception):
    pass


def read_tsv(path, what):
    """what: the file's role. An error line names the role, never the path."""
    try:
        text = open(path, encoding="utf-8", newline="").read()
    except (OSError, UnicodeDecodeError) as e:
        raise NotEvaluated("%s: could not be read (%s)" % (what, type(e).__name__))
    if not text.strip():
        raise NotEvaluated("%s: empty" % what)
    return [line.split("\t") for line in text.split("\n") if line != ""]


class Tree:
    """The tracked tree at one checkout. exclude: path prefixes left out of tree-wide text."""
    def __init__(self, repo, exclude):
        try:                                          # difference 4: the listing goes through the wrapper
            code, raw = git_run(repo, "ls-files")
        except NotEvaluated:
            raise NotEvaluated("git ls-files failed (OSError)")
        if code != 0:
            raise NotEvaluated("git ls-files failed (CalledProcessError)")
        out = raw.decode("utf-8", "replace")
        self.repo, self.files = repo, {f for f in out.split("\n") if f}
        if not self.files:
            raise NotEvaluated("no tracked file")
        self.base = {os.path.basename(f) for f in self.files}
        self.exclude, self._text, self._all = tuple(exclude), {}, None

    def text(self, path):
        if path not in self._text:
            try:
                self._text[path] = open(os.path.join(self.repo, path), encoding="utf-8").read()
            except (OSError, UnicodeDecodeError):
                self._text[path] = ""
        return self._text[path]

    def all_text(self):
        if self._all is None:
            self._all = "\n".join(self.text(f) for f in sorted(self.files) if not f.startswith(self.exclude))
        return self._all


def occurs(token, text):
    i = text.find(token)
    while i != -1:
        before, after = text[i - 1:i], text[i + len(token):i + len(token) + 1]
        if not (re.match(r"[A-Za-z0-9_]", before) and re.match(r"[A-Za-z0-9_]", token[0])) and \
           not (re.match(r"[A-Za-z0-9_]", after) and re.match(r"[A-Za-z0-9_]", token[-1])):
            return True
        i = text.find(token, i + 1)
    return False


def declared(text):
    """(names declared with leading posture token `required`, not qualified warn-mode-initial; all other declared names)."""
    req, other = set(), set()
    for line in text.split("\n"):
        m = DECL.search(line)
        if m:
            (req if REQUIRED.match(m.group(1)) else other).update(re.findall(r'"([^"]+)"', m.group(2)))
    return req, other


def derive_surface(tree, row):
    kind = row["mechanism_kind"]
    if kind in FIXED_SURFACE:
        return FIXED_SURFACE[kind]
    if kind != "ci-job":
        return None
    ref, q = CI_REF.match(row["mechanism_ref"]), re.search(r'"([^"]+)"', row["mechanism_ref"])
    first = row["source_path"].split(";")[0].strip()
    if not ref or not q or os.path.basename(first) != ref.group(1):
        return None                                   # the row's first source is not the workflow its reference names
    text, name = tree.text(first), q.group(1)
    req, other = declared(text)
    if name in req:                                   # a whole declared name
        return "merge-gate"
    m = MATRIX.match(name)
    if m:                                             # the one stated exception: a matrix job
        head = m.group(1) + " ("
        template = re.search(r"(?m)^\s*name:\s*%s\$\{\{\s*matrix\.[A-Za-z0-9_.\-]+\s*\}\}\)\s*$" % re.escape(head), text)
        if template and any(n.startswith(head) for n in req) and not any(n.startswith(head) for n in other):
            return "merge-gate"
    return "ci-run"


def ungrounded(v, source_text):
    """v with every quoted string and hyphen-joined name that its own source carries blanked out."""
    for t in re.findall(r'"[^"]+"', v) + re.findall(r"[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+", v):
        if occurs(t.strip('"'), source_text):
            v = v.replace(t, " ")
    return v


def cell_findings(tree, cells, source_text, patterns, prose_statement=False, settings_ref=False):
    """Rules 7 to 10 over a dict of cells. source_text is the row's own cited sources ('' if none).
    patterns is None when the pattern arm is declared not run."""
    out = []
    for col, v in cells.items():
        for rx in patterns or ():
            if rx.search(v):
                out.append(("R7a", col, "matches the private-source pattern"))
        for name, rx in DENY:
            if rx.search(v):
                out.append(("R7b", col, name))
        rest = v
        for m in NAME.finditer(v):
            t = m.group(0)
            rel = re.sub(r"^\./", "", t)
            key = settings_ref and col == "mechanism_ref" and SETTINGS_KEY.match(t) and \
                all('"%s"' % seg in source_text for seg in t.split("."))
            if rel in tree.files or (("/" not in rel) and rel in tree.base) or occurs(t, source_text) or key:
                rest = rest.replace(t, " " * len(t), 1)
            else:
                out.append(("R7c", col, "name not grounded"))
        for m in SNAKE.finditer(rest):
            if not occurs(m.group(0), source_text):
                out.append(("R7c", col, "identifier not grounded"))
        for rx in TREE_TOKENS:
            for m in rx.finditer(v):
                t = m.group(0).rstrip(".,;:")
                if DENY[0][1].fullmatch(t):
                    continue
                if not occurs(t, tree.all_text()):
                    out.append(("R7d", col, "placeholder or home-relative location not in tracked text"))
        for name, rx in OBSERVED:
            if any(not LABELLED.search(v[:m.start()]) for m in rx.finditer(v)):
                out.append(("R8", col, name))
        if LABEL.search(v) and not (col == "statement" and prose_statement):
            out.append(("R8", col, "evidence label"))
        if col in ("applies_to", "mechanism_ref", "enforcement_class_default") and STATUS_WORDS.search(ungrounded(v, source_text)):
            out.append(("R8", col, "registration-status wording"))
        for name, rx in FORMS:
            if rx.search(v):
                out.append(("R9", col, name))
        for name, rx in EXTERNAL:
            for m in rx.finditer(v):
                t = m.group(0).rstrip(".,;:")
                if not occurs(t, source_text) and not (name == "tracker-key" and occurs(t, tree.all_text())):
                    out.append(("R10", col, name))
    return out


def parse_ranges(specs):
    held = set()
    for s in specs:
        m = re.match(r"^C-(\d+)(?:\.\.C-(\d+))?$", s.strip())
        if not m:
            raise NotEvaluated("held range %r" % s)
        lo, hi = int(m.group(1)), int(m.group(2) or m.group(1))
        held.update(range(lo, hi + 1))
    if not held:
        raise NotEvaluated("no held-ID range was given; the ranges are a required input")
    return held


def ranges(nums):
    out, nums = [], sorted(nums)
    for n in nums:
        if out and n == out[-1][1] + 1:
            out[-1][1] = n
        else:
            out.append([n, n])
    return ["C-%03d..C-%03d" % (a, b) if a != b else "C-%03d" % a for a, b in out]


def parse_minted(spec):
    m = ID.match((spec or "").strip())
    if not m:
        raise NotEvaluated("the highest minted ID is absent or is not a control ID; it is a required input")
    return int(m.group(1))


def gap_findings(nums, held, minted):
    """R2 over a whole register. No row and no held ID lies above the highest minted ID, and every number
    from FLOOR up to it is a row or a held ID. One finding per run of numbers."""
    top = max(list(nums) + list(held) + [minted])
    return [("R2", r, "control_id", "above the highest minted ID")
            for r in ranges(n for n in set(nums) | set(held) if n > minted)] + \
           [("R2", r, "control_id", "no row and no held range")
            for r in ranges(n for n in range(FLOOR, top + 1) if n not in nums and n not in held)]


def check_controls(tree, table, held, patterns, fixture_register=False, whole=True, minted=None):
    """Returns (rows read, findings). A finding is (rule, control_id or line, column, detail).
    held: a set of numbers; the caller obtains it from parse_ranges, which refuses an empty one.
    whole: the table is a whole register, so the gap test runs; the export passes False for one projected row.
    minted: the highest minted ID as a number (parse_minted); required when whole.
    tree.exclude is (catalog root, fixture root); fixture_register: the register is a file in the fixture root."""
    catalog_root, fixture_root = tree.exclude
    f = []
    if whole and minted is None:
        raise NotEvaluated("the highest minted ID was not given; it is a required input")
    if table[0] != HEADER:
        return 0, [("R1", "header", "", "header differs from the contract")]
    last, seen = 0, set()
    for n, cells in enumerate(table[1:], 2):
        if len(cells) != len(HEADER):
            f.append(("R1", "line %d" % n, "", "%d cells" % len(cells)))
            continue
        row = dict(zip(HEADER, cells))
        cid = row["control_id"]
        m = ID.match(cid)
        if not m:
            f.append(("R2", "line %d" % n, "control_id", "form"))
        else:
            num = int(m.group(1))
            if cid in seen or num <= last:
                f.append(("R2", cid, "control_id", "not unique and ascending"))
            if num in held:
                f.append(("R2", cid, "control_id", "inside a held range"))
            last = max(last, num)
            seen.add(cid)
        paths = [p.strip() for p in row["source_path"].split(";")]
        shaped = [p for p in paths if re.match(r"^[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)*$", p) and not {".", ".."} & set(p.split("/"))]
        barred = [p for p in shaped if p.startswith(catalog_root) or (p.startswith(fixture_root) and not fixture_register)]
        if len(shaped) != len(paths):
            f.append(("R3a", cid, "source_path", "not a repository-relative path"))
        elif barred:
            f.append(("R3c", cid, "source_path", "a source under the catalog root, or a fixture source outside a fixture register"))
        elif any(p not in tree.files for p in paths):
            f.append(("R3b", cid, "source_path", "path is not tracked at this commit"))
        for name, rx in DENY[3:]:                 # a denied shape an option adds is read in the source cell too
            if rx.search(row["source_path"]):
                f.append(("R7b", cid, "source_path", name))
        if row["mechanism_kind"] not in KINDS:
            f.append(("R4", cid, "mechanism_kind", "outside the published kinds"))
        if not CLASS_CELL.match(row["enforcement_class_default"]):
            f.append(("R5", cid, "enforcement_class_default", "outside the class grammar"))
        want = derive_surface(tree, row) if len(shaped) == len(paths) else None
        if want is None or row["enforcement_surface"] != want:
            f.append(("R6", cid, "enforcement_surface", "differs from the derived value"))
        elif want == "merge-gate" and not row["enforcement_class_default"].startswith("code-enforce"):
            f.append(("R6b", cid, "enforcement_class_default", "a merge-gate row whose class does not begin code-enforce"))
        src = "\n".join(tree.text(p) for p in shaped if p in tree.files and p not in barred)
        body = {c: row[c] for c in ("statement", "mechanism_ref", "enforcement_class_default", "applies_to")}
        for rule, col, detail in cell_findings(tree, body, src, patterns, row["mechanism_kind"] == "prose-rule",
                                               row["mechanism_kind"] == "settings-permission"):
            f.append((rule, cid, col, detail))
    if whole:
        f.extend(gap_findings({int(c[2:]) for c in seen}, held, minted))
    return len(table) - 1, f


def check_registry(tree, table, patterns):
    f = []
    if table[0] != REG_HEADER:
        return 0, [("G1", "header", "", "header differs from the contract")]
    rows = [dict(zip(REG_HEADER, c)) for c in table[1:] if len(c) == len(REG_HEADER)]
    if len(rows) != len(table) - 1:
        f.append(("G1", "rows", "", "a row does not have %d cells" % len(REG_HEADER)))
    ids = [r["id"] for r in rows]
    l0 = {r["id"] for r in rows if r["level"] == "L0"}
    for r in rows:
        if not re.match(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", r["id"]) or ids.count(r["id"]) != 1:
            f.append(("G2", r["id"], "id", "not kebab-case and unique"))
        if r["level"] not in ("L0", "L1", "L2", "L3") or r["status"] != "minted":
            f.append(("G2", r["id"], "level/status", "outside the vocabulary"))
        if r["universe"] not in l0 or (r["parent"] and r["parent"] not in ids) or (r["level"] == "L0") != (r["parent"] == ""):
            f.append(("G2", r["id"], "universe/parent", "does not resolve"))
        for rule, col, detail in cell_findings(tree, {"title": r["title"]}, tree.all_text(), patterns):
            f.append(("G3:" + rule, r["id"], col, detail))
    return len(rows), f


def fixed_probes(tree, probe_source):
    """The contract's positive probe set: every shape in PROBE_SHAPES for every category word the
    tracked memory-reference gate's own expression lists. The pattern file cannot weaken it."""
    words = set()
    if probe_source in tree.files:
        for m in PROBE_WORDS.finditer(tree.text(probe_source)):
            words.update(m.group(1).split("|"))
    if not words:
        raise NotEvaluated("probe words could not be read from the probe source")
    return [shape % w for w in sorted(words) for shape in PROBE_SHAPES]


def load_patterns(path, tree, probe_source, digest_file):
    """One Python `re` expression per line, searched case-sensitively. Usable only if every fixed probe
    matches some expression and no fixed near-miss matches any. A `must-match:` line adds a probe; it
    replaces none. digest_file: a file whose first token is the SHA-256 its holder recorded for the
    pattern file; it is required, and a pattern file with any other digest is not evaluated. No digest
    is ever printed."""
    try:
        raw = open(path or "", "rb").read()
        lines = [l for l in raw.decode("utf-8").split("\n") if l.strip()]
    except (OSError, UnicodeDecodeError):
        raise NotEvaluated("private-source pattern file is absent or could not be read")
    if not digest_file:
        raise NotEvaluated("the pattern digest file was not given; it is a required input")
    try:
        want = open(digest_file, encoding="utf-8").read().split()[:1]
    except (OSError, UnicodeDecodeError):
        raise NotEvaluated("the pattern digest file could not be read")
    if not want or not re.fullmatch(r"[0-9a-f]{64}", want[0]):
        raise NotEvaluated("the pattern digest file does not begin with a SHA-256 value")
    if hashlib.sha256(raw).hexdigest() != want[0]:
        raise NotEvaluated("the pattern file is not the file its holder recorded")
    probes = fixed_probes(tree, probe_source) + [l[len("must-match:"):].strip() for l in lines if l.startswith("must-match:")]
    try:
        pats = [re.compile(l) for l in lines if not l.startswith("must-match:")]
    except re.error:
        raise NotEvaluated("private-source pattern does not compile")
    missed = sum(1 for t in probes if not any(p.search(t) for p in pats))
    if not pats or missed:
        raise NotEvaluated("private-source pattern: no expression, or %d of %d probes not matched" % (missed, len(probes)))
    if any(p.search(t) for p in pats for t in NEAR_MISS):
        raise NotEvaluated("private-source pattern matches a fixed near-miss; it is too wide to use")
    return pats, len(probes)


def folder(p):
    return p.rstrip("/") + "/"
# ==============================================================================================
# END OF THE REGISTER RULES BLOCK
# ==============================================================================================


# ----------------------------------------------------------------------------------------------
# The register load the tools share. The generator loads rows with the header and cell-count test
# and the zero-row stop only; the validator runs every rule (check_registers below).
# ----------------------------------------------------------------------------------------------
def load_table(path, header: list, what: str) -> list:
    """Rows as dicts. A header that differs, a row with another cell count, or no row: NotEvaluated."""
    table = read_tsv(path, what)
    if table[0] != header:
        raise NotEvaluated("%s: header differs from the contract" % what)
    if any(len(cells) != len(header) for cells in table[1:]):
        raise NotEvaluated("%s: a row does not have %d cells" % (what, len(header)))
    if len(table) < 2:
        raise NotEvaluated("%s: no row" % what)
    return [dict(zip(header, cells)) for cells in table[1:]]


def configure_register_rules(rules: dict) -> tuple:
    """Declared difference 1: the held ranges, the highest minted ID, the kinds and the classes are
    data, set here from the pack's `controls_register_rules` and held nowhere in code. Returns
    (held numbers, highest minted number)."""
    global KINDS, CLASS_CELL
    unmapped = [k for k in rules["kinds"] if k not in FIXED_SURFACE and k != "ci-job"]
    if unmapped:
        raise NotEvaluated("pack key controls_register_rules.kinds names a kind with no surface mapping: %s"
                           % unmapped[0])
    KINDS = set(rules["kinds"])
    arm = r"(?:%s)(?: \([A-Za-z0-9\-][A-Za-z0-9 \-]{0,39}\))?" % "|".join(re.escape(c) for c in rules["classes"])
    CLASS_CELL = re.compile(r"^%s(?: / %s)?$" % (arm, arm))
    return parse_ranges(rules["held_ids"]), parse_minted(rules["highest_minted_id"])


def is_fixture_register(roots: Roots, controls_path) -> bool:
    """Declared difference 3: the register's resolved path, relative to the resolved repository
    root, begins with the fixture root."""
    inside = os.path.relpath(os.path.realpath(controls_path), os.path.realpath(roots.repo)).replace(os.sep, "/")
    return inside.startswith(folder(roots.fixtures))


def roots_line(roots: Roots, held) -> str:
    """The tool-side fourth header line. Folder roots are printed with no trailing slash."""
    return "register roots: catalog=%s fixtures=%s probe_source=%s held=%s" % (
        roots.catalog_rel, roots.fixtures, roots.probe_source,
        ",".join(ranges(held)) if held is not None else "NA")


def check_registers(roots: Roots, pack: dict, controls_path, pattern_arm: str, pattern_file=None,
                    digest_file=None) -> dict:
    """Run the register rules over the controls register and the ID registry. Returns a dict:
    lines (what to print, in order), register_rows, registry_rows, findings, stop (a message, or
    None). A stop raised inside the block is the module's own NOT EVALUATED line: a role and an
    error type, never a path."""
    out = {"lines": [], "register_rows": "NA", "registry_rows": "NA", "findings": 0, "stop": None, "held": None}
    try:
        held, minted = configure_register_rules(pack["controls_register_rules"])
        out["held"] = held
        tree = Tree(roots.repo, (folder(roots.catalog_rel), folder(roots.fixtures)))
        pats, probes = load_patterns(pattern_file, tree, roots.probe_source, digest_file) \
            if pattern_arm == "run" else (None, 0)
        n, f = check_controls(tree, read_tsv(controls_path, "controls register"), held, pats,
                              is_fixture_register(roots, controls_path), minted=minted)
        m, g = check_registry(tree, read_tsv(roots.registry, "ID registry"), pats)
    except NotEvaluated as e:
        out["lines"] = [roots_line(roots, out["held"]), "NOT EVALUATED: %s" % e]
        out["stop"] = str(e)
        return out
    out["lines"] = [
        "controls register: %d rows read, %d findings" % (n, len(f)),
        "ID registry: %d rows read, %d findings" % (m, len(g)),
        "pattern arm: run, %d probes matched, words from %s" % (probes, roots.probe_source) if pats is not None else
        "pattern arm: NOT RUN (declared); rules R7b, R7c, R7d and R10 ran",
        roots_line(roots, held)]
    out["lines"] += ["%s\t%s\t%s\t%s" % finding for finding in f + g]
    out["register_rows"], out["registry_rows"], out["findings"] = n, m, len(f) + len(g)
    if n == 0 or m == 0:
        out["lines"].append("NOT EVALUATED: a register has no rows")
        out["stop"] = "a register has no rows"
    return out


# ----------------------------------------------------------------------------------------------
# Text helpers: fences, code spans, table rows. Fences are the shared link checker's, so a tilde
# fence and a fence inside a quote are masked exactly as that checker masks them.
# ----------------------------------------------------------------------------------------------
def fence_flags(lines: list) -> list:
    """True for each line the shared link checker blanks: a fence line, or a line inside a fence."""
    stripped = sibling(LINK_CHECKER).strip_code_blocks(lines)
    return [content != line for (_n, content), line in zip(stripped, lines)]


def code_spans(line: str) -> list:
    """(start, content start, content end, end) of each inline code span. A span opens on a run of
    N backticks and closes on the next run of exactly N; a run with no closer is literal text, and
    a backslash outside a span escapes the next character."""
    spans, i, n = [], 0, len(line)
    while i < n:
        ch = line[i]
        if ch == "\\":
            i += 2
            continue
        if ch != "`":
            i += 1
            continue
        j = i
        while j < n and line[j] == "`":
            j += 1
        run, k, close = j - i, j, -1
        while k < n:
            if line[k] != "`":
                k += 1
                continue
            m = k
            while m < n and line[m] == "`":
                m += 1
            if m - k == run:
                close = k
                break
            k = m
        if close < 0:
            i = j
            continue
        spans.append((i, j, close, close + run))
        i = close + run
    return spans


def mask_link_spans(line: str) -> str:
    """Blank every code span that holds a link's `](` — a link written inside a code span is
    illustration. A span that is only a link's label holds no `](` and is left as it is."""
    out = list(line)
    for start, c0, c1, end in code_spans(line):
        if "](" in line[c0:c1]:
            out[start:end] = " " * (end - start)
    return "".join(out)


def code_span_pipes(line: str) -> int:
    """Unescaped pipes inside the code spans of one line. The host splits a table cell on a bare
    pipe even inside a span, so only an escaped pipe survives there."""
    hits = 0
    for _start, c0, c1, _end in code_spans(line):
        span = line[c0:c1]
        hits += sum(1 for p, c in enumerate(span) if c == "|" and (p == 0 or span[p - 1] != "\\"))
    return hits


def split_row(line: str) -> list:
    """Cells of a table row; an escaped pipe or a pipe inside a code span does not split."""
    s = line.strip()
    t = s[1:-1] if s.startswith("|") and s.endswith("|") and len(s) > 1 else s
    inside = [False] * len(t)
    for start, _c0, _c1, end in code_spans(t):
        for p in range(start, end):
            inside[p] = True
    cells, cur, k = [], "", 0
    while k < len(t):
        ch = t[k]
        if ch == "\\" and k + 1 < len(t) and not inside[k]:
            cur += t[k:k + 2]
            k += 2
            continue
        if ch == "|" and not inside[k]:
            cells.append(cur.strip())
            cur = ""
        else:
            cur += ch
        k += 1
    cells.append(cur.strip())
    return cells


def is_table_line(line: str) -> bool:
    s = line.strip()
    return len(s) > 1 and s.startswith("|") and s.endswith("|")


def is_rule_line(line: str) -> bool:
    return is_table_line(line) and set(line.strip()) <= set("|-: ")


def parse_inline_list(value: str):
    """The items of an inline `[a, b]` list, or None when the value is not one."""
    v = (value or "").strip()
    if not (v.startswith("[") and v.endswith("]")):
        return None
    inner = v[1:-1].strip()
    return [x.strip() for x in inner.split(",") if x.strip()] if inner else []


def unspan(cell: str) -> str:
    """A cell with code-span marks removed."""
    return cell.replace("`", "").strip()


def token_estimate(text: str) -> int:
    return int(math.ceil(len(text.split()) / WORDS_PER_TOKEN))


# ----------------------------------------------------------------------------------------------
# The page model. Frontmatter is read through the shared reader's three functions and through
# nothing else; the names are looked up in this module at call time, so the self-tests can prove
# by behaviour that there is no second parser.
# ----------------------------------------------------------------------------------------------
LIST_FIELDS = ("precedes", "triggered_by", "depends_on", "depicts", "documented_by", "supersedes",
               "superseded_by", "actors")


class Page:
    def __init__(self, path: Path, rel: str, text: str):
        self.path, self.rel, self.text = path, rel, text
        self.id = path.name[:-3] if path.name.endswith(".md") else path.stem
        self.fm, self.fm_status = read_frontmatter(path)
        self.lines = frontmatter_lines(text=text) or []
        self.fm_end = frontmatter_end(text=text)
        self.body_start = 0 if self.fm_end is None else self.fm_end + 1
        self._cache = {}

    def get(self, name: str) -> str:
        return self.fm.get(name, "")

    def items(self, name: str) -> list:
        return parse_inline_list(self.fm.get(name, "")) or []

    @property
    def title(self) -> str:
        return self.fm.get("title", "") or self.id

    @property
    def status(self) -> str:
        return self.fm.get("status", "")

    @property
    def lens_status(self) -> str:
        return self.fm.get("lens_status", "")

    def body_lines(self) -> list:
        """(line index, text) for every body line; a fenced line is blank, and a code span that
        holds a link is blanked in place, so a column in this text is a column in the page."""
        if "body" not in self._cache:
            flags = fence_flags(self.lines)
            self._cache["body"] = [(i, "" if flags[i] else mask_link_spans(self.lines[i]))
                                   for i in range(self.body_start, len(self.lines))]
        return self._cache["body"]

    def sections(self) -> dict:
        """{section title: [(line index, raw line)]} for each `## ` heading outside fenced code."""
        if "sections" not in self._cache:
            flags = fence_flags(self.lines)
            found, current = {}, None
            for i in range(self.body_start, len(self.lines)):
                line = self.lines[i]
                m = None if flags[i] else re.match(r"^## (.+?)\s*$", line)
                if m:
                    current = m.group(1)
                    found.setdefault(current, [])
                elif current is not None:
                    found[current].append((i, "" if flags[i] else line))
            self._cache["sections"] = found
        return self._cache["sections"]

    def table(self, section: str):
        """(header cells or None, [(line index, cells)]) of the first table of a section."""
        header, rows, started = None, [], False
        for i, line in self.sections().get(section, []):
            if not is_table_line(line):
                if started:
                    break
                continue
            started = True
            if is_rule_line(line):
                continue
            if header is None:
                header = split_row(line)
            else:
                rows.append((i, split_row(line)))
        return header, rows

    def rows(self, section: str) -> list:
        return [cells for _i, cells in self.table(section)[1]]


def load_page(path: Path, roots: Roots) -> Page:
    """A page file that cannot be read or is not UTF-8 is NotEvaluated naming the file. It is read
    strictly here, before any path is handed to the shared link checker, whose own reader returns
    no finding for a file it cannot open."""
    rel = roots.rel(path)
    return Page(path, rel, read_text_strict(path, "the page %s" % rel))


# ----------------------------------------------------------------------------------------------
# Citations. One grammar, frozen for this release: the source-anchor comment is the opener, one
# space, `source-anchor:`, one space, `line=` and a line or a first-last span, a semicolon, one
# space, `fp=` and sixteen lower-case hexadecimal characters, one space, the closer.
# ----------------------------------------------------------------------------------------------
CITATION = re.compile(
    r"\[(?P<label>[^\]\n]*)\]\((?P<path>/[^)\s#]+)#L(?P<a>[0-9]+)(?:-L(?P<b>[0-9]+))?\)"
    r"(?P<anchor><!-- source-anchor: line=(?P<la>[0-9]+)(?:-(?P<lb>[0-9]+))?; fp=(?P<fp>[0-9a-f]{16}) -->)?")
ANCHOR_OPEN = re.compile(r"<!--\s*source-anchor:")
FRAGMENT = re.compile(r"\]\([^)\s#]+#L[0-9]+(?:-L[0-9]+)?\)")
ROOT_LINK = re.compile(r"(?<!!)\[(?P<label>[^\]\n]*)\]\((?P<path>/[^)\s#]*)(?P<frag>#[^)\s]*)?\)")
ANY_LINK_TARGET = re.compile(r"\]\([^)\n]*\)")
COMMENT = re.compile(r"<!--.*?-->")
LABEL_LINE_TOKEN = re.compile(r"\bL[0-9]+\b|\blines?\s+[0-9]+|:[0-9]+\s*$")
PROSE_LINE_REF = re.compile(r"\bL(?:[4-9]|[0-9]{2,})\b|\blines?\s+[0-9]+\b|[A-Za-z0-9_.\-]+\.[A-Za-z]{1,5}:[0-9]+\b")


class Citation:
    __slots__ = ("line", "start", "end", "label", "path", "a", "b", "fp", "state", "what", "anchor_start")

    def __init__(self, **kw):
        for key in self.__slots__:
            setattr(self, key, kw.get(key))

    @property
    def span(self) -> str:
        return "%d" % self.a if self.b in (None, self.a) else "%d-%d" % (self.a, self.b)

    @property
    def last(self) -> int:
        return self.a if self.b is None else self.b


def anchor_text(a: int, b, fp: str) -> str:
    return "<!-- source-anchor: line=%s; fp=%s -->" % ("%d" % a if b in (None, a) else "%d-%d" % (a, b), fp)


def fragment_text(a: int, b) -> str:
    return "#L%d" % a if b in (None, a) else "#L%d-L%d" % (a, b)


def find_citations(body_lines: list) -> list:
    """Every line citation of a page, with a state: `anchored`, `bare` (no anchor), `line-mismatch`
    (the anchor's `line` names other lines than the fragment), or `malformed` — an anchor opener, or
    a line fragment, that no full citation consumed, and a span that runs backwards. Nothing is
    skipped because it does not parse."""
    found = []
    for index, text in body_lines:
        used = []
        for m in CITATION.finditer(text):
            a, b = int(m.group("a")), (int(m.group("b")) if m.group("b") else None)
            used.append((m.start(), m.end()))
            state = "bare"
            if m.group("anchor"):
                la, lb = int(m.group("la")), (int(m.group("lb")) if m.group("lb") else None)
                state = "anchored" if (la, lb if lb is not None else la) == (a, b if b is not None else a) \
                    else "line-mismatch"
            if a < 1 or (b is not None and b < a):
                state = "malformed"
            found.append(Citation(line=index, start=m.start(), end=m.end(), label=m.group("label"),
                                  path=m.group("path").lstrip("/"), a=a, b=b, fp=m.group("fp"), state=state,
                                  what="span" if state == "malformed" else None,
                                  anchor_start=m.start("anchor") if m.group("anchor") else None))
        inside = lambda pos: any(s <= pos < e for s, e in used)   # noqa: E731
        for rx, what in ((ANCHOR_OPEN, "anchor"), (FRAGMENT, "fragment")):
            for m in rx.finditer(text):
                if not inside(m.start()):
                    found.append(Citation(line=index, start=m.start(), end=m.end(), label="", path="", a=0,
                                          state="malformed", what=what))
    found.sort(key=lambda c: (c.line, c.start))
    return found


def fingerprint(text: str) -> str:
    """The design-artifact standard's expression, verbatim: the first 16 hexadecimal characters of
    the SHA-1 digest of the text's UTF-8 bytes with every run of whitespace collapsed to one space."""
    return hashlib.sha1(" ".join(text.split()).encode("utf-8"), usedforsecurity=False).hexdigest()[:16]


def source_lines(data: bytes):
    """A file's lines as git numbers them, or None when the bytes are not UTF-8 text: split on line
    feeds, one final empty element dropped, one trailing carriage return removed from each line."""
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return None
    if "\0" in text:
        return None
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return [l[:-1] if l.endswith("\r") else l for l in lines]


def cited_text(lines: list, a: int, b) -> str:
    return "\n".join(lines[a - 1:(a if b is None else b)])


def places(lines: list, n: int, fp: str) -> list:
    """The 1-based starts of every run of `n` lines whose fingerprint is `fp`."""
    return [i + 1 for i in range(0, len(lines) - n + 1) if fingerprint("\n".join(lines[i:i + n])) == fp]


def resolve_citation(cit: Citation, lines):
    """(state, new first line or None) of an anchored citation against a file's lines. Uniqueness
    first: no place is `gone`; more than one is `ambiguous`, even when one is the recorded line;
    exactly one is `current` at the recorded line and `moved` anywhere else; a unique place whose
    first or last line is blank is `blank-edge`. `lines` is None when the file is not text."""
    if lines is None:
        return "not-text", None
    n = cit.last - cit.a + 1
    found = places(lines, n, cit.fp)
    if not found:
        return "gone", None
    if len(found) > 1:
        return "ambiguous", None
    start = found[0]
    if not lines[start - 1].strip() or not lines[start + n - 2].strip():
        return "blank-edge", None
    return ("current", None) if start == cit.a else ("moved", start)


def root_links(page: Page) -> list:
    """(line index, match) for every root link of a page body, outside fenced code. A root link
    whose label is a code span is a link; one written wholly inside a code span is not."""
    return [(index, m) for index, text in page.body_lines() for m in ROOT_LINK.finditer(text)]


# ----------------------------------------------------------------------------------------------
# The source set — the one place a path becomes files. It is the page's `depicts` entries and its
# root-link targets, folders expanded, less every file at or under the catalog root, removed after
# expansion. No page is in its own source set or another page's. No caller expands a path itself.
# ----------------------------------------------------------------------------------------------
def clean_entry(entry: str) -> str:
    entry = entry.strip()
    while entry.startswith("./"):
        entry = entry[2:]
    return entry.strip("/")


def in_catalog(path: str, catalog_rel: str) -> bool:
    return path == catalog_rel or path.startswith(catalog_rel + "/")


def expand_entries(entries: list, tracked: Tracked, catalog_rel: str) -> list:
    """Files, in first-seen order. An entry that names no tracked file stands for itself, so a
    source that was deleted is still a member; nothing at or under the catalog root ever is."""
    out, seen = [], set()
    for raw in entries:
        entry = clean_entry(raw)
        for f in tracked.expand(entry) or ([entry] if entry else []):
            if f not in seen and not in_catalog(f, catalog_rel):
                seen.add(f)
                out.append(f)
    return out


def source_set(page: Page, tracked: Tracked, catalog_rel: str) -> dict:
    """{"depicts": [files], "cites": [files the page links and does not depict]}."""
    key = ("sources", id(tracked), catalog_rel)
    if key not in page._cache:
        depicted = expand_entries(page.items("depicts"), tracked, catalog_rel)
        linked = expand_entries([m.group("path") for _i, m in root_links(page)], tracked, catalog_rel)
        held = set(depicted)
        page._cache[key] = {"depicts": depicted, "cites": [f for f in linked if f not in held]}
    return page._cache[key]


# ----------------------------------------------------------------------------------------------
# The catalog: the pack, the registry, the pages found by layout, and the tree helpers.
# ----------------------------------------------------------------------------------------------
class Catalog:
    """Page discovery is by layout, not by a recursive search: the pages are the `.md` files directly
    inside `<catalog>/<universe-id>/` for each registered L0 ID whose stem is a registered ID of
    that universe. A reserved folder is never read as pages. A universe is published when its L0
    page exists; a registered node with no page is unpublished and appears on no generated surface."""

    def __init__(self, roots: Roots, controls_override=None, with_controls: bool = True):
        self.roots = roots
        self.pack = load_pack(roots.pack)
        rows = load_table(roots.registry, REG_HEADER, "ID registry")
        self.registry = {}
        for row in rows:
            self.registry.setdefault(row["id"], row)
        self.order = {nid: n for n, nid in enumerate(self.registry)}
        self.kinds = load_kinds(roots.kinds)
        self.tracked = Tracked(roots.repo)
        self.controls_path = controls_register_path(self.pack, roots.pack, controls_override)
        self.controls = load_table(self.controls_path, HEADER, "controls register") if with_controls else []
        self.begin, self.end = self.pack["navigation_markers"]
        self.warnings = []
        self.universes = [n for n, r in self.registry.items() if r["level"] == "L0"]
        self.pages, self.non_pages = {}, []
        for u in self.universes:
            folder_path = roots.catalog / u
            if u in RESERVED_FOLDERS or not folder_path.is_dir():
                continue
            for p in sorted(folder_path.glob("*.md")):
                if not p.is_file():
                    continue
                row = self.registry.get(p.name[:-3])
                if row is not None and row["universe"] == u:
                    self.pages[p.name[:-3]] = load_page(p, roots)
                else:
                    self.non_pages.append(p)
        self.published_universes = [u for u in self.universes if u in self.pages]
        self.published = {n: p for n, p in self.pages.items()
                          if self.registry[n]["universe"] in self.published_universes}
        self._tree = None

    def warn(self, message: str) -> None:
        if message not in self.warnings:
            self.warnings.append(message)
            print("warning: " + message, file=sys.stderr)

    # -- the tree (the registry is the node set) --
    def level(self, nid: str) -> str:
        return self.registry[nid]["level"]

    def universe(self, nid: str) -> str:
        return self.registry[nid]["universe"]

    def parent_of(self, nid: str):
        page = self.published.get(nid)
        own = page.get("parent") if page else ""
        if own and own in self.registry:
            return own
        return self.registry.get(nid, {}).get("parent") or None

    def siblings(self, parent) -> list:
        """Nodes whose parent is `parent`, in `precedes` order, registry order as the tie-break."""
        sibs = [n for n in self.registry if self.parent_of(n) == parent]
        succ, indeg = defaultdict(list), {s: 0 for s in sibs}
        for s in sibs:
            page = self.published.get(s)
            for t in (page.items("precedes") if page else []):
                if t in indeg and t != s and t not in succ[s]:
                    succ[s].append(t)
                    indeg[t] += 1
        ready = sorted((s for s in sibs if indeg[s] == 0), key=self.order.get)
        out = []
        while ready:
            cur = ready.pop(0)
            out.append(cur)
            for t in succ[cur]:
                indeg[t] -= 1
                if indeg[t] == 0:
                    ready.append(t)
            ready.sort(key=self.order.get)
        return out + sorted((s for s in sibs if s not in out), key=self.order.get)   # a cycle, if any

    def children(self, nid) -> list:
        return self.siblings(nid)

    def descendants(self, nid) -> list:
        out, stack = [], list(self.children(nid))
        while stack:
            cur = stack.pop(0)
            out.append(cur)
            stack += self.children(cur)
        return out

    def title(self, nid: str) -> str:
        page = self.published.get(nid)
        return page.title if page else self.registry[nid]["title"]

    def tree_order(self) -> dict:
        """Pre-order over the tree: the order views list nodes in."""
        if self._tree is None:
            out = []

            def walk(n):
                out.append(n)
                for c in self.children(n):
                    walk(c)
            for root in self.siblings(None):
                walk(root)
            seen = set(out)
            out += [n for n in self.registry if n not in seen]
            self._tree = {n: i for i, n in enumerate(out)}
        return self._tree

    def view_pages(self) -> dict:
        """The pages the index and the views draw on: published, and not `DEPRECATED`."""
        return {n: p for n, p in self.published.items() if p.status != "DEPRECATED"}

    def sources(self, page: Page) -> dict:
        return source_set(page, self.tracked, self.roots.catalog_rel)


# ----------------------------------------------------------------------------------------------
# Generated surfaces. Every byte below is a function of two things: the list of tracked paths,
# and the bytes of the checked-out files under the catalog root. No commit, branch, clock,
# locale, environment variable or absolute path is read, and no file outside the catalog root is
# opened: a depicted folder is expanded from the path list.
# ----------------------------------------------------------------------------------------------
DISABLED_EMITTERS = set()         # a test seam: the emission-mutant arm disables one emitter at a time
EMITTERS = ("graph", "index", "controls-overview", "controls-cited", "controls-kind", "interfaces", "jobs",
            "data-flow", "state", "structure")
MD_LINK = re.compile(r"!?\[([^\]]*)\]\([^)]*\)")
ANCHOR_COMMENT = re.compile(r"<!--\s*source-anchor:.*?-->")
RUNNER_KINDS = ("ci", "hook", "script")
VIEW_NOTES = (
    ("controls-overview", "controls by mechanism kind and enforcement class"),
    ("controls-cited", "the pages and steps that cite each control"),
    ("interfaces", "sub-process boundaries, hand-offs and external system roles"),
    ("jobs", "automated runners and the event and schedule triggers"),
    ("data-flow", "artifacts and records with their producers and consumers"),
    ("state", "state machines the pages describe, and the page lifecycle"),
    ("structure", "depicted files by element kind, with the pages that depict them"),
)


def generated_header(title: str, purpose: str) -> str:
    return ("---\ntitle: %s\npurpose: %s\ntype: reference\nstatus: ACTIVE\n"
            "reversibility: CHEAP / Confidence HIGH\ngenerated_by: %s\n---\n" % (title, purpose, GENERATOR))


def generated_by_line() -> str:
    return "generated_by: %s" % GENERATOR


def plural(n: int, word: str, many: str = "") -> str:
    return "%d %s" % (n, word if n == 1 else (many or word + "s"))


def esc_pipes(s: str) -> str:
    return re.sub(r"(?<!\\)\|", r"\\|", s)


def wrap_placeholders(s: str) -> str:
    """An angle-bracket placeholder outside a code span renders literally once it is a code span."""
    parts = re.split(r"(`+[^`]*`+)", s)
    return "".join(p if p.startswith("`") else re.sub(r"<([A-Za-z][A-Za-z0-9_ -]*)>", r"`<\1>`", p) for p in parts)


def carry(s: str, words: int = 0) -> str:
    """A page cell carried into a view: each link is replaced by its label and each source-anchor
    comment is removed, so no line number and no source link reaches a generated file."""
    s = ANCHOR_COMMENT.sub("", s or "")
    s = re.sub(r"\s+", " ", MD_LINK.sub(lambda m: m.group(1), s)).strip()
    toks = s.split(" ")
    if words and len(toks) > words:
        cut = " ".join(toks[:words])
        if cut.count("`") % 2:
            cut = cut[:cut.rfind("`")]
        s = cut.rstrip(" ,;:—–") + " …"
    return esc_pipes(wrap_placeholders(s))


def md_cell(s: str) -> str:
    return wrap_placeholders(esc_pipes((s or "").replace("\n", " ").strip()))


def code_cell(s: str) -> str:
    return "`%s`" % s.replace("`", "").replace("|", "/")


def view_slug(kind: str) -> str:
    return re.sub(r"[^a-z0-9-]", "", kind)


def leading_class(cls: str) -> str:
    return re.split(r"\s*[(/]", cls.strip())[0].strip() or "—"


def section(heading: str, prose: list, header: list, rows: list) -> list:
    """Lines of one table section, or nothing when it is zero-row: the table has no data row, or
    every data row carries nothing beyond its own key. `rows` is [(cells, carries something)]."""
    if not rows or not any(carries for _cells, carries in rows):
        return []
    out = [heading, ""] + [p for line in prose for p in (line, "")]
    out += ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out += ["| " + " | ".join(cells) + " |" for cells, _carries in rows]
    return out + [""]


class Surfaces:
    """Everything `build` computes, in memory, before a byte is written."""

    def __init__(self, cat: Catalog):
        self.cat = cat
        self.vdir = "%s/%s" % (cat.roots.catalog_rel, VIEWS_FOLDER)
        self.view = cat.view_pages()
        self.lens = effective_lens(cat)
        self.pages = page_regions(cat, self.lens)             # {node id: the page's text as build writes it}
        self.cites, self.ranges = control_citations(self)
        self.files = {}                                       # {path relative to the catalog root: text}
        self.problems = []
        self._build()

    # -- links and locations --
    def link(self, nid: str, start: str) -> str:
        return os.path.relpath(self.cat.published[nid].rel, start).replace(os.sep, "/")

    def plink(self, nid: str, start=None) -> str:
        """A page's link from a view, with the draft mark directly after it; an unpublished or
        deprecated node is plain text."""
        if nid not in self.view:
            return carry(nid)
        mark = DRAFT_MARK if self.view[nid].status == "DRAFT" else ""
        return "[%s](%s)%s" % (nid, self.link(nid, start or self.vdir), mark)

    def locs(self, locs: dict, link_slugs: bool = False) -> str:
        """`[page](link) (slug, slug)` per page, in tree order."""
        order = self.cat.tree_order()
        out = []
        for pid in sorted(locs, key=lambda p: (order.get(p, len(order)), p)):
            slugs = [self.plink(s) if link_slugs and s in self.view else carry(s) for s in locs[pid] if s]
            out.append(self.plink(pid) + (" (%s)" % ", ".join(slugs) if slugs else ""))
        return " · ".join(out) or "—"

    def universes(self) -> list:
        return [u for u in self.cat.siblings(None) if u in self.cat.published_universes and u in self.view]

    def col(self, table: str, name: str, fallback: int) -> int:
        cols = self.cat.pack["tables"].get(table, [])
        return cols.index(name) if name in cols else fallback

    def step_rows(self, page: Page) -> list:
        width = len(self.cat.pack["tables"].get("Steps", [])) or 9
        return [r for r in page.rows("Steps") if len(r) >= width] if self.cat.level(page.id) == "L3" else []

    # -- assembly --
    def _build(self) -> None:
        cat = self.cat
        emit = lambda name: name not in DISABLED_EMITTERS      # noqa: E731
        views = {}
        if emit("controls-kind"):
            views.update(controls_kind_views(self))
        for name, builder in (("controls-overview", controls_overview), ("controls-cited", controls_cited),
                              ("interfaces", interfaces_view), ("jobs", jobs_view), ("data-flow", data_flow_view),
                              ("state", state_view), ("structure", structure_view)):
            if emit(name):
                views.update(builder(self) or {})
        for name, text in sorted(views.items()):
            self.files["%s/%s" % (VIEWS_FOLDER, name)] = text
        if emit("graph"):
            self.files[GRAPH_NAME] = json.dumps(build_graph(self), indent=2, sort_keys=True,
                                                ensure_ascii=False) + "\n"
        if emit("index"):
            text = render_index(self, sorted(views))
            if token_estimate(text) > INDEX_TOKEN_BUDGET:
                cat.warn("%s is about %d tokens, over its budget of %d"
                         % (INDEX_NAME, token_estimate(text), INDEX_TOKEN_BUDGET))
            self.files[INDEX_NAME] = text
        self._guard_number_signs()

    def _guard_number_signs(self) -> None:
        """A generated Markdown file never carries a number sign followed by a digit outside fenced
        code. The message names the page, register row or registry row the text came from."""
        hits = []
        for name, text in sorted(self.files.items()):
            if not name.endswith(".md"):
                continue
            lines = text.split("\n")
            flags = fence_flags(lines)
            if any(NUMBER_SIGN.search(line) for line, fenced in zip(lines, flags) if not fenced):
                hits.append(name)
        if not hits:
            return
        origins = []
        for nid, page in sorted(self.view.items()):
            if any(NUMBER_SIGN.search(text) for _i, text in page.body_lines()) or NUMBER_SIGN.search(page.title):
                origins.append("page %s" % nid)
        origins += ["register row %s" % r["control_id"] for r in self.cat.controls
                    if any(NUMBER_SIGN.search(v) for v in r.values())]
        origins += ["registry row %s" % n for n, r in self.cat.registry.items() if NUMBER_SIGN.search(r["title"])]
        self.problems.append("a generated file would carry a number sign followed by a digit (%s); it comes from: %s"
                             % (", ".join(hits), ", ".join(origins) or "an input no page or register row names"))


# -- the lens roll-up and the page regions the generator owns ------------------------------------
def derive_lens(counts: Counter):
    """The derived verdict of an L0 or L1 page from its descendant pages, or None with none."""
    if not counts:
        return None
    assessed = {k for k in counts if k != "not-assessed"}
    if not assessed:
        return "not-assessed"
    if "deviates" in assessed:
        return "deviates"
    if assessed == {"conformant"}:
        return "conformant"
    if assessed == {"unobserved"}:
        return "unobserved"
    return "deviates"


def effective_lens(cat: Catalog) -> dict:
    """`lens_status` per published page as `build` writes it. On an L2 page a floor only: `deviates`
    when a child L3 page deviates, otherwise the page's own value — it never lowers an L2. On an L1
    and an L0 page the value is derived from the descendant pages."""
    eff = {n: p.lens_status for n, p in cat.published.items()}
    for n in cat.published:
        if cat.level(n) == "L2" and any(eff[d] == "deviates" for d in cat.descendants(n)
                                        if d in cat.published and cat.level(d) == "L3"):
            eff[n] = "deviates"
    for level in ("L1", "L0"):
        for n in cat.published:
            if cat.level(n) == level:
                derived = derive_lens(Counter(eff[d] for d in cat.descendants(n) if d in cat.published))
                if derived is not None:
                    eff[n] = derived
    return eff


LENS_LINE = re.compile(r"^lens_status[ \t]*:")      # locates the one line build rewrites; the value is the reader's


def nav_line(cat: Catalog, nid: str) -> str:
    """An unpublished node never appears: Up is the nearest published ancestor, Previous and Next
    skip to the nearest published sibling, and Down lists published children only."""
    page = cat.published[nid]
    start = os.path.dirname(page.rel)
    ref = lambda n: "[%s](%s)" % (n, os.path.relpath(cat.published[n].rel, start).replace(os.sep, "/"))  # noqa: E731
    parts = []
    parent = cat.parent_of(nid)
    up = parent
    while up is not None and up not in cat.published:
        up = cat.parent_of(up)
    if up is not None:
        parts.append("Up: " + ref(up))
    sibs = cat.siblings(parent)
    i = sibs.index(nid)
    before = [s for s in sibs[:i] if s in cat.published]
    after = [s for s in sibs[i + 1:] if s in cat.published]
    if before:
        parts.append("Previous: " + ref(before[-1]))
    if after:
        parts.append("Next: " + ref(after[0]))
    kids = [k for k in cat.children(nid) if k in cat.published]
    if kids:
        parts.append("Down: " + " · ".join(ref(k) for k in kids))
    return " · ".join(parts)


def page_regions(cat: Catalog, eff: dict) -> dict:
    """Each published page's text with its two generator-owned regions rewritten and no other byte
    changed: the navigation block between the pack's two markers, and the `lens_status` line (derived
    on L0 and L1; the floor on L2). A page without the markers is left as it is."""
    out = {}
    for nid, page in cat.published.items():
        text = page.text
        b, e = text.find(cat.begin), text.find(cat.end)
        if 0 <= b < e:
            start = b + len(cat.begin)
            text = text[:start] + "\n" + nav_line(cat, nid) + "\n" + text[e:]
        if cat.level(nid) in ("L0", "L1", "L2") and eff[nid] != page.lens_status and page.fm_end is not None:
            parts = text.splitlines(keepends=True)
            for i in range(1, min(page.fm_end, len(parts))):
                line = parts[i]
                if LENS_LINE.match(line):
                    ending = line[len(line.rstrip("\r\n")):]
                    parts[i] = "lens_status: %s%s" % (eff[nid], ending)
                    break
            text = "".join(parts)
        out[nid] = text
    return out


# -- the graph -----------------------------------------------------------------------------------
def trigger_kind(cat: Catalog, t: str) -> str:
    for k in cat.pack["enums"]["trigger_kinds"]:
        if t.startswith(k):
            return k.rstrip(":")
    return "node" if t in cat.registry else "unknown"


def build_graph(s: Surfaces) -> dict:
    cat = s.cat
    nodes, edges = [], []
    depicted_by, cited_by, documented_by = defaultdict(list), defaultdict(list), defaultdict(list)

    def edge(kind, src, dst, **extra):
        e = {"type": kind, "from": src, "to": dst}
        e.update(extra)
        if dst in cat.registry and kind != "documents" and extra.get("target_kind", "node") == "node":
            e["target_published"] = dst in cat.published
        edges.append(e)

    for nid, row in cat.registry.items():
        page = cat.published.get(nid)
        parent = cat.parent_of(nid)
        nodes.append({"id": nid, "level": row["level"], "title": cat.title(nid), "universe": row["universe"],
                      "parent": parent, "published": page is not None, "path": page.rel if page else None,
                      "status": page.status if page else None, "lens_status": s.lens[nid] if page else None,
                      "children": cat.children(nid)})
        if parent:
            edge("sub-flow-of", nid, parent)
        if not page:
            continue
        for t in page.items("precedes"):
            edge("precedes", nid, t)
        for t in page.items("triggered_by"):
            edge("triggered-by", nid, t, target_kind=trigger_kind(cat, t))
        for t in page.items("depends_on"):
            edge("depends-on", nid, t)
        sources = cat.sources(page)
        for f in sources["depicts"]:
            edge("depicts", nid, f)
            depicted_by[f].append(nid)
        for f in sources["cites"]:
            cited_by[f].append(nid)
        for doc in page.items("documented_by"):
            doc = clean_entry(doc)
            if doc and not in_catalog(doc, cat.roots.catalog_rel):
                edge("documents", doc, nid)
                documented_by[doc].append(nid)
        for t in page.items("supersedes"):
            edge("supersedes", nid, t)
    ordered = lambda index: {p: sorted(ids, key=cat.order.get) for p, ids in sorted(index.items())}  # noqa: E731
    return {
        "schema_version": 1, "generator": GENERATOR, "pack_version": str(cat.pack["pack_version"]),
        "counts": {"nodes": len(nodes), "published": len(cat.published),
                   "nodes_by_level": dict(sorted(Counter(n["level"] for n in nodes).items())),
                   "pages_by_level": dict(sorted(Counter(n["level"] for n in nodes if n["published"]).items())),
                   "edges_by_type": dict(sorted(Counter(e["type"] for e in edges).items()))},
        "nodes": nodes, "edges": edges,
        "depicted_by": ordered(depicted_by), "cited_by": ordered(cited_by), "documented_by": ordered(documented_by),
    }


# -- the index -----------------------------------------------------------------------------------
def render_index(s: Surfaces, view_names: list) -> str:
    """One heading per published universe, linked to its L0 page; one bullet per value stream with
    its count of sub-processes and of those that have a page; one line per emitted view. No commit,
    no pack stamp, no registry total, and no line for an unpublished universe or node."""
    cat, root = s.cat, s.cat.roots.catalog_rel

    def ref(nid):
        mark = {"DRAFT": DRAFT_MARK, "SUPERSEDED": SUPERSEDED_MARK}.get(s.view[nid].status, "")
        return "[%s](%s)%s" % (carry(cat.title(nid)), s.link(nid, root), mark)

    lines = [generated_header("Process catalog index", "Every published universe and its value streams, with a "
                              "link to each page and to each generated view"),
             "# Process catalog index", ""]
    for u in s.universes():
        lines += ["## " + ref(u), ""]
        for l1 in cat.children(u):
            if l1 not in s.view:
                continue
            kids = cat.children(l1)
            lines.append("- %s · %s (%d with a page)"
                         % (ref(l1), plural(len(kids), "sub-process", "sub-processes"),
                            sum(1 for k in kids if k in s.view)))
        lines.append("")
    if view_names:
        notes = dict(VIEW_NOTES)
        lines += ["## Views", ""]
        for name in view_names:
            stem = name[:-3]
            note = notes.get(stem) or ("the controls whose mechanism kind is %s" % stem[len("controls-"):]
                                       if stem.startswith("controls-") else "one universe's part of a view")
            lines.append("- [%s](%s/%s) — %s" % (stem, VIEWS_FOLDER, name, note))
        lines.append("")
    return "\n".join(lines)


# -- views: shared ---------------------------------------------------------------------------------
def add_loc(locs: dict, pid: str, slug: str = "") -> None:
    locs.setdefault(pid, [])
    if slug and slug not in locs[pid]:
        locs[pid].append(slug)


def cited_ids(cell: str):
    ids, n = [], 0
    for m in CONTROL_RANGE.finditer(cell):
        lo, hi = int(m.group(1)), int(m.group(2))
        if lo < hi <= lo + 50:
            n += 1
            ids += ["C-%03d" % k for k in range(lo, hi + 1)]
    return list(dict.fromkeys(ids + CONTROL_ID.findall(cell))), n


def control_citations(s: Surfaces):
    """({control id: {page: [slug…]}}, ranges expanded). On an L3 page: each Steps row's Controls cell,
    with the step key as the slug. On an L1 or L2 page: each Controls row read whole, with the
    Applies-to cell's entries as the slugs."""
    cat, cites, ranges_n = s.cat, defaultdict(dict), 0
    order = cat.tree_order()
    c_col, a_col = s.col("Steps", "Controls", 4), s.col("Controls", "Applies to", 4)
    for nid in sorted(s.view, key=order.get):
        page = s.view[nid]
        if cat.level(nid) == "L3":
            src = [(r[c_col], [unspan(r[0])]) for r in s.step_rows(page)]
        else:
            src = [(" ".join(r), [x.strip() for x in r[a_col].split(",") if x.strip()] if len(r) > a_col else [])
                   for r in page.rows("Controls")]
        for cell, slugs in src:
            ids, n = cited_ids(cell)
            ranges_n += n
            for cid in ids:
                for slug in slugs or [""]:
                    add_loc(cites[cid], nid, slug)
    return dict(sorted(cites.items())), ranges_n


def assemble_view(s: Surfaces, name: str, title: str, purpose: str, intro: list, blocks: list, tail=()) -> dict:
    """{file name: text} for one view, or nothing when no section is left. Written whole, or — only
    above the split weight and with more than one published universe — as an overview with one file
    per universe. An over-weight file is a warning."""
    blocks = [(u, lines) for u, lines in blocks if lines]
    tail = list(tail)
    if not blocks and not tail:
        return {}
    head = generated_header(title, purpose)
    whole = [head, "# " + title, ""] + intro
    for u, lines in blocks:
        whole += ["## " + carry(s.cat.title(u)), ""] + lines
    whole += tail
    written = {}
    if split_weight("\n".join(whole)) <= VIEW_SPLIT_WEIGHT or len(s.universes()) < 2:
        written[name + ".md"] = "\n".join(whole)
    else:
        over = [head, "# " + title, ""] + intro + ["## Per universe", ""]
        over += ["- [%s](%s-%s.md)" % (carry(s.cat.title(u)), name, u) for u, _ in blocks] + [""] + tail
        written[name + ".md"] = "\n".join(over)
        for u, lines in blocks:
            sub = "%s — %s" % (title, carry(s.cat.title(u)))
            body = [generated_header(sub, purpose + ", for one universe"), "# " + sub, "",
                    "Part of [%s](%s.md), split by universe." % (title, name), ""]
            written["%s-%s.md" % (name, u)] = "\n".join(body + [l[1:] if l.startswith("### ") else l for l in lines])
    for file_name, text in written.items():
        if split_weight(text) > VIEW_SPLIT_WEIGHT:
            s.cat.warn("%s/%s is over the view split weight" % (VIEWS_FOLDER, file_name))
    return written


def split_weight(text: str) -> int:
    return token_estimate(text)


# -- views: the control layer --------------------------------------------------------------------
def register_kinds(s: Surfaces) -> list:
    present = {r["mechanism_kind"] for r in s.cat.controls}
    declared = [k for k in s.cat.pack["controls_register_rules"]["kinds"] if k in present]
    return declared + sorted(present - set(declared))


def class_arms(s: Surfaces, cls: str) -> list:
    """The distinct classes a register cell names: the leading token of each ` / ` arm."""
    arms = []
    for part in cls.split(" / "):
        lead = leading_class(part)
        if lead not in arms:
            arms.append(lead)
    return arms


def controls_kind_views(s: Surfaces) -> dict:
    """One view per mechanism kind that has rows; a kind with none is not written."""
    out = {}
    for kind in register_kinds(s):
        slug = view_slug(kind)
        rows = sorted((r for r in s.cat.controls if r["mechanism_kind"] == kind), key=lambda r: r["control_id"])
        title = "Controls — %s" % slug
        lines = [generated_header(title, "The %s whose mechanism kind is %s, from the controls register"
                                  % (plural(len(rows), "control"), slug)), "# " + title, "",
                 "%s from the controls register. The statement, the class and the surface are the register's "
                 "cells. Cited by counts the pages that cite the control; the pages and steps are on "
                 "[controls-cited](controls-cited.md)." % plural(len(rows), "control"), "",
                 "| Control | Statement | Enforcement class | Surface | Source path | Cited by |", "|---|---|---|---|---|---|"]
        for r in rows:
            n_pages = len(s.cites.get(r["control_id"], {}))
            paths = " · ".join(code_cell(p.strip()) for p in r["source_path"].split(";") if p.strip()) or "—"
            lines.append("| %s | %s | %s | %s | %s | %s |" % (
                r["control_id"], md_cell(r["statement"]), md_cell(r["enforcement_class_default"]),
                md_cell(r["enforcement_surface"]) or "—", paths, plural(n_pages, "page") if n_pages else "—"))
        lines.append("")
        out["controls-%s.md" % slug] = "\n".join(lines)
    return out


def controls_overview(s: Surfaces) -> dict:
    rows, kinds = s.cat.controls, register_kinds(s)
    classes = s.cat.pack["controls_register_rules"]["classes"]
    arms_of = {r["control_id"]: class_arms(s, r["enforcement_class_default"]) for r in rows}
    single, split_n, arm_n = Counter(), Counter(), Counter()
    for r in rows:
        arms = arms_of[r["control_id"]]
        for c in arms:
            arm_n[r["mechanism_kind"], c] += 1
        if len(arms) > 1:
            split_n[r["mechanism_kind"]] += 1
        else:
            single[r["mechanism_kind"], arms[0]] += 1
    seen = {c for _k, c in arm_n}
    cols = [c for c in classes if c in seen] + sorted(seen - set(classes))
    split_rows = [r for r in rows if len(arms_of[r["control_id"]]) > 1]
    cited = {cid for cid in s.cites if cid in arms_of}
    emitted = "controls-kind" not in DISABLED_EMITTERS
    lines = [generated_header("Controls — overview", "Counts of controls by mechanism kind and enforcement class, "
                              "with one view per kind and the control-to-page inversion"),
             "# Controls — overview", "",
             "%s in the controls register. A cell naming one class counts under that class, a qualifier included. "
             "A cell naming two classes counts in the Split column. Cited counts the kind's controls that at least "
             "one page cites." % plural(len(rows), "control"), "",
             "| Mechanism kind | " + " | ".join(md_cell(c) for c in cols) + " | Split | Total | Cited | View |",
             "|" + "---|" * (len(cols) + 5)]
    for kind in kinds:
        slug = view_slug(kind)
        total = sum(1 for r in rows if r["mechanism_kind"] == kind)
        n_cited = sum(1 for r in rows if r["mechanism_kind"] == kind and r["control_id"] in cited)
        cells = [str(single.get((kind, c), 0) or "") for c in cols]
        lines.append("| %s | %s | %s | %d | %s | %s |" % (
            md_cell(kind), " | ".join(cells), split_n.get(kind, 0) or "", total, n_cited or "",
            "[%s](controls-%s.md)" % (slug, slug) if emitted else slug))
    lines.append("| **Total** | %s | %d | %d | %d | |" % (
        " | ".join(str(sum(single.get((k, c), 0) for k in kinds)) for c in cols), len(split_rows), len(rows), len(cited)))
    lines.append("")
    lines += section("## Split cells, counted by arm",
                     ["A split cell counts once under each class it names."],
                     ["Control", "Mechanism kind", "Arms", "Cell as the register writes it"],
                     [([r["control_id"], md_cell(r["mechanism_kind"]),
                        " · ".join(md_cell(c) for c in arms_of[r["control_id"]]),
                        md_cell(r["enforcement_class_default"])], True)
                      for r in sorted(split_rows, key=lambda r: r["control_id"])])
    unreg = sorted(cid for cid in s.cites if cid not in arms_of)
    lines += ["## Citations", "",
              "%d of %s cited by at least one page, read from the Steps rows of activity pages and the Controls "
              "tables of the pages above them. The pages and steps citing each control are on "
              "[controls-cited](controls-cited.md). Cited IDs with no row in the register: %s."
              % (len(cited), plural(len(rows), "control is", "controls are"), ", ".join(unreg) if unreg else "none"), ""]
    return {"controls-overview.md": "\n".join(lines)}


def controls_cited(s: Surfaces) -> dict:
    cat, rows = s.cat, s.cat.controls
    kind_of = {r["control_id"]: r["mechanism_kind"] for r in rows}
    class_of = {r["control_id"]: r["enforcement_class_default"] for r in rows}
    blocks, summary = [], []
    for u in s.universes():
        lines, n_ids = [], 0
        for kind in register_kinds(s):
            ids = sorted(cid for cid in s.cites if kind_of.get(cid) == kind
                         and any(cat.universe(p) == u for p in s.cites[cid]))
            n_ids += len(ids)
            lines += section("### %s — %s" % (md_cell(kind), plural(len(ids), "control")), [],
                             ["Control", "Class", "Cited by: page (steps, or the Applies-to entries)"],
                             [([cid, md_cell(class_of[cid]),
                                s.locs({p: v for p, v in s.cites[cid].items() if cat.universe(p) == u},
                                       link_slugs=True)], True) for cid in ids])
        blocks.append((u, lines))
        if n_ids:
            summary.append("| %s | %d |" % (carry(cat.title(u)), n_ids))
    unreg = sorted(cid for cid in s.cites if cid not in kind_of)
    tail = section("## Cited IDs with no row in the register", [], ["Control", "Cited by"],
                   [([cid, s.locs(s.cites[cid], link_slugs=True)], True) for cid in unreg])
    intro = ["For each control in the register, the pages that cite it and where: on an activity page the keys of "
             "the Steps rows whose Controls cell names the ID; on a page above it the entries of the Controls row's "
             "Applies-to cell. A control no page cites is not listed.", ""]
    if summary:
        intro += ["| Universe | Controls cited |", "|---|---|"] + summary + [""]
    return assemble_view(s, "controls-cited", "Controls — cited by pages",
                         "The pages and steps that cite each control", intro, blocks, tail)


# -- views: interfaces -----------------------------------------------------------------------------
def interfaces_view(s: Surfaces) -> dict:
    cat, order = s.cat, s.cat.tree_order()
    blocks, summary = [], []
    for u in s.universes():
        l2s = sorted((n for n in s.view if cat.universe(n) == u and cat.level(n) == "L2"), key=order.get)
        rows = []
        for n in l2s:
            parent = cat.parent_of(n)
            for r in s.view[n].rows("Entry and exit"):
                rows.append(([s.plink(n), s.plink(parent) if parent else "—", carry(r[0]),
                              carry(r[1] if len(r) > 1 else "", CRITERIA_WORDS)], True))
        lines = section("### Sub-process boundaries",
                        ["The Entry and exit rows of each sub-process page, criteria cut to %d words." % CRITERIA_WORDS],
                        ["Sub-process", "Value stream", "Side", "Criteria"], rows)
        edges = set()
        for n in l2s:
            for t in s.view[n].items("precedes"):
                if t in cat.registry and cat.level(t) == "L2":
                    edges.add((n, "precedes", t))
            for t in s.view[n].items("triggered_by"):
                if t in cat.registry and cat.level(t) == "L2":
                    edges.add((n, "is triggered by", t))
        edges = sorted(edges, key=lambda e: (order.get(e[0]), e[1], order.get(e[2], len(order))))
        lines += section("### Hand-offs between sub-processes",
                         ["The `precedes` and `triggered_by` links whose two ends are sub-processes, as the pages "
                          "declare them."], ["Sub-process", "Link", "Other sub-process"],
                         [([s.plink(f), kind, s.plink(t)], True) for f, kind, t in edges])
        roles, trig = defaultdict(lambda: {"pages": {}, "steps": {}}), defaultdict(dict)
        for nid in sorted((p for p in s.view if cat.universe(p) == u), key=order.get):
            page = s.view[nid]
            for act in page.items("actors"):
                if act.startswith("external:"):
                    add_loc(roles[act]["pages"], nid)
            for t in page.items("triggered_by"):
                if t.startswith("external:"):
                    add_loc(trig[t], nid)
            for r in s.step_rows(page):
                for role in sorted(set(re.findall(r"external:[A-Za-z0-9_-]+", " ".join(r)))):
                    add_loc(roles[role]["steps"], nid, unspan(r[0]))
        lines += section("### External system roles",
                         ["Each `external:` actor, with the pages whose `actors` name it and the Steps rows that "
                          "name it."], ["Role", "Pages", "Steps"],
                         [([code_cell(role), s.locs(roles[role]["pages"]), s.locs(roles[role]["steps"])], True)
                          for role in sorted(roles)])
        lines += section("### External triggers", [], ["Trigger", "Pages it triggers"],
                         [([code_cell(t), s.locs(trig[t])], True) for t in sorted(trig)])
        blocks.append((u, lines))
        if lines:
            summary.append("| %s | %d | %d | %d | %d | %d |" % (carry(cat.title(u)), len(l2s), len(rows), len(edges),
                                                           len(roles), len(trig)))
    intro = ["Where the pieces meet: each sub-process's entry and exit, the hand-offs its page declares, and every "
             "external system role and external trigger with the pages and steps that touch it.", "",
             "| Universe | Sub-process pages | Boundary rows | Hand-offs | External roles | External triggers |",
             "|---|---|---|---|---|---|"] + summary + [""]
    return assemble_view(s, "interfaces", "Interfaces", "Sub-process boundaries, hand-offs between sub-processes "
                         "and external system roles, per universe", intro, blocks)


# -- views: jobs -------------------------------------------------------------------------------------
def runner_pattern(token: str):
    return re.compile(r"(?<![\w:./-])" + re.escape(token) + r"(?![\w./-])")


def runner_fired_by(runner: str, controls: list) -> list:
    """What the controls register says fires a runner: a workflow's job rows, a hook's registrations."""
    kind, name = runner.split(":", 1)
    stem = lambda p: os.path.splitext(os.path.basename(p.strip()))[0]      # noqa: E731
    out = []
    if kind == "ci":
        vals = defaultdict(list)
        for r in controls:
            if r["mechanism_kind"] == "ci-job" and stem(r["source_path"].split(";")[0]) == stem(name):
                vals[carry(r["applies_to"], 16)].append(r["control_id"])
        out = ["%s (%s)" % (v, ", ".join(ids)) for v, ids in vals.items()]
    elif kind == "hook":
        for r in controls:
            parts = r["mechanism_ref"].split("#")
            if r["mechanism_kind"] == "hook-registration" and len(parts) >= 2 and stem(parts[-1]) == stem(name):
                out.append(esc_pipes(" · ".join(code_cell(x) for x in parts[:-1])) + " (%s)" % r["control_id"])
    return out[:3] + (["+%d more" % (len(out) - 3)] if len(out) > 3 else [])


def jobs_view(s: Surfaces) -> dict:
    cat, order = s.cat, s.cat.tree_order()
    actor_col, mech_col = s.col("Steps", "Actor", 2), s.col("Steps", "Mechanism", 5)
    all_runners = sorted({a for p in s.view.values() for a in p.items("actors")
                          if ":" in a and a.split(":", 1)[0] in RUNNER_KINDS})
    pats = {r: (runner_pattern(r), runner_pattern(r.split(":", 1)[1]) if len(r.split(":", 1)[1]) >= 6 else None)
            for r in all_runners}
    blocks, summary = [], []
    for u in s.universes():
        acts, run_by, page_trig, triggers = defaultdict(dict), defaultdict(set), defaultdict(set), defaultdict(dict)
        for nid in sorted((p for p in s.view if cat.universe(p) == u), key=order.get):
            page = s.view[nid]
            for rn in (x for x in page.items("actors") if x in pats):
                add_loc(acts[rn], nid)
            ptrig = [t for t in page.items("triggered_by") if t.startswith(("event:", "schedule:"))]
            for t in ptrig:
                add_loc(triggers[t], nid)
            for r in s.step_rows(page):
                for rn, (p_actor, p_name) in pats.items():
                    if p_actor.search(r[actor_col]) or (p_name and p_name.search(r[mech_col])):
                        add_loc(acts[rn], nid, unspan(r[0]))
                        run_by[rn].update(x.strip() for x in re.split(r"[,;]", unspan(r[actor_col]))
                                          if x.strip() and x.strip() != rn)
                        page_trig[rn].update(ptrig)
        rows, n_steps = [], 0
        for rn in sorted(acts, key=lambda x: (RUNNER_KINDS.index(x.split(":", 1)[0]), x)):
            fired = runner_fired_by(rn, cat.controls)
            if fired:
                fired_s = "; ".join(fired)
            elif run_by[rn]:
                fired_s = "run by " + ", ".join(carry(x) for x in sorted(run_by[rn])) + " (no register row)"
            elif page_trig[rn]:
                fired_s = "page trigger " + ", ".join(code_cell(t) for t in sorted(page_trig[rn])) + " (no register row)"
            else:
                fired_s = "— (no register row, no other actor and no page trigger)"
            n_steps += sum(len(v) for v in acts[rn].values())
            rows.append(([code_cell(rn), fired_s, s.locs(acts[rn])], True))
        lines = section("### Runners",
                        ["Every `ci:`, `hook:` and `script:` actor. Fired by: the controls register where it has a "
                         "row; else the actors of the steps that run it; else the event and schedule triggers of "
                         "the pages where it acts."], ["Runner", "Fired by", "Acts in: page (steps)"], rows)
        lines += section("### Event and schedule triggers", [], ["Trigger", "Pages it triggers"],
                         [([code_cell(t), s.locs(triggers[t])], True)
                          for t in sorted(triggers, key=lambda x: (not x.startswith("schedule:"), x))])
        blocks.append((u, lines))
        if lines:
            by_kind = Counter(r.split(":", 1)[0] for r in acts)
            summary.append("| %s | %d | %d | %d | %d | %d | %d |" % (
                carry(cat.title(u)), by_kind["ci"], by_kind["hook"], by_kind["script"], n_steps,
                sum(1 for t in triggers if t.startswith("event:")), sum(1 for t in triggers if t.startswith("schedule:"))))
    intro = ["Every automated runner the pages name, what fires it and where it acts, and every event and schedule "
             "trigger with the pages it starts.", "",
             "| Universe | ci | hook | script | Step rows where a runner acts | Event triggers | Schedule triggers |",
             "|---|---|---|---|---|---|---|"] + summary + [""]
    stem = lambda p: os.path.splitext(os.path.basename(p.strip()))[0]      # noqa: E731
    depicted = {stem(r.split(":", 1)[1]) for r in all_runners if r.startswith("ci:")}
    registered = sorted({stem(r["source_path"].split(";")[0]) for r in cat.controls
                         if r["mechanism_kind"] == "ci-job" and r["source_path"].strip()})
    missing = [w for w in registered if w not in depicted]
    if missing and any(lines for _u, lines in blocks):
        intro += ["### Registered, not depicted", "",
                  "%d of the controls register's %s named by no page's `actors`: %s."
                  % (len(missing), plural(len(registered), "workflow is", "workflows are"),
                     ", ".join(code_cell("ci:" + w) for w in missing)), ""]
    return assemble_view(s, "jobs", "Jobs", "Automated runners and event and schedule triggers, with what fires "
                         "each and where it acts, per universe", intro, blocks)


# -- views: data flow --------------------------------------------------------------------------------
DF_STOP = {"pass", "fail", "warning", "warn", "blocker", "halt", "clean", "go", "no-go", "ok", "skip", "error", "none",
           "nothing", "yes", "no", "done", "conditional pass"}
DF_LEAD = re.compile(r"^(?:the|a|an|its|their|each|every|any|all|both|one|or|and|else|plus|then)\s+")
DF_FILE = re.compile(r"(?<![\w/.-])[\w.-]+\.(?:md|json|jsonl|tsv|csv|ya?ml|toml|txt|log|xlsx|docx|pptx)\b")
DF_CMD = re.compile(r"^(?:-|gh\b|git\b|python3?\b|bash\b|grep\b|jq\b|\./)")


def df_split(cell: str) -> list:
    """Items of an inputs or outputs cell: split on `;`, `, ` and ` + ` outside code spans and parentheses."""
    items, cur, depth, code, k = [], "", 0, False, 0
    while k < len(cell):
        ch = cell[k]
        if ch == "`":
            code = not code
        elif not code and ch in "([":
            depth += 1
        elif not code and ch in ")]" and depth:
            depth -= 1
        if not code and not depth and (ch == ";" or cell.startswith(", ", k) or cell.startswith(" + ", k)):
            items.append(cur)
            cur = ""
            k += 3 if cell.startswith(" + ", k) else 1
            continue
        cur += ch
        k += 1
    return [x.strip() for x in items + [cur] if x.strip()]


def df_norm(item: str) -> str:
    x = MD_LINK.sub(lambda m: m.group(1), ANCHOR_COMMENT.sub("", item))
    y = None
    while y != x:
        y, x = x, re.sub(r"\([^()]*\)", "", x)
    x = re.sub(r"\s+", " ", x.replace("`", "")).strip(" .;:,—–-").lower()
    y = None
    while y != x:
        y, x = x, DF_LEAD.sub("", x).strip()
    return x


def df_keys(item: str) -> list:
    """Record names inside an item: code spans that are not flags or commands, and file names."""
    text = MD_LINK.sub(lambda m: m.group(1), ANCHOR_COMMENT.sub("", item))
    keys = [c.strip() for c in re.findall(r"`([^`]+)`", text) if len(c.strip()) >= 3 and not DF_CMD.match(c.strip())]
    keys += DF_FILE.findall(re.sub(r"`[^`]*`", " ", text))
    return list(dict.fromkeys(keys))


def df_items(s: Surfaces) -> list:
    """Every named input and output of the activity pages: the ICOM table's Inputs and Outputs cells,
    and each Steps row's shape cell split at its first arrow."""
    cat, out = s.cat, []
    shape = s.col("Steps", "Inputs → outputs (shape)", 3)
    for nid in sorted(s.view, key=cat.tree_order().get):
        page = s.view[nid]
        if cat.level(nid) != "L3":
            continue
        cells = []
        for r in page.rows("ICOM"):
            cells += [("in", "ICOM", r[0])] + ([("out", "ICOM", r[2])] if len(r) > 2 else [])
        for r in s.step_rows(page):
            if "→" in r[shape]:
                left, right = r[shape].split("→", 1)
                cells += [("in", unspan(r[0]), left), ("out", unspan(r[0]), right)]
        for side, loc, cell in cells:
            for it in df_split(cell):
                norm = df_norm(it)
                if norm:
                    out.append({"u": cat.universe(nid), "page": nid, "loc": loc, "side": side, "raw": it,
                                "norm": norm, "keys": df_keys(it), "words": len(norm.split())})
    return out


def df_flows(items: list, key_fn) -> dict:
    flows = defaultdict(lambda: {"out": [], "in": []})
    for it in items:
        for name in key_fn(it):
            loc = (it["u"], it["page"], it["loc"])
            if loc not in flows[name][it["side"]]:
                flows[name][it["side"]].append(loc)
    return flows


def df_matched(flow: dict, u=None, cross: bool = False) -> bool:
    if cross:
        return any(o[0] != i[0] for o in flow["out"] for i in flow["in"])
    outs = [x for x in flow["out"] if u is None or x[0] == u]
    ins = [x for x in flow["in"] if u is None or x[0] == u]
    return any(o != i for o in outs for i in ins)


def data_flow(s: Surfaces):
    """(blocks, summary rows, tail lines, unmatched rows) — shared by the view and the listing command."""
    items = df_items(s)
    by_key = df_flows(items, lambda it: it["keys"])
    by_name = df_flows(items, lambda it: [it["norm"]] if it["words"] >= 2 and it["norm"] not in DF_STOP else [])

    def locs_of(entries, side, u=None):
        locs = {}
        for uu, page, loc in entries[side]:
            if u is None or uu == u:
                add_loc(locs, page, loc)
        return locs

    blocks, summary, matched = [], [], set()
    for u in s.universes():
        keys = sorted(k for k, f in by_key.items() if df_matched(f, u))
        names = sorted(k for k, f in by_name.items() if df_matched(f, u))
        lines = section("### Named records (code spans and file names)", [], ["Record", "Produced by", "Consumed by"],
                        [([code_cell(k), s.locs(locs_of(by_key[k], "out", u)), s.locs(locs_of(by_key[k], "in", u))], True)
                         for k in keys])
        lines += section("### Artifacts by name (two or more words, equal after normalization)", [],
                         ["Artifact", "Produced by", "Consumed by"],
                         [([carry(k), s.locs(locs_of(by_name[k], "out", u)), s.locs(locs_of(by_name[k], "in", u))], True)
                          for k in names])
        blocks.append((u, lines))
        u_items = [i for i, it in enumerate(items) if it["u"] == u]
        for i in u_items:
            if any(k in keys for k in items[i]["keys"]) or items[i]["norm"] in names:
                matched.add(i)
        summary.append((u, len(u_items), len(keys), len(names)))
    cross_keys = sorted(k for k, f in by_key.items() if df_matched(f, cross=True))
    cross_names = sorted(k for k, f in by_name.items() if df_matched(f, cross=True))
    for i, it in enumerate(items):
        if any(k in cross_keys for k in it["keys"]) or it["norm"] in cross_names:
            matched.add(i)
    unmatched = []
    for i, it in enumerate(items):
        if i in matched:
            continue
        if it["words"] < 2 or it["norm"] in DF_STOP:
            reason = "single word or verdict value" if not it["keys"] else "record named once"
        else:
            f = by_name[it["norm"]]
            reason = ("produced and consumed in the same step only" if f["out"] and f["in"]
                      else "only produced" if f["out"] else "only consumed")
        unmatched.append((it["u"], it["page"], it["loc"], it["side"], reason, it["norm"], it["raw"]))
    tail = section("## Across universes", ["Records and artifacts produced in one universe and consumed in another."],
                   ["Record or artifact", "Produced by", "Consumed by"],
                   [([code_cell(k), s.locs(locs_of(by_key[k], "out")), s.locs(locs_of(by_key[k], "in"))], True)
                    for k in cross_keys] +
                   [([carry(k), s.locs(locs_of(by_name[k], "out")), s.locs(locs_of(by_name[k], "in"))], True)
                    for k in cross_names])
    return blocks, summary, tail, unmatched, len(items)


def data_flow_view(s: Surfaces) -> dict:
    blocks, summary, tail, unmatched, _n = data_flow(s)
    per_u = Counter(row[0] for row in unmatched)
    intro = ["Artifacts and records named in the ICOM tables and the Steps rows of the activity pages, with the "
             "pages and steps that produce and consume each. Matching is conservative: two items match when their "
             "names are equal after link markup, parentheticals, code-span marks, outer punctuation and a leading "
             "article are dropped and the name has two or more words, or when they name the same code span or file. "
             "A match needs a producer and a consumer at different places.", "",
             "| Universe | Items | Records matched | Artifacts matched | Items matched | Items unmatched |",
             "|---|---|---|---|---|---|"]
    intro += ["| %s | %d | %d | %d | %d | %d |" % (carry(s.cat.title(u)), n, k, a, n - per_u[u], per_u[u])
              for u, n, k, a in summary if n] + [""]
    return assemble_view(s, "data-flow", "Data flow", "Artifacts and records with the pages and steps that produce "
                         "and consume them, per universe", intro, blocks, tail)


# -- views: state ------------------------------------------------------------------------------------
STATE_LABEL = re.compile(r"`status: ?([a-z][a-z-]*)`")
STATE_PAIR = re.compile(r"`status: ?([a-z][a-z-]*)`\s*(?:(?:back\s+)?to\b|→)\s*`status: ?([a-z][a-z-]*)`")
STAGE_VALUE = re.compile(r"\bStage(?: field)?(?: set)?(?: to)? (\d{1,2}-[A-Z][A-Za-z]+)")


def state_steps(s: Surfaces, find, keep=lambda row: True, pair=None) -> list:
    """Per Steps row naming a state: (page, step key, input-side states, output-side states). The
    output side is the right of the shape cell's first arrow plus the Action cell."""
    shape, action = s.col("Steps", "Inputs → outputs (shape)", 3), s.col("Steps", "Action", 1)
    out = []
    for nid in sorted(s.view, key=s.cat.tree_order().get):
        for r in s.step_rows(s.view[nid]):
            if not keep(r):
                continue
            left, right = (r[shape].split("→", 1) + [""])[:2]
            moves = [(m.group(1), m.group(2)) for t in (right, r[action]) for m in (pair.finditer(t) if pair else ())]
            left_st, entered = [m[0] for m in moves], {m[1] for m in moves}
            ins = list(dict.fromkeys(find(left) + left_st))
            outs = [x for x in dict.fromkeys(find(right) + find(r[action])) if x not in left_st or x in entered]
            if ins or outs:
                out.append((nid, unspan(r[0]), ins, outs))
    return out


def state_machine(s: Surfaces, states: list, hits: list, heading: str, rule: str) -> list:
    rows = []
    for state in states:
        into, read = {}, {}
        for nid, slug, ins, outs in hits:
            if state in outs:
                add_loc(into, nid, slug)
            elif state in ins:
                add_loc(read, nid, slug)
        rows.append(([code_cell(state), s.locs(into), s.locs(read)], bool(into or read)))
    lines = section(heading, [rule], ["State", "Moved into by (output side)", "Read or gated on by (input side)"], rows)
    if not lines:
        return []
    trans = defaultdict(dict)
    for nid, slug, ins, outs in hits:
        for s1 in ins:
            for s2 in outs:
                if s1 != s2:
                    add_loc(trans[s1, s2], nid, slug)
    if trans:
        order = {state: i for i, state in enumerate(states)}
        keys = sorted(trans, key=lambda k: (order.get(k[0], 99), order.get(k[1], 99)))
        sid = lambda state: "s_" + re.sub(r"\W", "_", state.lower())      # noqa: E731
        lines += ["Transitions a single step states, from a state on its input side to another on its output side:", "",
                  "| From | To | Moved by |", "|---|---|---|"]
        lines += ["| %s | %s | %s |" % (code_cell(a), code_cell(b), s.locs(trans[a, b])) for a, b in keys]
        lines += ["", "```mermaid", "flowchart LR"]
        lines += ["    %s([%s]) --> %s([%s])" % (sid(a), a, sid(b), b) for a, b in keys] + ["```", ""]
    return lines


def state_view(s: Surfaces) -> dict:
    cat = s.cat
    lines = []
    wi = state_steps(s, STATE_LABEL.findall, pair=STATE_PAIR)
    wi_states = sorted({x for _n, _k, i, o in wi for x in i + o}, key=lambda x: (-sum(x in o for *_r, o in wi), x))
    lines += state_machine(s, wi_states, wi, "## Work item — status labels",
                           "Case key: the work item. States: every `status: <label>` code span in a Steps row, "
                           "ordered by how many rows move a case into them.")
    stream = cat.pack.get("views", {}).get("state", {}).get("stage_stream", "")
    if stream and stream in s.view:
        stages = [n for n in cat.children(stream)]
        sset, pairs = set(stages), defaultdict(set)
        for n in stages:
            page = s.view.get(n)
            for t in (page.items("precedes") if page else []):
                if t in sset:
                    pairs[n, t].add("`precedes` on %s" % n)
            for t in (page.items("triggered_by") if page else []):
                if t in sset:
                    pairs[t, n].add("`triggered_by` on %s" % n)

        def kind_of(f, t):
            nxt = any(d.startswith("`precedes`") for d in pairs[f, t])
            back = (t, f) in pairs and any(d.startswith("`precedes`") for d in pairs[t, f])
            return ("loop" if back else "next") if nxt else ("return" if back else "trigger")
        keys = sorted((k for k in pairs if pairs[k]), key=lambda k: (cat.order[k[0]], cat.order[k[1]]))
        stage_lines = section("## Release — stages",
                              ["Case key: the release. States: the sub-processes of %s; a transition is a "
                               "`precedes` or `triggered_by` link between two of them." % s.plink(stream)],
                              ["From stage", "To stage", "Kind", "Declared by", "Pages"],
                              [([f, t, kind_of(f, t), "; ".join(sorted(pairs[f, t])), s.plink(f) + " · " + s.plink(t)],
                                True) for f, t in keys])
        if stage_lines:
            sid = lambda n: "st_" + re.sub(r"\W", "_", n)      # noqa: E731
            stage_lines += ["```mermaid", "flowchart LR"]
            stage_lines += ["    %s[%s] %s %s[%s]" % (sid(f), f, "-.->" if kind_of(f, t) == "return" else "-->",
                                                    sid(t), t) for f, t in keys] + ["```", ""]
        hits = [h for h in state_steps(s, STAGE_VALUE.findall)
                if stream in (cat.parent_of(h[0]), cat.parent_of(cat.parent_of(h[0]) or ""))]
        values = sorted({v for *_r, o in hits for v in o}, key=lambda v: (int(v.split("-")[0]), v))
        rows = []
        for v in values:
            locs = {}
            for nid, slug, _ins, outs in hits:
                if v in outs:
                    add_loc(locs, nid, slug)
            rows.append(([code_cell(v), s.locs(locs)], True))
        lines += stage_lines + section("### Stage values the steps set", [], ["Stage value", "Set by"], rows)
    agent_states = list(cat.pack["enums"].get("agent_state", []))
    if agent_states:
        agent_re = re.compile(r"\b(" + "|".join(map(re.escape, agent_states)) + r")\b")
        hits = state_steps(s, agent_re.findall)
        lines += state_machine(s, agent_states, hits, "## Project — agent state",
                               "Case key: the project. States: the pack's agent states, as the Steps rows name them.")
    page_states = list(cat.pack["enums"]["status"])
    pl_re = re.compile(r"\bstatus: ?(" + "|".join(map(re.escape, page_states)) + r")\b")
    pl = state_steps(s, pl_re.findall)
    counts = Counter(p.status for p in cat.published.values())
    rows = []
    for state in page_states:
        locs = {}
        for nid, slug, _ins, outs in pl:
            if state in outs:
                add_loc(locs, nid, slug)
        rows.append(([code_cell(state), str(counts.get(state, 0)), s.locs(locs)], bool(counts.get(state, 0) or locs)))
    lines += section("## Process page — lifecycle",
                     ["Case key: the page ID. States: the pack's page `status` values, with the pages in each state "
                      "now and the Steps rows that name a page state as a `status:` value."],
                     ["State", "Pages now", "Moved into by"], rows)
    if not lines:
        return {}
    head = [generated_header("State", "The state machines the pages describe, with the pages and steps that move "
                             "each transition, and the page lifecycle"), "# State", "",
            "Each machine is read from the pages' Steps rows: a state a row names on the right of its shape cell's "
            "arrow, or in its Action cell, is one the step moves the case into, and a state on the left only is one "
            "it reads or gates on.", ""]
    text = "\n".join(head + lines)
    if split_weight(text) > VIEW_SPLIT_WEIGHT:
        cat.warn("%s/state.md is over the view split weight" % VIEWS_FOLDER)
    return {"state.md": text}


# -- views: structure ----------------------------------------------------------------------------------
def structure_view(s: Surfaces) -> dict:
    """Per published universe: element kind, depicted file, pages. It lists depicted files only, so
    it changes only when a page's `depicts` changes."""
    cat, order = s.cat, kind_order(s.cat.kinds)
    blocks = []
    for u in s.universes():
        by_file = defaultdict(list)
        for nid in sorted((p for p in s.view if cat.universe(p) == u), key=cat.tree_order().get):
            for f in cat.sources(s.view[nid])["depicts"]:
                by_file[f].append(nid)
        rows = sorted(((classify_path(f, cat.kinds), f) for f in by_file), key=lambda r: (order.index(r[0]), r[1]))
        blocks.append((u, section("### Depicted files", [], ["Element kind", "Depicted file", "Pages"],
                                  [([kind, code_cell(f), " · ".join(s.plink(n) for n in by_file[f])], True)
                                   for kind, f in rows])))
    intro = ["The repository files the pages depict, by element kind, with the pages that depict each. A file no "
             "page depicts is not listed here; the generator's `coverage` command reports those.", ""]
    return assemble_view(s, "structure", "Structure", "Depicted files by element kind, with the pages that depict "
                         "them, per universe", intro, blocks)


# -- the expected set, and what is unexpected ----------------------------------------------------------
def unexpected_files(cat: Catalog, generated: set) -> list:
    """Repository-relative paths under the catalog root that nothing expects, among tracked files and
    untracked files that are not ignored. Expected: the catalog README, every file under the
    definitions folder, each discovered page, and each generated file. One function decides this for
    the generator's orphan rule and for the validator's catalog-level rules."""
    root = cat.roots.catalog_rel
    present = set(cat.tracked.under(root)) | set(untracked_files(cat.roots.repo, root))
    expected = {"%s/%s" % (root, README_NAME)} | {"%s/%s" % (root, g) for g in generated}
    expected |= {p.rel for p in cat.pages.values()}
    reserved = "%s/%s/" % (root, RESERVED_FOLDERS[0])
    return sorted(p for p in present if p not in expected and not p.startswith(reserved)
                  and os.path.exists(os.path.join(str(cat.roots.repo), p)))


# ----------------------------------------------------------------------------------------------
# The census and the summary block. Every command prints one census line as the last line on
# standard output, on exit 0, 1 and 3 alike; a usage exit prints none. Tokens are separated by one
# space, each is `key=value` with no space inside, and key names and their order are fixed.
# ----------------------------------------------------------------------------------------------
def census(gate: str, code: int, pairs: list) -> str:
    return "process-catalog %s status=%s exit=%d %s" % (
        gate, STATUS_WORD[code], code, " ".join("%s=%s" % (k, "NA" if v is None else v) for k, v in pairs))


def write_summary(path, gate: str, status: str, examined: str, body: list) -> None:
    """Append one block to a summary file; do nothing when no path was given. The option changes
    no output stream and no exit."""
    if not path:
        return
    block = ["### Process catalog — %s: %s" % (gate, status), "", "Examined: %s" % examined, ""] + list(body) + [""]
    with open(path, "a", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(block) + "\n")


SUMMARY_STATUS = {EXIT_CLEAN: "PASS", EXIT_FINDINGS: "FAIL", EXIT_NOT_EVALUATED: "NOT EVALUATED"}


# ----------------------------------------------------------------------------------------------
# Self-test support, shared by the four self-tests. A self-test builds a temporary repository
# from the fixture tree and from nothing else: no arm reads a file of the surrounding repository,
# its history or its configuration. The only things shared with it are the tool's sibling modules.
# ----------------------------------------------------------------------------------------------
FIXTURE_DIR = HERE.joinpath(*Path(default_part("fixtures")).parts[-2:])
TEST_IDENTITY = ("-c", "user.name=Fixture Author", "-c", "user.email=fixture-author.invalid",
                 "-c", "commit.gpgsign=false", "-c", "tag.gpgsign=false", "-c", "init.defaultBranch=trunk",
                 "-c", "core.hooksPath=" + os.devnull)


class Arms:
    """Counts self-test arms and prints the self-test census."""

    def __init__(self):
        self.count, self.failed = 0, []

    def check(self, label: str, ok, detail="") -> bool:
        self.count += 1
        if not ok:
            self.failed.append(label)
            print("SELF-TEST FAIL: %s%s" % (label, (" — %s" % (detail,)) if detail != "" else ""))
        return bool(ok)

    def raises(self, label: str, call, needle: str = "") -> bool:
        try:
            call()
        except NotEvaluated as e:
            return self.check(label, needle in str(e), "stopped, without naming %r: %s" % (needle, e))
        return self.check(label, False, "did not stop as not evaluated")

    def finish(self) -> int:
        code = EXIT_FINDINGS if self.failed else EXIT_CLEAN
        print("SELF-TEST %s" % ("FAIL" if self.failed else "PASS"))
        print(census("self-test", code, [("arms", self.count), ("failed", len(self.failed))]))
        return code


def isolate_git(home) -> None:
    """Make every later git call of this process, and of its children, independent of the machine's
    git configuration: the user-level and system-level files are nulled and the home folder points
    at the temporary folder. Identity, signing, branch name and hooks path go on each command line."""
    os.environ.update({"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_SYSTEM": os.devnull,
                       "GIT_CONFIG_NOSYSTEM": "1", "HOME": str(home), "GIT_TERMINAL_PROMPT": "0"})
    for name in location_vars():
        os.environ.pop(name, None)


def test_git(repo, *args) -> bytes:
    return git(repo, *(TEST_IDENTITY + args))


def commit_all(repo, message: str) -> str:
    test_git(repo, "add", "-A")
    test_git(repo, "commit", "-q", "--allow-empty", "-m", message)
    return git(repo, "rev-parse", "HEAD").decode("ascii").strip()


UNSTAMPED_COMMIT = "0" * 40
FIXTURE_UNIVERSE = "fixture-landscape"


class FixtureRepo:
    def __init__(self, repo: Path, layout: dict):
        self.repo, self.layout, self.base = repo, layout, UNSTAMPED_COMMIT
        self.catalog = repo / layout["catalog"]
        self.definitions = repo / layout["definitions"]
        self.args = ["--repo", str(repo), "--catalog-root", str(self.catalog), "--definitions", str(self.definitions),
                     "--pack-document", str(self.definitions / layout["pack_document"])]
        self.register_args = ["--fixture-root", layout["fixtures"], "--probe-source", layout["probe_source"]]

    def page(self, nid: str) -> Path:
        return next(self.catalog.glob("*/%s.md" % nid))

    def stamp(self, text: str) -> str:
        """A fixture page names no commit of its own: its verification commit is the temporary
        repository's first commit, written in when the page is placed."""
        return text.replace(UNSTAMPED_COMMIT, self.base)

    def fail_page(self, nid: str) -> Path:
        """Place one failing fixture page in the fixture universe's folder and return its path."""
        text = fixture_text("pages/fail/%s.md.txt" % nid)
        if self.layout != default_layout():
            text = text.replace(default_layout()["sources"] + "/", self.layout["sources"] + "/")
        path = self.catalog / FIXTURE_UNIVERSE / (nid + ".md")
        write_text(path, self.stamp(text))
        return path

    def roots(self) -> Roots:
        import argparse
        a = argparse.Namespace(root_repo=str(self.repo), root_catalog=str(self.catalog),
                               root_definitions=str(self.definitions),
                               root_pack_document=str(self.definitions / self.layout["pack_document"]),
                               root_fixtures=None, root_probe_source=None)
        roots = resolve_roots(a)
        roots.fixtures, roots.probe_source = self.layout["fixtures"], self.layout["probe_source"]
        return roots


def default_layout() -> dict:
    """The fixture tree at its own path, so the fixture registers are fixture registers and every
    fixture source sits where the fixture rows and pages name it."""
    fixtures = default_part("fixtures")
    workflows = Path(default_part("probe_source")).parent.as_posix()
    return {"catalog": default_part("catalog"), "definitions": fixtures, "fixtures": fixtures,
            "sources": fixtures + "/sources", "workflows": workflows, "pack_document": "definitions-pack.md.txt",
            "probe_source": workflows + "/probe-source.yml"}


def build_fixture_repo(dest: Path, layout=None, pages: bool = True, commit: bool = True) -> FixtureRepo:
    """The one function that builds a self-test's temporary repository from the fixture tree. Each
    pass page is written into its universe's folder with the `.txt` ending removed; each file under
    the fixture `workflows/` folder, and the fixture probe source, is written to the workflows folder
    with `.txt` removed. Under another layout the fixture tree's own prefix is rewritten in every
    text file, so the register and the pages name the sources where that layout puts them."""
    layout = dict(layout or default_layout())
    native = default_layout()
    moved = layout != native
    dest.mkdir(parents=True, exist_ok=True)

    def text_of(path: Path) -> str:
        text = path.read_text(encoding="utf-8")
        return text.replace(native["sources"] + "/", layout["sources"] + "/") if moved else text

    registry = {}
    for line in (FIXTURE_DIR / default_part("registry")).read_text(encoding="utf-8").split("\n")[1:]:
        cells = line.split("\t")
        if len(cells) >= 3:
            registry[cells[0]] = cells[2]
    if moved:
        for name in (default_part("pack"), default_part("registry"), default_part("kinds"), "controls-register.tsv"):
            write_text(dest / layout["definitions"] / name, text_of(FIXTURE_DIR / name))
        write_text(dest / layout["definitions"] / layout["pack_document"], text_of(FIXTURE_DIR / native["pack_document"]))
    else:
        for path in sorted(FIXTURE_DIR.rglob("*")):
            if path.is_file():
                write_text(dest / layout["fixtures"] / path.relative_to(FIXTURE_DIR).as_posix(),
                           path.read_text(encoding="utf-8"))
    if moved:
        for path in sorted((FIXTURE_DIR / "sources").glob("*")):
            write_text(dest / layout["sources"] / path.name, text_of(path))
    write_text(dest / layout["probe_source"], text_of(FIXTURE_DIR / "probe-source.yml.txt"))
    extra = FIXTURE_DIR / "workflows"
    if extra.is_dir():
        for path in sorted(extra.glob("*.txt")):
            write_text(dest / layout["workflows"] / path.name[:-4], text_of(path))
    (dest / layout["catalog"]).mkdir(parents=True, exist_ok=True)
    git(dest, *(TEST_IDENTITY + ("init", "-q")))
    fx = FixtureRepo(dest, layout)
    fx.base = commit_all(dest, "fixture sources")
    if pages:
        for path in sorted((FIXTURE_DIR / "pages" / "pass").glob("*.md.txt")):
            nid = path.name[:-len(".md.txt")]
            write_text(dest / layout["catalog"] / registry[nid] / (nid + ".md"), fx.stamp(text_of(path)))
        if commit:
            commit_all(dest, "fixture pages")
    return fx


TOOL_FILES = ("_process_catalog.py", "_frontmatter.py", LINK_CHECKER, "check-count-structure.py",
              "check-process-catalog.py", GENERATOR, "build-element-inventory.py")


def relocate_tools(dest: Path) -> Path:
    """Copy the catalog tools and their sibling modules to a folder — for the relocation arms, one
    outside any repository."""
    dest.mkdir(parents=True, exist_ok=True)
    for name in TOOL_FILES:
        if (HERE / name).is_file():
            shutil.copy2(HERE / name, dest / name)
    return dest


def relocated_layout() -> dict:
    """A fixture repository that shares no top-level folder name with this one. It keeps the
    definitions folder's own file names, so a root derived from a passed parent can be omitted."""
    return {"catalog": "book", "definitions": "book/" + default_part("definitions"), "fixtures": "spare",
            "sources": "stuff/sources", "workflows": "flows", "pack_document": default_part("pack_document"),
            "probe_source": "flows/probe-source.yml"}


def fixture_text(relative: str) -> str:
    return (FIXTURE_DIR / relative).read_text(encoding="utf-8")


# ----------------------------------------------------------------------------------------------
# The library's own self-test
# ----------------------------------------------------------------------------------------------
def _self_test() -> int:
    global GIT_CLEARS_LOCATION
    arms = Arms()
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(os.path.realpath(td))
        isolate_git(tmp)

        # -- the defaults table --
        names = [row[0] for row in DEFAULTS]
        arms.check("defaults: every parent is an earlier row",
                   all(row[1] is None or row[1] in names[:i] for i, row in enumerate(DEFAULTS)))
        arms.check("defaults: one argument per row, none repeated", len({row[3] for row in DEFAULTS}) == len(DEFAULTS))
        arms.check("defaults: the fixture folder beside this file is the fixtures row's last two segments",
                   FIXTURE_DIR.as_posix().endswith(default_part("fixtures").split("/", 3)[-1]) and FIXTURE_DIR.is_dir())

        # -- the citation grammar: every state --
        fp = fingerprint("alpha line")
        cases = [
            ("anchored", "[a](/x/y.txt#L3)%s" % anchor_text(3, None, fp), ["anchored"]),
            ("anchored span", "[a](/x/y.txt#L3-L5)%s" % anchor_text(3, 5, fp), ["anchored"]),
            ("bare", "see [a](/x/y.txt#L3) here", ["bare"]),
            ("line mismatch", "[a](/x/y.txt#L3)%s" % anchor_text(4, None, fp), ["line-mismatch"]),
            ("anchor after a space", "[a](/x/y.txt#L3) %s" % anchor_text(3, None, fp), ["bare", "malformed"]),
            ("anchor that does not parse", "[a](/x/y.txt#L3)<!-- source-anchor: line=3 fp=%s -->" % fp,
             ["bare", "malformed"]),
            ("anchor after a whole-file link", "[a](/x/y.txt)%s" % anchor_text(3, None, fp), ["malformed"]),
            ("fragment on a relative link", "[a](y.txt#L3)", ["malformed"]),
            ("a span that runs backwards", "[a](/x/y.txt#L5-L3)", ["malformed"]),
            ("a code-span label is a citation", "[`a`](/x/y.txt#L3)", ["bare"]),
            ("a link inside a code span is not", "`[a](/x/y.txt#L3)`", []),
            ("a whole-file link is no line citation", "[a](/x/y.txt)", []),
        ]
        for label, text, want in cases:
            got = [c.state for c in find_citations([(0, mask_link_spans(text))])]
            arms.check("grammar: " + label, got == want, got)
        fenced = ["```", "[a](/x/y.txt#L3)", "```", "~~~", "[a](/x/y.txt#L3)", "~~~", "> ```", "> [a](/x/y.txt#L3)",
                  "> ```", "[a](/x/y.txt#L3)"]
        flags = fence_flags(fenced)
        got = find_citations([(i, "" if flags[i] else l) for i, l in enumerate(fenced)])
        arms.check("grammar: a backtick fence, a tilde fence and a quoted fence are masked as the link checker "
                   "masks them", [c.line for c in got] == [9], [c.line for c in got])
        arms.check("grammar: the written anchor is the frozen form",
                   anchor_text(3, 5, "0123456789abcdef") == "<!-- source-anchor: line=3-5; fp=0123456789abcdef -->"
                   and fragment_text(3, 5) == "#L3-L5" and fragment_text(3, None) == "#L3")

        # -- the fingerprint, against the sibling tool that keys its baseline on the same digest --
        try:
            other = sibling("check-count-structure.py").sha1_preamble
            samples = ["plain text", "  re-indented\n\ttext  with   runs ", "ünïcode — text", ""]
            arms.check("fingerprint: equals the sibling content key on %d samples" % len(samples),
                       all(fingerprint(x) == other(x) for x in samples))
        except (NotEvaluated, AttributeError) as e:
            arms.check("fingerprint: the sibling content key could be loaded", False, e)
        arms.check("fingerprint: re-indenting keeps it and a changed word changes it",
                   fingerprint("a  b\n c") == fingerprint("a b c") != fingerprint("a b d"))

        # -- line numbering, against the shared link checker --
        counter = sibling(LINK_CHECKER).line_count
        for label, data in (("a trailing line feed", b"a\nb\n"), ("no trailing line feed", b"a\nb"),
                            ("an empty file", b""), ("carriage returns", b"a\r\nb\r\n")):
            probe = tmp / "count.txt"
            probe.write_bytes(data)
            arms.check("lines: %s numbers as the link checker counts" % label, len(source_lines(data)) == counter(probe))
        arms.check("lines: a trailing carriage return is removed", source_lines(b"a\r\nb\r\n") == ["a", "b"])
        arms.check("lines: bytes that are not UTF-8, and a NUL byte, are not text",
                   source_lines(b"\xff\xfe") is None and source_lines(b"a\0b") is None)

        # -- re-resolution states --
        src = ["one", "two", "", "three", "two"]
        mk = lambda a, b, text: Citation(a=a, b=b, fp=fingerprint(text), state="anchored")   # noqa: E731
        arms.check("resolve: current", resolve_citation(mk(1, None, "one"), src) == ("current", None))
        arms.check("resolve: moved", resolve_citation(mk(2, None, "three"), src) == ("moved", 4))
        arms.check("resolve: gone", resolve_citation(mk(1, None, "absent"), src) == ("gone", None))
        arms.check("resolve: ambiguous, the recorded line among the places",
                   resolve_citation(mk(2, None, "two"), src) == ("ambiguous", None))
        arms.check("resolve: a span, moved", resolve_citation(mk(1, 2, "three\ntwo"), src) == ("moved", 4))
        arms.check("resolve: a span that ends on a blank line", resolve_citation(mk(2, 3, "two\n"), src)[0] == "blank-edge")
        arms.check("resolve: a file that is not text", resolve_citation(mk(1, None, "one"), None) == ("not-text", None))

        # -- table and code-span helpers --
        pipe_cases = {"| a | `x | y` |": 1, "| a | `x \\| y` |": 0, "| a | ``x | y`` |": 1, "| a | b | c |": 0,
                      "| a | `open | no close |": 0, "| a | \\`x | y\\` |": 0}
        arms.check("tables: unescaped pipes inside code spans are counted",
                   all(code_span_pipes(k) == v for k, v in pipe_cases.items()),
                   {k: code_span_pipes(k) for k in pipe_cases})
        arms.check("tables: a pipe in a code span and an escaped pipe do not split a row",
                   split_row("| a | `x | y` | b \\| c |") == ["a", "`x | y`", "b \\| c"])
        arms.check("tables: an inline list parses and a block value does not",
                   parse_inline_list("[a, b]") == ["a", "b"] and parse_inline_list("") is None
                   and parse_inline_list("[]") == [])

        # -- the pack: shape, and unknown keys at nine places --
        good = json.loads(fixture_text(default_part("pack")))
        pack_path = tmp / "pack.json"

        def pack_with(change):
            pack = json.loads(json.dumps(good))
            change(pack)
            pack_path.write_text(json.dumps(pack), encoding="utf-8")
            return lambda: load_pack(pack_path)

        arms.check("pack: the fixture pack loads", bool(pack_with(lambda p: None)()))
        level0 = good["enums"]["level"][0]
        unknown = {
            "the top level": lambda p: p.update(extra=1),
            "id": lambda p: p["id"].update(extra=1),
            "levels": lambda p: p["levels"].update(extra=p["levels"][level0]),
            "a level object": lambda p: p["levels"][level0].update(extra=1),
            "enums": lambda p: p["enums"].update(extra=["x"]),
            "summary_counts": lambda p: p["summary_counts"].update(extra=1),
            "controls_register_rules": lambda p: p["controls_register_rules"].update(extra=1),
            "views": lambda p: p.update(views={"extra": {}}),
            "views.state": lambda p: p.update(views={"state": {"extra": 1}}),
        }
        for where, change in unknown.items():
            arms.raises("pack: an unknown key at %s stops the load" % where, pack_with(change), "extra")
        arms.check("pack: the two optional keys are admitted (the near-miss)",
                   bool(pack_with(lambda p: (p.update(views={"state": {"stage_stream": "x"}}),
                                             p["enums"].update(agent_state=["A"])))()))
        for key in PACK_KEYS:
            arms.raises("pack: a missing %s stops the load" % key, pack_with(lambda p, k=key: p.pop(k)), key)
        arms.raises("pack: a missing highest minted ID stops the load",
                    pack_with(lambda p: p["controls_register_rules"].pop("highest_minted_id")), "highest_minted_id")
        arms.raises("pack: a malformed highest minted ID stops the load",
                    pack_with(lambda p: p["controls_register_rules"].update(highest_minted_id="451")),
                    "highest_minted_id")
        arms.raises("pack: a repeated list entry stops the load",
                    pack_with(lambda p: p["harness_features"].append(p["harness_features"][0])), "harness_features")
        arms.raises("pack: a summary section that is not a required section stops the load",
                    pack_with(lambda p: p["summary_counts"].update(section="No such section")), "summary_counts")
        pack_path.write_text("{not json", encoding="utf-8")
        arms.raises("pack: text that is not JSON stops the load", lambda: load_pack(pack_path), "JSON")
        pack_path.write_bytes(b"\xff\xfe")
        arms.raises("pack: bytes that are not UTF-8 stop the load", lambda: load_pack(pack_path), "UTF-8")
        arms.raises("pack: an absent file stops the load", lambda: load_pack(tmp / "absent.json"), "pack")
        for bad in ("/abs/x.tsv", "~/x.tsv", "../x.tsv", "a/../x.tsv", "a\\x.tsv", ""):
            arms.raises("pointer: %r is refused" % bad, lambda b=bad: check_pointer(b, "controls_register"),
                        "controls_register")
        arms.check("pointer: a plain file name resolves beside the pack",
                   controls_register_path({"controls_register": "r.tsv"}, tmp / "d" / "pack.json") == tmp / "d" / "r.tsv")

        # -- the kinds table and the register tables --
        kinds_path = tmp / "kinds.tsv"
        kinds_path.write_text("kind\tpattern\nfirst\t^a/\nsecond\t^a/b\n", encoding="utf-8")
        kinds = load_kinds(kinds_path)
        arms.check("kinds: the first matching row wins and an unmatched path is `other`",
                   classify_path("a/b/c", kinds) == "first" and classify_path("z", kinds) == "other"
                   and kind_order(kinds) == ["first", "second", "other"])
        for label, body in (("a wrong header", "x\ty\na\tb\n"), ("a pattern that does not compile", "kind\tpattern\na\t(\n"),
                            ("no row", "kind\tpattern\n"), ("a short row", "kind\tpattern\nonly\n")):
            kinds_path.write_text(body, encoding="utf-8")
            arms.raises("kinds: %s stops the load" % label, lambda: load_kinds(kinds_path), "element-kinds")
        table = tmp / "t.tsv"
        for label, body in (("a wrong header", "a\tb\tc\n1\t2\t3\n"), ("a short row", "a\tb\n1\n"), ("no row", "a\tb\n")):
            table.write_text(body, encoding="utf-8")
            arms.raises("register table: %s stops the load" % label, lambda: load_table(table, ["a", "b"], "the table"),
                        "the table")
        arms.raises("register table: an empty file stops the load",
                    lambda: (table.write_text("", encoding="utf-8"), load_table(table, ["a", "b"], "the table")),
                    "the table")

        # -- register rules: data from the pack --
        rules = json.loads(json.dumps(good["controls_register_rules"]))
        held, minted = configure_register_rules(rules)
        arms.check("register rules: held numbers and the minted value come from the pack key",
                   held == parse_ranges(rules["held_ids"]) and minted == parse_minted(rules["highest_minted_id"]))
        arms.check("register rules: the class grammar is built from the pack's classes",
                   bool(CLASS_CELL.match(rules["classes"][0])) and not CLASS_CELL.match("no-such-class")
                   and bool(CLASS_CELL.match("%s (a note) / %s" % (rules["classes"][0], rules["classes"][-1]))))
        rules["kinds"] = rules["kinds"] + ["kind-with-no-surface"]
        arms.raises("register rules: a pack kind with no surface mapping stops the load",
                    lambda: configure_register_rules(rules), "kind-with-no-surface")
        configure_register_rules(good["controls_register_rules"])

        # -- the git wrapper, and the source set, in two scratch repositories --
        first, second = tmp / "first", tmp / "second"
        for repo, files in ((first, {"src/a.txt": "a\n", "src/deep/b.txt": "b\n", "book/u/p.md": "x\n",
                                     "book/definitions/pack.json": "{}\n", "top.txt": "t\n"}),
                            (second, {"only-here.txt": "x\n"})):
            for rel, body in files.items():
                write_text(repo / rel, body)
            git(repo, *(TEST_IDENTITY + ("init", "-q")))
            commit_all(repo, "scratch")
        arms.check("git: the location list holds the three variables a caller is most likely to set",
                   {"GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"} <= set(location_vars()))
        clean = Tracked(first).files
        decoys = {"GIT_DIR": str(second / ".git"), "GIT_WORK_TREE": str(second),
                  "GIT_INDEX_FILE": str(second / ".git" / "index")}
        for name, value in list(decoys.items()) + [("all three", None)]:
            patch = decoys if value is None else {name: value}
            os.environ.update(patch)
            try:
                arms.check("git: a decoy %s does not re-root a read" % name, Tracked(first).files == clean)
                if name in ("GIT_DIR", "all three"):
                    GIT_CLEARS_LOCATION = False
                    try:
                        moved = Tracked(first).files != clean
                    except NotEvaluated:
                        moved = True
                    finally:
                        GIT_CLEARS_LOCATION = True
                    arms.check("git: with the wrapper's clearing switched off, the decoy %s moves the read "
                               "(the control)" % name, moved)
            finally:
                for key in patch:
                    os.environ.pop(key, None)
        arms.raises("git: a failed call is not evaluated", lambda: git(first, "rev-parse", "no-such-ref^{commit}"), "git")
        tracked = Tracked(first)
        arms.check("source set: a folder is expanded from the path list",
                   expand_entries(["src/"], tracked, "book") == ["src/a.txt", "src/deep/b.txt"])
        arms.check("source set: a file stands for itself, and so does a path that is not tracked",
                   expand_entries(["top.txt", "gone/x.txt"], tracked, "book") == ["top.txt", "gone/x.txt"])
        arms.check("source set: no catalog file is a member, by the folder, a file in it or a folder above it",
                   expand_entries(["book", "book/u/p.md", "book/definitions/pack.json", ""], tracked, "book")
                   == ["src/a.txt", "src/deep/b.txt", "top.txt"])
        page_path = first / "book" / "u" / "p.md"
        page_path.write_text("---\nid: p\ndepicts: [src/a.txt]\n---\nBody [`label`](/top.txt) and `[x](/src/deep/b.txt)` "
                             "and [pack](/book/definitions/pack.json).\n", encoding="utf-8")
        import argparse
        roots = resolve_roots(argparse.Namespace(root_repo=str(first), root_catalog=str(first / "book")))
        page = load_page(page_path, roots)
        got = source_set(page, tracked, "book")
        arms.check("source set: a root link with a code-span label is a member; a link written inside a code span, "
                   "and a link into the catalog, are not", got == {"depicts": ["src/a.txt"], "cites": ["top.txt"]}, got)

        # -- roots --
        arms.check("roots: a default follows its parent",
                   roots.pack == first / "book" / default_part("definitions") / default_part("pack")
                   and roots.catalog_rel == "book" and roots.fixtures == default_part("fixtures"))
        arms.raises("roots: a repository root that is not a work tree's top level is named",
                    lambda: resolve_roots(argparse.Namespace(root_repo=str(first / "src"))), "--repo")
        arms.raises("roots: a catalog root the repository does not hold is named",
                    lambda: resolve_roots(argparse.Namespace(root_repo=str(first), root_catalog=str(first / "none"))),
                    "--catalog-root")

        # -- split parity with the shared reader --
        for mark in ("\x0c", " ", "\r"):
            body = "---\nfirst: a" + mark + "second: b\n---\nthird: c\n"
            page_path.write_bytes(body.encode("utf-8"))
            page = load_page(page_path, roots)
            arms.check("pages: the block ends where the reader ends it across %r" % mark,
                       page.fm_end == 3 and page.get("second") == "b" and "third" not in page.fm, (page.fm_end, page.fm))
        page_path.write_bytes(b"\xff\xfe not text")
        arms.raises("pages: a page that is not UTF-8 is not evaluated, naming the file",
                    lambda: load_page(page_path, roots), "book/u/p.md")

        # -- the census and the summary block --
        line = census("citations", EXIT_NOT_EVALUATED, [("pages", None), ("citations", 0)])
        arms.check("census: fixed form, one space between tokens, NA for a value that could not be read",
                   line == "process-catalog citations status=not-evaluated exit=3 pages=NA citations=0", line)
        summary = tmp / "summary.md"
        write_summary(None, "x", "PASS", "nothing", [])
        write_summary(summary, "citations", "FAIL", "2 pages", ["a line"])
        write_summary(summary, "citations", "PASS", "2 pages", [])
        arms.check("summary: a block is appended, and no path writes nothing",
                   summary.read_text(encoding="utf-8").count("### Process catalog — citations") == 2)

        # -- the fixture builder --
        fx = build_fixture_repo(tmp / "fx")
        fixtures_part = default_part("fixtures")
        arms.check("fixture repository: the fixture tree sits at its own path and pages sit in their universe",
                   (fx.repo / fixtures_part / default_part("pack")).is_file() and bool(list(fx.catalog.glob("*/*.md")))
                   and (fx.repo / fx.layout["probe_source"]).is_file())
        stamped = fx.page("fixture-activity-plain").read_text(encoding="utf-8")
        arms.check("fixture repository: each page names the repository's first commit as its verification commit",
                   fx.base in stamped and UNSTAMPED_COMMIT not in stamped and len(fx.base) == 40)
        arms.check("fixture repository: its checkout is clean",
                   git(fx.repo, "status", "--porcelain", "--untracked-files=all", "--ignored") == b"")
    return arms.finish()


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        try:
            sys.exit(_self_test())
        except NotEvaluated as e:
            print("NOT EVALUATED: %s" % e)
            print(census("self-test", EXIT_NOT_EVALUATED, [("arms", None), ("failed", None)]))
            sys.exit(EXIT_NOT_EVALUATED)
    print("usage: _process_catalog.py --self-test", file=sys.stderr)
    sys.exit(EXIT_USAGE)
