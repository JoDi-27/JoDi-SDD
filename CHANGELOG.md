# Changelog

## Unreleased

Renamed: the repository and marketplace are now `jodi-sdd`, and the plugin and CLI are `jsdd`. Commands are `/jsdd:plan`, `/jsdd:verify`, and so on, and the script is `jsdd done`, `jsdd next`, and so on.

**Upgrading from `sdd@sdd-kit`.** Swap the plugin, then run `/jsdd:init`, which replaces the old `Bash(sdd *)` permission with `Bash(jsdd *)`. Specs, claims, and the starters need no change.

```sh
claude plugin uninstall sdd@sdd-kit --scope project
claude plugin marketplace remove sdd-kit
claude plugin marketplace add JoDi-27/jodi-sdd --scope project
claude plugin install jsdd@jodi-sdd --scope project
```

## 0.1.0

First public release, packaged as a Claude Code plugin.

**Upgrading from the `install.sh` version.** Before it was a plugin, the kit was copied into each project by `install.sh`, into `.claude/` and `specs/_kit/`. In such a project, install the plugin and run `/sdd:init --migrate`. This removes the old copy and takes the old hooks out of `.claude/settings.json`, keeping the project's own settings. It also moves customizations such as the test command into `specs/constitution.md`.
