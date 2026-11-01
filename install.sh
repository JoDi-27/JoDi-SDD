#!/usr/bin/env bash
# install.sh: add the SDD kit to a project, or update the kit in a project that has it.
# Plain bash 3.2, so it runs on a stock macOS or Linux laptop.
set -euo pipefail

usage() {
  cat <<EOF
Usage: install.sh [--update] [--dry-run] <project dir>

Copies kit/ (skills, agents, hooks, the sdd tool, templates) into the project,
and starters/ (constitution, PLAN, BACKLOG, intent, requirements, decisions)
where the project does not have them yet.

  (default)   Copy missing files only. Kit files that differ are reported, not changed.
  --update    Also overwrite kit files that differ. Starters are never overwritten:
              the project owns them once copied. .claude/settings.json is never
              overwritten either; merge it by hand if the report says it differs.
  --dry-run   Report what would happen, change nothing.
EOF
}

update=""; dry=""; target=""
while [ $# -gt 0 ]; do
  case $1 in
    --update) update=1 ;;
    --dry-run) dry=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option '$1'" >&2; usage >&2; exit 1 ;;
    *) [ -z "$target" ] || { usage >&2; exit 1; }; target=$1 ;;
  esac
  shift
done
[ -n "$target" ] || { usage >&2; exit 1; }
[ -d "$target" ] || { echo "no such directory: $target" >&2; exit 1; }
target=$(cd "$target" && pwd)
KIT=$(cd "$(dirname "$0")" && pwd)

run() { [ -n "$dry" ] || "$@"; }

# place <source root> <relative path> <kit|starter>
place() {
  local src="$1/$2" dst="$target/$2"
  if [ ! -e "$dst" ]; then
    echo "  add      $2"
    run mkdir -p "$(dirname "$dst")"; run cp -p "$src" "$dst"
  elif cmp -s "$src" "$dst"; then
    :
  elif [ "$3" = starter ]; then
    :   # the project owns it
  elif [ "$2" = .claude/settings.json ]; then
    echo "  differs  $2 (never overwritten: merge the kit's hooks and permissions by hand)"
  elif [ -n "$update" ]; then
    echo "  update   $2"
    run cp -p "$src" "$dst"
  else
    echo "  differs  $2 (run with --update to take the kit's version)"
  fi
}

echo "Kit files:"
(cd "$KIT/kit" && find . -type f ! -name .DS_Store | sed 's|^\./||' | sort) | while IFS= read -r f; do place "$KIT/kit" "$f" kit; done
echo "Starters:"
(cd "$KIT/starters" && find . -type f ! -name .DS_Store | sed 's|^\./||' | sort) | while IFS= read -r f; do place "$KIT/starters" "$f" starter; done

run chmod +x "$target/specs/_kit/sdd" "$target"/.claude/hooks/*.sh 2>/dev/null || true

for line in ".claude/settings.local.json" "specs/_kit/.claims/"; do
  if ! grep -qxF "$line" "$target/.gitignore" 2>/dev/null; then
    echo "  ignore   $line (.gitignore)"
    [ -n "$dry" ] || printf '%s\n' "$line" >> "$target/.gitignore"
  fi
done

version=$(git -C "$KIT" rev-parse --short HEAD 2>/dev/null || echo unknown)
dirty=$(git -C "$KIT" status --porcelain 2>/dev/null | head -1)
[ -z "$dirty" ] || version="$version+dirty"
[ -n "$dry" ] || printf 'sdd-kit %s, installed %s\n' "$version" "$(date +%F)" > "$target/specs/_kit/VERSION"

echo
[ -n "$dry" ] && echo "Dry run: nothing changed."
echo "Kit version $version in $target/specs/_kit/VERSION."
if [ ! -f "$target/docs/requirements.md" ] || grep -q 'FR-AUTH-01 | <one behavior>' "$target/docs/requirements.md" 2>/dev/null; then
  cat <<EOF

Next steps:
  1. Fill in docs/intent.md, then the product articles in specs/constitution.md.
  2. List requirements in docs/requirements.md, and phases in PLAN.md tagged with their IDs.
  3. Put the project's real test command in the examples (search for 'make test').
  4. Start a new Claude Code session there so the hooks load, then run /sdd-status.
EOF
fi
