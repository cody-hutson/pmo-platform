# FIXTURE (test asset, not executed) — reproduces the deploy.sh Check-47 notes-dir default
# that the #230 -> RCA #3118 notes-folder move silently missed. The structural blast-radius
# mode MUST flag this file. One hard-coded reference line below (count == 1).
C32_NOTES_DIR="${REPO_ROOT}/release/releases/notes"
