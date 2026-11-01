# Changelog

## Unreleased

- `/jsdd:init` finds what a project already wrote down under other names. `jsdd init` lists Markdown files at the top level and in `docs/` whose names suggest a starter (`VISION.md`, `docs/PRD.md`, `docs/adr/`, and the install.sh kit's `PRODUCT_INTENT.md`) as `source`, for starters that are missing or still blank. The skill reads those, the README, and the other top-level docs, proposes which starter each one feeds, and after you confirm, moves whole files to `docs/legacy/` and folds their content in. It then offers to update references to the moved files.

## 0.5.0 (2026-11-01)

Support for existing codebases (brownfield projects).

- New `/jsdd:baseline <area>` and spec type `baseline`. A baseline records what one area of existing code does today: the new `sdd-surveyor` agent drafts its current behavior from the code and tests, you confirm what is intended, and the rows go into `docs/requirements.md`. The baseline spec's acceptance criteria are the existing tests. It has no plan or tasks, and `/jsdd:verify` closes it once every check passes. Create one with `jsdd new baseline "<title>"`.
- `jsdd done <ID> AC-n` ticks a baseline's acceptance criterion, only when its check passes (or with `--manual`).
- `/jsdd:init` handles existing code. `jsdd init` reports the tracked code and the test commands it finds, and marks as `keep` any file at a kit path that is the project's own document in another format. The skill asks whether the project is an existing product. If so, it surveys the code, plans one baseline per area the next milestone touches, and offers to move the files marked `keep` to `docs/legacy/` and fold their content in.
- `/jsdd:specify` suggests a baseline when a feature changes existing code in an area with no requirement rows. `/jsdd:plan` and `/jsdd:implement` refuse baselines.
- **Behavior change:** `jsdd coverage` now counts a requirement as done only when every spec covering it is done (dropped specs aside). Before, one done spec was enough. A feature that changes a row a baseline proved now shows it in progress until the feature is verified. A requirement split across several specs is done only when all of them are.

## 0.4.1 (2026-11-01)

- Windows support (Git Bash): the hooks run through `bash`, handle backslash paths and jq/Python CRLF output, find `python` when there is no `python3`, and `jsdd` reads CRLF project files. The session-start board warns when jq or Python is missing.
- CI also runs the smoke test on Windows.

## 0.4.0 (2026-11-01)

First public release.

- The plugin has an icon.
- Pull requests are checked in CI: the manifests, `shellcheck` on the scripts, and a smoke test of `jsdd` on Linux and on macOS's bash 3.2.
- Issue and pull request templates, and a security policy in [SECURITY.md](SECURITY.md).

## 0.3.0 (2026-11-01)

Private release.

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

Private release. Renamed the kit from `sdd-kit` to `jodi-sdd`, and the plugin and CLI from `sdd` to `jsdd`. Projects on `sdd@sdd-kit` switch by installing `jsdd@jodi-sdd` and running `/jsdd:init`, which updates the `Bash(jsdd *)` permission.

## 0.1.0

Private release. The kit became a Claude Code plugin. Before that it was copied into each project by `install.sh`; `/jsdd:init --migrate` removes such a copy and keeps the project's own settings.
