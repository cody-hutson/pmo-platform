#!/usr/bin/env python3
# check-process-catalog-publication.py
"""Publication gate for process-catalog text (Pre-Landing Contract: PL-3, PL-4, PL-9, PL-13; Addenda PLA and PLB).

`probe` counts the gated classes and review lists over files on disk or over blobs of a commit, and writes the pins.
`preflight` proves that a clone cannot push and commits under the pinned identity. `scan` is the Pack Contract's one
scan definition (S-1 to S-10): every commit of a range, each against its parent, for the term lists and the
identity. `shape` says whether a commit changes line values only. `gate`
checks one unpushed commit end to end: it reads every scanned byte from the commit's own objects, runs the catalog
tools in a detached checkout of that commit, takes every expected number from the pins, and writes one record that
ends with its own digest. Writes nothing but --record-out and --write-pins, and temporary folders it removes; with
--tmp-dir those folders are made under the directory the caller names.
Every private input is an argument; no private name, folder, title or term is typed in this file. `--self-test` builds
its own scratch repositories from synthetic text and reads no input of the caller's.
Standard output never prints the hash or the byte size of an input: those go to the record file only.
Exit 0 clean - 1 a gated class or a row failed - 2 usage - 3 not-evaluated (an input did not load, a pin differs or
is unsound, a denominator is wrong, a file is not text, or a tool could not be run)."""
import argparse, collections, contextlib, hashlib, io, json, os, re, shutil, subprocess, sys, tempfile

CATALOG = "core/process-catalog"
DEFS = CATALOG + "/definitions"
PACK = DEFS + "/pack.json"
REGISTERS = (DEFS + "/controls-register.tsv", DEFS + "/id-registry.tsv")
LISTS = (("effort", "effort-term"), ("hub", "hub-term"), ("added", "added-term"), ("page", "page-term"))
SELF = "core/deploy/tools/check-process-catalog-publication.py"
TOOL_TREES = ("core/deploy/tools", "release/tools", "core/hooks/lib")   # every file a G-9 row runs, imports or sources
GUARD = "core/hooks/git-pre-commit-pii.sh"
CLASS_WORDS = "code-enforce|code-warn|code-off|prose-only|host-config|not-a-control|tacit"
DROPPED = "mode_source|observed_here|firing_evidence|minted_at|minted_by"
LINK = re.compile(r"\[([^\]\n]*)\]\(([^)\s]+)\)")
ANCHOR = re.compile(r"<!--\s*source-anchor:.*?--!?>", re.DOTALL)   # a comment ends at either end form; read per line
ANCHOR_LINE = re.compile(r"(<!-- source-anchor: line=)[0-9]+(?:-[0-9]+)?(; fp=[0-9a-f]{16} -->)")   # the Tool Contract's grammar
FRAGMENT = re.compile(r"(\]\(/[^)#\s]+#L)[0-9]+(?:-L[0-9]+)?(\))")
LTOK = re.compile(r"(?<![A-Za-z0-9_#/])L(\d+)(?:\s*[–\-]\s*L?(\d+))?(?![A-Za-z0-9_])")
LWORD = re.compile(r"(?i)\blines? \d+|\.[A-Za-z]{1,8}:\d+\b")
PATHTOK = re.compile(r"(?<![A-Za-z0-9_.\-/>}])[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+/?")
NAME = re.compile(r"(?<![A-Za-z0-9_.\-/])[A-Za-z0-9_\-][A-Za-z0-9_.\-]*\.[A-Za-z][A-Za-z0-9]*(?![A-Za-z0-9_/])")
INSTANCE = re.compile(r"(?i)\b(?:(?:on )?this install|this instance|this machine|this workspace|live read|live mode|"
                      r"live value|mode file reads|as observed|observed (?:on|in|at|here)|at (?:this|its) read|fired here)\b")
HERE = re.compile(r"(?i)\bhere\b")
COVERAGE = re.compile(r"(?i)\bno (?:register |controls-register )?row (?:for|of|in)\b|\bcarr(?:y|ies) no row\b|\bno register row\b|"
                      r"\b\d[\d,]* register rows\b|\bnot in the (?:controls )?register\b|"
                      r"\bcontrols register (?:has|holds|carries|lists|omits|misses|does not)\b")
HOSTSTATE = re.compile(r"(?i)\bbranch[- ]protection\b|\brequired (?:check|context|status)\b|\b(?:not |un)?registered\b|\bnot (?:a )?required\b")
FIGURE = re.compile(r"\b\d{1,3}(?:,\d{3})+\b|(?i:(?<![\w\-])\d[\d,]*\s+(?:times|firings?|runs?|sessions?|tokens?|blocks?|hits?|events?|occurrences?)\b)")
IDRANGE = re.compile(r"\bC-(\d{3,})\s*(?:to|through|\.\.|–|-)\s*C-(\d{3,})\b")
DATE = re.compile(r"\b(?:19|20)\d\d-\d\d-\d\d\b")
DIGIT = re.compile(r"\d")
FENCE = "`" * 3
# What may stand between the words of a literal, on load and on read alike: white space (a line break included), a
# hyphen, an underscore, a slash, a dot, an en dash, a percent-encoded space, an emphasis mark - any run of them, or none.
JOINER = r"(?:[\s_\-/.*–]|%20)"
JOIN, SPLIT = JOINER + "*", JOINER + "+"
WRITTEN = ("  ", "-", "_", "\n", "", "/", ".", "–", "%20", "* *", "** **")   # each is tried on load, with both cases
SIGNED = ("G",)                                            # the one signature state that counts as signed
BOUND_ROW = re.compile(r"^([0-9]+)\t(\S.*)$")              # an outside-bounds row: <added lines><tab><path>
# A frontmatter line is left to the whole-file classes only when its value has the shape its key promises.
FM_SHAPE = re.compile(r"(?:level:\s*L[0-3]|last_verified_commit:\s*[0-9a-f]{40}|pack_version:\s*[0-9]+)\s*")
GATED = ["ws-name", "ws-path", "untracked-root-link", "unlinked-source", "line-label", "line-prose", "install-wording",
         "here-in-table", "effort-term", "hub-term", "register-coverage", "dropped-column", "bracketed-class", "held-id",
         "old-title", "added-term", "page-term", "unparsed"]
REVIEW = ["host-state", "figure-outside-executed", "date-outside-executed", "grounded-name", "newly-tracked-name",
          "basename-source", "numeral-lines"]
LISTED = ("effort-term", "hub-term", "added-term", "page-term")   # may be pinned at 0 only when every expression matched
PROVEN_ELSEWHERE = ("unparsed",)                           # 0 on the drafted pages by nature; its arm is the self-test
# By kind of file, the gated classes that are review lists there. A generated view names sources as code spans and may
# count the register rows it shows. The catalog README states rules: it may name a held range, a dropped column or a
# phrase a page may not use, so only the six disclosure classes are gated on it. `other` is the added lines of a
# changed file outside the catalog: every class is gated there.
MODE_REVIEW = {"page": (), "other": (), "generated": ("register-coverage", "unlinked-source"),
               "readme": ("unlinked-source", "line-label", "line-prose", "install-wording", "here-in-table", "register-coverage",
                          "dropped-column", "bracketed-class", "held-id")}


class NotEvaluated(Exception):
    pass


