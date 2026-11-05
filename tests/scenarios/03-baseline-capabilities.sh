#!/usr/bin/env bash
# An existing area recorded by a baseline, then changed by a feature, the way
# /jsdd:baseline and /jsdd:verify keep docs/capabilities/ current: acceptance
# criteria ticked only by their checks, and `jsdd capabilities --check` catching
# each way the capability document can fall behind the specs.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
requirements "FR-LIST-01|Contacts are listed a page at a time|M" "FR-LIST-02|Contacts can be filtered by name|M" \
  "FR-LIST-03|Contacts are sorted by id|S"
git add -A && git commit -qm "[meta] Requirements"

step "a baseline's criteria are ticked only by their checks, under the spec's claim"
base=$(jsdd new baseline "Contact listing: current behavior")
frontmatter "$base" refs '["FR-LIST-01", "FR-LIST-02", "FR-LIST-03"]'
frontmatter "$base" status in-progress
edit "$base" 's|^- \[ \] \*\*AC-1\*\* .*|- [ ] **AC-1** Lists a page · check: `true` → R1\
- [ ] **AC-2** Filters by name · check: `test -f name-test-passes` → R2\
- [ ] **AC-3** Sorted by id · check: manual: a person lists contacts → R3|'
refuses jsdd done 001 AC-1
jsdd claim 001 >/dev/null
expect "ticked 001 AC-1" jsdd done 001 AC-1
refuses jsdd done 001 AC-2
grep -q '^- \[ \] \*\*AC-2\*\*' "$base" || fail "a failing check ticked AC-2"
touch name-test-passes
expect "ticked 001 AC-2" jsdd done 001 AC-2
refuses jsdd done 001 AC-3
expect "ticked 001 AC-3" jsdd done 001 AC-3 --manual "scenario listed contacts"
expect "| 001 | baseline | in-progress | 0 | 3/3 |" jsdd status

step "a closed baseline that is not merged is flagged"
frontmatter "$base" status done
jsdd release 001 >/dev/null
out=$(jsdd capabilities) || true
has "$out" "not merged: 001 adds FR-LIST-01" || fail "capabilities did not flag the unmerged baseline: $out"
refuses jsdd capabilities --check

step "merging the baseline writes the area's first version"
mkdir -p docs/capabilities
cap=docs/capabilities/list.md
{
  printf '%s\n' '# Contact listing (FR-LIST)' ''
  for r in 01 02 03; do printf '%s\n' "## FR-LIST-$r · row $r" '' 'Last changed: 001 (2026-11-05)' '' '- The service shall ...' ''; done
  printf '%s\n' '## History' '' '| Date | Spec | Row | Change |' '| --- | --- | --- | --- |'
  for r in 01 02 03; do printf '| 2026-11-05 | 001 | FR-LIST-%s | adds |\n' "$r"; done
} >"$cap"
jsdd capabilities --check >/dev/null || fail "capabilities --check failed after the merge: $(jsdd capabilities)"
expect "| FR-LIST-01 | list.md | 001 |  |" jsdd capabilities FR-LIST

step "a feature's pending changes show against the entries it changes"
feat=$(jsdd new feature "Filter by email")
requirements "FR-LIST-01|Contacts are listed a page at a time|M" "FR-LIST-02|Contacts can be filtered by name (removed by 002)|W" \
  "FR-LIST-03|Contacts are sorted by id|S" "FR-LIST-04|Contacts can be filtered by email|M"
frontmatter "$feat" refs '["FR-LIST-01", "FR-LIST-02", "FR-LIST-04"]'
frontmatter "$feat" depends_on '["001"]'
edit "$feat" 's/^| FR-XXX-NN | adds | R1 |/| FR-LIST-01 | modifies | R1 |\
| FR-LIST-02 | removes | R2 |\
| FR-LIST-04 | adds | R3 |/'
out=$(jsdd capabilities FR-LIST)
has "$out" "| FR-LIST-01 | list.md | 001 | 002 modifies (draft) |" || fail "capabilities did not show the pending modify: $out"
has "$out" "| FR-LIST-04 |  |  | 002 adds (draft) |" || fail "capabilities did not show the pending add: $out"
# The dependency on the done baseline is met, with the ID quoted as refs are written.
! has "$(jsdd next)" "waiting on" || fail "002 waits on the done baseline: $(jsdd next)"

step "closing the feature: each half-merge is caught"
frontmatter "$feat" status done
out=$(jsdd capabilities) || true
has "$out" "not merged: 002 modifies FR-LIST-01" || fail "capabilities did not flag the unmerged feature: $out"
printf '| 2026-11-06 | 002 | FR-LIST-01 | modifies |\n| 2026-11-06 | 002 | FR-LIST-02 | removes |\n| 2026-11-06 | 002 | FR-LIST-04 | adds |\n' >>"$cap"
out=$(jsdd capabilities) || true
has "$out" "FR-LIST-02: removed, but its entry is still in list.md" || fail "capabilities did not flag the removed row's entry: $out"
edit "$cap" '/^## FR-LIST-02 /,/^- The service/d'
edit "$cap" 's/^## History/## FR-LIST-04 · row 04\
\
Last changed: 002 (2026-11-06)\
\
- When a client gives an email, the service shall ...\
\
## History/'
jsdd capabilities --check >/dev/null || fail "capabilities --check failed after the full merge: $(jsdd capabilities)"

step "an entry with no row is caught"
printf '\n## FR-LIST-09 · Gone\n' >>"$cap"
out=$(jsdd capabilities) || true
has "$out" "FR-LIST-09: entry in list.md has no row" || fail "capabilities did not flag the orphan entry: $out"
refuses jsdd capabilities --check
