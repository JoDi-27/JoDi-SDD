<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/banner-dark.svg">
  <img src=".github/assets/banner-light.svg" alt="JoDi-SDD: Spec-driven development for Claude Code, as a plugin." width="100%">
</picture>

[![CI](https://github.com/JoDi-27/JoDi-SDD/actions/workflows/ci.yml/badge.svg)](https://github.com/JoDi-27/JoDi-SDD/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/JoDi-27/JoDi-SDD)](https://github.com/JoDi-27/JoDi-SDD/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

# JoDi-SDD

Spec-driven development for [Claude Code](https://claude.com/claude-code), as a plugin.

Claude Code is fast, but on bigger features it drifts: it forgets what was decided, says work is done when it isn't, and loses track between sessions. JoDi-SDD turns each piece of work into a written spec that you approve one step at a time (specify → plan → implement → verify), with checks Claude can't skip and a board that tells you and Claude what to do next.

```
Next up:
  001  in-progress Password reset by email   /jsdd:implement 001   (T3 free)
  003  draft       Which email provider      /jsdd:spike 003
  002  waiting on 001

Requirement coverage:
  Must                  2   with a spec   1   done   0
  Should                1   with a spec   1   done   0
```

> Early release (0.x). The workflow is stable, but names and file formats may still change. Feedback and issues are welcome.

## What you get

- **You approve every step.** Each step ends with a review. Nothing moves forward until you run the next command.
- **Tasks are done when their check passes.** Every task has a check command, such as a test. `jsdd done` ticks the task only when that command succeeds, so Claude can't finish work by ticking a checkbox.
- **Reviews in a fresh context.** A reviewer agent that never saw the session that wrote the work checks each plan, and gives a verdict on each acceptance criterion before a spec is closed.
- **Parallel sessions that don't collide.** A session claims a spec or task before it starts. Claims are shared across git worktrees, so several Claude sessions can work on one project without picking up the same work.
- **Open questions get researched before you're asked.** A *spike* is a spec for answering a question rather than building something. A research agent writes a briefing with sources and asks you only what it can't look up. Your answers and the decisions they lead to stay in the project.
- **Existing codebases.** On a project with code, each area is recorded just before work first changes it, as a *baseline* checked by the tests you already have. There's no up-front inventory. See [Existing codebases](#existing-codebases).
- **Traceability.** Each requirement in `docs/requirements.md` has an ID (`FR-AUTH-02`). Specs cite those IDs, tasks cite the spec's acceptance criteria, and commits cite the task. `jsdd coverage` shows which requirements have a spec and which are done.

Everything is plain Markdown in your repository, driven by one bash script. There's no build step and no service.

## Requirements

- Claude Code with plugin support
- `bash`, `awk`, `jq`, and `python3` (already installed on most macOS and Linux machines)
- On Windows: [Git for Windows](https://gitforwindows.org) (Claude Code runs the hooks and `jsdd` in its Git Bash), plus jq and Python: `winget install jqlang.jq Python.Python.3.12`. Without them, the commit-message check and `STATUS.md` regeneration are skipped, and the session-start board says so.
- A git repository is recommended. Sharing claims across worktrees and checking commit messages both need one.

## Install

In the project where you want it:

```sh
claude plugin marketplace add JoDi-27/jodi-sdd --scope project
claude plugin install jsdd@jodi-sdd --scope project
```

Project scope records the plugin in the project's `.claude/settings.json`, so teammates who clone the project are offered it too. Use `--scope user` to install it for all your projects instead. The plugin stays inactive in any project that hasn't run `/jsdd:init`.

## Update and uninstall

To update to the latest release:

```sh
claude plugin update jsdd@jodi-sdd
```

Then start a new session, and run `/jsdd:init` again to pick up any changes to `specs/README.md`. It leaves your other files as they are. [CHANGELOG.md](CHANGELOG.md) lists what changed in each release, including behavior changes.

To uninstall, use the scope you installed with (the default is `user`):

```sh
claude plugin uninstall jsdd@jodi-sdd --scope project
```

Your specs, docs, `PLAN.md`, and `BACKLOG.md` stay in the repository as plain Markdown. Delete them yourself if you no longer want them. Claims are kept in `.git/sdd-claims` (or `specs/.claims` outside git); you can delete that too.

## Quick start

In a Claude Code session in your project:

1. Run `/jsdd:init` to set up the project (see [what it adds](#what-jsddinit-adds)). It then interviews you to fill in the intent, constitution, requirements, decisions, and plan, including your test command. Add notes about the product after the command to pre-fill answers.
2. Start a new session so the hooks pick up the project.
3. `/jsdd:status` shows the board and what to do next.
4. `/jsdd:specify <idea>` writes a spec and asks you the questions that block it.
5. `/jsdd:plan <ID>` approves the spec and writes the plan and tasks, which the reviewer agent checks.
6. `/jsdd:implement <ID>` works through the tasks, ticking each one when its check passes.
7. `/jsdd:verify <ID>` checks every acceptance criterion against evidence and closes the spec.

For an open question rather than a feature, run `/jsdd:spike <topic>` instead of steps 4 to 7.

## Existing codebases

The kit works on a project that already has code. It doesn't ask you to document the whole codebase up front. Instead, it records how an area works today just before new work first changes it:

1. `/jsdd:init` notices the existing code. It surveys the codebase for its areas, test command, and conventions, and plans the next milestone rather than an MVP. If the project already has its own `PLAN.md` or `docs/requirements.md`, init offers to move it to `docs/legacy/` and carry its content into the kit's format. It never overwrites a file.
2. Before a feature changes an area that has no requirements yet, `/jsdd:baseline <area>` reads that area's code and tests and drafts what it does today. You confirm which behavior is intended. Those become requirement rows and a *baseline spec*, whose acceptance criteria are the existing tests.
3. `/jsdd:verify` runs those tests. When they pass, the baseline is done and its requirements count as done, without anything being rebuilt.
4. The feature spec then cites the rows it changes. Coverage shows them in progress again until the feature is verified.

Areas no work touches stay unrecorded. `/jsdd:specify` suggests a baseline when a feature reaches existing code that has none.

The full workflow, including spec statuses, IDs, and the commit-message format, is in [starters/specs/README.md](starters/specs/README.md). `/jsdd:init` copies it into your project as `specs/README.md`.

## Commands

| Command | What it does |
| --- | --- |
| `/jsdd:init [notes]` | Sets up the project, then interviews you to fill in its starter files |
| `/jsdd:status [ID]` | Shows the board, what to do next, and requirement coverage |
| `/jsdd:specify <idea, PLAN item, or ID>` | Creates or refines a feature spec |
| `/jsdd:spike <topic or ID> [notes]` | Runs a spike: research first, then questions for you |
| `/jsdd:plan <ID>` | Approves the spec, then writes the plan and tasks |
| `/jsdd:implement <ID> [task]` | Works through the tasks |
| `/jsdd:baseline <area or ID>` | Records how an area of existing code works today, checked by its existing tests |
| `/jsdd:verify <ID>` | Checks the acceptance criteria (or a spike's answers) and closes the spec |

Under the hood, these commands use the `jsdd` CLI, which the plugin adds to the PATH for Claude's Bash tool. Run `jsdd help` for its subcommands.

## What `/jsdd:init` adds

| Path | Contents |
| --- | --- |
| `docs/intent.md` | What you are building and why |
| `docs/requirements.md` | Requirements with IDs (`FR-`, `NFR-`) and priorities |
| `docs/decisions.md` | Settled decisions (`DEC-nn`) and open ones (`ND-nn`) |
| `PLAN.md` | Phases, each item tagged with the requirements it covers |
| `BACKLOG.md` | One line per open decision with a suggested default, and spikes with their questions |
| `specs/constitution.md` | Rules every plan is checked against, plus your project's test command and architecture rules |
| `specs/README.md` | How the workflow runs |

These are your files. Running `/jsdd:init` again only updates `specs/README.md`, when a new plugin version changes it, and never overwrites the others.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how the plugin is laid out, how to test changes locally, and how to add a new command. Report security issues privately, as described in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
