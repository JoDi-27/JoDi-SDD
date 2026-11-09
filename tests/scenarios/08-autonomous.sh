#!/usr/bin/env bash
# Autonomous: the charter (the autonomous section of specs/jsdd.yml) is
# validated and fails closed; presets set gates and project gates win over them;
# the queue follows the charter's scope and skips what only a person can move;
# a dry run says where each spec would park; a loop takes specs one at a time
# within its budgets, and the Stop hook keeps it going only while it has work.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-NOTE-01|A user can add a note|M" "FR-BILL-01|A user can pay|M"
auto() { SDD_MODE=autonomous "$KIT/bin/jsdd" "$@"; }
hook() { printf '%s' "$2" | SDD_MODE=autonomous bash "$KIT/hooks/$1"; }
s1=$(jsdd new feature "Notes"); frontmatter "$s1" refs '["FR-NOTE-01"]'; frontmatter "$s1" phase 1; frontmatter "$s1" status approved
s2=$(jsdd new feature "Billing"); frontmatter "$s2" refs '["FR-BILL-01"]'; frontmatter "$s2" phase 1
s3=$(jsdd new feature "Search"); frontmatter "$s3" phase 2
s4=$(jsdd new feature "Tags"); frontmatter "$s4" phase 1; frontmatter "$s4" depends_on '["001"]'
s5=$(jsdd new spike "Which store"); frontmatter "$s5" phase 1
s6=$(jsdd new feature "Export"); frontmatter "$s6" phase 1
printf '\n- **R9** The format is [NEEDS CLARIFICATION: CSV or JSON?]\n' >>"$s6"
s7=$(jsdd new feature "Share"); frontmatter "$s7" phase 1
printf '\n- [ ] **AC-9** A person shares a note · check: manual: open the link on a phone\n' >>"$s7"
git add -A && git commit -qm "[meta] Specs"

step "the charter fails closed: scope keys only in autonomous, values checked"
cat >specs/jsdd.yml <<'YML'
version: 1
modes: [manual, autonomous, autopilot]
autopilot:
  preset: standard
autonomous:
  preset: reckless
  product: everything
  phases: [one]
  types: [feature, chore]
  exclude_groups: billing
  specs_per_run: 50
YML
out=$(jsdd mode --check 2>&1) && fail "--check passed a bad charter"
for want in "preset belongs in the autonomous section only" "'reckless' is not one of cautious, standard, hands-off" "'everything' is not one of park, cited, inferred, uncited, all" \
  "'one' is not a phase number" "'chore' is not one of feature, baseline, spike" "exclude_groups must be a list" \
  "specs_per_run: '50' is not a whole number from 1 to 20"; do
  has "$out" "$want" || fail "--check did not report: $want. Got:
$out"
done
expect "mode: manual (fallback)" auto mode

step "a valid charter: autonomous is available, cautious by default"
cat >specs/jsdd.yml <<'YML'
version: 1
modes: [manual, autonomous]
autonomous:
  phases: [1]
  types: [feature, spike]
  exclude_groups: [FR-BILL]
  specs_per_run: 2
YML
jsdd mode --check >/dev/null || fail "--check refused a valid charter"
expect "mode: autonomous (SDD_MODE)" auto mode
expect "preset: cautious (none set: the strictest)" auto mode --explain
expect "MODE: autonomous, preset cautious, product cited" auto status
[ "$(jsdd charter get product)" = cited ] || fail "cautious is not product: cited"
for g in spec.change task.manual_check spike.question merge depends.override; do [ "$(auto gate $g)" = park ] || fail "$g does not park in cautious"; done
for g in spec.clarify spec.approve plan.approve verify.gaps baseline.rows pr.open; do [ "$(auto gate $g)" = auto ] || fail "$g does not pass on its own"; done
out=$(jsdd charter)
for want in "preset           cautious" "product          cited" "specs_per_run    2" "merge            park"; do
  has "$out" "$want" || fail "jsdd charter lacks: $want. Got:
$out"
done
refuses jsdd charter get no.such.key
[ "$(auto budget specs_per_run)" = 2 ] || fail "the charter's specs_per_run was not used"

step "presets change gates; a gate the project sets wins over the preset"
printf '  preset: hands-off\n' >>specs/jsdd.yml
jsdd mode --check >/dev/null || fail "--check refused the preset: $(jsdd mode --check 2>&1)"
[ "$(jsdd charter get product)" = all ] || fail "hands-off is not product: all"
[ "$(auto gate merge)" = auto ] || fail "hands-off does not merge"
[ "$(auto gate spec.change)" = auto ] || fail "hands-off does not hand spec changes to sdd-product"
printf '  product: inferred\n' >>specs/jsdd.yml
[ "$(jsdd charter get product)" = inferred ] || fail "the charter's product did not win over the preset"
edit specs/jsdd.yml '/product: inferred/d'
expect "[preset hands-off]" auto mode --explain
printf '  merge: park\n' >>specs/jsdd.yml
[ "$(auto gate merge)" = park ] || fail "the project's merge: park did not win over the preset"
expect "[set in specs/jsdd.yml]" auto mode --explain
edit specs/jsdd.yml 's/preset: hands-off/preset: cautious/'
edit specs/jsdd.yml '/merge: park/d'

