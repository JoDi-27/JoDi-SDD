#!/usr/bin/env bash
# Runtime modes: with no specs/jsdd.yml every gate asks; SDD_MODE picks a mode
# only when the project allows it; a mode that needs
# consent is never a project default; a bad file falls back to manual and
# fails --check; the board says so; every gate a skill names is in the catalog.
. "$(dirname "$0")/lib.sh"

project
jsdd init >/dev/null

step "no specs/jsdd.yml: manual, every gate asks, --check passes"
expect "mode: manual (built-in default)" jsdd mode
jsdd mode --check >/dev/null || fail "--check failed with no specs/jsdd.yml"
for g in $(jsdd mode --explain | awk 'NR > 3 { print $1 }'); do
  [ "$(jsdd gate "$g")" = ask ] || fail "gate $g does not ask in manual mode"
done
refuses jsdd gate no.such.gate
out=$(jsdd status)
has "$out" "MODE" && fail "the board shows a mode line in plain manual mode"

step "SDD_MODE asks for a mode the project does not allow: manual, with a warning on the board"
expect "not allowed here" env SDD_MODE=autonomous "$KIT/bin/jsdd" mode
expect "Mode warning:" env SDD_MODE=autonomous "$KIT/bin/jsdd" status
refuses env SDD_MODE=autonomous "$KIT/bin/jsdd" mode --check
expect "is not a mode" env SDD_MODE=bogus "$KIT/bin/jsdd" mode

step "the project allows autonomous: the default stays manual, SDD_MODE picks it"
cat >specs/jsdd.yml <<'EOF'
# Runtime modes for this project.
version: 1
modes: [manual, autonomous]
default: manual

autonomous:
  verify.gap_option: park   # never pick an option without a person
  commit: "auto"
EOF
jsdd mode --check >/dev/null || fail "--check refused a valid specs/jsdd.yml"
expect "mode: manual (specs/jsdd.yml default)" jsdd mode
[ "$(jsdd gate verify.gap_option)" = ask ] || fail "the project's autonomous section changed a gate in manual mode"

step "in autonomous mode, overrides and the catalog decide each gate, and the board is loud"
preview() { SDD_MODE=autonomous "$KIT/bin/jsdd" "$@"; }
expect "mode: autonomous (SDD_MODE)" preview mode
[ "$(preview gate verify.gap_option)" = park ] || fail "the project override was not used"
[ "$(preview gate plan.approve)" = auto ] || fail "the catalog policy was not used"
[ "$(preview gate task.manual_check)" = park ] || fail "a manual check does not park"
expect "[set in specs/jsdd.yml]" preview mode --explain
expect "MODE: autonomous, preset cautious (from SDD_MODE)" preview status
preview status --write >/dev/null
has "$(cat specs/STATUS.md)" "MODE" && fail "the per-person mode was written to specs/STATUS.md"

step "a mode that needs consent cannot be the project default"
edit specs/jsdd.yml 's/^default: manual/default: autonomous/'
expect "default cannot be autonomous" jsdd mode --check
refuses jsdd mode --check
expect "mode: manual (fallback)" jsdd mode

step "a bad file fails closed: every error listed, manual everywhere"
cat >specs/jsdd.yml <<'EOF'
version: 2
modes: autonomous
color: blue
manual:
  commit: auto
autonomous:
  commit: park
  verify.gaps: maybe
  no.such.gate: ask
EOF
out=$(jsdd mode --check 2>&1) && fail "--check passed a bad file"
for want in "version must be 1" "modes must be a list" "unknown key 'color'" "manual cannot be changed" \
  "'park' is not one of ask, auto" "'maybe' is not one of" "unknown gate 'no.such.gate'"; do
  has "$out" "$want" || fail "--check did not report: $want. Got:
$out"
done
[ "$(preview gate plan.approve)" = ask ] || fail "an invalid file still let a gate pass"
expect "is invalid, so every gate asks" jsdd status

step "every gate a skill names is in the catalog"
gates=$(jsdd mode --explain | awk 'NR > 3 { print $1 }')
for g in $(grep -ohE 'gate `[a-z._]+`' "$KIT"/skills/*/SKILL.md | sed 's/gate `//; s/`//' | sort -u); do
  printf '%s\n' "$gates" | grep -qx "$g" || fail "a skill names gate $g, which jsdd does not know"
done
