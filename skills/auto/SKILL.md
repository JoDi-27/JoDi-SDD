---
name: auto
description: Run one authored feature spec to a pull request with nobody asked, in autopilot mode. Plans it, has the reviewer approve the plan, implements every task until its check passes, verifies and fixes the gaps a check can settle, then pushes the branch and opens a pull request. Anything only a person can decide parks the spec instead of being guessed. Use when the user runs /jsdd:auto <ID> on a spec they have written and approved, with SDD_MODE=autopilot.
argument-hint: <spec ID>
---

# Auto

Spec: $ARGUMENTS

The person did their part: they wrote the spec with `/jsdd:specify`, answered its questions, and started this run. Starting it is their approval of the spec. From here to the pull request, nobody is asked anything. Every gate is passed by a check, the fresh-context reviewer, or a rule written in the skills; a gate none of those can pass **parks** the spec, and the person picks it up from the pull request and the board. The person approves once more at the end, by reviewing and merging the pull request. You never merge.

## Rules for the whole run

- **Never ask.** No AskUserQuestion, no "should I…?" in chat, no waiting for an answer. The gate policy (`jsdd gate <gate>`) says what to do: `auto` passes the gate by its autopilot rule in the skill that reaches it, `park` parks it. A gate whose policy is `ask` cannot be reached in a run; if one is, park at it.
- **Park, never guess.** `jsdd park <ID> <gate> "<what a person must decide, in one sentence>"`. Then go to step 4: the run ends with a draft pull request that says what waits.
- **Record every decision as the run's, never a person's.** Write `auto: <gate>` and what passed it (`auto: plan.approve, sdd-reviewer`, `auto: verify.gap_option, the reviewer's recommendation`) in the spec's changelog, `verify-report.md`, or plan, and add it to the run report's "Decisions made without a person". The only decision recorded as the person's is the spec approval, because starting the run is it.
- **Only checks tick work.** `jsdd done` is the only way to tick a task, as always. Checks are frozen when the plan is approved (`jsdd freeze`); a check is never weakened to make it pass.
- **Never touch what belongs to people.** `specs/constitution.md`, `docs/intent.md`, `specs/jsdd.yml`, and `checks.lock` (a hook blocks the edit), the priority of a Must row in `docs/requirements.md`, and the main branch. Never force-push, rewrite history, or merge.
- **Budgets.** `jsdd budget attempts_per_task` caps the attempts at one task; `jsdd run status <ID>` fails when the wall-time budget is spent. Check it between phases; when it fails, go to step 4.
- **Keep going.** Do not end your turn until step 5 is done. While the run is open, the Stop hook sends you back to it as long as you keep making progress.

## 1. Preflight

The person is probably still watching here. Anything wrong at this step is refused with what to fix, not parked: nothing has started yet.

- `jsdd mode` must say `autopilot`. If not, stop and explain: the project allows it in `specs/jsdd.yml` (`modes: [manual, autopilot]`), and the person picks it with `SDD_MODE=autopilot` (in the shell, or under `env` in `.claude/settings.local.json`), then starts a new session.
- An ID is required: a run takes one spec. Open `specs/<ID>-*/spec.md`.
  - Only `type: feature`. A spike or baseline needs the person: suggest `/jsdd:spike` or `/jsdd:baseline`.
  - Status `draft`, `approved`, `planned`, or `in-progress`. `done` or `dropped`: nothing to run. `blocked`, or `draft` with a `verify-report.md` whose Decision is `approved` (a spec change waits): the person settles it first with `/jsdd:plan` or `/jsdd:specify`.
  - No `[NEEDS CLARIFICATION` markers in `spec.md`: suggest `/jsdd:specify <ID>`.
  - Not parked (`parked:` in the frontmatter): the person settles what it says, then runs `jsdd unpark <ID>`.
  - Every spec in `depends_on` is `done`.
