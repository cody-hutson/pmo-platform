<!-- reference-durability: allow-link -->
---
title: "ADR-082 — Headless-DOM regression tests use jsdom, not a real-browser driver"
status: Accepted
date: 2026-07-12
release: v3.74 build-security-hardening
deciders: "Stage-5 Solutioning DD-1 (empirically proven end-to-end, HIGH confidence) + Collective Review scope-lock"
tags: [testing, headless-dom, jsdom, xss-regression, eval-viewer, tooling, supply-chain, GHSA-rw36]
source_observations:
  - "GHSA-rw36 (eval-viewer stored XSS) shipped with NO test that renders generator output; the render-sink hardening (escapeHtml / escapeAttr / Number coercion in viewer.html) had no runtime regression proof — only a static sink census."
  - "The platform ships stdlib-only Python tooling with zero committed npm footprint and zero headless-DOM CI. Adding a RUNTIME DOM assertion needs either jsdom or a real-browser driver — a new supply-chain surface either way — so the tool choice is a durable, precedent-setting decision, not an incidental one."
  - "The load-bearing XSS-regression assertion is STRUCTURAL (does an injected element appear in a render-sink subtree?), not execution-fidelity: jsdom builds a faithful DOM tree from a markup assignment and runs inline scripts, which suffices; it does not fetch resources, so an <img> onerror never fires — and that is acceptable because element presence, not handler execution, is the discriminator."
---

# ADR-082 — Headless-DOM regression tests use jsdom, not a real-browser driver

## Status

**Accepted.** The jsdom canonicalization was decided at Stage-5 Solutioning (DD-1, HIGH confidence) and **empirically proven end-to-end** — RED on the pre-hardening tree, GREEN on the hardened tree — before it was selected. It was carried through the Collective Review scope-lock and is recorded here at Stage-6 authoring per the DD-5 ADR recommendation, because it is the repo's **first headless-DOM tooling decision** and the precedent every future DOM test will follow. This ADR is the durable record; the Stage-9 review verifies implementation conformance, it does not re-decide the tool.

## Context

Closing the eval-viewer stored-XSS advisory (**GHSA-rw36**) hardened the two render sinks in `viewer.html` (`renderGrades`, `renderBenchmark`) so untrusted eval data is `escapeHtml`/`escapeAttr`-encoded or `Number()`-coerced before it reaches an `innerHTML` sink. Static analysis (a custom semgrep sink census) proves the encoders are *present in source*, but it cannot prove they actually *neutralize a payload at render time* — a sink could be present yet mis-ordered, or a future template context could defeat it. A **runtime** regression that renders the real page with attacker-controlled data and asserts the payload lands inert is the complementary, load-bearing proof.

A runtime DOM assertion requires a headless DOM. The platform otherwise ships **stdlib-only Python** with no committed npm dependency, so introducing one is a supply-chain decision that sets precedent for all later DOM tests. The candidate tools split on one axis: a **faithful-DOM-tree** simulator (jsdom) versus a **real-browser driver** (Playwright, Puppeteer). The distinction only matters if the detector needs real-browser fidelity — so the detector's nature decides the tool.

The detector does **not** need real-browser fidelity. The XSS-regression discriminator is **structural**: an encoded payload becomes inert **text** inside the sink (no element node); a raw interpolation becomes a live **element** (`<img>`, `<script>`, an `on*`-bearing node). Counting active-markup element nodes in the sink subtree is exactly what a faithful DOM tree answers. jsdom builds that tree from a markup assignment and runs inline scripts (`runScripts: "dangerously"`); it does **not** fetch external resources, so an `<img src=x onerror=…>` never executes its handler — which is why the structural count, not an execution sentinel, is the real detector. The parse-time script-breakout class (a `</script>` escaping the inline-script context) is covered separately by the Python transport test and by a **self-contained positive control** that must fire on any tree, proving the harness is non-vacuous.

## Decision

**D1 — Headless-DOM regression tests use jsdom.** The eval-viewer DOM XSS regression renders the real `viewer.html` in jsdom, drives the render sinks, and asserts zero injected active-markup element nodes. jsdom is pinned to an exact version, declared a test-only `devDependency`, and installed from a **committed lockfile** (`npm ci`) so the DOM engine is reproducible; `node_modules` is git-ignored and excluded from the packaged skill.

**D2 — The load-bearing detector is structural, and non-vacuity is proven by a positive control.** The primary assertion is *element-node-in-render-sink*, not handler execution (jsdom loads no resources, so an image error-handler never fires — an execution-only sentinel would be vacuous). A checked-in, generator-independent positive control that MUST trip both the structural and execution detectors on any tree is the guard against a silently-broken harness.

**D3 — Real-browser fidelity is deferred, not foreclosed.** If a future DOM test genuinely needs event-handler execution or layout/paint behavior that jsdom cannot model, a real-browser driver may be introduced *for that test*; this ADR canonicalizes jsdom as the **default** for structural DOM-regression testing, not as a prohibition on browser drivers where fidelity is actually required.

**D4 — Home in `core/ADRs/`.** Headless-DOM test tooling is a cross-cutting engineering/test-infrastructure choice that sets platform-wide precedent, not a release-pipeline (SDLC) stage decision, so this record lives in `core/ADRs/` (consistent with the sibling charter ADR in the same release).

## Alternatives rejected

| Option | Trade-off | Verdict |
|---|---|---|
| **Playwright** | Real-browser fidelity (fires event handlers, models layout) — but a ~100s-of-MB browser download, higher CI cold-start, and more timing/network flakiness. Its sole advantage over jsdom (executing an `<img>` onerror) is **unnecessary** for a structural detector. | Rejected — over-powered for element-in-subtree detection; larger supply-chain + CI cost. |
| **Puppeteer** | Same real-browser fidelity via a Chromium download; same cost profile; same unused advantage. | Rejected — same reasons as Playwright. |
| **No runtime DOM test (static semgrep only)** | Zero new dependency, but proves only that encoders are *present in source*, never that they *neutralize a payload at render time* — the exact gap that let the sink defect ship. | Rejected — leaves the render-sink hardening without a runtime regression; the static census and the runtime proof are complementary, not substitutes. |
| **Hand-rolled regex/string checks on generated HTML** | No dependency, but cannot model DOM parsing (attribute-context breakouts, entity decoding, node materialization) — brittle and easily fooled. | Rejected — a faithful DOM tree is the correct model; a lockfile-pinned jsdom is the minimal way to get one. |

## Consequences

**Positive.**
- The render-sink hardening now has a **runtime** regression that fails RED if any per-sink encoder is removed — complementary to the static semgrep census (source-presence) and the transport test (serialization boundary).
- Minimal, reproducible supply-chain surface: a single pinned test-only dependency behind a committed lockfile, excluded from the shipped skill payload.
- A reusable, precedent-setting harness pattern (structural detector + non-vacuity positive control) for any future DOM test.

**Negative / accepted.**
- The repo gains its **first committed npm dependency** and a `node_modules`-capable CI job. Bounded: test-only, pinned, lockfile-driven, and gated on a floor Node version compatible with the pinned jsdom.
- jsdom cannot fire event handlers or model layout; DOM tests that genuinely need that fidelity must reach for a browser driver (D3). Accepted because the security-regression detector is structural.
- The eval-viewer test harness (including the lockfile) is bundled into the packaged skill under the current packager convention; leaning the deployed payload by excluding test directories is a separate packaging-tooling decision, out of scope here.
