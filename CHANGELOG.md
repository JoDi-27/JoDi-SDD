# Changelog

## Unreleased

- The project's whole test suite is now a gate before a spec closes or its pull request leaves draft. Task checks are narrow, so a change could pass every check, converge, and open a ready pull request that broke an existing test no task named, leaving CI to be the first full run.
  - New `jsdd suite <ID>` runs the project's test command from the repository root and records the result, with the commit it ran on, in `suite-result.txt` in the spec folder. `jsdd suite <ID> --check` says whether a pass is recorded for the code as it is now. A code change makes the pass stale; a change to the kit's own documents does not. `jsdd suite --command` prints the command and where it came from.
  - The command is the new `test_command` key in `specs/jsdd.yml`, else the first command in backticks on the constitution's `Test command:` line.
  - `/jsdd:verify` runs it, and each failing test is a gap. A feature converges and closes only on a fresh pass. In a run, a failure that also happens on the main branch, or a missing test command, parks at `verify.gaps`.
  - `jsdd run result --write` records a done feature without a fresh pass as `failed`, with the reason, so `jsdd auto run` exits 1.
  - New `jsdd pr <ID> --ready` exits 0 only for a spec that is done, not parked, and (for a feature) has a fresh pass; `/jsdd:auto` opens a draft otherwise. The pull request body states the suite's result. `jsdd auto run` turns a ready pull request that fails `--ready` back into a draft (event `pr.draft`).
  - `jsdd auto doctor` checks that a test command is set (FIX otherwise), and `/jsdd:auto` refuses to start without one. A hook blocks edits to `suite-result.txt` during a run.
  - `/jsdd:plan` keeps task checks narrow and adds no task just to run the whole suite. The reviewer's verify mode names existing tests that pin what the change alters.

## 0.7.12 (2026-11-11)

- Tasks can be blocks: a head line with the checkbox, the ID, `[P]`, a short title, and `→ AC-n`, then indented sub-bullets for the files, the check (`- check: …`), and notes. One-line tasks still work, and both forms can be mixed in one `tasks.md`. `jsdd done` reads the check from the body. With `--manual`, the note goes in a `- checked:` sub-bullet under the block. A task with more than one check is refused by `done` and `freeze`, and the autonomous dry run sees manual checks in a body. The template, `/jsdd:plan`, and the reviewer now write tasks as blocks, with a blank line between them, so ticks on neighboring tasks in two worktrees merge without a conflict. A check that needs pipes, `$(...)`, or several commands goes in a script the check runs.

## 0.7.11 (2026-11-10)

