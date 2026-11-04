---
name: baseline
description: Record what one area of an existing product already does, before new work changes it. Surveys the area's code with the sdd-surveyor agent, confirms its current behavior with the user, writes the requirement rows, and creates a baseline spec whose acceptance criteria are the existing tests. Use in a brownfield project when work is about to touch an area that has no rows in docs/requirements.md, or when /jsdd:init or /jsdd:specify suggests it.
argument-hint: <area | baseline spec ID> [what is about to change]
---

# Baseline

Input: $ARGUMENTS

A baseline writes down how an area works today, so the work that changes it has rows to cite and the kit counts existing behavior as done. It documents; it never changes code or writes tests. Survey only the area the coming work touches, never the whole product.

## 1. Open the baseline

- If the input starts with the ID of a baseline spec, open `specs/<ID>-*/spec.md`, claim it (`jsdd claim <ID>`), and continue at the first step that is not finished. If another session holds it, stop and report who.
- Otherwise run `jsdd status` and `jsdd coverage` for the area's group. If a baseline for the area exists, open it instead. If the area already has rows covered by done specs, say so and ask whether a baseline is still needed.
- Create it: `jsdd new baseline "<Area>: current behavior"`, then claim it with `jsdd claim <ID>`. Fill in the frontmatter (`phase: 0`, `refs` with the PLAN.md item that prompted it, if any) and the Area section.

## 2. Survey

- Launch the `sdd-surveyor` agent in `area` mode with the area, its paths if known, the work about to change it (from $ARGUMENTS or the PLAN.md item), the group prefix, and the area's existing rows of `docs/requirements.md`.
- While it runs, read `specs/constitution.md` for the test command and the related PLAN.md and BACKLOG.md items.

## 3. Confirm with the user

The survey says what the code does; the user says which of it is intended.

- Show the candidate rows as a table: behavior, code, tests, passing, suggested priority. Ask the user to confirm, reword, re-rank, or drop each. A behavior the user calls a bug is not a row: it goes to Findings.
- Ask the survey's questions for the owner, 3 or 4 at a time, with AskUserQuestion where there are real options (suggested option first, labelled Recommended).
- Never invent behavior. A row the user cannot confirm stays out, or stays in with a `[NEEDS CLARIFICATION: …]` marker in the spec.

## 4. Write

- **Requirements.** Add the confirmed rows to `docs/requirements.md` under the area's heading (create it if missing), with IDs `FR-<AREA>-nn` after the group's last, the source `code: <path>` (plus the user, where they changed it), and the priority. Never renumber existing rows.
- **Spec.** Fill in the baseline spec: `refs` gets every row ID it documents (quoted, for example `"FR-AUTH-01"`); Current behavior gets one EARS requirement per behavior, tagged with its row and its code path; Acceptance criteria get one checkbox per observable behavior, each with its check: an existing test as a command in backticks, or `check: manual: <what a person checks>` when no test covers it. Delete the guidance comments of the sections you fill. A baseline has no Capability changes table: when `/jsdd:verify` closes it, every row in `refs` is added to `docs/capabilities/<group>.md`. A row that already has an entry there does not belong in a new baseline; if one turns up, the entry and the code disagree, so settle it with the user and record it under Findings.
- **Findings.** Record each finding in the spec with where it went: a `BACKLOG.md` "Next" item (missing tests, small bugs), a new feature spec if the user wants it fixed now, or dropped. Ask the user before creating specs.
- **Decisions and rules.** A choice the code already made that the work relies on becomes a DEC row in `docs/decisions.md` (why: "chosen before the kit" unless the user knows the reason). A convention the user wants enforced goes under "Architecture checklist" in `specs/constitution.md`.
- **Plan.** Tag the area's "Baseline" item in `PLAN.md` Phase 0 with the IDs it documents (`· FR-AUTH-01, FR-AUTH-02`), adding the item if there is none, so `/jsdd:verify` can tick it.
- Run `jsdd coverage <group>` and show its rows: the new rows show the baseline as their spec.

## 5. Hand over

- If no `[NEEDS CLARIFICATION` markers remain, set `status: in-progress` (the behavior is confirmed and waits for verification) and add a changelog line. Otherwise keep `draft` and list the open markers.
- Release the spec (`jsdd release <ID>`) and run `jsdd status --write`.
- Report: the spec path, the rows added (by priority), the findings and where they went, and the next step: `/jsdd:verify <ID>`, which runs every check and closes the baseline. Then the work that prompted it: `/jsdd:specify`, citing the rows it changes.
