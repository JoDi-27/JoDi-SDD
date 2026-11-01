# Plan

Phased plan toward the first version described in [docs/intent.md](docs/intent.md). Open questions and spikes live in [BACKLOG.md](BACKLOG.md); settled choices live in [docs/decisions.md](docs/decisions.md).

Each checklist item is delivered through one or more specs in `specs/` (see [specs/README.md](specs/README.md)); `specs/STATUS.md` shows progress. A spec's `refs` quote the item it delivers and the requirement IDs from [docs/requirements.md](docs/requirements.md) it covers.

Items end with the requirements they cover after a `·`: a group such as `FR-AUTH` means every requirement in it, and a full ID means only that one. `specs/_kit/sdd coverage --phase 1 --priority M --missing` lists the Phase 1 Musts that still need a spec.

| Phase | Goal | Status |
| --- | --- | --- |
| 0. Spikes and foundations | Settle the unknowns that can change the design, and stand up an empty but deployed skeleton | Not started |
| 1. MVP | The first version | Not started |
| 2+. Later | Work through `BACKLOG.md` "Next", in priority order | Not started |

## Phase 0: Spikes and foundations

### Spikes

Each is a spike spec run with `/sdd-spike`; their goal questions are in `BACKLOG.md` "Spikes".

- [ ] **<spike name>**

### Foundations

Each item becomes a feature spec (`/sdd-specify`), split if it takes more than a few days.

- [ ] Repository layout, build, and test command. · NFR-XXX-01

### Exit criteria

- 

## Phase 1: MVP

- [ ] <deliverable> · FR-XXX
