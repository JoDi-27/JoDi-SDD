# Specs: how work gets done here

A lightweight spec-driven development (SDD) kit. Every piece of work, spike or feature, starts as a spec in this folder, moves through a few reviewed steps, and is tracked here until it is done. The kit is a Claude Code plugin (`jsdd`): plain Markdown, one shell script, seven skills, two subagents, and four hooks.

## Where things live

| Level | File | Answers |
| --- | --- | --- |
| Product intent | `docs/intent.md` | What we are building and why, long term |
| Requirements | `docs/requirements.md` | Every functional and non-functional requirement of the product, with IDs (`FR-AUTH-05`, `NFR-SEC-03`) and priorities |
| Decisions | `docs/decisions.md` | The register: settled choices (`DEC-nn`) and open ones (`ND-nn`), with options and reasoning |
| Roadmap | `PLAN.md`, `BACKLOG.md` | Which phase we are in, which requirements each phase delivers, which spikes are open, and a one-line item per open decision that points to its row in `docs/decisions.md` |
| Rules | `specs/constitution.md` | What every design must respect |
| Work items | `specs/NNN-slug/` | What one slice of work does, how, and how far along it is |
| Progress | `specs/STATUS.md` | Generated board of every spec |

A spec usually delivers one checklist item of `PLAN.md` (a spike, a foundations item, a Phase 1 deliverable). If an item is too big for a few days of work, split it into several specs that depend on each other.

## Requirements and specs

`docs/requirements.md` is the product-level list of what the product must do; a spec is one slice of it made testable. They link by ID, and nothing is copied:

- Each PLAN.md item ends with the requirements it covers after a `·`: a group (`FR-SES`, every row in it) or single IDs.
- A spec's `refs` list the requirement IDs it covers, and each of its requirements is tagged with the rows it refines: `**R1** (FR-AUTH-05) When …`. Its acceptance criteria make those rows testable.
- `requirements.md` stays the source of truth. When a spec changes what a row means, or finds behavior no row has, it edits or adds the row in the same change. It never gets a status column: progress comes from the specs.
- Measurable NFRs (response times, delivery windows) become acceptance criteria in the spec that delivers them. NFRs that apply to everything are product articles in `specs/constitution.md`, checked in every plan.
- `jsdd coverage` joins the two: each requirement, its priority, and the specs that cover it with their status. A requirement is done once a `done` spec covers it.

```mermaid
flowchart LR
  req["docs/requirements.md<br/>FR-AUTH-05"] -->|"PLAN item · FR-AUTH"| plan[PLAN.md]
  plan --> spec["spec.md<br/>refs: FR-AUTH-05<br/>R1 (FR-AUTH-05) → AC-1"]
  spec --> tasks["tasks.md<br/>T3 → AC-1"] --> ev["Evidence: AC-1 pass"]
  ev -.->|"jsdd coverage"| req
```

## Lifecycle

Features and spikes take different routes. A feature is specified, planned, and built. A spike is an interview: an agent prepares the questions, you answer and add information over as many sessions as it takes, and it ends with agreed decisions.

### Features

```mermaid
flowchart LR
  draft -->|"/jsdd:plan<br/>(approves spec)"| approved --> planned
  planned -->|"/jsdd:implement<br/>(approves plan)"| inprogress[in-progress]
  inprogress -->|"/jsdd:verify<br/>(all AC pass)"| done
  inprogress -.->|AC fails: new tasks| inprogress
```

| Status | Meaning | Set by |
| --- | --- | --- |
| `draft` | Spec written, may still have open questions | `/jsdd:specify` |
| `approved` | Spec reviewed; no open questions | `/jsdd:plan` (running it is the approval) |
| `planned` | Plan and tasks written | `/jsdd:plan` |
| `in-progress` | Tasks being done | `/jsdd:implement` (running it is the approval of the plan) |
| `done` | Every acceptance criterion verified with evidence | `/jsdd:verify` |
| `blocked` | Cannot continue; the reason is in the spec's changelog | anyone |
| `dropped` | Will not be done; the reason is in the spec's changelog | anyone |

