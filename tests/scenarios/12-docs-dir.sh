#!/usr/bin/env bash
# The docs folder: a project whose docs/ holds its own documentation keeps the
# kit's documents in a folder of their own (docs_dir in specs/jsdd.yml). Init
# copies the starters there, every command and hook follows it, an existing
# project is told once and moves with jsdd move-docs, which rewrites the
# references (frozen checks included) and brings over documents a branch adds
# to the old folder later.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
mkdir -p docs
echo "# User guide" >docs/guide.md
echo "site_name: Product" >mkdocs.yml
git add -A && git commit -qm "[meta] Docs site"

step "init --docs-dir records the folder and copies the starters there, their paths pointed at it"
out=$(jsdd init --docs-dir docs/product --dry-run)
has "$out" "set      specs/jsdd.yml docs_dir: docs/product" || fail "the dry run does not set docs_dir: $out"
has "$out" "add      docs/product/requirements.md" || fail "the dry run does not add the starters in docs/product: $out"
[ ! -e specs/jsdd.yml ] || fail "the dry run wrote specs/jsdd.yml"
jsdd init --docs-dir docs/product >/dev/null
grep -qx 'docs_dir: docs/product' specs/jsdd.yml || fail "init did not record docs_dir"
grep -qx 'version: 1' specs/jsdd.yml || fail "the new specs/jsdd.yml has no version"
jsdd mode --check >/dev/null || fail "the specs/jsdd.yml init wrote is not valid"
for f in intent.md requirements.md decisions.md; do
  [ -f "docs/product/$f" ] || fail "init did not add docs/product/$f"
  [ ! -e "docs/$f" ] || fail "init added docs/$f"
done
grep -q 'docs/product/requirements.md' specs/README.md || fail "specs/README.md still points at docs/requirements.md"
! grep -qE '(^|[^/a-z])docs/(requirements|decisions|intent)\.md' specs/README.md specs/constitution.md PLAN.md BACKLOG.md \
  || fail "a starter still names the default docs folder"
[ "$(jsdd paths --docs)" = docs/product ] || fail "paths --docs is not docs/product"
expect "requirements  docs/product/requirements.md" jsdd paths
expect '"requirements": "docs/product/requirements.md"' jsdd paths --json
out=$(jsdd init --dry-run)
! has "$out" "update" || fail "init would refresh specs/README.md it wrote with the folder: $out"
! has "$out" "source   docs/product" || fail "init lists the kit's own documents as sources: $out"
! has "$out" "Docs:" || fail "a project with its own docs folder is told to separate them: $out"
git add -A && git commit -qm "[meta] Init"

step "commands follow the folder: coverage, new specs, the board"
printf '%s\n' '# Requirements' '' '| ID | Requirement | Source | Pri |' '|---|---|---|---|' \
  '| FR-NOTE-01 | A user can add a note | scenario | M |' >docs/product/requirements.md
expect "FR-NOTE-01" jsdd coverage
spec=$(jsdd new feature "Notes")
grep -q 'docs/product/requirements.md' "$spec" || fail "jsdd new did not point the template at the docs folder"
! grep -qE '(^|[^/a-z])docs/requirements\.md' "$spec" || fail "the new spec names docs/requirements.md"
out=$(jsdd status)
! has "$out" "Docs" || fail "the board warns about a project already separated: $out"
git add -A && git commit -qm "[001] Spec"

step "a folder outside the repository, in specs/, or a file is refused"
expect "must stay inside the repository" env SDD_DOCS_DIR=../elsewhere "$KIT/bin/jsdd" status
refuses env SDD_DOCS_DIR=../elsewhere "$KIT/bin/jsdd" status
expect "cannot be inside specs/" env SDD_DOCS_DIR=specs/docs "$KIT/bin/jsdd" paths
expect "is a file" env SDD_DOCS_DIR=mkdocs.yml "$KIT/bin/jsdd" paths
expect "must be relative" jsdd init --docs-dir /tmp/docs --dry-run
[ "$(SDD_DOCS_DIR=handbook/ "$KIT/bin/jsdd" paths --docs)" = handbook ] || fail "SDD_DOCS_DIR does not override docs_dir"
expect "jsdd move-docs handbook" jsdd init --docs-dir handbook
refuses jsdd init --docs-dir handbook

