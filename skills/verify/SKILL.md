---
name: verify
description: Verify a spec's acceptance criteria (or a spike's answers) with evidence and check the code against its requirements, then close it, merge its capability changes into docs/capabilities/, and update PLAN.md and BACKLOG.md. Gaps go into a report for the user to approve, and /jsdd:plan turns approved gaps into tasks (a spec change goes through /jsdd:specify first); declining blocks the spec. Use when all of a spec's tasks are ticked, or when a baseline spec's current behavior is confirmed.
argument-hint: <spec ID>
---

# Verify

Spec: $ARGUMENTS

You prove that the spec is met. You do not add features.

**Runtime mode.** Run `jsdd mode` first. The decision points below are marked with their gate, like (gate `verify.gaps`). When you reach one, `jsdd gate <gate>` gives its policy. `ask`: a person decides, as the step says; in `manual` mode every gate asks. `auto`: pass it by the gate's rule in "Autopilot and autonomous rules" below, and record the decision as `auto: <gate>` with what passed it, never as a person's; when the rule cannot pass it, park. `park`: ask nobody and guess nothing. Run `jsdd park <ID> <gate> "<what a person must decide>"`, release your claims, run `jsdd status --write`, and stop (inside `/jsdd:auto`, go to its pull request step). In a mode other than `manual`, `autopilot`, and `autonomous`, stop and tell the user that this skill does not support it.

## Autopilot and autonomous rules

In `autopilot` and `autonomous` mode (see `/jsdd:auto`), these rules pass this skill's gates. Nobody is asked anything; what you would report to the user goes in the run report's "For the reviewer" section.

- **Manual checks** (gate `task.manual_check`): park.
- **Gaps** (gate `verify.gaps`): the report's gaps are approved together, or the spec parks. Approve when every gap is one of: fix the code, with a check that fails on the code as it is now; or record a Deviation, when it is the reviewer's recommended option and the drift changes no behavior an R or AC describes. Park at `verify.gaps` when a gap is a repeated gap (the two-rounds rule), or its only sensible actions are changing the spec or moving it to BACKLOG.md; park at `spec.change` when the kept action changes the spec, unless the spec-change rule below applies. On approval set Decision `approved (auto: verify.gaps, <date>)`, and write "(auto: verify.gaps)" at the end of the changelog line. When parking, leave Decision `pending`.
- **Options** (gate `verify.gap_option`): take the option the reviewer marked recommended, when it is a code fix or a Deviation as above, and record `Chosen: <option> (auto: verify.gap_option, the reviewer's recommendation)`. No recommendation, or a spec change: park. In autonomous mode, when the options differ in what a user would notice (not only in how the code is built), the choice is a product decision: ask the `sdd-product` agent instead, act on its answer by `/jsdd:auto`'s "Product decisions" rule, and record `Chosen: <option> (assumed, auto: product, sdd-product, <class> (<basis>), AS-nn)`.
- **Spec changes** (gate `spec.change`, autonomous mode, parks unless the preset is `hands-off` or the project sets `auto`): a gap whose only sensible fix is a spec change (and that is not a repeated gap) goes to the `sdd-product` agent, which says whether the spec changes (and how), the code changes, or the gap goes to `BACKLOG.md`. Act on its answer by `/jsdd:auto`'s "Product decisions" rule; an answer that drops or narrows a Must is protected and parks. When the spec changes, record the gap's action with the reworded R or AC and `(auto: spec.change, sdd-product, <class>, AS-nn)`, approve as above, and set `status: draft` as step 2d says for a kept spec change: `/jsdd:auto` then runs `/jsdd:specify` step 3a and `/jsdd:plan` amend mode by their autonomous rules.
- **Partial refs** (gate `verify.partial_ref`, parks unless the project sets `auto`): remove the ID from `refs`, add a BACKLOG.md item for the part not delivered, and record both as `auto: verify.partial_ref`.
- **Capability merges** (gate `verify.capability_merge`, parks unless the project sets `auto`): keep every statement of the entry that this spec's Rs do not contradict, never drop one, and record the merge as `auto: verify.capability_merge` in the History row.
- **Close** commits as `[<ID>] Close`.

## 1. Gate

- Open `specs/$ARGUMENTS-*/`. The status must be `in-progress`. If it is `blocked` with a `verify-report.md` whose Decision is `declined`, or `approved` with one whose Decision is `approved`, the gaps are waiting to be planned: suggest `/jsdd:plan <ID>` and stop. If it is `draft` with one whose Decision is `approved`, the spec is being revised: suggest `/jsdd:specify <ID>`, then `/jsdd:plan <ID>`, and stop.
- Claim the spec: `jsdd claim <ID>`. If another session holds the spec or one of its tasks, stop and report who.
- Every task must be ticked; for a spike, every goal question and question for the user, and the first deliverable (recommendation agreed). If not, list what is left and suggest `/jsdd:implement <ID>` (features) or `/jsdd:spike <ID>` (spikes).
- A baseline (`type: baseline`) has no tasks: it is ready when its status is `in-progress` and it has no `[NEEDS CLARIFICATION` markers. If it is still `draft`, suggest `/jsdd:baseline <ID>`. Go to step 2c.

