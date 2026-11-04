# How JoDi-SDD differs from Spec Kit

[Spec Kit](https://github.com/github/spec-kit) and similar frameworks give the agent better documents: a spec, a plan, a task list, and prompts that check them against each other. That helps, but it leaves the agent in charge of its own progress. The same session writes the code, ticks the task, and reviews the result.

JoDi-SDD is built for Claude Code only, so it can use what Claude Code offers instead of asking the model to behave:

- **Done means the check passed.** In Spec Kit, `/speckit.implement` tells the model to mark each task `[X]` when it's complete, and its checklist gate counts checkboxes. Here, each task names a check command, and `jsdd done` ticks it only when that command exits 0. A task that can only be checked by hand needs a note saying who checked what.
- **Reviews come from a fresh context.** Spec Kit's `/speckit.analyze` and `/speckit.converge` run in the session that wrote the work, which is biased toward it. JoDi-SDD hands each plan, and each spec before it closes, to a read-only reviewer subagent that never saw that session. It judges only what is on disk and gives a verdict per acceptance criterion, with evidence. Like `/speckit.converge`, `/jsdd:verify` also reads the code against each requirement and proposes a fix for each gap. Unlike converge, it adds no tasks itself: it shows you the report, and the fixes you approve go back through `/jsdd:plan` as a reviewed amendment, and spec changes through `/jsdd:specify` first. If you decline, the spec is blocked until you plan them or drop it. And where converge can loop, a gap that survives two rounds of fixes gets only one proposal: change the spec, or drop the gap.
- **Hooks enforce what prompts can only ask for.** The board and the open claims are put into context at the start of every session, so Claude knows what's in progress without being told. A commit whose message doesn't cite a spec or task is blocked before it runs. `STATUS.md` is regenerated whenever a spec or task list is edited, and a session that stops while still holding claims gets a warning.
- **Research happens in its own context too.** A spike's research agent reads the repository and current documentation and settles what it can before you're asked anything. On existing code, a survey agent drafts how an area works today from its code and tests, for you to confirm.
- **Parallel sessions share one board.** Claims live in the git common directory, so sessions in separate worktrees see each other's work and don't pick up the same task. Spec Kit tracks a single active feature in a file you point at by hand.
- **Requirements trace to commits.** Requirement IDs are project-wide, so `jsdd coverage` shows which requirements have a spec, which are in progress, and which are done.

What you give up: Spec Kit works with dozens of coding agents and has a large catalog of extensions and presets. JoDi-SDD works only in Claude Code. If you use another agent, or want Spec Kit's ecosystem, Spec Kit is the better fit.

[ROADMAP.md](../ROADMAP.md) compares JoDi-SDD with Kiro, OpenSpec, BMAD, Taskmaster, Tessl, and GSD, and lists the ideas drawn from them.
