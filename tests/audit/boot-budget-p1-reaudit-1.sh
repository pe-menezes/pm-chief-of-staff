#!/bin/sh
# Probes from the re-audit of fix round 1 of the boot-budget front, part 1.
# Behavior only, pinned by content.
# Run by hand: sh tests/audit/boot-budget-p1-reaudit-1.sh
# Every case works in folders under one mktemp -d, removed at the end. Each
# hook run goes through every shell found among /bin/sh and /bin/dash; the
# shells must agree byte for byte and on the exit, and the checks then run
# once on that output. A fake uname names the host "audithost".
# Cases:
# Q1 a number from wc that is not a safe integer (empty, garbage, negative,
#    a leading zero that arithmetic reads as octal or rejects, digits glued
#    to letters) gives exit 0 and exactly the one failure line, whether the
#    bad number comes from the size of CRITICAL_FACTS.md, from the size of
#    the manual, or from the size of the text the hook measures in memory;
#    a number of 10 or 20 digits gives exit 0 and either a pack or the one
#    failure line, never an empty stdout.
# Q2 date failing, printing garbage or printing another format: line 3 is
#    "time now: unknown" exactly when the date and time are not available;
#    the log is today's when the day is available and the latest dated log
#    when it is not, and neither memory/.md nor a log named after the
#    garbage is taken as the log.
# Q3 the bad number at each wc call in turn (call 1 to the last call the
#    hook makes in a pass-through run, so every measuring site is covered
#    without naming the sites): exit 0 and exactly the one failure line.
# Output: one ok or FAIL line per case; exit 0 only when every case passes.

ROOT=$(cd "$(dirname "$0")/../.." && pwd) || exit 1
HOOK="$ROOT/hooks/boot-memory.sh"
HEADER="=== MEMORY BOOT (pm-chief-of-staff) ==="
FAILLINE_RE='^Memory boot pack not assembled; the files are on disk in .+\.$'
REAL_WC=$(command -v wc)
failures=0

ok() { echo "ok    $1"; }
fail() { printf 'FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

work=$(mktemp -d 2>/dev/null)
if [ -z "$work" ] || [ ! -d "$work" ]; then
  echo "FAIL  mktemp -d returned no folder"
  exit 1
fi
work=$(cd "$work" && pwd)

SHELLS=""
for s in /bin/sh /bin/dash; do [ -x "$s" ] && SHELLS="$SHELLS $s"; done

# Fakes. The date answers from AUD_DAY and AUD_TIME: "fail" exits 1 with
# nothing on stdout, any other value is printed as is.
fakes="$work/fakes"
mkdir -p "$fakes"
cat > "$fakes/date" <<'EOF'
#!/bin/sh
case "$*" in
  '+%Y-%m-%d') v=$AUD_DAY ;;
  '+%Y-%m-%d %H:%M') v=$AUD_TIME ;;
  *) exec /bin/date "$@" ;;
esac
[ "$v" = fail ] && exit 1
printf '%s\n' "$v"
EOF
printf '#!/bin/sh\necho audithost\n' > "$fakes/uname"
# The wc answers AUD_WC_VALUE for the input picked by AUD_WC_TARGET and is
# the real wc for every other input: "all" is every input, "cf" the input
# that starts with CF_Q1 (CRITICAL_FACTS.md), "man" the one that starts with
# MAN_Q1 (the manual), "mem" every input that is neither (the text the hook
# measures in memory).
cat > "$fakes/wc" <<EOF
#!/bin/sh
t=\$(mktemp 2>/dev/null) || exit 1
cat > "\$t"
first=\$(LC_ALL=C head -c 6 "\$t")
hit=0
c=0
if [ -n "\$AUD_WC_COUNTER" ]; then
  c=\$(cat "\$AUD_WC_COUNTER" 2>/dev/null)
  c=\$((\${c:-0} + 1))
  echo "\$c" > "\$AUD_WC_COUNTER"
fi
case "\$AUD_WC_TARGET" in
  all) hit=1 ;;
  nth) [ "\$c" = "\$AUD_WC_N" ] && hit=1 ;;
  cf) case "\$first" in CF_Q1*) hit=1 ;; esac ;;
  man) case "\$first" in MAN_Q1) hit=1 ;; esac ;;
  mem) case "\$first" in CF_Q1*|MAN_Q1) ;; *) hit=1 ;; esac ;;
esac
if [ "\$hit" = 1 ]; then
  rm -f "\$t"
  printf '%s\n' "\$AUD_WC_VALUE"
  exit 0
