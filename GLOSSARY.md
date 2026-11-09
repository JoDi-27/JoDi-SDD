# Glossary

One line per term, alphabetical. The full reference for statuses, IDs, and file formats is [starters/specs/README.md](starters/specs/README.md), which `/jsdd:init` copies into your project as `specs/README.md`.

| Term | Meaning |
| --- | --- |
| Acceptance criterion (AC-1, AC-2, …) | A testable condition in a spec that proves a requirement is met. Verify checks every one. |
| Agent | A subagent that runs in its own context: `sdd-reviewer` checks plans and verdicts, `spike-researcher` writes briefings, `sdd-surveyor` reads existing code. |
| Amendment (A1, A2, …) | A section added to `plan.md` after verification found gaps, saying what each gap became. |
| Approval | Running the next command. There is no separate approve action. |
| Assumption (`auto: spec.clarify`) | An open question an autonomous run answered with a recorded default (from `BACKLOG.md`, a DEC row, or the spec's recommended answer), written as an assumption with its source. Run reports list every one. |
| `auto:` decision | A decision a run made without a person, written as `auto: <gate>` with what passed it (`auto: plan.approve, sdd-reviewer`). Never recorded as a person's. |
| Autopilot | A runtime mode: you write and approve a spec, and `/jsdd:auto <ID>` plans, implements, and verifies it and opens a pull request without asking you anything. What it cannot settle parks. |
| Autonomous | A runtime mode: within a charter the team committed, `/jsdd:auto` works through the queue spec after spec, each to a pull request, with the reviewer approving specs and plans. What it cannot settle parks. |
| Backlog (`BACKLOG.md`) | Open decisions with a suggested default, spikes with their questions, and work for later. |
| Baseline | A spec that records how an existing area of code works today, checked by its existing tests. |
| Board | The progress view of every spec and what to do next. Printed by `/jsdd:status` and at session start; saved as `specs/STATUS.md`. |
| Brownfield | A project with existing code brought under the kit. Init plans baselines instead of an MVP. |
| Capability document (`docs/capabilities/<area>.md`) | How one area works now, merged from every spec that changed it when the spec closed. |
| Charter | The `autonomous:` section of `specs/jsdd.yml`: the preset, the scope (types, phases, excluded requirement groups), and the budgets an autonomous run works within. A run can never edit it. |
| Check | The command on a task that proves it is done. `jsdd done` ticks the task only when the command exits 0. `check: manual: …` when no command can. |
| Claim | A lock a session takes on a spec or task before working on it, so parallel sessions don't collide. Lives in `.git/sdd-claims`, never committed. With remote claims, it is a ref under `refs/sdd-claims/` on the git remote instead. |
| Commit message format | `[003] T3 …` for a task, `[003] …` for a spec, `[meta] …` for housekeeping. The commit hook rejects anything else. |
| Constitution (`specs/constitution.md`) | The rules every plan is checked against: the kit's engineering articles plus your project's principles, test command, and architecture rules. |
| Converged | The verdict that closes a spec: every criterion passes, the code matches every requirement, nothing extra, no unrecorded deviation. |
| Coverage | `jsdd coverage`: each requirement with the specs that cover it. A requirement is done when every spec covering it is done. |
| Decision (DEC-nn, ND-nn) | A row in `docs/decisions.md`. `ND` while open, `DEC` once settled. |
| Deviation | A recorded difference between the plan and what was built, logged in `plan.md`. |
| EARS | A fixed sentence shape for requirements: "When *trigger*, the system shall *response*." |
| Evidence | The recorded result of each acceptance criterion's check, kept in `tasks.md`. |
| Feature | A spec for building something. Goes through specify, plan, implement, verify. |
| Fresh context | A subagent that never saw the session that wrote the work, so it judges only what is on disk. |
| Frozen check | A task's check as recorded in `checks.lock` when a run's plan was approved. `jsdd done` refuses a task whose check changed, unless a Deviation names it. |
| Gap (G1, G2, …) | Something verification found that the code or spec doesn't satisfy, with a proposed fix, in `verify-report.md`. |
| Gate | A named point where a skill waits for a person, like `spec.approve` or `verify.gaps`. The runtime mode says whether it asks, passes on its own, or parks. |
| Hook | A script Claude Code runs on its own: prints the board, regenerates `STATUS.md`, blocks commits without a spec ID, warns about held claims. Loads at session start. |
| Intent (`docs/intent.md`) | What you are building, for whom, and why. |
| jsdd | The bash script behind every command. `jsdd help` lists its subcommands. |
| Loop | An autonomous run over the queue (`/jsdd:auto` with no ID): `jsdd run next` takes one spec at a time until the queue is empty or `specs_per_run` or the wall time runs out. Writes a loop report in `specs/runs/`. |
| Needs clarification | `[NEEDS CLARIFICATION: …]`: an unknown written down instead of guessed. Plan won't start while any remain. |
| Parked | A spec waiting at a gate only a person can pass, with the reason in its `parked:` frontmatter. It keeps its status, shows under "Waiting for you", and `jsdd next` skips it until `jsdd unpark`. |
| Phase | A numbered stage in `PLAN.md`. Phase 0 is spikes and foundations, Phase 1 the first version or next milestone. |
| plan.md | How a spec will be built: design, decisions, constitution check, test strategy, deviations. No new requirements. |
| Preset | One line that sets the autonomous gates: `cautious` parks every product question, `standard` answers them with recorded defaults, `hands-off` also merges converged work once CI is green. |
| Priority | On a requirement row: M Must, S Should, C Could, W Won't. |
| Remote claims | Opt-in mode (`git config jsdd.claims remote`) where claims are refs on the git remote, so people on separate clones see each other's claims. The remote accepts each claim only once. |
| Requirement (FR-AUTH-02) | A row in `docs/requirements.md` with an ID, a priority, and a source. `FR` functional, `NFR` non-functional. |
| Requirement (R1, R2, …) | A numbered behaviour inside a spec, in EARS form, tagged with the rows it refines. |
| Roadmap (`PLAN.md`) | Phases of work, each item tagged with the requirements it delivers. Not a spec's `plan.md`. |
| Run report (`run-report.md`) | What a run (autopilot or autonomous) did, each decision and assumption it made without a person, and what parked. The pull request links it. |
| Runtime mode | What happens at every gate. `manual`, where every gate asks, is the default; `autopilot` runs an authored spec to a pull request; `autonomous` works through the queue within a charter. Chosen with `SDD_MODE` among the modes `specs/jsdd.yml` allows. |
| Session | One Claude Code conversation. Several can work on one project at once. |
| Skill | A `/jsdd:` command. There are nine. |
| Spec | One folder under `specs/` describing one slice of work: feature, spike, or baseline. |
| spec.md | What and why: scenarios, requirements, acceptance criteria. No technology or code. |
| Spec-driven development (SDD) | Writing down what work must do, in checkable form, before planning or building it. The spec is what Claude works from and is checked against. |
| Spike | A spec for answering a question rather than building. A research agent writes a briefing, then asks you only what it can't look up. |
| Starter | A template file init copies into a project. Never overwritten once it exists. |
| Status | Where a spec is: `draft`, `approved`, `planned`, `in-progress`, `done`, `blocked`, `dropped`. |
| Task (T1, T2, …) | A step of half a day at most in `tasks.md`, with its files, its check, and the criterion it serves. `[P]` marks tasks that can run in parallel. |
| tasks.md | A feature spec's ordered tasks and its evidence table. |
| Two rounds | A gap that survives two rounds of fixes gets only two options: change the spec, or drop the gap. |
| Verify | `/jsdd:verify`: checks every criterion and the code against every requirement, then closes the spec or reports gaps. |
| Worktree | A git feature giving one repository several checkouts. Claims are shared across them on one machine. |
