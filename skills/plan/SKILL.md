---
name: plan
description: Approve a spec and write its technical plan (plan.md) and task list (tasks.md), or amend them with follow-up tasks for the gaps a verification found. Use when a feature spec in specs/ is ready to be planned, or when /jsdd:verify left it approved or blocked with gaps to fix, or in draft after /jsdd:specify revised it; spikes are run with /jsdd:spike instead.
argument-hint: <spec ID>
---

# Plan

Spec: $ARGUMENTS

You write the HOW for one spec. You do not implement.

**Runtime mode.** Run `jsdd mode` first. The decision points below are marked with their gate, like (gate `spec.approve`). When you reach one, `jsdd gate <gate>` gives its policy. `ask`: a person decides, as the step says; in `manual` mode every gate asks. `auto`: pass it by the gate's autopilot rule in "Autopilot rules" below, and record the decision as `auto: <gate>` with what passed it, never as a person's; when the rule cannot pass it, park. `park`: ask nobody and guess nothing. Run `jsdd park <ID> <gate> "<what a person must decide>"`, release your claims, run `jsdd status --write`, and stop (inside `/jsdd:auto`, go to its pull request step). In any mode other than `manual` and `autopilot`, stop and tell the user that this skill does not support it yet.

## Autopilot rules

In `autopilot` mode (see `/jsdd:auto`), these rules pass this skill's gates. Nobody is asked anything.

- **Spec approval** (gate `spec.approve`): the person approved the spec by starting `/jsdd:auto <ID>` (or by running this command). Add the changelog line "Approved (by <`git config user.name`>, by starting /jsdd:auto)." It is the only decision of the run recorded as a person's.
- **Dependencies** (gate `depends.override`): parks.
- **Checks you can run.** An autopilot plan has no `check: manual:`. Write every task's check as a command that fails on the code as it is now and passes once the task is done, and name a test or command for every AC in the test strategy. If an AC cannot be proven by any command, write the plan, then park at `task.manual_check` naming the AC.
- **Plan approval** (gate `plan.approve`, after step 4 or amend step 6): launch the `sdd-reviewer` agent in `plan` mode, saying the plan is for an autopilot run. Fix the blocking findings, and the others you agree with; then run the reviewer again on what changed. The gate passes on the first round with no blocking finding, at most three rounds. Then run `jsdd freeze <ID>` (in amend mode it adds the new tasks to `checks.lock`) and add the changelog line "Plan approved (auto: plan.approve, sdd-reviewer round <n>)." (for an amendment, "Amendment A<n> approved (auto: plan.approve, …)."). Blocking findings left after the third round: park at `plan.approve` with them.
- **Amend mode.** The gaps were decided by verify's autopilot rules, recorded as `auto: verify.gaps` and `auto: verify.gap_option`: plan them as decided. A `blocked` spec, or a kept spec-change gap, parks at `spec.change`.
- **Finish** commits the plan, tasks, `checks.lock`, and spec as `[<ID>] Plan` (or `[<ID>] Amendment A<n>`); there is no report to a person.

## 1. Gate

- Open `specs/$ARGUMENTS-*/spec.md`. If no ID was given, run `jsdd next` and ask which spec to plan.
- If the spec is a spike (`type: spike`), stop: spikes have no plan. Suggest `/jsdd:spike <ID>`.
- If the spec is a baseline (`type: baseline`), stop: a baseline records existing behavior and has no plan. Suggest `/jsdd:baseline <ID>` or `/jsdd:verify <ID>`.
- If the spec has any `[NEEDS CLARIFICATION` markers, stop: list them and suggest `/jsdd:specify <ID>`.
- If any spec in `depends_on` is not `done`, say so and ask whether to plan anyway (gate `depends.override`).
- Claim the spec: `jsdd claim <ID>`. If another session holds it, stop and report who.
- **Amend mode:** if the folder has a `verify-report.md` with gaps that are not yet planned (no "Planned as" line), and the status is `approved` or `draft` (Decision `approved`) or `blocked` (Decision `declined`), go to step 6 instead of steps 2 to 5. Never write a new plan over one that was built. Any other `blocked` spec: report the reason from its changelog and stop.
- Running this command is the user's approval of the spec (gate `spec.approve`). If the status is `draft`, set it to `approved` and add a changelog line. (In amend mode, step 6 does this.)

## 2. Load context

- Read `specs/constitution.md` and the spec.
- Read the code, configuration, and specs that the work touches. Read `plan.md` of the specs it depends on, and the capability document entries (`docs/capabilities/<group>.md`) of the rows in the spec's Capability changes: they say how the area works now, which the design must keep unless the spec changes it.
- Check current documentation for every library, SDK, or tool the plan relies on, and note the versions (Article 6). When there are three or more, launch one `spike-researcher` agent per library in a single message, each with a focus such as "current stable version of <library>, and the documented way to <what the plan needs>; cite the docs page and date". Use its findings, not memory, for the versions.

## 3. Write the plan and tasks

