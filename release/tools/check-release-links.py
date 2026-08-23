#!/usr/bin/env python3
"""
Intra-repo link checker for the markdown corpus.

Walks every markdown file under one or more root directories, parses markdown
links of the form `[text](target)` (and `![alt](target)` image links), and
reports any link target that:

- Resolves to a file that does not exist on disk
- Escapes the repo root (`../` past the top)
- (when --check-anchors) carries a `#fragment` that names no heading in the
  target file, where the fragment is resolved by a faithful github-slugger port

Path resolution (canonical rule, ADR-085 — identical to check-doc-links.py, see
core/standards/doc-link-maintenance-protocol.md § Path resolution): a link
resolves relative to the source file's directory; a leading `/` denotes the
workspace (repo) root; there is NO bare module-prefix fallback (a bare `core/…`
from a non-root file is an ordinary relative path, so it is broken).

Skips (treated as intentional non-links):

- External URLs (`http://`, `https://`, `mailto:`, `tel:`)
- Pure anchors (`#section`)  [resolved in-file only when --check-anchors]
- Template placeholders (`{REPO}`, `<OPERATOR_INSTANCE_*>`, `$VAR`, `~/...`)
- All-caps bareword placeholders (`URL`, `PATH`, `...`)
- Version-string placeholders (`vX.Y`)

NOT skipped: release-plan / release-notes refs. A concrete `_RELEASE_PLAN.md` /
`_RELEASE_NOTES.md` target names a file tracked in this repository under
`release/releases/`, so a link to one that does not resolve is real drift and is
reported like any other broken link. A blanket suffix skip for the three live
filename shapes once suppressed that whole class on the premise that these notes
were instance-side and need not exist in the public tree; the tracked corpus
grew to hold them and the premise stopped being true. The genuine placeholder
forms are still skipped, by the classes above: `vX.Y_RELEASE_NOTES.md` by the
version-string rule and `<slug>_RELEASE_PLAN.md` by the angle-bracket rule.

Backward-compatibility contract:
  Invoked with NO arguments, this script is byte-for-byte equivalent in behavior
  to the original release-only checker: it walks `release/` exactly, checks file
  existence only (anchors and image targets are NOT checked), and exits 0/1 on
  link resolution. All new behavior is opt-in via flags that default OFF.

Exit codes:
  0 — all checked links resolve
  1 — at least one broken link (or, when --check-anchors is hard-failing, a
      missing anchor) found

Usage:
  python3 release/tools/check-release-links.py
  python3 release/tools/check-release-links.py --roots core release docs .github --top-level-md --check-anchors --images
"""
from __future__ import annotations
import argparse
import collections
import re
import sys
import tempfile
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[2]

# Captures both [text](target) and ![alt](target) — the leading `!` (if any) is
# not part of the match, so image links and ordinary links are both seen here.
# Whether an image target is *checked* is governed by --images.
LINK_RE = re.compile(r'(!?)\[[^\]]*\]\(([^)]+)\)')

# Note: a leading `/` is deliberately NOT skipped — per the canonical rule
# (ADR-085; core/standards/doc-link-maintenance-protocol.md § Path resolution) it
# denotes the workspace (repo) root and is resolved in check_file, matching
# check-doc-links.py. Only genuinely off-repo / non-path schemes are skipped here.
SKIP_PREFIXES = ("http://", "https://", "mailto:", "tel:", "#")

PLACEHOLDER_TARGETS = {
    "URL", "PATH", "FILE", "TARGET", "...", "path", "URI", "<URL>",
}


def is_skippable(target: str) -> bool:
    if any(target.startswith(p) for p in SKIP_PREFIXES):
        return True
    if "{" in target or "}" in target:
        return True
    if "<" in target or ">" in target:
        return True
    if target.startswith("$") or target.startswith("~"):
        return True
    if target in PLACEHOLDER_TARGETS:
        return True
    if re.search(r'v[A-Z]\.[A-Z]', target):
        return True
    # NOTE: there is deliberately NO `_RELEASE_PLAN.md` / `_RELEASE_NOTES.md`
    # suffix skip here. A concrete note/plan target names a tracked file under
    # release/releases/, so an unresolvable one is real drift. The placeholder
    # forms that genuinely name no file (`vX.Y_...`, `<slug>_...`) are already
    # caught by the version-string and angle-bracket rules above; do not
    # re-broaden those into a suffix rule.
    return False