def git(repo, *args, text=True):
    env = {k: v for k, v in os.environ.items() if k not in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")}
    try:
        return subprocess.run(["git", "-C", repo] + list(args), capture_output=True, text=text, check=True, env=env).stdout
    except (OSError, subprocess.CalledProcessError) as e:
        raise NotEvaluated("git %s failed (%s)" % (args[0], type(e).__name__))


def git_rc(repo, *args):
    env = {k: v for k, v in os.environ.items() if k not in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")}
    r = subprocess.run(["git", "-C", repo] + list(args), capture_output=True, text=True, env=env)
    return r.returncode, r.stdout


def tool_env(extra):
    """The environment a tool row runs in: the caller's, less every variable git lists as naming a repository's
    location, so a tool in the detached checkout reads that checkout and nothing else."""
    try:
        names = subprocess.run(["git", "rev-parse", "--local-env-vars"], capture_output=True, text=True, check=True,
                               cwd=tempfile.gettempdir(), env={k: v for k, v in os.environ.items() if not k.startswith("GIT_")}).stdout.split()
    except (OSError, subprocess.CalledProcessError) as e:
        raise NotEvaluated("git could not list its repository-location variables (%s)" % type(e).__name__)
    if not names:
        raise NotEvaluated("git listed no repository-location variable")
    return dict({k: v for k, v in os.environ.items() if k not in names}, **extra)


_signature_reader = None       # replaced in-process by the self-test alone; no option and no variable reaches it


def signature_state(repo, commit):
    """The signature state of a commit as git reports it: one letter, `G` for a good signature, `N` for none."""
    if _signature_reader is not None:
        return _signature_reader(repo, commit)
    return git_rc(repo, "show", "-s", "--format=%G?", commit)[1].strip() or "?"


def scratch_dir(a, prefix):
    """A temporary folder of this tool's own, removed by its maker: under the caller's directory when one is named."""
    base = getattr(a, "tmp_dir", None)
    if base is not None and not os.path.isdir(base):
        raise NotEvaluated("--tmp-dir does not name a directory")
    return tempfile.mkdtemp(prefix=prefix, dir=os.path.abspath(base) if base is not None else None)


def added_lines(repo, old, new, path):
    """The lines a commit adds to one path, read from the hunks of its diff against `old`."""
    out, hunk = [], False
    for x in git(repo, "diff", "--no-renames", "-U0", old, new, "--", path).split("\n"):
        if x.startswith("@@"):
            hunk = True
        elif hunk and x.startswith("+"):
            out.append(x[1:])
    return out


def sha(data):
    return hashlib.sha256(data if isinstance(data, bytes) else data.encode("utf-8")).hexdigest()


class Tree:
    """The tracked names of one commit, and its blobs on demand."""
    def __init__(self, repo, rev):
        self.repo, self.rev = repo, git(repo, "rev-parse", "--verify", rev + "^{commit}").strip()
        self.modes = {l.split("\t", 1)[1]: l.split(" ", 1)[0] for l in git(repo, "ls-tree", "-r", "-z", self.rev).split("\0") if l}
        self.files = set(self.modes)
        if not self.files:
            raise NotEvaluated("no tracked file at %s" % rev)
        self.dirs = {"/".join(f.split("/")[:i]) for f in self.files for i in range(1, f.count("/") + 1)}
        self.bases = collections.defaultdict(list)
        for f in self.files:
            self.bases[os.path.basename(f)].append(f)
        self._raw = {}

    def raw(self, path):
        if path not in self._raw:
            try:
                self._raw[path] = git(self.repo, "show", "%s:%s" % (self.rev, path), text=False)
            except NotEvaluated:
                raise NotEvaluated("%s could not be read at the commit" % path)   # a failed read is never an empty file
        return self._raw[path]

    def blob(self, path, strict=True):
        """Text of a file at the commit. A scanned entry that is not a regular file, is not UTF-8 text or holds a NUL
        byte is not evaluated, never read as empty."""
        if strict and (self.modes.get(path) not in ("100644", "100755") or b"\0" in self.raw(path)):
            raise NotEvaluated("%s is not a regular text file at the commit" % path)
        try:
            return self.raw(path).decode("utf-8")
        except UnicodeDecodeError:
            if strict:
                raise NotEvaluated("%s is not text at the commit" % path)
            return self.raw(path).decode("utf-8", "replace")

    def under(self, path):
        path = path.strip("/")
        return {path} if path in self.files else {f for f in self.files if f.startswith(path + "/")}

    def tree_id(self, path):
        rc, out = git_rc(self.repo, "rev-parse", "--verify", "--quiet", "%s:%s" % (self.rev, path))
        return out.strip() if rc == 0 else ""


def read_lines(path, what):
    try:
        raw = open(path, "rb").read()
        return raw, [l.strip() for l in raw.decode("utf-8").split("\n")]
    except (OSError, UnicodeDecodeError) as e:
        raise NotEvaluated("%s could not be read (%s)" % (what, type(e).__name__))


def variants(words):
    """The ways one literal gets written: both cases, then every joiner of WRITTEN between its words."""
    return [" ".join(words).lower(), " ".join(words).upper()] + [j.join(words) for j in WRITTEN]


def terms(path, what):
    """One entry per line, and no line is dropped unseen. `lit:<words>` is a literal: matched in any case, with any
    run of the JOINER characters (or none) between its words; the same characters part its words on load.
    `re:<expression>` is a Python `re` expression, matched in any case. `# ` begins a comment. Any other non-empty
    line stops the run, and so does a line that holds a line separator the reader did not split on."""
    raw, lines = read_lines(path, what)
    pats, lits, comments, blank = [], [], 0, 0
    for i, l in enumerate(lines, 1):
        if not l:
            blank += 1
        elif len(l.splitlines()) != 1:
            raise NotEvaluated("%s line %d holds a line separator: it would be read as one entry" % (what, i))
        elif l == "#" or l.startswith("# "):
            comments += 1
        elif l.startswith("lit:"):
            words = [w for w in re.split(SPLIT, l[4:]) if w]
            if not words:
                raise NotEvaluated("%s line %d is an empty literal" % (what, i))
            lits.append((words, re.compile(JOIN.join(re.escape(w) for w in words), re.I)))
            pats.append(lits[-1][1])
        elif l.startswith("re:"):
            try:
                pats.append(re.compile(l[3:].strip(), re.I))
            except re.error:
                raise NotEvaluated("%s line %d does not compile" % (what, i))
        else:
            raise NotEvaluated("%s line %d is not `lit:`, `re:` or a `# ` comment" % (what, i))
    if not pats or any(p.search("") for p in pats):
        raise NotEvaluated("%s: no expression, or one that matches the empty string" % what)
    tried = [(p, v) for words, p in lits for v in variants(words)]
    if any(not p.search(v) for p, v in tried):
        raise NotEvaluated("%s: a literal does not match one of its own written forms" % what)
    return raw, pats, {"lines": len(lines), "expressions": len(pats), "literals": len(lits), "comments": comments,
                       "blank": blank, "variants_matched": len(tried)}


def one_line(path, what):
    raw, _ = read_lines(path, what)
    v = raw.decode("utf-8").strip("\n")
    if not v.strip() or "\n" in v:
        raise NotEvaluated("%s must hold exactly one non-empty line" % what)
    return raw, v


def identity(path):
    raw, lines = read_lines(path, "the identity file")
    vals = [l for l in lines if l]
    if len(vals) != 2:
        raise NotEvaluated("the identity file must hold a name line and an address line")
    return raw, tuple(vals)


def held(specs):
    out = set()
    for s in specs:
        m = re.match(r"^C-(\d+)(?:\.\.C-(\d+))?$", s.strip())
        if not m:
            raise NotEvaluated("a held range is malformed")
        out.update(range(int(m.group(1)), int(m.group(2) or m.group(1)) + 1))
    if not out:
        raise NotEvaluated("no held range")
    return out


def load_inputs(a, tree, ground=None, lists_only=False):
    """Every private input, with its digest. The digests go to the record and the pins, never to standard output."""
    ctx, dig = {"tree": tree, "ground": ground or tree, "matched": collections.Counter(), "lists": {}}, {}
    dig["tool"] = sha(read_lines(os.path.abspath(__file__), "this tool's own file")[0])
    raw, ctx["effort"], ctx["lists"]["effort"] = terms(a.effort_terms, "the effort list")
    dig["effort"] = sha(raw)
    # `hub`: read on whole content everywhere. `added`: whole content of a file the release adds, added lines of a
    # file that pre-dates it (the Pack Contract's S-4). `page`: gated on pages only, net of the old title (PA-10).
    for key, files in (("hub", a.hub_terms), ("added", getattr(a, "added_terms", None) or []), ("page", getattr(a, "page_terms", None) or [])):
        ctx[key] = []
        for i, f in enumerate(files):
            raw, pats, ctx["lists"]["%s-%d" % (key, i + 1)] = terms(f, "%s term list %d" % (key, i + 1))
            dig["%s-%d" % (key, i + 1)] = sha(raw)
            ctx[key] += pats
    ctx["every"] = ctx["effort"] + ctx["hub"] + ctx["added"] + ctx["page"]
    raw, ctx["old_title"] = one_line(a.old_title_file, "the old-title file")
    dig["old-title"] = sha(raw)
    raw, ctx["new_title"] = one_line(a.new_title_file, "the new-title file")
    dig["new-title"] = sha(raw)
    words = [w for w in re.split(r"[^A-Za-z0-9]+", ctx["old_title"]) if w]
    if not words:
        raise NotEvaluated("the old title holds no word")
    # the old title in any case and spacing: its first two words together, or its one word
    ctx["title"] = re.compile(r"(?i)(?<![A-Za-z0-9])%s(?![A-Za-z0-9])" % JOIN.join(re.escape(w) for w in words[:2]))
    ctx["title_whole"] = re.compile("(?i)" + JOIN.join(re.escape(w) for w in words))
    if ctx["title"].search(ctx["new_title"]):
        raise NotEvaluated("the new title would be read as the old one")
    if getattr(a, "identity_file", None):
        raw, ctx["identity"] = identity(a.identity_file)
        dig["identity"] = sha(raw)
    if lists_only:
        return ctx, dig
    raw, lines = read_lines(a.listing, "the working-set listing")
    wfiles = {l for l in lines if l}
    if not wfiles:
        raise NotEvaluated("the working-set listing is empty")
    dig["listing"] = sha(raw)
    ctx["wfiles"] = wfiles
    ctx["wdirs"] = {"/".join(f.split("/")[:i]) for f in wfiles for i in range(1, f.count("/") + 1)}
    ctx["wbases"] = {os.path.basename(f) for f in wfiles}
    # A listing name that no file tracked at the ground commit carries is read in any case: one expression per
    # lower-case form, so two listing names that differ by case alone count one mention once.
    ctx["wnames"] = [(k, re.compile(r"(?i)(?<![A-Za-z0-9_])" + re.escape(k) + r"(?![A-Za-z0-9_])"))
                     for k in sorted({b.lower() for b in ctx["wbases"] - set(ctx["ground"].bases)})]
    if getattr(a, "held", None):
        ctx["held"], dig["held"] = held(a.held), sha(",".join(sorted(a.held)))
    else:
        if PACK not in tree.files:
            raise NotEvaluated("no --held was given and the commit carries no pack")
        ranges = json.loads(tree.blob(PACK))["controls_register_rules"]["held_ids"]
        ctx["held"], dig["held"] = held(ranges), sha(",".join(sorted(ranges)))
    return ctx, dig


def split(text):
    """(frontmatter lines or None, [(section, line, kind)], fence markers) - kind is 'fm', 'fence' or 'body'.
    No line is dropped: a fence-marker line is read as a fenced line, and a frontmatter line is skipped only when
    its whole value has the shape its key promises."""
    lines = text.split("\n")
    fm, out, start, markers = None, [], 0, 0
    if lines and lines[0] == "---" and "---" in lines[1:]:
        end = lines.index("---", 1)
        fm, start = lines[1:end], end + 1
    out += [("", l, "fm") for l in fm or [] if not FM_SHAPE.fullmatch(l)]
    section, fence = "", False
    for l in lines[start:]:
        if l.startswith(FENCE):
            fence, markers = not fence, markers + 1
            out.append((section, l, "fence"))
            continue
        if not fence and l.startswith("## "):
            section = l[3:].strip()
        out.append((section, l, "fence" if fence else "body"))
    return fm, out, markers


def norm(token):
    return re.sub(r"^\./", "", token).rstrip("./")


def executed_row(section, line):
    if section != "Evidence" or not line.startswith("|"):
        return False
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    return bool(cells) and re.search(r"(?i)\bexecuted\b", cells[0]) is not None


def scan(text, ctx, mode="page"):
    tree, ground, n = ctx["tree"], ctx["ground"], collections.Counter()
    fm, rows, markers = split(text)
    # The source set a page declares: `depicts` (folders expanded) and root links, less every file at or under the
    # catalog root - filtered after expansion, so a link to the catalog, into it or above it adds no catalog file.
    dep = None
    for l in fm or []:
        if l.startswith("depicts:"):
            dep = {x.strip() for x in l.split(":", 1)[1].strip().strip("[]").split(",") if x.strip()}
    if mode == "page":
        n["unparsed"] += (fm is None) + (dep is None) + (markers % 2)
    body = "\n".join(l for _, l, k in rows if k == "body")
    linked = {m.group(2).split("#")[0].strip("/") for m in LINK.finditer(body) if m.group(2).startswith("/")}
    source = set()
    for p in (dep or set()) | linked:
        source |= tree.under(p)
    source = {f for f in source if not f.startswith(CATALOG + "/")}
    # ws-name: a listing name no tracked file carries as its name - whole file. A name is grounded only when a file of
    # the page's source set that was already tracked at the ground commit (the pushed base) carries it there as a
    # whole token: counted on its own review line, never dropped. A commit cannot ground a name by what it adds.
    # The name is read in any case. A mention whose own spelling is the name of a file tracked at the ground commit is
    # that file's name and is not counted; the two review lines are given only to the spelling the mention uses.
    carriers, low, seen = sorted(source & ground.files), text.lower(), {}
    for key, pat in ctx["wnames"]:
        if key not in low:
            continue
        for w in pat.findall(text):
            if w in ground.bases:
                continue
            if w not in seen:
                exact = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(w) + r"(?![A-Za-z0-9_])")
                seen[w] = "newly-tracked-name" if w in tree.bases else (            # the commit adds a file of this name
                    "grounded-name" if any(exact.search(ground.blob(f, strict=False)) for f in carriers) else "ws-name")
            n[seen[w]] += 1
    untracked = ctx["wbases"] - set(tree.bases)
    for m in PATHTOK.finditer(text):
        t = norm(m.group(0))
        if t in tree.files or t in tree.dirs or os.path.basename(t) in untracked:
            continue
        if t in ctx["wfiles"] or any(t == d or t.startswith(d + "/") or ("/" + t).endswith("/" + d) for d in ctx["wdirs"] if "/" in d):
            n["ws-path"] += 1
    nolink = LINK.sub(" ", body)
    named = {norm(m.group(0)) for m in PATHTOK.finditer(nolink)} & tree.files
    if dep is not None:                                    # a page; a generated file declares no `depicts`
        n["unlinked-source"] += len(named - source)
        for b in {m.group(0) for m in NAME.finditer(PATHTOK.sub(" ", nolink))}:
            if b in tree.bases and not set(tree.bases[b]) & source:
                n["basename-source"] += 1                  # a tracked file named by base name, outside the source set
    for section, line, kind in rows:
        if kind == "body":
            for lm in LINK.finditer(line):
                label, target = lm.group(1), lm.group(2).split("#")[0].strip("/")
                if lm.group(2).startswith("/"):
                    n["untracked-root-link"] += target not in tree.files and target not in tree.dirs
                    n["line-label"] += len(LTOK.findall(label)) + len(LWORD.findall(label))
        rest = ANCHOR.sub(" ", LINK.sub(lambda m: " " * (len(m.group(0)) - 1) + "`", line))
        for m in LTOK.finditer(rest):
            a, b = int(m.group(1)), m.group(2)
            if not (a <= 3 and b is None and not re.search(r"`\s*$", rest[:m.start()])):
                n["line-prose"] += 1
        n["line-prose"] += len(LWORD.findall(rest))
        n["install-wording"] += len(INSTANCE.findall(line))
        if line.startswith("|"):
            n["here-in-table"] += len(HERE.findall(line))
        n["register-coverage"] += len(COVERAGE.findall(line))
        n["dropped-column"] += len(re.findall(r"(?<![A-Za-z0-9_])(?:%s)(?![A-Za-z0-9_])" % DROPPED, line))
        n["bracketed-class"] += len(re.findall(r"<(?:%s)>" % CLASS_WORDS, line))
        spans = [(int(a), int(b)) for a, b in IDRANGE.findall(line)]
        n["held-id"] += sum(1 for a, b in spans if b - a < 500 and ctx["held"] & set(range(a, b + 1)))
        n["held-id"] += sum(1 for x in re.findall(r"\bC-(\d{3,})\b", IDRANGE.sub(" ", line)) if int(x) in ctx["held"])
        n["host-state"] += len(HOSTSTATE.findall(line))
        if not executed_row(section, line):
            n["figure-outside-executed"] += len(FIGURE.findall(line))
            n["date-outside-executed"] += len(DATE.findall(LINK.sub(" ", line)))
            n["numeral-lines"] += bool(DIGIT.search(ANCHOR.sub(" ", LINK.sub(lambda m: m.group(1), line))))
    net = ctx["title_whole"].sub(" ", text)                # a page list is counted on what is left without the old title
    for key, cls in LISTS:
        if (key == "added" and mode == "readme") or (key == "page" and mode != "page"):
            continue                                       # the README pre-dates the release: G-7 reads its added lines
        for p in ctx[key]:
            c = len(p.findall(net if key == "page" else text))
            n[cls] += c
            ctx["matched"][p] += c
    n["old-title"] += len(ctx["title"].findall(text))
    n["new-title-heading"] += sum(1 for l in text.split("\n") if l == "## " + ctx["new_title"])
    n["old-title-heading"] += sum(1 for l in text.split("\n") if l.startswith("## ") and ctx["title"].search(l))
    return n


def run_probe(texts, ctx, mode, out, by_file=False):
    """texts: {name: text}. Returns (counts per class, lines examined, bad)."""
    per = {t: scan(x, ctx, mode) for t, x in sorted(texts.items())}
    total = collections.Counter()
    for c in per.values():
        total.update(c)
    lines = sum(x.count("\n") + (not x.endswith("\n") and bool(x)) for x in texts.values())
    gated = [k for k in GATED if k not in MODE_REVIEW[mode]]
    review = REVIEW + [k for k in GATED if k not in gated]
    out("examined: %d files, %d lines, %d bytes" % (len(texts), lines, sum(len(x.encode("utf-8")) for x in texts.values())))
    for kind, keys in (("gated  ", gated), ("review ", review)):
        for k in keys:
            out("%s %-24s %5d on %2d files" % (kind, k, total[k], sum(1 for c in per.values() if c[k])))
    for key, _ in LISTS:
        out("terms   %s lists: %d of %d expressions matched at least once" % (key, sum(1 for p in ctx[key] if ctx["matched"][p]), len(ctx[key])))
    out("title   old headings %d on %d files; new headings %d on %d files" % (
        total["old-title-heading"], sum(1 for c in per.values() if c["old-title-heading"]),
        total["new-title-heading"], sum(1 for c in per.values() if c["new-title-heading"])))
    if by_file:
        out("file\tlines\t" + "\t".join(GATED + REVIEW))
        for t, c in per.items():
            out("%s\t%d\t%s" % (os.path.splitext(os.path.basename(t))[0], texts[t].count("\n"), "\t".join(str(c[k]) for k in GATED + REVIEW)))
    return {k: total[k] for k in GATED + REVIEW + ["old-title-heading", "new-title-heading"]}, lines, sum(total[k] for k in gated)


def list_lines(ctx, out):
    for name, s in sorted(ctx["lists"].items()):
        out("list    %s: lines=%d expressions=%d literals=%d comments=%d blank=%d variants_matched=%d" % (
            name, s["lines"], s["expressions"], s["literals"], s["comments"], s["blank"], s["variants_matched"]))


def disk_texts(paths):
    targets = []
    for p in paths:
        if os.path.isdir(p):
            for d, _, fs in os.walk(p):
                targets += [os.path.join(d, f) for f in sorted(fs) if f.endswith((".md", ".json"))]
        elif os.path.isfile(p):
            targets.append(p)
        else:
            raise NotEvaluated("a path given is not a file or folder")
    try:
        return {t: open(t, encoding="utf-8").read() for t in targets}
    except (OSError, UnicodeDecodeError) as e:
        raise NotEvaluated("a file could not be read (%s)" % type(e).__name__)


def rev_texts(tree, paths, suffixes=(".md", ".json")):
    out = {}
    for p in paths:
        hit = sorted(f for f in tree.under(p) if f.endswith(suffixes) or f == p.strip("/"))
        if not hit:
            raise NotEvaluated("%s holds no file at the commit" % p)
        out.update({f: tree.blob(f) for f in hit})
    return out


def term_only(paths, ctx):
    """Sensitivity files: read for the term lists alone, so that every expression can be shown to match."""
    for x in disk_texts(paths).values():
        for p in ctx["every"]:
            ctx["matched"][p] += len(p.findall(x))
    return sum(1 for p in ctx["every"] if not ctx["matched"][p])


def kind_of(path, universe):
    """Which class reads a path. `unread` is a path under the catalog that no class reads: it fails the gate."""
    if not path.startswith(CATALOG + "/"):
        return "outside"
    if path == CATALOG + "/README.md":
        return "readme"
    if path.startswith(CATALOG + "/" + universe + "/"):
        return "page" if path.endswith(".md") else "unread"
    if path.startswith(DEFS + "/"):
        return "definitions"
    return "generated" if path.endswith((".md", ".json")) else "unread"


def manifest_rows(path):
    raw, lines = read_lines(path, "the file-set manifest")
    rows = sorted(l for l in lines if l)
    if not rows or any(not re.match(r"^[AMD]\t\S", r) for r in rows):
        raise NotEvaluated("the manifest is empty or holds a line that is not `<A|M|D><tab><path>`")
    return "\n".join(rows), rows                           # the digest is of the sorted rows, not of the file's bytes


def load_pins(path):
    try:
        return json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError):
        raise NotEvaluated("the pins file could not be read")


def check_pins(pins, dig, skip=(), only=None):
    keys = (set(dig) | set(pins.get("inputs", {}))) - set(skip)
    diff = sorted(k for k in (keys if only is None else keys & set(only)) if dig.get(k) != pins.get("inputs", {}).get(k))
    if diff:
        raise NotEvaluated("inputs differ from the pins: %s" % ", ".join(diff))
    return pins


