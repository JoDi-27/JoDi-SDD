#!/usr/bin/env bash
# PreToolUse on Edit|Write: during this session's autopilot or autonomous run, block edits to the files a run must never change.
# Exit 2 blocks the call and sends stderr to Claude.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
sid=$(json '.session_id // empty')
file=$(posix_path "$(json '.tool_input.file_path // empty')")
[ -n "$sid" ] && [ -n "$file" ] || exit 0
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root=$(posix_path "${CLAUDE_PROJECT_DIR:-${cwd:-.}}")
[ -f "$root/specs/constitution.md" ] || exit 0   # not set up with jsdd init
runs=$(cd "$root" && CLAUDE_CODE_SESSION_ID=$sid "$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd" run active 2>/dev/null | tr -d '\r')
[ -n "$runs" ] || exit 0
# Compare physical paths, both from pwd -P: the input may name /var/... where
# git says /private/var/..., and in Git Bash git says C:/... where pwd says /tmp/...
d=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P) || d=$(dirname "$file")
r=$(cd "$root" 2>/dev/null && pwd -P) || r=$root
rel=${d#"$r"}/$(basename "$file"); rel=${rel#/}
case $rel in
  specs/constitution.md|docs/intent.md|specs/jsdd.yml|specs/*/checks.lock) ;;
  *) exit 0 ;;
esac
echo "A run never edits $rel: the constitution, the intent, the mode settings (the charter), and frozen checks belong to people. If the run cannot go on without changing it, park the spec: jsdd park <ID> <gate> \"<reason>\"." >&2
exit 2
