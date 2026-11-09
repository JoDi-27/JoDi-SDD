---
name: specify
description: Create a new feature spec in specs/, or refine and clarify an existing one, including the spec changes a verification found. Use when starting a new piece of work, picking up a PLAN.md item, or when /jsdd:verify left a spec in draft for a spec change; spikes go to /jsdd:spike.
argument-hint: <idea | PLAN.md item | spec ID>
---

# Specify

Input: $ARGUMENTS

You write the WHAT and WHY of one slice of work. You do not plan or implement.

**Runtime mode.** Run `jsdd mode` first. The decision points below are marked with their gate, like (gate `spec.approve`). In `manual` mode every gate is `ask`: a person decides, as the step says. If the mode is anything else, stop and tell the user that this skill runs only in manual mode for now.

## 1. Load context

- Read `specs/README.md` (the workflow) and `specs/constitution.md`.
- Read the parts of `PLAN.md`, `BACKLOG.md`, and `docs/intent.md` that relate to the input. Use grep on headings rather than reading the intent doc whole.
- Find the requirements the work covers in `docs/requirements.md`: the IDs and groups after the `·` on the PLAN.md item, or a search by topic. Run `jsdd coverage <IDs or groups>` to see which already have a spec, and do not take one that another live spec covers unless the user agrees to split it.
- Read how the area works now: `docs/capabilities/<group>.md` for each requirement group the work touches (`auth.md` for `FR-AUTH`), the entries of the rows it changes. Run `jsdd capabilities <groups>` to see which rows have an entry and which other live specs are about to change them.
- Run `jsdd status` to see existing specs, so you can set `depends_on` and avoid duplicates.
- **Existing code.** If the work changes code that already exists in an area with no rows in `docs/requirements.md`, suggest `/jsdd:baseline <area>` first: it records how the area works today, so this spec can cite the rows it changes and the existing tests guard against regressions. The user may skip it for a small change; then this spec adds the rows it needs. When the area has a baseline that is not `done`, add it to `depends_on`.

## 2. Create or open the spec

- If the input is a spec ID (for example `003`), claim it (`jsdd claim 003`), open `specs/003-*/spec.md`, and go to step 4. If another session holds it, stop and report who. If the spec is `draft` and its folder has a `verify-report.md` whose Decision is `approved`, go to step 3a first.
- Otherwise pick the type: `spike` if the work answers questions or settles decisions (all PLAN.md Phase 0 spikes), `feature` if it delivers working behavior.
- Spikes are created and run as an interview by `/jsdd:spike`, not by this skill. For a spike (new, or an existing spike ID), stop here and follow the `/jsdd:spike` skill instead. The same goes for a baseline (`type: baseline`): follow `/jsdd:baseline`.
- If the work is clearly larger than a few days, propose a split into several specs and confirm it with the user before creating them (gate `spec.split`).
- Create it: `jsdd new feature "<title>"`, then claim the new ID with `jsdd claim <ID>`. Keep titles short and use the PLAN.md wording when the work comes from there.

## 3. Write the spec

Fill in every section of the template and delete the guidance comments.

- Frontmatter: `phase` (PLAN.md phase number), `depends_on` (spec IDs that must be done first), `refs` (the PLAN.md and BACKLOG.md items it delivers or settles, and every requirement ID from `docs/requirements.md` it covers, as quoted strings, for example `"FR-AUTH-05"`), `updated` (today).
- Problem, scope in and out, user scenarios, numbered requirements in EARS form, and acceptance criteria that are observable and testable. Every requirement is covered by at least one acceptance criterion. No technology, schemas, or code.
- `docs/requirements.md` is the product-level list; the spec makes its rows testable. Tag each R with the requirement IDs it refines, as `**R1** (FR-AUTH-05) When …`. Every ID in `refs` is tagged on at least one R; an R with no ID is allowed only for behavior the listed rows imply.
- A spec that changes behavior a baseline recorded cites the same row and tags the R that changes it, for example `**R2** (FR-AUTH-01) When a reset token is valid, …`. Reword the row in `docs/requirements.md` to the new behavior in the same change. Until this spec is done, `jsdd coverage` shows the row as in progress again.
- Where a row is too vague to build from, add a `[NEEDS CLARIFICATION]` marker rather than guessing. When the user's answer changes what a row means, or adds behavior no row has, edit `docs/requirements.md` in the same change: reword the row, or add a new row with the next ID in its group and a priority (Article 4).
- **Capability changes.** One line per row an R is tagged with: `adds` when the row has no entry in its capability document, `modifies` when it has one and the spec changes that behavior (write the R from the entry, so nothing it already says is lost by accident), `removes` when the behavior goes away. A row whose done baseline `jsdd capabilities` lists as not merged also counts as having an entry: read the baseline's Rs instead, and write `modifies`. A removal says why under Scope, and its row in `docs/requirements.md` keeps its ID but gets priority `W` and "(removed by <ID>)" at the end of its text. When another live spec also changes the row, say so to the user and set `depends_on` if one must close first.
- A measurable NFR the spec delivers (for example a response time) becomes an acceptance criterion. NFRs that apply to everything are product articles, checked in the plan, and need no R.
- Never guess. Anything unknown becomes `[NEEDS CLARIFICATION: <specific question>]` in the section where it matters.

## 3a. Revise the spec for a verification

A verification found gaps and the user chose to change the spec for some of them. The plan and tasks were already built from the old spec; `/jsdd:plan` will amend them after you.

- Read `verify-report.md`. Revise only for the kept gaps whose action (or chosen option) is a spec change; leave the others for `/jsdd:plan`.
- For each, rework the R or AC with the user, following the rules in step 3, and update the Capability changes lines it affects. When a gap leaves the behavior itself unclear, add a `[NEEDS CLARIFICATION]` marker and ask it in step 4.
- Add one changelog line per gap that names the round and gap: "Verify round 2/G3: R3 reworded to match the code." Do not edit the report, the plan, or the tasks.

## 4. Clarify

- Collect the open markers. Ask the user the most important ones (up to five, those that change scope or behavior most) in a single AskUserQuestion call, with a recommended answer first where you have one (gate `spec.clarify`).
- Write each answer into the spec where it belongs, and record it under Open questions as `Q: … A: … (date)`. Leave unanswered markers in place.
- Add a changelog line for what changed.

## 5. Finish

- Keep `status: draft`. Release the spec (`jsdd release <ID>`) and run `jsdd status --write`.
- Report in a few lines: the spec path, the requirement IDs it covers, any rows of `docs/requirements.md` you changed or added, the rows it adds, modifies, or removes in the capability documents, the number of open questions left, and the next step: the user reviews the spec, then runs `/jsdd:plan <ID>` (after a verification, it plans the rest of the gaps as an amendment).
