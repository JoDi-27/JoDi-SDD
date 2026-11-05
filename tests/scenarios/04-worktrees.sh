#!/usr/bin/env bash
# Sessions working in parallel git worktrees of one repository: claims and new
# spec IDs are shared through the git common dir, so two worktrees never take
# the same spec, task, or ID, and prune keeps what another branch still needs.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
spec=$(jsdd new feature "Shared work")
frontmatter "$spec" status planned
printf '%s\n' '# 001 · Tasks' '' '## Tasks' '' '- [ ] **T1** One · check: `true` → AC-1' '- [ ] **T2** Two · check: `true` → AC-1' >"$(dirname "$spec")/tasks.md"
git add -A && git commit -qm "[001] Specify shared work"
wt=$TMP/wt
git worktree add -q "$wt" -b other

step "a spec claimed in one worktree is refused in another"
jsdd claim 001 >/dev/null
out=$(cd "$wt" && as session-b jsdd claim 001 2>&1) && fail "worktree b claimed a spec held in main: $out"
has "$out" "session-" || fail "the refusal did not say who holds 001: $out"
expect "001      claimed  by you" jsdd claims
jsdd release 001 >/dev/null

step "tasks are shared too"
[ "$(jsdd claim 001 next)" = T1 ] || fail "main did not get T1"
refuses sh -c "cd '$wt' && CLAUDE_CODE_SESSION_ID=session-b '$KIT/bin/jsdd' claim 001 next"

step "new spec IDs never collide across worktrees"
other=$(cd "$wt" && as session-b jsdd new feature "Only on the other branch")
case $other in specs/002-*) ;; *) fail "worktree b did not get 002: $other" ;; esac
mine=$(jsdd new feature "On main")
case $mine in specs/003-*) ;; *) fail "main reused an ID reserved in another worktree: $mine" ;; esac

step "prune keeps the reservation of a spec that only another branch has"
git add -A && git commit -qm "[003] Specify on main"
jsdd claims --prune >/dev/null
again=$(jsdd new feature "After prune")
case $again in specs/004-*) ;; *) fail "after prune, main reused the other branch's ID: $again" ;; esac

step "depends_on with quoted IDs, as refs are written"
frontmatter "$again" depends_on "['001', \"003\"]"
expect "004  waiting on 001 003" jsdd next
frontmatter "$spec" status done
frontmatter "$mine" status done
! has "$(jsdd next)" "waiting on" || fail "004 still waits after 001 and 003 are done: $(jsdd next)"
expect "| 004 | feature | draft | - | - |  | 001,003 |" jsdd status
