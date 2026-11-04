# Roadmap

Feature ideas for JoDi-SDD, drawn from a comparison with other spec-driven development frameworks: [Spec Kit](https://github.com/github/spec-kit), Kiro (and cc-sdd), OpenSpec, BMAD, Taskmaster, Tessl, and GSD. Nothing here is committed to. Each idea says what's missing today, where it comes from, and a rough shape for it. Open an issue before starting one, as described in [CONTRIBUTING.md](CONTRIBUTING.md).

Already covered, so not listed: a constitution, EARS requirements, `NEEDS CLARIFICATION` markers, requirement-to-commit traceability, spikes, brownfield baselines, and parallel claims.

## High value

### 1. Living capability specs

*From OpenSpec.*

**Gap:** each spec is one change. Once a spec is `done`, its detailed behavior stays in its own folder, and `docs/requirements.md` holds only one line per requirement. Nothing says how an area works now without reading every spec that touched it.

**Shape:** when `/jsdd:verify` closes a spec, merge its requirements into a per-area document such as `docs/capabilities/<area>.md`. A spec then lists what it adds, modifies, or removes from that document, as OpenSpec does. Baselines already write the first version of an area. They become its starting point.

### 2. A lighter track for small changes

*From OpenSpec and BMAD's quick flow.*

**Gap:** the spec types are `feature | spike | baseline`. A one-line bug fix still goes through specify → plan → implement → verify. That ceremony is the most common complaint about SDD tools, and it pushes small work outside the kit.

**Shape:** a `fix` (or `chore`) type with:

- a short spec and no separate plan
- one or more tasks, each with a check, so "done means the check passed" still holds
- verify that runs the checks without a full reviewer pass

It still cites requirements and shows in `jsdd coverage`.

### 3. A fresh subagent for each task

*From GSD.*

**Gap:** `/jsdd:implement` works through all tasks in one session. On a long task list the context fills up and the work drifts. Reviews and research already run in fresh contexts. Implementation doesn't.

**Shape:** for each task, the main session gives an implementer subagent the spec, the relevant plan excerpt, and the acceptance criteria. The main session only coordinates: it claims tasks (`jsdd claim <ID> next`), hands them out, and runs `jsdd done`.

### 4. Drift detection after `done`

*From Kiro and Tessl.*

**Gap:** nothing notices when a later commit changes code that a closed spec described. Traceability runs from requirements to commits, but not back again.

**Shape:** `jsdd drift`. It maps the files each spec's tasks touched, using the commits that cite those tasks, and flags later commits that change those files while citing a different spec. `/jsdd:status` then shows which requirements may be stale, for example "FR-AUTH-02 may be stale".

## Medium value

### 5. Path-scoped standards

*From Kiro's steering files and Agent OS standards.*

**Gap:** `specs/constitution.md` is one global file. Area conventions (API style, UI patterns, migrations) either crowd it or go unwritten.

**Shape:** keep the standards for each area in Claude Code's path-scoped rules or nested `CLAUDE.md` files, so they load only when Claude edits that area. `/jsdd:baseline` drafts them from the conventions it finds.

### 6. A spec-quality review before planning

*From Spec Kit's `/speckit.clarify` and `/speckit.checklist`.*

**Gap:** the reviewer checks plans and finished specs, but not the spec itself before `/jsdd:plan`. A weak spec is found only at verify, where it costs the most to fix.

**Shape:** a reviewer pass at the start of `/jsdd:plan` that checks the spec:

- Is each requirement testable?
- Does each requirement have an acceptance criterion?
- Are the error, empty, and permission cases covered?

Optional domain checklists (security, accessibility, data retention) can add more checks.

### 7. Checking NFRs and risks

*From BMAD's QA gate (risk profile, test design, NFR assessment).*

**Gap:** `NFR-` rows exist, but nothing pushes them toward a check you can run. The plan's "Risks and unknowns" section isn't tied to the test strategy.

**Shape:** an NFR gets a check like any task, such as a benchmark command, a bundle-size limit, or an audit scan. The plan names which risks the test strategy must cover, and the reviewer enforces that.

### 8. Exporting to PRs and issues

*From Spec Kit's `/speckit.taskstoissues`.*

**Gap:** spec, acceptance criteria, and evidence are all on disk, but writing a PR description means retyping them.

**Shape:** `jsdd pr <ID>` prints a PR body from the spec, its acceptance criteria, and the evidence in `tasks.md`. Exporting tasks as GitHub issues is optional, as a second step.

## Considered and set aside

- **Support for other coding agents, and an extension or preset catalog.** Being built only for Claude Code is a deliberate trade-off (see the README). The hook-based enforcement depends on it. A cheaper middle ground is letting a project override files in `templates/`, for example with `specs/.templates/`.
- **Task complexity scoring** (Taskmaster). The plan reviewer can flag tasks that are too big without a separate feature.
- **Persona agents** (BMAD). They add ceremony without the guarantees the hooks and checks give.

## Suggested order

Ideas 1 and 2 first. Living specs make the kit useful over the long term, and a light track gets it used for everyday work. Idea 3 is the cheapest real quality gain, since it reuses the subagent setup the kit already has.
