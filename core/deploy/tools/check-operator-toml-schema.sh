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
#      generator source not found, or python3 unavailable. NEVER a clean zero.
#
# USAGE
#   bash core/deploy/tools/check-operator-toml-schema.sh                # all legs
#   bash core/deploy/tools/check-operator-toml-schema.sh --repo-integrity  # C70b + C70c
#   bash core/deploy/tools/check-operator-toml-schema.sh --instance     # C70a (warn)
#   bash core/deploy/tools/check-operator-toml-schema.sh --emit-delta   # for update.sh
#   bash core/deploy/tools/check-operator-toml-schema.sh --self-test    # fixture arms
#   bash core/deploy/tools/check-operator-toml-schema.sh --root <dir>   # another work tree

set -uo pipefail

ROOT="${PWD}"
CONFIG_ROOT="${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"

REL_DECL="core/config/operator-toml-schema.json"
REL_TEMPLATE="core/config/operator.toml.template"
REL_GENERATOR="docs/scripts/setup-workspace.sh"

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
  S_LIVE="${CONFIG_ROOT}/operator.toml" \
  python3 -c '
import json, os, re, sys

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

self_test() {
  # FIVE arms. Each states what it must observe, and the run FAILS if an arm that must
  # fire does not — an arm that silently passes is the failure mode this exists to catch.
  local tmp rc fails=0
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/c70-selftest-XXXXXX") || return 3
  mkdir -p "${tmp}/core/config" "${tmp}/docs/scripts"

  # A minimal but structurally faithful fixture repo.
  cat >"${tmp}/core/config/operator-toml-schema.json" <<'JSON'
{"schema":"operator.toml","declaration_version":1,"sections":[
 {"name":"meta","delivery":"delivered","keys":[
   {"key":"schema_version","type":"int","source":"declaration-version","since":"1.0"}]},
 {"name":"automation","delivery":"delivered","keys":[
   {"key":"automation_level","type":"string","source":"operator-or-default","default":"recommend","since":"4.23"}]},
 {"name":"projects","delivery":"opt-in","keys":[
   {"key":"board_url","type":"string","source":"operator-or-default","since":"4.0"}]}
]}
JSON
  cat >"${tmp}/core/config/operator.toml.template" <<'TPL'
[meta]
schema_version = 1
[automation]
automation_level = "recommend"
[projects]
board_url = ""
TPL
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

  rm -rf "${tmp}"
  if [ "${fails}" -ne 0 ]; then
    echo "SELF-TEST: ${fails} arm(s) failed — the check is NOT trustworthy in this state."
    return 3
  fi
  echo "SELF-TEST: 5/5 arms behaved as specified (2 specificity silent, 3 sensitivity fired)."
  return 0
}

MODE="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --self-test)       require_python || exit 3; self_test; exit $? ;;
    --repo-integrity)  MODE="repo"; shift ;;
    --instance)        MODE="instance"; shift ;;
    --emit-delta)      MODE="delta"; shift ;;
    --root)            ROOT="${2:?--root requires a path}"; shift 2 ;;
    --config-root)     CONFIG_ROOT="${2:?--config-root requires a path}"; shift 2 ;;
    *) echo "usage: $0 [--self-test | --repo-integrity | --instance | --emit-delta] [--root <dir>] [--config-root <dir>]"; exit 3 ;;
  esac
done

require_python || exit 3
run_probe "${MODE}"
exit $?
