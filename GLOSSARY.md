# Glossary

The words JoDi-SDD uses, grouped so you can read them in order rather than alphabetically. Each term links to where it is used in practice. The full reference for statuses, IDs, and file formats is [starters/specs/README.md](starters/specs/README.md), which `/jsdd:init` copies into your project as `specs/README.md`.

## The method

- **Spec-driven development (SDD).** Writing down what a piece of work must do, in a form that can be checked, before planning or building it. The written spec, not the chat history, is what Claude works from and what the result is checked against.
- **Spec.** One folder under `specs/` (such as `specs/003-password-reset/`) describing one slice of work: the problem, what is in and out of scope, numbered requirements, and acceptance criteria. There are three kinds: feature, spike, and baseline.
- **Feature.** A spec for building something. It goes through the four steps: specify, plan, implement, verify.
- **Spike.** A spec for answering a question instead of building. A research agent writes a briefing from the repository and current documentation, then asks you only what it can't look up. It ends in recorded decisions. See [Spikes](starters/specs/README.md#spikes).
- **Baseline.** A spec that records how an existing area of code behaves today, checked by the tests it already has. It lets existing behaviour count as done without rebuilding it. See [Baselines](starters/specs/README.md#baselines).
- **Constitution.** `specs/constitution.md`. The rules every plan is checked against: six engineering articles that ship with the kit, plus your project's own principles, test command, and architecture rules.
- **Approval.** You approve a step by running the next command. There is no separate approve action. Running `/jsdd:plan` approves the spec; running `/jsdd:implement` approves the plan.
- **Brownfield.** A project with existing code brought under the kit. `/jsdd:init` surveys it and plans baselines instead of an MVP.

## The project documents

- **Intent.** `docs/intent.md`. What you are building, for whom, and why.
- **Requirement (product-level).** One row in `docs/requirements.md` with an ID, the behaviour, where it came from, and a priority. This is the product-level list that specs make testable.
- **Requirement ID.** `FR-<AREA>-nn` for a functional requirement, `NFR-<AREA>-nn` for a non-functional one. Example: `FR-AUTH-02`. An ID never changes once a spec cites it.
- **Priority.** On each requirement row: `M` Must, `S` Should, `C` Could, `W` Won't.
- **Roadmap.** `PLAN.md`. The phases of work, each item tagged with the requirements it delivers. Not the same thing as a spec's `plan.md`.
- **Phase.** A numbered stage in `PLAN.md`. Phase 0 holds spikes and foundations, Phase 1 the first version (or, on an existing codebase, the next milestone).
- **Backlog.** `BACKLOG.md`. Open decisions with a suggested default, spikes with their questions, and work for after the first version.
- **Decision.** A row in `docs/decisions.md`. `ND-nn` while it is still open, `DEC-nn` once settled, with the options and the reasoning.
- **Capability document.** `docs/capabilities/<area>.md`. How one area works now, merged from every spec that changed it. Written when specs close, so you can read how an area behaves without reading every spec that touched it.
- **Board.** The progress view of every spec, with what to do next. Printed by `/jsdd:status`, at the start of each session, and saved as `specs/STATUS.md`.
- **Starter.** A template file that `/jsdd:init` copies into a project, such as `docs/intent.md` or `PLAN.md`. Init never overwrites one that already exists.

## Inside a spec

- **spec.md.** What and why. Scenarios, requirements, and acceptance criteria. No technology, schemas, or code: those belong in `plan.md`.
- **Requirement (in a spec).** `R1`, `R2`, … One behaviour each, written in EARS form and tagged with the product-level rows it refines: `**R1** (FR-AUTH-02) When …`.
- **EARS.** A fixed sentence shape for requirements, such as "When *trigger*, the system shall *response*" or "If *condition*, then the system shall *response*". It makes each requirement testable and hard to misread.
- **Acceptance criterion (AC).** `AC-1`, `AC-2`, … An observable, testable condition that proves a requirement is met. `/jsdd:verify` checks every one and records evidence.
- **Needs-clarification marker.** `[NEEDS CLARIFICATION: …]` in a spec or plan. An unknown written down instead of guessed. `/jsdd:plan` refuses to start while any remain.
- **plan.md.** How the spec will be built: design, decisions, constitution check, test strategy, and deviations. It adds no new requirements.
- **tasks.md.** The ordered list of tasks for a feature spec, plus the evidence table filled in at verification.
- **Task.** `T1`, `T2`, … A step of half a day at most that leaves the build green. Each names the files it touches, the acceptance criterion it serves, and its check. Consecutive tasks marked `[P]` can run in parallel.
- **Check.** The command on a task that proves it is done, written as ``check: `pytest tests/test_reset.py` ``. `jsdd done` runs it and ticks the task only when it exits 0. A task no command can prove is written `check: manual: …` and needs a note saying who checked what.
- **Evidence.** The recorded result of a check or a manual verification, one row per acceptance criterion, kept in `tasks.md` (or in a baseline's `spec.md`).
- **Deviation.** A recorded difference between the plan and what was actually built, logged in `plan.md` so the plan stays true.
- **Changelog (of a spec).** The log at the end of `spec.md` of every change to it, including why a spec was blocked or dropped.
- **Status.** Where a spec is: `draft`, `approved`, `planned`, `in-progress`, `done`, `blocked`, or `dropped`. The full table, with which command moves a spec between them, is in [Lifecycle](starters/specs/README.md#lifecycle).

## Verification

- **Verify.** `/jsdd:verify`. Checks every acceptance criterion against evidence and the code against every requirement, then closes the spec or reports gaps for you to approve.
- **Converged.** The verdict that closes a spec: every acceptance criterion passes, the code does what each requirement says, nothing extra was built, and every difference from the plan is recorded as a deviation.
- **Gap.** `G1`, `G2`, … Something verification found that the code or the spec does not satisfy, with a proposed fix. Gaps are written to `verify-report.md` in the spec folder. Verify changes nothing itself; you approve or decline the fixes.
- **Amendment.** `A1`, `A2`, … A numbered section added to `plan.md` by `/jsdd:plan` after a verification with gaps, saying what each gap became: follow-up tasks, a spec change, a deviation, or a backlog item.
- **Two rounds.** If a gap on the same criterion survives two rounds of fixes, the spec or its check is probably wrong. Verify then offers only a spec change or dropping the gap, not a third fix.
- **Coverage.** `jsdd coverage`. Each product-level requirement with the specs that cover it and their status. A requirement counts as done once every spec that covers it is done.

## The machinery

- **jsdd.** The bash script behind every command. The plugin puts it on the Bash tool's PATH inside Claude Code; `jsdd help` lists its subcommands.
- **Skill.** A `/jsdd:` command, such as `/jsdd:specify`. The kit has eight.
- **Agent.** A subagent that runs in its own context. The kit has three: `sdd-reviewer` (checks plans, and gives a verdict per acceptance criterion at verification), `spike-researcher` (writes a spike's briefing), and `sdd-surveyor` (reads existing code for baselines and init).
- **Fresh context.** A subagent that never saw the session which wrote the work, so it judges only what is on disk rather than what the session meant to do.
- **Hook.** A script Claude Code runs automatically. The kit's hooks print the board at session start, regenerate `specs/STATUS.md` when a spec changes, block a `git commit` whose message cites no spec, and warn when a session stops while still holding claims. Hooks load at session start, so you need a new session after `/jsdd:init`.
- **Commit message format.** `[003] T3 Reject expired tokens` for work on a task, `[003] …` for a spec, `[meta] …` for housekeeping. The commit hook rejects anything else.
- **Claim.** A lock a session takes on a spec or a task before working on it, so parallel sessions never pick the same work. Claims live in `.git/sdd-claims`, are never committed, and show as stale after 8 hours. See [Working in parallel](starters/specs/README.md#working-in-parallel).
- **Worktree.** A git feature that gives one repository several checkouts, each on its own branch. Claims are shared across all worktrees on one machine.
- **Session.** One Claude Code conversation. Several sessions can work on one project at once; claims keep them apart.
