#!/usr/bin/env bash
# smoke: run jsdd and the hooks end to end in a throwaway git repository.
# Usage: smoke.sh   (from anywhere; uses the checkout it lives in)
# CI runs it on Linux, macOS (bash 3.2), and Windows (Git Bash). There, project
# files may be CRLF and hook input has C:\ paths, so it tests both everywhere.
set -euo pipefail

kit=$(cd "$(dirname "$0")/../.." && pwd)
jsdd=$kit/bin/jsdd
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# The scripts run `env bash`: point that at the bash running this script, so
# `/bin/bash smoke.sh` tests macOS's bash 3.2 even when a newer one is on PATH.
# (Not on Windows, where ln -s copies bash.exe; Git Bash has one bash.)
mkdir "$tmp/bin" "$tmp/proj"
case $OSTYPE in
  msys*|cygwin*) ;;
  *) ln -s "$BASH" "$tmp/bin/bash"; PATH=$tmp/bin:$PATH ;;
esac
proj=$tmp/proj
cd "$proj"
git init -q -b main 2>/dev/null || { git init -q && git checkout -q -b main; }
git config user.name smoke
git config user.email smoke@example.com

step() { printf '\n== %s\n' "$*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
# has <text> <substring>
has() { case $1 in *"$2"*) return 0 ;; esac; return 1; }
# to_crlf <file>: as a Windows checkout with core.autocrlf has it.
to_crlf() { awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$1" >"$1.crlf" && mv "$1.crlf" "$1"; }
# native <path>: the path as Claude Code sends it in hook input (C:\... on Windows).
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
# str <s>: s as a JSON string.
str() { jq -Rn --arg s "$1" '$s' | tr -d '\r'; }
# hook <name> <json>: run a hook the way hooks.json does.
hook() { printf '%s' "$2" | bash "$kit/hooks/$1.sh"; }

step "hooks stay quiet before init"
for h in "$kit"/hooks/*.sh; do
  case $h in */_lib.sh) continue ;; esac   # sourced by the hooks, not one itself
  out=$(printf '{"cwd":"%s","session_id":"s","tool_input":{"command":"git commit -m x","file_path":"x"}}' "$proj" | "$h")
  [ -z "$out" ] || fail "$(basename "$h") printed output in a project without jsdd: $out"
done

step "init lists documents that may hold a starter's content"
mkdir -p docs/adr
echo "# Product intent" >PRODUCT_INTENT.md
echo "# PRD" >docs/PRD.md
echo "# Use Postgres" >docs/adr/0001-use-postgres.md
echo "# Readme" >README.md
out=$("$jsdd" init --dry-run)
has "$out" "source   PRODUCT_INTENT.md (the install.sh kit's intent file) for docs/intent.md" || fail "init did not list PRODUCT_INTENT.md: $out"
has "$out" "source   docs/PRD.md for docs/intent.md and docs/requirements.md" || fail "init did not list docs/PRD.md: $out"
has "$out" "source   docs/adr/ for docs/decisions.md" || fail "init did not list docs/adr/: $out"
! has "$out" "README.md for" || fail "init listed README.md as a source: $out"
! has "$out" "0001-use-postgres" || fail "init listed a file inside docs/adr/ on its own: $out"

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
out=$("$jsdd" init --dry-run)
! has "$out" "PRODUCT_INTENT.md" || fail "init listed a source for docs/intent.md once it was filled in: $out"
has "$out" "docs/adr/ for docs/decisions.md" || fail "init stopped listing docs/adr/ while docs/decisions.md is blank: $out"
rm -r PRODUCT_INTENT.md docs/PRD.md docs/adr README.md

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

step "CRLF spec, tasks, and requirements"
spec=$("$jsdd" new feature 'Login "fast" | flow')
dir=$(dirname "$spec")
sed 's/^status: draft/status: planned/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"
printf '%s\n' '# Tasks' '' \
  '- [ ] **T1** First · `a` · check: `test -f specs/constitution.md` → AC-1' \
  '- [ ] **T2** Second · `b` · check: manual: look at it → AC-1' >"$dir/tasks.md"
