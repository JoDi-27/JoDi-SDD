#!/usr/bin/env bash
# smoke: run jsdd and the hooks end to end in a throwaway git repository.
# Usage: smoke.sh   (from anywhere; uses the checkout it lives in)
set -euo pipefail

kit=$(cd "$(dirname "$0")/../.." && pwd)
jsdd=$kit/bin/jsdd
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# The scripts run `env bash`: point that at the bash running this script, so
# `/bin/bash smoke.sh` tests macOS's bash 3.2 even when a newer one is on PATH.
mkdir "$tmp/bin" "$tmp/proj"
ln -s "$BASH" "$tmp/bin/bash"
PATH=$tmp/bin:$PATH
proj=$tmp/proj
cd "$proj"
git init -q
git config user.name smoke
git config user.email smoke@example.com

step() { printf '\n== %s\n' "$*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

step "hooks stay quiet before init"
for h in "$kit"/hooks/*.sh; do
  out=$(printf '{"cwd":"%s","session_id":"s","tool_input":{"command":"git commit -m x","file_path":"x"}}' "$proj" | "$h")
  [ -z "$out" ] || fail "$(basename "$h") printed output in a project without jsdd: $out"
done

step "init"
"$jsdd" init
for f in docs/intent.md docs/requirements.md docs/decisions.md PLAN.md BACKLOG.md specs/constitution.md specs/README.md; do
  [ -f "$f" ] || fail "init did not create $f"
done
jq -e '.permissions.allow | index("Bash(jsdd *)")' .claude/settings.json >/dev/null || fail "init did not allow Bash(jsdd *)"

step "init again keeps the project's files"
echo "kept" >>docs/intent.md
"$jsdd" init >/dev/null
grep -q '^kept$' docs/intent.md || fail "a second init overwrote docs/intent.md"

step "new"
"$jsdd" new feature "Password reset by email"
"$jsdd" new spike "Which email provider"
[ -f specs/001-password-reset-by-email/spec.md ] || fail "new feature did not create spec 001"
ls specs/002-*/spec.md >/dev/null || fail "new spike did not create spec 002"

step "status, next, coverage"
"$jsdd" status --write
[ -f specs/STATUS.md ] || fail "status --write did not write specs/STATUS.md"
"$jsdd" next
"$jsdd" coverage

step "claim and release"
"$jsdd" claim 001
case $("$jsdd" claims) in *001*) ;; *) fail "claim 001 is not listed" ;; esac
"$jsdd" release 001
"$jsdd" claims --prune

step "session-start hook prints the board after init"
out=$(printf '{"cwd":"%s"}' "$proj" | "$kit/hooks/session-start.sh")
case $out in *"Spec board"*) ;; *) fail "session-start printed no board" ;; esac

printf '\nsmoke: ok\n'
