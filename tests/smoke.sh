#!/usr/bin/env bash
# Smoke test of bin/jsdd and the hooks in a throwaway project. CI runs it on
# Linux, macOS, and Windows (Git Bash). Run: bash tests/smoke.sh
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
JSDD="$KIT/bin/jsdd"
HOOKS="$KIT/hooks"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export CLAUDE_CODE_SESSION_ID=smoke-session
unset CLAUDE_PROJECT_DIR SDD_ROOT SDD_REQUIREMENTS 2>/dev/null || true

fails=0
ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1" >&2; fails=$((fails + 1)); }
check() { local name=$1; shift; if "$@"; then ok "$name"; else fail "$name"; fi; }
has()  { printf '%s' "$1" | grep -qF -- "$2"; }

# native_path <path>: the path as Claude Code sends it in hook input: C:\...
# on Windows, unchanged elsewhere.
native_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
# json_str <s>: s as a JSON string.
json_str() { jq -Rn --arg s "$1" '$s' | tr -d '\r'; }
# to_crlf <file>
to_crlf() { awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$1" > "$1.crlf" && mv "$1.crlf" "$1"; }

P="$WORK/project"
mkdir -p "$P" && cd "$P"
git init -q -b main 2>/dev/null || { git init -q && git checkout -q -b main; }
git config user.email smoke@example.com && git config user.name smoke

# --- CLI -------------------------------------------------------------------

out=$("$JSDD" init 2>&1)
check "init copies the starters" test -f specs/constitution.md -a -f docs/requirements.md -a -f PLAN.md
check "init allows jsdd in settings" grep -qF 'Bash(jsdd *)' .claude/settings.json
"$JSDD" init >/dev/null 2>&1
check "init twice adds the .gitignore line once" test "$(grep -cxF .claude/settings.local.json .gitignore)" = 1

spec=$("$JSDD" new feature 'Login "fast" | flow')
check "new creates the spec" test -f "$spec"
dir=$(dirname "$spec")

# A Windows checkout with core.autocrlf has CRLF project files.
to_crlf "$spec"
out=$("$JSDD" status)
check "status reads a CRLF spec" has "$out" '| 001 | feature | draft |'
check "status keeps the quoted title" has "$out" 'Login "fast" \| flow'

sed 's/^status: draft/status: planned/' "$spec" > "$spec.tmp" && mv "$spec.tmp" "$spec"
to_crlf "$spec"
printf '%s\n' '# Tasks' '' \
  '- [ ] **T1** First · `a` · check: `test -f specs/constitution.md` → AC-1' \
  '- [ ] **T2** Second · `b` · check: manual: look at it → AC-1' > "$dir/tasks.md"
to_crlf "$dir/tasks.md"

check "claim next picks T1" test "$("$JSDD" claim 001 next 2>/dev/null)" = T1
check "T2 waits on T1" sh -c '! "$1" claim 001 T2 >/dev/null 2>&1' _ "$JSDD"
out=$("$JSDD" done 001 T1 2>&1)
check "done runs the check and ticks T1" has "$out" 'check passed; ticked 001 T1'
check "the ticked line stays CRLF" sh -c "grep -q '^- \[x\] \*\*T1\*\*.*AC-1.\$' '$dir/tasks.md' && [ \"\$(grep -c \"\$(printf '\r')\$\" '$dir/tasks.md')\" = 4 ]"
"$JSDD" claim 001 T2 >/dev/null
out=$("$JSDD" done 001 T2 --manual 'smoke looked' 2>&1)
check "done --manual records the note" grep -q 'T2.*checked: smoke looked' "$dir/tasks.md"
out=$("$JSDD" status)
check "status counts the ticks" has "$out" '| 2/2 |'
out=$("$JSDD" claims)
check "claims lists the done tasks" has "$out" '001 T1   done'

to_crlf docs/requirements.md
out=$("$JSDD" coverage)
check "coverage reads CRLF requirements" has "$out" 'FR-AUTH-01'

# --- hooks -----------------------------------------------------------------
# Hook input as Claude Code sends it on this platform; run the way hooks.json does.
hook() { local h=$1; shift; printf '%s' "$1" | bash "$HOOKS/$h.sh"; }
cwd=$(json_str "$(native_path "$P")")
bash_input() { printf '{"session_id":"smoke-session","cwd":%s,"tool_name":"Bash","tool_input":{"command":%s}}' "$cwd" "$(json_str "$1")"; }

rc=0; hook pre-commit-message "$(bash_input 'git commit -m "add login"')" 2>/dev/null || rc=$?
check "commit hook blocks a message with no spec ID" test "$rc" = 2
rc=0; hook pre-commit-message "$(bash_input 'git commit -m "[001] T1 Add login"')" || rc=$?
check "commit hook allows [001] T1" test "$rc" = 0
rc=0; hook pre-commit-message "$(bash_input "git -C . commit -F - <<'EOF'
[meta] Tidy é
EOF")" || rc=$?
check "commit hook reads a heredoc message" test "$rc" = 0
rc=0; hook pre-commit-message "$(bash_input 'git status')" || rc=$?
check "commit hook ignores other commands" test "$rc" = 0

rm -f specs/STATUS.md
file=$(json_str "$(native_path "$P/$dir/tasks.md")")
hook post-edit-status "{\"cwd\":$cwd,\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":$file}}"
check "edit hook regenerates STATUS.md from a native path" test -f specs/STATUS.md
rm -f specs/STATUS.md
file=$(json_str "$(native_path "$P/docs/intent.md")")
hook post-edit-status "{\"cwd\":$cwd,\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":$file}}"
check "edit hook ignores other files" test ! -f specs/STATUS.md

out=$(hook session-start "{\"cwd\":$cwd,\"hook_event_name\":\"SessionStart\"}")
check "session-start prints the board" has "$out" 'Spec board (jsdd status):'
check "session-start finds jq and Python" sh -c '! printf "%s" "$1" | grep -q "jsdd: missing"' _ "$out"

"$JSDD" claim 001 >/dev/null
out=$(hook stop-claims "{\"session_id\":\"smoke-session\",\"cwd\":$cwd}")
check "stop hook warns about held claims" has "$out" 'still holds jsdd claims: 001'
out=$(hook stop-claims "{\"session_id\":\"other-session\",\"cwd\":$cwd}")
check "stop hook is quiet for another session" test -z "$out"

# Hooks exit quietly outside a jsdd project.
mkdir "$WORK/plain"
out=$(cd "$WORK/plain" && hook session-start "{\"cwd\":$(json_str "$(native_path "$WORK/plain")")}")
check "hooks are quiet outside a jsdd project" test -z "$out"

echo
if [ "$fails" -gt 0 ]; then echo "$fails failed" >&2; exit 1; fi
echo "all passed"