# --- github-slugger port (load-bearing; verified faithful across the corpus) ---
# Reproduces GitHub's heading-anchor slug algorithm: lowercase, strip everything
# that is not a Unicode word char / space / hyphen (so `§`, em-dash, emoji,
# periods, parens are dropped), then spaces -> hyphens. A per-file collision
# counter appends `-1`, `-2`, ... to repeated base slugs, matching GitHub's
# duplicate-heading suffixing. Do NOT replace this with a hand-rolled 3-rule
# regex — the Unicode-aware strip + collision counter is what makes it faithful.
HEADING_RE = re.compile(r'^(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$')
# Kramdown explicit-anchor form: `## Heading {#explicit-id}` — GitHub itself does
# not honor `{#id}` in its rendered markdown, so the port mirrors that and such
# headings fall into the warn-mode-absorbed residual class.
INLINE_CODE_RE = re.compile(r'`([^`]*)`')


def github_slug(text: str) -> str:
    s = text.strip().lower()
    s = re.sub(r'[^\w \-]', '', s, flags=re.UNICODE)
    return s.replace(' ', '-')


def heading_text(raw_heading: str) -> str:
    """Strip markdown inline formatting that GitHub removes before slugging.

    GitHub slugs the *rendered* heading text. The constructs that materially
    affect the slug for this corpus are inline-code spans (backticks are dropped
    but their contents are kept) and link syntax `[text](url)` (the visible
    `text` is kept). Emphasis markers (`*`/`_`) are word-adjacent punctuation that
    the `[^\\w \\-]` strip already removes, so they need no pre-pass.
    """
    t = INLINE_CODE_RE.sub(r'\1', raw_heading)
    # [visible](url) -> visible   ;   ![alt](url) -> alt
    t = re.sub(r'!?\[([^\]]*)\]\([^)]*\)', r'\1', t)
    return t


