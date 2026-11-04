# Changelog

## Unreleased

- The README is rewritten for readers new to spec-driven development: it explains what SDD is, walks through a first feature with example spec and task lines, and says when the kit is and isn't a good fit, with an FAQ. Reference material moved out: the first-feature walkthrough and the existing-codebase guide to `docs/`, the Spec Kit comparison to `docs/comparison.md`, with an animated lifecycle diagram in the walkthrough (`.github/scripts/make_lifecycle.py`). New `GLOSSARY.md` defines every term the kit uses, linked from both READMEs.

## 0.7.0 (2026-11-04)

- Living capability documents. Each requirement group gets `docs/capabilities/<group>.md` (`auth.md` for `FR-AUTH`), which says how that area works now: one entry per requirement row with its current behavior, what proves it, and the spec that last changed it. Template `templates/capability.md`.
- Feature specs have a new **Capability changes** table: one line per requirement row the spec `adds`, `modifies`, or `removes`. `/jsdd:specify` fills it in after reading the area's entries. A removed behavior keeps its row ID with priority `W`. A baseline needs no table: when it closes, every row in its `refs` is added, which writes the area's first version.
- **Behavior change:** `/jsdd:verify` merges a spec's Capability changes into the capability documents when it closes the spec. If an entry changed after the spec was approved, it shows you both before merging. The reviewer checks the table in plan, verify, and baseline modes. `/jsdd:plan` reads the entries as context.
- New `jsdd capabilities [--check] [ID or group ...]`: the rows with an entry, the spec that last changed each, and the live specs about to change them. It flags done specs whose changes were never merged, removed rows that still have an entry, and entries with no row; `--check` exits 1 when it finds one. Feature specs closed before this release have no table and are not checked. Baselines closed before it show as not merged: the next `/jsdd:verify` in their area merges them first, so the area's document starts from them.

## 0.6.1 (2026-11-04)

- **Behavior change:** spec changes from a verification go through `/jsdd:specify`, not the plan. The plan is derived from the spec, so an amendment no longer edits `spec.md`. When you approve a gap whose fix is a spec change, `/jsdd:verify` sets the spec back to `draft`. `/jsdd:specify <ID>` revises it with you and logs each change against its gap ("Verify round 2/G3: …"). `/jsdd:plan <ID>` then approves the revised spec and plans the rest of the gaps as an amendment, never a new plan. `jsdd next` points such a spec to `/jsdd:specify`.
- `/jsdd:verify` stops the fix loop after two rounds. A gap on the same acceptance criterion or requirement as last round, whose planned fix is now built, gets only two options: change the spec, or drop the gap.

## 0.6.0 (2026-11-03)

- `/jsdd:verify` checks the code against the spec, not only the acceptance criteria' tests. The `sdd-reviewer` agent, and the verifying session, give each requirement a verdict (`delivered`, `partial`, `missing`, `contradicted`) with the code that delivers it. They also list behavior no requirement asks for and differences from the plan that its Deviations do not record. Each gap gets a proposed fix: a task with a check, a spec change, a Deviation, or a BACKLOG item.
- **Behavior change:** `/jsdd:verify` no longer adds fix tasks. It only judges: it writes `verify-report.md` in the spec folder (template `templates/verify-report.md`), with a numbered proposed action per gap, shows it, and asks whether to fix the gaps. If you approve, the spec goes back to `approved`. If you decline, only the report is kept and the spec is `blocked`; `jsdd next` shows it as "verification declined".
- `/jsdd:plan` has an amend mode for those gaps, which also resumes a blocked spec. It adds an amendment to the plan's new Amendments section (A1, A2, …) with one row per gap saying what it became: follow-up tasks, a spec change, a Deviation, or a BACKLOG item. The follow-up tasks go in `tasks.md` under `### A<n> · Follow-up from verify round <r>` and name the gap they serve. The reviewer checks the amendment in plan mode, and `/jsdd:implement` builds it as usual. The amendment is self-contained: it carries its own Decisions, Constitution check, Test strategy, and Risks, and the original plan stays as it was built.
- Verify and plan never record an approval or a choice you did not give. When a gap has more than one sensible fix, the report lists them as options and records the one you choose; plan follows it and never picks. When nobody can answer (for example, in a headless run), the decision stays `pending` and nothing is planned.

## 0.5.2 (2026-11-01)

- `/jsdd:init` finds what a project already wrote down under other names. `jsdd init` lists Markdown files at the top level and in `docs/` whose names suggest a starter (`VISION.md`, `docs/PRD.md`, `docs/adr/`, and the install.sh kit's `PRODUCT_INTENT.md`) as `source`, for starters that are missing or still blank. The skill reads those, the README, and the other top-level docs, proposes which starter each one feeds, and after you confirm, moves whole files to `docs/legacy/` and folds their content in. It then offers to update references to the moved files.

## 0.5.1 (2026-11-01)

- The README covers updating and uninstalling the plugin, and shows CI, release, and license badges.

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
