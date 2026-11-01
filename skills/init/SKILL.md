---
name: init
description: Set up the current project for spec-driven development, then interview the user to fill in the starter files (intent, constitution, requirements, decisions and backlog, plan), or move a project from the install.sh kit to the plugin. Use when a project has no specs/constitution.md yet, when the starters are still empty, or when jsdd reports an old kit copy.
argument-hint: [--migrate] [notes about the product]
---

# Init

Arguments: $ARGUMENTS (`--migrate` is a flag; any other text is information from the user about the product, used to pre-fill answers below)

## 1. Check

- Run `jsdd init --dry-run` and show what it would add, update, or remove.
- If it stops because the project has the kit that install.sh copied in, explain that the plugin replaces it and the old hooks would run twice. Before migrating, look for project tweaks in the old files: the test command in `.claude/skills/sdd-plan/SKILL.md` and `.claude/agents/sdd-reviewer.md` (anything other than `make test`), and rules under "Architecture checklist" in the reviewer. Ask the user whether to migrate.

## 2. Run

- Run `jsdd init` (with `--migrate` if the user agreed).
- Copy any tweaks found in step 1 into the "Project specifics" section of `specs/constitution.md`. Add that section from the plugin's starter (`${CLAUDE_PLUGIN_ROOT}/starters/specs/constitution.md`) if the project's constitution predates it.

## 3. Report

- What was added, updated, and removed.
- That hooks load at session start, so the user starts a new session before relying on them.
- The next steps `jsdd init` printed, or `/jsdd:status` if the project is already filled in.

## 4. Interview

Continue only when the starters still hold placeholders: empty sections, `<...>` angle-bracket text, or `FR-XXX`. Otherwise stop after the report. This skill creates no spec.

Fill the files in dependency order (steps a to e), then finish (step f). For each file that is already filled in, skip it and say which. Rules for every step:

- Ask 3 or 4 questions at a time. Use AskUserQuestion where there are real options, with the suggested option first and labelled Recommended. Ask open-ended questions as a short numbered list in chat.
- Use what the user put in $ARGUMENTS and what the repository already says before asking. Never invent product facts: anything unknown stays a question, or a placeholder left on purpose.
- Write each file as soon as its answers are in, and show a few lines of what was written.

a. **Intent** (`docs/intent.md`). Ask: the product in one sentence, who it is for, why now, what the first version must and must not do, what success looks like in a year, and 2 to 5 principles. Keep the "First version" pointer to `PLAN.md`.

b. **Constitution** (`specs/constitution.md`). Draft one checkable product article per principle (P1, P2, …) and let the user accept, reword, or drop each. Ask for the test command and any architecture rules already decided, and write them under "Project specifics". Never edit the six engineering articles; record a change as an Amendments row. Delete the guidance comments of the sections you fill.

c. **Requirements** (`docs/requirements.md`). First the areas (3 to 8). Then the behaviours per area, in the user's words, each with its source. Then rank each M, S, C, or W, with a suggested ranking taken from the intent. A quality that applies to everything becomes an NFR row if it is measurable, or a product article if it is really a rule. IDs are `FR-<AREA>-nn` and `NFR-<AREA>-nn`. Write the file, then run `jsdd coverage` and show its summary line. If it prints no rows, fix the table shape.

d. **Decisions and spikes** (`docs/decisions.md`, `BACKLOG.md`). Turn each open point into one of: an ND row in `docs/decisions.md` "Still open" plus a one-line BACKLOG item with a suggested default; a spike in BACKLOG "Spikes" (the ND rows it settles, its dependencies, at most 3 goal questions); or, if already decided, a DEC row under Decided. Wants for after the MVP go to BACKLOG "Next". Write both files.

e. **Plan** (`PLAN.md`). Phase 0 holds the spikes and the foundations items, each tagged `· <IDs or groups>`. Phase 1 holds deliverables grouped from the Musts, with every Must in exactly one item; add Shoulds only if the user says so. Let the user reorder, and ask for the Phase 0 exit criteria. Write the file, keeping the opening paragraphs and the phase table with "Not started". Run `jsdd coverage --phase 1 --priority M --missing`: every Phase 1 Must should be listed. A Must that is missing from the list means an item is untagged; fix it.

f. **Finish.** Reread the six files (intent, constitution, requirements, decisions, BACKLOG, PLAN) for contradictions and fix them with the user. Run `jsdd status --write`. Offer to commit with the message `[meta] Initialise SDD kit`. Report: the files written; counts (requirements by priority, open decisions, spikes, Phase 1 items); the placeholders left on purpose; and the next step, which is to start a new session so the board loads, then run `/jsdd:status` and the first command it suggests (normally `/jsdd:spike`).
