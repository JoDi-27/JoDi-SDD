#!/usr/bin/env bash
# The full suite: a task's check is narrow, so a change can pass it and still
# break a test no task named (an API description test that lists every query
# parameter, say). jsdd suite runs the project's whole test command and records
# the result; a done feature without a fresh pass is a failed run, its pull
# request stays a draft, and the headless runner turns a ready one back into a draft.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-DEAL-01|Deals can be filtered by contact|M"
spec=$(jsdd new feature "Deal list contact filter")
dir=$(dirname "$spec")
frontmatter "$spec" refs '["FR-DEAL-01"]'
# The product: the deal list's query parameters. Two test files: the one the
# task names, and an existing one that pins the whole parameter list.
mkdir -p src tests
echo companyId >src/params.txt
printf '#!/usr/bin/env bash\ngrep -qx "${1:-companyId}" src/params.txt\n' >tests/deal-list.sh
printf '#!/usr/bin/env bash\n[ "$(cat src/params.txt)" = companyId ] || { echo "ApiDescriptionTest: unexpected parameters: $(paste -sd, src/params.txt)"; exit 1; }\n' >tests/api-description.sh
printf '#!/usr/bin/env bash\nfor t in tests/*.sh; do bash "$t" || exit 1; done\n' >run-tests.sh
git add -A && git commit -qm "[001] Spec"

step "the test command: from the constitution, unless specs/jsdd.yml sets test_command"
expect "make test	(from specs/constitution.md (Project specifics))" jsdd suite --command
edit specs/constitution.md 's/^- \*\*Test command:\*\* `make test`/Test command: `bash run-tests.sh` (one file: `bash tests\/<name>.sh`)/'
expect "bash run-tests.sh	(from specs/constitution.md" jsdd suite --command
printf 'version: 1\nmodes: [manual, autopilot]\ntest_command: "bash run-tests.sh"\n' >specs/jsdd.yml
jsdd mode --check >/dev/null || fail "--check refused test_command"
expect "bash run-tests.sh	(from specs/jsdd.yml test_command)" jsdd suite --command
edit specs/constitution.md 's/^Test command: .*/Tests: see CI/'
expect "bash run-tests.sh" jsdd suite --command
printf 'version: 1\nmodes: [manual, autopilot]\n' >specs/jsdd.yml
refuses jsdd suite --command
expect "no test command" jsdd suite 001
expect "FIX   no test command" env SDD_MODE=autopilot "$KIT/bin/jsdd" auto doctor
printf 'version: 1\nmodes: [manual, autopilot]\ntest_command: "bash run-tests.sh"\n' >specs/jsdd.yml
expect "test command: \`bash run-tests.sh\`" env SDD_MODE=autopilot "$KIT/bin/jsdd" auto doctor
git add -A && git commit -qm "[meta] Test command"

step "the narrow task check passes; the full suite fails on a test no task named"
frontmatter "$spec" status in-progress
cat >"$dir/tasks.md" <<'TASKS'
# 001 · Tasks: Deal list contact filter

## Tasks

- [ ] **T1** Add the contactId filter → AC-1
  - files: `src/params.txt`
  - check: `bash tests/deal-list.sh contactId`

## Evidence

| Acceptance criterion | Result | Evidence (test, command output, manual check) |
| --- | --- | --- |
| AC-1 | pass | bash tests/deal-list.sh contactId |
TASKS
printf '# Plan\n\n## Deviations\n\n## Amendments\n' >"$dir/plan.md"
jsdd freeze 001 >/dev/null
echo contactId >>src/params.txt
jsdd claim 001 next >/dev/null
expect "ticked 001 T1" jsdd done 001 T1
git add -A && git commit -qm "[001] T1 Add the contactId filter"
expect "the full suite has not run" jsdd suite 001 --check
out=$(jsdd suite 001 2>&1) && fail "jsdd suite passed with a broken test: $out"
has "$out" "ApiDescriptionTest: unexpected parameters: companyId,contactId" || fail "the suite's output was not shown: $out"
has "$out" "full suite failed (exit 1" || fail "no failure line: $out"
expect "result=fail" cat "$dir/suite-result.txt"
expect "the full suite failed (exit 1)" jsdd suite 001 --check

step "a done feature without a passing suite: the run failed, the pull request stays a draft"
frontmatter "$spec" status done
git add -A && git commit -qm "[001] Close"
expect "the full suite failed" jsdd pr 001 --ready
refuses jsdd pr 001 --ready
expect "Full test suite not passed" jsdd pr 001
SDD_MODE=autopilot CLAUDE_CODE_SESSION_ID=run-1 "$KIT/bin/jsdd" run result 001 --write >/dev/null
[ "$(jq -r '.runs[-1].outcome' "$dir/run-result.json")" = failed ] || fail "a done spec with a failing suite was not a failed run: $(cat "$dir/run-result.json")"
has "$(jq -r '.runs[-1].reason' "$dir/run-result.json")" "full test suite: the full suite failed" || fail "the result does not say why: $(cat "$dir/run-result.json")"

step "fix the broken test: the old pass is stale, a new run passes, and only code changes make it stale"
printf '#!/usr/bin/env bash\n[ "$(paste -sd, src/params.txt)" = companyId,contactId ] || exit 1\n' >tests/api-description.sh
expect "the full suite failed" jsdd suite 001 --check
expect "full suite passed" jsdd suite 001
expect "note: it ran on uncommitted changes" jsdd suite 001
expect "passed on uncommitted changes" jsdd suite 001 --check
git add -A && git commit -qm "[001] T2 Update the API description test"
expect "full suite passed" jsdd suite 001
jsdd suite 001 --check >/dev/null || fail "a fresh pass was not accepted: $(jsdd suite 001 --check)"
git add -A && git commit -qm "[001] Full suite"
echo "- note" >>BACKLOG.md; echo "verify notes" >>"$dir/tasks.md"
jsdd suite 001 --check >/dev/null || fail "a kit document change made the pass stale"
git add -A && git commit -qm "[001] Close"
expect "Full test suite: the full suite passed" jsdd pr 001
expect "001 is ready for review" jsdd pr 001 --ready
SDD_MODE=autopilot CLAUDE_CODE_SESSION_ID=run-2 "$KIT/bin/jsdd" run result 001 --write >/dev/null
[ "$(jq -r '.runs[-1].outcome' "$dir/run-result.json")" = done ] || fail "a done spec with a passing suite was not done: $(cat "$dir/run-result.json")"
echo companyId >>src/params.txt
expect "the code changed since the suite passed" jsdd suite 001 --check
git checkout -q -- src/params.txt
expect "the full suite passed" jsdd suite 001 --check
printf 'version: 1\nmodes: [manual, autopilot]\ntest_command: "bash run-tests.sh && true"\n' >specs/jsdd.yml
expect "the test command changed" jsdd suite 001 --check
git checkout -q -- specs/jsdd.yml

step "a run cannot edit the recorded result"
SDD_MODE=autopilot "$KIT/bin/jsdd" run start 001 >/dev/null
in='{"session_id":"session-a","cwd":"'"$PWD"'","tool_input":{"file_path":"'"$PWD/$dir/suite-result.txt"'"}}'
if printf '%s' "$in" | SDD_MODE=autopilot bash "$KIT/hooks/protect-run-files.sh" 2>/dev/null; then fail "a run could edit suite-result.txt"; fi
SDD_MODE=autopilot "$KIT/bin/jsdd" run end 001 >/dev/null
