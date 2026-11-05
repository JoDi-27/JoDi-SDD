# Roadmap

Feature ideas for JoDi-SDD, drawn from a comparison with other spec-driven development frameworks: [Spec Kit](https://github.com/github/spec-kit), Kiro (and cc-sdd), OpenSpec, BMAD, Taskmaster, Tessl, and GSD. Nothing here is committed to. Each idea says what's missing today, where it comes from, and a rough shape for it. Open an issue before starting one, as described in [CONTRIBUTING.md](CONTRIBUTING.md).

Already covered, so not listed: a constitution, EARS requirements, `NEEDS CLARIFICATION` markers, requirement-to-commit traceability, spikes, brownfield baselines, and parallel claims between sessions on one machine (idea 9 extends them to several people).

## High value

### 1. Living capability specs

*From OpenSpec.* **Built:** see `docs/capabilities/` and `jsdd capabilities` in [CHANGELOG.md](CHANGELOG.md) (Unreleased).

**Gap:** each spec is one change. Once a spec is `done`, its detailed behavior stays in its own folder, and `docs/requirements.md` holds only one line per requirement. Nothing says how an area works now without reading every spec that touched it.

**Shape:** when `/jsdd:verify` closes a spec, merge its requirements into a per-area document such as `docs/capabilities/<area>.md`. A spec then lists what it adds, modifies, or removes from that document, as OpenSpec does. Baselines already write the first version of an area. They become its starting point.

### 2. A lighter track for small changes

*From OpenSpec and BMAD's quick flow.*

**Gap:** the spec types are `feature | spike | baseline`. A one-line bug fix still goes through specify → plan → implement → verify. That ceremony is the most common complaint about SDD tools, and it pushes small work outside the kit.

**Shape:** a `fix` (or `chore`) type with:

- a short spec and no separate plan
- one or more tasks, each with a check, so "done means the check passed" still holds
- verify that runs the checks without a full reviewer pass

It still cites requirements and shows in `jsdd coverage`.

### 3. A fresh subagent for each task

*From GSD.*

**Gap:** `/jsdd:implement` works through all tasks in one session. On a long task list the context fills up and the work drifts. Reviews and research already run in fresh contexts. Implementation doesn't.

**Shape:** for each task, the main session gives an implementer subagent the spec, the relevant plan excerpt, and the acceptance criteria. The main session only coordinates: it claims tasks (`jsdd claim <ID> next`), hands them out, and runs `jsdd done`.

### 4. Drift detection after `done`

*From Kiro and Tessl.*

**Gap:** nothing notices when a later commit changes code that a closed spec described. Traceability runs from requirements to commits, but not back again.

**Shape:** `jsdd drift`. It maps the files each spec's tasks touched, using the commits that cite those tasks, and flags later commits that change those files while citing a different spec. `/jsdd:status` then shows which requirements may be stale, for example "FR-AUTH-02 may be stale".

## Medium value

### 5. Path-scoped standards

*From Kiro's steering files and Agent OS standards.*

**Gap:** `specs/constitution.md` is one global file. Area conventions (API style, UI patterns, migrations) either crowd it or go unwritten.

**Shape:** keep the standards for each area in Claude Code's path-scoped rules or nested `CLAUDE.md` files, so they load only when Claude edits that area. `/jsdd:baseline` drafts them from the conventions it finds.

### 6. A spec-quality review before planning

*From Spec Kit's `/speckit.clarify` and `/speckit.checklist`.*

**Gap:** the reviewer checks plans and finished specs, but not the spec itself before `/jsdd:plan`. A weak spec is found only at verify, where it costs the most to fix.

**Shape:** a reviewer pass at the start of `/jsdd:plan` that checks the spec:

- Is each requirement testable?
- Does each requirement have an acceptance criterion?
- Are the error, empty, and permission cases covered?

Optional domain checklists (security, accessibility, data retention) can add more checks.

### 7. Checking NFRs and risks

*From BMAD's QA gate (risk profile, test design, NFR assessment).*

**Gap:** `NFR-` rows exist, but nothing pushes them toward a check you can run. The plan's "Risks and unknowns" section isn't tied to the test strategy.

**Shape:** an NFR gets a check like any task, such as a benchmark command, a bundle-size limit, or an audit scan. The plan names which risks the test strategy must cover, and the reviewer enforces that.

### 8. Exporting to PRs and issues

*From Spec Kit's `/speckit.taskstoissues`.*

**Gap:** spec, acceptance criteria, and evidence are all on disk, but writing a PR description means retyping them.

**Shape:** `jsdd pr <ID>` prints a PR body from the spec, its acceptance criteria, and the evidence in `tasks.md`. Exporting tasks as GitHub issues is optional, as a second step.

### 9. Claims shared through the git remote

*From the kit's own limits, not another framework.*

**Gap:** claims live in `.git/sdd-claims`, which is untracked and local. They coordinate sessions across worktrees on one machine, but two people on their own clones never see each other's claims. Both can pick the same task, and `jsdd new` can give them the same spec ID. The README FAQ's "can two people work on one project?" answer reads as if this were covered.

**Shape:** an opt-in remote mode (`git config jsdd.claims remote`, remote from `jsdd.claimsRemote`, default `origin`). Each claim becomes a ref on the remote, `refs/sdd-claims/<name>` (`003`, `003-T4`, `id-004`). The ref points at an empty-tree commit whose message holds `owner=`, `user=`, `host=`, `since=`, `at=`, and `state=active|done`. Every update is a compare-and-swap that the remote enforces:

- **claim:** `git push --force-with-lease=<ref>: origin <sha>:<ref>`, which succeeds only if the ref does not exist yet
- **release:** a delete leased on this session's own sha, or on the sha just fetched with `--force`
- **done:** a new `state=done` commit, leased on this session's own sha
- **reads** (`status`, `next`, `claims`, hooks): `git fetch --prune` of `refs/sdd-claims/*` into a local cache, shown as "claims as of HH:MM"
- **new:** `next_id` also counts remote `id-*` refs and the specs on `origin/main`
- **prune:** the same rules as today, checked against `origin/main`, with leased deletes

A prototype with a bare repository and two clones gave exactly one winner in each of 20 simultaneous claims, and refused a delete leased on the wrong sha. A default clone fetches none of these refs, and they are not branches. A claim fails closed when the remote is unreachable (`--local` overrides that), while reads fall back to the cache. Local mode stays the default.

**Open questions:**

- *Finished is not merged.* Another person can claim T5 as soon as T4 is marked done, while T4's code is still on its author's branch. One option is to record T4's branch in its done commit and have `claim` say "T4 is on `alice/003`; merge or rebase onto it first". The other is to gate on the tick reaching `origin/main`.
- *Hosts.* GitHub and GitLab should accept custom ref namespaces, but test it on each host before relying on it. Gerrit and locked-down setups may refuse them.
- *Latency.* Each claim costs a fetch and a push. Reuse a fetch made in the last ~30 seconds so the session-start hook's `status` and `claims` cost one round trip. Bash 3.2 on macOS has no `timeout`, so a remote that hangs needs a background-and-kill wrapper.
- *Switching modes.* Refuse to switch while local claims are held, or move them to the remote with `jsdd claims --push-local`.
- These refs coordinate people who cooperate. They don't enforce anything: anyone with push access can delete them.

**Touches:**

- `bin/jsdd`: put storage functions (`claim_exists`, `claim_state`, `claim_list`, `claim_take`, `claim_mark_done`, `claim_drop`) behind the ~20 places that read `$CLAIMS` directly, plus `next_id`, `cmd_new`, `prune_claims`, and the config and identity setup
- `hooks/stop-claims.sh`: replace its copy of the storage logic with a `jsdd` call
- `hooks/session-start.sh`: one fetch per session start
- tests: a new `tests/scenarios/05-remote-claims.sh` with a bare origin and two clones, while the existing scenarios cover local mode
- docs: `starters/specs/README.md` (Working in parallel), the README FAQ, and `GLOSSARY.md`

The skills don't change: they only call the `jsdd` CLI.

## Considered and set aside

- **Support for other coding agents, and an extension or preset catalog.** Being built only for Claude Code is a deliberate trade-off (see the README). The hook-based enforcement depends on it. A cheaper middle ground is letting a project override files in `templates/`, for example with `specs/.templates/`.
- **Task complexity scoring** (Taskmaster). The plan reviewer can flag tasks that are too big without a separate feature.
- **Persona agents** (BMAD). They add ceremony without the guarantees the hooks and checks give.

## Suggested order

Ideas 1 and 2 first. Living specs make the kit useful over the long term, and a light track gets it used for everyday work. Idea 3 is the cheapest real quality gain, since it reuses the subagent setup the kit already has.
