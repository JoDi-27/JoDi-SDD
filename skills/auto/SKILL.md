---
name: auto
description: Run specs to pull requests with nobody asked. In autopilot mode, /jsdd:auto <ID> takes one feature spec the person wrote and approved through plan, implement, and verify to a pull request. In autonomous mode, /jsdd:auto with no ID works through the queue within the project's charter (the autonomous section of specs/jsdd.yml), including spikes and baselines it allows, and can merge converged work. Anything only a person can decide parks the spec instead of being guessed. Also /jsdd:auto setup writes the charter, /jsdd:auto --dry-run shows what a run would do, and /jsdd:auto doctor checks what an unattended run needs. Use when the user runs /jsdd:auto, with SDD_MODE=autopilot or SDD_MODE=autonomous.
argument-hint: "[<spec ID> | setup | --dry-run | doctor]"
---

# Auto

Input: $ARGUMENTS

Two modes run work with nobody asked:

- **autopilot**: the person wrote and approved one spec. `/jsdd:auto <ID>` takes it to a pull request. Starting the run is their approval of the spec.
- **autonomous**: the project committed a **charter** (the `autonomous:` section of `specs/jsdd.yml`: a preset, a product class, the scope, and budgets), and the person typed `/jsdd:auto`. A **loop** takes specs from `jsdd auto queue` one by one, each to a pull request, until the queue is empty or a budget runs out. Here nobody approved each spec: the `sdd-reviewer` does. Product questions go to the `sdd-product` agent, and the charter's product class says how far the run may act on its answers.

In both, every gate is passed by a check, the fresh-context reviewer, or a rule written in the skills; a gate none of those can pass **parks** the spec, and the person picks it up from the pull request and the board. The person approves once more at the end, by reviewing the pull request, or in autonomous mode with `merge: auto` (preset `hands-off`), by reading the run reports of what was merged.

## Which command

| Input | Do |
| --- | --- |
| `setup` | Step A: write the charter. Allowed in any mode. |
| `--dry-run` | Run `jsdd auto dry-run` and show its output: what a loop would take, in order, where each spec may park, and what it leaves out and why. Change nothing. |
| `doctor` | Run `jsdd auto doctor` and show its output with each fix. |
| a spec ID | One run on that spec: steps 1 to 5. |
| nothing | Autonomous mode: the loop, step 6. In autopilot mode, an ID is required: say so, and show `jsdd next`. |

## Rules for the whole run

- **Never ask.** No AskUserQuestion, no "should I…?" in chat, no waiting for an answer. The gate policy (`jsdd gate <gate>`) says what to do: `auto` passes the gate by its rule in the skill that reaches it (its "Autopilot and autonomous rules"), `park` parks it. A gate whose policy is `ask` cannot be reached in a run; if one is, park at it.
- **Park, never guess.** `jsdd park <ID> <gate> "<what a person must decide, in one sentence>"`. Then go to step 4: the run ends with a draft pull request that says what waits. In the loop, the next spec goes on.
- **Record every decision as the run's, never a person's.** Write `auto: <gate>` and what passed it (`auto: plan.approve, sdd-reviewer`, `auto: verify.gap_option, the reviewer's recommendation`, `auto: product, sdd-product, cited (BACKLOG.md § Open decisions)`) in the spec's changelog, `verify-report.md`, or plan, and add it to the run report's "Decisions made without a person". In autopilot, the only decision recorded as the person's is the spec approval, because starting the run is it. In autonomous mode there is none.
- **Product decisions** (autonomous only). A product question (an open marker, gap options that differ in product behavior, a spec change, which part of a split comes first, bug or intended) goes to the `sdd-product` agent, never to your own judgment: launch it with the questions, their context, and `jsdd charter get product`. Act on an answer only when its class is within the charter's product class. The classes go `cited`, then `inferred`, then `uncited`, then `conflict`: `cited` allows only cited answers, `inferred` allows cited and inferred, `uncited` allows everything but conflicts, `all` allows conflicts too, and `park` allows none. A `protected` answer is never acted on. An answer beyond the class parks at the gate that asked, with the agent's answer and class in the reason, so the owner sees what the run would have done. For each answer acted on:
  - Write it where it belongs (the spec, `Chosen:` in `verify-report.md`, the split), marked `(assumed, auto: product, sdd-product, <class> (<basis>))`.
  - Add a row to the **Assumed** section of `docs/decisions.md` (create the section after "Still open" if it is missing, with the header `| ID | Decision | Choice | Class | Basis | Reversal | Spec | Date |`), numbered `AS-nn` after the last one. The owner later confirms a row (it becomes a DEC row) or rejects it (it is removed, with a BACKLOG item or a new spec to undo it).
  - Add it to the run report's "Product decisions", weakest basis first: conflict, uncited, inferred, then cited. An `expensive` reversal also goes under "For the reviewer".
