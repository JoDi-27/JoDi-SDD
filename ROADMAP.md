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

*From the kit's own limits, not another framework.* **Built:** see `jsdd.claims remote` in [CHANGELOG.md](CHANGELOG.md) (Unreleased). As built: a task done on another branch makes `claim` print that branch, it does not wait for the tick to reach `main`. GitHub accepts `refs/sdd-claims/*`, but other hosts are untested. Switching modes warns about claims still held locally instead of moving them (no `--push-local`). An offline claim is `SDD_CLAIMS=local`, not `--local`.

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

### 10. GitHub Copilot support

*From Agent Plugins, the plugin format that Copilot CLI and VS Code share, which also accepts Claude-format plugins.*

**Gap:** the kit runs only in Claude Code. Copilot can now install plugins, and the same `skills/<name>/SKILL.md` layout loads in both, but a few parts still depend on Claude Code:

- the hooks, whose event names, stdin JSON, and way of blocking a command differ in Copilot (VS Code also ignores matchers)
- `${CLAUDE_PLUGIN_ROOT}` in the plan, init, and verify skills
- `bin/jsdd` being on the PATH
- the agents, which Copilot reads as `*.agent.md` with its own tool names
- `$CLAUDE_CODE_SESSION_ID` as the owner of a claim

**Shape:** one repository and one plugin for both agents:

- A spike first: install the current plugin in Copilot CLI and record what loads, which manifest location it reads, and what the skills' slash names are.
- `jsdd template <name>` prints a template's path, so skills no longer need `${CLAUDE_PLUGIN_ROOT}`.
- Copilot hooks under `com.github.copilot/hooks/`, with `hooks/_lib.sh` converting Copilot's input so the hook scripts stay the same.
- `jsdd init` installs a git `commit-msg` hook, so the commit-message check works with any agent, or none.
- Copilot agents in `com.github.copilot/agents/`, generated from `agents/*.md` at release so the two copies can't drift.
- `JSDD_SESSION_ID` as the claim owner, set by whichever agent starts the session.
- If Copilot can't show the board at session start, `jsdd init` adds a line to `.github/copilot-instructions.md` telling the agent to run `jsdd status` first.

### 11. A dependency graph of specs and tasks

*From Taskmaster's task dependencies.*

**Gap:** dependencies are recorded but never drawn. Each spec's `depends_on` shows on the board as a list of IDs, and the order of tasks is implicit in `tasks.md`: a task waits for every task before it, except the other tasks in its own run of `[P]` tasks. To see what blocks what across several specs, or which tasks in a spec can run in parallel, you have to read the files.

**Shape:** `jsdd graph [specs|tasks] [ID ...]`:

- `specs` prints the spec graph from `depends_on`, ordered by level (how many specs must close before each one). Each spec shows its status and the dependencies it is still waiting on, and the graph flags missing IDs and cycles.
- `tasks` prints each spec's tasks as steps, with each run of `[P]` tasks as one step. Each task shows its state (ticked, claimed, free, or waiting on earlier tasks).
- With no argument, it prints both together: the spec graph with each spec's tasks nested under it.
- `--mermaid` prints the same graph as a Mermaid flowchart, with one subgraph per spec, which can go into `STATUS.md` or a PR description.

## Larger: autonomous mode

### 12. Autonomous mode

*From GSD's unattended runs and Taskmaster's task loop, held to this kit's checks.*

**Built so far:** runtime modes and gates (0.7.6), and the `autopilot` mode (Unreleased), which covers most of M0 and M1 for one spec whose author has already approved it: `/jsdd:auto <ID>` runs it to a pull request, with parking, `auto:` provenance, frozen checks, run budgets, a run report, the protected-files hook, and a Stop hook that keeps the run going. It keeps the settings in `specs/jsdd.yml` instead of a separate charter, and leaves to `autonomous` what still needs one: settling clarifications, the loop over `jsdd next`, spikes and baselines, and merging. **Foundation:** runtime modes and gates (see `jsdd mode` in [CHANGELOG.md](CHANGELOG.md), Unreleased). Each gate in the table below has a name in `jsdd`'s gate catalog, and `autonomous` is registered as a mode that needs consent but is not available yet. The charter described below becomes the `autonomous:` section of `specs/jsdd.yml`, and `SDD_MODE=autonomous` (or `/jsdd:auto`) is the person's consent.

**Gap:** the kit is built around a person approving each step. Running the next command is the approval, and three skills say outright that an agent must never record a decision the user did not give. So a run nobody is watching stops at the first gate: `/jsdd:verify` leaves its report `pending`, `/jsdd:plan` changes nothing, and `/jsdd:implement` stops at the first check it cannot fix. There is no way to say "work through Phase 1 overnight" and come back to verified work.