def slug_set(md_text: str) -> set[str]:
    """All heading anchors GitHub would generate for a file, with collision
    suffixing applied in document order."""
    seen: collections.Counter[str] = collections.Counter()
    slugs: set[str] = set()
    in_fence = False
    for line in md_text.splitlines():
        if re.match(r'^[ \t]*```', line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = HEADING_RE.match(line)
        if not m:
            continue
        base = github_slug(heading_text(m.group(2)))
        if not base:
            continue
        n = seen[base]
        slug = base if n == 0 else f"{base}-{n}"
        seen[base] += 1
        slugs.add(slug)
    return slugs


def _line_of(text: str, offset: int) -> int:
    """1-based line number of a character offset in text."""
    return text.count("\n", 0, offset) + 1


def check_file(md: Path, *, check_anchors: bool, images: bool,
               anchor_warns: list[str],
               added: set[int] | None = None) -> list[str]:
    """Return hard-fail findings for one file. Anchor misses are appended to
    anchor_warns (warn-mode) rather than returned as hard fails.

    When `added` is provided (a set of 1-based line numbers added since a diff
    base), a finding is reported ONLY if its source link sits on an added line.
    This is the net-new-delta posture that keeps pre-existing links in a file
    that a PR touches for unrelated reasons from being re-flagged (the same
    added-lines discipline the reference-durability gate uses). With
    `added=None`, every link in the file is considered.
    """
    broken: list[str] = []
    try:
        text = md.read_text()
    except Exception:
        return broken
    # Cache target-file slug sets so a file linked many times is read once.
    slug_cache: dict[Path, set[str]] = {}
    for m in LINK_RE.finditer(text):
        if added is not None and _line_of(text, m.start()) not in added:
            continue   # link is on a pre-existing line — not this PR's concern
        is_image = m.group(1) == "!"
        target = m.group(2).strip()
        if is_image and not images:
            continue
        if is_skippable(target):
            continue
        target_path, _, frag = target.partition("#")
        target_path = unquote(target_path).strip()
        if not target_path:
            # Pure in-file anchor (`#frag`) — only meaningful with --check-anchors,
            # resolved against THIS file's own headings.
            if check_anchors and frag:
                this_slugs = slug_cache.get(md)
                if this_slugs is None:
                    this_slugs = slug_set(text)
                    slug_cache[md] = this_slugs
                if unquote(frag) not in this_slugs:
                    anchor_warns.append(
                        f"  missing-anchor (in-file): {target} "
                        f"-> #{unquote(frag)} not a heading in {md.name}")
            continue
        if target_path.startswith("/"):
            # Canonical rule clause 2 (ADR-085): a leading `/` denotes the
            # workspace (repo) root, matching GitHub's rendered-blob behavior and
            # check-doc-links.py. Anchor explicitly on REPO_ROOT — joining an
            # absolute path via `md.parent / target_path` would reset to the
            # filesystem root and then read as "escapes repo root".
            resolved = (REPO_ROOT / target_path.lstrip("/")).resolve()
        else:
            resolved = (md.parent / target_path).resolve()
        try:
            resolved.relative_to(REPO_ROOT)
        except ValueError:
            broken.append(f"  escapes repo root: {target}")
            continue
        if not resolved.exists():
            broken.append(f"  broken: {target} -> {resolved.relative_to(REPO_ROOT)}")
            continue
        if check_anchors and frag and resolved.is_file():
            target_slugs = slug_cache.get(resolved)
            if target_slugs is None:
                try:
                    target_slugs = slug_set(resolved.read_text())
                except Exception:
                    target_slugs = set()
                slug_cache[resolved] = target_slugs
            if unquote(frag) not in target_slugs:
                anchor_warns.append(
                    f"  missing-anchor: {target} -> #{unquote(frag)} "
                    f"not a heading in {resolved.relative_to(REPO_ROOT)}")
    return broken


# --- Depth-invariance lint for pre-claim release plans ----------------------
# A release plan is authored at `release/releases/plans/<slug>_RELEASE_PLAN.md`
# and ships at `release/releases/plans/v<MAJOR>/<tag>_RELEASE_PLAN.md`: the
# ADR-092 claim-time stamp in claim-version.sh git-mv's it ONE DIRECTORY DEEPER
# partway through its life. Every relative link inside it therefore carries two
# different meanings -- one while the plan is authored and reviewed, another
# once it ships -- and NO relative form is correct at both depths:
#
#     ../../references/...     resolves at plans/ , breaks   at plans/v4/
#     ../../../references/...  breaks   at plans/ , resolves at plans/v4/
#     /release/references/...  resolves at BOTH             (ADR-085 clause 2)
#
# The ordinary existence check evaluates a file at the path it currently
# occupies, so a plan whose links are correct at authoring depth passes every
# pre-merge gate and only breaks after the stamp -- surfacing on the Stage-12
# chore PR, post-merge. v4.06 and v4.38 both shipped that way and were fixed
# forward. This lint asserts the depth-INVARIANT form rather than the
# resolution, so the defect is caught on the release PR while the fix is still
# one line.
PLAN_DIR_REL = "release/releases/plans"
PLAN_SUFFIX = "_RELEASE_PLAN.md"


def is_preclaim_plan(md: Path) -> bool:
    """True for a release plan sitting at AUTHORING depth -- directly in
    `release/releases/plans/`, not yet moved into `plans/v<MAJOR>/` by the
    claim-time stamp.

    A plan already nested under `v<MAJOR>/` will not move again, so its relative
    links are stable and out of scope. `plans/README.md` is likewise out of
    scope: it documents the directory, is not a plan, and never moves -- keying
    on the `_RELEASE_PLAN.md` suffix rather than on "any .md under plans/" is
    what keeps its nine relative links from reading as findings."""
    try:
        rel = md.resolve().relative_to(REPO_ROOT)
    except ValueError:
        return False
    return rel.parent.as_posix() == PLAN_DIR_REL and rel.name.endswith(PLAN_SUFFIX)


def check_plan_depth(md: Path, *, added: set[int] | None = None) -> list[str]:
    """Return depth-sensitivity findings for one pre-claim release plan.

    Reports every intra-repo link target that is NOT workspace-rooted, because
    each one resolves differently once the plan moves a directory deeper -- a
    `../` form and a bare same-directory form alike. The skip classes are shared
    with check_file, so external URLs, pure anchors and template placeholders are
    untouched, and `added` applies the same net-new-delta posture."""
    findings: list[str] = []
    try:
        text = md.read_text()
    except Exception:
        return findings
    for m in LINK_RE.finditer(text):
        if added is not None and _line_of(text, m.start()) not in added:
            continue
        target = m.group(2).strip()
        if is_skippable(target):
            continue
        target_path, _, _frag = target.partition("#")
        target_path = unquote(target_path).strip()
        if not target_path:
            continue          # pure in-file anchor -- travels with the file
        if target_path.startswith("/"):
            continue          # workspace-rooted -- the prescribed, invariant form
        findings.append(
            f"  depth-sensitive: {target} -> resolves differently once the "
            f"ADR-092 claim-time stamp moves this plan into "
            f"{PLAN_DIR_REL}/v<MAJOR>/; write it workspace-rooted "
            f"(/release/..., /core/...) so one form is correct at both depths")
    return findings


def added_lines_for(md: Path, diff_base: str) -> set[int]:
    """1-based line numbers in `md` (head/working version) that are net-new
    since `diff_base`, computed from the unified diff's hunk headers. An empty
    set means no added lines (the file is unchanged or only had deletions)."""
    import subprocess
    rel = md.resolve()
    try:
        rel = rel.relative_to(REPO_ROOT)
    except ValueError:
        return set()
    try:
        out = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "diff", "--unified=0",
             f"{diff_base}...HEAD", "--", str(rel)],
            capture_output=True, text=True, check=False).stdout
    except Exception:
        return set()
    added: set[int] = set()
    new_ln = 0
    for line in out.splitlines():
        if line.startswith("@@"):
            # @@ -a,b +c,d @@  -> new-file hunk starts at c
            try:
                plus = line.split("+", 1)[1]
                start = plus.split(maxsplit=1)[0]
                c = start.split(",")[0]
                new_ln = int(c)
            except (IndexError, ValueError):
                new_ln = 0
        elif line.startswith("+") and not line.startswith("+++"):
            if new_ln:
                added.add(new_ln)
                new_ln += 1
        elif line.startswith("-") and not line.startswith("---"):
            pass  # deletions do not advance the new-file counter
    return added


