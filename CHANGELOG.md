# Changelog

## Unreleased

- `docs/decisions.md` is the single register of decisions. Open ones (`ND-nn`) become `DEC-nn` rows when a spike or plan settles them; the backlog keeps a one-line item. Spike, plan, verify, and both agents read and write it.
- `sdd claim <ID> <Tn>` now follows the same order as `claim next` and is refused while earlier tasks are unfinished.
- Removed `sdd release --done`. Use `sdd done <ID> <Tn>`.
- Spec titles with quotes or pipes work.
- `specs/STATUS.md` is also regenerated when `PLAN.md` or `docs/requirements.md` is edited.
- The stop hook works outside git.
- The commit hook catches the `git -c` and `git -C` forms.
- Removed the Verification items (V1, V2) from `tasks.md`; only Tasks and Evidence remain.
- `/sdd:init` now interviews you to fill the starter files, after setting up the project.
- `/sdd:verify` and the reviewer use the project's main branch (`$SDD_MAIN_BRANCH`, else `main`) for the git range, or the spec's commits when work was committed directly on it.

## 0.1.0

First public release, packaged as a Claude Code plugin.

**Upgrading from the `install.sh` version.** Before it was a plugin, the kit was copied into each project by `install.sh`, into `.claude/` and `specs/_kit/`. In such a project, install the plugin and run `/sdd:init --migrate`. This removes the old copy and takes the old hooks out of `.claude/settings.json`, keeping the project's own settings. It also moves customizations such as the test command into `specs/constitution.md`.
