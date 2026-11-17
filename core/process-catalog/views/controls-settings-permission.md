---
title: Controls — settings-permission
purpose: The 7 controls whose mechanism kind is settings-permission, from the controls register
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — settings-permission

7 controls from the controls register. The statement, the class and the surface are the register's cells. Cited by counts the pages that cite the control; the pages and steps are on [controls-cited](controls-cited.md).

| Control | Statement | Enforcement class | Surface | Source path | Cited by |
|---|---|---|---|---|---|
| C-112 | Destructive git operations are denied natively: git push --force / -f, git reset --hard, git clean -f / -fd, git checkout -- ., git update-ref on main, git symbolic-ref HEAD to main, git filter-branch, git filter-repo (10 patterns) | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-113 | rm -rf of .git, Projects/, pmo-platform/, projects/ is denied natively (4 patterns) | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-114 | gh gist create is denied natively | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-115 | Read-tool access to credential paths is denied natively: ~/.ssh, ~/.aws, ~/.config/gh, .env variants, *.pem, *.key, id_rsa, id_ed25519 (12 patterns) | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-116 | Read-tool access to personal folders (~/Documents, Desktop, Music, Pictures, Movies, Public, Library mail/messages/calendars/containers/cookies/browsers, the shared system users folder) is denied natively (17 patterns) | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-117 | Edit-tool access to the same personal folders is denied natively (17 patterns) | code-enforce | runtime-permission | `core/settings.json.template` | — |
| C-118 | rm -rf and rm -r prompt for confirmation natively (ask list) | code-enforce (prompt) | runtime-permission | `core/settings.json.template` | — |
