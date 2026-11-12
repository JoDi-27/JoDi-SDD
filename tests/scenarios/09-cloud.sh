#!/usr/bin/env bash
# Cloud-native runs: a profile fills in settings nobody set, commands meant for
# scripts print one JSON document with stable exit codes, a run leaves a
# run-result.json written from disk, and jsdd auto run starts claude -p with
# nobody watching and has the last word on what happened. A stub claude acts
# out the runs (done, parked, crashed), so no tokens are spent.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-NOTE-01|A user can add a note|M"
for t in Notes Export Import; do jsdd new feature "$t" >/dev/null; done
jsdd new spike "Which store" >/dev/null
jsdd new feature "Formats" >/dev/null
printf '\n[NEEDS CLARIFICATION: CSV or JSON?]\n' >>specs/005-formats/spec.md
printf 'version: 1\nmodes: [manual, autopilot]\nclaims: remote\ntest_command: "test ! -f broken.txt"\n' >specs/jsdd.yml
git add -A && git commit -qm "[meta] Specs"
git clone -q --bare . "$TMP/origin.git"
git remote add origin "$TMP/origin.git"
git fetch -q origin
git branch -q -u origin/main
# ok <json> <jq filter> <what>: the filter must hold.
ok() { printf '%s' "$1" | jq -e "$2" >/dev/null 2>&1 || fail "$3. Got:
$1"; }
# rc <want> <command...>: the command's exit code.
rc() { local want=$1 got=0; shift; "$@" >/dev/null 2>&1 || got=$?; [ "$got" = "$want" ] || fail "'$*' exited $got, not $want"; }
cloud() { SDD_PROFILE=cloud "$KIT/bin/jsdd" "$@"; }
# jq.exe prints CRLF on Windows; values read with jq -r must compare equal.
case $OSTYPE in msys*|cygwin*) jq() { command jq "$@" | tr -d '\r'; } ;; esac

step "profiles: cloud fills in what nobody set; an explicit setting wins; an unknown one fails"
out=$(cloud profile)
has "$out" "autopilot" && has "$out" "profile cloud" || fail "cloud did not pick autopilot: $out"
expect "mode: autopilot (profile cloud)" env SDD_PROFILE=cloud JSDD_OUTPUT=text "$KIT/bin/jsdd" mode
expect "mode: manual (SDD_MODE)" env SDD_PROFILE=cloud SDD_MODE=manual JSDD_OUTPUT=text "$KIT/bin/jsdd" mode
rc 2 env SDD_PROFILE=bogus "$KIT/bin/jsdd" next
out=$(cloud profile)
ok "$out" '.schema == "jsdd.profile/1" and .data.settings.claims.value == "remote" and .data.settings.output.source == "profile cloud"' "profile JSON is wrong"
[ "$(jsdd profile | grep claims)" != "" ] || fail "profile lists no claims setting"
expect "specs/jsdd.yml" jsdd profile

step "claims: remote in specs/jsdd.yml; a bad value fails the check"
printf 'version: 1\nmodes: [manual, autopilot]\nclaims: shared\n' >specs/jsdd.yml
expect "claims: 'shared' is not one of local, remote" jsdd mode --check
rc 2 jsdd mode --check
git checkout -q specs/jsdd.yml

step "JSON: one envelope per command, also on failure; text commands refuse --json"
for c in next status "mode --explain" charter profile "auto queue" "auto dry-run"; do
  # shellcheck disable=SC2086  # the command and its subcommand
  out=$(jsdd $c --json 2>/dev/null) || true
  ok "$out" '.schema and .jsdd and (.ok | type == "boolean") and has("data") and (.errors | type == "array")' "'$c --json' printed no envelope"
done
out=$(jsdd next --json)
ok "$out" '.data.ready | map(.id) | index("001")' "next --json lacks 001"
out=$(jsdd status --json)
ok "$out" '.data.specs | length == 5' "status --json does not list 5 specs"
out=$(jsdd run status 001 --json) && fail "run status on no run succeeded"
ok "$out" '.ok == false and .exit == 1 and (.errors[0].message | test("no run on 001"))' "the failure envelope is wrong"
rc 2 jsdd gate pr.open --json
[ "$(JSDD_OUTPUT=json SDD_MODE=autopilot jsdd gate pr.open)" = auto ] || fail "JSDD_OUTPUT=json changed gate's text output"
has "$(JSDD_OUTPUT=json jsdd pr 001)" '"schema"' && fail "JSDD_OUTPUT=json changed the pull request body"

step "exit codes: usage 2, nothing to do 3, parked 4"
rc 2 jsdd claim
rc 2 jsdd run frobnicate
SDD_MODE=autopilot jsdd park 002 spec.clarify "which fields" >/dev/null
rc 4 env SDD_MODE=autopilot "$KIT/bin/jsdd" run start 002
jsdd unpark 002 >/dev/null

