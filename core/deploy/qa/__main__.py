"""Entry point for `python3 -m qa` — run the suite, exit with its status code."""

from __future__ import annotations

import sys

from .runner import main

sys.exit(main(sys.argv[1:]))
