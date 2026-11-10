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

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/demo-dark.svg">
  <img src=".github/assets/demo-light.svg" alt="A password-reset spec moving through /jsdd:specify, /jsdd:plan, /jsdd:implement and /jsdd:verify. A task whose check fails stays unticked until the check passes. Then /jsdd:status shows what to do next." width="100%">
</picture>

> Early release (0.x). The workflow is stable, but names and file formats may still change. Feedback and issues are welcome.

## What spec-driven development is

Instead of describing a feature in chat and hoping the agent remembers, you write down what it must do before any code exists: a short document with numbered requirements and the conditions that prove each one is met. That document is the *spec*. The agent plans from it, builds from it, and the result is checked against it. When reality disagrees with the spec, the spec changes first, so it stays the single place where the truth of a feature lives.

JoDi-SDD adds the part prompts can't guarantee: Claude cannot tick its own boxes. A task is done when its check command passes, a plan is reviewed by an agent that never saw the session that wrote it, and a commit that doesn't cite a spec is blocked. New to the vocabulary? There is a [glossary](GLOSSARY.md).

## How it works

Every feature goes through four commands. Running the next command is how you approve the step before, so nothing moves forward without you.

| Step | You run | Claude does | You get |
| --- | --- | --- | --- |
| 1. Specify | `/jsdd:specify <idea>` | Writes the spec and asks the questions that block it | `spec.md`: what to build, and how to prove it |
| 2. Plan | `/jsdd:plan <ID>` | Designs the solution, breaks it into small tasks with a check each, and has a reviewer agent check the plan | `plan.md` and `tasks.md` |
| 3. Implement | `/jsdd:implement <ID>` | Works through the tasks, ticking each one only when its check passes | Code and green tests, committed per task |
| 4. Verify | `/jsdd:verify <ID>` | Checks every acceptance criterion and reads the code against every requirement | A closed spec, or a report of gaps for you to approve |

Along the way:

