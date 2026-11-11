#!/usr/bin/env bash
# Tasks written as blocks: a head line with the checkbox, then indented
# sub-bullets for the files, the check, and notes. The check is read from the
# body, a manual note lands under the block, one-line tasks keep working beside
# them, and ticks on consecutive blocks merge across worktrees without conflict.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
spec=$(jsdd new feature "Receiver")
dir=$(dirname "$spec")
frontmatter "$spec" status in-progress
cat >"$dir/tasks.md" <<'TASKS'
# 001 · Tasks: Receiver

## Tasks

<!-- - [ ] **T9** A commented-out task · check: `false` -->

- [ ] **T1** Add the receiver's decision, test first → AC-1
  - files: `receiver/app.py`, `tests/test_receiver.py`
  - check: `test -f decision.txt`
  - The health check: endpoint returns 200; this prose is not the check.

- [ ] **T2** [P] Add the caller check → AC-4
  - files: `receiver/app.py`

    A longer note, after a blank line inside the block.
  - check: `test -f caller.txt`

- [ ] **T3** [P] Add the image → AC-6
  - check: `test -f image.txt`

- [ ] **T4** One-line task · `x` · check: `test -f one.txt` → AC-1

- [ ] **T5** Try it by hand → AC-7
  - check: manual: a person posts to /sweep without a token and gets 401
  - files: none

- [ ] **T6** Two checks by mistake · check: `true` → AC-1
  - check: `true`

## Evidence
TASKS

step "a block's check comes from its body, and only a passing check ticks the head"
[ "$(jsdd claim 001 next)" = T1 ] || fail "claim next did not give T1"
expect "check: test -f decision.txt" jsdd done 001 T1
grep -q '^- \[ \] \*\*T1\*\*' "$dir/tasks.md" || fail "a failing body check ticked T1"
touch decision.txt
out=$(jsdd done 001 T1)
has "$out" "ticked 001 T1" || fail "done did not tick T1: $out"
grep -q '^- \[x\] \*\*T1\*\*' "$dir/tasks.md" || fail "the head line of T1 is not ticked"
grep -q '^  - check: `test -f decision.txt`$' "$dir/tasks.md" || fail "the tick changed T1's body"

step "[P] on a block head is still parallel, and a blank line inside a body keeps the block"
[ "$(jsdd claim 001 next)" = T2 ] || fail "session a did not get T2"
[ "$(as session-b jsdd claim 001 next)" = T3 ] || fail "session b did not get the parallel T3"
expect "check: test -f caller.txt" jsdd done 001 T2
touch caller.txt image.txt
jsdd done 001 T2 >/dev/null
as session-b jsdd done 001 T3 >/dev/null

step "a one-line task beside blocks works as before"
jsdd claim 001 next >/dev/null
touch one.txt
expect "ticked 001 T4" jsdd done 001 T4

step "a manual check in a body needs a note, which lands under the block"
[ "$(jsdd claim 001 next)" = T5 ] || fail "claim next did not give T5"
expect "--manual" jsdd done 001 T5
jsdd done 001 T5 --manual "scenario got 401 without a token" >/dev/null
awk '/\*\*T5\*\*/ { s = 1 } s && /^  - files: none$/ { getline; print; exit }' "$dir/tasks.md" | grep -q '^  - checked: scenario got 401 without a token (' \
  || fail "the manual note is not a sub-bullet after T5's last line: $(cat "$dir/tasks.md")"
grep -q '^- \[x\] \*\*T5\*\* Try it by hand → AC-7$' "$dir/tasks.md" || fail "the note was put on T5's head line"

step "two checks on one task are refused by done and freeze"
jsdd claim 001 next >/dev/null
expect "more than one check" jsdd done 001 T6
grep -q '^- \[ \] \*\*T6\*\*' "$dir/tasks.md" || fail "a task with two checks was ticked"
printf '# Plan\n\n## Deviations\n\n## Amendments\n' >"$dir/plan.md"
expect "T6 has more than one check" jsdd freeze 001
edit "$dir/tasks.md" 's/^- \[ \] \*\*T6\*\* Two checks by mistake · check: `true` → AC-1$/- [ ] **T6** One check now → AC-1/'
out=$(jsdd done 001 T6)
has "$out" "ticked 001 T6" && has "$out" "every task of 001 is ticked" || fail "T6 with one check was not ticked: $out"

step "freeze records a body check, and done refuses it once changed"
spec2=$(jsdd new feature "Frozen")
dir2=$(dirname "$spec2")
frontmatter "$spec2" status in-progress
printf '%s\n' '# 002 · Tasks' '' '## Tasks' '' '- [ ] **T1** Build it → AC-1' '  - check: `test -f built.txt`' >"$dir2/tasks.md"
printf '# Plan\n\n## Deviations\n\n## Amendments\n' >"$dir2/plan.md"
expect "1 tasks, 1 new" jsdd freeze 002
expect "T1	test -f built.txt" cat "$dir2/checks.lock"
edit "$dir2/tasks.md" 's/test -f built.txt/true/'
jsdd claim 002 next >/dev/null
expect "changed since the plan was approved" jsdd done 002 T1

step "ticks on consecutive blocks in two worktrees merge without a conflict"
spec3=$(jsdd new feature "Merge")
dir3=$(dirname "$spec3")
frontmatter "$spec3" status in-progress
printf '%s\n' '# 003 · Tasks' '' '## Tasks' '' \
  '- [ ] **T1** [P] One → AC-1' '  - check: `true`' '' \
  '- [ ] **T2** [P] Two → AC-1' '  - check: `true`' >"$dir3/tasks.md"
git add -A && git commit -qm "[003] Plan merge"
wt=$TMP/wt
git worktree add -q "$wt" -b other
[ "$(jsdd claim 003 next)" = T1 ] || fail "main did not get T1 of 003"
[ "$(cd "$wt" && as session-b jsdd claim 003 next)" = T2 ] || fail "the worktree did not get T2 of 003"
jsdd done 003 T1 >/dev/null
(cd "$wt" && as session-b jsdd done 003 T2 >/dev/null)
git commit -qam "[003] T1"
(cd "$wt" && git commit -qam "[003] T2")
git merge -q --no-edit other >/dev/null || fail "ticks on consecutive blocks conflicted"
[ "$(grep -c '^- \[x\]' "$dir3/tasks.md")" = 2 ] || fail "the merge lost a tick: $(cat "$dir3/tasks.md")"
