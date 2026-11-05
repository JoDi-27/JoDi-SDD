#!/usr/bin/env bash
# Run the scenario tests: each tests/scenarios/NN-*.sh is a whole workflow
# (migration, a feature's lifecycle, a baseline and its capability document,
# parallel worktrees) driven through jsdd in a throwaway repository.
# Usage: run.sh [name-filter]   e.g. run.sh lifecycle
# CI runs it with /bin/bash on macOS (bash 3.2), Linux, and Git Bash on Windows.
set -uo pipefail

dir=$(cd "$(dirname "$0")" && pwd)
failed=""
count=0
for f in "$dir"/[0-9][0-9]-*.sh; do
  name=$(basename "$f" .sh)
  case $name in *"${1:-}"*) ;; *) continue ;; esac
  count=$((count + 1))
  printf '\n== %s\n' "$name"
  if "$BASH" "$f"; then echo "   ok"; else failed="$failed $name"; fi
done
[ "$count" -gt 0 ] || { echo "no scenario matches '${1:-}'" >&2; exit 1; }
if [ -n "$failed" ]; then printf '\nscenarios failed:%s\n' "$failed" >&2; exit 1; fi
printf '\nscenarios: %d ok\n' "$count"