def sound(pins, gate=False, zero=True):
    """Pins that prove nothing are refused, whoever wrote them: a gated class pinned at 0 on the drafted pages, a
    count pinned at 0, or - for the gate - a missing section."""
    zero = zero and sorted(k for k in GATED if k not in LISTED + PROVEN_ELSEWHERE and not pins.get("drafted", {}).get(k))
    if zero:
        raise NotEvaluated("pinned at 0 on the drafted pages, so the sensitivity arm proves nothing: %s" % ", ".join(zero))
    if not gate:
        return
    exp = pins.get("expected", {})
    need = ("pages", "generated_files", "renamed", "register_rows", "registry_rows")
    if any(not isinstance(exp.get(k), int) or exp[k] < 1 for k in need) or not isinstance(exp.get("grounded_name"), int):
        raise NotEvaluated("the pins hold no expected count, or one that is 0")
    if not pins.get("manifests") or set(pins.get("tools", {})) != set(TOOL_TREES) or not all(pins["tools"].values()) \
            or not pins.get("definitions") or "identity" not in pins.get("inputs", {}):
        raise NotEvaluated("the pins are not gate pins: a manifest, a tool tree, the definitions tree or the identity is missing")
    bounds = pins.get("outside")
    if not re.fullmatch(r"[0-9a-f]{40,64}", str(pins.get("head", ""))) or not isinstance(bounds, dict) \
            or any(not isinstance(v, int) or v < 1 for v in bounds.values()) or not isinstance(pins.get("lineage"), str):
        raise NotEvaluated("the pins are not gate pins: the publication head, the outside bounds or the lineage is missing")
    if pins.get("head_signature") not in SIGNED:
        raise NotEvaluated("the pins were made on a publication head that is not signed (state %s): two unsigned commits "
                           "must never agree their way to a pass" % (pins.get("head_signature") or "absent"))


def outside_bounds(path):
    """The hub's bound on each edit outside the catalog: one `<added lines><tab><path>` row per path."""
    raw, lines = read_lines(path, "the outside-bounds file")
    rows = [BOUND_ROW.match(l) for l in lines if l]
    if not rows or not all(rows) or len({m.group(2) for m in rows}) != len(rows) or any(int(m.group(1)) < 1 for m in rows):
        raise NotEvaluated("the outside-bounds file is empty, repeats a path, or holds a line that is not `<added lines><tab><path>`")
    return {m.group(2): int(m.group(1)) for m in rows}


def reproduce(pins, counts, unmatched):
    bad = sorted(k for k, v in pins["drafted"].items() if counts.get(k) != v)
    if bad or unmatched:
        raise NotEvaluated("the sensitivity run does not reproduce the pins: %s; %d expression(s) matched nothing" % (", ".join(bad) or "-", unmatched))


def gate_pins(a, counts, files, old):
    """The sections the gate needs, each derived and none typed: the tool trees and the definitions tree (pack,
    registers and whatever else that folder holds) at the publication head, the manifests' digests, the counts. They
    also keep the publication head itself and its signature state, the hub's bound on each edit outside the catalog,
    and one line of lineage: whether these are first pins or a re-pin, and what moved."""
    if not a.identity_file or not a.manifest:
        raise NotEvaluated("gate pins need --identity-file and at least one --manifest")
    head = Tree(a.repo, a.head_rev)
    state = signature_state(a.repo, head.rev)
    if state not in SIGNED:
        raise NotEvaluated("the publication head is not signed (state %s): gate pins are refused on it" % state)
    tools = {d: head.tree_id(d) for d in TOOL_TREES}
    if not all(tools.values()) or SELF not in head.files:
        raise NotEvaluated("the publication head lacks a tool folder or this file")
    defs, rows = head.tree_id(DEFS), []
    for r in REGISTERS:
        if r not in head.files:
            raise NotEvaluated("the publication head carries no %s" % r)
        rows.append(len([l for l in head.blob(r).split("\n") if l.strip()]) - 1)
    digests, gen, outside = [], set(), set()
    for m in a.manifest:
        raw, mrows = manifest_rows(m)
        digests.append(sha(raw))
        outside |= {r.split("\t")[1] for r in mrows if r[0] != "D" and kind_of(r.split("\t")[1], a.universe) == "outside"}
        kinds = collections.Counter(kind_of(r.split("\t")[1], a.universe) for r in mrows if r[0] == "A")
        if kinds["page"]:
            if kinds["page"] != files:
                raise NotEvaluated("a manifest adds %d pages and %d drafted pages were read" % (kinds["page"], files))
            gen.add(kinds["generated"])
    exp = dict(old.get("expected", {})) if old else {}
    if gen:
        if len(gen) != 1:
            raise NotEvaluated("the manifests disagree on how many generated files are added")
        exp["generated_files"] = gen.pop()
    exp.update(pages=files, renamed=counts["old-title-heading"], register_rows=rows[0], registry_rows=rows[1],
               grounded_name=counts["grounded-name"] if a.ack_grounded is None else a.ack_grounded)
    # Each changed path outside the catalog is bounded: the hub states how many lines its edit adds, and the gate
    # fails a commit that adds any other number. A bound is carried through a re-pin; a path with none is refused.
    bounds, given = dict(old.get("outside", {})) if old else {}, outside_bounds(a.outside_bounds) if a.outside_bounds else {}
    bounds.update(given)
    if outside - set(bounds) or set(given) - outside:
        raise NotEvaluated("outside bounds: %d manifest path(s) outside the catalog have no bound; %d bound(s) name a path "
                           "no manifest of this run changes" % (len(outside - set(bounds)), len(set(given) - outside)))
    # The lineage is decided by what the head already tracks, not by the options: any pin run that is not the first
    # says so, and says what moved when earlier pins were named. The gate copies the line into its record.
    tracked = sum(1 for f in head.files if kind_of(f, a.universe) == "page")
    if old:
        lineage = ("re-pin: publication head moved: %s; tool folders that differ from the earlier pins: %d; definitions folder "
                   "differs: %s; manifests added: %d; pages tracked at the head: %d" % (
                       old.get("head") != head.rev, sum(1 for d in TOOL_TREES if old.get("tools", {}).get(d) != tools[d]),
                       old.get("definitions") != defs, len(set(digests) - set(old.get("manifests", []))), tracked))
    elif tracked:
        lineage = "re-pin: no earlier pins were named, so nothing is compared; pages tracked at the head: %d" % tracked
    else:
        lineage = "pin: first gate pins; pages tracked at the head: 0"
    print(lineage)
    return {"expected": exp, "tools": tools, "definitions": defs, "head": head.rev, "head_signature": state, "outside": bounds,
            "lineage": lineage, "generation": (old.get("generation", 0) if old else 0) + 1,
            "previous": sha(read_lines(a.pins, "the earlier pins")[0]) if old else "none",
            "manifests": sorted(set(digests) | set(old.get("manifests", []) if old else []))}


def cmd_probe(a):
    tree = Tree(a.repo, a.rev)
    ctx, dig = load_inputs(a, tree, Tree(a.repo, a.ground_rev) if a.ground_rev else None)
    texts = rev_texts(tree, a.paths) if a.at_rev else disk_texts(a.paths)
    if len(texts) != a.expect_files or a.expect_files < 1 or any(not x.strip() for x in texts.values()):
        raise NotEvaluated("examined %d files, expected %d (at least 1); or a file is empty" % (len(texts), a.expect_files))
    print("loaded: tracked names at %s: %d files" % (a.rev, len(tree.files)))
    list_lines(ctx, print)
    mode = "generated" if a.generated else ("readme" if a.readme else ("other" if a.other else "page"))
    counts, _, bad = run_probe(texts, ctx, mode, print, a.by_file)
    unmatched = term_only(a.sensitivity_file or [], ctx)
    state, old = "none", None
    if a.pins:
        old = check_pins(load_pins(a.pins), dig, tuple(k for k, absent in (("held", not a.held), ("identity", not a.identity_file)) if absent))
        sound(old)
        state = "match"
        if a.expect_drafted or a.write_pins:
            reproduce(old, counts, unmatched)
            state = "match; drafted counts reproduced; every expression matched"
    if a.write_pins:
        if mode != "page" or a.at_rev or unmatched:
            raise NotEvaluated("pins are written from the drafted pages on disk, with every expression matched (%d were not)" % unmatched)
        pins = {"inputs": dig, "drafted": counts}
        sound(pins)
        if a.head_rev:
            pins.update(gate_pins(a, counts, len(texts), old))
            sound(pins, gate=True)
        json.dump(pins, open(a.write_pins, "w", encoding="utf-8"), indent=1, sort_keys=True)
        state = "written (%s)" % ("gate pins" if a.head_rev else "probe pins")
    print("inputs: %d loaded; pins: %s; expressions that matched nothing: %d" % (len(dig), state, unmatched))
    if a.write_pins:                                       # the drafted pages must hold gated hits; writing pins is the success
        print("publication pins status=pass written=1 gated_total_on_drafted=%d files=%d" % (bad, len(texts)))
        return 0
    print("publication probes status=%s gated_total=%d files=%d" % ("pass" if not bad else "fail", bad, len(texts)))
    return 1 if bad else 0


def population(repo, commit, release, parent=None):
    """What one commit publishes (S-3, S-4), read from its own objects against its first parent. Per file it adds or
    changes: the whole text, and the text the added-line lists read - the whole text of a file the release adds, the
    added lines of a file that pre-dates the release, and for a merge only lines that stand in no parent. Plus the
    names of the paths it touches, and its message. Returns ({label: (whole, added)}, files listed, files read,
    identity). `listed` is counted from the commit's name list and `read` from the texts in hand, so the two can
    differ; a read that fails stops the run naming the file, and a file a parent does not hold is told apart from one
    that could not be read there."""
    tree = Tree(repo, commit)
    parents = git(repo, "rev-list", "--parents", "-n", "1", tree.rev).split()[1:]
    if not parents:
        raise NotEvaluated("%s has no parent" % tree.rev[:12])
    first = parent or parents[0]
    rows = [l.split("\t", 1) for l in git(repo, "diff", "--no-renames", "--name-status", first, tree.rev).split("\n") if l]
    listed = [p for s, p in rows if s[:1] in ("A", "C", "M", "T")]
    names = "\n".join(p for _, p in rows)
    olds = [Tree(repo, p) for p in parents] if len(parents) > 1 else []
    pop = {}
    for f in listed:
        whole = tree.blob(f)
        if olds:
            seen = set()
            for o in olds:
                if f in o.files:
                    seen |= set(o.blob(f).split("\n"))
            whole = added = "\n".join(l for l in whole.split("\n") if l not in seen)
        elif f in release.files:
            added = "\n".join(added_lines(repo, first, tree.rev, f))
        else:
            added = whole
        pop[f] = (whole, added)
    read = len(pop)
    pop["(path names)"] = (names, names)
    msg = git(repo, "show", "-s", "--format=%B", tree.rev)
    pop["(message)"] = (msg, msg)
    return pop, len(listed), read, tuple(git(repo, "show", "-s", "--format=%an%n%ae%n%cn%n%ce", tree.rev).split("\n")[:4])


def term_hits(pop, ctx, count=True):
    hits = 0
    for whole, added in pop.values():
        for key, x in (("effort", whole), ("hub", whole), ("added", added)):
            for p in ctx[key]:
                c = len(p.findall(x))
                hits += c
                if count:
                    ctx["matched"][p] += c
    return hits, sum(len(ctx["title"].findall(whole)) for whole, _ in pop.values())


def cmd_scan(a):
    """The Pack Contract's scan, S-1 to S-10. The range is every commit reachable from --head and from no --base."""
    ctx, dig = load_inputs(a, None, lists_only=True)
    # The pins are required: the control commit is made from the lists in hand, and proves those lists and no others.
    check_pins(load_pins(a.pins), dig, ("listing", "held") + tuple("page-%d" % i for i in range(1, 9)))
    list_lines(ctx, print)
    release = Tree(a.repo, a.release_base)
    lists = ctx["effort"] + ctx["hub"] + ctx["added"]
    # S-8: the control travels the read path the subject travels - a commit, read from its objects
    cpop, clisted, cread, _ = population(a.repo, a.control_commit, release)
    _, ctitle = term_hits(cpop, ctx)
    unmatched = sum(1 for p in lists if not ctx["matched"][p])
    print("control commit: files=%d listed=%d expressions matched=%d of %d title matched=%s" % (
        cread, clisted, len(lists) - unmatched, len(lists), bool(ctitle)))
    if unmatched or not ctitle or not cread or cread != clisted:
        raise NotEvaluated("the control commit does not carry every arm")
    # S-8's second range is required too, and a zero over it counts only when it holds text to read
    npop, nlisted, nread, _ = population(a.repo, a.near_miss_commit, release)
    hits, title = term_hits(npop, ctx, count=False)
    print("near-miss commit: files=%d listed=%d term_hits=%d title_hits=%d" % (nread, nlisted, hits, title))
    if not nread or nread != nlisted or not any(w.strip() for w, _ in list(npop.values())[:nread]):
        raise NotEvaluated("the near-miss commit holds no text: a zero over it proves nothing")
    if hits or title:
        raise NotEvaluated("the near-miss commit is counted: an expression over-matches")
    commits = [c for c in git(a.repo, "rev-list", "--reverse", a.head, "--not", *a.base).split("\n") if c]
    if not commits or (a.one_commit and len(commits) != 1):
        raise NotEvaluated("the range holds %d commit(s)%s" % (len(commits), "; exactly one is required" if a.one_commit else ""))
    total = files = listed = 0
    for c in commits:
        pop, nl, nr, who = population(a.repo, c, release)
        hits, title = term_hits(pop, ctx, count=False)
        same = who[:2] == ctx["identity"] and who[2:] == ctx["identity"]
        print("commit %s files=%d listed=%d term_hits=%d title_hits=%d identity_equal=%s" % (c[:12], nr, nl, hits, title, same))
        total, files, listed = total + hits + title + (not same), files + nr, listed + nl
    texts = a.text_file or []
    if texts:                                              # S-6: a branch name, a pull-request title, a pull-request body
        probe = collections.Counter()
        for f in a.sensitivity_file or []:
            x = read_lines(f, "a sensitivity file")[0].decode("utf-8")
            for p in lists + [ctx["title"]]:
                probe[p] += len(p.findall(x))
        if any(not probe[p] for p in lists + [ctx["title"]]):
            raise NotEvaluated("text files need a --sensitivity-file, read the same way, in which every expression and the title match")
        for f in texts:
            x = read_lines(f, "a text file")[0].decode("utf-8")
            if not x.strip():
                raise NotEvaluated("a text file is empty")
            hits, title = term_hits({f: (x, x)}, ctx, count=False)
            print("text %d term_hits=%d title_hits=%d" % (texts.index(f) + 1, hits, title))
            total += hits + title
    print("examined: commits=%d files=%d listed=%d texts=%d" % (len(commits), files, listed, len(texts)))
    if files != listed:                                    # S-7: read unequal to listed is never a count
        raise NotEvaluated("read %d of the %d files the range lists" % (files, listed))
    print("publication scan status=%s findings=%d" % ("pass" if not total else "fail", total))
    return 1 if total else 0