Each step stops for human review before the next one starts. The human gates are simply running the next command.

### Spikes

```mermaid
flowchart LR
  start(["/jsdd:spike topic"]) --> prep[spike-researcher:<br/>briefing + questions]
  prep --> ask[Ask 3-4 questions]
  ask --> takein[Record answers and notes:<br/>Log, Findings]
  takein -->|"goal questions open"| ask
  takein -->|"all answered"| rec[Recommendation<br/>agreed with you]
  rec -->|/jsdd:verify| done
```

Spikes go `draft → in-progress → done`, with no plan step.

1. `/jsdd:spike <topic>` (or a spec ID) creates the spike from its `BACKLOG.md` "Spikes" entry, with one **goal question** per question there.
2. The `spike-researcher` agent reads the repository and current docs and writes a **briefing** (what is known, what is only suggested, and what is unknown, with sources). It looks up the facts it can and drafts **questions for you**, only about what you know or decide, each with why it matters, options, and a suggested answer.
3. Claude asks the questions a few at a time. Every answer goes into the **Log** and the **Findings** of the goal questions it affects, labelled as a decision, a fact, or an assumption. Answers that raise new questions get researched or added to the queue.
4. You can add information at any time: in chat during a session, as `/jsdd:spike <ID> <notes>`, or by writing in the spike's **Inbox** section between sessions. The next session processes the Inbox and clears it.
5. When every goal question is answered, Claude drafts the recommendation and decisions for your agreement. `/jsdd:verify <ID>` then closes the spike and updates `BACKLOG.md` and `PLAN.md`.

## Working in parallel

Several Claude Code sessions can work at once, in one checkout or in separate worktrees. Each session claims its work before starting it, so two sessions never pick the same thing:

- `/jsdd:implement` claims one task at a time with `jsdd claim <ID> next`. That hands out the first task that is not ticked, not claimed, and whose earlier tasks are finished. Consecutive `[P]` tasks can be handed out together, so they are where parallel work within one spec comes from. An explicit `jsdd claim <ID> <Tn>` follows the same order and is refused while earlier tasks are unfinished.
- `/jsdd:specify`, `/jsdd:plan`, `/jsdd:spike`, and `/jsdd:verify` claim the whole spec. A spike stays claimed while its interview runs; a second session only adds notes to its Inbox.
- `jsdd next` skips work other sessions hold and shows which tasks are free. `jsdd status` lists the claims.

A claim is a directory created with `mkdir`, which is atomic, under `.git/sdd-claims/`. Every worktree on this machine shares it, and git does not track it. The owner is the Claude Code session ID. `jsdd done` marks a finished task done, and it stays marked until `jsdd claims --prune` sees its tick, because other worktrees do not see the tick until it is merged. `jsdd new` also reserves the spec ID there, so two worktrees never create the same number; prune drops the reservation only once the spec is on `main`. Prune never drops a claim whose spec folder is missing in this worktree, because that spec may live on another worktree's branch.

A session that ends without releasing leaves its claim behind. Claims older than 8 hours (`SDD_STALE_HOURS`) are shown as stale; free one with `jsdd release <ID> [Tn] --force` once you know that session is gone. Claims only coordinate sessions on one machine.

## Automation

Claude Code hooks keep the kit honest: they print the board and the claims at session start, regenerate `specs/STATUS.md` when a spec, task list, `PLAN.md`, or `docs/requirements.md` changes, block commit messages without a spec ID or `[meta]`, and warn at the end of a session that still holds claims. The hooks, skills, agents, and the `jsdd` script live in the plugin, not in this repository; the hooks do nothing in a project without `specs/constitution.md`.

## Artifacts

| File | Feature | Spike | Content |
| --- | --- | --- | --- |
| `spec.md` | yes | yes (spike template) | What and why: scenarios, EARS requirements, acceptance criteria. For a spike: inbox, goal questions, briefing, questions for you, log, findings, decisions |
| `plan.md` | yes | no | How: design, decisions, constitution check, test strategy, deviations |
| `tasks.md` | yes | no | Ordered, small, checkable tasks, plus verification evidence |
| `prototype/` | no | yes | Throwaway code for a spike, never shipped |

