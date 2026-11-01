<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/banner-dark.svg">
  <img src=".github/assets/banner-light.svg" alt="JoDi-SDD: Spec-driven development for Claude Code, as a plugin." width="100%">
</picture>

# JoDi-SDD

Spec-driven development for [Claude Code](https://claude.com/claude-code), as a plugin.

Claude Code is fast, but on bigger features it drifts: it forgets what was decided, says work is done when it isn't, and loses track between sessions. sdd-kit turns each piece of work into a written spec that you approve one step at a time (specify → plan → implement → verify), with checks Claude can't skip and a board that tells you and Claude what to do next.

```
Next up:
  001  in-progress Password reset by email   /sdd:implement 001   (T3 free)
  003  draft       Which email provider      /sdd:spike 003
  002  waiting on 001

Requirement coverage:
  Must                  2   with a spec   1   done   0
  Should                1   with a spec   1   done   0
```

> Early release (0.1). The workflow is stable, but names and file formats may still change. Feedback and issues are welcome.

## What you get

- **You approve every step.** Each step ends with a review. Nothing moves forward until you run the next command.
- **Tasks are done when their check passes.** Every task has a check command, such as a test. `sdd done` ticks the task only when that command succeeds, so Claude can't finish work by ticking a checkbox.
- **Reviews in a fresh context.** A reviewer agent that never saw the session that wrote the work checks each plan, and gives a verdict on each acceptance criterion before a spec is closed.
- **Parallel sessions that don't collide.** A session claims a spec or task before it starts. Claims are shared across git worktrees, so several Claude sessions can work on one project without picking up the same work.
- **Open questions get researched before you're asked.** A *spike* is a spec for answering a question rather than building something. A research agent writes a briefing with sources and asks you only what it can't look up. Your answers and the decisions they lead to stay in the project.
- **Traceability.** Each requirement in `docs/requirements.md` has an ID (`FR-AUTH-02`). Specs cite those IDs, tasks cite the spec's acceptance criteria, and commits cite the task. `sdd coverage` shows which requirements have a spec and which are done.

Everything is plain Markdown in your repository, driven by one bash script. There's no build step and no service.

## Requirements

- Claude Code with plugin support
- `bash`, `awk`, `jq`, and `python3` (already installed on most macOS and Linux machines)
- A git repository is recommended. Sharing claims across worktrees and checking commit messages both need one.

## Install

In the project where you want it:

```sh
claude plugin marketplace add JoDi-27/sdd-kit --scope project
claude plugin install sdd@sdd-kit --scope project
```

Project scope records the plugin in the project's `.claude/settings.json`, so teammates who clone the project are offered it too. Use `--scope user` to install it for all your projects instead. The plugin stays inactive in any project that hasn't run `/sdd:init`.

## Quick start

In a Claude Code session in your project:

1. Run `/sdd:init` to set up the project (see [what it adds](#what-sddinit-adds)), then start a new session so the hooks pick it up.
2. Fill in `docs/intent.md`, `docs/requirements.md`, and the phases in `PLAN.md`. Claude can draft these with you. Set your test command under "Project specifics" in `specs/constitution.md`.
3. `/sdd:status` shows the board and what to do next.
4. `/sdd:specify <idea>` writes a spec and asks you the questions that block it.
5. `/sdd:plan <ID>` approves the spec and writes the plan and tasks, which the reviewer agent checks.
6. `/sdd:implement <ID>` works through the tasks, ticking each one when its check passes.
7. `/sdd:verify <ID>` checks every acceptance criterion against evidence and closes the spec.

For an open question rather than a feature, run `/sdd:spike <topic>` instead of steps 4 to 7.

The full workflow, including spec statuses, IDs, and the commit-message format, is in [starters/specs/README.md](starters/specs/README.md). `/sdd:init` copies it into your project as `specs/README.md`.

## Commands

| Command | What it does |
| --- | --- |
| `/sdd:init` | Sets up the project |
| `/sdd:status [ID]` | Shows the board, what to do next, and requirement coverage |
| `/sdd:specify <idea, PLAN item, or ID>` | Creates or refines a feature spec |
| `/sdd:spike <topic or ID> [notes]` | Runs a spike: research first, then questions for you |
| `/sdd:plan <ID>` | Approves the spec, then writes the plan and tasks |
| `/sdd:implement <ID> [task]` | Works through the tasks |
| `/sdd:verify <ID>` | Checks the acceptance criteria (or a spike's answers) and closes the spec |

Under the hood, these commands use the `sdd` CLI, which the plugin adds to the PATH for Claude's Bash tool. Run `sdd help` for its subcommands.

## What `/sdd:init` adds

| Path | Contents |
| --- | --- |
| `docs/intent.md` | What you are building and why |
| `docs/requirements.md` | Requirements with IDs (`FR-`, `NFR-`) and priorities |
| `docs/decisions.md` | Settled decisions (`DEC-nn`) and open ones (`ND-nn`) |
| `PLAN.md` | Phases, each item tagged with the requirements it covers |
| `BACKLOG.md` | Open decisions with suggested defaults, and spikes with their questions |
| `specs/constitution.md` | Rules every plan is checked against, plus your project's test command and architecture rules |
| `specs/README.md` | How the workflow runs |

These are your files. Running `/sdd:init` again only updates `specs/README.md`, when a new plugin version changes it, and never overwrites the others.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how the plugin is laid out, how to test changes locally, and how to add a new command.

## License

[MIT](LICENSE)
