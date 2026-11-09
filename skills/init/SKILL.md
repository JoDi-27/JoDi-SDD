---
name: init
description: Set up the current project for spec-driven development, then interview the user to fill in the starter files (intent, constitution, requirements, decisions and backlog, plan), or move a project from the install.sh kit to the plugin. Works on new projects and on existing codebases, where it surveys the code and plans baselines for the areas the next work touches. Use when a project has no specs/constitution.md yet, when the starters are still empty, or when jsdd reports an old kit copy.
argument-hint: [--migrate] [notes about the product]
---

# Init

Arguments: $ARGUMENTS (`--migrate` is a flag; any other text is information from the user about the product, used to pre-fill answers below)

## 1. Check

- Run `jsdd init --dry-run` and show what it would add, update, keep, or remove.
- **Existing project.** If the dry run prints "Existing code", ask with AskUserQuestion whether this is an existing product to bring under the kit (brownfield) or a new one starting in this repository. Recommend brownfield when there are more than a handful of commits or files. Brownfield changes the interview (step 4) and nothing else.
- **Files in another format.** For each path marked `keep`, the project has its own document under a kit name, which the kit cannot read. Show its first lines and ask whether to move it to `docs/legacy/<name>` (with `git mv` in a git repository), so init adds the kit's version and the interview folds the old content in. Recommend moving. A file the user wants left in place stays, and the step of the interview that fills it is skipped, with a warning that `jsdd` cannot read it (for `docs/requirements.md`, `SDD_REQUIREMENTS` can point coverage at a kit-format file elsewhere).
- **Documents elsewhere.** The project may already say what a starter should hold under another name. Read each `source` path the dry run lists, plus the README, `CLAUDE.md`, and the other Markdown files at the top level and in `docs/`. Judge by content, not name: a listed file may cover nothing, or a different starter, and a file the dry run missed may be the intent. Show the user the mapping you propose, one line per document (`VISION.md` → intent, `README.md` "About" → intent, `docs/adr/` → decisions), and let them confirm or correct it. A whole file that does a starter's job: recommend moving it to `docs/legacy/<name>` (with `git mv` in a git repository), as for a `keep` file. Part of a file, such as a README section: it stays where it is and is read as a source. If the project has existing code and nothing covers the intent, ask whether it is written down anywhere (a path, a link, or pasted text).
- If it stops because the project has the kit that install.sh copied in, explain that the plugin replaces it and the old hooks would run twice. Before migrating, look for project tweaks in the old files: the test command in `.claude/skills/sdd-plan/SKILL.md` and `.claude/agents/sdd-reviewer.md` (anything other than `make test`), and rules under "Architecture checklist" in the reviewer. Ask the user whether to migrate.
- **Old kit references.** For each `stale` line under "Old kit references", the file (often `CLAUDE.md`) still tells sessions to use the install.sh kit: `/sdd-specify` and the other `/sdd-*` commands, `specs/_kit/sdd`, or `.claude/skills/sdd-*`. Once the old copy is removed, those commands do not exist. Show the lines and propose the replacement for each: `/sdd-<step>` → `/jsdd:<step>`, `specs/_kit/sdd <command>` → `jsdd <command>` (`release --done` → `jsdd done <ID> <Tn>`), and a row about `.claude/skills/sdd-*` dropped. Recommend rewriting them.

## 2. Run

- Move the files the user agreed to into `docs/legacy/`.
- Run `jsdd init` (with `--migrate` if the user agreed).
- Rewrite the old kit references the user agreed to, then run `jsdd init --dry-run` again: it lists no `stale` lines once they are all gone.
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
- When a file's old version is in `docs/legacy/`, or the user confirmed a source for it in step 1, read it first and carry its content into the kit's version, in the kit's format, asking the user only about what does not fit. Tell the user the legacy copy can be deleted once they are happy.

**Brownfield.** On an existing product, the interview records what exists only where the next work will land; it never inventories the whole codebase. Before step a, launch the `sdd-surveyor` agent in `areas` mode, and ask the intent questions while it runs. The steps change as marked **Brownfield** below. Areas the next milestone does not touch get no rows: that is expected, and the report says so.

