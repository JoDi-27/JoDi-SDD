# sdd-kit

A lightweight spec-driven development (SDD) kit for Claude Code, to drop into any project or prototype. Every piece of work starts as a spec, moves through reviewed steps (specify → plan → implement → verify, or an interview-style spike), and links back to the product's requirements by ID.

It is plain Markdown, one bash script, six skills, two subagents, and four hooks. No dependencies beyond `bash`, `awk`, `jq`, and `python3`.

## Use it in a project

```sh
~/repos/personal/sdd-kit/install.sh path/to/project             # first install
~/repos/personal/sdd-kit/install.sh --update path/to/project    # take kit improvements
~/repos/personal/sdd-kit/install.sh --dry-run path/to/project   # see what would change
```

Then start a new Claude Code session in the project (hooks load at session start) and run `/sdd-status`. The full workflow is in [kit/specs/README.md](kit/specs/README.md), which is installed as `specs/README.md`.

## What gets installed

| Folder | Owned by | Install | `--update` |
| --- | --- | --- | --- |
| `kit/` | the kit | copied where missing; differences reported | overwrites what differs, except `.claude/settings.json` |
| `starters/` | the project, once copied | copied where missing | never touched |

**Kit files** (`kit/`), the same in every project:

| Path | What |
| --- | --- |
| `.claude/skills/sdd-*` | `/sdd-specify`, `/sdd-plan`, `/sdd-implement`, `/sdd-spike`, `/sdd-verify`, `/sdd-status` |
| `.claude/agents/` | `sdd-reviewer` (fresh-context plan and verify review), `spike-researcher` (briefings and questions for spikes) |
| `.claude/hooks/` | Board at session start, `specs/STATUS.md` regenerated on edits, `[NNN]`/`[meta]` commit messages enforced, unreleased claims warned at stop |
| `.claude/settings.json` | Registers the hooks and allows `specs/_kit/sdd` without a prompt |
| `specs/_kit/sdd` | The CLI: `new`, `status`, `next`, `claim`, `release`, `done`, `claims`, `coverage` |
| `specs/_kit/templates/` | `spec.md`, `spike.md`, `plan.md`, `tasks.md` |
| `specs/README.md` | How the workflow runs |

**Starters** (`starters/`), filled in per project:

| Path | What |
| --- | --- |
| `docs/intent.md` | What and why, the short version |
| `docs/requirements.md` | `FR-`/`NFR-` rows with priorities, in the table shape `sdd coverage` reads |
| `docs/decisions.md` | `DEC-nn` settled, `ND-nn` open |
| `PLAN.md` | Phases, with items tagged by the requirement IDs they cover |
| `BACKLOG.md` | Open decisions with suggested defaults, spikes with goal questions, "Next" |
| `specs/constitution.md` | Product articles (yours to write) and six engineering articles |

`install.sh` also adds `.claude/settings.local.json` and `specs/_kit/.claims/` to `.gitignore`, and writes the kit commit to `specs/_kit/VERSION` so you can tell which version a project runs.

## Per-project tweaks after install

- Replace the `make test` examples in `.claude/skills/sdd-plan/SKILL.md` and `.claude/agents/sdd-reviewer.md` with the project's test command.
- Add architecture rules to the reviewer's "Architecture checklist".
- Add project permissions (build tools and so on) to `.claude/settings.json`.

These files are kit-owned, so `--update` reports them as different afterwards. Either keep the project's version (run without `--update`), or move the tweak back into the kit if every project wants it.

## Improving the kit

Change it here, commit, then `install.sh --update` each project that should get it. When an improvement starts in a project (for example a skill fix made while working), copy the file back here first:

```sh
cp path/to/project/.claude/skills/sdd-plan/SKILL.md kit/.claude/skills/sdd-plan/SKILL.md
```

and review the diff for anything project-specific before committing.

## Adding a new engineering flow

A flow is a skill, plus agents or hooks if it needs them. Put it under `kit/` so every project gets it:

1. **Skill:** `kit/.claude/skills/<flow>/SKILL.md` with `name`, `description` (when to use it; Claude reads this to decide), and `argument-hint` in its frontmatter. Write it as numbered steps with a gate at the start (what must be true to begin) and a report at the end (what was done, and the next command). Look at `sdd-plan` for the shape.
2. **Agent** (optional, for a fresh-context or read-only helper): `kit/.claude/agents/<name>.md` with `name`, `description`, `tools`, and a fixed output format the calling skill can paste or act on.
3. **Hook** (optional, for something that must happen every time): a script in `kit/.claude/hooks/` whose line 2 is `# <Event> on <matcher>: <what it does>`, registered in `kit/.claude/settings.json`. Hooks read their input as JSON on stdin and need to work without git.
4. **State** the flow keeps goes in files in the project (like `specs/`), never only in the conversation.
5. If the flow touches specs, use the `sdd` CLI rather than editing status or checkboxes by hand, and add a subcommand to `specs/_kit/sdd` when it needs a new one.

Then document it in `kit/specs/README.md` (or its own README) and in the tables above.

## Origin

Extracted from `ai-workflow-poc`, then generalized in `gym-app`, which added requirement traceability (`sdd coverage`, FR tags in PLAN, requirement checks in the skills and the reviewer).