# A project set up before docs_dir existed: the kit's documents share docs/ with its guides.
cd "$TMP" && rm -rf "$PROJ"
project
mkdir -p docs && echo "# User guide" >docs/guide.md
jsdd init >/dev/null
d=$(dirname "$(jsdd new feature "Notes")")
frontmatter "$d/spec.md" status in-progress
cat >"$d/tasks.md" <<'TASKS'
# 001 · Tasks: Notes

## Tasks

- [ ] **T1** List the requirements → AC-1
  - check: `grep -q "Requirements" docs/requirements.md`
TASKS
jsdd freeze 001 >/dev/null
grep -q 'docs/requirements.md' "$d/checks.lock" || fail "the frozen check does not name docs/requirements.md"
mkdir -p docs/capabilities
printf '# Notes (FR-NOTE)\n\n> `docs/requirements.md` lists the rows.\n\nLast changed: 001 (2026-01-01)\n' >docs/capabilities/note.md
mkdir -p docs/legacy && echo "See docs/intent.md" >docs/legacy/OLD.md
printf 'Read docs/intent.md first.\n' >CLAUDE.md
printf 'cat docs/decisions.md\n' >tool.sh
git add -A && git commit -qm "[meta] Kit in docs/"

step "an existing project whose docs/ is shared is told once, and reminded on the board"
expect "Docs: docs/ holds the kit's documents and 1 other entry" jsdd status
expect "Docs: docs/ holds" jsdd init --dry-run
out=$(jsdd notices)
has "$out" "jsdd move-docs docs/product --dry-run" || fail "the notice does not name the move: $out"
[ -z "$(jsdd notices)" ] || fail "the notice was shown twice"
expect "jsdd move-docs" jsdd notices --all
git -C "$PROJ" worktree add -q "$TMP/wt" -b other 2>/dev/null
[ -z "$(cd "$TMP/wt" && "$KIT/bin/jsdd" notices)" ] || fail "a worktree of the same clone was told again"
git worktree remove --force "$TMP/wt"
out=$(SDD_DOCS_DIR=docs "$KIT/bin/jsdd" status)
! has "$out" "Docs:" || fail "the reminder shows although the folder was chosen: $out"

step "move-docs refuses uncommitted changes and a run in progress; a dry run changes nothing"
echo change >>tool.sh
expect "uncommitted changes" jsdd move-docs docs/product
refuses jsdd move-docs docs/product
git checkout -q -- tool.sh
claims=$(git rev-parse --git-common-dir)/sdd-claims
mkdir -p "$claims/run-001"
expect "A run is in progress (run-001)" jsdd move-docs docs/product
rm -rf "${claims:?}/run-001"
out=$(jsdd move-docs docs/product --dry-run)
for want in "move     docs/requirements.md -> docs/product/requirements.md" \
  "move     docs/capabilities/note.md -> docs/product/capabilities/note.md" \
  "move     docs/legacy/OLD.md -> docs/product/legacy/OLD.md" \
  "set      specs/jsdd.yml docs_dir: docs/product" \
  "rewrite  $d/tasks.md (1 line)" "rewrite  $d/checks.lock (1 line)" "rewrite  CLAUDE.md (1 line)" \
  "rewrite  docs/product/capabilities/note.md (1 line)" "mention  tool.sh:1:cat docs/decisions.md"; do
  has "$out" "$want" || fail "the dry run does not say '$want': $out"
done
! has "$out" "guide.md" || fail "the dry run would move the project's own guide: $out"
! has "$out" "OLD.md (" || fail "the dry run would rewrite a legacy copy: $out"
[ -z "$(git status --porcelain)" ] || fail "the dry run changed files: $(git status --porcelain)"

step "move-docs moves with git mv, sets docs_dir, and rewrites the references"
jsdd move-docs docs/product >/dev/null
for f in intent.md requirements.md decisions.md capabilities/note.md legacy/OLD.md; do
  [ -f "docs/product/$f" ] || fail "docs/product/$f was not moved"
  [ ! -e "docs/$f" ] || fail "docs/$f is still there"
