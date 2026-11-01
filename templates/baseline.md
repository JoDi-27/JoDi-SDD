---
id: {{ID}}
title: "{{TITLE}}"
type: baseline
status: draft
phase: 0
depends_on: []
refs: []
updated: {{DATE}}
---

# {{ID}} · {{TITLE}}

<!--
A baseline records what an area of an existing product already does, so the requirements it covers count as done
without being built again. It is written by /jsdd:baseline from a survey of the code, confirmed by the user, and
closed by /jsdd:verify once every acceptance criterion's check passes. It describes the code as it is today: a bug
found along the way is a finding (a BACKLOG item or a new spec), never a requirement here.
Progress counts the checkboxes in Acceptance criteria. Each is ticked only by `jsdd done {{ID}} AC-n`, which runs its check.
-->

## Area

<!-- What this baseline covers and where it lives in the code (paths), and the work that prompted it: the PLAN.md item or feature about to change this area. -->

## Current behavior

<!--
Tag each with the docs/requirements.md IDs it documents: **R1** (FR-AUTH-01) When ...
Every requirement ID in refs is tagged on at least one R. EARS form, one behavior each, as the code behaves today.
Source each in the code: "(src/auth/login.ts)". Anything the survey could not settle is a [NEEDS CLARIFICATION: ...] marker.
-->

- **R1** (FR-XXX-NN) When ..., the system shall ... (`path/to/code`)

## Acceptance criteria

<!--
One per observable behavior; every R is covered by at least one. Each names its check: an existing test as a command
in backticks after "check:", run from the repository root, or "check: manual: <what a person checks>" when no test
covers it. Never write a new test here: a missing test is a finding.
-->

- [ ] **AC-1** Given ..., when ..., then ... · check: `<command>` → R1

## Findings

<!-- What the survey found that is not current behavior to keep: bugs, missing tests, dead code, behavior nobody could explain. Each says where it went (BACKLOG.md item, new spec, or dropped). -->

## Evidence

| Acceptance criterion | Result | Evidence (test, command output, manual check) |
| --- | --- | --- |
| AC-1 | | |

## Changelog

- {{DATE}} Created.
