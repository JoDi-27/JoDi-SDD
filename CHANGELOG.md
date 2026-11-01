# Changelog

## Unreleased

Support for existing codebases (brownfield projects).

- New `/jsdd:baseline <area>` and spec type `baseline`. A baseline records what one area of existing code does today: the new `sdd-surveyor` agent drafts its current behavior from the code and tests, you confirm what is intended, and the rows go into `docs/requirements.md`. The baseline spec's acceptance criteria are the existing tests. It has no plan or tasks, and `/jsdd:verify` closes it once every check passes. Create one with `jsdd new baseline "<title>"`.
- `jsdd done <ID> AC-n` ticks a baseline's acceptance criterion, only when its check passes (or with `--manual`).
- `/jsdd:init` handles existing code. `jsdd init` reports the tracked code and the test commands it finds, and marks as `keep` any file at a kit path that is the project's own document in another format. The skill asks whether the project is an existing product. If so, it surveys the code, plans one baseline per area the next milestone touches, and offers to move the files marked `keep` to `docs/legacy/` and fold their content in.
- `/jsdd:specify` suggests a baseline when a feature changes existing code in an area with no requirement rows. `/jsdd:plan` and `/jsdd:implement` refuse baselines.
- **Behavior change:** `jsdd coverage` now counts a requirement as done only when every spec covering it is done (dropped specs aside). Before, one done spec was enough. A feature that changes a row a baseline proved now shows it in progress until the feature is verified. A requirement split across several specs is done only when all of them are.

## 0.3.0 (2026-11-01)

- `docs/decisions.md` is the single register of decisions. Open ones (`ND-nn`) become `DEC-nn` rows when a spike or plan settles them; the backlog keeps a one-line item. Spike, plan, verify, and both agents read and write it.
- `jsdd claim <ID> <Tn>` now follows the same order as `claim next` and is refused while earlier tasks are unfinished.
- Removed `jsdd release --done`. Use `jsdd done <ID> <Tn>`.
- Spec titles with quotes or pipes work.
- `specs/STATUS.md` is also regenerated when `PLAN.md` or `docs/requirements.md` is edited.
- The stop hook works outside git.
- The commit hook catches the `git -c` and `git -C` forms.
- Removed the Verification items (V1, V2) from `tasks.md`; only Tasks and Evidence remain.
- `/jsdd:init` now interviews you to fill the starter files, after setting up the project.
- `/jsdd:verify` and the reviewer use the project's main branch (`$SDD_MAIN_BRANCH`, else `main`) for the git range, or the spec's commits when work was committed directly on it.

## 0.2.0 (2026-11-01)

Renamed: the repository and marketplace are now `jodi-sdd`, and the plugin and CLI are `jsdd`. Commands are `/jsdd:plan`, `/jsdd:verify`, and so on, and the script is `jsdd done`, `jsdd next`, and so on.

**Upgrading from `sdd@sdd-kit`.** Swap the plugin, then run `/jsdd:init`, which replaces the old `Bash(sdd *)` permission with `Bash(jsdd *)`. Specs, claims, and the starters need no change.

```sh
claude plugin uninstall sdd@sdd-kit --scope project
claude plugin marketplace remove sdd-kit
claude plugin marketplace add JoDi-27/jodi-sdd --scope project
claude plugin install jsdd@jodi-sdd --scope project
```

## 0.1.0

First public release, packaged as a Claude Code plugin.

**Upgrading from the `install.sh` version.** Before it was a plugin, the kit was copied into each project by `install.sh`, into `.claude/` and `specs/_kit/`. In such a project, install the plugin and run `/sdd:init --migrate`. This removes the old copy and takes the old hooks out of `.claude/settings.json`, keeping the project's own settings. It also moves customizations such as the test command into `specs/constitution.md`.
