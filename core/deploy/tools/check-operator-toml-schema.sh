#!/bin/bash
# check-operator-toml-schema.sh — Check 70 predicate: core/config/operator-toml-schema.json
# is the ONE place the operator.toml key set is declared, and everything downstream agrees
# with it.
#
# WHAT IT ASSERTS. Three legs, two populations, two modes:
#
#   C70a  the live operator.toml carries every key the declaration marks `delivered`.
#         Population: OPERATOR INSTANCE STATE (~/.config/pmo-platform/operator.toml).
#         Mode: WARN. An operator whose instance is behind is not a repo defect and must
#         never red-wall their deploy — that punishes the victim of the bug. Each miss
#         reports the key, the version it shipped in, and the remedy command.
#
#   C70b  no hand-written per-key emit survives beside the derivation loop in
#         write_operator_toml. Population: tracked repo files. Mode: ENFORCE.
#         This is the anti-drift teeth. Because the generator DERIVES from the
#         declaration, this leg should be tautologically true — that is the point. It
#         exists to catch a future hand-edit that re-introduces a literal emit and
#         quietly re-creates the shadow SSOT the declaration exists to prevent. It is
#         the falsifier for the invariant the whole design rests on.
#
#   C70c  the declaration's full key set equals operator.toml.template's key set, BOTH
#         DIRECTIONS. Population: tracked repo files. Mode: ENFORCE.
#         The template stays hand-authored — 437 lines of per-key operator-facing prose
#         is the artifact's value and generating it would be a lossy rewrite. This leg
#         is what keeps "what exists" (the declaration) and "what it means" (the
#         template) from drifting apart without forcing one to generate the other.
#
#   C70d  the THIRD registry agrees with the other two. Population: tracked repo files.
#         Mode: ENFORCE.
#         The operator-instance vocabulary is declared in THREE places, not two: the
#         depersonalization-spec.md §4 table (the registry deploy.sh Check 44 actually
#         reads at runtime), operator.toml.template, and the declaration. C70c asserts
#         the second against the third. Nothing asserted either against the FIRST, and
#         they had already drifted: §4 codified <OPERATOR_INSTANCE_ANALYSIS_PATH> — 91
#         corpus references — while both config registries omitted it entirely.
#         This leg closes that seam, all three directions, naming the token and every
#         surface it is missing from.
#
#         WHY THIS IS A REGISTRY-TO-REGISTRY ASSERTION AND NOT A CORPUS ONE. It would be
#         a category error to widen this into "every angle token in the corpus must be
#         registered". ADR-154 decided the opposite and the spec says so in its own
#         words: the square family is closed and gating, the ANGLE family is open and
#         incrementally codified, so an un-codified angle token in corpus is SANCTIONED
#         and a gate failing on it would fail correct work — measured at 239 findings
#         across 17 spec-sanctioned tokens. Closure is true BETWEEN THE REGISTRIES and
#         false over corpus usage. This leg asserts only where closure holds.
#
#   C70e  a NEWLY AUTHORED angle token carries a §4 table row in the SAME change.
#         Population: the added lines of a pull-request diff. Mode: ENFORCE (see below).
#         This is the one obligation §4 does impose on the open family, and it is a
#         property of a DIFF, not of a working tree — which is why no deploy-time check
#         can carry it and why ADR-154 recorded it as deferred rather than shipping a
#         stored tolerated-set (a list the violating change may edit in the same diff
#         buys the word "ratchet" and not the property).
#
#         THE BASE-ABSENCE TEST IS WHAT KEEPS THIS HONEST. "Newly authored" means the
#         token is absent from the corpus at the BASE commit — not merely that a line
#         mentioning it was added. A diff adding another reference to an already-present
#         un-codified token is exactly the incremental use §4 sanctions, and firing on it
#         would reproduce the failure C70d's comment above describes.
#
#         ENFORCING, NOT BLOCKING. A finding exits non-zero and turns the CI job red.
#         Whether red BLOCKS a merge is branch-protection required-context registration —
#         repository configuration, not readable from this tree, and an operator action.
#         Stated rather than implied, because a check that quietly does not block is
#         indistinguishable from one that does until the day it matters.
#
# WHY A PRIMITIVE RATHER THAN AN INLINE deploy.sh BLOCK. THREE consumers share this one
# predicate — deploy.sh Check 70, the repo-integrity CI job, and update.sh Phase 2. Three
# call sites re-encoding one predicate is how the two lists this card deletes drifted in
# the first place. Check 69 established the convention (a tool under core/deploy/tools/
# carrying --self-test, control arms first, a DENOM line); this follows it.
#
# WHY update.sh CALLS THIS INSTEAD OF PARSING JSON ITSELF. update.sh carries ZERO JSON
# parsers — 0 jq, 0 python3, 0 node; it reads TOML with grep and awk. Putting a JSON parse
# inside it would add a runtime dependency to the lighter of the two update paths, and a
# missing parser inside a || true-tolerant bash phase yields an EMPTY delta, which is
# indistinguishable from "already reconciled" — reproducing the exact inertness this card
# exists to remove. So the delta computation lives HERE, update.sh calls --emit-delta, and
# an unresolvable parser is a LOUD non-zero (exit 3), never a quiet exit 0.
#
# THE CONTROL ARM IS BUILT INTO THE VERDICT, NOT BOLTED BESIDE IT. Every leg counts its
# population before it reports a finding count. A declaration that parses to zero keys, a
# template that parses to zero keys, or a generator source that cannot be located is a
# SCAN-ERROR (exit 3), never a clean zero. A zero whose control arm also returned zero is
# a broken probe, not an empty population.
#
# DECLARED COVERAGE BOUNDARY — state it, do not imply more. This gate asserts the KEY SET
# and the absence of a hand-written emit. It does NOT assert:
#   * that a declared `enum` constrains the value an operator actually set — enum is
#     declared for the settings-manager consumer and is NOT yet enforced anywhere;
#   * that a declared `type` matches the type of a value already on disk;
#   * that the canonical default named in a key's `description` is the one the resolver
#     returns (that is CIAC-2's job, and it spans two cards);
#   * anything about opt-in keys in the live config — they are outside the coverage set
#     by construction.
#
# EXIT CODES (the corpus's three-value contract):
#   0  clean
#   1  one or more findings (one FAIL line each; WARN lines do not set this)
#   3  input failure / broken probe — declaration unreadable, zero keys extracted,
#      generator source not found, a §4 table parsing to zero rows, an unresolvable
#      diff base, or python3/git unavailable. NEVER a clean zero.
#
# USAGE
#   bash core/deploy/tools/check-operator-toml-schema.sh                # all repo+instance legs
#   bash core/deploy/tools/check-operator-toml-schema.sh --repo-integrity  # C70b + C70c + C70d
#   bash core/deploy/tools/check-operator-toml-schema.sh --instance     # C70a (warn)
#   bash core/deploy/tools/check-operator-toml-schema.sh --emit-delta   # for update.sh
#   bash core/deploy/tools/check-operator-toml-schema.sh --self-test    # fixture arms
#   bash core/deploy/tools/check-operator-toml-schema.sh --root <dir>   # another work tree
#   bash core/deploy/tools/check-operator-toml-schema.sh --diff-base <ref>  # C70e (PR-time)

