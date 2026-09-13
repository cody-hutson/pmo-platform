# Hub session state — M4 tree fixture, the FLAGGED slug

**This file is load-bearing, and it is not a contrivance.** Git carries no empty
directory, so a ledger-less fixture slug with nothing in it would vanish on a fresh
clone and the arm would silently degrade to "directory absent" — testing the wrong
branch while still reporting green. The real `release-closeout-integrity` hub-state
directory contains exactly `sessions.md` and nothing else, so this mirrors an
observed hub-state shape rather than inventing one.

What this slug represents: a release that **rendered decisions and reached stage 13**
— it completed — and left **no `action-items.md` behind. That is the condition the
M4 screen reports: a durable commitment was owed at some routing point and no ledger
records whether one was ever made, on a release that is now closed and cannot repair
it. `log-m4.md` carries two rows for this slug, one of them at stage 13.

Deliberately carries no `AI-<digits>` token, so the tree cannot perturb C4's id join.