- Cloud-native runs (roadmap idea 13): the kit can be driven by scripts, cron, CI, or a container with nobody watching. See [docs/machine-output.md](docs/machine-output.md).
- New `jsdd auto run [<ID> | --loop] [--worktree] [-- <claude flags>]`: the headless runner. It checks what an unattended run needs, picks the next spec (or takes the one given), runs `/jsdd:auto` with `claude -p`, and afterwards, however the session ended, records the result, commits it, and pushes the run branch (never `--force`). It exits with the outcome: 0 done, 4 parked, 5 budget spent, 1 failed, 3 nothing to do. It never picks a permission mode: pass one after `--`.
- New profiles: `SDD_PROFILE=cloud` fills in what an unattended run needs, but only where nobody set a value: autopilot, JSON output, remote claims, and the unattended doctor checks. An env var wins, then the profile, then `specs/jsdd.yml`. A profile never widens the modes a project allows. `jsdd profile [--explain]` shows each setting and where it came from.
- `--json` on `next`, `status`, `mode`, `charter`, `profile`, `auto queue`, `auto dry-run`, `auto doctor`, `auto run`, `run status`, and `run result`, or `JSDD_OUTPUT=json` for those commands only. Each prints one document with a versioned schema (`jsdd.<command>/1`), also on failure. Commands that skills, hooks, or GitHub read as text (`pr`, `gate`, `budget`, `run next`) never change.
- Exit codes are now the same for every command: 0 ok, 1 failed, 2 usage or setup (was 1), 3 nothing to do, 4 parked, 5 budget spent, 6 lost a claim race, 7 remote unreachable. Scripts that only test for non-zero are unaffected.
- New `run-result.json` beside `run-report.md`: how a run ended (`done`, `merged`, `parked`, `budget`, `failed`, `noop`), the gate, the branch, tasks, commits, assumed decisions, and the session's cost. jsdd writes it from disk with `jsdd run result <ID> --write`, which `/jsdd:auto` runs before its last commit; `jsdd run end` writes it if it is missing, and takes `--outcome`. Loops add `specs/runs/<date>-<n>.json` (`jsdd run result --loop --write`).
- In autopilot mode, `jsdd auto queue` lists what `/jsdd:auto <ID>` accepts: feature specs with no open questions, not parked, with their dependencies done and no open run branch. Each left-out spec has a reason code.
- `JSDD_EVENTS=<file>` appends one JSON line for each state change: runs, loop steps, claims, ticked tasks, frozen checks, and parking.
- A new PreToolUse hook blocks AskUserQuestion while the session has a run open, and tells it to park instead. Outside a run nothing changes.
- `jsdd auto doctor --unattended` (implied by the cloud profile) adds checks as FIX:
  - Claude Code is installed, and Claude credentials are set
  - `JSDD_SESSION_ID` is set
  - jq is installed
  - a git identity is set
  - claims are remote, and a probe can push and delete a ref under `refs/sdd-claims/`
  - `gh` works
  It now exits 2 when something needs fixing.
- `claims: remote` (or `local`) in `specs/jsdd.yml` sets the claim mode for every clone. `SDD_CLAIMS` and `git config jsdd.claims` still win.
- The claim owner is `$JSDD_SESSION_ID` when it is set, ahead of `$CLAUDE_CODE_SESSION_ID`. `jsdd auto run` sets it, and passes the same UUID to `claude --session-id`.

## 0.7.10 (2026-11-10)

- New `autonomous` mode (roadmap idea 12, M1 and M2): with a charter the team commits, `/jsdd:auto` works through the queue without asking anyone. It takes spec after spec, each on its own branch and each ending in a pull request, until the queue is empty or a budget runs out. The charter is the `autonomous:` section of `specs/jsdd.yml`: a `preset` (`cautious`, the default; `standard`; `hands-off`), a `product` class (how far the `sdd-product` agent may decide), the scope (`types`, `phases`, `exclude_groups`), and budgets (new `specs_per_run`, default 3). A gate set in the section wins over the preset. Like autopilot, the mode needs consent: the project lists it under `modes`, and each person picks it with `SDD_MODE=autonomous`.
- New `sdd-product` agent: in autonomous mode, product questions (open markers, gap options that differ in product behavior, spec changes from verify, split order, bug or intended) go to it instead of the session that asked. It reads only the product documents and code, answers each one, and classifies it as `cited`, `inferred`, `uncited` (decided by a fixed order: reversible, smallest, closest, consistent), or `conflict`, with its source or rule and the cost of undoing it. The charter's `product` setting (`park`, `cited`, `inferred`, `uncited`, `all`) caps which answers a run acts on; the rest park. `cautious` is `cited`, `standard` is `inferred`, and `hands-off` is `all`: it also hands spec changes from verify to the agent and merges a converged spec once every CI check passed. Each decision acted on gets an `AS-nn` row in a new Assumed section of `docs/decisions.md` until the owner confirms or rejects it, and the run report and pull request list them weakest basis first. The board counts the rows waiting.
- In autonomous mode nobody approves a spec, so the `sdd-reviewer` has a new `spec` mode that does: testable requirements, an acceptance criterion for each, the error, empty, and permission cases, traceability, and size. A spec it finds too large is split, with `sdd-product` picking which part goes first. `/jsdd:specify`, `/jsdd:spike`, and `/jsdd:baseline` gain autonomous rules: spikes resolve only what the researcher can answer from docs and code; baseline rows are confirmed by the reviewer (`source: code (auto)`, never Must), and bugs go to Findings and `BACKLOG.md`.
- New `/jsdd:auto setup` writes the charter, `/jsdd:auto --dry-run` (`jsdd auto dry-run`) shows what a loop would take, in order, where each spec would park, and why the others are left out, and `/jsdd:auto doctor` (`jsdd auto doctor`) checks the charter, the mode, the work tree, `gh`, and the permission mode, printing the fix for each. `jsdd auto queue` prints the queue.
- New `jsdd run start --loop`, `jsdd run next` (start the run on the next spec in the queue and print its ID), `jsdd run status --loop`, and `jsdd run end --loop`. A spec run inside a loop shares the loop's wall-time clock. The Stop hook keeps a loop going while it has specs and budget left, and lets it stop once it makes no progress. Each loop writes a report in `specs/runs/` (template `templates/loop-report.md`); run reports gain a Product decisions section. New `jsdd charter [get <key>]` prints the charter's effective values.
- The queue leaves out a spec whose run branch (`autonomous/<ID>-*` or `autopilot/<ID>-*`, local or on a remote) is not merged into the current branch yet, so a second loop never starts again work that waits in a pull request. In a run, a verify gap whose only fix is a `BACKLOG.md` item for follow-up work (every AC passing, every R delivered) no longer parks.
- `jsdd mode --explain` shows the preset, the product class, and the scope in autonomous mode, and marks gates the preset changed. The board says `MODE: autonomous, preset <name>, product <class>`. `spec.clarify` passes in autonomous mode (through `sdd-product`), and `spec.change` can be set to `auto`.