set -uo pipefail

ROOT="${PWD}"
CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"

REL_DECL="core/config/operator-toml-schema.json"
REL_TEMPLATE="core/config/operator.toml.template"
REL_GENERATOR="docs/scripts/setup-workspace.sh"
# The THIRD registry. deploy.sh Check 44 reads this same file as its runtime
# vocabulary; C70d/C70e read it here so the gate and the spec cannot disagree.
REL_SPEC="core/standards/depersonalization-spec.md"
DIFF_BASE=""

# python3 is the parser. It is a hard preflight dependency of setup-workspace.sh
# already; an absence here is a LOUD failure so a caller can never read it as clean.
require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "SCAN-ERROR: python3 not found — cannot parse ${REL_DECL}. Refusing to report a"
    echo "SCAN-ERROR: clean result from a probe that never ran."
    return 3
  fi
  return 0
}

# ─── the shared extractor ─────────────────────────────────────────────────────
# One python program, four verbs. Keeping the parse in ONE place is the same
# discipline that motivates the primitive itself.
run_probe() {
  local verb="$1"
  S_VERB="${verb}" \
  S_DECL="${ROOT}/${REL_DECL}" \
  S_TEMPLATE="${ROOT}/${REL_TEMPLATE}" \
  S_GENERATOR="${ROOT}/${REL_GENERATOR}" \
  S_SPEC="${ROOT}/${REL_SPEC}" \
  S_ROOT="${ROOT}" \
  S_BASE="${DIFF_BASE}" \
  S_LIVE="${CONFIG_ROOT}/operator.toml" \
  python3 -c '
import json, os, re, subprocess, sys

verb = os.environ["S_VERB"]
decl_path = os.environ["S_DECL"]

try:
    with open(decl_path, "r") as f:
        schema = json.load(f)
except (IOError, OSError, ValueError) as e:
    print("SCAN-ERROR: cannot read declaration {}: {}".format(decl_path, e))
    sys.exit(3)

declared = []          # (section, key, since, delivered)
delivered = []
for sec in schema.get("sections", []):
    sd = sec.get("delivery", "delivered")
    for k in sec.get("keys", []):
        kd = k.get("delivery", sd)
        declared.append((sec["name"], k["key"], k.get("since", "?"), kd == "delivered"))
        if kd == "delivered":
            delivered.append((sec["name"], k["key"], k.get("since", "?")))

# CONTROL ARM, before any verdict. A declaration that parses to zero keys would make
# every leg below report a vacuous clean.
if not declared:
    print("SCAN-ERROR: declaration parsed to ZERO keys; extractor is not reaching the")
    print("SCAN-ERROR: population. This is a broken probe, not an empty one.")
    sys.exit(3)

def parse_toml_keys(path):
    keys = []
    section = None
    with open(path, "r") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            if s.startswith("[") and s.endswith("]") and not s.startswith("[["):
                section = s[1:-1].strip()
                continue
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=", s)
            if m and section is not None:
                keys.append((section, m.group(1)))
    return keys

# TABLE-SCOPED, exactly as deploy.sh Check 44 reads the same file: only the FIRST
# CELL of a markdown table row registers. That is not a stylistic choice — it is
# what excludes the §4 schema metavariable  <OPERATOR_INSTANCE_X_PATH>  BY  # depersonalization-token: allow — naming the metavariable this read excludes; it is prose here exactly as it is prose there
# CONSTRUCTION rather than by a name-specific exception a future edit must
# remember. Prose mentions, including the Convention-scope clause that names
# un-codified tokens as examples, do not register.
ANGLE_ROW = re.compile(r"^\|\s*`<([A-Z][A-Z0-9_]*)>`\s*\|", re.M)
SQUARE_ROW = re.compile(r"^\|\s*`\[([A-Z][A-Z0-9_]*)\]`\s*\|", re.M)

def read_spec(path):
    try:
        with open(path, "r") as f:
            return f.read()
    except (IOError, OSError) as e:
        print("SCAN-ERROR: cannot read the vocabulary registry {}: {}".format(path, e))
        sys.exit(3)

findings = 0

if verb in ("repo", "all"):
    # ---- C70c: declaration <-> template parity, BOTH directions ----
    tpl_path = os.environ["S_TEMPLATE"]
    try:
        tpl = parse_toml_keys(tpl_path)
    except (IOError, OSError) as e:
        print("SCAN-ERROR: cannot read template {}: {}".format(tpl_path, e))
        sys.exit(3)
    if not tpl:
        print("SCAN-ERROR: template parsed to ZERO keys; broken probe.")
        sys.exit(3)
    tpl_set = set(tpl)
    decl_set = set((s, k) for (s, k, _, _) in declared)
    only_decl = sorted(decl_set - tpl_set)
    only_tpl = sorted(tpl_set - decl_set)
    for (s, k) in only_decl:
        print("FAIL: [{}].{} is declared in {} but ABSENT from {} — the template is the"
              " operator-facing prose for every declared key.".format(s, k, "the schema", "operator.toml.template"))
        findings += 1
    for (s, k) in only_tpl:
        print("FAIL: [{}].{} is documented in operator.toml.template but ABSENT from the"
              " declaration — an undeclared key cannot be emitted, checked, or"
              " reconciled.".format(s, k))
        findings += 1
    print("DENOM: C70c compared {} declared key(s) against {} template key(s); CONTROL both"
          " populations non-zero, so the {} finding(s) above are readable.".format(
              len(decl_set), len(tpl_set), len(only_decl) + len(only_tpl)))

    # ---- C70b: no hand-written per-key emit beside the derivation loop ----
    gen_path = os.environ["S_GENERATOR"]
    try:
        with open(gen_path, "r") as f:
            gen_lines = f.read().splitlines()
    except (IOError, OSError) as e:
        print("SCAN-ERROR: cannot read generator {}: {}".format(gen_path, e))
        sys.exit(3)
    start = None
    for i, l in enumerate(gen_lines):
        if l.startswith("write_operator_toml() {"):
            start = i
            break
    if start is None:
        print("SCAN-ERROR: write_operator_toml not found in {} — the leg cannot assert"
              " anything about a function it cannot locate.".format(gen_path))
        sys.exit(3)
    end = None
    for i in range(start + 1, len(gen_lines)):
        if gen_lines[i] == "}":
            end = i
            break
    if end is None:
        end = len(gen_lines)
    body = gen_lines[start:end]
    # A literal per-key emit looks like:  out.append("<key> = ...
    # The derived loop emits via a format string over the declaration, so it carries
    # no bare `<identifier> = ` literal. A section header emit is NOT a key emit.
    _Q = chr(34)
    literal_emit = re.compile(r"out\.append\(\s*" + _Q + r"([A-Za-z_][A-Za-z0-9_]*)\s*=")
    hits = []
    for off, l in enumerate(body):
        m = literal_emit.search(l)
        if m:
            hits.append((start + off + 1, m.group(1)))
    for (ln, key) in hits:
        print("FAIL: {}:{} emits key \"{}\" as a hand-written literal inside"
              " write_operator_toml. The emit is DERIVED from {} — a literal beside the"
              " loop re-creates the shadow SSOT the declaration exists to"
              " prevent.".format(os.path.basename(gen_path), ln, key, "the declaration"))
        findings += 1
    # CONTROL: the function body must be non-trivial, and the derivation loop must be
    # present. Either absent means this leg is asserting nothing.
    body_text = "\n".join(body)
    loop_present = "for _sec in SECTIONS" in body_text
    if len(body) < 20 or not loop_present:
        print("SCAN-ERROR: write_operator_toml body extracted {} line(s), derivation loop"
              " present={} — the extraction is not reaching the function.".format(
                  len(body), loop_present))
        sys.exit(3)
    print("DENOM: C70b scanned {} line(s) of write_operator_toml; CONTROL derivation loop"
          " present, so the {} literal-emit finding(s) above are readable.".format(
              len(body), len(hits)))

    # ---- C70d: THREE-registry parity, all directions ----
    # spec §4 vocabulary table  <->  operator.toml.template  <->  the declaration.
    spec_text = read_spec(os.environ["S_SPEC"])
    spec_rows = set(ANGLE_ROW.findall(spec_text))
    # The §4 token <-> [paths] key correspondence is a pure lowercasing. Asserting it
    # here is what makes a row and its config key ONE fact rather than two that happen
    # to look alike.
    spec_keys = set(t.lower() for t in spec_rows)
    tpl_inst = set(k for (_s, k) in tpl if k.startswith("operator_instance_"))
    decl_inst = set(k for (_s, k, _v, _d) in declared if k.startswith("operator_instance_"))

    # CONTROL ARM, BEFORE ANY VERDICT — and it is the arm this leg most needs. A §4
    # table that parsed to zero rows would make every set-difference below empty and
    # report a vacuous clean over a registry the extractor never reached. That is the
    # precise failure mode the check exists to prevent, so it must not be able to
    # commit it itself.
    if not spec_rows:
        print("SCAN-ERROR: the §4 vocabulary table in {} parsed to ZERO angle rows; the"
              " registry extractor is not reaching the population. This is a broken"
              " probe, not an empty registry.".format(os.environ["S_SPEC"]))
        sys.exit(3)
    if not tpl_inst or not decl_inst:
        print("SCAN-ERROR: operator_instance_* key set parsed to ZERO in {} — refusing"
              " to report registry parity from a population that was never read.".format(
                  "operator.toml.template" if not tpl_inst else "the declaration"))
        sys.exit(3)

    c70d_hits = 0
    for key in sorted(spec_keys - (tpl_inst & decl_inst)):
        absent = []
        if key not in tpl_inst:
            absent.append("core/config/operator.toml.template")
        if key not in decl_inst:
            absent.append("core/config/operator-toml-schema.json")
        print("FAIL: <{}> carries a depersonalization-spec.md §4 vocabulary row but is"
              " ABSENT from {} — a codified token whose override field does not exist"
              " cannot be set by an operator, and deploy.sh Check 44 reads §4 as the live"
              " registry, so the two disagree on every run.".format(
                  key.upper(), " and ".join(absent)))
        c70d_hits += 1
        findings += 1
    for key in sorted((tpl_inst | decl_inst) - spec_keys):
        present = []
        if key in tpl_inst:
            present.append("core/config/operator.toml.template")
        if key in decl_inst:
            present.append("core/config/operator-toml-schema.json")
        print("FAIL: {} is declared in {} but has NO §4 vocabulary row in"
              " depersonalization-spec.md — add the row (canonical default, override"
              " field, and the landed consumer that supplies the default) or remove the"
              " key. An override with no registry row is unreachable by the resolver and"
              " invisible to Check 44.".format(key, " and ".join(present)))
        c70d_hits += 1
        findings += 1
    print("DENOM: C70d compared {} §4 vocabulary row(s) against {} template and {}"
          " declared operator_instance_* key(s); CONTROL all three populations non-zero,"
          " so the {} parity finding(s) above are readable.".format(
              len(spec_rows), len(tpl_inst), len(decl_inst), c70d_hits))

if verb == "diff":
    # ---- C70e: the same-change obligation, at the one surface that has a diff ----
    spec_path = os.environ["S_SPEC"]
    root = os.environ["S_ROOT"]
    base = os.environ["S_BASE"]
    if not base:
        print("SCAN-ERROR: --diff-base requires a ref; none was supplied.")
        sys.exit(3)

    def git(*args):
        return subprocess.run(["git", "-C", root] + list(args),
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    probe = git("rev-parse", "--verify", "{}^{{commit}}".format(base))
    if probe.returncode != 0:
        print("SCAN-ERROR: diff base {!r} does not resolve to a commit in {} ({}). A"
              " shallow checkout is the usual cause — this arm needs fetch-depth 0."
              .format(base, root, probe.stderr.decode("utf-8", "replace").strip()))
        sys.exit(3)

    spec_text = read_spec(spec_path)
    spec_rows = set(ANGLE_ROW.findall(spec_text))
    if not spec_rows:
        print("SCAN-ERROR: the §4 vocabulary table parsed to ZERO angle rows; refusing to"
              " classify any token as un-codified against a registry never read.")
        sys.exit(3)

    # Prefix set derived at runtime from BOTH registry table families, exactly as
    # Check 44 derives it — so the reach of this arm matches the deploy-time
    # inventory exactly, and a new prefix widens both at once with no edit here.
    prefixes = sorted(set(t.split("_")[0] for t in
                          list(spec_rows) + SQUARE_ROW.findall(spec_text)))
    if not prefixes:
        print("SCAN-ERROR: registry tables yielded an EMPTY prefix set; the derived"
              " vocabulary is unavailable and this arm did not run.")
        sys.exit(3)
    tok_re = re.compile(r"<((?:" + "|".join(prefixes) + r")_[A-Z0-9_]+)>")

    dif = git("diff", "--unified=0", "{}...HEAD".format(base))
    if dif.returncode != 0:
        print("SCAN-ERROR: could not compute the diff against {} ({}).".format(
            base, dif.stderr.decode("utf-8", "replace").strip()))
        sys.exit(3)

    # Added lines only, file-scoped so the §4 EXCLUSIONS apply here exactly as they
    # apply at deploy time: release/releases/ is a terminal ledger surface, and a line
    # carrying the marker is a declared illustrative use.
    added = []          # (path, line_text)
    spec_rel = os.path.relpath(spec_path, root)
    spec_added_rows = set()
    cur = None
    for line in dif.stdout.decode("utf-8", "replace").splitlines():
        if line.startswith("+++ "):
            p = line[4:].strip()
            cur = None if p == "/dev/null" else p[2:] if p.startswith("b/") else p
            continue
        if not line.startswith("+") or line.startswith("+++"):
            continue
        if cur is None:
            continue
        text = line[1:]
        if cur == spec_rel:
            spec_added_rows |= set(ANGLE_ROW.findall(text + "\n"))
        if cur.startswith("release/releases/"):
            continue
        if "depersonalization-token: allow" in text:
            continue
        added.append((cur, text))

    cand = {}
    for (p, text) in added:
        for m in tok_re.finditer(text):
            cand.setdefault(m.group(1), set()).add(p)

    # The BASE-ABSENCE test. Without it this arm fires on every added REFERENCE to an
    # already-present un-codified token — which §4 expressly sanctions — and becomes
    # the uniform closed-set rule ADR-154 rejected, only louder because it fails a PR.
    base_tokens = set()
    if cand:
        bg = git("grep", "-h", "-I", "-E",
                 "<(" + "|".join(prefixes) + ")_[A-Z0-9_]+>", base, "--", ".")
        # git grep exits 1 on "no match", which is a legitimate empty result, not an
        # error; anything above 1 is a real failure and must not read as "all new".
        if bg.returncode > 1:
            print("SCAN-ERROR: could not enumerate tokens present at base {} ({}). An"
                  " unreadable base would make every token look newly authored."
                  .format(base, bg.stderr.decode("utf-8", "replace").strip()))
            sys.exit(3)
        for line in bg.stdout.decode("utf-8", "replace").splitlines():
            base_tokens |= set(tok_re.findall(line))

    c70e_hits = 0
    for tok in sorted(cand):
        if tok in base_tokens:
            continue                       # pre-existing: sanctioned incremental use
        if tok in spec_rows:
            continue                       # codified at HEAD (row added in this diff or earlier)
        where = ", ".join(sorted(cand[tok])[:3])
        print("FAIL: <{}> is NEWLY AUTHORED in this change ({}) and carries no"
              " depersonalization-spec.md §4 vocabulary row added in the same diff."
              " §4: \"Authoring NEW angle-bracket tokens MUST add a row to this table in"
              " the same PR.\" Add the row (canonical default, [paths] override field,"
              " and the landed consumer supplying the default) plus its"
              " operator.toml.template and operator-toml-schema.json counterparts — C70d"
              " asserts all three agree.".format(tok, where))
        c70e_hits += 1
        findings += 1
    print("DENOM: C70e read {} added line(s) across {} changed path(s) against base {};"
          " {} distinct angle token(s) appeared in them, {} token(s) were already present"
          " at base, §4 carries {} row(s) ({} added in this diff); {} finding(s) above."
          .format(len(added), len(set(p for (p, _t) in added)), base[:12], len(cand),
                  len([t for t in cand if t in base_tokens]), len(spec_rows),
                  len(spec_added_rows), c70e_hits))

if verb in ("instance", "all", "delta"):
    # ---- C70a: the live config carries every delivered key ----
    live_path = os.environ["S_LIVE"]
    if not os.path.isfile(live_path):
        if verb == "delta":
            print("SCAN-ERROR: no operator.toml at {} — nothing to reconcile.".format(live_path))
            sys.exit(3)
        print("DENOM: C70a skipped — no operator.toml at {} (not an installed"
              " instance).".format(live_path))
    else:
        try:
            live = set(parse_toml_keys(live_path))
        except (IOError, OSError) as e:
            print("SCAN-ERROR: cannot read {}: {}".format(live_path, e))
            sys.exit(3)
        if not live:
            print("SCAN-ERROR: {} parsed to ZERO keys; refusing to report that as"
                  " \"nothing missing\".".format(live_path))
            sys.exit(3)
        missing = [(s, k, since) for (s, k, since) in delivered if (s, k) not in live]
        for (s, k, since) in missing:
            print("WARN: [{}].{} is declared delivered (since v{}) but ABSENT from {}."
                  .format(s, k, since, live_path))
        if missing:
            print("WARN: remedy — bash docs/scripts/setup-workspace.sh --reconcile-config")
        print("DENOM: C70a checked {} delivered key(s) against {} key(s) present in {};"
              " CONTROL both populations non-zero, so the {} miss(es) above are"
              " readable.".format(len(delivered), len(live), live_path, len(missing)))
        if verb == "delta" and missing:
            sys.exit(1)

sys.exit(1 if findings else 0)
'
}

# ─── self-test fixture writers ────────────────────────────────────────────────
# Two registries the C70d/C70e arms must be able to vary INDEPENDENTLY, so each is
# written by a function taking an optional extra member. Varying one surface while
# holding the others fixed is what makes an arm discriminating rather than merely
# loud: an arm that changed all three at once could not tell a parity failure from
# a parse failure.
_fx_write_decl() {
  # $1 = fixture root; $2 = OPTIONAL extra operator_instance_* key under [paths]
  local _root="$1" _extra=""
  if [ -n "${2:-}" ]; then
    _extra=",
   {\"key\":\"$2\",\"type\":\"string\",\"source\":\"operator-or-default\",\"delivery\":\"opt-in\",\"default\":\"\",\"since\":\"1.0\"}"
  fi
  cat >"${_root}/core/config/operator-toml-schema.json" <<JSON
{"schema":"operator.toml","declaration_version":1,"sections":[
 {"name":"meta","delivery":"delivered","keys":[
   {"key":"schema_version","type":"int","source":"declaration-version","since":"1.0"}]},
 {"name":"automation","delivery":"delivered","keys":[
   {"key":"automation_level","type":"string","source":"operator-or-default","default":"recommend","since":"4.23"}]},
 {"name":"paths","delivery":"opt-in","keys":[
   {"key":"operator_instance_hub_state_path","type":"string","source":"operator-or-default","delivery":"opt-in","default":"","since":"1.0"}${_extra}]},
 {"name":"projects","delivery":"opt-in","keys":[
   {"key":"board_url","type":"string","source":"operator-or-default","since":"4.0"}]}
]}
JSON
}

_fx_write_template() {
  # $1 = fixture root; $2 = OPTIONAL extra operator_instance_* key under [paths]
  local _root="$1"
  cat >"${_root}/core/config/operator.toml.template" <<'TPL'
[meta]
schema_version = 1
[automation]
automation_level = "recommend"
[paths]
operator_instance_hub_state_path = ""
TPL
  [ -n "${2:-}" ] && printf '%s = ""\n' "$2" >>"${_root}/core/config/operator.toml.template"
  printf '[projects]\nboard_url = ""\n' >>"${_root}/core/config/operator.toml.template"
}

_fx_write_spec() {
  # $1 = fixture root; $2 = OPTIONAL extra §4 angle row token (bare NAME, no <>)
  local _root="$1"
  mkdir -p "${_root}/core/standards"
  cat >"${_root}/core/standards/depersonalization-spec.md" <<'SPEC'
# fixture spec

## §1 Identity tokens

| Token | Meaning |
|---|---|
| `[OPERATOR_NAME]` | the operator display name |

## §4 Operator-instance path tokens

| Token | Canonical default | operator.toml override field | Codified by |
|---|---|---|---|
| `<OPERATOR_INSTANCE_HUB_STATE_PATH>` | `WSROOT/pmo-instance/hub-state` | `[paths].operator_instance_hub_state_path` | fixture |
SPEC
  # Prose mention of a metavariable — present so every arm re-proves that the registry
  # read is TABLE-SCOPED and does not register prose. This is the property that keeps
  # the real spec free of a name-specific exception for its schema metavariable.
  # The marker must sit on the SAME line as the literal — the matcher is per-line — so
  # this printf deliberately does NOT use a line continuation.
  printf 'Each `<OPERATOR_INSTANCE_X_PATH>` resolves per the rule above (prose, not a row).\n' >>"${_root}/core/standards/depersonalization-spec.md"  # depersonalization-token: allow — fixture metavariable written INTO a throwaway temp spec, never a corpus reference
  if [ -n "${2:-}" ]; then
    printf '| `<%s>` | `WSROOT/x` | `[paths].%s` | fixture |\n' \
      "$2" "$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')" \
      >>"${_root}/core/standards/depersonalization-spec.md"
  fi
}

self_test() {
  # NINE arms. Each states what it must observe, and the run FAILS if an arm that must
  # fire does not — an arm that silently passes is the failure mode this exists to catch.
  local tmp rc fails=0
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/c70-selftest-XXXXXX") || return 3
  mkdir -p "${tmp}/core/config" "${tmp}/docs/scripts"

  # A minimal but structurally faithful fixture repo.
  _fx_write_decl "${tmp}"
  _fx_write_template "${tmp}"
  _fx_write_spec "${tmp}"
  {
    echo 'write_operator_toml() {'
    echo '  python3 -c "'
    for _i in $(seq 1 24); do echo "# padding line ${_i}"; done
    echo 'for _sec in SECTIONS:'
    echo '    out.append("[{}]".format(_name))'
    echo '"'
    echo '}'
  } >"${tmp}/docs/scripts/setup-workspace.sh"

  # ARM 1 (specificity) — a faithful fixture must be CLEAN.
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/noconfig" run_probe repo >"${tmp}/a1.out" 2>&1
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "SELF-TEST FAIL arm1: a conformant fixture must be clean, got exit ${rc}"
    sed 's/^/  /' "${tmp}/a1.out"
    fails=$((fails + 1))
  fi

  # ARM 2 (sensitivity, C70c) — a template key absent from the declaration must FIRE.
  echo 'orphan_key = ""' >>"${tmp}/core/config/operator.toml.template"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/noconfig" run_probe repo >"${tmp}/a2.out" 2>&1
  rc=$?
  if [ "${rc}" -ne 1 ] || ! grep -q 'orphan_key' "${tmp}/a2.out"; then
    echo "SELF-TEST FAIL arm2: template-only key must FAIL and be named; exit ${rc}"
    fails=$((fails + 1))
  fi
  # restore
  grep -v 'orphan_key' "${tmp}/core/config/operator.toml.template" >"${tmp}/t.tmp"
  mv "${tmp}/t.tmp" "${tmp}/core/config/operator.toml.template"

  # ARM 3 (sensitivity, C70b) — a hand-written literal emit must FIRE.
  cp "${tmp}/docs/scripts/setup-workspace.sh" "${tmp}/gen.bak"
  awk '{print} /^for _sec in SECTIONS:$/ && !d {print "    out.append(\"automation_level = x\")"; d=1}' \
    "${tmp}/gen.bak" >"${tmp}/docs/scripts/setup-workspace.sh"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/noconfig" run_probe repo >"${tmp}/a3.out" 2>&1
  rc=$?
  if [ "${rc}" -ne 1 ] || ! grep -q 'hand-written literal' "${tmp}/a3.out"; then
    echo "SELF-TEST FAIL arm3: a literal per-key emit must FAIL; exit ${rc}"
    fails=$((fails + 1))
  fi
  mv "${tmp}/gen.bak" "${tmp}/docs/scripts/setup-workspace.sh"

  # ARM 4 (sensitivity, C70a) — a STALE instance config must WARN and name the key.
  mkdir -p "${tmp}/cfg"
  printf '[meta]\nschema_version = 1\n' >"${tmp}/cfg/operator.toml"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/cfg" run_probe instance >"${tmp}/a4.out" 2>&1
  if ! grep -q 'automation_level' "${tmp}/a4.out" || ! grep -q '^WARN:' "${tmp}/a4.out"; then
    echo "SELF-TEST FAIL arm4: a stale config must WARN naming the missing key"
    sed 's/^/  /' "${tmp}/a4.out"
    fails=$((fails + 1))
  fi

  # ARM 5 (specificity, C70a) — a CURRENT instance config must be silent, and an
  # EMPTY-STRING operator value must count as PRESENT (the value is preserved by
  # ovd() semantics; absence is what this leg measures, not emptiness).
  printf '[meta]\nschema_version = 1\n[automation]\nautomation_level = ""\n' \
    >"${tmp}/cfg/operator.toml"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/cfg" run_probe instance >"${tmp}/a5.out" 2>&1
  if grep -q '^WARN:' "${tmp}/a5.out"; then
    echo "SELF-TEST FAIL arm5: a current config must not warn (empty value is present)"
    sed 's/^/  /' "${tmp}/a5.out"
    fails=$((fails + 1))
  fi

  # ARM 6 (sensitivity, C70d) — a §4 row whose [paths] counterpart does not exist must
  # FIRE, and must name the token AND both surfaces it is missing from. This is the
  # shipped defect in fixture form: <OPERATOR_INSTANCE_ANALYSIS_PATH> carried a §4 row
  # and 91 corpus references while both config registries omitted it, and no executable
  # compared those surfaces.
  _fx_write_spec "${tmp}" "OPERATOR_INSTANCE_GHOST_PATH"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/noconfig" run_probe repo >"${tmp}/a6.out" 2>&1
  rc=$?
  if [ "${rc}" -ne 1 ] \
     || ! grep -q 'OPERATOR_INSTANCE_GHOST_PATH' "${tmp}/a6.out" \
     || ! grep -q 'operator.toml.template' "${tmp}/a6.out" \
     || ! grep -q 'operator-toml-schema.json' "${tmp}/a6.out"; then
    echo "SELF-TEST FAIL arm6: a codified token absent from both config registries must FAIL and name the token and both surfaces; exit ${rc}"
    sed 's/^/  /' "${tmp}/a6.out"
    fails=$((fails + 1))
  fi

  # ARM 7 (specificity, C70d) — reconcile the SAME token across all three registries and
  # the leg must go silent. The DENOM assertion is what makes this arm non-vacuous: a
  # silence produced by an extractor that read nothing would report 0 rows against 0
  # keys, so the arm requires the reconciled count (2) to appear.
  _fx_write_template "${tmp}" "operator_instance_ghost_path"
  _fx_write_decl "${tmp}" "operator_instance_ghost_path"
  ROOT="${tmp}" CONFIG_ROOT="${tmp}/noconfig" run_probe repo >"${tmp}/a7.out" 2>&1
  rc=$?
  if [ "${rc}" -ne 0 ] \
     || grep -q '^FAIL:' "${tmp}/a7.out" \
     || ! grep -q 'C70d compared 2 ' "${tmp}/a7.out"; then
    echo "SELF-TEST FAIL arm7: three reconciled registries must be silent AND report a non-empty denominator; exit ${rc}"
    sed 's/^/  /' "${tmp}/a7.out"
    fails=$((fails + 1))
  fi
  # restore the base fixture for anything downstream
  _fx_write_spec "${tmp}"; _fx_write_template "${tmp}"; _fx_write_decl "${tmp}"

  # ARMS 8-9 (C70e) — the diff-scoped arm asserts a property of a DIFF, so its fixture
  # is a real two-commit git repository. Nothing else can exercise it honestly.
  # SKIPPED, not failed, where git is absent: that is an environment fact, and failing
  # on it would make the whole primitive unusable rather than reporting one arm unrun.
  local ran=7
  if command -v git >/dev/null 2>&1; then
    ran=9
    local gfx="${tmp}/gitfx" basesha
    mkdir -p "${gfx}/core/config" "${gfx}/docs"
    _fx_write_decl "${gfx}"; _fx_write_template "${gfx}"; _fx_write_spec "${gfx}"
    # Every fixture token below is a THROWAWAY LITERAL written into a temp git repo —
    # it is not a corpus reference, so each line carries the exemption marker. Without
    # them these four names would enter Check 44 arm (d) inventory as real un-codified
    # tokens, and C70e would flag this very file on the PR that introduces it.
    printf 'base doc: <OPERATOR_INSTANCE_LEGACY_PATH> is already here, and un-codified.\n' >"${gfx}/docs/notes.md"  # depersonalization-token: allow — self-test fixture literal
    git -C "${gfx}" -c init.defaultBranch=main init -q >/dev/null 2>&1
    git -C "${gfx}" add -A >/dev/null 2>&1
    # commit.gpgsign is FORCED off for the fixture: this repo sets it globally, and a
    # fixture commit that needs a signing key would make the self-test fail for a
    # reason that has nothing to do with the check.
    git -C "${gfx}" -c user.email=selftest@example.invalid -c user.name=selftest \
      -c commit.gpgsign=false commit -q -m base >/dev/null 2>&1
    basesha="$(git -C "${gfx}" rev-parse HEAD 2>/dev/null)"

    # ONE commit carrying all three cases, so a single run adjudicates all of them and
    # the three verdicts are known to come from the same extraction.
    _fx_write_spec "${gfx}" "OPERATOR_INSTANCE_SAMECHANGE_PATH"
    {
      printf 'newly authored, no row anywhere: <OPERATOR_INSTANCE_BRANDNEW_PATH>\n'   # depersonalization-token: allow — self-test fixture literal
      printf 'another reference to the pre-existing <OPERATOR_INSTANCE_LEGACY_PATH>\n'   # depersonalization-token: allow — self-test fixture literal
      printf 'codified in this very diff: <OPERATOR_INSTANCE_SAMECHANGE_PATH>\n'   # depersonalization-token: allow — self-test fixture literal
    } >>"${gfx}/docs/notes.md"
    git -C "${gfx}" add -A >/dev/null 2>&1
    git -C "${gfx}" -c user.email=selftest@example.invalid -c user.name=selftest \
      -c commit.gpgsign=false commit -q -m head >/dev/null 2>&1

    DIFF_BASE="${basesha}" ROOT="${gfx}" CONFIG_ROOT="${tmp}/noconfig" \
      run_probe diff >"${tmp}/a89.out" 2>&1
    rc=$?

    # ARM 8 (sensitivity) — the genuinely new, un-codified token MUST fire and be named.
    if [ "${rc}" -ne 1 ] || ! grep -q 'OPERATOR_INSTANCE_BRANDNEW_PATH' "${tmp}/a89.out"; then
      echo "SELF-TEST FAIL arm8: a newly authored angle token with no same-change row must FAIL and be named; exit ${rc}"
      sed 's/^/  /' "${tmp}/a89.out"
      fails=$((fails + 1))
    fi

    # ARM 9 (specificity, THREE limbs) — this is the arm that keeps C70e from silently
    # becoming the uniform closed-set rule ADR-154 rejected. Limb (a): a token already
    # present at base is sanctioned incremental use and must NOT be reported. Limb (b):
    # a token whose §4 row lands in the same diff has MET the obligation. Limb (c): the
    # two silences must be shown non-vacuous — the run has to have SEEN all three
    # tokens and recognised one as pre-existing, which the DENOM line reports.
    if grep -q 'OPERATOR_INSTANCE_LEGACY_PATH' "${tmp}/a89.out"; then
      echo "SELF-TEST FAIL arm9a: a token already present at BASE must not be reported — that is the sanctioned incremental use, and firing on it fails correct work"
      sed 's/^/  /' "${tmp}/a89.out"
      fails=$((fails + 1))
    fi
    if grep -q 'OPERATOR_INSTANCE_SAMECHANGE_PATH' "${tmp}/a89.out"; then
      echo "SELF-TEST FAIL arm9b: a token whose §4 row lands in the SAME diff must not be reported"
      sed 's/^/  /' "${tmp}/a89.out"
      fails=$((fails + 1))
    fi
    if ! grep -q '3 distinct angle token(s) appeared' "${tmp}/a89.out" \
       || ! grep -q '1 token(s) were already present at base' "${tmp}/a89.out"; then
      echo "SELF-TEST FAIL arm9c: the specificity silences are VACUOUS — the DENOM line must show all 3 tokens seen and 1 recognised as pre-existing"
      sed 's/^/  /' "${tmp}/a89.out"
      fails=$((fails + 1))
    fi
  else
    echo "SELF-TEST NOTE: arms 8-9 (C70e diff-scoped) SKIPPED — git is not available here."
  fi

  rm -rf "${tmp}"
  if [ "${fails}" -ne 0 ]; then
    echo "SELF-TEST: ${fails} arm(s) failed — the check is NOT trustworthy in this state."
    return 3
  fi
  if [ "${ran}" -eq 9 ]; then
    echo "SELF-TEST: 9/9 arms behaved as specified (4 specificity silent, 5 sensitivity fired)."
  else
    echo "SELF-TEST: 7/7 runnable arms behaved as specified (3 specificity silent, 4 sensitivity fired); 2 diff-scoped arms skipped for want of git."
  fi
  return 0
}

MODE="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --self-test)       require_python || exit 3; self_test; exit $? ;;
    --repo-integrity)  MODE="repo"; shift ;;
    --instance)        MODE="instance"; shift ;;
    --emit-delta)      MODE="delta"; shift ;;
    --diff-base)       MODE="diff"; DIFF_BASE="${2:?--diff-base requires a ref}"; shift 2 ;;
    --root)            ROOT="${2:?--root requires a path}"; shift 2 ;;
    --config-root)     CONFIG_ROOT="${2:?--config-root requires a path}"; shift 2 ;;
    *) echo "usage: $0 [--self-test | --repo-integrity | --instance | --emit-delta | --diff-base <ref>] [--root <dir>] [--config-root <dir>]"; exit 3 ;;
  esac
done

require_python || exit 3
run_probe "${MODE}"
exit $?
