# Constitution

The non-negotiable rules every spec and plan is checked against. Each plan has a "Constitution check" that names the articles it touches.

`docs/intent.md` stays the source of product intent; the product articles distill the parts of it that constrain day-to-day design. To change an article, record the decision in the amendments log at the bottom, and update the intent doc if the product intent changed too.

## Product articles

<!-- Distill the principles in docs/intent.md into rules a reviewer can check a plan against. One rule each, testable, numbered P1, P2, …
Example: - **P1 Tenants are isolated.** Every record belongs to one tenant, and isolation is enforced in the database, not only in application code. -->

## Engineering articles

1. **Happy path first.** Build the simplest version that moves the current roadmap item forward. Anything else goes to the backlog, not into the current spec.
2. **Tests prove acceptance criteria.** Every acceptance criterion maps to an automated test or a recorded manual check. A task is done only when its check passes.
3. **Small, traceable increments.** One spec is one reviewable slice (a few days at most; split it otherwise). One task is about one commit, and commit messages start with the spec and task ID, for example `[003] T2 Add invite table`.
4. **Specs are living.** When implementation shows the spec or plan is wrong, update them first, then the code. Code never silently diverges from its spec.
5. **Decisions are written down.** Every choice between real alternatives gets a row in the plan's Decisions table (or a spike's Recommendation). A choice that settles an open decision moves its row in `docs/decisions.md` from Still open to Decided, and ticks the backlog item.
6. **Verify current docs.** Before using a library, SDK, or tool API, check its current documentation rather than relying on memory, and note the version in the plan.

## Project specifics

What the kit's skills and the reviewer need to know about this project.

- **Test command:** `make test` <!-- the command that runs the whole suite, as CI does. /jsdd:verify runs it (jsdd suite) before a spec closes; task checks use narrower commands. test_command in specs/jsdd.yml, if set, wins over this line. -->

### Architecture checklist

<!-- Rules the sdd-reviewer agent checks every plan and change against, as the design settles (layering, ports and adapters, tenancy, and so on). Keep each rule checkable from the code. -->

## Amendments

| Date | Article | Change | Why |
| --- | --- | --- | --- |
