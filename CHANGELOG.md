# Changelog

## 0.1.0

First public release, packaged as a Claude Code plugin.

**Upgrading from the `install.sh` version.** Before it was a plugin, the kit was copied into each project by `install.sh`, into `.claude/` and `specs/_kit/`. In such a project, install the plugin and run `/sdd:init --migrate`. This removes the old copy and takes the old hooks out of `.claude/settings.json`, keeping the project's own settings. It also moves customizations such as the test command into `specs/constitution.md`.