step "the queue follows the scope and skips what only a person can move"
q=$(auto auto queue | cut -f1 | paste -sd ' ' -)
[ "$q" = "001 005 006 007" ] || fail "the queue is '$q', not '001 005 006 007'"
out=$(auto auto dry-run)
for want in "002  refs FR-BILL-01, in autonomous.exclude_groups" "003  phase 2 is not in autonomous.phases" "004  waiting on 001" \
  "sdd-product answers 1 open questions as far as product: cited allows" "would park at task.manual_check: AC-9" "parks at spike.question" \
  "each spec ends at a pull request" "(after specs_per_run: next loop)"; do
  has "$out" "$want" || fail "the dry run lacks: $want. Got:
$out"
done
jsdd park 006 spec.clarify "CSV or JSON" >/dev/null
q=$(auto auto queue | cut -f1 | paste -sd ' ' -)
[ "$q" = "001 005 007" ] || fail "a parked spec stayed in the queue: $q"
expect "006  parked at spec.clarify" auto auto dry-run
jsdd unpark 006 >/dev/null
as session-b jsdd claim 005 >/dev/null
expect "005  claimed" auto auto dry-run
as session-b jsdd release 005 >/dev/null

step "a loop needs autonomous mode, takes specs one at a time, and stops at specs_per_run"
refuses jsdd run start --loop
refuses auto run next
expect "loop started: preset cautious, up to 2 specs" auto run start --loop
expect "already started by you" auto run start --loop
refuses as session-b env SDD_MODE=autonomous "$KIT/bin/jsdd" run start --loop
[ "$(auto run next 2>/dev/null)" = 001 ] || fail "the loop did not take 001 first"
printf '%s\n' "$(auto run active)" | grep -qx loop || fail "run active does not list the loop"
printf '%s\n' "$(auto run active)" | grep -qx 001 || fail "run active does not list the spec run"
expect "the run on 001 is still open" auto run next
input='{"session_id":"session-a","cwd":"'"$PWD"'","stop_hook_active":false}'
again='{"session_id":"session-a","cwd":"'"$PWD"'","stop_hook_active":true}'
expect "The run on 001 is not finished" hook stop-autopilot.sh "$input"
edit_input() { printf '{"session_id":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$PWD" "$PWD/$2"; }
refuses hook protect-run-files.sh "$(edit_input session-a specs/jsdd.yml)"
auto run end 001 >/dev/null
expect "Take the next spec with: jsdd run next" hook stop-autopilot.sh "$input"
expect "made no progress" hook stop-autopilot.sh "$again"
refuses hook protect-run-files.sh "$(edit_input session-a docs/intent.md)"
[ "$(auto run next 2>/dev/null)" = 005 ] || fail "the loop did not take 005 second"
auto run end 005 >/dev/null
expect "took 2 of 2 specs (001 005)" auto run status --loop
expect "it took 2 of 2 specs (specs_per_run)" auto run next
expect "Write the loop report" hook stop-autopilot.sh "$input"
expect "loop ended after 2 specs: 001 005" auto run end --loop
[ -z "$(hook stop-autopilot.sh "$input")" ] || fail "the Stop hook still blocks after the loop ended"
hook protect-run-files.sh "$(edit_input session-a specs/jsdd.yml)" || fail "an edit was blocked with no run"

step "a loop skips specs taken earlier in it, and another session's run"
edit specs/jsdd.yml 's/specs_per_run: 2/specs_per_run: 5/'
auto run start --loop >/dev/null
as session-b env SDD_MODE=autonomous "$KIT/bin/jsdd" run start 001 >/dev/null
[ "$(auto run next 2>/dev/null)" = 005 ] || fail "the loop took a spec another session runs"
auto run end 005 >/dev/null
[ "$(auto run next 2>/dev/null)" = 006 ] || fail "the loop took 005 twice"
auto run end 006 >/dev/null; auto run next >/dev/null 2>&1; auto run end 007 >/dev/null
expect "the queue is empty" auto run next
auto run end --loop >/dev/null
as session-b env SDD_MODE=autonomous "$KIT/bin/jsdd" run end 001 >/dev/null

step "doctor: what a run needs, with a fix for each"
expect "FIX   mode is manual" jsdd auto doctor
refuses jsdd auto doctor
git add -A && git commit -qm "[meta] Charter"
echo wip >wip.txt
expect "the work tree has uncommitted changes" auto auto doctor
rm wip.txt
expect "the work tree is clean" auto auto doctor
expect "permission mode:" auto auto doctor

step "assumed decisions: the board counts them until the owner confirms or rejects them"
printf '\n## Assumed\n\n| ID | Decision | Choice | Class | Basis | Reversal | Spec | Date |\n|---|---|---|---|---|---|---|---|\n| AS-01 | Export format | CSV | inferred | intent.md § Principles | cheap | 006 | 2026-11-09 |\n' >>docs/decisions.md
expect "Assumed decisions: 1 made by autonomous runs" jsdd status
