# FIXTURE (test asset, not executed) — reproduces the check-release-body-drift.sh NOTES_DIR /
# NOTES_REL consumer that the #230 -> RCA #3118 notes-folder move silently missed. The
# structural blast-radius mode MUST flag this file. Two hard-coded reference lines (count == 2).
NOTES_DIR="${REPO_ROOT}/release/releases/notes"
NOTES_REL="release/releases/notes"