def is_test_fixture(path: Path) -> bool:
    """True for markdown that is TEST DATA rather than corpus prose.

    A `.md` file under `**/tests/fixtures/**` is an INPUT to a test, not a document
    anyone navigates. Its links are payload: the blast-radius doc-tracer fixture, for
    instance, needs `[t](docs/target.md)` in its frozen corpus precisely so the tracer
    has a reference edge to find, and that target is resolved relative to the fixture's
    own scan root at test time — not relative to the repo. Resolving it as a corpus link
    is a category error, and "fixing" it would corrupt the fixture the test depends on.

    This mirrors the exclusion the corpus checks in core/deploy/deploy.sh already apply
    to `**/tests/fixtures/**`; this checker simply had not needed it before, because no
    fixture markdown had carried a link.

    Deliberately NARROW: it requires BOTH a `tests` and a `fixtures` path segment, and
    `fixtures` must follow `tests`. A stray directory merely named `fixtures` elsewhere
    in the tree is still checked.
    """
    parts = path.parts
    for i, seg in enumerate(parts[:-1]):
        if seg == "tests" and "fixtures" in parts[i + 1:-1]:
            return True
    return False


def iter_markdown(roots: list[str], top_level_md: bool,
                  only: set[Path] | None = None):
    """Yield markdown files under each root dir, plus top-level *.md when asked.

    Markdown under `**/tests/fixtures/**` is skipped — see is_test_fixture().

    When `only` is provided (the resolved paths of a changed-files set), the
    walk is intersected with it: a file is yielded only if it both falls under
    an in-scope root (or is a top-level *.md when --top-level-md) AND appears in
    `only`. This is how the PR-time dead-file-ref gate scans the delta only —
    pre-existing corpus rot in unchanged files is never re-flagged (the
    drainage-is-out-of-release principle). With `only=None` (the bare
    invocation) the full root walk is preserved unchanged.
    """
    seen: set[Path] = set()
    for root in roots:
        root_dir = (REPO_ROOT / root).resolve()
        if not root_dir.exists():
            continue
        for md in sorted(root_dir.rglob("*.md")):
            if md in seen:
                continue
            if only is not None and md not in only:
                continue
            if is_test_fixture(md):
                continue
            seen.add(md)
            yield md
    if top_level_md:
        for md in sorted(REPO_ROOT.glob("*.md")):
            if md in seen:
                continue
            if only is not None and md not in only:
                continue
            seen.add(md)
            yield md