done
[ ! -d docs/capabilities ] || fail "the empty docs/capabilities/ was left behind"
[ -f docs/guide.md ] || fail "the project's own guide moved"
git status --porcelain | grep -q '^R  docs/intent.md -> docs/product/intent.md' || fail "the move was not a git mv: $(git status --porcelain)"
grep -qx 'docs_dir: docs/product' specs/jsdd.yml || fail "docs_dir was not set"
grep -q 'docs/product/requirements.md' "$d/tasks.md" || fail "the task's check was not rewritten"
grep -q 'docs/product/requirements.md' "$d/checks.lock" || fail "the frozen check was not rewritten"
grep -qx 'Read docs/product/intent.md first.' CLAUDE.md || fail "CLAUDE.md was not rewritten"
grep -q 'docs/product/requirements.md' docs/product/capabilities/note.md || fail "the capability document was not rewritten"
grep -qx 'See docs/intent.md' docs/product/legacy/OLD.md || fail "the legacy copy was rewritten"
grep -qx 'cat docs/decisions.md' tool.sh || fail "a mention outside the kit's files was rewritten"
[ "$(jsdd claim 001 next)" = T1 ] || fail "claim next did not give T1"
expect "ticked 001 T1" jsdd done 001 T1
out=$(jsdd status)
! has "$out" "Docs" || fail "the board still warns after the move: $out"
[ -z "$(jsdd notices --all)" ] || fail "the notice still applies after the move"
git add -A && git commit -qm "[meta] Move kit docs to docs/product"
expect "Nothing to move" jsdd move-docs docs/product

step "a kit document a branch adds to the old folder is flagged and moved over"
mkdir -p docs/capabilities
printf '# Billing (FR-BILL)\n\nLast changed: 002 (2026-01-02)\n' >docs/capabilities/billing.md
echo "# Our decisions, not the kit's" >docs/decisions.md
git add -A && git commit -qm "[meta] Merge an old branch"
out=$(jsdd status)
has "$out" "Docs warning: kit documents outside the docs folder docs/product/: docs/capabilities/billing.md" || fail "the straggler is not flagged: $out"
has "$out" "decisions.md" && fail "the project's own docs/decisions.md is flagged: $out"
rm docs/decisions.md && git add -A && git commit -qm "[meta] Drop it"
expect "move     docs/capabilities/billing.md -> docs/product/capabilities/billing.md" jsdd move-docs docs/product
[ -f docs/product/capabilities/billing.md ] || fail "the straggler was not moved"
git add -A && git commit -qm "[meta] Move the straggler"

step "a document in both folders stops the move"
printf '# Intent\n\n## The product in one sentence\n\nOld.\n' >docs/intent.md
git add -A && git commit -qm "[meta] Old intent"
expect "conflict docs/intent.md: docs/product/intent.md exists" jsdd move-docs docs/product
refuses jsdd move-docs docs/product
[ -f docs/intent.md ] || fail "a refused move moved a file"
git rm -q docs/intent.md && git commit -qm "[meta] Drop it"

step "the hooks follow the folder"
hook() { printf '%s' "$2" | SDD_MODE=autopilot bash "$KIT/hooks/$1"; }
rm -f specs/STATUS.md
hook post-edit-status.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/docs/product/requirements.md\"}}"
[ -f specs/STATUS.md ] || fail "editing docs/product/requirements.md did not regenerate STATUS.md"
rm specs/STATUS.md
mkdir -p docs/other && echo x >docs/other/requirements.md
hook post-edit-status.sh "{\"cwd\":\"$PWD\",\"tool_input\":{\"file_path\":\"$PWD/docs/other/requirements.md\"}}"
[ ! -f specs/STATUS.md ] || fail "editing another requirements.md regenerated STATUS.md"
rm -rf docs/other
printf 'version: 1\ndocs_dir: docs/product\nmodes: [manual, autopilot]\n' >specs/jsdd.yml
SDD_MODE=autopilot "$KIT/bin/jsdd" run start 001 >/dev/null
edit_input() { printf '{"session_id":"%s","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$PWD" "$PWD/$2"; }
refuses hook protect-run-files.sh "$(edit_input session-a docs/product/intent.md)"
hook protect-run-files.sh "$(edit_input session-a docs/guide.md)" || fail "a run was blocked from the project's own docs"
SDD_MODE=autopilot "$KIT/bin/jsdd" run end 001 >/dev/null
out=$(printf '{"cwd":"%s"}' "$PWD" | bash "$KIT/hooks/session-start.sh")
has "$out" "Spec board" || fail "the session-start hook did not print the board: $out"
has "$out" "Docs folder: docs/product/" || fail "the session-start hook does not name the docs folder: $out"
has "$out" "upgrade notices" && fail "the session-start hook repeats a notice that no longer applies: $out"
true
