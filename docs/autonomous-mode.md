# Autonomous mode

A walkthrough of letting runs work through your specs without you, from writing the charter to reading the morning digest. It assumes a project already set up with `/jsdd:init`, with a few specs taken through by hand first ([Your first feature](first-feature.md)). Most projects never need this: without a charter, nothing here applies.

Autonomous mode changes one thing about the kit: who passes the gates. In manual mode you approve each step. Here you approve twice: once up front, by committing a **charter** that says what a run may do on its own, and once at the end, by reading the pull requests and run reports. In between, a check, the fresh-context reviewer, or a rule in the charter passes each gate, and product questions go to a product agent, `sdd-product`, that answers from your documents. Where none can, the spec **parks**: it waits for you on the board, and the run moves on to other work. A run never pretends you decided something. Each decision it makes is written as `auto: <gate>`, so anyone can see afterwards what was decided without you.

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

Pick the preset by how much product judgment you're willing to hand over. Every product question goes to the `sdd-product` agent, which reads only your product documents and code, answers, and says what supports the answer: **cited** (your docs already say it), **inferred** (it follows from your principles), **uncited** (nothing covers it, so it picks the most reversible, then smallest option, and names the rule), or **conflict** (your docs disagree). The preset sets how far the run may act on those answers:

- `cautious` (`product: cited`) acts only on what your docs already answer; everything else parks. Each spec ends at a pull request. Start here.
- `standard` (`product: inferred`) also acts on what follows from your principles.
- `hands-off` (`product: all`) acts on every answer outside the protected files, lets the agent decide spec changes from verification, and merges a spec that converged with every CI check green.

The better your intent, `BACKLOG.md` defaults, and decisions are written, the more answers are cited rather than guessed.

Commit the file. A run can never edit it, and `jsdd mode --check` rejects any key or value it doesn't know, so a typo fails instead of quietly loosening a setting.

**2. Opt in yourself.** Set `SDD_MODE=autonomous` in your shell, or under `env` in `.claude/settings.local.json`, and start a new session. The board now starts with `MODE: autonomous, preset cautious`. A teammate who pulls the charter isn't affected until they do the same.

**3. Check what the kit can't control.** `/jsdd:auto doctor` checks the charter, the mode, a clean work tree, `gh` (for pull requests), and your permission mode, and prints the fix for anything missing. The permission mode matters most: a run can't answer a permission prompt, so it stalls at the first one. Doctor tells you exactly which allow rules to add. The kit never changes your permission settings for you.

**4. See what a run would do.** `/jsdd:auto --dry-run` changes nothing. It lists the specs a loop would take, in order, where each one would park, and why every other spec is left out:

```
A loop would take, in order:
  004  feature  approved    feature: plan, implement, verify
  005  feature  draft       feature: review spec, plan, implement, verify
         sdd-product answers 2 open questions as far as product: cited allows; the rest park at spec.clarify
Left out:
  006  refs FR-BILLING-02, in autonomous.exclude_groups
  007  waiting on 004
```

If most specs would park at the first open question, answer those with `/jsdd:specify` first, write the missing defaults into `BACKLOG.md` or `docs/decisions.md` so the agent can cite them, or move to `standard`.

**5. Run one spec.** `/jsdd:auto 004` takes one spec through to a pull request without asking you anything. Nobody approved the spec, so the `sdd-reviewer` reviews it first: are the requirements testable, does each have an acceptance criterion, are the error, empty, and permission cases covered, and is it small enough? Then the reviewer approves the plan, checks tick the tasks (one commit each), and verification builds the fixes a check can prove. The run ends with a pull request, plus a `run-report.md` listing every decision it made, with the product decisions weakest basis first.

**6. Run the loop.** Once single runs look right, `/jsdd:auto` with no ID works through the queue. Each spec gets its own branch (`autonomous/<ID>-<slug>`), its own run report, and its own pull request. The loop stops when the queue is empty, after `specs_per_run` specs, or when `wall_time_hours` runs out. While it has work left, a Stop hook keeps the session going, and it lets the session stop once the run stops making progress.

**7. Read the results.** The loop writes `specs/runs/<date>-<n>.md` with what each spec ended as, what is waiting for you, every product decision it made, and a short digest. Start with "Waiting for you": each parked spec says what you need to decide. Settle it, run `jsdd unpark <ID>`, and the next run picks the spec up again. Then go through the **Assumed** section of `docs/decisions.md`: each `AS-nn` row is a product decision a run made, with its class, its basis, and what undoing it would cost. Confirm it (it becomes a DEC row, which later runs cite) or reject it (remove it, and add a BACKLOG item or a spec to undo it). Then review the pull requests, reading the product decisions and deviations first.

## What a run never does

- Tick a task or criterion without its check passing, or change a check after the plan was approved, unless the reviewer accepts a recorded Deviation.
- Edit `specs/constitution.md`, `docs/intent.md`, `specs/jsdd.yml`, or `checks.lock` (a hook blocks it), or change the priority of a Must requirement.
- Act on a product answer beyond the charter's `product` class: it parks, with the agent's answer in the reason.
- Change what a spec asks for, except under `hands-off`, where `sdd-product` decides spec changes from verification. Narrowing or dropping a Must always parks.
- Force-push, rewrite history, or merge anything except a converged spec with green CI under `hands-off`.
- Run `/jsdd:init`, or decide which areas need a baseline. Baselines and spikes run only when the charter lists their type, and only on what the code and docs can answer.

## Running it with nobody at the machine

Everything above happens in a session you started. To run a spec from cron, CI, or a container, use the headless runner:

```bash
SDD_PROFILE=cloud jsdd auto run -- --permission-mode bypassPermissions
```

It checks what an unattended run needs (`jsdd auto doctor --unattended`), takes the next spec, runs `/jsdd:auto` with `claude -p`, and afterwards, however the session ended, records the outcome in `run-result.json`, commits it, and pushes the branch. Its exit code says what happened. `--json`, the exit codes, and the event log are described in [Running jsdd from scripts and the cloud](machine-output.md).

## What it costs

A reviewer that approves a spec or plan is weaker than you doing it: it's the same model, and a fresh context only partly helps. The product agent shares the author's model even in a fresh context, and a well-cited-sounding answer is more convincing than a bare default: the Assumed rows only help if someone reads them. Each reviewer pass and retry spends tokens, and the budgets cap a run but don't make a loose charter cheap. Frozen checks stop a run from weakening a test after the plan is approved. They don't stop it from writing a weak test in the first place; only the reviewer guards against that. Start with `cautious`, a narrow scope, and single runs, and widen them once the run reports show you can trust them.
