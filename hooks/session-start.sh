#!/usr/bin/env bash
# SessionStart: print the spec board and the claims into context (stdout is added as context).
# The session's own checkout: in a worktree, $CLAUDE_PROJECT_DIR is the main checkout.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
cwd=$(json '.cwd // empty')
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || root="${CLAUDE_PROJECT_DIR:-.}"
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with jsdd init
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd"
echo "Spec board (jsdd status):"
"$SDD" status 2>&1
echo
echo "Claims (jsdd claims):"
"$SDD" claims 2>&1
# The docs folder, when the project moved it: skills and agents name the kit's
# documents as docs/<file>, which then means <folder>/<file>.
docs=$("$SDD" paths --docs 2>/dev/null | tr -d '\r')
if [ -n "$docs" ] && [ "$docs" != docs ]; then
  echo
  echo "Docs folder: $docs/ (docs_dir in specs/jsdd.yml). Where a jsdd skill or agent names docs/<file>, use $docs/<file>."
fi
# Upgrade notices: changes in a new jsdd version that ask something of a project
# set up before it, each shown once per clone, and only where it applies.
notes=$("$SDD" notices 2>/dev/null)
if [ -n "$notes" ]; then
  echo
  echo "jsdd upgrade notices (new for this clone; tell the user about each one once, in a sentence or two, and offer the dry run it names):"
  printf '%s\n' "$notes"
fi
# The other hooks need jq, and the commit check Python 3; without them they do nothing.
missing=""
command -v jq >/dev/null 2>&1 || missing="$missing jq"
find_python >/dev/null || missing="$missing python3"
if [ -n "$missing" ]; then
  echo
  echo "jsdd: missing$missing, so the commit-message check and STATUS.md regeneration are off. Ask the user to install it (on Windows: winget install jqlang.jq Python.Python.3.12)."
fi
exit 0
