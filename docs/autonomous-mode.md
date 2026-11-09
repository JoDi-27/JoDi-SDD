# Autonomous mode

A walkthrough of letting runs work through your specs without you, from writing the charter to reading the morning digest. It assumes a project already set up with `/jsdd:init`, with a few specs taken through by hand first ([Your first feature](first-feature.md)). Most projects never need this: without a charter, nothing here applies.

Autonomous mode changes one thing about the kit: who passes the gates. In manual mode you approve each step. Here you approve twice: once up front, by committing a **charter** that says what a run may do on its own, and once at the end, by reading the pull requests and run reports. In between, a check, the fresh-context reviewer, or a rule in the charter passes each gate. Where none can, the spec **parks**: it waits for you on the board, and the run moves on to other work. A run never pretends you decided something. Each decision it makes is written as `auto: <gate>`, so anyone can see afterwards what was decided without you.

In a Claude Code session in your project:

**1. Write the charter.** `/jsdd:auto setup` asks a few questions: the preset, which spec types and phases a run may take, how many specs per run, and which requirement groups are off limits. Then it writes the `autonomous:` section of `specs/jsdd.yml`:

```yaml
version: 1
modes: [manual, autonomous]
autonomous:
  preset: cautious            # cautious | standard | hands-off
  types: [feature]
  phases: [1]
  exclude_groups: [FR-BILLING]
  specs_per_run: 3
  wall_time_hours: 4
```

Pick the preset by how much product judgment you're willing to hand over:

- `cautious` parks every open question and opens a pull request for each spec. Start here.
- `standard` also answers an open question when a default is already written down (a suggested default in `BACKLOG.md`, a DEC row, or a recommended answer in the spec) and records it as an assumption.
- `hands-off` is `standard` plus merging: a spec that converged, with every CI check green, is merged by the run.

Commit the file. A run can never edit it, and `jsdd mode --check` rejects any key or value it doesn't know, so a typo fails instead of quietly loosening a setting.

**2. Opt in yourself.** Set `SDD_MODE=autonomous` in your shell, or under `env` in `.claude/settings.local.json`, and start a new session. The board now starts with `MODE: autonomous, preset cautious`. A teammate who pulls the charter isn't affected until they do the same.

**3. Check what the kit can't control.** `/jsdd:auto doctor` checks the charter, the mode, a clean work tree, `gh` (for pull requests), and your permission mode, and prints the fix for anything missing. The permission mode matters most: a run can't answer a permission prompt, so it stalls at the first one. Doctor tells you exactly which allow rules to add. The kit never changes your permission settings for you.

**4. See what a run would do.** `/jsdd:auto --dry-run` changes nothing. It lists the specs a loop would take, in order, where each one would park, and why every other spec is left out:

```
A loop would take, in order:
  004  feature  approved    feature: plan, implement, verify
  005  feature  draft       feature: review spec, plan, implement, verify
         would park at spec.clarify: 2 open questions (preset standard takes recorded defaults as assumptions)
Left out:
  006  refs FR-BILLING-02, in autonomous.exclude_groups
  007  waiting on 004
```

If most specs would park at the first open question, answer those with `/jsdd:specify` first, or record defaults in `BACKLOG.md` and move to `standard`.

**5. Run one spec.** `/jsdd:auto 004` takes one spec through to a pull request without asking you anything. Nobody approved the spec, so the `sdd-reviewer` reviews it first: are the requirements testable, does each have an acceptance criterion, are the error, empty, and permission cases covered, and is it small enough? Then the reviewer approves the plan, checks tick the tasks (one commit each), and verification builds the fixes a check can prove. The run ends with a pull request, plus a `run-report.md` listing every decision and assumption it made.

**6. Run the loop.** Once single runs look right, `/jsdd:auto` with no ID works through the queue. Each spec gets its own branch (`autonomous/<ID>-<slug>`), its own run report, and its own pull request. The loop stops when the queue is empty, after `specs_per_run` specs, or when `wall_time_hours` runs out. While it has work left, a Stop hook keeps the session going, and it lets the session stop once the run stops making progress.

**7. Read the results.** The loop writes `specs/runs/<date>-<n>.md` with what each spec ended as, what is waiting for you, every assumption it made, and a short digest. Start with "Waiting for you": each parked spec says what you need to decide. Settle it, run `jsdd unpark <ID>`, and the next run picks the spec up again. Then review the pull requests, reading the decisions and assumptions first.

## What a run never does

- Tick a task or criterion without its check passing, or change a check after the plan was approved, unless the reviewer accepts a recorded Deviation.
- Edit `specs/constitution.md`, `docs/intent.md`, `specs/jsdd.yml`, or `checks.lock` (a hook blocks it), or change the priority of a Must requirement.
- Make up an answer: an open question with no recorded default parks.
- Change what a spec asks for: a spec change from verification always parks, in every preset.
- Force-push, rewrite history, or merge anything except a converged spec with green CI under `hands-off`.
- Run `/jsdd:init`, or decide which areas need a baseline. Baselines and spikes run only when the charter lists their type, and only on what the code and docs can answer.

## What it costs

A reviewer that approves a spec or plan is weaker than you doing it: it's the same model, and a fresh context only partly helps. Recorded assumptions only help if someone reads the reports. Each reviewer pass and retry spends tokens, and the budgets cap a run but don't make a loose charter cheap. Frozen checks stop a run from weakening a test after the plan is approved. They don't stop it from writing a weak test in the first place; only the reviewer guards against that. Start with `cautious`, a narrow scope, and single runs, and widen them once the run reports show you can trust them.