fi
"$REAL_WC" "\$@" < "\$t"
r=\$?
rm -f "\$t"
exit \$r
EOF
chmod +x "$fakes/date" "$fakes/uname" "$fakes/wc"

# run DIR: runs the hook in DIR under every shell with the fakes in front of
# the PATH; the output of the first shell is in $work/out, $rc is its exit,
# $nl its line count; $shdiff is non-empty when the shells disagree.
run() {
  shdiff=""
  first=""
  for shl in $SHELLS; do
    : > "$work/wc.count"
    (cd "$1" && unset CLAUDE_PROJECT_DIR && PATH="$fakes:$PATH" "$shl" "$HOOK" > "$work/out.$$" 2>/dev/null)
    r=$?
    if [ -z "$first" ]; then
      first=$shl
      rc=$r
      mv "$work/out.$$" "$work/out"
    else
      if [ "$r" -ne "$rc" ] || ! cmp -s "$work/out" "$work/out.$$"; then
        shdiff="$first and $shl differ (exit $rc and $r)"
      fi
      rm -f "$work/out.$$"
    fi
  done
  nl=$(LC_ALL=C awk 'END { print NR + 0 }' "$work/out")
  size=$(LC_ALL=C "$REAL_WC" -c < "$work/out" | tr -d ' ')
}

# is_failline: the output is exactly the one failure line.
is_failline() {
  [ "$nl" -eq 1 ] && sed -n 1p "$work/out" | LC_ALL=C grep -Eq "$FAILLINE_RE"
}

# A small Chief of Staff whose files start with the markers the fake wc
# looks for.
d1="$work/q1 cos"
mkdir -p "$d1/memory"
printf 'MAN_Q1 manual\n' > "$d1/AGENTS.md"
printf 'CF_Q1 facts\n' > "$d1/CRITICAL_FACTS.md"
printf 'NAV_Q1\n' > "$d1/navigation.md"
printf '## [08:00] Q1_HEAD\n' > "$d1/memory/2031-05-17.md"

# Baseline: with the fake wc answering the real wc for every input, the
# pack boots (the fake itself is sound).
AUD_DAY=2031-05-17
AUD_TIME='2031-05-17 09:30'
export AUD_DAY AUD_TIME AUD_WC_TARGET AUD_WC_VALUE
AUD_WC_TARGET=none
AUD_WC_VALUE=
run "$d1"
q1=""
if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || [ "$(sed -n 1p "$work/out")" != "$HEADER" ] \
  || ! LC_ALL=C grep -qxF 'CF_Q1 facts' "$work/out" \
  || ! sed -n 4p "$work/out" | LC_ALL=C grep -Eq "^Sizes: CRITICAL_FACTS\.md 12 bytes .*, AGENTS\.md 14 bytes .*, this pack $size bytes \(limit 8000\)\.$"; then
  q1="baseline with the pass-through wc: exit $rc, $nl lines $shdiff"
fi

# Values that are not a safe integer give the failure line, at every source.
if [ -z "$q1" ]; then
  for target in all cf man mem; do
    for v in "" "zz9x" "-5" "12abc" "08" "0123" "1 2x"; do
      AUD_WC_TARGET=$target
      AUD_WC_VALUE=$v
      run "$d1"
      if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || ! is_failline; then
        q1="$q1 [$target '$v': exit $rc, $nl lines, $(sed -n 1p "$work/out" | cut -c1-60) $shdiff]"
      fi
    done
  done
  # Long numbers: exit 0 and a pack or the failure line.
  for v in 1000000000 99999999999999999999; do
    for target in all mem; do
      AUD_WC_TARGET=$target
      AUD_WC_VALUE=$v
      run "$d1"
      good=0
      [ "$(sed -n 1p "$work/out")" = "$HEADER" ] && good=1
      is_failline && good=1
      if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || [ "$good" -ne 1 ]; then
        q1="$q1 [$target '$v': exit $rc, $nl lines $shdiff]"
      fi
    done
  done
fi
AUD_WC_TARGET=none
if [ -z "$q1" ]; then
  ok "Q1 a wc number that is not a safe integer gives exit 0 and the one failure line, from the files and from memory"
else
  fail "Q1 bad numbers from wc" "$q1"
fi