# A note-shaped filename that must never exist on disk. Used as the negative arm
# of the fail-closed fixture in run_self_test; if a real note is ever given this
# name the fixture asserts loudly rather than passing vacuously.
SELF_TEST_ABSENT_NOTE = "v0.00-self-test-absent_RELEASE_NOTES.md"


def run_self_test() -> int:
    """In-process smoke test for is_skippable — the skip predicate the release
    dead-file-ref gate + release-link-check.yml both consume.

    The load-bearing case is that release-plan / release-notes link targets are
    CHECKED, not skipped. A concrete `_RELEASE_PLAN.md` / `_RELEASE_NOTES.md`
    target names a file tracked in this repository under `release/releases/`, so
    a link to one that does not resolve is real drift. A blanket suffix skip
    covering the three live filename shapes (versioned, version-less/theme-named,
    hybrid) once suppressed that whole class, on the premise that these notes
    were instance-side and need not exist in the public tree. The tracked corpus
    grew to hold them and the premise stopped being true, so the rule was
    removed and this test was inverted with it.

    Both arms are pinned, because a skip predicate can fail in two directions:
    the concrete shapes MUST be checkable (under-arming would restore the
    suppression), and the genuine placeholder forms MUST still skip
    (over-arming would flood the gate with template text). A third fixture runs
    the predicate through check_file end-to-end, so the assertions cannot pass
    on a boolean that never reaches the existence check.
    """
    # ── The three live release-plan/notes filename shapes — ALL checkable ──
    # These name real tracked files under release/releases/. A link to one that
    # does not resolve is drift, so is_skippable must NOT swallow them.
    plan_note_shapes = [
        # versioned
        "release/releases/notes/v3.56_RELEASE_NOTES.md",
        "release/releases/plans/v3.56_RELEASE_PLAN.md",
        # version-less / theme-named
        "release/releases/plans/pda-rollup-and-portfolio_RELEASE_PLAN.md",
        "release/releases/notes/declarative-gating-model_RELEASE_NOTES.md",
        # hybrid (version prefix + hyphen-slug)
        "release/releases/plans/v3.72-release-hub-mode-r-and-o_RELEASE_PLAN.md",
        # bare filename (no directory)
        "v1.24_RELEASE_NOTES.md",
    ]
    for t in plan_note_shapes:
        assert not is_skippable(t), \
            f"self-test: release-plan/notes ref must be CHECKED, not skipped: {t!r}"

    # ── Specificity guard: the genuine placeholder forms MUST still skip ──
    # This is the anti-over-arming arm. `vX.Y` is a version-string template and
    # `<slug>` an angle-bracket placeholder; neither names a file on disk, and
    # both are caught by pre-existing skip classes the rule removal left intact.
    # If this arm ever fails, the checker has started reporting template prose.
    placeholder_note_shapes = [
        "release/releases/notes/vX.Y_RELEASE_NOTES.md",
        "release/releases/plans/vX.Y_RELEASE_PLAN.md",
        "release/releases/notes/<slug>_RELEASE_NOTES.md",
        "release/releases/plans/<version>_RELEASE_PLAN.md",
    ]
    for t in placeholder_note_shapes:
        assert is_skippable(t), \
            f"self-test: placeholder note/plan form must still skip: {t!r}"

    # ── Regression guard: ordinary links MUST NOT be over-skipped ──
    # These are RELEASE-adjacent filenames that a future re-broadening of the
    # skip classes could plausibly swallow — the last two are the near-misses
    # that a loosely-written token rule catches by accident. They were pinned
    # when the note/plan suffix skip existed and stay pinned now that it does
    # not, because the shape they guard against is a suffix/token rule of any
    # generation, not that one rule in particular.
    not_skippable = [
        "release/references/pipeline/stage-13-close.md",
        "../governance/RELEASE_PROTOCOL.md",
        "release/releases/RELEASE_LOG.md",
        "docs/RELEASE_PLANNING.md",   # RELEASE_PLAN not immediately followed by .md
        "guide_release_plan.md",      # lowercase — not the RELEASE_PLAN token
    ]
    for t in not_skippable:
        assert not is_skippable(t), \
            f"self-test: ordinary link wrongly skipped (over-skip): {t!r}"

    # ── Pre-existing skip classes still hold ──
    for t in ["https://example.com/x", "#anchor", "mailto:a@b.c",
              "{REPO}/x.md", "<OPERATOR_INSTANCE_LOG>", "$VAR/x.md",
              "~/x.md", "URL", "...", "vX.Y"]:
        assert is_skippable(t), f"self-test: pre-existing skip class regressed: {t!r}"
    # ...and a plain relative link in that same neighborhood is still checked.
    assert not is_skippable("stage-02-triage.md"), \
        "self-test: a plain relative link must remain checkable"

    # ── Test-fixture path exclusion, with its own over-skip guard ──
    # A skip that is not itself tested can broaden silently and swallow a real link,
    # so both arms are pinned: what MUST be excluded, and what must NOT be.
    fixture_paths = [
        "release/tools/tests/fixtures/blast-radius-f1/corpus/docs/a.md",
        "release/tools/tests/fixtures/deciders-carveout/x.md",
        "core/deploy/tests/fixtures/nested/deep/y.md",
    ]
    for p in fixture_paths:
        assert is_test_fixture(Path(p)), \
            f"self-test: expected test-fixture markdown to be excluded: {p!r}"

    # Over-skip guard — these are corpus prose and MUST still be checked. A predicate
    # that returned True here would silently drop real documents from the scan.
    not_fixture_paths = [
        "release/references/pipeline/stage-06-engineering.md",
        "core/disciplines/architecture-overview.md",
        "release/tools/tests/README.md",              # under tests/, but not in fixtures/
        "docs/fixtures/setup.md",                     # a 'fixtures' dir with no 'tests' parent
        "release/tools/tests/fixtures.md",            # a FILE named fixtures, not a directory
    ]
    for p in not_fixture_paths:
        assert not is_test_fixture(Path(p)), \
            f"self-test: corpus markdown wrongly excluded as a fixture (over-skip): {p!r}"

    # ── Fail-closed fixture — end-to-end, both arms ──────────────────────────
    # The assertions above test a boolean. This one runs a note link through
    # check_file, so a predicate that says "not skippable" but never reaches the
    # existence check cannot pass silently. Two links in one probe file:
    #   negative arm — a note-shaped target naming no file MUST be reported
    #   positive arm — a note-shaped target naming a real tracked note MUST NOT
    # If the positive arm were wrongly skipped the finding count would still be
    # 1, so it is pinned separately against is_skippable rather than inferred.
    #
    # Both links use the leading-`/` workspace-root form (ADR-085 clause 2), so
    # they resolve against REPO_ROOT while the probe file itself lives in the OS
    # temp dir — this self-test writes nothing inside the repository.
    notes_dir = REPO_ROOT / "release" / "releases" / "notes"
    absent_note = notes_dir / SELF_TEST_ABSENT_NOTE
    assert not absent_note.exists(), (
        f"self-test: the fail-closed fixture's negative arm names a file that "
        f"now EXISTS ({SELF_TEST_ABSENT_NOTE!r}) — rename it, or the fixture "
        f"proves nothing")
    real_note = next(iter(sorted(notes_dir.rglob("*_RELEASE_NOTES.md"))), None)
    assert real_note is not None, (
        "self-test: no *_RELEASE_NOTES.md found under release/releases/notes/ — "
        "the fail-closed fixture has no positive arm and cannot be trusted")
    real_target = "/" + real_note.relative_to(REPO_ROOT).as_posix()
    absent_target = "/" + absent_note.relative_to(REPO_ROOT).as_posix()
    assert not is_skippable(real_target), \
        f"self-test: the fixture's positive arm is being skipped: {real_target!r}"
    assert not is_skippable(absent_target), \
        f"self-test: the fixture's negative arm is being skipped: {absent_target!r}"

    with tempfile.TemporaryDirectory() as td:
        probe = Path(td) / "fail-closed-probe.md"
        probe.write_text(
            f"[absent]({absent_target})\n[present]({real_target})\n",
            encoding="utf-8")
        probe_warns: list[str] = []
        findings = check_file(probe, check_anchors=False, images=False,
                              anchor_warns=probe_warns)
    assert len(findings) == 1, (
        f"self-test: fail-closed fixture expected exactly 1 finding "
        f"(the absent note); got {len(findings)}: {findings!r}")
    assert SELF_TEST_ABSENT_NOTE in findings[0], (
        f"self-test: fail-closed fixture reported the wrong link: {findings[0]!r}")

    # -- Depth-invariance lint: predicate scope + both finding arms ---------
    # Two failure directions, both pinned. Under-arming would let a depth-
    # sensitive link ship (the v4.06 / v4.38 defect this lint exists to catch);
    # over-arming would flag the plans/ README, an already-stamped plan, or an
    # ordinary skip class, and a noisy gate gets abandoned. Path predicates are
    # pure, so the scope arms need no files on disk; the finding arms run on
    # temp probes, so this self-test still writes nothing inside the repository.
    plans_dir = REPO_ROOT / PLAN_DIR_REL
    for in_scope in (plans_dir / "v9.99_RELEASE_PLAN.md",
                     plans_dir / "some-theme-name_RELEASE_PLAN.md"):
        assert is_preclaim_plan(in_scope), \
            f"self-test: pre-claim plan must be in depth-lint scope: {in_scope!r}"
    for out_of_scope in (
            plans_dir / "v4" / "v4.38_RELEASE_PLAN.md",  # stamped -- never moves again
            plans_dir / "README.md",                     # directory README, not a plan
            REPO_ROOT / "release" / "references" / "pipeline" / "stage-04-planning.md",
            REPO_ROOT / "release" / "releases" / "notes" / "v3.18_RELEASE_NOTES.md"):
        assert not is_preclaim_plan(out_of_scope), \
            f"self-test: file wrongly pulled into depth-lint scope: {out_of_scope!r}"

    with tempfile.TemporaryDirectory() as td:
        # Negative arm -- every non-workspace-rooted intra-repo form is reported,
        # the bare same-directory form included (it re-points into plans/v<N>/).
        flagged_probe = Path(td) / "depth-flagged-probe.md"
        flagged_probe.write_text(
            "[a](../../references/standards/release-notes-standard.md)\n"
            "[b](../../../governance/RELEASE_PROTOCOL.md)\n"
            "[c](sibling_RELEASE_PLAN.md)\n",
            encoding="utf-8")
        flagged_findings = check_plan_depth(flagged_probe)
        # Positive arm -- the prescribed form and the ordinary skip classes are
        # silent. Each line here is a near-miss the lint must NOT flag.
        clean_probe = Path(td) / "depth-clean-probe.md"
        clean_probe.write_text(
            "[a](/release/references/standards/release-notes-standard.md)\n"
            "[b](/core/governance/OPERATIONS.md)\n"
            "[c](https://example.com/x)\n"
            "[d](#in-file-anchor)\n"
            "[e](<slug>_RELEASE_PLAN.md)\n"
            "[f](release/releases/notes/vX.Y_RELEASE_NOTES.md)\n",
            encoding="utf-8")
        clean_findings = check_plan_depth(clean_probe)
    assert len(flagged_findings) == 3, (
        f"self-test: depth lint expected 3 findings (two ../ forms + one bare "
        f"same-dir form); got {len(flagged_findings)}: {flagged_findings!r}")
    assert not clean_findings, (
        f"self-test: depth lint flagged the prescribed workspace-rooted form or "
        f"an ordinary skip class: {clean_findings!r}")

    print("self-test OK (release-plan/notes refs are checked not skipped, "
          "placeholder forms still skip, fail-closed fixture reports the "
          "absent note, skip classes + test-fixture path exclusion hold, "
          "plan depth-invariance lint scopes and fires correctly)")
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Intra-repo markdown link (and optional anchor/image) checker.")
    p.add_argument(
        "--roots", nargs="+", default=["release"],
        help="Root directories to walk (default: release). Each is walked "
             "recursively for *.md files.")
    p.add_argument(
        "--top-level-md", action="store_true",
        help="Also check top-level *.md files at the repo root (e.g. README.md).")
    p.add_argument(
        "--check-anchors", action="store_true",
        help="Also resolve #fragment anchors against target-file headings using "
             "the github-slugger port. Findings are warn-mode (do NOT fail the "
             "run) during calibration. Default OFF.")
    p.add_argument(
        "--images", action="store_true",
        help="Also check ![alt](path) image targets for existence. Default OFF "
             "(image targets are parsed but not checked).")
    p.add_argument(
        "--anchors-hard-fail", action="store_true",
        help="Promote missing-anchor findings from warn-mode to hard failures "
             "(exit 1). Default OFF; calibration ships anchors in warn-mode.")
    p.add_argument(
        "--files", nargs="*", default=None,
        help="Restrict checking to this explicit set of files (repo-relative or "
             "absolute paths), intersected with --roots/--top-level-md scope. "
             "Used by the PR-time dead-file-ref gate to scan only the changed "
             "delta so pre-existing rot in unchanged files is not re-flagged. "
             "Omit (default) to walk the full roots — the bare-invocation "
             "contract.")
    p.add_argument(
        "--diff-base", default=None,
        help="A git ref/SHA. When set, only links on lines ADDED since this base "
             "(base...HEAD) are checked, so pre-existing links in a file the PR "
             "touched for unrelated reasons are not re-flagged — the same net-new "
             "added-lines posture the reference-durability gate uses. Omit "
             "(default) to consider every link in the in-scope files.")
    p.add_argument(
        "--plan-depth-lint", action="store_true",
        help="Also assert that pre-claim release plans (files directly in "
             "release/releases/plans/ named *_RELEASE_PLAN.md) carry only "
             "workspace-rooted intra-repo links, so a link stays correct after "
             "the ADR-092 claim-time stamp moves the plan into plans/v<MAJOR>/. "
             "Default OFF -- the bare-invocation contract is unchanged.")
    p.add_argument(
        "--self-test", action="store_true",
        help="Run the in-process is_skippable smoke test (release-plan/notes "
             "filename-shape consistency + skip-class regression guards) and exit.")
    return p.parse_args(argv)