step "the autopilot queue: features a person wrote, with no open questions"
out=$(SDD_MODE=autopilot SDD_CLAIMS=local jsdd auto queue --json)
ok "$out" '[.data.take[].id] == ["001", "002", "003"]' "the autopilot queue is wrong"
ok "$out" '.data.skip | map({ (.id): .reason }) | add | .["004"] == "type_out_of_scope" and .["005"] == "open_questions"' "skip reasons are wrong"
git checkout -q -- specs

step "doctor --unattended: what a run with nobody at the machine needs, as FIX"
out=$(cloud auto doctor) && fail "doctor passed with no credentials"
ok "$out" '.exit == 2 and (.data.checks | map(select(.status == "fix") | .id) | index("claude_auth") and index("session_id"))' "doctor did not FIX credentials and session"

step "the AskUserQuestion hook: blocks during a run, never outside one"
hook() { printf '%s' "$2" | bash "$KIT/hooks/$1"; }
ask='{"session_id":"session-a","cwd":"'"$PWD"'","tool_name":"AskUserQuestion"}'
hook pre-ask-park.sh "$ask" || fail "the hook blocked a question outside a run"
SDD_MODE=autopilot SDD_CLAIMS=local jsdd run start 001 >/dev/null
out=$(hook pre-ask-park.sh "$ask" 2>&1) && fail "the hook let a question through during a run"
has "$out" "jsdd park" || fail "the hook did not say to park: $out"
SDD_MODE=autopilot SDD_CLAIMS=local jsdd run end 001 >/dev/null
rm -f specs/001-notes/run-result.json

step "run result: written from disk, kept when the run ends, one entry per run"
git switch -q -c autopilot/002-export
SDD_MODE=autopilot SDD_CLAIMS=local JSDD_EVENTS="$TMP/ev.ndjson" jsdd run start 002 >/dev/null
echo code >export.txt && git add export.txt && git commit -qm "[002] T1 Export"
SDD_MODE=autopilot SDD_CLAIMS=local JSDD_EVENTS="$TMP/ev.ndjson" jsdd park 002 spec.change "keep CSV" >/dev/null
expect "002: parked" env SDD_MODE=autopilot SDD_CLAIMS=local JSDD_EVENTS="$TMP/ev.ndjson" "$KIT/bin/jsdd" run result 002 --write
expect "run 002 ended: parked" env SDD_MODE=autopilot SDD_CLAIMS=local JSDD_EVENTS="$TMP/ev.ndjson" "$KIT/bin/jsdd" run end 002
out=$(jsdd run result 002 --json)
ok "$out" '.data.outcome == "parked" and .data.gate == "spec.change" and .data.reason == "keep CSV" and .data.n == 1 and .data.commits == 1 and .data.branch == "autopilot/002-export"' "the run result is wrong"
for e in run.start park run.result run.end; do grep -q "\"event\":\"$e\"" "$TMP/ev.ndjson" || fail "no $e event"; done
git add -A && git commit -qm "[002] Park" && git switch -q main && git branch -q -D autopilot/002-export

# The stub claude: acts out /jsdd:auto <ID> the way the skill would, as $STUB says.
cat >"$TMP/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$@" >"$STUB_ARGS"
id=${2#/jsdd:auto }
[ "$3" = --session-id ] && [ "$4" = "$JSDD_SESSION_ID" ] || { echo "no --session-id $JSDD_SESSION_ID" >&2; exit 9; }
[ "$JSDD_OUTPUT" = text ] || { echo "the session got JSDD_OUTPUT=$JSDD_OUTPUT" >&2; exit 9; }
echo '{"type":"system","subtype":"init"}'
jsdd() { "$KIT/bin/jsdd" "$@"; }
jsdd run start "$id" >/dev/null
slug=$(basename "$(ls -d specs/"$id"-*)")
git switch -q -c "autopilot/$slug"
echo "$id" >"work-$id.txt" && git add "work-$id.txt" && git commit -qm "[$id] T1 Work"
case $STUB in
  done|red)
        [ "$STUB" = done ] || { echo x >broken.txt && git add broken.txt && git commit -qm "[$id] T2 Break a test"; }
        jsdd suite "$id" >/dev/null 2>&1 || true
        sed -i.bak 's/^status:.*/status: done/' "specs/$slug/spec.md" && rm "specs/$slug/spec.md.bak"
        git add -A && git commit -qm "[$id] Verify" ;;
  park) jsdd park "$id" spec.clarify "a person picks the format" >/dev/null && git commit -qam "[$id] Park" ;;
  crash) exit 1 ;;
