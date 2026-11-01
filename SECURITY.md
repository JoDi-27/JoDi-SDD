# Security

jsdd runs on your machine with your permissions: its hooks run on every Claude Code session in a project set up with `/jsdd:init`, and `jsdd done` runs the check command written in a task. A bug in either could run something you didn't intend.

## Reporting a vulnerability

Please report it privately through [GitHub's security advisories](https://github.com/JoDi-27/jodi-sdd/security/advisories/new), not as a public issue. Include what an attacker controls (a spec file, a commit message, a branch name), what it leads to, and the steps to reproduce.

You'll get a reply within a week. Fixes go out as a new release, and the advisory is published once the fix is out.

## Supported versions

Only the latest release gets fixes.
