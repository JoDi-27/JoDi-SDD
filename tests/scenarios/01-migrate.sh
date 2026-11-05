#!/usr/bin/env bash
# Moving a project from the install.sh kit to the plugin, as /jsdd:init --migrate
# does: the old copy goes, the project's own settings and documents stay, and the
# files that still teach the old commands are flagged until they are rewritten.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project old-kit

step "init refuses while the old copy is there"
expect "jsdd init --migrate" jsdd init
[ -d specs/_kit ] || fail "init without --migrate removed the old kit"

step "the dry run lists everything and changes nothing"
out=$(jsdd init --migrate --dry-run)
for f in .claude/skills/sdd-plan .claude/agents/sdd-reviewer.md .claude/hooks/stop-claims.sh specs/_kit; do
  has "$out" "remove   $f" || fail "dry run did not list $f for removal: $out"
done
has "$out" "source   PRODUCT_INTENT.md (the install.sh kit's intent file) for docs/intent.md" || fail "dry run did not offer PRODUCT_INTENT.md: $out"
has "$out" "stale    CLAUDE.md (lines 7, 8, 9, 13)" || fail "dry run did not flag CLAUDE.md's old commands: $out"
has "$out" "keep     specs/constitution.md" || fail "dry run did not keep the old-format constitution: $out"
has "$out" "test commands found: npm test" || fail "dry run did not find the test command: $out"
! has "$out" "specs/001-first-feature" || fail "dry run flagged a spec, which is history: $out"
[ -z "$(git status --porcelain)" ] || fail "the dry run changed files: $(git status --porcelain)"

step "migrate removes the old copy and keeps the project's settings"
jsdd init --migrate >/dev/null
for f in .claude/skills .claude/agents .claude/hooks specs/_kit; do [ ! -e "$f" ] || fail "migrate left $f"; done
s=.claude/settings.json
jq -e '.permissions.allow | index("Bash(jsdd *)")' $s >/dev/null || fail "migrate did not allow jsdd: $(cat $s)"
jq -e '.permissions.allow | index("Bash(npm test)")' $s >/dev/null || fail "migrate dropped the project's permission: $(cat $s)"
! jq -e '.permissions.allow | index("Bash(specs/_kit/sdd *)")' $s >/dev/null || fail "migrate kept the old permission"
! grep -q '\.claude/hooks/' $s || fail "migrate kept an old hook: $(cat $s)"
grep -q 'project-own-hook.sh' $s || fail "migrate dropped the project's own hook: $(cat $s)"
! jq -e '.hooks.SessionStart' $s >/dev/null || fail "migrate left an empty SessionStart"
cmp -s "$KIT/starters/specs/README.md" specs/README.md || fail "migrate did not refresh specs/README.md"
for f in docs/intent.md docs/requirements.md docs/decisions.md BACKLOG.md; do [ -f "$f" ] || fail "migrate did not add $f"; done
grep -q 'Notes baseline' PLAN.md || fail "migrate replaced the project's PLAN.md"
grep -q 'API only' specs/constitution.md || fail "migrate replaced the project's constitution"

step "the board reads specs written with the old kit"
expect "| 001 | feature | done | 1 | 1/1 |" jsdd status

step "rewriting the old references clears them"
expect "stale    CLAUDE.md" jsdd init --dry-run
edit CLAUDE.md 's|/sdd-\([a-z]*\)|/jsdd:\1|g; s|specs/_kit/sdd|jsdd|g; /\.claude\/skills\/sdd-/d'
out=$(jsdd init --dry-run)
! has "$out" "stale" || fail "init still flags CLAUDE.md after the rewrite: $out"
! has "$out" "  add " || fail "a second init adds starters again: $out"

step "a second migrate is a no-op"
before=$(git status --porcelain; cat .claude/settings.json)
jsdd init --migrate >/dev/null
[ "$before" = "$(git status --porcelain; cat .claude/settings.json)" ] || fail "a second migrate changed files"