a. **Intent** (`docs/intent.md`). Ask: the product in one sentence, who it is for, why now, what the first version must and must not do, what success looks like in a year, and 2 to 5 principles. Keep the "First version" pointer to `PLAN.md`.
   **Brownfield:** ask what the product does today and who uses it, then what the next milestone changes and why now. Rename "First version" to "Next milestone", keeping the pointer to `PLAN.md`.

b. **Constitution** (`specs/constitution.md`). Draft one checkable product article per principle (P1, P2, …) and let the user accept, reword, or drop each. Ask for the test command and any architecture rules already decided, and write them under "Project specifics". Never edit the six engineering articles; record a change as an Amendments row. Delete the guidance comments of the sections you fill.
   **Brownfield:** propose the test command from the survey (or the dry run's "test commands found") and say whether it passed. Offer the survey's conventions as Architecture checklist rules, one at a time, for the user to accept or drop: only rules the code already follows, since the reviewer will hold new work to them.

c. **Requirements** (`docs/requirements.md`). First the areas (3 to 8). Then the behaviours per area, in the user's words, each with its source. Then rank each M, S, C, or W, with a suggested ranking taken from the intent. A quality that applies to everything becomes an NFR row if it is measurable, or a product article if it is really a rule. IDs are `FR-<AREA>-nn` and `NFR-<AREA>-nn`. Write the file, then run `jsdd coverage` and show its summary line. If it prints no rows, fix the table shape.
   **Brownfield:** use the survey's areas and ask which ones the next milestone touches. For those, add rows only for new behavior the milestone brings. Behavior that exists today is recorded by a baseline (step e), not here, so leave each touched area's existing behavior out for now and note the area.

d. **Decisions and spikes** (`docs/decisions.md`, `BACKLOG.md`). Turn each open point into one of: an ND row in `docs/decisions.md` "Still open" plus a one-line BACKLOG item with a suggested default; a spike in BACKLOG "Spikes" (the ND rows it settles, its dependencies, at most 3 goal questions); or, if already decided, a DEC row under Decided. Wants for after the MVP go to BACKLOG "Next". Write both files.
   **Brownfield:** add the survey's "choices already made" as DEC rows (why: "chosen before the kit" unless the user knows the reason), so plans respect them.

e. **Plan** (`PLAN.md`). Phase 0 holds the spikes and the foundations items, each tagged `· <IDs or groups>`. Phase 1 holds deliverables grouped from the Musts, with every Must in exactly one item; add Shoulds only if the user says so. Let the user reorder, and ask for the Phase 0 exit criteria. Write the file, keeping the opening paragraphs and the phase table with "Not started". Run `jsdd coverage --phase 1 --priority M --missing`: every Phase 1 Must should be listed. A Must that is missing from the list means an item is untagged; fix it.
   **Brownfield:** rename Phase 0 to "Baseline, spikes, and foundations" and Phase 1 to "Next milestone", in the headings and the phase table, and reword the opening line to plan toward the next milestone. Phase 0 starts with a "Baselines" list: one item per touched area, `- [ ] **Baseline: <area>**`, run with `/jsdd:baseline <area>`. Do not run the baselines here; each is its own step.

f. **Finish.** Reread the six files (intent, constitution, requirements, decisions, BACKLOG, PLAN) for contradictions and fix them with the user. If files moved to `docs/legacy/`, search the project for their old paths (outside `docs/legacy/` and done specs) and offer to point each reference at the kit file that replaced it, such as `PRODUCT_INTENT.md` → `docs/intent.md` in `CLAUDE.md`. Run `jsdd status --write`. Offer to commit with the message `[meta] Initialise SDD kit`. Report: the files written; counts (requirements by priority, open decisions, spikes, Phase 1 items); the placeholders left on purpose; and the next step, which is to start a new session so the board loads, then run `/jsdd:status` and the first command it suggests (normally `/jsdd:spike`, or `/jsdd:baseline <area>` on a brownfield project). On a brownfield project, also list the areas with no rows yet, and say that each gets a baseline when work first touches it. Last, in one line and only as an offer: once a few specs have gone through by hand, `/jsdd:auto setup` can let runs plan, build, and verify specs without asking (autonomous mode); nothing changes unless the team commits a charter.
