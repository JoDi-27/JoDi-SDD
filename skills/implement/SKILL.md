---
name: implement
description: Implement a planned feature spec task by task, ticking each task only when its check passes. Use when a spec in specs/ is planned or in progress.
argument-hint: <spec ID> [task ID, e.g. T3]
---

# Implement

Arguments: $ARGUMENTS (spec ID, then an optional task ID)

**Runtime mode.** Run `jsdd mode` first. The decision points below are marked with their gate, like (gate `plan.approve`). When you reach one, `jsdd gate <gate>` gives its policy. `ask`: a person decides, as the step says; in `manual` mode every gate asks. `auto`: pass it by the gate's rule in "Autopilot and autonomous rules" below, and record the decision as `auto: <gate>` with what passed it, never as a person's; when the rule cannot pass it, park. `park`: ask nobody and guess nothing. Run `jsdd park <ID> <gate> "<what a person must decide>"`, release your claims, run `jsdd status --write`, and stop (inside `/jsdd:auto`, go to its pull request step). In a mode other than `manual`, `autopilot`, and `autonomous`, stop and tell the user that this skill does not support it.

## Autopilot and autonomous rules

In `autopilot` and `autonomous` mode (see `/jsdd:auto`), these rules pass this skill's gates. Nobody is asked anything.

- **Plan approval** (gate `plan.approve`): passes when the spec folder has `checks.lock` and the changelog says the current plan (or its newest amendment) was approved by `auto: plan.approve`. Otherwise, approve it as `/jsdd:plan`'s autopilot rule does (reviewer rounds, then `jsdd freeze <ID>`), or park. The changelog line for `in-progress` is "Implementing (auto: plan.approve)."
- **Stuck** (gate `implement.stuck`):
  - A check fails: fix the code, never the check or the assertions of the tests it runs. Up to `jsdd budget attempts_per_task` attempts (a change, then `jsdd done`). Still failing: release the task, park at `implement.stuck` with the failing output in one line.
  - The plan is wrong: add a Deviation row starting `auto: implement.stuck:` with what changed and why, and change the design or tasks. A changed or new check needs the `sdd-reviewer` in `plan` mode, told which tasks changed and why, to raise no blocking finding; then `jsdd freeze <ID> --accept <Tn>` for a changed check, or `jsdd freeze <ID>` for a new task. Otherwise park.
  - A decision the plan lacks: decide it only when nothing in the spec, the constitution, or `docs/decisions.md` bears on it and a user of the product would not notice the difference (a name, an internal structure); record it as a Deviation starting `auto: implement.stuck:`. Anything else parks.
  - Something only a person can do (credentials, an account, a paid service, a device): park.
- **Manual checks** (gate `task.manual_check`) and **spec changes** (gate `spec.change`): park.
- **Commits** (gate `commit`): after each `jsdd done`, commit only that task's files with a message starting `[<ID>] T<n>`.

## 1. Gate

- Open the spec folder `specs/<ID>-*/`. If no ID was given, run `jsdd next` and ask which one.
- If the spec is a spike (`type: spike`), stop and follow the `/jsdd:spike` skill instead.
- If the spec is a baseline (`type: baseline`), stop: nothing is built. Suggest `/jsdd:verify <ID>`.
- The status must be `planned` or `in-progress`. If it is `draft` or `approved`, stop and suggest `/jsdd:plan <ID>` (or `/jsdd:specify <ID>` first, for a `draft` spec with a `verify-report.md` whose Decision is `approved`: its spec is being revised). If it is `blocked` with a `verify-report.md` whose Decision is `declined`, stop and suggest `/jsdd:plan <ID>`, which resumes it by planning the gaps.
- Running this command is the user's approval of the plan (gate `plan.approve`). If the status is `planned`, set it to `in-progress` and add a changelog line.
- Read `specs/constitution.md`, `spec.md`, `plan.md`, and `tasks.md`.

## 2. Work the tasks

Other sessions may be working on the same spec. Never pick a task by reading `tasks.md`; claim it, and work only on a task you hold.

1. Claim the task: `jsdd claim <ID> <Tn>` for a given task (refused while earlier tasks are unfinished; then use `jsdd claim <ID> next`), or else `jsdd claim <ID> next`, which prints the task it claimed (or the one this session already holds). If the claim fails, stop and report its message: who holds which task, or what the free tasks wait on.
2. Do exactly that task, following the plan. Test first where the task calls for it.
3. Run the build and the relevant tests so the tree stays green.
4. Run `jsdd done <ID> <Tn>`. It runs the task's check and, only when it passes, ticks the task and marks the claim done. Never tick a task by editing `tasks.md`. If the check fails, fix the work and run it again. For a `check: manual:` task, do the check (or ask the user to) (gate `task.manual_check`) and run `jsdd done <ID> <Tn> --manual "<who checked what>"`. If a task has no check at all, add one to its line in `tasks.md` and a row to the plan's Deviations.
5. If the user has asked for commits (gate `commit`), commit with a message starting `[<ID>] T<n>`; otherwise suggest that message.
6. Continue from step 1 with `claim <ID> next`, unless a task ID was given.

Stop and ask the user (gate `implement.stuck`) when: a check fails and the fix is not obvious, the plan turns out wrong, a task needs a decision the plan does not cover, or something requires a human action. If you stop with the task unfinished, keep the claim only if this session will resume it; otherwise release it with `jsdd release <ID> <Tn>`.

When reality disagrees with the documents, update them before the code (Article 4):
- Plan wrong: add a row to the plan's Deviations, and change the design or tasks.
- Spec wrong (behavior, scope, or ACs change): stop, explain, and get the user's agreement before editing the spec and its changelog (gate `spec.change`).
- New work found: add a new task; never do untracked extra work.

## 3. Finish

- Make sure this session holds no claim it will not resume (`jsdd claims`). Run `jsdd status --write`.
- Report briefly: tasks done in this session, what is left, deviations recorded, and the next step: `/jsdd:implement <ID>` again, or `/jsdd:verify <ID>` once every task is ticked.
