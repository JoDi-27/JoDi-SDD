#!/usr/bin/env bash
# PostToolUse on Edit|Write: regenerate specs/STATUS.md when a spec.md or tasks.md changed.
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
case "$file" in
  */specs/[0-9][0-9][0-9]-*/spec.md|*/specs/[0-9][0-9][0-9]-*/tasks.md) ;;
  *) exit 0 ;;
esac
# The checkout that holds the edited file: in a worktree, $CLAUDE_PROJECT_DIR
# is the main checkout, not the worktree.
root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || exit 0
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with sdd init
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/sdd"
"$SDD" status --write >/dev/null 2>&1 || echo "sdd status --write failed" >&2
exit 0