for f in "$spec" "$dir/tasks.md" docs/requirements.md; do to_crlf "$f"; done
[ "$(tr -cd '\r' <"$dir/tasks.md" | wc -c | tr -d ' ')" = 4 ] || fail "to_crlf did not write CRLF: $(od -c "$dir/tasks.md" | head -4)"
out=$("$jsdd" status)
has "$out" '| 003 | feature | planned | - | 0/2 |' || fail "status misread a CRLF spec: $out"
has "$out" 'Login "fast" \| flow' || fail "status lost the quoted title"
has "$("$jsdd" coverage)" FR-AUTH-01 || fail "coverage misread CRLF requirements"

step "claim next, done"
export CLAUDE_CODE_SESSION_ID=smoke
[ "$("$jsdd" claim 003 next)" = T1 ] || fail "claim next did not pick T1"
if "$jsdd" claim 003 T2 2>/dev/null; then fail "T2 was claimed before T1 was done"; fi
"$jsdd" done 003 T1
grep -q '^- \[x\] \*\*T1\*\*' "$dir/tasks.md" || fail "done did not tick T1"
# (Count CRs with tr: grep in Git Bash drops them before matching.)
crs() { tr -cd '\r' <"$1" | wc -c | tr -d ' '; }
[ "$(crs "$dir/tasks.md")" = 4 ] || fail "done changed the CRLF line endings: $(crs "$dir/tasks.md") CRs in 4 lines: $(od -c "$dir/tasks.md" | head -4)"
"$jsdd" claim 003 T2
"$jsdd" done 003 T2 --manual "smoke looked"
grep -q 'T2.*checked: smoke looked' "$dir/tasks.md" || fail "done --manual did not record the note"
has "$("$jsdd" status)" '| 2/2 |' || fail "status did not count the ticks"

step "blocked by a declined verification"
sed 's/^status: planned/status: blocked/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"
printf '%s\n' '# Verify report' '' '**Decision:** declined (smoke, 2026-11-03)' >"$dir/verify-report.md"
to_crlf "$dir/verify-report.md"
has "$("$jsdd" next)" 'resume with /jsdd:plan 003' || fail "next did not offer to resume the blocked verification: $("$jsdd" next)"
rm "$dir/verify-report.md"
has "$("$jsdd" next)" '003  blocked (see spec)' || fail "next showed a resume hint without a declined report"

step "draft for a spec change a verification found"
sed 's/^status: blocked/status: draft/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"
printf '%s\n' '# Verify report' '' '**Decision:** approved (smoke, 2026-11-04)' >"$dir/verify-report.md"
to_crlf "$dir/verify-report.md"
has "$("$jsdd" next)" '(spec change from verify)' || fail "next did not point a verify spec change to /jsdd:specify: $("$jsdd" next)"
rm "$dir/verify-report.md"
sed 's/^status: draft/status: in-progress/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"

step "commit-message hook"
cwd=$(str "$(native "$proj")")
commit() { printf '{"session_id":"smoke","cwd":%s,"tool_name":"Bash","tool_input":{"command":%s}}' "$cwd" "$(str "$1")"; }
rc=0; hook pre-commit-message "$(commit 'git commit -m "add login"')" 2>/dev/null || rc=$?
[ $rc = 2 ] || fail "a message without a spec ID was not blocked (exit $rc)"
hook pre-commit-message "$(commit 'git commit -m "[003] T1 Add login"')" || fail "[003] T1 was blocked"
hook pre-commit-message "$(commit "git -C . commit -F - <<'EOF'
[meta] Tidy é
EOF")" || fail "a heredoc [meta] message was blocked"

step "edit hook with a native path"
rm -f specs/STATUS.md
hook post-edit-status "{\"cwd\":$cwd,\"tool_input\":{\"file_path\":$(str "$(native "$proj/$dir/tasks.md")")}}"
[ -f specs/STATUS.md ] || fail "editing tasks.md did not regenerate STATUS.md"
rm specs/STATUS.md
hook post-edit-status "{\"cwd\":$cwd,\"tool_input\":{\"file_path\":$(str "$(native "$proj/docs/intent.md")")}}"
[ ! -f specs/STATUS.md ] || fail "editing docs/intent.md regenerated STATUS.md"

