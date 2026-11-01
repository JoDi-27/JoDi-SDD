#!/usr/bin/env bash
# release: bump the plugin version and move CHANGELOG.md's Unreleased notes under it.
# Usage: release.sh <major|minor|patch> <PR title> <PR number> <PR url> [notes-file]
# Run from the repository root. Prints the new version; writes the release notes
# to notes-file when given. With no Unreleased notes, the PR title is the entry.
set -euo pipefail

bump=$1 title=$2 number=$3 url=$4 notes_out=${5:-}
manifest=.claude-plugin/plugin.json
changelog=CHANGELOG.md

IFS=. read -r major minor patch <<<"$(jq -r .version "$manifest")"
case $bump in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "unknown bump '$bump'" >&2; exit 1 ;;
esac
version="$major.$minor.$patch"

tmp=$(mktemp)
jq --arg v "$version" '.version = $v' "$manifest" >"$tmp" && mv "$tmp" "$manifest"

# Notes: the body of "## Unreleased", up to the next "## " heading, trimmed.
notes=$(awk '/^## /{ if (on) exit; on = ($0 == "## Unreleased"); next } on' "$changelog" \
  | sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}')
[ -n "$notes" ] || notes="- $title ([#$number]($url))"

# Rewrite: drop the old Unreleased section, then put an empty one and the new
# release above the first release heading.
NOTES="$notes" awk -v head="## $version ($(date -u +%Y-%m-%d))" '
  /^## / && skip { skip = 0 }
  $0 == "## Unreleased" { skip = 1; next }
  skip { next }
  /^## / && !done { print "## Unreleased\n\n" head "\n\n" ENVIRON["NOTES"] "\n"; done = 1 }
  { print }
  END { if (!done) print "\n## Unreleased\n\n" head "\n\n" ENVIRON["NOTES"] }
' "$changelog" >"$tmp" && mv "$tmp" "$changelog"

[ -z "$notes_out" ] || printf '%s\n' "$notes" >"$notes_out"
echo "$version"