**Shape:** an opt-in mode in which the human approves once, up front, by committing a **charter** (`specs/autonomy.yml`), and once at the end, by reading a **run report**. Every gate in between is passed by a machine check, a fresh-context reviewer, or a rule in the charter. A gate that none of those can pass is **parked**: the spec waits, visible on the board, and the run moves on to other work. Autonomy never means pretending a person decided. Each decision is recorded with the charter key or agent that made it (`auto: charter decisions.gap_options`, `auto: reviewer`), so the history stays honest and anyone can audit it afterwards.

#### Where a person approves today, and what replaces it

| Gate | Today | In autonomous mode |
| --- | --- | --- |
| Spec approval (`/jsdd:plan` runs) | The user reads the spec | A spec-quality reviewer pass (idea 6) with no blocking findings, and no `[NEEDS CLARIFICATION]` markers left |
| Clarifying questions (`/jsdd:specify` step 4) | AskUserQuestion | `spike-researcher` settles the factual ones. `sdd-product` decides the product ones, as far as `decisions.product` allows (see "The product agent"). The rest park |
| Splitting a large spec | The user confirms | Split when the reviewer agrees each part is a few days at most. `sdd-product` decides which part comes first |
| Plan approval (`/jsdd:implement` runs) | The user reads the plan | `sdd-reviewer` plan mode with no blocking findings. The checks are frozen (see guardrails) |
| A check fails, the plan is wrong, a decision is missing | Implement stops and asks | Up to `budgets.attempts_per_task` attempts. A plan change becomes a Deviation the reviewer accepts, when `decisions.deviations` allows it. A spec change is parked unless `decisions.spec_changes` allows it |
| `check: manual:` tasks and ACs | A person checks | Not allowed in an autonomous plan. A spec that needs one is parked at that task |
| Commits | Only if the user asked | One commit per task, `[<ID>] T<n>`, on the run's branch |
| Verify gaps | The user approves, picks options, or stops | A gap whose fix is code with a check is approved. A gap with options takes the reviewer's recommended option when `decisions.gap_options` is `reviewer`, or `sdd-product`'s pick when the options differ in product behavior and it is `product`. A spec-change gap goes to `sdd-product` when `decisions.spec_changes` allows it. A repeated gap (the two-rounds rule) is parked |
| Partial `refs`, capability entries "changed since" | The user agrees | The reviewer checks the split or merge; parked if it disagrees |
| Spikes | An interview | Only spikes the researcher can answer from docs and code. Questions for the owner park the spike |
| Baselines | The user confirms each row | Reviewer baseline mode confirms the rows (`source: code (auto)`). A behavior that looks like a bug goes to Findings and `BACKLOG.md`, never into a row. `sdd-product` may judge "bug or intended" when the docs answer it |
| `/jsdd:init` interview | The user | Out of scope. A project must be initialized, with intent and constitution filled in, before a run |
| Merge to the main branch | The user | `merge.policy`: `pr` opens a pull request (the default), `auto` merges when CI is green and the spec converged |

#### The charter

`specs/autonomy.yml` says what a run in this project may do on its own. It is committed, so the whole team sees it, and a run can never edit it.

```yaml
# Autonomy charter. Read by jsdd; a run can never edit this file.
version: 1
preset: cautious                   # cautious | standard | hands-off

# Optional: any key below overrides the preset.
scope:
  phases: [1]
  types: [feature, baseline]       # spike only if researcher-answerable
  exclude_groups: [FR-BILLING]

decisions:
  product: cited                   # park | cited | inferred | uncited | all
  gap_options: reviewer            # reviewer | product | park
  spec_changes: park               # park | narrow-should-could | product
  deviations: reviewer             # reviewer | park

budgets:
  specs_per_run: 3
  attempts_per_task: 3
  verify_rounds: 2
  wall_time_hours: 4

merge:
  policy: pr                       # pr | auto
  require_ci: true
```