step "session-start and stop hooks"
out=$(hook session-start "{\"cwd\":$cwd}")
has "$out" "Spec board" || fail "session-start printed no board"
! has "$out" "jsdd: missing" || fail "session-start did not find jq or Python: $out"
"$jsdd" claim 001
# (JSON in variables: bash 3.2 brace-expands {a,b} inside "$(...)".)
mine="{\"session_id\":\"smoke\",\"cwd\":$cwd}"
other="{\"session_id\":\"other\",\"cwd\":$cwd}"
out=$(hook stop-claims "$mine")
has "$out" "still holds jsdd claims: 001" || fail "the stop hook did not warn about a held claim: $out"
out=$(hook stop-claims "$other")
[ -z "$out" ] || fail "the stop hook warned another session: $out"

step "capabilities"
# 003 added FR-AUTH-01 and is done; 001 is about to change it.
sed 's/^| FR-XXX-NN | adds |/| FR-AUTH-01 | modifies |/' specs/001-*/spec.md >"$tmp/s" && mv "$tmp/s" specs/001-password-reset-by-email/spec.md
sed 's/^| FR-XXX-NN | adds |/| FR-AUTH-01 | adds |/; s/^status: in-progress/status: done/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"
out=$("$jsdd" capabilities)
has "$out" 'not merged: 003 adds FR-AUTH-01' || fail "capabilities did not flag an unmerged done spec: $out"
if "$jsdd" capabilities --check >/dev/null; then fail "capabilities --check passed with an unmerged spec"; fi
mkdir -p docs/capabilities
printf '%s\n' '# Accounts (FR-AUTH)' '' '<!-- ## FR-AUTH-07 · in a comment -->' '## FR-AUTH-01 · Sign in' '' 'Last changed: 003 (2026-11-04)' '' \
  '- When a user signs in, the system shall ...' '' '## History' '' '| Date | Spec | Row | Change |' '| --- | --- | --- | --- |' \
  '| 2026-11-04 | 003 | FR-AUTH-01 | adds |' >docs/capabilities/auth.md
to_crlf docs/capabilities/auth.md
out=$("$jsdd" capabilities --check FR-AUTH) || fail "capabilities --check failed after the merge: $out"
has "$out" '| FR-AUTH-01 | auth.md | 003 | 001 modifies (draft) |' || fail "capabilities misread the entry or the pending change: $out"
printf '%s\r\n' '## FR-AUTH-09 · Gone' >>docs/capabilities/auth.md
has "$("$jsdd" capabilities)" 'FR-AUTH-09: entry in auth.md has no row' || fail "capabilities did not flag an entry with no row"
# A baseline has no table: each row in its refs is an "adds".
b=$("$jsdd" new baseline "Accounts: current behavior")
sed 's/^refs: \[\]/refs: ["FR-AUTH-01"]/; s/^status: draft/status: done/' "$b" >"$b.tmp" && mv "$b.tmp" "$b"
has "$("$jsdd" capabilities FR-AUTH-01)" 'not merged: 004 adds FR-AUTH-01' || fail "capabilities did not flag an unmerged baseline: $("$jsdd" capabilities FR-AUTH-01)"
awk '{ print } /\| 003 \| FR-AUTH-01 \| adds \|/ { printf "| 2026-11-04 | 004 | FR-AUTH-01 | adds |\r\n" }' docs/capabilities/auth.md >"$tmp/a" && mv "$tmp/a" docs/capabilities/auth.md
"$jsdd" capabilities --check FR-AUTH-01 >/dev/null || fail "capabilities --check failed after the baseline was merged: $("$jsdd" capabilities FR-AUTH-01)"
rm -r docs/capabilities
sed 's/^status: done/status: in-progress/' "$spec" >"$spec.tmp" && mv "$spec.tmp" "$spec"

printf '\nsmoke: ok\n'