## 2a. Feature: check every acceptance criterion

- Launch the `sdd-reviewer` agent in `verify` mode with the spec folder and the git range of the work: from the project's main branch (`$SDD_MAIN_BRANCH` if set, else `main`) to HEAD. When the work was committed directly on that branch, name the commits instead (for example the `[<ID>]` commits from `git log --oneline --grep '^\[<ID>\]'`). While it runs, do the checks below yourself.
- For each AC in `spec.md`, run its verification from the plan's test strategy: the named tests, commands, or a manual check.
- For a manual check that needs the user (for example, a UI flow), ask them to do it and record what they report (gate `task.manual_check`).
- Fill one row of the Evidence table in `tasks.md` per AC: pass or fail, and concrete evidence (test name, command and its relevant output, or who checked what).
- Also confirm: the full build and test suite pass, every requirement is covered by a passing AC, every requirement ID in the spec's `refs` is tagged on an R whose ACs pass, and the plan's Deviations reflect what was built. An ID in `refs` that the work only partly delivers is either split into a new row of `docs/requirements.md` (and the delivered part kept in `refs`) or removed from `refs`, with the user's agreement (gate `verify.partial_ref`). The Capability changes table has a line for every row an R is tagged with, and each line's change matches the code: a `removes` whose behavior is still there is a gap.
- **Converge the code with the spec.** Passing tests are not enough: for each R, find the code that delivers it and check that it does what the R says, no more and no less (`delivered`, `partial`, `missing`, or `contradicted`, with `file:line`). Also look for behavior in the changed code that no R asks for, and for differences from the plan's Design and tasks that its Deviations do not record.
- Compare with the reviewer's report. Where it says an AC is failed or unproven, or an R is not delivered, and you found otherwise, look again: a test that passes without exercising the behavior does not prove the AC. Treat a disagreement you cannot settle as a gap, or ask the user. Report its other blocking findings to the user.

Then go to step 2d.

## 2d. Feature: report and ask

Verify judges; it does not fix. Apart from the Evidence table, it changes nothing but `verify-report.md` and the spec's status and changelog: no tasks, no plan edits, no spec edits. `/jsdd:specify` makes the spec changes, and `/jsdd:plan` turns the gaps into tasks.

Write `verify-report.md` in the spec folder from `${CLAUDE_PLUGIN_ROOT}/templates/verify-report.md`. On a later round, overwrite the round's sections, bump the Round, and add a History row. Fill it from your checks and the reviewer's: the AC results, the R verdicts, unrequested behavior, plan drift, and one **proposed action** per gap, numbered G1, G2, … For a failed AC or an R that is not delivered, the action is usually a fix with a check. For unrequested behavior or drift, offer the other fixes too: change the spec to match the code (Article 4), record a Deviation, or move it to BACKLOG.md. When more than one fix is sensible, list them as options (a, b, …) on the gap: the user picks one, and `/jsdd:plan` never picks for them.

**Two rounds, then the spec.** A gap on the same AC or R as a gap in the previous round, whose planned fix is now built (its tasks ticked), is a repeated gap: two rounds of fixes have not closed it, so the spec or its check is likely wrong rather than the code. Say so on the gap, and offer only (a) change the spec, or (b) drop the gap. Do not propose another code fix.

- **Converged** (every AC passes, every R is `delivered`, no unrequested behavior, no unrecorded drift): set Outcome `converged` and Decision `none needed`, and go to step 3.
- **Gaps found:** show the user the report and ask whether to plan the fixes (gate `verify.gaps`), and for each gap with options, which one (gate `verify.gap_option`). They can approve, change or drop actions, or stop. Record each answer on its gap in the report: `Chosen: b (<by whom>)` or `(dropped by <who>)`.
  - **Never record a decision the user did not give.** Do not assume an answer, pick an option, or approve on the user's behalf. In `autopilot` and `autonomous` mode, the Autopilot and autonomous rules decide instead, recorded as `auto:`, never as the user's. If you cannot get an answer (for example, in a run nobody is watching), leave Decision `pending` and the status `in-progress`, release the spec, and report that the report waits for the user; running `/jsdd:verify <ID>` again asks again.
  - **Approved:** every gap has an answer (a chosen option where it had options, or dropped). Set Decision `approved (<by whom, date>)`.
    - If no kept gap is a spec change, set `status: approved` and add a changelog line: "Verification round <n> found gaps; fixes approved, see verify-report.md." Release the spec, run `jsdd status --write`, and suggest `/jsdd:plan <ID>`, which plans the fixes as an amendment.
    - If any kept gap is a spec change (gate `spec.change`), the requirements are open again: set `status: draft` and add a changelog line: "Verification round <n> found gaps; spec changes approved (G<n>, …), see verify-report.md." Release the spec, run `jsdd status --write`, and suggest `/jsdd:specify <ID>` to revise the spec, then `/jsdd:plan <ID>`, which plans the rest as an amendment.
  - **Stop:** set Decision `declined (<by whom, date>)`. Set `status: blocked` and add a changelog line: "Blocked: verification round <n> found gaps; see verify-report.md." Release the spec and run `jsdd status --write`. Tell the user that the spec stays blocked until it is concluded: `/jsdd:plan <ID>` resumes it by planning the fixes (running it is the approval; a spec change it sends to `/jsdd:specify` first), or they can drop the spec (`status: dropped`, with the reason in its changelog).

