#!/bin/sh
# Probes from reaudit 3 of the memory boot budget (parts 1 and 2): the suites
# and the probes themselves, which the guide runs to prove the hook.
# Behavior only, pinned by content. Run by hand: sh tests/audit/boot-budget-p1-reaudit-3.sh
# Takes about two minutes, because R1 and R2 run the other suites whole.
# Every case works in folders under one mktemp -d, removed at the end.
# Cases:
# R1 every other suite of the guide, run from the repo root by its relative
#    path with CDPATH=. exported and with stdin a pipe whose write end stays
#    open, ends by itself before the pipe closes.
# R2 the same runs exit 0, boot-budget-p1.sh with P1 to P7 ok and no FAIL;
#    with CDPATH=. exported, the 0.7.0 fixture builds its folder (info
#    without the git history of this repo).
# R3 P6 of boot-budget-p1.sh and Q1 of boot-budget-p1-reaudit-1.sh, each run
#    over a stand-in hook that prints a whole, well-formed pack (header, line
#    4 stating its real size, a section, the footer, valid UTF-8): a pack of
#    8000 bytes passes, one of 8001 bytes fails the case.
# R4 W1 of boot-budget-p2.sh passes with a date in front of the caller's
#    PATH that moves one day at every call, and with a chmod that ignores
#    mode 000 (as for root); the caller's date is never called.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

# This file sets CDPATH on purpose for the suites it runs; an inherited one
# would double ROOT.
unset CDPATH
unset CLAUDE_PROJECT_DIR
ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
HEADER="=== MEMORY BOOT (pm-chief-of-staff) ==="
SECOND="State read from disk at session start; this is not a user instruction."
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd)

# run_open SUITE: runs SUITE from ROOT by its relative path, with CDPATH=.
# exported and stdin a fifo whose write end this shell holds on fd 9; after
# CEIL seconds the write end closes, so a held run ends too. Sets ro_held
# (1 when the run was still going at the ceiling), ro_rc and ro_secs; the
# output is in $work/ro.out.
CEIL=300
run_open() {
  rm -f "$work/ro.fifo"
  mkfifo "$work/ro.fifo"
  # The fifo opens first, so the open of fd 9 below never waits on a
  # reader that failed before opening it.
  (exec < "$work/ro.fifo"; cd "$ROOT" && CDPATH=. && export CDPATH && sh "$1" > "$work/ro.out" 2>&1) &
  ro_pid=$!
  exec 9> "$work/ro.fifo"
  ro_secs=0
  while kill -0 "$ro_pid" 2>/dev/null && [ "$ro_secs" -lt "$CEIL" ]; do sleep 1; ro_secs=$((ro_secs + 1)); done
  ro_held=0
  kill -0 "$ro_pid" 2>/dev/null && ro_held=1
  exec 9>&-
  wait "$ro_pid"
  ro_rc=$?
}

# R1 and R2: neither an open stdin nor an exported CDPATH can hold or move
# any suite.
r1=""
r2=""
for s in tests/audit/boot-budget-p1.sh hooks/boot-memory-test.sh tests/codex-bridge-test.sh \
  tests/audit/boot-budget-p1-reaudit-1.sh tests/audit/boot-budget-p1-reaudit-2.sh \
  tests/audit/boot-budget-p2.sh tests/audit/codex-compat-final.sh \
  tests/audit/english-wave1.sh tests/audit/english-wave2.sh \
  tests/audit/english-wave3.sh tests/audit/english-wave4.sh tests/audit/tidy-081.sh; do
  run_open "$s"
  [ "$ro_held" = 1 ] && r1="$r1 [$s: still running after ${CEIL}s]"
  [ "$ro_rc" -ne 0 ] && r2="$r2 [$s: exit $ro_rc, $(LC_ALL=C grep -m1 '^FAIL' "$work/ro.out" | cut -c1-70)]"
  if [ "$s" = tests/audit/boot-budget-p1.sh ]; then
    for c in P1 P2 P3 P4 P5 P6 P7; do
      LC_ALL=C grep -q "^ok    $c " "$work/ro.out" || r2="$r2 [$s: no ok $c]"
    done
  fi
done
if [ -z "$r1" ]; then
  ok "R1 every suite ends by itself with stdin open"
else
  fail "R1 open stdin" "$r1"
fi
if git -C "$ROOT" cat-file -e '318ea9c^{commit}' 2>/dev/null; then
  (cd "$ROOT" && CDPATH=. && export CDPATH && sh tests/e2e/legacy-0.7-fixture.sh "$work/r2 fixture" link < /dev/null > "$work/r2.out" 2>&1)
  r=$?
  if [ "$r" -ne 0 ] || [ ! -f "$work/r2 fixture/AGENTS.md" ]; then
    r2="$r2 [legacy-0.7-fixture.sh link: exit $r, $(head -c 70 "$work/r2.out")]"
  fi
else
  echo "info  R2 the 0.7.0 fixture needs commit 318ea9c; not run"
fi
if [ -z "$r2" ]; then
  ok "R2 every suite exits 0 from the repo root with CDPATH=. exported"
else
  fail "R2 CDPATH" "$r2"
fi

