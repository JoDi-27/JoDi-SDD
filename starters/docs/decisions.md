# Decisions

The register of decisions. Settled choices get a `DEC-nn` row; open ones keep their `ND-nn` row under "Still open", with a one-line item in [BACKLOG.md](../BACKLOG.md). A spike's Recommendation, or a plan's cross-cutting Decisions row, settles an ND into a DEC here with the same reasoning, and the BACKLOG item is ticked in the same change. Plans cite the `DEC-nn` they rely on. In autonomous mode, the `sdd-product` agent's decisions go under "Assumed" as `AS-nn` rows until the owner confirms one (it becomes a `DEC-nn` row) or rejects it (it is removed, with a BACKLOG item or a spec to undo it).

## Decided

| ID | Decision | Choice | Why | Date |
|---|---|---|---|---|

## Still open

| ID | Decision | Options | Current leaning | Source |
|---|---|---|---|---|

## Assumed

| ID | Decision | Choice | Class | Basis | Reversal | Spec | Date |
|---|---|---|---|---|---|---|---|
