"use strict";
/*
 * dom_xss_test.js — headless-DOM (jsdom) XSS regression for the eval-viewer render sinks.
 * Guards GHSA-rw36-5pf9-w2vc at RUNTIME: renders the ACTUAL viewer.html (via
 * generate_review.generate_html) with attacker-controlled EMBEDDED_DATA, drives the two
 * innerHTML sinks (renderGrades via showRun, and renderBenchmark), and asserts every
 * payload lands INERT. Complements the static semgrep template-context-XSS sink census and the Python
 * transport test (test_transport_xss.py) with a rendered-DOM proof.
 *
 * Detectors:
 *   B1 (structural, LOAD-BEARING): zero active-markup element nodes inside a render sink.
 *      escapeHtml()/escapeAttr()/Number() land a payload as TEXT (no element); a raw
 *      interpolation lands it as an ELEMENT. jsdom does not load resources, so an <img>
 *      onerror never executes -> the ELEMENT's presence, not execution, is the discriminator.
 *   B2 (execution sentinel): window.__xssFired / alert / onerror never fire.
 *   B3 (parser breakout): no NEW <script> element (one that does NOT carry the EMBEDDED_DATA
 *      assignment) was parser-created carrying the payload marker. The inert payload TEXT
 *      inside the legitimate EMBEDDED_DATA script is expected and excluded.
 *
 * Non-vacuity: positive_control.html (self-contained) MUST fire BOTH detectors on ANY tree.
 *
 * Reproduction: set EVX_FIXTURE=/path/to/prerendered.html to assert against a fixture
 * rendered elsewhere (e.g. the pre-hardening tree eb90e67^) instead of generating one from
 * the current tree — used to demonstrate the harness goes RED on the vulnerable tree.
 *
 * Exit 0 = GREEN (hardened tree). Exit 1 = RED (a payload rendered live, or the harness
 * is broken). Proven RED against the pre-hardening tree eb90e67^ (ba694a4).
 */
const { JSDOM } = require("jsdom");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const HERE = __dirname;

// Active-markup selector. Matched WITHIN a render sink only; legitimate sink content
// (spans, tables, text) never matches, so any hit is injected markup.
const SINK_SELECTOR =
  "img, script, svg, iframe, object, embed, [onerror], [onload], [onclick], [onmouseover], [onfocus]";

let failures = 0;
function check(label, cond, detail) {
  if (cond) {
    console.log("PASS: " + label);
  } else {
    console.log("FAIL: " + label + (detail ? "  -- " + detail : ""));
    failures++;
  }
}

// Install the execution sentinel BEFORE any page script runs.
function loadWithSentinel(html) {
  const fired = [];
  const dom = new JSDOM(html, {
    runScripts: "dangerously",
    url: "https://localhost/",
    beforeParse(window) {
      window.__xssFired = function (where) { fired.push(String(where)); };
      window.alert = function () { fired.push("alert"); };
      window.onerror = function () { fired.push("onerror"); return true; };
      // Deterministic + hermetic: init() takes the sync path (previous_feedback is set in
      // the fixture) so this is belt-and-braces against any stray call hanging the run.
      window.fetch = function () { return Promise.reject(new Error("network disabled in test")); };
    },
  });
  return { dom, fired };
}

function countStructural(doc, sinkId) {
  const el = doc.getElementById(sinkId);
  if (!el) return -1; // sink missing -> contract/harness broken
  return el.querySelectorAll(SINK_SELECTOR).length;
}

// ---------------------------------------------------------------------------
// 1. Generated-fixture assertions — GREEN on the current (hardened) tree
// ---------------------------------------------------------------------------
let tmpDir = null;
let fixtureHtml;
if (process.env.EVX_FIXTURE) {
  fixtureHtml = fs.readFileSync(process.env.EVX_FIXTURE, "utf8");
  console.log("(loading pre-rendered fixture from EVX_FIXTURE=" + process.env.EVX_FIXTURE + ")");
} else {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "evx-"));
  const fixturePath = path.join(tmpDir, "fixture.html");
  execFileSync("python3", [path.join(HERE, "render_fixture.py"), fixturePath], {
    stdio: ["ignore", "inherit", "inherit"],
  });
  fixtureHtml = fs.readFileSync(fixturePath, "utf8");
}

const { dom: fdom, fired: ffired } = loadWithSentinel(fixtureHtml);
const fwin = fdom.window;

// The page auto-runs init()+renderBenchmark() at parse; re-drive explicitly for
// determinism (each sink does innerHTML = html, so re-driving is idempotent).
try { if (typeof fwin.showRun === "function") fwin.showRun(0); } catch (e) { /* ignore */ }
try { if (typeof fwin.renderBenchmark === "function") fwin.renderBenchmark(); } catch (e) { /* ignore */ }

const gradesNodes = countStructural(fwin.document, "grades-content");
const benchNodes = countStructural(fwin.document, "benchmark-content");

check("sink #grades-content exists", gradesNodes >= 0, "sink element not found");
check("sink #benchmark-content exists", benchNodes >= 0, "sink element not found");
check("B1 grades: zero injected structural nodes", gradesNodes === 0, gradesNodes + " active-markup node(s) in #grades-content");
check("B1 benchmark: zero injected structural nodes", benchNodes === 0, benchNodes + " active-markup node(s) in #benchmark-content");
check("B2: zero script executions (sentinel silent)", ffired.length === 0, "fired: " + JSON.stringify(ffired));
// B3: a real parser breakout produces a NEW <script> that does NOT carry the EMBEDDED_DATA
// assignment. The inert payload text inside the legitimate data script is excluded.
const injectedScripts = Array.from(fwin.document.querySelectorAll("script")).filter(function (s) {
  const t = s.textContent || "";
  return /__xssFired/.test(t) && !/EMBEDDED_DATA/.test(t);
});
check("B3: no parser-created breakout <script>", injectedScripts.length === 0, injectedScripts.length + " found");

// ---------------------------------------------------------------------------
// 2. Positive control — self-contained; MUST fire BOTH detectors (non-vacuity)
// ---------------------------------------------------------------------------
const pcHtml = fs.readFileSync(path.join(HERE, "positive_control.html"), "utf8");
const { dom: pcdom, fired: pcfired } = loadWithSentinel(pcHtml);
const pcStructural = countStructural(pcdom.window.document, "pc-sink");
check("PC B2: parser-breakout sentinel fired (execution detector works)", pcfired.indexOf("pc-parser-breakout") !== -1, "fired: " + JSON.stringify(pcfired));
check("PC B1: structural detector found an injected node (detector works)", pcStructural > 0, pcStructural + " found");

// ---------------------------------------------------------------------------
if (tmpDir) { try { fs.rmSync(tmpDir, { recursive: true, force: true }); } catch (e) { /* ignore */ } }

console.log("\n================================");
console.log(failures === 0
  ? "DOM XSS regression: GREEN (all assertions held)"
  : "DOM XSS regression: RED (" + failures + " failure(s))");
console.log("================================");
process.exit(failures === 0 ? 0 : 1);