- **The board knows what's next.** `/jsdd:status` shows every spec, its status, and the command to run. It's also printed at the start of each session, so Claude picks up where it left off.
- **Questions get researched before you're asked.** For an open question rather than a feature, `/jsdd:spike <topic>` has a research agent write a briefing and ask you only what it can't look up.
- **Existing code is recorded as it's touched.** `/jsdd:baseline <area>` writes down how an area works today, checked by its existing tests. No up-front inventory.
- **Several sessions can work at once.** Each session claims a spec or task before starting, and claims are shared across git worktrees, so sessions never collide.
- **Everything traces.** Requirements have IDs, specs cite them, tasks cite the spec's criteria, and commits cite the task. `jsdd coverage` shows what is done.
- **Or hand it off after the spec.** In autopilot mode (opt-in, per project and per person), `/jsdd:auto <ID>` takes a spec you wrote to a pull request with no questions: the reviewer approves the plan, checks tick the tasks, verification fixes what a check can prove, and anything only you can decide parks the spec and goes in the pull request. See [Autopilot](starters/specs/README.md#autopilot). With a committed charter, autonomous mode goes further: `/jsdd:auto` works through the queue on its own, has a product agent decide open questions as far as the charter allows, and leaves you pull requests and a morning digest. See [Autonomous](starters/specs/README.md#autonomous) and [the walkthrough](docs/autonomous-mode.md).

Everything is plain Markdown in your repository, driven by one bash script. There's no build step and no service.

## Is this for me?

JoDi-SDD earns its keep on work that takes more than one session: a feature with several moving parts, a change to code nobody fully remembers, a question that needs research before anyone can decide, or a project where several Claude sessions work at once. The spec is what lets a new session, or a reviewer that never saw the conversation, pick up the work and judge it.

It is not yet a good fit for a one-line fix. Today every feature goes through all four steps, and the ceremony is real. A lighter track for small changes is [on the roadmap](ROADMAP.md#2-a-lighter-track-for-small-changes); until then, do small fixes outside the kit and commit them as `[meta] …`.

It only works in Claude Code. If you use other coding agents, or want a large ecosystem of extensions, [Spec Kit](https://github.com/github/spec-kit) is the better fit. [docs/comparison.md](docs/comparison.md) says what each does differently.

## Install

You need Claude Code with plugin support, ideally in a git repository. In the project where you want it:

```sh
claude plugin marketplace add JoDi-27/jodi-sdd --scope project
claude plugin install jsdd@jodi-sdd --scope project
```

Project scope records the plugin in the project's `.claude/settings.json`, so teammates who clone the project are offered it too. Use `--scope user` to install it for all your projects instead. The plugin stays inactive in any project that hasn't run `/jsdd:init`.

<details>
<summary>Requirements, and Windows</summary>

- `bash`, `awk`, `jq`, and `python3`, already installed on most macOS and Linux machines.
- On Windows: [Git for Windows](https://gitforwindows.org) (Claude Code runs the hooks and `jsdd` in its Git Bash), plus jq and Python: `winget install jqlang.jq Python.Python.3.12`. Without them, the commit-message check and `STATUS.md` regeneration are skipped, and the session-start board says so.
- A git repository is recommended rather than required. Sharing claims across worktrees and checking commit messages both need one.

</details>

## Get started

In a Claude Code session in your project:

1. `/jsdd:init` sets up the project and interviews you to fill in its files. Add notes after the command to pre-fill answers.
2. Start a new session, so the hooks pick up the project.
3. `/jsdd:status` shows the board and the first command to run.

Then follow [Your first feature](docs/first-feature.md) on a new project, or [Existing codebases](docs/existing-codebases.md) on one that already has code.

## Commands

| Command | What it does |
| --- | --- |
| `/jsdd:init [notes]` | Sets up the project, then interviews you to fill in its starter files |
| `/jsdd:status [ID]` | Shows the board, what to do next, and requirement coverage |
| `/jsdd:specify <idea, PLAN item, or ID>` | Creates or refines a feature spec |
| `/jsdd:spike <topic or ID> [notes]` | Runs a spike: research first, then questions for you |
| `/jsdd:plan <ID>` | Approves the spec, then writes the plan and tasks; after a verification with gaps, plans the fixes as an amendment |
| `/jsdd:implement <ID> [task]` | Works through the tasks |
| `/jsdd:baseline <area or ID>` | Records how an area of existing code works today, checked by its existing tests |
| `/jsdd:verify <ID>` | Checks the acceptance criteria (or a spike's answers) and the code against the spec, then closes it, or reports gaps for your approval |
| `/jsdd:auto <ID>` | In autopilot or autonomous mode: runs a spec through plan, implement, and verify to a pull request without asking you anything; parks what only you can decide |
| `/jsdd:auto [setup \| --dry-run \| doctor]` | In autonomous mode: works through the queue within the project's charter; `setup` writes the charter, `--dry-run` shows what a run would do, `doctor` checks what it needs |

Under the hood, these commands use the `jsdd` CLI, which the plugin adds to the PATH for Claude's Bash tool. Run `jsdd help` for its subcommands.

## What `/jsdd:init` adds

| Path | Contents |
| --- | --- |
| `docs/intent.md` | What you are building and why |
| `docs/requirements.md` | Requirements with IDs (`FR-`, `NFR-`) and priorities |
| `docs/capabilities/` | Created as specs close: one document per requirement group saying how that area works now |
| `docs/decisions.md` | Settled decisions (`DEC-nn`) and open ones (`ND-nn`) |
| `PLAN.md` | The roadmap: phases, each item tagged with the requirements it covers |
| `BACKLOG.md` | One line per open decision with a suggested default, and spikes with their questions |
| `specs/constitution.md` | Rules every plan is checked against, plus your project's test command and architecture rules |
| `specs/README.md` | How the workflow runs: statuses, IDs, file formats, and parallel work |

These are your files. Running `/jsdd:init` again only updates `specs/README.md`, when a new plugin version changes it, and never overwrites the others.

## FAQ

**The board didn't print and commits aren't checked.** Hooks load at session start. Start a new session after `/jsdd:init` or after installing the plugin.

**My commit was blocked.** A commit message must start with the spec it belongs to, `[003] T3 …` for a task or `[003] …` for the spec, or `[meta] …` for anything that isn't spec work. Work outside the kit, such as a quick fix, is committed as `[meta]`.

**Verify found gaps. What now?** Read `verify-report.md` in the spec folder: one numbered gap (G1, G2, …) with a proposed fix each. Approve, and `/jsdd:plan <ID>` plans the fixes as an amendment, which `/jsdd:implement` then builds. Decline, and the spec is blocked; `/jsdd:plan <ID>` later is your approval to fix them after all. A gap that survives two rounds gets only two options: change the spec, or drop the gap.

**Where does my data live, and how do I remove the kit?** Everything is Markdown in your repository: `specs/`, `docs/`, `PLAN.md`, and `BACKLOG.md`. Claims are kept in `.git/sdd-claims` (or `specs/.claims` outside git). Remote claims are refs under `refs/sdd-claims/` on the remote, cached in `.git/sdd-claims-remote`. Uninstall with the scope you installed with (the default is `user`), then delete those files if you no longer want them:

```sh
claude plugin uninstall jsdd@jodi-sdd --scope project
```

**How do I update?** Run `claude plugin update jsdd@jodi-sdd`, start a new session, and run `/jsdd:init` again to pick up any changes to `specs/README.md`. It leaves your other files as they are. [CHANGELOG.md](CHANGELOG.md) lists what changed in each release, including behaviour changes.

**Can two people, or two sessions, work on one project?** Yes. A session claims a spec or task before starting, so another session skips it. By default, claims are shared across worktrees on one machine. For several people on their own clones, run `git config jsdd.claims remote` in each clone, and claims become refs on the git remote that every clone sees. Claims show as stale after 8 hours. See [Working in parallel](starters/specs/README.md#working-in-parallel).

## Going further

Two guides, depending on where you start:

| | New project | Existing codebase |
| --- | --- | --- |
| Read | [Your first feature](docs/first-feature.md) | [Existing codebases](docs/existing-codebases.md) |
| Init does | Interviews you and plans an MVP | Surveys the code and plans the next milestone |
| Before building | Specify the feature | Record how the area works today with `/jsdd:baseline` |
| Requirements come from | The interview | The code, confirmed by you, one area at a time |

Once the basics work:

- [Runtime modes](starters/specs/README.md#runtime-modes): what happens at each point where a skill waits for you. `manual` asks every time; `autopilot` takes a spec you approved to a pull request with `/jsdd:auto <ID>`. Turn modes on in `specs/jsdd.yml`, then pick one per person with `SDD_MODE`. See [Autopilot](starters/specs/README.md#autopilot) for what a run does and what makes it park.
- [Working in parallel](starters/specs/README.md#working-in-parallel): how sessions claim specs and tasks so they never collide. Claims are shared across worktrees on one machine by default. [Remote claims](starters/specs/README.md#several-people-claims-through-the-git-remote) (`git config jsdd.claims remote`) share them through the git remote, for several people on their own clones.

Reference:

- [GLOSSARY.md](GLOSSARY.md): every term the kit uses, one line each.
- [starters/specs/README.md](starters/specs/README.md): the full workflow, including every spec status and what moves a spec between them, spikes, baselines, IDs, file formats, and the commit-message format. `/jsdd:init` copies it into your project as `specs/README.md`.
- [docs/comparison.md](docs/comparison.md): how JoDi-SDD differs from Spec Kit, and what you give up.
- [ROADMAP.md](ROADMAP.md): feature ideas drawn from other SDD frameworks, open for discussion.
- [CHANGELOG.md](CHANGELOG.md): what changed in each release.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how the plugin is laid out, how to test changes locally, and how to add a new command. Report security issues privately, as described in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
