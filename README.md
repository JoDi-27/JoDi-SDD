# sdd-kit

Spec-driven development for Claude Code, as a plugin. Every piece of work starts as a spec in `specs/`, moves through steps you review (specify → plan → implement → verify), and links back to your product's requirements by ID. Open questions are run as spikes: interviews where Claude researches what it can and asks you only what it can't look up.

It is plain Markdown, one bash script, seven skills, two subagents, and four hooks. No build step, and no dependencies beyond `bash`, `awk`, `jq`, and `python3`.

## Why this one

- **Checks that have to pass.** Every task carries a check command, and `sdd done` ticks the task only when that command exits 0. Claude can't mark work finished by editing a checkbox.
- **Parallel sessions that don't collide.** Sessions claim a spec or a task before starting it. Claims are shared across git worktrees on the machine, so several Claude sessions can work on one project without picking the same work.
- **Traceability from requirement to evidence.** `FR-AUTH-05` → spec requirement `R1` → acceptance criterion `AC-1` → task `T3` → commit `[003] T3 …` → evidence row. `sdd coverage` shows which requirements have a spec and which are done.
- **Spikes as interviews.** A research agent writes a briefing with sources and drafts questions only you can answer. Your answers go into a log and findings that survive across sessions, until the spike ends in agreed decisions.
- **A second opinion with fresh context.** A reviewer agent that never saw the session that wrote the work checks each plan, and gives a verdict on each acceptance criterion at verify time.
- **Human gates.** Each step stops for your review. Running the next command is the approval.

## Install

In the project where you want it:

```sh
claude plugin marketplace add JoDi-27/sdd-kit --scope project
claude plugin install sdd@sdd-kit --scope project
```

Project scope writes the plugin into the project's `.claude/settings.json`, so it runs only there, and teammates who clone the project are offered it. Use `--scope user` to have it everywhere. Its hooks do nothing in a project that hasn't been set up with `/sdd:init`.

## Quick start

In a Claude Code session in the project:

1. `/sdd:init` copies the starter documents (intent, requirements, decisions, PLAN, BACKLOG, constitution) and allows the `sdd` script in the project's settings. Start a new session afterwards so the hooks pick up the project.
2. Fill in `docs/intent.md` and `docs/requirements.md`, then the phases in `PLAN.md`. Claude can draft these with you.
3. `/sdd:status` shows the board and what to do next.
4. `/sdd:specify <PLAN item or idea>` writes a spec and asks you the questions that block it.
5. `/sdd:plan <ID>` approves the spec and writes `plan.md` and `tasks.md`, reviewed by the reviewer agent.
6. `/sdd:implement <ID>` works through the tasks, ticking each one when its check passes.
7. `/sdd:verify <ID>` checks every acceptance criterion with evidence and closes the spec.

For open questions, use `/sdd:spike <topic>` instead of steps 4 to 7. The full workflow is in [starters/specs/README.md](starters/specs/README.md), which `/sdd:init` copies into the project as `specs/README.md`.

## Commands

| Command | Does |
| --- | --- |
| `/sdd:init [--migrate]` | Sets up the project |
| `/sdd:status [ID]` | The board, what to do next, and requirement coverage |
| `/sdd:specify <idea, PLAN item, or ID>` | Creates or refines a feature spec |
| `/sdd:spike <topic or ID> [notes]` | Runs a spike as an interview |
| `/sdd:plan <ID>` | Approves the spec, then writes the plan and tasks |
| `/sdd:implement <ID> [task]` | Works through the tasks |
| `/sdd:verify <ID>` | Verifies acceptance criteria (or a spike's answers) and closes the spec |

The skills drive the `sdd` script, which the plugin puts on the PATH of Claude's Bash tool: `sdd new`, `status`, `next`, `claim`, `release`, `done`, `claims`, `coverage`. Run `sdd help` for details.

## What `/sdd:init` adds to a project

| Path | What |
| --- | --- |
| `docs/intent.md` | What you are building and why |
| `docs/requirements.md` | `FR-`/`NFR-` rows with IDs and priorities |
| `docs/decisions.md` | Settled decisions (`DEC-nn`) and open ones (`ND-nn`) |
| `PLAN.md` | Phases, each item tagged with the requirement IDs it covers |
| `BACKLOG.md` | Open decisions with suggested defaults, spikes with their questions |
| `specs/constitution.md` | The rules every plan is checked against, plus Project specifics |
| `specs/README.md` | How the workflow runs (refreshed by `/sdd:init` when the plugin changes it) |

It never overwrites the other files once they exist: they are the project's.

## Per-project settings

The plugin files are the same in every project. What a project tunes goes in its `specs/constitution.md`, under "Project specifics": the test command that plans use in task checks, and the architecture rules the reviewer checks.

## Upgrading from the install.sh version

Before it was a plugin, this kit was copied into each project by `install.sh`, into `.claude/` and `specs/_kit/`. In such a project, install the plugin and run `/sdd:init --migrate`. It removes the old copy and takes the old hooks out of `.claude/settings.json`, keeping the project's own settings. It also moves tweaks such as the test command into the constitution.

## Developing

Try changes without installing: `claude --plugin-dir path/to/sdd-kit` in a test project. Check the manifests with `claude plugin validate .`. Bump `version` in `.claude-plugin/plugin.json` for a release; projects take it with `claude plugin update sdd@sdd-kit`.

| Path | What |
| --- | --- |
| `skills/<name>/SKILL.md` | One skill each, run as `/sdd:<name>` |
| `agents/` | `sdd-reviewer` and `spike-researcher` |
| `hooks/` | Session-start board, `STATUS.md` regeneration, commit-message check, unreleased-claims warning. Registered in `hooks/hooks.json` |
| `bin/sdd` | The CLI (bash 3.2 and awk). It works on the git checkout of the current directory, or `$SDD_ROOT` |
| `templates/` | `spec.md`, `spike.md`, `plan.md`, `tasks.md` |
| `starters/` | What `sdd init` copies into a project |
| `.claude-plugin/` | `plugin.json`, and `marketplace.json` that makes this repository its own marketplace |

To add a flow:

1. **Skill:** `skills/<flow>/SKILL.md` with `name`, `description` (when to use it; Claude reads it to decide), and `argument-hint` in the frontmatter. Write it as numbered steps, with a gate at the start (what must be true to begin) and a report at the end (what was done, and the next command). `skills/plan` shows the shape. `${CLAUDE_PLUGIN_ROOT}` in the body becomes the plugin's path.
2. **Agent** (optional, for a fresh-context or read-only helper): `agents/<name>.md` with `name`, `description`, `tools`, and a fixed output format the calling skill can use.
3. **Hook** (optional, for something that must happen every time): a script in `hooks/` whose line 2 is `# <Event> on <matcher>: <what it does>`, registered in `hooks/hooks.json`. Hooks read JSON on stdin, must work without git, and exit quietly in a project without `specs/constitution.md`.
4. **State** goes in files in the project, never only in the conversation. If the flow touches specs, it uses the `sdd` CLI rather than editing status or checkboxes by hand, and adds a subcommand when it needs one.
5. Document it in `starters/specs/README.md` and in the tables above.

## License

[MIT](LICENSE)
