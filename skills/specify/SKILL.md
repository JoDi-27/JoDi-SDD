---
name: specify
description: Create a new feature spec in specs/, or refine and clarify an existing one. Use when starting a new piece of work or picking up a PLAN.md item; spikes go to /jsdd:spike.
argument-hint: <idea | PLAN.md item | spec ID>
---

# Specify

Input: $ARGUMENTS

You write the WHAT and WHY of one slice of work. You do not plan or implement.

## 1. Load context

- Read `specs/README.md` (the workflow) and `specs/constitution.md`.
- Read the parts of `PLAN.md`, `BACKLOG.md`, and `docs/intent.md` that relate to the input. Use grep on headings rather than reading the intent doc whole.
- Find the requirements the work covers in `docs/requirements.md`: the IDs and groups after the `·` on the PLAN.md item, or a search by topic. Run `jsdd coverage <IDs or groups>` to see which already have a spec, and do not take one that another live spec covers unless the user agrees to split it.
- Run `jsdd status` to see existing specs, so you can set `depends_on` and avoid duplicates.

## 2. Create or open the spec

- If the input is a spec ID (for example `003`), claim it (`jsdd claim 003`), open `specs/003-*/spec.md`, and go to step 4. If another session holds it, stop and report who.
- Otherwise pick the type: `spike` if the work answers questions or settles decisions (all PLAN.md Phase 0 spikes), `feature` if it delivers working behavior.
- Spikes are created and run as an interview by `/jsdd:spike`, not by this skill. For a spike (new, or an existing spike ID), stop here and follow the `/jsdd:spike` skill instead.
- If the work is clearly larger than a few days, propose a split into several specs and confirm it with the user before creating them.
- Create it: `jsdd new feature "<title>"`, then claim the new ID with `jsdd claim <ID>`. Keep titles short and use the PLAN.md wording when the work comes from there.

## 3. Write the spec

Fill in every section of the template and delete the guidance comments.

- Frontmatter: `phase` (PLAN.md phase number), `depends_on` (spec IDs that must be done first), `refs` (the PLAN.md and BACKLOG.md items it delivers or settles, and every requirement ID from `docs/requirements.md` it covers, as quoted strings, for example `"FR-AUTH-05"`), `updated` (today).
- Problem, scope in and out, user scenarios, numbered requirements in EARS form, and acceptance criteria that are observable and testable. Every requirement is covered by at least one acceptance criterion. No technology, schemas, or code.
- `docs/requirements.md` is the product-level list; the spec makes its rows testable. Tag each R with the requirement IDs it refines, as `**R1** (FR-AUTH-05) When …`. Every ID in `refs` is tagged on at least one R; an R with no ID is allowed only for behavior the listed rows imply.
- Where a row is too vague to build from, add a `[NEEDS CLARIFICATION]` marker rather than guessing. When the user's answer changes what a row means, or adds behavior no row has, edit `docs/requirements.md` in the same change: reword the row, or add a new row with the next ID in its group and a priority (Article 4).
- A measurable NFR the spec delivers (for example a response time) becomes an acceptance criterion. NFRs that apply to everything are product articles, checked in the plan, and need no R.
- Never guess. Anything unknown becomes `[NEEDS CLARIFICATION: <specific question>]` in the section where it matters.

## 4. Clarify

- Collect the open markers. Ask the user the most important ones (up to five, those that change scope or behavior most) in a single AskUserQuestion call, with a recommended answer first where you have one.
- Write each answer into the spec where it belongs, and record it under Open questions as `Q: … A: … (date)`. Leave unanswered markers in place.
- Add a changelog line for what changed.

## 5. Finish

- Keep `status: draft`. Release the spec (`jsdd release <ID>`) and run `jsdd status --write`.
- Report in a few lines: the spec path, the requirement IDs it covers, any rows of `docs/requirements.md` you changed or added, the number of open questions left, and the next step: the user reviews the spec, then runs `/jsdd:plan <ID>`.
