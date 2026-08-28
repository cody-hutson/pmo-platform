#!/usr/bin/env bash
# fx-gamma — NON-MARKDOWN target fixture.
#
# Every one of these comment lines is syntactically ATX. That is the whole point
# of the fixture: running the markdown heading extractor over a shell target
# would scrape comment prose and present it as "the sections that do exist",
# which is why a non-markdown target is a counted not-run rather than a verdict.
#
# Phase 1 — setup
# Phase 2 — run
# Phase 3 — teardown
echo "fixture only; never executed by the check"
