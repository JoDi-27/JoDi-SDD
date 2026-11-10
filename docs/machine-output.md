# Running jsdd from scripts and the cloud

This page is for scripts that drive the kit with nobody watching: a cron line, a CI job, or a container such as [sdd-runtime](https://github.com/JoDi-27/sdd-runtime). It covers:

- the `cloud` profile
- JSON output and exit codes
- the run result
- events
- `jsdd auto run`, the headless runner

People never need any of it. Autopilot and autonomous mode work the same with or without it ([Autonomous mode](autonomous-mode.md)).

## In one line

```bash
SDD_PROFILE=cloud jsdd auto run --json -- --permission-mode bypassPermissions
```

In a fresh clone with Claude Code installed, this:

1. checks what an unattended run needs
2. picks the next spec autopilot accepts
3. runs `/jsdd:auto <ID>` with `claude -p`
4. records how the run ended, commits that record, and pushes the branch, however the session ended
5. exits with a code that says what happened

## Profiles

A profile is a named, built-in set of settings, picked with `SDD_PROFILE`. It fills in only the settings nobody set. The order is:

1. an env var
2. the profile
3. `specs/jsdd.yml`
4. the built-in default

A profile never widens what the project allows. The mode it picks must still be listed under `modes:` in `specs/jsdd.yml`. A profile is never set in `specs/jsdd.yml`, so a clone that pulls the repository behaves as before.

| Setting | `local` (default) | `cloud` |
| --- | --- | --- |
| Mode | `SDD_MODE`, else the `specs/jsdd.yml` default, else manual | autopilot (`SDD_MODE=autopilot`) |
| Output | text | JSON from the commands below (`JSDD_OUTPUT=json`) |
| Claims | `SDD_CLAIMS`, else `git config jsdd.claims`, else `claims:` in `specs/jsdd.yml`, else local | remote (`SDD_CLAIMS=remote`) |
| `auto doctor` | the checks for a session someone watches | adds the unattended checks, as FIX (`JSDD_UNATTENDED=1`) |

`SDD_PROFILE=cloud SDD_MODE=autonomous` is a hands-off loop in the cloud. `jsdd profile` prints each setting with where it came from, and `jsdd profile --explain` lists the profiles. An unknown profile exits 2.

The claim owner is `$JSDD_SESSION_ID` when set, else `$CLAUDE_CODE_SESSION_ID`, else `user@host`. `jsdd auto run` sets it and passes the same UUID to `claude --session-id`, so the runner and the session own the same claims and runs. Don't export one `JSDD_SESSION_ID` into several interactive sessions: they would become one owner.

## JSON output

These commands print JSON with `--json`, or when `JSDD_OUTPUT=json`:

- `next`, `status`, `mode`, `charter`, `profile`
- `auto queue`, `auto dry-run`, `auto doctor`, `auto run`
- `run status`, `run result`

Other commands refuse `--json` (exit 2). `JSDD_OUTPUT` never changes the commands that skills, hooks, or GitHub read as text: `pr`, `gate`, `budget`, `charter get`, `run next`, `run stop-check`, and `claims --mine`. `jsdd auto run` also gives the session it starts `JSDD_OUTPUT=text`.

Every JSON command prints exactly one document on stdout, also when it fails. stderr becomes `warnings` on success, or the error message on failure.

```json
{ "schema": "jsdd.queue/1", "jsdd": "0.8.0", "ok": true, "exit": 0,
  "data": { … }, "warnings": [], "errors": [] }
```

On failure, `ok` is false, `exit` is the exit code, `errors` is `[{ "code": "<exit code name>", "message": "…" }]`, and `data` is null, or whatever the command had to report (`auto doctor` still lists its checks).

**Versions.** Each schema is `jsdd.<command>/<n>`. Within one `n`, fields are only added. A rename or a removal is a new `n`. Ignore fields you don't know. The kit needs jq (README, Requirements), and `--json` without jq exits 2.

### Schemas

| Schema | `data` |
| --- | --- |
| `jsdd.next/1` | `ready[]` (`id`, `type`, `status`, `title`, `next`: the command to run), `parked[]` (`gate`, `reason`), `waiting[]` (`waiting_on[]`), `blocked[]` (`reason`) |
| `jsdd.status/1` | `mode`, `mode_source`, `mode_warning`, `profile`, `specs[]` (`id`, `type`, `status`, `phase`, `depends_on[]`, `done`, `total`, `open_questions`, `title`, `dir`, `claim`, `task_note`, `parked`), `next` (as `jsdd.next/1`), `assumed_decisions`, `counts` (by status) |
| `jsdd.mode/1` | `mode`, `source`, `warning`, `profile`, `config` (`exists`, `valid`, `errors[]`), `allowed_modes[]`; with `--explain`: `gates[]` (`gate`, `policy`, `source`, `decides`), `budgets[]` |
| `jsdd.charter/1` | `charter` (has an autonomous section), `autonomous_allowed`, `preset`, `product`, `types[]`, `phases[]` (null: every phase), `exclude_groups[]`, `budgets`, `gates` |
| `jsdd.profile/1` | `profile`, `source`, `settings` (`mode`, `claims`, `output`, `owner`, `events`, `doctor`: each `{ value, source }`), `profiles[]` |
| `jsdd.queue/1` | `mode`, `profile`, `take[]` (`id`, `type`, `status`, `next`), `skip[]` (`id`, `type`, `status`, `reason`, `detail`) |
| `jsdd.dry-run/1` | the queue, plus `preset`, `product`, `specs_per_run`, `wall_time_hours`, `merge` (`auto` or `pull_request`); each `take[]` adds `would_park[]` and `next_loop` (past `specs_per_run`) |
| `jsdd.doctor/1` | `mode`, `profile`, `unattended`, `ready`, `fix`, `warn`, `checks[]` (`id`, `status`: `ok`, `warn`, or `fix`, `message`, `fix`) |
| `jsdd.run-status/1` | `spec`, `owner`, `mine`, `branch`, `status`, `started`, `parked`, `hours_left`, `wall_time_hours`, `attempts_per_task`, `budget_spent`; for `--loop`: `taken[]`, `specs_per_run`, `hours_left`, `takes_more`, `stops_because`, `next` |
| `jsdd.run-result/1` | the latest run (see below), plus `spec` and `pr` (looked up with `gh` when it works) |
| `jsdd.auto-run/1` | `spec`, `outcome`, `exit`, `branch`, `pushed`, `pr`, `result` (the run), `logs` (`session`, `events`); for `--loop`: `loop` (the loop's result) and `claude` |

**Skip reasons** (`jsdd.queue/1` and `jsdd.dry-run/1`):

| Reason | Meaning |
| --- | --- |
| `blocked` | blocked, so a person resumes it |
| `parked` | parked at a gate |
| `spec_change_waiting` | a spec change from verify waits for a person |
| `type_out_of_scope` | its type isn't in the charter's `types`; in autopilot, anything but a feature |
| `phase_out_of_scope` | its phase isn't in the charter's `phases` |
| `waiting` | a `depends_on` spec isn't done |
| `claimed` | another session claimed it |
| `running` | another session runs it |
| `open_questions` | `[NEEDS CLARIFICATION` markers: in a baseline, or in any spec in autopilot |
| `run_branch_open` | its `autopilot/<ID>-*` or `autonomous/<ID>-*` branch isn't merged here yet |
| `excluded_group` | it refs a group in `exclude_groups` |

**The queue follows the mode.** In autonomous mode it is the charter's scope. In autopilot mode it is what `/jsdd:auto <ID>` accepts:

- feature specs from `draft` to `in-progress`
- no open questions
- not parked or blocked
- every `depends_on` spec done
- no open run branch, and not claimed

`jsdd auto queue` exits 3 when it has nothing to take.

## Exit codes

The same with text or JSON output, for every command:

| Code | Name | Meaning |
| --- | --- | --- |
| 0 | `ok` | done |
| 1 | `failed` | a check, a push, or a run that ended without a result |
| 2 | `usage` | bad arguments, an invalid `specs/jsdd.yml`, an unknown profile, or a doctor FIX |
| 3 | `nothing_to_do` | the queue is empty, or the loop takes no more specs |
| 4 | `parked` | parked, or a run on a parked spec |
| 5 | `budget_spent` | the wall-time budget is spent |
| 6 | `claim_lost` | another session holds the claim |
| 7 | `remote_unreachable` | the claims remote, or the push or fetch, failed |

## The run result

`run-result.json` sits beside `run-report.md` in the spec folder and is committed on the run branch. It is the record a script reads; the run report stays the record a person reads. jsdd writes it from what is on disk, never the model:

- `/jsdd:auto` runs `jsdd run result <ID> --write` before its last commit
- `jsdd run end <ID>` writes it if it is still missing (`--outcome <outcome>` says how the run ended)
- `jsdd auto run` writes it after a crash, and adds the session's cost

```json
{ "schema": "jsdd.run-result/1", "spec": "004", "runs": [
  { "n": 1, "mode": "autopilot", "profile": "cloud", "session": "6f1c…",
    "outcome": "parked", "gate": "spec.clarify", "reason": "Which currency…",
    "branch": "autopilot/004-export", "base": "origin/main", "status": "planned",
    "tasks": { "ticked": 3, "total": 6 }, "commits": 5, "assumed": ["AS-03"],
    "started": "2026-11-12T02:00:00Z", "ended": "2026-11-12T03:41:00Z",
    "claude": { "cost_usd": 3.41, "turns": 212, "is_error": false, "session_id": "6f1c…" } } ] }
```

- **`outcome`** is one of `done`, `merged`, `parked`, `budget`, `failed`, or `noop` (nothing committed beyond the spec).
- **How `outcome` is decided.** Without `--outcome`: the spec is `done` → `done`; it has `parked:` → `parked`; the run's wall time is spent → `budget`; no commits beyond the spec → `noop`; otherwise `failed`.
- **What the other fields hold.** `commits` counts the branch's commits since the main branch. `assumed` lists the Assumed rows in `docs/decisions.md` whose Spec column names the spec.
- **One entry per session.** Writing again from the same session updates its entry and keeps its outcome. A later run on the same spec adds `"n": 2`.
- **No pull request URL in the file.** It is committed before the pull request exists. `jsdd run result <ID> --json` looks the URL up with `gh`.
- **The loop.** `jsdd run result --loop --write` (or `jsdd run end --loop`) writes `specs/runs/<date>-<n>.json` next to the loop report, with the specs the loop took and how each ended.

## Events

With `JSDD_EVENTS=<file>`, every jsdd command that changes state appends one JSON line:

```json
{"ts":"2026-11-12T02:14:07Z","session":"6f1c…","event":"task.done","spec":"004","task":"T3","check":"passed"}
```

| Event | Fields |
| --- | --- |
| `run.start`, `run.end`, `run.result` | `spec`, `mode` or `outcome` |
| `loop.start`, `loop.next`, `loop.end`, `loop.result` | `spec`, `taken`, `file` |
| `claim`, `release` | `spec`, `task` |
| `task.done`, `ac.done` | `spec`, `task` or `ac`, `check` (`passed` or `manual`) |
| `freeze` | `spec`, `tasks` |
| `park`, `unpark` | `spec`, `gate`, `reason` |
| `session.start`, `session.end`, `pr` (from `jsdd auto run`) | `spec`, `prompt`, `exit`, `cost_usd`, `url` |

Every transition in a run goes through the jsdd CLI, so the file is a full log of the run. `jsdd auto run` turns events on for its own runs and puts the file in its run folder.

## `jsdd auto run`

```
jsdd auto run [<ID> | --loop] [--worktree] [--json] [-- <claude flags>]
```

1. **Check.** Fetch `origin`'s branches and the claims, then run `jsdd auto doctor --unattended`. Any FIX exits 2 before a session starts. The unattended checks are:
   - Claude Code is installed
   - `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` is set
   - `JSDD_SESSION_ID` is set (the runner sets it)
   - jq is installed
   - a git identity is set
   - claims are remote, and a probe can push and delete a ref under `refs/sdd-claims/`
   - `origin` is set and `gh` works, unless `pr.open` parks
   - the permission mode passed after `--` won't prompt
2. **Pick.** Take the given ID, or the first spec in `jsdd auto queue`. With none, exit 3 within seconds.
3. **Run.** `claude -p "/jsdd:auto <ID>" --session-id <uuid> --output-format stream-json --verbose <your flags>`, with `SDD_MODE`, `SDD_CLAIMS`, `JSDD_SESSION_ID`, `JSDD_EVENTS`, and `JSDD_OUTPUT=text` exported. `JSDD_CLAUDE` names another command to run instead of `claude`; the scenario tests use a stub.
4. **Reconcile.** If the run is still open when the session exits, write its result (`failed` when the session failed and nothing better is on disk), and end it. Then commit the spec folder as `[<ID>] Run result` and push the branch, never with `--force` and never the main branch.
5. **Exit** with the outcome's code: `done`, `merged`, and `noop` 0; `parked` 4; `budget` 5; `failed` 1.

The session's stream and events are kept under `.git/jsdd-runs/<session>/`.

- **`--loop`** runs `/jsdd:auto` with no ID, in autonomous mode, and ends with the loop's result. It exits 1 if any spec failed.
- **`--worktree`** runs in a new worktree from the main branch, so a laptop's cron never touches a checkout in use. The worktree is removed afterwards unless it holds work that isn't pushed.
- **The runner never picks a permission mode** (the kit never changes permission settings). Pass `--permission-mode` after `--`. Use `bypassPermissions` only in a container or VM.

### Examples

A cron line on a machine where the project is checked out:

```bash
0 2 * * * cd ~/src/app && SDD_PROFILE=cloud jsdd auto run --worktree -- --permission-mode acceptEdits >>~/jsdd-cron.log 2>&1
```

A scheduled GitHub Actions job:

```yaml
- run: npm install -g @anthropic-ai/claude-code@2.1.314
- run: claude plugin install jsdd   # or let .claude/settings.json install it
- run: |
    git config user.name "jsdd bot"; git config user.email "jsdd-bot@users.noreply.github.com"
    SDD_PROFILE=cloud jsdd auto run --json -- --permission-mode bypassPermissions > run.json || code=$?
    jq . run.json; [ "${code:-0}" -eq 3 ] && exit 0; exit "${code:-0}"
  env:
    CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
    GH_TOKEN: ${{ secrets.JSDD_TOKEN }}
```

Pin the Claude Code version you tested. The runner relies on `-p`, `--session-id`, and the `stream-json` result event.