Templates are in the plugin's `templates/` folder. Frontmatter in `spec.md` is what the tooling reads:

```yaml
id: 003                # matches the folder number
type: feature          # feature | spike
status: draft          # see Lifecycle
phase: 1               # PLAN.md phase
depends_on: [001, 002] # specs that must be done first
refs: ["PLAN Phase 1 / Core", "FR-AUTH-05", "FR-AUTH-09"]  # PLAN and BACKLOG items, and requirement IDs
updated: 2026-10-07
```

## Commands

In Claude Code:

| Command | Does |
| --- | --- |
| `/jsdd:spike <ID, PLAN spike number, or topic> [notes]` | Runs a spike as an interview; with notes, records them first |
| `/jsdd:specify <idea, PLAN item, or spec ID>` | Creates a feature spec (or refines an existing one) and asks the questions that block it |
| `/jsdd:plan <ID>` | Approves the spec, then writes `plan.md` and `tasks.md` |
| `/jsdd:implement <ID> [task]` | Works through the tasks in order, ticking each when its check passes |
| `/jsdd:verify <ID>` | Checks every acceptance criterion (or a spike's answers), records evidence, closes the spec, updates PLAN and BACKLOG |
| `/jsdd:status [ID]` | Shows the board and what to do next |
| `/jsdd:init [--migrate] [notes]` | Sets up a project (starters, settings, `.gitignore`), then interviews you to fill the starters; or moves it off the old install.sh copy |

From a shell. In Claude Code the plugin puts `jsdd` on the Bash tool's PATH; in your own terminal, use its path in the plugin's `bin/` folder:

```sh
jsdd new feature "User invites"      # or: new spike "..."
jsdd status                          # board + next up
jsdd status --write                  # also regenerates specs/STATUS.md
jsdd next                            # only what can be worked on now
jsdd claim 003 next                  # claim the next free task of 003; prints its ID
jsdd done 003 T4                     # run T4's check; only if it passes, tick T4 and mark it done
jsdd claims --prune                  # list claims, dropping the ones no longer needed
jsdd coverage FR-AUTH                # requirements in a group, with the specs covering each
jsdd coverage --phase 1 --priority M --missing   # Phase 1 Musts with no spec yet
```

Progress is computed from the files: checkboxes in `tasks.md` (for a spike, the goal questions, questions for you, and deliverables in `spec.md`), and the open questions count from the `[NEEDS CLARIFICATION: …]` markers in `spec.md` and `plan.md`. HTML comments are ignored, so template guidance never counts.

## Good practices this kit enforces

- **What before how.** `spec.md` has no technology in it; `plan.md` has no new requirements in it.
- **No guessing.** Unknowns are written as `[NEEDS CLARIFICATION: …]` and must be resolved before planning.
- **Testable requirements.** Requirements use EARS ("When …, the system shall …"). Every requirement is covered by an acceptance criterion, and every acceptance criterion by a test or a recorded manual check.
- **Traceability.** IDs link everything: FR-AUTH-05 → R1 → AC-1 → T3 → commit `[003] T3 …` → evidence row.
- **Small tasks.** Half a day at most, each leaving the build green, test first where it fits.
- **Checks that run.** Each task's check is a command in backticks, and `jsdd done` ticks the task only when that command exits 0. A check no command can prove is written `check: manual: …`, and `jsdd done --manual "<who checked what>"` records the note on the task.
- **Fresh-eyes review.** `/jsdd:plan` and `/jsdd:verify` ask the `sdd-reviewer` agent, which never saw the session that wrote the work, for a second opinion on the plan and on each acceptance criterion.
- **Living documents.** When reality disagrees with the spec or plan, the document changes first and the change is logged (spec changelog, plan Deviations).
- **Decisions on record.** Every real choice gets a row with alternatives and rationale. A choice that settles an open decision moves its row in `docs/decisions.md` from Still open to Decided, and ticks the BACKLOG item.
- **Constitution check.** Every plan states how it respects the articles it touches.
