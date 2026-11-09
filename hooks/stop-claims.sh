#!/usr/bin/env bash
# Stop: warn (never block) when this session still holds jsdd claims.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
sid=$(json '.session_id // empty')
[ -n "$sid" ] || exit 0
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root=$(posix_path "${CLAUDE_PROJECT_DIR:-${cwd:-.}}")
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with jsdd init
# Where bin/sdd keeps claims: the git common dir, else specs/.claims.
if common=$(git rev-parse --git-common-dir 2>/dev/null); then
  dir="$(cd "$common" && pwd)/sdd-claims"
else
  dir="$(pwd)/specs/.claims"
fi
[ -d "$dir" ] || exit 0
held=""
for c in "$dir"/*/; do
  [ -f "$c/owner" ] || continue
  name=$(basename "$c")
  case "$name" in id-*|run-*) continue ;; esac   # ID reservations and autopilot runs, not held work
  [ -f "$c/done" ] && continue             # finished tasks
  [ "$(sed -n 's/^owner=//p' "$c/owner" | head -1)" = "$sid" ] && held="$held $name"
done
[ -n "$held" ] || exit 0
msg="This session still holds jsdd claims:$held. Finish a task with: jsdd done <ID> <Tn>, or release with: jsdd release <ID> [Tn]"
jq -n --arg m "$msg" '{systemMessage: $m}'
exit 0