- **Only checks tick work.** `jsdd done` is the only way to tick a task or acceptance criterion. Checks are frozen when the plan is approved (`jsdd freeze`); a check is never weakened to make it pass.
- **Never touch what belongs to people.** `specs/constitution.md`, `docs/intent.md`, `specs/jsdd.yml` (the charter), and `checks.lock` (a hook blocks the edit), the priority of a Must row in `docs/requirements.md`, and the main branch, except a merge that `jsdd gate merge` allows. Never force-push or rewrite history.
- **Budgets.** `jsdd budget attempts_per_task` caps the attempts at one task; `jsdd run status <ID>` fails when the wall-time budget is spent (in a loop, the loop's clock). Check it between phases; when it fails, go to step 4.
- **Keep going.** Do not end your turn until the run (or the loop) is ended. While it is open, the Stop hook sends you back as long as you keep making progress.

## A. Setup (`/jsdd:auto setup`)

The person is here: ask, with recommended answers first.

1. Run `jsdd mode --check` and read `specs/jsdd.yml` if it exists. Keep what is there; change only the `modes` list and the `autonomous:` section.
2. Ask in one AskUserQuestion call:
   - **Preset:** `cautious` (Recommended: the `sdd-product` agent decides only what the docs already answer, `product: cited`; every other product question and every spec change parks; each spec ends at a pull request), `standard` (it also decides what follows from the principles, `product: inferred`), `hands-off` (it decides everything outside the protected files, `product: all`, including spec changes from verification, and a converged spec is merged once CI is green).
   - **Scope, types:** features only (Recommended), or also baselines and spikes.
   - **Scope, phases:** the current PLAN.md phase (Recommended), or every phase.
   - **Budget:** specs per loop, 3 (Recommended), 1, or 5.
   Then ask in chat whether any requirement groups are off limits (billing, auth, anything with money or personal data), listing the groups in `docs/requirements.md`.
3. Write `specs/jsdd.yml`, with a comment on each line saying what it does:

   ```yaml
   version: 1
   modes: [manual, autonomous]   # add autopilot too if the project uses it

   # The charter: what an autonomous run may do here. A run can never edit this file.
   autonomous:
     preset: cautious            # cautious | standard | hands-off
     product: cited              # optional: how far sdd-product decides (park | cited | inferred | uncited | all)
     types: [feature]            # feature, baseline, spike
     phases: [1]                 # PLAN.md phases; leave out for every phase
     exclude_groups: []          # requirement groups a run never touches, like [FR-BILLING]
     specs_per_run: 3
     wall_time_hours: 4
   ```

   A gate set under `autonomous:` (`spec.clarify: park`) overrides the preset; `jsdd mode --explain` lists them all.
4. Run `jsdd mode --check` until it passes. Commit as `[meta] Autonomy charter` if the person agrees.
5. Tell them the next steps: each person who wants to run it sets `SDD_MODE=autonomous` (in the shell, or under `env` in `.claude/settings.local.json`) and starts a new session; `/jsdd:auto doctor` checks the rest (most often, a permission mode that will not stall the run); `/jsdd:auto --dry-run` shows what a run would take; `/jsdd:auto <ID>` runs one spec, and `/jsdd:auto` the loop once that is trusted.

## 1. Preflight

The person is probably still watching here. Anything wrong at this step is refused with what to fix, not parked: nothing has started yet. In a loop, a spec that fails preflight is parked at the gate that fits (or skipped with a line in the loop report), and the loop goes on.

- `jsdd mode` must say `autopilot` or `autonomous`. If not, stop and explain: the project allows the mode in `specs/jsdd.yml` (`/jsdd:auto setup` writes it), and the person picks it with `SDD_MODE=<mode>`, then starts a new session.
- Open `specs/<ID>-*/spec.md`.
  - **Type.** Autopilot: only `feature`; a spike or baseline needs the person, so suggest `/jsdd:spike` or `/jsdd:baseline`. Autonomous: `feature`, and `baseline` or `spike` when the charter's `types` lists it (`jsdd mode --explain`). When the spec is outside the charter's scope (`jsdd auto dry-run` lists why), a run the person started by ID goes on, and the run report says so.
  - **Status** `draft`, `approved`, `planned`, or `in-progress`. `done` or `dropped`: nothing to run. `blocked`: the person settles it first with `/jsdd:plan`. `draft` with a `verify-report.md` whose Decision is `approved` (a spec change waits): in autopilot, the person settles it with `/jsdd:specify`; in autonomous mode, the run goes on when the report records the change as `auto: spec.change`.
  - **Open questions.** `[NEEDS CLARIFICATION` markers in `spec.md`: autopilot refuses, and suggests `/jsdd:specify <ID>`. Autonomous: `/jsdd:specify <ID>`'s autonomous rules settle them (gate `spec.clarify`) in step 2.
  - Not parked (`parked:` in the frontmatter): the person settles what it says, then runs `jsdd unpark <ID>`.
  - Every spec in `depends_on` is `done`.
- **Git.** The work tree must be clean except for the spec being run and the documents specify edits (`specs/<ID>-*/`, `docs/requirements.md`, `PLAN.md`, `BACKLOG.md`, `specs/STATUS.md`, and in a loop its report under `specs/runs/`); commit those, except the loop report, as `[<ID>] Spec`. Anything else uncommitted: stop and list it. If the current branch is the main branch (`$SDD_MAIN_BRANCH`, else `main`), create one: `git switch -c <mode>/<ID>-<slug>`. In a loop, each spec gets its own branch from the main branch: `git switch <main> && git pull --ff-only` (when there is a remote), then `git switch -c autonomous/<ID>-<slug>`.
- **Pull request.** Check `git remote get-url origin` and `gh auth status`. If either fails, say that the run will end with a local branch and a run report instead of a pull request, and go on.
- `jsdd run start <ID>` (in a loop, `jsdd run next` already did). It refuses another session's run.
- Create `run-report.md` in the spec folder from `${CLAUDE_PLUGIN_ROOT}/templates/run-report.md`, replacing `{{ID}}`, `{{TITLE}}`, `{{DATE}}`, and filling the header (the mode; for autopilot the person is `git config user.name`; for autonomous, the preset and the loop it belongs to).
- Outside a loop, tell the person, in a few lines, that the run starts now and will not ask anything; that any permission prompt will stall it (`/jsdd:auto doctor` checks the permission mode); and that they will get a pull request (or a draft one saying what waits for them).

## 2. The run

Repeat until the spec is `done`, parked, or the budget is spent. Before each pass, run `jsdd run status <ID>`. Read the spec's type and status and act:

| Spec | Do |
| --- | --- |
| feature, `draft` with `[NEEDS CLARIFICATION` markers (autonomous) | Follow `/jsdd:specify <ID>`, step 4, by its autonomous rules. |
| feature, `draft` with a `verify-report.md` whose Decision is `approved` (autonomous, a spec change `sdd-product` decided) | Follow `/jsdd:specify <ID>`, step 3a, by its autonomous rules, then `/jsdd:plan <ID>` in amend mode. |
| feature, `draft` or `approved`, no `plan.md` | Follow `/jsdd:plan <ID>`. Its rules approve the spec (autopilot: the person, by starting the run; autonomous: the reviewer's spec mode), have the reviewer approve the plan, and freeze the checks. |
| feature, `approved` with a `verify-report.md` whose gaps are not planned | Follow `/jsdd:plan <ID>` in amend mode. |
| feature, `planned` or `in-progress`, tasks left | Follow `/jsdd:implement <ID>`: every task, one commit each. |
| feature, `in-progress`, every task ticked | Follow `/jsdd:verify <ID>`. Converged closes the spec (`done`); gaps a check can fix are approved, and the run plans and builds them. |
| baseline, `draft` (autonomous) | Follow `/jsdd:baseline <ID>` by its autonomous rules. |
| baseline, `in-progress` (autonomous) | Follow `/jsdd:verify <ID>`. |
| spike, `draft` or `in-progress` (autonomous) | Follow `/jsdd:spike <ID>` by its autonomous rules; once every goal question is answered, `/jsdd:verify <ID>`. |
| `done` | Go to step 3. |

Follow each skill as written, with the policies `jsdd gate` gives and the skill's autopilot and autonomous rules. After each phase, add a line to the run report's Timeline (the spec review, clarifications with their sources, the plan with its review rounds, each task with its attempts, each verification round with its outcome) and commit what the phase changed, starting the message with `[<ID>]`.

## 3. Close

- The spec is `done`: verify merged its capability changes and ticked PLAN.md. Make sure everything is committed.

## 4. Pull request (gate `pr.open`) and merge (gate `merge`)

Reached when the spec is `done`, parked, or the budget ran out. A run that committed nothing beyond the spec opens no pull request.

- Finish the run report: Outcome, Ended, the Parked section (the gate and what the person must decide, or "Nothing."), "Product decisions" (every `sdd-product` answer acted on, weakest basis first, each with its class, basis, reversal cost, and `AS-nn` row), and "For the reviewer": the two or three places a person should read first (decisions made without them, product decisions that are uncited, conflicts, or `expensive` to reverse, deviations, gaps the reviewer raised and the run left). Run `jsdd status --write`. Commit as `[<ID>] Run report`.
- If `jsdd gate pr.open` is `park`, leave the branch unpushed and say so. Otherwise:
  - `git push -u origin HEAD` (never `--force`).
  - Write the body with `jsdd pr <ID>` to a file outside the repository, and open the pull request with `gh pr create --base <main branch> --title "$(jsdd pr <ID> --title)" --body-file <file>`. Add `--draft` when the spec is not `done`. If the branch already has an open pull request (`gh pr view`), update it with `gh pr edit --body-file <file>` instead.
  - If the push or `gh` fails, record why in the run report and your final message; the branch and report stay as they are.
- **Merge** only when all of these hold: `jsdd gate merge` is `auto` (autonomous mode, preset `hands-off` or a project setting); the spec is `done` and not parked; verify converged with no gap left; and the pull request has at least one CI check and every check passed (`gh pr checks <n> --watch`; a pull request with no checks is never merged). Then `gh pr merge <n> --merge` (a merge commit keeps each `[<ID>] T<n>` commit, which the requirement history relies on; never `--admin`), and add "Merged (auto: merge, CI green)" to the run report and the spec's changelog. A failed or missing check, or a merge `gh` refuses: leave the pull request open and say why in the run report. Autopilot never merges.

## 5. End the run

- `jsdd run end <ID>`. Release any claim this session still holds (`jsdd claims --mine`; `jsdd release <ID> [Tn]`).
- In a loop, go back to step 6. Otherwise report in a few lines: the pull request link (or why there is none), the outcome, the tasks built, each decision and product decision made without the person (from the run report), what parked and what the person must decide to unpark it, and the next step: review the pull request; for a parked spec, settle the question, `jsdd unpark <ID>`, and run `/jsdd:auto <ID>` again to continue on the same branch.

## 6. The loop (autonomous, `/jsdd:auto` with no ID)

1. **Start.** `jsdd mode` must say `autonomous`. Run `jsdd auto doctor`: anything under FIX stops the loop before it starts, with the fix. Run `jsdd auto dry-run` and show it to the person in a few lines, saying the loop starts now and asks nothing. `jsdd run start --loop`. Create the loop report `specs/runs/<date>-<n>.md` (the next free `<n>` for today) from `${CLAUDE_PLUGIN_ROOT}/templates/loop-report.md`.
2. **Take the next spec.** `jsdd run next` prints its ID and starts its run, or exits non-zero saying why the loop takes no more: the queue is empty, `specs_per_run` is reached, or the wall-time budget is spent. Then go to 4.
3. **Run it**: steps 1 to 5 for that ID. Add its line to the loop report (the spec, its outcome, the pull request, merged or not, where it parked), then go back to 2. The loop report stays uncommitted until step 4 (preflight lets `specs/runs/` through), and is never committed on the main branch directly. A spec that cannot start (preflight fails) parks or is skipped with its reason; the loop goes on.
4. **End.** Finish the loop report: the specs taken and their outcomes, every parked spec with what a person must decide, and the morning digest: what was merged or is waiting in pull requests, the product decisions made across specs (weakest basis first, and how many `AS-nn` rows now wait for the owner), and what `jsdd auto dry-run` would take next. Commit it on the last run's branch (push and update its pull request), or when no spec ran, leave it uncommitted and say so. `jsdd run end --loop`. Report in a few lines: the pull requests (and merges), what parked and why, the budget left, and where the loop report is.
