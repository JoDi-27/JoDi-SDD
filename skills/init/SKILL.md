---
name: init
description: Set up the current project for spec-driven development, or move a project from the install.sh kit to the plugin. Use when a project has no specs/constitution.md yet, or when jsdd reports an old kit copy.
argument-hint: "[--migrate]"
---

# Init

Arguments: $ARGUMENTS

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
