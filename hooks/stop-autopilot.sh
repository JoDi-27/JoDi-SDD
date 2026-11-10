#!/usr/bin/env bash
# Stop: while this session runs /jsdd:auto (one spec, or an autonomous loop) with work, budget, and progress left, block stopping so the run goes on.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
sid=$(json '.session_id // empty')
[ -n "$sid" ] || exit 0
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root=$(posix_path "${CLAUDE_PROJECT_DIR:-${cwd:-.}}")
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with jsdd init
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd"
# stop_hook_active: the session is already going on because of a block. jsdd
# then lets it stop unless the run changed something since, so it never loops.
again=""; [ "$(json '.stop_hook_active // false')" = true ] && again=--again
out=$(CLAUDE_CODE_SESSION_ID=$sid "$SDD" run stop-check $again 2>/dev/null | tr -d '\r') || exit 0
block=$(printf '%s\n' "$out" | sed -n 's/^block: //p' | head -1)
if [ -n "$block" ]; then
  jq -n --arg r "$block" '{decision: "block", reason: $r}'
elif [ -n "$out" ]; then
  jq -n --arg m "jsdd: $(printf '%s\n' "$out" | sed -n 's/^allow: //p' | paste -sd ' ' -)" '{systemMessage: $m}'
fi
exit 0