## 0.7.9 (2026-11-09)

- [meta] Roadmap: product agent for autonomous mode ([#31](https://github.com/JoDi-27/JoDi-SDD/pull/31))

## 0.7.8 (2026-11-09)

- Claims can be shared through the git remote, so several people on their own clones never pick the same spec or task, or create the same spec ID. Turn it on in each clone with `git config jsdd.claims remote` (remote from `jsdd.claimsRemote`, default `origin`). Each claim is then a ref under `refs/sdd-claims/` on the remote. Taking one is a push the remote accepts only if the ref does not exist yet, so exactly one of two simultaneous claims wins. Release and done are pushes leased on the ref this session last saw. Local mode stays the default and behaves as before.
- In remote mode, reads reuse a fetch made in the last 30 seconds and show `(remote origin, as of HH:MM)`, falling back to the last fetch when the remote is unreachable. Writes fail when it is unreachable; `SDD_CLAIMS=local` takes an offline claim on this machine only, and `jsdd claims` warns about local claims nobody else sees. A remote that hangs is given up after 15 seconds (`SDD_CLAIMS_TIMEOUT`). `jsdd new` also counts the specs on the remote's `main`, and `jsdd claims --prune` reads specs and ticks there.
- A task marked done records the branch it was done on. When a later claim on the spec comes from a checkout that does not have the tick yet, `jsdd claim` says which branch to merge or rebase onto first, in both modes.
- New `jsdd claims --mine` lists what this session still holds. The Stop hook uses it instead of its own copy of the claims storage.

## 0.7.7 (2026-11-09)

- New `autopilot` mode: once you have written and approved a spec, `/jsdd:auto <ID>` runs it to a pull request with nobody asked. It plans the spec and has the `sdd-reviewer` approve the plan, implements every task until its check passes (one commit each), verifies and builds the gaps a check can fix, then pushes the branch and opens a pull request whose body comes from the spec, the evidence, and a run report. A gate only a person can pass (a spec change, a manual check, a product choice, a gap that survives two rounds, a check that keeps failing) parks the spec instead, and the run ends with a draft pull request saying what waits. Every decision the run makes is recorded as `auto: <gate>`, never as yours. The mode needs consent: the project lists it in `specs/jsdd.yml`, and each person picks it with `SDD_MODE=autopilot`.
- New gate `pr.open`, and run budgets in `specs/jsdd.yml` (`attempts_per_task`, default 3; `wall_time_hours`, default 4), shown by `jsdd mode --explain` and printed by `jsdd budget <name>`.
- New `jsdd park <ID> <gate> <reason>` and `jsdd unpark <ID>`: a parked spec keeps its status, shows as parked on the board and under "Waiting for you", and `jsdd next` skips it.
- New `jsdd freeze <ID> [--accept <Tn>...]` records each task's check in `checks.lock`; `jsdd done` then refuses a task whose check changed, or a task the lock does not know, unless a Deviation names it. New `jsdd run start|end|status|active|stop-check` marks an autopilot run per session, and `jsdd pr <ID> [--title]` prints a pull request body.
- New hooks: during an autopilot run, a Stop hook keeps the session going while the run has work, budget, and progress left, and a PreToolUse hook blocks edits to `specs/constitution.md`, `docs/intent.md`, `specs/jsdd.yml`, and `checks.lock`. The `sdd-reviewer` marks a recommended option on gaps that have several, and in plan mode for an autopilot run treats manual checks and checks that already pass as blocking.
- Fixed: `specs/jsdd.yml` lists lost a trailing `t` on macOS (BSD sed read `[ \t]` as space, backslash, or `t`), so a mode such as `autopilot` was reported unknown.

## 0.7.6 (2026-11-09)

- Runtime modes, the foundation for running the kit with less hand-holding. Every point where a skill waits for a person is now a named gate (`spec.approve`, `spec.clarify`, `plan.approve`, `verify.gaps`, and 12 more), marked in the skills. A runtime mode decides what happens at each gate: `ask`, `auto`, or `park`. `manual`, where every gate asks, is the default and behaves exactly as before. `autonomous` is reserved but not available yet.
- New `specs/jsdd.yml` (optional, committed): which modes the project allows, and gate changes for each. New `SDD_MODE` picks a person's mode. A mode that needs consent can never be the project's default. A bad file, or a mode that is unknown, not allowed, or not available, falls back to manual, and the board says why.
- New `jsdd mode [--check | --explain]` prints the mode and where it came from, validates `specs/jsdd.yml` (exit 1 on any unknown key, gate, or value), and lists every gate with its policy. New `jsdd gate <gate>` prints one gate's policy.

## 0.7.5 (2026-11-05)

- Scenario tests (`tests/scenarios/run.sh`) run whole workflows through `jsdd` in CI on Linux, macOS bash 3.2, and Windows: migrating a project from the install.sh kit, a feature from planned to done across two sessions with every verification outcome and an amendment, a baseline and its capability document, and parallel worktrees.

## 0.7.4 (2026-11-05)

- The plugin declares its icon. `plugin.json` sets `icon` to `./icon.png`, and the image moved from `.claude-plugin/` to the plugin root.

## 0.7.3 (2026-11-05)

- `depends_on` accepts quoted IDs (`depends_on: ["003"]`, the way `refs` is written). Before, the quotes stayed on the ID, so `jsdd status` and `jsdd next` showed the spec waiting on its dependency even after it was done.
- `jsdd init` lists Markdown files that still point at the install.sh kit (`/sdd-specify` and the other `/sdd-*` commands, `specs/_kit/sdd`, `.claude/skills/sdd-*`) as `stale`, with their line numbers. After `--migrate` those commands are gone, and a `CLAUDE.md` that still names them sends every session to them. `/jsdd:init` shows the lines and offers to rewrite them to `/jsdd:*` and `jsdd`.

## 0.7.2 (2026-11-04)

- The board shows when a feature spec is ready for `/jsdd:verify`. Once every task is ticked, its Progress cell reads `6/6 ready to verify` and the summary line counts it (`in-progress 3 (1 ready to verify)`), in `jsdd status`, `specs/STATUS.md`, and the board shown at session start. `jsdd done` on the last open task also prints `next: /jsdd:verify <ID>`. Readiness is still worked out from the ticks, not stored as a status.

## 0.7.1 (2026-11-04)

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