def resolve_only(files: list[str] | None) -> set[Path] | None:
    """Resolve a changed-files list to absolute paths under the repo. Files that
    are not *.md or escape the repo are dropped (the gate only checks markdown).
    Returns None when no --files was supplied (full-walk mode)."""
    if files is None:
        return None
    out: set[Path] = set()
    for raw in files:
        raw = raw.strip()
        if not raw or not raw.endswith(".md"):
            continue
        p = Path(raw)
        resolved = p.resolve() if p.is_absolute() else (REPO_ROOT / raw).resolve()
        try:
            resolved.relative_to(REPO_ROOT)
        except ValueError:
            continue
        out.add(resolved)
    return out


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.self_test:
        return run_self_test()
    only = resolve_only(args.files)
    total_broken = 0
    files_with_broken = 0
    anchor_warns: list[str] = []
    depth_findings: list[str] = []
    depth_total = 0
    for md in iter_markdown(args.roots, args.top_level_md, only=only):
        added = added_lines_for(md, args.diff_base) if args.diff_base else None
        if added is not None and not added:
            continue   # no net-new lines in this file — nothing to check
        broken = check_file(
            md, check_anchors=args.check_anchors, images=args.images,
            anchor_warns=anchor_warns, added=added)
        if broken:
            files_with_broken += 1
            total_broken += len(broken)
            print(f"\n{md.relative_to(REPO_ROOT)}:")
            for b in broken:
                print(b)
        if args.plan_depth_lint and is_preclaim_plan(md):
            depth = check_plan_depth(md, added=added)
            if depth:
                depth_total += len(depth)
                depth_findings.append(
                    f"\n{md.relative_to(REPO_ROOT)}:\n" + "\n".join(depth))
    print(f"\n=== {total_broken} broken links across {files_with_broken} files ===")
    if args.plan_depth_lint:
        # Printed even at zero: a lint that is silent when clean is
        # indistinguishable from a lint that never ran.
        print(f"\n=== {depth_total} depth-sensitive plan links across "
              f"{len(depth_findings)} files ===")
        for d in depth_findings:
            print(d)
    if args.check_anchors and anchor_warns:
        label = "MISSING ANCHORS (hard-fail)" if args.anchors_hard_fail \
            else "missing anchors (warn-mode — not failing the run)"
        print(f"\n=== {len(anchor_warns)} {label} ===")
        for w in anchor_warns:
            print(w)
    fail = (total_broken > 0 or depth_total > 0
            or (args.anchors_hard_fail and bool(anchor_warns)))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