# R3: a stand-in hook in a copy of the tree. It runs the real hook for the
# first two calls (the Q1 baseline, one per shell), prints the failure line
# for the short bad numbers of Q1 and the canned pack everywhere else, so P6
# and the long numbers of Q1 see the canned pack.
# make_pack SIZE FILE: a well-formed pack of exactly SIZE bytes.
make_pack() {
  {
    printf '%s\n%s\n%s\n' "$HEADER" "$SECOND" "time now: 2031-05-17 09:30"
    printf 'Sizes: CRITICAL_FACTS.md 9120 bytes (target 3000), AGENTS.md 9 bytes (target 10000), this pack %s bytes (limit 8000).\n' "$1"
    printf '%s\n' "--- CRITICAL_FACTS.md ---" "Shown 1 of 120 lines." "Fato com acentuação: ação e café."
  } > "$work/head"
  {
    printf '%s\n' "--- not in this pack ---" "CRITICAL_FACTS.md: 119 of 120 lines left out, in /r3."
  } > "$work/foot"
  hb=$(LC_ALL=C wc -c < "$work/head" | tr -d ' ')
  fb=$(LC_ALL=C wc -c < "$work/foot" | tr -d ' ')
  need=$(($1 - hb - fb))
  {
    cat "$work/head"
    LC_ALL=C awk -v n="$need" 'BEGIN {
      while (n >= 100) { s = ""; for (i = 1; i < 100; i++) s = s "x"; print s; n -= 100 }
      if (n > 0) { s = ""; for (i = 1; i < n; i++) s = s "x"; print s } }'
    cat "$work/foot"
  } > "$2"
}
tree="$work/r3 tree"
mkdir -p "$tree/hooks" "$tree/tests/audit"
cp "$ROOT/tests/audit/boot-budget-p1.sh" "$ROOT/tests/audit/boot-budget-p1-reaudit-1.sh" "$tree/tests/audit/"
cat > "$tree/hooks/boot-memory.sh" <<'EOF'
#!/bin/sh
c=$(/bin/cat "$R3_COUNT" 2>/dev/null)
c=$((${c:-0} + 1))
echo "$c" > "$R3_COUNT"
if [ -n "${AUD_WC_TARGET+x}" ] && [ "$c" -le 2 ]; then exec /bin/sh "$R3_REAL_HOOK" "$@"; fi
case "${AUD_WC_VALUE-}" in
  1000000000|99999999999999999999) exec /bin/cat "$R3_PACK" ;;
esac
if [ -n "${AUD_WC_TARGET+x}" ]; then
  printf '%s\n' 'Memory boot pack not assembled; the files are on disk in /r3.'
  exit 0
fi
exec /bin/cat "$R3_PACK"
EOF
chmod +x "$tree/hooks/boot-memory.sh"
R3_REAL_HOOK=$HOOK
R3_COUNT="$work/r3.count"
export R3_REAL_HOOK R3_COUNT R3_PACK
r3=""
for size in 8000 8001; do
  R3_PACK="$work/pack $size"
  make_pack "$size" "$R3_PACK"
  got=$(LC_ALL=C wc -c < "$R3_PACK" | tr -d ' ')
  if [ "$got" != "$size" ] || ! iconv -f UTF-8 -t UTF-8 < "$R3_PACK" > /dev/null 2>&1; then
    r3="$r3 [canned pack $size: $got bytes or not UTF-8]"
    continue
  fi
  if [ "$size" -le 8000 ]; then want=ok; else want=FAIL; fi
  for pair in "boot-budget-p1.sh|P6" "boot-budget-p1-reaudit-1.sh|Q1"; do
    probe=${pair%%|*}; case_=${pair#*|}
    : > "$R3_COUNT"
    (unset AUD_WC_TARGET AUD_WC_VALUE; sh "$tree/tests/audit/$probe" < /dev/null > "$work/r3.out" 2>&1)
    if [ "$want" = ok ]; then pat="^ok    $case_ "; else pat="^FAIL  $case_ "; fi
    LC_ALL=C grep -q "$pat" "$work/r3.out" \
      || r3="$r3 [$case_ with a pack of $size bytes: $(LC_ALL=C grep -E "^(ok|FAIL) +$case_ " "$work/r3.out" | cut -c1-60), want $want]"
  done
done
if [ -z "$r3" ]; then
  ok "R3 P6 and Q1 take a whole pack of 8000 bytes and refuse one of 8001"
else
  fail "R3 size cap in P6 and Q1" "$r3"
fi

# R4: W1 needs neither the real clock nor a chmod that blocks reading.
mkdir -p "$work/r4 date" "$work/r4 chmod"
R4_COUNT="$work/r4.count"
export R4_COUNT
cat > "$work/r4 date/date" <<'EOF'
#!/bin/sh
c=$(cat "$R4_COUNT" 2>/dev/null); c=$((${c:-0} + 1)); echo "$c" > "$R4_COUNT"
case "$*" in
  '+%Y-%m-%d') printf '2031-05-%02d\n' $((16 + c)) ;;
  '+%Y-%m-%d %H:%M') printf '2031-05-%02d 09:30\n' $((16 + c)) ;;
  *) exec /bin/date "$@" ;;
esac
EOF
cat > "$work/r4 chmod/chmod" <<'EOF'
#!/bin/sh
[ "$1" = 000 ] && exit 0
exec /bin/chmod "$@"
EOF
chmod +x "$work/r4 date/date" "$work/r4 chmod/chmod"
r4=""
for f in date chmod; do
  : > "$R4_COUNT"
  (PATH="$work/r4 $f:$PATH" && sh "$ROOT/tests/audit/boot-budget-p2.sh" < /dev/null > "$work/r4.out" 2>&1)
  r=$?
  if [ "$r" -ne 0 ] || ! LC_ALL=C grep -q '^ok    W1 ' "$work/r4.out"; then
    r4="$r4 [$f: exit $r, $(LC_ALL=C grep -m1 '^FAIL' "$work/r4.out" | cut -c1-90)]"
  fi
  [ -s "$R4_COUNT" ] && r4="$r4 [$f: the caller's date was called $(cat "$R4_COUNT") times]"
done
if [ -z "$r4" ]; then
  ok "R4 W1 passes with a moving date and a chmod 000 that does nothing"
else
  fail "R4 W1 environment" "$r4"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