## 2b. Spike: check the answers

- Every goal question has findings labelled as decisions, facts with sources, or assumptions. Remaining assumptions are either confirmed by the user or listed as Follow-ups.
- The Inbox is empty, the Log covers every answer, the Recommendation table is filled in and agreed, and Follow-ups are listed.
- Each BACKLOG.md item the spike settles is updated in place: ticked, with the choice and a link to the spike.
- Each decision the spike settled is in `docs/decisions.md` as a `DEC-nn` row (moved from its ND row), with the same reasoning.
- Each Follow-up exists as a new spec, a BACKLOG.md item, or an agreed decision to drop it. Ask the user which before creating new specs.

## 2c. Baseline: check current behavior

A baseline proves that the code does what it says today. Nothing is built, so a failure means the description is wrong, not the code.

- Launch the `sdd-reviewer` agent in `baseline` mode with the spec folder. While it runs, do the checks below yourself.
- Tick each acceptance criterion only with `jsdd done <ID> AC-n`, which runs its check from the repository root and ticks it only when the check passes. For `check: manual: …`, do or ask for the check (gate `task.manual_check`) and run `jsdd done <ID> AC-n --manual "<who checked what>"`.
- Fill one row of the spec's Evidence table per AC: pass or fail, and the test name or command output, or who checked what.
- When a check fails, find out why with the user. If the code behaves differently from the description, rewrite the R and AC to match the code (a baseline records what is, not what should be) and record the gap under Findings with where it went. If the test itself is broken or flaky, use a manual check instead and add a BACKLOG.md "Next" item to fix the test. Never close a baseline with an AC that is not ticked.
- Also confirm: every R is covered by an AC, every requirement ID in `refs` is tagged on an R and has no entry in its capability document yet (one that has an entry means the entry and the code disagree: settle it with the user and record it under Findings), and every Finding says where it went.
- Compare with the reviewer's report. Where it says a test does not exercise the behavior its AC claims, or an R misdescribes the code, fix the spec, or treat the disagreement as a failure and ask the user.

## 3. Close

- Tick the spike's Deliverables.
- Check `docs/decisions.md`: each decision the spike or spec settled is a `DEC-nn` row under Decided; move or add it if not.
- Tick the PLAN.md checkbox(es) for the items in the spec's `refs` that are now complete: an item is complete when `jsdd coverage` shows every Must it names as done. Update BACKLOG.md items it settles, if not done already.
- **Merge the capability changes** (features and baselines; a spike has none). For each line of the spec's Capability changes table (for a baseline, which has no table, each row in `refs` as `adds`), open the group's capability document: `docs/capabilities/<group>.md`, the group in lower case without the `FR-` prefix (`FR-AUTH` → `auth.md`, `NFR-PERF` → `nfr-perf.md`). If it does not exist, create it from `${CLAUDE_PLUGIN_ROOT}/templates/capability.md`, with the area's heading from `docs/requirements.md`, and delete the template's example entry and History row.
  - `adds` or `modifies`: write the row's entry, `## <row ID> · <row text>`, in ID order. It holds the behavior as it is now, in EARS form: the spec's Rs tagged with the row (without their R numbers), plus the statements of the old entry that the spec does not change. Under **Proven by**, name the ACs' checks from the Evidence table. Set `Last changed: <ID> (<date>)`.
  - `removes`: delete the row's entry.
  - **Older baselines first.** Before the spec's own lines, run `jsdd capabilities <groups>`. A done baseline it lists as not merged (one closed before the kit had capability documents) is how the area worked before this spec: merge its rows first, as `adds` with its ID and the date it closed, so this spec's lines apply on top of them.
  - Add one History row per line: date, spec ID, row, change.
  - **Changed since?** If the entry was last changed by another spec after this one was approved (its `Last changed` date is later than this spec's approval line in the changelog), it may hold behavior this spec never saw. Show the user the entry and this spec's Rs, and merge what they agree; never drop a statement without asking (gate `verify.capability_merge`).
- Set `status: done` and `updated` in the spec, and add a changelog line.
- Run `jsdd capabilities --check <groups>` for the groups merged. It fails when a done spec's line is not in its document's History, or a document has an entry with no row; fix the document before going on.
- Release the spec and clear its leftover claims: `jsdd release <ID>`, then `jsdd claims --prune`. Run `jsdd status --write`.
- Report briefly: the result per AC (or per question), the PLAN and BACKLOG items updated, the capability documents updated (rows added, modified, removed), the requirement IDs now done (`jsdd coverage <IDs>`), and what `jsdd next` now shows.