# Q2: today is 2031-05-16 when the day is available; memory/2031-05-17.md
# is the latest dated log; memory/.md is a decoy.
d2="$work/q2 cos"
mkdir -p "$d2/memory"
printf 'manual\n' > "$d2/AGENTS.md"
printf 'CF_Q2\n' > "$d2/CRITICAL_FACTS.md"
printf 'NAV_Q2\n' > "$d2/navigation.md"
printf '## [08:00] Q2_TODAY\n' > "$d2/memory/2031-05-16.md"
printf '## [08:00] Q2_LATEST\n' > "$d2/memory/2031-05-17.md"
printf '## [08:00] Q2_DECOY\n' > "$d2/memory/.md"
printf '## [08:00] Q2_DECOY\n' > "$d2/memory/zz.md"
q2=""
# mode: AUD_DAY | AUD_TIME | expected line 3 | expected log
for mode in \
  "fail|fail|time now: unknown|memory/2031-05-17.md" \
  "zz|zz|time now: unknown|memory/2031-05-17.md" \
  "2031-05-16|fail|time now: unknown|memory/2031-05-16.md" \
  "fail|2031-05-16 09:30|time now: 2031-05-16 09:30|memory/2031-05-17.md" \
  "2031-5-16|2031-05-16 9:30|time now: unknown|memory/2031-05-17.md" \
  "2031-05-16|2031-05-16 09:30|time now: 2031-05-16 09:30|memory/2031-05-16.md"; do
  AUD_DAY=${mode%%|*}; rest=${mode#*|}
  AUD_TIME=${rest%%|*}; rest=${rest#*|}
  want3=${rest%%|*}
  wantlog=${rest#*|}
  run "$d2"
  why=""
  if [ -n "$shdiff" ]; then why="$shdiff"
  elif [ "$rc" -ne 0 ]; then why="exit $rc"
  elif [ "$(sed -n 1p "$work/out")" != "$HEADER" ]; then why="line 1: $(sed -n 1p "$work/out" | cut -c1-60)"
  elif [ "$(sed -n 3p "$work/out")" != "$want3" ]; then why="line 3: $(sed -n 3p "$work/out")"
  elif [ "$size" -gt 8000 ]; then why="$size bytes"
  elif ! LC_ALL=C grep -qxF -- "--- $wantlog ---" "$work/out"; then why="no section $wantlog"
  elif [ "$(LC_ALL=C grep -c -- '^--- memory/' "$work/out")" -ne 1 ]; then why="more than one log section"
  elif LC_ALL=C grep -q 'Q2_DECOY' "$work/out"; then why="an undated log taken as the log"
  elif ! LC_ALL=C grep -qxF "Nothing is left out of this pack; the files are in $d2." "$work/out"; then why="footer"
  fi
  [ -n "$why" ] && q2="$q2 [day '$AUD_DAY', time '$AUD_TIME': $why]"
done
if [ -z "$q2" ]; then
  ok "Q2 date failing or off format gives 'time now: unknown', today's log or the latest dated one, never an undated log"
else
  fail "Q2 date fallbacks" "$q2"
fi

# Q3: count the wc calls of a pass-through run in the Q1 folder, then put
# the bad number at each call in turn.
AUD_DAY=2031-05-17
AUD_TIME='2031-05-17 09:30'
AUD_WC_COUNTER="$work/wc.count"
export AUD_WC_COUNTER AUD_WC_N
AUD_WC_TARGET=none
run "$d1"
calls=$(cat "$work/wc.count")
q3=""
case "$calls" in ''|*[!0-9]*) q3="no wc call counted" ;; esac
[ -z "$q3" ] && [ "$calls" -lt 5 ] && q3="only $calls wc calls counted"
if [ -z "$q3" ]; then
  n=1
  while [ "$n" -le "$calls" ]; do
    for v in "" "08" "12abc"; do
      AUD_WC_TARGET=nth
      AUD_WC_N=$n
      AUD_WC_VALUE=$v
      run "$d1"
      if [ -n "$shdiff" ] || [ "$rc" -ne 0 ] || ! is_failline; then
        q3="$q3 [call $n '$v': exit $rc, $nl lines $shdiff]"
      fi
    done
    n=$((n + 1))
  done
fi
AUD_WC_TARGET=none
AUD_WC_COUNTER=
if [ -z "$q3" ]; then
  ok "Q3 a bad number at any one of the $calls wc calls gives exit 0 and the one failure line"
else
  fail "Q3 bad number at one wc call" "$q3"
fi

rm -rf "$work"
[ "$failures" -eq 0 ]