- **Git.** The work tree must be clean except for the spec being run and the documents specify edits (`specs/<ID>-*/`, `docs/requirements.md`, `PLAN.md`, `BACKLOG.md`, `specs/STATUS.md`); commit those as `[<ID>] Spec`. Anything else uncommitted: stop and list it. If the current branch is the main branch (`$SDD_MAIN_BRANCH`, else `main`), create one: `git switch -c autopilot/<ID>-<slug>`.
- **Pull request.** Check `git remote get-url origin` and `gh auth status`. If either fails, say that the run will end with a local branch and a run report instead of a pull request, and go on.
- `jsdd run start <ID>`. It refuses another session's run.
- Create `run-report.md` in the spec folder from `${CLAUDE_PLUGIN_ROOT}/templates/run-report.md`, replacing `{{ID}}`, `{{TITLE}}`, `{{DATE}}`, and filling the header (the person is `git config user.name`).
- Tell the person, in a few lines, that the run starts now and will not ask anything; that any permission prompt will stall it, so the session needs a permission mode that does not prompt for edits, the project's test and build commands, `git`, and `gh`; and that they will get a pull request (or a draft one saying what waits for them).

## 2. The loop

Repeat until the spec is `done`, parked, or the budget is spent. Before each pass, run `jsdd run status <ID>`. Read the spec's status and act:

| Status | Do |
| --- | --- |
| `draft` or `approved`, no `plan.md` | Follow `/jsdd:plan <ID>`. Its autopilot rules approve the spec, have the reviewer approve the plan, and freeze the checks. |
| `approved` with a `verify-report.md` whose gaps are not planned | Follow `/jsdd:plan <ID>` in amend mode. |
| `planned` or `in-progress`, tasks left | Follow `/jsdd:implement <ID>`: every task, one commit each. |
| `in-progress`, every task ticked | Follow `/jsdd:verify <ID>`. Converged closes the spec (`done`); gaps a check can fix are approved, and the loop plans and builds them. |
| `done` | Go to step 3. |

Follow each skill as written, with the policies `jsdd gate` gives and the skill's autopilot rules. After each phase, add a line to the run report's Timeline (plan with its review rounds, each task with its attempts, each verification round with its outcome) and commit what the phase changed, starting the message with `[<ID>]`.

## 3. Close

- The spec is `done`: verify merged its capability changes and ticked PLAN.md. Make sure everything is committed.

## 4. Pull request (gate `pr.open`)

Reached when the spec is `done`, parked, or the budget ran out. A run that committed nothing beyond the spec opens no pull request.

- Finish the run report: Outcome, Ended, the Parked section (the gate and what the person must decide, or "nothing"), and "For the reviewer": the two or three places a person should read first (decisions made without them, deviations, gaps the reviewer raised and the run left). Run `jsdd status --write`. Commit as `[<ID>] Run report`.
- If `jsdd gate pr.open` is `park`, leave the branch unpushed and say so. Otherwise:
  - `git push -u origin HEAD` (never `--force`).
  - Write the body with `jsdd pr <ID>` to a file outside the repository, and open the pull request with `gh pr create --base <main branch> --title "$(jsdd pr <ID> --title)" --body-file <file>`. Add `--draft` when the spec is not `done`. If the branch already has an open pull request (`gh pr view`), update it with `gh pr edit --body-file <file>` instead.
  - If the push or `gh` fails, record why in your final message; the branch and report stay as they are.
- Never merge (gate `merge`).

## 5. End the run

- `jsdd run end <ID>`. Release any claim this session still holds (`jsdd claims`; `jsdd release <ID> [Tn]`).
- Report in a few lines: the pull request link (or why there is none), the outcome, the tasks built, each decision made without the person (from the run report), what parked and what the person must decide to unpark it, and the next step: review the pull request; for a parked spec, settle the question, `jsdd unpark <ID>`, and run `/jsdd:auto <ID>` again to continue on the same branch.
