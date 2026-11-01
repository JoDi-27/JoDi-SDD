# sdd-kit

A lightweight spec-driven development (SDD) kit for Claude Code, packaged as a plugin (`sdd`) to enable in any project or prototype. Every piece of work starts as a spec, moves through reviewed steps (specify → plan → implement → verify, or an interview-style spike), and links back to the product's requirements by ID.

It is plain Markdown, one bash script, seven skills, two subagents, and four hooks. No dependencies beyond `bash`, `awk`, `jq`, and `python3`.

## Use it in a project

This repository is its own plugin marketplace. In the project:

```sh
claude plugin marketplace add ~/repos/personal/sdd-kit --scope project
claude plugin install sdd@sdd-kit --scope project
```

Both write to the project's `.claude/settings.json` (`extraKnownMarketplaces`, `enabledPlugins`), so the plugin runs only in projects that enable it. Then start a Claude Code session there and run `/sdd:init`. It copies the starters, allows `sdd` in the project's settings, and adds `.claude/settings.local.json` to `.gitignore`. Start a new session so the hooks see the project, then run `/sdd:status`. The full workflow is in [starters/specs/README.md](starters/specs/README.md), which is installed as `specs/README.md`.

The hooks also check for `specs/constitution.md` and do nothing without it, so enabling the plugin at user scope is safe too.

### Moving a project off the old install.sh copy

Projects set up with the old `install.sh` have the kit in `.claude/` and `specs/_kit/`. Enable the plugin, then run `/sdd:init --migrate`: it removes the old skills, agents, hooks, and `specs/_kit/`, takes the old hooks and permission out of `.claude/settings.json`, and moves project tweaks (test command, architecture rules) into `specs/constitution.md`. Without `--migrate`, `sdd init` refuses to run there, because every hook would run twice.

## What is in the plugin

| Path | What |
| --- | --- |
| `skills/` | `/sdd:specify`, `/sdd:plan`, `/sdd:implement`, `/sdd:spike`, `/sdd:verify`, `/sdd:status`, `/sdd:init` |
| `agents/` | `sdd-reviewer` (fresh-context plan and verify review), `spike-researcher` (briefings and questions for spikes) |
| `hooks/` | Board at session start, `specs/STATUS.md` regenerated on edits, `[NNN]`/`[meta]` commit messages enforced, unreleased claims warned at stop. Registered in `hooks/hooks.json` |
| `bin/sdd` | The CLI: `init`, `new`, `status`, `next`, `claim`, `release`, `done`, `claims`, `coverage`. The plugin puts it on the Bash tool's PATH; it works on the git checkout of the current directory (or `$SDD_ROOT`) |
| `templates/` | `spec.md`, `spike.md`, `plan.md`, `tasks.md`, used by `sdd new` and `/sdd:plan` |
| `starters/` | Copied into the project by `sdd init` |
| `.claude-plugin/` | `plugin.json` (the plugin) and `marketplace.json` (this repo as a marketplace) |

**Starters**, copied where missing and then owned by the project:

| Path | What |
| --- | --- |
| `docs/intent.md` | What and why, the short version |
| `docs/requirements.md` | `FR-`/`NFR-` rows with priorities, in the table shape `sdd coverage` reads |
| `docs/decisions.md` | `DEC-nn` settled, `ND-nn` open |
| `PLAN.md` | Phases, with items tagged by the requirement IDs they cover |
| `BACKLOG.md` | Open decisions with suggested defaults, spikes with goal questions, "Next" |
| `specs/constitution.md` | Product articles (yours to write), six engineering articles, and Project specifics: the test command and the reviewer's architecture checklist |
| `specs/README.md` | How the workflow runs. Kit-owned: `sdd init` refreshes it when it differs |

## Per-project settings

Everything a project tunes lives in its own `specs/constitution.md`, under "Project specifics": the test command plans use in task checks, and the architecture rules `sdd-reviewer` checks. The plugin files stay the same for every project.

## Improving the kit

Change it here and commit, bumping `version` in `.claude-plugin/plugin.json`. Projects pick it up with `claude plugin update sdd@sdd-kit` (or `/plugin`), then a new session. To try a change before committing, run Claude Code with `claude --plugin-dir ~/repos/personal/sdd-kit` in a test project. Check the manifests with `claude plugin validate .`.

## Adding a new engineering flow

A flow is a skill, plus agents or hooks if it needs them:

1. **Skill:** `skills/<flow>/SKILL.md` with `name`, `description` (when to use it; Claude reads this to decide), and `argument-hint` in its frontmatter. It runs as `/sdd:<flow>`. Write it as numbered steps with a gate at the start (what must be true to begin) and a report at the end (what was done, and the next command). Look at `skills/plan` for the shape. `${CLAUDE_PLUGIN_ROOT}` in the body is replaced with the plugin's path.
2. **Agent** (optional, for a fresh-context or read-only helper): `agents/<name>.md` with `name`, `description`, `tools`, and a fixed output format the calling skill can paste or act on.
3. **Hook** (optional, for something that must happen every time): a script in `hooks/` whose line 2 is `# <Event> on <matcher>: <what it does>`, registered in `hooks/hooks.json`. Hooks read their input as JSON on stdin, need to work without git, and exit quietly in a project without `specs/constitution.md`.
4. **State** the flow keeps goes in files in the project (like `specs/`), never only in the conversation.
5. If the flow touches specs, use the `sdd` CLI rather than editing status or checkboxes by hand, and add a subcommand to `bin/sdd` when it needs a new one.
6. **Settings** a project needs to tune go in the constitution's Project specifics, not in the plugin.

Then document it in `starters/specs/README.md` and in the tables above.

## Origin

Extracted from `ai-workflow-poc`, then generalized in `gym-app`, which added requirement traceability (`sdd coverage`, FR tags in PLAN, requirement checks in the skills and the reviewer). Shipped by `install.sh` until it became a plugin.
