---
id: {{ID}}
title: "{{TITLE}}"
type: feature
status: draft
phase:
depends_on: []
refs: []
updated: {{DATE}}
---

# {{ID}} · {{TITLE}}

<!--
spec.md says WHAT and WHY. No technology, schemas, class names, or code: those go in plan.md.
Write anything unknown as a NEEDS CLARIFICATION marker, for example:
  - [NEEDS CLARIFICATION: can a run have more than one owner?]
and never guess. /jsdd:plan refuses to start while markers remain.
Delete these comments once the section is filled in.
-->

## Problem

<!-- Why this matters now, who it is for, and which PLAN.md item and docs/requirements.md rows it delivers. -->

## Scope

**In:**

**Out:**
<!-- Each "out" item says where it goes instead: BACKLOG.md "Next", or another spec. -->

## User scenarios

<!-- The main flows, from the actor's point of view. Number them so requirements can refer to them. -->

### S1 · <name>

<actor> wants to <goal>, so that <outcome>.

1. ...

## Requirements

<!--
Tag each with the docs/requirements.md IDs it refines: **R1** (FR-AUTH-05) When ...
Every requirement ID in refs is tagged on at least one R.
Numbered, one behavior each, in EARS form:
  Ubiquitous:   The <system> shall <response>.
  Event:        When <trigger>, the <system> shall <response>.
  State:        While <state>, the <system> shall <response>.
  Unwanted:     If <condition>, then the <system> shall <response>.
-->

- **R1** (FR-XXX-NN) The <system> shall ...

## Acceptance criteria

<!-- Observable and testable. Every requirement is covered by at least one. /jsdd:verify checks each one and records evidence in tasks.md. -->

- **AC-1** Given ..., when ..., then ...

## Capability changes

<!--
What this spec does to the capability documents in docs/capabilities/ (one per requirement group, for example
docs/capabilities/auth.md for FR-AUTH). One line per row of docs/requirements.md that an R is tagged with:
  adds      the row has no entry in its capability document yet
  modifies  the row has an entry, and this spec changes the behavior it describes
  removes   the behavior goes away; say why under Scope, and set the row's priority to W in docs/requirements.md
/jsdd:verify merges these lines into the capability documents when it closes the spec.
-->

| Row | Change | Requirements |
| --- | --- | --- |
| FR-XXX-NN | adds | R1 |

## Open questions

<!-- Resolved questions stay here with their answer: "Q: ... A: ... (decided by, date)". -->

## Changelog

- {{DATE}} Created.
