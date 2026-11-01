# Contributing

Issues and pull requests are welcome. For anything bigger than a fix, open an issue first so we can agree on the shape.

## Trying changes

You don't need to install the plugin to test it. Run Claude Code in a test project with the plugin loaded from your checkout:

```sh
claude --plugin-dir path/to/jodi-sdd
```

Check the manifests with `claude plugin validate .`, and run `/bin/bash .github/scripts/smoke.sh` for an end-to-end test of `jsdd` and the hooks in a throwaway repository. [CI](.github/workflows/ci.yml) runs both on every pull request, plus `shellcheck -S warning` on the scripts; the smoke test runs on Linux, on macOS's bash 3.2, and on Windows in Git Bash.

## Releasing

Every PR merged into `main` is released by [the Release workflow](.github/workflows/release.yml): it bumps `version` in `.claude-plugin/plugin.json`, moves the notes under `## Unreleased` in [CHANGELOG.md](CHANGELOG.md) into a section for the new version, tags it `vX.Y.Z`, and publishes a GitHub release. Projects pick up the new version with `claude plugin update jsdd@jodi-sdd`.

- The bump is a patch unless the PR has the `release:minor` or `release:major` label. While the version is 0.x, use `release:minor` for breaking changes. `release:skip` merges without a release.
- Write user-facing notes under `## Unreleased` in your PR. With none, the PR title becomes the entry.
- Don't edit `version` by hand.

## Layout

| Path | What |
| --- | --- |
| `skills/<name>/SKILL.md` | One skill each, run as `/jsdd:<name>` |
| `agents/` | `sdd-reviewer`, `spike-researcher`, and `sdd-surveyor` |
| `hooks/` | Session-start board, `STATUS.md` regeneration, commit-message check, unreleased-claims warning. Registered in `hooks/hooks.json` |
| `bin/jsdd` | The CLI (bash 3.2 and awk). It works on the git checkout of the current directory, or `$SDD_ROOT` |
| `templates/` | `spec.md`, `spike.md`, `baseline.md`, `plan.md`, `tasks.md` |
| `starters/` | What `jsdd init` copies into a project |
| `.claude-plugin/` | `plugin.json`, and `marketplace.json` that makes this repository its own marketplace |

## Adding a flow

1. **Skill:** `skills/<flow>/SKILL.md` with `name`, `description` (when to use it; Claude reads it to decide), and `argument-hint` in the frontmatter. Write it as numbered steps, with a gate at the start (what must be true to begin) and a report at the end (what was done, and the next command). `skills/plan` shows the shape. `${CLAUDE_PLUGIN_ROOT}` in the body becomes the plugin's path.
2. **Agent** (optional, for a fresh-context or read-only helper): `agents/<name>.md` with `name`, `description`, `tools`, and a fixed output format the calling skill can use.
3. **Hook** (optional, for something that must happen every time): a script in `hooks/` whose line 2 is `# <Event> on <matcher>: <what it does>`, registered in `hooks/hooks.json`. Hooks read JSON on stdin, must work without git, and exit quietly in a project without `specs/constitution.md`.
4. **State** goes in files in the project, never only in the conversation. If the flow touches specs, it uses the `jsdd` CLI rather than editing status or checkboxes by hand, and adds a subcommand when it needs one.
5. **Docs:** describe it in `starters/specs/README.md` and add it to the commands table in `README.md`.

## Conventions

- `bin/jsdd` stays portable: bash 3.2 (stock macOS) and POSIX awk, no GNU-only flags.
- Windows runs everything in Git Bash. Project files may be CRLF, so awk that reads them starts with `{ sub(/\r$/, "") }`. Hooks read their input with `json` from `hooks/_lib.sh` (jq.exe prints CRLF, and paths arrive with backslashes) and find Python with `find_python`.
- Commit messages in this repository start with `[meta]`.
