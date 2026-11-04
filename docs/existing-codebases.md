# Existing codebases

How the kit comes to a project that already has code. For the four-step loop itself, read [Your first feature](first-feature.md).

The kit works on a project that already has code. It doesn't ask you to document the whole codebase up front. Instead, it records how an area works today just before new work first changes it:

1. `/jsdd:init` notices the existing code. It surveys the codebase for its areas, test command, and conventions, and plans the next milestone rather than an MVP. If the project already has its own `PLAN.md`, `docs/requirements.md`, `VISION.md`, PRD, or folder of ADRs, init offers to move it to `docs/legacy/` and carry its content into the kit's format, for you to confirm. It never overwrites a file.
2. Before a feature changes an area that has no requirements yet, `/jsdd:baseline <area>` reads that area's code and tests and drafts what it does today. You confirm which behaviour is intended. Those become requirement rows and a *baseline spec*, whose acceptance criteria are the existing tests.
3. `/jsdd:verify` runs those tests. When they pass, the baseline is done and its requirements count as done, without anything being rebuilt.
4. The feature spec then cites the rows it changes. Coverage shows them in progress again until the feature is verified.

Areas no work touches stay unrecorded. `/jsdd:specify` suggests a baseline when a feature reaches existing code that has none.

The survey and baseline steps in detail are in [specs/README.md](../starters/specs/README.md#baselines).
