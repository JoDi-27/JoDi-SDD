#!/usr/bin/env bash
# Autopilot: the mode needs the project's consent and the person's; a run is
# marked per session and the Stop hook keeps it going only while it makes
# progress; parking takes a spec out of the queue and onto "Waiting for you";
# frozen checks stop a task's check from changing quietly; protected files
# cannot be edited during a run; a pull request body comes from the spec.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-NOTE-01|A user can add a note|M"
spec=$(jsdd new feature "Notes")
dir=$(dirname "$spec")
frontmatter "$spec" refs '["FR-NOTE-01"]'
git add -A && git commit -qm "[001] Spec"
auto() { SDD_MODE=autopilot "$KIT/bin/jsdd" "$@"; }
hook() { printf '%s' "$2" | SDD_MODE=autopilot bash "$KIT/hooks/$1"; }

step "autopilot needs specs/jsdd.yml to allow it, and SDD_MODE to pick it"
expect "not allowed here" auto mode
refuses auto run start 001
printf 'version: 1\nmodes: [manual, autopilot]\ndefault: autopilot\n' >specs/jsdd.yml
expect "default cannot be autopilot" jsdd mode --check
printf 'version: 1\nmodes: [manual, autopilot]\nautopilot:\n  attempts_per_task: 5\n  verify.capability_merge: auto\n' >specs/jsdd.yml
jsdd mode --check >/dev/null || fail "--check refused a valid autopilot config"
expect "mode: manual" jsdd mode
expect "mode: autopilot (SDD_MODE)" auto mode
expect "MODE: autopilot" auto status

step "gates: the person's steps ask, the build passes on its own, people's decisions park"
for g in spec.clarify spec.split spike.question baseline.rows; do [ "$(auto gate $g)" = ask ] || fail "$g does not ask"; done
for g in spec.approve plan.approve implement.stuck commit verify.gaps verify.gap_option pr.open verify.capability_merge; do
  [ "$(auto gate $g)" = auto ] || fail "$g does not pass on its own"
done
for g in spec.change task.manual_check depends.override verify.partial_ref merge; do [ "$(auto gate $g)" = park ] || fail "$g does not park"; done
[ "$(jsdd gate pr.open)" = ask ] || fail "pr.open does not ask in manual mode"

step "budgets: the catalog's default, the project's value, and range checks"
[ "$(auto budget attempts_per_task)" = 5 ] || fail "the project's attempts_per_task was not used"
[ "$(auto budget wall_time_hours)" = 4 ] || fail "wall_time_hours is not the default 4"
expect "attempts_per_task" auto mode --explain
printf 'version: 1\nmodes: [manual, autopilot]\nautopilot:\n  wall_time_hours: 99\n' >specs/jsdd.yml
expect "is not a whole number from 1 to 24" jsdd mode --check
printf 'version: 1\nmodes: [manual, autopilot]\n' >specs/jsdd.yml

step "a run is held by one session; the Stop hook blocks while it makes progress"
refuses jsdd run start 001
expect "run 001 started" auto run start 001
expect "already started by you" auto run start 001
refuses as session-b env SDD_MODE=autopilot "$KIT/bin/jsdd" run start 001
[ "$(auto run active)" = 001 ] || fail "run active did not list 001"
[ -z "$(as session-b jsdd run active)" ] || fail "another session sees this run as its own"
expect "4h left" auto run status 001
input='{"session_id":"session-a","cwd":"'"$PWD"'","stop_hook_active":false}'
expect '"decision": "block"' hook stop-autopilot.sh "$input"
again='{"session_id":"session-a","cwd":"'"$PWD"'","stop_hook_active":true}'
expect "made no progress" hook stop-autopilot.sh "$again"
echo work >note.txt
expect '"decision": "block"' hook stop-autopilot.sh "$again"
other='{"session_id":"session-b","cwd":"'"$PWD"'","stop_hook_active":false}'
[ -z "$(hook stop-autopilot.sh "$other")" ] || fail "the Stop hook blocked a session with no run"
out=$(hook stop-claims.sh '{"session_id":"session-a","cwd":"'"$PWD"'"}')
has "$out" "run-001" && fail "stop-claims reported the run as a held claim"

