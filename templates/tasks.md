# {{ID}} · Tasks: {{TITLE}}

<!--
Rules:
- Ordered. A task starts once every task before it is ticked, except that consecutive tasks marked [P]
  (written right after the ID: **T3** [P]) can run at the same time, in different sessions.
- Small: half a day at most, and each one leaves the build and tests green.
- Each names the files or modules it touches, how it is checked, and the acceptance criteria it serves (→ AC-n).
- Write the check as a command in backticks after "check:", which `jsdd done <ID> <Tn>` runs from the
  repository root, or as "check: manual: <what a person checks>" when no command can prove it.
- Prefer test first: a task that adds behavior starts by adding the failing test for it.
- Follow-up tasks that /jsdd:plan adds for gaps a verification found go after the last task, under
  "### A<n> · Follow-up from verify round <r>", and name the gap they serve: → AC-2 (A1/G1).
- Tick a task only with `jsdd done`, which ticks it only when its check passes. New work found along the way becomes a new task, not a silent extra.
-->

## Tasks

- [ ] **T1** <imperative description> · `path/or/module` · check: `<command>` → AC-1

## Evidence

| Acceptance criterion | Result | Evidence (test, command output, manual check) |
| --- | --- | --- |
| AC-1 | | |