- **A YAML subset, no new dependency.** The kit needs only bash, awk, jq, and python3, and none of them reads YAML on its own (Python's standard library has no YAML module). The charter uses sections one level deep, scalar values, and inline lists, the same subset `jsdd` already parses in spec frontmatter.
- **Only `jsdd` parses it.** `jsdd charter get <key>` prints one effective value (preset plus overrides). Skills and hooks read it that way.
- **Fails closed.** `jsdd charter --check` rejects unknown keys, values outside the allowed set, and numbers out of range: a typo in a safety setting is an error, never ignored. No file means autonomy is off. A key left out takes its preset's value, and with no preset, its strictest value.
- **Presets make it one line.** Each preset is a full, documented set of values. `cautious` lets the product agent answer only what the docs already say, parks every other product question and every spec change, and opens a PR. `standard` also lets it decide what follows from the principles, and takes the reviewer's option for gaps. `hands-off` lets it decide everything outside the protected files, including spec changes and gaps with product options, and may merge (an open decision below). Most projects pick a preset and never learn the keys.
- **Why lives in comments.** Teams that want longer reasoning add it to `specs/constitution.md`.

#### The product agent

A person who turns on autonomous mode accepts that the run will make product decisions for them. If product questions only parked, the mode would not be autonomous. Letting the session that wrote the spec answer its own questions is the weakest option, because it shares the author's context and blind spots. So product questions go to a new read-only agent, `sdd-product`, which decides them in a fresh context, the same way `sdd-reviewer` and `spike-researcher` work.

**What it reads.** Only what's on disk: `docs/intent.md` (principles, "Not now", what success looks like), the product articles in `specs/constitution.md`, `docs/requirements.md` with priorities, `docs/decisions.md`, `BACKLOG.md`, `PLAN.md`, `docs/capabilities/`, the spec in question, and the code. It never sees the session that asked.

**How far it may go.** Each answer is classified by what supports it, and `decisions.product` sets the highest class the run may act on. Anything above that class parks.

| The question | Needs `decisions.product` | `cautious` | `standard` | `hands-off` |
| --- | --- | --- | --- | --- |
| The docs already answer it | `cited` | decides | decides | decides |
| It follows from the principles | `inferred` | parks | decides | decides |
| Nothing in the docs covers it | `uncited` | parks | parks | decides |
| The docs contradict each other | `all` | parks | parks | decides: picks the newer or more specific source, and flags the conflict |
| It would change the constitution, the intent, or a Must row's priority | (none) | parks | parks | parks |

The last row parks under every preset because those files are protected (see guardrails), not because the agent is unsure.

**How it decides with nothing to cite.** When the docs say nothing, it follows a fixed order of preference and records which rule it used:

1. **Reversible:** the option that is cheapest to undo, such as an additive change, a flag, or no change to a data model or public API.
2. **Smallest:** the smallest scope that still meets the acceptance criteria.
3. **Closest:** what best fits the stated principles and the nearest existing capability.
4. **Consistent:** what the code already does in similar places.

**How decisions are recorded.** Each one is an `auto:` decision that names its class and its source, such as `auto: product, sdd-product, cited (intent.md § Not now)` or `auto: product, sdd-product, uncited (rule: reversible)`. It is also appended to `docs/decisions.md` with `status: assumed`. When the owner confirms or rejects it from the run report, the entry becomes a real decision, or a one-line correction and a new spec. Over time the docs answer more questions, and later runs park less and infer less.

**The person gives up control over results, not the ability to change them.** The run report lists product decisions strongest-basis last: uncited and contradiction decisions first, each with what it would cost to reverse. A decision that is expensive to reverse (a schema, an external contract, deleting data) is still made under `hands-off`, but it also goes on the pull request as an item to review.

**Not a persona.** This is not the BMAD-style role-play set aside below. The agent has a contract: it reads the files, classifies each answer, cites a source or names its rule, and never edits a file. Its output can be checked line by line.

#### Who turns it on

Two sides must agree: the **project**, by committing a charter, and the **person**, by typing `/jsdd:auto`. Typing the command is the consent. A user who clones a public repository that has a charter never starts a run unless they run it themselves.

Plugin configuration (`userConfig` in `plugin.json`) adds an optional third key: a per-user "never allow autonomous runs" switch, off by default, which the Stop hook reads as `CLAUDE_PLUGIN_OPTION_*` and `/jsdd:auto` reads through `${user_config.*}`. It is not required, because `claude plugin install` from the shell never prompts for it, and every required step costs onboarding. What plugin configuration cannot do: set a permission mode, permission rules, or environment variables (a plugin's `settings.json` applies only `agent` and `subagentStatusLine`, and plugin agents ignore `permissionMode`). A fully unattended run needs a permission mode that does not prompt. That stays the user's setting; the kit explains it and never sets it.

#### Onboarding

Most users of the kit will never turn autonomous mode on, and they pay nothing for it: no charter means the README path, the four commands, and the files are unchanged. For those who do, the path is three steps.

1. **`/jsdd:auto setup`** asks three or four questions with recommended answers (scope, preset, PR or merge), writes `specs/autonomy.yml` with comments, and runs `jsdd charter --check`. `/jsdd:init` offers it at the end, and only offers.
2. **`/jsdd:auto --dry-run`** shows which specs a run would pick and, for each, which gates it would pass and where it would park ("004 would park at verify: spec-change gap"). It changes nothing.
3. **`/jsdd:auto <ID>`** runs one spec. `/jsdd:auto` with no ID runs the loop once that is trusted.

Alongside:

- **`jsdd auto doctor`** checks what the kit does not control and prints the fix for each failure: the charter is valid, the git tree is clean, `gh` is available when the policy is `pr`, and the permission mode will not prompt. The permission mode is the hardest step for a newcomer, so the fix it prints is exact.
- **The board shows the mode.** The session-start board and `jsdd status` print `autonomous: standard · 2 parked` when a charter exists, with parked specs under "Waiting for you".
- **One walkthrough page,** `docs/autonomous-mode.md`, in the style of `docs/first-feature.md`, and new `GLOSSARY.md` rows: charter, preset, parked, `auto:` decision, product agent, assumed decision, run report.

#### Guardrails that never relax

- **Only checks tick work.** `jsdd done` stays the only way to tick a task or AC, exactly as today.
- **Checks are frozen at plan approval.** `jsdd done` records a hash of each task's check and of the test files its ACs name. A changed check or a weakened test after approval fails the task unless a Deviation records it and the reviewer accepted it. With nobody watching, this is the guard against an agent making tests pass by making them weaker.
- **Protected files.** `specs/constitution.md`, `docs/intent.md`, `specs/autonomy.yml`, and the priority of any Must row in `docs/requirements.md` are never changed by a run. A hook blocks the edit.
- **No invented decisions.** Every answer the run gives is written as an assumption or an `auto:` decision citing its charter key, never as the user's. A product decision also names its class and source or rule. The run report lists all of them.
- **Budgets.** The charter caps specs per run, attempts per task, verification rounds per spec (two, as today), and wall time. The run stops cleanly at a cap and releases its claims.
- **Isolation.** Each run works in its own worktree and branch. It never force-pushes, never rewrites history, and touches the main branch only when `merge.policy` is `auto`.

#### Milestones

**M0. Foundations.** Each is useful without autonomous mode, and the mode cannot be built safely without them.

- Idea 3, a fresh subagent for each task, so a long run does not drift as its context fills.
- Idea 6, the spec-quality review, which becomes the spec-approval gate.
- Decision provenance: an `auto:` form for `Chosen:`, `Decision`, and changelog lines, which `jsdd status` and the reviewer understand.
- Parking: `jsdd park <ID> [Tn] "<reason>"` and `jsdd unpark`. A parked spec keeps its status, shows under "Waiting for you" on the board, and `jsdd next` skips it.
- Frozen checks in `jsdd done`.

**M1. One spec, end to end.** `/jsdd:auto <ID>` takes one spec from `draft` (or any later status) to `done` on a branch, with no questions, parking where it must. Adds the charter and its parser (`jsdd charter get`, `--check`), the three presets, `/jsdd:auto setup`, `--dry-run`, `jsdd auto doctor`, the protected-files hook, the `sdd-product` agent with `decisions.product` and its `assumed` entries in `docs/decisions.md`, and the run report (`specs/runs/<date>-<n>.md`: what was done, every `auto:` decision and assumption, what was parked and why). Scenario tests drive a stub feature through `jsdd` with no prompts, and check that a bad charter is refused.

**Decision point.** Before M2, run M1 on a real project under each preset. Count where runs park, and how many product decisions fall in each class. Then have the owner grade the assumed decisions in `docs/decisions.md` as confirmed or rejected. If `inferred` and `uncited` decisions are mostly rejected, the presets move down a class, or the order of preference changes, before the loop makes more of them unattended. If `cautious` runs mostly park at the first product question, that is the expected cost of that preset, and the walkthrough points such projects to `standard`.

**M2. Unattended loop.** `/jsdd:auto` with no ID works through `jsdd next` within the charter until the queue is empty or a budget runs out, skipping parked specs. While a run is active, the Stop hook blocks stopping as long as charter work and budget remain, checking `stop_hook_active` so it never loops on a condition that will not change. `jsdd auto` starts the same loop headless (`claude -p` in a new worktree), so it can run from cron or a scheduled agent. Several runs can share a project through the existing claims. Spikes the researcher can answer and baselines join the loop. The optional per-user switch lands here.

**M3. Full autonomy.** `merge.policy: auto` is honored: a spec that converged, with CI green and nothing parked, is merged by the run. Idea 4, drift detection, runs after each merge, so a later autonomous spec that breaks an earlier one is caught. The run report gains a short digest of what changed, to read in the morning. Idea 8 writes the PR bodies.

#### Trade-offs

What it gains:

- **The most common complaint about SDD tools, the ceremony, goes away** for work the charter covers: you review results instead of each step.
- **It builds on what the kit already enforces.** Checks that tick tasks, fresh-context reviewers, and claims make autonomy safer here than in a tool that relies on the agent's word.
- **Honest and auditable.** `auto:` decisions, assumptions, and the run report show what was decided without you, and by which key.
- **Degrades safely.** A run decides only as far as its preset allows and parks beyond that. A missing charter or key means stricter, never looser.
- **Product docs improve as it runs.** Each assumed decision the owner confirms or rejects becomes a written decision, so later runs cite more and guess less.
- **The foundations pay off alone.** Ideas 3 and 6, provenance, parking, and frozen checks improve interactive use even if M2 and M3 never ship.

What it costs:

- **It weakens the core promise.** A reviewer approving a plan is weaker than a person doing it. The reviewer and the author are the same model and can share blind spots; a fresh context only partly helps.
- **The product agent makes the owner's choices.** That is the point of `standard` and `hands-off`, but it is also where they fail quietly. A grounded-sounding answer is more convincing than a bare default, and the agent shares the author's model even in a fresh context. Ordering the report by strength of basis, and logging each decision as `assumed`, helps only if someone reads them.
- **Under `cautious`, parking may be the common case.** Owner questions, spec changes, manual checks, and repeated gaps all park. On a young project with thin docs, a run may do little before it stops. The other presets trade that for more decisions made without the owner.
- **Weak tests are the remaining hole.** Frozen checks stop an agent weakening a test after approval, not writing a weak one before it. Only the reviewer guards that.
- **Cost.** Reviewer passes, research, and retries spend tokens fast. Budgets cap a run, but a loose charter can still spend an evening on work that ends parked.
- **The permission mode is outside the kit's control.** Many users will either struggle with it or set something broader than they need.
- **Maintenance surface.** A schema, presets, a parser, hooks, `doctor`, dry runs, and run reports, in a kit whose appeal is plain Markdown and one bash script. Every skill gains an autonomous branch, which doubles what the scenario tests must cover.
- **Auto-merge has real blast radius.** Drift detection catches breakage after a merge, not before.

#### Open decisions

- **Preset values.** What exactly `cautious`, `standard`, and `hands-off` set, and whether `hands-off` should allow merging at all.
- **The enums.** The allowed values for each `decisions` key are a first cut, settled while building M1.
- **Spec changes from verify.** Whether `standard` allows `narrow-should-could`, and whether `hands-off` should hand all spec changes to the product agent (`product`) or only narrowing.
- **Product classes.** Whether four classes are the right cut, whether the order of preference is fixed or set in the charter, and what counts as "expensive to reverse" for the pull request list.
- **Assumed decisions.** The format of `status: assumed` entries in `docs/decisions.md`, and whether a later run may cite an assumed decision as `cited`, or only a confirmed one.
- **Runner.** In-session loop through the Stop hook, headless `claude -p`, or both.
- **The pitch.** The README says "nothing moves forward without you". It needs a line on what changes when a charter exists, and the name of the mode may change after the M1 decision point.

## Considered and set aside

- **Support for other coding agents beyond Copilot, and an extension or preset catalog.** The hook-based enforcement depends on each agent's hooks, so each one costs real work to support. Copilot (idea 10) is the exception because it reads the same plugin format. A cheaper middle ground is letting a project override files in `templates/`, for example with `specs/.templates/`.
- **Task complexity scoring** (Taskmaster). The plan reviewer can flag tasks that are too big without a separate feature.
- **Persona agents** (BMAD). They add ceremony without the guarantees the hooks and checks give.

## Suggested order

Ideas 1 and 2 first. Living specs make the kit useful over the long term, and a light track gets it used for everyday work. Idea 3 is the cheapest real quality gain, since it reuses the subagent setup the kit already has.

Autonomous mode (idea 12) builds on ideas 3 and 6, so they come first either way. After them, its M0 parts (provenance, parking, frozen checks) are worth building on their own: they make unattended single runs safe before any loop exists. M1 then decides the rest: how often single-spec runs park on a real project says whether the loop and auto-merge are worth their cost.
