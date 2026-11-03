---
name: status
description: Show the progress board of specs in specs/ and what to work on next, or the detailed state of one spec. Use when asked about progress, status, or what to do next.
argument-hint: [spec ID]
---

# Status

Arguments: $ARGUMENTS

## Without an ID

- Run `jsdd status --write` and show the board.
- Summarize in a few lines: what is in progress, what is next and the command for it (from "Next up"), what other sessions hold (from "Claims", pointing out stale ones and that `jsdd release <ID> [Tn] --force` frees them), what is blocked or waiting (a spec blocked by a declined verification resumes with `/jsdd:plan <ID>`), and specs with open questions.
- Relate it to the roadmap: which PLAN.md phase is current, and which of its items have no spec yet. Suggest the command for the next one in PLAN.md order: `/jsdd:spike` for a spike, `/jsdd:baseline <area>` for a baseline, `/jsdd:specify` otherwise.
- Requirement coverage for the current phase: run `jsdd coverage --phase <N> --priority M` and give one line, Musts with a spec and done out of the total, plus the uncovered Musts grouped by PLAN.md item (`--missing`).

## With an ID

Read the spec folder and report: status, the requirement IDs in its `refs`, open questions, tasks done and left (with the next free task and the tasks other sessions hold, from `jsdd claims`), plan deviations, failing or missing evidence, and the next command to run.

Do not change any spec files, except regenerating `specs/STATUS.md`.
