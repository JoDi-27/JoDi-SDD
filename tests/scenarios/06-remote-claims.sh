#!/usr/bin/env bash
# Two people on their own clones share claims through the git remote
# (git config jsdd.claims remote): each claim is a ref under refs/sdd-claims/
# that a leased push takes only once, so the remote decides every race.
# shellcheck source=tests/scenarios/lib.sh
. "$(dirname "$0")/lib.sh"
project
jsdd init >/dev/null
spec=$(jsdd new feature "Shared across clones")
frontmatter "$spec" status planned
printf '%s\n' '# 001 · Tasks' '' '## Tasks' '' '- [ ] **T1** One · check: `true` → AC-1' '- [ ] **T2** Two · check: `true` → AC-1' >"$(dirname "$spec")/tasks.md"
git add -A && git commit -qm "[001] Specify shared work"
rm -rf "$(git rev-parse --git-common-dir)/sdd-claims"   # the reservation "new" made here, in local mode
git clone -q --bare . "$TMP/origin.git"
for who in alice bob; do
  git clone -q "$TMP/origin.git" "$TMP/$who"
  git -C "$TMP/$who" config user.name "$who"
  git -C "$TMP/$who" config user.email "$who@example.com"
  git -C "$TMP/$who" config jsdd.claims remote
done
A=$TMP/alice B=$TMP/bob
alice() { (cd "$A" && CLAUDE_CODE_SESSION_ID=session-alice "$KIT/bin/jsdd" "$@"); }
bob() { (cd "$B" && CLAUDE_CODE_SESSION_ID=session-bob "$KIT/bin/jsdd" "$@"); }

step "a spec claimed in one clone is refused in the other, naming who holds it"
alice claim 001 >/dev/null
out=$(bob claim 001 2>&1) && fail "bob claimed a spec alice holds: $out"
has "$out" "alice@" || fail "the refusal did not name alice: $out"
git --git-dir="$TMP/origin.git" show-ref | grep -q 'refs/sdd-claims/001$' || fail "no refs/sdd-claims/001 on the remote"
expect "(remote origin, as of" bob claims
expect "001      claimed  by alice@" bob claims

step "release: another person's claim needs --force"
refuses bob release 001
alice release 001 >/dev/null
! git --git-dir="$TMP/origin.git" show-ref | grep -q 'refs/sdd-claims/001$' || fail "release left the ref on the remote"

step "simultaneous claims: exactly one winner each round"
for round in 1 2 3 4 5; do
  alice claim 001 >"$TMP/a.out" 2>&1 & pa=$!
  bob claim 001 >"$TMP/b.out" 2>&1 & pb=$!
  ra=0; rb=0; wait $pa || ra=$?; wait $pb || rb=$?
  [ $((ra == 0)) -ne $((rb == 0)) ] || fail "round $round: alice exit $ra, bob exit $rb
$(cat "$TMP/a.out" "$TMP/b.out")"
  if [ $ra = 0 ]; then alice release 001 >/dev/null; else bob release 001 >/dev/null; fi
done

step "tasks: a done task records its branch, and the next claim says where it is"
git -C "$A" checkout -q -b alice/001
[ "$(alice claim 001 next 2>/dev/null)" = T1 ] || fail "alice did not get T1"
out=$(bob claim 001 next 2>&1) && fail "bob got a task while T1 was open: $out"
has "$out" "T2 waits on T1" || fail "bob was not told T2 waits on T1: $out"
expect "check passed; ticked 001 T1" alice done 001 T1
git --git-dir="$TMP/origin.git" log -1 --format=%B refs/sdd-claims/001-T1 | grep -qx 'branch=alice/001' \
  || fail "the done commit does not name alice's branch"
out=$(bob claim 001 next 2>&1)
has "$out" "T2" || fail "bob did not get T2 after T1 was done: $out"
has "$out" "done on branch alice/001 (by alice)" || fail "bob was not told T1 is on alice/001: $out"

step "the Stop hook's list: only what this session still holds"
[ "$(bob claims --mine)" = "001-T2" ] || fail "bob's held claims: $(bob claims --mine)"
[ -z "$(alice claims --mine)" ] || fail "alice still holds: $(alice claims --mine)"

step "new spec IDs never collide across clones"
a=$(alice new feature "Alice's next")
b=$(bob new feature "Bob's next")
case "$a $b" in "specs/002-"*" specs/003-"*) ;; *) fail "IDs collided or skipped: $a, $b" ;; esac

step "prune reads main on the remote: a tick on alice's branch frees nothing"
alice claims --prune >/dev/null
expect "001 T1   done" bob claims
git -C "$A" add -A && git -C "$A" commit -qm "[001] T1" && git -C "$A" push -q origin alice/001:main
alice claims --prune >/dev/null
! git --git-dir="$TMP/origin.git" show-ref | grep -q 'refs/sdd-claims/001-T1$' || fail "prune kept T1 on the remote after its tick reached main"
expect "(remote origin, as of" bob claims   # a read within SDD_CLAIMS_REUSE seconds reuses the last fetch...
! has "$(SDD_CLAIMS_REUSE=0 bob claims)" "001 T1" || fail "a fresh read still shows T1"   # ...a fresh one sees the prune

step "a default clone fetches no claim refs"
git clone -q "$TMP/origin.git" "$TMP/plain"
[ -z "$(git -C "$TMP/plain" for-each-ref refs/sdd-claims refs/sdd-claims-remote)" ] || fail "a plain clone got claim refs"

step "an unreachable remote: claims fail closed, reads fall back to the cache"
git -C "$B" remote set-url origin "$TMP/gone.git"
out=$(bob claim 003 2>&1) && fail "bob claimed with the remote gone: $out"
has "$out" "cannot reach the claims remote origin" || fail "no unreachable message: $out"
out=$(SDD_CLAIMS_REUSE=0 bob claims 2>&1)
has "$out" "unreachable; claims as of" || fail "claims did not say the remote is unreachable: $out"
has "$out" "001 T2" || fail "the cache lost bob's claim: $out"
SDD_CLAIMS=local bob claim 003 >/dev/null || fail "SDD_CLAIMS=local could not claim offline"
git -C "$B" remote set-url origin "$TMP/origin.git"

step "switching to remote with local claims held warns about them"
expect "claims held in local mode are not shared: 003" bob claims
expect "claims held in local mode are not shared: 003" bob status
SDD_CLAIMS=local bob release 003 >/dev/null
! has "$(bob claims)" "local mode" || fail "the warning stayed after the local claim was released"
