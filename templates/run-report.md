# {{ID}} · Run report: {{TITLE}}

<!--
Written by /jsdd:auto (autopilot or autonomous), one per run (a later run on the same spec adds a "## Run 2" section with the same parts).
Everything here was done without a person. Read "Decisions made without a person" and "Parked" first.
-->

**Mode:** autopilot | autonomous, preset <preset>, loop <specs/runs/…> · **Started by:** <person, by running /jsdd:auto> · **Branch:** <branch>
**Started:** {{DATE}} <time> · **Ended:** <date time>
**Outcome:** pull request ready | merged (auto: merge, CI green) | draft pull request: parked at <gate> | draft pull request: wall-time budget spent

## Timeline

<!-- One line per phase: the plan and its reviewer rounds, each task with its attempts, each verification round and its outcome. -->

## Decisions made without a person

<!--
One line each: what was decided, the gate, and what passed it. For example:
- Spec approved by <person>, by starting the run (spec.approve); in autonomous mode: no blocking findings in sdd-reviewer spec mode round 1 (auto: spec.approve)
- Plan approved: no blocking findings in sdd-reviewer round 2 (auto: plan.approve)
- T4's check changed from `…` to `…`: Deviation 2, accepted by sdd-reviewer (auto: implement.stuck)
- G2 option (a), fix the code: the reviewer's recommendation (auto: verify.gap_option)
-->

## Assumptions

<!-- Autonomous mode: each open question answered with a default (auto: spec.clarify), the answer, and where it came from (BACKLOG.md, the recommended answer in the spec). Or "None." -->

## Parked

<!-- The gate, and what a person must decide before `jsdd unpark {{ID}}` and `/jsdd:auto {{ID}}` again. Or "Nothing." -->

## For the reviewer

<!-- The two or three places a person should read first: decisions above, deviations, findings the reviewer raised that the run left. -->
