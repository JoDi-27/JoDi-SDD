# shellcheck shell=bash
# Shared by the scenarios (sourced). Each scenario runs in its own throwaway git
# repository and drives jsdd the way the skills do, asserting on its output and
# on the files it writes.
set -euo pipefail

KIT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
FIXTURES=$KIT/tests/fixtures
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# The scripts run `env bash`: point that at the bash running the scenario, so
# `/bin/bash run.sh` tests macOS's bash 3.2 even when a newer one is on PATH.
mkdir "$TMP/bin"
case $OSTYPE in
  msys*|cygwin*) ;;
  *) ln -s "$BASH" "$TMP/bin/bash"; PATH=$TMP/bin:$PATH ;;
esac
export CLAUDE_CODE_SESSION_ID=session-a
unset SDD_MAIN_BRANCH SDD_REQUIREMENTS

jsdd() { "$KIT/bin/jsdd" "$@"; }
step() { printf '  - %s\n' "$*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
# has <text> <substring>
has() { case $1 in *"$2"*) return 0 ;; esac; return 1; }
# expect <substring> <command...>: run the command, fail unless its output (stdout and stderr) has the substring.
expect() {
  local want=$1 out; shift
  out=$("$@" 2>&1) || true
  has "$out" "$want" || fail "'$*' did not print '$want'. Got:
$out"
}
# refuses <command...>: the command must exit non-zero.
refuses() { if "$@" >/dev/null 2>&1; then fail "'$*' succeeded but should have been refused"; fi; }
# edit <file> <sed script>: sed -i that works with BSD and GNU sed.
edit() { sed "$2" "$1" >"$1.tmp" && mv "$1.tmp" "$1"; }
# as <session> <command...>: run as another Claude Code session.
as() { local s=$1; shift; CLAUDE_CODE_SESSION_ID=$s "$@"; }

# project [fixture]: a new git repository in $TMP/proj (a copy of the fixture, if given), cd'd into.
project() {
  PROJ=$TMP/proj
  mkdir "$PROJ"
  [ -z "${1:-}" ] || cp -R "$FIXTURES/$1/." "$PROJ/"
  cd "$PROJ"
  git init -q -b main 2>/dev/null || { git init -q && git checkout -q -b main; }
  git config user.name scenario
  git config user.email scenario@example.com
  git add -A && git commit -qm "[meta] Start" --allow-empty
}

# requirements <row...>: write docs/requirements.md with one table of "ID | text | Pri" rows.
requirements() {
  local r
  {
    printf '%s\n' '# Requirements' '' '## 1. Functional requirements' '' '### 1.1 Area' '' \
      '| ID | Requirement | Source | Pri |' '|---|---|---|---|'
    for r in "$@"; do
      printf '| %s | %s | scenario | %s |\n' "$(echo "$r" | cut -d'|' -f1)" "$(echo "$r" | cut -d'|' -f2)" "$(echo "$r" | cut -d'|' -f3)"
    done
  } >docs/requirements.md
}

# frontmatter <spec.md> <key> <value>: set one frontmatter field.
frontmatter() { edit "$1" "s|^$2:.*|$2: $3|"; }
