#!/usr/bin/env bash
# Stop: warn (never block) when this session still holds jsdd claims.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
sid=$(json '.session_id // empty')
[ -n "$sid" ] || exit 0
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root=$(posix_path "${CLAUDE_PROJECT_DIR:-${cwd:-.}}")
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with jsdd init
# jsdd knows where the claims are (local, or the remote's cache) and whose they are.
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd"
held=$(CLAUDE_CODE_SESSION_ID=$sid "$SDD" claims --mine 2>/dev/null | tr -d '\r') || exit 0
[ -n "$held" ] || exit 0
msg="This session still holds jsdd claims: $held. Finish a task with: jsdd done <ID> <Tn>, or release with: jsdd release <ID> [Tn]"
jq -n --arg m "$msg" '{systemMessage: $m}'
exit 0
