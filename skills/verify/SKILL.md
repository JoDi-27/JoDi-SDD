---
name: verify
description: Verify a spec's acceptance criteria (or a spike's answers) with evidence, then close it and update PLAN.md and BACKLOG.md. Use when all of a spec's tasks are ticked, or when a baseline spec's current behavior is confirmed.
argument-hint: <spec ID>
---

# Verify

Spec: $ARGUMENTS

You prove that the spec is met. You do not add features.

## 1. Gate

- Open `specs/$ARGUMENTS-*/`. The status must be `in-progress`.
- Claim the spec: `jsdd claim <ID>`. If another session holds the spec or one of its tasks, stop and report who.
- Every task must be ticked; for a spike, every goal question and question for the user, and the first deliverable (recommendation agreed). If not, list what is left and suggest `/jsdd:implement <ID>` (features) or `/jsdd:spike <ID>` (spikes).
- A baseline (`type: baseline`) has no tasks: it is ready when its status is `in-progress` and it has no `[NEEDS CLARIFICATION` markers. If it is still `draft`, suggest `/jsdd:baseline <ID>`. Go to step 2c.

## 2a. Feature: check every acceptance criterion

- Launch the `sdd-reviewer` agent in `verify` mode with the spec folder and the git range of the work: from the project's main branch (`$SDD_MAIN_BRANCH` if set, else `main`) to HEAD. When the work was committed directly on that branch, name the commits instead (for example the `[<ID>]` commits from `git log --oneline --grep '^\[<ID>\]'`). While it runs, do the checks below yourself.
- For each AC in `spec.md`, run its verification from the plan's test strategy: the named tests, commands, or a manual check.
- For a manual check that needs the user (for example, a UI flow), ask them to do it and record what they report.
- Fill one row of the Evidence table in `tasks.md` per AC: pass or fail, and concrete evidence (test name, command and its relevant output, or who checked what).
- Also confirm: the full build and test suite pass, every requirement is covered by a passing AC, every requirement ID in the spec's `refs` is tagged on an R whose ACs pass, and the plan's Deviations reflect what was built. An ID in `refs` that the work only partly delivers is either split into a new row of `docs/requirements.md` (and the delivered part kept in `refs`) or removed from `refs`, with the user's agreement.
- Compare with the reviewer's report. Where it says an AC is failed or unproven and you found it passing, look again: a test that passes without exercising the behavior does not prove the AC. Treat a disagreement you cannot settle as a failure, or ask the user. Report its other blocking findings to the user.

If any AC fails, do not close the spec. Add a fix task for each failure to `tasks.md`, keep `in-progress`, release the spec, report the failures, and suggest `/jsdd:implement <ID>`.

## 2b. Spike: check the answers

- Every goal question has findings labelled as decisions, facts with sources, or assumptions. Remaining assumptions are either confirmed by the user or listed as Follow-ups.
- The Inbox is empty, the Log covers every answer, the Recommendation table is filled in and agreed, and Follow-ups are listed.
- Each BACKLOG.md item the spike settles is updated in place: ticked, with the choice and a link to the spike.
- Each decision the spike settled is in `docs/decisions.md` as a `DEC-nn` row (moved from its ND row), with the same reasoning.
- Each Follow-up exists as a new spec, a BACKLOG.md item, or an agreed decision to drop it. Ask the user which before creating new specs.

## 2c. Baseline: check current behavior

A baseline proves that the code does what it says today. Nothing is built, so a failure means the description is wrong, not the code.

- Launch the `sdd-reviewer` agent in `baseline` mode with the spec folder. While it runs, do the checks below yourself.
- Tick each acceptance criterion only with `jsdd done <ID> AC-n`, which runs its check from the repository root and ticks it only when the check passes. For `check: manual: …`, do or ask for the check and run `jsdd done <ID> AC-n --manual "<who checked what>"`.
- Fill one row of the spec's Evidence table per AC: pass or fail, and the test name or command output, or who checked what.
- When a check fails, find out why with the user. If the code behaves differently from the description, rewrite the R and AC to match the code (a baseline records what is, not what should be) and record the gap under Findings with where it went. If the test itself is broken or flaky, use a manual check instead and add a BACKLOG.md "Next" item to fix the test. Never close a baseline with an AC that is not ticked.
- Also confirm: every R is covered by an AC, every requirement ID in `refs` is tagged on an R, and every Finding says where it went.
- Compare with the reviewer's report. Where it says a test does not exercise the behavior its AC claims, or an R misdescribes the code, fix the spec, or treat the disagreement as a failure and ask the user.

## 3. Close

- Tick the spike's Deliverables.
- Check `docs/decisions.md`: each decision the spike or spec settled is a `DEC-nn` row under Decided; move or add it if not.
- Tick the PLAN.md checkbox(es) for the items in the spec's `refs` that are now complete: an item is complete when `jsdd coverage` shows every Must it names as done. Update BACKLOG.md items it settles, if not done already.
- Set `status: done` and `updated` in the spec, and add a changelog line.
- Release the spec and clear its leftover claims: `jsdd release <ID>`, then `jsdd claims --prune`. Run `jsdd status --write`.
- Report briefly: the result per AC (or per question), the PLAN and BACKLOG items updated, the requirement IDs now done (`jsdd coverage <IDs>`), and what `jsdd next` now shows.