step "protected files cannot be edited during a run"
edit_input() { printf '{"session_id":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$PWD" "$PWD/$2"; }
refuses hook protect-run-files.sh "$(edit_input session-a specs/constitution.md)"
refuses hook protect-run-files.sh "$(edit_input session-a "$dir/checks.lock")"
hook protect-run-files.sh "$(edit_input session-a "$dir/plan.md")" || fail "a plan edit was blocked"
hook protect-run-files.sh "$(edit_input session-b specs/constitution.md)" || fail "a session with no run was blocked"

step "frozen checks: done refuses a changed check or an unfrozen task"
frontmatter "$spec" status in-progress
cat >"$dir/tasks.md" <<'TASKS'
# 001 · Tasks: Notes

## Tasks

- [ ] **T1** Add notes · `notes` · check: `test -f add.txt` → AC-1
- [ ] **T2** Try it · check: manual: a person adds a note → AC-1

## Evidence

| Acceptance criterion | Result | Evidence (test, command output, manual check) |
| --- | --- | --- |
| AC-1 | pass | test -f add.txt |
TASKS
printf '# Plan\n\n## Deviations\n\n## Amendments\n' >"$dir/plan.md"
expect "2 tasks, 2 new" jsdd freeze 001
expect "T2	manual" cat "$dir/checks.lock"
edit "$dir/tasks.md" 's/test -f add.txt` → AC-1/true` → AC-1/'
jsdd claim 001 next >/dev/null
expect "changed since the plan was approved" jsdd done 001 T1
grep -q '^- \[ \] \*\*T1\*\*' "$dir/tasks.md" || fail "a changed check ticked T1"
expect "checks changed since they were frozen" jsdd freeze 001
expect "needs a row in plan.md's Deviations" jsdd freeze 001 --accept T1
printf '# Plan\n\n## Deviations\n\n- T1: the file check was wrong; true is enough (reviewer accepted)\n\n## Amendments\n' >"$dir/plan.md"
expect "2 tasks, 0 new" jsdd freeze 001 --accept T1
expect "ticked 001 T1" jsdd done 001 T1
awk '/\*\*T2\*\*/ { print; print "- [ ] **T3** Extra · check: `true` → AC-1"; next } 1' "$dir/tasks.md" >"$dir/t" && mv "$dir/t" "$dir/tasks.md"
jsdd claim 001 next >/dev/null
jsdd done 001 T2 --manual "scenario" >/dev/null
jsdd claim 001 next >/dev/null
expect "not in checks.lock" jsdd done 001 T3

step "parking: off the queue, onto Waiting for you, with a changelog line; unpark puts it back"
refuses jsdd park 001 no.such.gate "why"
expect "parked 001 at spec.change" auto park 001 spec.change 'R2 contradicts the "notes" row'
[ "$(jsdd unpark 001 >/dev/null; jsdd park 001 spec.change 'R2 contradicts the "notes" row' >/dev/null; sed -n 's/^parked: //p' "$spec")" = '"spec.change: R2 contradicts the \"notes\" row"' ] \
  || fail "the parked line is not quoted: $(grep '^parked:' "$spec")"
expect 'R2 contradicts the "notes" row' jsdd status
out=$(jsdd next)
has "$out" "Waiting for you:" || fail "next has no Waiting for you section: $out"
has "$out" "/jsdd:implement 001" && fail "next offers a parked spec: $out"
expect "in-progress, parked" jsdd status
grep -q "Parked at gate spec.change" "$spec" || fail "no changelog line for the park"
expect "parked at spec.change" hook stop-autopilot.sh "$input"
expect "made no progress" hook stop-autopilot.sh "$again"
expect "is parked" auto run start 001
expect "unparked 001" jsdd unpark 001
grep -q '^parked:' "$spec" && fail "unpark left the parked line"
grep -q "Unparked." "$spec" || fail "no changelog line for the unpark"

step "a pull request body from the spec, evidence, and run report"
printf '# Run report\n\n## Decisions made without a person\n\n- Plan approved (auto: plan.approve, sdd-reviewer)\n' >"$dir/run-report.md"
[ "$(jsdd pr 001 --title)" = "[001] Notes" ] || fail "pr --title is wrong: $(jsdd pr 001 --title)"
out=$(jsdd pr 001)
for want in "Spec [001](specs/001-notes/spec.md)" "refs FR-NOTE-01" "## Acceptance criteria and evidence" "| AC-1 | pass |" \
  "## Deviations from the plan" "## Decisions made without a person" "auto: plan.approve" "run-report.md"; do
  has "$out" "$want" || fail "the PR body lacks: $want. Got:
$out"
done

step "the run ends; the Stop hook lets the session stop"
expect "run 001 ended" auto run end 001
[ -z "$(hook stop-autopilot.sh "$input")" ] || fail "the Stop hook still blocks after the run ended"
expect "no run on 001" auto run end 001