esac
jsdd run result "$id" --write >/dev/null && git add -A && git commit -qm "[$id] Run report"
jsdd run end "$id" >/dev/null
echo '{"type":"result","total_cost_usd":1.25,"num_turns":12,"is_error":false,"session_id":"'"$JSDD_SESSION_ID"'"}'
STUB
# The stub gh: signed in; with $GH_PR set, the branch has that ready pull request, and --undo is logged.
cat >"$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "pr list") [ -z "${GH_PR:-}" ] || echo "$GH_PR" ;;
  "pr view") echo false ;;
  "pr ready") printf '%s\n' "$*" >>"$GH_LOG" ;;
esac
exit 0
STUB
chmod +x "$TMP/bin/claude" "$TMP/bin/gh"
PATH=$TMP/bin:$PATH   # lib.sh adds it only outside Windows; the stubs need it everywhere
export KIT STUB_ARGS="$TMP/claude.args" CLAUDE_CODE_OAUTH_TOKEN=test-token GH_LOG="$TMP/gh.log"
run() { SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run "$@" -- --permission-mode bypassPermissions; }

step "auto run: a spec to done, its result committed and pushed, exit 0"
out=$(STUB=done run 001) || fail "the run did not exit 0: $out"
ok "$out" '.schema == "jsdd.auto-run/1" and .data.outcome == "done" and .data.pushed == true and .data.result.claude.cost_usd == 1.25' "the done run's output is wrong"
grep -qx -- --permission-mode "$STUB_ARGS" || fail "the claude flags after -- did not reach claude"
git ls-remote --exit-code -q origin refs/heads/autopilot/001-notes >/dev/null || fail "the run branch was not pushed"
[ -z "$(SDD_CLAIMS=local jsdd run active)" ] || fail "the run is still open"
ev=$(printf '%s' "$out" | jq -r .data.logs.events)
for e in session.start run.start run.result run.end session.end; do grep -q "\"event\":\"$e\"" "$ev" || fail "no $e event in $ev"; done
git switch -q main

step "auto run: a parked spec exits 4"
rc 4 env STUB=park SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run 002 -- --permission-mode bypassPermissions
[ "$(git show autopilot/002-export:specs/002-export/run-result.json | jq -r '.runs[-1].outcome')" = parked ] || fail "the parked result is not committed"
git switch -q main

step "auto run: a crashed session still gets a result, committed and pushed, exit 1"
rc 1 env STUB=crash SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run 003 -- --permission-mode bypassPermissions
git fetch -q origin
r=$(git show origin/autopilot/003-import:specs/003-import/run-result.json) || fail "no result on the pushed branch"
ok "$r" '.runs[-1].outcome == "failed" and .runs[-1].commits >= 1' "the crashed run's result is wrong"
[ -z "$(SDD_CLAIMS=local jsdd run active)" ] || fail "the crashed run is still open"
git switch -q main

step "auto run: done but the full suite fails: exit 1, and a ready pull request goes back to draft"
tid=$(basename "$(dirname "$(jsdd new feature "Tags")")" | cut -c1-3)
git add -A && git commit -qm "[$tid] Spec" && git push -q origin main
out=$(STUB=red GH_PR=https://example.com/pr/7 run "$tid") && fail "a run whose full suite failed exited 0: $out"
ok "$out" '.data.outcome == "failed" and (.data.result.reason | test("full test suite"))' "the red run's output is wrong"
grep -q "pr ready https://example.com/pr/7 --undo" "$GH_LOG" || fail "the ready pull request was not turned back into a draft"
grep -q '"event":"pr.draft"' "$(printf '%s' "$out" | jq -r .data.logs.events)" || fail "no pr.draft event"
git switch -q main

step "auto run: nothing to do exits 3; a setup problem exits 2 before any session"
rc 3 env SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run -- --permission-mode bypassPermissions
rm -f "$STUB_ARGS"
rc 2 env -u CLAUDE_CODE_OAUTH_TOKEN SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run 001 -- --permission-mode bypassPermissions
[ ! -f "$STUB_ARGS" ] || fail "claude started although doctor failed"

step "auto run --worktree: the checkout in use is not touched"
jsdd new feature "Search" >/dev/null && git add -A && git commit -qm "[007] Spec" && git push -q origin main
echo mine >scratch.txt
out=$(STUB=done SDD_PROFILE=cloud "$KIT/bin/jsdd" auto run 007 --worktree -- --permission-mode bypassPermissions) || fail "the worktree run failed: $out"
ok "$out" '.data.outcome == "done"' "the worktree run did not finish"
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] && [ -f scratch.txt ] || fail "the worktree run changed this checkout"
git ls-remote --exit-code -q origin refs/heads/autopilot/007-search >/dev/null || fail "the worktree run did not push"
[ "$(git worktree list | wc -l | tr -d ' ')" = 1 ] || fail "the worktree was left behind: $(git worktree list)"
rm scratch.txt