def cmd_preflight(a):
    """Is this clone one that cannot push, and does it commit under the pinned identity? Run by the hub after it makes
    the clone, and by each session from its own working directory before its first commit."""
    raw, want = identity(a.identity_file)
    if a.pins:
        check_pins(load_pins(a.pins), {"identity": sha(raw)}, only=["identity"])
    miss = []

    def line(name, ok, detail):
        print("%-4s preflight %s - %s" % ("PASS" if ok else "FAIL", name, detail))
        if not ok:
            miss.append(name)

    remotes = git(a.repo, "remote").split()
    line("no remote", not remotes, "remotes=%d" % len(remotes))
    rc, out = git_rc(a.repo, "config", "--get-regexp", r"^remote\.|^branch\..*\.(remote|merge)$|^url\.")
    line("no remote, branch-remote or url setting", rc == 1 and not out.strip(), "settings=%d" % len(out.split("\n")) if out.strip() else "settings=0")
    alt = os.path.join(git(a.repo, "rev-parse", "--path-format=absolute", "--git-common-dir").strip(), "objects", "info", "alternates")
    line("no alternates file", not os.path.exists(alt), "present=%s" % os.path.exists(alt))
    rc, out = git_rc(a.repo, "config", "--get", "core.hooksPath")
    line("no hook-path setting", rc == 1, "set=%s" % (rc == 0))
    hooks = git(a.repo, "rev-parse", "--path-format=absolute", "--git-path", "hooks").strip()
    push, pre = os.path.join(hooks, "pre-push"), os.path.join(hooks, "pre-commit")
    line("the pre-push hook is an executable file", os.path.isfile(push) and os.access(push, os.X_OK), "file=%s executable=%s" % (os.path.isfile(push), os.access(push, os.X_OK)))
    top = git(a.repo, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
    guard_ok = os.path.isfile(pre) and os.access(pre, os.X_OK) and os.path.realpath(pre).endswith("/" + GUARD) \
        and os.path.realpath(pre).startswith(os.path.dirname(os.path.realpath(top)) + "/")
    line("the commit-time guard is linked and executable", guard_ok, "linked=%s" % guard_ok)
    idents = [re.match(r"^(.*) <([^>]*)> ", git(a.repo, "var", v)) for v in ("GIT_AUTHOR_IDENT", "GIT_COMMITTER_IDENT")]
    same = all(m and (m.group(1), m.group(2)) == want for m in idents)
    line("author and committer are the pinned identity", same, "identity_equal=%s" % same)
    # A push that fails for a reason of its own is not a refusal. The check passes only when HEAD names a commit there
    # is to push, the hook itself - run as git runs it for this push - exits non-zero, and the push then delivers nothing.
    rc_head, head = git_rc(a.repo, "rev-parse", "--verify", "--quiet", "HEAD^{commit}")
    head_ok, head = rc_head == 0 and bool(head.strip()), head.strip()
    tmp = scratch_dir(a, "publication-preflight-")
    try:
        target = os.path.join(tmp, "target.git")
        git(tmp, "init", "--quiet", "--bare", target)
        refuses = False
        if head_ok and os.path.isfile(push) and os.access(push, os.X_OK):
            rc_top, top_dir = git_rc(a.repo, "rev-parse", "--show-toplevel")
            try:
                refuses = subprocess.run([push, target, target], input="HEAD %s refs/heads/preflight %s\n" % (head, "0" * len(head)),
                                         cwd=top_dir.strip() if rc_top == 0 and top_dir.strip() else a.repo, capture_output=True,
                                         text=True, timeout=120).returncode != 0
            except (OSError, subprocess.SubprocessError):
                refuses = False
        rc, _ = git_rc(a.repo, "push", target, "HEAD:refs/heads/preflight")
        refs = len([l for l in git(target, "for-each-ref").split("\n") if l])
        line("a push to an empty repository is refused", head_ok and refuses and rc != 0 and refs == 0,
             "head_names_a_commit=%s hook_refuses=%s exit_nonzero=%s refs_received=%d" % (head_ok, refuses, rc != 0, refs))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    rc, out = git_rc(a.repo, "config", "--get", "commit.gpgsign")
    print("info preflight commit signing setting present=%s" % (rc == 0))
    print("publication preflight status=%s checks=8 missed=%d" % ("pass" if not miss else "not-evaluated", len(miss)))
    return 3 if miss else 0


BUILD, CHECK = "core/deploy/tools/build-process-catalog.py", "core/deploy/tools/check-process-catalog.py"
CENSUS = r"(?m)^process-catalog %s status=pass exit=0 %s$"   # a catalog tool's closing line on a pass, whole, as built
REGISTER_ARM = {  # by declared mode: (the arguments the register check takes, the line it prints for the pattern arm)
    "run": (["--private-pattern-file", "{pattern}", "--pattern-digest-file", "{pattern_digest}"], r"(?m)^pattern arm: run, "),
    "not-run": ([], r"(?m)^pattern arm: NOT RUN \(declared\)"),
}


def tool_rows(arm):
    """(row, interpreter, argv, expressions that must each match the output); `{md}` expands to the changed Markdown
    files. The register check takes the pattern file and its digest together when the pattern arm runs, and neither
    when it is declared not run. Each catalog-tool expression is the tool's whole closing line, hyphenated as printed."""
    return [
        ("register invariant, pattern arm " + arm, "py", [CHECK, "--registers-only", "--pattern-arm", arm] + REGISTER_ARM[arm][0],
         [CENSUS % ("registers", r"register_rows={register_rows} registry_rows={registry_rows} pattern_arm=%s findings=0" % arm), REGISTER_ARM[arm][1],
          r"(?m)^register roots: catalog=core/process-catalog fixtures=core/deploy/tools/fixtures/process-catalog probe_source=\S+ held=\S+$"]),
        ("generated output", "py", [BUILD, "build", "--check"], [CENSUS % (
            "generated-output", r"universes=[0-9]+ pages={pages} generated_files={generated_files} differing=0 missing=0 orphans=0 link_findings=0")]),
        ("citations", "py", [BUILD, "anchors", "resolve", "--check"], [CENSUS % (
            "citations", r"pages={pages} citations=[0-9]+ current=[0-9]+ moved=[0-9]+ gone=[0-9]+ ambiguous=[0-9]+ other=[0-9]+ rewritten=[0-9]+")]),
        ("page validation", "py", [CHECK, "--pattern-arm", "not-run"], [CENSUS % (
            "page-validation", r"universes=[0-9]+ pages={pages} registry_rows={registry_rows} register_rows={register_rows} pattern_arm=not-run errors=0 warns=[0-9]+")]),
        ("staleness, depicted and cited", "py", [BUILD, "stale", "--fail-on", "any"], [CENSUS % (
            "staleness", r"pages={pages} sources=[0-9]+ depicted_changed=[0-9]+ cited_changed=[0-9]+ fail_on=any")]),
    ] + CHECKER_ROWS


CHECKER_ROWS = [
    ("close keywords in the commit message", "py", ["core/deploy/tools/check-commit-close-keywords.py", "--base", "{base}", "--head", "{commit}"],
     [r"commits examined: 1\b", r"findings: 0\b"]),
    ("links, whole changed files", "py", ["core/deploy/tools/check-doc-links.py", "--require-targets", "--target-paths", "{md_csv}"], [r"\A[^\n]*\n?\Z"]),
    ("links, added lines", "py", ["release/tools/check-release-links.py", "--roots", "core", "release", "docs", ".github", "--top-level-md",
                                  "--check-anchors", "--images", "--diff-base", "{base}", "--files", "{md}"], [r"=== 0 broken links across 0 files ==="]),
    ("issue references", "bash", ["core/deploy/tools/check-issue-ref-validity.sh", "--base", "{base}", "--head", "{commit}", "--resolver", "gh"],
     [r"Issue-reference validity — all #N in changed markdown resolve"]),
]


def cmd_gate(a):
    rec, fails, noteval = [], [], []

    def out(line):
        rec.append(line)
        if not line.startswith("digest "):
            print(line)

    def row(name, ok, detail, evaluated=True):
        out("%-13s %s - %s" % ("NOT-EVALUATED" if not evaluated else ("PASS" if ok else "FAIL"), name, detail))
        if not evaluated:
            noteval.append(name)
        elif not ok:
            fails.append(name)

    arm = a.pattern_arm                                    # declared, never inferred from a missing file
    tree = Tree(a.repo, a.commit)
    ground = Tree(a.repo, a.base)
    commit, base = tree.rev, ground.rev
    tree_id = git(a.repo, "rev-parse", commit + "^{tree}").strip()
    out("gate   commit=%s tree=%s base=%s" % (commit, tree_id, base))
    ctx, dig = load_inputs(a, tree, ground)
    for k in sorted(dig):
        out("digest %s sha256=%s" % (k, dig[k]))
    list_lines(ctx, out)
    msg_raw, _ = read_lines(a.message_file, "the commit-message file")
    out("digest message-file sha256=%s" % sha(msg_raw))
    for k, f in (("private-pattern-file", a.private_pattern_file), ("pattern-digest-file", a.pattern_digest_file)):
        if f:
            out("digest %s sha256=%s" % (k, sha(read_lines(f, "the " + k)[0])))
    out("digest pins-file sha256=%s" % sha(read_lines(a.pins, "the pins file")[0]))
    pins = check_pins(load_pins(a.pins), dig, ("held",))
    sound(pins, gate=True, zero=False)
    exp = pins["expected"]
    out("digest pins-previous sha256=%s" % pins.get("previous", "none"))
    out("pins   generation=%s %s" % (pins.get("generation", "?"), pins["lineage"]))
    out("pinned pages=%(pages)d generated_files=%(generated_files)d renamed=%(renamed)d register_rows=%(register_rows)d "
        "registry_rows=%(registry_rows)d grounded_name=%(grounded_name)d" % exp)
    out("pinned head=%s head_signature=%s outside_paths=%d outside_added_lines=%d pattern_arm=%s" % (
        pins["head"], pins["head_signature"], len(pins["outside"]), sum(pins["outside"].values()), arm))
    # G-1 one commit on the pinned publication head, the pinned file set, and a class for every path. The base is an
    # argument; the head the pins were written at is not. A base that is not that head fails the row, whatever it is.
    parents = git(a.repo, "rev-list", "--parents", "-n", "1", commit).split()[1:]
    ahead = git(a.repo, "rev-list", "--count", "%s..%s" % (base, commit)).strip()
    one = ahead == "1" and parents == [base] and base == pins["head"]
    row("G-1 one commit on the pinned publication head", one, "ahead=%s parents=%d parent_is_base=%s base_is_pinned_head=%s" % (
        ahead, len(parents), parents[:1] == [base], base == pins["head"]))
    out("parent %s %s" % ("one commit on" if one else "NOT one commit on", pins["head"]))
    status = sorted(l for l in git(a.repo, "diff", "--no-renames", "--name-status", base, commit).split("\n") if l)
    mraw, want = manifest_rows(a.manifest)
    out("digest manifest sha256=%s" % sha(mraw))
    pinned = sha(mraw) in pins["manifests"]
    row("G-1 the manifest is one the pins name", pinned, "pinned=%s" % pinned)
    row("G-1 the file set is the manifest", status == want, "paths=%d expected=%d differing=%d" % (len(status), len(want), len(set(status) ^ set(want))))
    kinds = collections.Counter(kind_of(l.split("\t")[1], a.universe) for l in status)
    intree = collections.Counter(kind_of(f, a.universe) for f in tree.files if f.startswith(CATALOG + "/"))
    row("G-1 every changed path, and every catalog file, is of a kind a class reads", not kinds["unread"] and not kinds["definitions"] and not intree["unread"],
        "pages=%d generated=%d readme=%d outside=%d definitions=%d unread=%d unread_in_tree=%d" % (
            kinds["page"], kinds["generated"], kinds["readme"], kinds["outside"], kinds["definitions"], kinds["unread"], intree["unread"]))
    # G-2 the gate, the tools it runs and the registers are the pinned ones
    same = SELF in tree.files and sha(tree.raw(SELF)) == dig["tool"]
    row("G-2 the commit carries this file, byte for byte, and the pins name it", same, "tracked=%s equal=%s" % (SELF in tree.files, same))
    moved = sorted(d for d in TOOL_TREES if tree.tree_id(d) != pins["tools"][d])
    row("G-2 the tool folders are the pinned trees", not moved, "folders=%d differing=%d" % (len(TOOL_TREES), len(moved)))
    for d in TOOL_TREES:                                   # the trees the tool rows below run from, by ID
        out("tools  %s tree=%s" % (d, tree.tree_id(d) or "absent"))
    defs_ok = tree.tree_id(DEFS) == pins["definitions"]
    row("G-2 the definitions folder - pack, registers, held ranges - is the pinned tree", defs_ok, "equal=%s" % defs_ok)
    # G-12 the commit's own identity
    who = git(a.repo, "show", "-s", "--format=%an%n%ae%n%cn%n%ce", commit).split("\n")[:4]
    ident_ok = tuple(who[:2]) == ctx["identity"] and tuple(who[2:]) == ctx["identity"]
    row("G-12 author and committer are the pinned identity", ident_ok, "identity_equal=%s" % ident_ok)
    # G-14 the commit's signature state. The pins were refused unless their head was signed, so equality means signed.
    state = signature_state(a.repo, commit)
    row("G-14 the commit's signature state is the pinned publication head's", state == pins["head_signature"],
        "state=%s pinned=%s" % (state, pins["head_signature"]))
    # G-3 sensitivity: the drafted pages, tracked names at the pinned commit, must reproduce the pins
    try:
        dtree = Tree(a.repo, a.drafted_rev)
        dctx, ddig = load_inputs(argparse.Namespace(**dict(vars(a), held=a.drafted_held)), dtree)
        check_pins(pins, ddig)
        sound(pins)
        dtexts = disk_texts([a.drafted])
        dcounts, _, _ = run_probe(dtexts, dctx, "page", lambda l: out("  G-3 | " + l))
        reproduce(pins, dcounts, term_only(a.sensitivity_file or [], dctx))
        row("G-3 sensitivity: the drafted pages reproduce the pins, no class is pinned at 0, every expression matched", len(dtexts) == exp["pages"],
            "files=%d expected=%d" % (len(dtexts), exp["pages"]))
        row("G-3 the held ranges at the commit are the pinned ones", dctx["held"] == ctx["held"], "equal=%s" % (dctx["held"] == ctx["held"]), dctx["held"] == ctx["held"])
    except NotEvaluated as e:
        row("G-3 sensitivity", False, str(e), evaluated=False)
    # G-4, G-5, G-13: the commit's own bytes, read from its objects
    pages = rev_texts(tree, [CATALOG + "/" + a.universe], (".md",))
    readme = {CATALOG + "/README.md": tree.blob(CATALOG + "/README.md")}
    gen = {f: tree.blob(f) for f in sorted(tree.files) if kind_of(f, a.universe) == "generated"}
    outside, grew = {}, {}
    for l in status:
        st, path = l.split("\t")
        if kind_of(path, a.universe) == "outside" and st != "D":
            tree.blob(path)                                # not text: not evaluated
            lines = added_lines(a.repo, base, commit, path)
            outside[path], grew[path] = "\n".join(lines), len(lines)
    n_out = sum(1 for l in status if l[0] != "D" and kind_of(l.split("\t")[1], a.universe) == "outside")
    for name, texts, expect, mode in (("G-4 pages", pages, exp["pages"], "page"), ("G-4 the catalog README", readme, 1, "readme"),
                                      ("G-5 generated files", gen, exp["generated_files"], "generated"),
                                      ("G-13 added lines of changed files outside the catalog", outside, n_out, "other")):
        counts, lines, bad = run_probe(texts, ctx, mode, lambda l: out("  %s %s | %s" % (name.split()[0], mode, l)), by_file=True)
        row(name + ": examined", len(texts) == expect and all(x.strip() for x in texts.values()), "files=%d expected=%d lines=%d" % (len(texts), expect, lines))
        row(name + ": every gated class reads 0", bad == 0, "gated_total=%d" % bad)
        if mode == "page":
            row("G-4 the rename", counts["old-title-heading"] == 0 and counts["new-title-heading"] == exp["renamed"],
                "old=%d new=%d expected_new=%d" % (counts["old-title-heading"], counts["new-title-heading"], exp["renamed"]))
            row("G-4 grounded names are the acknowledged count", counts["grounded-name"] == exp["grounded_name"],
                "grounded=%d acknowledged=%d newly_tracked=%d" % (counts["grounded-name"], exp["grounded_name"], counts["newly-tracked-name"]))
    # G-13, the bound: each changed path outside the catalog adds exactly the number of lines the pins record for it.
    # A path with no pinned bound, and a path that adds more or fewer lines than its bound, each fail the row.
    off = sorted(p for p in grew if pins["outside"].get(p) != grew[p])
    row("G-13 each changed path outside the catalog adds the pinned number of lines", not off,
        "paths=%d bounded=%d differing=%d added_lines=%d pinned_lines=%d" % (
            len(grew), sum(1 for p in grew if p in pins["outside"]), len(off), sum(grew.values()),
            sum(pins["outside"].get(p, 0) for p in grew)))
    body = git(a.repo, "show", "-s", "--format=%B", commit).strip()
    row("G-6 the commit message is the hub's file", bool(body) and sha(body) == sha(msg_raw.decode("utf-8").strip()), "bytes=%d" % len(body.encode("utf-8")))
    pop, nlisted, nfiles, _ = population(a.repo, commit, Tree(a.repo, a.release_base), base)
    hits, title = term_hits(pop, ctx, count=False)
    row("G-7 term lists and the old title over every changed file, every changed path's name and the message",
        hits == 0 and title == 0 and nfiles >= 1 and nfiles == nlisted,
        "examined=%d files=%d listed=%d term_hits=%d title_hits=%d" % (len(pop), nfiles, nlisted, hits, title))
    # G-8 to G-11: the catalog tools and the required gates' checkers, in a detached checkout of the commit
    tmp = scratch_dir(a, "publication-gate-")
    co = os.path.join(tmp, "tree")
    try:
        git(a.repo, "worktree", "add", "--detach", co, commit)
        clean = lambda: not git(co, "status", "--porcelain", "--untracked-files=all", "--ignored")
        head_ok = git(co, "rev-parse", "HEAD^{tree}").strip() == tree_id and clean()
        row("G-8 the checkout is the signed tree and is clean", head_ok, "tree_equal_and_status_empty=%s" % head_ok)
        md = [l.split("\t")[1] for l in status if l[0] != "D" and l.endswith(".md")]
        fill = dict(exp, base=base, commit=commit, md_csv=",".join(md),
                    pattern=os.path.abspath(a.private_pattern_file) if arm == "run" else "",
                    pattern_digest=os.path.abspath(a.pattern_digest_file) if arm == "run" else "")
        env = tool_env({"PYTHONDONTWRITEBYTECODE": "1", "GITHUB_REPOSITORY": a.repository, "GITHUB_STEP_SUMMARY": os.devnull})
        row("G-9 changed Markdown files handed to the checkers", len(md) >= 1, "files=%d" % len(md))
        for name, kind, argv, must in tool_rows(arm):
            args = []
            for x in argv:
                args += md if x == "{md}" else [x.format(**fill)]
            if not os.path.isfile(os.path.join(co, args[0])):
                row("G-9 " + name, False, "the commit does not carry %s" % args[0], evaluated=False)
                continue
            r = subprocess.run(([sys.executable, "-B"] if kind == "py" else ["bash"]) + args, cwd=co, capture_output=True, text=True, env=env)
            miss = [m for m in must if not re.search(m.format(**fill), r.stdout)]
            last = ([l for l in r.stdout.strip().split("\n") if l] or [""])[-1]
            row("G-9 " + name, r.returncode == 0 and not miss, "exit=%d unmet=%d of %d last=%s" % (r.returncode, len(miss), len(must), last[:120]),
                evaluated=r.returncode not in (2, 3))
        anc = git_rc(a.repo, "merge-base", "--is-ancestor", a.verified, commit)[0] == 0
        row("G-10 the publication head is an ancestor of the commit", anc, "is_ancestor=%s" % anc)
        row("G-11 the checkout is still clean", clean(), "status_empty=%s" % clean())
    finally:
        git_rc(a.repo, "worktree", "remove", "--force", co)
        shutil.rmtree(tmp, ignore_errors=True)
        git_rc(a.repo, "worktree", "prune")
    verdict = "NOT-EVALUATED" if noteval else ("FAIL" if fails else "PASS")
    out("paths  changed=%d pages=%d generated=%d readme=%d outside=%d" % (len(status), kinds["page"], kinds["generated"], kinds["readme"], kinds["outside"]))
    out("edits  outside the catalog: paths=%d added_lines=%d" % (len(grew), sum(grew.values())))
    out("gate   verdict=%s rows=%d rows_failed=%d rows_not_evaluated=%d" % (
        verdict, sum(1 for l in rec if re.match(r"^(PASS|FAIL|NOT-EVALUATED) +G-", l)), len(fails), len(noteval)))
    digest = sha("\n".join(rec))
    open(a.record_out, "w", encoding="utf-8").write("\n".join(rec) + "\nrecord sha256=%s\n" % digest)
    print("record sha256=%s lines=%d commit=%s tree=%s" % (digest, len(rec) + 1, commit, tree_id))
    return 3 if noteval else (1 if fails else 0)


def cmd_shape(a):
    """Does base..commit change line values only? A page counts as `mechanical` when it is modified and equals its old
    self once the line numbers of each root-link fragment, and the `line=` value of each source-anchor comment in the
    Tool Contract's exact grammar, are masked. Anything else is `other`: a page that differs in any other byte -
    prose inside an anchor comment included - and every changed path that is not a page."""
    base, commit = (git(a.repo, "rev-parse", "--verify", x + "^{commit}").strip() for x in (a.base, a.commit))
    mask = lambda t: ANCHOR_LINE.sub(r"\1\2", FRAGMENT.sub(r"\1\2", t))
    rows = [l.split("\t") for l in git(a.repo, "diff", "--no-renames", "--name-status", base, commit).split("\n") if l]
    if not rows:
        raise NotEvaluated("the range changes no path")
    show = lambda rev, p: git(a.repo, "show", "%s:%s" % (rev, p), text=False)
    kinds = collections.Counter(kind_of(p, a.universe) for _, p in rows)
    mech = sum(1 for s, p in rows if kind_of(p, a.universe) == "page" and s == "M"
               and mask(show(base, p).decode("utf-8", "replace")) == mask(show(commit, p).decode("utf-8", "replace")))
    other = len(rows) - mech
    print("shape commit=%s base=%s changed_paths=%d pages=%d mechanical=%d other=%d not_pages=%d" % (
        commit, base, len(rows), kinds["page"], mech, other, len(rows) - kinds["page"]))
    return 1 if other else 0


def main(argv=None):
    argv = sys.argv[1:] if argv is None else list(argv)
    if "--self-test" in argv:                              # no input of the caller's is read; --tmp-dir places its folders
        st = argparse.ArgumentParser(description="Run the publication gate's own arms in scratch repositories.")
        st.add_argument("--self-test", action="store_true", required=True)
        st.add_argument("--tmp-dir", help="make the scratch repositories under this directory")
        return self_test(st.parse_args(argv))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("probe", "gate", "scan"):
        p = sub.add_parser(name)
        for k in ("--repo", "--effort-terms", "--old-title-file", "--new-title-file"):
            p.add_argument(k, required=True)
        p.add_argument("--hub-terms", action="append", required=True, help="lists read on whole content")
        p.add_argument("--added-terms", action="append", help="lists read on added lines of a file that pre-dates the release")
        p.add_argument("--page-terms", action="append", help="lists gated on pages only, net of the old title")
        p.add_argument("--sensitivity-file", action="append", help="read for the term lists alone")
        p.add_argument("--identity-file", required=name != "probe", help="two lines: the repository's own commit name and address")
        if name != "scan":
            p.add_argument("--listing", required=True)
        if name == "probe":
            p.add_argument("paths", nargs="+")
            p.add_argument("--rev", required=True, help="the commit whose tracked names ground a name")
            p.add_argument("--ground-rev", help="the pushed base, when --rev is an unpushed commit")
            p.add_argument("--at-rev", action="store_true", help="read the paths from the commit's objects, not from disk")
            p.add_argument("--expect-files", type=int, required=True)
            p.add_argument("--held", action="append", help="held ranges; without it they are read from the commit's pack")
            p.add_argument("--generated", action="store_true")
            p.add_argument("--readme", action="store_true", help="the file is the catalog README: the six disclosure classes are gated")
            p.add_argument("--other", action="store_true", help="text from outside the catalog: every class is gated")
            p.add_argument("--by-file", action="store_true")
            p.add_argument("--pins")
            p.add_argument("--write-pins")
            p.add_argument("--expect-drafted", action="store_true", help="the run must reproduce the pinned drafted counts")
            p.add_argument("--head-rev", help="with --write-pins: the publication head; writes gate pins")
            p.add_argument("--manifest", action="append", help="with --head-rev: a file set the gate may be given")
            p.add_argument("--universe", default="engineering-harness")
            p.add_argument("--ack-grounded", type=int, help="with --head-rev: the grounded-name count the hub acknowledges")
            p.add_argument("--outside-bounds", help="with --head-rev: `<added lines><tab><path>` for each manifest path outside the catalog")
        elif name == "gate":
            for k in ("--commit", "--base", "--verified", "--release-base", "--manifest", "--message-file",
                      "--drafted", "--drafted-rev", "--record-out", "--universe", "--pins", "--repository"):
                p.add_argument(k, required=True)
            p.add_argument("--pattern-arm", choices=["run", "not-run"], required=True, help="declared on every run; never inferred")
            p.add_argument("--private-pattern-file", help="with --pattern-arm run: handed to the register check")
            p.add_argument("--pattern-digest-file", help="with --pattern-arm run: handed to the register check with the pattern")
            p.add_argument("--tmp-dir", help="make the detached checkout under this directory")
            p.add_argument("--drafted-held", action="append", required=True)
            p.set_defaults(held=None)
        else:
            for k in ("--head", "--control-commit", "--release-base"):
                p.add_argument(k, required=True)
            p.add_argument("--base", action="append", required=True, help="a ref the remote already holds; repeat for each")
            p.add_argument("--near-miss-commit", required=True, help="a commit that holds text and must read 0")
            p.add_argument("--one-commit", action="store_true", help="the range must hold exactly one commit")
            p.add_argument("--text-file", action="append", help="a branch name, a pull-request title or body, in a file")
            p.add_argument("--pins", required=True, help="the lists in hand must be the pinned ones")
    p = sub.add_parser("preflight")
    for k in ("--repo", "--identity-file"):
        p.add_argument(k, required=True)
    p.add_argument("--pins")
    p.add_argument("--tmp-dir", help="make the empty push target under this directory")
    p = sub.add_parser("shape")
    for k in ("--repo", "--base", "--commit", "--universe"):
        p.add_argument(k, required=True)
    a = ap.parse_args(argv)
    if a.cmd == "gate":                                    # both files with the arm, neither without it
        files = (a.private_pattern_file, a.pattern_digest_file)
        if a.pattern_arm == "run" and not all(files):
            ap.error("--pattern-arm run needs --private-pattern-file and --pattern-digest-file")
        if a.pattern_arm == "not-run" and any(f is not None for f in files):
            ap.error("--pattern-arm not-run takes neither --private-pattern-file nor --pattern-digest-file")
    try:
        return {"probe": cmd_probe, "gate": cmd_gate, "scan": cmd_scan, "preflight": cmd_preflight, "shape": cmd_shape}[a.cmd](a)
    except NotEvaluated as e:
        print("NOT-EVALUATED: %s" % e)
        print("publication %s status=not-evaluated" % a.cmd)
        return 3


# ----------------------------------------------------------------------------------------------------------------------
# Self-test. Every repository is a scratch one, built at run time from the synthetic text below: no remote, no fixture
# file, and nothing of the caller's is read. The machine's git configuration is not relied on - the user-level and
# system-level files are nulled for this process and each scratch repository carries its own identity. No scratch
# commit is signed, because no setting asks for a signature and no option switches one off. The signature row is
# therefore driven two ways: through `_signature_reader`, replaced here and nowhere else, to stand for a signed commit;
# and through the real reader, which must read every scratch commit as unsigned.
# ----------------------------------------------------------------------------------------------------------------------
ST_UNIVERSE, ST_HELD = "lab", "C-100..C-110"
ST_WHO = ("Fixture Committer", "fixture-committer.invalid")
ST_OTHER = ("Fixture Stranger", "fixture-stranger.invalid")
ST_OLD, ST_NEW = "Legacy Ledger Notes", "Neutral Section"
ST_LISTS = {"effort": "# a synthetic list\nlit:zeta effort\n", "hub": "lit:quark hub\nre:\\bQX-[0-9]+\\b\n",
            "added": "lit:omega added\n", "page": "lit:ledger\n"}
ST_SENSITIVITY = "zeta effort; quark hub; QX-7; omega added; ledger.\n"
ST_LISTING = "stage/deep/draft-notes.md\nstage/handoff-report.md\nstage/Readme.md\n"
ST_OUTSIDE = ("core/standards/alpha-standard.md", "release/references/beta-guide.md", "release/references/gamma-guide.md")
ST_PAGE = "core/process-catalog/" + ST_UNIVERSE + "/lab-page-%d.md"
ST_FRONT = "---\nid: lab-page-%d\nlevel: L3\nlast_verified_commit: %s\npack_version: 1\ndepicts: [src/alpha.txt]\n---\n# Page %d\n\n"
ST_BODY = ("## " + ST_NEW + "\n\nThe flow reads [alpha](/src/alpha.txt) and writes handoff-report.md, which its source "
           "describes. See README.md.\n\n| step | where |\n|---|---|\n| one | the source |\n\n" + FENCE + "text\na fenced block\n" + FENCE + "\n")
ST_DRAFT = ("## " + ST_OLD + "\n\nSee [alpha L12](/src/alpha.txt#L12) and [gone](/missing/file.md).\n"
            "The draft lives in draft-notes.md under stage/deep/ and handoff-report.md is described by its source.\n"
            "Read src/gamma.txt at line 14 on this install.\n"
            "There is no register row for it; minted_by is dropped; class <code-warn>; see C-105.\n\n"
            "| step | where |\n|---|---|\n| one | here |\n\nzeta effort and quark hub and omega added.\n")
ST_PLANT = "on this install C-105 minted_by"                 # three gated classes, one hit each
ST_TOOL = '''import os, sys
a = sys.argv[1:]
cat, uni = "core/process-catalog", "%s"
pages = len([f for f in os.listdir(os.path.join(cat, uni)) if f.endswith(".md")]) if os.path.isdir(os.path.join(cat, uni)) else 0
gen = len([f for f in os.listdir(cat) if f != "README.md" and f.endswith((".md", ".json"))])
rows = lambda n: len([l for l in open(os.path.join(cat, "definitions", n), encoding="utf-8").read().split("\\n") if l.strip()]) - 1
reg, ids = rows("controls-register.tsv"), rows("id-registry.tsv")
def close(gate, tail):
    print("process-catalog %%s status=pass exit=0 %%s" %% (gate, tail))
    sys.exit(0)
if "--registers-only" in a:
    arm = a[a.index("--pattern-arm") + 1]
    files = [a[a.index(k) + 1] for k in ("--private-pattern-file", "--pattern-digest-file") if k in a]
    if (arm == "run") != (len(files) == 2) or not all(os.path.isfile(f) for f in files):
        sys.exit(2)
    print("pattern arm: run, 1 probes matched, words from a stand-in" if arm == "run" else "pattern arm: NOT RUN (declared); stand-in")
    print("register roots: catalog=core/process-catalog fixtures=core/deploy/tools/fixtures/process-catalog probe_source=stand-in held=%s")
    close("registers", "register_rows=%%d registry_rows=%%d pattern_arm=%%s findings=0" %% (reg, ids, arm))
if a[:2] == ["build", "--check"]:
    close("generated-output", "universes=1 pages=%%d generated_files=%%d differing=0 missing=0 orphans=0 link_findings=0" %% (pages, gen))
if a[:1] == ["anchors"]:
    close("citations", "pages=%%d citations=0 current=0 moved=0 gone=0 ambiguous=0 other=0 rewritten=0" %% pages)
if a[:1] == ["stale"]:
    close("staleness", "pages=%%d sources=1 depicted_changed=0 cited_changed=0 fail_on=any" %% pages)
close("page-validation", "universes=1 pages=%%d registry_rows=%%d register_rows=%%d pattern_arm=not-run errors=0 warns=0" %% (pages, ids, reg))
''' % (ST_UNIVERSE, ST_HELD)
ST_CHECKERS = {  # stand-ins for the four tracked checkers: each prints the line the real one prints on a pass
    "core/deploy/tools/check-commit-close-keywords.py": 'print("  commits examined: 1")\nprint("  findings: 0")\n',
    "core/deploy/tools/check-doc-links.py": "import sys\nsys.exit(0)\n",
    "release/tools/check-release-links.py": 'print("\\n=== 0 broken links across 0 files ===")\n',
    "core/deploy/tools/check-issue-ref-validity.sh":
        'echo ":white_check_mark: Issue-reference validity — all #N in changed markdown resolve in-repo and sit in reference blocks"\n',
}
ST_AS_BUILT = {  # what each real checker's source must still hold for its stand-in to be a fair one
    "core/deploy/tools/check-commit-close-keywords.py": ("commits examined: {examined}", "findings: {len(findings)}"),
    "release/tools/check-release-links.py": ("=== {total_broken} broken links across {files_with_broken} files ===",),
    "core/deploy/tools/check-issue-ref-validity.sh": ("Issue-reference validity — all #N in changed markdown resolve",),
}


class _Lab:
    """One scratch repository and the folder of hub-side files beside it."""

    def __init__(self, root, name):
        self.root, self.repo, self.n = root, os.path.join(root, name), 0
        os.makedirs(self.repo)
        os.makedirs(os.path.join(root, "in"), exist_ok=True)
        self.g("init", "--quiet")
        self.g("config", "--local", "user.name", ST_WHO[0])
        self.g("config", "--local", "user.email", ST_WHO[1])

    def g(self, *args, env=None):
        r = subprocess.run(["git", "-C", self.repo] + list(args), capture_output=True, text=True, env=dict(os.environ, **(env or {})))
        if r.returncode != 0:
            raise RuntimeError("scratch git %s failed: %s" % (args[0], r.stderr.strip()[:200]))
        return r.stdout

    def f(self, name, text):
        path = os.path.join(self.root, "in", name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(text if isinstance(text, bytes) else text.encode("utf-8"))
        return path

    def write(self, files):
        for rel, text in files.items():
            path = os.path.join(self.repo, rel)
            if text is None:
                self.g("rm", "--quiet", "--", rel)
                continue
            os.makedirs(os.path.dirname(path), exist_ok=True)
            if os.path.lexists(path):
                os.remove(path)
            if isinstance(text, tuple):                    # ("link", target): an entry that is not a regular file
                os.symlink(text[1], path)
            else:
                with open(path, "wb") as fh:
                    fh.write(text if isinstance(text, bytes) else text.encode("utf-8"))
                if rel.endswith(".sh"):
                    os.chmod(path, 0o700)
            self.g("add", "--", rel)

    def commit(self, parent, files, message="lab: a scratch commit\n", who=None):
        self.n += 1
        if parent:
            self.g("checkout", "--quiet", "-B", "b%d" % self.n, parent)
        self.write(files)
        env = dict(zip(("GIT_AUTHOR_NAME", "GIT_AUTHOR_EMAIL", "GIT_COMMITTER_NAME", "GIT_COMMITTER_EMAIL"), who * 2)) if who else None
        self.g("commit", "--quiet", "--allow-empty", "-F", self.f("message-%d" % self.n, message), env=env)
        return self.g("rev-parse", "HEAD").strip()


def _st_run(*argv):
    """One in-process run of this tool: (exit, standard output)."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(io.StringIO()):
        try:
            code = main([str(x) for x in argv])
        except SystemExit as e:
            code = e.code
    return code, buf.getvalue()


def _st_rows(text):
    """{row name: verdict token} of one gate run."""
    return {m.group(2): m.group(1) for m in re.finditer(r"(?m)^(PASS|FAIL|NOT-EVALUATED) +(G-[0-9]+ .*?) - ", text)}


def self_test(opts):
    global _signature_reader
    if opts.tmp_dir is not None and not os.path.isdir(opts.tmp_dir):
        print("NOT-EVALUATED: --tmp-dir does not name a directory")
        print("publication self-test status=not-evaluated")
        return 3
    saved, root = dict(os.environ), os.path.realpath(tempfile.mkdtemp(prefix="publication-self-test-", dir=opts.tmp_dir))
    arms, failed, attacks = [0], [], [0, 0]

    def check(label, ok, detail=""):
        arms[0] += 1
        if not ok:
            failed.append(label)
            print("SELF-TEST FAIL: %s%s" % (label, " - " + str(detail)[:900] if detail != "" else ""))
        return bool(ok)

    def attack(label, code, text, exact=None, includes=(), want_code=1):
        """An attack passes its arm only when the run fails on the row it names: `exact` is the whole set of failed
        rows, `includes` rows that must be among them."""
        bad = {k for k, v in _st_rows(text).items() if v != "PASS"}
        named = (exact is None or bad == set(exact)) and all(any(k.startswith(i) for k in bad) for i in includes)
        return tally(label, code == want_code and named, "exit=%s; rows not passing: %s" % (code, "; ".join(sorted(bad)) or "none read"))

    def tally(label, ok, detail):
        """One attack, one printed line: what was tried, the exit, and the rows it did not pass."""
        attacks[0] += 1
        attacks[1] += bool(ok)
        print("attack %2d %s | %s | %s" % (attacks[0], "fails as named" if ok else "DOES NOT FAIL AS NAMED", label, detail))
        return check("attack: " + label, ok, detail)

    try:
        os.environ.update({"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_SYSTEM": os.devnull, "GIT_CONFIG_NOSYSTEM": "1",
                           "HOME": root, "GIT_TERMINAL_PROMPT": "0"})
        for k in [k for k in os.environ if k.startswith(("GIT_AUTHOR_", "GIT_COMMITTER_")) or k in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")]:
            del os.environ[k]
        tmp = os.path.join(root, "tmp")
        os.makedirs(tmp)
        lab = _Lab(root, "k")
        here = open(os.path.abspath(__file__), "rb").read()

        # ---- the scratch history: a release base, a publication head that carries the tools, and the clean commit
        outside0 = {p: "# A standing file\n\nOld text.\n" for p in ST_OUTSIDE}
        rb = lab.commit(None, dict(outside0, **{
            "README.md": "# Scratch\n", "docs/notes.md": "An old line: omega added, long public.\n", "src/alpha.txt": "alpha writes handoff-report.md\n",
            "src/gamma.txt": "gamma\n", "core/hooks/lib/reader.sh": "#!/bin/sh\nexit 0\n", "core/hooks/git-pre-commit-pii.sh": "#!/bin/sh\nexit 0\n"}))
        tools = dict(ST_CHECKERS, **{SELF: here, BUILD: ST_TOOL, CHECK: ST_TOOL})
        head = lab.commit(rb, dict(tools, **{
            CATALOG + "/README.md": "# Catalog\n\nHow to read: start at the index.\n",
            PACK: json.dumps({"controls_register_rules": {"held_ids": [ST_HELD]}}) + "\n",
            REGISTERS[0]: "id\tname\nC-001\tone\nC-002\ttwo\n", REGISTERS[1]: "id\tkind\nN-1\tnode\n"}))
        page = lambda i, body=ST_BODY, front=ST_FRONT: (front % (i, rb, i)) + body
        clean = dict({ST_PAGE % i: page(i) for i in range(1, 5)}, **{
            CATALOG + "/index.md": "# Index\n\nThe pages of the lab universe, by node.\n", CATALOG + "/graph.json": '{"nodes": ["lab-page"]}\n',
            CATALOG + "/README.md": "# Catalog\n\nHow to read: start at the index.\n\nA small-context reader may skip the tables.\n"})
        clean.update({p: outside0[p] + "One added clause.\n" for p in ST_OUTSIDE})
        message = "lab: publish the pages\n"
        with_ = lambda **kw: dict(clean, **kw)                # the clean commit with some paths written otherwise
        made = lambda files, **kw: lab.commit(head, files, kw.pop("message", message), **kw)
        good = made(clean)

        # ---- the hub's files: lists, titles, listing, identity, manifests, bounds, message, pattern and its digest
        lists = []
        for key, opt in (("effort", "--effort-terms"), ("hub", "--hub-terms"), ("added", "--added-terms"), ("page", "--page-terms")):
            lists += [opt, lab.f("list-" + key, ST_LISTS[key])]
        lists += ["--old-title-file", lab.f("old-title", ST_OLD + "\n"), "--new-title-file", lab.f("new-title", ST_NEW + "\n")]
        ident, listing, sens = lab.f("identity", "%s\n%s\n" % ST_WHO), lab.f("listing", ST_LISTING), lab.f("sensitivity", ST_SENSITIVITY)
        status = lambda files: "".join("%s\t%s\n" % ("M" if p in outside0 or p == CATALOG + "/README.md" else "A", p) for p in sorted(files))
        manifest = lab.f("manifest", status(clean))
        inner = {p: t for p, t in clean.items() if p not in outside0}
        manifest_inner = lab.f("manifest-inner", status(inner))
        bounds = lab.f("bounds", "".join("1\t%s\n" % p for p in ST_OUTSIDE))
        msg, pat = lab.f("message", message), lab.f("pattern", "stand-in\n")
        dig = lab.f("pattern-digest", sha("stand-in\n") + "\n")
        drafted = os.path.join(root, "in", "drafted")
        for i in range(1, 5):
            lab.f("drafted/lab-page-%d.md" % i, page(i, ST_DRAFT))
        common = ["--repo", lab.repo] + lists + ["--sensitivity-file", sens, "--identity-file", ident]
        pin_args = ["probe", drafted] + common + ["--listing", listing, "--rev", rb, "--expect-files", 4, "--held", ST_HELD,
                                                  "--universe", ST_UNIVERSE, "--head-rev", head, "--manifest", manifest,
                                                  "--manifest", manifest_inner, "--outside-bounds", bounds]
        pins, record = os.path.join(root, "in", "pins.json"), os.path.join(root, "in", "record.txt")

        unsigned = set()
        real_reader = _signature_reader
        _signature_reader = lambda repo, c: "N" if c in unsigned else "G"     # stands for "signed" on every other commit

        def gate(commit, base=None, **kw):
            argv = ["gate"] + common + ["--listing", kw.get("listing", listing), "--commit", commit, "--base", base or head, "--verified", head,
                                        "--release-base", rb, "--universe", ST_UNIVERSE, "--manifest", kw.get("manifest", manifest),
                                        "--message-file", kw.get("message_file", msg), "--pins", kw.get("pins", pins), "--drafted", drafted,
                                        "--drafted-rev", rb, "--drafted-held", ST_HELD, "--repository", "owner/name",
                                        "--record-out", record, "--tmp-dir", tmp]
            argv += kw.get("arm", ["--pattern-arm", "run", "--private-pattern-file", pat, "--pattern-digest-file", dig]) + kw.get("more", [])
            return _st_run(*argv)

        # ---- pins: refused on an unsigned head by the real reader; written, exit 0, once the head reads as signed
        _signature_reader = real_reader
        code, text = _st_run(*(pin_args + ["--write-pins", pins]))
        check("pins: the real reader reads a scratch head as unsigned, and gate pins are refused on it",
              code == 3 and "is not signed (state N): gate pins are refused on it" in text and not os.path.exists(pins), text[-300:])
        _signature_reader = lambda repo, c: "N" if c in unsigned else "G"
        code, text = _st_run(*(pin_args + ["--write-pins", pins]))
        check("pins: writing gate pins exits 0 and says these are first pins",
              code == 0 and "pin: first gate pins; pages tracked at the head: 0" in text and "publication pins status=pass written=1" in text, text[-400:])
        pinned = json.load(open(pins, encoding="utf-8"))
        check("pins: they keep the publication head, its signature state and a bound for each path outside the catalog",
              pinned.get("head") == head and pinned.get("head_signature") == "G" and pinned.get("outside") == {p: 1 for p in ST_OUTSIDE})
        check("pins: no gated class that the lists do not back is pinned at 0 on the drafted pages",
              all(pinned["drafted"][k] > 0 for k in GATED if k not in LISTED + PROVEN_ELSEWHERE), pinned["drafted"])
        for i in (1, 2):
            lab.f("clean-pages/lab-page-%d.md" % i, page(i))
        code, text = _st_run(*(["probe", os.path.join(root, "in", "clean-pages")] + common + [
            "--listing", listing, "--rev", rb, "--expect-files", 2, "--held", ST_HELD, "--write-pins", os.path.join(root, "in", "empty-pins.json")]))
        tally("pins written over clean pages are refused", code == 3 and "pinned at 0" in text, "exit=%s; no pins are written" % code)
        code, text = _st_run(*(pin_args[:-2] + ["--write-pins", os.path.join(root, "in", "unbounded.json")]))
        check("pins: a manifest path outside the catalog with no bound is refused", code == 3 and "have no bound" in text, text[-300:])

        def forged(name, change):
            doc = json.load(open(pins, encoding="utf-8"))
            change(doc)
            return lab.f(name, json.dumps(doc))

        # ---- the clean commit passes every row, twice with one digest; then each attack fails on the row it names
        code, text = gate(good)
        rows = _st_rows(text)
        check("clean commit: PASS on every row, exit 0", code == 0 and rows and set(rows.values()) == {"PASS"} and "gate   verdict=PASS rows=%d rows_failed=0 rows_not_evaluated=0" % len(rows) in text,
              "exit=%s %s" % (code, sorted(k for k, v in rows.items() if v != "PASS")) + text[-300:])
        clean_rows = len(rows)
        first = open(record, encoding="utf-8").read()
        check("clean commit: the record's first line and last line keep their form",
              re.match(r"gate   commit=%s tree=[0-9a-f]{40} base=%s\n" % (good, head), first) is not None
              and first.rstrip("\n").rsplit("\n", 1)[1] == "record sha256=" + sha(first.rstrip("\n").rsplit("\n", 1)[0]))
        check("clean commit: the record states one commit on the pinned head, the signature state, the pins' digest and lineage, and the tool trees",
              "parent one commit on " + head in first and "state=G pinned=G" in first and "digest pins-file sha256=" + sha(open(pins, "rb").read()) in first
              and "pins   generation=1 pin: first gate pins" in first and all("tools  %s tree=%s" % (d, pinned["tools"][d]) in first for d in TOOL_TREES))
        check("clean commit: no digest of an input reaches standard output", "sha256=" not in text.replace(text.strip().split("\n")[-1], ""))
        under, real_mkdtemp = [], tempfile.mkdtemp
        tempfile.mkdtemp = lambda *a, **k: under.append(k.get("dir")) or real_mkdtemp(*a, **k)
        try:
            gate(good)
        finally:
            tempfile.mkdtemp = real_mkdtemp
        check("clean commit: a second run writes the same record", open(record, encoding="utf-8").read() == first)
        check("clean commit: the tool's folders are made under --tmp-dir and removed", under == [tmp] and os.listdir(tmp) == [], under)
        code, text = gate(good, more=["--tmp-dir", os.path.join(root, "absent")])
        check("a --tmp-dir that is not a directory is exit 3", code == 3 and "--tmp-dir" in text, text[-200:])
        code, text = gate(good, arm=["--pattern-arm", "not-run"])
        check("pattern arm declared not run: the register row is handed neither file and says so",
              code == 0 and _st_rows(text).get("G-9 register invariant, pattern arm not-run") == "PASS" and "pattern_arm=not-run" in text, text[-300:])
        check("pattern arm run without the digest file is a usage exit", gate(good, arm=["--pattern-arm", "run", "--private-pattern-file", pat])[0] == 2)
        check("pattern arm not-run with a pattern file is a usage exit", gate(good, arm=["--pattern-arm", "not-run", "--private-pattern-file", pat])[0] == 2)
        check("a typed count is a usage exit", gate(good, more=["--generated-files", "0"])[0] == 2)
        check("a --tool-file option is a usage exit", gate(good, more=["--tool-file", pat])[0] == 2)
        inner_commit = made(inner)
        code, text = gate(inner_commit, manifest=manifest_inner)
        check("a commit that changes no path outside the catalog passes, with files=0 expected=0 on that row",
              code == 0 and "paths=0 bounded=0 differing=0" in text and set(_st_rows(text).values()) == {"PASS"}, text[-300:])

        G1, G1K = "G-1 one commit on the pinned publication head", "G-1 every changed path"
        G2S, G2T, G2D = "G-2 the commit carries this file", "G-2 the tool folders are the pinned trees", "G-2 the definitions folder"
        G4, G4N, G4R = "G-4 pages: every gated class reads 0", "G-4 pages: examined", "G-4 the rename"
        G13, G13B, G14 = "G-13 added lines of changed files outside the catalog: every gated class reads 0", \
            "G-13 each changed path outside the catalog adds the pinned number of lines", "G-14 the commit's signature state is the pinned publication head's"
        p1, p2 = ST_PAGE % 1, ST_PAGE % 2
        name_line = "\nThe draft is draft-notes.md.\n"

        def run_attack(label, files, exact=None, includes=(), want_code=1, needle="", **kw):
            c = lab.commit(kw.pop("parent", head), files, kw.pop("message", message), who=kw.pop("who", None))
            code, text = gate(c, **kw)
            return attack(label, code, text if needle in text else "", exact, includes, want_code), c

        _, stranger = run_attack("a commit made under another identity fails the identity row and no other", clean,
                                 exact=["G-12 author and committer are the pinned identity"], who=ST_OTHER, needle="identity_equal=False")
        run_attack("no generated file", {p: t for p, t in clean.items() if p not in (CATALOG + "/index.md", CATALOG + "/graph.json")},
                   includes=["G-5 generated files: examined", "G-9 generated output"], needle="files=0 expected=2")
        run_attack("no page carries the new heading", with_(**{ST_PAGE % i: page(i, ST_BODY.replace(ST_NEW, "Another Heading")) for i in range(1, 5)}),
                   exact=[G4R], needle="new=0 expected_new=4")
        code, text = gate(good, pins=forged("forged-zero.json", lambda d: d["drafted"].update({k: 0 for k in GATED})))
        attack("pins forged by hand to read 0 on the drafted pages", code, text, includes=["G-3 sensitivity"], want_code=3)
        run_attack("the commit replaces a catalog tool", with_(**{BUILD: ST_TOOL + "# changed\n"}), includes=[G2T], needle="differing=1")
        run_attack("the commit adds a library beside the catalog tools", with_(**{"core/deploy/tools/_library.py": "VALUE = 1\n"}), includes=[G2T], needle="differing=1")
        run_attack("three gated plants on a fence's opening line", with_(**{p1: page(1, ST_BODY.replace(FENCE + "text", FENCE + "text " + ST_PLANT))}),
                   exact=[G4], needle="gated_total=3")
        run_attack("three gated plants on a frontmatter level line", with_(**{p1: page(1, front=ST_FRONT.replace("level: L3", "level: L3 " + ST_PLANT))}),
                   exact=[G4], needle="gated_total=3")
        run_attack("a working-set name on a page that links to the catalog folder", with_(**{p1: page(1) + name_line + "See [the catalog](/core/process-catalog).\n"}),
                   exact=[G4], needle="gated_total=1")
        run_attack("a working-set name on a page that depicts the catalog folder",
                   with_(**{p1: page(1, front=ST_FRONT.replace("[src/alpha.txt]", "[src/alpha.txt, core/process-catalog]")) + name_line}), exact=[G4], needle="gated_total=1")
        run_attack("two pages that each write the name and depict the other", with_(**{
            p1: page(1, front=ST_FRONT.replace("[src/alpha.txt]", "[src/alpha.txt, %s]" % p2)) + name_line,
            p2: page(2, front=ST_FRONT.replace("[src/alpha.txt]", "[src/alpha.txt, %s]" % p1)) + name_line}), exact=[G4], needle="gated_total=2")
        run_attack("a file under the universe folder that is not Markdown", with_(**{CATALOG + "/" + ST_UNIVERSE + "/notes.txt": ST_PLANT + "\n"}),
                   includes=[G1K], needle="unread=1")
        run_attack("a generated file that is neither Markdown nor JSON", with_(**{CATALOG + "/view.txt": ST_PLANT + "\n"}), includes=[G1K], needle="unread=1")
        run_attack("a Markdown file under the definitions folder", with_(**{DEFS + "/extra.md": ST_PLANT + "\n"}), includes=[G1K, G2D], needle="definitions=1")
        run_attack("a Markdown file outside the catalog that carries four plants", with_(**{"docs/extra.md": ST_PLANT + " draft-notes.md\n"}),
                   includes=[G13, G13B], needle="gated_total=4")
        _, named = run_attack("a listed term in a changed file's name only", with_(**{"docs/quark-hub.md": "A clean line.\n"}),
                              includes=["G-7 term lists"], needle="term_hits=1")
        run_attack("a gated word planted in a table", with_(**{p1: page(1, ST_BODY.replace("the source |", "here |"))}), exact=[G4], needle="gated_total=1")
        run_attack("one page fewer", {p: t for p, t in clean.items() if p != ST_PAGE % 4}, includes=[G4N], needle="files=3 expected=4")
        run_attack("the commit changes this tool's own file", with_(**{SELF: here + b"# changed\n"}), includes=[G2S, G2T], needle="equal=False")
        run_attack("the commit drops a catalog tool", with_(**{BUILD: None}), includes=["G-9 generated output", G2T], want_code=3)
        # the parent: a gated commit that sits on an unpushed commit, with the base typed either way
        parked = lab.commit(head, {"docs/unpushed.md": ST_PLANT + " draft-notes.md\n"})
        _, riding = run_attack("the gated commit sits on an unpushed commit, and the base typed is that commit", clean, exact=[G1],
                               parent=parked, base=parked, needle="base_is_pinned_head=False")
        code, text = gate(riding)
        attack("the same commit with the pinned head typed as its base", code, text if "ahead=2" in text and "parent NOT one commit on " + head in text else "",
               includes=[G1])
        # the signature: a commit that is not signed, read by the injected reader and then by the real one
        unsigned.add(good)
        code, text = gate(good)
        attack("a commit with no signature fails the signature row and no other", code, text if "state=N pinned=G" in text else "", exact=[G14])
        code2, text2 = gate(good, pins=forged("forged-unsigned.json", lambda d: d.update(head_signature="N")))
        unsigned.discard(good)
        code, text = gate(good, pins=os.path.join(root, "in", "forged-unsigned.json"))
        attack("pins made on an unsigned head are refused, whether or not the commit is unsigned too", 3 if code == code2 == 3 else 0,
               text if "is not signed (state N)" in text and "is not signed (state N)" in text2 else "", want_code=3)
        _signature_reader = real_reader
        code, text = gate(good)
        _signature_reader = lambda repo, c: "N" if c in unsigned else "G"
        attack("the real reader on a scratch commit, against pins that record a signed head", code, text if "state=N pinned=G" in text else "", exact=[G14])
        # the bound on the edits outside the catalog
        run_attack("one file outside the catalog gains many clean lines", with_(**{ST_OUTSIDE[0]: outside0[ST_OUTSIDE[0]] + "Another clean clause.\n" * 150}),
                   exact=[G13B], needle="differing=1 added_lines=152 pinned_lines=3")
        code, text = gate(good, pins=forged("forged-unbound.json", lambda d: d["outside"].pop(ST_OUTSIDE[1])))
        attack("a changed path outside the catalog that the pins give no bound", code, text if "bounded=2 differing=1" in text else "", exact=[G13B])
        # the listing name in another case, and the literal written with another joiner
        run_attack("a working-set name written in another case", with_(**{p1: page(1) + "\nThe draft is Draft-Notes.MD.\n"}), exact=[G4], needle="gated_total=1")
        run_attack("a literal written with a slash between its words", with_(**{p1: page(1) + "\nThe zeta/effort was large.\n"}),
                   includes=[G4, "G-7 term lists"], needle="gated_total=1")
        code, text = gate(good, listing=lab.f("listing-other", ST_LISTING + "stage/more.md\n"))
        check("a listing that is not the pinned one is exit 3, naming the input", code == 3 and "inputs differ from the pins: listing" in text, text[-200:])
        copy = lab.f("forged-tool.py", here + b"# a changed copy\n")
        r = subprocess.run([sys.executable, "-B", copy, "gate"] + [str(x) for x in common] + [
            "--listing", listing, "--commit", good, "--base", head, "--verified", head, "--release-base", rb, "--universe", ST_UNIVERSE, "--manifest", manifest,
            "--message-file", msg, "--pins", pins, "--drafted", drafted, "--drafted-rev", rb, "--drafted-held", ST_HELD, "--repository", "owner/name",
            "--record-out", os.path.join(root, "in", "forged-record.txt"), "--pattern-arm", "not-run"], capture_output=True, text=True)
        tally("a changed copy of this tool run as itself", r.returncode == 3 and "inputs differ from the pins: tool" in r.stdout,
              "exit=%s; the pins do not name the copy" % r.returncode)

        # ---- a re-pin says what moved; a pin run with no earlier pins named, at a head that tracks pages, says that
        moved = lab.commit(good, {BUILD: ST_TOOL + "# a later fix\n"})
        repin = os.path.join(root, "in", "repin.json")
        again = ["probe", drafted] + common + ["--listing", listing, "--rev", rb, "--expect-files", 4, "--held", ST_HELD, "--universe", ST_UNIVERSE,
                                               "--head-rev", moved, "--manifest", manifest]
        code, text = _st_run(*(again + ["--pins", pins, "--write-pins", repin]))
        check("re-pin: names the earlier pins, exits 0 and prints what moved",
              code == 0 and "re-pin: publication head moved: True; tool folders that differ from the earlier pins: 1; definitions folder differs: False; "
              "manifests added: 0; pages tracked at the head: 4" in text, text[-400:])
        later = json.load(open(repin, encoding="utf-8"))
        check("re-pin: the expected counts and the bounds are carried, and the pins name the ones before them",
              later["expected"] == pinned["expected"] and later["outside"] == pinned["outside"] and later["generation"] == 2
              and later["previous"] == sha(open(pins, "rb").read()))
        code, text = _st_run(*(again + ["--outside-bounds", bounds, "--write-pins", os.path.join(root, "in", "fresh.json")]))
        check("re-pin: with no earlier pins named, at a head that already tracks pages, the run says nothing is compared",
              code == 0 and "re-pin: no earlier pins were named, so nothing is compared; pages tracked at the head: 4" in text, text[-300:])

        # ---- term lists: every written form of a literal, a near-miss, and lines the reader must not drop
        _, pats, stat = terms(lab.f("list-forms", "lit:zeta effort\nlit:alpha.beta/gamma\nlit:#lab-channel\n"), "a list")
        forms = ["zeta effort", "ZETA  EFFORT", "zeta-effort", "zeta_effort", "zeta\neffort", "zetaeffort", "zeta/effort", "zeta.effort", "zeta–effort",
                 "zeta%20effort", "zeta* *effort", "zeta** **effort"]
        check("term list: a literal matches in each of its written forms (%d forms)" % len(forms), all(pats[0].search(x) for x in forms),
              [x for x in forms if not pats[0].search(x)])
        check("term list: the two words apart in one sentence do not match", not pats[0].search("zeta and then effort; effort, then zeta"))
        check("term list: a literal written with a dot and a slash is parted on them", pats[1].search("alpha beta gamma") and pats[1].search("Alpha.Beta/Gamma")
              and not pats[1].search("alpha and beta"))
        check("term list: a literal that begins with a number sign is matched, not dropped", pats[2].search("in #lab-channel today") and stat["literals"] == 3)
        check("term list: each written form is tried on load", stat["variants_matched"] == 3 * (2 + len(WRITTEN)))
        for label, body in (("a line of no kind", "lit:zeta effort\nzeta effort\n"), ("a number sign with no space", "#comment\nlit:zeta effort\n"),
                            ("an empty literal", "lit: - \n"), ("an expression that does not compile", "re:(\n"),
                            ("two entries joined by a lone carriage return", "lit:zeta effort\rlit:quark hub\n")):
            try:
                terms(lab.f("list-bad", body), "a list")
                check("term list: %s stops the run" % label, False, "it was read")
            except NotEvaluated as e:
                check("term list: %s stops the run" % label, "line" in str(e) or "literal" in str(e), e)

        # ---- probe: parse states, and the name class beside a tracked name that differs by case alone
        def probe_one(body, cls):
            code, text = _st_run(*(["probe", lab.f("one/page.md", body)] + common + ["--listing", listing, "--rev", head, "--expect-files", 1, "--held", ST_HELD]))
            m = re.search(r"(?m)^(?:gated|review)\s+%s\s+([0-9]+) on" % re.escape(cls), text)
            return int(m.group(1)) if m else -1
        check("probe: a page with an unpaired fence is unparsed", probe_one(page(1) + FENCE + "\n", "unparsed") == 1)
        check("probe: a page with no depicts line is unparsed", probe_one(page(1, front=ST_FRONT.replace("depicts: [src/alpha.txt]\n", "")), "unparsed") == 1)
        check("probe: a page with no frontmatter is unparsed twice", probe_one("# A page\n\n" + ST_BODY, "unparsed") == 2)
        check("probe: a mention spelled as a tracked file's own name is counted on no line, though a listing name differs by case alone",
              probe_one(page(1), "ws-name") == 0 and probe_one(page(1), "newly-tracked-name") == 0 and "README.md" in ST_BODY and "stage/Readme.md" in ST_LISTING)
        check("probe: the same name spelled as the listing spells it is counted", probe_one(page(1) + "\nSee Readme.md.\n", "ws-name") == 1)

        # ---- shape
        cite = "\n[alpha](/src/alpha.txt#L%d)<!-- source-anchor: line=%d; fp=0123456789abcdef%s -->\n"
        cited = lab.commit(good, {p1: page(1) + cite % (3, 3, "")})
        shape = lambda base, commit: _st_run("shape", "--repo", lab.repo, "--base", base, "--commit", commit, "--universe", ST_UNIVERSE)
        code, text = shape(cited, lab.commit(cited, {p1: page(1) + cite % (5, 5, "")}))
        check("shape: line values alone are mechanical", code == 0 and "mechanical=1 other=0" in text, text)
        code, text = shape(cited, lab.commit(cited, {p1: page(1) + cite % (3, 3, " and a note")}))
        check("shape: prose inside an anchor comment is other", code == 1 and "mechanical=0 other=1" in text, text)
        check("shape: an empty range is exit 3", shape(good, good)[0] == 3)

        # ---- scan: the control and the near-miss travel the read path; pins, both commits and every read are required
        control = lab.commit(rb, {"control/planted.md": ST_SENSITIVITY + ST_OLD + "\n"})
        near = lab.commit(rb, {"control/near.md": "zeta and then effort; quark then hub; omega then added; legacy then ledger.\n"})

        def run_scan(tip, *bases, **kw):
            argv = ["scan"] + [str(x) for x in (kw.get("common") or common)] + ["--head", tip, "--release-base", rb, "--control-commit", kw.get("control", control)]
            for b in bases or (head,):
                argv += ["--base", b]
            argv += [] if kw.get("no_near") else ["--near-miss-commit", kw.get("near", near)]
            argv += [] if kw.get("no_pins") else ["--pins", kw.get("pins", pins)]
            return _st_run(*(argv + kw.get("more", [])))

        code, text = run_scan(good, more=["--one-commit"])
        check("scan: one clean commit under the one-commit guard passes, and prints both counters",
              code == 0 and "examined: commits=1 files=%d listed=%d texts=0" % (len(clean), len(clean)) in text and "publication scan status=pass findings=0" in text, text[-300:])
        check("scan: without its pins it is a usage exit", run_scan(good, no_pins=True)[0] == 2)
        check("scan: without the near-miss commit it is a usage exit", run_scan(good, no_near=True)[0] == 2)
        short = [x if not str(x).endswith("list-hub") else lab.f("list-hub-short", "lit:quark hub\n") for x in common]
        code, text = run_scan(named, common=short)
        check("scan: a list one line shorter than the pinned one is exit 3", code == 3 and "inputs differ from the pins: hub-1" in text, text[-200:])
        planted = lab.commit(head, {"docs/slip.md": "A quark hub line.\n"})
        cleaned = lab.commit(planted, {"docs/slip.md": "A clean line.\n"})
        code, text = run_scan(cleaned)
        check("scan: a term added in one commit and removed in the next is found on the first", code == 1 and "commit %s files=1 listed=1 term_hits=1" % planted[:12] in text, text[-400:])
        check("scan: two commits under the one-commit guard are exit 3", run_scan(cleaned, more=["--one-commit"])[0] == 3)
        check("scan: an empty range is exit 3", run_scan(head)[0] == 3)
        check("scan: a term in a changed file's name alone is a finding", run_scan(named)[0] == 1)
        check("scan: a term in the message alone is a finding", run_scan(lab.commit(head, {"docs/slip.md": "A clean line.\n"}, "lab: the quark hub\n"))[0] == 1)
        code, text = run_scan(stranger)
        check("scan: a commit under another identity is a finding", code == 1 and "identity_equal=False" in text, text[-300:])
        check("scan: an old file edited, whose old lines hold an added-line term, passes", run_scan(lab.commit(head, {"docs/notes.md": "An old line: omega added, long public.\nA new clean line.\n"}))[0] == 0)
        check("scan: the same term on a line the commit adds is a finding", run_scan(lab.commit(head, {"docs/notes.md": "An old line: omega added, long public.\nNew: omega added.\n"}))[0] == 1)
        side = lab.commit(rb, {"docs/notes.md": "An old line: omega added, long public.\nThe base moved: omega added.\n"})
        lab.g("checkout", "--quiet", "-B", "merged", head)
        lab.g("merge", "--quiet", "--no-ff", "--no-edit", side)
        check("scan: a merge that brings a term already public on the other parent passes", run_scan(lab.g("rev-parse", "HEAD").strip(), head, side)[0] == 0)
        lab.g("checkout", "--quiet", "-B", "merged-more", head)
        lab.g("merge", "--quiet", "--no-ff", "--no-commit", side)
        evil = lab.commit(None, {"docs/notes.md": "An old line: omega added, long public.\nThe base moved: omega added.\nA quark hub line of the merge's own.\n"})
        check("scan: a merge with one line that stands in neither parent is a finding", run_scan(evil, head, side)[0] == 1)
        hot, cold, sensed = lab.f("text-branch", "feature/quark-hub\n"), lab.f("text-title", "lab: publish the pages\n"), ["--sensitivity-file", lab.f("text-sense", ST_SENSITIVITY + ST_OLD + "\n")]
        scan_common = [x for i, x in enumerate(common) if x != "--sensitivity-file" and common[i - 1] != "--sensitivity-file"]
        check("scan: a branch name that carries a term is a finding", run_scan(good, common=scan_common, more=["--text-file", hot] + sensed)[0] == 1)
        check("scan: a clean title passes", run_scan(good, common=scan_common, more=["--text-file", cold] + sensed)[0] == 0)
        check("scan: a text file with no sensitivity file is exit 3", run_scan(good, common=scan_common, more=["--text-file", cold])[0] == 3)
        check("scan: a control commit that lacks an arm is exit 3", run_scan(good, control=near)[0] == 3)
        check("scan: a near-miss commit that is counted is exit 3", run_scan(good, near=control)[0] == 3)
        check("scan: a near-miss commit that holds no text is exit 3", run_scan(good, near=lab.commit(rb, {}))[0] == 3)
        for label, files in (("is not UTF-8", {"docs/raw.md": b"\xff\xfe bytes\n"}), ("holds a NUL byte", {"docs/raw.md": b"a\x00b\n"}),
                             ("is not a regular file", {"docs/link.md": ("link", "notes.md")})):
            code, text = run_scan(lab.commit(head, files))
            check("scan: a file that %s is exit 3, naming it" % label, code == 3 and "docs/" in text, text[-200:])
        real_population = population

        def one_unread(repo, commit, *rest):                 # the subject commit alone loses one read
            pop, listed, read, who = real_population(repo, commit, *rest)
            return pop, listed, read - (commit == good), who
        try:
            globals()["population"] = one_unread
            code, text = run_scan(good)
        finally:
            globals()["population"] = real_population
        check("scan: a file listed and not read is exit 3, never a count",
              code == 3 and "files=%d listed=%d" % (len(clean) - 1, len(clean)) in text and "status=not-evaluated" in text, text[-300:])

        # ---- preflight, in a scratch clone-like repository of its own: eight checks, and a push that must be refused
        pre = _Lab(root, "p")
        pre.commit(None, {"core/hooks/git-pre-commit-pii.sh": "#!/bin/sh\nexit 0\n", "README.md": "# Scratch\n"})
        hooks = os.path.join(pre.repo, ".git", "hooks")
        os.makedirs(hooks, exist_ok=True)
        refuse, permit, hook = "#!/bin/sh\necho refused\nexit 1\n", "#!/bin/sh\nexit 0\n", os.path.join(hooks, "pre-push")

        def install(where, text, mode=0o700):
            with open(where, "w", encoding="utf-8") as fh:
                fh.write(text)
            os.chmod(where, mode)
        install(hook, refuse)
        os.symlink("../../" + GUARD, os.path.join(hooks, "pre-commit"))
        flight = lambda repo=pre.repo: _st_run("preflight", "--repo", repo, "--identity-file", ident, "--pins", pins, "--tmp-dir", tmp)
        under, tempfile.mkdtemp = [], lambda *a, **k: under.append(k.get("dir")) or real_mkdtemp(*a, **k)
        try:
            code, text = flight()
        finally:
            tempfile.mkdtemp = real_mkdtemp
        check("preflight: the scratch repository as built passes 8 of 8, and its last line keeps its form",
              code == 0 and text.strip().split("\n")[-1] == "publication preflight status=pass checks=8 missed=0" and "hook_refuses=True exit_nonzero=True refs_received=0" in text, text)
        check("preflight: its push target is made under --tmp-dir and removed", under == [tmp] and os.listdir(tmp) == [], under)
        install(hook, permit)
        code, text = flight()
        check("preflight: a hook that refuses nothing is exit 3, with HEAD on a commit", code == 3 and "hook_refuses=False" in text and "refs_received=1" in text, text)
        install(hook, refuse, 0o600)
        code, text = flight()
        check("preflight: a hook that is not executable is exit 3, and the push arrives", code == 3 and "refs_received=1" in text and "missed=2" in text, text)
        # a push that fails for a reason of its own, under a hook that refuses nothing, is not a refusal
        install(hook, permit)
        pre.g("config", "--local", "protocol.file.allow", "never")
        try:
            code, text = flight()
        finally:
            pre.g("config", "--local", "--unset", "protocol.file.allow")
        check("preflight: a push that fails for its own reason, under a hook that refuses nothing, is exit 3 on the push check alone",
              code == 3 and "hook_refuses=False exit_nonzero=True refs_received=0" in text and "missed=1" in text, text)
        install(hook, refuse)
        # the same clone-like repository with no commit yet: every other check passes, and the push check alone fails
        bare = _Lab(root, "unborn")
        os.makedirs(os.path.join(bare.repo, ".git", "hooks"), exist_ok=True)
        os.makedirs(os.path.join(bare.repo, os.path.dirname(GUARD)))
        install(os.path.join(bare.repo, GUARD), permit)
        os.symlink("../../" + GUARD, os.path.join(bare.repo, ".git", "hooks", "pre-commit"))
        for label, text0 in (("a hook that refuses nothing", permit), ("a hook that refuses", refuse)):
            install(os.path.join(bare.repo, ".git", "hooks", "pre-push"), text0)
            code, text = flight(bare.repo)
            check("preflight: %s, where HEAD names no commit, is exit 3 on the push check alone" % label,
                  code == 3 and "head_names_a_commit=False" in text and "missed=1" in text, text)
        for label, do, undo in (
                ("an identity forced by the environment", lambda: os.environ.update(GIT_COMMITTER_EMAIL=ST_OTHER[1]), lambda: os.environ.pop("GIT_COMMITTER_EMAIL")),
                ("another identity set in the repository", lambda: pre.g("config", "--local", "user.email", ST_OTHER[1]), lambda: pre.g("config", "--local", "user.email", ST_WHO[1])),
                ("a hook-path setting", lambda: pre.g("config", "--local", "core.hooksPath", "elsewhere"), lambda: pre.g("config", "--local", "--unset", "core.hooksPath")),
                ("a remote", lambda: pre.g("remote", "add", "origin", os.path.join(root, "nowhere")), lambda: pre.g("remote", "remove", "origin")),
                ("no commit-time guard", lambda: os.remove(os.path.join(hooks, "pre-commit")), lambda: os.symlink("../../" + GUARD, os.path.join(hooks, "pre-commit")))):
            do()
            try:
                code, text = flight()
            finally:
                undo()
            check("preflight: %s is exit 3" % label, code == 3 and "status=not-evaluated" in text, text)
        check("preflight: after each change is undone it passes again", flight()[0] == 0)
        code, text = _st_run("preflight", "--repo", pre.repo, "--identity-file", lab.f("identity-other", "%s\n%s\n" % ST_OTHER), "--pins", pins)
        check("preflight: an identity file that is not the pinned one is exit 3", code == 3 and "inputs differ from the pins: identity" in text, text)

        # ---- as built: the catalog-tool expressions against the real tools on their own fixture repository
        try:
            as_built(check, os.path.join(root, "as-built"))
        except Exception as e:                                # the sibling tools moved or changed shape: say so, as a failed arm
            check("as built: the real catalog tools ran on their fixture repository", False, "%s: %s" % (type(e).__name__, e))
    except Exception as e:
        check("the self-test ran to its end", False, "%s: %s" % (type(e).__name__, e))
    finally:
        _signature_reader = None
        os.environ.clear()
        os.environ.update(saved)
        shutil.rmtree(root, ignore_errors=True)
    print("self-test attacks=%d failed_on_the_named_row=%d clean_commit_rows=%s" % (attacks[0], attacks[1], locals().get("clean_rows", "NA")))
    print("SELF-TEST %s" % ("FAIL" if failed else "PASS"))
    print("publication self-test status=%s arms=%d failed=%d" % ("fail" if failed else "pass", arms[0], len(failed)))
    return 1 if failed else 0


def as_built(check, folder):
    """The gate's catalog-tool expressions, matched against what the real tools beside this file print on the fixture
    repository their own self-tests build - so a stand-in that prints a line typed here is never the only witness."""
    import importlib.util
    tools = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location("catalog_library_under_test", os.path.join(tools, "_process_catalog.py"))
    lib = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = lib
    keep, sys.dont_write_bytecode = sys.dont_write_bytecode, True     # the import leaves no file beside the tools
    try:
        spec.loader.exec_module(lib)
    finally:
        sys.dont_write_bytecode = keep
    from pathlib import Path
    os.makedirs(folder)
    fx = lib.build_fixture_repo(Path(folder) / "repo")
    pattern = os.path.join(tools, "fixtures", "process-catalog", "private-pattern.txt")
    digest = os.path.join(folder, "digest.txt")
    with open(digest, "w", encoding="utf-8") as fh:
        fh.write(sha(open(pattern, "rb").read()) + "\n")
    roots, build, checker = [str(x) for x in fx.args], os.path.join(tools, os.path.basename(BUILD)), os.path.join(tools, os.path.basename(CHECK))

    def real(argv):
        r = subprocess.run([sys.executable, "-B"] + argv, cwd=str(fx.repo), capture_output=True, text=True, env=tool_env({"PYTHONDONTWRITEBYTECODE": "1"}))
        return r.returncode, r.stdout

    before = real([build] + roots[:-2] + ["build", "--check"])
    real([build] + roots[:-2] + ["build"])
    outs = {"generated output": real([build] + roots[:-2] + ["build", "--check"]), "citations": real([build] + roots[:-2] + ["anchors", "resolve", "--check"]),
            "staleness, depicted and cited": real([build] + roots[:-2] + ["stale", "--fail-on", "any"]),
            "page validation": real([checker, "--pattern-arm", "not-run"] + roots + fx.register_args + [str(x) for x in fx.measure_args]),
            "register invariant, pattern arm run": real([checker, "--registers-only", "--pattern-arm", "run", "--private-pattern-file", pattern,
                                                         "--pattern-digest-file", digest] + roots + fx.register_args),
            "register invariant, pattern arm not-run": real([checker, "--registers-only", "--pattern-arm", "not-run"] + roots + fx.register_args)}
    seen = lambda key: (re.search(r"\b%s=([0-9]+)\b" % key, "".join(o for _, o in outs.values())) or [None, "NA"])[1]
    fill = {k: seen(k) for k in ("pages", "generated_files", "register_rows", "registry_rows")}
    for arm in ("run", "not-run"):
        for name, _, _, must in tool_rows(arm)[:5]:
            if name in outs and (arm == "run" or name.endswith("not-run")):
                code, text = outs[name]
                miss = [m for m in must if not re.search(m.format(**fill), text)]
                check("as built: %s - the real tool exits 0 and prints what the row requires" % name, code == 0 and not miss,
                      "exit=%s unmet=%s last=%s" % (code, miss, text.strip().split("\n")[-1:]))
    must = tool_rows("run")[1][3]
    check("as built: a real failing run of the generated-output check does not meet the row", before[0] == 1 and not any(re.search(m.format(**fill), before[1]) for m in must),
          before[1].strip().split("\n")[-1:])
    for rel, needles in sorted(ST_AS_BUILT.items()):
        path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(tools))), rel)
        text = open(path, encoding="utf-8").read() if os.path.isfile(path) else ""
        check("as built: %s still prints the line its row reads" % os.path.basename(rel), all(n in text for n in needles))


if __name__ == "__main__":
    sys.exit(main())
