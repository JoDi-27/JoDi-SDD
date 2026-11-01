#!/usr/bin/env bash
# SessionStart: print the spec board and the claims into context (stdout is added as context).
# The session's own checkout: in a worktree, $CLAUDE_PROJECT_DIR is the main checkout.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root="${CLAUDE_PROJECT_DIR:-.}"
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with sdd init
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/sdd"
echo "Spec board (sdd status):"
"$SDD" status 2>&1
echo
echo "Claims (sdd claims):"
"$SDD" claims 2>&1
exit 0