- Create `plan.md` and `tasks.md` in the spec folder from `${CLAUDE_PLUGIN_ROOT}/templates/`, replacing `{{ID}}` and `{{TITLE}}`.
- **plan.md:** the approach, the constitution check (every article the work touches, how it complies, and a justification for any exception), the design, requirement coverage (every R maps to part of the design), decisions with alternatives (a decision that settles an ND, or that later specs must respect, also gets its DEC row in `docs/decisions.md`, and the BACKLOG item is ticked; cite the DEC IDs the plan relies on), the test strategy (every AC maps to how it is verified), and risks.
- **tasks.md:** ordered tasks, each small (half a day at most), leaving the build green, naming the files or modules it touches, its check, and the ACs it serves (`→ AC-n`). Write the check as a command in backticks (``check: `make test` ``, using the test command in the constitution's Project specifics), which `jsdd done` runs, or as `check: manual: <what a person checks>` when no command can prove it. Test first where it fits. Mark tasks that can run in parallel with `[P]` right after the task ID (`- [ ] **T3** [P] …`): consecutive `[P]` tasks can be claimed by different sessions at once, while any other task waits for every task before it. Use `[P]` only for tasks that touch different files and do not need each other's code. Keep the Evidence section.
- If planning shows the spec is wrong or incomplete, fix the spec first and add a changelog line. Do not add requirements in the plan.

## 4. Review

- Launch the `sdd-reviewer` agent in `plan` mode with the spec folder.
- Fix the blocking findings and the ones you agree with in the plan or tasks. Keep the others for the report, with a line on why you left each.

## 5. Finish

- Set `status: planned` and `updated` in the spec. Release the spec (`jsdd release <ID>`) and run `jsdd status --write`.
- Report briefly: the key decisions, the number of tasks, any risks, the reviewer findings you did not apply, and the next step: the user reviews the plan, then runs `/jsdd:implement <ID>`.

## 6. Amend mode: plan the gaps a verification found

The plan and tasks already exist and were built. You add to them; you do not rewrite them. Every change is traceable to a gap in `verify-report.md`.

1. **Gate.** Plan only what the user decided. If the status is `blocked`, show the report's Proposed actions and ask the user to confirm which to plan (gate `verify.gaps`), and for each gap with options, which one (gate `verify.gap_option`); record the answers on the gaps as verify does (`Chosen: b (<by whom>)`, `(dropped by <who>)`). Then set Decision `approved (<by whom>, via /jsdd:plan, <date>)` and add a changelog line: "Resumed: planning the gaps from verification round <n>." If the status is `approved` but a gap with options has no `Chosen:` answer, ask for that too. **Never record an approval or a choice the user did not give.** (In `autopilot` mode, verify's rules recorded them as `auto:`; see Autopilot rules.) Plan does not edit the spec: if a kept gap is a spec change and the spec's changelog has no line for it ("Verify round <r>/G<n>: …"), set `status: draft` (when it is `blocked` or `approved`), add a changelog line: "Spec changes from verification round <r> go through /jsdd:specify first.", release the spec, run `jsdd status --write`, suggest `/jsdd:specify <ID>`, and stop. Otherwise, if the status is `draft`, running this command is the user's approval of the revised spec (gate `spec.approve`): set it to `approved` and add a changelog line. If you cannot get an answer (for example, in a run nobody is watching), change nothing, release the spec, and report what is waiting for the user. Read `specs/constitution.md`, `spec.md`, `plan.md`, `tasks.md`, and `verify-report.md`.
2. **Number the amendment** A1, A2, … after the last one in the plan's Amendments section.
3. **Plan each approved gap**, never a dropped one:
   - **Fix the code:** one or more tasks, following the task rules in step 3.
   - **Change the spec:** `/jsdd:specify` already made the change; its changelog line names the gap. Plan for what the revised R or AC means for the build: a task when the code still has to change, Design or Test strategy changes in the amendment, or nothing. Do not edit `spec.md`.
   - **Record a Deviation:** add a row to the plan's Deviations, starting with the amendment and gap ("A2/G4: …").
   - **Move to BACKLOG.md:** add the item there.
   - A Design section the fix changes is edited in place, with "(changed in A<n>)" after the change.
4. **Write the follow-up tasks** in `tasks.md` under the Tasks section, after the last task, under a heading `### A<n> · Follow-up from verify round <r>`. Number them after the last task, and end each one with the gap it serves: `→ AC-2 (A2/G1)`.
5. **Write the amendment** in the plan's Amendments section, from the template's example. It is self-contained: its source (the report round and who approved it), one row per gap, planned or dropped, saying what it became (tasks, spec change, Deviation, or BACKLOG item), and, when the amendment has any, its own Decisions (including the options chosen), Constitution check, Test strategy rows for the ACs it adds or re-tests, and Risks. Do not edit the plan's original tables to add these, and do not ask anyone to merge them later: the original plan stays as it was built, and the amendment says what changed. Every gap in the report's Proposed actions has a row.
6. **Review.** Launch the `sdd-reviewer` agent in `plan` mode with the spec folder, saying that amendment A<n> is new. Fix the blocking findings as in step 4.
7. **Finish.** In `verify-report.md`, set "Planned as" to `A<n> in plan.md`. If the amendment added tasks, set `status: planned`; implementing them is the user's approval of the amendment. If it added none (only spec changes, Deviations, or BACKLOG items), set `status: in-progress` and suggest `/jsdd:verify <ID>` to check again. Add a changelog line, release the spec, and run `jsdd status --write`.
8. Report briefly: the amendment, each gap and what it became, the follow-up tasks, and the next step: the user reviews the amendment, then runs `/jsdd:implement <ID>` (or `/jsdd:verify <ID>` when no tasks were added).
