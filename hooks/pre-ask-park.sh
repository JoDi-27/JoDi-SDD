#!/usr/bin/env bash
# PreToolUse on AskUserQuestion: during this session's autopilot or autonomous run, nobody is there to answer, so block the question and say to park instead.
# Outside a run nothing changes (/jsdd:auto setup asks on purpose). Exit 2 blocks the call and sends stderr to Claude.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
sid=$(json '.session_id // empty')
[ -n "$sid" ] || exit 0
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root=$(posix_path "${CLAUDE_PROJECT_DIR:-${cwd:-.}}")
[ -f "$root/specs/constitution.md" ] || exit 0   # not set up with jsdd init
runs=$(cd "$root" && CLAUDE_CODE_SESSION_ID=$sid "$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd" run active 2>/dev/null | tr -d '\r' | paste -sd ' ' -)
[ -n "$runs" ] || exit 0
echo "Nobody can answer during this run (${runs}): a run never asks. If a person must decide, park the spec at the gate that needs them: jsdd park <ID> <gate> \"<what they must decide, in one sentence>\", then finish the run (the run report, the draft pull request, jsdd run end <ID>)." >&2
exit 2
