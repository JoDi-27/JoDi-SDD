#!/usr/bin/env bash
# PostToolUse on Edit|Write: regenerate specs/STATUS.md when a spec.md, tasks.md, or the root PLAN.md or the requirements file changed.
. "$(dirname "$0")/_lib.sh"   # reads the hook input
file=$(posix_path "$(json '.tool_input.file_path // empty')")
rootdoc=""
case "$file" in
  */specs/[0-9][0-9][0-9]-*/spec.md|*/specs/[0-9][0-9][0-9]-*/tasks.md) ;;
  */PLAN.md|*/requirements.md) rootdoc=1 ;;   # STATUS.md has the coverage summary
  *) exit 0 ;;
esac
SDD="$(cd "$(dirname "$0")/.." && pwd)/bin/jsdd"
# The requirements file is <docs folder>/requirements.md (docs_dir in specs/jsdd.yml).
req() { (cd "$1" && "$SDD" paths --docs 2>/dev/null || echo docs) | tr -d '\r' | sed 's|$|/requirements.md|'; }
# The checkout that holds the edited file: in a worktree, $CLAUDE_PROJECT_DIR
# is the main checkout, not the worktree. PLAN.md and the requirements file count
# only at the root of that checkout.
dir=$(dirname "$file")
if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
  if [ -n "$rootdoc" ]; then
    rel="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)$(basename "$file")"
    case "$rel" in PLAN.md|"$(req "$root")") ;; *) exit 0 ;; esac
  fi
else
  root=$(posix_path "${CLAUDE_PROJECT_DIR:-}")
  [ -n "$root" ] || exit 0
  if [ -n "$rootdoc" ]; then
    case "$file" in "$root/PLAN.md"|"$root/$(req "$root")") ;; *) exit 0 ;; esac
  fi
fi
cd "$root" || exit 0
[ -f specs/constitution.md ] || exit 0   # not set up with jsdd init
"$SDD" status --write >/dev/null 2>&1 || echo "jsdd status --write failed" >&2
exit 0
