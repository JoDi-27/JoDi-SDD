#!/usr/bin/env bash
# One feature from planned to done, the way /jsdd:implement, /jsdd:verify, and
# /jsdd:plan drive it: two sessions sharing the tasks, checks that really fail,
# the board's "ready to verify", each verification outcome, and an amendment.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-NOTE-01|A user can add a note|M" "FR-NOTE-02|A user can delete a note|M"
spec=$(jsdd new feature "Notes")
dir=$(dirname "$spec")
frontmatter "$spec" refs '["FR-NOTE-01", "FR-NOTE-02"]'
frontmatter "$spec" status planned
cat >"$dir/tasks.md" <<'TASKS'
# 001 · Tasks: Notes

## Tasks

- [ ] **T1** Add the store · `store` · check: `test -f store.txt` → AC-1
- [ ] **T2** [P] Add notes · `add` · check: `test -f add.txt` → AC-1
- [ ] **T3** [P] Delete notes · `delete` · check: `test -f delete.txt` → AC-2
- [ ] **T4** Try it by hand · check: manual: a person adds and deletes a note → AC-1, AC-2

## Evidence
TASKS

step "a planned spec is next, with its first free task"
expect "/jsdd:implement 001   (T1 free)" jsdd next
expect "| FR-NOTE-01 | M | 001:planned |" jsdd coverage

step "tasks are claimed in order, and only by one session"
frontmatter "$spec" status in-progress
[ "$(jsdd claim 001 next)" = T1 ] || fail "claim next did not give T1"
[ "$(jsdd claim 001 next 2>/dev/null)" = T1 ] || fail "claim next did not return the task this session holds"
refuses as session-b jsdd claim 001 next
refuses as session-b jsdd claim 001 T2

step "a task is ticked only when its check passes"
refuses jsdd done 001 T1
grep -q '^- \[ \] \*\*T1\*\*' "$dir/tasks.md" || fail "a failing check ticked T1"
touch store.txt
out=$(jsdd done 001 T1)
has "$out" "ticked 001 T1" || fail "done did not tick T1: $out"
! has "$out" "/jsdd:verify" || fail "done pointed to verify with tasks open: $out"

step "parallel [P] tasks go to different sessions; the next waits for both"
[ "$(jsdd claim 001 next)" = T2 ] || fail "session a did not get T2"
[ "$(as session-b jsdd claim 001 next)" = T3 ] || fail "session b did not get the parallel T3"
refuses as session-c jsdd claim 001 next
touch add.txt delete.txt
jsdd done 001 T2 >/dev/null
as session-b jsdd done 001 T3 >/dev/null
expect "001 T3   done     by session-" jsdd claims

step "a manual check needs a note"
jsdd claim 001 next >/dev/null
refuses jsdd done 001 T4
out=$(jsdd done 001 T4 --manual "scenario added and deleted a note")
has "$out" "next: /jsdd:verify 001" || fail "done on the last task did not point to verify: $out"
grep -q 'T4.*checked: scenario added and deleted a note' "$dir/tasks.md" || fail "the manual note was not recorded"

step "the board shows the spec ready to verify"
out=$(jsdd status --write)
has "$out" "| 4/4 ready to verify |" || fail "status did not mark the spec ready: $out"
has "$out" "in-progress 1 (1 ready to verify)" || fail "status summary did not count it: $out"
grep -q '4/4 ready to verify' specs/STATUS.md || fail "STATUS.md does not show the spec ready"
expect "/jsdd:verify 001" jsdd next

report() { printf '%s\n' '# 001 · Verify report' '' "**Decision:** $1" >"$dir/verify-report.md"; }

step "verification: gaps declined block the spec until /jsdd:plan"
report "declined (scenario, 2026-11-05)"
frontmatter "$spec" status blocked
expect "blocked: verification declined; resume with /jsdd:plan 001" jsdd next

step "verification: a spec change goes to /jsdd:specify first"
report "approved (scenario, 2026-11-05)"
frontmatter "$spec" status draft
expect "/jsdd:specify 001, then /jsdd:plan 001   (spec change from verify)" jsdd next

step "verification: approved fixes go to /jsdd:plan"
frontmatter "$spec" status approved
expect "/jsdd:plan 001" jsdd next

step "an amendment's task reopens the spec"
edit "$dir/tasks.md" 's|^## Evidence|### A1 · Follow-up from verify round 1\
\
- [ ] **T5** Reject an empty note · `add` · check: `test -f empty.txt` → AC-1 (A1/G1)\
\
## Evidence|'
frontmatter "$spec" status planned
out=$(jsdd status)
has "$out" "| 4/5 |" || fail "the amendment's task was not counted: $out"
! has "$out" "ready to verify" || fail "a spec with an open amendment task shows ready: $out"
expect "/jsdd:implement 001   (T5 free)" jsdd next
frontmatter "$spec" status in-progress
[ "$(jsdd claim 001 next)" = T5 ] || fail "claim next did not give the amendment's T5"
touch empty.txt
expect "next: /jsdd:verify 001" jsdd done 001 T5
expect "| 5/5 ready to verify |" jsdd status

step "closing the spec counts its requirements as done and frees its claims"
frontmatter "$spec" status done
expect "Must                  2   with a spec   2   done   2" jsdd coverage
jsdd release 001 >/dev/null 2>&1 || true
git add -A && git commit -qm "[001] Close"
jsdd claims --prune >/dev/null
expect "(no claims)" jsdd claims
